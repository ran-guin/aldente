###################################################################################################################################
# QPIX.pm
#
# Customized function code for interacting with the QPIX robot
#
###################################################################################################################################
package Sequencing::QPIX;

### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;
use Storable;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";

### Reference to alDente modules
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use RGTools::RGIO;
use RGTools::Object;
use RGTools::Conversion;

### Global variables
use vars qw($user $Sess $homelink %Settings);

###############################################################
# Subroutine: Writes out the qpix file to the project/library directory
# RETURN: The fully-qualified file/directory where the qpix file was written
##############################################################
sub write_qpix_file {
    my $self        = shift;
    my $dbc         = $self->{dbc};
    my %args        = @_;
    my $rearray_id  = $args{-rearray_id};    # (Scalar) The rearray ID of the clone rearray
    my $plate_limit = $args{-plate_limit};

    # determine the filename and path
    my @find_array =
      $dbc->Table_find( 'Plate,ReArray_Request,Library,Project', 'Project_Name,Project_Path,Library_Name', "WHERE ReArray_Request_ID in ($rearray_id) AND FKTarget_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID" );
    my ( $project_name, $project_path, $libname ) = split ',', $find_array[0];

    my @rearray_array = split ',', $rearray_id;
    @rearray_array = sort (@rearray_array);
    my $min_id = $rearray_array[0];
    my $max_id = $rearray_array[-1];

    my $date = &date_time();
    $date = &today();
    my $filename = "$project_name\_$libname\_$min_id-$max_id\_$date.imp";
    my $path     = "";
    if ( $URL_version eq 'Production' ) {
        $path = "/home/sequence/alDente/QPIX";
    }
    else {
        $path = "/home/sequence/alDente/QPIX/test";
    }
    my @qpix_str = @{ generate_qpix( -dbc => $dbc, -rearray_ids => $rearray_id, -plate_limit => $plate_limit ) };

    # write directory if it doesn't exist
    if ( -e "$path" ) {
        try_system_command("mkdir $path");
    }
    my $file_no = 1;
    foreach my $qpix_str (@qpix_str) {
        $filename =~ s/ /_/g;
        $qpix_str =~ s/\n/\r\n/g;
        my $new_filename;
        if ( int(@qpix_str) > 1 ) {
            $filename =~ s/\.IMP//ig;
            $new_filename = $filename . "_$file_no.IMP";
        }
        else { $new_filename = $filename; }

        # write file
        my $fh;
        open( $fh, ">$path/$new_filename" );
        print $fh $qpix_str;
        close($fh);
        Message("Wrote QPIX file to $path/$new_filename");
        $file_no++;
    }

    # <CUSTOM> Use unix2dos
    #   `/usr/bin/unix2dos $path/$filename`;
    return $path . "/" . $filename;
} ## end sub write_qpix_file

###############################################################
# Subroutine: Creates a qpix string given a hashref of information on all needed rearrays
#             Original-style QPIX file
# RETURN: a string representing the qpix file
###############################################################
sub _generate_qpix_source_only {
###############################################################
    my %args = &filter_input( \@_, -args => 'dbc,data_ref' );

    my $dbc         = $args{-dbc};         # (ObjectRef) Database handle
    my $data_ref    = $args{-data_ref};    # (Hashref) A Table_retrieve hash of FKSource_Plate__ID,FK_Library__Name,Plate_Number,Source_Well,Target_Well,Plate_Size, and Plate_Position
    my $qpix_string = "";

    # get mapping from 96-well to 384-well (in case it is necessary)
    my %well_lookup = &Table_retrieve( $dbc, "Well_Lookup", [ 'Quadrant', 'Plate_96', 'Plate_384' ], 'order by Quadrant,Plate_96' );
    my %well_96_to_384;
    my $index = 0;
    foreach my $well ( @{ $well_lookup{'Plate_96'} } ) {
        $well_96_to_384{ uc( $well_lookup{'Plate_96'}[$index] ) . $well_lookup{'Quadrant'}[$index] } = $well_lookup{'Plate_384'}[$index];
        $index++;
    }

    my %rearray_info = %{$data_ref};

    # loop through %rearray_info and create a hash that maps {Source_Plates} => arrayref of plate names in the format
    # <LIBNAME><PLATENUMBER><WELL>,<TARGETWELL>
    my %sourceplate_hash;
    my %source_id_to_platename;
    $index = 0;
    my @Ordered_source_ids = ();
    my $total_clone_count  = 0;
    foreach my $source_id ( @{ $rearray_info{'FKSource_Plate__ID'} } ) {

        # add library name
        my $plate_name = $rearray_info{'FK_Library__Name'}[$index];

        # add plate number
        $plate_name .= $rearray_info{'Plate_Number'}[$index];
        $source_id_to_platename{$source_id} = $plate_name;

        # add source well
        if ( ( $rearray_info{"Plate_Size"}[$index] eq "96-well" ) && ( $rearray_info{Wells}[$index] eq '384' ) ) {
            my $quadrant = $rearray_info{"Plate_Position"}[$index];
            $plate_name .= &format_well( $well_96_to_384{ $rearray_info{'Source_Well'}[$index] . $quadrant } );
            my ($mul_id) = $Connection->Table_find( "Multiple_Barcode", "Multiple_Text", "WHERE Multiple_Text like '%pla$source_id%'" );
            $source_id = $mul_id;
        }
        else {
            $plate_name .= $rearray_info{'Source_Well'}[$index];
        }

        # add target well
        $plate_name .= $rearray_info{'Target_Well'}[$index];
        $index++;
        if ( defined $sourceplate_hash{"$source_id"} ) {
            push( @{ $sourceplate_hash{"$source_id"} }, "$plate_name" );
        }
        else {
            $sourceplate_hash{"$source_id"} = ["$plate_name"];

            # save the first instance of the source ID into an ordered array
            # to make it easy to retrieve the order (IMPORTANT!)
            push( @Ordered_source_ids, "$source_id" );
        }
        $total_clone_count++;
    } ## end foreach my $source_id ( @{ ...

    # process hash into the qpix string
    my $source_counter    = 0;
    my $clone_counter     = 0;
    my $total_plate_count = scalar(@Ordered_source_ids);
    foreach my $source_id (@Ordered_source_ids) {
        $source_counter++;
        $qpix_string .= "PLATE: $source_counter\n";
        if ( $source_id =~ /pla/i ) {
            $qpix_string .= "BARCODE: $source_id\n";
        }
        else {
            $qpix_string .= "BARCODE: pla$source_id\n";
        }

        # loop through all the names
        my @source_wells = ();
        my $well_counter = 0;
        foreach my $input_name ( @{ $sourceplate_hash{"$source_id"} } ) {
            my ( $well_name, $target_well ) = split ',', $input_name;
            $well_name =~ /(\S{5})(\S+)(\S{3})(\S{3})/;

            # $qpix_string .= "$well_name ";
            push( @source_wells, $3 );
            $well_counter++;
        }
        $clone_counter += $well_counter;
        $qpix_string .= "COMMENT: $source_id_to_platename{$source_id} SRC $source_counter\_$total_plate_count CLN $well_counter DONE $clone_counter\_$total_clone_count\n";

        # print the source wells in order
        foreach my $source_well (@source_wells) {
            $qpix_string .= "$source_well\n";
        }
    } ## end foreach my $source_id (@Ordered_source_ids)

    return $qpix_string;
} ## end sub _generate_qpix_source_only

###############################################################
# Subroutine: Creates a qpix string given a hashref of information on all needed rearrays
#             New-style QPIX file
# RETURN: a string representing the qpix file
###############################################################
sub _generate_qpix_source_and_destination {
###############################################################
    my %args = &filter_input( \@_, -args => 'dbc,data_ref' );

    my $dbc      = $args{-dbc};         # (ObjectRef) Database handle
    my $data_ref = $args{-data_ref};    # (Hashref) A Table_retrieve hash of FKSource_Plate__ID,FK_Library__Name,Plate_Number,Source_Well,Target_Well,Plate_Size,and Plate_Position

    my $qpix_string = "";

    # get mapping from 96-well to 384-well (in case it is necessary)
    my %well_lookup = &Table_retrieve( $dbc, "Well_Lookup", [ 'Quadrant', 'Plate_96', 'Plate_384' ], 'order by Quadrant,Plate_96' );
    my %well_96_to_384;
    my $index = 0;
    foreach my $well ( @{ $well_lookup{'Plate_96'} } ) {
        $well_96_to_384{ uc( $well_lookup{'Plate_96'}[$index] ) . $well_lookup{'Quadrant'}[$index] } = $well_lookup{'Plate_384'}[$index];
        $index++;
    }

    my %rearray_info = %{$data_ref};

    # loop through %rearray_info and create a hash for information on the qpix
    my %source_id_to_platename;
    $index = 0;
    my @Ordered_source_ids = ();
    my $total_clone_count  = 0;
    my %qpix_info;
    my %sourceplate_track;
    my %targetplate_track;

    foreach my $source_id ( @{ $rearray_info{'FKSource_Plate__ID'} } ) {

        # add library name
        my $plate_name = $rearray_info{'FK_Library__Name'}[$index];

        # add plate number
        $plate_name .= $rearray_info{'Plate_Number'}[$index];
        $source_id_to_platename{$source_id} = $plate_name;

        my $source_well = $rearray_info{'Source_Well'}[$index];

        # determine correct source_id and well (remap mul plates)
        if ( ( $rearray_info{"Plate_Size"}[$index] eq "96-well" ) && ( $rearray_info{'Wells'}[$index] eq '384' ) ) {
            my $quadrant = $rearray_info{"Plate_Position"}[$index];
            $source_well = &format_well( $well_96_to_384{ $source_well . $quadrant } );
            my ($mul_id) = $Connection->Table_find( "Multiple_Barcode", "Multiple_Text", "WHERE Multiple_Text like '%pla$source_id%'" );
            $source_id = $mul_id;
        }
        unless ( defined $sourceplate_track{"$source_id"} ) {

            # save the first instance of the source ID into an ordered array
            # to make it easy to retrieve the order
            push( @Ordered_source_ids, "$source_id" );
            $sourceplate_track{"$source_id"} = scalar(@Ordered_source_ids);
        }

        my $target_id   = $rearray_info{'FKTarget_Plate__ID'}[$index];
        my $target_well = $rearray_info{'Target_Well'}[$index];

        # define what number the target_plate is
        if ( defined $targetplate_track{"$target_id"} ) {
            $target_id = $targetplate_track{"$target_id"};
        }
        else {
            my $target_count = scalar( keys %targetplate_track );
            $target_count++;
            $targetplate_track{"$target_id"} = $target_count;
            $target_id = $targetplate_track{"$target_id"};
        }

        if ( defined $qpix_info{"$source_id"} ) {
            push( @{ $qpix_info{"$source_id"}{Rearray} }, "$source_well,$sourceplate_track{$source_id},$target_well,$target_id" );
        }
        else {
            $qpix_info{"$source_id"}{Rearray} = ["$source_well,$sourceplate_track{$source_id},$target_well,$target_id"];
        }
        $index++;
        $total_clone_count++;
    } ## end foreach my $source_id ( @{ ...

    #HTML_Dump(\%qpix_info);
    # process hash into the qpix string
    my $source_counter    = 0;
    my $clone_counter     = 0;
    my $total_plate_count = scalar(@Ordered_source_ids);

    # dump all the source definitions
    foreach my $source_id (@Ordered_source_ids) {
        $source_counter++;
        $qpix_string .= "PLATE: $source_counter\n";
        if ( $source_id =~ /pla/i ) {
            $qpix_string .= "BARCODE: $source_id\n";
        }
        else {
            $qpix_string .= "BARCODE: pla$source_id\n";
        }
        my $well_count = scalar( @{ $qpix_info{$source_id}{Rearray} } );
        $clone_counter += $well_count;
        $qpix_string .= "COMMENT: $source_id_to_platename{$source_id} SRC $source_counter\_$total_plate_count CLN $well_count DONE $clone_counter\_$total_clone_count\n";
    }

    # dump all the sourcewell => targetwell definitions
    foreach my $source_id (@Ordered_source_ids) {
        foreach my $row ( @{ $qpix_info{"$source_id"}{Rearray} } ) {
            $qpix_string .= "$row\n";
        }
    }

    return $qpix_string;
} ## end sub _generate_qpix_source_and_destination

###############################################################
# Subroutine: Function that generates a QPIX string
# RETURN: a string representing the qpix file
###############################################################
sub generate_qpix {
###############################################################
    my %args        = &filter_input( \@_, -args => "dbc,rearray_ids,type,quadrant" );
    my $rearray_ids = $args{-rearray_ids};                                              # (Scalar) A comma-delimited list of rearray_ids to generate a qpix file for. It is generally recommended to use one at a time.
    my $dbc         = $args{-dbc};                                                      # (ObjectRef) Database handle
    my $type        = $args{-type} || 'Source Only';                                    # (Scalar) Type of QPIX file. One of 'Source Only' or 'Source and Destination'
    my $quadrant    = $args{-quadrant} || 0;                                            # (Scalar) [Optional] Quadrant specification

    my $plate_limit = $args{-plate_limit};

    # retrieve rearray information from the database
    unless ($rearray_ids) {
        Message("Specify rearray ids");
    }

    my $extra_condition = '';

    if ($quadrant) {
        $extra_condition = " AND Quadrant in ($quadrant) ";
    }

    my $condition =
"where ReArray_Request_ID in ($rearray_ids) AND ReArray_Request_ID=FK_ReArray_Request__ID AND FKSource_Plate__ID=Plate_ID AND Plate_ID=FK_Plate__ID AND Plate_384=concat(Left(Target_Well,1),abs(Right(Target_Well,2))) AND FK_Plate_Format__ID=Plate_Format_ID $extra_condition order by ReArray_Request_ID,FKSource_Plate__ID,Quadrant,Plate_96";

    my %rearray_info = &Table_retrieve(
        $dbc,
        'Well_Lookup,ReArray_Request,ReArray,Plate,Plate_Format,Library_Plate',
        [ 'FKSource_Plate__ID', 'FK_Library__Name', 'Plate_Number', 'Source_Well', 'Target_Well', 'FKTarget_Plate__ID', 'Plate_Size', 'Wells', 'Library_Plate.Plate_Position' ], $condition
    );
    my %split_hash      = ();
    my @present_sources = ();
    my $index           = 0;
    my $split_index     = 1;

    while ( defined $rearray_info{FKSource_Plate__ID}[$index] ) {
        my $source = $rearray_info{FKSource_Plate__ID}[$index];
        if ( !( grep( /^$source$/, @present_sources ) ) ) {
            push( @present_sources, $source );
        }

        if ($plate_limit) {
            if ( int(@present_sources) > $plate_limit ) {

                @present_sources = ();
                $split_index++;
                next;
            }

        }
        foreach my $key ( keys %rearray_info ) {
            push( @{ $split_hash{$split_index}{$key} }, $rearray_info{$key}[$index] );
        }
        $index++;
    } ## end while ( defined $rearray_info...

    my @qpix_str = ();
    foreach my $qpix_key ( sort keys %split_hash ) {
        my $qpix_str = '';
        if ( $type =~ /Source Only/ ) {

            # old-style QPIX file
            $qpix_str = &_generate_qpix_source_only( -dbc => $dbc, -data_ref => $split_hash{$qpix_key} );
            push( @qpix_str, $qpix_str );
        }
        elsif ( $type =~ /Source and Destination/ ) {

            # new style QPIX file

            $qpix_str = &_generate_qpix_source_and_destination( -dbc => $dbc, -data_ref => $split_hash{$qpix_key} );
            push( @qpix_str, $qpix_str );
        }
        else {
            $Sess->error("ERROR: Invalid Argument: Type should be one of 'Source Only' or 'Source and Destination'");
        }
    }

    return \@qpix_str;
} ## end sub generate_qpix

###############################################################
# Subroutine: Function that writes a QPIX string to disk
# RETURN: None
###############################################################
sub write_qpix_to_disk {
###############################################################
    my %args           = &filter_input( \@_, -args => "dbc,rearray_ids,type,split_quadrant,split_files" );
    my $rearray_ids    = $args{-rearray_ids};                                                                # (Scalar) A comma-delimited list of rearray_ids to generate a qpix file for. It is generally recommended to use one at a time.
    my $dbc            = $args{-dbc};                                                                        # (ObjectRef) Database handle
    my $type           = $args{-type} || 'Source Only';                                                      # (Scalar) Type of QPIX file. One of 'Source Only' or 'Source and Destination'
    my $split_quadrant = $args{-split_quadrant} || 0;                                                        # (Scalar) [Optional] Allow quadrant splitting
    my $split_files    = $args{-split_files} || 0;                                                           # (Scalar) [Optional] Allow splitting of files per rearray
    my $plate_limit    = $args{-plate_limit};

    # define the set of rearray IDs to generate files for
    # add one array entry per file
    # group them all together if not split
    my @rearray_spec = ();
    if ($split_files) {
        @rearray_spec = split( ',', $rearray_ids );
    }
    else {
        @rearray_spec = ($rearray_ids);
    }

    # generate a file per entry in rearray_spec
    foreach my $rearray_id (@rearray_spec) {
        my @quad_spec = ();

        # define quadrant to generate for
        if ($split_quadrant) {
            @quad_spec = ( "'a'", "'b'", "'c'", "'d'" );
        }
        else {
            @quad_spec = ("'a','b','c','d'");
        }
        foreach my $quad (@quad_spec) {
            my @qpix_str = @{ generate_qpix( -dbc => $dbc, -rearray_ids => $rearray_id, -type => $type, -quadrant => $quad, -plate_limit => $plate_limit ) };
            ### write to disk

            # determine the filename and path
            my @find_array = $Connection->Table_find(
                'Plate,ReArray_Request,Library,Project',
                'Project_Name,Project_Path,Library_Name',
                "WHERE ReArray_Request_ID in ($rearray_id) AND FKTarget_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID"
            );
            my ( $project_name, $project_path, $libname ) = split ',', $find_array[0];

            my @rearray_array = split ',', $rearray_id;
            @rearray_array = sort (@rearray_array);
            my $min_id = $rearray_array[0];
            my $max_id = $rearray_array[-1];

            my $date = &date_time();
            $date = &today();
            my $filename = '';
            if ($split_quadrant) {
                $quad =~ s/\'//g;
                $filename = "$project_name\_$libname\_$min_id-$max_id\_$date.$quad.imp";
            }
            else {
                $filename = "$project_name\_$libname\_$min_id-$max_id\_$date.imp";
            }
            my $path = "";
            if ( $URL_version eq 'Production' ) {
                $path = "/home/sequence/alDente/QPIX";
            }
            else {
                $path = "/home/sequence/alDente/QPIX/test";
            }

            # write directory if it doesn't exist
            if ( -e "$path" ) {
                try_system_command("mkdir $path");
            }
            my $file_no = 1;
            foreach my $qpix_str (@qpix_str) {
                $filename =~ s/ /_/g;
                $qpix_str =~ s/\n/\r\n/g;
                my $new_filename;
                if ( int(@qpix_str) > 1 ) {
                    $filename =~ s/\.IMP//ig;
                    $new_filename = $filename . "_$file_no.IMP";
                }
                else { $new_filename = $filename; }

                # write file
                my $fh;
                open( $fh, ">$path/$new_filename" );
                print $fh $qpix_str;
                close($fh);
                Message("Wrote QPIX file to $path/$new_filename");
                $file_no++;
            }

            # <CUSTOM> Use unix2dos
            #`/usr/bin/unix2dos $path/$filename`;

        } ## end foreach my $quad (@quad_spec)
    } ## end foreach my $rearray_id (@rearray_spec)
} ## end sub write_qpix_to_disk

###############################################################
# Subroutine: prompts user for QPIX file options
# RETURN: none
###############################################################
sub prompt_qpix_options {
###############################################################
    my %args        = &filter_input( \@_, -args => "dbc,request" );
    my $rearray_ids = $args{-request};                                # (Scalar) a comma-delimited string of rearray ids to generate a qpix for
    my $dbc         = $args{-dbc};                                    # (ObjectRef) database handle

    print &start_custom_form( "QPIX Options", $dbc->homelink() );
    print hidden( -name => 'Request_ID', -value => $rearray_ids );

    # prompt user for PO, filetype, and if the order is to be split
    my $table = new HTML_Table();
    $table->Set_Title("Additional information (if applicable)");
    my %type_labels = ( 'Source Only' => 'Source Only (Old)', 'Source and Destination' => 'Source and Destination (New)' );
    $table->Set_Row( [ "File type:", &popup_menu( -name => "Filetype", -values => [ 'Source Only', 'Source and Destination' ], -labels => \%type_labels ) ] );
    $table->Set_Row( [ "Split Files per Rearray:", &checkbox( -name => "Split Files", -label => '' ) ] );
    $table->Set_Row( [ "Max number of source plates", textfield( -name => "Number_Of_Source_Plates", -value => '', -force => 1, -size => 4 ) ] );

    #$table->Set_Row(["Split Files per Quadrant:",&checkbox(-name=>"Split Quadrant",-label=>'')]);
    $table->Set_Row( [ '', &submit( -name => "Write to File", -class => "Std" ) ] );
    print $table->Printout(0);
    print end_form();
} ## end sub prompt_qpix_options

###############################################################
# Subroutine: displays all qpix racks.
# RETURN: none
###############################################################
sub view_qpix_rack {
###############################################################
    my %args = &filter_input( \@_, -args => "dbc,rearray_ids,type,split_quadrant" );

    my $rearray_ids    = $args{-request};                # (Scalar) a rearray id to generate the qpix racks for
    my $dbc            = $args{-dbc};                    # (ObjectRef) Database handle
    my $split_quadrant = $args{-split_quadrant} || 0;    # (Scalar) [Optional] Splits rack view into quadrants
    my $plate_limit    = $args{-plate_limit} || 12;      ## Maximum number of source plates for QPIX deck
    my @quad_spec      = ();

    # define quadrant to generate for
    if ($split_quadrant) {
        @quad_spec = ( "'a'", "'b'", "'c'", "'d'" );
    }
    else {
        @quad_spec = ("'a','b','c','d'");
    }

    # retrieve rearray information from the database
    unless ($rearray_ids) {
        Message("Specify rearray ids");
    }

    foreach my $quadrant (@quad_spec) {

        my @target_info = $dbc->Table_find( 'ReArray_Request,Plate', 'FKTarget_Plate__ID,FK_Library__Name,Plate_Number', "where FKTarget_Plate__ID=Plate_ID AND ReArray_Request_ID in ($rearray_ids) order by ReArray_Request_ID" );

        my $extra_condition = '';

        if ($quadrant) {
            $extra_condition = " AND Quadrant in ($quadrant) ";
        }

        my $header_target_string = "";
        my $targetcount          = 1;
        foreach my $row (@target_info) {
            my ( $target_plate, $target_lib, $target_platenum ) = split ',', $row;
            $header_target_string .= " Target $targetcount: pla$target_plate ($target_lib-$target_platenum)<BR>";
            $targetcount++;
        }

        my %rearray_info = &Table_retrieve( $dbc, 'Well_Lookup,Equipment,Rack,ReArray_Request,ReArray,Plate,Plate_Format', [ 'Plate_ID', 'FK_Library__Name', 'Plate_Number', 'Equipment_Name', 'Rack_ID', 'Wells', 'Plate_Size' ],
"where Equipment_ID=FK_Equipment__ID AND Rack_ID=FK_Rack__ID AND ReArray_Request_ID in ($rearray_ids) AND ReArray_Request_ID=FK_ReArray_Request__ID AND FKSource_Plate__ID=Plate_ID AND FK_Plate_Format__ID=Plate_Format_ID AND Plate_384=concat(Left(Target_Well,1),abs(Right(Target_Well,2))) $extra_condition order by ReArray_Request_ID,FKSource_Plate__ID,Quadrant,Plate_96"
        );

        # loop through %rearray_info and create a hash that maps {Source_Plates} => arrayref of plate names in the format
        # <LIBNAME><PLATENUMBER><WELL>,<TARGETWELL>
        my %sourceplate_hash;
        my $index              = 0;
        my @Ordered_source_ids = ();
        foreach my $source_id ( @{ $rearray_info{'Plate_ID'} } ) {

            # add library name
            my $plate_name = $rearray_info{'FK_Library__Name'}[$index] . ",";

            # add plate number
            $plate_name .= $rearray_info{'Plate_Number'}[$index] . ",";

            # add equipment name
            $plate_name .= $rearray_info{'Equipment_Name'}[$index] . ",";

            # add rack id
            $plate_name .= $rearray_info{'Rack_ID'}[$index];

            # adjustment for 96x4/384-well
            if ( ( $rearray_info{"Plate_Size"}[$index] eq "96-well" ) && ( $rearray_info{Wells}[$index] eq '384' ) ) {
                my ($mul_id) = $Connection->Table_find( "Multiple_Barcode", "Multiple_Text", "WHERE Multiple_Text like '%pla$source_id%'" );
                $source_id = $mul_id;
            }
            else {
                $plate_name .= $rearray_info{'Source_Well'}[$index];
            }

            $index++;
            unless ( defined $sourceplate_hash{"$source_id"} ) {
                $sourceplate_hash{"$source_id"} = "$plate_name";

                # save the first instance of the source ID into an ordered array
                # to make it easy to retrieve the order (IMPORTANT!)
                push( @Ordered_source_ids, $source_id );
            }
        } ## end foreach my $source_id ( @{ ...

        # process hash into tables
        my $source_counter = 0;

        # order the source ids to correspond to the racks of the qpix machines
        # store the ordered source ids to @qpix_rack_array, with each element as
        # a reference to an array that contains the source ids in the specific
        # order required by the qpix rack.
        # if the source ID is -1, then there is no source plate assigned to that position
        my @qpix_rack_array = ();

        # populate the whole single qpix rack with -1
        my $single_qpix_rack = [];
        @{$single_qpix_rack} = map { $_ = -1 } ( 1 .. 12 );

        # put every 16 source ids into one array
        my $id_counter = 0;
        for ( my $i = 0 ; $i < scalar(@Ordered_source_ids) ; $i++ ) {
            my ( $lib_name, $plate_num, $equip_name, $rack_id ) = split ',', $sourceplate_hash{ $Ordered_source_ids[$i] };
            my $entry = "";
            if ( $Ordered_source_ids[$i] =~ /pla/i ) {
                $entry .= "BARCODE: " . $Ordered_source_ids[$i] . "<BR>";
            }
            else {
                $entry .= "BARCODE: pla" . $Ordered_source_ids[$i] . "<BR>";
            }
            $entry .= "PLATE: " . $lib_name . "-" . $plate_num . "<BR>";
            $entry .= "LOC: " . $equip_name . " RACK " . $rack_id . "<BR>";
            $single_qpix_rack->[ $id_counter % 12 ] = $entry;
            $id_counter++;

            # push once 12 elements have been put in a rack
            if ( $id_counter == $plate_limit ) {
                push( @qpix_rack_array, $single_qpix_rack );

                # reset $single_qpix_rack
                $single_qpix_rack = [];
                @{$single_qpix_rack} = map { $_ = -1 } ( 1 .. 12 );
                $id_counter = 0;
            }
        } ## end for ( my $i = 0 ; $i < ...

        # if $id_counter != 0, then there is a $single_qpix_rack that hasn't been pushed
        if ( $id_counter != 0 ) {
            push( @qpix_rack_array, $single_qpix_rack );
        }

        # change ids to rack mapping
        foreach my $rack (@qpix_rack_array) {
            $rack = _rack_mapping($rack);
        }

        my $quad_str = '';
        if ($split_quadrant) {
            $quadrant =~ s/\'//g;
            $quad_str = " Quadrant $quadrant ";
        }
        my $full_table = new HTML_Table();
        $full_table->Set_HTML_Header($html_header);

        my $max_plates_per_rack = submit( -name => "Rearray View Options", -value => "Show QPIX Rack" ) . hspace(10) . "Max Source Plates" . textfield( -name => 'Max_Plates_Per_Rack', -size => 4 );
        $full_table->Set_sub_header( "Plates are Rearrayed to:<BR>$header_target_string $quad_str $max_plates_per_rack", 'mediumblue' );

        my $table = new HTML_Table( -border => 3 );
        $table->Set_Title("Source Rack 1");
        $table->Set_Column_Widths( [ 200, 200, 200, 200 ] );

        # print into a formatted table
        {

            # make sure integer division is used
            use integer;
            my $rack_count = 1;
            foreach my $rack (@qpix_rack_array) {
                my @single_row = ();
                for ( my $i = 0 ; $i < scalar( @{$rack} ) ; $i++ ) {

                    # if there is nothing in the cell (-1), then print blank
                    if ( $rack->[$i] == -1 ) {
                        push( @single_row, '&nbsp<BR><BR><BR>' );
                        $table->Set_Cell_Class( ( $i / 4 ) + 1, ( $i % 4 ) + 1, 'lightredbw' );
                    }
                    else {
                        push( @single_row, $rack->[$i] );
                    }
                    if ( ( $i % 4 ) == 3 ) {
                        $table->Set_Row( \@single_row );
                        @single_row = ();
                    }
                }
                $rack_count++;
                $full_table->Set_Row( [ $table->Printout( '', '', 1 ) ] );
                print "<BR>";
                $table = new HTML_Table( -border => 3 );
                $table->Set_Title("Source Rack $rack_count");
                $table->Set_Column_Widths( [ 200, 200, 200, 200 ] );
            } ## end foreach my $rack (@qpix_rack_array)
        }
        print $full_table->Printout( "$alDente::SDB_Defaults::URL_temp_dir/QPIX_Rack$rearray_ids@{[timestamp()]}.html", $html_header );

        print start_custom_form( "QPIX Rack", $dbc->homelink() );
        $full_table->Printout();
        print hidden( -name => 'Rearray Action',  -value => 1 );
        print hidden( -name => 'Request_ID',      -value => $rearray_ids );
        print hidden( -name => 'Split_Quadrants', -value => $split_quadrant );
        print end_form();
    } ## end foreach my $quadrant (@quad_spec)
} ## end sub view_qpix_rack

############################################################
# Function: returns the rack mapping for a qpix.
#           This is simply the transpose of that 3x4 matrix.
#           HARDCODED.
# RETURN: the rack mapping for a qpix rack
############################################################
sub _rack_mapping {
    my $rack_array_ref = shift;
    my @rack_array     = @{$rack_array_ref};
    my @new_rack       = map { $_ = -1 } ( 1 .. 12 );

    # HARDCODED matrix transpose
    $new_rack[0]  = $rack_array[11];
    $new_rack[1]  = $rack_array[8];
    $new_rack[2]  = $rack_array[5];
    $new_rack[3]  = $rack_array[2];
    $new_rack[4]  = $rack_array[10];
    $new_rack[5]  = $rack_array[7];
    $new_rack[6]  = $rack_array[4];
    $new_rack[7]  = $rack_array[1];
    $new_rack[8]  = $rack_array[9];
    $new_rack[9]  = $rack_array[6];
    $new_rack[10] = $rack_array[3];
    $new_rack[11] = $rack_array[0];

    return \@new_rack;
} ## end sub _rack_mapping

return 1;
