##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Core::App;

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

use base SDB::CGI_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;    ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);

use Core::Model;
use Core::Views;

##############################
# global_vars                #
##############################

my $dbc;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home Page'                        => 'home_page',
);

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}


#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes
##################
sub home_page {
##################

    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $home_form = $self->help();

    return $home_form;
}

###########
sub help {
############

    my $page;

    $page .= "<B>General Instructions:</B>....";
    return $page;
}

return 1;
