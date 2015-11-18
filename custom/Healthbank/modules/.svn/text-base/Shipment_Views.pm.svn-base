###################################################################################################################################
# Healthbank::Shipment_Views.pm
#
# View in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package Healthbank::Shipment_Views;

use base alDente::Shipment_Views;
use strict;
use Healthbank::Shipment;

my $q = new LampLite::CGI;

use RGTools::RGIO;   ## include standard tools


####################
sub import_Layers {
####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $id   = $args{-id};
    my $dbc  = $args{-dbc} || $self->{dbc};

    my ($layers, $order, $default) = $self->SUPER::import_Layers(%args);
    
    require Healthbank::Views;

    my $include = $q->hidden( -name => 'Shipment_ID', -value => $id, -force => 1 ) . '<P>Define New Source Material Records: <BR>';
    
    $layers->{'Link to Onyx Barcodes'} = Healthbank::Views::link_shipment_to_onyx_tubes($dbc, -include=>$include);

    push @$order, 'Link to Onyx Barcodes';
    $default = 'Link to Onyx Barcodes';
    
    return ($layers, $order, $default);
}

1;

