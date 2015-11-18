# LampLite::Login.pm
#
# Basic login functionality
#
###################################################################################################################################
package LampLite::Login;

use base LampLite::DB_Object;
use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::Login.pm - Model for basic Login functionality

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

use CGI qw(:standard);
use Time::localtime;

## Local modules ##
use LampLite::Session;
use LampLite::Bootstrap;
##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO qw(filter_input try_system_command Call_Stack Link_To);

##############################
# global_vars                #
##############################
my $BS = new Bootstrap();
#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;

   if ($dbc) { $self->{dbc} = $dbc }
    $self->init();

    return $self;
}

## Enable Scope specific initialization ##
############
sub init {
############

    return;
}

##################################
sub reload_input_parameters {
##################################
    my %args  = filter_input( \@_ );
    my $input = $args{-input};
    my $reset = $args{ -reset };
    my $clear = $args{-clear};

    my $q = new CGI;

    my $reload;

    my %Input;
    if ($input) {
        $reload = $input;
    }
    else {
        $reload = reload_Input( -clear => $clear );
    }

    my $page;
    foreach my $p ( keys %$reload ) {
        my $value = $reload->{$p};
        if ( ref $value eq 'ARRAY' ) {
            my @values = @$value;
            foreach my $i ( 0 .. $#values ) {
                $page .= $q->hidden( -name => $p, -value => qq($values[$i]), -force => 1 ) . "\n";
            }
        }
        else {
            $page .= $q->hidden( -name => $p, -value => $value, -force => 1 ) . "\n";
        }
    }

    return $page;
}

#####################
sub reload_Input {
#####################
    my %args    = filter_input( \@_ );
    my $testing = $args{-testing};
    my $clear   = $args{-clear};
    my $q       = new CGI;
    my %Input;
    foreach my $name ( $q->param() ) {
        my @value = $q->param($name);
        $Input{$name} = [];
        foreach my $val (@value) {
            if ( $clear && grep /^$name$/,      @$clear ) {next}
            if ( $clear && grep /^$name=$val$/, @$clear ) {next}
            push @{ $Input{$name} }, $val;
        }

    }

    return \%Input;
}

#
# Simple generic accessor to retrieve password from a password file.
#
# The password file itself should NOT be committed to SVN and should have read only permissions accessible by whoever needs to run this code
#
# Can be adjusted to handle different file formats, and include file encryption, but currently the login file format should be:
#
# $host:$user:$password  (if desired, this may be adapted easily to accept a format input (eg -format => "^HOST:USER:PASSWORD" ))
#
# The host itself may also be replaced by a configuration key
#  eg:
# <PRODUCTION_HOST>:$user:$password
#
#
# Return: password
###################
sub get_password {
###################
    my %args   = filter_input( \@_, -args => 'host,user' );
    my $host   = $args{-host};
    my $user   = $args{-user};
    my $file   = $args{-file};
    my $method = $args{-method} || 'read';                    ## grep / read / yml files ... may expand to include yml / storable / xml (?) ...
    if ( !$file ) {return}                                    ## okay when passwords not required

    if ( !( $host && $user && $file ) ) { print "Require File ($file), Host ($host) AND User ($user)"; return; }

    my @found;
    my $password;                                             ##
    if ( $method =~ /grep/ ) {
        ## use grep to find password from login file ##
        my $grep = "grep '^$host:$user:' $file";
        @found = split "\n", `$grep`;
        if ( !@found ) {return}
    }
    elsif ( $method =~ /read/ ) {
        ## open file and read to retrieve password ##
        open my $FILE, '<', $file || return;
        while (<$FILE>) {
            if ( $_ =~ /^$host:$user:(\S+)/ ) {
                push @found, $_;
            }
        }
        close $FILE;
    }

    if ( @found > 1 ) { print "warning: multiple passwords defined for $host : $user.\n" }
    if ( $found[0] =~ /^$host\:$user\:(\S+)/ ) { $password = $1 }

    ## else returns null (okay)
    return $password;
}

#
#  Save the new password.
#
####################
sub save_password {
####################
    my $self            = shift;
    my %args            = filter_input( \@_ );
    my $dbc             = $args{-dbc} || $self->param('dbc');
    my $current_pwd     = $args{-current_pwd};
    my $new_pwd         = $args{-new_pwd};
    my $confirm_new_pwd = $args{-confirm_new_pwd};
    my $force           = $args{-force};
    my $encrypted          = $args{-encrypted};
    my $user_id            = $args{-user_id} || $dbc->get_local('user_id');
    my $user               = $args{-user} || $dbc->get_local('user');
    my $validated = $args{-validated};
   
    #First make sure we are not changing password for the Guest user...
    
    my $login_table = $dbc->config('login_type');
    my $userid_field = $login_table . '_ID';

    my $condition = "WHERE $userid_field = $user_id";
    if ($encrypted) { $condition .= " AND Password = '$encrypted'" }
    else { $condition .= " AND (Password = Password('$current_pwd') OR Password = Old_Password('$current_pwd'))" }
    
    my $validate = $dbc->get_db_value(-sql=>"SELECT $userid_field FROM $login_table $condition");

    if ( !$validate ) { 
        $dbc->error("Incorrect Old Password supplied"); 
        return; 
    }

   # if ( $user eq 'Guest' && !$force ) {
  #      $dbc->warning("Password can NOT be changed for the Guest user.");
  #      return;
   #}

    #Now make sure the the new password is valid.....
    if ( $new_pwd ne $confirm_new_pwd ) {

        #new password and re-type new password not match. Notify the user and show the change password form again.
        $dbc->warning("The new passwords do not match each other. Password NOT changed.");
        return;
    }
    elsif ( $new_pwd =~ /^[^a-zA-Z]/ ) {

        #new password must start with a letter. Notify the user and show the change password form again if this is not the case..
        $dbc->warning("The password MUST start with a letter. Password NOT changed.");
        return;
    }
    elsif ( $new_pwd =~ /\s+/ ) {
        $dbc->warning("The password MUST contain NO spaces. Password NOT changed.");
        return;
    }

    if (!$validated) {
        ## validate password formate ##
        if ( !( $self->validate_password( -pwd => $new_pwd, -dbc => $dbc ) ) ) {return}
    }

    # password okay, so allows update of the new password.

    my $ok = $dbc->Table_update( $login_table, 'Password', "PASSWORD('$new_pwd')", "where $userid_field=$user_id", -override => 1 );
    if ($ok) {
        $dbc->message("Password changed successfully.");
        
        my $login_link = $dbc->homelink(-clear=>1);
        
        print Link_To($dbc->homelink(-clear=>1)," Log in again ");

        &main::leave($dbc);
    }
    else {
        $dbc->error("Error changing password.");
        return;
    }
}

#
# Wrapper to add DB User
#
# * Adds user to mysql.user if not already applied
# * Adds user to  mysql.db if not already applied
# * Optionally addes host:user:password to mysql.login file
#
##################
sub add_DB_user {
##################
    my %args              = filter_input( \@_ );
    my $dbc               = $args{-dbc};
    my $user              = $args{-db_user};                   ## name of db_user to add
    my $host              = $args{-host} || $dbc->{host};      ## host server to add db_user to
    my $dbase             = $args{-dbase} || $dbc->{dbase};    ## database to provide access to
    my $pass              = $args{-password};
    my $append_login_file = $args{-append_login_file};         ## login file (should have restricted read access )
    my $privileges        = $args{-privileges} || [];          ## temporarily ... array of standard privileges: (select, insert, update, delete..);
    my $debug             = $args{-debug};

    my $user_added = $dbc->get_db_value(-sql=>"SELECT COUNT(*) FROM mysql.user WHERE User = '$user'" );
    if ( !$user_added ) {
        if ($append_login_file) {
            my ($included) = split "\n", try_system_command("grep '$host:$user:' $append_login_file");

            if ( $included =~ /^$host:$user:(\S+)/ ) {
                $pass = $1;
                if ($debug) { print "Using existing password\n"; }
            }
            else {
                try_system_command("echo '$host:$user:$pass' >> $append_login_file");
                if ($debug) { print "appended $host:$user:$pass to login file\n" }
            }
        }
        my $ok = $dbc->execute_command("INSERT INTO mysql.user (Host, User, Password) values ('%', '$user', Password('$pass'))");
        if ($debug) { print "INSERT INTO mysql.user ... %, $user, $pass [$ok]\n" }
    }

    my $db_added = $dbc->get_db_value(-sql=>"SELET COUNT(*) FROM mysql.db WHERE Db = '$dbase' AND User = '$user'" );
    if ( !$db_added ) {
        my ( $s, $i, $u, $d ) = @$privileges;

        my $ok = $dbc->execute_command("INSERT INTO mysql.db (Host, Db, User, Select_priv, Insert_priv, Update_priv, Delete_priv) values ('%', '$dbase', '$user', '$s', '$i', '$u', '$d')");
        if ($debug) { print "INSERT INTO mysql.db ... %, $dbase, $user, $s, $i, $u, $d [$ok]\n" }
    }
    elsif ($debug) { print "Added $db_added. count(*) FROM mysql.db WHERE Db = '$dbase' AND User = '$user'\n" }

    return;
}

############################################
sub log_in {
############################################
    # Log in function
############################################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $user          = $args{-user};
    my $emp_ref       = $args{-employess};
    my $password      = $args{-pwd};
    my $printer_group = $args{-printer_group};

    my $login_table = $args{-login_table} || $dbc->{login_table} || 'User';
    
    ### customizable ##
    my $userid_field   = $args{-userid_field}   || $login_table . '_ID';      # eg 'User_ID'
    my $username_field = $args{-username_field} || $login_table . '_Name';    # eg 'User_Name'
    my $email_field    = $args{-email_field}    || 'Email_Address';           #


    my $password_validated = 1;
    if ($login_table eq 'Contact') { 
        $email_field = 'Contact_Email';
        $password_validated = 0; 
    }
    ## customized...##

    ## Define Login attributes for login table ##
    $self->{username_field} = $username_field;
    $self->{userid_field}   = $userid_field;
    $self->{login_table}    = $login_table;
    $self->{email_field}    = $email_field;
    
    my ($db_user, $user_id, $user, $access) = LampLite::DB_Access::get_DB_user(-dbc=>$dbc, -user=>$user); 
    unless ( $user_id =~ /[1-9]/ ) { return ( $user_id, $user, 'wrong user' ) }

    if ($password_validated) {

        my $user_name = $dbc->get_db_value(-sql=>"SELECT  $self->{username_field} FROM $self->{login_table} WHERE $self->{userid_field} = $user_id");

        my $result = $self->check_password( -user => $user_name, -pwd => $password, -dbc => $dbc );
        
        if ($result) {
            my $validate = $self->validate_password( -user => $user_name, -pwd => $password, -email_field=>$email_field, -dbc => $dbc );
            if ($validate) {
                $self->{logged_in} = $user_id;

                my $session = $dbc->{session};

                #            my $session = LampLite::Session->new( -user => $user_name, -user_id => $user_id, -host => $self->{host}, -dbase => $self->{dbase}, -dbc=>$dbc);
                ## reset session object parameters ##
                $session->param( 'dbase',   $dbc->{dbase} );
                $session->param( 'host',    $dbc->{host} );
                $session->param( 'user',    $user_name );
                $session->param( 'user_id', $user_id );
                $session->param('access', $access);
                if ( $dbc->is_Connected ) { $session->param( 'dbc', 'connected' ) }

                $dbc->{session} = $session;

                return ( $user_id, $user, 'logged in' );
            }
            else { return ( $user_id, $user, 'change password' ) }
        }
        else { return ( $user_id, $user, 'wrong password' ) }
    }
    else { return ($user_id, $user, 'public access') }
}

############################################
sub get_user_id {
############################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $user    = $args{-user};
    my $user_id = $args{-userid};

    my $condition = "$self->{login_table}_Status = 'Active'";

    if ($user) { $condition .= " AND $self->{username_field} = '$user' " }
    elsif ($user_id) { $condition = " AND $self->{userid_field} = '$user_id' " }
    else             { return $dbc->error('must supply user or userid') }

    ##### Verifying Employee Name

    my $hash = $dbc->hash(-table=>$self->{login_table}, -fields=>[ $self->{userid_field}, $self->{username_field} ], -condition=>"WHERE $condition" );
    my $user = $hash->{$self->{userid_field}};
    my $user_id = $hash->{$self->{username_field}};

    unless ( $user_id =~ /[1-9]/ && $self->{email_field} ) {
        ## if no user found using username, use Email_Address as optional username ##
        $condition =~ s/\b$self->{username_field}\b/$self->{email_field}/;
        
        my $hash = $dbc->hash( -table=>$self->{login_table}, -fields=>[ $self->{userid_field}, $self->{username_field} ], -condition=>"WHERE $condition" );
        $user = $hash->{$self->{userid_field}};
        $user_id = $hash->{$self->{username_field}};
    }
    return ( $user_id, $user );
}

############################################
sub check_password {
############################################
    # Log in function
############################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $user     = $args{-user};
    my $password = $args{-pwd};

    $dbc->connect_if_necessary();

    ## removed case INsensitivity below .... should be case sensitive ...
    
    my $sql = "SELECT  $self->{userid_field} FROM $self->{login_table} WHERE $self->{username_field} in ('$user') and PASSWORD('$password') = Password";

    my $result = $dbc->get_db_value(-sql=>$sql );

    if ( !$result ) {

        #my $status = $dbc->execute_command(-command => 'status');
        my $stat_check = "mysql -e status -u viewer -pviewer -h $dbc->{host} $dbc->{dbase}";
        my $status     = try_system_command($stat_check);

        my $version;
        if ( $status =~ /Server version:\s+(\d+\.\d+)/ ) {
            $version = $1;
        }

        if ( $version > 4.1 ) {
            ## try old password encryption ##
            my $old_value = $dbc->get_db_value(-sql=>"SELECT $self->{userid_field} FROM $self->{login_table} WHERE $self->{username_field} in ('$user') and OLD_PASSWORD(lcase('$password')) = Password" );

            if ($old_value) {
                my $validate = $self->validate_password( -user => $user, -pwd => $password, -dbc => $dbc );
                if ($validate) {
                    $dbc->message("Password re-encrypted for newer version of mySQL.\nNote: Password is now case sensitive\n\nContact LIMS admin if you need to reset your password");
                    return $self->save_password( -new_pwd => $password, -confirm_new_pwd => $password, -dbc => $dbc, -force => 1 );
                }
                else { return 1 }    # let log_in check to change password
            }
        }
    }

    if ( !$result ) {
        ## check if password is super_user password ##
        my $super_user = $dbc->get_db_value(-sql=>"SELECT $self->{userid_field} FROM $self->{login_table} WHERE $self->{username_field} in ('Admin') and PASSWORD('$password') = Password" );
        if ($super_user) {
            $result = $super_user;
        }
    }

    return $result;
}

############################################
sub validate_password {
############################################
    # Log in function
############################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc};
    my $user     = $args{-user};
    my $password = $args{-pwd};

    my $login_table = $args{-login_table} || $self->{login_table} || $dbc->config('login_type') || 'User';
    my $email_field = $args{-email_field} || $dbc->config('user_email_field') || 'Email';
    my $username_field = $args{-username_field} || $dbc->config('username_field') || $login_table . '_Name';
  
    my @forbidden_pwds = ( 'password', 'pwd', $user );

    ### Customizable Password requirements ###

    if ( !$password ) {return}
    if ( $user eq 'Guest' ) { return 1 }
    if ( length($password) < 6 ) {return}

    ### End of Customizable Password requirements ###
    my $login_table = $args{-login_table} || $dbc->{login_table} || 'User';

    my $email = $dbc->get_db_value(-sql=>"SELECT $email_field FROM $login_table WHERE $username_field = '$user'" );
    push @forbidden_pwds, $user;
    push @forbidden_pwds, $email;

    if ( grep /^$password$/, @forbidden_pwds ) {
        $dbc->warning( $self->validate_password_message() );
        return;
    }
    return 1;
}

############################################
sub validate_password_message {
############################################
    # Log in function
############################################
    my $self    = shift;
    my $message = "Your password cannot be your username,email or default password. \n
				   It also has to be longer than 5 characters. \n
				   Please change your password below and confirm.\n";    ## Customizable message ##
    return $message;
}

############################
sub set_temp_password {
############################
    my $self = shift;
    
    my %args          = &filter_input( \@_ );
    my $dbc           = $args{-dbc} || $self->{dbcv};
    my $user_name     = $args{-user_name};
    my $range         = 100000;
    my $random_number = int( rand($range) );
    my $new_pass      = 'C' . $random_number . 'kP';
    
    $dbc->Table_update_array( 'Employee', ['Password'], ["password('$new_pass')"], "WHERE Employee_Name='$user_name'" );
    
    return $new_pass;
}

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
    my $email_field    = 'Email_Address';
    
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

    my $from = $dbc->config('admin_email') || 'aldente';

    use LampLite::Notification;
    my $sent = LampLite::Notification->send_Email(-to => $full_target, -from=>$from, -subject => $subject, -body => $body, -content_type => 'html' );
    
    return $sent;
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
