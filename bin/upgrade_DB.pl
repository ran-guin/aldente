#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

upgrade_DB.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>

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
use strict;
use Getopt::Std;
use Storable;
use Data::Dumper;
use DBI;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";

use SDB::DBIO;
use SDB::HTML;
use SDB::Installation;
use RGTools::RGIO;
use RGTools::Process_Monitor;
use alDente::SDB_Defaults;
use Getopt::Long;
use SDB::CustomSettings qw(%Configs);

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_v $opt_user $opt_pass $opt_dbase $opt_host $opt_debug $opt_help $opt_test $opt_F $opt_version $opt_match $opt_prompt $opt_continue);
use vars qw($monitor_name);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

&GetOptions(
    'v=s'       => \$opt_v,
    'user=s'    => \$opt_user,
    'pass=s'    => \$opt_pass,
    'dbase=s'   => \$opt_dbase,
    'host=s'    => \$opt_host,
    'debug'     => \$opt_debug,
    'continue'  => \$opt_continue,
    'help'      => \$opt_help,
    'test'      => \$opt_test,
    'match'     => \$opt_match,
    'prompt'    => \$opt_prompt,
    'version=s' => \$opt_version,
);

my $variation = $opt_v;
my $host      = $opt_host || $Configs{DEV_HOST};
my $database  = $opt_dbase || $Configs{DEV_DATABASE};
my $user      = $opt_user;
my $password;
my $debug       = $opt_debug;
my $test        = $opt_test;
my $version     = $opt_version;
my $prompt_mode = $opt_prompt;
my $continue    = $opt_continue;

if ( !$opt_v || $opt_help ) {

    print <<END;

File:  upgarde_DB.pl
###################


Usage:
######
perl upgarde_DB.pl -v <Variation> -host lims02 -dbase seqtest -user super_cron -pass *******

Options:
#########
Mandatory:
-variation        
-host
-dbase
-pass
-user
Optional :
-version    target version
-debug      Outputs details of actions going on
-test       Cuts off connection to SVN and doesnt update or commit version_tracker file
-match      Match patches to patches installed on production database
-prompt     Run in prompt mode - ask for verification at each step...
-continue   Continue to install next releases from the current version

END

    exit;
}
#############################
# Optional addon-package details
#############################

################## construct Process_Monitor object for writing to log file ##################################
######## Set variables used throughout script
my $Report;

my $whoami = `whoami`;
if ( $whoami !~ /aldente/ ) { print "Please run as aldente user\n"; exit; }

$Report = Process_Monitor->new( -testing => $test, -variation => $variation );
$Report->set_Message("Report created: logged to $Report->{log_file}");

if ( $database =~ /sequence/ ) {
    print "Are you sure you want to upgrade the '$database' database on '$host'? (y/n)";
    my $ans = Prompt_Input( -type => 'char' );
    unless ( $ans =~ /y|Y/ ) {
        $Report->set_Message("Declined to upgrade the '$database' database on '$host'");
        $Report->DESTROY();
        exit;
    }
}
unless ($user) {
    $user = Prompt_Input( -prompt => 'Username: ' );
}
if ($opt_pass) {
    $password = $opt_pass;
}

_main();

$Report->completed();
$Report->DESTROY();
exit;

######################
sub _main {
######################
    $monitor_name = "Upgrade_DB";
    my $dbc = new SDB::DBIO(
        -host    => $host,
        -dbase   => $database,
        -user    => $user,
        -connect => 1
    );
    unless ($dbc) {
        $Report->set_Error("No database connection stablished. Exiting ... ");
        exit;
    }

    my $dir      = $FindBin::RealBin;
    my $core_dir = $dir . '/../install/patches/Core/';

    if ($continue) {
        my $command = "ls $core_dir";
        my @versions = split "\n", try_system_command(qq{$command});
        @versions = SDB::Installation::version_sort( \@versions );
        $version = Cast_List( -list => \@versions, -to => 'string', -autoquote => 0 );
    }

    if ($version) {
        my $command = "ls $core_dir";
        my @versions = split "\n", try_system_command(qq{$command});
        @versions = SDB::Installation::version_sort( \@versions );
        my $version_list = Cast_List( -list => \@versions, -to => 'string', -autoquote => 0 );
        @versions = split $version, $version_list;
        $version = $versions[0] . $version;
    }

    my $install = new SDB::Installation( -dbc => $dbc, -simple => 1, -report => $Report, -prompt => $prompt_mode );
    $install->upgrade_DB( -test => $test, -debug => $debug, -version => $version, -match => $opt_match );
    return;
}

exit;
