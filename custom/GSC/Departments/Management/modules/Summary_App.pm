###################################################################################################################################
# Mapping::Summary_App.pm
#
#
#
#
###################################################################################################################################
package Management::Summary_App;


use base RGTools::Base_App;
use CGI qw(:standard);
use Data::Dumper;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use Imported::CGI_App::Application;
use base 'CGI::Application';
use strict;
use alDente::Form;


use vars qw( $Connection $user_id $homelink %Configs );



sub setup {
    my $self = shift;

    $self->start_mode('Default Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Default Page' 	=>  'summary_page',
		'Display' 		=>  'display_Summary'	
    );
	$ENV{CGI_APP_RETURN_ONLY} = 1;	
    my $dbc = $self->param('dbc');


	return 0;

}


###########################
sub summary_page {
###########################
    my $self = shift;
	my $form;
	my $q = $self->query;

	$form .= start_custom_form(-name => 'summary home', -parameters => {&_alDente_URL_Parameters()});
	$form .= Views::sub_Heading ("Summary", -1);
	$form .= "We are at Management summary";
	$form .= $q-> hidden (-name => 'cgi_application', -value => 'Management::Summary_App' ,-force=>1);	
	$form .= $q-> submit (-name => 'rm',-value => 'Display', -class => "Search" ,-force=>1);  
	$form .=  	 "<span class=small>" . vspace() 
				."note: This button will take you to the display page" 
				. "</span>";
	$form .= end_form();

	return $form;
}


###########################
sub display_Summary {
###########################
    my $self = shift;
	my $form;
	my $q = $self->query;
	
	$form .= Views::sub_Heading ("Summary", -1);
	$form .=  	 "Here's the display for Management" ;

	return $form;
}
1;
