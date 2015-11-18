###################################################################################################################################
# alDente::Study_App.pm
#
###################################################################################################################################
package alDente::Study_App;
use base alDente::CGI_App;
use strict;

## Local modules ##
use SDB::DBIO;
use SDB::HTML;

use RGTools::RGIO;

use alDente::Study;
use alDente::Study_Views;

use vars qw( %Configs );

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'default'          => 'entry_page',
        'Define New Study' => 'new_study',
        'View Studies'     => 'list_page',
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    # Load object by default
    my $id = $q->param("Study_ID") || $q->param("ID");

    if ($id) {
        my $Study = new alDente::Study( -dbc => $dbc, -id => $id );
        my $Study_View = new alDente::Study_Views( -model => $Study );

        $self->param( 'Study'      => $Study );
        $self->param( 'Study_View' => $Study_View );
    }

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}

#####################
# entry_page (default). Display home_page or go to search page
#
# Return: html page.
#####################
sub entry_page {
    my $self = shift;
    my %args = filter_input( \@_ );

    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $view = $self->param('Study_View');

    if ($view) {
        return $view->home_page();
    }
    else {
        return $self->search_page();
    }
}

######################
# Get the search page
#
# Return: html
#####################
sub search_page {
#####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $view = new alDente::Study_Views( -dbc => $dbc );
    return $view->search_page();
}

sub home_page {
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $output = "Under construction";
    return $output;

}

################
# Create a new study
#
# Return: html page
##################
sub new_study {
####################
    my $self  = shift;
    my $dbc   = $self->param('dbc');
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Study', -target => 'Database' );

    return $table->generate( -navigator_on => 1, -return_html => 1 );

}

################################
# View page for studies (providing search result for search_page)
#
# Return: html page
############################
sub list_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @study_names   = $q->param("Study.Study_Name Choice");
    my $study_ids_str = $q->param("Study IDs");
    my @study_ids     = Cast_List( -list => $study_ids_str, -to => 'Array' );

    my $view = new alDente::Study_Views( -dbc => $dbc );
    return $view->view_studies( -study_names => \@study_names, -study_ids => \@study_ids );
}

return 1;
