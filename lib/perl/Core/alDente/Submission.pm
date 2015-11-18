###################################################################################################################################
# Submission.pm
#
# Class module that encapsulates a DB_Object that represents a single Submission
#
# $Id: Submission.pm,v 1.7 2004/09/08 23:31:52 rguin Exp $
###################################################################################################################################
package alDente::Submission;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Submission.pm - Class module that encapsulates a DB_Object that represents a single Submission

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Class module that encapsulates a DB_Object that represents a single Submission<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

use base SDB::Submission;

# @ISA = qw(SDB::DB_Object);

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

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use SDB::DB_Object;
use SDB::DBIO;
use SDB::DIOU;
use SDB::HTML;
use alDente::Validation;
use alDente::Subscription;
use SDB::CustomSettings;
use RGTools::HTML_Table;
use RGTools::RGIO;
use CGI qw(:standard);
use strict;
##############################
# global_vars                #
##############################
use vars qw($Connection $URL_version);

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
my $CONTACT_FK_FIELD          = 'FK_Contact__ID';
my $SUBMISSION_DATETIME_FIELD = 'Submission_DateTime';
my $SUBMISSION_STATUS_FIELD   = 'Submission_Status';
my $SUBMISSION_ID_FIELD       = 'Submission_ID';

##############################
# constructor                #
##############################

############################################################
# Constructor: Takes a database handle and a submisison ID and constructs a submission object
# RETURN: Reference to a Submission object
############################################################
sub new {
    my $this          = shift;
    my %args          = @_;
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $submission_id = $args{-submission_id};                                                           # Submission ID of the Submission
    my $contact_id    = $args{-contact_id};                                                              # contact ID for multiple Submissions
    my $frozen        = $args{-frozen} || 0;                                                             # flag to determine if the object was frozen
    my $encoded       = $args{-encoded};                                                                 # flag to determine if the frozen object was encoded

    my $class = ref($this) || $this;

    my $self;
    if ($frozen) {
        $self = $this->Object::new(%args);
    }
    else {
        if ($submission_id) {
            $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Submission" );
            $self->primary_value( 'Submission', $submission_id );

            #acquire all information necessary for Submissions
            $self->load_Object();
            $self->{"multiple"} = 0;
        }
        else {
            $self = {};
            if ($contact_id) {
                $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Submission" );
                $self->load_Object( -condition => "$CONTACT_FK_FIELD=$contact_id" );
                $self->{"multiple"} = 1;
            }
        }
        bless $self, $class;
    }

    $self->{"dbc"} = $dbc;
    $self->{dbc} = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

#########################################
sub validate_Submission {
#########################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $id   = $args{-id};
    my ($file_req) = $dbc->Table_find( 'Submission', 'File_Required', "WHERE Submission_ID = $id" );
    my $failed;
    if ( $file_req =~ /yes/i ) {
        my $attachments = SDB::Submission::get_attachment_list( -dbc => $dbc, -sid => $id );
        my @attachments = @$attachments if $attachments;
        unless ( $attachments[0] ) {
            $failed = 1;
            $dbc->warning("No attachments found");
        }
    }
    else {

    }
    return !$failed;
}

#####################
sub display_full_table {
#####################
    my $self     = shift;
    my $index    = 0;
    my $multiple = $self->{"multiple"};
    my $table    = new HTML_Table();
    my @fields   = $self->fields();
    $table->Set_Title("<h3> Submissions </h3>");
    $table->Set_Headers( \@fields );
    if ($multiple) {
        my @ids = @{ $self->values( -field => "$SUBMISSION_ID_FIELD", -multiple => 1 )->{$SUBMISSION_ID_FIELD} };
        foreach my $id (@ids) {
            my @values = ();
            foreach my $field (@fields) {
                push( @values, $self->values( -field => $field, -multiple => 1 )->{$field}->[$index] );
            }
            $table->Set_Row( \@values );
            $index++;
        }
    }
    else {
        my @values = ();
        foreach my $field (@fields) {
            push( @values, $self->value($field) );
        }
        $table->Set_Row( \@values );
    }
    return $table->Printout();
}

############################################################
# Subroutine: prints a simple table of all submissions, with Submission ID, date submitted, and status
# RETURN: HTML
############################################################
sub display_simple_submission_table {
################################
    my $self     = shift;
    my $index    = 0;
    my $multiple = $self->{"multiple"};
    my $table    = new HTML_Table();
    $table->Set_Title("<H3> Submissions </H3>");
    $table->Set_Headers( [ "Submission ID", "Date", "Status" ] );
    $table->Set_Row( [ " ", " ", " " ] );
    if ( $multiple == 1 ) {
        my @ids = @{ $self->values( -field => "$SUBMISSION_ID_FIELD", -multiple => 1 )->{$SUBMISSION_ID_FIELD} };
        foreach my $id (@ids) {
            my $s_id     = $id;
            my $s_date   = $self->values( -field => "$SUBMISSION_DATETIME_FIELD", -multiple => 1 )->{$SUBMISSION_DATETIME_FIELD}->[$index];
            my $s_status = $self->values( -field => "$SUBMISSION_STATUS_FIELD", -multiple => 1 )->{$SUBMISSION_STATUS_FIELD}->[$index];
            $table->Set_Row( [ "<a href='/$URL_dir_name/cgi-bin/submission_view.pl?Submission_ID=$s_id'>$s_id</a>", $s_date, $s_status ] );
            $index++;
        }
    }
    else {
        my $s_id     = $self->primary_value();
        my $s_date   = $self->value("Submission_DateTime");
        my $s_status = $self->value("Submission_Status");
        $table->Set_Row( [ "<a href='/$URL_dir_name/cgi-bin/submission_view.pl?Submission_ID=$s_id'>$s_id</a>", $s_date, $s_status ] );
    }
    $table->Toggle_on_Column(1);
    return $table->Printout();
}

#########################################
# Add presets for fields that do not need to be filled in
#########################################
sub microarray_submission_file_presets {
#########################################
    my %args          = @_;
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $submission_id = $args{-sid};
    my $user_id       = $dbc->get_local('user_id');

    my ($contact_id) = $dbc->Table_find( "Submission", "FK_Contact__ID", "WHERE Submission_ID=$submission_id" );
    my $datetime     = &date_time();
    my $date         = substr( $datetime,              0,                10 );

    my $tables = 'Original_Source,Source,RNA_DNA_Source,Library,RNA_DNA_Collection,Library_Source';
    my @email_fields = ( 'Library.Library_Name', 'Source.Label' );

    my %info;
    my %presets;

    $presets{'FK_Contact__ID'}          = $contact_id;
    $presets{'FK_Barcode_Label__ID'}    = 18;                 ## 2D Source label
    $presets{'FK_Employee__ID'}         = $user_id;
    $presets{'FKCreated_Employee__ID'}  = $user_id;
    $presets{'Defined_Date'}            = $date;
    $presets{'Sample_Available'}        = 'Yes';
    $presets{'Source_Type'}             = 'RNA_DNA_Source';
    $presets{'Source_Status'}           = 'Reserved';
    $presets{'Received_Date'}           = $date;
    $presets{'FKReceived_Employee__ID'} = $user_id;
    $presets{'FK_Rack__ID'}             = 2;
    $presets{'Source_Number'}           = 1;
    $presets{'Library_Type'}            = 'RNA/DNA';
    $presets{'Library_Obtained_Date'}   = $date;
    $presets{'Library_Status'}          = "Submitted";
    $presets{'FK_Grp_ID'}               = 21;
    $presets{'Starting_Plate_Number'}   = 1;
    $presets{'Source_In_House'}         = 'Yes';

    $info{presets}      = \%presets;
    $info{tables}       = $tables;
    $info{email_fields} = \@email_fields;
    return \%info;
}

##########################################
# Call functions to insert the batch submission file
##########################################
sub insert_submission_file {
##########################################
    my %args     = @_;
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sid      = $args{-sid};
    my $filename = $args{-filename};
    my $delim    = $args{-delim} || 'comma';
    my $type     = $args{-type} || 'microarray';

    my $file = "$filename";

    Message("Opening $file");

    # read file
    my @lines = ();
    open( INF, $file );
    @lines = <INF>;
    close(INF);

    ### assume all validation checks have been done when the user has submitted the file

    ### Add all preset fields

    # get number of rows (to expand preset fields)
    my $numRows = int(@lines) - 1;
    my $info    = {};
    if ( $type eq 'microarray' ) {
        $info = &microarray_submission_file_presets( -sid => $sid );
    }
    my $tables  = $info->{tables};
    my $presets = $info->{presets};

    my $values = [];
    my $fields = [];
    foreach my $field ( keys %{$presets} ) {
        my @col = map { $presets->{$field} } ( 1 .. $numRows );
        push( @{$fields}, $field );
        push( @{$values}, \@col );
    }

    my $newfile = &SDB::DIOU::add_column_to_submission( -file => $file, -fields => $fields, -values => $values );

    # sanity check
    my $found_v_errors = &SDB::DIOU::batch_validate_file( -file => $newfile, -deltr => $delim, -tables => $tables );
    if ( int( @{$found_v_errors} ) > 0 ) {
        Message("Aborting insert...");
        return 0;
    }
    else {
        Message("Inserting data...");
    }

    # call insert function
    my %newids;
    my $found_errors = &SDB::DIOU::batch_append_file( -file => $newfile, -deltr => $delim, -tables => $tables, -newids => \%newids );

    # send email to collaborator with insert file as attachment, cc lab admin
    my $email_fields = $info->{email_fields};
    my $html_table   = new HTML_Table();

    if ($email_fields) {
        my @headers = ();
        foreach my $ref_field ( @{$email_fields} ) {
            my ( $table, $field ) = &SDB::DBIO::simple_resolve_field($ref_field);
            my ($primary) = $dbc->get_field_info( -table => $table, -type => 'Primary' );

            my @column = ();
            push( @headers, $field );
            foreach my $id ( @{ $newids{$table} } ) {

                # grab value of field
                my ($value) = $dbc->Table_find( $table, $field, "WHERE $primary = '$id'" );
                push( @column, $value );
            }
            $html_table->Set_Column( [@column] );
        }
        $html_table->Set_Headers( \@headers );
        my $printout = $html_table->Printout(0);

        # grab email addresses for lab admins and collaborator
        my %submission_info = $dbc->Table_retrieve( "Submission,Contact", [ 'FKTo_Grp__ID', 'Contact_Email', 'Contact_Name', 'Submission_DateTime', 'Approved_DateTime' ], "WHERE FK_Contact__ID=Contact_ID AND Submission_ID=$sid" );
        my $target_grp      = $submission_info{'FK_Grp__ID'}[0];
        my $contact_email   = $submission_info{'Contact_Email'}[0];
        my $contact_name    = $submission_info{'Contact_Name'}[0];
        my $submit_time     = $submission_info{'Submission_DateTime'}[0];
        my $approved_time   = $submission_info{'Approved_DateTime'}[0];

        my $cc_email = join ', ', @{ &alDente::Employee::get_email_list( $dbc, 'admin', -group => $target_grp ) };

        my $header      = "Content-type: text/html\n\n";
        my $subject_str = "Submission - Submission ID $sid Approved";
        my $msg         = "The following submission has been approved:<BR><BR>";
        $msg .= "<B>Submission ID:</B> $sid<BR>";
        $msg .= "<B>Submitted by:</B> $contact_name<BR>";
        $msg .= "<B>Submitted at:</B> $submit_time<BR>";
        $msg .= "<B>Approved at:</B> $approved_time<BR><BR>";
        $msg .= $printout;

        #	&alDente::Notification::Email_Notification(-to=>$contact_email,
        #						   -cc=>$cc_email,
        #						   -from=>'submission@bcgsc.ca',
        #						   -subject=>$subject_str,
        #						   -body=>$msg,
        #						   -header=>$header);

        #++++++++++++++++++++++++++++++ Subscription Module version of the Notification
        my $ok = alDente::Subscription::send_notification(
            -dbc          => $dbc,
            -name         => "Approved Submission",
            -from         => 'submission@bcgsc.ca',
            -subject      => $subject_str . '(from Subscription Module)',
            -body         => $msg,
            -content_type => 'html',
            -to           => $contact_email,
            -testing      => 1
        );

        #++++++++++++++++++++++++++++++
    }

    if ( int( @{$found_errors} ) > 0 ) {
        return 0;
    }
    else {
        return 1;
    }
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

$Id: Submission.pm,v 1.7 2004/09/08 23:31:52 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
