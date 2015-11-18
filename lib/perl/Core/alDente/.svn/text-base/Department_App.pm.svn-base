##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package alDente::Department_App;

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

use base alDente::CGI_App;

use strict;

## SDB modules
use SDB::HTML;

## RG Tools
use RGTools::RGIO;

use alDente::Department;
use alDente::Department_Views;

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
            'Database' => 'display_Database',
    );

    $self->update_session_info();    ## needed to dynamically recover session attributes if not supplied (eg printer_group)

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    return 0;
}

#
# This standardizes the Database run mode for all departments
# 
# Requirements: The Department model should include the method: get_searches_and_creates
#
# ... this may be tidied up later to create a more intuitive accessor for this information, but it centralizes it for now.
#
#  Note: first line of get_searches_and_creates should be:
#  
#  my %args   = filter_input(\@_, -self=>'DeptName::Department');   ## must include self argument to enable to be called as either function or method ##
#
##########################
sub display_Database {
########################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my $local = ref $self;
    $local =~s/_App//;   ## convert from App to Model 
    
    eval "require $local";
    my ( $search_ref, $creates_ref, $conversion_ref, $custom ) = $local->get_searches_and_creates( -access => \%Access );
    my @searches    = @$search_ref;
    my @creates     = @$creates_ref;
    my @conversions = @$conversion_ref;

    my $search_create_box = alDente::Department::search_create_box($dbc, -search => \@searches, -create => \@creates, -convert => \@conversions, -custom_search => $custom );
}

1;
