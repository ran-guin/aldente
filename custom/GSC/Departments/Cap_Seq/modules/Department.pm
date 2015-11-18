package Cap_Seq::Department;

use base alDente::Department;

use strict;
use warnings;

use CGI qw(:standard);
use Data::Dumper;

use alDente::Department;
use Sequencing::Sequencing_Library;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use SDB::DBIO;
use alDente::Validation;

## Specify the icons that you want to appear in the top bar

## removed Admin icon (included as layer in main department page)
## (removed Sample_Sheets - this page should not be necessary - functionality exists more appropriately elsewhere)

my @icons_list = qw(Last_24h Daily_Planner Views Database Solutions_App Equipment_App Rack Plates Rearrays Libraries Sources Dept_Projects Pipeline
    Shipments Barcodes Seq_Stat Solexa_Summary_App Solid_Summary_App Template Import Export Contacts Shipments In_Transit RNA_DNA_Collections Subscription);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,open_layer' );
    my $dbc        = $args{-dbc}        || $self->dbc;
    my $open_layer = $args{-open_layer} || 'Lab';

    $dbc->Benchmark('Cap_Seq_home_page');

    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };

    #This user does not have any permissions on Sequencing
    if ( !( $Access{Cap_Seq} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    #  alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    $dbc->Benchmark('SD_set_links');

    #Lab permissions for searches
    if ( grep( /Lab/, @{ $Access{Cap_Seq} } ) ) {

        push( @searches, qw(Collaboration Contact Equipment Library_Plate Order_Notice Plate Plate_Format PCR_Product_Library Sequence Solution Stock Tube Vector_Based_Library Vector_Type Attribute) );
        push( @creates,  qw(Plate Contact) );
    }

    #Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Cap_Seq} } ) ) {
        push( @searches, qw(Study Library) );
        push( @creates,  qw(Study) );
    }

    #Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Cap_Seq} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Primer Project Rack Stock_Catalog) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Order_Notice Organization Plate_Format Project Stock_Catalog Vector_Type Transposon Process_Deviation) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    #  my $main_table = HTML_Table->new(-title=>"Sequencing Home Page",
    #				   -width=>'100%' , -border=>0, -padding=>10, -bgcolour=>'white');

    ###Plates Section
    my @id_choices;

    push( @id_choices, 'View Ancestry' );
    push( @id_choices, 'Plate History' );
    push( @id_choices, 'Delete' );
    push( @id_choices, 'Fail Plates' ), push( @id_choices, 'Fail and Throw Out Plates' ), push @id_choices, 'Throw Out Plates';
    push( @id_choices, 'Annotate' );
    push( @id_choices, 'Set No Grows' );
    push( @id_choices, 'Set Slow Grows' );
    push( @id_choices, 'Set Unused Wells' );
    push( @id_choices, 'Set Empty Wells' );
    push( @id_choices, 'Set Problematic Wells' );
    push( @id_choices, 'Re-Print Plate Labels' );

    # ??  push(@id_choices,'Library_Plate_Option_btn');

    my %labels;
    $labels{'-'}                        = '--Select--';
    $labels{'Library_Plate_Option_btn'} = 'Set Well Growth Status';

    my ( $plates, $seq_request, $solution, $equip );
    $dbc->Benchmark('pre_plates_box');

    #  use alDente::Container_App;
    use alDente::Container_Views;
    if ( grep( /Lab|Bioinformatics/, @{ $Access{Cap_Seq} } ) ) {

        #      my $plate_app = new alDente::Container_App(PARAMS => {dbc => $dbc});
        $plates = alDente::Container_Views::plates_box(
            -dbc             => $dbc,
            -type            => 'Library_Plate',
            -id_choices      => \@id_choices,
            -access          => $Access{Cap_Seq},
            -labels          => \%labels,
            -include_rearray => 1
        );
    }
    $dbc->Benchmark('plate_box');

    if ( grep( /Lab/, @{ $Access{Cap_Seq} } ) ) {
        ###Run Requests Section
        $seq_request = alDente::Department::seq_request_box( $dbc, -choices => [ ( 'Remove Run Request', 'Mark Failed Runs', 'Annotate Run Comments' ) ] );

        ###Solution Section
        $solution = alDente::Department::solution_box(
            -choices => [ ( 'Find Stock', 'Search Solution', 'Show Applications' ) ],
            -dbc => $dbc
        );

        ###Equipment Section
        $equip = alDente::Department::equipment_box( $dbc, -choices => [ ( '--Select--', 'Maintenance', 'Maintenance History', 'Sequencer Status' ) ] );
    }
    $dbc->Benchmark('SD_sol_equ_box');

    ###Views Section (Run summaries)
    eval "require SequenceRun::Run_Views";
    my $views = SequenceRun::Run_Views->latest_Cap_Seq_runs_box(-dbc=>$dbc);

    $dbc->Benchmark('CS_latest_runs');
    my $reports = alDente::Department::prep_summary_box( -dbc => $dbc );
    $dbc->Benchmark('CS_prep_summ');

    my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'Cap_Seq' );
    $dbc->Benchmark('CS_admin');

    #  $main_table->Set_Row([$plates.$solution.$equip.$seq_request,
    #			alDente::Department::search_create_box($dbc, \@searches,\@creates).
    #			lbr.$views.$reports]);

    my $groups = Cast_List( -list => $dbc->get_local('groups'), -to => 'string', -autoquote => 1 );

    $dbc->Benchmark('SD_admin');

    #    my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Sequencing','Public') AND Grp_Name IN ($groups)" );
    $dbc->Benchmark('SD_libs_ok');

    #    my $projects = &alDente::Project::list_projects( $dbc, "Library_Name IN ('$libs')" );
    $dbc->Benchmark('SD_proj_ok');
    #    my $dbase_options = alDente::Department::search_create_box( $dbc, \@searches, \@creates );
    $dbc->Benchmark('SD_dbase_ok');
    my $layers = {

        #        "Projects"   => $projects,
        "Lab"       => $plates . $solution . $equip . $seq_request,
    #    "Database"  => $dbase_options,
        "Summaries" => $views . $reports,
    };

    $dbc->Benchmark('SD_built_layers');
    my @order = qw(Projects Lab Database Summaries);
    if ( grep( /Admin/, @{ $Access{Cap_Seq} } ) ) {
        require alDente::Rack_Views;
        push( @order, 'Admin', 'In Transit' );
        $layers->{"Admin"} = $admin_table;
        $layers->{'In Transit'} = alDente::Rack_Views::in_transit( -dbc => $dbc ),;
    }
    $dbc->Benchmark('SD_lib_main');
    my $lib = new Sequencing::Sequencing_Library( -dbc => $dbc );
    my $library_layers = $lib->library_main( -form_name => 'Admin_layer', -get_layers => 'Library Options' );
    $dbc->Benchmark('lib_layers');
    if ( defined %$library_layers ) {
        foreach my $key ( keys %$library_layers ) {
            $layers->{"$key"} = $library_layers->{$key};
            push( @order, "$key" );
        }
    }
    elsif ($library_layers) { return; }    ## returns 1 if generating a page of its own ...

    #  $output .= &Views::Table_Print(content=>[[$lib->library_main($form_name)]],print=>0);

    #  $main_table->Toggle_Colour('off');
    #  $main_table->Set_Column_Widths(['50%','50%']);

    $dbc->Benchmark('SD_home_end');
    my $output = &define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );

    return $output;
}

#
# <snip>
#
# </snip>
###############################
sub get_searches_and_creates {
##############################
    my %args   = filter_input(\@_, -self=>'Cap_Seq::Department');   ## must include self argument to enable to be called as either function or method ##
    my %Access = %{ $args{-access} };

    my @creates;
    my @searches;
    my @converts;

    #Lab permissions for searches
    if ( grep( /Lab/, @{ $Access{Cap_Seq} } ) ) {

        push( @searches, qw(Collaboration Contact Equipment Library_Plate Order_Notice Plate Plate_Format PCR_Product_Library Sequence Solution Stock Tube Vector_Based_Library Vector_Type Attribute) );
        push( @creates,  qw(Plate Contact) );
    }

    #Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Cap_Seq} } ) ) {
        push( @searches, qw(Study Library) );
        push( @creates,  qw(Study) );
    }

    #Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Cap_Seq} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Primer Project Rack Stock_Catalog) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Order_Notice Organization Plate_Format Project Stock_Catalog Vector_Type Transposon Process_Deviation) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    return ( \@searches, \@creates, \@converts );

}

########################################
#
# Accessor function for the icons list
####################
sub get_icons {
####################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{Cap_Seq} } ) ) {
        push @icons_list, "Submission";
        push @icons_list, "Employee";
    }

    return \@icons_list;
}
########################################
#
#
####################
sub get_custom_icons {
####################
    my %images;

    return \%images;

}
return 1;
