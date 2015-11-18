###################################################################################################################################
# Template::Run_Stat_App.pm
#
#
#
#
###################################################################################################################################
package Template::Run_Stat_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use base RGTools::Base_App;
use strict;
use Imported::CGI_App::Application;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use alDente::Form;
use Template::Run_Stat;
use Template::Run_Stat_Views;

##############################
# global_vars                #
##############################
use vars qw($user_id $homelink %Configs );

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Search');
    $self->header_type('none');
    $self->mode_param('rm');
    
    $self->run_modes(
		'Search'		        =>	'search_page',
    );

    my $dbc = $self->param('dbc');
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    
    return $self;
}

###########################
sub search_page {
###########################
 	my $self = shift;
	my $dbc 			= $self -> param ('dbc') ;
    return  Template::Run_Stat_Views::display_search_page(-dbc=>$dbc);
}
#
return 1;