#!/usr/local/bin/perl
#
##############################################
#
# $ID$
# CVS Revision: $Revision: 1.25 $
#     CVS Date: $Date: 2004/09/21 00:53:24 $
#
##############################################
#
# sequencing.pl
#

use strict;

use CGI qw(:standard);
use DBI;
use URI::Escape;

use Benchmark;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;

use alDente::Help;
use alDente::SDB_Defaults;
use alDente::Web;

use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
 
use SDB::HTML;

use vars qw($SDB_banner $SDB_links $URL_address $bin_home $homelink);

my $thisfile = $0;

my $time1 = date_time();

my $host = param('Host') || 'lims-dbm';
my $dbase = param('Database') || 'sequence';
my $Idbase = 'seqdev';    ### temporary until updated production database..

#my $URL_address =  "http://seq.bcgsc.bc.ca/cgi-bin/rguin/";
my $bin_dir = "/opt/alDente/versions/rguin/bin";
my $adminlink = "$URL_address/DB_admin.pl";

my $std_parameters = "Database=$dbase&Host=$host";

my $homelink = "$URL_address/sequencing.pl?User=guest&$std_parameters";
my $barcode = "$URL_address/barcode.pl";
my $helplink = "$URL_address/help.pl";

#my $file_view = "http://rgweb.bcgsc.bc.ca/cgi-bin/intranet/File_View.pl";
#my $module_dir = "/home/sequence/WebVersions/Beta/SeqDB/lib/perl/SDB/";
my $help = "$URL_address/help.pl";

my $page;  print &alDente::Web::Initialize_page(-include=>'contact,help,info');

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

    my $usage = try_system_command("$bin_dir/$file");
    
    $usage=~s/\n/<BR>/g;
    print "Try: <B>$bin_dir/$file</B><P>";
    print "<Span class=small>";
    print $usage;
    print "</span>";
    &leave();
}

#print "<h1>Sequencing Database Information</h1>";
#print $SDB_banner;
print $SDB_links;
#print &RGTools::Views::Heading("Basic Information");

print "<Table width = 100% align = center cellpadding = 20> <TR>".
    "<TD valign=top bgcolor='lightgrey'>";

#print &RGTools::Views::Heading("Basic Info");
my $fields;

my $table_list = 'Project,Vector,Library,Employee';
$fields = "DBTable_Name as Table_Name,DBTable_Description as Description";
$fields = uri_escape($fields);
my $Tables_link = &Link_To($adminlink,'Tables',"?$std_parameters&DBTable=DBTable&Title=Database+Tables&DBList=$fields",'red',['newwin']);

my $Fields_link = &Link_To($adminlink,'Fields',"?$std_parameters&Show+Fields=1&List+Tables=1",'red',['newwin']); 
my $Relationships_link = &Link_To($adminlink,'Relationships',"?$std_parameters&Tree=1&TableName=Plate",'red',['newwin']);
my $ER_diagrams_link = &Link_To("$help?Help=ER_Diagrams",'ER Diagrams',undef,'red',['newwin']);
my $Formats_link = &Link_To("$help?Help=Formats",'Formats',undef,'red',['newwin']);
my $Flow_link = &Link_To("$help?Help=SequencingFlowchart",'Generating Sequence_Data',undef,'red',['newwin']);

my $LIMS_link = &Link_To("$help?Help=LIMScontext",'LIMS',undef,'blue',['newwin']);
my $alDente_link = &Link_To("$help?Help=alDenteContext",'alDente',undef,'blue',['newwin']);
my $Laboratory_link = &Link_To("$help?Help=LaboratoryContext",'Laboratory',undef,'blue',['newwin']);
my $Sequencing_link = &Link_To("$help?Help=SequencingContext",'Sequencing',undef,'blue',['newwin']);
my $Scanning_link = &Link_To("$help?Help=ScanningFlowchart",'Scanning',undef,'blue',['newwin']);

print "<Span class=small><UL>";
print "<LI>" . $Tables_link;
print "<LI>" . $Fields_link;
print "<LI>" . $Relationships_link;
print "<LI>" . $ER_diagrams_link;
print "<LI>" . $Formats_link;
print "</UL></Span>";

print &Views::Heading("Table Info");

my @tables = ('Project','Vector','Library','Organization','Plate','Tube','Rack','Lab_Protocol','Prep','Run','RunBatch','SequenceRun','Clone_Sequence','Solution','Equipment','Stock','Orders','Clone','Transposon');

print start_form(-action=>"$adminlink?$std_parameters");

print "<B>$dbase</B> Tables:<span class=small><UL>";
foreach my $table (@tables) {
    print '<LI>'.
	&Link_To($adminlink,$table,"?$std_parameters&TableHome=$table",'blue',['newwin']);
}
print "</UL></Span>"; 
print end_form();   

print &Views::Heading("Admin Tools");
print "<UL>";
print "<LI><a href='$URL_address/Protocol.pl'>Protocols</A>";
print "<li><a href='$URL_address/barcode.pl?User=Auto&$std_parameters&Chemistry+Parameters=1'>Std_Solutions</A>";   
print "<li><a href='$URL_address/query_tool.pl'>Query Tool</A>";   
print "<li><a href='$URL_address/DBIntegrity.pl'>DB Integrity</A>";  
print "<li><a href='$URL_address/barcode.pl?User=Auto&$std_parameters&Info=1&Table=Issue&Order+By=Issue_ID+Desc'>Issues</A>";  
print "</UL>";

print "</TD><TD valign=top>"; 

print <<MAIN; 
<Table><TR><TD width=500>
<a href="$URL_address/barcode.pl?User=Auto&$std_parameters">
<h2>Barcode Page</h2>
<img src="/$image_dir/stripe.png"></img>
</A>
</TD><TD>

MAIN
    
    print start_form(-action=>"$barcode").
    hidden(-name=>'User',-value=>'guest').
    hidden(-name=>'Banner',-value=>'On').
    hidden(-name=>'Database',-value=>$dbase).
    end_form();

    print start_form(-action=>"$helplink") . 
    submit(-name=>'Search Database',-value=>'Look for Records', -style=>"background-color:yellow") . &vspace(10) . ' containing: ' .
    textfield(-name=>'DB Search String',-size=>10). 
    &vspace(20);

    &Online_help_search();
    print end_form();

print "</TD></TR></Table>";

print "<H2>alDente - Automated Laboratory Data Entry  N' Tracking Environment</H2><P>";
print <<DESC;

alDente is essentially a LIMS System (yet ANOTHER $&\#*@ acronym for 'Laboratory Information Management System' - slightly redundant yes..) which has been specifically designed for use in a genome sequencing laboratory.  It has been developed to store detailed information related to standard sample preparation procedures as well as final sequence data.  
<P>
In addition there is an interface which allows users to interact with the database via a barcode scanner during regular lab processes, and a sophisticated suite of report generating and data visualization tools which provide lab administrators with the means to quickly and effectively evaluate results and monitor status on a regular basis.
<P>
Also, by maintaining this detailed information in a highly structured format, there is the capability to perform a number of automatic procedures such as monitoring stock, error checking, and diagnostic analysis, generating real-time messages for users or regular email notifications to administrators.  This helps to ensure the integrity of recorded data, and may prevent time-consuming errors by flagging them or identifying possible problems.

DESC

print &vspace(10);
print &Link_To($help,'Users Manual','?Help=Manual','blue',['newwin']);
print &hspace(10);
print &Link_To($help,'Administrators Manual','?Help=Administration.chapter','blue',['newwin']);
print &hspace(10);
print &Link_To($help,'Developers Manual','?Help=DevMan_Index','blue',['newwin']);
print &vspace(10);

print "Note:  some of the following may still be under construction.".&vspace(20);

print "<Table width = 100%><TR><TD class=small valign=top>";
print &Link_To($help,'General','?Help=SDB_info','blue',['newwin'])."<BR>";
print &Link_To($help,'Database','?Help=Database','blue',['newwin'])."<BR>";
print &Link_To($help,'E-R Diagrams','?Help=ER_Diagrams','blue',['newwin'])."<BR>";
print &Link_To($help,'Sequence Data','?Help=Sequence_Data','blue',['newwin'])."<BR>";
print &Link_To($help,'Plate Tracking','?&Help=Plate_Tracking','blue',['newwin'])."<BR>";
print &Link_To($help,'Solution Tracking','?Help=Solution_Tracking','blue',['newwin']) . "<BR>";
print &Link_To($help,'Equipment Monitoring','?Help=Equipment_Monitoring','blue',['newwin'])."<BR>";
print &Link_To($help,'Run Monitoring','?Help=Run_Monitoring','blue',['newwin']) . "<BR>";
print &Link_To($help,'Barcode Scanners','?Help=Scanners','blue',['newwin']) . "<BR>";
print &Link_To($help,'Examples of Data Views','?Help=Sample_Views','blue',['newwin']) . "<BR>";
print &Link_To($help,'Ongoing Development','?Help=Ongoing_Development','blue',['newwin']) . "<BR>";

print "</TD><TD class=small valign=top>";

### set up requirements links ###
my $condition;
$fields = "Type,Description,Status";

$condition = uri_escape("Type='Requirement' AND Assigned_Release NOT IN ('3.0')","+'");
my $Requirements_link = &Link_To($adminlink,'Requirements(v2.0)',"?Database=$Idbase&DBTable=Issue&DBView=1&Condition=$condition",'red',['newwin']);

$condition = uri_escape("Type='Requirement' AND Assigned_Release IN ('1.0')","+'");
my $current_link = &Link_To($adminlink,'current',"?Database=$Idbase&DBTable=Issue&DBView=1&Condition=$condition",'red',['newwin']);

$condition = uri_escape("Type='Requirement' AND Assigned_Release NOT IN ('1.0')","+'");
my $development_link = &Link_To($adminlink,'development',"?Database=$Idbase&DBTable=Issue&DBView=1&Condition=$condition",'red',['newwin']);

my $GE_requirements_link = &Link_To("/SDB/share/requirements/requirements_GE_checklist.html","Gene Expression LIMS",'','red',['newwin']);
my $full_requirements_link = &Link_To("/SDB/share/requirements/requirement_checklist.html","General",'','red',['newwin']);
my $development_link = &Link_To("/SDB/share/requirements/development.html","Development",'','red',['newwin']);

print "Requirements:";
print "<UL>";
print "<LI>" .$full_requirements_link;
print "<LI>" .$GE_requirements_link;
print "</UL>";

print "(via database):<UL>";
print "<LI>" . $Requirements_link;
print "<UL><LI>" . $current_link;
print "<LI>" . $development_link;
print "</UL>";

print "<LI>Types:<UL>";
my @types = ('General','View','Forms','I/O','Report','Settings','Error Checking','Auto-Notification','Documentation','Scanner','Background Process');
foreach my $type (@types) {
    print "<LI>" . _link_requirement($type);
};
print "</UL>";
print "</UL>";

print "</TD><TD class=small valign=top>";

print "Design Document: (UNDER CONSTRUCTION)<UL>";

print "<LI>" . 'Context diagrams:<UL>';
print "<LI>" . $LIMS_link;
print "<LI>" . $alDente_link;
print "<LI>" . $Laboratory_link;
print "<LI>" . $Sequencing_link;
print "<LI>" . $Scanning_link;
print "</UL>";
print "<LI>" . &Link_To($help,'Roles of Entities',"?Help=EntityRoles",'blue',['newwin']);
print "<LI>" .  &Link_To($help,'Design Issues / Decisions','?Help=IssuesDecisions','blue',['newwin']);
print "<LI>" . &Link_To($help,'Static View of Classes','?Help=StaticView','blue',['newwin']);
print "<LI>" . &Link_To($help,'Dynamic Processes','?Help=DynamicView','blue',['newwin']);
print "<LI>" . &Link_To($adminlink,'DataLayer',"?$std_parameters&Show+Fields=1&List+Tables=1",'blue',['newwin']);
print "<LI>" . &Link_To($help,'Classes','?Help=Classes.chapter','blue',['newwin']);
print "<LI>" . &Link_To($help,'Modules','?Help=Modules.chapter','blue',['newwin']);
print "<LI>" . &Link_To($help,'GUI Design','?Help=Sample_Views','blue',['newwin']);
print "</UL>";

print &vspace(10);
print "</TD></TR></Table>";

&leave;


###################
sub _link_requirement{
###################
    my $type = shift;

    my $padded_type = $type;
    $padded_type =~s/\s+/+/g;

    $fields = "Issue_ID,Type,SubType,Description,Status";
   
    my $link;
    $link = &Link_To($adminlink,$type,"?Database=$Idbase&DBTable=Issue&DBView=1&Condition=Type=\\'Requirement\\'+AND+SubType=\\'$padded_type\\'",'red',['newwin2']);
    
    return $link;
}

#########
sub leave {
#########
    my $time2 = date_time();
#    print "\n$time1 .. $time2.";
    print &alDente::Web::unInitialize_page($page);
    exit;
}

