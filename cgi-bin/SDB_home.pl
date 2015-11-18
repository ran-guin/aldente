#!/usr/local/bin/perl

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

use vars qw($SDB_banner $SDB_links $image_dir);

my $dbase = 'sequence';

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
<Img Src='/SDB/$image_dir/stripe.png'>
</A><BR>
(Log in as a Guest)
</TD><TD>
<A Href=$home_web?User=Auto&Database=$dbase&PageName=Main+Orders>
<img src='/SDB/$image_dir/box.png'alt = 'Orders' align = top border=0 height=40 width=40></A>
<BR>
Orders
</TD></TR></Table>
ICONS

print &SDB::Views::Heading("Database Information");

print <<INFO;

<UL>
<LI>
<A Href='$home_web/SDB_info.pl'>
get detailed information on Database Structure and Formats
</A>

<LI>
<Form action='$home_web/barcode.pl'>
<INPUT type=hidden name='User' value='Guest'>
<INPUT type=hidden name='Database' value=$dbase>
Look for Data: <INPUT type=submit name='Search Database' value='Search Database' style='background-color:yellow'>
 for string: 
<INPUT type=textfield name='DB Search String' size=10>
</FORM>
</UL>

INFO

print &SDB::Views::Heading("Database Reports");

print <<REPORTS;
<Table><TR><TD>
<A Href="$home_web/barcode.pl?User=Auto&Database=$dbase&Sequencing+Status=1">
<Img Src='/SDB/$image_dir/data.png'>
</A>
</TD><TD>
<A Href="$home_web/barcode.pl?User=Auto&Database=$dbase&Sequencing+Status=1">
Project/Library Summaries
</A>

</TD></TR><TR><TD>

<A Href="$home_web/barcode.pl?User=Auto&Database=$dbase&Last+24+Hours=1">
<Img Src='/SDB/$image_dir/hourglass.png'>
</A>
</TD><TD>
<A Href="$home_web/barcode.pl?User=Auto&Database=$dbase&Last+24+Hours=1">
Runs in Last 24 Hours 
</A>

</TD></TR><TR><TD>

    <Form action='$home_web/barcode.pl'>
    <INPUT type=hidden name='User' value='Guest'>
    <INPUT type=hidden name='Database' value='sequence'>
    <INPUT type=submit name='Stock Used' value='Stock Used' style='background-color:yellow'> 
    From Library: 
    <INPUT type=textfield name='Library Name' size=10> (may list more than one)
    </FORM>

</TD></TR></Table>
REPORTS


    print "</TD></TR></Table></Body>";
    
    exit;
