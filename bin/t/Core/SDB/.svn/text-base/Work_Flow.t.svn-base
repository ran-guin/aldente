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
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
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

    return new SDB::Work_Flow(%args);

}

############################################################
use_ok("SDB::Work_Flow");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::Work_Flow", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bload\b/ ) {
    can_ok("SDB::Work_Flow", 'load');
    {
        ## <insert tests for load method here> ##
    }
}

if ( !$method || $method =~ /\bget_Full_Filename\b/ ) {
    can_ok("SDB::Work_Flow", 'get_Full_Filename');
    {
        ## <insert tests for get_Full_Filename method here> ##
    }
}

if ( !$method || $method =~ /\bsave_Condition_Fields\b/ ) {
    can_ok("SDB::Work_Flow", 'save_Condition_Fields');
    {
        ## <insert tests for save_Condition_Fields method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Work_Flow test');

exit;
