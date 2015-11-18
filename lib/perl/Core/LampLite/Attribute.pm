###################################################################################################################################
# LampLite::Attribute.pm
#
# Model in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package LampLite::Attribute;

use base LampLite::DB_Object;
use strict;

use RGTools::RGIO;   ## include standard tools

##################
sub new {
##################
#
# Constructor of the object
#
    my $this = shift;
    my $class = ref($this) || $this; 
    my %args = filter_input(\@_);
    
    $args{-table} = 'Attribute';
    my $self = $this->SUPER::new(%args);

    bless $self, $class;
    
    return $self;
}

1;


