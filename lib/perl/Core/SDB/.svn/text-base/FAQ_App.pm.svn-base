###################################################################################################################################
# SDB::FAQ_App.pm
#
# Controller in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::FAQ_App;

use base LampLite::App;
use strict;

use SDB::FAQ;
use SDB::FAQ_Views;

use RGTools::RGIO;   ## include standard tools

##############################
# Dependent on methods:
#
# Session::get_sessions  (retrieve list of sessions given user, date, string)
# Session::open_session
##############################
sub setup {
##############################
    my $self = shift;

    $self->start_mode('help');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                 => 'FAQs',
            'FAQs'   => 'display_FAQs',
        }
    );

    my $dbc          = $self->param('dbc');
    my $q            = $self->query();

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

####################
sub display_FAQs {
####################
    my $self = shift;
    my $q = $self->query();
    
    my $category = $q->param('FAQ_Category');
    my $question = $q->param('FAQ_Question');
    
    return $self->View->show_FAQs(-category=>$category, -question=>$question);
}
1;


