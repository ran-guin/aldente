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
use alDente::CGI_App;
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




use_ok("alDente::CGI_App");

if ( !$method || $method =~ /\bgo_button\b/ ) {
    can_ok("alDente::CGI_App", 'go_button');
    {
        ## <insert tests for go_button method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_session_attribute\b/ ) {
    can_ok("alDente::CGI_App", 'validate_session_attribute');
    {
        ## <insert tests for validate_session_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_for_session_info\b/ ) {
    can_ok("alDente::CGI_App", 'prompt_for_session_info');
    {
        ## <insert tests for prompt_for_session_info method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_session_info\b/ ) {
    can_ok("alDente::CGI_App", 'update_session_info');
    {
        ## <insert tests for update_session_info method here> ##
    }
}

if ( !$method || $method =~ /\b_session_attributes\b/ ) {
    can_ok("alDente::CGI_App", '_session_attributes');
    {
        ## <insert tests for _session_attributes method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed CGI_App test');

exit;
