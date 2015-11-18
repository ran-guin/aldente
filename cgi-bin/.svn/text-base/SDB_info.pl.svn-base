#!/usr/local/bin/perl-w

use strict;

use CGI qw(:standard);
use DBI;
use Benchmark;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;

use alDente::Help;
use alDente::SDB_Defaults qw(:versions);

use vars qw($SDB_banner $SDB_links);

my $dbase = 'sequence';

my $homelink = "http://seq.bcgsc.bc.ca/cgi-bin/SDB_test/DB_admin.pl";
my $home_web = "http://seq.bcgsc.bc.ca/cgi-bin/SDB_test";
my $file_view = "http://rgweb.bcgsc.bc.ca/cgi-bin/intranet/File_View.pl";
my $image_dir = "/home/aldente/www/htdocs/SDB";
     
print "Content-type: text/html\n\n";
print <<HEADER;
<META HTTP-EQUIV='Pragma' CONTENT='no-cache'>
<META HTTP-EQUIV='Expires' CONTENT='-1'>
<LINK rel=stylesheet type='text/css' href='/site-style/gsc/x/style.css' >
<LINK rel=stylesheet type='text/css' href='/site-style/gsc/netscape/links.css'>
<LINK rel=stylesheet type='text/css' href='/site-style/gsc/common.css'>
<LINK rel=stylesheet type='text/css' href='/site-style/gsc/colour.css'>	
<Body color=white>
HEADER

print "<Table width=80% align=center><TR><TD>";

print $SDB_banner;
print $SDB_links;

print <<ICONS;
<Table width=80% align=center><TR><TD>
<A Href='$home_web/barcode.pl?User=Auto&Database=$dbase'>
<Img Src='/SDB/Images/stripe.png'>
</A><BR>
(Log in as a Guest)
</TD><TD>
<A Href=$home_web?User=Auto&Database=$dbase&PageName=Main+Orders>
<img src='/SDB/Images/box.png'alt = 'Orders' align = top border=0 height=40 width=40></A>
<BR>
Orders
</TD></TR></Table>
ICONS

print &SDB::Views::Heading("General Database Structure Information");

print <<PART1;
<UL>
<li>
<a href="$homelink?Show+Fields=1&List+Tables=1">
<B>List of Fields</B>
</A>
<li>
<a href="$homelink?Tree=1&TableName=Plate">
<B>Single Level Tree Structure</B>
<LI>
<A href='$file_view?Images=Sequencing.png&Title=Sequencing Flowchart'>
 <B>Sequencing Flowchart</B></A>
<LI>
<A href='$file_view?Images=scan.png&Title=Scanner Flowchart'>
<B>Scanning Flowchart</B></A>
<li><a href="$file_view?Table=Formats">
<B>Formats (Paths, Naming Conventions)</B>
</A>
</UL>
PART1

print &SDB::Views::Heading("Specific Table Information");

print <<TABLES;

<h3>Some Table Descriptions:</h3> 
<Table>

<TR><TD>
<a href="$file_view?Table=Library">
Library</A>
</TD><TD>
<a href="$homelink?Query=1&querystring=Select+Library_Name,Library_FullName,Organism,Tissue,FK_Vector__Name,Library_Description,Project_Name+from+Library,Project+where+Project_ID=FK_Project__ID Order by Project_Name,Library_Name">  
List Libraries with Description</A>
    <BR>
    <a href="$file_view?Table=NewLib"</A>  
Creating a New Library</A>    
</TD></TR>

<TR><TD>
<a href="$file_view?Table=Run">
Run</TD><TD>
(Run_Time, Mobility_Version)
</A>
</TD></TR>

<TR><TD>
<a href="$file_view?Table=Plate">
Plate</A></TD><TD>
(Library, Number, Created, No_Grows...) <BR>
    
    <a href="$file_view?NoGrows=1">  
Tracking No Grow Wells</A>   
</TD></TR>

<TR><TD>
    <a href="$file_view?ReArray=1">
ReArray</TD><TD>
(Source plate, Target Plate, ReArray Request)
</A>
</TD></TR>

<TR><TD>
    <a href="$file_view?Clone_Sequence=1">
Clone_Sequence</TD><TD>
(Run,Scores,Quality,Vector info)
</A>
</TD></TR>

<TR><TD>
    <a href="$file_view?Clone=1">
Clone,Clone_Gel</TD><TD>
(for cDNA Clones)</TD><TD>
</A>
</TD></TR>

<TR><TD>

</TD><TD>
    <a href="$homelink?Query=1&querystring=Select+Clone_Source,Clone_Source_Name,Clone_Source_Library,Clone_Source_Library_ID,Clone_Source_Plate,Clone_Source_Row,Clone_Source_Col+from+Clone+where+Clone_Source_Col=1&Limit=400">  
View Data in Clone table</A>
(1st row)</TD><TD>

</TD></TR>

<TR><TD>
    <a href="$file_view?Pool=1">
Pool</A></TD><TD>
<a href="$homelink?Query=1&querystring=Select+*+from+Pool">
View Data in Pool table
</A></TD><TD>   
</TD></TR>

<TR><TD>
<a href="$file_view?Table=Primer">
Primers</TD><TD>
(Primer,PrimerVector)
</A>
</TD></TR>

<TR><TD>
</TD><TD>
    <a href="$homelink?Query=1&querystring=Select+Primer_Name,Primer_Sequence,Purity,GC_Percent,Tm1,Tm50+from+Primer">  
View Data in Primer table</TD><TD>
</A>
</TD></TR>
<TR><TD>
</TD><TD>
    <a href="$homelink?Query=1&querystring=Select+FK_Primer__Name,FK_Vector__Name,Direction+from+VectorPrimer+Order+by+FK_Primer__Name">  
View Data in VectorPrimer table</TD><TD>
</A>
</TD></TR>
</Table>
</UL>

TABLES

    print &SDB::Views::Heading("Search Database for Info or Data");

    print <<SEARCH;

<Form action='$home_web/barcode.pl'>
<INPUT type=hidden name='User' value='Guest'>
<INPUT type=hidden name='Database' value=$dbase>
Look for Data... 
<INPUT type=submit name='Search Database' value='Search Database' style='background-color:yellow'>
 for string: 
<INPUT type=textfield name='DB Search String' size=10>

SEARCH

    print &vspace(5),"Check Instructions...";
&Online_help_search("$homelink?User=Auto&Database=sequence");

print "</FORM>";

print "</TD></TR></Table>";
exit;
