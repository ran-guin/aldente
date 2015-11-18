###################################################################################################################################
# Sequencing::Template.pm
#
# Model in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package UTM::Template;

use strict;

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input(\@_);
    my $dbc = $args{-dbc};
    
    my $self = {};

    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;
 
    return $self;
}

sub get_template_data {
    my $self = shift;
    my $data;
    
    ## Retrieve the raw data;
    
    ## $data = $self->{dbc}->Table_retrieve();
    $data = "Hello world";
    return $data;
}

sub set_template_data {
    my $self = shift;
    my $updated;
    
    ## do the action on the model data
    
    return $updated;
}
1;
