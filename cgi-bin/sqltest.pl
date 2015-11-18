#!/usr/local/bin/perl
################################################################################
# sqltestcd .pl
#
#  This is a database administrator front end
#
################################################################################

################################################################################
# $Id: sqltest.pl,v 1.7 2003/11/21 20:10:22 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.7 $
#     CVS Date: $Date: 2003/11/21 20:10:22 $
################################################################################

#

use CGI qw(:standard);
#use local::gscweb;

use vars qw($user $homefile $homelink);
use vars qw(@libraries @tables $dbase @users);
use vars qw($colour_on_off);

#use strict;


use DBI;
use Benchmark;

 
use SDB::RGIO;
use SDB::Plate;
use SDB::GSCvariables;
use SDB::Run;
use SDB::Solutions;
use SDB::Table;
use SDB::Sequencing;
use SDB::SDB_Status;

use SDB::Views;
use SDB::DB_Form_Viewer;

######## Sequencing Lab Specific Modules ########
require "$FindBin::RealBin/../Custom_Settings.pl";

#
# set up standard page template... (from gscweb)
######################################################

$dbase = param('Database') || "sequence";

my $page = 'gscweb'->new();
$page->SetTitle("$dbase Mapping");
$page->SetContactName("Ran Guin");
$page->SetContactEmail("rguin\@bcgsc.bc.ca");
$page->SetAgeObject("$db_name database");
#$page->SetAgeFile("$db_dir/database/block1.wrm");

$page->TopBar();
 
print "\n<!------------ Java -------------!>\n";
print "\n<script src='/intranet/js/SDB.js'></script>";    

#######################################################

my $feedback = 0;
$style = "html";

my $colour1 = "lightblue";
my $colour2 = "whitesmoke";
my $colour;
my $colour_on;

my $debug = 0;
 
$dbc = DB_Connect(dbase=>$dbase);
@libraries = Table_find($dbc,'Library','Library_Name','Order by Library_Name');
@tables = $dbc->tables();
@users = &Table_find($dbc,'Employee','Employee_Name','Order by Employee_Name');

#&test();

my $br = "<BR>\n";
if ($feedback) {
    foreach my $name (param()) {
	my $value = join ',', param($name);
	print "$name: $value".$br;
    }
}
#######################################################################################

my $mycgi = new CGI;

$homefile = $0;  ##### a pointer back to this file 
if ($homefile =~/\/([\w_]+[.pl]{0,3})$/) {
    $homefile = "http://rgweb.bcgsc.bc.ca/cgi-bin/intranet/$1";
}
elsif ($homefile =~/\/([\w_]+)$/) {
    $homefile = "http://rgweb.bcgsc.bc.ca/cgi-bin/intranet/$1";
}

$user = param('User') || 'Guest';

my $Huser = $user; $Huser=~s / /+/g;
$homelink = "$homefile?User=$Huser&Database=$dbase";

########## Generic Search / Edit functions ################
if (&DB_Viewer_Branch($dbc)) {$page->BottomBar(); exit;}
elsif (param('Search for')) {	   
    my $table = param('Table');
    Table_search(-dbc=>$dbc,-tables=>$table);
}
elsif (param('Search')) {	   
    my $table = param('Table');
    Table_search_edit($dbc,$table);
}
elsif (param('Next Page') || param('Previous Page') || param('Get Page')) {
    my $table = param('Table');
    Table_search_edit($dbc,$table,param('Search List'));
}
elsif (param('Save Changes')) {
    my $table = param('Table');
    &Table_search_edit($dbc,$table,param('Search List'),'update');
    &Table_search_edit($dbc,$table,param('Search List'));   
}
elsif (param('Save Changes as New')) {
    my $table = param('Table');
    &Table_search_edit($dbc,$table,param('Search List'),'append');
    &Table_search_edit($dbc,$table,param('Search List'));   
}
elsif (param('Parse')) {
    my $table = param('TableName');
    my $file = param('FileName');
    &parse_to_table($dbc,$table,$file);
}
elsif (param('Parse File')) {
    my $table = param('TableName');
    my $file = param('FileName');
    &perform_parse($dbc,$table,$file);
}
##########################3
elsif (param('SEARCH')) {
    print h1("Searching in Table");
    Table_search(-dbc=>$dbc,-tables=>param('TableName'));
}
elsif (param('Create Table')) {
    print h1("Creating Table");
    define_table($dbc,param('TableName'),param('fields'));
}
elsif (param('Construct Table')) {
    print h1("Constructing Table");
    construct_table($dbc,param('TableName'));
    &admin_home;
}
elsif (param('Add Table')) {
    print h1("Adding Table");
    Table_add($dbc,param('TableName'),param('fields'));
}
elsif (param('Drop Table')) {
    my $table=param('TableName');
    print h1("Dropped Table: \"$table\"");
    Table_drop($dbc,$table);
    &admin_home;
}
elsif (param('View Table')) {
    print h1("Viewing Table");
    my $table = param('TableName');
    my @fields = split ',',param('View Fields');
    my $conditions = param('Conditions');
    if (param('Limit')=~/(\d+)/) {$conditions .= " Limit $1";}
    
    my $Records = DB_Record->new($dbc,$table);
    $Records->List_by_Condition($conditions);
#    &view_table($dbc,param('TableName'),\@fields,$conditions);
}
elsif (param('Show Table Details')) {
    print h1("Table Model");
    show_table($dbc,param('TableName'));
}
elsif (param('Tree')) {
    print h1("Table Tree Structure");
    my $table = param('TableName');
    my $multilevel = param('MultiLevel') || 0;
    Table_Tree($dbc,$table,multilevel=>$multilevel);
}
elsif (param('Append Table')) {
    print "Append Table";    
    foreach my $name (param()) {
	my $value=param($name);
	if ($name=~m"F:") {
	    $name=$';
	    chomp $name;
	    $newfields .= "$name,";
	    $newentries .= "\"$value\",";
	}
    }
    chop $newfields; chop $newentries;
    Table_append($dbc,param('TableName'),$newfields,$newentries);
}
elsif (param('List Tables')) {
    print h1("Table List");
    if (param('Show Fields')) {
	&list_tables($dbc,1);
    }
    else {
	&list_tables($dbc);
    }
}
#######################
#  Data Dumping 
#######################
elsif (param('DB Data Dump')) {
    my $tablelist = param('TableList');
    print h1("Dumping Tables: $tablelist");
    DB_Data_Dump($dbase,$tablelist);
}
elsif (param('DB Structure Dump')) {
    my $tablelist = param('TableList');
     my $options = param('Options');
    print h1("Dumping Structure");
    DB_Structure_Dump($dbc,$tablelist);
}
elsif (param('Add Record')) {
    print h1("Add record");
    add_record($dbc,param('TableName'));
}
elsif (param('Update Table')) {
    my $update_table = param('Update Table');
    if ($update_table=~/Update (\S+) Table/) {$update_table = $1;}
    print h1("Add record");
    update_record($dbc,$update_table);
}
elsif (param('Dump to file')) {
    print h1("Dump all Data from Table to file");
    my $dumpfile = param('Dumpfile') || param('TableName');
    my $table = param('TableName');
    Query_Dump_File($dbc,"select * from $table","$dumpfile.dump");
}
elsif (param('Delete Record')) {
    print h1("Delete record");
    delete_records($dbc,param('TableName'));
    &admin_home;
}
elsif (param('Execute')) {
    print h1("Execute command");
    Execute($dbc,param('command'));
    &admin_home;
}
elsif (param('Dump')) {
    my $command = param('dcommand');
    print h1("Execute & Dump command");
    if (param('To File')) {
	Query_Dump_File($dbc,$command,param('To File'));
    }
    else {Query_Dump_HTML($dbc,$command);}
}
elsif (param('Query')) {
    print h1("Query Results");
    Query($dbc,param('querystring'));
#    &admin_home;
}
elsif (param('Run Status')) {
    home_sequence;
}
elsif (param('Retrieve Session')) {
    my $sessionUser = param('Session User');
    my $sessionDay = param('Session Day') || '';
 
    (my $SUser) = &Table_find($dbc,'Employee','Employee_ID',"where Employee_Name='$sessionUser'");
    &retrieve_session("$SUser:$sessionDay");
    print "Retrieve Session : $SUser:$sessionDay";

}

else {&admin_home;}

$page->BottomBar(); 
exit;

#########################################################################

sub admin_home {

    my $topcolour='lightgreen';
    my $bottomcolour='lightgreen';
    my $maincolour = 'white';

    print &start_admin_form(), 
    h1("Database: $dbase");

    print "<Table cellpadding=20 border=0 cellspacing=0><TR><TD bgcolor=$topcolour>";

    print submit(-name=>'Home',-style=>"background-color:yellow"),' ',
    submit(-name=>'List Tables',-style=>"background-color:yellow"), 
    checkbox(-name=>'Show Fields'),&vspace(20),
    submit(-name=>'DB Data Dump',-style=>"background-color:red"), "optional Table List:", 
    textfield(-name=>'TableList',-size=>20),' ', 
    submit(-name=>'DB Structure Dump',-style=>"background-color:red"), 
    end_form;

    print &start_admin_form, 
    submit(-name=>'Create Table',-style=>"background-color:yellow"),
    textfield(-name=>'TableName'),
    " with ", textfield(-name=>'fields',-value=>'2', size=>5), 
   " Fields", p,    
    end_form;
    
    print "</TD></TR><TR><TD bgcolor=$maincolour>";

   # print "<HR>";
    
    print &start_admin_form(),
    "<BR><B>Table:</B>", 
    popup_menu(-name=>'TableName',-value=>[@tables]),
    submit(-name=>'SEARCH',-style=>"background-color:yellow"),
    submit(-name=>'Tree',-style=>"background-color:yellow"),
    submit(-name=>'Show Table Details',-style=>"background-color:yellow"),
    &vspace(20),
    submit(-name=>'View Table',-style=>"background-color:yellow"),"Fields:",
    textfield(-name=>'View Fields',-size=>10,-default=>'*',-force=>1),
    " Conditions: ",textfield(-name=>'Conditions',-size=>40),br,
    "Limit returned records to ",textfield(-name=>'Limit',-default=>20,-size=>4,-force=>1),
    &vspace(20),
#    submit(-name=>'Drop Table'),    
    submit(-name=>'Add Record',-style=>"background-color:yellow"),
    submit(-name=>'Parse',-value=>'Add Records from File',-style=>"background-color:yellow"),
    textfield(-name=>'FileName',-size=>20),
    &vspace(20),
    submit(-name=>'Dump to file',-value=>'Dump Table Contents to File :',-style=>"background-color:red"),
    textfield(-name=>'Dumpfile',-size=>20);

    print "</TD></TR><TR><TD bgcolor=$bottomcolour>";
#    "<HR>",    
    
    print submit(-name=>'Execute',-style=>"background-color:red")," ", 
    textarea(-name=>'command',-rows=>2,-cols=>60),
    "<HR>",    
    submit(-name=>'Query',-style=>"background-color:yellow"), 
    textfield(-name=>'querystring',-size=>60),
    "<HR>",    
    submit(-name=>'Dump',-style=>"background-color:yellow"), 
    textfield(-name=>'dcommand',-size=>60), 
    &vspace(10), 
    " to file:", 
    textfield(-name=>'To File',-size=>20), "(defaults to screen)",
    submit(-name=>'Run Status',-style=>"background-color:yellow"), 
    &vspace(20),
    end_form;
    
    print start_form(-action=>'/cgi-bin/intranet/barcode_alpha?User=Ran'),
    submit(-name=>"Retrieve Session",-style=>"background-color:yellow"),
    "  (MM:DD):",
    popup_menu(-name=>'Session Day',-value=>['','Mon','Tue','Wed','Thu','Fri','Sat','Sun']),
    " By: ",
    popup_menu(-name=>'Session User',-value=>['',@users]),    
    end_form();

    print "</TD></TR></Table>";

    return;
}

####################################################################
sub show_table {  #
###################
    my $dbc = shift;
    my $table = shift;
    print h1("Table:  $table"),p;
    print "<TABLE Border width = 90%><Caption>Fields</Caption>";
    print "<TR><TH width>Field</TH>";
    print "<TH width>Type</TH>";
    print "<TH width>Max Size (Bytes)</TH></TR><UL>";
   
    my $table_data = $dbc->dbh()->prepare("select * from $table");
    $table_data->execute();

    my $table_length = $table_data->rows;

    my %row = %{$table_data->fetchrow_hashref};
    my @field_names = keys %row;
    my @rows = values %row;

    $fields = scalar(@field_names);

    print "found $fields fields\n";

    foreach my $index (1..@field_names) {
	print "<TR>\n";
	print "<TD>$table_data->{'NAME'}->[$index-1]</TD>";
	print "<TD>$table_data->{'mysql_type_name'}->[$index-1]</TD><TD>";
	print "<TD>$table_data->{'PRECISION'}->[$index-1]</TD><TD>";
	print "</TD></TR>";
    }
    print "</Table>", p;
    $table_data->finish();
    Message("Total Records: ", $table_length);

    return;
}

##########################################################################
sub define_table {   #
######################
    my $dbc = shift;
    my $table = shift; 
    my $fields = shift;
    if ($fields=~/(\d+)/) {$fields=$1;}
    my @types=('Int','Float','Text','Char','LONGText','Date','DateTime');
    
    print "<TABLE width = 90%>";
    print h1("Adding Table: $table with $fields fields");
    print &start_admin_form(), 
    hidden(-name=>'TableName',-value=>"$table"),
    hidden(-name=>'DB',-value=>"$dbc");
    
    for (my $i=0; $i<$fields; $i++) {
	print "<TR><TD align=right>";
	print "Field Name:","</TD><TD>",textfield(-name=>"field$i"), "</TD><TD align=right>"; 
	print "Type:","</TD><TD>",popup_menu(-name=>"type$i",value=>[@types],-default=>'TEXT'),
	' ','Format: ',textfield(-name=>'Format$i',-size=>5,-default=>'');
	print "</TD><TD>",checkbox(-name=>'Primary');
	print "</TD><TD>",checkbox(-name=>'Auto-increment');
	print "</TD><TD>",checkbox(-name=>'Not Null');
	print "</TD>", p;
    }    
    print submit(-name=>'Construct Table');
    print end_form;
    print "</TR></Table>";
    return;
}
########################
sub construct_table {  #
########################
    my $db = shift;
    my $table = shift;
    my $fieldnames="";
    my $fields=0;
    my $addons=0;
    my $f=0;

    print "Constructing table: $table\n";
    foreach my $name (param()) {
	$value=param($name);
	$_=$name;
	if (/^field/) {
	    if ($f) {$fieldnames .= ", ";}
	    $field[$f++]=$value;
	    $fieldnames .= " $value";
	    $fields++;
	}
	elsif (/^type/) {
	    $fieldnames .= " $value";
	}
	elsif (/^Format/) {
	    $fieldnames .= "($value)";
	}
	elsif (/^Primary/) {
	    $fieldnames .= " PRIMARY KEY";
	    $fieldnames .= " NOT NULL";
	}
	elsif (/^Auto/) {
	    $fieldnames .= " AUTO_INCREMENT";
	}    
	elsif (/^NotNull/) {
	    $fieldnames .= " NOT NULL";
	}    
    }
#    chop $fieldnames;

    print "<BR>Creating table:  $table with $fields fields<BR>$fieldnames.";
#    Table_add($db,$table,$fieldnames);    
#    initialize_table($db,$table,$fields);
    return;
}

##########################################################################
sub initialize_table {     #
########################
    my $dbc = shift;
    my $table = shift;
    my $entries = shift;
    print "<BR> Initializing $table with $entries NULL values...";

    my $sql = "insert into $table values ("; 
    for (my $i=0; $i<$entries;) {
	$sql .= "NULL,";
	$entry[$i++]=$i*10;
    }
    chop $sql;
    $sql .=")";

    my $sth = $dbc->dbh()->prepare($sql);
    $sth->execute(@entries);
    $sth->finish();
    return;
}

##########################################################################
sub add_to_table {     #
########################
    my $dbc = shift;
    my $table = shift;
    my $querystring = "select * from $table";
 
    my $table_data = $dbc->dbh()->prepare($querystring);
    $table_data->execute();

    my $entries=$table_data->rows;
    print h1("$table (Found $entries entries)");

    my %row = %{$table_data->fetchrow_hashref};
    my @field_names = keys %row;
    my @rows = values %row;
    $table_data->finish();

    print &start_admin_form, 
    submit(-name=>'Append Table');
    print hidden(-name=>'TableName',-value=>"$table");
    print "<TABLE border>";
    foreach my $field (@field_names) {
	my $title;
	if ($field =~m/$table[_]/) {
	    $title = $';
	}
	else {$title = $field;}
	if ($title ne 'ID') {
	    print "<TR>";
	    print "<TD width=100 align=center bgcolor=red>";
	    print "$title</TD> <TD>";
	    print textfield(-name=>"F:$field",-size=>20);
	    print "</TD></TR>";
	}
    }

    print "</Table>", p;
    print end_form;
    return;
}

################################################################
# Count number of records in database
################################################################
sub CountRec {

  my $dbc = shift;
  my $table = shift;
  my $sth = $dbc->dbh()->prepare("select * from $table");
  $sth->execute();
  my $npeople  = $sth->rows;
  if($npeople < 0) {$npeople = 0;}
  return $npeople;
}

############################################################

sub Verbose {
    
    if($debug) {print $_[0];}
    return;
}
############################################################

############################################################

sub Execute {
    my $dbc = shift;
    my $command = shift;
#    print "<BR>Command: $command";
#    my $sth = $dbc->prepare("$command");
#    $sth->execute();
#    $sth->finish();
#    my $errmsg = $sth->errstr;
#    print "Errors ?: $errmsg";
    my $try_ok = $dbc->dbh()->do($command);
    if (!defined $try_ok) {Message("Error: ",$DBI::errstr);}
    else {Message("Records Affected: $try_ok", "($DBI::errstr)");}
    return $try_ok;
}

#############################################
############################################################

###############
sub Query {
    my $dbc = shift;
    my $querystring = shift;
    print "<BR>Query: $querystring";
    my $sth = $dbc->dbh()->prepare($querystring);
    $sth->execute();
    my $frecs = $sth->rows();
    my $t0 = new Benchmark;

    $querystring =~ m/from/i;
    my $fields = $`;
    $fields =~ m/select/i;
    $fields = $';
    $fields =~s/[\s ]//;
    
    my $qf=0;
    my $newvalue=0;
    my @col;
    my %row;

    if ($fields =~ /[*]/) {
	my %row = %{$sth->fetchrow_hashref};
	@col = keys %row;
	$qf = scalar(@col);
#	$check=%row->{$col[0]};
    }
    else {
	my $i=0;
	foreach my $field (split /,/,$fields) {
	    $field =~ s/[\s]//;
	    chomp $field;
	    $field =~s/ //;
	    $col[$i] = $field;
	    chomp $col[$i++];
	}
	$qf=$i;
    }
    $sth->execute;  # reload (since if * used, 1st line has already been read)

    print "   ($qf fields)";
    print "<BR><BR>($frecs Records found:)";

    my $colour;
    if ($frecs > 0) {
	print "<Table width=90%><TR bgcolor=red>";
	for (my $i=0;$i<$qf;$i++) {
	    $newvalue=$col[$i];
	    print "<TH>$newvalue</TH>";
	}
	print "</TR>";

	while($ref = $sth->fetchrow_hashref()) {
	#### toggle colours ###
#	if ($colour_on) {$colour=$colour1; $colour_on=0;}
#	else {$colour=$colour2; $colour_on=1;}
	    $colour=&toggle_colour($colour);
	
	print "<TR align=left>";
	for (my $i=0;$i<$qf; $i++) {
	    $newvalue=$ref->{$col[$i]};
	    print "<TD bgcolor=$colour>".$newvalue."</TD>";
	}
	print "</TR>";
	}
	print "</Table>";
    }
    else {print "No records containing $search in Table: $table";}

    my $t1 = new Benchmark;
    my $td = timediff($t1,$t0);
    print "<BR>Search time: " . timestr($td) . "<BR>";
    print "Found $frecs records\n";
    return;
}

############################################################
sub test {

#    my @show = threshold_phred_scores($dbc,20,"where Run_Directory like \"%E3.1\"");
    my @show = threshold_phred_scores($dbc,20,"where Run_ID=32");
    
    foreach my $result (@show) {
	print $result."<BR>";
    }
    return;
}

##########################
sub start_admin_form {
##########################
    my $form = "\n<Form name=$form_name Action='$homefile' Method='POST' enctype='mulitpart/form-data'>";
    
    return $form;
}
