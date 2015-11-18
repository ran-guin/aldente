###################################################################################################################################
# LampLite::Notification.pm
#
# Basic HTML based tools for sending notification messages
#
###################################################################################################################################
package LampLite::Notification;

use strict;

use RGTools::RGIO qw(filter_input);

#
# Simple wrapper to send email messages
#
#
#
#################
sub send_Email {
#################
	my $self = shift;
	my %args = filter_input(\@_);
	my $attachments_ref = $args{-attachments};
    my $attachment_type = $args{-attachment_type} || 'text';
	my $to_address = $args{-to};
	my $from_address = $args{-from};
	my $cc_address = $args{-cc};
	my $bcc_address = $args{-bcc};
	my $subject = $args{-subject};
	my $message = $args{-message} || $args{-body};
	my $header = $args{-header};
	my $content_type = $args{-content_type} || 'text/html';

    ## use MIME::Lite to send attachments
    ## if no attachment, use SENDMAIL directly
    ## An improvement can be done in the future is to support multiple attachment types in one email, e.g. sending out two attachments (one excel and one csv) in the same email
    
        $header
            ||= "Content-Type: multipart/mixed; boundary=\"DMW.Boundary.605592468\"\n\n--DMW.Boundary.605592468\nContent-Type: $content_type; name=\"message.txt\"; charset=US-ASCII\nContent-Disposition: inline; filename=\"message.txt\"\nContent-Transfer-Encoding: 7bit\n\n";                                        
                
        ### body message ###
        my $msg = MIME::Lite->new(
            From    => $from_address,
            To      => $to_address,
            Cc      => $cc_address,
            Bcc     => $bcc_address,
            Subject => $subject,
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
    
    return;
}

1;