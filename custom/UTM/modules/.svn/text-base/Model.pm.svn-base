package UTM::Model;

use strict;
use warnings;

use UTM::Views;

## Specify the icons that you want to appear in the top bar

my @icons_list = qw( LIMS_Help Contacts);

########################################
sub home_page {
    my $self = shift;
    my %args = filter_input( \@_ );

    return UTM::Views::home_page(%args);

}   

#
#
######################
sub get_greys_and_omits {
######################

    my @greys = ();
    my @omits = ();

    return ( \@greys, \@omits );

}

#
#<snip>
#
#</snip>
###################################
sub get_searches_and_creates {
###################################

    my %args   = @_;
    my %Access = %{ $args{-access} };

    my @creates  = ('');
    my @searches = ('');

    @creates  = sort @{ unique_items( [ sort(@creates) ] ) };
    @searches = sort @{ unique_items( [ sort(@searches) ] ) };

    return ( \@searches, \@creates );

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

#######################
sub get_custom_icons {
#######################
    my %images;

    $images{LIMS_Help}{icon} = "help.gif";
    $images{LIMS_Help}{url}  = "cgi_application=UTM::App&rm=Help";
    $images{LIMS_Help}{name} = "LIMS Help";

    return \%images;
}


return 1;
