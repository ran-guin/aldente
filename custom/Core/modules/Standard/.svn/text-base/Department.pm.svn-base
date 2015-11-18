package Core::Standard::Department;

use base Core::Department;

use strict;
use warnings;

use RGTools::RGIO;
use LampLite::HTML;

use LampLite::Bootstrap;
use SDB::FAQ;

use Core::Standard::Department_Views;

my $BS = new Bootstrap;

my @icons_list = qw();


## Specify the icons that you want to appear in the top bar
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


return 1;
