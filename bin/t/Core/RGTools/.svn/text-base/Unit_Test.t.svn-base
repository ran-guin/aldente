#!/usr/local/bin/perl

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
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use RGTools::Unit_Test;
############################
############################################################
use_ok("RGTools::Unit_Test");

my $self = new Unit_Test();
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Unit_Test", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bform_wrapped\b/ ) {
    can_ok("Unit_Test", 'form_wrapped');
    {
        ## <insert tests for form_wrapped method here> ##
    }
}

if ( !$method || $method=~/\bfind_modules\b/ ) {
    can_ok("Unit_Test", 'find_modules');
    {
        ## <insert tests for find_modules method here> ##
    }
}

if ( !$method || $method=~/\bfind_module\b/ ) {
    can_ok("Unit_Test", 'find_module');
    {
        ## <insert tests for find_module method here> ##
    }
}

if ( !$method || $method=~/\bfind_methods\b/ ) {
    can_ok("Unit_Test", 'find_methods');
    {
        ## <insert tests for find_methods method here> ##
    }
}

if ( !$method || $method=~/\bget_file\b/ ) {
    can_ok("Unit_Test", 'get_file');
    {
        ## <insert tests for get_file method here> ##
    }
}

if ( !$method || $method=~/\bget_unit_test\b/ ) {
    can_ok("Unit_Test", 'get_unit_test');
    {
        ## <insert tests for get_unit_test method here> ##
    }
}

if ( !$method || $method=~/\brun_test\b/ ) {
    can_ok("Unit_Test", 'run_test');
    {
        ## <insert tests for run_test method here> ##
    }
}

if ( !$method || $method=~/\btest_output\b/ ) {
    can_ok("Unit_Test", 'test_output');
    {
        ## <insert tests for test_output method here> ##
    }
}

if ( !$method || $method=~/\bfailure_test_output\b/ ) {
    can_ok("Unit_Test", 'failure_test_output');
    {
        ## <insert tests for failure_test_output method here> ##
    }
}

if ( !$method || $method=~/\bdump_Benchmarks\b/ ) {
    can_ok("Unit_Test", 'dump_Benchmarks');
    {
        ## <insert tests for dump_Benchmarks method here> ##
    }
}

if ( !$method || $method=~/\btable_count\b/ ) {
    can_ok("Unit_Test", 'table_count');
    {
        ## <insert tests for table_count method here> ##
    }
}

if ( !$method || $method=~/\brow_count\b/ ) {
    can_ok("Unit_Test", 'row_count');
    {
        ## <insert tests for row_count method here> ##
    }
}

if ( !$method || $method=~/\bcolumn_count\b/ ) {
    can_ok("Unit_Test", 'column_count');
    {
        ## <insert tests for column_count method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Unit_Test test');

exit;


=comment

    my $self    = shift;
    my %args    = @_;
    my $dbc     = $args{-connection};
    my $methods = $args{-methods};

    if ( not defined $methods or $methods =~ /\bbasic\b/ ) {
        my $module  = "SDB::DBIO";
        my $path    = $self->{path};
        my @modules = $self->find_modules('SDB');
        is( int(@modules), 21, "Found modules" );
        ok( int( $self->find_methods( 'SDB', 'DBIO' ) ) > 100,
            "Found methods" );
        ok( $self->find_module($module), "Found DBIO module" );
        my ( $package, $local_unit_test ) = $self->get_unit_test($module);
        ok( $local_unit_test, "retrieved unit test" );
        is(
            substr( $local_unit_test, 0, 15 ),
            'sub unit_test {',
            'found proper block start'
        );
        is(
            substr( $local_unit_test, length($local_unit_test) - 19, 19 ),
            "return 'completed';",
            'found proper block ending'
        );
        is( $self->get_file( 'SDB', 'DBIO' ),
            "$path/SDB/DBIO.pm", "found file" );
        is( $self->get_file('SDB/DBIO'),  "$path/SDB/DBIO.pm", "found file" );
        is( $self->get_file('SDB::DBIO'), "$path/SDB/DBIO.pm", "found file" );

        my $hash_std  = { 'Test' => 'hash', 'Test2' => 'pass' };
        my $hash_same = { 'Test' => 'hash', 'Test2' => 'pass' };
        my $hash_diff = { 'Test' => 'hash', 'Test2' => 'fail' };
        is_deeply( $hash_std, $hash_same, "Same hash" );
        is_deeply( $hash_std, $hash_diff, "Different hash" );
    }
    return 'completed';

=cut

