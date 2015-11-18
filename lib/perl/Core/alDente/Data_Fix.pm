###################################################################################
# alDente::Data_Fix.pm
#
# Repository for data fix methods.
#
#
####################################################################################
package alDente::Data_Fix;
use base SDB::DB_Object;    ## remove this line if object is NOT a DB_Object

use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

use Benchmark;

## alDente modules

use vars qw( %Configs %Benchmark );

#####################
sub new {
#####################
    my $this = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id} || $args{-template_id};    ##

    my $self = {};                                   ## if object is NOT a DB_Object ... otherwise...
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        ## $self->add_tables();  ## add tables to standard object if applicable
        $self->primary_value( -table => 'Data_Fix', -value => $id );
        $self->load_Object();
    }

    return $self;
}

#############################################
sub redefine_original_plate_as_tubes {
#############################################
    my %args         = filter_input( \@_, -args => 'dbc,old_plate,library' );
    my $dbc          = $args{-dbc};
    my $old_plate_id = $args{-plate_id};

    my ($copy_info) = $dbc->Table_retrieve( 'Plate', [ 'FK_Library__Name', 'FK_Rack__ID', 'FK_Plate_Format__ID', 'FK_Pipeline__ID' ], "WHERE Plate_ID = $old_plate_id" );

    $dbc->start_trans('redefine');

    ### first aliquot original into Nx1 Tray ##
    if ( $old_plate_id && $copy_info->{Plate_ID}[0] eq $old_plate_id ) {
        my $ok = &alDente::Container_Set::plate_transfer_to_tube(
            -plate_id => $copy_info->{Plate_ID}[0],

            #   -quantity    => $transfer_quantity,
            #   -units       => $transfer_units,
            #   -lib         => $copy_info->{FK_Library__Name}[0],
            -rack => $copy_info->{FK_Rack__ID}[0],

            #   -plate_num   => $plate_num,
            -format => $copy_info->{FK_Plate_Format__ID}[0],

            #  -test        => $test_plate,
            -pipeline_id => $copy_info->{FK_Pipeline__ID}[0],
            -dbc         => $dbc,
        );
    }
    else {
        $dbc->error("Cannot redefine 'PLA $old_plate_id' (no records found)");
        return;
    }

    my $ok = 1;
    ## retrieve all plate / well pair references ##

    ## replace plate / well pair references ##

    ## delete_replace other records (SHOULD NOT BE ANYTHING THAT REFERENCES Plate without referencing Well ?)

    $dbc->finish_trans('redefine');

    return $ok;
}

################################################
sub replace_rearrayed_plate_with_tubes {
################################################
    my %args         = filter_input( \@_, -args => 'dbc,old_plate,library' );
    my $dbc          = $args{-dbc};
    my $old_plate_id = $args{-plate_id};
    my $library      = $args{-library};

    Message("\nREPLACE REARRAY\nP: $old_plate_id; L: $library\n");

    my ($plate_data) = $dbc->Table_find( 'Plate', 'FK_Plate_Format__ID,FK_Rack__ID,FK_Pipeline__ID,FK_Library__Name,Plate_Created,Plate.FK_Employee__ID', "WHERE Plate_ID=$old_plate_id" );
    my ( $old_format, $old_rack, $old_pipeline_id, $old_lib, $created, $creator ) = split ',', $plate_data;
    $dbc->set_local( 'user_id', $creator );

    print "\n** $plate_data **\n";

    ### ONLY retrieve Plates rearrayed from tubes...
    my %source_rearray_plates = $dbc->Table_retrieve(
        'Plate,ReArray_Request,ReArray, Plate as SrcPlate', [ 'FKSource_Plate__ID', 'Target_Well', 'Plate.FK_Plate_Format__ID', 'FKTarget_Plate__ID', 'Plate.Plate_Comments' ],
        "WHERE Plate.Plate_ID = ReArray_Request.FKTarget_Plate__ID and ReArray_Request_ID = FK_ReArray_Request__ID AND FKTarget_Plate__ID = $old_plate_id AND SrcPlate.Plate_ID = FKSource_Plate__ID AND SrcPlate.Plate_Size NOT IN ('8-well','16-well','32-well','48-well','64-well','80-well','96-well','384-well') ORDER BY Target_Well ASC",
        -distinct => 1,
        -debug    => 1
    );

    my $comments = "Replaced $old_plate_id;";

    Message("*** START *** Delete PLA$old_plate_id ***\n");
    $dbc->start_trans( "Delete PLA$old_plate_id", -message => 'Starting Transaction' );

    my @replacements = ();
    if ( defined $source_rearray_plates{Plate_Comments} ) {
        if ( $source_rearray_plates{Plate_Comments}[0] ) { $comments .= ' ' . $source_rearray_plates{Plate_Comments}[0] }
        print "** Found " . int( @{ $source_rearray_plates{FKSource_Plate__ID} } ) . " rearray records\n";

        my %Tube_values;
        $Tube_values{'Source_Plates'} = $source_rearray_plates{FKSource_Plate__ID};
        $Tube_values{'Target_Wells'}  = $source_rearray_plates{Target_Well};
        $Tube_values{'Plate_Format'}  = $old_format;
        $Tube_values{'Rack'}          = $old_rack;
        $Tube_values{'Plate_Created'} = $created;

        #    $Tube_values{'Application'} = $application;
        $Tube_values{'Library'}     = $library;
        $Tube_values{'Pipeline_ID'} = $old_pipeline_id;

        Message("Generating new tube records for previous ReArray -> $old_plate_id");
        ## use existing method for transferring tube -> tray (requires extra updating of Rack + Plate_Created info)
        my $created = &alDente::Container_Set::confirm_create_plate_from_tube( -dbc => $dbc, -track_as => 'Tray', -tube_data => \%Tube_values, -user_id => 4 );

        #
        # Change (?) to use standard transfer ? (independent of target / source size) if possible #
        #
        # (simulate manual rearray -> tube)...

        if ( !$created ) { Message("\n*** Aborted ***\n"); print HTML_Dump \%Tube_values; return; }

        @replacements = Cast_List( -list => $created, -to => 'array' );
        Message("\nReplacements:  @replacements\n");

        my $list = join ',', @replacements;
        my @tray = $dbc->Table_find( 'Plate_Tray', 'FK_Tray__ID', "WHERE FK_Plate__ID IN ($list)", -distinct => 1 );
        Message("Created TRA @tray from PLA $old_plate_id ($library)");
    }
    else {
        Message("\n*** NO Rearray found for $old_plate_id");
    }

    #print HTML_Dump $dbc->Table_retrieve('Plate',['*'],"WHERE Plate_ID = $replacements[0]");
    delete_old_plate( $dbc, $old_plate_id, $old_lib, $library, \@replacements );

    $dbc->finish_trans("Delete PLA$old_plate_id");
    Message("*** FINISH ***");
    return 1;
}

# Replaces aliquots to plate records with multiple tube -> tube transfers as required
#
# (includes recursive call to delete downstream plates as well if necessary... )
#
############################
sub _replace_aliquots {
############################
    my %args         = filter_input( \@_, -args => 'dbc,old_plate,library,replacements' );
    my $dbc          = $args{-dbc};
    my $old_plate_id = $args{-old_plate};
    my $library      = $args{-library};
    my $replace      = $args{-replacements};

    my @replacements = @$replace;

    ## create downstream replacement tubes if plate aliquoted to more plates ##
    my @aliquoted_plates = $dbc->Table_find( 'Plate', 'Plate.Plate_ID', "WHERE Plate.FKParent_Plate__ID=$old_plate_id AND Plate.Plate_Size IN ('8-well','16-well','32-well','48-well','64-well','80-well','96-well','384-well','1-well')" );

    Message("\nREPLACE ALIQUOTS\nP: $old_plate_id; L: $library; Replace: $replacements[0]..$replacements[-1];\n-> @aliquoted_plates\n");

    my $aliquoted = 0;
    foreach my $plate_info (@aliquoted_plates) {
        my ( $plate, $size ) = split ',', $plate_info;

        ## get basic target plate information to pass to transfer call ##
        my %aliquoted_plate_data = $dbc->Table_retrieve(
            'Plate,Plate_Sample',
            [ 'Plate_ID', 'Well', 'FK_Plate_Format__ID', 'FK_Rack__ID', 'FK_Employee__ID', 'FK_Pipeline__ID', 'Plate_Created', 'Plate_Size' ],
            "WHERE Plate.FKParent_Plate__ID = $old_plate_id AND Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID",
            -distinct => 1
        );

        Message("\nFound Aliquot -> $plate\n");
        if ( !$aliquoted_plate_data{Plate_ID}[0] ) { $dbc->message("\n*** No Aliquoted Plate Data in Plate_Sample table for PLA$old_plate_id ***"); next; }

        my ($old_lib) = $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID=$plate" );

        $dbc->set_local( 'user_id', $aliquoted_plate_data{FK_Employee__ID}[0] );

        #	print HTML_Dump 'Aliquoted:', \%aliquoted_plate_data;
        my %Tube_values;
        $Tube_values{'Source_Plates'} = \@replacements;
        $Tube_values{'Target_Wells'}  = $aliquoted_plate_data{Well};
        $Tube_values{'Plate_Format'}  = $aliquoted_plate_data{FK_Plate_Format__ID}[0];
        $Tube_values{'Rack'}          = $aliquoted_plate_data{FK_Rack__ID}[0];
        $Tube_values{'Plate_Created'} = $aliquoted_plate_data{Plate_Created}[0];

        #	$Tube_values{'Application'} = $application;
        $Tube_values{'Library'}     = $library;
        $Tube_values{'Pipeline_ID'} = $aliquoted_plate_data{FK_Pipeline__ID}[0];

        my $type = 'Tray';
        if ( $size eq '1-well' ) { $type = 'Tube' }
        Message("\nre-create plate from tube(s) ($type)");

        my $created = &alDente::Container_Set::confirm_create_plate_from_tube( -dbc => $dbc, -track_as => $type, -tube_data => \%Tube_values );

        my @next_replacements = Cast_List( -list => $created, -to => 'array' );
        Message( "\nReplaced ALIQUOT: $plate with " . int(@replacements) . " Replacements: @replacements\n" );

        my $aliquots = _replace_aliquots( $dbc, $plate, $library, \@next_replacements );
        Message("\n(replaced $aliquots aliquots for $plate)\n");

        ## to do ...
        ## Replace previous rearrays from this plate with rearray referencing new replacements... ##

        Message("\ndelete old plate $plate ($old_lib)");
        my $ok = delete_old_plate( $dbc, $plate, $old_lib, $library, \@next_replacements );
    }

    Message("\nReplaced $aliquoted Aliquots\n");
    return $aliquoted;
}

#
# Delete Plate records
#
#  If replacement tube records are supplied, this assumes that the replacement tubes are already recorded (and located in a set plate_position on a tray.
#   - in this case any downstream rearrays will point to the replacement tubes rather than the previous plate/well combinations.
#
###########################
sub delete_old_plate {
############################
    my $dbc          = shift;
    my %args         = filter_input( \@_, -args => 'old_plate,old_lib,library,replacements' );
    my $old_plate_id = $args{-old_plate};
    my $old_lib      = $args{-old_lib};
    my $library      = $args{-library};
    my $replace      = $args{-replacements};

    my @replacements = @$replace;
    Message("\nDELETE OLD PLATE\n$old_plate_id; L: $old_lib -> $library; $replacements[0]..$replacements[-1]");
    if (@replacements) { _replace_aliquots( $dbc, $old_plate_id, $old_lib, \@replacements ) }

    Message("\n** Deleting change history for old_plate ($old_plate_id) **");
    $dbc->delete_record( -table => 'Change_History', -field => 'Record_ID', -value => $old_plate_id, -condition => 'FK_DBField__ID IN (838,1219)' );

    my ($new_tray) = $dbc->Table_find( 'Plate_Tray', 'FK_Tray__ID', "WHERE FK_Plate__ID = $replacements[0]" );
    Message("\n** Convert PLA $old_plate_id -> TRA $new_tray ($replacements[0]...$replacements[-1]) **");

    $dbc->Table_update_array( 'Plate_Prep', ['FK_Plate__ID'], [ $replacements[0] ], "WHERE FK_Plate__ID='$old_plate_id'" );    ## replace Plate_Prep records with FIRST replacement ##
    $dbc->Table_update_array( 'Plate_Set',  ['FK_Plate__ID'], [ $replacements[0] ], "WHERE FK_Plate__ID='$old_plate_id'" );    ## replace Plate_Prep records with FIRST replacement ##

    ### Add copy of Plate_Prep records for each well after A01 ###
    $dbc->execute_command(
        "INSERT into Plate_Prep SELECT '',Plate_ID,FK_Prep__ID,FK_Plate_Set__Number,FK_Equipment__ID,FK_Solution__ID,Solution_Quantity,Solution_Quantity_Units,Transfer_Quantity,Transfer_Quantity_Units FROM Plate_Prep,Plate WHERE Plate_ID BETWEEN ($replacements[1]) AND $replacements[-1] AND Plate_Prep.FK_Plate__ID = $replacements[0]"
    );

    my ($new_tray) = $dbc->Table_find( 'Plate_Tray', 'FK_Tray__ID', "WHERE FK_Plate__ID = $replacements[0]" );
    foreach my $replacement (@replacements) {
        ## replaced source records referencing old plate with replacement tube ##
        my ($old_info) = $dbc->Table_find( 'Plate, Plate_Tray', 'Plate_Size,Plate_Position', "WHERE FK_Plate__ID = Plate_ID AND Plate_ID = $replacement" );
        my ( $old_size, $old_well ) = split ',', $old_info;

        #	if ($old_size =~ /well$/ && $old_size ne '1-well') { }
        #	else { $old_well = 'N/A' }

        my $fixed = $dbc->Table_update_array( 'ReArray', [ 'FKSource_Plate__ID', 'Source_Well' ], [ $replacement, 'N/A' ], "WHERE FKSource_Plate__ID='$old_plate_id' and Source_Well IN ('$old_well','N/A')", -autoquote => 1 );

## replace Plate_Prep records with FIRST replacement ##
        #	Message("S: $old_plate_id ($old_size : $old_well) -> $replacement [fixed $fixed]");
        #	print HTML_Dump $dbc->Table_find('Plate LEFT JOIN Plate_Tray ON FK_Plate__ID=Plate_ID','Plate_ID,Plate_Size,Plate_Position',"WHERE Plate_ID = $replacement");

        if   ( $replacement eq $replacements[0] || $replacement eq $replacements[-1] ) { Message("\n Replace $old_plate_id ($old_well) with $replacement") }
        else                                                                           { print '.' }
    }

    #    print HTML_Dump $dbc->Table_retrieve('ReArray',['FKSource_Plate__ID', 'Source_Well'],"WHERE FKSource_Plate__ID='$old_plate_id'");

    my $replacement_list = Cast_List( -list => \@replacements, -to => 'string' );
    $dbc->execute_command(
        "INSERT INTO Plate_Set (FK_Plate__ID, Plate_Set_Number, FKParent_Plate_Set__Number) SELECT Plate_ID, Plate_Set_Number, FKParent_Plate_Set__Number FROM Plate,Plate_Set WHERE Plate_ID IN ($replacement_list) AND Plate_ID != $replacements[0] AND Plate_Set.FK_Plate__ID=Plate_ID"
    );

    $dbc->delete_record( -table => 'Change_History', -field => 'Record_ID', -value => $old_plate_id, -condition => 'FK_DBField__ID IN (838,1219)' );    ## Plate_Number, Rack changes removed...
    Message("\n** DELETING PLA $old_plate_id and Lib: $old_lib **");
    my $ok = &alDente::Container::Delete_Container( -dbc => $dbc, -ids => $old_plate_id, -confirm => 1 );

    my $delete_lib = 0;                                                                                                                                 ## suppress deletion of libraries until later to avoid rollback ##
    Message("\n** Delete Library: $old_lib [$delete_lib] **");
    if ($delete_lib) {
        ## delete library if no more records referencing it...##
        $dbc->delete_records( -table => 'Work_Request', -dfield => 'FK_Library__Name', -cascade => ['Material_Transfer'], -id_list => $old_lib, -condition => 'FK_Goal__ID=7' );    ## No defined Goals record removed ##
        $dbc->delete_records( -table => 'Library', -dfield => 'Library_Name', -id_list => $old_lib, -cascade => [ 'Library_Source', 'RNA_DNA_Collection' ] );
    }

    ## adjust the rearray to point from the tube to the pool MX library
    return $ok;
}

#
#
#
################################
sub regenerate_Source_Numbers {
################################
    my $self = shift;
    my $dbc  = $self->{'dbc'};

    print HTML_Dump $self;

    Message("fix all NULL OS references");
    $dbc->execute_command("update Source set FKParent_Source__ID = NULL WHERE FKParent_Source__ID = 0");
    $dbc->execute_command("UPDATE Source SET FKOriginal_Source__ID = CASE WHEN FKParent_Source__ID > 0 THEN FKParent_Source__ID ELSE Source_ID END WHERE FKOriginal_Source__ID IS NULL");

    my @missing_parent1 = $dbc->Table_find( 'Source', 'Source_ID', "WHERE FKOriginal_Source__ID != Source_ID AND FKParent_Source__ID = 0" );
    my @missing_parent2 = $dbc->Table_find( 'Source', 'Source_ID', "WHERE FKOriginal_Source__ID != Source_ID AND FKParent_Source__ID IS NULL" );

    if ( @missing_parent1 || @missing_parent2 ) {
        $dbc->warning("Missing Parent Record !!");
        print Cast_List( -list => [ @missing_parent1, @missing_parent2 ], -to => 'ol' );
    }

    ### Ensure FKOriginal_Source__ID references source with no parent ##
    my @fix_OS = $dbc->Table_find_array( 'Source LEFT JOIN Source as OS ON Source.FKOriginal_Source__ID=OS.Source_ID', [ 'Source.Source_ID', 'OS.FKParent_Source__ID' ], "WHERE OS.FKParent_Source__ID > 0" );
    while (@fix_OS) {
        ## recursively update OS where OS has a parent ##
        foreach my $fix (@fix_OS) {
            my ( $s_id, $os_p ) = split ',', $fix;
            $dbc->execute_command("UPDATE Source SET FKOriginal_Source__ID=$os_p WHERE Source_ID = $s_id");
            Message("Fixed $s_id -> $os_p");
        }
        @fix_OS = $dbc->Table_find_array( 'Source LEFT JOIN Source as OS ON Source.FKOriginal_Source__ID=OS.Source_ID', [ 'Source.Source_ID', 'OS.FKParent_Source__ID', 'OS.FKOriginal_Source__ID', 'OS.Source_ID' ], "WHERE OS.FKParent_Source__ID > 0" );
    }

    ## Now that the ancestry is corrected, fix the Source Numbers.. ##

    my ( @repeat_sn, @num_conflict );

    ## Single Original Src records only ... ensure Source_Number = 1 or P1 .. ##
    my @check_os = $dbc->Table_find(
        'Original_Source,Source LEFT JOIN Source_Pool ON Source_Pool.FKChild_Source__ID=Source_ID',
        'Original_Source_ID,Source_Number,Source_Pool_ID',
        "WHERE Source.FK_Original_Source__ID=Original_Source_ID AND Source.FKOriginal_Source__ID=Source_ID GROUP BY Source_ID ORDER BY Original_Source_ID, Source_Number"
    );

    my %OS;
    foreach my $os (@check_os) {
        my ( $os, $sn, $pool ) = split ',', $os;

        if ( $OS{"$os.$sn"} ) {
            push @repeat_sn, $os;
            next;
        }
        $OS{"$os.$sn"}++;
        $OS{$os}++;

        my $num;
        my $prefix = '';

        if ($pool) { $prefix = 'P' }

        if ( $sn =~ /^$prefix(\d+)$/ ) { $num = $1 }

        if ( $num && $num <= $OS{$os} ) {
            ## ok ##
        }
        else {
            push @num_conflict, $os;
        }
    }
    my @fix_os = ( @repeat_sn, @num_conflict );
    Message( "repeat sn: " . int(@repeat_sn) );
    Message("@repeat_sn");

    Message( "sn wrong: " . int(@num_conflict) );
    Message("@num_conflict");

    #   print Cast_List(-list=>\@fix_os, -to=>'OL');
    ## Original Pooled Src records... ensure Source_Number = 'P*' ##

    my @conflict_os = $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "WHERE Source.FKOriginal_Source__ID=Source_ID GROUP BY FK_Original_Source__ID,Source_Number HAVING COUNT(*) > 1", -distinct => 1 );
    Message( "Found " . int(@conflict_os) . ' OS with Source_Number conflicts to regenerate' );
    Message("@conflict_os");

    #   print Cast_List(-list=>\@fix_os, -to=>'OL');

    my %Fixed;
    my $conflicts = 0;
    my @os_fixes  = ();
    foreach my $os ( @fix_os, @conflict_os ) {
        if ( $Fixed{$os} ) {next}
        $Fixed{$os}++;

        my %Src = $dbc->Table_retrieve(
            'Source LEFT JOIN Sample_Type ON FK_Sample_Type__ID=Sample_Type_ID',
            [ 'Source.Source_ID', 'Source_Number', 'FK_Sample_Type__ID', 'Sample_Type' ],
            "WHERE FK_Original_Source__ID= '$os' AND FKOriginal_Source__ID=Source_ID"
        );
        if ( $Src{Source_Number} && int( @{ $Src{Source_Number} } ) == 1 && $Src{Source_Number}[0] == '1' ) {
            print '.';
            next;
        }
        else {
            my $fail = 0;
            my $i    = 0;

            # $dbc->warning("OS: $os");
            my @sources = ();
            while ( defined $Src{Source_ID}[$i] ) {
                push @sources, "$Src{Source_ID}[$i]: $Src{Source_Number}[$i]-$Src{Sample_Type}[$i]";
                if ( $Src{Source_Number}[$i] == $i + 1 ) {
                    ## ok... continue ... ##
                }
                else {
                    $fail++;
                }

                # Message("SRC$Src{Source_ID}[$i] : $Src{Source_Number}[$i] - $Src{Sample_Type}[$i]");
                $i++;
            }
            if ($fail) {
                if ( grep /^$os$/, @conflict_os ) {
                    $dbc->warning("OS $os NUMBER CONFLICT");
                    push @os_fixes, $os;
                    $conflicts++;
                }
                else { $dbc->warning("OS $os Warning (no number conflict) - okay...") }
                print Cast_List( -list => \@sources, -to => 'OL' );
            }
        }
    }

    Message( "Fixing Source Numbers for OS: " . int(@os_fixes) );
    Message("@os_fixes");

    foreach my $os (@os_fixes) {
        my @srcs = $dbc->Table_find_array(
            'Source LEFT JOIN Source as Parent ON Source.FKParent_Source__ID=Parent.Source_ID LEFT JOIN Source_Pool ON Source.Source_ID=FKChild_Source__ID',
            [ 'Source.Source_ID', 'Source.Source_Number', 'Parent.Source_Number', 'Source_Pool_ID' ],
            "WHERE Source.FK_Original_Source__ID = '$os' AND Source.Source_ID = Source.FKOriginal_Source__ID GROUP BY Source.Source_ID ORDER BY Source.Received_Date, Source.Source_Number, Source.Source_ID"
        );

        my $index      = 1;
        my $pool_index = 1;
        foreach my $src (@srcs) {
            my ( $sid, $snum, $pnum, $pool ) = split ',', $src;

            if ($pnum) { $dbc->warning("Parent source found for Original SRC") }
            elsif ( !$pool ) {
                if ( $snum eq $index ) { $dbc->message("OS $os: original Src $sid ($index)") }
                else {
                    $dbc->Table_update( 'Source', 'Source_Number', $index, "WHERE Source_ID = $sid" );
                    $dbc->warning("OS $os: original Src$sid ($snum -> $index)");
                }
                $index++;
            }
            elsif ($pool) {
                if ( $snum eq 'P' . $pool_index ) { $dbc->message("$os: P$pool_index") }
                else {
                    $dbc->Table_update( 'Source', 'Source_Number', 'P' . $pool_index, "WHERE Source_ID = $sid", -autoquote => 1 );
                    $dbc->warning("OS $os: original Src$sid ($snum -> P$pool_index)");
                }
                $pool_index++;
            }
            else {
                $dbc->warning("Error: both Parent ($pnum) and Source_Pool ($pool) found for original Src $sid");
            }
        }
    }

    ## at this point original sources should all be okay... now correct downstream numbers where required... ##
    Message("Downstream NUMBER FIXING ONLY");
    my @fix_src = $dbc->Table_find_array(
        'Source, Source as Parent',
        [ 'Parent.Source_ID', 'Parent.FK_Original_Source__ID' ],
        "where Parent.Source_ID = Source.FKParent_Source__ID AND  Length(Replace(Source.Source_Number,Concat(Parent.Source_Number,'.'),''))+Length(Parent.Source_Number)+1 != Length(Source.Source_Number) ORDER BY Parent.Source_ID",
        -distinct => 1
    );

    Message( "fix src numbers:" . int(@fix_src) );
    Message("@fix_src");

    #    print Cast_List(-list=>\@fix_num, -to=>'OL');

    foreach my $src (@fix_src) {
        my ( $sid, $osid ) = split ',', $src;
        $self->correct_Source_Number( $sid, $osid );
    }

    return;
}

#############################
sub correct_Source_Number {
#############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'source_id, original_source_id' );
    my $source_id = $args{-source_id};
    my $os        = $args{-original_source_id};

    my $dbc = $self->{'dbc'};

    my @srcs = $dbc->Table_find_array(
        'Source, Source as Parent',
        [ 'Source.FK_Original_Source__ID', 'Source.Source_ID', 'Source.Source_Number', 'Parent.Source_Number' ],
        "WHERE  Source.FKParent_Source__ID=Parent.Source_ID AND Parent.Source_ID = $source_id AND Parent.FK_Original_Source__ID=$os ORDER BY Source.Received_Date, Source.Source_Number, Source.Source_ID"
    );

    my $index = 1;
    foreach my $src (@srcs) {
        my ( $os, $sid, $snum, $pnum ) = split ',', $src;

        my $nextnum = $pnum . '.' . $index++;

        if ( $snum eq $nextnum ) { $dbc->message("Src$sid: $snum") }
        else {
            $dbc->Table_update( 'Source', 'Source_Number', $nextnum, "WHERE Source_ID = $sid", -autoquote => 1 );
            $dbc->warning("OS $os - Src$sid ($snum -> $nextnum)");
            $self->correct_Source_Number( $sid, $os );    ## recursively correct for downstream sources ...
        }
    }

    return;
}

1;
