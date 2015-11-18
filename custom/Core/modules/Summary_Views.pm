package Core::Summary_Views;

use base Core::Views;

use strict;
use warnings;

use RGTools::RGIO;
use SDB::HTML;

use Core::Model;
use LampLite::Bootstrap;
use LampLite::CGI;

##############################
# global_vars                #
##############################

my $BS = new Bootstrap;
my $q = new LampLite::CGI;

my ( $session, $account_name );

############################
sub prompt_for_summary {
############################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'dbc,prefix');
    my $dbc = $args{-dbc} || $self->{dbc};
    my $prefix = $args{-prefix};   ## specify prefix for samples (eg BC or SHE)
    my $layer  = $args{-layer};

    my $layered;
    if ($layer) { $layered = "[ by $layer]" }

    return 'summary';
}

return 1;
