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
use alDente::Subscription;
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




use_ok("alDente::Subscription");

if ( !$method || $method =~ /\bget_subscription_id\b/ ) {
    can_ok("alDente::Subscription", 'get_subscription_id');
    {
   # Subscription:
        # +----------------------+-----------------------+
        # | SubscriptionEvent_ID |SubscriptionEvent_Name | 
        # +----------------------+-----------------------+
        # |        1             |       Stock Supply Low|
        # +----------------------+-----------------------+
	$tmp = alDente::Subscription->new(-dbc => $dbc);

	# Test Case 2: enter a non existing EventName returns 0 (i.e. No match)
        my $SubscriptionID = $tmp->get_subscription_id("Coffee Break");
        eq_or_diff($SubscriptionID,[],'Undefined EventName'); 

	# Test Case 3: enter an existing EventName returns the SubscriptionEventID of the SubscriptionEvent record with the matching EventName

        my @SubscriptionID = @{$tmp->get_subscription_id(-name=>"Poor Runs Warning")};
        my @expected_result = [3];
        eq_or_diff(@SubscriptionID,@expected_result,'Retrieved SubscriptionID of the SubscriptionEvent record with the matching EventName Stock Supply Low'); 

    }
}

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Subscription", 'new');
    {
        ## <insert tests for new method here> ##

    }
}

if ( !$method || $method =~ /\badd_Subscription\b/ ) {
    can_ok("alDente::Subscription", 'add_Subscription');
    {
        ## <insert tests for add_Subscription method here> ##

    }


}

if ( !$method || $method =~ /\bget_Subscription\b/ ) {
    can_ok("alDente::Subscription", 'get_Subscription');
    {
        $tmp = alDente::Subscription->new(-dbc => $dbc);
        print $tmp->get_Subscription(-subscription_event_id=>1);
    }
}

if ( !$method || $method =~ /\badd_Subscriber\b/ ) {
    can_ok("alDente::Subscription", 'add_Subscriber');
    {
        ## <insert tests for add_Subscriber method here> ##
    }

}

if ( !$method || $method =~ /\bupdate_Subscriber\b/ ) {
    can_ok("alDente::Subscription", 'update_Subscriber');
    {

    }
}

if ( !$method || $method =~ /\bdelete_Subscriber\b/ ) {
    can_ok("alDente::Subscription", 'delete_Subscriber');
    {

    }
}

if ( !$method || $method =~ /\bget_Subscriber\b/ ) {

    can_ok("alDente::Subscription", 'get_Subscriber');
    {
           # Subscriber:
        # +--------------+-----------------+-----------------+
        # | Subscriber_ID| Subscriber_Type |FK_Employee_ID   |
        # +--------------------------------+-----------------+
        # |        1     | Emp             | 10              |
        # +--------------+-----------------+-----------------+
	$tmp = alDente::Subscription->new(-dbc=>$dbc); 
	
	# Test Case 1: enter a non existing SubscriptionID returns an empty array (i.e. No match)
        my $EmailLists = $tmp->get_Subscriber(9413);

        eq_or_diff($EmailLists,[],'Undefined SubscriptionID returns no matches'); 


	# Test Case 2: enter an existing SubscriptionID returns the email addresses of all the Subscriber records as an array with the matching SubscriptionID
        my @EmailLists = sort @{$tmp->get_Subscriber(7)};

	my @ExpectedEmailLists = $dbc->Table_find("Employee,GrpEmployee","Email_Address","WHERE FK_Grp__ID in (6,7,10,11,16,19,24,25,26,40) and Employee_ID = FK_Employee__ID and employee_status = 'Active' order by email_address asc",-distinct=>1,-debug=>0);

        eq_or_diff(\@EmailLists,\@ExpectedEmailLists,'Retrieved Subscriber Email addresses with the matching SubscriptionID=7'); 

    }
}


if ( !$method || $method =~ /\bfind_Subscription\b/ ) {
    can_ok("alDente::Subscription", 'find_Subscription');
    {

    }
}

if ( !$method || $method =~ /\bsend_notification\b/ ) {
    can_ok("alDente::Subscription", 'send_notification');
    {
# After a discussion with Ran, we agreed that we should only be notified if the unit test for send_notification fails instead of reciving an email everytime send_notification ran successfully.  Currently I haven't figured out the way to do this so I will commented out the test on this method for now.  AL

    }
}

if ( !$method || $method =~ /\bsubscription_log\b/ ) {
    can_ok("alDente::Subscription", 'subscription_log');
    {
	my $subscription = alDente::Subscription->new(-dbc=>$dbc);
	$subscription->subscription_log("testing", -file_path=>"$Configs{'data_log_dir'}/subscriptions/testing");
	my $line = `cat $Configs{'data_log_dir'}/subscriptions/testing`;
	is($line,'testing',"log ok");
	`rm $Configs{'data_log_dir'}/subscriptions/testing`;
    }
}
 



## END of TEST ##

ok( 1 ,'Completed Subscription test');

exit;
