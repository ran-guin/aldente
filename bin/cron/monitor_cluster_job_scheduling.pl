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
use alDente::Subscription;

use vars qw($opt_help $opt_host $opt_dbase $opt_user );

&GetOptions(
    'help|h|?'     => \$opt_help,
    'host=s'       => \$opt_host,
    'dbase|d=s'    => \$opt_dbase,
    'user|u=s'     => \$opt_user,
);

my $help  = $opt_help;
my $host  = $opt_host;
my $dbase = $opt_dbase;
my $user  = $opt_user;

if ( !$host || !$dbase || !$user ) {
    print
        "Database connection information is required! Please specify host, database, and user name!\n\n";
    &display_help();
    exit;
}

my $cluster_obj = new Cluster::Cluster();
my $cluster_dir = $cluster_obj->{cluster_dir};

## check cluster log file
my $today    = today();
my $log_file = "$cluster_dir/logs/JOBS_$today.log";
if ( -f $log_file ) {
    my ( $output, $stderr ) = try_system_command( -command => "stat -c %Y $log_file" );
    if ($output) {
        my $last_modification_time = $output;
        chomp($last_modification_time);
        my $time_gap = time() - $last_modification_time;

# not being updated over 30 minutes and .lock file exists - this indicates an abnormal situation
        if ( $time_gap >= 1800 && -e "$cluster_dir/.lock" ) {
            ## check if the schedule_cluster_jobs.pl process exists
            my $command = "ps -C schedule_cluster_jobs.pl";
            my ( $out, $err ) = try_system_command( -command => $command );
            if ($out) {
                my @arr = split '\n', $out;
                shift @arr;    # shift out the header
                my $process_exist = scalar(@arr);
                if ( !$process_exist ) {    # process died without removing .lock file
                    my $now = now();
                    print "\n---- $now ----\n";
                    print
                        "$time_gap seconds elapsed since the last modification of $log_file\n";
                    print "$cluster_dir/.lock exists\n";
                    print "schedule_cluster_jobs.pl process doesn't exist\n";

                    # remove the lock file
                    my $ok      = 1;
                    my $command = "rm -f $cluster_dir/.lock";
                    my ( $output1, $stderr1 ) = try_system_command( -command => $command );
                    if ( !$stderr1 ) {
                        print "$cluster_dir/.lock removed!\n";
                    }
                    else {
                        print "ERROR occurred when running command $command: $stderr1\n";
                        $ok = 0;
                    }

                    my $message
                        = "The following indicates an abnormal activity of the cron job bin/cron/schedule_cluster_jobs.pl:\n";
                    $message
                        .= "- $time_gap seconds elapsed since the last modification of $log_file\n";
                    $message .= "- $cluster_dir/.lock exists\n";
                    $message .= "- schedule_cluster_jobs.pl process doesn't exist\n";
                    $message
                        .= "\nIt is possible that the cron job died and left the lock file unremoved.\n";
                    if ($ok) {
                        $message .= "$cluster_dir/.lock has been removed!\n";
                        $message
                            .= "The cluster job scheduling should be back to normal. Please double check.\n";
                    }
                    else {
                        $message
                            .= "Error occurred when trying to remove $cluster_dir/.lock: $stderr1\n";
                        $message .= "Please check!\n";
                    }

                    # send out notice
                    my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                    );
                    &send_notice( -body => $message, );

                }
            }
        }

    }
}
exit;

#############################
# Check request lock file
#
# Return: none
###########################
sub check_request_lock {
###########################	
	my ( $this_host, $err ) = try_system_command( -command => 'hostname' );
	chomp( $this_host );
	my $request_lock_file = "$cluster_dir/.request_lock";
	my $try_count = 3;
	my $not_sure_count = 0;
	while( $try_count > 0 ) {
    	my $command = "head $request_lock_file";
    	my ( $output, $stderr ) = try_system_command( -command => $command );
    	if ($output) {
    		chomp( $output );
    		if( $output =~ /(\d+)\@(.+)/ ) {
    			my $pid = $1;
    			my $host = $2;
    			my $cmd = "ps -p $pid";
    			## using ssh is not a preferrable way since it might get into the authentication problem, e.g. ask to confirm RSA key fingerprint. 
    			if( $host ne $this_host ) {
    				$cmd = "ssh $host \"$cmd\"";
    			}
    			print "running command $cmd\n";
    			my ( $output2, $stderr2 ) = try_system_command( -command => $cmd );
    			if( $output2 =~ /$pid/ ) { # process exists
    				# do nothing
    			}
    			else { # process not exist any more, remove the lock file
    				my $ok = &remove_file( -filename => $request_lock_file );
                    &send_notice( -body => "ERROR removing $request_lock_file.\nContent: $output\n$pid\@$host does not exist!\n" ) if( !$ok );
    			}
    			last;
    		}
    		else { # unrecoginized format
    			# not sure if it's temporary, try again
    			$not_sure_count++;
    		}
    	}
    	else {
    			# not sure if it's temporary, try again
    			$not_sure_count++;
    	}
    	$try_count--;
    	sleep( 2 );
	}
	
	if( $try_count <= 0 && $not_sure_count >= 3 ) { # it is not temporary, remove the lock file
    				my $ok = &remove_file( -filename => $request_lock_file );
                    &send_notice( -body => "ERROR removing $request_lock_file.\n" ) if( !$ok );
	}
}	
	

	
####################################
# Remove a specified file
#
# Return:	1 on success; 0 on failure
######################
sub remove_file {
    my %args = @_;
	my $filename = $args{-filename};
		
                    my $command = "rm -f $filename";
                    my ( $stdout, $stderr ) = try_system_command( -command => $command );
                    if ( !$stderr ) {
                        print "$filename removed!\n";
                        return 1;
                    }
                    else {
                        print "ERROR occurred when running command $command: $stderr\n";
                        return 0;
                    }
}

# send out notification
sub send_notice {
    my %args = @_;
    my $body = $args{-body};

    # get dbc connection for send_notification() use only
    my $dbc = new SDB::DBIO(
        -host     => $host,
        -dbase    => $dbase,
        -user     => $user,
        -connect  => 1,
    );

    my $subject
        = "Cluster Monitor: Abnormal cluster log activity (from Subscription Module) - Test";
    my $name = "Cluster Monitor: Abnormal cluster log activity";
    my $from = "Cluster Monitor <aldente\@bcgsc.ca>";

    alDente::Subscription::send_notification(
        -dbc     => $dbc,
        -name    => $name,
        -from    => $from,
        -subject => $subject,
        -body    => $body
    );
}

sub display_help {
    print <<HELP;

Syntax
======
cluster_lock_monitor.pl - This script monitors the activity of the cron job schedule_cluster_jobs.pl and reports abnormal situations.

Arguments:
=====

-- required arguments --
-host				: specify database host, ie: -host lims02 
-dbase, -d			: specify database, ie: -dbase sequence 
-user, -u			: specify database user. 



-- optional arguments --
-help, -h, -?		: displays this help. (optional)


Example
=======
cluster_lock_monitor.pl -h lims02 -d seqtest -u viewer -p xxxx 

HELP
}

