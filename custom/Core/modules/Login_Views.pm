###################################################################################################################################
# LampLite::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package Core::Login_Views;

use base SDB::Login_Views;

use strict;

## Standard modules ##
use LampLite::CGI;


use RGTools::RGIO;
use RGTools::Views;
#use RGTools::HTML_Table;

use SDB::HTML;
use LampLite::Bootstrap();

my $q = new LampLite::CGI;
my $BS = new Bootstrap();

############## 
sub relogin {
##############
    my $self = shift;
    my %args = @_;
    return $self->SUPER::relogin(%args);
}

# Return: customized footer spec
#############
sub footer {
#############
     my $self = shift;   
    return; 
}

#
# custom login page (may call standard login page with extra sections appended)
#
# CUSTOM - move app to same level (not SDB::Session)
#############################################################
#
#
#
# Return: html page
#############################################################
sub display_Login_page {
#############################################################
    my $self     = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->param('dbc');

    my @login_extras;
    my $other_versions = $self->aldente_versions( -dbc => $dbc );
    push @login_extras, ['Other Versions:', $other_versions];
    
    my $page = $self->SUPER::display_Login_page(%args, -append=>\@login_extras, -app=>'Core::Login_App', -clear=>['Database_Mode', 'CGISESSID'], -title=>"Log In");
    return "<center><div style='max-width:500px'>\n$page</div></center>\n"

}

#############################################################
#
# Move to Core scope ... 
#
#############################################################
sub aldente_versions {
#############################################################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $dbc            = $args{-dbc} || $self->param('dbc');

    my $other_versions = '';

    my $master = 'hblims01';
    my $dev    = 'hblims01';
    my $domain = '.bcgsc.ca';
    
    my $file = $dbc->config('custom_version_name') || 'SDB.pl';
    
    my $Target = {
        'Production' => "http://$master$domain/SDB/cgi-bin/$file?Database_Mode=PRODUCTION",
        'Test' => "http://$master$domain/SDB_test/cgi-bin/$file?Database_Mode=TEST",
        'Alpha' => "http://$dev$domain/SDB_alpha/cgi-bin/$file?Database_Mode=DEV",
        'Beta' => "http://$master$domain/SDB_beta/cgi-bin/$file?Database_Mode=BETA",
        'Development' => "http://$dev$domain/SDB_dev/cgi-bin/$file?Database_Mode=DEV",    
    };

    my @versions = qw(Production Test Alpha Beta Development);
    foreach my $ver (@versions) {
        my $URL = $Target->{$ver};

        $other_versions .= "<li> <a href='$URL'>$ver version</a></li>\n";
    }
    return $other_versions;
}

1;
