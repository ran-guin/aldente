#!/usr/local/bin/perl

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
###################################################################################################################################
# DB_monitor.pl
#
# Performs various database monitoring functions
#
# $Id: DB_monitor.pl,v 1.6 2004/11/25 00:37:26 jsantos Exp $
###################################################################################################################################
########################################
## Standard Initialization of Module ###
########################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/LampLite";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

########################
## Local Core modules ##
########################
use CGI;
use Data::Dumper;
use Benchmark;

use strict;
##########################
## Local custom modules ##
##########################
use RGTools::RGIO;
use LampLite::Bootstrap;

use SDB::DBIO;         ## use to connect to database
use SDB::DB_Access;    ## use to retrieve login access passwords
use SDB::HTML;         ## use for web interface output (only needed for cgi-bin files)

use alDente::Config;   ## use to initialize configuration settings

### Modules used for Web Interface only ###
use alDente::Session;
use LampLite::MVC;

##############################
# global_vars                #
##############################
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);        ## replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
use vars qw($homelink);       ## replace with $dbc->homelink()
use vars qw(%Search_Item);    ## replace with $dbc->homelink()
use vars qw($Connection);
use vars qw(%Field_Info);
use vars qw($scanner_mode);
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

SDB::CustomSettings::load_config($configs);    ## temporary ...

#####################
## Input Arguments ##
#####################
use vars qw($opt_help);
use vars qw($opt_space $opt_records $opt_host $opt_mode $opt_user $login_file $opt_dbase $opt_table $help $opt_v);

use Getopt::Long;
&GetOptions(
    'help|h'    => \$opt_help,
    'dbase|D=s' => \$opt_dbase,
    'table|T=s' => \$opt_table,
    'host|H=s'  => \$opt_host,
    'mode|m=s'  => \$opt_mode,
    'user|u=s'  => \$opt_user,
    'space'     => \$opt_space,
    'records'   => \$opt_records,
    'help|h'    => \$help,
    'v=s'       => \$opt_v
);

use RGTools::Process_Monitor;
use SDB::Report;

if ($opt_help) {
    print help();
    exit;
}

############################################
## End of Standard Template for bin files ##
############################################

use alDente::Notification;
use RGTools::Conversion;
use XML::Dumper;

my $host    = $opt_host;
my $dbase   = $opt_dbase;
my $table   = $opt_table || '';
my $Mode    = $opt_mode || 'detail';
my $user    = $opt_user || 'cron_user';
my $version = $opt_v;

print "Host: $host, Dbase: $dbase, Table(s): $table, Mode: $Mode, User: $user\n";

my $mysql_dir  = $Config->value('mysql_dir');
my $login_file = SDB::DBIO->_get_login_file($configs);

use vars qw($administrator_email);
### Modular variables
my @Size_Scale = ( 1, 1024, 1024**2, 1024**3, 1024**4 );
my @Size_Scale_Units = ( 'B', 'KB', 'MB', 'GB', 'TB' );
######################## construct Process_Monitor object for writing to log file ###########

my $Report = Process_Monitor->new( -variation => $version, -configs => $Config );

_main();

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

################
# Main function
################
sub _main {
    if ($help) { _print_help_info() }
    elsif ( $Mode && $Mode !~ /detail|summary|view/i ) {
        $Report->set_Error("Invalid mode specified. Type DB_monitor.pl -h for help info.");
        return;
    }

    #    elsif ($Mode =~ /view/i) {
    #        _generate_view(-log=>$Log_File,-hosts=>$Hosts,-dbases=>$opt_D,-tables=>$opt_T);
    #    }
    else {
        if ($opt_space) {
            foreach my $this_host ( split /,/, $host ) {

                my $pwd = SDB::DB_Access->get_password( -host => $this_host, -user => $user, -file => $login_file );
                if ( $Mode =~ /detail|summary/i ) {
                    $Report->set_Message("Host: $this_host");
                }

                my @databases;
                if ($dbase) {
                    $Report->set_Message("Database(s): $dbase");
                    @databases = split /,/, $dbase;
                }
                else {

                    # Get available database of this host
                    @databases = @{ _get_DB( -host => $this_host, -pwd => $pwd ) };
                    $Report->set_Message( "Database(s): (ALL) " . join( ',', @databases ) );

                }

                foreach my $dbase (@databases) {
                    if ( $dbase =~ /mysql50/i ) {next}
                    _check_space_usage( -host => $this_host, -dbase => $dbase, -pwd => $pwd );
                }
            }
        }

        if ($opt_records) {
            set_record_count();
        }
    }
    $Report->completed();
    $Report->DESTROY();
}

########################
sub set_record_count {
########################
    my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => 'cron_user' );
    $dbc->connect();

    my @tables = $dbc->tables();
    if ($table) { @tables = split ',', $table }
    foreach my $table (@tables) {
        my ($count) = $dbc->Table_find( $table, 'count(*)' );
        $dbc->Table_update( 'DBTable', 'Records', $count, "WHERE DBTable_Name = '$table'" );
        $Report->set_Detail("$count Records in $table\n");
    }
}

##############################
# Get databases of the host
##############################
sub _get_DB {
##############################
    my %args = @_;
    my $host = $args{-host};
    my $pwd  = $args{-pwd};
    my @databases;

    my $command = "$mysql_dir/mysql -h $host -u $user -p$pwd -e 'SHOW DATABASES'";
    my $fback = try_system_command( $command, -report => $Report );

    foreach my $line ( split /\n/, $fback ) {
        if ( $line =~ /(\w+)/ ) {
            my $dbase = $1;
            unless ( $dbase eq 'Database' ) {
                push( @databases, $dbase );
            }
        }
    }

    return \@databases;
}

##############################
# Checks database space usage
##############################
sub _check_space_usage {
##############################
    my %args = @_;

    my $host  = $args{-host};
    my $dbase = $args{-dbase};
    my $pwd   = $args{-pwd};

    if ( $Mode =~ /detail|summary/i ) {
        $Report->set_Detail("Getting usage info for database: $dbase");
    }

    my $total = 0;
    my $total_units;
    my $now = date_time();    #today();

    my $command = "$mysql_dir/mysql -h $host -u $user -p$pwd $dbase -e 'SHOW TABLE STATUS'";
    my $fback   = try_system_command( $command, -report => $Report );
    my $tables  = _get_Hash_ref( -text => $fback );

    my %table_list;
    if ($table) {
        %table_list = map { $_, 1 } split( /,/, $table );
    }

    foreach my $table (@$tables) {
        my $name = $table->{Name};
        if ( keys(%table_list) && !exists $table_list{$name} ) {next}

        my $size     = $table->{Data_length};
        my $max_size = $table->{Max_data_length};

        my $usage_percent;
        if ($max_size) {
            $usage_percent = $size / $max_size * 100;
            $usage_percent = sprintf( "%.2f", $usage_percent );
        }

        $total += $size;

        # Convert the units
        my $size_units;
        my $max_size_units;

        ( $size, $size_units ) = Custom_Convert_Units( -value => $size, -units => 'B', -scale => \@Size_Scale, -scale_units => \@Size_Scale_Units, -decimals => 2 );

        if ( $Mode =~ /detail/i ) {
            if ($max_size) {
                ( $max_size, $max_size_units ) = Custom_Convert_Units( -value => $max_size, -units => 'B', -scale => \@Size_Scale, -scale_units => \@Size_Scale_Units, -decimals => 2 );
            }

            if ($max_size) {
                $Report->set_Detail("$name: $size $size_units / $max_size $max_size_units ($usage_percent%)");
            }
            else {
                $Report->set_Detail("$name: $size $size_units");
            }
        }
        else {
            $Report->set_Detail("Host: '$host'\tDB: '$dbase'\tTable: '$name'\tSize: '$size $size_units'");
        }
    }

    ( $total, $total_units ) = Custom_Convert_Units( -value => $total, -units => 'B', -scale => \@Size_Scale, -scale_units => \@Size_Scale_Units, -decimals => 2 );
    $Report->set_Message("TOTAL SPACE USAGE\t\tHost: '$host'\tDB: '$dbase'\tSize: '$total $total_units'");

}

#
#################################
sub _get_Hash_ref {
#################################
    my %args  = @_;
    my $text  = $args{-text};
    my @lines = split "\n", $text;

    my $size      = @lines;
    my @header    = split "\t", $lines[0];
    my $col_count = @header;
    my @final;

    for my $index ( 1 .. $size - 1 ) {
        my %records;
        my @content = split "\t", $lines[$index];

        for my $sec_index ( 0 .. $col_count - 1 ) {
            $records{ $header[$sec_index] } = $content[$sec_index];
        }
        push @final, \%records;
    }
    return \@final;
}

#################################
# View usage growth from log file
#################################
sub _generate_view {
#################################
    my %args = @_;

    my $log    = $args{ -log };
    my $hosts  = $args{-hosts} || '';
    my $dbases = $args{-dbases} || '';
    my $tables = $args{-tables} || '';

    my %host_list;
    my %dbase_list;
    my %table_list;

    if ($hosts) {
        %host_list = map { $_, 1 } split( /,/, $hosts );
    }
    if ($dbases) {
        %dbase_list = map { $_, 1 } split( /,/, $dbases );
    }
    if ($tables) {
        %table_list = map { $_, 1 } split( /,/, $tables );
    }

    my $info = xml2pl($log);

    foreach my $host ( sort keys %$info ) {
        if ( keys(%host_list) && !exists $host_list{$host} ) {next}
        $Report->set_Detail( "*" x 50 );
        $Report->set_Detail("Host: $host");
        foreach my $dbase ( sort keys %{ $info->{$host} } ) {
            if ( keys(%dbase_list) && !exists $dbase_list{$dbase} ) {next}
            $Report->set_Detail( "*" x 10 );
            $Report->set_Detail("Database: $dbase");
            foreach my $table ( sort keys %{ $info->{$host}{$dbase}{tables} } ) {
                if ( keys(%table_list) && !exists $table_list{$table} ) {next}
                foreach my $date ( sort keys %{ $info->{$host}{$dbase}{tables}{$table} } ) {
                    $Report->set_Detail("- $info->{$host}{$dbase}{tables}{$table}{$date}{size} $info->{$host}{$dbase}{tables}{$table}{$date}{size_units} ($date)");
                }
            }
            $Report->set_Detail( "-" x 10 );
            $Report->set_Detail("Total space usage of database $dbase:");
            foreach my $date ( sort keys %{ $info->{$host}{$dbase}{totals} } ) {
                $Report->set_Detail("- $info->{$host}{$dbase}{totals}{$date}{size} $info->{$host}{$dbase}{totals}{$date}{size_units} ($date)");
            }
            $Report->set_Detail( "-" x 50 );
        }
    }
}

#########################
sub _print_help_info {
#########################
    print <<HELP;

File:  DB_monitor.pl
####################
This script monitors the space usage of databases.

Options:
##########

------------------------------
1) Databases information:
------------------------------
-H     A comma-delimited list of hosts to be monitored
-D     A comma-delimited list of databases to be monitored
-T     A comma-delimited list of tables to be monitored

---------------------------
2) Additional options:
---------------------------
-m     The mode that the script runs. Can be one of the followings (Default = detail):
       - detail:  Print out the total usage of the database as well as usage of each table
       - summary: Print out the total usage of the database
       - log:     Logs the usage growth of the databaes to a log file
-h     Print help info.

HELP
}

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

