##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package GSC::App;

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

use base alDente::CGI_App;

use strict;

##############################
# custom_modules_ref         #
##############################

##############################
# global_vars                #
##############################

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home Page'                        => 'home_page',
        'Help'                             => 'help',
        'Custom Shipment Display'   => 'display_Shipments',
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    $self->{dbc} = $dbc;
    
    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

sub home_page {
    my $self = shift;
    return 'GSC home page...';
}

sub help {
    my $self = shift;
    return 'GSC help...';
}

########################
sub display_Shipments {
#########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    
    my $q = $self->query();
    my $limit_to_dept = $q->param('LIMIT');
    
    return $self->View->display_Shipments(-limit=>$limit_to_dept);
}

return 1;
