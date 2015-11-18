package Instrumentation::Department_Views;

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
    if ( !( $Access{'Instrumentation'} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    alDente::Department::set_links($dbc);

    my ( $search_ref, $creates_ref, $custom ) = Instrumentation::Department::get_searches_and_creates( -access => \%Access );
    my @searches = @$search_ref;
    my @creates  = @$creates_ref;

    my ( $greys_ref, $omits_ref ) = Instrumentation::Department::get_greys_and_omits();
    my @grey_fields = @$greys_ref;
    my @omit_fields = @$omits_ref;

    my $grey = join '&Grey=', @grey_fields;
    my $omit = join '&Omit=', @omit_fields;

    my $extra_links;
    my $search_create_box = alDente::Department::search_create_box($dbc, \@searches, \@creates, $custom );
    my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'Instrumentation' );
    my $view_summary = alDente::Department::view_summary_box(-dbc => $dbc);
    my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Instrumentation','Public')" );


    ## Define the layers of the BioSpecimens Department
    my $layers = {
        "Database"   => $search_create_box . lbr . $extra_links,
        'Admin'      => $admin_table,
        "Summaries"  => $view_summary,
        'In Transit' => alDente::Rack_Views::in_transit($dbc),
        "Projects"  => &alDente::Project::list_projects( $dbc, "Library_Name IN ('$libs')" ),
        
    };
    my @order = ( 'Database', 'Summaries', 'In Transit' , 'Projects');
    if ( grep( /Admin/, @{ $Access{Instrumentation} } ) ) {
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
sub recent_shipments {
#####################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $last_month = substr( date_time( -offset => '-30d' ), 0, 10 );

    my $table = $dbc->Table_retrieve_display(
        "Shipment LEFT JOIN Source ON FK_Shipment__ID = Shipment_ID LEFT JOIN Original_Source ON FK_Original_Source__ID=Original_Source_ID 
                LEFT JOIN Anatomic_Site ON FK_Anatomic_Site__ID=Anatomic_Site_ID ",
        [   'Shipment_ID as Shipment',
            'Shipment_Type',
            'Shipment.FKSupplier_Organization__ID as Supplier',
            'Shipment_Sent',
            'Shipment_Received',
            'FKFrom_Grp__ID as From_Group',
            'FKTarget_Grp__ID as To_Group',
            'FK_Sample_Type__ID',
            'Count(Distinct Source_ID) as Sources',
            'Count(Distinct Original_Source_ID) as Specimens',
            'Min(Original_Source_Name) as First_Sample',
            'Max(Original_Source_Name) as Last_Sample',
            'GROUP_CONCAT(DISTINCT Anatomic_Site_Alias) as Tissues'
        ],
        "WHERE 1 AND Shipment_Sent > '$last_month'
					GROUP BY Shipment_ID  
					ORDER BY Shipment_ID DESC",
        -return_html   => 1,
        -title         => 'Shipments for the last 30 days',
        -total_columns => 'Samples,Sources,Specimens',
        -print_link    => 1,
    );

    return $table;
}

return 1;
