##################
# Navigation 
##################
#
# This module is used to customize Navigation settings
#
package GSC_External::Menu;

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
$Local_Icons{Home}      = [qw(Home)];
$Local_Icons{Help}      = [qw(Contact_Us Dept_Help LIMS_Help)];

$Local_Icons{ORDER} = [qw(Home Help)];

######################
sub get_Icon_Groups {
######################
    my %args         = &filter_input( \@_, -self=>'alDente::Menu');
    my $self = $args{-self} || $args{-Menu};

    my %Icons = alDente::Menu::get_Icon_Groups(%args, -local_icons=>\%Local_Icons, -standard=>0);
    return %Icons;
}

################
sub get_Icons {
################
    my %args         = &filter_input( \@_, -self=>'alDente::Menu');
    my $self = $args{-self} || $args{-Menu};
    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc};
    my $key          = $args{-key};     ## indicate thumbnail; otherwise retrieves array of defined icons

    my %images = alDente::Menu::get_Icons(%args, -standard=>0);
    
    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

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
            my $department = $dept;
            
            $department =~ s/ /_/;
           
            foreach my $key ( keys %images ) {
                my $user_id = $dbc->config('user_id');
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
