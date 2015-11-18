#!/usr/local/bin/perl
#
################################################################################
#
# cleanup_slx_space.pl
#
#   1. retrieves all runs from the SolexaRun table are Approved, Files_Status = 'Raw', Protected = 'No'
#   2. checks files to be sure analysis is complete
#   3. deletes all images other than those from the 50th tile
#   4. runs shell script on m-nodes that compresseses all int and nse files and runs make compress and make clean intermediate reducing size
#
################################################################################

use strict;
use CGI qw(:standard);
use DBI;
use File::stat;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::CustomSettings;
use SDB::DBIO;
use Data::Dumper;

use alDente::SDB_Defaults;
use alDente::Run;
use Sequencing::Solexa_Analysis;

use Getopt::Long;
require "getopts.pl";
use vars qw($opt_D $opt_S $opt_X $opt_P $opt_m $opt_b $opt_i $opt_H $opt_A $opt_help $opt_quiet $opt_dbase $opt_pwd $opt_flowcell $opt_run $opt_manual $opt_check_space);

&GetOptions(
    'help'        => \$opt_help,
    'quiet'       => \$opt_quiet,
    'dbase=s'     => \$opt_dbase,
    'pwd=s'       => \$opt_pwd,
    'flowcell=s'  => \$opt_flowcell,
    'manual'      => \$opt_manual,
    'run=s'       => \$opt_run,
    'check_space' => \$opt_check_space,
);

my $host        = $Configs{PRODUCTION_HOST};
my $dbase       = $opt_dbase;
my $user        = 'super_cron_user';
my $pwd         = $opt_pwd;
my $flowcell    = $opt_flowcell;
my $run         = $opt_run;                    # name of run directory NOT run_ID
my $manual      = $opt_manual;                 ## flag to indicate manual operation (script dumps shell commands that should be used to execute deletion/compression) ##
my $check_space = $opt_check_space;
my $threshold   = '7';

print "Manual cleanup mode: run commands indicated as shell commands (or SQL commands) as required\n\n";
my $data_dir = 'Solexa/Data/current';

my $Report = Process_Monitor->new();

my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my %runs;
my $tables    = 'Run,SolexaRun,Flowcell';
my $condition = "WHERE SolexaRun.FK_Run__ID = Run.Run_ID and FK_Flowcell__ID = Flowcell_ID and Run_Validation in ('Approved','Rejected') and Files_Status = 'Raw' and Protected = 'No'";

if ($flowcell) {
    $condition .= " and Flowcell_Code = '$flowcell'";
}
elsif ($run) {
    $condition .= " AND Run_Directory = '$run'";
}
else {
    $tables    .= ",SolexaAnalysis";
    $condition .= " AND SolexaAnalysis.FK_Run__ID=Run_ID";
    $condition .= " AND TO_DAYS(CURDATE()) - TO_DAYS(SolexaAnalysis_Finished) > $threshold ";    ## leave 1 week buffer before auto-deleting ##   #implement once SolexaAnalysis_Finished set properly
}

%runs = $dbc->Table_retrieve( $tables, [ 'Run_ID', 'Run_Directory', 'Run_Validation', 'Flowcell_Code', 'Lane', 'Run_DateTime' ],, $condition, -autoquote => 1 );

my $rejected_threshold = $threshold + 7;
my %rejected_runs;
my $rejected_tables = 'Run,SolexaRun,Flowcell LEFT JOIN SolexaAnalysis ON SolexaAnalysis.FK_Run__ID=Run_ID';
my $rejected_condition
    = "WHERE SolexaRun.FK_Run__ID = Run.Run_ID and FK_Flowcell__ID = Flowcell_ID and Run_Validation in ('Rejected') and Files_Status = 'Raw' and Protected = 'No' and (TO_DAYS(CURDATE()) - TO_DAYS(Run_DateTime) > $rejected_threshold) and SolexaAnalysis_Finished is null";

$rejected_condition .= " limit 16";

%rejected_runs = $dbc->Table_retrieve( $rejected_tables, [ 'Run_ID', 'Run_Directory', 'Run_Validation', 'Flowcell_Code', 'Lane', 'Run_DateTime' ],, $rejected_condition, -autoquote => 1 );

foreach my $key ( keys(%runs) ) {
    push( @{ $runs{$key} }, @{ $rejected_runs{$key} } );
}

#find_number_to_delete(-volume=>$volume)

my $j = 0;
foreach my $run_id ( @{ $runs{Run_ID} } ) {
    my $run_dir    = @{ $runs{Run_Directory} }[$j];
    my $flowcell   = @{ $runs{Flowcell_Code} }[$j];
    my $lane       = @{ $runs{Lane} }[$j];
    my $timestamp  = @{ $runs{Run_DateTime} }[$j];
    my $validation = @{ $runs{Run_Validation} }[$j];
    my $lane_dir   = ".L$lane";
    $j++;

    my $run_object = new alDente::Run( -dbc           => $dbc, -run_id => $run_id );
    my $data_path  = $run_object->get_data_path( -dbc => $dbc, -run_id => $run_id );

    #check that analysis is complete
    chdir "$data_path/$data_dir";
    print "** $data_path :: $data_dir\ **\n";
    my $compress_count = 0;

    my $analysis_checked = 0;

    if ( $validation eq 'Approved' ) {
        my @check_analysis = split "\n", try_system_command("find $data_path/$data_dir/Bustard*/GERALD*/*_finished.txt* -maxdepth 0");
        if ( $check_analysis[10] ) { $analysis_checked = 1; }
    }
    elsif ( $validation eq 'Rejected' ) { $analysis_checked = 1; }

    my ($protected_old)
        = $dbc->Table_find( 'Run,SolexaRun', 'Protected',
        "WHERE FK_Run__ID=Run_ID AND Run_Status IN ('Analyzed','Failed') AND Run_Validation IN ('Approved','Rejected') AND Files_Status = 'Raw' AND TO_DAYS(CURDATE())-TO_DAYS(Run_DateTime)>180 AND Protected = 'No' AND Run_ID=$run_id" );

    if ( $analysis_checked || ( $protected_old eq 'No' ) ) {    # analysis done

        # delete images
        if ( $protected_old eq 'No' ) {
            $Report->set_Message("Deleting old unprotected files");
        }
        else {
            $Report->set_Message("Analysis successful for $flowcell Lane $lane");
        }
        ### Erase images ###
        my ( $erased, $message, $warning ) = Sequencing::Solexa_analysis::erase_images( -dbc => $dbc, -run_id => $run_id, -data_path => $data_path, -preserve => '2837|_50', -manual => $manual );
        if ($message) { $Report->set_Detail($message) }
        if ($warning) { $Report->set_Warning($warning) }

        if ($erased) {
            $Report->set_Message("Erased $erased images");
        }
        else {
            unless ($warning) {
                $Report->set_Message("Nothing erased (already deleted ?) - reset Files_Status to 'Images Deleted'");
                $dbc->Table_update_array( 'SolexaRun', ['Files_Status'], ['Images Deleted'], "WHERE FK_Run__ID=$run_id", -autoquote => 1 );
            }
        }
        ### compress nse and int ###
        # run illumina makefiles to clean redundant files and compress necessary ones not already compressed
        my ( $compressed, $message ) = Sequencing::Solexa_analysis::compress_files( -run_id => $run_id, -data_dir => $data_dir, -data_path => $data_path, -manual => $manual );
    }
    else {
        my ($info) = $dbc->Table_find( 'Run,SolexaRun', 'Files_Status,Run_Validation,Run_Status,Protected', "WHERE FK_Run__ID=Run_ID AND Run_ID = $run_id" );
        my ( $fs, $rv, $rs, $p ) = split ',', $info;
        $Report->set_Message(" (analysis incomplete for $flowcell Lane $lane [$rs : $rv : $fs : $p]) - initiated $timestamp");
        $Report->set_Message("(failed: find $data_path/$data_dir/Bustard*/GERALD*/*_finished.txt* -maxdepth 0");
    }
}

if ($check_space) {
    my ( $message, $warning ) = Sequencing::Solexa_analysis::check_space_usage( -dbc => $dbc, -flowcell => $flowcell, -run => $run );
    $Report->set_Detail($message);
    $Report->set_Warning($warning);
}

$dbc->disconnect();
$Report->completed();
$Report->DESTROY();
exit;
