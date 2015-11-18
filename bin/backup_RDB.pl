#!/usr/local/bin/perl

################################################################################
#
# backup_RDB.pl
#
# This program backup the MySQL database with replication implemented
#
#
#**********SOME DETAILS STILL NEED TO BE LOGGED!!!!*************** Matt 14/12
#
################################################################################

use strict;
use DBI;
use Data::Dumper;
use File::stat;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::CustomSettings;
use SDB::DBIO;
use RGTools::RGIO;
use RGTools::Process_Monitor;
use alDente::SDB_Defaults;

use LampLite::Login;
use LampLite::Config;

use vars
    qw($opt_dbase $opt_user $opt_password $opt_host $opt_type $opt_slave $opt_T $opt_X $opt_path $opt_limit $opt_S $opt_time $opt_mysql_dir $opt_condition $opt_start_index $opt_end_index $opt_confirm $opt_purge $opt_binlog $opt_dump $opt_h $opt_core $opt_finish_file $opt_v $opt_lock_master $opt_no_record $opt_routine);
use vars qw($testing $Dump_dir %Defaults $bin_dir %Configs);
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
    'T|table=s'     => \$opt_T,
    'X=s'           => \$opt_X,
    'path=s'        => \$opt_path,
    'limit=s'       => \$opt_limit,
    'S'             => \$opt_S,
    'time=s'        => \$opt_time,
    'mysql_dir=s'   => \$opt_mysql_dir,
    'start_index=s' => \$opt_start_index,
    'end_index=s'   => \$opt_end_index,
    'confirm'       => \$opt_confirm,
    'purge'         => \$opt_purge,
    'binlog'        => \$opt_binlog,
    'dump'          => \$opt_dump,
    'h'             => \$opt_h,
    'core'          => \$opt_core,
    'finish_file'   => \$opt_finish_file,
    'version|v=s'   => \$opt_v,
    'lock_master'   => \$opt_lock_master,
    'no_record=s'   => \$opt_no_record,
    'routine'       => \$opt_routine
);

### Get Mandatory input ###
my $dbase       = $opt_dbase;
my $user        = $opt_user;
my $password    = $opt_password;
my $host        = $opt_host;
my $type        = $opt_type || 'txt';
my $slave       = $opt_slave;
my $start_index = $opt_start_index || 1;                ## just for large split files ...
my $end_index   = $opt_end_index;                       ## just for large split files ...
my $confirm     = $opt_confirm;                         ## just for large split files ...
my $purge       = $opt_purge;
my $core        = $opt_core;

### Get Optional input ###
my $tables      = $opt_T         || '';
my $exclusions  = $opt_X         || '';
my $structure   = $opt_S;
my $path        = $opt_path;    ## default dump structure ##
my $max_records = $opt_limit     || 100000;
my $mysql_dir   = $opt_mysql_dir || '/usr/bin';
my $time_request = $opt_time;
my $condition    = $opt_condition;
my $lock_master  = $opt_lock_master;
my $no_record    = $opt_no_record;
my $routine      = $opt_routine;
######################## construct Process_Monitor object for writing to log file ###########


my $Setup = LampLite::Config->new( -initialize=>$FindBin::RealBin . '/../conf/custom.cfg');
my $Config = $Setup->{config};

my $Dump_dir =  $Config->{dumps_data_dir};
$host ||= $Config->{SQL_HOST};

my $Report = Process_Monitor->new( -variation => $opt_v, -configs=>$Config);

if ( $opt_h || !$dbase ) {
    print_help_info();
    $Report->completed();
    exit;
}

my @no_records;
if ($no_record) {
    @no_records = split ',', $no_record;    ### start out with specified tables or
}

my %Split_Records;
### old input...

my $m_dbase = $dbase;                       ## $opt_D;                  # Master database
my $m_host  = $host;                        ## Master host
my $s_hosts = $slave;                       ##$opt_S;                   # Slave hosts

my $backup_type;                            ## = $opt_t;                     # Backup type

if    ($opt_purge)  { $backup_type = 'purge' }
elsif ($opt_binlog) { $backup_type = 'binlog' }
elsif ($opt_dump)   { $backup_type = 'dump' }

# Resolve master dbase into host if necessary
if ( $m_dbase =~ /([\w\-]*):([\w\-]*)/ ) {
    $m_host  = $1;
    $m_dbase = $2;
}

my $s_host  = $s_hosts;
my $s_dbase = $dbase;

# Resolve slave dbase into host if necessary
if ( $s_hosts =~ /([\w\-]*):([\w\-]*)/ ) {
    $s_host  = $1;
    $s_dbase = $2;
}

my $local_dump_dir = $path || create_dump_dir();    # Create the dump directory if necessary
$path ||= "$Dump_dir/<HOST>/<DATABASE>/<DATE>/<TIME>";

### not consistent with usage???

#print "\n########################\n M: $m_host \n########################\n";
#unless ($m_host && $m_dbase && $s_hosts && $user && $backup_type) {
#    print "Missing arguments. Please use '-h' to see help info.\n";
#    print "... -host $m_host -dbase $m_dbase -slave $s_hosts -user $user; ($backup_type)\n";
#    exit;
#}

### Set time stamp ###
my ( $today, $nowtime ) = split ' ', &date_time;

if ( $time_request =~ /[\s\.]/ ) { ( $today, $nowtime ) = split /[\s\.]/, $time_request; }
elsif ($time_request) { $nowtime = $time_request; }

if ( $nowtime =~ /(\d\d:\d\d):\d\d/ ) { $nowtime = $1 }    ## trim off seconds from time ##

unless ($host) { $host = Prompt_Input( 'string', 'Which Database Host ?: ' ) }

unless ($password) {
#    my $login_file = SDB::DBIO::_get_login_file();
    my $login_file = "/opt/alDente/versions/ll/conf/mysql.login";
    
    $password = LampLite::Login::get_password( -host => $host, -user => $user, -file => $login_file, -method => 'grep' );
}

my ( $use_host, $m_db ) = check_replication( $host, $dbase, $slave );
##modify path with variables
$path =~ s /<HOST>/$m_host/g;
$path =~ s /<DATABASE>/$dbase/g;
$path =~ s /<DATE>/$today/g;
$path =~ s /<TIME>/$nowtime/g;
##this is for dumping just stored procedures

if ( !$backup_type && $routine ) {
    backup_stored_procedure($path);
    exit;
}
else { $backup_type ||= 'dump' }

$Report->set_Message("Backup requested: $today.$nowtime");

############# Options for Backing UP ###########
my @ignore = split ',', $exclusions;
my $ignored_tables = scalar(@ignore);

unless ($user)     { $user     = Prompt_Input( 'string',   'Database Username >>' ) }
unless ($password) { $password = Prompt_Input( 'password', 'Password >>' ) }

# Connect to the master database
$Report->set_Detail("Connecting to $m_host : $m_dbase");
my $m_Conn = SDB::DBIO->new( -host => $m_host, -dbase => $m_dbase, -user => $user, -login_file=>$login_file, -connect => 1 );
my $s_Conn;
if ($slave) {
    $s_Conn = SDB::DBIO->new( -host => $s_host, -dbase => $s_dbase, -user => $user, -login_file=>$login_file, -connect => 1 );
}

$Report->set_Detail("Connected to $m_dbase");
unless ( $m_Conn->dbh() ) {
    $Report->set_Error( "Failed connecting master database - " . $DBI::errstr );
    $Report->DESTROY();
    exit;
}
##Get the Master Database Status Before Backup
#Stop Slave DB
if ( $s_host . $s_dbase eq $use_host . $m_db && $slave ) {
    $s_Conn->stop_slave($Report);
    $Report->set_Message("Master log");
    $m_Conn->master_log($Report);
    $Report->set_Message("Slave log");
    $s_Conn->slave_log($Report);
}
else {
    $Report->set_Message("Master log");
    if ($lock_master) {
        $m_Conn->lock_tables($Report);
    }
    $m_Conn->master_log($Report);
    if ($slave) {
        $Report->set_Message("Slave log");
        $s_Conn->slave_log($Report);
    }
}

my %MS_Status;
if ( $use_host . $m_db ne $host . $dbase ) {
    %MS_Status = %{ get_MasterSlave_Status( -master => $m_host, -dbase => $dbase, -slave => $s_hosts ) };
}

# See what kind of backup we are doing
if ( $backup_type =~ /binlog/i ) {    # Just backup the binary logs
    $Report->set_Message("Bin Logs backup");
    bin_logs_backup();
}
elsif ( $backup_type =~ /dump/i ) {    # Performs a full dump of the database, backup and purge the binary logs
    $Report->set_Message("Full backup");
    full_backup();
}
elsif ( $backup_type =~ /purge/i ) {    # Backup and purge the binary logs
    $Report->set_Message("Purging bin logs...");
    purge_binlogs();
}
else {
    $Report->set_Error("Invalid backup type specified.");
    $Report->DESTROY();
}

##Get the Master Database Status After Backup
#Start Slave DB again
#Print Master and Slave Log Positions
if ( $s_host . $s_dbase eq $use_host . $m_db && $slave ) {
    $Report->set_Message("Master log");
    $m_Conn->master_log($Report);
    $Report->set_Message("Slave log");
    $s_Conn->slave_log($Report);

    $s_Conn->start_slave($Report);
    sleep(1);
    if ( $s_Conn->is_slave_running($Report) ) {
        $Report->set_Message("Slave is running again");
    }
    else {
        $Report->set_Error("Slave is not running, check and make sure that it works fine");
    }
}
else {
    $Report->set_Message("Master log");
    $m_Conn->master_log($Report);
    if ($slave) {
        $Report->set_Message("Slave log");

        $s_Conn->slave_log($Report);
    }
    if ($lock_master) {
        $m_Conn->unlock_tables($Report);
    }

}

$Report->completed();
$Report->DESTROY();
$m_Conn->disconnect();

exit;

############################
# Perform binary log backups
############################
sub bin_logs_backup {
#######################
    # Get information on the binary logs
    my @full_master_logs = @{ get_bin_logs_info() };
    my ($index_file) = $full_master_logs[0] =~ /(.+)\.\d+$/;
    $index_file .= ".index";

    # Copy the binary logs
    $Report->set_Detail("Backing up the binary logs (@{[date_time()]})...");
    my $cmd = "cp $index_file " . join( " ", @full_master_logs ) . " $local_dump_dir";
    $Report->set_Detail($cmd);
    my $feedback = try_system_command($cmd);
    $Report->set_Detail($feedback);
    if ($feedback) {
        $Report->set_Error("ERROR: $feedback");
        return 0;
    }
    $Report->set_Detail("Binary logs backup completed. (@{[date_time()]}");
    return 1;
}

####################################
# Get information on the binary logs
#
# Return the location of the master logs
####################################
sub get_bin_logs_info {
#########################

    # Get information about the master binary logs
    $Report->set_Detail("Obtaining information on binary logs on master ($m_host:$m_dbase) (@{[date_time()]})...");
    my $sql = "SHOW MASTER LOGS";
    $Report->set_Detail("SQL: $sql");
    my $sth  = $m_Conn->query( -query            => $sql, -finish => 0 );
    my $info = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'AofH' );
    my @master_logs = map { $_->{Log_name} } @$info;
    $Report->set_Detail( "Found binary logs: \n" . join( "\n", @master_logs ) );

    # Find the location of the logs
    $Report->set_Detail("Retrieving datadir on master ($m_host:$m_dbase) (@{[date_time()]})...");
    $sql = "SHOW VARIABLES LIKE 'datadir'";
    $Report->set_Detail("SQL: $sql");
    $sth = $m_Conn->query( -query => $sql, -finish => 0 );
    my $datadir = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' )->{Value};

    $Report->set_Detail("datadir = $datadir");

    # See if the binary logs are there and readable
    $Report->set_Detail("Verifying binary logs are existing and readable (@{[date_time()]})...");

    my @full_master_logs;
    foreach my $log (@master_logs) {
        my $full_log = "$datadir/$log";
        if ( -f $full_log ) {
            unless ( -r $full_log ) {
                $Report->set_Error("Binary log $full_log is not readable by the current user.");
                $Report->DESTROY();
                exit;
            }
            push( @full_master_logs, $full_log );
        }
        else {
            $Report->set_Error("Binary log $full_log not found.");
            $Report->DESTROY();
            exit;
        }
    }

    return \@full_master_logs;
}

#############################
# Performs full backup/dump
#############################
sub full_backup {
######################
    # Create the dump directory
    if ( $MS_Status{in_sync} ) {
        $Report->set_Detail("Master / Slave ** IN SYNC **");
        ($use_host) = split ',', $s_hosts;
    }
    else {
        $Report->set_Detail("Master / Slave ** NOT IN SYNC ** - using master for backup");
    }

    my @full_table_list = $m_Conn->DB_tables();

    my $fback;
## Establish list of tables to back up (indicated list, indicated exclusions or all tables)
    my @table_list;
    if ($tables) {
        @table_list = split ',', $tables;    ### start out with specified tables or
    }
    elsif ($ignored_tables) {
        foreach my $table (@full_table_list) {
            unless ( grep /^\b*$table\b*$/, @ignore ) { push( @table_list, $table ); }
        }
    }
    elsif ($core) {
        @table_list = SDB::DB_Model->get_tables( -dbc => $m_Conn );
        Message( "Only backing up Core " . int(@table_list) . ' tables' );
    }
    else { @table_list = @full_table_list; }

    $Report->set_Message( "Found " . int(@full_table_list) . " tables..." );

    $Report->set_Detail( "Backing up:\n" . join "\n", @table_list );

    ## replace tags in path is supplied ##

    $Report->set_Detail("Dumping to Directory: $path");
    $Report->set_Detail("using start_index of $start_index)");
    $Report->set_Detail("stopping at $end_index") if $end_index;

    my $char = 'n';
    if ( !$confirm ) {
        $char = Prompt_Input( 'char', 'Continue (y or n) ? ' );
    }
    unless ( $char =~ /^y/i || $confirm ) { Message("Aborted"); $m_Conn->disconnect(); exit; }

    my $dump_options = qq{--opt -all -q --quote_names};
    my $options      = qq{-u $user --password="$password" -h $use_host};

    if ( $type =~ /xml/ ) { $options .= qq{ --xml} }
    if ($condition) { $options .= qq{ --where "$condition"} }

    my $fake_options = $options;
    $fake_options =~ s/--password=\"\S+\"/--password=\"\*\*\*\"/;

    $Report->set_Detail("Archiving Data for each table separately");

    my $feedback;
    my $tables_backed_up = 0;
    
    try_system_command("rm $path/dump.log");  ### reset ##
    foreach my $table (@table_list) {

        ## Dump create table statement ##
        $Report->set_Detail(qq{$mysql_dir/mysqldump $fake_options $dump_options --no-data $m_db $table > '$path/$table.sql'});
        $feedback = &try_system_command(qq{$mysql_dir/mysqldump $options $dump_options --no-data $m_db $table > '$path/$table.sql'});
        $Report->set_Detail($feedback);

        $Report->set_Detail("$table structure regenerated");
        if ($structure) {next}    ## no more to do if only dumping structure ##

        my ($primary_field) = $m_Conn->get_field_info( -table => $table, -type => 'Primary' );
        my $query = "SELECT * FROM $table";
        $query .= " ORDER BY $primary_field" if $primary_field;
        if ($condition) { $query .= " WHERE $condition"; }

        if ( $type =~ /xml/ ) {
            ## use mysqldump for XML output ##
            $Report->set_Detail(qq{$mysql_dir/mysqldump $fake_options $dump_options $m_db $table > '$path/$table.xml'});
            $feedback = &try_system_command(qq{$mysql_dir/mysqldump $options $dump_options $m_db $table > '$path/$table.xml'});
            $Report->set_Detail($feedback);
        }
        elsif ( defined %Split_Records->{$table} ) {
            #### Special handling for very LARGE tables.. (separate into multiple files)...####
            my $files = &split_dump( -table => $table, -limit => $max_records, -query => $query, -start_index => $start_index, -end_index => $end_index );
            $Report->set_Detail("** Saved $table into $files files **");
        }
        
        else {
            ### standard backup ####
            if ( $type eq 'sql' ) { $type = 'txt' }    ## conflicts with structure type extension ##

            my $command;
            my $hostname = try_system_command('hostname');
            if ( $hostname =~ /\b$use_host/ ) {
                ## this is more efficient, but only works if the host is local ##
                if ( -e "$path/$table.$type" ) {

                    try_system_command("rm $path/$table.$type");
                }
                unless ( grep /^\b*$table\b*$/, @no_records ) {
                    $command = qq{$mysql_dir/mysql $options $m_db -e "$query INTO OUTFILE '$path/$table.$type'" >> $path/dump.log };
                    $Report->set_Detail(qq{$mysql_dir/mysql $fake_options $m_db -e "$query INTO OUTFILE '$path/$table.$type'" >> $path/dump.log});
                    $feedback = &try_system_command($command);
                }
            }
            else {
                if ( -e "$path/$table.$type" ) {
                    try_system_command("rm $path/$table.$type");
                }
                unless ( grep /^\b*$table\b*$/, @no_records ) {
                    $command = qq{$mysql_dir/mysql $options $m_db -e "$query" > '$path/$table.$type'};
                    $Report->set_Detail(qq{$mysql_dir/mysql $fake_options $m_db -e "$query" > '$path/$table.$type'});
                    $feedback = &try_system_command($command);
                }
                ## slower, but this works if mysql daemon is on a different volume, however big table like Clone_Sequence can crash server##
                #$command = qq{$mysql_dir/mysql $options $m_db -e "SET NAMES latin1; $query" > $path/$table.$type};
                #$Report->set_Detail(qq{$mysql_dir/mysql $fake_options $m_db -e "$query" > $path/$table.$type});
                ## only for > $path/$table.$type
                #my $q_file = "$path/$table.$type";
                #substitute_NULL($q_file);
            }

            $Report->set_Detail($feedback);
        }
        $tables_backed_up++;
        $Report->succeeded();
    }
    if ($routine)         { backup_stored_procedure($path) }
    if ($opt_finish_file) { try_system_command("touch $path/backup.finished.txt") }

    $Report->set_Detail( "Database '$dbase' backed-up on " . &date_time() . " to $path" );
    $Report->set_Detail("Number of tables backed-up: $tables_backed_up");
    $Report->set_Message( "Database '$dbase' backed-up on " . &date_time() . " to $path" );
    $Report->set_Message("Number of tables backed-up: $tables_backed_up");
    purge_binlogs($local_dump_dir) if $purge;
    return;
}

#############################
# Create the dump directory
#
# Returns the new dump dir created
#############################
sub create_dump_dir {
#######################
    my ( $today, $nowtime ) = split ' ', &date_time;
    my ( $hour,  $minute )  = split ":", $nowtime;

    $time_request ||= $hour . ":" . $minute;

    # Create the dump directory
    print "\n>>Creating dump directory ($m_host: $today $nowtime...)\n";
    $Report->set_Detail("Creating dump directory ($m_host: $today $nowtime)...");
    my $dir;

    if ( $backup_type =~ /binlog|purge/i ) {
        $dir = "$Dump_dir/$m_host/$m_dbase/$today/$nowtime-binlog";
    }
    elsif ( $backup_type =~ /dump/i ) {
        $dir = "$Dump_dir/$m_host/$m_dbase/$today/$time_request";
    }

    #    my $cmd = "mkdir -m 777 -p $dir";   ## requires open permission so mysql can write to it..
    #    print ">>Trying '$cmd'...\n";
    $Report->set_Detail("Trying create_dir(-path=>$Dump_dir,-mode=>777,-subdirectory=>\"$m_host/$m_dbase/$today/$time_request\")");
    create_dir( -path => $Dump_dir, -mode => 777, -subdirectory => "$m_host/$m_dbase/$today/$time_request", -debug => 1 );    ###try_system_command($cmd);

    if ( -e "$Dump_dir/$m_host/$m_dbase/$today/$time_request" ) {
        ## ok ##
    }
    else {
        my $feedback = "Directory $Dump_dir/$m_host/$m_dbase/$today/$time_request could not be created\n";
        $Report->set_Error("ERROR: $feedback");
        exit;
    }

    return $dir;
}

#############################
# Purge the binary logs
#############################
sub purge_binlogs {
#####################
    my $dump_dir = shift;

    # Lock all tables in the master to read lock
    print "\n>>Acquiring read locks on all tables of the master ($m_host:$m_dbase) (@{[date_time()]})...\n";
    $Report->set_Detail("Acquiring read locks on all tables of the master ($m_host:$m_dbase) (@{[date_time()]})...");
    my $sql = "FLUSH TABLES WITH READ LOCK";
    my ( $arg1, $arg2, $arg3 ) = $m_Conn->execute_command( -command => $sql );
    unless ( $arg3 =~ /success/i ) {
        print "ERROR: Failed to acquire read locks. ($arg3)\n";
        $Report->set_Error("Failed to acquire read locks. ($arg3)");
        return;
    }

    my $purge = $MS_Status{in_sync};

    # Now purge the binary log if OK
    if ($purge) {

        # First backup the binary log
        my $ok = bin_logs_backup($dump_dir);
        if ($ok) {    # If backup OK then delete the logs
            eval {

                # First stop the slaves
                foreach my $slave ( split /,/, $s_hosts ) {
                    $sql = "STOP SLAVE";
                    print ">Stopping slave '$slave' (@{[date_time()]})...\n";
                    $Report->set_Detail("Stopping slave '$slave' (@{[date_time()]})...");
                    ( $arg1, $arg2, $arg3 ) = $MS_Status{$slave}{dbc}->execute_command( -command => $sql );
                    die( "ERROR: Failed to stop slave '$slave'. ($arg3)\n", $Report->set_Error("Failed to stop slave '$slave'. ($arg3)"), $Report->DESTROY() )
                        unless ( $arg3 =~ /success/i );    # As long as one slave failed to stop then we should not purge the binary logs
                }

                # Purge binary logs
                my $purge_succeed;
                print "\n>>Purging binary logs of the master ($m_host:$m_dbase) (@{[date_time()]})...\n";
                set_Detail("Purging binary logs of the master ($m_host:$m_dbase) (@{[date_time()]})...");
                $sql = "RESET MASTER";
                ( $arg1, $arg2, $arg3 ) = $m_Conn->execute_command( -command => $sql );
                if ( $arg3 =~ /success/i ) {
                    $purge_succeed = 1;
                }
                else {
                    $purge_succeed = 0;
                    print "ERROR: Failed to purge binary logs. ($arg3)\n";
                    $Report->set_Error("Failed to purge binary logs. ($arg3)");
                }

                # Reset slave if purge succeeded
                if ($purge_succeed) {

                    # Get the status of the master
                    print "\n>>Obtaining status of the master ($m_host:$m_dbase) after the purge (@{[date_time()]})...\n";
                    my $sql             = "SHOW MASTER STATUS";
                    my $sth             = $m_Conn->query( -query => $sql, -finish => 0 );
                    my $new_master_info = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );

                    my ( $new_m_file, $new_m_position ) = @$new_master_info{ ( 'File', 'Position' ) };
                    print "\n>>Attempting to reset binary log file '$new_m_file' on slaves (@{[date_time()]})...\n";

                    # Now need to reset the slaves as well.
                    foreach my $slave ( split /,/, $s_hosts ) {

                        # Reset binary log info on slave
                        $sql = "CHANGE MASTER TO MASTER_LOG_FILE='$new_m_file', MASTER_LOG_POS=$new_m_position";
                        print ">Resetting '$slave' (@{[date_time()]})...\n";
                        ( $arg1, $arg2, $arg3 ) = $MS_Status{$slave}{dbc}->execute_command( -command => $sql );
                        if ( $arg3 =~ /success/i ) {

                            # Restart slave
                            $sql = "START SLAVE";
                            print ">Starting '$slave' (@{[date_time()]})...\n";
                            ( $arg1, $arg2, $arg3 ) = $MS_Status{$slave}{dbc}->execute_command( -command => $sql );
                            print "ERROR: Failed to start slave '$slave'. ($arg3)\n" unless ( $arg3 =~ /success/i );
                            $Report->set_Error("Failed to start slave '$slave'. ($arg3)");
                        }
                        else {
                            print "ERROR: Failed to reset slave '$slave'. ($arg3)\n";
                            $Report->set_Error("Failed to reset slave '$slave'. ($arg3)");
                        }
                    }
                }
                else {    # If purge not succeed we still need to restart the slaves
                    foreach my $slave ( split /,/, $s_hosts ) {

                        # Restart slave
                        $sql = "START SLAVE";
                        print ">Starting '$slave' (@{[date_time()]})...\n";
                        ( $arg1, $arg2, $arg3 ) = $MS_Status{$slave}{dbc}->execute_command( -command => $sql );
                        print "ERROR: Failed to start slave '$slave'. ($arg3)\n";
                        $Report->set_Error("Failed to start slave '$slave'. ($arg3)");
                    }
                }
            };
            print $@ if $@;
        }
        else {
            print "ERROR: Failed to backup the binary logs. Binary logs will NOT be purged.\n";
            $Report->set_Error("Failed to backup the binary logs. Binary logs will NOT be purged.");
            $purge = 0;
        }
    }

    # Unlock tables of the master database
    print "\n>>Unlocking all tables of the master ($m_host:$m_dbase) (@{[date_time()]})...\n";
    $sql = "UNLOCK TABLES";
    ( $arg1, $arg2, $arg3 ) = $m_Conn->execute_command( -command => $sql );
    unless ( $arg3 =~ /success/i ) {
        print "ERROR: Failed to unlock tables. ($arg3)\n";
        $Report->set_Error("Failed to unlock tables. ($arg3)");
        return;
    }

    # Close all slave connections
    foreach my $slave ( split /,/, $s_hosts ) {
        $MS_Status{$slave}{dbc}->dbh()->disconnect();
    }

    return $purge;
}

sub backup_stored_procedure {

    my $path = shift;

    my $options_sp = qq{-u $user --password='$password' -h $host --routines --no-create-info --no-data --no-create-db --skip-opt};

    create_dir( -path => $path, -mode => 777, -subdirectory => "stored_procedure", -debug => 1 );

    $Report->set_Detail(qq{mysql $options_sp $dbase > $path/stored_procedure/stored_procedure.sql \n});

    my $feedback_busp = &try_system_command(qq{mysqldump $options_sp $dbase > $path/stored_procedure/stored_procedure.sql});

    $Report->set_Detail($feedback_busp);

    unless ($feedback_busp) {

        print "\n>>Stored procedures were getting dumped\n";

    }
}
##############################
sub get_MasterSlave_Status {
    ##############################
    my %args    = &filter_input( \@_ );
    my $m_host  = $args{-master};
    my $s_hosts = $args{-slave};
    my $m_dbase = $args{-dbase};

    my %Info;

    # Get the status of the master
    print "\n>>Obtaining status of the master ($m_host:$m_dbase) (@{[date_time()]})...\n";
    $Report->set_Detail("Obtaining status of the master ($m_host:$m_dbase) (@{[date_time()]})...");
    my $sql         = "SHOW MASTER STATUS";
    my $sth         = $m_Conn->query( -query => $sql, -finish => 0 );
    my $master_info = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );

    my ( $m_file, $m_position ) = @$master_info{ ( 'File', 'Position' ) };
    print ">>Found master binary log file '$m_file' with position '$m_position'\n";

    $MS_Status{master}{file}     = $m_file;
    $MS_Status{master}{position} = $m_position;

    # Get the status of the slaves
    my %slaves_info;
    my %slaves_conn;
    foreach my $slave ( split /,/, $s_hosts ) {
        print "\n>>Obtaining status of the slave '$slave' (@{[date_time()]})...\n";

        # Connect to the slave host
        my $s_Conn = SDB::DBIO->new();
        my $s_dbh = $s_Conn->connect( -host => $slave, -dbase => $m_dbase, -user => $user );    # Note that '$m_dbase' is NOT a typo

        unless ($s_dbh) {
            print "\nERROR: Failed connecting slave database - " . $DBI::errstr . ".\n";
            $Report->set_Error( "Failed connecting slave database - " . $DBI::errstr );
            return;
        }

        $sql = "SHOW SLAVE STATUS";
        $sth = $s_Conn->query( -query => $sql, -finish => 0 );
        my $slave_info = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );

        $slaves_info{$slave}    = $slave_info;
        $slaves_conn{$slave}    = $s_Conn;
        $MS_Status{$slave}{dbc} = $s_Conn;

    }

    my $purge = 1;

    # Compare these info to the slaves
    foreach my $slave ( sort keys %slaves_info ) {
        my $slave_info = $slaves_info{$slave};
        my ( $s_file, $s_position, $last_error, $last_error_num, $s_dbase ) = @$slave_info{ ('Master_Log_File'), ('Read_Master_Log_Pos'), ('Last_error'), ('Last_errno'), ('Replicate_Do_DB') };
        $MS_Status{$slave}{position}   = $s_position;
        $MS_Status{$slave}{file}       = $s_file;
        $MS_Status{$slave}{errors}     = $last_error;
        $MS_Status{$slave}{last_error} = $last_error_num;
        $MS_Status{$slave}{dbase}      = $s_dbase;

        if ( $s_file eq $m_file ) {
            print ">>Verifying status of I/O thread on slave '$slave' for binary log '$s_file'...\n";
            $Report->set_Detail("Verifying status of I/O thread on slave '$slave' for binary log '$s_file'...");

            if ( $s_dbase ne $m_dbase ) {
                print "Slave database ($s_dbase) differs from database of interest ($m_dbase) ... using original\n";
                $purge = 0;
            }
            elsif ( $last_error || $last_error_num ) {

                # Error found in slave - do not purge binary log yet
                print ">ERROR: Error found in slave '$slave' ($last_error_num: '$last_error'). Binary log files will not be purged.\n";
                $Report->set_Error("Error found in slave '$slave' ($last_error_num: '$last_error'). Binary log files will not be purged.");
                $purge = 0;
            }
            elsif ( $s_position == $m_position ) {

                # OK
                print "Slave '$slave' OK (Master position: $m_position; Slave position: $s_position; $m_host:$m_dbase = $slave:$s_dbase).\n";
            }
            else {

                # Slave's I/O thread hasn't caught up with master
                print ">WARNING: I/O thread of slave '$slave' has not caught up with master yet (Master position: $m_position; Slave position: $s_position). Binary log files will not be purged.\n";
                $Report->set_Warning("WARNING: I/O thread of slave '$slave' has not caught up with master yet (Master position: $m_position; Slave position: $s_position). Binary log files will not be purged.");
                $purge = 0;
            }
        }
        else {

            # Slave's I/O thread hasn't caught up with master
            print ">WARNING: I/O thread of slave '$slave' has not caught up with master yet (Master log: $m_file; Master log on slave: $s_file). Binary log files will not be purged.\n";
            $Report->set_Warning("WARNING: I/O thread of slave '$slave' has not caught up with master yet (Master log: $m_file; Master log on slave: $s_file). Binary log files will not be purged.");
            $purge = 0;
        }
    }

    $Info{in_sync} = $purge;

    return \%Info;
}

##########
#
# Returns host and database for slave if it seems to match the current master
# (otherwise return the master host and database)
#
########################
sub check_replication {
########################
    my $host  = shift;
    my $dbase = shift;
    my $slave = shift;

    my ( $slave_host, $slave_db );

    if ( $slave =~ /:/ ) {
        ( $slave_host, $slave_db ) = split ":", $slave;
    }
    elsif ($slave) {
        $slave_host = $slave;
        $slave_db   = $dbase;
    }
    else { return ( $host, $dbase ) }    ## no slave indicated ##

    my $bindir = $FindBin::RealBin;
    $Report->set_Message("Checking the replication status...");
    my $errors = try_system_command("$bindir/check_replication.pl -M $host:$dbase -S $slave_host:$slave_db -q -u $user -p $password -l");
    if ( $errors !~ /Error: None/ ) {
        $Report->set_Error("Replication error: $errors");
        $Report->set_Message("Slave is NOT replicating master, using Master ($host,$dbase)");
        return ( $host, $dbase );        ## difference between master and slave - use master instead ##
    }
    else {
        $Report->set_Message("Replication is in good shape... using Slave ($slave_host:$slave_db)");
        return ( $slave_host, $slave_db );
    }
}

######################
sub print_help_info {
######################
    print <<HELP;
File:  backup_DB
##################
Options:
##########
    -dbase                 database specification (Mandatory)
	-slave (host)          replication database specification (optional - tries to use this server if it is up-to-date) 
	    -T (table)             specify specific list of tables (defaults to ALL tables)
		-X (table)             specify tables NOT to back up... (exceptions) 
		    -S                     just backup the database STRUCTURE (generates CREATE TABLE command)
			-t                     specify the timestamp to use (format = "yyyy-mm-dd.HH:MM")
			    -path (path)           specify path for dump directory
				-user (user)           specify user to login as
				    -password (password)   specify password for user
					-host (host)           defaults to $Defaults{mySQL_HOST} 
    -condition (condition) optional condition for dumping eg. (-w "Employee_Name='tom'")
	-type (extension)      csv/txt (LOAD INFILE) or sql (INSERT statements) or xml 
	    -limit num             Number of records per group when splitting (default to 100,000 records)
		-time timestamp        indicate timestamp to use for directory (over-rides current time (and date if provided) eg -time "2006-01-01 14:00" 

## Types of backup: ##
										-dump                  Full data dump
										-binlog                Just dump binary logs
										-purge                 Just purge binary logs

Example:  
###########

backup_RDB.pl -dbase sequence -T Plate    (backup Plate table - defaults to production lab database)

backup_RDB.pl -dbase mydatabase -path /home/mydir/backups/ -host lims01 -user viewer
										
HELP
    return;

}

######################
sub substitute_NULL {
######################
    my $file     = shift;
    my $sec_file = $file . 'temp';

    my $command = "cat $file ";
    $command .= "| sed '" . 's/\tNULL\t/\t\\\N\t/g' . "' ";
    $command .= "| sed '" . 's/^NULL\t/\\\N\t/g' . "' ";
    $command .= "| sed '" . 's/\tNULL$/\t\\\N/g' . "' ";
    $command .= "| sed '" . 's/\tNULL\t/\t\\\N\t/g' . "' ";
    $command .= " > $sec_file";
    my $ok = try_system_command( $command, -verbose => 1 );

    my $delete_command  = "rm  $file";
    my $ok              = try_system_command( $delete_command, -verbose => 1 );
    my $replace_command = " mv  $sec_file $file";
    my $ok              = try_system_command( $replace_command, -verbose => 1 );
    return;
}

