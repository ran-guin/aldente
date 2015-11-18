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
use alDente::DBIntegrity;
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




use_ok("alDente::DBIntegrity");

if ( !$method || $method=~/\b_start_cmdline_mode\b/ ) {
    can_ok("alDente::DBIntegrity", '_start_cmdline_mode');
    {
        ## <insert tests for _start_cmdline_mode method here> ##
    }
}

if ( !$method || $method=~/\b_start_web_mode\b/ ) {
    can_ok("alDente::DBIntegrity", '_start_web_mode');
    {
        ## <insert tests for _start_web_mode method here> ##
    }
}

if ( !$method || $method=~/\b_start_form\b/ ) {
    can_ok("alDente::DBIntegrity", '_start_form');
    {
        ## <insert tests for _start_form method here> ##
    }
}

if ( !$method || $method=~/\b_print_task_page\b/ ) {
    can_ok("alDente::DBIntegrity", '_print_task_page');
    {
        ## <insert tests for _print_task_page method here> ##
    }
}

if ( !$method || $method=~/\b_print_login_form\b/ ) {
    can_ok("alDente::DBIntegrity", '_print_login_form');
    {
        ## <insert tests for _print_login_form method here> ##
    }
}

if ( !$method || $method=~/\bprint_fk_tables\b/ ) {
    can_ok("alDente::DBIntegrity", 'print_fk_tables');
    {
        ## <insert tests for print_fk_tables method here> ##
    }
}

if ( !$method || $method=~/\bperform_fk_checks\b/ ) {
    can_ok("alDente::DBIntegrity", 'perform_fk_checks');
    {
        ## <insert tests for perform_fk_checks method here> ##
    }
}

if ( !$method || $method=~/\bprint_errchks\b/ ) {
    can_ok("alDente::DBIntegrity", 'print_errchks');
    {
        ## <insert tests for print_errchks method here> ##
    }
}

if ( !$method || $method=~/\bperform_cmd_indexcheck\b/ ) {
    can_ok("alDente::DBIntegrity", 'perform_cmd_indexcheck');
    {
        ## <insert tests for perform_cmd_indexcheck method here> ##
    }
}

if ( !$method || $method=~/\bperform_cmdchks\b/ ) {
    can_ok("alDente::DBIntegrity", 'perform_cmdchks');
    {
        ## <insert tests for perform_cmdchks method here> ##
    }
}

if ( !$method || $method=~/\bshow_errchk_details\b/ ) {
    can_ok("alDente::DBIntegrity", 'show_errchk_details');
    {
        ## <insert tests for show_errchk_details method here> ##
    }
}

if ( !$method || $method=~/\bperform_refchks\b/ ) {
    can_ok("alDente::DBIntegrity", 'perform_refchks');
    {
        ## <insert tests for perform_refchks method here> ##
    }
}

if ( !$method || $method=~/\bdescribe_table\b/ ) {
    can_ok("alDente::DBIntegrity", 'describe_table');
    {
        ## <insert tests for describe_table method here> ##
    }
}

if ( !$method || $method=~/\bshow_tables\b/ ) {
    can_ok("alDente::DBIntegrity", 'show_tables');
    {
        ## <insert tests for show_tables method here> ##
    }
}

if ( !$method || $method=~/\b_check_fk_field\b/ ) {
    can_ok("alDente::DBIntegrity", '_check_fk_field');
    {
        ## <insert tests for _check_fk_field method here> ##
    }
}

if ( !$method || $method=~/\b_split_fk_field_name\b/ ) {
    can_ok("alDente::DBIntegrity", '_split_fk_field_name');
    {
        ## <insert tests for _split_fk_field_name method here> ##
    }
}

if ( !$method || $method=~/\b_execute_cmd_str\b/ ) {
    can_ok("alDente::DBIntegrity", '_execute_cmd_str');
    {
        ## <insert tests for _execute_cmd_str method here> ##
    }
}

if ( !$method || $method=~/\b_combine_fields\b/ ) {
    can_ok("alDente::DBIntegrity", '_combine_fields');
    {
        ## <insert tests for _combine_fields method here> ##
    }
}

if ( !$method || $method=~/\b_adjust_font\b/ ) {
    can_ok("alDente::DBIntegrity", '_adjust_font');
    {
        ## <insert tests for _adjust_font method here> ##
    }
}

if ( !$method || $method=~/\bmandatory_field_check\b/ ) {
    can_ok("alDente::DBIntegrity", 'mandatory_field_check');
    {
        ## <insert tests for mandatory_field_check method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DBIntegrity test');

exit;
