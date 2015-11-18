#!/usr/bin/perl
###################################################################################################################################
# Multiprobe.pm
#
# Customized function code for interacting with the multiprobe robot
#
###################################################################################################################################
package Sequencing::Multiprobe;

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
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use RGTools::RGIO;
use RGTools::Object;
use RGTools::Conversion;

### Global variables
use vars qw($user $Sess $homelink %Settings);

###############################################################
# Subroutine: Creates a multiprobe string, given a set of rearray
#             IDs. These must be strictly 96-96 DNA rearrays (for the moment).
# RETURN: a string representing the multiprobe file
###############################################################
sub generate_multiprobe {
###############################################################
    my %args = &filter_input( \@_, -args => 'dbc,rearray_ids,primer_plate_ids,type' );

    my $rearray_ids      = $args{-rearray_ids};           # (Scalar) A (comma or dash range-separated) range of rearray ids
    my $primer_plate_ids = $args{-primer_plate_ids};      # (Scalar)  A (comma or dash range-separated) range of primer plate ids
    my $type             = $args{-type};                  # (Scalar) The type of multiprobe file to generate. One of Primer or DNA
    my $dbc              = $args{-dbc} || $Connection;    # (Objectref) Database handle
    my $plate_limit      = $args{-plate_limit};           # (Scalar) The maximum number of plates to put into one file. If this limit is reached, another file will be generated
    my $split_quadrant   = $args{-split_quadrant} || 1;
    my $plate_size;
    my @multiprobe_info = ();
    if ($rearray_ids) {

        # resolve range
        $rearray_ids = &RGTools::RGIO::resolve_range($rearray_ids);

        ## first, check if the rearray is 96-96
        my @target_rearray = $dbc->Table_find( "ReArray_Request,Plate,Plate_Format", "Wells", "WHERE ReArray_Request_ID in ($rearray_ids) AND FKTarget_Plate__ID=Plate_ID AND FK_Plate_Format__ID=Plate_Format_ID", 'distinct' );

        my @target_rearray_sizes = $dbc->Table_find( "ReArray,Plate,Plate_Format", "Wells", "WHERE FK_ReArray_Request__ID in ($rearray_ids) AND FKSource_Plate__ID=Plate_ID AND FK_Plate_Format__ID=Plate_Format_ID", 'distinct' );
        if ( ( scalar(@target_rearray_sizes) != 1 ) && ( $target_rearray_sizes[0] ne '96' ) ) {
            $dbc->warning("Target plate is not 96-well") if ($dbc);
        }
        if ( ( scalar(@target_rearray_sizes) != 1 ) && ( $target_rearray_sizes[0] ne '96' ) ) {
            $dbc->warning("One or more source plates is not 96-well") if ($dbc);
        }

        my @rearray_id_array = split ',', $rearray_ids;

        my $counter = 1;
        foreach my $id (@rearray_id_array) {
            ### get the rearray information + the sample information - sorted by Target_Plate, then Target_Well
            my ($rearray_status) = $dbc->Table_find( "ReArray_Request,Status", "Status_Name", "WHERE FK_Status__ID=Status_ID AND ReArray_Request_ID=$id" );
            my @rearray_array = ();

            # call specialized functions to retrieve data in correct format
            if ( $type eq "Primer" ) {
                @rearray_array = @{ &_generate_rearray_primer_multiprobe( -dbc => $dbc, -rearray_id => $id, -default_sol_id => $counter ) };
                $counter++;
            }
            else {
                @rearray_array = @{ &_generate_DNA_multiprobe( -dbc => $dbc, -rearray_id => $id ) };
            }

            # push into result array
            foreach my $info (@rearray_array) {
                my ( $source, $target, $source_well, $target_well, $sample_name ) = split ',', $info;
                push( @multiprobe_info, [ $source, $target, $source_well, $target_well, $sample_name ] );
            }

        }
    }
    elsif ($primer_plate_ids) {

        # resolve range
        $primer_plate_ids = &RGTools::RGIO::resolve_range($primer_plate_ids);

        # get multiprobe array
        my @primer_array = @{ &_generate_primer_multiprobe( -dbc => $dbc, -id => $primer_plate_ids ) };

        # push into result array
        foreach my $info (@primer_array) {
            my ( $source, $target, $source_well, $target_well, $sample_name ) = split ',', $info;
            push( @multiprobe_info, [ $source, $target, $source_well, $target_well, $sample_name ] );
        }

    }

    # scan the array and count the number of source plates
    # split up the array every time the limit is reached
    my @split_array = ();

    my %quad;
    if ($rearray_ids) {
        ($plate_size) = $dbc->Table_find( "ReArray_Request,Plate_Format,Plate", "Plate_Size", "WHERE ReArray_Request_ID IN ($rearray_ids) and FKTarget_Plate__ID = Plate_ID and Plate_Format_ID = FK_Plate_Format__ID" );
    }
    if ( $split_quadrant && $plate_size =~ /384/ ) {

        foreach my $row (@multiprobe_info) {
            ## check the target well
            ## convert to 96well format and get the quadrant
            my ( $source, $target, $source_well, $target_well, $sample_name ) = @{$row};
            $target_well = lc( format_well( $target_well, 'nopad' ) );
            my ($well_info) = $dbc->Table_find( 'Well_Lookup', 'Quadrant,Plate_96', "WHERE Plate_384 = '$target_well'" );
            my ( $quad, $new_target_well ) = split ',', $well_info;
            push( @{ $quad{$quad} }, [ $source, $target, $source_well, $new_target_well, $sample_name ] );
        }
    }
    else {
        $quad{''} = \@multiprobe_info;
    }

    my %split_hash;
    foreach my $key ( sort keys %quad ) {
        my $curr_array      = [];
        my @present_sources = ();
        my @multiprobe_info = @{ $quad{$key} };
        foreach my $row (@multiprobe_info) {
            my ( $source, undef ) = @{$row};
            if ( !( grep( /^$source$/, @present_sources ) ) ) {
                push( @present_sources, $source );
            }

            if ($plate_limit) {
                if ( int(@present_sources) > $plate_limit ) {
                    push( @{ $split_hash{$key} }, $curr_array );
                    $curr_array      = [];
                    @present_sources = ();
                }
            }
            push( @{$curr_array}, $row );
        }
        push( @{ $split_hash{$key} }, $curr_array );
    }

    # write out each row of the multiprobe string
    # if the source plate limit is reached, roll over into another string

    my %multiprobe_hash = ();

    foreach my $key ( sort keys %split_hash ) {
        my $counter = 1;

        my $multiprobe_string = "";
        foreach my $set ( @{ $split_hash{$key} } ) {
            foreach my $row (@$set) {
                my ( $source, $target, $source_well, $target_well, $sample_name ) = @{$row};

                # remove well 0-padding
                $source_well = &format_well( $source_well, 'nopad' );
                $target_well = &format_well( $target_well, 'nopad' );

                # if first line, write out number of rows
                if ( $counter == 1 ) {
                    my $numrows = scalar(@$set);
                    $multiprobe_string .= "$sample_name,$counter,$source,$source_well,$target_well,$target,$numrows\n";
                }
                else {
                    $multiprobe_string .= "$sample_name,$counter,$source,$source_well,$target_well,$target\n";
                }
                $counter++;
            }

            # push string into array
            push( @{ $multiprobe_hash{$key} }, $multiprobe_string );
            $multiprobe_string = '';
            $counter           = 1;
        }
    }

    return \%multiprobe_hash;
}

###############################################################
# Subroutine: Writes out the multiprobe file to the appropriate directories
# RETURN: none
##############################################################
sub write_multiprobe_file {
##############################################################
    my %args = &filter_input( \@_, -args => 'dbc,rearray_id,primer_plate_id,type' );

    my $rearray_id      = $args{-rearray_id};            # (Scalar) The rearray ID of the rearrays
    my $primer_plate_id = $args{-primer_plate_id};       # (Scalar) The primer plate ID of the primer plate that was remapped
    my $type            = $args{-type};                  # (Scalar) one of Primer or DNA
    my $dbc             = $args{-dbc} || $Connection;    # (ObjectRef) Database handle
    my $plate_limit     = $args{-plate_limit};           # (Scalar) The maximum number of plates to put into one file. If this limit is reached, another file will be generated
    my $user_id         = $dbc->get_local('user_id');

    my $filename = "";
    my $date     = &date_time();
    $date = &today();
    my ($initials) = $dbc->Table_find( "Employee", "Initials", "WHERE Employee_ID=$user_id" );

    # determine the filename and path
    if ( $type eq "DNA" ) {
        my @find_array = $dbc->Table_find( 'Plate,ReArray_Request', 'Plate_ID,FK_Library__Name,Plate_Number', "WHERE ReArray_Request_ID in ($rearray_id) AND FKTarget_Plate__ID=Plate_ID" );
        my ( $plate_id, $lib_name, $platenum ) = split ',', $find_array[0];
        $filename = "${plate_id}_${lib_name}_${platenum}_multiprobe_<COUNT>_${type}_${date}_${initials}.csv";
    }
    elsif ( ( $type eq "Primer" ) && $rearray_id ) {
        my @find_array = $dbc->Table_find(
            'Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate,ReArray_Request,Plate',
            'distinct FK_Solution__ID,FK_Library__Name,Plate_Number',
            "WHERE ReArray_Request_ID in ($rearray_id) AND FKTarget_Plate__ID=Plate_ID AND FK_Plate__ID=Plate_ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND Primer_Plate_ID=FK_Primer_Plate__ID"
        );
        my ( $plate_id, $lib_name, $platenum ) = split ',', $find_array[0];

        # check if plate is a direct mapping. If it is not, name it 'primers' instead of a solution id
        my %well_info = &Table_retrieve(
            $dbc,
            "ReArray,ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well",
            [ "Target_Well", "Well as Primer_Well" ],
            "WHERE ReArray_Request_ID=$rearray_id AND FK_ReArray_Request__ID=ReArray_Request_ID AND (FKTarget_Plate__ID=FK_Plate__ID AND Plate_Well=Target_Well) AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID"
        );
        my $counter   = 0;
        my $can_remap = 0;
        while ( exists $well_info{"Target_Well"}[$counter] ) {
            if ( $well_info{"Target_Well"}[$counter] ne $well_info{"Primer_Well"}[$counter] ) {
                $can_remap = 1;
                last;
            }
            $counter++;
        }
        if ( $can_remap == 1 ) {
            $plate_id = 'primers';
        }

        $filename = "${plate_id}_${lib_name}_${platenum}<QUAD>multiprobe_<COUNT>_${type}_${date}_${initials}.csv";
    }
    elsif ( ( $type eq 'Primer' ) && $primer_plate_id ) {
        my ($notes)  = $dbc->Table_find( 'Primer_Plate_Well,Primer_Plate', 'Notes',           "WHERE Primer_Plate_ID=FK_Primer_Plate__ID AND Primer_Plate_ID=$primer_plate_id" );
        my ($sol_id) = $dbc->Table_find( 'Primer_Plate_Well,Primer_Plate', 'FK_Solution__ID', "WHERE Primer_Plate_ID=FK_Primer_Plate__ID AND Primer_Plate_ID=$primer_plate_id" );
        $filename = "${sol_id}_${primer_plate_id}_${notes}_multiprobe_<COUNT>_${type}_${date}_${initials}";
    }
    else {
        Message("Invalid type $type");
        return 0;
    }
    my $path = "";
    if ( $URL_version eq 'Production' ) {
        $path = "/home/sequence/alDente/multiprobe/$type";
    }
    else {
        $path = "/home/sequence/alDente/multiprobe/test";
    }

    # get the multiprobe string
    my $multiprobe_string = &generate_multiprobe( -dbc => $dbc, -rearray_ids => $rearray_id, -primer_plate_ids => $primer_plate_id, -type => $type, -plate_limit => $plate_limit );

    # write directory if it doesn't exist
    if ( -e "$path" ) {
        try_system_command("mkdir $path");
    }

    my $multiprobe_summary = HTML_Table->new( -title => "Multiprobe Summary" );

    # write files
    foreach my $key ( sort keys( %{$multiprobe_string} ) ) {
        my $count = 1;
        foreach my $str ( @{ $multiprobe_string->{$key} } ) {
            my $full_filename = "$filename";
            $full_filename =~ s/<COUNT>/$count/;
            my $quad = uc($key);
            $full_filename =~ s/<QUAD>/\_$quad\_/;
            my $fh;
            open( $fh, ">$path/$full_filename" );
            print $fh $str;
            close($fh);

            my $primer_plate_summary = HTML_Table->new( -title => "Summary for $full_filename" );
            $primer_plate_summary->Set_sub_title("ReArray ID: $rearray_id <BR>");
            $primer_plate_summary->Set_Headers( [ 'Primer Plate Name', 'Solution ID', 'Location' ] );

            my @primer_solutions = parse_multiprobe_string_for_primer_plates( -multiprobe_string => $str );
            foreach my $solution (@primer_solutions) {
                my $solution_id = get_aldente_id( $dbc, $solution, 'Solution' );
                my ($solution_info) = Table_find( $dbc, 'Solution,Primer_Plate', 'Primer_Plate_Name,FK_Rack__ID', "WHERE FK_Solution__ID = Solution_ID and Solution_ID = $solution_id" );
                my ( $primer_plate_name, $rack ) = split ',', $solution_info;
                $rack = get_FK_info( $dbc, 'FK_Rack__ID', $rack );
                $primer_plate_summary->Set_Row( [ $primer_plate_name, $solution_id, $rack ] );
            }
            $multiprobe_summary->Set_Row( [ $primer_plate_summary->Printout(0) ] );

            Message("Wrote multiprobe file to $path/$full_filename");
            $count++;
        }
    }
    print $multiprobe_summary->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Multiprobe_" . $rearray_id . "_@{[timestamp()]}.html", $html_header );
    $multiprobe_summary->Printout();

    return;
}

sub parse_multiprobe_string_for_primer_plates {
    my %args              = @_;
    my $multiprobe_string = $args{-multiprobe_string};

    my @multiprobe_contents = split '\n', $multiprobe_string;

    my @primer_solutions;
    foreach my $multiprobe_content (@multiprobe_contents) {

        my ( $sample_name, $counter, $source, $source_well, $target_well, $target ) = split ',', $multiprobe_content;

        unless ( grep /$source/i, @primer_solutions ) {
            push( @primer_solutions, $source );
        }
    }

    return sort (@primer_solutions);
}

########################################
# Subroutine: Prompts for the maximum number of source plates for a multiprobe
# RETURN: none
########################################
sub prompt_multiprobe_limit {
########################################
    my %args = &filter_input( \@_, -args => 'rearray_id,primer_plate_id,type,dbc' );

    my $rearray_id      = $args{-rearray_id};         # (Scalar) rearray id for this primer multiprobe
    my $primer_plate_id = $args{-primer_plate_id};    # (Scalar) primer plate id for this primer multiprobe
    my $type            = $args{-type};               # (Scalar) Type of multiprobe file. One of DNA or Primer
    my $dbc             = $args{-dbc};

    print &RGTools::RGIO::start_custom_form( "Multiprobe Prompt", $dbc->homelink() );
    my $table = new HTML_Table();
    $table->Set_Title("Additional Information (if applicable)");
    $table->Set_Row( [ 'Max number of source plates', &textfield( -name => 'SourceLimit' ) ] );
    $table->Set_Row( [ '', &submit( -name => 'Generate Multiprobe', -class => "Std" ) ] );
    print $table->Printout(0);
    if ($rearray_id) {
        print hidden( -name => "Rearray ID", -value => $rearray_id );
    }
    elsif ($primer_plate_id) {
        print hidden( -name => "Primer Plate ID", -value => $primer_plate_id );
    }
    print hidden( -name => "Multiprobe Type", -value => $type );
    print end_form();
}

###############################################################
# Subroutine: Generates an ordered array representing information needed for a multiprobe file (based on a rearray)
# RETURN: an array, with each line representing a multiprobe line
###############################################################
sub _generate_rearray_primer_multiprobe {
###############################################################
    my %args = &filter_input( \@_, -args => 'rearray_id,default_sol_id' );

    my $rearray_id     = $args{-rearray_id};             # (Scalar) rearray id for this primer multiprobe
    my $new_sol_id     = $args{-default_sol_id} || 1;    # (Scalar) placeholder solution id (if a sol id has not yet been defined)
    my $dbc            = $args{-dbc} || $Connection;     # (ObjectRef) Database handle
    my $split_quadrant = 1;

    # first, look to see if the Primer_Plate applied (through Plate_PrimerPlateWell) is Made in House (if there is only one)
    # if it isn't - just pull off the information from Plate_PrimerPlateWell and ask the user if he/she
    #               wants to create a new Primer_Plate with the new mapping
    # if it is    - use the parent Primer_Plate information instead of the information in Plate_PrimerPlateWell
    #               Ask the user if he/she wants to re-create a new Primer_Plate

    # flag that determined whether the Primer_Plates can be remapped
    my $new_plate = 0;

    # grab primer plate/s

    my @primer_plate_ids
        = $dbc->Table_find( "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well", "distinct FK_Primer_Plate__ID", "WHERE FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND ReArray_Request_ID=$rearray_id" );

    # more than 1 source primer plate - definitive indication that it can be remapped
    my ($plate_size) = $dbc->Table_find( "ReArray_Request,Plate_Format,Plate", "Plate_Size", "WHERE ReArray_Request_ID=$rearray_id and FKTarget_Plate__ID = Plate_ID and Plate_Format_ID = FK_Plate_Format__ID" );
    my $order_by = "right(Plate_Well,2),left(Plate_Well,1)";
    my $extra_condition;
    my $rearray_tables = "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well as Child,Primer_Plate_Well as Parent,Primer_Plate as Parent_Plate,Primer_Plate as Child_Plate";
    my $rearray_fields = "Parent_Plate.FK_Solution__ID,Child_Plate.FK_Solution__ID,Parent.Well,Plate_Well,Parent.FK_Primer__Name";

    if ( $plate_size =~ /384/i ) {
        $new_plate = 1;
        if ($split_quadrant) {
            $rearray_tables  .= ",Well_Lookup";
            $extra_condition .= "AND Plate_Well = CASE WHEN (Length(Plate_384)=2) THEN ucase(concat(left(Plate_384,1),'0',Right(Plate_384,1))) ELSE Plate_384 END";
            $order_by = "Quadrant," . $order_by;
        }
    }
    elsif ( scalar(@primer_plate_ids) > 1 ) {
        $new_plate = 0;
    }
    else {

        # check to see if the primer plate has the same mapping as Plate_PrimerPlateWell
        # if it is, then it has been mapped already
        my @well_match = $dbc->Table_find( "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well", "Plate_Well,Well", "WHERE FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND ReArray_Request_ID=$rearray_id" );
        foreach (@well_match) {
            my ( $plate_well, $primer_well ) = split ',', $_;
            if ( $plate_well ne $primer_well ) {
                $new_plate = 0;
                last;
            }
            else {

                # if it passed this test, then they are the same
                $new_plate = 1;
            }
        }
    }
    my @result_array = ();

    # already created a new Primer_Plate. Display its parents' information
    if ( $new_plate == 1 ) {
        @result_array = $dbc->Table_find( "$rearray_tables", "$rearray_fields",
            "WHERE ReArray_Request_ID=$rearray_id AND FKTarget_Plate__ID=FK_Plate__ID AND Child.Primer_Plate_Well_ID=FK_Primer_Plate_Well__ID AND Child.FK_Primer_Plate__ID=Child_Plate.Primer_Plate_ID AND Child.FKParent_Primer_Plate_Well__ID=Parent.Primer_Plate_Well_ID AND Parent.FK_Primer_Plate__ID=Parent_Plate.Primer_Plate_ID $extra_condition ORDER BY $order_by"
        );
    }
    else {

        # did not create a new Primer_Plate. Display
        @result_array = $dbc->Table_find(
            "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate",
            "FK_Solution__ID,'$new_sol_id',Well,Plate_Well,FK_Primer__Name",
            "WHERE ReArray_Request_ID=$rearray_id AND FKTarget_Plate__ID=FK_Plate__ID AND Primer_Plate_Well_ID=FK_Primer_Plate_Well__ID AND FK_Primer_Plate__ID=Primer_Plate_ID ORDER BY right(Plate_Well,2),left(Plate_Well,1)"
        );
    }

    my @remap_array = ();
    foreach my $info (@result_array) {
        my ( $source, $target, $source_well, $target_well, $primer_name ) = split ',', $info;

        # zero-pad the SOL ID for target and source
        $source = sprintf( "SOL%010d", $source );
        $target = sprintf( "SOL%010d", $target );
        push( @remap_array, "$source,$target,$source_well,$target_well,$primer_name" );
    }

    return \@remap_array;
}

###############################################################
# Subroutine: generates a string representation of the multiprobe control file, based on a primer remapping
# RETURN: an array, with each line representing a multiprobe line
###############################################################
sub _generate_primer_multiprobe {
    my %args = @_;
    my $id   = $args{-id};
    my $dbc  = $args{-dbc} || $Connection;

    # first, look to see if the primer plate's wells have parents
    # if it doesn't, then error out (cannot create multiprobe)
    # if it does, return the multiprobe array

    my @parent_plate_wells = $dbc->Table_find( "Primer_Plate_Well", "FKParent_Primer_Plate_Well__ID", "WHERE FK_Primer_Plate__ID in ($id)", -distinct => 1 );
    if ( ( !( int(@parent_plate_wells) > 0 ) ) || ( !( $parent_plate_wells[0] ) ) ) {
        Message("No parents available - not a remapped primer plate");
        return [];
    }

    # if it is remapped, query the remapping

    my @result_array = $dbc->Table_find(
        "Primer_Plate_Well as Target_Well,Primer_Plate_Well as Source_Well,Primer_Plate as Target_Plate, Primer_Plate as Source_Plate",
        "Source_Plate.FK_Solution__ID,Target_Plate.FK_Solution__ID,Source_Well.Well,Target_Well.Well,Target_Well.FK_Primer__Name",
        "WHERE Target_Plate.Primer_Plate_ID in ($id) AND Target_Plate.Primer_Plate_ID=Target_Well.FK_Primer_Plate__ID AND Target_Well.FKParent_Primer_Plate_Well__ID=Source_Well.Primer_Plate_Well_ID AND Source_Well.FK_Primer_Plate__ID=Source_Plate.Primer_Plate_ID ORDER BY right(Target_Well.Well,2),left(Target_Well.Well,1)"
    );

    my @remap_array = ();
    foreach my $info (@result_array) {
        my ( $source, $target, $source_well, $target_well, $primer_name ) = split ',', $info;

        # zero-pad the SOL ID for target and source
        $source = sprintf( "SOL%010d", $source );
        $target = sprintf( "SOL%010d", $target );
        push( @remap_array, "$source,$target,$source_well,$target_well,$primer_name" );
    }

    return \@remap_array;
}

###############################################################
# Subroutine: Generates an ordered array representing information needed for a multiprobe file
# RETURN: an array, with each line representing a multiprobe line
###############################################################
sub _generate_DNA_multiprobe {
###############################################################
    my %args       = &filter_input( \@_, -args => 'rearray_id' );
    my $rearray_id = $args{-rearray_id};                            # (Scalar) Rearray ID for this multiprobe
    my $dbc        = $args{-dbc} || $Connection;                    # (ObjectRef) Database handle

    my @result_array = $dbc->Table_find(
        "ReArray,ReArray_Request,Library_Plate,Plate",
        "concat(FK_Library__Name,'-',Plate_Number,Plate.Parent_Quadrant,'_',Source_Well),FKSource_Plate__ID,FKTarget_Plate__ID,Source_Well,Target_Well",
        "WHERE ReArray_Request_ID=$rearray_id AND FK_ReArray_Request__ID=ReArray_Request_ID AND FKSource_Plate__ID=Plate_ID AND FK_Plate__ID=Plate_ID ORDER BY right(Target_Well,2),left(Target_Well,1) ASC"
    );
    my @rearray_array = ();
    foreach my $info (@result_array) {
        my ( $sample_name, $source, $target, $source_well, $target_well ) = split ',', $info;

        # zero-pad the PLA ID for target and source
        $source = sprintf( "PLA%010d", $source );
        $target = sprintf( "PLA%010d", $target );
        push( @rearray_array, "$source,$target,$source_well,$target_well,$sample_name" );
    }
    return \@rearray_array;
}

return 1;
