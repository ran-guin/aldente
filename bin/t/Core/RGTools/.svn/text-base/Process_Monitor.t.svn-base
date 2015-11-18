#!/usr/local/bin/perl

use strict;

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
use Test::More qw(no_plan);

my $opt_method;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test
use SDB::CustomSettings qw(%Configs);

############################
use RGTools::Process_Monitor;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );

############################################################
use_ok("RGTools::Process_Monitor");

# my $self = new Process_Monitor(-dbc=>$dbc);
my $self = Process_Monitor->new();

 if ( !$method || $method=~/\bnew\b/ ) {
         can_ok("Process_Monitor", 'new');
         {
             ## <insert tests for new method here> ##
         }
 }
 
 if ( !$method || $method=~/\bcron_dir\b/ ) {
         can_ok("Process_Monitor", 'cron_dir');
         {
             ## <insert tests for cron_dir method here> ##
         }
 }
 
 if ( !$method || $method=~/\bset_notify\b/ ) {
         can_ok("Process_Monitor", 'set_notify');
         {
             ## <insert tests for set_notify method here> ##
         }
 }
                            
 if ( !$method || $method=~/\bset_Message\b/ ) {
     can_ok("Process_Monitor", 'set_Message');
     {
         ## <insert tests for set_Message method here> ##
     }
 }
 
 if ( !$method || $method=~/\bset_Warning\b/ ) {
     can_ok("Process_Monitor", 'set_Warning');
     {
         ## <insert tests for set_Warning method here> ##
     }
 }
 
 if ( !$method || $method=~/\bset_Error\b/ ) {
     can_ok("Process_Monitor", 'set_Error');
     {
         ## <insert tests for set_Error method here> ##
     }
 }
 
 if ( !$method || $method=~/\bset_Detail\b/ ) {
     can_ok("Process_Monitor", 'set_Detail');
     {
         ## <insert tests for set_Detail method here> ##
     }
 }
 
 if ( !$method || $method=~/\bsucceeded\b/ ) {
     can_ok("Process_Monitor", 'succeeded');
     {
         ## <insert tests for succeeded method here> ##
     }
 }
 
 if ( !$method || $method=~/\bcompleted\b/ ) {
     can_ok("Process_Monitor", 'completed');
     {
         ## <insert tests for completed method here> ##
     }
 }
 
 if ( !$method || $method=~/\bDESTROY\b/ ) {
     can_ok("Process_Monitor", 'DESTROY');
     {
         ## <insert tests for DESTROY method here> ##
     }
 }
 
 if ( !$method || $method=~/\b_is_different\b/ ) {
     can_ok("Process_Monitor", '_is_different');
     {
         ## <insert tests for _is_different method here> ##
     }
 }
 
 if ( !$method || $method=~/\b_get_last_message\b/ ) {
     can_ok("Process_Monitor", '_get_last_message');
     {
         ## <insert tests for _get_last_message method here> ##
     }
 }
 
 if ( !$method || $method=~/\b_write_to_log\b/ ) {
     can_ok("Process_Monitor", '_write_to_log');
     {
         ## <insert tests for _write_to_log method here> ##
     }
 }
 
 if ( !$method || $method=~/\bcreate_HTML_page\b/ ) {
     can_ok("Process_Monitor", 'create_HTML_page');
     {
         ## <insert tests for create_HTML_page method here> ##
     }
 }
 
 if ( !$method || $method=~/\bsimplify\b/ ) {
     can_ok("Process_Monitor", 'simplify');
     {
         ## <insert tests for simplify method here> ##
     }
 }
 
 if ( !$method || $method=~/\b_log_repeat_message\b/ ) {
     can_ok("Process_Monitor", '_log_repeat_message');
     {
         ## <insert tests for _log_repeat_message method here> ##
     }
 }
 
 if ( !$method || $method=~/\b_send_notification\b/ ) {
     can_ok("Process_Monitor", '_send_notification');
     {
         ## <insert tests for _send_notification method here> ##
     }
 }
 
 if ( !$method || $method=~/\b_report_incomplete\b/ ) {
     can_ok("Process_Monitor", '_report_incomplete');
     {
         ## <insert tests for _report_incomplete method here> ##
     }
 }

 if ( !$method || $method=~/\bwrite_lock\b/ ) {
     can_ok("Process_Monitor", 'write_lock');
     {
         ## <insert tests for write_lock method here> ##
		my $lock = $self->write_lock();
		ok( $self->{lock}, 'write_lock' );
     }
 }
 if ( !$method || $method=~/\bremove_lock\b/ ) {
     can_ok("Process_Monitor", 'remove_lock');
     {
         ## <insert tests for remove_lock method here> ##
		$self->remove_lock();
		my $lock_file = $self->log_dir() . '/'. $self->{title} . '.lock';
		my $exist = 0;
		if( -f $lock_file ) { $exist = 1 }
		ok( !$exist, 'remove_lock' );
     }
 }

$self->completed();

## END of TEST ##

ok( 1 ,'Completed Process_Monitor test');

exit;
