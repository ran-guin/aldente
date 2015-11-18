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
use alDente::Lane;
############################

############################################


use_ok("alDente::Lane");

if ( !$method || $method=~/\b_get_lane_well_mapping\b/ ) {
    can_ok("alDente::Lane", '_get_lane_well_mapping');
    {
        ## <insert tests for home_page method here> ##
        
        my @lane_fields = qw(FK_GelRun__ID FK_Sample__ID Lane_Number Lane_Status Well Lane_Growth);
        #my $result = &alDente::Lane::_get_lane_well_mapping(-dbc=>$dbc,-run_ids=>"80452,80453",-fields=>\@lane_fields);
        #my $encoded = md5_hex(objToJson($result));
        #is($encoded,'f85d9fd284581c691a07a5395b1290f4',"Retrieved correct mapping");
        
        my $result = &alDente::Lane::_get_lane_well_mapping(-dbc=>$dbc,-run_ids=>"80452,80453",-fields=>\@lane_fields);   
        my $encoded = md5_hex(JSON::to_json($result));
        is($encoded, 'f85d9fd284581c691a07a5395b1290f4',"Retrieved correct mapping");

    }
}

## END of TEST ##

ok( 1 ,'Completed Lane test');

exit;
