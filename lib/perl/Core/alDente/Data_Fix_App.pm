############################
# alDente::Data_Fix_App.pm #
#
# Repository for data fix methods.
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Data_Fix_App;
use base alDente::CGI_App;
use strict;

## Local modules required ##

use RGTools::RGIO;

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

#use CGI qw(:standard);

## global_vars ##
use vars qw(%Configs);

my $dbc;
my $q;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'              => 'home_page',
            'Home Page'            => 'home_page',
            'Load File Attributes' => 'load_file_attributes',
            'Test Stats'           => 'test_Stats',
            'Update'               => 'multi_table_update',
            'Fix_TCGA'             => 'fix_TCGA',
            ,
            'Test Trigger'          => 'test_trigger',
            'Flag Replacement'      => 'flag_Replacement',
            'Fix Duplicate Sources' => 'fix_duplicate_Sources',
            'Delete Plates'         => 'delete_Plate',
            'view JIRA'             => 'view_Jira_tickets',
        }
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    my $id = $q->param("Data_Fix_ID");    ### Load Object by default if standard _ID field supplied.
    $self->param( 'dbc' => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}
###################
sub test_Stats {
###################
    my $self = shift;

    use alDente::Stats_Table;

    my $Tab = alDente::Stats_Table->new( -title => 'testeer' );
    $Tab->Set_Row( [ 125, 3, 5,     6.5 ] );
    $Tab->Set_Row( [ 125, 3, 5,     6.5 ] );
    $Tab->Set_Row( [ 125, 3, 5,     6.5 ] );
    $Tab->Set_Row( [ 124, 3, 5,     6.5 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 123, 5, 7.1.6, 22.1 ] );

    print $dbc->Table_retrieve_display( 'Employee', ["Employee_Name as Basics"], "WHERE Employee_Name like 'R%'", -return_html => 1 );

    $Tab->add_Stats( { '1' => 'histogram', '2' => 'min,max,stddev', '4' => 'Count,Sum,Avg,N,stddev,median' }, 'mediumbluebw' );
    return $Tab->Printout(0);

}

##################
sub home_page {
##################
    my $self = shift;
    Message("HOME PAGE");

    my $view = $self->param('Data_Fix_View');

    return $view->home_page();
}

#
#
# eg '&cgi_application=Data_Fix_App&rm=Load File Attributes&File=/home/sequence/Trash/GSCTS.txt'
#
##############################
sub load_file_attributes {
##############################
    my $self = shift;

    my $file = $q->param('File');

    my $production_dbc = SDB::DBIO->new( -dbase => 'sequence', -host => 'lims02', -user => 'rguin', -password => '', -connect => 1 );
    print HTML_Dump $production_dbc;

    open my $FILE, '<', $file or die "Cannot open $file";

    ## based upon input columns:  '',plate_id, well, '', amplicon_length
    my %list;
    while (<$FILE>) {
        my $line = $_;
        my ( $plate, $plate_id, $well, $patient, $amp ) = split "\t", $line;
        chomp $amp;
        if ( $well && $amp && $plate_id =~ /pla(\d+)/ ) {
            my $id = $1;
            $amp =~ /(\d+)/;
            $amp = $1;
            my $sample = join ',', $production_dbc->Table_find( 'Plate_Sample', 'FK_Sample__ID', "WHERE FKOriginal_Plate__ID=$id AND Well = '$well'" );

            #	    Message("Set $id ($well) Sample $sample -> $amp");
            $list{$sample} = $amp;
        }
    }
    my $fback = &alDente::Attribute::set_attribute( '', -dbc => $production_dbc, -attribute => 'Amplicon_Length', -object => 'Sample', -list => \%list, -debug => 1, -fk_employee_id => 150 );
    Message("F: $fback");
    return 1;
}

###################
sub test_Stats2 {
###################
    my $self = shift;

    use alDente::Stats_Table;

    my $Tab = alDente::Stats_Table->new( -title => 'testeer' );
    $Tab->Set_Row( [ 125, 3, 5,     6.5 ] );
    $Tab->Set_Row( [ 125, 3, 5,     6.5 ] );
    $Tab->Set_Row( [ 125, 3, 5,     6.5 ] );
    $Tab->Set_Row( [ 124, 3, 5,     6.5 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 122, 4, 8.1.5, 22.1 ] );
    $Tab->Set_Row( [ 123, 5, 7.1.6, 22.1 ] );

    $Tab->add_Stats( { '1' => 'histogram', '4' => 'Count,Sum,Avg,N' }, 'mediumbluebw' );
    return $Tab->Printout(0);

}

######################
sub tmp_test_system_check {
#####################
    my $self = shift;

    use alDente::System;
    my $system = alDente::System->new( -dbc => $dbc );

    #    my $watched = $system->get_watched_directories(-scope=>'shared');

    #    $system -> check_directory_usage (-host => 'shared', -directory => '/home/aldente/versions/rguin/www/*', -max_depth=>1, -threshold=>'10M', -log=>1);
    #    $system->log_directory_usage(-host=>'shared',-threshold=>'10M');
    #    $system -> get_directory_usage('shared');

    my $system_view = alDente::System_Views->new( -dbc => $dbc );
    $system_view->{'System'} = $system;

    my @files = split "\n", `find /home/aldente/private/logs/sys_monitor/shared/dirs/ -mtime +8 -type f`;

    #    @files = ("/home/aldente/private/logs/sys_monitor/shared/dirs/::home::aldente::public::logs::shipping_manifolds.stats");
    foreach my $file (@files) {
        my $now = `cat $file`;
        Message($file);
        Message($now);
        alDente::System::_fix_stat_file( $file, ['Size(K)'], 1024 * 1024, '\(K\)' );
        $now = `cat $file`;
        Message($now);
    }

    #    print $system_view->show_Directories('shared');

    return 1;
}

###################
sub check_dir {
###################
    my $self = shift;

    my @hosts = ('lims03');

    foreach my $host (@hosts) {
        my @files = split "\n", `ls -alt $Configs{Sys_monitor_dir}/$host/dirs/*.stats`;
        Message("$host files:");
        foreach my $file (@files) {
            Message("F: $file");
            my $filename;
            if ( $file =~ /(\S+).stats$/ ) { $filename = "$1.stats" }
            my $tempfile = "$Configs{Sys_monitor_dir}/tmp.txt";
            open my $TMP, '>', $tempfile;

            #	    open my $FILE ,'<', $filename;
            Message("OPENING $filename");
            my @lines = split "\n", `cat $filename`;
            if ( $lines[0] !~ /Date/ ) { print $TMP "Date\tSize(K)\n" }
            foreach my $line (@lines) {
                if ( $line =~ /Size/ ) { $line =~ s/\(G\)/\(K\)/ }
                elsif ( $line =~ /2010\-07\-07/ ) { }
                elsif ( $line =~ /(\d\d\d\d\-\d\d\-\d\d)\s+([0\d\.]+)/ ) {
                    my $date      = $1;
                    my $size      = $2;
                    my $real_size = $size;
                    if ( $real_size < 1000 ) { $real_size = int( $real_size * 1024 * 1024 ); Message("boost"); }
                    $line =~ s /\t$size\b/\t$real_size/;
                }
                else { Message("HUH ? : $line") }

                #		Message("L: $line");
                print $TMP "$line\n";
            }
            close $TMP;
            print `chgrp $tempfile lims`;
            print `chgrp $filename lims`;
            print `chmod 774 $filename`;
            print `chmod 774 $tempfile`;
            print `mv $filename $filename.old`;
            print `cp $tempfile $filename`;

            #	    `rm $tempfile`;
            Message("mv $tempfile $filename");

            #	    close $FILE;

            if ( $file !~ /Jan\s+[78]\s/ ) {
                Message("Stopping at $file..");
                last;
            }
        }
    }

    return 1;
}

##########################
sub flag_Replacement {
##########################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $ids = $q->param('Source_ID');

    Message("check if SRC(s) $ids is/are replacement");

    use alDente::Source;

    my $replacements = 0;
    foreach my $id ( split ',', $ids ) {
        $replacements += alDente::Source->is_Replacement( -dbc => $dbc, -id => $id );
    }

    if ($replacements) {
        $dbc->message("$replacements Replacement identified");
    }
    else {
        $dbc->message("No identified as replacements");
    }

    return;
}

################################
sub fix_preprinted_plates {
################################
    my $self = shift;
    my $bcg = SDB::DBIO->new( -dbase => 'bcg', -user => 'super_cron_user', -host => 'hblims01', -connect => 1 );

    my @plates = $bcg->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_Status = 'Pre-Printed' and Plate_Created < '2010-01-13' AND FK_Rack__ID < 3", -debug => 1 );

    Message( "Found " . int(@plates) . " preprinted plates" );
    foreach my $plate (@plates) {
        my ($details) = $bcg->Table_find_array(
            'Plate, Plate as Parent',
            [ 'Plate.Plate_ID', 'Parent.Plate_ID as Parent', 'Plate.FK_Rack__ID', 'Parent.FK_Rack__ID as Parent_Rack' ],
            "WHERE Plate.FKParent_Plate__ID=Parent.Plate_ID AND Plate.Plate_ID = $plate",
            -return_html => 1
        );

        my ( $pl, $pa, $pl_r, $pa_r ) = split ',', $details;

        if ( $pl_r > 10 ) {

            # $bcg->Table_update_array('Plate',['Plate_Status'],['Active'],"WHERE Plate_ID = $pl",-autoquote=>1);
            # $bcg->Table_update_array('Plate',['Plate_Status','FK_Rack__ID'],['Thrown Out',2], " WHERE Plate_ID = $pa", -autoquote=>1);
            Message("X $pl");
        }
        else {
            my ($info) = $bcg->Table_find_array( 'Plate', [ 'Plate_Label', 'FK_Sample_Type__ID', 'FK_Plate_Format__ID', 'FK_Rack__ID' ], "WHERE Plate_ID = $pl" );

            my ( $label, $sample, $format ) = split ',', $info;
            Message("I: $info");
            my ($existing) = $bcg->Table_find( 'Plate', 'count(*)', "WHERE Plate_Label = '$label' AND FK_Sample_Type__ID=$sample AND FK_Plate_Format__ID=$format AND Plate_Status = 'Active' AND FK_Rack__ID > 100" );

            if ( $existing == 6 ) {
                $bcg->delete_records( -table => 'Plate', -field => 'Plate_ID', -id_list => $pl, -cascade => [ 'Tube', 'Plate_Set' ] );

                #		Message("DELETE $pl");
            }
            Message("Cannot activate $details [$label : $sample : $format] ($existing currently OK) - delete $pl ?");
        }

        #	last;

        #	Message("$plate: $details");
        #	last;
    }

    return 1;
}

##########################
sub multi_table_update {
##########################
    my $self = shift;

    my $table     = $q->param('Table')     || 'Employee LEFT JOIN Department ON FK_Department__ID=Department_ID';
    my $field     = $q->param('Field')     || 'Initials, Email_Address';
    my $value     = $q->param('Value')     || 'SC, rguin4';
    my $condition = $q->param('Condition') || "FK_Department__ID = Department_ID AND Department_Name like 'LIMS Admin' AND Employee_Name = 'Ran'";

    my @fields = split ',', $field;
    my @values = split ',', $value;

    my $ok = $dbc->Table_update_array( $table, \@fields, \@values, "WHERE $condition", -debug => 1, -autoquote => 1 );

    return 1;

}

#################
sub fix_TCGA {
#################
    my $self = shift;

    my $debug = $q->param('Debug');
    Message("FIX TCGA Samples");

    my @os_ids = $dbc->Table_find_array(
        'Sample, Source, Original_Source, Sample_Attribute',
        [ 'Original_Source_ID', 'FK_Contact__ID', 'Original_Source_Name', 'FKCreated_Employee__ID', 'Defined_Date', 'FK_Tissue__ID' ],
        "WHERE FK_Source__ID = Source_ID and FK_Original_Source__ID=Original_Source_ID AND Sample_Attribute.FK_Sample__ID = Sample_ID AND FK_Attribute__ID = 240 AND Attribute_Value like 'TCGA%' AND FK_Patient__ID IS NULL",
        -distinct => 1,
        -debug    => $debug
    );

    Message( "Found " . int(@os_ids) . ' applicable OS ids' );

    foreach my $os (@os_ids) {
        my ( $os_id, $contact_id, $os_name, $created, $defined, $tissue ) = split ',', $os;
        my @os_records = $dbc->Table_find_array(
            'Sample, Source, Original_Source LEFT JOIN Sample_Attribute ON Sample_Attribute.FK_Sample__ID = Sample_ID AND FK_Attribute__ID = 240',
            [ 'Count(*) as Samples', 'Sample_Name', 'Original_Source_ID', 'Source_ID', 'Original_Source_Name', 'Attribute_Value as patient', 'Received_Date', 'FKReceived_Employee__ID', 'Source.FK_Rack__ID', 'FK_Barcode_Label__ID', 'FK_Plate_Format__ID' ],
            "WHERE FK_Source__ID = Source_ID and FK_Original_Source__ID=Original_Source_ID AND Original_Source_ID = $os_id GROUP BY Sample_ID ORDER BY Sample_ID",
            -debug => $debug
        );

        $dbc->start_trans('fixer');
        my ( $sample_updates, $source_updates, $plate_updates ) = ( 0, 0, 0 );
        my $i = 1;

        foreach my $os_info (@os_records) {
            my ( $N, $sample, $os2, $source, $os_name, $patient, $received, $by, $rack, $barcode, $format ) = split ',', $os_info;

            Message("found $N patient $patient records");
            my $existing;
            if ( $patient =~ /^(TCGA\-\w\w\-\d\d\d\d)\-/ ) {
                my $patient_id = $1;
                ($existing) = $dbc->Table_find( 'Patient', 'Patient_ID', "WHERE Patient_Identifier = '$patient_id'" );

                if ( !$existing ) {
                    $existing = $dbc->Table_append_array( 'Patient', ['Patient_Identifier'], [$patient_id], -autoquote => 1 );
                    Message("Add patient $existing ($patient_id)");
                }
            }
            else {
                Message("Patient not identified ( $sample : '$patient' )");
            }
            if ( $N > 1 ) {
                Message("MORE THAN 1 ($N) with patient_id: $patient");
                Message("$N : $sample : $os : $source : $os_name : $patient...");
                next;
            }
            else {
                Message("$N : $sample : $os : $source : $os_name : $patient...");
            }

            my $new_os = $dbc->Table_append_array(
                'Original_Source', [ 'FK_Contact__ID', 'Original_Source_Name', 'FKCreated_Employee__ID', 'Defined_Date', 'FK_Tissue__ID', 'FK_Patient__ID' ],
                [ $contact_id, "$os_name.$i", $created, $defined, $tissue, $existing ],
                -autoquote => 1,
                -debug     => 1
            );

            my $new_source = $dbc->Table_append_array(
                'Source',
                [ 'External_Identifier', 'Source_Type',    'Source_Status', 'FK_Original_Source__ID', 'Received_Date', 'FKReceived_Employee__ID', 'FK_Rack__ID', 'Source_Number', 'FK_Barcode_Label__ID', 'FK_Plate_Format__ID' ],
                [ $patient,              'RNA_DNA_Source', 'Active',        $new_os,                  $received,       $by,                       $rack,         $i,              $barcode,               $format ],
                -autoquote => 1,
                -debug     => 1
            );

            Message("OS: $new_os; S: $new_source");
            $i++;

            $dbc->Table_append_array( 'RNA_DNA_Source', [ 'FK_Source__ID', 'Nature', 'Storage_Medium' ], [ $new_source, 'Total RNA', 'DEPC Water' ], -autoquote => 1 );

            $plate_updates += $dbc->Table_update_array(
                'Library,Plate,Plate_Sample,Sample',
                ['FK_Original_Source__ID'],
                [$new_os], "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate_ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Plate.FK_Library__Name = Library_Name AND Sample_Name = '$sample'"
            );
            $sample_updates += $dbc->Table_update_array( 'Sample', ['FK_Source__ID'], [$new_source], "WHERE Sample_Name = '$sample'", -autoquote => 1 );
            $source_updates += $dbc->Table_update_array( 'Source', ['Notes'], ["Concat(Notes,' ','Previously tied to $sample')"], "WHERE Source_ID = $source", -autoquote => 1 );

#	    my $done = $dbc->execute_command("Update Sample,Sample as Orig, ReArray, ReArray_Request, Plate_Sample SET Sample.FKParent_Sample__ID=Orig.Sample_ID, Sample.Sample_Type='Clone', Orig.Sample_Type='Original', Sample.FK_Source__ID=Orig.FK_Source__ID where Orig.Sample_ID = ReArray.FK_Sample__ID AND ReArray.FK_ReArray_Request__ID = Rearray_Request_ID and ReArray_Request.FKTarget_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND ReArray.Target_Well = Plate_Sample.Well AND Plate_Sample.FK_Sample__ID = Sample.Sample_ID AND Sample.Sample_Name = '$sample' AND Sample.FKParent_Sample__ID = 0");
        }

        $dbc->finish_trans('fixer');
        Message("Warning: Updated $sample_updates Samples; $source_updates Sources for $os");

        #	last;
    }

    Message("EXTRA...");
    my $done
        = $dbc->execute_command(
        "Update Sample,Sample as Orig, ReArray, ReArray_Request, Plate_Sample SET Sample.FKParent_Sample__ID=Orig.Sample_ID, Sample.Sample_Type='Clone', Orig.Sample_Type='Original', Sample.FK_Source__ID=Orig.FK_Source__ID where Orig.Sample_ID = ReArray.FK_Sample__ID AND ReArray.FK_ReArray_Request__ID = Rearray_Request_ID and ReArray_Request.FKTarget_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND ReArray.Target_Well = Plate_Sample.Well AND Plate_Sample.FK_Sample__ID = Sample.Sample_ID AND Sample.Sample_Name like 'A00%' AND Sample.FKParent_Sample__ID = 0"
        );

    Message("Did $done");
    return;

}

######################
sub test_trigger {
######################
    my $self  = shift;
    my $q     = $self->query();
    my $dbc   = $self->param('dbc');
    my $debug = $q->param('Debug');
    my $ids   = $q->param('ID');

    print "testing accordion...";

    use LampLite::Bootstrap();
    my $BS = new Bootstrap();
    
#    print SDB::HTML::accordion( -layers => { 'A' => 'A text', 'B' => 'B text' } );
    
    print '<hr>';
    print "<Table><TR><TD>CELL 1</TD></TR>\n";
    
    print $BS->accordion( -layers => [ {'<TR><TD>A</TD></TR>' => '<TR><TD>Row A text</TD></TR>'}, {'<TR><TD>B</TD></TR>' => '<TR><TD>Row B text</TD></TR>'}] );

    print "</Table>\n";
    return 'ok';
}

######################
sub delete_Plate {
######################
    my $self      = shift;
    my $q         = $self->query();
    my $dbc       = $self->param('dbc');
    my $debug     = $q->param('Debug');
    my $ids       = $q->param('ID');
    my $confirmed = $q->param('Confirm');

    use alDente::Container;
    if ($ids) {
        &alDente::Container::delete_Container( -dbc => $dbc, -ids => $ids, -confirm => $confirmed );
    }

    return;
}

#
#
###############################
sub fix_duplicate_Sources {
###############################
    my $self = shift;
    my $q    = $self->query();

    my $debug = $q->param('Debug');

    my $confirmed = 1;
    my %plates    = $dbc->Table_retrieve(
        'Plate,Sample,Source',
        [ 'count(*) AS Count', 'Min(Plate_ID) as MinPlate', 'Max(Plate_ID) as MaxPlate', 'Plate_Label', 'External_Identifier', 'Min(Source_ID) as MinSource', 'Max(Source_ID) as MaxSource' ],
        "WHERE Sample.FK_Source__ID=Source_ID AND Sample.FKOriginal_Plate__ID=Plate_ID group by External_Identifier having count(*)>1 ORDER BY Plate_ID",
        -debug => $debug
    );

    my @plate_deletions;
    my @src_deletions;

    print SDB::HTML::display_hash( -dbc => $dbc, -hash => \%plates, -return_html => 1, -title => 'Duplicate Sources Found' );

    my $duplicate_rack = 15;    ### Rack where duplicates seem to be showing up.... ###

    my $deleted = 0;

    my $bulk = 0;               ## set to 1 to delete together - faster, but will rollback if any fail ##
    if ($bulk) { $dbc->start_trans('deleted') }

    my $index = 0;
    while ( defined $plates{MaxPlate}[$index] ) {
        my $plate    = $plates{MaxPlate}[$index];
        my $source   = $plates{MaxSource}[$index];
        my $good_src = $plates{MinSource}[$index];
        my $count    = $plates{Count}[$index];
        my $ext_id   = $plates{External_Identifier}[$index];
        $index++;

        if ( $count == 1 || $count > 3 ) {
            Message("Skipping PLA $plate (SRC $source) - count = $count");
            next;
        }
        if ( !$ext_id ) {
            Message("No EXT ID supplied - duplicates okay ....");
            next;
        }

        $dbc->start_trans('single_delete');
        my @confirm = $dbc->Table_find( 'Plate', 'FK_Rack__ID', "WHERE Plate_ID = $plate OR FKParent_Plate__ID= $plate" );
        my ($confirm2) = $dbc->Table_find( 'Sample', 'FK_Source__ID', "WHERE FKOriginal_Plate__ID=$plate" );

        if ( int(@confirm) == 1 && $confirm[0] == $duplicate_rack && $confirm2 == $source ) {
            Message("****************** DELETING $plate SRC $confirm2 <- $good_src *******************************");
            push @plate_deletions, $plate;
            push @src_deletions,   $source;
            my $ok = $dbc->Table_update( 'Source_Attribute', 'FK_Source__ID', $good_src, "WHERE FK_Source__ID=$source", -debug => 1 );
            $dbc->delete_record( -table => 'Change_History', -field => 'Record_ID', -value => $plate,  -condition => 'FK_DBField__ID IN (1224,1219)' );
            $dbc->delete_record( -table => 'Change_History', -field => 'Record_ID', -value => $source, -condition => 'FK_DBField__ID IN (2360,2368,2369)' );
            Message("Updated $ok Source_Attributes -> $good_src");
            $deleted++;

            if ( !$bulk ) {
                Message("Confirming deletion of $plate ($confirmed)");
                ## delete one at a time ##
                my $ok = &alDente::Container::Delete_Container( -dbc => $dbc, -ids => $plate, -confirm => $confirmed );
                my $ok = $dbc->delete_records( -table => 'Source', -dfield => 'Source_ID', -id_list => $source, -cascade => ['Library_Source'], -quiet => 1 );
            }
            else {
                Message("waiting for bulk deletion...($bulk)");
            }
        }
        else {
            Message("******************* SKIP $plate ($confirm[0]) SRC $confirm2 <- $good_src **************");
        }
        $dbc->finish_trans('single_delete');
    }
    my $plate_list = join ',', @plate_deletions;

    if ($bulk) {
        ## delete together at the end ##
        Message("Deleting Plates: $plate_list");
        if (@plate_deletions) {
            my $ok = &alDente::Container::Delete_Container( -dbc => $dbc, -ids => $plate_list, -confirm => $confirmed );
            my $ok = $dbc->delete_records( -table => 'Source', -dfield => 'Source_ID', -id_list => \@src_deletions, -cascade => ['Library_Source'], -quiet => 1 );
        }

        $dbc->finish_trans('deleted');
    }

    Message("Fixed $deleted");
    return 1;

}

return 1;
