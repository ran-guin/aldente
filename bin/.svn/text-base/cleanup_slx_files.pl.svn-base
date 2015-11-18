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
#   5. deletes lane directory from raw volume
#   6. NEED STEP TO DELETE FLOWCELL DIR FROM RAW VOLUME
#   ???NOTE:  directories are hard coded for Safety (/home/sequence/)???
#
#   use -testing to test
#   use -delete to delete files from raw directory.  Will leave them if -delete not used
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
my $threshold      = '14';

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
my $condition
    = "WHERE SolexaRun.FK_Run__ID = Run.Run_ID and FK_Flowcell__ID = Flowcell_ID and Run_Validation in ('Approved','Rejected') and Files_Status = 'Images Deleted' and Protected = 'No' and (QC_Status in ('Passed','Failed') or (QC_Status = 'N/A' and ( (Solexa_Sample_Type = 'Control') or (Run_Validation = 'Rejected') ) ) ) ";

if ($flowcell) {
    $condition .= " and Flowcell_Code = '$flowcell'";
}
elsif ($run) {
    $condition .= " AND Run_ID = '$run'";
}
else {
    $tables    .= ",SolexaAnalysis";
    $condition .= " AND SolexaAnalysis.FK_Run__ID=Run_ID";
    $condition .= " AND TO_DAYS(CURDATE()) - TO_DAYS(SolexaAnalysis_Finished) > $threshold";    ## leave 2 week buffer before auto-deleting/compressing ##
}

# <CONSTRUCTION> Add 'lock' to stop cronjob from running again the next day if still running. For now, limit should stop script from lasting over 24 hours and running parallel
$condition .= " limit 16";

%runs = $dbc->Table_retrieve( $tables, [ 'Run_ID', 'Run_Directory', 'Run_Validation', 'Flowcell_Code', 'Lane', 'Run_DateTime', 'Solexa_Sample_Type', 'SolexaRun_Type' ],, $condition, -autoquote => 1 );
unless ( defined(%runs) ) { $Report->set_Warning("Table retrieve found no runs: select * from $tables $condition"); }

my $j = 0;
foreach my $run_id ( @{ $runs{Run_ID} } ) {
    my $run_dir       = @{ $runs{Run_Directory} }[$j];
    my $flowcell      = @{ $runs{Flowcell_Code} }[$j];
    my $lane          = @{ $runs{Lane} }[$j];
    my $run_type      = @{ $runs{Solexa_Run_Type} }[$j];
    my $lane_dir      = ".L$lane";
    my $copy_complete = 0;
    $j++;

    print "Storing files for $flowcell Lane $lane\n";

    my $run_object = new alDente::Run( -dbc           => $dbc, -run_id => $run_id );
    my $data_path  = $run_object->get_data_path( -dbc => $dbc, -run_id => $run_id );

### compress seq,prb and qhg files in Bustard dir, and delete sig2 files ###
    # check realign because all dirs without Gerald have been compressed
    my @check_analysis = split "\n", try_system_command("find $data_path/$data_dir/Bustard*/GERALD*/*finished.txt* -maxdepth 0");

    if ( $check_analysis[1] ) {
        $Report->set_Message("Analysis complete, compressing data");
        unless ($testing) {
            my $storing = $dbc->Table_update_array( 'SolexaRun', ['Files_Status'], ['Storing'], "where FK_Run__ID = $run_id", -autoquote => 1 );
            my $compress_count = Sequencing::Solexa_analysis::compress_bustard( -dbc => $dbc, -run_id => $run_id, -data_path => $data_path, -data_dir => $data_dir );
            if ( $compress_count < 20 ) { $Report->set_Warning("Less files compressed than expected, $compress_count files compressed"); }
        }
    }
    else { $Report->set_Warning("Analysis not complete. Gerald failure? Check run."); }

    # get FC???? dir to make directories for old flowcells
    my @flowcell_paths = Sequencing::Solexa_analysis::find_flowcell_dir($flowcell);
    my $flowcell_path  = $flowcell_paths[0];
    my ( $slash, $home, $sequence, $archive, $slx, $one, $volume, $fc_dir ) = split '/', $flowcell_path;

    my $paired_dir;
    if ( $flowcell_paths[1] ) {
        my ( $p_slash, $p_home, $p_sequence, $p_archive, $p_slx, $p_one, $p_volume );
        ( $p_slash, $p_home, $p_sequence, $p_archive, $p_slx, $p_one, $p_volume, $paired_dir ) = split '/', $flowcell_paths[1];
    }

    # check if copy already done
    # check Bustard for now while backfilling, as some old runs do not have Gerald.  Change to check for realign or finished.txt once this is done.
    my $bustard_path = "$storage_dir/$fc_dir/$run_dir$lane_dir/Data/current/Bustard*";
    my $check_files = Sequencing::Solexa_analysis::check_solexa_copy( -bustard_path => $bustard_path );
    if ($check_files) { $copy_complete = 1; $Report->set_Message("Files Already Copied for $flowcell Lane $lane"); }
    else              { $Report->set_Message("Data not yet copied for $flowcell Lane $lane"); }

    # copy data to storage
    my $diff_check = '';

    unless ($copy_complete) {
        try_system_command("mkdir $storage_dir/$fc_dir/");
        $Report->set_Message("cp $flowcell_path/$run_dir$lane_dir $storage_dir/$fc_dir/ -r ");
        unless ($testing) { try_system_command("cp $flowcell_path/$run_dir$lane_dir $storage_dir/$fc_dir/ -r "); }
        print "diff -r $flowcell_path/$run_dir$lane_dir/Data/current/Bustard* $storage_dir/$fc_dir/$run_dir$lane_dir/Data/current/Bustard* \n";
        $diff_check = try_system_command("diff -r $flowcell_path/$run_dir$lane_dir/Data/current/Bustard* $storage_dir/$fc_dir/$run_dir$lane_dir/Data/current/Bustard*");
    }

    # check for copy success
    # check Bustard for now while backfilling, as some old runs do not have Gerald.  Change to check for realign or Summary.htm once this is done

    $check_files = Sequencing::Solexa_analysis::check_solexa_copy( -bustard_path => $bustard_path );
    if ( $check_files && $diff_check eq '' ) { $copy_complete = 1; $Report->set_Message("Data copy successful"); }
    else {
        unless ($testing) {
            unless ($check_files) { $copy_complete = 0; $Report->set_Error( "Problem with data copy for $flowcell Lane $lane.  Could not locate $storage_dir/$fc_dir/$run_dir$lane_dir/Data/current/Bustard*/s_$lane" . "_finished.txt " ); }
            unless ( $diff_check eq '' ) { $copy_complete = 0; $Report->set_Error("Differences found between directories $flowcell_path/$run_dir$lane_dir and $storage_dir/$fc_dir/$run_dir$lane_dir : $diff_check"); }
        }
    }

    # copy remaining images and files in flowcell dir to storage
    my $copy_flowcell_files;    #use to test success of try_system_command below?
    my $images_dir     = "Images";
    my $params_file    = "$fc_dir" . ".params";
    my $raw_image_file = "$flowcell_path/$images_dir/L00$lane/C1.1/s_$lane" . "_" . $preserve_image . "_a.tif";
    my $image_file     = "$storage_dir/$fc_dir/$images_dir/L00$lane/C1.1/s_$lane" . "_" . $preserve_image . "_a.tif";

    if ($copy_complete) {
        try_system_command("mkdir $storage_dir/$fc_dir/$images_dir");
        if ($paired_dir) { try_system_command("mkdir $storage_dir/$paired_dir"); try_system_command("mkdir $storage_dir/$paired_dir/$images_dir"); }

        unless ($testing) {
            try_system_command("cp $flowcell_path/* $storage_dir/$fc_dir ");
            try_system_command("cp $flowcell_path/Config $storage_dir/$fc_dir -r");

            if ($paired_dir) {
                try_system_command("cp $flowcell_paths[1]/* $storage_dir/$paired_dir ");
                try_system_command("cp $flowcell_paths[1]/Config $storage_dir/$paired_dir -r");
            }
        }
        if ( -e "$raw_image_file" || -e "$raw_image_file" . ".bz2" ) {    #.bz2 to find old compressed images

            # <CONSTRUCTION> uncomment once old paired runs are deleted as they already have half their images copied
            #	    unless (-e "$image_file" || -e "$image_file" . ".bz2" ) {
            #$Report->set_Message("No image found $image_file");
            unless ($testing) {
                try_system_command("cp $flowcell_path/$images_dir/L00$lane $storage_dir/$fc_dir/$images_dir/ -r");
                if ($paired_dir) { try_system_command("cp $flowcell_paths[1]/$images_dir/L00$lane $storage_dir/$paired_dir/$images_dir/ -r"); }
                elsif ( $run_type eq 'Paired' ) { $Report->set_Warning("No directory containing paired read images found."); }
            }
            $Report->set_Message("Copy Images: cp $flowcell_path/$images_dir/L00$lane $storage_dir/$fc_dir/$images_dir/ -r ");

            #	    }
            if ( -e "$image_file" || -e "$image_file" . ".bz2" ) {
                $Report->set_Message("Tile $preserve_image images for $flowcell Lane $lane copied");
            }
            else {
                $copy_complete = 0;
                unless ($testing) { $Report->set_Error("Images for $flowcell Lane $lane not copied to storage. $image_file not found. "); }
            }
        }
        else { $Report->set_Warning("No original image file found $raw_image_file") }
    }

    # move Run Dir sym links to storage

    my $remove_path = "$flowcell_path/$run_dir$lane_dir";
    my $remove_path_checked;
    if ( $remove_path =~ /\S+\.L\d+$/ ) { $remove_path_checked = 1; $Report->set_Message("Directory to be removed unless data3: $remove_path"); }
    else                                { $Report->set_Error("$remove_path is incorrect, no data deleted"); }

    my $storage_path  = "$storage_dir/$fc_dir";
    my $lane_data_dir = "$run_dir$lane_dir";

    if ($copy_complete) {
        Sequencing::Solexa_analysis::change_solexa_links( -testing => $testing, -new_location => $storage_path, -new_paired_location => $flowcell_paths[1], -solexa_run_path => $data_path, -params_file => $params_file, -lane_data_dir => $lane_data_dir );

###!!! delete data from raw volume (uncomment later ONLY once ready to start removing everything)!!! ## filestat/checksum double check?
#### <CONSTRUCTION> if last lane, then delete flowcell directory on raw volume.
        #if all other lanes have Files_Status = 'Stored' and no other directories =~ /\S+\.L\d+$/ then delete flowcell dir

        if ( $copy_complete && $remove_path_checked ) {
            unless ( $testing || !$delete || $volume =~ /data3/ ) {
                if ($volume) {
                    $Report->set_Message("Removing $remove_path");
                    chdir "$flowcell_path";
                    try_system_command("rm -rf $remove_path > $flowcell_path/remove.out$lane");
                }
            }
        }

        #more checks before set to 'Stored'?
        #set solexa files status

        unless ($testing) { my $stored = $dbc->Table_update_array( 'SolexaRun', ['Files_Status'], ['Stored'], "where FK_Run__ID = $run_id", -autoquote => 1 ); }

    }
    else {
        unless ($testing) { $Report->set_Error("Problem with Data or Image copy or Remove Path $remove_path, reverting Files_Status to Images Deleted"); }
        unless ($testing) { my $storing = $dbc->Table_update_array( 'SolexaRun', ['Files_Status'], ['Images Deleted'], "where FK_Run__ID = $run_id", -autoquote => 1 ); }
    }
    if ($testing) {
        print "\n\n ***** TESTING: PREDICTED COMMANDS ***** \n\n";
        print "Set Files_Status = 'Storing' where FK_Run__ID = $run_id \n";
        print "Copy Data: cp $flowcell_path/$run_dir$lane_dir $storage_dir/$fc_dir/ -r  \n";
        print "diff -r $flowcell_path/$run_dir$lane_dir/Data/current/Bustard* $storage_dir/$fc_dir/$run_dir$lane_dir/Data/current/Bustard* \n";
        print "Copy Flowcell Directory Files:cp $flowcell_path/* $storage_dir/$fc_dir \n";
        print "Copy Paired Read Files: cp $flowcell_paths[1]/* $storage_dir/$paired_dir \n";
        print "Copy Images: cp $flowcell_path/$images_dir/L00$lane $storage_dir/$fc_dir/$images_dir/ -r \n";
        if ($paired_dir) { print "Copy Paired Images: cp $paired_dir/$images_dir/L00$lane $storage_dir/$paired_dir/$images_dir/ -r \n"; }

        my $link_test = Sequencing::Solexa_analysis::change_solexa_links(
            -testing             => $testing,
            -new_location        => $storage_path,
            -new_paired_location => $flowcell_paths[1],
            -solexa_run_path     => $data_path,
            -params_file         => $params_file,
            -lane_data_dir       => $lane_data_dir
        );

        unless ( $volume =~ /data3/ ) {
            print "Remove Original Directory: rm -rf $flowcell_path/$run_dir$lane_dir \n";
        }
        print "Set Files_Status = 'Stored' where FK_Run__ID = $run_id \n";
    }
    print "\n\n";
}

################ use this if we want to create a directory structure similar to projects dir
#    my ( $slash, $home, $aldente, $private, $Projects, $project_dir, $library_dir, $Analyzed, $run_dir ) = split '/', $data_path;
#    try_system_command("mkdir $storage_dir/$project_dir/");
#    try_system_command("mkdir $storage_dir/$project_dir/");
#    try_system_command("mkdir $storage_dir/$project_dir/");
#    print "$storage_dir/$project_dir/$library_dir/$run_dir/ \n";
#    system("cp $data_path/$data_dir/* /archive/solexa1_3/data3/ -r");
#################
$Report->completed();
exit;

