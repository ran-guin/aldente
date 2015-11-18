##################
# Template_App.pm #
##################
#
# This is a template for the use of various MVC App modules (using the CGI Application module)
#
package SDB::Template_App;

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

use SDB::CustomSettings;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes( {} );

    my $dbc = $self->param('dbc');

    my $q = $self->query();

    return $self;
}

1;
