###############
# User.pm #
###############
#
# This module is used to handle 'Employee' objects
#
package UTM::User;

use base LampLite::User;

use CGI;

use strict;

use RGTools::RGIO;

my $q = new CGI;

##################
sub define_User {
##################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->dbc;
    
    my $returnval = $self->SUPER::define_User(%args);

    my $access = $self->Object_data(-table=>'User', -field=>'User_Access') || 'Guest';
    $dbc->config('utm_access', $access);

    my $access_mode = $q->param('Access') || $dbc->session->param('Access') || 'Guest';
    $dbc->config('utm_access_mode', $access_mode);

    ## add simple flag for hosting access ##
    if ($access_mode =~ /Host|Admin/i) {
        $dbc->config('host', 1);
    }
    else { $dbc->config('host', 0) }
    
    return $returnval;
}


return 1;