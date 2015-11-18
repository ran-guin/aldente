#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
my $dbase  = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("SDB::Query");

if ( !$method || $method =~ /\bcompare_queries\b/ ) {
    can_ok("SDB::Query", 'compare_queries');
    {
        ## <insert tests for compare_queries method here> ##
    }
}

if ( !$method || $method =~ /\bdeconstruct_query\b/ ) {
    can_ok("SDB::Query", 'deconstruct_query');
    {
        ## <insert tests for deconstruct_query method here> ##
        my $query = "SELECT Original_Source.FK_Contact__ID AS Contact,Library.Library_Notes AS Library_Notes,object_name,Plate.Plate_ID AS Container,Library_Name FROM (Library , RNA_DNA_Collection , Source , Library_Source , Original_Source , Plate , Plate_Prep , Prep , Lab_Protocol , (select Object_Class as object_name FROM Object_Class WHERE object_class_id = 4)as OC)LEFT JOIN Plate_Tray on Plate_Tray.FK_Plate__ID = Plate_ID WHERE 1 AND Library.FK_Original_Source__ID = Original_Source.Original_Source_ID AND Library.Library_Name = RNA_DNA_Collection.FK_Library__Name AND Source.FK_Original_Source__ID = Original_Source.Original_Source_ID AND Library_Source.FK_Library__Name = Library.Library_Name AND Plate.FK_Library__Name = Library.LIbrary_Name AND Plate_Prep.FK_Plate__ID = Plate_ID AND Prep.Prep_ID = Plate_Prep.FK_Prep__ID AND Lab_Protocol.Lab_Protocol_ID = Prep.FK_Lab_Protocol__ID AND Lab_Protocol_Name IN ( 'Agilent 1 (RNA)' , 'Agilent 2 (RNA/DNAse I)' , 'Caliper total RNA QC' , 'Caliper Flow through RNA QC') AND Library_Status IN ( 'Submitted' , 'In Production') AND Experiment_Type = 'Solexa' AND Library_Obtained_Date > DATE_SUB(curdate() , INTERVAL 1 YEAR) AND Library_Name NOT IN ( select FK_Library__Name from Plate , Plate_Attribute where FK_Plate__ID = Plate_ID and FK_Attribute__ID = 418) AND Plate.Plate_ID IN ( '719998' , '719999' , '720000' ) GROUP BY Library_Name,Container ORDER BY Library_Name LIMIT 2000";
        my $cleaned_query = SDB::Query::deconstruct_query($query);
        #print "result=[$cleaned_query]\n";
        my $expected = 
"<B>SELECT</B><BR>
Original_Source.FK_Contact__ID AS Contact<BR>
,Library.Library_Notes AS Library_Notes<BR>
,object_name<BR>
,Plate.Plate_ID AS Container<BR>
,Library_Name<BR>
<B>FROM</B><BR>
(Library  , RNA_DNA_Collection  , Source  , Library_Source  , Original_Source  , Plate  , Plate_Prep  , Prep  , Lab_Protocol  , (select Object_Class as object_name FROM Object_Class WHERE object_class_id = 4)as OC)<BR>
 LEFT JOIN  Plate_Tray on Plate_Tray.FK_Plate__ID = Plate_ID<BR>
<B>WHERE</B><BR>
1 <BR>
 AND Library.FK_Original_Source__ID = Original_Source.Original_Source_ID <BR>
 AND Library.Library_Name = RNA_DNA_Collection.FK_Library__Name <BR>
 AND Source.FK_Original_Source__ID = Original_Source.Original_Source_ID <BR>
 AND Library_Source.FK_Library__Name = Library.Library_Name <BR>
 AND Plate.FK_Library__Name = Library.LIbrary_Name <BR>
 AND Plate_Prep.FK_Plate__ID = Plate_ID <BR>
 AND Prep.Prep_ID = Plate_Prep.FK_Prep__ID <BR>
 AND Lab_Protocol.Lab_Protocol_ID = Prep.FK_Lab_Protocol__ID <BR>
 AND Lab_Protocol_Name IN  ( 'Agilent 1 (RNA)'  , 'Agilent 2 (RNA/DNAse I)'  , 'Caliper total RNA QC'  , 'Caliper Flow through RNA QC')<BR>
 AND Library_Status IN  ( 'Submitted'  , 'In Production')<BR>
 AND Experiment_Type = 'Solexa' <BR>
 AND Library_Obtained_Date > DATE_SUB(curdate() , INTERVAL 1 YEAR)<BR>
 AND Library_Name NOT IN  ( select FK_Library__Name from Plate  , Plate_Attribute where FK_Plate__ID = Plate_ID  and FK_Attribute__ID = 418)<BR>
 AND Plate.Plate_ID IN  ( '719998'  , '719999'  , '720000' )<BR>
<B>GROUP BY</B><BR>
Library_Name<BR>
,Container<BR>
<B>ORDER BY</B><BR>
Library_Name<BR>
<B>LIMIT</B><BR>
2000 ";        

		is( $cleaned_query, $expected, 'deconstruct_query');
    }
}

if ( !$method || $method =~ /\bquery_string\b/ ) {
    can_ok("SDB::Query", 'query_string');
    {
        ## <insert tests for query_string method here> ##
    }
}

if ( !$method || $method =~ /\bsplit_fields\b/ ) {
    can_ok("SDB::Query", 'split_fields');
    {
        ## <insert tests for split_fields method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Query test');

exit;
