###################################################################################################################################
# Sequencing::Primer_Plate_View.pm
#
#
#
###################################################################################################################################
package alDente::Primer_Plate_Views;

use strict;
use CGI qw(:standard);
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## alDente modules
use alDente::Primer;
use alDente::Primer_Plate;

use vars qw( %Configs );

my $q = new CGI;

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

#####################
sub display_Entry_Page {
#####################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $directs = $args{-dir};
    my $volumes = $args{-volumes};
    my $hosts   = $args{-hosts};
    my $page    = 'Under Construction';
    return $page;
}

############################
sub display_delete_Primer_Plate_table {
############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $id   = $args{-id};

    my @primer_plate_status = ('');
    push( @primer_plate_status, $dbc->Table_find( 'Primer_Plate', 'distinct Primer_Plate_Status' ) );
    my @primer_types = ('');
    push( @primer_types, $dbc->Table_find( "Primer", "distinct Primer_Type", "WHERE 1" ) );
    @primer_types = @{ &unique_items( \@primer_types ) };

    my $rearray_utilities = HTML_Table->init_table( -title => "Find Primer Plate to delete", -width => 600, -toggle => 'on' );
    $rearray_utilities->Set_Border(1);
    $rearray_utilities->Set_Row(
        [   $q->submit( -name => "rm", -value => "View Primer Plates", -style => "background-color:lightgreen" ),
            "<BR> Primer Plate ID: <BR>" . $q->textfield( -name => "Primer Plate ID" ) . "<BR>Status:<BR>" . $q->popup_menu( -name => "Primer Plate Status", -values => \@primer_plate_status, -default => 'To Order' )
        ]
    );

    my $output
        = alDente::Form::start_alDente_form( -dbc => $dbc, -name => "Rearray_Utilities" )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::ReArray_App', -force => 1 )
        . $q->hidden( -name => 'button options',  -value => 'bioinformatics',       -force => 1 )
        . $rearray_utilities->Printout(0)
        . $q->end_form();
    return $output;

}

1;
