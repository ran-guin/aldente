##############################################
#
# $ID$
# CVS Revision: $Revision: 1.71 $
#     CVS Date: $Date: 2004/12/16 18:28:03 $
#
##############################################
#
# This file contains Default values that should
# be specified in order to utilize the barcoding
# and Sequencing Database functionality.
#
# Any code that is specific to a particular user
# should utilize variable names that are defined here.
#
# (more general defaults may be defined in SDB::CustomSettings.pm)
#
# Default types:
#
# Defaults that SHOULD be set by individual users...
#
###################
# Directory Paths #
###################
#
# specific directory paths specific to local systems
#
#############
# Filenames #
#############
#
# specific filenames used in scripts
#
###################
# Display Options #
###################
#
# control the way some of the viewers display Table information
#
# specific formulas and parameters used to calculate 'Standard' Solutions
#
#
################################################################################
#
# Author           : Ran Guin
#
# Purpose          : Repository for Defaults specifically for use with
#                    Sequencing Database Interface - al dente
#                    - Exports variables for use by alDente/SDB modules
#
# Standard Modules : CGI, DBI, FindBin
#
# Custom Modules   : SDB::CustomSettings
#
# Added Modules    : gscweb (required for Custom use of Initialize_page)
#
# Setup Required   : Reset variables below as required...
#
################################################################################
package alDente::SDB_Defaults;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

SDB_Defaults.pm - $ID$

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
$ID$<BR>This file contains Default values that should<BR>be specified in order to utilize the barcoding <BR>and Sequencing Database functionality.<BR>Any code that is specific to a particular user<BR>should utilize variable names that are defined here.<BR>(more general defaults may be defined in SDB::CustomSettings.pm) <BR>Default types:<BR>Defaults that SHOULD be set by individual users...<BR>Directory Paths #<BR>specific directory paths specific to local systems<BR>Filenames #<BR>specific filenames used in scripts<BR>Display Options #<BR>control the way some of the viewers display Table information<BR>specific formulas and parameters used to calculate 'Standard' Solutions<BR>Author           : Ran Guin <BR>Purpose          : Repository for Defaults specifically for use with <BR>Sequencing Database Interface - al dente<BR>- Exports variables for use by alDente/SDB modules<BR>Standard Modules : CGI, DBI, FindBin<BR>Custom Modules   : SDB::CustomSettings<BR>Added Modules    : gscweb (required for Custom use of Initialize_page)<BR>Setup Required   : Reset variables below as required...<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    $page $banner $testing
    $login_name $login_pass  $visit
    $development
    $lab_administrator_email $seq_administrator_email $stock_administrator_email $lims_administrator_email
    $equipment $equipment_id $step
    $expiry $oldest
    $sets $procedure $protocol $protocol_id
    $last_page $errmsg
    $nowday $nowtime $nowDT
    $size $quadrant $rack $format $button_style
    $MenuSearch $padding
    $Growth_by_Lib $Notes_by_Lib
    $REPRINT
    $CVSTAG $old_user $old_id $express $stock $VERSION
    $libs
    @users @projects @active_projects @suppliers @Departments %Pages $Current_Department $User_Home $Last_Department
    @plate_sizes @plate_info @plate_formats @all_plates
    @s_suppliers @e_suppliers @organizations @locations
    @libraries @library_names
    @sequencers %sequencers
    %login_parameters
    @Versions $version_name $version_number $next_version $version_name_full $code_version
    $java_header $html_header  $SDB_links $SDB_banner
    $button_colour $Machine_cap_rows $look_back
    %Search_Item %Tool_Tips $Security
    $help_dir $data_log_directory $Dump_dir $archive_dir $bin_home $parameters_file
    $error_directory $data_error_directory $project_dir $public_project_dir $data_home_dir $home_dir $home_web_dir $SDB_web_dir
    $Temp_dir $session_dir $Stats_dir $run_maps_dir $crons_log_dir $inventory_dir $inventory_test_dir $work_package_dir $bulk_email_dir
    $qpix_log_dir  $qpix_dir $affy_reports_dir $sample_files_dir $uploads_dir $multiprobe_dir $yield_reports_dir $archive_dir
    $java_bin_dir $templates_dir $phred_dir $trace_dir $edit_dir $poly_dir $vector_directory $request_dir $fasta_dir
    $adir $ddir $sssdir $mirror $mirror_dir $Dump_dir $archive_dir $well_image_dir $colour_image_dir $protocols_dir $issues_dir
    $parameters_file $gel_run_upload_dir
    $trace_file_ext1 $failed_trace_file_ext1
    $trace_file_ext2 $failed_trace_file_ext2
    $rawext $rawext2 $psd_ext $plt_ext $ss_ext $phred_ext
    $genss_script $phredpar $trace_link $pending_sequences
    $SDB_submit_image $SDB_Move_Right $SDB_Move_Left $SDB_Move_Up $SDB_Move_Down $gel_run_upload_dir
    @active_icons
    %Track
    %object_aliases
    %department_aliases
    %table_barcodes
    &get_cascade_tables
);
@EXPORT_OK = qw(
    %login_parameters
    @Versions $version_name $version_number $next_version $version_name_full $code_version
    $java_header $html_header  $SDB_links $SDB_banner
    $button_colour $Machine_cap_rows $look_back
    %Search_Item %Tool_Tips $Security
    $help_dir $data_log_directory $Dump_dir $archive_dir $bin_home $issues_dir $parameters_file
    $error_directory $data_error_directory $project_dir $public_project_dir $data_home_dir $home_dir $home_web_dir $SDB_web_dir
    $Temp_dir $session_dir $Stats_dir $run_maps_dir $crons_log_dir $inventory_dir $inventory_test_dir $work_package_dir $bulk_email_dir
    $qpix_log_dir $affy_reports_dir $sample_files_dir $uploads_dir $multiprobe_dir $qpix_dir $yield_reports_dir $archive_dir
    $java_bin_dir $templates_dir $phred_dir $trace_dir $edit_dir $poly_dir $vector_directory $request_dir $fasta_dir
    $adir $ddir $sssdir $mirror $mirror_dir $protocols_dir
    $trace_file_ext1 $failed_trace_file_ext1
    $trace_file_ext2 $failed_trace_file_ext2
    $rawext $rawext2 $psd_ext $plt_ext $ss_ext $phred_ext
    $genss_script $phredpar $trace_link $pending_sequences
    $SDB_submit_image $SDB_Move_Right $SDB_Move_Left $SDB_Move_Up $SDB_Move_Down $gel_run_upload_dir
    &get_cascade_tables
);
%EXPORT_TAGS = (
    versions => [
        qw($version_name $version_number $next_version $version_name_full $code_version
            $SDB_links $SDB_banner
            )
    ],
    directories => [
        qw(
            $help_dir $data_log_directory $Dump_dir $archive_dir $bin_home $well_image_dir $colour_image_dir $issues_dir
            $error_directory $data_error_directory $project_dir $public_project_dir $data_home_dir $home_dir $home_web_dir
            $SDB_web_dir $Temp_dir $session_dir $Stats_dir $run_maps_dir $parameters_file $crons_log_dir $inventory_dir
            $inventory_test_dir $work_package_dir $bulk_email_dir $qpix_log_dir $affy_reports_dir $sample_files_dir
            $uploads_dir $multiprobe_dir $qpix_dir $yield_reports_dir $archive_dir
            $phred_dir $trace_dir $edit_dir $poly_dir $vector_directory $request_dir $fasta_dir
            $adir $ddir $sssdir $mirror $mirror_dir $protocols_dir
            )
    ],
    sequencers => [
        qw(
            $trace_file_ext1 $failed_trace_file_ext1
            $trace_file_ext2 $failed_trace_file_ext2
            $rawext $rawext2
            $psd_ext $plt_ext $ss_ext $phred_ext
            )
    ],
    files => [qw($genss_script $phredpar $trace_link $pending_sequences)],
    %table_barcodes
);

##############################
# standard_modules_ref       #
##############################

use strict;

##############################
# custom_modules_ref         #
##############################
######## Custom Modules Required #######################
use SDB::CustomSettings;    ### Generic mySQL Database Default file
use RGTools::RGIO;

##############################
# global_vars                #
##############################
### page initialization, banner set up... ###
#use lib "/home/martink/export/prod/modules/gscweb";
#use gscweb;
### moved from CustomSettings (this is specific to Sequencing)...
#
### ORGANIZE this stuff when you get a chance !!!
#
use vars qw($page $track_sessions);
use vars qw($login_name $login_pass $visit);
use vars qw($development);
use vars qw($lab_administrator_email $seq_administrator_email $stock_administrator_email $lims_administrator_email);
use vars qw($equipment $equipment_id $step);
use vars qw($expiry $oldest);
use vars qw($sets $procedure $protocol);
use vars qw($last_page $errmsg);
use vars qw($lf);          #
use vars qw(%DB_lists);    ### lists generated by wrapper function...
use vars qw(@users @projects @active_projects @suppliers @plate_sizes @plate_info @plate_formats @all_plates @Departments %Pages $Current_Department $User_Home $Last_Department);
use vars qw(@s_suppliers @e_suppliers @organizations @locations);
use vars qw(@libraries @library_names @sequencers);    #
use vars qw($nowday $nowtime $nowDT);
use vars qw($size $quadrant $rack $format $button_style);
use vars qw($MenuSearch $padding);
use vars qw($Growth_by_Lib $Notes_by_Lib);
use vars qw($REPRINT);                                 #
use vars qw($version_info);                            ### generated in original file
use vars qw($CVSTAG $old_user $old_id $express $stock $VERSION $libs);
######### IMPORTED Variables  ########
use vars qw( $loginlink $user $session_id $dbase $URL_address $URL_dir_name $Web_home_dir $Data_home_dir $URL_domain $URL_base_dir_name $config_dir);
######### EXPORTED Variables  ########
use vars qw(%Defaults);                                ### reference is IMPORTED, some values are EXPORTED
######### Standard Defaults ############
use vars qw($project $banner $plate_id $plate_set $current_plates $step_name $solution_id $sol_mix $barcode);    ### TEMPORARY
use vars qw($button_colour $Machine_cap_rows $look_back);
use vars qw(%Search_Item %Tool_Tips);

# %Prompts %VFields %Fields %Primary_fields %Mandatory_fields %FK_View %Prefix);
use vars qw(%Prefix %Configs);
use vars qw(@Versions $version_name $version_number $next_version $version_name_full $code_version);
use vars qw($java_header $html_header $SDB_links $SDB_banner $scanner_mode);
use vars qw($SDB_submit_image $SDB_Move_Right $SDB_Move_Left $SDB_Move_Up $SDB_Move_Down);
######### Directory Paths ##############
use vars qw($java_bin_dir $templates_dir $help_dir $data_log_directory $Dump_dir $archive_dir $well_image_dir $colour_image_dir $bin_home $parameters_file);
use vars qw($error_directory $data_error_directory $project_dir $public_project_dir $home_dir $data_home_dir $home_web_dir $SDB_web_dir $Temp_dir
    $session_dir $Stats_dir $run_maps_dir $crons_log_dir $inventory_dir $inventory_test_dir $work_package_dir $bulk_email_dir
    $qpix_log_dir $qpix_dir $affy_reports_dir $sample_files_dir $uploads_dir $multiprobe_dir $yield_reports_dir $archive_dir
    $gel_run_upload_dir);
use vars qw($phred_dir $trace_dir $edit_dir $poly_dir $vector_directory $request_dir $fasta_dir);
use vars qw($adir $ddir $sssdir $mirror $mirror_dir $Dump_dir $protocols_dir $issues_dir $gel_run_upload_dir);

#use vars qw(%Mssdir $NTssdir $NThost $NTsharename $local_sample_sheets $local_drive);
use vars qw($trace_file_ext1 $trace_file_ext2 $failed_trace_file_ext1 $failed_trace_file_ext2);
use vars qw($rawext $rawext2 $psd_ext $plt_ext $ss_ext $phred_ext);

#use vars qw($RunModule $AnModule $MobFile);
######### Special Filenames ############
use vars qw($genss_script $phredpar $trace_link $pending_sequences);
use vars qw(%login_parameters);
use vars qw(@active_icons);
use vars qw(%Track);
use vars qw(%object_aliases %department_aliases %table_barcodes);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
my $jsversion  = 'js.3.15';
my $cssversion = 'css.3.15';

##############################
# main_header                #
##############################
###############################
## Standard Default Settings ##
###############################
$Defaults{SOC_MEDIA_QTY}   = 9;
$Defaults{CELLS_QTY}       = 1;
$Defaults{MAX_LIB_PRIMERS} = 5;    #maximum number of primers that can associate to a library
###########################
## Locally Set Variables: #
###########################
## lab administrators ##
my @lab_admin = (
    'aldente@bcgsc.bc.ca', 'dsmailus@bcgsc.bc.ca', 'gyang@bcgsc.bc.ca', 'sbarber@bcgsc.ca',  'mbala@bcgsc.ca',    'aprabhu@bcgsc.ca', 'cmathew@bcgsc.bc.ca', 'jasano@bcgsc.bc.ca', 'jkhattra@bcgsc.bc.ca', 'ngirn@bcgsc.bc.ca',
    'dlee@bcgsc.ca',       'tzeng@bcgsc.ca',       'abaross@bcgsc.ca',  'scoughli@bcgsc.ca', 'yzhao@bcgsc.bc.ca', 'dmah@bcgsc.bc.ca', 'kfichter@bcgsc.ca',   'elau@bcgsc.ca',      'rmoore@bcgsc.ca',      'mhirst@bcgsc.ca',
);
## sequencing administrators ##
my @seq_admin = (
    'aldente@bcgsc.bc.ca',
    'dsmailus@bcgsc.bc.ca',
    'gyang@bcgsc.bc.ca',
    'sbarber@bcgsc.bc.ca',
    'mbala@bcgsc.bc.ca',

    #		 'ybutterf@bcgsc.bc.ca',
    'mbala@bcgsc.ca',
    'rmoore@bcgsc.ca',

    #		 'mmarra@bcgsc.bc.ca',
    #		 'sjones@bcgsc.bc.ca',
);
## stock administrators ##
my @stock_admin = ('aldente@bcgsc.bc.ca');
my @lims_admin  = ('aldente@bcgsc.bc.ca');
$lab_administrator_email   = join ',', @lab_admin;
$stock_administrator_email = join ',', @stock_admin;
$seq_administrator_email   = join ',', @seq_admin;
$lims_administrator_email  = join ',', @lims_admin;
#######################
## Protocol Tracking ##
#######################
### adjust to remove % symbols so that it may be used by =~// OR by like '...';
#$Track->{rxn} = "%Therm%cycl%";
#$Track->{rxn384} = "384 Well %Therm%cycl%";
$Track{Antibiotic} = "Antibiotic";
###################
# Display Options #
###################
$button_colour = "lightblue";
$look_back     = 30;            ### specify time (in days) to look back for statistics summaries...

################################################
## Cascade List of Tables for Record Deletion ##
################################################
my %Cascade_Tables = (
    'Run'   => [ 'SequenceRun', 'SolexaRun', 'MultiPlate_Run', 'Invoiceable_Run', 'Invoiceable_Analysis' ],
    'Plate' => {
        ### subtype ###
        #'tube'		=> [],
        ### custom ###
        'Original' => [ 'Clone_Sample',          'Extraction_Sample', 'Plate_Sample',  'Sample', 'Library_Plate', 'Tube',            'Array',           'Plate_Set',      'Plate_Attribute', 'Plate_Schedule', 'Plate_Tray', 'Invoiceable_Work' ],
        'Rearray'  => [ 'Plate_PrimerPlateWell', 'Plate_Sample',      'Library_Plate', 'Tube',   'Array',         'Plate_Set',       'Plate_Attribute', 'Plate_Schedule', 'Plate_Tray',      'Invoiceable_Work' ],
        'Daughter' => [ 'Plate_Sample',          'Library_Plate',     'Tube',          'Array',  'Plate_Set',     'Plate_Attribute', 'Plate_Schedule',  'Plate_Tray',     'Invoiceable_Work' ],
    },
    'Invoiceable_Work' => [ 'Invoiceable_Run', 'Invoiceable_Prep', 'Invoiceable_Analysis', 'Invoiceable_Work_Reference' ],

    #    'ReArray_Request'	=> ['ReArray'],
    'Pool'            => [ 'Sample_Pool', 'PoolSample' ],
    'Lane'            => ['Band'],
    'Pipeline_Step'   => ['Pipeline_StepRelationship'],
    'ReArray_Request' => {
        'ReArray'         => ['ReArray_Attribute'],
        'ReArray_Request' => ['ReArray']
    },
    'ReArray' => ['ReArray_Attribute'],
    'Stock'   => {
        ### subtype ###
        'Primer' => {
            'Primer_Plate_Well' => ['Plate_PrimerPlateWell'],
            'Primer_Plate'      => ['Primer_Plate_Well'],
            'Solution'          => ['Primer_Plate'],
            'Stock'             => ['Solution']
        }
    },
    'Primer_Plate' => ['Primer_Plate_Well'],
    'Rack'         => ['Rack'],
);

#########################
# Table Display Options #
#########################
#
# Specify the prompt which will be used for the given fields for under normal circumstance
#
# list of fields to View in Table with renamed headers...
#
#######  Allow a general search to check for string in any of the following fields... #############
#
# (make sure these are ALL INDEXED !)
#
%Search_Item = (
    'Employee'  => [ 'Employee_Name',    'Employee_FullName', 'Initials', 'Email_Address' ],
    'Equipment' => [ 'Equipment_Name',   'Serial_Number' ],
    'Stock'     => [ 'Stock_Lot_Number', 'Identifier_Number' ],
    'Stock_Catalog' => [ 'Stock_Catalog_Name', 'Stock_Catalog_Number', 'Model' ],
    'Library'       => [ 'Library_Name',       'Library_Description' ],
    'Organism'      => [ 'Organism_Name',      'Species' ],
    'Contact'       => [ 'Contact_Name',       'Contact_Email' ],
    'Sample'        => ['Sample_Name'],
    'Sample_Alias'  => ['Alias'],
    'Contact'       => ['Contact_Name'],
    'Project'      => [ 'Project_Name', 'Project_Description' ],
    'Run'          => ['Run_Directory'],
    'Organization' => ['Organization_Name'],
    'Vector_Type'  => ['Vector_Type_Name'],
    'Patient'      => ['Patient_Identifier'],
    'Shipment'     => ['Shipment_Reference'],
    'Primer'       => ['Primer_Name'],
    'Plate' => [ 'concat(FK_Library__Name,Plate_Number)', 'Plate_Label', "concat(FK_Library__Name,'-',Plate_number)", "concat(FK_Library__Name,'-',Plate_number,Parent_Quadrant)" ],

    #   'Clone'                     => ['Clone_Source_Name','Clone_Source2_Name','Genbank_ID','Clone_Source_Collection','Clone_Source_Library'],

    'Clone_Source'    => [ 'Source_Collection', 'Source_Library_Name',                    'Source_Clone_Name' ],
    'Machine_Default' => ['Host'],
    'Original_Source' => ['Original_Source_Name'], ## (removed 'Organism') add Source_RNA_DNA
    'Source'                    => [ 'External_Identifier', 'Source_Label' ],
    'Flowcell'                  => ['Flowcell_Code'],
    'Standard_Solution'         => ['Standard_Solution_Name'],
    'Lab_Protocol'              => ['Lab_Protocol_Name'],
    'Funding'                   => ['Funding_Code'],
    'Sample_Attribute'          => ['Attribute_Value'],
    'Plate_Attribute'           => ['Attribute_Value'],
    'Original_Source_Attribute' => ['Attribute_Value'],
    'Source_Attribute'          => ['Attribute_Value'],
    'Library_Attribute'         => ['Attribute_Value'],
    'Invoice'                   => [ 'Invoice_Code',        'Invoice_Draft_Name' ],
    'Rack' => ['Rack_Alias'],
);
###Popup help messages

my $scan_options
    = 'Options<BR><BR><B>Type:</B><UL>'
    . '<LI>(any single barcode) -> Get info on object + more options'
    . '<LI>Pla + Pla ...->Generate Container Set to Prep/Transfer/Throw Away'
    . '<LI>Sol + Sol -> Mix Reagents'
    . '<LI>Pla + Sol -> Apply Reagent/Solution to Container'
    . "<LI>Sol + $Prefix{Rack} -> Move Reagents/Solutions"
    . "<LI>Pla + $Prefix{Rack} -> Move Containers"
    . "<LI>$Prefix{Rack} + $Prefix{Equipment} (Freezer) -> Move Rack between Freezers"
    . "<LI>$Prefix{Rack} + $Prefix{Rack} -> Move Rack from Source -> Target destination" . "</UL>";

#if ($dbc->package_active('Sequencing') ) {
if ( $Configs{Plugins} =~ /Sequencing/ ) {
    $scan_options .= '<BR><BR>Sequencing Specific:<UL>' . '<LI>Pla + Equ (sequencer) -> Generate SampleSheet' . '<LI>Equ + Sol (matrix/buffer) -> Change Matrix and/or Buffer' . "</UL>";
}

$scan_options .= "<BR><B>..and press 'Scan' Button</B><BR>";

$scan_options
    .= '<BR><BR>Shortcuts:<UL>'
    . "<LI>$Prefix{Plate}1-$Prefix{Plate}5 -> retrieves multiple plates (eg 1,2,3,4,5) - works for other objects as well"
    . "<LI>$Prefix{Tray}(a)$Prefix{Tray}(a-c) -> retrieves specific quadrant(s) from a 96x4 384-well plates"
    . "<LI>CC001 -> exact match of library name will pull up home page for that library" . "</UL>";

$scan_options .= "<BR><B>To search database for string use 'Search DB' Button on the right side of the menu bar</B<BR>";

%Tool_Tips = (
    ###Fields from left navigation bar
    Search_Button_Field      => 'Search key fields in the database<BR>Use * for a wildcard<BR>Numerical Ranges ok (eg 12345-12348)<BR>(use quotes if searching for a string that resembles a range)',
    Help_Button_Field        => 'Search the help files',
    Scan_Button_Field        => $scan_options,
    Plate_Set_Button_Field   => 'Grab plate sets',
    Print_Text_Label_Field   => 'Print text labels to barcode printers',
    Error_Notification_Field => 'Report an issue and send email notification to administrators',
    Catalog_Number_Field     => 'Enter any portion of the catalog number or name to retrieve current stock items<BR>Use * for a wildcard if desired',
    New_Primer_Type_Link     => 'Define a new type of primer',
    New_Plate_Type_Link      => 'Define a new type of plate/plasticware',
    ###Fields from Login page
    Edit_Lane_Link => 'Update Comments for a Lane',
    Password_Field => 'The default password is pwd',
    Reset_Button   => 'Reset all form elements to default values',
    Load_Set       => 'Quick load of specified Set of Plates / Tubes',
);
############################################################
## Object Aliases:  Aliases for database objects
##
##
############################################################
%object_aliases = (
    Original_Source  => 'Source',
    ReArray          => 'Rearray',
    Run              => 'Read,Run',
    SequenceAnalysis => 'Read,Run',
    Clone_Sample     => 'Clone',
    Sample           => 'Clone',
);
%department_aliases = ( 'Lib_Construction' => { Library => 'RNA_DNA_Collection' } );

%table_barcodes = (
    'Plate_Format'      => 'plate',
    'Source'            => 'source',
    'Standard_Solution' => 'solution',
    'Stock'             => 'solution,equipment,microarray'
);
############################################################
##                                                        ##
## Note: Also change Chemistry values (at bottom of page) ##
##                                                        ##
############################################################
#####################################################################
## Defaults below are generally NOT changed except on installation ##
#####################################################################
$trace_file_ext1        = ".abd";     # files generated by MegaBase Sequencers...
$trace_file_ext2        = ".ab1";     # files generated by D3700 Sequencers..
$failed_trace_file_ext1 = ".fsd";     # files generated by MegaBase Sequencers...
$failed_trace_file_ext2 = ".fsd";     # files generated by D3700 Sequencers..
$rawext                 = ".rsd";     # files generated by MegaBase Sequencers...
$rawext2                = ".esd";     # files generated by MegaBase Sequencers...
$phred_ext              = ".phd.1";
$psd_ext                = ".psd";
$plt_ext                = ".plt";
$ss_ext->{MB}           = ".psd";
$ss_ext->{D3}           = ".plt";
### specify number of rows of capillaries on Megabase machines..
$Machine_cap_rows->{MB1} = 8;
$Machine_cap_rows->{MB2} = 8;
$Machine_cap_rows->{MB3} = 16;
##################
## Version Info ##
##################
#
# This is seperate from CVS version numbers, and should be
# manually changed in Production, Test and other installed
# versions of the code base in order to give the sequencers
# simple names to refer to different versions.
#
# Names are prepended with either 'Barcode' or 'Scanner' to
# distinguish between the handheld mode or desktop mode
#
# Releases:
#
# - last rgweb.bcgsc.bc.ca version : rgweb
# - first seq.bcgsc.bc.ca version : New (tagged as 2.0.0 in CVS)
# - first pass at modularizing the code (also, first 'named' version) : Monkey (should be tagged as 2.1.0)
#
# Future names: Cat, Dog, Mouse, Rat, Cow
#
@Versions     = ( '1.10', '1.20', '1.30', '2.00', '2.1', '2.2', '2.3', '2.4', '2.41', '2.5', '3.0' );    ###Make sure to add the next upcoming version to this array before release current version.
$version_name = 'alDente';
$code_version = '2.5';                                                                                   ### <CONSTRUCTION> Make sure to check this number is the current version before release.

# Set in barcode.pl  $version_number = '1.40';
$version_number ||= '';

#Figure out next version

my $i = 0;
foreach my $version (@Versions) {
    if ( $version eq $version_number ) {last}
    $i++;
}
$i++;
if   ( $i <= ($#Versions) ) { $next_version = $Versions[$i]; }
else                        { $next_version = $Versions[$#Versions]; }

#$version_name_full = 'D1.0';
#if ($main::scanner_mode) { $version_name_full = 'Scanner' } else { $version_name_full = 'Barcode' }
#$version_name_full .= " $version_name $version_number";
my $intranet = '';    ### link to intranet subdirectory... ?
if ( $0 =~ /intranet/ ) { $intranet = '/intranet'; }
### header for custom page wrapper ###
### used in html_header AND Initialize_page
$java_header .= "\n<script src='/$URL_dir_name/$jsversion/alDente.js'></script>\n";
$java_header .= "\n<script src='/$URL_dir_name/$jsversion/scrollbar.js'></script>\n";
$SDB_banner       = "<h2>alDente: Automated Laboratory Data Entry N' Tracking Environment</h2>\n";
$SDB_submit_image = "/$URL_dir_name/images/icons/arrow_fwd_blue.gif";
$SDB_Move_Right   = "/$URL_dir_name/images/icons/iconMoveRight.gif";
$SDB_Move_Left    = "/$URL_dir_name/images/icons/iconMoveLeft.gif";
$SDB_Move_Up      = "/$URL_dir_name/images/icons/iconMoveUp.gif";
$SDB_Move_Down    = "/$URL_dir_name/images/icons/iconMoveDown.gif";

my $link_bgcolor = 'lightgrey';
#################
## Directories ##
#################
####### Local Directory Structure/Path Information ###########
$bin_home = $FindBin::RealBin . "/../bin";    ### directory for binaries

#$help_dir = $FindBin::RealBin . "/../../../www/dynamic/public/LIMS_manual";
#$help_dir = $FindBin::RealBin . "/../../../www/htdocs/docs/out";
$help_dir = $FindBin::RealBin . "/../www/docs/out";

$SDB_links = "
<Table width=100% cellspacing=0 cellpadding=5>
<TR><TD bgcolor=$link_bgcolor>
<A Href='$URL_address/sequencing.pl'>al dente</A>
</TD><TD bgcolor=$link_bgcolor>
<A Href='$URL_address/SDB_help.pl'>Help</A>
</TD><TD bgcolor=$link_bgcolor>
<A Href='$URL_address/SDB_reports.pl'>Reports</A>
</TD><TD bgcolor=$link_bgcolor>
<A Href='$URL_address/SDB_code.pl'>Coding Info</A>
</TD><TD bgcolor=$link_bgcolor>
<A Href='$URL_address/barcode.pl?User=Auto&Database_Mode=PRODUCTION'>Barcode Page</A>
</TD></TR></Table>
";

$java_bin_dir       = $Configs{java_bin_dir};
$templates_dir      = $Configs{templates_dir};
$data_log_directory = $Configs{data_log_dir};         ### log for data directory (NOT on web server)
$Dump_dir           = $Configs{Dump_dir};
$project_dir        = $Configs{project_dir};          ### main project directory
$public_project_dir = $Configs{project_dir};          ### main project directory
$run_maps_dir       = $Configs{run_maps_dir};
$crons_log_dir      = $Configs{cron_log_dir};
$inventory_dir      = $Configs{inventory_dir};
$inventory_test_dir = $Configs{inventory_test_dir};
$work_package_dir   = $Configs{work_package_dir};
$bulk_email_dir     = $Configs{bulk_email_dir};
$qpix_dir           = $Configs{qpix_dir};
$qpix_log_dir       = $Configs{qpix_log_dir};
$affy_reports_dir   = $Configs{affy_reports_dir};
$sample_files_dir   = $Configs{sample_files_dir};
$uploads_dir        = $Configs{uploads_dir};
$multiprobe_dir     = $Configs{multiprobe_dir};
$yield_reports_dir  = $Configs{yield_reports_dir};
$archive_dir        = $Configs{archive_dir};
$gel_run_upload_dir = $Configs{gel_run_upload_dir};

###### the following directories should local to server for performance reasons #####
$session_dir = $Configs{session_dir};    ### Track User sessions
$Stats_dir   = $Configs{Stats_dir};      ### log Statistics.

######### Directories specifically related to Sequencing ###############
$phred_dir        = "phd_dir";
$trace_dir        = "chromat_dir";
$edit_dir         = "edit_dir";
$poly_dir         = "poly_dir";
$adir             = "AnalyzedData";
$ddir             = "Data";
$sssdir           = "SampleSheets";
$well_image_dir   = "images/wells";            ### image of the wells
$colour_image_dir = "images/colour";           ### image of the colours
$vector_directory = $Configs{vector_dir};
$request_dir      = $Configs{request_dir};     ### directory where configuration file requests are placed.
$fasta_dir        = $Configs{fasta_dir};
$mirror_dir       = $Configs{mirror_dir};
$mirror           = $mirror_dir;
$archive_dir      = $Configs{archive_dir};
$protocols_dir    = $Configs{protocols_dir};
$issues_dir       = $Configs{issues_dir};

#$data_home_dir         = "$Data_home_dir";             ### base directory
#$home_dir              = "$Web_home_dir";             ### base directory
#$home_web_dir          = "/home/sequence/www/cgi-bin$intranet/$URL_dir_name";
#$SDB_web_dir           = "/home/sequence/www/htdocs/$URL_dir_name";        ### Sequencing results directory
#$Temp_dir              = "/home/sequence/www/htdocs/$URL_dir_name/tmp";  ### Temporary directory
#$error_directory       = "$web_home_dir/logs/errors";  # track errors here
#$data_error_directory  = "$$SDB::CustomSettings::Data_home_dir/logs/errors";  # track errors here

#######################
## Special Filenames ##
#######################
$genss_script      = "$bin_home/genss.pl";                      # command line script to generate sample sheets
$phredpar          = "$config_dir/phredpar.dat";                # phred parameter file - currently '/home/pubseq/BioSw/phred/current/phredpar.dat'
$trace_link        = $URL_address . "/view_chromatogram.pl";    ### trace file generator
$pending_sequences = $Configs{pending_sequences};               #"$SDB::CustomSettings::Web_home_dir/dynamic/logs/pending_sequences"; # track incomplete sequence files
########## Sequencer specific defaults ####################
#
# (retrieve from Machine_Default Table)
#
@active_icons = ( 'Home', 'Bugs', 'LogIn', 'Runs', 'SS', 'Solutions', 'Equipment', 'Plates', 'Tubes', 'Status', 'Libraries', 'Orders', 'Contacts', 'Admin', 'Changes' );

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################

##############################
# public_functions           #
##############################

#
# Accessor to cascade tables
#
# usage:
#
# my $list = get_cascade_tables( 'Run' );
# my $list = get_cascade_tables( 'Plate', 'Original_Plate' );
#
# Note:
# 	use subtype to include more specific (non-table) keys, e.g. the one for Plate,
#	but need to differ this from the cascade list that has a hash structure ( like the one for Stock).
#	If subtype is passed in, return subtype cascade list.
#	If subtype is not passed in, return default if defined. Give warning if no default.
#
# Return: Array or hash ref of table names if found
##################
sub get_cascade_tables {
##################
    my $object  = shift;
    my $subtype = shift;    # subtype or custom argument

    if ($subtype) {
        if ( defined $Cascade_Tables{$object} ) {
            ## hash
            if ( ref $Cascade_Tables{$object} eq 'HASH' ) {
                if ( defined $Cascade_Tables{$object}{$subtype} ) {
                    return $Cascade_Tables{$object}{$subtype};
                }
                else {
                    print("WARNING: Cascade deletion list for $object $subtype NOT defined!\n");
                    return;
                }
            }
            ## array, that means no subtypes or custom types are defined. The list applies to all types.
            if ( ref $Cascade_Tables{$object} eq 'ARRAY' ) {
                return $Cascade_Tables{$object};
            }
        }
        else {
            print("WARNING: Cascade deletion list for $object NOT defined!\n");
            return;
        }
    }
    else {
        if ( ref $Cascade_Tables{$object} eq 'ARRAY' ) {
            return $Cascade_Tables{$object};
        }
        elsif ( ref $Cascade_Tables{$object} eq 'HASH' ) {
            print("WARNING: subtype or custom type of $object required for retrieving cascade deletion list!\n");
            return;
        }
    }

    return;
}

##################
# %Search_Item used to be a global, moving it into a function which can be
# called when the global is needed.
# <CONSTRUCTION> DB_Fields allows for fields to be set as "Searchable", may
# want to move to using a table retrieve for obtaining this hash.
##################
sub search_fields {
##################
    my %args = filter_input( \@_ );

    # my $dbc = %args{-dbc}; # to be changed later on to use database connection.

    return \%Search_Item;
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

$Id: SDB_Defaults.pm,v 1.71 2004/12/16 18:28:03 mariol Exp $ (Release: $Name:  $)

=cut

return 1;
