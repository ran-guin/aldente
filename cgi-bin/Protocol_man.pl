#!/usr/local/bin/perl

###############################
#
# Protocol_man.pl
#
###############################

use CGI qw(:standard);
use DBI;
use Benchmark;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use Date::Calc qw(Day_of_Week);
use GD;

use strict;

#use lib "/home/martink/export/prod/modules/gscweb";
#use gscweb;
#use local::Barcode;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::HTML_Table;
use alDente::SDB_Defaults qw($image_dir);

use vars qw($image_dir);

print "Content-type: text/html\n\n";
print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/x/style.css'>";
print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/netscape/links.css'>";
print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/common.css'>";
print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/colour.css'>";	 

print "<Body bgcolor=white align = center>";

my $Prep=HTML_Table->new();
$Prep->Set_Width('75%');
$Prep->Set_Table_Alignment('Center');
$Prep->Toggle_Colour(0);
$Prep->Set_Title("<H1>Plate Tracking</H1>");
$Prep->Set_sub_title('Defining the Protocol',2,'lightgreenbw');
$Prep->Set_sub_header("Before tracking can take place, a detailed protocol is written up and stored in the database, including in the definitions of each step the inputs that are required (or available), default values, instructions, and whether or not the step is to require feedback from the scanner.  This is administered through the Protocol Administration program.<BR><Img Src='/$image_dir/protocol_define.png'>",'white');
$Prep->Set_sub_header('Monitoring the Protocol','lightgreenbw');
$Prep->Set_sub_header("The protocol may be monitored and edited to ensure that it is always up to date.<BR><Img Src='/$image_dir/Protocol_admin.png'>",'white');

$Prep->Set_sub_header('Scanner Home Page','lightgreenbw');
$Prep->Set_Row(["At the home page of the scanner, the user is given a number of options including:<UL><LI>Scanning any barcoded item to get a description of it<LI>Scanning a group of plates to define as a plate set<LI>Making up a standard batch of Solution I<LI>Making up a standard batch of Solution II<LI>Retrieving a plate set immediately by entering the plate set number</UL>",
		"<Img Src='/$image_dir/scanner_home.png'>"],'white');
$Prep->Set_sub_header('Selecting a Protocol','lightgreenbw');

$Prep->Set_Row(["The user then selects the Protocol they wish to use from a popdown menu.<BR>Alternatively the user can Display a plate history (showing all preparation done for the current plate or plate set)",
		"<Img Src='/$image_dir/plateset_home.png'>"],'white');
$Prep->Set_sub_header('Stepping through the Protocol','lightgreenbw');
$Prep->Set_Row(["Through each step of the protocol, the user scans appropriate Equipment, Solutions etc. as required.  Fields for input are automatically generated based on the protocol step definitions.",
		"<Img Src='/$image_dir/protocol_step.png'>"],'white');
$Prep->Set_sub_header('Viewing a plate history','lightgreenbw');
$Prep->Set_Row(["A history of what has been done for a plate or plate set is available as well to monitor what has already been tracked showing<UL><LI>The Plate Set Number<LI>The Plate (if a step relates each plate with a unique piece of equipment)<LI>The Protocol Name<LI>The Protocol Step Name<LI>The time the procedure was performed<LI>The user who performed the procedure</UL>",
		"<Img Src='/$image_dir/plate_history.png'>"],'white');
$Prep->Printout();

exit;
