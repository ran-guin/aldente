package Microarray::Department;
use base alDente::Department;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;

use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;
use alDente::Form;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use SDB::DBIO;

use vars qw($Connection);

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(GenechipExpSummary Database GenechipMapSummary Solutions_App Equipment_App Tubes RNA_DNA_Collections Sources Dept_Projects Pipeline Stat_App Gene_Summary_App Bio_Summary_App Export Contacts);

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
    my $open_layer = $args{-open_layer} || 'Lab';

    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };

    #This user does not have any permissions on Lib_Construction
    if ( !( $Access{'Microarray'} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    #Lab permissions for searches
    if ( grep( /Lab/, @{ $Access{'Microarray'} } ) ) {
        push( @searches, qw(Collaboration Contact Equipment Library Library_Plate Plate Plate_Format Source Solution Stock Study Tube) );
        push( @creates,  qw(Plate Contact Study) );
    }

    #Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{'Microarray'} } ) ) {
        push( @searches, qw(Agilent_Assay Employee Enzyme Funding GCOS_Config Organization Original_Source Project Rack Original_Source Stock_Catalog) );
        push( @creates,  qw(Agilent_Assay Collaboration Employee Enzyme Funding GCOS_Config Genechip_Type Organization Plate_Format Project Stage Stock_Catalog) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    #  my $main_table = HTML_Table->new(-title=>"Lib_Construction Home Page",
    #				   -width=>'100%' , -bgcolour=>'white');

    ###Plates Section
    my @id_choices = ('-');

    #push(@choices,'Save Plate Set');
    push( @id_choices, 'Recover Set' );

    #push(@choices,'Throw Away Plate');
    push( @id_choices, 'Select No Grows' );
    push( @id_choices, 'Select Slow Grows' );
    push( @id_choices, 'Select Unused Wells' );
    push( @id_choices, 'View Ancestry' );
    push( @id_choices, 'Plate History' );
    push( @id_choices, 'Plate Set' );

    my %labels;
    $labels{'-'}           = '--Select--';
    $labels{'Plate Set'}   = 'Grab Plate Set';
    $labels{'Recover Set'} = 'Recover Plate Set';

    my ( $plates, $solution, $equip, $spect, $bioanalyzer );

    if ( grep( /Lab|Bioinformatics/, @{ $Access{'Microarray'} } ) ) {
        $plates = alDente::Container_Views::plates_box(
            -dbc        => $dbc,
            -type       => 'Library_Plate',
            -id_choices => \@id_choices,
            -access     => $Access{'Microarray'},
            -labels     => \%labels
        );
    }
    if ( grep( /Lab/, @{ $Access{'Microarray'} } ) ) {
        ###Solution Section
        $solution = alDente::Department::solution_box(
            -choices => [ ( 'Find Stock', 'Search Solution', 'Show Applications' ) ],
            -dbc => $dbc
        );

        ###Equipment Section
        $equip = alDente::Department::equipment_box( $dbc, -choices => [ ( '--Select--', 'Maintenance', 'Maintenance History', 'Sequencer Status' ) ] );

        ###Spectrophotometer Section
        #$spect = alDente::Department::spect_run_box();

        ###Bioanalyzer(Agilent) Section
        $bioanalyzer = alDente::Department::bioanalyzer_run_box($dbc);
    }
    my $reports = alDente::Department::prep_summary_box( -dbc => $dbc );
    my $run_summary = view_summary_box($dbc);

    #  $main_table->Set_Row([$plates . $solution . $equip,
    #			alDente::Department::search_create_box($dbc, \@searches,\@creates) .lbr. $reports]);
    #
    #  $main_table->Toggle_Colour('off');
    #  $main_table->Set_Column_Widths(['50%','50%']);
    #  $main_table->Set_VAlignment('top');

    #  my $libs = join "','", $dbc->Table_find('Library,Grp,Department','Library_Name',"WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Microarray')");

    my $admin_table = alDente::Admin::Admin_page( -dbc => $dbc, -reduced => 0, -department => 'Microarray', -form_name => 'Admin_layer' );

    my $layers = {

        #      "Projects" => &alDente::Project::list_projects($dbc,"Library_Name IN ('$libs')"),
        "Lab"       => $plates . $solution . $equip . $spect . $bioanalyzer,
        # "Database"  => alDente::Department::search_create_box( $dbc, \@searches, \@creates ),
        "Summaries" => $reports . $run_summary,
    };

    my @order = ( 'Projects', 'Lab', 'Database', 'Summaries' );
    if ( grep( /Admin/, @{ $Access{'Microarray'} } ) ) {
        push( @order, 'Admin' );
        $layers->{"Admin"} = $admin_table;
    }

    my $lib = new alDente::RNA_DNA_Collection( -dbc => $dbc );

    my $library_layers = $lib->library_main( -form_name => 'Admin_layer', -get_layers => 'RNA/DNA Collection Options', -dbc => $dbc );
    if ( defined %$library_layers ) {
        foreach my $key ( keys %$library_layers ) {
            $layers->{"$key"} = $library_layers->{$key};
            push( @order, "$key" );
        }
    }
    elsif ($library_layers) { return; }    ## returns 1 if generating a page of its own ...

    my $output = &define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );
    return $output;
}

########################################
#
# Accessor function for the icons list
####################
sub get_icons {
####################
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
####################
sub view_summary_box {
####################
    my $dbc = shift;

    my $views = alDente::Department::_init_table('Run Views');
    $views->Set_Headers( [ 'View Name', 'Description' ] );
    $views->Set_Row( [ &Link_To( $homelink, "Bioanalyzer run search",         "&Lib_Construction_BioanalyzerRun=1&bioanalyzer_home_page=1" ), "Search for information on bioanalyzer runs" ] );
    $views->Set_Row( [ &Link_To( $homelink, "Mapping Genechip run search",    "&cgi_application=Mapping::Summary_App" ),                      "Search for information on mapping genechip runs" ] );
    $views->Set_Row( [ &Link_To( $homelink, "Expression Genechip run search", "&cgi_application=Microarray::Summary_App" ),                   "Search for information on expression genechip runs" ] );

    return alDente::Form::start_alDente_form( $dbc, 'RunViews', $homelink ) . $views->Printout(0) . end_form();
}

return 1;
