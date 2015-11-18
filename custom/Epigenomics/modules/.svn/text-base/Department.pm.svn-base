## Epigenomics department home page, will need to be adjusted according to needs of the group, Department Name, etc.
## Also, see other alDente::<name_of>_Department modules to guide adjusting the access priveledges of the layers
## This one started out as the Cancer_Genetics_Department.pm module

package Epigenomics::Department;

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
use Epigenomics::Department_Views;

use vars qw(%Configs);

## Specify the icons that you want to appear in the top bar
#my @icons_list = qw( Export Shipments In_Transit Rack Contacts Database );
my @icons_list = qw(Home Current_Dept Views Solutions_App Equipment_App Rack Tubes Pool_ReArray  Sources Export Import Template Shipments Contacts In_Transit Database Solexa_Summary_App);
my $icon_class = 'dropnav';                                                                                                                                                  # 'iconmenu';

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
    if ( !( $Access{'Epigenomics'} || $Access{'LIMS Admin'} ) ) {
        return;
    }
    alDente::Department::set_links($dbc);
    return Epigenomics::Department_Views::home_page( -dbc => $dbc );
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
#<snip>
#
#</snip>
##################
sub get_searches_and_creates {
##################

    my %args   = @_;
    my %Access = %{ $args{-access} };

    my @creates  = ();
    my @searches = ();
    my @converts;

    # Department permissions for searches
    if ( grep( /Lab/, @{ $Access{Epigenomics} } ) ) {
        push( @searches, qw(Collaboration Contact RNA_DNA_Collection Equipment Library Library_Plate Plate Plate_Format Source Solution Stock Study Tube) );
        push( @creates,  qw(Plate Contact Study) );
        push( @converts, qw() );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Epigenomics} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Epigenomics} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Original_Source Project Rack Original_Source Stock_Catalog) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Organization Plate_Format Project Stock_Catalog) );
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
    if ( grep( /Admin/, @{ $Access{Epigenomics} } ) ) {
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
