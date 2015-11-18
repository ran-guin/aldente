#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

quick_restore.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>

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
use strict;
use CGI ':standard';
use DBI;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;
use alDente::SDB_Defaults;           ### get directories only...
use alDente::Notification;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_D $opt_R $opt_H $opt_T $opt_b $opt_c $opt_x $opt_f);
use vars qw($testing $Dump_dir %Defaults);
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
&Getopts('D:u:p:R:H:T:bxf:c');

my $unix_user = `whoami`;
chomp($unix_user);
my $to_address = "$unix_user\@bcgsc.ca,aldente\@bcgsc.bc.ca";
my $hostname = `uname -n`;
my $msg;
$msg .= "Dear $unix_user,\n\n";
$msg .= "You have tried to run quick_restore.pl from $hostname. This script is deprecated since the implementation of MySQL replication and please remove all usages of it. Thanks.\n\n";
$msg .= "LIMS team";
print "ERROR: quick_restore.pl has been deprecated due to the implementation of replication on the backup server\n";
&alDente::Notification::Email_Notification($to_address,'aldente@bcgsc.bc.ca','Access to quick_restore.pl denied',$msg);
exit;

my %Split_Records->{'Clone_Sequence'} = 100000;   ### maximum of 400,000 records in one file... 
my $min_size = 1000;  ### minimum size of dump file (take into account header, lock, unlock.. )
my $user = 'rguin';
my $dbase = $opt_D || 'sequence';
my $Ppassword;
my $Bpassword;
my $target_host = $opt_H || $Defaults{BACKUP_HOST};
my $Pdbase = 'sequence';
my $Phost = 'lims02';  ## use this even if default is to BACKUP_HOST ..
#my $Phost = $Defaults{SQL_HOST};
my $whoami = `whoami`; 
chop $whoami;
unless ($whoami=~/(aldente|sequence|sage|rguin|achan)/) { print "\nPlease log in as sequence or sage first (not $whoami)\n\n"; exit; }
if (($dbase eq $Pdbase) && ($Phost eq $target_host)) {
    print "\nTarget is same as host ? - no restore required\n\n"; exit; 
}

my $basic = $opt_b;

unless ($opt_c || $opt_b || $opt_T || $opt_R) {
    print<<HELP;

File:  quick_restore.pl

This script is used to dynamically update the backup database with current data from the production database.
** Note:  Data that has CHANGED in the Clone_Sequence,Contamination, or Cross_Match file will NOT be update by default.

Since the method of restoring quickly ONLY adds new records that have been added to the Clone_Sequence,Contamination, and Cross_Match data.
(Using -R (runlist) will restore updated records for specified runs if desired)

Options:
*********

-c             - complete backup
-b             - basic tables only
-T (tablelist) - specified tables restored only
-R runlist     - (optional list of run ids to force updating for)

Example:  
           quick_restore.pl -c   (complete restore)
    OR
           quick_restore.pl -R 17558,17559  (restore these runs specifically)

******
NOTE:  For full restore (not incremental), please use restore_DB.pl 
******
HELP
    exit;
}

my $path = $alDente::SDB_Defaults::Dump_dir;
my @large_tables = ('Clone_Sequence','Contaminant','Cross_Match');

my $exclude_list = join ',', @large_tables;

if ($target_host && $Phost) { print "Restoring from $Phost ($Pdbase)  -> $target_host ($dbase)\n\n" } 
else { print "Hosts not defined"; exit; }

my $fully_restore_tables;
if ($opt_T) { 
    $fully_restore_tables = "-T $opt_T"; 
    foreach my $L_table (@large_tables) {    ## Exclude LARGE tables from list of fully restored 
	$fully_restore_tables =~s/\b$L_table\b//g;
    }
    $fully_restore_tables =~ s/^(-T\s+),?(.+)\,?\s*$/$1$2/;
    $fully_restore_tables =~ s/,{2,}/,/g;
}
else { $fully_restore_tables = "-X $exclude_list" }

my $timestamp = &date_time();

unless ($Ppassword) {
    unless ($login_file) {
        print "No Password or Login File specified \n";
        return 0;
    }

    open( OUTFILE, $login_file ) or print "** I cannot open $login_file ($DBI::errstr)\n";
    while (<OUTFILE>) {
        if (/^$target_host:$user:(\S+)/) { $Ppassword = $1; last; }
    }
    close(OUTFILE);
}

my $command = "$bin_home/restore_DB.pl -D $target_host:$dbase -f $Phost:$Pdbase -F $fully_restore_tables -u $user -p $Ppassword > $Data_log_directory/quick_restore.log";
my $feedback = $command;
$feedback=~s/-p \"?(\S+)/-p \*\*\*\*/;

print "Executing ($timestamp):\n$feedback\n";
print "Executing '$command'...\n";

try_system_command($command);          ## basic tables or all tables..
print "Fully restored NON-large tables...\n";

if ($basic && !$opt_T) { exit }         ## stop here if only basic restore required (and Table list NOT specified) 

my $source_dbc = SDB::DBIO->new(-dbase=>$Pdbase,-user=>$user,-host=>$Phost,-connect=>0);
my $target_dbc = SDB::DBIO->new(-dbase=>$dbase,-user=>$user,-host=>$target_host,-connect=>0);
$source_dbc->connect();
$target_dbc->connect();
$timestamp =~s/\s/_/g;
unless (-e "$path/restore/$Phost.$timestamp/") { 
    try_system_command(qq{mkdir $path/restore/$Phost.$timestamp/});
}
my ($max1) = &Table_find($source_dbc,'Clone_Sequence',"Max(Clone_Sequence_ID)");
my ($max2) = &Table_find($target_dbc,'Clone_Sequence',"Max(Clone_Sequence_ID)");
print "filling in from $max2 .. $max1 : " . &date_time();
print "\n";
my $runs;
if ($opt_R) {
    $runs = $opt_R;
} else {
    $runs = join ',', &Table_find($source_dbc,'Clone_Sequence','FK_Run__ID',"where Clone_Sequence_ID > $max2",'Distinct');
}

print "update Runs: " . &date_time();
print "\n$runs\n";
foreach my $table (@large_tables) {
    if ($opt_T) { 
	unless (grep /\b$table\b/, $opt_T) { next }   ## IF Table list specified, skip unless this one was in list
    }
    print "$table Table:\n**********************************\n";
my $condition = "FK_Run__ID in ($runs)";
my $cond = qq{"--where=$condition"};
my $dump_command = qq{$mysql_dir/mysqldump --extended-insert --add-locks --all -q -h $Phost -u $user --password="$Ppassword"};
$command = qq{$dump_command --no-create-info $cond $Pdbase $table > '$path/restore/$Phost.$timestamp/update_$table.sql'};

my $feedback = $command;
$feedback=~s/(--password=\"?)(\S+)/$1\*\*\*\*/;
print "Executing (backup):\n$feedback\n\n";
try_system_command($command);
print "$timestamp\n";
#unless ($opt_x) { next }

unless ($Bpassword) {
    unless ($login_file) {
        print "No Password or Login File specified \n";
        return 0;
    }

    open( OUTFILE, $login_file ) or print "** I cannot open $login_file ($DBI::errstr)\n";
    while (<OUTFILE>) {
        if (/^$target_host:$user:(\S+)/) { $Bpassword = $1; last; }
    }
    close(OUTFILE);
}

my $mysql_command = qq{$mysql_dir/mysql -u $user --password="$Bpassword" -h $target_host $dbase};   ### connect to backup Database
$command = qq{$mysql_command < $path/restore/$Phost.$timestamp/update_$table.sql};
$feedback = $command;
$feedback=~s/(--password=\"?)(\S+)/$1\*\*\*\*/;
print "Executing (restore):\n$command\n**\n$feedback\n\n";
my $ok = try_system_command(qq{$command});
print $ok;
}

$source_dbc->disconnect();
$target_dbc->disconnect();
print "\n";
print "Started  :  $timestamp\n";
print "Completed:  " . &date_time();
print "\n\n";
exit;

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

$Id: quick_restore.pl,v 1.22 2004/05/18 17:12:44 achan Exp $ (Release: $Name:  $)

=cut

