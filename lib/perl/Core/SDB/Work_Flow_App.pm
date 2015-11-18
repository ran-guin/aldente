##################
# Form_App.pm #
##################
#
#
package SDB::Work_Flow_App;

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
use SDB::DBIO;
use SDB::HTML;
use SDB::Work_Flow_Views;
use SDB::Work_Flow;
use SDB::Form_Views;
use SDB::Form;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'Start Work Flow' => 'start_Work_Flow',
            'Next'            => 'continue_Work_Flow',
            'Previous'        => 'continue_Work_Flow',
        }
    );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##########################
sub start_Work_Flow {
##########################
    my $self         = shift;
    my $q            = $self->query();
    my $dbc          = $self->{dbc} || $self->param('dbc');
    my $work_flow    = $q->param('Work_Flow');
    my $submission   = $q->param('Submission_ID');
    my $count        = $q->param('Records');
    my $current_page = $q->param('current_page') || 1;
    my $max_row      = $q->param('Row');
    my $max_col      = $q->param('Col');
    my $order        = $q->param('Order');
    my $mode         = $q->param('Mode');

    ## NEED A TOP PArt from the damn questionaire
    my $WF = new SDB::Work_Flow( -dbc => $dbc );
    $WF->load(
        -file       => $work_flow,
        -submission => $submission,
        -mode       => $mode,
    );
    my $form_file = $WF->{control_file};
    my $Form = new SDB::Form( -dbc => $dbc );
    $Form->load(
        -template_file => $form_file,
        -submission_id => $submission,
    );

    if ( $WF->{main_field} ) {
        $WF->{main_field_title} = $Form->{configs}{ $WF->{main_field} }{header};
    }

    my @additional_fields;
    my $slots;
    if ( $max_row && $max_col && $order ) {
        $slots = $Form->load_slots( -max_row => $max_row, -max_col => $max_col, -order => $order );
        my %hash = ( name => 'Location', values => $slots );
        push @additional_fields, \%hash;

    }

    #print HTML_Dump $WF;
    my $append
        = $q->hidden( -force => 1, -name => 'Work_Flow', -value => $work_flow )
        . Safe_Freeze( -name => "additional_fields", -value => \@additional_fields, -format => 'hidden', -encode => 1 )
        . Safe_Freeze( -name => "Model", -value => $WF, -format => 'hidden', -encode => 1 );

    my $buttons   = $self->View->get_Buttons( -page => $current_page );
    my $Form_View = new SDB::Form_Views( -dbc       => $dbc);
    $Form_View -> Mode ($mode);
    my $page = $Form_View->display_Grid( -form => $Form, -records => $count, -cgi_app => 'SDB::Work_Flow_App', -button => $buttons, -append => $append, -additional_fields => \@additional_fields );
    return $page;
}

##########################
sub continue_Work_Flow {
##########################
    my $self         = shift;
    my $q            = $self->query();
    my $dbc          = $self->{dbc} || $self->param('dbc');
    my $file         = $q->param('file');
    my $submission   = $q->param('Submission_ID');
    my $count        = $q->param('record_count');
    my $current_page = $q->param('current_page');
    my $title        = $q->param('title');
    my $work_flow    = $q->param('Work_Flow');
    my $rm           = $q->param('rm');
    my $afields      = Safe_Thaw( -name => 'additional_fields', -thaw => 1, -encoded => 1 );
    my $WF           = Safe_Thaw( -name => 'Model', -thaw => 1, -encoded => 1 );
    my $fields       = Safe_Thaw( -name => 'fields', -thaw => 1, -encoded => 1 );
    my @fields       = @$fields if $fields;
    my $col_count    = @fields;
    my %input;
    my @additional_fields = @$afields if $afields;

    ##### STEP 1: Save Data From Previous Page #####
    for my $col ( 0 .. $col_count - 1 ) {
        my $field = $fields[$col];
        for my $row ( 1 .. $count ) {
            my $temp = "E_" . ( $col + 1 ) . "_" . $row;
            $input{$field}{$row} = $q->param($temp);
        }
    }
    my %file_data;
    $file_data{data} = \%input;
    require SDB::Submission;
    SDB::Submission::write_to_file( -submit_type => 'NEW TYPE', -data_ref => \%file_data, -dbc => $dbc, -sid => $submission, -type => 'xml', -file_prefix => $title );

    ##### STEP 2: Update the Object #####
    if ( $current_page == 1 ) {
        ## This is the decider page and other records need to be updated
        $WF->save_Condition_Fields( -input => \%input );
        ## gotta load main field;
        $WF->{main_field_records} = $input{ $WF->{main_field} };
    }

    my $continue = 1;
    my $index;

    while ( $continue && $index < 100 ) {
        ## This figures out the next page
        $index++;
        if    ( $rm eq 'Next' )     { $current_page++ }
        elsif ( $rm eq 'Previous' ) { $current_page-- }
        if ( $current_page == 1 ) { $continue = 0 }
        else {
            my @records = @{ $WF->{config}{$current_page}{records} } if $WF->{config}{$current_page}{records};
            if (@records) { $continue = 0 }
        }
    }

    #####  STEP 3: read next template #####
    my $Form      = new SDB::Form( -dbc           => $dbc );
    my $form_file = $WF->get_Full_Filename( -file => $WF->{config}{$current_page}{file} );
    $Form->load(
        -template_file => $form_file,
        -submission_id => $submission,
    );

    #####  STEP 4: Dispaly Page #####
    my $append
        = $q->hidden( -force => 1, -name => 'Work_Flow', -value => $work_flow )
        . Safe_Freeze( -name => "additional_fields", -value => \@additional_fields, -format => 'hidden', -encode => 1 )
        . Safe_Freeze( -name => "Model", -value => $WF, -format => 'hidden', -encode => 1 );

    if ( $WF->{main_field} && $current_page != 1 ) {
        my %hash = ( name => $WF->{main_field_title}, values => $WF->{main_field_records} );
        push @additional_fields, \%hash;
    }

    my $buttons;
    if ( int keys %{ $WF->{config} } == $current_page ) {
        $buttons = $self->View->get_Buttons( -page => $current_page, -last_page => 1, -mode => $WF->{mode} );
    }
    else {
        $buttons = $self->View->get_Buttons( -page => $current_page );
    }

    my $Form_View = new SDB::Form_Views( -dbc => $dbc );
    $Form_View -> Mode ( $WF -> {mode} );

    my $page = $Form_View->display_Grid(
        -form              => $Form,
        -records           => $count,
        -cgi_app           => 'SDB::Work_Flow_App',
        -button            => $buttons,
        -append            => $append,
        -display_records   => $WF->{config}{$current_page}{records},
        -additional_fields => \@additional_fields,
        
    );
    return $page;
    ## if it's last page!!

    return 'lets build this page';

}

return 1;
