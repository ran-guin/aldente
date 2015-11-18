##################
# GelRun_App.pm #
##################
#
# This module is used to monitor GelRuns.
#
package alDente::GelRun_App;

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

use base alDente::Run_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use RGTools::HTML_Table qw(Printout);
use SDB::HTML qw(vspace HTML_Dump);
use alDente::Form;
use SDB::CustomSettings;
use alDente::Validation;

## Run modules required ##
use alDente::GelRun;
use Mapping::Mapping_Summary;
##############################
# global_vars                #
##############################
use vars qw(%Settings %Configs $URL_temp_dir $html_header $project_dir $URL_dir_name);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
#####################
    #       Description:
    #               - set up this App application
    #       Input:
    #               - dbc
    # <snip>
    # Usage Example:
    #       my $gelrun_app = alDente::GelRun_App->new(PARAMS => { dbc => $dbc });
    # </snip>
#####################
    my $self = shift;

    $self->start_mode('Default Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Default Page'      => 'default_page',
        'Home Page'         => 'home_page',
        'List Page'         => 'list_page',
        'Summary Page'      => 'summary_page',
        'Search Page'       => 'search_page',
        'View Gel Lanes'    => 'view_gel_lanes',
        'View Gel Analysis' => 'view_gel_analysis',
        'Do Actions'        => 'do_actions'
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');
    my $gelrun = new alDente::GelRun( -dbc => $dbc );

    $self->param( 'GelRun_Model' => $gelrun, );

    return $self;
}

sub default_page {
#####################
    #       Description:
    #               - This is the default page and default run mode for GelRun_App
    #               - It displays a default page when no IDs were given or redirect to home_page if 1 ID was given or redirect to list page when more than 1 IDs were given
    #       Input:
    #               - $args{-ID} || param('ID')
    #       output:
    #               - GelRun_App default page
    # <snip>
    # Usage Example:
    #       my $gelrun_app = alDente::GelRun_App->new( PARAMS => { dbc => $dbc } );
    #       my $page = $gelrun_app->run();
    # </snip>
#####################

    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $run_id  = $args{-ID} || $q->param('ID');
    my @run_ids = split( ",", $run_id );
    my $page;

    if ( !$run_id ) {

        #Case 0: the default page
        $page = $self->search_page();
    }
    elsif ( @run_ids > 1 ) {

        #Case >1: list_page
        $page = $self->list_page();
    }
    elsif ( @run_ids == 1 ) {

        #Case 1: home_page
        $page = $self->home_page();
    }

    return $page;

}

sub home_page {
#####################
    #       Description:
    #               - This displays information of a gel run
    #               - For example: fields in GelRun, gel run image
    #       Input:
    #               - $args{-ID} || param('ID') where ID is only a single ID
    #       output:
    #               - gel run homepage
    # <snip>
    # Usage Example:
    #       my $page = $gelrun_app->home_page(-ID=>Run_ID) || $gelrun_app->home_page();
    #
    # </snip>
#####################

    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-ID} || $q->param('ID');
    my $page;

    ###Initialize gel run model with gel run id
    my ($gelrun_id) = $dbc->Table_find( "GelRun", "GelRun_ID", "WHERE FK_Run__ID=$run_id" );
    $self->param('GelRun_Model')->load_gelrun( -gelrun_id => $gelrun_id );

    my $Run = new alDente::Run( -dbc => $dbc, -run_id => $run_id );

    #    my $GelRun  = new alDente::GelRun(-dbc=>$dbc,-gelrun_id=>$gelrun_id);
    #    $self->param( 'GelRun_Model' => $GelRun );

    ## Change whatever needs to be changed in run and gelrun tables

    my $summary_table = alDente::Run_App::get_summary_table( -dbc => $dbc, -run_id => $run_id );

    my $details = $Run->display_Record( -tables => $Run->{tables} );
    my $display_run_data = &alDente::Run_Views::show_run_data( -dbc => $dbc, -run_id => $run_id );

    $display_run_data .= vspace(5);
    $display_run_data .= $self->get_gel_stats( -run_id => $run_id );

    my $actionbuttons .= alDente::Form::start_alDente_form( $dbc, -name => 'Actions' );
    $actionbuttons .= $q->hidden( -name => 'cgi_application', -value => 'alDente::GelRun_App', -force => 1 );
    $actionbuttons .= $q->hidden( -name => 'rm',              -value => 'Do Actions',          -force => 1 );
    $actionbuttons .= $q->hidden( -name => 'ID',              -value => "$run_id",             -force => 1 );
    $actionbuttons .= $q->hidden( -name => 'run_id',          -value => "$run_id",             -force => 1 );
    ##action buttons
    $actionbuttons .= $self->_action_buttons();
    $actionbuttons .= $q->end_form();

    my $more_actions = Views::Heading("More Actions");
    $more_actions .= $self->param('GelRun_Model')->display_actions( -return_html => 1 );

    $page .= &Views::Table_Print( content => [ [ $summary_table . vspace(5) . $display_run_data . vspace(5) . $actionbuttons . vspace(5) . $more_actions, $details ] ] );

## To add gel analysis and gel lane table sin, append view_gel_analysis and view_gel_lanes into the Table_Print function above. If they are just appended to the page, they will not be organized neatly into the page's table

    return $page;

}

sub list_page {
#####################
    #       Description:
    #               - This is the default page when more than one IDs were given
    #       Input:
    #               - $args{-ID} || param('ID') where ID is a comma delimited list of IDs
    #       output:
    #               - A page listing information for the given IDs
    # <snip>
    # Usage Example:
    #       my $page = $gelrun_app->list_page();
    #
    # </snip>
#####################

    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $run_id  = $args{-ID} || $q->param('ID');
    my @run_ids = split( ",", $run_id );

    return $self->summary_page();

}

sub summary_page {
#####################
    #       Description:
    #               - This displays a summary of searched runs (work in conjunction with search_page)
    #       Input:
    #               -
    #       output:
    #               -
    # <snip>
    # Usage Example:
    #       my $page = alDente::GelRun_App::summary_page();
    #
    # </snip>
#####################

    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $run_id  = $args{-ID} || $q->param('ID');
    my @run_ids = split( ",", $run_id );
    my $page    = "Hello World GelRun Summary Page<BR>";

    return $page;

}

sub search_page {
#####################
    #       Description:
    #               - This let users search for gelruns with different criteria
    #       Input:
    #               -
    #       output:
    #               -
    # <snip>
    # Usage Example:
    #       my $page = alDente::GelRun_App::search_page();
    #
    # </snip>
#####################

    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $page;

    my $run_app = alDente::Run_App->new( PARAMS => { dbc => $dbc } );
    $page = $run_app->search_page();

    ##search fields specifically for gel runs from the table GelRun
    #GelRun_ID
    #GelRun_Type
    #FKPoured_Employee__ID, FKComb_Equipment__ID, FKAgarose_Solution__ID, FKAgarosePour_Equipment__ID, FKGelBox_Equipment__ID?
    $page .= "GelRun Search Page<br>";
    my $form .= alDente::Form::start_alDente_form( $dbc, -name => 'Search_Page' );
    $form .= $q->hidden( -name => 'cgi_application', -value => 'alDente::GelRun_App', -force => 1 );
    $form .= $q->hidden( -name => 'rm', -value => 'Default Page', -force => 1 );
    $form .= &SDB::HTML::query_form( -dbc => $dbc, -fields => ['Run.Run_ID'] );
    $form .= $q->submit( -name => 'Action', -value => "Search", -class => "Search", -force => 1 );
    $form .= $q->end_form();
    $page .= $form;

    return $page;

}

#<snip>
#run mode that performs actions done by the action buttons
#
#
#</snip>
###############
sub do_actions {
###############
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-ID} || $q->param('ID');
    my $page;

    my $Summary = new Mapping::Mapping_Summary;
    my $ok = $Summary->do_actions( -dbc => $dbc );

    $self->default_page();
    return;
}

sub reprep {
#####################
    #       Description:
    #               -
    #       Input:
    #               -
    #       output:
    #               -
    # <snip>
    # Usage Example:
    #       my $page = alDente::GelRun_App::reprep();
    #
    # </snip>
#####################

    my $self = shift;
    my %args = &filter_input( \@_ );

}

sub recut {
#####################
    #       Description:
    #               -
    #       Input:
    #               -
    #       output:
    #               -
    # <snip>
    # Usage Example:
    #       my $page = alDente::GelRun_App::recut();
    #
    # </snip>
#####################

    my $self = shift;
    my %args = &filter_input( \@_ );

}

sub reload {
#####################
    #       Description:
    #               -
    #       Input:
    #               -
    #       output:
    #               -
    # <snip>
    # Usage Example:
    #       my $page = alDente::GelRun_App::reload();
    #
    # </snip>
#####################

    my $self = shift;
    my %args = &filter_input( \@_ );

}

sub view_gel_lanes {
#####################
    #       Description:
    #               - Dispaly the content of the table Lane in a html table (or maybe a html page)
    #               - Note: the method already in GelRun.pm can try to access it from GelRun_Model first but the method should be move here (see sub display_gel_image)
    #               - Note2: have to be careful about run id <=> gelrun id
    #       Input:
    #               - a run id
    #       output:
    #               - html table for the table Lane
    # <snip>
    # Usage Example:
    #       my $page = $gelrun_app->view_gel_lanes(-run_id=>$run_id);
    #
    # </snip>
#####################

    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-run_id};
    my $hidden = $args{-hidden} || 0;                  ## show hidden fields if param passed in
    my $table  = "Put gel lanes here<br>";

    my $gelidcond = "WHERE FK_Run__ID = $run_id";
    my ($gelrun_id) = $dbc->Table_find( 'GelRun', 'GelRun_ID', "$gelidcond" );

    my $lanefieldcond = "WHERE FK_DBTable__ID = (SELECT DBTable_ID FROM DBTable WHERE DBTable_Name = 'Lane')";
    $lanefieldcond .= " AND Field_Options NOT RLIKE 'Obsolete' AND Field_Options NOT RLIKE 'Removed'";
    if ( !$hidden ) {
        $lanefieldcond .= " AND Field_Options NOT RLIKE 'Hidden'";
    }

    my @lane_fields = $dbc->Table_find( 'DBField', 'Field_Name', $lanefieldcond );
    my $lanecond    = "WHERE FK_GelRun__ID = $gelrun_id";
    my $order       = " ORDER BY Lane_Number";
    my $title       = "Lane Data for GelRun $gelrun_id";
    $table .= $dbc->Table_retrieve_display( 'Lane', \@lane_fields, "$lanecond $order", -return_html => 1, -title => $title );

    return $table;

}

sub view_gel_analysis {
#####################
    #       Description:
    #               - Dispaly the content of the table GelAnalysis in a html table (or maybe a html page)
    #               - Note: Mapping/Mapping_Summary.pm has something very similar (see sub do_actions, param('View_Diagnostic_Page'))
    #       Input:
    #               - a run id
    #       output:
    #               - gel analysis table
    # <snip>
    # Usage Example:
    #       my $gel_analysis = $gelrun_app->view_gel_analysis(-run_id=>$run_id);
    #
    # </snip>
#####################

    my $self   = shift;
    my %args   = &filter_input( \@_, -args => 'run_id', -mandatory => 'run_id' );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-run_id};
    my $table;    ## Put gel analysis here

    my $fieldcondition = "WHERE FK_DBTable__ID = DBTable_ID AND DBTable_Name='GelAnalysis'";
    my @fields         = $dbc->Table_find( 'DBField,DBTable', 'Field_Name', "$fieldcondition" );
    my $condition      = "WHERE FK_Run__ID = $run_id";
    $table .= $dbc->Table_retrieve_display( 'GelAnalysis', \@fields, $condition, -return_html => 1 );

    return $table;

}

sub get_gel_image {
#####################
    #       Description:
    #               -
    #       Input:
    #               - a run id
    #       output:
    #               - a gel image and a link to a full gel image
    # <snip>
    # Usage Example:
    #       my $gel_image = $gelrun_app->get_gel_image(-run_id=>$run_id);
    #
    # </snip>
#####################

    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-run_id};

    #get gel image from file
    my $path = &alDente::Run::get_data_path( -dbc => $dbc, -run_id => $run_id );
    $path =~ s/^.*?Projects\///;
    my $filepath = $path . "/annotated.jpg";
    my $thumb_sm = $path . "/thumb.jpg";

    my $annotated = "$path" . "/annotated.jpg";

    #    my $gel_image = $self->_get_thumbnail_link(-dbc=>$dbc,-key_field_value=>$run_id,-output_value=>$annotated);

    my $gel_image = "<img src='../images/icons/magnify.gif' onMouseOver=\"writetxt('Click to see full size Image')\" onMouseOut='writetxt(0)' onClick=\"window.open('../dynamic/data_home/public/Projects/$filepath')\" width=13 height=13/>
                      <div><img src='../dynamic/data_home/public/Projects/$thumb_sm'/></div>";

    #gel image table
    my $title = "GelRun Image";
    my $gel_image_table = HTML_Table->new( -title => $title );
    $gel_image_table->Set_Row( [$gel_image] );

    return $gel_image_table->Printout(0);

}

sub get_gel_stats {
#####################
    #       Description:
    #               - Given a run id, it will search in the run's data path for stats.html, extract the stats and put into a html table
    #       Input:
    #               - a run id
    #       output:
    #               - Return a html table of gel stats. If stats.html not available yet, it returns a message "Gel Stats Not Available"
    # <snip>
    # Usage Example:
    #       my $gel_stats = $gelrun_app->get_gel_stats(-run_id=>$run_id);
    #
    # </snip>
#####################

    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-run_id};
    my $table;

    my $path = &alDente::Run::get_data_path( -dbc => $dbc, -run_id => $run_id );

    my $annotated = "$path" . "/annotated.jpg";

    $table .= $self->_get_thumbnail_link( -dbc => $dbc, -key_field_value => $run_id, -output_value => $annotated );
    my $title = 'Image and Stats';

    my $stats_table = HTML_Table->new( -title => $title );
    $stats_table->Set_Row( ["Click magnifying for full size image"] );
    $stats_table->Set_Row( ["Click picture to show gel run statistics"] );

    $stats_table->Set_Row( ["$table"] );

    return $stats_table->Printout(0);

}

sub _action_buttons {
#####################
#       Description:
#               - This displays action buttons specific for a GelRun which include:
#               - Pass QC and Approve Run
#               - RePrep
#               - ReCut
#               - ReLoad
#               - View Lanes
#               - View Diagnostic Page
#               - Abort Selected?
#               - Set Test Status?
# (reprep, recut, reload, add comment, set test status, view lanes -> display Lane table, view diagnostic page -> display GelAnalysis table?, pick bands from gelrun to plate (this is for MGC_closure grup not for mapping but still related to a gel run)???)
#
#       Note: These should be moved into GelRun.pm and should be commonly used by GelRun home_page, list_page, default_page, summary_page, etc
#
# <snip>
# Usage Example:
#       my $action_buttons .= $self->_action_buttons();
#
# </snip>
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $buttons;    ## Put GelRun action buttons here

    my $class = "Mapping::Mapping_Summary";
    eval "require $class";
    Message($@) if $@;
    my $view = $class->new( -title => "Gel Run Summary" );

    my %actions = &Mapping::Mapping_Summary::get_actions();
    $buttons = $view->display_actions( -actions => \%actions );

    return $buttons;

}

######################
sub _get_thumbnail_link {
######################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};

    my $run_id      = $args{-key_field_value};            ## run_id
    my $filepath    = $args{-output_value};
    my $project_dir = "/home/aldente/private/Projects";
    $filepath =~ /Projects\/([\w\/\.]+)$/;
    $filepath = $1;

    my $thumb_sm = $filepath;
    $thumb_sm =~ s/annotated\.jpg$/thumb.jpg/;
    my $stats_page = $filepath;
    $stats_page =~ s/annotated\.jpg$/stats.html/;

    my $objid = rand();

    # get the eight least significant figures
    $objid = 'Summary' . substr( $objid, -8 );

    my $return;

    if ( -e "$project_dir/$filepath" ) {

        $return .= "<img src='../images/icons/magnify.gif' onMouseOver=\"writetxt('Click to see full size Image')\" onMouseOut='writetxt(0)' onClick=\"window.open('../dynamic/data_home/public/Projects/$filepath')\" width=25 height=25/>
            <div id='${objid}img' onMouseOver=\"writetxt(this.getAttribute('tip'))\" tip='Click to see statistics' onMouseOut='writetxt(0)'>
                <img src='../dynamic/data_home/public/Projects/$thumb_sm' onClick=\"if(document.getElementById('$objid').style.display=='none') {Effect.BlindDown('$objid')} else {Effect.BlindUp('$objid')}\" />
            </div>
            <div id='$objid' style='display:none;'></div>";

        my $attributes = join ',', $dbc->Table_find( 'Run_Attribute', 'Run_Attribute_ID', "WHERE FK_Run__ID=$run_id" );
        if ( -e "$project_dir/$stats_page" and $attributes ) {
            $return .= "<script>load_content_from_url('$objid','','../dynamic/data_home/public/Projects/$stats_page')</script>";
        }
        else {
            $return .= "<script>document.getElementById('$objid' + 'img').setAttribute('tip','<h3>Summary page is unavailable!</h3>');</script>";
        }
    }
    else {
        $return = "<Img Src ='/$URL_dir_name/images/wells/Pending_Run.png' border=1/>";
        $return .= "Stats not available";
    }

    my ($test_status) = $dbc->Table_find( 'Run', 'Run_Test_Status', "WHERE Run_ID=$run_id" );
    if ( $test_status eq 'Test' ) {
        $return = "<div style='background-color:#FCC'>$return</div>";
    }

    return $return;
}

sub get_Scanner_Actions {
    my $actions = {
        'Solution(1-N)+Equipment[Gel Comb](1-N)+Rack(1-N)' => 'alDente::GelRun_App::gel_request_form',    # Sol88440Equ1623Equ705Rac26206Rac26205
        'Plate(1-N)+Equipment[Gel Box](1-N)+Run(1-N)'      => 'alDente::GelRun_App::start_gel_runs',      # Equ856Pla210300Run84577
    };

    return $actions;
}

sub gel_request_form {
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};                                                                        ## Barcode Scanned

    my $equipment_list = &get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my @equipment_ids = split ',', $equipment_list;

    my @gel_trays;
    my $solutions = &get_aldente_id( $dbc, $barcode, 'Solution' );

    unless ($solutions) {
        return 0;
    }

    my $agarose_pattern = "(Stock_Catalog_Name like '%Agarose%' OR Stock_Catalog_Name like '%Mediaprep%')";
    my @agarose = $dbc->Table_find( "Solution,Stock,Stock_Catalog", 'Solution_ID', "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_ID=FK_Stock__ID AND Solution_ID =$solutions AND $agarose_pattern" );

    unless (@agarose) {
        Message("Error: Solution $solutions : is not an Agarose Solutions");
    }
    else {
        @gel_trays = split ',', &get_aldente_id( $dbc, $barcode, 'Rack' ) if ( $barcode =~ /rac/i );

        if ( @gel_trays && scalar(@gel_trays) != scalar(@equipment_ids) ) {
            Message("Error: Incorrect number of Comb and GelRun Tray scanned");

            #Testing
            #print HTML_Dump(\@gel_trays,\@equipment_ids);
        }
        else {
            require alDente::GelRun;
            alDente::GelRun::gel_request_form( -gel_trays => \@gel_trays, -solution => $solutions, -combs => \@equipment_ids );
        }
    }
}

sub start_gel_runs {
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my @equipment_ids = split ',', $equipment_list;

    my $current_plates = &get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    Message("Starting Gel Runs");
    require alDente::GelRun;
    my @plate_ids = split ',', $current_plates;
    my @runs = split ',', get_aldente_id( $dbc, $barcode, 'Run' );
    alDente::GelRun::start_gelruns( -gelboxes => \@equipment_ids, -plates => \@plate_ids, -gelruns => \@runs ) or &main::leave();

    return 1;
}

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

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
