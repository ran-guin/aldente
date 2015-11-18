###################################################################################################################################
# UHTS::Statistics.pm
#
#
#
#   By: Ash Shafiei 
###################################################################################################################################
package UHTS::Statistics_App;


use base RGTools::Base_App;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;

## alDente modules

use vars qw( $Connection $user_id $homelink %Configs );

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('Search');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
		'Results' 		=>  'display_Stats',
		'Search'		=>	'search_page'
    );
	$ENV{CGI_APP_RETURN_ONLY} = 1;	
    my $dbc = $self->param('dbc');

	return 0;

}
###########################
sub search_page {
###########################
 	my $self = shift;
	my $q 				= $self -> query;
	my $dbc 			= $self -> param ('dbc') || $Connection;
	my $regenerate 		= $self -> param ('Regenerate View') 	|| $q -> param ('Regenerate View');
  	my $generate_results = $self -> param ('Generate Results') 	|| $q -> param ('Generate Results'); ## whether to generate results (from param("Generate Results")
	my $form;

	my $application = 'alDente::View_App';
	eval "require $application";

	# construct object from default
	my $title =	'Illumina Statistics'; 
	my $class = "UHTS::Statistics";
	eval "require $class";
	Message($@) if $@;
	my $view = $class->new(-title=>$title, -dbc => $dbc );

	if ($regenerate) {
	   	my $key_field =  $view->{hash_display}->{-selectable_field};
	   	my @key_values = param('Mark');
	   	my $key_values = Cast_List(-list=>\@key_values,-to=>'String',-autoquote=>1);
	   	my $qualified_field = $view->{config}{'output_params'}{$key_field};
	   	if ($qualified_field) {
	       	$qualified_field =~ s/(.*) AS (.*)/$1/ig;   
	       	$key_field = $qualified_field;
	   	}
	   	$view->{config}->{'query_condition'} .= " AND $key_field IN ($key_values)";  
	}

	$view->parse_input_options();
	$view->parse_output_options();

	my $webapp = $application->new(PARAMS => {	dbc 				=> $dbc, 
												'Source Call'		=> 'UHTS::Statistics_App',
												Quiet               => 'quiet',
												Object				=> $view
												});

	if  ($generate_results ) {
	    $webapp -> start_mode ('Results')
	}
	else {
		$webapp -> start_mode ('Main');
    }
	$form .= $webapp->run();

	return $form;

	
}


###########################
sub display_Stats {
###########################
	my $self = shift;
	my $q 				= $self -> query;
	my $dbc 			= $self -> param ('dbc') || $Connection;
	my $regenerate 		= $self -> param ('Regenerate View') 	|| $q -> param ('Regenerate View');
  	my $generate_results = $self -> param ('Generate Results') 	|| $q -> param ('Generate Results'); ## whether to generate results (from param("Generate Results")
	my $save	 		= $self -> param ('Save View For') 		|| $q -> param ('Save View For');
	my $form;

	my $application = 'alDente::View_App';
	eval "require $application";

	# construct object from default
	my $title =	'Illumina Statistics'; 
	my $class = "UHTS::Statistics";
	eval "require $class";
	Message($@) if $@;
	my $view = $class->new(-title=>$title);

	if ($regenerate) {
	   	my $key_field =  $view->{hash_display}->{-selectable_field};
	   	my @key_values = param('Mark');
	   	my $key_values = Cast_List(-list=>\@key_values,-to=>'String',-autoquote=>1);
	   	my $qualified_field = $view->{config}{'output_params'}{$key_field};
	   	if ($qualified_field) {
	       	$qualified_field =~ s/(.*) AS (.*)/$1/ig;   
	       	$key_field = $qualified_field;
	   	}
	   	$view->{config}->{'query_condition'} .= " AND $key_field IN ($key_values)";  
	}

	$view->parse_input_options();
	$view->parse_output_options();

	my $webapp = $application->new(PARAMS => {	dbc 				=> $dbc, 
												'Source Call'		=> 'UHTS::Statistics_App',
												Quiet               => 'quiet',
												'Save View For'		=> $save,
												Object				=> $view
												});

	$webapp -> start_mode ('Results');
	$form .= $webapp->run();
 
	return $form;
}
1;
