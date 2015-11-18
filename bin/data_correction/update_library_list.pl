#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

################################################################################
#
# update_lib_list.pl
#
# This program regularly updates the library_list file.
#
################################################################################
################################################################################
# $Id: update_library_list.pl,v 1.17 2004/12/01 02:19:39 rguin Exp $ID$
################################################################################
# CVS Revision: $Revision: 1.17 $
#     CVS Date: $Date: 2004/12/01 02:19:39 $
################################################################################
use strict;
use CGI qw(:standard);
use Benchmark;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";

# Standard Input/Output routines (DB_Connect)
use SDB::DBIO;
use SDB::CustomSettings;

use RGTools::RGIO;
use RGTools::Process_Monitor; 

use alDente::SDB_Defaults;
use alDente::Sequencing;
use alDente::Notification;

require "getopts.pl";
&Getopts('v');

use vars qw($opt_v);
##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($testing $project_dir $mirror_dir $archive_dir $bioinf_dir $URL_cache $login_file);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $dbase = "sequence";
my $public_project_dir = $bioinf_dir;
my $verbose = $opt_v || 0;    ## only send notification in verbose mode (1 / day)
my %Messages;
my $check_name 	= "update_library_list";
my $email_recipient = "aldente";

################# construct Process_Monitor object for writing log ##################

my $Report = Process_Monitor->new('update_library_list.pl Script');

######### Get default database from login_file configuration settings ########
my $CONFIG;

my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>'lims02',-user=>'cron',-password=>'');
$dbc->connect();

my @updates = ();

### Update Library subdirectories in alDente Projects directory ###
my @info = &Table_find($dbc,'Library,Project','Library_Name,Project_Path',"where FK_Project__ID=Project_ID ORDER BY Library_Name");

my $library_list_file = "$URL_cache/library_list";
my $LIB_LIST;

open (LIB_LIST,">$library_list_file") or ($Report->set_Error("Error opening $library_list_file file.") );

my $checked = 0;
$Report->set_Message("Inspecting " . scalar(@info) . " Libraries");
foreach my $lib (@info) {
    $checked++;
    (my $library,my $localpath) = split ',',$lib;
    my $project_path = "$project_dir/$localpath";
    #print LIB_LIST "$localpath/$library\n";
    unless (-e "$project_path/$library/AnalyzedData") {
	#print "Create AnalyzedData subdirectory for $lib\n";
	$Report->set_Detail("Create AnalyzedData subdirectory for $lib");
	try_system_command("mkdir $project_path/$library/AnalyzedData -m 777 -p",-verbose=>$verbose,-report=>$Report);
	push(@updates,"Added $project_path/$library AnalyzedData directory");
    }

    unless (-e "$project_path/$library/SampleSheets") {
	#print "Create SampleSheets subdirectory for $lib\n";
	$Report->set_Detail("Create SampleSheets subdirectory for $lib");
	try_system_command("mkdir $project_path/$library/SampleSheets -m 777 -p",-verbose=>$verbose);
	push(@updates,"Added $project_path/$library SampleSheet directory");
    }

    ###############################################################################################
    # add 'published' subdirectories to each project and each library within the project 
    unless (-e "$project_path/published") {
	$Report->set_Detail("Create published subdirectory for $project_path");
	try_system_command("mkdir $project_path/published -m 777 -p",-verbose=>$verbose);
	push(@updates,"Added $project_path/ published directory");
    }
    unless (-e "$project_path/$library/published") {
	$Report->set_Detail("Create published subdirectory for $lib");
	try_system_command("mkdir $project_path/$library/published -m 777 -p",-verbose=>$verbose);
	push(@updates,"Added $project_path/$library published directory");
    }
    ###############################################################################################


    ## Check for moved or copied (repeated) library directories ##
 
    my @other_directories = split "\n", try_system_command("ls $project_dir/*/$library -d");
    if (int(@other_directories) > 1) {
		my $update = "Warning: Repeat library directory found in Projects directory: $library\n";
                $update .= join("\n",@other_directories);
		$Report->set_Warning($update);
		push(@updates,$update);

    } else {     
	$Report->succeeded();
	$Report->set_Detail("$library ... ok ...");
	#print "$library ... ok ...\n";
    }
    
    unless ($public_project_dir && ($project_dir ne $public_project_dir)) { next }
    ## Make public directories ##
    
    unless (-e "$public_project_dir/$localpath/$library/" || $project_dir eq $public_project_dir) {
	my $sys_command = "mkdir $public_project_dir/$localpath/$library -m 777 -p";
	my $fback = try_system_command($sys_command,-verbose=>$verbose);
	$Report->set_Warning($fback) if $fback;
	push(@updates,"Added Public path: $public_project_dir/$localpath/$library SampleSheet directory");
	
	my @other_directories = split "\n", try_system_command("ls $public_project_dir/*/$library -d");
	if (int(@other_directories) > 1) {
	    
	    my $update = "Warning: Repeat library subdirectory found in public Projects directory:\n";
	    foreach my $dir (@other_directories) {
		$update .= "$dir\n";
	    }     
	    $Report->set_Warning($update);
	    push(@updates,$update);
	}   
    }
}

close(LIB_LIST);
$Report->set_Message("Checked $checked library paths\n");

### ensure inclusion of all mirror & archive directories for sequence data ###
 my %Machine_Info = &Table_retrieve($dbc,"Machine_Default,Equipment",['Equipment_Name','Local_Data_dir'],"where FK_Equipment__ID=Equipment_ID AND Equipment_Type IN ('Sequencer','Fluorimager') Order by Equipment_Name","Distinct");
 
#print "Set Local Path for active Hosts:\n";
$Report->set_Detail("Set Local Path for active Hosts:");
my $index=0;
while (defined %Machine_Info->{Equipment_Name}[$index]) {
    my $host = %Machine_Info->{Equipment_Name}[$index];
    my $dir = %Machine_Info->{Local_Data_dir}[$index];
    if (($host=~/\S+/) && ($dir=~/(.*)\/(.*?)$/)) {
	my $volume = $2;
	#print "Host: $host  Path:$dir\n";
	$Report->set_Detail("Host: $host  Path:$dir");
    }
    #### Ensure mirror/archive paths exist ####
    unless (-e "$mirror_dir/$dir") {
	try_system_command("mkdir $mirror_dir/$dir -p -m 755",-verbose=>$verbose); 
	push(@updates, "Added $dir machine directory"); 
    }
    unless (-e "$archive_dir/$dir") {
	try_system_command("mkdir $archive_dir/$dir -p -m 755",-verbose=>$verbose); 
	push(@updates, "Added $dir machine directory");
    }
    $index++;
}

### Refresh Parameters... ###
$Report->set_Message("Refreshing Parameters...");
&alDente::Tools::initialize_parameters($dbc,$dbase);

if (@updates && $verbose) {
    my $list = join "\n", @updates;
    $Report->set_Detail("Updates Made: $list");
}

$Report->completed();
$Report->DESTROY();
exit;

