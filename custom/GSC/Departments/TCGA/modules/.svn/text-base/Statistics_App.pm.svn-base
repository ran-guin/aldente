###################################################################################################################################
# TCGA::Statistics_App.pm
#
#
#
###################################################################################################################################
package TCGA::Statistics_App;


use base RGTools::Base_App;
use strict;

use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use alDente::Form;
use TCGA::Statistics;
use TCGA::Statistics_Views;

use vars qw( $user_id $homelink %Configs );

###########################
sub setup {
###########################
#
###########################
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'   				=> 'home_page',
            'Home Page' 				=> 'home_page',
			'Show Shipment Summary' 	=>'show_shipment_summary',
			'Show Organization Summary' => 'show_organization_summary',
			'Show Tissue Type Summary' 	=> 'show_tissue_type_summary',
			'Show Histology Summary'	=> 'show_histology_summary',
			'Show Project Summary'		=> 'show_project_summary',
		}
    );

    my $dbc = $self->param('dbc');
    $q   = $self->query();

    my $Model = new TCGA::Statistics( -dbc => $dbc );
    my $View = new TCGA::Statistics_Views( -model => { 'Model' => $Model } );

    $self->param( 'Model'      => $Model );
    $self->param( 'View' => $View );
    $self->param( 'dbc'           => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}


###########################
sub search_page {
###########################
#
#
#
#
###########################
	my $self = shift;
	my $q 				= $self -> query;
	my $dbc 			= $self -> param ('dbc');
	my $form;
	Message "hiiiiiiiii";
	return 1;
}

###########################
sub home_page {
###########################
#
#
#
#
###########################
 	my $self = shift;
	my $q 				= $self -> query;
	my $dbc 			= $self -> param ('dbc');
	my $form;
    return $self->param('View') -> home_page(-dbc => $dbc);    

}

#############################################################
sub show_shipment_summary {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc   = $args{-dbc} || $self -> param ('dbc');
    my $View = $self->param('View');
	return $View -> shipment_summary (-dbc => $dbc);
}
#############################################################
sub show_organization_summary  {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc   = $args{-dbc} || $self -> param ('dbc');
    my $View = $self->param('View');
	return $View -> organization_summary (-dbc => $dbc);
}
#############################################################
sub show_tissue_type_summary  {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc   = $args{-dbc} || $self -> param ('dbc');
    my $View = $self->param('View');
	return $View -> tissue_type_summary (-dbc => $dbc);

}
#############################################################
sub show_histology_summary  {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc   = $args{-dbc} || $self -> param ('dbc');
    my $View = $self->param('View');
	return $View -> histology_summary (-dbc => $dbc);

}

#############################################################
sub show_project_summary  {
#################
#
#
# Return: html page
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $dbc   = $args{-dbc} || $self -> param ('dbc');
    my $View = $self->param('View');
	return 'Under Construction';

}
1;
