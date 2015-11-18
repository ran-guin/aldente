#!/usr/local/bin/perl
#######################################################################################
## Standard Template for building cron jobs or scripts that connect to the database ###
#######################################################################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/LampLite";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

########################
## Local Core modules ##
########################
use CGI;
use Data::Dumper;
use Benchmark;

##########################
## Local custom modules ##
##########################
use RGTools::RGIO;
use RGTools::Process_Monitor;
use LampLite::Bootstrap;

use SDB::DBIO;                  ## use to connect to database 

use alDente::Config;            ## use to initialize configuration settings
use Healthbank::Model;

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
my $Setup = LampLite::Config->new( -initialize=>$FindBin::RealBin . '/../conf/custom.cfg');
my $configs = $Setup->{config};
        
%Configs = %{$configs};  ## phase out global, but leave in for now .... 
###################################################
## END OF Standard Module Initialization Section ##
###################################################

## Load input parameter options ## 
#
## (replace section below with required input parameters as required) ##
#
use vars qw($opt_host $opt_dbase $opt_debug $opt_plate_condition $opt_source_condition $opt_since);

use Getopt::Long;
&GetOptions(
    'host=s'    => \$opt_host,
    'dbase=s'   => \$opt_dbase,
    'debug|t'     => \$opt_debug,
    'plate_condition=s' => \$opt_plate_condition,
    'source_condition=s' => \$opt_source_condition,
    'since=s' => \$opt_since,
);

#############################################
my $dbase        = $opt_dbase || $configs->{PRODUCTION_DATABASE};
my $host         = $opt_host || $configs->{PRODUCTION_HOST};
my $debug = $opt_debug;
my $db_user = 'cron_user';  ## use super_cron_user if requiring write access (or repl_client to run database restoration scripts)

my $plate_condition = $opt_plate_condition || 1;
my $source_condition = $opt_source_condition || 1;
if ($opt_since) { 
    my $time = date_time("-$opt_since");
    $plate_condition .= " AND Plate_Created >= '$time'";
}

## Connect to slave host/dbase if using for read only purposes ##
my $login_file = $FindBin::RealBin . "/../conf/mysql.login";
my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $db_user, -config=>$configs, -login_file=>$login_file);
$dbc->connect();

if (! $dbc->{connected} ) { print "Error connecting to $host.$dbase as $db_user\n"; exit; }

############## End of Standard Template ####################

print "Connected to $host . $dbase successfully as $db_user: " . $dbc->{connected} . "\n";
print "Started: " . date_time();
    print "\n";
    print "*"x50;
    print "\n";

### Attribute IDs ###
       my ($collected)         = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Source' and Attribute_Name = 'collection_time'" );
       my ($stored)         = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Plate' and Attribute_Name = 'first_stored'" );
       my ($ttf)         = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Plate' and Attribute_Name = 'initial_time_to_freeze'" );
   
    ### Update Sample_Collection_Time for Sources if required ###
    my $update_condition = "Collected.Attribute_Value > 0 AND (Source.Sample_Collection_Time = '0' OR Source.Sample_Collection_Time IS NULL)";
    my @update_collection_time = $dbc->Table_find_array(
        "Source LEFT JOIN Source_Attribute as Collected ON FK_Attribute__ID = $collected AND FK_Source__ID=Source_ID",
        ['Source_ID'],
        "WHERE $source_condition",
        );

    my $Scount = int(@update_collection_time);
    print "Update Collection Times\n****************************\n";
    if (!@update_collection_time) { print "No Source records found that require updating\n" }
    else {
        my $fix_sources = join ',', @update_collection_time;
        my $update_command = "UPDATE  Source,Source_Attribute AS Collected SET Source.Sample_Collection_Time = Collected.Attribute_Value WHERE $source_condition AND $update_condition AND FK_Attribute__ID = $collected AND Collected.FK_Source__ID=Source_ID";
        
        my ($fixed_sources, $fixed_progeny) = $dbc->execute_command($update_command);
        print "Updated/Confirmed $fixed_sources collection times for Sources\n";
        print Dumper $fixed_sources, $fixed_progeny;
    }

    ### Update First Storage Time for Plates if required ###
    my ($storage_field) = $dbc->Table_find( 'DBField', 'DBField_ID', "WHERE Field_Name = 'FK_Rack__ID' AND Field_Table = 'Plate'" );
    
    my @update_first_storage = $dbc->Table_find_array(
        "Plate LEFT JOIN Plate_Attribute as Stored ON FK_Attribute__ID=$stored AND FK_Plate__ID=Plate_ID", 
        ['Plate_ID'],
        "WHERE Stored.Attribute_Value IS NULL AND $plate_condition GROUP BY Plate_ID", 
        -debug=>$debug);

    print "Update First Storage Times\n****************************\n";
    if (@update_first_storage) {
        my $fix_storage = join ',', @update_first_storage;
        my $found_plate_storage = Healthbank::Model::update_first_storage_time(-dbc=>$dbc, -plates=>$fix_storage, -condition=>$plate_condition, -debug=>$debug);
        my $count = int(@update_first_storage);
        print "Tried to update $count first storage times for containers\n";
    }
    else {
        print "No Container records found that require first storage time updating\n"; 
    }

    ###  Update Time to Freeze Attribute ###
    my @update_TTF = $dbc->Table_find_array(
        "Plate LEFT JOIN Plate_Attribute as TTF ON FK_Attribute__ID = $ttf AND FK_Plate__ID=Plate_ID",
        ['Plate_ID'],
        "WHERE TTF.Attribute_Value IS NULL AND $plate_condition",
   ); 
   
    if (@update_TTF) {
        my $fix = join ',', @update_TTF;
        ### Run auto_update_time_attributes method ###
        print "Update Time to Freeze Attribute\n****************************\n";
        Healthbank::Model::auto_update_time_attributes(-dbc=>$dbc, -plates=>$fix, -debug=>$debug);
    }
    
    print "Summary:\n***************\n";
    ### Get samples which only require time to freeze to be updated ###
    my $tables = '(Plate, Plate_Sample, Sample, Source)';
    $tables .= " LEFT JOIN Plate_Attribute as Stored ON Plate.Plate_ID=Stored.FK_Plate__ID AND Stored.FK_Attribute__ID=$stored";
    $tables .= " LEFT JOIN Source_Attribute as Collected ON Source.Source_ID=Collected.FK_Source__ID AND Collected.FK_Attribute__ID=$collected";
    $tables .= " LEFT JOIN Plate_Attribute as TTF ON Plate.Plate_ID=TTF.FK_Plate__ID AND TTF.FK_Attribute__ID=$ttf";

# $condition .= " AND TTF.Attribute_Value IS NULL AND Collected.Attribute_Value IS NOT NULL AND Stored.Attribute_Value IS NOT NULL";
    
    my $summary_condition = "$plate_condition AND $source_condition";

    my @current_data = $dbc->Table_find(
        $tables,
        'Plate.Plate_ID, Source_ID, Source.Sample_Collection_Time, Collected.Attribute_Value, Stored.Attribute_Value, TTF.Attribute_Value',
        "WHERE Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample.Sample_ID AND Sample.FK_Source__ID=Source_ID AND $summary_condition",
        -debug=>$debug
    );

    foreach my $data (@current_data) {
        my ($p, $s, $ct, $ca, $st, $ttf) = split ',', $data;
        
        if ($ttf) { $ttf_count++ }
        else { $ttf_missing++ }
        
        if ($debug) {
            $data =~s/\,/\t/g;
            print $data . "\n";
        }
    }
    
    print "$ttf_count Time To Freeze Values Defined\n";
    print "$ttf_missing Time to Freeze Values Missing\n";
    
    print "\nCompleted: " . date_time();
    print "\n";
    print "*"x50;
    print "\n";

    print "Clear empty attributes";
    my $clear = "DELETE FROM Plate_Attribute WHERE FK_Attribute__ID IN ($stored, $ttf) AND (Attribute_Value = '' OR Attribute_Value IS NULL)";
    $dbc->execute_command($clear);
    
    $clear = "DELETE FROM Source_Attribute WHERE FK_Attribute__ID IN ($collected) AND (Attribute_Value = '0' OR Attribute_Value = '' OR Attribute_Value IS NULL)";
    $dbc->execute_command($clear);
    
exit;
