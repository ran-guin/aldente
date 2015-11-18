#!/usr/local/bin/perl

###############################
#
# Views_help.pl
#
# This is a basic tutorial for using various display modules
#
#
##################################################################################

################################################################################
# $Id: Views_man.pl,v 1.8 2003/08/22 21:46:23 jsantos Exp $
################################################################################
# CVS Revision: $Revision: 1.8 $
#     CVS Date: $Date: 2003/08/22 21:46:23 $
################################################################################


use CGI qw(:standard);
use DBI;
use Benchmark;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use Date::Calc qw(Day_of_Week);
use GD;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use Imported::Barcode;
use SDB::Histogram;
use RGTools::HTML_Table;

#my $Temp_dir = "/home/sequence/www/htdocs/SDB/Temp/";
my $Temp_dir = $URL_temp_dir;
my $Temp_src = "/SDB/dynamic/tmp/";

print "Content-type: text/html\n\n";
print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/x/style.css'>";
print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/netscape/links.css'>";
print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/common.css'>";
print "\n<LINK rel=stylesheet type='text/css' href='/site-style/gsc/colour.css'>";	 

print "<Body bgcolor=white>";
#print "<Table width=80%><TR><TD>";

print h2("Adding Simple Histograms or Web Tables in Perl scripts");

my $Hist =HTML_Table->new();
$Hist->Set_Title("<B>Creating Simple Histograms</B>");
$Hist->Set_Line_Colour('white');
$Hist->Set_Row(['This is a simple object used to create histograms allowing for quick generation 
of small histograms for data viewing purposes on web pages.
<BR>  Further features can be added as they prove useful, with only very basic features existing currently.']);
$Hist->Set_Row(['<H2>The Basics</H2><UL><LI>Include these USE statements in your code:<BR>
<b>use lib \'/home/sequence/WebVersions/Production/SeqDB/\'
<BR>use SDB::Histogram;</b><BR>

<LI>Initializing:<BR><b>my $Hist = Histogram->new();</b>
<LI>Define each column ("bin") in the histogram:<BR><b>my ($scale,$max) = $Hist->Set_Bins(\@data,$width);</b>
<BR>(where $width = defined width of bars/columns in pixels - defaults to 10)

<LI>Set Path to write images to (defaults to /home/sequence/www/htdocs/SDB/Temp/)
<BR>(This is necessary if you are another user and wish to both write to the directory and read from it via the web)
<BR><b>$Hist->Set_Path($path);</b><LI>Set Options...

<LI>Draw:<BR><b>$Hist->DrawIt($filename,$height)</b>
<BR>(where $height is the defined height in pixels of the image)
<BR>($scale returns units/pixel, $max returns maximum value</UL>']);

$Hist->Set_Row(['<H2>Options</H2><UL><LI><b>$Hist->Number_of_Colours(N) </b>
<br>set number of colours to be used (one colour per bar). N cannot exceed 10. 
<br>If the histogram has more than 10 bars, the colours are reused.

<LI><b>$Hist->Group_Colours(N)</b> 
<br>specifies the number of bars to be grouped under one colour. By default, one bar would use one colour.

<LI><b>$Hist->Border($colour)</b>
<br>change the border colour to $colour, where $colour is an integer representing the colour.

<LI><b>$Hist->Set_X_Axis($title, $indexes_ref, $index_labels_ref)</b>and <b>$Hist->Set_Y_Axis($title, $indexes_ref, $index_labels_ref)</b>
<br>set the axis title, where to put the index ticks, and what to label them. <i>$indexes_ref</i> and <i>$index_labels_ref</i> is optional.
<br><i>$title</i> is a string denoting the title.
<br><i>$indexes_ref</i> is a reference to an array that lists the columns that will have ticks under them.
<br><i>$index_labels_ref</i> is a reference to an array that lists the labels corresponding to each tick in $indexes_ref.

<LI><b>$Hist->Set_Height(N)</b>
<br>set the height of the histogram to N pixels.
<br>the width will be autoscaled depending on how many columns there are and the bin width.
<LI><b>Future options:</b>  background specification, multiple datasets...</UL>']);
$Hist->Printout();

my $Examples=HTML_Table->new();
$Examples->Set_Title("<h3>Histogram Examples</h3>");
$Examples->Set_Headers(['Basic','Reduced Height','Reduced Bin width','Grouping Bin Colours']);
$Examples->Set_Alignment('Center');
$Examples->Set_Class('small');

my $Hist1 = SDB::Histogram->new();
#$Hist1->Set_Path($Temp_dir);
$Hist1->Set_Bins([1,2,3,4,5,4,3,2,1,0.5,1,2,3,4,5,4,3,2,1]);
$Hist1->DrawIt("Example1.png",height=>100);
$Hist1->DrawIt("Example2.png",yscale=>10);
$Hist1->Set_Bins([1,2,3,4,5,4,3,2,1,0.5,1,2,3,4,5,4,3,2,1],4);
#$Hist1->Set_Bins([1,2,3,4,5,4,3,2,1,1,2,3,4,5,4,3,2,1,1,2,3,4,5,4,3,2,1,1,2,3,4,5,4,3,2,1,1,2,3,4,5,4,3,2,1,1,2,3,4,5,4,3,2,1,1],2);
$Hist1->DrawIt("Example3.png",yscale=>10);
$Hist1->Group_Colours(5);

$Hist1->DrawIt("Example4.png",yscale=>10);
$Hist1->Set_X_Axis('xlabel',[5,10,15]);
$Hist1->Set_Y_Axis('ylabel',[0,1,3]);
$Hist1->DrawIt("Example5.png",yscale=>10);

$Examples->Set_Row(["<Img src='$Temp_src/Example1.png'>","<img src='$Temp_src/Example2.png'>","<img src='$Temp_src/Example3.png'>","<img src='$Temp_src/Example4.png'>","<img src='$Temp_src/Example5.png'>"]);

$Examples->Set_Row(['define Bins, set height to 100','define height using yscale','define bin_width=4 (default=10)','Group 5 bins per colour','add labels (with scale factors)']);
$Examples->Set_Row(['<B>my $Hist1 = Histogram->new();<BR>$Hist1->Set_Bins([1,2,3,4,5,4,3,2,1]);<BR>$Hist1->DrawIt("Example1.png",height=>100);</B>',
'my $Hist1 = Histogram->new();<BR>$Hist1->Set_Bins([1,2,3,4,5,4,3,2,1])<BR>$Hist1->DrawIt("Example2.png",<B>yscale=>10</B>);',
'my $Hist1 = Histogram->new();<BR>$Hist1->Set_Bins(\@data<B>,4</B>);<BR>$Hist1->DrawIt("Example3.png",yscale=>10);<BR>..OR..<BR>my $Hist1 = Histogram->new();<BR>$Hist1->Set_Bins(\@data);<BR>$Hist1->DrawIt("Example3.png",<B>xscale=>4,</B>yscale=>10);',
'my $Hist1 = Histogram->new();<BR>$Hist1->Set_Bins(\@data,4);<BR><B>$Hist1->Group_Colours(5);</B><BR>$Hist1->DrawIt("Example4.png",yscale=>10);',
'my $Hist1 = Histogram->new();<BR>$Hist1->Set_Bins(\@data,4);<BR>$Hist1->Group_Colours(5);<BR><B>$Hist1->Set_X_Axis(\'xlabel\',undef,[5,10,15]);<BR>$Hist1->Set_Y_Axis(\'ylabel\',[0,1,3]);</B><BR>$Hist1->DrawIt("Example5.png");']);

$Examples->Printout();

print "<P>";

my $HT=HTML_Table->new();
$HT->Set_Line_Colour('white');
$HT->Set_Title("<B>HTML_Table Module</B>");
$HT->Set_Row(['This module is used to generate Tables quickly and easily, according to a fairly standard format.<BR>It is meant to be used within a perl script in which tables are used regularly.  This removes the necessity of including an oppressive number of TR, TD, /TD commands, and it automatically sets up coloured headings and line colour toggling.  There are a growing variety of options including defining table elements by column (instead of by row), printing out the table to an html file, colour/class setting, and html form element definitions.<BR>']);
$HT->Set_Row(['<H2>Code</H2><UL><LI>Include in your code the lines:<BR><B>use lib \'/home/sequence/WebVersions/Production/SeqDB/\'
<BR>use HTML_Table;</B> ## for Histograms<BR>
<LI>Initializing:<BR>
<B>my $Table=HTML_Table->new();</B></BR>
<LI>Set Title:<BR>
<B>$Table->Set_Title($title);</B></BR>
<LI>Set Headers:<BR>
<B>$Table->Set_Headers(\@headers);</B><BR>
<LI>Set Rows:<BR>
<B>$Table->Set_Row(\@data);</B><BR>
<LI>Printing out:<BR>
<B>$Table->Printout();</B><BR>
</UL>
<bR>']);
$HT->Printout();

print h2("Generating Data Tables quickly");

print <<END;
<PRE class = 'darkredtext'>
my \@data1 = (1,2,3,4,5);
my \@data2 = ('a','b','c','d','e');
my \@field_names = ('field 1','field 2','field 3','field 4','field 5');
</PRE>    
END

my @data1 = (1,2,3,4,5);
my @data2 = ('a','b','c','d','e');
my @field_names = ('field 1','field 2','field 3','field 4','field 5');

############ Simplest example ##################
print h1("The most basic example...");

print <<END;
<PRE class = 'darkredtext'>
my \$Test = HTML_Table->new();    ## define the Table
\$Test->Set_Row(\@data1);          ## Add a row
\$Test->Printout();               ## Print it out
</PRE>
END

my $Test = HTML_Table->new();
$Test->Set_Row(\@data1);
$Test->Printout();

############ Adding basic features #############
print p,h1("Adding a few basic features...");
    print <<END;
<PRE class = 'darkredtext'>
\$Test = HTML_Table->new();
\$Test->Set_Title("Basic Title");     ## Add a title  
\$Test->Set_Headers(\@field_names);    ## Define the field headings
foreach my \$index (1..4) {           ## Add a few more lines...  
    \$Test->Set_Row(\@data1);
    \$Test->Set_Row(\@data2);
}
\$Test->Printout();
\$Test->Printout("\$Temp_dir/Basic_table.html");  ### (optional)
</PRE>
END

$Test = HTML_Table->new();
$Test->Set_Title("Basic Title");
$Test->Set_Headers(['field 1','field 2','field 3','field 4','field 5']);
foreach my $index (1..4) {
    $Test->Set_Row(\@data1);
    $Test->Set_Row(\@data2);
}
$Test->Printout();
$Test->Printout("$Temp_dir/Basic_table.html");


############ Adding some more complicated features #############
print p,h1("Adding more complicated features...");
    print <<END;
<PRE class = 'darkbluetext'>

print start_form();   <Span class = 'darkredtext'>### include first if forms are to be imbedded in table...</Span>

\$Test = HTML_Table->new();
\$Test->Set_Title("H1> Basic Title /H1>",class=>'lightbluebw');     <Span class = 'darkredtext'>## Note you can define colour classes to be as sickening as you like</Span>
\$Test->Set_Headers([\@field_names,'link'],'darkbluebw');

\$Test->Set_Border(4);              <Span class = 'darkredtext'>## Add a border</Span>
\$Test->Set_Alignment('center');    <Span class = 'darkredtext'>## Set standard alignment to center</Span>
\$Test->Set_Alignment('right',3);   <Span class = 'darkredtext'>## Set alignment of column 3 to right

# <I>Including Form Elements</I>
#
#  add 'LINK' where you wish include a form item in the table.
#  then use 'Set_Link' to define the form items in order... (they will replace 'LINK') 
#  (allows for boxes, text, popup, radio, submit...)
#  (parameters are used to define values, names, labels, and defaults).
</Span>
foreach my \$index (1..5) {
    \$Test->Set_Row([\@data1,'eg: LINK'],'lightyellowbw'); 
    \$Test->Set_Row([\@data2],'lightgreenbw');
}
<Span class = 'darkredtext'>
#
# Note that as we loop through 5 'LINK's will be generated, 4 of which are defined below.
# (Any undefined links simply show up as 'Link' in the Table.
#
</Span>
\$Test->Set_Link('text','Field Name',20,'Default');
\$Test->Set_Link('popup','Name',['George','Karla','Rapunzel'],'Karla');
\$Test->Set_Link('radio','Choose',['Good','Bad','Ugly'],'Ugly');
\$Test->Set_Link('submit','A Button','Button Label');

<Span class = 'darkredtext'>
### another column can be appended afterwards, and will appear on the right.
</Span>

\$Test->Set_Column(['one','more','partial','column','added'],'Extra');

\$Test->Printout();
<Span class = 'darkredtext'>
## Print it out to a file and provide a link to it...
</Span>
\$Test->Printout("$Temp_dir/Views_man.html");

print end_form();
</PRE>
END

    print start_form();  ### if forms are to be imbedded in table...

$Test = HTML_Table->new();
$Test->Set_Title("<H2>Basic Title</H2>",class=>'lightbluebw');  
$Test->Set_Headers([@field_names,'link'],'darkbluebw');

$Test->Set_Border(4);              ## Add a border
$Test->Set_Alignment('center');    ## Set standard alignment to center
$Test->Set_Alignment('right',3);   ## Set alignment of column 3 to right

## enter 'LINK' where you wish to include link the table to a form item.
#  use Set_Link to define the form items in order... (allows for boxes, text, popup, radio, submit...)
#  (parameters are used to define values, names, labels, and defaults).
# (if the link is not defined, the table will simply print out 'Link');

foreach my $index (1..5) {
    $Test->Set_Row([@data1,'eg: LINK'],'lightyellowbw'); 
    $Test->Set_Row([@data2],'lightgreenbw');
}
$Test->Set_Link('text','Field Name',20,'Default');
$Test->Set_Link('popup','Name',['George','Karla','Rapunzel'],'Karla');
$Test->Set_Link('radio','Choose',['Good','Bad','Ugly'],'Ugly');
$Test->Set_Link('submit','A Button','Button Label');

### another column can be appended afterwards, and will appear on the right.

$Test->Set_Column(['one','more','partial','column','added'],'Extra');

$Test->Printout();
$Test->Printout("$Temp_dir/Views_man2.html");

print end_form();

#print "</TD></TR></Table>";

exit;

