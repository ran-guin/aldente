###################################################################################################################################
# LampLite::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package LampLite::Login_Views;

use base LampLite::Views;

use strict;

## Standard modules ##

use Time::localtime;

## Local modules ##

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;

use LampLite::CGI;
use LampLite::Form;
use LampLite::HTML;

my $q = new LampLite::CGI;
my $BS = new Bootstrap();

#####################
sub new {
#####################
    my $this   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $Login  = $args{-Login};

    my $login_table = $args{-login_table};
    
    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($dbc) { $self->{dbc} = $dbc }
    if ($Login) { $self->{Login} = $Login }

   
    return $self;
}

###############
sub relogin {
###############
    my $self = shift;
    my %args         = filter_input( \@_, -args => 'dbc,reload' );
    my $dbc          = $args{-dbc};
    my $reload       = $args{-reload};                           ## optionally pass input parameters (eg from previous expired session ?)
    my $default_user = $args{-user};                             ## enable call with default user specified ... still need to enter password of user or admin to get in...

    if (!ref $self) { $self = $self->new( -dbc => $dbc ) }

    my $page = $self->display_Login_page( -dbc => $dbc, -reload => $reload, -default_user => $default_user );
    
    print $page;

    $self->leave();
    exit;
}

#
# Custom header definition
#
# 
########################
sub login_page_header {
########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $row  = $args{-row};
    my $right = $args{-right};
    my $left  = $args{-left};
    
    my @row;
    if (ref $row eq 'ARRAY') { @row = @$row }
    elsif (! ref $row) { @row = [ $row ] }

    my $table = new HTML_Table(-align=>'center', -width=>'100%');
    $table->Set_Line_Colour('#fff');
    $table->Set_Class('small');
    $table->Set_Row(\@row);
    
    my $main = $table->Printout(0);   
    my $header = { 
                   '-main' => [$main] , 
                   '-right' => [ $right ] , 
                   '-left'  => [$left],             
    };
    
    return $BS->header(-centre=>$main, -left=>$left, -right=>$right, -style=>"margin:0px; background-color:white; border-color:white;", -flex=>['',1,''], -position=>'top');
#    return $header;

}
#
# Generates the Department / Project display / selector on the main header
#
# Return: hash (for displaying as parameter for $BS->menu() )
######################
sub _dept_header {
######################
    my $self  = shift;
    my $scope = shift;
    my $dbc   = $self->{dbc};

    my $prompt = $scope;
    my ( $depts, $extra_link_parameters );

    if ( $scope =~ /department/i ) {
        $prompt = 'Dept';
        $depts  = $dbc->get_local('departments');
        $depts ||= ['Public'];
    }
    elsif ( $scope =~ /project/i ) {
        $depts = $dbc->get_local('projects');
        my $custom = $dbc->config('custom');
        $extra_link_parameters = "&cgi_application=${custom}::App&rm=Project";
    }

    my $Current_Department = $dbc->config( "Target_" . $scope ) || '';
    my $current_dept = Show_Tool_Tip( "$prompt: <B>$Current_Department</B> " . $BS->icon('caret-down'), "Select $prompt", -placement => 'bottom' );

    my @depts;
    my $local_homelink = $dbc->homelink( -clear => [ 'Target_' . $scope ] );
    if ( $depts && $depts->[0] ) {
        foreach my $dept ( sort @$depts ) {
            my $link = Link_To( $local_homelink, $dept, "$extra_link_parameters&Target_$scope=$dept" );
            push @depts, $link;
        }
    }
    else { @depts = ( '-- No Options Available --', "-- Contact Admin to Enable Access to ${prompt}s as required --" ) }

    return { $current_dept => \@depts };
}

#
# Generates the User label with dropdown for user based options on the main header
#
# Return: hash (for displaying as parameter for $BS->menu() )
###################
sub _user_header {
###################
    my $self   = shift;
    my $scope  = shift;
    my $mobile = shift;

    my $dbc = $self->{dbc};

    my $pg         = $dbc->session->user_setting('PRINTER_GROUP');
    my $user_label = $dbc->config('db_user') . '@' . $dbc->config('dbase') . '.' . $dbc->config('host');
    my $access     = $dbc->session->param('access');

    my @user_options;    ## = ('<B>' . $dbc->config('user') . '</B> @' . $dbc->config('dbase'), "<U><B>$user_label</B></U>", "[$pg]", "Access: " . $access);
    
    my $user = $dbc->config('user');
    my $dbase = $dbc->config('dbase');

    my $class = ref $self->Model;

    if ( $scope =~ /department/i ) {
        if ($mobile) {
            my $mode;
            if ($dbc->config('Database_Mode') && $dbc->config('Database_Mode') ne 'PRODUCTION') { $mode = '[' .  $dbc->config('Database_Mode')  . ']' }  ## only show for non-production modes... 
            
            $user = "<span style='padding:40px;'>\n" . "$mode <B>$user</B> " . Show_Tool_Tip( $BS->icon('user') . ' ' . $BS->icon('caret-down'), "User Options", -placement => 'bottom' ) . "\n</span>\n";
        }
        else {
            $user = $BS->icon('user') . " - <B>$user</B> \@$dbase" . $BS->icon('caret-down');
        }

        push @user_options, (
            Link_To( $homelink, 'Change Password', "&cgi_application=${class}_App&rm=Change Password" ),
            # Link_To($homelink,'Preferences',"&cgi_application=LampLite::Session_App&rm=Set Preferences"),
            Link_To($homelink,'View Settings',"&cgi_application=LampLite::Session_App&rm=View Settings"),
            Link_To( $homelink, 'Change Printer Group', "&cgi_application=alDente::Barcode_App&rm=Change Printer Group" ),

            #  Link_To($homelink,'Generate Login Barcode',"&cgi_application=alDente::Employee_App&rm=Generate Login Barcode"),
        );
    }
    elsif ( $scope =~ /project/i ) {
        $user   = $dbc->session->param('user_name') . ' ' . $BS->icon('caret-down');
        $access = 'Limited Access as Collaborator';

        ## Different User dropdown options for external users ##
        push @user_options, ( Link_To( $homelink, 'My Profile', "&cgi_application=alDente::Login_App&rm=Contact Profile" ), Link_To( $homelink, 'LIMS Contacts', "&cgi_application=alDente::Login_App&rm=LIMS Contacts" ), );
    }

    my $home = $dbc->homelink( -clear => 1 );
    push @user_options, Link_To($home , 'Logout', "&Relogin=1" );

    my $alternate_version = $dbc->homelink();
    my $alternate;
    
    my ($desktop, $mobile) = ('alDente.pl', 'scanner.pl');
    if ($dbc->mobile()) {
        $alternate_version =~s/\/$mobile/\/$desktop/;
        $alternate = 'desktop';
    }
    else {
        $alternate_version =~s/\/$desktop/\/$mobile/;
        $alternate = 'mobile';
    }
    push @user_options, '<hr>';
    push @user_options, Link_To($alternate_version, "Switch to $alternate version");

    return { $user => \@user_options };
}

##################
sub guest_page {
##################
    my $self = shift;
    my $dbc = shift;

    return $self->relogin($dbc);
}

#############################################################
sub unidentified_user_page {
#############################################################
    #
    #
    #
    # Return: html page
#############################################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $user = $args{-user};
    my $dbc  = $args{-dbc} || $self->{dbc};
    
    my $Login = $self->{Login};
    
    my $messages;
    my $first_letter = substr( $user, 0, 1 );
    my @possible_username_matches = $dbc->Table_find( $Login->{login_table}, $Login->{username_field}, "WHERE $Login->{username_field} LIKE '%$user%' OR $Login->{username_field} LIKE '$first_letter%'");
    my $username_list = "<ul><li>" . join( "</li><li>", @possible_username_matches ) . "</li></ul>";

    my ($inactive) = $dbc->Table_find( $Login->{login_table}, $Login->{username_field}, "WHERE ($Login->{username_field} like '$user' OR $Login->{email_field} Like '$user') and $Login->{login_table}_Status NOT LIKE 'Active'");
    
    if ($inactive) {
        $dbc->warning("$inactive appears to be currently flagged as an Inactive user - please see LIMS admin to reactivate this account");
    }
    else {
        $dbc->warning("Sorry, '$user' is not a recognized account name\n<B>Note: User names are case sensitive</B>");
        if (@possible_username_matches) { print $BS->message(["Perhaps you meant one of these names?: ", @possible_username_matches]) }
    }
    return;
}

#############################################################
#
#
#
# Return: html page
#############################################################
sub change_password_box {
#############################################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $email = $args{-email} || $dbc->config('user_email') ;
    my $encryption = $args{-encryption};

    my $printer = $q->param('Printer_Group');

    my $hidden = $q->hidden( -name => 'email',          -value => $email, -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'LampLite::Login_App', -force => 1 )
        . set_validator(-name=>'New_Pwd', -mandatory=>1, -format=>"^[a-zA-Z]\\S{5,}\$", -prompt=>"Password must:\n* start with a letter\n* contain no spaces\n* be at least 6 characters long")
        . set_validator(-name=>'Confirm_New_Pwd', -mandatory=>1);    

    if ($email && $encryption) {
        $hidden .= $q->hidden( -name => 'Encrypted', -value => $encryption, -force=>1) , "\n"
            . set_validator(-name=>'Current_Pwd', -mandatory=>1) . "\n";        
    }    
    else {
        $user = $email || $dbc->{user_name} || 'Username';
    }

    my $check_confirmation = "if ( document.getElementById('pwd1').value != document.getElementById('pwd2').value ) { alert('New Password values do not match'); return false; }";
    
    my $Form = new LampLite::Form(-dbc=>$dbc, -framework=>'bootstrap', -style=>'form-horizontal');

    $Form->append('Username:', $q->textfield(-disable=>1, -placeholder=>$user)); ##  . ' [' . $dbc->config('user_email')  . ']', -disable=>1);
    $Form->append('Old Password:',         $q->password_field( -name => 'Current_Pwd', -default => '', -size => 20, -force => 1 ) );
    $Form->append( 'New Password:',         $q->password_field( -name => 'New_Pwd', -default => '', -id=>'pwd1', -size => 20, -force => 1 ) );
    $Form->append('Confirm New Password:', $q->password_field( -name => 'Confirm_New_Pwd', -default => '', -id=>'pwd2', -size => 20, -force => 1 ));
    $Form->append('', $q->submit(
                -name  => 'rm',
                -value => "Save New Password",
                -class => "Action",
                -force => 1,
                -onClick => "$check_confirmation; return validateForm(this.form);"
            )
    );
        
    my $page = '<h3><center>Change Password</center></h3>' . $Form->generate(-open=>1, -close=>1, -include=>$hidden);

    return $page;
}

#############################################################
#
#
#
# Return: html page
#############################################################
sub display_change_password_page {
#############################################################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $printer = $q->param('Printer_Group');

    my $table = HTML_Table->new( -title => "Password Change", -colour => '#CCCCCC', -width => '40%' );

    $table->Set_Row( [ 'Username:',                 $dbc->{user_name} ] );
    $table->Set_Row( [ 'Old Password:',         $q->password_field( -name => 'Current_Pwd', -default => '', -size => 20, -force => 1 ) ] );
    $table->Set_Row( [ 'New Password:',         $q->password_field( -name => 'New_Pwd', -default => '', -size => 20, -force => 1 ) ] );
    $table->Set_Row( [ 'Confirm New Password:', $q->password_field( -name => 'Confirm_New_Pwd', -default => '', -size => 20, -force => 1 ) ] );
    $table->Set_Row(
        [   $q->submit(
                -name  => 'rm',
                -value => "Save new password",
                -class => "Action",
                -force => 1,
                -onClick => "return validateForm(this.form);"
            ),
            ''
        ]
    );
    
    my $session_app = ref $self || $self;   ## enables use as either object or fully qualified function ##
    $session_app =~s/::(.+)$/::Session_App/;

    my $page
        = $self->Model->start_Form( $dbc, 'Change_Pass_Page' )
        . $table->Printout(0)
        . $dbc->message("Password MUST start with a letter and contain no spaces", -return_html=>1)
        . $q->hidden( -name => 'cgi_application', -value => $session_app, -force => 1 )
        . set_validator(-name=>'Current_Pwd', -mandatory=>1)
        . set_validator(-name=>'New_Pwd', -mandatory=>1, -format=>"^[a-zA-Z].{5}", -prompt=>"Password must: start with a letter, contain no spaces and be at least 6 characters long")
        . set_validator(-name=>'Confirm_New_Pwd', -mandatory=>1)
        . $q->end_form();

    return $page;
}

###########################
sub display_Default_page {
###########################
    my $self = shift;
    
    my $default =<<DEFAULT;
    
Welcome to the LampLite Default page (with no login).

You should only see this page if you are attempting to generate a login page, but there is no database connection.

You should either troubleshoot your database connection or turn off the requirement for a login process.

DEFAULT


    $default =~s/\n/<BR>/g;
    
    return $default;
    
}

#
# Override this message at higher levels as required or customize here if necessary
#
#
#
# Return: block of text for guest home page (no login required)
#######################
sub guest_home_page {
#######################
    my $self = shift;
    
    my $page =<<DEFAULT;

 This is the default guest page.
 
 If you require users to login, set the 'login_required' flag in the main configuration file.
 
 If you want to customize this page, create a method of the same name within the top level Login_Views module (ideally at the custom/ level if applicable)

DEFAULT

     $page =~s/\n/<BR>/g;

     return $page;   
    
}

#
# Wrapper for default home page
#
#
################
sub home_page {
################
    my $self   = shift;
    my %args   = \@_;
    my $option = $args{-target} || 1;
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $position = $args{-position};
    my $scope = $args{-scope} || 'department';
    
    my $mobile = $dbc->mobile();

    my $quiet = 1;

    my $right = [ $self->_dept_header($scope), $self->_user_header( $scope, $mobile ) ]; ## , $self->_help_header()
        
    my $header = $BS->start_header( -name => 'collapseHeader', -position => $position )
        . $BS->header(
            -left   => [ 'LEFT' ],
            -centre => [ 'CENTER'],
            -right  => $right,
            -style  => "background-color:white; border-color:white;",
            -flex   => [ 2, 2, 1]
        );
        
    my $id = int( rand(1000) );
    my $guest = 0;
    
    my $input_bar;
    $header .= "<div style='display:none' id=>$id>\n$input_bar</div>\n";
    
    if (!$guest && $input_bar) {
        ## only include input bar for internal users during run mode (scanner home page already has sections for standard input bar buttons)
        $header .= $BS->toggle_open($id)
        . $input_bar
        . $BS->toggle_close()
    }
    $header .= $BS->end_header();
    
    my $main_block = $BS->layer(-layers=> [
            { label => 'Introduction', content => 'Introduction section'},
            { label => 'Details', content => 'Detailed section'},
            { label => 'Contact Us', content => "Contact Details..." },
            { label => 'Map', content => test_map() },
        ]);

    my $return_page = $header . $main_block;
 
    return $return_page;
}

#################
sub test_map {
#################
    
    my $map = qq(
<div id='map-canvas' width=100%>
<img src="http://maps.googleapis.com/maps/api/staticmap?
center=Vancouver, BC
&size=1400x600
&zoom=7
&maptype=roadmap
&markers=color:blue%7Clabel:A%7CSquamish, Vancouver, BC
&markers=color:blue%7Clabel:B%7CRichmond, BC
&markers=color:red%7Clabel:C%7CPowell River, BC
&markers=color:red%7Clabel:C%7CVictoria, BC
&markers=color:red%7Clabel:C%7CDuncan, BC
&sensor=false"
</div>
);

    my $init = qq(
<script>
        function initialize() {
          var mapOptions = {
            zoom: 4,
            center: new google.maps.LatLng(-25.363882, 131.044922)
          };

          var map = new google.maps.Map(document.getElementById('map-canvas'),
              mapOptions);

          var marker = new google.maps.Marker({
            position: map.getCenter(),
            map: map,
            title: 'Click to zoom'
          });

          google.maps.event.addListener(map, 'center_changed', function() {
            // 3 seconds after the center of the map has changed, pan back to the
            // marker.
            window.setTimeout(function() {
              map.panTo(marker.getPosition());
            }, 3000);
          });

          google.maps.event.addListener(marker, 'click', function() {
            map.setZoom(8);
            map.setCenter(marker.getPosition());
          });
        }

        google.maps.event.addDomListener(window, 'load', initialize);        
</script>
);

    return $map . $init;
}

#############################################################
#
#
#
# Return: html page
#############################################################
sub display_Login_page {
#############################################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->{dbc};
    my $dest_url = $args{-url};
    my $reload   = $args{-reload};
    my $expired  = $args{-expired};
    my $forgot    = $args{-forgot};    ## override optional apply for account link
    my $apply    = $args{-apply};      ## override optional apply for account link
    my $append   = $args{-append};   ## optional extra lines in login page ( array of arrays for each row added )
    my $prepend   = $args{-prepend};   ## optional extra lines in login page ( array of arrays for each row added )
    my $title    = $args{-title} || 'Log In';
    my $default_user     =  $args{-default_user};
    my $app      = $args{-app} || 'LampLite::Login_App';
    my $header   = $args{-header};

    if (!$dbc) { return $self->display_Default_page() }

    my $forgot = Show_Tool_Tip(
        Link_To( "alDente.pl?cgi_application=LampLite::Login_App&Database_Mode=PRODUCTION&rm=Log In&User=Guest&cgi_application=SDB::Login_App&rm=Reset Password", "Forgot Password or Username ?" ),
        "This will send an email message that will enable you to reset your password");
        
    my $apply = Show_Tool_Tip(
        Link_To( "alDente.pl?cgi_application=LampLite::Login_App&rm=Log In&User=Guest&cgi_application=SDB::Login_App&rm=Apply for Account", "Register" ),
        "This will direct you to a form to apply for your own LIMS account.\n\nIf you think you may already have a LIMS account\nplease use 'Forgot Password' link below"
        );

    my $mode     = $dbc->{screen_mode};

    my $Sess = $dbc->session();
    $expired ||= $Sess->param('expired_session');
    if ($dest_url) {
        $dbc->message("Please provide your password to login to the system.");
    }
    else {
        $dest_url = $dbc->homelink(-clear=>1);    ## could also use 'url' (?)..
    }

    my $user = $q->param('User') || "Guest";
    my @clear = ('CGISESSID', 'Database_Mode');
    
    my $version_name = $args{-version_name};
    my $user_entry = Show_Tool_Tip( $q->textfield(-name=>'User', -default=>$default_user, -class=>'form-control input-lg', -force=>1, -placeholder=>'Username'), 'Enter Username or Email Address');
    
    my $password_entry = $self->password_box( -dbc => $dbc, -default=>'', -placeholder=>'Password', -force=>1);
    
    my $login_table = HTML_Table->new(
        -title  => $title,
        -toggle => 0,
        -align  => 'center',
        -padding => 15,
        -width => '80%',
    );

    my $sign_in = qq(<button class="btn btn-primary btn-lg btn-block" name='rm' value='Log In' onclick="return validateForm(this.form)" class="Std">Sign In</button>\n);
    my $options = qq(<span class="pull-left">$forgot</span>\n<span class="pull-right">$apply</span>\n);

    $login_table->Set_Row( [ "<span class='pull-left'>$apply</span><BR>" . $user_entry] );
    $login_table->Set_Row( [ $password_entry . "<BR><span class='pull-left'>$forgot</span>"] );
    $login_table->Set_Row( [ $sign_in ]); #                    $q->submit( -name => 'rm', -value => 'Log In', -force => 1, -class => "Std", -size=>'large', -onclick => 'return validateForm(this.form)' ) ] );

    if ($append) {
        my $extras = new HTML_Table(-width=>'100%');
        foreach my $row (@$append) {
            $extras->Set_Row( $row, -name=>'advanced_login');
        }
        $extras->Set_Column_Class( 1, 'align=center' );
        
        $login_table->Set_Row( [$BS->accordion(-layers=>[{ label => 'Advanced Login Options', 'content' => $extras->Printout(0) }]) ]);
    }

   $login_table->Set_VAlignment('top');
    $login_table->Set_Column_Class( 1, 'align=center' );

    my $form = new LampLite::Form(-dbc=>$dbc, -type=>'login');
    
    my $content = $login_table->Printout(0) . $q->hidden( -name => 'cgi_application', -value => $app, -force => 1 );
    
    if ($expired) { $content .= $q->hidden( -name => 'Expired_Session', -value => $expired, -force=>1) }    ## note that this is an expired login (allows for regeneration of previous page ##

    if ($reload || $expired) {
        $content .= $q->hidden( -name => 'Dest_URL', -value => $dest_url, -force => 1 );
        ## Construction: move to Login section... ##
        my $reload = LampLite::Login::reload_input_parameters( -reset => 1, -clear=>\@clear);
        $content .= $reload;
    }
    
    $content .= set_validator( -name => 'User', -mandatory => 1 );
    $content .= set_validator( -name => 'Pwd', -mandatory => 1 );
    
    my $page = $header;
    
    $page .= $prepend;
    
    $page .= $form->generate(-content=>$content, -wrap=>1, -clear=>\@clear);

    return $page;
}

#
# initialize header
#
#######################
sub generate_Header {
######################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'dbc,header,case' );
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $header = $args{ -header };                                  ## default header (used for login page or guest page ...)  ##
    my $case   = $args{ -case };
    my $brand_image = $dbc->config('icon');

    if ($self->{generated_header}) { return }

    my $user;
    if ( $dbc && $dbc->session() && $dbc->session->logged_in() ) {
        $header = $self->header( -dbc => $dbc, -icon => $brand_image, -text=>"");
    }
    else {
        $header = $self->login_page_header( -dbc => $dbc, -image => $brand_image );
    }
    
    $self->{generated_header};
    $dbc->{header_generated} = 1;
    return $header;
}

##############
sub header {
##############
    my $self = shift;
    my %args   = filter_input( \@_, -args => 'rows,span' );
    my $row = $args{-row};
    my $span = $args{-span};
    my $colour = $args{-colour} || '#FFF';
    my $dbc = $self->dbc();

    my $header = "<div id='primaryHeader' class='primaryHeader navbar-fixed-top' style='background-color:$colour'>HEADER\n";
    if ($row) { $header .= $BS->row($row, $span) }
    $header .= "\n</div> <!-- End of Header -->\n\n";
            
    my $header = "<div class='col-md-12'>\n<div class='col-md-1'>\n";
    
    $header .= "</div><div class='col-md-10'>\n";
    $header .= "Standard Header...";
    $header .= "</div><div class='col-md-1'>\n";
    
    $header .= "</div>\n</div> <!-- END of Standard Header -->\n";

    return $header;
}

#######################
sub login_page_header {
#######################
    my $self = shift;
    my %args   = filter_input( \@_, -args => 'rows,span' );
    my $row = $args{-row};
    my $span = $args{-span};
    my $colour = $args{-colour} || '#FFF';
    my $image = $args{-image};  ## logo
        
    if ($image && !$row) { $row = ["<center><IMG SRC='$image' class='logo'></IMG></center>"] }
    
    my $header = "<div id='primaryHeader' class='primaryHeader navbar-fixed-top' style='background-color:$colour'>\n";
    $header .= $BS->row($row, $span);
    $header .= "\n</div> <!-- End of primaryHeader -->\n\n";

    return $header;
}

#
# Generates the Home / Icon for the primary header
#
# Return: HTML for Home / Icon
####################
sub _home_header {
####################
    my $self   = shift;
    my %args = filter_input(\@_, -args=>'scope,mobile');
    my $scope  = $args{-scope};
    my $mobile = $args{-mobile};
    my $style  = $args{-style};
    my $dbc    = $self->{dbc};

    my $icon_img = $dbc->config('icon');
    
    if (!$mobile) { $style .= " padding-top:15px" }  ## adjust spacing on desktop ... 
    
    my $icon   = "<IMG SRC='$icon_img' width=300>\n";

    my $home = $BS->icon( 'home', -size => '2x', -style=>$style);
    $home = Link_To($dbc->homelink(), $home);

    if ($mobile) {
        return $home;
    }
    else {
        return $BS->flexbox( [ $home, $icon ] );
    }
}

##########################################################################################################################
#####  SMALL FUNCITONS
##########################################################################################################################
#############################################################
#login
#
#
#############################################################
sub reset_unknown_password {
#############################################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    
    my $class = ref $self->Model;
 
    my $form = new LampLite::Form( -dbc => $dbc, -name => 'Reset_Password');
    my $page = page_heading("Resetting Password");
    $page .= $form->generate( -dbc => $dbc, -open => 1)
        . $q->hidden(-name=>'cgi_application', -value=>$class . '_App', -force=>1)
        . "\nEmail Address:\n"
        . Show_Tool_Tip( $q->textfield( -name => 'email', -size => 20, -default => $user, -force => 1 ), 'Email address (do not need to include the domain (@bcgsc.ca) if internal)' ) . "\n"
        . $q->submit( -name => 'rm', -value => "Reset Password", -force => 1, -class => "Action" )  . "\n"
        . $q->submit( -name => 'rm', -value => "Email Username", -force => 1, -class => "Action" )  . "\n"
        . $q->end_form()  . "\n";

    return $page;
}

#
#
#
#############################################################
sub password_box {
#############################################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $password_description = "Default Password for new users = 'pwd'";
    my $password = &RGTools::RGIO::Show_Tool_Tip( 
        $q->password_field( -name => 'Pwd', -class=>'form-control input-lg', -default => '', -size=>'large', -force => 1, -placeholder=>'Password'), 
        $password_description );

    return $password;
}


##########################################################################################################################################################
## Methods below moved from alDente::Web ... may need to move some logic back up the ladder, but the baseline methods should probably be at this level ###
##########################################################################################################################################################

###########
sub Menu {
###########
    my $self = shift;
    my %args            = &filter_input( \@_ );
    my $sections        = $args{-sections};
    my $link            = $args{ -link };
    my $dbc             = $args{-dbc} || $self->dbc;
    my $style           = $args{-style};
    my $id              = $args{-id} || rand(100);
    my $include_options = $args{-include_options};
    my $class           = $args{-class} || 'tabmenu';    ## two menu types being used are iconmenu, dropnav and tabmenu for now...
    my $inverse         = $args{-inverse};
    my $position        = $args{-position};

    my $user_id   = $dbc->get_local('userid');
    my $dept      = $dbc->get_local('current_department');
    my $timestamp = date_time();

    my $menu_items = [];
    my $menu;

    if ( $link =~ /Target_Department/ ) {
        ### Department Menu at top of header ###
        $style = 'topmenu';
        foreach my $dept (@$sections) {
            $link =~ s/Target_Department=([\w\s]+)/Target_Department=$dept/;
            push @{$menu_items}, { $dept => "$link" };
        }
    }
    else {
        ### Icon Menu at bottom of header ###
        $style           = 'bottommenu';
        $link            = $dbc->{homelink};
        $menu_items      = $sections;
        $include_options = 1;
    }

    return $menu_items;
}

########################################
#
# Generate barcode icons for the top of the page.
#   specify the icons you want to be displayed as array ref $args{-icons}
#
########################
sub page_icons {
########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc                = $args{-dbc} || $self->dbc;
    my $dept               = $args{-dept};
    my $custom_icons       = $args{-custom_icons};
    my $custom_icon_groups = $args{-custom_icon_groups};
    my $height             = $args{-height} || 30;
    my $width              = $args{-width} || 30;

    my $background = 'white';    ## background color of the table
    my $icon_text  = 1;          ## turn off text below icons...
    my $user_id   = $dbc->config('user_id');

    my $admin = ( $dbc->get_local('groups') && grep /Admin$/, @{ $dbc->get_local('groups') } );

    my $homelink = $dbc->homelink();

    my ( $icon_list, $icon_class ) = $self->load_standard_icons(%args);
    my $scanner_mode = $dbc->config('screen_mode');
    
    my $URL_domain = $dbc->config('URL_domain');
    my $dir     = $dbc->config('URL_dir_name');
    my $path = "$URL_domain/$dir/cgi-bin/";
    
    if ( $scanner_mode =~ /desktop/i && $admin ) {
        if ( $icon_class =~ /^drop/ ) {
            ## Hash format for dropdown menus ##
            if ( grep /Site Admin/, keys %{ $dbc->config('Access') } ) {
                ## admin options at top of page... ##
                push @$icon_list,
                    {
                    'LIMS Team' => [
                        { 'Query Tool' => "$homelink&cgi_application=SDB::DB_Query_App" },
                        { 'Table_Info' => "$path/DB_admin.pl?Database_Mode=DEV&Type=General" },
                        { 'Coding'     => "$path/SDB_code.pl?Database_Mode=DEV&Type=General" },
                    ]
                    };
            }
            elsif ( grep /Admin/, @{ $dbc->config('groups') } ) {                
                 push @$icon_list,
                        {
                        'mySQL' => [
                            { 'Query Tool' => "$homelink&cgi_application=SDB::DB_Query_App" },
                        ]
                    };
            }
        }
        else {
            push @$icon_list, { 'Add Message' => "$homelink&New+Entry=New+Message&FK_Employee__ID=$user_id" };

            if ( grep /Site Admin/, keys %{ $dbc->get_local('Access') } ) {
                ## admin options at top of page... ##
                push @$icon_list, { 'Query Tool' => "&cgi_application=SDB::DB_Query_App" }, { 'Table_Info' => "$path/DB_admin.pl?Database_Mode=DEV&Type=General" },
                    { 'Coding' => "$path/SDB_code.pl?Database_Mode=DEV&Type=General" };
            }
        }
    }
    return ( $icon_list, $icon_class );
}

#
# Wrapper to build menu specification hash
# (Controls order and organization of primary navigation menu)
#
###########################
sub load_standard_icons {
###########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,dept,getall', -mandatory => 'dept' );
    my $dbc                = $args{-dbc} || $self->dbc;
    my $dept               = $args{-dept};
    my $custom_icon_groups = $args{-custom_icon_groups};
    my $custom_icons       = $args{-custom_icons};
    my $height             = $args{-height} || 30;
    my $width              = $args{-width} || 30;

    my @defaults = qw();
    push( @defaults, 'Issues' );

    my ( @icons, $icon_class );

    ## Check to see if icons variable is specified
    if ( $dept eq 'Site Admin' ) {
        ## don't bother setting icons ... all should be included ...
        $icon_class = 'dropnav';
    }

    if ( $args{-getall} ) {
        @icons = $self->icons( -custom_icons => $custom_icons );
    }
    else {
        $dept ||= 'Public';    ## if no department specified, assume public ##

        @icons = @defaults;

        # Dynamicly get the department module path and name
        my ( $path, $module ) = $self->get_dept_module($dept);
        eval "require $module";
        my $icons_ref = [];

        $icons_ref = $module->get_icons( -dbc => $dbc );
        $icon_class = $module->get_icon_class() || 'dropnav';

        my $dept_icons;
        eval("\$dept_icons = \$module->get_custom_icons();");

        if ($icons_ref) { push @icons, @{$icons_ref} }
        if ($dept_icons) {
            foreach my $key ( keys %{$dept_icons} ) {
                if ( !grep /^$key$/, @icons ) { push @icons, $key }
            }
        }
    }

    my %Icons;
    if ($custom_icon_groups) { %Icons = %$custom_icon_groups }

    my @icon_list;
    my ( $label, @headers ) = ('short');
    if ( $icon_class =~ /^drop/ ) {
        if ( $custom_icon_groups->{ORDER} ) {
            @headers = @{ $custom_icon_groups->{ORDER} };    ## ( 'Home', 'Lab', 'Tracking', 'Admin', 'Database', 'Shipments', 'Runs', 'Views', 'Summaries', 'Help' );
        }
        elsif ($custom_icon_groups) {
            @headers = keys %$custom_icon_groups;
        }

        $label = 'long';
    }


    my ( %Links, @dropdown_icons, %duplicate_icons );
    ## build dropdown menu ## skip this block if just showing icons at top of page... ##
    foreach my $key (@headers) {
        if ( !$Icons{$key} ) { next }
        my @available_icons = @{ $Icons{$key} };

        foreach my $icon (@available_icons) {
            if ( @icons && !grep /^$icon$/, @icons ) { next }    ## only include it if it is in the specified list of icons
            if ( $duplicate_icons{$icon} ) { next }              ## icon already included
            $duplicate_icons{$icon} = 1;

            my $hash = $self->icons( $icon, -dbc => $dbc, -width => $width, -custom_icons => $custom_icons, -hash => 1, -label => $label );
            
            push @{ $Links{$key} }, $hash;
            push @dropdown_icons, $icon;
        }

        if ( $key eq 'Views' ) {
            ## Add Personal Views to Menu if available ##
            my @views = $self->load_user_views( -dept => $dept );
            if (@views) { push @{ $Links{$key} }, @views }     ## format eg: @views = ({'A' => 'B'}, {'C' => 'D'});
        }
    }

    foreach my $key (@headers) {
        if ( $Links{$key} && int( @{ $Links{$key} } ) >= 1 ) {
            my $added = { $key => $Links{$key} };
            push @icon_list, $added;
        }
        else { push @icon_list, $Links{$key}->[0] }
    }

    # Go through all icons to be included in case any of them were missed above....
    foreach my $type (@icons) {
        if ( grep /^$type$/, @dropdown_icons ) {next}

        #Special check for admin icon
        if ( $type =~ /Admin/ ) {
            my $Access = $dbc->get_local('Access');
            unless ( ( grep( /Admin/, @{ $Access->{$dept} } ) ) || $Access->{'Site Admin'} ) {next}
        }

        my $image = $self->icons( $type, -dbc => $dbc, -width => $width, -custom_icons => $custom_icons, -hash => 1, -label => $label );
        push @icon_list, $image;
    }

    return ( \@icon_list, $icon_class );
}

##################
sub icons {
##################
    my %args         = &filter_input( \@_, -args => 'name,dept,dbase', -self=>'LampLite::Login_Views');
    my $self = $args{-self};
    my $key          = $args{-name};                                       ## indicate thumbnail; otherwise retrieves array of defined icons
    my $dbc          = $args{-dbc} || $self->dbc;
    my $no_link      = $args{-no_link};                                    ## enable link from label if applicable
    my $no_label     = $args{-no_label} || 0;                              ## show label below icon
    my $no_tip       = $args{-no_tip};
    my $window       = $args{-window};                                     ## open in new window option (eg -window=>['icon_window'])
    my $custom_icons = $args{-custom_icons};
    my $image        = $args{-image};                                      ## similar, but simply returns image (same usage as name)
    my $hash         = $args{-hash};                                       ## return hash IMG => link
    my $label        = $args{-label};                                      ## long or short format with name + image

    my $homelink = $dbc->homelink();

    if ($image) { $key = $image; $no_label = 1 }

    my $pic_only = $args{-pic_only};
    if ($pic_only) { ( $no_link, $no_label, $no_tip ) = ( 1, 1, 1 ) }

    my $dept  = $args{-dept}  || '';
    my $dbase = $args{-dbase} || '';
    my $height = $args{-height};
    my $width  = $args{-width};
    my $home_dept;

    my $department;

    my $size_spec = '';
    if ($height) {
        $size_spec .= " style=height:${height}px";
    }    ## allow specification of icon heights...
    if ($width) {
        $size_spec .= " style=width:${width}px";
    }

    my %images;
    if ($custom_icons) { %images = %$custom_icons }
    else {
        my $custom;
        if ($dbc) { $custom = $dbc->config('custom') }
        $custom ||= 'alDente';
        $custom .= '::Menu';

        eval "require $custom";
        my $Menu = $self->Model(-class=>'Menu', -dbc=>$dbc);
        
        %images = $Menu->get_Icons( -dbc => $dbc );
    }

    if ( !$key ) { Message("NO KEY FOR image"); return keys %images; }
    elsif ( $key && $images{$key} ) {
        my $title     = $images{$key}{name} || $key;
        my $icon_name = $images{$key}{icon};
        my $url       = $images{$key}{url};
        my $link      = $images{$key}{link};
        my $tip       = $images{$key}{tip};

        if ($url) { $link ||= "$homelink&$url" }
        my $show_icons = 1;

        #        my $start_icon_link = Link_To($link,$image,'&test=1');  ## qq(<a href='$link' style="text-decoration:none;">);
        #        my $end_icon_link   = '</a>';
        my $image = "";
        my $image_dir     =  $dbc->config('images_url_dir');
        
        if ($show_icons) {
            $image .= qq(<IMG border=0 src='$image_dir/iconss/$icon_name' alt='$key' title='$key' $size_spec>);
        }

        if ( $link && $hash ) {
            my $img = "<IMG border=0 SRC='$image_dir/icons/$icon_name' alt='$key' title='$key' $size_spec>";
            if ( $label =~ /long/ ) { $img .= " - $title" }
            elsif ( $label =~ /short/ ) {
                $title =~ s/\s/<BR>/;
                $img .= "<BR>$title";
            }
            return { $img => $link };
        }

        if ( $link && $image ) { $image = Link_To( $link, $image, -window => $window ) }    ## $start_icon_link . $image . $end_icon_link }
        if ( $tip && !$no_tip ) { $image = Show_Tool_Tip( $image, $tip ) }

        my ( $icon, $label );
        if ( !$no_label ) {
            if ($title) {
                $label = $title;
            }
            else {
                $label = $key;
            }
            $icon = Views::Table_Print( content => [ [$image], ["<font size=-2>$label</font>"] ], print => 0, width => $height, nowrap => 0 );
        }
        else {
            $icon = $image;
        }

        return $icon;
    }
    else {
        if ($hash) { return { '' => '' } }
        return $key;
    }
}

#
# Load user views into the dropdown menu
#
#
# Return array of hashes for LI elements as
#######################
sub load_user_views {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->dbc;
    my $dept = $args{-dept};

    require alDente::View;
    my $View = new alDente::View( -dbc => $dbc );

    my @views;

    my $homelink = $dbc->homelink();

    my @Eviews;
    my $user_id = $dbc->get_local('user_id');
    my $Eviews = $View->get_available_employee_views( -dbc => $dbc );
    
    if ( $Eviews && values %$Eviews ) {
        my %Eviews = %{ $Eviews->{$user_id} };    ## only one
        foreach my $key ( keys %Eviews ) {
            my $val = $Eviews{$key};
            push @Eviews, { $val => $homelink . '&cgi_application=alDente::View_App&rm=Display&File=' . $key . '&Generate+Results=1' };
        }
    }
    if (@Eviews) { push @views, { 'My Views' => \@Eviews } }
    
    foreach my $dept_group ( $dept, 'Internal', 'Public') {    
        my $Pviews = $View->get_available_group_views( -dbc => $dbc, -department => $dept_group);
        
        if ( $Pviews && keys %$Pviews ) {
            my @groups = keys %$Pviews;
        
            my @Pviews;    
            foreach my $group (@groups) {
                my %Pviews = %{ $Pviews->{$group} };
                my $group_ref = $dbc->display_value( 'Grp', $group, -no_link=>1);
                 foreach my $key ( sort keys %Pviews ) {
                    push @Pviews, { $Pviews{$key} => $homelink . '&cgi_application=alDente::View_App&rm=Display&File=' . $key . '&Generate+Results=1' };
                }
                push @views, { "$group_ref Views" => \@Pviews };
            }
        }  
        
              
    }
    
    #    Clearly delineate section with views (?)
    #    if (@views) { unshift @views, { 'Custom Views' => "<a href='#'>--- Custom Views ---</a>" } }

    return @views;

}

#
# Wrapper to exit script smoothly from anywhere in the code if necessary
#
# Return: does not return - exits directly 
#############
sub leave {
#############
    my $self = shift;
    my %args = filter_input( \@_, -args=>'dbc' );
    my $dbc = $args{-dbc} || $self->{dbc};
    my $quiet = $args{-quiet};    

    ( my $now ) = &RGTools::RGIO::date_time();

    if ($dbc && $dbc->{Benchmark}) { $dbc->Benchmark('End') }
    
    my $big_text_size = 100;
    if ($dbc && $dbc->{screen_mode} =~ /(mobile|tablet)/i) { $big_text_size = 40; }

    #   if ($left_frame) {&Close_Left_Frame();}

    my ($Sess, $homelink);
    
    if ($dbc && $dbc->{connected}) {
        $Sess = $dbc->session();
	    $homelink = $dbc->homelink();
	    $dbc->{admin_access} = 1;
	}
	
    my $output;
    if ($dbc && $dbc->{transaction} && @{ $dbc->{transaction}{trans_names} } ) {
        ## if open transactions found ##
        $output .= $dbc->warning("Unfinished transactions (SQL commands MAY NOT COMMITTED)");
        $dbc->debug_message('Open Transactions: ' . Dumper $dbc->{transaction}{trans_names} );
    }
   
    if ($dbc && $dbc->session && $dbc->Site_admin()) {
        
        $output .= "<HR><h4>Site Admin Session Details:</h4>";
        $output .= $self->session_details( $dbc );
    
        if ($dbc && defined $dbc->{Benchmark}) {
        ### Display Benchmarks, Session, Input, dbc, Config folders to only Site Admins and do not run them for other users
        require RGTools::Unit_Test;
        if ( $dbc->Benchmark->{Start}) {
            my $benchmarks = "\n<U>Ordered list of identified Benchmarks:</U><BR>\n";
            $benchmarks .= Unit_Test::dump_Benchmarks( -benchmarks => $dbc->Benchmark(), -delimiter => '<BR>', -start => 'Start', -format => 'html', -mark => [ 0, 1, 3, 5, 10 ] );
            $output .= create_tree( -tree => { 'Benchmarks' => $benchmarks }, -print => 0 );
        }

        ### see how long this script took to execute (excluding module loading) ###
        if ( $dbc->Benchmark->{End} && $dbc->Benchmark->{Start}) {
            require Benchmark;
            my $diff = Benchmark::timediff( $dbc->Benchmark->{End}, $dbc->Benchmark->{Start} );
            my $execution_time = Benchmark::timestr( $diff );
            if ( $execution_time =~ /(\S+)\s/ && ( $Sess->{dbase} eq $dbc->{PRODUCTION_DATABASE} ) ) {    ## only monitor slow queries for default database ##
                my $slow_time = 10;
                my $very_slow = 30;
                my $time      = $1;
                my $adjective = "SOMEWHAT (> $slow_time sec)";
                if ( $time > $very_slow ) { $adjective = "EXTREMELY (>$very_slow sec)"; }

                if ( $time > $slow_time ) {                                                       ## if it is slow or very slow... ##
                    my $padded_session_time = $Sess->{session_name};
                    if ( $padded_session_time =~ /\d+:(.*)/ ) { $padded_session_time = $1; }
                    $homelink =~ s|\./||;
                    my $PID = $Sess->PID;

                    ## Dump out detailed messages regarding session input for administrators . ##

                    my $user_id = $Sess->{user_id};
                    my $message = "Slow Page Load Time Noted ($time s ?).\nCheck out this link to investigate -> \n<a href='$homelink&Retrieve+Session=1&Session+User=$user_id&Session+Day=$padded_session_time#PID$PID'>View Session</a>\n";

                    $dbc->message("$adjective Slow response time noted and logged");

                    ## Log Slow page generation ##
                    if ($dbc->{slow_page_log_directory}) {
                        ## LOG slow page generation ##
                        my $slow_dir = $dbc->{slow_page_log_directory}; ## "$Data_log_directory/slow_pages/";
                        unless ( -e $slow_dir ) {`mkdir -m 777 $slow_dir`}
                        my $symlink  = $slow_dir . 'current';
                        my $filename = $slow_dir . &datestamp;
                        unless ( -e $filename ) {`touch $filename; chmod 666 $filename; rm $symlink; ln -s $filename $symlink`}

                        open( SLOW, ">>$filename" );
                        print SLOW join "\n", @{ $dbc->{slow_queries} } if ( $dbc->{slow_queries} );
                        print SLOW "Messages\n";
                        print SLOW join "\n", @{ $dbc->{messages} } if ( $dbc->{messages} );
                        print SLOW "Warnings\n";
                        print SLOW join "\n", @{ $dbc->{warnings} } if ( $dbc->{warnings} );
                        print SLOW "Errors\n";
                        print SLOW join "\n", @{ $dbc->{errors} } if ( $dbc->{errors} );
                        print SLOW "System Status\n";
                        print SLOW try_system_command('top -b -n 1 | head -20');
                        print SLOW "\n$message\n" . $self->session_details( $Sess, 'text', 50 ) . "\n**************************\n";
                        close SLOW;
                    }
                }
            }
        }
    }
    }
    
    if ( $dbc->{track_sessions} && $Sess ) {
        $Sess->store_Session_messages() if $Sess;
    }

    if ( $dbc->{admin_access} ) {
        if ( $dbc && $dbc->{connected} ) { $dbc->disconnect }
        else                             { $output .= "(not connected to database)"; }
    }

    print "<div class='col-md-12'>\n$output</div>\n";

    print $BS->close();       ## close container span divs (bootstrap containers)
    
    print LampLite::HTML::uninitialize_page();

    exit;
}

########################
sub session_details {
########################
    my $self = shift;
    my %args = filter_input( \@_, -args=>'dbc' );
    my $dbc     = $args{-dbc};
    my $format   = $args{-format} || 'html';    ## specify output ('html' or 'text')
    my $truncate = $args{-truncate} || 255;     
    my $force    = $args{-force} || 1;
 
    if (!$dbc && ref $self eq 'HASH') { $dbc = $self->{dbc} }
    
    my $br = "<BR>";
    my $li = "<LI>";
    unless ( $format =~ /html/ ) {
        $br = "\n";                    ## use standard linefeed unless html format.
        $li = "\n\t";
    }
    my $message = '<hr>' if $format =~ /html/;

    my $Sess;
    my ($debug_message_count, $debug_messages);
    my $details;
    if ($dbc) {
        $Sess = $dbc->session();
    
         if ($Sess) {
            $details = "\nSession Details:" . $br . $br;
            foreach my $key ( keys %{$Sess} ) {
                $details .= "$key = ";
#                $details .= Dumper $Sess->{$key};
                $details .= $br;
            }
        }

        $debug_messages = 'no debug messages';
        my $debug          = $dbc->{debug_messages};
        if ($debug) {
            $debug_messages = Cast_List( -list => $debug, -to => 'UL' );
            $debug_message_count = int(@{$debug});
        }
        
        $force ||= $dbc->{admin_access};
    }
        
    my $input = $q->show_parameters( $li, $format, $truncate, 'show profiler' );
    
    if ($force) {
        if ( $format =~ /html/ ) {
            my $conn = HTML_Dump($dbc->{LocalAttribute});
            my $config = HTML_Dump($dbc->{config});
            
            my $persistent = $dbc->{config}{session_parameters};
            my $Persistent;
            if ($persistent) {
                $Persistent = "Session Parameters:<BR>"; 
                foreach my $param (@$persistent) {
                    $Persistent .= "$param = " . $dbc->session->param($param) . "<BR>";
                }
            }
            
            my $url = $dbc->{config}{url_parameters};
            if ($url) { 
                $Persistent .= "URL Parameters:<BR>";
                foreach my $param (@$url) {
                    $Persistent .= "$param = " . $dbc->config($param) . "<BR>";
                }
            }
            
            $message .= create_tree( -tree => { 'Input' => $input }, -print => 0 );
            if ($debug_message_count) { $message .= create_tree( -tree => { 'Debug Messages' => $debug_messages }, -print => 0 ) }
            if ($Sess) { $message .= create_tree( -tree => { 'Session' => HTML_Dump($Sess->{_DATA}) }, -print => 0 ) }
            if ($dbc) { $message .= create_tree( -tree => { 'Local' => $conn }, -print => 0 ) }
            if ($config) { $message .= create_tree( -tree => { 'Config' => $config }, -print => 0 ) }
            if ($persistent) { $message .= create_tree( -tree => { 'Persistent' => $Persistent }, -print => 0 ) }
        }
        else {
            $message .= $details . $input;
        }
    }
    
    my @env = split "\n", `env`;
    $message .= create_tree(-tree => { 'ENV' => Cast_List(-list=>\@env, -to=>'UL') } );
    
    return $message;
}

########################################
#
# Return the module and path of a department, passed in as an arg
#
######################
sub get_dept_module {
######################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'dept,custom');
    my $dbc = $self->dbc();
    my $dept = $args{-dept};
    my $custom = $args{-custom} || $dbc->config('custom_version_name');
    
    $dept =~ s/ /_/g;    #repalce the space between dept words

    if ($custom) { return ( "$custom/$dept/Department.pm", $custom . '::' . $dept . '::Department' ) }
    else { return ( "Departments/$dept/Department.pm", $dept . '::Department' ) }

}
 
#########################
sub LIMS_contact_info {
#########################
    my $self = shift;

    my $output;
    $output .= "<U>alDente Development Team:</U>";
    $output .= "<UL>";
    $output .= "<LI>Ran Guin</LI>";
    $output .= "</UL>";
    $output .= "<P><A HREF='mailto:rguin\@bcgsc.ca'>Contact US</A>";

    $output .= '<hr>';

    $output .= "<p>";
    $output .= "<P><A HREF='http://www.bcgsc.bc.ca'>Michael Smith Genome Sciences Centre</A>";

    $output .= "<p>";
    $output .= "<P><A HREF='http://www.bccancer.bc.ca'>BC Cancer Agency</A>";

    return $output;
}
   
#
# If cgi_application was not run, then check for legacy logic not utilizing MVC run mode framework
#
# Return: page generated if applicable (0 if no secondary page generated)
#########################
sub MVC_exceptions {
#########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $sid = $args{-sid};

    my %params;

    ## no run mode output generated... continue as logged in user or guest ... gradually phase out MVC_exceptions and Button_Options ##
    my $mod = $dbc->dynamic_require('MVC_exceptions'); 
    my $branched = $mod->non_MVC_run_modes( $dbc, $sid, \%params, 'alDente' );    ## PHASE OUT - previously embedded in barcode.pl ##
    if ($branched) { $dbc->debug_message("Deprecate use of non_MVC run mode") }
    if ($branched) { print $branched }

    $dbc->Benchmark('tried_mvc_exceptions');

    return $branched;
}

1;
