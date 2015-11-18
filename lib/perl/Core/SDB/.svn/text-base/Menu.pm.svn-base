# This module is used to customize Navigation settings
#
package SDB::Menu;

use base LampLite::Menu;

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
$Std_Icons{Site_Admin} = [qw(Session)];
$Std_Icons{Home}       = [qw(Home Current_Dept)];
$Std_Icons{Admin}      = [qw(Submission Pipeline Protocols Employee Sources Contacts Subscription JIRA Sample_Request)];
$Std_Icons{Shipments}  = [qw(Shipments Receive_Shipment Export In_Transit)];
$Std_Icons{Lab}        = [qw(Rack Rearrays Plates Tubes Equipment_App Libraries Barcodes)];
$Std_Icons{Projects}   = [qw( Dept_Projects All_Projects)];

######################
sub get_Icon_Groups {
######################
    my %args        = &filter_input( \@_, -self => 'SDB::Menu');
    my $self = $args{-self} || $args{-Menu};
    
    my $dept        = $args{-dept};
    my $local_icons = $args{-local_icons};
    my $standard    = defined $args{-standard} ? $args{-standard} : 1;

    my %Icons;

    if ($standard) {
        %Icons = %Std_Icons;
        if ($dept) { push @{ $Icons{Summaries} }, "${dept}_Stat", "${dept}_Summary" }
        if ($dept) { push @{ $Icons{Help} }, "${dept}_Help" }
    }

    if ($local_icons) {
        my %Local_Icons = %$local_icons;
        foreach my $key ( keys %Icons ) {
            if ( defined $Local_Icons{$key} ) {
                $Icons{$key} = $Local_Icons{$key};    ## override existing settings ...
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
    my %args        = &filter_input( \@_, -self => 'SDB::Menu');
    my $self = $args{-self} || $args{-Menu};
    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc} || $self->dbc;
    my $key          = $args{-key};                                       ## indicate thumbnail; otherwise retrieves array of defined icons
    my $standard     = defined $args{-standard} ? $args{-standard} : 1;
    my $dept         = $args{-dept} || $dbc->config('Target_Department');

    my %images;

    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

    if ($standard) {
        $images{DBField}{icon} = "help.gif";
        $images{DBField}{url}  = "cgi_application=alDente::DBField_App";

        $images{Help}{icon} = "help.gif";
        $images{Help}{link} = "help.pl";

        $images{Queries}{icon} = "help.gif";
        $images{Queries}{url}  = "cgi_application=alDente::View_App&Open+View=1";

        $images{Search}{icon} = 'flashlight.png';
        $images{Search}{name} = 'Search';
        $images{Search}{url}  = 'cgi_application';

        $images{Receiving}{icon} = 'truck.jpg';


        ### Database specific Icons ###
        if ($dbc) {
            my $homelink     = $dbc->homelink();
            my $installation = $dbc->config('installation');
            my $dbase_mode   = $dbc->config('Database_Mode');
            my $home_dept    = $dbc->session->param('home_dept');
            my $department   = $dept;
            $department =~ s/ /_/;

            $images{Home}{icon} = "home.gif";
            $images{Home}{url}  = "Database_Mode=$dbase_mode&Target_Department=$home_dept";
            $images{Home}{tip}  = "Default Home page";

            if ( $dept ne $home_dept ) {
                $images{Current_Dept}{icon} = "home.gif";
                $images{Current_Dept}{url}  = "Database_Mode=$dbase_mode&Target_Department=$dept";
                $images{Current_Dept}{tip}  = "Home page for the current department";
            }

            $images{Login}{icon} = "login.gif";
            $images{Login}{url}  = "Re+Log-In=1&Database_Mode=$dbase_mode";

            $images{Changes}{icon} = "NEW.png";
            $images{Changes}{url}  = "Database_Mode=$dbase_mode&Quick+Help=New_Changes";

         ## Installation specific pages ##

            $images{Summary}{icon} = "summary.ico";
            $images{Summary}{url}  = "cgi_application=${installation}::Summary_App";
            $images{Summary}{name} = "$installation Summary";
            $images{Summary}{tip}  = "Summary information from $installation LIMS";

            $images{Statistics}{icon} = "summary.ico";
            $images{Statistics}{url}  = "cgi_application=${installation}::Statistics_App";
            $images{Statistics}{name} = "$installation Stats";
            $images{Statistics}{tip}  = "General Statistics from $installation LIMS";

            ## Department specific Pages ##
            $images{Dept_Projects}{icon} = "project_icon.gif";
            $images{Dept_Projects}{url}  = "Database_Mode=$dbase_mode&cgi_application=alDente::Project_App&Department=$department";
            $images{Dept_Projects}{tip}  = "List of current Projects";
            $images{Dept_Projects}{name} = "$department Projects";

            $images{Dept_Summary}{icon} = "summary.ico";
            $images{Dept_Summary}{url}  = "cgi_application=" . "$department" . "::Summary_App";
            $images{Dept_Summary}{name} = $department . '_Summary';
            $images{Dept_Summary}{tip}  = $department . '_Summary';

            $images{Dept_Statistics}{icon} = "Statistics2.png";
            $images{Dept_Statistics}{url}  = "cgi_application=" . "$department" . "::Statistics_App";
            $images{Dept_Statistics}{name} = "$department Stats";
            $images{Dept_Statistics}{tip}  = $department . '_Statistics';

            $images{Dept_Help}{icon} = "help.gif";
            $images{Dept_Help}{url}  = "cgi_application=" . "$department" . "::Help_App";
            $images{Dept_Help}{name} = $department . '_Help';
            $images{Dept_Help}{tip}  = $department . '_Help';

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
