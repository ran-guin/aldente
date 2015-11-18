###################################################################################################################################
# alDente::Trigger.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package TCGA::Trigger;
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

    my $self = {};    ## if object is NOT a DB_Object

    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;
    return $self;
}

#########################################################################
# Run trigger
#
###########################
sub TCGA_Library_trigger {
###########################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $library_name  = $args{-id};
    my $dbc     = $self->{dbc};
    my $ok;
    
    my ($original_source_name) = $dbc -> Table_find ('Library, Original_Source, Project',"Original_Source_Name","WHERE FK_Original_Source__ID=Original_Source_ID and FK_Project__ID=Project_ID and Project_Name='TCGA' and Library_Name='$library_name'");

    if ($original_source_name) {
        $ok = $dbc-> Table_update_array ('Library',['Library_FullName'],[$original_source_name],"WHERE Library_Name = '$library_name' ", -autoquote => 1);
    }

    return $ok;
}

1;
