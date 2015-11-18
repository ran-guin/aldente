package Lib_Construction::Department;
use base alDente::Department;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;

use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;
use alDente::Container_Views;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use SDB::DBIO;
use Bioanalyzer::Run_Views;

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Views Solexa_Summary_App Solutions_App Equipment_App Rack Tubes Pool_ReArray  Sources Dept_Projects Pipeline Stat_App
    Export Import Template Shipments Contacts Lib_Construction_Summary Bioanalyzer_Run_App CLIPR_Run_App GelRun_App In_Transit RNA_DNA_Collections Database Barcodes Subscription Custom_Import );

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

    ###Permissions###
    my %Access      = %{ $dbc->get_local('Access') };
    my %group_types = %{ $dbc->get_local('group_type') };

    #This user does not have any permissions on Lib_Construction
    if ( !( $Access{'Lib_Construction'} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    #  my $main_table = HTML_Table->new(-title=>"Lib_Construction Home Page",
    #				   -width=>'100%' , -bgcolour=>'white');

    ###Plates Section
    my @id_choices = ('-');

    #push(@choices,'Save Plate Set');
    push( @id_choices, 'Delete' );
    push( @id_choices, 'Fail Plates' ), push( @id_choices, 'Fail and Throw Out Plates' ), push @id_choices, 'Throw Out Plates';
    push( @id_choices, 'Annotate' );
    push( @id_choices, 'Recover Set' );

    #push(@choices,'Throw Away Plate');
    push( @id_choices, 'Select No Grows' );
    push( @id_choices, 'Select Slow Grows' );
    push( @id_choices, 'Select Unused Wells' );
    push( @id_choices, 'View Ancestry' );
    push( @id_choices, 'Plate History' );
    push( @id_choices, 'Re-Print Plate Labels' );

    #push(@id_choices,'Plate Set');

    my %labels;
    $labels{'-'}           = '--Select--';
    $labels{'Plate Set'}   = 'Grab Plate Set';
    $labels{'Recover Set'} = 'Recover Plate Set';

    my ( $plates, $solution, $equip, $spect, $bioanalyzer );

    if ( grep( /Lab|Bioinformatics/, @{ $Access{'Lib_Construction'} } ) ) {
        $plates = alDente::Container_Views::plates_box(
            -dbc        => $dbc,
            -type       => 'Library_Plate',
            -id_choices => \@id_choices,
            -access     => $Access{'Lib_Construction'},
            -labels     => \%labels
        );
    }

    if ( grep( /Lab/, @{ $Access{'Lib_Construction'} } ) ) {
        ###Solution Section
        $solution = alDente::Department::solution_box(
            -choices => [ ( 'Find Stock', 'Search Solution', 'Show Applications' ) ],
            -dbc => $dbc
        );

        ###Equipment Section
        $equip = alDente::Department::equipment_box( $dbc, -choices => [ ( '--Select--', 'Maintenance', 'Maintenance History', 'Sequencer Status' ) ] );
    }
    $Benchmark{gen_reports} = new Benchmark;

    # my $reports      = alDente::Department::prep_summary_box( -dbc => $dbc );
    #$Benchmark{gen_view} = new Benchmark();;
    #my $run_summary  = view_summary_box();
    #$Benchmark{gen_dept_view} = new Benchmark();

    #  $main_table->Set_Row([$plates . $solution . $equip,
    #			alDente::Department::search_create_box($dbc, \@searches,\@creates) .lbr. $reports]);
    #
    #  $main_table->Toggle_Colour('off');
    #  $main_table->Set_Column_Widths(['50%','50%']);
    #  $main_table->Set_VAlignment('top');

    $Benchmark{gen_query} = new Benchmark();

    # my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('Lib_Construction','Public')" );
    $Benchmark{gen_admin} = new Benchmark;

    my $admin_table = alDente::Admin::Admin_page( -dbc => $dbc, -reduced => 0, -department => 'Lib_Construction', -form_name => 'Admin_layer' );

## commented out sections below that are moved to Department_Views ...
    my %Layers;

    $Layers{"Lab"} = $plates . $solution . $equip,

        #    $Layers{"Bioanalyzer Runs"} = Bioanalyzer::Run_Views::view_runs( -dbc => $dbc );

        my @order = ( 'Lab', 'Bioanalyzer Runs' );
    if ( grep( /Admin/, @{ $Access{'Lib_Construction'} } ) ) {
        $Layers{"Admin"} = $admin_table;
        push( @order, 'Admin' );
    }
    if ( grep( /TechD/, @{ $group_types{'Lib_Construction'} } ) ) {
        $Layers{"TechD"} = alDente::Department_Views::display_TechD( -dbc => $dbc, -department => 'Lib_Construction' );
        push @order, 'TechD';
    }
    $Benchmark{gen_rna_dna} = new Benchmark();

    #print HTML_Dump $layers;

    my $output = &define_Layers(
        -layers    => \%Layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );

    $Benchmark{done_lib_con} = new Benchmark();
    return $output;
}

#
# <snip>
#
# </snip>
###############################
sub get_searches_and_creates {
##############################

    my %args   = @_;
    my %Access = %{ $args{-access} };
    my @creates;
    my @searches;
    my @converts;

    # Department permissions for searches
    if ( grep( /Lab/, @{ $Access{Lib_Construction} } ) ) {
        push( @searches, qw(Collaboration Contact RNA_DNA_Collection Equipment Library Library_Plate Plate Plate_Format Source Solution Stock Study Tube) );
        push( @creates,  qw(Plate Contact Study) );
        push( @converts, qw() );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Lib_Construction} } ) ) {
        push( @searches, qw() );
        push( @creates,  qw() );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{Lib_Construction} } ) ) {
        push( @searches, qw(Agilent_Assay Employee Enzyme Funding GCOS_Config Organization Original_Source Project Rack Original_Source Stock_Catalog) );
        push( @creates,  qw(Agilent_Assay Collaboration Enzyme Funding GCOS_Config Organization Plate_Format Project Stage Stock_Catalog Process_Deviation RNA_Strategy Control_Type) );
    }
    @creates  = sort @{ unique_items( [ sort(@creates) ] ) };
    @searches = sort @{ unique_items( [ sort(@searches) ] ) };
    @converts = sort @{ unique_items( [ sort(@converts) ] ) };

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
    if ( grep( /Admin/, @{ $Access{'Lib_Construction'} } ) ) {
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
