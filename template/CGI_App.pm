##################
# Goal_App.pm #
##################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Goal_App;

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

use alDente::Goal;
##############################
# global_vars                #
##############################
use vars qw(%Configs %Benchmark);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home');
    $self->header_type('none');
    $self->mode_param('rm');
    
    $self->run_modes(
        {
        'Home' => 'home',
        }
    );

    my $dbc = $self->param('dbc');
    my $goal = new alDente::Goal(-dbc=>$dbc);
    
    $self->param(
        'Goal_Model'    => $goal,
    );
    
    return $self;
}

sub home {
    return;
}

return 1;
