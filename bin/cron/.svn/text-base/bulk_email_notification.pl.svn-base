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
@EXPORT = qw();
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use CGI ':standard';
use strict;
use FindBin;
use Data::Dumper;
use lib $FindBin::RealBin . "/../lib/perl/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Imported/"; # add the local directory to the lib search path

use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::RGmath;
use RGTools::Process_Monitor;

use SDB::DBIO;
use alDente::SDB_Defaults;
use alDente::Notification;
use alDente::Employee;


##############################
# custom_modules_ref         #
############################################################
# global_vars                #
##############################
use vars qw($vector_directory $bulk_email_dir);
use vars qw($html_header);

##############################
# modular_vars               #
##############################
my $Report = Process_Monitor->new('bulk_email_notification Script',
				  -quiet => 0,
				  -verbose => 0
				  );

##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $pass;
my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>'lims02',-user=>'rguin',-password=>$pass,-connect=>1);

## Custom insert (temporary) <CONSTRUCION> - change to allow user log in ? (remove hardcoded Admin id (141) ##
$dbc->set_local('user_id',141);
my $eo = new alDente::Employee(-dbc=>$dbc,-id=>141);
$eo->define_User();


my @warnings = ();
my @errors = ();
my $summary_message= "Checking For Bulk Mail...\n******************************\n";

#my $bulk_email_directory = "/home/sequence/alDente/bulk_email";
my $bulk_email_directory = $bulk_email_dir;
my @bulk_email_files = <$bulk_email_directory/*.*>;

my $found = 0;
Message("Files: @bulk_email_files");
foreach my $file (@bulk_email_files) {
    my $full_filename = $file;
    if ($file=~/(.*)\/(.*?)$/) { $file = $2 }  ## just get file name... 
    else { next }
    
    # read to: list
    open (INF,$full_filename);
    my $to_list = '';
    while (<INF>) {
	my $line = $_;
	if ($line =~ /^\<B\>To\:\<\/B\>(.+)$/) {
	    $to_list = $1;
	    last;
	}
    }

    close INF;

    $found++;
    my $email_list;
    my $subject = "Bulk Message";
    if ($file =~/(.*)\.admin/) {
	$subject .= " for Admins";
	$email_list = join ', ', @{ &alDente::Employee::get_email_list($dbc,'admin')};
    } elsif ($file =~/(.*)\.LIMS/) {
	$subject .= " for LIMS";
	$email_list = join ', ', @{ &alDente::Employee::get_email_list($dbc,'LIMS')};
    } elsif ($file =~/(.*)\.report/) {
	$subject = "Bulk Report";
	$email_list = join ', ', @{ &alDente::Employee::get_email_list($dbc,'report')};
    } elsif ($file =~/(.*)\.group\.([\d\,]+)/) {
	my $group = $2;
	$subject .= " for Group(s): $group";	
	$email_list = join ',', @{ &alDente::Employee::get_email_list($dbc,'admin',-group=>$group)};
    } else {
	$subject .= " for Undefined Recipient *** ?? ***";	
	$email_list = join ', ', @{ &alDente::Employee::get_email_list($dbc,'LIMS')};
	$Report->set_Warning("*** Undefined target for Bulk email found:\n$file\n(should be admin,LIMS,report or group)");
    }


    # compare email list to original to_list and add missing values
    my @email_list_array = split ',',$email_list;
    my @to_list_array = split ',',$to_list;
    @email_list_array = map { chomp_edge_whitespace($_) } @email_list_array;
    @to_list_array = map { chomp_edge_whitespace($_) } @to_list_array;

    my ($isect,$a_only,$b_only) = RGmath::intersection(\@to_list_array,\@email_list_array);
    
    # add the a_only array to the email list
    # this makes sure that emails that get omitted are still sent to the intended recipient
    push (@email_list_array,@{$a_only});
    $email_list = join(',',@email_list_array);

    ## <construction> - necessary to allow attachments (?)... 
    my $header = "Content-Type: multipart/mixed; boundary=\"DMW.Boundary.605592468\"\n\n\n--DMW.Boundary.605592468\nContent-Type: text/html; name=\"message.txt\"; charset=US-ASCII\nContent-Disposition: inline; filename=\"message.txt\"\nContent-Transfer-Encoding: 7bit\n\n\n";
#    my $header = '';
#    $header .= "Content-Type: text/html\n\n";
#    $header .= $html_header;

    ## send bulk file to intended target list ##
    my $from = try_system_command("grep 'From:' $bulk_email_directory/$file");
    foreach my $sender (split "\n", $from) {
	if ($sender =~ /^From:\s+(.*)/i) {
	    my $sender_email = $1;
	    $email_list .= ", $sender_email" unless ($email_list =~/\b$sender_email\b/);
	}
    }
    ## send bulk email to cc list
    my $cc_list = '';
    my $cc = try_system_command("grep 'CC:' $bulk_email_directory/$file");
    foreach my $receiver (split "\n", $cc) {
	if ($receiver =~ /^CC:\s+(.*)/i) {
	    my $target_email = $1;
	    $email_list .= ",$target_email" unless ($email_list =~/\b$target_email\b/);
	}
    }

    ## <CONSTRUCTION> replace -to=>aldente below with -to=>$email_list once confirmed to be working
    ## (ensure working for submissions, primer orders, rearrays etc) ...
    Message("Sending Message: $subject -> $email_list");
    &alDente::Notification::Email_Bulk_Notification(-to=>$email_list,-from=>'Bulk Mail Handler',-subject=>$subject,-file=>$file,-header=>$header);        
    $email_list =~s/\@bcgsc.ca//g;
    $Report->set_Detail("Sending $file to:\n$email_list\n");

    ## append target_list to file before archiving ##     
    &alDente::Notification::Email_Notification('aldente@bcgsc.ca','bulk mail handler','Target_List',"Final Target list: $email_list",-append=>$file);    

    ## move bulk email file to archived directory ##
    try_system_command("mv $bulk_email_directory/$file $bulk_email_directory/archived/$file.sent.". &timestamp,-report=>$Report);
}

$Report->set_Message("Checked $bulk_email_directory for bulk email: (*** Forwarded $found files ***)");
$Report->completed();

$dbc->disconnect();
exit;

