##################
# Statistics_App.pm #
##################
#
# This module is used to monitor Goals for Library and Project objects.
#
package Core::Statistics_App;

##############################
# superclasses               #
##############################

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use Core::Statistics_Views;

##############################
# global_vars                #
##############################

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Statistics');
    $self->header_type('none');
    $self->mode_param('rm');
    
    $self->run_modes(
	'Home Page'	       => 'home_page', 
    'Statistics'                          => 'stats',
    'Generate Stats'                 => 'stats',
    );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    
    return $self;
}

############
sub stats {
############
    my $self = shift;
    my $dbc = $self->dbc();
    
    return $self->View->stats();
}

#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes 
###############
sub home_page {
###############
    my $self = shift;
    
    return 'home';
}

return 1;
