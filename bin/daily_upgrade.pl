#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

daily_upgrade.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>This program:<BR>- Is used during development to perform daily upgrades on the database <BR>

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
# daily_upgrade.pl
#
# This program:
#   - Is used during development to perform daily upgrades on the database 
#
################################################################################
################################################################################
# $Id: daily_upgrade.pl,v 1.19 2004/01/21 17:22:11 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.19 $
#     CVS Date: $Date: 2004/01/21 17:22:11 $
################################################################################
use strict;
use DBI;
use Cwd 'abs_path';
use Getopt::Std;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO;
use SDB::CustomSettings;
 
use alDente::SDB_Defaults;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_D $opt_f $opt_u $opt_p $opt_U $opt_d $opt_X $opt_P);
use vars qw($current_dir $mysql_dir);

##############################
# modular_vars               #
##############################
my $upgraded_clone_sequence_path = "/home/sequence/alDente/dumps/Clone_Sequence_3212467/"; # Location where the dumps of the upgrade Clone_Sequence table is found
my $upgraded_clone_sequence_db = 'seqdev'; # The database where the dumps of the upgrade Clone_Sequence table was created
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
getopts('D:f:u:p:UdX:P');

my $cmd;
my $fback;
my $source_dir = abs_path("$current_dir/../") . "/";
my $production = $opt_P if ($opt_P);       # If $opt_P is set then runs the commands - otherwise just do a dry run to see if the commands are correct

if ($opt_U) { # Update source code
    # First check the status of the upgrade code in CVS.  If there are conflicts then exit the upgrade.
    my $cmd = "cd $source_dir; cvs -n update install/upgrade/";
    print ">>>Checking conflicts in source code. Trying '$cmd'...\n";
    $fback = try_system_command($cmd) if $production;
    print "$fback\n";
    foreach my $line (split /\n/, $fback) {
	my ($status,$file) = $line =~ /^([A-Z]{1}) (.*)/;
	if ($status eq 'C') {
	    print "*****Conflicts found in '$file'. Exiting the script.\n";
	    exit;
	}
    }
    # If no conflicts found lets do a cvs update
    $cmd = "cd $source_dir; cvs update install/upgrade/";
    print ">>>Updating local source code. Trying '$cmd'...\n";
    $fback = try_system_command($cmd) if $production;
    print "$fback\n";
}

my $t_host = $Defaults{mySQL_HOST}; #Default to the default mysql host.
my $t_dbase = $opt_D if ($opt_D);
my $user = $opt_u if ($opt_u);
my $password = $opt_p if ($opt_p);
if ($t_dbase =~ /([\w\-]*):([\w\-]*)/) { #See if user is specifying both host and database.
    $t_host = $1;
    $t_dbase = $2;
}

unless ($t_host && $t_dbase && $user && $password) {
    print "*****Target database login information missing. Exiting the script.\n";
    exit;
}

#Safety guard - Prompt user again if they are trying to upgrade the 'sequence' database...
if ($t_dbase =~ /sequence/) {
    print "*****Daily upgrade on 'sequence' database not allowed. Exiting the script.\n";
    exit;
}

# Restore database
my $s_host = $Defaults{mySQL_HOST};
my $s_dbase = $opt_f if ($opt_f);
if ($s_dbase =~ /([\w\-]*):([\w\-]*)/) { #See if user is specifying both host and database.
    $s_host = $1;
    $s_dbase = $2;
}
unless ($s_host && $s_dbase && $user && $password) {
    print "*****Source database login information missing. Exiting the script.\n";
    exit;
}

# Drop existing database and recreate it.
if ($opt_d) {
    $cmd = "$mysql_dir/mysql -h $t_host -u $user --password=$password -e 'DROP DATABASE IF EXISTS $t_dbase; CREATE DATABASE $t_dbase' -vv";
    print ">>>Dropping database '$t_dbase' on host '$t_host'. Trying '$cmd'...\n";
    $fback = try_system_command($cmd) if $production;
    print "$fback\n";
}

# Restore database (skip Clone_Sequence)
my $exclude;
if ($opt_X) {$exclude = "-X $opt_X"}
else {$exclude = "-X Clone_Sequence"} # By default do not restore the Clone_Sequence table from production database
$cmd = "$source_dir/bin/restore_DB.pl -D $t_host:$t_dbase -f $s_host:$s_dbase -u $user -p $password -F $exclude";
print ">>>Restoring database '$t_dbase' on host '$t_host' from database '$s_dbase' on host '$s_host'. Trying '$cmd'...\n";
$fback = try_system_command($cmd) if $production;
print "$fback\n";

# Upgrade database (skip Clone_Sequence)
$cmd = "$source_dir/bin/upgrade_DB.pl -A upgrade -D $t_host:$t_dbase -u $user -p $password -B Clone_Sequence -S -l";
print ">>>Upgrading database '$t_dbase' on host '$t_host' without Clone_Sequence table. Trying '$cmd'...\n";
$fback = try_system_command($cmd) if $production;
print "$fback\n";

# Restore the upgraded Clone_Sequence table from backup location
$cmd = "$source_dir/bin/restore_DB.pl -D $t_host:$t_dbase -f $upgraded_clone_sequence_db -l '$upgraded_clone_sequence_path' -u $user -p $password -F";
print ">>>Restoring Clone_Sequence table on database '$t_dbase' on host '$t_host' from location '$upgraded_clone_sequence_path'. Trying '$cmd'...\n";
$fback = try_system_command($cmd) if $production;
print "$fback\n";

# Insert the new Clone_Sequence records from the source database starting from the records that have not been upgrade yet
my ($max_upgraded_clone_sequence_id) = $upgraded_clone_sequence_path =~ /(\d+)\/?$/;
my $Connection = DBIO->new();
$Connection->connect(-host=>$t_host,-dbase=>$t_dbase,-user=>$user,-password=>$password);
my $cmd = "INSERT INTO $t_dbase.Clone_Sequence SELECT *,'' FROM $s_dbase.Clone_Sequence WHERE $s_dbase.Clone_Sequence.Clone_Sequence_ID > $max_upgraded_clone_sequence_id";
print ">>>Inserting new Clone_Sequence records. Executing '$cmd'...\n";
my $arg1;
my $arg2;
my $arg3;
($arg1,$arg2,$arg3) = $Connection->execute_command(-command=>$cmd,-feedback=>2) if $production;
if ($arg3 =~ /success/i or !$production) {
    print ">>>New Clone_Sequence records created successfully.\n";
    # Upgrade the Clone_Sequence table for the new records
    $cmd = "$source_dir/bin/upgrade_DB.pl -A upgrade -D $t_host:$t_dbase -u $user -p $password -b Clone_Sequence -N Clone_Sequence -f -l";
    print ">>>Upgrading new records of Clone_Sequence table on database '$t_dbase' on host '$t_host'. Trying '$cmd'...\n";
    $fback = try_system_command($cmd) if $production;
    print "$fback\n";
}
else {print ">>>Failed to create new Clone_Sequence records ($arg3)\n"}
$Connection->disconnect();

# Set DB Fields
$cmd = "$source_dir/bin/upgrade_DB.pl -A set -D $t_host:$t_dbase -u $user -p $password";
print ">>>Setting DBTable and DBField on database '$t_dbase' on host '$t_host'. Trying '$cmd'...\n";
$fback = try_system_command($cmd) if $production;
print "$fback\n";

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

$Id: daily_upgrade.pl,v 1.19 2004/01/21 17:22:11 achan Exp $ (Release: $Name:  $)

=cut

