package Receiving::Department;

use base alDente::Department;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use SDB::DBIO;
use alDente::Validation;
use alDente::Stock_Views;

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Views Solutions_App Equipment_App  Summary_App Contacts Barcodes Rack);
my $icon_class = 'dropnav';                                                                   # 'iconmenu';

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc');
    my $dbc = $args{-dbc} || $self->dbc;

    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };

    #This user does not have any permissions on Lib_Construction
    if ( !( $Access{Receiving} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    alDente::Department::set_links($dbc);

    my @searches = qw(Contact Equipment Organization Stock);
    my @creates  = qw(Contact Organization);

    ###Catalog Number Section
    my $cat_num = alDente::Stock_Views::display_entry_page( -dbc => $dbc );

    ###Notification Section
    my $notification = alDente::Department::notify_box($dbc);

    ###Search for Stock Section
    my $stock_search = alDente::Stock_Views::search_stock_box( -dbc => $dbc );

    my $output = define_Layers(
        -layers => {
            "Purchasing"   => $cat_num,
            "Notification" => $notification,
            "Search"       => $stock_search,
            "Database"     => alDente::Department::search_create_box( $dbc, \@searches, \@creates )
        },
        ,
        -tab_width => 100,
        -order     => 'Purchasing,Notification,Search,Database',
        -default   => 'Purchasing'
    );

    return $output;
}

########################################
#
# Accessor function for the icons list
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

    return \%images;

}
#####################
sub get_icon_class {
####################
    return $icon_class;
}

return 1;
