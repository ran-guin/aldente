#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Benchmark;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";

use SDB::DBIO;
use RGTools::RGIO;
use SDB::CustomSettings;
use alDente::Submission_Volume;
use Cluster::Cluster;

use vars qw(%Configs $opt_help $opt_host $opt_dbase $opt_user $opt_password );

&GetOptions(
    'help|h|?'     => \$opt_help,
    'host=s'       => \$opt_host,
    'dbase|d=s'    => \$opt_dbase,
    'user|u=s'     => \$opt_user,
    'password|p=s' => \$opt_password,
);

my $help  = $opt_help;
my $host  = $opt_host;
my $dbase = $opt_dbase;
my $user  = $opt_user;
my $pwd   = $opt_password;

if ($help) {
    &display_help();
    exit;
}

my $lock_file = $Configs{data_submission_workspace_dir} . "/.bundle_run_data.lock";

# exit if locked
if ( -e "$lock_file" ) {
    print "The script is locked.\n";
    exit;
}

# write a lock file
try_system_command( -command => "touch $lock_file" );

my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};
my $dbc                  = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my @logs     = ();
my $today    = today();
my $LOG_FILE = "$SUBMISSION_WORK_PATH/logs/bundle_run_data_$today.log";
if ( !-e $LOG_FILE ) {
    my $log_file_ok = RGTools::RGIO::create_file( -name => "bundle_run_data_$today.log", -path => "$SUBMISSION_WORK_PATH/logs", -chgrp => 'lims', -chmod => 'g+w' );
    if ($log_file_ok) {
        &log("Created $LOG_FILE");
    }
    else {
        &log("ERROR: Create $LOG_FILE failed: $!\n");
    }
}

my $cluster       = new Cluster::Cluster();
my $job_type      = 'ZIP';
my $cluster_host  = 'm0001';
my $queue         = 'flow7.q';
my $slot_required = 1;
my $volume_obj    = new alDente::Submission_Volume( -dbc => $dbc );
my @volumes       = $volume_obj->get_volumes( -run_status => "In Process" );

#print Dumper \@volumes;
foreach my $volume_id (@volumes) {
    my $volume_name = $volume_obj->get_volume_name( -volume_id => $volume_id );
    my $volume_name_without_space = $volume_name;
    $volume_name_without_space =~ s| |_|g;    # replace space with underscore
    my $submission_dir = "$SUBMISSION_WORK_PATH/$volume_name_without_space";
    my $command        = "find $submission_dir -name '.bundle' -maxdepth 2 -printf \"%p\n\"";
    my ( $output, $stderr ) = try_system_command( -command => $command );
    if ($output) {

        #print Dumper $output;
        my @bundles = split /\n/, $output;
        foreach my $bundle (@bundles) {
            if ( -f "$bundle.done" ) {

                #my $command = "rm -f $bundle";
                #try_system_command( -command => $command );
                next;
            }

            $command = "head -1 $bundle";
            my ( $filename, $err ) = try_system_command( -command => $command );
            if ($filename) {
                chomp($filename);    # get the full job file name
                my $path;
                my $name;
                if ( $filename =~ /^(.*)\/([^\/]+)$/ ) {
                    $path = $1;
                    $name = $2;
                }
                ### submit the job to cluster

                ## check quota for job type
                my $has_quota = $cluster->check_quota(
                    -job_type => $job_type,
                    -host     => $cluster_host,
                    -queue    => $queue,
                );
                while ( !$has_quota ) {
                    &log("No quota for job type $job_type, wait!");
                    sleep(300);    #wait 5 min
                    $has_quota = $cluster->check_quota(
                        -job_type => $job_type,
                        -host     => $cluster_host -queue => $queue,
                    );
                }

                ## check free slot
                my $capacity = $cluster->get_slot_capacity( -host => $cluster_host, -queue => $queue );
                if ( defined $capacity ) {
                    my $free_slot_count = $cluster->get_free_slot_count( -host => $cluster_host, -queue => $queue );
                    my $slot_available = $free_slot_count - $slot_required;
                    while ( !$slot_available ) {
                        &log("Not enough free slots( required slot = $slot_required, free slot = $free_slot_count )! Wait!");
                        sleep(300);    #wait 5 min
                        $free_slot_count = $cluster->get_free_slot_count(
                            -host  => $cluster_host,
                            -queue => $queue
                        );
                        $slot_available = $free_slot_count - $slot_required;
                    }
                }

                $cluster->submit_to_cluster_queue(
                    -job_name    => $name,
                    -host        => $cluster_host,
                    -queue       => $queue,
                    -std_out_dir => $path,
                    -std_err_dir => $path,
                    -job_file    => $filename,
                    -job_type    => $job_type,
                );
                &write_log( -file => $LOG_FILE );
            }    # END if( $filename )
        }    # END foreach my $bundle ( @bundles )
    }    # END if( $output )
}    # END foreach my $volume_id ( @volumes )

# remove lock file
try_system_command( -command => "rm $lock_file" );
exit;

#########
sub log {
########
    my %args = filter_input( \@_, -args => 'log' );
    my $log = $args{ -log };

    my $timestamp = &date_time();
    push @logs, "$timestamp: $log" if ($log);
    print "$timestamp: $log\n";
    return;
}

################
sub write_log {
################
    my %args = filter_input( \@_, -args => 'file' );
    my $file = $args{-file};

    my $logs = join "\n", @logs;
    if ( open my $LOG, '>>', "$file" ) {
        print $LOG "$logs\n";
        close($LOG);
        @logs = ();    ## cleanup the log array
    }
    else {
        print "ERROR: open log file $file failed: $!\n";
    }

    return;
}

##################
sub display_help {
##################
    print <<HELP;

Syntax
======
bundle_run_data.pl - This script sends the jobs of bundling the run data files to clusters.

Arguments:
=====

-- required arguments --
-host			: specify database host, ie: -host limsdev02 
-dbase, -d		: specify database, ie: -d seqdev. 
-user, -u		: specify database user. 
-password, -p		: password for the user account

-- optional arguments --
-help, -h, -?		: displays this help. (optional)

Example
=======
bundle_run_data.pl -host lims05 -d seqtest -u user -p xxxxxx 

HELP

}
