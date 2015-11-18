package Healthbank::GENIC::Statistics_Views;

use base Healthbank::Statistics_Views;

use strict;
use warnings;

#############
sub stats {
#############
    my $self = shift;
    my $condition = shift || 1;
    
    my $dbc = $self->dbc();

    return $self->SUPER::stats("Plate.FK_Library__Name = 'GENIC'");
}

return 1;
