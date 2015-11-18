###################################################################################################################################
#
#
#
#
###################################################################################################################################
package alDente::Project_App;
use base alDente::CGI_App;
use strict;

## RG Tools
use RGTools::RGIO;
## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use alDente::Project;
use alDente::Project_Views;
use alDente::Import_Views;

use vars qw( %Configs);
my $q = new CGI;
#####################
sub setup {
#####################
    my $self = shift;
    $self->start_mode('entry_page');
    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes(
        'entry_page'               => 'entry_page',
        'Show Published Documents' => 'get_Published_Documents',
        'Show Project Libraries'   => 'show_Project_libs',
        'List Projects'  => 'list_Projects',
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $dbc = $self->param('dbc');
    $self->param( 'Model' => alDente::Project->new( -dbc => $dbc ), );

    return $self;
}

###########################
sub list_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $list = $q->param('list') || $args{-list};
    my $view = $dbc->Table_retrieve_display(
        -table => "Project",

        # -fields      => [ 'Solution_ID', 'Stock_Catalog_Name', 'Solution_Type', 'FK_Rack__ID', 'Stock_Received' ],
        -return_html => 1,
    );
    return $view;
}

###########################
sub entry_page {
###########################
    my $self       = shift;
    my %args       = @_;
    my $q          = $self->query;
    my $dbc        = $self->param('dbc') || $args{-dbc};
    my $id         = $q->param('ID');
    my $department = $q->param('Department');

    unless ($id) { return $self->main_page( -dbc => $dbc, -department => $department ) }
    if ( $id =~ /,/ ) { return $self->list_page( -dbc => $dbc, -list => $id ) }
    else              { return $self->home_page( -dbc => $dbc, -id => $id ) }
    return 'Error: Inform LIMS';
}

###########################
sub main_page {
###########################
    #
    # General Equipment home page...
    #
    # This is NOT used for scanner mode
    #
###########################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $dbc        = $self->param('dbc');
    my $department = $q->param('Department') || $args{-department};

    return alDente::Project_Views::list_projects( -dbc => $dbc, -department => $department );
}

###########################
sub home_page {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $id   = $args{-id};

    my $model = alDente::Project->new( -dbc => $dbc, -id => $id );
    my $page = alDente::Project_Views::home_info($model);
    return $page;
}

#####################
sub get_Published_Documents {
#####################
    my $self   = shift;
    my $dbc    = $self->param('dbc');
    my $model  = $self->param('Model');
    my $id     = $q->param('Project_ID') || $self->param('Project_ID');
    my $files  = $model->get_Published_files( -id => $id );
    my $output = alDente::Import_Views::display_Published_Documents( -files => $files, -dbc => $dbc );
    return $output;

}

#############################
sub show_Project_libs {
#############################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $project_id = $q->param('Project_ID');
    my $order = join ',', $q->param('Order By');

    Message("ORDERING BY $order.") if $order;

    my $lib_type = $q->param('Library_Type');      ## specify Sequencing_Library or RNA_DNA_Collection
    my $libs = join ',', $q->param('Libraries');

    return alDente::Project_Views::show_Project_libraries( -dbc => $dbc, -project_id => $project_id, -order_by => $order, -libraries => $libs, -lib_type => $lib_type );
}

####################
sub list_Projects {
####################
    my $self = shift;
    
    my ($P_layers, $P_order) = $self->Model->get_projects( );

    my $output = define_Layers(
        -layers    => $P_layers,
        -tab_width => 100,
        -order     => $P_order,
        );

    return $output;
}

1;
