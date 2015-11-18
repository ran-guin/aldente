#!/usr/local/bin/perl

###############################
#
# Table_man.pl
#
# This program is the home page for the lab interface to the Sequencing Database
#
# It is designed to utilized barcoded lab objects to track all stages
# involved in Sequencing.
#
# (Creation, Movement, Use of Plates, Solutions, Equipment etc)
#
# There are various modes allowed which adjust the look of the output:
#
# 'scanner_mode' is a flag to indicate that output is to be sent to a barcode scanner
#  (this mode is less interactive, and the display is kept concise)
#
# a 'testing' flag is used for code testing to generate more verbose output.
#
#
#################################################################################

use CGI qw(:standard);
use DBI;
use Benchmark;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use Date::Calc qw(Day_of_Week);
use GD;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use alDente::SDB_Defaults;
use alDente::Web;
use RGTools::HTML_Table;
use RGTools::Views;
use RGTools::RGIO; 

 

print &alDente::Web::Initialize_page();

if (param('Example')) {
    (my $type) = param('Example');
    if ($type=~/Table_find/) {
	print <<EX1;

<PRE>

<B>SIMPLE EXAMPLE:</B>

my \@employees = Table_find_array(\$dbc,'Employee','Employee_Name');

generates an array of employee names:

eg. ('Duane','Jeff','George','Carrie',...)


<B>MORE COMPLICATED:</B> 
    
my \@info = Table_find_array(\$dbc,'Solution,Stock',
	['Stock_Name',"concat(Solution_Number,' of ',Solution_Number_in_Batch)"],
	"where FK_Stock__ID=Stock_ID AND Stock_Name like 'Sodium%'");
	
... resulting in something like:
("Sodium Chloride,1 of 3","Sodium Chloride,2 of 3",...);


Generally results can be quickly parsed out with code like:

    foreach my \$details (\@info) {
	(my \$name,my \$bottle) = split ',',\$details;
	...
    }

</PRE>

EX1
}	
    elsif ($type=~/Table_retrieve$/) {
	print <<EX2;

<PRE>

<B>SIMPLE EXAMPLE:</B>


my %employees = Table_retrieve(\$dbc,'Employee',['Employee_Name']);

generates an array of employee names:

    %employees->{Employee_Name}[0] = 'Duane'
    %employees->{Employee_Name}[1] = 'Jeff' ...etc
    

<B>MORE COMPLICATED:</B> 
    
my \%info = Table_retreive(\$dbc,'Solution,Stock',
	['Stock_Name as Name',"concat(Solution_Number,' of ',Solution_Number_in_Batch) <B> as Bottle</B>"],
	"where FK_Stock__ID=Stock_ID AND Stock_Name like 'Sodium%'");
	
... resulting in something like:

    %info->{Name}[0] = 'Sodium Chloride',
    %info->{Bottle}[0] = '1 of 3',
    %info->{Name}[1] = 'Sodium Chloride',
    %info->{Bottle}[1] = '2 of 3',
    ... etc.

</PRE>

EX2
}
elsif ($type=~/Table_retrieve_display/) {
	
print <<EX3;

<PRE>

This generates an HTML table showing the results of the search
(results have been limited to 5 records)...    

my %info = Table_retreive(\$dbc,'Solution,Stock',
	['Solution_ID as ID','Stock_Name as Name',"concat(Solution_Number,' of ',Solution_Number_in_Batch) <B> as Bottle </B>"],
	"where FK_Stock__ID=Stock_ID AND Stock_Name like 'Sodium%' LIMIT 5");
	
... resulting in something like:

</PRE>

EX3
    my $dbc = SDB::DBIO->new(dbase=>'sequence',-connect=>0);
    $dbc->connect();

    $dbc->Table_retrieve_display('Solution,Stock',['Solution_ID','Stock_Name as Name',"concat(Solution_Number,' of ',Solution_Number_in_Batch) as Bottle"],"where FK_Stock__ID=Stock_ID AND Stock_Name like 'Sodium%' and Stock_ID > 1000 LIMIT 5");

}
    elsif ($type=~/Table_append/) {
print <<EX4;

<PRE>

This appends the database with the given record...
(<B>If there is an auto_increment ID field in the Table, it returns this value</B>)
- otherwise it returns the number of records added. (1 if successful) 

    my \$new_id = Table_append_array(\$dbc,'Employee',
		['Employee_Name','Initials','Position'],
		['Richie Valens','RV','Teen Rock Star']);

or...

    my \@fields = ('FK_Employee__Name','Initials','Email_Address');
    my \@values = (5,'JFK','jfk@pentagon.com');

    my $new_id = Table_append_array(\$dbc,'Employee',\\\@fields,\\\@vallues);
                 

</PRE>

EX4
   
}
    elsif ($type=~/Table_update/) {
print <<EX4;

<PRE>

This updates the database as specified,
returning the number of changed records. 
    
    my \@fields = ('Run_Status','Run_State','Sequence_DateTime');
    my \@values = ('Production','Analyzed','2002-02-02');


    my \$updated = Table_update_array(\$dbc,'Run',\\\@fields,\\\@values,
	        "where Run_ID = 12345",-autoquote=>1);

NOTE:  the autoquote flag is used so that you do not have to worry
       about putting text fields (or date fields) in quotation marks,
       and should generally be used.
      
    The autoquote flag would NOT be used in the following however:

    my \$updated = Table_update_array(\$dbc,'Stock',
		['Stock_Name'],
		["concat('Stock: ',Stock_Name)"],
	        "where Stock_Name like 'H2O%'");


</PRE>

EX4
    }
    elsif ($type=~/delete_records/) {
print <<EX4;
<PRE>

This deletes a multiple records as specified in a list...

    my \$deleted = delete_record(\$dbc,'Employee','Employee_ID','1,2,3,4,5');

(deleting the Employee's with ID's: 1,2,3,4,and 5)

</PRE>
EX4
}
elsif ($type=~/delete_record/) {
print <<EX4;
<PRE>

This deletes <B>a single record</B> as specified...

    my \$deleted = delete_record(\$dbc,'Employee','Employee_Name','Richie Valens');

(It may also be used to replace foreign keys to deleted records with pointers to another record).

    my \$deleted = delete_record(\$dbc,'Organization','Organization_ID',55,66);

will delete Organization number 55, and replace all references to Organization 55 with references to Organization 66 instead.

This is useful if it is realized that two records represent the same entity
(eg. a company with more than one entry in the database due to slightly different naming conventions or typos):

Fisher Chemical, Fisher Chem, Fisher, Fischer 

</PRE>
EX4
}
    elsif ($type=~/Table_copy/) {
print <<EX5;
<PRE>

This copies records as per condition specified.

    ### Do NOT copy the Orders_ID field (it is unique - a primary key)
    ### Do NOT copy these other fields as they are bound to be different for a new order
    my \@exceptions = ('Orders_ID','Orders_Received_Date','Orders_Status','PO_Date');
    my \$datefield = "Req_Date";  ## replace this field with the current date time...

    my \$copied = Table_copy(\$dbc,'Orders',"where Orders_ID in (\$select_list)",\\\@exceptions,\$datefield);

<B>Note:</B>
- if you know for instance that you wish to set one of the exception fields to, you may specify another parameter.

eg my \@replacements = (NULL,'2002-02-02',NULL,NULL); 
 (setting Orders_Receieved_Date to '2002-02-02' for all of the above copied orders)

</PRE>
EX5
}
else {Message("Nothing found for $type");}

print &alDente::Web::unInitialize_page();
exit;
}


print &Views::Heading("Using the GSDB.pm Module to edit the Sequencing Database");

    
print &Views::sub_Heading("Preparing to use the module");

print <<GSDB;
 
To use the GSDB.pm module you should include a few lines at the start of your code:
<P>
<PRE>
use lib '/usr/local/ulib/prod/alDente/lib/perl/'; ## find local module directory
                                     ## the module...
use SDB::DBIO;                                   ## (only needed if DB_Connect is used)
</PRE>
<P>
You will also need a database handle which you can generate easily using the command:
<BR>
<B>my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>$login_name,-password=>$login_pass);
<BR>$dbc->connect();
</B><BR>
(or connecting yourself and generating a database handle $dbc).

GSDB

print &Views::sub_Heading("Why Bother using this Module");

print <<WHY;

<h3>Foreign Key implementation in mySQL</H3><P>
the use of mySQL as a database is unique in that it does not provide automatic handling of foreign key relationships. This means that the data, which is separated into numerous 'Tables' representing unique types of data, is not inherently interconnected. Rather, the connectivity between the tables is handled specifically by programmers. While this at first may seem rather burdensome, it offers the advantage of a much faster response time (due to decreased overhead).
<P>
The disadvantage is that the relationships must be handled specifically by the developers. Once a set of routines are developed to accomplish this, however, there is not much additional work required by programmers.
<P>
If this is to work effectively, there are three particular areas in which it is crucial that Database updating passes through these custom handling protocols:
<UL>
<LI>Appending the database - to ensure that invalid data does not get added to the database<BR>
      eg. setting a foreign key to a record that does not exist.
<li>Editing the database - to ensure that valid data does not become invalid (as above) through changes.
<LI>Deleting from the database - to ensure that invalid data is not created by the deletion of records which are referenced by other tables
</UL>

<P>
To ensure that all of the above procedures are checked carefully before making changes to the database,
ALL 'Insert','Update', or 'Delete' commands should be accomplished via the routines:
<UL>
<LI>Table_append
<LI>Table_update_array
<LI>delete_record(s)
</UL>
<P>
Some of things that are done during any database edits include:
<UL>
    <LI> Check User permissions (if $user_id variable set to Employee_ID)
    <LI> Check to ensure references to foreign keys point to existing records
    <LI> Ensure Mandatory fields are filled in
    <LI> Ensure Unique fields are not repeated
    <LI> Ensure that records that are pointed to by other tables are not deleted
    <LI> Generate informative messages where failures occur.
    <LI> Convert date formats to more readable versions<BR>
(2001-01-01 becomes 'Jan-01-2001' via data retrieval commands)
</UL>
<P>
Notes: - for Debugging purposes, the queries generated are displayed if the global variable: '$testing' is set to 1. - to utilize user permission checking, you should have a global variable: $user_id set (The value of which is the Employee_ID of the user wishing to make the change) 

<HR>

WHY

my $find_link = &Link_To('Table_man.pl','Table_find_array example','?Example=Table_find','black',['newwindow']);
my $retrieve_link = &Link_To('Table_man.pl','Table_retrieve example','?Example=Table_retrieve','black',['newwindow']);
my $retrieve_display_link = &Link_To('Table_man.pl','Table_retrieve_display example','?Example=Table_retrieve_display','black',['newwindow']);
my $append_link = &Link_To('Table_man.pl','Table_append example','?Example=Table_append','black',['newwindow']);
my $update_link = &Link_To('Table_man.pl','Table_update_array example','?Example=Table_update_array','black',['newwindow']);
my $deletes_link = &Link_To('Table_man.pl','delete_records example','?Example=delete_records','black',['newwindow']);
my $delete_link = &Link_To('Table_man.pl','delete_record example','?Example=delete_record','black',['newwindow']);
my $copy_link = &Link_To('Table_man.pl','Table_copy example','?Example=Table_copy','black',['newwindow']);

$Table=HTML_Table->new();
$Table->Set_Line_Colour('white','white');
$Table->Set_Border(2);
$Table->Toggle_Colour(0);
$Table->Set_Padding(10);
$Table->Set_Title("Some Routines Available from the GSDB.pm module");
$Table->Set_Headers(['Command','Description']);
$Table->Set_sub_header('Retrieving Data from the Database','mediumgreenbw');
$Table->Set_Row(['my @info = <BR><B>&Table_find_array($dbc,$table,\@field_list,$condition);</B>',
"This is a very simple way and fast way to retrieve data in one short command.<BR>Multiple values can easily be parsed out provided commas do not appear in the output.<BR>$find_link"]);

$Table->Set_Row(['my %info = <BR><B>&Table_retrieve($dbc,$table,\@field_list,$condition);<B>',"The results are placed in an indexed array<BR>(safer if the output may contain commas)<BR>$retrieve_link"]);

$Table->Set_Row(['my %info = <BR><B>&Table_retrieve_display($dbc,$table,\@field_list,$condition);<B>',
"This automatically dumps the results of the Table_retrieve command to a viewable HTML Table<BR>$retrieve_display_link"]);   

$Table->Set_sub_header('Appending the Database','mediumgreenbw');

$Table->Set_Row(['my $ok = <BR><B>&Table_append_array($dbc,$table,\@fields,\@values,$autoquote);</B>',
		 "(Adds a record to the database)<BR>(<B>IF the primary field in the added record is an AUTO_INCREMENT key:<BR>\$ok returns the value of the new ID.</B><BR>Otherwise: \$ok returns the number of records updated).(\$autoquote specifies whether the fields should be automatically quoted)</UL><BR>$append_link"]);

$Table->Set_sub_header('Editing Data in the Database','mediumgreenbw');
$Table->Set_Row(['my $ok = <BR><B>&Table_update_array($dbc,$table,\@fields,\@values,$condition);</B>',"This updates certain records in the database<BR>(Returning the number of records changed)<BR>$update_link"]);

$Table->Set_sub_header('Deleting Records from the Database','mediumgreenbw');
$Table->Set_Row(['my $ok = <BR><B>&delete_records($dbc,$table,$idfield,$list,$extra_condition);</B>',
"(returning the number of records deleted.)<p>
This routine should be used to delete a list of records as specified<BR>$deletes_link"]);

$Table->Set_Row(['my $ok = <BR><B>&delete_record($dbc,$table,$field,$value,$replace_value);</B>',
"(<B>this should be used to delete one record at a time only</B>.)<p>
It may also be used to automatically replace all incidences found with an alternative value specified.<BR>$delete_link"]);

$Table->Set_sub_header('Copying Records within the Database','mediumgreenbw');
$Table->Set_Row(['my $ok = <BR><B>&Table_copy($dbc,$table,$condition,\@exceptions,$DateTime_field,\@replacements);</B>',
"(returning the number of records copied.)<p>
This routines copies specified records within a table.<BR>
It allows for exceptions and replacement_values<BR>(Useful when you are copying records which include unique field entries.<BR>$copy_link"]);

$Table->Printout();

print &alDente::Web::unInitialize_page();
exit;
