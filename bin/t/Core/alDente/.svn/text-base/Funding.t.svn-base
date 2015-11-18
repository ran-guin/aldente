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
use alDente::Funding;
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




use_ok("alDente::Funding");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Funding", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_funding_ids\b/ ) {
    can_ok("alDente::Funding", 'search_funding_ids');
    {
        ## <insert tests for search_funding_ids method here> ##
    }
}

if ( !$method || $method =~ /\bget_funding_ids\b/ ) {
    can_ok("alDente::Funding", 'get_funding_ids');
    {
        ## <insert tests for get_funding_ids method here> ##
    }
}

if ( !$method || $method =~ /\bget_Projects\b/ ) {
    can_ok("alDente::Funding", 'get_Projects');
    {
        ## <insert tests for get_Projects method here> ##
    }
}

if ( !$method || $method =~ /\bget_Libraries\b/ ) {
    can_ok("alDente::Funding", 'get_Libraries');
    {
        ## <insert tests for get_Libraries method here> ##
    }
}

if ( !$method || $method =~ /\bget_detail_ids\b/ ) {
    can_ok("alDente::Funding", 'get_detail_ids');
    {
        ## <insert tests for get_detail_ids method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_ids\b/ ) {
    can_ok("alDente::Funding", 'get_plate_ids');
    {
        ## <insert tests for get_plate_ids method here> ##
    }
}

if ( !$method || $method =~ /\bfunding_analysis_trigger\b/ ) {
    can_ok("alDente::Funding", 'funding_analysis_trigger');
    {
        ## <insert tests for funding_analysis_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bget_db_object\b/ ) {
    can_ok("alDente::Funding", 'get_db_object');
    {
        ## <insert tests for get_db_object method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_work_request\b/ ) {
    can_ok("alDente::Funding", 'validate_work_request');
    {
        ## <insert tests for validate_work_request method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_active_funding\b/ ) {
    can_ok("alDente::Funding", 'validate_active_funding');
    {
        ## <insert tests for validate_active_funding method here> ##
        my $pass = $self->validate_active_funding( -dbc => $dbc, -plates => '666635', -fatal => 'protocol', -value => '194' );
        is( $pass, 1, "validate_active_funding - valid funding");
        my $pass = $self->validate_active_funding( -dbc => $dbc, -plates => '484928', -fatal => 'protocol', -value => '194' );
        is( $pass, 0, "validate_active_funding - invalid funding");
    }
}

if ( !$method || $method =~ /\b_return_value\b/ ) {
    can_ok("alDente::Funding", '_return_value');
    {
        ## <insert tests for _return_value method here> ##
    }
}

if ( !$method || $method =~ /\bunion\b/ ) {
    can_ok("alDente::Funding", 'union');
    {
        ## <insert tests for union method here> ##
    }
}
if ( !$method || $method =~ /\bget_funding_analysis_reference\b/ ) {
    can_ok("alDente::Funding", 'get_funding_analysis_reference');
    {
        ## <insert tests for union method here> ##
        my $funding = self(-dbc=>$dbc);        
        my $reference = $funding->get_funding_analysis_reference(-run_analysis_id=>26920);
        is ($reference,77,"Found ref");
        my $reference = $funding->get_funding_analysis_reference(-multiplex_run_analysis_id=>30202);
        is ($reference,18,"Found ref");
        my $reference = $funding->get_funding_analysis_reference(-multiplex_run_analysis_id=>28091);
        is ($reference,75,"Found ref");
    }
}
if ( !$method || $method =~ /\bget_funding_genome_reference\b/ ) {
    can_ok("alDente::Funding", 'get_funding_genome_reference');
    {
        my $funding = self(-dbc=>$dbc);
        my $reference = $funding->get_funding_genome_reference(-library=>'IX0651');
        print Dumper $reference;
       
    }
}
## END of TEST ##

ok( 1 ,'Completed Funding test');

exit;
