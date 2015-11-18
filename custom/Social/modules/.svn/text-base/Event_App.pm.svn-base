###################################################################################################################################
# Social::Event_App.pm
#
# Controller in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package Social::Event_App;

use base SDB::DB_Object_App;

use strict;

use Social::Event;
use Social::Event_Views;

use RGTools::RGIO;   ## include standard tools

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home Page'                        => 'home_page',
        'Attend' => 'attend_Event',
        'Publish'     => 'publish_Event',
        'Generate Invitation List'     => 'check_Invites',
        'Cancel Event' => 'cancel_Event',
);

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

################
sub home_page {
################
    my $self = shift;

    return 'cancel event...';
}

################
sub attend_Event {
################
    my $self = shift;
    
    return 'attend event...';
}

####################
sub publish_Event {
####################
    my $self = shift;

    return 'publish event...';
}
####################
sub check_Invites {
####################
    my $self = shift;
    my $q = $self->query();
    
    my $id = $q->param('Event_ID');
    
    my @invitees = $self->Model->generate_Invitation_List($id); 
    
    return $self->View->std_home_page($id);
}

###################
sub cancel_Event {
###################
    my $self = shift;

    return 'cancel event...';
}

1;


