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
use alDente::Goal;
############################

############################################


use_ok("alDente::Goal");

if ( !$method || $method=~/\bset_Library_Status\b/ ) {
    can_ok("alDente::Goal", 'set_Library_Status');
    {
        ## <insert tests for initialize_Progress method here> ##
        my @result = alDente::Goal::set_Library_Status( -dbc => $dbc, -library => 'A27820,A27821,PX0008,PX0009' );
        print Dumper \@result;
    }
}

if ( !$method || $method=~/\bget_Progress\b/ ) {
    can_ok("alDente::Goal", 'get_Progress');
    ## <insert tests for get_Progress method here> ##
        
    my $lib = 'HGL01';
   
    my %goals = %{ alDente::Goal::get_Progress(-dbc=>$dbc,-library=>$lib) };
    
    ok(defined $goals{$lib}{Completed}[0], 'completed goals defined');     
    ok(defined $goals{$lib}{Target}[0], 'Target defined');     
    ok(defined $goals{$lib}{Initial_Target}[0], 'initial target defined');     
    ok(defined $goals{$lib}{Additional_Requests}[0], 'additional requests defined');     
    ok(defined $goals{$lib}{Goal_Name}[0], 'goal names defined');     
    ok(defined $goals{$lib}{Outstanding}[0], 'outsanding goals defined');     
}

if ( !$method || $method=~/\bget_sub_goals\b/ ) {
    can_ok("alDente::Goal", 'get_sub_goals');
    {
        ## <insert tests for get_sub_goals method here> ##
        my $result = alDente::Goal::get_sub_goals( -dbc => $dbc, -goal_id => 50 );
        my $expected = [ 61, 62 ];
        is_deeply( $result, $expected, 'get_sub_goals');
    }
}

## END of TEST ##

ok( 1 ,'Completed Goal test');

exit;
