package PRAM::Views;

use base SDB::Department_Views;

use strict;
use warnings;

use RGTools::RGIO;
use PRAM::Model;
use LampLite::Bootstrap;
use LampLite::CGI;
use SDB::HTML;

##############################
# global_vars                #
##############################

my $BS = new Bootstrap;
my $q = new LampLite::CGI;

my ( $session, $account_name );

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $self = {};
    $self->{dbc} = $dbc;
    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my %args = filter_input( \@_, -args => 'dbc,open_layer', -mandatory => 'dbc' );
    my $dbc        = $args{-dbc}  ;

    return 'home page';
}


return 1;
