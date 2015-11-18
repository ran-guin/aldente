package UHTS::Department;
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
use alDente::Form;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use SDB::DBIO;

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Views Solexa_Summary_App Solutions_App Equipment_App Rack Tubes Rearrays RNA_DNA_Collections Sources Database
    Projects Pipeline Stat_App Ion_Torrent_Summary QPCR_Run_App Export Import Template Shipments Contacts In_Transit RNA_DNA_Collection Subscription);

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,open_layer');
    my $dbc        = $args{-dbc}        || $self->dbc;
    my $open_layer = $args{-open_layer} || 'Lab';

    ###Permissions###
    my %Access      = %{ $dbc->get_local('Access') };
    my %group_types = %{ $dbc->get_local('group_type') };

    #This user does not have any permissions on UHTS
    if ( !( $Access{'UHTS'} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

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

    my ( $plates, $solution, $equip, $seq_request, $spect, $bioanalyzer );

    if ( grep( /Lab|Bioinformatics/, @{ $Access{'UHTS'} } ) ) {
        $plates = alDente::Container_Views::plates_box(
            -dbc        => $dbc,
            -type       => 'Library_Plate',
            -id_choices => \@id_choices,
            -access     => $Access{'UHTS'},
            -labels     => \%labels
        );
    }

    if ( grep( /Lab/, @{ $Access{'UHTS'} } ) ) {
        ###Solution Section
        $solution = alDente::Department::solution_box(
            -choices => [ ( 'Find Stock', 'Search Solution', 'Show Applications' ) ],
            -dbc => $dbc
        );
        ###Run Requests Section
        $seq_request = alDente::Department::seq_request_box( $dbc, -choices => [ ( 'Remove Run Request', 'Mark Failed Runs', 'Annotate Run Comments' ) ] );

        ###Equipment Section
        $equip = alDente::Department::equipment_box( -dbc => $dbc, -choices => [ ( '--Select--', 'Maintenance', 'Maintenance History', 'Sequencer Status' ) ] );

        ###Spectrophotometer Section
        #$spect = alDente::Department::spect_run_box();

        ###Bioanalyzer(Agilent) Section
        #$bioanalyzer = alDente::Department::bioanalyzer_run_box();
    }

    my $reports = alDente::Department::prep_summary_box( -dbc => $dbc );
    my $run_summary = view_summary_box( -dbc => $dbc );

    #  my $view_summary = alDente::Department::view_summary_box( -dbc => $dbc );

    #  $main_table->Set_Row([$plates . $solution . $equip,
    #			alDente::Department::search_create_box($dbc, \@searches,\@creates) .lbr. $reports]);
    #
    #  $main_table->Toggle_Colour('off');
    #  $main_table->Set_Column_Widths(['50%','50%']);
    #  $main_table->Set_VAlignment('top');

    my $admin_table = alDente::Admin::Admin_page( -dbc => $dbc, -reduced => 0, -department => 'UHTS', -form_name => 'Admin_layer' );

    my $layers = {
        "Lab"       => $plates . $solution . $equip . $seq_request . $spect . $bioanalyzer,
        "Summaries" => $reports . $run_summary,
    };

    my @order = ( 'Lab', 'Summaries' );
    if ( grep( /Admin/, @{ $Access{'UHTS'} } ) ) {
        require alDente::Rack_Views;
        push( @order, 'Admin', 'In Transit' );
        $layers->{"Admin"} = $admin_table;

    }
    if ( grep( /TechD/, @{ $group_types{'UHTS'} } ) ) {
        $layers->{"TechD"} = alDente::Department_Views::display_TechD( -dbc => $dbc, -department => 'UHTS' );
        push @order, 'TechD';
    }

    #    my $lib = new alDente::RNA_DNA_Collection( -dbc => $dbc );
    #    my $library_layers = $lib->library_main( -form_name => 'Admin_layer', -get_layers => 'RNA/DNA Collection Options', -dbc => $dbc );
    #    if ( defined %$library_layers ) {
    #        foreach my $key ( keys %$library_layers ) {
    #            $layers->{"$key"} = $library_layers->{$key};
    #            push( @order, "$key" );
    #        }
    #    }
    #    elsif ($library_layers) { return; }    ## returns 1 if generating a page of its own ...

    #print HTML_Dump $layers;

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
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{'UHTS'} } ) ) {
        push @icons_list, "Submission";
        push @icons_list, "Employee";
    }

    return \@icons_list;
}

###############################
sub get_searches_and_creates {
##############################

    my %args   = @_;
    my %Access = %{ $args{-access} };

    my @creates;
    my @searches;
    my @converts;

    #Lab permissions for searches
    if ( grep( /Lab/, @{ $Access{'UHTS'} } ) ) {
        push( @searches, qw(Collaboration Contact RNA_DNA_Collection Equipment Library Library_Plate Plate Plate_Format Source Solution Stock Study Tube) );
        push( @creates,  qw(Plate Contact Study) );
    }

    #Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{'UHTS'} } ) ) {
        push( @searches, qw(Agilent_Assay Employee Enzyme Funding GCOS_Config Organization Original_Source Project Rack Original_Source Stock_Catalog) );
        push( @creates,  qw(Agilent_Assay Collaboration Employee Enzyme Funding GCOS_Config Organization Plate_Format Project Stage Stock_Catalog Process_Deviation RNA_Strategy) );
    }

    @creates  = sort @{ unique_items( [ sort(@creates) ] ) };
    @searches = sort @{ unique_items( [ sort(@searches) ] ) };
    @converts = sort @{ unique_items( [ sort(@converts) ] ) };

    return ( \@searches, \@creates, \@converts );

}

####################
sub view_summary_box {
####################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};
	my $homelink = $dbc->homelink();
	
    my $views = alDente::Department::_init_table('Run Views');
    $views->Set_Headers( [ 'View Name', 'Description' ] );
    $views->Set_Row( [ &Link_To( $homelink, "Solexa run search",   "&cgi_application=Illumina::Solexa_Summary_App" ), "Search for information on Solexa runs" ] );
    $views->Set_Row( [ &Link_To( $homelink, "Run Analysis Report", "&cgi_application=alDente::Run_Analysis_App" ),    "Run Analysis Reports" ] );
    return alDente::Form::start_alDente_form( $dbc, 'RunViews') . $views->Printout(0) . end_form();
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
