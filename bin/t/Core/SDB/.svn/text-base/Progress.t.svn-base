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

    return new SDB::Progress(%args);

}

############################################################
use_ok("SDB::Progress");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::Progress", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\b_initialize\b/ ) {
    can_ok("SDB::Progress", '_initialize');
    {
        ## <insert tests for _initialize method here> ##
    }
}

if ( !$method || $method =~ /\bupdate\b/ ) {
    can_ok("SDB::Progress", 'update');
    {
        ## <insert tests for update method here> ##
    }
}

if ( !$method || $method =~ /\bimg_line\b/ ) {
    can_ok("SDB::Progress", 'img_line');
    {
        ## <insert tests for img_line method here> ##
    }
}

if ( !$method || $method =~ /\bcomplete\b/ ) {
    can_ok("SDB::Progress", 'complete');
    {
        ## <insert tests for complete method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Progress test');

exit;
