#!/usr/local/bin/perl
#
################################################################################
#
# cleanup_slx_files.pl
#
# This program:
#   1. retrieves all runs from the SolexaRun table that have been marked as "Images Deleted"
#   2. compresseses all prb and seq files
#   3. moves directory to storage volume (currently /home/sequence/archive/solexa/1/data3/)
#   4. resets sym links to storage volume
#   5. deletes from raw volume (On hold until system has been in use for awhile)
#   ???NOTE:  directories are hard coded for Safety (/home/sequence/)???
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
use Sequencing::Solexa_Analysis;

use alDente::SDB_Defaults;
use alDente::Run;

use Getopt::Long;
require "getopts.pl";
use vars qw($opt_D $opt_S $opt_X $opt_P $opt_m $opt_b $opt_i $opt_H $opt_A $opt_help $opt_quiet $opt_dbase $opt_pwd $opt_flowcell $opt_run $opt_testing $opt_delete $opt_preserve_image);

&GetOptions(
    'help'             => \$opt_help,
    'quiet'            => \$opt_quiet,
    'dbase=s'          => \$opt_dbase,
    'pwd=s'            => \$opt_pwd,
    'flowcell=s'       => \$opt_flowcell,
    'run=s'            => \$opt_run,
    'testing'          => \$opt_testing,
    'delete'           => \$opt_delete,
    'preserve_image=s' => \$opt_preserve_image
);

my $host  = $Configs{PRODUCTION_HOST};
my $dbase = $opt_dbase;
my $user  = 'super_cron_user';
my $pwd   = $opt_pwd;

my $data_dir       = 'Solexa/Data/current';
my $storage_dir    = '/home/sequence/archive/solexa/1/data3';
my $flowcell       = $opt_flowcell;
my $run            = $opt_run;
my $testing        = $opt_testing;
my $delete         = $opt_delete;
my $preserve_image = $opt_preserve_image | "50";
my $threshold      = '15';

my $Report = Process_Monitor->new();

my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my %runs;
my $tables = 'Run,SolexaRun,Flowcell';

#my $condition = "WHERE SolexaRun.FK_Run__ID = Run.Run_ID and FK_Flowcell__ID = Flowcell_ID and Run_Validation in ('Approved','Rejected') and Files_Status = 'Images Deleted' and Protected = 'No' and Solexa_Sample_Type = 'Control' and (  QC_Check in ('Passed','Failed') or (QC_Check = 'N/A' and Solexa_Sample_Type = 'Control') ) ";
my $condition
    = "WHERE SolexaRun.FK_Run__ID = Run.Run_ID and FK_Flowcell__ID = Flowcell_ID and Run_Validation in ('Approved','Rejected') and Files_Status = 'Images Deleted' and Protected = 'No' and (QC_Status in ('Passed','Failed') or (QC_Status = 'N/A' and ( (Solexa_Sample_Type = 'Control') or (Run_Validation = 'Rejected') ) ) )";

if ($flowcell) {
    $condition .= " and Flowcell_Code = '$flowcell'";
    $tables    .= ",SolexaAnalysis";
    $condition .= " AND SolexaAnalysis.FK_Run__ID=Run_ID";
    $condition .= " AND TO_DAYS(CURDATE()) - TO_DAYS(SolexaAnalysis_Finished) > $threshold";
}
elsif ($run) {
    $condition .= " AND Run_Directory = '$run'";
    $tables    .= ",SolexaAnalysis";
    $condition .= " AND SolexaAnalysis.FK_Run__ID=Run_ID";
    $condition .= " AND TO_DAYS(CURDATE()) - TO_DAYS(SolexaAnalysis_Finished) > $threshold";
}
else {
    $tables    .= ",SolexaAnalysis";
    $condition .= " AND SolexaAnalysis.FK_Run__ID=Run_ID";
    $condition .= " AND TO_DAYS(CURDATE()) - TO_DAYS(SolexaAnalysis_Finished) > $threshold";    ## leave 2 week buffer before auto-deleting/compressing ##
}

%runs = $dbc->Table_retrieve( $tables, [ 'Run_ID', 'Run_Directory', 'Run_Validation', 'Flowcell_Code', 'Lane', 'Run_DateTime', 'Solexa_Sample_Type' ],, $condition, -autoquote => 1 );

unless ( defined(%runs) ) { $Report->set_Warning("Table retrieve found no runs: select X from $tables $condition"); }

my $total_runs = 0;

my $j = 0;
foreach my $run_id ( @{ $runs{Run_ID} } ) {
    my $run_dir       = @{ $runs{Run_Directory} }[$j];
    my $flowcell      = @{ $runs{Flowcell_Code} }[$j];
    my $lane          = @{ $runs{Lane} }[$j];
    my $lane_dir      = ".L$lane";
    my $copy_complete = 0;
    $j++;

    print "Compressing bustard files for $flowcell Lane $lane\n";

    my $run_object = new alDente::Run( -dbc           => $dbc, -run_id => $run_id );
    my $data_path  = $run_object->get_data_path( -dbc => $dbc, -run_id => $run_id );

### compress seq,prb and qhg files in Bustard dir, and delete sig2 files ###
    # check realign because all dirs without Gerald have been compressed
    my @check_analysis = split "\n", try_system_command("find $data_path/$data_dir/Bustard*/GERALD*/*finished.txt* -maxdepth 0");

    $check_analysis[1] = "delete";

    if ( $check_analysis[1] ) {
        $Report->set_Message("Analysis complete, compressing data");
        $total_runs = Sequencing::Solexa_analysis::compress_bustard_parallel( -dbc => $dbc, -run_id => $run_id, -data_path => $data_path, -data_dir => $data_dir, -total_runs => $total_runs );
    }
    else { $Report->set_Warning("Analysis not complete. Gerald failure? Check run. $data_path/$data_dir"); }
}
print "Total runs: $total_runs\n";

$Report->completed();
exit;

