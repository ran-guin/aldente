#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use CGI qw(:standard);

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use RGTools::HTML_Table;
use RGTools::RGIO;

use alDente::SDB_Defaults;
use alDente::Web;

use vars qw(%Defaults $URL_temp_dir $html_header $dbc %Configs);

#start html.
#print header('text/html'),
#    start_html('Query Tool');
my $host = param('Server') || $Configs{PRODUCTION_HOST};
my $dbase = param('Database') || $Configs{PRODUCTION_DATABASE};
my $user = param('Username') || 'viewer';
my $pwd  = param('Pwd')  || 'viewer';
$dbc = new SDB::DBIO(-host=>$host,-dbase=>$dbase,-user=>$user,-password=>$pwd,-connect=>1);
print &alDente::Web::Initialize_page(-dbc => $dbc);
print h2('Query Tool');
print "<span class='smaller'>";

my $timestamp = &timestamp();
my $homelink = 'query_tool.pl';
my $keyword = join ',', param('Keyword');
my @keywords = split ',', $keyword;         ## allow comma-separated list of keywords
my $driver = param('DB_Driver') || 'mysql';
my $host = param('Server') ||  $Configs{PRODUCTION_HOST};
my $dbase = param('Database') || $Configs{PRODUCTION_DATABASE};
my $user = param('Username') || 'viewer';
my $pwd  = param('Pwd')  || 'viewer';

my $split    = param('Split');
my $toggle   = param('Toggle');
my $border   = param('Border');
my $width    = param('Width') || '100%';
my $file     = param('File') || '';
my $file_type = param('File_Type') || 'html';
my $subdir    = param('Subdirectory') || 'tmp';

if ($file =~/^(.*)\.$file_type$/i) { $file = $1 }   ## strip extension from file if it is redundant ##

my $output   = '';
if (param('Help')) {
    print "<ul><li>Queries:",
    "<ul><li>NO semicolons after the SQL statements.",
    "<li>Multiple SQL statments can be executed at the same time to generate multiple result sets.",
    "<li>Invididual SQL statements can be commented out by preceding the statements with '#'.",
    "</ul>",
    "<li>Other features:",
    "<ul><li>Highlight keyword: If entered then all occurence of the keyword in the result set will be highlighted for easier spotting.",
    "<li>Show column titles every X rows: If entered then every X rows in the result set will have the column titles displayed.",
    "<li>Show results in new window: If checked then the result set will be displayed in a new browser window.",
    "</ul>",
    "</ul>";
}
else {
#(no ending semicolon needed; SQL statements can be commented out by preceding with '#'):
    #If displaying result set in a new window, then don't display the query form.
    unless (param('NewWin')) {
	#Toggle display result set in a new window or not.
	my $newwin = 0;
	if (param('ToggleNewWin') && (param('ToggleNewWin') eq 'true')) {
  	    $newwin = 1;
	}

	if ($newwin) {
	    print start_form(-action=>$homelink,-method=>'post',-target=>'_blank');
	}
	else {
	    print start_form(-action=>$homelink,-method=>'post');
	}
	
	print hidden(-name=>'Query Tool');

	print "DB Driver: " . textfield(-name=>'DB_Driver',-default=>$driver,-size=>8) . &hspace(5);
	print "Server: " . textfield(-name=>'Server',-default=>$host,-size=>12) . &hspace(5),
	"Database: " . textfield(-name=>'Database',-default=>$dbase,-size=>12) . hspace(5),
	"Username: " . textfield(-name=>'Username',-default=>$user,-size=>12) . hspace(5),
	"Password: " . password_field(-name=>'Pwd',-default=>$pwd,-size=>12) . br . br,
	"Query: (" . &Link_To("query_tool.pl","Help","?Help=1",'blue',['newwin']). ")" . br . textarea(-name=>'Query',-cols=>'160',-rows=>'10') . br,
	submit(-name=>'Run',-style=>"background-color:$Settings{EXECUTE_BUTTON_COLOUR}") . hspace(5),
	"Highlight keyword(s): " . textfield(-name=>'Keyword',-default=>'',-size=>15) . hspace(5),
	"Show column titles every: " . textfield(-name=>'Title_Per',-default=>'',-size=>'3') . " rows" . hspace(5),
	"Split Output on: " . 
	    textfield(-name=>'Split',-default=>'',-size=>4),
	    &hspace(4),
	"Toggle Colour on: " . 
	    textfield(-name=>'Toggle',-default=>'',-size=>4),
	    hspace(4),
	"Width: " . 
	    textfield(-name=>'Width',-default=>'100%',-size=>4),
	    hspace(4),
### new line ##
	    vspace(5),
	    "Save to File: " . 
		Show_Tool_Tip(
			      textfield(-name=>'File',-default=>'',-size=>20,-force=>1),
			      "writes to:<BR>/opt/alDente/www/dynamic/$subdir/<BR>(no extension needed)",-tip_style=>"left:-40em"),
		    radio_group(-name=>'File_Type',-values=>['html','csv'],-default=>'html'),
		    hspace(10),

		    checkbox(-name=>'NewWin',-label=>'Show results in new window',-checked=>$newwin,-onClick=>"goTo('$homelink','?ToggleNewWin=' + this.checked);") . &hspace(10) ,
		    checkbox(-name=>'Border',-checked=>0) . &hspace(20) . 
			"<B>Write To ->" . 
			    radio_group(-name=>'Subdirectory',-values=>['tmp','share'],-default=>'tmp') .
			    "</form><hr>";
    }
    
    if (param('Run')) {
	my $query = param('Query');
	$query =~s/\s/ /g;        ## replace linefeeds with simple space 
	my $title_per = param('Title_Per');
	$dbc = new SDB::DBIO(-host=>$host,-dbase=>$dbase,-user=>$user,-password=>$pwd,-connect=>1);	
	while ($query) {
	    my $current_query;
	    
	    if ($query =~ /\n+/) {
		$current_query = $`;
		$query = $';
		if (($current_query =~ /^\#/) || ($current_query =~ /^\s$/)) {next;}
	    }
	    else {
		$current_query = $query;
		$query = '';
	    }
	    
	    unless ($current_query =~ /^\#/) {
		
		if ($current_query =~ /^select|^desc|^show|^describe|^explain/i) { #The query will return a result set.
		    my $sth = $dbc->dbh()->prepare(qq{$current_query}) || error("Prepare query fail: ");
		    $sth->execute() || error("Execute query fail: ");
		    
		    my $table = HTML_Table->new(-width=>$width, -autosort=>1,-border=>$border);
		    $table->Set_Class('small');
		    $table->Set_Headers(\@{$sth->{NAME}});
		    $table->Toggle_Colour_on_Column($toggle) if $toggle;
		    print h3('Results: ' . $sth->rows() . " records returned");
		    if ($file) {
			print "Link to new File: <A Href='/SDB/dynamic/$subdir/$file.$file_type'>$file.$file_type</A><BR>";
		    }
		    print "<font size=1>Query = $current_query</font><br>";

		    my $row;
		    my $rows=0;
		    my $title_per_count=0;
		    while($row = $sth->fetchrow_arrayref) {
			my @record;
			
			#See if we need to display column titles.
			if (($title_per) && ($title_per_count == $title_per)) {
			    print $table->Printout("$URL_temp_dir/query.$timestamp.html",$html_header);
			    $table->Printout();
			    $table = HTML_Table->new(-autosort=>1,-border=>$border);
			    $table->Set_Class('small');
			    $table->Set_Headers(\@{$sth->{NAME}});
			    $title_per_count = 0;
			}
			
			for (my $i = 0; $i < @{$row}; $i++) {
			    my $col = $row->[$i];
			    if (!defined $col) { #Check for NULL values
				$col = 'undef';	
			    }
			    $col = &format($col);
			    push(@record, $col);
			}
			$table->Set_Row(\@record);
			if ($file && ($file_type !~/html/i)) {
			    $output .= join "\t", @record;
			    $output .= "\n";
			}
			$title_per_count++;
			$rows++;
		    }
		    
		    $sth->finish();
		    if ($file && ($file_type =~/html/i)) {
			$output .= $table->Printout(); ## "$URL_temp_dir/$file.$file_type",$html_header);
		    }
		    
		    print $table->Printout("$URL_temp_dir/query.$timestamp.html",$html_header);
		    $table->Printout();
		    print "<br><b>$rows row(s) returned</b>";
		}
		else { #The query will NOT return a result set.
		    my $rows=0;
		    print br;
		    $rows = $dbc->dbh()->do(qq{$current_query}) || error("Do query fail: ");

		    print h3("Results: $rows returned");
		    print "<font size=1>Command = $current_query</font><br>";
		    
		    if (!$rows) {
			error("Do query fail: ");
		    }
		    else {
			$rows += 0;
			print "<br><b>$rows row(s) affected</b>";
		    }
		}
		
		print hr;
	    }
	}
	$dbc->disconnect();
    }

    if ($file) {
	open(FILE,">$URL_temp_dir/$file.$file_type") or die "Cannot open file : $URL_temp_dir/file.$file_type\n";
	print FILE $output;
	close FILE;
	Message("Wrote to file : $URL_temp_dir/$file.$file_type");
    }
    exit;
}

#################
# Format record
###############
sub format {
#############
    my $value = shift;
    
    foreach my $keyword (@keywords) { #Check to see if data contains keyword for highlights
	if ($value =~ /$keyword/g) { $value = "<font color='red'><b>$value</b></font>"; last; }
    }
    if ($split) {
	$value =~s/$split/$split<BR>/g;
    }
    return $value;
}

print "</span>";
#print end_html;
print &alDente::Web::unInitialize_page($page);

sub error {
    my $msg = shift;

    print "<font color='red'>$msg$DBI::err ($DBI::errstr)</font>";
}



