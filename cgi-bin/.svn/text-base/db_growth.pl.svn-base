#!/usr/local/bin/perl

################################################################################
# post_sequence.pl
#
# This program updates the database with Run Run Information
# by running phred and extracting sequence & quality information
# from generated 'phred' files.
#
################################################################################

################################################################################
# $Id: db_growth.pl,v 1.3 2004/06/03 18:11:13 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.3 $
#     CVS Date: $Date: 2004/06/03 18:11:13 $
################################################################################

use CGI ':standard';
use Shell qw(cp mkdir ls);
use File::stat;
use Time::Local;
use strict;
# include GSC modules #
use lib "/home/martink/export/prod/modules/gscweb";
use gscweb;

use vars qw($testing);
use vars qw($dbase $nowdate $nowtime $vector_directory);
use vars qw($trace_file_ext1 $trace_file_ext2 $rawext $rawext2);
use vars qw($local_drive $local_sample_sheets);
use vars qw($edit_dir $trace_dir $phred_dir $poly_dir $home_dir $phredpar);
use vars qw($opt_w);
use vars qw($SCREEN $PFILE $ERROR $status);

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::Plate;
 
use SDB::RGIO;
use SDB::Histogram;
use SDB::Errors;
use SDB::Report;
use SDB::Views;
use SDB::SDB_Defaults;

#use SDB::Table;
#use SDB::Views;
#use SDB::Info;  ##### SQL_phred

use vars qw($opt_R);
require "getopts.pl";
&Getopts('R');    ### options (type post_sequence.pl to see options)

  ######################################################
  # set up standard page template... (from gscweb)
  ######################################################


  my $VERSION = q{ $Revision: 1.3 $ };
  my $CVSTAG = q{ $Name:  $ };
  # these regexp statements remove blanks and nasty $ signs
  if($VERSION =~ /\$.*:\s*(.*?)\s*\$/) {
    $VERSION=$1;
  }
  if($CVSTAG =~ /\$.*:\s*(.*?)\s*\$/) {
    $CVSTAG=$1;
  }
#my $updated;
#    my @blanks = Table_find($dbc,'Stock,Solution','Stock_ID,Solution_Started',"where FK_Stock__ID=Stock_ID and Stock_Received like '0000%'");
#my $index;
#foreach my $info (@blanks) {
#    my ($id,$rcvd) = split ',', $info;
#    $updated += Table_update_array($dbc,'Stock',['Stock_Received'],[$rcvd],"where Stock_ID = $id and Stock_Received like '0000%'",-autoquote=>1);
#	$index++;
#}#

#print "updated $updated (tried $index)\n";


my  $page = 'gscweb'->new();
$page->SetTitle("$dbase Database");
$page->SetContactName("Ran Guin");
$page->SetContactEmail("rguin\@bcgsc.bc.ca");
$page->SetAgeObject("Sequencing Database Interface v$VERSION $CVSTAG");
$page->SetAgeFile("");
$page->TopBar();  

#print "Content-type: text/html\n\n";
#print "\n<META HTTP-EQUIV='Pragma' CONTENT='no-cache'>";
#print "\n<META HTTP-EQUIV='Expires' CONTENT='-1'>";
#print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/x/style.css' >";
#print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/netscape/links.css'>";
#print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/common.css'>";
#print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/colour.css'>";	

#print "\n***************\n Runs \n****************";
  
my $filename1 = "Runs_History.gif";
my $filename2 = "Prep_History.gif";
my $filename3 = "Sol_History.gif";

if ($opt_R) {
    my $dbc = DB_Connect(dbase=>'sequence');
    
    my @runs = &Table_find($dbc,'RunBatch','count(*),RunBatch_RequestDateTime',"where RunBatch_RequestDateTime like '2%' group by Left(RunBatch_RequestDateTime,7) order by Left(RunBatch_RequestDateTime,7)");
    (undef,my $start_run) = split ',', $runs[1];
    
    my @RBins = (0,0);     ## two months before first run info recorded...
    foreach my $info (@runs) {
	my ($num, $month) = split ',',$info;
#    print "Runs: $month: $num\n";
	push(@RBins,$num);
    }
    
    my @preps = &Table_find($dbc,'Prep','count(*),Prep_DateTime',"where Prep_DateTime like '2%' group by Left(Prep_DateTime,7) order by Left(Prep_DateTime,7)");
    
    (undef,my $start_preps) = split ',', $preps[1];
    
    my @PBins = (0,0,0,0,0,0,0,0,0,0,0,0);
    foreach my $info (@preps) {
	my ($num, $month) = split ',',$info;
#    print "Preps: $month: $num\n";
	push(@PBins,$num);
    }
    
    my @sols = &Table_find($dbc,'Solution,Stock','count(*),Stock_Received',"where FK_Stock__ID=Stock_ID and Stock_Received like '2%' group by Left(Stock_Received,7) order by Left(Stock_Received,7)");
    
    (undef,my $start_sols) = split ',', $sols[1];

    my @SBins;
    foreach my $info (@sols) {
	my ($num, $month) = split ',',$info;
#    print "Solutions: $month: $num\n";
	push(@SBins,$num);
    }
    $dbc->disconnect();
    
    my $binsize = 20;
    
    my $Hist=SDB::Histogram->new();
    $Hist->Set_Bins(\@RBins,$binsize);
    $Hist->Number_of_Colours(10);
#$Hist->Group_Colours(1);
    $Hist->Set_Height(100);
    (my $scale,my $max1) = $Hist->DrawIt($filename1,100,100);
    
    
#print "<BR>Runs from 2000-05 ... 2002-02",
#    "\n<BR>try:  xv  /home/sequence/www/htdocs/SDB/Temp/$filename\n<BR>\n";
#print "<IMG SRC='/SDB/Temp/$filename>";

    
    $Hist=SDB::Histogram->new();
    $Hist->Set_Bins(\@PBins,$binsize);
    $Hist->Number_of_Colours(10);
#$Hist->Group_Colours(1);
    $Hist->Set_Height(100);
    (my $scale,my $max1) = $Hist->DrawIt($filename2,100,100);
    
    
    $Hist=SDB::Histogram->new();
    $Hist->Set_Bins(\@SBins,$binsize);
    $Hist->Number_of_Colours(10);
#$Hist->Group_Colours(1);
    $Hist->Set_Height(100);
    (my $scale,my $max1) = $Hist->DrawIt($filename3,100,100);
}

print "This is a general outline of some of the increase in usage of the sequencing database since its basic inception in May/2000.";

print "<Table><TR><TD colspan = 3>",
    &SDB::Views::Heading("Runs"),
    ,"This depicts the number of runs generated per month from 2000-05 until 2002-02\n",
    &vspace(10),"<BR>(with a maximum of 250 runs in March 2001)",
    "</TD></TR>";

print "<TR><TD colspan=2>",
    "\n",
    qq{<img src="/SDB/Temp/$filename1">\n},
    "</TD><TD width = 500>",
    "</TD></TR>";

print "<TR><TD align=left>",
    "|<BR>2000-05",
    "</TD><TD align=right>",
    "| <BR>2002-02",
    "</TD></TR>";

print "<TR><TD colspan=3>",
    &SDB::Views::Heading("Plate Preparation Tracking"),
    "This depicts the number of Preparation steps tracked per month from 2000-05 until 2002-02\n<BR>",
    &vspace(10),"<BR>(with a maximum of 4350 in January 2001)",
    "</TD></TR>";

print "<TR><TD colspan=2 width=1>",
    "\n",
    qq{<img src="/SDB/Temp/$filename2">\n},
    "</TD><TD width = 500>",
    "</TD></TR>";

print "<TR><TD align=left>",
    "|<BR>2000-05",
    "</TD><TD align=right>",
    "| <BR>2002-02",
    "</TD></TR>";

print "<TR><TD colspan=3>",
    &SDB::Views::Heading("Solution Tracking"),
    "This depicts the number of Solutions/Reagents entered into the database from 2000-05 until 2002-02\n",
    &vspace(10),"<BR>(with a maximum of 509 in January 2001)",
    "</TD></TR>";

print "<TR><TD colspan=2 width=1>",
    "\n",
    qq{<img src="/SDB/Temp/$filename3">\n},
    "</TD><TD width = 500>",
    "</TD></TR>";

print "<TR><TD align=left>",
    "|<BR>2000-05",
    "</TD><TD align=right>",
    "I <BR>2002-02",
    "</TD></TR>";

print "<TR><TD colspan=3>",
    &SDB::Views::Heading("Code"),
    "The number of lines of code does not necessarily reflect the advancing stages of the code development, since much of the initial code was implemented rapidly to enable the initiation of data collection, while time is then spent organizing and documenting the code more carefully as well as ensuring that the functionality is as robust as possible.  Thus code improvements are not necessarily associated with an increas in the number of lines of code.<P>",
    "Rough indications are available from May /2001 as follows:",
    "</TD></TR><TR>",
    "<TD><B>Month</B></TD><TD><B>Lines of Code</B></TD></TR>",
    "<TD>May</TD><TD>28,000</TD></TR>",
    "<TD>Jul</TD><TD>32,000</TD></TR>",
    "<TD>Aug</TD><TD>39,000</TD></TR>",
    "<TD>Oct</TD><TD>40,000</TD></TR>",
    "<TD>Dec</TD><TD>42,000</TD></TR>",
    "<TD>Dec</TD><TD>50,000</TD></TR>",
    "</UL>";

print "<TR><TD colspan=3>",
    &SDB::Views::Heading("Tables"),
    "The Table structure, while being adjusted periodically has not increased in size considerably, since the original table structure was designed with the scalability in mind.  Exceptions to this are the tables implemented for finishing (along with a separate database), and another table to allow the soon to be incorporated stock monitoring system which will displace the current system).",
    "Various tables, while implemented initially, have not been used extensively until more recently (such as the maintenance tracking tables), or have not yet been fully used (such as the Grant and Contact information tables)"; 

print "</TD></TR></Table>";

print "<HR>";
#print "Runs started: $start_run\n<BR>";
#print "Preps started: $start_preps\n<BR>";
#print "Solutions started: $start_sols\n<BR>";


$page->BottomBar();
exit;
