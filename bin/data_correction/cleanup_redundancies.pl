#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../../lib/perl/";             # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Core/";        # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../../lib/perl/Imported/";    # add the local directory to the lib search path
use Getopt::Long;

use RGTools::RGIO;
use RGTools::Process_Monitor;

use SDB::DBIO;
use SDB::CustomSettings;
use Switch;

use vars qw($opt_help $opt_quiet $opt_host $opt_dbase $opt_user $opt_password $opt_table $opt_field $opt_join $opt_map $opt_v $opt_block $opt_debug);

&GetOptions(
    'help'       => \$opt_help,
    'quiet'      => \$opt_quiet,
    'dbase=s'    => \$opt_dbase,
    'host=s'     => \$opt_host,
    'user=s'     => \$opt_user,
    'password=s' => \$opt_password,
    'table=s'    => \$opt_table,
    'field=s'    => \$opt_field,
    'join=s'     => \$opt_join,
    'map=s'      => \$opt_map,
    'block=s'    => \$opt_block,
    'debug'      => \$opt_debug,
);

my $help  = $opt_help;
my $quiet = $opt_quiet;
my $host  = $opt_host;
my $dbase = $opt_dbase;
my $user  = $opt_user;
my $pwd   = $opt_password;
my $table = $opt_table;
my $field = $opt_field;
my $join  = $opt_join;
my $map   = $opt_map;
my $block = $opt_block;

my $debug = $opt_debug;

if ($help) { help(); exit; }

my $Report = Process_Monitor->new( -variation => $opt_v );
$Report->set_Message("Attempting to connect to $host:$dbase as $user");

require SDB::DBIO;
my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

my $choice = $ARGV[0];
if ($block) { $choice = 'sync_' . $block }

my $conf_sex;
my $conf_taxonomy;
my $conf_age;
my $conf_sample;
my $conf_cell_line;
my $conf_billable;
my $conf_source_received_date;
my $conf_collection_time;

print "Sync $block...\n";

print "Trim all attribute values...\n";
$dbc->execute_command("Update Source_Attribute set Attribute_Value = TRIM(Attribute_Value)");

switch ($choice) {
    case "sync_sex" {
        $conf_sex = sync_sex( -dbc => $dbc );
    }
    case "sync_taxonomy" {
        $conf_taxonomy = sync_taxonomy( -dbc => $dbc );
    }
    case "sync_age" {
        $conf_age = sync_age( -dbc => $dbc );
    }
    case "sync_sample" {
        $conf_sample = sync_sample( -dbc => $dbc );
    }
    case "sync_cell_line" {
        $conf_cell_line = sync_cell_line( -dbc => $dbc );
    }
    case "sync_billable" {
        $conf_billable = sync_billable( -dbc => $dbc );
    }
    case "sync_source_received_date" {
        $conf_source_received_date = sync_source_received_date( -dbc => $dbc );
    }
    case "sync_collection_time" {
        $conf_collection_time = sync_collection_time( -dbc => $dbc );
    }
    else {

        print "Synchronize all defined fields... \n";
        
        $conf_sex                  = sync_sex( -dbc                  => $dbc );
        $conf_taxonomy             = sync_taxonomy( -dbc             => $dbc );
        $conf_age                  = sync_age( -dbc                  => $dbc );
        $conf_sample               = sync_sample( -dbc               => $dbc );
        $conf_cell_line            = sync_cell_line( -dbc            => $dbc );
        $conf_billable             = sync_billable( -dbc             => $dbc );
        $conf_source_received_date = sync_source_received_date( -dbc => $dbc );
        $conf_collection_time      = sync_collection_time( -dbc     => $dbc );
    }
}

if ($conf_sex) {
    $Report->set_Warning("There are conflicting sex values between Original_Source and Patient tables");
}

if ($conf_taxonomy) {
    $Report->set_Warning("There are conflicting taxonomy values between Original_Source and Patient tables");
}

if ($conf_cell_line) {
    $Report->set_Warning("There are conflicting Anatomic Site between Cell_Line and Original Source tables");
}

if ($conf_source_received_date) {
    print Dumper $conf_source_received_date;
    $Report->set_Warning("There are sources with Received Date not the same as their shipments Received Date");
}

if ($conf_collection_time) {
    $Report->set_Warning("There is conflicting Collection Time information");
}

$Report->completed();
$Report->DESTROY();
print "\n\n";
exit;

#
# Standardized synchronization method to reduce need for custom code ... 
#
# 
#################
sub sync_standard {
#################
    my %args = &filter_input( \@_, -args => 'fields,condition' );
    my $fields = $args{-fields};
    my $join_condition = $args{-condition};
    
    my $f1 = $fields->[0];
    my $f2 = $fields->[1];

    my ($t1) = split /\./, $f1;
    my ($t2) = split /\./, $f2;
    
    if ( $dbc->field_exists($f1) && $dbc->field_exists($f2) ) {    
        
        my $fix1 = "UPDATE $t1,$t2 SET $f2 = $f1 WHERE $join_condition AND ( Length($f1) > 0 AND $f1 IS NOT NULL) AND (Length($f2) = 0 OR $f2 IS NULL)";
        my $fixed = $dbc->execute_command($fix1);     ## fix empty f1 
         
        my $fix2 = "UPDATE $t1,$t2 SET $f1 = $f2 WHERE $join_condition AND ( Length($f2) > 0 AND $f2 IS NOT NULL) AND (Length($f1) = 0 OR $f1 IS NULL )";
        $fixed .= $dbc->execute_command($fix2);    ## fix empty f2
        
        if ($debug) { print "$fix1\n$fix2\n" }
        
        print "Synchronized $f1 with $f2\n********************************\n$fixed\n\n";
        return $dbc->Table_retrieve( "$t1, $t2", [ 'count(*)', $f1, $f2 ], "WHERE $join_condition AND $f1 NOT LIKE $f2", -group => "$f1,$f2", -debug=>$debug);
    }
    else { 
        print "$f1 or $f2 missing... skipping this synchronization...\n";
        return;
    }
}

#
# Standard synchronization when an attribute is synced with a field (accounts for non-existence of existing attribute)
#
#
#
####################
sub sync_attribute {
####################
    my %args = &filter_input( \@_, -args => 'field,attribute' );
    my $field = $args{-field};
    my $attribute = $args{-attribute};
    my $condition = $args{-condition};
    
    my $f1 = $field;
    my ($t1) = split /\./, $f1;

    my $non_qualified_field = $f1;
    $non_qualified_field =~s/(.*)\.//;
    
    my $t2 = $t1 . '_Attribute';
    my $f2 = "$t2.Attribute_Value";
    
 
    my ($attribute_id) = $dbc->Table_find('Attribute', "Attribute_ID", "WHERE Attribute_Class = '$t1' AND Attribute_Name ='$attribute'");
    my ($primary) = $dbc->get_field_info(-table=>$t1, -type=>'Primary');
    my $join_condition = "$primary=${t1}_Attribute.FK_${t1}__ID AND FK_Attribute__ID='$attribute_id'";
    
    if ( $dbc->field_exists($f1) && $dbc->field_exists($f2) && $attribute) {  
                          
        my %missing_attributes = $dbc->Table_retrieve("$t1 LEFT JOIN $t2 ON $join_condition", [$primary, $f1], "WHERE ${t2}_ID IS NULL AND " . _has_value($f1, $condition), -debug=>$debug);
        my ($added, $i) = (0,0);
        
        if ($debug && $missing_attributes{$primary}) {
            print "Missing IDs:\n";
            print join ',', @{$missing_attributes{$primary}};
            print "\n";
        }
        while ($missing_attributes{$primary}[$i]) {
            my $p1 = $missing_attributes{$primary}[$i];
            my $v1 = $missing_attributes{$non_qualified_field}[$i];
            $added += $dbc->Table_append_array($t2, ['FK_' . $t1 . '__ID', 'FK_Attribute__ID', 'Attribute_Value'], [$p1, $attribute_id, $v1], -autoquote=>1, -debug=>$debug);
            $i++;
        }
        
        if ($i) { print "Added $added attribute values\n\n" }
        else { print "No missing attributes\n\n" }
        
        my $fix1 = "UPDATE $t1, $t2 SET $f2 = $f1 WHERE $join_condition AND " . _has_value($f1, $condition) . " AND  " . _has_no_value($f2, $condition);
        my $fixed = $dbc->execute_command($fix1);     ## fix empty f1 
         
        my $fix2 = "UPDATE $t1,$t2 SET $f1 = $f2 WHERE $join_condition AND " . _has_value($f2, $condition) . " AND " . _has_no_value($f1, $condition);
        $fixed .= $dbc->execute_command($fix2);    ## fix empty f2
        
        if ($debug) { print "$fix1\n$fix2\n" }
        
        print "Synchronized $f1 with $f2\n********************************\n$fixed\n\n";
        return $dbc->Table_retrieve( "$t1, $t2", [ 'count(*)', $f1, $f2 ], "WHERE $join_condition AND $f1 NOT LIKE $f2", -group => "$f1,$f2", -debug=>$debug);
    }
    else { 
        print "$f1 or $f2 missing (or attribute '$attribute' undefined for $t1 class)... skipping this synchronization...\n";
        return;
    }
}   

#################
sub _has_value {
#################
    my $field = shift;
    my $condition = shift;
    
    my $test = "Length($field) > 0 AND $field IS NOT NULL";
    if ($condition) { 
        $condition =~s/<FIELD>/$field/g;
        $test .= " AND $condition";
    }
    return "($test)";
}

#################
sub _has_no_value {
#################
    my $field = shift;
    my $condition = shift;
          
    my $test = "Length($field) = 0 OR $field IS NULL";
    if ($condition) { 
        $condition =~s/<FIELD>/$field/g;
        $test .= " OR !$condition";
    }
    
    return  "($test)";
}

##########################
sub sync_cell_line {
##########################
    # Description:
    #       This function copies over the Anatomic Site of Cell_Line to Original Source if the Original Source Tissue is not set
##########################

    my %args = &filter_input( \@_, -args => '' );
    my $dbc = $args{-dbc};

    my @ids = $dbc->Table_find( 'Anatomic_Site', 'Anatomic_Site_ID', 'WHERE Anatomic_Site_Alias LIKE "Unspecified%" OR Anatomic_Site_Alias LIKE "Unknown%"' );
    push @ids, 0;
    my $ids = join ',', @ids;
    my $command
        = "UPDATE Cell_Line, Original_Source SET Original_Source.FK_Anatomic_Site__ID  = Cell_Line.FK_Anatomic_Site__ID  WHERE FK_Cell_Line__ID = Cell_Line_ID and Cell_Line.FK_Anatomic_Site__ID <> Original_Source.FK_Anatomic_Site__ID and Original_Source.FK_Anatomic_Site__ID IN ($ids) AND Cell_Line.FK_Anatomic_Site__ID <> 0 AND Cell_Line.FK_Anatomic_Site__ID IS NOT NULL";

    $dbc->execute_command("$command");

    my %data = $dbc->Table_retrieve(
        'Original_Source LEFT JOIN Anatomic_Site as OS_Tissue ON  Original_Source.FK_Anatomic_Site__ID = OS_Tissue.Anatomic_Site_ID , Cell_Line LEFT JOIN Anatomic_Site as Cell_Line_Tissue ON Cell_Line.FK_Anatomic_Site__ID = Cell_Line_Tissue.Anatomic_Site_ID',
        [ 'Cell_Line_Name', 'Original_Source_Name', 'Cell_Line_Tissue.Anatomic_Site_Alias as Cell_Line_Tissue', 'OS_Tissue.Anatomic_Site_Alias as OS_Tissue' ],
        "WHERE FK_Cell_Line__ID = Cell_Line_ID and Cell_Line.FK_Anatomic_Site__ID <> Original_Source.FK_Anatomic_Site__ID ORDER BY Cell_Line_Name"
    );

#   print Dumper %data;
# select  Cell_Line_Name, Original_Source_Name, Cell_Line_Tissue.Anatomic_Site_Alias as Cell_Line_Tissue,  OS_Tissue.Anatomic_Site_Alias as OS_Tissue from Original_Source LEFT JOIN Anatomic_Site as OS_Tissue ON  Original_Source.FK_Anatomic_Site__ID = OS_Tissue.Anatomic_Site_ID , Cell_Line LEFT JOIN Anatomic_Site as Cell_Line_Tissue ON Cell_Line.FK_Anatomic_Site__ID = Cell_Line_Tissue.Anatomic_Site_ID WHERE FK_Cell_Line__ID = Cell_Line_ID and Cell_Line.FK_Anatomic_Site__ID <> Original_Source.FK_Anatomic_Site__ID ORDER BY Cell_Line_Name
    return %data;

}

##########################
sub sync_sex {
##########################
    
    return sync_standard(['Original_Source.Sex','Patient.Patient_Sex'], "FK_Patient__ID=Patient_ID");
    
    my %args = &filter_input( \@_, -args => '' );
    my $dbc = $args{-dbc};

    $dbc->execute_command("UPDATE Original_Source,Patient SET Patient_Sex = Sex WHERE FK_Patient__ID=Patient_ID AND ( Length(Sex) > 0 AND Sex IS NOT NULL) AND (Length(Patient_Sex) = 0 OR Patient_SEX IS NULL)");     ## fix empty OS.Sex
    $dbc->execute_command("UPDATE Original_Source,Patient SET Sex = Patient_Sex WHERE FK_Patient__ID=Patient_ID AND ( Length(Patient_Sex) > 0 AND Patient_Sex IS NOT NULL) AND (Length(Sex) = 0 OR Sex IS NULL )");    ## fix empty OS.Sex

    return $dbc->Table_retrieve( 'Original_Source,Patient', [ 'count(*)', 'Original_Source.Sex', 'Patient_Sex' ], "WHERE FK_Patient__ID=Patient_ID AND Original_Source.Sex != Patient_Sex", -group => "Sex,Patient_Sex" );
}

##########################
sub sync_taxonomy {
##########################

    return sync_standard(['Original_Source.FK_Taxonomy__ID','Patient.FK_Taxonomy__ID'], "FK_Patient__ID=Patient_ID");

    my %args = &filter_input( \@_, -args => '' );
    my $dbc = $args{-dbc};

    $dbc->execute_command("UPDATE Original_Source,Patient SET Patient.FK_Taxonomy__ID = Original_Source.FK_Taxonomy__ID WHERE FK_Patient__ID=Patient_ID AND Original_Source.FK_Taxonomy__ID > 0 AND Patient.FK_Taxonomy__ID = 0")
        ;    ## fix empty Patient.FK_Taxonomy__ID
    $dbc->execute_command("UPDATE Original_Source,Patient SET Original_Source.FK_Taxonomy__ID = Patient.FK_Taxonomy__ID WHERE FK_Patient__ID=Patient_ID AND Patient.FK_Taxonomy__ID > 0 AND Original_Source.FK_Taxonomy__ID = 0")
        ;    ## fix empty OS.FK_Taxonomy__ID

    return $dbc->Table_retrieve(
        'Original_Source,Patient',
        [ 'count(*)', 'Original_Source.FK_Taxonomy__ID', 'Patient.FK_Taxonomy__ID' ],
        "WHERE FK_Patient__ID=Patient_ID AND Original_Source.FK_Taxonomy__ID != Patient.FK_Taxonomy__ID",
        -group => "Original_Source.FK_Taxonomy__ID,Patient.FK_Taxonomy__ID"
    );
}

# Description:
# This function copies over the Shipment received date to source received date if the latter is different from the former
##########################

##########################
sub sync_source_received_date {
##########################

    return sync_standard(['Source.Received_Date','Shipment.Shipment_Received'], "FK_Shipment__ID=Shipment_ID");

    my %args = &filter_input( \@_, -args => '' );
    my $dbc = $args{-dbc};

    $dbc->execute_command("Update Source, Shipment set Received_Date = Shipment_Received WHERE FK_Shipment__ID is not null AND FK_Shipment__ID = Shipment_ID AND Received_Date != Shipment_Received");

    return $dbc->Table_retrieve( 'Source,Shipment', ['Source_ID'], "WHERE FK_Shipment__ID is not null AND FK_Shipment__ID = Shipment_ID AND Received_Date != Shipment_Received", );
}

# Description:
#
# This function syncs the Attribute Collection Time with the field Collection Time (attribute is easier to use in the current workflow even though a field exists)
#
###############################
sub sync_collection_time {
###############################

    return sync_attribute('Source.Sample_Collection_Time', 'collection_time', -condition=>"DAY(TRIM(<FIELD>))");

    my %args = &filter_input( \@_, -args => '' );
    my $dbc = $args{-dbc};

    my ($attribute) = $dbc->Table_find( "Attribute", "Attribute_ID", "WHERE Attribute_Class = 'Source' AND Attribute_Name like 'collection_time'" );

    use SDB::DB_Object;
    SDB::DB_Object::sync( -dbc => $dbc, -fields => [ 'Source_Attribute.Attribute_Value', 'Source.Sample_Collection_Time' ], -join_condition => "FK_Source__ID=Source_ID AND FK_Attribute__ID = $attribute" );

    $dbc->execute_command(
        "Update Source, Source_Attribute set Sample_Collection_Time = Attribute_Value WHERE FK_Source__ID=Source_ID AND FK_Attribute__ID = $attribute AND (Sample_Collection_Time = '0' OR Sample_Collection_Time IS NULL) AND Length(Attribute_Value) > 1",
        -debug => 1 );

    return $dbc->Table_retrieve( 'Source, Source_Attribute', ['Source_ID'], "WHERE FK_Source__ID=Source_ID AND FK_Attribute__ID = $attribute AND Attribute_Value != Sample_Collection_Time" );
}

################
sub sync_age {
################

    return "Under construnction";
}

##########################
sub sync_sample {
##########################

    return "Under construnction";
}

##########################
sub help {
##########################

    print <<HELP;

Usage:
*********
    
    //clean up redundancies 
    cleanup_redundancies.pl -host server -database db -user user -password *****

 

Mandatory Input:
**************************

    
Options:
**************************     
    -host
    -base
    -user
    -pwd
    

Examples:
***********

    cleanup_redundancies.pl -host lims05 -dbase seqtest -user aldente_admin -pwd ******
    
HELP

}

##########################
# Calls sync_billable() in alDente::Invoiceable_Work.pm
# then calls sync() in SDB::DB_Object.pm
# other sync_*** method may also calls the general sync method with out passing ids
##########################
sub sync_billable {
##########################
    #The run.billable field may get phased out.
    #Synchronizing Run.Billable and Invoiceable_Work_Reference.Billable

    my %args  = &filter_input( \@_, -args => '' );
    my $dbc   = $args{-dbc};
    my $debug = $args{-debug};

    require alDente::Invoiceable_Work;

    my $result = alDente::Invoiceable_Work::sync_billable( -dbc => $dbc, -debug => $debug );

    return;
}

