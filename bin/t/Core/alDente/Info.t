#!/usr/local/bin/perl
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
use alDente::Info;
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




use_ok("alDente::Info");

if ( !$method || $method=~/\bGoHome\b/ ) {
    can_ok("alDente::Info", 'GoHome');
    {
        ## <insert tests for GoHome method here> ##
    }
}

if ( !$method || $method=~/\bstandard_page\b/ ) {
    can_ok("alDente::Info", 'standard_page');
    {
        ## <insert tests for standard_page method here> ##
    }
}

if ( !$method || $method=~/\bDefault_Home\b/ ) {
    can_ok("alDente::Info", 'Default_Home');
    {
        ## <insert tests for Default_Home method here> ##
    }
}

if ( !$method || $method=~/\binfo\b/ ) {
    can_ok("alDente::Info", 'info');
    {
        ## <insert tests for info method here> ##
    }
}


if ( !$method || $method=~/\bcontact_info\b/ ) {
    can_ok("alDente::Info", 'contact_info');
    {
        ## <insert tests for contact_info method here> ##
    }
}

if ( !$method || $method=~/\borganization_info\b/ ) {
    can_ok("alDente::Info", 'organization_info');
    {
        ## <insert tests for organization_info method here> ##
    }
}

if ( !$method || $method=~/\buser_info\b/ ) {
    can_ok("alDente::Info", 'user_info');
    {
        ## <insert tests for user_info method here> ##
    }
}

if ( !$method || $method=~/\btable_info\b/ ) {
    can_ok("alDente::Info", 'table_info');
    {
        ## <insert tests for table_info method here> ##
    }
}

if ( !$method || $method=~/\badd_suggestion\b/ ) {
    can_ok("alDente::Info", 'add_suggestion');
    {
        ## <insert tests for add_suggestion method here> ##
    }
}

if ( !$method || $method=~/\blist_suggestions\b/ ) {
    can_ok("alDente::Info", 'list_suggestions');
    {
        ## <insert tests for list_suggestions method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Info test');

exit;
