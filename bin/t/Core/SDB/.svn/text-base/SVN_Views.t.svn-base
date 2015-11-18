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

    return new SDB::SVN_Views(%args);

}

############################################################
use_ok("SDB::SVN_Views");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::SVN_Views", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bview_Tags\b/ ) {
    can_ok("SDB::SVN_Views", 'view_Tags');
    {
        ## <insert tests for view_Tags method here> ##
    }
}

if ( !$method || $method =~ /\bget_tag_doc\b/ ) {
    can_ok("SDB::SVN_Views", 'get_tag_doc');
    {
        ## <insert tests for get_tag_doc method here> ##
    }
}

if ( !$method || $method =~ /\bget_tickets_list\b/ ) {
    can_ok("SDB::SVN_Views", 'get_tickets_list');
    {
        ## <insert tests for get_tickets_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_tag_status\b/ ) {
    can_ok("SDB::SVN_Views", 'get_tag_status');
    {
        ## <insert tests for get_tag_status method here> ##
    }
}

if ( !$method || $method =~ /\bget_training_status\b/ ) {
    can_ok("SDB::SVN_Views", 'get_training_status');
    {
        ## <insert tests for get_training_status method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed SVN_Views test');

exit;
