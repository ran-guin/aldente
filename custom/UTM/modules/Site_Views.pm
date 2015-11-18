##################################################################################################################################
# UTM::Site_Views.pm
#
# Views Module for Tour Guide Site object class
#
###################################################################################################################################
package UTM::Site_Views;

use base LampLite::DB_Object_Views;
use Carp;

use strict;

use UTM::Site;

use RGTools::RGIO;
use LampLite::Bootstrap;
use LampLite::CGI;
use LampLite::HTML;

my $q = new LampLite::CGI;
my $BS = new Bootstrap();

#########################
sub single_record_page {
#########################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my $id   = $args{-id};
    my $dbc  = $self->dbc();
   
    my $context = 'Tour';
    
    my $page;
    if ($context =~/Site/) { 
        $page = $self->view_Site(-id=>$id);
    }
    else {
        $page = $self->view_Tour(-id=>$id);
    }

    return $page;
}   

################
sub view_City {
################
     my $self = shift;
     my %args = filter_input(\@_);

     my $id   = $args{-id};
     my $dbc  = $self->dbc();
       
     my $Tour = $self->Model->load(-id=>$id);  
    
     my ($toggle, $section) = $self->list_Sites(-id=>$id);
      
     my $page = $self->page_header(-id=>$id, -scope=>'Tour', -append=>$toggle);
     $page .= "<div class='site-content col-xs-12'>\n";
     
     $page .= "<hr></hr>\n";
     
     if ($Tour->{site_ids} && @{$Tour->{site_ids}}) {
         $page .= "<B><U>City Sites:</U></B>" . $section;
         if ( $self->edit_mode() && !$dbc->mobile() ) { $page .= $self->add_Sites($id, -Tour=>$Tour, -icon=>'plus') }
         
     }
     else {
         ## Add link to add sites ## 
         $page .= $dbc->warning("This Region does not yet have any defined sites or tours", -return_html=>1);
     }
     
     $page .= "</div>\n";

     return $page;
}

##################
sub list_Sites {
##################  
    my $self = shift;
    my %args = filter_input(\@_, -args=>'Tour');
    my $Tour = $args{-Tour};                              
    my $id   = $args{-id} || $args{-tour_id};                              
    my $dbc = $args{-dbc} || $self->{dbc};
    my $include_map = defined $args{-include_map} ? $args{-include_map} : 1;   
    my $add_link = $args{-add_link};   
    
    my $block;
    my (@ids, @sites);
    
    if ($Tour) { @ids = @{$Tour->{site_ids}} }
    elsif ($id) {  @ids = $dbc->get_db_array(-table=>'Site', -field=>'Site_ID', -condition=>"FK_Tour__ID = '$id'") }                        ## simply retrieve list of sites given id 
    else { @ids = $dbc->get_db_array(-sql=>"SELECT Site_ID FROM Site WHERE FK_Tour__ID IS NULL OR FK_Tour__ID = 0") }        ## find list of top level sites if no context is given
    
    foreach my $site (@ids) {
        push @sites, $self->site_link($site, 'Site', -context=>'List');
    }
        
    if ($add_link && $self->edit_mode() && !$dbc->mobile() ) { 
        push @sites, $BS->modal(
            -icon => 'plus',
            -title => "Define Site",
            -body  => $self->add_Site(-parent=>$id),
            -launch_type => 'button',
        );
    }

    my $list = Cast_List(-list=>\@sites, -to=>'UL');
    
    if (!$include_map) { return ($list, int(@sites)) }  ## simply return list if map is not included
    
    my @addresses = @{ $self->map_addresses(\@ids) };

    my ($width, $height,$scale, $zoom ) = (400, 400, 2);  ## figure this out dynamically ... ###
    
    my $map = $self->include_map(-width=>$width, -height=>$height, -zoom=>$zoom, -scale=>$scale, -markers=>\@addresses);

    my ($toggle, $section) = LampLite::HTML::toggle_section(
        -label=>[ 'Map', 'List'], 
        -tooltip=>['Display Map of Sites','Display List of Sites'], 
        -button_class=>'Default btn-lg', 
        -content=>[$map, $list],
        -separate=>1);
    
    return ($toggle, $section);
}

##################
sub list_Tours {
##################  
    my $self = shift;
    my %args = filter_input(\@_, -args=>'Tour');
    my $Tour = $args{-Tour};           
    my $id   = $args{-id} ||  $args{-site_id};                              
    my $dbc = $args{-dbc} || $self->{dbc};
    my $include_map = defined $args{-include_map} ? $args{-include_map} : 1;   
    my $add_link = $args{-add_link};   
    
    my $block;
    my (@ids, @sites);
    
    if ($id) {  @ids = $dbc->get_db_array(-sql=>"SELECT Tour_ID from Tour WHERE FK_Site__ID = '$id'") }                        ## simply retrieve list of sites given id 
    else { @ids = $dbc->get_db_array(-sql=>"SELECT Tour_ID FROM Tour WHERE FK_Site__ID IS NULL OR FK_Site__ID = 0") }        ## find list of top level sites if no context is given
    
    foreach my $site (@ids) {
        push @sites, $self->site_link($site, 'Tour', -size=>'xs', -context=>'list');
    }

 #   if ($add_link && $self->edit_mode() && !$dbc->mobile() ) { push @sites, $self->add_Sites($id, -Tour=>$Tour, -icon=>'plus'); }

    my $list = Cast_List(-list=>\@sites, -to=>'UL');
    
    if (!$include_map) { return ($list, int(@sites)) }
    
    my @addresses = @{ $self->map_addresses(\@ids) };

    my ($width, $height,$scale, $zoom ) = (400, 400, 2);  ## figure this out dynamically ... ###
    
    my $map = $self->include_map(-width=>$width, -height=>$height, -zoom=>$zoom, -scale=>$scale, -markers=>\@addresses);

    my ($toggle, $section) = LampLite::HTML::toggle_section(
        -label=>[ 'Map', 'List'], 
        -tooltip=>['Display Map of Sites','Display List of Sites'], 
        -button_class=>'Std btn-lg', 
        -content=>[$map, $list],
        -separate=>1);
    
    return ($toggle, $section);
}

#####################
sub map_addresses {
#####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');
    my $id = $args{-id};
    my $dbc = $self->{dbc};
    
    my @ids = Cast_List(-list=>$id, -to=>'array');
    
    my @addresses;
    foreach my $id (@ids) {
        my @address = $dbc->get_db_array(-sql=>"SELECT DISTINCT Site_Address FROM Site WHERE Site_ID = '$id' AND Length(Site_Address) > 0");
        if (!@address) {
            my $parent = $dbc->get_db_value(-sql=>"SELECT FK_Site__ID FROM Tour WHERE Site_ID = '$id' AND Site.FK_Tour__ID=Tour_ID");
            if ($parent) { @address = @{ $self->map_addresses($parent)} }
        }
        if (@address) { push @addresses, @address }
    }
    
    map { $_ =~s/\s/\+/g } @addresses;
    
    return \@addresses;
}

#################
sub include_map {
#################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');
    my $height = $args{-height};
    my $width = $args{-width};
    my $scale = $args{-scale};
    my $zoom = $args{-zoom};
    my $markers = $args{-markers};
    my $centre  = $args{-centre};
    

    my $param = "size=${width}x${height}";
    if ($centre) { $param .= "&center=$centre" }
    if ($zoom) { $param .= "&zoom=$zoom" }
    if ($scale) { $param .= "&scale=$scale" }
    
    if ($markers) {
        foreach my $marker (@$markers) {
            $param .= "&markers=C$marker";
        }
    } 

my $map =<<MAP;
    
<div width='500px' height='500px' id='map-canvas'>
    <img src="//maps.googleapis.com/maps/api/staticmap?$param&sensor=false"></img>
</div>
    
MAP

return $map;
}

###############
sub add_Sites {
###############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');
    my $Tour = $args{-Tour};
    my $tour_id   = $args{-id} || $Tour->{id};
    my $label = $args{-label};
    my $icon  = $args{-icon}; 
    my $dbc  = $self->dbc();
    
    my $Form = new LampLite::Form(-dbc=>$dbc, -span=>[4,8]);

    $Form->append( 
        -label=>'How Many Site(s) / Tour(s) would you like to add to ' . $Tour->field('Site_Name') . ' ? ', 
        -input=>$BS->dropdown(-name=>'N Sites', -values=>[1..20], -class=>'short-txt', -tooltip=>"Just add 1 if you are only defining a new Tour\n...or add multiple tours at once and add sites later...")
        );

    my $fields = $dbc->fields('Site');
        
    $Form->append( 
        -label=>'Include Fields: (optional)', 
        -input=>$BS->dropdown(-name=>'Fields', -values=>$fields, -type=>'multi')
    );
    
    $Form->append(
        -label=> '',
        -input=>$q->submit( -name=>"Continue", -class=>'Std btn-lg', -tooltip=>'Add Sites (you can add more later if you need to)') .
        $q->submit( -name=>"Cancel", -class=>'Std btn-lg', -onclick=>"HideElement('NewSiteOptions'); return false;")
    );
    
    $Form->append( 
        $Form->View->prompt(-table=>'Site', -field=>'Site_Type', -label=>"Primary Site  Type:", -tooltip=>'Select the primary type of sites you are adding')
    );    

    my $options = $Form->generate(-open=>0, -close=>0) ;

    my ($toggle, $popup);
     if ( $self->edit_mode() && !$dbc->mobile() ) { 
         ($toggle, $popup) = LampLite::HTML::toggle_section(-label=>$label, -icon=>['plus','minus'], -tooltip=>'Add Tours / Sites to this Tour', -content=>$options);
     }
    
    my $add_sites = $BS->modal(
        -icon => 'plus',
        -title => "Define Site",
        -body  => $self->add_Site(-parent=>$tour_id),
        -launch_type => 'button',
        );

    my $Form = new LampLite::Form(-dbc=>$dbc);

    my $add = $Form->start_Form(-name=>'add')
        . $q->hidden(-name=>'cgi_application', -value=>'UTM::Site_App', -force=>1) 
        . $q->hidden(-name=>'rm', -value=>'Add New Site', -force=>1) 
        . $q->hidden(-name=>'FK_Tour__ID', -value=>$tour_id, -force=>1)
        . $q->hidden(-name=>'Debug', -value=>1, -force=>1)
        . $toggle . $popup
        . $add_sites
        . $q->end_form();
       
    return $add_sites;
}

################
sub site_link {
################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id,scope');
    my $id = $args{-id};
    my $scope = $args{-scope} || 'Site';
    my $append = $args{-append};
    my $context = $args{-context};
    my $size   = $args{-size} || 'xs';
    
    my $dbc = $self->{dbc};
 
    my $field_info = $dbc->{Field_Info};

    my $name = $dbc->get_db_value(-sql=>"SELECT ${scope}_Name from $scope WHERE ${scope}_ID = '$id'");

    my $link;
            
    if ($scope eq 'Tour') {
        my $parent_site = $self->Model->field('Site_ID');
        if ($parent_site && $context !~/(list|path)/i) {
            $link .= $self->button_link(-icon=>'caret-up', -scope=>'Site', -id=>$parent_site, -size=>'xs', -tooltip=>"Return to Site");
            $link .= "\n<P>\n";
         }
        
        $name =~s/ Tour$//;
        $name = "$name Tour"; ## include Tour in name if this is the scope ... 

        $link .= $self->button_link(-label=>$name, -scope=>$scope, -id=>$id, -size=>$size, -class=>"utm-$scope", -tooltip=>"Go to $scope: $name");
    }
    else {
        $link = Link_To($dbc->homelink(),"<B>$name</B> $append","&cgi_app=UTM::Site_App&rm=View $scope&ID=$id", -tooltip=>"Go to $scope: $name");
    }
   
    if ( $self->host() ) {
        my $Form = new LampLite::Form(-dbc=>$dbc); 
        my $FV = $Form->View();       
        $link .= $BS->modal(
            -label => $BS->icon('edit',-colour=>'red'),
            -title => "Edit $scope [$id] Details",
            -body  => $FV->edit_Records(-table=>$scope, -id=>$id),
            -size=>'xs',
            );
    }

    if ($context !~/List/i) { return $link }
    
    ## section below branches out downstream hierarchy - only include for list views ##
    
    if ($scope eq 'Tour') {   
        my $tour_link = $self->site_link(-id=>$id, -scope=>'Tour', -context=>'Tour');
        my ($sites, $count) = $self->list_Sites(-id=>$id, -include_map=>0);
        
        if ($sites) { 
            my ($toggle, $sites_link) = LampLite::HTML::toggle_section(-label=>["$count Sites"], -icon=>['plus-circle','minus-circle'], -button_class=>'x', -content=>[  $sites ]);
            $link .= $toggle . $sites_link;
        }
#             
#        $link .= " [$count Sites]";
    }
    else {
        my $site_link = $self->site_link(-id=>$id, -scope=>'Site', -context=>'Site');
        my ($tours, $count) = $self->list_Tours(-id=>$id, -include_map=>0);
        
        if ($tours) { 
            my ($toggle, $tours_link) = LampLite::HTML::toggle_section(-label=>["$count Tours"], -icon=>['plus-circle','minus-circle'], -button_class=>'x', -content=>[  $tours ]);
            $link .= $toggle . $tours_link;
        }
#        $link .= " [$count Tours]";
    }

    return $link;
}

######################
sub start_tour_link {
######################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'tour_id,scope');
    my $tour_id = $args{-tour_id};
    my $site_id = $args{-site_id} || $self->Model->field('FK_Site__ID');

    my $disabled;
    my $sites = $self->Model->{site_ids};
    if (!$sites) { $disabled = 'disabled' }

    my $name = $self->Model->field('Tour_Name');
 
    my $starting_site = $sites->[0];
    $name =~s/ Tour$//i;  ## truncate redundant tour name if included ... 
    
    my $link = $self->button_link(-label=>"Start $name Tour", -id=>$starting_site, -scope=>'Site', -disabled=>$disabled, -class=>'Std')
        . $self->button_link(-label=>"Finish $name Tour", -id=>$site_id, -scope=>'Site', -class=>'Action');

    return $link;
}

################
sub view_Site {
################
    my $self = shift;
    my %args = filter_input(\@_);
    my $id   = $args{-id};
       
    $self->dbc->Benchmark('startSiteView');
    my $load_tour = $args{-load_tour} || 1;

    my $dbc  = $self->dbc();  

    if (!$id) { return UTM::Login_Views->home_page(-dbc=>$dbc) } 
    
    if ($load_tour) {
        my $parent = $dbc->get_db_value(-sql=>"SELECT FK_Tour__ID FROM Site WHERE Site_ID = $id");
        if ($parent) {
            return $self->layered_Sites(-tour_id=>$parent, -active=>$id);
        }
    }

    my $Site = $self->Model->load(-site_id=>$id);  

    my $page = $self->page_header(-id=>$id, -scope=>'Site');

    my $description =  $Site->field('Site_Description');

    my $media = $self->media(-site_id=>$id);
    if ($media) { $page .= '<hr>' . $media }
    
    $self->dbc->Benchmark('endSiteView');
       
    return $page;
}

################
sub view_Tour {
################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');

    my $id   = $args{-id};
    my $dbc  = $self->dbc;

    $self->dbc->Benchmark('startTourView');

    my $Tour = $self->Model->load(-tour_id=>$id);  

    my $page;

    my ($toggle, $section) = $self->list_Sites(-tour_id=>$id, -add_link=>1);

    $page = $self->page_header(-id=>$id, -scope=>'Tour', -append=>$toggle);

    $page .= "<div class='site-content col-xs-12'>\n";
    $page .= "<hr></hr>\n";

    my $desc = $dbc->get_db_value(-table=>'Tour',-field=>"Tour_Description", -condition=>"Tour_ID = $id");
    $page .= $desc . '<hr></hr>';

    $page .= $section;
    $page .= "</div>\n";

    my $media = $self->media(-tour_id=>$id);
    if ($media) { $page .= '<hr>' . $media }

    $self->dbc->Benchmark('endTourView');
    
    return $page;
}

############
sub media {
############
    my $self = shift;
    my %args = filter_input(\@_);
    my $site_id = $args{-site_id};
    my $tour_id = $args{-tour_id};
    
    my $dbc = $self->{dbc};

    my $media_path = $dbc->config('media_data_dir') . '/' . $dbc->{dbase};
    my $relative_path = $dbc->config('media_url_dir') . '/' . $dbc->{dbase};
    
    if ($site_id) { 
        $media_path .= "/Site/$site_id";
        $relative_path .= "/Site/$site_id";
    }
    elsif ($tour_id) { 
        $media_path .= "/Tour/$tour_id";
        $relative_path .= "/Tour/$tour_id";
    }
    
    ## for now just get mp3 .. adjust to extract different file types ##
    my ($file_found) = split "\n", `ls $media_path/Audio.*`;
    if (!$file_found) { return "(no audio available)" }

    my $file = "$relative_path/Audio.mp3";
    
    my $type;

    if ( $file =~/\.mp3$/) { $type = "audio/mpeg"; }
    elsif ( $file =~/\.(.+)$/ ) { $type = "audio/" . lc($1) }  ## wav or ogg 

    my $audio = qq(
        <audio controls style='width:100%'>
        <source src="$file" type="$type">
        Your browser does not support the audio element.
        </source>
        </audio>
        );
        return $audio

}

####################
sub layered_Sites {
####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');
    my $Tour = $args{-Tour};
    my $tour_id   = $args{-tour_id};
    my $active = $args{-active};
    my $dbc  = $self->{dbc};
    
    $Tour ||= $self->Model->load(-tour_id=>$tour_id);  
    my @sites = @{$Tour->{site_ids}};

    my $page;
    if (@sites) {
        $page = $self->layered_page_header(-Tour=>$Tour, -active=>$active, -scope=>'Tour');

        $page .= "<div class='site-content col-xs-12'>\n";
        $page .= "<hr></hr>\n";
        
        my %layers;
        $active ||= $sites[0];

         foreach my $site (@sites) {   
            my $site_page = $self->body(-site_id=>$site);
            
            my $media = $self->media(-site_id=>$site);
            if ($media) { $site_page .= '<hr>' . $media }
            
            my $style;
            if ($active eq $site) { $style = 'display:block' }
            else { $style = 'display:none'}
            
            $page .= "\n<div id='Site$site-page' style='$style' class='col-xs-12'>\n$site_page\n</div>\n";
        }     
        $page .= "</div>\n";
    }
    else {
        $page .= $self->view_Tour(-id=>$tour_id);
    }

    return $page;
}

###################
sub page_header {
###################
    my $self = shift;
    my %args = filter_input(\@_);
    my $id   = $args{-id};
    my $scope = $args{-scope};
    my $append = $args{-append};

    my $dbc  = $self->dbc();

    if (!$id) { $id = 5; $scope = 'Tour' }  ## default home page ...
    
    my %info;
    my $header;
    my $next_line;

    if ($scope eq 'Tour') {
        my @path = $self->path($id);

        $header .= $BS->path(\@path, 'display:inline-block; width:100%;');
        $next_line .= $append;

        $scope = 'Tour';
        my $ids = Cast_List(-list=>$self->Model->{site_ids}, -to=>'string');
        $next_line .= $self->start_tour_link($id);
    }
    else {
        my $next_id = $id+1;
        my $last_id = $id-1;
        my @path = ( $self->site_link( $id, 'Site', -context=>'Header') );
        
        $header .= $self->button_link(-icon=>'chevron-left', -id=>$last_id ,-scope=>'Site', -tooltip=>'Next Site');
        $header .= $BS->path(\@path, 'display:inline-block; width:80%');
        $header .= $self->button_link(-icon=>'chevron-right', -id=>$next_id ,-scope=>'Site', -tooltip=>'Previous Site');
        
        if ($self->Model->{site_ids} && @{$self->Model->{site_ids}}) {
            $next_line = Link_To($dbc->homelink(), ' [go to Tour]', "&cgi_application=UTM::Site_App&rm=View Tour&ID=$id");  
        }
    }   
     
    if ($next_line) { $header .= '<BR>' . $next_line }
     
    return $header;  
}
# Deprecated... #
#################
sub edit_link {
#################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');
    my $scope = $args{-scope};

    my $id = $args{-id};
    my $dbc = $self->{dbc};
        
    my $tooltip;
    if ($scope eq 'Site') { $tooltip = "Edit this single site (Go to the tour page to edit all of the sites if applicable)" }
    else { $tooltip = "Edit sites for this tour" }
    my $link = Link_To($dbc->homelink(), " [Edit $scope]", "&cgi_application=LampLite::Form_App&rm=Edit Records&Class=Site&ID=$id&Preset=Site_ID&Site_ID=<ID>", -tooltip=>$tooltip);
    
    return $link;
}

##########################
sub layered_page_header {
##########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $Tour = $args{-Tour};
    my $tour_id   = $args{-tour_id} || $Tour->{tour_id};
    my $active = $args{-active};
    
    my $dbc  = $self->dbc();

    my $info = $dbc->hash(-table=>'Site', -condition => "FK_Tour__ID = $tour_id ORDER BY Site_ID");
    if (!$info) { return $dbc->warning("Could not Retrieve Tour $tour_id", -return_html=>1) }
    
    my $header = "<div id='Tour$tour_id-header' class='col-xs-12'></div>";

    $Tour ||= $self->Model->load(-id=>$tour_id, -scope=>'Tour');

    my $name = $Tour->field('Site_Name');

    my $tour = $self->site_link($tour_id, 'Tour', -context=>'layered Header'); ## Link_To($dbc->homelink(), $name . 'aa', "cgi_app=UTM::Site_App&rm=View Tour&ID=$id");

    my $host = $Tour->access(-tour_id=>$tour_id);
    
    my $i = 0;

    my @sites = @{$Tour->{site_ids}} if $Tour->{site_ids};
    my $site_count = @sites;

    while ( defined $info->{Site_ID}[$i]) {
        my $site_id = $info->{Site_ID}[$i];
        my $site_name = $info->{Site_Name}[$i];
        
        my $path = $tour;
        
        my $N_Site = new UTM::Site(-dbc=>$dbc, -id=>$site_id);
        
        my $next_id = $info->{Site_ID}[$i+1];
        my $last_id = $info->{Site_ID}[$i-1];
         
        if ($site_id == $info->{Site_ID}[-1] ) { $next_id = $site_id }
        if ($i == 0) { $last_id = $site_id }
        
        my $position = $i+1 . "/$site_count";

        my $home = $self->site_link($site_id, 'Site', -append=> "[$position]", -context=>'layered header');
        
        my  @subsites = $self->Model->children(-site_id=>$site_id);

        my $redirect_button;

        if (@subsites && $subsites[0]) {
            my $redirect;
            foreach my $subsite (@subsites) {
                $redirect .=  $N_Site->View->button_link( -label=>"Take $site_name Tour", -size=>'xs', -app=>"UTM::Site_App", -rm=>"View Tour", -id=>$subsite, -tooltip=>"Take $site_name Tour");
            }
            $redirect_button = $BS->modal(-label=>'<B>T</B>', -launch_type=>'button', -class=>'utm-Tour', -body=>$redirect, -title=>"Redirect to $site_name Tour(s)", -tooltip=>"Redirect to Tour for $site_name");            
        }
        
        if ( $self->host() ) {
#            my $add_tour_link = Link_To($dbc->homelink(), "Define $site_name Tour ", "&cgi_application=UTM::Site_App&rm=View Tour&ID=$site_id", -tooltip=>"Generate $site_name Tour"); ;
#            $path .= '<BR>' . $BS->icon('arrows-v') . '<BR>' . $add_tour_link ;

            my $redirect =  $N_Site->View->button_link( -label=>"Define New Tour for '$site_name'", -size=>'xs', -app=>"UTM::Site_App", -rm=>"Add Tour", -id=>$site_id, -tooltip=>"Add Tour");   
            $redirect_button .= ' ' . $BS->modal(-label=> "<Font color='red'>Add Tour</Font>",  -body=>$redirect, -title=>"Redirect to $site_name Tour(s)", -tooltip=>"define new Tour for $site_name");
        }
            
        my $N_site = &Views::Table_Print( 
            content=> 
                [[ $N_Site->View->button_link(-icon=>'chevron-left', -id=>$last_id ,-scope=>'Site', -onclick=> change_page($site_id, $last_id), -tooltip=>'Previous'), 
                    "<center>$path</center>",
                    $N_Site->View->button_link(-icon=>'chevron-right', -id=>$next_id ,-scope=>'Site', -onclick=> change_page($site_id, $next_id), -tooltip=>'Next')
                ]],
                print => 0, 
                align => ['','','right']
            );
                
        if ($home) { $N_site .= '<BR>' . $home . "\n" }
        
        my $style;
        if ($active && $active == $site_id) { $style = "display:block" }
        else { $style = 'display:none' }
        
        $header .= "\n<div id='Site$site_id-header' style='$style;' class='col-xs-12 utm-title'>\n"
            . $self->page_title("$N_site $redirect_button")
            . "</div>\n";
        
        $i++;
    }

    return $header;
    
}

#################
sub page_title {
#################
    my $self = shift;
    my $title = shift;

    my $tag = 'h4';
    return qq(<$tag>$title</$tag>);
}

############
sub host {
############
    my $self = shift;
    my $dbc = $self->dbc();
    
    if ($dbc->config('utm_access_mode') =~ /(host|admin)/i) { return 1 }
    else { return 0 }
    
}

#
#################
sub change_page {
#################
    my $id = shift;
    my $new_id = shift;
    
    my $onclick = "HideElement('Site$id-header'); "
        . "unHideElement('Site$new_id-header'); "
       . "HideElement('Site$id-page'); "
        . "unHideElement('Site$new_id-page'); "
        . " return false; ";
        
    return $onclick;
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
    my $onclick = $args{-onclick};
    my $tooltip = $args{-tooltip};
    my $disabled = $args{-disabled};
    my $app = $args{-app} || 'UTM::Site_App';
    my $rm  = $args{-rm}  || "View $scope";
    my $size = $args{-size} || 'lg';
    my $class = $args{-class} || 'Default';
    my $style = $args{-style};

    my $dbc = $self->dbc();
    
    my $scope = 'Site';
    
    my @options = Cast_List(-list=>$id, -to=>'array');
    
    if (@options > 1) {
        my $content;
        foreach my $option (@options) {
            my %pass_args = %args;
            $pass_args{-id} = $option;
            $content .= $self->button_link(%pass_args) . '<P></P>';
        }
        
        my $modal = $BS->modal(
            -label => 'go to tour',
            -title => "Define Site",
            -body  => $content,
            -launch_type => 'button',
        );
        
        return $modal;
    }
    
    $id = $options[0];
    my $link = $dbc->homelink();
    $link .= "&cgi_app=$app&rm=$rm&ID=$id";
    
    my $button = "<A Href='$link' >";
    $button .= $BS->button(-label=>$label, -icon=>$icon, -onclick=>$onclick, -class=>"$class btn-$size", -style=>$style, -tooltip=>$tooltip, -disabled=>$disabled);
    $button .= "</A>";
    
    return $button;
}


################
sub path {
################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'tour_id');
    my $tour_id   = $args{-tour_id};
    my $dbc = $self->dbc();

    my @path;
    my $follow = $tour_id;
    
    my $count;
    while ($follow && $count <= 5) {
        unshift @path, $self->site_link( $follow, 'Tour', -context=>'path');
        
        $follow = $dbc->get_db_value(-sql=>"SELECT FK_Tour__ID FROM Site, Tour WHERE Site_ID=Tour.FK_Site__ID AND Tour_ID = '$follow'");
        $count++;
    }
    
    return @path;
}

###########
sub body {
###########
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');
    my $site_id = $args{-site_id};
    my $tour_id = $args{-tour_id};
    my $dbc = $self->{dbc};
    
    my ($scope, $id, $desc);
    if ($site_id) {
        $scope = 'Site';
        $id = $site_id;
    }
    elsif ($tour_id) {
        $scope = 'Tour';
        $id = $tour_id;
    }

    $desc = $dbc->get_db_value(-table=>$scope,-field=>"${scope}_Description", -condition=>"${scope}_ID = $id");

    $desc ||= 'descript';
    my $image = $self->image($id, -scope=>$scope);

    my $body;
    if ($image) { 
        $body .= "<div class='site-image'>\n$image</div> <!-- End of Site Image -->\n";
        $body .= "<div class='site-text'>\n$desc</div> <!-- End of Site Text -->\n";
    }
    else {
        $body .= "<div class='site-text-only'>\n$desc</div> <!-- End of Site Text -->\n";        
    }

    return $body;
}

#
# Access Tour or Site images.
#
# Usage:  
#
#  print $self->image(-scope=>'Tour', -id=>$tour_id);
#  print $self->image(-scope=>'Site', -id=>$site_id);
#
# Return: Single image or carousel if multiple images available 
#############
sub image {
#############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'id');
    my $id   = $args{-id} || $self->{id};
    my $scope = $args{-scope};
    my $dbc = $self->{dbc};

    my $image = $dbc->get_db_value(-table=>$scope, -field=>'Image_Name', -condition=>"${scope}_ID = $id");
    
    my $image_path = $dbc->config('url_root') . "/dynamic/media/" . $dbc->config('dbase') . "/$scope/$id";
    
    if ($image) { 
        my @extra_images = map { "$image_path/" . $_ } grep /.+/, $dbc->get_db_array(-table=>"${scope}_Image", -field=>'Image_Name', -condition=>"FK_${scope}__ID = $id");
        if (@extra_images) { 
            return $BS->carousel([ "$image_path/$image", @extra_images]);
        }
        else {
            return "<IMG Src='$image_path/$image' style='max-width:80%'></IMG>";
        }
    } 
    
    return '';
}

###############
sub add_Site {
###############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'parent');
    my $parent = $args{-parent};
    
    my $fields = $args{-fields};
    my $type   = $args{-type};
    
    my $dbc = $self->{dbc};
    
    my $page = section_heading("Define Site");

    my $style = 'vertical';
    
    my $Form = new LampLite::Form(-dbc=>$dbc, -title=>'New Tour');
    
    my $Hidden = { 'Site_ID' => '', 'Site_Status' => 'Pending' };
    my $Default = { 'Site_Type' => $type };
    my $Preset = { 'FK_Tour__ID' => $parent };
    
    $Form->append_fields(-table=>'Site', -default=>$Default, -preset=>$Preset, -hidden=>$Hidden, -index=>1, -style=>$style, -fields=>$fields);
    
    my $include = $q->hidden(-name=>'cgi_app', -value=>'UTM::Site_App', -force=>1);
        
    $include .= $q->hidden(-name=>'rm', -value=>'Save New Site(s)', -force=>1) . $q->submit(-name=>'Save', -class=>'Std btn-lg');
    
    $include .= $q->checkbox(-name=>'Debug', -value=>1, -force=>1);
    $page .= $Form->generate(-open=>1, -close=>1, -include=>$include);
    
    return $page;
}

###############
sub add_Tour {
###############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'parent');
    my $parent = $args{-parent};
    my $N      = $args{-N} || 1;       ### number of tours / sites to add at once ... 
    my $fields = $args{-fields};
    my $type   = $args{-type};

    my $dbc = $self->{dbc};

    my $page = section_heading("Add Tour(s)");

    my $style = 'vertical';
    if ($N > 1) { $style = 'horizontal'}

    my $Form = new LampLite::Form(-dbc=>$dbc, -title=>'New Tour', -type=>'horizontal');
    
    my $Hidden = { 'Tour_ID' => '', 'FK_Site__ID' => $parent };
    my $Default = { };
    my $Preset = {};
    
    foreach my $i (1..$N) {
        $Form->append_fields(-table=>'Tour', -default=>$Default, -preset=>$Preset, -hidden=>$Hidden, -index=>1, -style=>$style, -id_suffix=>$i, -fields=>$fields);
    }
    
    my $include = $q->hidden(-name=>'FK_Site__ID', -value=>$parent, -force=>1)
         . $q->hidden(-name=>'cgi_app', -value=>'UTM::Site_App', -force=>1);
        
    $include .= $q->hidden(-name=>'rm', -value=>'Save New Tour(s)', -force=>1) . $q->submit(-name=>'Save', -class=>'Std btn-lg');
    
    $include .= $q->checkbox(-name=>'Debug', -value=>1, -force=>1);
    $page .= $Form->generate(-open=>1, -close=>1, -include=>$include);
    
    return $page;
}
  

################
sub setup_map {
################

    my $block = <<TOOLTIPS;

    <script type="text/javascript">
      \$(document).ready(function () {
        \$("[rel=popover]").popover({
            html: 'true',
            placement: function(a, element) {
                    var position = \$(element).position();
                     if (position.top < 250){
                        return "bottom";
                    }
                    if (position.left > 515) {
                        return "left";
                    }
                    if (position.left < 515) {
                        return "right";
                    }
                    return "top";
                },
            });
      });
    </script>

    <script type="text/javascript">
      \$(document).ready(function () {
        \$("[rel=tooltip]").tooltip();
      });
    </script>

TOOLTIPS

    return $block;
}  


sub init_map2 {
    
    my $lat = "-34.397";
    my $long = "200.644";
    my $zoom = "8";
    
    my $js_block = qq(
        <style>
                            #map-canvas {
                                              height: 500px;
                                                     margin: 20px;
                                                              padding: 20px
                                                                    }
        </style>
    <script src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false"></script>
    
        
    <script>
                                                                           var map;
                                                                           function initialize() {
                                                                                 var mapOptions = {
                                                                                         zoom: $zoom,
                                                                                         center: new google.maps.LatLng($lat, $long)
                                                                                           };
                                                                                                 map = new google.maps.Map(document.getElementById('map-canvas'),
                                                                                                       mapOptions);
                                                                           }
     
                                                                           google.maps.event.addDomListener(window, 'load', initialize);
     </script>
);

return $js_block;
}
    
################
sub edit_mode {
################
    my $self = shift;
    my $dbc = $self->dbc;
    
    my $access = $dbc->config('utm_access_mode');
    if ($access =~/Host|Admin/i) { return 1 }
    
    return 0;
}
    
sub init_map {

    my $init_script =<<INIT;
// <html manifest='../cache/manifest.pl'>
<meta charset="utf-8">
<meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=no, width=device-width">
<meta name="apple-mobile-web-app-capable" content="yes">

<LINK rel=stylesheet type='text/css' href='../css/mobile.css'>
<LINK rel='stylesheet' type='text/css' href='../css/socio.css'>

<script type="text/javascript"
      src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCsyK7DfqGJs73u4qpS2iEKDOdnp6SJxzQ&sensor=true">
</script>

<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6/jquery.min.js"></script>

<script src='../js/socio.js'></script>
<script src='../js/guide.js'></script>
<script src='../js/map.js'></script>
<script src='../js/iscroll.js'></script>
<script src='../js/contact_scroll.js'></script>

	<script type="text/javascript">
		/* Local JavaScript Here */
		var initScrolling = function() {
			var scroller = new iScroll('scroller', { bounceLock:true, desktopCompatibility: true});
			var buttons = document.getElementsByClassName("button");
			for (var i = 0, len = buttons.length; i < len; i++) {
				buttons[i].addEventListener("touchstart", function() {
					this.className = "button touched";
				});
				buttons[i].addEventListener("touchend", function() {
					this.className = "button";
				});
			}
		};
		document.addEventListener('DOMContentLoaded', initScrolling, false);
	</script>

INIT

    return $init_script;
}

return 1;

__END__;
##############################
# perldoc_header             #
##############################
=head1 NAME <UPLINK>

<module_name>

=head1 SYNOPSIS <UPLINK>

Usage:

=head1 DESCRIPTION <UPLINK>

<description>

=for html

=head1 KNOWN ISSUES <UPLINK>
    
None.    

=head1 FUTURE IMPROVEMENTS <UPLINK>
    
=head1 AUTHORS <UPLINK>
    
    Ran Guin

=head1 CREATED <UPLINK>
    
    <date>

=head1 REVISION <UPLINK>
    
    <version>

=cut
