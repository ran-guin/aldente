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
use alDente::Import_App;
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




use_ok("alDente::Import_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Import_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bentry_page\b/ ) {
    can_ok("alDente::Import_App", 'entry_page');
    {
        ## <insert tests for entry_page method here> ##
    }
}

if ( !$method || $method =~ /\bupload_file\b/ ) {
    can_ok("alDente::Import_App", 'upload_file');
    {
        ## <insert tests for upload_file method here> ##
    }
}

if ( !$method || $method =~ /\bupload_Link\b/ ) {
    can_ok("alDente::Import_App", 'upload_Link');
    {
        ## <insert tests for upload_Link method here> ##
    }
}

if ( !$method || $method =~ /\b_get_Published_path\b/ ) {
    can_ok("alDente::Import_App", '_get_Published_path');
    {
        ## <insert tests for _get_Published_path method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Import_App test');

exit;
