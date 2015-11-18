###################################################################################################################################
# Template::Run_Views.pm
#
#
#
#
###################################################################################################################################
package Template::Run_Views;

use strict;
use CGI qw(:standard);

use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use RGTools::RGIO;
use RGTools::Views;
use alDente::Run;
use vars qw( $Connection $user_id $homelink %Configs );



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


###########################
sub display_Template_main {
###########################
# 
#
# Usage:  
#
# Output: 
#
###########################
    my $self = shift;
    my %args = filter_input(\@_,-args=>'data');
    my $data = $args{-data};
    
    my $view ;
    
    return $view;
}

1;
