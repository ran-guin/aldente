###################################################################################################################################
# LampLite::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package UTM::Login_Views;

use base LampLite::Login_Views;

use LampLite::CGI;
use LampLite::Bootstrap;
use strict;

## Standard modules ##

my $q = new LampLite::CGI;
my $BS = new Bootstrap();

use RGTools::RGIO;
use LampLite::HTML;

use UTM::Site_Views;
use UTM::Login_Views;
#################
sub home_page {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->{dbc};
    my $include_header = $args{-include_header};
    
    my $condition = 1;

    my $SV = new UTM::Site_Views(-dbc=>$dbc);

    my ($toggle, $section) = $SV->list_Sites(-dbc=>$dbc, -id=>5);
 
     my $page;
     if ($include_header) { $page .= $self->header()}
     $page .= $SV->page_header();

    $page .= $section;
    return $page;
}

##############
sub header {
##############
    my $self = shift;
    my %args = filter_input(\@_);

    my $dbc = $args{-dbc} || $self->{dbc};
    my $icon_img = $args{-icon} || $dbc->config('icon');

    my $icon     = "<IMG SRC='$icon_img' style='height:100px'>\n";
    
    $icon =~s/alDente_brand/UTM2/;
    $icon = "<h3>Universal Touring Machine</h3>";

    my $BS = new Bootstrap(); ## problem using module wide variable for some reason (?) ... 

    my $help_icon = $BS->icon('question-sign', -tooltip=>"Help Options", -placement=>'bottom'); 
    my $homelink = $dbc->homelink();

    my $user = $dbc->config('user');

    my $access = $dbc->config('utm_access') || 'Guest';
    my $access_mode = $dbc->config('utm_access_mode') || 'Guest';

    my $show_access = Link_To( $dbc->homelink(), "Permission Level: $access");

    my @user_options = ( $show_access );

    push @user_options, '<hr>';

    my ($gm, $vm, $hm, $am);
    if ($access_mode eq 'Guest') { $gm = $BS->icon('check') }
    elsif ($access_mode eq 'Member') { $vm = $BS->icon('check') }
    elsif ($access_mode eq 'Host')   { $hm = $BS->icon('check') }
    elsif ($access_mode eq 'Admin')  { $am = $BS->icon('check') }
    
    my $cgi_app = $q->param('cgi_app');
    my $rm = $q->param('rm');
    my $id= $q->param('ID');
    my $params = "&cgi_app=$cgi_app&rm=$rm&ID=$id";
     
    if ($access =~ /Admin/i) {    
        push @user_options, Link_To( $dbc->homelink(), 'Guest Mode ' . $gm, $params . '&Access=Guest');
        push @user_options, Link_To( $dbc->homelink(), 'View Mode ' . $vm, $params . '&Access=Member');
        push @user_options, Link_To( $dbc->homelink(), 'Host Mode ' . $hm, $params . '&Access=Host');
        push @user_options, Link_To( $dbc->homelink(), 'Admin Mode ' . $am, $params . '&Access=Admin');
    }
    elsif ($access =~ /Host/i) { 
        push @user_options, Link_To( $dbc->homelink(), 'Guest Mode ' . $gm, $params . '&Access=Guest');
        push @user_options, Link_To( $dbc->homelink(), 'View Mode ' . $vm, $params . '&Access=Member');
        push @user_options, Link_To( $dbc->homelink(), 'Host Mode ' . $hm, $params . '&Access=Host');        
    }
    elsif ($access =~/Member/i) {
        push @user_options, Link_To( $dbc->homelink(), 'Guest Mode ' . $gm, $params . '&Access=Guest');
        push @user_options, Link_To( $dbc->homelink(), 'View Mode ' . $vm, $params . '&Access=Member');
        push @user_options, '<hr>';

        my $signup = "At this time, please contact us at info\@cosinesystems.org to register as a host.";
        push @user_options, $BS->modal(-label=>'Register as Host', -title=>'Register as Host', -body=>$signup, -dbc=>$dbc); 
    }
    
    if ($access =~/Guest/i) {
        push @user_options,   Link_To( $dbc->homelink(), 'Sign In');
        ## Register as Member ##
        my $public = $dbc->get_db_value(-sql=>"SELECT Department_ID from Department where Department_Name = 'Public'");
        
        my %hidden;
        $hidden{FK_Department__ID} = $public;
        $hidden{User_Status} = 'Active';
        $hidden{User_Access} = 'Member';

        my $signup = $dbc->View->update_Record(-table=>'User', -omit=>\%hidden, -append=>1 , -cgi_app=>'UTM::App', -rm=>'Register as Member');
        push @user_options, $BS->modal(-label=>'Create an Account', -title=>'Set up a User Account', -body=>$signup, -dbc=>$dbc);
    }
    else {
        push @user_options,   '<hr>';
        push @user_options,   Link_To( $dbc->homelink(-clear=>1), 'Log Out');
    }

    my $site_map;

    my $style;
    if ( !$dbc->mobile() ) { $style .= " padding-top:15px" }  ## adjust spacing on desktop ... 

    my $home = Link_To( $dbc->homelink(), $BS->icon('home', -size=>'3x', -style=>$style) );
    $home = Show_Tool_Tip($home, 'Return to Home Page', -placement=>'bottom');

    my $table = new HTML_Table();
    $table->Set_Line_Colour('#fff');
    $table->Set_Class('nav dropdown-toggle');
    $table->Set_Row([ '', $home , '', $icon]);

    my $main = $table->Printout(0);
    my $header = { 
        '-main' => [ $main] , 
        '-right' => [ 
        #                       { $help_icon => [ Link_To($site_map,'Site Map') , Link_To($homelink, 'Manual', '&cgi_application=alDente::Help_App&rm=Help') ] }, 
        { $user . $BS->icon('bars') => \@user_options },    
        ],
        '-padding' => '40px',   ## this should match fixed header margin in CSS !  ... and align with top of page given logo height
    };

    my $header = 
        $BS->start_header( -name => 'collapseHeader', -position => 'top', -class=>"utm-header")
        . $BS->header(-left => [$home], -centre => [$icon], -right => [{  $BS->button(-label=>$user , -icon=>'bars', -size=>'lg') => \@user_options }], -padding => '40px', -col_size=>'xs')
        . $BS->end_header();
        
    return $header;
    
    return $self->SUPER::header(-dbc=>$dbc, -icon=>$icon, -environment=>'web',
        -left => [$home], -centre => [$icon], -right => [{  $BS->button(-label=>$user , -icon=>'bars', -size=>'lg') => \@user_options }], -padding => '40px', -col_size=>'xs');
}

#############
sub footer {
#############
    my $self = shift;
    
    my $last_id = 1;

    my $footer =  Views::Table_Print(
        content => [[ 
        $self->button_link(-icon=>'backward', -id=>$last_id ,-scope=>'Site'), 
        $self->button_link(-icon=>'chevron-left', -id=>$last_id ,-scope=>'Site'),
        $self->button_link(-icon=>'eject', -id=>$last_id ,-scope=>'Site'),
        $self->button_link(-icon=>'chevron-right', -id=>$last_id ,-scope=>'Site'),
        $self->button_link(-icon=>'forward', -id=>$last_id ,-scope=>'Site'),
        ]], 
        print=>0,
        bgcolour=>'#666',
        align=>['center'],
        width=>'100%');
        
    
    return ;
    return "\n<Div class='footer' style='width:100vw'>$footer</div>\n";
}

###################
sub button_link {
###################
    my $self = shift;
    my %args = filter_input(\@_);
    my $id   = $args{-id};
    my $scope = $args{-scope};
    my $label = $args{-label};
    my $icon  = $args{-icon};

    my $dbc = $self->{dbc};
    
    my $scope = 'Site';
    my $link = $dbc->homelink() . "&cgi_app=UTM::Site_App&rm=View $scope&ID=$id";
    
    my $button = "<A Href='$link' >";

    my $BS = new Bootstrap();  ## seems to be a problem when using module wide variable (?) ... 
    
    $button .= $BS->button(-label=>$label, -icon=>$icon);
    $button .= "</A>";
    
    return $button;
}
#
# custom login page (may call standard login page with extra sections appended)
#
# CUSTOM - move app to same level (not SDB::Session)
#############################################################
#
#
#
# Return: html page
#############################################################
sub display_Login_page {
#############################################################
    my $self     = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $self->param('dbc');
    my @login_extras = (['','<hr>']);

    my $script = 'alDente.pl';
    
    my $other_versions; ##  = $self->aldente_versions( -dbc => $dbc );
    push @login_extras, ['Other Versions:', $other_versions];
    
    my $forgot = Link_To( "$script?cgi_application=LampLite::Login_App&Database_Mode=PRODUCTION&rm=Log In&User=Guest&cgi_application=SDB::Login_App&rm=Reset Password", "Forgot Username or Password?" );
    my $apply = Link_To( "$script?cgi_application=LampLite::Login_App&rm=Log In&User=Guest&cgi_application=SDB::Login_App&rm=Apply for Account", "Apply for New Account" );

    my $header = $self->login_page_header();
    return $self->SUPER::display_Login_page(%args, -app=>'LampLite::Login_App', -apply=>$apply, -forgot=>$forgot, -clear=>['Database_Mode', 'CGISESSID'], -header=>$header);
    
}

#
# 
########################
sub login_page_header {
########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $image = $args{-image};
    
    my $dbc = $args{-dbc} || $self->{dbc};
    my $screen_mode = $dbc->{screen_mode} || 'desktop';

    ## Default home page header ##
    if ($image) { $image ="<center><IMG SRC='$image' width=200></center>\n"}
    else { $image = "<center><B>Universal Touring Machine</B></center>" }

    $image = "<center><B>Universal Touring Machine</B></center>";
 
    my @row;

    my $contact_link;
    if ($screen_mode =~ /desktop/) {
        $contact_link =  "<center>" . $BS->text('Contact Us', -popover => 'vivocongusto@gmail.com'. '</center>');
         $image .= "<P>" . $contact_link;
    }
    push @row, $image;

    return $self->SUPER::login_page_header(-row=>\@row);  

}

#############################################################
#
# Move to GSC scope ... 
#
#############################################################
sub aldente_versions {
#############################################################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $dbc            = $args{-dbc} || $self->param('dbc');

    my $other_versions = '';

    my $master = 'hblims01';
    my $dev    = 'hblims01';
    my $domain = '.bcgsc.ca';
    
    my $script = 'alDente.pl';
    
    my $Target = {
        'Production' => "http://$master$domain/SDB/cgi-bin/$script",
        'Test' => "http://$master$domain/SDB_test/cgi-bin/$script",
        'Alpha' => "http://$dev$domain/SDB_alpha/cgi-bin/$script",
        'Beta' => "http://$master$domain/SDB_beta/cgi-bin/$script",
        'Development' => "http://$dev$domain/SDB_dev/cgi-bin/$script",    
    };

    my @versions = qw(Production Test Alpha Beta Development);
    foreach my $ver (@versions) {
        my $URL = $Target->{$ver};

        $other_versions .= "<li> <a href='$URL'>$ver version</a></li>\n";
    }
    return $other_versions;
}

#####################
sub MVC_exceptions {
#####################
    my %args           = filter_input( \@_, -self=>'UTM::Login_Views');
    my $self = $args{-self};

    return 0;
}
1;
