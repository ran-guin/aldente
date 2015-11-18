###################################################################################################################################
# BASEDIR::Template_View.pm
#
#
#
#
###################################################################################################################################
package BASEDIR::Template_View;

use strict;
use CGI qw(:standard);

## SDB modules

## RG Tools
use RGTools::RGIO;

## alDente modules

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input(\@_);
    my $dbc  = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;
 
    if ($dbc) { $self->{dbc} = $dbc }
 
    return $self;
}


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

1;
