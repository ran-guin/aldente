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
use SDB::HTML;
use RGTools::RGIO;
use SDB::CustomSettings;
use Plugins::JIRA::Jira;
use RGTools::HTML_Table;
use alDente::Subscription;

use vars qw( $opt_help $opt_since $opt_until );

&GetOptions(
    'help|h'  => \$opt_help,
    'since=s' => \$opt_since,
    'until=s' => \$opt_until,
);

my $help  = $opt_help;
my $since = $opt_since;
my $until = $opt_until;

if ($help) {
    &display_help();
    exit;
}

my $jira_user     = 'limsproxy';
my $jira_password = 'noyoudont';                         ## <CONSTRUCTION> remove hardcoding
my $jira_wsdl     = $Configs{'jira_wsdl'};
my $jira_link     = "http://gin.bcgsc.ca/jira/browse";

my $jira = Jira->new( -user => $jira_user, -password => $jira_password, -uri => $jira_wsdl, -proxy => $jira_wsdl );
$jira->login();

if ( !$since ) {                                         # default to start from last Monday
    $since = &get_last_Monday();
}
if ( !$until ) {                                         # default to current time
                                                         #$until = &today(1);
    my $latest_time = timestamp();
    my $year        = substr( $latest_time, 0, 4 );
    my $month       = substr( $latest_time, 4, 2 );
    my $day         = substr( $latest_time, 6, 2 );
    my $hour        = substr( $latest_time, 8, 2 );
    my $minute      = substr( $latest_time, 10, 2 );
    $until = "$year-$month-$day $hour:$minute";
}

my $report  = "";
my $result1 = $jira->get_report_by_status( -since => $since, -until => $until, -status => 'Closed', -type => 'Bug' );
my $result2 = $jira->get_report_by_status( -since => $since, -until => $until, -status => 'Closed', -type => 'New Feature' );
my $result3 = $jira->get_report_by_status( -since => $since, -until => $until, -status => 'Closed', -type => 'Task' );
my $result4 = $jira->get_report_by_status( -since => $since, -until => $until, -status => 'Closed', -type => 'Improvement' );
my $count1  = scalar keys %$result1;
my $count2  = scalar keys %$result2;
my $count3  = scalar keys %$result3;
my $count4  = scalar keys %$result4;

my $link = "";

my $table = new HTML_Table();
$table->Set_Title("<H3> JIRA Work Completion Report ($since - $until) </H3>");
$table->Set_Headers( [ "Issue Type", "Number of Issues" ] );
$table->Set_Row( [ " ",           " " ] );
$table->Set_Row( [ 'Bug',         $count1 ] );
$table->Set_Row( [ 'New Feature', $count2 ] );
$table->Set_Row( [ 'Task',        $count3 ] );
$table->Set_Row( [ 'Improvement', $count4 ] );
$table->Set_Row( [ " ",           " " ] );

my $table1 = new HTML_Table();
$table1->Set_Title("<H3> List of New Features ($since - $until) </H3>");
$table1->Set_Headers( [ "Issue Type", "Key", "Summary", "Assignee" ] );
$table1->Set_Row( [ " ", " ", " ", " " ] );

my $table2 = new HTML_Table();
$table2->Set_Title("<H3> List of Improvements ($since - $until) </H3>");
$table2->Set_Headers( [ "Issue Type", "Key", "Summary", "Assignee" ] );
$table2->Set_Row( [ " ", " ", " ", " " ] );

while ( my ( $key, $value ) = each(%$result2) ) {
    $table1->Set_Row( [ 'New Feature', Link_To( "$jira_link/$key", "$key" ), $value->[1], $value->[2] ] );
}
while ( my ( $key, $value ) = each(%$result4) ) {
    $table2->Set_Row( [ 'Improvement', Link_To( "$jira_link/$key", "$key" ), $value->[1], $value->[2] ] );
}

#$report .= $table->Printout();

$table->Printout();
if ( $count2 > 0 ) { $table1->Printout() }

#create_tree( -tree => { 'Bug' => $result1 }, -print => 1 );
#create_tree( -tree => { 'New Feature' => $result2 }, -print => 1 );
#create_tree( -tree => { 'Task' => $result3 }, -print => 1 );
#create_tree( -tree => { 'Improvement' => $result4 }, -print => 1 );
if ( $count4 > 0 ) { $table2->Printout() }

exit;

sub get_last_Monday {
    my $seconds_in_a_day = 24 * 60 * 60;
    my $time             = time();
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime($time);
    my $last;

    # On Sunday or Monday, the last Monday returned is the Monday in previous week.
    # On other weekdays, the last Monday returned is the Monday in the current week.
    if    ( $wday == 0 ) { $wday = 7; }
    elsif ( $wday == 1 ) { $wday = 8; }
    my $offset = $wday - 1;
    my $last_monday = &date_time( -offset => "-$offset" . "d" );

    return substr( $last_monday, 0, 10 );
}

sub display_help {
    print <<HELP;

Syntax
======
create_closed_jira_report.pl (This script generates a JIRA work completion report in HTML).

Arguments:
=====

-- optional arguments --
-help, -h, -?	: displays this help.
-since		: specify the start date, hour, and minute. Default is last Monday at 00:00 (HH:mm).
-until		: specify the end date, hour, and minute. Default is current time.

Example
=======
1. To generate a report of all the closed JIRA issues since a given time:

create_closed_jira_report.pl -since 'yyyy-MM-dd HH:mm' > JIRA_Report.html

2. To generate a report of all the closed JIRA issues between two given times:

create_closed_jira_report.pl -since 'yyyy-MM-dd HH:mm' -until 'yyyy-MM-dd HH:mm'> JIRA_Report.html

Note
=======

When hour and minute are not specified i.e. only 'yyyy-MM-dd'. It implies HH:mm of 00:00.
e.g.

'2010-02-28' implies '2010-02-28 00:00'


HELP
}

