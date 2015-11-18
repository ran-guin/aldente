#!/usr/local/bin/perl
use CGI qw(:standard);
use DBI;
use Benchmark;
use CGI::Carp qw( fatalsToBrowser );

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use alDente::Run; 
use alDente::Web;
use alDente::SDB_Defaults; 

             ## for various Table reading functions...
use SDB::DB_Form_Viewer;  ## this generates some of the HTML views of the Database..
use SDB::CustomSettings;
use SDB::HTML;

use RGTools::RGIO;            ## for the Message() function
use RGTools::HTML_Table;           ## used to generate the HTML tables automatically...
use RGTools::Views;           ## for basic headers etc...

#
# set up standard page template... (from gscweb)
######################################################

use vars qw(@libraries @tables $dbase $homelink);
use vars qw($colour_on_off $testing);

# To run this from your own  cgi-bin/ webspace... simply reset the link below to your 
# file path...

### provide a link back to this page ###
$dbase = param('Database') || "sequence";
$homelink = "http://seq.bcgsc.bc.ca/cgi-bin/rguin/example.pl?Database=$dbase";

print &alDente::Web::Initialize_page();

my $buttonColour = 'lightblue';

my $dbc = DB_Connect(dbase=>$dbase);

if (param('Test Code')) {
    &test_code();
    print &alDente::Web::unInitialize_page();

    exit;
}

print "\n<Form Name='ThisForm' Action='$homelink'>",
    submit(-name=>'Home',-style=>"background-color:$buttonColour"),
    &hspace(10),
    submit(-name=>'Initial Set-up',-style=>"background-color:$buttonColour"),
    &hspace(10);
#
# Use to test code:..
#
#    print &Link_To($homelink,'Test Code','&Test+Code=1','black',['newwin']);
        
print Views::Heading("methods of retrieving data from an SQL database"),
    "<B>Click on any of the buttons below to see a different method of extracting database data</B><BR>",
    submit(-name=>'Using Table_retrieve',-style=>"background-color:$buttonColour"),
    &hspace(10),
    submit(-name=>'Debugging',-style=>"background-color:$buttonColour"),
    &hspace(10),
    submit(-name=>'Table_retrieve_display',-style=>"background-color:$buttonColour"),
    &hspace(10),
    br(),
    submit(-name=>'view_records',-style=>"background-color:$buttonColour"),
    &hspace(10),
    submit(-name=>'mark_records',-style=>"background-color:$buttonColour"),
    &hspace(10),
    submit(-name=>'edit_records',-style=>"background-color:$buttonColour"),
    &hspace(10),
    "</Form>\n";   

&SDB::DB_Form_Viewer::DB_Viewer_Branch(dbc=>$dbc,link=>$homelink);

if (param('Using Table_retrieve')) {
    &example_1();
} elsif (param('Debugging')) {
    &example_2();
} elsif (param('Table_retrieve_display')) {
    &example_3();
} elsif (param('view_records')) {
    &example_4();
} elsif (param('mark_records')) {
    &example_5();
} elsif (param('edit_records')) {
    &example_6();
} else {
    home();
}
print &alDente::Web::unInitialize_page();
exit;

###############
sub home {
###############
#    print &Views::Heading("Examples of Database viewing routines");

    print &Views::Heading("Initial Set-Up");

    print <<HOME;

<PRE>
There are a number of ways of extracting data from the database for viewing on web pages.  

These are a few common routines used to automatically generate a view showing database information, 
many allowing the user to delete or edit data as required.

For all of these commands, a database handle (\$dbc) must first be defined.

This may easily be generated with the command:

    <B>my \$dbc = &SDB::DBIO->new(-dbase=>'sequence');</B>

	(or you could generate this handle yourself)

<HR>

To enable the editing features via buttons on many of these pages, you must include the 'DB_Form_Viewer' module 
and include at the beginning of your code a few lines like:
        <B>## first  provide pointer back to this page...</B>
        <B>\$homelink = "http://seq.bcgsc.bc.ca/cgi-bin/rguin/example.pl?Database=$dbase";  </B> 

	<B>if (&DB_Viewer_Branch(dbc=>\$dbc,link=>\$homelink)) {exit;}</B>

where DB_Viewer_Branch returns true if a branch was found.  

(This checks the parameters passed from various pages and directs code to appropriate routines)
</PRE>
HOME


    return 1;
}

##################
sub example_1 {
##################
#    my $dbc = shift;
    
###############
## SHOW CODE ##
###############
    
    print &Views::Heading("Example using Table_retrieve(\$dbc,\$table_list,\@field_list,\$condition);");
    
    print <<EXAMPLE;
    <PRE>	
    my \$dbc = DB_Connect(dbase=>'sequence');
    my \$tables = 'Solution,Employee,Stock';
    my \@fields = ('Stock_Name','Employee_Name','Solution_Started as Opened','Solution_Status as Status');
    my \$condition = "where Stock.FK_Employee__ID=Employee_ID and FK_Stock__ID=Stock_ID 
           AND Stock_Name like '\$pattern' AND Solution_Started > '2002-01-01'";
    
    my \$pattern = 'Sodium%';
    
    #### this routine retrieves data placing it into a hash...
    my %Info = &SDB::GSDB::Table_retrieve(\$dbc,\$tables,\\\@fields,\$condition); 

    ### and now print out the results...
    
    my \$index=0;
    while (defined %Info->{Stock_Name}[\$index]) {
        print "************** Record \$index: *************\".br();
	print "Name : ". %Info->{Stock_Name}[\$index] . br();
	print "User : ". %Info->{Employee_Name}[\$index] . br();
	print "Open : ". %Info->{Opened}[\$index] . br();	
	print "Stat : ". %Info->{Status}[\$index] . br();
	\$index++;
    }
    
    print "FOUND \$index Records";
    </PRE>
	
EXAMPLE
	    
###############
# EXECUTION #
###############

    print &Views::Heading("Resulting in the following output");
    
    my $sol = "Sodium%";
    my %Info = &SDB::GSDB::Table_retrieve($dbc,'Solution,Employee,Stock',
      ['Stock_Name','Employee_Name','Solution_Started as Opened','Solution_Status as Status'],
      "where Stock.FK_Employee__ID=Employee_ID AND FK_Stock__ID=Stock_ID AND Stock_Name like '$sol' AND Solution_Started > '2002-01-01'"); 
    
    my $index=0;
    while (defined %Info->{Stock_Name}[$index]) {
	print "<BR>**************Record $index:\**************";
	print "<BR> Name : ". %Info->{Stock_Name}[$index];
	print "<BR> User : ". %Info->{Employee_Name}[$index];
	print "<BR> Open : ". %Info->{Opened}[$index];	
	print "<BR> Stat : ". %Info->{Status}[$index];
	print "<BR>";
	$index++;
    }
    print "\nFOUND $index Records\n";
    
    return;
}

###############
sub example_2 {
###############

     print &Views::Heading("Testing/Debugging Queries:");
   
     print <<EXAMPLE2;

<PRE>
To help debug, you may view the queries generated by setting the variable: \$testing.
This variable should be exported as a global (and is checked by GSDB.pm).

If \$testing is true, it will provide various feedback, including generated queries.

    my \$dbc = DB_Connect(dbase=>'sequence');
    my \$tables = 'Solution,Employee,Stock';
    my \@fields = ('Stock_Name','Employee_Name','Solution_Started as Opened','Solution_Status as Status');
    my \$condition = "where Stock.FK_Employee__ID=Employee_ID and FK_Stock__ID=Stock_ID 
           AND Stock_Name like '\$pattern' AND Solution_Started > '2002-01-01'";
    
    my \$pattern = 'Sodium%';
    \$testing = 1;       ### this must be a global variable
    
    #### this routine retrieves data placing it into a hash...
    my %Info = &SDB::GSDB::Table_retrieve(\$dbc,\$tables,\\\@fields,\$condition); 

<B>Note:</B>
- If the \$testing flag is not set, this query generates no output by itself.

</PRE>

EXAMPLE2
   
print &Views::Heading("Output using the testing variable");

    $testing = 1;
    my $pattern = "Sodium%";
    my %Info = &SDB::GSDB::Table_retrieve($dbc,'Solution,Employee,Stock',
      ['Stock_Name','Employee_Name','Solution_Started as Opened','Solution_Status as Status'],
      "where Stock.FK_Employee__ID=Employee_ID AND FK_Stock__ID=Stock_ID AND Stock_Name like '$pattern' AND Solution_Started > '2002-01-01'"); 

     return 1;
} 
 
################
sub example_3 {
################
 
   print &Views::Heading("Example using Table_retrieve_display");

   my $sol = 'Sodium%';
 
      print <<EXAMPLE3;
<PRE>
    my \$dbc = DB_Connect(dbase=>'sequence');
   my \$tables = 'Solution,Employee,Stock';
   my \@fields = ('Stock_Name','Employee_Name','Solution_Started as Opened','Solution_Status as Status');
   my \$condition = "where Stock.FK_Employee__ID=Employee_ID and FK_Stock__ID=Stock_ID and Stock_Name like '\$pattern'";

    my \$pattern = 'Sodium%';
    &Table_retrieve_display(\$dbc,\$tables,\\\@fields,\$condition); 

</PRE>      
EXAMPLE3

    ##############
    ## Method 3 ##
    ##############
    
    print &Views::Heading("Resulting in the output:");

   $testing=1;
    &Table_retrieve_display($dbc,'Solution,Employee,Stock',['Stock_Name','Employee_Name','Solution_Started as Opened','Solution_Status as Status'],"where Stock.FK_Employee__ID=Employee_ID and FK_Stock__ID=Stock_ID and Stock_Name like '$sol'");

      
      return 1;
  }

################
sub example_4 {
################

    ##############
    ## Method 4 ##
    ##############

    print &Views::Heading("view_records: Coding Example");

    print <<EXAMPLE4;
<PRE>
     
    print &SDB::DB_Form_Viewer::view_records(\$dbc,'Stock','Stock_Name','Sodium%');
 
<B>Note:</B>
- Foreign keys are replaced by more informative information
- the FKeys-> field at the far right indicates what other tables reference this record
  (these other references may be viewed directly by clicking on the table)
- A list of fields to view from the table is listed in a Default module.

</PRE>
EXAMPLE4

    print &Views::Heading("Resulting in the output:");

    print &SDB::DB_Form_Viewer::view_records($dbc,'Stock','Stock_Name','Sodium%');
    
    return 1;
}

################
sub example_5 {
################

    ##############
    ## Method 5 ##
    ##############

    print &Views::Heading("mark_records: Coding Example");

    print <<EXAMPLE5;
<PRE>

    my \@fields = ('Stock_Name','FK_Employee__ID');
    my $condition = "where Stock_Name like 'Sodium%'";
    my \$more_buttons = 'Another Button,And Yet Another';

    print &SDB::DB_Form_Viewer::mark_records(\$dbc,'Stock',\\\@fields,\$condition,\$more_buttons);

<B>Note:</B>
- the FK_Employee__ID field is REPLACED with data from that table
   (what is displayed in place of foreign keys is defined in a defaults module) 
- the addition of the other requested buttons for the page (optional).

</PRE>
EXAMPLE5

    print &Views::Heading("Resulting in the output:");

    print &SDB::DB_Form_Viewer::mark_records($dbc,'Stock',['Stock_Name','FK_Employee__ID'],"where Stock_Name like 'Sodium%'",'Another Button,And Yet Another');
    
    return 1;
}

################
sub example_6 {
################

    ##############
    ## Method 6 ##
    ##############

    print &Views::Heading("edit_records: Coding Example");
    print <<EXAMPLE6;
<PRE>

    print &SDB::DB_Form_Viewer::edit_records(\$dbc,'Stock',
       'Stock_Name',"Sodium%");

<B>Note:</B>
  The fields to be displayed are set within the defaults module.
      (if unspecified, all fields are displayed)..
 

</PRE>
EXAMPLE6

    print &Views::Heading("Resulting in the output:");
 
    print &SDB::DB_Form_Viewer::edit_records($dbc,'Stock','Stock_Name',"Sodium%");
     
    return 1;
}

################
sub test_code {
################

    Message("This routine is used to test code");
   

    print 'Try  &Table_retrieve_display($dbc,\'Employee\',[\'Employee_Name\',\'Initials as Init\'],\"where Employee_Name like \'S%\'\");<P>';

    $testing=1;
    
    my %test_return = &Table_retrieve_display($dbcy,'Employee',['Employee_Name','Initials as Init'],"where Employee_Name like 'S%'");
    $testing=0;

   return 1;
}
