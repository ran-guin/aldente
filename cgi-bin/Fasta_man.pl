#!/usr/local/bin/perl 
###############################
# Fasta_man.pl
###############################
#
#
##################################################################################

use CGI qw(:standard);
use DBI;
use Benchmark;
use Carp;
use CGI::Carp qw(fatalsToBrowser);

use strict;
use Date::Calc qw(Day_of_Week);

use GD;

use lib "/home/martink/export/prod/modules/gscweb";
use gscweb;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use lib "/home/rguin/CVS/SeqDB/lib/perl/";
use HTML_Table;

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
$Prep->Set_Title("<H1>Generating Fasta Files</H1>");
$Prep->Set_sub_title('Defining the Protocol',2,'lightgreenbw');
$Prep->Set_sub_header("You can generate fasta files from within the 'barcode' page (when you are looking at the data for a particular run - it is printed to the directory: home/sequence/FASTA and optionally may be dumped to the screen), or from the command line via the command: /home/rguin/public/fasta.pl",'white');
$Prep->Set_sub_header("Generating fasta files from a Library",'lightgreenbw');
$Prep->Set_Row(["/home/rguin/public/fasta.pl -L CN001"]);

$Prep->Printout();

exit;
