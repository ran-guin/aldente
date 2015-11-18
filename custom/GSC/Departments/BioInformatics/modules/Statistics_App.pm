###################################################################################################################################
# BioInformatics::Statistics_App.pm
#
#
#
#
###################################################################################################################################
package BioInformatics::Statistics_App;

use base RGTools::Base_App;
use CGI qw(:standard);
use Data::Dumper;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use Imported::CGI_App::Application;
use base 'CGI::Application';
use strict;
use alDente::Form;

Message('hello');

use vars qw( $Connection $user_id $homelink %Configs );

sub setup {
    my $self = shift;

    $self->start_mode('stat_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes( [ 'stat_page', 'display_stats' ] );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    return 0;

}

###########################
sub stat_page {
###########################
    my $self = shift;
    my $form;
    my $q = $self->query;

    $form .= start_custom_form( -name => 'stat results', -parameters => { &_alDente_URL_Parameters() } );
    $form .= Views::sub_Heading( "Statistics", -1 );
    $form .= "We are at BioInformatics stats";
    $form .= $q->hidden( -name => 'cgi_application', -value => 'BioInformatics::Statistics_App', -force => 1 );
    $form .= $q->hidden( -name => 'rm', -value => "display_stats", -force => 1 );
    $form .= $q->submit( -name => 'Action', -value => 'Display', -class => "Search", -force => 1 );
    $form .= "<span class=small>" . vspace() . "note: This button will take you to the display page" . "</span>";
    $form .= end_form();

    return $form;
}

###########################
sub display_stats {
###########################
    my $self = shift;
    my $form;
    my $q = $self->query;

    $form .= Views::sub_Heading( "Statistics", -1 );
    $form .= "Here's the display";

    return $form;
}
1;
