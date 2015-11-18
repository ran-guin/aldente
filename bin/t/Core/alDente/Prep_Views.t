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
use alDente::Prep_Views;
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




use_ok("alDente::Prep_Views");

if ( !$method || $method =~ /\bprompt_Step\b/ ) {
    can_ok("alDente::Prep_Views", 'prompt_Step');
    {
        ## <insert tests for prompt_Step method here> ##
    }
}

if ( !$method || $method =~ /\bProtocol_step_page\b/ ) {
    can_ok("alDente::Prep_Views", 'Protocol_step_page');
    {
        ## <insert tests for Protocol_step_page method here> ##
    }
}

if ( !$method || $method =~ /\b_print_Prep_footer\b/ ) {
    can_ok("alDente::Prep_Views", '_print_Prep_footer');
    {
        ## <insert tests for _print_Prep_footer method here> ##
    }
}

if ( !$method || $method =~ /\b_get_not_completed_prompt\b/ ) {
    can_ok("alDente::Prep_Views", '_get_not_completed_prompt');
    {
        ## <insert tests for _print_Prep_footer method here> ##
	use alDente::Prep;
	use alDente::Prep_Views;
		
	my $prep = new alDente::Prep(-dbc => $dbc);
	
	#set up test data
	$prep->{non_repeatable} = 1;
	$prep->{plate_ids} = '654445,654446,654447,654448,654449,654450';
	$prep->{Plates_Completed} = '654448,654449,654450';
	
	my $prompt = alDente::Prep_Views::_get_not_completed_prompt($prep);
	#print Dumper $prompt;
	my $test = grep /Remove/, $prompt;
	is($test, 1, "Returned remove plates link");
	
	$prep->{plate_ids} = '654448,654449,654450';
	$prompt = alDente::Prep_Views::_get_not_completed_prompt($prep);
	$test = grep /Remove/, $prompt;
	is($test, 0, "All plates completed protocol");
    }
}

## END of TEST ##

ok( 1 ,'Completed Prep_Views test');

exit;
