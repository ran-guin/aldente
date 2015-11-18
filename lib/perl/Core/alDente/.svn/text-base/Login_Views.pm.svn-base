###################################################################################################################################
# alDente::Login_Views.pm
#
# Interface generating methods for the Session MVC  (associated with Session.pm, Session_App.pm)
#
# NOTE: many of this should probably be moved to the applicable custom/ module  and use this module as a base
#
#
###################################################################################################################################
package alDente::Login_Views;

use base SDB::Login_Views;

use strict;

## Standard modules ##
use CGI qw(:standard);
use Time::localtime;
use Data::Dumper;
use Benchmark;

## Local modules ##
use SDB::HTML;
    
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
use LampLite::HTML;

use alDente::Session;
use File::Spec;

use vars qw( %Configs %Benchmark $scanner_mode);

my $q  = new CGI;
my $BS = new Bootstrap();

my ( $VOLUME, $FILE_DIR, $FILE_NAME ) = File::Spec->splitpath(__FILE__);

my %Prefix;
$Prefix{Rack}  = 'Rac';
$Prefix{Plate} = 'Pla';
$Prefix{Tray}  = 'Tra';

my $padding   = '160px';
my $collapsed = '70px';

my $scan_options
    = 'Options<BR><BR><B>Type:</B><UL>'
    . '<LI>(any single barcode) -> Get info on object + more options'
    . '<LI>Pla + Pla ...->Generate Container Set to Prep/Transfer/Throw Away'
    . '<LI>Sol + Sol -> Mix Reagents'
    . '<LI>Pla + Sol -> Apply Reagent/Solution to Container'
    . "<LI>Sol + $Prefix{Rack} -> Move Reagents/Solutions"
    . "<LI>Pla + $Prefix{Rack} -> Move Containers"
    . "<LI>$Prefix{Rack} + $Prefix{Equipment} (Freezer) -> Move Rack between Freezers"
    . "<LI>$Prefix{Rack} + $Prefix{Rack} -> Move Rack from Source -> Target destination" . "</UL>";

#if ($dbc->package_active('Sequencing') ) {
if ( $Configs{Plugins} =~ /Sequencing/ ) {
    $scan_options .= '<BR><BR>Sequencing Specific:<UL>' . '<LI>Pla + Equ (sequencer) -> Generate SampleSheet' . '<LI>Equ + Sol (matrix/buffer) -> Change Matrix and/or Buffer' . "</UL>";
}

$scan_options .= "<BR><B>..and press 'Scan' Button</B><BR>";

$scan_options
    .= '<BR><BR>Shortcuts:<UL>'
    . "<LI>$Prefix{Plate}1-$Prefix{Plate}5 -> retrieves multiple plates (eg 1,2,3,4,5) - works for other objects as well"
    . "<LI>$Prefix{Tray}(a)$Prefix{Tray}(a-c) -> retrieves specific quadrant(s) from a 96x4 384-well plates"
    . "<LI>CC001 -> exact match of library name will pull up home page for that library" . "</UL>";

$scan_options .= "<BR><B>To search database for string use 'Search DB' Button on the right side of the menu bar</B<BR>";

my %Tool_Tips = (
    ###Fields from left navigation bar
    Search_Button_Field      => 'Search key fields in the database<UL><LI>Use * for a wildcard<\LI><LI>Numerical Ranges ok (eg 12345-12348)</LI><LI>use quotes if searching for a string that resembles a range</LI</UL>',
    Help_Button_Field        => 'Search the help files',
    Scan_Button_Field        => $scan_options,
    Grab_Plate_Set           => 'Enter Plate Set Number to retrieve previously defined group of plates/tubes',
    Plate_Set_Button_Field   => 'Grab plate sets',
    Print_Text_Label_Field   => 'Print text labels to barcode printers',
    Error_Notification_Field => 'Report an issue and send email notification to administrators',
    Catalog_Number_Field     => 'Enter any portion of the catalog number or name to retrieve current stock items<BR>Use * for a wildcard if desired',
    New_Primer_Type_Link     => 'Define a new type of primer',
    New_Plate_Type_Link      => 'Define a new type of plate/plasticware',
    ###Fields from Login page
    Edit_Lane_Link => 'Update Comments for a Lane',
    Password_Field => 'The default password is pwd',
    Reset_Button   => 'Reset all form elements to default values',
    Load_Set       => 'Quick load of specified Set of Plates / Tubes',
);

############################################################
## Object Aliases:  Aliases for database objects
##
##
############################################################
my %object_aliases = (
    Original_Source  => 'Source',
    ReArray          => 'Rearray',
    Run              => 'Read,Run',
    SequenceAnalysis => 'Read,Run',
    Clone_Sample     => 'Clone',
    Sample           => 'Clone',
);

###############
sub relogin {
###############
    my $self = shift;
    my %args         = filter_input( \@_, -args => 'dbc,reload' );

    return $self->SUPER::relogin(%args);
}

#################
sub lims_header {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my $dbc = $args{-dbc} || $self->{dbc};
    my $icon = $args{-icon};

    my $text = "<B>A</B>utomated <B>L</B>aboratory <B>D</B>ata <B>E</B>ntry <B>N</B>' <B>T</B>racking <B>E</B>nvironment";
        
    my $local_homelink = $dbc->homelink(-clear=>['Target_Department']);
    if ($icon) { $icon = Show_Tool_Tip("<A Href='$local_homelink'><IMG SRC='$icon' width=200></A>\n", "Go back to default Home Page", -placement=>'bottom') }

    my $home = Show_Tool_Tip("<A Href='$local_homelink'>" . $BS->icon('home', -size=>'3x', -colour=>'#666') . "</A>", 'Return to Home Page', -placement=>'bottom');
    $home = qq(<button type="button" class="btn btn-default btn-md" style="border:0;">) . $home . "</button>\n";
    
    my $table = new HTML_Table();
    $table->Set_Line_Colour('#fff');
    $table->Set_Class('nav dropdown-toggle');
    $table->Set_Row([ &hspace(10), $home , &hspace(10), $icon,  &hspace(10), "<div class='visible-lg'>$text</div>"]);
    
    my $main = $table->Printout(0);
     
    my $dept = $dbc->config('Target_Department');
 
    my $Menu = $self->Model(-class=>'Menu');
  
    my %custom_icon_map = $Menu->get_Icons(-dbc=>$dbc, -dept=>$dept);
    my %icon_groups = $Menu->get_Icon_Groups(-dept=>$dept);    
    
    my ( $icons, $icon_class ) = $self->page_icons( $dbc, -dept => $dept, -width => 30, -custom_icons => \%custom_icon_map, -custom_icon_groups=>\%icon_groups);
        
    my $menu = $self->Menu(-dbc=>$dbc, -sections => $icons, -limit => 20, -off_colour => 'white', -id => 'icons', -class => $icon_class, -inverse=>1);
   
    if (! SDB::HTML::clear_tags($menu) ) { $menu = '' };  ## if no menu items are included, ignore hash of empty blocks so that header is not displayed ##

    my $left = [ $home . hspace(10) . $icon ];
    my $main = "<div class='visible-lg'>$text</div>";
    
    unshift @$menu, $BS->flexbox( [$BS->hide_header('collapseHeader',60, -class=>'Default btn'), $BS->show_header('collapseHeader', 160, -class=>'Default btn')], -direction=>'column');
    
    return $self->header(-dbc=>$dbc, -icon=>$main, -menu => $menu, -left=>$left, -text=>$text);
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

    if ($external) { $environment = 'external' }

    my $input_bar;
    if ( $environment =~ /lab/i ) { $input_bar = $self->alDente_header_bar( -mobile_mode => 0 ) }

    my $mobile;
    if ( $dbc->config('screen_mode') =~ /mobile|tablet/i ) { $mobile = 1 }

    my $scope;
    if   ($external) { $scope = 'Project' } 
    else             { $scope = 'Department' }

    if ( !defined $left ) {
        ### Default header left ###
        $left = [ $self->_home_header( $scope, $mobile, -icon=>$icon) ];
    }

    if ( !defined $centre ) {
        ### Default header centre ###        
        if ( $dbc->config('Database_Mode') && $dbc->config('PRODUCTION_DATABASE') && $dbc->config('dbase') && $dbc->config('dbase') ne $dbc->config('PRODUCTION_DATABASE') ) {
            $text .= '<BR>' . Show_Tool_Tip( "<center><Font color='red'>Non-Production Mode</Font>", "Current Database is <B>Non_Production</B></center>", -placement => 'bottom' );
        }

        if ($text) { $centre = "<div class='visible-lg'>$text</div>" }
    }
    
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

    my $centre;
    if ($icon) { $centre ||= $icon } ## "<IMG SRC = '/" . $dbc->config('images_url_dir') . '/' . $dbc->config('icon') . "' width=150 />" }
    
    my $header;
    if ($mobile) {
        $header =  $BS->start_header( -name => 'collapseHeader', -position => $position ) 
        . $BS->header( 
            -centre => $centre,
            -left =>  $left,
            -right => $right,
            -style => "margin:0px; background-color:white; border-color:white;",);

        if ( !$guest && ( $input_bar || $menu ) ) {
            $header .= $BS->row( [$input_bar] );
 #           $header .= $BS->end_dynamic_header();
 #           $header .= $BS->menu( $menu, -toggle => 'Menu:', -inverse => 1, -grayscale => 1, -style => "margin:inherit;");
        }
        $header .= $BS->end_header();
        
        if (0) {
        my $scanner;
        if ( !$guest && $input_bar ) {
            my @items = ( $self->scan_button(), $self->error_button() );
            my @span = ( 3, 1 );
            $scanner = $BS->flexbox( \@items, \@span );
        }
        $header = $BS->start_header( -name => 'collapseHeader', -position => $position )
            . $BS->header(
            -left  => [ $self->_home_header( $scope, $mobile ), $self->_dept_header($scope), $scanner ],
            -right => [ $self->_user_header( $scope, $mobile ) ],
            -style => "background-color:white; border-color:white;",
            -flex => [ 1, '', '' ]
            );
        $header .= $BS->end_header();

        ## Special case for mobile so error notification can be viewed in modal -- need to declare modal outside of navbar div
        my $form = new LampLite::Form( -dbc => $dbc, -wrap => 0 );
        $header .= $BS->modal(
            -id          => 'submit-error-btn',
            -no_launcher => 1,
            -title       => 'Submit Error to JIRA',
            -body        => $form->generate(
                -wrap    => 1,
                -class   => 'nomargin',
                -content => textarea(
                    -value       => '',
                    -rows        => 10,
                    -columns     => 45,
                    -force       => 1,
                    -id          => 'Error Notes',
                    -name        => 'Error Notes',
                    -placeholder => 'Please enter an error message.'
                    )
                    . '<BR>' 
                    . '<BR>'
                    . $BS->button(
                    -id    => 'submit-error',
                    -value => 'Error Notification',
                    -label => 'Submit Error',
                    -class => 'search Action',
                    ),
                -include => "<input type='hidden' value='alDente::Login_App' name='cgi_application'></input>"
            )
        );
        }
    }
    else {
        $header = $BS->start_header( -name => 'collapseHeader', -position => $position ) 
        . $BS->header( 
            -centre => $centre, 
            -left => $left, 
            -right => $right, -
            style => "margin:0px; background-color:white; border-color:white;", -flex => [ '', 1, '' ] );

        if ( !$guest && ( $input_bar || $menu ) ) {
            $header .= $BS->row( [$input_bar] );
            $header .= $BS->end_dynamic_header();
            $header .= $BS->menu( $menu, -toggle => 'Menu:', -inverse => 1, -grayscale => 1, -style => "margin:inherit;");
        }
         $header .= $BS->end_header();
    }

    return $header;
}


#########################

#
# Custom header definition
#
#
########################
sub login_page_header {
########################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $image       = $args{-image};
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $screen_mode = $dbc->{screen_mode} || 'desktop';
    my $text = $args{-text};

    ## Default home page header ##
    if ($image) { $image = "<center><IMG SRC='$image' width=200></center>\n" }

    $text = ""; # "<center><B>A</B>utomated <B>L</B>aboratory <B>D</B>ata <B>E</B>ntry <B>N</B>' <B>T</B>racking <B>E</B>nvironments</center>";

    my $spacer = SDB::HTML::hspace(10);
    my @row    = $spacer;

    my $contact_link;
    if ( $screen_mode =~ /desktop/ ) {
        $image .= "<BR>$text";
        $contact_link = "<center>" . $BS->text( 'Contact Us ', -popover => $self->contact_info() . '</center>' );
        $image .= "<P>" . $contact_link;
    }
    push @row, $image;
    push @row, $spacer;

    return $self->SUPER::login_page_header( -row => \@row );

}

##########################
sub alDente_header_bar {
##########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

 #   my $search_button = $self->search_button();
    my $scan_button   = $self->scan_button();
 #   my $err_button    = $self->error_button();
 
    ## pass dbc flag to modal calls below so that modal body can be attached separately at end of body ##
    my $err_icon = $BS->icon('exclamation-triangle', -colour=>'#c33', -size=>'2x');
    my $err_button = $BS->modal(-label=>$err_icon, -title=>'Submit Error', -body=>$self->error_button, -dbc=>$dbc, -tooltip=>'Submit Error'); 

    my $search_icon = $BS->icon('search', -colour=>'green', -size=>'2x');
    my $search_button = $BS->modal(-label=>$search_icon, -title=>'Search Database', -body=>$self->search_button, -dbc=>$dbc, -tooltip=>'Search Database');  ## pass dbc flag so that modal body can be attached separately at end of body ##

    my $options_button;    ## optional shortcut to retrieve plate set ##
    if ( 1 || $Configs{protocol_tracking} ) { 
#        $options_button = $self->plate_set_button();
        my $options_icon = $BS->icon('bars', -size=>'2x');
        $options_button = $BS->modal(-label=>$options_icon, -title=>'Input Options', -body=>$self->plate_set_button(), -tooltip=>'Other Standard Options', -dbc=>$dbc);  ## pass dbc flag so that modal body can be attached separately at end of body ##
    }
    else {
        $options_button .= hspace(50);
    }

    my @items = ( $scan_button, "$err_button $search_button $options_button");
    my @span = ( 6, 4);
    my @styles = ('width:100%');
    my @classes = ('','pull-right');

    my $lock;
    if ( $dbc->config('screen_mode') eq 'mobile' ) {
        my $barcode_icon = $BS->icon('barcode', -colour=>'#c33', -size=>'2x');
        $scan_button = $BS->modal(-label=>$barcode_icon, -title=>'Scan Barcode', -body=>$self->scan_button, -dbc=>$dbc, -tooltip=>'Scan LIMS Barcode');
        
        return $BS->header(-centre => [$scan_button .  $err_button . $search_button . $options_button], -span=>12);
    }
    else {   
        unshift @items, "<span style='text-align:left;'>" . $BS->lock_unlock_header( 'locked', $padding ) . "</span>";
        unshift @span, 2;
        unshift @styles, '';
        unshift @classes,'pull-left';
        
        $lock =  $BS->lock_unlock_header( 'locked', $padding );
    
        return $BS->header(-left=>$lock, -centre=> $scan_button, -right=>[$err_button, $search_button,$options_button], -style=>'background-color:#eee', 
                    -span=>\@span, -styles=>\@styles, -classes=>\@classes);
    }

}

##################
sub scan_button {
##################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $mode = $args{-mobile} || 'desktop';
    my $dbc  = $args{-dbc} || $self->{dbc};

    my ( $help_message, $append, $append_text, $tooltip );
    if ( $mode =~ /mobile/ ) {
        $append_text = 'Scan';
    }
    else {
        $append       = 'fa fa-barcode';                                                                 ## depends on font-awesome version ...
        $help_message = $Tool_Tips{Scan_Button_Field};
        $tooltip      = '<B>Initiate action by Scanning LIMS Barcode</B><BR>click to open/close help';
    }
    my $form = new LampLite::Form( -dbc => $dbc, -wrap => 0 );

    my $text_class;                                                                                      # = 'normal-txt';

    my $scan_button = $form->generate(
        -wrap    => 1,
        -class   => 'nomargin',
        -content => $BS->text_group_element(
            -append_button  => 'barcode',
            -append_tooltip => 'Fetch page',
            -placeholder    => 'Scan LIMS Barcode(s)',
            -name           => 'Barcode',
            -run_mode       => 'Scan',

            #-tooltip        => ' ',
            #-popover        => ' ',
            -help_button  => $help_message,
            -button_class => "Std",
            -text_class   => $text_class,
            -app          => 'alDente::Scanner_App',
            -flex         => 'on',
            -style        => 'padding:3px',
            -mobile       => $dbc->mobile(),
        )
    );

    return $scan_button;
}

##################
sub search_button {
##################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $mode = $args{-mobile} || 'desktop';
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $form = new LampLite::Form( -dbc => $dbc, -wrap => 0 );

    my ( $popover, $append, $append_text, $tooltip );
    if ( $mode =~ /mobile/ ) {
        $append_text = 'Search';
    }
    else {
        $append  = 'fa fa-search';                                                              ## depends on font-awesome version ...
        $popover = $Tool_Tips{Search_Button_Field};
        $tooltip = "<B>Search Database for specified string</B><BR>click to open/close help";
    }

    my $text_class;                                                                             # = 'normal-txt';

    my $search_button = $form->generate(
        -wrap    => 1,
        -class   => 'nomargin',
        -content => $BS->text_group_element(
            -append_button  => 'search',
            -append_tooltip => 'Search Database',
            -placeholder    => 'Search',
            -name           => 'DB Search String',
            -run_mode       => 'Search Database',

            #-tooltip        => ' ',
            -popover      => $popover,
            -button_class => "Search",
            -text_class   => $text_class,
            -app          => 'alDente::Login_App',
            -flex         => 'on',
            -style        => 'padding:3px',
            -mobile       => $dbc->mobile(),
        )
    );

    return $search_button;
}

###################
sub error_button {
####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $mode = $args{-mobile} || 'desktop';
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $form = new LampLite::Form( -dbc => $dbc, -wrap => 0 );

    my ( $popover, $append, $append_text, $tooltip );
    if ( $mode =~ /mobile/ ) {
        $append_text = 'Submit Error';
    }
    else {
        $append  = 'fa fa-thumbs-o-down';                                           ## depends on font-awesome version ...
        $popover = $Tool_Tips{Error_Notification_Field};
        $tooltip = "<B>Attach comments to Error</B><BR>click to open/close help";
    }

    my $text_class;                                                                 # = 'normal-txt';

    my $error_button;
    if ( $dbc->mobile() ) {
        $error_button = qq(<button type='button' class="btn btn-lg btn-danger" data-toggle='modal' data-target="#submit-error-btn" style='flex:on; margin:3px' style='width:100%'><i class='fa fa-bug'></i></button>);
    }
    else {
        $error_button = $form->generate(
            -wrap    => 1,
            -class   => 'nomargin',
            -content => $BS->text_group_element(
                -append_button  => 'thumbs-o-down',
                -append_tooltip => 'Submit Error to JIRA',
                -placeholder    => 'Error',
                -name           => 'Error Notes',
                -run_mode       => 'Error Notification',
                -button_class   => "Action",
                -app            => 'alDente::Login_App',
        
                #-tooltip        => ' ',
                -popover => $popover,

                #            -text_class     => $text_class,
                -flex  => 'on',
                -style => 'padding:3px',
            )
        );
    }

    return $error_button;
}

########################
sub plate_set_button {
########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $mode = $args{-mobile} || 'desktop';
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $form = new LampLite::Form( -dbc => $dbc, -wrap => 0 );

    my ( $popover, $append, $append_text, $tooltip );
    if ( $mode =~ /mobile/ ) {
    }
    else {
        $append  = 'fa fa-arrow-circle-right';                                          ## depends on font-awesome version ...
        $popover = $Tool_Tips{Grab_Plate_Set};
        $tooltip = "<B>Retrieve indicated Plate Set</B><BR>click to open/close help";
    }

    my $text_class;                                                                     # = 'normal-txt';

    #    $append_text = 'Grab Plate Set';

    my $ps_button = $form->generate(
        -wrap    => 1,
        -class   => 'nomargin',
        -content => $BS->text_group_element(
            -append_button  => 'arrow-circle-right',
            -append_tooltip => 'Retrieve this Plate Set',
            -placeholder    => 'Plate Set #',
            -name           => 'Plate Set Number',
            -run_mode       => 'Grab Plate Set',
            -app            => 'alDente::Login_App',

            #-tooltip        => ' ',
            -popover      => $popover,
            -button_class => "Std",

            #            -text_class     => $text_class,
            -flex   => 'on',
            -style  => 'padding:3px',
            -mobile => $dbc->mobile(),
        )
    );

    return $ps_button;
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
    my $self           = shift;
    my %args           = filter_input( \@_, -args => 'dbc' );
    my $dbc            = $args{-dbc} || $self->{dbc};
    my $append         = $args{-append} || [];
    my $choose_printer = $args{-choose_printer} || 1;

    $args{-app} ||= 'alDente::Login_App';

    if ($choose_printer) {
        $append = [ $self->printers_popup( -dbc => $dbc ), @$append ];
    }

    my $header;
    
    if (! $dbc->{header_generated}) { $header = $self->generate_Header( -dbc => $dbc ) }  ## already generated   .... 

    return $self->SUPER::display_Login_page( %args, -append => $append, -clear => [ 'Database_Mode', 'CGISESSID' ], -header => $header );
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
#    if (my $images_dir = $dbc->config('images_url_dir')) { $brand_image = "$images_dir/$brand_image" }

     my $user;
    if ( $dbc && $dbc->session() && $dbc->session->logged_in() ) {
        $user = $dbc->session->{user};  
        $header = $self->lims_header( -dbc => $dbc, -icon => $brand_image);
    }
    else {
        $header = $self->login_page_header( -dbc => $dbc, -image => $brand_image );
    }
    $dbc->{header_generated} = 1;

    return $header;
}

#############################################################
#
#
#
#############################################################
sub printers_popup {
#############################################################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc  = $args{-dbc}  || $self->{dbc};
    my $mode = $args{-mode} || $dbc->config('default_mode');
    my $default = $args{-default};

    my @printer_groups = $dbc->Table_find( 'Printer_Group', 'Printer_Group_Name', "WHERE Printer_Group_Status = 'Active' ORDER BY Printer_Group_Name" );
    my ($disabled) = $dbc->Table_find( 'Printer_Group', 'Printer_Group_Name', "WHERE Printer_Group_Name LIKE '%Disabled'" );

    ## set javascript to dynamically activate / deactivate Printers based upon Database mode selected (deactivate if non-production) ##
    #    $self->{activate_printers_js}   = "SetSelection(this.form, 'Printer_Group', '')";
    #    $self->{deactivate_printers_js} = "SetSelection(this.form, 'Printer_Group', '$disabled')";

    if   ( $mode eq 'PRODUCTION' ) { $default ||= '' }
    else                           { $default ||= $disabled }

    if ( int(@printer_groups) > 1 ) {
        unshift @printer_groups, '';
    }    ## if more than one option, the first option should be blank .. ##

    my $printer = $q->popup_menu(
        -name    => 'Printer_Group',
        -values  => \@printer_groups,
        -default => $default,
        -force   => 1,
    );

    my @array = ( "Printer Group: ", Show_Tool_Tip( $printer, 'Specify group of printers (optional) - Details will appear following login, with option to change if desired.' ) );
    return \@array;
}

################################
# Display bottom bar for LIMS
# This should be customized for specific LIMS locales
################################
sub footer {
################################
    my $self   = shift;
    my %args   = @_;
    my $footer = $args{ -footer };
    my $dbc    = $self->{dbc};

    return qq(<hr><div class='footer'>$footer</div>\n);
}

###################
sub contact_info {
###################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'contact_id', mandatory => 'contact_id' );

    my $contact_id = $args{-contact_id};
    my $dbc = $args{-dbc} || $self->{dbc};

    eval "require alDente::Contact";
    eval "require alDente::Contact_Views";

    my $contact_Obj = alDente::Contact->new( -dbc => $dbc, -contact_id => $contact_id );

    my $col1 = $contact_Obj->collaborations( -contact_id => $contact_id );
    my $col2 = $contact_Obj->display_Record( -view_only  => 1 );

    my %colspan;
    $colspan{1}->{1} = 2;    ## set the Heading to span 2 columns
    return &Views::Table_Print( content => [ [ $col1, "&nbsp&nbsp&nbsp&nbsp", $col2 ] ], -colspan => \%colspan, -spacing => "10", print => 0 );

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
    require alDente::MVC_exceptions;
    my $branched = alDente::MVC_exceptions::non_MVC_run_modes( $dbc, $sid, \%params, 'alDente' );    ## PHASE OUT - previously embedded in barcode.pl ##
    if ($branched) { $dbc->debug_message("Deprecate use of non_MVC run mode") }
    else {
        ## PHASE OUT  ##
        require alDente::Button_Options;
        $branched = alDente::Button_Options::Check_Button_Options( -dbc => $dbc );
        if ($branched) { $dbc->debug_message("Deprecate use of Button Options") }
    }
    if ($branched) { print $branched }

    $dbc->Benchmark('tried_mvc_exceptions');

    return $branched;
}

#########################
sub contact_info {
#########################
    my $self = shift;

    my $output;
    $output .= "<U>GSC LIMS Team:</U>";
    $output .= "<UL>";
    $output .= "<LI>Eric Chuah</LI>";
    $output .= "<LI>Dean Cheng</LI>";
    $output .= "<LI>Ash Shafiei</LI>";
    $output .= "<LI>Athena Deng</LI>";
    $output .= "<LI>Patrick Plettner</LI>";
    $output .= "<LI>Tom Zhang</LI>";
    $output .= "<LI>Joseph Hong</LI>";
    $output .= "</UL>";
    $output .= "<P><A HREF='mailto:aldente\@bcgsc.ca'>Contact US</A>";

    $output .= '<HR>';
    $output .= "<U>Custom LIMS Installations:</U>";
    $output .= "<UL>";
    $output .= "<LI>Ran Guin</LI>";
    $output .= "</UL>";
    $output .= "<P><A HREF='mailto:rguin\@bcgsc.ca'>Contact US</A>";

    $output .= '<hr>';

    $output .= "<p>";
    $output .= "<P><A HREF='http://www.bcgsc.bc.ca'>Michael Smith Genome Sciences Centre</A>";

    #     $output .= &Link_To( "http://www.bcgsc.bc.ca", "Michael Smith Genome Sciences Centre" );
    $output .= "<p>";
    $output .= "<P><A HREF='http://www.bccancer.bc.ca'>BC Cancer Agency</A>";

    #     $output .= &Link_To( "http://www.bccancer.bc.ca", "BC Cancer Agency" );

    return $output;
}

1;
