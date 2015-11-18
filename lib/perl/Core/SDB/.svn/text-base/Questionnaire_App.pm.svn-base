##################
# Form_App.pm #
##################
#
#
package SDB::Questionnaire_App;

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
use SDB::Questionnaire_Views;
use SDB::Questionnaire;
use SDB::Form_Views;
use SDB::Form;
use alDente::Form;

my $BS = new Bootstrap();

##############################
# global_vars                #
##############################
use vars qw(%Configs);
my $q = new CGI;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes( { 'start' => 'start_Questionnaire', } );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

####################
sub start_Questionnaire {
####################
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $mode          = $q->param('Mode');
    my $submission_id = $q->param('Submission_ID');

    my $append = $q->hidden( -name => 'Mode', -value => $mode, -force => 1 ) . $q->hidden( -name => 'Submission_ID', -value => $submission_id, -force => 1 );

    my @pages = (
        {   -name    => 'Number of Samples',
            -content => $self->View->sample_count_Page()
        },
        {   -name    => 'Sample Nature',
            -content => $self->View->sample_type_Page(),
        },
        {   -name    => 'Additional Information',
            -content => $self->View->Xenograft() . $self->View->Disease_types() . $self->View->Taxonomy()
        },
        {   -name    => 'Save Form',
            -content => $self->View->display_Save_Form(),
        },
    );

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc ) . $BS->wizard( -title => 'Sample Questionaire', -pages => \@pages ) . $append . $q->end_form();

    return $page;
}

return 1;
