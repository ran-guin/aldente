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

    return new SDB::DB_Manage(%args);

}

############################################################
use_ok("SDB::DB_Manage");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::DB_Manage", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\badd_enum_values\b/ ) {
    can_ok("SDB::DB_Manage", 'add_enum_values');
    {
        ## <insert tests for add_enum_values method here> ##
    }
}

if ( !$method || $method =~ /\bget_field_info_hash\b/ ) {
    can_ok("SDB::DB_Manage", 'get_field_info_hash');
    {
        ## <insert tests for get_field_info_hash method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_field_definition\b/ ) {
    can_ok("SDB::DB_Manage", 'generate_field_definition');
    {
        ## <insert tests for generate_field_definition method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Manage test');

exit;
