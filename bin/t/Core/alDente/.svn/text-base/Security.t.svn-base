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
use alDente::Security;
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




use_ok("alDente::Security");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Security", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\blogin_info\b/ ) {
    can_ok("alDente::Security", 'login_info');
    {
        ## <insert tests for login_info method here> ##
    }
}

if ( !$method || $method=~/\bdepartments\b/ ) {
    can_ok("alDente::Security", 'departments');
    {
        ## <insert tests for departments method here> ##
    }
}

if ( !$method || $method=~/\bLIMS_admin\b/ ) {
    can_ok("alDente::Security", 'LIMS_admin');
    {
        ## <insert tests for LIMS_admin method here> ##
    }
}

if ( !$method || $method=~/\bdepartment_access\b/ ) {
    can_ok("alDente::Security", 'department_access');
    {
        ## <insert tests for department_access method here> ##
    }
}

if ( !$method || $method=~/\bcheck\b/ ) {
    can_ok("alDente::Security", 'check');
    {
        ## <insert tests for check method here> ##
    }
}

if ( !$method || $method=~/\bget_accessible_items\b/ ) {
    can_ok("alDente::Security", 'get_accessible_items');
    {
        ## <insert tests for get_accessible_items method here> ##
    }
}

if ( !$method || $method=~/\bsecurity_checks\b/ ) {
    can_ok("alDente::Security", 'security_checks');
    {
        ## <insert tests for security_checks method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_popup_choices\b/ ) {
    can_ok("alDente::Security", 'generate_popup_choices');
    {
        ## <insert tests for generate_popup_choices method here> ##
    }
}

if ( !$method || $method=~/\bget_groups\b/ ) {
    can_ok("alDente::Security", 'get_groups');
    {
        ## <insert tests for get_groups method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_set_groups\b/ ) {
    can_ok("alDente::Security", 'display_set_groups');
    {
        ## <insert tests for display_set_groups method here> ##
    }
}

if ( !$method || $method=~/\bset_groups\b/ ) {
    can_ok("alDente::Security", 'set_groups');
    {
        ## <insert tests for set_groups method here> ##
    }
}

if ( !$method || $method=~/\bget_table_permissions\b/ ) {
    can_ok("alDente::Security", 'get_table_permissions');
    {
        ## <insert tests for get_table_permissions method here> ##
    }
}

if ( !$method || $method=~/\b_initialize\b/ ) {
    can_ok("alDente::Security", '_initialize');
    {
        ## <insert tests for _initialize method here> ##
    }
}

if ( !$method || $method=~/\bcheck_permission\b/ ) {
    can_ok("alDente::Security", 'check_permission');
    {
        ## <insert tests for check_permission method here> ##
    }
}


## END of TEST ##

ok( 1 ,'Completed Security test');

exit;
