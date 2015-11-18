##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package Healthbank::BCG_Mobile::Department_App;

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

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML;  ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);
use SDB::DBIO;
use SDB::CustomSettings;

use Healthbank::BCG_Mobile::Department_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);  # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');
    
    $self->run_modes(
		     'Home Page'	       => 'home_page', 
                     'Help'   => 'help',
                    'Summary' => 'summary',
);

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    
    return $self;
}

sub summary {
    return  'Overall Summary page (under construction)';
}


#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes 
##################
sub home_page {
##################
 
   my $self = shift;
   my $q = $self->query;
   my $dbc = $self->param('dbc') ;

   my @other_run_modes = ('Display Samples','Display Tubes','Display Preps');

   my $home_form = Healthbank::BCG_Mobile::Department_Views::home_page($dbc); 

   return $home_form;
}

#
#
# 
###########
sub help {
############

my $page;

$page .= Healthbank::Views::help();

return $page ;
}
