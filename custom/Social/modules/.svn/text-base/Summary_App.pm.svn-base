##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Social::Summary_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base RGTools::Base_App;

use strict;

use Social::Summary_Views;
##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;

use LampLite::Bootstrap;
use LampLite::CGI;

my $q = new LampLite::CGI;


##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $dbc;
my $BS = new Bootstrap();

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Summary');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Summary' => 'summary',
        'Re-Generate Summary' => 'summary',
        'Generate Summary' => 'summary',
        );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##############
sub summary {
##############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();
    return 'generated custom summary';
}

return 1;
