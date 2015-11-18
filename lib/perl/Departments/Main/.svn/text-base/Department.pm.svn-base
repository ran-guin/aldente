package Main::Department;

use base LampLite::DB_Object;

use strict;
use warnings;
use CGI('standard');
use Data::Dumper;
use Benchmark;

use RGTools::RGIO;
use LampLite::Bootstrap;

my $BS = new Bootstrap;

## Specify the icons that you want to appear in the top bar
my @icons_list;

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,open_layer');
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $open_layer = $args{-open_layer} || 'Projects';

    ### Permissions ###
    my $access =  $dbc->get_local('Access') ;
    my %Access = %{ $access } if $access;

    # This user does not have any permissions on Main
    if ( !( $Access{Main} || $Access{'LIMS Admin'} ) ) {
        return;
    }

#  alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    # Main permissions for searches
    if ( %Access &&  grep( /Main/, @{ $Access{Lab} } ) ) {
        push( @searches, qw(Collaboration Contact Equipment Library_Plate Plate Plate_Format Run Solution Stock Tube Vector_Type) );
        push( @creates,  qw(Plate Contact Source) );
    }

    # Admin permissions for searches
    if ( %Access &&  grep( /Admin/, @{ $Access{Main} } ) ) {
        push( @searches, qw(Employee Enzyme Funding Organization Primer Project Rack ) );
        push( @creates,  qw(Collaboration Employee Enzyme Funding Organization Plate_Format Project Rack Study) );
    }
    @creates  = @{ unique_items( [ sort(@creates) ] ) };
    @searches = @{ unique_items( [ sort(@searches) ] ) };

    my $main_table = HTML_Table->new(
        -title    => "Main Home Page",
        -width    => '100%',
        -bgcolour => 'white',
        -nolink   => 1,
    );

    my @layers = (
        { 'label' => 'Section 1', 'content' => 'Content for Section 1'},
        { 'label' => 'Section 2', 'content' => 'Content for Section 2'},
    ); 
    return $BS->layer(
        -layers    => \@layers,
        -tab_width => 100,
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

    my $access = $dbc->get_local('Access');
    my %Access = %{$access} if $access;
    if ( $Access{Public} && grep( /Admin/, @{ $Access{Public} } ) ) {
        push @icons_list, "Employee";
    }

    return \@icons_list;
}

#
#
####################
sub get_custom_icons {
####################
    my %images;
    return \%images;

}

# Return: default icon_class (may override in specific Department.pm module )
######################
sub get_icon_class {
#####################
    my $self = shift;
    my $navbar = 1;                                                          ## flag to turn on / off dropdown navigation menu

    my $class = 'iconmenu';
    if ($navbar) { $class = 'dropnav' }

    return $class;
}

return 1;
