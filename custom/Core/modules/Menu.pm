##################
# Navigation 
##################
#
# This module is used to customize Navigation settings
#
package Core::Menu;

use base SDB::Menu;

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
$Local_Icons{Database}  = [qw(Database Queries DBField Template XRef System_Monitor Session Modules)];
$Local_Icons{Views}     = [qw(Views)];
$Local_Icons{Help}      = [qw(Dept_Help LIMS_Help)];
$Local_Icons{Admin}     = [qw(Contacts)];

$Local_Icons{ORDER} = [qw(Home LIMS_Admin Admin Database Views Help)];

sub get_Icon_Groups {
######################
    my %args         = &filter_input( \@_, -self => 'SDB::Menu');
    my $self = $args{-self} || $args{-Menu};

    my %Icons = SDB::Menu::get_Icon_Groups(%args, -local_icons=>\%Local_Icons, -standard=>0);
    return %Icons;
}

################
sub get_Icons {
################
    my %args         = &filter_input( \@_, -self => 'SDB::Menu');
    my $self = $args{-self} || $args{-Menu};
    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc};
    my $key          = $args{-key};     ## indicate thumbnail; otherwise retrieves array of defined icons

    my %images = SDB::Menu::get_Icons(%args);
    
    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

        $images{Core_Help}{icon} = "help.gif";
        $images{Core_Help}{url}  = "cgi_application=Core::Department_App";
        $images{Core_Help}{name} = "Core Help";
        $images{Core_Help}{tip}  = "General Help for using Core LIMS";
        
        $images{Maintenance}{icon} = 'wrench.png';

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
