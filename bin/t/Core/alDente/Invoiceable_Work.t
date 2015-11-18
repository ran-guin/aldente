#!/usr/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Invoiceable_Work;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Invoiceable_Work");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_IWR_funding_update\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'validate_IWR_funding_update');
    {
        ## <insert tests for validate_IWR_funding_update method here> ##
    }
}

if ( !$method || $method =~ /\bchange_billable_btn\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'change_billable_btn');
    {
        ## <insert tests for change_billable_btn method here> ##
    }
}

if ( !$method || $method =~ /\bset_funding_btn\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'set_funding_btn');
    {
        ## <insert tests for set_funding_btn method here> ##
    }
}

if ( !$method || $method =~ /\bget_work_info\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'get_work_info');
    {
        ## <insert tests for get_work_info method here> ##
    }
}

if ( !$method || $method =~ /\bfunding_warning\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'funding_warning');
    {
        ## <insert tests for funding_warning method here> ##
    }
}

if ( !$method || $method =~ /\binvoice_billable_trigger\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'invoice_billable_trigger');
    {
#	
#	my $self = new alDente::Invoiceable_Work( -dbc => $dbc );	
#	my $table = "Invoiceable_Work_Reference";
#	my @id = [1];
#	
#	# This method does not use the $self parameter
#    require alDente::Invoiceable_Work;
#    my $test = alDente::Invoiceable_Work::invoice_billable_trigger( 1, -dbc => $dbc, -table=> $table, -id=>@id );
#	
#	is($test, 1);
    }
}

if ( !$method || $method =~ /\biwr_invoice_trigger\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'iwr_invoice_trigger');
    {
        ## <insert tests for iwr_invoice_trigger method here> ##
        
        my $old_invoice = 3102;
        my $new_invoice = 3108;
        my $iwr = 375646;
        my ($iw) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FKReferenced_Invoiceable_Work__ID', "WHERE Invoiceable_Work_Reference_ID = $iwr" );
        # Invoiceable Work Reference (Invoiced to GBForest (GSC 790) Y10Q1) record with 12 children -- updating to be on invoice GSCINV-1149
        $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['FK_Invoice__ID'], [$new_invoice], "WHERE Invoiceable_Work_Reference_ID = $iwr" );
        # Checking that IWR 375646 and its children were updated to be on invoice 3108
        my ($updated_invoice) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FK_Invoice__ID', "WHERE FKReferenced_Invoiceable_Work__ID = $iw", -distinct => 1 );
        is($updated_invoice, $new_invoice, "IWR $iwr and its children updated to be on invoice $new_invoice.");
        
        $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['FK_Invoice__ID'], [$old_invoice], "WHERE Invoiceable_Work_Reference_ID = $iwr" );
        my ($reverted_invoice) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FK_Invoice__ID', "WHERE FKReferenced_Invoiceable_Work__ID = $iw", -distinct => 1 );
        is($reverted_invoice, $old_invoice, "IWR $iwr and its children reverted to being on invoice $old_invoice.");
    }
}

if ( !$method || $method =~ /\bsync_billable\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'sync_billable');
    {
        ## <insert tests for sync_billable method here> ##
        my $iwr = 385546;
        my $run = 144014;
        my $Invoiceable_Work = new alDente::Invoiceable_Work(-dbc=>$dbc);
        # Testing for updated Invoiceable_Work_Reference record
        $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['Billable'], ['No'], "WHERE Invoiceable_Work_Reference_ID = $iwr", -autoquote => 1 );
        $Invoiceable_Work->sync_billable( -dbc => $dbc, -ids => $iwr, -table => 'Invoiceable_Work_Reference', -billable => 'No' );
        # Checking that Run.Billable was updated
        my ($run_billable) = $dbc->Table_find( 'Run', 'Billable', "WHERE Run_ID = $run" );
        is($run_billable, 'No', "Run.Billable synced with IWR.");
        # Checking that children of IWR are updated
        my ($children_billable1) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Billable', "WHERE FKParent_Invoiceable_Work_Reference__ID = $iwr", -distinct => 1 );
        is($children_billable1, 'No', "Children of IWR Billable updated.");

        # Testing for updated Run record
        $dbc->Table_update_array( 'Run', ['Billable'], ['Yes'], "WHERE Run_ID = $run", -autoquote => 1 );
        $Invoiceable_Work->sync_billable( -dbc => $dbc, -ids => $run, -table => 'Run' );
        # Checking that IWR.Billable was updated
        my ($iwr_billable) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Billable', "WHERE Invoiceable_Work_Reference_ID = $iwr", -billable => 'Yes' );
        is($iwr_billable, 'Yes', "IWR.Billable synced with Run.");
        # Checking that children of IWR are updated
        my ($children_billable2) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Billable', "WHERE FKParent_Invoiceable_Work_Reference__ID = $iwr", -distinct => 1 );
        is($children_billable2, 'Yes', "Children of IWR Billable updated.");
    }
}

if ( !$method || $method =~ /\bsync_billable_email_helper\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'sync_billable_email_helper');
    {
        ## <insert tests for sync_billable_email_helper method here> ##
    }
}

if ( !$method || $method =~ /\bget_child_invoiceable_work_reference\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'get_child_invoiceable_work_reference');
    {
        ## <insert tests for get_child_invoiceable_work_reference method here> ##
    }
}

if ( !$method || $method =~ /\bappend_invoiceable_work_comment\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'append_invoiceable_work_comment');
    {
        ## <insert tests for append_invoiceable_work_comment method here> ##
    }
}

if ( !$method || $method =~ /\bhas_multiple_invoiceable_work_ref\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'has_multiple_invoiceable_work_ref');
    {
        ## <insert tests for has_multiple_invoiceable_work_ref method here> ##
        # Invoiceable_Work_ID does have child Invoiceable_Work_Reference records
        my $id = 263745;
        my $check_multiple1 = alDente::Invoiceable_Work::has_multiple_invoiceable_work_ref(-dbc=>$dbc, -id=>$id);
        my ($parent_iwr) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE FKReferenced_Invoiceable_Work__ID = $id AND FKParent_Invoiceable_Work_Reference__ID IS NULL" );
        is($check_multiple1, $parent_iwr, "Invoiceable_Work_ID: $id has child Invoiceable_Work_Reference items. Test 1 expected behaviour.");

        #Invoiceable_Work_ID does NOT have child Invoiceable_Work_reference records
        my $id = 264035;
        my $check_multiple2 = alDente::Invoiceable_Work::has_multiple_invoiceable_work_ref(-dbc=>$dbc, -id=>$id);
        is($check_multiple2, 0, "Invoiceable_Work_ID: $id does NOT have child Invoiceable_Work_Reference items. Test 2 expected behaviour.");
    }
}

if ( !$method || $method =~ /\biwr_change_funding_trigger\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'iwr_change_funding_trigger');
    {
        ## <insert tests for iwr_change_funding_trigger method here> ##
    }
}

if( !$method || $method =~ /\biw_funding_change_notification\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'iw_funding_change_notification');
    {
        ## <insert tests for iw_funding_change_notification method here> ##
    }
}

if ( !$method || $method =~ /\bbackfill_invoiceable_work_reference\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'backfill_invoiceable_work_reference');
    {
	
# backfill script for invoiceable_work_reference table
	
#       my $invoiceable_work = new alDente::Invoiceable_Work(-dbc => $dbc);
#	$invoiceable_work->backfill_invoiceable_work_reference(-dbc => $dbc);	
    }
}

if ( !$method || $method =~/\bget_change_history_comments\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'get_change_history_comments');
    {
        ## <insert tests for get_change_history_comments here> ##
    }
}

if ( !$method || $method =~ /\bbillable_status_change_notification\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'billable_status_change_notification');
    {
        ## <insert tests for billable_status_change_notification method here> ##
        ## Can't really run the test here! The email message is not returned from the method.
    	#my $result = alDente::Invoiceable::billable_status_change_notification( $dbc, -iw_ids => $iw_id, -billable_status => $status, -billable_comments => $comments[0] );
    }
}

if ( !$method || $method =~ /\bbackfill_invoiceable_work\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'backfill_invoiceable_work');
    {
#	Use this to test the backfilling script

#	my $invoiceable_work = new alDente::Invoiceable_Work(-dbc => $dbc);
#	$invoiceable_work -> backfill_invoiceable_work(-prep => 'Library_Construction');
#	$invoiceable_work -> backfill_invoiceable_work(-run => 'SolexaRun');
#	$invoiceable_work -> backfill_invoiceable_work(-project => '210');
#	$invoiceable_work -> backfill_invoiceable_work(-project_status => 'Active');
    }
}

if ( !$method || $method =~ /\brecord_invoiceable_prep\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'record_invoiceable_prep');
    {
        ## <insert tests for record_invoiced_prep method here> ##
	
	#Need to use this mysql command on the database to make sure that it works:
	#Update Invoice_Protocol set Invoiceable_Protocol_Status = 'Inactive' where Invoice_Protocol_ID = 1;
	
	
    }
}

if ( !$method || $method =~ /\brecord_indirectly_invoiceable_prep\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'record_indirectly_invoiceable_prep');
    {
        ## <insert tests for record_indirectly_invoiced_prep method here> ##
	
    # Testing this method to make sure that it works
	my $invoiceable_work = new alDente::Invoiceable_Work(-dbc => $dbc);
	$invoiceable_work -> record_indirectly_invoiceable_prep(-invoiceable_work_id => '93531', -invoiceable_work_ref_id => '8927', -debug => '1');
    
    }
}

if ( !$method || $method =~ /\badd_invoiceable_prep_info\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'add_invoiceable_prep_info');
    {		
        ## <insert tests for add_invoiceable_prep_info method here> ##
	
	my $test_prep_id = 0; ## '543048' change to something better;
	my $expected_results = 0;
	my $invoiceable_work = new alDente::Invoiceable_Work(-dbc=>$dbc);		
	my $method_results = $invoiceable_work->add_invoiceable_prep_info(-dbc => $dbc, -prep_id => $test_prep_id);

	is_deeply($method_results, $expected_results, 'add_invoiceable_work_info: return 0, duplicate therefore skip entry');
	
	my $invoiceable_work = new alDente::Invoiceable_Work(-dbc => $dbc);
	my $added = $invoiceable_work -> add_invoiceable_prep_info(-prep_id => '949205');
	is($added , 0, "No Records Added <- Expected");
	
	my $test_ids = $invoiceable_work -> add_invoiceable_prep_info(-prep_id => '949205', -test_flag =>1);
	
	is($test_ids, 25069, "Invoiceable_Work IDs match");
	
    }
}

if ( !$method || $method =~ /\badd_invoiceable_run_info\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'add_invoiceable_run_info');
    {
        my $invoiceable_work = new alDente::Invoiceable_Work(-dbc => $dbc);
	my $added = $invoiceable_work->add_invoiceable_run_info(-run_id => '135317', -debug => 1);
	is($added , 0, "No Records Added <- Expected");
	
	my $test_id = $invoiceable_work->add_invoiceable_run_info(-run_id => '135317', -test_flag => 1);
	
is($test_id, 236471, "Invoiceable_Work IDs match");
    }
}

if ( !$method || $method =~ /\brecord_invoiceable_run\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'record_invoiceable_run');
    {    
	## <insert tests for record_invoiceable_run method here> ##
    }
}

if ( !$method || $method =~ /\brecord_indirectly_invoiceable_run\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'record_indirectly_invoiceable_run');
    {
        ## <insert tests for record_indirectly_invoiceable_run method here> ##
    }
}

if ( !$method || $method =~ /\bget_dissemination_date\b/ ) {
    can_ok("alDente::Invoiceable_Work", 'get_dissemination_date');
    {
        ## <insert tests for get_dissemination_date method here> ##
        my @ra_ids = (45356,45357,45358,45396,45397,45398,45399,45400,45359,45360);
        my $results = alDente::Invoiceable_Work::get_dissemination_date( -dbc => $dbc, -analysis_ids => \@ra_ids );
        my @expected = $dbc->Table_find( 'Run_Analysis', 'MAX(Dissemination_Date)', "WHERE Run_Analysis_ID IN (45368,45372,45376,45327,45401,45328,45402,45329,45403,45330,45404,45331,45369,45370) GROUP BY FK_Run__ID" );
        print "Expected: @expected\n";
        print "Actual: @$results\n";
        is (@$results, @expected, 'Dates of Dissemination match, test behaviour as expected.');
    }
}

## END of TEST ##

ok( 1 ,'Completed Invoiceable_Work test');

exit;
