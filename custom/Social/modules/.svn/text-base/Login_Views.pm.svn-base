###################################################################################################################################
# LampLite::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package Social::Login_Views;

use base SDB::Login_Views;

use strict;

## Standard modules ##


use RGTools::RGIO;
use RGTools::Views;
#use RGTools::HTML_Table;

use SDB::HTML;
use LampLite::Bootstrap();
use LampLite::CGI;

my $q = new LampLite::CGI;
my $BS = new Bootstrap();

############## 
sub relogin {
##############
    my $self = shift;
    my %args = @_;
    return $self->SUPER::relogin(%args);
}

# Return: customized footer spec
#############
sub footer {
#############
     my $self = shift;   
    return; 
}

######################
sub MVC_exceptions {
######################
    my $self = shift;
    
    return 0;
}
######################
sub generate_Header {
######################
    
}
#################
sub lims_header {
#################
    my $self = shift;
    my %args = filter_input(\@_);

    my $dbc = $args{-dbc} || $self->{dbc};
    my $icon = $args{-icon};

    my $text = "";


    my $links = [
        {'href' => '#first', 'label' => 'First'},
        {'href' => '#second', 'label' => 'Second'},
    
    ];
    
    my $local_homelink = $dbc->homelink(-clear=>['Target_Department']);
    if ($icon) { $icon = Show_Tool_Tip("<A Href='$local_homelink'><IMG SRC='$icon' width=200 class='hidden-xs'></A>\n", "Go back to default Home Page", -placement=>'bottom') }
    
    my $space = hspace(60);
    
    my $links;
    if (my $depts = $dbc->config('departments') ) {
        foreach my $dept (@$depts) {
            my $link = Link_To($dbc->homelink(-clear=>'Target_Department'), $dept, "&Target_Department=$dept");
            $links .= $link . ' / ';
        }
    }
    $icon = "<span width=40% align='left'><B><strong style='font-size:26px'>SocioLite</strong></B> $space $icon</span><span class='pull-right'>$links</span><HR>";
    
    return $icon;
}

###################
sub contact_info {
###################
    my $self = shift;

    my $output;
    $output .= "<U>Cosine Team:</U>";
    $output .= "<UL>";
    $output .= "<LI>Ran Guin</LI>";
    $output .= "</UL>";
    $output .= "<P><A HREF='mailto:aldente\@bcgsc.ca'>Contact US</A>";

    $output .= '<HR>';
    $output .= "<U>Collaborators:</U>";
    $output .= "<UL>";
    $output .= "<LI>Ran Guin</LI>";
    $output .= "</UL>";

    $output .= '<hr>';

    $output .= "<p>";
    $output .= "<P><A HREF='http://cosinesystems.org'>COSINE (Community-Oriented Software Innovation Network)</A>";

    $output .= "<p>";

    return $output;
}


#
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

    my @login_extras;
    my $other_versions = $self->aldente_versions( -dbc => $dbc );
    push @login_extras, ['Other Versions:', $other_versions];

    my $page = $self->SUPER::display_Login_page(%args, -append=>\@login_extras, -app=>'Social::Login_App', -clear=>['Database_Mode', 'CGISESSID'], -title=>"Log In");

    return "<center><div style='max-width:500px'>\n$page</div></center>\n"
    

}

1;
