#!/usr/local/bin/perl
#
# Tests to create new Original_Source, Source (RNA_DNA_Source), Library (RNA_DNA_Collection)
#
#
# Add to the lib search path
use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/custom";
use lib $FindBin::RealBin . "/../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";
use lib $FindBin::RealBin . "/../../../lib/perl/Experiment";

use strict;
use Data::Dumper;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use Test::More "no_plan";
use Test::Exception;

### Reference to alDente modules
use alDente::SDB_Defaults;

use SDB::CustomSettings;
use SDB::DBIO;


### Global variables
use vars qw(%Configs);

#### data can be seperated into another file ###
# config data
my $share = "SDB_" . $Configs{version_name};
my $browser_url = $Configs{URL_domain};
my $test_url = $Configs{URL_domain}."/".$share."/cgi-bin/barcode.pl";
print Dumper $test_url;
my $database_mode = $Configs{version_name} =~ /production/xmsi ? 'TEST' : 'BETA';

## login data
my $login_name = 'unit_tester1';
# retrieve password from file
my $pwd;
my $pwd_file = "$Configs{Home_dir}/versions/$Configs{version_name}/conf/unit_test_login.lims";
open my $PWD_FILE, "$pwd_file" or die "$!\n";
while( <$PWD_FILE> ) {
	chomp($_);
	$pwd = $_;
}

my $database = $Configs{$database_mode . '_DATABASE'};

## database host
my $db_host = $Configs{$database_mode . '_HOST'};

# general data
my $department = "Cap_Seq";
my $icon = "Sources";

# original source data
my $original_source_name = "SEL TEST 5";
my $sample_avail = "Yes";
my $organism = "Homo sapiens - human [9606]";
my $tissue = "Blood";
my $sex = "male";
my $contact = "BCCA: Nathalie Johnson";
my $date = "2007-06-04";
my $original_source_type = 'Bodily_Fluid';

# source data
my $source_type = "Nucleic_Acid";
my $ext_id =  "selenium test";
my $label = "selenium test label";
my $current_amount = "10";
my $original_amount = "10";
my $amount_units = "ul";
my $plate_format = "1.5 mL Tube";
my $received_employee = "Emp456: unit_tester1";
my $barcode_label = "No Barcode";
my $nature = "DNA";
my $storage_medium = "TE 10:0.1";
my $storage_medium_quantity = "10";
my $storage_medium_quantity_units = 'mg'; #"ul";

# library data
my $project = "MR - Affymetrix 500K Assay";
my $library_type = "RNA/DNA";
my $library_name = "SEL019";
my $library_full_name = "TEST SELENIUM";
my $library_obtained_date = "2006-09-13";
my $library_contact = "Scan Plus: Gord McBride";
my $grp = "Cap_Seq Production";
my $collection_type = "Microarray";

############################### Original_Source_Name field is unique.  If the previous execution of this unit test fails, the clean up wasn't completed (i.e. Original Source with the name $original_source_name stays in the database)

my $original_source_id;

my $dbc = SDB::DBIO->new(-dbase=>$database,-host=>$db_host,-user=>"super_cron",-connect=>1);
do {
    $original_source_name = 'SEL TEST '.int(rand(100));

    ($original_source_id) = $dbc->Table_find("Original_Source", "Original_Source_ID", "where Original_Source_Name = '$original_source_name'");
} while ($original_source_id);


#    print "original_source_id record defined\n";
#   $dbc->delete_records(-table=>"Original_Source",-dfield=>"Original_Source_ID",-id_list=>$original_source_id); 
#}
#die();

###############################

## connect to the selenium server
my $sel = Test::WWW::Selenium->new( host => "lims04.phage.bcgsc.ca",
                                    port => 4444,
                                    browser => '*firefox C:\Program Files\Mozilla Firefox\firefox.exe',
                                    auto_stop=>1,
                                    browser_url => $browser_url );

## open url
$sel->open_ok($test_url);

## login
$sel->type_ok("document.LoginPage.elements['User List']", $login_name);
$sel->type("Pwd", $pwd);
$sel->select_ok("Printer_Group", "label=5th Floor Printers");
$sel->click_ok("//input[\@name='Database_Mode' and \@value='$database_mode']");
$sel->click_ok("//input[\@value='Log In']");
$sel->wait_for_page_to_load_ok("30000");

## choose department
$sel->click_ok("link=$department");
$sel->wait_for_page_to_load_ok("30000");

## choose icon
#$sel->click_ok("link=$icon");
#$sel->click_ok("link=Profiler");
#$sel->click_ok("value=Standard+Page=Source");
$sel->click_ok("xpath=//a[contains(\@href,'Source')]");
$sel->wait_for_page_to_load_ok("30000");

$sel->click_ok("document.SourcePage_Create.elements['Create New Library']");
$sel->wait_for_page_to_load_ok("30000");

WAIT: {
    for (1..60) {
        if (eval { $sel->is_element_present("xpath=//input[\@value=\"Next >>\"]") }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}

## fill out original source form
# Useful for debugging: print $sel->get_title; print $sel->get_html_source();
#print $sel->get_title; print $sel->get_html_source();
$sel->select_ok("Sample_Available", "label=$sample_avail");
$sel->type_ok("Original_Source_Name", $original_source_name);

#$sel->type_ok("Original_Source.FK_Taxonomy__ID", "$organism");
#$sel->type_ok("xpath=//*[text()=\"FK_Taxonomy__ID\"]", "$organism");
#$sel->type_ok("Taxonomy_ID", "$organism");
$sel->type_ok("xpath=//input[contains(\@name,'FK_Taxonomy__ID')]", "$organism"); #$sel->type_ok("name=FK_Taxonomy__ID", "$organism"); was also ok

#$sel->select_ok("Original_Source.FK_Tissue__ID.Choice", "label=$tissue");
#$sel->select_ok("name=FK_Tissue__ID Choice", "label=$tissue");
$sel->select_ok("Original_Source.Original_Source_Type", "label=$original_source_type");
$sel->click_ok("Original_Source.Original_Source_Type");
sleep(50);
#print $sel->get_title; print $sel->get_html_source(); 
$sel->select_ok("xpath=//select[contains(\@name,'FK_Anatomic_Site__ID')]", "label=$tissue");

$sel->type_ok("Sex", $sex);
#$sel->select_ok("Original_Source.FK_Contact__ID.Choice", "label=$contact");
$sel->select_ok("xpath=//select[contains(\@name,'FK_Contact__ID Choice')]", "label=$contact");

$sel->click_ok("Defined_Date");
$sel->type_ok("Defined_Date", $date);

$sel->select_ok("xpath=//select[contains(\@name,'Disease_Status')]", "label=Normal");

$sel->click_ok("//input[\@value='Next >>']");

WAIT: {
    for (1..60) {
        if (eval { $sel->is_element_present("//input[\@value='Next >>']") }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}

## fill out source form
#print $sel->get_html_source();
sleep(5); #when things are slow, the branch loading is slow
$sel->select_ok("xpath=//select[contains(\@name,'FK_Sample_Type__ID')]", "label=$source_type");
$sel->type_ok("External_Identifier", $ext_id);
$sel->type_ok("Source_Label", $label);
$sel->click_ok("Received_Date");
$sel->type_ok("Received_Date", $date);
$sel->type_ok("Current_Amount", $current_amount);
$sel->type_ok("Original_Amount", $original_amount);
$sel->select_ok("Amount_Units", $amount_units);

#$sel->select_ok("FK_Plate_Format__ID.Choice", "label=$plate_format");
$sel->select_ok("xpath=//select[contains(\@name,'FK_Plate_Format__ID')]", "label=$plate_format");

#$sel->select_ok("Source.FKReceived_Employee__ID.Choice", "label=$received_employee");
$sel->select_ok("xpath=//select[contains(\@name,'FKReceived_Employee__ID Choice')]", "label=$received_employee");

#$sel->select_ok("Source.FK_Barcode_Label__ID", $barcode_label);
$sel->select_ok("xpath=//select[contains(\@name,'FK_Barcode_Label__ID')]", "$barcode_label");

$sel->click_ok("//input[\@value='Next >>']");

WAIT: {
    for (1..60) {
        if (eval { $sel->is_element_present("//input[\@value='Next >>']") }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}

## fill out RNA_DNA_Source form
#print $sel->get_html_source();
$sel->click_ok("RNA_DNA_Isolation_Date");
$sel->type_ok("Submitted_Amount", $storage_medium_quantity);
#$sel->type_ok("Storage_Medium_Quantity_Units", $storage_medium_quantity_units);
$sel->select_ok("Submitted_Amount_Units", $storage_medium_quantity_units);

$sel->click_ok("//input[\@value='Next >>']");
WAIT: {
    for (1..60) {
        if (eval { $sel->is_element_present("//input[\@value='Next >>']") }) { pass; last WAIT }
        sleep(2);
    }
    fail("timeout");
}

## fill out Library form
#$sel->select_ok("xpath=//select[contains(\@name,'')]", "");
#print $sel->get_html_source();
#$sel->select_ok("Library.FK_Project__ID.Choice", "label=$project");
$sel->select_ok("xpath=//select[contains(\@name,'FK_Project__ID Choice')]", "label=$project");

$sel->select_ok("Library_Type", "label=$library_type");
$sel->type_ok("Library_Name", $library_name);
$sel->type_ok("Library_FullName", $library_full_name);
$sel->click_ok("Library_Obtained_Date");
$sel->type_ok("Library_Obtained_Date", $date);

#$sel->select_ok("Library.FK_Contact__ID.Choice", "label=$library_contact");
$sel->select_ok("xpath=//select[contains(\@name,'FK_Contact__ID Choice')]", "label=$library_contact");

#$sel->select_ok("Library.FK_Grp__ID.Choice", "label=$grp");
$sel->select_ok("xpath=//select[contains(\@name,'FK_Grp__ID')]", "label=$grp");

$sel->click_ok("Requested_Completion_Date");

$sel->click_ok("//input[\@value='Next >>']");
WAIT: {
    for (1..60) {
        if (eval { $sel->is_element_present("//input[\@value='Next >>']") }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}

# should we add a wait block here
$sel->select_ok("Experiment_Type", "label=$collection_type");
$sel->click_ok("//input[\@value='Next >>']");

WAIT: {
    for (1..60) {
        if (eval { $sel->is_element_present("//input[\@value='Next >>']") }) { pass; last WAIT }
        sleep(1); 
         }
        fail("timeout");
}
#$sel->select_ok("LibraryGoal.FK_Goal__ID.Choice", "label=No Defined goals");
#$sel->type_ok("Goal_Target", "1");
#$sel->click_ok("//input[\@value='Finish']");
#$sel->wait_for_page_to_load_ok("30000");

# fill out Work_Request
#print $sel->get_html_source();
$sel->select_ok("FK_Goal__ID", "label=No Defined goals");
$sel->type_ok("Goal_Target", "1");
$sel->select_ok("xpath=//select[contains(\@name,'FK_Work_Request_Type__ID')]", "label=Default Work Request");
$sel->click_ok("//input[\@value='Next >>']");

#WAIT: {
#    for (1..60) {
#        if (eval { $sel->is_element_present("//input[\@value='Next >>']") }) { pass; last WAIT }
#        sleep(1);
#    }
#    fail("timeout");
#}
# find out To Be Returned
#print $sel->get_html_source();
#$sel->type_ok("Number_to_Transfer", "0");
#$sel->select_ok("xpath=//select[contains(\@name,'FK_Sample_Format__ID')]", "label=None");
#$sel->click_ok("//input[\@value='Next >>']");

#For Library_Source link
WAIT: {
    for (1..60) {
        if (eval { $sel->is_element_present("//input[\@value='Finish']") }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}

$sel->click_ok("//input[\@value='Finish']");
$sel->wait_for_page_to_load_ok("50000");

# THIS is clicking yes on the dialog box
ok($sel->get_confirmation() =~ /^Submit all forms[\s\S]$/,"Ok got Submit all forms confirmation");

$sel->wait_for_page_to_load_ok("30000");
## verify results
#print $sel->get_html_source();
my $os_ok = $sel->is_text_present_ok("New Original_Source record added");
my $s_ok = $sel->is_text_present_ok("New Source record added");
my $library_ok = $sel->is_text_present_ok("New Library record added");
my $l_s_ok = $sel->is_text_present_ok("New Library_Source record added");
my $rdc_ok = $sel->is_text_present_ok("New RNA_DNA_Collection record added");
my $rds_ok = $sel->is_text_present_ok("New Nucleic_Acid record added");
my $wr_ok = $sel->is_text_present_ok("New Work_Request record added");
my $mt_ok;# = $sel->is_text_present_ok("New Material_Transfer record added");

### remove the test data from database
# move to the above
# my $dbc = SDB::DBIO->new(-dbase=>$database,-host=>$db_host,-user=>"",-password=>"",-connect=>1);

## delete the following table: Original_Source, Source, RNA_DNA_Source, Library, RNA_DNA_Collection, Library_Source
=for manual delete if you want to look at the new records in LIMS before deleting
Delete Library_Source from Library_Source,Source,Original_Source where FK_Source__ID = Source_ID and FK_Original_Source__ID = Original_Source_ID and FK_Library__Name = 'SEL009' and Original_Source_Name like 'SEL TEST%';
Delete Nucleic_Acid, Source, Original_Source from Nucleic_Acid, Source, Original_Source where FK_Source__ID = Source_ID AND FK_Original_Source__ID = Original_Source_ID and Original_Source_Name like 'SEL TEST%';
Delete from RNA_DNA_Collection where FK_Library__Name = 'SEL009';
Delete from Library where Library_Name = 'SEL009';
Delete Work_Request,Material_Transfer from Work_Request LEFT JOIN Material_Transfer ON FK_Work_Request__ID = Work_Request_ID where FK_Library__Name = 'SEL009';
=cut
#exit;

my $os_id;
my $s_id;

my @ids = $dbc->Table_find("Original_Source", "Original_Source_ID", "where Original_Source_Name = '$original_source_name'");
if ($ids[0]){
  $os_id = $ids[0];
}


@ids = $dbc->Table_find("Source", "Source_ID", "where FK_Original_Source__ID = $os_id");
if ($ids[0]){
  $s_id = $ids[0];
}


if ($l_s_ok){
  my ($l_s_id) = $dbc->Table_find("Library_Source", "Library_Source_ID", "where FK_Source__ID = $s_id and FK_Library__Name = '$library_name'");
  if ($l_s_id){
    $dbc->delete_records(-table=>"Library_Source",-dfield=>"Library_Source_ID",-id_list=>$l_s_id);
  }
}

if ($rds_ok){
  my ($rds_id) = $dbc->Table_find("Nucleic_Acid", "Nucleic_Acid_ID", "where FK_Source__ID = $s_id");
  if ($rds_id){
    $dbc->delete_records(-table=>"Nucleic_Acid",-dfield=>"Nucleic_Acid_ID",-id_list=>$rds_id);
  }
}

if ($rdc_ok){
  my ($rdc_id) = $dbc->Table_find("RNA_DNA_Collection", "RNA_DNA_Collection_ID", "where FK_Library__Name = '$library_name'");
  if ($rdc_id){
    $dbc->delete_records(-table=>"RNA_DNA_Collection",-dfield=>"RNA_DNA_Collection_ID",-id_list=>$rdc_id);
  }
}

if ($s_ok){
  if ($s_id){
    $dbc->delete_records(-table=>"Source",-dfield=>"Source_ID",-id_list=>$s_id);
  }
}

if ($library_ok){
  print "delete from Library where Library_Name = '$library_name';\n";
  $dbc->dbh()->do("delete from Library where Library_Name = '$library_name'");
}

if ($os_ok){
  if ($os_id){
    $dbc->delete_records(-table=>"Original_Source",-dfield=>"Original_Source_ID",-id_list=>$os_id);
  }
}

if ($wr_ok && $mt_ok) {
    print "Delete Work_Request,Material_Transfer from Work_Request,Material_Transfer where FK_Library__Name = '$library_name' and FK_Work_Request_\_ID = Work_Request_ID;\n";
    $dbc->dbh()->do("Delete Work_Request,Material_Transfer from Work_Request LEFT JOIN Material_Transfer ON FK_Work_Request__ID = Work_Request_ID where FK_Library__Name = '$library_name'");
}

ok( 1 ,'Completed Selenium test');

