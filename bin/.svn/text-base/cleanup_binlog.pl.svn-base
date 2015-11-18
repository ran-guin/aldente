#!/usr/local/bin/perl
#
################################################################################
#
# cleanup_binlog.pl
#
# This program:
# Flushes the master binary log and removes the old logs up to the specified days before
# NOTE:  directories are hard coded for Safety (/home/sequence/)
#
################################################################################

################################################################################
# $Id: cleanup.pl,v 1.19 2004/07/07 17:32:49 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.19 $
#     CVS Date: $Date: 2004/07/07 17:32:49 $
################################################################################

use strict;
use DBI;
use File::stat;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::DBIO;
use RGTools::RGIO;

use SDB::CustomSettings;

use alDente::SDB_Defaults;
use Data::Dumper;
use vars qw($opt_dbase $opt_user $opt_password $opt_days $opt_mhost $opt_shost);

############# Options for Cleaning UP ###########

my $dbase;
my $user;
my $password;

use Getopt::Long;
&GetOptions(
	    'dbase=s' => \$opt_dbase,
	    'mhost=s'  => \$opt_mhost,
            'shost=s'  => \$opt_shost,
	    'user=s'     => \$opt_user,
	    'password=s'     => \$opt_password,
	    'days=s' => \$opt_days
	    );


my $dbase = $opt_dbase || 'sequence';  ## Master Database
my $mhost = $opt_mhost || 'lims02';  ## Master Host
my $shost = $opt_shost || 'lims01'; ## Slave Host
my $user = $opt_user;  ## user
my $password = $opt_password;  ## password

if ($dbase && $user && $password) {
    my $mdbc = SDB::DBIO->new(-dbase=>$dbase,-host=>$mhost,-user=>$user,-password=>$password); 
    $mdbc->connect();
    my $flush_query = "FLUSH LOGS";
    my $flushed_queries = $mdbc->query(-query=>"$flush_query");
    my $sdbc =  SDB::DBIO->new(-dbase=>$dbase,-host=>$shost,-user=>$user,-password=>$password); 
    $sdbc->connect();
    my $sth = $sdbc->query(-query=>"SHOW SLAVE STATUS",-finish=>0);
    my $results = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'AofH');
    #print Dumper $results;
    my $master_log_file = $results->[0]->{Master_Log_File};
    my $slave_running = $results->[0]->{Slave_SQL_Running};
    my $slave_io = $results->[0]->{Slave_IO_Running};
    if ($slave_running eq 'Yes' && $slave_io eq 'Yes'){
	my $purge_query = "PURGE MASTER LOGS";
	$purge_query .=" TO '$master_log_file'";

	my $purged_queries = $mdbc->query(-query=>"$purge_query");
    }
    $mdbc->disconnect();
    $sdbc->disconnect();



} else {

print "Dbase, user, and password are mandatory\n"; 

print<<HELP;

File:  cleanup_binlog.pl
#####################

Options:
##########

 

-dbase (database)    Database files to clean up.
-host (Host)
-user (User
-password (Password)

to cleanup the binary logs

Example:  
###########
           cleanup_binlog.pl -dbase sequence -host lims02 -user <user> -password <password>

Flushes the master database and cleans up the binary logs

HELP
    exit;
}
