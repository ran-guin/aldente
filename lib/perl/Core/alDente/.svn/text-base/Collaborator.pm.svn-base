package alDente::Collaborator;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Collaborator.pm - 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################

@ISA = qw(alDente::Contact);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw();

##############################
# standard_modules_ref       #
##############################

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;
use SDB::DB_Form_Viewer;
use SDB::CustomSettings;
use RGTools::HTML_Table;
use RGTools::RGIO;
use SDB::HTML;
use alDente::Submission;
use alDente::Collaboration;
use alDente::Contact;
use strict;

##############################
# global_vars                #
##############################
use vars qw($testing $Connection %Settings);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Local Constants
my $CONTACT_NAME_FIELD      = 'Contact_Name';
my $CONTACT_POSITION_FIELD  = 'Position';
my $ORGANIZATION_NAME_FIELD = 'Organization.Organization_Name';

##############################
# constructor                #
##############################

#Constructor;
sub new {
    my $this = shift;
    my %args = @_;

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);    # Database handle
    my $contact_id = $args{-contact_id};

    my $class = ref($this) || $this;
    my $self = alDente::Contact->new( -dbc => $dbc, -contact_id => $contact_id );

    $self->{dbc} = $dbc;

    bless $self, $class;

    return $self;
}

##############################
# public_methods             #
##############################

#function that returns the Collaborator information as an HTML page
sub get_collaborator_html {
    my $self                 = shift;
    my $dbc = $self->{dbc};
    my $contact_id           = $self->primary_value();
    my $contact_name         = $self->value($CONTACT_NAME_FIELD);
    my $contact_organization = $self->value($ORGANIZATION_NAME_FIELD);
    my $contact_position     = $self->value($CONTACT_POSITION_FIELD);
    my $table                = new HTML_Table();
    $table->Set_Title("<H3> Collaborator Information </H3>");
    $table->Set_Row( [ "Contact Name", $contact_name ] );
    $table->Set_Row( [ "Position",     $contact_position ] );
    $table->Set_Row( [ "Organization", $contact_organization ] );

    $table->Set_Row( [ Link_To( $dbc->config('homelink'), 'Edit', "?User=Guest&Info=1&Table=Contact&Field=Contact_ID&Like=$contact_id", $Settings{LINK_COLOUR} ) ] );

    return $table->Printout();
}

#function that returns the project information of a collaborator as an HTML table
# PRE: None
# POST: return a string that contains project information as an HTML table, with links to Project.pm
sub get_projects_html {
    my $self = shift;
    return $self->get_Collaboration()->display_simple_project_table();
}

#function that returns the project information of a collaborator as an HTML table
# PRE: None
# POST: return a string that contains project information as an HTML table, with links to Project.pm
sub get_submissions_html {
    my $self    = shift;
    my $sub_obj = $self->get_Submission();
    return $sub_obj->display_simple_submission_table();
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

$Id: Collaborator.pm,v 1.9 2004/09/08 23:31:48 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
