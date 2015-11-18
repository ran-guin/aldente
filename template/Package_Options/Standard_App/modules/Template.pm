###################################################################################################################################
# alDente::Template.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Template;
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
    my $id   = $args{-id} || $args{-template_id};    ##

    # my $self = {};   ## if object is NOT a DB_Object

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Template' );    ## if object IS a DB_Object (generally and class relating to database record)
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        ## $self->add_tables();  ## add tables to standard object if applicable (relationships that ALWAYS link records to other database records)
        $self->primary_value( -table => 'Template', -value => $id );                 ## same thing as above..
        $self->load_Object();
    }

    return $self;
}

#########################################################################
# Script to run whenever a new Template record is added to the database
#
###########################
sub new_Template_trigger {
###########################
    return;
}

1;
