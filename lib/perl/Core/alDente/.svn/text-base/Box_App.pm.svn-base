##################
# Box_App.pm #
##################
#
# This module is used to monitor Boxs for Library and Project objects.
#
package alDente::Box_App;

## Standard modules required ##

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML qw(vspace HTML_Dump);

use alDente::Box;
use alDente::Box_Views;
use alDente::Barcoding;

##############################
# global_vars                #
##############################
use vars qw(%Configs);    # $current_plates $testing $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'Throw Away Box'       => 'throw_away_Box',
            'Open Box'             => 'open_Box',
            'Home Page'            => 'home_page',
            'Re-Print Box Barcode' => 'reprint_Barcode',
        }
    );

    my $dbc = $self->param('dbc');

    my $q = $self->query();
    my $id = $q->param('Box_ID') || $q->param('ID');
    if ($id) {
        my $Box = new alDente::Box( -dbc => $dbc, -id => $id );

        $self->param( 'Box_Model' => $Box, );
    }

    return $self;
}

#######################
sub throw_away_Box {
#######################
    my $self = shift;
    my $q    = $self->query();

    my $confirmed = $q->param('Confirmed');
    my @box_ids   = $q->param('Box_ID');
    my $dbc       = $self->param('dbc');

    my $boxes = join( ',', @box_ids );
    return $self->param('Box_Model')->throw_away( -ids => $boxes, -confirmed => $confirmed );
}

#####################
sub open_Box {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query();

    my $box_id = $q->param('Box ID') || $q->param('Box_ID');
    my $type = $q->param('Boxed Items');

    my $Box = $self->param('Box_Model');

    $Box->open_box( -box_id => $box_id, -type => $type );

}

##################
sub home_page {
##################
    my $self = shift;

    my $dbc = $self->param('dbc');
    my $Box = $self->param('Box_Model');
    return alDente::Box_Views->home_page( -dbc => $dbc, -Box => $Box );
}

#########################
sub reprint_Barcode {
#########################
    my $self   = shift;
    my $dbc    = $self->param('dbc');
    my $q      = $self->query();
    my $box_id = $q->param('Box ID') || $q->param('Box_ID') || $q->param('ID');

    my $ok = &alDente::Barcoding::PrintBarcode( $dbc, 'Box', $box_id );
    return "$ok Barcode(s) Printed";
}

return 1;
