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
use alDente::Chemistry;
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




use_ok("alDente::Chemistry");

my $self = new alDente::Chemistry(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Chemistry", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\brequest_broker\b/ ) {
    can_ok("alDente::Chemistry", 'request_broker');
    {
        ## <insert tests for request_broker method here> ##
    }
}

if ( !$method || $method=~/\bdbh\b/ ) {
    can_ok("alDente::Chemistry", 'dbh');
    {
        ## <insert tests for dbh method here> ##
    }
}

if ( !$method || $method=~/\bload_chemistry\b/ ) {
    can_ok("alDente::Chemistry", 'load_chemistry');
    {
        ## <insert tests for load_chemistry method here> ##
    }
}

if ( !$method || $method=~/\blist_Formulas\b/ ) {
    can_ok("alDente::Chemistry", 'list_Formulas');
    {
        ## <insert tests for list_Formulas method here> ##
    }
}

if ( !$method || $method=~/\blist_Parameters\b/ ) {
    can_ok("alDente::Chemistry", 'list_Parameters');
    {
        ## <insert tests for list_Parameters method here> ##
    }
}

if ( !$method || $method=~/\bshow_Formula\b/ ) {
    can_ok("alDente::Chemistry", 'show_Formula');
    {
        ## <insert tests for show_Formula method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Formula\b/ ) {
    can_ok("alDente::Chemistry", 'update_Formula');
    {
        ## <insert tests for update_Formula method here> ##
    }
}

if ( !$method || $method=~/\bsave_Formula\b/ ) {
    can_ok("alDente::Chemistry", 'save_Formula');
    {
        ## <insert tests for save_Formula method here> ##
    }
}

if ( !$method || $method=~/\binitialize_Chemistry_parameters\b/ ) {
    can_ok("alDente::Chemistry", 'initialize_Chemistry_parameters');
    {
        ## <insert tests for initialize_Chemistry_parameters method here> ##
    }
}

if ( !$method || $method=~/\bget_Parameter\b/ ) {
    can_ok("alDente::Chemistry", 'get_Parameter');
    {
        ## <insert tests for get_Parameter method here> ##
    }
}

if ( !$method || $method=~/\badd_Parameter\b/ ) {
    can_ok("alDente::Chemistry", 'add_Parameter');
    {
        ## <insert tests for add_Parameter method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Parameter\b/ ) {
    can_ok("alDente::Chemistry", 'update_Parameter');
    {
        ## <insert tests for update_Parameter method here> ##
    }
}

if ( !$method || $method=~/\bChemistry_Parameters\b/ ) {
    can_ok("alDente::Chemistry", 'Chemistry_Parameters');
    {
        ## <insert tests for Chemistry_Parameters method here> ##
    }
}

if ( !$method || $method=~/\blarge_chemistry_barcode\b/ ) {
    can_ok("alDente::Chemistry", 'large_chemistry_barcode');
    {
        ## <insert tests for large_chemistry_barcode method here> ##
    }
}

if ( !$method || $method=~/\bprint_chemistry_sheet\b/ ) {
    can_ok("alDente::Chemistry", 'print_chemistry_sheet');
    {
        ## <insert tests for print_chemistry_sheet method here> ##
    }
}

if ( !$method || $method=~/\bchemistry_latex_printout\b/ ) {
    can_ok("alDente::Chemistry", 'chemistry_latex_printout');
    {
        ## <insert tests for chemistry_latex_printout method here> ##
    }
}

if ( !$method || $method=~/\bescape_latex_str\b/ ) {
    can_ok("alDente::Chemistry", 'escape_latex_str');
    {
        ## <insert tests for escape_latex_str method here> ##
    }
}

if ( !$method || $method=~/\bcreate_Formula_interface\b/ ) {
    can_ok("alDente::Chemistry", 'create_Formula_interface');
    {
        ## <insert tests for create_Formula_interface method here> ##
    }
}

if ( !$method || $method=~/\bgroups\b/ ) {
    can_ok("alDente::Chemistry", 'groups');
    {
        ## <insert tests for groups method here> ##
    }
}

if ( !$method || $method=~/\badd_group\b/ ) {
    can_ok("alDente::Chemistry", 'add_group');
    {
        ## <insert tests for add_group method here> ##
    }
}

if ( !$method || $method=~/\bget_value\b/ ) {
    can_ok("alDente::Chemistry", 'get_value');
    {
        ## <insert tests for get_value method here> ##
	## simple case, given 10 return 10
	my %param;
	my $value = 10;
	my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
	ok($result == $value, "simple case, given 10 return 10");

	## another simple case, given 0.022 return 0.022
        my %param;
        my $value = 0.022;
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == $value, "another simple case, given 0.022 return 0.022");

	## simple but with parameter, given -2 return -2
        my %param = (A => 10, B => 10);
        my $value = 2;
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == $value, "simple but with parameter, given -2 return -2");

        ## simple but with parameter, given 0 return 0
        my %param = (A => 10, B => 10);
        my $value = 0;
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == $value, "simple but with parameter, given 0 return 0");

	## no value ... should return nothing
        my %param;
        my $value;
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok(!$result, "no value ... should return nothing");

	## non number value ... should return nothing
        my %param;
        my $value = 'A';
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok(!$result, "non number value ... should return nothing");

	## Simple formula: Given (A => 10, B => 10) and A + B, return 20
        my %param = (A => 10, B => 10);
        my $value = "A + B";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 20, "Simple formula: Given (A => 10, B => 10) and A + B, return 20");

	## Another simple formula: Given (A => 10, B => 10) and A + 20, return 30
        my %param = (A => 10, B => 10);
        my $value = "A + 20";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 30, "Another simple formula: Given (A => 10, B => 10) and A + 20, return 30");

	## Undefine value: Given (A => 10, B => ) and A + B, return nothing
        my %param = (A => 10, B => );
        my $value = "A + B";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok(!$result, "Undefine value: Given (A => 10, B => ) and A + B, return nothing");

	## Undefine variable: Given (A => 10, B => 10) and A + C, return nothing
        my %param = (A => 10, B => 10);
        my $value = "A + C";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok(!$result, "Undefine variable: Given (A => 10, B => 10) and A + C, return nothing");

	## recursive variable working version Given (A => 10, B => A) and A + B, return 20
        my %param = (A => 10, B => A);
        my $value = "A + B";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
	ok($result == 20, "recursive variable working version Given (A => 10, B => A) and A + B, return 20");

	## recursive: given (A => 10, B => 10, C => A + B) and C + 20 return 40
        my %param = (A => 10, B => 10, C => "A + B");
        my $value = "C + 20";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 40, "recursive: given (A => 10, B => 10, C => A + B) and C + 20 return 40");

	## recursive: given (A => 15, B => A - 5, C => B - 5) and C + 20 return 25
        my %param = (A => 15, B => "A - 5", C => "B - 5");
        my $value = "C + 20";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 25, "recursive: given (A => 15, B => A - 5, C => B - 5) and C + 20 return 25");

	## recursive: given (A => 15, B => C - 5, C => A - 5) and B + 20 return 25
        my %param = (A => 15, B => "C - 5", C => "A - 5");
        my $value = "B + 20";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 25, "recursive worst case: given (A => 15, B => C - 5, C => A - 5) and B + 20 return 25");

	## recursive: given (A => 15, B => A - 5, C => B - 5) and C + B + A + 20 return 50
        my %param = (A => 15, B => "A - 5", C => "B - 5");
        my $value = "C + B + A + 20";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 50, "recursive: given (A => 15, B => A - 5, C => B - 5) and C + B + A + 20 return 50");

	## recursive: given (D => 15, A => D, B => A - 5, C => B - 5) and C + 20 return 50
        my %param = (D => 15, A => D, B => "A - 5", C => "B - 5");
        my $value = "C + 20";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 25, "recursive: given (D => 15, A => D, B => A - 5, C => B - 5) and C + 20 return 25");

	## recursive: given (D => 15, A => D, B => A - 5, C => B - 5) and C + 20 return 50
        my %param = (D => 15, A => D, B => "A - 5", C => "B - 5");
        my $value = "C + 20";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 25, "recursive: given (D => 15, A => D, B => A - 5, C => B - 5) and C + 20 return 25");

	## Undefine variable: Given (A => 10, B => C) and A + B, return nothing
        my %param = (A => 10, B => C);
        my $value = "A + B";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok(!$result, "Undefine variable: Given (A => 10, B => C) and A + B, return nothing");

	## Undefine variable but no used: Given (A => 10, B => C) and A + 10, return 20
        my %param = (A => 10, B => C);
        my $value = "A + 10";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 20, "Undefine variable but no used: Given (A => 10, B => C) and A + 10, return 20");

	## junk value reutrn nothing
	my %param = (A => 10, B => 10);
        my $value = "A + B () + *";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
	print "$result\n";
        ok(!$result, "junk value reutrn nothing");

        ## long formula reutrn proper value                                                                                                                                                                                           
        my %param = (A => 10, B => 10);
        my $value = "A + B/A + (A+B) * 2 / 4 - 5";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok($result == 16, "long formula reutrn proper value");

        ## self reference param reutrn nothing
        my %param = (A => "A * A", B => A);
        my $value = "B + 10";
        my $result = alDente::Chemistry::get_value(-params=>\%param, -value=>$value, -dbc=>$dbc);
        ok(!$result, "self reference param reutrn nothing");
    }
}

## END of TEST ##

ok( 1 ,'Completed Chemistry test');

exit;
