###################################################################################################################################
# Sequencing::Template_View.pm
#
#
#
#
###################################################################################################################################
package UTM::Template_View;

use strict;

## RG Tools
use RGTools::RGIO;

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input(\@_);

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;
 
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
