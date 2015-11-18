#!/usr/local/bin/perl
#
################################################################################
#
# cleanup.pl
#
# This program:
#   removes old files
#   archives some directories
#
# NOTE:  uses /conf/cleanup_archive.conf and /conf/cleanup_delete.conf
################################################################################

use strict;
use CGI qw(:standard);
use DBI;
use File::stat;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::CustomSettings;
use alDente::SDB_Defaults;
use SDB::DBIO;

use vars qw($mirror_dir $session_dir $Dump_dir $Data_log_directory $Data_home_dir);
use vars qw($URL_dir $URL_temp_dir);
use vars qw($opt_D $opt_C $opt_T $opt_v $opt_u $opt_p $opt_b $opt_analyze $opt_ai );

&GetOptions(
    'd'         => \$opt_D,
    't'         => \$opt_T,
    'C'         => \$opt_C,
    'b'         => \$opt_b,
    'v=s'       => \$opt_v,
    'u=s'       => \$opt_u,
    'p=s'       => \$opt_p,
    'analyze|a' => \$opt_analyze,
    'ai|i'      => \$opt_ai,
);

############# CONF FILES ########################
my $delete_conf_file  = $FindBin::RealBin . '/../conf/cleanup_delete.conf';
my $archive_conf_file = $FindBin::RealBin . '/../conf/cleanup_archive.conf';
my $purge_conf_file   = $FindBin::RealBin . '/../conf/cleanup_purge.conf';
############# Options for Cleaning UP ###########
my $removed              = 0;
my $debug                = $opt_D;
my $test                 = $opt_T;
my $variation            = $opt_v;
my $do_purge             = $opt_b;
my $analyze_table        = $opt_analyze;
my $check_auto_increment = $opt_ai;

unless ($opt_C) { help(); exit; }
if ( ( my $whoami = `whoami` ) !~ /aldente/ ) {
    chomp $whoami;
    print "$whoami: Please log in as aldente to run\n\n";
    exit;
}

#############################################
my $dbase        = $Configs{PRODUCTION_DATABASE};
my $host         = $Configs{PRODUCTION_HOST};
my $slave_dbase  = $Configs{BACKUP_DATABASE};
my $slave_host   = $Configs{BACKUP_HOST};
my $logs_to_keep = 10;
my $feedback;
#############################################

my $Report = Process_Monitor->new( -testing => $test, -variation => $variation );

my %delete  = _load_config( -type => 'delete' );
my %archive = _load_config( -type => 'archive' );

for my $key ( keys %archive ) {
    my $dir = _get_dir(
        -path  => $archive{$key}{name}{value},
        -depth => $archive{$key}{depth}{value}
    );

    _archive_files(
        -dir   => $dir,
        -day   => $archive{$key}{days}{value},
        -to    => $archive{$key}{to}{value},
        -save  => $archive{$key}{save}{value},
        -types => $archive{$key}{types}{value}
    );
}

for my $key ( keys %delete ) {
    my $dir = _get_dir(
        -path  => $delete{$key}{name}{value},
        -depth => $delete{$key}{depth}{value}
    );

    _delete_files(
        -dir   => $dir,
        -day   => $delete{$key}{days}{value},
        -types => $delete{$key}{types}{value}
    );
}

## create master and slave database connection if necessary
my $m_dbc, my $s_dbc;
if ( $do_purge || $check_auto_increment || $analyze_table ) {

    # Connect to the master database
    $m_dbc = SDB::DBIO->new();
    $m_dbc->connect( -host => $host, -dbase => $dbase, -user => $opt_u );

    # Connect to the slave database
    $s_dbc = SDB::DBIO->new();
    $s_dbc->connect( -host => $slave_host, -dbase => $slave_dbase, -user => $opt_u );
}

if ($do_purge) {

    #&_purge_bin_logs( -mhost=>$host, -mdbase=>$dbase, -shost=>$slave_host, -sdbase=>$slave_dbase, -logs_to_keep=>$logs_to_keep, -user=>$opt_u, -password=>$opt_p );
    &_purge_bin_logs( -master_dbc => $m_dbc, -slave_dbc => $s_dbc, -logs_to_keep => $logs_to_keep );
}

if ($check_auto_increment) {
    &_check_auto_increment( -master_dbc => $m_dbc, -slave_dbc => $s_dbc );
}

if ($analyze_table) {
    print "analyze_table=$analyze_table";
    &_analyze_tables( -master_dbc => $m_dbc );
}

$Report->completed();
$Report->DESTROY();

exit;

###########################
sub _get_dir {
###########################
    my %args  = filter_input( \@_ );
    my $dir   = $args{-path};
    my $depth = $args{-depth};
    my $name  = $Configs{$dir} || $dir;
    for my $counter ( 1 .. $depth ) { $name .= '/*' }
    return $name;
}

###########################
sub _archive_files {
###########################
    my %args  = filter_input( \@_ );
    my $dir   = $args{-dir};
    my $day   = $args{-day};
    my $types = $args{-types};
    my $to    = $args{-to};
    my $save  = $args{-save};

    $Report->start_Section("To archive $dir");
    $Report->set_Message("Checking $types in $dir older than $day days old ");

    if ( $types =~ /file/ ) {
        my $command = "find $dir -ctime +$day -maxdepth 1 -mindepth 1  -type f  -follow";
        Message $command if $debug;
        my @oldfilelist = split "\n", try_system_command($command);
        if ( $oldfilelist[0] =~ /No such file/i ) {
            $Report->set_Message("Failed to find $types in $dir older than $day days old  ");
        }
        else {
            my $archive_count;
            my $delete_count;
            foreach my $direc (@oldfilelist) {
                if ( $direc =~ /archive/ ) {next}
                if ( $direc =~ /$save$/ ) {
                    my $move_command = "mv $direc $to";
                    $move_command .= $1 if $1;
                    Message $move_command if $debug;
                    my $response = try_system_command($move_command) unless $test;
                    if ( $response =~ /Permission denied/ ) { $Report->set_Warning("Permission denied for moving $direc ") }
                    elsif ($response) { Message $response }
                    else              { $archive_count++ }
                }
                else {
                    my $del_command = "rm -f \"$direc\"";
                    Message $del_command if $debug;
                    my $response = try_system_command($del_command) unless $test;
                    if ( $response =~ /Permission denied/ ) { $Report->set_Warning("Permission denied for $direc") }
                    elsif ($response) { Message $response }
                    else              { $delete_count++ }
                }
            }
            unless ($archive_count) { $archive_count = '0' }
            unless ($delete_count)  { $delete_count  = '0' }
            $Report->set_Message("Archived $archive_count $types ");
            $Report->set_Message("Deleted $delete_count $types ");
        }
    }

    if ( $types =~ /directory/ ) {
        my $command = "find $dir -ctime +$day -maxdepth 1 -mindepth 1 -type d -follow ";
        Message $command if $debug;
        my @oldfilelist = split "\n", try_system_command($command);
        if ( $oldfilelist[0] =~ /No such file/i ) {
            $Report->set_Message("Failed to find $types in $dir older than $day days old  ");
        }
        else {
            my $archive_count;
            my $delete_count;
            foreach my $direc (@oldfilelist) {
                if ( $direc =~ /archive/ ) {next}
                if ( $direc =~ /$save$/ ) {
                    my $move_command = "mv $direc $to";
                    $move_command .= $1 if $1;
                    Message $move_command if $debug;
                    my $response = try_system_command($move_command) unless $test;
                    if ( $response =~ /Permission denied/ ) { $Report->set_Warning("Permission denied for moving $direc ") }
                    elsif ($response) { Message $response }
                    else              { $archive_count++ }
                }
                else {
                    my $del_command = "rm -rf $direc";
                    Message $del_command if $debug;
                    my $response = try_system_command($del_command) unless $test;
                    if ( $response =~ /Permission denied/ ) { $Report->set_Warning("Permission denied for $direc") }
                    elsif ($response) { Message $response }
                    else              { $delete_count++ }
                }
            }
            unless ($archive_count) { $archive_count = '0' }
            unless ($delete_count)  { $delete_count  = '0' }
            $Report->set_Message("Archived $archive_count $types ");
            $Report->set_Message("Deleted $delete_count $types ");
        }
    }

    $Report->end_Section("To archive $dir");
    return;
}

###########################
sub _delete_files {
###########################
    my %args  = filter_input( \@_ );
    my $dir   = $args{-dir};
    my $day   = $args{-day};
    my $types = $args{-types};
    $Report->start_Section("To delete $dir");
    $Report->set_Message("Checking $types in $dir older than $day days old ");

    if ( $types =~ /file/ ) {
        my $command = "find $dir -ctime +$day -maxdepth 1 -mindepth 1   -type f  -follow";
        Message $command if $debug;
        my @oldfilelist = split "\n", try_system_command($command);
        if ( $oldfilelist[0] =~ /No such file/i ) {
            $Report->set_Message("Failed to find $types in $dir older than $day days old  ");
        }
        else {
            my $count;
            foreach my $direc (@oldfilelist) {
                if ( $direc =~ /archive/ ) {next}
                my $del_command = "rm -f \"$direc\"";
                Message $del_command if $debug;
                my $response = try_system_command($del_command) unless $test;
                if ( $response =~ /Permission denied/ ) { $Report->set_Warning("Permission denied for $direc") }
                elsif ($response) { Message $response }
                else              { $count++ }
            }
            unless ($count) { $count = '0' }
            $Report->set_Message("Deleted $count $types ");
        }
    }

    if ( $types =~ /directory/ ) {
        my $command = "find $dir -ctime +$day -maxdepth 1 -mindepth 1 -type d   -type d  -follow";
        Message $command if $debug;
        my @oldfilelist = split "\n", try_system_command($command);    #,-report=>$Report
        if ( $oldfilelist[0] =~ /No such file/i ) {
            $Report->set_Message("Failed to find $types in $dir older than $day days old  ");
        }
        else {
            my $count;
            foreach my $direc (@oldfilelist) {
                if ( $direc =~ /archive/ ) {next}
                my $del_command = "rm -rf $direc";
                Message $del_command if $debug;
                my $response = try_system_command($del_command) unless $test;
                if ( $response =~ /Permission denied/ ) { $Report->set_Warning("Permission denied for $direc") }
                elsif ($response) { Message $response }
                else              { $count++ }
            }
            unless ($count) { $count = '0' }
            $Report->set_Message("Deleted $count $types ");
        }
    }

    $Report->end_Section("To delete $dir");
    return;
}

##############################
sub _load_config {
##############################
    my %args = filter_input( \@_ );
    my $type = $args{-type} || 'archive';
    my $conf_file;
    my %info;

    if    ( $type eq 'archive' ) { $conf_file = $archive_conf_file }
    elsif ( $type eq 'delete' )  { $conf_file = $delete_conf_file }
    else                         { Message "ErrosRRRRRRRR"; exit; }

    if ( -f $conf_file ) {
        my $data = XML::Simple::XMLin("$conf_file");
        %info = %{$data};
    }
    else {
        die "no config file $conf_file found\n";
    }
    return %info;

}

##############################
sub help {
##############################
    print <<HELP;

        File:  cleanup.pl
        #####################

        Options:
        ##########
        -t      Test (No action just report actions that will be taken if run)
        -d      Debug
        -C      Confirmed: This flag is necesary for script to run
        -v      <Variation> (Suggestion Use HOST_NAME)
        -u		database user name
        -p		password for the database user
        -b		purge bin logs
        -a		perform analyze tables
        -i		check auto increment counter between master and slave. Reset the counter if inconsistent 

        Example:  
        ###########
        cleanup.pl -C -v lims02 -u super_cron -p xxxx

        Cleans up old files.  Uses config files in conf directory to figure out what to archive or delete. 
        Purges mysql master logs. Uses config files in conf directory to figure out how many binary logs to keep.
        Execute ANALYZE TABLE statement . ANALYZE TABLE analyzes and stores the key distribution for a table.
        Check auto increment counter between master and slave. Reset the master's counter if inconsistent. 
        

HELP

}

###############################
sub compress_directories {
###############################
    #
    # This should compress the directory/directories listed to a .tgz file..
    #
    # (not being used currently)... (adjust)
    #

    #
    my $target_name;
    my $zipped_up;
    my $feedback;
    my $zipped;
    my $target_file;
    my $name;

    #  ... more code (erased) to be inserted...

    if ( -e "$target_name" ) {
        if ( -e "$target_file.tar.gz" ) {
            if ($zipped_up) {
                $feedback .= try_system_command( "tar -u --remove-files -z -v -f $target_file.tar.gz $name/", -report => $Report );
            }
            else { $feedback .= "(already zipped & empty)\n"; next; }
        }
        else {    ### update if this file already exists...
            $zipped++;
            $Report->set_Message("Tarring $name..");
            $feedback .= "*****\ntarring new $name\n->$name\n";

            #		$feedback .= try_system_command("tar -c --remove-files -z -v -f $target_file.tar.gz $name/");
        }
    }
    else { $feedback .= "name invalid ($target_name)\n"; }

    $Report->set_Message("Compressed\n$feedback (Zipped $zipped files) (Removed $removed backup directories)");

    my $df = try_system_command( "df -h $mirror_dir", -report => $Report );
    $Report->set_Message("Current Disk Space $df");

    return $feedback;
}

############################
# Purge binary logs
#
# Arguments:
#   -to_keep	=> scalar, how many binary log files to keep
#   -earliest_relay_master_log_file	=> scalar, the earliest relay master log file name
#
######################
sub _purge_bin_logs {
######################
    my %args         = @_;
    my $m_dbc        = $args{-master_dbc};
    my $s_dbc        = $args{-slave_dbc};
    my $m_host       = $args{-mhost};
    my $m_dbase      = $args{-mdbase};
    my $s_host       = $args{-shost};
    my $s_dbase      = $args{-sdbase};
    my $logs_to_keep = $args{-logs_to_keep};
    my $user         = $args{-user};

    #my $password	= $args{-password};

    $Report->start_Section("To purge master logs $m_host:$m_dbase");

    if ( !$m_dbc ) {

        # Connect to the master database
        $m_dbc = SDB::DBIO->new();
        $m_dbc->connect( -host => $m_host, -dbase => $m_dbase, -user => $user );
    }
    if ( !$s_dbc ) {

        #Connect to the slave database
        $s_dbc = SDB::DBIO->new();
        $s_dbc->connect( -host => $s_host, -dbase => $s_dbase, -user => $user );
    }

    my $error;

    # check master logs
    my $sth = $m_dbc->query( -query => "SHOW MASTER STATUS", -finish => 0 );
    my $master_info = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );
    if ( $master_info->{Last_errno} || $master_info->{Last_error} ) {
        $error .= "Error on master: $master_info->{Last_error} ($master_info->{Last_errno})\n";

        #$Report->set_Error ("Error on master: $master_info->{Last_error} ($master_info->{Last_errno})");
    }
    my ( $m_file, $m_position ) = @$master_info{ ( 'File', 'Position' ) };

    # Check the replication status on the slave
    my $sth = $s_dbc->query( -query => "SHOW SLAVE STATUS", -finish => 0 );
    my $slave_info = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );
    if ( $slave_info->{Last_errno} || $slave_info->{Last_error} || $slave_info->{Slave_SQL_Running} eq 'No' || $slave_info->{Slave_IO_Running} eq 'No' ) {
        $error .= "Error on slave: $slave_info->{Last_error} ($slave_info->{Last_errno}) Slave_IO_Running: $slave_info->{Slave_SQL_Running} Slave_SQL_Running: $slave_info->{Slave_IO_Running}\n";

        #$Report->set_Error ( "Error on slave: $slave_info->{Last_error} ($slave_info->{Last_errno}) Slave_IO_Running: $slave_info->{Slave_SQL_Running} Slave_SQL_Running: $slave_info->{Slave_IO_Running}" );
    }
    my ( $s_file, $s_position ) = @$slave_info{ ('Master_Log_File'), ('Read_Master_Log_Pos') };

    my $misc_info;
    $misc_info .= "\n";
    $misc_info .= "Master log file: $m_file (position: $m_position)\n";
    $misc_info .= "Master log file read on slave: $s_file (position: $s_position)\n";
    $misc_info .= "\n";

    if ($error) {
        $misc_info .= "Error: $error\n";
        $Report->set_Error($misc_info);
        return;
    }

    $Report->set_Message($misc_info);
    my $earliest_relay_master_log_file = $slave_info->{Relay_Master_Log_File};

    my @fields         = ('Log_name');
    my $sth            = $m_dbc->query( -query => "SHOW BINARY LOGS", -finish => 0 );
    my $bin_logs       = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'CA', -fields => \@fields );
    my $bin_logs_count = scalar(@$bin_logs);
    my $to_keep_count  = 0;
    my $purge_to_file;
    for ( my $i = $bin_logs_count - 1; $i >= 0; $i-- ) {
        if ( $bin_logs->[$i] eq $earliest_relay_master_log_file ) {
            $to_keep_count = 1;
        }
        elsif ($to_keep_count) {
            $to_keep_count++;
            if ( $to_keep_count >= $logs_to_keep ) {
                $purge_to_file = $bin_logs->[$i];
                last;
            }
        }
    }
    if ($purge_to_file) {
        my $purge_sth = "PURGE BINARY LOGS TO \'$purge_to_file\'";
        Message $purge_sth if $debug;
        my @results = $m_dbc->execute_command( -command => $purge_sth, -feedback => 1 ) unless $test;
        $Report->set_Message( join '\n', @results ) if (@results);
    }
}

############################
# Compare auto increment counters between master and slave. Reset the master's counter if they are inconsistent
#
#
#
######################
sub _check_auto_increment {
######################
    my %args  = @_;
    my $m_dbc = $args{-master_dbc};
    my $s_dbc = $args{-slave_dbc};

    $Report->start_Section("To check AUTO INCREMENT counters $host:$dbase vs $slave_host:$slave_dbase");
    if ( !$m_dbc ) {

        # Connect to the master database
        $m_dbc = SDB::DBIO->new();
        $m_dbc->connect( -host => $host, -dbase => $dbase, -user => $opt_u );
    }
    if ( !$s_dbc ) {

        #Connect to the slave database
        $s_dbc = SDB::DBIO->new();
        $s_dbc->connect( -host => $slave_host, -dbase => $slave_dbase, -user => $opt_u );
    }

    # check master auto increment counters
    my @original_table_list = $m_dbc->DB_tables();
    my $table_string = Cast_List( -list => \@original_table_list, -to => 'string', -autoquote => 1 );
    ## get all tables with auto increment field
    my %ai_tables = $m_dbc->Table_retrieve( 'INFORMATION_SCHEMA.COLUMNS', [ 'TABLE_NAME', 'COLUMN_NAME' ], "WHERE TABLE_SCHEMA = '$dbase' and TABLE_NAME in ($table_string) AND EXTRA like '%auto_increment%'" );
    ## get auto increment counter from master database
    my %m_ai_values = $m_dbc->Table_retrieve( 'INFORMATION_SCHEMA.TABLES', [ 'TABLE_NAME', 'AUTO_INCREMENT' ], "WHERE TABLE_SCHEMA = '$dbase' and TABLE_NAME in ($table_string)", -key => 'TABLE_NAME' );
    ## get auto increment counter from slave database
    my %s_ai_values = $s_dbc->Table_retrieve( 'INFORMATION_SCHEMA.TABLES', [ 'TABLE_NAME', 'AUTO_INCREMENT' ], "WHERE TABLE_SCHEMA = '$slave_dbase' and TABLE_NAME in ($table_string)", -key => 'TABLE_NAME' );
    my $index;
    my $max, my $new_counter, my $command;
    while ( defined $ai_tables{TABLE_NAME}[$index] ) {
        my $table     = $ai_tables{TABLE_NAME}[$index];
        my $ai_field  = $ai_tables{COLUMN_NAME}[$index];
        my $m_counter = $m_ai_values{$table}{AUTO_INCREMENT}[0];
        my $s_counter = $s_ai_values{$table}{AUTO_INCREMENT}[0];
        if ( $m_counter != $s_counter ) {    # inconsistent auto increment counter between master and slave => reset master counter
            $Report->set_Message("Inconsistent AUTO INCREMENT counter: $table ( master $m_counter - slave $s_counter )");

            ## reset master auto increment counter
            ($max) = $m_dbc->Table_find( "$table", "MAX($ai_field)", -condition => "WHERE 1 FOR UPDATE" );
            if ($max) {
                $new_counter = $max + 1;
                $command     = "ALTER TABLE $table AUTO_INCREMENT = $new_counter";
                $Report->set_Message("Executing command: $command");
                my ( $ok, $newid, $feedback ) = $m_dbc->execute_command( -command => $command );
                if ( !$ok ) { $Report->set_Message("Failed command: $command ($feedback)") }
            }
        }
        $index++;
    }
}

############################
# Do ANALYZE TABLE
#
#
#
######################
sub _analyze_tables {
######################
    my %args  = @_;
    my $m_dbc = $args{-master_dbc};    # master database connection

    $Report->start_Section("To do ANALYZE TABLE for $host:$dbase");
    if ( !$m_dbc ) {

        # Connect to the master database
        $m_dbc = SDB::DBIO->new();
        $m_dbc->connect( -host => $host, -dbase => $dbase, -user => $opt_u );
    }

    my @original_table_list = $m_dbc->DB_tables();
    my $table_string        = Cast_List( -list => \@original_table_list, -to => 'string', -autoquote => 0 );
    my $command             = "ANALYZE TABLE $table_string";
    $Report->set_Message("Executing command: $command");
    my ( $ok, $newid, $feedback ) = $m_dbc->execute_command( -command => $command );
    if ( !$ok ) {
        $Report->set_Message("Failed command: $command ($feedback)");
        return 0;
    }
    else {
        $Report->set_Message("ANALYZE TABLE finished");
        return 1;
    }
}
