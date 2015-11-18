#!/usr/bin/perl -w
###################################################################################################################################
# Projects::Statistics_App.pm
#
#
#
# By Ash Shafiei, September 2008
###################################################################################################################################
package Projects::Statistics_App;

use base RGTools::Base_App;
use strict;

use Data::Dumper;

## SDB modules
#use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;

#use RGTools::Views;

## alDente modules

#use alDente::Form;

use vars qw($Connection $user_id $homelink %Configs );

###########################
sub setup {
###########################
    my $self = shift;
    $self->start_mode('default page');
    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes( 'default page' => 'stat_page' );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    return 0;
}
###########################
sub stat_page {
###########################
    my $self   = shift;
    my $q      = $self->query;
    my $dbc    = $self->param('dbc');
    my $output = define_Layers(
        -layers => {
            "Microarray"       => microarray_stat( -dbc => $dbc ),
            "Mapping"          => mapping_stat( -dbc    => $dbc ),
            "Lib_Construction" => GE_stat( -dbc         => $dbc ),
            "Cap_Seq"          => sequencing_stat( -dbc => $dbc )
        },
        -tab_width => 100,
        -order     => 'Cap_Seq,Lib_Construction,Mapping,Microarray',
        -default   => 'Cap_Seq'
    );

    return $output;
}

###########################
sub GE_stat {
###########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $application = 'Lib_Construction::Statistics_App';
    eval "require $application";

    # construct object from default

    my $webapp = $application->new(
        PARAMS => {
            dbc         => $dbc,
            'Open View' => 0
        }
    );
    my $form .= $webapp->run();
    return $form;

}
###########################
sub mapping_stat {
###########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $application = 'Mapping::Statistics_App';
    eval "require $application";

    # construct object from default

    my $webapp = $application->new(
        PARAMS => {
            dbc         => $dbc,
            'Open View' => 0
        }
    );
    my $form .= $webapp->run();
    return $form;

}

###########################
sub microarray_stat {
###########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $application = 'Microarray::Statistics_App';
    eval "require $application";

    # construct object from default

    my $webapp = $application->new(
        PARAMS => {
            dbc         => $dbc,
            'Open View' => 0
        }
    );
    my $form .= $webapp->run();
    return $form;

}

###########################
sub sequencing_stat {
###########################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $application = 'Sequencing::Stat_App';
    eval "require $application";

    # construct object from default

    my $webapp = $application->new(
        PARAMS => {
            dbc         => $dbc,
            'Open View' => 0
        }
    );
    my $form .= $webapp->run();
    return $form;

}
1;
