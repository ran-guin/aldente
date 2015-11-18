###################################################################################################################################
# SDB::Login_App.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package SDB::Help_App;

use base LampLite::Help_App;

use strict;

use SDB::Help;

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
        {   'default'                 => 'help',
            'Help'   => 'help',
        }
    );

    my $dbc          = $self->param('dbc');
    my $q            = $self->query();

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##########
sub help {
##########
    my $self = shift;
    my $q            = $self->query();
    my $topic = $q->param('Help') || $q->param('Quick Help');
    
    my $dbc = $self->param('dbc');
    
    my $page = $self->Views->SDB_help(-topic=>$topic);
    
    return $page;
}

1;