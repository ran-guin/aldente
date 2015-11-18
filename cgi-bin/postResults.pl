#!/usr/local/bin/perl

use strict;
use warnings;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use CGI qw(:standard);
use alDente::Notification;
use RGTools::Process_Monitor;
use SDB::HTML;


# set up the process monitor for this script.
my $Report = Process_Monitor->new( -title    => 'Selenium Test Runner Results',
                                   -quiet    => 1,                                                 # we don't want Process Monitor data in the cgi-script output
                                   -verbose  => 0,
                                   -cron_dir => '/home/aldente/public/logs/selenium/cron_logs',    # we define this since the limsweb user can't
                                                                                                   # write to the default cron directory
                                 );

my $timestamp = time();
write_results( CGI->new, "/home/aldente/public/logs/selenium/selenium_results.$timestamp.log" );

$Report->completed();
$Report->DESTROY();

exit;

###################
sub write_results {
###################
    
    my ( $q, $log_filename ) = @_;

    # start the HTML page.  This must come before emailing the report, since send_notification_email() prints error messages
    print $q->header();
    print $q->start_html( 'Posting Selenium Test Runner Results' );

    # create the HTML report for the results
    my $html_report = create_html_report($q);    
    
    # if there are any failures or incomplete tests, send an email
    my $tests_failed = ( $q->param('numTestFailures') > 0 || $q->param('numCommandFailures') > 0 || $q->param('numCommandErrors') > 0 ); 

    if ( $tests_failed ) {
        my $email_result =  send_notification_email( $html_report, $q->param('numCommandFailures'), $q->param('numTestFailures') );
    }

    # Save results to the log file
    open ( my $LOGFILE, ">>", "$log_filename" ) || print "Can't open $log_filename: $!";
    
    my $date = localtime;
    print $LOGFILE "<html><head><title>Selenium results from $date</title></head><body>\n" || print "Can't print to $log_filename: $!";
    print $LOGFILE $html_report;
    print $LOGFILE "</body></html>";

    close $LOGFILE || print "Can't close $log_filename: $!";

    # print the report to the browser/terminal
    print $html_report;

}

#############################
sub send_notification_email {
#############################

    my ( $report, $num_commands_failed, $num_tests_failed ) = @_;

    # send notification
    my $header  = "Content-type: text/html\n\n";
    my $subject = "Selenium Functional Testing:  $num_commands_failed Failed Commands in $num_tests_failed Tests";
    my $ok      = &alDente::Notification::Email_Notification( -to_address   => "aldente\@bcgsc.ca",
                                                              -cc_address   => "aldente\@bcgsc.ca",
                                                              -from_address => "aldente\@bcgsc.ca",
                                                              -subject      => $subject,
                                                              -body_message => $report,
                                                              -header       => $header,
                                                              -verbose      => 0,
                                                          );
    
    if (!$ok) { print "<h1>Warning: Could not send email!</h1>" }
    

    
}

########################
sub create_html_report {
########################

    my ($q) = @_;

    # CSS definitions for the email
    my $email_style = "<style>
            body, table, td          { font-family: Verdana, Arial, sans-serif; font-size: 8pt;}
            tr.summary       td      { border: 2px solid #ccc; font-size: 10pt; padding: 0px 1em; }
            tr.summary td.failed     { color: #F66; font-weight: bold;}
            tr.summary td.passed     { color: #0c0; font-weight: bold }
            tr.summary td.incomplete { color: #f90; font-weight: bold }
            tr.summary td.empty      { border: none; }
            tr.status_failed td      { background-color: #F99; }
            tr.status_done   td      { background-color: #cFc; }
            tr.status_passed td      { background-color: #9F9; }
            tr.title         td      { background-color: #FFF; font-weight: bold; text-align: center; border: 2px solid #ccc; }
            span.failed              { color: #F66; }
            h1, h2                   { margin-bottom: 0px; }
        </style>";

    # change the time from seconds to a readable hh::mm::ss format
    my $seconds_elapsed = $q->param('totalTime');
    my @time_parts      = gmtime( $seconds_elapsed );
    
    my $elapsed_time    = sprintf( '%02d', $time_parts[2] ) . ":"  # hours
                        . sprintf( '%02d', $time_parts[1] ) . ":"  # minutes
                        . sprintf( '%02d', $time_parts[0] );       # seconds
    
    # figure out the total number of tests
    my $num_tests_passed = $q->param('numTestPasses');
    my $num_tests_failed = $q->param('numTestFailures');
    my $total_tests      = $num_tests_passed + $num_tests_failed;

    my $num_commands_passed = $q->param('numCommandPasses');
    my $num_commands_failed = $q->param('numCommandFailures');
    my $num_commands_error  = $q->param('numCommandErrors');
    my $total_commands      = $num_commands_passed + $num_commands_failed + $num_commands_error;

    # set styles depending on number of errors
    my $failed_tests_class        = ( $num_tests_failed    > 0 ) ? "failed"     : "";
    my $failed_commands_class     = ( $num_commands_failed > 0 ) ? "failed"     : "";
    my $incomplete_commands_class = ( $num_commands_error  > 0 ) ? "incomplete" : "";

    # We're going to set the Process Monitor report stuff here, since all the data is figured out in the above section.
    $Report->set_Detail( "$total_tests tests run containing $total_commands commands." );

    if ($num_tests_failed) {
        $Report->set_Error( "$num_tests_failed tests failed with $num_commands_failed failed commands and $num_commands_error incomplete commands" );
    }

    # Process Monitor: add in a success for each test that passed
    for (1..$num_tests_passed) {
        $Report->succeeded();
    }
    
    # body of email
    my $email_text = "";
    $email_text   .= "<h1 class=\"failed\">Selenium Functional Test Results</h1>";
    $email_text   .= "<h2>Summary</h2>
        <table>
            <tr class=\"summary\">
                <td>$total_tests tests run</td>
                <td class=\"passed\">$num_tests_passed tests passed</td>
                <td class=\"$failed_tests_class\">$num_tests_failed tests failed</td>
                <td>Time: $elapsed_time</td>
            </tr>
            <tr class=\"summary\">
                <td>$total_commands commands run</td>
                <td class=\"passed\">$num_commands_passed commands passed</td>
                <td class=\"$failed_commands_class\">$num_commands_failed commands failed</td>
                <td class=\"$incomplete_commands_class\">$num_commands_error commands incomplete</td>
            </tr>
        </table>";


    $email_text .= "<h2>Test Details</h2>";
    
    # print each of the test tables
    my $i = 0;
    while (1) {
        $i++;
        my $test_table = $q->param("testTable.$i");

        last unless $test_table;

        $email_text .= $test_table;

    } 

    my $html_report = $email_style . $email_text;

    return $html_report;
    
}

1;
