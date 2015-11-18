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
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";

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

    return new Sequencing::Primer(%args);

}

############################################################
use_ok("Sequencing::Primer");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Sequencing::Primer", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_primer_order\b/ ) {
    can_ok("Sequencing::Primer", 'display_primer_order');
    {
        ## <insert tests for display_primer_order method here> ##
    }
}

if ( !$method || $method =~ /\bsend_primer_email\b/ ) {
    can_ok("Sequencing::Primer", 'send_primer_email');
    {
        ## <insert tests for send_primer_email method here> ##
    }
}

if ( !$method || $method =~ /\bget_ChemistryInfo\b/ ) {
    can_ok("Sequencing::Primer", 'get_ChemistryInfo');
    {
        ## <insert tests for get_ChemistryInfo method here> ##
    }
}

if ( !$method || $method =~ /\bview_source_remap_primer_plates\b/ ) {
    can_ok("Sequencing::Primer", 'view_source_remap_primer_plates');
    {
        ## <insert tests for view_source_remap_primer_plates method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Primer test');

exit;
