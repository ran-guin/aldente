package QC::Department;
use base alDente::Department;

use strict;
use warnings;
use CGI('standard');
use Data::Dumper;
use Benchmark;

use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::QC_Batch_Views;
use alDente::Equipment;
use alDente::Equipment_Views;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;


## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Views Database Plates Solutions_App Equipment_App Dept_Projects Libraries Sources Pipeline Contacts Subscription);

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
    my $open_layer = $args{-open_layer} || 'QC_Batch';
    my $dept       = $args{-dept};

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    # This user does not have any permissions on Lab
    if ( !( $Access{'QC'} || $Access{'LIMS Admin'} ) ) {
        Message('no access');
        return;
    }
    alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    # Lab permissions for searches
    if ( grep( /Lab/, @{ $Access{$dept} } ) ) {
        push( @searches, qw(Box Contact Equipment Plate Run Solution Stock Process_Deviation ) );
        push( @creates,  qw(Plate Process_Deviation) );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{$dept} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{$dept} } ) ) {
        push @searches, qw(Employee Enzyme Funding Organization Primer Project Rack Collaboration QC_Type);
        push @creates,  qw(Collaboration Enzyme Funding Organization Project Study Stock_Catalog QC_Type QC_Batch_Member);
    }

    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    # my $search_create_box = alDente::Department::search_create_box( $dbc, \@searches, \@creates );

    #    my $project_list = &alDente::Project::list_projects( $dbc, "Project_Status = 'Active'" );

    my $maintenance_layer = alDente::Equipment_Views::maintenance_block($dbc) . '<hr>' . alDente::Equipment_Views::scheduled_maintenance( $dbc, -return_html => 1 );

    my $qc_layer = alDente::QC_Batch_Views::home_page($dbc);

    require alDente::Process_Deviation_Views;

    my $pd_layer = alDente::Process_Deviation_Views::home_page( -dbc => $dbc );

    my @order = ( 'Projects', 'Maintenance', 'QC_Batch', 'Database', 'Process_Deviation' );
    my $layers = {

        #        "Projects"          => $project_list,
        "Maintenance" => $maintenance_layer,
        "QC_Batch"    => $qc_layer,

        #"Database"          => $search_create_box,
        "Process_Deviation" => $pd_layer,
    };

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
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{QC} } ) ) {
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

###############################
sub get_searches_and_creates {
##############################

    my %args   = @_;
    my %Access = %{ $args{-access} };

    my @creates;
    my @searches;
    my @converts;

    # Lab permissions for searches
    if ( grep( /Lab/, @{ $Access{'QC'} } ) ) {
        push( @searches, qw(Box Contact Equipment Plate Run Solution Stock Process_Deviation ) );
        push( @creates,  qw(Plate Process_Deviation) );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{'QC'} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{'QC'} } ) ) {
        push @searches, qw(Employee Enzyme Funding Organization Primer Project Rack Collaboration QC_Type);
        push @creates,  qw(Collaboration Enzyme Funding Organization Project Study Stock_Catalog QC_Type QC_Batch_Member);
    }

    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    @creates  = sort @{ unique_items( [ sort(@creates) ] ) };
    @searches = sort @{ unique_items( [ sort(@searches) ] ) };
    @converts = sort @{ unique_items( [ sort(@converts) ] ) };

    return ( \@searches, \@creates, \@converts );

}

return 1;
