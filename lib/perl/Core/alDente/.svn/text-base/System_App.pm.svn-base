###################################################################################################################################
# Sequencing::Statistics.pm
#
#
#
#
###################################################################################################################################
package alDente::System_App;
use base alDente::CGI_App;

use strict;

## RG Tools
use RGTools::RGIO;
use RGTools::Conversion;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use alDente::System;
use alDente::System_Views;

use vars qw( %Configs);
my $q = new CGI;

#####################
sub setup {
#####################
    my $self = shift;
    $self->start_mode('entry_page');
    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes(
        'entry_page'                => 'entry_page',
        'Display Volume History'    => 'display_Graph',
        'Display Directory History' => 'display_Graph',
        'Display Sub_Directories'   => 'display_Sub_directories'
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $dbc = $self->param('dbc');

    my $model = alDente::System  -> new( -dbc => $dbc );

    $self->param(
		 'Model' =>  $model,
		 'View'  => new alDente::System_Views( -dbc => $dbc, -models => [$model])
		 );
    
    return $self;
}

#####################
sub entry_page {
#####################
    my $self = shift;
    my $dbc     = $self->{dbc};
    my $view    = $self -> param('View');

    my $host    = $q -> param('Host');

    my $output =  $view->display_Entry_Page($host);
    return $output;
}   

####################################
sub display_Graph {
####################################
    my $self        = shift;
    my $dbc         = $self -> {dbc};
    my $view        = $self -> param('View');
    my $directory   = $q    -> param('Dir_Name');
    my $host        = $q    -> param('Host');
    my $ymax        = $q -> param('Ymax');
    my $type        = $q -> param('Type');

    my $output      = $view  -> display_Graph(-directory => $directory, -host => $host, -ymax=>$ymax, -type=>$type) ;
    return $output;
}

#################################
sub display_Sub_directories {
#################################
    my $self        = shift;
    my $dbc         = $self -> {dbc};
    my $view        = $self -> param('View');
    my $directory   = $q    -> param('Dir_Name');
    my $host        = $q    -> param('Host');
    my $graphs      = $q    -> param('Graphs');

    my $page;
    $page .= $view->show_usage_table(-host=>$host, -follow=>$directory, -graph=>$graphs, -type=>'dirs');

    $page ||= "Could not find $directory subdirectories";

    return $page;
}



1;
