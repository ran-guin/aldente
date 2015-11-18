## BioSpecimens department home page, will need to be adjusted according to needs of the group, Department Name, etc.
## Also, see other alDente::<name_of>_Department modules to guide adjusting the access priveledges of the layers
## This one started out as the Cancer_Genetics_Department.pm module

package Biospecimen_Core::Department;

use base alDente::Department;

use strict;
use warnings;
use CGI('standard');
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use Biospecimen_Core::Department_Views;

use vars qw(%Configs);

## Specify the icons that you want to appear in the top bar
my @icons_list
    = qw(Home Protocols Current_Dept Sample_Request Contacts Views Equipment_App Pool_ReArray Rack Pipeline Solutions_App RNA_DNA_Collections Receive_Shipment Export Import Template GSC_Shipments Submission Barcodes Database In_Transit Subscription Custom_Import Summary_App POG GelRun_App AATI_Run_App);
my $icon_class = 'dropnav';    # 'iconmenu';
my $navbar     = 1;            ## flag to turn on / off menu drop menu navigation
if ($navbar) { $icon_class = 'dropnav' }

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    
    my %args       = filter_input( \@_, -args => 'dbc,open_layer' );
    my $dbc        = $args{-dbc} || $self->dbc;
    my $open_layer = $args{-open_layer} || '';

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my $datetime = &date_time;
    my $user     = $dbc->get_local('user_id');

    # This user does not have any permissions on Lab
    if ( !( $Access{'Biospecimen_Core'} || $Access{'LIMS Admin'} ) ) {
        return;
    }
    alDente::Department::set_links($dbc);
    return $self->View->home_page();

}

#
#
#
######################
sub get_greys_and_omits {
######################
    my $self = shift;

    my @greys = qw( Source_Type FK_Plate_Format__ID Source_Status Received_Date FKReceived_Employee__ID FK_Barcode_Label__ID Current_Amount Plate_Type Plate_Content_Type FK_Employee__ID Plate_Created Plate_Status Failed FK_Library__Name);
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
    my $self   = shift;
    my %args   = @_;
    my %Access = %{ $args{-access} } if $args{-access};

    my @creates = sort
        qw(Source_Alert Anatomic_Site BCR_Batch Cell_Line Cell_Line_Type Collaboration Drug Patient Shipment Original_Source Employee Project Drug Contact Organization Project Plate_Format Source Anatomic_Site Pathology Histology Cell_Line Cell_Type Replacement_Source_Reason Sample_Alert_Reason Location Shipment Site Stage Storage_Medium Strain Submission);

    my @searches = sort
        qw(Source_Alert Source Plate Library Anatomic_Site BCR_Batch Cell_Line Cell_Type Collaboration Contact Drug Employee Equipment Histology Location Organization Plate Plate_Format Project Rack Replacement_Source_Reason Site Storage_Medium Strain Source Original_Source Source Patient Shipment Rack Pathology Replacement_Source_Request Source_Alert Stage Strain Submission);

    my @converts = sort qw(Source.External_Identifier Patient.Patient_Identifier Original_Source.Original_Source_Name);

    # Department permissions for searches
    if ( grep( /Lab/, @{ $Access{Biospecimen_Core} } ) ) {
        push( @searches, qw() );
        push( @creates,  qw() );
        push( @converts, qw() );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Biospecimen_Core} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Biospecimen_Core} } ) ) {
        push( @searches, qw(Patient_Treatment) );
        push( @creates,  qw(Patient_Treatment Contact Collaboration Organization Project Transport_Container Pathology Histology Cell_Type Replacement_Source_Request Source_Alert BCR_Batch Stage Strain ) );
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
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{Biospecimen_Core} } ) ) {
        push @icons_list, "Employee";
    }

    return \@icons_list;
}

#####################
sub get_icon_class {
####################
    return $icon_class;
}

return 1;
