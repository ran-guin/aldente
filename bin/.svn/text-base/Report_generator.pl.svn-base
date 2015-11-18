#!/usr/local/bin/perl
#
# This script generates reports using the existing alDente web interface.
#
# It simply extracts dynamically generated files that are dumped to the tmp directory and attaches them to an email notification.
# (it also copies a version of the file to the share directory so it can be accessed using the internal css formatting)
#
# It does require a 'Printable version' of the table of interest to be generated based upon the supplied parameters.
#
# Report specifications are defined within the Report table in the database.
#
# <CONSTRUCTION>
#
# The css formatting should also be enabled as in-line html to make the default views and attachments more cleanly viewable.
#
###################################################################################################################################

use strict;
use DBI;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";

use RGTools::RGIO;
use alDente::Notification;
use SDB::CustomSettings;
use SDB::Report;

use RGTools::Process_Monitor;
use alDente::Subscription;

use vars qw($opt_help $opt_quiet $opt_test $opt_report $opt_dbase $opt_host $opt_ext);

use Getopt::Long;
&GetOptions(
    'help'     => \$opt_help,
    'quiet'    => \$opt_quiet,
    'test'     => \$opt_test,
    'report=s' => \$opt_report,
);

use vars qw(%Configs);

my $help   = $opt_help;
my $quiet  = $opt_quiet;
my $test   = $opt_test;
my $report = $opt_report;
my $ext    = $opt_ext;    ## optional - include all extensions found by default ...

my $master = $Configs{PRODUCTION_HOST};
my $slave  = $Configs{BACKUP_HOST};
my $dbase  = $Configs{PRODUCTION_DATABASE};
my $user   = 'cron_user';
my $pwd;

print "$master/$slave : $dbase ($user)\n";

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host    => $slave,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

my $dbc_master = new SDB::DBIO(
    -host    => $master,
    -dbase   => $dbase,
    -user    => 'super_cron_user',
    -connect => 1,
);

my $db;
if    ( $dbc->is_Connected )        { $db  = $dbc;        Message("Using Slave"); }
elsif ( $dbc_master->is_Connected ) { $db = $dbc_master; Message("Using Master"); }
else                                { Message("No Database connection found"); exit; }

my $temp_dir   = "dynamic/tmp";
my $report_dir = "dynamic/share";

my $full_temp_dir   = $Configs{Web_home_dir} . "/$temp_dir";
my $full_report_dir = $Configs{Web_home_dir} . "/$report_dir";

my $condition = 1;
if ($report) { $condition = "Extract_File = '$report'" }

my %reports = $db->Table_retrieve(
    'Report',
    [ 'Report_ID', 'Target', 'Extract_File', 'Report_Frequency', 'Report_Sent', "CASE WHEN DATE(AddDate(Report_Sent, INTERVAL Report_Frequency DAY)) > CURDATE() THEN 'NO' ELSE 'YES' END as Send" ],
    "WHERE $condition",
    -debug => $test
);

if ( !defined $reports{Report_ID}[0] ) {
    Message("No Reports to generate");
    exit;
}

my $Report = Process_Monitor->new( -no_log => 1 );
$Report->set_Message("Generating $report report for database $dbase (Master: $master - Slave: $slave) ");

my $index = 0;
while ( defined $reports{Report_ID}[$index] ) {
    my $target    = $reports{Target}[$index];
    my $extract   = $reports{Extract_File}[$index];
    my $frequency = $reports{Report_Frequency}[$index];
    my $sent      = $reports{Report_Sent}[$index];
    my $send      = $reports{Send}[$index];
    my $id        = $reports{Report_ID}[$index];
    $index++;

    Message("Report $id ($extract -> $target)");
    unless ( $send eq 'YES' ) {
        $Report->set_Message("Report $id not sent (sent $sent)\n");
        next;
    }

    sleep(1);
    my @files = SDB::Report::load_DB_Report( -dbc => $db, -report_id => $id, -extension => 'html,xml,xls,xlsx' );
    Message( "\nfound " . int(@files) . " files for report $id" );

    ## replace standard tags in parameters string ##

    my $content;
    my %Attachments;
    my $attachment_type;
    if (@files) {
        foreach my $file (@files) {
            my $filename = $file;
            my $ext      = '';
            if ( $file =~ /(.*)\/(.+?)\.(\w+)$/ ) { $filename = "$2.$3"; $ext = $3; }
            Message("** Found File: $filename **");

            Message("copy '$file' to to $full_report_dir/ ...");
            try_system_command("cp '$file' $full_report_dir/");

            if ( $file =~ /\.html$/ ) {
                if ( $file =~ /LIMS_End_to_End_Report_Clinical/i ) {
                    ## do not include the html report content in the email body for LIMS_End_to_End_Report_Clinical, since it is too large to display
                }
                else {
                    my $local_content = try_system_command("cat $file");
                    $content = $local_content . '<HR>' . $content;
                }
            }
            else {
                ## for LIMS_End_to_End_Report_Clinical report, compress the file and include it as an attachment
                if ( $file =~ /LIMS_End_to_End_Report_Clinical/i ) {    # include as attachment
                    my $compressed_file = $file . '.zip';
                    try_system_command("zip -j $compressed_file $file");
                    my $local_name = '.zip';
                    if ( $compressed_file =~ /([^\/]+)$/ ) {
                        $local_name = $1;
                    }
                    $Attachments{"$compressed_file"} = $local_name;
                    $attachment_type = 'x-gzip';
                }
            }

            $content .= "Link to:\n<A Href='http://limsmaster.bcgsc.ca/SDB/$report_dir/$filename'>$ext version</A><HR>";

            $Report->set_Message("*** cp $file -> $report_dir");
        }

        Message("Send email notification to $target (+ aldente");
        &alDente::Notification::Email_Notification(
             $target, 'LIMS Reporter <aldente@bcgsc.ca>',
            -subject         => "Report Auto-generated for $target",
            -body            => 'This report is autogenerated.  Please notify LIMS staff (aldente@bcgsc.ca) to change the report parameters or frequency' . "<HR>$content",
            -content_type    => 'html',
            -dbc             => $dbc_master,
            -attachments     => \%Attachments,
            -attachment_type => $attachment_type
        );

        my $timestamp = date_time();
        Message("Update Report Table");
        $dbc_master->Table_update_array( 'Report', ['Report_Sent'], [$timestamp], "WHERE Report_ID = $id", -autoquote => 1 );
    }
    else {
        print "$extract file(s) not found in output\n";
        $Report->set_Warning("$extract not found in output");
    }
}
$Report->completed();
$Report->DESTROY();

exit;

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    <script> [options]

Mandatory Input:
**************************

Options:
**************************     


Examples:
***********

HELP

}
