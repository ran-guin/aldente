package Lib_Construction::Department_Views;

use base alDente::Department_Views;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use SDB::Import;

use vars qw(%Configs);

## Specify the icons that you want to appear in the top bar

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my $dbc = $self->{dbc};
    
    return $self->Model->home_page(-dbc=>$dbc);
}

########################################
#
#  Summary page for this department
#
##############################
sub summary_page {
##############################
    my $self = shift;
    my $dbc = shift || $self->{dbc};

    my $reports      = alDente::Department::prep_summary_box( -dbc => $dbc );
    my $run_summary  = view_summary_box();
    my $view_summary = alDente::Department::view_summary_box( -dbc => $dbc );

    my $layers = {
        'Reports'      => $reports,
        'Run_Summary'  => $run_summary,
        'View_Summary' => $view_summary,
    };

    my $open_layer = 'Reports';
    my $output     = &define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -default   => $open_layer
    );

    return $output;
}

####################
sub view_summary_box {
####################
    my $dbc = shift;

    my $views = alDente::Department::_init_table('Run Views');
    $views->Set_Headers( [ 'View Name', 'Description' ] );
    $views->Set_Row( [ &Link_To( $dbc->{homelink}, "Solexa run search",   "&cgi_application=Illumina::Solexa_Summary_App" ), "Search for information on Solexa runs" ] );
    $views->Set_Row( [ &Link_To( $dbc->{homelink}, "Run Analysis Report", "&cgi_application=alDente::Run_Analysis_App" ),    "Run Analysis Reports" ] );
    return start_custom_form( 'RunViews', $dbc->{homelink} ) . $views->Printout(0) . end_form();
}

#
# Moved from Home Page to speed up
#
#
##################################
sub RNA_DNA_Collection_Options {
##################################
    my $dbc = shift;

    my $layers = {};

    my $lib = new alDente::RNA_DNA_Collection( -dbc => $dbc );
    my @order;
    my $library_layers = $lib->library_main( -form_name => 'Admin_layer', -get_layers => 'RNA/DNA Collection Options', -dbc => $dbc );
    if ( defined %$library_layers ) {
        foreach my $key ( keys %$library_layers ) {
            $layers->{"$key"} = $library_layers->{$key};
            push( @order, "$key" );
        }
    }
    elsif ($library_layers) { return; }    ## returns 1 if generating a page of its own ...

    my $output = &define_Layers( -layers => $layers, -order => \@order );

    return $output;
}

return 1;
