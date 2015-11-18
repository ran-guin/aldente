#############################################
#
# $ID$
#
# CVS Revision: $Revision: 1.140 $
#     CVS Date: $Date: 2004/12/03 00:09:19 $
#
##############################################
#
#
# This script contains various Customized Settings for a given Database
#  Application. All settings in this module should come from configuration
#  files under conf/
# Configuration files under conf/ should be configured when running setup.pl
#
# It should include:
#
#    Custom modules required to run the script (if any)
#    Global variables to be used in custom scripts
#    Some standard routines that may be called from the wrapper scrip...
#
#    The following Routines should be Included:
#
#        initialize_variables();  ### initialization of global variables
#        initialize_page();       ### an initialization for the page (may contain banners etc.)
#        preliminary_script();    ### script to be executed before main pages..
#        main_branches();         ### a customized list of branches to custom routines
#        home();                  ### a home page
#        return_to();             ### a routine used to return to specific pages
#        leave();                 ### a general program exiting routine
#        top_icons();             ### generation of icons for the top of the page
#
#  (if you have no need for any of the above, please create an empty routine returning a value of 1);
#
################################################################################
#
# Author           : Ran Guin
#
# Purpose          : Repository for Defaults specifically for use with
#                    mySQL Database Interface
#
# Standard Modules :
#
# Setup Required   : Reset variables below as required...
#
# Usage            : Designed for use with SDB modules:
#                       RGIO, GSDB, DB_Form_Viewer, DB_Record
#
################################################################################
package SDB::CustomSettings;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

CustomSettings.pm - $ID$

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
$ID$<BR>This script contains various Customized Settings for a given Database<BR>Application.<BR>It should include:<BR>Custom modules required to run the script (if any)<BR>Global variables to be used in custom scripts<BR>Some standard routines that may be called from the wrapper scrip...<BR>The following Routines should be Included:<BR>initialize_variables();  ### initialization of global variables<BR>initialize_page();       ### an initialization for the page (may contain banners etc.)<BR>preliminary_script();    ### script to be executed before main pages..<BR>main_branches();         ### a customized list of branches to custom routines<BR>home();                  ### a home page<BR>return_to();             ### a routine used to return to specific pages<BR>leave();                 ### a general program exiting routine<BR>top_icons();             ### generation of icons for the top of the page<BR>(if you have no need for any of the above, please create an empty routine returning a value of 1);<BR>Author           : Ran Guin <BR>Purpose          : Repository for Defaults specifically for use with <BR>mySQL Database Interface <BR>Standard Modules : <BR>Setup Required   : Reset variables below as required...<BR>Usage            : Designed for use with SDB modules:<BR>RGIO, GSDB, DB_Form_Viewer, DB_Record<BR>

=cut

##############################
# superclasses               #
##############################

use SDB::Errors;

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    %Order %Mandatory_fields %FK_View %Validate_condition %Prefix %Unique %Form_Searches %Configs %Configs_Custom $Configs_Non_Custom
    $user $user_id $dbase $nav $login_name $login_pass
    $image_dir $Data_home_dir $Web_home_dir $Web_log_directory  $Data_log_directory
    $mysql_dir $submission_dir $jira_wsdl $jira_link $issue_tracker $config_dir $install_dir $current_dir $login_file $domain $web_home $homefile $homelink $URL_version
    $URL_dir_name $URL_base_dir_name $URL_dir $URL_temp_dir $URL_cgi_dir $URL_address $URL_domain $URL_home $URL_cache $aldente_upload_dir $aldente_runmap_dir
    $testing $style $administrator_email
    $Session $track_sessions $session_id $Sess
    $scanner_mode
    $trace_file $trace_level $dbh $q
    %Defaults %Input %Settings %Std_Parameters %Barcode %Login %User_Setting
    %Benchmark
    $Sys_config_file $Connection $Transaction $Multipage_Form
    $html_header $java_header
    $view_directory
    &_combine_configs
    &_load_custom_config
    &_load_non_custom_config
    &load_lims01
    &define_Term
);

##############################
# standard_modules_ref       #
##############################

# Set standard defaults (generic)
use Storable;
use Cwd;
use Cwd 'abs_path';
use strict;
use Data::Dumper;
##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
####### Generic Database handle, CGI
use vars qw(%Defaults %Input %Settings %Std_Parameters %Barcode %Benchmark %Login %Configs %Configs_Custom $Configs_Non_Custom %User_Setting $login_name $login_pass);
use vars qw($image_dir $Data_home_dir $Web_home_dir $Data_log_directory $Web_log_directory);
use vars qw($mysql_dir $submission_dir $issue_tracker $jira_wsdl $jira_link $config_dir $web_dir $install_dir $current_dir $login_file $domain $web_home $URL_version);
use vars qw($trace_file $trace_level $dbh $q $Sys_config_file $Connection $Transaction $Multipage_Form);
####### URL address variables ###
use vars qw($URL_dir_name $URL_base_dir_name $URL_dir $URL_temp_dir $URL_cgi_dir $URL_address $URL_domain $URL_home $URL_cache);
####### Required by GSDB.pm ########
use vars qw(%Order %Mandatory_fields %Primary_fields %FK_View %Validate_condition %Prefix);
use vars qw($scanner_mode);    ### display mode (=1 for less output)
use vars qw($user $user_id);
####### more variables Required by DB_Form_Viewer.pm #####
use vars qw($homefile $homelink %Form_Searches);
use vars qw($dbase $nav);
use vars qw($testing $style $administrator_email);

#use vars qw(%Plate_Contents);
#### req'd by RGIO.pm
use vars qw($Session $session_id $track_sessions $Sess $html_header $java_header);
#### alDente
use vars qw($uploads_dir $aldente_upload_dir $aldente_runmap_dir $run_maps_dir);
use vars qw($view_directory);

##############################
# modular_vars               #
##############################

##############################
# constants                  #
##############################
my $jsversion  = 'js.3.16';
my $cssversion = 'css.3.16';

##############################
# main_header                #
##############################
my ($local_dir) = $INC{'SDB/CustomSettings.pm'} =~ /^(.*)Core\/(\/)?SDB\/CustomSettings\.pm$/;
###################################################################################################################
### First find configuration dir and the configuration files.
#Get current directory of the install.pl
if ( -l $0 ) {

    #if the file name is indeed a symlink then need to dereference.
    my $realfile = readlink $0;
    $realfile =~ /^(.*)\//;
    $current_dir = $1;
}
elsif ( $0 =~ /^(.*)\// ) {
    $current_dir = $1;
}
else {
    $current_dir = cwd();
}
$config_dir  = abs_path("$local_dir/../../conf");
$install_dir = abs_path("$local_dir/../../install");
$web_dir     = abs_path("$local_dir/../../www");

# This file contain system configurations such as paths.
$Sys_config_file = "$config_dir/system.cfg";
my $Sys_personalize_config_file = "$config_dir/personalize.cfg";

###Load the configurations###

# The configuration hash %Configs comes from 1) system.conf file containing customizable configs (%Configs_Custom) 2) array of hashes defined here containing non-customizable configs ($Configs_Non_Custom)
# %Configs_Custom and $Configs_Non_Custom will be used in setup.pl to modify configs and create directories

### Glossary of Terms & Definitions ##
my $Term_Definitions = {
    'Aliquot'   => 'Transferring a portion of the Sample from one container to another',
    'Transfer'  => 'Transferring entire contents from one container to another (throws out original)',
    'Extract'   => 'Retrieving material of a different type from the current container (eg retrieving RNA from an existing Tissue sample)',
    'AutoFill'  => 'Set &quot&quot cells with value above it (clearing the &quot&quot in any cell will prevent all cells below it from being auto-filled)',
    'ResetForm' => 'Reset field values to original values',
    'ClearForm' => 'Clear all values - will only update values re-entered',
};

##############
## Prefixes ##
##############
#
#  A list of standard prefixes used for specific tables.
#   (These prefixes are used for barcodes, and keys to these fields should be scannable...)
#
## Set in alDente::Config ##

&load_config();    ## phase out ... replace with call from main script with file loaded configs if applicable

##################
sub load_config {
##################
    my $config = shift;

    $config->{Home_public}  = $config->{Data_home_dir} . '/public';
    $config->{Home_private} = $config->{Data_home_dir} . '/private';

    &_init_config($config);
#    &_load_custom_config($config);
    &_load_non_custom_config($config);
    %Configs = %{ &_combine_configs($config) };

    if ($config) {
        foreach my $key ( keys %$config ) {
            $Configs{$key} = $config->{$key};
        }
    }

    return \%Configs;
}

# determine %Confings

###################################################################################################################
$style = 'html';    ### set IO style ('text' or 'html').
################### Standard Settings ####################
$Settings{FOREIGN_KEY_POPUP_MAXLENGTH} = 3000;    ### set to text field if > N
$Settings{RETRIEVE_LIST_LIMIT}         = 200;     ### default limit on retrieved records (editing page)
## colour settings ##
$Settings{STD_BUTTON_COLOUR}        = '#AFFFA1';
$Settings{EXECUTE_BUTTON_COLOUR}    = '#FF0000';
$Settings{SEARCH_BUTTON_COLOUR}     = '#ECFF7A';
$Settings{SCAN_BUTTON_COLOUR}       = 'violet';
$Settings{MESSAGE_COLOUR}           = 'yellow';
$Settings{LINK_COLOUR}              = 'blue';
$Settings{LINK_BLACK}               = 'black';
$Settings{LINK_LIGHT}               = 'yellow';
$Settings{LINK_EXECUTE}             = 'red';
$Settings{DONE_COLOUR}              = 'lightgrey';
$Settings{OLD_COLOUR}               = 'grey';
$Settings{EMPTY_COLOUR}             = 'grey';
$Settings{IP_COLOUR}                = 'yellow';         ## replace IP_COLOUR with HIGHLIGHT_COLOUR
$Settings{HIGHLIGHT_WAITING_COLOUR} = 'yellow';
$Settings{HIGHLIGHT_READY_COLOUR}   = 'lightgreen';
$Settings{START_COLOUR}             = 'lightgreen';
$Settings{WARNING_COLOUR}           = 'orange';
$Settings{ERROR_COLOUR}             = 'red';
$Settings{LIGHT_BKGD}               = "#d8d8d8";
$Settings{WHITE_BKGD}               = "#FFFFFF";
$Settings{HEADER_COLOUR}            = '#6699ff';
$Settings{HIGHLIGHT_CLASS}          = "lightredbw";
$Settings{SUBHEADER_CLASS}          = "lightgreenbw";
$Settings{HEADER_CLASS}             = 'lightbluebw';
$Settings{PAGE_WIDTH}               = '1100';
$Settings{TEXTFIELD_SIZE}           = 20;
$Settings{BIG_TEXTFIELD_SIZE}       = 20;
$Settings{SMALL_TEXTFIELD_SIZE}     = 5;
$Settings{DATEFIELD_SIZE}           = 12;
$Settings{DATETIMEFIELD_SIZE}       = 20;
$Settings{SCANFIELD_SIZE}           = 10;
################### User Settings ########################
# these are retrieved from the Database if specified (from Session module)
################### Standard Defaults ####################

$Defaults{DEFAULT_LOCATION} = "1";    # Default location (rac id) when the actual location is unknown
######### Barcoded Items ###########
$Barcode{Equipment} = 1;
$Barcode{Employee}  = 1;
$Barcode{Plate}     = 1;
$Barcode{Tube}      = 1;
$Barcode{Solution}  = 1;
$Barcode{Rack}      = 1;
$Barcode{Source}    = 1;
################### Also set standard Input, but generate in script #########
#
#  $Input{} = ..
#
$Input{Dbase} = 'sequence';    ### set as default
####################################################################
# SET VARIABLES: mysql_dir, domain, web_home, homelink, homefile
####################################################################
#Be
# this is the filename containing database, user, and password information
# login_file format: "database:(database_name)\nuser:(user_name)\nkey:(password)
$login_file = "$config_dir/mysql.login";
### Local Directories ###
$image_dir = "images/png";     ### images as accessed from the URL...

my $Home_dir;

#########################
sub _init_config {
#########################
    my $config = shift;

    my $host = $ENV{'SERVER_ADDR'};

    $Defaults{DATABASE}        = $config->{DATABASE};
    $Defaults{TEST_DATABASE}   = $config->{TEST_DATABASE};
    $Defaults{BACKUP_DATABASE} = $config->{BACKUP_DATABASE};
    $Defaults{SQL_HOST}        = $config->{SQL_HOST};
    $Defaults{mySQL_HOST}      = $config->{mySQL_HOST};
    $Defaults{BACKUP_HOST}     = $config->{BACKUP_HOST};

    $Home_dir           = $Configs{Home_dir}          || $config->{Home_dir};
    $Data_home_dir      = $Configs{Data_home_dir}     || $config->{Data_home_dir};                 ### universally accessible ...
    $Web_home_dir       = $Configs{Web_home_dir}      || $config->{Web_home_dir};                  ### local to webserver only...
    $Data_log_directory = $Configs{Data_log_dir}      || $config->{Data_log_dir};                  # place data files in here...
    $mysql_dir          = $Configs{mysql_dir}         || $config->{mysql_dir};                     ### location of mysql binary directory
    $URL_domain         = $Configs{URL_domain}        || $config->{URL_domain};                    ### primary domain for url
    $URL_home           = $Configs{URL_home}          || $config->{URL_home};
    $URL_base_dir_name  = $Configs{URL_base_dir_name} || $config->{URL_base_dir_name} || 'SDB';    ### a specification for the URL indicating version (may be *_last or *_test) ###
    $URL_dir            = $Configs{URL_dir}           || $config->{URL_dir};                       ### the path to files to be accessed via the URL (static AND dynamic paths ?)
    $URL_cgi_dir        = $Configs{URL_cgi_dir}       || $config->{URL_cgi_dir};
    $URL_temp_dir       = $Configs{URL_temp_dir}      || $config->{URL_temp_dir};
    $URL_cache          = $Configs{URL_cache}         || $config->{URL_cache};
    $URL_address        = $Configs{URL_address}       || $config->{URL_address};                   ### local URL for web directory
    $Web_log_directory  = $Configs{Web_log_dir}       || $config->{Web_log_dir};                   # place web log files in here...
    $submission_dir     = $Configs{submission_dir}    || $config->{submission_dir};
    $jira_wsdl          = $Configs{jira_wsdl}         || $config->{jira_wsdl};
    $jira_link          = $Configs{jira_link}         || $config->{jira_link};
    $issue_tracker      = $Configs{issue_tracker}     || $config->{issue_tracker};

    $homefile = $0;                                                                                ##### a pointer back to the executable file
    ### Custom modifications ###
    $URL_dir_name = $URL_base_dir_name;                                                            #Save the base name of the URL_dir.
    $URL_version  = 'Unknown';

    # =~s /\/$URL_dir_name\//\/$URL_dir_name\_test\//} ### link to beta version

    my $path;
    if ( $ENV{'SCRIPT_NAME'} ) {
        $path = $ENV{'SCRIPT_NAME'};
    }
    else {
        $0 =~ /^\.(.*)/;
        $path = cwd();
        $path = "$path$1";
    }

    if ( $path =~ /\/SDB\// ) { $URL_version = 'Production'; }
    elsif ( $path =~ /SDB_last/ ) { $URL_dir_name .= "_last"; $URL_version = 'Last'; }
    elsif ( $path =~ /SDB_beta/ ) { $URL_dir_name .= "_beta"; $URL_version = 'Beta'; }
    elsif ( $path =~ /SDB_test/ ) { $URL_dir_name .= "_test"; $URL_version = 'Test'; }
    ## <CONSTRUCTION> if runs from other than versions this will break
    elsif ( $path =~ /\/SDB_([\w\.]+)\// ) { $URL_dir_name .= "_" . $1; $URL_version = 'Dev'; }

    ## add section below since previously config settings in beta were pointing to production directories ...
    foreach my $key ( keys %Configs ) {
        if ( $Configs{$key} =~ /^\/SDB\// ) { $Configs{$key} =~ s /^\/SDB\//\/$URL_dir_name\// }
    }

    ### don't use below... ?
    #if ($0=~/Beta/) {$URL_dir_name =~s /\/$URL_dir_name\//\/$URL_dir_name\_test\//} ### link to beta version
    #if ($0=~/Last_Version/) {$URL_dir_name =~s /\/$URL_dir_name\//\/$URL_dir_name\_last\//} ### link to last version
    $URL_address = $URL_domain . "/$URL_dir_name/cgi-bin";    ### local URL for web directory
    $URL_cgi_dir = "$URL_home/$URL_dir_name/cgi-bin";

    $Configs{URL_dir_name} = $URL_dir_name;                   ## reset configuration variable
    $config->{URL_dir_name} = $URL_dir_name;                  ## reset configuration variable

    #$Configs{version_name} = $URL_version;

    $view_directory = "$Configs{'Home_public'}/views";

    #$aldente_runmap_dir = "/home/sequence/alDente/run_maps";
    $aldente_upload_dir = $uploads_dir;

    if ( $homefile =~ m|/([\w_]+[.pl]{0,3})$| ) {
        my $localfile = $1;
        $localfile =~ s/(.*)_test(.*)/$1$2/;                  ### convert back to original name...
        $localfile =~ s/(.*)_last(.*)/$1$2/;                  ### convert back to original name...
        $homefile = "$URL_address/$localfile";
    }
    elsif ( $homefile =~ m|/([\w_]+)$| ) {
        my $localfile = $1;
        $localfile =~ s/(.*)_last(.*)/$1$2/;                  ### convert back to original name...
        $homefile = "$URL_address/$localfile";
    }
}
####################################################################
### Other directory settings...
####################################################################
####################################################################
####################################################################
# SET VARIABLES: administrator_email, trace_file, $trace_level
####################################################################
$administrator_email = 'rguin@bcgsc.ca,echuah@bcgsc.ca,mariol@bcgsc.ca,jsantos@bcgsc.ca,rsanaie@bcgsc.ca';
my $time = localtime();
$trace_file  = "$Web_log_directory/traces/trace_$time";
$trace_level = 0;                                         ### set to 0 for no storage of trace data (takes lots of storage)
### set to 2 for detailed trace

##########################################################################################
# SET VARIABLES: %Order, %Mandatory_Fields, %Primary_fields %FK_Views, %Prefix
##########################################################################################
############## This provides the default Ordering for various views...
%Order = (
###############
    Protocol_Tracking => "Protocol_Tracking_Order,Protocol_Tracking_Title,Protocol_Tracking_Status",
);

####################  This may be generated easily automatically...
%Primary_fields = (
####################
    Clone_Sequence => "FK_Run__ID",
    Cross_Match    => "Cross_Match_ID",
    Data           => "Data_ID",
    Equipment      => "Equipment_ID",
    Employee       => "Employee_ID",
    Solution       => "Solution_ID",
    Plate          => "Plate_ID",

    #		   Protocol => "Protocol_ID",
    Primer       => "Primer_ID",
    Vector_Type  => "Vector_Type_ID",
    Vector       => "Vector_ID",
    Run          => "Run_ID",
    RunBatch     => "RunBatch_ID",
    Library      => "Library_Name",
    Project      => "Project_ID",
    Mixture      => "Mixture_ID",
    Organization => "Organization_ID",
    Plate_Set    => "Plate_Set__ID",
    Maintenance  => "Maintenance_ID",
    Plate_Format => "Plate_Format_ID",
    Plate_Set    => "Plate_Set_ID",
    FK_View      => "FK_View_ID",
    Pool         => "Pool_ID",
    Contact      => "Contact_ID",

    #		   Person=>"Person_ID",
    Vector_TypePrimer => "Vector_TypePrimer_ID",
);

######################
## Mandatory Fields ##
######################
#
################################################################################
#  List of fields that MUST be entered (checked in validation process)
################################################################################
#
%Mandatory_fields = (

    #Box => "FK_Rack__ID",
    #     Chemistry_Code => "Chemistry_Code_Name",
    Issue => 'Priority',

    #Equipment => "Equipment_ Type",
    Library               => "FK_Project__ID,FK_Grp__ID,FK_Contact__ID",
    Library_Plate         => "FK_Plate__ID",
    Mapping_Library       => 'FK_Vector_Based_Library__ID,DNA_Shearing_Method',
    Grp                   => 'Grp_Name,FK_Department__ID,Access',
    Grp_Relationship      => 'FKBase_Grp__ID,FKDerived_Grp__ID',
    GrpDBTable            => 'FK_Grp__ID,FK_DBTable__ID,Permissions',
    GrpEmployee           => 'FK_Grp__ID,FK_Employee__ID',
    GrpLab_Protocol       => 'FK_Grp__ID,FK_Lab_Protocol__ID',
    GrpStandard_Solution  => 'FK_Grp__ID,FK_Standard_Solution__ID',
    Lab_Protocol          => "Lab_Protocol_Name",
    Library_Container     => "Library_Container_Type,FK_Rack__ID,FK_Barcode_Label__ID",
    Library_Pool          => 'Library_Pool_Type',
    LibraryStudy          => 'FK_Library__Name,FK_Study__ID',
    Library               => 'Library_Type,Library_Obtained_Date,FK_Project__ID,Library_FullName,FKCreated_Employee__ID,FK_Grp__ID',
    Maintenance_Protocol  => "FK_Service__Name,Step,Maintenance_Step__Name",
    Orders                => "Orders_Item,Orders_Quantity,FK_Account__ID,FK_Funding__Code,Req_Number",
    Plate                 => "FK_Library__Name,FK_Plate_Format__ID,Plate_Status",
    Pool                  => 'FKPool_Library__Name,Pool_Type',
    PoolSample            => 'FK_Plate__ID,FK_Pool__ID',
    Primer                => "Primer_Name",
    Primer_ReArray        => "Primer_Type,Oligo_Direction",
    Project               => "FK_Funding__ID",
    ProjectStudy          => 'FK_Project__ID,FK_Study__ID',
    Protocol_Step         => 'FK_Lab_Protocol__ID,Protocol_Step_Name,Protocol_Step_Number',
    Rack                  => "FK_Equipment__ID,Rack_Name,Rack_Type",
    ReArray               => "Source_Well,Target_Well,FK_ReArray_Request__ID",
    ReArray_Request       => "ReArray_Status,FK_Employee__ID,ReArray_Type,ReArray_Format_Size",
    Original_Source_Stage => 'Stage_Name',
    Original_Source_Type  => 'Original_Source_Type_Name',
    Original_Source       => 'Original_Source_Name,FK_Contact__ID',
    SAGE_Library          => 'FK_Vector_Based_Library__ID,FKInsertSite_Enzyme__ID,FKAnchoring_Enzyme__ID,FKTagging_Enzyme__ID,Concatamer_Size_Fraction,Clones_100to500Insert_Percent,Clones_500PlusInsert_Percent,Tags_Requested',
    Run                   => "Run_Type",
    RunBatch              => "FK_Equipment__ID,FK_Employee__ID",
    Vector_Based_Library  => 'FK_Library__Name,Vector_Based_Library_Type',
    Solution              => "FK_Rack__ID",
    Source                => 'Source_Type,FK_Original_Source__ID,Received_Date,FKReceived_Employee__ID,FK_Rack__ID,FK_Barcode_Label__ID,Source_Status',
    Stock                 => "Stock_Number_in_Batch,FK_Grp__ID,FK_Barcode_Label__ID",
    Study                 => 'Study_Name',
    Transposon_Pool       => 'FK_Pool__ID,FK_Transposon__ID,Pipeline',
    Tube                  => 'FK_Plate__ID',
    Vector                => "",
    Vector_TypePrimer     => 'FK_Vector_Type__ID,FK_Primer__ID,Direction'
);

##############
## FK_Views ##
##############
#
#  A list of parameters to display by default when specific Fields are being referenced...
#   (often, but not necessarily used to display foreign key information)
#
#  (Note: Barcoded tables have IDs included automatically)
#
%FK_View = (

    #	    Antibiotic_ID => "Antibiotic_Name",
    Rack_ID              => "Rack_Alias",
    Plate_ID             => "concat(FK_Library__Name,'-',Plate_Number,Parent_Quadrant)",
    Equipment_ID         => "concat(Equipment_Name,' (EQU',Equipment_ID,')')",
    Library_Name         => "CASE WHEN LENGTH(Library_FullName) > 0 THEN Library_Name ELSE concat(Library_Name,':',Library_FullName) END",
    Solution_ID          => "concat('Sol',Solution_ID,': ',Solution_Number,'/',Solution_Number_in_Batch)",
    Box_ID               => "concat('Box',Box_ID,': ',Box_Number,'/',Box_Number_in_Batch)",
    Employee_ID          => "Employee_Name",
    Plate_Set_Number     => "Plate_Set_Number",
    Run_ID               => "Run_Directory",
    Funding_Code         => "Funding_Code",
    Organization_ID      => "Organization_Name",
    Funding_ID           => "Funding_Name",
    Project_ID           => "Project_Name",
    Account_ID           => "concat(Account_ID, ' (',Account_Name,')')",
    Funding_Code         => "concat(Funding_Code,': ',Funding_Name)",
    Stock_ID             => "Stock_ID",                                                                                                      ## leave out Stock ID to allow name to be shown in Sol...
    Solution_Info_ID     => "Solution_Info_ID",
    Orders_ID            => "Orders_ID, Orders_Item",
    Standard_Solution_ID => "Standard_Solution_Name",
    Vector_Type_ID       => "Vector_Type.Vector_Type_Name",
    Note_ID              => "concat(Note_ID,': ',Note_Text)",

    #	    Tube_ID => "Tube_Status",
    Plate_Format_ID => "CASE WHEN Well_Capacity_mL > 0 THEN concat(_mL,' mL ',Plate_Format_Type) ELSE Plate_Format_Type END",

    #	    Tube_ID => "Tube_Status,FK_Library__Name",
    Lab_Protocol_ID   => "Lab_Protocol_Name",
    Protocol_Step_ID  => "concat(Protocol_Step_ID,': ',Protocol_Step_Number,'-',Protocol_Step_Name",
    Solution_Info_ID  => "concat(Solution_Info_ID,': ',ODs,'ODs ',nMoles,'nM ',micrograms,'ug')",
    Contamination_ID  => "Contamination_Alias",
    Field_ID          => "Field_Name",
    Contact_ID        => "Contact_Name",
    Sequencer_Type_ID => "Sequencer_Type_Name",
    SS_Config_ID      => "concat(FK_Sequencer_Type__ID,': ',SS_Alias)",
    SS_Option_ID      => "concat(FK_SS_Config__ID,': ',SS_Option_Alias)",
    DBTable_ID        => 'DBTable_Name',

    #DBField_ID => "concat(FK_DBTable__ID,'.',Field_Name)",
    DBField_ID               => "Field_Name",
    Barcode_Label_ID         => 'Label_Descriptive_Name',
    DB_Form_ID               => "concat(DB_Form_ID,': ',Form_Table)",
    Department_ID            => "Department_Name",
    Grp_ID                   => "Grp_Name",
    Enzyme_ID                => "concat(Enzyme_ID,': ',Enzyme_Name)",
    Transposon_ID            => "concat(Transposon_ID,': ',Transposon_Name)",
    Original_Source_ID       => "concat(Original_Source_ID,': ', Original_Source_Name)",
    Source_ID                => "concat(Source_Type,'-',Source_Number)",
    Agilent_Assay_ID         => "concat(Agilent_Assay_ID,' : ',Agilent_Assay_Name)",
    Vector_Based_Library_ID  => "concat(Vector_Based_Library_ID,': ',FK_Library__Name)",
    Lab_Protocol_ID          => "Lab_Protocol_Name",
    Attribute_ID             => "Attribute_Name",
    Sample_ID                => 'Sample_Name',
    Issue_ID                 => "CONCAT(Issue_ID,': ',LEFT(Description,60),'...')",
    Location_ID              => 'Location_Name',
    WorkPackage_ID           => 'WP_Name',
    Original_Source_Type_ID  => 'Original_Source_Type_Name',
    Original_Source_Stage_ID => 'Stage_Name',
    Prep_ID                  => "concat(Prep_Name,': ',Prep_DateTime)",
    Study_ID                 => "Study_Name",
    UseCase_Step_ID          => "concat(UseCase_Step_ID,' : ',UseCase_Step_Title)",
    UseCase_ID               => "concat(UseCase_ID,' : ',UseCase_Name)",
    Object_Class_ID          => "Object_Class",
    Antibiotic_ID            => "Antibiotic_Name",
    Goal_ID                  => "Goal_Name",
    Organism_ID              => "Organism_Name",

    Genechip_Type_ID => "Name",
    Pipeline_ID      => "concat(Pipeline_Code,': ',Pipeline_Name)",
    ## <CONSTRUCTION> - why is the tissue_Id not showing up properly ??
);

my %Unique = (
    Clone_Sequence => "FK_Run__ID,Well",
    Employee       => "Initials",
);

my %Description = (
    Run            => 'Records of Sequence Runs on Plates',
    Clone_Sequence => 'Results of Sequence Runs on each Clone',
    Plate          => '96-well and 384-well Laboratory Plates',
    Equipment      => 'Laboratory Equipment (Machines, Freezers, etc.)',
    Employee       => 'Employee Information',
    Maintenance    => 'Tracking of Service/Repairs to Equipment',
    Protocol       => 'Detailed Protocols for Laboratory',
    Vector         => 'List of available/used Vectors associated with Libraries',
    Library        => 'List of Libraries consisting of multiple Plates',
    Project        => 'Specific Projects containing multiple Libraries',
);

##############
## Library Types ##
##############
#
# Types of samples available for a library type
#
#$Plate_Contents{Sequencing_Library} = { 'Plate_Content_Type' => 'Clone' };

#Plate_Contents{RNA_Library} = {'Plate_Content_Type' => ['DNA','RNA','Protein','Mixed','Amplicon']}; old list
#$Plate_Contents{RNA_Library}
#    = { 'Plate_Content_Type' => [ 'DNA', 'RNA', 'Protein', 'Mixed', 'Amplicon', 'mRNA', 'Tissue', 'Cells', 'RNA - DNase Treated', 'cDNA', '1st strand cDNA', 'Amplified cDNA', 'Ditag', 'Concatemer - Insert', 'Concatemer - Cloned' ] };

###################
## Form Searches ##
###################
#
# A list of searches that will include foreign tables in search forms
#
# This should be replaced eventually by information within DBTable which implies this more effectively
#
#####################################

# Stock items
$Form_Searches{Box} = {
    'tables'         => [ 'Box',   'Stock',           'Stock_Catalog' ],
    'include_fields' => [ 'Box.*', 'Stock_Catalog.*', 'Stock.*' ]
};
$Form_Searches{Solution} = {
    'tables'         => [ 'Solution',   'Stock',           'Stock_Catalog' ],
    'include_fields' => [ 'Solution.*', 'Stock_Catalog.*', 'Stock.*' ]
};
$Form_Searches{Equipment} = {
    'tables'         => [ 'Equipment',   'Stock',           'Stock_Catalog' ],
    'include_fields' => [ 'Equipment.*', 'Stock_Catalog.*', 'Stock.*' ]
};
$Form_Searches{Stock} = {
    'tables'         => [ 'Stock',   'Stock_Catalog' ],
    'include_fields' => [ 'Stock.*', 'Stock_Catalog.*' ]
};
$Form_Searches{Library} = {
    'tables'         => [ 'Library',   'Project' ],
    'include_fields' => [ 'Library.*', 'Project.*' ]
};
$Form_Searches{PCR_Product_Library} = {
    'tables'         => [ 'Library',   'Project',   'PCR_Product_Library' ],
    'include_fields' => [ 'Library.*', 'Project.*', 'PCR_Product_Library.*' ]
};
$Form_Searches{RNA_DNA_Collection} = {
    'tables'         => [ 'Library',   'Project',   'RNA_DNA_Collection' ],
    'include_fields' => [ 'Library.*', 'Project.*', 'RNA_DNA_Collection.*' ]
};
$Form_Searches{Vector_Based_Library} = {
    'tables'         => [ 'Library',   'Project',   'Vector_Based_Library' ],
    'include_fields' => [ 'Library.*', 'Project.*', 'Vector_Based_Library.*' ],
    'exclude_fields' => ['Vector_Based_Library.FK_Vector__ID']
};

$Form_Searches{Library_Plate} = {
    'tables'         => [ 'Plate',   'Library_Plate' ],
    'include_fields' => [ 'Plate.*', 'Library_Plate.*' ]
};
$Form_Searches{Tube} = {
    'tables'         => [ 'Plate',   'Tube' ],
    'include_fields' => [ 'Plate.*', 'Tube.*' ]
};

$Form_Searches{Original_Source} = {
    'tables'         => [ 'Original_Source',   'Anatomic_Site',   'Taxonomy',   'Stage' ],
    'include_fields' => [ 'Original_Source.*', 'Anatomic_Site.*', 'Taxonomy.*', 'Stage.*' ]
};

######################
# HTML/Java headers
######################
### used in html_header AND Initialize_page
$java_header
    = "\n<!------------ JavaScript ------------->\n"
    . "\n<script src='/$URL_dir_name/$jsversion/FormNav.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/calendar.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/SDB.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/form.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/onmouse.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/json.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/Prototype.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/alttxt.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/DHTML.js'></script>\n"

    #. "\n<script src='/$URL_dir_name/js/jquery.js'></script>\n"
    . "\n<script src='/$URL_dir_name/$jsversion/jquery-custom.js'></script>\n" . "\n<script src='/$URL_dir_name/$jsversion/jquery-ui-custom.js'></script>\n" . "<script type=\"text/javascript\">\n" . "jQuery.noConflict();\n" . "</script>";

$html_header
    = "\n<META HTTP-EQUIV='Pragma' CONTENT='no-cache'>\n"
    . "\n<META HTTP-EQUIV='Expires' CONTENT='-1'>\n"
    . "\n<!------------ Style Sheets ------------->\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/FormNav.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/calendar.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/style.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/cssmenu.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/colour.css'>\n"
    . "\n<LINK rel=stylesheet type='text/css' href='/$URL_dir_name/$cssversion/jquery-ui-custom.css'>\n";

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#####################
sub barcode_prefix {
#####################
    my $class = shift;

    if ($class) { return $Prefix{$class} }

}

#####################
sub barcode_class {
#####################
    my $barcode = shift;

    my @classes;
    foreach my $class ( keys %Prefix ) {
        my $prefix = $Prefix{$class};
        if ( $barcode =~ /\b$prefix\d+/i ) { push @classes, $class }
    }

    return @classes;
}

##############################
sub _load_custom_config {
##############################
    #
    # Load customizable configs from system.conf file
    #
    my %core_configs;
    my %personalize_configs;
    my %custom_configs;
        
#    eval "require XML::Simple";
    eval "require YAML";
    ## Load Standard Configuration Variables ##
    if ( -f $Sys_config_file ) {
#        my $data = XML::Simple::XMLin("$Sys_config_file");
        my $data = YAML::LoadFile($Sys_config_file);
        %core_configs = %{$data};
    }
    else {
        die "no sys config file $Sys_config_file found\n";
    }

    ## Load Personalized Configuration Variables ##

    if ( -f $Sys_personalize_config_file ) {
#        my $data = XML::Simple::XMLin("$Sys_personalize_config_file");
        my $data = YAML::LoadFile("$Sys_personalize_config_file");
        %personalize_configs = %{$data};
    }
    else {

        # ("no personalize sys config file $Sys_personalize_config_file found\n");
    }

    if ( $personalize_configs{custom}{value} ) {
        my $custom_path = $config_dir . "/../custom/" . $personalize_configs{custom}{value} . '/conf/';

        ### GET Custom Configuration variables ###
        my $custom_conf_file = $custom_path . "system.cfg";
        
        require YAML;
        if ( -f $custom_conf_file ) {
 #           my $data = XML::Simple::XMLin("$custom_conf_file");
            my $data = YAML::LoadFile("$custom_conf_file");
            %custom_configs = %{$data};
        }
        else {
            die "no custom sys config file $custom_conf_file found\n";
        }

        my $custom_prefixes = $custom_configs{prefix};
        if ($custom_prefixes) {
            foreach my $object ( keys %$custom_prefixes ) {
                $Prefix{$object} = $custom_prefixes->{$object}{value};
            }
        }
    }

    %Configs_Custom = ( %core_configs, %personalize_configs, %custom_configs );
    return;
}

###################################
sub load_lims01 {
###################################
    #
    # non_customizable directories requiring backup_host group
    #
    my %Configs_lims01 = (
        'URL_dir'           => 1,
        'Web_log_dir'       => 1,
        'URL_temp_dir'      => 1,
        'session_dir'       => 1,
        'run_map_dirs'      => 1,
        'submission_dir'    => 1,
        'URL_cache'         => 1,
        'Stats_dir'         => 1,
        'pending_sequences' => 1,
    );
    return \%Configs_lims01;
}

################################
sub _load_non_custom_config {
################################
    #
    # Load non_customizable configs (relative directories)
    #
    # The order of this array is important. Please do not change.
    # If you want to add new configs, check if your root ({xxx}) directory/node is already defined.
    # If you are defining a directory, you need to specify permission

    $Configs_Non_Custom = [
        { 'perl_dir' => { 'value' => $local_dir, } },

        # root: SQL_HOST
        { 'mySQL_HOST' => { 'value' => '{SQL_HOST},', } },
        { 'homelink'   => { 'value' => $homelink,
                } },

        # root: Web_home_dir
        {   'URL_dir' => {
                'value'      => '{Web_home_dir},/dynamic',
                'permission' => '0755',                      # in backup_host group
            }
        },
        {   'URL_home' => {
                'value'      => '{Web_home_dir},',
                'permission' => '0755',
            }
        },
        {   'web_doc_dir' => {
                'value'      => '{Web_home_dir},/htdocs/docs',
                'permission' => '0775',
            }
        },

        # root: URL_dir (in backup_host group)
        {   'Web_log_dir' => {
                'value'      => '{URL_dir},/logs',
                'permission' => '0755',
            }
        },
        {   'URL_temp_dir' => {
                'value'      => '{URL_dir},/tmp',
                'permission' => '0777',
            }
        },
        {   'run_maps_dir' => {
                'value'      => '{URL_dir},/run_maps',
                'permission' => '0775',
            }
        },
        {   'views_dir' => {
                'value'      => '{URL_dir},/views',
                'permission' => '0755',
            }
        },

        {   'session_dir' => {
                'value'      => '{URL_dir},/sessions',
                'permission' => '0777',
            }
        },

        # <CONSTRUCTION> add _dir to indicate directory
        {   'URL_cache' => {
                'value'      => '{URL_dir},/cache',
                'permission' => '0775',
            }
        },

        # root: URL_dir_name
        { 'URL_address' => { 'value' => '{URL_dir_name},/cgi-bin', } },
        {   'URL_home_URL_dir' => {
                'value'      => '{URL_home},/,{URL_dir_name}',
                'permission' => '0775',
            }
        },
        {   'URL_cgi_dir' => {
                'value'      => '{URL_home},/,{URL_dir_name},/cgi-bin',
                'permission' => '0755',
            }
        },

        # root: URL_cache (group backup_host)
        {   'Stats_dir' => {
                'value'      => '{URL_cache},',
                'permission' => '0775',
            }
        },

        # root: Web_log_dir (group backup_host)
        {   'pending_sequences' => {
                'value'      => '{Web_log_dir},/pending_sequences',
                'permission' => '0755',
            }
        },

        # root: Data_home_dir
        {   'mirror_dir' => {
                'value'      => '{Data_home_dir},/mirror',
                'permission' => '0777',
            }
        },
        {   'archive_dir' => {
                'value' => '{Data_home_dir},/archive',
                ,
                'permission' => '0775',
            }
        },
        {   'Home_public' => {
                'value'      => '{Data_home_dir},/public',
                'permission' => '0775',
            }
        },
        {   'Home_private' => {
                'value'      => '{Data_home_dir},/private',
                'permission' => '0775',
            }
        },

        # root: Home_public
        {   'uploads_dir' => {
                'value'      => '{Home_public},/uploads',
                'permission' => '0777',
            }
        },

        {   'fasta_dir' => {
                'value'      => '{Home_public},/FASTA',
                'permission' => '0777',
            }
        },
        {   'qpix_dir' => {
                'value'      => '{Home_public},/QPIX',
                'permission' => '0777',
            }
        },
        {   'bioinf_dir' => {
                'value'      => '{Home_public},/bioinformatics',
                'permission' => '0777',
            }
        },
        {   'multiprobe_dir' => {
                'value'      => '{Home_public},/multiprobe',
                'permission' => '0777',
            }
        },
        {   'public_log_dir' => {
                'value'      => '{Home_public},/logs',
                'permission' => '0777',
            }
        },
        {   'session_archive' => {
                'value'      => '{Home_private},/sessions',
                'permission' => '0775',
            }
        },
        {   'API_logs' => {
                'value'      => '{public_log_dir},/API_logs',
                'permission' => '0777',
            }
        },
        {   'collab_sessions_dir' => {
                'value'      => '{Home_private},/collab_sessions',
                'permission' => '0777',
            }
        },
        {   'submission_dir' => {
                'value'      => '{Home_public},/submissions',
                'permission' => '0777',
            }
        },
        {   'share_dir' => {
                'value'      => '{Home_public},/share',
                'permission' => '0777',
            }
        },
        {   'upload_template_dir' => {
                'value'      => '{URL_dir},/Upload_Template',
                'permission' => '0771',
            }
        },
        {   'manifest_logs' => {
                'value'      => '{Web_log_dir},/manifests',
                'permission' => '0775',
            }
        },
        {   'shipment_logs' => {
                'value'      => '{Web_log_dir},/shipments',
                'permission' => '0775',
            }
        },

        # root: Home_private
        {   'reference_dir' => {
                'value'      => '{Home_public},/reference',
                'permission' => '0775',
            }
        },
        {   'vector_dir' => {
                'value'      => '{Home_public},/reference/vector',
                'permission' => '0775',
            }
        },
        {   'protocols_dir' => {
                'value'      => '{Home_private},/Protocols',
                'permission' => '0775',
            }
        },
        {   'bulk_email_dir' => {
                'value'      => '{Home_private},/bulk_email',
                'permission' => '0775',
            }
        },
        {   'ttr_files_dir' => {
                'value'      => '{Home_private},/TTR_files',
                'permission' => '0775',
            }
        },
        {   'Data_log_dir' => {
                'value'      => '{Home_private},/logs',
                'permission' => '0771',
            }
        },
        {   'tag_validation_dir' => {
                'value'      => '{Data_log_dir},/tag_validation',
                'permission' => '0775',
            }
        },
        {   'Code_Update_dir' => {
                'value'      => '{Home_dir},/update_logs',
                'permission' => '0777',
            }
        },
        {   'Sys_monitor_dir' => {
                'value'      => '{Home_private},/logs/sys_monitor',
                'permission' => '0777',
            }
        },
        {   'updates_logs_dir' => {
                'value'      => '{Data_log_dir},/updates',
                'permission' => '0771',
            }
        },
        {   'Dump_dir' => {
                'value'      => '{Home_private},/dumps',
                'permission' => '0771',
            }
        },
        {   'temp_dir' => {
                'value'      => '{Home_private},/temp',
                'permission' => '0775',
            }
        },
        {   'inventory_dir' => {
                'value'      => '{Home_private},/Inventory',
                'permission' => '0771',
            }
        },
        {   'inventory_test_dir' => {
                'value'      => '{Home_private},/Inventory/test',
                'permission' => '0775',
            }
        },
        {   'sample_files_dir' => {
                'value'      => '{Home_private},/sample_files',
                'permission' => '0775',
            }
        },
        {   'project_dir' => {
                'value'      => '{Home_private},/Projects',
                'permission' => '0771',
            }
        },
        {   'cluster_jobs_dir' => {
                'value'      => '{Home_private},/Cluster_Jobs',
                'permission' => '0771',
            }
        },
        {   'data_submission_dir' => {
                'value'      => '{Home_private},/Submissions',
                'permission' => '0771',
            }
        },
        {   'data_submission_log_dir' => {
                'value'      => '{data_submission_dir},/volume_logs',
                'permission' => '0771',
            }
        },
        {   'data_submission_config_dir' => {
                'value'      => '{data_submission_dir},/templates',
                'permission' => '0771',
            }
        },
        {   'data_submission_SRA_dir' => {
                'value'      => '{data_submission_dir},/Short_Read_Archive',
                'permission' => '0771',
            }
        },
        {   'data_submission_workspace_dir' => {
                'value'      => '/projects/prod_scratch1/lims',
                'permission' => '0771',
            }
        },

        # root: Data_log_dir
        {   'data_log_dir' => {
                'value'      => '{Data_log_dir},',
                'permission' => '0775',
            }
        },

        # root: public_log_dir
        {   'qpix_log_dir' => {
                'value'      => '{public_log_dir},/QPix_logs',
                'permission' => '0777',
            }
        },

        {   'yield_reports_dir' => {
                'value'      => '{public_log_dir},/Yield_Reports',
                'permission' => '0777',
            }
        },
        {   'request_dir' => {
                'value'      => '{public_log_dir},/File_Transfers',
                'permission' => '0777',
            }
        },
        {   'data_submission_request_dir' => {
                'value'      => '{public_log_dir},/Data_Submission',
                'permission' => '0777',
            }
        },

        # root: data_log_dir
        {   'orders_log_dir' => {
                'value'      => '{data_log_dir},/Orders',
                'permission' => '0775',
            }
        },
        {   'slow_pages_log_dir' => {
                'value'      => '{data_log_dir},/slow_pages',
                'permission' => '0775',
            }
        },
        {   'deletions_dir' => {
                'value'      => '{data_log_dir},/deletions',
                'permission' => '0775',
            }
        },
        {   'cron_log_dir' => {
                'value'      => '{data_log_dir},/cron_logs',
                'permission' => '0775',
            }
        },
        {   'process_monitor_log_dir' => {
                'value'      => '{cron_log_dir},/Process_Monitor',
                'permission' => '0775',
            }
        },
        {   'templates_dir' => {
                'value'      => $config_dir . "/templates",
                'permission' => '0775',
            }
        },
        {   'web_dir' => {
                'value'      => $web_dir,
                'permission' => '0775',
            }
        },
        {   'run_analysis_log_dir' => {
                'value'      => '{data_log_dir},/run_analysis_log',
                'permission' => '0775',
            }
        },
        {   'PUBLIC_PROJECT_DIR' => {
                'value'      => '/html/Project',
                'permission' => '0775',
            }
        },
        {   'JAVASCRIPT' => {
                'value'      => "/{URL_dir_name},/$jsversion",
                'permission' => '0775',
            }
        },
        {   'CSS' => {
                'value'      => "/{URL_dir_name},/$cssversion",
                'permission' => '0775',
            }
        },
        {   'IMAGE_DIR' => {
                'value'      => $URL_dir_name . '/images/png',
                'permission' => '0775',
            }
        },
        {   'lab_instruments_dir' => {
                'value'      => '/projects/labinstruments',
                'permission' => '0777',
            }
        },
        {   'lab_instruments_windows_dir' => {
                'value'      => '\\\isaac\labinstruments',
                'permission' => '0777',
            }
        },

        # root: lab_instruments_dir
        {   'bioanalyzer_dir' => {
                'value'      => '{lab_instruments_dir},/Bioanalyzer_Run',
                'permission' => '0775',
            }
        },
        {   'QPCR_Run_dir' => {
                'value'      => '{lab_instruments_dir},/QPCR_Run',
                'permission' => '0775',
            }
        },
    ];
}

#
# Accessor to glossary of terms
#
# usage:
#
# Show_Tool_Tip( radio_group(-name=>'Aliquot'),
#    -tip => definitions('Aliquot'));
#
#
# Return: definition
##################
sub define_Term {
##################
    my $term = shift;
    my $alt  = shift;    ## optional alternative definition if not defined

    my @keys = keys %{$Term_Definitions};
    if ( defined $Term_Definitions->{$term} ) {
        return $Term_Definitions->{$term};
    }
    else { return $alt }
}

######################
sub _combine_configs {
######################
    #
    # Combines %Configs_Custom and $Configs_Non_Custom into %Configs
    #
    my $config = shift || {};    ## new config settings
    my %configs = %Configs;      ## old config settings
    
    foreach my $key ( keys %Configs_Custom ) {
        if (ref $Configs_Custom{$key} eq 'HASH') {
            $configs{$key} = $Configs_Custom{$key}{value};
        }
        else { $configs{$key} = $Configs_Custom{$key} }
    }
    

    foreach my $item (@$Configs_Non_Custom) {
        my @keys      = keys %$item;
        my $key       = $keys[0];
        my $value     = $item->{$key}{value} || '';
        my @nodes     = split ',', $value;
        my $new_value = '';
        foreach my $node (@nodes) {
            if ( $node =~ /{(.*)}/ ) {
                $new_value .= $config->{$1} || $configs{$1};
            }
            else {
                $new_value .= $node;
            }
        }
        $configs{$key} = $new_value;
        $config->{$key} = $new_value;
    }
    return \%configs;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: CustomSettings.pm,v 1.140 2004/12/03 00:09:19 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
