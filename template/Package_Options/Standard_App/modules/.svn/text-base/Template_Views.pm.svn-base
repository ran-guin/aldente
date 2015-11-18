###################################################################################################################################
# alDente::Template_Views.pm
#
# Interface generating methods for the Template MVC  (associated with Template.pm, Template_App.pm)
#
###################################################################################################################################
package alDente::Template_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use vars qw( %Configs );

#############################################
#
# Standard view for single Template record
#
#
# Return: html page
###################
sub home_page {
###################
    my $self = shift;
    my %args = filter_input( \@_, 'id' );
    my $id   = $args{-id};

    my $Template = $self->param('Template');
    my $dbc      = $Template->param('dbc');

    $id = Cast_List( -list => $id, -to => 'string' );

    if ( $id =~ /,/ ) {
        return $self->list_page(%args);
    }

    my $page;

## Generate interface view for single Template object ##

    return $page;
}

#############################################################
# Standard view for multiple Template records if applicable
#
#
# Return: html page
#################
sub list_page {
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $id   = $args{-id};

    my $Template = $self->param('Template');
    my $dbc      = $Template->param('dbc');

    my $page;

    return $page;
}

1;
