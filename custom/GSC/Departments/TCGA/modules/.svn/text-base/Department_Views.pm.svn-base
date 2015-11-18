package TCGA::Department_Views;

use base alDente::Department_Views;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use vars qw(%Configs);

## Specify the icons that you want to appear in the top bar

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,open_layer');
    my $dbc = $args{-dbc} || $self->dbc;

    my $open_layer = $args{-open_layer};

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my $datetime = &date_time;
    my $user     = $dbc->get_local('user_id');

    # This user does not have any permissions on Department
    if ( !( $Access{'TCGA'} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    alDente::Department::set_links($dbc);

    my ( $search_ref, $creates_ref, $custom ) = $self->Model->get_searches_and_creates( -access => \%Access );
    my @searches = @$search_ref;
    my @creates  = @$creates_ref;

    my ( $greys_ref, $omits_ref ) = $self->Model->get_greys_and_omits();
    my @grey_fields = @$greys_ref;
    my @omit_fields = @$omits_ref;

    my $grey = join '&Grey=', @grey_fields;
    my $omit = join '&Omit=', @omit_fields;

    my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'TCGA' );

#    my $sample_search = '<h2>Search for DB Sample records:</h2>';
#    foreach my $type ( 'Plate', 'Source', 'Library' ) {
#        $sample_search .= '<p ></p>' . Link_To( $homelink, "$type records", "&cgi_application=SDB::DB_Object_App&rm=Search Records&Table=$type" );
#    }



    ## Define the layers of the TCGA Department
    my $layers = {
        'TCGA Samples' => TCGA_samples( -dbc => $dbc ),
        'Admin'        => $admin_table,
#        "Summaries"    => $sample_search 
    };
    my @order = ( 'TCGA Samples', 'Database', 'Summaries', 'In Transit' );
    if ( grep( /Admin/, @{ $Access{TCGA} } ) ) {
        push( @order, 'Admin' );
    }
    return define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );
}

#####################
sub TCGA_samples {
#####################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my ($batch_attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Source' AND Attribute_Name = 'BCR_Batch'" );
    my $table = $dbc->Table_retrieve_display(
        "Source,Original_Source, Shipment LEFT JOIN Source_Attribute AS Batch ON Batch.FK_Source__ID=Source_ID AND Batch.FK_Attribute__ID= $batch_attribute LEFT JOIN BCR_Batch ON Batch.Attribute_Value=BCR_Batch_ID",
        [   'Shipment_ID as Shipment',
            'BCR_Batch.FKSupplier_Organization__ID AS Supplier',
            'Received_Date',
            'BCR_Batch_ID as BCR_Batch',
            'Count(Distinct Source_ID) as Sources',
            'Count(Distinct Original_Source_ID) as Specimens',
            'Count(Distinct Mid(External_Identifier,22,4)) as Plates',
            'Min(Original_Source_Name) as First_Sample',
            'Max(Original_Source_Name) as Last_Sample'
        ],
        "WHERE External_Identifier LIKE 'TCGA%' AND FK_Shipment__ID=Shipment_ID AND FK_Original_Source__ID=Original_Source_ID GROUP BY Shipment_ID, BCR_Batch_ID ORDER BY Shipment_ID",
        -return_html   => 1,
        -title         => 'Current Samples Tracked with Patient_ID reference',
        -total_columns => 'Samples,Sources,Specimens',
        -print_link    => 1,
    );

    return $table;
}

return 1;
