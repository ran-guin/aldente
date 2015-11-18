package Prostate_Lab::Department_Views;

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
use SDB::Import;

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
    if ( !( $Access{'Prostate Lab'} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    alDente::Department::set_links($dbc);

    my ( $search_ref, $creates_ref ) = $self->Model->get_searches_and_creates( -access => \%Access );
    my @searches = @$search_ref;
    my @creates  = @$creates_ref;

    my ( $greys_ref, $omits_ref ) = $self->Model->get_greys_and_omits();
    my @grey_fields = @$greys_ref;
    my @omit_fields = @$omits_ref;

    my $grey = join '&Grey=', @grey_fields;
    my $omit = join '&Omit=', @omit_fields;

    my $search_create_box = alDente::Department::search_create_box($dbc, \@searches, \@creates );

    my $extra_links;

    ## Define admin layer
    my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'Prostate_Lab', -form_name => 'Admin_layer' );

    ## Define the layers of the Prostate_Lab Department
    my $layers = {
        "Database"   => $search_create_box . lbr . $extra_links,
        "Admin"      => $admin_table,
        "CLIPR Runs" => CLIPR_runs( -dbc => $dbc ),
        'Labels'     => alDente::Barcoding::barcode_label_form( -dbc => $dbc, -label => 'label1', -preview => 1 ),
        "Upload Plates" => upload_source_and_plate_box( -dbc => $dbc ),
    };

    my @order = ( 'Upload Plates', 'CLIPR Runs', 'Database', 'Labels', 'Admin' );
    return define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );
}

########################################
#
#  Display current list of CLIPR runs and thier status
#
##############################
sub CLIPR_runs {
##############################
    my %args = filter_input( \@_, -args => 'dbc', -mandatory => 'dbc' );
    my $dbc = $args{-dbc};

    my $table = $dbc->Table_retrieve_display(
        "Run,CLIPR_Run,Plate",
        [ 'Run_ID', 'Run_Status', 'Run_DateTime', 'CLIPR_Run_Finished', 'FK_Plate__ID', 'FK_Library__Name' ],
        "WHERE FK_Run__ID = Run_ID AND FK_Plate__ID = Plate_ID ORDER BY Run_ID desc",
        -return_html => 1,
        -title       => 'Current CLIPR Runs',
        -print_link  => 1,
    );

    return $table;
}

########################################
#
#  Display upload box and current list of uploaded plates
#
##############################
sub upload_source_and_plate_box {
##############################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $Iview = new SDB::Import_Views();
    my $view = $Iview->upload_file_box(
        -dbc             => $dbc,
        -cgi_application => 'Prostate_Lab::Department_App',
        -button          => submit( -name => 'rm', -value => 'Upload Plate', -force => 1, -class => 'Action' ),

        #-extra      => [ $extra   ]
        -download => "Prostate_Lab_Source_to_Plate.yml"
    );

    my $table = $dbc->Table_retrieve_display(
        "Plate,Plate_Attribute,Attribute,Source",
        [ 'Plate_ID', 'Plate.FK_Library__Name as Library_Name', 'Plate_Number', 'External_Identifier' ],
        "WHERE Plate.FK_Library__Name = 'PrLab1' AND Plate_ID = Plate.FKOriginal_Plate__ID AND Plate_ID = Plate_Attribute.FK_Plate__ID AND FK_Attribute__ID = Attribute_ID AND Attribute_Name = 'Redefined_Source_For' AND Attribute_Value = Source_ID Order by Plate_Number desc",
        -return_html => 1,
        -title       => 'Uploaded Plates',
        -print_link  => 1,
    );
    $view .= $table;

    return $view;
}

return 1;
