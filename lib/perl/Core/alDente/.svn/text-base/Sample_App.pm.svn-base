##################
# Sample_App.pm #
##################
#
# This is a Sample for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Sample_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use SDB::HTML;
use alDente::Sample_Views;
use alDente::Sample;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'home_page'        => 'home_page',
            'lineage_page'     => 'lineage_page',
            'default_page'     => 'default_page',
            'list_page'        => 'list_page',
            'Mix Sample Types' => 'mix_Sample_Types',

        }
    );

    my $dbc = $self->param('dbc');

    ## enable related object(s) as required ##
    my $sample       = new alDente::Sample( -dbc       => $dbc );
    my $sample_views = new alDente::Sample_Views( -dbc => $dbc );

    $self->param( 'Sample_Model' => $sample, );
    $self->param( 'Sample_View'  => $sample_views, );

    return $self;
}

#####################
#
# home_page (default)
#
# Return: display (table)
#####################
sub home_page {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    my $id   = $q->param('ID');

    my $Sample = new alDente::Sample( -dbc => $dbc, -id => $id );
    return $Sample->home_page;

    my $various_data;    ## accumulate data from models as required (preferably using simple and transparent accessor(s))

    my %organized_data = { 'data' => $various_data };    ## slightly more structured form for data to enable call to display

    return $self->_display_data( -data => %organized_data );    ## call wrapper for displaying data unless relatively trivial (keeps output format details localized)
}

#################################
sub mix_Sample_Types {
#################################
    my $self      = shift;
    my $dbc       = $self->param('dbc');
    my $q         = $self->query();
    my $View      = $self->param('Sample_View');
    my $Model     = $self->param('Sample_Model');
    my $confirmed = $q->param('confirmed');
    my $first     = $q->param('sample_type_1');
    my $second    = $q->param('sample_type_2');

    if ($confirmed) {
        return $Model->mix_Sample_types( -dbc => $dbc, -first => $first, -second => $second );

    }
    else {
        return $View->mix_Sample_types( -dbc => $dbc );
    }

}

sub list_page {
    my $self = shift;
    Message("No view currently defined for multiple samples");

}
############################
# Concise summary view of data
# (useful for inclusion on library home page for example)
#
# Return: display (table) - smaller than for show_Progress
############################
sub summary_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my %data;
    my @keys = sort keys %data;    ## specify order of keys in output if desired

    my $output = SDB::HTML::display_hash(
        -dbc         => $dbc,
        -hash        => \%data,
        -keys        => \@keys,
        -title       => 'Summary',
        -colour      => 'white',
        -border      => 1,
        -return_html => 1,
    );

    return $output;
}

##############################################
#
# Local version of display if not standardized externally
#
#######################
sub _display_data {
#######################
    my $self = shift;

    my %args  = &filter_input( \@_, -args => 'data', -mandatory => 'data' );
    my $data  = $args{-data};
    my $title = $args{-title};

    my $output = new HTML_Table( -title => $title, -class => 'small', -padding => 10 );
    $output->Set_Alignment( 'center', 5 );
    $output->Set_Headers( [ 'FK_Project__ID', "Library", 'Goal', 'Target<BR>(Initial + Work Requests)', 'Completed', ' (%)' ] );

    foreach my $lib ( sort keys %$data ) {
        $lib++;

        ## build up output table display ....
    }

    return $output->Printout(0);

}

return 1;
