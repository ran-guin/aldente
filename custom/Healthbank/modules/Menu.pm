##################
# Navigation 
##################
#
# This module is used to customize Navigation settings
#
package Healthbank::Menu;

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

my %Local_Icons;
## This controls the various sections under which ALL icons should appear - some of this may be loaded dynamically via config files instead ##
$Local_Icons{Home}      = [qw(Home Current_Dept)];
$Local_Icons{Lab}       = [qw(Rack Rearrays Equipment_App Sources Plates Tubes Solutions_App Libraries Onyx Barcodes)];
$Local_Icons{Shipments} = [qw(Shipments Receive_Shipment Export In_Transit)];
$Local_Icons{Database}  = [qw(Database_BC Database Queries DBField Import Custom_Import Template XRef System_Monitor Session Modules)];
$Local_Icons{Views}     = [qw(Views)];
$Local_Icons{Summaries} = [qw(Statistics Summary Dept_Summary Dept_Statistics)];
$Local_Icons{Tracking}  = [qw(Funding Study_App Submission_Volume_App)];
$Local_Icons{Runs}      = [qw()];
$Local_Icons{Help}      = [qw(Dept_Help LIMS_Help)];
$Local_Icons{Admin}     = [qw(Contacts Employee Subscription Protocols Pipeline Submission JIRA)];

$Local_Icons{ORDER} = [qw(Home LIMS_Admin Admin Projects Lab Shipments Database Views Summaries Runs Help)];

######################
sub get_Icon_Groups {
######################
    my %args         = &filter_input( \@_, -self => 'Healthbank::Menu');
    my $self = $args{-self} || $args{-Menu};

    my %Icons = $self->SUPER::get_Icon_Groups(%args, -local_icons=>\%Local_Icons, -standard=>0);
    return %Icons;
}

################
sub get_Icons {
################

    my %args         = &filter_input( \@_, -self => 'Healthbank::Menu');
    my $self = $args{-self} || $args{-Menu};

    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc} || $self->dbc;
    my $key          = $args{-key};     ## indicate thumbnail; otherwise retrieves array of defined icons
    my $dept         = $args{-dept};

    $args{-self} = '';
    my %images = $self->SUPER::get_Icons(%args);

    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

        $images{Healthbank_Help}{icon} = "help.gif";
        $images{Healthbank_Help}{url}  = "cgi_application=Healthbank::Department_App";
        $images{Healthbank_Help}{name} = "Healthbank Help";
        $images{Healthbank_Help}{tip}  = "General Help for using Healthbank LIMS";

        $images{Pipeline}{icon} = "data.png";
        $images{Pipeline}{url}  = "Pipeline+Summary=1";
        $images{Pipeline}{name} = "Pipeline Summary";
        $images{Pipeline}{tip}  = "Retrieve details for individual Pipelines or Protocols";

        $images{Custom_Import}{icon} = 'uplink.png';
        $images{Custom_Import}{name} = 'Custom Upload';
        $images{Custom_Import}{url}  = 'cgi_application=alDente::Transform_App';

        $images{JIRA}{icon} = "ssheet.png";
        $images{JIRA}{url}  = "cgi_application=Plugins::JIRA::Jira_App&rm=Generate+Report&Days=60&Project=Healthbank";
        $images{JIRA}{name} = 'JIRA Tickets';
        $images{JIRA}{tip}  = "view progress on JIRA tickets";

        $images{Onyx}{icon} = "mini_stripe.png";
        $images{Onyx}{url}  = "cgi_application=Healthbank::App&rm=Onyx Barcoding";
        $images{Onyx}{name} = 'Onyx Barcoding';
        $images{Onyx}{tip}  = "Onyx Barcoding Encryption / Decryption";
        
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

        return %images;    
}

return 1;
