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

my $lock_file = $Configs{data_submission_workspace_dir} . "/.update_submission_run_status.lock";

# exit if locked
if ( -e "$lock_file" ) {
    print "The script is locked.\n";
    exit;
}

# write a lock file
try_system_command( -command => "touch $lock_file" );

my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};

my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
my @statuses_to_check = ( '.upload.done', '.bundle.done', '.create.done' );
my %upper_statuses = (
    '.bundle.done' => ['.upload'],
    '.create.done' => [ '.upload', '.bundle' ],
);
my %to_statuses = (
    '.upload.done' => 'Submitted',
    '.bundle.done' => 'Bundled',
    '.create.done' => 'Created',
);
## get runs with status 'in process'
my @in_process_runs = $volume_obj->get_submission_runs( -dbc => $dbc, -run_status => "In Process" );
print Dumper \@in_process_runs;

foreach my $run_volume_ref (@in_process_runs) {
    my $run_id    = $run_volume_ref->{run};
    my $volume_id = $run_volume_ref->{volume_id};

    my $volume_info = $volume_obj->get_volume_info( -dbc => $dbc, -id => $volume_id );
    if ( !$volume_info || !defined $volume_info->{Volume_Name} ) {
        print "WARNING: Volume id $volume_id missing required volume information\n" if ( !$quiet );
        next;
    }
    my $volume_name     = $volume_info->{Volume_Name};
    my $submission_type = $volume_info->{Submission_Type};

    ## check if status file exist
    my $run_data_dir = "$SUBMISSION_WORK_PATH/Run$run_id" . $run_dir_suffix;
    if ( -d $run_data_dir ) {
        foreach my $status_pattern (@statuses_to_check) {
            my $file_to_search = "$status_pattern" . '*';

            #$status_pattern =~ s|\.|\\.|g;
            my $command = "find $run_data_dir -name $file_to_search -maxdepth 1 -printf \"%f\n\" ";
            my ( $output, $stderr ) = try_system_command( -command => $command );
            if ($output) {
                ## check if there are upper statuses. If no, do the update; if yes, no need to update
                my $upper_status_exist = 0;
                foreach my $status ( @{ $upper_statuses{$status_pattern} } ) {
                    $file_to_search = "$status" . '*';
                    $command        = "find $run_data_dir -name $file_to_search -maxdepth 1 -printf \"%f\n\" ";
                    my ( $output2, $stderr2 ) = try_system_command( -command => $command );
                    if ($output2) {
                        $upper_status_exist = 1;
                        last;    ## no need to check the downstream statuses
                    }
                }

                if ( !$upper_status_exist ) {
                    my @files = split /\n/, $output;
                    foreach my $file (@files) {
                        ## update Submission status
                        $volume_obj->set_run_data_status(
                            -dbc       => $dbc,
                            -volume_id => $volume_id,
                            -run_id    => $run_id,
                            -status    => $to_statuses{$status_pattern},
                        );

                        ## log
                        my $log_file = "$Configs{data_submission_log_dir}/$volume_name" . ".log";
                        &log(
                            -file => "$log_file",
                            -log  => "Updated Trace_Submission run $run_id volume $volume_id to $to_statuses{$status_pattern}"
                        );
                    }
                    last;    # no need to check the rest
                }    # END if( !$upper_status_exist )
            }
        }
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
                            $requests{$run_id}{$run_file_type} = 1;
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
    my %args = filter_input( \@_, -args => 'file,log' );
    my $file = $args{-file};
    my $log  = $args{ -log };

    my $timestamp = &date_time();
    print "$timestamp: $log\n";

    open my $LOG, '>>', "$file";
    print $LOG "$timestamp: $log\n";
    close($LOG);

    return;
}

##################
sub display_help {
##################
    print <<HELP;

Syntax
======
update_submission_run_status.pl - This script scans the 'In Process' runs in Trace_Submission and updates the Submission_Status.

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
update_submission_run_status.pl -host lims05 -d seqtest -u user -p xxxxxx


HELP

}
