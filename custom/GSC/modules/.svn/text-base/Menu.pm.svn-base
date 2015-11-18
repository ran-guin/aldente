##################
# Navigation
##################
#
# This module is used to customize Navigation settings
#
package GSC::Menu;

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

## Default settings ##

my %Local_Icons;
## This controls the various sections under which ALL icons should appear - some of this may be loaded dynamically via config files instead ##
$Local_Icons{Lab}      = [qw(Rack Rearrays Plates Tubes Equipment_App Solutions_App Libraries RNA_DNA_Collections Pool_ReArray Pool_ReArray_to_Tube Barcodes POG)];
$Local_Icons{Database} = [qw(Database_BC Database Queries DBField Import Custom_Import Template XRef System_Monitor Modules)];
$Local_Icons{Views}    = [qw(Views)];
$Local_Icons{Summaries}
    = [
    qw(Last_24h Daily_Planner Seq_Stat Solexa_Summary_App Stat_App Ion_Torrent_Summary Summary_App Bioinformatics_Stat Solexa_Summary_App_NO_filter Solid_Summary_App_NO_filter Solid_Summary_App Bioanalyzer_Run_App CLIPR_Run_App QPCR_Run_App GelRun_App AATI_Run_App Lib_Construction_Summary)
    ];
$Local_Icons{Projects}  = [qw(Dept_Projects All_Projects Funding Study_App Submission_Volume_App)];
$Local_Icons{Runs}      = [qw()];
$Local_Icons{Help}      = [qw( LIMS_Help )];
$Local_Icons{Shipments} = [qw(GSC_Shipments Shipments Receive_Shipment Export In_Transit)];

$Local_Icons{ORDER} = [qw(Home LIMS_Admin Admin Projects Lab Shipments Database Views Summaries Runs Help)];

######################
sub get_Icon_Groups {
######################
    my %args = &filter_input( \@_, -self=>'alDente::Menu' );
    my $self = $args{-self} || $args{-Menu};
    my %Icons = $self->SUPER::get_Icon_Groups( %args, -local_icons => \%Local_Icons );

    return %Icons;
}

################
sub get_Icons {
################
    my %args = &filter_input( \@_, -self=>'alDente::Menu' );
    my $self = $args{-self} || $args{-Menu};
    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc};
    my $key          = $args{-key};                                  ## indicate thumbnail; otherwise retrieves array of defined icons

    my %images = $self->SUPER::get_Icons(%args);

    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

    ## Database independent Icons ##
    $images{Daily_Planner}{icon} = "Daily_Planner.png";
    $images{Daily_Planner}{url}  = "cgi_application=Cap_Seq::Statistics_App";
    $images{Daily_Planner}{name} = "Daily Planner";
    $images{Daily_Planner}{tip}  = "customized Daily Planner views for Sequencing group";

    $images{BioInformatics_Stat}{icon} = "Statistics2.png";
    $images{BioInformatics_Stat}{url}  = "cgi_application=" . "Projects::Statistics_App&Generate+Results=1";
    $images{BioInformatics_Stat}{name} = 'Stats';
    $images{BioInformatics_Stat}{tip}  = "Project level Summaries; (see Summary icon for Laboratory level summaries)";

    $images{BioInformatics_Summary}{icon} = "summary.ico";
    $images{BioInformatics_Summary}{url}  = "cgi_application=" . "Sequencing::Stat_App&rm=Sequencing+Status";
    $images{BioInformatics_Summary}{name} = 'Summary';
    $images{BioInformatics_Summary}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

    $images{Pipeline}{icon} = "data.png";
    $images{Pipeline}{url}  = "Pipeline+Summary=1";
    $images{Pipeline}{name} = "Pipeline Summary";
    $images{Pipeline}{tip}  = "Retrieve details for individual Pipelines or Protocols";

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

    $images{Custom_Import}{icon} = 'uplink.png';
    $images{Custom_Import}{name} = 'Custom Upload';
    $images{Custom_Import}{url}  = 'cgi_application=alDente::Transform_App';

    $images{POG}{icon} = 'POG.png';
    $images{POG}{name} = 'POG Home';
    $images{POG}{url}  = 'cgi_application=POG::POG_App';

    $images{Sample_Sheets}{icon} = "ssheet.png";
    $images{Sample_Sheets}{url}  = "Sample+Sheets=1";
    $images{Sample_Sheets}{name} = 'Sample Sheets';

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
        my $homelink   = $dbc->homelink();
        my $dbase_mode = $dbc->config('Database_Mode');
        my $dept       = $dbc->config('Target_Department');
        my $home_dept  = $dbc->session->param('home_dept');

        my $department = $dept;
        $department =~ s/ /_/;

        $images{GSC_Shipments}{icon} = 'box.png';
        $images{GSC_Shipments}{name} = "Shipments to/from $department";
        $images{GSC_Shipments}{url}  = 'cgi_application=GSC::App&rm=Custom Shipment Display&LIMIT=' . $department;

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
        $images{Last_24h}{url}  = "Database_Mode=$dbase_mode&cgi_application=SequenceRun::Run_App&rm=Last+24+Hours&Include+Runs=Production&Include+Runs=Test";
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

        $images{Stat_App}{icon} = "Statistics2.png";
        $images{Stat_App}{url}  = "cgi_application=" . "$department" . "::Statistics_App&Generate+Results=1";
        $images{Stat_App}{name} = 'Stats';
        $images{Stat_App}{tip}  = "Project level Summaries; (see Summary icon for Laboratory level summaries)";

        ### The icons should not have the name of the dept in them ... delete Database_BC - use Database instead...

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

        $images{"RNA_DNA_Collections"}{icon} = $images{Libraries}{icon};
        $images{"RNA_DNA_Collections"}{url}  = $images{Libraries}{url};
        $images{"RNA_DNA_Collections"}{name} = 'RNA/DNA Collections';

        $images{Bioanalyzer_Run_App}{icon} = "summary.ico";
        $images{Bioanalyzer_Run_App}{url}  = "cgi_application=" . "Bioanalyzer::Run_App&rm=Run Summary";
        $images{Bioanalyzer_Run_App}{name} = 'Bioanalyzer Runs Summary';

        $images{CLIPR_Run_App}{icon} = "summary.ico";
        $images{CLIPR_Run_App}{url}  = "cgi_application=" . "CLIPR::Run_App&rm=Run Summary";
        $images{CLIPR_Run_App}{name} = 'Caliper Runs Summary';

        $images{QPCR_Run_App}{icon} = "summary.ico";
        $images{QPCR_Run_App}{url}  = "cgi_application=" . "QPCR::Run_App&rm=View Runs";
        $images{QPCR_Run_App}{name} = 'QPCR Run Summary';

        $images{GelRun_App}{icon} = "summary.ico";
        $images{GelRun_App}{url}  = "cgi_application=" . "Gel::Run_App&rm=Run Summary";
        $images{GelRun_App}{name} = 'Gel Runs Summary';

        $images{AATI_Run_App}{icon} = "summary.ico";
        $images{AATI_Run_App}{url}  = "cgi_application=" . "AATI::Run_App&rm=Run Summary";
        $images{AATI_Run_App}{name} = 'AATI Runs Summary';

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
