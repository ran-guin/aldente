###################################################################################################################################
# Healthbank::BC_Generations::Help_App.pm
#
# Controller in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package Healthbank::BC_Generations::Help_App;

use base Healthbank::Help_App;
use strict;

use Healthbank::BC_Generations::Help_Views;

use RGTools::RGIO;   ## include standard tools

############
sub setup {
############
        my $self = shift;

            $self->start_mode('Home Page');
    $self->header_type('none');
                    $self->mode_param('rm');

                        $self->run_modes(
                                'Home Page'                        => 'home_page',
                                );

                            my $dbc = $self->param('dbc');

                                    $self->update_session_info();
                                        $ENV{CGI_APP_RETURN_ONLY} = 1;

                                            return $self;
}

################
sub home_page {
################
    my $self = shift;

    my $help =<<HELP;

BC Generations LIMS
*******************

HELP

    return $help;

}
    

1;


