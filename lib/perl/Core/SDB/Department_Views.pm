###################################################################################################################################
# alDente::Department_Views.pm
#
#
#
#
###################################################################################################################################
package SDB::Department_Views;

use CGI qw(:standard);
use base SDB::DB_Object_Views;

use strict;
## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;

my $q = new CGI;

###############
sub home_page {
###############
    my $self = shift;
    my %args       = filter_input( \@_ );
    my $Department = $args{-Department} || ref $self;

    $Department =~s/::Department_Views$//;
    
    return "<h2>$Department home page not set up</h2>";

}

###########
sub logo {
###########
    my $self = shift;
    my $dbc = $self->dbc();

    my $logo = $dbc->config('images_url_dir') . '/' . $dbc->config('custom_version_name') . '.logo.png';
    my $output = "<IMG SRC='$logo'  class='logo' >\n";
    return $output;
}

1;
