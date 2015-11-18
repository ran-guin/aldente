################################################################################
#
# Submission.pm
#
# This modules provides submission_related functionality
#
################################################################################
# Ran Guin (2001) rguin@bcgsc.bc.ca
#
################################################################################
# $Id: Submission.pm,v 1.16 2004/11/30 01:44:11 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.16 $
#     CVS Date: $Date: 2004/11/30 01:44:11 $
################################################################################
#
# Improvements to be made:
#
#
################################
#
# Globals variables for custom use:
#
#
################################
package SDB::Submission;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Submission.pm - This modules provides submission_related functionality

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This modules provides submission_related functionality<BR>Ran Guin (2001) rguin@bcgsc.bc.ca<BR>Improvements to be made:<BR>Globals variables for custom use:<BR>

=cut

##############################
# superclasses               #
##############################
use base SDB::DB_Object;

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

use lib $FindBin::RealBin . "/../lib/perl/Imported/";

use strict;
use CGI qw(:standard);
use DBI;
use Storable;
use File::stat;
use Data::Dumper;
use RGTools::RGIO;
use RGTools::HTML_Table;

use SDB::HTML;
use SDB::User;
##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::CustomSettings;
use alDente::Notification;
use alDente::SDB_Defaults;
use alDente::Employee;
use alDente::Subscription;    ## Subscription module.  Replace Notification with this in the future

##############################
# global_vars                #
##############################
use vars qw(%Field_Info $testing $lims_administrator_email $Current_Department $submission_dir $URL_version $Connection %Configs);
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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

###########################

#############################
# Function to write a submission to a file
#############################
sub write_to_file {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,data_ref,type,sid' );

    my $dbc         = $args{-dbc};
    my $data_ref    = $args{-data_ref};
    my $type        = $args{-type};
    my $sid         = $args{-sid};
    my $roadmap     = $args{-roadmap};
    my $submit_type = $args{-submit_type};
    my $file_prefix = $args{-file_prefix} || "sub_${sid}";

    # get the status
    my ($status) = &Table_find( $dbc, "Submission", "Submission_Status", "WHERE Submission_ID=$sid" );

    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    my $test_path = &create_dir( -path => $path, -subdirectory => "$sub_dir/$status/submission_${sid}" );

    #Message("The test path is $test_path");
    $path .= $sub_dir;

    if ($roadmap) {
        my $file  = "$path/$status/submission_${sid}/map.json";
        my $found = `ls -altr $file`;

        my $timestamp;
        if ( $found =~ /(\w+)\s+(\d+)\s+(\d+\:\d+)/ ) {
            $timestamp = "$1$2_$3";
        }
        else {
            $timestamp = date_time();
            $timestamp =~ s/\s/\_/g;
        }

        `cp $file $file.$timestamp`;    ## copy original version of file before overwriting (temporary ?) ##

        open my $MAP, "> $file", or die "$!\n";
        try_system_command("chmod 777 $file");
        print $MAP $roadmap;
        close $MAP;
    }

    # XML writing - use XML::Dumper
    # <CONSTRUCTION> - do check if XML::Dumper is actually loadable
    # if not, then proceed to storable anyway
    if ( $type =~ /xml|storable/i ) {

        # check to see if file is already there
        # if it is, change increment number to maxnum+1
        my @files       = glob("$path/$status/submission_${sid}/${file_prefix}*.xml");
        my $max_filenum = 1;

        # error check - if there are no files, return
        if ( int(@files) > 0 ) {
            foreach my $fullpath (@files) {
                my ( $dir, $file ) = &Resolve_Path($fullpath);
                my ($num) = $file =~ /sub_\d+.(\d+).xml/;
                if ( $num > $max_filenum ) {
                    $max_filenum = $num;
                }
            }

            # increment max_filenum
            $max_filenum++;
        }

        my $file = "$path/$status/submission_${sid}/${file_prefix}.${max_filenum}.xml";
        require XML::Dumper;

        # define directories
        my $dump   = new XML::Dumper();
        my $xmlstr = $dump->pl2xml($data_ref);
        open( OUTF, ">$file" );

        print OUTF $xmlstr;
        close OUTF;
        `chmod 777 $file`;
    }
    elsif ( $type =~ /txt/i ) {
        my $file = "$path/$status/submission_${sid}/${file_prefix}_type.txt";
        open my $TEMP, '>', $file or die "CANNOT OPEN $file";
        my $command  = "echo '$submit_type' >> $file ";
        my $response = try_system_command($command);
        Message $response if $response;
        my $command  = "chmod 777 $file";
        my $response = try_system_command($command);
        Message $response if $response;
        close $TEMP;

    }

    return;
}

#############################
sub get_Path {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,data_ref,type,sid' );
    my $dbc  = $args{-dbc};
    my $sid  = $args{-sid};

    my ($status) = $dbc->Table_find( "Submission", "Submission_Status", "WHERE Submission_ID=$sid" );

    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    my $test_path = &create_dir( -path => $path, -subdirectory => "$sub_dir/$status/submission_${sid}" );

}

#############################
sub get_Submit_Type {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,data_ref,type,sid' );

    my $dbc = $args{-dbc};
    my $sid = $args{-sid};
    my $submit_type;

    # get the status
    my ($status) = &Table_find( $dbc, "Submission", "Submission_Status", "WHERE Submission_ID=$sid" );
    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    my $test_path = &create_dir( -path => $path, -subdirectory => "$sub_dir/$status/submission_${sid}" );

    #Message("The test path is $test_path");
    $path .= $sub_dir;
    my $file = "$path/$status/submission_${sid}/sub_${sid}_type.txt";
    unless ( -e $file ) {
        $dbc->error("This submission might be obsolete.  Some files and/or data is missing");
        return;
    }

    open( IMPORT, "< $file " ) or die "Could not open file for read:  $file ";
    my @lines = <IMPORT>;
    close IMPORT;
    return $lines[0];
}

####################################
# Handles file uploads for a submission
####################################
sub upload_file_to_submission {
####################################
    my %args = &filter_input( \@_, -args => 'dbc,upload_fh,filename,data,sid' );

    my $upload_fh = $args{-upload_fh};
    my $filename  = $args{-filename};
    my $data      = $args{-data};
    my $sid       = $args{-sid};
    my $dbc       = $args{-dbc};

    my $return_file_name;

    # get the status
    my ($status) = &Table_find( $dbc, "Submission", "Submission_Status", "WHERE Submission_ID=$sid" );

    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    my $test_path = &create_dir( -path => $path, -subdirectory => "$sub_dir/$status/submission_${sid}/attachments" );

    #Message("The test path is $test_path");
    $path .= $sub_dir;

    my $outfile_name = '';

    # if data array is provided, write that, otherwise use upload_fh
    if ($data) {

        # get filename
        $outfile_name = $filename;
        if ( $outfile_name =~ /^(.*[\\\/])(.*)/ ) {
            $outfile_name = $2;
        }

        open( OUTF, ">$path/$status/submission_${sid}/attachments/${outfile_name}" );
        foreach my $line ( @{$data} ) {
            print OUTF $line;
        }
        close OUTF;
        $return_file_name = $path . "/" . $status . "/submission_" . $sid . "/attachments/" . $outfile_name;
    }
    else {

        # get filename
        $outfile_name = $upload_fh;
        if ( $outfile_name =~ /^(.*[\\\/])(.*)/ ) {
            $outfile_name = $2;
        }

        # check if filename exists. If it does, append start with Reupload
        if ( -e "$path/$status/submission_${sid}/attachments/${outfile_name}" ) {
            $outfile_name = "Reupload.${outfile_name}";
        }
        my $buffer = '';
        my $outfile;
        open( $outfile, ">$path/$status/submission_${sid}/attachments/${outfile_name}" );
        binmode($outfile);    # change to binary mode
        while ( read( $upload_fh, $buffer, 1024 ) ) {
            print $outfile $buffer;
        }
        close($outfile);

        # close original filestream
        close($upload_fh);
        $return_file_name = $path . "/" . $status . "/submission_" . $sid . "/attachments/" . $outfile_name;
    }

    try_system_command("chmod -R 777 $path/$status/submission_${sid}/attachments");
    $dbc->message("Uploaded file");

    return $return_file_name;
}

#########################
## edit batch submission file

sub edit_batch_submission {

    my %args = &filter_input( \@_, -args => 'dbc,sid,file' );
    my $sid  = $args{-sid};
    my $file = $args{-file};                                    # External storage for submissions
    my $dbc  = $args{-dbc};

    # edit batch submission to add required info. to be implemented.

}

########################
# Get an arrayref of attachments
########################
sub get_attachment_list {
########################
    my %args = &filter_input( \@_, -args => 'dbc,sid,link,fullpath' );

    my $sid      = $args{-sid};
    my $link     = $args{ -link };     # prepare attachments for linking (make symbolic links in temp dir) for linking on a page
    my $dbc      = $args{-dbc};
    my $fullpath = $args{-fullpath};

    # get the status
    my ($status) = &Table_find( $dbc, "Submission", "Submission_Status", "WHERE Submission_ID=$sid" );

    my ( $p, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    $p .= $sub_dir;

    my @attachments = glob("$p/$status/submission_${sid}/attachments/*");

    if ( !$fullpath ) {
        my $base_path = $alDente::SDB_Defaults::URL_temp_dir;
        my $test_path = &create_dir( -path => $base_path, -subdirectory => "$sub_dir/submission_${sid}" );

        foreach (@attachments) {
            my ( $path, $file ) = &Resolve_Path($_);
            my $full = $path . '/' . $file;

            #Remove any previous softlink in case file location has changed. e.g.submission status changed
            &try_system_command("rm '$base_path/$sub_dir/submission_$sid/$file'");

            #Message("Creating softlink $base_path/$sub_dir/submission_$sid/$file if not already exists");
            &try_system_command("ln -s '$full' '$base_path/$sub_dir/submission_$sid/$file'");
            $_ = $file;

        }
    }

    return \@attachments;
}

#############################
sub Generate_Submission {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,data_ref,draft,testing', -mandatory => 'dbc,data_ref' );

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id = $dbc->get_local('user_id');

    my $data_raw    = $args{-data_ref};
    my $draft       = $args{-draft};         # Determine if the submission will be saved as a draft
    my $roadmap     = $args{-roadmap};
    my $submit_type = $args{-submit_type};

    my %data_raw;
    if ($data_raw) { %data_raw = %$data_raw }

    require SDB::DB_Form;

    ### Get the submission entry off the data_raw
    my %submission_data;
    my $sid;

    require JSON;
    if (JSON->VERSION =~/^1/) { $roadmap = JSON::jsonToObj($roadmap) }
    else { $roadmap = JSON::from_json($roadmap) }
    
    if ( $data_raw{'Submission'} ) {
        $submission_data{'Submission'} = $data_raw{'Submission'};
        my $s_info = &SDB::DB_Form::conv_FormNav_to_DBIO_format( -dbc => $dbc, -data => \%submission_data );

        if ($draft) { $s_info->{tables}{Submission}{0}{Submission_Status} = 'Draft'; }

        ### Write this submission to the database and get the submission id
        my $result = $dbc->Batch_Append( -data => $s_info, -quiet => 1 );
        $sid = $result->{'Submission.Submission_ID'};

        ### Remove Submission entries from data object
        #delete $data_raw{'Submission'};
        #my $submission_table = pop( @{ $roadmap->{ $roadmap->{'original_form'} }{'child_form'} } );
        #if ( $roadmap->{ $roadmap->{'original_form'} }{'child_form'}[0] && $submission_table ne 'Submission' ) {
        #    Message("Error: Bad '$submission_table' : Please report error.");
        #}
        #delete $roadmap->{Submission};

        $s_info->{tables}{Submission}{0}{Submission_ID} = $sid;
    }
    else {
        my $starting_form = $roadmap->{ $roadmap->{'original_form'} }{'ThisTableName'};
        my ($grp) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name='Public'" );
        my $to_grp = $grp;

        $sid = $dbc->Table_append_array(
            'Submission',
            [qw(Submission_DateTime Submission_Source Submission_Status FKSubmitted_Employee__ID Table_Name Key_Value FKTo_Grp__ID FKFrom_Grp__ID)],
            [ &date_time(), 'Internal', $draft, $user_id, $starting_form, undef, $to_grp, $grp ],
            -autoquote => 1,
            -debug     => 1
        );
    }
    if (JSON->VERSION =~/^1/) { $roadmap = JSON::objToJson($roadmap) }
    else { $roadmap = JSON::to_json($roadmap) }
    

    ### Our data hash now contains the meat of the submission, so save it to file for later retrieval
    &write_to_file( $dbc, \%data_raw, 'xml', $sid, -roadmap => $roadmap );
    &write_to_file( -dbc => $dbc, -type => 'txt', -sid => $sid, -submit_type => $submit_type );

    unless ($draft) {

        # When Submitted, then show the Hidden fields so that Admins can edit them if required
        &Modify_Submission_Remove_Field( -dbc => $dbc, -sid => $sid, -flag => 'Omit' );

        # When Submitted, then show the Greyed out fields so that Admins can edit them if required
        &Modify_Submission_Remove_Field( -dbc => $dbc, -sid => $sid, -flag => 'Grey' );

        &Send_Submission_Email( -dbc => $dbc, -sid => $sid );
    }

    return $sid;
}

##################################
#
#
###########################
sub Send_Submission_Email {
###########################
    my %args = &filter_input( \@_, -args => 'dbc,sid', -mandatory => 'dbc,sid' );
    my $dbc  = $args{-dbc};
    my $sid  = $args{-sid};

    my %s_info = $dbc->Table_retrieve(
        'Submission',
        [   'Submission_DateTime', 'Submission_Source', 'Submission_Status', 'FK_Contact__ID', 'FKSubmitted_Employee__ID', 'Submission_Comments', 'FKApproved_Employee__ID', 'Approved_DateTime',
            'FKTo_Grp__ID',        'FKFrom_Grp__ID',    'Table_Name',        'Key_Value',      'Reference_Code'
        ],
        "WHERE Submission_ID=$sid"
    );

    my $from_grp       = $s_info{FKFrom_Grp__ID}[0];
    my $target_grp     = $s_info{FKTo_Grp__ID}[0];
    my $source         = $s_info{Submission_Source}[0];
    my $reference_code = $s_info{Reference_Code}[0];

    my $body;
    my $submitter_name;
    my $submitter_email;
    my ( $from_email, $from_name );
    my $to_email;
    my $cc_email;
    my $bcc_email;

    my ($public_grp) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name='Public'" );

    if ( $s_info{FK_Contact__ID}[0] ) {
        my %q = $dbc->Table_retrieve( 'Contact', [ 'Contact_Name', 'Contact_Email' ], "WHERE Contact_ID=$s_info{FK_Contact__ID}[0]" );
        $submitter_name  = $q{Contact_Name}[0];
        $submitter_email = $q{Contact_Email}[0];
    }
    elsif ( $s_info{FKSubmitted_Employee__ID}[0] ) {
        my %q = $dbc->Table_retrieve( 'Employee', [ 'Employee_FullName', 'Email_Address' ], "WHERE Employee_ID=$s_info{FKSubmitted_Employee__ID}[0]" );
        $submitter_name  = $q{Employee_FullName}[0];
        $submitter_email = $q{Email_Address}[0];
    }
    elsif ( $s_info{Table_Name}[0] eq 'Employee' ) {
        ## submission for new account ##
        $submitter_name = 'Guest';
    }
    else {
        $dbc->error("Error: Could not identify the submitter of the submission.");
        return 0;
    }

    #######################################
    # Send email notification to lab admins
    #######################################
    my $header = "Content-type: text/html\n\n";

    my $submitted_from = $dbc->get_FK_info( 'FK_Grp__ID', $from_grp );
    my $submitted_to   = $dbc->get_FK_info( 'FK_Grp__ID', $target_grp );
    my $submission_type = $s_info{Table_Name}[0];
    my $info_table = HTML_Table->new( -border => 0 );
    $info_table->Set_Row( [ 'Submission id:',   $sid ] );
    $info_table->Set_Row( [ 'Submission Type:', $submission_type ] );
    $info_table->Set_Row( [ 'Submitted by:',    "$submitter_name ($submitter_email)" ] );
    $info_table->Set_Row( [ 'Submitted at:',    $s_info{Submission_DateTime}[0] ] );
    $info_table->Set_Row( [ 'Submitted from:',  $submitted_from ] );
    $info_table->Set_Row( [ 'Submitted to:',    $submitted_to ] );
    $info_table->Set_Row( [ 'Comments:',        $s_info{Submission_Comments}[0] ] );
    $info_table->Set_Row( [ 'SOW:',             $s_info{Reference_Code}[0] ] );

    my $status = $s_info{Submission_Status}[0];

    my $subject = "BCCRC GSC alDente Submission - Submission ID $sid - $status";

    $info_table->Set_Title("The following submission has been <b>$status<b>");
    my @grp_array;

    if ( $status =~ /Submitted/ ) {
        $to_email = join ', ', @{ &SDB::User::get_email_list( $dbc, 'admin,report', -group => $target_grp ) };

        # add the person who is ordering on the cc email list
        $cc_email = join ', ', ( @{ &SDB::User::get_email_list( $dbc, 'admin,report', -group => $from_grp ) }, $submitter_email );

        push( @grp_array, $from_grp );

        $bcc_email = 'aldente';
        if ( $source eq 'Internal' ) {
            $from_name  = $submitter_name;
            $from_email = $submitter_email;
        }
        elsif ( $source eq 'External' ) {
            $from_name  = 'Genome Sciences Centre LIMS';
            $from_email = 'aldente';
        }
        else {
            Message("Error: Unknown submission source '$source'");
            return 0;
        }
    }
    elsif ( $status =~ /Draft/i ) {
        ## Do nothing
        return 0;
    }
    elsif ( $status =~ /Cancelled|Rejected|Approved/i ) {
        $from_name  = 'Genome Sciences Centre LIMS';
        $from_email = 'aldente';
        $to_email   = $submitter_email;
        $cc_email   = 'aldente';
    }
    else {
        Message("Error: Unknown status ($status)");
        return 0;
    }

    my $msg = $info_table->Printout(0);
    $msg .= &SDB::Submission::Load_Submission( -dbc => $dbc, -sid => $sid, -action => 'view,emailoutput', -return_html => 1 );    # -external => 1

    $subject = "$status: $submission_type Submission from $submitted_from to $submitted_to (Submission ID $sid)";

    ## retrieve project name
    my $project_id;
    my $project_name;
    if ( $submission_type eq 'Original_Source' ) {
        $project_id = get_submission_field( -dbc => $dbc, -sid => $sid, -field => 'Library.FK_Project__ID' );
        $project_name = $dbc->get_FK_info( -field => 'FK_Project__ID', -id => $project_id ) if ($project_id);
    }
    elsif ( $submission_type eq 'Work_Request' ) {
        my $lib = get_submission_field( -dbc => $dbc, -sid => $sid, -field => 'Work_Request.FK_Library__Name' );

        my ($project_info) = $dbc->Table_find( 'Library,Project', 'Project_ID,Project_Name', "where Library_Name = '$lib' and FK_Project__ID = Project_ID" );
        ( $project_id, $project_name ) = split ',', $project_info;
    }
    if ($project_name) {
        $subject = "<$project_name> " . $subject;
    }

    push( @grp_array, $target_grp );
    my $subscription_event_name = 'Submission';
    if ( $status =~ /Approved/i ) {
        $subscription_event_name = 'Approved Submission';
        if ( $s_info{Table_Name}[0] eq 'Employee' ) {
            $subscription_event_name = 'Approved Employee Submission';
            @grp_array               = (1);                              ## New Employee Submissions should only be sent to submitted employee and aldente
        }
    }
    elsif ( $status =~ /Submitted/i ) {
        $subscription_event_name = 'Submitted Submission';
        if ( $s_info{Table_Name}[0] eq 'Employee' ) {
            $subscription_event_name = 'Submitted Employee Submission';
            @grp_array               = (1);
        }
    }
    elsif ( $status =~ /Cancelled/i ) {
        $subscription_event_name = 'Cancelled Submission';
        if ( $s_info{Table_Name}[0] eq 'Employee' ) {
            $subscription_event_name = 'Cancelled Employee Submission';
            @grp_array               = (1);
        }
    }

    if ( $s_info{Table_Name}[0] eq 'Employee' ) {
        my $submission_ref;
        $submission_ref = &SDB::Submission::Retrieve_Submission( -dbc => $dbc, -sid => $sid );
        my %submission    = %$submission_ref;
        my $employee_name = $submission{1}{0}{Employee_FullName};
        $submitter_email = $submission{1}{0}{Email_Address};
        if ( $subscription_event_name =~ /Submitted/ ) {

            # Integrate error notification with Issue Tracker.
            my %params;
            my %originals;

            my $notes   = "New LIMS Account Request for $employee_name";
            my $message = "New Employee Submission: Request for new LIMS account for $employee_name. Please view Submission $sid for more details.";

            ## type 3 = 'Task';
            my $issue_tracker = 'jira';
            if ( $issue_tracker =~ /jira/i ) {
                %params = (
                    'project'     => $dbc->config('jira_project'),
                    'type'        => '3',
                    'summary'     => $notes,
                    'description' => $message,
                );
            }

            require alDente::Issue;    ## dynamically load
            my $updated = &alDente::Issue::Update_Issue( -dbc => $dbc, -parameters => \%params, -originals => \%originals );
        }
    }

    my $ok = alDente::Subscription::send_notification(
        -dbc          => $dbc,
        -name         => $subscription_event_name,
        -from         => "$from_name <$from_email>",
        -subject      => $subject,
        -body         => $msg,
        -content_type => 'html',
        -group        => \@grp_array,
        -project      => $project_id,
        -cc_address   => $submitter_email
    );

    if ( !$ok ) {
        Message("Failed to send submission notification (Target: $to_email).");
    }
    return;
}

######################
sub Cancel_Submission {
######################
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'dbc,sid,source,action,status,resubmit', -mandatory => 'dbc' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sid      = $args{-sid};
    my $no_email = $args{-no_email} || 0;

    my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Cancelled', -no_email => $no_email );
    $dbc->Table_update_array( 'Submission', ['Key_Value'], ['N/A'], "WHERE Submission_ID=$sid", -autoquote => 1 );

    if ($ok) {
        $dbc->message( "Submission ID $sid is cancelled.", Get_DBI_Error() );
    }
    else {
        $dbc->warning( "Error cancelling submission ID $sid.", Get_DBI_Error() );
    }

    return;
}

######################
sub Reject_Submission {
######################
    my %args = &filter_input( \@_, -args => 'dbc,sid,source,action,status,resubmit', -mandatory => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sid = $args{-sid};

    my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Rejected' );
    $dbc->Table_update_array( 'Submission', ['Key_Value'], ['N/A'], "WHERE Submission_ID=$sid", -autoquote => 1 );
    if ($ok) {
        Message( "Submission ID $sid is rejected.", Get_DBI_Error() );
    }
    else {
        Message( "Error rejecting submission ID $sid.", Get_DBI_Error() );
    }
    return;
}

#############################
sub Activate_Submission {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,sid,source,action,status,resubmit', -mandatory => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sid = $args{-sid};

    my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Submitted' );

    if ($ok) {
        Message( "Submission ID $sid has been submitted.", Get_DBI_Error() );
    }
    else {
        Message( "Error reactivating submission ID $sid.", Get_DBI_Error() );
    }
    return;
}

######################
sub Archive_Submission {
######################
    my %args = &filter_input( \@_, -args => 'dbc,sid,source,action,status,resubmit', -mandatory => 'dbc' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sid = $args{-sid};

    my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Completed' );
    if ($ok) {
        Message( "Submission ID $sid is submitted.", Get_DBI_Error() );
    }
    else {
        Message( "Error reactivating submission ID $sid.", Get_DBI_Error() );
    }
    return;
}

##################################
sub Load_Submission {
##################################
    my %args = &filter_input( \@_, -args => 'dbc,sid,source,action,status,resubmit', -mandatory => 'dbc' );
    my $dbc                    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sid                    = $args{-sid};
    my $action                 = $args{-action};                                                                  # Can be 'load','view','add','edit'
    my $external               = $dbc->{file} =~ /alDente_public\.pl/;                                            #$args{-external};                                                                # screens functionality for external users
    my $img_dir                = $args{-image_dir};                                                               # (Scalar) Image directory for folder images
    my $return_html            = $args{-return_html};
    my $require_file           = $args{-require_file};
    my $fk_original_source__id = $args{-fk_original_source_id};
    my $library_name           = $args{-library_name};

    my $user_id = $dbc->get_local('user_id');

    my $load           = ( $action =~ /load/i );
    my $view           = ( $action =~ /view/i );
    my $approve        = ( $action =~ /approve/i );
    my $edit           = ( $action =~ /edit/i );
    my $cancel         = ( $action =~ /cancel/i );
    my $reject         = ( $action =~ /reject/i );
    my $archive        = ( $action =~ /completed/i );
    my $activate       = ( $action =~ /activate|SubmitDraft/i );
    my $email_output   = ( $action =~ /emailoutput/i );
    my $saveasnew      = ( $action =~ /saveasnew/i );
    my $copynewlibrary = ( $action =~ /copynewlibrary/i );
    my $output         = '';
    my $sub_table;
    my $ok;
    my %fields;    # Contains the mapping between field name and field descriptions
    my $modified = 1;                 # A flag indicating whether the submission has been modified by library admin.
    my $prev_approved_table;          # The previous table that was approved.  Normally this corresponds to the final table of the submission process.
    my $prev_approved_table_index;    # The previous table index that was approved.  Normally this corresponds to the final table of the submission process.
    my $prev_approved_record;         # The previous record that was approved. Normally this corresponds to the final record of the submission process.

    my $homelink = $dbc->homelink();
    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    $path .= $sub_dir;

    ## <Construction>  - placed here to ensure that omit and greyed out fields are removed when a submission is reloaded ##
    if ( $action =~ /edit/ ) {

        # When a submission is changed to Submitted, then show the Hidden fields so that Admins can edit them if required
        &Modify_Submission_Remove_Field( -dbc => $dbc, -sid => $sid, -flag => 'Omit' );

        # When a submission is changed to Submitted, then show the Greyed out fields so that Admins can edit them if required
        &Modify_Submission_Remove_Field( -dbc => $dbc, -sid => $sid, -flag => 'Grey' );
    }

    my $submission_ref;
    $submission_ref = &SDB::Submission::Retrieve_Submission( -dbc => $dbc, -sid => $sid );

    unless ($submission_ref) {
        return 0;
    }

    my %submission;
    my $OLD_SUBMISSION_STRUCTURE = 0;

    if ( defined $submission_ref->{'ext_submission_dir'} ) {
        ### For backward compatibility, using an obsolete field to check
        $OLD_SUBMISSION_STRUCTURE = 1;
        %submission               = %{$submission_ref};
    }
    else {
        %submission = %{ &SDB::DB_Form::conv_FormNav_to_DBIO_format( -dbc => $dbc, -data => $submission_ref ) };
    }

    my ($status) = $dbc->Table_find( 'Submission', 'Submission_Status', "WHERE Submission_ID=$sid" );

    # list attachments and their links
    my $attach_ref = &SDB::Submission::get_attachment_list( -dbc => $dbc->dbc(), -sid => $sid );
    my $full_attach_list = &SDB::Submission::get_attachment_list( -dbc => $dbc->dbc(), -sid => $sid, -fullpath => 1 );

    # determine if this is a batch submission
    ### ARE WE SUPPORTING BATCH SUB?
    my $is_batchsub = 0;
    my $batch_file  = '';
    if ( ( int( @{$full_attach_list} ) > 0 ) && ( grep /batchfile\.csv/, @{$full_attach_list} ) ) {
        $is_batchsub = 1;
        my $curr_version = 0;

        # determine which is the latest batch submission file
        foreach my $file ( @{$full_attach_list} ) {
            if ( $file =~ /batchfile\.csv\.(\d+)$/ ) {
                if ( $curr_version < $1 ) {
                    $curr_version = $1;
                    $batch_file   = $file;
                }
            }
            else {
                $batch_file = $file;
            }
        }
    }

    my @headers = ( 'Record #', 'Field', 'Value' );
    if ($load) {

        #Just return the hash.
        return %submission;
    }
    elsif ($cancel) {
        my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Cancelled' );
        $dbc->Table_update_array( 'Submission', ['Key_Value'], ['N/A'], "WHERE Submission_ID=$sid", -autoquote => 1 );
        if ($ok) {
            Message( "Submission ID $sid is cancelled.", Get_DBI_Error() );
        }
        else {
            Message( "Error cancelling submission ID $sid.", Get_DBI_Error() );
        }
        return 0;
    }
    elsif ($activate) {
        my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Submitted' );
        if ($ok) {

            #Message("Submission ID $sid has been submitted.",Get_DBI_Error());
            return Message( "Submission ID $sid has been submitted.", Get_DBI_Error() );

        }
        else {
            Message( "Error reactivating submission ID $sid.", Get_DBI_Error() );
        }
        return 0;
    }
    elsif ($reject) {
        my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Rejected', -dbc => $dbc );
        $dbc->Table_update_array( 'Submission', ['Key_Value'], ['N/A'], "WHERE Submission_ID=$sid", -autoquote => 1 );
        if ($ok) {
            Message( "Submission ID $sid is rejected.", Get_DBI_Error() );
        }
        else {
            Message( "Error rejecting submission ID $sid.", Get_DBI_Error() );
        }
        return 0;
    }
    elsif ($archive) {
        my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Completed' );
        if ($ok) {
            Message( "Submission ID $sid is completed.", Get_DBI_Error() );
        }
        else {
            Message( "Error completing submission ID $sid.", Get_DBI_Error() );
        }
        return 0;
    }
    elsif ($view) {

        #Display the info.
        #Do the mapping of field names and field descriptions.
        foreach my $table_index ( sort { $a <=> $b } keys( %{ $submission{index} } ) ) {
            my $table = $submission{index}{$table_index};
            my %info  = $dbc->Table_retrieve( 'DBTable,DBField', [ 'Field_Name', 'Prompt' ], "where DBTable_ID = FK_DBTable__ID and DBTable_Name = '$table'", -debug => 0 );
            my $i     = 0;
            while ( defined $info{Field_Name}[$i] ) {
                $fields{$table}->{ $info{Field_Name}[$i] } = $info{Prompt}[$i];
                $i++;
            }
        }

        $sub_table = HTML_Table->new( -toggle => 0, -bgcolour => 'white', -border => 1 );
        $sub_table->Set_Title("Submission ID $sid");
    }
    elsif ($edit) {
        ### Not sure if batch editing is supported right now....
        #Bring user to forms so they can edit the info before update.
        # if it is a batch submission, then edit the batch file, not the forms
        if ($is_batchsub) {
            require SDB::DIOU;
            Message("opening $batch_file");
            &SDB::DIOU::edit_submission_file(
                -mandatory_fields => ['Library_Name'],
                -tables           => "Original_Source,Source,Library,RNA_DNA_Source,RNA_DNA_Collection",
                -file             => $batch_file,
                -deltr            => 'tab'
            );
        }
        elsif ($OLD_SUBMISSION_STRUCTURE) {
            $dbc->error("Can not edit submissions (Contains old file structure). Please contact Site Admin for editing it");
        }
        else {
            my $roadmap = &Retrieve_Submission( -dbc => $dbc, -sid => $sid, -output_file => 'roadmap' );
            my @fields = qw(Table_name Submission_Comments);
            my ($results) = $dbc->Table_find_array( 'Submission', \@fields, "WHERE Submission_ID=$sid" );
            my ( $table, $submission_comments ) = split( ',', $results );
            $output .= "Submission Comments: $submission_comments<br>" if $submission_comments;

            my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $table, -submission_id => $sid, -external_form => $external, -target => 'Submission' );
            my $project_id;
            if ($external) { $project_id = $project }

            require alDente::Submission_App;
            my $submit_type       = get_Submit_Type( -dbc       => $dbc, -sid => $sid, );    #
            my $submission_source = get_submission_source( -dbc => $dbc, -sid => $sid );
            if ( $submission_source =~ /external/i ) {
                my %configs = alDente::Submission_App::get_Configs( -dbc => $dbc, -submit_type => $submit_type, -project_id => $project_id, -library_name => $library_name, -admin => 1 )
                    if $submit_type;                                                         ## -target_group => $target_group, -contact_id => $contact_id
                $form->configure(%configs);
            }
            $form->{formData}          = $submission_ref;
            $form->{DisableCompletion} = $require_file;                                      ## Disables completion if file is required
            $form->{Require_File}      = $require_file;
            $form->{Limit_Edit}        = 1;

            if ($require_file) {
                $form->{Submission}{Grey} = ['File_Required'];
                $form->{Submission}{Preset} = { 'File_Required' => 'yes' };
            }

            #  print HTML_Dump $form;
            $output .= $form->generate( -navigator_on => 1, -roadmap => $roadmap, -return_html => 1 );
        }
    }

    my $prev_approved_table_found = 0;
    my %newids;
    my %inserted_records;
    my %List;

    if ($view) {

        # <CUSTOM> do a check to see if LibraryApplication entries (Primer) are valid
        if ( grep( /^LibraryApplication$/, keys( %{ $submission{tables} } ) ) && grep( /^LibraryVector$/, keys( %{ $submission{tables} } ) ) && !$external ) {
            foreach my $count ( keys %{ $submission{tables}{'LibraryApplication'} } ) {
                my $lib             = $submission{tables}{'LibraryApplication'}{$count}{'FK_Library__Name'};
                my $primer_id       = $submission{tables}{'LibraryApplication'}{$count}{'Object_ID'};
                my $object_class_id = $submission{tables}{'LibraryApplication'}{$count}{'FK_Object_Class__ID'};
                my $vector_id       = $submission{tables}{'LibraryVector'}{1}{'FK_Vector__ID'};
                if ( $lib && $primer_id && $object_class_id && $vector_id && ( $vector_id =~ /\d+/ ) ) {
                    my ($class) = $dbc->Table_find( "Object_Class", "Object_Class", "WHERE Object_Class_ID=$object_class_id" );
                    if ( $class eq 'Primer' ) {
                        my ($primer_name) = $dbc->Table_find( "Primer",             "Primer_Name",      "WHERE Primer_ID=$primer_id" );
                        my ($vector_name) = $dbc->Table_find( "Vector,Vector_Type", "Vector_Type_Name", "WHERE FK_Vector_Type__ID=Vector_Type_ID AND Vector_ID=$vector_id" );
                        my ($valid) = $dbc->Table_find( "Primer,Vector_TypePrimer,Vector_Type,Vector",
                            "Primer_Name", "WHERE FK_Primer__ID=Primer_ID AND Vector_TypePrimer.FK_Vector_Type__ID=Vector_Type_ID AND Vector.FK_Vector_Type__ID=Vector_Type_ID AND Primer_ID = $primer_id AND Vector_ID = $vector_id" );
                        unless ($valid) {
                            Message("Warning: Suggested Primer ($primer_name) is not a valid primer for Vector ($vector_name)");
                        }
                    }
                }
            }
        }

        # if viewing, then build the list of tables
        foreach my $table ( sort { $a <=> $b } values %{ $submission{index} } ) {
            my %info = $dbc->Table_retrieve( 'DBField,DBTable', [ 'DBTable_Title', 'Field_Name', 'Prompt' ], "WHERE DBTable_ID=FK_DBTable__ID AND DBTable_Name='$table'" );
            my %prompts;
            @prompts{ @{ $info{'Field_Name'} } } = @{ $info{'Prompt'} };
            my $table_alias = $info{'DBTable_Title'}->[0];
            foreach my $index ( sort { $a <=> $b } keys %{ $submission{tables}{$table} } ) {
                foreach my $field ( keys %{ $submission{tables}{$table}{$index} } ) {
                    my $value = $submission{tables}{$table}{$index}{$field};

                    # check if the FK exists in the database
                    # if it is, give a link
                    if ( $value =~ /<\w+\.\w+>/ ) {
                        next;
                    }
                    my $label;
                    if ( $field =~ /^Object_ID$/ ) {
                        my $object_class_id = $submission{tables}{$table}{$index}{'FK_Object_Class__ID'};
                        my ($class) = $dbc->Table_find( "Object_Class", "Object_Class", "WHERE Object_Class_ID=$object_class_id" );
                        $label = $dbc->get_FK_info( $field, $value, -class => $class );
                        $value = &Link_To( -link_url => $homelink, -label => $label, -param => "&HomePage=$class&ID=$value" ) unless ($external);

                    }
                    elsif ( my ( $fk_tablename, $field_name, undef ) = $dbc->foreign_key_check($field) ) {
                        $label = $dbc->get_FK_info( $field, $value );
                        $value = &Link_To( -link_url => $homelink, -label => $label, -param => "&HomePage=$fk_tablename&ID=$value" ) unless ($external);
                    }
                    $label ||= $value;
                    my @row = ( $index + 1, $prompts{$field}, $label );
                    unless ( defined $List{$table} ) {
                        $List{$table} = new HTML_Table->new( -title => "$table_alias information", -width => '100%' );
                        $List{$table}->Set_Headers( \@headers );
                        $List{$table}->Toggle_Colour_on_Column(1);
                    }
                    $List{$table}->Set_Row( \@row );
                }
            }
        }
    }
    elsif ($approve) {

        # initialize transaction
        # Starts transaction
        $dbc->start_trans('submission');

        # batch insert values with override flag
        eval {

            # if it is a batch submission, add batch file
            if ($is_batchsub) {
                require alDente::Submission;
                my $success = &alDente::Submission::insert_submission_file( -dbc => $dbc, -sid => $sid, -filename => $batch_file, -delim => 'tab', -type => 'microarray' );
                if ( !$success ) {
                    die "Error in file submission";
                }
            }
            else {

         #<CONSTRUCTION>: Unsure why ignore duplicate was turned on before
         #It caused more trouble if a duplicate library name was present and ignorning it will casue Work_Request/Source/etc to assoicate with the old library instead of trying to make a new one and associate with the new one. Therefore turning it off now
         #However, for work request submissions, library application is often re-enter again, so only not ignore duplicate for Library submission
                my $on_duplicate_ignore = 1;
                for my $key ( keys %{ $submission{index} } ) {
                    if ( $submission{index}{$key} eq 'Library' ) { $on_duplicate_ignore = 0; }
                }

                ### update submission info with what's in the file and delete submission so that i will not add a duplicate new one
                my @submission_fields = keys %{ $submission{'tables'}{'Submission'}{'0'} };
                my @submission_values = values %{ $submission{'tables'}{'Submission'}{'0'} };
                $dbc->Table_update_array( 'Submission', \@submission_fields, \@submission_values, "WHERE Submission_ID=$sid", -autoquote => 1 );
                ### Remove Submission entries from data object
                delete $submission{'tables'}{'Submission'};

                # Check duplicate initials in the case of new employee account
                my $employee = $submission{'tables'}{'Employee'};
                if ( defined $employee ) {
                    my $initials = $employee->{'0'}{'Initials'};
                    if ( defined $initials ) {
                        my $new_initials = $initials;
                        my $index        = 1;
                        my $duplicate;

                        while ( $index < 100 ) {
                            $duplicate = $dbc->Table_find( 'Employee', 'Initials', "where Initials = '$new_initials'" );
                            if ($duplicate) { $new_initials = $initials . $index; }
                            else            { last; }
                            $index++;
                        }
                        $submission{'tables'}{'Employee'}{'0'}{'Initials'} = $new_initials;
                    }
                }

                if ( defined $submission{'tables'}{Original_Source} ) {
                    $submission{'tables'}{'Original_Source'}{'0'}{'FKCreated_Employee__ID'} = $user_id;
                }
                if ( defined $submission{'tables'}{Source} ) {
                    $submission{'tables'}{'Source'}{'0'}{'FKReceived_Employee__ID'} = $user_id;
                }
                if ( defined $submission{'tables'}{Library} ) {
                    $submission{'tables'}{'Library'}{'0'}{'FKCreated_Employee__ID'} = $user_id;
                }

                my $insert_ids = $dbc->Batch_Append( -data => \%submission, -on_duplicate_ignore => $on_duplicate_ignore );
                if ($insert_ids) {
                    %newids = %{$insert_ids};
                }
                else {
                    die "Error in batch append";
                }
            }
        };

        #Finally update the submission status.
        if ($@) {
            Call_Stack();
            $dbc->finish_trans( 'submission', -error => $@ );
            return;
        }
        else {
            if ( defined $dbc->transaction->{newids} ) {
                my %transaction_ids = %{ $dbc->transaction->{newids} };

                foreach my $table ( keys %transaction_ids ) {
                    my @new_ids = @{ $transaction_ids{$table} };
                    foreach my $new_id (@new_ids) {
                        $dbc->Table_append_array( 'Submission_Table_Link', [ 'FK_Submission__ID', 'Table_Name', 'Key_Value' ], [ $sid, $table, $new_id ], -autoquote => 1 );
                    }
                }
            }

            $dbc->finish_trans('submission');
            my $ok = &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Approved' );
            my $table_name = join ',', $dbc->Table_find( 'Submission', 'Table_Name', "WHERE Submission_ID=$sid" );
            unless ( $table_name =~ /File Submission/i ) {
                my ($primary_field) = $dbc->get_field_info( $table_name, undef, 'Primary' );
                $dbc->Table_update_array( 'Submission', ['Key_Value'], [ $newids{"$table_name.$primary_field"} ], "WHERE Submission_ID=$sid", -autoquote => 1 );
            }
            $output .= vspace(5) . &Link_To( $dbc->config('homelink'), 'Check Other Submissions', "&Check+Submissions=1", $Settings{LINK_COLOUR} );
            return \%newids;
        }
    }

    elsif ( $saveasnew || $copynewlibrary ) {
        if ($OLD_SUBMISSION_STRUCTURE) {
            Message("Error: Can not save a copy of older submissions (prior to release 2.5)");
            return;
        }

        my ( @excludes, @replaces );

        @excludes = qw(Submission_ID
            Submission_DateTime
            Submission_Source
            Submission_Status
            FKApproved_Employee__ID
            Approved_DateTime
            Key_Value);
        @replaces = ( undef, &date_time(), $external ? 'External' : 'Internal', 'Draft', undef, undef, undef );

        if ($external) {
            push( @excludes, 'FKSubmitted_Employee__ID' );
            push( @replaces, undef );
        }
        else {
            push( @excludes, 'FKSubmitted_Employee__ID', 'FK_Contact__ID' );
            push( @replaces, $user_id, undef );
        }

        my ($new_sub_id) = $dbc->Table_copy(
            -table     => 'Submission',
            -condition => "WHERE Submission_ID=$sid",
            -exclude   => \@excludes,
            -replace   => \@replaces
        );

        if ($new_sub_id) {
            Message("Submission $sid copied to <font color=red>Submission $new_sub_id</font>.");
            Message("Please note that this submission has been saved as a 'Draft' and still needs to be 'Submitted'");

            try_system_command("cp -R $path/$status/submission_${sid}/ $path/Draft/submission_${new_sub_id}/");
            try_system_command("chmod 777 -R $path/Draft/submission_${new_sub_id}/");

            my @content = glob("$path/Draft/submission_${new_sub_id}/*");
            push( @content, glob("$path/Draft/submission_${new_sub_id}/attachments/*") );

            foreach my $file (@content) {
                if ( -f $file ) {
                    my $newfile = $file;
                    $newfile =~ s/sub_$sid/sub_${new_sub_id}/g;
                    try_system_command("mv $file $newfile");
                }
            }

            if ($copynewlibrary) {
                my $input_file  = "$path/Draft/submission_${new_sub_id}/map.json";
                my $output_file = "$path/Draft/submission_${new_sub_id}/map.json";    #$input_file;

                my $result = &SDB::Submission::update_submission_file( -file_path => $input_file, -old_value => '"FK_Original_Source__ID":"[^"]+', -new_value => "\"FK_Original_Source__ID\"\:\"$fk_original_source__id", -dest_file_path => $output_file );

                my $result = &SDB::Submission::update_submission_file( -file_path => $input_file, -old_value => '"FK_Library__Name":"[^"]+', -new_value => "\"FK_Library__Name\"\:\"$library_name", -dest_file_path => $output_file );

                # xml portion. in the end 1st call will have file_path = source file, dest = source file, 2nd call w/ file_path & dest both set to source file

                # only the xml file with the largest suffix (most updated one) will be modified
                my @files       = glob("$path/Draft/submission_${new_sub_id}/sub_*.xml");
                my $max_filenum = 1;

                # error check - if there are no files, return
                if ( int(@files) > 0 ) {
                    foreach my $fullpath (@files) {
                        my ( $dir, $file ) = &Resolve_Path($fullpath);
                        my ($num) = $file =~ /sub_\d+.(\d+).xml/;
                        if ( $num > $max_filenum ) {
                            $max_filenum = $num;
                        }
                    }

                    # increment max_filenum
                    $max_filenum++;
                }
                $max_filenum--;

                my $input_file  = "$path/Draft/submission_${new_sub_id}/sub_${new_sub_id}.${max_filenum}.xml";
                my $output_file = "$path/Draft/submission_${new_sub_id}/sub_${new_sub_id}.${max_filenum}.xml";    #$input_file;

                my $result = &SDB::Submission::update_submission_file(
                    -file_path      => $input_file,
                    -old_value      => '<item key="FK_Original_Source__ID">[^<]+',
                    -new_value      => "<item key=\"FK_Original_Source__ID\">$fk_original_source__id",
                    -dest_file_path => $output_file
                );

                my $result = &SDB::Submission::update_submission_file( -file_path => $input_file, -old_value => '<item key="FK_Library__Name">[^<]+', -new_value => "<item key=\"FK_Library__Name\">$library_name", -dest_file_path => $output_file );
                Message("$input_file and Map.json has been updated");

            }
        }
        else {
            Message("Error: Submission did not copy properly. Please submit an issue");
        }
        return Link_To(
            $dbc->{homelink},
            "<Font size=+2>Your Submission ID is: <B>$new_sub_id</B   (Click here to review or to attach a file to this Submission)</Font>",
            "&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$new_sub_id&external=1"
            )

    }
    elsif ($copynewlibrary) {

        # this block will do what saveasnew block does except
        # change the portion of the file which records the information of the library and library source
    }
    if ($view) {
        $output .= "<BR>";

        my %super_table = %{ combine_Tables( \%List ) };
        if ($email_output) {
            foreach ( keys %List ) {
                $sub_table->Set_Row( [ $List{$_}->Printout(0) ] );
            }
        }
        elsif ($img_dir) {
            $sub_table->Set_Row( [ SDB::HTML::create_tree( -tree => \%super_table, -closed_image => "$img_dir/closed.gif", -open_image => "$img_dir/open.gif" ) ] );
        }
        else {
            $sub_table->Set_Row( [ SDB::HTML::create_tree( -tree => \%super_table ) ] );
        }
        $output .= $sub_table->Printout(0);

        unless ($email_output) {
            $output .= '<br>'
                . $dbc->Table_retrieve_display(
                'Submission',
                [ 'Submission_ID', 'Submission_DateTime', 'Submission_Source', 'Submission_Status', 'FK_Contact__ID', 'FKSubmitted_Employee__ID', 'Submission_Comments', 'FKTo_Grp__ID as To_Grp', 'FKFrom_Grp__ID as From_Grp', 'Reference_Code' ],
                "WHERE Submission_ID=$sid",
                -return_html => 1
                );

            $output .= h2("Attachments");
            foreach my $file (@$attach_ref) {

                # only allow attachment viewing internally (may allow external viewing in the future)
                if ($external) {
                    $output .= "<a href='$path/$status/submission_${sid}/attachments/$file'>$file</a><br>";
                }
                else {
                    my $URL_path = $alDente::SDB_Defaults::URL_temp_dir;
                    if   ( $URL_path =~ m|\/(dynamic\/.*)| ) { $URL_path = $1; }
                    else                                     { $URL_path = $file; }
                    $output .= "<a href='/$URL_path/$file'>$file</a><br>";
                }
            }

            # start multipart form
            if ($external) {    #|| $status !~ /Draft/i
                
                require LampLite::Form_Views;
                
                $output .= LampLite::Form_Views::start_custom_form( "SubmissionUploadForm", -dbc=>$dbc );
                $output .= "<BR>Attach file:" . filefield( -name => 'Submission_Upload', -size => 30 ) . "<BR>";
                $output .= hidden( -name => 'Submission ID', -value => $sid );
                $output .= submit( -name => 'Attach', -class => "Action" );
                $output .= end_form();
            }

            ### Actions...
            $output .= br;
            $output .= "<ul>";
            if ($external) {
                if ( $status =~ /Draft/ ) {

                    #                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Edit submission',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=Edit",'blue') . br;
                    #                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Submit Draft',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=SubmitDraft",'blue') . br;
                    $output .= "<li>" . &Link_To( $dbc->config('homelink'), 'Edit submission', "&cgi_application=alDente::Submission_App&rm=Edit&Submission_ID=$sid",        'blue' ) . br;
                    $output .= "<li>" . &Link_To( $dbc->config('homelink'), 'Submit Draft',    "&cgi_application=alDente::Submission_App&rm=SubmitDraft&Submission_ID=$sid", 'blue' ) . br;

                }
            }
            else {
                if ( $status =~ /Draft/ ) {

                    #                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Edit submission',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=Edit",'blue') . br;
                    #                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Submit Draft',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=SubmitDraft",'blue') . br;
                    $output .= "<li>" . &Link_To( $dbc->config('homelink'), 'Edit submission', "&cgi_application=alDente::Submission_App&rm=Edit&Submission_ID=$sid",        'blue' ) . br;
                    $output .= "<li>" . &Link_To( $dbc->config('homelink'), 'Submit Draft',    "&cgi_application=alDente::Submission_App&rm=SubmitDraft&Submission_ID=$sid", 'blue' ) . br;

                }
                elsif ( $status =~ /Submitted/i ) {
                    if ( ( $submission{flags}->{isNewLibrary}->{1} && !$modified ) ) {

                        #Do not allow approval yet since library admin need to fill in library name etc.
                    }
                    else {

#                        $output .="<li>" . &Link_To( $dbc->config('homelink'),'Approve submission and update database',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=Approve",'blue','',"onclick=\"return confirm('Are you sure you want to approve submission ID $sid?');\"") . br;
                        $output .= "<li>"
                            . &Link_To(
                            $homelink,
                            'Approve submission and update database',
                            "&cgi_application=alDente::Submission_App&rm=Approve&Submission_ID=$sid",
                            'blue', '', "onclick=\"return confirm('Are you sure you want to approve submission ID $sid?');\""
                            ) . br;

                    }

                    #                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Edit submission',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=Edit",'blue') . br;
                    $output .= "<li>" . &Link_To( $dbc->config('homelink'), 'Edit submission', "&cgi_application=alDente::Submission_App&rm=Edit&Submission_ID=$sid", 'blue' ) . br;

                    if ( !$is_batchsub ) {
                        $output .= "<li>" . &Link_To( $dbc->config('homelink'), 'Edit submission as a re-submission', "&Submission_ID=$sid&Submission_Action=SubmitAsResubmission", 'blue' ) . br;

                        #                        $output .="<li>" . &Link_To( $dbc->config('homelink'),'Edit submission as a re-submission',"&cgi_application=alDente::Submission_App&rm=SubmitAsResubmission&Submission_ID=$sid",'blue') . br;

                    }

#                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Cancel submission',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=Cancel",'blue','',"onclick=\"return confirm('Are you sure you want to cancel submission ID $sid?');\"") . br;
#                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Reject submission',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=Reject",'blue','',"onclick=\"return confirm('Are you sure you want to reject submission ID $sid?');\"") . br;
                    $output
                        .= "<li>"
                        . &Link_To( $dbc->config('homelink'), 'Cancel submission', "&cgi_application=alDente::Submission_App&rm=Cancel&Submission_ID=$sid", 'blue', '', "onclick=\"return confirm('Are you sure you want to cancel submission ID $sid?');\"" )
                        . br;
                    $output
                        .= "<li>"
                        . &Link_To( $dbc->config('homelink'), 'Reject submission', "&cgi_application=alDente::Submission_App&rm=Reject&Submission_ID=$sid", 'blue', '', "onclick=\"return confirm('Are you sure you want to reject submission ID $sid?');\"" )
                        . br;

                }
                elsif ( $status =~ /Approved/i ) {

#                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Complete submission',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=Completed",'blue','',"onclick=\"return confirm('Are you sure you want to complete submission ID $sid?');\"") . br;
                    $output .= "<li>"
                        . &Link_To(
                        $dbc->config('homelink'),
                        'Complete submission',
                        "&cgi_application=alDente::Submission_App&rm=Completed&Submission_ID=$sid",
                        'blue', '', "onclick=\"return confirm('Are you sure you want to complete submission ID $sid?');\""
                        ) . br;

                }
                elsif ( $status =~ /Completed/i ) {
                    ###Do nothing.
                }
                elsif ( $status =~ /Cancelled/i ) {

#                    $output .="<li>" . &Link_To( $dbc->config('homelink'),'Activate cancelled submission',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=Activate",'blue','',"onclick=\"return confirm('Are you sure you want to change submission ID $sid to Submitted?');\"") . br;
                    $output .= "<li>"
                        . &Link_To(
                        $homelink,
                        'Activate cancelled submission',
                        "&cgi_application=alDente::Submission_App&rm=Activate&Submission_ID=$sid",
                        'blue', '', "onclick=\"return confirm('Are you sure you want to change submission ID $sid to Submitted?');\""
                        ) . br;

                }

                $output .= "<li>" . &Link_To( $dbc->config('homelink'), 'View/Edit Submission Info', "&Info=1&Table=Submission&Field=Submission_ID&Like=$sid", 'blue' ) . br;

            }

            ### Save as New
            unless ($OLD_SUBMISSION_STRUCTURE) {

                #                $output .="<li>" . &Link_To( $dbc->config('homelink'),'Save As a New Submission',"&cgi_application=alDente::Submission_App&rm=Submission+Action&Submission_ID=$sid&Submission_Action=SaveAsNew",'blue') . br;
                $output .= "<li>" . &Link_To( $dbc->config('homelink'), 'Save As a New Submission', "&cgi_application=alDente::Submission_App&rm=SaveAsNew&Submission_ID=$sid", 'blue' ) . br;

            }

            $output .= "</ul>";
        }
    }
    unless ($return_html) { print $output }
    return $output;
}

################################
sub Modify_Submission {
################################
    my %args        = &filter_input( \@_, -args => 'dbc,data_ref,sid' );
    my $dbc         = $args{-dbc};                                         # (ObjectRef) Database handle
    my $sid         = $args{-sid};                                         # (Scalar) Submission ID
    my $data_ref    = $args{-data_ref};                                    # (HashRef) Hash that contains all new information.
    my $roadmap     = $args{-roadmap};
    my $submit_type = $args{-submit_type};

    my $stored_ref = &Retrieve_Submission( -dbc => $dbc, -sid => $sid );

    #First merge the new hash with the submission file.
    ### Convert both data structures to DBIO format in order to figure out what fields have been modified and what tables have been added/deleted
    my %new = %{ &SDB::DB_Form::conv_FormNav_to_DBIO_format( -dbc => $dbc, -data => $data_ref ) };
    my %old = %{ &SDB::DB_Form::conv_FormNav_to_DBIO_format( -dbc => $dbc, -data => $stored_ref ) };

    my %updated_submission_fields;

    ######## Notify user about DELETED tables
    foreach my $table ( keys %{ $old{tables} } ) {
        unless ( exists $new{tables}{$table} ) {
            Message("Deleted table $table");
        }
    }

    ######## Notify user about ADDED tables
    foreach my $table ( keys %{ $new{tables} } ) {
        unless ( exists $old{tables}{$table} ) {
            Message("Added table $table");
        }
    }

    ######## Notify user about MODIFIED fields
    foreach my $table ( keys %{ $new{tables} } ) {
        foreach my $index ( keys %{ $new{tables}->{$table} } ) {
            foreach my $field ( keys %{ $new{tables}->{$table}->{$index} } ) {
                unless ( $old{tables}->{$table}->{$index}->{$field} eq $new{tables}->{$table}->{$index}->{$field} ) {
                    Message("Changed $table($index).$field from '$old{tables}->{$table}->{$index}->{$field}' to '$new{tables}->{$table}->{$index}->{$field}'");
                    if ( $table eq 'Submission' ) {
                        $updated_submission_fields{$field} = $new{tables}->{$table}->{$index}->{$field};
                    }
                }
            }
        }
    }

    # now save the modified data
    &write_to_file( $dbc, $data_ref, 'xml', $sid, -roadmap => $roadmap );
    &write_to_file( -dbc => $dbc, -type => 'txt', -sid => $sid, -submit_type => $submit_type );

    # update Submission table
    my $ok;
    if ( int( keys %updated_submission_fields ) ) {
        my @keys   = keys %updated_submission_fields;
        my @values = values %updated_submission_fields;
        $ok = $dbc->Table_update_array( 'Submission', \@keys, \@values, "WHERE Submission_ID=$sid", -autoquote => 1 );
        if ( !$ok ) {
            $dbc->error("Error updating Submission table (Submission ID $sid).");
        }
    }

    Message("Updated Submission $sid. This submission still needs to be approved") if ($ok);
}

##########################################
sub Modify_Submission_Remove_Field {
##########################################
    my %args    = &filter_input( \@_, -args => 'dbc,sid,flag', -mandatory => 'flag' );
    my $dbc     = $args{-dbc};                                                                     # (ObjectRef) Database handle
    my $sid     = $args{-sid};                                                                     # (Scalar) Submission ID
    my $flag    = $args{-flag};                                                                    # (Scalar) Json field to be blank out, eg 'Omit' for hidden fields
                                                                                                   # $submission_dir .= '/test';
                                                                                                   # get json file
    my $roadmap = &Retrieve_Submission( -dbc => $dbc, -sid => $sid, -output_file => 'roadmap' );

    #convert jason into perl object to manipulate
    require JSON;
    if (JSON->VERSION =~/^1/) { $roadmap = JSON::jsonToObj($roadmap) }
    else { $roadmap = JSON::from_json($roadmap) }

    #find the flag in the object and blank them out
    for my $key ( keys %{$roadmap} ) {
        if ( ref $roadmap->{$key} eq 'HASH' ) {
            $roadmap->{$key}{$flag} = '';
        }
    }

    #convert back to json format
    if (JSON->VERSION =~/^1/) { $roadmap = JSON::objToJson($roadmap) }
    else { $roadmap = JSON::to_json($roadmap) }

    # now save the modified json file
    &write_to_file( -dbc => $dbc, -sid => $sid, -roadmap => $roadmap );
}

################################
# Retrieve submission from file
################################
sub Retrieve_Submission {
################################
    my %args          = @_;
    my $dbc           = $args{-dbc};
    my $sid           = $args{-sid};
    my $output_format = $args{-output_format} || 'HASH';
    my $quiet         = $args{-quiet};
    my $output        = $args{-output_file} || 'data';

    # get the status
    my ($status) = $dbc->Table_find( "Submission", "Submission_Status", "WHERE Submission_ID=$sid" );
    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    $path .= $sub_dir;
    create_dir( $path, $sub_dir );

    # error check - see if the submission directory exists
    unless ( -e "$path/$status/submission_$sid" ) {
        Message("Submission directory '$path/$status/submission_$sid' does not exist or is unreadable");
        return;
    }

    if ( $output =~ /roadmap/ ) {
        my $map;
        if ( -e "$path/$status/submission_${sid}/map.json" ) {
            open my $MAP, "$path/$status/submission_${sid}/map.json" or die "$!\n";
            $map = <$MAP>;
            close $MAP;
        }
        return $map;
    }
    else {

        # retrieve the latest submission file
        my @files = glob("$path/$status/submission_${sid}/*");

        # error check - if there are no files, return
        if ( int(@files) == 0 ) {
            Message("No files matching submission $sid") unless ($quiet);
            return;
        }

        my $max_filenum = 1;
        foreach my $fullpath (@files) {
            my ( $dir, $file ) = &Resolve_Path($fullpath);
            my ($num) = $file =~ /sub_\d+.(\d+).xml/;
            if ( $num > $max_filenum ) {
                $max_filenum = $num;
            }
        }

        my $file = "$path/$status/submission_${sid}/sub_${sid}.${max_filenum}.xml";
        if ( -r "$file" ) {
            $dbc->message("Retrieved submission ID $sid ") unless $quiet;

            if ( $output_format eq 'HASH' ) {

                # open the latest submission file
                require XML::Dumper;

                # define directories
                my $dump = new XML::Dumper();

                my $stored_ref = $dump->xml2perl($file);
                return $stored_ref;
            }
            elsif ( $output_format eq 'TXT' ) {
                my $IN;
                open( $IN, "$file" );
                my @lines = <$IN>;
                close $IN;
                return join( "\n", @lines );
            }
            else {
                Message("Error: Invalid output format");
            }
        }
        else {
            Message("Submission file: $file not found for submission ID $sid.") unless $quiet;
            return;
        }
    }
}

##################
sub combine_Tables {
##################
    my $hash = shift;

    my %super_table;
    my %List = %$hash;
    foreach my $key ( keys %List ) {
        my $subTable = $List{$key};
        my $output   = $subTable->Printout(0);
        $super_table{$key} = [$output];
    }
    return \%super_table;
}

##############################
# change Submissions to a different status
##############################
sub change_status {
##############################
    my %args = &filter_input( \@_, -args => 'dbc,sid,status', -mandatory => 'dbc|dbc' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $sid        = $args{-sid};
    my $new_status = $args{-status};
    my $no_email   = $args{-no_email};
    my $user_id    = $dbc->get_local('user_id');

    my ($old_status) = &SDB::DBIO::Table_find( $dbc, "Submission", "Submission_Status", "WHERE Submission_ID=$sid" );
    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    $path .= $sub_dir;
    if ( $old_status eq $new_status ) {
        return 1;
    }

    if ( $new_status eq "Submitted" ) {

        # When a submission is changed to Submitted, then show the Hidden fields so that Admins can edit them if required
        &Modify_Submission_Remove_Field( -dbc => $dbc, -sid => $sid, -flag => 'Omit' );

        # When a submission is changed to Submitted, then show the Greyed out fields so that Admins can edit them if required
        &Modify_Submission_Remove_Field( -dbc => $dbc, -sid => $sid, -flag => 'Grey' );
    }

    # change the status
    my $ok = $dbc->Table_update_array( "Submission", ['Submission_Status'], ["'$new_status'"], "WHERE Submission_ID=$sid" );

    unless ($ok) {
        Message("Failed to change status of submission $sid");
        Call_Stack();
        return 0;
    }

    my $test_path = &create_dir( -path => $path, -subdirectory => "$new_status" );

    # move files to different status
    try_system_command("mv $path/$old_status/submission_${sid} $path/$new_status/submission_$sid");

    if ($no_email) {
        Message("Email notification not sent");
    }
    else {
        &Send_Submission_Email( -dbc => $dbc, -sid => $sid );
    }

    # if the submission is being approved, update approval and emp_id
    if ( $new_status eq 'Approved' ) {
        my $datetime = &date_time();
        $dbc->Table_update_array( "Submission", [ 'Approved_DateTime', 'FKApproved_Employee__ID' ], [ "$datetime", $user_id ], "WHERE Submission_ID=$sid", -autoquote => 1 );
    }

    Message("Changed status of Submission $sid to $new_status");
    return 1;
}
############################
# opens a submission file, find a field and replace it a new value
###########################
sub update_submission_file {
############################
    my %args           = filter_input( \@_, -args => 'file_path,old_value,new_value,dest_file_path', -mandatory => 'file_path,old_value,new_value,dest_file_path' );
    my $file_path      = $args{-file_path};
    my $old_value      = $args{-old_value};
    my $new_value      = $args{-new_value};
    my $dest_file_path = $args{-dest_file_path};

    my $success;

    # open the file and read the contents
    open my $FILE, '<', $file_path or { $success = 0 };
    my @lines = <$FILE>;
    close $FILE;
    open my $FILE1, '>', $dest_file_path or { $success = 0 };
    foreach my $line (@lines) {

        $line =~ s/$old_value/$new_value/g;    #g;

        print $FILE1 $line;
    }
    close $FILE1;
    $success = 1;
    return $success;
}

########################
# Get a link for an attachment file
########################
sub get_attachment_link {
########################
    my %args = &filter_input( \@_, -args => 'dbc,sid,file' );

    my $sid  = $args{-sid};
    my $file = $args{-file};
    my $dbc  = $args{-dbc};

    my ($status) = $dbc->Table_find( 'Submission', 'Submission_Status', "WHERE Submission_ID=$sid" );
    $status ||= 'Submitted';
    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'submission', -dbc => $dbc );
    $path .= $sub_dir;

    my $URL_path = $alDente::SDB_Defaults::URL_temp_dir;
    if   ( $URL_path =~ m|\/(dynamic\/.*)| ) { $URL_path = $1; }
    else                                     { $URL_path = $file; }

    return "/$URL_path/$sub_dir/submission_$sid/$file";
}

sub get_submission_source {
    my %args = &filter_input( \@_, -args => 'dbc,sid', -mandatory => 'dbc,sid' );
    my $dbc  = $args{-dbc};
    my $sid  = $args{-sid};

    my ($source) = &Table_find( $dbc, "Submission", "Submission_Source", "WHERE Submission_ID=$sid" );
    return $source;
}

sub get_submission_field {
    my %args  = &filter_input( \@_, -args => 'dbc,sid,field', -mandatory => 'dbc,sid,field' );
    my $dbc   = $args{-dbc};
    my $sid   = $args{-sid};
    my $field = $args{-field};                                                                   # fully qualified field name, e.g. Library.FK_Project__ID

    my $form;
    my $field_name;
    if ( $field =~ /(\w+)\.(\w+)/ ) {
        $form       = $1;
        $field_name = $2;
    }

    my $submission_ref = &SDB::Submission::Retrieve_Submission( -dbc => $dbc, -sid => $sid );

    my %submission = %{ &SDB::DB_Form::conv_FormNav_to_DBIO_format( -dbc => $dbc, -data => $submission_ref ) };

    my $value;
    foreach my $count ( keys %{ $submission{tables}{$form} } ) {
        if ( defined $submission{tables}{$form}{$count}{$field_name} ) {
            $value = $submission{tables}{$form}{$count}{$field_name};
            last;
        }
    }

    return $value;
}

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

$Id: Submission.pm,v 1.16 2004/11/30 01:44:11 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
