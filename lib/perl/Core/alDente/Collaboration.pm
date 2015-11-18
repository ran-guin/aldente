###################################################################################################################################
# Collaboration.pm
#
# Class module that encapsulates a DB_Object that represents Collaborations (singly or in multiples for a single Contact)
#
# $Id: Collaboration.pm,v 1.6 2004/09/08 23:31:48 rguin Exp $
###################################################################################################################################
package alDente::Collaboration;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Collaboration.pm - Class module that encapsulates a DB_Object that represents Collaborations (singly or in multiples for a single Contact)

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Class module that encapsulates a DB_Object that represents Collaborations (singly or in multiples for a single Contact)<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT    = qw();
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use Data::Dumper;

#use Storable qw (freeze thaw);
use MIME::Base32;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::Project;
use SDB::DB_Object;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::HTML_Table;
use RGTools::RGIO;
use SDB::HTML;
use strict;
##############################
# global_vars                #
##############################
use vars qw($Connection);
use vars qw(%Settings);
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
my $PROJECT_FK_FIELD = 'FK_Project__ID';
my $CONTACT_FK_FIELD = 'FK_Contact__ID';

##############################
# constructor                #
##############################

############################################################
# Constructor: Takes a database handle and a Collaboration ID or Contact ID and constructs a Collaboration object
# RETURN: Reference to a Collaboration object
############################################################
sub new {
    my $this = shift;
    my %args = @_;

    my $dbc              = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);    # Database handle
    my $collaboration_id = $args{-collaboration_id};      # Collaboration ID of a row
    my $contact_id       = $args{-contact_id};
    my $frozen           = $args{-frozen} || 0;           # flag to determine if the object was frozen
    my $encoded          = $args{-encoded};               # flag to determine if the frozen object was encoded

    my $class = ref($this) || $this;

    my $self;
    if ($frozen) {
        $self = $this->Object::new(%args);
    }
    else {
        if ($collaboration_id) {

            # represent a single collaboration
            $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Collaboration", -primary => $collaboration_id );

            # acquire all information necessary for Collaborations
            $self->load_Object();

            # construct the associated project
            my $project = Project->new( -dbc => $dbc, -project_id => $self->value($PROJECT_FK_FIELD) );
            $self->{"Projects"} = [$project];

        }
        else {

            # represent a set of collaborations belonging to a single contact
            $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Collaboration" );
            $self->load_Object( -condition => "$CONTACT_FK_FIELD=$contact_id" );

            # construct and store the associated projects
            my @projects = ();
            my @proj_ids = @{ $self->values( -field => "$PROJECT_FK_FIELD", -multiple => 1 )->{$PROJECT_FK_FIELD} };
            foreach my $proj_id (@proj_ids) {
                my $project = Project->new( -dbc => $dbc, -project_id => $proj_id );
                push( @projects, $project );
            }
            $self->{"Projects"} = \@projects;
        }
        bless $self, $class;
    }
    $self->{"dbc"} = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

############################################################
# Subroutine: Displays a simple table with project IDs, date initiated, and status
# RETURN: HTML
############################################################
sub display_simple_project_table {
    my $self         = shift;
    my $projects_ref = $self->{"Projects"};
    my $table        = new HTML_Table();
    $table->Set_Title("<H3> Projects </H3>");
    $table->Set_Headers( [ "Name", "Initiated", "Status" ] );
    $table->Set_Row( [ " ", " ", " " ] );
    foreach $project ( @{$projects_ref} ) {
        my $p_name   = $project->value("Project_Name");
        my $p_init   = $project->value("Project_Initiated");
        my $p_status = $project->value("Project_Status");

        my $project_id = $project->primary_value();
        my %input_args;
        $input_args{"Project_ID"} = $project->primary_value();
        my $enc_frozen = MIME::Base32::encode( freeze( \%input_args ) );

        $table->Set_Row( [ Link_To( -link_url => 'project_view.pl', -label => $project_id, -param => "?args=$enc_frozen", -colour => $Settings{LINK_COLOUR}, -method => "POST" ), $p_init, $p_status ] );
    }
    return $table->Printout();
}

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

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Collaboration.pm,v 1.6 2004/09/08 23:31:48 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
