package alDente::Public_Department;

use strict;
use warnings;
use CGI('standard');
use Data::Dumper;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use Mapping::Mapping_Summary;

use vars qw($Connection);

## Specify the icons that you want to appear in the top bar
my @icons_list = qw();

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

    alDente::Department::set_links();

    my @searches;
    my @creates;

    my $main_table = HTML_Table->new(
        -title    => "Public Home Page",
        -width    => '100%',
        -bgcolour => 'white'
    );

    my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID" );

    my @order = ( 'Projects', 'Lab', 'Summaries', 'Database' );

    my %layers;
    $layers{Projects} = &alDente::Project::list_projects();
    if ( $Configs{options} = ~/\bLab\b/ ) { $layers{Lab} = $main_table->Printout(0) }
    $layers{Database} = alDente::Department::search_create_box($dbc, \@searches, \@creates );

    return define_Layers(
        -layers    => \%layers,
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
