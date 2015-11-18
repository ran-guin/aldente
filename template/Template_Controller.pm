###################################################################################################################################
# Sequencing::Statistics.pm
#
#
#
#
###################################################################################################################################
package Sequencing::Template_Controller;

use strict;
use CGI qw(:standard);


use Imported::CGI_App::Application;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;

## RG Tools
use RGTools::RGIO;

## alDente modules


use Sequencing::Template_View;
use Sequencing::Template;

use vars qw( $Connection $user_id $homelink %Configs );

use base 'CGI::Application';


#####################
# 
# Intercept the new() method and store the $dbc in the object
#
#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input(\@_);
    my $dbc = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->{dbc} = $dbc;
    return $self->SUPER::new();
}

sub setup {
    my $self = shift;
    $self->start_mode('main_page');

    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes(
        'main_page' => 'main_page',
        'display_secondary_page' => 'display_secondary_page'
    );
}
sub main_page {
    my $self = shift;
    my $output;
    
    my $template_model_obj = Sequencing::Template->new(-dbc=>$self->{dbc});
    
    my $data = $template_model_obj->get_template_data();
    
    my $template_view_obj = Sequencing::Template_View->new();
   
    $output = $template_view_obj->display_template_main(-data=>$data);
     
    return $output;
}   

sub display_secondary_page {
    my $self = shift;
    my $output;
    
    my $template_view_obj = Sequencing::Template_View->new();

    $output = $template_view_obj->display_secondary_page();
    
    return $output;
}




1;
