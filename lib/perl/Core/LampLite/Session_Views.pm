###################################################################################################################################
# LampLite::Session_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package LampLite::Session_Views;

use base LampLite::Views;
use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::Session_Name - Wrapper for Controller using CGI::Application & CGI::Session 

=head1 SYNOPSIS <UPLINK>

=head1 DESCRIPTION <UPLINK>sub

=for html
  
=cut

## Standard modules ##
use CGI qw(:standard);

my $q = new CGI;
############################
## Local modules required ##
############################

##############################
# Methods:
##############################

##############################
# public_methods        #
##############################
######################
sub show_session_settings {
######################
    my $self = shift;
    my $dbc = $self->dbc();
    
    my $block = "<h3>Persistent Session Settings</h3>";
    my $settings = $dbc->session->param('persistent_parameters');

    my $Pref = new HTML_Table( -title => 'Current Session Settings', -border => 1 );
    $Pref->Set_Headers( [ 'Setting', 'Default' ] );
    if ($settings) {
        foreach my $setting (@$settings) {
            my $value = $dbc->session->param($setting);
            $Pref->Set_Row( [ $setting, $value ] );
        }

        $block .= $Pref->Printout(0);
    }
    
    return $block;
}

######################
sub show_user_settings {
######################
    my $self = shift;   
    my $dbc = $self->dbc();
  
    my $block = "<h3>User Settings</h3>";

    my $settings = $dbc->session->user_setting();
  
    my $Pref = new HTML_Table( -title => 'User Settings', -border => 1 );
    $Pref->Set_Headers( [ 'Setting', 'Value'] );
    if (ref $settings eq 'HASH') {
        my @keys = keys %$settings;
        foreach my $key (keys %$settings) {
            $Pref->Set_Row([$key, $settings->{$key}]);
        }
    } 
    else {
        print "Type: " . ref $settings;
    }

    $block .= $Pref->Printout(0);

    return $block;
}

##############################
# main_footer                #
##############################

##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

Ran Guin

=head1 CREATED <UPLINK>

2013-08-20

=head1 REVISION <UPLINK>

$Id$ (Release: $Name$)

=cut

1;
