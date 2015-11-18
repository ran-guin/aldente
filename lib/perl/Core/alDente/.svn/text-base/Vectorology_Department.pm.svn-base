package alDente::Vectorology_Department;

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
my @icons_list = qw(Plates Solutions Equipments Libraries Sources Status Pipeline Contacts);

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
    if ( !( $Access{Vectorology} || $Access{'LIMS Admin'} ) ) {
        return;
    }
    alDente::Department::set_links();

    my @searches;
    my @creates;

    # Lab permissions for searches
    #  if (grep(/Lab/,@{$Access{Vectorology}})) {
    push( @searches, qw(Collaboration Contact Library Enzyme Primer Vector_Type Stock Organization Employee Vector_Backbone Buffer Stock Primer) );
    push( @creates,  qw(Contact Library Enzyme Primer Vector_Type Organization Employee Vector_Backbone Buffer Stock Primer) );

    #  }

    my $output = "<h2>Vectorology</H2>";
    $output .= '<hr>';

    my ($temp_rack)    = $dbc->Table_find( 'Rack',         'Rack_ID',         "WHERE Rack_Name = 'Temporary'", -limit => 1 );
    my ($std_pipeline) = $dbc->Table_find( 'Pipeline',     'Pipeline_ID',     -limit                                  => 1 );
    my ($std_format)   = $dbc->Table_find( 'Plate_Format', 'Plate_Format_ID', -limit                                  => 1 );

    my $datetime    = &date_time;
    my $user        = $dbc->get_local('user_id');
    my @omit_fields = qw(Plate_Number FK_Employee__ID FKOriginal_Plate__ID FKParent_Plate__ID);
    my @grey_fields = qw(Plate_Created Plate_Status Plate_Type FK_Plate_Format__ID Plate_Test_Status FK_Pipeline__ID FK_Library__Name);

    my $omit = join '&Omit=', @omit_fields;
    my $grey = join '&Grey=', @grey_fields;

    my $set = "&FK_Employee__ID=$user&Plate_Status=Active&Plate_Type=Tube&Plate_Created=$datetime&FK_Plate_Format__ID=$std_format&Plate_Test_Status=Production&FK_Pipeline__ID=$std_pipeline&FK_Library__Name=Vectr";

    my $centre = new HTML_Table( -align => 'center', -width => '100%' );

    my @links;
    my @content_types = ( 'gDNA', 'BAC_clone', 'Plasmid_clone', 'DNA_fragment', 'Vector_only' );
    foreach my $type (@content_types) {
        my $type     = $type;
        my $also_set = '';
        my $label    = "<Img src='/$URL_dir_name/images/icons/$type.png'/><BR>$type";
        #push @links, &Link_To( $dbc->config('homelink'), $label, "&New+Entry=New+Plate$set$also_set&Omit=$omit&Omit=Plate_Content_Type&Grey=$grey&Plate_Content_Type=$type" );
	my ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$type'" );
	push @links, &Link_To( $dbc->config('homelink'), $label, "&New+Entry=New+Plate$set$also_set&Omit=$omit&Omit=FK_Sample_Type__ID&Grey=$grey&FK_Sample_Type__ID=$sample_type_id" );
    }

    $centre->Set_Row( [ "<B>Click on new Sample to define: <B>", @links ] );

    $output .= $centre->Printout(0);

    my $layers = {
        "New Sample" => $output,
        "Queries"    => alDente::Department::view_summary_box( -dbc => $dbc ),
        "Database"   => alDente::Department::search_create_box($dbc, \@searches, \@creates ),
        "Upload"     => alDente::Department::upload_file_box(),
    };
    my @order = ( 'New Sample', 'Queries', 'Database', 'Upload' );
    $open_layer = 'New Sample';

    my $page = define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );

    my $plates_box;

    if ( grep( /Vectorology|Lab|Bioinformatics/, @{ $Access{Vectorology} } ) ) {
        $plates_box = '<p ></p>' . alDente::Department::delete_plates_box();
        $page .= $plates_box;
    }

    return $page;
##########
    alDente::Department::set_links();

    # Lab permissions for searches
    if ( grep( /Lab/, @{ $Access{Vectorology} } ) ) {
        push( @searches, qw(Collaboration Contact Equipment Library_Plate Plate Plate_Format Run Solution Stock Tube Vector_Type) );
        push( @creates,  qw(Plate Contact Source) );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Vectorology} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Vectorology} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Primer Project Rack) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Organization Plate_Format Project Rack Study) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    my $main_table = HTML_Table->new(
        -title    => "Vectorology Home Page",
        -width    => '100%',
        -bgcolour => 'white',
        -nolink   => 1,
    );

    ### Solution Section
    my $solution = alDente::Department::solution_box( -choices => [ ( 'Find Stock', 'Search Solution', 'Show Applications' ) ] );

    ### Equipment Section
    my $equip = alDente::Department::equipment_box( -choices => [ ( '--Select--', 'Maintenance', 'Maintenance History' ) ] );

    ## Prep, Protocol, Pipeline summaries

    my $views         = alDente::Department::latest_runs_box( -dbc => $dbc );
    my $summaries_box = alDente::Department::prep_summary_box( -dbc => $dbc );
    my $view_summary  = alDente::Department::view_summary_box( -dbc => $dbc );

    my $extra_links = &Link_To( $dbc->config('homelink'), "Search Vectors for Primers / Restriction Sites", "&Search+Vector=1" );

    ###Plates Section
    my %labels;
    $labels{'-'}           = '--Select--';
    $labels{'Plate Set'}   = 'Grab Plate Set';
    $labels{'Recover Set'} = 'Recover Plate Set';

    if ( grep( /Lab|Bioinformatics/, @{ $Access{Vectorology} } ) ) {
        $plates_box = alDente::Department::plates_box(
            -type            => 'Library_Plate',
            -id_choices      => [ '-', 'Recover Set', 'Select No Grows', 'Select Slow Grows', 'Select Unused Wells', 'View Ancestry', 'Plate History', 'Plate Set' ],
            -access          => $Access{Vectorology},
            -include_rearray => 1,
            -labels          => \%labels
        );
    }

    #  $main_table->Set_Row([$plates_box . ]);
    $main_table->Set_Row( [ $plates_box . $solution . $equip ] );

    my $search_create_box = alDente::Department::search_create_box($dbc, \@searches, \@creates );

    my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Lab')" );

    my $project_list = &alDente::Project::list_projects("Library_Name IN ('$libs')");
    $main_table->Toggle_Colour('off');
    $main_table->Set_Column_Widths( [ '50%', '50%' ] );
    $main_table->Set_VAlignment('top');

    my $lab_layer = $main_table->Printout( -filename => 0 );
    @order = ( 'Projects', 'Lab', 'Summaries', 'Database' );
    $layers = {
        "Projects"  => $project_list,
        "Lab"       => $lab_layer,
        "Summaries" => $views . $summaries_box . $view_summary,
        "Database"  => $search_create_box . lbr . $extra_links
    };
    my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'Vectorology', -form_name => 'Admin_layer' );

    if ( grep( /Admin/i, @{ $Access{Vectorology} } ) ) {
        push( @order, 'Admin' );
        $layers->{"Admin"} = $admin_table;
    }
    require Sequencing::Sequencing_Library;
    my $lib = new Sequencing::Sequencing_Library( -dbc => $dbc );
    my $library_layers = $lib->library_main( -form_name => 'Admin_layer', -get_layers => 'Library Options', -labels => { 'Sequencing_Library' => 'Genomic_Library' } );
    if ( defined %$library_layers ) {
        foreach my $key ( keys %$library_layers ) {
            $layers->{"$key"} = $library_layers->{$key};
            push( @order, "$key" );
        }
    }
    elsif ($library_layers) { return; }    ## returns 1 if generating a page of its own ...

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
