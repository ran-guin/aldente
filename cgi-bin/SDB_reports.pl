#!/usr/local/bin/perl
#
##############################################
#
# $ID$
# CVS Revision: $Revision: 1.4 $
#     CVS Date: $Date: 2003/05/13 22:30:40 $
#
##############################################
#
# sequencing.pl
#

use strict;

use CGI qw(:standard);
use DBI;
use Benchmark;

#use lib "/home/martink/export/prod/modules/gscweb";
#use gscweb;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;

use SDB::CustomSettings;
use SDB::HTML;

use alDente::Help;
use alDente::SDB_Defaults;

use vars qw($SDB_banner $SDB_links $URL_address);

my $page;  print &alDente::Web::Initialize_page();
print $SDB_banner;
print $SDB_links;

print &vspace(10).
    "Common Reports accessing sequence database information:".
    &vspace(5);

my $homelink = "$URL_address/barcode.pl?User=Auto&Database=sequence";

my $Reports = HTML_Table->new;
$Reports->Set_Title("sequence Database Reports");
my $last24hours = &Link_To($homelink,"Last 24 Hours","&Last+24+Hours=1",'blue',['newwin']);
my $prepsummary = &Link_To($homelink,"Prep Summary","&Prep+Summary=1",'blue',['newwin']);
my $protocol_summary = &Link_To($homelink,"Protocol Summary","&Protocol+Summary=1",'blue',['newwin']);
my $projects = &Link_To($homelink,"Projects","&HomePage=Project",'blue',['newwin']);
my $librarystats = &Link_To($homelink,"(Grouped by Library with details)","&Project Stats=1&Project Choice=Forestry&Group By=Library_Name&Include Details=1",'blue',['newwin']);
my $projectstats = &Link_To($homelink,"Projects","&Project+Stats=1&Project+Choice=Forestry",'blue',['newwin']);

$Reports->Set_Row([$last24hours,"Summary of Results of analysis for recent sequence runs"]);
$Reports->Set_Row([$prepsummary,"Summary of Preparation status for a given library"]);
$Reports->Set_Row([$protocol_summary,"Summary of Preparation status for a given library"]);
$Reports->Set_Row([$projects,"Summary of Projects"]);
$Reports->Set_Row(["$projectstats<BR>$librarystats","Statistics for Projects and/or Libraries"]);

$Reports->Printout();

print &vspace(10);
print "Note: more detailed reports are also available via 'dbsummary', but are not currently being maintained";

&leave;

###############
sub leave {
###############
    print &alDente::Web::unInitialize_page($page);
    exit;
}
