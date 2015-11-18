#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    # Example:     $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new Mapping::Mapping_API(%args);

}

############################################################
use_ok("Mapping::Mapping_API");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Mapping_API", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bset_analysis_status\b/ ) {
    can_ok("Mapping_API", 'set_analysis_status');
    {
        ## <insert tests for set_analysis_status method here> ##
    }
}

if ( !$method || $method =~ /\bfail_lane\b/ ) {
    can_ok("Mapping_API", 'fail_lane');
    {
        ## <insert tests for fail_lane method here> ##
    }
}

if ( !$method || $method =~ /\bunfail_lanes\b/ ) {
    can_ok("Mapping_API", 'unfail_lanes');
    {
        ## <insert tests for unfail_lanes method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_lanes\b/ ) {
    can_ok("Mapping_API", 'create_lanes');
    {
        ## <insert tests for create_lanes method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_bands\b/ ) {
    can_ok("Mapping_API", 'update_bands');
    {
        ## <insert tests for update_bands method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_lane_mapping\b/ ) {
    can_ok("Mapping_API", 'update_lane_mapping');
    {
        ## <insert tests for update_lane_mapping method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Mapping_API test');

exit;
