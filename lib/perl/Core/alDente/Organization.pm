###################################################################################################################################
# alDente::Organization.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Organization;
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
    my $id   = $args{-id} || $args{-Organization_id};    ##

    # my $self = {};   ## if object is NOT a DB_Object

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Organization' );    ## if object IS a DB_Object (generally and class relating to database record)
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        ## $self->add_tables();  ## add tables to standard object if applicable (relationships that ALWAYS link records to other database records)
        $self->primary_value( -table => 'Organization', -value => $id );                 ## same thing as above..
        $self->load_Object();
    }

    return $self;
}

############################
sub local_organization_id {
############################
    my $dbc = shift;
    
    if ( ! $dbc->get_local('Organization_ID')) { 

        my $local_org = $dbc->config('installation');
        my ($internal_org_id) = $dbc->Table_find('Organization','Organization_ID',"WHERE Organization_Name = '$local_org'");
    
        if ($internal_org_id) { 
            $dbc->set_local('Organization_ID', $internal_org_id);
        }
    }
   
    return $dbc->get_local('Organization_ID');
}

#########################################################################
# Script to run whenever a new Organization record is added to the database
#
###########################
sub new_Organization_trigger {
###########################
	my $self 	= shift;
    my $dbc 	= $self -> {dbc};
    my ($id)    = $dbc -> Table_find( 'Organization', 'Max(Organization_ID)' );
	my $local 	= $dbc -> Table_find( 'Organization', 'Organization_Type',"WHERE Organization_ID = $id and Organization_Type LIKE '%Local%'" );
	
    if ($local) {
	    my $count_local_org = $dbc -> Table_find('Organization','Organization_ID','WHERE Organization_Type LIKE "%Local%"');
		if ($count_local_org > 1) {
			Message "A local organization already exists!";
			return;
		}
		else {return 1}
	}
	else{
		return 1;
	}
	
	return;
}

#########################################################################
# Script to run whenever a new Organization record is added to the database
#
###########################
sub get_Local_organization {
###########################
	my $self 	= shift;
    my %args 	= &filter_input(\@_,);
    my $return  = $args{-return} || 'id';                  # enum (name, id)
    my $dbc 	= $self -> {dbc} || $args{-dbc};
	my $field = 'Organization_' .$return;
	my ($local) 	= $dbc -> Table_find( 'Organization', $field,"WHERE Organization_Type LIKE '%Local%'" );
	return $local;
}

1;
