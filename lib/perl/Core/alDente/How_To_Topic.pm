#
################################################################################
# How_To.pm
#
# This module handles How_To based functions
#
###############################################################################
package alDente::How_To_Topic;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

use strict;
use CGI qw(:standard);
use Data::Dumper;
use SDB::CustomSettings;

use SDB::HTML;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;

use SDB::Session;
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::Conversion;
use alDente::Form;
use vars qw($user);
use vars qw($MenuSearch $scanner_mode);

###########################
# Constructor of the object
###########################
sub new {
    my $this  = shift;
    my %args  = @_;
    my $class = ref($this) || $this;

    my $how_to_topic_id = $args{-how_to_topic_id} || $args{-id};                                                        # required
    my $dbc             = $args{-dbc}             || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $tables          = $args{-tables}          || 'How_To_Topic';
    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => $tables );

    if ($how_to_topic_id) {
        $self->primary_value( -table => 'How_To_Topic', -value => $how_to_topic_id );
        $self->{id} = $how_to_topic_id;
    }

    $self->{dbc} = $dbc;

    $self->load_Object();
    bless $self, $class;
    return $self;
}

############################
sub load_Object {
#########################
    #
    # Load Plate information into attributes from Database
    #
    my $self = shift;
    my %args = @_;

    my $dbc = $args{-dbc} || $self->{dbc};
    my $id  = $args{-id}  || $self->{id};
    $self->SUPER::load_Object( -id => $id );
    $self->{topic_name} = $self->value('Topic_Name');

    return 1;
}

sub homepage {

    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    $self->load_Object();
    print alDente::Form::start_alDente_form( $dbc, -type => 'start' );

    my @steps = $dbc->Table_find( 'How_To_Topic, How_To_Step', 'How_To_Step_ID,How_To_Step_Number,How_To_Step_Description', "where FK_How_To_Topic__ID = How_To_Topic_ID AND How_To_Topic_ID = $self->{id}" );

    my $step_count  = 0;
    my $step_table  = HTML_Table->new( -border => 1 );
    my @step_header = ( 'Select', 'Step Number', 'Step Name' );
    foreach my $step (@steps) {
        my ( $step_id, $step_number, $step_name ) = split ',', $step;
        $step_table->Set_Row( [ "<INPUT TYPE=\"radio\" NAME=\"Edit Step\" VALUE=\"$step_id\">", $step_number, $step_name ] );
        $step_count++;
    }
    print "Topic $self->{topic_name} has $step_count steps<BR><BR>";

    $step_table->Printout();
    print submit( -name => "View How To Step",   -value => 'View Step',   -class => "Std" );
    print submit( -name => "Edit How To Step",   -value => 'Edit Step',   -class => "Std" );
    print submit( -name => "Add How To Step",    -value => 'Add Step',    -class => "Std" );
    print submit( -name => "Delete How To Step", -value => 'Delete Step', -class => "Std" );
    print hidden( -name => "How To Topic ID", -value => $self->{id} );

    print end_form();

    return 1;
}

sub add_topic_form {
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    print alDente::Form::start_alDente_form( $dbc, -type => 'start' );
    my $how_to_id = $args{-how_to};

    print "New Topic<BR><BR>";

    print "Topic Name" . hspace(10) . textfield( -name => 'Topic Name', -size => 80 ) . "<BR>";

    my @topic_choices = ( 'New', 'Update', 'Find', 'Edit' );

    print "Topic Type: " . RGTools::Web_Form::Popup_Menu( name => 'Topic Type', values => \@topic_choices, force => 1 ) . "<BR>";
    print "Topic Description:" . hspace(14) . textarea( -name => 'Topic Description', -rows => 2, -cols => 60, -value => '', -force => 1 ) . "<BR>";
    print submit( -name => "Confirm Add How To Topic", -value => 'Add Topic', -class => "Std" );
    print hidden( -name => "How_To", -value => $how_to_id );
    print end_form();
    return 1;
}

