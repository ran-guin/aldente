############################
# alDente::Contact_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Contact_App;
use base alDente::CGI_App;
use strict;

## Local modules required ##

use RGTools::RGIO;
use RGTools::RGmath;
use SDB::DBIO;
use SDB::HTML;
use alDente::Tools;
use alDente::Contact;
use alDente::Contact_Views;

## global_vars ##
use vars qw(%Configs);

############
sub setup {
############
    my $self = shift;
    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'             => 'entry_page',
            'Home'                => 'home_page',
            'List'                => 'list_page',
            'Main'                => 'main_page',
            'Create LDAP Account' => 'create_LDAP_account',
        }
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    my $id = $q->param("Contact_ID") || $q->param("ID");    ### Load Object by default if standard _ID field supplied.
    my $Contact = new alDente::Contact( -dbc => $dbc, -id => $id );
    my $Contact_View = new alDente::Contact_Views( -model => { 'Contact' => $Contact } );

    $self->param( 'Contact'      => $Contact );
    $self->param( 'Contact_View' => $Contact_View );
    $self->param( 'dbc'          => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}

###########################
sub entry_page {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('ID');
    unless ($id) { return $self->main_Page( -dbc => $dbc ) }
    if ( $id =~ /,/ ) { return $self->list_page( -dbc => $dbc, -list => $id ) }
    else              { return $self->home_page( -dbc => $dbc, -id => $id ) }
}

###########################
sub home_page {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('id') || $args{-id};
    return $self->param('Contact_View')->home_page( -dbc => $dbc, -id => $id );
}

###########################
sub list_page {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $list = $q->param('list') || $args{-list};
    my $view = $dbc->Table_retrieve_display(
        -table       => "Contact",
        -fields      => ['*'],
        -condition   => "WHERE Contact_ID IN ($list)",
        -return_html => 1,
    );
    return $view;
}

###############
sub main_Page {
###############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    return $self->param('Contact_View')->contact_main( -dbc => $dbc );
}
###########################
sub create_LDAP_account {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $id   = $q->param('Contact_ID');
    my $name = $q->param('user_name');

    ### MAKE SURE NOT TO CALL IF NOT PRODUCTION
    my $found = $self->param('Contact')->find_LDAP_account( -name => $name );

    if ($found) {
        Message "Account '$name' is already being used.  Please try again";
        return $self->param('Contact_View')->home_page( -dbc => $dbc, -id => $id );
    }
    else {
        ## check for no spaces
        ## get account
        ## send email
        ## update contact table
    }

    return 'UNDER_CONSTRCTION';

}

return 1;
