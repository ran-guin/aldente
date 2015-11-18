package Social::Views;

use base LampLite::Views;

use strict;
use warnings;
use Data::Dumper;
use Benchmark;

use RGTools::RGIO;

use Social::Model;

use LampLite::Bootstrap;
use LampLite::CGI;

use SDB::HTML;

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
    my $open_layer = $args{-open_layer} || 'Incoming Samples';

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

    my $datetime = &date_time;
    my $user     = $dbc->get_local('user_id');

    # This user does not have any permissions on Lab
    if ( !( $Access{'Social'} || $Access{'LIMS Admin'} ) ) {
        return;
    }

    return 'Home Page (customize)';    
}


    
##########################
sub show_discrepencies {
##########################

}

return 1;
