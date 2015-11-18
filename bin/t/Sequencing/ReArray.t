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

    return new Sequencing::ReArray(%args);

}

############################################################
use_ok("Sequencing::ReArray");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Sequencing::ReArray", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_sequencing_rearray\b/ ) {
    can_ok("Sequencing::ReArray", 'create_sequencing_rearray');
    {
        ## <insert tests for create_sequencing_rearray method here> ##
    }
}

if ( !$method || $method =~ /\border_oligo_rearray_from_file\b/ ) {
    can_ok("Sequencing::ReArray", 'order_oligo_rearray_from_file');
    {
        ## <insert tests for order_oligo_rearray_from_file method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_clone_plates\b/ ) {
    can_ok("Sequencing::ReArray", 'search_clone_plates');
    {
        ## <insert tests for search_clone_plates method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_clone_rearray\b/ ) {
    can_ok("Sequencing::ReArray", 'create_clone_rearray');
    {
        ## <insert tests for create_clone_rearray method here> ##
    }
}

if ( !$method || $method =~ /\bautoset_primer_rearray_status\b/ ) {
    can_ok("Sequencing::ReArray", 'autoset_primer_rearray_status');
    {
        ## <insert tests for autoset_primer_rearray_status method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed ReArray test');

exit;
