###############################################################################################################
# 				Session_App.pm
###############################################################################################################
#
#	This module provides a simple Controller based upon CGI::Application and CGI::Session
#
###############################################################################################################
package LampLite::Session_App;

use base RGTools::Base_App;

use strict;

use RGTools::RGIO;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::Session_Name - Wrapper for Controller using CGI::Application & CGI::Session 

=head1 SYNOPSIS <UPLINK>

=head1 DESCRIPTION <UPLINK>sub

=for html
  
=cut

##############################
# standard_modules_ref       #
##############################
use DBI;
use Carp;

############################
## Local modules required ##
############################

##############################
# global_vars                #
##############################

##############################
# Methods:
##############################

#
# Standard initialization method defining CGI::Application run modes 
##############################
sub setup {
##############################    my $self = shift;
    my $self = shift;
    $self->start_mode('search_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                 => 'search_page',
            'search_page'             => 'search_page',
            'display_Session_details' => 'display_Session_details',
            'display_Sessions_List'   => 'display_Sessions_List',
            'Log In'                  => 'attempt_Login',
            'Search'                  => 'display_Sessions_List',
            'Show Printers'           => 'show_Printers',
            'View Settings'           => 'persistent_Settings',
            'Preferences'             => 'display_Preferences',
            'Set Preferences'         => 'set_Preferences',            
        }
    );

    my $dbc          = $self->param('dbc');
    my $q            = $self->query();

    my $class = ref $self;
    $class =~s/_App$//;
    
    my ($Session, $Session_View);    
    if (defined $dbc->{session}) { 
        $Session = $dbc->session();
    }
    else {
        eval "require $class";
        $Session      = $class->new('id:md5', $q);
    }
    
    $Session->init($dbc);
    
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

#
# Quick accessor to View module 
# (Since Base Model cannot be used for Session object which is a different class
#
###########
sub Model {
###########
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $class = $args{-class};

    if ($class) { return $self->SUPER::Model(%args) }
    
    if ($dbc) { $self->{dbc} = $dbc }
    $dbc ||= $self->{dbc};

    return $dbc->session();
}

######################
sub set_Preferences {
######################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $settings = $dbc->session->user_setting();

    my $page = "<h3>User Settings</h3>";

    my $Pref = new HTML_Table( -title => 'User Settings', -border => 1 );
    $Pref->Set_Headers( [ 'Setting', 'Default' ] );
    if ($settings) {
        my @keys   = keys %$settings;
        my @values = values %$settings;

        foreach my $i ( 1 .. int(@keys) ) {
            $Pref->Set_Row( [ $keys[ $i - 1 ], $values[ $i - 1 ], 'Edit', 'Delete' ] );
        }

        $page .= $Pref->Printout(0);
    }

    $page .= "<P>Edit / Delete Options are still under Construction...";
    return $page;

}

######################
sub persistent_Settings {
######################
    my $self = shift;
    my $dbc  = $self->dbc();

    eval "require LampLite::HTML";
   
    my $V = $self->View;

    my $page = $self->View->show_user_settings(-dbc=>$dbc)
        . '<HR>';   

    $page .=  LampLite::HTML::create_tree(-tree=> { 'Persistent Session Settings' => $self->View->show_session_settings } );

    return $page;

}

##############################
# private_functions          #
##############################

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

return 1;
