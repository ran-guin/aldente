###################################################################################################################################
# Template::Run_App.pm
#
#
#
#
###################################################################################################################################
package Template::Run_App;

use base alDente::CGI_App;
use strict;

## aldente modules
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use Template::Run;
use Template::Run_Views;

use vars qw($user_id $homelink %Configs );

#############################
sub setup {
#############################
# Description:
#
# Usage: 
#
#############################
    my $self = shift;
    $self->start_mode('home_page');

    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes(
        'home_page'                  => 'home_page',
        'display_secondary_page'     => 'display_secondary_page',
        'display_create_run_form'    => 'display_create_run_form',
        'create_run'                 => 'create_run',
        'transfer_to_Template_plate' => 'transfer_to_Template_plate',
	'upload_run_result'          => 'upload_run_result',
	'View Runs'                  => 'view_Runs',
	'View Analysis'              => 'view_Analysis',
    );
}

#############################
sub home_page {
#############################
# Description: Display basic information of a run and the run's result
#
# Usage: 
#
#############################
    my $self    = shift;
    my %args    = filter_input( \@_);
    my $dbc     = $args{-dbc};
    
    my $model   = Template::Run       ->    new(-dbc=>$self->{dbc});
    my $view    = Template::Run_Views ->    new();
    my $data    = $model -> get_Template_data();
    my $output  = $view  -> display_Template_main(-data=>$data);
     
    return $output;
}   

#############################
sub display_secondary_page {
#############################
# Description:
#
# Usage: 
#
#############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query();
    
    my $view    = Template::Run_Views -> new();
    my $output  = $view -> display_secondary_page();
    return $output;
}


#############################
sub display_create_run_form {
#############################
# Description: Display form that take in specific information about Template_Run
#
# Usage: 
#
#############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query();

    my $output;

    return $output;
}


#############################
sub create_run {
#############################
# Description: create Template_Run records and Run records
#
# Usage: 
#
#############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query();
    
    my $output;

    return $output;
}

#############################
sub transfer_to_Template_plate {
#############################
# Description: Create special type of plate for Template_Run if necessary
#
# Usage: 
#
#############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query();
    
    my $output;

    return $output;
}

#############################
sub upload_run_result {
#############################
# Description: Upload run result if necessary
#
# Usage: 
#
#############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query();

    my $output;

    return $output;
}

#############################
sub view_Runs {
#############################
# Description: Display specific view for Template_Run
#
# Usage: 
#
#############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query();

    my $output;

    return $output;
}

#############################
sub view_Analysis {
#############################
# Description: Display specific analysis view for Template_Run
#
# Usage: 
#
#############################
    my $self = shift;
    my %args = filter_input( \@_);
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $q    = $self->query();

    my $output;

    return $output;
}

#############################
sub get_Scanner_Actions {
    my %args = &filter_input( \@_ );
    my $dbc = $args{-dbc};
#############################
# Description: return a hash, key is the things need to scan to create the run and value is the run mode
#
# Usage: 
#
#############################

    my $actions = {
	#'Plate(1-N)+Equipment[Template](1-N)' => 'Template::Run_App::display_create_run_form', # Equ***Pla***
    };

    return $actions;


}

1;
