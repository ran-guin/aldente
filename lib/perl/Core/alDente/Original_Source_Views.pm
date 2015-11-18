###################################################################################################################################
#
###################################################################################################################################
package alDente::Original_Source_Views;

use base alDente::Object_Views;

use strict;
use CGI qw(:standard);

use vars qw(%Configs $Security);

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use RGTools::Conversion;
use RGTools::HTML_Table;
use RGTools::Directory;
use RGTools::RGIO;
use SDB::DBIO;
use SDB::DB_Object;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Original_Source;
use alDente::Import;
use alDente::Tools;

##############################
# global_vars                #
##############################
use vars qw(%Benchmark);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Local constants

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

########################################
# Generates a small label describing the container
#
# Options:
#  table type - returns small colour coded table cell
#  tooltip type - returns link to plate with details showing up as tooltip
#  details type - returns details of plate in text string (can be used for external tooltips) #
#
# Returns a string containing info about a container
####################
sub object_label {
####################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'id,include' );
    my $dbc  = $args{-dbc} || $self->{dbc} ;

    my $id = $args{-id} || $self->{id};
    my $type = $args{-type} || 'table';    ## eg 'tooltip', 'table', or 'details'

    return $self->Model->label();
}


##########################
sub display_record_page {
##########################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $id    = $args{-id} || $self->{id};
    my $OS = $args{-Original_Source} || $self->Model( -id => $id );    ## new alDente::Container( -id => $id, -dbc => $dbc );

    my $dbc = $self->{dbc};
    
    my $lib_list      = join '<LI>', map { &alDente_ref( 'Library', -name => $_, -dbc => $dbc ) } $OS->collections;
    my $source_list   = join '<LI>', map { my $id = $_; alDente::Source_Views->foreign_label( -dbc => $dbc, -id => $id ) } $OS->sources;                        ## &alDente_ref( 'Source', $_ ) } $self->sources;
    
    my $create_new_library
        = "<B>Libraries/Collections:</B>" 
        . lbr
        . &Link_To( $dbc->homelink(), "Add New (With Source Tracking)", "&Create+New+Library=1&FK_Original_Source__ID=$self->{id}&Grey=FK_Original_Source__ID&Source+Tracking=Yes", $Settings{LINK_COLOUR} )
        . lbr
        . &Link_To( $dbc->homelink(), "Add New (Without Source Tracking)", "&Create+New+Library=1&FK_Original_Source__ID=$self->{id}&Grey=FK_Original_Source__ID&Source+Tracking=No", $Settings{LINK_COLOUR} )
        . "<UL><LI>$lib_list</UL>";

    my $create_new_source
        = "<B>Sources:</B>" 
        . lbr
        . &Link_To( $dbc->homelink(), "Add New", "&cgi_application=alDente::Source_App&rm=Add+Source&Original_Source_ID=$self->{id}&Library+Tracking=Yes", $Settings{LINK_COLOUR} )
        . lbr
        . &Link_To( $dbc->homelink(), "Add New (Without Libray)", "&cgi_application=alDente::Source_App&rm=Add+Source&Original_Source_ID=$self->{id}&Library+Tracking=No", $Settings{LINK_COLOUR} )

        . "<UL><LI>$source_list</UL>";

        my $list_sources_table = &alDente::Source::get_offspring_details( -dbc => $self->{dbc}, -id => $self->{id} );

        my $ancestry = alDente::Original_Source_Views::ancestry_view( -id => $self->{id}, -dbc => $dbc )
         . alDente::Original_Source_Views::source_ancestry_view( -id => $self->{id}, -dbc => $dbc );

    my @layers = (
        {label => 'Ancestry', content => $ancestry},
        {label => 'Add', content => $create_new_library . '<hr>' . $create_new_source },
        {label => 'Offspring', content => $list_sources_table },
    );

    return $self->SUPER::display_record_page(
         -layers     => \@layers,
     );
}

# show hierarchy of hybrids
#######################
sub ancestry_view {
#######################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};
    my $seek = $args{ -seek } || 'parents,children';

    my $link = alDente_ref( 'Original_Source', $id, -dbc => $dbc );

    my @row            = ($link);
    my $primary_column = 1;

    my @parents;
    my @children;

    if ( $seek =~ /children/ ) {
        @children = $dbc->Table_find( 'Hybrid_Original_Source', 'FKChild_Original_Source__ID', "WHERE FKParent_Original_Source__ID = $id" );
        if (@children) {
            my $generation;
            foreach my $child (@children) {
                $generation .= '<br>' . ancestry_view( -id => $child, -dbc => $dbc, -seek => 'children' );
            }
            push @row, '}-->';
            push @row, $generation;
        }
    }
    
    if ( $seek =~ /parent/ ) {
        @parents = $dbc->Table_find( 'Hybrid_Original_Source', 'FKParent_Original_Source__ID', "WHERE FKChild_Original_Source__ID = $id" );
        if (@parents) {
            my $generation;
            foreach my $parent (@parents) {
                $generation .= '<br>' . ancestry_view( -id => $parent, -dbc => $dbc, -seek => 'parent' );
            }

            unshift @row, '}-->';
            unshift @row, $generation;
            $primary_column += 2;
        }
    }

    my $ancestry = new HTML_Table();
    $ancestry->Set_Row( \@row );
    if ( $seek =~ /parents/ && $seek =~ /children/ ) {
        $ancestry->Set_Cell_Colour( 1, $primary_column, '#FFAAAA' );
        if ( $ancestry->{columns} > 1 ) { $ancestry->Set_Title('Original_Source Ancestry'); }
    }

    my $view;
    if ( @parents || @children ) {
        $view = create_tree( -tree => { 'Hybrid Ancestry' => $ancestry->Printout(0) } );
    }
    else {
        $view = $link;
    }

    return $view;
}

#######################
sub source_ancestry_view {
#######################
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $id       = $args{-id};
    my $detailed = 1;

    require alDente::Source_Views;

    my @first_level_sources = $dbc->Table_find( 'Source', 'Source_ID', "WHERE FK_Original_Source__ID = $id and ( FKParent_Source__ID = ''  OR FKParent_Source__ID = 0 OR FKParent_Source__ID IS NULL )" );
    my @other_sources = $dbc->Table_find( 'Source as child , Source as parent', 'child.Source_ID', "WHERE child.FK_Original_Source__ID = $id and  child.FKParent_Source__ID = parent.Source_ID and parent.FK_Original_Source__ID <> $id" );

    my $table = new HTML_Table( -title => "Source Ancestry", -border => 1 );
    my @total;

    my @all_sources = @first_level_sources;
    push @all_sources, @other_sources;

    for my $src (@all_sources) {
        my @rows = ();
        my $Source = new alDente::Source( -dbc => $dbc, -id => $src );
        my ( $parents, $children ) = $Source->source_ancestry();
        push @rows, alDente::Source_Views::object_label( -source_id => $src, -dbc => $dbc, -detailed => $detailed );

        foreach my $gen (@$children) {
            my @offspring = @$gen;
            my $generation;
            if (@offspring) {
                map {
                    if ($_)
                    {
                        my $src_id = $_;
                        my ($os_id) = $dbc->Table_find( 'Source', 'FK_Original_Source__ID', "WHERE Source_ID = $src_id " );
                        if ( $os_id == $id ) {
                            $generation .= alDente::Source_Views::object_label( -source_id => $src_id, -dbc => $dbc, -detailed => $detailed ) . '<BR>';

                        }
                    }
                } @offspring;
            }
            push @rows, $generation if $generation;
        }

        push @total, \@rows;
    }

    for my $first (@total) {
        $table->Set_Row($first);
    }
    my $page = $table->Printout(0);
    return vspace() . create_tree( -tree => { 'Source Ancestry' => $page } ) . vspace();

}

1;

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Project.pm,v 1.9 2004/09/08 23:31:49 rguin Exp $ (Release: $Name:  $)

=cut
