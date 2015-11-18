#!/usr/local/bin/perl
 
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl/";
use lib $FindBin::RealBin . "/../../lib/perl/Core/";
use lib $FindBin::RealBin . "/../../lib/perl/Imported/";
use lib $FindBin::RealBin . "/../../lib/perl/Plugins/";

use SDB::DBIO;
use RGTools::RGIO;
use Cluster::Cluster;
use XML::Simple;
use alDente::Subscription;
use RGTools::HTML_Table;
use RGTools::Process_Monitor;

use vars qw($opt_help $opt_host $opt_dbase $opt_user $opt_quiet $opt_test $opt_debug $opt_queue);

&GetOptions(
    'help|h|?'     => \$opt_help,
    'host=s'       => \$opt_host,
    'dbase|d=s'    => \$opt_dbase,
    'user|u=s'     => \$opt_user,
    'quiet'        => \$opt_quiet,
    'test|t'       => \$opt_test,
    'debug'        => \$opt_debug,
    'queue|q=s'    => \$opt_queue,
);

my $help       = $opt_help;
my $host       = $opt_host;
my $dbase      = $opt_dbase;
my $user       = $opt_user;
my $quiet      = $opt_quiet;
my $test       = $opt_test;
my $debug      = $opt_debug;
my $queue_list = $opt_queue;

if( $help ) {
	&display_help();
	exit;
}

if( !$host || !$dbase || !$user ) {
	print "Database connection information is required! Please specify host, database and user name!\n\n";
	&display_help();
	exit;
}

my $cluster_obj = new Cluster::Cluster( -test => $test, -host=>$host, -dbase=>$dbase, -user=>$user );
my $cluster_dir = $cluster_obj->{cluster_dir};
my $reported_dir = "$cluster_dir/reported";

# exit if locked
if( -e "$cluster_dir/.lock" ) {
	print "The script is locked.\n";
	exit;
}

my $Report = Process_Monitor->new();

# write a lock file
open my $LOCK, '>', "$cluster_dir/.lock";
close $LOCK;

my $today       = today();
my $log_file    = "$cluster_dir/logs/JOBS_$today.log";

my $timestamp = &date_time();
$cluster_obj->log( "\n############  check_cluster_jobs.pl executed on $timestamp #############\n" );
$cluster_obj->log( "---- test flag on ----\n" ) if ($test);
$cluster_obj->log( "lock file $cluster_dir/.lock created" );

$cluster_obj->write_logs( -log_file=> $log_file, -debug => $debug );
#&write_log();

my @cluster_queues;
if ($queue_list) {
    @cluster_queues = Cast_List( -list => $queue_list, -to => 'Array' );
}
else {
    @cluster_queues = $cluster_obj->get_cluster_queues();
}
@cluster_queues = sort @cluster_queues;

my $continue = 1;
while ( $continue ) {
	$continue = 0;
	$timestamp = &date_time();
	$cluster_obj->log( "\n----------  $timestamp ----------\n" );
		
	my %report;
	foreach my $cluster_queue (@cluster_queues) {
    	next if ( $cluster_queue eq 'test__test' );    # skip the test queue test__test
    	$cluster_obj->log("Processing queue $cluster_queue ...");

    	my $message = $cluster_obj->check_in_process_jobs( -queue => $cluster_queue );

    	$report{$cluster_queue} = $message if ( keys %$message );
		&generate_jobs_report( -message => $message );
		
		## send out notice if there are errors 
	    my @error_logs = @{ $cluster_obj->get_error_logs() };
	    $cluster_obj->clean_error_logs();
		if( @error_logs ) {
    		my $error_table = new HTML_Table();
    		$error_table->Set_Headers( [ "Error_Messages" ] );
    		$error_table->Set_Row( [ "" ] );
    		foreach my $msg ( @error_logs ) {
    			$error_table->Set_Row( [$msg] );
    		}
    		my $body = $error_table->Printout();
			$cluster_obj->send_notice( 
				-subject	=> "Cluster Job Scheduling Error (from Subscription Module)", 
				-name		=> "Cluster Job Scheduling Error", 
				-from		=> "Cluster Monitor <aldente\@bcgsc.ca>", 
				-body		=> $body, 
				-content_type => 'html',
			);
		
			print "Error logs:\n";
			print Dumper \@error_logs;
		my $errors = Dumper \@error_logs;
		$Report->set_Error("$errors");
		}
		
    	# Write to log file
    	#&write_log();
		$cluster_obj->write_logs( -log_file=> $log_file, -debug => $debug );

	}
}

# remove lock file
try_system_command( -command => "rm $cluster_dir/.lock" );

$cluster_obj->log("\nLock file removed\n");
#&write_log();
$cluster_obj->write_logs( -log_file=> $log_file, -debug => $debug );

$Report->completed();
$Report->DESTROY();

exit;

# generate report
sub generate_jobs_report {
	my %args = @_;
	my %report = %{$args{-message}};
	
    my $running_table = new HTML_Table();
    $running_table->Set_Headers( [ "Queue", "Job ID", "Job Type", "Hours_after_submission", "Set_Time_limit(hours)", "qstat", "in_process_file" ] );
    $running_table->Set_Row( [ " ", " ", " ", " ", " ", " ", "" ] );

    my $terminated_table = new HTML_Table();
    $terminated_table->Set_Headers( [ "Queue", "Job ID", "Job Name", "Job Type", "qacct" ] );
    $terminated_table->Set_Row( [ " ", " ", " ", " ", " " ] );

    my $unkown_table = new HTML_Table();
    $unkown_table->Set_Headers( [ "Queue", "Job ID", "Job Name", "Job Type", "Hours_after_submission", "Time_limit(hours)", "in_process file" ] );
    $unkown_table->Set_Row( [ " ", " ", " ", " ", " ", " ", " " ] );

    my $running_jobs_count    = 0;
    my $terminated_jobs_count = 0;
    my $unknown_jobs_count    = 0;

	## grab all reported jobs
	my @reported = ();
	push @reported, glob( "$reported_dir/*" );
	
    foreach my $category ( keys %report ) {
        foreach my $job_id ( keys %{ $report{$category} } ) {
            if ( $report{$category}{$job_id}{qstat} ) {
            	## if this job has been reported, skip
            	next if( grep /^$reported_dir\/$job_id$/, @reported );
            	 
                $running_jobs_count++;
                $running_table->Set_Row( [ $report{$category}{$job_id}{queue_name}, $job_id, $report{$category}{$job_id}{type}, $report{$category}{$job_id}{span}, $report{$category}{$job_id}{limit}, $report{$category}{$job_id}{qstat}, $report{$category}{$job_id}{in_process_file} ] );
                
                # set the reported flag
                my $command = "touch $reported_dir/$job_id";
                try_system_command( -command => "$command" );
            }
        }
    }

    my $abnormal_jobs_count = $running_jobs_count;
    if ($abnormal_jobs_count) {

        # get dbc connection for send_notification() use only
        my $dbc = new SDB::DBIO(
            -host     => $host,
            -dbase    => $dbase,
            -user     => $user,
            -connect  => 1,
        );

        my $body = '';
        if ($terminated_jobs_count) {
            $terminated_table->Set_Title("<H3> $terminated_jobs_count Jobs Terminated Unexpectedly </H3>");
            $body .= $terminated_table->Printout();
        }
        if ($running_jobs_count) {
            $running_table->Set_Title("<H3> $running_jobs_count Jobs Not Finished in expected time limit </H3>");
            $body .= $running_table->Printout();
        }
        if ($unknown_jobs_count) {
            $unkown_table->Set_Title("<H3> $unknown_jobs_count Jobs with in_process file exist but cluster status unknown </H3>");
            $body .= $unkown_table->Printout();
        }

        my $subject = "Cluster Monitor: Abnormal Jobs Report (from Subscription Module)";
        my $name    = "Cluster Monitor: Abnormal Jobs Report";
        my $from    = "Cluster Monitor <aldente\@bcgsc.ca>";

		$cluster_obj->send_notice( 
				-subject	=> $subject, 
				-name		=> $name, 
				-from		=> $from, 
				-body		=> $body, 
				-content_type => 'html',
		);
    }
}

sub display_help {
    print <<HELP;

Syntax
======
schedule_cluster_jobs.pl - This is a wrapper script for cluster job scheduling.

Arguments:
=====

-- required arguments --
-host				: specify database host, ie: -host lims02. For email notification purpose only. 
-dbase, -d			: specify database, ie: -dbase sequence. For email notification purpose only. 
-user, -u			: specify database user. For email notification purpose only. 



-- optional arguments --
-help, -h, -?		: displays this help. (optional)
-quiet, -q			: flag to turn off message printing
-test, -t			: flag to tell the script that this is a test. No jobs will be submitted to cluster in a test mode.
-debug				: flag to turn on debug message printing
-queue, -q			: specify the list of queue names, ie: -q flow1.q__m0001,test__test


Example
=======
schedule_cluster_jobs.pl -host lims02 -d seqtest -u viewer -p xxxx -t
schedule_cluster_jobs.pl -host lims02 -d seqtest -u viewer -p xxxx -q flow1.q__m0001


HELP
}		
