package Core::Model;

use base SDB::Object;

use strict;
use warnings;

use CGI qw(:standard);
use Data::Dumper;

use RGTools::RGIO;

## Specify the icons that you want to appear in the top bar

my @icons_list = qw( LIMS_Help );

########################################
sub home_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );

    return $self->View->std_home_page(%args);

}
#
#
######################
sub get_greys_and_omits {
######################

    my @greys = qw( );
    my @omits = qw( );

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

    my @creates  = ();
    my @searches = ();

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
    $images{LIMS_Help}{url}  = "cgi_application=Core::App&rm=Help";
    $images{LIMS_Help}{name} = "LIMS Help";

    return \%images;
}

return 1;
