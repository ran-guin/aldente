#!/usr/local/bin/perl

################################################################################
#
# backup_consistency_check.pl
#
# This program check the slave status and write the results to a log - generating a cron summary error if the slave log position remains stuck in the same place for two consecutive calls.
#
#
################################################################################

use strict;
use DBI;
use Data::Dumper;
use File::stat;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";


use SDB::CustomSettings;
use SDB::DBIO;
use RGTools::RGIO;
use RGTools::Process_Monitor;
use alDente::SDB_Defaults;  

use vars qw($opt_dbase $opt_user $opt_password $opt_host $opt_type $opt_slave $opt_T $opt_X $opt_path $opt_limit $opt_S $opt_time $opt_mysql_dir $opt_condition $opt_start_index $opt_end_index $opt_confirm $opt_purge $opt_binlog $opt_dump $opt_h);
use vars qw($testing $Dump_dir %Defaults $bin_dir);
##############################
#use vars qw($opt_D $opt_S $opt_u $opt_p $opt_h $opt_t);
#use vars qw($Dump_dir);
#
#require "getopts.pl";
#&Getopts('D:S:u:p:ht:');

use Getopt::Long;
&GetOptions(
	    'dbase=s'       => \$opt_dbase,
	    'user=s'        => \$opt_user,
	    'password=s'    => \$opt_password,
	    'host=s'        => \$opt_host,
	    'type=s'        => \$opt_type,
	    'slave=s'       => \$opt_slave,
	    'T=s'           => \$opt_T,
	    'X=s',          => \$opt_X,
#	    'path=s',       => \$opt_path,
	    'limit=s',      => \$opt_limit,
	    'S',            => \$opt_S,
	    'time=s'        => \$opt_time,
	    'mysql_dir=s'   => \$opt_mysql_dir,
	    'start_index=s' => \$opt_start_index,
	    'end_index=s'   => \$opt_end_index,
            'confirm'       => \$opt_confirm,
#	    'purge'         => \$opt_purge,
	    'binlog'        => \$opt_binlog,
	    'dump'          => \$opt_dump,
	    'h'             => \$opt_h,
	    );
$Dump_dir = '/home/aldente/private/dumps/';

### Get Mandatory input ###
my $dbase       = $opt_dbase;
my $user        = $opt_user;
my $password    = $opt_password;
my $host        = $opt_host || $Defaults{mySQL_HOST};
my $type        = $opt_type || 'txt';
my $slave       = $opt_slave;
my $start_index = $opt_start_index || 1;    ## just for large split files ... 
my $end_index   = $opt_end_index;              ## just for large split files ... 
my $confirm     = $opt_confirm;              ## just for large split files ... 
my $purge       = $opt_purge;

### Get Optional input ###
my $tables              = $opt_T || '';
my $exclusions          = $opt_X || '';
my $structure           = $opt_S;
my $path                = $opt_path || "$alDente::SDB_Defaults::Dump_dir/<HOST>/<DATABASE>/<DATE>/<TIME>";    ## default dump structure ##
my $max_records         = $opt_limit || 100000;
my $mysql_dir           = $opt_mysql_dir || '/usr/bin/';
my $time_request        = $opt_time;
my $condition           = $opt_condition;

######################## construct Process_Monitor object for writing to log file ###########

my $Report = Process_Monitor->new();

if ($opt_h || !$dbase) {
    print_help_info();
    $Report->completed();
    $Report->DESTROY();
    exit;
}

my %Split_Records;
### old input... 

my $m_dbase = $dbase;  ## $opt_D;                  # Master database
my $m_host = $host;    ## Master host
my $s_hosts = $slave;  ##$opt_S;                   # Slave hosts
my $user = $opt_user;                                # Login user

my $backup_type;  ## = $opt_t;                     # Backup type
if ($opt_purge) { $backup_type = 'purge' }
elsif ($opt_binlog) { $backup_type = 'binlog' }
elsif ($opt_dump)   { $backup_type = 'dump' }
# Resolve master dbase into host if necessary
if ($m_dbase =~ /([\w\-]*):([\w\-]*)/) {
    $m_host = $1;
    $m_dbase = $2;
}


### not consistent with usage???

#print "\n########################\n M: $m_host \n########################\n";
#unless ($m_host && $m_dbase && $s_hosts && $user && $backup_type) {
#    print "Missing arguments. Please use '-h' to see help info.\n";
#    print "... -host $m_host -dbase $m_dbase -slave $s_hosts -user $user; ($backup_type)\n";
#    exit;
#}

### Set time stamp ###
my ($today,$nowtime) = split ' ',&date_time;

if ($time_request =~ /[\s\.]/) { ($today,$nowtime) = split /[\s\.]/, $time_request; }
elsif ($time_request) {$nowtime = $time_request;}

if ($nowtime =~ /(\d\d:\d\d):\d\d/) { $nowtime=$1 }  ## trim off seconds from time ##

unless ($host) { $host = Prompt_Input('string','Which Database Host ?: ') }

#my ($use_host,$m_db) = check_replication($host,$dbase,$slave);

$Report->set_Message("Constistency Check requested: $today.$nowtime");

############# Options for Backing UP ###########
my @ignore = split ',', $exclusions;
my $ignored_tables = scalar(@ignore); 

unless ($user) { $user = Prompt_Input('string','Database Username >>') }

# Connect to the master database
$Report->set_Detail("Connecting to $m_host : $m_dbase");
my $m_Conn = SDB::DBIO->new(-host=>$m_host,-dbase=>$m_dbase,-user=>$user,-password=>$password,-connect=>1);
#$Report->set_Detail("Connected to $m_dbase");
unless ($m_Conn->dbh()) {
    $Report->set_Error("Failed connecting master database - " . $DBI::errstr);
    $Report->DESTROY();
    exit;
}

my %MS_Status = %{ get_MasterSlave_Status(-master=>$m_host,-dbase=>$dbase,-slave=>$s_hosts) };    


$Report->completed();
$Report->DESTROY();
$m_Conn->disconnect();
exit;

##############################
sub get_MasterSlave_Status {
##############################
    my %args = &filter_input(\@_);
    my $m_host = $args{-master};
    my $s_hosts  = $args{-slave};
    my $m_dbase  = $args{-dbase};
    my $success;
    my $file_path = Process_Monitor::cron_dir('0d')."/backup_consistency_check.log";
    my %Info;
=begin
    # Get the status of the master
    print "\n>>Obtaining status of the master ($m_host:$m_dbase) (@{[date_time()]})...\n";
    $Report->set_Detail("Obtaining status of the master ($m_host:$m_dbase) (@{[date_time()]})...");
    my $sql = "SHOW MASTER STATUS";
    my $sth = $m_Conn->query(-query=>$sql,-finish=>0);
    my $master_info = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'RH');
    
    my ($m_file, $m_position) = @$master_info{('File','Position')};
    print ">>Found master binary log file '$m_file' with position '$m_position'\n";
    
    $MS_Status{master}{file} = $m_file;
    $MS_Status{master}{position} = $m_position;
=cut
    my $read_master_log_pos;
	
    open my $FILE, '<', $file_path or {$success = 0};
    my @lines = <$FILE>; 
    close $FILE;
    
    # we want to find the last position from the log
    @lines = reverse @lines;
    my $master_log_file;
    
    my $field = 'Read_Master_Log_Pos';
    $read_master_log_pos = find_last_element_in_array(-lines=>\@lines,-field=>$field);   
    
    my $field = "Master_Log_File";               
    $master_log_file = find_last_element_in_array(-lines=>\@lines,-field=>$field); 
    
    # Get the status of the slaves
    my %slaves_info;
    my %slaves_conn;
    
    my $slave = 'lims01';
    print "\n>>Obtaining status of the slave '$slave' (@{[date_time()]})...\n";
    
    # Connect to the slave host
    my $s_Conn = SDB::DBIO->new();
    my $s_dbh = $s_Conn->connect(-host=>$slave,-dbase=>$m_dbase,-user=>$user,-password=>$password, -connect=>1); # Note that '$m_dbase' is NOT a typo
    
    unless ($s_dbh) {
	print "\nERROR: Failed connecting slave database - " . $DBI::errstr . ".\n";
	$Report->set_Error("Failed connecting slave database - " . $DBI::errstr);
	return;
    }
    
    my $sql = "SHOW SLAVE STATUS";
    my $sth = $s_Conn->query(-query=>$sql,-finish=>0);
    my $slave_info = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'RH');
    
    $slaves_info{$slave} = $slave_info;
    $MS_Status{$slave}{dbc} = $s_Conn;
    
    
    my $purge = 1;
    # Compare these info to the slaves
    my $slave_info = $slaves_info{$slave};
    my ($s_file, $s_position, $last_error, $last_error_num,$slave_io_running,$slave_sql_running,$Relay_Master_Log_File,$Exec_Master_Log_Pos) = @$slave_info{('Master_Log_File'),('Read_Master_Log_Pos'),('Last_Error'),('Last_Errno'),('Slave_IO_Running'),('Slave_SQL_Running'),('Relay_Master_Log_File'),('Exec_Master_Log_Pos')};
    #$MS_Status{$slave}{position} = $s_position;
    #$MS_Status{$slave}{file} = $s_file;
    #$MS_Status{$slave}{errors} = $last_error;
    #$MS_Status{$slave}{last_error} = $last_error_num;
    $Report->set_Message("Master_Log_File: $s_file");
    $Report->set_Message("Read_Master_Log_Pos: $s_position");
    $Report->set_Message("Slave_IO_Running: $slave_io_running");
    $Report->set_Message("------------------------------------------------");
    $Report->set_Message("Relay_Master_Log_File: $Relay_Master_Log_File");
    $Report->set_Message("Exec_Master_Log_Pos: $Exec_Master_Log_Pos");
    $Report->set_Message("Slave_SQL_Running: $slave_sql_running");
    #$Report->set_Message("Last_error: $last_error");
    #$Report->set_Message("Last_errno: $last_error_num");
    
    #if (($slave_sql_running eq 'No') && ($s_position == $read_master_log_pos)) {
    if (($slave_sql_running eq 'No') || ($slave_io_running eq 'No')) {
	# Slave's I/O thread hasn't caught up with master
	
	my $msg = "Synchronization Error between Master and Slave\n";
	print ">$msg";
	$Report->set_Error($msg);
	if ($last_error) {
	    $Report->set_Message("Last_errno: $last_error_num, Last_error: $last_error\n");
	}
	
	$purge = 0;
    }
    else {
	print "Master and Slave is in Sync\n";
    }
    
    $Info{in_sync} = $purge;
    
    return \%Info;
}
    
###################
sub find_last_element_in_array {    
###################
    my %args = filter_input(\@_);
    my @lines = @{$args{-lines}};
    my $field = $args{-field};
    my $output = '';
    my $field_name = "$field: ";
    
    foreach my $line (@lines) {
 	 	if ($line =~ /$field_name/) {
 	 	    $line =~ s/$field_name//;            
            
            $output = $line;
            $output =~ s/[-' ]//g;
            last;
 	 	}	 
    }
    return $output;

}
######################
sub print_help_info {
######################
    print<<HELP;
File:  backup_consistency_check
##################
Options:
##########
    -dbase                 database specification (Mandatory)
	-user (user)           specify user to login as    
	-password (password)   specify password for user
	-host (host)           defaults to $Defaults{mySQL_HOST} 
    -condition (condition) optional condition for dumping eg. (-w "Employee_Name='tom'")

Example:  
###########

backup_consistency_check.pl -dbase sequence -host lims01 -user super_cron

										
HELP
return;

   }
