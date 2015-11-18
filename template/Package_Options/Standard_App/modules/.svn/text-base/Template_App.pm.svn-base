############################
# alDente::Template_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Template_App;
use base alDente::CGI_App;

use strict;
##############################
# standard_modules_ref       #
##############################

############################
## Local modules required ##
############################

use RGTools::RGIO;

use SDB::DBIO;
use SDB::HTML;

use alDente::Template;
use alDente::Template_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs);    #

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'   => 'home_page',
            'Home Page' => 'home_page',
        }
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    my $id = $q->param("Template_ID");    ### Load Object by default automatically if standard _ID field supplied as a parameter.

    my $Template = new alDente::Template( -dbc => $dbc, -id => $id );
    my $Template_View = new alDente::Template_Views( -model => { 'Template' => $Template } );

    $self->param( 'Template'      => $Template );
    $self->param( 'Template_View' => $Template_View );
    $self->param( 'dbc'           => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}

################
sub home_page {
################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $id = $q->param('ID') || $q->param('Template_ID');

    $dbc->session->reset_homepage("Template=$id");
    return alDente::Template_Views( $dbc, $id );
}

return 1;
