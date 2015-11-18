###################################################################################################################################
# LampLite::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package GSC::Login_Views;

use base alDente::Login_Views;
use strict;

## Standard modules ##
use LampLite::CGI;
use LampLite::Bootstrap();

my $q  = new LampLite::CGI;
my $BS = new Bootstrap();

use RGTools::RGIO;
use GSC::Menu;


#
# Custom header definition
#
# utilizes local methods below to generate sections of header for: user / dept / help etc...
#
#
# Return: Header string
####################
sub header {
####################
    my $self = shift;
    my %args = filter_input( \@_ );

    $args{-text} = "<B>A</B>utomated <B>L</B>aboratory <B>D</B>ata <B>E</B>ntry <B>N</B>' <B>T</B>racking <B>E</B>nvironment";
    return $self->SUPER::header(%args);
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
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my @login_extras;

    my $checkbox = $q->checkbox( -name => 'Active Projects Only', -checked => 1, -force => 1 );
    push @login_extras, [ 'Options:', $checkbox ];

    push @login_extras, [ '', '<hr>' ];

    my $other_versions = $self->aldente_versions( -dbc => $dbc );
    push @login_extras, [ 'Other Versions:', $other_versions ];

    return $self->SUPER::display_Login_page( %args, -append => \@login_extras, -app => 'alDente::Login_App', -clear => [ 'Database_Mode', 'CGISESSID' ], -choose_printer => 1 );
}

#############################################################
#
# Move to GSC scope ...
#
#############################################################
sub aldente_versions {
#############################################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my $other_versions = '';

    my $master = 'lims08';
    my $dev    = 'lims11';
    my $domain = '.bcgsc.ca';

    my $Target = {
        'Production'  => "http://$master$domain/SDB/cgi-bin/barcode.pl",
        'Test'        => "http://$master$domain/SDB_test/cgi-bin/barcode.pl",
        'Alpha'       => "http://$dev$domain/SDB_alpha/cgi-bin/alDente.pl",
        'Beta'        => "http://$dev$domain/SDB_beta/cgi-bin/alDente.pl",
        'Development' => "http://$dev$domain/SDB_dev/cgi-bin/alDente.pl",
    };

    my @versions = qw(Production Test Alpha Beta Development);
    foreach my $ver (@versions) {
        my $URL = $Target->{$ver};

        $other_versions .= "<li> <a href='$URL'>$ver version</a></li>\n";
    }
    return $other_versions;
}

1;
