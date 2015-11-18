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
### Reference to standard Perl modules
use strict;
use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Notification;
use SDB::CustomSettings;
 
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Process_Monitor;

use XML::Dumper;

# Get options
use Getopt::Long;
use vars qw($opt_space $opt_records $opt_host $opt_mode $opt_user $opt_pwd $opt_dbase $opt_table $help);

&GetOptions(
    'dbase|D=s'   => \$opt_dbase,
    'table|T=s'   => \$opt_table,
    'host|H=s'    => \$opt_host,
    'mode|m=s'    => \$opt_mode,
    'user|u=s'    => \$opt_user,
    'pwd|p=s'    => \$opt_pwd,
    'space'     => \$opt_space,
    'records'   => \$opt_records,
    'help|h'    => \$help,
    );

my $host = $opt_host;
my $dbase = $opt_dbase;
my $table = $opt_table || '';
my $Mode = $opt_mode || 'detail';
my $user = $opt_user || 'viewer';
my $pwd = $opt_pwd || 'viewer';

print "Host: $host, Dbase: $dbase, Table(s): $table, Mode: $Mode, User: $user\n";

use vars qw($administrator_email);
### Modular variables
my @Size_Scale = (1,1024,1024**2,1024**3,1024**4);
my @Size_Scale_Units = ('B','KB','MB','GB','TB');
######################## construct Process_Monitor object for writing to log file ###########

my $Report = Process_Monitor->new('DB_monitor.pl Script');

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
    if ($help) {_print_help_info()}
    elsif ($Mode && $Mode !~ /detail|summary|view/i) {
	$Report->set_Error("Invalid mode specified. Type DB_monitor.pl -h for help info.");
	return;
    }
#    elsif ($Mode =~ /view/i) {
#        _generate_view(-log=>$Log_File,-hosts=>$Hosts,-dbases=>$opt_D,-tables=>$opt_T);
#    }
    else {
        if ($opt_space) {
	  foreach my $this_host (split /,/, $host) {
	    if ($Mode =~ /detail|summary/i) {
                $Report->set_Message("Host: $this_host");
	    }

	    my @databases;
	    if ($dbase) {
                $Report->set_Message("Database(s): $dbase");
		@databases = split /,/, $dbase;
	    }
	    else {
		# Get available database of this host
		@databases = @{_get_DB(-host=>$this_host)};
                $Report->set_Message("Database(s): (ALL) " . join(',',@databases));
	    }
	    
	    foreach my $dbase (@databases) {
		_check_space_usage(-host=>$this_host,-dbase=>$dbase);
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

sub set_record_count {
    
    my $dbc = SDB::DBIO->new();
    $dbc->connect(-host=>$host,-dbase=>$dbase,-user=>"$user",-password=>$pwd);
    my @tables = $dbc->tables();
    if ($table) { @tables = split ',', $table }
    foreach my $table (@tables) {
        my ($count) = $dbc->Table_find($table,'count(*)');
        $dbc->Table_update('DBTable','Records',$count,"WHERE DBTable_Name = '$table'");
        $Report->set_Detail("$count Records in $table\n");
    }
}

##############################
# Get databases of the host
##############################
sub _get_DB {
    my %args = @_;

    my $host = $args{-host};

    my @databases;

    my $command = "$mysql_dir/mysql -h $host -u $user -p$pwd -e 'SHOW DATABASES'";
    my $fback = try_system_command($command,-report=>$Report);

    foreach my $line (split /\n/, $fback) {
	if ($line =~ /(\w+)/) {
	    my $dbase = $1;
	    unless ($dbase eq 'Database') {
		push(@databases, $dbase); 
	    }
	}
    }

    return \@databases;
}

##############################
# Checks database space usage
##############################
sub _check_space_usage {
    my %args = @_;
    
    my $host = $args{-host};
    my $dbase = $args{-dbase};

    my $dbc = SDB::DBIO->new();
    $dbc->connect(-host=>$host,-dbase=>$dbase,-user=>"$user",-password=>$pwd);

    if ($Mode =~ /detail|summary/i) {
        $Report->set_Detail("Getting usage info for database: $dbase");
    }

    my $total = 0;
    my $total_units;
    my $now = date_time(); #today();

    my $sth = $dbc->query(-query=>'SHOW TABLE STATUS',-finish=>0);
    my $tables = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'AofH');

    my %table_list;
    if ($table) {%table_list = map { $_,1 } split(/,/, $table)}

    foreach my $table (@$tables) {
	my $name = $table->{Name};
	if (keys(%table_list) && !exists $table_list{$name}) {next}

	my $size = $table->{Data_length};
	my $max_size = $table->{Max_data_length};

	my $usage_percent;
	if ($max_size) { 
	    $usage_percent = $size / $max_size * 100;
	    $usage_percent = sprintf("%.2f",$usage_percent);
	}

	$total += $size;

	# Convert the units
	my $size_units;
	my $max_size_units;

	($size,$size_units) = Custom_Convert_Units(-value=>$size,-units=>'B',-scale=>\@Size_Scale,-scale_units=>\@Size_Scale_Units,-decimals=>2);

	if ($Mode =~ /detail/i) {
	    if ($max_size) {
		($max_size,$max_size_units) = Custom_Convert_Units(-value=>$max_size,-units=>'B',-scale=>\@Size_Scale,-scale_units=>\@Size_Scale_Units,-decimals=>2);
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

    ($total,$total_units) = Custom_Convert_Units(-value=>$total,-units=>'B',-scale=>\@Size_Scale,-scale_units=>\@Size_Scale_Units,-decimals=>2);
    $Report->set_Message("TOTAL SPACE USAGE\t\tHost: '$host'\tDB: '$dbase'\tSize: '$total $total_units'");

    $dbc->disconnect();
}

#################################
# View usage growth from log file
#################################
sub _generate_view {
    my %args = @_;

    my $log = $args{-log};
    my $hosts = $args{-hosts} || '';
    my $dbases = $args{-dbases} || '';
    my $tables = $args{-tables} || '';
    
    my %host_list;
    my %dbase_list;
    my %table_list;

    if ($hosts) {%host_list = map { $_,1 } split(/,/, $hosts)}
    if ($dbases) {%dbase_list = map { $_,1 } split(/,/, $dbases)}
    if ($tables) {%table_list = map { $_,1 } split(/,/, $tables)}

    my $info = xml2pl($log);

    foreach my $host (sort keys %$info) {
	if (keys(%host_list) && !exists $host_list{$host}) {next}
        $Report->set_Detail("*"x50);
        $Report->set_Detail("Host: $host");
	foreach my $dbase (sort keys %{$info->{$host}}) {
	    if (keys(%dbase_list) && !exists $dbase_list{$dbase}) {next}
            $Report->set_Detail("*"x10);
            $Report->set_Detail("Database: $dbase");
	    foreach my $table (sort keys %{$info->{$host}{$dbase}{tables}}) {
		if (keys(%table_list) && !exists $table_list{$table}) {next}
		foreach my $date (sort keys %{$info->{$host}{$dbase}{tables}{$table}}) {
		    $Report->set_Detail("- $info->{$host}{$dbase}{tables}{$table}{$date}{size} $info->{$host}{$dbase}{tables}{$table}{$date}{size_units} ($date)");
		}
	    }
	    $Report->set_Detail("-"x10);
	    $Report->set_Detail("Total space usage of database $dbase:");
	    foreach my $date (sort keys %{$info->{$host}{$dbase}{totals}}) {
		$Report->set_Detail("- $info->{$host}{$dbase}{totals}{$date}{size} $info->{$host}{$dbase}{totals}{$date}{size_units} ($date)");
	    }
            $Report->set_Detail("-"x50);
	}
    }
}

#########################
sub _print_help_info {
#########################
print<<HELP;

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


