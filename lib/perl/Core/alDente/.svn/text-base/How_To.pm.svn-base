#
################################################################################
# How_To.pm
#
# This module handles How_To based functions
#
###############################################################################
package alDente::How_To;

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
use vars qw( $user);
use vars qw($MenuSearch $scanner_mode);

###########################
# Constructor of the object
###########################
sub new {
    my $this  = shift;
    my %args  = @_;
    my $class = ref($this) || $this;

    my $how_to_id = $args{-how_to_id} || $args{-id};                                                        # required
    my $dbc       = $args{-dbc}       || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $tables    = $args{-tables}    || 'How_To_Object';
    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => $tables );

    if ($how_to_id) {
        $self->primary_value( -table => 'How_To_Object', -value => $how_to_id );
        $self->{id} = $how_to_id;
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

    $self->{name} = $self->value('How_To_Object_Name');

    return 1;
}

#########################
sub home_page {
#########################
    #
    # Display the homepage
    #
    # Return: 1 on success
###########################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    $self->load_Object();
    print alDente::Form::start_alDente_form( $dbc, 'How_To_Home_Page', -type => 'start' );

    ## Get a list of topics
    my @topics = $dbc->Table_find( 'How_To_Object, How_To_Topic', 'How_To_Topic_ID, Topic_Number, Topic_Name, Topic_Type', "where FK_How_To_Object__ID = How_To_Object_ID AND How_To_Object_ID = $self->{id}" );

    my $topic_count = 0;

    #my $topic_table = HTML_Table->new(-border=>1);
    #my @topic_header = ('Select','Topic Number','Topic Name','Topic Type','Options');
    #$topic_table->Set_Headers(\@topic_header);
    print "How To Guide: $self->{name}<BR><BR>";
    foreach my $topic (@topics) {

        # Get Topic info
        my ( $topic_id, $topic_number, $topic_name, $topic_type ) = split ',', $topic;

        # Link for adding steps
        my $add_step = &Link_To( $dbc->config('homelink'), "Add Step", "&Add+How+To+Step=1&Edit+Topic=$topic_id", $Settings{LINK_COLOUR} );

        # Get a list of steps for the topic
        my @steps = $dbc->Table_find( 'How_To_Step, How_To_Topic', 'How_To_Step_ID, How_To_Step_Number, How_To_Step_Description,How_To_Step_Result,Users,Mode', "where FK_How_To_Topic__ID = How_To_Topic_ID AND How_To_Topic_ID = $topic_id" );

        #$topic_table->Set_Row(["<INPUT TYPE=\"radio\" NAME=\"Edit Topic\" VALUE=\"$topic_id\">" , $topic_number , $topic_name,$topic_type,$add_step]);
        print "<INPUT TYPE=\"radio\" NAME=\"Edit Topic\" VALUE=\"$topic_id\">" . $topic_number . "." . $topic_name . hspace(10) . $add_step . "<BR>";

        # check if there are steps
        if ( scalar(@steps) > 0 ) {
            my $step_table = HTML_Table->new( -border => 1 );
            my @step_header = ( 'Select', 'Step Number', 'Step Description', 'Result' );
            $step_table->Set_Headers( \@step_header );
            my $step_rows = 0;
            foreach my $step (@steps) {
                my ( $step_id, $step_number, $step_descrip, $result ) = split ',', $step;

                $step_table->Set_Row( [ "<INPUT TYPE=\"radio\" NAME=\"Edit Step\" VALUE=\"$step_id\">", $step_number, $step_descrip, $result ] );
                $step_rows++;
            }

            #$topic_table->Set_sub_header(&Views::Table_Print(content=>[[$step_table->Printout(0)]],print=>0));
            $step_table->Printout();
        }

        $topic_count++;
    }

    #$topic_table->Printout();

    # Display Button options for How To
    print submit( -name => "View How To Topic",   -value => 'View Topic',   -class => "Std" );
    print submit( -name => "Edit How To Topic",   -value => 'Edit Topic',   -class => "Std" );
    print submit( -name => "Add How To Topic",    -value => 'Add Topic',    -class => "Std" );
    print submit( -name => "Delete How To Topic", -value => 'Delete Topic', -class => "Std" );
    print hidden( -name => "How To Object ID", -value => $self->{id} );

    print end_form();

    return 1;
}

