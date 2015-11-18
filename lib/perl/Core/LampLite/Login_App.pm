###################################################################################################################################
# LampLite::Login_App.pm
#
# Basic run modes related to logging in (using CGI_Application MVC Framework)
#
###################################################################################################################################
package LampLite::Login_App;

use base RGTools::Base_App;

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::Login_App.pm - Controller for basic Login functionality

=head1 SYNOPSIS <UPLINK>


=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

use Time::localtime;

## Local modules ##
use LampLite::Login_Views;
use LampLite::Bootstrap;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;

##############################
# global_vars                #
##############################

my $BS = new Bootstrap();    ## Login errors do not need to be session logged, so can be called directly ##
############
sub setup {
############
    my $self = shift;

    $self->start_mode('Log In');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
            'Log In' => 'login',
            'Forgot Password' => 'reset_password',
            'Default Log In' => 'default_login',
            'Save New Password' => 'save_password',
            'Change Password'         => 'prompt_change_password',   
            'Reset Password' => 'forgot_Password',        
            'Email Username' => 'forgot_Password',        
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

#############
sub login { 
#############
    my $self = shift;
    my %args = filter_input(\@_);

    my $q          = $self->query();    
    my $user       = $q->param('User');
    my $password   = $q->param('Pwd') || 'pwd';  ## guest password
    
    my $dbc = $self->param('dbc');

    my $login = $args{-Login} || $self->Model();
    my $view = $args{-Login_Views} || $self->View();
    
    ### Log in if necessary ##
    my ($user_id, $user_name, $result ) = $login->log_in( -user => $user, -dbc => $dbc, -pwd => $password);

    my $page;
    if ( $result eq 'logged in' ) {
#         $page .= $dbc->message("$user_name [$user_id] logged in successfully ...");
    }
    elsif ( $result eq 'wrong password' ) {
        $page .= $BS->error('Incorrect password - please try again');
        $self->{failed}=1;        $page .= $view->display_Login_page( -dbc => $dbc );
    }
    elsif ( $result eq 'wrong user' ) {
        $self->{failed}=1;
        $page .= $view->unidentified_user_page( -dbc => $dbc, -user => $user );
        $page .= $view->display_Login_page( -dbc => $dbc );
    }
    elsif ( $result eq 'change password' ) {
        $page .= $BS->message( $login->validate_password_message() );
        $page .= $view->change_password_box( -dbc => $dbc, -user => $user );
    }
    elsif ( $result eq 'No printer group' ) {
        $page .= $BS->warning('No printer group selected!');

        $self->{failed}=1;
        $page .= $view->display_Login_page( -dbc => $dbc );
    }
    else {
        $page .= $BS->warning("Unidentified login result ($result)");
        $page .= $view->display_Login_page( -dbc => $dbc );
    }
    
    if ($result ne 'logged in') {
        ## exit if not logged in successfully ##
        print $page;
        LampLite::Login_Views->leave($dbc);
    }

    
    return $page;
}


#############################
sub prompt_change_password {
#############################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');
    
    return $self->View->change_password_box( -dbc => $dbc );
}

##############################
sub save_password {
##############################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $self->param('dbc') || $args{-dbc};
    my $q          = $self->query();
    
    my $current = $q->param('Current_Pwd');
    my $pass    = $q->param('New_Pwd'); 
    my $confirm = $q->param('Confirm_New_Pwd');
    my $encrypted = $q->param('Encrypted');
    my $email    = $q->param('email');
     
    my $q = $self->query;
    my $valid = $self->Model->validate_password( -dbc => $dbc, -pwd => $pass );

    my $user_id;
    if ($email) {
        my $login_table = $dbc->config('login_type');
        my $userid_field = $login_table . '_ID';
        my $email_field = $dbc->config('email_address_field') || 'Email_Address';
 
        my ($short_email, $long_email) = $dbc->email_options($email);
        
        ($user_id) = $dbc->Table_find($login_table, $userid_field, "WHERE $email_field IN ('$short_email', '$long_email')"); 
    }

    if ( !$valid ) {
        Message $self ->Model->validate_password_message();
        return $self->View->change_password_box( -dbc => $dbc, -email=>$email, -encryption=>$encrypted);
    }

    my $ok = $self->Model->save_password(
        -dbc             => $dbc,
        -user_id         => $user_id,
        -current_pwd     => $current,
        -new_pwd         => $pass,
        -confirm_new_pwd => $confirm,
        -encrypted => $encrypted,
        -validated => 1,
    );

    if ($ok) {
        return;
    }
    else {
        return $self->View->change_password_box( -dbc => $dbc, -email=>$email);
    }
    return;
}

####################
sub reset_password {
####################
    my $self = shift;
    my $dbc = $self->param('dbc');
    print $BS->message("Reset passsword message");
    return;
}

######################
sub forgot_Password {
######################
    my $self = shift;
    
    my $q = $self->query();
    my $dbc = $self->{dbc};

    my $email         = $q->param('email');
    my $confirmed     = $q->param('Confirmed');
    my $new_password = $q->param('New_Pwd');
    my $sec_password = $q->param('Confirm_Pwd');
    my $encryption   = $q->param('encryption');
    
    my $rm = $q->param('rm');
   
    my ($short_email, $long_email) = $dbc->email_options($email);
    
    my $page;
    if ($confirmed) {
        $page .= page_heading("Resetting Password");

        my $passed       = $dbc->Table_find( 'Employee', "Employee_ID", "WHERE Password = '$encryption' and Email_Address IN ('$short_email','$long_email')" );

        if ( !$passed ) {
            if ($email && $encryption) {
                $dbc->warning("Password has been changed since password was last reset.  You may need to click on 'Forgot Password' link again to re-enable access.");
            }
            else {
                $dbc->warning("Incorrect Password");
            }
            $page .= $self->View->change_password_box(   );
        }
        elsif ( $new_password && $new_password eq $sec_password ) {
            $dbc->Table_update_array( 'Employee', ['Password'], ["password('$new_password')"], "WHERE Email_Address IN ('$short_email', '$long_email')" );
            $page .=  Link_To( 'barcode.pl', 'Continue', "" );
        }
        elsif ($new_password) {
            $page .= $dbc->warning("Warning: The two passwords did not match", -return_html=>1);
            $page .= $self->View->change_password_box( -encryption => $encryption, -email=>$long_email );
        }
        else {
            $page .= $self->View->change_password_box( -encryption => $encryption, -email=>$long_email );
        }

    }
    elsif ($email) {
        my %user_info = $dbc->Table_retrieve( 'Employee', [ 'Employee_Name', 'Email_Address', 'Employee_Status' ], "WHERE Email_Address IN ('$short_email','$long_email')" );
        my $count = int( @{ $user_info{Employee_Name} } ) if $user_info{Employee_Name};

        if ( $count > 1 ) { $dbc->warning("Warning: There is more than one account assocated with this email please contact LIMS.") }
        elsif ($count) {
            my $status = $user_info{Employee_Status}[0];
            if ( $status eq 'Active' ) {

                if ( $rm eq 'Email Username' ) {
                    $self->Model->send_notification( -target => $user_info{Email_Address}[0], -user_name => $user_info{Employee_Name}[0], -dbc => $dbc );
                    $dbc->message("Your info has been sent to your email account.");
                }
                else {
                    my $temp_password = $self->Model->set_temp_password( -user_name => $user_info{Employee_Name}[0], -dbc => $dbc );
                    $self->Model->send_notification( -target => $user_info{Email_Address}[0], -user_name => $user_info{Employee_Name}[0], -dbc => $dbc, -new_password => $temp_password );
                    $dbc->message("A link has been sent to your email account.  Please follow the link to reset your password.");
                }
            }
            else { $dbc->warning("Warning: Your account status is $status. Please contact LIMS to activate this account.") }
        }
        else {
            $dbc->error("Warning: There is no account assocated with this email please apply for a new account.");
            $page .= $self->View->reset_unknown_password( -dbc => $dbc );

        }
        return $self->View->relogin($dbc);
    }
    else {
        $page .= $self->View->reset_unknown_password( -dbc => $dbc );
    }  
      
    return $page;
        
}

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

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

1;
