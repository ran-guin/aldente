############################
# alDente::Session_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Session_App;
use base SDB::Session_App;

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

use alDente::Session;
use alDente::Session_Views;

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

    my $id = $q->param("Session_ID");    ### Load Object by default automatically if standard _ID field supplied as a parameter.

    my $Session = new alDente::Session( -dbc => $dbc, -id => $id );
    my $Session_View = new alDente::Session_Views( -model => { 'Session' => $Session } );

    $self->param( 'Session'      => $Session );
    $self->param( 'Session_View' => $Session_View );
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

    my $id = $q->param('ID') || $q->param('Session_ID');

    $dbc->session->reset_homepage("Session=$id");
    return alDente::Session_Views( $dbc, $id );
}

return 1;
