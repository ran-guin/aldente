package Core::Site_Admin::Department;

use base Site_Admin::Department;

use strict;
use warnings;

use RGTools::RGIO;


## Specify the icons that you want to appear in the top bar

my @icons_list = qw( LIMS_Help );


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

    return $self->View->home_page(%args);
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
    my $navbar = 1;                                                          ## flag to turn on / off dropdown navigation menu

    my $class = 'iconmenu';
    if ($navbar) { $class = 'dropnav' }

    return $class;
}

1;
