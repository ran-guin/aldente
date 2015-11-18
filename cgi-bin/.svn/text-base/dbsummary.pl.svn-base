#!/usr/local/bin/perl

################################################################
#
# CVS Revision: $Revision: 1.12 $
# Commit Date:  $Date: 2004/12/03 16:25:01 $
# CVS Tag     : $Name:  $
#
################################################################

################################################################
use CGI qw/:all/;
use CGI::Carp qw(fatalsToBrowser);

use POSIX qw(strftime);

use Benchmark;
use GD;
use GD::Graph;
use GD::Graph::bars; # was GIFgraph::bars
#use Math::VecStat qw(max min maxabs minabs sum average);
use Statistics::Descriptive;
use Date::Calc qw(Today Now Delta_Days Add_Delta_Days Date_to_Days);

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
#use Imported::gscweb;
use Imported::MySQLdb;
use Imported::MySQL_GSC;
use Imported::MySQL_Tools;
use alDente::ChromatogramHTML;
use alDente::SDB_Defaults;
use alDente::Security;
use alDente::Employee;
use alDente::Web;
use SDB::CustomSettings;
use SDB::DBIO;
 
use RGTools::RGIO;

GD::Graph::colour::read_rgb("$config_dir/rgb.txt");

use vars qw($homelink $session_id $user $dbase $project $login_name $q $Security $Connection $user_id $Connection);
$session_id = param('Session');
$user = param('User');
$dbase = param('Database');
$login_name = param('Login_Name');
$project = param('Project');
$homelink = "barcode.pl?Session=$session_id&User=$user&Database=$dbase&Project=$project";


# retrieve user id
my $dbc = new SDB::DBIO(-host=>$Defaults{SQL_HOST},-dbase=>$dbase,-user=>'labuser',-password=>$pwd);
($user_id) = &Table_find($dbc,"Employee","Employee_ID","WHERE Employee_Name like '$user'");
my $pwd = 'manybases';
$dbc->set_local('user_id',$user_id);

my $eo = new alDente::Employee(-dbc=>$dbc,-id=>$user_id);
$eo->define_User();

#my $dbc = DBI->connect("DBI:mysql:$dbase:$Defaults{SQL_HOST}" , 'viewer', 'viewer', {RaiseError => 1});
$Security = alDente::Security->new(-dbc=>$dbc,-user_id=>$user_id);

################################################################
my $DBASE = 'lims02';
$Imported::MySQL_GSC::debug = 0;

################################################################
# The local URL of the script
$PROGNAME = $ENV{SCRIPT_NAME};
my $PARAMS = "Session=$session_id&Project=$project&Database=$dbase&Login_Name=$login_name&User=$user";
################################################################

#$Connection = DBIO->new(-dbase=>$dbase,-user=>'labuser',-password=>$pwd,-trace_level=>$trace_level,-connect=>0);
#$dbc = $Connection->connect();

$DETAILEDHISTBIN = 25;
$DEBUG=0;
$DEFAULTPHRED=20;
$APPLET_WIDTH=1000;
$APPLET_HEIGHT=250;
$CVSDATE = q{ $Date: 2004/12/03 16:25:01 $ };
$VERSION = q{ $Revision: 1.12 $ };
$RELEASE = q{ $Name:  $ }; 
if($CVSDATE =~ /\$.*?:\s*(.*)\s*\$/) { $CVSDATE=$1;}
if($VERSION =~ /\$.*:\s*(.*?)\s*\$/) { $VERSION=$1;}
if($RELEASE =~ /\$.*:\s*(.*?)\s*\$/) { $RELEASE=$1;}

#Color stuff.
my $STDRAINBOW = ["white","vlightpurple","lightpurple","vlightblue","lightcyan","lightgreen","vlightgreen","vlightyellow","vlightorange",
		  "vlightred","lightred","mediumgrey"];
my $STDPHREDSCALE = [1000,900,800,700,600,500,400,300,200,100,1,0];

# Current time for the benchmark. 
$time_top=new Benchmark;

$q = new CGI;
my $page;

print &alDente::Web::Initialize_page($dbc,-include=>'Home,Login,Contact,Help,Hostinfo');
unless ($User_Home) {
    if (defined %Department && exists %Department->{$user_id}) {
	$User_Home = %Department->{$user_id};
    }
    if ($User_Home =~ /Bioinformatics|Mapping|Lib_Construction|None/i || $User_Home eq '') {$User_Home = 'Cap_Seq'} #####Temporary
}
unless($Current_Department) {$Current_Department = $User_Home}
&alDente::Web::page_icons($Current_Department);
#print &alDente::Web::Tab_Bar($Current_Department);
#print &alDente::Web::app_info_bar();
#$page->SetHome("$PROGNAME");
# Javascript for trace-viewing. It calls the java class for displaying traces.
#$page->AddJavaScript("http://olweb.bcgsc.bc.ca/intranet/View_Chromatogram/view_chromatogram.js");
my $b_report0 = new Benchmark;

################################################################
# SCOPED REPORTING
################################################################
# If a scoped report is requested, call DetailedReport
#    scope = project,library,sequencer
if (param('scope')) {
  #$page->TopBar();
  Header();
  if(param('scope') =~ /sequence/) {
    if(param('scopevalue') =~ /(.*)\-(.*)/) {
      my $db = Imported::MySQL_GSC::GetSequenceDb();
      $scopesearch=GetScopeSearch($db,param('scope'),param('scopevalue'));
      my $plateid = $scopesearch->GetRecord(0)->GetFieldValue("FK_Plate__ID");
      print 
	  "<table width=100% border=0 cellpadding=0 cellspacing=0>",
	  "<tr><td width=100% align=right>";
      PrintIcons($1);
      print "</td></tr></table>";
      print "<h2>Run for Plate $plateid Well $2</h2>";
      ScopeDescriptionTable($scopesearch);
      print "<br>";
      SequenceView($1,$2);
    }
  } elsif (param('scope') =~ /runplate/i) {
    ################################################################
    # Produce a gel-style graphic view of all reads in a run
    ################################################################
    RunPlate();
  } else {
    my $option = param('option') || "";
    DetailedReport(param('scope'),param('scopevalue'),$option,[20,30,40]);
    my $b_report1=new Benchmark;
    print
	"<br><hr>",
	"<table><tr><Td>",
	"<span class=small>Report generation time: ",FormatBench($b_report1,$b_report0),"&nbsp;&nbsp;&nbsp;",
	"<br>",
	"Report date: ",scalar localtime,"</span>",
	"</td></tr></table>";
  }
  my $time_bottom = new Benchmark;
#  print FormatBench($time_top,$time_bottom);
  #$page->BottomBar();
  print &alDente::Web::unInitialize_page($page);
  exit;
}
################################################################

################################################################
# Create a search based on the CGI parameters.
#
# Pass to ParamSearch either "runs" to retrieve runs or
# "reads" to retrieve reads.
sub ParamSearch {
  my $searchtype = shift || "runs";

  my ($seq_id_name, $plate_id_name);
  my ($searchkey, $criterialist);
  my $db = Imported::MySQL_GSC::GetSequenceDb();
  $search = $db->CreateSearch(int(rand(1000000)));

  #####
  # Runs and Plate Views use the Run table
  if ($searchtype =~ /runs|plates/i) {
    $search->SetTable("Run");
    $seq_id_name = "Run_ID";
    $plate_id_name = "FK_Plate__ID";
  }
  # Set-up Reads and Analysis to use the Clone_Sequence table
  elsif ($searchtype =~ /reads|analysis/i) {
    $search->SetTable("Clone_Sequence");
    $search->AddFK({"field"=>"Run.ID"});
    $seq_id_name = "FK_Run__ID";
    $plate_id_name = "Run.FK_Plate__ID";

    # Slow Grows/No Grows
    if (param('growth')) {
      if (param('growth') eq "Exclude All") {
	$search->AddField({"field"=>"Clone_Sequence.Growth","value"=>"OK"});
	$criterialist .= "Slow Grows/No Grows: Exclude All.<br>";
      }
      elsif (param('growth') eq "") {
	$search->AddField({"field"=>"Clone_Sequence.Growth","value"=>['OK','Slow Grow']});
	$criterialist .= "Slow Grows/No Grows: Include Slow.<br>";
      }
      else {
	$criterialist .= "Slow Grows/No Grows: Include All.<br>";
      }
    }
  }
  #####

  $search->AddFK({"field"=>"RunBatch.ID","fktable"=>"Run"});
  $search->AddFK({"field"=>"Equipment.ID","fktable"=>"RunBatch"});
  $search->AddFK({"field"=>"Employee.ID","fktable"=>"RunBatch"});

  # Parse all the search terms.
  foreach $searchkey (param) {
    my $searchvalue = param($searchkey);
    # Limit the number of retrieved records
    if ($searchkey =~ /limit_offset|limit_num/i && $searchtype !~ /analysis/i) {
      my $off = param('limit_offset');
      my $num = Extract_Values([param('limit_num'),10]);
      # override batch size for plate view, as web browser bog down when displaying 50 plates
      if ($searchtype =~ /plates/) { $num = 10 }
      $search->Limit({'range'=>"[$off,$num]"});
    }

    # Plate ID - this is a value-based search
    if($searchkey =~ /plateid/i) {
      $searchvalue =~ s/pla//ig;
      # do a range based search
      # e.g.: 60-75
      if ($searchvalue =~ m/-/) {
	my ($start, $end) = split("\s*-\s*", $searchvalue);
	my @plates;
	for (my $i = $start; $i <= $end; $i++) {
	  push @plates, $i;
	}
	if(@plates) {
	  $search->AddField({"field"=>$plate_id_name,"value"=>\@plates});
	  $criterialist .= "Plate IDs: ".join(", ",@plates)."<br>";
	}
      }
      # do a comma separated value based search
      # e.g.: 66, 67
      else {
	my @plates = split(",\s*",$searchvalue);
	if (@plates) {
	  $search->AddField({"field"=>$plate_id_name,"value"=>\@plates});
	  $criterialist .= "Plate IDs: ".join(", ",@plates)."<br>";
	}
      }
    }

    # Run ID - this is a value-based search
    if($searchkey =~ /runid/i) {
      $searchvalue =~ s/run//ig;
      # do a range based search
      # e.g.: 4560-4575
      if ($searchvalue =~ m/-/) {
	my ($start, $end) = split("\s*-\s*", $searchvalue);
	my @runs;
	for (my $i = $start; $i <= $end; $i++) {
	  push @runs, $i;
	}
	if(@runs) {
	  $search->AddField({"field"=>$seq_id_name,"value"=>\@runs});
	  $criterialist .= "Run IDs: ".join(", ",@runs)."<br>";
	}
      }
      # do a comma separated value based search
      # e.g.: 4566, 4567
      else {
	my @runs = split(",\s*", $searchvalue);
	if(@runs) {
	  $search->AddField({"field"=>$seq_id_name,"value"=>\@runs});
	  $criterialist .= "Run IDs: ".join(", ",@runs)."<br>";
	}
      }
    }

    # Comment field - this is a regexp search
    if($searchkey =~ /comment/i) {
      my @comments = split(",",$searchvalue);
      if(@comments) {
	$search->AddField({"field"=>"RunBatch.Sequence_Batch_Comments","regexp"=>\@comments});
	$criterialist .= "Comments text: ".join(", ",@comments)."<br>";
      }
    }

    # Sequencer - this is a value based search
    if($searchkey =~ /sequencer/i) {
      my @sequencers = param('sequencer');
      if(NotEmpty(@sequencers)) {
	$search->AddField({"field"=>"Equipment.Equipment_Name","value"=>\@sequencers});
	$criterialist .= "Sequencers: ".join(", ",@sequencers)."<br>";
      }
    }

    # Subdirectory - this is a regexp search
    if($searchkey =~ /subdirectory/i) {
      if($searchvalue ne "") {
	$search->AddField({"field"=>"Run_Directory","regexp"=>$searchvalue});
	$criterialist .= "Sample Sheet: $searchvalue<br>";
      }
    }

    # Run parameters
    if($searchkey =~ /(.*)_check/) {
      my $param = $1;
      my $dbfield = $param;
      $dbfield =~ s/ /_/g;
      my $min = (defined(param("${param}_min")))?param("${param}_min"):"";
      my $max = (defined(param("${param}_max")))?param("${param}_max"):"";
      if($min ne "" || $max ne "") {
	$search->AddField({"field"=>"Run.$dbfield","range"=>"[$min,$max]"});
	$criterialist .= "$param: [$min,$max]<br>\n";
      }
    }

    # Time pick
    if($searchkey =~ /timepick/) {
      if($searchvalue =~ /today/i) {
	$search->DateRefine({"field"=>"Run.Sequence_DateTime","filter"=>"today"});
	$criterialist .= "Time Period: Today<br>";
      }
      if($searchvalue =~ /thisweek/i) {
	$search->DateRefine({"field"=>"Run.Sequence_DateTime","filter"=>"thisweek"});
	$criterialist .= "Time Period: This week<br>";
      }
      if($searchvalue =~ /lastweek/i) {
	$search->DateRefine({"field"=>"Run.Sequence_DateTime","filter"=>"lastweek"});
	$criterialist .= "Time Period: Last week<br>";
      }
      if($searchvalue =~ /last7days/i) {
	$search->AddField({"field"=>"Run.Sequence_DateTime","agerange"=>"[0d,7d]"});
	$criterialist .= "Time Period: Last 7 days<br>";
      }
      if($searchvalue =~ /thismonth/i) {
	$search->DateRefine({"field"=>"Run.Sequence_DateTime","filter"=>"thismonth"});
	$criterialist .= "Time Period: This month<br>";
      }
      if($searchvalue =~ /last30days/i) {
	$search->AddField({"field"=>"Run.Sequence_DateTime","agerange"=>"[0d,30d]"});
	$criterialist .= "Time Period: Last 30 days<br>";
      }
      if($searchvalue =~ /lastmonth/i) {
	$search->DateRefine({"field"=>"Run.Sequence_DateTime","filter"=>"lastmonth"});
	$criterialist .= "Time Period: Last month<br>";
      }
      if($searchvalue =~ /last n days/i) {
	my $lastndays = 7;
	if(defined param('lastndays') && param('lastndays') ne "") {
	  $lastndays = param('lastndays');
	}
	$search->AddField({"field"=>"Run.Sequence_DateTime","agerange"=>"[0d,${lastndays}d]"});
	$criterialist .= "Time Period: Last $lastndays days<br>";
      }
      if($searchvalue =~ /last n weeks/i) {
	my $lastnweeks = 2;
	if(defined param('lastnweeks') && param('lastnweeks') ne "") {
	  $lastnweeks = param('lastnweeks');
	}
	$search->AddField({"field"=>"Run.Sequence_DateTime","agerange"=>"[0d,${lastnweeks}w]"});
	$criterialist .= "Time Period: Last $lastnweeks weeks<br>";
      }
      if($searchvalue =~ /last n months/i) {
	my $lastnmonths = 2;
	if(defined param('lastnmonths') && param('lastnmonths') ne "") {
	  $lastnmonths = param('lastnmonths');
	}
	$search->AddField({"field"=>"Run.Sequence_DateTime","agerange"=>"[0d,${lastnmonths}M]"});
	$criterialist .= "Time Period: Last $lastnmonths months<br>";
      }
      if($searchvalue =~ /weekof/i) {
	my $weekofday = strftime "%Y-%m-%d",localtime;
	if(defined param('weekofday') && param('weekofday') ne "") {
	  $weekofday = param('weekofday');
	}
	$search->DateRefine({"field"=>"Run.Sequence_DateTime","filter"=>"weekofday=$weekofday"});
	$criterialist .= "Time Period: Week of $weekofday<br>";
      }
      if($searchvalue =~ /monthyear/i) {
	my $month = param('month');
	my $year  = param('year');
	$search->DateRefine({"field"=>"Run.Sequence_DateTime","filter"=>"month=$month year=$year"});
	$criterialist .= "Time Period: Month $month Year $year<br>";
      }

      # dates: YYYY-MM-DD, YYYY-MM-DD
      if ($searchvalue eq "dates") {
	my $dates;
	if (param('dates')) {
	  $dates = param('dates');
	}
	$dates =~ s/\s+//g;
	my @dateset = split(",", $dates);
	$search->AddField({"field"=>"Run.Sequence_DateTime", "function"=>"DATE_FORMAT:'%Y-%m-%d'", "value"=>\@dateset});
	$criterialist .= "Dates: " . join(", ", @dateset) . "<br>\n";
      }

      # date range: YYYY-MM-DD to YYYY-MM-DD
      if ($searchvalue =~ /daterange/i) {
 	my @today = Today();
	my $todaydate = Date_to_Days(@today);
	my ($startdate, $startdays, $enddate, $enddays);
	# convert YYYY-MM-DD dates to # of days ago
	if (param('startdate')) {
	  $startdate = param('startdate');
	  $startdate =~ m/(\d{4})\-(\d{2})\-(\d{2})/;
	  $startdays = $todaydate - Date_to_Days($1,$2,$3);
	}
	if (param('enddate')) {
	  $enddate = param('enddate');
	  $enddate =~ m/(\d{4})\-(\d{2})\-(\d{2})/;
	  $enddays = $todaydate - Date_to_Days($1,$2,$3);
	}
	$search->AddField({"field"=>"Run.Sequence_DateTime","agerange"=>"[${enddays}d,${startdays}d]"});
	$criterialist .= "Time Period: Date range: From $startdate to $enddate<br>";
      }

      # time range: YYYY-MM-DD HH:MM:SS to YYYY-MM-DD HH:MM:SS
      if ($searchvalue =~ /timerange/i) {
	my ($starttime, $endtime);
	if (param('starttime')) {
	  $starttime = param('starttime');
	}
	if (param('endtime')) {
	  $endtime = param('endtime');
	}
	$search->AddField({"field"=>"Run.Sequence_DateTime","agerange"=>"[$starttime,$endtime]"});
	$criterialist .= "Time Period: Time range: From $starttime to $endtime<br>";
      }
    }

    # Employee search - this is a value search
    if($searchkey =~ /employee_name/) {
      my @emps = param('employee_name');
      if(NotEmpty(@emps)) {
	$search->AddField({"field"=>"Employee.Employee_Name","value"=>\@emps});
	$criterialist .= "Employee: ";
	foreach (@emps) { $criterialist .= $_ . ", " }
	$criterialist .= "<br>";
      }
    }

    # Chemistry - this is a value search - there is no point in resolving the FK since
    # this is the field we are searching by
    if ($searchkey =~ /chemistry_name/) {
      my @chems = param('chemistry_name');
      if(NotEmpty(@chems)) {
	$search->AddField({"field"=>"Run.FK_Chemistry_Code__Name","value"=>\@chems});
	$criterialist .= "Chemistry: ";
	foreach (@chems) { $criterialist .= $_ . ", " }
	$criterialist .= "<br>";
      }
    }

    # Library - this is a value search - there is no point in resolving the FK since
    # this is the field we are searching by
    if ($searchkey =~ /library/) {
      my @libs = param('library');
      if(NotEmpty(@libs)) {
	$search->AddFK({"field"=>"Plate.ID","fktable"=>"Run"});
	$search->AddField({"field"=>"Plate.FK_Library__Name","value"=>\@libs});
	$criterialist .= "Libraries: ";
	foreach (@libs) { $criterialist .= $_ . ", " }
	$criterialist .= "<br>";
      }
    }

    # Project - this is a value search
    if ($searchkey =~ /project/) {
      my @projs = param('project');
      if(NotEmpty(@projs)) {
	$search->AddFK({"field"=>"Plate.ID","fktable"=>"Run"});
	$search->AddFK({"field"=>"Library.Name","fktable"=>"Plate"});
	$search->AddFK({"field"=>"Project.ID","fktable"=>"Library"});
	$search->AddField({"field"=>"Project.Project_Name","value"=>\@projs});
	$criterialist .= "Projects: ";
	foreach (@projs) { $criterialist .= $_ . ", " }
	$criterialist .= "<br>";
      }
    }

    # Test runs
    if ($searchkey =~ /testruns/) {
      if ($searchvalue =~ /exclude/i) {
	$search->AddField({"field"=>"Run.Run_Status","regexp"=>"Production"});
	$criterialist .= "Test Runs: Excluded<br>";
      }
      if ($searchvalue =~ /only/i) {
	$search->AddField({"field"=>"Run.Run_Status","regexp"=>"Test"});
	$criterialist .= "Test Runs: Included<br>";
      }
    }

    # Foil piercing
    if ($searchkey =~ /foilpiercing/) {
      if ($searchvalue =~ /yes/i) {
	$search->AddField({"field"=>"Run.Foil_Piercing","value"=>1});
	$criterialist .= "Foil Piercing: Yes<br>";
      }
      if ($searchvalue =~ /no/i) {
	$search->AddField({"field"=>"Run.Foil_Piercing","value"=>0});
	$criterialist .= "Foil Piercing: No<br>";
      }
    }
  }
  return ($search,$criterialist);
}

################################################################
# Adds appropriate viewfields to a search depending on
# whether we are listing RUNS or READS.

sub AddViewFields {
  my $search = shift;
  my $searchtype = shift;
  if($searchtype =~ /runs|plates/i) {
    RunList($search);
  } elsif ($searchtype =~ /reads/i) {
    ReadList($search);
  }
  my $orderkey;
  foreach $order (param('order1'),param('order2')) {
    if($order =~ /date/i) {
      $search->Order({"field"=>"Run.Sequence_DateTime",'order'=>'desc'});
    } elsif ($order =~ /sequencer/i) {
      $search->Order({"field"=>"Equipment.Equipment_Name"});
    }
  }
  return $search;
}
#
################################################################

################################################################
# List the runs which were found by the search
#
# There are four distinct routes that searching can take:
#   - list runs   : add view fields for "reads"
#   - list reads  : add view fields for "runs"
#   - show plates : show the plates
#   - do analysis : don't add any viewfields, don't execute!!!
#

if (defined param('search')) {
  #$page->TopBar();
    #print &alDente::Web::Initialize_page();
  Header();
  my $scope = param('search');
  $scope =~ tr/A-Z/a-z/;
  if ($scope =~ /.*?\s+(.*)/i) { $scope = $1; }
  # Creates a search object which is filtered using CGI parameters pass to it from
  # a search form.
  my ($search, $criterialist) = ParamSearch($scope);
  # Depending on what the purpose for this search is, we could possibly be adding
  # view fields to it right now.
  if($scope =~ /read|run|plates/i) {
    AddViewFields($search, $scope);
    $search->Execute();
    # print "<p>The SQL SELECT statement used: [",$search->{_sql},"]</p>\n";
  }
  my $date = strftime "%d-%B-%Y %H:%M",localtime;
  print "<br><b>Search parameters:</b><br>";
  print $criterialist;
  print "<br>";

  if ($scope =~ /plates/i) {

    ################################################################
    # A colourful plate view with supporting information and
    # quick-link buttons to other views of this run
    ################################################################

    PrintIcons($runid);

    my $off = param('limit_offset') || 0;
    #my $num = Extract_Values([param('limit_num'),10]);
    my $num = 10; # batch size prefence is overriden for Plate views
    my $nextoff = ($off)?$off+$num:$num;
    my $prevoff = ($off>$num)?$off-$num:0;
    print "<table width=100% border=0 cellspacing=0 cellpadding=0><tr>";
    if($off >= 2*$num) {
      print
	  "<td width=5>",
	  start_form,
	  HiddenMultiple(['limit'],param),
	  hidden(-name=>'limit_offset',-value=>0,-override=>1),
	  hidden(-name=>'limit_num',-value=>$num,-override=>1),
	  hidden(-name=>'search',-value=>1,-override=>1),
	  "<input type='submit' name='First ", $num, "' value=' First ", $num ," '>",
	  end_form,
	  "</td>";
    }
    if($off) {
      print
	  "<td width=5>",
	  start_form,
	  HiddenMultiple(['limit'],param),
	  hidden(-name=>'limit_offset',-value=>$prevoff,-override=>1),
	  hidden(-name=>'limit_num',-value=>$num,-override=>1),
	  hidden(-name=>'search',-value=>1,-override=>1),
	  "<input type='submit' name='Previous ", $num, "' value=' Previous ", $num, " '>",
	  end_form,
	  "</td>";
    }
    # Print the Next graphic only if there were $num records in this search.
    # This means that there may be more records.
    if ($search->get_nrecs == $num) {
      print
	  "<td width=5>",
	  start_form,
	  HiddenMultiple(['limit'],param),
	  hidden(-name=>'limit_offset',-value=>$nextoff,-override=>1),
	  hidden(-name=>'limit_num',-value=>$num,-override=>1),
	  hidden(-name=>'search',-value=>1,-override=>1),
	  "<input type='submit' name='Next ", $num, "' value=' Next ", $num, " '>",
	  end_form,
	  "<td>";
    }
    print
	  "<td align=right>",
	start_form,
	HiddenMultiple(['limit','searchform','search'],param),
	hidden(-name=>'searchform',-value=>1,-override=>1),
	"<input type='submit' name='submit' value='Another Search'>",
	end_form,
	"</td>",
	"</tr></table>";
    foreach (my $run=0; $run < $num; $run++) {
      # Quit out of loop if we run out of records.
      if($run >= $search->get_nrecs) {last}
      my $rec       = $search->GetRecord($run);
      my $runid     = $rec->GetFieldValue("Run_ID");
      my $date      = $rec->GetFieldValue("Sequence_DateTime");
      my $dow       = $rec->GetFieldValue("Day");
      my $plateid   = $rec->GetFieldValue("FK_Plate__ID");
      my $seq_comments  = $rec->GetFieldValue("Sequence_Comments") || "None";
      my $batch_comments  = $rec->GetFieldValue("Sequence_Batch_Comments") || "None";
      my $sequencer = $rec->GetFieldValue("Equipment_Name");
      my $subdirectory = $rec->GetFieldValue("Run_Directory");
      my $employee = $rec->GetFieldValue("Employee_Name");
      print "<table border='0' cellpadding='2' cellspacing='0'><tr>";
      print "<td>";
      my $legendflag = ($run==$runs-1 || !($run%3))?1:0;
      my $phredvalue = (defined param('phredvalue'))?param('phredvalue'):20;
      print htmlPlateViewPhred();
      htmlPlateView({"runid"=>$runid,"legendflag"=>$legendflag});
      print htmlPlateViewLegend;
      print
	  "</td>",
	  "<td valign=top style='padding:15px;'>";

      print "<table border=0 cellspacing=0 cellpadding=0><tr><td class='darkgrey'>\n";
      print "<table border=0 cellspacing=1 cellpadding=3>\n";
      print "<tr>\n";
      print "<td align=center class=vlightbluebw>\n";
      print "<span class=vlarger><b>Run Information for $runid</b></span>\n";
      print "</td></tr>\n";

      my $labelstart = "<td class=vdarkblue valign=center align=center style='padding:3px;'><span class=small><b>\n";
      my $labelend = "</b></span></td></tr>\n";
      my $contentstart = "<tr class='vvvlightgrey'><td align=center class=vvlightgrey>\n";
      my $contentend = "</td></tr>\n";

      print $labelstart . "Date" . $labelend;
      print $contentstart . "$dow, $date" . $contentend;
      print $labelstart . "Plate ID" . $labelend;
      print $contentstart . "$plateid" . $contentend;
      print $labelstart . "Run Comments" . $labelend;
      print $contentstart . "$seq_comments" . $contentend;
      print $labelstart . "Run Batch Comments" . $labelend;
      print $contentstart . "$batch_comments" . $contentend;
      print $labelstart . "Sample Sheet" . $labelend;
      print $contentstart . "$subdirectory" . $contentend;
      print $labelstart . "Sequencer" . $labelend;
      print $contentstart . "$sequencer" . $contentend;
      print $labelstart . "Operator" . $labelend;
      print $contentstart . "$employee" . $contentend;

      print "</td></tr></table>\n";
      print "</td></tr></table>\n";

      print
	  "</td>",
	  "</tr>",
	  "</table>";
      print "<hr>";
    }
    #$page->BottomBar();
    print &alDente::Web::unInitialize_page($page);
    exit;
  } elsif ($scope =~ /analysis/i) {
    if (BasePairSummary({"scope"=>$search})) {
      print "No records found for this search.<BR>";
      print "<BR><BR>";
      print "<hr>",
      print "$date<BR>";
      my $time_bottom = new Benchmark;
      print FormatBench($time_top,$time_bottom);
      #$page->BottomBar();
      print &alDente::Web::unInitialize_page($page);
      exit;
    }
    print "<Br>";
    $search->ResetSearch();
    $db=$search->get_db;
    # Get all unique sequencers in this search
    $search->AddViewField({'field'=>"Equipment.Equipment_Name",'alias'=>'Sequencer'});
    $search->AddGroup({'field'=>"Equipment.Equipment_Name"});
    $search->Execute();
    print "<p>The SQL SELECT statement used: [",$search->{_sql},"]</p>\n";
    $nr = $search->get_nrecs;
    my $sequencers;
    for($i=0;$i<$nr;$i++) {
      push(@{$sequencers},$search->GetRecord($i)->GetFieldValue("Sequencer"));
    }
    $search->ResetSearch();
    my ($phredvalues,$pvhistdvalue) = PrintHistogramForm();
    DisplayPhredHistograms({"phredvalues"=>$phredvalues,
			    "search"=>$search,
			    "sequencers"=>$sequencers,
			    "pvhistdvalue"=>$pvhistdvalue});
  } elsif (! $search->get_nrecs) {
    print "<span class=large>No runs were found with these criteria.</span><br><br><br>";
  } else {
    my $off = param('limit_offset');
    my $num = Extract_Values([param('limit_num'),10]);
    $nextoff = ($off)?$off+$num:$num;
    $prevoff = ($off>$num)?$off-$num:0;
    print
	"<table width=100% border=0 cellspacing=0 cellpadding=0><tr>";
    if ($off >= 2*$num) {
      print
	  "<td width=5>",
	  start_form,
	  HiddenMultiple(['limit'],param),
	  hidden(-name=>'limit_offset',-value=>0,-override=>1),
	  hidden(-name=>'limit_num',-value=>$num, -override=>1),
	  hidden(-name=>'search',-value=>1,-override=>1),
	  "<input type='submit' name='First ", $num, "' value=' First ", $num ," '>",
	  end_form,
	  "</td>";
    }
    if($off) {
      print 
	  "<td width=5>",
	  start_form,
	  HiddenMultiple(['limit'],param),
	  hidden(-name=>'limit_offset',-value=>$prevoff,-override=>1),
	  hidden(-name=>'limit_num',-value=>$num,-override=>1),
	  hidden(-name=>'search',-value=>1,-override=>1),
	  "<input type='submit' name='Previous ", $num, "' value=' Previous ", $num, " '>",
	  end_form,
	  "</td>";
    }
    print
	"<td width=5>",
	start_form,
	HiddenMultiple(['limit'],param),
	hidden(-name=>'limit_offset',-value=>$nextoff,-override=>1),
	hidden(-name=>'limit_num',-value=>$num,-override=>1),
	hidden(-name=>'search',-value=>1,-override=>1),
	"<input type='submit' name='Next ", $num, "' value=' Next ", $num, " '>",
	end_form,
	"<td>";
    print
	"<td align=right>",
	start_form,
	HiddenMultiple(['limit','searchform','search'],param),
	hidden(-name=>'searchform',-value=>1,-override=>1),
	"<input type='submit' name='submit' value='Another Search'>",
	end_form,
	"</td>",
	"</tr></table>";
    $search->PrintHTML({
      'title'=>"Run Runs",
      'center'=>'yes',
      'summary'=>'yes',
      'excludetypes'=>[".*blob.*"],
      'printfieldname'=>'0',
      'printfieldtype'=>'0',
      'extratagsfields'=>{'Run_ID'=>'align=center class=vvlightgrey|<b>%%VALUE%%</b>',
			  'Run_Status'=>'align=center|',
			  'Sequence_DateTime'=>'align=center|',
			  'Employee'=>'align=center|'},
      'links'=>{"Run_ID"=>"$URL_domain${PROGNAME}?scope=RunID&scopevalue=%Run_ID%&option=bpsummary&$PARAMS",
		"Equipment_Name"=>"$URL_domain/cgi-bin/intranet/sequence/summary/dbsummary-front?view=recentruns&seq_key=D3700-1&size=50&show_hist=1&$PARAMS",
		"Employee_Name"=>"$URL_domain${PROGNAME}?weekofday=2001-09-06&month=September&year=2001&timepick=all&employee_name=%Employee_Name%&testruns=Include&foilpiercing=Both&order1=Date&order2=Sequencer&limit_offset=0&limit_num=10&search=List+Runs&$PARAMS",
	       },
    });
  }
  my $time_bottom = new Benchmark;
  print FormatBench($time_top,$time_bottom);
  #$page->BottomBar();
  print &alDente::Web::unInitialize_page($page);
  exit;
}

################################################################
# Run search form
if (defined param('searchform')) {
  #$page->TopBar();
  Header();

  # Get all distinct employees
  my @emp   = Imported::MySQL_GSC::GetDistinctEmployees();
  my @chem  = Imported::MySQL_GSC::GetDistinctChemistries();
  my @projs = Imported::MySQL_GSC::GetDistinctProjects();
  my @libs  = Imported::MySQL_GSC::GetDistinctLibraries();
  my %libnames = Imported::MySQL_GSC::GetDistinctLibraryLabels();
  @emp  = ("",sort @emp);
  @chem = ("",sort @chem);
  @projs = ("",sort @projs);
  @libs = ("",sort @libs);
  my $today = strftime "%Y-%m-%d",localtime;
  my $today_month = strftime "%B",localtime;
  my $today_year = strftime "%Y",localtime;
  my @years;
  for(my $i=5;$i>=0;$i--) {
    push(@years,$today_year-$i);
  }

  print start_form(-method=>'post');
  print
      "<table border=0 cellspacing=0 cellpadding=5 class=vvvlightgrey><tr>",
      "<td valign=top>";
  print "<table border=0 cellspacing=0 cellpadding=5 width='100%'><tr class=lightyellowbw>",
        "<td valign=top>";
  print qq{<img src="/intranet/icons/simpsons_spyglass.jpeg" border="0" vspace="5" hspace="5" align=right>\n};
  print "<span class=smaller>Welcome<br>to the<br></span><span class=larger>Run Database<br><b>Search Form</b></span>";
  print "</td></tr></table>\n";
  print
      "<table border=0 cellspacing=0 cellpadding=5><tr>";

  my $month_popup = popup_menu(-name=>"month",
			       -values=>["January","February","March","April","May","June","July","August","September","October","November","December"],
			       -defaults=>$today_month,
			       -style=>"font-size:12px;");
  my $year_popup = popup_menu(-name=>'year',
			      -values=>\@years,
			      -default=>$today_year);

  # make some nice default date strings
  my @today = Today();
  my @now = Now();
  my @yday = Add_Delta_Days(Today(), -1);
  my $tdate = sprintf("%04d",$today[0]) . '-' . sprintf("%02d",$today[1]) . '-' . sprintf("%02d", $today[2]);
  my $ydate = sprintf("%04d",$yday[0]) . '-' . sprintf("%02d",$yday[1]) . '-' . sprintf("%02d", $yday[2]);
  my $ttime = $tdate . ' ' . sprintf("%02d",$now[0]) .':' . sprintf("%02d",$now[1]) . ':' . sprintf("%02d",$now[2]);
  my $ytime = $ydate . ' ' . sprintf("%02d",$now[0]) .':' . sprintf("%02d",$now[1]) . ':' . sprintf("%02d",$now[2]);;

  @timepick = (
	       [ "today", "Today" ],
	       [ "thisweek", "This week" ],
	       [ "lastweek", "Last week" ],
	       [ "last7days", "Last 7 days" ],
	       [ "thismonth", "This month" ],
	       [ "last30days", "Last 30 days" ],
	       [ "lastmonth", "Last month" ],
	       [ "Last n days", qq|Last <input type="text" name="lastndays"  size="3" style="font-size:12px;"> days| ],
	       [ "Last n weeks", qq|Last <input type="text" name="lastnweeks" size="3" style="font-size:12px;"> weeks| ],
	       [ "Last n months", qq|Last <input type="text" name="lastnmonths" size="3" style="font-size:12px;"> months| ],
	       [ "Weekof", qq|Week of <input type="text" name="weekday" value="$tdate" size="10" style="font-size:12px;"> <span class="small">(YYYY-MM-DD)</span>| ],
	       [ "monthyear", qq|Month $month_popup Year $year_popup| ],
	       [ "dates", qq|Dates: <span class="small">(YYYY-MM-DD, YYYY-MM-DD)</span><br><input type="text" name="dates" value="$ydate, $tdate" size="22" style="font-size: 12px;">| ],
	       [ "daterange", qq|Date range: <span class="small">(YYYY-MM-DD)</span><br>From <input type="text" name="startdate" value="$ydate" size="10" maxlength="10" style="font-size: 12px;"> to <input type="text" name="enddate" value="$tdate" size="10" maxlength="10" style="font-size: 12px;">| ],
	       [ "timerange", qq|Time range: <span class="small">(YYYY-MM-DD HH:MM:SS)</span><br>From <input type="text" name="starttime" value="$ytime" size="19" maxlength="19" style="font-size: 12px;"><br>to <input type="text" name="endtime" value="$ttime" size="19" maxlength="19" style="font-size: 12px;">| ],
	       );
  print
      "<td valign=top>\n",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Time Period</span>",
      "</td></tr></table>\n";

  print qq[<table border="0" cellpadding="0" cellspacing="1">\n];
  foreach my $aref (@timepick) {
    print qq[<tr><td valign="top"><input type="radio" name="timepick" value="$$aref[0]">&nbsp;</td>\n];
    print qq[<td valign="top">$$aref[1]</td></tr>\n];
  }
  print qq[<tr><td valign="top"><input type='radio' name='timepick' value='all' CHECKED>&nbsp;</td><td valign="top">Any date</td></tr>];
  print qq[</table\n\n];

  print
      "</td>";
  print
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Sequencer</span></td></tr></table>",
      checkbox_group(-name=>'sequencer',-values=>["MB1","MB2","MB3","D3700-1","D3700-2","D3700-3","D3700-4","D3700-5","D3700-6"],-linebreak=>1),
      "</td>";
  print
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Run ID</span></td></tr></table>",
      textfield(-name=>'runid',-value=>'',-size=>15),
      "<br><span class=smaller>(<b>4567, 4290</b> or a range <b>3200-3210</b>)</span><br>",
      "&nbsp;<br>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Plate ID</span></td></tr></table>",
      textfield(-name=>'plateid',-value=>'',-size=>15),
      "<br><span class=smaller>(<b>67, 71</b> or a range <b>60-75</b>)</span><br>&nbsp;<br>",
      "&nbsp;<br>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Subdirectory</span></td></tr></table>",
      textfield(-name=>'subdirectory',-value=>'',-size=>15),
      "<br><span class=small>(<a href='http://web02.bcgsc.bc.ca:9673/gin/books/mysql/manual_Regexp.html'>REGEX</a> search <b>11a\.B</b>)</span>",
      "<br>&nbsp;<br>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Comment field text</span></td></tr></table>",
      textfield(-name=>'comment',-value=>'',-size=>15),
      "<br><span class=small>(Applies to Run Batch Comments field)</span></td>";
  print
      "</tr></table>",
      "</td>",
      "</tr>";
  print
      "<tr><td class=lightyellowbw>",
      "Submit search and show results as ",
      submit(-name=>'search',-value=>'list_runs',-label=>' Runs ')," ",
      submit(-name=>'search',-value=>'list_reads',-label=>' Reads ')," ",
      submit(-name=>'search',-value=>'plateview',-label=>' Plates ')," ",
      submit(-name=>'search',-value=>'analysis',-label=>' Phred Analysis '),
      "</td></tr>";

  print
      "<tr>",
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=3><tr class='vvvlightgrey'>",
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Project</span></td></tr></table>",
      scrolling_list(-name=>"project",-value=>\@projs,-size=>20,-multiple=>'true',-default=>"",-style=>"font-size:12px;"),
      "</td>",
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Library</span></td></tr></table>",
      scrolling_list(-name=>"library",-value=>\@libs,-labels=>\%libnames,-size=>20,-multiple=>'true',-default=>"",-style=>"font-size:12px;"),
      "</td>",
      "</tr></table>",
      "</td>",
      "</tr>";
  print
      "<tr><td class=lightyellowbw>",
      "Submit search and show results as ",
      submit(-name=>'search',-value=>'list_runs',-label=>' Runs ')," ",
      submit(-name=>'search',-value=>'list_reads',-label=>' Reads ')," ",
      submit(-name=>'search',-value=>'plateview',-label=>' Plates ')," ",
      submit(-name=>'search',-value=>'analysis',-label=>' Phred Analysis '),
      "</td></tr>";
  print
      "<tr>",
      "<td>",
      "<table border=0 cellspacing=0 cellpadding=3><tr>",
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Test Runs</span></td></tr></table>",
      radio_group(-name=>"testruns",
		  -values=>["Include","Exclude","Only"],
		  -default=>"Exclude",
		  -linebreak=>1),
      "<br>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Slow Grows/No Grows</span></td></tr></table>",
      radio_group(-name=>"growth",
		  -values=>["Include All","Include Slow","Exclude All"],
		  -default=>"Include Slow",
		  -linebreak=>1),
      "<br>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Foil Piercing</span></td></tr></table>",
      radio_group(-name=>"foilpiercing",
		  -values=>["Yes","No","Both"],
		  -default=>"Both",
		  -linebreak=>1),
      "</td>",
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Run Parameters</span></td></tr></table>",
      "<table border=0 cellspacing=0 cellpadding=0>",
      "<tr><td></td><td class=small align=center>min</td><td class=small align=center>max</td></tr>",
      FormRange("Injection Voltage"),
      FormRange("Injection Time"),
      FormRange("Run Voltage"),
      FormRange("Run Time"),
      FormRange("Run Temperature"),
      FormRange("Agarose Percentage"),
      FormRange("PMT1"),
      FormRange("PMT2"),
      "</table>",
      "</td>";
  print
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Employee</span></td></tr></table>",
      scrolling_list(-name=>"employee_name",-value=>\@emp,-size=>10,-multiple=>'true',-default=>"",-style=>"font-size:12px;"),
      "</td>";
  print
      "<td valign=top>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Chemistry</span></td></tr></table>",
      scrolling_list(-name=>"chemistry_name",-value=>\@chem,-size=>10,-multiple=>'true',-default=>"",-style=>"font-size:12px;"),
      "</td>";
  print
      "</tr></table>",
      "</td>",
      "</tr>";
  print
      "<tr><td class=lightyellowbw>",
      "Submit search and show results as ",
      submit(-name=>'search',-value=>'list_runs',-label=>' Runs ')," ",
      submit(-name=>'search',-value=>'list_reads',-label=>' Reads ')," ",
      submit(-name=>'search',-value=>'plateview',-label=>' Plates ')," ",
      submit(-name=>'search',-value=>'analysis',-label=>' Phred Analysis '),
      "</td></tr>";
  print
      "<tr class='vlightbluebw'>",
      "<td>",
      "<table><tr><td>",
      "Sort by ",
      "</td>",
      "<td>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>First Order Field</span></td></tr></table>",
      popup_menu(-name=>'order1',-value=>['---','Date','Sequencer'],-default=>"Date"),
      "</td>",
      "<td>",
      "<table border=0 cellspacing=0 cellpadding=4 width='100%'><tr><td valign=top class=lightgreenbw>",
      "<span class=small>Second Order Field</span></td></tr></table>",
      popup_menu(-name=>'order2',-value=>['---','Date','Sequencer'],-default=>"Sequencer"),
      "</td></tr></table>",
      "</td></tr>";
  print
      "<tr class='vlightbluebw'>",
      "<td>",
      "Results per page: ",
      "<input type='radio' name='limit_num' value='10'> 10 ",
      "<input type='radio' name='limit_num' value='25'> 25 ",
      "<input type='radio' name='limit_num' value='50' checked> 50 ",
      "<input type='radio' name='limit_num' value='100'> 100 ",
      "</td></tr>";
  print
      "<tr><td>",
      "<p><b>Search Help</b>",
      "<ul>",
      "<li>this page is one large form, the multiple submit buttons all do the same thing, the extra buttons are just there for your convenience",
      "<li>different search fields will be searched using boolean AND",
      "<li>lists of possible values for the same field will be searched using OR",
      "<li>some search fields will override the values in others. If you select a plate ID and then select a date, you will receive nothing unless the run with that plate ID falls within your date specification.",
      "<li>checkbox fields which are unchecked will be used to narrow down the search.",
      "<li>run parameters will only be search if their associated checkbox is checked and either the min and/or max value(s) are defined.",
      "<li>send comments, suggestions and feature requests to Kevin Teague &lt;kteague\@bcgsc.bc.ca&gt;",
      "</ul>",
      "</td></tr>";
  print
      "</table>",
      hidden(-name=>'limit_offset',-value=>0,-override=>1),
      end_form;

  my $time_bottom = new Benchmark;
  print FormatBench($time_top,$time_bottom);
  #$page->BottomBar();
  print &alDente::Web::unInitialize_page($page);
  exit;
}

sub FormRange {

  my $fieldname = shift;
  my $value;
  $value .= "<tr>";
  $value .= "<td>";
  $value .= checkbox(-name=>"${fieldname}_check",-label=>"",-checked=>0,-value=>1);
  $value .= $fieldname." ";
  $value .= "</td>";
  $value .= "<td> &nbsp;";
  $value .= textfield(-name=>"${fieldname}_min",-value=>'',-size=>4,-style=>'font-size:10px;');
  $value .= "</td>";
  $value .= "<td>&nbsp;";
  $value .= textfield(-name=>"${fieldname}_max",-value=>'',-size=>4,-style=>'font-size:10px;');
  $value .= "</td>";
  $value .= "</tr>\n";
  return $value;

}

################################################################
# TOP LEVEL REPORTING - FROM FILE
################################################################
# If no parameters were passed, and nothing on the command line
# dump out a stored copy of the top-level report.
if(! @ARGV && ! param) {
  my $file = "/usr/local/apache${PROGNAME}-toplevel.html";
  if(! open(FILE,$file))  {
    #$page->TopBar();
    Header();
    print "<h1>Database view currently unavailable</h1>";
    my $time_bottom = new Benchmark;
    print FormatBench($time_top,$time_bottom);
    #$page->BottomBar();
    print &alDente::Web::unInitialize_page($page);
    exit;
  }
  while(<FILE>) {
    print;
  }
  close(FILE);
  exit;
}
################################################################

################################################################
# TOP LEVEL REPORTING - DYNAMIC
################################################################
# Do the top level report.
#$page->TopBar();
Header();
print "<h1>Run Database Summary</h1>";
my $t00 = new Benchmark;

# On average, calculate stats for phred 20,30,40.

my $phredvalues = [20,30,40];

################################################################
# Top-level base pair summary

print "You can search the database from <a href=\"$PROGNAME?searchform=1&$PARAMS\">here</a>.<br><br>";

BasePairSummary();

################################################################
# Top-level scope reports : LIBRARY, PROJECT, SEQUENCER
# This is generated for the top-level database summary page.
# This page contains reports for each of the scopes.
foreach $scope ("Library","Project","Sequencer") {
  ScopeSummary($scope,$phredvalues);
}
# Afterwards, check how long it took us to do this and  date stamp the report
my $t01 = new Benchmark;
print "<br><br>";
print "<span class=small>Report generation time: ",timestr(timediff($t01,$t00)),"</span><br>";
print "<span class=small>Report date: ",scalar localtime,"</span>";
#$page->BottomBar();
print &alDente::Web::unInitialize_page($page);
exit;

sub RunPlate {
    my ($well,$runid);
    my $db = Imported::MySQL_GSC::GetSequenceDb;
    if(defined param('scopevalue') && param('scopevalue') =~ /^(\d+)$/) {
      $runid=$1;
    } else {
      print "<h2>ERROR: Incorrect CGI parameter list.</h2>";
      print "<p>Expected <b>script?scope=runplate&scopevalue=RUNID</b></p>";
      print "<p>where RUNID is the numerical run ID</p>";
      #$page->BottomBar();
      print &alDente::Web::unInitialize_page($page);
      exit;
    }
    my ($row_size, $col_size) = getRowColSize( $runid );
    my $reads = $row_size * $col_size;
    my $rowheight=7;  # Height of each read in the image
    my $n_bp=1200;      # Width of the image - each bp is 1 pixel.
    my $topmargin=85;
    my $leftmargin=40;
    my $rightmargin=60;
    my $im = new GD::Image($n_bp/2 + $leftmargin + $rightmargin, $reads * $rowheight + $topmargin);
    #my $font = "$config_dir/trebuc.ttf";
    my $qual;
    my @color_qual;
    my (@rgb,$hue,$tone_f,$tone_r);

    # Allocate the colours for the image
    my $maxqual=70;
    my $qualstep=2;
    my $qualshift = 10;
    my $maxhue = 300;
    for ($qual=0;$qual<=$maxqual;$qual+=$qualstep) {
      $hue = int($maxhue*($qual-$qualshift)/($maxqual-$qualshift));  # Maps $qual onto 0-300 (red-blue)
      if($hue<0) {$hue=0}
      #      $tone_f = int(255*($hue%60)/60);      # Maps $qual onto 0-255 linearly (forward)
      $tone_f = int(255*(1/(1+exp(-(($hue%60)-30)/6))));
      $tone_r = 255-$tone_f;
      if($hue < 60) {
	@rgb = (255,$tone_f,0);
      } elsif ($hue <120) {
	@rgb = ($tone_r,255,0);
      } elsif ($hue < 180) {
	@rgb = (0,255,$tone_f);
      } elsif ($hue < 240) {
	@rgb = (0,$tone_r,255);
      } else {
	@rgb = ($tone_f,0,255);
      }
      $hue = int(255*$hue/$maxhue);
      $color_qual[$qual/$qualstep] = $im->colorAllocate(@rgb);
      $color_vec[$qual/$qualstep] = $im->colorAllocate($hue,$hue,$hue);
      $color_gen[$qual/$qualstep] = $im->colorAllocate($hue,0,0);
    }
    my $white = $im->colorAllocate(255,255,255);
    my $black = $im->colorAllocate(0,0,0);
    my $dgreen = $im->colorAllocate(0,175,0);
    my $dred = $im->colorAllocate(175,0,0);
    my $dyellow = $im->colorAllocate(175,175,0);
    my $background = $im->colorAllocate(100,100,100);
    my $blue = $im->colorAllocate(0,0,255);

    # fills
    $im->fill(1,1,$background);
    $im->filledRectangle(0, 0, $n_bp, $topmargin, $white);
    $im->filledRectangle(0, 0, $leftmargin, $reads * $rowheight + $topmargin, $white);
    $im->filledRectangle( $n_bp / 2 + $leftmargin + 1
			, 0
			, $n_bp / 2 + $leftmargin + $rightmargin
			, $reads * $rowheight + $topmargin, $white
			);
    my ($run,$bp,$phred,$bpcolor,$bp1status,$bp2status,$posx);

    #Provide a legend for the well, capillary, read length and Q20.
    my $line_xoffset = 12;
    my $line_yoffset = 3;
    #$im->stringTTF($font,0,$topmargin-20,'Well',7,0,$blue);
    $im->string(gdTinyFont,0,$topmargin-25,'Well',$blue);
    $im->line(0+$line_xoffset,$topmargin-$line_yoffset,0+$line_xoffset,$topmargin-20+$line_yoffset,$blue);
    #$im->stringTTF($font,20,$topmargin-20,'Cap',7,0,$blue);
    $im->string(gdTinyFont,25,$topmargin-25,'Cap',$blue);
    $im->line(20+$line_xoffset,$topmargin-$line_yoffset,20+$line_xoffset,$topmargin-20+$line_yoffset,$blue);
    #$im->stringTTF($font,$n_bp/2+$leftmargin+2,$topmargin-20,'Leng',7,0,$blue);
    $im->string(gdTinyFont,$n_bp/2+$leftmargin+2,$topmargin-25,'Leng',$blue);
    $im->line($n_bp/2+$leftmargin+2+$line_xoffset,$topmargin-$line_yoffset,$n_bp/2+$leftmargin+2+$line_xoffset,$topmargin-20+$line_yoffset,$blue);
    #$im->stringTTF($font,$n_bp/2+$leftmargin+25,$topmargin-20,'Q20',7,0,$blue);
    $im->string(gdTinyFont,$n_bp/2+$leftmargin+25,$topmargin-25,'Q20',$blue);
    $im->line($n_bp/2+$leftmargin+25+$line_xoffset,$topmargin-$line_yoffset,$n_bp/2+$leftmargin+25+$line_xoffset,$topmargin-20+$line_yoffset,$blue);

    # Provide a scale
    for($bp=0;$bp<=$n_bp;$bp++) {
      $posx = int($leftmargin+$bp/2);
      if(! ($bp % 100)) {
	$im->line($posx,$topmargin,$posx,$topmargin-5,$black);
	#$im->stringTTF($font,$posx-(length($bp)-1)*2,$topmargin-8,$bp,7,0,$black);
	$im->string(gdTinyFont,$posx-(length($bp)-1)*2,$topmargin-13,$bp,$black);
      } elsif (! ($bp % 25)) {
	$im->line($posx,$topmargin,$posx,$topmargin-2,$black);
      }
    }
    my $read_summary = Imported::MySQL_GSC::GetReadSummary($db,$runid);
    my $run_summary = Imported::MySQL_GSC::GetRunSummary($db,$runid);
    my $phred_lengths = Imported::MySQL_GSC::GetPhredLengths($db,{'phreds'=>[20],'scope'=>"runid:$runid",'testruns'=>'yes'});
    my $imgmap = "";
    print "<div width=100% align=right>";
    PrintIcons($runid);
    print "</div><br>";
    print "<span class=small>";
    foreach $key (sort keys %{$run_summary}) {
      print "<b><span class=vdarkbluetext>$key</span></b> ".$run_summary->{$key};
      print "&nbsp;&nbsp;";
    }
    print "</span><BR>";

    # Generate the Imagemap
    $imgmap .= qq{<map name="platemap">\n};
    my ($mapx1,$mapx2,$mapy1,$mapy2,$alttext);
    my $index = 0;
    my $update_well = 1;
    my $well = 0;
    while ($index < $reads) {
      my $well_text = chr(int($index/$col_size)+65).sprintf("%02d", $index % $col_size + 1);
      #$im->stringTTF($font,0,$topmargin+($well+1)*$rowheight-2,$well_text,7,0,$black);
      $im->string(gdTinyFont,0,$topmargin+($index+1)*$rowheight-7.5,$well_text,$black);
      if ($well_text eq $read_summary->[$well]->{'well'}) {
	  my $p20bp = $phred_lengths->[0]->[$well];
	  my @scores = Imported::MySQL_GSC::GetScores($db,$runid,$well_text);
	  ($mapx1,$mapy1,$mapx2,$mapy2)=($leftmargin,$topmargin+$well*$rowheight,$n_bp/2+$leftmargin,$topmargin+($well+1)*$rowheight-1);
	  $alttext = "$well_text | RL ".$read_summary->[$well]->{'length'}." | QL $p20bp | QL/QR ".$read_summary->[$well]->{'ql'}."/".$read_summary->[$well]->{'qt'}." | VL/VR/VT ".$read_summary->[$well]->{'vl'}."/".$read_summary->[$well]->{'vr'}."/".$read_summary->[$well]->{'vt'}." |";
	  my $chromatogram_link = "$URL_address/view_chromatogram.pl?runid=$runid&well=$well_text&height=$APPLET_HEIGHT&width=$APPLET_WIDTH";
	  $imgmap .= qq{<area shape=rect coords="$mapx1,$mapy1,$mapx2,$mapy2" href='$chromatogram_link' target='_blank' title="$alttext">\n};
	  # For now, analyze the first $n_bp BP.
	  for ($bp=0; $bp<$n_bp; $bp+=2) {
	      $posx = $leftmargin+$bp/2;
	      # Take the average phred between the two base pairs.
	      if(defined $scores[$bp] && defined $scores[$bp+1]) {
		  $phred = int(($scores[$bp]+$scores[$bp])/2);
	      } elsif (! defined $scores[$bp+1]) {
		  $phred = $scores[$bp];
	      }
	      $bp1status = Imported::MySQL_GSC::GetBPStatus($read_summary,$well,$bp);
	      $bp2status = Imported::MySQL_GSC::GetBPStatus($read_summary,$well,$bp+1);
	      # Decide what colour to use.
	      if($bp1status =~ /vector/ || $bp2status =~ /vector/) {
		  $bpcolor = $color_vec[$phred/$qualstep];
	      } elsif($bp1status =~ /quality/ && $bp2status =~ /quality/) {
		  $bpcolor = $color_qual[$phred/$qualstep];
	      } elsif ($bp1status =~ /outside/ || $bp2status =~ /outside/) {
		  last;
	      } else {
		  $bpcolor= $color_gen[$phred/$qualstep];
	      }
	      unless ($bpcolor) {$bpcolor = $white} # If no color is defined, then use white
	      $im->filledRectangle($posx,$topmargin+$index*$rowheight,$posx+1,$topmargin+($index+1)*$rowheight-2,$bpcolor);
	  }

	  #$im->stringTTF($font,20,$topmargin+($well+1)*$rowheight-2,$read_summary->[$well]->{'capillary'},7,0,$black);
	  $im->string(gdTinyFont,20,$topmargin+($index+1)*$rowheight-7.5,$read_summary->[$well]->{'capillary'},$black);
	  #$im->stringTTF($font,$n_bp/2+$leftmargin+2,$topmargin+($well+1)*$rowheight-2,$read_summary->[$well]->{'length'},7,0,$black);
	  $im->string(gdTinyFont,$n_bp/2+$leftmargin+2,$topmargin+($index+1)*$rowheight-7.5,$read_summary->[$well]->{'length'},$black);
	  if($p20bp > 300) {
	      #$im->stringTTF($font,$n_bp/2+$leftmargin+25,$topmargin+($well+1)*$rowheight-2,$p20bp,7,0,$dgreen);
	      $im->string(gdTinyFont,$n_bp/2+$leftmargin+25,$topmargin+($index+1)*$rowheight-7.5,$p20bp,$dgreen);
	  } elsif ($p20bp > 100) {
	      #$im->stringTTF($font,$n_bp/2+$leftmargin+25,$topmargin+($well+1)*$rowheight-2,$p20bp,7,0,$dyellow);
	      $im->string(gdTinyFont,$n_bp/2+$leftmargin+25,$topmargin+($index+1)*$rowheight-7.5,$p20bp,$dyellow);
	  } else {
	      #$im->stringTTF($font,$n_bp/2+$leftmargin+25,$topmargin+($well+1)*$rowheight-2,$p20bp,7,0,$dred);
	      $im->string(gdTinyFont,$n_bp/2+$leftmargin+25,$topmargin+($index+1)*$rowheight-7.5,$p20bp,$dred);
	  }
	  $well++;
      }
      $index++;
    }
    $imgmap .= qq{</map>\n};
    print $imgmap,"\n";

    # Generate a legend
    my $legend_topx = 20;
    my $legend_width=215;
    my $legend_height = 40;
    my $legend_item_width = 5;
    my $legend_item_height = 10;
    $im->rectangle($legend_topx,0,$legend_topx+$legend_width,$legend_height,$black);
    my $qual_idx;
    my $color;
    #$im->stringTTF($font,$legend_topx+20,10,"Quality/Vector Base Pair Phred",7,0,$black);
    $im->string(gdTinyFont,$legend_topx+20,5,"Quality/Vector Base Pair Phred",$black);
    my $i = 1;
    for ($qual=0;$qual<$maxqual;$qual+=$qualstep) {
      $qual_idx = $qual/$qualstep;
      $color = $color_qual[$qual_idx];
      $im->filledRectangle($legend_topx+20+$qual_idx*$legend_item_width,15,$legend_topx+20+($qual_idx+1)*$legend_item_width,15+$legend_item_height,$color);
     $color = $color_vec[$qual_idx];
      $im->filledRectangle($legend_topx+20+$qual_idx*$legend_item_width,15+5,$legend_topx+20+($qual_idx+1)*$legend_item_width,15+$legend_item_height,$color);
      if(! ($qual % ($qualstep*2))) {
	  my $font_colour;
	  # Alternate the color so it is easier to read the legend
	  if ($i % 2 == 0) {
	      $font_colour = $black;
	  }
	  else {
	      $font_colour = $red;
	  }
	  #$im->stringTTF($font,$legend_topx+20+$qual_idx*$legend_item_width,15+$legend_item_height+10,$qual,7,0,$black);
	  $im->string(gdTinyFont,$legend_topx+20+$qual_idx*$legend_item_width,15+$legend_item_height+5,$qual,$font_colour);
	  $i++;
      }
    }
    my $text = "Run Plate View for run ID $runid";
    #$im->stringTTF($font,$legend_topx+$legend_width+30,15,$text,15,0,$black);
    $im->string(gdGiantFont,$legend_topx+$legend_width+30,0,$text,$black);
    my $subtext = "Vector sequence shown in greyscale. Non-vector, quality sequence shown";
    #$im->stringTTF($font,$legend_topx+$legend_width+30,27,$subtext,7,0,$black);
    $im->string(gdSmallFont,$legend_topx+$legend_width+30,12,$subtext,$black);
    $subtext = "in rainbow palette. Non-vector, non-quality sequence shown in dark red.";
    #$im->stringTTF($font,$legend_topx+$legend_width+30,35,$subtext,7,0,$black);
    $im->string(gdSmallFont,$legend_topx+$legend_width+30,20,$subtext,$black);
    $subtext = "Numbers to the right show read length and phred 20 length.";
    #$im->stringTTF($font,$legend_topx+$legend_width+30,43,$subtext,7,0,$black);
    $im->string(gdSmallFont,$legend_topx+$legend_width+30,28,$subtext,$black);

    # write the image to disk
    open(FILE,">/$URL_temp_dir/detail-$runid$well.png");
    binmode FILE;
    print FILE $im->png;
    close(FILE);

    # output display HTML
    print qq{<br><img src="/dynamic/tmp/detail-$runid$well.png" border=0 usemap="#platemap">};
    print "<br><span class=small><b>Placing your cursor over a read will show some statistics.</b></span>";
}

sub ScopeSummary {

  my $scope = shift;
  my $phredvalues = shift;

  my $db = Imported::MySQL_GSC::GetSequenceDb();
  my $s = $db->CreateSearch($scope.int(rand(1000000)));
  $s->SetTable("Clone_Sequence");
  $s->AddFK({'field'=>'Run.ID'});
  $s->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
  $s->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
  if($scope =~ /sequencer/i) {
    $s->AddFK({'field'=>'Equipment.ID','fktable'=>'Run'});
    $s->AddViewField({'field'=>'Equipment.Equipment_Name','alias'=>'Sequencer'});
  } else {
    $s->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
    if($scope =~ /library/i) {
      $s->AddViewField({'field'=>'Library.Library_Name','alias'=>'Library'});
    }
    $s->AddViewField({'field'=>'Project.Project_Name','alias'=>'Project'});
  }
  $s->AddViewField({'field'=>'Clone_Sequence.FK_Run__ID','alias'=>'Reads','function'=>'count'});
  if($scope =~ /library/i) {
    $s->Order({'field'=>'Library.Library_Name','order'=>'asc'});
    $s->AddGroup({'field'=>'Library.Library_Name'});
  } elsif ($scope =~ /project/i) {
    $s->Order({'field'=>'Project.Project_Name','order'=>'asc'});
    $s->AddGroup({'field'=>'Project.Project_Name'});
  } elsif ($scope =~ /sequencer/i) {
    $s->Order({'field'=>'Equipment.Equipment_Name','order'=>'asc'});
    $s->AddGroup({'field'=>'Equipment.Equipment_Name'});
  }
  $s->Execute();

  print "<h2>$scope Summary</h2>";

  print "<table><tr><td valign=bottom>\n";

  $s->PrintHTML({
    'title'=>"$scope Report",
    'center'=>'yes',
    'bench'=>'yes',
    'summary'=>'yes',
    'extratagstypes'=>{'.*int.*'=>'class=vvlightgreen align=center|'},
    'extratagsfields'=>{'NReads'=>'align=center|',
			'Library'=>'align=center|%%VALUE%%',
			'Sequencer'=>'align=center|%%VALUE%%'},
    'links'=>{"Library_Name"=>"$URL_domain${PROGNAME}?scope=Library&scopevalue=%Library_Name%&$PARAMS",
	      'Project_Name'=>"$URL_domain${PROGNAME}?scope=Project&scopevalue=%Project_Name%&$PARAMS",
	      'Equipment_Name'=>"$URL_domain${PROGNAME}?scope=Sequencer&scopevalue=%Equipment_Name%&$PARAMS"}
  });

  print "</td><td valign=bottom>";

  # Now we have to do the phred summary here.

  my $t0 = new Benchmark;

  my $nr = $s->get_nrecs;
  my @items;
  for($i=0;$i<$nr;$i++) {
    push(@items,$s->GetRecord($i)->GetFieldValue($scope));
  }

  my $cols = @{$phredvalues}+1;
  print "<table border=1 cellspacing=0 cellpadding=0>";
  print "<tr>";
  print "<tr><td colspan=$cols class=vdarkblue align=center><span class=large><b>Phred Length Summary</b></span></td></tr>";
  my $td="<td class=vdarkblue align=center><span class=vlightredtext><b>";
  my $tdend="</b></span></td>";
  print "$td $scope $tdend";
  foreach $phred (@{$phredvalues}) {
    print "$td Q $phred $tdend";
  }
  print "</tr>";

  foreach $item (@items) {
    my $search;
    my $db = Imported::MySQL_GSC::GetSequenceDb();
    my $phredscores = $db->Imported::MySQL_GSC::GetPhredLengths({'phreds'=>$phredvalues,'scope'=>"$scope:$item",'testruns'=>'no','qualityonly'=>'no'});
    print "<tr>";
    print "<td>$item</td>";
    my $phred_idx=0;
    foreach $phred (@{$phredvalues}) {
      my $avg = average(\@{$phredscores->[$phred_idx++]});
      my $tdclass = "vvlightred";
      if($avg > 400) {
	$tdclass = "vvlightgreen";
      } elsif ($avg > 300) {
	$tdclass = "vvlightyellow";
      } elsif ($avg > 200) {
	$tdclass = "vvlightorange";
      }
      print 
	  "<td class=$tdclass align=right>",
	  sprintf("%5.1f",$avg),
	  "&nbsp;</td>";
    }
    print "</tr>";
  }
  
  print "</table>";

  my $t1 = new Benchmark;
  print "<span class=small>Compute time: ",timestr(timediff($t1,$t0)),"</span>";
  print "</td></tr></table>";
}

################################################################
# Present a detailed report by project, library or machine,
# or runid.

sub DetailedReport {

  my $scope       = shift;
  my $scopevalue  = shift;
  my $option      = shift;
  my $phredvalues = shift;
  my $t00 = new Benchmark;
  # Header

  print
      "<table width=100%><tr>",
      "<td class=large valign=bottom>",
      "<span class=vdarkbluetext>",
      "<b>Detailed View for $scope $scopevalue</b>",
      "</span></td>";

  # Bench the report
  print "<td valign=top align=right>";
  if($scope =~ /runid/i) {
    my $prevrun = $scopevalue-1;
    my $nextrun = $scopevalue+1;
    print "<span class=small>Run ID Navigation:</span> ";
    print qq{<a href="${PROGNAME}?scope=$scope&scopevalue=$prevrun&option=$option&$PARAMS" onMouseOver="select(prevrun,1)" onMouseOut="select(prevrun,0)"><img src="/$image_dir/previous-s0.png" align=top width=15 name=prevrun border=0 alt="See the previous run - $scope $prevrun"></a>};
    print qq{<a href="${PROGNAME}?scope=$scope&scopevalue=$nextrun&option=$option&$PARAMS" onMouseOver="select(nextrun,1)" onMouseOut="select(nextrun,0)"><img src="/$image_dir/next-s0.png" align=top width=15 name=nextrun border=0 alt="See the next run - $scope $nextrun"></a>};
    print "<br>";
  }
  #print qq{<a href="${PROGNAME}?scope=$scope&scopevalue=$scopevalue&option=bpsummary&$PARAMS" onMouseOver="select(bpsummary,1)" onMouseOut="select(bpsummary,0)"><img src="/$image_dir/bpsummary-s0.png" name=bpsummary border=0 alt="See the base pair summary for $scope $scopevalue"></a>};
  if($scope =~ /runid/i) {
    print qq{<a href="${PROGNAME}?scope=$scope&scopevalue=$scopevalue&option=scorecard&$PARAMS" onMouseOver="select(scorecard,1)" onMouseOut="select(scorecard,0)"><img src="/$image_dir/scorecard-s0.png" name=scorecard border=0 alt="See the score card for $scope $scopevalue"></a>};
  }
  print qq{<a href="${PROGNAME}?scope=$scope&scopevalue=$scopevalue&option=histogram&$PARAMS" onMouseOver="select(histogram,1)" onMouseOut="select(histogram,0)"><img src="/$image_dir/histogram-s0.png" name=histogram border=0 alt="See the phred histograms for $scope $scopevalue"></a>};
  if($scope =~ /runid/i) {
    print qq{<a href="${PROGNAME}?scope=runplate&scopevalue=$scopevalue&$PARAMS" onMouseOver="select(runplate,1)" onMouseOut="select(runplate,0)"><img src="/$image_dir/runplate-s0.png" name=runplate border=0 alt="See the run plate for $scope $scopevalue"></a>};
  }
  #print qq{<a href="${PROGNAME}?scope=$scope&scopevalue=$scopevalue&option=runlist&$PARAMS" onMouseOver="select(runlist,1)" onMouseOut="select(runlist,0)"><img src="/$image_dir/runlist-s0.png" name=runlist border=0 alt="See the run list for $scope $scopevalue"></a>};
  #print qq{<a href="${PROGNAME}?searchform=1&$PARAMS" onMouseOver="select(searchruns,1)" onMouseOut="select(searchruns,0)"><img src="/$image_dir/search-s0.png" name=searchruns border=0 alt="Search for runs or reads"></a>};
  #print " ";
  #print qq{<a href="${PROGNAME}?$PARAMS" onMouseOver="select(toplevel,1)" onMouseOut="select(toplevel,0)"><img src="/$image_dir/toplevel-s0.png" name=toplevel border=0 alt="See the top level database summary."></a>};
  print "</td>";
  print "</tr></table>";
  my $b_summary0 = new Benchmark;
  my $db = Imported::MySQL_GSC::GetSequenceDb();
  # Prepare the scope description table. This is a description of the scope element we are
  # looking at: project, library, machine, etc.

  $scopesearch = GetScopeSearch($db,$scope,$scopevalue);

  ################################################################
  # DO BASE PAIR SUMMARY: option bpsummary
  # This is included in all the views. If the 'bpsummary' option
  # is chosen, only the base summary and scope tables are shown
  ################################################################
  print "<table><tr><td valign=top>";
  # Allow users to change the phred value in the base pair summary.
  BasePairSummary({"scope"=>$scope,
		   "scopevalue"=>$scopevalue});
  print "</td><td valign=top>";
  ScopeDescriptionTable($scopesearch);
  print "</td></tr></table>";
  my $b_summary1 = new Benchmark;
  print "<br>";

  ################################################################
  # Do a PLATE VIEW SUMMARY (color candy) if this is a runid
  # scope
  ################################################################
  if ($scope =~ /runid/i && $option =~ /bpsummary/i) {
    print htmlPlateViewPhred();
    if (param('batch')) {
      print htmlQuadPlateView( {"runid"=>$scopevalue} );
    } else {
      htmlPlateView( {"runid"=>$scopevalue} );
      print htmlBatchLinks( $scopevalue, 'bpsummary' );
    }
    print htmlPlateViewLegend();
  }
  if(! defined $option || $option !~ /\w+/ || $option =~ /bpsummary/) {return};
  #
  ################################################################

  ################################################################
  # Search for all the reads for this scope. The search is grouped
  # by sequencer. Employee group has been removed.
  ################################################################
  my $search = $db->CreateSearch("search");
  $search->SetTable("Clone_Sequence");
  $search->AddFK({'field'=>'Run.ID'});
  $search->AddFK({'field'=>'RunBatch.ID' ,'fktable'=>'Run'});
  $search->AddFK({'field'=>'Equipment.ID','fktable'=>'RunBatch'});
  if($scope =~ /runid/i) {
    $search->AddField({'field'=>'Run.Run_ID','value'=>$scopevalue});
  }
  if($scope =~ /sequencer/i) {
    $search->AddField({'field'=>'Equipment.Equipment_Name','value'=>$scopevalue});
  }
  if($scope =~ /project/i) {
    $search->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
    $search->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
    $search->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
    $search->AddField({'field'=>'Project.Project_Name','value'=>$scopevalue});
  }
  if($scope =~ /library/i) {
    $search->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
    $search->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
    $search->AddField({'field'=>'Library.Library_Name','value'=>$scopevalue});
  }
  $search->AddViewField({'field'=>'Equipment.Equipment_Name','alias'=>'Sequencer'});
  $search->AddViewField({'field'=>'FK_Run__ID'
			     ,function=>'count',alias=>'N_Reads'});
  $search->AddGroup({'field'=>'Equipment.Equipment_Name'});
  $search->Order({'field'=>'Equipment.Equipment_Name','order'=>'asc'});
  $search->Order({'field'=>'Clone_Sequence.FK_Run__ID','order'=>'desc'});
  $search->Execute();

  ################################################################
  # Get a list of the machines that did reads for this scope
  ################################################################
  @sequencers;
  for($i=0; $i<$search->get_nrecs; $i++) {
    push(@sequencers, $search->GetRecord($i)->GetFieldValue("Sequencer"));
  }
  #
  ################################################################

  ################################################################  
  # Print the Phred histogram tables. Keep track of the max # of reads in any
  # one column for the plot later.
  ################################################################
  if($option =~ /histogram/i) {
    # The histogram form offers the radio/text fields for
    # selecting the phred values for the histogram plots.
    my ($phredvalues,$pvhistdvalue) = PrintHistogramForm();
    DisplayPhredHistograms({"phredvalues"=>$phredvalues,
			   "scope"=>$scope,
			   "scopevalue"=>$scopevalue,
			   "testruns"=>"yes",
			   "sequencers"=>\@sequencers,
			   "pvhistdvalue"=>$pvhistdvalue});
  }

  ################################################################
  # Show SCORECARD (well-by-well) information for a run
  ################################################################
  if($scope =~ /runid/i && $option =~ /scorecard/i) {
    my $phredvaluescore;
    if(defined param('phredvaluesc') && param('phredvaluesc') > 0 && param('phredvaluesc') < 99) {
      $phredvaluesc = param('phredvaluesc');
    } else {
      $phredvaluesc = 20;
    }
    print
	"<table>",
	start_form,
	"<tr><td>",
	HiddenMultiple(['phredvaluesc'],param),
	"<span class=small>Phred value for base pair summary</span> ",
	textfield(-name=>'phredvaluesc',-value=>$phredvaluesc,-size=>3,-style=>'font-size:12px;'),
	" ",
	submit(-name=>"Analyze",-label=>"Redisplay",-style=>'font-size:12px;'),
	"</td></tr>",
	end_form,
	"</table>";
    if (param('batch')) {
      print htmlQuadScoreCard($scopevalue,$phredvaluesc);
    } else {
      print htmlScoreCard($scopevalue, $phredvaluesc);
      print htmlBatchLinks( $scopevalue, 'scorecard' );
    }
    return;
  }
  if($scope =~ /runid/i && $option =~ /runlist/i) {
    ListReads($scopevalue);
    return;
  }
  if($option =~ /runlist/i) {
    my $runlist;
    my $db = Imported::MySQL_GSC::GetSequenceDb();
    $runlist = $db->CreateSearch("runlist");
    $runlist->SetTable("Run");
    $runlist->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
    $runlist->AddFK({'field'=>'RunBatch.ID','fktable'=>'Run'});
    $runlist->AddFK({'field'=>'Employee.ID' ,'fktable'=>'RunBatch'});
    $runlist->AddFK({'field'=>'Equipment.ID','fktable'=>'RunBatch'});
    if($scope !~ /sequencer/i) {
      $runlist->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
      if($scope =~ /project/i) {
	$runlist->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
      }
      if($scope =~ /library/i) {
	$runlist->AddField({'field'=>'Library.Library_Name','value'=>$scopevalue});
      } else {
	$runlist->AddField({'field'=>'Project.Project_Name','value'=>$scopevalue});
      }
    } else {
      $runlist->AddField({'field'=>'Equipment.Equipment_Name','value'=>$scopevalue});
    }
    $runlist->AddViewField({'field'=>'Run.Run_ID','alias'=>'ID'});
    $runlist->AddViewField({'field'=>'Run.Sequence_DateTime','alias'=>'Date'});
    $runlist->AddViewField({'field'=>'Run.Run_Directory','alias'=>'Directory'});
    $runlist->AddViewField({'field'=>'Equipment.Equipment_Name','alias'=>'Sequencer'});
    $runlist->AddViewField({'field'=>'Employee.Employee_Name','alias'=>'Employee'});
    $runlist->AddViewField({'field'=>'Run.Run_Status','alias'=>'Test'});
    $runlist->AddViewField({'field'=>'Run.Sequence_Comments','alias'=>'Sequence_Comments'});
    $runlist->AddViewField({'field'=>'RunBatch.Sequence_Batch_Comments','alias'=>'Batch_Comments'});
    $runlist->Order({'field'=>'Run.Sequence_DateTime','order'=>'desc'});
    $runlist->Execute();
    $runlist->PrintHTML({
      'title'=>'Run Runs for this View',
      'center'=>'yes',
      'summary'=>'yes',
      'extratagstypes'=>{'int'=>'<span class=small>%%VALUE%%</span>'},
      'extratagsfields'=>{'ID'=>'align=center class=vvlightgrey|',
			  'Run_Status'=>'align=center class=small|',
			  'Sequencer'=>'align=center class=small|',
			  'Date'=>'class=small|',
			  'Employee'=>'align=center class=small|'},
      'links'=>{"Run_ID"=>"$URL_domain${PROGNAME}?scope=RunID&scopevalue=%Run_ID%&option=bpsummary&$PARAMS",
	       }
    });
  }
}

sub ReadList {
  my $reads = shift;
  $reads->AddViewField({'field'=>'Run.Run_ID','alias'=>"SeqID"});
  $reads->AddViewField({'field'=>'Run.Sequence_DateTime','alias'=>"Date"});
  $reads->AddViewField({'field'=>'Run.Sequence_DateTime','function'=>'DAYNAME','alias'=>"Day"});
  $reads->AddViewField({'field'=>'Well','alias'=>'Well'});
  $reads->AddViewField({'field'=>'Run','alias'=>'Run'});
  $reads->AddViewField({'field'=>'Sequence_Length','alias'=>'Length'});
  $reads->AddViewField({'field'=>'Equipment.Equipment_Name','alias'=>"Sequencer"});
  $reads->AddViewField({'field'=>'Quality_Left','alias'=>'QL'});
  # $reads->AddViewField({'field'=>'Quality_Right','alias'=>'QR'});
  $reads->AddViewField({'field'=>'Quality_Length','alias'=>'QTot'});
  $reads->AddViewField({'field'=>'Vector_Total','alias'=>'VTot'});
  $reads->AddViewField({'field'=>'Vector_Left','alias'=>'VL'});
  $reads->AddViewField({'field'=>'Vector_Right','alias'=>'VR'});
  $reads->AddViewField({'field'=>'Vector_Quality','alias'=>'VQ'});
  $reads->AddViewField({'field'=>'Clone_Sequence_Comments','alias'=>'Comments'});
  $reads->AddViewField({'field'=>'Phred_Histogram','alias'=>'Histogram'});
  $reads->Order({'field'=>'Run_ID','order'=>'desc'});
  $reads->Order({'field'=>'Well'});
  return $reads;
}

sub RunList {
  my $runlist = shift;
  $runlist->AddViewField({'field'=>'Run.Run_ID','alias'=>'ID'});
  $runlist->AddViewField({'field'=>'Run.Sequence_DateTime','alias'=>'Date'});
  $runlist->AddViewField({'field'=>'Run.Sequence_DateTime','function'=>"DAYNAME",'alias'=>'Day'});
  $runlist->AddViewField({'field'=>'Equipment.Equipment_Name','alias'=>'Sequencer'});
  $runlist->AddViewField({'field'=>'Employee.Employee_Name','alias'=>'Employee'});
  $runlist->AddViewField({'field'=>'Run.Run_Status','alias'=>'Test'});
  $runlist->AddViewField({'field'=>'Run.Sequence_Comments','alias'=>'Sequence_Comments'});
  $runlist->AddViewField({'field'=>'RunBatch.Sequence_Batch_Comments','alias'=>'Batch_Comments'});
  $runlist->AddViewField({'field'=>'Run.Run_Directory','alias'=>'Directory'});
  $runlist->AddViewField({'field'=>'Run.FK_Chemistry_Code__Name','alias'=>'Chemistry'});
  $runlist->AddViewField({'field'=>'Run.FK_Plate__ID'});
}

################################################################
# Do a base pair summary for a given scope
# Lists total/quality/vecotr number of base pairs for
# production/test/all runs.
################################################################
#
# This can also take a search object. The search object
# is expected to have NO view fields - we add our own.
#
# 19 October 2000
# Moved the user defined phred and cutoff values into this
# function.

sub BasePairSummary {

  $DEFAULTCUTOFF=100;

  my $hash = shift || "";
  my $scope;
  my $scopevalue;
  my $phredvalue;
  my $search;
  my $cutoff;

  Imported::MySQL_Tools::ArgAssign($hash,{'scope'=>\$scope,
			       'scopevalue'=>\$scopevalue,
			       'phredvalue'=>\$phredvalue,
			       'search'=>\$search,
			       'cutoff'=>\$cutoff,
			     },$hash);
  if (! defined $phredvalue) {
    if (defined param('phredvaluebpsum')) {
      $phredvalue = param('phredvaluebpsum');
    } else {
      $phredvalue = $DEFAULTPHRED;
    }
  }
  if ($phredvalue < 0 || $phredvalue > 99) {
    $phredvalue=$DEFAULTPHRED;
  }
  if (! defined $cutoff) {
    if (defined param('phredvaluecutoff')) { $cutoff = param('phredvaluecutoff') }
    else { $cutoff = $DEFAULTCUTOFF }
  }
  my $db;
  my $s;
  my $searchpassed_flag = 0;
  #print "Inside bpsummary ",Imported::MySQL_GSC::Now(),"<BR>";
  if((ref $scope) =~ /mysql_search/i) {
    # If we are passed a search object, then assign it directly to
    # this function's search object
    $s = $scope;
    $searchpassed_flag = 1;
  } else {
    # Otherwise, create one using the scope text passed
    $db = Imported::MySQL_GSC::GetSequenceDb();
    $s = $db->CreateSearch("bpsummary");
    $s->SetTable("Clone_Sequence");
    $s->AddFK({'field'=>'Run.ID'});
    if($scope =~ /runid/i) {
      $s->AddField({'field'=>'Run.Run_ID','value'=>$scopevalue});
    }
    if($scope =~ /sequencer/i) {
      $s->AddFK({'field'=>'Equipment.ID','fktable'=>'Run'});
      $s->AddField({'field'=>'Equipment.Equipment_Name','value'=>$scopevalue});
    }
    if($scope =~ /library/i) {
      $s->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
      $s->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
      $s->AddField({'field'=>'Library.Library_Name','value'=>$scopevalue});
    }
    if($scope =~ /project/i) {
      $s->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
      $s->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
      $s->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
      $s->AddField({'field'=>'Project.Project_Name','value'=>$scopevalue});
    }
  }
  # Add the necessary view fields for the search.
  $s->AddViewField({'field'=>'Clone_Sequence.Sequence_Length','alias'=>'"All Bases"','function'=>'sum'});
  $s->AddViewField({'field'=>'Clone_Sequence.Quality_Length','alias'=>'"Quality Bases"','function'=>'sum'});
  $s->AddViewField({'field'=>'Clone_Sequence.Vector_Total','alias'=>'"Vector Bases"','function'=>'sum'});
  if (! $searchpassed_flag) {
    $s->AddViewField({'field'=>'Run.Run_Status','alias'=>'Run_Status'});
    $s->AddGroup({'field'=>'Run.Run_Status'});
    $s->Order({'field'=>'Run.Run_Status'});
  }
  #print "Refined search ",Imported::MySQL_GSC::Now(),"<BR>";
  $s->Execute();
  # print "The Following SQL SELECT statement was used:<br> [",$s->{_sql},"]<BR>\n";
  if (! $s->get_nrecs || ! defined $s->GetRecord(0)->GetFieldValue("Sequence_Length")) {return 1};
  #print "Executed search ",Imported::MySQL_GSC::Now(),"<BR>";
  #$s->PrintHTML();

  my ($bp_t0_all,$bp_t0_q,$bp_t0_vec)=(0,0,0);
  my ($bp_t1_all,$bp_t1_q,$bp_t1_vec)=(0,0,0);

  if ($searchpassed_flag) {
    $bp_t0_all = $s->GetRecord(0)->GetFieldValue("Sequence_Length");
    $bp_t0_q   = $s->GetRecord(0)->GetFieldValue("Quality_Length");
    $bp_t0_vec = $s->GetRecord(0)->GetFieldValue("Vector_Total");
    if($bp_t0_vec<0) {$bp_t0_vec=0}
  } else {
    for (my $i=0;$i<$s->get_nrecs;$i++) {
      my $rec = $s->GetRecord($i);
      if ($rec->GetFieldValue("Run_Status") =~ /test/i) {
	$bp_t1_all += $rec->GetFieldValue("Sequence_Length");
	$bp_t1_q   += $rec->GetFieldValue("Quality_Length");
	$bp_t1_vec += $rec->GetFieldValue("Vector_Total");
	if ($bp_t1_vec<0) {$bp_t1_vec=0}
      } else {
	$bp_t0_all += $rec->GetFieldValue("Sequence_Length");
	$bp_t0_q   += $rec->GetFieldValue("Quality_Length");
	$bp_t0_vec += $rec->GetFieldValue("Vector_Total");
	if ($bp_t0_vec<0) {$bp_t0_vec=0}
      }
    }
  }

  my $bp_all = $bp_t0_all + $bp_t1_all;
  my $bp_q = $bp_t0_q + $bp_t1_q;
  my $bp_vec = $bp_t0_vec + $bp_t1_vec;
  # Relative to all.
  my $bp_q_rel = Frac($bp_q, $bp_all);
  my $bp_vec_rel = Frac($bp_vec, $bp_all);

  # Relative to test_flag
  my $bp_q_t0_rel = Frac($bp_t0_q, $bp_t0_all);
  my $bp_vec_t0_rel = Frac($bp_t0_vec, $bp_t0_all);
  my $bp_q_t1_rel = Frac($bp_t1_q, $bp_t1_all);
  my $bp_vec_t1_rel = Frac($bp_t1_vec, $bp_t1_all);

  print "<center>\n";
  print
      "<table border=0 cellspacing=0 cellpadding=0>",
      start_form,
      "<tr><td>",
      HiddenMultiple(['phredvalue'],param),
      "<span class=small><span class=greytext>Base pair phred </span></span> ",
      textfield(-name=>'phredvaluebpsum',-value=>$phredvalue,-size=>3,-style=>'font-size:10px;'),
      "&nbsp;&nbsp;";
  if (! $searchpassed_flag) {
    print
      "<span class=small><span class=greytext>Quality length cutoff </span></span> ",
      textfield(-name=>'phredvaluecutoff',-value=>$cutoff,-size=>3,-style=>'font-size:12px;'),
	" ";
  }
  print
      submit(-name=>"Analyze",-label=>"Redisplay",-style=>'font-size:12px;'),
      "</td></tr>",
      end_form,
      "</table>";

  $s->ResetSearch();
  $db = $s->get_db;
  my $tabletitle = "$scope $scopevalue";
  if($searchpassed_flag) {
    $tabletitle = "your search";
  }
  if($tabletitle !~ /\w/) {
    $tabletitle = " Cap_Seq database";
  }
  print "<table border=1 cellspacing=0 cellpadding=2>\n";
  print
      "<tr>",
      "<td colspan=4 align=center class=vdarkblue>",
      "<span class=vlightyellowtext><b>All reads in $tabletitle</span>",
      "</td>",
      "</tr>\n";
  print
      "<tr>",
      "<td align=right class=vdarkblue>&nbsp;</td>",
      "<td align=center class=vdarkblue><span class=small><b>All&nbsp;</b></span></td>",
      "<td align=center class=vdarkblue><span class=small><b>Quality&nbsp;</b></span></td>",
      "<td align=center class=vdarkblue><span lcass=small><b>Vector&nbsp;</b></span></td>",
      "</tr>\n";
  # Production
  if($searchpassed_flag) {
    goto ALLRUNS;
  }
  my $phredscores = $db->Imported::MySQL_GSC::GetPhredInfoSummary({'phreds'=>[$phredvalue],'scope'=>"$scope:$scopevalue,testruns:no",});
  my $tot20prod = $phredscores->[0]->{'totbp'};
  my $avg20prod = int($phredscores->[0]->{'avglength'});
  my $std20prod = int(sqrt($phredscores->[0]->{'varlength'}));
  my $med20prod = int($phredscores->[0]->{'medianlength'});
  my $readsprod = $phredscores->[0]->{'reads'};
  my $skipped   = $phredscores->[0]->{'skipped'};
  print
      "<tr>",
      "<td align=right class=vvlightgrey><span class=small><b>Production</b></span></td>",
      "<td valign=top align=center><span class=small>$readsprod/$skipped</span><br>$bp_t0_all (100%)<br>",
      "<span class=small>",Frac($bp_t0_all,$bp_all),"</span><br>",
      "<span class=vlightgreen><span class=small><b>p$phredvalue</b>:&nbsp;$tot20prod&nbsp;(",Frac($tot20prod,$bp_t0_all),")</span></span><br>$avg20prod/$std20prod/$med20prod</td>",
      "<td valign=top align=center><span class=small>&nbsp;</span><br>$bp_t0_q&nbsp;($bp_q_t0_rel)<br><span class=small>",Frac($bp_t0_q,$bp_q),"</span></td>",
      "<td valign=top align=center><span class=small>&nbsp;</span><br>$bp_t0_vec&nbsp;($bp_vec_t0_rel)<br><span class=small>",Frac($bp_t0_vec,$bp_vec),"</span></td>",

      "</tr>\n";
  # TEST
  my $phredscores = $db->Imported::MySQL_GSC::GetPhredInfoSummary({'phreds'=>[$phredvalue],'scope'=>"$scope:$scopevalue,testruns:only"});
  my $tot20test = $phredscores->[0]->{'totbp'};
  my $avg20test = int($phredscores->[0]->{'avglength'});
  my $std20test = int(sqrt($phredscores->[0]->{'varlength'}));
  my $med20test = int($phredscores->[0]->{'medianlength'});
  my $readstest = $phredscores->[0]->{'reads'};
  my $skipped   = $phredscores->[0]->{'skipped'};
  print
      "<tr>",
      "<td align=right class=vvlightgrey><span class=small><b>Test</b></span></td>",
      "<td valign=top align=center><span class=small>$readstest/$skipped</span><br>$bp_t1_all (100%)<br>",
      "<span class=small>",Frac($bp_t1_all,$bp_all),"</span><br>",
      "<span class=vlightgreen><span class=small><b>p$phredvalue</b>:&nbsp;$tot20test&nbsp;(",Frac($tot20test,$bp_t1_all),")</span></span><br>$avg20test/$std20test/$med20test</td>",
      "<td valign=top align=center><span class=small>&nbsp;</span><br>$bp_t1_q&nbsp;($bp_q_t1_rel)<br><span class=small>",Frac($bp_t1_q,$bp_q),"</span></td>",
      "<td valign=top align=center><span class=small>&nbsp;</span><br>$bp_t1_vec&nbsp;($bp_vec_t1_rel)<br><span class=small>",Frac($bp_t1_vec,$bp_vec),"</span></td>",
      "</tr>\n";

  # All runs
ALLRUNS:
  #print "Before phredinfosummary search ",Imported::MySQL_GSC::Now(),"<BR>";
  my $phredscores = $db->Imported::MySQL_GSC::GetPhredInfoSummary({'phreds'=>[$phredvalue],'scope'=>"$scope:$scopevalue,testruns:yes",'search'=>$s});
  #print "After phredinfosummary search ",Imported::MySQL_GSC::Now(),"<BR>";
  my $tot20 = $phredscores->[0]->{'totbp'};
  my $avg20 = int($phredscores->[0]->{'avglength'});
  my $std20 = int(sqrt($phredscores->[0]->{'varlength'}));
  my $med20 = int($phredscores->[0]->{'medianlength'});
  my $reads = $phredscores->[0]->{'reads'};
  my $skipped   = $phredscores->[0]->{'skipped'};
  print
      "<tr>",
      "<td align=right class=vvlightgrey><span class=small><b>All</b></span></td>",
      "<td valign=top align=center class=vvlightorange>",
      "<span class=small>reads/skipped: $reads/$skipped</span><br>",
      "Base Pairs: $bp_all&nbsp;(100%)<br>",
      "<span class=small>100%</span><br>",
      "<span class=vlightgreen><span class=small><b>$phredvalue</b>:&nbsp;$tot20&nbsp;(",Frac($tot20,$bp_all),")</span></span><br>",
      "<span class=small>avg/std dev/median:&nbsp;$avg20/$std20/$med20</span>",
      "</td>",
      "<td valign=top align=center><span class=small>&nbsp;</span><br>$bp_q&nbsp;($bp_q_rel)<br><span class=small>100%</span></td>",
      "<td valign=top align=center><span class=small>&nbsp;</span><br>$bp_vec&nbsp($bp_vec_rel)<br><span class=small>100%</span>",
      "</tr>\n";

  if($searchpassed_flag) {
    print "</table>\n";
    print "</center>\n";
    return 0;
  }

  # Excluding fails on all runs.
  my $badvalue=$cutoff;
  if($scope =~ /runid/i) {
    my $phredscores = $db->Imported::MySQL_GSC::GetPhredLengths({'phreds'=>[$phredvalue],'scope'=>"$scope:$scopevalue",'testruns'=>'yes','qualityonly'=>'no'});
    my $runsummary  = $db->Imported::MySQL_GSC::GetReadSummary($scopevalue);
    my $well;
    my @failedcap;
    my @failedphred;
    my @badcap;
    my @badphred;
    my @goodphred;
    my @nonfailedphred;
    my @nonfailedcap;
    my @failarray = (0,0,0,0,0,0);
    my @badarray = (0,0,0,0,0,0);
    for($well=0;$well<96;$well++) {
      my $well_text = chr(int($well/12)+65).sprintf("%02d",$well%12+1);
      my $phred = $phredscores->[0]->[$well];
      my $readlength = $runsummary->[$well]->{'length'};
      if(! $readlength) {
	# The capillary gave a 0-length read. This is a FAILED CAP
	push(@failedcap,$well_text);
	$failarray[int($well%12/2)]++;
      } else {
	push(@nonfailedphred,$phred);
	push(@nonfailedcap,$well_text);
	if ($phred < $badvalue) {
	  # The capillary gave a low phred value (<cutoff). This is a BAD CAP
	  push(@badcap,$well_text);
	  push(@badphred,$phred);
	  $badarray[int($well%12/2)]++;
	} else {
	  # The capillary gave a good phred value. This is a GOOD CAP
	  push(@goodcap,$well_text);
	  push(@goodphred,$phred);
	}
      }
    }
    # Do some statistics
    my $good      = Statistics::Descriptive::Full->new();
    my $bad       = Statistics::Descriptive::Full->new();
    my $nonfailed = Statistics::Descriptive::Full->new();
    $good->add_data(@goodphred);
    $bad->add_data(@badphred);
    $nonfailed->add_data(@nonfailedphred);
    my $badcap = @badcap;
    my $nonfailedcap = @nonfailedcap;
    my $failedcap = @failedcap;
    my $goodcap = @goodcap;
    print 
	"<tr>",
	"<td valign=top align=right class=darkgreen>",
	"<span class=small><b>OK Caps</b></span>",
	"</td>",
	"<td class=vvlightgreen align=center>",
	"<b>$nonfailedcap</b> (",Frac($nonfailedcap,96),")",
	"</td>",
	"<td colspan=2 class=vvlightgreen align=center>",
	sprintf("%d/%d/%d",$nonfailed->mean(),sqrt($nonfailed->variance()),$nonfailed->median()),
	"</td>",
	"</tr>";
    print 
	"<tr>",
	"<td valign=top align=right class=darkgreen>",
	"<b><span class=small>Good Caps</b></span>",
	"</td>",
	"<td class=vvlightgreen align=center>",
	"<b>$goodcap</b> (",Frac($goodcap,96),")",
	"</td>",
	"<td colspan=2 class=vvlightgreen align=center>",
	sprintf("%d/%d/%d",$good->mean(),sqrt($good->variance()),$good->median()),
	"</td>",
	"</tr>";
    print
	"<tr>",
	"<td valign=top align=right class=darkred>",
	"<b><span class=small>Bad Caps</span></b>",
	"</td>",
	"<td class=vvlightred align=center valign=top>",
	"<b>$badcap</b> (",Frac($badcap,96),")",
	"<br>",
	"<span class=small>",
	join(" ",@badcap),
	"</span>",
	"</td>",
	"<td colspan=2 class=vvlightred align=center valign=top>",
	sprintf("%d/%d/%d",$bad->mean(),sqrt($bad->variance()),$bad->median()),
	"<br></tr>";
    
    print
	"<tr>",
	"<td valign=top align=right class=darkred>",
	"<b><span class=small>Failed Caps</span></b>",
	"</td>",
	"<td class=vvlightred align=center valign=top>",
	"<b>$failedcap</b> (",Frac($failedcap,96),")",
	"<br>",
	"<span class=small>",
	join(" ",@failedcap),
	"</span>",
	"</td>",
	"<td colspan=2 class=vvlightred align=center valign=top>";
    # Handle array fails. This makes sense for MB machines.
    # Try to figure out whether an array has totally failed (well, as far as we are 
    # concerned). An array has a failed well if the well's phred length is less than
    # the cutoff value 
    # An array is considered to be FAILED if 
    #     - it contains more than 40% of all the failed wells in the run 
    #         AND contains more than 4 failed wells.
    #  OR - it contains more than 12 failed wells.
    my $array;
    print "<span class=small>";
    my $failedarray_frac;
    my @taggedfailarrays;
    for($array=0;$array<6;$array++) {
      my $failedwells = $failarray[$array];
      if($failedwells) {
	if(($failedwells/$failedcap > 0.4 && $failedwells > 4) || 
	   ($failedwells > 12)) { 
	  print "<span class=lightred>&nbsp;<b>"; 
	  push(@taggedfailarrays,$array);
	}
	$failedarray_frac = Frac($failedwells,$failedcap);
	print "$array:",$failedwells," $failedarray_frac";
	if(($failedwells/$failedcap > 0.4 && $failedwells > 4) || 
	   ($failedwells > 12)) { 
	  print "</b>&nbsp;</span>"; }
	print "<br>";
      }
   }
    print "</span>";
    if(@taggedfailarrays) {
      print "<span class=darkred><span class=whitetext>";
      print "&nbsp;<b>Array failure: ",join(",",@taggedfailarrays),"&nbsp;</b>";
      print "</span></span>";
    } else {
      print "no array warnings";
    }
    print
	"</td>",
	"</tr>";
  }
  print "</table>";
  print "<table><tr><td align=center>";
  print "<span class=greytext>";
  print "<span class=small>reads: good/skipped | phred values: average/standard deviation/median";
  if($scope =~ /runid/i) {
    print "<br>Good caps: p$phredvalue>=$badvalue | bad caps: p20<$badvalue | OK caps: readlength > 0 | Failed caps: readlength = 0<br>";
  } else {
    print "</span><br>";
  }
  print "</table>\n";
  print "</center>\n";
  return 0;
  
}

################################################################
# Produces a formatted fraction
sub Frac {
  my $num=shift;
  my $tot=shift;
  if($tot) {
    return sprintf("%4.1f%%",100*$num/$tot);
  } else {
    return "0.0%";
  }
}
#
################################################################

sub Round {
  my $num = shift;
  if($num - int(num) >= 0.5) {
    return (int($num+1));
  } else {
    return (int($num));
  }

}


sub ColorScale {

  my $value = shift;
  my $scale = shift;
  my $colors = shift;
  
  my $idx;
  my $divisions = @{$scale};
  for($idx=0;$idx<$divisions;$idx++) {
    if($value >= $scale->[$idx]) {
      return $colors->[$idx];
    }
  }
  return "white";
}

################################################################
# Generate a phred histogram table. Uses the hash phred structure 
# 
# $phredscoreshist{$phredvalue}->[int($phredlength/100)+1] 
#
# keys:   phred values
# values: bin values (bin size is fixed to 100).

sub PhredHistogramTable {
  
  my $phredscoreshist = shift;
  my $phredavg = shift;
  my $read_num = shift;
  my $td;
  $td = "<td align=center class=black";
  print 
      "<center>",
      "<table cellspacing=0 cellpadding=1 border=1>",
      "<tr>",
      "$td rowspan=2>&nbsp;",
      "</td>";
  foreach $phredvalue (sort {$a <=> $b} keys %$phredscoreshist) {
    print "$td colspan=3><span class=vlightbluetext><b>Q=$phredvalue</b></span><br>",
    "</td>";
  }
  print 
      "</tr>\n",
      "<tr>";
  foreach $phredvalue (sort {$a <=> $b} keys %$phredscoreshist) {
    print 
	"$td colspan=2> Reads</td>",
	"$td> Cml</td>";
  }
  print "</tr>\n";
  my $idx=0;
  my ($value,$phredcumul,$maxvalue,@x);
  while () {
    print "<tr>";
    my $tdclass="vvlightred";
    if(!$idx)    {$tdclass="lightred"};
    if($idx > 3) {$tdclass="vvlightyellow"}
    if($idx > 6) {$tdclass="vvlightgreen"}
    if(! $idx) {
      print "<td class=$tdclass align=right><span class=small>",0,"</span></td>";
      push(@x,0);
    } else  {
      print "<td class=$tdclass align=right><span class=small>",($idx-1)*100+1,"-",$idx*100,"</span></td>";
      push(@x,(($idx-1)*100+1)."-".$idx*100);
    }

    my $found=0;
    foreach $phredvalue (sort {$a <=> $b} keys %$phredscoreshist) {    
      if(defined $phredscoreshist->{$phredvalue}->[$idx]) {
	$value = $phredscoreshist->{$phredvalue}->[$idx];
	if($value > $maxvalue) {
	  $maxvalue = $value;
	}
	$phredcumul{$phredvalue}+=$value;
	print 
	    "<td align=right class==small>$value&nbsp;</td>",
	    "<td align=right class=small>",sprintf("%3.1f",100*$value/$read_num->{$phredvalue}),"&nbsp;</td>";
	if($read_num->{$phredvalue}) {
	  print
	      "<td align=right class=small>",sprintf("%3.1f",100*$phredcumul{$phredvalue}/$read_num->{$phredvalue}),"&nbsp;</td>";
	} else {
	  print 
	      "<td align=right class=small>0%&nbsp;</td>";
	}
	$found=1;
      } else {
	print "<td colspan=3 class=vvlightgrey>&nbsp;</td>";
      }
    }
    print "</tr>\n";
    $idx++;
    # Bug fix 15 Oct 2000
    # Quit only if there are no values in this bin and when the index of the
    # bin is > 8. The second condition had to be added for displaying low phred
    # value quality lengths. When using a low phred value it is posible for a
    # run to have no reads of length 0, or 1-100, or 101-200 ...
    if(!$found && $idx>8) {last}
  }
  print "<tr>";
  print "<td align=right>Average</td>";
  foreach $phredvalue (sort {$a <=> $b} keys %$phredscoreshist) {     
    print 
	"<td colspan=3 align=center>",
	sprintf("%5.1f",$phredavg->{$phredvalue}),
	"</td>";
  }
  print "</tr>";
  print "</table>";
  print "</center>";

}

sub PhredHistogramGIF {

  my $phredscoreshist = shift;
  my $width = Extract_Values([shift,300]);
  my $height = Extract_Values([shift,100]);
  my $graph = new GD::Graph::bars($width,$height);
  # Try to compute the max value:
  my ($maxrows,$rows,$phred,$maxvalue,$value)=(0,0,0,0,0);
  foreach $phred (sort {$a <=> $b} keys %$phredscoreshist) {
    $rows=0;
    foreach $value (@{$phredscoreshist->{$phred}}) {
      if($value>$maxvalue) {$maxvalue=$value}
      $rows++;
    }
    if($rows>$maxrows) {
      $maxrows=$rows;
    }
  }
  if($maxvalue < 100) {
    $maxvalue = 10*(int($maxvalue/10)+1),
  } else {
    $maxvalue = 100*(int($maxvalue/100)+1),
  }
  $graph->set(
	      y_max_value=>$maxvalue,
	      bar_spacing=>1,
	      axis_space=>1,
	      );
  $graph->set_legend(sort {$a <=> $b} keys %$phredscoreshist);
  $graph->set('boxclr'=>"gscblue1");
  $graph->set('fgclr'=>"gscblue2");
  $graph->set('accentclr'=>"dodgerblue4");
  $graph->set('dclrs'=>["tomato","gold1","steelblue1","springgreen2"]);
  $graph->set('y_long_ticks'=>1);
  $graph->set('x_long_ticks'=>1);
  my $randpic = int(rand(1000000));

  open(IMG,">/$URL_temp_dir/graph$randpic.png");
  binmode IMG;
  # Make sure all arrays have same size.
  # Also, the x labels just now give the max element value in that histogram bin.
  my (@xtext,$label);
  for ($label=0;$label<$maxrows;$label++) {
    push(@xtext,$label*100);
  }
  my @data = (\@xtext);
  foreach $phred (sort {$a <=> $b} keys %$phredscoreshist) {    
    $phredscoreshist->{$phred}->[$#xtext]=0;
    push(@data,$phredscoreshist->{$phred});
  }
  my $gd = $graph->plot(\@data);
  print IMG $gd->png;
  close IMG;
  print qq{<center><img src="/dynamic/tmp/graph$randpic.png"></center>};
}

sub PhredHistogramGIF_Detail {

  my $phredscoreshist = shift;
  my $phredvalue = shift;
  my $width = Extract_Values([shift,300]);
  my $height = Extract_Values([shift,100]);
  my $graph = new GD::Graph::bars($width,$height);
  # Try to compute the max value:
  my ($maxrows,$rows,$phred,$maxvalue,$value)=(0,0,0,0,0);
  foreach $value (@{$phredscoreshist->{$phredvalue}}) {
    if($value>$maxvalue) {$maxvalue=$value}
    $rows++;
  }
  if($rows>$maxrows) {
    $maxrows=$rows;
  }
  if($maxvalue < 100) {
    $maxvalue = 10*(int($maxvalue/10)+1),
  } else {
    $maxvalue = 10*(int($maxvalue/10)+1),
  }
  $graph->set(
	      y_max_value=>$maxvalue,
	      bar_spacing=>2,
	      x_label_skip=>4,
	      axis_space=>1,
	      );
  $graph->set_legend($phredvalue);
  $graph->set('boxclr'=>"gscblue1");
  $graph->set('fgclr'=>"gscblue2");
  $graph->set('accentclr'=>"dodgerblue4");
  $graph->set('dclrs'=>["springgreen2","gold1","steelblue1","springgreen2"]);
  $graph->set('y_long_ticks'=>1);
  $graph->set('x_long_ticks'=>1);
  my $randpic = int(rand(1000000));
  open(IMG,">/$URL_temp_dir/graph$randpic.png");
  binmode IMG;
  # Make sure all arrays have same size.
  # Also, the x labels just now give the max element value in that histogram bin.
  my (@xtext,$label);
  for ($label=0;$label<$maxrows;$label++) {
    push(@xtext,$label*$DETAILEDHISTBIN);
  }
  my @data = (\@xtext);
  $phredscoreshist->{$phredvalue}->[$#xtext]=0;
  push(@data,$phredscoreshist->{$phredvalue});
  my $gd = $graph->plot(\@data);
  print IMG $gd->png;
  close IMG;
  print qq{<center><img src="/dynamic/tmp/graph$randpic.png"></center>};
}


################################################################
# Prints the Phred Length summary table, listing all machines
# that did runs for this scope and their phred avg/stdev/median
# values
sub PhredLengthSummary {

  my $phredvalues = shift;
  my $sequencers  = shift;
  my $scope       = shift;
  my $scopevalue  = shift;

  my $t20 = new Benchmark;  
  print "<table border=1 cellspacing=0 cellpadding=1>";
  print "<tr>";
  print "<tr><td colspan=6 class=vdarkblue align=center><span class=large><b>Phred Length Summary</b></span></td></tr>";
  $td="<td class=vdarkblue align=center><span class=vlightredtext><b>";
  $tdend="</b></span></td>";
  print "$td Sequencer $tdend";
  print "$td Reads $tdend";
  foreach $phred (@{$phredvalues}) {
    print "$td Q $phred $tdend";
  }
  print "</tr>";
  my $scopestring="";
  if($scope !~ /machine/i) {
    $scopestring="$scope:$scopevalue";
  }
  my $record_idx=0;
  foreach $machine (@{$sequencers}) {
    my $search;
    my $db = Imported::MySQL_GSC::GetSequenceDb();
    my $phred_summary = $db->Imported::MySQL_GSC::GetPhredInfoSummary({'phreds'=>$phredvalues,'scope'=>"$scopestring,sequencer:$machine",'testruns'=>'yes','qualityonly'=>'no'});
    my $reads   = $phred_summary->[$phred_idx]->{'reads'};
    print "<tr>";
    print 
	"<td align=right>$machine&nbsp;</td>",
	"<td align=center>$reads</td>";
    my $phred_idx=0;
    foreach $phred (@{$phredvalues}) {
      my $avg     = $phred_summary->[$phred_idx]->{'avglength'};
      my $stdev   = sqrt($phred_summary->[$phred_idx]->{'varlength'});
      my $median  = $phred_summary->[$phred_idx]->{'medianlength'};
      my $tdclass = "vvlightred";
      if($avg > 300) {
	$tdclass = "vvlightgreen";
      } elsif ($avg > 200) {
	$tdclass = "vvlightyellow";
      } elsif ($avg > 100) {
	$tdclass = "vvlightorange";
      }
      print 
	  "<td class=$tdclass align=right>",
	  sprintf("%d/%d/%d",$avg,$stdev,$median),
	  "&nbsp;</td>";
      $phred_idx++;
    }
    print "</tr>";
    if($scopestring eq "") {last}
  }
  print "</table>\n";
  print "<center><span class=small><span class=greytext>Legend: average/standard deviation/median</span></span><br>";
  my $t21 = new Benchmark;
  my $timetext = timestr(timediff($t21,$t20));
  $timetext =~ s/.*(\d+)\s+wall.*/$1/;
#  print "<center><span class=small>Time: ",$timetext," sec</span></center><br>";
}

################################################################
# Print the scope description table. This is a two column
# table that lists the field values associated with a scope
# item. For each item (run, machine, library, etc.) other
# tables are linked in the search to give additional information.
# For example, a run description links library and plate information.
#
# 18 Oct 2000
#
# Added the facility to produce a new scope description table for the
# scope "SEQUENCE". The SEQUENCE scope lists fields in the Clone_Sequence
# table as well as any other lookup tables liked to a record in it. Some
# of the fields in Clone_Sequence are either (a) very long (e.g. sequence), 
# or (b) binary (e.g. histograms). 
#
# Changed the function to skip over such fields.
#
sub ScopeDescriptionTable {
  my $scopesearch = shift;
  print "<table cellspacing=0 cellpadding=0 border=0>";
  my $r;
  my $delay="";

  while($r = $scopesearch->ForEachRecord) {
    my $row=1;
    foreach $f (@{$r->get_fields}) {
      my $fieldname;
      # Now binary fields (blobs) are not listed (18 Oct 2000) and the Run
      # field is not listed.
      if($f->get_value ne "" && $f->get_name !~ /FK|^Run$/ && $f->get_type !~ /blob/) {
	$fieldname = $f->get_name;
	my $value = $f->get_value;
	my $value_delay = (length($value)>20)?1:0;
	my ($ahref_open,$ahref_close) = ("","");
	if($fieldname =~ /^Library_Name$/) {
	  $ahref_open=qq{<a href="${PROGNAME}?scope=Library&scopevalue=$value&$PARAMS">};
	  $ahref_close="</a>";
	} elsif ($fieldname =~ /^Project_Name$/) {
	  $ahref_open=qq{<a href="${PROGNAME}?scope=Project&scopevalue=$value&$PARAMS">};
	  $ahref_close="</a>";
	} elsif ($fieldname =~ /^Equipment_Name$/) {
	  $ahref_open=qq{<a href="${PROGNAME}?scope=Sequencer&scopevalue=$value&$PARAMS">};
	  $ahref_close="</a>";
	} else {
	  #
	}
	$fieldname =~ s/_+/&nbsp;/g;
	if($row%2 == 1) {
	  if(! $value_delay) {
	    print "<tr>";
	  }
	}
	if($value_delay) {
	  $delay .= "<tr><td align=left valign=top><span class=small>".$fieldname."&nbsp;</span></td></tr>";
	} else {
	  print "<td align=right valign=top><span class=small>",$fieldname,"&nbsp;</span></td>";
	}
	my $tdclass="white";
	if($f->get_name =~ /ID/) {
	  $tdclass="darkgreentext";
	}
#	$value =~ s/(.{20,30},)/$1<br>/g;
	if($value_delay) {
	  $delay .= "<tr><td align=left valign=top class=$tdclass><b><span class=small>$ahref_open".$value."$ahref_close</b></td></tr>";
	} else {
	  print "<td valign=top class=$tdclass><b><span class=small>$ahref_open",$value,"$ahref_close</b></td>";
	}
	if(!($row%2) && ! $value_delay) {
	  print "</tr>";
	}
	$row++;
      }
    }
  }
  print "</table>";
  print "<br>";
  print "<table border=0 cellspacing=0 cellpadding=0>$delay</table>";
}

sub FormatBench {
  my $t0 = shift;
  my $t1 = shift;
  my $diff = timestr(timediff($t1,$t0));
  if($diff =~ /.*(\d+) wall.*(\d+\.\d+) CPU/) {
    return "$1 wall, $2 CPU";
  }
}


sub htmlScoreCard {
  #
  # Prints a score card view for a given run id.
  #

  my $runid = shift;
  my $phredvalue = Extract_Values([shift,20]);

  my $p;
  my $db = Imported::MySQL_GSC::GetSequenceDb();
  # Get the phred lengths for this run.
  my $phred_lengths = $db->Imported::MySQL_GSC::GetPhredLengths({'phreds'=>[$phredvalue],'scope'=>"runid:$runid",'testruns'=>'yes','qualityonly'=>'no'});
  # Get the read summary for this run.
  my $read_summary = $db->Imported::MySQL_GSC::GetReadSummary($runid);
  # Setup the color scale for the scorecard;
  my ($row, $col);
  my ($row_size, $col_size) = getRowColSize( $runid );
  my $well_idx=0;

  $p .= "<center><table border=1 cellspacing=0 cellpadding=1>\n";
  $p .= "<tr>";
  $p .= "<td class=black align=center colspan=" . ($col_size + 1) . ">\n";
  $p .= "<span class=small><b>Score card for Run id $runid (phred $phredvalue)</b></span>";
  $p .= "</td></tr><tr>";
  $p .= "<td class=black align=center>&nbsp;</td>\n";
  foreach ($col=0; $col < $col_size; $col++) {
    $p .= "<td align=center class=black>" . ($col + 1) . "</td>\n";
  }
  $p .= "</tr>\n";
  my ($comment,%comment,$comment_short,$well_text,$nogrow,$slowgrow);
  # Cycle over rows: (A-H)
  $well_idx = 0;
  foreach ($row=0;$row<$row_size;$row++) {
    $p .= "<tr>";
    $p .= "<td class=black align=right valign=center>&nbsp;";
    $p .= chr($row + 65);
    $p .= "&nbsp;</td>\n";
    # Cycle over well columns (displayed as 1 thru $col_size)
    foreach ($col=0; $col < $col_size; $col++) {
      #$well_idx = $row * $col_size + $col;
      if ($read_summary->[$well_idx]->{'well'} eq (_row_num_to_alphabet($row+1) . sprintf("%02d",$col+1))) {
	  $p .= htmlScoreCardWell( $well_idx, $read_summary, $phred_lengths );
	  $well_idx++;
      }
      else {
	  $p .= "<td bgcolor='black'><br><br><br></td>";
      }
    }
    $p .= "</tr>\n";
  }
  $p .= "<tr><td colspan=13 align=center>\n";
  # Print a line listing all the flags for the wells.
  if(keys %comment > 0) {
    foreach $comment (sort {$comment{$a} <=> $comment{$b}} keys %comment) {
      if($comment) {
	$comment_short = $comment;
	$comment_short =~ s/[\b\s]*(.)([^\b\s]*)/$1/g;
	$p .= $comment," ($comment_short)&nbsp;&nbsp;&nbsp;";
      }
    }
  }
  $p .= "<span class=small>";
  $p .= "No grow " . "<img src='/$image_dir/nogrow.png' align=center>";
  $p .= " ";
  $p .= "Slow grow " . "<img src='/$image_dir/slowgrow.png' align=center>";
  # Print a legend:
  $p .= "&nbsp;&nbsp;&nbsp;Phred $phredvalue Colour map: ";
  my $increment = 1;
  for($phred=0;$phred<1100;$phred+=$increment) {
    $phredcolor=ColorScale($phred,$STDPHREDSCALE,$STDRAINBOW);
    if ($phred == 1) {$phred = '&gt;0'; $increment = 100;};
    $p .= "<span class=$phredcolor><span class=small>&nbsp;$phred&nbsp;</span></span>";
  }
  $p .= "</span>";
  $p .= "</td></tr></table>";
  $p .= "</center>";

  return $p;
}


sub htmlQuadScoreCard {
  #
  # Prints a score card view for a given run id.
  #
  my $runid = shift;
  my $phredvalue = Extract_Values([shift,20]);
  my $p;

  my (%comments, $comment, $comment_short);
  my $db = Imported::MySQL_GSC::GetSequenceDb();
  my $runs_aref = getBatchByRun( $runid );

  my (@phred_lengths, @read_summary);

  my ($row, $col);
  my $row_size = 16;
  my $col_size = 24;
  my ($c, $r);
  my ($well_idx, $quad_idx);

  $p .= "<table border='0' cellspacing='0' cellpadding='0'>\n";
  $p .= "<tr>\n";
  $p .= "<td colspan=" . ($col_size + 1) . " align=center>";
  $p .= "<table border='0' cellspacing='2' cellpadding='4' bgcolor='#eeeeee'>\n";
  $p .= "<tr><td colspan='2' bgcolor='#bbbbbb'><b>Plate&nbsp;View&nbsp;for&nbsp;Runs</b></td></tr>";
  $p .= "<tr>\n";
  $p .= qq{<td>a: <a href="${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[0]&option=scorecard&$PARAMS">$$runs_aref[0]</a></td>\n};
  $p .= qq{<td>b: <a href="${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[1]&option=scorecard&$PARAMS">$$runs_aref[1]</a></td>\n};
  $p .= "</tr>\n";
  $p .= "<tr>\n";
  $p .= qq{<td>c: <a href="${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[2]&option=scorecard&$PARAMS">$$runs_aref[2]</a></td>\n};
  $p .= qq{<td>d: <a href="${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[3]&option=scorecard&$PARAMS">$$runs_aref[3]</a></td>\n};
  $p .= "</tr>\n";
  $p .= "</table>&nbsp;<br>\n";

  $p .= "<center>\n";
  $p .= "<table border=1 cellspacing=0 cellpadding=1>\n";
  $p .= "<tr>\n";
  $p .= "<td class=black align=center colspan=" . ($col_size + 1) . ">\n";
  $p .= "<span class=small><b>Score card for Runs: ";
  for (@$runs_aref) { $p .= $_ . " " }
  $p .= "(phred $phredvalue)</b></span></td>\n";
  $p .= "</tr>\n\n";
  $p .= "<tr>\n";
  $p .= "<td class=black align=center>&nbsp;</td>\n";
  foreach ($col=0; $col < $col_size; $col++) {
    $p .= "<td align=center class=black>" . ($col + 1) . "</td>\n";
  }
  $p .= "</tr>\n";

  foreach ($i = 0; $i < 4; $i++) {
    $phred_lengths[$i] = $db->Imported::MySQL_GSC::GetPhredLengths(
						   {
						    'phreds'=>[$phredvalue],
						    'scope'=>"runid:$$runs_aref[$i]",
						    'testruns'=>'yes',
						    'qualityonly'=>'no'}
						  );
    $read_summary[$i] = $db->Imported::MySQL_GSC::GetReadSummary( $$runs_aref[$i] );
  }

  # Cycle over rows: (A-P)
  foreach ($row=0; $row < $row_size; $row++) {
    $p .= "<tr>\n";
    $p .= "<td class=black align=right valign=center>&nbsp;";
    $p .= chr($row + 65);
    $p .= "&nbsp;</td>\n";

    # assign 96 well quadrant index and well index
    # translating from 384 well x,y co-ords
    foreach ($col = 0; $col < $col_size; $col++) {
      if ($col >= 12) {
	if ($row >= 8) {
	  $quad_idx = 3;
	  $well_idx = (($row - 8) * ($col_size / 2)) + ($col - 12);
	} else {
	  $quad_idx = 1;
	  $well_idx = ($row * ($col_size / 2)) + ($col - 12);
	}
      } else {
	if ($row >= 8) {
	  $quad_idx = 2;
	  $well_idx = (($row - 8) * ($col_size / 2)) + $col;
	} else {
	  $quad_idx = 0;
	  $well_idx = ($row * ($col_size / 2)) + $col;
	}
      }
      # display the well
      $p .= htmlScoreCardWell( $well_idx, $read_summary[$quad_idx], $phred_lengths[$quad_idx] );
      $comment = $read_summary->[$well_idx]->{'comment'};
      if ($comment =~ /\w+/) { $comments{$comment} = '' }
    }
    $p .= "</tr>\n";
  }

  $p .= "<tr><td colspan='" . ($col_size + 1) . "' align='center'>\n";

  if (keys %comments > 0) {
    foreach $comment (sort {$comments{$a} <=> $comments{$b}} keys %comments) {
      if ($comment) {
	$comment_short = $comment;
	$comment_short =~ s/[\b\s]*(.)([^\b\s]*)/$1/g;
	$p .= $comment . " ($comment_short)&nbsp;&nbsp;&nbsp;";
      }
    }
  }
  $p .= "<span class=small>";
  $p .= "No grow " . "<img src='/$image_dir/nogrow.png' align=center>";
  $p .= " ";
  $p .= "Slow grow " . "<img src='/$image_dir/slowgrow.png' align=center>";

  $p .= "&nbsp;&nbsp;&nbsp;Phred $phredvalue Colour map: ";
  for($phred=0;$phred<800;$phred+=50) {
    $phredcolor=ColorScale($phred,$STDPHREDSCALE,$STDRAINBOW);
    $p .= "<span class=$phredcolor><span class=small>&nbsp;$phred&nbsp;</span></span>";
  }
  $p .= "</span>";
  $p .= "</td></tr></table>";
  $p .= "</center>";

  return $p;
}


sub htmlScoreCardWell {
  #
  # return the HTML to display a single ScoreCard table cell
  #

  my $p;
  my $well_idx = shift;
  my $read_summary = shift;
  my $phred_lengths = shift;
  my ($runid, $comment, $comment_short, $well_text, $nogrow, $slowgrow, $phredlength, $readlength, $phredcolor);
  $runid = $read_summary->[$well_idx]->{'runid'};
  $well_text = $read_summary->[$well_idx]->{'well'};
  $comment = $read_summary->[$well_idx]->{'comment'};
  $readlength = $read_summary->[$well_idx]->{'length'};
  if ($read_summary->[$well_idx]->{'growth'} eq "No Grow") { $nogrow = 1; } else { $nogrow = 0; }
  if ($read_summary->[$well_idx]->{'growth'} eq "Slow Grow") { $slowgrow = 1; } else { $slowgrow = 0; }
  $phredlength = $phred_lengths->[0]->[$well_idx];
  if (!$readlength) { $phredlength=0 }

  # Colour code the box according to phred value
  $phredcolor=ColorScale($phredlength, $STDPHREDSCALE, $STDRAINBOW);
  $p .= "<td align=center valign=top class=$phredcolor>";
  my $chromatogram_link = "$URL_address/view_chromatogram.pl?runid=$runid&well=$well_text&height=$APPLET_HEIGHT&width=$APPLET_WIDTH";
  my $on_click = "window.open('$chromatogram_link','newwin','height=800,width=1000,scrollbars=yes,resizable=yes,toolbar=yes,location=no,directories=no'); return false";
  $p .= "<a href='$chromatogram_link' onClick=\"$on_click\">" . "<span class=large><b>" . $phredlength . "</b></span></a>";
  $p .= "&nbsp;&nbsp;";
  $p .= "<span class=small>$readlength</span>";
  if ($nogrow) {
      $p .= "<img src='/$image_dir/nogrow.png' alt='NO GROW in this well'>";
  }
  if ($slowgrow) {
      $p .= "<img src='/$image_dir/slowgrow.png' alt='SLOW GROW in this well'>";
  }

  # Vector/Quality GRAPHS
  my $width = 50;
  my $length = $read_summary->[$well_idx]->{'length'};
  my $bpwidth = ($length)?50/$length:0;
  my $qt = Round($bpwidth*$read_summary->[$well_idx]->{'qt'});
  my $ql = Round($bpwidth*$read_summary->[$well_idx]->{'ql'});
  my $qr = Round($bpwidth*($length-$read_summary->[$well_idx]->{'qr'}));
  my $vt = $read_summary->[$well_idx]->{'vt'};
  my $vl = $read_summary->[$well_idx]->{'vl'};
  my $vr = $read_summary->[$well_idx]->{'vr'};
  # Set vector and quality negative values to zero.
  if ($ql < 0) { $ql = 0; }
  if ($qr < 0) { $qr = 0; }
  ## QUALITY ASSESSMENT
  # No quality sequence.
  if(! $qt) {
    $qr = $width; $qt = 0; $ql = 0;
  }
  # Rounding
  if($qt+$qr+$ql > $width) {
    $qt = ($width-$ql-$qr);
  }
  ## VECTOR ASSESSMENT
  #
  # 0............................................L
  # --vector---|           |----vector------------
  # (width=vl) | width=vt  | width=vl
  #
  if ($vl == -1 && $vr == -1) {
    # No vector at all - the only image is the non-vector image (dark box)
    # of size vt (vector-gap).
    $vl = 0; $vt = $width;  $vr = 0;
  } elsif ($vl > $vr && ! $vr) {
    # All vector, the only image is the vector image (light box) of size vl
    $vl = $width; $vt = 0; $vr = 0;
  } else {
    if($vl < 0) { $vl = 0; }
    $vl = Round($bpwidth*$vl);
    if($vr < 0) {
      $vt = $width - $vl;
      $vr = 0;
    } else {
      $vt = Round($bpwidth*($vr-$vl));
      $vr = $width-$vl-$vt;
    }
  }
  $p .= "<br>";
  my $height = 4;
  if ($ql) {$p .= "<img src='/$image_dir/vdarkgreendot.png' height=$height width=$ql>"}
  if ($qt) {$p .= "<img src='/$image_dir/lightgreendot.png' height=$height width=$qt>"}
  if ($qr) {$p .= "<img src='/$image_dir/vdarkgreendot.png' height=$height width=$qr>"}
  $p .= "<br>";
  if ($vl) {$p .= "<img src='/$image_dir/golddot.png' height=$height width=$vl>"}
  if ($vt) {$p .= "<img src='/$image_dir/vdarkgolddot.png' height=$height width=$vt>"}
  if ($vr) {$p .= "<img src='/$image_dir/golddot.png' height=$height width=$vr>"}

  # BP Frequency
  my ($sequence,$bp_a,$bp_t,$bp_g,$bp_c,$bp_o) = (0,0,0,0,0);
  $sequence = $read_summary->[$well_idx]->{'sequence'};
  while($sequence =~ /(.)/g) {
    if($1 eq "a") { $bp_a++}
    elsif($1 eq "g") { $bp_g++}
    elsif($1 eq "t") { $bp_t++}
    elsif($1 eq "c") { $bp_c++}
    else { $bp_o++}
  }
  $height = 30;
  my $width = 5;
  if($length) {
    my $bp_a = Round($height*$bp_a/$length);
    my $bp_g = Round($height*$bp_g/$length);
    my $bp_t = Round($height*$bp_t/$length);
    my $bp_c = Round($height*$bp_c/$length);
    my $bp_o = Round($height*$bp_o/$length);
    $p .= qq{<br><img src="/$image_dir/spacer.png" height=3 width=1><br>};
    $p .= "<img src='/$image_dir/vdarkbluedot.png' height=$bp_a width=$width>";
    $p .= "<img src='/$image_dir/vdarkbluedot.png' height=$bp_c width=$width>";
    $p .= "<img src='/$image_dir/vdarkbluedot.png' height=$bp_g width=$width>";
    $p .= "<img src='/$image_dir/vdarkbluedot.png' height=$bp_t width=$width>";
    $p .= "<img src='/$image_dir/vdarkbluedot.png' height=$bp_o width=$width>";
    $p .= "<br>";
    $p .= "<a href=\"$URL_domain${PROGNAME}?scope=sequence&scopevalue=$runid-$well_text&$PARAMS\"><span class=small>ACGTN</span></a>";
  } else {
    $p .= "<br>";
  }
  if ($comment =~ /\w+/) {
    $comment_short = $comment;
    $comment_short =~ s/[\b\s]*(.)([^\b\s]*)/$1/g;
    $p .= "<br><span class=mediumred>&nbsp;&nbsp;<span class=small><span class=whitetext>";
    $p .= $comment_short . "</span>&nbsp;&nbsp;</span></span><br>";
  }
  $p .= "</td>\n";

  return $p;
}


sub SequenceView {
  #
  # Produces a sequence view, showing base pairs, their index
  # their phred scores as well as quality and vector regions.
  #

  my $bpcols=30;
  my $tablewidth=800;
  my $colwidth=int($tablewidth/$bpcols);
  my $run = shift;
  my $well = shift;
  my $db = Imported::MySQL_GSC::GetSequenceDb;
  my $sequence =  Imported::MySQL_GSC::GetSequenceText($db,$run,$well);
  my $readsummary = Imported::MySQL_GSC::GetReadSummary($db,$run);
  my @scores = Imported::MySQL_GSC::GetScores($db,$run,$well);
  $formatsequence=$sequence;
  $formatsequence =~ s/(.{60})/$1\n/g;
  $formatsequence =~ tr/a-z/A-Z/;
  my $well_idx;
  if($well =~ /(\w)(\d\d)/) {
    $well_idx = 12*(ord($1)-65)+(int($2))-1;
  }
  #  print "<span class=vlightblacktext>Well index: $well_idx</span><br><br>";
  my $stdrainbow = ["vlightpurple","vlightblue","vlightgreen","vlightgreen",
		    "vlightyellow","vlightyellow","vlightorange"
		    ,"vlightred","mediumred"];
  my $phredvalues = [45,40,35,30,25,20,15,10,0];
  my $bp_idx=0;
  my $status;
  my $bp;
  my $phredvalue;
  my ($indexcolor,$bpcolor,$scorecolor);
  print "<table cellspacing=5><tr>";
  # Show the formatted sequence: small text
  print "<td class=small>";
  print "<pre>";
  print $formatsequence;
  print "</pre>";
  print "</td>";
  print "<td valign=top>";
  print 
      "<table border=1 cellspacing=0 cellpadding=2>",
      "<tr>",
      "<td align=center><span class=small>base index</span><br>",
      "233",
      "</td></tr>",
      "<tr>",
      "<td align=center><span class=small>base pair</span><br>",
      "<span class=large><b>A</b></span>",
      "</td></tr>",
      "<tr>",
      "<td align=center><span class=small>phred score</span><br>",
      "23",
      "</td></tr></table>";
  print "</td><td valign=top>";
  print 
      "Base phred score is coloured as follows:<br><br>",
      "<span class=vdarkyellow>&nbsp;vector&nbsp;</span><br>",
      "<span class=vdarkorange>&nbsp;quality vector&nbsp;</span><br>",
      "<span class=vdarkgreen>&nbsp;quality&nbsp;</span><br>",
      "<span class=black>&nbsp;neither vector nor quality&nbsp;</span><br>";
  print "<br><br>";
  print "Phred color legend:<br>";
  foreach $phredvalue (sort {$a <=> $b} @{$phredvalues}) {
    $bpcolor=ColorScale($phredvalue,
			$phredvalues,
			$stdrainbow);
    print "<span class=$bpcolor>&nbsp;$phredvalue&nbsp;</span>";
  }
  my ($bp_tot,$bp_a,$bp_t,$bp_g,$bp_c,$bp_o) = (0,0,0,0,0);
  $bp_tot = length($sequence);
  while($sequence =~ /(.)/g) {
    if($1 eq "a") { $bp_a++}
    elsif($1 eq "g") { $bp_g++}
    elsif($1 eq "t") { $bp_t++}
    elsif($1 eq "c") { $bp_c++}
    else { $bp_o++}
  }
  print "<br><br>Total length: ",$bp_tot,"<br>";
  print "<div class=indentsmall>";
  print "A - ",$bp_a," (",Frac($bp_a,$bp_tot),")<br>";
  print "C - ",$bp_c," (",Frac($bp_c,$bp_tot),")<br>";
  print "G - ",$bp_g," (",Frac($bp_g,$bp_tot),")<br>";
  print "T - ",$bp_t," (",Frac($bp_t,$bp_tot),")<br>";
  print "N - ",$bp_o," (",Frac($bp_o,$bp_tot),")<br>";
  print "</div>";
  print "</td>";
  print "</tr></table>";
  # Extract $bpcols from $sequence basepairs at a time and process these.
  print "\n\n";

  my $dbc = DBI->connect("DBI:mysql:sequence:$DBASE" , 'viewer', 'viewer', {RaiseError => 1});
  ViewChromatogramApplet($dbc, $run, $well, 500, 300, 1);
  $dbc->disconnect;

  print "\n\n";
  print "<br><br>";
  goto NEWVIEW;
  my $seqpos=0;
  my $bpsubset;
  my $bp;
  # Extract chunks from the sequence;
  while($bpsubset=substr($sequence,$seqpos,$bpcols)) {
    $bp_idx=$seqpos;
    print "<table border=0 cellspacing=0 cellpadding=0>";
    print "<tr>";
    # Print the index row
    my $indexcolor;
    while($bpsubset =~ /(.)/g) {
      $status = Imported::MySQL_GSC::GetBPStatus($readsummary,$well_idx,$bp_idx);
      if($status =~ /vector/) { 
	$indexcolor = "black";
      } else {
	$indexcolor = "white";
      }
      my $test = length($bpsubset);
      print "<td align=center width=$colwidth class=$indexcolor><span class=small>$bp_idx</span></td>\n";
      $bp_idx++;
    } 
    print "</tr>\n";
    # Print the base pair row
    print "<tr>";
    $bp_idx=$seqpos;
    my $bpcolor;
    while($bpsubset =~ /(.)/g) {
      $bp=$1;
      $bp =~ tr/a-z/A-Z/;
      $status = Imported::MySQL_GSC::GetBPStatus($readsummary,$well_idx,$bp_idx);
      $bpcolor=ColorScale($scores[$bp_idx],
			  $phredvalues,
			  $stdrainbow);
      if($bp =~ /n/i) {
	$bpcolor="white";
      }
      my $test = length($bpsubset);
      print "<td align=center width=$colwidth class=$bpcolor><span class=large>$bp</span></td>\n";      
      $bp_idx++;
    } 
    print "</tr>\n";
    # Print the score row
    print "<tr>";
    my $phredcolor;
    $bp_idx=$seqpos;
    while($bpsubset =~ /(.)/g) {
      $status = Imported::MySQL_GSC::GetBPStatus($readsummary,$well_idx,$bp_idx);
      if($status =~ /quality/) { 
	$phredcolor = "white";
      } else {
	$phredcolor = "black";
      }
      print "<td align=center width=$colwidth class=$phredcolor><span class=small>$scores[$bp_idx]</span></td>\n";      
      $bp_idx++;
    } 
    print "</tr>\n";
    print "</table>";
    print qq{<img src="/$image_dir/spacer.png" height=5><Br>};
    $seqpos+=$bpcols;
#    if($seqpos >100) {last}
  } 
NEWVIEW:
  ################################################################
  # New sequence view: no tables!

  my $seqpos=0;
  my $bpsubset;
  my $bp;
  # Extract chunks from the sequence;
  # Each sequence line is accompanied by index (top) and score (bottom)
  #
  # 10             15             20       ...
  # a  g  t  c  t  c  a  t  g  a  a  t  t  ...
  # 15 12 33 30 55 23 23 8  5  25 30 25 11 ...
  #
  my $newview = "";
  my $spacer=3;
  my $idxtickperiod=5;
  my $idxsize=$spacer*$idxtickperiod;
  $bp_idx=0;
  my ($idxview,$bpview,$scoreview)=("","","");
  my $idx,$bp,$score;
  $stdrainbow = ["vlightpurpletext","vlightbluetext","vlightgreentext","vlightgreentext",
		 "vlightyellowtext","vlightyellowtext","vlightorangetext"
		 ,"vlightredtext","mediumredtext"];
  my $suppressidx=0;
  while($sequence =~ /(.)/g) {
    $status = Imported::MySQL_GSC::GetBPStatus($readsummary,$well_idx,$bp_idx);
    $bp = sprintf("%-${spacer}s",$1);
    $bp =~ tr/a-z/A-Z/;
    $bp = "<b>$bp</b>";
    $bpcolor=ColorScale($scores[$bp_idx],
			$phredvalues,
			$stdrainbow);
    $bpview .= "<span class=$bpcolor>$bp</span>";
#    if(!($bp_idx % $idxtickperiod)) {
    # This is the index number.
    $idx = sprintf("%d",$bp_idx);
    if(length($idx) > $spacer) {
      my $spacer2=2*$spacer;
      $idx = sprintf("%-${spacer2}d",$idx);
    } else {
      $idx = sprintf("%-${spacer}d",$idx);
    }
    if(! $suppressidx && !(($bp_idx)%$idxtickperiod)) {
      $idxview .= "<span class=greytext>$idx</span>";
      if(length($idx)>$spacer) {
	$suppressidx=1;
      }
    } elsif(! $suppressidx) {
      $idxview .= sprintf("%${spacer}s"," ");
      $suppressidx=0;
    } else {
      $suppressidx=0;
    }
    $score = sprintf("%-3d",$scores[$bp_idx]);
    if($status =~ /quality/ && $status !~ /vector/) {
      $scoreview .= "<span class=vdarkgreen>$score</span>";
    } elsif ($status =~ /vector/ && $status !~ /quality/) {
      $scoreview .= "<span class=vdarkyellow>$score</span>";
    } elsif ($status =~ /vector/ && $status =~ /quality/) {
      $scoreview .= "<span class=vdarkorange>$score</span>";
    } else {
      $scoreview .= $score;
    }

    if(! (($bp_idx+1) % $bpcols) && $bp_idx > 2) {
      $newview .= $idxview."\n";
      $newview .= $bpview."\n";
      $newview .= $scoreview."\n";
      $newview .= "\n";
      ($idxview,$bpview,$scoreview) = ("","","");
    }
    $bp_idx++;
#    if($bp_idx>2000) {last}
  }
  print "<table><tr><td class=black>";
  print "<pre>$newview</pre>";
  print "</td></tr></table>";

}


sub htmlPlateViewPhred {

  my $p;
  my $phredvalue;

  $phredvalue = Extract_Values([param('phredvalueplate'),$DEFAULTPHRED]);
  if ($phredvalue < 0 || $phredvalue > 99) {
    $phredvalue=$DEFAULTPHRED;
  }

  # Override the phred value with passed argument, if available.
  # Print the small form that offers the user to change the phred value.
  $p .= "<table>\n";
  $p .= start_form;
  $p .= "<tr><td>";
  $p .= HiddenMultiple(['phredvalue'],param);
  $p .= "<span class=small><span class=greytext>Phred value for well colours</span></span> ";
  $p .= textfield(-name=>'phredvalueplate',-value=>$phredvalue,-size=>3,-style=>'font-size:12px;');
  $p .= " ";
  $p .= submit(-name=>"Analyze",-label=>"Redisplay",-style=>'font-size:12px;');
  $p .= "</td></tr>";
  $p .= end_form;
  $p .= "</table>\n";

  return $p;
}


sub htmlPlateView {
  #
  # Fun & colourful M&M style plate view
  #

  my $hash = shift || "";
  my $runid;
  my $phredvalue;
  Imported::MySQL_Tools::ArgAssign($hash,{'runid'=>\$runid,
				'phredvalue'=>\$phredvalue,
			       },$hash);
  my ($row_size, $col_size) = getRowColSize( $runid );


  # Grab the phred value from parameters, if not available from the
  # argument hash
  if (! defined $phredvalue) {
    $phredvalue = Extract_Values([param('phredvalueplate'),$DEFAULTPHRED]);
  }
  if ($phredvalue < 0 || $phredvalue > 99) {
    $phredvalue=$DEFAULTPHRED;
  }

  my $db = Imported::MySQL_GSC::GetSequenceDb;
  my $phred_lengths = $db->Imported::MySQL_GSC::GetPhredLengths({'phreds'=>[$phredvalue],'scope'=>"runid:$runid",'testruns'=>'yes','qualityonly'=>'no'});
  my $read_summary = $db->Imported::MySQL_GSC::GetReadSummary($runid);
  my ($img_idx, $well_idx, $row,$col, $well_text, $readlength, $phredlength, $nogrow, $slowgrow, $alt);
  print "<table border=0 cellspacing=0 cellpadding=0>\n";
  print "<tr>\n";
  print "<td colspan=" . ($col_size + 1) . " align=center>";
  print "<b>Plate View for RunID $runid</b><br>";
  print "<i><span class=small>Colour-coded read quality length (phred $phredvalue)</span></i>";
  print "</td>\n";
  print "</tr>\n";
  print "<tr><td><img src='/$well_image_dir/well-blank.png'></td>";
  foreach ($col=0; $col < $col_size; $col++) {
    $well_idx = $col + 1;
    print "<td><img src='/$well_image_dir/$well_idx.png'></td>";
  }
  print "</tr>";
  $well_idx = 0;
  foreach ($row=0; $row < $row_size; $row++) {
    print "<tr>";
    #$well_idx = $row+1;
    print "<td><img src='/$well_image_dir/" . _row_num_to_alphabet($row+1) . ".png'></td>"; #Translate the row numbers into alphabets.
    foreach ($col=0; $col < $col_size; $col++) {
	#$well_idx = $row * $col_size + $col;
	if ($read_summary->[$well_idx]->{'well'} eq (_row_num_to_alphabet($row+1) . sprintf("%02d",$col+1))) {
	    $well_text = $read_summary->[$well_idx]->{'well'};
	    $readlength = $read_summary->[$well_idx]->{'length'};
	    $phredlength = $phred_lengths->[0]->[$well_idx];
	    $qualitylength = $read_summary->[$well_idx]->{'qt'};
	    $vectorlength = $read_summary->[$well_idx]->{'vt'};
	    $comment = $read_summary->[$well_idx]->{'comment'};
	    if ($read_summary->[$well_idx]->{'growth'} eq "No Grow") { $nogrow = 1; } else { $nogrow = 0; }
	    if ($read_summary->[$well_idx]->{'growth'} eq "Slow Grow") { $slowgrow = 1; } else { $slowgrow = 0; }
	    if(! $readlength) {
		$img_idx = "failed";
		if ($nogrow)   { $img_idx .= "-ng"; }
		if ($slowgrow) { $img_idx .= "-sg"; }
	    } elsif ( $phredlength == 0 ) {
		$img_idx = 0;
		if ($nogrow) { $img_idx .= "-ng"; }
		if ($slowgrow) { $img_idx .= "-sg"; }
	    } else {
		$img_idx = int( $phredlength / 100 ) + 1;
		if ($img_idx > 9) {
		    $img_idx = 9;
		}
		if ($nogrow) { $img_idx .= "-ng"; }
		if ($slowgrow) { $img_idx .= "-sg"; }
	    }
	    $alt = "$phredlength/$readlength/$qualitylength/$vectorlength/$comment";
	    if ($nogrow) { $alt = "NO GROW $alt"; }
	    if ($slowgrow) { $alt = "SLOW GROW $alt"; }
	    my $chromatogram_link = "$URL_address/view_chromatogram.pl?runid=$runid&well=$well_text&height=$APPLET_HEIGHT&width=$APPLET_WIDTH";
	    my $on_click = "window.open('$chromatogram_link','newwin','height=800,width=1000,scrollbars=yes,resizable=yes,toolbar=yes,location=no,directories=no'); return false";
	    print
		"<td>",
		qq{<a href="$chromatogram_link" onMouseOver="select($well_text$runid,1);" onMouseOut="select($well_text$runid,0)" onClick="$on_click">},
		"<img src='/$well_image_dir/well-$img_idx-s0.png' border=0 name=$well_text$runid alt='$alt'>",
		"</a>",
		"</td>";
	    $well_idx++;
	}
	else {
	    print "<td bgcolor='black'></td>";
	}
    }
    print "</tr>";
  }
  print "</table>";
}


sub htmlQuadPlateView {
  #
  # Fun and colourful M&M style plate view that displays four 96 well plates
  # as one seamless 384 well plate
  #

  my $hash = shift || "";
  my $p;
  my $runid;
  my $phredvalue;
  my ($phred_lengths, $read_summary);
  my ($img_idx, $well_idx, $row,$col, $well_text, $readlength, $phredlength, $nogrow, $slowgrow, $alt);
  my ($db, $runs_aref, $quad_idx);

  Imported::MySQL_Tools::ArgAssign($hash,{'runid'=>\$runid,
				'phredvalue'=>\$phredvalue,
			       },$hash);
  my $row_size = 16;
  my $col_size = 24;

  # Grab the phred value from parameters, if not available from the
  # argument hash
  if (! defined $phredvalue) {
    $phredvalue = Extract_Values([param('phredvalueplate'),$DEFAULTPHRED]);
  }
  if ($phredvalue < 0 || $phredvalue > 99) {
    $phredvalue=$DEFAULTPHRED;
  }

  $db = Imported::MySQL_GSC::GetSequenceDb;
  $runs_aref = getBatchByRun( $runid );

  $p .= "<table border='0' cellspacing='0' cellpadding='0'>\n";
  $p .= "<tr>\n";
  $p .= "<td colspan=" . ($col_size + 1) . " align=center>";
  $p .= "<table border='0' cellspacing='2' cellpadding='4' bgcolor='#eeeeee'>\n";
  $p .= "<tr><td colspan='2' bgcolor='#bbbbbb'><b>Plate&nbsp;View&nbsp;for&nbsp;Runs</b></td></tr>";
  $p .= "<tr>\n";
  $p .= qq{<td>a: <a href="${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[0]&option=bpsummary&$PARAMS">$$runs_aref[0]</a></td>\n};
  $p .= qq{<td>b: <a href="${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[1]&option=bpsummary&$PARAMS">$$runs_aref[1]</a></td>\n};
  $p .= "</tr>\n";
  $p .= "<tr>\n";
  $p .= qq{<td>c: <a href="${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[2]&option=bpsummary&$PARAMS">$$runs_aref[2]</a></td>\n};
  $p .= qq{<td>d: <a href="${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[3]&option=bpsummary&$PARAMS">$$runs_aref[3]</a></td>\n};
  $p .= "</tr>\n";
  $p .= "</table>&nbsp;<br>\n";

  $p .= "<i><span class=small>Colour-coded read quality length (phred $phredvalue)</span></i>";
  $p .= "</td>\n";
  $p .= "</tr>\n";
  $p .= "<tr><td><img src='/$well_image_dir/well-blank.png'></td>";
  foreach ($col=0; $col < $col_size; $col++) {
    $p .= "<td><img src=\"http://seq.bcgsc.bc.ca/Images/" . ($col + 1) . ".gif\"></td>";
  }
  $p .= "</tr>";

  foreach ($row=0; $row < $row_size; $row++) {
    $p .= "<tr>";
    $p .= "<td><img src=\"http://seq.bcgsc.bc.ca/Images/" . ($row + 1) . ".gif\"></td>";
    if ($row == 0 or $row == 8) {
      for ($i=1; $i < 3; $i++) {
	$p .= "<td colspan='12' rowspan='8'>\n";
	$p .= "<!-- begin nested 96 well plate table -->\n";
	$p .= "<table border='0' cellpadding='0' cellspacing='0'>\n";
	$phred_lengths = $db->Imported::MySQL_GSC::GetPhredLengths(
							 {'phreds'=>[$phredvalue],
							  'scope'=>"runid:$$runs_aref[$quad_idx]",
							  'testruns'=>'yes',
							  'qualityonly'=>'no'}
							);
	$read_summary = $db->Imported::MySQL_GSC::GetReadSummary($$runs_aref[$quad_idx]);
	foreach ($r=0; $r < 8; $r++) {
	  $p .= "<tr>\n";
	  foreach ($c=0; $c < 12; $c++) {
	    $well_idx = ($r * 12) + $c;
	    $well_text = $read_summary->[$well_idx]->{'well'};
	    $readlength = $read_summary->[$well_idx]->{'length'};
	    $phredlength = $phred_lengths->[0]->[$well_idx];
	    $qualitylength = $read_summary->[$well_idx]->{'qt'};
	    $vectorlength = $read_summary->[$well_idx]->{'vt'};
	    $comment = $read_summary->[$well_idx]->{'comment'};
	    if ($read_summary->[$well_idx]->{'growth'} eq "No Grow") { $nogrow = 1; } else { $nogrow = 0; }
	    if ($read_summary->[$well_idx]->{'growth'} eq "Slow Grow") { $slowgrow = 1; } else { $slowgrow = 0; }
	    if(! $readlength) {
	      $img_idx = "failed";
	      if ($nogrow)   { $img_idx .= "-ng"; }
	      if ($slowgrow) { $img_idx .= "-sg"; }
	    } elsif ( $phredlength == 0 ) {
	      $img_idx = 0;
	      if ($nogrow) { $img_idx .= "-ng"; }
	      if ($slowgrow) { $img_idx .= "-sg"; }
	    } else {
	      $img_idx = int( $phredlength / 100 ) + 1;
	      if ($img_idx > 9) {
		$img_idx = 9;
	      }
	      if ($nogrow) { $img_idx .= "-ng"; }
	      if ($slowgrow) { $img_idx .= "-sg"; }
	    }
	    $alt = "$phredlength/$readlength/$qualitylength/$vectorlength/$comment";
	    if ($nogrow) { $alt = "NO GROW $alt"; }
	    if ($slowgrow) { $alt = "SLOW GROW $alt"; }
	    $p .= "<td>";
	    $p .= qq{<a href="$URL_domain${PROGNAME}?scope=sequence&scopevalue=$runid-$well_text&$PARAMS" onMouseOver="select($well_text$runid,1);" onMouseOut="select($well_text$runid,0)">};
	    $p .= "<img src='/$well_image_dir/well-$img_idx-s0.png' border=0 name=$well_text$runid alt='$alt'>";
	    $p .= "</a></td>\n";
	  }
	  $p .= "</tr>\n";
	}
	$p .= "</table>\n";
	$p .= "<!-- End nested 96 well plate table -->\n";
	$p .= "</td>\n";
	$quad_idx++;
      }
    }
    $p .= "</tr>\n";
  }
  $p .= "</table>\n\n";

  return $p;
}


sub htmlPlateViewLegend {

  $p .= <<"HerePlateViewLegend";

  <table border=0 cellspacing=0 cellpadding=0>

  <tr>
  <td class=small align=center>failed</td>
  <td class=small align=center>=0</td>
  <td class=small align=center>&gt;0</td>
  <td class=small align=center>100</td>
  <td class=small align=center>200</td>
  <td class=small align=center>300</td>
  <td class=small align=center>400</td>
  <td class=small align=center>500</td>
  <td class=small align=center>600</td>
  <td class=small align=center>700</td>
  <td class=small align=center>800</td>
  <td class=small align=center>900</td>
  <td class=small align=center>1000</td>
  </tr>

  <tr>
  <td><img src="/$well_image_dir/well-failed-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-0-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-1-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-2-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-3-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-4-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-5-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-6-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-7-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-8-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-9-s0.png" border=0 name=H12></td>
  <td><img src="/$well_image_dir/well-10-s0.png" border=0 name=H12></td>  
  <td><img src="/$well_image_dir/well-11-s0.png" border=0 name=H12></td>     
  </tr>

  <tr>
  <td colspan=11 align=right>
    <span class=small>white cross = no grows | semi circle = slow grows</span><br>
    e.g. <img src="/$well_image_dir/well-1-ng-s0.png" alt="Example of a no grow well"> <img src="/$well_image_dir/well-1-sg-s0.png" alt="Example of a slow grow well"><br>
    <b>Legend</b>: well quality length (phred 20)<br>
    <span class=small>phred quality length/read length/quality length/vector length/comment</span></td>
  </tr>

  </table>
HerePlateViewLegend

  return $p;
}


sub htmlBatchLinks {
  my $runid = shift;
  my $option = shift;
  my $p;

  my $runs_aref = getBatchByRun( $runid );
  if (scalar @$runs_aref > 1) {
    $p .= "<p>Show <a href='${PROGNAME}?scope=RunID&scopevalue=$$runs_aref[0]&option=$option&batch=1&$PARAMS'>entire batch</a>.<br>\n";
    $p .= "Runs in batch: ";
    for (@$runs_aref) {
      $p .= "<a href='${PROGNAME}?scope=RunID&scopevalue=$_&option=bpsummary&$PARAMS'>$_</a> \n";
    }
    $p .= "</p>";
  }

  return $p;
}


sub getBatchByRun {
  my $runid = shift;
  my @runs;
  my $quad;

  my $dbc = DBI->connect("DBI:mysql:sequence:$DBASE" , 'viewer', 'viewer', {RaiseError => 1});
  my $sth = $dbc->dbh()->prepare("select FK_RunBatch__ID from Run where Run_ID=$runid");
  $sth->execute();
  my $sbid = ${$sth->fetchrow_hashref()}{'FK_RunBatch__ID'};
  $sth->finish();

  my $sth = $dbc->dbh()->prepare("select Run_ID, Run_Directory from Run where FK_RunBatch__ID=$sbid");
  $sth->execute();
  while (my $href = $sth->fetchrow_hashref()) {
    ${$href}{'Run_Directory'} =~ m/.{5}\d+(\w+)/;
    $quad = lc $1;
    if ($quad eq 'a') { $quad = 0 }
    elsif ($quad eq 'b') { $quad = 1 }
    elsif ($quad eq 'c') { $quad = 2 }
    elsif ($quad eq 'd') { $quad = 3 }
    else { $quad = 4 }
    $runs[$quad] = ${$href}{'Run_ID'};
  }
  $sth->finish();

  $dbc->disconnect();

  return \@runs;
}


sub ListReads {

  my $runid = shift;
  my $db = Imported::MySQL_GSC::GetSequenceDb();
  $reads = $db->CreateSearch("reads");
  $reads->SetTable("Clone_Sequence");
  $reads->AddFK({'field'=>'Run.ID'});
  $reads->AddField({'field'=>'Run.Run_ID','value'=>$runid});
  $reads->AddViewField({'field'=>'Run.Run_ID'});
  $reads->AddViewField({'field'=>'Well','alias'=>'Well'});
  $reads->AddViewField({'field'=>'Run','alias'=>'Run'});
  $reads->AddViewField({'field'=>'Sequence_Length','alias'=>'Length'});
  $reads->AddViewField({'field'=>'Quality_Left','alias'=>'QL'});
  $reads->AddViewField({'field'=>'Quality_Length','alias'=>'QTot'});
  $reads->AddViewField({'field'=>'Vector_Total','alias'=>'VTot'});
  $reads->AddViewField({'field'=>'Vector_Left','alias'=>'VL'});
  $reads->AddViewField({'field'=>'Vector_Right','alias'=>'VR'});
  $reads->AddViewField({'field'=>'Vector_Quality','alias'=>'VQ'});
  $reads->AddViewField({'field'=>'Clone_Sequence_Comments','alias'=>'Comments'});
  $reads->Order({'field'=>'Well','alias'=>'Well'});
  $reads->Execute();
  $reads->PrintHTML({
    'title'=>"Reads for Run ID $runid ",
    'center'=>'yes',
    'excludetypes'=>['.*blob.*'],
    'excludefields'=>['Run_ID'],
    'extratagstypes'=>{'.*int|float.*'=>'class=vvlightgreen align=center|<span class=small>%%VALUE%%</span>'},
    'extratagsfields'=>{'Well'=>'align=center class=vvlightred|',
			'Run'=>'align=left class=vvlightblue|<span class=small>%%VALUE%%</span>',
			'Sequencer'=>'align=center|%%VALUE%%',
			'Comments'=>'class=lightred|'},
    'links'=>{'Well'=>"$URL_domain${PROGNAME}?scope=sequence&scopevalue=%Run_ID%-%Well%&$PARAMS",
	      'Run'=>"$URL_domain${PROGNAME}?scope=sequence&scopevalue=%Run_ID%-%Well%&$PARAMS",
	    }
  });
}

sub GetScopeSearch {
  my $db    = shift;
  my $scope = shift;
  my $scopevalue = shift;
  if($scope =~ /sequencer/i) {
    $scopesearch=$db->CreateSearch("scopesearch");
    $scopesearch->SetTable("Equipment");
    $scopesearch->AddFK({'field'=>'Organization.ID'});
    $scopesearch->AddField({'field'=>'Equipment_Name','value'=>$scopevalue});
    $scopesearch->Execute;
  } elsif  ($scope =~ /project/i) {
    $scopesearch=$db->CreateSearch("scopesearch");
    $scopesearch->SetTable("Project");
    $scopesearch->AddField({'field'=>'Project_Name','value'=>$scopevalue});
    $scopesearch->Execute;
  } elsif ($scope =~ /library/i) {
    $scopesearch=$db->CreateSearch("scopesearch");
    $scopesearch->SetTable("Library");
    $scopesearch->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
    $scopesearch->AddField({'field'=>'Library_Name','value'=>$scopevalue});
    $scopesearch->Execute;
  } elsif ($scope =~ /runid/i) {
    # For a run scope, list some plate and library info as well.
    $scopesearch=$db->CreateSearch("scopesearch");
    $scopesearch->SetTable("Run");
    $scopesearch->AddFK({'field'=>'Plate.ID'});
    $scopesearch->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
    $scopesearch->AddFK({'field'=>'RunBatch.ID'});
    $scopesearch->AddFK({'field'=>'Equipment.ID','fktable'=>'RunBatch'});
    $scopesearch->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
    $scopesearch->AddField({'field'=>'Run_ID','value'=>$scopevalue});
    $scopesearch->Execute;
  } elsif ($scope =~ /sequence|read/) {
    my ($run,$well);
    if($scopevalue =~ /(.*)\-(.*)/) {
      $run=$1;
      $well=$2;
    } else {
      return NULL;
    }
    $scopesearch=$db->CreateSearch("scopesearch");
    $scopesearch->SetTable("Clone_Sequence");
    $scopesearch->AddFK({'field'=>'Run.ID'});
    $scopesearch->AddFK({'field'=>'Plate.ID','fktable'=>'Run'});
    $scopesearch->AddFK({'field'=>'Library.Name','fktable'=>'Plate'});
    $scopesearch->AddFK({'field'=>'RunBatch.ID','fktable'=>'Run'});
    $scopesearch->AddFK({'field'=>'Equipment.ID','fktable'=>'RunBatch'});
    $scopesearch->AddFK({'field'=>'Project.ID','fktable'=>'Library'});
    $scopesearch->AddField({'field'=>'Run.Run_ID','value'=>$run});
    $scopesearch->AddField({'field'=>'Well','value'=>$well});
    $scopesearch->Execute;
  }
  return $scopesearch;
}

sub HiddenMultiple {

  my $exclude = shift;
  my @params = @_;
  my ($excl,$p,@results);
  my $excl_flag=0;
  foreach $p (@params) {
    my $excl_flag=0;
    foreach $excl (@{$exclude}) {
      if($p =~ /$excl/i) {
	$excl_flag=1;
	last;
      }
    }
    if(! $excl_flag) {
      push(@results,hidden(-name=>$p));
    }
  }
  return @results;

}

sub NotEmpty {

  my @array = @_;
  if(! @array) {
    return 0;
  }
  if(@array == 1 && $array[0] eq "") {
    return 0;
  }
  return 1;

}
    
sub DisplayPhredHistograms {
  
  my $hash = shift || "";
  my $scope;
  my $scopevalue;
  my $phredvalues;
  my $pvhistdvalue;
  my $sequencers;
  my $testruns;
  my $search;
  
  Imported::MySQL_Tools::ArgAssign($hash,{'scope'=>\$scope,
				'scopevalue'=>\$scopevalue,
				'phredvalues'=>\$phredvalues,
				'testruns'=>\$testruns,
				'search'=>\$search,
				'sequencers'=>\$sequencers,
				'pvhistdvalue'=>\$pvhistdvalue,
			      },$hash);

  ################################################################
  # Make the histogram data structures
  #
  my $HISTBINWIDTH=100;
  my $phredlength;
  my $hist;
  my $hist_d;
  my $phredavg;
  my $read_num;
  my $phred_idx=0;
  my $db = Imported::MySQL_GSC::GetSequenceDb;
  my $phredscores;
  if(defined $search) {
    $phredscores = $db->Imported::MySQL_GSC::GetPhredLengths({'phreds'=>$phredvalues,'search'=>$search});
  } else {
    $phredscores = $db->Imported::MySQL_GSC::GetPhredLengths({'phreds'=>$phredvalues,'scope'=>"$scope:$scopevalue",'testruns'=>'yes'});
  }
  # For every phred score that was requested (i.e. 20)
  # Here we make two kinds of histograms: detailed histograms (bin size=10) and summary histograms
  # (bin size=100)
  foreach $phredvalue (@{$phredvalues}) {
    # Cycle over all the phred lengths for the requested value.
    foreach $phredlength (@{$phredscores->[$phred_idx]}) {
      # Histogram the length into a histogram with bin size of 100.
      if(! $phredlength) {
	$hist->{$phredvalue}->[0]++;
	$hist_d->{$phredvalue}->[0]++;
      } else {
	$hist->{$phredvalue}->[int($phredlength/$HISTBINWIDTH)+1]++;
	$hist_d->{$phredvalue}->[int($phredlength/$DETAILEDHISTBIN)+1]++;
      }
      $read_num->{$phredvalue}++;
      $phredavg->{$phredvalue}+=$phredlength;

    }
    $phredavg->{$phredvalue} /= $#{$phredscores->[$phred_idx]}+1;
    $phred_idx++;
  }
  # Phred histograms are now made.
  ################################################################
  print "<table border=0 cellspacing=0 cellpadding=2><tr><td valign=top>";
  PhredHistogramTable($hist,$phredavg,$read_num);
  print "</td>";
  ################################################################
  # create a Quality Length Histogram GIF image
  ################################################################
  print "<td valign=bottom>";
  if(defined $sequencers) {
    print "<center>";
    PhredLengthSummary($phredvalues,$sequencers,$scope,$scopevalue);
    print "</center>";
    print "<br>";
  }
  print "<center>";
  print "<b>Summary Quality Length Histogram</b>";
  PhredHistogramGIF($hist,400,175);
  print "</center>";
  print "</td></tr></table>";
  print "<center><b><span class=large>Detailed Phred Histogram</span></b></center>\n";
  print "<center><i>reported for phred $pvhistdvalue</i></center>\n";
  print "<center>";
  PhredHistogramGIF_Detail($hist_d,$pvhistdvalue,600,200);
  print "</center>";
  return;
}

sub PrintHistogramForm {

  my $var;
  my $pvhistd;
  my $phredvalues = ();
  # Populate the phredvalues array with the values from the form fields
  foreach $var (0..2) {
    if(defined param("pvhist$var") && param("pvhist$var") > 0 && param("pvhist$var") < 99) {
      push(@{$phredvalues},param("pvhist$var"));
    } else {
      # Do nothing if form field not set
    }
  }
  # If none of the form fields are set, then set them to the default values.
  if(! @{$phredvalues}) {
    $phredvalues = [10,20,30];
  }
  # Sort the phred values!
  if(defined param("pvhistd")) {
    $pvhistd = param("pvhistd");
  } else {
    $pvhistd = 1;
  }
  # Define which field is to be used for the detailed histogram view.
  if(! defined $phredvalues->[$pvdistd]) {
    if(defined $phredvalues->[0]) {
      $pvdistd=1;
    } else {
      $pvdistd=2;
    }
  }
  my $pvhistdvalue = $phredvalues->[$pvhistd];
  my @sorted = @{$phredvalues};
  @sorted = sort {$a <=> $b} @sorted;
  $phredvalues = \@sorted;
#  print @{$phredvalues};
#  print " ",$pvhistd," ",$pvhistdvalue;
  if($pvhistdvalue != $phredvalues->[$pvhistd]) {
    if($pvhistdvalue == $phredvalues->[0]) {
      $pvhistd = 0;
    } elsif ($pvhistdvalue == $phredvalues->[1]) {
      $pvhistd = 1;
    } else {
      $pvhistd = 2;
    }
  }
  %labels = ("0"=>"","1"=>"","2"=>"");
  print
      "<table>",
      start_form,
      "<tr><td>",
      HiddenMultiple(["pvhist0","pvhist1","pvhist2","pvhistd"],param),
      "<span class=small><span class=greytext>Phred values for histograms (radio button indicates phred value for detailed histogram): </span></span> ",
      radio_group(-name=>'pvhistd',-values=>0,-size=>3,-labels=>\%labels,-style=>'font-size:12px;',-default=>$pvhistd,-override=>1)," ",
      textfield(-name=>'pvhist0',-value=>$phredvalues->[0],-size=>3,-style=>'font-size:12px;',-override=>1)," ",
      radio_group(-name=>'pvhistd',-values=>1,-size=>3,-labels=>\%labels,-style=>'font-size:12px;',-default=>$pvhistd,-override=>1)," ",
      textfield(-name=>'pvhist1',-value=>$phredvalues->[1],-size=>3,-style=>'font-size:12px;',-override=>1)," ",
      radio_group(-name=>'pvhistd',-values=>2,-size=>3,-labels=>\%labels,-style=>'font-size:12px;',-default=>$pvhistd,-override=>1)," ",
      textfield(-name=>'pvhist2',-value=>$phredvalues->[2],-size=>3,-style=>'font-size:12px;',-override=>1),
      submit(-name=>"Analyze",-label=>"Redisplay",-style=>'font-size:12px;'),
      "</td></tr>",
      end_form,
      "</table>";

  return($phredvalues,$pvhistdvalue);
}

sub PrintIcons {
  
  my $runid=shift;

  print
      #qq{<a href="${PROGNAME}?scope=runid&scopevalue=$runid&option=bpsummary&$PARAMS" onMouseOver="select(bpsummary$runid,1)" onMouseOut="select(bpsummary$runid,0)"><img src="/$image_dir/bpsummary-s0.png" name=bpsummary$runid border=0 alt="See the base pair summary for RunID $runid"></a>},
      qq{<a href="${PROGNAME}?scope=runid&scopevalue=$runid&option=scorecard&$PARAMS" onMouseOver="select(scorecard$runid,1)" onMouseOut="select(scorecard$runid,0)"><img src="/$image_dir/scorecard-s0.png" name=scorecard$runid border=0 alt="See the score card for RunID $runid"></a>},
      qq{<a href="${PROGNAME}?scope=runid&scopevalue=$runid&option=histogram&$PARAMS" onMouseOver="select(histogram$runid,1)" onMouseOut="select(histogram$runid,0)"><img src="/$image_dir/histogram-s0.png" name=histogram$runid border=0 alt="See the phred histograms for RunID $runide"></a>},
      qq{<a href="${PROGNAME}?scope=runplate&scopevalue=$runid&$PARAMS" onMouseOver="select(runplate$runid,1)" onMouseOut="select(runplate$runid,0)"><img src="/$image_dir/runplate-s0.png" name=runplate$runid border=0 alt="See the run plate for RunID $runid"></a>},
      #qq{<a href="${PROGNAME}?scope=runid&scopevalue=$runid&option=runlist&$PARAMS" onMouseOver="select(runlist$runid,1)" onMouseOut="select(runlist$runid,0)"><img src="/$image_dir/runlist-s0.png" name=runlist$runid border=0 alt="See the run list for RunID $runid"></a>},
      #qq{<a href="${PROGNAME}?searchform=1&$PARAMS" onMouseOver="select(searchruns$runid,1)" onMouseOut="select(searchruns$runid,0)"><img src="/$image_dir/search-s0.png" name=searchruns$runid border=0 alt="Search for runs or reads"></a>},
      #" ",
      #qq{<a href="${PROGNAME}?$PARAMS" onMouseOver="select(toplevel$runid,1)" onMouseOut="select(toplevel$runid,0)"><img src="/$image_dir/toplevel-s0.png" name=toplevel$runid border=0 alt="Look at the top level database summary."></a>},
      
}

################################################################
# Database application header. Displayed immediately above
# the top bar.

sub Header {

  my $date = strftime "%d %B %Y %H:%M:%S",localtime;
  print "<span class=greytext><span class=small>GSC Run Viewer $VERSION $RELEASE [$CVSDATE]| Today: $date&nbsp;&nbsp;</span></span>\n<br>";
  print qq{<img src="/$image_dir/sequence_viewer_title.png"};
  print "<br><br><br>";
  
}

#
################################################################

sub getRowColSize {
  # Hacky subroutine to determine the number of rows and columns
  # for a given run

  my $runid = shift;

  my $row_size = 8;
  my $col_size = 12;

  my $dbc = DBI->connect("DBI:mysql:sequence:$DBASE" , 'viewer', 'viewer', {RaiseError => 1});
  my $sth = $dbc->dbh()->prepare("SELECT Plate_Size FROM Plate,Run WHERE Run_ID=$runid AND FK_Plate__ID=Plate_ID");
  $sth->execute();
  if ( ${$sth->fetchrow_hashref()}{'Plate_Size'} =~ /384.*well/ ) {
    $row_size = 16;
    $col_size = 24;
  }
  $sth->finish();
  $dbc->disconnect();

  return ($row_size, $col_size);
}

##############################
sub _row_num_to_alphabet {
##############################
#
# Converts a row number of a plate to the corresponding alphabet
#
    my $number = shift;

    my $ascii;
    if ($number < 10) {
	$ascii = ord($number) + 16;
    }
    else {
	$ascii = ord(9) + 16 + ($number - 9);
    }

    return chr($ascii); 
}
