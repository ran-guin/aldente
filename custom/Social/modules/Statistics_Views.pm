package Social::Statistics_Views;

use base Social::Views;

use strict;
use warnings;
use CGI qw(:standard);

use RGTools::RGIO;

use LampLite::Bootstrap;

my $BS = new Bootstrap;
my $q = new CGI;

#############
sub stats {
#############
    my $self = shift;
    my $condition = shift || 1;
    my $layer = shift;
 
    return 'generated custom stats...';
}

return 1;
