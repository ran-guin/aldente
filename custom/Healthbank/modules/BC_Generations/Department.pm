package Healthbank::BC_Generations::Department;
use base Healthbank::Department;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use Healthbank::Healthbank::BC_Generations::Department_Views;

## Specify the icons that you want to appear in the top bar

my @icons_list = qw(Dept_Help Equipment_App Sources Healthbank_Summary Healthbank_Statistics Summary Statistics Dept_Summary Dept_Statistics Rack Receive_Shipment Export Contacts Views Pipeline Onyx Shipments JIRA);

################
sub home_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    
    return $self->View->home_page(%args);
}

#
#
######################
sub get_greys_and_omits {
######################
    my $self = shift;

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
    my $self = shift;
    my %args   = @_;
    my $access = $args{-access};
    my %Access = %{ $access } if $access;

    my @creates  = ();
    my @searches = ();
    
    my @converts = sort qw(Source.External_Identifier Patient.Patient_Identifier Original_Source.Original_Source_Name);

    # BC_Generations permissions for searches
    if ( grep( /BC_Generations/, @{ $Access{BC_Generations} } ) ) {
        push( @searches, qw(Collaboration Contact Equipment Plate Tube Rack) );
        push( @creates,  qw(Plate Contact Source Equipment Rack Patient) );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Lab} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{'BC_Generations'} } ) ) {
        push( @searches, qw(Employee Organization Contact Rack Tube Rack Plate) );
        push( @creates,  qw(Collaboration Employee Organization Project Patient) );
    }
    @creates  = sort @{ unique_items( [ sort(@creates) ] ) };
    @searches = sort @{ unique_items( [ sort(@searches) ] ) };
    @converts = sort @{ unique_items( [ sort(@converts) ] ) };

    return ( \@searches, \@creates, \@converts );

}

########################################
#
# Accessor function for the icons list
#
####################
sub get_icons {
####################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{'BC_Generations'} } ) ) {
        push @icons_list, "Submission";
    }
    return \@icons_list;
}

#######################
sub get_custom_icons {
#######################
    my %images;

    use Healthbank::Model;
    my $base_images = Healthbank::Model::get_custom_icons();
    if ($base_images) { %images = %$base_images }

    $images{BC_Generations_Summary}{icon} = "Daily_Planner.png";
    $images{BC_Generations_Summary}{url}  = "cgi_application=Healthbank::App&rm=Summary&Prefix=BC";
    $images{BC_Generations_Summary}{name} = "BCG Summary";
    $images{BC_Generations_Summary}{tip}  = "Public Summary of BCG Lab Data";

             
    return \%images;
}

1;

