package Management::Department;
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
use RGTools::Code;
use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

#use Mapping::Mapping_Summary;

use vars qw($Connection);

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Views Last_24h Plates Database Solutions_App Equipment_App Dept_Projects Libraries Sources Pipeline Management_Stat Management_Summary Solexa_Summary_App_NO_filter Solid_Summary_App_NO_filter Contacts);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,open_layer');
    my $dbc        = $args{-dbc}        || $self->{dbc};
    my $open_layer = $args{-open_layer} || 'Summaries';
    my $modules    = $args{-modules};

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    # This user does not have any permissions on Lab
    if ( !( $Access{Management} || $Access{'LIMS Admin'} ) ) {
        Message("no access");
        return;
    }
    alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    # Lab permissions for searches
    #  if (grep(/Management/,@{$Access{Management}})) {#
    push( @searches, qw(Collaboration Funding Contact Equipment Library_Plate Plate Plate_Format Run Solution Stock Tube Vector_Type) );
    push( @creates,  qw(Collaboration Contact Funding Source) );

    #  }

    # Management permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Management} } ) ) {
        push( @searches, qw(Attribute Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Management} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Primer Project Rack) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Organization Plate_Format Project Study) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    #  my $main_table = HTML_Table->new(-title=>"Management Home Page",
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

    my $views     = alDente::Department::latest_runs_box($dbc);
    my $summaries = overview_summaries($dbc);

    #  my $extra_links = &Link_To( $homelink, "Search Vectors for Primers / Restriction Sites", "&Search+Vector=1" );

    ###Plates Section
    my %labels;
    $labels{'-'}           = '--Select--';
    $labels{'Plate Set'}   = 'Grab Plate Set';
    $labels{'Recover Set'} = 'Recover Plate Set';

    my $plates_box;
    if ( grep( /Lab|Management/, @{ $Access{Management} } ) ) {
        $plates_box = alDente::Department::plates_box(
            -type            => 'Library_Plate',
            -id_choices      => [ '-', 'Recover Set', 'Select No Grows', 'Select Slow Grows', 'Select Unused Wells', 'View Ancestry', 'Plate History', 'Plate Set' ],
            -access          => $Access{Management},
            -include_rearray => 1,
            -labels          => \%labels
        );
    }

    #  $main_table->Set_Row([$plates_box . ]);
    #  $main_table->Set_Row([ $plates_box . $solution . $equip]);

    #  my $search_create_box = alDente::Department::search_create_box( $dbc, \@searches, \@creates );

    #    my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Cap_Seq')" );

    #    my $project_list = &alDente::Project::list_projects( $dbc, "" );    ## Library_Name IN ('$libs')");

    #  $main_table->Toggle_Colour('off');
    #  $main_table->Set_Column_Widths(['50%','50%']);
    #  $main_table->Set_VAlignment('top');
    #
    #  my $lab_layer = $main_table->Printout(-filename=>0);

    my @order;
    my %layers;

    unless ( param('API') ) {
        push @order, ( 'Projects', 'Summaries', 'Database' );

        #        $layers{Projects}  = $project_list;
        $layers{Summaries} = $summaries;
        #  $layers{Database}  = $search_create_box . lbr . $extra_links;

        $open_layer = 'Summaries';
    }

    my $output = SDB::HTML::define_Layers(
        -layers    => \%layers,
        -tab_width => 100,
        -order     => \@order,
        -format    => $format
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
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{Management} } ) ) {
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

##########################
sub overview_summaries {
##########################
    my %args    = filter_input( \@_, -args => 'dbc,include' );
    my $dbc     = $args{-dbc};
    my $include = $args{-include} || 'Reads,Throughput,Run_Type';

    my $page;

    my %read_data = $dbc->Table_retrieve(
        'Run LEFT JOIN Run_Analysis ON Run_Analysis.FK_Run__ID=Run_ID LEFT JOIN SOLID_Run_Analysis ON SOLID_Run_Analysis.FK_Run_Analysis__ID=Run_Analysis_ID LEFT JOIN SequenceRun ON SequenceRun.FK_Run__ID=Run_ID LEFT JOIN SequenceAnalysis ON FK_SequenceRun__ID=SequenceRun_ID LEFT JOIN Solexa_Read ON Solexa_Read.FK_Run__ID=Run_ID',
        [   'Left(Run_DateTime,4) as Year',
            'Run_Type'
            , "SUM(
        CASE WHEN Run_Type = 'SequenceRun' THEN SequenceAnalysis.AllReads
        WHEN Run_Type = 'SolexaRun' THEN Solexa_Read.Number_Reads 
        WHEN Run_Type = 'SOLIDRun' THEN SOLID_Run_Analysis.Number_Reads 
        ELSE 0 END)/1000000 as Million_Reads"
            , 'count(*) as Runs'
        ],
        -group => 'Year, Run_Type',
        -order => 'Year'
    );

    use RGTools::GGraph;
    my $Graph = new GGraph();

    my ( $height, $width ) = ( 600, 800 );

    $page .= '<h2>Total Runs</H2>';

    $page .= $Graph->google_chart( -name => 'Runs', -data => \%read_data, -type => 'Column', -xaxis => 'Year', -merge => 'Run_Type', -yaxis => 'Runs', -width => $width, -height => $height, -isStacked => 1, -quiet => 1 );

    $page .= '<h2>Total Reads</H2>';

    $page .= $Graph->google_chart( -name => 'Reads', -data => \%read_data, -type => 'Column', -xaxis => 'Year', -merge => 'Run_Type', -yaxis => 'Million_Reads', -width => $width, -height => $height, -isStacked => 1, -quiet => 1, -logScale => 1 );

    return $page;
}

return 1;
