#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

################################################################################
#
# update_lib_list.pl
#
# This program regularly updates the library_list file.
#
################################################################################

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

use SDB::DBIO;    ## use to connect to database

use alDente::Config;    ## use to initialize configuration settings

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);    ### phase out global, but leave in for now .... replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
###############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Setup = new alDente::Config( -initialize => 1, -root => $FindBin::RealBin . '/..' );

my $configs = $Setup->{configs};

%Configs = $configs;      ## phase out global, but leave in for now ....
###################################################
## END OF Standard Module Initialization Section ##
###################################################

## Load input parameter options ##
#
## (replace section below with required input parameters as required) ##
#
use vars qw($opt_host $opt_dbase $opt_debug);
use vars qw($opt_host $opt_dbase $opt_user $opt_v $opt_full %Configs);

use Getopt::Long;
&GetOptions(
    'v'       => \$opt_v,
    'host=s'  => \$opt_host,
    'dbase=s' => \$opt_dbase,
    'user=s'  => \$opt_user,
    'full'    => \$opt_full,    # flag to do a full check of all libraries, otherwise, only libraries obtained today will be checked
    'debug|t' => \$opt_debug,
);

#############################################
my $dbase = $opt_dbase || $configs->{PRODUCTION_DATABASE};
my $host  = $opt_host  || $configs->{PRODUCTION_HOST};
my $test  = $opt_debug;
my $db_user = 'cron_user';      ## use super_cron_user if requiring write access (or repl_client to run database restoration scripts)

## load variables previously stored as globals ##
my $project_dir = $configs->{project_dir};
my $mirror_dir  = $configs->{mirror_dir};
my $archive_dir = $configs->{archive_dir};
my $bioinf_dir  = $configs->{bioinf_dir};
my $URL_cache   = $configs->{URL_cache};

############## End of Standard Template ####################

my $host  = $opt_host  || $Configs{SQL_HOST};
my $dbase = $opt_dbase || $Configs{DATABASE};
my $user  = $opt_user;

my $public_project_dir;       ## removed public mirror... 
my $verbose = $opt_v || 0;    ## only send notification in verbose mode (1 / day)
my %Messages;
my $check_name      = "update_library_list";
my $email_recipient = "aldente";

my $variation = 'basic';
if ($opt_full) { $variation = 'full' }

################# construct Process_Monitor object for writing log ##################
## Enable automatic logging as required ##
my $logfile = $Setup->get_log_file( -ext => 'html', -config => $configs, -type => 'relative' );

my $Report = Process_Monitor->new( -testing => $test, -url => $logfile, -configs => $configs, -force => 1, -variation => $variation );
my $lock = $Report->write_lock();
if ( !$lock ) {
    $Report->set_Message("This script is locked [$lock]");
    $Report->DESTROY();
    exit;
}

## Connect to slave host/dbase if using for read only purposes ##
my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $db_user, -config => $configs );
$dbc->connect();

if ( !$dbc->{connected} ) { print "Error connecting to $host.$dbase as $db_user\n"; exit; }

######### Get default database from login_file configuration settings ########
my $CONFIG;

my @updates = ();

### Update Library subdirectories in alDente Projects directory ###
my @info;
if ($opt_full) {
    @info = &Table_find( $dbc, 'Library,Project', 'Library_Name,Project_Path', "where FK_Project__ID=Project_ID ORDER BY Library_Name" );
}
else {
    my $today = today();
    @info = &Table_find( $dbc, 'Library,Project', 'Library_Name,Project_Path', "where FK_Project__ID=Project_ID and Library_Obtained_Date >= '$today' ORDER BY Library_Name" );
}

my $library_list_file = "$URL_cache/library_list";
my $LIB_LIST;

open my $LIB_LIST, '>', $library_list_file or ( $Report->set_Error("Error opening $library_list_file file.") );

my $checked = 0;
$Report->set_Message( "Inspecting " . scalar(@info) . " Libraries" );
foreach my $lib (@info) {
    $checked++;
    ( my $library, my $localpath ) = split ',', $lib;
    my $project_path = "$project_dir/$localpath";

    print $LIB_LIST "$localpath/$library\n";
    unless ( -e "$project_path" ) {
        $Report->set_Detail("Create project directory for $project_path");
        try_system_command( "mkdir $project_path -m 775 ", -verbose => $verbose, -report => $Report );
        push( @updates, "Added $project_path project directory" );
    }

    unless ( -e "$project_path/$library/AnalyzedData" ) {

        #print "Create AnalyzedData subdirectory for $lib\n";
        $Report->set_Detail("Create AnalyzedData subdirectory for $lib");
        try_system_command( "mkdir $project_path/$library/AnalyzedData -m 774 -p", -verbose => $verbose, -report => $Report );
        push( @updates, "Added $project_path/$library AnalyzedData directory" );
    }

    unless ( -e "$project_path/$library/SampleSheets" ) {

        #print "Create SampleSheets subdirectory for $lib\n";
        $Report->set_Detail("Create SampleSheets subdirectory for $lib");
        try_system_command( "mkdir $project_path/$library/SampleSheets -m 777 -p", -verbose => $verbose );
        push( @updates, "Added $project_path/$library SampleSheet directory" );
    }

    ###############################################################################################
    # add 'published' subdirectories to each project and each library within the project
    unless ( -e "$project_path/published" ) {
        $Report->set_Detail("Create published subdirectory for $project_path");
        try_system_command( "mkdir $project_path/published -m 777 -p", -verbose => $verbose );
        push( @updates, "Added $project_path/ published directory" );
    }
    unless ( -e "$project_path/$library/published" ) {
        $Report->set_Detail("Create published subdirectory for $lib");
        try_system_command( "mkdir $project_path/$library/published -m 777 -p", -verbose => $verbose );
        push( @updates, "Added $project_path/$library published directory" );
    }
    ###############################################################################################

    ## Check for moved or copied (repeated) library directories ##

    my @other_directories = split "\n", try_system_command("ls $project_dir/*/$library -d");
    if ( int(@other_directories) > 1 ) {
        my $update = "Warning: Repeat library directory found in Projects directory: $library\n";
        $update .= join( "\n", @other_directories );
        $Report->set_Warning($update);
        push( @updates, $update );
        for my $directory (@other_directories) {
            if ( $directory ne "$project_path/$library" ) {
                my $fback = try_system_command( "rmdir $directory/AnalyzedData", -verbose => 1 );
                if ( !$fback ) { $fback = "rmdir $directory/AnalyzedData" }
                push( @updates, $fback );
                $fback = try_system_command( "rmdir $directory/published", -verbose => 1 );
                if ( !$fback ) { $fback = "rmdir $directory/published" }
                push( @updates, $fback );
                $fback = try_system_command( "rmdir $directory/SampleSheets", -verbose => 1 );
                if ( !$fback ) { $fback = "rmdir $directory/SampleSheets" }
                push( @updates, $fback );
                $fback = try_system_command( "rmdir $directory", -verbose => 1 );
                if ( !$fback ) { $fback = "rmdir $directory" }
                push( @updates, $fback );
            }
        }
    }
    else {
        $Report->succeeded();

        #  $Report->set_Detail("$library ... ok ...");
        #print "$library ... ok ...\n";
    }

    unless ( $public_project_dir && ( $project_dir ne $public_project_dir ) ) {next}
    ## Make public directories ##

    unless ( -e "$public_project_dir/$localpath/$library/" || $project_dir eq $public_project_dir ) {
        my $sys_command = "mkdir $public_project_dir/$localpath/$library -m 777 -p";
        my $fback = try_system_command( $sys_command, -verbose => $verbose );
        $Report->set_Warning($fback) if $fback;
        push( @updates, "Added Public path: $public_project_dir/$localpath/$library SampleSheet directory" );

        my @other_directories = split "\n", try_system_command("ls $public_project_dir/*/$library -d");
        if ( int(@other_directories) > 1 ) {

            my $update = "Warning: Repeat library subdirectory found in public Projects directory:\n";
            foreach my $dir (@other_directories) {
                $update .= "$dir\n";
            }
            $Report->set_Warning($update);
            push( @updates, $update );
        }
    }
}

close($LIB_LIST);

$Report->set_Message("Checked $checked library paths\n");

### ensure inclusion of all mirror & archive directories for sequence data ###
my %Machine_Info = &Table_retrieve(
    $dbc,
    "Machine_Default,Equipment,Stock,Stock_Catalog,Equipment_Category",
    [ 'Equipment_Name', 'Local_Data_dir' ],
    "where FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Equipment_Category__ID = Equipment_Category_ID and FK_Equipment__ID=Equipment_ID AND Category IN ('Sequencer','Fluorimager') Order by Equipment_Name", "Distinct"
);

#print "Set Local Path for active Hosts:\n";
$Report->set_Detail("Set Local Path for active Hosts:");
my $index = 0;
while ( defined %Machine_Info->{Equipment_Name}[$index] ) {
    my $host = %Machine_Info->{Equipment_Name}[$index];
    my $dir  = %Machine_Info->{Local_Data_dir}[$index];
    if ( ( $host =~ /\S+/ ) && ( $dir =~ /(.*)\/(.*?)$/ ) ) {
        my $volume = $2;

        #print "Host: $host  Path:$dir\n";
        $Report->set_Detail("Host: $host  Path:$dir");
    }
    #### Ensure mirror/archive paths exist ####
    unless ( -e "$mirror_dir/$dir" ) {
        try_system_command( "mkdir $mirror_dir/$dir -p -m 755", -verbose => $verbose );
        push( @updates, "Added $dir machine directory" );
    }
    unless ( -e "$archive_dir/$dir" ) {
        try_system_command( "mkdir $archive_dir/$dir -p -m 755", -verbose => $verbose );
        push( @updates, "Added $dir machine directory" );
    }
    $index++;
}

### Refresh Parameters... ###
$Report->set_Message("Refreshing Parameters...");
&alDente::Tools::initialize_parameters( $dbc, $dbase );

if ( @updates && $verbose ) {
    my $list = join "\n", @updates;
    $Report->set_Detail("Updates Made: $list");
}

$Report->completed();
$Report->DESTROY();
exit;

