#!/usr/local/bin/perl

################################################################################
#
# check_replication.pl
#
# This allows monitoring of replication database...
#
################################################################################

use strict;
use DBI;
use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";

########################
## Local Core modules ##
########################
use CGI;
use Data::Dumper;
use Benchmark;

##########################
## Local custom modules ##
##########################
use RGTools::RGIO;
use RGTools::Process_Monitor;
use LampLite::Bootstrap;

use SDB::DBIO;    ## use to connect to database

use alDente::Config;    ## use to initialize configuration settings

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);    ## replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
###############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Config = new alDente::Config( -initialize => 1, -root => $FindBin::RealBin . '/..' );

my ( $home, $version, $domain, $custom, $path, $dbase, $host, $login_type, $session_dir, $init_errors, $url_params, $session_params, $brand_image, $screen_mode, $configs, $custom_login, $css_files, $js_files, $init_errors ) = (
    $Config->{home},       $Config->{version},      $Config->{domain},      $Config->{custom},     $Config->{path},           $Config->{dbase}, $Config->{host},
    $Config->{login_type}, $Config->{session_dir},  $Config->{init_errors}, $Config->{url_params}, $Config->{session_params}, $Config->{icon},  $Config->{screen_mode},
    $Config->{configs},    $Config->{custom_login}, $Config->{css_files},   $Config->{js_files},   $Config->{init_errors}
);

%Configs = $configs;

#Tmp fix for now
$Configs{Data_home_dir} = "/home/aldente";
$Configs{version_name}  = "production";
$Configs{Dump_dir}      = "/home/aldente/private/dumps";
$Configs{mySQL_HOST}    = "lims05";

###################################################
## END OF Standard Module Initialization Section ##
###################################################

## Load input parameter options ##
#use vars qw($opt_host $opt_dbase $opt_debug);
#
#use Getopt::Long;
#&GetOptions(
#    'host=s'    => \$opt_host,
#    'dbase=s'   => \$opt_dbase,
#    'debug|t'     => \$opt_debug,
#);#
#
##############################
use vars qw($opt_M $opt_u $opt_p $opt_h $opt_S $opt_T $opt_q $opt_X $opt_n $opt_l $opt_r $opt_F $opt_D $opt_t $opt_Z $opt_v);
use vars qw($lims_administrator_email %Configs);

#require "getopts.pl";
#&Getopts('M:S:u:hf:T:qX:lnr:FDZt:p:v:');

use Getopt::Long;
Getopt::Long::Configure("no_ignore_case");

&GetOptions(
    'Force'            => \$opt_F,
    'Master=s'         => \$opt_M,
    'Slave=s'          => \$opt_S,
    'user=s'           => \$opt_u,
    'xclude=s'         => \$opt_X,
    'Tables=s'         => \$opt_T,
    'no_notification'  => \$opt_n,
    'log_check'        => \$opt_l,
    'quiet'            => \$opt_q,
    'Dump_table_check' => \$opt_D,
    'time=s'           => \$opt_t,
    'Z'                => \$opt_Z,
    'password=s'       => \$opt_p,
    'version=s'        => \$opt_v,
);

if ($opt_h) {
    &print_help_info();
    exit;
}
my $force_table_check = $opt_F;
my $m_dbase           = $opt_M;                  # Master database
my $source            = $opt_S;                  # Slave databasey
my $m_host            = $Configs{mySQL_HOST};    # Master host
my $user              = $opt_u;                  # Login user
my $exclusions        = $opt_X;
my $tables_to_check   = $opt_T;
my $no_notifications  = $opt_n;
my $log_check         = $opt_l;
my $quiet             = $opt_q;
my $dump_table_check  = $opt_D;
my $dump_time         = $opt_t;
my $slave_dump_check  = $opt_Z;
my $password          = $opt_p;
my $version           = $opt_v;

#############################################

## Enable automatic logging as required ##

my $Dump_dir = $Configs{Dump_dir};
#########
my $Report = Process_Monitor->new( -variation => $version, -configs => $Config );

# Resolve master dbase into host if necessary
if ( $m_dbase =~ /([\w\-]*):([\w\-]*)/ ) {
    $m_host  = $1;
    $m_dbase = $2;
}

my $s_host;
my $s_dbase;
if ( $source =~ /([\w\-]*):([\w\-]*)/ ) {
    ## specify slave host : database (if ONLY restoring slave)
    $s_host  = $1;
    $s_dbase = $2;
}
elsif ($source) {
    ## assume slave database has same name, but on different host
    $s_host  = $source;
    $s_dbase = $m_dbase;
}
else {
    ## restore both together...
    $s_host  = $m_host;
    $s_dbase = $m_dbase;
}

#my $password = $opt_p || Prompt_Input( -type => 'password', -prompt => 'Password: >' );

unless ($user) {
    $Report->set_Error("invalid login parameters entered...");
    exit;
}

# Connect to the master database
my $m_dbc = SDB::DBIO->new();
$m_dbc->connect( -host => $m_host, -dbase => $m_dbase, -user => $user );

my $s_dbc = SDB::DBIO->new();
$s_dbc->connect( -host => $s_host, -dbase => $s_dbase, -user => $user );

my $datetime = &date_time();

my $error;

if ($slave_dump_check) {
    &slaves_check();
}
else {
    &mysql_replication_check();

    if ($force_table_check) {
        &table_count_replication_check();
    }

    if ($dump_table_check) {
        &full_replication_check();
    }
}

$m_dbc->disconnect();
$s_dbc->disconnect();
$Report->completed();
$Report->DESTROY();
exit;

sub mysql_replication_check {

    # Get log positions
    my $sth = $m_dbc->query( -query => "SHOW MASTER STATUS", -finish => 0 );
    my $master_info = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );
    if ( $master_info->{Last_errno} || $master_info->{Last_error} ) {
        $error = "Error on slave: $master_info->{Last_error} ($master_info->{Last_errno})\n";
    }
    my ( $m_file, $m_position ) = @$master_info{ ( 'File', 'Position' ) };

    # Check the replication status on the slave
    $sth = $s_dbc->query( -query => "SHOW SLAVE STATUS", -finish => 0 );
    my $slave_info = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'RH' );
    if ( $slave_info->{Last_errno} || $slave_info->{Last_error} || $slave_info->{Slave_SQL_Running} eq 'No' || $slave_info->{Slave_IO_Running} eq 'No' ) {
        $error .= "Error on slave: $slave_info->{Last_error} ($slave_info->{Last_errno})\n";
        $error .= "Slave_IO_Running: $slave_info->{Slave_SQL_Running} Slave_SQL_Running: $slave_info->{Slave_IO_Running}\n";
    }
    my ( $s_file, $s_position ) = @$slave_info{ ('Master_Log_File'), ('Read_Master_Log_Pos') };

    # Show master and slave log positions
    my $misc_info;
    $misc_info .= "\n";
    $misc_info .= "Master log file: $m_file (position: $m_position)\n";
    $misc_info .= "Master log file read on slave: $s_file (position: $s_position)\n";
    $misc_info .= "\n";

    if ($error) {
        $misc_info .= "Error: $error\n";
        $Report->set_Error($misc_info);
        return 0;
    }
    else {
        $Report->set_Message($misc_info);
        print "Error: None\n";
        return 1;
    }
}

sub table_count_replication_check {
    my $sth = $m_dbc->query( -query => "show tables", -finish => 0 );
    my $tables = &SDB::DBIO::format_retrieve( -sth => $sth, -format => 'CS' );

    if ($opt_T) { $tables = $opt_T }

    my $good         = 0;
    my $empty        = 0;
    my $inconsistent = 0;
    my $checked      = 0;

    my %empties;
    my %inconsistents;
    my $msg;
    foreach my $table ( split ',', $tables ) {
        if ( $exclusions =~ /\b$table\b/ ) {next}
        my ($count1) = &Table_find( $m_dbc, $table, 'count(*)' );
        my ($count2) = &Table_find( $s_dbc, $table, 'count(*)' );

        my $msg;
        $msg = printf "%20s : %5d %5d", $table, $count1, $count2 unless $quiet;

        if ( $count1 == $count2 ) {
            $Report->set_Detail("$msg . (OK $table)");
            $Report->succeeded();
            $good++;
        }
        elsif ( $count1 && !$count2 ) {
            $Report->set_Error("$msg ** Empty Slave: $table.  Master ($count1) != Slave ($count2) **");
            $empties{$table} = $msg;
            $empty++;
        }
        else {
            $Report->set_Error("$msg ** Inconsistent Slave: $table.  Master ($count1) != Slave ($count2) **");
            $Report->set_Detail($msg);
            $inconsistents{$table} = $msg;
            $inconsistent++;
        }
        $checked++;
    }

    my $m = "Summary
*************
Tables Checked: $checked
Empty Slave: $empty
Inconsistent Slave: $inconsistent
 
Passed: $good / $checked\n";
    $Report->set_Message($m);

    if ( %empties || %inconsistents || $error ) {
        $msg = "$datetime\n\n";

        foreach my $e ( sort keys %empties ) {
            $msg .= "$e -> $empties{$e}\n";
        }
        foreach my $i ( sort keys %inconsistents ) {
            $msg .= "$i -> $inconsistents{$i}\n";
        }
        return 0;
    }
    else {
        print "Error: None\n";
        return 1;
    }
}

sub full_replication_check {

    # ensure the slave is running and up to date.
    my $replication_running = &mysql_replication_check();
    if ( !$replication_running ) {
        $Report->set_Error("Can't do full replication check since replication is not running");
        return 0;
    }

    my ( $today, $nowtime ) = split ' ', &date_time;
    if ($tables_to_check) { $tables_to_check = "-T $tables_to_check" }

    # lock master
    $Report->set_Message("LOCK MASTER $m_host:$m_dbase");
    $m_dbc->execute_command( -command => "FLUSH TABLES WITH READ LOCK" );

    # turn off the slave
    $Report->set_Message("STOP SLAVE $s_host:$s_dbase");
    $s_dbc->execute_command( -command => "STOP SLAVE" );

    # perform full backup of master (or optionally on list of tables if supplied)
    my $m_path = "$Dump_dir/$m_host/$m_dbase/$today/$dump_time";
    $Report->set_Message("Start backup to $m_path");
    my ( $stdout, $stderr ) = try_system_command(
        "$Configs{Data_home_dir}/WebVersions/$Configs{version_name}/bin/backup_RDB.pl -dump -host $m_host -dbase $m_dbase -user super_cron_user -confirm -time $dump_time $tables_to_check -finish_file -routine 1>/home/aldente/private/logs/full_replication_check_backup_master.log 2>/home/aldente/private/logs/full_replication_check_backup_master.err",

        #-host    => $m_host,
        -verbose => 1
    );
    $Report->set_Message("Finish backup to $m_path");

    #while (!-e "$m_path/backup.finished.txt") { print "Dumping $m_host:$m_dbase sleeping\n"; sleep(10); }

    # unlock master
    $Report->set_Message("UNLOCK MASTER $m_host:$m_dbase");
    $m_dbc->execute_command( -command => "UNLOCK TABLES" );

    # perform a full backup of slave (or optionally on list of tables if supplied)
    my $s_path = "$Dump_dir/$s_host/$s_dbase/$today/$dump_time";
    $Report->set_Message("Start backup to $s_path");
    my ( $stdout, $stderr ) = try_system_command(
        "$Configs{Data_home_dir}/WebVersions/$Configs{version_name}/bin/backup_RDB.pl -dump -host $s_host -dbase $s_dbase -user super_cron_user -confirm -time $dump_time $tables_to_check -finish_file -routine 1>/home/aldente/private/logs/full_replication_check_backup_slave.log 2>/home/aldente/private/logs/full_replication_check_backup_slave.err",

        #-host    => $s_host,
        -verbose => 1
    );

    # to adjust removed basic database infor difference so it won't break md5sum check
    my ( $stdout, $stderr ) = try_system_command("sed -i s/--.*//g $m_path/*sql");
    my ( $stdout, $stderr ) = try_system_command("sed -i s/--.*//g $s_path/*sql");
    $Report->set_Message("Finsih backup to $s_path");

    #while (!-e "$s_path/backup.finished.txt") { print "Dumping $s_host:$s_dbase sleeping\n"; sleep(10); }

    # turn slave back on
    $Report->set_Message("START SLAVE $s_host:$s_dbase");
    $s_dbc->execute_command( -command => "START SLAVE" );

    # Compare dumps
    my $ok = &md5sum_check( $m_path, $s_path );
    if ($ok) {

        #remove slave dump
        $s_path =~ s/\/$dump_time//;
        $Report->set_Message("md5sum check passed, removing slave backup $s_path");
        try_system_command( "rm -rf $s_path", -verbose => 1 );
    }
}

sub md5sum_check {
    my $dir_1 = shift;
    my $dir_2 = shift;
    my $ok    = 1;

    my ( $stdout, $stderr ) = try_system_command("ls $dir_1");
    my @files_from_dir_1 = split( "\n", $stdout );
    my %hash_1 = map { $_ => 1; } grep {$_} @files_from_dir_1;

    #print Dumper \%hash_1;

    my ( $stdout, $stderr ) = try_system_command("ls $dir_2");
    my @files_from_dir_2 = split( "\n", $stdout );
    my %hash_2 = map { $_ => 1; } grep {$_} @files_from_dir_2;

    #print Dumper \%hash_2;

    #Go through each file in directory 1 and check if exist in directoy 2 and do a checksum check
    for my $file_1 ( sort keys %hash_1 ) {

        #print "$file_1 " . &date_time() . "\n";
        #if ($file_1 =~ /Band.txt|Clone_Sequence.txt/) { next }
        #if ($file_1 !~ /^(Cross_Match.txt|Library_Plate.txt|Plate.txt|Plate_Attribute.txt|Plate_Prep.txt|Plate_Sample.txt|Plate_Set.txt|Prep.txt|Run_Attribute.txt|Sample.txt|SolexaAnalysis.txt|Solution.txt|Work_Request.txt)$/) { next }
        if ( !$hash_2{$file_1} ) {

            #File not in dir 2
            $Report->set_Error("$file_1 not in $dir_2");
            $ok = 0;
        }
        else {

            #Do md5sum check
            my ( $file_1_md5sum, $stderr ) = try_system_command("md5sum $dir_1/$file_1");
            my ( $file_2_md5sum, $stderr ) = try_system_command("md5sum $dir_2/$file_1");
            ($file_1_md5sum) = split( " ", $file_1_md5sum );
            ($file_2_md5sum) = split( " ", $file_2_md5sum );

            #print Dumper $file_1_md5sum, $file_2_md5sum;

            if ( $file_1_md5sum ne $file_2_md5sum ) {
                $ok = 0;
                $Report->set_Error("$file_1 failed md5sum check");
                my ( $diff, $stderr ) = try_system_command("diff $dir_1/$file_1 $dir_2/$file_1");
                $Report->set_Message("$file_1:\n$diff");
            }
        }
    }

    #Final go through each file in directory 2 and see if there is an extra file in directory 2
    for my $file_2 ( sort keys %hash_2 ) {
        if ( !$hash_1{$file_2} ) {
            $ok = 0;
            $Report->set_Error("$file_2 not in $dir_1");
        }
    }
    return $ok;
}

sub slaves_check {

    # ensure the slave is running and up to date.
    #my $replication_running = &mysql_replication_check();
    #if ( !$replication_running ) {
    #    $Report->set_Error("Can't do full replication check since replication is not running");
    #    return 0;
    #}

    my ( $today, $nowtime ) = split ' ', &date_time;
    if ($tables_to_check) { $tables_to_check = "-T $tables_to_check" }

    # turn off slave 1
    $Report->set_Message("STOP SLAVE $m_host:$m_dbase");
    $m_dbc->execute_command( -command => "STOP SLAVE" );

    # turn off slave 2
    $Report->set_Message("STOP SLAVE $s_host:$s_dbase");
    $s_dbc->execute_command( -command => "STOP SLAVE" );

    # perform full backup of master (or optionally on list of tables if supplied)
    my $m_path = "$Dump_dir/$m_host/$m_dbase/$today/$dump_time";
    $Report->set_Message("Start backup to $m_path");
    my ( $stdout, $stderr ) = try_system_command(
        "$Configs{Data_home_dir}/WebVersions/$Configs{version_name}/bin/backup_RDB.pl -dump -host $m_host -dbase $m_dbase -user super_cron_user -confirm -time $dump_time $tables_to_check -finish_file",
        -host    => $m_host,
        -verbose => 1
    );
    $Report->set_Message("Finish backup to $m_path");

    #while (!-e "$m_path/backup.finished.txt") { print "Dumping $m_host:$m_dbase sleeping\n"; sleep(10); }

    # start slave 1
    $Report->set_Message("START SLAVE $m_host:$m_dbase");
    $m_dbc->execute_command( -command => "START SLAVE" );

    # perform a full backup of slave (or optionally on list of tables if supplied)
    my $s_path = "$Dump_dir/$s_host/$s_dbase/$today/$dump_time";
    $Report->set_Message("Start backup to $s_path");
    my ( $stdout, $stderr ) = try_system_command(
        "$Configs{Data_home_dir}/WebVersions/$Configs{version_name}/bin/backup_RDB.pl -dump -host $s_host -dbase $s_dbase -user super_cron_user -confirm -time $dump_time $tables_to_check -finish_file",
        -host    => $s_host,
        -verbose => 1
    );

    # to adjust removed basic database infor difference so it won't break md5sum check
    my ( $stdout, $stderr ) = try_system_command("sed -i s/--.*//g $m_path/*sql");
    my ( $stdout, $stderr ) = try_system_command("sed -i s/--.*//g $s_path/*sql");
    $Report->set_Message("Finsih backup to $s_path");

    #while (!-e "$s_path/backup.finished.txt") { print "Dumping $s_host:$s_dbase sleeping\n"; sleep(10); }

    # start slave 2
    $Report->set_Message("START SLAVE $s_host:$s_dbase");
    $s_dbc->execute_command( -command => "START SLAVE" );

    # Compare dumps
    my $ok = &md5sum_check( $m_path, $s_path );
    if ($ok) {

        #remove slave dump
        $s_path =~ s/\/$dump_time//;
        $Report->set_Message("md5sum check passed, removing slave backup $s_path");
        try_system_command( "rm -rf $s_path", -verbose => 1 );
    }
}

#######################
sub print_help_info {
#######################

    print "
Options:
-M master_host:master_database
-S slave_host:slave_database
-T tables to check
-u username
-q quiet
-n no emails
-F Force table count check
";
    return;
}
