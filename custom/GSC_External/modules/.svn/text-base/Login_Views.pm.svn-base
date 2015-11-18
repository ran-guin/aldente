###################################################################################################################################
# LampLite::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package GSC_External::Login_Views;

use base alDente::Login_Views;
use strict;

## Standard modules ##
use CGI qw(:standard);
use LampLite::Bootstrap();

my $q = new CGI;
my $BS = new Bootstrap();

use RGTools::RGIO;
use RGTools::Views;

use SDB::HTML;
use alDente::Web;
use GSC_External::Menu;

##############
sub header {
##############
    my $self = shift;
    my %args = filter_input(\@_);
    
    my $dbc = $args{-dbc} || $self->{dbc};
    my $icon = $args{-icon};

    my $text = "<B>A</B>utomated <B>L</B>aboratory <B>D</B>ata <B>E</B>ntry <B>N</B>' <B>T</B>racking <B>E</B>nvironment";
    if ($icon) { $icon = "<IMG SRC='$icon' width=200>\n"}
    
    my $local_homelink = $dbc->homelink(-clear=>['Target_Project']);
    my $home = Show_Tool_Tip("<A Href='$local_homelink'>" . $BS->icon('home', -sub_class=>'icon-2x') . "</A>", 'Return to Home Page', -placement=>'bottom');
    
     
    my $table = new HTML_Table();
    $table->Set_Line_Colour('#fff');
    $table->Set_Class('nav dropdown-toggle');
    $table->Set_Row([ &hspace(10), $home , &hspace(10), $icon,  &hspace(10), "<div class='big-screen-item'>$text</div>"]);
                       
    my $main = $table->Printout(0);
     
    my $dept = 'External';
    
    my %custom_icon_map = GSC_External::Menu::get_Icons(-dbc=>$dbc, -dept=>$dept);
    my %icon_groups = GSC_External::Menu::get_Icon_Groups(-dept=>$dept);
    
    my ( $icons, $icon_class ) = &alDente::Web::page_icons( $dbc, -dept => $dept, -width => 30, -custom_icons => \%custom_icon_map, -custom_icon_groups=>\%icon_groups);
    
    my $menu = &alDente::Web::Menu(-dbc=>$dbc, -sections => $icons, -limit => 20, -off_colour => 'white', -id => 'icons', -class => $icon_class, -inverse=>1);
   
    if (! SDB::HTML::clear_tags($menu) ) { $menu = '' };  ## if no menu items are included, ignore hash of empty blocks so that header is not displayed ##

    return $self->SUPER::header(-dbc=>$dbc, -icon=>$main, -menu => $menu, -external=>1);
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
    
    my $prepend = vspace(80);  ## add more space at the top to account for smaller padding, but large header at login ... 
    
    
    
    return $self->SUPER::display_Login_page(%args, -app=>'GSC_External::Login_App', -prepend=> $prepend, -clear=>['Database_Mode', 'CGISESSID']);

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
    
    my $Target = {
        'Production' => "http://$master$domain/SDB/cgi-bin/barcode.pl",
        'Test' => "http://$master$domain/SDB_test/cgi-bin/barcode.pl",
        'Alpha' => "http://$dev$domain/SDB_alpha/cgi-bin/alDente.pl",
        'Beta' => "http://$master$domain/SDB_beta/cgi-bin/alDente.pl",
        'Development' => "http://$dev$domain/SDB_dev/cgi-bin/alDente.pl",    
    };

    my @versions = qw(Production Test Alpha Beta Development);
    foreach my $ver (@versions) {
        my $URL = $Target->{$ver};

        $other_versions .= "<li> <a href='$URL'>$ver version</a></li>\n";
    }
    return $other_versions;
}

#################
# Generate header bar specific to contact who is logged in
#################
sub home_page {
#################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'home,dbc,user_name,contact_id' );
    my $dbc = $self->{dbc};

    my $home         = $args{-home};                  # (Scalar) The home URL
    my $user_name    = $args{-user_name};
    my $account_name = $args{-account_name};
    my $contact_id   = $args{-contact_id} || $dbc->config('contact_id');
    my $project_path = $args{-project_path};          # (Scalar) Web-accessible path for projects and libraries (for publishing)
    my $config_ref   = $args{-config};
    my $layer_key    = $args{-layer_key};
    my $sub_tab      = $args{-sub_tab};
    my $active       = $args{-active};
    my $img_dir      = $args{-img_dir};
    my $session_id   = $args{-session_id};
    my $project_id   = $args{-project_id};
    my $project_name = $args{-project_name};
    
    $dbc->Benchmark('generate_std_home_page');
    my $custom_views = $dbc->config('custom') . '::Views';
    eval "require $custom_views";

    # get what organization the contact is part of
    my @org_list = $dbc->Table_find( "Organization,Contact", "Organization_Name,Canonical_Name", "WHERE FK_Organization__ID=Organization_ID AND Contact_ID=$contact_id" );

    # get list of projects the contact is associated with

    my $scope_condition = "FK_Contact__ID = $contact_id";

    if ( $user_name =~ /^(LIMS Admin|Ran Guin)$/i ) { $dbc->{admin} = 1; $scope_condition = "Project_Status = 'Active'"; }
    my @project_array = $dbc->Table_find( "Collaboration,Project", "Project_ID,Project_Path", "WHERE FK_Project__ID=Project_ID AND $scope_condition" );

    my %home_hash;

    if ($project_id) {
        ($project_name) = $dbc->Table_find( 'Project', 'Project_Name', "WHERE Project_ID = $project_id" );
        $home_hash{$project_name} = $custom_views->project_home_page(%args);
    }
    elsif ($project_name) { 
        ($project_id) = $dbc->Table_find('Project','Project_ID',"WHERE Project_Name = '$project_name'");
    }
    else {
        $project_name = 'Home';
        $home_hash{$project_name} = section_heading('Welcome to the GSC Collaborator LIMS') . "Please click on 'Projects' Tab and select a project from the list.";
    }
    my $templates = $custom_views->External_Template_Download_box(-dbc=>$dbc, -project_id => $project_id );
    $home_hash{'Previous Submissions'} = $custom_views->External_submissions(-dbc=>$dbc, -contact_id=>$contact_id, -config_ref=>$config_ref, -home=>$home, -img_dir=>$img_dir );
    $home_hash{'Download Template'} = $templates if $templates;

    $home_hash{'Projects'} = $self->project_list(-contact_id => $contact_id, -home => $home, -account_name => $account_name, -session_id => $session_id );    ## change to use object & attributes to retrieve many of these parameters ...

    my %tab_links;

    my @order = ( $project_name, 'Contact Info', 'Projects', 'Previous Submissions', 'Download Template', 'Contact Us' );
    my $default = $project_name;

    if ($active) {
        ### add layer for the active submission form ####
        $home_hash{'Active Submission'} = $active;
        push( @order, 'Active Submission' );
        $default = 'Active Submission';
        ### make home link reload page if active layer exists..
        #        $tab_links{'Home'} = &Link_To( $home, 'Home' );
    }

    my $main_tabs = &define_Layers(
        -default    => $default,
        -layers     => \%home_hash,
        -format     => 'tab',
        -name       => $layer_key,
        -tab_width  => 200,
        -tab_offset => 150,
        -sub_tab    => $sub_tab,
        -order      => \@order,
        -tab_links  => \%tab_links,
        -tab_colour => '#999999',
        -off_colour => '#cccccc'
    );

    $dbc->Benchmark('generated_std_home_page');
    return $main_tabs;
}


 #####################
 sub project_list {
 #####################
    my $self = shift;
     my %args         = &filter_input( \@_ , -args=>'contact_id');
     my $contact_id   = $args{-contact_id};
     my $home         = $args{-home};
     my $account_name = $args{-account_name};
     my $session      = $args{-session};
     my $dbc          = $args{-dbc} || $self->{dbc};

     my $scope_condition = "FK_Contact__ID = $contact_id";
     if ( $dbc->LIMS_admin() ) { $scope_condition = '1'; }

     my @project_array = $dbc->Table_find( "Collaboration,Project", "Project_ID,Project_Path", "WHERE FK_Project__ID=Project_ID AND $scope_condition GROUP BY Project_ID ORDER BY Project_Name" );

     my $projects = section_heading('List of Associated Projects');
     $projects .= 'Note: If you are collaborating on a project not indicated below, please contact GSC LIMS to ensure this collaboration is recorded<P>';

     $projects .= subsection_heading('Projects:');
          
     foreach my $row (@project_array) {
         my ( $project_id, $path ) = split ',', $row;
         my $project_name = $dbc->get_FK_info( -field => 'FK_Project__ID', -id => $project_id );

         ## if specific project not chosen, simply list projects available ##
         $projects .= '<LI>' . Link_To( $dbc->homelink, $project_name, "?cgi_application=GSC_External::App&rm=Project&User=$account_name&Session=$session&Project_ID=$project_id" );
     }
     $projects .= '</UL>';

     return $projects;
 }

1;
