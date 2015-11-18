package alDente::Lab_Department;

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

#use Mapping::Mapping_Summary;

use vars qw($Connection);

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Plates Solutions Equipment Libraries Sources Pipeline Contacts);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my %args = filter_input( \@_, -args => 'dbc,open_layer', -mandatory => 'dbc' );
    my $dbc        = $args{-dbc}        || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $open_layer = $args{-open_layer} || 'Projects';

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    # This user does not have any permissions on Lab
    if ( !( $Access{Lab} || $Access{'LIMS Admin'} ) ) {
        return;
    }
    alDente::Department::set_links();

    my @searches;
    my @creates;

    # Lab permissions for searches
    if ( grep( /Lab/, @{ $Access{Lab} } ) ) {
        push( @searches, qw(Collaboration Contact Equipment Library_Plate Plate Plate_Format Run Solution Stock Tube Vector_Type) );
        push( @creates,  qw(Plate Contact Source) );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Lab} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Lab} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Primer Project Rack) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Organization Plate_Format Project Rack Study) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    my $main_table = HTML_Table->new(
        -title    => "Lab Home Page",
        -width    => '100%',
        -bgcolour => 'white',
        -nolink   => 1,
    );

    ### Solution Section
    my $solution = alDente::Department::solution_box( -choices => [ ( 'Find Stock', 'Search Solution', 'Show Applications' ) ], -dbc=>$dbc );

    ### Equipment Section
    my $equip = alDente::Department::equipment_box( -choices => [ ( '--Select--', 'Maintenance', 'Maintenance History' ) ], -dbc=>$dbc );

    ## Prep, Protocol, Pipeline summaries

    my $views         = alDente::Department::latest_runs_box(-dbc=>$dbc);
    my $summaries_box = alDente::Department::prep_summary_box(-dbc=>$dbc);
    my $view_summary  = alDente::Department::view_summary_box(-dbc=>$dbc);

    my $extra_links = &Link_To( $dbc->config('homelink'), "Search Vectors for Primers / Restriction Sites", "&Search+Vector=1" );

    ###Plates Section
    my %labels;
    $labels{'-'}           = '--Select--';
    $labels{'Plate Set'}   = 'Grab Plate Set';
    $labels{'Recover Set'} = 'Recover Plate Set';

    my $plates_box;
    if ( grep( /Lab|Bioinformatics/, @{ $Access{Lab} } ) ) {
        $plates_box = alDente::Department::plates_box(
            -type            => 'Library_Plate',
            -id_choices      => [ '-', 'Recover Set', 'Select No Grows', 'Select Slow Grows', 'Select Unused Wells', 'View Ancestry', 'Plate History', 'Plate Set' ],
            -access          => $Access{Lab},
            -include_rearray => 1,
            -labels          => \%labels,
            -dbc => $dbc
        );
    }

    #  $main_table->Set_Row([$plates_box . ]);
    $main_table->Set_Row( [ $plates_box . $solution . $equip ] );

    my $search_create_box = alDente::Department::search_create_box($dbc, \@searches, \@creates, -dbc=>$dbc );

    my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Lab')" );

    my $project_list = &alDente::Project::list_projects("Library_Name IN ('$libs')");
    $main_table->Toggle_Colour('off');
    $main_table->Set_Column_Widths( [ '50%', '50%' ] );
    $main_table->Set_VAlignment('top');

    my $lab_layer = $main_table->Printout( -filename => 0 );
    my @order = ( 'Projects', 'Lab', 'Summaries', 'Database' );
    my $layers = {
        "Projects"  => $project_list,
        "Lab"       => $lab_layer,
        "Summaries" => $views . $summaries_box . $view_summary,
        "Database"  => $search_create_box . lbr . $extra_links
    };
    my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'Lab', -form_name => 'Admin_layer' );

    if ( grep( /Admin/i, @{ $Access{Lab} } ) ) {
        push( @order, 'Admin' );
        $layers->{"Admin"} = $admin_table;
    }
    my $library_layers;

    if ( $dbc->package_active('Sequencing') ) {
        require Sequencing::Sequencing_Library;

        my $lib = new Sequencing::Sequencing_Library( -dbc => $dbc );

        $library_layers = $lib->library_main( -form_name => 'Admin_layer', -get_layers => 'Library Options', -labels => { 'Sequencing_Library' => 'Genomic_Library' } );
    }
    if ( defined %$library_layers ) {
        foreach my $key ( keys %$library_layers ) {
            $layers->{"$key"} = $library_layers->{$key};
            push( @order, "$key" );
        }
    }
    elsif ( $library_layers && ( $dbc->package_active('Sequencing') ) ) { return; }    ## returns 1 if generating a page of its own ...

    return define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );
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
