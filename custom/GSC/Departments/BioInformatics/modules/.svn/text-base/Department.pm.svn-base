package BioInformatics::Department;
use base alDente::Department;

use strict;
use warnings;
use CGI qw(:standard);
use DBI;
use Data::Dumper;
use Benchmark;

use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Tools;
use alDente::Primer_Plate_Views;
use alDente::Import_Views;
use RGTools::Code;
use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

#use Mapping::Mapping_Summary;

use vars qw($Connection);

## Specify the icons that you want to appear in the top bar
my @icons_list
    = qw(Last_24h Views Plates Rearrays Solutions_App Equipment_App Libraries Sources Dept_Projects Pipeline BioInformatics_Stat BioInformatics_Summary Solexa_Summary_App_NO_filter Solexa_Summary_App Solid_Summary_App_NO_filter Submission Contacts Template Import Database Modules Subscription);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'dbc,open_layer' );
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $open_layer = $args{-open_layer} || 'API modules';
    my $modules    = $args{-modules};

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    # This user does not have any permissions on Lab
    if ( !( $Access{BioInformatics} || $Access{'LIMS Admin'} ) ) {
        Message("no access");
        return;
    }
    alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    # Lab permissions for searches
    #  if (grep(/BioInformatics/,@{$Access{BioInformatics}})) {#
    push( @searches, qw(Collaboration Funding Contact Equipment Library_Plate Plate Plate_Format Run Solution Stock Tube Vector_Type) );
    push( @creates,  qw(Collaboration Contact Funding Source) );

    #  }

    # BioInformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{BioInformatics} } ) ) {
        push( @searches, qw(Attribute Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{BioInformatics} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Primer Project Rack) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Organization Plate_Format Project Study) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    #  my $main_table = HTML_Table->new(-title=>"BioInformatics Home Page",
    #				   -width=>'100%',
    #				   -bgcolour=>'white',
    #				   -nolink=>1,
    #				   );
    #
    #  ### Solution Section
    #  my $solution = alDente::Department::solution_box(-choices=>[('Find Stock','Search Solution','Show Applications')]);##
    #
    #  ### Equipment Section
    #  my $equip = alDente::Department::equipment_box(-choices=>[('--Select--','Maintenance','Maintenance History')]);##
    #
    # ## Prep, Protocol, Pipeline summaries

    $dbc->Benchmark('start_bioinf');
    my $views = alDente::Department::latest_runs_box($dbc);
    my $summaries_box = alDente::Department::prep_summary_box( -dbc => $dbc );
    $dbc->Benchmark('summary_generated');

    #  my $extra_links = &Link_To( $homelink, "Search Vectors for Primers / Restriction Sites", "&Search+Vector=1" );

    ###Plates Section
    my %labels;
    $labels{'-'}           = '--Select--';
    $labels{'Plate Set'}   = 'Grab Plate Set';
    $labels{'Recover Set'} = 'Recover Plate Set';

    my $plates_box;
    if ( grep( /Lab|BioInformatics/, @{ $Access{BioInformatics} } ) ) {
        $plates_box = alDente::Department::plates_box(
            -type            => 'Library_Plate',
            -id_choices      => [ '-', 'Recover Set', 'Select No Grows', 'Select Slow Grows', 'Select Unused Wells', 'View Ancestry', 'Plate History', 'Plate Set' ],
            -access          => $Access{BioInformatics},
            -include_rearray => 1,
            -labels          => \%labels
        );
    }

    #  $main_table->Set_Row([$plates_box . ]);
    #  $main_table->Set_Row([ $plates_box . $solution . $equip]);

    #  my $search_create_box = alDente::Department::search_create_box( $dbc, \@searches, \@creates );

    my $format = 'tab';    ## format for layers
    my %layers;
    my @order = ( 'Projects', 'Lab', 'Summaries', 'Database', 'Upload Document', 'Analysis Goals' );

    if ( $dbc->table_loaded('Primer_Plate') ) {
        my $primer_plate_view = new alDente::Primer_Plate_Views( -dbc => $dbc );
        $layers{'Primer Plate'} = $primer_plate_view->display_delete_Primer_Plate_table( -dbc => $dbc );
        push @order, 'Primer Plate';
    }
    $dbc->Benchmark('displayed_PP');

    my $import_view = new alDente::Import_Views( -dbc => $dbc );
    $layers{'Upload Document'} = $import_view->display_Import_Document_box( -dbc => $dbc );

    $dbc->Benchmark('imported_doc');

#####################

    #  my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Cap_Seq')" );
    #  my $project_list = &alDente::Project::list_projects( $dbc, "" );    ## Library_Name IN ('$libs')");
    #  $dbc->Benchmark('projects_listed');

    #  $main_table->Toggle_Colour('off');
    #  $main_table->Set_Column_Widths(['50%','50%']);
    #  $main_table->Set_VAlignment('top');
    #
    #  my $lab_layer = $main_table->Printout(-filename=>0);

    #  $layers{Projects} = $project_list;

    #      $layers{Lab} = $lab_layer;
    $layers{Summaries} = $views . $summaries_box;

    #  $layers{Database}  = $search_create_box . lbr . $extra_links;
    $layers{'Analysis Goals'} = alDente::Goal::add_Analysis_Goal_form( -dbc => $dbc, -goal_type => 'Data Analysis' );

    if ( grep( /Admin/i, @{ $Access{BioInformatics} } ) ) {
        my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'BioInformatics', -form_name => 'Admin_layer' );
        push( @order, 'Admin' );
        $layers{"Admin"} = $admin_table;
    }
    require Sequencing::Sequencing_Library;
    my $lib = new Sequencing::Sequencing_Library( -dbc => $dbc );
    my $library_layers = $lib->library_main( $dbc, -form_name => 'Admin_layer', -get_layers => 'Library Options', -labels => { 'Sequencing_Library' => 'Genomic_Library' } );
    if ( defined %$library_layers ) {
        foreach my $key ( keys %$library_layers ) {
            $layers{"$key"} = $library_layers->{$key};
            push( @order, "$key" );
        }
    }
    elsif ($library_layers) { return; }    ## returns 1 if generating a page of its own ...
    $open_layer = 'Projects';

    my $output = SDB::HTML::define_Layers(
        -layers    => \%layers,
        -tab_width => 100,
        -order     => \@order,
        -format    => $format
    );

    $Benchmark{main_page_loaded} = new Benchmark();
    return $output;
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
    if ( grep( /Admin/, @{ $Access{BioInformatics} } ) ) {
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
    $images{Solexa_Summary_App_NO_filter}{icon} = "summary.ico";
    $images{Solexa_Summary_App_NO_filter}{url}  = "cgi_application=" . "Illumina::Solexa_Summary_App&filter_by_department=0";
    $images{Solexa_Summary_App_NO_filter}{name} = 'Solexa Summary';
    $images{Solexa_Summary_App_NO_filter}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";

    $images{Solid_Summary_App_NO_filter}{icon} = "summary.ico";
    $images{Solid_Summary_App_NO_filter}{url}  = "cgi_application=" . "SOLID::SOLID_Summary_App&filter_by_department=0";
    $images{Solid_Summary_App_NO_filter}{name} = 'Solid Summary';
    $images{Solid_Summary_App_NO_filter}{tip}  = "Laboratory level Summaries; (see Stats icon for Project level summaries)";
    return \%images;

}
return 1;
