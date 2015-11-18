##################
# Navigation
##################
#
# This module is used to customize Navigation settings
#
package alDente::Menu;

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
$Std_Icons{LIMS_Admin} = [qw(Session)];
$Std_Icons{Home}       = [qw(Home Current_Dept)];
$Std_Icons{Admin}      = [qw(Submission Pipeline Protocols Employee Sources Contacts Subscription JIRA Sample_Request)];
$Std_Icons{Shipments}  = [qw(Shipments Receive_Shipment Export In_Transit)];
$Std_Icons{Lab}        = [qw(Rack Rearrays Plates Tubes Equipment_App Libraries Barcodes)];
$Std_Icons{Projects}   = [qw( Dept_Projects All_Projects)];

######################
sub get_Icon_Groups {
######################
    my %args        = &filter_input( \@_, -self => 'alDente::Menu');
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
    my %args        = &filter_input( \@_, -self => 'alDente::Menu');
    my $self = $args{-self} || $args{-Menu};
    my $custom_icons = $args{-custom_icons};
    my $dbc          = $args{-dbc} || $self->dbc;
    my $key          = $args{-key};                                       ## indicate thumbnail; otherwise retrieves array of defined icons
    my $standard     = defined $args{-standard} ? $args{-standard} : 1;

    my %images = $self->SUPER::get_Icons(%args);

    my %custom_images;
    if ($custom_icons) { %custom_images = %$custom_icons }

    if ($standard) {
        ## Database independent Icons ##
        $images{Subscription}{icon} = "envelope.gif";
        $images{Subscription}{url}  = "cgi_application=alDente::Subscription_Event_App";
        $images{Subscription}{name} = "Subscription";

        $images{Protocols}{icon} = "data.png";
        $images{Protocols}{url}  = "cgi_application=alDente::Protocol_App";
        $images{Protocols}{name} = "Lab Protocols";
        $images{Protocols}{tip}  = "Retrieve details or edit Lab Protocols";

        $images{Solutions_App}{icon} = "solution.png";
        $images{Solutions_App}{url}  = "cgi_application=alDente::Solution_App";
        $images{Solutions_App}{name} = "Solution";
        $images{Solutions_App}{tip}  = "* For new reagents: go to the 'Purchasing' page to barcode a new reagent<BR>* For new solutions: simply scan their barcodes and click on the main 'Scan' button at the top of the page";

        $images{Views}{icon} = "data.png";
        $images{Views}{url}  = "cgi_application=" . "alDente::View_App&Sections=Public,Internal,Group,Employee,Other";
        $images{Views}{name} = 'Views';
        $images{Views}{tip}  = "Create and use views";

        $images{DBField}{icon} = "help.gif";
        $images{DBField}{url}  = "cgi_application=alDente::DBField_App";

        $images{All_Projects}{icon} = "project_icon.gif";
        $images{All_Projects}{url}  = "cgi_application=alDente::Project_App&rm=List Projects";
        $images{All_Projects}{name} = "Projects List";
        $images{All_Projects}{tip}  = "Retrieve details for individual Pipelines or Protocols";

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

        $images{Maintenance}{icon} = 'wrench.png';

        $images{Storage}{icon}        = 'freezer2.png';
        $images{'Moves To'}{icon}     = 'right_arrow1.png';
        $images{Approval}{icon}       = 'Approval.ico';
        $images{Customize}{icon}      = 'Customize.png';
        $images{Approved}{icon}       = 'Approved.png';
        $images{Processed}{icon}      = 'processed.png';
        $images{Sample_Request}{icon} = 'box_request.png';
        $images{Preferences}{icon}    = 'tools_2.png';

        $images{Xref}{icon} = 'Reference.gif';
        $images{Xref}{name} = 'Xref Templates';

        $images{Expandable}{icon} = 'wired.png';
        $images{Expandable}{name} = 'Expandable Templates';

        $images{Test_Tubes}{icon} = 'test_tubes.png';
        $images{Test_Tubes}{name} = 'Solutions';

        ### Database specific Icons ###
        if ($dbc) {
            my $homelink     = $dbc->homelink();
            my $installation = $dbc->config('installation');
            my $dbase_mode   = $dbc->config('Database_Mode');
            my $dept         = $dbc->config('Target_Department');
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

            $images{Solutions}{icon} = "solution.png";
            $images{Solutions}{url}  = "Database_Mode=$dbase_mode&Standard+Page=Solution";

            $images{Equipment}{icon} = "Equipment.png";
            $images{Equipment}{url}  = "Database_Mode=$dbase_mode&Standard+Page=Equipment";
            $images{Equipment}{name} = 'Equipment';

            $images{Rack}{icon} = "shelf.png";
            $images{Rack}{url}  = "Database_Mode=$dbase_mode&cgi_application=alDente::Rack_App&rm=Standard+Page";
            $images{Rack}{name} = 'Location Tracking';

            ### The icons should not have the name of the dept in them ... delete Database_BC - use Database instead...

            $images{Database}{icon} = "db_update.png";
            $images{Database}{url}  = "cgi_application=" . "$department" . "::Department_App&rm=Database";
            $images{Database}{name} = 'Database';
            $images{Database}{tip}  = "Search and Add to Database Tables";

            $images{Modules}{icon} = "db_update.png";
            $images{Modules}{url}  = "cgi_application=alDente::Document_App&rm=View Modules";
            $images{Modules}{name} = 'Modules';
            $images{Modules}{tip}  = "View Help Pages for Modules";

            $images{Shipments}{icon} = 'box.png';
            $images{Shipments}{name} = 'Shipments';
            $images{Shipments}{url}  = 'cgi_application=alDente::Shipment_App&rm=List+Shipments&LIMIT=' . "$department";

            $images{Study_App}{icon} = "biology.png";
            $images{Study_App}{url}  = "cgi_application=" . "alDente::Study_App";
            $images{Study_App}{name} = 'Study';
            $images{Study_App}{tip}  = "Create study and view study information";

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

            $images{Admin}{icon} = "admin2.png";
            $images{Admin}{url}  = " => 1=$dbase_mode&Admin+Page=$dept";

            $images{Submission}{name} = "Submissions";
            $images{Submission}{icon} = "submission.jpg";
            $images{Submission}{url}  = "cgi_application=alDente::Submission_App";

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

return 1;
