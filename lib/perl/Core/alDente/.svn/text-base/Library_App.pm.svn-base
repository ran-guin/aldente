##################
# Library_App.pm #
##################
#
# This is a template for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Library_App;

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

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use SDB::HTML;
use SDB::Session;
use alDente::Library;
use alDente::Library_Views;
##############################
# global_vars                #
##############################
use vars qw(%Configs);

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'home_page'                => 'home_page',
            'summary_page'             => 'summary_page',
            'reset_status'             => 'reset_status',
            'Show Published Documents' => 'show_Published_Documents',
            'Set Library QC Status'    => 'set_library_qc_status',
            'Set Library Status'       => 'set_Library_Status',
            'Change Project'           => 'change_Project',
            'Add Goals'                => 'add_work_request',
            'Save Goals'               => 'save_work_request',
            'Sub_Library_IW'           => 'all_sub_iws',
        }
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query;
    my $id  = $q->param('ID') || $q->param('Library');

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    $self->param(
        'Model' => alDente::Library->new( -dbc       => $dbc, -library => $id ),
        'View'  => alDente::Library_Views->new( -dbc => $dbc, -library => $id ),

    );

    return $self;
}

##################
# Regenerate Library Status
# (if anything changes, email notification messages will be sent out from Library::reset_Status)
#
#
###################
sub reset_status {
###################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->param('dbc');
    my $q        = $self->query;
    my $feedback = $q->param('Feedback');

    my $lib = $args{-library} || $q->param('Library_Name');

    my $output = '';
    if ($feedback) { Message("Regenerating status based upon goals...") }
    my ( $closed, $opened, $messages ) = alDente::Library::reset_Status( $dbc, $lib );
    my @closed_list  = @$closed;
    my @opened_list  = @$opened;
    my @message_list = @$messages;

    if (@closed_list)  { Message("Closed: @closed_list") }
    if (@opened_list)  { Message("Opened: @opened_list") }
    if (@message_list) { Message( "Messages: " . join '<BR>', @message_list ) }

    $output .= $self->home_page( -library => $lib );

    print $output;
    return $output;
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
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $lib = $args{-library} || $q->param('Library_Name') || $q->param('ID');

    my $library_view = new alDente::Library_Views( -dbc => $dbc, -library => $lib );
    return $library_view->home_page( -library => $lib, -dbc => $dbc );
}

#####################
sub change_Project {
#####################
    # Description
    #     Changes the project for a given library
    # Input:
    #     Library, Project
    #     Confirmation (if it is set it will change if not it will ask permission)
    # Output:
    #     HTML Page (depends which on confirmation)
#####################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $self->param('dbc');
    my $q         = $self->query;
    my $View      = $self->param('View');
    my $Model     = $self->param('Model');
    my $confirmed = $q->param('Confirmed');
    my $project   = $q->param('FK_Project__ID Choice') || $q->param('FK_Project__ID');
    my $lib       = $q->param('Library');

    if ($confirmed) {
        $Model->change_Project( -project => $project );
        return $View->home_page( -dbc => $dbc );
    }
    else {
        my $approved = $Model->approve_Project_Change();
        if ($approved) {
            return $View->confirm_change_Project( -project => $project );
        }
        else {
            return $View->home_page();
        }
    }

}

############################
# Concise summary view of data
# (useful for inclusion on library home page for example)
#
# Return: display (table) - smaller than for show_Progress
############################
sub summary_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my %data;
    my @keys = sort keys %data;    ## specify order of keys in output if desired

    my $output = SDB::HTML::display_hash(
        -dbc         => $dbc,
        -hash        => \%data,
        -keys        => \@keys,
        -title       => 'Summary',
        -colour      => 'white',
        -border      => 1,
        -return_html => 1,
    );

    return $output;
}

############################
sub show_Published_Documents {
############################
    my $self    = shift;
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $view    = $self->param('View');
    my $model   = $self->param('Model');
    my $library = $q->param('Library_Name') || $self->param('Library_Name');
    my $files   = $model->get_Published_files( -library => $library );
    require alDente::Import_Views;
    my $output = alDente::Import_Views::display_Published_Documents( -files => $files, -dbc => $dbc );
    return $output;

}

############################
sub set_Library_Status {
############################
    my $self   = shift;
    my $dbc    = $self->param('dbc');
    my $q      = $self->query;
    my @libs   = $q->param('library');
    my $reason = $q->param('Reason');
    my $status = $q->param('Status');

    my $Library = $self->param('Model');
    $Library->set_Library_Status( -reason => $reason, -status => $status, -libs => \@libs, -dbc => $dbc );

    my $size = @libs;
    if ( $size == 1 ) {
        my $library_view = new alDente::Library_Views( -dbc => $dbc, -library => $libs[0] );
        return $library_view->home_page( -library => $libs[0], -dbc => $dbc );
    }
    else {
        return;
    }

}

sub set_library_qc_status {
    my $self               = shift;
    my $dbc                = $self->param('dbc');
    my $q                  = $self->query;
    my $sample_qc_status   = $q->param('Library_QC');
    my @libraries          = $q->param('Collection');
    my $attribute          = $q->param('Library_QC_Status_Attribute') || 'Library_QC_Status';
    my $key_object         = $q->param('Key_Object') || 'Library';
    my $approve_pooled_lib = $q->param('Approve_Pooled_Library');

    unless (@libraries) {
        my @key_objects = $q->param('Mark');
        if ( $key_object =~ /Library/ ) {
            @libraries = @key_objects;
        }
        elsif ( $key_object =~ /(Container)|(Plate)/ ) {
            ## get the libraries from the key object
            my $plate_list = Cast_List( -list => \@key_objects, -to => 'string' );
            @libraries = $dbc->Table_find( 'Plate', 'FK_Library__Name', "where Plate_ID in ( $plate_list )", -distinct => 1 );
        }

        unless (@libraries) {
            @libraries = $q->param('Library_Name');
        }
    }

    if ( @libraries && $sample_qc_status ) {
        $dbc->start_trans('set_library_QC');
        require alDente::Attribute;
        my $attribute_obj = alDente::Attribute->new( -dbc => $dbc );
        $attribute_obj->set_attribute( -object => 'Library', -attribute => "$attribute", -value => "$sample_qc_status", -id => \@libraries, -on_duplicate => 'REPLACE' );
        my $number_plates = int(@libraries);
        $dbc->message("Set Attribute $attribute for $number_plates libraries");

        ## set QC status for pooled libraries
        if ($approve_pooled_lib) {
            my $lib_obj = new alDente::Library( -dbc => $dbc );
            my $pooled_lib_to_set = $lib_obj->get_pooled_library_for_QC( -dbc => $dbc, -library => \@libraries, -attribute => $attribute, -status => $sample_qc_status, -debug => 0 );
            foreach my $status ( keys %$pooled_lib_to_set ) {
                if ( int( @{ $pooled_lib_to_set->{$status} } ) ) {
                    $attribute_obj->set_attribute( -object => 'Library', -attribute => "$attribute", -value => "$status", -id => $pooled_lib_to_set->{$status}, -on_duplicate => 'REPLACE' );
                    my $count = int( @{ $pooled_lib_to_set->{$status} } );
                    $dbc->message("Set Attribute $attribute = $status for $count pooled libraries");
                }
            }
        }

        my $fail_library = $q->param('Fail_Library');
        if ( $sample_qc_status eq 'Failed' && $fail_library ) {
            my $fail_reason = $q->param('Fail_Reason');
            my $Library     = $self->param('Model');
            $Library->set_Library_Status( -reason => $fail_reason, -status => $sample_qc_status, -libs => \@libraries, -dbc => $dbc );
            $dbc->message("Failed $number_plates libraries");
        }
        $dbc->finish_trans('set_library_QC');
    }
    return;
}

############################
# Create a IWs table for dsub libraries
# The method is called from Library_Views as a link
# Input: selected Library Name (Parent Library)
# Return: display a table of IWs from sub_libraries
############################
sub all_sub_iws {
####################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $lib  = $q->param('Library_Name');
    my $debug;

    #gets all the sub libraries...
    my @source_parents = $dbc->Table_find(
        'Source_Pool,Library_Source,Library_Source as Parent', 'Parent.FK_Library__Name',
        , "WHERE Source_Pool.FKChild_Source__ID=Library_Source.FK_Source__ID AND FKParent_Source__ID=Parent.FK_Source__ID AND Library_Source.FK_Library__Name = '$lib' AND Parent.FK_Library__Name != '$lib'",
        -distinct => 1,
        -debug    => $debug
    );

    if (@source_parents) {

        #If the main library has sub libraries -> Create a IW summary table made of the sub libraries'...
        require alDente::Invoice_Views;

        my @iw_summary_fields = (
            'work_id',   'plate', 'work_request', 'protocol', 'work_type', 'library_strategy', 'attribute_value', 'library', 'plate_id', 'attribute_id',
            'work_date', 'pla',   'tra',          'run_id',   'run_type',  'machine',          'billable',        'invoice', 'funding',  'funding2'
        );

        my $invoiceable_work_info = alDente::Invoice_Views::get_invoiceable_work_summary( -dbc => $dbc, -library_names => \@source_parents, -field_list => \@iw_summary_fields );

        #Back to Library_Views
        return $invoiceable_work_info;

    }
    else {
        $dbc->warning("Sorry, I can't find any sub libraries of $lib");
        return;
    }
}

return 1;
