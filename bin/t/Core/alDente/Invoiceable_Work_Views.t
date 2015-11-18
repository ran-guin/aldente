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
use alDente::Invoiceable_Work_Views;
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




use_ok("alDente::Invoiceable_Work_Views");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Invoiceable_Work_Views", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Invoiceable_Work_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_update_funding_page\b/ ) {
    can_ok("alDente::Invoiceable_Work_Views", 'confirm_update_funding_page');
    {
        ## <insert tests for confirm_update_funding_page method here> ##
    }
}

if ( !$method || $method =~ /\bappend_iw_comment_btn\b/ ) {
    can_ok("alDente::Invoiceable_Work_Views", 'append_iw_comment_btn');
    {
        ## <insert tests for append_iw_comment_btn method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_update_funding_btn\b/ ) {
    can_ok("alDente::Invoiceable_Work_Views", 'confirm_update_funding_btn');
    {
        ## <insert tests for confirm_update_funding_btn method here> ##
    }
}

if ( !$method || $method =~ /\bget_child_invoiceable_work_ref_table\b/ ) {
    can_ok("alDente::Invoiceable_Work_Views", 'get_child_invoiceable_work_ref_table');
    {
        ## <insert tests for get_child_invoiceable_work_ref method here> ##
    }
}

if ( !$method || $method =~ /\bget_invoiceable_work_for_invoice_report\b/ ) {
    can_ok("alDente::Invoiceable_Work_Views", 'get_invoiceable_work_for_invoice_report');
    {
        ## <insert tests for get_invoiceable_work_for_invoice_report method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Invoiceable_Work_Views test');

exit;
