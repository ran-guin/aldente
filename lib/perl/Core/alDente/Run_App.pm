##################
# Run_App.pm #
##################
#
# This module is used to monitor Runs.
#
package alDente::Run_App;

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

use base RGTools::Base_App;
use strict;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use RGTools::HTML_Table qw(Printout);
use RGTools::RGmath qw(merge_Hash);
use SDB::DBIO;
use SDB::HTML qw(vspace HTML_Dump);

## Run modules required ##
use alDente::Run;
use alDente::Run_Views;
use alDente::Run_Info;
use alDente::Equipment_Views;
##############################
# global_vars                #
##############################
use vars qw(%Configs %Settings $URL_temp_dir $html_header );    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Default Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Default Page'  => 'default_page',
        'Home Page'     => 'home_page',
        'List Page'     => 'list_page',
        'Summary Page'  => 'summary_page',
        'Search Page'   => 'search_page',
        'View Runs'     => 'view_Runs',
        'View Analysis' => 'view_Analysis',

        'Remove Run Request'    => 'remove_Run_Request',
        'Mark Failed Runs'      => 'mark_Failed_Runs',
        'Annotate Run Comments' => 'annotate_Run_Comments',
        'Set Run Test Status'   => 'set_run_test_status',
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');
    my $run = new alDente::Run( -dbc => $dbc );

    $self->param( 'Run_Model' => $run, );

    return $self;
}

#####################
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
    #               - This displays all common information of different types of run for a single run
    #               - For example, fields in Run and Container
    #               - Then use subclass Run_App (e.g. GelRun_App) to display specific infomration about a type of a run
    #       Input:
    #               - a run id
    #       output:
    #               - home page of a run
    # <snip>
    # Usage Example:
    #       my $page = alDente::Run_App::home_page(-id=>Run_ID);
    #
    # </snip>
#####################

    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-id} || $q->param('ID');
    my $page;

    if ( !$run_id ) { return $self->search_page() }

    my $Run = new alDente::Run( -dbc => $dbc, -run_id => $run_id );
    $self->param( 'Run_Model' => $Run, );

    # load data for the run id
    $self->param('Run_Model')->load_run( -run_id => $run_id, -quick_load => 1 );

    my $run_type = $self->param('Run_Model')->get_run_type();
    my $app = &get_app( -run_type => $run_type );

    if ( eval "require $app" ) {

        #initializing new sub type Run_App and run that app if it exists
        my $subrun_app = $app->new( PARAMS => { dbc => $dbc } );
        $page .= $subrun_app->home_page( -id => $run_id );
    }
    else {

        #default run model home page if no Run_App exists
        $page .= $self->param('Run_Model')->home_page( -dbc => $dbc, -run_id => $run_id );

    }

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
    #       my $page = $run_app->list_page();
    #
    # </snip>
#####################

    my $self = shift;

    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $run_id  = $args{-ID} || $q->param('ID');
    my @run_ids = split( ",", $run_id );

    my $output = 'Multiple run information here';
    $output .= $q->hr;

    #    $output .= $self->summary_page();

    return $output;
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
    #       my $page = alDente::Run_App::summary_page();
    #
    # </snip>
#####################

    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $run_id  = $args{-ID} || $q->param('ID');
    my @run_ids = split( ",", $run_id );
    my $page    = "Hello World Run Summary Page<BR>";

    return $page;

}

sub search_page {
#####################
    #       Description:
    #               - This let users search for runs with different criteria
    #               - It display common fields first such as dates and run ids
    #               - then once user chooses a run type, dynamically generate fields for the run type
    #
    #               - or this just calls the appropriate search_page of the run type and have a common Run_App sub that all differnt Run_App uses
    #       Input:
    #               - Nothing
    #       output:
    #               - A search form for users to enter values to search
    # <snip>
    # Usage Example:
    #       my $page = alDente::Run_App::search_page();
    #
    # </snip>
#####################

    my $self = shift;
    my %args = &filter_input( \@_ );
    my $page;

    $page = "Hello World Run Search Page<br>";
    ###common search fields for all runs (e.g. fields in Run table)
    ##Run_ID
    ##FK_Plate__ID
    ##FK_RunBatch__ID
    ##Run_DateTime
    ##Run_Test_Status
    ##Run_status
    ##Run_Validation
    ##QC_Status

    return $page;

}

sub set_run_test_status {
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $run_id  = $args{-id};
    my @run_ids = ();
    @run_ids = Cast_List( -list => $run_id, -to => 'Array' );
    unless ($run_id) {
        @run_ids = $q->param('run_id');
    }
    my $test_status = $args{-test_status} || $q->param('Run_Test_Status');
    if (@run_ids) {
        alDente::Run::set_run_test_status( -run_id => \@run_ids, -test_status => $test_status, -dbc => $dbc );
    }
    else {
        Message("No valid run ids chosen");

    }
    return;
}

sub remove_Run_Request {
#####################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-id} || $q->param('ID');
    my ($user_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = '$user'" );
    my $search = $q->param('Search String');
    my $condition;
    if ($search) { $condition = "and Run_Directory like '%$search%'"; }
    unless ( $q->param('All Users') ) { $condition .= " AND RunBatch.FK_Employee__ID = $dbc->{config}{user_id}"; }
    Message("Condition: $condition");
    my @fields = ( 'Run_ID', 'Run_Directory', 'Run_DateTime', 'Run_Test_Status', 'RunBatch.FK_Equipment__ID as Machine', 'RunBatch.FK_Employee__ID as User' );
    return &SDB::DB_Form_Viewer::mark_records(
        $dbc, 'Run,RunBatch', \@fields,
        "WHERE FK_RunBatch__ID=RunBatch_ID AND Run_Status in ('Initiated', 'Not Applicable','In Process','Expired') $condition ORDER BY Run_DateTime desc",
        -run_modes => [ 'Aborted', 'Delete Record' ]
    );

}

sub mark_Failed_Runs {
#####################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $q        = $self->query;
    my $dbc      = $args{-dbc} || $self->param('dbc');
    my $username = $user || $q->param('username');

    my ($user_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = '$username'" );

    my $search = $q->param('Search String');
    $search ||= "";
    my $condition;
    if ($search) { $condition = "and Run_Directory like \"%$search%\""; }
    unless ( $q->param('All Users') ) { $condition .= " AND FK_Employee__ID = $user_id"; }

    my $limit = 20;
    my @fields = ( 'Run_ID', 'Run_Directory', 'Run_DateTime', 'Run_Status', 'Run_Test_Status', 'FK_Equipment__ID', 'FK_Employee__ID' );

    return &SDB::DB_Form_Viewer::mark_records( $dbc, 'Run,RunBatch', \@fields, "WHERE FK_RunBatch__ID=RunBatch_ID $condition ORDER BY Run_DateTime desc,Run_Directory Limit $limit", -run_modes => [ 'Delete Record', "Set to Failed" ] );

}

sub annotate_Run_Comments {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my ($user_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = '$user'" );

    my $search = $q->param('Search String');
    $search ||= "";
    my $condition;
    if   ($search) { $condition = "Run_Directory like \"%$search%\""; }
    else           { $condition = '1'; }

    unless ( $q->param('All Users') ) { $condition .= " AND FK_Employee__ID = $user_id"; }
    my $limit = 20;
    my @fields = ( 'Run_ID', 'Run_Directory', 'Run_DateTime', 'Run_Test_Status', 'FK_Equipment__ID', 'FK_Employee__ID' );

    return &SDB::DB_Form_Viewer::mark_records( $dbc, 'Run,RunBatch', \@fields, "WHERE FK_RunBatch__ID=RunBatch_ID AND $condition ORDER BY Run_DateTime desc,Run_Directory Limit $limit", -run_modes => [ 'Delete Record', "Annotate Run_Comments" ] );
}

sub _action_buttons {
#####################
    #       Description:
    #               - This displays action buttons for a run which include:
    #               - Set Validation Status
    #               - Set Billable
    #               - Re-Print Barcodes
    #               - Set as Failed
    #               - Comment (Mandatory for Rejected and Failed runs)
    #
    # <snip>
    # Usage Example:
    #       my $action_buttons .= $self->_action_buttons();
    #
    # </snip>
#####################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $buttons = "Put action buttons here";

    return $buttons;

}

sub display_Run_and_Plate_tables {
#####################
    #       Description:
    #               - This displays the Run table and Plate table given a Run ID, this must provide "Edit" link for those tables
    #       Input:
    #               - a run id
    # <snip>
    # Usage Example:
    #       my $tables .= $self->display_Run_and_Plate_tables(-run_id=>$run_id);
    #
    # </snip>
#####################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $runid  = $args{-run_id};
    my $hidden = $args{-hidden} || 0;                  ## option whether to show fields marked as hidden
    my $tables;

    my $platecond = "WHERE Run_ID = '$runid'";
    my ($plateid) = $dbc->Table_find( 'Run', 'FK_Plate__ID', $platecond );

    my @displaytables = ( 'Run', 'Plate' );
    foreach my $table (@displaytables) {
        my $id;
        if ( $table eq 'Plate' ) { $id = $plateid; }
        if ( $table eq 'Run' )   { $id = $runid; }

        my $title = "Data for $table $id";

        my $fieldcondition = "WHERE FK_DBTable__ID = DBTable_ID AND DBTable_Name = '$table' AND Field_Options NOT RLIKE 'Obsolete' AND Field_Options NOT RLIKE 'Removed'";
        if ( !$hidden ) {
            $fieldcondition .= " AND Field_Options NOT RLIKE 'Hidden'";
            if ( $table ne 'Run' ) { $title .= " (Run $runid)"; }
        }
        my (@field_list) = $dbc->Table_find( 'DBField,DBTable', 'Field_Name', $fieldcondition );

        my $cond = "WHERE $table" . "_ID = '$id'";

        my $link = "[ " . &Link_To( $dbc->config('homelink'), 'Edit', "&Search=1&Table=$table&Search+List=$id", $Settings{LINK_COLOUR}, ['newwin'] ) . " ]";
        $tables .= $dbc->Table_retrieve_display( $table, \@field_list, $cond, -title => "$title $link", -return_html => 1 );
        $tables .= "<br>";
    }

    return $tables;

}

#<snip>
# my $summary_table = get_summary_table(-run_id=>$run_id,-run=>$Run,-dbc=>$dbc);
# Or, from external module:
# my $summary_table =
#</snip>
#code is taken from Run.pm
#############################
sub get_summary_table {
#############################

    my %args   = @_;
    my $run_id = $args{-run_id};
    my $Run    = $args{-run};
    my $dbc    = $args{-dbc};

    $Run ||= new alDente::Run( -dbc => $dbc, -run_id => $run_id );

    my $API = alDente::alDente_API->new( -dbc => $dbc );

    my $run_data = $API->get_run_data( -run_id => $run_id, -fields => 'FK_Plate__ID, Run_Datetime, Run_Directory, Run_Status, Run_Test_Status, Run_Type', -log => 0, -quiet => 1 );
    my $plate_id    = &alDente::Tools::alDente_ref( 'Plate', $run_data->{'FK_Plate__ID'}[0] );
    my $datetime    = $run_data->{'Run_Datetime'}[0];
    my $run_dir     = $run_data->{'Run_Directory'}[0];
    my $status      = $run_data->{'Run_Status'}[0];
    my $test_status = $run_data->{'Run_Test_Status'}[0];
    my $type        = $run_data->{'Run_Type'}[0];

    my $summary_table = HTML_Table->new( -class => 'small', -title => "Run: $run_id" );
    $summary_table->Set_Row( [ 'Type: ', $type ] ) if $type;
    $summary_table->Set_Row( [ 'Plate: ',       $plate_id ] );
    $summary_table->Set_Row( [ 'Datetime: ',    $datetime ] );
    $summary_table->Set_Row( [ 'Directory: ',   $run_dir ] );
    $summary_table->Set_Row( [ 'Status: ',      "<font color='red'>$status</font>" ] ) if $status ne 'Analyzed';
    $summary_table->Set_Row( [ 'Test Status: ', "<font color='red'>$test_status</font>" ] ) if $test_status eq 'Failed';

    return $summary_table->Printout(0);

}

sub get_Scanner_Actions {
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $core_actions = {
        'Plate(1-N)+Equipment[Sequencer-3700](1-1)'                           => 'alDente::Run_App::prepare_sample_sheet',              #Should be Sequencing::SequenceRun_App::prepare_sample_sheet
        'Plate(1-N)+Equipment[Sequencer-3730](1-1)'                           => 'alDente::Run_App::prepare_sample_sheet',              #Should be Sequencing::SequenceRun_App::prepare_sample_sheet pla5000equ246
        'Plate(1-N)+Equipment[Sequencer-3100](1-1)'                           => 'alDente::Run_App::prepare_sample_sheet',              #Should be Sequencing::SequenceRun_App::prepare_sample_sheet
        'Plate(1-N)+Equipment[Sequencer-MB](1-1)'                             => 'alDente::Run_App::prepare_sample_sheet',              #Should be Sequencing::SequenceRun_App::prepare_sample_sheet
        'Solution(1-N)+Equipment[Sequencer](1-N)'                             => 'alDente::Run_App::apply_matixbuffer_to_sequencer',    #Should be Sequencing::SequenceRun_App::apply_matixbuffer_to_sequencer, sol100669equ246
        'Plate(1-N)+Equipment[Sequencer-Cluster Station](1-N)'                => 'alDente::Run_App::display_flowcell_form',             #Should be Solexa::SolexaRun_App::display_flowcell_form, TRA19867equ2197
        'Plate(1-N)+Equipment[Sequencer-cBot Cluster Generation System](1-N)' => 'alDente::Run_App::display_flowcell_form',             #Should be Solexa::SolexaRun_App::display_flowcell_form, TRA19867equ
        'Plate(1-N)+Equipment[Sequencer-Genome Analyzer](1-N)'                => 'alDente::Run_App::display_solexa_run_form',           #Should be Solexa::SolexaRun_App::display_solexa_run_form, TRA19867equ1656
        'Plate(1-N)+Equipment[Sequencer-MiSeq](1-N)'                          => 'alDente::Run_App::display_miseq_run_form',            #Should be Solexa::SolexaRun_App::display_solexa_run_form, TRA19867equ1656
        'Plate(1-N)+Equipment[Sequencer-HiSeq](1-N)'                          => 'alDente::Run_App::display_hiseq_run_form',            #Should be Solexa::SolexaRun_App::display_hiseq_run_form, TRA19867equ2328
        'Plate(1-N)+Equipment[Sequencer-Solid](1-N)'                          => 'alDente::Run_App::display_solid_run_form',            #Should be SOLID::SOLIDRun_App::display_solid_run_form, TRA19867equ2186
        'Plate(1-1)+Microarray(1-1)'                                          => 'alDente::Run_App::create_array',                      #Should be GeneChipRun_App::create_array, pla69018mry1769
        'Plate(1-N)+Equipment[Hyb Oven](1-N)'                                 => 'alDente::Run_App::prepare_GCOS_sample_sheet',         #Should be GeneChipRun_App::prepare_GCOS_sample_sheet, pla5000equ866, pla273030equ866
        'Plate(1-N)+Equipment[GeneChip System-Scanner](1-N)'                  => 'alDente::Run_App::assign_scanner',                    #Should be GeneChipRun_App::assign_scanner,pla272633equ610
        'Plate(1-N)+Equipment[Spectrophotometer](1-N)'                        => 'alDente::Run_App::spect_request_form',                #Should be SpectRun_App::spect_request_form, pla5000equ620
        'Plate(1-N)+Equipment[Sequencer-LS_454](1-N)'                         => 'LS_454::LS_454Run_App::start_LS_454_runs',            # Equ856Pla210300Run84577
    };

    #Get all availble run plugins
    #(i.e. get a list of plugins and need to know which directory the plugin is installed too)
    my @run_types = $dbc->get_enum_list( 'Run', 'Run_Type' );
    my $plugin_actions;

    for my $run_type (@run_types) {

        my $proper_app = &get_app( -run_type => $run_type );

        if ( eval "require $proper_app" ) {
            my $cmd                 = "$proper_app" . "::get_Scanner_Actions()";
            my $curr_plugin_actions = eval "$cmd";

            #print HTML_Dump $curr_plugin_actions, $app, $cmd;
            #for some reasons, can't use merge_Hash twice
            for my $key ( keys %{$curr_plugin_actions} ) {
                $plugin_actions->{$key} = $curr_plugin_actions->{$key};
            }
        }

    }

    #print HTML_Dump $plugin_actions;
    my $actions = &RGmath::merge_Hash( -hash1 => $core_actions, -hash2 => $plugin_actions );

    #print HTML_Dump $actions;
    return $actions;
}

######################################################
## FUNCTIONS to handle scanner actions, which most of them can be moved into more specific Run_App (e.g. GelRun_App)
######################################################

## SequenceRun
###########################
sub prepare_sample_sheet {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    require Sequencing::Sample_Sheet;     ## dynamically load module ##
    import Sequencing::Sample_Sheet;

    require Sequencing::Sequence;         ## dynamically load module ##
    import Sequencing::Sequence;

    print &alDente::Container::Display_Input($dbc);
    unless ( &Sequencing::Sample_Sheet::preparess( $dbc, $barcode ) ) {
        ### returns value if successful
        &Sequencing::Sequence::sequence_home();
    }

}

## SequenceRun
#####################################
sub apply_matixbuffer_to_sequencer {
#####################################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $solutions         = &alDente::Validation::get_aldente_id( $dbc, $barcode,      'Solution' );
    my $equipment_list    = &alDente::Validation::get_aldente_id( $dbc, $barcode,      'Equipment', -validate => 1, -quiet => 1 );
    my @matrixbuffers     = $dbc->Table_find( "Solution",               "Solution_ID", "WHERE Solution_Type in ('Matrix','Buffer') AND Solution_ID in ($solutions )" );
    my @not_matrixbuffers = $dbc->Table_find( "Solution",               "Solution_ID", "WHERE Solution_Type not in ('Matrix','Buffer') AND Solution_ID in ($solutions )" );
    if ( int(@not_matrixbuffers) > 0 ) {
        Message("solutions @not_matrixbuffers are not Matrices or Buffers. Ignoring...");
    }

    return alDente::Equipment_Views::confirm_MatrixBuffer( -dbc => $dbc, -equipment_id => $equipment_list, -sol_id => \@matrixbuffers );
}

## BioanalyzerRun
###############################
sub bioanalyzer_request_form {
###############################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my $current_plates = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    require alDente::BioanalyzerRun;
    &alDente::BioanalyzerRun::bioanalyzer_request_form( -plate => $current_plates, -scanner => $equipment_list );

}

## SpectRun
###############################
sub spect_request_form {
###############################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my $current_plates = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    require alDente::SpectRun;
    &alDente::SpectRun::spect_request_form( -plate => $current_plates, -scanner => $equipment_list );

}

## GeneChipRun
###########################
sub create_array {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $microarray_id = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Microarray', -validate => 1 );
    my $plate_id      = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate',      -validate => 1 );

    require alDente::Array;
    my $mo = new alDente::Array( -dbc => $dbc );
    my $new_plate_id = $mo->create_array( -plate_id => $plate_id, -microarray_id => $microarray_id );
    if ($new_plate_id) {
        &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $new_plate_id );
        &alDente::Info::GoHome( $dbc, -table => 'Plate', -id => $new_plate_id );
    }

}

## GeneChipRun
###############################
sub prepare_GCOS_sample_sheet {
###############################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my $current_plates = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    require Lib_Construction::GCOS_SS;

    my $ss = new Lib_Construction::GCOS_SS( -dbc => $dbc );
    $ss->prompt_ss( -plate_id => $current_plates, -equipment_id => $equipment_list );

}

## GeneChipRun
###############################
sub assign_scanner {
###############################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my $current_plates = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    require Lib_Construction::GCOS_SS;

    my $ss = new Lib_Construction::GCOS_SS( -dbc => $dbc );
    $ss->assign_scanner( -plate_id => $current_plates, -equipment_id => $equipment_list );

}

## SolexaRun
###########################
sub display_flowcell_form {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $current_plates = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );
    require Illumina::Flowcell;
    my ($tray_id) = $dbc->Table_find( "Plate_Tray", "FK_Tray__ID", "WHERE FK_Plate__ID IN ($current_plates)" );
    Illumina::Flowcell::display_flowcell_form( -dbc => $dbc, -tray_id => $tray_id );

}

## SolexaRun
###########################
sub display_solexa_run_form {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my @plate_ids = split ',', &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    require Sequencing::SolexaRun;
    Sequencing::SolexaRun::display_SolexaRun_form( -dbc => $dbc, -equipment_id => $equipment_list, -plate_ids => \@plate_ids );

}

## SolexaRun
###########################
sub display_hiseq_run_form {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my @plate_ids = split ',', &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    my ($lanes) = $dbc->Table_find( 'Plate,Plate_Format', 'Wells', "WHERE Plate_Format_ID = FK_Plate_Format__ID and Plate_ID IN ($plate_ids[0])" );
    require Sequencing::SolexaRun;
    Sequencing::SolexaRun::display_SolexaRun_form( -dbc => $dbc, -equipment_id => $equipment_list, -plate_ids => \@plate_ids, -hiseq => 1, -lanes => $lanes );

}

## SolexaRun
###########################
sub display_miseq_run_form {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my @plate_ids = split ',', &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    require Sequencing::SolexaRun;
    Sequencing::SolexaRun::display_SolexaRun_form( -dbc => $dbc, -equipment_id => $equipment_list, -plate_ids => \@plate_ids, -miseq => 1 );

}

#SOLIDRun
###########################
sub display_solid_run_form {
###########################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my %args    = &filter_input( \@_ );
    my $barcode = $args{-barcode};        ## Barcode Scanned

    my $equipment_list = &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Equipment', -validate => 1, -quiet => 1 );
    my @plate_ids = split ',', &alDente::Validation::get_aldente_id( $dbc, $barcode, 'Plate', -validate => 1 );

    require SOLID::SOLIDRun;
    SOLID::SOLIDRun::display_SOLIDRun_form( -dbc => $dbc, -equipment_id => $equipment_list, -plate_ids => \@plate_ids );

}

#
# Default wrapper for viewing general run information
# (Run_Type specific views should be generated in the applicable Plugin)
#
# Return: summary table
#################
sub view_Runs {
#################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    my %args = &filter_input( \@_ );

    my $library   = $q->param('Library_Name');
    my $project   = $q->param('Project_ID');
    my $run_type  = $q->param('Run_Type');
    my $condition = $q->param('Condition');

    my $tables = 'Run,RunBatch,Plate,Library';
    my @fields = ( 'Run_DateTime', 'Run_Status', 'Run_Directory', 'Run_Validation', 'Run.FK_Plate__ID', 'RunBatch.FK_Equipment__ID', 'Run.QC_Status' );
    $condition = 'WHERE RunBatch_ID=Run.FK_RunBatch__ID AND Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name';

    if ($library) {
        my $lib = Cast_List( -list => $library, -to => 'string', -autoquote => 1 );
        $condition .= " AND Library_Name IN ($lib)";
    }
    elsif ($project) {
        $condition .= " AND Library.FK_Project__ID IN ($project)";
    }
    else {
        return "User must supply library or project";
    }

    if ($run_type) {
        $tables    .= ",$run_type";
        $condition .= " AND $run_type.FK_Run__ID=Run_ID";
    }

    return $dbc->Table_retrieve_display( $tables, \@fields, $condition, -return_html => 1 );
}

#
# Default wrapper for viewing general run information
# (Run_Type specific views should be generated in the applicable Plugin)
#
# Return: summary table
######################
sub view_Analysis {
######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    my %args = &filter_input( \@_ );

    my $library   = $q->param('Library_Name');
    my $project   = $q->param('Project_ID');
    my $run_type  = $q->param('Run_Type');
    my $condition = $q->param('Condition');

    my $tables = 'Run,RunBatch,Plate,Library,Run_Analysis';
    my @fields = ( 'Run_Analysis.FK_Run__ID as Run', 'Run_DateTime', 'Run_Status', 'Run_Directory', 'Run_Validation', 'Run.FK_Plate__ID', 'RunBatch.FK_Equipment__ID', 'Run.QC_Status' );

    ## add analysis fields ##
    push @fields, ( 'Run_Analysis_Started', 'Run_Analysis_Status', 'Run_Analysis_Finished', 'Run_Analysis_Type', 'FKAnalysis_Pipeline__ID', 'FKLast_Analysis_Step__ID', 'Current_Analysis' );
    $condition = 'WHERE RunBatch_ID=Run.FK_RunBatch__ID AND Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name AND Run_Analysis.FK_Run__ID=Run_ID';

    my $title = "Run Analysis";
    if ($library) {
        my $lib = Cast_List( -list => $library, -to => 'string', -autoquote => 1 );
        $condition .= " AND Library_Name IN ($lib)";
        $title     .= " for $lib";
    }
    elsif ($project) {
        $condition .= " AND Library.FK_Project__ID IN ($project)";
        $title     .= " for Project $project";
    }
    else {
        return "User must supply library or project";
    }

    if ($run_type) {
        $tables    .= ",$run_type";
        $condition .= " AND $run_type.FK_Run__ID=Run_ID";
        $title     .= " $run_type Experiments";
    }

    return $dbc->Table_retrieve_display( $tables, \@fields, $condition, -return_html => 1, -toggle_on_column => 'Run', -title => $title );
}

#
# Method to get which Run_App to load given a run type
#
# Return: App moudle to load
######################
sub get_app {
######################
    my %args     = &filter_input( \@_ );
    my $run_type = $args{-run_type};

	if( $run_type =~ /_Run$/xms ) {
	    $run_type =~ s/_Run//;
	}
	elsif( $run_type =~ /Run$/xms ) {
	    $run_type =~ s/Run//;
	}

    my $proper_app = $run_type . "::Run_App";
    if ( eval {"require $proper_app"} ) {
        return $proper_app;
    }

    my $directory = 'alDente';
    my $app       = $directory . "::" . $run_type . "_App";
    if ( eval {"require $proper_app"} ) {
        return $app;
    }

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
