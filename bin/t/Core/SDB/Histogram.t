#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::Histogram;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("SDB::Histogram");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::Histogram", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bBorder\b/ ) {
    can_ok("SDB::Histogram", 'Border');
    {
        ## <insert tests for Border method here> ##
    }
}

if ( !$method || $method=~/\bGet_Colours\b/ ) {
    can_ok("SDB::Histogram", 'Get_Colours');
    {
        ## <insert tests for Get_Colours method here> ##
    }
}

if ( !$method || $method=~/\bSet_Background\b/ ) {
    can_ok("SDB::Histogram", 'Set_Background');
    {
        ## <insert tests for Set_Background method here> ##
    }
}

if ( !$method || $method=~/\bSet_Colour\b/ ) {
    can_ok("SDB::Histogram", 'Set_Colour');
    {
        ## <insert tests for Set_Colour method here> ##
    }
}

if ( !$method || $method=~/\bSet_Shades\b/ ) {
    can_ok("SDB::Histogram", 'Set_Shades');
    {
        ## <insert tests for Set_Shades method here> ##
    }
}

if ( !$method || $method=~/\bSet_Bins\b/ ) {
    can_ok("SDB::Histogram", 'Set_Bins');
    {
        ## <insert tests for Set_Bins method here> ##
    }
}

if ( !$method || $method=~/\bSet_X_Axis\b/ ) {
    can_ok("SDB::Histogram", 'Set_X_Axis');
    {
        ## <insert tests for Set_X_Axis method here> ##
    }
}

if ( !$method || $method=~/\bSet_Y_Axis\b/ ) {
    can_ok("SDB::Histogram", 'Set_Y_Axis');
    {
        ## <insert tests for Set_Y_Axis method here> ##
    }
}

if ( !$method || $method=~/\bNumber_of_Colours\b/ ) {
    can_ok("SDB::Histogram", 'Number_of_Colours');
    {
        ## <insert tests for Number_of_Colours method here> ##
    }
}

if ( !$method || $method=~/\bGroup_Colours\b/ ) {
    can_ok("SDB::Histogram", 'Group_Colours');
    {
        ## <insert tests for Group_Colours method here> ##
    }
}

if ( !$method || $method=~/\bSet_Height\b/ ) {
    can_ok("SDB::Histogram", 'Set_Height');
    {
        ## <insert tests for Set_Height method here> ##
    }
}

if ( !$method || $method=~/\bSet_Path\b/ ) {
    can_ok("SDB::Histogram", 'Set_Path');
    {
        ## <insert tests for Set_Path method here> ##
    }
}

if ( !$method || $method=~/\bHorizontalLine\b/ ) {
    can_ok("SDB::Histogram", 'HorizontalLine');
    {
        ## <insert tests for HorizontalLine method here> ##
    }
}

if ( !$method || $method=~/\bDrawIt\b/ ) {
    can_ok("SDB::Histogram", 'DrawIt');
    {
        ## <insert tests for DrawIt method here> ##
    }
}

if ( !$method || $method=~/\bDrawLine\b/ ) {
    can_ok("SDB::Histogram", 'DrawLine');
    {
        ## <insert tests for DrawLine method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Histogram test');

exit;
