####################
# Priority_Object_App.pm #
####################
#
# This is a Priority_Object for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Priority_Object_App;

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

use SDB::CustomSettings;
use SDB::HTML;
use RGTools::RGIO;
use alDente::SDB_Defaults;

use alDente::Priority_Object_Views;
use alDente::Priority_Object;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Settings $Security);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'home_page'    => 'home_page',
            'Set Priority' => 'set_priority',
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    return $self;
}

###############
sub home_page {
###############
    my $self = shift;

    return 'Priority_Object_App Home';
}

sub set_priority {
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query;
    my $object        = $q->param('Object');
    my $priority      = $q->param('Priority');
    my $priority_date = $q->param('Priority_Date');
    my @marked        = $q->param('Mark');

    if ( @marked && ( $priority || $priority_date ) ) {
        my $priority_obj = new alDente::Priority_Object( -dbc => $dbc );
        foreach my $id (@marked) {
            my $ok = $priority_obj->update_priority( -priority => $priority, -priority_date => $priority_date, -object_class => $object, -object_id => $id, -override => 1, -quiet => 1 );
            if ( !$ok ) {
                $ok = $priority_obj->set_priority( -priority => $priority, -priority_date => $priority_date, -object_class => $object, -object_id => $id );
            }
            if ( !$ok ) {
                $dbc->error("Set Priority failed for $object $id!");
            }
        }
    }
    return;

}

1;

