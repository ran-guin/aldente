###################################################################################################################################
# SDB::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
###################################################################################################################################
package SDB::Login_Views;

use base LampLite::Login_Views;

use strict;
## Standard modules ##
use Time::localtime;

## Local modules ##

## SDB modules
use LampLite::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;

use LampLite::Bootstrap;

my $q = new LampLite::CGI;
my $BS = new Bootstrap;

my ( $VOLUME, $FILE_DIR, $FILE_NAME ) = File::Spec->splitpath(__FILE__);

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
    my $dbc      = $args{-dbc} || $self->dbc;  #$self->param('dbc');
    my $dest_url = $args{-url};
    my $reload   = $args{-reload};
    my $expired  = $args{-expired};
    my $append   = $args{-append};
    my $database_mode = $args{-database_mode};
    
    $args{-title} ||= 'Login Page';
    $args{-app} ||= 'SDB::Login_App';

    my @login_extras;
    
    my $hidden;
    ## Prompt for Database modes ##
    if ($database_mode) { 
        ## specified mode ##
        $hidden = $q->hidden(-name=>'Database_Mode', -value=>$database_mode, -force=>1);
     }
     else {
         my $database_modes_prompt = $self->database_modes();
         if ($database_modes_prompt) { push @login_extras, ['Database Mode:', $database_modes_prompt] }
     }
    
    if ($dest_url) {
        $dbc->message("Please provide your password to login to the system.");
    }
    else {
        $dest_url = $SDB::CustomSettings::homefile;    ## could also use 'url' (?)..
    }
    
    if ($append) { 
        if (ref $append ne 'ARRAY') { print HTML_Dump $append, 'format' }
        else { push @login_extras, @$append }
    }
    
    if (@login_extras) { unshift @login_extras, ['', '<hr>'] }

    push @login_extras, ['', $hidden];
    my $page = $self->SUPER::display_Login_page(%args, -append=>\@login_extras);
    
    return $page;
}

###############
sub relogin {
###############
    my $self = shift;
    my %args         = filter_input( \@_, -args => 'dbc,reload' );

    return $self->SUPER::relogin(%args);
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

     my $quiet = 1;
     my $return_page;
     if ( $option =~ /(main|default|1)/i ) {

#         if ( $dbc->mobile() ) { return alDente::Scanner::home_page($dbc) }

         ### Main Home Page ###
         $dbc->connect_if_necessary();
         my $Current_Department = $q->param('Target_Department') || $dbc->session->param('Target_Department') || $dbc->config('Target_Department') || $dbc->session->param('home_dept') || $dbc->config('home_dept') ;
         my $open_tab = '';
         $dbc->Benchmark('web_gohome');

         my ($file, $mod) = $self->get_dept_module($Current_Department, $dbc->config('custom_version_name'));
         eval "require $mod";
         
         my $Dept = $mod->new(-dbc=>$dbc);

         $return_page .= $Dept->home_page();

         $dbc->Benchmark('web_wenthome');
     }

     if ( !$quiet ) {
         print $return_page;
     }

     return $return_page;
 }
 
##########################################################################################################################
#####  SMALL FUNCITONS
##########################################################################################################################

#############################################################
sub host_popup {
#############################################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->dbc;  ## param('dbc');
    my $name = $args{-name} || 'Host Choice';
    my @options;
    my @config_hosts = qw( BETA_HOST TEST_HOST BACKUP_HOST PUBLIC_HOST DEV_HOST PRODUCTION_HOST);

    #	require alDente::System;
    #	my $sys = new alDente::System ();
    #	my @config_databases = $sys -> get_all_databases();
    #	print HTML_Dump \@config_databases;
    ########
    #		SHOULD BE REPLACED WITH FUNCTION IN SYSTEM>PM TO GET ALL AVAILABLE DATABASES
    #######
    foreach my $host (@config_hosts) {
        my $host_name = $dbc->config($host);
        if ( !( grep /^$host_name$/, @options ) ) {
            push @options, "$host_name";
        }
    }

    my $database = $q->popup_menu(
        -name    => $name,
        -values  => [ sort @options ],
        -default => $dbc->config('DATABASE'),
        -force   => 1
    );
    return $database;

}

#############################################################
#
#
#
#############################################################
sub database_modes {
#############################################################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->dbc;
    my $name    = $args{-name} || 'Database_Mode';
    my $default = $args{-mode} || $dbc->config('default_mode');
    my @options;

    my @db_modes = qw(TEST);

    my $Description = {
        'PRODUCTION' => 'Production Database',
        'TEST'       => 'Copy of Production Database regenerated daily for testing purposes',
        'BETA'       => 'Beta database (schema adjusted as required for next upgrade)',
        'CORE'       => 'Skeleton database - used by admins for testing baseline functionality',
        'DEV'        => 'Development database (schema adjusted as required to include latest committed changes)',
    };

    if ( $0 =~ /versions\/production\// ) {
        ## only allow access to Production database from production code version ##
        @db_modes = ( 'PRODUCTION', @db_modes );
    }
    elsif ( $default eq 'DEV' ) {
        ## add development test modes for non-production code ##
        push @db_modes, ( 'CORE', 'BETA', 'DEV', 'PRODUCTION' );
    }
    else {
        push @db_modes, ( 'BETA', 'DEV', 'PRODUCTION' );
    }
    #######
    foreach my $mode (@db_modes) {
        if ($mode) { $mode = uc($mode) }

        my $db_name = $dbc->config("${mode}_DATABASE");
        if ( !( grep /^$db_name$/, @options ) ) {    ## && $URL_version =~ /(Test|Beta|Dev)/i ) {
            push @options, $mode;
        }
    }

    if ( $q->param('Database') ) {
        my $passed_DB = $q->param('Database');
        unless ( grep /^$passed_DB$/, @options ) {
            push @options, $passed_DB;
        }
    }

    my $database;
    my $onclick;
    foreach my $option (@options) {
        my $checked = '';
        if ( $option eq $default ) {
            $checked = 'CHECKED';
        }
        if   ( $option eq 'PRODUCTION' ) { $onclick = $self->{activate_printers_js} }
        else                             { $onclick = $self->{deactivate_printers_js} }

        $database .= Show_Tool_Tip( 
                        $q->radio_group( -name => $name, -value => $option, -default => $default, -onclick => $onclick), 
                        $Description->{$option} 
                    );
        $database .= "<BR>";
    }
    return $database;

}

#
# Custom header definition
#
# utilizes local methods below to generate sections of header for: user / dept / help etc...
#
#
# Return: Header string
####################
sub header {
####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $left   = $args{-left};
    my $right  = $args{-right};
    my $centre = $args{-centre};
    my $icon     = $args{-icon}; ##  || $dbc->config('icon');
    my $text     = $args{-text};    ## text title on header (optional)
    my $menu     = $args{-menu};                           ## for now mobile does not include menu ##
    my $external = $args{-external};
    my $environment = $args{-environment} || 'lab';
    my $pre_menu = $args{-pre_menu};                  ## optional line above menu ##
    my $post_menu = $args{-post_menu};                 ## only shown on desktop mode (optional line after menu)

    if ($external) { $environment = 'external' }
    
    if ($icon && ($icon !~ /SRC=/i) ) { 
        my $local_homelink = $dbc->homelink(-clear=>['Target_Department']);
        $icon = Show_Tool_Tip("<A Href='$local_homelink'><IMG SRC='$icon'  class='logo' ></A>\n", "Go back to default Home Page", -placement=>'bottom');
    }
    
    my $mobile;
    if ( $dbc->config('screen_mode') =~ /mobile|tablet/i ) { $mobile = 1 }

    my $scope;
    if   ($external) { $scope = 'Project' } 
    else             { $scope = 'Department' }

    if ( !defined $left ) {
        ### Default header left ###
        $left = [ $self->_home_header( $scope, $mobile) ];
    }

    if ( !defined $centre ) { $centre = $icon }
        ### Default header centre ###        
        if ( $dbc->config('Database_Mode') && $dbc->config('PRODUCTION_DATABASE') && $dbc->config('dbase') && $dbc->config('dbase') ne $dbc->config('PRODUCTION_DATABASE') ) {
            $text .= '<BR>' . Show_Tool_Tip( "<center><Font color='red'>Non-Production Mode</Font>", "Current Database is <B>Non_Production</B></center>", -placement => 'bottom' );
        }

        if ($text) { $centre = qq(<div class='pull-left col-md-6'>$centre</div><div class='pull-right col-md-6 visible-lg'>$text</div>) }
     
    my $guest = ( $dbc->config('user') eq 'Guest' );
    
    if ( !defined $right ) {
        ### Default header right ###
        $right = [ $self->_dept_header($scope), $self->_user_header( $scope, $mobile ), $self->_help_header() ];
    }
    
    my $id = int( rand(1000) );
    my $position = 'top';
    ## Generate Browser Update Warning if applicable ##
    my $browser_ok = LampLite::HTML::browser_check( -dbc => $dbc, -required => { 'Firefox' => 24 }, -recommended => { 'Firefox' => 24 } );    ## adjust required/recommended versions as required...
    if ( !$browser_ok ) { return $self->_old_browser_header( $scope, $menu ) }

    my $dept = $dbc->config('Target_Department');      
    my (%custom_icon_map, %icon_groups);
    
    if (! defined $menu) {
        my $menu_object = $dbc->dynamic_require('Menu', -dbc=>$dbc);
        my $Menu = $menu_object->new(-dbc=>$dbc);

        %custom_icon_map = $Menu->get_Icons( -dept=>$dept);
        %icon_groups = $Menu->get_Icon_Groups(-dept=>$dept);
        
        if (%custom_icon_map || %icon_groups) {      
            my ( $icons, $icon_class ) = $self->page_icons( -dept => $dept, -width => 30, -custom_icons => \%custom_icon_map, -custom_icon_groups=>\%icon_groups);  
           $menu = $self->Menu(-dbc=>$dbc, -sections => $icons, -limit => 20, -off_colour => 'white', -id => 'icons', -class => $icon_class, -inverse=>1);
        }
    }

    my $header;
    if ($mobile) {
        $header =  $BS->start_header( -name => 'collapseHeader', -position => $position ) 
        . $BS->header( 
            -centre => $centre,
            -left =>  $left,
            -right => $right,
            -style => "margin:0px; background-color:white; border-color:white;",);

        if ( !$guest && ( $pre_menu || $menu || $post_menu) ) {
            $header .= $BS->row( [$pre_menu] ) if $pre_menu;
 #           $header .= $BS->end_dynamic_header();
 #           $header .= $BS->menu( $menu, -toggle => 'Menu:', -inverse => 1, -grayscale => 1, -style => "margin:inherit;");
        }
        $header .= $BS->end_header();
    }
    else {
        $header = $BS->start_header( -name => 'collapseHeader', -position => $position ) 
        . $BS->header( 
            -centre => $centre, 
            -left => $left, 
            -right => $right, 
            -style => "margin:0px; background-color:white; border-color:white;", -span => [ 1, 7, 4 ] );
            
        if ( !$guest && ( $pre_menu || $menu || $post_menu) ) {
            $header .= $BS->row( [$pre_menu] ) if $pre_menu;
            $header .= $BS->end_dynamic_header();
            $header .= $BS->menu( $menu, -toggle => 'Menu:', -inverse => 1, -grayscale => 1, -style => "margin:inherit;") if $menu;
            $header .= $BS->row( [$pre_menu] ) if $post_menu;
        }
         $header .= $BS->end_header();
    }
    return $header;
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

#############
sub footer {
#############

return;    
}

#
# Generates the Home / Icon for the primary header
#
# Return: HTML for Home / Icon
####################
sub _home_header {
####################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'scope,mobile' );
    my $scope  = $args{-scope};
    my $mobile = $args{-mobile};
    my $style  = $args{-style};
    my $icon   = $args{-icon};
    my $dbc    = $self->{dbc};

    if ( !$mobile ) { $style .= " padding-top:15px" }    ## adjust spacing on desktop ...

    my $home = $BS->icon( 'home', -size => '2x', -style => $style );
    $home = Link_To( $dbc->homelink(), $home );

    if ($mobile || !$icon) {
        return $home;
    }
    else {
        return $BS->flexbox( [ $home, $icon ] );
    }
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
    }
    elsif ( $scope =~ /project/i ) {
        $depts = $dbc->get_local('projects');
        my $custom = $dbc->config('custom');
        $extra_link_parameters = "&cgi_application=${custom}::App&rm=Project";
    }

    my $param = 'Target_' . $scope;
    my $Current_Department = $dbc->config( $param );

    my $current_dept;
    if ( $dbc->mobile() ) {
        my $dept = $Current_Department;
        $dept =~ s/_/ /g;
        $current_dept = "<div style='font-size:12px;'><B>$dept</B>" . $BS->icon('caret-down') . "</div>";
    }
    else {
        $current_dept = Show_Tool_Tip( "$prompt: <B>$Current_Department</B> " . $BS->icon('caret-down'), "Select $prompt", -placement => 'bottom' );
    }

    my @depts;
    my $local_homelink = $dbc->homelink( -clear => [ 'Target_' . $scope ] );
    my $custom = $dbc->config('custom_version_name');
    
    if ( $depts && $depts->[0] ) {
        foreach my $dept ( sort @$depts ) {

            # Needed for these department entries in DB:
            #
            # - Site Admin
            # - Prostate Lab

            ( my $dept_with_underscore = $dept ) =~ s/\s+/_/;

            my $dept_file = File::Spec->catfile( $FILE_DIR, "../../Departments/$custom/$dept_with_underscore", "Department.pm" );
            
            if ( -e $dept_file ) {
                my $link = Link_To( $local_homelink, $dept, "$extra_link_parameters&Target_$scope=$dept" );
                push @depts, $link;
            }
        }
    }
    else { @depts = ( '-- No Options Available --', "-- Contact LIMS to Enable Access to ${prompt}s as required --" ) }

    if (int(@depts) == 1) { return }  ## no options so no need to show department dropdown ## 
    
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

    my $dbc        = $self->{dbc};
    my $pg         = $dbc->session->user_setting('PRINTER_GROUP');
    my $user_label = $dbc->config('db_user') . '@' . $dbc->config('dbase') . '.' . $dbc->config('host');
    my $access     = $dbc->session->param('access');

    my @user_options;    ## = ('<B>' . $dbc->config('user') . '</B> @' . $dbc->config('dbase'), "<U><B>$user_label</B></U>", "[$pg]", "Access: " . $access);

    my $user  = $dbc->config('user_name');
    my $dbase = $dbc->config('dbase');

    my $dm = $dbc->config('Database_Mode');

    if ( $scope =~ /department/i ) {
        if ($mobile) {
            my $mode;
            if ( $dbc->config('Database_Mode') && $dbc->config('Database_Mode') ne 'PRODUCTION' ) { $mode = '[' . $dbc->config('Database_Mode') . ']' }    ## only show for non-production modes...

            $user = "<span>\n" . "<B>$user</B> " . $BS->icon('user') . ' ' . $BS->icon('caret-down') . "<BR>$mode\n</span>\n";
        }
        else {
            $user = $BS->icon('user') . " - <B>$user</B> \@$dbase" . $BS->icon('caret-down');
        }

        push @user_options, (
            Link_To( $homelink, 'Change Password', "&cgi_application=LampLite::Login_App&rm=Change Password" ),

            # Link_To($homelink,'Preferences',"&cgi_application=SDB::Session_App&rm=Set Preferences"),
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

    push @user_options, Link_To( $dbc->homelink( -clear => 1 ), 'Logout', "&Relogin=1" );

    my $alternate_version = $dbc->homelink();
    my $alternate;
    
    my ($desktop, $mobile) = ('alDente.pl', 'scanner.pl');
    if ($dbc->mobile() ) {
        $alternate_version =~s/\/$mobile/\/$desktop/;
        $alternate = 'desktop';
    }
    else {
        $alternate_version =~ s/\/$desktop/\/$mobile/;
        $alternate = 'mobile';
    }
    push @user_options, '<hr>';
    push @user_options, Link_To( $alternate_version, "Switch to $alternate version" );

    return { $user => \@user_options };
}

#
# Generates the Help label with dropdown options
#
# Return: hash (for displaying as parameter for $BS->menu() )
###################
sub _help_header {
###################
    my $self  = shift;
    my $scope = shift;
    my $dbc   = $self->{dbc};

    my $help_icon = Show_Tool_Tip( $BS->icon('question-circle'), "Help Options", -placement => 'bottom' );

    my $homelink = $dbc->session->param('homelink') || $dbc->homelink();
    my $site_map = $homelink;

    $site_map =~ s/alDente.pl/Site_Map.pl/;

    return { $help_icon => [ Link_To( $site_map, 'Site Map' ), Link_To( $homelink, 'Manual', '&cgi_application=SDB::Help_App&rm=Help' ) ] };
}

#############################################################
#
# Move to Lab scope ... 
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
    
    my $file = $dbc->config('custom_version_name') || 'alDente.pl';
    
    my $Target = {
        'Production' => "http://$master$domain/SDB/cgi-bin/$file?Database_Mode=PRODUCTION",
        'Test' => "http://$master$domain/SDB_test/cgi-bin/$file?Database_Mode=TEST",
        'Alpha' => "http://$dev$domain/SDB_alpha/cgi-bin/$file?Database_Mode=DEV",
        'Beta' => "http://$master$domain/SDB_beta/cgi-bin/$file?Database_Mode=BETA",
        'Development' => "http://$dev$domain/SDB_dev/cgi-bin/$file?Database_Mode=DEV",    
    };

    my @versions = qw(Production Test Alpha Beta Development);
    foreach my $ver (@versions) {
        my $URL = $Target->{$ver};

        $other_versions .= "<li> <a href='$URL'>$ver version</a></li>\n";
    }
    return $other_versions;
}

1;
