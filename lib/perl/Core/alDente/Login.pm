###################################################################################################################################
# alDente::Login.pm
#
# Basic login functionality
#
###################################################################################################################################
package alDente::Login;

use base SDB::Login;

use strict;

use RGTools::RGIO;

## Standard modules ##
use CGI qw(:standard);
use Time::localtime;

my $q = new CGI;

############################
sub send_notification {
############################
    my $self = shift;
    my %args      = &filter_input( \@_ );
    my $target    = $args{-target};
    my $user_name = $args{-user_name};
    my $dbc       = $args{-dbc};
    my $temp_pass = $args{-new_password};
    
    my $subject = 'LIMS Account Information';

    my $target_class = $dbc->config('login_type');  ## eg Employee
    my $password_field = 'Password';
    my $email_field    = 'Email Address';
    
    my $domain = $dbc->config('default_email_domain');
    
    my $full_target = $target;
    if ($target !~/\@/) { $full_target .= '@' . $dbc->config('default_email_domain') }

    my ($encryption) = $dbc->Table_find($target_class,$password_field,"WHERE $email_field like '$target' OR $email_field like '$full_target'");

    if (!$encryption) { 
        $dbc->warning("$target not found in current list of valid email addresses.  Please contact LIMS team for help");
        return 1;
    }
    
    my $class = ref $self;
    
    my $reset_link = $dbc->homelink();
    my $link = Link_To( $reset_link, 'Reset Your Password', "&cgi_application=$class&rm=Log In&User=Guest&cgi_application=${class}_App&rm=Reset Password&Confirmed=1&email=$target&encryption=$encryption" );
    my $body
        = " Hi $user_name,"
        . '<BR><BR>'
        . "You are receiving this email because you have requested to change your LIMS password or needed to know your username."
        . '<BR><BR>'
        . "Username: $user_name"
        . '<BR><BR>'
        . "Alternate Username: $target"
        . '<BR><BR>'
        . "Thank you,"
        . '<BR><BR>' . "LIMS.";

    if ($temp_pass) {
        $body .= '<BR><BR>' . "To change your password please follow the link below and reset your password.  " . '<BR><BR>' . "Link:  " . "$link";
    }

    require alDente::Notification;
    alDente::Notification::Email_Notification(-dbc=>$dbc, -to => $full_target, -subject => $subject, -body => $body, -content_type => 'html' );

    #print $body;
}


return 1;
