package Healthbank::GENIC::Department;
use base Healthbank::Department;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use vars qw(%Configs $Connection);
use Healthbank::GENIC::Department_Views;

## Specify the icons that you want to appear in the top bar

my @icons_list = qw( Home BCG_Help BCG_Summary Receive_Shipment Onyx Rack Export Contacts Pipeline Import Template Pool_ReArray Pool_ReArray_to_Tube Views);

########################################
sub home_page {
#################
    my $self = shift;
    my %args = filter_input( \@_ );
    return $self->View->home_page(%args);
}

#
#
######################
sub get_greys_and_omits {
######################

    my @greys = qw( FK_Sample_Type__ID FK_Plate_Format__ID Source_Status Received_Date FKReceived_Employee__ID FK_Barcode_Label__ID Current_Amount Plate_Type Plate_Content_Type FK_Employee__ID Plate_Created Plate_Status FK_Library__Name);
    my @omits = qw( Current_Amount FKOriginal_Plate__ID Plate_Content_Type );

    return ( \@greys, \@omits );

}

#
#<snip>
#
#</snip>
###################################
sub get_searches_and_creates {
###################################

    my %args   = @_;
    my %Access = %{ $args{-access} };

    my @creates  = ();
    my @searches = ();

    # BC_Generations permissions for searches
    if ( grep( /GENIC/, @{ $Access{GENIC} } ) ) {
        push( @searches, qw(Collaboration Contact Equipment Plate Tube Rack) );
        push( @creates,  qw(Plate Contact Source Equipment Rack Patient) );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Lab} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{'GENIC'} } ) ) {
        push( @searches, qw(Employee Organization Contact Rack Tube Rack Plate) );
        push( @creates,  qw(Collaboration Employee Organization Project Patient) );
    }
    @creates  = sort @{ unique_items( [ sort(@creates) ] ) };
    @searches = sort @{ unique_items( [ sort(@searches) ] ) };

    return ( \@searches, \@creates );

}

########################################
#
# Accessor function for the icons list
#
####################
sub get_icons {
####################

    return \@icons_list;
}

#######################
sub get_custom_icons {
#######################
    my %images;

    use Healthbank::Model;
    my $base_images = Healthbank::Model::get_custom_icons();
    if ($base_images) { %images = %$base_images }

    $images{GENIC_Summary}{icon} = "Daily_Planner.png";
#    $images{GENIC_Summary}{url}  = "cgi_application=Healthbank::GENIC::Statistics_App";
    $images{GENIC_Summary}{url}  = "&cgi_application=Healthbank::App&rm=Summary&Prefix=SHE";
    $images{GENIC_Summary}{name} = "GENIC Summary";
    $images{GENIC_Summary}{tip}  = "Public Summary of GENIC Lab Data";

    return \%images;
}

1;

