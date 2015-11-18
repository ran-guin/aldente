##################
# Navigation 
##################
#
# This module is used to customize Navigation settings
#
package UTM::Menu;


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

my %Local_Icons;
## This controls the various sections under which ALL icons should appear - some of this may be loaded dynamically via config files instead ##
$Local_Icons{Home}      = [qw(Home Current_Dept)];
$Local_Icons{Lab}       = [qw(Rack Rearrays Plates Tubes Solutions_App Libraries Onyx Barcodes)];
$Local_Icons{Shipments} = [qw(Shipments Receive_Shipment Export In_Transit)];
$Local_Icons{Database}  = [qw(Database_BC Database Queries DBField Import Custom_Import Template XRef System_Monitor Session Modules)];
$Local_Icons{Views}     = [qw(Views)];
$Local_Icons{Summaries} = [qw(UTM_Statistics Summary_App Dept_Summary Dept_Statistics)];
$Local_Icons{Tracking}  = [qw(Funding Study_App Submission_Volume_App)];
$Local_Icons{Runs}      = [qw()];
$Local_Icons{Help}      = [qw(Dept_Help LIMS_Help)];


######################
sub get_Icon_Groups {
######################
    my %args         = &filter_input( \@_);

    my %Icons; ##  = alDente::Menu::get_Icon_Groups(%args, -local_icons=>\%Local_Icons);
    return %Icons;
}

################
sub get_Icons {
################
    my %args         = &filter_input( \@_);
    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc};
    my $key          = $args{-key};     ## indicate thumbnail; otherwise retrieves array of defined icons

    my %images; ## = alDente::Menu::get_Icons(%args);
    
    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

        ## Database independent Icons ##
        $images{UTM_Statistics}{icon} = "data.png";
        $images{UTM_Statistics}{url}  = "cgi_application=UTM::Statistics_App";
        $images{UTM_Statistics}{name} = "UTM Statistics";
        $images{UTM_Statistics}{tip}  = "General Stats from the UTM LIMS";

        $images{UTM_Help}{icon} = "help.gif";
        $images{UTM_Help}{url}  = "cgi_application=UTM::Department_App";
        $images{UTM_Help}{name} = "UTM Help";
        $images{UTM_Help}{tip}  = "General Help for using UTM LIMS";

        ### Database specific Icons ###
        if ($dbc) {
            my $homelink = $dbc->homelink();
            my $dbase_mode = $dbc->config('Database_Mode');
            my $dept       = $dbc->config('Target_Department');
            my $home_dept  = $dbc->session->param('home_dept');
            my $department = $dept;
            
            $department =~ s/ /_/;
        }
        
        return %images;
    
}

return 1;
