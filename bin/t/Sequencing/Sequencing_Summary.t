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

    return new Sequencing::Sequencing_Summary(%args);

}

############################################################
use_ok("Sequencing::Sequencing_Summary");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Sequencing::Sequencing_Summary", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bpreset_input_fields\b/ ) {
    can_ok("Sequencing::Sequencing_Summary", 'preset_input_fields');
    {
        ## <insert tests for preset_input_fields method here> ##
    }
}

if ( !$method || $method =~ /\bpreset_output_fields\b/ ) {
    can_ok("Sequencing::Sequencing_Summary", 'preset_output_fields');
    {
        ## <insert tests for preset_output_fields method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("Sequencing::Sequencing_Summary", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_input_options\b/ ) {
    can_ok("Sequencing::Sequencing_Summary", 'display_input_options');
    {
        ## <insert tests for display_input_options method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_output_options\b/ ) {
    can_ok("Sequencing::Sequencing_Summary", 'display_output_options');
    {
        ## <insert tests for display_output_options method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Sequencing_Summary test');

exit;
