#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Plugins";

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

    return new RGTools::Process_Monitor::Manager(%args);

}

############################################################
use_ok("RGTools::Process_Monitor::Manager");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Process_Monitor::Manager", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_reports\b/ ) {
    can_ok("Process_Monitor::Manager", 'generate_reports');
    {
        ## <insert tests for generate_reports method here> ##
    }
}

if ( !$method || $method =~ /\b_get_script_reports\b/ ) {
    can_ok("Process_Monitor::Manager", '_get_script_reports');
    {
        ## <insert tests for _get_script_reports method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_HTML\b/ ) {
    can_ok("Process_Monitor::Manager", 'create_HTML');
    {
        ## <insert tests for create_HTML method here> ##
    }
}

if ( !$method || $method =~ /\bprint_out\b/ ) {
    can_ok("Process_Monitor::Manager", 'print_out');
    {
        ## <insert tests for print_out method here> ##
    }
}

if ( !$method || $method =~ /\btmp_copy\b/ ) {
    can_ok("Process_Monitor::Manager", 'tmp_copy');
    {
        ## <insert tests for tmp_copy method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_summary_page\b/ ) {
    can_ok("Process_Monitor::Manager", 'create_summary_page');
    {
        ## <insert tests for create_summary_page method here> ##
    }
}

if ( !$method || $method =~ /\bsend_summary\b/ ) {
    can_ok("Process_Monitor::Manager", 'send_summary');
    {
        ## <insert tests for send_summary method here> ##
    }
}

if ( !$method || $method =~ /\b_day_of_week\b/ ) {
    can_ok("Process_Monitor::Manager", '_day_of_week');
    {
        ## <insert tests for _day_of_week method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_stats_graphs_old\b/ ) {
    can_ok("Process_Monitor::Manager", 'generate_stats_graphs_old');
    {
        ## <insert tests for generate_stats_graphs_old method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Manager test');

exit;
