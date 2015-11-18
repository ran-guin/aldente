##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package TCGA::Department_App;

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

use base alDente::CGI_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;    ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Form;
use alDente::Container;
use alDente::Rack;
use alDente::Validation;
use alDente::Tools;
use alDente::Source;

use TCGA::Department;
use TCGA::Department_Views;
##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $q;
my $dbc;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Home Page' => 'home_page',
        'Help'      => 'help',
        'Summary'   => 'summary',
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

###############
sub summary {
###############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $since     = $q->param('from_date_range');
    my $until     = $q->param('to_date_range');
    my $debug     = $q->param('Debug');
    my $condition = $q->param('Condition') || 1;

    my $page = "summary";
    return $page;
}

# Also, displays some basic statistics relevant to each of the run modes
##################
sub home_page {
##################

    my $self = shift;

    return Departments::TCGA::Department_Views::home_page( -dbc => $dbc );
}

###########
sub help {
############

    my $page;

    return $page;
}

return 1;
