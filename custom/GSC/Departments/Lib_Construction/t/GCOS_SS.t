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

    return new Lib_Construction::GCOS_SS(%args);

}

############################################################
use_ok("Lib_Construction::GCOS_SS");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Lib_Construction::GCOS_SS", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_sheet\b/ ) {
    can_ok("Lib_Construction::GCOS_SS", 'create_sheet');
    {
        ## <insert tests for create_sheet method here> ##
    }
}

if ( !$method || $method =~ /\bgen_sheet\b/ ) {
    can_ok("Lib_Construction::GCOS_SS", 'gen_sheet');
    {
        ## <insert tests for gen_sheet method here> ##
    }
}

if ( !$method || $method =~ /\bconfigure_gcos_config\b/ ) {
    can_ok("Lib_Construction::GCOS_SS", 'configure_gcos_config');
    {
        ## <insert tests for configure_gcos_config method here> ##
    }
}

if ( !$method || $method =~ /\bset_gcos_config\b/ ) {
    can_ok("Lib_Construction::GCOS_SS", 'set_gcos_config');
    {
        ## <insert tests for set_gcos_config method here> ##
    }
}

if ( !$method || $method =~ /\bassign_scanner\b/ ) {
    can_ok("Lib_Construction::GCOS_SS", 'assign_scanner');
    {
        ## <insert tests for assign_scanner method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed GCOS_SS test');

exit;
