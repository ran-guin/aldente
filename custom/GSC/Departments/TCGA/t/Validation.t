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
use RGTools::RGIO;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $host = 'limsdev04';
my $dbase = 'seqdev';
my $user   = 'viewer';
my $pwd    = 'viewer';



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

    return new TCGA::Validation(%args);

}

############################################################
use_ok("TCGA::Validation");
my $Validation = new TCGA::Validation(-dbc => $dbc);


if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("TCGA::Validation", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_Barcode\b/ ) {
    can_ok("TCGA::Validation", 'validate_Barcode');
    {
       my $ok = $Validation -> validate_Barcode (-barcode => 'TCGA-A2-A04V-01A-21R-A035-13 ');
    }
}

## END of TEST ##

ok( 1 ,'Completed Validation test');

exit;
