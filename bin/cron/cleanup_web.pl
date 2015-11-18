#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

cleanup_web.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>cleanup.pl<BR>This program:<BR>compresses old backup files, <BR>removes old files in Temp directory<BR>NOTE:  directories are hard coded for Safety (/home/sequence/)<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
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
################################################################################
# $Id: cleanup_web.pl,v 1.9 2004/05/25 23:37:30 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.9 $
#     CVS Date: $Date: 2004/05/25 23:37:30 $
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
use SDB::Report; 
use SDB::CustomSettings;
use alDente::SDB_Defaults;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_D $opt_S $opt_X $opt_P $opt_m $opt_b $opt_u);
use vars qw($session_dir $Data_log_directory $Data_home_dir);
use vars qw($URL_dir $URL_temp_dir);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
require "getopts.pl";
&Getopts('D:S:X:P:mbu:');
############# Options for Cleaning UP ###########
my $directory;
my $exception;
my $preserve;
my $erased=0;
my $checked=0;
my $preserved=0;
my $removed=0;
my $save = 0;
my $unknown = 0;

######################## construct Process_Monitor object for writing to log file ###########

my $Report = Process_Monitor->new('Cleanup Web Script');

if ($opt_X) {$exception = $opt_X;}
if ($opt_P) {$preserve = Extract_Values([$opt_P,1]); if ($preserve<10) {$preserve="0$preserve";}}
my $userid;
if ($opt_u) {
    $userid = $opt_u;
}
if ($opt_S) {$save = " -mtime +$opt_S";}
else {
$Report->set_Error("Specify days to Save ( '-S 4' to save Session files newer than 4 days old)");
print<<HELP;
File:  cleanup.pl
#####################
Options:
##########
-S N             number of days to Save.  (all older than N days will be erased)
-u 25            specify user for session files to move...
(to restore database use:  'restore_DB')
Example:  
###########
           cleanup_web.pl -S 7
cleans up all files except those within the last 7 days.
(Also save files containing a datestamp for the first of the month).
Note:
###########
cleanup.pl also empties some TEMP directories of files (older than 2 days by default)
HELP
    exit;
}
##### track cleanup in log_file... #######
my $log_file = "$Web_log_directory/cleanup/cleanup_".&today;
my $temp_save = 7;  ### save time in days for temporary directories...
#### Get rid of old files in Temp directory ####
$Report->set_Detail("Cleaning out Temp directory..");
if ($URL_temp_dir=~/tmp/i) {      ### require path name to include temp to be sure int is imported...
    my @imagelist = split '\n',try_system_command("find $URL_temp_dir/ -mtime +$temp_save -type f",-report=>$Report);
    my $deleted = 0;
    foreach my $file (@imagelist) {
	if ( $file=~ /(.*)\/tmp\/(.*)/i ) { #ensure it is a temp directory..  
	    $Report->set_Detail("delete $file..");
	    unlink($file);
 #           ### hard code in TEMP path to be SAFE	    
#	    $fback .= "rm -f $1/tmp/$2\n";
#	    $fback .= try_system_command("rm -f $1/tmp/$2");  
	    $deleted++;
	}
#    unlink $file;
    }
    $Report->set_Message("Deleted $deleted files older than $temp_save days old from $URL_temp_dir");
}
############# also clean up SessionInfo files... #############
$Report->set_Detail("Move Sessions to subdirectories");
my @sessionlist = split "\n", try_system_command("find $session_dir -name \"$userid*\" $save -type f -maxdepth 1",-report=>$Report);
$Report->set_Detail("found ".int(@sessionlist)." Session files");
if ($sessionlist[0]=~/too long/) { 
    $Report->set_Detail(" *** LIST TOO LONG ... ***");
} elsif (int(@sessionlist) < 2) {
    $Report->set_Detail("@sessionlist");
}
my $moved = 0;
my $feedback;
foreach my $file (@sessionlist) {
    unless ($file && $session_dir) {next;}
    if ($file=~/$session_dir\/(.+)\//) {
        $Report->set_Detail("skip subdirectory $file");
        next;
    } ## ignore subdirectory files..
    if ($file=~/$session_dir\/\d*:(\w{3})_(\w{3})_([\d_]{2})(.*)(\d{4})/) {
	my $month = "$2_$5";
	my $newdir = "$1_$3";
        $Report->set_Detail("Month: $month; Directory: $newdir");
	unless (-e "$session_dir/$month/") {
	    $feedback = &try_system_command("mkdir -m 775 $session_dir/$month",-report=>$Report);

	    $feedback = &try_system_command("chgrp aldente $session_dir/$month",-report=>$Report);

            $Report->set_Detail("** Made $month directory..");
	}
	unless (-e "$session_dir/$month/$newdir") {
	    $feedback = &try_system_command("mkdir -m 775 $session_dir/$month/$newdir",-report=>$Report);
	    $feedback = &try_system_command("chgrp aldente $session_dir/$month/$newdir",-report=>$Report);
            $Report->set_Detail("** Made $month/$newdir directory..");
	}
	my $error;
	if (-f "$session_dir/$month/$newdir/$file") {  # If session file already exist, merge the new one into it
	    $error = &try_system_command("cat $file $session_dir/$month/$newdir/$file > $file.tmp",-report=>$Report);

	    $error = &try_system_command("mv $file.tmp $session_dir/$month/$newdir/$file",-report=>$Report);
	}
	else {  # Otherwise just move the file into the archived folder
	    $error = &try_system_command("mv $file $session_dir/$month/$newdir/",-report=>$Report);
	}
	if ($error) {
            $Report->set_Error("Error moving $file to $newdir in $month ?: $error");
        }
        
	$moved++;
    }
    else {
	$Report->set_Error("$file not found in $session_dir/SessionInfo/");
    }
}
$Report->set_Message("Moved $moved old SessionInfo files (in $session_dir)");
#### delete sessions older than one month AS WELL ####
$Report->completed();
$Report->succeeded();
$Report->DESTROY();


##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################
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

$Id: cleanup_web.pl,v 1.9 2004/05/25 23:37:30 achan Exp $ (Release: $Name:  $)

=cut

