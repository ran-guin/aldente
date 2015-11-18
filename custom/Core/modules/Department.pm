package Core::Department;

use base Main::Department;

use strict;
use warnings;

use RGTools::RGIO;


## Specify the icons that you want to appear in the top bar

my @icons_list = qw( LIMS_Help );

########################################
sub home_page {
#################
    my $self = shift;
    my %args = filter_input( \@_ );

    return Core::Views::home_page(%args);

}

1;
