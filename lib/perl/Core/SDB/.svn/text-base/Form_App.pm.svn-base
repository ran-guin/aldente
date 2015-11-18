##################
# Form_App.pm #
##################
#
#
package SDB::Form_App;

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
        {   'New Form'  => 'new_Form',
            'Save Data' => 'save_Data',
        }
    );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}
##########################
# TO DO:
#     Controller to control the flow from one form to another and update each other
#     Top part of page
#     Buttons for:
#              - paste (pop out)
#              - autofil
#              - clear
#              - help icon
#      Validator for each element after typing
#     key fields??
#
#
#
#
#
#
#
#
#
#
#
##########################

##########################
sub save_Data {
##########################
    my $self          = shift;
    my $q             = $self->query();
    my $dbc           = $self->{dbc} || $self->param('dbc');
    my $count         = $q->param('record_count');
    my $title         = $q->param('title');
    my $submission_id = $q->param('Submission_ID');
    my $fields        = Safe_Thaw( -name => 'fields', -thaw => 1, -encoded => 1 );
    my @fields        = @$fields if $fields;
    my $col_count     = @fields;
    my %input;

    ## Get form input
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

    SDB::Submission::write_to_file( -submit_type => 'NEW TYPE', -data_ref => \%file_data, -dbc => $dbc, -sid => $submission_id, -type => 'xml', -file_prefix => $title );
    return 1;
}

##########################
sub new_Form {
##########################
    my $self          = shift;
    my $q             = $self->query();
    my $dbc           = $self->{dbc} || $self->param('dbc');
    my $template_file = $q->param('template_file');
    my $submission    = $q->param('Submission_ID');
    my $max_row       = $q->param('Row');
    my $max_col       = $q->param('Col');
    my $order         = $q->param('Order');

    ## NUMBER OF SAMPLES
    ### how to tie to submission id????
    ### how to know which fields need to be GREYED out
    ### ADDABLE button for work request

    my $Form = new SDB::Form( -dbc => $dbc );
    $Form->load(
        -template_file => $template_file,
        -submission_id => $submission,
    );

    $Form->load_slots( -max_row => $max_row, -max_col => $max_col, -order => $order );

    my $page = $self->View->display_Grid( -form => $Form, -records => 10 );

    return $page;

}

return 1;
