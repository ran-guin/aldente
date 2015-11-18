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

use vars qw(%Configs $opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_run_dir_suffix $opt_quiet);

&GetOptions(
    'help|h|?'         => \$opt_help,
    'host=s'           => \$opt_host,
    'dbase|d=s'        => \$opt_dbase,
    'user|u=s'         => \$opt_user,
    'password|p=s'     => \$opt_password,
    'run_dir_suffix=s' => \$opt_run_dir_suffix,
    'quiet|q'          => \$opt_quiet,
);

my $help           = $opt_help;
my $host           = $opt_host;
my $dbase          = $opt_dbase;
my $user           = $opt_user;
my $pwd            = $opt_password;
my $run_dir_suffix = $opt_run_dir_suffix || '';
my $quiet          = $opt_quiet;

if ($help) {
    &display_help();
    exit;
}

my $lock_file = $Configs{data_submission_workspace_dir} . "/.calculate_submission_run_checksum.lock";

# exit if locked
if ( -e "$lock_file" ) {
    print "The script is locked.\n";
    exit;
}

# write a lock file
try_system_command( -command => "touch $lock_file" );

my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my %run_file_types = ( 'SRF' => '.srf', );
my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};

my @logs     = ();
my $today    = today();
my $LOG_FILE = "$SUBMISSION_WORK_PATH/logs/calculate_submission_run_checksum_$today.log";
if ( !-e $LOG_FILE ) {
    my $log_file_ok = RGTools::RGIO::create_file( -name => $LOG_FILE, -chgrp => 'lims', -chmod => 'g+w' );
    if ($log_file_ok) {
        &log("Created $LOG_FILE");
    }
    else {
        &log("ERROR: Create $LOG_FILE failed: $!");
    }
}

my $runs = &get_runs_by_status( -status_pattern => '.create.done' );
foreach my $run ( keys %$runs ) {
    foreach my $run_file_type ( keys %{ $runs->{$run} } ) {
        my $run_dir       = $runs->{$run}{$run_file_type};
        my $checksum_file = "$SUBMISSION_WORK_PATH/$run_dir/.checksum";
        my ($lane) = $dbc->Table_find( -table => 'SolexaRun', -fields => 'Lane', -condition => "WHERE FK_Run__ID = $run", -distinct => 1 );
        my $run_data_file = "$SUBMISSION_WORK_PATH/$run_dir/Run$run" . "Lane$lane$run_file_types{$run_file_type}";
        my $checksum;
        if ( !-f $checksum_file && -f $run_data_file ) {
            &log("calculating MD5 checksum for run $run ... ...");
            $checksum = RGTools::RGIO::get_MD5( -file => $run_data_file );

            # store the checksum in a file for reuse
            my $ok = RGTools::RGIO::create_file( -name => ".checksum", -content => $checksum, -path => "$SUBMISSION_WORK_PATH", -dir => "$run_dir", -chgrp => 'lims', -chmod => 'g+w' );
            if ($ok) {
                &log("Checksum $checksum for run $run has been stored in $checksum_file");
            }
            else {
                &log("ERROR: Could not create file $checksum_file to store the checksum $checksum for run $run");
            }
        }
        &write_log( -file => $LOG_FILE );
    }
}

# remove lock file
try_system_command( -command => "rm $lock_file" );
exit;

#######################################################
# Retrieve the requests
#
# Usage		: my %requests =  %{get_requests()};
#
# Return	: Hash ref of the requests
#######################################################
sub get_runs_by_status {
############################
    my %args = filter_input( \@_, -args => 'status_pattern' ) or err ("Improper input");
    my $status_pattern = $args{-status_pattern};    # .create.done
    my %requests;

    my $command = "find $SUBMISSION_WORK_PATH -name 'Run*' -maxdepth 1 -printf \"%f\n\" ";
    my ( $output, $stderr ) = try_system_command( -command => $command );
    if ($output) {
        my @run_dirs = split /\n/, $output;
        my $file_to_search = "$status_pattern" . "_*";
        $status_pattern =~ s|\.|\\\.|g;
        foreach my $run_dir (@run_dirs) {
            $command = "find $SUBMISSION_WORK_PATH/$run_dir -name $file_to_search -maxdepth 1 -printf \"%f\n\" ";
            ( $output, $stderr ) = try_system_command( -command => $command );
            if ($output) {
                ## get the run id
                if ( $run_dir =~ /Run(\d+)/ ) {
                    my $run_id = $1;
                    my @files = split /\n/, $output;
                    foreach my $file (@files) {
                        if ( $file =~ /$status_pattern\_(.*)/ ) {
                            my $run_file_type = $1;
                            $requests{$run_id}{$run_file_type} = $run_dir;
                        }
                    }
                }
            }
        }
    }
    return \%requests;
}

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
calculate_submission_run_checksum.pl - This script calculates the MD5 checksum for the run data files.

Arguments:
=====

-- required arguments --
-host			: specify database host, ie: -host limsdev02 
-dbase, -d		: specify database, ie: -d seqdev. 
-user, -u		: specify database user. 
-passowrd, -p	: password for the user account

-- optional arguments --
-help, -h, -?		: displays this help. (optional)
-run_dir_suffix		: specify the suffix of the run data directory. 

Example
=======
calculate_submission_run_checksum.pl -host lims05 -d seqtest -u user -p xxxxxx


HELP

}
