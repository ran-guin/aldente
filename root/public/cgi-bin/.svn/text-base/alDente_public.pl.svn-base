#!/usr/local/bin/perl

use strict;

use FindBin;

# use alDente tools
CONFIG_ALDENTEPATH : use lib '/home/aldente/public/WebVersions/Production/lib/perl';
# use external tools
CONFIG_ALDENTEIMP : use lib '/home/aldente/public/WebVersions/Production/lib/perl/Imported';
# use LDAP
CONFIG_LDAPPATH : use lib '/home/aldente/public/WebVersions/Production/lib/perl/Imported/LDAP';

use CGI qw(:standard);
use CGI::Carp('fatalsToBrowser');
use Digest::MD5;
use Data::Dumper;
use Net::LDAP;
use XML::Dumper;

### Submission modules
use Submission::Globals; 
use Submission::Public;
use Submission::Redirect;

### alDente modules
use alDente::Web;
use SDB::DBIO;
use SDB::HTML;
use SDB::Session;
use SDB::CustomSettings;
use RGTools::RGIO;

use vars qw($homelink $Connection $submission_dir $URL_version);
 
my $bindir = $FindBin::RealBin;

CONFIG_CONFIGFILE : my $config_file = "/usr/local/apache/htdocs/collab_submission/conf/config.conf";

## load config file
my %config = %{&Submission::Public::load_Config(-file=>"$config_file")}; 

# Set useful global variables from config
my $SESS_DIR = $config{'SESSION_DIR'};
my $LDAP = $config{'LDAP'};
my $JS_DIR = $config{'JAVASCRIPT'};
my $CSS_DIR = $config{'CSS'};
my $homelink = $config{'HOMELINK'};
my $project_path = $config{'PUBLIC_PROJECT_DIR'};
my $base_ext_path = $config{'BASE_EXT_PATH'};
my $image_dir = $config{"IMAGE_DIR"};
my $dbase = $config{"DATABASE"};
my $host = $config{"HOST"};
my $cgi_root = $config{"CGI_ROOT"};

my $logged_in = 0;

# initialize js 
my $js = &Submission::Public::gen_javascript(-js_dir=>$JS_DIR,-js_files=>"SDB.js,alDente.js,DHTML.js,Prototype.js,FormNav.js,json.js,alttxt.js,calendar.js"); 
my $js_str = '';
foreach my $elem (@{$js}) {
    $js_str .= $elem;
}

# initialize css and pragmas
my $css = &Submission::Public::gen_css(-css_dir=>$CSS_DIR,-css_files=>"colour.css,links.css,style.css,common.css,FormNav.css,calendar.css");
#my $css = &Submission::Public::gen_css(-css_dir=>$CSS_DIR,-css_files=>"ext_style.css");
my $css_str = '';
# <CONSTRUCTION> Pragmas. Move into conf file
$css_str .= "\n<META HTTP-EQUIV='Pragma' CONTENT='no-cache'>\n";
$css_str .= "\n<META HTTP-EQUIV='Expires' CONTENT='-1'>\n";
foreach my $elem (@{$css}) {
    $css_str .= $elem;
}

my $login_messages;
my $cookie_ref;

# grab all assigned cookies
my %cookie_values = %{&Submission::Public::retrieve_cookies(-name=>"alDente_collab:user,alDente_collab:name,alDente_collab:email,alDente_collab:session_id")};

# check if user is trying to log out
if (param('Log Out')) {
    # wipe out all cookie information
    $cookie_ref = &alDente::Web::gen_cookies
	(
	 -names=>['alDente_collab:user','alDente_collab:name','alDente_collab:email','alDente_collab:session_id'],
	 -values=>["","","",""],
	 -expires=>["-1d","-1d","-1d","-1d"]
	 );
    $logged_in = 0;
}
# check if user is trying to log in
elsif (param('Log In')) {
    $user_name = param('User');
    my $password = param('Password');
    # do taint checking! <CONSTRUCTION>
    
    my $retval = &Submission::Public::authenticate_user_LDAP(-server=>$LDAP,-user=>$user_name,-password=>$password);
    
    # if defined, then user can log in
    if ($retval) {
	# record cookie 
	($collab_name,$collab_email) = @$retval;
	$cookie_ref = &alDente::Web::gen_cookies(-names=>['alDente_collab:user','alDente_collab:name','alDente_collab:email'],
						       -values=>["$user_name","$collab_name","$collab_email"],
						       -expires=>["+1d","+1d","+1d"]);
	$logged_in = 1;
    }
    else {
	$login_messages .= &Views::Heading("<B>Authentication Failed for $user_name ! Invalid username or password</B>","bgcolor='#CC0000' align='center'");
    }
}
# check if the user has a cookie
elsif ($cookie_values{"alDente_collab:user"}) {
    # get cookie value
    $user_name = $cookie_values{"alDente_collab:user"};
    $collab_name = $cookie_values{"alDente_collab:name"};
    # check the password hash against the collaborator password <CONSTRUCTION>
    $logged_in = 1;
}

# initialize the connection object
my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>"collab_user",-password=>"collab_user",-connect=>0);
$dbc->connect();
my $include_headers;
if ($URL_version !~ /production/i) {
    $submission_dir .= '/test';
    $include_headers = 'Contact,HostInfo';
}

my $topbar = &alDente::Web::show_topbar(-include=>$include_headers,
					-image_dir=>"$image_dir",
					-about_link=>"http://www.bcgsc.ca",
					-contact_link=>"http://www.bcgsc.ca",
					-center_link=>'http://www.bcgsc.ca',
                                        -dbc=>$dbc,
                                        );

unless ($logged_in) {
    # ask user to log in 
    # start header and html
    print &alDente::Web::Initialize_page(-topbar=>$topbar,-cookie_ref=>$cookie_ref,-css_pragma_header=>$css_str,-java_header=>$js_str);
    
    &Submission::Public::show_login_form(-login_messages=>$login_messages,
					 -title=>"<B>Public Access page to GSC for Collaborators</B>"
					 );
    
    my $botbar = &alDente::Web::show_botbar(-image_dir=>"$image_dir",-center_link=>'http://www.bcgsc.ca');

    print &alDente::Web::unInitialize_page(-botbar=>$botbar);
    print end_html();
    $dbc->disconnect();
    exit;
}

# check if session is already stored
$sess_obj = undef;
my $session_id = undef;
if ($cookie_values{"alDente_collab:session_id"}) {
    $session_id = $cookie_values{"alDente_collab:session_id"};
    $sess_obj = new SDB::Session(-dbc=>$dbc,-session_id=>$session_id,-user=>$user_name,-user_id=>$user_name,-load=>1,-session_dir=>$SESS_DIR);
}
else {
    # define new session
    $sess_obj = new SDB::Session(-dbc=>$dbc,-user=>$user_name,-user_id=>$user_name,-session_dir=>$SESS_DIR,-generate_id=>1);
    if ($user_name) {
        $session_id = $sess_obj->session_id();
        my $cookie_sess = &alDente::Web::gen_cookies(-names=>'alDente_collab:session_id',
                                                           -values=>"$session_id",
                                                           -expires=>'+1d');
        push (@{$cookie_ref}, @{$cookie_sess});
    }
}

# start header and html
print &alDente::Web::Initialize_page(-topbar=>$topbar,-cookie_ref=>$cookie_ref,-css_pragma_header=>$css_str,-java_header=>$js_str,-include=>'null');

#$home .= "?User=$user_name";
$homelink .= "?User=$user_name";

## generate title bar for top of page.. ##
my $title_bar = &Views::Heading("$collab_name ($user_name)");
#print &vspace(5) . &Views::Heading($title_bar,"bgcolor='lightblue'");

# check the redirection branches
my $redirected = &Submission::Redirect::redirect(-dbc=>$dbc,-config=>\%config,-cookies=>\%cookie_values);
#\print "returned -> $redirected";

if (param('DBUpdate') && !$contact_id) {
    ($contact_id) = &Table_find($dbc,"Contact","Contact_ID","WHERE Canonical_Name='$user_name'");
} 

if($contact_id) {
	# if not redirected, then show welcome page
	if ($redirected) {
		    print &Submission::Public::title_bar(-home=>$homelink,-dbc=>$dbc,-user_name=>$collab_name,-contact_id=>$contact_id,-project_path=>$project_path,-config=>\%config,-layer_key=>'proj',-sub_tab=>$title_bar,-active=>$redirected,-img_dir=>$image_dir); 
	} else {
    
	    print &Submission::Public::title_bar(-home=>$homelink,-dbc=>$dbc,-user_name=>$collab_name,-contact_id=>$contact_id,-project_path=>$project_path,-config=>\%config,-layer_key=>'proj',-sub_tab=>$title_bar,-img_dir=>$image_dir); 
	    print $login_messages;

	    print &Submission::Public::home_page(-home=>$homelink,-dbc=>$dbc,-user_name=>$collab_name,-contact_id=>$contact_id,-project_path=>$project_path,-config=>\%config,-layer_key=>'proj',-sub_table=>' ');   
	}
}
print &vspace(10) . &logout_button();

my $botbar = &alDente::Web::show_botbar(-image_dir=>"$image_dir",-center_link=>'http://www.bcgsc.ca');
print &alDente::Web::unInitialize_page(-botbar=>$botbar);

# end html
print end_html();

# store the session
$sess_obj->store_Session();

exit;

################################
# returns an HTML string for a logout button
################################
sub logout_button {
################################
    my $homelink = shift;
    
    my $str = '';
    $str .= start_form(-name=>"Logout Form",-method=>'POST');
#    $str .= br();
    $str .= submit(-name=>'Log Out',-style=>"background-color:red").br();
    $str .= end_form();
    if ($homelink) {
	return &Link_To($homelink,'Log Out','&Log Out=1');
    }
    else { return $str }
}

