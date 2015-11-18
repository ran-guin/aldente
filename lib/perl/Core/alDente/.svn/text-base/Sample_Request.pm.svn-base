###################################################################################################################################
# alDente::Sample_Request.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Sample_Request;
use base SDB::DB_Object;    ## remove this line if object is NOT a DB_Object

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

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id  = $args{-id};

    my $self = {};    ## if object is NOT a DB_Object ... otherwise...
    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->{dbc} = $dbc;
    $self->{id} = $id;

    if ($id) {
       $self->add_tables( 'Sample_Request');
       $self->primary_value( -table => 'Sample_Request', -value => $id );
       $self->load_Object( -force => 1 );
    }

    return $self;
}


1;
