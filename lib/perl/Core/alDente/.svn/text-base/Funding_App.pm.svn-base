###################################################################################################################################
# alDente::Funding_App.pm
#
#
#
#   By Ash Shafiei, October 2008
###################################################################################################################################
package alDente::Funding_App;

use base RGTools::Base_App;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;

## alDente modules
#use alDente::Form;
use alDente::Funding;
use alDente::Funding_Views;

use alDente::Tools;
use alDente::Work_Request_Views;

#use alDente::SDB_Defaults;

use vars qw( %Configs  $Security);

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('Home');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home'                      => 'home_page',
        'Find Funding'              => 'display_results',
        'Display Funding'           => 'funding_details_home',
        'Search Funding'            => 'display_secondary_results',
        'Search'                    => 'display_results',
        'List All Funding'          => 'display_full_list',
        'Protocol Page'             => 'protocol_page',
        'Define New Funding Source' => 'prompt_new_funding',

        #        'Generate JIRA Ticket'      => 'generate_JIRA_ticket',
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');
    $self->param( 'Model' => alDente::Funding->new( -dbc => $dbc ) );

    return 0;

}
######################################################
##          Controller                              ##
######################################################

##################
sub home_page {
##################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $q   = $self->query;
    my $dbc = $self->param('dbc');

    my $id = $args{-id} || $q->param('ID');

    if ($id) {
        $dbc->session->reset_homepage( { 'Funding' => $id } );
        return $self->funding_details_home( -id => $id );
    }

    return alDente::Funding_Views::home_page( -dbc => $dbc, -id => $id );
}

###########################
sub display_results {
###########################
    #
    #
    #
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $from_date  = $q->param('from_ApplicationDate');
    my $until_date = $q->param('to_ApplicationDate');
    my $funding    = $self->param('Model');
    my $keyword    = $q->param('Keyword');

    my @id_array;

    ( my $fields, my $values ) = alDente::Form::get_form_input( -table => 'Funding', -object => $self, -array_return => 1, -dbc => $dbc );

    my $ids = $funding->get_funding_ids(
        -fields  => $fields,
        -values  => $values,
        -from    => $from_date,
        -to      => $until_date,
        -dbc     => $dbc,
        -keyword => $keyword
    );
    @id_array = @$ids;
    my $size = @id_array;

    if ( $size == 1 ) {
        return $self->funding_details_home( -dbc => $dbc, -id => $id_array[0] );
    }
    elsif ( $size > 1 ) {
        return alDente::Funding_Views::display_list_page( -dbc => $dbc, -list => \@id_array );
    }
    else {
        Message("No Match Found - Please refine your search or use 'List All Funding' to get a full list");
        return alDente::Funding_Views::home_page( -dbc => $dbc );
    }
}

###########################
sub display_secondary_results {
###########################
    #
    #
    #
###########################
    my $self       = shift;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');
    my $funding    = $self->param('Model');
    my $goal       = $q->param('FK_Goal__ID Choice') || $q->param('FK_Goal__ID');
    my $library    = $q->param('FK_Library__Name Choice') || $q->param('FK_Library__Name');
    my $project    = $q->param('FK_Project__ID Choice') || $q->param('FK_Project__ID');
    my $goal_id    = $dbc->get_FK_ID( -field => 'Goal_ID', -value => $goal );
    my $project_id = $dbc->get_FK_ID( -field => 'Project_ID', -value => $project );

    my $ids = $funding->search_funding_ids(
        -dbc     => $dbc,
        -library => $library,
        -project => $project_id,
        -funding => $goal_id
    );
    my @id_array = @$ids;
    my $size     = @id_array;

    if ( $size == 1 ) {
        return $self->funding_details_home( -dbc => $dbc, -id => $id_array[0] );
    }
    elsif ( $size > 1 ) {
        return alDente::Funding_Views::display_list_page( -dbc => $dbc, -list => \@id_array );
    }
    else {
        Message('No Match Found - Choose less options to get more matches');
        return alDente::Funding_Views::home_page( -dbc => $dbc );
    }

}

###########################
sub display_full_list {
###########################
    my $self     = shift;
    my $dbc      = $self->param('dbc');
    my $funding  = $self->param('Model');
    my $ids      = $funding->get_funding_ids( -dbc => $dbc );
    my @id_array = @$ids;
    return alDente::Funding_Views::display_list_page( -dbc => $dbc, -list => \@id_array );
}

###########################
sub protocol_page {
###########################
    my $self    = shift;
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $funding = $self->param('Model');
    my $id      = $self->param('funding_id') || $q->param('funding_id');
    my $user_id = $dbc->get_local('user_id');

    my $Prep = alDente::Plate_Prep->new( -dbc => $dbc, -user => $user_id );

    my $plate_ids = $funding->get_plate_ids( -dbc => $dbc, -funding_id => $id );
    my $ids_list = join ',', @$plate_ids;

    return $Prep->get_Prep_history( -plate_ids => $ids_list, -view => 1 );
}

######################################################
##          View                                    ##
######################################################

#
# Reliant upon the JIRA plugin, this ties Funding Records (SOWs typically) to specific tickets
#
# Return: ticket code
##############################
sub generate_JIRA_ticket {
###############################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $funding_id = $q->param('Funding_ID');

    my $funding_details = "Details regarding Funding $funding_id (.. under construction)";

    my $page;
    if ( ( $Configs{issue_tracker} eq 'default' ) && $dbc->package_active('JIRA') ) {
        Message("Generating JIRA ticket..");

        #	$page .= $self->funding_details_home( -id => $funding_id );   ## return home page for jira ticket...
    }
    else {
        Message("JIRA Tracking is not turned on.  See LIMS Admin to include this feature");
    }

    return $page;
}

#############################
sub prompt_new_funding {
#############################
    my $self  = shift;
    my $dbc   = $self->param('dbc');
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Funding', -target => 'Database' );

    return $table->generate( -navigator_on => 1, -return_html => 1 );
}

###############################
sub funding_details_home {
###############################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;

    my $dbc = $args{-dbc} || $self->param('dbc');
    my $funding_id = $args{-id} || $self->param('funding_id') || $q->param('funding_id');
    my $funding = $self->param('Model');

    my $ids_found = $funding->validate_work_request( -dbc => $dbc, -id => $funding_id );
    my $db_object = $funding->get_db_object( -dbc         => $dbc, -id => $funding_id );

    if ($ids_found) {
        ( my $project_ids, my $goal_ids, my $library_ids ) = $funding->get_detail_ids( -dbc => $dbc, -funding_id => $funding_id );
        return alDente::Funding_Views::display_funding_details(
            -funding_id => $funding_id,

            #            -project_id => $project_ids,
            #            -library_id => $library_ids,
            -db_object => $db_object,
            -dbc       => $dbc
        );
    }
    else {
        return alDente::Funding_Views::display_empty_funding(
            -funding_id => $funding_id,
            -db_object  => $db_object,
            -dbc        => $dbc
        );
    }
}

######################################################
##          Private Functions                       ##
######################################################

###########################

1;
