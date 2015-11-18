package TCGA::Department;
use base alDente::Department;

## TCGA department home page, will need to be adjusted according to needs of the group, Department Name, etc.
## Also, see other alDente::<name_of>_Department modules to guide adjusting the access priveledges of the layers
## This one started out as the Cancer_Genetics_Department.pm module

use strict;
use warnings;

use CGI('standard');
use Data::Dumper;
use Benchmark;

use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use TCGA::Department_Views;

use vars qw(%Configs);

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Views Stat_App Contacts Equipment_App Pipeline Receive_Shipment Export Import Template GSC_Shipments Barcodes In_Transit Rack);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args       = filter_input( \@_, -args => 'dbc,open_layer');
    my $dbc        = $args{-dbc} || $self->dbc;
    my $open_layer = $args{-open_layer} || '';

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my $datetime = &date_time;
    my $user     = $dbc->get_local('user_id');

    # This user does not have any permissions on Lab
    if ( !( $Access{'TCGA'} || $Access{'LIMS Admin'} ) ) {
        return;
    }
    alDente::Department::set_links($dbc);

    return $self->View->home_page();

    my ( $search_ref, $creates_ref ) = get_searches_and_creates( -access => \%Access );
    my @searches = @$search_ref;
    my @creates  = @$creates_ref;

    my ( $greys_ref, $omits_ref ) = get_greys_and_omits();
    my @grey_fields = @$greys_ref;
    my @omit_fields = @$omits_ref;

    my $grey = join '&Grey=', @grey_fields;
    my $omit = join '&Omit=', @omit_fields;

    ## Main table
    my $main_table = HTML_Table->new(
        -title    => "Department Home Page",
        -width    => '100%',
        -bgcolour => 'white ',
        -nolink   => 1,
    );

    my $search_create_box = alDente::Department::search_create_box( $dbc, \@searches, \@creates );
    my $extra_links;

    my @order = ();
    ## Define the layers of the Department
    my $layers = { "Database" => $search_create_box . lbr . $extra_links };    ## June 13 - removed Lab, Summaries, and Database options from
    return $self->View->home_page( );

    #define_Layers(-layers=>$layers,
    #		       -tab_width=>100,
    #		       -order=>\@order,
    #                       -default=>$open_layer);
}

#
#
#
######################
sub get_greys_and_omits {
######################

    my @greys = qw( Source_Type FK_Plate_Format__ID Source_Status Received_Date FKReceived_Employee__ID FK_Barcode_Label__ID Current_Amount Plate_Type Plate_Content_Type FK_Employee__ID Plate_Created Plate_Status FK_Library__Name);
    my @omits = qw( Current_Amount FKOriginal_Plate__ID Plate_Content_Type );

    return ( \@greys, \@omits );

}

#
# <snip>
#
# </snip>
###############################
sub get_searches_and_creates {
##############################

    my %args   = @_;
    my %Access = %{ $args{-access} } if $args{-access};

    my @creates  = sort qw(Employee Project Contact Organization Project Plate_Format Source);
    my @searches = sort qw(Original_Source Source Patient Shipment);

    # Department permissions for searches
    if ( grep( /Lab/, @{ $Access{Lab_Department} } ) ) {
        push( @searches, qw(Collaboration Contact Equipment Plate Tube Rack) );
        push( @creates,  qw(Plate Contact Source Equipment Rack) );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Lab} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{'Lab_Department'} } ) ) {
        push( @searches, qw(Employee Organization Contact Rack Tube Rack Plate) );
        push( @creates,  qw(Collaboration Employee Organization Project) );
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

return 1;
