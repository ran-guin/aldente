###############################################################################
#
# Notification.pm
#
# This modules drives various notification messages.
#
################################################################################
################################################################################
# $Id: Notification.pm,v 1.20 2004/08/12 00:11:30 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.20 $
#     CVS Date: $Date: 2004/08/12 00:11:30 $
################################################################################
package alDente::Notification;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Notification.pm - This modules drives various notification messages.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This modules drives various notification messages.<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    Email_Notification
    Send_Notice
);
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################
use DBI;
use CGI;

use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;

use RGTools::RGIO;

use alDente::SDB_Defaults;

use SDB::HTML;

##############################
# global_vars                #
##############################
use vars qw($bulk_email_dir %Configs);
##############################
# modular_vars               #
##############################
use vars qw($html_header);
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
#my $_email_directory = "/home/aldente/private/bulk_email";
my $bulk_email_directory = $bulk_email_dir;

############################
sub Email_Notification {
############################
    my %args = &filter_input( \@_, -args => 'to,from,subject,body,attachments,content_type,verbose,attachment_type' );
    my $cc_address  = $args{-cc_address}  || $args{-cc};
    my $bcc_address = $args{-bcc_address} || $args{-bcc};
    my $Subject     = $args{-subject};
    my $body        = $args{-body}        || $args{-body_message} || $args{-message};    ## <construction> - legacy - a few calls still use this syntax
    my $attachments_ref = $args{-attachments};                                           # (hashref) hash of plain text attachments keyed by "filename"
    my $content_type    = $args{-content_type} || "text";                                # (scalar) determine whether or not the text is html or text
    my $verbose         = $args{-verbose} || 0;
    my $attachment_type = $args{-attachment_type} || 'text';
    my $target_list     = $args{-target_list};                                           ## enable special lists (eg. 'lab admin' , 'admin', 'LIMS')
    my $append          = $args{-append};                                                ## append notification to file (sent out periodically using Email_Bulk_Notification
    my $header          = $args{-header} || '';
    my $testing         = $args{-testing};
    my $dbc             = $args{-dbc};                                                   ## alternative to test for production vs beta databases.

    my $default_target = $dbc->config('admin_email');
    if ($dbc->config('default_email_domain') && $default_target !~/\@/) { $default_target .= '@' . $dbc->config('default_email_domain') }
    
    my $to_address     = $args{-to_address} || $args{-to} || $default_target;
    my $from_address   = $args{-from_address} || $args{-from} || $default_target;

    $testing ||= non_Production_DB($dbc);

    if ($testing) {
        my $db_found;
        if ( $dbc && defined $dbc->{dbase} ) { $db_found = $dbc->{dbase} }

        ## Intercept messages that are not generated from PRODUCTION DATABASE interactions ## (previously it was based on the url version, but checking the database is more appropriate) ##
        my $body_message = "<i>Original Recipients: <ul>\n<li><b>TO:</b> $to_address</li>\n<li><b>CC:</b> $cc_address</li>\n<li><b>BCC:</b> $bcc_address</li></ul></i><br>\n";
        $body_message .= "\nThis copy redirected to LIMS since this db ($db_found) != $Configs{PRODUCTION_DATABASE} and/or testing=$args{-testing}.<BR>\n\n";
        $body_message .= join "<br>", @{ Call_Stack( -quiet => 1 ) };
        $body_message .= '<hr>';
        $body_message .= $body;
        $body = $body_message;

        $to_address  = $default_target;
        $cc_address  = '';
        $bcc_address = '';

        $append .= ".test" if ( $append && $append !~ /.+\.test$/ );    ## do not append ".test" again if file name ends with ".test" already
    }
    else {
        if ( $cc_address !~ /\b$default_target\b/ ) {
            $cc_address .= '; ' if $cc_address;
            $cc_address .= $default_target;
        }
    }

    if ( !$to_address ) {
        $to_address = $default_target;
        $body .= "\n\nNOTE: No target email address was specified for this message\n\n";
    }

    unless ( $to_address && $from_address ) {
        Message("No Sender ($from_address) or Target address ($to_address) supplied (aborting)");
        return 0;
    }

    $to_address   = &_format_list($to_address);
    $from_address = &_format_list($from_address);
    $cc_address   = &_format_list($cc_address);
    $bcc_address  = &_format_list($bcc_address);

    if ( $content_type eq 'html' ) {
        $content_type = "text/html";
    }
    elsif ( $content_type eq 'text' ) {
        $content_type = "text/plain";
    }

    # remove beginning and trailing endlines and whitespace from $body
    my $message = &RGTools::RGIO::chomp_edge_whitespace($body);

    if ( $content_type =~ /html/ ) { $message = "<Table><TR><TD>\n$message\n</TD></TR></Table>\n" }    ## required for some reason to make link show up properly ##

    if ($attachments_ref) {
        ### <CONSTRUCTION> - can this header be used as a standard to be more flexible ? ###
        $header
            = "Content-Type: multipart/mixed; boundary=\"DMW.Boundary.605592468\"\n\n--DMW.Boundary.605592468\nContent-Type: $content_type; name=\"message.txt\"; charset=US-ASCII\nContent-Disposition: inline; filename=\"message.txt\"\nContent-Transfer-Encoding: 7bit\n\n";
    }
    else {
        unless ( $content_type =~ /^Content-Type/i ) {
            $content_type = "Content-Type: $content_type\n\n";
        }
        $header ||= "$content_type\n";
    }

    if ( $header =~ /html/i ) {
        $header .= "$html_header\n";
    }

    if ($dbc) {
        $dbc->message(" Sending message to $to_address.");
    }
    else {
        Message(" Sending message to $to_address.");
    }
    if ($append) {    ## when appending to a file instead of using sendmail
        open( SENDMAIL, ">>$bulk_email_directory/$append" ) or die "Can't append to $bulk_email_directory/$append: $!\n";

        print SENDMAIL "<B>Subject:</B>\t$Subject<br />\n";    ## show separate subject lines in file when appending

        print SENDMAIL "<B>From:</B>\t$from_address<br />\n";
        print SENDMAIL "<B>To:</B>\t$to_address<br />\n";
        print SENDMAIL "<B>CC:</B>\t$cc_address<br />\n" if $cc_address;
        print SENDMAIL "<B>Sent:</B>\t" . date_time() . "<br />\n\n";    ## put timestamp in appended file to show when generated

        print SENDMAIL "$message\n\n";
        if ( $content_type eq 'html' ) {
            print SENDMAIL "<hr>";
        }
        close(SENDMAIL) or warn "sendmail couldn't close";
        try_system_command("chmod 777 $bulk_email_directory/$append");
    }
    else {                                                               ## normally just send message directly using sendmail
        ## use MIME::Lite to send attachments
        ## if no attachment, use SENDMAIL directly
        ## An improvement can be done in the future is to support multiple attachment types in one email, e.g. sending out two attachments (one excel and one csv) in the same email
        if ($attachments_ref) {                                          # use MIME::Lite to send attachments
            eval "require MIME::Lite";
            ### body message ###
            my $msg = MIME::Lite->new(
                From    => $from_address,
                To      => $to_address,
                Cc      => $cc_address,
                Bcc     => $bcc_address,
                Subject => $Subject,
                Type    => 'text/html',
                Data    => $message
            );

            ### attachments ###
            foreach my $attachment ( keys %$attachments_ref ) {
                $msg->attach(
                    Type     => $attachment_type,
                    Path     => $attachment,
                    Filename => $attachments_ref->{$attachment}
                );
            }
            $msg->send();
        }
        else {    # if no attachment, use SENDMAIL directly
            open( SENDMAIL, "|/usr/lib/sendmail -t" ) or die "Can't sendmail: $!\n";

            print SENDMAIL<<EOF;
From: $from_address
To: $to_address
Cc: $cc_address
Bcc: $bcc_address
Subject: $Subject
EOF

            print SENDMAIL "$header\n\n";    ## only include header when sending (?)

            print SENDMAIL "$message\n\n";
            if ( $content_type eq 'html' ) {
                print SENDMAIL "<hr>";
            }
            close(SENDMAIL) or warn "sendmail couldn't close";
        }
    }

    return 1;
}

###########################
#
# Allows regular use of Email_Notification to write to a file instead of sending an email.
# This file can be sent as a notification in bulk on a regular basis.  (Initiated by a cron job for instance)
#
# (This is useful when large numbers of emails would otherwise be generated in a small amount of time)
#
##################################
sub Email_Bulk_Notification {
##################################
    my %args         = &filter_input( \@_, -args => 'file,subject,to,from' );
    my $file         = $args{-file};                                            ## name of file to email out
    my $subject      = $args{-subject};
    my $to_address   = $args{-to};                                              ## target_address (in cases where standard list not used)
    my $from_address = $args{-from};                                            ## sender address to include
    my $cc_address   = $args{-cc};                                              ## sender address to include
    my $bcc_address  = $args{-bcc};                                             ## sender address to include
    my $header       = $args{-header};
    my $dbc          = $args{-dbc};
    my $testing      = $args{-testing} || '';

    open( SENDMAIL, "| /usr/lib/sendmail -t" )      or die "Can't sendmail: $!\n";
    open( FILE,     "$bulk_email_directory/$file" ) or die "Cannot read $bulk_email_directory/$file";

    my $message = $header;
    while (<FILE>) {
        my $line = $_;

        # $line =~ s/\n/<BR>/g;			causes problems with breaks in tables and uneccessary
        $message .= $line;
    }

    if ( $testing || non_Production_DB($dbc) ) {
        $to_address = 'aldente';
        $subject .= "--Intercepted message for $to_address.  (redirected to $to_address) (testing=$testing)";
    }

    print SENDMAIL<<EOF;
From: $from_address
To: $to_address
Cc: $cc_address
Bcc: $bcc_address
Subject: $subject
$message
EOF

    Message("Sent message to $to_address..");
}

#
# Return flag if indicated database is the production database
#
#
##########################
sub non_Production_DB {
##########################
    my $dbc = shift;

    my $this_db;
    if ($dbc) {
        $this_db = $dbc->{dbase};
    }
    else {
        $this_db = $Configs{DATABASE};
    }
    my $testing = ( $this_db ne $Configs{PRODUCTION_DATABASE} );

    return $testing;
}

###########################
#
# Send Notice to user(s), tracking notices sent within the database.
#
# Checks for last incidence of similar notice and repeats depending upon specified frequency.
#
#
####################
sub Send_Notice {
####################

    my $dbc      = shift;
    my $user_ids = shift;
    my $subject  = shift;
    my $text     = shift;
    my $send     = shift;    #### how long ago to repeat message (eg. '-14d')
    my $now      = shift;    #### flag to indicate message should be sent now.

    my $addresses = $user_ids;
    unless ( $addresses =~ /\@/ ) {
        $addresses = join ',', $Connection->Table_find( 'Employee', 'Email_Address', "where Employee_ID in ($user_ids)" );
    }

    ( my $today ) = split ' ', &date_time();

    if ($send) {
        my ($repeat_date) = split ' ', &date_time($send);
        ( my $sent ) = $Connection->Table_find( 'Notice', 'Notice_Date', "where Notice_Text='$text' and Notice_Date>'$repeat_date' Order by Notice_Date desc" );

        if ( $sent =~ /(\d\d\d\d-\d\d-\d\d)/ ) {
            $sent = 1;
            Message( "Message already sent:", "$text", 'text' );
            return '';
        }
        elsif ($now) { Message( "Send message to $addresses for:", "$text", 'text' ); }
    }

    $Connection->Table_append_array( 'Notice', [ 'Target_List', 'Notice_Date', 'Notice_Subject', 'Notice_Text' ], [ $addresses, $today, $subject, $text ], -autoquote => 1 );

    unless ($now) { return $text; }    ### don't send now ####

    my $from = 'Auto Notifier<sequence@bcgsc.ca>';

    my $full_addresses = map {
        unless (/\@/) { $_ .= "\@bcgsc.ca"; }
    } split ',', $addresses;

    #$full_addresses = 'rguin@bcgsc.bc.ca,achan@bcgsc.bc.ca'; ## temporarily turn off from users ### .. revert to send to full_addresses...
    &Email_Notification( $full_addresses, $from, $subject, $text, -dbc => $dbc );

    return $text;
}

##############################
# private_methods            #
##############################

###################
#
#
###################
sub _format_list {
###################
    my $list = shift;

    my $email_domain = 'bcgsc.ca';

    my $formatted = join ', ', map {
        my $a = $_;
        unless ( $a =~ /\@/ ) {
            if ( $a =~ /([\s\w]+)?\s*<(\w+)>/ ) {
                $a = "$1<$2\@$email_domain>";
            }
            elsif ( $a =~ /\w+/ ) {
                $a = "$a\@$email_domain";
            }
        }
        chomp_edge_whitespace($a);
    } split( /[,;]/, $list );

    return $formatted;
}
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

2003-09-25

=head1 REVISION <UPLINK>

$Id: Notification.pm,v 1.20 2004/08/12 00:11:30 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
