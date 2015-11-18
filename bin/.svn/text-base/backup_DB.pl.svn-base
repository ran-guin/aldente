#!/usr/local/bin/perl

################################################################################
#
# backup_DB
#
# This program generates Backup files for the SQL Database
#
################################################################################
################################################################################
# $Id: backup_DB.pl,v 1.26 2004/12/09 17:41:23 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.26 $
#     CVS Date: $Date: 2004/12/09 17:41:23 $
################################################################################
use strict;
use CGI ':standard';
use DBI;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use File::stat;
use Statistics::Descriptive;

use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Process_Monitor;

use alDente::SDB_Defaults;    ### get directories only...
use alDente::Employee;

use LampLite::Config;
##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_dbase $opt_user $opt_password $opt_host $opt_type $opt_slave $opt_T $opt_X $opt_path $opt_limit $opt_S $opt_time $opt_mysql_dir $opt_condition $opt_start_index $opt_end_index $opt_confirm);
use vars qw($testing $Dump_dir %Defaults $bin_dir);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
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
    'path=s',       => \$opt_path,
    'limit=s',      => \$opt_limit,
    'S',            => \$opt_S,
    'time=s'        => \$opt_time,
    'mysql_dir=s'   => \$opt_mysql_dir,
    'start_index=s' => \$opt_start_index,
    'end_index=s'   => \$opt_end_index,
    'confirm'       => \$opt_confirm,
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

unless ($dbase) { &usage(); exit; }

my $Setup = LampLite::Config->new( -initialize=>$FindBin::RealBin . '/../conf/custom.cfg');
my $Config = $Setup->{config};

my $Dump_dir = $Config->{dumps_data_dir};
$host ||= $Config->{mySQL_HOST};

my $hostname = try_system_command('hostname');
my $localhost = ($hostname eq $host);

### Get Optional input ###
my $tables      = $opt_T         || '';
my $exclusions  = $opt_X         || '';
my $structure   = $opt_S;
my $path        = $opt_path      || "$Dump_dir/<HOST>/<DATABASE>/<DATE>/<TIME>";    ## default dump structure ##
my $max_records = $opt_limit     || 100000;
my $mysql_dir   = $opt_mysql_dir || '/usr/bin/';
my $time_request = $opt_time;
my $condition    = $opt_condition;

# $path = "/home/aldente/private/dumps/<HOST>/<DATABASE>/<DATE>/<TIME>";

my %Split_Records;
my $min_size = 10;                                                                                         ### minimum size of dump file (take into account header, lock, unlock.. )

############ Construct Report object for writing to log files ###########
my $Report = Process_Monitor->new();

# $Split_Records{'Clone_Sequence'} = $max_records;   ### maximum of 400,000 records in one file...

### Set time stamp ###
my ( $today, $nowtime ) = split ' ', &date_time;

if ( $time_request =~ /[\s\.]/ ) { ( $today, $nowtime ) = split /[\s\.]/, $time_request; }
elsif ($time_request) { $nowtime = $time_request; }

if ( $nowtime =~ /(\d\d:\d\d):\d\d/ ) { $nowtime = $1 }    ## trim off seconds from time ##

unless ($host) { $host = Prompt_Input( 'string', 'Which Database Host ?: ' ) }

my ( $source_host, $source_db ) = &check_replication( $host, $dbase, $slave );

$Report->set_Message("Backup requested: $today.$nowtime");

############# Options for Backing UP ###########
my @ignore = split ',', $exclusions;
my $ignored_tables = scalar(@ignore);

unless ($user)     { $user     = Prompt_Input( 'string',   'Database Username >>' ) }
unless ($password) { $password = Prompt_Input( 'password', 'Password >>' ) }

## connect to source database ##
my $dbc = new SDB::DBIO( -dbase => $source_db, -user => $user, -password => $password, -host => $source_host, -connect => 1 );

my @full_table_list = $dbc->DB_tables();
$dbc->disconnect();

my $feedback;
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
else { @table_list = @full_table_list; }

$Report->set_Detail( "Tables to back up:\n***************\n" . join "\n", @table_list . "\n" );

## replace tags in path is supplied ##
$path =~ s /<HOST>/$source_host/g;
$path =~ s /<DATABASE>/$source_db/g;
$path =~ s /<DATE>/$today/g;
$path =~ s /<TIME>/$nowtime/g;

$Report->set_Message("Dumping to Directory: $path");
$Report->set_Message("(using start_index of $start_index)") if $start_index > 1;
$Report->set_Message("(stopping at $end_index)")            if $end_index;

unless ( -e "$path" ) {
    my $command = qq{mkdir -p $path -m 777};
    $Report->set_Detail($command);
    $feedback = try_system_command($command);
    $Report->set_Detail($feedback);
}
unless ( -e "$path" ) {
    $Report->set_Error("Could not create directory: $path");
    $Report->DESTROY();
    exit;
}

my $char = 'n';
if ( !$confirm ) {
    $char = Prompt_Input( 'char', 'Continue (y or n) ? ' );
}

unless ( $char =~ /^y/i || $confirm ) {
    $Report->set_Error("Aborted");
    $dbc->disconnect();
    exit;
}

my $dump_options = qq{--opt -all -q --quote_names};
my $options      = qq{-u $user --password="$password" -h $source_host};

if ( $type =~ /xml/ ) { $options .= qq{ --xml} }
if ($condition) { $options .= qq{ --where "$condition"} }

#my $dump_command = qq{$mysql_dir/mysqldump $options};

#unless (-e "$path/$source_db.$today/") {
#    try_system_command(qq{mkdir $path/$source_db.$today});
#}

$Report->set_Message("Archiving Data for each table separately");
my $tables_backed_up = 0;
foreach my $table (@table_list) {

    ## Dump create table statement ##
    &try_system_command(qq{$mysql_dir/mysqldump $options $dump_options --no-data $source_db $table > '$path/$table.sql'});
    $Report->set_Detail("$table structure");
    if ($structure) {next}    ## no more to do if only dumping structure ##

    my $query = "SELECT * FROM $table";
    if ($condition) { $query .= " WHERE $condition"; }

    if ( $type =~ /xml/ ) {
        ## use mysqldump for XML output ##
        &try_system_command(qq{$mysql_dir/mysqldump $options $dump_options $source_db $table > '$path/$table.xml'});
    }
    elsif ( defined %Split_Records->{$table} ) {
        #### Special handling for very LARGE tables.. (separate into multiple files)...####
        my $files = &split_dump( -table => $table, -limit => $max_records, -query => $query, -start_index => $start_index, -end_index => $end_index );
        $Report->set_Detail("** Saved $table into $files files **");
    }
    else {    ### standard backup ####
        if ( $type eq 'sql' ) { $type = 'txt' }    ## conflicts with structure type extension ##

        my $command;
        if ($localhost) {
            $command = qq{$mysql_dir/mysql $options $source_db -e "$query INTO OUTFILE '$path/$table.$type'"};
        }
        else {
            $command = qq{$mysql_dir/mysql $options $source_db -e "$query" > '$path/$table.$type'"};
        }
        
        $Report->set_Detail("EXEC: $command");
        $feedback = &try_system_command($command);
        $Report->set_Detail($feedback);
    }
    $tables_backed_up++;
    $Report->succeeded();
}

$Report->set_Message( "Database: $dbase backed up. (" . &date_time() . ")" );
$Report->set_Message("Number of tables backed up: $tables_backed_up");
$Report->set_Message("Directory: $path");
$Report->completed();
$Report->DESTROY();
exit;

######################
#
# Usage instructions #
#
#
#############
sub usage {
#############
    print <<HELP;
File:  backup_DB
##################
Options:
##########
-dbase                 database specification (Mandatory)
-slave (host:dbase)    replication database specification (optional - tries to use this server if it is up-to-date) 
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

Example:  
###########

           backup_DB.pl -dbase sequence -T Plate    (backup Plate table - defaults to production lab database)

	   backup_DB.pl -dbase mydatabase -P /home/mydir/backups/ -h lims01 -u viewer -p viewer

HELP
    return;
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
    }
    else { return ( $host, $dbase ) }    ## no slave indicated ##

    my $bindir = $FindBin::RealBin;
    my $errors = try_system_command("$bindir/check_replication.pl -M $host:$dbase -S $slave_host:$slave_db -q -u $user -p $password");
    if ($errors) {
        $Report->set_Error("** Replication error: $errors\n** Retrieving data from master");
        return ( $host, $dbase );        ## difference between master and slave - use master instead ##
    }
    return ( $slave_host, $slave_db );
}

##########################
# Saves dump to a number of indexed files (rather than one very large file)
#
# saves in batches of $records records
#
##################
sub split_dump {
##################
    my %args        = &filter_input( \@_, -args => 'table,limit,query' );
    my $table       = $args{-table};
    my $max_records = $args{-limit};
    my $query       = $args{-query};
    my $start_index = $args{-start_index} || 1;
    my $end_index   = $args{-end_index} || 100;                             ## set to 100 to prevent runaway process if some sort of error (may be overridden)

    ## indexing files only available when directing to individual files ##
    my $index = $start_index;

    my $start = ( $index - 1 ) * $max_records;
    my $stop = $index * ($max_records);
    $Report->set_Detail("Split dump for $table");

    while ($index) {
        $Report->set_Detail(".$index");

        $Report->set_Detail("Records $start -> $stop");
        
        my $command;
        if ($localhost) {
            $command = qq{$mysql_dir/mysql $options $source_db -e "$query $condition LIMIT $start,$stop INTO OUTFILE '$path/$table.$type.$index'"};
        }
        else {
            $command = qq{$mysql_dir/mysql $options $source_db -e "$query $condition LIMIT $start,$stop" > '$path/$table.$type.$index'"};
        }
        
        $Report->set_Detail($command);
        $feedback = &try_system_command($command);
        $Report->set_Detail($feedback);

        $start += $max_records;
        $stop  += $max_records;

        my $stats;
        sleep 1;
        if ( -e "$path/$table.$type.$index" ) {
            $stats = stat("$path/$table.$type.$index");
        }
        else {
            $Report->set_Warning("Cannot find '$path/$table.$type.$index' ???");
            $index++;
            if ( $index >= $end_index ) {last}
            next;
        }

        if ( $end_index == $index ) {last}    ## quit if this is specified as a termination point

        $index++;

        ## check for empty file - if found, erase and end loop
        my $size = $stats->size;
        if ( $size > $min_size ) {
            $Report->set_Detail( "(" . number($size) . " bytes)" );
        }
        else {
            ## finished - last file created was too small (no data)... ##
            unlink("$path/$table.$type.$index");
            $index--;
            last;
        }
    }
    return $index - 1;
}
