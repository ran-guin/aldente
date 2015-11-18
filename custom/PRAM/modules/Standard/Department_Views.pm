###################################################################################################################################
# Public::Department_View.pm
#
#
#
#
###################################################################################################################################
package PRAM::Standard::Department_Views;

use base PRAM::Department_Views;

use strict;

## RG Tools
use SDB::HTML;

use RGTools::RGIO;

use LampLite::CGI;
use LampLite::Bootstrap;

my $q = new LampLite::CGI;
my $BS = new Bootstrap;

#
# Usage: 
#   my $view = $self->display(-data=>$data);
#
# Returns: Formatted view for the raw data
###########################
sub display {
###########################
    my $self = shift;
    my %args = filter_input(\@_,-args=>'data');
    my $data = $args{-data};
    
    ## Format the raw data into a viewable form (ie HTML)
    my $view;
    
    return $view;
}

################
sub home_page {
################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->{dbc};

    return "Customized Standard HOME PAGE";
}

1;
