##################
# Statistics_App.pm #
##################
#
# This module is used to monitor Goals for Library and Project objects.
#
package UTM::Statistics_App;

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
	'Home Page'	       => 'home_page', 
    );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    
    return $self;
}


#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes 
###############
sub home_page {
###############
 
   my $self = shift;
   my $q = $self->query;
   my $dbc = $self->param('dbc') ;

    my $output = 'home page';
    return $output;
}

return 1;
