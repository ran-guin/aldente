###################################################################################################################################
# alDente::Transform_Views.pm
#
# Interface generating methods for the Transform MVC  (associated with Transform.pm, Transform_App.pm)
#
###################################################################################################################################
package alDente::Transform_Views;
use base alDente::Object_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Import_Views;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use vars qw( %Configs );

my $q = new CGI;
#############################################
#
# Standard view for single Transform record
#
#
# Return: html page
###################
sub home_page {
###################
    my $self = shift;
    my %args = filter_input( \@_, 'id' );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $Import_View = new SDB::Import_Views( -dbc => $dbc );

    return $Import_View->upload_file_box(
        -type            => 'Xref_File',
        -button          => $q->submit( -name => 'rm', -value => 'Upload Library Info', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form, 4)' ),
        -cgi_application => 'alDente::Transform_App',
        -dbc             => $dbc
    );

}

#############################################################
# Standard view for multiple Transform records if applicable
#
#
# Return: html page
#################
sub list_page {
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $id   = $args{-id};

    my $Transform = $self->param('Transform');
    my $dbc       = $Transform->param('dbc');

    my $page;

    return $page;
}

######################
sub show_Plate_to_Source_option {
######################
    my %args     = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc      = $args{-dbc};
    my $rack_id  = $args{-rack_id};
    my $plates   = $args{-plate};
    my @tray_ids = $dbc->Table_find( "Plate_Tray,Plate", "distinct FK_Tray__ID", "WHERE FK_Plate__ID IN ($plates) AND FK_Plate__ID = Plate_ID and Plate_Type = 'Tube'" );
    require alDente::Tray_Views;
    my $tray_view = alDente::Tray_Views->new( -dbc => $dbc );
    s/^/Tra/g foreach @tray_ids;    ##Without this tray_of_tube_box will break

    my $tree;
    my $well_table;
    my $page
        = alDente::Form::start_alDente_form( -dbc => $dbc )
        . alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Storage_Medium__ID', -table => 'Source', -id => )
        . vspace()
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Redefine Plates as Sources', -force => 1, -class => 'Action' ), 'This will throw away the plates and redefine those records as sources' )
        . Show_Tool_Tip( $q->checkbox( -name => 'Suppress Barcodes', -checked => 0 ), 'will not auto-generate barcodes automatically' )
        . Show_Tool_Tip( $q->checkbox( -name => 'Reset Labels',  -checked => 0 ), 'will reset labels for samples' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Transform_App', -force => 1 )
        . $q->hidden( -name => 'plates', -value => $plates, -force => 1 )
        . vspace();

    for my $tray_id (@tray_ids) {
        $well_table .= $tray_view->tray_of_tube_box( -tray_id => $tray_id, -resolve => 1, -default_checked => 1 );

    }
    $tree = create_tree( -tree => { "Select wells to INCLUDE" => $well_table }, -print => 0 );

    $page .= $tree . $q->end_form();

    return $page;
}
1;
