#!/usr/local/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use alDente::SDB_Defaults;
use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;

use Data::Dumper;
use Time::Local;

use vars qw($opt_d $opt_r $opt_dbase $opt_host $opt_user $opt_pass $opt_update);

use Getopt::Long;
&GetOptions(
	    'd=s'      => \$opt_d,
	    'r=s'      => \$opt_r,
	    'dbase=s'      => \$opt_dbase,
	    'pass=s' => \$opt_pass,
	    'host=s'     => \$opt_host,
	    'user=s'       => \$opt_user,
 	    'update=s' => \$opt_update
	    );

my $API = new SDB::DBIO(-dbase=>$opt_dbase,-host=>$opt_host,-user=>$opt_user,-password=>$opt_pass,-connect=>1);
my $dbc = $API;

my $condition = '';
if ($opt_r) {
    my $runs = &resolve_range($opt_r);
    $condition .= " AND Run_ID in ($opt_r) ";
}
if ($opt_d) {
    $condition .= " AND Run_DateTime >= '$opt_d' ";
}

my @run_info = $dbc->Table_find("Project,Library,Plate,Run,SequenceRun,SequenceAnalysis,RunBatch,Equipment","Run_ID,Project_Path,Library_Name,Run_Directory,Q20mean,Equipment_Name,Run_DateTime","WHERE FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID AND FK_Plate__ID=Plate_ID AND SequenceRun_ID=FK_SequenceRun__ID AND FK_Run__ID=Run_ID AND FK_RunBatch__ID=RunBatch_ID AND FK_Equipment__ID=Equipment_ID $condition");

foreach my $row (@run_info) {    
    my ($run_id,$project_path,$library,$run_dir,$q20mean,$equ,$old_datetime) = split ',',$row;
    my @files = `ls /home/sequence/Projects/$project_path/$library/AnalyzedData/$run_dir/chromat_dir/*`;

    my $first_file = $files[0];
    chomp $first_file;
    my @statval = stat($first_file);
    my $datetime = date_time($statval[9]);
    my ($year,$mon,$mday,$hour,$min,$sec) = $old_datetime =~ /(\d{4})\-(\d{2})\-(\d{2})\s(\d{2})\:(\d{2})\:(\d{2})/;
    my $old_epoch =  timelocal($sec,$min,$hour,$mday,$mon-1,$year);
    my $daydiff = (((($statval[9] - $old_epoch)/60)/60)/24);
    print "$run_id, $run_dir, $equ, $q20mean, $old_datetime, $datetime, ".substr($daydiff,0,4)." days\n";
    if ($opt_update) {
	$dbc->Table_update_array("Run",["Run_DateTime"],[$datetime],"WHERE Run_ID = $run_id",-autoquote=>1);
    }
}
