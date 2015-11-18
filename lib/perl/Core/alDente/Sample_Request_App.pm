##################
# Sample_Request_App.pm #
##################
#
# This is a Sample_Request for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Sample_Request_App;

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

#use base SDB::Sample_Request_App;
use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Sample_Request;
use alDente::Sample_Request_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

my $Import;
my $Import_View;
################
# Dependencies
################
#
# (document list methods accessed from external models)
#

###########################################################
# Previous methods that were here, but now commented out
###########################################################

############
sub setup {
############
    my $self = shift;

    $self->start_mode('entry_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'home_page'  => 'home_page',
            'main_page'  => 'main_page',
            'entry_page' => 'entry_page',

            'New Shipment'    => 'add_New_Shipment',
            'New Request'     => 'add_New_Request',
            'Search Requests' => 'search_Requests',
            'Print Label'     => 'print_Label',

        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    my $Sample_Request = new alDente::Sample_Request( -dbc => $dbc );
    my $View = new alDente::Sample_Request_Views( -dbc => $dbc, -model => $Sample_Request );

    $self->param( 'Model' => $Sample_Request );
    $self->param( 'View'  => $View );
    $self->param( 'dbc'   => $dbc );

    return $self;
}

################
sub entry_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    my $id   = $q->param('ID');

    if ( $id =~ /,/ ) {
        return "UNDER CONSTRCUTION";
    }
    elsif ($id) {
        return $self->param('View')->home_page( -id => $id );
    }
    else {
        return $self->param('View')->main_page();
    }

}

################
sub main_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    return $self->param('View')->main_page( -dbc => $dbc );
}

################
sub home_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    my $id   = $q->param('ID');

    return $self->param('View')->home_page( -id => $id ) if $id;
}

################
sub add_New_Shipment {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    my $id   = $q->param('ID') || $q->param('FK_Sample_Request__ID');
    return $self->param('View')->display_New_Shipment( -id => $id ) if $id;

}

################
sub add_New_Request {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    return $self->param('View')->display_New_Request();

}

################
sub search_Requests {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    my $id   = $q->param('ID');
    return "UNDER CONSTRCUTION"

}

################
sub print_Label {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    my $id   = $q->param('ID');
    return "UNDER CONSTRCUTION"

}

1;
