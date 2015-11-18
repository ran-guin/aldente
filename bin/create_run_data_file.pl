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
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

use SDB::DBIO;
use RGTools::RGIO;

#use Sequencing::Solexa_Analysis;
use Cluster::Cluster;
use SDB::CustomSettings;
use alDente::Run;
use Illumina::Run;

use vars qw(%Configs $opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_runs $opt_flowcells $opt_flowcell_dir $opt_target_dir $opt_include $opt_include_raw $opt_no_cluster $opt_run_dir_suffix  $opt_skip_prb $opt_run_file_type );

&GetOptions(
    'help|h|?'         => \$opt_help,
    'host=s'           => \$opt_host,
    'dbase|d=s'        => \$opt_dbase,
    'user|u=s'         => \$opt_user,
    'password|p=s'     => \$opt_password,
    'runs=s'           => \$opt_runs,
    'flowcells=s'      => \$opt_flowcells,
    'include=s'        => \$opt_include,          # the condition of including approved and Production/Test runs. Default 'Approved,Production'
    'target_dir=s'     => \$opt_target_dir,       # directory to store the SRF file
    'include_raw'      => \$opt_include_raw,      # flag to include raw data
    'no_cluster'       => \$opt_no_cluster,       # flag to indicate not to submit jobs to cluster
    'run_dir_suffix=s' => \$opt_run_dir_suffix,
    'skip_prb'         => \$opt_skip_prb,         # flag to skip prb files
    'run_file_type'    => \$opt_run_file_type,    # the run file type, e.g. srf, fastq. Default is srf
);

my $help           = $opt_help;
my $host           = $opt_host;
my $dbase          = $opt_dbase;
my $user           = $opt_user;
my $pwd            = $opt_password;
my $run_list       = $opt_runs;
my $flowcell_list  = $opt_flowcells;
my $include        = $opt_include || 'Approved,Production';
my $target_dir     = $opt_target_dir;
my $include_raw    = $opt_include_raw;
my $use_cluster    = !$opt_no_cluster;
my $run_dir_suffix = $opt_run_dir_suffix || '';
my $skip_prb       = $opt_skip_prb;
my $run_file_type  = $opt_run_file_type || 'SRF';

if ($help) {
    &display_help();
    exit;
}

my $lock_file = $Configs{data_submission_workspace_dir} . "/.create_run_data_file.lock";

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

my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};
$target_dir = $SUBMISSION_WORK_PATH if ( !$target_dir );
if ( !-d $target_dir ) {
    ## create the target directory if not exist
    try_system_command( -command => "mkdir $target_dir" );
}

my @logs     = ();
my $today    = today();
my $LOG_FILE = "$SUBMISSION_WORK_PATH/logs/create_run_data_file_$today.log";
if ( !-e $LOG_FILE ) {
    my $log_file_ok = RGTools::RGIO::create_file( -name => "create_run_data_file_$today.log", -path => "$SUBMISSION_WORK_PATH/logs", -chgrp => 'lims', -chmod => 'g+w' );
    if ($log_file_ok) {
        &log("Created $LOG_FILE");
    }
    else {
        &log("ERROR: Create $LOG_FILE failed: $!\n");
    }
}

my %benchmarks;
my %flowcells;
my $run_count = 0;
my @order;
if ($run_list) {
    my @runs = Cast_List( -list => $run_list, -to => 'Array' );
    foreach my $run (@runs) {
        my ($flowcell_lane) = $dbc->Table_find( 'SolexaRun,Flowcell', 'Flowcell_Code,Lane', "WHERE FK_Run__ID = $run and FK_Flowcell__ID = Flowcell_ID" );
        my ( $flowcell, $lane ) = split ',', $flowcell_lane;
        $flowcells{$flowcell}{$lane}{run_id} = $run;

        #$flowcells{$flowcell}{$lane}{run_file_type} = [$run_file_type];
        $run_count++;
    }
}
elsif ($flowcell_list) {
    my @fcs = Cast_List( -list => $flowcell_list, -to => 'Array' );
    my $include_condition;
    if ( $include =~ /Approved/i ) {
        $include_condition .= " and Run_Validation = 'Approved'";
    }
    if ( $include =~ /Production/ ) {
        $include_condition .= " and Run_Test_Status = 'Production'";
    }
    if ( $include =~ /Test/ ) {
        $include_condition .= " and Run_Test_Status = 'Test'";
    }

    foreach my $fc (@fcs) {
        my %runs_info = $dbc->Table_retrieve(
            -table     => 'Flowcell,SolexaRun,Run',
            -fields    => [ 'Lane', 'FK_Run__ID' ],
            -condition => "WHERE Flowcell_Code = '$fc' and FK_Flowcell__ID = Flowcell_ID and FK_Run__ID = Run_ID" . $include_condition
        );
        my $index = 0;
        while ( defined $runs_info{FK_Run__ID}[$index] ) {
            my $run  = $runs_info{FK_Run__ID}[$index];
            my $lane = $runs_info{Lane}[$index];
            $flowcells{$fc}{$lane}{run_id} = $run;
            $run_count++;
            $index++;
        }
    }
}
else {    # if no run / flowcell specified, scan data submission work space run directories to gather requests that have obtained basecall dir
    my $requests = &get_requests();

    #print Dumper $requests;
    foreach my $request (@$requests) {
        my $run = $request->{run_id};
        my ($flowcell_lane) = $dbc->Table_find( 'SolexaRun,Flowcell', 'Flowcell_Code,Lane', "WHERE FK_Run__ID = $run and FK_Flowcell__ID = Flowcell_ID" );
        my ( $flowcell, $lane ) = split ',', $flowcell_lane;
        $flowcells{$flowcell}{$lane}{run_id} = $run;
        $run_count++;
        $request->{flowcell} = $flowcell;
        $request->{lane}     = $lane;
        $request->{log}      = [];
        push @order, $request;
    }
}

unless (@order) {
    foreach my $fc ( keys %flowcells ) {
        foreach my $lane ( keys %{ $flowcells{$fc} } ) {
            my %request;
            $request{flowcell}      = $fc;
            $request{lane}          = $lane;
            $request{run_file_type} = $run_file_type;
            $request{run_id}        = $flowcells{$fc}{$lane}{run_id};
            $request{log}           = [];

            my $run_dir = "Run$request{run_id}";
            if ( -e "$SUBMISSION_WORK_PATH/$run_dir/.obtain_basecall_dir.ready_SRF" ) {
                ## get the basecall dir
                my $command = "head $SUBMISSION_WORK_PATH/$run_dir/.obtain_basecall_dir.ready_SRF";
                my ( $output, $stderr ) = try_system_command( -command => $command );
                if ($output) {
                    chomp($output);
                    $request{basecall_dir} = $output;
                }
            }
            push @order, \%request;
        }
    }
}

my $request_count = scalar(@order);
my $fc_count      = keys %flowcells;
if ($request_count) {
    my $message = '';
    $message .= "The following $request_count requests on $run_count runs on $fc_count flowcells will be processed:\n";
    $message .= "Order\tFlowcell\tLane\tRun_id\tRun_file_type\n";
    my $count = 0;
    foreach my $request (@order) {
        $count++;
        $message .= "$count\t$request->{flowcell}\t$request->{lane}\t$request->{run_id}\t$request->{run_file_type}\n";
    }
    &log("$message\n");
}
else {
    &log("No request");
}

foreach my $request (@order) {
    my $fc            = $request->{flowcell};
    my $lane          = $request->{lane};
    my $run           = $request->{run_id};
    my $run_file_type = $request->{run_file_type};

    my $run_data_dir = "$target_dir/Run$run" . $run_dir_suffix;
    if ( !-d $run_data_dir ) {
        print try_system_command( -command => "mkdir $run_data_dir" );
    }

    &log("Processing $fc Lane $lane Run $run ... ...");

    ## check cluster quota and available free slots
    my $cluster_host  = 'm0001';
    my $cluster_queue = 'flow6.q';
    my $job_type      = $run_file_type;
    my $slot_required = 1;
    my $cluster       = new Cluster::Cluster(
        -host     => $host,
        -dbase    => $dbase,
        -user     => $user,
        -password => $pwd
    );

    ## check quota for job type
    my $has_quota = $cluster->check_quota(
        -job_type => $job_type,
        -queue    => $cluster_queue,
        -host     => $cluster_host
    );
    while ( !$has_quota ) {
        &log("No quota for job type $job_type, wait!");
        sleep(300);    #wait 5 min
        $has_quota = $cluster->check_quota(
            -job_type => $job_type,
            -queue    => $cluster_queue,
            -host     => $cluster_host
        );
    }

    ## check free slot
    my $capacity = $cluster->get_slot_capacity( -queue => $cluster_queue, -host => $cluster_host );
    if ( defined $capacity ) {
        my $free_slot_count = $cluster->get_free_slot_count( -queue => $cluster_queue, -host => $cluster_host );
        my $slot_available = $free_slot_count - $slot_required;
        while ( !$slot_available ) {
            &log("Not enough free slots( required slot = $slot_required, free slot = $free_slot_count )! Wait!");
            sleep(300);    #wait 5 min
            $free_slot_count = $cluster->get_free_slot_count(
                -queue => $cluster_queue,
                -host  => $cluster_host
            );
            $slot_available = $free_slot_count - $slot_required;
        }
    }

    ## create status file .create.$type
    my $status_file = "$run_data_dir/.create_$run_file_type";
    my $status_file_ok = RGTools::RGIO::create_file( -name => ".create_$run_file_type", -content => "creating", -path => $run_data_dir, -chgrp => 'lims', -chmod => 'g+w' );
    if ($status_file_ok) {
        &log("Created $status_file");
    }
    else {
        &log("ERROR: Create $status_file failed!");
    }

    ## remove any .checksum file if exists
    my $checksum_file = "$run_data_dir/.checksum";
    if ( -f "$checksum_file" ) {
        try_system_command( -command => "rm -rf $checksum_file" );
        &log("Removed $checksum_file");
    }

    if ( $run_file_type =~ /SRF/ ) {
        my $run_obj = new alDente::Run( -dbc => $dbc, -run_id => $run );
        my $run_type = $run_obj->get_run_type();
        if ( $run_type eq 'SolexaRun' ) {
            my $illumina_run_obj = new Illumina::Run( -dbc => $dbc, -run_id => $run );
            my $msg = $illumina_run_obj->create_srf(
                -dbc         => $dbc,
                -run         => $run,
                -flowcell    => $fc,
                -lane        => $lane,
                -seq_path    => $request->{basecall_dir},
                -job_path    => $run_data_dir,
                -target_path => $run_data_dir,
                -include_raw => $include_raw,
                -uncompress  => '1',
                -use_cluster => $use_cluster,
                -skip_prb    => $skip_prb,
            );
            &log($msg);
        }
    }

    &write_log( -file => $LOG_FILE );
}    # END foreach $request

# remove lock file
try_system_command( -command => "rm $lock_file" );
exit;

#######################################################
# Retrieve the requests that have basecall dir ready and sort the requests by the creation time of .obtain_basecall_dir.ready
#
# Usage		: my @requests =  @{get_requests()};
#
# Return	: array ref of the sorted requests. Each array item is a hash ref of the details of the request.
#######################################################
sub get_requests {
############################
    my %requests;

    my $command = "find $SUBMISSION_WORK_PATH -name 'Run*' -maxdepth 1 -printf \"%f\n\" ";
    my ( $output, $stderr ) = try_system_command( -command => $command );
    if ($output) {
        my @run_dirs = split /\n/, $output;
        foreach my $run_dir (@run_dirs) {
            $command = "find $SUBMISSION_WORK_PATH/$run_dir -name '.obtain_basecall_dir.ready_*' -maxdepth 1 -printf \"%f\n\" ";
            ( $output, $stderr ) = try_system_command( -command => $command );
            if ($output) {
                ## get the run id
                if ( $run_dir =~ /Run(\d+)/ ) {
                    my $run_id = $1;
                    my @request_files = split /\n/, $output;
                    foreach my $request (@request_files) {
                        if ( $request =~ /\.obtain_basecall_dir\.ready_(.*)/ ) {
                            my $run_file_type = $1;

                            ## if .create.type exists, this request has been processed. Ignore!
                            next if ( -e "$SUBMISSION_WORK_PATH/$run_dir/.create_$run_file_type" );

                            $requests{$run_id}{$run_file_type} = 1;

                            ## get the basecall dir
                            my $command = "head $SUBMISSION_WORK_PATH/$run_dir/$request";
                            ( $output, $stderr ) = try_system_command( -command => $command );
                            if ($output) {
                                chomp($output);
                                $requests{$run_id}{$run_file_type} = $output;
                            }
                        }
                    }
                }
            }
        }
    }
    return &sort_requests( -requests => \%requests );
}

#######################################################
# Sort the requests by last modified time
#
# Usage		: my $sorted =  sort_requests( -requests => \%requests );
#
# Return	: array ref of the sorted requests. Each array item is a hash ref of the details of the request.
#######################################################
sub sort_requests {
############################
    my %args = filter_input( \@_, -args => 'requests' ) or err ("Improper input");
    my $requests = $args{-requests};

    my %when;
    foreach my $run_id ( keys %$requests ) {
        foreach my $type ( keys %{ $requests->{$run_id} } ) {
            my $request_file  = "$SUBMISSION_WORK_PATH/Run$run_id/.obtain_basecall_dir.ready_$type";
            my @last_mod_time = try_system_command( -command => "stat -c %Y $request_file" );
            my $last_mod_time = chomp_edge_whitespace( $last_mod_time[0] );
            my $key           = "$run_id" . '_' . $type;
            $when{$key}{time}          = $last_mod_time;
            $when{$key}{run_id}        = $run_id;
            $when{$key}{run_file_type} = $type;
            $when{$key}{basecall_dir}  = $requests->{$run_id}{$type};
        }
    }

    my @sorted = ();
    foreach my $key ( sort { $when{$a}{time} <=> $when{$b}{time} } keys %when ) {    # sort by request time
        my %request;
        $request{run_id}        = $when{$key}{run_id};
        $request{run_file_type} = $when{$key}{run_file_type};
        $request{basecall_dir}  = $when{$key}{basecall_dir};
        push @sorted, \%request;
    }

    return \@sorted;
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
create_run_data_file.pl - This script creates the run data file for data submission.

Arguments:
=====

-- required arguments --
-host			: specify database host, ie: -host limsdev02 
-dbase, -d		: specify database, ie: -d seqdev. 
-user, -u		: specify database user. 
-passowrd, -p		: password for the user account

-- choice arguments ( One and only one must be used ) --
-runs			: specify the run ids in comma separated list format
-flowcells		: specify flowcell codes in comma separated list format. All the runs of these flowcells will be processed.

-- optional arguments --
-help, -h, -?		: displays this help. (optional)
-include			: specify the the condition of including approved and Production/Test runs. Default 'Approved,Production'
-include_raw		: flag to include raw data
-skip_prb			: flag to skip prb files
-run_file_type		: specify he run file type, e.g. SRF, fastq. Default is SRF
-target_dir			: specify the directory to create the run data folder. Default is the data submission workspace directory that is specified in $Configs{data_submission_workspace_dir}.
-run_dir_suffix		: specify the suffix of the run data directory. 
-no_cluster			: flag to indicate not to submit the jobs to cluster

Example
=======
create_run_data_file.pl -host lims05 -d seqtest -u user -p xxxxxx -runs 10779,10881 
create_run_data_file.pl -host lims05 -d seqtest -u user -p xxxxxx -flowcells 616GYAAXX,600JAAAXX -include_raw  


HELP

}
