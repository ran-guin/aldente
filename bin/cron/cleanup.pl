#!/usr/local/bin/perl
#
################################################################################
#
# cleanup.pl
#
# This program:
#   compresses old backup files, 
#   removes old files in Temp directory
#   
# NOTE:  directories are hard coded for Safety (/home/sequence/)
#
################################################################################

use strict;
use CGI qw(:standard);
use DBI;
use File::stat;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Imported/"; # add the local directory to the lib search path
use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::CustomSettings;

use alDente::SDB_Defaults;

require "getopts.pl";
&Getopts('D:H:S:X:P:mbA');
use vars qw($opt_D $opt_S $opt_X $opt_P $opt_m $opt_b $opt_H $opt_A);

use vars qw($mirror_dir $session_dir $Dump_dir $Data_log_directory $Data_home_dir);
use vars qw($URL_dir $URL_temp_dir);

############# Options for Cleaning UP ###########

my $directory;
my $exception;
my $preserve = '01';   # default to first of month... #
my $erased=0;
my $checked=0;
my $archived=0;
my $preserved=0;
my $removed=0;
my $save = 0;
my $unknown = 0;

if ($opt_X) {$exception = $opt_X;}

if ($opt_P) {
    $preserve = Extract_Values([$opt_P,1]);
    if ($preserve =~ /^\d$/) { $preserve="0$preserve"}
}

my $Report = Process_Monitor->new('cleanup.pl Script');

if ($opt_S) {$save = " -ctime +$opt_S";}
else {
######################## construct Process_Monitor object for writing log file ##############

$Report->set_Error("Specify days to Save ( '-S 4' to save files newer than 4 days old)"); 

print<<HELP;

File:  cleanup.pl
#####################

Options:
##########

 
-S N             number of days to Save.  (all older than N days will be erased)

-X (string)      eXclude filenames containing (string) from cleanup. 

-P N             Preserve filenames with datestamp showing Nth day of the month 
                 (automatically saves first of the month) 

-D (database)    Database files to clean up.

-H (host)        Host for the database. defaults to lims02.

-m               Also compress mirror directories

-b               Also delete/compress backup directories

-A               do not move preserved backups to archive (to restore database use:  'restore_DB')

Example:  
###########
           cleanup.pl -D /home/sequence/Dumps -S 7 -m -b

cleans up all files except those within the last 7 days.
(Also save files containing a datestamp for the first of the month).


Note:
###########
cleanup.pl also empties some TEMP directories of files (older than 2 days by default)

HELP
    exit;
}

my $dbase = $opt_D || 'sequence';
my $host = $opt_H || 'lims02';


my $temp_save = 60;  ### save time in minutes for temporary directories...
my $session_save = '7d';

my $fback = '';  

$Report->set_Message("Cleanup: " . &date_time());
if ($opt_b) {  ## backup directory ##
########################################
###### Clean up Dump Directory #########
########################################
#
# remove directories older than a week
#
# save directories from 1st of month (& compress) 
# remove most subdirectories except last one in directories older than 2 days... 
#
    my $clear = Extract_Values([$opt_S,5]);  # number of days to retain
    ### First locate all directories older than 5 days #######
my $archive_dir = "$Dump_dir/archive/$dbase";
my @oldfilelist = split "\n", try_system_command("find $Dump_dir/$host/$dbase*/ -ctime +$clear -type d -maxdepth 1",-report=>$Report);

if ($oldfilelist[0] =~ /No such file/i) { 
    $Report->set_Error("Dump files: $Dump_dir/$host/$dbase* not found (?)");   

}

else {
    foreach my $dir (@oldfilelist) {
	## locate the $preserve backup (usually first of month)
	if ($dir =~ /(\d{4})\-(\d{2})\-(\d{2})$/ ) {
	    ### move to the archive directory if $opt_a 
	    my $year = $1;
	    my $month = $2;
	    my $day = $3;
	    if (($day eq '01') || ($day eq $preserve)) {
		## leave HARD-CODE '01' to prevent these files from EVER being deleted automatically ##
		if (!$opt_A) {
		    $fback .= "Archiving to $archive_dir.${year}-${month}-${day}\n"; 
		    `mv $dir $archive_dir.${year}-${month}-${day}\n`;
		    $archived++;
		}
		next;
	    } 
	    
	    ### else, delete $dir
	    $fback .= "Deleting $dir\n";
	    `rm -rf $dir\n` if ($dir =~ /\/dumps\//);   ## unnecessary check but LEAVE IN as a SAFETY considering use of dangerous 'rm -rf'
	    $erased++;
	    
	} 
	
    }
    $checked = int(@oldfilelist);
    $Report->succeeded(); 
}

$fback .= "\nCleaned up Dump Directory\n";
$fback .= "$checked directories checked\n";
$fback .= "$erased Erased directories\n";
$fback .= "$archived archived directories\n";
$fback .= "************************************\n";

}

if ($opt_m) {

##################################
#### Cleanup Mirror directory ####
##################################
#
# This should clean up the mirror directory.
# Files already in the archive directory should be erased.
# A list of Files sitting around should be sent to administrators for cleaning out or checking... 
#
# (to be updated)... 
##################################
    
######### compress sequencing data files. (older than one month) #################
    my $maxage = '-30d';
$fback .=  "\nCompressing files older than $maxage....\n";
my @raw = (); ######## Array of directories to compress...
my @datafiles = ();
my $error;

my @mbace_data = split "\n",try_system_command("find $mirror_dir/mbace/*/data2/Data/* -type d",-report=>$Report);

if ($mbace_data[0] =~ /No such file/i) { $Report->set_Error("Mirror files: $mirror_dir/mbace/*/data2/Data/* not found (?)");
					 $error++;}

my @mbace_analyzed = split "\n",try_system_command("find $mirror_dir/mbace/*/data2/AnalyzedData/* -type d",-report=>$Report);
if ($mbace_data[0] =~ /No such file/i) { $Report->set_Error("Mirror files: $mirror_dir/mbace/*/data2/AnalyzedData/* not found (?)");
					 $error++;}

my @mbace_d3700_data = split "\n",try_system_command("find $mirror_dir/3700/*/data1/Data/* -type d",-report=>$Report);
if ($mbace_data[0] =~ /No such file/i) { $Report->set_Error("Mirror files: $mirror_dir/3700/*/data1/Data/* not found (?)"); 
					 $error++;}

$Report->succeeded() unless $error;

    push(@raw, glob("$mirror_dir/mbace/*/data2/Data/*/"));  ### mbace has both *.rsd, *.ab1
    push(@raw, glob("$mirror_dir/mbace/*/data2/AnalyzedData/*/"));
    push(@raw, glob("$mirror_dir/3700/*/data1/Data/*/"));

push (@raw,@mbace_data);
push (@raw,@mbace_analyzed);
push (@raw,@mbace_d3700_data);

### compress if access time older than one month...#
#
#    $fback .=  &compress_directories(\@raw,0,$maxage,'m');    #  Turn off compression... 
#
}

$Report->set_Detail($fback);
$Report->set_Message("Cleaned Dumpfiles $fback");

$Report->completed();
$Report->DESTROY();

exit;

###############################
sub compress_directories {
###############################
#
# This should compress the directory/directories listed to a .tgz file..
# 
# (not being used currently)... (adjust)
#

#
    my $target_name;
    my $zipped_up;
    my $feedback;
    my $zipped;
    my $target_file;
    my $name;

#  ... more code (erased) to be inserted...    

    if (-e "$target_name") {
	if (-e "$target_file.tar.gz") {
	    if ($zipped_up) {
		$feedback .= try_system_command("tar -u --remove-files -z -v -f $target_file.tar.gz $name/",-report=>$Report);
	    }
	    else {$feedback .= "(already zipped & empty)\n"; next;}
	}
	else {  ### update if this file already exists... 
	    $zipped++;
	    $Report->set_Message("Tarring $name..");
	    $feedback .= "*****\ntarring new $name\n->$name\n";
#		$feedback .= try_system_command("tar -c --remove-files -z -v -f $target_file.tar.gz $name/");
	}
    }
    else {$feedback .= "name invalid ($target_name)\n";}

    $Report->set_Message("Compressed\n$feedback (Zipped $zipped files) (Removed $removed backup directories)");
    
    my $df = try_system_command("df -h $mirror_dir",-report=>$Report);
    $Report->set_Message("Current Disk Space $df");
    
    return $feedback;
}
