#!/usr/local/bin/perl

###############################
# warnings.pl
###############################

use strict;
use CGI qw(:standard);
use DBI;
use Benchmark;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";


############## Local Modules ################
use lib "/home/martink/export/prod/modules/gscweb";
use gscweb;
use local::Barcode;

use SDB::Views;
use SDB::Table;
use SDB::SDB_Status;

use vars qw($dbc $testing);

#print "Content-type: text/html\n\n";


my $page = 'gscweb'->new();
$page->SetTitle("Warnings");
$page->SetContactName("Ran Guin");
$page->SetContactEmail("rguin\@bcgsc.bc.ca");
#    $page->SetAgeObject("Threader HTML Report");
#    $page->SetAgeFile("");
$page->TopBar();   

my $homefile = $0;  ##### a pointer back to this file 
if ($homefile =~/\/([\w_]+[.pl]{0,3})$/) {
    $homefile = "http://rgweb.bcgsc.bc.ca/cgi-bin/$1";
}
elsif ($homefile =~/\/([\w_]+)$/) {
    $homefile = "http://rgweb.bcgsc.bc.ca/cgi-bin/$1";
}

print h1("Warning Page");
$dbc = DB_Connect(dbase=>'sequence');
my @libs = Table_find($dbc,'Library','Library_Name');
my @notes = Table_find($dbc,'Note','Note_Text,Note_Description','Order by Note_Text');  #### order should agree with SDB_Status 

my $Warnings=HTML_Table->new();

my @Title;
my @Desc;

my $Note_num=0;
foreach my $note (@notes) {
    (my $Note_title, my $Note_Description) = split ',',$note;
    if ($Note_title=~/\w/) {
	push(@Title,$Note_title);
	push(@Desc,$Note_Description);
	$Note_num++;
    }
}

$Warnings->Set_Title("<B>Sequencing Warnings</B>");
my @headers = ('Warning','Explanation');
$Warnings->Set_Headers(\@headers);

my $look_at = param('Warning');
foreach my $index (1..$Note_num) {
    my @fields = ("$Title[$index-1]","$Desc[$index-1]");
    if ($index == $look_at) {
	$Warnings->Set_Row(\@fields,undef,'mediumredbw');
    } else {
	$Warnings->Set_Row(\@fields);
    }
    }   
$Warnings->Printout();

print "<HR>";

my $limit = param('Limit') || 20;
if (param('Index')) {
    my $lib = param('Library');
    &index_warnings($lib,$limit);
    print start_form(-action=>$homefile),
    "Select Library ",
    popup_menu(-name=>'Library',-values=>[@libs]),
    " Limit Search to ",
    textfield(-name=>'Limit',-size=>5,-default=>40)," ",
    submit(-name=>'Index',-value=>'View Index Errors'),
    end_form();
}
$dbc->disconnect;


$page->BottomBar();
exit;
