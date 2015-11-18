package UTM::Views;

use strict;
use warnings;

use RGTools::RGIO;

use UTM::Model;

use LampLite::Bootstrap;
my $BS = new Bootstrap;

## Specify the icons that you want to appear in the top bar

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    return 'home';
}

return 1;
