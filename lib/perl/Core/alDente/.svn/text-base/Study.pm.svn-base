###################################################################################################################################
# Study.pm
#
# Model in the MVC structure
#
# 
###################################################################################################################################
package alDente::Study;
use base SDB::DB_Object;

use strict;

## Standard modules ##
use CGI qw(:standard);

## SDB modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RGTools ##
use RGTools::RGIO;
#use RGTools::Views;

use vars qw( %Configs );

####################
sub new {
####################	
    my $this  = shift;
    my %args  = filter_input( \@_, -args => 'dbc,id', -mandatory => 'dbc' );
    my $dbc   = $args{-dbc};
    my $id		= $args{-id} || $args{-study_id};

    my $self  = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Study' );
    $self->{'dbc'} = $dbc;
    
    my ($class) = ref $this || $this;
    bless $self, $class;
	
	if( $id ) {
		$self->{id} = $id;
		$self->primary_value( -table => 'Study', -value => $id );
		$self->load_object();
	}
	
    return $self;
}


#######################################
# Get all libraries for a given study
# Returns an array of libraries
#######################################
sub get_libraries {
    my %args = @_;

    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);    # Database handle
    my $study_id   = $args{-study_id};              # Specify a study by ID
    my $study_name = $args{-study_name};            # Specify a study by name

    my $condition;
    if ( $study_id && $study_id =~ /^\d$/ ) { $condition = "AND Study_ID = $study_id" }
    elsif ($study_name) { $condition = "AND Study_Name = '$study_name'" }
    else                { return "Please provide a valid Study ID or Study Name.\n" }

    my @by_libraries = $dbc->Table_find_array( 'Study,LibraryStudy', ['FK_Library__Name'], "where Study_ID=FK_Study__ID $condition" );
    my @by_projects = $dbc->Table_find_array( 'Study,ProjectStudy,Project,Library', ['Library_Name'], "where Study_ID=FK_Study__ID and Project_ID=ProjectStudy.FK_Project__ID and Project_ID=Library.FK_Project__ID $condition" );

    my @all_libraries = @{ union( \@by_libraries, \@by_projects ) };
    unless ( @all_libraries > 0 ) { @all_libraries = ('0') }

    return @all_libraries;
}
sub get_genome_for_study {
    my %args = @_;
    my $dbc = $args{-dbc};
    my $id = $args{-id};

    if ($id) {

        my ($genome) = $dbc->Table_find('Study,Study_Attribute,Attribute', 'Attribute_Value', "WHERE Study_Attribute.FK_Study__ID = Study_ID and Study_Attribute.FK_Attribute__ID = Attribute_ID and Study_ID = $id and Attribute_Name = 'FK_Genome__ID' and Attribute_Class = 'Study'");
        return $genome;
    }
    return 0;
}

sub create_study_record {
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc,fields,values', -mandatory => 'fields,values' );
    my $dbc        = $args{-dbc} || $self->{'dbc'};
	my $fields = $args{-fields};
	my $values = $args{-values};
	
	my $new_study_id = $dbc->Table_append_array(
						-dbc=> $dbc,
						-table => 'Study',
						-fields => $fields,
						-values => $values,
						-autoquote=>1,
	); 
	return $new_study_id;
}

sub set_attribute {
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc,study_id,attribute_name,attribute_id,value', -mandatory => 'study_id,value' );
    my $study_id = $args{-study_id};
    my $attribute_name = $args{-attribute_name};
    my $attribute_id = $args{-attribute_id};
    my $value = $args{-value};
    my $dbc        = $args{-dbc} || $self->{'dbc'};
	
	if( !$attribute_id && $attribute_name ) {
		( $attribute_id ) = $dbc->Table_find(
		    		-table => 'Attribute', 
		    		-fields => 'Attribute_ID', 
		    		-condition => " WHERE Attribute_Name = '$attribute_name' and Attribute_Class = 'Study' ",
		    		-distinct => 1
		);
	}
	my $datetime = date_time();
	my $user_id = $dbc->get_local('user_id');

	my @fields = ( 'FK_Study__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' );
	my @values = ( $study_id, $attribute_id, $value, $user_id, $datetime );
	my $new_id = $dbc->Table_append_array(
						-dbc=> $dbc,
						-table => 'Study_Attribute',
						-fields => \@fields,
						-values => \@values,
						-autoquote=>1,
	); 
	return $new_id;
}

sub link_to_library {
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc,study_id,library_name', -mandatory => 'study_id,library_name' );
    my $study_id = $args{-study_id};
    my $library_name = $args{-library_name};
    my $dbc        = $args{-dbc} || $self->{'dbc'};
	
	my @fields = ( 'FK_Library__Name', 'FK_Study__ID' );
	my @values = ( $library_name, $study_id );
	my $new_id = $dbc->Table_append_array(
						-dbc=> $dbc,
						-table => 'LibraryStudy',
						-fields => \@fields,
						-values => \@values,
						-autoquote=>1,
	); 
	return $new_id;
}

return 1;
