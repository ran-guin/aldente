package LampLite::Menu;

use base LampLite::DB_Object;
##################
# Navigation
##################
#
# This module is used to customize Navigation settings
#
# To enable a menu element to be displayed within a group.
#
#   * Make sure the %Std_Icons or %Local_Icons (NOT inherited) contains desired keys (groups), and lists menu item as array element within a group
#   * Make sure the menu item is defined as a key in the get_Icons method (uses inheritance)
#   * Make sure the menu item above is listed under a section within the Menu.pm file (uses inheritance)
#   * Make sure the menu item is listed in the full list of Department-specific @icon_list in Department.pm (no inheritance)
#
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
# eg:
# $Std_Icons{Home}       = [qw(Home Current_Dept)];
# $Std_Icons{Shipments}  = [qw(Shipments Receive_Shipment Export In_Transit)];
#
######################
sub get_Icon_Groups {
######################
    my %args        = &filter_input( \@_, -self => 'LampLite::Menu');
    my $self = $args{-self} || $args{-Menu};
    
    my $dept        = $args{-dept};
    my $local_icons = $args{-local_icons};
    my $standard    = defined $args{-standard} ? $args{-standard} : 1;

    my %Icons;

    if ($standard) {
        %Icons = %Std_Icons;
        ## add dept specific icons ##
		if ($dept) { 
		 	## eg .... push @{ $Icons{Summaries} }, "${dept}_Stat", "${dept}_Summary" }
        }
    }

    if ($local_icons) {
        my %Local_Icons = %$local_icons;
        foreach my $key ( keys %Icons ) {
            if ( defined $Local_Icons{$key} ) {
                $Icons{$key} = $Local_Icons{$key}; 
            }
        }

        foreach my $key ( keys %Local_Icons ) {
            if ( defined $Icons{$key} ) {next}
            my %add;
            $add{$key} = $Local_Icons{$key};
            %Icons = ( %Icons, %add );
        }
    }

    return %Icons;
}

################
sub get_Icons {
################
    my %args        = &filter_input( \@_, -self => 'LampLite::Menu');
    my $self = $args{-self} || $args{-Menu};
    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc};
    my $key          = $args{-key};                                       ## indicate thumbnail; otherwise retrieves array of defined icons
    my $standard     = defined $args{-standard} ? $args{-standard} : 1;

    my %images;

    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

    if ($standard) {
        ## Database independent Icons ##

        $images{Help}{icon} = "help.gif";
        $images{Help}{link} = "help.pl";
        $images{Help}{url}  = "cgi_app=LampLite::View_App&rm=Help";

        ### Database specific Icons ###
        if ($dbc) {
            my $homelink     = $dbc->homelink();
            $images{Database}{icon} = "db_update.png";
            $images{Database}{url}  = "cgi_application=LampLite::View_App&rm=Database";
            $images{Database}{name} = 'Database';
            $images{Database}{tip}  = "Search and Add to Database Tables";

            #
            # The block below needs to be moved down below the inclusion of the custom_images
            #
            # leaving it here temporarily until all calls with undef dbc are fixed
            #

            foreach my $key ( keys %images ) {
                my $user_id = $dbc->config('user_id');
                my ( $date, $time ) = split ' ', date_time;

                if ( !defined $images{$key}{url} ) {next}
                $images{$key}{url} =~ s /\<USERID\>/$user_id/g;
                $images{$key}{url} =~ s /\<TODAY\>/$date/g;
                $images{$key}{url} =~ s /\<NOW\>/$date $time/g;
            }
        }
        else {
            Message("Please change code to pass dbc to this method");
            Call_Stack();
        }
    }

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
