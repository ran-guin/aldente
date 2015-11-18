package Epigenomics::Department_Views;

use base alDente::Department_Views;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use vars qw(%Configs);

## Specify the icons that you want to appear in the top bar

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my %args = filter_input( \@_, -args => 'dbc,open_layer', -mandatory => 'dbc' );
    my $dbc = $args{-dbc};

    my $open_layer = $args{-open_layer};

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my $datetime = &date_time;
    my $user     = $dbc->get_local('user_id');

    # This user does not have any permissions on Department
    if ( !( $Access{'Epigenomics'} || $Access{'LIMS Admin'} ) ) {
        return;
    }
    alDente::Department::set_links($dbc);

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

    my ( $plates, $solution, $equip );

    if ( grep( /Lab|Bioinformatics/, @{ $Access{'Epigenomics'} } ) ) {
        $plates = alDente::Container_Views::plates_box(
            -dbc        => $dbc,
            -type       => 'Library_Plate',
            -id_choices => \@id_choices,
            -access     => $Access{'Epigenomics'},
            -labels     => \%labels
        );
    }

    if ( grep( /Lab/, @{ $Access{'Epigenomics'} } ) ) {
        ###Solution Section
        $solution = alDente::Department::solution_box(
            -choices => [ ( 'Find Stock', 'Search Solution', 'Show Applications' ) ],
            -dbc => $dbc
        );

        ###Equipment Section
        $equip = alDente::Department::equipment_box( -dbc => $dbc, -choices => [ ( '--Select--', 'Maintenance', 'Maintenance History', 'Sequencer Status' ) ] );
    }

    my ( $search_ref, $creates_ref ) = Epigenomics::Department::get_searches_and_creates( -access => \%Access );
    my @searches = @$search_ref;
    my @creates  = @$creates_ref;

    my ( $greys_ref, $omits_ref ) = Epigenomics::Department::get_greys_and_omits();
    my @grey_fields = @$greys_ref;
    my @omit_fields = @$omits_ref;

    my $grey = join '&Grey=', @grey_fields;
    my $omit = join '&Omit=', @omit_fields;

    #my $search_create_box = alDente::Department::search_create_box(\@searches,\@creates);

    my $extra_links;

    ## Define admin layer
    my $admin_table = alDente::Admin::Admin_page( $dbc, -reduced => 0, -department => 'Epigenomics', -form_name => 'Admin_layer' );

    ## Define the layers of the Template Department
    my $layers = { "Lab" => $plates . $solution . $equip, };

    #	      "Database" => $search_create_box . lbr . $extra_links

    my @order = ( 'Lab', 'Database' );

    if ( grep( /Admin/, @{ $Access{'Epigenomics'} } ) ) {
        require alDente::Rack_Views;
        push( @order, 'Admin', 'In Transit' );
        $layers->{"Admin"} = $admin_table;

    }

    return define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => \@order,
        -default   => $open_layer
    );
}

return 1;
