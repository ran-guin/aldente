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

use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
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


sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new UHTS::Spect_Summary(%args);

}

############################################################
use_ok("UHTS::Spect_Summary");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("UHTS::Spect_Summary", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bpreset_input_fields\b/ ) {
    can_ok("UHTS::Spect_Summary", 'preset_input_fields');
    {
        ## <insert tests for preset_input_fields method here> ##
    }
}

if ( !$method || $method =~ /\bconfigure\b/ ) {
    can_ok("UHTS::Spect_Summary", 'configure');
    {
        ## <insert tests for configure method here> ##
    }
}

if ( !$method || $method =~ /\bget_default_inputs\b/ ) {
    can_ok("UHTS::Spect_Summary", 'get_default_inputs');
    {
        ## <insert tests for get_default_inputs method here> ##
    }
}

if ( !$method || $method =~ /\bset_default_inputs\b/ ) {
    can_ok("UHTS::Spect_Summary", 'set_default_inputs');
    {
        ## <insert tests for set_default_inputs method here> ##
    }
}

if ( !$method || $method =~ /\bpreset_output_fields\b/ ) {
    can_ok("UHTS::Spect_Summary", 'preset_output_fields');
    {
        ## <insert tests for preset_output_fields method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Spect_Summary test');

exit;
