#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
################################################################################

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";

use Data::Dumper;
use Getopt::Std;

use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::Process_Monitor;

use alDente::SDB_Defaults;
use vars qw(%Defaults %Configs);
use vars qw($opt_v $opt_help $opt_user $opt_host $opt_dbase $opt_test $opt_pass );

use Getopt::Long;
&GetOptions(
    'help'        => \$opt_help,
    'user=s'      => \$opt_user,
    'host=s'      => \$opt_host,
    'dbase=s'     => \$opt_dbase,
    'version|v=s' => \$opt_v,
    'test'        => \$opt_test,
);

my $dbase      = $opt_dbase;
my $host       = $opt_host;
my $user       = $opt_user || 'super_cron_user';
my $test       = $opt_test;
my $FROM_EMAIL = 'Query Monitor <aldente@bcgsc.ca>';
my $TO_EMAIL   = '<aldente@bcgsc.ca>';

### Constant time that queries should not exceed in seconds
my $WARNING_TIME = 900;
my $MAX_TIME     = 3600;
my $errs;

if ( $opt_help || !( $host && $dbase ) ) { help(); exit; }

if ( !$test ) {
    my $username = `whoami`;
    if ( $username !~ /aldente/ ) {
        print "Must run as 'aldente' user (not $username)\n";
        exit;
    }
}

my $dbc = new SDB::DBIO( -host => $host, -dbase => $dbase, -user => $user, -connect => 1 );

unless ($dbc) {
    Message "No database connection established. Exiting ... ";
    exit;
}

my $Report;

unless ($test) {
    $Report = Process_Monitor->new( -variation => $opt_v );
}

my $results = $dbc->get_Processlist();

my %pr_list = %$results if $results;
my $ids = $pr_list{Id};

my $size = int @$ids if $ids;
my $message = "Query Monitor: Process exceeding time limitations";
my $body;

for my $index ( 0 .. $size - 1 ) {
    my $time    = $pr_list{Time}[$index];
    my $query   = $pr_list{Info}[$index];
    my $command = $pr_list{Command}[$index];
    my $db      = $pr_list{db}[$index];
    my $id      = $pr_list{Id}[$index];
    my $p_user  = $pr_list{User}[$index];
    my $state   = $pr_list{State}[$index];
    my $p_host  = $pr_list{Host}[$index];

    if ( $time > $MAX_TIME && $query =~ /select/i && $query !~ /load/i ) {
        my $header  = "Process $id from user $p_user from host $p_host running on database $db has exceeded our time limitation ($time / $MAX_TIME) and will be killed";
        my $details = "(State :$state ) - $query";
        my $command = "KILL $id";
        $body .= $header . vspace() . $details . vspace(1) . "** COMMAND: $command" . vspace(5);

        if ($test) {
            Message $message ;
            Message $details;
            Message $command;
        }
        else {
            $Report->set_Error($message);
            $Report->set_Detail($details);
            $Report->set_Message($command);
            my $outcome = $dbc->execute_command( -command => $command );
            $Report->set_Detail($outcome);
            $body .= vspace(1) . $outcome;
        }
    }
    elsif ( $time > $WARNING_TIME && $query =~ /select/i && $query !~ /load/i ) {

        my $header  = "Process $id from user $p_user from host $p_host running on database $db has exceeded our warning time limitation ($time / $WARNING_TIME)";
        my $details = "(State :$state ) - $query";
        $body .= $header . vspace() . $details . vspace(5);

        $Report->set_Warning($message);
        $Report->set_Detail($details);

    }
    elsif ( $state =~ /Waiting for table metadata lock/i ) {
        my $header  = "Process $id from user $p_user from host $p_host is locked out of database due to database lock (lock time: $time)";
        my $details = "Query: $query";
        $body .= $header . vspace() . $details . vspace(5);
    }
}

if ($body) {
    alDente::Notification::Email_Notification( -to_address => $TO_EMAIL, -from_address => $FROM_EMAIL, -subject => $message, -body => $body, -content_type => "html" );
}

unless ($test) {
    unless ($errs) {
        $Report->succeeded();
        $Report->completed();
    }
    $Report->DESTROY();
}

exit;

#############
sub help {
    #############

    print <<HELP;
    
    ********
    Usage:  kill_runaway_queries.pl -host lims05  -dbase seqtest
    host and dbase are mandatory
    *********
    test : just to see the queries run and not execute them
    pass : mySQL password
    host
    dbase
    user
     

HELP
}
