#!/usr/local/bin/perl
use CGI qw(:standard);
use DBI;
use Benchmark;
use CGI::Carp qw( fatalsToBrowser );

# include GSC modules #
use lib "/home/martink/export/prod/modules/gscweb";
use gscweb;

use lib '/home/rguin/CVS/SeqDB/lib/perl/';

      ## for various Table reading functions...
use HTML_Table;

use vars qw($testing);
   
my  $page = 'gscweb'->new();
$page->SetTitle("Database Tools");
$page->SetContactName("Ran Guin");
$page->SetContactEmail("rguin\@bcgsc.bc.ca");
$page->TopBar();

print h2("Please use the following commands when editing any data in the sequence database\n\n");

print h2("Utilizing Standard IO Tools for the Sequencing Database");
print "\n<BR>Connect to the database using: <BR>";
print "<B>my $dbc = SDB::DBIO->new(-dbase=>'sequence'</B>";
## Connecting to the Database... ##

my $dbc = SDB::DBIO->new(-dbase=>'sequence',-connect=>0);
$dbc->connect();


## Simple data extraction 

my $Example = HTML_Table->new();
$Example->Set_Width(1000);
$Example->Set_Headers([Command,Result]);
$Example->Set_Row(['my @array = &Table_find($dbc,$tables,$fields,$condition,$distinct_flag)',
		   'comma-delimited array of results of query:<BR>'.
		   '<B>Select (Distinct) $fields from $tables $condition</B><BR>'.
		   '(where Distinct is used if $distinct_flag is non-zero)']);
$Example->Set_Row(['<B>Example 1</B><BR>'.
		   "my @employees = &Table_find($dbc,'Employee','Employee_Name,'where Employee_Name like Carrie%')",
		   'comma-delimited array of results of query:<BR>'.
		   '<B>Select (Distinct) $fields from $tables $condition</B><BR>'.
		   '(where Distinct is used if $distinct_flag is non-zero)']);

$Example->Printout();

print "<Table><TR><TD>Command</TD><TD>Result</TD></TR>";

print "<TR><TD>",
    'my @array = &Table_find($dbc,$tables,$fields,$condition,$distinct_flag)',
    "</TD><TD>",
    "comma-delimited array of results of query:<BR>",
    "<B>Select (Distinct) $fields from $tables $condition</B><BR>",
    "(where Distinct is used if $distinct_flag is non-zero)",
    "</TD></TR>";

print "</Table>";

my @employees = &Table_find($dbc,'Employee','Employee_Name',"Limit 2");
print "Emp: <BR>******<BR>". join "<BR>",@employees;

my @recent_runs = &Table_find($dbc,'Run,RunBatch,Employee','count(*) as Number,Employee_Name',"where FK_RunBatch__ID=Sequence_Batch_ID AND RunBatch.FK_Employee__ID=Employee_ID GROUP BY Employee_ID Limit 2");
print "Runs: <BR>*******<BR>". join "<BR>", @recent_runs;
			      
my @recent_libs_used = &Table_find($dbc,'Run','Left(Run_Directory,5) as Lib',"where Sequence_DateTime > '2002-01-01' Limit 2",'Distinct');
print "Recent Libs: <BR>*************<BR>". join "<BR>", @recent_libs_used;

print "Done<BR>";

$page->BottomBar();
exit;
