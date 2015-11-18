package GSC::Department;

use base alDente::Department;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;


## Specify the icons that you want to appear in the top bar

my @icons_list = qw( LIMS_Help Contacts Receive_Shipment Export);

########################################
sub home_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );

    return $self->View->home_page(%args);

}

return 1;
