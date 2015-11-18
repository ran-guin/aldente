#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

#################################################################################
# restore_DB
#
# This program restores Database info from backups.
#
#
# Note: some older backups are stored in a different format.
# (To extract these please use an older version of restore_DB.pl)
#
#
################################################################################
################################################################################
# $Id: restore_DB.pl,v 1.39 2004/11/29 21:56:12 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.39 $
#     CVS Date: $Date: 2004/11/29 21:56:12 $
################################################################################
use CGI ':standard';
use DBI;
use Data::Dumper;
use Shell qw (ls);
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::DBIO;

use SDB::CustomSettings;
use alDente::SDB_Defaults;
use SDB::Installation;

use LampLite::Config;

use strict;

use vars
    qw($opt_root $opt_from $opt_date $opt_dbase $opt_time $opt_table $opt_T $opt_structure $opt_S $opt_force $opt_path $opt_user $opt_password $opt_X $opt_update $opt_directory $opt_rebuild $opt_skip $opt_continue $opt_local $opt_log $opt_min_size $opt_max_size $opt_host $opt_slave $opt_confirm $opt_quiet $opt_routine);

use vars qw($testing $Dump_dir %Defaults %Configs);

#require "getopts.pl";
#&Getopts('f:d:D:T:t:v:RFP:u:p:X:aUl:rSe:I:C:Lm:M:');

use Getopt::Long;
Getopt::Long::Configure("no_ignore_case");

&GetOptions(
    'dbase=s'    => \$opt_dbase,
    'user=s'     => \$opt_user,
    'password=s' => \$opt_password,
    'host=s'     => \$opt_host,
    'rebuild'    => \$opt_rebuild,
    'X=s',       => \$opt_X,
    'continue=s' => \$opt_continue,
    'structure'  => \$opt_structure,
    'S'          => \$opt_S,
    'slave=s'    => \$opt_slave,
    'skip=s'     => \$opt_skip,

    #       'header=s'      => \$opt_header,
    'local=s',    => \$opt_local,
    'min_size=s'  => \$opt_min_size,
    'max_size=s'  => \$opt_max_size,
    'confirm'     => \$opt_confirm,
    'from=s'      => \$opt_from,
    'date=s'      => \$opt_date,
    'time=s'      => \$opt_time,
    'table=s'     => \$opt_table,
    'T=s'         => \$opt_T,
    'force'       => \$opt_force,
    'path=s'      => \$opt_path,
    'update'      => \$opt_update,
    'log'         => \$opt_log,
    'directory=s' => \$opt_directory,
    'quite'       => \$opt_quiet,
    'routine'     => \$opt_routine,
);

my @Large_Databases   = ('Clone_Sequence');
my @Raid_Hosts        = ('athena');                       ## list of machines that use RAID storage for large tables.
my $dbase             = $opt_dbase;
my $host              = $opt_host;
my $user              = $opt_user || 'super_cron_user';
my $password          = $opt_password || '';
my $remove_all_tables = $opt_rebuild;
my $exclusions        = $opt_X || '';
my $contin            = $opt_continue;
my $structure         = $opt_structure || $opt_S;
my $skip_records      = $opt_skip;
my $header;                                               # = $opt_header;         ## header lines in csv data files
my $local = $opt_local || '';                             ## switch to indicate local data files.
my $log = $opt_log;                                       ## log to cron summary
my $source_db;
my $min_size_limit = $opt_min_size || 0;                  ## only restore tables smaller than size_limit
my $max_size_limit = $opt_max_size || 0;
my $table_input    = $opt_table    || $opt_T;
my $quiet          = $opt_quiet;
my $routine        = $opt_routine;

my $source_host = $Defaults{mySQL_HOST};
my $target_host;                                          # = $Defaults{mySQL_HOST};

my $extension = 'txt';
if ($structure) { $extension = 'sql' }

#$extension = ".txt"; ##  if $extension =~ /csv/;

if ( $dbase && $user && $host ) {
    if ( $dbase =~ /([\w\-]*):([\w\-]*)/ ) {
        $target_host = $1;
        $dbase       = $2;
    }
    else {
        $target_host = $host;
    }

    if ($opt_from) {
        $source_db = $opt_from;
        if ( $source_db =~ /([\w\-]*):([\w\-]*)/ ) {
            $source_host = $1;
            $source_db   = $2;
        }
    }
    else {
        $source_db = $dbase;
    }
}
else {
    print <<HELP;
File:  restore_DB
####################
Options:
##########
-dbase                database specification (Mandatory)
-host                  -specify host by 'host:database' (Mandatory) (e.g. athena:sequence). Default to standard if no host specified. 
-user                  -specify mySQL user name 
-from                  restore from another database 
                      -specify host by 'host:database' (e.g. lims02:sequence). Default to standard if no host specified. 
-date (day)              specify date of retrieved version: (may enter: 'YYYY-MM-DD', 'MM-DD', or 'DD' (default = most recent version)
-time (time)             specify time of retrieved version: ('HH:MM');
-T                    load data only from a specific table...(does NOT regenerate structure)
-X                    exclude table from full list
-directory (dump_directory)  specify path for dump directory (path to look for the dbase.datestamp directories)
-path                 specify path for dump directories (defaults to ../dumps/<host>/<dbase>/)
-l (location)         specify location where the dump SQL files are found
-a                    auto-determine list of tables (from latest backup directory)
-u                    update ONLY (only restore tables that are MISSING from the target database, but are backed up)
-rebuild                    remove all tables from database
-I N                  ignore first N records (if loading from csv file)

(to save database use:  'backup_DB')
Examples:  
###########
To restore entire database:  restore_DB -dbase sequence -host lims02 -rebuild -directory <latest_dump_path>
to restore from another DB:  restore_DB -dbase seq01 -host lims01 -from sequence -rebuild 
to restore from ~1/2 hour ago:  restore_DB -dbase sequence -host lims02 -v 3    (3 means 3 versions ago - backed up every 10 minutes) 
to restore from the 15th:       restore_DB -dbase sequence -host lims02 -d 15    
to restore from midnight:       restore_DB -dbase sequence -host lims02 -t 00:00   
to restore the Employee table: restore_DB -dbase sequence -host lims02 -T Employee
to restore the Protocol table
(from the test database):      restore_DB -dbase limsdev02:seqdev -from sequence -host lims02 -T Protocol,Protocol_List 

to restore the Clone_Sequence structure: restore_DB -dbase sequence -host lims02 -structure Clone_Sequence

HELP
    exit;
}

my $login_file;
unless ($password) {
    $login_file = $FindBin::RealBin . "/../conf/mysql.login";
    
    $password = LampLite::Login::get_password( -host => $host, -user => $user, -file => $login_file, -method => 'grep' );
}

my $Config = LampLite::Config->new( -initialize=>$FindBin::RealBin . '/../conf/custom.cfg');
my $Report = Process_Monitor->new( -title => 'Restore_DB', -configs=>$Config->{config});

my @ignore = split ',', $exclusions;
push( @ignore, 'gs', 'General_Statistics' );    ### temporary tables to ignore...
my $ignored_tables = scalar(@ignore);

#####################################################################################################################

( my $today, my $time ) = &date_time();

my $pass = "-p";
if ($password) {
    $pass = "--password=$password";
}
else {
    $password = Prompt_Input( -prompt => "Password >>", -type => 'password' );
    $pass = "--password=$password";
}

my $dbc;
my $install;
if (! $opt_path ) {
    $Report->set_Detail("Connecting as '$user' to '$source_db' on '$source_host'");
    print "CONNECT...";
    $dbc = SDB::DBIO->new( -host => $source_host, -dbase => $source_db, -user => $user, -login_file=>$login_file, -connect => 1, -config=>$Config->{config});
    print "CONNECT " . $dbc->{connected};
    $install = new SDB::Installation( -dbc => $dbc, -simple => 1 );

print "CONFIGS:\n" . $dbc->config('dumps_data_dir');

    my ($user_id) = $dbc->config('user_id'); ## $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = 'Admin'" );

    my $mysql_dir = $dbc->config('mysql_dir');

#    print "U: $user_id.\n";
#    # include permissions
#    require alDente::Employee;

    my @current_tables = $dbc->DB_tables();    ## check current tables in source database to ensure Employee table exists.

    my $login_table;
    if ( ($login_table) = grep /^(Employee|User)$/, @current_tables ) {
        ## employee table found to enable use of administrator id ##
    }
    else {
        $Report->set_Message("Login Table does not exist - You will need to manually indicate the directory in which the files are stored (eg dump directory) [add '-directory <path>']");
        leave( -message => "Login table requires restoration - exact path required" );
    }
    print "Using login table: $login_table\n";
    
    my ($admin_id) = $dbc->Table_find( $login_table, "${login_table}_ID", "WHERE ${login_table}_Name = 'Admin'" );
    my $Model = $dbc->dynamic_require($login_table);
    print "Logging in using: $Model\n";
    
    my $eo = $Model->new( -dbc => $dbc, -id => $admin_id );

    $eo->define_User();                        ## loads variables required
    $Report->set_Detail("Using Admin User ($admin_id)");

}

my $mysql_command = qq{${mysql_dir}mysql -u $user $pass -h $target_host $dbase};

# dropping all tables (if opt_rebuild)
if ($remove_all_tables) {

    if ($opt_force) {
        $Report->set_Message("Execution forced - bypassing user validation check...");
    }
    else {
        $Report->set_Message("*** Warning - You are about to Delete the Entire $dbase Database !! ***");
        my $continue = Prompt_Input( 'text', ' Continue ? (yes/no)' );
        if ( $continue ne 'yes' ) { &leave( -message => "Aborting by choice", -no_log => 1 ); }    ## EXIT
    }
    my $drop_mysql_command = $mysql_command;
    $drop_mysql_command =~ s/ $dbase$//;                                                           ## leave out database specification when connecting

    my $command = qq{$drop_mysql_command -e 'drop database if exists $dbase;'};
    $Report->set_Detail(qq{$drop_mysql_command -e 'drop database $dbase;'});
    my $drop_feedback = try_system_command($command);
    chomp $drop_feedback;
    if ( $drop_feedback eq 'Warning: Using a password on the command line interface can be insecure.' ) {
        $drop_feedback = 0;                                                                        #Ignore warning
    }

    my $command = qq{$drop_mysql_command -e 'create database $dbase;'};
    $Report->set_Detail(qq{$drop_mysql_command -e 'create database $dbase;'});
    my $create_feedback = try_system_command($command);
    print $command;
    chomp $create_feedback;
    if ( $create_feedback eq 'Warning: Using a password on the command line interface can be insecure.' ) {
        $create_feedback = 0;                                                                      #Ignore warning
    }

    # If error out, exit
    if ( $drop_feedback || $create_feedback ) {
        $Report->set_Error("Failed to recreate $dbase \nDropping: $drop_feedback\nCreating: $create_feedback");
        ### Submit the cron hash before exit
        leave( -message => "Error rebuilding database" );                                          ## EXIT
    }
}

my $T_dbc = SDB::DBIO->new( -host => $target_host, -dbase => $dbase, -user => $user, -login_file=>$login_file, -connect => 1, -config=>$Config->{config});

my @original_table_list = $T_dbc->DB_tables();

my $update = 1 if $opt_update;
my $timestamp = $opt_time || qq{*};
my $datestamp = $opt_date || qq{*};
if ( $opt_time =~ /\s/ ) { ( $datestamp, $timestamp ) = split " ", $opt_time; }

my $path = $opt_path || $dbc->config('dumps_data_dir') . "/<HOST>/<DATABASE>";    ## default dump structure ##
$path =~ s /<HOST>/$source_host/g;
$path =~ s /<DATABASE>/$source_db/g;

#$Report->set_Message("Restoring $garget_host:$dbase, using Directory: $path");

my $subdirectory;                                                                ### find most recent timestamped directory (or as specified)

$Report->set_Detail("Time: $opt_time; Directory: $opt_directory;");

my $find_table_backup = 0;

if ($opt_directory) {
    if ( -d $opt_directory ) {
        $subdirectory = $opt_directory;
        $Report->set_Detail("Specified Backup: $subdirectory");
    }
    else {
        $Report->set_Error("Directory '$opt_directory' not found.");
        &leave( -message => "Directory not found - aborting" );
    }
}
else {
    $find_table_backup = 1;
}

my @full_table_list;

if ($table_input) {    ## list of tables
    @full_table_list = split /,/, $table_input;
}
else {
    my @tables;
    if ($subdirectory) {    # Get the list of tables from the SQL files in the subdirectory specified
        $Report->set_Message("Looking in $subdirectory..");
        my @files_found = glob("$subdirectory/*.$extension");
        my %Tlist;
        map {
            if (/(\w+)\.$extension/) { %Tlist->{$1} = 1; }
        } @files_found;
        @tables = sort keys %Tlist;
    }
    elsif ($dbc) {                  # Get the list of tables from the source database
        @tables = $dbc->DB_tables();
    }
    foreach my $this_table ( sort @tables ) {
        if ( $update && grep /^$this_table$/, @original_table_list ) {
            $Report->set_Warning("$this_table already exists");
            next;
        }                   ## only add to list if it is missing (if update switch used)
        else { push( @full_table_list, $this_table ) }
    }
}

my @tables;
if ($table_input) {
    @tables = @full_table_list;    ### start out with specified tables or
}
elsif ($ignored_tables) {
    foreach my $table (@full_table_list) {
        if ( grep /^\s*$table\s*$/, @ignore ) {
            $Report->set_Detail("Skipping $table...");
        }
        else {
            push( @tables, $table );
        }
    }
}

print "TABLES: @tables\n";

my $table_list = join( ",", @tables );
$Report->set_Detail("Tables: $table_list");
$Report->set_Message( "Restoring " . scalar(@tables) . " tables for " . $target_host . ":" . $dbase . ", using Directory: " . $path );
$Report->set_Message("** (continuing from $contin table)... **") if $contin;

if ($routine) {
    my $sproc_dir = find_subdirectory( "*/stored_procedure", $subdirectory );
    $Report->set_Detail(qq{mysql_command < $sproc_dir/stored_procedure.sql});
    my $feedback = &try_system_command(qq{$mysql_command < $sproc_dir/stored_procedure.sql});
    $Report->set_Detail($feedback);
}

if ( !$opt_force ) {
    Message("*********************************************************************************************");
    Message("*****   Warning: This will restore info in Above $dbase tables (from $extension files) !");
    Message("*********************************************************************************************");
    Message("$mysql_dir/mysql -u $user -p -h $target_host $dbase");

    my $continue = Prompt_Input( 'c', ' Continue ? (y/n)' );
    if ( !( $continue =~ /Y/i ) ) { &leave( -message => "Aborting by choice", -no_log => 1 ); }    ## EXIT
}

#If no latest back found then move on to the next table;
my $mysql_import;
if ( $extension =~ /(csv|txt)/ ) {
    $mysql_import = qq{$mysql_dir/mysqlimport --lock-tables -u $user $pass -h $target_host $dbase};
}
$Report->set_Detail(qq{mysql_dir/mysqlimport --lock-tables -u $user <pass> -h $target_host $dbase});

#$Report->set_Message("Restoring...");

my $feedback;

T: foreach my $table (@tables) {
    unless ($table) { next; }
    if ($contin) {
        if ( $table eq $contin ) { $contin = ''; }    ## clear continue variable ##
        else {
            $Report->set_Detail("Skipping $table..");
            next T;
        }
    }
    my $Tsubdir = find_subdirectory( $table, $subdirectory );

    my $options;
    my $header = $install->header_included( -dbc => $dbc, -file => "$Tsubdir/$table.txt", -table => $table ) if ( $dbc && !$structure );
    if ( $skip_records || $header ) {
        ## ignore lines if specified ##
        $Report->set_Detail("Skipping $skip_records records in files + $header header lines for table $table");
        my $skip = $skip_records || $header;
        if ($skip) {
            $options = "IGNORE $skip LINES";
        }
        else {
            $options = '';
        }
    }

    my $source_count = &count_records( $dbc,   $table, 1 );
    my $target_count = &count_records( $T_dbc, $table, 1 );

    $Report->set_Detail("$table records in SOURCE DB:\t$source_count");
    $Report->set_Detail("$table records BEFORE Restore:\t$target_count");

    if ( $max_size_limit && ( $source_count > $max_size_limit ) ) {
        ## skip large tables
        $Report->set_Detail("Skipping $table (> $max_size_limit records");
        next T;
    }
    elsif ( $min_size_limit && ( $source_count < $min_size_limit ) ) {
        ## skip smaller tables
        $Report->set_Detail("Skipping $table (< $min_size_limit records");
        next T;
    }

    ## restore table ##
    $Report->set_Detail("Re-Initialized $table table");
    try_system_command("sed -i -e 's/Warning: Using a password on the command line interface can be insecure.//' $Tsubdir/$table.sql");
    $Report->set_Detail(qq{mysql_command < $Tsubdir/$table.sql});
    $feedback = &try_system_command(qq{$mysql_command < $Tsubdir/$table.sql});
    $Report->set_Detail($feedback);
    $Report->set_Detail(qq{mysql_command -e "LOCK TABLES $table WRITE"});
    $feedback = &try_system_command(qq{$mysql_command -e "LOCK TABLES $table WRITE"});
    $Report->set_Detail($feedback);

    #### Special handling for very LARGE tables.. (separate into multiple files)...####
    if ( !$structure && ( grep /^$table$/, @Large_Databases ) ) {
        my $index        = 1;
        my $skip_options = $options;
        if ($skip_records) {
            $Report->set_Detail("NOT regenerating table (in Skip_records mode)");
            my $locally_skipped = $skip_records;
            while ( $skip_records > 0 ) {
                if ( -e "$Tsubdir/$table.$extension.$index" ) {
                    my ( $words, $lines, $chars ) = try_system_command("cat $Tsubdir/$table.$extension.$index | wc");
                    $Report->set_Detail("cat $Tsubdir/$table.$extension.$index | wc");
                    $Report->set_Detail("Words: $words, Lines: $lines, Chars: $chars");

                    if ( $locally_skipped >= $lines ) {
                        ## go to next file (skipping more records than exist in this index file)
                        $index++;
                        $locally_skipped -= $lines;
                    }
                    else {
                        ## normal skipping message ##
                        $Report->set_Detail("Skipping $locally_skipped in index $index file");
                        last;
                    }
                }
                else {
                    if ($locally_skipped) {
                        ## waiting to skip more records, but no more index files - skip this table.
                        $Report->set_Error("Error finding $Tsubdir/$table.$extension.$index (waiting to skip $locally_skipped more records)");
                        last T;
                    }
                    else {
                        ## locally skipped works out (by chance) to be exactly zero ##
                    }
                }
            }
            $skip_options =~ s /IGNORE $skip_records LINES/IGNORE $locally_skipped LINES/;
            $Report->set_Detail("Skipping to index $index file and skipping first $locally_skipped lines");
        }

        if ( grep /^$target_host$/, @Raid_Hosts ) {
            set_Raid($table);
        }

        my $skipped = 0;
        while ( -e "$Tsubdir/$table.$extension.$index" ) {
            my $command;
            $Report->set_Detail("file # $index..");
            if ( $extension eq 'sql' ) {
                $command = qq{< $Tsubdir/$table.$extension.$index};
            }
            else {
                $command = qq{-e "LOAD DATA $local INFILE '$Tsubdir/$table.$extension.$index' INTO TABLE `$table` $options"};
            }

            $Report->set_Detail(qq{mysql_command $command});
            $feedback = try_system_command(qq{$mysql_command $command});

            #If error out then move on to the next table.
            if ( $feedback =~ /ERROR/ ) { $Report->set_Error($feedback); next T; }

            $Report->set_Detail( "$Tsubdir/$table.$extension.$index (" . &date_time() . &count_records( $T_dbc, $table ) . ")" );

            #If finished restoring from the first dump of the table, then check to see if we are restoring to RAID host and if so alter the table to use RAID.
            $index++;
        }
        $index--;
        $Report->set_Detail("Restored (from $index $Tsubdir/$table.$extension files)");
        $Report->set_Detail("*************************************************************************");
    }
    else {
        ### Standard Upload ###
        my $command;
        if ( -e "$Tsubdir/$table.$extension" ) {
            if ( $extension eq 'sql' ) {
                $command = qq{< $Tsubdir/$table.$extension};
            }
            elsif ( !$structure ) {
                $Report->start_sub_Section("Loading $table data");
                $command = qq{-e "LOAD DATA $local INFILE '$Tsubdir/$table.$extension' INTO TABLE $table $options"};
                $Report->end_sub_Section("Loading $table data");
            }
        }
        else {
            $Report->set_Warning("$Tsubdir/$table.$extension NOT FOUND.");
            next T;
        }

        $Report->set_Detail(qq{mysql_command $command});
        $feedback = try_system_command(qq{$mysql_command $command});
        $Report->set_Detail($feedback);

        #If error out then move on to the next table.
        if ( $feedback =~ /ERROR/ ) { $Report->set_Error($feedback); next T; }
    }

    $Report->set_Detail(qq{mysql_command -e "UNLOCK TABLES"});
    $feedback = try_system_command(qq{$mysql_command -e "UNLOCK TABLES"});
    $Report->set_Detail($feedback);
    $Report->set_Detail(qq{mysql_command -e "OPTIMIZE TABLE $table"});
    $feedback = try_system_command(qq{$mysql_command -e "OPTIMIZE TABLE $table"});
    $Report->set_Detail($feedback);

    ## <CONSTRUCTION> Double optimize, probably only needed for large tables with complex indexes
    ## For example Plate. Plate_Sample is a large table however the indexes for it are actually simple so no need to double optimizing.
    if ( $table eq 'Plate' ) {
        $Report->set_Detail(qq{mysql_command -e "OPTIMIZE TABLE $table"});
        $feedback = try_system_command(qq{$mysql_command -e "OPTIMIZE TABLE $table"});
        $Report->set_Detail($feedback);
    }

    $Report->set_Detail( "$table records AFTER Restore:\t" . count_records( $T_dbc, $table ) ) if $opt_from;
    $Report->set_Detail( "($table Table Restored at " . &date_time() . ")" );

    $Report->succeeded();
}

leave( -message => "Completed " . &date_time(), -success => 1 );    ## EXIT

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

########################
sub count_records {
########################
    my $dbc             = shift;
    my $table           = shift;
    my $target_override = shift;
    my $count           = 0;

    my @T_tables = $T_dbc->DB_tables();
    my @tables   = $dbc->DB_tables();

    if ( !( grep /^$table$/, @T_tables ) && !$target_override ) {
        $Report->set_Warning(" Note: $table not in target database");
        return 0;
    }

    if ( grep /^$table$/, @tables ) {
        ($count) = $dbc->Table_find( $table, "count(*)" );
    }

    return $count;
}

#####################################################
# Find location of backup for specified table
#########################
sub find_subdirectory {
#########################
    my $table        = shift;
    my $subdirectory = shift;    ## optional directory to try first...

    if ( -e "$subdirectory/$table.$extension" ) { return $subdirectory }

    if ( $opt_time || $opt_date ) {
        my $basename = "$path/$datestamp/$timestamp";
        my @versions = glob("$path/$datestamp/$timestamp/$table.$extension");
        $subdirectory = $versions[$#versions];    ### grab most recent if more than one
        Message("glob $path/$datestamp/$timestamp/$table.$extension -> $subdirectory");
        $Report->set_Detail("Specified Backup: $subdirectory");
    }
    else {
        ## if ($opt_a) { ## just use latest directory found
        my @dates = glob("$path/$datestamp/*");
        my $index = $#dates;
        while ( !$subdirectory && ( $index >= 0 ) ) {    ## find most recent backup of this table
            my @versions = glob("$dates[$index]/$table.$extension");
            my $index2   = $#versions;
            while ( !$subdirectory && ( $index2 >= 0 ) ) {
                $subdirectory = $versions[$index2];
                if ( $subdirectory =~ /^(.*)\/$table\.$extension$/ ) {
                    $subdirectory = $1;
                }
                else { $subdirectory = ''; }             ### not the right one ?..
                $index2--;
            }
            $index--;
        }
    }

    ($subdirectory) = split "\n", try_system_command("ls -t $path/$datestamp/$timestamp/$table.$extension");
    
 #   if ($subdirectory =~/No such file/i) { $subdirectory = "(NOT FOUND)" }
    
    if ( $subdirectory =~ /^(.*)\/$table\.$extension$/ ) {
        $subdirectory = $1;
        $Report->set_Message("Found Backup: $subdirectory");
    }

    return $subdirectory;
}

###############
sub set_Raid {
###############
    my $table = shift;

    my $command = qq{$mysql_command -e 'ALTER TABLE $table type=MyISAM raid_type=striped raid_chunks=6 raid_chunksize=32;'};
    $Report->set_Detail( "Altering $table to use RAID(" . &date_time() . "): $command" );
    my $feedback = try_system_command($command);

    #If error out then move on to the next table.
    if ($feedback) { $Report->set_Detail($feedback); next T; }
    $Report->set_Detail( "Altered $table successfully.(" . &date_time() . ")" );
}

################
# exit cleanly
################
sub leave {
################
    my %args    = &filter_input( \@_ );
    my $message = $args{-message};
    my $success = $args{-success};
    my $no_log  = $args{-no_log};

    Call_Stack();
    
    $dbc->disconnect() if $dbc;


    $T_dbc->disconnect();
    if ($no_log) { Message($message); exit; }

    if ($message) {
        $Report->set_Message("EXITING: $message");
    }
    if ($success) { $Report->completed() }

    $Report->DESTROY();
    exit;
}
