#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../../../lib/perl/custom";

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

    return new GSC::Views(%args);

}

############################################################
use_ok("GSC::Views");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("GSC::Views", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_genome_reference\b/ ) {
    can_ok("GSC::Views", 'display_genome_reference');
    {
        ## <insert tests for display_genome_reference method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Shipments\b/ ) {
    can_ok("GSC::Views", 'display_Shipments');
    {
        ## <insert tests for display_Shipments method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_BCR_Batch_Shipments\b/ ) {
    can_ok("GSC::Views", 'display_BCR_Batch_Shipments');
    {
        ## <insert tests for display_BCR_Batch_Shipments method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Views test');

exit;
