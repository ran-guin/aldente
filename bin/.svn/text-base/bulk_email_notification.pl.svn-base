#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
# bulk_email_notification.pl
#
# This program looks for files that store accumulated mail messages and sends them out to the applicable target list.
#
# Standard target lists include:  .LIMS, .admin, .report, .group.<id_list>
#
##############################
# superclasses               #
##############################
#
################################################################################
# CVS Revision: $Revision$
#     CVS Date: $Date$
################################################################################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT    = qw();
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use CGI ':standard';
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::RGmath;
use RGTools::Process_Monitor;
use SDB::CustomSettings;
use SDB::DBIO;
use alDente::SDB_Defaults;
use alDente::Notification;
use alDente::Employee;

use Getopt::Long;
use vars qw($opt_test);
GetOptions(
    'test' => \$opt_test,

);

my $test = $opt_test;

##############################
# custom_modules_ref         #
############################################################
# global_vars                #
##############################
use vars qw($vector_directory $bulk_email_dir);
use vars qw($html_header);
use vars qw(%Configs);

##############################
# modular_vars               #
##############################
my $Report = Process_Monitor->new(
    -quiet   => 0,
    -verbose => 0
);

##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $database = $Configs{PRODUCTION_DATABASE};
my $host     = $Configs{PRODUCTION_HOST};

if ($test) {
    print "testing ... \n\n";
    $database = $Configs{TEST_DATABASE};
    $host     = $Configs{TEST_HOST};
}

my $pass;
my $dbc = SDB::DBIO->new( -dbase => $database, -host => $host, -user => 'cron', -connect => 1 );

## Custom insert (temporary) <CONSTRUCION> - change to allow user log in ? (remove hardcoded Admin id (141) ##
$dbc->set_local( 'user_id', 141 );
my $eo = new alDente::Employee( -dbc => $dbc, -id => 141 );
$eo->define_User();

my @warnings        = ();
my @errors          = ();
my $summary_message = "Checking For Bulk Mail...\n******************************\n";

my $bulk_email_directory = $bulk_email_dir;
my $source               = 'BulkMailHandler<aldente@bcgsc.ca>';

my @bulk_email_files = <$bulk_email_directory/*.*>;
my $header
    = "Content-Type: multipart/mixed; boundary=\"DMW.Boundary.605592468\"\n\n\n--DMW.Boundary.605592468\nContent-Type: text/html; name=\"message.txt\"; charset=US-ASCII\nContent-Disposition: inline; filename=\"message.txt\"\nContent-Transfer-Encoding: 7bit\n\n\n";

my %Subject;
my %Target;
my %From;

my $found = 0;
Message("Files found: @bulk_email_files");
my $single_email_subject;
my $bulk_email_count = @bulk_email_files;
foreach my $file (@bulk_email_files) {
    my $full_filename = $file;
    if ( $file =~ /(.*)\/(.*?)$/ ) { $file = $2 }    ## just get file name...
    else                           {next}

    my ( $count, $subject, $from, $to, $cc ) = get_mail_info($full_filename);
    $found++;

    if ( $subject =~ /,/ ) { $subject = "$count Request(s) " }

    my $email_list = $to;
    if ($cc) { $cc .= ",$from" }
    else     { $from = $cc }

    Message("Sending Message: $subject -> $email_list");
    &alDente::Notification::Email_Bulk_Notification( -to => $email_list, -from => $source, -cc => $cc, -subject => $subject, -file => $file, -header => $header, -dbc => $dbc );

    $Report->set_Detail("Sending $file to:\n$email_list\n");

    ## append target_list to file before archiving ##
    &alDente::Notification::Email_Notification( 'aldente', 'bulk mail handler', 'Target_List', "\nFinal Target list: $email_list\nCC: $cc\n\Subject: $subject", -append => $file, -dbc => $dbc );

    ## move bulk email file to archived directory ##
    unless ($test) {
        try_system_command( "mv $bulk_email_directory/$file $bulk_email_directory/archived/$file.sent." . &timestamp, -report => $Report );
    }
}

$Report->set_Message("Checked $bulk_email_directory for bulk email: (*** Forwarded $found files ***)");
$Report->completed();

$dbc->disconnect();
exit;

####################
sub get_mail_info {
####################
    my $file = shift;

    open( INF, $file );
    my $to;
    my $from;
    my $subject;
    my $cc;
    my $sent;

    my $found = 0;
    while (<INF>) {
        my $line = $_;
        if ( $line =~ /^\<B\>Subject\:\<\/B\>(.+?)(\<br \/\>)?$/ ) {
            $subject .= ",$1";

            #
        }
        elsif ( $line =~ /^\<B\>From\:\<\/B\>(.+?)(\<br \/\>)?$/ ) {
            $from = ",$1";

            #        last;
        }
        elsif ( $line =~ /^\<B\>To\:\<\/B\>(.+?)(\<br \/\>)?$/ ) {
            $to .= ",$1";
            $found++;
        }
        elsif ( $line =~ /^\<B\>CC\:\<\/B\>(.+?)(\<br \/\>)?$/ ) {
            $cc .= ",$1";

            #        last;
        }
        elsif ( $line =~ /^\<B\>Sent\:\<\/B\>(.+)(\<br \/\>)?$/ ) {

        }
    }

    my $to_list      = join ',', @{ &RGmath::distinct_list( [ split ',', $to ],      -strip => 1 ) };
    my $from_list    = join ',', @{ &RGmath::distinct_list( [ split ',', $from ],    -strip => 1 ) };
    my $subject_list = join ',', @{ &RGmath::distinct_list( [ split ',', $subject ], -strip => 1 ) };
    my $cc_list      = join ',', @{ &RGmath::distinct_list( [ split ',', $cc ],      -strip => 1 ) };

    close INF;

    return ( $found, $subject_list, $from_list, $to_list, $cc_list );

}

