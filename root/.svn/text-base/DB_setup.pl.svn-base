#!/usr/local/bin/perl56

###############################
# DB_setup.pl
###############################

##################################################
# Custom Initialization of Database (Description)
##################################################
#
# It is designed to:
#  - set up the initial structure for the sequence database,
#  - include a few standard records to some tables
#
#################
#  Preparation 
#################
#
# Ensure:  
#   - Data_directory path is specified correctly in SDB_Defaults
#   - 
#
#

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; # add the local directory to the lib search path

use alDente::SDB_Defaults;    ### custom defaults (Dump_dir, bin_home)

use SDB::DB_IO;                ### database I/O module
use SDB::CustomSettings;       ### default settings (login_file, Defaults)

use RGTools::RGIO;             ### system command with feedback.

use vars qw(%Defaults);
use vars qw($Dump_dir $login_file $bin_home);

my $abort = 0;

my $dbase = $Defaults{DATABASE};
my $testdbase = 'seqtest1';

print "\nTesting with $testdbase rather than $dbase\n\n";
my $dbase = $testdbase;

my $restore_script = "restore_DB.pl";

print "Check for Dump directory\n*******************************\n";
if (-e "$archive_dir") {print "Found Dump directory\n($archive_dir)... (Continuing)\n\n";}
else                {print "Dump directory not found !\n($archive_dir) (ABORTING)\n\n"; $abort=1; }

print "Check for Login File\n*******************************\n";
if (-e "$login_file") {print "Found Login configuration file\n($login_file) ... (Continuing)\n\n";}
else                {print "Login configuration file not found\n($login_file) ! (ABORTING)\n\n"; $abort=1; }

print "Check for Restoration Script\n*******************************\n";
if (-e "$bin_home/$restore_script") {print "Found restore script\n($bin_home/$restore_script)... (Continuing)\n\n";}
else                {print "restore Database script not found !\n($bin_home/$restore_script) (ABORTING)\n\n"; $abort=1; }

my $dbh = DB_Connect(dbase=>$dbase);
unless ($dbh) { 
    print "First create empty database $dbase in mySQL\n"; 
    $abort=1; 
}
$dbh->disconnect();

if ($abort) {
    print "Initialization Aborted.  Please address errors first and try running again.\n\n";
} else {
    my $command = "$restore_script -D $dbase -f startup -R";
#    my $feedback = try_system_command("$restore_script -D $dbase -f startup -R");  ### restores startup database from skeleton version of database.
	print "Command: $command.\n";
}

exit;
