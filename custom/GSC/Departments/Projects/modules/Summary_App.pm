###################################################################################################################################
# Projects::Summary_App.pm
#
#
#
# Written By: Ash Shafiei September 2008
###################################################################################################################################
package Projects::Summary_App;

use base RGTools::Base_App;
use strict;
use Data::Dumper;

## SDB modules
#use SDB::CustomSettings;
#use SDB::DBIO;
use SDB::HTML;
## RG Tools
#use RGTools::RGIO;
#use RGTools::Views;

## alDente modules
#use alDente::Form;

use vars qw($Connection $user_id $homelink %Configs );

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('Default Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes( 'Default Page' => 'summary_page' );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    return 0;

}

###########################
sub summary_page {
###########################
    my $self   = shift;
    my $q      = $self->query;
    my $dbc    = $self->param('dbc');
    my $output = define_Layers(
        -layers => {
            "Microarray"       => ' ',                    #microarray_stat (-dbc => $dbc),
            "Mapping"          => ' ',                    #mapping_stat (-dbc => $dbc),
            "Lib_Construction" => 'Under Construction',
            "Cap_Seq"          => 'Under Construction'
        },
        -tab_width => 100,
        -order     => 'Cap_Seq,Lib_Construction,Mapping,Microarray',
        -default   => 'Lib_Construction'
    );

    return $output;
}

1;
