#!/usr/local/bin/perl

################################################################################
# DB_admin.pl
#
#  This is a simple database administrator front end
#
################################################################################

################################################################################
# $Id: DB_admin.pl,v 1.32 2004/10/27 18:26:08 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.32 $
#     CVS Date: $Date: 2004/10/27 18:26:08 $
################################################################################
#

use CGI qw(:standard);
use DBI;
use Benchmark;
use CGI::Carp qw( fatalsToBrowser );

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::Barcode;

use alDente::SDB_Defaults;
use alDente::Web;
use SDB::DB_Form_Viewer;
use SDB::DBIO;
use SDB::CustomSettings;      ### exports common variables...
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
#
# set up standard page template... (from gscweb)
######################################################

use vars qw(@libraries @tables $dbase $homelink $URL_temp_dir $html_header);
use vars qw($colour_on_off $q %Settings $testing $user $user_id $Connection %Field_Info $dbc);

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

my @dbases = param('Database');
$dbase = param('Database') || $Configs{DATABASE};

$host = param('Host') || $Configs{SQL_HOST};  ## ignore param('Host')
$q = new CGI;

#Initialize_page();

$homefile = $0;  ##### a pointer back to the executable file
if ( $homefile =~ m|/([\w_]+[.pl]{0,3})$| ) {
    $homefile = "$alDente::SDB_Defaults::URL_address/$1";
}
elsif ($homefile =~ m|/([\w_]+)$| ) {
    $homefile = "$alDente::SDB_Defaults::URL_address/$1";
}

my $user = param('User');
my $user_parameter;
if ($user) {$user_parameter = "&User=$user";}

$homelink = "$homefile?Database=$dbase&Host=$host$user_parameter";

#######################################################

my $feedback = 0;
$style = "html";

my $colour1 = "lightblue";
my $colour2 = "whitesmoke";
my $colour;
my $colour_on;

my $debug = 0;

unless ($dbase) {
    &home();
    &leave();
}

## Connect to slave host/dbase if using for read only purposes ##
my $db_user = 'lab_user';
my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $db_user, -config=>$configs);
$dbc->connect();

print LampLite::HTML::initialize_page( -path => "/$path", -css_files => $css_files, -js_files => $js_files, -min_width => $min_width );    ## generate Content-type , body tags, load css & js files ... ##
print $BS->open();

unless ($dbc && $dbc->ping()) { print "No database connection for $user on $host:$dbase."; &leave(); } 

@tables = $dbc->tables();

### Custom retrieve global libraries ###

my $left_nav = 0;
if ($dbc) {
    $left_nav = 1;
    Left_Nav_Bar($dbc);
    if (grep /^Library$/, @tables) {
	@libraries = &Table_find($dbc,'Library','Library_Name');
    }
} else { print "Database not connected";}

if (param('TableHome')) {
    my $table = param('TableHome');
    TableHome($dbc,$table);
    &leave();
} elsif (param('Log In')) {
    unless ($dbc) {print "DB connection failed"; }
}

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

%Field_Info = initialize_field_info($dbc);

if ( SDB::DB_Form_Viewer::DB_Viewer_Branch(-dbc=>$dbc,user=>$user) ) {
   #  &leave();
}

########## Generic Search / Edit functions ################

if (param('Search for')) {	   
    my $table = param('Table');
    Table_search(-dbc=>$dbc,-tables=>$table);
}
elsif (param('Search')) {	   
    my $table = param('Table');
    Table_search_edit($dbc,$table);
}
elsif (param('Next Page') || param('Previous Page')) {
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
    my $test = param('Test Only');
    &perform_parse($dbc,$table,$file,$test);
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
    &home;
}
elsif (param('Add Table')) {
    print h1("Adding Table");
    Table_add($dbc,param('TableName'),param('fields'));
}
elsif (param('Drop Table')) {
    my $table=param('TableName');
    print h1("Dropped Table: \"$table\"");
    Table_drop($dbc,$table);
    &home;
}
elsif (param('Edit Table')) {
    print h2("Table Editor");
    &SDB::DB_Form_Viewer::info_view($dbc,param('TableName'),param('View Fields'),undef,undef,param('Conditions'));
}
elsif (param('View Table')) {
    print h2("Viewing Table");
    print &SDB::DB_Form_Viewer::view_records($dbc,param('TableName'),param('View Fields'),param('Conditions'));
}
#elsif (param('Show Table Details')) {
#    print h2("Table Information");
#    show_table($dbc,param('TableName'));
#}
#elsif (param('Show Table Settings')) {
#    print h2("Table Information");
#    show_table($dbc,param('TableName'));
#}
elsif (param('Simple View')) {
    my $table = param('Simple View');
    show_table($dbc,$table,'simple');
} elsif (param('Fields')) {
    my $table = param('Fields');
    &TableHome($dbc,$table);
}
#elsif (param('Standard View')) {
#    my $table = param('Standard View');
#    show_table($dbc,$table,'standard');
#}
#elsif (param('Detailed View')) {
#    my $table = param('Detailed View');
#    show_table($dbc,$table,'detailed');
#}
elsif (param('Tree')) {
    print h2("Table Tree Structure");
    my $multilevel = 1;
    print SDB::DB_Form_Viewer::Table_Tree($dbc,param('TableName'),$multilevel=>$multilevel);
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
    print h2("Table List");
    if (param('Show Fields')) {
	&list_tables($dbc);
    }
    else {
	&list_tables($dbc);
    }
}
elsif (param('Show_DBTable')) {
    &show_dbtable($dbc);
}
#######################
#  Data Dumping 
#######################
elsif (param('DB Data Dump')) {
    my $tablelist = param('TableList');
    print h1("Dumping Tables: $tablelist");
    DB_Archive(dbase=>$dbase,tables=>$tablelist,include_data=>1);
}
elsif (param('DB Structure Dump')) {
    my $tablelist = param('TableList');
     my $options = param('Options');
    print h1("Dumping Structure");
    DB_Archive(dbase=>$dbase,tables=>$tablelist);
}
elsif (param('Add Record')) {
    print h1("Add record");
    &SDB::DB_Form_Viewer::add_record($dbc,param('TableName'));
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
    &home;
}
elsif (param('Execute')) {
    print h1("Execute command");
    Execute($dbc,param('command'));
    &home;
}
elsif (param('Dump')) {
    print h1("Execute & Dump command");
    if (param('To File')) {
	Query_Dump_File($dbc,param('dcommand'),param('To File'));
    }
    else {Query_Dump_HTML($dbc,param('dcommand'));}
}
elsif (param('Query')) {
    print h1("Query Results");
    Query($dbc,param('querystring'));
#    &home;
}
else {&home;}

&leave();

sub leave {
     print $BS->close(); ## &alDente::Web::unInitialize_page();
    exit;
}
#########################################################################
##############
sub home {
##############
    
#    my $dbc = DB_Connect(dbase=>'sequence');
 #   my @drivers = DBI->available_drivers(1);
 #   foreach my $driver (@drivers) {
#	my @databases = DBI->data_sources($driver);
#	print "$driver: @databases<BR>";
#    }

#    my @databases = DB_Query->data_sources('mysql');
#    $dbc->disconnect();

    my @databases = ('sequence','seqdev','seqlast','seqtest','seqmed','sequenceDB');
    my @hosts = ('lims01','lims02','athena','nmemosyne','lims02-sqlnet');

    if ($user) {print "User: $user";}

#    Message("You must log in to have access to a database");
#
#    print start_form(-action=>$homelink), 
#    &RGTools::Views::Heading("Database Editor: $dbase"), &vspace(20),
#    submit(-name=>'Log In',-style=>"background-color:$Settings{STD_BUTTON_COLOUR}"),
#    &hspace(20), "As: ", textfield(-name=>'User',-size=>10,-default=>$user,-force=>1), &hspace(20),
#    "Password: ", password_field(-name=>'Password',-size=>10,-default=>$password,-force=>1), &vspace(10);
    
    #Get a list of parameters from previous page and then create a hidden field that contains their value for each paramter.
    my @params = param();
    foreach my $param (@params) {
	if (param($param)) {
	    print hidden(-name=>$param,-value=>param($param));
	}
    }
    
#    print submit(-name=>'Home',-value=>'Change Database',-style=>"background-color:$Settings{STD_BUTTON_COLOUR}"), hspace(20),
#    submit(-name=>'List Tables',-style=>"background-color:yellow"), 
#    checkbox(-name=>'Show Fields'),&vspace(10),
    popup_menu(-name=>'Database',-values=>[@databases],-default=>$dbase),
    &hspace(10).
    popup_menu(-name=>'Host',-values=>[@hosts],-default=>$dbase),
    end_form;

#    print start_form, 
#    submit(-name=>'Create Table'),textfield(-name=>'TableName'),
#    " with ", textfield(-name=>'fields',-value=>'2', size=>5), 
#   " Fields", &hspace(10),    
#    end_form;

    print "<HR>";

    if ($dbc && $dbc->ping()) {
	my @types = &Table_find($dbc,'DBTable','DBTable_Type',undef,'Distinct');
	print "Types of Data Tables or Entities:";
	print "<ul>";
	foreach my $type (@types) {
	    unless ($type) { next }
	    my $padded_type = $type;
	    $padded_type=~s/\s+/\+/g;
	    print '<LI><span class=small>' . &Link_To($homelink,$type,"&Type=$padded_type") . '</span>'; 
	}
	print "</uL>";
	
	if (param('Type')) {
	    my $type = param('Type');
	    my $unpadded_type = $type;
	    $unpadded_type=~s/\+/ /g;
	    
	    my @tables = &Table_find_array($dbc,'DBTable',['DBTable_Name as Table_Name','DBTable_Description as Description'],"where DBTable_Type = '$type' Order by DBTable_Type,DBTable_Name");
	    my $Tables = HTML_Table->new(-autosort=>1);
	    $Tables->Set_Title("$unpadded_type Entities represented by Tables");
	    $Tables->Set_Headers(['Table','Description']);
	    $Tables->Set_Class('small');
	    foreach my $table (@tables) {
		if ($table=~/(.+?),(.*)/) {
		    my $name =  $1;
		    my $desc = $2;
		    $Tables->Set_Row([&Link_To($homelink,$1,"&TableHome=$name",undef,['newwin']),$desc],);
		}
	    }
	    $Tables->Printout();
	    $Tables->Printout("$URL_temp_dir/$type"."_Tables.html");
	}
    }
    #  print start_form(-action=>$homelink),
 #   "<Table cellspacing=10 cellpadding=10><TR><TD>",    
 #   submit(-name=>'Execute',-style=>"background-color:red"),"</TD><TD>", 
 #   textarea(-name=>'command',-rows=>2,-cols=>60),"</TD></TR><TR><TD>",
 #   submit(-name=>'Query',-style=>"background-color:yellow"), "</TD><TD>", 
 #   textfield(-name=>'querystring',-size=>60), "</TD></TR><TR><TD>", 
 #   submit(-name=>'Dump',-style=>"background-color:lightblue"), "<p>to file:","</TD><TD>", 
 #   textfield(-name=>'dcommand',-size=>60), "<p>", 
 #   textfield(-name=>'To File',-size=>40), " (defaults to screen)", "</TD></TR></Table>", 
 #   end_form;

    return;
}

####################################################################
sub show_table {  #
###################

    my $dbc = shift;
    my $table = shift;
    my $view = shift;
    
    &TableHeader($dbc,$table);
    print &vspace(5);

    my $condition = "DBTable_Name = '$table' and Field_Options NOT LIKE '%Hidden%' Order by Field_Order";
    my @fields;

    if ($view =~/simple/i) {  ## only show Field names for simple view ##
	@fields = ('Field_Name');
    } elsif ($view=~/detail/i) {                 ## otherwise show all defined Field_Info columns ##
	@fields = ('Field_Order as _Order','Field_Description as Description','Prompt','Field_Name as Field_Name','Field_Type as Type','Field_Options as Options','Foreign_Key');
    } else {
	@fields = ('Field_Order as _Order','Prompt','Field_Name as Field_Name','Field_Type as Type','Foreign_Key');
    }

    my %Info = &Table_retrieve($dbc,'DBField,DBTable',\@fields,
				"where DBTable_ID=FK_DBTable__ID AND $condition");
    
#    my  %Info = &Table_retrieve($dbc,'DBField,DBTable',[@headers],"where DBTable_ID=FK_DBTable__ID AND DBTable_Name = '$table' and Field_Options NOT LIKE '%Hidden%'");

    my @headers = map {
	my $field = $_;
	if ($field=~/(.*) as (.*)/) { $_ =$2 }
	else {$_ = $field }  
    } @fields;
    
    my $Show = HTML_Table->new(-autosort=>1);
    $Show->Set_Title("$table Fields");
    $Show->Set_Headers(\@headers);
    $Show->Set_Class('small');
    $Show->Set_Border(1);

    my $index=0;
    while (defined %Info->{Field_Name}[$index])  {
	my @row;
	foreach my $field (@headers) {
	    my $value = %Info->{$field}[$index];
	    if ($field =~ /Prompt/i) { $value = "<B>$value</B>" }
	    if ($field =~ /Foreign_Key/i) { 
		if ($value=~/(.*)\.(.*)/) { 
		    $reftable =  $1;
		}
		$value = &Link_To($homelink,$value,"&Standard+View=$reftable"); 
	    }
	    push(@row,$value);
	}
	$Show->Set_Row(\@row);
	$index++;
    }
    $Show->Printout();

    return;

#    my @fields = get_fields($dbc,$table);
#    my @fields = keys %{%Field_Info{$table}};
	my @headers;

    (my $records) = &Table_find($dbc,$table,'count(*)');
    
    print "<Table border=1><TR>";
    foreach my $header (@headers) {
	print "<TD bgcolor=lightblue>$header</TD>";
    }
    print "</TR>";

    my $row=0;
    foreach my $field (@headers) {
	print "<TR>";
	foreach my $header (@headers) {
	    $value = %Info->{$field}->{$field}->{$header} || '-';
	    print "<TD bgcolor=lightyellow>$value</TD>";
	}
	$row++;
	print "</TR>";
    }
    print "</Table>";

    return;
}

#####################
sub showDBTableInfo {
#####################
    my $dbc = shift;
    my $table = shift;
       
    my ($table_id) = &Table_find($dbc,'DBTable','DBTable_ID',"where DBTable_Name='$table'");
    print &SDB::DB_Form_Viewer::view_records($dbc,'DBTable',undef,"DBTable_ID=$table_id");    
    
    print &SDB::DB_Form_Viewer::view_records($dbc,'DBField',undef,"FK_DBTable__ID=$table_id");
    
    return;
}

##########################################################################
sub define_table {   #
######################
    my $dbc = shift;
    my $table = shift; 
    my $fields = shift;
    if ($fields=~/(\d+)/) {$fields=$1;}
    my @types=('INT','REAL','TEXT','Char(40)','LONGTEXT','Date','DateTime');
    
    print "<TABLE width = 90%>";
    print h1("Adding Table: $table with $fields fields");
    print start_form(-action=>$homelink), 
    hidden(-name=>'Database',-value=>$dbase),
    hidden(-name=>'User',-value=>$user),
    hidden(-name=>'TableName',-value=>"$table"),
    hidden(-name=>'DB',-value=>"$dbc");
    for (my $i=0; $i<$fields; $i++) {
	print "<TR><TD align=right>";
	print "Field Name:","</TD><TD>",textfield(-name=>"field$i"), "</TD><TD align=right>"; 
	print "Type:","</TD><TD>",popup_menu(-name=>"type$i",value=>[@types],-default=>'TEXT');
	print "</TD><TD>",checkbox(-name=>'Primary');
	print "</TD><TD>",checkbox(-name=>'Auto-increment');
	print "</TD>", p;
    }    
    print submit(-name=>'Construct Table');
    print end_form;
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
	elsif (/^Primary/) {
	    $fieldnames .= " PRIMARY KEY";
	    $fieldnames .= " NOT NULL";
	}
	elsif (/^Auto/) {
	    $fieldnames .= " AUTO_INCREMENT";
	}    
    }
#    chop $fieldnames;

    print "<BR>Creating table:  $table with $fields fields<BR>$fieldnames.";
    Table_add($db,$table,$fieldnames);
    
    initialize_table($db,$table,$fields);
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

    print start_form(-action=>$homelink), 
    hidden(-name=>'Database',-value=>$dbase),
    hidden(-name=>'User',-value=>$user),
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

################
sub Execute {
################
    my $dbc = shift;
    my $command = shift;
    my $try_ok = $dbc->dbh()->do($command);
    if (!defined $try_ok) {Message("Errors: ",$DBI::errstr);}
    else {Message("Records Affected: $try_ok", "($DBI::errstr)");}
    return $try_ok;
}

#############################################
############################################################

###############
sub Query {
###############
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

######################
 sub perform_parse {
######################
# 
# handles data from 'parse_to_table' routine
#
#
    my $dbc = shift;
    my $table = shift;
    my $file = shift;
    my $test = shift;

    if ($test) { $test = "-t" } 

#    my @positions = param(Field Position);

    my @Clist;  ## Column List;
    my @Flist;  ## Field List;
    my @Slist;  ## Static List;
    my @Svalues; ## Static Values;
    foreach my $name (param()) {
	my $value = param($name);
	if (($name=~/FP:(.*)/) && $value=~/\S/) {
	    $value= sprintf "%2d", $value;
	    $value =~s / /0/g;
	    push (@Clist,$value);
	}
	elsif ($value=~/\S/ && ($name=~/Fix:(.*)/)) {
	    my $field = $1;
	    push (@Slist,$field);
	    my $type = &get_fields($dbc,$table,$field);
	    push (@Svalues,qq{$value});
	}
    }

    @Clist = sort @Clist;

    foreach my $col (@Clist) {
	$col = $col+0;
	foreach my $name (param()) {
	    my $value = param($name);
	    if (($name=~/FP:(.*)/) && $value == $col) {
		push (@Flist,$1);
	    }
	}
    }

    my $Static_list;
    my $Static_values;
    my $Static;
    if ($Svalues[0]) {
	$Static_list = join ',',@Slist;
	$Static_list =~s / //g;	
	$Static_values = join ',',@Svalues;
	$Static = "-S $Static_list -V $Static_values";
    }	    

    my $Flisted = join ',',@Flist;
    my $Clisted = join ',',@Clist;
    my $header = param('Header Lines');

    print "\n*** Retrieving: $Clisted = $Flisted\n";

    my $command = "$bin_home/parse_table.pl -c $Clisted -f $file -h $header -T $table -F $Flisted -D $dbase $Static $test";
    print $command;
    my $fback;
    $fback = try_system_command($command);
    print "<PRE>\n";
    print $fback;
    print "</PRE>";

    return 1;
}

#####################
sub Left_Nav_Bar {
#####################
    my $dbc = shift;
    my $type = shift || 'Database';

    my $left_frame_colour = "'bbbbbb'";

    print "<Table width=100% cellpadding=10 cellspacing=0><TR>".
	"<TD valign=top bgcolor=$left_frame_colour width=150>";

    print start_form(-action=>$homelink);

    print "<Table bgcolor=$left_frame_colour>";
    print "<Font size=-1>";
 
    print "$user<BR>";
    print &Link_To("$homelink$user_parameter","Home",undef,'red') . &vspace(10);        

    if ($type eq 'Database') {
	print "<B>$host:$dbase</B><BR>($#tables Tables):<P>";
	foreach my $table (@tables) {
	    print '<TR><TD><Font size=-1>'.
		&Link_To("$homelink",$table,"&TableHome=$table",'blue').
		    '</Font></TD></TR>';
	}
    }    
    print "</Font>";
    print "</Table>";
    
    print '</Form>';
    
    print "</TD><TD valign=top cellpadding=0 bgcolor=$home_background>";
    return;
}

#############################
sub Close_Left_Nav_Bar {
#############################
    print "</TD></TR></Table>";
    return;
}

##################
sub TableHeader {
##################
    my $dbc = shift;
    my $table = shift;

    if ($user) {print "User: $user" . &vspace(10);}

    print &Views::sub_Heading("$table",1);

    print "<Font size=-1>";
    print &vspace(5).
	&Link_To($homelink,"Simple","&Simple+View=$table"),
	&hspace(10).
#	&Link_To($homelink,"Standard","&Standard+View=$table"),
#	&hspace(10).
	    &Link_To($homelink,"Fields","&Fields=$table"),
	    &hspace(10).
		&Link_To($homelink,"Append","&New+Entry=New+$table"),
		&hspace(10).
		    &Link_To($homelink,"Search","&Search+for=1&TableName=$table"),
		    &hspace(10).
			&Link_To($homelink,"View","&Info=1&TableName=$table"),
			&hspace(10);
   
    if ($user eq 'Admin') {
	print &Link_To($homelink,"Edit","&Edit+Table=$table"),
	&hspace(30);
    }
    
    print &Link_To($homelink,"Local_Relationships","&Tree=1&TableName=$table");
    
    print "</font>";
    my ($desc) = &Table_find($dbc,'DBTable','DBTable_Description',"where DBTable_Name = '$table'");
    if ($desc =~ /[a-zA-Z]/) {
	print "<P><B>$table</B> Table: $desc<P>";
    } else { print '<P>' }
    
    return ;
}

##################
sub TableHome {
##################
    my $dbc = shift;
    my $table = shift;
    &TableHeader($dbc,$table);

    &list_tables($dbc,$table);
    
#    showDBTableInfo($dbc,$table);
 
    print &vspace(10);
    
    print &Views::sub_Heading("Foreign Keys",1);

    my @foreign_keys = &get_fields($dbc,undef,"FK%$table%");
    
    print "<UL>";
    my $FKeys = 0;
    foreach my $this_key (@foreign_keys) {
	if ($this_key=~/(.*)\.FK([a-zA-Z0-9]*)_$table[_]{2}(.*)/) {
	    (my $f_table,my $f_key,my $f_field) = ($1,"FK$2"."_$table"."__$3",$3);
	    print "<LI>" .
		&Link_To($homelink,"$f_table -> $f_key","&TableHome=$f_table");
	    $FKeys++;
	}
    }
    print "</UL>";
    unless ($FKeys) { print "(No Tables point to this table)"; }

    print &vspace(10);

    print &Views::sub_Heading("Special Options",1);

    print start_form(-action=>$homelink),
    hidden(-name=>'Database',-value=>$dbase),
    hidden(-name=>'User',-value=>$user),
    submit(-name=>'Parse',-value=>'Parse from File',-style=>"background-color:lightblue"), 
    &hspace(5),
    textfield(-name=>'FileName',-size=>20),&vspace(10),
    submit(-name=>'Dump to file',-value=>'Dump Table Contents to File :',-style=>"background-color:lightblue"),
    &hspace(5),
    textfield(-name=>'Dumpfile',-size=>20),
    "<HR>",    
    "</Form>";

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

##########################################################################
sub show_dbtable {     # Display the DBTable records.
########################
    my $dbc = shift;
    my $table = HTML_Table->new(-autosort=>1);
    $table->Set_Class('small');
    $table->Set_Title('Tables of the '.param('Database').' database');
    $table->Set_Headers(['Table Name','Table Description','Table Status','Status Last Updated','Number of Records','Indices (key(column))']);

    my %info = &Table_retrieve($dbc,param('Database').'DB.DBTable',['DBTable_Name','DBTable_Description','DBTable_Status','Status_Last_Updated'],"order by DBTable_Name");

    my $index=0;
    while (defined %info->{DBTable_Name}[$index]) {
	my $name = %info->{DBTable_Name}[$index];
	my $desc = %info->{DBTable_Description}[$index];
	my $status = %info->{DBTable_Status}[$index];
	my $updated = %info->{Status_Last_Updated}[$index];
	(my $count) = &Table_find($dbc,$name,'count(*)');

	#Now get the indices
	my $sth = $dbc->dbh()->prepare(qq{show index from $name});
	$sth->execute();
	my @indices = ();
	while(my $row = $sth->fetchrow_arrayref) {
	    for (my $i = 0; $i < @{$row}; $i++) {
		#only interested in the Key_Name and Column_Name info for now.
		unless ($i == 2 || $i == 4) {next;}
		push(@indices, $row->[$i]);
	    }
	}

	#Generate a semicolon-delimited list of the indices.
	my $indices = "";
	my $i;	
	while (defined $indices[$i]) {
	    if ($i % 2 ==0) {
		$indices .= $indices[$i];
	    }
	    else { 
		$indices .= "($indices[$i])<br>";
	    }
	    $i++;
	}
		
	$sth->finish();
	
	$table->Set_Row([$name,$desc,$status,$updated,$count,$indices]);

	$index++;
    }

    $table->Printout(-file=>"$URL_temp_dir/query.$timestamp.html",-header=>$html_header);
    $table->Printout();
    #&Link_To("$homelink&Password=".param('Password')."&Database=".param('Database')."&Host=".param('Host')."&Show_Indices=1&Table=".%info->{DBTable_Name}[$index],'View indices',undef,'blue',['newwin'])
    #&Table_retrieve_display($dbc,'DBTable',['DBTable_Name','DBTable_Description','DBTable_Status'],"order by DBTable_Name");
    return;
}
