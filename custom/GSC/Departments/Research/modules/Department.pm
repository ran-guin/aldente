package Research::Department;
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


## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Views Last_24h Plates Database Dept_Projects Solutions_App Equipment_App Libraries Sources Pipeline Solexa_Summary_App_NO_filter Solid_Summary_App_NO_filter Export Subscription Contacts Modules);

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
    my $open_layer = $args{-open_layer} || 'Summaries';
    my $modules    = $args{-modules};

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    # This user does not have any permissions on Lab
    if ( !( $Access{Research} || $Access{'LIMS Admin'} ) ) {
        Message("no access");
        return;
    }
    alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    # Lab permissions for searches
    #  if (grep(/Research/,@{$Access{Research}})) {
    push( @searches, qw(Collaboration Funding Contact Equipment Library_Plate Plate Plate_Format Run Solution Stock Tube Vector_Type) );
    push( @creates,  qw(Collaboration Contact Funding Source) );

    #  }

    # Research permissions for searches
    if ( grep( /Research/, @{ $Access{Research} } ) ) {
        push( @searches, qw(Attribute Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Research} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Primer Project Rack) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Organization Plate_Format Project Study) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    #  my $main_table = HTML_Table->new(-title=>"Research Home Page",
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

    my $views         = alDente::Department::latest_runs_box($dbc);
    my $summaries_box = alDente::Department::prep_summary_box( -dbc => $dbc );

    #  my $extra_links = &Link_To( $homelink, "Search Vectors for Primers / Restriction Sites", "&Search+Vector=1" );

    ###Plates Section
    my %labels;
    $labels{'-'}           = '--Select--';
    $labels{'Plate Set'}   = 'Grab Plate Set';
    $labels{'Recover Set'} = 'Recover Plate Set';

    my $plates_box;
    if ( grep( /Lab|Research/, @{ $Access{Research} } ) ) {
        $plates_box = alDente::Department::plates_box(
            -type            => 'Library_Plate',
            -id_choices      => [ '-', 'Recover Set', 'Select No Grows', 'Select Slow Grows', 'Select Unused Wells', 'View Ancestry', 'Plate History', 'Plate Set' ],
            -access          => $Access{Research},
            -include_rearray => 1,
            -labels          => \%labels,
            -dbc             => $dbc
        );
    }

    #  $main_table->Set_Row([$plates_box . ]);
    #  $main_table->Set_Row([ $plates_box . $solution . $equip]);

    #  my $search_create_box = alDente::Department::search_create_box($dbc,  \@searches, \@creates );
#######################################
##  Add layer for API documentation ###
#######################################

    my $format = 'tab';    ## format for layers
    my %layers;
    my @order;

    ## To add new modules to the API documentation layer, add to the array below (eg <directory>::<module_name> )
    my @modules  = qw(Sequencing::Sequencing_API Illumina::Solexa_API alDente::alDente_API Lib_Construction::Microarray_API Mapping::Mapping_API);    ## list of applicable modules
    my @sections = qw(SYNOPSIS DESCRIPTION NAME);

    my $import_view = new alDente::Import_Views( -dbc => $dbc );
    $layers{'Upload Document'} = $import_view->display_Import_Document_box( -dbc => $dbc );

#####################

    my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Cap_Seq')" );

    #  my $project_list = &alDente::Project::list_projects( $dbc, "" );                                                                                  ## Library_Name IN ('$libs')");

    #  $main_table->Toggle_Colour('off');
    #  $main_table->Set_Column_Widths(['50%','50%']);
    #  $main_table->Set_VAlignment('top');
    #
    #  my $lab_layer = $main_table->Printout(-filename=>0);

    unless ( param('API') ) {
#        push @order, ( 'Projects', 'Lab', 'Summaries', 'Database', 'Primer Plate', 'Upload Document' );
        #  $layers{Projects} = $project_list;

        #      $layers{Lab} = $lab_layer;
        $layers{Summaries} = $views . $summaries_box ;
        #  $layers{Database}  = $search_create_box . lbr . $extra_links;

        my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'Research', -form_name => 'Admin_layer' );

        if ( grep( /Admin/i, @{ $Access{Research} } ) ) {
            push( @order, 'Admin' );
            $layers{"Admin"} = $admin_table;
        }
        require Sequencing::Sequencing_Library;
        my $lib = new Sequencing::Sequencing_Library( -dbc => $dbc );
        my $library_layers = $lib->library_main( -form_name => 'Admin_layer', -get_layers => 'Library Options', -labels => { 'Sequencing_Library' => 'Genomic_Library' } );
        if ( defined %$library_layers ) {
            foreach my $key ( keys %$library_layers ) {
                $layers{"$key"} = $library_layers->{$key};
                push( @order, "$key" );
            }
        }
        elsif ($library_layers) { return; }    ## returns 1 if generating a page of its own ...
#        $open_layer = 'Projects';
    }

    my $output = SDB::HTML::define_Layers(
        -layers    => \%layers,
        -tab_width => 100,
#        -order     => \@order,
        -format    => $format,
        -default   => $open_layer,
    );

    return $output;
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
