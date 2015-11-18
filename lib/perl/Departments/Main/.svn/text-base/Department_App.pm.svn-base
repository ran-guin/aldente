##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Main::Department_App;

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

my $q;
my $dbc;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');
    
    $self->run_modes(
		     'Home Page'	       => 'home_page', 
                     'Help'   => 'help',
		     'Summary' => 'summary',
);

    $dbc = $self->param('dbc');
    $q = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    
    return $self;
}

###############
sub summary {
###############
    my $self = shift;
    my $dbc = $self->param('dbc');
    my $q = $self->query();
    
    my $since = $q->param('from_date_range');
    my $until = $q->param('to_date_range');
    my $debug = $q->param('Debug');
    my $condition = $q->param('Condition') || 1;

    my $page = "summary";
    return $page;
}

# Also, displays some basic statistics relevant to each of the run modes 
##################
sub home_page {
##################
 
   my $self = shift;

   return Departments::Main::Department_Views::home_page(-dbc=>$dbc);
}

###########
sub help {
############

my $page;

return $page ;
}

return 1;
