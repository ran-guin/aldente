##################
# SVN_App.pm #
##################
#
# This module is used to monitor SVNs for Library and Project objects.
#
package SDB::SVN_App;

## Standard modules required ##

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML qw(vspace HTML_Dump);

use SDB::SVN;
use SDB::SVN_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs);  # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('show Tags');
    $self->header_type('none');
    $self->mode_param('rm');
    
    $self->run_modes(
		     {
			 'Show Tags' => 'show_Tags',
		     });
    
    my $dbc = $self->param('dbc');

    my $q = $self->query();


    return $self;
}

#####################
sub show_Tags {
#####################
    my $self = shift;
    my %args = &filter_input( \@_);
    my $dbc        = $args{-dbc} || $self->param('dbc');
    my $q = $self->query();
    my $version    = $q->param('Version');
    
    my $output = &SDB::SVN_Views::view_Tags(-dbc => $dbc, -version=>$version); 

    return $output;
}

return 1;
