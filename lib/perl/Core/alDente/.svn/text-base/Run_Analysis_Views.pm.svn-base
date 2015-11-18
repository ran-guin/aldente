####################
# Work_Request_Views.pm #
####################
#
# This contains various Work_Request view pages directly
#

package alDente::Run_Analysis_Views;

use RGTools::RGIO;
use RGTools::Views;
use SDB::HTML;
use alDente::Tools;
use CGI qw(:standard);
use strict;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Settings);

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->{dbc} = $dbc;

    return $self;
}

######################################################
##          Views                                  ##
######################################################
############################
sub display_list_page {
############################

    my $q    = CGI->new;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

}

sub display_run_analysis_views {
    my $self               = shift;
    my %args               = filter_input( \@_ );
    my $run_analysis_views = $args{-run_analysis_views};
    my $order              = $args{-order};
    my $layers;
    my $title = Views::Heading("Run Analysis Status Report");
    if ($order) {
        $layers = define_Layers(
            -layers     => $run_analysis_views,
            -format     => 'tab',
            -name       => "Run Analysis",
            -tab_width  => 200,
            -tab_offset => 150,
            -order      => $order,
            -tab_colour => '#999999',
            -off_colour => '#cccccc'
        );
    }
    else {
        $layers = define_Layers(
            -layers     => $run_analysis_views,
            -format     => 'tab',
            -name       => "Run Analysis",
            -tab_width  => 200,
            -tab_offset => 150,
            -tab_colour => '#999999',
            -off_colour => '#cccccc'
        );
    }
    my $output = $title . $layers;
    return $output;
}

return 1;
