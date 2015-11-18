package alDente::GelAnalysis;

use strict;
use Data::Dumper;

use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::Transaction;

use RGTools::RGIO;
use RGTools::Conversion;

use alDente::SDB_Defaults;
use alDente::GelRun;
use alDente::Prep;

use vars qw($project_dir $mirror_dir $archive_dir);

#################################
#
# Move Gel images into the Projects directory
# Create the Lane entries for all the wells, mark the Lane Growth depending on the growth of the Well
# Record this event in the Prep table
#
##################
sub import_gel_image {
##################
    my %args = &filter_input( \@_, -args => 'dbc,report', -mandatory => 'dbc,report' );
    my $mirror_dir = $args{-mirror_dir} || $mirror_dir;
    my $Report     = $args{-report};
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);

    my %machine_info = $dbc->Table_retrieve(
        'Equipment,Machine_Default,Stock,Stock_Catalog,Equipment_Category',
        [ 'Equipment_ID', 'Local_Data_dir', 'Sub_Category' ],
        "WHERE (Category='Gel Imager/Scanner') AND FK_Equipment__ID=Equipment_ID AND FK_Stock__ID = Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID");
    ### Store a key-value paired for paths & equipment ids of fluroimagers
    my %machine_paths;
    my %Sub_Category;
    for (my $i =0; $i <=$#{$machine_info{Local_Data_dir}}; $i++) {
	$machine_paths{$machine_info{Local_Data_dir}[$i]}{Equipment_ID} = $machine_info{Equipment_ID}[$i];
	$machine_paths{$machine_info{Local_Data_dir}[$i]}{Sub_Category} = $machine_info{Sub_Category}[$i];
	$machine_info{Sub_Category}[$i] =~ s/Standard/Fluorimager/;
	$Sub_Category{$machine_info{Sub_Category}[$i]} = 1;
    }

    my @results;
    for my $EQUIPMENT_TYPE (keys %Sub_Category) {
	$Report->set_Detail("EXEC: find $mirror_dir/$EQUIPMENT_TYPE/ -iname 'run*'");
	my $result = try_system_command( "find $mirror_dir/$EQUIPMENT_TYPE/ -iname 'run*.gel'", -linefeed => "\n" );
	$Report->set_Detail($result);
	my @equ_results = split( '\n', $result );
	push @results, @equ_results;
    }

    my %found_files;
    map {
        my $file = $_;
        $file =~ /^(.+)\/run(\d+)/i;
        my $dir = $1;
        my $id  = $2;
        $id =~ s/^0+//g;

        ### Store Run IDs and Paths as key pair values
        $found_files{$id} = $file;
	#$found_files{$id} = $file if $file !~ /Fluorimager\/6/; #ignored during testing
    } @results;

    unless (%found_files) {
        $Report->set_Message("No new gel images found");
        return undef;
    }

    my @found_runs = sort keys %found_files;
    my $run_ids = join( ',', @found_runs );

    my %runs = $dbc->Table_retrieve(
        'RunBatch,Run,GelRun,Plate,Library,Project,
            Equipment       AS GelBoxEqu,
            Equipment       AS GelCombEqu,
            Employee        AS LoaderEmp, 
            Solution        AS AgarSol, 
            Stock           AS AgarStock,
            Stock_Catalog   AS AgarCatalog,
            Rack            AS GelRack',

        [   'Plate_ID', 'Run_ID', 'RunBatch_ID', 'Run_Directory', 'Library_Name', 'Project_Path',
            'GelBoxEqu.Equipment_Name AS GelBox',
            'GelCombEqu.Equipment_Name AS GelComb',
            'LoaderEmp.Initials AS Loader',
            'AgarCatalog.Stock_Catalog_Name AS AgarSol',
            'FKPosition_Rack__ID', "CONCAT(GelRack.FKParent_Rack__ID,':',GelRack.Rack_Name) AS RackPos"
        ],

        "WHERE Project.Project_ID=Library.FK_Project__ID AND
            Library.Library_Name=Plate.FK_Library__Name AND 
            Plate.Plate_ID=Run.FK_Plate__ID AND 
            RunBatch_ID=FK_RunBatch__ID AND 
            GelCombEqu.Equipment_ID=GelRun.FKComb_Equipment__ID AND 
            GelBoxEqu.Equipment_ID=GelRun.FKGelBox_Equipment__ID AND 
            LoaderEmp.Employee_ID=RunBatch.FK_Employee__ID AND
            GelRun.FKAgarose_Solution__ID = AgarSol.Solution_ID AND 
            AgarSol.FK_Stock__ID=AgarStock.Stock_ID AND 
            AgarStock.FK_Stock_Catalog__ID = AgarCatalog.Stock_Catalog_ID AND
            GelRun.FK_Run__ID=Run.Run_ID AND 
            Run.FKPosition_Rack__ID = GelRack.Rack_ID AND 
            Run_Status='In Process' AND
            Run_ID IN ($run_ids)"
    );

    unless (%runs) {
        $Report->set_Message("No valid gel images found");
        return undef;
    }

    my @done;
    my @plates_to_dispose;
    my $index = -1;
    my ($tmp_equ) = $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_Name='Shelf-2'" );

    while ( defined $runs{Run_ID}[ ++$index ] ) {
        ### These files are valid, they need to
        #     - be moved to archived
        #     - updated their fluroimager equipment id
        #     - create a link in projects directory for this file
        #     - create thumbnails as required..
        #     - marked in the system to have it's analysis started

        my $run_id    = $runs{Run_ID}[$index];
        my $proj_path = $runs{Project_Path}[$index];
        my $library   = $runs{Library_Name}[$index];
        my $run_dir   = $runs{Run_Directory}[$index];
        my $rack_id   = $runs{FKPosition_Rack__ID}[$index];

        my $file = $found_files{$run_id};

        ### If scanning is not done yet, or file is not a valid TIFF image, skip
        my $format_check = try_system_command( "file $file", -report => $Report );
        if ( $format_check !~ /: TIFF image data/ ) {
            if ( $format_check =~ /ERROR/ ) {
                $Report->set_Detail("Scanning of $file not done yet");
            }
            else {
                $Report->set_Error("Unknown message: $format_check for $file");
            }
            next;
        }

        $file =~ /^$mirror_dir\/(.+)\/run/i;

        my $path = $1;
        ### Update the Fluroimager ID..

        unless ( $machine_paths{$path}{Equipment_ID} ) {
            $Report->set_Error("Can not find the Equipment_ID for path $path");
            next;
        }

        ### Move file to archived directory
        my $new_file_path = "$archive_dir/$path/$run_dir.run.$run_id.tif";
        try_system_command( "mv $file $new_file_path", -report => $Report );

        $Report->set_Detail("Setting Equipment_ID of $run_id to $machine_paths{$path}{Equipment_ID} ('$path')");
        $dbc->Table_update_array( 'RunBatch', ['FK_Equipment__ID'], [ $machine_paths{$path}{Equipment_ID} ], "WHERE RunBatch_ID=$runs{RunBatch_ID}[$index]", -autoquote => 1 );
        $dbc->Table_update_array( 'Run', ['Run_Status'], ['Data Acquired'], "WHERE Run_ID=$run_id", -autoquote => 1 );

        ### Move the parent rack out of the gel box, into the Cart Equipment
        &alDente::GelRun::move_geltray_to_equ( $dbc, $rack_id, $tmp_equ );

        my $run_directory_full_path = "$project_dir/$proj_path/$library/AnalyzedData/$run_dir";
        try_system_command( "mkdir $run_directory_full_path", -report => $Report );

        try_system_command( "ln -s $new_file_path $run_directory_full_path/image.tif", -report => $Report );

	#LIMS-3832 adding customization for this particular scanner (equ2192 Sgg-1)
	my $extra_args = '-level 50%,90%';
	my $thumb_extra_args = '-level 30%,95%';
	if ($machine_paths{$path}{Sub_Category} eq 'SLR') { $extra_args = '-evaluate Multiply 1.20'; $thumb_extra_args = '-evaluate Multiply 1.20'; }

        &annotate_image(
            -input      => "$run_directory_full_path/image.tif",
            -output     => "$run_directory_full_path/annotated.jpg",
            -text       => "$runs{Run_Directory}[$index]\t$runs{GelBox}[$index]\t$runs{GelComb}[$index]\t" . "$runs{Loader}[$index]\t$runs{AgarSol}[$index]\t$runs{RackPos}[$index]",
	    -extra_args => " $extra_args",
            #-extra_args => ' -level 40%,90% ',
	    #-extra_args => ' -level 50%,90% ',
            -report     => $Report
        );

        &annotate_image(
            -input      => "$run_directory_full_path/image.tif",
            -output     => "$run_directory_full_path/thumb.jpg",
            -extra_args => " -resize 120x120 $thumb_extra_args",
	    #-extra_args => " -resize 120x120 -level 30%,95%",
            -report     => $Report
        );

        push( @done,              $runs{Run_ID}[$index] );
        push( @plates_to_dispose, $runs{Plate_ID}[$index] );
        $Report->succeeded();
    }

    if (@done) {
        &alDente::Container::throw_away( -dbc => $dbc, -ids => join( ',', @plates_to_dispose ), -notes => 'Gel Scanned', -confirmed => 1 );
        &start_analysis( -dbc => $dbc, -runids => \@done, -report => $Report );
        return \@done;
    }
    else {
        return undef;
    }
}

#########################
#
#  Start the analysis of Gel Runs
#
#
#########################
sub start_analysis {
#########################
    my %args = &filter_input( \@_, -args => 'dbc,runids,report' );

    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $runids = $args{-runids};
    my $Report = $args{-report};

    my $time = &date_time();
    my %GA_entries;
    my @GA_fields = qw(FK_Run__ID GelAnalysis_DateTime);

    my @runids = Cast_List( -list => $runids, -to => 'array' );
    my $index = 0;
    foreach (@runids) {
        $GA_entries{ ++$index } = [ $_, $time ];
    }

    my $GA_ids = $dbc->smart_append( -tables => 'GelAnalysis', -fields => \@GA_fields, -values => \%GA_entries, -autoquote => 1 );

    if ( $GA_ids->{GelAnalysis}->{newids} ) {
        $Report->set_Message( "Created " . int( @{ $GA_ids->{GelAnalysis}->{newids} } ) . " GelAnalysis entries" );
        &alDente::Run::set_analysis_status( $dbc, \@runids, 'Gel', 'Image Copied' );
    }
    else {
        $Report->set_Error( $dbc->{transaction}{error} );
    }
}

######################
#
# Creates a thumbnail of a
#
#####################
sub annotate_image {
#####################
    my %args = &filter_input( \@_, -args => 'input,output,text,report' );

    my $input      = $args{-input};
    my $output     = $args{-output};
    my $text       = $args{-text};
    my $Report     = $args{-report};
    my $rotate     = $args{-rotate} || 90;
    my $extra_args = $args{-extra_args} || '';

    if ($rotate) {
        $extra_args .= " -rotate $rotate ";
    }

    if ($text) {
        my $pointsize = 32;
        $Report->set_Detail("Writing $text");
        $extra_args .= " -fill black -draw \"text 10,50 '$text'\" -pointsize $pointsize";
    }

    my $command = "/usr/bin/convert $input $extra_args $output 2>/dev/null";    ## Stupid convert always gives error 'MissingRequired.'
    try_system_command( $command, -report => $Report );
}

#########################
# Imported from /home/mapper/production/gel_scripts/gels.pl
#
##################
sub MakeThumbGel {
##################
    my %input      = @_;
    my $inputfile  = $input{inputfile};
    my $outputfile = $input{outputfile};
    my $width      = $input{width} || 100;
    my $cropx      = $input{cropx};
    my $annotate   = $input{annotate};
    my $rotate     = $input{rotate};
    print "$inputfile\n";
    my $image = Image::Magick->new();
    $image->Read($inputfile);
    my $xsize = $image->Get('width');
    my $ysize = $image->Get('height');
    print " x=$xsize y=$ysize\n";

    # Crop if required
    if ($cropx) {
        my ( $cropx1, $cropx2 ) = @$cropx;
        print " cropping $cropx1 $cropx2\n";
        $image->Crop(
            width  => $cropx2 - $cropx1,
            height => $ysize,
            x      => $cropx1,
            y      => 0
        );
    }
    $xsize = $image->Get('width');
    $ysize = $image->Get('height');
    my $newx = $width;
    my $newy = int( $ysize * $newx / $xsize );
    $image->Scale( geometry => "$newx x $newy" );
    print " + contrast\n";
    my $ok = $image->Contrast( sharpen => "true" );

    if ($ok) {
        print " contrast [$ok]\n";
    }
    print " + despeckle\n";
    $ok = $image->Despeckle();
    if ($ok) {
        print " despeckle [$ok]\n";
    }
    print " + enhance\n";
    $ok = $image->Enhance();
    if ($ok) {
        print " enhance [$ok]\n";
    }
    print " + sharpen\n";
    $image->Sharpen( factor => 50 );
    if ($rotate) {
        $image->Rotate($rotate);
    }
    if ($annotate) {
        $ok = $image->Annotate(%$annotate);
        if ($ok) {
            print " font [$ok]\n";
        }
    }
    $image->Write($outputfile);
    print " $outputfile\n";
}
return 1;

