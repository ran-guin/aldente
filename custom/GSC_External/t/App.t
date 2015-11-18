#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../../../lib/perl/custom";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
my $dbase  = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("GSC_External::App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("GSC_External::App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_Project\b/ ) {
    can_ok("GSC_External::App", 'home_Project');
    {
        ## <insert tests for home_Project method here> ##
    }
}
if ( !$method || $method =~ /\bExternal_Submission\b/ ) {
    can_ok("GSC_External::App", 'External_Submission');
    {
        ## <insert tests for External_Submission method here> ##
    }
}
if ( !$method || $method =~ /\b_sanitize\b/ ) {
    can_ok("GSC_External::App", '_sanitize');
    {
        ## <insert tests for _sanitize method here> ##
    }
}

if ( !$method || $method =~ /\bExternal_Form_Submission\b/ ) {
    can_ok("GSC_External::App", 'External_Form_Submission');
    {
        ## <insert tests for External_Form_Submission method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed App test');

exit;
