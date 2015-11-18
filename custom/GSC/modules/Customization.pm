##################
# Navigation 
##################
#
# This module is used to customize Navigation settings
#
package GSC_Menu;

use base alDente::Menu;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use RGTools::RGIO;

use strict;

##############################
# custom_modules_ref         #
##############################

##############################
# global_vars                #
##############################

my %Std_Icons;
## This controls the various sections under which ALL icons should appear - some of this may be loaded dynamically via config files instead ##
$Std_Icons{Home}      = [qw(Home Current_Dept)];
$Std_Icons{Admin}     = [qw(RNA_DNA_Collections Projects Submission Pipeline Protocols Employee Sources Contacts Subscription JIRA Issues Sample_Request)];
$Std_Icons{Lab}       = [qw(Rack Rearrays Plates Tubes Equipment_App Solutions_App Libraries  Pool_ReArray Pool_ReArray_to_Tube Barcodes)];
$Std_Icons{Shipments} = [qw(Shipments Receive_Shipment Export In_Transit)];
$Std_Icons{Database}  = [qw(Database_BC Database Queries DBField Import Custom_Import Template XRef System_Monitor Session Modules)];
$Std_Icons{Views}     = [qw(Views)];
$Std_Icons{Summaries} = [qw(Last_24h Daily_Planner Seq_Stat Solexa_Summary_App Stat_App Ion_Torrent_Summary Summary_App Bioinformatics_Stat Solexa_Summary_App_NO_filter Solid_Summary_App_NO_filter Solid_Summary_App Bioanalyzer_Run_App QPCR_Run_App GelRun_App)];
$Std_Icons{Tracking}  = [qw(Funding Study_App Submission_Volume_App)];
$Std_Icons{Runs}      = [qw()];
$Std_Icons{Help}      = [qw( LIMS_Help )];


######################
sub get_Icon_Groups {
######################
    my $dept = shift;

    my %Icons = %Std_Icons;
    if ($dept) { push @{ $Icons{Summaries} }, "${dept}_Stat", "${dept}_Summary" }
    if ($dept) { push @{ $Icons{Help} }, "${dept}_Help" }

    return %Icons;
}

################
sub get_Icons {
################
    my %args         = &filter_input( \@_);
    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc};
    my $key          = $args{-key};     ## indicate thumbnail; otherwise retrieves array of defined icons

    my %images;
    
    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

        ## Database independent Icons ##
        $images{Daily_Planner}{icon} = "Daily_Planner.png";
        $images{Daily_Planner}{url}  = "cgi_application=Cap_Seq::Statistics_App";
        $images{Daily_Planner}{name} = "Daily Planner";
        $images{Daily_Planner}{tip}  = "customized Daily Planner views for Sequencing group";

        $images{Subscription}{icon} = "envelope.gif";
        $images{Subscription}{url}  = "cgi_application=alDente::Subscription_Event_App";
        $images{Subscription}{name} = "Subscription";

        $images{Pipeline}{icon} = "data.png";
        $images{Pipeline}{url}  = "Pipeline+Summary=1";
        $images{Pipeline}{name} = "Pipeline Summary";
        $images{Pipeline}{tip}  = "Retrieve details for individual Pipelines or Protocols";

        $images{Protocols}{icon} = "data.png";
        $images{Protocols}{url}  = "cgi_application=alDente::Protocol_App";
        $images{Protocols}{name} = "Lab Protocols";
        $images{Protocols}{tip}  = "Retrieve details or edit Lab Protocols";

        $images{Solutions_App}{icon} = "solution.png";
        $images{Solutions_App}{url}  = "cgi_application=alDente::Solution_App";
        $images{Solutions_App}{name} = "Solution";
        $images{Solutions_App}{tip}  = "* For new reagents: go to the 'Purchasing' page to barcode a new reagent<BR>* For new solutions: simply scan their barcodes and click on the main 'Scan' button at the top of the page";

        $images{Views}{icon} = "data.png";
        $images{Views}{url}  = "cgi_application=" . "alDente::View_App&Sections=GSC_Internal,Group,Employee,Other";
        $images{Views}{name} = 'Views';
        $images{Views}{tip}  = "Create and use views";

        $images{DBField}{icon} = "help.gif";
        $images{DBField}{url}  = "cgi_application=alDente::DBField_App";

    ## phase out _App keys ##
        $images{Equipment_App}{icon} = "Equipment.png";
        $images{Equipment_App}{url}  = "cgi_application=alDente::Equipment_App";
        $images{Equipment_App}{name} = 'Equipment';
        $images{Equipment_App}{tip}  = "Search for Equipment<BR>Schedule or View Maintenance<BR>Inventory on Storage Freezers";

        $images{Equipment}{icon} = "Equipment.png";
        $images{Equipment}{url}  = "cgi_application=alDente::Equipment_App";
        $images{Equipment}{name} = 'Equipment';
        $images{Equipment}{tip}  = "Search for Equipment<BR>Schedule or View Maintenance<BR>Inventory on Storage Freezers";

        $images{System_Monitor}{icon} = "System.png";
        $images{System_Monitor}{url}  = "cgi_application=alDente::System_App";
        $images{System_Monitor}{name} = 'System Monitor';
        $images{System_Monitor}{tip}  = "Monitors volumes and directories";

        $images{Help}{icon} = "help.gif";
        $images{Help}{link} = "help.pl";

        $images{Queries}{icon} = "help.gif";
        $images{Queries}{url}  = "cgi_application=alDente::View_App&Open+View=1";

        $images{Barcodes}{icon} = 'mini_stripe.png';
        $images{Barcodes}{url}  = 'Barcode_Event=Home';

        $images{Rearrays}{icon} = "Plate.png";
        $images{Rearrays}{url}  = "cgi_application=alDente::ReArray_App";
        $images{Rearrays}{tip}  = "rearray samples";

        $images{Pool_ReArray}{icon} = "Plate.png";
        $images{Pool_ReArray}{url}  = "cgi_application=alDente::ReArray_App";
        $images{Pool_ReArray}{name} = "Pool/ReArray";
        $images{Pool_ReArray}{tip}  = "Pool/ReArray samples";

        $images{Pool_ReArray_to_Tube}{icon} = "Plate.png";
        $images{Pool_ReArray_to_Tube}{url}  = "cgi_application=alDente::ReArray_App&rm=Manually Set Up ReArray/Pooling&Target Well Nomenclature=Tube";
        $images{Pool_ReArray_to_Tube}{name} = "Pool/ReArray to Tube";
        $images{Pool_ReArray_to_Tube}{tip}  = "Pool/ReArray samples into Tubes";

        $images{Search}{icon} = 'flashlight.png';
        $images{Search}{name} = 'Search';
        $images{Search}{url}  = 'cgi_application';

        $images{Receiving}{icon} = 'truck.jpg';

        $images{Receive_Shipment}{icon} = 'truck.jpg';
        $images{Receive_Shipment}{name} = 'Receive Samples';
        $images{Receive_Shipment}{url}  = 'cgi_application=alDente::Shipment_App&rm=Receive+Samples&Grey=FKRecipient_Employee__ID,Shipment_Status,Shipment_Type&FKRecipient_Employee__ID=<USERID>&Shipment_Received=<NOW>&Shipment_Status=Received';

        $images{Export}{icon} = 'truck.jpg';
        $images{Export}{name} = 'Export Samples';
        $images{Export}{url}  = 'cgi_application=alDente::Rack_App&rm=Show Export Form';

        $images{In_Transit}{icon} = 'truck.jpg';
        $images{In_Transit}{name} = 'In Transit';
        $images{In_Transit}{url}  = 'cgi_application=alDente::Rack_App&rm=View Items in Transit';

        $images{Import}{icon} = 'uplink.png';
        $images{Import}{name} = 'Upload';
        $images{Import}{url}  = 'cgi_application=SDB::Import_App&rm=home';

        $images{Custom_Import}{icon} = 'uplink.png';
        $images{Custom_Import}{name} = 'Custom Upload';
        $images{Custom_Import}{url}  = 'cgi_application=alDente::Transform_App';

        $images{POG}{icon} = 'POG.png';
        $images{POG}{name} = 'POG Home';
        $images{POG}{url}  = 'cgi_application=POG::POG_App';

        $images{Sample_Sheets}{icon} = "ssheet.png";
        $images{Sample_Sheets}{url}  = "Sample+Sheets=1";
        $images{Sample_Sheets}{name} = 'Sample Sheets';

        $images{Session}{icon} = "text-enriched.png";
        $images{Session}{url}  = "cgi_application=SDB::Session_App";
        $images{Session}{name} = 'Session';

        $images{Template}{icon} = "new_file.png";
        $images{Template}{url}  = "cgi_application=alDente::Template_App";
        $images{Template}{name} = 'Template';

        $images{Employee}{icon} = "EMPLOYEE1.png";
        $images{Employee}{url}  = "cgi_application=alDente::Employee_App";
        $images{Employee}{name} = 'Employee';
        $images{Employee}{tip}  = "Manage Employees";

        $images{JIRA}{icon} = "ssheet.png";
        $images{JIRA}{url}  = "cgi_application=JIRA::Jira_App&rm=View+Jira+Tickets";
        $images{JIRA}{name} = 'JIRA';
        $images{JIRA}{tip}  = "view progress on JIRA tickets";

        $images{Maintenance}{icon} = 'wrench.png';

        $images{Storage}{icon}        = 'freezer2.png';
        $images{'Moves To'}{icon}     = 'right_arrow1.png';
        $images{Approval}{icon}       = 'Approval.ico';
        $images{Customize}{icon}      = 'Customize.png';
        $images{Approved}{icon}       = 'Approved.png';
        $images{Processed}{icon}      = 'processed.png';
        $images{Sample_Request}{icon} = 'box_request.png';

        $images{Xref}{icon} = 'Approved.png';
        $images{Xref}{name} = 'Xref Templates';

        foreach my $key ( keys %custom_images ) {
            ## override if defined in custom icons ##
            if ( defined $images{$key} ) {
                foreach my $subkey ( keys %{ $custom_images{$key} } ) {
                    $images{$key}{$subkey} = $custom_images{$key}{$subkey};
                }
            }
            else {
                $images{$key} = $custom_images{$key};
            }
        }

        ### Database specific Icons ###
        if ($dbc) {
            my $homelink = $dbc->homelink();
            my $dbase_mode = $dbc->config('Database_Mode');
            my $dept       = $dbc->config('Target_Department');
            my $home_dept  = $dbc->session->param('home_dept');
            my $department;
            
            if ($key) {
                $department = $dept;
                $department =~ s/ /_/;
            }

            $images{Home}{icon} = "home.gif";
            $images{Home}{url} = "Database_Mode=$dbase_mode&Target_Department=$home_dept";
            $images{Home}{tip} = "Default Home page";

            if ($dept ne $home_dept) {
                $images{Current_Dept}{icon} = "home.gif";
                $images{Current_Dept}{url} = "Database_Mode=$dbase_mode&Target_Department=$dept";
                $images{Current_Dept}{tip} = "Home page for the current department";
            }
            
            $images{Issues}{icon} = "bug.png";
            $images{Issues}{name} = 'Bugs';
            
            if ( $dbc->config('jira_link') ) {
                $images{Issues}{link} = $dbc->config('jira_link');
            }
            else {
                $images{Issues}{url} = "Database_Mode=$dbase_mode&Issues_Home=1";
            }

            $images{Login}{icon} = "login.gif";
            $images{Login}{url}  = "Re+Log-In=1&Database_Mode=$dbase_mode";

            $images{Changes}{icon} = "NEW.png";
            $images{Changes}{url}  = "Database_Mode=$dbase_mode&Quick+Help=New_Changes";

            $images{Cap_Run_Stat}{icon} = "Statistics2.png";
            $images{Cap_Run_Stat}{url}  = "cgi_application=" . "Cap_Seq::Run_Stat_App";
            $images{Cap_Run_Stat}{name} = 'Capillary Stats';
            $images{Cap_Run_Stat}{tip}  = "Capillary Run Statiscs";

            $images{Illumina_Run_Stat}{icon} = "Statistics2.png";
            $images{Illumina_Run_Stat}{url}  = "cgi_application=" . "Illumina::Run_Stat_App";
            $images{Illumina_Run_Stat}{name} = 'Illumina Stats';
            $images{Illumina_Run_Stat}{tip}  = "Illumina Run Statiscs";

            $images{SOLID_Run_Stat}{icon} = "Statistics2.png";
            $images{SOLID_Run_Stat}{url}  = "cgi_application=" . "SOLID::Run_Stat_App";
            $images{SOLID_Run_Stat}{name} = 'SOLID SDatabase_Mode=$dbase_modeats';
            $images{SOLID_Run_Stat}{tip}  = "SOLID Run Statiscs";

            $images{Last_24h}{icon} = "hglass2.png";
            $images{Last_24h}{url}  = "Database_Mode=$dbase_mode&Last+24+Hours=1&Include+Runs=Production&Include+Runs=Test";
            $images{Last_24h}{name} = 'Last 24h';
            $images{Last_24h}{tip}  = 'Retrieve Run summaries collected within last 24 hours (or as requested)';

            $images{Solexa_Data}{icon} = "hglass2.png";
            $images{Solexa_Data}{url}  = "Database_Mode=$dbase_mode&Solexa+Summary=1&Include+Runs=Production&Include+Runs=Test";
            $images{Solexa_Data}{name} = 'Solexa';
            $images{Solexa_Data}{tip}  = 'Solexa Run Summary';

            $images{GenechipExpSummary}{icon} = "hglass2.png";
            $images{GenechipExpSummary}{url}  = "Database_Mode=$dbase_mode&Genechip+Expression+Summary=1";
            $images{GenechipExpSummary}{name} = "GCOS Expression Summary";

            $images{GenechipMapSummary}{icon} = "hglass2.png";
            $images{GenechipMapSummary}{url}  = "Database_Mode=$dbase_mode&Genechip+Mapping+Summary=1";
            $images{GenechipMapSummary}{name} = "GCOS Mapping Summary";

            $images{BioanalyzerSummary}{icon} = "hglass2.png";
            $images{BioanalyzerSummary}{url}  = "Database_Mode=$dbase_mode&Bioanalyzer+Summary=1";
            $images{BioanalyzerSummary}{name} = "Bioanalyzer Run Summary";

            $images{GelRunSummary}{icon} = "hglass2.png";
            $images{GelRunSummary}{url}  = "Database_Mode=$dbase_mode&Mapping_Summary=1&Generate+Results=1";
            $images{GelRunSummary}{name} = "Gel Run Summary";

            $images{Solutions}{icon} = "solution.png";
            $images{Solutions}{url}  = "Database_Mode=$dbase_mode&Standard+Page=Solution";

            $images{Equipment}{icon} = "Equipment.png";
            $images{Equipment}{url}  = "Database_Mode=$dbase_mode&Standard+Page=Equipment";
            $images{Equipment}{name} = 'Equipment';

            $images{Rack}{icon} = "shelf.png";
            $images{Rack}{url}  = "Database_Mode=$dbase_mode&cgi_application=alDente::Rack_App&rm=Standard+Page";
            $images{Rack}{name} = 'Location Tracking';

            $images{Stat_App}{icon} = "Statistics2.png";
            $images{Stat_App}{url}  = "cgi_application=" . "$department" . "::Statistics_App&Generate+Results=1";
            $images{Stat_App}{name} = 'Stats';
            $images{Stat_App}{tip}  = "Project level Summaries; (see Summary icon for Laboratory level summaries)";

            ### The icons should not have the name of the dept in them ... delete Database_BC - use Database instead...
            $images{Database_BC}{icon} = "db_update.png";
            $images{Database_BC}{url}  = "cgi_application=" . "$department" . "::Department_App&rm=Database";
            $images{Database_BC}{name} = 'Database';
            $images{Database_BC}{tip}  = "Search and Add to Database Tables";

            $images{Database}{icon} = "db_update.png";
            $images{Database}{url}  = "cgi_application=" . "$department" . "::Department_App&rm=Database";
            $images{Database}{name} = 'Database';
            $images{Database}{tip}  = "Search and Add to Database Tables";

            $images{Modules}{icon} = "db_update.png";
            $images{Modules}{url}  = "cgi_application=alDente::Document_App&rm=View Modules";
            $images{Modules}{name} = 'Modules';
            $images{Modules}{tip}  = "View Help Pages for Modules";

            $images{Summary_App}{icon} = "summary.ico";
            $images{Summary_App}{url}  = "cgi_application=" . "$department" . "::Summary_App";
            $images{Summary_App}{name} = 'Summary';
            $images{Summary_App}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

            $images{Shipments}{icon} = 'box.png';
            $images{Shipments}{name} = 'Shipments';
            $images{Shipments}{url}  = 'cgi_application=alDente::Shipment_App&rm=List+Shipments&LIMIT=' . "$department";

            $images{Sample_Request}{icon} = 'box_request.png';
            $images{Sample_Request}{name} = 'Sample Request';
            $images{Sample_Request}{url}  = 'cgi_application=alDente::Sample_Request_App&LIMIT=' . "$department";

            $images{BioInformatics_Stat}{icon} = "Statistics2.png";
            $images{BioInformatics_Stat}{url}  = "cgi_application=" . "Projects::Statistics_App&Generate+Results=1";
            $images{BioInformatics_Stat}{name} = 'Stats';
            $images{BioInformatics_Stat}{tip}  = "Project level Summaries; (see Summary icon for Laboratory level summaries)";

            $images{BioInformatics_Summary}{icon} = "summary.ico";
            $images{BioInformatics_Summary}{url}  = "cgi_application=" . "Sequencing::Stat_App&rm=Sequencing+Status";
            $images{BioInformatics_Summary}{name} = 'Summary';
            $images{BioInformatics_Summary}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

            ##
            $images{Gene_Summary_App}{icon} = "summary.ico";
            $images{Gene_Summary_App}{url}  = "cgi_application=" . "$department" . "::Summary_App";
            $images{Gene_Summary_App}{name} = 'Genechip Summary';
            $images{Gene_Summary_App}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

            $images{Bio_Summary_App}{icon} = "summary.ico";
            $images{Bio_Summary_App}{url}  = "cgi_application=" . "$department" . "::Bioanalyzer_Summary_App";
            $images{Bio_Summary_App}{name} = 'Bioanalyzer Summary';
            $images{Bio_Summary_App}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

            $images{Solexa_Summary_App}{icon} = "summary.ico";
            $images{Solexa_Summary_App}{url}  = "cgi_application=" . "Illumina::Solexa_Summary_App";
            $images{Solexa_Summary_App}{name} = 'Solexa Summary';
            $images{Solexa_Summary_App}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

            $images{Solid_Summary_App}{icon} = "summary.ico";
            $images{Solid_Summary_App}{url}  = "cgi_application=" . "SOLID::SOLID_Summary_App";
            $images{Solid_Summary_App}{name} = 'Solid Summary';
            $images{Solid_Summary_App}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

            $images{Ion_Torrent_Summary}{icon} = "summary.ico";
            $images{Ion_Torrent_Summary}{url}  = "cgi_applicationlication=" . "Ion_Torrent::Run_Summary_App";
            $images{Ion_Torrent_Summary}{name} = 'Ion Torrent Summary';
            $images{Ion_Torrent_Summary}{tip}  = "Laboratory level Summaries)";

            $images{Lib_Construction_Summary}{icon} = "summary.ico";
            $images{Lib_Construction_Summary}{url}  = "cgi_application=" . "Lib_Construction::Department_App&rm=Summary";
            $images{Lib_Construction_Summary}{name} = 'Lib Construction Summary';

            $images{RNA_DNA_Collections}{icon} = "summary.ico";
            $images{RNA_DNA_Collections}{url}  = "cgi_application=" . "Lib_Construction::Department_App&rm=Summary";
            $images{RNA_DNA_Collections}{name} = 'Lib Construction Summary';

            $images{BioSpec_Summary_App}{icon} = "summary.ico";
            $images{BioSpec_Summary_App}{url}  = "cgi_application=" . "BioSpecimens::Bio_Summary_App";
            $images{BioSpec_Summary_App}{name} = 'BioSpecimen Core Summary';

            #   $images{BioSpec_Summary_App}{tip} = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

            $images{CLIPR_Run_Summary_App}{icon} = "summary.ico";
            $images{CLIPR_Run_Summary_App}{url}  = "cgi_application=" . "CLIPR" . "::Run_Summary_App";
            $images{CLIPR_Run_Summary_App}{name} = 'CLIPR Summary';
            $images{CLIPR_Run_Summary_App}{tip}  = "Laboratory level Summaries";

            $images{Submission_Volume_App}{icon} = "db_update.png";
            $images{Submission_Volume_App}{url}  = "cgi_application=" . "SRA::Data_Submission_App";
            $images{Submission_Volume_App}{name} = 'Data Submission';
            $images{Submission_Volume_App}{tip}  = "Request data submission and view data submission progress information";

            $images{Study_App}{icon} = "biology.png";
            $images{Study_App}{url}  = "cgi_application=" . "alDente::Study_App";
            $images{Study_App}{name} = 'Study';
            $images{Study_App}{tip}  = "Create study and view study information";

            $images{Seq_Stat}{icon} = "Statistics2.png";
            $images{Seq_Stat}{url}  = "cgi_application=Sequencing::Stat_App";
            $images{Seq_Stat}{name} = 'Stats';
            $images{Seq_Stat}{tip}  = "Project level Summaries; (see Summary icon for Laboratory level summaries)";
            ##
            $images{Funding}{icon} = "money_2.png";
            $images{Funding}{url}  = "cgi_application=alDente::Funding_App";
            $images{Funding}{name} = 'Funding';
            $images{Funding}{tip}  = "View Funding Sources/SOWs and retrieve relevant progress information";

            $images{Organization}{icon} = "Organization.png";
            $images{Organization}{url}  = "cgi_application=alDente::Organization_App";
            $images{Organization}{name} = 'Organization';

            $images{Plates}{icon} = "Plate.png";
            $images{Plates}{url}  = "Database_Mode=$dbase_mode&Standard+Page=Plate";
            $images{Plates}{tip}  = "* Click on Plate Icon for advanced plate/tube searches or to define a new Plate Format Type<BR>*For single plate information, just scan any plate and click on the 'Scan' button at the top of the page";

            $images{Tubes}{icon} = "tube.png";
            $images{Tubes}{url}  = $images{Plates}{url};
            $images{Tubes}{name} = 'Plates/Tubes';
            $images{Tubes}{tip}  = $images{Plates}{tip};

            $images{Sources}{icon} = "dna.gif";
            $images{Sources}{url}  = "Database_Mode=$dbase_mode&Standard+Page=Source";
            $images{Sources}{tip}  = "Define new Samples or Starting Material; Search for current Sample sources";

            $images{Status}{icon} = "data.png";
            $images{Status}{url}  = "Database_Mode=$dbase_mode&Sequencing+Status=1";
            $images{Status}{tip}  = "Project level Summaries; (see Summary icon for Laboratory level summaries)";

            $images{Libraries}{icon}             = "lib.png";
            $images{Libraries}{url}              = "Database_Mode=$dbase_mode&Standard+Page=Library";
            $images{"RNA_DNA_Collections"}{icon} = $images{Libraries}{icon};
            $images{"RNA_DNA_Collections"}{url}  = $images{Libraries}{url};
            $images{"RNA_DNA_Collections"}{name} = 'RNA/DNA Collections';

            $images{Contacts}{icon} = "contacts.gif";
            $images{Contacts}{url}  = "cgi_application=alDente::Contact_App";
            $images{Contacts}{tip}  = "Search or Add Contacts, Collaborators, Organizations, and/or Funding Sources";

            $images{Projects}{icon} = "project_icon.gif";
            $images{Projects}{url}  = "Database_Mode=$dbase_mode&cgi_application=alDente::Project_App&Department=$department";
            $images{Projects}{tip}  = "List of current Projects";
            $images{Projects}{name} = 'Projects';

            $images{Admin}{icon} = "admin2.png";
            $images{Admin}{url}  = " => 1=$dbase_mode&Admin+Page=$dept";

            $images{Submission}{name} = "Submissions";
            $images{Submission}{icon} = "submission.jpg";
            $images{Submission}{url}  = "cgi_application=alDente::Submission_App";

            $images{Bioanalyzer_Run_App}{icon} = "summary.ico";
            $images{Bioanalyzer_Run_App}{url}  = "cgi_application=" . "Bioanalyzer::Run_App&rm=Run Summary";
            $images{Bioanalyzer_Run_App}{name} = 'Bioanalyzer Runs Summary';

            $images{QPCR_Run_App}{icon} = "summary.ico";
            $images{QPCR_Run_App}{url}  = "cgi_application=" . "QPCR::Run_App&rm=View Runs";
            $images{QPCR_Run_App}{name} = 'QPCR Run Summary';

            $images{GelRun_App}{icon} = "summary.ico";
            $images{GelRun_App}{url}  = "cgi_application=" . "Gel::Run_App&rm=Run Summary";
            $images{GelRun_App}{name} = 'Gel Runs Summary';

            foreach my $key ( keys %images ) {
                my $user_id = $dbc->config('user_id') || 17;
                my ( $date, $time ) = split ' ', date_time;

                if ( !defined $images{$key}{url} ) {next}
                $images{$key}{url} =~ s /\<USERID\>/$user_id/g;
                $images{$key}{url} =~ s /\<TODAY\>/$date/g;
                $images{$key}{url} =~ s /\<NOW\>/$date $time/g;
            }
        }
        
        return %images;
    
}

return 1;
