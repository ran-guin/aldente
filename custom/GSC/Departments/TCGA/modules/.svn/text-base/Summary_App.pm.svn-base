###################################################################################################################################
# TCGA::Summary_App.pm
#
#
#
###################################################################################################################################
package TCGA::Summary_App;


use base RGTools::Base_App;
use strict;

use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use alDente::Form;
use TCGA::Summary;
use TCGA::Summary_Views;

use vars qw( $user_id $homelink %Configs );

###########################
sub setup {
###########################
#
###########################
    my $self = shift;

    $self->start_mode('Search');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
		'Results' 		=>  'display_Summary',
		'Search'		=>	'search_page'
    );
	$ENV{CGI_APP_RETURN_ONLY} = 1;	
    my $dbc = $self->param('dbc');

	return 0;

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
    return $form;    
}

###########################
sub display_Summary {
###########################
#
#
#
#
###########################
 	my $self = shift;
	my $q 				= $self -> query;
	my $dbc 			= $self -> param ('dbc') ;
	return $form;

}

1;
