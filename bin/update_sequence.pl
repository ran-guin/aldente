#!/usr/local/bin/perl
##############################
#
# update_sequence.pl
#
################################################################################
#
# update_sequence.pl
#
# Updates the sequence SQL database by reading data that was mirrored from
# the Sequencers. It calls phred, cross-match and analysis procedures.
#
# "Here's thirty thousand pounds,
#  quick take it before they arrest me,
#  it's hot."
#
################################################################################
################################################################################
# $Id: update_sequence.pl,v 1.55 2004/11/30 16:59:27 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.55 $
#     CVS Date: $Date: 2004/11/30 16:59:27 $
###############################################################################

use CGI qw(:standard);
use Time::Local;
use strict;
use Getopt::Std;
use Date::Calc qw(Now Today Day_of_Week);
use Storable;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::DBIO;
use SDB::Report;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Reads;
use RGTools::String;
use RGTools::Process_Monitor;
use Sequencing::Post;
use alDente::SDB_Defaults;
use alDente::Notification qw(Email_Notification);
use alDente::Employee;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
our ( $opt_h, $opt_A, $opt_x, $opt_v, $opt_S, $opt_D, $opt_i, $opt_M, $opt_t, $opt_l, $opt_v, $opt_R, $opt_r, $opt_f, $opt_F, $opt_c, $opt_L, $opt_a, $opt_b, $opt_z, $opt_m, $opt_d, $opt_P, $opt_H );

our ( $dbase, $nowdate, $nowtime, $reversal );

use vars qw( $testing           $local_drive
    $Stats_dir         $mirror_dir
    $Web_log_directory $vector_directory
    $Data_log_directory
);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $dbase      = "sequence";          ## default
my $check_name = "update_sequence";
my $actions;
my $state;                            #### flag aborted runs
my $exclusions;
my $inclusions;
my $base;
my $chemcode;
my $ver;
my $verbose = 0;                      # verbose flag.
my $force   = 0;                      # Force analysis flag. Set to 1 to force for a quadrant. Set to 2 to force no matter what.
my $seq_list;
my $machine_choice;                   # gets set to a snippet of a SELECT statement to limit runs to a particular machine
my @sequences;

######################## construct Process_Monitor object for writing to log file ###########
my $Report = Process_Monitor->new();

getopts('A:x:vS:D:i:M:t:lvRrfFhcL:abzmd:P:H:T');

my $notification = '';

### abort execution if this script is in process (excluding this instance)
my $current_processes = try_system_command("ps axwww | grep 'update_sequence.pl' | grep -v 'xemacs' | grep -v ' 0:00 ' | grep -v ' 0:01 ' | grep -v ' 0:03 '");
if ($current_processes) {
    $Report->set_Message("** already in process ** $current_processes");
    $Report->completed();
    $Report->DESTROY();
    exit;
}

$Report->set_Message( "Begin " . &date_time() );

$nowdate = sprintf( "%4d-%02d-%02d",  Today() );
$nowtime = sprintf( "%02d:%02d:%02d", Now() );

my $stamp = timestamp();

#$Data_log_directory = '/home/sequence/alDente/test/logs/';
my $directory = $opt_d || '';

if ($opt_D) { $dbase      = $opt_D; }    # database to use
if ($opt_v) { $verbose    = 1; }         # verbose mode
if ($opt_x) { $exclusions = $opt_x; }    # exclude these Run IDs
if ($opt_i) { $inclusions = $opt_i; }    # include Run IDs from inclusion file...

my $phred_file   = $opt_P || 0;          # optional - phred directory to use
my $check_zipped = $opt_z || 0;          # check for zipped files as well...
my $mirror       = $opt_m || 0;

if ($opt_R) {
    $Report->set_Message("NOTE: Reversed Plate Orientation! (full)");
    $reversal = 'full';                  # entire sequenced plate...
}

if ($opt_r) {
    $Report->set_Message("NOTE: Reversed Plate Orientation! (partial)");
    $reversal = 'partial';               # only one of 96 well plates within 384 well plate
}

if    ($opt_f) { $force = 1; }           # force analysis for quadrant of 384 well
elsif ($opt_F) { $force = 2; }           # force even if not even 96 files found

my $blast = $opt_b || 0;
my @machine_names;
my @hosts;

if ($opt_M) {
    @machine_names = split ',', $opt_M;
}

# Check that the script is being run as 'sequence' before anything is done.
my $username = try_system_command("whoami");
chomp $username;

unless ( ( $username =~ /aldente/ ) || ( $actions =~ /\s*cache\s*/i ) ) {
    $Report->set_Error("$username does NOT have permission to run update command ($actions). Please 'su sequence' and try again");
    $Report->DESTROY();

    exit;
}

if ($directory) {    ### just run analysis on a specified directory :
    $Report->set_Message("Parsing single directory: $directory");

    my $Reads = Reads->new();
    $Reads->parse_directory(
        trim        => 1,
        dir         => $directory,
        vector_file => "$vector_directory/vector",
        phredpar    => "$config_dir/phredpar.dat",
        phred_bin   => $phred_file
    );
    $Reads->create_CSV_file();
    $Report->completed();

    exit;
}

$Report->set_Detail( "Beginning " . &date_time() );

# parse dbase
my $db_host = $opt_H || $Defaults{PRODUCTION_HOST} || $Defaults{SQL_HOST};

if ( $dbase =~ /:/ ) {
    ( $db_host, $dbase ) = split ':', $dbase;
}

print "Using DB host $db_host\n";
my $Connection = SDB::DBIO->new(
    -host    => $db_host,
    -dbase   => $dbase,
    -user    => 'super_cron_user',
    -connect => 1,
    -sessionless=>1
);
my $dbc = $Connection;

## Custom insert (temporary) <CONSTRUCION> - change to allow user log in ? (remove hardcoded Admin id (141) ##
$Connection->set_local( 'user_id', 141 );

my $eo = new alDente::Employee( -dbc => $dbc, -id => 141 );
$eo->define_User();

my $auto_action;
if ($opt_a) {    ### automatic version ... runs regularly checking for 'files.mirrored' file ###
    my @mirrored = glob("$mirror_dir/mirrored.*");

    foreach my $mirrored_host (@mirrored) {

        if ( $mirrored_host =~ /mirrored\.(\S+)/ ) {

            my $host = $1;
            push @hosts, $host;
            my ($add_machine) = &Table_find( $dbc, 'Machine_Default,Equipment,Sequencer_Type', 'Equipment_Name', "WHERE FK_Equipment__ID=Equipment_ID and FK_Sequencer_Type__ID = Sequencer_Type_ID" . " AND Host like '$host'" );

            push @machine_names, $add_machine;
        }
    }

    if ( int(@machine_names) ) {

    }
    elsif ( -e "$mirror_dir/files.mirrored" ) {    ### run after mirroring
        $Report->set_Detail("Detected files.mirrored status");

        unless ($opt_l) {
            try_system_command("mv $mirror_dir/files.mirrored $mirror_dir/files.open");
            try_system_command("chmod 666 $mirror_dir/files.open");

            $auto_action = "All";
        }
    }
    elsif ( -e "$mirror_dir/analysis.request" ) {    ### run upon request
        $Report->set_Detail("Detected analysis.request status");
        my @runs;
        $force ||= 1;                                ### force analysis for runs that are specifically requested.

        open( RUNS, "$mirror_dir/analysis.request" ) or die( "cannot open $mirror_dir/analysis.request", $Report->set_Error("cannot open $mirror_dir/analysis.request"), $Report->DESTROY() );
        while (<RUNS>) {
            if (/:(.*)/) {
                &parse_options($1);
            }                                        ## parse options as specified...

            if (/^(\d+)$/) {
                push @runs, $1;
            }
        }

        close(RUNS) or die( "cannot close $mirror_dir/analysis.request", $Report->set_Error("cannot close $mirror_dir/analysis.request"), $Report->DESTROY() );

        unless ($opt_l) {
            system("mv $mirror_dir/analysis.request $mirror_dir/files.open");
            system("chmod 666 $mirror_dir/files.open");
            $auto_action = "All";
        }

        $seq_list = join ',', @runs;
    }
    elsif ( -e "$mirror_dir/cache.request" ) {    ### run upon request
        $Report->set_Detail("Detected cache.request status");
        my @runs;

        open( RUNS, "$mirror_dir/cache.request" ) or die( "cannot open $mirror_dir/cache.request", $Report->set_Error("cannot open $mirror_dir/cache.request"), $Report->DESTROY() );
        while (<RUNS>) {
            if (/^(\d+)$/) {
                push @runs, $1;
            }
        }

        close(RUNS) or die( "cannot close $mirror_dir/cache.request", $Report->set_Error("cannot close $mirror_dir/cache.request"), $Report->DESTROY() );

        unless ($opt_l) {
            system("mv $mirror_dir/cache.request $mirror_dir/files.open");
            system("chmod 666 $mirror_dir/files.open");
            $auto_action = "cache";
        }

        $seq_list = join ',', @runs;
    }
    elsif ( -e "$mirror_dir/files.open" ) {    ### running ?

        # check how long the 'files.open' file has existed.
        my $lock_age = -M "$mirror_dir/files.open";
        if ( $lock_age >= 1 ) {
            $Report->set_Error( "Lock file '$mirror_dir/files.open' is more than 1 day old."
                    . " The script probably crashed or exited abruptly without cleaning up after itself."
                    . " Do not delete this file.  Look in the logs and find out where it was moved from and move it back."
                    . " Your choices will be either 'files.mirrored', 'analysis.request' or 'cache.request'." );
        }
        else {
            $Report->set_Warning("analysis in progress!");
        }

        $Report->completed();

        exit;
    }
    else {
        $Report->set_Message("Can't find any requests!");
        $Report->completed();

        exit;
    }    ### quit ... check again later...
}

if ( ( !$opt_A && !$opt_l && !$opt_L && !$opt_a ) or ($opt_h) ) {

    usage();
    $Report->completed();
    $Report->set_Error("Missing parameters");
    $Report->DESTROY();

    exit;
}
elsif ($opt_A) {
    $actions = $opt_A;
    $Report->set_Detail("Set action to $actions");
}
elsif ($opt_a) {
    $actions = $auto_action || "get,Phred,Update";
    $Report->set_Detail("Set action to $actions");
}

if ( $actions =~ /all/i ) {
    $actions = "get,Phred,Update";
}

if ($opt_S) {
    $seq_list = $opt_S;

    while ( ( $seq_list =~ /(\d+)[-](\d+)/ ) && ( $2 > $1 ) ) {
        my $numlist = join ',', ( $1 .. $2 );
        $seq_list =~ s/$1[-]$2/$numlist/;
    }
}
elsif ($opt_L) {
    my $lib = $opt_L;
    $Report->set_Detail("Searching for Library: $lib");

    my $list_condition;
    unless ( $opt_A =~ /reanalyze/i ) {
        $list_condition = " AND Run_Status like 'In Process'";
    }

    $seq_list = join ',', &Table_find( $dbc, 'Run', 'Run_ID', "where Run_Directory like '$lib%' $list_condition" );

    $Report->set_Detail("Found ($list_condition) : $seq_list");
}

if (@machine_names) {
    my $M_id;
    my $Mname = join "','", @machine_names;
    while ( $Mname =~ s/^mbace(\d+)/MB$1/ ) {

        # do nothing
    }
    while ( $Mname =~ s/^d?37(\d\d)-(\d+)/D37$1-$2/ ) {

        # do nothing
    }

    $M_id = join ',', Table_find( $dbc, 'Equipment', 'Equipment_ID', "where Equipment_Name in ('$Mname')" );

    if ( $M_id eq 'NULL' ) {
        $Report->set_Error("Invalid Machine Name ($M_id) entered");
        $Report->DESTROY();

        exit;
    }

    $machine_choice = "and Equipment_ID in ($M_id)";

    foreach my $host (@hosts) {
        my ($name) = Table_find( $dbc, 'Equipment,Machine_Default,Sequencer_Type', 'Equipment_Name', "where FK_Equipment__ID=Equipment_ID" . " AND FK_Sequencer_Type__ID = Sequencer_Type_ID" . " AND Host = '$host'" );

        if ( -e "$mirror_dir/mirrored.$host" ) {
            system("mv $mirror_dir/mirrored.$host $mirror_dir/analyzed.$name");
            system("chmod 666 $mirror_dir/analyzed.$name");
        }
    }
}

my $date_choice;
if ($opt_t) {

    if ( $opt_t =~ m/[>](\d\d\d\d-\d\d-\d\d)/ ) {
        $date_choice = " and Run_DateTime > \"$1\"";
    }
    elsif ( $opt_t =~ m/(\d\d\d\d-\d\d-\d\d)/ ) {
        $date_choice = " and Run_DateTime > \"$1 00:00:00\" and Run_DateTime <= \"$1 23:59:59\" ";
    }
}

$Report->set_Detail("*** Starting update_sequence.pl ***");
my @fields = ( 'Run_ID', 'FK_Plate__ID', 'Run_Directory', 'Equipment_Name', 'RunBatch_RequestDateTime', 'Run_Status', 'Run_Validation' );

if ( $seq_list =~ /^all$/i ) {
    @sequences = Table_find_array( $dbc, 'Run,RunBatch,Equipment', \@fields, "where FK_RunBatch__ID=RunBatch_ID" . " and RunBatch.FK_Equipment__ID=Equipment_ID" . " and Run_Status like '%In Process%'" . " $machine_choice Order by Run_ID" );
}
elsif ($inclusions) {

    $Report->set_Message("including only ids in $inclusions");

    my @include;
    open( INCLUDE, "$inclusions" ) or die( "cannot open $inclusions file", $Report->set_Error("cannot open $inclusions file"), $Report->DESTROY() );

    while (<INCLUDE>) {

        if (/(\d+)/) {
            push @include, $1;
        }
    }

    close(INCLUDE);

    my $inclusion_list = join ',', @include;
    if ($inclusion_list) {
        @sequences = &Table_find_array( $dbc, 'Run,RunBatch,Equipment', \@fields, "where FK_RunBatch__ID=RunBatch_ID" . " and Run_ID in ($inclusion_list)" . " and RunBatch.FK_Equipment__ID=Equipment_ID" . " $date_choice Order by Run_ID" );
    }
}
elsif ($seq_list) {
    @sequences = Table_find_array( $dbc, 'Run,RunBatch,Equipment', \@fields, "where FK_RunBatch__ID=RunBatch_ID" . " and Run_ID in ($seq_list)" . " and RunBatch.FK_Equipment__ID=Equipment_ID" . " $date_choice Order by Run_ID" );
}
elsif ($date_choice) {
    @sequences = Table_find_array( $dbc, 'Run,RunBatch,Equipment', \@fields, "where FK_RunBatch__ID=RunBatch_ID" . " and RunBatch.FK_Equipment__ID=Equipment_ID" . "$date_choice Order by Run_ID" );
}
else {
    @sequences = Table_find_array( $dbc, 'Run,RunBatch,Equipment', \@fields, "where FK_RunBatch__ID=RunBatch_ID" . " and Run_Status like \"%In Process%\"" . " and RunBatch.FK_Equipment__ID=Equipment_ID" . " $machine_choice Order by Run_ID" );
}

my $list = '';
foreach my $id_dir (@sequences) {

    unless ( $id_dir =~ /^[1-9]/ ) {
        $Report->set_Error("No Runs selected");
        $Report->DESTROY();

        exit;
    }
    else {
        ( my $id, my $Pid, my $ss, my $equip, my $date, my $state ) = split ',', $id_dir;
        $equip = sprintf "%10s", $equip;
        $list .= "Run $id :\t Plate $Pid\t$equip\t ($date) \t$ss";

        if ( $id && $Pid && $equip && $ss ) {
            $list .= "\n";
        }
        else {
            $list .= " ******* ??? Warning ************\n";
        }

        unless ( $state =~ /(In Process|Analyzed|Expired)/ ) {
            $Report->set_Detail(" ** State fixed as $state for Run $id **");
        }
    }
}

if ($opt_l) {
    $Report->set_Message("Just listing..");
    $Report->set_Detail($list);
    $Report->completed();

    exit;
}

my $found = scalar(@sequences);
if ( $found == 1 && $sequences[0] eq 'NULL' ) {
    $Report->set_Error("No Runs Specified");
    $Report->DESTROY();

    exit;
}
else {
    $list .= "Updating $found runs: *** $nowdate ***\n";
}

$Report->set_Detail("Runs To Update: $list");

$Report->set_Detail("*** Updating commands: ($actions) ***");
my @add_to_cache = ();
if ( $actions =~ /cache/i ) {

    foreach my $id_dir (@sequences) {
        my ( $sid, $pid, $sd, $sequencer ) = split ',', $id_dir;

        if ( $sid =~ /[1-9]/ ) {
            push @add_to_cache, $sid;
        }
    }
}

if ( $actions =~ /stats/i ) {
    my @update_stats;

    foreach my $id_dir (@sequences) {
        my ( $sid, $pid, $sd, $sequencer ) = split ',', $id_dir;

        if ( $sid =~ /[1-9]/ ) {
            push @update_stats, $sid;
        }
    }

    $Report->set_Detail("Only updating Stats for existing data..");
    get_run_statistics( $dbc, \@update_stats, $Report );
    $Report->completed();

    exit;
}

$Report->set_Detail("Request: $actions -> $seq_list");
$Report->set_Detail("Started Update");

foreach my $id_dir (@sequences) {
    if ( !( $id_dir =~ m/\S/ ) || $id_dir eq 'NULL' ) {
        next;
    }

    my $sid;
    my $pid;
    my $sd;
    my $sequencer;
    my $approved;
    my $sr;
    my $errors;
    my $date;
    my $state;

    ( $sid, $pid, $sd, $sequencer, $date, $state, $approved ) = split ',', $id_dir;

    $sequencer =~ /^(\w+)\s/;
    $sequencer = $1;

    if ( defined $exclusions && $exclusions =~ /$sid/ ) {
        $Report->set_Detail("skipping $sid");

        next;
    }

    $Report->set_Detail("**  Action: Getting Run Information");

    unless ( $sid =~ /[1-9]/ ) {
        $Report->set_Warning("No Run_ID");

        next;
    }

    my %ri = %{ get_run_info( $dbc, $sid ) };
    my $temp_screen_file = "$ri{'savedir'}/$ri{'longname'}/$phred_dir/tmp_vfile";

    if ($verbose) {
        $Report->set_Detail("Plate: $ri{'plate_id'}");
        $Report->set_Detail("Chemcode: $ri{'chemcode'}");
        $Report->set_Detail("Subdirectory: $ri{'subdirectory'}");
        $Report->set_Detail("Machine: $ri{'Mname'}");
        $Report->set_Detail("Parents: $ri{'parents'}");
        $Report->set_Detail("Plate number: $ri{'plate_number'}");
        $Report->set_Detail("Basename: $ri{'basename'}");
        $Report->set_Detail("Version: $ri{'version'}");
        $Report->set_Detail("Quadrant: $ri{'quadrant'}");
        $Report->set_Detail("User: $ri{'user'}");
        $Report->set_Detail("Mirror Path: $ri{'mirrored'}");
        $Report->set_Detail("Archive: $ri{'archived'}");
    }

    update_datetime(
        dbc      => $dbc,
        run_info => \%ri,
        State    => 'Data Acquired',
        Report   => $Report
    );

    if ( $actions eq 'colour' ) {
        ## generate colour map ONLY ##
        $Report->set_Detail("**  Action: ONLY Generating Colour Maps");

        $sr = create_colour_map(
            dbc      => $dbc,
            run_info => \%ri
        );
    }

    if ( $state =~ /(In Process|Data Acquired|Analyzed|Expired)/ ) {
        $state = 'Analyzed';
    }
    else {
        $Report->set_Warning("** Warning: State fixed as $state (to force re-analysis, state must be reset to 'In Process') **");

        next;
    }

    if ( $approved =~ /approved/i ) {
        $Report->set_Warning( "** Warning: This run ($sid) is '$approved'." . " Analysis should not be redone unless this is changed (and COMMENTED) **" );

        next;
    }

    my ($run_comments) = &Table_find( $dbc, 'Run', 'Run_Comments', "WHERE Run_ID = $ri{'sequence_id'}" );

    if ($reversal) {
        my $new_comment;
        if ( $run_comments =~ /REVERSED Plate ($reversal)/ ) {
            $new_comment = $run_comments;
        }
        elsif ( $run_comments =~ /(.*)REVERSED Plate \((.*?)\)(.*)/i ) {
            $new_comment = $1 . "REVERSED Plate ($reversal)" . $3;
        }
        elsif ( $run_comments =~ /\S/ ) {
            $new_comment = "$run_comments; REVERSED Plate ($reversal)";
        }
        else {
            $new_comment = "REVERSED Plate ($reversal)";
        }

        $Connection->Table_update_array( 'Run', ['Run_Comments'], [$new_comment], "where Run_ID = $ri{'sequence_id'}", -autoquote => 1 );
        if ($DBI::errstr) {
            $Report->set_Error($DBI::errstr);
        }

        $Report->set_Detail("NEW COMMENT: $new_comment");
    }
    elsif ( $run_comments =~ /(.*)REVERSED Plate \((.*)\)(.*)/ ) {
        my $new_comment = "$1$2";

        $Connection->Table_update_array( 'Run', ['Run_Comments'], [$new_comment], "where Run_ID = $ri{'sequence_id'}", -autoquote => 1 );

        if ($DBI::errstr) {
            $Report->set_Error($DBI::errstr);
        }
    }

    if ( $mirror || ( $actions =~ /get/i ) ) {
        $Report->set_Detail("Checking Mirrored Data");

        get_mirrored_data(
            dbc      => $dbc,
            run_info => \%ri,
            force    => $force,
            Report   => $Report,
        );
    }

    if ( $actions =~ /get/i ) {
        $Report->set_Detail("**  Action: Transferring Trace files");

        $sr = get_analyzed_data(
            dbc      => $dbc,
            run_info => \%ri,
            reversal => $reversal,
            force    => $force,
        );

        if ( &check_for_errors( $sr, 'Warning', "All Files not found (still running ?) (Run $ri{'sequence_id'})", $verbose ) ) {

            my ($local_data_dir) = &Table_find( $dbc, "Machine_Default", "Local_Data_Dir", "where FK_Equipment__ID = $ri{'Mid'}", 'Distinct' );

            my $search = "$mirror_dir/$local_data_dir/$ri{'Master_basename'}";    ## Temporary - remove Data from path...
            my @files = split "\n", try_system_command("ls $search*.tar.gz");

            $Report->set_Detail("Search for $search*.tar.gz");

            my $dayold_files_exist;                                               # track this so that we can error out only when the run hasn't completely downloaded within a day.

            if ( $files[0] =~ /No such file/i ) {

                # $Report->set_Warning("No compressed file found like $search.tar.gz)");

                next;
            }
            elsif ( $check_zipped && ( $files[0] =~ /(\S+.tar.gz)/ ) ) {

                foreach my $file (@files) {

                    my $file_age = ( -M $file );
                    $dayold_files_exist++ if ( $file_age >= 1 );

                    my $path;
                    my $zipped_file;
                    if ( $file =~ /(.*)\/(\S+.tar.gz)/ ) {
                        $path        = $1;
                        $zipped_file = $2;
                    }
                    else {
                        $Report->set_Warning("Strange Format ($file ?). No compressed file found like $search.tar.gz)");
                        next;
                    }

                    my @batch;
                    if ( $zipped_file =~ /(.*)\/(.*)Run/ ) {
                        my $subdir = $2;
                        ( my $master ) = &Table_find( $dbc, 'MultiPlate_Run,Run', 'FKMaster_Run__ID', "where FK_Run__ID=Run_ID" . " AND Run_Directory = '$subdir'" );

                        $Report->set_Detail("Master ID: $master");

                        if ( $master =~ /(\d+)/ ) {
                            @batch = &Table_find( $dbc, 'Run,MultiPlate_Run', 'Run_Directory', "where FK_Run__ID=Run_ID" . " AND FKMaster_Run__ID=$master" );
                        }
                    }
                    else {
                        @batch = ($zipped_file);
                    }

                    foreach my $zipped (@batch) {

                        if ( -e "$path/$zipped" ) {
                            $Report->set_Detail("Unzipping compressed file $path/$zipped");
                            my $fback = try_system_command("cd /; tar -xzvf $path/$zipped; cd -");
                        }
                        else {
                            $Report->set_Warning("$path/$zipped does NOT exist");
                        }

                    }
                }

                ### try again after unzipping ###
                $sr = get_analyzed_data(
                    dbc      => $dbc,
                    run_info => \%ri,
                    reversal => $reversal,
                    force    => $force,
                );

                if ( &check_for_errors( $sr, 'Warning', "All Files not found (still running ?) (Run $ri{'sequence_id'})", $verbose ) ) {

                    if ($dayold_files_exist) {
                        $Report->set_Warning("Still did not work... files not found: $ri{'sequence_id'}");
                    }

                    next;
                }
            }
            elsif (@files) {
                $Report->set_Detail( "Possible compressed files:" . join "\n", @files );

                next;
            }
        }

        $Report->set_Detail("Got files ...");
    }

    unless ( -e "$ri{'savedir'}/$ri{'longname'}/$phred_dir/" ) {
        $Report->set_Error("$ri{'savedir'}/$ri{'longname'}/$phred_dir NOT FOUND");

        next;
    }

    my $mask_restriction_site = create_temp_screen_file( $dbc, $pid, "$ri{'savedir'}/$ri{'longname'}/$phred_dir/tmp_vfile", $Report, "$check_name" );

    if ( $actions =~ /zip/i ) {
        $Report->set_Detail("**  Action: Zipping Trace files");

        $sr = zip_trace_files(
            dbc      => $dbc,
            run_info => \%ri,
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Zipping (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Zipping (Run $ri{'sequence_id'})");

            next;
        }
    }

    if ( $actions =~ /Phred/i ) {    ### runs Phred AND Cross-Match

        $Report->set_Detail("**  Action: Running phred and cross_match");
        $Report->set_Detail("****************** PHRED *******************");

        $sr = run_phred(
            dbc       => $dbc,
            run_info  => \%ri,
            force     => $force,
            phredfile => $phred_file
        );
        $sr .= "\n*********************************************\n";

        if ( &check_for_errors( $sr, 'Error', "Aborting from Phred (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Phred (Run $ri{'sequence_id'})");
            abort_run( $ri{'sequence_id'} );

            next;
        }

        $Report->set_Detail("** Action: Running Cross Match");
        $Report->set_Detail("****************** Cross Match *******************");

        $sr .= run_crossmatch(
            dbc                  => $dbc,
            run_info             => \%ri,
            vector_sequence_file => $temp_screen_file
        );
        $sr .= "\n*********************************************\n";

        if ( &check_for_errors( $sr, 'Error', "Aborting from Cross-Match (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Cross-Match (Run $ri{'sequence_id'})");
            abort_run( $ri{'sequence_id'} );

            next;
        }

        $sr .= "\n*********************************************\n";

        if ( &check_for_errors( $sr, 'Error', "Aborting from Contaminant Screening (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Contaminant Screening (Run $ri{'sequence_id'})");
            abort_run( $ri{'sequence_id'} );

            next;
        }
    }
    elsif ( $actions =~ /Xmatch/i ) {
        $Report->set_Detail("**  Action: Running cross_match");

        $sr = run_crossmatch(
            dbc                  => $dbc,
            run_info             => \%ri,
            vector_sequence_file => $temp_screen_file
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Cross-Match (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Cross-Match (Run $ri{'sequence_id'})");

            next;
        }
    }
    elsif ( $actions =~ /Screen/i ) {    #### done in run_crossmatch automatically
        $Report->set_Detail("**  Action: Running screen process");

        $sr = parse_screen_file(
            dbc      => $dbc,
            run_info => \%ri,
            file     => "$ri{'savedir'}/$ri{'longname'}/$phred_dir/screen"
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Screening Process (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Screening Process (Run $ri{'sequence_id'})");
            abort_run( $ri{'sequence_id'} );

            next;
        }
    }

    if ( $actions =~ /Cont/i ) {
        $Report->set_Detail("**  Action: Running Contamination checking process");

        my $contam = screen_contaminants(
            dbc      => $dbc,
            run_info => \%ri,
            path     => "$ri{'savedir'}/$ri{'longname'}/$phred_dir",
            blast    => $blast
        );

        $sr = $contam;
        $notification .= $contam;

        $Report->set_Detail($contam);

        if ( &check_for_errors( $sr, 'Error', "Aborting from Contaminant Screening Process (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Contaminant Screening Process (Run $ri{'sequence_id'})");

            next;
        }
    }

    if ( $actions =~ /Score/i ) {
        $Report->set_Detail("** Action: Parsing phred scores");

        $sr = parse_phred_scores(
            dbc                   => $dbc,
            run_info              => \%ri,
            reversal              => $reversal,
            mask_restriction_site => $mask_restriction_site,
            Report                => $Report
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Parsing Phred Scores (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Parsing Phred Scores (Run $ri{'sequence_id'})");
            abort_run( $ri{'sequence_id'} );

            next;
        }
    }

    if ( $actions =~ /Update/i ) {
        push @add_to_cache, $ri{'sequence_id'};

        $Report->set_Detail("**  Action: Generating Scores");

        $sr = init_clone_sequence_table(
            dbc      => $Connection,
            run_info => \%ri
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Generating Scores (Run $ri{'sequence_id'})", $verbose ) ) {

            &check_for_errors( $sr, 'Tried', "Tried Generating Scores (Run $ri{'sequence_id'})", $verbose );

            $Report->set_Error("Aborting from Generating Scores (Run $ri{'sequence_id'})");
            abort_run( $ri{'sequence_id'} );

            next;
        }

        $sr = parse_phred_scores(
            dbc                   => $dbc,
            run_info              => \%ri,
            reversal              => $reversal,
            mask_restriction_site => $mask_restriction_site,
            Report                => $Report
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Parsing Phred Scores (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Parsing Phred Scores (Run $ri{'sequence_id'})");

            next;
        }

        $Report->set_Detail("****************** Screen for Contaminants *******************");

        my $contam = screen_contaminants(
            dbc      => $dbc,
            run_info => \%ri,
            path     => "$ri{'savedir'}/$ri{'longname'}/$phred_dir",
            blast    => 1
        );
        $notification .= $contam;
        $sr = update_datetime(
            dbc      => $dbc,
            run_info => \%ri,
            State    => $state,
            Report   => $Report
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from DateStamping Run (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from DateStamping Run (Run $ri{'sequence_id'})");

            next;
        }

        $Report->set_Detail("**  Action: Generating Colour Maps");

        $sr = create_colour_map(
            dbc      => $dbc,
            run_info => \%ri
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Colour-Mapping Run (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Colour-Mapping Run (Run $ri{'sequence_id'})");

            next;
        }

        $Report->set_Detail("**  Action: Clearing out Phred Files");

        $sr = clear_phred_files(
            dbc      => $dbc,
            run_info => \%ri
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Clearing Phred Files (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Clearing Phred Files (Run $ri{'sequence_id'})");

            next;
        }
    }
    elsif ( $actions =~ /colour/i ) {
        $Report->set_Detail("**  Action: Generating Colour Maps");

        $sr = create_colour_map(
            dbc      => $dbc,
            run_info => \%ri
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Colour-Mapping (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Colour-Mapping (Run $ri{'sequence_id'})");

            next;
        }
    }
    elsif ( $actions =~ /date/i ) {
        $Report->set_Detail("**  Action: Regenerating DateStamp");

        $sr = update_datetime(
            dbc      => $dbc,
            run_info => \%ri,
            Report   => $Report
        );

        if ( &check_for_errors( $sr, 'Error', "Aborting from TimeStamping (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from TimeStamping (Run $ri{'sequence_id'})");

            next;
        }
    }
    elsif ( $actions =~ /source/i ) {
        $Report->set_Detail("** Source: Update original Sample source");
        $sr = update_source( dbc => $Connection, run_info => \%ri );
    }

    if ( $actions =~ /Clear/i ) {
        $Report->set_Detail("**  Action: Clearing out Phred Files");

        $sr = clear_phred_files( dbc => $dbc, run_info => \%ri );

        if ( &check_for_errors( $sr, 'Error', "Aborting from Clearing Phred Files (Run $ri{'sequence_id'})", $verbose ) ) {
            $Report->set_Error("Aborting from Clearing Phred Files (Run $ri{'sequence_id'})");

            next;
        }
    }

    if ( $opt_f || $opt_F ) {
        $Report->set_Detail("Delete from Clone_Sequence where FK_Run__ID=$sid and Sequence_Length < 0");

        my $cleaned = $dbc->dbh()->do("Delete from Clone_Sequence where FK_Run__ID=$sid and Sequence_Length < 0");
    }

    $Report->set_Message( "Done " . $ri{'subdirectory'} . " : Run = " . $ri{'sequence_id'} . "; Plate = " . $ri{'plate_id'} );
    $Report->succeeded();
}

&get_run_statistics( $dbc, \@add_to_cache, $Report );    ### (Re) Generate Statistics for given runs..

$dbc->disconnect();

$Report->set_Detail("********** Finished updating the sequence database **********");
$Report->set_Message("Completed Successfully");

if ($opt_a) {
    if ( -e "$mirror_dir/files.open" ) {
        system("mv $mirror_dir/files.open $mirror_dir/request.analyzed");
        system("chmod 666 $mirror_dir/request.analyzed");
    }
}

$Report->completed();
$Report->DESTROY();

exit 1;

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

###############
sub parse_options {
###############
    my $options = shift;

    if ( $options =~ /-R/ ) {
        $Report->set_Detail("Well fully reversed");
        $reversal = 'full';
    }
    elsif ( $options =~ /-r/ ) {
        $Report->set_Detail("Well reversed by quadrant");
        $reversal = 'partial';
    }

    if    ( $options =~ /-F/ ) { $force = 2; }
    elsif ( $options =~ /-f/ ) { $force = 1; }

    return;
}

##################
sub abort_run {
##################
    my $id = shift;

    $Report->set_Error("***** $id Aborted *****");

    return;
}

###########################
sub check_for_errors {
###########################
    #
    # Check feedback for Errors
    #
    my $feedback    = shift;
    my $errorstring = shift || 'Error';
    my $message     = shift;
    my $verbose     = shift;

    my $errors = get_line_with( $feedback, $errorstring );

    if ($verbose) {
        print $feedback;
    }

    if ($errors) {

        if ( $errorstring eq 'Error' ) {
            $Report->set_Error("$errorstring\n$message\n$errors)");
        }
        elsif ( $errorstring eq 'Warning' ) {
            if ( $feedback =~ /non-fatal/i ) {
                ## allow for suspension to analysis without generating warning or error message ##
                $Report->set_Message("non-fatal $errorstring\n$message\n$errors)");
            }
            else {
                $Report->set_Warning("$errorstring\n$message\n$errors)");
            }
        }

        return 1;
    }

    return 0;
}

####################################
sub usage {

    # Usage instructions

    print <<END;
update_sequence.pl is run after trace files have been mirrored onto
the file server. It handles things like running Phred, Phrap, updating
the SQL database, generating GIF colour maps, and zipping up data files.

Usage: update_sequence.pl [-A actions] [options]
****************************************************
  Using the -A switch to specify which actions you want to perform.

  By default, it searches for sequence runs with no associated date.
  There are a number of switches that change the sequence runs
  operated on.

Options:

* Operational modes:

  -A  actions to take.

      get    : Gets files from the local sequencing drives
      phred  : Generates Phred Scores and Cross-Match data
      update : Updates the database with parsed data from phred files
      all    : Does all three actions: get,phred,update

* Run selection modifiers:

  -S  sequence_ID list. Performs updates for indicated sequences (or "-S all" for ALL sequences)
      You may also supply imbedded ranges: "-S 1-3,8,10-12" selects 1,2,3,8,10,11,12

  -i  include specific Run IDs (similar functionality to -S)

  -x  exclude specific Run IDs (can be used in combination with other options)

  -M  machine Perform update for new sequences on a specified Machine (mbace1, d3700-2)
               (eg: -M mbace2 or -M d3700-2 )

  -t  date    Perform update for all sequences done on a specified date (-t 2000-09-18)
               (eg: -t 2000-09-25 )

* Operational modifiers:

  -R  reverse plate Orientation due to incorrect positioning of plate (entire plate)
  -r  reverse plate Orientation (only 1 of 96 well sections of 384 well plate)

  -f  force analysis even if only 1 quadrant of 384 well plate is done

  -F  force analysis even if less than 1 quadrant is done

  -D  specify database name (normally 'sequence')

* Informative output:

  -h  help. print this help text and then exit

  -v  verbose mode

  -l  list chosen sequences on queue and then exit
     (this dumps Run_ID, Plate_ID, Run_Directory, Machine)

  -b  run blast again for contamination checking even if it was blasted before

  -z  if trace files not found, try unzipping files..

Examples:

  Generally all actions will be performed on new runs using the command:

    update_sequence.pl -A all

 Or to regenerate all sequences:

    update_sequence.pl -A Phred,Update -S all

  To run phred on data sequenced on the 22nd of September, given that
  the trace files have already been transferred to /home/aldente/public/Projects/:

    update_sequence.pl -A Phred,Update -t 2000-09-22

  To transfer files AND run data on sequence runs 455, 456 and 457 (already mirrored):

    update_sequence.pl -A all -S 455,456,457

***********************************
current phred version : 

END

    print &alDente::Post::check_phred_version() . "\n\n";

    return 1;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: update_sequence.pl,v 1.55 2004/11/30 16:59:27 jsantos Exp $ (Release: $Name:  $)

=cut

