#!/usr/local/bin/perl
#
##############################################
#
# $ID$
# CVS Revision: $Revision: 1.4 $
#     CVS Date: $Date: 2003/05/13 22:31:09 $
#
##############################################
#
# SDB_help.pl
#

use strict;

use CGI qw(:standard);
use CGI::Carp('fatalsToBrowser');
use DBI;
use Benchmark;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;

use SDB::HTML;

use alDente::Help;
use alDente::SDB_Defaults;
use alDente::Web;
use LampLite::Bootstrap;

my $BS = new Bootstrap;

use vars qw($SDB_banner $SDB_links $image_dir %all_available_versions %Configs);

#print "<body bgcolor='#DCDCDC' alink='#336699' vlink='#800080' link='#0000FF' text='#000000'>";
my $mode = 'BETA';
my $Config = new alDente::Config( -initialize => 1, -root => $FindBin::RealBin . '/..', -bootstrap => 1, -mode => $mode );

my ( $home, $version, $domain, $custom, $path, $dbase, $host, $login_type, $session_dir, $init_errors, $url_params, $session_params, $brand_image, $screen_mode, $configs, $custom_login, $css_files, $js_files, $init_errors ) = (
    $Config->{home},       $Config->{version},      $Config->{domain},      $Config->{custom},     $Config->{path},           $Config->{dbase}, $Config->{host},
    $Config->{login_type}, $Config->{session_dir},  $Config->{init_errors}, $Config->{url_params}, $Config->{session_params}, $Config->{icon},  $Config->{screen_mode},
    $Config->{configs},    $Config->{custom_login}, $Config->{css_files},   $Config->{js_files},   $Config->{init_errors}
);

$configs->{icon} = $brand_image;

if ( ref $configs eq 'HASH' ) { %Configs = %$configs }

SDB::CustomSettings::load_config($configs);    ## temporary ...

$home =~s/alDente\.pl//;
#my $home =  "http://seq.bcgsc.bc.ca/cgi-bin/rguin/";
my $herelink = "$home/alDente.pl"; ##http://seq.bcgsc.bc.ca/cgi-bin/rguin/sequencing.pl";
my $homelink = "$home/DB_admin.pl";
my $barcode = "$home/alDente.pl";
my $file_view = "$home/intranet/File_View.pl";
my $module_dir = "/home/sequence/WebVersions/Beta/SeqDB/lib/perl/SDB/";

my $page;  

print LampLite::HTML::initialize_page( -path => "/$path", -css_files => $css_files, -js_files => $js_files );    ## generate Content-type , body tags, load css & js files ... ##
print $BS->open();

print "
<SCRIPT LANGUAGE='Javascript'>
<!--HIDE
var box_status = 0;
function all_boxes(form,Name) {
   box_status = 1 - box_status;
   for (var i=0; i<form.length; i++) {
       var e = form.elements[i];            // look at each form in turn...
       var elementName = e.name;
       if (elementName.search(Name)==0) {
               if ((e.type == 'radio') || (e.type == 'checkbox'))
                   e.checked = box_status;
       }
   }
}
//STOP HIDING --->
</SCRIPT>";

if (param('Try')) {
    my $file = param('Try');

    my $usage = try_system_command("$home$file");
    
    $usage=~s/\n/<BR>/g;
    print $usage;
    &leave();
}

#print "<h1>Sequencing Database Information</h1>";
print $SDB_banner;
print $SDB_links;
#print &RGTools::Views::Heading("Basic Information");

print "<Table width = 100% align = center cellpadding = 20> <TR>",
    "<TD valign=top bgcolor=#ccccff>";

print &Views::Heading("Basic Info");
print <<PART1;
<UL>
<li>
<a href="$homelink?Show+Fields=1&List+Tables=1">
<B>Fields</B>
</A>
<li>
<a href="$homelink?Tree=1&TableName=Plate">
<B>Relationships</B>
<LI>
<a href="$file_view?Table=Formats">
<B>Formats</B>
</A>
<LI>
<A href='$file_view?Images=Sequencing.png&Title=Sequencing Flowchart'>
 <B>Sequencing Flowchart</B></A>
<LI>
<A href='$file_view?Images=scan.png&Title=Scanner Flowchart'>
<B>Scanning Flowchart</B></A>
</UL>

PART1

print &Views::Heading("Table Info");

    my @tables = ('Project','Library','Vector','Plate','Solution','Run','Clone_Sequence','Clone','Clone_Gel','Primer','VectorPrimer','Employee','Organization');

print "<UL>";
foreach my $table (@tables) {
    print "<LI>",
    "<a href='$barcode?User=Auto&Database=sequence&Table+Info=$table'>",
    "$table</A><BR>";
}
print "</UL>";

print &Views::Heading("Admin Tools");
print "<UL>";
print "<LI><a href='$home/Protocol.pl'>Protocols</A>";
print "<li><a href='$barcode.pl?User=Auto&Database=sequence&Chemistry+Parameters=1'>Std_Solutions</A>";   
print "</UL>";

my $prod_ver = "http://$Configs{PRODUCTION_HOST}/SDB/cgi_bin/barcode.pl"; ## all_available_versions{'Production'};
my $beta_ver = "http://$Configs{BETA_HOST}/SDB_beta/cgi_bin/barcode.pl"; ## all_available_versions{'Production'};
my $test_ver = "http://$Configs{PRODUCTION_HOST}/SDB_test/cgi_bin/barcode.pl"; ## all_available_versions{'Production'};
my $dev_ver = "http://$Configs{DEV_HOST}/SDB_development/cgi_bin/barcode.pl"; ## all_available_versions{'Production'};

#my $test_ver = $all_available_versions{'Test Version'};
#my $prev_ver = $all_available_versions{'Previous Version'};

print <<MAIN;

</TD><TD>

<Table><TR><TD width=500>
<a href="$prod_ver">
<h2>Barcode Page</h2>
<img src="/$image_dir/stripe.png"></img>
</A>
<a href="$test_ver">
<h4>Test Version</h4></A>
<h4>Last Version</h4>
</A>
</TD><TD>

MAIN
    
    print start_form(-action=>"$barcode"),
    hidden(-name=>'User',-value=>'Guest');
    hidden(-name=>'Banner',-value=>'On');
    hidden(-name=>'Database',-value=>'sequence'); 
    print submit(-name=>'Search Database',-value=>'Look for Records', -style=>"background-color:yellow"), &vspace(10) ,' containing: ',
    textfield(-name=>'DB Search String',-size=>10),
    &vspace(20);

&Online_help_search();
print end_form();

print "</TD></TR></Table>";

print "<H2>alDente - Automated Laboratory Data Entry N' Tracking Environment</H2>";
print "Note:  some of the following are under construction.".&vspace(20);

#print "<H2>Functions of the alDente System</H2>";
print &Link_To($barcode,'General','?User=Auto&Database=sequence&Help=SDB_info','blue',['newwin'])."<BR>";
print &Link_To($barcode,'Plate Tracking','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin'])."<BR>";
print "<UL><LI>".
    &Link_To($barcode,'Specifying Protocols','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Protocol Tracking','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Viewing Protocol Status','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Viewing Plate Information','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<UL><LI>".
    &Link_To($barcode,'Plate History','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Plate Ancestry','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Well Status','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "</UL>".
    "</UL>";

print &Link_To($barcode,'Solution Tracking','?User=Auto&Database=sequence&Help=Solution_Tracking','blue',['newwin']) . "<BR>";

print "<UL><LI>".
    &Link_To($barcode,'Mixing Solutions','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Specifying Standard Solution Calculations','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Checking Stock Supplies','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Stock Supply Notification','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "</UL>";

print &Link_To($barcode,'Equipment Monitoring','?User=Auto&Database=sequence&Help=Equipment_Monitoring','blue',['newwin'])."<BR>";
print "<UL><LI>".
    &Link_To($barcode,'Maintenance Procedures','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Maintenance Monitoring','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Capillary Status','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "</UL>";

print &Link_To($barcode,'Run Monitoring','?User=Auto&Database=sequence&Help=Run_Monitoring','blue',['newwin']) . "<BR>";
print "<UL><LI>".
    &Link_To($barcode,'Last 24 Hour View','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Liink to Run Map','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Diagnostics','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Detailed Run Info','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "</UL>";

print &Link_To($barcode,'Project/Library Summaries','?User=Auto&Database=sequence&Help=Project_Summaries','blue',['newwin'])."<BR>";
print "<UL><LI>".
    &Link_To($barcode,'Basic Project/Library Information','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "<LI>".
    &Link_To($barcode,'Detailed Project/Library Info','?User=Auto&Database=sequence&Help=Plate_Tracking','blue',['newwin']).
    "</UL>";

print &Link_To($barcode,'Reporting','?User=Auto&Database=sequence&Help=Reporting','blue',['newwin']) . "<BR>";

print "<H2>New Database Entries</H2>";
print &Link_To($barcode,'Projects','?User=Auto&Database=sequence&Help=Projects','blue',['newwin'])."<BR>";
print &Link_To($barcode,'Libraries','?User=Auto&Database=sequence&Help=Libraries','blue',['newwin'])."<BR>";
print &Link_To($barcode,'Plates','?User=Auto&Database=sequence&Help=Plates','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Reagents','?User=Auto&Database=sequence&Help=Reagents','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Equipment','?User=Auto&Database=sequence&Help=Equipment','blue',['newwin']) . "<BR>";

#print "<H2>Ongoing Lab procedures</H2>";
#print &Link_To($barcode,'Transferring Plates','?User=Auto&Database=sequence&Help=Plate_Transferring','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Re-Arraying Plates','?User=Auto&Database=sequence&Help=ReArraying','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Specifying No Grows, Slow Grows','?User=Auto&Database=sequence&Help=Plate_Transfering','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Throwing out Plates','?User=Auto&Database=sequence&Help=ReArraying','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Mixing Solutions','?User=Auto&Database=sequence&Help=Mixing_Solutions','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Making Standard Solutions','?User=Auto&Database=sequence&Help=Standard_Solutions','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Equipment Maintenance','?User=Auto&Database=sequence&Help=Equipment_Maintenance','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Tracking Protocols','?User=Auto&Database=sequence&Help=Plate_Preparation','blue',['newwin']) . "<BR>";

print "<H2>Searching & Viewing Forms</H2>";
print &Link_To($barcode,'Record Editing Form','?User=Auto&Database=sequence&Help=DB_Summary','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Record Searching','?User=Auto&Database=sequence&Help=DB_Summary','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Record Appending','?User=Auto&Database=sequence&Help=DB_Summary','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Viewing Plate History','?User=Auto&Database=sequence&Help=Plate_History','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Viewing Plate Ancestry','?User=Auto&Database=sequence&Help=Plate_History','blue',['newwin']) . "<BR>";
#print &Link_To($barcode,'Checking Stock Supplies','?User=Auto&Database=sequence&Help=DB_Summary','blue',['newwin']) . "<BR>";

print "<H2>Reports</H2>";
print &Link_To($barcode,'Last 24 Hours','?User=Auto&Database=sequence&Help=Last_24_Hours','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Plate Preparation','?User=Auto&Database=sequence&Help=Viewing_Plate_Preparation_Status','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Project Stats','?User=Auto&Database=sequence&Help=Project_Stats','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Library Stats','?User=Auto&Database=sequence&Help=Library_Stats','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Diagnostics','?User=Auto&Database=sequence&Help=Diagnostics','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'DB Summary','?User=Auto&Database=sequence&Help=DB_Summary','blue',['newwin']) . "<BR>";

print "<h2>Administrative Tools</H2>";
print &Link_To($barcode,'DB_admin.pl','?User=Auto&Database=sequence&Help=DB_admin','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Protocol Definition','?User=Auto&Database=sequence&Help=Protocols','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Standard Solution Definition','?User=Auto&Database=sequence&Help=Chemistry_Calculator','blue',['newwin']) . "<BR>";

print "<H2>System Requirements</H2>";
print &Link_To($barcode,'General Assumptions','?User=Auto&Database=sequence&Help=SDB_Assumptions','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Hardware','?User=Auto&Database=sequence&Help=Hardware_Requirements','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Software','?User=Auto&Database=sequence&Help=Software_Requirements','blue',['newwin']) . "<BR>";
print &Link_To($barcode,'Personnel','?User=Auto&Database=sequence&Help=Personnel_Requirements','blue',['newwin']) . "<BR>";


print "</TD></TR></Table>",
    "</Form>";

print "</TD></TR></Table>";

&leave;

sub leave {

    print $BS->close();
    exit;
}
