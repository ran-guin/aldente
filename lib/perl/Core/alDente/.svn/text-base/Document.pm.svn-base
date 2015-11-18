#
################################################################################
# How_To.pm
#
# This module handles How_To based functions
#
###############################################################################
package alDente::Document;

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
use vars qw($MenuSearch $scanner_mode $Connection);

###########################
# Constructor of the object
###########################
sub new {
    my $this  = shift;
    my %args  = @_;
    my $class = ref($this) || $this;

    my $doc_id = $args{-doc_id} || $args{-id};                                                        # required
    my $dbc    = $args{-dbc}    || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $tables = $args{-tables} || 'Document';
    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => $tables );

    if ($doc_id) {
        $self->primary_value( -table => 'Document', -value => $doc_id );
        $self->{id} = $doc_id;
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

    my $dbc = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id = $args{-id} || $self->{id};

    if ( !$id ) {return}

    $self->SUPER::load_Object( -id => $id );

    $self->{name}        = $self->value('Document_Name');
    $self->{description} = $self->value('Document_Description');
    $self->{created}     = $self->value('Document_Created');
    $self->{modified}    = $self->value('Document_Modified');

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
    my %args = &filter_input( \@_ );

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    print alDente::Form::start_alDente_form( $dbc, 'DocumentPage' );

    ## Get a list of documents
    my @docs = $dbc->Table_find( 'Document', 'Document_ID,Document_Name,Document_Description,Document_Created,Document_Modified' );

    if ( scalar(@docs) ) {
        my @doc_header = ( 'Select', 'Name', 'Description', 'Last Modified', 'Created' );
        my $doc_table = HTML_Table->new( -width => 800 );
        $doc_table->Set_Title("LIMS Documents");
        $doc_table->Set_Headers( \@doc_header );

        foreach my $doc (@docs) {

            # Get Document info
            my ( $doc_id, $doc_name, $doc_desc, $doc_created, $doc_modified ) = split ',', $doc;
            $doc_table->Set_Row( [ "<INPUT TYPE=\"radio\" NAME=\"Select Document\" VALUE=\"$doc_id\">", $doc_name, $doc_desc, $doc_modified, $doc_created ] );
        }
        $doc_table->Printout();

        # Display Button options for How To
        print submit( -name => "View Document", -value => 'View Document', -class => "Std" );

        #print submit(-name=>"Edit Document",-value=>'Edit Document',-class=>"Std");
        print submit( -name => "Add Document",    -value => 'Add Document',    -class => "Std" );
        print submit( -name => "Delete Document", -value => 'Delete Document', -class => "Std" );

        #print hidden(-name=>"Document ID", -value=>$self->{id});
    }
    else {
        print "Sorry, no documents available<BR>";
        print submit( -name => "Add Document", -value => 'Add Document', -class => "Std" );
    }

    print end_form();

    return 1;
}

sub view {
#########################
    #
    # Display the homepage
    #
    # Return: 1 on success
###########################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tables = 'Document_Step';
    $self->load_Object();
    my $doc_id = $self->{id};
    print alDente::Form::start_alDente_form( $dbc, 'Document', -type => 'start' );

    ## Get a list of document steps
    #my %steps = &Table_retrieve($dbc,$tables,['Document_Step_ID','Document_Step_Number','Document_Step_Description','Document_Step_Comments','FKParent_Document_Step__ID'],"WHERE FK_Document__ID=$doc_id");
    my @top_level_steps = $dbc->Table_find( $tables, 'Document_Step_ID,Document_Step_Number,Document_Step_Name,Document_Step_Description,Document_Step_Comments,FKParent_Document_Step__ID', "WHERE FK_Document__ID=$doc_id" );

    my $doc_edit_link = &Link_To( $dbc->config('homelink'), $self->{name}, "&Search=1&Table=Document&Search+List=" . $self->{id}, $Settings{LINK_COLOUR} );
    print "Document: $doc_edit_link<BR>";
    print "Description: $self->{description}<BR>";
    print "Created: $self->{created}<BR>";
    print "Last modified : $self->{modified}<BR>";

    my %Rows;
    my $doc = HTML_Table->new( -width => 800 );
    $doc->Set_Title( $self->{name} );

    for my $step (@top_level_steps) {
        my ( $step_id, $step_no, $step_name, $step_desc, $step_comments, $step_parent ) = split( ',', $step );
        my $edit_link = &Link_To( $dbc->config('homelink'), "Edit",   "&Search=1&Table=Document_Step&Search+List=$step_id", $Settings{LINK_COLOUR} );
        my $del_link  = &Link_To( $dbc->config('homelink'), "Delete", "&Search=1&Table=Document_Step&Search+List=$step_id", $Settings{LINK_COLOUR} );
        push( @{ $Rows{$step_no}{header} }, [ $step_no, $step_name, $step_desc, $step_comments, $edit_link, $del_link ] );
    }

    for my $row ( sort keys %Rows ) {

        $doc->Set_Row( @{ $Rows{$row}{details} } );
    }
    $doc->Printout();

    print submit( -name => "Add Step",        -value => 'Add Step',        -class => "Std" );
    print submit( -name => "Add Sub Title",   -value => 'Add Sub Title',   -class => "Std" );
    print submit( -name => "Add Document",    -value => 'Add Document',    -class => "Std" );
    print submit( -name => "Delete Document", -value => 'Delete Document', -class => "Std" );
    print hidden( -name => "Document ID", -value => $doc_id );
    print end_form();

    return 1;
}

