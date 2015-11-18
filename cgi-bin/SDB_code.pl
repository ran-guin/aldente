#!/usr/local/bin/perl

use strict;

use CGI qw(:standard);
use DBI;
use Benchmark; 
use CGI::Carp('fatalsToBrowser');
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::CustomSettings;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;

use alDente::SDB_Defaults qw(:versions);
use alDente::Notification;
use alDente::Web;
use vars qw($SDB_banner $SDB_links $URL_dir_name $URL_temp_dir  $URL_address $URL_home $code_version);

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);        ### phase out global, but leave in for now .... replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
###############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Setup = new alDente::Config(-initialize=>1, -root=>$FindBin::RealBin . '/..');

my $configs = $Setup->{configs};
   
%Configs = %{$configs};  ## phase out global, but leave in for now .... 
###################################################
## END OF Standard Module Initialization Section ##
###################################################

my ( $home, $version, $domain, $custom, $path, $dbase, $host, $login_type, $session_dir, $init_errors, $url_params, $session_params, $brand_image, $screen_mode, $configs, $custom_login, $css_files, $js_files, $init_errors ) = (
    $Setup->{home},       $Setup->{version},      $Setup->{domain},      $Setup->{custom},     $Setup->{path},           $Setup->{dbase}, $Setup->{host},
    $Setup->{login_type}, $Setup->{session_dir},  $Setup->{init_errors}, $Setup->{url_params}, $Setup->{session_params}, $Setup->{icon},  $Setup->{screen_mode},
    $Setup->{configs},    $Setup->{custom_login}, $Setup->{css_files},   $Setup->{js_files},   $Setup->{init_errors}
);

$home =~s/alDente\.pl//;

use vars qw($opt_host $opt_dbase $opt_debug);

## Load input parameter options ## 
#
## (replace section below with required input parameters as required) ##
#
my $dbase        = $opt_dbase || $configs->{DATABASE};
my $host         = $opt_host || $configs->{SQL_HOST};
my $test = $opt_debug;
my $db_user = 'cron_user';  ## use super_cron_user if requiring write access (or repl_client to run database restoration scripts)
my $min_width = 1200;

## Enable automatic logging as required ##
my $logfile = $Setup->get_log_file(-ext=>'html', -config=>$configs, -type=>'relative');

## Connect to slave host/dbase if using for read only purposes ##
my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $db_user, -config=>$configs);
$dbc->connect();

#my $home = "$URL_address/";
my $help = "$home/help.pl";
my $perldoc_home = "$URL_dir_name/html/perldoc/";

my $herelink = "$home/sequencing.pl";
my $homelink = "$home/DB_admin.pl";
my $barcode = "$home/alDente.pl";
#my $module_dir = "/home/sequence/WebVersions/Beta/SeqDB/lib/perl/SDB/";
my $selflink = "SDB_code.pl";

my $bin = $FindBin::RealBin . '/../bin/';

print LampLite::HTML::initialize_page( -path => "/$path", -css_files => $css_files, -js_files => $js_files, -min_width => $min_width );    ## generate Content-type , body tags, load css & js files ... ##
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

# print $SDB_banner;

print $SDB_links;
my $find = param('Find');
my $string = param('String');

if (param('Try')) {
    my $file = param('Try');

    my $usage = try_system_command("$bin/$file");
    
    $usage=~s/\n/<BR>/g;
    
    print $usage;
    &leave;
} elsif (param('Modules') && $find) {
    my @modules = param('Modules');
    my $search_area = join ',', param('SearchArea');
    if ($string=~/\S/) { $string = "-s " . $string; }
    my $timestamp = join '',localtime();

    foreach my $module (@modules) {
        my $path = "lib/perl";
        if ($module =~/^(RGTools|SDB|alDente)$/i) { $path .= "/Core" }
	my $command = qq{$bin/index.pl -d $path/$module $string -m ALL -f "Search.$timestamp.$module" -a "$search_area"};
	Message($command);
	print &try_system_command($command);
    }

    print &try_system_command(qq{cat $URL_temp_dir/Search.$timestamp*});
    Message(qq{cat $URL_temp_dir/Search.$timestamp*});
    print &alDente::Web::unInitialize_page();
    exit;
} elsif (param('Perl_Std')) {
    &_perl_std();
    &leave;
} elsif ($find) {
    Message("You must choose a module package to search");
}

#print "</TR><TR><TD colspan=2>";
print &Views::Heading("Code Information");

print "
<P>
alDente is driven by over 150,000 lines of code, written primarily in perl.<P>
It is designed to be fairly portable, though it does cater to the information and processes that take place in a sequencing laboratory.  <P>
Some of the modules used in its development may also be useful to other mySQL based databases, provided that field naming conventions adhere to the specified format designed to define foreign key relationships (though this limitation is being phased out).  The package is gradually evolving to increase its flexibility in ways that make it applicable to a broader range of applications.
<P>Feel free to let us know if you have any valuable suggestions that would enable this to be of more value.<P>";

print "<a href='mailto:aldente\@bcgsc.bc.ca\'>Contact Developer</a><P>";

print "<HR>";
print "Versions of this page: ";
print &hspace(10);
print "<A Href='/SDB/cgi-bin/SDB_code.pl'>Production</A>";
print &hspace(10);
print "<A Href='/SDB_beta/cgi-bin/SDB_code.pl'>Beta</A>";
print "<HR>";

my $Coding_Std = HTML_Table->new();
$Coding_Std->Set_Title("<B>Coding standards</B>");
$Coding_Std->Set_Line_Colour('white','white');
$Coding_Std->Set_Row([&Link_To($selflink,"Perl coding standards","?Perl_Std=1",'black',['newwin']),"The Perl coding standards used by the GSC Bioinformatics group"]);
$Coding_Std->Printout();

my $Code = HTML_Table->new();
$Code->Set_Title("<B>Some Useful routines</B>");
$Code->Set_Line_Colour('white','white');

my @include = ('fasta.pl','searchDB.pl','restore_DB.pl','backup_DB.pl','quick_view.pl','build_pod.pl');

my $Description;
$Description->{'fasta.pl'} = "A simple command line program that generates Fasta files (using Seq_Data.pm)";
$Description->{'searchDB.pl'} = "A simple command line database search tool";
$Description->{'restore_DB.pl'} = "A simple command line program used to restore a Table from another backed up database";
$Description->{'backup_DB.pl'} = "A routine that allows users to back up current versions of a database, or given tables within it";
$Description->{'quick_view.pl'} = "A simple run viewing script that can be run from the command line";
$Description->{'build_pod.pl'} = "A script documenting script that enables users to generate a simple html file system navigator ";

foreach my $file (@include) {
    $Code->Set_Row(
		   [
		    &Link_To($herelink,$file,"?Try=$file",'black',['newwin']),
		    $Description->{$file}
		    ]
		   );
}
$Code->Printout();

my $Module=HTML_Table->new();
$Module->Set_Line_Colour('white','white');
$Module->Set_Title("<B>Some Useful Modules</B>");

my @modules = ('Table_man','example','Views_man','Protocol_man');

my $Description;
$Description->{'Table_man'} = "Database I/O:  Using the GSDB.pm module to view/edit Table data";
$Description->{'Views_man'} = "Histograms/Tables: generating Histograms and HTML_Tables for perl scripts";
$Description->{'Protocol_man'} = "New Lab Protocols: Entering new Lab Protocols";
$Description->{'example'} = "Examples of I/O: Extracting Data from the Database for viewing";

foreach my $file (@modules) {
    my ($title,$desc) = split ":", $Description->{$file};
    $Module->Set_Row(
		     [
		      $title,
		      &Link_To("$home/$file.pl",$title,undef,'black',['newwin']),
		      $desc
		      ]
		   );
}
$Module->Printout();

my $Dir=HTML_Table->new();
$Dir->Set_Line_Colour('white','white');
$Dir->Set_Title("<B>Perl Directories</B>");

my @directs = ('RGTools','SDB','alDente','Sequencing');

my $Description;
$Description->{'RGTools'} = "Generic set of perl tools";
$Description->{'SDB'} = "Generic tools that can be used for interacting with an SQL database";
$Description->{'alDente'} = "Tools that are used for the alDente LIMS";
$Description->{'Sequencing'} = "alDente tools specific to the 'Sequencing' application (currently many of these are still in the 'alDente' module)";

foreach my $dir (@directs) {
    my $desc = $Description->{$dir};
    $Dir->Set_Row(
		  [
		   &Link_To("$help?Help=$dir"."_modules",$dir,undef,'black',['newwin']),
		   $desc
		   ]
		  );
}

$Dir->Printout();

my $API=HTML_Table->new();
$API->Set_Line_Colour('white','white');
$API->Set_Title("<B>Some Useful APIs</B>");

my @apis = ('Object','DB_Object','DBIO','Reads','alDente_API','Sequencing_API');

my $Description;
$Description->{'Object'} = "Basic objects (inherited by most other objects)";
$Description->{'DB_Object'} = "Basic Database record objects";
$Description->{'DBIO'} = "Database I/O object (including connection method)";
$Description->{'Reads'} = "Read handling object";
$Description->{'alDente_API'} = "API access to standard alDente information";
$Description->{'Sequencing_API'} = "Custom sequencing data accessor functions)";

foreach my $module (@apis) {
    my $desc = $Description->{$module};
    my $scope = 'Core/SDB';
    if ($module =~/alDente/) { $scope = 'Core/alDente' }
    if ($module =~/Sequencing/) { $scope = 'Sequencing'}

    $API->Set_Row(
		  [
		   &Link_To("/$perldoc_home/lib/perl/$scope/$module.html",$module,undef,'black',['newwin']),
		   $desc
		   ]
		  );
}

$API->Printout();

my $DB=HTML_Table->new();
$DB->Set_Line_Colour('white','white');
$DB->Set_Title("<B>The sequence Database</B>");
$DB->Set_Row([&Link_To($help,'Laboratory',"?User=Guest&Help=LaboratoryContext",'black',['newwin']),'Database schema']);
$DB->Set_Row([&Link_To($help,'Sequencing',"?User=Guest&Help=SequencingContext",'black',['newwin']),'Database schema']);
$DB->Set_Row([&Link_To($homelink,'Relationships',"?Tree=1&TableName=Plate",'black',['newwin']),'Display table relationships']);
$DB->Set_Row([&Link_To($help,'New Changes',"?User=Guest&Quick+Help=New_Changes",'black',['newwin']),"New database changes in release $code_version"]);
$DB->Printout();

print &Views::Heading("Search current modules for routines");

print <<SEARCH;

<form METHOD="POST" ACTION="$home/SDB_code.pl" ENCTYPE="application/x-www-form-urlencoded" NAME="Modules">
<input TYPE="hidden" NAME="Table" VALUE="SearchIndex">
<input TYPE="text" NAME="String" SIZE='20'>
<input TYPE="submit" Name="Find" VALUE="Search for String in Module Index" STYLE="background-color:yellow">

<BR><b>Choose Modules to search:</B>
<TAble width=1000><TR><TD>
<input TYPE="radio" Name="All" OnClick="all_boxes(document.Modules,'Modules')"><B>All</B> 
</TD><TD width = 800>
SEARCH
    
my @modules = ('alDente','SDB','RGTools','Sequencing'); # split "\n",try_system_command("ls $module_dir");

my $index = 0;
foreach my $mod (@modules) {
#    unless ($mod=~/\.pm$/) {next;}
    print "<input TYPE='checkbox' Name='Modules' VALUE=$mod>$mod<BR>";
    if ($index>9) {print "</TD><TD width=800>"; $index=0;}
    $index++;
}
print "</TD></TR></Table>";

print "<P>";
print "<B>Search : </B>";
print radio_group(-name=>'SearchArea',-values=>['Routine Name','Comments']);
print " (including comments for input & defaults)";

#print "<input TYPE='radio' Name='SearchArea' VALUE=Routine Name CHECKED=1>Routine Name";
#print "<input TYPE='checkbox' Name='SearchArea' VALUE=Comments>Comments";

print "</Form>";

print "</TD></TR></Table>";

&leave;

sub leave {
    
    print $BS->close();
    exit;
}

########################################################################
sub _perl_std {
print <<END_HTML;
<h1>GSC Perl Coding Standards</h1>
<span class=smaller>
Conventions that must be strictly enforced:
<ul>
<li>Indent the code properly.
<pre>
    if (\$1) {
        unless (\$2) {
            if (\$3) {
                ........
            }
        }
    }
    else {
        for (\$i = 0; \$i < 5; \$i++) {
	    while (\$count < 10) {
                ........
            }
        }
    }
</pre>
<li>Put the opening curly bracket on the same line as the keyword. Also line up the closing curly bracket of a mulit-line block with the keyword:
<pre>
    if (\$1) {
    ........
    }
</pre>
<li>Put blank lines between chunks of code that do different things.
<li>Naming conventions for identifiers such as variables, functions, classes/packages:
<ul>
<li>Use meaningful names. 
<pre>
e.g. use \$gene instead of \$g
</pre> 
However, there could be exceptions to this rule, such as for the variable \$i that is often used as a loop counter.
<li>Separate words within variable and function names with underscores. 
<pre>
e.g. use \$gene_therapy instead of \$genetherapy or \$GeneTherapy
e.g. use \$get_foreign_keys instead of \$getforeignkeys or \$GetForeignKeys
</pre>
<li>Module and class names should begin with a capital letter and use mixed case with NO underscores separating words. 
<pre>
e.g. use GeneChip instead of gene_chip or Gene_Chip or geneChip
</pre>
</ul>
<li>Use letter cases and underscores to indicate scope or nature:
<ul>
<li>Constants -> All upper cases.
<pre>
e.g. \$LIBRARY_NAME
</pre>
<li>Global variables: Variables with package scope and visible outside the package (i.e. declared with "use vars" or "our") -> First letter of each word is uppercase to indicate package scope.
<pre>
e.g. \$Library_Name
</pre>
<li>Package variables: Variables with package scope and NOT visible outside the package (i.e. declared with "my" outside a routine) -> Addition of leading underscore in the variable name to denote it is NOT used outside the package.
<pre>
e.g. \$_Library_Name
</pre>
<li>Local variables: Variables with local/function scope (i.e. declared with "my" or "local" inside a routine) -> All lower cases. 
<pre>
e.g. \$library_name
</pre>
<li>Function names should be all lower cases. An exception is for function names that contain class names.
<pre>
e.g. get_foreign_keys (no class name inside)
e.g. get_GeneChip (GeneChip is a class name)
</pre>
<li>Private functions: Functions that should only be used inside a package -> Leading underscore.
<pre>
e.g. _get_info
</pre>
<li>Public functions: Functions that could be called outside a package -> No leading underscore.
<pre>
e.g. get_info
</pre>  
</ul>
</ul>

Conventions that are recommended:
<ul>
<li>No space before the semicolon.
<li>Put space around most operators:
<pre>
    \$x = \$y * 2 if (\$x != \$y);
</pre>
<li>Line up corresponding items vertically:
<pre>
    \$n = 12345 &nbsp;&nbsp; if (\$opt_n);
    \$l = abc &nbsp;&nbsp;&nbsp;&nbsp; if (\$opt_l);
    \$a = 12345abc if (\$opt_a);
</pre>
<li>Use parentheses with function calls:
<pre>
print sort keys %info;
print(sort(keys(%info)));
</pre>
</ul>	
Note that these conventions are derived from 2 existing Perl coding standards:
<ul>
<li>perlstyle - used by the general Perl community (<a href='http://www.perldoc.com/perl5.8.0/pod/perlstyle.html'>http://www.perldoc.com/perl5.8.0/pod/perlstyle.html</a>)
<li>Ensembl coding and naming conventions (<a href='http://www.ensembl.org/Docs/ensembl9/#conventions'>http://www.ensembl.org/Docs/ensembl9/#conventions</a>)  
</ul>
It is strongly recommended that you read these documents as well since they contain additional conventions/suggestions that will help to improve the maintainability of Perl code.
</span>		
END_HTML
}
########################################################################
