#!/usr/local/bin/perl
#
################################################################################
#
# public.pl
#
# This program provides a public interface to alDente
#
################################################################################

################################################################################
# $Id: public.pl,v 1.11 2003/01/28 02:03:23 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.11 $
#     CVS Date: $Date: 2003/01/28 02:03:23 $
################################################################################

use strict;
use CGI qw(:standard);
use DBI;
use File::stat;

use Statistics::Descriptive;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Views;

  
use SDB::DB_Form_Viewer;
use SDB::CustomSettings;

use Sequencing::SDB_Status;
use alDente::SDB_Defaults;
use alDente::Run_Info;
use alDente::Library;

require "getopts.pl";
&Getopts('D:S:X:P:mb');
use vars qw($opt_D $opt_S $opt_X $opt_P $opt_m $opt_b);

use vars qw($homelink $dbase %Settings);

###### Globals.. #######

$homelink = "http://limsdev01.bcgsc.bc.ca/SDB_test/cgi-bin/public.pl?User=Auto";   
my $barcode = "http://limsdev01.bcgsc.bc.ca/SDB_test/cgi-bin/barcode.pl?User=Auto&Database=seqtest";   
my $backup_dbase = 'seqlast';    

print "Begin " . &date_time() . "\n";

print "Content-type: text/html\n\n";
print $html_header;   ### imported from Default File (SDB_Defaults.pm)

print "\n<!------------ JavaScript ------------->\n";
print $java_header;   ### imported from Default File (SDB_Defaults.pm)
   
    &home;

exit;

#############
sub home {
#############

    print &Views::Heading("Public home page");

    print "<P>This is simply a tentative (somewhat trivial) wrapper to link to various places in the LIMS system that may be made publicly accessible.<P>In some cases, the links would require users to be logged in with a valid contact name which could be passed to the link.<P>In most cases, navigation links at the top of the page, and at the left would also be removed for guests.<P>Note any 'updates' to the database via this link would be stored as 'submissions', and would not be written directly to the database.<P>Statistics presented could also be limited to projects with which collaborators are associated.<P>";

    print "Some possible Links:";
    print Views::sub_Heading("Submit Libraries",2);
    
    print "<UL><LI>".
	&Link_To($barcode,'Submit SAGE Library',"&User=Guest&Public=1&Submit+Library=SAGE&FK_Contact__ID=2&FK_Project__ID=2",
		 $Settings{LINK_COLOUR},['newwin']);
    print "<LI>".
	&Link_To($barcode,'Submit cDNA Library',"&User=Guest&Public=1&Submit+Library=cDNA&FK_Contact__ID=2&FK_Project__ID=2",
		 $Settings{LINK_COLOUR},['newwin']);
    print "<LI>".
	&Link_To($barcode,'Submit Genomic Library',"&User=Guest&Public=1&Submit+Library=Genomic&FK_Contact__ID=2&FK_Project__ID=2",
		 $Settings{LINK_COLOUR},['newwin']);
    print "</UL>";
#	&Link_To($barcode,'Submit Library','&DBTable=Library&DBAppend=Library&Target=XML&FK_Project__ID=5&Library_Source=As+Entered+In+Login&Library+Status#=Pending&FK_Contact__ID=2',$Settings{LINK_COLOUR},['newwin']);
    
    
    print Views::sub_Heading("Check Statistics",2);    
    print "<UL><LI>".
	&Link_To($barcode,'Project/Library Stats','&User=Guest&Public=1&Sequencing+Status=1',$Settings{LINK_COLOUR},['newwin']);
    print "</UL>";
    print hr;
    return;
}
