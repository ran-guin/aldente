#!/usr/local/bin/perl58

############################
#
# generate_gelrun_stats.pl
#
# This script is responsible for generating an HTML page called 'stats.html' and storing it in the Run_Directory of different Gel Runs.
#  By default it'll generate stats for runs that were analyzed in the past two days
#
# This stats.html page currently will show up as a slide down for gel images in the summary view
#
# This script should be running off one of the xhost machines, since it is written and maintaned by MapDev
#
############################

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Imported/SOAP";

use Data::Dumper;
use XMLRPC::Lite;
use vars qw($opt_update $opt_run_id);
use vars qw($testing $Connection $uploads_dir);

use Getopt::Long;
&GetOptions(
    'update'   => \$opt_update,
    'run_id=s' => \$opt_run_id,
);
my $update = $opt_update || 0;

my $web_service_client = XMLRPC::Lite->proxy("http://lims02.bcgsc.ca/SDB/cgi-bin/Web_Service.pl");

my $report_script = '/home/mapper/www/cgi-bin/intranet/limsaids/gel_report.pl';

## Creating a login object
my $login = $web_service_client->call( 'lims_web_service.login', { 'username' => 'testlims', 'password' => 'testlims' } )->result;

my $today = &date_time();

#Check for log file and if log file exist and it was generate before 6 minutes ago then run updates
my $log_dir = '/home/mapper/Logs/autopass/';
my @files   = `find $log_dir -mmin -6 -type f`;
if (@files) {
    $update = 1;
}
if ($update) {

    #my $yesterday = &date_time(-offset=>'-2d');
    my $yesterday      = '0000-00-00 00:00:00';
    my @run_qc_status  = qw (Pending Failed Re-Test Passed);
    my $run_validation = 'Pending';
    my $run_status     = 'Data Acquired';
    my @run_ids;
    if ($opt_run_id) {
        @run_ids        = split( /,/, $opt_run_id );
        @run_qc_status  = ();
        $run_validation = '';
        $run_status     = '';
    }

    my $request = $web_service_client->call(
        'lims_web_service.mapping_api',
        $login,
        {   -db_user        => 'viewer',
            -db_password    => 'viewer',
            -dbase          => 'sequence',
            -fields         => 'full_run_path,run_time',
            -run_validation => $run_validation,
            -include        => 'production',
            -run_status     => $run_status,
            -run_qc_status  => \@run_qc_status,
            -method         => 'get_gelrun_data',
            -since          => $yesterday,
            -until          => $today,
            -run_id         => \@run_ids,
            -order          => 'Run_ID DESC',

        }
    )->result;

    if ($request) {
        my $index = -1;
        while ( $request->{Run_ID}[ ++$index ] ) {
            my $run_id   = $request->{Run_ID}[$index];
            my $run_path = $request->{full_run_path}[$index];
            print "$report_script 'run=$run_id&nomarkup=1' > $run_path/stats.html\n";
            `$report_script "run=$run_id&nomarkup=1" > $run_path/stats.html`;
        }

        #print $index;
    }
}

#########################
#
# Retrieves date_time in 'YYYY-MM-DD HH:MM:SS' format
#
# parameter allows you to specify forward or back (-) any number of
# seconds (s), minutes(m), hours(h) or days(d).
#
#  eg. date_time('-1d') retrieves the same time yesterday
#
##################
sub date_time {
##################
    my %args = @_;
    my $another_time = $args{-offset} || '';    # optional other time or +/- number of days

    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();

    if ( $another_time =~ /(\d+)(\s*w[eeks]*)/i ) {
        my $string = $2;
        my $weeks  = $1;
        my $days   = $weeks * 7;
        $another_time =~ s/$weeks$string/$days d/;
    }

    my $newtime;
    my $addon;
    ## allow offset of months  ##
    if ( $another_time =~ /(-)?(\d+)\s*mo/i ) {
        my $plus   = $1;
        my $offset = $2;
        if ( $plus eq '-' ) { $offset *= -1; }
        $mon = $mon + $offset;
        if    ( $mon > 12 ) { $mon = $mon - 12; $year++; }
        elsif ( $mon < 0 )  { $mon = $mon + 12; $year--; }
    }
    ############# if standard time units are specified... ###########
    elsif ( $another_time =~ /^[+\-]?(\d+)\s?([smhdSMHD])/ ) {
        my $adjust = $1;
        my $units  = $2;
        if    ( $units =~ /s/i ) { $addon = $adjust; }
        elsif ( $units =~ /m/i ) { $addon = $adjust * 60; }
        elsif ( $units =~ /h/i ) { $addon = $adjust * 60 * 60; }
        else                     { $addon = $adjust * 60 * 60 * 24; }
        if ( $another_time =~ /^\-/ ) { $addon *= -1; }
        $newtime = time + $addon;
        ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($newtime);
    }
    ############### otherwise convert from stat time...################
    elsif ( $another_time =~ /^\d+$/ ) {
        ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($another_time);
    }

    # <CONSTRUCTION> remove this block after format option is added to filter_input
    # Check for the correct delay time format
    elsif ($another_time) {    ## defined delay time, but not recognized (?)
        print "<h3> error: invalid delay ($another_time)</h3>";
        Call_Stack();
        return;
        ############### otherwise supply current local time... ############
    }
    else {
        ## use default localtime settings ##
    }

    my $nowtime = sprintf "%02d:%02d:%02d", $hour, $min, $sec;
    my $nowdate = sprintf "%04d-%02d-%02d", $year + 1900, $mon + 1, $mday;
    $nowdate =~ s/ /0/g;
    $nowtime =~ s/ /0/g;
    my $date_time = $nowdate . " " . $nowtime;

    #    print "TIME: $date_time";
    return ("$date_time");
}

