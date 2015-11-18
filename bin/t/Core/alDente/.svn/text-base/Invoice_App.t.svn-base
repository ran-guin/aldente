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
use alDente::Invoice_App;
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




use_ok("alDente::Invoice_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Invoice_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Invoice_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_invoice\b/ ) {
    can_ok("alDente::Invoice_App", 'new_invoice');
    {
        ## <insert tests for new_invoice method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_add_to_invoice\b/ ) {
    can_ok("alDente::Invoice_App", 'confirm_add_to_invoice');
    {
        ## <insert tests for confirm_add_to_invoice method here> ##
    }
}

if ( !$method || $method =~ /\badd_to_invoice\b/ ) {
    can_ok("alDente::Invoice_App", 'add_to_invoice');
    {
        ## <insert tests for add_to_invoice method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_append_new_invoice\b/ ) {
    can_ok("alDente::Invoice_App", 'create_append_new_invoice');
    {
        ## <insert tests for create_append_new_invoice method here> ##
    }
}

if ( !$method || $method =~ /\bremove_from_invoice\b/ ) {
    can_ok("alDente::Invoice_App", 'remove_from_invoice');
    {
        ## <insert tests for remove_from_invoice method here> ##
    }
}

if ( !$method || $method =~ /\bremove_invoice\b/ ) {
    can_ok("alDente::Invoice_App", 'remove_invoice');
    {
        ## <insert tests for remove_invoice method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_credit\b/ ) {
    can_ok("alDente::Invoice_App", 'create_credit');
    {
        ## <insert tests for create_credit method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_invoice\b/ ) {
    can_ok("alDente::Invoice_App", 'generate_invoice');
    {
        ## <insert tests for generate_invoice method here> ##
    }
}

if ( !$method || $method =~ /\bappend_iw_comment_from_invoice\b/ ) {
    can_ok("alDente::Invoice_App", 'append_iw_comment_from_invoice');
    {
        ## <insert tests for append_iw_comment_from_invoice method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Invoice_App test');

exit;
