#!/usr/bin/perl
###################################################################################################################################
# QA.pm
#
###################################################################################################################################
package alDente::QA;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;

#use Benchmark;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;
use alDente::Attribute;
use SDB::DB_Form_Viewer;
use SDB::DB_Form;
use SDB::Session;
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::RGmath;

##############################
# global_vars                #
##############################
use vars qw( $user $table);
use vars qw($MenuSearch $scanner_mode %Settings $Connection);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

### Global variables

### Modular variables

###########################
# Constructor of the object
###########################

##############################
# public_methods             #
##############################

##############################
# Get all information for plates that have been reloaded
#
#  Example:
#	&get_info(-dbc=>$dhb,-equipment_type=>$equ_type,-date=>$date);
#
#  Options:
#   -equ_type =>  (default is Sequencer)
#   -date =>  (default is Jan.1,2005
#
#  Returns:
#	\%results;
#
##############################
sub get_info {
##############

    my $dbc        = shift;
    my $tables     = 'Run,RunBatch';
    my $equ_type   = 'Sequencer';
    my $date_range = '2005-01-01';
    my @verified_equ;
    my @corr_date;

    # get a list of all equipment ids of particular type that are currently in use
    my @equipment = @{ get_equipment_id( -dbc => $dbc, -equ_type => $equ_type, -equ_status => 'In Use' ) };

    # get a list of reloaded Plate_IDs
    my %reload_info = %{ get_reloads( -dbc => $dbc, -tables => $tables, -date => $date_range ) };

    if ( @equipment && %reload_info ) {

        my %results;
        my $read = Sequencing::Read->new( -dbc => $dbc );

        my @plate_id = @{ $reload_info{FK_Plate__ID} };
        my @equ_1_id = @{ $reload_info{Equ1} };
        my @equ_2_id = @{ $reload_info{Equ2} };
        my @run_1_id = @{ $reload_info{Run1} };
        my @run_2_id = @{ $reload_info{Run2} };
        my @date1    = @{ $reload_info{Date1} };
        my @date2    = @{ $reload_info{Date2} };

        my $test = 0;
        my $needed;
        my $test_complete;
        my $full_correlation;

        # for each reloaded Plate_ID...
        for ( my $i = 0; $i < scalar(@plate_id); $i++ ) {

            # check if the equipment onto which the Plate_ID was reloaded is of proper type
            my $valid_equ = _check_equ( -equ_list => \@equipment, -equ1 => $equ_1_id[$i], -equ2 => $equ_2_id[$i] );
            if ($valid_equ) {

                # check if this reload correlation should be used (if it hasn't been used already in a previous run)
                $needed = _check_if_needed( -verified => \@verified_equ, -equ1 => $equ_1_id[$i], -equ2 => $equ_2_id[$i] );

                if ($needed) {
                    $dbc->message("Submitting Plate $plate_id[$i] for BLAST reanalysis - Run_IDs $run_1_id[$i] and $run_2_id[$i]...<BR>");

                    # run the correlation (BLAST) test on the two Run_IDs associated with the current Plate_ID
                    %results = $read->compare_runs( -run1 => $run_1_id[$i], -run2 => $run_2_id[$i], -poor_threshold => 100, -pass_percentage => 90 );

                    # check the result of the above analysis to see if correlation was successful
                    my $passed = _analyze_results( -dbc => $dbc, -result => \%results, -equ_type => $equ_type, -equ1 => $equ_1_id[$i], -equ2 => $equ_2_id[$i], -date => $date1[$i], -poor_threshold => 100, -pass_percentage => 90, -print_table => 0 );

                    # if correlation (BLAST) results indicate a successful correlation record the analysis
                    if ($passed) {
                        $test_complete = _record_correlation( -verified => \@verified_equ, -corr_date => \@corr_date, -equ1 => $equ_1_id[$i], -equ2 => $equ_2_id[$i], -date => $date1[$i] );
                    }

                    # check if all tests have been performed
                    if ($test_complete) {
                        _view_results( -all_equ => \@equipment, -correlated_equ => \@verified_equ, -correlated_date => \@corr_date, -equ_type => $equ_type );
                        last;
                    }

                }
            }
        }
        if ( !$test_complete ) {
            $dbc->message("Partial correlation");
            _view_results( -all_equ => \@equipment, -correlated_equ => \@verified_equ, -correlated_date => \@corr_date, -equ_type => $equ_type );
        }

    }
    else {
        print "Could not execute the test<BR>";
        return 0;
    }
    return 1;

}

###############################
#  _view_results:
#
#  Example:
#
#  Returns:
#
#################
sub _view_results {
#################

    my %args            = &filter_input( \@_, -args => 'all_equ,correlated_equ,correlated_date,equ_type', -mandatory => 'all_equ,equ_type' );
    my $verified_equ    = $args{-correlated_equ};
    my @correlated_date = @{ $args{-correlated_date} };
    my @all_equ         = @{ $args{-all_equ} };
    my $equ_type        = $args{-equ_type};
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $corr_equ_list = Cast_List( -list => $verified_equ, -to => 'string' );
    my @corr_equ_names = $dbc->Table_find( 'Equipment', 'Equipment_Name', "where Equipment_ID IN ($corr_equ_list)" ) if $corr_equ_list;
    my $corr_equ_names = Cast_List( -list => \@corr_equ_names, -to => 'string' );

    my ( $corrlated, $uncorrelated, $tmp ) = RGmath::intersection( \@all_equ, \@$verified_equ );
    my $uncorr_list = Cast_List( -list => $uncorrelated, -to => 'string' );
    my @uncorr_equ_names = $dbc->Table_find( 'Equipment', 'Equipment_Name', "where Equipment_ID IN ($uncorr_list)" );
    my $uncorr_equ_names = Cast_List( -list => \@uncorr_equ_names, -to => 'string' );

    print "<BR>";
    my $correlation_summary = HTML_Table->new( -width => 600 );
    $correlation_summary->Set_Title( "<B>QA - Correlation Summary for Equipment Type '$equ_type'", fsize => '-1' );
    $correlation_summary->Set_Row( [ "Correlated Equip: ",   $corr_equ_names ] );
    $correlation_summary->Set_Row( [ "Correlation date: ",   $correlated_date[0] ] );
    $correlation_summary->Set_Row( [ "Uncorrelated Equip: ", $uncorr_equ_names ] );
    $correlation_summary->Printout();
    return;

}

###############################
#  _record_correlation
#
#  Example:
#
#  Returns:
#
##############################
sub _record_correlation {

    my %args         = &filter_input( \@_, -args => 'equ1,equ2,date', -mandatory => 'equ1,equ2,date' );
    my $verified_equ = $args{-verified};
    my $corr_date    = $args{-corr_date};
    my $equ1         = $args{-equ1};
    my $equ2         = $args{-equ2};
    my $date         = $args{-date};

    my $checked_equ1 = grep /\b$equ1\b/i, @$verified_equ;
    my $checked_equ2 = grep /\b$equ2\b/i, @$verified_equ;
    my $checked_date = grep /\b$date\b/i, @$corr_date;

    if ( !$checked_equ1 ) {
        push( @$verified_equ, $equ1 );
    }
    if ( !$checked_equ2 ) {
        push( @$verified_equ, $equ2 );
    }

    # find the (oldest) date of the correlation
    if ( !$checked_date ) {
        if ( scalar(@$corr_date) == 0 ) {
            push( @$corr_date, $date );
        }
        else {
            my $curr_date = @$corr_date[0];
            my $new_date  = $date;
            $curr_date =~ s/\W//g;
            $date      =~ s/\W//g;
            if ( $date < $curr_date ) {
                @$corr_date[0] = $new_date;
            }
        }
    }

    if ( scalar(@$verified_equ) == 11 ) {
        return 1;
    }
    else {
        return 0;
    }
}

###############################
# Check if the equipment pair is new (needed)
#
#  Example:
#
#  Returns:
#
##############################
sub _check_if_needed {

    my %args         = &filter_input( \@_, -args => 'verified,equ1,equ2', -mandatory => 'equ1,equ2' );
    my $verified_equ = $args{-verified};
    my $equ1         = $args{-equ1};
    my $equ2         = $args{-equ2};

    my $checked_equ1 = grep /\b$equ1\b/i, @$verified_equ;
    my $checked_equ2 = grep /\b$equ2\b/i, @$verified_equ;

    if ( !$checked_equ1 || !$checked_equ2 ) {
        return 1;
    }
    return 0;
}

###############################
# Check if the equipment type is an active sequencer
#
#  Example:
#	my $valid_equ = _check_equ(-equ_list=>\@equipment_id,-equ1=>$equ_1_id[$i],-equ2=>$equ_2_id[$i]);
#
#  Returns:
#	0 - if either of the equipment ids passed in is not an active sequencer
#	1 - if both of the equipment ids passed in are active and distinct sequencers
#
##############################
sub _check_equ {

    my %args     = &filter_input( \@_, -args => 'equ_list,equ1,equ2', -mandatory => 'equ_list,equ1,equ2' );
    my @equ_list = @{ $args{-equ_list} };
    my $equ1     = $args{-equ1};
    my $equ2     = $args{-equ2};

    # check if the plate was reloaded on distict equipment
    if ( $equ1 != $equ2 ) {
        my $sequencer1 = grep /\b$equ1\b/i, @equ_list;
        my $sequencer2 = grep /\b$equ2\b/i, @equ_list;

        # check if both pieces of equipment are active sequencers
        if ( $sequencer1 && $sequencer2 ) {
            return 1;
        }
    }
    return 0;
}

###############################
#  Get list of reloaded plate_ids for specified equipment and specified date range
#
#  Example:
#
#  Returns:
#
##############################
sub get_reloads {

    my %args = &filter_input( \@_, -args => 'dbc,tables,date', -mandatory => 'dbc,tables' );

    my $dbc        = $args{-dbc};
    my $tables     = $args{-tables};
    my $date_range = $args{-date} || '2005-01-01';

    # get information on any plates and equipment that were reloaded since specified date
    my %reload_info = $dbc->Table_retrieve(
        $tables,
        [ 'FK_Plate__ID', 'Min(FK_Equipment__ID) as Equ1', 'Max(FK_Equipment__ID) as Equ2', 'Min(Run_ID) as Run1', 'Max(Run_ID) as Run2', 'Min(Run_DateTime) as Date1', 'Max(Run_DateTime) as Date2' ],
        "WHERE FK_RunBatch__ID=RunBatch_ID AND Run_DateTime > '$date_range' AND FK_Plate__ID IS NOT NULL Group by FK_Plate__ID having count(*) > 1"
    );
    my @plate_id = @{ $reload_info{FK_Plate__ID} };

    if ( $plate_id[0] ) {
        return \%reload_info;
    }
    else {
        print 'Failed to retrieve list of realoads<BR>';
        return 0;
    }
}

###############################
#  Get list of Equipment_IDs that are active
#
#  Example:
#
#  Returns:
#
##############################
sub get_equipment_id {

    my %args = &filter_input( \@_, -args => 'dhb,equ_type,equ_status', -mandatory => 'dbc,equ_type' );

    my $dbc        = $args{-dbc};
    my $equ_type   = $args{-equ_type};
    my $equ_status = $args{-equ_status} || 'In Use';

    # get equipment ids
    my @equipment_id = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
        'Equipment_ID', "where Category ='$equ_type' AND Equipment_Status = '$equ_status' AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID" );

    if ( $equipment_id[0] ) {
        return \@equipment_id;
    }
    else {
        print 'Failed to retrieve list of equipment<BR>';
        return 0;
    }
}

###############################
#  Parse and analyze the %result
#
#  Example:
#
#  Returns:
#
##############################
sub _analyze_results {

    my %args            = &filter_input( \@_, -args => 'dbc,result,equ1,equ2,date', -mandatory => 'dbc,result,equ1,equ2,date' );
    my $dbc             = $args{-dbc};
    my %result          = %{ $args{-result} };
    my $poor_threshold  = $args{-poor_threshold} || 100;                                                                           ## threshold quality to ignore non-correlating wells
    my $pass_percentage = $args{-pass_percentage} || 90;                                                                           ## percentage match for pass (or warnings generated)
    my $match_threshold = $args{-match_threshold} || 90;                                                                           ## percentage match for for correlation to be considered as successful
    my $equ_type        = $args{-equ_type};                                                                                        ## equipment type being compared
    my $equ1            = $args{-equ1};
    my $equ2            = $args{-equ2};
    my $date            = $args{-date};
    my $print_table     = $args{-print_table} || undef;                                                                            ## switch to print out the table

    my $total_analyzed_wells = 0;
    my $match                = 0;
    my $warning              = 0;
    my $poor                 = 0;
    my $fail                 = 0;
    my $match_tree;
    my $warning_tree;
    my $poor_tree;
    my $fail_tree;
    my @match;
    my @warning;
    my @poor;
    my @fail;

    if ( exists $result{match}[0] ) {
        @match = @{ $result{match} };
        $match = scalar(@match);
        $total_analyzed_wells += $match;

        my %matches;
        my $key;
        my $value;
        foreach my $well (@match) {
            my %well_info = %{ $result{$well} };
            my @well_details;
            while ( ( $key, $value ) = each %well_info ) {
                push( @well_details, "$key:<font color=blue> $value</font>\n" );
            }
            $matches{$well} = \@well_details;
        }
        my %match_tree = ( Matches => \%matches );
        $match_tree = SDB::HTML::create_tree( -tree => \%match_tree, -print => 0 );
    }
    if ( exists $result{warning}[0] ) {
        @warning = @{ $result{warning} };
        $warning = scalar(@warning);
        $total_analyzed_wells += $warning;
        my %warnings;
        my $key;
        my $value;
        foreach my $well (@warning) {
            my %well_info = %{ $result{$well} };
            my @well_details;
            while ( ( $key, $value ) = each %well_info ) {
                push( @well_details, "$key:<font color=blue> $value</font>\n" );
            }
            $warnings{$well} = \@well_details;
        }

        my %warning_tree = ( Warnings => \%warnings );
        $warning_tree = SDB::HTML::create_tree( -tree => \%warning_tree, -print => 0 );
    }
    if ( exists $result{poor}[0] ) {
        @poor = @{ $result{poor} };
        $poor = scalar(@poor);
        $total_analyzed_wells += $poor;

        my %poors;
        my $key;
        my $value;
        foreach my $well (@poor) {
            my %well_info = %{ $result{$well} };
            my @well_details;
            while ( ( $key, $value ) = each %well_info ) {
                push( @well_details, "$key:<font color=blue> $value</font>\n" );
            }
            $poors{$well} = \@well_details;
        }
        my %poor_tree = ( Poor => \%poors );
        $poor_tree = SDB::HTML::create_tree( -tree => \%poor_tree, -print => 0 );
    }
    if ( exists $result{fail}[0] ) {
        @fail = @{ $result{fail} };
        $fail = scalar(@fail);
        $total_analyzed_wells += $fail;

        my %fails;
        my $key;
        my $value;
        foreach my $well (@fail) {
            my %well_info = %{ $result{$well} };
            my @well_details;
            while ( ( $key, $value ) = each %well_info ) {
                push( @well_details, "$key:<font color=blue> $value</font>\n" );
            }
            $fails{$well} = \@well_details;
        }
        my %fail_tree = ( Poor => \%fails );
        $fail_tree = SDB::HTML::create_tree( -tree => \%fail_tree, -print => 0 );
    }

    if ($total_analyzed_wells) {

        my $percent_match   = sprintf( "%.2f", ( $match / $total_analyzed_wells ) * 100 ) . "%";
        my $percent_warning = sprintf( "%.2f", ( $warning / $total_analyzed_wells ) * 100 ) . "%";
        my $percent_poor    = sprintf( "%.2f", ( $poor / $total_analyzed_wells ) * 100 ) . "%";
        my $percent_fail    = sprintf( "%.2f", ( $fail / $total_analyzed_wells ) * 100 ) . "%";
        my $percent_all     = sprintf( "%.2f", ( $total_analyzed_wells / $total_analyzed_wells ) * 100 ) . "%";

        if ( $percent_match >= $match_threshold ) {
            my ($equ1_name) = $dbc->Table_find( 'Equipment', 'Equipment_Name', "where Equipment_ID = $equ1" );
            my ($equ2_name) = $dbc->Table_find( 'Equipment', 'Equipment_Name', "where Equipment_ID = $equ2" );

            my $results_table = HTML_Table->new( -width => 800 );
            $results_table->Set_Title( "<B>QA Analysis Results - </B>$percent_match correlation between $equ_type $equ1_name and $equ2_name  ($date)", fsize => '-1' );
            $results_table->Set_Alignment( 'center', 3 );
            $results_table->Set_Alignment( 'center', 4 );
            $results_table->Set_Headers( [ '', 'Details', '# of Wells', 'Percentage' ], $Settings{HIGHLIGHT_CLASS} );
            $results_table->Set_Row( [ "<B>Matched Wells:</B><font color=red> (Correlation >= $pass_percentage %)</font>",                 $match_tree,   $match,   $percent_match ] );
            $results_table->Set_Row( [ "<B>Warning Wells: </B><font color=red> (Correlation < $pass_percentage %)</font>",                 $warning_tree, $warning, $percent_warning ] );
            $results_table->Set_Row( [ "<B>Poor Wells:</B><font color=red> (Quality Length < $poor_threshold bps)</font>",                 $poor_tree,    $poor,    $percent_poor ] );
            $results_table->Set_Row( [ "<B>Failed Wells: </B><font color=red> (No Match AND Quality Length > $poor_threshold bps)</font>", $fail_tree,    $fail,    $percent_fail ] );
            $results_table->Set_Row( [ "<B>Total Wells Analyzed: </B>", '-', $total_analyzed_wells, $percent_all ], "mediumbluebw" );
            $results_table->Printout($print_table);

            return 1;
        }
    }
    $dbc->message("Correlation not valid or below match threshold of $match_threshold % -> NOT INCLUDED");
    print "<BR>";
    return 0;
}
###################
sub check_for_qc {
###################
    my %args  = filter_input( \@_, -args => 'ids, table' );
    my $ids   = $args{-ids};
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table = $args{-table};                                                                   ## Plate or Solution
    my @ids   = Cast_List( -list => $ids, -to => 'Array' );
    my ($primary_field) = SDB::DBIO::get_field_info( $dbc, $table, undef, 'Primary' );

    my %qc_status;

    foreach my $id (@ids) {

        my @qc_status = $dbc->Table_find( $table, 'QC_Status', "where $primary_field IN ($id)" );

        if (@qc_status) {
            $qc_status{$id} = $qc_status[0];
        }
        else { $qc_status{$id} = '' }
    }

    return \%qc_status;
}

# set the QC Status for an object ie (Plate, Solution)
# can handle attributes as well
#
#
###################
sub set_qc_status {
###################
    my %args      = filter_input( \@_, -args => 'ids, table' );
    my $ids       = $args{-ids};
    my $dbc       = $args{-dbc};
    my $table     = $args{-table};                                                                   ## Object that the QC Status will be set for
    my $qc_type   = $args{-qc_type} || 'Standard';
    my $attribute = $args{-attribute};                                                               ## optional attribute name will result in attribute value being set for the Attribute table of $table

    my $status = $args{-status};
    my $update_ids = Cast_List( -list => $ids, -to => 'String' );
    my ($primary_field) = $dbc->get_field_info( $table, undef, 'Primary' );
    my ($qc_type_id) = $dbc->Table_find( 'QC_Type', 'QC_Type_ID', "WHERE QC_Type_Name = '$qc_type'" );
    ## check to see if the qc multi join table  exists for this table
    my $qc_multi = $table . "_QC";
    ## probably a faster way to check this if qc_multi exists
    my $qc_multi_exists = 0;
    ($qc_multi_exists) = $dbc->Table_find( 'DBTable', 'DBTable_Name', "WHERE DBTable_Name ='$qc_multi'" );

    unless ( $ids =~ /\d+/ ) { return 0 }
    my $updated;
    if ($attribute) {
        ## handling for Attribute values
        my $attribute_obj = alDente::Attribute->new( -dbc => $dbc );
        my %attribute_val;
        my $set_loading_conc = $attribute_obj->set_attribute( -id => $ids, -object => "$table", -attribute => $attribute, -value => $status );
    }
    elsif ($qc_multi_exists) {
        ##
        my ($fk_field) = $dbc->foreign_key( -table => $table );
        my @fields = ( $fk_field, 'FK_QC_Type__ID', 'QC_Status', 'QC_DateTime' );
        my %values;
        my @update_ids = Cast_List( -list => $ids, -to => 'Array' );
        my $index = 1;
        foreach my $id (@update_ids) {
            ## check if other types of QC exist for this ID. If exists, stop since multiple types of QC are not supported.
            my ($record_exists) = $dbc->Table_find( $qc_multi, "$fk_field,FK_QC_Type__ID", "WHERE $fk_field = $id" );
            if ($record_exists) {
                my ( $fk_id, $exist_qc_type_id ) = split ',', $record_exists;
                if ( $exist_qc_type_id != $qc_type_id ) {
                    my $exist_qc_type = $dbc->get_FK_info( -field => 'FK_QC_Type__ID', -id => $exist_qc_type_id );
                    $dbc->warning("$exist_qc_type has been done to $table $id. Multiple QCs are not supported!");
                    return;
                }
                else {
                    $dbc->Table_update_array( $qc_multi, ['QC_Status'], [$status], "WHERE FK_QC_Type__ID = $qc_type_id and $fk_field = $id", -autoquote => 1 );
                }
            }
            else {
                $values{$index} = [ $id, $qc_type_id, $status, &date_time() ];
                $index++;
            }
        }
        if (%values) {
            my $ok = $dbc->smart_append( "$qc_multi", -fields => \@fields, -values => \%values, -autoquote => 1 );
        }
        $updated = $dbc->Table_update_array( $table, ['QC_Status'], [$status], "WHERE $primary_field IN ($update_ids)", -autoquote => 1 );
        $dbc->message("Setting QC status for type $qc_type to $status for $update_ids ...($updated records updated)");
    }
    else {
        $updated = $dbc->Table_update_array( $table, ['QC_Status'], [$status], "WHERE $primary_field IN ($update_ids)", -autoquote => 1 );
        $dbc->message("Setting QC status to $status for $update_ids ...($updated records updated)");
    }
    ## add prep record if the object is a plate
    if ( $table =~ /Plate/ ) {
        require alDente::Prep;
        my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $dbc->get_local('user_id') );
        my %input;
        $input{'Current Plates'} = $update_ids;
        my $qc_status_name;
        if ($attribute) {
            $qc_status_name = "$attribute";
        }
        else {
            $qc_status_name = "QC_Status";
        }
        $input{'Prep Step Name'} = "Set $qc_type $qc_status_name to $status";
        $Prep->Record( -ids => $update_ids, -protocol => 'Standard', -input => \%input, -change_location => 0 );
    }

    return $updated;
}

# Create a QC button for views with caller supply the Status (e.g. Failed, Passed)
#
# Returns: HTML Button
######################
sub QC_btn {
######################
    my %args         = @_;
    my $status       = $args{-status};
    my $failed_plate = $args{-failed_plate};
    my $start_qc     = $args{-start_qc};
    my $button;

    if ( $status eq 'Failed' ) {
        $button = submit( -name => "Set $status QC", -value => "$status QC / Throw out", -class => 'Std' );
    }
    else {
        $button = submit( -name => "Set $status QC", -value => "$status QC", -class => 'Std' );
    }

    if ($start_qc) {
        $button .= checkbox( -name => 'QC Gel', -value => 'QC Gel', -label => 'QC Gel', -checked => 0, -force => 1 );
    }
    elsif ($failed_plate) {
        $button .= hidden( -name => 'Fail Plate', -value => 'Fail Plate' );
    }

    return $button;
}

# Catches the QC btn, sets the QC status of plates to the corresponding button pressed by the user
# Returns: none
############################
sub catch_QC_btn {
############################
    my %args          = filter_input( \@_, -args => 'dbc' );
    my $dbc           = $args{-dbc};
    my @plates        = param('Mark');
    my $qc_gel        = param('QC Gel');
    my $fail_comments = param('Comments');

    unless (@plates) {
        @plates = param('FK_Plate__ID');
    }
    my $num_updated    = 0;
    my $status         = '';
    my $plate_comments = '';
    if ( param('Set Passed QC') ) {
        $status = 'Passed';
    }
    if ( param('Set Failed QC') ) {
        $status = 'Failed';
    }
    if ( param('Set Re-Test QC') ) {
        $status = 'Re-Test';
    }

    if ( $status ne '' ) {
        my $no_of_plates = @plates;

        if ( $no_of_plates == 0 ) {
            Message("Operation cancelled.  Select at least 1 Plate and try again.");
            return;
        }
        $num_updated = set_qc_status( -dbc => $dbc, -ids => \@plates, -table => 'Plate', -status => $status );
        $dbc->message("$num_updated plates were set to '$status'");
    }

    if ( ( $status eq 'Failed' ) && ( param('Fail Plate') ) ) {
        alDente::Form::catch_fail_btn( -object => 'Plate', -bypass => 1, -reason => 'General Reason', -comments => $fail_comments );
    }

    if ($qc_gel) {
        require Sequencing::Custom;
        my $plate_ids = Cast_List( -list => @plates, -to => 'String', -delimiter => ',' );
        my $result = Sequencing::Custom::build_QC( -dbc => $dbc, -plate_ids => $plate_ids );
        if   ($result) { print $result; }
        else           { return 0; }

    }
    return;
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################
return 1;
