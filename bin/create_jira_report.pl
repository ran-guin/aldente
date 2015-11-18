#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::DBIO;
use RGTools::RGIO;
use SDB::CustomSettings;
use Plugins::JIRA::Jira;
use RGTools::HTML_Table;
use alDente::Subscription;

use vars qw( $opt_help $opt_group_by $opt_host $opt_dbase $opt_user $opt_debug $opt_since $opt_until );

&GetOptions(
    'help|h'       => \$opt_help,
    'group_by|g=s' => \$opt_group_by,
    'host=s'       => \$opt_host,
    'dbase|d=s'    => \$opt_dbase,
    'user|u=s'     => \$opt_user,
    'debug'        => \$opt_debug,
    'since=s'      => \$opt_since,
    'until=s'      => \$opt_until,
);

my $help     = $opt_help;
my $group_by = $opt_group_by;
my $host     = $opt_host;
my $dbase    = $opt_dbase;
my $user     = $opt_user;
my $debug    = $opt_debug;
my $since    = $opt_since;
my $until    = $opt_until;

if ($help) {
    &display_help();
    exit;
}

if ( !$debug && ( !$host || !$dbase || !$user ) ) {
    print "Database connection information is required! Please specify host, database, and user name!\n\n";
    &display_help();
    exit;
}

if ( defined $group_by && $group_by ne 'type' && $group_by ne 'assignee' ) {
    print "Sorry, the current group_by options only support 'type' and 'assignee'!\n ";
    exit;
}

my $jira_user     = 'limsproxy';
my $jira_password = 'noyoudont';             ## <CONSTRUCTION> remove hardcoding
my $jira_wsdl     = $Configs{'jira_wsdl'};

my $jira = Jira->new( -user => $jira_user, -password => $jira_password, -uri => $jira_wsdl, -proxy => $jira_wsdl );
$jira->login();

my $issue_types = $jira->get_issue_types();      # get the type_id => type mapping
my $subtasks    = $jira->get_LIMS_subtasks();    # get the subtask => parent mapping

## default options
my @groups;
if ($group_by) { push @groups, $group_by }
else           { push @groups, ( 'type', 'assignee' ) }

if ( !$since ) {                                 # default to start from last Monday
    $since = &get_last_Monday();
}
if ( !$until ) {                                 # default to today
    $until = &today();
}

my $report = "";
foreach my $group (@groups) {
    my $result = $jira->get_stat( -since => $since, -until => $until, -group_by => $group, -issue_types => $issue_types, -subtasks => $subtasks );

    my $table = new HTML_Table();
    $table->Set_Title("<H3> JIRA Work Report By $group ($since - $until) </H3>");
    $table->Set_Headers( [ $group, "Number Tickets", "Total Time Spent", "Total Time Estimated" ] );
    $table->Set_Row( [ " ", " ", " ", " " ] );
    foreach my $key ( keys %{$result} ) {
        $table->Set_Row( [ $key, $result->{$key}{count}, $result->{$key}{time_spent}, "N/A" ] );
    }
    $report .= $table->Printout();
}

# get dbc connection for send_notification() use only
my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

## send out notice
my $subject = "JIRA Work Report ( $since - $until ) (from Subscription Module) - Test";
my $name    = "JIRA Work Report";
my $from    = "JIRA Work Report <aldente\@bcgsc.ca>";

alDente::Subscription::send_notification( -dbc => $dbc, -name => $name, -from => $from, -subject => $subject, -body => $report, -content_type => 'html' );

exit;

sub get_last_Monday {
    my $seconds_in_a_day = 24 * 60 * 60;
    my $time             = time();
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime($time);
    my $last;

    $wday = 7 if ( $wday == 0 );
    my $offset = $wday - 1;
    my $last_monday = &date_time( -offset => "-$offset" . "d" );

    return substr( $last_monday, 0, 10 );

}

sub display_help {
    print <<HELP;

Syntax
======
create_jira_report.pl - This script generates JIRA work report.

Arguments:
=====

-- required arguments --
-host				: specify database host, ie: -host lims02 
-dbase, -d			: specify database, ie: -dbase sequence 
-user, -u			: specify database user. 


-- optional arguments --
-help, -h, -?		: displays this help. (optional)
-group_by, -g		: specify the grouping. Two valid options: 'type' and 'assignee'. If this is not entered, the report will be generated on both options.
-debug				: flag for debugging
-since				: specify the start day. Default is the last Monday.
-until				: specify the end day. Default is today.

Example
=======
create_jira_report.pl -h lims02 -d seqtest -u viewer 
create_jira_report.pl -h lims02 -d seqtest -u viewer -g 'assignee'
create_jira_report.pl -h lims02 -d seqtest -u viewer -since 2010-03-22 -until 2010-03-26 


HELP
}

