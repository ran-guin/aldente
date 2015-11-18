##################
# Prep_App.pm #
##################
#
# This is a template for the use of various MVC App modules (using the CGI Application module)
##################

##################
# Prep_App.pm #
##################
#
# This module is used to prompt users through Preps.
#
package alDente::Prep_App;

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
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

#use CGI qw(:standard);
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

use base RGTools::Base_App;
use strict;
use Benchmark;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use alDente::Tools;
use alDente::SDB_Defaults;
use alDente::Tray;
use alDente::Validation;

use alDente::Prep;
use alDente::Prep_Views;
##############################
# global_vars                #
##############################
use vars qw(%Configs $URL_temp_dir $html_header %Benchmark);    # $current_plates $testing %Std_Parameters $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Show Prep');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'Get Instructions'                        => 'get_Instructions',
            'Completed Step'                          => 'complete_Protocol_Step',
            'Skip Step'                               => 'skip_Protocol_Step',
            'Go Back One Step'                        => 'repeat_Protocol_Step',
            'Repeat Last Step'                        => 'repeat_Protocol_Step',
            'Fail Step'                               => 'fail_Prep',
            'Re-Print Plate Barcodes'                 => 'reprint_Barcodes',
            'Prep Notes'                              => 'annotate_Protocol_Step',
            'Fail Prep, Remove Container(s) from Set' => 'fail_Prep',

            'Continue with Lab Protocol'            => 'continue_Protocol',
            'Continue with Production Protocol'     => 'continue_Protocol',
            'Continue with Approved TechD Protocol' => 'continue_Protocol',
            'Continue with Pending TechD Protocol'  => 'continue_Protocol',

            'Apply Solution to Plate' => 'apply_Solution_to_plate',
            'Show Prep'               => 'home_page',
            'Edit Prep'               => 'edit_Prep',
            'Batch Update'            => 'batch_Prep',
            'Update Steps Completed'  => 'batch_Prep',
            'Continue with Protocol'  => 'continue_Prep',
            'Prep Summary'            => 'prep_Summary',
            'Protocol Summary'        => 'protocol_Summary',
        }
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $dbc = $self->param('dbc');
    my $goal = new alDente::Goal( -dbc => $dbc );

    #    my $lib  = new alDente::Library(-dbc=>$dbc);

    $self->param(
        'Goal_Model' => $goal,

        #        'Library_Model' => $lib,
    );

    return $self;
}

#####################
#
# home_page (default)
#
# Return: display (table)
#####################
sub home_page {
#####################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $id = $q->param('ID');

    my $page = alDente_ref( 'Prep', $id, -dbc => $dbc );

    $page .= $dbc->Table_retrieve_display(
        'Prep,Plate_Prep',
        [   'FK_Plate__ID', 'Prep_Name',
            'Prep_DateTime as Completed',
            'FK_Employee__ID as Prepped_By',
            "FK_Equipment__ID as Equipment",
            'FK_Solution__ID as Solution',
            "CONCAT(Solution_Quantity,' ', Solution_Quantity_Units) as Sol_Qty",
            "CONCAT(Transfer_Quantity,' ', Transfer_Quantity_Units) as Xfer_Qty"
        ],
        "WHERE FK_Prep__ID=Prep_ID AND Prep_ID = '$id'",
        -return_html => 1
    );

    return $page;
}

######################
sub get_param_input {
######################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $q     = $self->query;
    my $dbc   = $self->param('dbc');
    my $debug = $args{-debug};

    my %Input;
    foreach my $name ( $q->param() ) {
        my $value = $q->param($name);
        if ( $dbc->foreign_key_check( -field => $name ) ) { $value = alDente::Scanner::scanned_barcode($name); }    ## enable custom scanned barcode conversions for Foreign key fields ##
        $Input{$name} = $value;

        if ($debug) {                                                                                               ### testing is a global variable that provides verbose feedback
            my $values = join ',', $q->param($name);
            Message("Input: $name = ($values)");
        }
    }
    return %Input;
}

#
# Completed single step of protocol - Records and goes to next step...
#
#
############################
sub complete_Protocol_Step {
############################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my %Input = $self->get_param_input();
    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');
    my $split    = $q->param('Split_X');
    my $sol_ids  = $q->param('FK_Solution__ID');
    my @sol_ids  = split ',', $sol_ids;

    ## THIS IS NOT A GOOD FIX, just temporary #################
    $sol_ids = join 'sol', @sol_ids;
    $sol_ids =~ s/^/sol/i;
    $sol_ids =~ s/sol$//i;
    $sol_ids =~ s/solsol/sol/ig;
    $sol_ids =~ s/sol/sol/ig;
    $sol_ids =~ s/sol0+/sol/ig;

    $Input{'FK_Solution__ID'} = $sol_ids;

    $dbc->defer_messages();

    my $Prep;
    if ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }

    my $step = $Prep->{Step}->{ $Prep->{thisStep} };

    my $comments = $q->param('Append Comments');

    if ($comments) { $Input{Prep_Comments} = "$comments;\n" . $Input{Prep_Comments} }
    my $action = 'Completed';

    my $ok = $Prep->Record( -step => $step, -input => \%Input, -action => $action, -split => $split );    ## -input => $input );

    $dbc->success("Recorded $step... continue") if $ok;

    $dbc->flush_messages( -combine => 1 );

    my $output = $self->_continue_Protocol($Prep);
    return $output;
}

############################
sub skip_Protocol_Step {
############################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');

    my $Prep;
    if ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }

    my $step = $Prep->{Step}->{ $Prep->{thisStep} };

    my $action = 'Skipped';
    my $ok = $Prep->Record( -step => $step, -action => $action );    ##  -input => $input );

    return $self->_continue_Protocol($Prep);
}

############################
sub edit_Prep {
############################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $q       = $self->query;
    my $prep_id = $q->param('FK_Prep__ID');

    if ( !$prep_id ) { return $dbc->error("Must provide prep id to edit") }

    my @plate_preps = $dbc->Table_find( 'Plate_Prep', "Plate_Prep_ID", "WHERE FK_Prep__ID IN ($prep_id)" );

    my $pp_ids = join ',', @plate_preps;
    if ( !$pp_ids ) { return "No IDs ($pp_ids) specified." }

    my $page = SDB::DB_Form_Views::choose_Fields( -dbc => $dbc, -id => $pp_ids, -class => 'Plate_Prep' ) . "<hr>";
    $page .= SDB::DB_Form_Views::choose_Fields( -dbc => $dbc, -id => $prep_id, -class => 'Prep' );

    return $page;
}

############################
sub annotate_Protocol_Step {
############################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');

    my $Prep;
    if ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }

    my $note = $q->param('Prep Plate Note');
    $Prep->annotate_Plates( -note => $note );
    return $self->_continue_Protocol($Prep);

}

#############################################################
# Remove plates from plate set, and fail them for this step
#
#
#################
sub fail_Prep {
#################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');

    my $Prep;
    if ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }

    my $step = $Prep->{Step}->{ $Prep->{thisStep} };

    my $ok;
    if ( $q->param('Plates To Fail Prep') eq '' ) {
        ### The user is trying to fail all the plates, ask for confirmation
        if ( $q->param('Confirm Fail') ) {

            # Fail all of current plates
            my $plate_ids = &get_aldente_id( $dbc, $q->param('Current Plates'), 'Plate', -validate => 1 );
            $ok = $Prep->fail_Plate( -ids => $plate_ids, -step => $step, -note => $q->param('Prep Plate Note') );
        }
        else {
            return $Prep->prompt_User( -confirm_fail => 1 );
        }
    }
    else {
        ### The user is only failing a set of plates, check to see if plates are in Current_Plates

        my $plate_ids = get_aldente_id( $dbc, $q->param('Plates To Fail Prep'), 'Plate' );

        # Check to see if requested plates exist in the current plates list
        my @Current_Plates = split( ',', $q->param('Current Plates') );

        my @ToFail = split( ',', $plate_ids );
        my @invalids;

        foreach my $id (@ToFail) {
            if ( !grep( /^$id$/, @Current_Plates ) ) {
                push( @invalids, $id );
            }
        }
        if (@invalids) {
            my $ids = join ',', @invalids;
            $dbc->session->message("Container $ids not in the current plate set");
        }
        else {
            $ok = $Prep->fail_Plate( -ids => $plate_ids, -step => $step, -note => $q->param('Prep Plate Note') );
        }
    }
    return $self->_continue_Protocol($Prep);
}

###########################
sub get_Instructions {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');

    my $Prep;
    if ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }

    my $prompted = $Prep->prompt_User( -instructions => 1 );
    return $prompted;
}

###########################
sub check_History {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');

    my $Prep;
    if ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }

    my $prompted = $Prep->check_History();
    return $prompted;
}

###########################
sub repeat_Protocol_Step {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');

    my $Prep;
    if ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }

    my $prev_step = $Prep->{thisStep};
    $prev_step = --$prev_step;

    my $prev_step_name = $Prep->{Step}->{$prev_step};
    $dbc->session->message("Repeating step $prev_step_name");
    my $prompted = $Prep->prompt_User( -step_num => $prev_step, -repeat_last_step => 1 );
    return $prompted;
}

#
# Reprint barcodes for current plates
#
#
#######################
sub reprint_Barcodes {
#######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');

    my $Prep;
    if ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }

    my $barcode_name = $q->param('Barcode Name');
    my $curr_plates  = $q->param('Current Plates');

    my %printed_trays;
    my @plate_list = split ',', $curr_plates;

    foreach my $curr_id (@plate_list) {
        if ( !$curr_id ) {next}
        if ( my $tray_id = &alDente::Tray::exists_on_tray( $dbc, 'Plate', $curr_id ) ) {
            if (1) { print 'hello2' }
            unless ( $printed_trays{$tray_id} ) {
                &alDente::Barcoding::PrintBarcode( $dbc, 'Tray', $curr_id, 'print,library_plate' );
                $printed_trays{$tray_id} = 1;
            }
        }
        else {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $curr_id );
        }
    }
    return $self->_continue_Protocol($Prep);
}

######################################################
# Update entire Protcol in one step using batch mode
#
#
############################
sub batch_update_Protocol {
############################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $batch_edit = 1;

    my $plate_set = param('Plate_Set_Number');    ## ||=

    # get the plate set number

    # get the plate numbers associated with the plate set
    my $plate_ids = $q->param('Plate_IDs');

    # get the lab protocol id
    $protocol = $q->param('Protocol');

    # get the number of input rows
    my $input_steps  = $q->param('NumInputRows');
    my $new_pipeline = $q->param('FK_Pipeline__ID');
    my $completed    = $q->param('Completed Protocol');
    my $user_id      = $dbc->get_local('user_id');

    ### process all the parameters into a hash of {STEP_NAME}->{COLUMN_NAME} = VALUE to be passed to update_Protocol

    my %inputhash;

    # get all fields in Prep
    my $dbo     = new SDB::DB_Object( -dbc => $dbc, -tables => "Prep" );
    my @fields  = @{ $dbo->fields() };
    my @checked = param('SELECTED');
    my @order;
    foreach my $i (@checked) {
        my %rowhash;
        my $prep_name;
        foreach my $field (@fields) {
            my $localfield = $field;
            if ( $field =~ /(.+)\.(.+)/ ) { $localfield = $2; }

            $rowhash{$localfield} = $q->param("$field-$i") || $q->param("$localfield-$i");
            if ( $field =~ /\bPrep_Name$/i ) {
                $prep_name = $q->param("$field-$i") || $q->param("$localfield-$i");
            }
        }
        $inputhash{$prep_name} = \%rowhash;
        push( @order, $prep_name );
    }

    if ( $plate_set && $batch_edit ) {
        my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set );
        if (@order) {
            my $errors_ref = $Prep->update_Protocol( -values => \%inputhash, -userid => $user_id, -order => \@order );
            $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set, -suppress_messages_load => 1 );
            $Prep->check_Protocol( -error_step => $errors_ref );
        }
        if ( $Prep->track_completion() ) {

            #$Prep->Record( -step => 'Completed $Prep->{protocol_name} Protocol', -change_location => 0 );
            $Prep->Record( -step => 'Completed Protocol', -change_location => 0 );
        }
    }
    else {
        print "no Set defined\n";
    }

    return 1;
}

#####################
## Local method(s) ##
#####################

#
# Continues with current protocol given a Prep object
#
#
#######################
sub _continue_Protocol {
#######################
    my $self = shift;
    my $Prep = shift;
    my $dbc  = $self->param('dbc');

    my $q = $self->query;

    # Get info regarding previous step
    my $prev_step = $Prep->{Step}->{ $Prep->{thisStep} };

    # $dbc->message("$action step '$prev_step'<br>");
    # if ( $q->param('FK_Solution__ID') ) {
    # $dbc->message("Applied solution $input->{FK_Solution__ID}<BR>");
    # }
    $Prep->load_Preparation();
    my $output = $self->thaw_Protocol($Prep);

    #if (defined $Prep && defined $Prep->{Completed} && defined $Prep->{Completed}{"Completed $Prep->{protocol_name} Protocol"}) {
    if ( defined $Prep && defined $Prep->{Completed} && defined $Prep->{Completed}{"Completed Protocol"} ) {
        ## if protocol is completed revert to display home page for list of current plates ##
        my $current_plates = Cast_List( -list => $Prep->{plate_ids}, -to => 'string' );
        my $plates = new alDente::Container( -dbc => $dbc, -id => $current_plates );
        $output .= $plates->View->std_home_page( -id => $current_plates, -hide_header => 1 );
    }

    return $output;

    #    return '<hr>';
}

###############################################
# Continues with Protocol one step at a time
# (only comes here to start a Protocol - otherwise it uses thaw_Protocol)
#
# Return: page generated
#######################
sub continue_Protocol {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );    ## if called from another method
    my $q    = $self->query();

    my $plate_set = $args{-plate_set} || $q->param('Plate_Set_Number') || $q->param('Plate Set');
    my $current_plates = $args{-plate_ids} || $q->param('Current Plates') || $q->param('Plate ID') || $q->param('Plate_IDs');
    my $protocol = $args{-protocol} || $q->param('Protocol');

    my $dbc = $self->param('dbc');

    my $user_id      = $dbc->get_local('user_id');
    my $scanner_mode = $dbc->get_local('scanner_mode');

    my $rm            = $q->param('rm');
    my $protocol_type = 'Lab Protocol';
    if ( $rm =~ /Continue with (.+)/ ) {
        $protocol_type = $1;
        $protocol      = $q->param($protocol_type);
    }

    my $batch_edit   = $args{-batch_edit}   || $q->param("Batch_Edit $protocol_type");
    my $dynamic_text = $args{-dynamic_text} || $q->param("Enable Dynamic Text Fields for $protocol_type");

    if ( !$protocol ) { Message("No protocol chosen"); return; }

    alDente::Container::reset_current_plates( $dbc, $current_plates );

    # $dbc->{current_plates} = [split ',', $current_plates];   ## reset current_plates info

    use alDente::Container_Set;
    my $output;
    $output .= '<p ></p>' . Link_To( $dbc->{homelink}, "Return to home page for current plate(s)", "&HomePage=Plate&ID=$current_plates" ) . '<p ></p>';
    my $shipping = ( $protocol =~ /Ship Samples/ );    ## if shipping samples, skip container validation..

    my $Set;
    if ( $plate_set =~ /new/i ) {
        $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates, -skip_validation => $shipping );
        $plate_set = $Set->save_Set( -force => 1 );
    }
    elsif ($plate_set) {
        $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set, -skip_validation => $shipping );
    }

    if ( $plate_set && $batch_edit ) {
        my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -Set => $Set, -plates => $current_plates, -dynamic_text => $dynamic_text );
        $output .= $Prep->check_Protocol();
    }
    else {
        my $Prep = new alDente::Prep( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -Set => $Set, -plates => $current_plates, -dynamic_text => $dynamic_text );
        $output .= $Prep->prompt_User();
    }

    if ( $plate_set && !$output ) {    ## re-post container set options ..
        return '<hr>' . $Set->Set_home_info( -brief => $scanner_mode );
    }

    return $output;
}

#########################
#
# Methods below are phased out ? ###
#
###############
###################
sub thaw_Protocol {
###################
    my $self = shift;
    my $Prep = shift;

    my $dbc = $self->param('dbc');
    my $q   = $self->query;

    ## allow input parameters for testing only ##
    my $protocol = $q->param('Protocol_ID');
    my $plates   = $q->param('Plate_ID');

    if ($Prep) { }
    elsif ( $q->param('Freeze Protocol') ) {
        my $encoded = Safe_Thaw( -name => 'Freeze Protocol', -thaw => 0 );
        $Prep = new alDente::Prep( -dbc => $dbc, -encoded => $encoded );
    }
    elsif ( $plates && $protocol ) {
        $Prep = new alDente::Prep( -dbc => $dbc, -plates => $plates, -protocol => $protocol );
    }
    else {
        $dbc->warning('No Frozen Protocol or Plate/Protocol specifications');
        return;
    }
    my $scanner_mode = $dbc->get_local('scanner_mode');

    my $prompt;
    if ( $Prep && !$Prep->prompted() ) { $prompt = $Prep->prompt_User; }

    $dbc->Benchmark('deep_freeze');
    unless ($prompt) {
        ## return to main plate(s) pages..
        if ( $Prep->plate_set ) {
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $Prep->plate_set );
            $prompt .= $Set->Set_home_info( -brief => $scanner_mode );
        }
        elsif ( $Prep->current_plates =~ /,/ ) {
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $Prep->current_plates );
            $prompt .= $Set->Set_home_info( -brief => $scanner_mode );
        }
        elsif ( $q->param('Plate_ID') || $q->param('Current Plates') ) {    ##  $plate_id || $current_plates ) {
            my $id = $q->param('Current Plates') || $q->param('Plate_ID');    ## $current_plates || $plate_id;
            my $Plate = alDente::Container->new( -dbc => $dbc, -id => $id );
            my $type = $Plate->value('Plate.Plate_Type') || 'Container';
            $type = 'alDente::' . $type;
            my $object = $type->new( -dbc => $dbc, -plate_id => $plate_id );

            $prompt .= $object->home_page( -brief => $scanner_mode );
        }
        else {
            $prompt = "no current plates or plate sets";
            return 0;
        }
    }
    $dbc->Benchmark('end_freeze');
    return $prompt;
}

#######################
sub inside_Protocol {
#######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $protocol       = $q->param('Protocol');
    my $plate_set      = $q->param('Plate_Set_Number') || $q->param('Plate Set');
    my $current_plates = $q->param('Current Plates');
    my $batch_edit     = $q->param('Batch_Edit');

    my $user_id      = $dbc->get_local('user_id');
    my $scanner_mode = $dbc->get_local('scanner_mode');

    SDB::Errors::log_deprecated_usage("inside_Protocol");

    my $prompt;

    if ( $plate_set =~ /new/i ) {
        my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
        $plate_set = $Set->save_Set( -force => 1 );
    }

    unless ($plate_set) {
        Message("Error: No Plate Sets found.");
        return 1;
    }
    print &alDente::Container::Display_Input($dbc);

    my $page_generated;
    require alDente::Prep;
    my $Prep;

    if ( $plate_set && $batch_edit ) {
        $Prep = new alDente::Prep(
            -dbc      => $dbc,
            -user     => $user_id,
            -protocol => $protocol,
            -set      => $plate_set,
            -plates   => $current_plates
        );
        $Prep->check_Protocol();
    }
    else {
        $Prep = new alDente::Prep(
            -dbc      => $dbc,
            -user     => $user_id,
            -protocol => $protocol,
            -set      => $plate_set,
            -plates   => $current_plates
        );
        $prompt = $Prep->prompt_User();
    }

    if ( $plate_set && !$prompt ) {    ## re-post container set options ..
        my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
        return $Set->Set_home_info( -brief => $scanner_mode );
    }
    return $prompt;
}

#######################
sub apply_Solution_to_plate {
#######################
    my $self   = shift;
    my $dbc    = $self->param('dbc');
    my $q      = $self->query;
    my $count  = $q->param('Number_of_Solutions');
    my $plates = $q->param('Plate_ID');

    my $Prep = new alDente::Prep( -dbc => $dbc );

    for my $index ( 0 .. $count - 1 ) {
        my $solution = $q->param( 'Solution_' . $index );
        my $amount   = $q->param( 'Apply Quantity_' . $index );
        my $units    = $q->param( 'Quantity_Units_' . $index );
        $Prep->apply_Solution_to_Plate( -solution => $solution, -plate => $plates, -qty => $amount, -units => $units );
    }
    return;
}

#################
sub batch_Prep {
#################
    my $self       = shift;
    my $dbc        = $self->param('dbc');
    my $q          = $self->query;
    my $batch_edit = 1;
    my $user_id    = $dbc->get_local('user_id');

    # get the plate set number
    $plate_set ||= $q->param('Plate_Set_Number');

    my $plate_ids = $q->param('Plate_IDs');
    my $input_str = $q->param('InputFields');
    my $split;

    if ( $plate_set =~ /new/i ) {
        my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $plate_ids );
        $plate_set = $Set->save_Set( -force => 1 );
    }

    # get the lab protocol id
    $protocol = $q->param('Protocol');

    # get the number of input rows
    my $input_steps  = $q->param('NumInputRows');
    my $new_pipeline = $q->param('FK_Pipeline__ID');
    my $completed    = $q->param('Completed Protocol');

    ### process all the parameters into a hash of {STEP_NAME}->{COLUMN_NAME} = VALUE to be passed to update_Protocol

    my %inputhash;

    # get all fields in Prep
    my $dbo = new SDB::DB_Object( -dbc => $dbc, -tables => "Prep, Plate_Prep" );
    my @fields = @{ $dbo->fields() };

    my @input_fields = split ',', $input_str;
    push @fields, @input_fields;

    my @checked = $q->param('SELECTED');
    my @order;
    my $temp_count = 0;
    foreach my $i (@checked) {
        my %rowhash;
        my $prep_name;
        foreach my $field (@fields) {
            my $localfield = $field;

            if ( $field =~ /(.+)\.(.+)/ ) { $localfield = $2; }
            $rowhash{$localfield} = $q->param("$field-$i") || $q->param("$localfield-$i");
            if ( $field =~ /\bPrep_Name$/i ) {
                $prep_name = $q->param("$field-$i") || $q->param("$localfield-$i");
            }
            if ( $field =~ /Split/ ) {
                $split              = $q->param("Split_X-$i");
                $rowhash{'Split'}   = $q->param("Split_X-$i");
                $rowhash{'Sources'} = $q->param("Sources-$i");
                push @input_fields, 'Sources';
            }
            if ( $field =~ /Solution_Quantity/ ) {
                $rowhash{'Solution_Quantity_Units'} = $q->param("Quantity_Units-$i");
                $rowhash{'Quantity_Units'}          = $q->param("Quantity_Units-$i");
                push @input_fields, 'Quantity_Units';
            }
            if ( $field =~ /FK_Solution__ID/ ) {
                my $sol_ids = $q->param('FK_Solution__ID');
                my @sol_ids = split ',', $sol_ids;

                $sol_ids = join 'sol', @sol_ids;
                $sol_ids =~ s/^/sol/i;
                $sol_ids =~ s/sol$//i;
                $sol_ids =~ s/solsol/sol/ig;
                $sol_ids =~ s/sol/sol/ig;
                $sol_ids =~ s/sol0+/sol/ig;
                $rowhash{'FK_Solution__ID'} = $sol_ids;
            }
            if ( $field =~ /Track_Transfer/ || $field =~ /Transfer_Quantity/ ) {
                $rowhash{'Transfer_Quantity'} = $q->param("$field-$i") || $q->param("$localfield-$i");
                $rowhash{'Transfer_Quantity_Units'} = $q->param("Transfer_Quantity_Units-$i");
                push @input_fields, 'Transfer_Quantity_Units';
            }
            if ( $field =~ /_Attribute/ ) {
                my @attr = split '=', $field;
                push @{ $rowhash{ $attr[0] } }, $attr[1];
                $rowhash{ $attr[1] } = $q->param( $attr[1] );
            }
            if ( $field =~ /(FK_Pipeline__ID)-(\d+)/i ) {
                my @temp = $q->param($1);
                $rowhash{"$1"} = $temp[$temp_count];
                push @input_fields, 'FK_Pipeline__ID';
            }

            if ( $field =~ /(Pool_\w+)/ ) {
                if ( $field =~ /(Pool_\w+:\d+)/ ) {
                    $rowhash{$1} = $q->param("$1");
                }
                else {
                    $rowhash{$1} = $q->param("$1-$i");
                }
            }
        }
        $temp_count++;
        $inputhash{$prep_name} = \%rowhash;
        push( @order, $prep_name );
    }

    if ( $plate_set && $batch_edit ) {
        my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set );
        if (@order) {
            my $ok = $Prep->update_Protocol( -values => \%inputhash, -userid => $user_id, -order => \@order, -fields => \@input_fields );
            $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set, -suppress_messages_load => 1, -plates => $current_plates );

            if ( !$ok ) {
                Message("FAILED...");
                my $errors_ref = $Prep->{errors};
                $Prep->check_Protocol( -error_step => $errors_ref );

                return $self->continue_Protocol( -plate_set => $plate_set, -batch_edit => 1 );
            }
            else {
                return $self->continue_Protocol( -plate_set => $plate_set, -batch_edit => 1 );
            }
        }
        if ( $completed =~ /yes/i ) {
            $Prep->Record( -step => 'Completed Protocol', -change_location => 0 );
        }
    }
    else {
        print "no Set defined\n";
    }

    return 1;
}

#####################
sub continue_Prep {
#####################
    my $self = shift;

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    my $protocol       = $q->param('Protocol');
    my $plate_set      = $q->param('Plate_Set_Number');
    my $current_plates = $q->param('Plate_ID');
    my $batch_edit     = $q->param('Batch_Edit');

    if ( !$current_plates ) { return $dbc->warning('No current plates') }

    SDB::Errors::log_deprecated_usage("continue_Prep");

    my $user_id = $dbc->get_local('userid');

    if ( $plate_set =~ /new/i ) {
        my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates );
        $plate_set = $Set->save_Set( -force => 1 );
    }

    my $page = "Continuing prep...($batch_edit - $plate_set)";

    $self->{set_number} = $plate_set;
    if ( $plate_set && $batch_edit ) {
        my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set, -plates => $current_plates );
        $page .= $Prep->check_Protocol();
    }
    else {
        use alDente::Prep;

        #require &alDente::Prep;  ## <CONSTRUCTION> - WHY is this necessary ??
        my $Prep = new alDente::Prep( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set, -plates => $current_plates );

        $page .= $Prep->prompt_User();
    }

    if ( 0 && $plate_set ) {    ## re-post container set options ..
        my $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set );
        $page .= $Set->Set_home_info( -brief => $scanner_mode );
    }

    return $page;
}

##################
sub prep_Summary {
##################
    my $self = shift;

    my $dbc = $self->dbc();
    my $q   = $self->query();

    my $library = SDB::HTML::get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) || SDB::HTML::get_Table_Param( -table => 'Plate', -field => 'FK_Library__Name', -dbc => $dbc ) || $q->param('Library Status');

    my $plate_spec    = $q->param('Plate Number');
    my $include       = $q->param('Inclusive');
    my $details       = $q->param('Details');
    my $days_ago      = $q->param('Days_Ago');
    my $track_primers = $q->param('Track Primers') || 0;

    my $Current_Department = $dbc->config('Target_Department');

    my $page;
    if ( $q->param('SummaryType') =~ /Last/ ) { $days_ago = $q->param('N') }
    if ( $Current_Department =~ /Cap_Seq/i ) {
        eval "require Sequencing::Lab_View";
        $page .= &Sequencing::Lab_View::prep_status( -dbc => $dbc, library => $library, plates => $plate_spec, include => $include, days => $days_ago, details => $details, track_primers => $track_primers );
    }
    elsif ( $Current_Department =~ /Lib_Construction/i ) {
        eval "require Lib_Construction::GE_View";
        $page .= &Lib_Construction::GE_View::prep_status( -dbc => $dbc, library => $library, plates => $plate_spec, include => $include, days => $days_ago, details => $details, track_primers => $track_primers );
    }
    else {
        eval "require Lib_Construction::GE_View";
        $page .= &Lib_Construction::GE_View::prep_status( -dbc => $dbc, library => $library, plates => $plate_spec, include => $include, days => $days_ago, details => $details, track_primers => $track_primers );
    }

    return $page;

}

##################
sub protocol_Summary {
##################
    my $self    = shift;
    my $dbc     = $self->dbc();
    my $q       = $self->query();
    my $user_id = $dbc->get_local('user_id');

    my $library_param   = SDB::HTML::get_Table_Params( -field => 'FK_Library__Name', -table => 'Plate',   -dbc => $dbc );
    my $group_name_list = SDB::HTML::get_Table_Params( -field => 'FK_Grp__ID',       -table => 'Library', -dbc => $dbc );
    my $status          = SDB::HTML::get_Table_Params( -field => 'Plate_Status',     -table => 'Plate',   -dbc => $dbc );
    my $project         = SDB::HTML::get_Table_Params( -field => 'FK_Project__ID',   -table => 'Library', -dbc => $dbc );
    my @group_list_array;

    my $page = page_heading('Protocol Summary');
    if ( $group_name_list && ref $group_name_list eq 'ARRAY' ) {
        foreach my $group (@$group_name_list) {
            my ($group_id) = $dbc->Table_find( "Grp", "Grp_ID", "where Grp_Name = '$group'" );
            push( @group_list_array, $group_id );
        }
    }
    my $group_list;
    if ( my $input_group_list = $q->param("Group_List") ) {
        $group_list = $input_group_list;
    }
    elsif ( scalar @group_list_array > 0 ) {
        $group_list = join( ",", @group_list_array );
    }

    my ( $library, $lib );
    if ( $library_param && ref($library_param) =~ /ARRAY/ ) {
        foreach my $lib_param (@$library_param) {
            if ( $lib_param !~ /^\s*$/ ) {
                $library .= "," . $lib_param;
                $lib .= "," . get_FK_ID( -dbc => $dbc, -field => 'FK_Library__Name', -value => $lib_param );
            }
        }
        $library =~ s/,$//;
        $lib     =~ s/,$//;
        $library =~ s/^,//;
        $lib     =~ s/^,//;
    }
    my $plate_numbers = $q->param('Plate Number') || $q->param('Plate Numbers');
    my $days_ago      = $q->param('Days_Ago')     || 7;
    my $Prep = alDente::Plate_Prep->new( -dbc => $dbc, -user => $user_id );
    my $details = $q->param('Details');

    ## more params ...

    my $ids = $q->param('Plate IDs') || $current_plates || join( ",", $q->param('FK_Plate__ID') );
    my $edit = $q->param('Allow editing') || 0;
    my $verbose         = $q->param('Verbose');
    my $protocol_id     = $q->param('Protocol_ID') || $q->param('FK_Lab_Protocol__ID') || 0;
    my $pipeline_id     = SDB::HTML::get_Table_Params( -field => 'FK_Pipeline__ID', -table => 'Plate', -dbc => $dbc );
    my $generations     = Extract_Values( [ $q->param('Generations'), 10 ] );
    my $set             = $q->param('Plate_Set');
    my $split_quadrants = $q->param('Split_Quadrants');

    if ($details) {
        ### show detailed Library Preparation status only when Library chosen ###
        my $condition = 1;
        if ($lib) {
            $condition .= " AND FK_Library__Name IN ('$lib')";
        }
        if ($plate_numbers) {
            $plate_numbers = &extract_range($plate_numbers);
            $condition .= " AND Plate_Number in ($plate_numbers)";
        }
        if ( $library && $details ) {
            eval "require Sequencing::Lab_View";
            $page .= &Sequencing::Lab_View::show_Prepped_Plates( $dbc, $condition );
        }
    }
    ### copied logic from Plate History below ...
    my $output = "";
    if ( $project && $project->[0] ) {
        $output = $Prep->get_Prep_history( -project => $project, -pipeline_id => $pipeline_id, -view => 1, -group_list => $group_list );
    }
    elsif ($lib) {

        #	    my $Prep = alDente::Plate_Prep->new(-dbc=>$dbc,-user=>$user_id);

        $output = $Prep->get_Prep_history( -pipeline_id => $pipeline_id, -protocol_id => $protocol_id, -view => 1, -split_quad => $split_quadrants );
    }
    elsif ( $ids =~ /[1-9]/ ) {

        #	    my $Prep = alDente::Plate_Prep->new(-dbc=>$dbc,-user=>$user_id);
        $output = $Prep->get_Prep_history( -pipeline_id => $pipeline_id, -plate_ids => $ids, -protocol_id => $protocol_id, -view => 1, -split_quad => $split_quadrants );
    }
    elsif ( $sets =~ /[1-9]/ ) {

        #	    my $Prep = alDente::Plate_Prep->new(-dbc=>$dbc,-user=>$user_id);
        $output = $Prep->get_Prep_history( -pipeline_id => $pipeline_id, -sets => $set, -protocol_id => $protocol_id, -view => 1, -split_quad => $split_quadrants );
    }
    elsif ( $pipeline_id && $pipeline_id->[0] ) {

        #	    my $Prep = alDente::Plate_Prep->new(-dbc=>$dbc,-user=>$user_id);
        $output = $Prep->get_Prep_history( -pipeline_id => $pipeline_id, -view => 1, -group_list => $group_list );
    }
    else {
        $output = $Prep->get_Prep_history( -pipeline_id => $pipeline_id, -view => 1, -group_list => $group_list );
    }

    $page .= $output;

    return $page;
}

return 1;
