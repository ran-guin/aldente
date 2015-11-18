package alDente::Web;

use strict;

use warnings;
use CGI qw(:standard);
use CGI::Carp('fatalsToBrowser');
use DBI;
use Data::Dumper;
use Benchmark;

use RGTools::RGWeb;
use RGTools::RGIO;
use RGTools::Views;

use SDB::HTML;
use SDB::CustomSettings;

use alDente::SDB_Defaults;
use alDente::Form;

use LampLite::Login_Views;

use vars qw($user $version_number %Benchmark @icons_list $Sess $Security $issue_tracker $jira_link %Configs);

my $headerbg          = '#DDDDDD';     ## "rgb(200,200,200)";
my $headerfontc       = "'#AAAAAA'";
my $header_bar_colour = "#DDDDDD";

my $BS = new Bootstrap();
########################################
#
#  Creates the tab for each department in alDente
#
####################
sub GoHome {
####################
    my %args = filter_input( \@_, -args => 'dbc,dept,open_layer', -mandatory => 'dbc,dept' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $dept = $args{-dept} || $dbc->get_local('home_dept');
    my $quiet = $args{-quiet};

    my $open_layer = $args{-open_layer};
    my $access     = $dbc->get_local('Access');

    if ( !( $access->{$dept} || $access->{'LIMS Admin'} || $dept eq 'Public' ) ) {

        # This line shouldn't generaly be displayed, unless user is doing something bad!
        #  ie tampering with the URL to gain access to a different department
        # print "<blink>No Access for '$dept' for you!</blink><br>";
         
        my ( $path, $module ) = LampLite::Login_Views::get_dept_module($dept);
        if ( $path =~ /alDente/ && keys %{$access} ) {

            #No home page for the department, go to the next available department
            my $old_dept = $dept;
            ($dept) = keys %{$access};

            #$dbc->warning("No $old_dept department home page, go to $dept department instead)");
        }
        else {
            $dbc->warning("$dept Department not available for this user - see LIMS Admin to add if required");
            return;
        }
    }

    # Dynamicly get the department module path and name
    my ( $path, $module ) = LampLite::Login_Views::get_dept_module($dept);
    require $path;

    my $page;

    my $scanner_mode = $dbc->config('screen_mode');
    if ( $scanner_mode =~ /mobile/i ) {
        require alDente::Scanner;
        $page = alDente::Scanner::home_page($dbc);
    }
    else {
        my $view = $module . '_Views';
        my $ok   = eval "require $view";

        ## This block (and the entire method) can be deprecated and moved to alDente::Login_Views to replace the current Info::GoHome call... ###

        ## the options below were added theo solve some breaking home pages.  The second case should be deprecated so that all home pages are generated via the View modules, but the second block remains in the meantime ##
        ## previously, the code was breaking properly set up home pages (home_page in view).  Now, if anything new breaks, it will be because it is set up INappropriately (eg home_page in model) ... these should be easily fixable if encountered

        ## Note: both cases should ultimately be replaced with calls to std_home_page (new standard), but this hasn't been set up yet for Departments so should be deferred for now...

        if ($ok) {
            ## Try to go to View home page first (this is the preferred way) - if this is NOT where the logic should go, then the model home page method should be moved to the view so that this works... ##
            my $object = $view->new( -dbc => $dbc );
            $page = $object->home_page( -dbc => $dbc, -dept => $dept, -open_layer => $open_layer );
        }
        elsif ( eval "require $module" ) {
            ## if the view does not exist, we can try going to the model home page, but this should be deprecated - previously everything was going through this block .... ##
            my $object = $module->new( -dbc => $dbc );
            $page = $object->home_page( -dbc => $dbc, -dept => $dept, -open_layer => $open_layer );
        }

    }

    if ( !$quiet ) { print $page }

    return $page;
}

#
# Retrieves image from Image directory
#
#############
sub image {
#############
    my %args   = filter_input( \@_, -args => 'name' );
    my $name   = $args{-name};
    my $height = $args{-height};
    my $width  = $args{-width};
    my $border = $args{-border} || 0;
    my $alt    = $args{-alt};
    my $title  = $args{-title};
    my $id     = $args{-id};

    my $size_spec;
    if ($height) { $size_spec .= " height=$height" }
    if ($width)  { $size_spec .= " width=$width" }

    my $image = qq(<img id='$id' border=$border src='/$URL_dir_name/images/png/$name' alt='$alt' title='$title' $size_spec>);

    return $image;
}

###############
sub thumbnail {
###############
    my %args = filter_input( \@_, -args => 'image' );

    my $image   = $args{ -image };
    my $dir     = $args{-dir} || 'icons';
    my $link    = $args{ -link };
    my $tooltip = $args{-tip};

    my $output = "\n<img src='/$Configs{URL_dir_name}/images/$dir/$image'>";
    if ($link) {
        $output = Link_To( $link, $output, -tooltip => $tooltip );
    }

    return $output;
}

#######################
sub header_messages {
#######################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $messages;

    $messages .= validate_Printers( -dbc => $dbc );

    $messages .= show_current_messages($dbc);

    return $messages;
}

########################
sub validate_Printers {
########################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    my $messages;
    my $session = $dbc->session();

    my $warning;

    my $printer_group   = $session->{user_settings}{PRINTER_GROUP};
    my $current_printer = $session->{printer_group};

    my $prompt = 'Set';
    if ($current_printer) {
        return;
    }
    elsif ($printer_group) {
        require LampLite::Barcode;
        $warning = "Set Default Printer Group to $printer_group";
        my $User = new alDente::Employee( -id => $dbc->get_local('user_id'), -dbc => $dbc );   ## should probably be part of $dbc, but pass in for now to reduce potential legacy problems
        my $ok = LampLite::Barcode->reset_Printer_Group( -dbc => $dbc, -name => $printer_group, -User=>$User);
        if ($ok) { $prompt = 'Change' }
    }
    else {
        $warning = 'Printer Group not defined';
    }
    
    require alDente::Barcode_Views;
    $messages .= alDente::Barcode_Views::reset_Printer_button( -dbc => $dbc, -warning => $warning, -prompt => $prompt );

    return $messages;
}

#########################
sub show_current_messages {
#########################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $p = '';

    #
    # Print Messages    #

    my $removed_messages;
    if ( param("Remove Message") ) { $removed_messages = join ',', param("Message") }

    my $homelink = $dbc->homelink();

    require alDente::Messaging;
    my $msg_obj = alDente::Messaging->new( -dbc => $dbc );
    my ($msgref) = $msg_obj->get_messages( -exclude => $removed_messages, -homelink => $homelink );

    #      if (int(@$msgref)) {

    my $scanner_mode = $dbc->config('screen_mode');
    if ( $msgref && @$msgref && $scanner_mode =~ /desktop/i ) {
        my @Messages = @$msgref;
        $p .= "<hr/>";
        my $remove_link = Link_To( $dbc->config('homelink'), "Remove Messages (Mark as Read)", "&Message+Removal+Window=1", $Settings{LINK_COLOUR}, ["newwin"] );
        $p .= create_tree( -tree => { 'Active Message(s):' => $remove_link . Cast_List( -list => \@Messages, -to => 'UL' ) }, -default_open => 'Active Message(s):' );
    }

    $p .= "<hr/>";

#### set login_name for mysql if permissions allow updates... ####
    return $p;
}

#
# Wrapper to generate hide / unhide elements on the current page
# (eg. can be used to enable options to hide / show headers on page)
# Return: (hide_element_string, unhide_element_string)
#
####################
sub hide_element {
####################
    my %args           = filter_input( \@_, -args => 'element,content,unhide' );
    my $element        = $args{-element};
    my $content        = $args{-content};
    my $unhide_element = $args{-unhide};

    my $hide   = "<a href='#' class='button' id='hide.$element'  style='color:black; font-weight:bold;' onclick=\"HideElement('$element'); this.style.color='white'; getElementById('unhide.$element').style.color='black';";
    my $unhide = "<a href='#' class='button' id='unhide.$element' style='color:white; font-weight:bold;' onclick=\"unHideElement('$element'); this.style.color='white'; getElementById('hide.$element').style.color='black'; ";

    if ($unhide) {
        $hide   .= " unHideElement('$unhide_element');";
        $unhide .= " HideElement('$unhide_element');";
    }
    $hide   .= "\">\n<span>Hide $content</span></a>\n";
    $unhide .= "\">\n<span>Show $content</span></a>\n";

    return ( $hide, $unhide );
}

#######################
sub add_sub_labels {
#######################
    my %args      = filter_input( \@_ );
    my $d         = $args{-hash};
    my $class     = $args{-class};
    my $link      = $args{ -link };
    my $dept      = $args{-dept};
    my $active    = $args{-active};
    my $recursive = $args{-recursive};

    my $label;

    if ( !$d ) {return}

    my $menu;

    # Print the tabs

    my ( $display_section, $display_target );
    if ( ref $d eq 'ARRAY' ) {
        $display_section = $d->[0];
        $display_target  = $d->[0];
    }
    elsif ( ref $d eq 'HASH' ) {
        ($display_section) = keys %$d;
        ($display_target)  = values %$d;
    }
    else {
        $display_section = $d;
        $display_target  = '';
    }

    my ( $this_class, @sub_labels );
    if ( $dept eq $display_section ) {
        ### dept menu only ###
        $this_class = "id='activelabel' style='background-color:$headerbg'";    #  match active label with colour of core header (differs from other tabs...);
        $active     = 1;
        my $thislink = $link;
        $thislink =~ s/Target_Department=(\w+)/Target_Department=$dept/;
        $label .= &Link_To( $thislink, $display_section );
    }
    elsif ( ref $display_target eq 'ARRAY' ) {
        ### sub menus included ###
        @sub_labels = @$display_target;
        $this_class = "class='has-sub '";
        if ($recursive) { $display_section .= ' >>' }                           ## after top menu - indicates expandable option...
        $label .= $display_section;
    }
    else {
        $display_target ||= $link;
        $label .= &Link_To( $display_target, $display_section );

        if ( !$active ) {
            ### first of list in lower menu (not sure if necessary) ###
            $this_class = "class='active '";
            $active     = 1;
        }
    }

    $menu .= "\t<li $this_class>$label\n";
    if (@sub_labels) {
        $menu .= "\n\t\t<ul>\n";
        foreach my $sub_label (@sub_labels) {
            my ($sub_text)   = keys %{$sub_label};
            my ($sub_target) = values %{$sub_label};

            if ( ref $sub_target eq 'ARRAY' ) {
                $menu .= add_sub_labels( -hash => { $sub_text => $sub_target }, -class => $class, -link => $link, -dept => $dept, -active => $active, -recursive => 1 );
            }
            else {
                if ( $sub_target =~ /\<a href/i ) {
                    ## target contains a link .. leave it alone ##
                    $sub_text = $sub_target;
                }
                elsif ( $sub_target =~ /^http:/i ) {
                    ## target is fully qualified link ##
                    $sub_text = &Link_To( $sub_target, $sub_text );
                }
                else {
                    $sub_text = &Link_To( $link, $sub_text, $sub_target );
                }
                $menu .= "\n\t\t\t<li>$sub_text</li>\n";
            }
        }
        $menu .= "\n\t\t</ul>\n";
    }
    $menu .= "\t</li>\n";

    return $menu;
}

#
# Refactored and redirected to new Menu method ...
#
#########################
sub Tab_Bar {
#########################
    #
    # Refactored into new Menu method
    #
    my %args = &filter_input( \@_ );

    return Menu(%args);
}

#######################
#
# Provide a quick page that simply prompts for fields that are missing.
# This resubmits input parameters along with the prompted field(s)
# <snip>
# Example:
#    unless (param('FK_Employee__ID') {
#       alDente::Web::reload_parameters($dbc, 'FK_Employee__ID',-prompt=>'Who',-values=>['me','you'])
#    }
#
#  or  alDente::Web::reload_parameters($dbc, 'FK_Employee__ID,FK_Library__Name',
#                                      -parameters=>{&Set_Parameters()
#                                      -prompt=>{'FK_Employee__ID'=>'Who','FK_Library__Name'=>"Library:"},
#                                      -values=>{'FK_Employee__ID' => ['me','you'],'FK_Library__Name'=>$Dbc->get_library_list(-project=>1)} );
########################
sub reload_parameters {
########################
    my %args = &filter_input( \@_, -args => 'dbc,required' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $required   = $args{-required};                                                                ## fields that should be required (regenerates page, prompting for these fields to be entered...
    my $values     = $args{ -values };                                                                ## hash (keyed on fields required) indicating values applicable - generates popup_menu ## (scalar ok if only 1 required field)
    my $prompt     = $args{-prompt};                                                                  ## hash (keyed on fields required) indicating prompts to use.. ## (scalar ok if only 1 required field)
    my $parameters = $args{-parameters};                                                              ## input parameters

    my %Prompt = %{$prompt};
    my %Values = %{$values};

    unless ( $required =~ /,/ ) {                                                                     ## allow scalar if only one field
        $Prompt{$required} = $prompt unless ( defined $Prompt{$required} );
        $Values{$required} = $values unless ( defined $Values{$required} );
    }

    my @required_list = Cast_List( -list => $required, -to => 'array' );

    #    print alDente::Form::start_alDente_form($dbc, 'ReLoad', -parameters => $parameters );
    print alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'ReLoad' );

    print hidden( -name => 'carried', -value => 'over' );
    foreach my $key ( param() ) {
        my @values = param($key);
        foreach my $value (@values) {
            print hidden( -name => $key, -value => $value, -force => 1 );
        }
    }
    foreach my $required_field (@required_list) {
        my $prompt = $Prompt{$required_field} || $required_field;
        if ( $Values{$required_field} ) { $prompt .= popup_menu( -name => $prompt, -values => $Values{$required_field}, -force => 1 ) }
        else                            { $prompt .= textfield( -name => $required_field, -size => 20, -force => 1 ) }
        print standard_label($prompt);
    }
    print submit( -name => 'resubmit', -class => 'Action' );
    print "\n" . end_form() . "\n";

    return;

}

##########################
# Initialize alDente-specific cookies
##########################
sub initialize_cookies {
##########################
    my %args    = &filter_input( \@_, -args => 'dbc' );
    my $dbc     = $args{-dbc};
    my $user_id = $dbc->get_local('user_id');

    my $cookie;
    my @cookies = ();

    if ( ( defined $user ) && ( $user ne 'nobody' ) ) {
        $cookie = cookie( -name => "$URL_dir_name:user", -value => $user, -expires => "+1y" );
        push( @cookies, $cookie );
        if ( $user ne 'Guest' && $user ne 'Auto' ) {
            $cookie = cookie( -name => "$URL_dir_name:active", -value => time(), -expires => "+1y" );
            ###Couldn't use "-expires=>'+5m' since doesn't work with IE!!!!
            push( @cookies, $cookie );

        }
        my $last_department;
        if ( param('Target_Department') ) {
            $last_department = param('Target_Department');
        }
        elsif ($Current_Department) { $last_department = $Current_Department }

        if ($last_department) {
            $cookie = cookie( -name => "$user_id:last_department", -value => $last_department, -expires => "+1y" );    # Set last page the user was in
            push( @cookies, $cookie );
        }
    }

    return \@cookies;
}

#################################
### Moved from Submission::Public
# Subroutine: Initialize cookie array for CGI
# Return: An arrayref of cookies
#################################
sub gen_cookies {
#################################
    my %args = &filter_input( \@_, -args => 'names,values,expires' );

    my $names   = $args{-names};       # (ArrayRef) A list of names for the cookies
    my $values  = $args{ -values };    # (ArrayRef) A list of values of the cookies
    my $expires = $args{-expires};     # (ArrayRef) A list of expiry dates for the cookies

    my @names_list   = &Cast_List( -list => $names,   -to => 'array' );
    my @values_list  = &Cast_List( -list => $values,  -to => 'array' );
    my @expires_list = &Cast_List( -list => $expires, -to => 'array' );

    my @cookies = ();

    my $counter = 0;

    foreach my $name (@names_list) {
        my $value  = $values_list[$counter];
        my $expire = $expires_list[$counter];
        push( @cookies, &cookie( -name => $name, -value => $value, -expires => $expire ) );
        $counter++;
    }

    return \@cookies;
}

#########################
# Initialize LIMS page
#########################
sub Initialize_page {
#########################
    my %args           = &filter_input( \@_, -args => 'dbc' );
    my $dbc            = $args{-dbc};
    my $full_width     = $args{-width} || $Settings{PAGE_WIDTH};
    my $cookie_ref     = $args{-cookie_ref};                            # (ArrayRef) Array of cookies to place into
    my $css_pragma_str = $args{-css_pragma_header} || $html_header;     # (Scalar) String definition of css
    my $js_str         = $args{-java_header} || $java_header;           # (Scalar) String definition of javascript source files
    my $topbar         = $args{-topbar};                                # (Scalar) [Optional] string definition of the topbar
    my $header         = $args{-header};
    my $offset         = $args{-offset} || 0;
    my $include        = $args{-include} || 'Home,Info,Contact,Help';

    my $colspan = 10;

    my $width;
    if ($offset) { $width = $full_width - $offset }

    # if no cookies, then use the default cookies from LIMS
    unless ($cookie_ref) {
        $cookie_ref = &initialize_cookies( -dbc => $dbc );
    }

    my $str = header( -cookie => $cookie_ref );

    #    $str .= "<HTML>\n";
    $str .= "<!--- Initializing page --->\n";
    $str .= $css_pragma_str;
    $str .= $js_str;

    $str .= "\n<BODY>";
    $str .= "<noscript>\n
    <table width='100%' bgcolor=yellow><tr><td><center>
    <font color=red size=+1><b>JavaScript has been Disabled!</b></font><BR>
    <font color=red size=-1>Please note that in order to take full advantage of alDente LIMS' functionalities, you need to enable JavaScript</font>
    <br>
    <font color=blue size=-1>For more information, please visit <a href='https://www.google.com/support/adsense/bin/answer.py?answer=12654'>Enabling JavaScript</a></font>
    </center></td></tr></table>\n</noscript>\n";

    $str .= "<Table width=$full_width Border=0 cellspacing=0 cellpadding=0>\n";

    $str .= "<TR>\n";
    $str .= "";
    $str .= "<TD>" . &hspace($offset) . "</TD>";                               ## left margin
    $str .= "<TD colspan=$colspan><div id='navtxt' class='navtext'></div>";    ## allow three columns for topbar if necessary...

    if ($topbar) {
        $str .= $topbar;
    }
    elsif ($header) {
        $str .= &show_topbar( $dbc, -width => $width, -include => $include, -header => $header );
    }
    else {
        $str .= &show_topbar( $dbc, -width => $width, -include => $include );
    }

    $str .= "</TD></TR>\n";

    ## add alternative header (hidden) in case user wants to shrink main header ##
    #    $str .= "<TR>" . "<div id='miniheader' style='display:none'>" . user_label( $dbc, $include ) . '</div>' . '</TR>';

    $str .= "<TR><TD></TD><TD colspan=$colspan>\n<div id='miniheader' style='display:none'>\n" . user_label( $dbc, $include ) . "</div>\n";

    #    $str .= "<HR style=\"margin-bottom:1px; margin-top:0px;\">";
    ### set width for body of page... as defined
    #$str .= "<Table width=$width cellpadding=5 border=0 cellspacing=0><TR><TD>";

    return $str;
}

#########################
# show bottom LIMS bar and close formatting tables
#########################
sub unInitialize_page {
#########################
    my %args   = &filter_input( \@_ );
    my $botbar = $args{-botbar};         # (Scalar) Bottom bar
    my $width  = $args{-width};
    my $offset = $args{-offset} || 0;

    my $str = '';

    ### close body of page table..
    $str .= "</TD></TR></Table>";

    if ($botbar) {
        $str .= $botbar;
    }
    else {
        $str .= alDente::Web::show_botbar( -width => $width );
    }

    $str .= "</BODY>";
    ### close wrapper table ..
    #    $str .= "\n</TD></TR></Table>\n";

    return $str;
}

################################
# Display topbar for LIMS
# This should be customized for specific LIMS locales
################################
sub show_topbar {
################################
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc        = $args{-dbc}        || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $image_path = $args{-image_dir}  || "$URL_dir_name/$image_dir";
    my $about_URL  = $args{-about_link} || '';
    my $contact_URL = $args{-contact_link};
    my $center_URL  = $args{-center_link};
    my $help_URL    = $args{-help_link};
    my $page_width  = $args{-width} || $Settings{PAGE_WIDTH} || 800;
    my $include     = $args{-include};
    my $header      = $args{-header};
    my $home_URL    = $args{-homelink} || $dbc->{homelink};

    # if the path does not start with a leading slash, add it in
    if ( $image_path !~ /^\// ) {
        $image_path = "/$image_path";
    }

    my ( $ind1, $ind2, $ind3 ) = ( "\t", "\t\t", "\t\t\t" );

    $dbase ||= $Configs{DATABASE};

    my $dbase_mode = $dbc->{dbase_mode};

    # LIMS-specific link
    $about_URL   ||= "$Configs{URL_address}/sequencing.pl?Database_Mode=$dbase_mode";
    $contact_URL ||= "$URL_domain/$URL_dir_name/html/ContactUs.html";
    $center_URL  ||= "http://www.bcgsc.ca";
    $help_URL    ||= "$URL_domain/$URL_dir_name/cgi-bin/help.pl";

    my $str = '';

    my $help_button = '';
    if ( $include =~ /Help/i ) {
        $help_button
            = alDente::Form::start_alDente_form( $dbc, -name => 'help', -url => $help_URL )
            . textfield( -name => 'Help', -size => 10, -default => '-- HELP --', -onClick => "this.value=''", -force => 1 ) . ' '
            . submit( -name => '?', -class => 'Search' ) . "\n"
            . end_form() . "\n";
    }

    my ( $home, $info, $site_map, $log, $contact ) = ( '', '', '' . '', '', '' );

    $home     = Link_To( $home_URL,                    "<B>Home</B>",     "&Home=Default", -colour => '#333333', -hover_colour => 'black', -ul => 0 ) if ( $include =~ /\bHome/i );
    $info     = Link_To( "$URL_address/sequencing.pl", "<B>About</B>",    "",              -colour => '#333333', -hover_colour => 'black', -ul => 0 ) if ( $include =~ /\binfo/i );
    $site_map = Link_To( $dbc->{homelink},             "<B>Site Map</B>", "&Site Map=1",   -colour => '#333333', -hover_colour => 'black', -ul => 0 ) if ( $include =~ /\bSite/i );

    my $loginlink = $dbc->{homelink} || '';
    $loginlink =~ s/(.+?)\?(.*)/$1/;    ## truncate all parameters when logging out.

    $log = Link_To( $loginlink, "<B>Logout</B>", "&Re Log-In=1&Database_Mode=$dbase_mode", -colour => '#333333', -hover_colour => 'black', -ul => 0 ) if ( $include =~ /\bLog/i );
    $contact = &Link_To(
        'mailto:alDente@bcgsc.ca',
        '<B>Contact Us</B>',
        '',
        -colour       => '#333333',
        -hover_colour => 'black'
    ) if ( $include =~ /\bContact/i );

    my @local_links = ();
    push @local_links, $home     if $home     && $include =~ /home/i;
    push @local_links, $info     if $info     && $include =~ /info/i;
    push @local_links, $site_map if $site_map && $include =~ /site/i;
    push @local_links, $log      if $log      && $include =~ /log/i;
    push @local_links, $contact  if $contact  && $include =~ /contact/i;
    my $llinks = join " | ", @local_links;

    my $header_image;
    if ($header) { $header_image = $header }
    ;    #  = "vectorology_header.png";
    my $height      = 10;     ## offset height from bottom..
    my $logo_height = 80;
    my $logo_width  = 1080;

    #    my $logo_height = 108;
    #    my $logo_width = 853;

    my $user_label = user_label( $dbc, -include => $include );

    if ( param('Kill') ) {    #  $URL_version =~ /Dev/i ) {
        $user_label .= " <a href='/$URL_dir_name/cgi-bin/kill.pl?ID=$$'> <font color=red size=-3> (KILL page)</font></a> ";
    }

    if ($header_image) {
        $str .= "\n<div id='header1'>\n";

        #@        $str .= &hspace(10);
        $str .= "<Table align=left width = $logo_width height=$logo_height background='$image_path/$header_image' border=0 cellspacing=0 cellpadding=0>\n$ind1<TR>\n";
        $str .= "$ind2<TD height=$height> </TD>\n</TR><TR>\n";
        $str .= "$ind2<TD width=300></TD>\n";
        $str .= "$ind2<TD width=300 align=left valign=top>$user_label</TD>\n";                                                                                           ## fill out full width...
        $str .= "$ind2<TD width=250 align=left nowrap valign=top>$llinks</TD>\n";                                                                                        ## fill out full width...
        $str .= "$ind2<TD width=200 align=left valign=top>$help_button</TD>\n";                                                                                          ## fill out full width...
        $str .= "$ind2<TD width=80></TD>\n";                                                                                                                             ## fill out full width...
        $str .= "$ind1</div></TR>$ind1<TR>$ind2<TD>$ind2</TD>\n";
        $str .= "$ind1</TR>\n</Table></div>\n";
    }
    else {
        $str
            .= "\n<Table width=$page_width cellpadding=5 border=0 cellspacing=0>\n$ind1<TR>\n$ind2<TD bgcolor=#ffffff align=center>\n$ind3"
            . "<Font color=white><B>$user_label</B></Font></TD>\n$ind2<TD bgcolor=#FFFFFF align=center>\n$ind3"
            . "<Font color=Red size=-1> Automated Laboratory Data Entry 'N Tracking Environment </Font></TD><TD>$llinks</TD>"
            . "\n$ind2</TD>\n$ind1</TR>\n</Table>\n";
    }

    if ( $dbc->{host} eq $Configs{BACKUP_HOST} && $dbc->{dbase} eq $Configs{BACKUP_DATABASE} ) {
        $str .= $dbc->warning( "Connected to Replication Server with Read Only Privileges", -hide => 1 );
    }

    ## add hidden alternative header (which may replace full header if necessary)
    return $str;
}

##################
sub user_label {
##################
    my %args    = filter_input( \@_, -args => 'dbc,include' );
    my $dbc     = $args{-dbc};
    my $include = $args{-include};

    my $user = '?';
    if ( $dbc && defined $dbc->{session} ) {
        $user = $dbc->session->{user} || '';
    }

    my $user_label = "<Font color=black><B>$user</B>";

    if ( $include =~ /\bhostinfo\b/i ) {
        $user_label .= "<B>";
        if ( defined $dbc->session && $dbc->session->{site_name} ) { $user_label .= "@" . $dbc->session->{site_name} }

        my $host    = $dbc->{host}    || '';
        my $dbase   = $dbc->{dbase}   || '';
        my $db_user = $dbc->{db_user} || '';
        $user_label .= "</B> [$db_user\@$host:$dbase]</Font>";
    }

    return $user_label;
}

################################
# Display bottom bar for LIMS
# This should be customized for specific LIMS locales
################################
sub show_botbar {
################################
    my %args = @_;

    my $image_path   = $args{-image_dir} || "$URL_dir_name/$image_dir";
    my $center_URL   = $args{-center_link};
    my $width        = $args{-width} || $Settings{PAGE_WIDTH};
    my $footer_image = "botbar_blue.png";

    $center_URL ||= "http://www.bcgsc.ca";

    # if the path does not start with a leading slash, add it in
    if ( $image_path !~ /^\// ) {
        $image_path = "/$image_path";
    }

    my ( $ind1, $ind2, $ind3 ) = ( "\t", "\t\t", "\t\t\t" );

    my $str = '';
    $str
        .= "\n<P/>\n<Table width=1100 >\n$ind1<TR>\n$ind2<TD colspan=2 align=right cellpadding=0 cellspacing=0>"
        . "<A Href='$center_URL' border=0>"
        . "<img src='$image_path/botbar-address.png' border=0></A>\n"
        . "$ind2</TD>\n$ind1</TR>\n$ind1<TR>\n$ind2<TD nowrap>"
        . "<img src='$image_path/botbar-white_to_blue.png'>"
        . "<img src='$image_path/botbar-blue.png' border=0>"
        . "<img src='$image_path/topbar-bcca.png' border=0>"
        . "\n$ind2</TD>\n$ind1</TR>\n</Table>\n";
    return $str;
}

#
# Reloads given input in preparation for regenerating login page
#  (clears information explicitly retrieved from login page)
#
# Return: Revised Input hash
######################
sub reload_input {
######################
    my $input = shift;

    my @clear = ( 'Session', 'Method', 'url', 'Dest_URL', 'User List', 'Pwd', 'Log In', 'Database', 'Department', 'Printer_Group' );

    if ( defined $input && ref $input eq 'HASH' ) {
        ## clear login input parameters ##
        foreach my $par (@clear) {
            delete $input->{$par};
        }
    }
    else { $input = {} }

    return $input;
}

# ->alDente::Web (probably not used anywhere)
########################
sub login_password {
########################
    my $dbc = shift;

    print h3("Login to Database:");
    print alDente::Form::start_alDente_form( $dbc, -name => 'LoginPage' );

    print submit( -name => 'Login' ), br(), popup_menu( -name => 'User Choice', -value => [@users], -default => "$user" ), password_field( -name => 'Password', -value => [@users], -force => 1, -default => "" ), "\n</FORM>";

    return 1;
}

return 1;

