#!/usr/local/bin/perl
#
# This is a minimalist script that includes (optional) session tracking and login capabilities
#  and the framework for enabling MVC run modes using parameters: cgi_app + rm 
#
# The MVC framework enables this simple script to be scalable to support a large sophisticated web application
#
# It assumes the following configuration setup files:
# * RGTools::RGIO
# * LampLite modules
# 
# * optional requirements
# - database connection (requires system.cfg : DATABASE HOST LOGIN_FILE)
# - session tracking (requires system.cfg : SESSION_DIR )
# - login_required (requires system.cfg : LOGIN_FILE )
#
########################################
## Standard Initialization of Module ###
########################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../custom/";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";

use lib $FindBin::RealBin . "/../lib/perl/Core/RGTools";

########################
## Local Core modules ##
#######################
use LampLite::Login_Views;
use LampLite::DB;
use LampLite::Notification;

use RGTools::RGIO;

### Modules used for Web Interface only ###
use LampLite::Config;
use LampLite::Bootstrap;
use LampLite::HTML;
use LampLite::Build;

use LampLite::Session;
use LampLite::MVC;

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
######################################
######## Setup Options ###############
######################################
    
$| = 1;
my $path = "./..";

my $kill = $q->param('Kill PID');
if ($kill) { kill_pid($kill); exit; }  ## quick way to kill a runaway process generated from the UI ##

my ($track_sessions, $database_connection, $login_required) = (1, 1, 1);         

#################################################################################################
### Standard configuration initialization ###
#
#  Include the couple of line below in any file that requires access to configuration settings #
#
#  configuration variables will be contained within $Config->{config} 
#################################################################################################
    my $file = $0;
    $file =~s/(.+)\/(.+)$/$2/;

    my $Config = LampLite::Config->new( -bootstrap => 1, -initialize=>$FindBin::RealBin . "/../conf/$file.cfg");

############################################
## local Variables (just for readability) ##
############################################
    my $Setup = $Config->{config};
        
    my $host = $Setup->{SQL_HOST};
    my $dbase = $Setup->{DATABASE};
    my $version = ''; ##  $Setup->{version_name};
    my $custom = $Setup->{custom_version_name} || 'Core';
    my $lims_user_grp = $Setup->{lims_user_grp};
    my $session_expiry = $Setup->{session_expiry} || '8h';  ## '+8h'  
    my $mobile_expiry = $Setup->{mobile_expiry} || '1h';   ## eg '+1h'  - may specify different expiration standard for mobile devices
    
    my $root_dir = $Setup->{root_directory};
    my $login_file = "/opt/alDente/versions/" . $Setup->{root_directory} . "/conf/mysql.login";
    my $url_root_dir = $Setup->{url_root}; 
    my $login_type = $Setup->{login_type};
##########################################################
    my $Login_Views = $custom . '::Login_Views';
    my $DB = $custom . '::DB';

    eval "require $Login_Views";
    eval "require $DB";

    my $Login_User  = $custom . '::' . $login_type;
    eval "require $Login_User";

###############################
## system.cfg Variables ##
###############################
    my $web_root = $Setup->{web_root};
    my $data_root = $Setup->{data_root};
    
### Load Input parameters ###
# my $project         = $q->param('Target_Project');
# my $opentab         = $q->param('OpenTab');                ## optional tracking of open tab layer

my $rm              = $q->param('rm');
my $auto            = $q->param('Auto_Report');            ## used for direct connection (bypassing login) to read-only access page via link
my $mode            = $q->param('Database_Mode');
my $dept            = $q->param('Target_Department');

if ($mode && $Setup->{"${mode}_HOST"} ) { $host = $Setup->{"${mode}_HOST"}  }
if ($mode && $Setup->{"${mode}_DATABASE"} ) { $dbase = $Setup->{"${mode}_DATABASE"}  }

##########################################################

my $init_errors;
if ( $init_errors && @$init_errors ) {
    my $errors = Cast_List( -list => $init_errors, -to => 'UL' );
    print LampLite::Session::abort_session( "Initialization Errors", $errors );
    exit;
}

print LampLite::HTML::initialize_page(-path=>"$url_root_dir", -css_files=>$Setup->{css_files}, -js_files=>$Setup->{js_files});    ## generate Content-type , body tags, load css & js files ... ##
print $BS->open(-width=>'90%');

#################################################
### Validate Mandatory Configuration Settings ###
#################################################

my ($dbc, $output, $MVC, $db_user, $pwd);
        
## use backup host/dbase for read-only auto connects ##
if ($auto) { ( $host, $dbase, $user_id, $db_user, $pwd ) = $session->setup_auto_session( $Setup->{BACKUP_HOST}, $Setup->{BACKUP_DATABASE} ) }

# if ($database_connection) {
    my $url_params = $Setup->{url_params} || [];
    my $session_params = $Setup->{session_params} || [];
    
    $dbc = $DB->new(
            -dbase              => $dbase,
            -host               => $host,
            -password           => $pwd,
            -session            => $session,
            -config             => $Setup,
            -session_parameters => $session_params,
            -url_parameters     => $url_params,
            -login_table        => $login_type,
            -connect            => 0,
            -defer_messages     => 1,
            -sessionless => !$track_sessions,
            -login_file => $login_file,
        );

#    my $Build = new LampLite::Build();
#    my ($fs_ok, $message) = $Build->filesystem_check(-dbc=>$dbc, -config=>$Setup, -create=>['data_root', 'web_root'], -file=>$FindBin::RealBin . '/../conf/directories.yml');

    #####################
    ## define homelink ##
    #####################
    ## move to other module ##
    my $domain        = $Setup->{URL_domain};
    my $custom        = $Setup->{custom_version_name};
    
    my $home = "$domain$url_root_dir/cgi-bin/$file";    
    
    my $mobile;
    if ($file =~/scanner/i) { $dbc->config('screen_mode', 'mobile'); $mobile = 1; }
    else { $dbc->config('screen_mode', 'desktop') }
    
    $dbc->config('Target_Department', $dept);
    #####################
#}

my ($session, $User, $sid, $logged_in, $username);
#if ($track_sessions) {
    #######################################
    ## Define and Load Interface Session ##
    #######################################
    my $session_dir = $dbc->config('sessions_web_dir');
    
    my $ok = try_system_command("chmod 770 $session_dir/$root_dir/$dbase");
    create_dir( "$session_dir/", "$root_dir/$dbase", 770 );
    
    $session = new LampLite::Session( 'id:md5', $q, { Directory => "$session_dir/$root_dir/$dbase" } );
    $session->param( 'PID', $$ );

    $username        = $q->param('User') || $session->param('user');
    $sid = $session->validate_session();  

    $dbc->config('CGISESSID', $sid);
   
    foreach my $param (@{$url_params}, @{$session_params}) {
        my $set = $q->param($param);
        if ($set) { $dbc->config($param, $set) }
    }
    $dbc->homelink($home); ## url_parameters are appended automatically 
 
    ## check for expired session ##
          
#    `CHGRP -R $lims_user_grp $session_dir/$root_dir`;        ## ensure directories owned by lims group in case run as single user ##
#    `CHMOD 660 $session_dir/$root_dir/$dbase/cgisess_$sid`;

    
    $logged_in = $session->logged_in();
#}
    $dbc->{session} = $session;

$dbc->Benchmark('Start');
my ($login_view, $header_generated);
if ($dbc && $sid && $logged_in ) {   
    ( $user_id, $db_user, $pwd, $host ) = ( $session->param('user_id'), $session->param('db_user'), $session->param('db_pwd'), $session->param('host') );
    $dbc->connect( -user => $db_user, -pwd => $pwd );

    $User = $Login_User->new( -dbc => $dbc, -id => $logged_in, -initialize => 1 );    ## define current user settings
    &initialize_dbc_configs();                                                            ## define initial configuration settings for url_parameters & homelink (eg CGISESSID, Database_Mode, Target_Department)

    $MVC = new LampLite::MVC( -dbc => $dbc, -params => { dbc => $dbc }, -call => 1);
    
    $output = $MVC->{output};
}
else {
    if   ( $login_type =~ /contact/i ) { $db_user = 'collab' }
    else                               { $db_user = 'login' }
        
    if ($dbc) { $dbc->connect( -user => $db_user, -pwd => $pwd ) }
    if ( $rm eq 'Log In' ) {
        if ( $login_type =~ /contact/i ) {
            ## Connecting as Contact through LDAP - no need to reconnect as new user ##
            &initialize_dbc_configs();    ## define initial configuration settings for url_parameters & homelink (eg CGISESSID, Database_Mode, Target_Department)
            $user_id = $dbc->get_db_value( "SELECT Contact_ID FROM Contact WHERE Canonical_Name = '$username'" );
        }
        elsif ( $username eq 'Guest' ) {
            $user_id = $dbc->get_db_value(-sql=>"SELECT ${login_type}_ID FROM ${login_type} WHERE ${login_type}_Name = 'Guest'");
        }
        else {
            ## Once password is confirmed, reconnect to database as applicable db_user ##

            ($db_user) = LampLite::DB_Access::get_DB_user( -dbc => $dbc, -user => $username);    ## Reconnect to applicable database as new user ...

            if ($db_user) { $dbc->connect( -user => $db_user, -pwd => $pwd, -force=>1) }
            else          { $Login_Views->relogin( $dbc, 1 ) }
        }

        $MVC = new LampLite::MVC( -dbc => $dbc, -params => { dbc => $dbc }, -call => 1);    ## Calls login run mode which should reset dbc & user
        $user_id ||= $dbc->config('user_id');

        $User = $Login_User->new( -dbc => $dbc, -id => $user_id, -initialize => 1 );         ## define settings based upon logged in user ##

        &initialize_dbc_configs();                                                           ## define initial configuration settings for url_parameters & homelink (eg CGISESSID, Database_Mode, Target_Department)
        $output = $MVC->{output};
    }
    elsif ($login_required) {
        &initialize_dbc_configs();                                                           ## define initial configuration settings for url_parameters & homelink (eg CGISESSID, Database_Mode, Target_Department)
        ## Not Logged in, and not logging in... go to login page again ... ##
        if ($mobile) { $dbc->{screen_mode} = 'mobile' }
        $Login_Views->relogin( -dbc => $dbc );
    }
}

if ( !( $dbc && $dbc->{connected} ) && $database_connection) {
    ## Failed to establish initial database connection (with generic login user) ##
    print $BS->error("FAILED TO CONNECT $db_user TO $dbase DATABASE ON $host using login file: $login_file");
    $login_view->leave($dbc);
}

if ( $MVC && $MVC->{reload_cgi_app} && $MVC->{reload_rm} ) {
    ## (generates page from reloaded MVC parameters when user logs in again from expired session) ##
    $output = $MVC->_call_sub_MVC( -dbc => $dbc, -sub_cgi => $MVC->{reload_cgi_app}, -rm => $MVC->{reload_rm}, -display => 1 );
}

if ( $dbc->mobile() ) { $expiry = $mobile_expiry || $session_expiry }
else { $expiry = $session_expiry }

$session->expire($expiry);    ## set sessions to expire after 2 hours
$session->flush();
##############################
#### Generate Page Output ####
##############################

if ($output) {
    if ( $ENV{CGI_APP_RETURN_ONLY} ) { print $output }
}
elsif ( $MVC->{secondary_output} ) {
    ## Generates page from reloaded input parameters ... in this case, it needs to be printed out since it is not automatically generated from the app ##
    print $MVC->{secondary_output};
}
else {
    my $ref = ref $Login_Views;
    my $branched = $Login_Views->MVC_exceptions( -dbc=>$dbc, -sid=>$sid );    ## phase out gradually...customize to only run in GSC local mode ... 
    if ( ! $branched) { 
        if ( $dbc->session->logged_in() ) {
            my $header;
            if (!$header_generated) { print ".. GEN .."; $header = $login_view->header( -dbc => $dbc ) }

            &home( 'main', -header => $header, -case => $case, -open_tab => $opentab, -exit=>0);
        }
        else {
            ## optional home page for guest (if applicable)
            print $Login_Views->guest_home_page();
        }
    }
}

if ($track_sessions) { store_Session($dbc) }

_close_page($dbc);    ## exits here
exit;

#############################
sub initialize_dbc_configs {
#############################
#    $dbc->config( 'CGISESSID',     $sid );
    $dbc->config( 'Database_Mode', $mode );
    $dbc->config( 'installation',  $custom );
    
    my $images_dir = "/$url_root_dir/images/";
    my $logo = $dbc->config('images_url_dir') . "/$custom.logo.png";
    $dbc->config( 'icon', $logo);
    
    if ($mobile) { 
        $dbc->{screen_mode} = 'mobile';
#        $dbc->config('screen_mode','mobile');
    }

    $dbc->config('screen_mode', $Setup->{screen_mode});
#    $dbc->config('User', $User);

    if ( $login_type =~ /Contact/i ) {
        $dbc->config( 'Target_Project', $project );
    }
    else {
        $dbc->config( 'Target_Department', $dept );
    }

    $homelink = $dbc->homelink($Setup->{home});    ## establish homelink parameter and save as session attribute (this method automatically appends url_parameters to $home)
    
    $login_view = $Login_Views->new( -dbc => $dbc );
 
    if ( $User && ! $dbc->mobile() ) {        
        my $tool_tip_disable = $User->get_Settings( -setting => 'DISABLE_TOOLTIPS', -scope => 'Employee' );
        if ( $tool_tip_disable =~ /on/i ) { $ENV{DISABLE_TOOLTIPS} = 1 }
    }
    
    my $user = $dbc->session->param('user');
    if ( $user ) {
        print $login_view->generate_Header();    ## header needs to be generated after user is identified since user information is included in the header ##
        $header_generated++;
    }
    elsif ( $rm eq 'Log In' ) { }
    else { 
        print $login_view->generate_Header(); 
        $header_generated++;
    }
    
#    print $login_view->session_details();

    $dbc->flush_messages();
    return 1;
}

#
# Close page - mirrors page initialization (_generate_Header)
#"
##################
sub _close_page {
##################
    my $dbc            = shift;
    my %args           = @_;
    my $include_footer = defined $args{-include_footer} ? $args{-include_footer} : 1;

    $login_view ||= $Login_Views->new( -dbc => $dbc );

    print $BS->close($dbc);

    my $desktop_footer = "<a href='http://www.bcgsc.ca'><img src='/$path/images/png/aldente_footer.png' width=300></img></a>";

    if ($include_footer) {
        my $footer = qq(<center></center>$desktop_footer</div>\n) if !$dbc->mobile();
        print $login_view->footer( -footer => $footer );
    }
    

    my $Session = $dbc->session();
    if ( $Session && $Session->param('session_dir') && $Session->param('session_name') ) {
        my $dir  = $Session->param('session_dir');
        my $name = $Session->param('session_name') . '.sess';
        $Session->store_Session_messages("$dir/$name");
    }

    $login_view->leave($dbc);
}

############
sub leave {
############
    my $db = shift || $dbc;
    $login_view ||= $Login_Views->new( -dbc => $db );
    $login_view->leave($db);
}

####################
sub store_Session {
####################
    my $dbc = shift;

    my $Session = $dbc->session();
    $track_sessions = 1;

    if ( $track_sessions && $Session->param('user') ) {
        $Session->store_Session( -dbc => $dbc );
    }
    return 1;
}

#
# Customized default home page
#
# Return: page output
################
sub home {
################
    my %args     = filter_input( \@_, -args => 'option,open_tab' );
    my $option   = $args{-option};
    my $open_tab = $args{-open_tab} || $q->param('OpenTab');
    my $header   = $args{-header};
    my $quiet    = $args{-quiet};
    my $exit     = $args{ -exit };
    my $case     = $args{ -case };

    my $quotes = 0;

    $login_view ||= $Login_Views->new( -dbc => $dbc );

    my ( $table, $id );
    if ( $q->param('HomePage') ) {
        $table = $q->param('HomePage');
        $id    = $q->param('ID');
    }
    elsif ( $dbc && $dbc->session &&  $dbc->session->homepage() =~ /^(\w+)=([\w\,]+)$/ ) {
        $table = $1;
        $id    = $2;
    }

    if ( $table ) {        
        my $scope = $custom;
        
         $table =~s/\bPlate\b/Container/;  ## replace container with Plate ... need to make more generic... 
         my $class = $scope . '::' . $table;
        
        ## Go to standard home page (deprecate non_MVC AND Button_Options HomePage functionality) ##
        if ( my $Loaded = $dbc->dynamic_require($table, -id=>$id, -construct=>1) ) {

            $Object = $Loaded;
        }
        elsif ( RGTools::RGIO::module_defined($class) ) { 
            my $ok    = eval "require $class";
            $Object = $class->new( -dbc => $dbc, -id => $id );
        }
        elsif ($dbc->table_loaded($table)) { 
            $Object = SDB::DB_Object->new(-dbc => $dbc, -table=>$table, -id=>$id);
        }
        else {
            $dbc->error("No Home Page for $table class");
            return;
        }
        $dbc->message("GENERATE HOME PAGE");
        my $page = $Object->View->std_home_page( );    ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##
        print $page;
    }
    else {
        ## Go to default home page ##
        print $login_view->home_page();
    }

    if ($exit) {
        $login_view->leave($dbc);
    }
    return;
}

############
sub abort {
############
    my $message = shift;
    
    print $BS->error($message);
    print $BS->close($dbc);
    
    exit;
}

###############
sub kill_pid {
###############
    my $pid = shift;
    print "Content-type: text/html\n\n\n";
    print "Killing process: $pid.\n\n<P>";
    if ($pid =~/^\d+$/) {
        my $ok = `kill -9 $pid`;    
        print "KILLED $pid\n\n<P>$ok\n\n<P>Aborting\n\n";
    }
    else {
        print "Could not identify PID: $pid ? (set parameter Kill=PID)\n\n";
    }
    exit;
    
}

1;
