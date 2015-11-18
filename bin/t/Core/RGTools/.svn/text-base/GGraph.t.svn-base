#!/usr/bin/perl

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
use Test::More;
use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
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


sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new RGTools::GGraph(%args);

}

############################################################
use_ok("RGTools::GGraph");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("GGraph", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bwrapper\b/ ) {
    can_ok("GGraph", 'wrapper');
    {
        ## <insert tests for wrapper method here> ##
    }
}

if ( !$method || $method =~ /\bset_options\b/ ) {
    can_ok("GGraph", 'set_options');
    {
        ## <insert tests for set_options method here> ##
    }
}

if ( !$method || $method =~ /\bgoogle_chart\b/ ) {
    can_ok("GGraph", 'google_chart');
    {
        ## <insert tests for google_chart method here> ##
    }
}

if ( !$method || $method =~ /\bgoogle_data\b/ ) {
    can_ok("GGraph", 'google_data');
    {
        ## <insert tests for google_data method here> ##
    }
}

if ( !$method || $method =~ /\bconvert_data\b/ ) {
    can_ok("GGraph", 'convert_data');
    {
        ## <insert tests for convert_data method here> ##
    }
}

if ( !$method || $method =~ /\bmerge_data\b/ ) {
    can_ok("GGraph", 'merge_data');
    {
        ## <insert tests for merge_data method here> ##
    }
}

if ( !$method || $method =~ /\boptions_interface\b/ ) {
    can_ok("GGraph", 'options_interface');
    {
        ## <insert tests for options_interface method here> ##
    }
}

if ( !$method || $method =~ /\bparse_output_parameters\b/ ) {
    can_ok("GGraph", 'parse_output_parameters');
    {
        ## <insert tests for parse_output_parameters method here> ##
    }
}

if ( !$method || $method =~ /\bwarning\b/ ) {
    can_ok("GGraph", 'warning');
    {
        ## <insert tests for warning method here> ##
    }
}

if ( !$method || $method =~ /\bboolean\b/ ) {
    can_ok("GGraph", 'boolean');
    {
        ## <insert tests for boolean method here> ##
    }
}

if ( !$method || $method =~ /\b_string_required\b/ ) {
    can_ok("GGraph", '_string_required');
    {
        ## <insert tests for _string_required method here> ##
    }
}

if ( !$method || $method =~ /\b_initialize\b/ ) {
    can_ok("GGraph", '_initialize');
    {
        ## <insert tests for _initialize method here> ##
    }
}

if ( !$method || $method =~ /\b_init_data\b/ ) {
    can_ok("GGraph", '_init_data');
    {
        ## <insert tests for _init_data method here> ##
    }
}

if ( !$method || $method =~ /\b_draw\b/ ) {
    can_ok("GGraph", '_draw');
    {
        ## <insert tests for _draw method here> ##
    }
}

if ( !$method || $method =~ /\b_close\b/ ) {
    can_ok("GGraph", '_close');
    {
        ## <insert tests for _close method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed GGraph test');

exit;
