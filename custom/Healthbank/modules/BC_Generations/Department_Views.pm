package Healthbank::BC_Generations::Department_Views;

use base Healthbank::Department_Views;

use strict;
use warnings;
use LampLite::CGI;

use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;
use alDente::Tools;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use LampLite::Bootstrap;

use Healthbank::Model;
use Healthbank::Views;

## Specify the icons that you want to appear in the top bar

my $BS = new Bootstrap();
my $q = new CGI;
########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,open_layer', -self=>'Healthbank::Login_Views');

    my $dbc        = $args{-dbc}  || $self->dbc;
    my $open_layer = $args{-open_layer} || 'Incoming Samples';
    
    ### Permissions ###
    my %Access;
    my $access = $dbc->get_local('Access');
    if ($access) { %Access = %{ $access} }

    my $datetime = &date_time();
    my $user     = $dbc->get_local('user_id');
    
    if ( !( $Access{'Public'} || $Access{'LIMS Admin'} ) ) {
        $dbc->warning('Access level not set');
        return;
    }
    alDente::Department::set_links();

    my ( $search_ref, $creates_ref ) = Healthbank::Model::get_searches_and_creates(-access => \%Access );
    my @searches = @$search_ref;
    my @creates  = @$creates_ref;

    my ( $greys_ref, $omits_ref ) = Healthbank::Model::get_greys_and_omits();
    my @grey_fields = @$greys_ref;
    my @omit_fields = @$omits_ref;

    my $grey = join '&Grey=', @grey_fields;
    my $omit = join '&Omit=', @omit_fields;

    use alDente::Source_App;

    my %layers;

    my $now = date_time();
    my $options = { '1' => 1, '2' => 2, '3' => 3, '4' => 1 };    ## custom numbers of blood/urine collection tubes to print out by default

    if (0) {
        ## turn this off for now...
        $layers{'Blood Collection'} = alDente::Source_Views::receive_Samples(
            -dbc         => $dbc,
            -options     => $options,
            -preset      => { 'Collection_DateTime' => '$now' },
            -rack        => 2,
            -origin      => 1,
            -sample_type => 'Whole Blood',
        );
    }
    
     my $HV = $self->Model(-class=>'Healthbank::Views');

    $layers{'Sample Preparation'} = $HV->sample_prep_page(-dbc=>$dbc);
    $layers{'AC Collection'}      = $HV->sample_prep_page(-dbc=>$dbc, -mobile=>'mobile');
    $layers{'Administration'}     = $HV->_admin_page($dbc, -condition=>"Patient_Identifier like 'BC%'");
    $layers{'Export'}             = $HV->_export_page($dbc);
    $layers{'Search'}             = $HV->_search_page($dbc, -url_condition => 'FK_Project__ID=1' );
    $layers{'In Transit'}         = alDente::Rack_Views::in_transit($dbc);

    my $page = define_Layers(
        -layers    => \%layers,
        -order     => [ 'AC Collection', 'Sample Preparation', 'Search', 'Export', 'Administration', 'In Transit' ],
        -tab_width => 100,
        -default   => 'Sample Preparation',
    );
  
    if ($q->param('rm') eq 'Log In') {
        ## only prompt to reset printer group when first logging in ##
        my $printer_group = "Default Printer Group at Login: <B>" 
            . $dbc->session->user_setting('PRINTER_GROUP') 
            . Link_To($dbc->homelink, ' [Change / Check Printer Settings]', '&cgi_app=alDente::Barcode_App&rm=Change Printer Group')
            . '</B><hr>';
        print $printer_group;
    }
    
    print $page;
    return;

    my @links;
    my @content_types = qw( Blood Plasma Serum Saliva );    ## Urine);
    my $type;
    my ($srclabel) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Barcode_Label_Name = 'src_no_barcode'" );
    my @rackids = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Type = 'Box'" );
    my $defaultrack = 1;
    foreach my $rack (@rackids) {
        if ( $rack > $defaultrack ) { $defaultrack = $rack; }
    }

## Set source fields
    my $set = '';
    $set .= "&FKReceived_Employee__ID=$user";
    $set .= "&Source_Status=Active";
    $set .= "&Received_Date=$datetime";
    $set .= "&FK_Barcode_Label__ID=$srclabel";
    $set .= "&FK_Plate_Format__ID=Tube";
    $set .= "&FK_Original_Source__ID=1";
    $set .= "&FK_Library__Name='BM08'";
    $set .= "&FK_Rack__ID=$defaultrack";

## Set plate fields
    my $plateset = '';
    $plateset .= "&Plate_Created=$datetime";
    $plateset .= "&FK_Employee__ID=$user";
    $plateset .= "&Plate_Type=Tube";
    $plateset .= "&Plate_Status=Active";

    my $extra;

    my $output;
    $output .= "<h2>Healthbank Samples</h2>";
    $output .= '<hr>';

    foreach $type (@content_types) {
        my $label = "<img src='/" . $dbc->config('$URL_dir_name') . "/images/png/$type.png'/><BR>" . "$type";

        my ($type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$type'" );
        $plateset .= "&FK_Sample_Type__ID=$type_id";

        if ( $type eq 'Blood' || $type eq 'Saliva' ) {
            push( @links, &Link_To( $homelink, $label, "&New+Entry=New+Source&Plate_Content_Type=$type$set$plateset&Grey=$grey&Omit=$omit&FK_Sample_Type__ID=$type_id" ) );
        }
        elsif ( $type eq 'Plasma' || $type eq 'Serum' ) {
            push( @links, &Link_To( $homelink, $label, "&Database=healthbank&cgi_application=Healthbank::Statistics_App&rm=Display+Patient+Info&Original+Samples+Only=1" ) );
        }

    }

## Main table
    my $main_table = HTML_Table->new(
        -title    => "Healtbank Home Page",
        -width    => '100%',
        -bgcolour => 'white ',
        -nolink   => 1,
    );

    my $centre = HTML_Table->new( -align => 'center ', -width => '100%' );
    $centre->Set_Row( [ "<B>Click on a new sample to define: <B>", @links ] );
    $output .= $centre->Printout(0);

### Solution Section
    my $solution = alDente::Department::solution_box( -choices => [ ( 'Find Stock', 'Search Solution', 'Show Applications' ) ] );

### Equipment Section
    my $equip = alDente::Department::equipment_box( -choices => [ ( '--Select--', 'Maintenance ', 'Maintenance History ' ) ] );

## Prep, Protocol, Pipeline summaries

    my $views         = alDente::Department::latest_runs_box();
    my $summaries_box = alDente::Department::prep_summary_box();
    my $view_summary  = alDente::Department::view_summary_box();

    my $extra_links = '';

## Plates Section
    my %labels;
    $labels{'-'}           = '--Select--';
    $labels{'Plate Set'}   = 'Grab Plate Set ';
    $labels{'Recover Set'} = 'Recover Plate Set ';

    my $plates_box;
    if ( grep( /Lab|Bioinformatics/, @{ $Access{'Healthbank'} } ) ) {
        $plates_box = alDente::Department::plates_box(
            -type            => 'Library_Plate',
            -id_choices      => [ '-', 'View Ancestry', 'Plate History', ],
            -access          => $Access{'Healthbank'},
            -include_rearray => 0,
            -labels          => \%labels
        );
    }    # June 5 - removed -id_choices 'Recover Set','Select No Grows', 'Select Slow Grows', 'Select Unused Wells', 'Plate Set'

## Lab Layer
    $main_table->Set_Row( [ $plates_box . $solution . $equip ] );

    my $search_create_box = alDente::Department::search_create_box( \@searches, \@creates );

    my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Healthbank')" );

    my $project_list = &alDente::Project::list_projects("Library_Name IN ('$libs')");
    $main_table->Toggle_Colour('off');
    $main_table->Set_Column_Widths( [ '50%', '50%' ] );
    $main_table->Set_VAlignment('top');

    my $lab_layer = $main_table->Printout( -filename => 0 );
    my @order = ( 'Projects', 'Incoming Samples', 'Lab', 'Summaries', 'Database' );

## Define the layers of the Healthbank Department
    my $layers = {
        "Incoming Samples" => $output,
        "Database"         => $search_create_box . lbr . $extra_links
    };    ## June 13 - removed Lab, Summaries, and Database options from

## Define admin layer
    my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'Healthbank', -form_name => 'Admin_layer' );
    if ( grep( /Admin/i, @{ $Access{'Cancer Genetics'} } ) ) {
        push( @order, 'Admin' );
        $layers->{"Admin"} = $admin_table;
    }


    my $printer_group = "Current Printer Group: " . $dbc->config('PRINTER_GROUP');

    my $show_layers = define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );

    return $printer_group . $show_layers;
}


return 1;
