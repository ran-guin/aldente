###################################################################################################################################
# LampLite::Help.pm
#
# Model in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package LampLite::Help;

use strict;

use RGTools::RGIO;   ## include standard tools

################/default#####
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_, -args => 'name' );

    my $dbc  = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    $self->{dbc} = $dbc;
    
    return $self;
}

1;


