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

    return new Statistics(%args);

}

############################################################
use_ok("Mapping::Statistics");

my $self = new Mapping::Statistics(-dbc=>$dbc);

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Mapping::Statistics", 'new');
    {
#        my %result = $self->get_run_validation_counts(-condition=>"FK_Library__Name='HTa23'");

#        my @keys = keys %result;
#        isnt(@keys,0,'Returned results');

#        is(int(@{$result{$keys[0]}}),int(@{$result{$keys[1]}}),"Rows match");
    }
}

#if ( !$method || $method =~ /\bget_run_validation_counts\b/ ) {
#    can_ok("Mapping::Statistics", 'get_run_validation_counts');
#    {
#        my %result = $self->get_run_validation_counts(-condition=>"FK_Library__Name='HTa23'");

 #       my @keys = keys %result;
 
#       isnt(@keys,0,'Returned results');

#        is(int(@{$result{$keys[0]}}),int(@{$result{$keys[1]}}),"Rows match");
#    }
#}

#if ( !$method || $method =~ /\bget_run_status_counts\b/ ) {
#    can_ok("Mapping::Statistics", 'get_run_status_counts');
#    {
#        my %result = $self->get_run_status_counts(-condition=>"FK_Library__Name='HTa23'");

#        my @keys = keys %result;
#        isnt(@keys,0,'Returned results');

#        is(int(@{$result{$keys[0]}}),int(@{$result{$keys[1]}}),"Rows match");
#    }
#}

if ( !$method || $method =~ /\bget_lab_protocol_steps\b/ ) {
    can_ok("Mapping::Statistics", 'get_lab_protocol_steps');
    {
    }
}

if ( !$method || $method =~ /\bget_pipeline_protocol_plate_counts\b/ ) {
    can_ok("Mapping::Statistics", 'get_pipeline_protocol_plate_counts');
    {
    }
}

#if ( !$method || $method =~ /\bget_run_fail_counts\b/ ) {
#    can_ok("Mapping::Statistics", 'get_run_fail_counts');
#    {
#        my %result = $self->get_run_fail_counts(-condition=>"FK_Library__Name='HTa23'");

#        my @keys = keys %result;
#        isnt(@keys,0,'Returned results');

#        is(int(@{$result{$keys[0]}}),int(@{$result{$keys[1]}}),"Rows match");
#    }
#}

#if ( !$method || $method =~ /\bget_lane_fail_counts\b/ ) {
#    can_ok("Mapping::Statistics", 'get_lane_fail_counts');
#    {
#        my %result = $self->get_lane_fail_counts(-condition=>"FK_Library__Name='HTa23'");

 #       my @keys = keys %result;
 #       isnt(@keys,0,'Returned results');

  #      is(int(@{$result{$keys[0]}}),int(@{$result{$keys[1]}}),"Rows match");
 #   }
#}

## END of TEST ##

ok( 1 ,'Completed Statistics test');

exit;
