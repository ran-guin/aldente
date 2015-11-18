#!/usr/bin/perl
###################################################################################################################################
# Original_Source.pm
#
###################################################################################################################################
package alDente::Original_Source;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;
##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DBIO;
use SDB::DB_Object;

use SDB::DB_Form_Viewer;
use SDB::DB_Form;
use SDB::Session;
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::Conversion;
use alDente::Source;
use alDente::Tools;
use alDente::Attribute_Views;
##############################
# global_vars                #
##############################
use vars qw($dbc $Session $Sess);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

### Global variables

### Modular variables

###########################
# Constructor of the object
###########################
sub new {
    my $this  = shift;
    my %args  = @_;
    my $class = ref($this) || $this;

    my $os_id = $args{-original_source_id} || $args{-id};                                       # required
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $tables = $args{-tables};

    if ( !$tables ) {
        if   ( $dbc->package_active('Taxonomy') ) { $tables = 'Original_Source,Taxonomy'; }
        else                                      { $tables = 'Original_Source'; }
    }

    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => $tables );

    if ($os_id) {
        $self->primary_value( -value => $os_id );
        $self->{id} = $os_id;
    }

    $self->{dbc} = $dbc;

    $self->load_Object();
    $self->{id} = $self->value('Original_Source_ID');
    bless $self, $class;
    return $self;

}

##############################
# public_methods             #
##############################

##############################
# calls the DBObject's load_Object method and performs other object specific actions
#
# $self->load_Object();
#
# Returns: $self
#
##############################
sub load_Object {
####################
    my $self = shift;
    $self->SUPER::load_Object();
    return $self;
}

##############################
# Home info page for individual sources
##############################
sub home_page {
##################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my $info;
    my $orig_src_name = $self->value('Original_Source.Original_Source_Name');
    my $header        = $self->label() . '<BR>' . alDente::Attribute_Views::show_attribute_link( "Original_Source", $self->{id}, -dbc => $dbc );
    my $lib_list      = join '<LI>', map { &alDente_ref( 'Library', -name => $_, -dbc => $dbc ) } $self->collections;
    my $source_list   = join '<LI>', map { my $id = $_; alDente::Source_Views->foreign_label( -dbc => $dbc, -id => $id ) } $self->sources;         ## &alDente_ref( 'Source', $_ ) } $self->sources;

    my $create_new_library
        = "<B>Libraries/Collections:</B>" 
        . lbr
        . &Link_To( $dbc->config('homelink'), "Add New (With Source Tracking)", "&Create+New+Library=1&FK_Original_Source__ID=$self->{id}&Grey=FK_Original_Source__ID&Source+Tracking=Yes", $Settings{LINK_COLOUR} )
        . lbr
        . &Link_To( $dbc->config('homelink'), "Add New (Without Source Tracking)", "&Create+New+Library=1&FK_Original_Source__ID=$self->{id}&Grey=FK_Original_Source__ID&Source+Tracking=No", $Settings{LINK_COLOUR} )
        . "<UL><LI>$lib_list</UL>";

    my $create_new_source
        = "<B>Sources:</B>" 
        . lbr
        . &Link_To( $dbc->config('homelink'), "Add New", "&cgi_application=alDente::Source_App&rm=Add+Source&Original_Source_ID=$self->{id}&Library+Tracking=Yes", $Settings{LINK_COLOUR} )
        . lbr
        . &Link_To( $dbc->config('homelink'), "Add New (Without Libray)", "&cgi_application=alDente::Source_App&rm=Add+Source&Original_Source_ID=$self->{id}&Library+Tracking=No", $Settings{LINK_COLOUR} )

        . "<UL><LI>$source_list</UL>";

    my $create_table = HTML_Table->new();
    $create_table->Set_Class('small');
    $create_table->Set_Width('100%');
    $create_table->Toggle_Colour('off');
    $create_table->Set_Line_Colour( '#eeeeff', '#eeeeff' );
    $create_table->Set_Row( [$create_new_source] );
    $create_table->Set_Row( [$create_new_library] );

    #     $create_table->Set_Row([$attributes]);
    my $list_sources_table = &alDente::Source::get_offspring_details( -dbc => $self->{dbc}, -id => $self->{id} );

    $info .= $header;
    $info .= '<BR><BR>';
    $info .= alDente::Original_Source_Views::ancestry_view( -id => $self->{id}, -dbc => $dbc );
    $info .= alDente::Original_Source_Views::source_ancestry_view( -id => $self->{id}, -dbc => $dbc );

    $info .= '<BR><BR>';
    $info .= $create_table->Printout(0) . '<BR>';
    $info .= $list_sources_table;
    my $details = '';
    $details = $self->display_Record() unless ($scanner_mode);

    my %colspan;
    $colspan{1}->{1} = 2;    ### Set the Heading to span 2 columns
    $colspan{2}->{2} = 2;    ### Set the 'Stats' cell to span 2 columns
    return Views::Table_Print( content => [ [ &Views::Heading($orig_src_name) ], [ $info, $details ] ], spacing => 5, colspan => \%colspan, -return_html => 1 );
}

###############
sub sources {
###############
    my $self    = shift;
    my $id      = $self->value('Original_Source_ID');
    my @sources = $self->{dbc}->Table_find( 'Source', 'Source_ID', "WHERE FK_Original_Source__ID = $id" );

    return @sources;
}

####################
sub collections {
####################
    my $self        = shift;
    my $id          = $self->value('Original_Source_ID');
    my @collections = $self->{dbc}->Table_find( 'Library', 'Library_Name', "WHERE FK_Original_Source__ID = $id" );

    return @collections;
}

##############
sub label {
##############
    my $self = shift;
    my $dbc = $self->{dbc};

    my $orig_src_name = $self->value('Original_Source_Name');
    my $organism;
    my $type = $self->value('Original_Source_Type');
    my $strain;
    my $stage;

    if ( $self->{dbc}->package_active('Taxonomy') ) {
        $organism = $self->value('Taxonomy_Name');
    }

    if ( $self->{dbc}->package_active('Genomic') ) {
        $strain = $self->value('FK_Strain__ID');
    }

    if ( $self->{dbc}->package_active('GSC') ) {
        $stage = $self->value('FK_Stage__ID');
    }

    #  my $anatomic_site  = $self->value('Anatomic_Site_Alias');

    my $label = "<B>$orig_src_name</B><BR>";
    $label .= "$type - $organism <BR>" if $organism;
    $label .= "$strain Strain<BR>"     if $strain;
    $label .= alDente_ref( 'Stage', $stage, -dbc => $dbc ) . " Stage<BR>" if $stage;

    return $label;
}

return 1;
##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################
