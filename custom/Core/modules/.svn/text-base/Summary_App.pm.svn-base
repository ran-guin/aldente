##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Core::Summary_App;

##############################
# superclasses               #
##############################

use base SDB::CGI_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use LampLite::Bootstrap;
use Core::Summary_Views;
##############################
# global_vars                #
##############################

my $BS = new Bootstrap();

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Summary');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Summary' => 'summary',
        'Re-Generate Summary' => 'summary',
        'Generate Summary' => 'summary',
        );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##############
sub summary {
##############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    return 'generated custom summary';
}

return 1;
