#!/usr/local/bin/perl

use strict;

use CGI qw(:standard);

use POSIX qw(strftime);
require "getopts.pl";

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Imported/"; # add the local directory to the lib search path



use SDB::DBIO;
use Data::Dumper;

use alDente::SDB_Defaults;   
use SDB::CustomSettings;  

use RGTools::Process_Monitor;
use RGTools::RGIO;

use vars qw($project_dir);

my $PUBLISH_DIR = "/usr/local/apache/htdocs/ssl/collab_submission/htdocs/Projects";
my $SEQ_DIR = $project_dir;

my $Report = Process_Monitor->new('Mirror Publish dir script');

# check if the script is already running
my ($script_name) = $0 =~ /\/?([^\/]+)$/; 
my $cmd = "ps uww -C $script_name";
my $others_found = '';
my $current_processes = `$cmd`;
foreach my $ps (split /\n/, $current_processes) {
    unless ($ps =~ /$script_name/) {next}
    else {
	my ($pid) = $ps =~ /^\w+\s+(\d+)/;
	unless (int($pid) == int($$)) { # Found other seqmirror processes.  Exit.
    	     $others_found .= "$ps\n";
	}
    }
}

if ($others_found) {
    print "** already in process **\n";			
    print $others_found;
    exit;
}

# Connect
my $host = $Defaults{mySQL_HOST}; #Default to the default mysql host.
my $db = "sequence";
my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$db,-user=>'viewer',-password=>'viewer',-connect=>1);

# try to rsync Projects
my @project_info = $dbc->Table_find("Project","Project_ID,Project_Name,Project_Path");
my ($command,$feedback);
foreach my $row (@project_info) {
    my ($project_id,$project_name,$project_path) = split ',',$row;

    if (-e "$SEQ_DIR/$project_path/publish") {
	$Report->set_Detail("Syncing publish directory for $project_name");
	# create directory
	unless (-e "$PUBLISH_DIR/$project_path") {
	    try_system_command("mkdir $PUBLISH_DIR/$project_path",-report=>$Report);
	}
	unless (-e "$PUBLISH_DIR/$project_path/publish") {
            $feedback = try_system_command("mkdir $PUBLISH_DIR/$project_path/publish",-report=>$Report);
	}
	# rsync project command
	$feedback = try_system_command(qq{rsync --delete --ignore-existing -u $SEQ_DIR/$project_path/publish/* $PUBLISH_DIR/$project_path/publish},-report=>$Report);
    }
    else {
	print "PDIR: $PUBLISH_DIR \n";
	$Report->set_Detail("No publish directory, skipping $project_name");
    }
    # try to rsync Libraries
    my @lib_info = $dbc->Table_find("Library","Library_Name","WHERE FK_Project__ID=$project_id");
    foreach my $row (@lib_info) {
	my $lib = $row;
	if (-e "$SEQ_DIR/$project_path/$lib/publish") {
	    $Report->set_Message("Syncing publish directory for $lib");
	    unless (-e "$PUBLISH_DIR/$project_path") {
                $feedback = try_system_command("mkdir $PUBLISH_DIR/$project_path",-report=>$Report);
	    }
	    unless (-e "$PUBLISH_DIR/$project_path/$lib") {
                $feedback = try_system_command("mkdir $PUBLISH_DIR/$project_path/$lib",-report=>$Report);
	    }
	    unless (-e "$PUBLISH_DIR/$project_path/$lib/publish") {
                $feedback = try_system_command("mkdir $PUBLISH_DIR/$project_path/$lib/publish",-report=>$Report);
	    }
	    # rsync library command
            $feedback = try_system_command(qq{rsync --delete --ignore-existing -u $SEQ_DIR/$project_path/$lib/publish/* $PUBLISH_DIR/$project_path/$lib/publish},-report=>$Report);
	}
	else {
	    $Report->set_Detail("No publish directory, skipping $lib");
	}
    }
}

$Report->completed();
exit;
