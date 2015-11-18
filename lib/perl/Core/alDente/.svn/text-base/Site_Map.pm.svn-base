#############################################################################
#
# Site_Map.pm
#
# This module handles specific Button options
#
#########################sw#######################################################
# $Id: Button_Options.pm,v 1.428 2004/12/15 20:19:30 echuah Exp $
################################################################################
package alDente::Site_Map;

use SDB::CustomSettings;
use RGTools::Views;
use RGTools::RGIO;

use YAML;
use strict;

#####################
sub new {
#####################
    my $this = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $link = $args{-link};
    my $mode = $args{-mode};
    my $open = $args{-open};

    if ($mode) { $link .= "&Database_Mode=$mode" }

    my $self = {};   ## if object is NOT a DB_Object ... otherwise...
    $self->{dbc} = $dbc;
    $self->{link} = $link;
    $self->{open} = $open;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}  

##############################
# perldoc_header             #
##############################
#####################
#
# This map should enable users to find help on how to accomplish tasks and/or direct them to the applicable pages.
#
#
########################
sub default_site_map {
########################
    my %args = filter_input(\@_);
    my $link = $args{-homelink};
    
    my $site_map = &Views::Heading('Site Map');    
    
    $site_map .= &Views::sub_Heading( 'Defining New Objects', -1 );
    $site_map .= "<UL>";
    foreach my $object ( 'Project', 'Library', 'Source', 'Plate', 'Solution', 'Primer', 'Vector', 'Contact', 'Organization', 'Employee' ) {
        $site_map .= "<li>" . &Link_To( $link, $object, "&New+Object=$object" );
    }
    $site_map .= "</ul>";

    $site_map .= &Views::sub_Heading( 'Plates', -1 );
    $site_map .= "<UL>";
    foreach my $branch ( 'Find', 'Edit', 'Move' ) {
        $site_map .= "<li>" . &Link_To( $link, $branch, "&Home=Plate&Action=$branch" );
    }
    $site_map .= "</ul>";

    $site_map .= &Views::sub_Heading( 'Solutions', -1 );
    $site_map .= "<UL>";
    foreach my $branch ( 'Mix Standard Solution', 'Mix N Reagents', 'Find', 'Edit', 'Move', 'Move' ) {
        $site_map .= "<li>" . &Link_To( $link, $branch, "&Home=Solution&Action=$branch" );
    }
    $site_map .= "</ul>";

    return $site_map;
}

#
# Build or access site_map 
#
####################
sub site_map {
###############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'type,chapter');
    my $chapter = $args{-chapter};
    my $type    = $args{-type} || 'Site Map';
    
    my $file;
    if ($0 =~/^(.*)\/cgi-bin\/Site_Map.pl/) { $file =  "$1/conf/" }   ## temporarily access base directory ##
    my $site_map_file = "$file/map.yml";

    my $site_map = YAML::LoadFile($site_map_file);

    my $legend = "<B><U>Legend:</U></B><P>";
    my $description;
    if ($type =~/Site/) {
        $description = "Aid to help navigate directly to various parts of the interface";
        $legend .= alDente::Web::image('arrow.png', -height=>15) . &hspace(5) . ' Navigate to Applicable Section in Interface <BR>';
    }
    elsif ($type =~/Help/) {
        $description = "Quick access to short list of help topics & instructions - see manual for full guide";
        $legend .= alDente::Web::image('help.gif', -height=>15) . &hspace(5) . ' Display Help on Topic <BR>';       
    }
    
    use SDB::HTML;
    my $page = &Views::Heading("$type - $description",'bgcolor=lightblue');

    $legend .= alDente::Web::image('warning.jpg', -height=>15) . &hspace(5) . ' Under Construction - (feel free to contact LIMS to prioritize any of these pages you are interested in seeing)<BR>';
    $page .= $legend;
    $page .= '<HR>';    

    
    my @elements = @{$site_map->{$type}};
    foreach my $element (@elements) {
        $page .= $self->site_map_element($element);
    }
    
    return $page;
    
}

#######################
sub site_map_element {
#######################
    my %args = filter_input(\@_, -args=>'element,link,level', -self => 'alDente::Site_Map');
    my $self = $args{-self};
    my $element = $args{-element};
    my $link    = $args{-link};
    my $level   = $args{-level} || 0;

    my $open = ($level > 1);          ## default to keep everything after the first level open... 
   
    my $home = 'cgi-bin/site_map.pl';
   
    my $homelink = 'Site_Map.pl';

    my $header = 'h3';

    if (!defined $element) { return Link_To('undefined_link', $link . '&nbsp'. alDente::Web::image('warning.jpg', -height=>15)) . "<BR>" }

    my @Colours = ('#AAAAFF','AAFFAA','#FFAAAA','#AAFFFF','#FFFFAA','FFAAFF');
    my $Hclass = "bgcolor='lightblue'; ## $Colours[$level]";

    my $block = '';
    if (ref $element eq 'ARRAY') { 
               
        my $list = &Views::Heading("$link", $Hclass);
        $list .= "<OL>";
        foreach my $elem (@$element) {
            $list .= '<LI>' . $self->site_map_element($elem, $elem, $level+1);
            $list .= "\n";
        }
        $list .= "</OL>\n";
        
        my $default_open;
        if ($open) { $default_open = $link }
        $block .= create_tree(-tree=>{ $link => $list}, -style=>'expand', -default_open=>[$default_open]);
    }
    elsif (ref $element eq 'HASH') {
        my @keys = keys %$element;
        my @values = values %$element;

#        if ($link && ! ref $link) { $block .= &Views::Heading("$link", $Hclass) }
        if (int(@keys) == 1 && int(@values) == 1) {
            $block .= $self->site_map_element($values[0], $keys[0], $level+1);
        }
        else { 
            
            my $list = &Views::Heading("$link", $Hclass);
            $list .= "<UL>";
            foreach my $i (0..$#keys) {
                $list .=  '<LI>';
                $list .= $self->site_map_element($values[$i], $keys[$i], $level+1);
            }
            $list .= "</UL>\n";
            
            my $default_open;
            if ($open) { $default_open = $link }

            $block .= create_tree(-tree=>{ $link => $list}, -style=>'expand', -default_open=>[$default_open]);
        }
    }
    elsif (ref $element) {
        Message("REF: " . ref $element);
    }
    else {
         $block .= $self->generate_link($element, $link);
    }
    
   return $block;
}

###################      
sub generate_link {
###################
    my $self = shift;

    my $element = shift;
    my $link    = shift;
    
    my $ref = "$Configs{web_dir}/docs/out/$element";  ## look for standard documentation file ##

    my $block;
    if ($element =~/^http/) {
        ## fully qualified link ##
        $block .= Link_To($element, $link . '&nbsp'. alDente::Web::image('help.gif', -height=>15));
    }
    elsif ($element =~ /(.*\.html)(\#.*|)$/) {
        ## Link to chapter in local manual ##
        my $anchor = $2;
        if ($anchor) { $ref =~s/$anchor$//; }
        
        if (-e $ref ) {
            $block .=  Link_To("http://limsmaster/SDB/docs/out/$element", $link . '&nbsp'. alDente::Web::image('help.gif', -height=>15));
        }
        else {
            $block .= Link_To("http://limsmaster/SDB/docs/out/$element", $link . '&nbsp'. alDente::Web::image('warning.jpg', -height=>15)); 
        }
    }
    elsif ($element ne $link) {
        ## Link to page in current session ##
        my $ref = "$self->{link}&$element";
        $block .= Link_To($ref, $link . '&nbsp'. alDente::Web::image('arrow.png', -height=>15), -tooltip=>'Navigate to this link'); 
    }
    else {
        ## link is undefined ## (Note: link = element for some arrays when not defined as lvalue)
        $block .= Link_To("http://limsmaster/SDB/docs/out/undef", $link . '&nbsp'. alDente::Web::image('warning.jpg', -height=>15));
    }
    
    return $block;
}

return 1;
