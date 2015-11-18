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
use alDente::Library_Views;
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




use_ok("alDente::Library_Views");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Library_Views", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bancestry_view\b/ ) {
    can_ok("alDente::Library_Views", 'ancestry_view');
    {
        ## <insert tests for ancestry_view method here> ##
    }
}

if ( !$method || $method =~ /\bset_status_box\b/ ) {
    can_ok("alDente::Library_Views", 'set_status_box');
    {
        ## <insert tests for set_status_box method here> ##
        #my $page = alDente::Library_Views::set_status_box();
        #ok( $page =~ /In Production/, 'set_status_box' ); 
    }
}

if ( !$method || $method =~ /\bget_Library_Header\b/ ) {
    can_ok("alDente::Library_Views", 'get_Library_Header');
    {
        ## <insert tests for get_Library_Header method here> ##
    }
}

if ( !$method || $method =~ /\blibrary_qc_status_view\b/ ) {
    can_ok("alDente::Library_Views", 'library_qc_status_view');
    {
        ## <insert tests for library_qc_status_view method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Library_Views test');

exit;
