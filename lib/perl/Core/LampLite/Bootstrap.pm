package Bootstrap;

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::Bootstrap.pm - Wrapper for bootstrap embedded elements

=head1 SYNOPSIS <UPLINK>

Assumes installed bootstrap css and js libraries 

# Usage examples:
#
#  my $BS = new Bootstrap();
#
#  print $BS->load_css($path);
#  print $BS->load_js($path);
#
#  print $BS->open();
#
#  print $BS->print_Header(\%header);
#
#  print $BS->menu(\%menu);
#  
#  print $BS->warning('standard warning message')
#
# print $BS->close();
#

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################
# 

use RGTools::RGIO qw(filter_input Cast_List Call_Stack Show_Tool_Tip);

##############################
# custom_modules_ref         #
##############################

##############################
# global_vars                #
##############################

my $t = "\t";

## Bootstrap 2.x 
# my $icon_prefix = 'icon';
# my $icon_class = 'icon';

## Bootstrap 3.x
my $icon_prefix = 'fa fa';
my $icon_class = 'glyphicon';  ## was icon in bootstrap 2.x



## Cross-browser support ##
my $display_flex = flex_display_css();

########################
sub flex_display_css {
########################   
    my %args = @_;
    my $direction = $args{-direction};

    my $css = "display: -webkit-box;"     ## /* OLD - iOS 6-, Safari 3.1-6 */
    . "display: -moz-box;"         ## /* OLD - Firefox 19- (buggy but mostly works) */
    . "display: -ms-flexbox;"      ## /* TWEENER - IE 10 */
    . "display: -webkit-flex;"     ## /* NEW - Chrome */
    . "display: flex; ";            ## /* NEW, Spec - Opera 12.1, Firefox 20+ */

    if ($direction) {
        $css .= "flex-direction: $direction; "
    }

    return $css;
}


########################
sub flex_css {
########################
    my $value = shift;

## width: 20%;               /* For old syntax, otherwise collapses. */

    my $flex_css = "-webkit-box-flex: $value;      /* OLD - iOS 6-, Safari 3.1-6 */\n"
    . "-moz-box-flex: $value;         /* OLD - Firefox 19- */\n"
    . "-webkit-flex: $value;          /* Chrome */\n"
    . "-ms-flex: $value;              /* IE 10 */\n"
    . "flex: $value;                  /* NEW, Spec - Opera 12.1, Firefox 20+ */\n";

    return $flex_css;
}

########################
sub flex_order_css {
########################
    my $value = shift;

## width: 20%;               /* For old syntax, otherwise collapses. */

    my $flex_order_css =<<ORDER;
-webkit-box-ordinal-group: $value;  
-moz-box-ordinal-group: $value;     
-ms-flex-order: $value;     
-webkit-order: $value;  
order: $value;
ORDER

    return $flex_order_css;
}

###################
# Constructor
#
# Simple bootstrap object simplifying inclusion of various bootstrap objects
#
##########
sub new {
##########
    my $this = shift;
    my $class = ref($this) || $this;   

    my ($self) = {};           
    bless $self, $class;

    $self->{status} = '';
    
    return $self;
}

############
sub scope {
############    
}

##############
sub visible {
##############
    my $self = shift;
    my $scope = shift;  ## xs, sm, md, lg
    my $block = shift;
    
    ## legacy support for Bootstrap 2.3.1 terminology ##
    if ($scope eq 'phone') { $scope = 'xs' }
    if ($scope eq 'mobile') { $scope = 'xs' }
    if ($scope eq 'tablet') { $scope = 'sm' }
    if ($scope eq 'desktop') { $scope = 'md' }
    
    return "\n<span class='visible-$scope'>\n$block\n</span>\n";
    
}

##############
sub hidden {
##############
    my $self = shift;
    my $scope = shift;
    my $block = shift;

    ## legacy support for Bootstrap 2.3.1 terminology ##
    if ($scope eq 'phone') { $scope = 'xs' }
    if ($scope eq 'mobile') { $scope = 'xs' }
    if ($scope eq 'tablet') { $scope = 'sm' }
    if ($scope eq 'desktop') { $scope = 'md' }
    
    return "\n<span class='hidden-$scope'>\n$block\n</span>\n";

}

#####################################################
# Wrapper to generate HTML Header with bootstrap file 
#
# Return: HTML code to include css file 
###############
sub load_css {
###############
    my $self = shift;
    my $path = shift;
    my $custom = shift;
    my $responsive = 1;
    my $font_awesome = 1;

    my $script = "<LINK rel=stylesheet type='text/css' href='$path/bootstrap.css'>\n";
    if ($custom) { 
        if (ref $custom ne 'ARRAY') { $custom = [$custom] }
        foreach my $c (@$custom) {
            $script .= "<LINK rel=stylesheet type='text/css' href='$c'>\n";
        }
    }
    if ($font_awesome) { 
        $script .= qq(<link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.no-icons.min.css" rel="stylesheet">\n);
        $script .= qq(<link href="//netdna.bootstrapcdn.com/font-awesome/3.2.1/css/font-awesome.css" rel="stylesheet">\n);
    }
    if ($responsive) { $script .= "<LINK rel=stylesheet type='text/css' href='$path/bootstrap-responsive.css'>\n" }
    return $script;
}

#####################################################
# Wrapper to generate HTML Header with bootstrap file 
#
# Return: HTML code to include js file 
###############
sub load_js {
###############
    my $self = shift;
    my $path = shift;
    my $include = shift;

    return _bootstrap_js($path, $include);
}

# 
#
# Return: html text to include bootstrap js files 
###################
sub _bootstrap_js {
###################
    my $path = shift;
    my $include = shift;

    my $js;
    
    $js = <<JS;
    <script src="$path/holder/holder.js"></script>
    <script src="$path/google-code-prettify/prettify.js"></script>
    <script src="$path/application.js"></script>
JS

    if ($include) { 
        foreach my $addon (@$include) {
            $js .= "<script src='$path/bootstrap-$addon.js'></script>\n";
        }
    }
    else {
        $js .= "<script src='$path/bootstrap.js'></script>\n";
    }

    return $js;
}

#
# Wrapper to include tooltip supporting javascript within header 
# 
# Return: html tags for applicable javascript 
#####################
sub load_tooltip_js {
#####################
    
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

##############################################
# Wrapper to generate bootstrap container div
# (close container_div with close_bootstrap)
#
# Return: HTML string to open container div
##############################################
sub open {
###########
    my $self = shift;
    my %args = filter_input(\@_);
    my $container_type = $args{-container_type} || 'container';
    my $width = $args{-width};
    my $col_size = $args{-col_size} || 'md';
    
    my $style;
    if ($width) { $style = "style=width:$width; " }
    
    $self->{status} = 'open';

    my $container = "<div class='full-size-container' id='full-size-container' width=100%>\n<div class='$container_type' $style=$style>\n"; ##  style='padding:1%; margin: 2px;'>\n";

    return $container;
}

#################################################
# Wrapper to close bootstrap container div
# (open container_div with open_bootstrap)
#
# (will return null if $self->{status} ne 'open')
# 
# Return: string to include to close div 
#################################################
sub close {
############
	my $self = shift;
	my $dbc = shift;
	
	my $close_block;
	if ($dbc && $dbc->{BS_footer}) {
#	    $dbc->message("INCLUDING CACHED");
	    my $include = "<!-- Include cached block(s) -->\n";
	    foreach my $block (@{$dbc->{BS_footer}}) {
	        $include .= $block . "\n";
	    }
	    $close_block .= $include;
	}
	
	
	if ($self->{status} eq 'open') { 
		$self->{status} = 'closed';
		$close_block .= "\n</div>\n";
	}
	elsif ( !$self->{status} ) { 
		$self->{status} = 'closed';
		$close_block .= "\n</div>\n";        ## close if the status is not tracked ##
	}
	$close_block .= "<!-- Closed BS Container -->\n";
	$close_block .= "<!-- Closed Full-sized Container -->\n";

	return $close_block;   ## do not close container div if already closed 
}

#############
sub button {
#############
    my $self = shift;
    my %args = @_;
    my $label = $args{-label};
    my $id = $args{-id};
    my $name = $args{-name} || 'rm';  ## default to run mode for MVC usage
    my $icon = $args{-icon};
    my $icon_class = $args{-icon_class} || 'fa';  ## font-awesome by default (or use glyphicon )
    my $value = $args{-value};
    my $attributes = $args{-attributes};
    my $type = $args{-type} ;  ## primary, info, success, warning, danger, inverse, link
    my $btn_type = $args{-btn_type} || 'submit';  ## primary, info, success, warning, danger, inverse, link
    my $size = $args{-size};  ## large, small, or mini
    my $onclick = $args{-onClick} || $args{-onclick};
    my $title  = $args{-title};
    my $style = $args{-style};
    my $class = $args{-class} || 'btn';
    my $tooltip = $args{-tooltip};
    my $disabled = $args{-disabled};
    my $debug = $args{-debug};

    my $colour = $args{-colour};
    if ($colour) { $style .= " color:$colour;"}

    if ($disabled) { $disabled = "disabled='disabled'"}
    
    ## legacy adaptation to support size parameters from bootstrap 2.3.1 ##
    if ($size eq 'mini' || $type eq 'mini') { $size = 'xs' }
    elsif ($size eq 'small' || $type eq 'small') { $size = 'sm' }
    elsif ($size eq 'large' || $type eq 'large') { $size = 'lg' }


    if ($label =~/^[\w\s]+$/ && !$value) { $value = $label }   ## don't default value if label contains non word elements ...     
    if ($icon) { 
        $label .= ' ' . $self->icon($icon, -icon_class=>$icon_class);
        $style ||= 'background-color:transparent; '  ## default to transparent when using icons ##
    }
    
    if ($size) { $class .= " btn-$size" }
    if ($type) { $class .= " btn-$type" }
    
    if ($type eq 'navbar') { $class =~s/btn-navbar/navbar-btn/g; }  ## legacy v2.3.1 support
    
    my $button = qq(<button  class="$class btn-no-margin" );
    $button .= qq($attributes) if $attributes;
    $button .= qq(margin=0 " );
    $button .= qq( type='$btn_type' ) if $btn_type;
    $button .= qq( id="$id" ) if $id; 
    $button .= qq( name="$name" ) if $name;
    $button .= qq( value="$value" ) if $value;
    $button .= qq( onClick="$onclick" ) if $onclick;
    $button .= qq( title="$title" ) if $title;
    $button .= qq( style="$style">$label</button>\n);
    
    if ($tooltip) { $button = $self->tooltip($button, $tooltip); }
    
    return $button;
}

####################
sub custom_modal {
####################
    my $self = shift;
    my %args = @_;
    
    return $self->modal(%args);
}

# 
# Simple wrapper for basic modal element
#
# Example:
#    print $BS->modal( -body => 'content of open modal', -label=>'button label')
#
############
sub modal {
############
    my $self = shift;
    my %args = @_;
    my $body = $args{-body};
    my $id       = $args{-id}  || int(rand(10000));
    my $title    = $args{-title};
    my $button   = $args{-button} || $args{-buttons};     ## one or more button elements to include in footer along with the close button 
    my $onclick  = $args{-onclick};
    my $icon     = $args{-icon};       ## alternative to label for launching modal
    my $label    = $args{-label};      ## text label used to launch modal 
    my $class    = $args{-class} || 'btn ';
    my $style    = $args{-style};
    my $launch_type = $args{-launch_type};   ## text or button
    my $tooltip  = $args{-tooltip};
    my $size     = $args{-size};
    my $type     = $args{-type};
    my $colour   = $args{-colour} || 'transparent';
    my $button_style = $args{-button_style} || "background-color:$colour";

    my $dbc      = $args{-dbc};        ## only include if nesting modal creates problems with standard modal call... (this includes modal code at the end of the script upon $BS->close($dbc) call )

    if ($icon) { $launch_type ||= 'text' }
    else { $launch_type ||= 'button' }
    
    if ($size eq 'mini' || $type eq 'mini') { $size = 'xs' }
    elsif ($size eq 'small' || $type eq 'small') { $size = 'sm' }
    elsif ($size eq 'large' || $type eq 'large') { $size = 'lg' }

    if ($size) { $class .= " btn-$size" }
    if ($type) { $class .= " btn-$type" }
    
    if ($icon) { $label .= $self->icon($icon) }

    my $launcher;
    if ($launch_type =~/^b/i) { $launcher = qq (<button type='button' class="$class" data-toggle='modal' data-target="#$id" style="$button_style">$label</button>) }
    else {  $launcher = qq (<div class="$class" data-toggle='modal' data-target="#$id" style="$style">$label</div>) }
    

    if ($tooltip) { $launcher = $self->tooltip($launcher, $tooltip) }
    
    my $close = qq (<button type="button" class="btn btn-default" data-dismiss="modal">Close</button>);
    
    my $buttons;    
    if ($button) {
        ## add custom buttons if supplied ##
        my @buttons;
        if (! ref $button) { @buttons = ($button) }
        foreach my $button (@buttons) {
            $buttons .= qq (\t\t\t<button type="button" class="btn btn-primary">$button</button>\n);
        }
    }
    
    my $modal = qq(    
<!-- Modal -->
     <div class="modal fade" id="$id" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
       <div class="modal-dialog">
         <div class="modal-content">
);

if ($title) {
    ## only include title section if title supplied ##
    $modal .= qq(
           <div class="modal-header">
             <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
             <h4 class="modal-title" id="myModalLabel">$title</h4>
           </div>
    );
}
    
$modal .= qq(
           <div class="modal-body">
             $body
           </div>
           <div class="modal-footer">
                $close
                $buttons
           </div>
         </div>
       </div>
     </div>
     );
    if ($dbc) { 
        ## use only if nesting modals inside some collapsible items.  This will put the code for the actual modal outside the collapsible elements (eg separated from the launcher) ##
        ## to complete the functionality, the dbc object must be passed to the bootstrap close method at which point the modal object is included.
         push @{ $dbc->{BS_footer} }, $modal;
         return $launcher;
    }
    else {
        return $launcher . $modal;
    }
}

#
# Wrapper for simple datetime picker
#
# Usage: When creating a text field, if you want the calendar to show up onclick pass in this function as the onclick parameter
# Example: $output = $BS->text_element(-id => $element_id, -icon_append => $icon, -onclick => $BS->calendar( -id => $element_id, ...), ...);
#
# Output: JavaScript to initialize and open calendar for the provided element id
#
##################
sub calendar {
##################
    my $self = shift;
    my %args = &filter_input( \@_, -args=>'id', -mandatory=>'id|element_id' );

    my $calid = $args{-id} || $args{-element_id} || $args{-from} || 'datetimepicker';
    my $to_id = $args{-to};
    my $calname = $args{-name} || $args{-element_name} || $args{-from_name} || $calid;
    my $to_name = $args{-to_name} || $to_id;
    my $shortcuts = $args{-shortcuts} || 1;
    my $type      = $args{-type} || 'date';     ## eg time or date
    my $default_to = $args{-default_to};
    my $default = $args{-default_from} || $args{-default};
    my $default_to = $args{-default_to};              ## indicate default time (only applies to from date when using range)
    my $calendar_format = $args{-calendar_format} || 'jquery';    ## enable option of different calendar format types
 
    require LampLite::HTML;  ## use for display_date_field & auto_pick_dates ##

    $args{-field_name} = $calname || 'Date';
    $args{-element_id} = $calid;
    
    return LampLite::HTML::display_date_field(%args, -calendar_format=>$calendar_format);  ## alternatively, use jquery to access jquery version... 
}  

#
#
# Wrapper to generate basic row on web page based upon bootstrap 12 column grid
#
# Options:
# -span [array of span lengths]
#
# Usage:
#    print $BS->row(['col1','col2'],-span=>[8,4]);
#
#
###########
sub row {
###########
    my $self = shift;
    my %args = filter_input(\@_, -args=>'row');
    my $columns = $args{-row};
    my $span    = $args{-span};
    my $style   = $args{-style};
    my $class   = $args{-class};       ## class of columns (was 'nav dropdown-toggle')
    my $size    = $args{-size} || 'md';  ## bootstrap size: xs , md, lg ...  ##
    my $column_style = $args{-column_style};
    my $size    = $args{-size} || 'md'; ## size of display (xs - phone, sm - tablet, md/lg - desktop)

    my $mobile = $args{-mobile};
    
    my $single_style;
    if ($style && int(@$style) == 1) { $single_style = $style->[0] }
    
    if ($columns && ref $columns eq 'ARRAY' && !$span) {
        my $common_span = int (12 / int(@$columns));
        $span = [];
        foreach my $i (1 .. int(@$columns)) { push @$span, $common_span }
    }
    
    my $row = "<!-- START OF ROW -->\n";
    if ($columns && $span && ref $columns eq 'ARRAY' && ref $span eq 'ARRAY' && int(@$columns) == int(@$span) ) {
        my $length = int(@$columns);
        
        $row .= "<div class='row'>\n";
        foreach my $i (1..$length) {
            my $colspan = $span->[$i-1];
            my $colstyle = $single_style || $style->[$i-1];
            my $content = $columns->[$i-1];
            if ($column_style && $column_style->[$i-1]) { $colstyle .= $column_style->[$i-1] }
            
            if ($colstyle && ($colstyle !~/^style=/) ) { $colstyle = "style='$colstyle'" }
            
            $content =~s/\n/\n\t\t/xmsg;
            $row .= "\t<div class='col-$size-$colspan $class' $colstyle>\n";
            $row .= "\t\t$content\n";
            $row .= "\t</div>\n";
        }
        $row .= "</div>\n";
        $row .= "<!-- END OF ROW -->\n";   
    }
    else {
#        Leave out messages for now (these are generated if session is expired)
#        Call_Stack();
#        return $self->error("Error specifying row");
# 
    }
    
    return $row;
}

###############
sub flexbox {
###############    
    my $self = shift;
    my %args = filter_input(\@_, -args=>'content,flex');
    my $list = $args{-content};
    my $flex = $args{-flex} || 1;
    my $direction = $args{-direction};
    my $justify = $args{-justify_content};
    my $style = $args{-style};
	my $toggle = $args{-toggle};
	my $id = $args{-id} || int(rand(1000));
	my $tag_type = $args{-tag_type} || 'div';

    my $flexbox;
    
    if ($toggle) { 
#        $flexbox .= qq(<nav class = 'navbar navbar-default col-md-12' style='$style'>\n);
        if ($toggle eq '1') { $toggle = '<!-->' }
        $flexbox .= $self->toggle(-id=>$id, -button=>$toggle);
        $flexbox .= $self->toggle_open($id);
    }
    
    if ($direction) { $style .= "flex-direction:$direction;" }
    if ($justify) { $style .= "justify-content:$justify;" }
    
    $flexbox .= "<$tag_type class='flexbox-row' style='$display_flex; $style'>\n";

    foreach my $i (1..int(@$list)) {
        my $item = $list->[$i-1];
        my $style;

        if ($flex && ref $flex eq 'ARRAY') { $style = flex_css($flex->[$i-1]) } ## "flex:$flex->[$i-1]"}
        elsif ($flex) { $style = flex_css($flex) } ## "flex: $flex" } 
 
        $flexbox .= "\t<span style='$style'>\n";
        $flexbox .= "\t\t" . $item;
        $flexbox .= "\t</span> <!-- end of span for section $i -->\n";
    }

    $flexbox .= "</$tag_type> <!-- end of flexbox-row $tag_type -->\n";
    
    if ($toggle) {$flexbox  .= $self->toggle_close() }
    
    return $flexbox;
}

#################
sub spaced_row {
#################   
    my $self = shift;
    my %args = filter_input(\@_, -args=>'row,span');
    my $list = $args{-row};
    my $span = $args{-span};
	my $id = $args{-id} || int(rand(1000));
	my $toggle = $args{-toggle};
    my $style = $args{-style} || 'text-align: center;';
    my $size = $args{-size} || 'lg';   ## may be sm, md, or lg 

    my $spanbox;
    
    if ($toggle) { 
        if ($toggle eq '1') { $toggle = '<!-->' }
        $spanbox .= $self->toggle(-id=>$id, -button=>$toggle);
        $spanbox .= $self->toggle_open($id);
    }
    
    $spanbox .= "<div class='row' style='$style'>\n";

    my $count = int(@$list);
    my $default_span = int(12/$count);
    
    foreach my $i (1..int(@$list)) {
        my $item = $list->[$i-1];
        my $class;

        if ($span && ref $span eq 'ARRAY') { $class = "col-$size-$span->[$i-1]"}
        elsif ($span) { $class = "col-$size-$default_span" } 
 
        $spanbox .= "\t<div class='$class'>\n";
        $spanbox .= "\t\t" . $item;
        $spanbox .= "\t</div>\n";
    }

    $spanbox .= "</div> <!-- end of spanbox-row -->\n";
    
    if ($toggle) { $spanbox  .= $self->toggle_close() }

    return $spanbox;
}

###########
sub form {
###########
    my $self = shift;
    my %args = filter_input(\@_, -args=>'rows');
    my $title = $args{-title};
    my $Form = $args{-Form};   ## form object if defined 
    my $rows = $args{-rows} || $Form->{rows};
    my $type = $args{-type} || $Form->{type};  ## eg horizontal or in-line
    my $style = $args{-style} || $Form->{style};
    my $class = $args{-class} || $Form->{class};
    my $role  = $args{-role}  || $Form->{role} || 'form';
    my $include = $args{-include};
    
    my $row_style = $args{-row_style};
    
    my $initialize = $args{-initialize} || $args{-open};   ## supply specific form initialization, but wrap form in bootstrap class
    my $close = $args{-close};
    
    my $role = 'form';
    
    
    my $form;
    
    if ($type) { $class .= " form-$type" }

    if ($initialize) { 
        $form .= $initialize;
        $form =~s/<FORM(\s)/<FORM class='$class' role='$role' style='$style'/i;
    }

    if ($title) {
        $form .= "<div class='form-header' >$title</div>";
    }
    
    foreach my $row (@$rows) {
        my $this_row_style;
        if (defined $row_style && defined $row_style->[$row]) { $this_row_style = $row_style->[$row] }
        
        $row =~s/\n/\n\t/g;
        $form .= "<div class='form-group' style='$this_row_style'>\n"
            . "\t$row\n"
            . "</div><!-- end of form-group -->\n";
    }
    
    if ($include) { $form .= $include }
    
    if ($close) { $form .= "</FORM> <!-- End of Form -->\n"; }

    return $form;
}

#
# Wrapper for basic bootstrap element
#
# elements can be added in a row using a combination of form_element and row
#
#    my $first = $self->form_element(-label=>'First Name', -input=> qq(<input type="text"></input>), -span=>[2,4]);
#    my $last = $self->form_element(-label=>'Last Name', -input=> qq(<input type="text"></input>), -span=>[2,4]);
#        
#    my $email = $self->form_element(-label=>'Email Address', -input=> qq(<input type="text"></input>), -span=>[2,10]) ;
#
# ## follow up with call to form:
#
# 
#   print $self->form( [ $first.$last,  $email] , -class=>'form-horizontal');
#
#    
###################
sub form_element {
###################
    my $self = shift;
	my %args = filter_input(\@_, -args=>'label,input');
	my $Form   = $args{-Form};
    my $label  = $args{-label};
    my $input    = $args{-input};
    my $span     = $args{-span} || $Form->{span};
    my $input_id = $args{-input_id};
	my $id     = $args{-id};
    my $style   = $args{-style};
    my $label_style = $args{-label_style} || $style;
    my $framework = $args{-framework} || 'Bootstrap';   ## alternatively, use Table framework for table structured form
    my $no_format = $args{-no_format};
    my $col_size = $args{-col_size} || 'md';  ## bootstrap col size spec (md wraps for smaller screens by default.  Use xs to enforce horizontal for small screens)
    
    my $input_class    = $args{-input_class}; 
    my $label_class = 'control-label';
    
    my $class;
    if (!$no_format) { $class = 'form-control' }
   
    my $original_class = $input_class || '';
    if ($input =~/<(input|select|button)(.*?)>/i) {
        my $attributes = $2;        
        if ($attributes =~ /class=[\'\"](.+?)[\'\"]/i) { $original_class .= ' ' . $1; }
    }
    

    if ($input =~s/<(input|select|button)\s/<$1 class='$class $original_class' /i ) { }     ## make all original input elements into form-control elements
    elsif ($input) { $input = "<p class='$class-static'>$input</class>\n" }           ## static input
    
    if ($span) { 
        $label_class .= " col-$col_size-" . $span->[0];
        my $input_span = "col-$col_size-" . $span->[1];
        $input = "<div class='$input_span'>\n$input</div>\n";
    }
    
    my $element;  ## form-group class generated in form method to enable multiple form_elements on one line if desired... ##
    
    if ($framework =~ /bootstrap/i) {
        $span ||= [2,10];
        
        $label_class .= " col-$col_size-" . $span->[0];
        my $input_span = "col-$col_size-" . $span->[1];
        $input = "<div class='$input_span'>\n$input</div>\n";
        
        if (defined $label) { $element .= "\t<label for='$input_id' class='$label_class' style='$label_style'>$label</label>\n" }
        $element .= "\t\t" . $input. "\n";

        if ($style || $id) { $element = "<div id='$id' style='$style'>\n$element\n</div>\n" }
    }
    elsif ($framework =~/table/i) {
        $element .= "<TR>\n";
        $element .= "\t<TD class='$label_class'>$label</TD>\n";
        $element .= "\t<TD class='$input_class'>$input</TD>\n";
        $element .= "</TR>\n";
    }
    
    return $element;
}

###########################################################
# Simple wrapper to generate bootstrap tags for menu
#
# Input: hash with menu details
# 
#  eg print $BS->header(-left=>$icon, -centre=>$title, -right=>[$dept_options, $user_options]);
#
# Note: if values are arrays, then they will appear as dropdown menus using the menu method.
#
# Return: HTML code supporting bootstrap tagged menu
############################################################
sub header {
############
	my $self = shift;
	my %args = filter_input(\@_);
	my $level = $args{-level} || 0;
	my $inverse = $args{-inverse} || '';
	my $id = $args{-id} || int(rand(1000));
	my $menu = $args{-menu};
	my $centre = $args{-centre};
	my $left = $args{-left};
	my $right = $args{-right};
    my $class = $args{-class};
    my $classes = $args{-classes};  ## apply to sections (array)
	my $toggle =  $args{-toggle};
    my $position    = $args{-position};
    my $style       = $args{-style};
    my $styles       = $args{-styles};  ## apply to sections 
    my $flex = $args{-flex};
    my $span = $args{-span};
    my $col_size = $args{-col_size} || 'md';  ## bootstrap col size spec (md wraps for smaller screens by default.  Use xs to enforce horizontal for small screens)
    
    my $menu_class = $args{-menu_class};  ## allow option to specify pull-right for menu ( eg -menu_class=>'pull-right');
        
    if (!$flex && !$span) { $span = 4 }  ## if neither flex or span specification supplied, default to 4 | 4 | 4 division of header 
    my $col_span;
    if ($position =~/top/i) { $position = 'navbar-fixed-top' }
    elsif ($position =~/bottom/i) { $position = 'navbar-fixed-bottom' }
    else { $col_span = "col-$col_size-12" }

	if ($inverse) { $inverse = 'navbar-inverse'}

    my $grayscale = $args{-grayscale} || $args{-greyscale} || 0;  ## bootstrap uses american spelling... 
    
    my $string = '';

    my $subclass;
        
    my ($ul_class, $ul_style, $li_style);
#    $ul_style ||= 'flex:1;';
#    $li_style ||= 'flex:1;';
    $li_style = $style;
    
    my ($left_flex, $centre_flex, $right_flex);
    my ($end_span, $left_span, $centre_span, $right_span);
    
        $string .= "\n<!-- START OF Header -->\n";
 #       $string .= "<nav class='navbar navbar-default $inverse $position $col_span' role='navigation' style='margin:inherit; $style'>\n";
        $string .= "<div class = '$position $col_span' style='$style'>\n";
        if ($toggle) { 
            if ($toggle eq '1') { $toggle = '<!-->' }
            $string .= $self->toggle(-id=>$id, -button=>$toggle, -inverse=>$inverse);
            $string .= $self->toggle_open($id);
        }
        if ($flex) { 
            if (ref $flex eq 'ARRAY') { 
                $left_flex = $flex->[0];
                $centre_flex = $flex->[1];
                $right_flex = $flex->[2];
            }
            $string .= "\t<div style='$display_flex'>\n";
            $ul_style .= $display_flex;
            $ul_class .= " flexbox-row";
            $li_style = flex_css($flex); ## "flex:$flex;";
        }
        elsif ($span) {
            if (!ref $span) { $span = [$span, $span, $span] }
            if (ref $span eq 'ARRAY') { 
                $left_span = "<div class='col-$col_size-" . $span->[0] . " pull-left'>\n";
                $centre_span = "<div class='col-$col_size-" . $span->[1]  . "'>\n";
                $right_span = "<div class='col-$col_size-" . $span->[2]  . " pull-right'>\n";
                $end_span = "</div> <!-- end span -->\n";
            }
        }
              
#        $subclass = 'dropdown';
        $ul_class .= ' nav navbar-nav';
#        if (!$menu) { $li_style .= ' width:100%' }
        
    my $indent = "\t"x$level;  ## establish indentation level for readability
    
    if ($styles && !(ref $styles)) { $ul_style .= ' ' . $styles }  ## apply style (eg width:100% to ul in menu item in each section below respectively (may be distinct for each section by passing array of style values)
    if ($classes && !(ref $classes)) { $ul_class .= ' ' . $classes }  ## apply style (eg width:100% to ul in menu item in each section below respectively (may be distinct for each section by passing array of style values)
    
    my $style_index = 0;   ## allow array of styles to be applied to defined sections respectively (eg left+right or left+centre+right or centre+right)
    my $class_index = 0;
    if (defined $left) {
        my $left_style = $ul_style;
        my $left_class = $ul_class;
        if (ref $styles eq 'ARRAY') { $left_style .= ' ' . $styles->[$style_index++] }
        if (ref $classes eq 'ARRAY') { $left_class .= ' ' . $classes->[$class_index++] }
        
        $string .= "<!-- LEFT SECTION ($left_flex)-->\n" 
        . $left_span;
        
        if (ref $left eq 'ARRAY' && int(@$left) == 1 &&  ! ref $left->[0]) {
            ## single scalar value - no need to convert to menu UI ##
            $string .= $left->[0];
        }
        else {
            $string .= $self->menu(-menu => $left, -level=>$level+1, -class=>"nav navbar-nav navbar-left", -flex=>$left_flex , -grayscale=>$grayscale, -ul_class=>$left_class, -ul_style=>$left_style)
        }

        $string .= $end_span;
    }
    if (defined $centre) { 
        my $centre_style = $ul_style;
        my $centre_class = $ul_class . ' col-md-12';     ## ensure centre block fills full width assigned ##
        if (ref $styles eq 'ARRAY') { $centre_style .= ' ' . $styles->[$style_index++] }
        if (ref $classes eq 'ARRAY') { $centre_class = ' ' . $classes->[$class_index++] }

        $string .= "<!-- CENTRE SECTION ($centre_flex)-->\n" 
        . $centre_span
        . $self->menu(-menu => $centre, -level=>$level+1, -class=>"nav navbar-nav navbar", -flex=>$centre_flex, -grayscale=>$grayscale, -style=>'text-align:center; width:100%;', -ul_class=>$centre_class, -ul_style=>$centre_style)
        . $end_span;
    }

    $string .= $indent . "</ul>\n";
    
    if (defined $right) { 
        my $right_style = $ul_style;
        my $right_class = $ul_class;
        if (ref $styles eq 'ARRAY') { $right_style .= ' ' . $styles->[$style_index++] }
        if (ref $classes eq 'ARRAY') { $right_class .= ' ' . $classes->[$class_index++] }

        $string .= "<!-- RIGHT SECTION ($right_flex)-->\n"
        . $right_span;
        if (ref $right eq 'ARRAY' && int(@$right) == 1 &&  ! ref $right->[0]) { 
            ## single scalar value - no need to convert to menu UI ##
            $string .= $right;
        }
        else {
            $string .= $self->menu(-menu => $right, -level=>$level+1, -class=>"nav navbar-nav navbar-right", -flex=>$right_flex, -grayscale=>$grayscale, -menu_class=>'pull-right', -ul_class=>$right_class, -ul_style=>$right_style);
        }
        $string .= $end_span;
    }

    if ($flex) { $string .= "</div> <!-- close flexbox -->\n" }
    if ($toggle) { $string .= $self->toggle_close() }
    $string .= "\n</div><!-- END OF HEADER -->\n";

	return $string;
}

###########################################################
# Simple wrapper to generate bootstrap tags for menu
#
# Input: hash with menu details
# 
#  eg [{ 'Option1' => [
#			'A label only',
#			'B label only',
#			{'C' => [
#				{'C.1' => 'C.1 link'},
#				'C.2 labelonly',
#				{'C.2.1' => 'http://gmail.com'}
#				]
#			}
#			]inam
#		},
#		{ 'Option2' => [{'x' => 'xlink'},{'y' => 'ylink'}] }
#	]  
# Return: HTML code supporting bootstrap tagged menu
############################################################
sub menu  {
############
	my $self = shift;
	my %args = filter_input(\@_,-args=>'menu');
	my $level = $args{-level} || 0;
	my $inverse = $args{-inverse} || '';
	my $id = $args{-id} || int(rand(1000));
	my $menu = $args{-menu};
	my $centre = $args{-centre};
	my $left = $args{-left};
	my $right = $args{-right};
    my $class = $args{-class};
	my $toggle =  $args{-toggle};
    my $position    = $args{-position};
    my $style       = $args{-style};
    my $flex = $args{-flex};
    my $span = $args{-span};
    my $ul_style = $args{-ul_style};
    my $ul_class = $args{-ul_class};
    my $navbar = defined $args{-navbar} ? $args{-navbar} : 1;   ### allow option to explicitly turn navbar off (for use by old browsers)
    my $col_size = $args{-col_size} || 'md';  ## bootstrap col size spec (md wraps for smaller screens by default.  Use xs to enforce horizontal for small screens)
    
    my $menu_class = $args{-menu_class};  ## allow option to specify pull-right for menu ( eg -menu_class=>'pull-right');
        
    my $col_span;
    if ($position =~/top/i) { $position = 'navbar-fixed-top' }
    elsif ($position =~/bottom/i) { $position = 'navbar-fixed-bottom' }
    else { $col_span = "col-$col_size-12" }

	if ($inverse) { $inverse = 'navbar-inverse'}

    my $grayscale = $args{-grayscale} || $args{-greyscale} || 0;  ## bootstrap uses american spelling... 
    
    my $string = '';

    my $subclass;
        
    my ($li_style);
    $li_style = $style;
    
    my ($left_flex, $centre_flex, $right_flex);
    my ($end_span, $left_span, $centre_span, $right_span);
    
    if (!$level) {  
        $string .= "\n<!-- START OF Menu -->\n";
        if ($navbar) { $string .= "<nav class='navbar navbar-default $inverse $position $col_span' role='navigation' style='margin:inherit; $style'>\n" }
        if ($toggle) { 
            if ($toggle eq '1') { $toggle = '<!-->' }
            $string .= $self->toggle(-id=>$id, -button=>$toggle, -inverse=>$inverse);
            $string .= $self->toggle_open($id);
        }

        if ($flex) { 
            $string .= "\t<div style='$display_flex'>\n";
            $ul_style .= $display_flex;
            $ul_class .= " flexbox-row";
            $li_style = flex_css($flex); ## "flex:$flex;";
        }
        elsif ($span) {
        }
              
#        $subclass = 'dropdown';
        $ul_class .= ' nav navbar-nav';
        $ul_style ||= 'width:100%';
#        if (!$menu) { $li_style .= ' width:100%' }
        
    }
    else {
        if ($class =~/dropdown/) {
#            $subclass = "dropdown-submenu $menu_class";
            $ul_class = "dropdown-menu sub-menu $menu_class";
        }
        else { 
            $ul_class .= ' ' . $class;
            $subclass = 'dropdown';
        } 
        if ($grayscale) { $ul_class .= " grayscale"}   ## only apply grayscale to secondary elements 

        if ($flex) {
            $ul_style .= $display_flex . flex_css($flex); ## "display:flex; flex: $flex";
        }
    }

    my $indent = "\t"x$level;  ## establish indentation level for readability

    if ($menu) { $string .= $indent . "<ul class='$ul_class' style='$ul_style'>\n" }

    my $ref = ref $menu;

    if (ref $menu ne 'ARRAY') { 
        if (! ref $menu) { $menu = [$menu] }
        else {
            my $message = ref $menu || "scalar ($menu)";
            $message .= ' found - expecting array...';
            return $self->error($message);
        }
    }

    foreach my $menu_item (@{$menu}) {
        
        if (!$menu_item) { next }
        
        my $Iref = ref $menu_item;        
        if (!$Iref) {
            $string .= $indent . "\t" 
            . "<LI class='$subclass' style='$li_style'>"
            . $menu_item .
            "</li>\n";
            next;
        }
        elsif ($Iref eq 'ARRAY') { 
            $string .= $self->error("$Iref found - expecting a hash");
             next;
        }
        
        my ($label) = keys %$menu_item;
        my ($target) = values %$menu_item;
        
        ($label, my $attributes) = split_a_tag($label, $target);
        
        if (ref $target) {
            
            my $trigger_symbol;   ## customize menu with right & left caret controls (use with  menu.css & $BS->menu_js)
            if ($level > 1) { $trigger_symbol = 'right-caret' }
            
            ## if target is not scalar link, add a sub-menu ##
            $string .= 
            $indent . "\t<Li class='$subclass' style='$li_style'>\n"
            . $indent . "\t\t<A tabindex='-1' class='dropdown-toggle trigger $trigger_symbol' data-toggle='dropdown' $attributes>$label</a>\n"
            . $self->menu(-menu => $target, -level => $level+2, -class=>'dropdown', -flex=>0, -grayscale=>$grayscale, -menu_class=>$menu_class)
            . $indent . "\t</li>\n";
        }
        else {
            ## add html for menu / submenu item ##
            my $trigger_symbol = 'right-caret';
            $string .=
            $indent . "\t<LI class='$subclass' style='$li_style'>\n"
            . $indent . "\t\t<A tabindex='-1'  $attributes>\n"
            . $indent . "\t\t\t$label\n"
            .$indent . "\t\t</a>\n"
            . $indent . "\t</li>\n";
        }

        if ( !$level ) { $string .= qq(<li class="divider-vertical" style="$li_style"></li>) }
    }
    

    $string .= $indent . "</ul>\n";
 
    if (!$level) { 
        if ($flex) { $string .= "</div> <!-- close flexbox -->\n" }
        if ($toggle) { $string .= $self->toggle_close() }
        if ($navbar) { $string .= "\n</nav>\n<!-- END OF MENU -->\n" }
    }

	return $string;
}

#############
sub toggle {
#############
    my $self = shift;
    my %args = filter_input(\@_);
    my $id = $args{-id};
    my $title = $args{-title};
    my $toggle_button = $args{-button};
    my $alt_text      = $args{-alt_txt};
    
    my $inverse = $args{-inverse} || 1;
    
    my $toggle_class = 'navbar-toggle';
    if ($inverse) { $toggle_class .= ' grayscale' }
    
    if ($toggle_button !~/[a-zA-Z0-9]/) { 
        $toggle_button =<<BUTTON;
    <i class="$icon_prefix-bars fa-lg" style=''></i>
BUTTON
    }
    
    my $toggle =<<TOGGLE;
    
      <!-- Brand and toggle get grouped for better mobile display -->
      <div class="navbar-header">
        <button type="button" class="$toggle_class" data-toggle="collapse" data-target="#$id">
          <span class="sr-only">Toggle navigation</span>
          $toggle_button
        </button>
        <a class="navbar-brand" id='open-title' style='display:none' href="#">$title</a>
        $alt_text
      </div>

TOGGLE

    return $toggle;
}

#################
sub toggle_open {
#################
    my $self = shift;
    my $id = shift;
    
   return qq(<div class="collapse navbar-collapse" id="$id">);
}

##################
sub toggle_close {
##################
    my $self = shift;
    
   return qq(</div> <!-- end of toggled navbar collapse section -->\n);
}

#
# Extracts A tag attributes and separates them from the primary label
#
# This avoids embedded A tags, and allows inclusion of a tag attributes specified in a given label to be included in the parent A tag.
#
#  $string returned is the original label with the A tag stripped off
#  $attributes are the attributes of the A tag (including the Href )
#
#  Input Options:
#     target - specified Href target (otherwise defaults to '#')
#
# Return: ($string, $attributes)
#################
sub split_a_tag {
#################
    my $label = shift;
    my $target = shift || '#';

    if (ref $target) { $target = '#' }  # only include if it is a scalar value ... 
    

    my $attributes = "Href='$target'"; ## default ##
    if ($label =~/^<A (.*?)>(.*)<\/A>/ixms) {
        $attributes = $1;
        $label = $2;
    }
    
    if ($attributes =~s/class=\"(.*?)\"//) { print "REPLACED: $attributes" }
    return ($label, $attributes);
}

#######################################################
# Wrapper for generating bootstrap layered blocks
#
# eg. tab-layered sections of page
#
# Return: HTML code to include layered sections
#############
sub layer {
#############
	my $self = shift;
	my %args = filter_input(\@_, -args=>'layers');
	my $layers = $args{-layers};
	my $active = $args{-active} || $args{-default};
	my $id     = $args{-id} || int(rand(10000));
	my $visibility = $args{-visibility};
	my $layer_type = $args{-layer_type}; ## tabs';  ## default to tabbed layering - alternate options include:  accordion / menu 
    my $style = $args{-style};
    my $class = $args{-class};
    my $onclick = $args{-onclick};                  ## optionally include on_click specification for each layer... 
    my $collapse = $args{-collapse};                ## automatically (dynamic) replace nav tabs with dropdown menu on top right corner for small screen size
    my $collapsed_class = $args{-collapsed_class}; 

    if ( $0 =~ /\b(mobile|scanner)\b/) { $layer_type ||= 'accordion' }
    else { $layer_type ||= 'tabs' }
    
    my $subclass;
    if ($layer_type =~/accordion/i) { return $self->accordion(%args) }
    elsif ($layer_type =~/tab/i ) { $subclass = 'tabclass' }
    elsif ($layer_type =~/menu/i ) { $subclass = 'menuclass' }
    elsif ($layer_type =~/nav-tab/i ) {$subclass = 'nav-tabs' }
   
   my %Content;
   ## generate tabs first ##
   my @titles;
 	
 	my ($hidden, $shown);
 	if ($collapse) {
 	    ## collapse when screen size gets down to vs or xs ##
 	    foreach my $size (@$collapse) {
 	        $shown .= "hidden-$size ";
 	        $hidden .= "visible-$size ";
 	    }
    }
 	
 	my $string = qq(<ul class='nav nav-tabs $shown $class' style="$style">\n);
	my $index = 1;
			
	foreach my $layer (@$layers) {
	    my @keys = keys %{$layer};
	    	    
	    my ($title, $content);
	    ### options below account for old formatting structure ##
        if (int(@keys) == 1) {
            $title = $keys[0];
            ($content) = values %{$layer};
        }
	    elsif (grep /^label$/, @keys) {
	        $title = $layer->{label};
	        $content = $layer->{content};
        }
        else {
            print $self->error("Layer format unrecognized - or label not supplied");
        }
        
        push @titles, $title;
	    $Content{$title} = $content;
	    
	    my $active_spec = '';
	    if ( ($active eq $title) || (!$active && $index == 1) ) { $active_spec = "class='active'" }
	    
	    my $vtag = $self->visibility_tag($visibility, $title, 'embedded');
	    
	    my $local_onclick;
	    if (ref $onclick eq 'HASH' && defined $onclick->{$title}) {
	        $local_onclick = $onclick->{$title};
	    }
	    elsif ($onclick && ! ref $onclick) { $local_onclick = $onclick }
	    
	    if ($content) { $string .= qq(\t<li $active_spec $vtag ><a href='#tab$id-$index' data-toggle='tab' class='$subclass' onclick="$local_onclick">\n$title\n</a></li>\n); }
	    $index++;
	}
	$string .= "</ul>\n";
	
	if ($collapse) {
	    $string .= convert_to_mobile_menu(-ul=>$string, -hidden=>$hidden, -shown=>$shown, -id=>$id, -class=>$collapsed_class);
    }
	
	## generate content ##
	
	$string .= qq(<div class="tab-content">\n);
	my $index = 1;
	foreach my $title (@titles) {
	    
	    my $vtag = $self->visibility_tag($visibility, $title, 'embedded');
        
	    my $active_spec = '';
	    if ( ($active eq $title) || (!$active && $index == 1) ) { $active_spec = " active" }
	    
        $string .= qq(\t<div class="tab-pane $active_spec" $vtag id="tab$id-$index">);
        $string .= $Content{$title};
        $string .= "\t</div>\n";
         $index++;
	}
	$string .= "</div>\n";
	return $string;
}

#
# Convert UL block (using nav nav-tabs) to dropdown mobile style menu
#
##############################
sub convert_to_mobile_menu {
##############################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'ul,include');
    my $block = $args{-ul};
    my $hidden = $args{-hidden};
    my $shown = $args{-shown};
    my $include = $args{-include}; 
    my $class   = $args{-class};
    my $id = $args{-id};
    
    my @inclusions;
    if ($include && ref $include eq 'ARRAY') { @inclusions = @$include }
    elsif ($include =~/[a-zA-Z]/) { @inclusions = ($include) }
    
    my $collapsed = $block;

    $collapsed =~s/class='nav nav\-tabs (.*?)'/class='mobile-menu $class'/;   ## mobile-menu included in custom bootstrap.css
    $collapsed =~s/mobile\-menu $shown /mobile-menu /;

    my $mobile_menu .=<<COLLAPSE;
    	 <div id='collapsed-$id' class='$hidden' style=''>
    	    <div id='mobile-menu-key' class="pull-right" >
    	        <A href='#' onclick="document.getElementById('mobile-menu-$id').style.display='block'; document.getElementById('mobile-menu-key').style.display='none';">
    	            <i class='fa fa-bars fa-2x mobile-menu-icon'></i>
    	        </A>
    	    </div>

    	    <div id='mobile-menu-$id' class="mobile-menu " style='display:none'>
                <a class="mobile-menu-close" style="position:fixed; top:11px; right:0px; width:46px; font-size:20px; z-index:999;">
                    <i class="fa fa-times-circle" onclick="document.getElementById('mobile-menu-$id').style.display='none'; document.getElementById('mobile-menu-key').style.display='block';"></i>
                </a>
COLLAPSE

    foreach my $include (@inclusions) {
        $mobile_menu .= $include;
    }

    $mobile_menu .= $collapsed;
    $mobile_menu .= "</div></div>\n";

    return $mobile_menu;
}

#################
sub accordion {
#################
    my $self = shift;
	my %args = @_;
    my $id = $args{-id} || int(rand(1000));
    my $layers = $args{-layers};
	my $active = $args{-active};
    
    my $block = qq(\n<!-- Start of Accordion Block -->\n);
    $block .= qq(<div class="panel-group" id="accordion$id">\n);
    
    my $i = 1;
    my $in = 'in';   ## may append to panel-collapse collapse class (do not use - leave accordion options closed to start)
    foreach my $layer (@$layers) {   
	    my @keys = keys %{$layer};
	    
	    my ($title, $content);
	    ### options below account for old formatting structure ##
        if (int(@keys) == 1) {
            $title = $keys[0];
            ($content) = values %{$layer};
        }
	    else {
	        $title = $layer->{label};
	        $content = $layer->{content};
        }

        my $active_spec;
        my $toggle_icon = 'down';
	    if ( ($active eq $title) || (!$active && $i == 1) ) { 
	        $toggle_icon = 'up';
	    }
        
        if (!$content) { next}
             
        $block .= qq(\t<div class="panel panel-default $active_spec" >\n);
        $block .= qq(\t\t<div class="panel-heading accordion-toggle collapsed" data-toggle="collapse" data-parent="#accordion$id" href="#collapse-$id-$i">\n);
        $block .= qq(\t\t<h4 class="panel-title">\n);
        
#        $block .= qq(\t\t\t<a class="panel-toggle" data-toggle="collapse" data-parent="#accordion$id" href="#collapse$i">\n);
        $block .= qq(\t\t\t<a href="#">\n);
        
        if ($i > 1) { $in = ''}
        
        $title =~s/\n/\t\t\t\t\n/xmsg;
        $content =~s/\n/\t\t\t\t\n/xmsg;
        
        $block .= "\t\t\t\t$title\n";
         $block .= "\t\t\t</a>\n\t\t</div>\n";
        $block .= qq(\t\t<div id="collapse-$id-$i" class="panel-collapse collapse">\n);
        $block .= qq(\t\t\t<div class="panel-body">\n);
        $block .= "\t\t\t\t$content\n";
        $block .= qq(\t\t\t</div>\n\t\t</div>\n\t</div>\n);
    
        $i++;
    }
        
    $block .= "</div>\n";
    $block .= qq(<!-- END of Accordion Block -->\n);
    return $block;
}

#
# Wrapper for returning null value, but tracking error messages.
#
#
# Return: 0 
#############
sub error {
#############
	my $self = shift;
	my $msg = shift;
	
	push @{$self->{errors}}, $msg;
	return 0;
}

###################
sub start_header {
###################
    my $self = shift;
    my %args = filter_input(\@_);
    my $name   = $args{-name};
    my $inverse = $args{-inverse} || '';
    my $position    = $args{-position};
    my $style       = $args{-style};
    my $secondary_style = $args{-secondary_style};   ## style for internal header section ... 
    my $class       = $args{-class};

    if ($inverse) { $inverse = 'navbar-inverse' }

    if ($position =~/top/i) { $position = 'navbar-fixed-top' }
    elsif ($position =~/bottom/i) { $position = 'navbar-fixed-bottom' }
 
    my $content = "\n<!-- START OF HEADER -->\n";

    $content .= <<OPEN;
        <div id='primaryHeader' class="$class $position primaryHeader" style='$style'>  
            <div id='$name' style='$secondary_style' class="collapsible-header">
OPEN
        
#    class="navbar navbar-default $inverse $position" style='$style'>
        return $content;    
    
}

#########################
sub end_dynamic_header {
#########################
    my $self = shift;
    my $content = "</div> <!-- end of collapseHeader div -->\n";
    
    $self->{dynamic_header_closed} = 1;
    return $content;
}

##################
sub end_header {
##################
    my $self = shift;
    
    my $content;
    
    if (! $self->{dynamic_header_closed} ) { $content = "</div> <!-- end of collapseHeader div -->\n"; }
    $content .= "</div> <!-- end of primaryHeader div -->\n";
    $content .= "<!-- END OF HEADER -->\n";

    return $content;
}

###########
sub icon {
###########
    my $self = shift;
    my $class = shift;
    my %args = @_;
    my $line_height = $args{-line_height};
    my $sub_class = $args{-sub_class};
    my $colour       = $args{-colour};
    my $id = $args{-id};
    my $size = $args{-size};
    my $style = $args{-style};
    my $onclick = $args{-onclick};
    my $icon_class = $args{-icon_class} || 'fa';  ## or glyphicon 
    
    my $icon_prefix = "$icon_class $icon_class";
    
    if ($size) { $sub_class .= " fa-$size" }

    if ($line_height) { $style .= "; line-height:${line_height}px; " }
    if ($colour) { $style .= "; color:$colour; "}
    
    my $icon = qq(<i class="$icon_prefix-$class $sub_class"  id='$id' style='$style' onclick="$onclick"></i>);     ## icon used for font-awesome icons (glyphicon used for bootstrap ?) 
    
    return $icon;

}

###############
sub glyphicon {
###############
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $icon    = $args{-icon};
    my $style   = $args{-style};
    
    my $glyphicon = qq(<i class='glyphicon glyphicon-$icon' style='$style'></i>);

    return $glyphicon;
}

#########################
sub lock_unlock_header {
#########################
    my $self = shift;
    my $default = shift;  ## locked or unlocked 
    my $padding = shift;
     
    if ($default =~ /unlock/) { return $self->lock_header('block', $padding) . $self->unlock_header('none') }
    else { return $self->lock_header('none', $padding) . $self->unlock_header('block') }   
}

##################s
sub lock_header {
##################
    my $self = shift;
    my $display = shift || 'none';
    my $padding = shift || '40';  ## should match fixed padding-top for body 
    
    my $button = $self->button(-icon=>'lock', -type=>'mini', -class=>'Default btn', -colour=>'black', -onClick=>"document.getElementById('primaryHeader').style.position='fixed'; document.getElementById('body').style.paddingTop='$padding'; unHideElement('unlock-btn'); HideElement('lock-btn'); unHideElement('expand-btn'); unHideElement('collapse-btn');");
    
    return qq(<a href='#' id='lock-btn' rel='tooltip' data-toggle="tooltip" data-placement='right' title="lock header to top of page" style="display:$display">$button</a>\n);
}

##################
sub unlock_header {
##################
    my $self = shift;
    my $display = shift || 'none';
    my $collapsed = shift || '0';  ## should match fixed padding-top for body 
    
    my $button = $self->button(-icon=>'unlock', -type=>'mini', -class=>'Default btn', -colour=>'black', -onClick=>"document.getElementById('primaryHeader').style.position='relative'; document.getElementById('body').style.paddingTop='0'; unHideElement('lock-btn'); HideElement('unlock-btn'); HideElement('expand-btn'); HideElement('collapse-btn');");
    
    return qq(<a href='#' id='unlock-btn' rel='tooltip' data-toggle="tooltip" data-placement='right' title="unlock header so that it scrolls with rest of page" style="display:$display">$button</a>\n);
}

##################
sub show_header {
##################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'name, padding');
    my $name = $args{-name};
    my $padding = $args{-padding} || '60';  ## should match fixed padding-top for body 
    my $style  = $args{-style};
    my $class  = $args{-class};
    
    my $button = $self->button(-icon=>'chevron-down', -type=>'mini', -class=>$class, -style=>$style, -colour=>'black', -onClick=>"document.getElementById('body').style.paddingTop='${padding}px'; unHideElement('$name');");
    return qq(<a href='#' id='expand-btn' rel='tooltip' data-placement='right' data-toggle="tooltip" title="show header">$button</a>\n);
    
}

###################
sub hide_header {
###################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'name, padding');
    my $name = $args{-name};
    my $padding = $args{-padding} || '0';  ## should match fixed padding-top for body 
    my $style  = $args{-style};
    my $class  = $args{-class};

    my $button = $self->button(-icon=>'chevron-up', -type=>'mini', -class=>$class, -colour=>'black', -style=>$style, -onClick=>"document.getElementById('body').style.paddingTop='${padding}px'; HideElement('$name');");
    return qq(<a href='#' id='collapse-btn' rel='tooltip' data-placement='right' data-toggle="tooltip" title="hide header">$button</a>\n);;
}

############
sub _header {
############
    my $self = shift;
    my $options = shift;
    my %args = @_;
    my $class = $args{-class} || 'nav';
    my $dropdown_class = $args{-dropdown_class} || 'dropdown';
    my $indent = $args{-indent};

    my $default_class = 'header-item';  ## default class of header titles if not dropdown menu

    my @options;
    if (ref $options eq 'ARRAY') { @options = @$options }
    elsif (ref $options eq 'HASH') { @options = [$options] }
    
    my $content = "$indent<ul class='$class'>\n";
       
    foreach my $H (@options) {
        ### Standard Header Items ###
        my $title;
        my $attributes;
        my @list;
        my %Hinfo;
        
        if (ref $H eq 'HASH') { 
            ($title) = keys %$H;
            my ($list) = values %$H;
            if (ref $list eq 'ARRAY') { @list = @$list }
            elsif (ref $list eq 'HASH') {
                %Hinfo = %$list;
                if ($Hinfo{title} ) { $title = $Hinfo{title} }
                if ($Hinfo{options}) { @list = @{$Hinfo{options}} }      
            }
        }
        elsif (! ref $H) { $title = $H }
        
        if (@list) {
            $content .= "$indent<lI class='$class'>";
            
            ($title, $attributes) = split_a_tag($title);
            
            $content .= qq($indent$t<a class="dropdown-toggle" data-toggle='dropdown' $attributes>$title</a>);
            $content .= qq($indent$t<ul class="dropdown-menu h" >);
            
            foreach my $item (@list) {
                if (ref $item eq 'ARRAY') { print $self->error("item cannot be array (should be hash or scalar)") }
                elsif (ref $item eq 'HASH') {
                    my @keys = keys %$item;
                    my @vals = values %$item;
                    $content .= $self->_header(\@vals, -level=>1, -class=>'dropdown');
                }
                else { 
                    my ($item, $item_attributes) = split_a_tag($item);
                    $content .= qq($indent$t$t<lI><a $item_attributes>$item</a></li>)
                }
            }
            $content .= "$indent$t</ul>\n";
            $content .= "$indent</li>";
        }
        else {
            my $class = $Hinfo{class} || $default_class;
            $content .= "$indent<lI>\n$indent$t<$class>$title</$class>\n$indent</li>\n";
        }
    }

    $content .= "$indent</ul>\n";
    
    return $content;
}

#
# Generates path like text (eg  Home / Projects / Options )
#
#
##########
sub path {
##########
    my $self = shift;
    my $array = shift;
    my $style = shift;
    my $divider = shift;
    
    my $content = qq(\t<ul class="breadcrumb" style='$style'>\n);
    
    if ($array && ref $array eq 'ARRAY') { 
        foreach my $item (@$array) {
            $content .= qq(\t\t<li>$item<span class="divider">$divider</span></li>\n);
        } 
    }  
    $content .= "\t</ul>\n";
    
    return $content;
}	




##############
sub context {
##############
    my $self = shift;

    my $context;
    unless ($context) {
        if ( $0 =~ /ajax/i ) {
            $context = 'ajax';
        }
        elsif ( $0 =~ /Web_Service/i ) {
            $context = 'text - web_service';
        }
        elsif ( $0 =~ /\.html$/ || $0 =~ /\/cgi-bin\// ) {
            $context = 'html';
        }
        elsif ( $0 =~ /\.xml$/ ) {
            $context = 'xml';
        }
        elsif ( $0 =~/\bbin\b/) {
            $context = 'text';
        }
        else {
            $context = 'text';
        }
    }

    return $context;
}

#
# Wrapper used by message, warning, error, success, info ....
#
# Options:
#  -message (mandatory - can be scalar or array - array generates bulleted list for output)
#  -type (mandatory : message, warning, error, success or info)
#  -close (default = 1)
#  -block (default = 1 if message is long)
#
#
# Return: HTML for applicable alert
############
sub alert {
#############
    my $self = shift;
    my $message = shift;
    my %args = @_;
    
    my $type = $args{-type} || 'message';   
    my $close = defined $args{-close} ? $args{-close} : 1;

    if ($self->context() eq 'text') { $message =~s/<BR>/\n/; return "** $type ** $message\n\n" }

    my $long = 500;  ## length of message that generates an alert-block class (more padding)

    if (ref $message eq 'ARRAY') {
        ## display as bulleted list of messages if array supplied ##
        my $list = "<ul>\n";
        foreach my $m (@$message) { 
            $m =~s/\n/<BR>/g;
            $list .= "<li>$m</li>\n"
        }
        $list .= "</ul>\n";
        $message = $list;
    }
    else {
        $message =~s/\n/<BR>/g;
    }
    
    my $block = defined $args{-block} ? $args{-block} : length($message) > $long;
    
    ## Define classes for various alert types (based upon bootstrap classes) ##  Note: alert-message is customized , and alert-warning adjusted 
    my $Class = {'warning' => 'alert-warning', 'error' => 'alert-danger', 'success' => 'alert-success', 'info' => 'alert-info', 'message' => 'alert-message'};
    
    
    my $class = 'alert';
    if ($type && $Class->{$type}) { $class .= ' ' . $Class->{$type} }
    
    if ( $block ) { $class .= " alert-block" }
    
    my $alert = "<div class='$class' background-color=#FF0000>\n";
    
    if ($close) { $alert .= qq(\t<button type="button" class="close" data-dismiss="alert">&times;</button>\n) }

    if ($type =~/warning/i)  { $message = "<strong>Warning !</strong> $message" }
    elsif ($type =~/error/i) { $message = "<strong>Error !</strong> $message" }

    $alert .= $message;
    $alert .= "</div>\n";
    
    if ($args{-print}) { print $alert }
    return $alert;
}

#
# Wrapper for basic bootstrap text types
# 
# eg $BS->text('submission sent', 'success')
#
# Text types: success, muted, warning, error, info
#
# Return: Bootstrap tag containing text
###########
sub text {
###########
    my $self = shift;
    my $text = shift;
    my %args = @_;
    my $text_type = $args{-type} || 'text';
    my $tooltip = $args{-tooltip};
    my $popover     = $args{-popover};
    my $title       =  $args{-title} || $tooltip;
    
    if ($tooltip) { $tooltip = qq(rel="tooltip"  data-html="true" title="$title") }
    if ($popover) { $popover = qq(rel="popover" data-original-title="$title" data-content="$popover") }

    unless ($text_type eq 'muted') { $text_type = 'text-' . $text_type }
    return "<A Href='#' class='$text_type' $tooltip $popover>$text</A>\n";
}

# Wrapper for standard alert (see alert method for options)
#
# Return: HTML for applicable alert
#############
sub message {
#############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'message, type');
    my $message = $args{-message};
    
    $args{-type} ||= 'message';
    return $self->alert($message, %args);
    
}

# Wrapper for standard alert (see alert method for options)
#
# Return: HTML for applicable alert
#############
sub warning {
#############
    my $self = shift;
    my $message = shift;
    my %args = @_;
  
    return $self->alert($message,-type=>'warning', %args);
}    

# Wrapper for standard alert (see alert method for options)
#
# Return: HTML for applicable alert
#############
sub error {
#############
    my $self = shift;
    my $message = shift;
    my %args = @_;
    
    return $self->alert($message,-type=>'error', %args);
}

# Wrapper for standard alert (see alert method for options)
#
# Return: HTML for applicable alert
#############
sub info {
#############
    my $self = shift;
    my $message = shift;
    my %args = @_;
    
    return $self->alert($message,-type=>'info');
}

# Wrapper for standard alert (see alert method for options)
#
# Return: HTML for applicable alert
#############
sub success {
#############
    my $self = shift;
    my $message = shift;
    my %args = @_;
    
    return $self->alert($message,-type=>'success', %args);
}

#
# Wrapper to generate input textfield with icon submit attached 
# 
# This is used for a standard text element within a form. prepend and append options available
#
# For simple form elements, use form_element method instead.
#
# (used primarily for standard Search elements)
#
# $BS->text_group_element(
#    -placeholder  => 'Search',
#    -name         => 'DB Search String',
#    -tooltip      => $tooltip,
#    -default      =>  $default,                  
# )
#
# Additional options.... (eg as used for date fields)
#
#    -append_icon       => 'calendar',                                                     ## add icon following text field
#    -append_text       => $example                                                        ## add text following text field
#    -icon_onclick => "jQuery('#$element_id').datetimepicker('show');",                    ## execute when icon is clicked
#    -onclick => "jQuery('#$element_id').datetimepicker('show');",                         ## execute when textfield is clicked
#
#
# Note: Does not include form wrappers.
#
# Return element
########################
sub text_element {
########################
    my $self = shift;
    my %args = @_;
        
    my $id          = $args{-id};
    my $name        = $args{-name};              ##  name of text element
    my $class       = $args{-class} || 'form-control';
    my $placeholder = $args{-placeholder};  ## eg 'Search'
    my $span        = $args{-span};         ## grid columns to span (out of 12)
    my $style       = $args{-style};
    my $default     = $args{-default};      ## value to have text field default to
    
    my $tooltip     = $args{-tooltip};     ## tooltip for text element
    my $popover     = $args{-popover};      ## popover for text element
    my $title       = $args{-title};
    my $onclick     = $args{-onclick};      ## onclick action for textfield
    
    my $append_icon     = $args{-append_icon};
    my $icon_onclick    = $args{-icon_onclick};
    my $append_text     = $args{-append_text};
    my $append_style    = $args{-append_style};
    
    my $text_class = $args{-text_class};
    my $text_style = $args{-text_style};
    my $internal   = $args{-internal};      ## internal element (exclude form classes)
    my $col_size = $args{-col_size} || 'md';  ## bootstrap col size spec (md wraps for smaller screens by default.  Use xs to enforce horizontal for small screens)
        
    my $bootstrap_disabled   = $args{-bootstrap_disabled};  ## enable this to work even if bootstrap css is not available ... 
 
    my @pass_arguments = qw(id name style value onchange onclick force);
    my $include_args;

    foreach my $arg (@pass_arguments) {
        if ( defined $args{"-$arg"} ) { $include_args .= qq($arg='$args{"-$arg"}') }
    } 

    if ($text_class) { $text_class = "$class $text_class" }
    else { $text_class = $class }
        
    if ($append_icon || $append_text ) { $class = "input-group" }
        
 
    my ($popover_spec, $tooltip_spec);

    if  ($ENV{DISABLE_TOOLTIPS} ){
       $popover = undef;
       $tooltip = undef;
    }

    if ($popover) { $popover_spec = qq(rel="popover" data-original-title="$title" data-content="$popover") }
    elsif ($tooltip) { $tooltip_spec = qq(rel="tooltip"  data-html="true" title="$tooltip") }
    
    my $element;
#    if ($span) { $class .= " col-$col_size-$span" }
    
    my ($element_class, $element_style);
    if ($span && $span < 12) { $element_class = "col-$col_size-$span"; $element_style = 'padding-left:0px;'}
    
    $element .= qq(<div class="form-search $element_class" style="$element_style">\n);
    $element .= qq(<div class='$class' style="$style">\n);
                
    my $main_text;
    if ($id || $name) {
        $main_text = qq(<input type="text" $tooltip_spec $popover_spec $include_args class="$text_class" placeholder="$placeholder" value="$default" style="$text_style"/>\n); 
        if ($tooltip && $popover) { $main_text = $self->tooltip($main_text, $tooltip, -placement=>'top') }  ## if BOTH being used, make sure tooltip goes on top so popover can appear below without overlapping 
    }
        
    $element .= $main_text;

    my $append_section;  ## optionally add text or icon following input element ##
    if ($append_icon || $append_text) {
        $append_section .= qq(<span class="input-group-addon" style="$append_style">\n);
        
        if ($append_icon) { $append_section .= $self->icon($append_icon, -onclick=>$icon_onclick) . "\n"}
        if ($append_text) { $append_section .= $append_text . "\n" }
        $append_section .= "</span> <!-- end of appended section -->\n";
        $element .= $append_section;
    }    

    $element .= "</div> <!-- end of input-group -->\n";
    $element .= "</div> <!-- end of form-search -->\n";

    return $element;
}

#
# Wrapper to generate input textfield with icon submit attached 
# 
# This is used for an advanced element with prepend and append sections and optional execution buttons attached.
#
# For simple form elements, use form_element method instead.
#
# (used primarily for standard Search elements)
#
# $BS->text_group_element(
#    -append_button       => 'clock',
#    -append_tooltip  => 'press here',
#    -placeholder  => 'Search',
#    -name         => 'DB Search String',
#    -run_mode     => 'Search Database',
#    -tooltip      => $tooltip,
#    -popover      => $popover,
#    -button_class => 'Search btn',
#    -text_class     => 'short-txt',
#    -app          => 'LampLite::Login_App',
# )
# Note: Does not include form wrappers.
#
# Return element
########################
sub text_group_element {
########################
    my $self = shift;
    my %args = @_;
        
    my $name   = $args{-name};              ##  name of text element
    my $text_class = $args{-text_class};
    my $placeholder = $args{-placeholder};  ## eg 'Search'
    
    my $app         = $args{-app};          ## app called from button if applicable 
    my $run_mode    = $args{-run_mode};     ## run mode called from button if applicable 
    my $button_class = $args{-button_class}; 
    my $tooltip      = $args{-tooltip};     ## tooltip for text element
    my $popover     = $args{-popover};      ## popover for text element
    my $help_button	= $args{-help_button};	## if this parameter is passed in, a question mark button will be displayed with the parameter value as the popover content, which will open/close when being clicked. It is mainly for showing the help message.
    my $width       = $args{-width};
    my $title       = $args{-title};
    my $flex        = $args{-flex};         ## whether to implement flex box to 
    my $span        = $args{-span};
    my $id          = $args{-id};
    my $onclick     = $args{-onclick};      ## onclick action for textfield 
    my $text_style  = $args{-text_style};   ## style for text element 
    my $default     = $args{-default};
    my $mobile = $args{-mobile};
    
    my $size;
    if ($mobile) { $size = 'large' }
    
    ## append and prepend options ##
    my $apppend_button = $args{-append_button};            ## icon for append button
    my $append_button_text = $args{-append_button_text};       ## text for append button (either icon or text - not both...)
    my $append_text = $args{-append_text};                ## simple text appended to input field
    my $append_icon = $args{-append_icon};                ## simple icon appended to input field
    my $append_tooltip = $args{-append_tooltip};
    my $append_onclick = $args{-append_onclick};
    
    my $bootstrap_disabled   = $args{-bootstrap_disabled};  ## enable this to work even if bootstrap css is not available ... 
    
    my $class = 'input-group';
    if ($button_class !~/btn/) { $button_class .= ' btn' }
    
    if ($size =~/^l/i) { 
        $class = 'input-group-lg';
        $button_class .= '-lg';
        $text_class .= " input-lg";

        $args{-button_class} = $button_class;
        $args{-text_class} = $text_class;
    }
    
    my $style = $args{-style} || 'padding:3px;'; # = 'display:flex';

    my ($pre_flex, $main_flex, $post_flex);
    if ($flex) {
        $style = "display:flex; $style";
        if (! ref $flex) { $flex = [$flex, $flex, $flex] }
        $pre_flex = $flex->[0];
        $main_flex = $flex->[1];
        $post_flex = $flex->[2];
    }    
    
    if ($width) { $width = "width='$width'" }
    if (defined $default) { $default = "value='$default' force=1" }
 
    if ($text_class) { $text_class = "form-control $text_class" }
    else { $text_class = "form-control" }
 
#    $popover =~s/<BR>/\n\n/xmsig;  
    my ($popover_spec, $tooltip_spec);

    if  ($ENV{DISABLE_TOOLTIPS} ){
       $popover = undef;
       $tooltip = undef;
    }

    if ($popover) { $popover_spec = qq(rel="popover" data-original-title="$title" data-content="$popover") }
    elsif ($tooltip) { $tooltip_spec = qq(rel="tooltip"  data-html="true" title="$tooltip") }
    
    my $element;
#    if ($span) { $element .= qq(<div class='col-$col_size-$span'>) }
    
    $element .= qq(<span class="form-search">\n);
    $element .= qq(<div class='$class' style="$style">\n);
        
    $args{-flex} = $pre_flex;
    $element .= $self->_add_input_group(%args, -scope=>'prepend');
                
    my $main_text = qq(<input class="$text_class" type="text" id='$id' $default $width $tooltip_spec $popover_spec name="$name" placeholder='$placeholder' style='$text_style; flex:$main_flex; ' onclick="$onclick"/>\n); 
    if ($tooltip && $popover) { $main_text = $self->tooltip($main_text, $tooltip, -placement=>'top') }  ## if BOTH being used, make sure tooltip goes on top so popover can appear below without overlapping 
        
    $element .= $main_text;
    
    $args{-flex} = $post_flex;
    $element .= $self->_add_input_group(%args, -scope=>'append');

    if( $help_button && !$mobile ) {
	    my $msg_button .= qq(<A HREF= '#'>);
	    $msg_button .= qq(<SPAN data-placement="bottom" data-html="true" data-content="$help_button" rel="popover" trigger="click" data-original-title="">);
	    $msg_button .= qq(<button type='button' class="fa fa-question-circle" style="background-color:transparent; border:0px"></button>);
	    $msg_button .= qq(</SPAN>);
	    $msg_button .= qq(</A>);
    	
    	$element .= $msg_button;
    }

    $element .= "</div> <!-- end of input-group span -->\n";
    $element .= "</span> <!-- end of form-search span -->\n";

    if ($span) { $element .= "</div> <!-- end of div with span specification -->\n" }

    if ($app) { $element .= qq(<input type='hidden' name="cgi_application" value="$app" ></input>\n) }

    return $element;
}

######################
sub _add_input_group {
######################
    my $self = shift;
    my %args = @_;
    
    my $app         = $args{-app};          ## app called from button if applicable 
    my $run_mode    = $args{-run_mode};     ## run mode called from button if applicable 
    my $button_class = $args{-button_class}; 
    
    my $scope   = $args{-scope};
    
    my $append_button = $args{"-${scope}_button"};            ## icon for append button
    my $append_button_text = $args{"-${scope}_button_text"};       ## text for append button (either icon or text - not both...)
    my $append_text = $args{"-${scope}_text"};                ## simple text appended to input field
    my $append_icon = $args{"-${scope}_icon"};                ## simple icon appended to input field
    my $append_tooltip = $args{"-${scope}_tooltip"};
    my $append_button_options =  $args{"-${scope}_button_options"};  ## use for button dropdown elements
    my $append_style = $args{"-${scope}_style"};
    my $append_onclick = $args{"-${scope}_onclick"};
    
    my $flex = $args{-flex};
    my $joined = $args{-joined};  ## indicate if button should be joined with text field (otherwise separated... )
    
    my $append_section;
    if ($append_text || $append_icon) { 
        ## text / image only - not a button ##
        $append_section .= qq(<span class="input-group-addon" style="$append_style">\n);
        
        if ($append_icon) { $append_section .= $self->icon($append_icon, -onclick=>$append_onclick) . "\n"}
        else { $append_section .= $append_text . "\n"}
        
        if ($append_onclick) { $append_section .= "</button>\n" }
        
        $append_section .= "</span> <!-- end of $scope input-group-addon  -->\n";
    }
    elsif ($append_button || $append_button_text || $append_button_options) { 
        ## button object ##
        $append_style ||= "flex:$flex";
        my $style;
        if ($joined) { $append_section .= qq(<span class="input-group-btn" style='$append_style'>\n) }
        else { $style = $append_style }
        
        $append_section .= ' ';
        my $button;
        
        if ($append_button_options) {
            $button = qq(<button type="button" class="btn btn-default dropdown-toggle $button_class" data-toggle="dropdown" style='$style'>\n);
        }
        elsif ($run_mode) {
            $button = qq(<button type="submit" name="rm" value="$run_mode" class="btn btn-search $button_class" style='$style'>\n); ## $button_class 
        }
        elsif ($append_onclick) {
            $button = qq(<button class="btn btn-search $button_class" style='$style' onclick=>"$append_onclick">\n);
        }
        
        my $button_content;
        if ($append_button) { $button_content .= $self->icon($append_button) . "\n"}
        else { $button_content .= $append_button_text . "\n" }
        if ($append_tooltip) { $button_content = $self->tooltip($button_content, $append_tooltip, -placement=>'top') }

        $button .= "$button_content\n</button>\n";
        
        if ($append_button_options) {
            $button .= "<ul class = 'dropdown-menu ig'>\n";
            foreach my $option (@${append_button_options}) {
                $button .= "<li><a href='#'>$option</a></li>\n";
            }
            $button .= "</ul> <!-- end of button option list -->\n";
        }
        
        $append_section .= $button;
        if ($joined) { $append_section .= "</span> <!-- end of $scope input-group-btn  -->\n"; }
    }
    
    return $append_section;
}

#
# Add tooltip to element
# 
# Usage:
#   print tooltip($element, $message);
#
# 
##############
sub tooltip {
##############
    my $self = shift;
    my $element = shift;
    my $tooltip = shift;
    my %args = @_;
    my $placement = $args{-placement} || 'bottom';  ## add other options ... 
    my $delay = $args{-delay} ;  ## add other options ... 

    if ($ENV{DISABLE_TOOLTIPS} ){ return $element }
    
    my $attributes = "rel='tooltip' data-html='true' title='$tooltip'";
    if ($placement) { $attributes .= " data-placement='$placement'" }
    if ($delay) { $attributes .= " data-delay='$delay'" }
    
    return qq(\n<SPAN $attributes >\n$element\n</SPAN>\n);
}

###################
### Progress Bar ##
###################

#
# Show progress bar without updates
#
# This is used when a single task (ie not in a loop) may take time
# (eg - mysql query)
#
# Return: in progress bar
###################
sub in_Progress {
###################
    my $self = shift;
    
    my $bar = "<div id='inprogressbar' class='progress progress-striped active'>\n"
            . qq(<div class="progress-bar"  role="progressbar" aria-valuenow="50" aria-valuemin="0" aria-valuemax="100" style='width: 50%'>\n)
            . qq(<span class="sr-only">45% Complete</span>\n)
            . "</div></div>\n";

    return $bar;
}

####################
sub start_Progress {
####################
   my $self = shift;
   my $title = shift;
   my $target = shift || 100;
   
   my $content = "<div id='progressbar'>\n";
   $content .= qq(<div class="progress progress-striped">\n); 
   $content .= qq(<div class="bar" style="width: 10%;"></div>\n);
   $content .= "</div>\n";
   $content .= "</div>\n";
   
   $self->{progress} = 0;
   $self->{progress_visible} = 1;
   return $content;
}

######################
sub update_Progress {
######################
    my $self = shift;
    my $progress = shift;
    
    $self->{progress} = $progress;

    ## not set up ##
    return;
}

##############
sub search {
##############
    my $self = shift;

    #    my $search <<SEARCH;
    my $search = qq(
        <div class="pull-right">
        <form class="form-search js-search-form " action="/search" id="global-nav-search">
        <label class="visuallyhidden" for="search-query">Search query</label>
        <input class="search-input" type="text" id="search-query" placeholder="Search" name="q" autocomplete="off" spellcheck="false">
        <span class="search-icon js-search-action">
        <button type="submit" class="$icon_class nav-search">
        <span class="visuallyhidden">

        Search
        </span>
        </button>
        </span>
        <input disabled="disabled" class="search-input search-hinting-input" type="text" id="search-query-hint" autocomplete="off" spellcheck="false">
        <div class="dropdown-menu typeahead">
        <div class="dropdown-caret">
        <div class="caret-outer"></div>
        <div class="caret-inner"></div>
        </div>
        <div class="dropdown-inner js-typeahead-results">
        <div class="typeahead-saved-searches">
        <ul class="typeahead-items saved-searches-list">

        <li class="typeahead-item typeahead-saved-search-item"><a class="js-nav" href="" data-search-query="" data-query-source="" data-ds="saved_search" tabindex="-1"><span class="$icon_class generic-search"></span></a></li>
        </ul>
        </div>

        <ul class="typeahead-items typeahead-topics">

        <li class="typeahead-item typeahead-topic-item">
        <a class="js-nav" href="" data-search-query="" data-query-source="typeahead_click" data-ds="topics" tabindex="-1">
        <i class="generic-search"></i>
        </a>
        </li>
        </ul>


        <ul class="typeahead-items typeahead-accounts js-typeahead-accounts">

        <li data-user-id="" data-user-screenname="" data-remote="true" data-score="" class="typeahead-item typeahead-account-item js-selectable">

        <a class="js-nav" data-query-source="typeahead_click" data-search-query="" data-ds="account">
        <img class="avatar size24">
        <div class="typeahead-user-item-info">
        <span class="fullname"></span>
        <span class="js-verified hidden"><span class="$icon_class verified"><span class="visuallyhidden">Verified account</span></span></span>
        <span class="username"><s>@</s><b></b></span>
        </div>
        </a>
        </li>
        <li class="js-selectable typeahead-accounts-shortcut js-shortcut"><a class="js-nav" href="" data-search-query="" data-query-source="typeahead_click" data-shortcut="true" data-ds="account_search"></a></li>
        </ul>

        <ul class="typeahead-items typeahead-trend-locations-list">

        <li class="typeahead-item typeahead-trend-locations-item"><a class="js-nav" href="" data-ds="trend_location" data-search-query="" tabindex="-1"></a></li>
        </ul>
        </div>
        </div>

        </form>
        );

        ##SSEARCH

        return $search;
}
    
###############
sub login {
###############
        my $self = shift;

        my $login = qq(
            <ul class="nav secondary-nav session-dropdown" id="session">
            <li class="dropdown js-session">
            <a class="dropdown-toggle dropdown-signin" id="signin-link" href="#" data-nav="login">
            <small>Have an account?</small> Sign in<span class="caret"></span>
            </a>
            <a class="dropdown-signup" id="signup-link" href="https://twitter.com/signup?context=login" data-nav="signup">
            <small>New to Twitter?</small><span class="emphasize"> Join Today &raquo;</span>
            </a>
            <ul class="dropdown-menu dropdown-form" id="signin-dropdown">
            <li class="dropdown-caret right">
            <span class="caret-outer"></span>
            <span class="caret-inner"></span>
            </li>
            <li>
            <form action="https://twitter.com/sessions" class="js-signin signin" method="post">
            <fieldset class="textbox">
            <label class="username js-username">
            <span>Username or email</span>
            <input class="js-username-field email-input" type="text" name="session[username_or_email]" autocomplete="on">
            </label>
            <label class="password js-password">
            <span>Password</span>
            <input class="js-password-field" type="password" value="" name="session[password]">
            </label>
            </fieldset>

            <fieldset class="subchck">
            <label class="remember">
            <input type="checkbox" value="1" name="remember_me" >
            <span>Remember me</span>
            </label>
            <button type="submit" class="btn submit">Sign in</button>
            </fieldset>

            <input type="hidden" name="scribe_log">
            <input type="hidden" name="redirect_after_login" value="/twbootstrap">
            <input type="hidden" value="93a2417c5621be5e2414cd139d31c4774b224b5d" name="authenticity_token"/>

            <div class="divider"></div>
            <p class="footer-links">

            <a class="forgot" href="/account/resend_password">Forgot password?</a><br />
            <a class="mobile has-sms" href="/account/complete">Already using Twitter via text message?</a>
            </p>
            </form>

            </li>
            </ul>
            </li>
            </ul>
            );

return $login;
}

#####################
sub visibility_tag {
#####################
    my $self = shift;
    my $visibility = shift;
    my $key = shift;
    my $embedded = shift;
     
    my $vis_class;
    if ($visibility) {
        if ( ref $visibility eq 'HASH') {
            my $v = $visibility->{$key};
            $vis_class = $self->visibility_class($v);
        }
        else { 
            $vis_class = $self->visibility_class($visibility);    
        }
    }

    if ($vis_class) { 
        if ($embedded) { return "class = '$vis_class'" }
        else { return ("<div class = '$vis_class'>\n", "</div> <!-- end visibility class -->\n") }
    }
    
    return;
}

#
# Generate bootstrap class specification from visibility information.
#
# (automatically maps phone -> xs, tablet -> sm, desktop -> md + lg)
# .. additionally maps 'mobile' -> xs + sm
#
# return: bootstrap class for applicable visiblity
########################
sub visibility_class {
########################
    my $self = shift;
    my $visibility = shift;
    
    my @vis_list = Cast_List(-list=>$visibility, -to=>'array');
    
    my $vis_class;
    foreach my $mode (@vis_list) {
        $vis_class .= "visible-$mode ";    ## convert to ['tablet', 'desktop'] to 'visbile-sm visible-md visible-lg' for example
        if ($mode =~ /desktop/) { $vis_class .= 'visible-lg' }
        if ($mode =~ /mobile/) { $vis_class .= 'visible-md visible-sm visible-xs' }
    }
    
    $vis_class =~s /\bphone\b/xs/i;
    $vis_class =~s /\bmobile\b/xs/i;
    $vis_class =~s /\btablet\b/sm/i;
    $vis_class =~s /\bdesktop\b/md/i;
    
    return $vis_class;
}

##############################################################
## Dropdown Menus & Multi-Select Dropdowns (Scrolling List) ##
##############################################################
#
# These are technically 3rd party plugins, but developed to work effectively with existing Bootstrap 
# 

#
# Simple accessor to multiple-select dropdown menu.
#
#  Usage:
#
#    print $BS->dropdown(-options => \@options, -default=>$default);
#
#  It should also support standard element parameter inclusions (eg onchange, class, style etc)
#
# This utilizes a third party plugin (Bootstrap-multiselect) that extends existing bootstrap functionality with associated css & js files
#
# Return: code generating multi-select dropdown menu.
###############
sub dropdown {
###############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'options');
    my $id = $args{-id} || int(rand(1000));
    my $name = $args{-name};
    my $class = $args{-class};
    my $options = $args{-options} || $args{-values} || $args{-value};
    my $default = $args{-default}; 
    my $labels  = $args{-labels};
    my $style = $args{-style};
    my $disable = $args{-disable};
    my $type    = $args{-type} || 'select';   ## select or multiselect ##
    my $ajax  = $args{-ajax};
    my $filter  = $args{-filter};
    
    my $test  = $args{-test};
                                                             
    my $extras = $self->_std_element_options(%args);
    my $block = "<!-- Bootstrap dropdown -->\n";

    if ($options && int(@$options) > 2) { $filter = 1 }
    if ($filter) { $extras .= "data-filter='true' " }
    
    $args{-id} = $id;

        ## Use Bootstrap Multiselect ##
        if ($type =~/multi/i) { 
            $args{-filter} = $filter;
            $args{-options} = $options;
            $args{-multiple} = 'multiple';
        }
        $block .= $self->multi_dropdown(%args);
        
    $block .= "<!-- end of bootstrap dropdown -->\n";
    
#    if ($ajax) { $block .= $self->_ajax_fill_dropdown(-ajax=>$ajax, -id=>$id, -type=>'select') }
    $block .= _js_init_dropdown(%args);
   
    
    return $block;
}

#
#
# Wrapper to generate additional element attributes based upon input arguments.
#  (should be generic to all standard html objects)
#
# Return: string to include in element tag 
############################  
sub _std_element_options {
############################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'options');
    my $onchange = $args{-onchange};
    
    my $extras;
    if ($onchange) { $extras .= qq(onchange="$onchange"\n) } 
    
    return $extras;
}  

#
# javascript included to accompany multiselect dropdowns.
#
#  Note: this should ADD to the functionality in the custom_bootstrap file, but it doesn't seem to be included... may need to investigate though not important for now..
# 
# Return: inline javascript code to be included with dropdown method
########################
sub _js_init_dropdown {
########################
    my %args = filter_input(\@_);
    my $id = $args{-id};

    ## Advanced Options ##
    
    my $options;
    
    ## add to options based upon input arguments ##
    
    my $init =<<INIT;

<!-- Initialize the plugin: -->
<script type="text/javascript">
    \$(document).ready(function() {
        \$('#$id').style = 'display:block';
        $options
  });
</script>

INIT

    return $init;
}

#
# Simple accessor to multiple-select dropdown menu.
#
#  Usage:
#
#    print $BS->multi_dropdown(-options => \@options, -default=>$default);
#    print $BS->dropdown(-options => \@options, -default=>$default, -type=>'multi');   ## automatically redirected from dropdown()
#
#  It should also support standard element parameter inclusions (eg onchange, class, style etc)
#
# This utilizes a third party plugin (Bootstrap-multiselect) that extends existing bootstrap functionality with associated css & js files
#
# Return: code generating multi-select dropdown menu.
######################
sub multi_dropdown {
######################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'options');

    my $id = $args{-id} || int(rand(1000));
    my $name = $args{-name};
    my $class = $args{-class};
    my $options = $args{-options} || $args{-values} || $args{-value};
    my $default = $args{-default}; 
    my $labels  = $args{-labels};
    my $style = $args{-style};
    my $ajax  = $args{-ajax};
    my $ajax_condition  = $args{-ajax_condition};
    my $multiple = $args{-multiple};
    my $group_labels = $args{-group_labels};

    my @defaults = Cast_List(-list=>$default, -to=>'array');
    
    ## Advanced Options (passed to js initialization method)##
    my $selectAll = $args{-selectAll}; 

    my $block = "<!-- Bootstrap multiselect -->\n";
    
    my $extras = $self->_std_element_options(%args);

    eval "require MIME::Base32";
    
    if ($ajax) { 
        ## caught / used by custom_bootstrap.js ##
        $ajax = qq(ajax="$ajax" );
        if ($ajax_condition) { $ajax .= qq() }
        $class .= ' ajax-populated';
        $block .= "<span class='bs-ms ajax-populated' id='$id'>\n";
    }  
    else {
        $block .= "<span class='bs-ms' id='$id'>\n";
    }

    if ($multiple) { $extras .= "multiple='multiple'" }
    $block .= qq(\n<select id='$id-ms' name='$name' class="$class multiselect" default="$default" style="$style" $ajax $extras>\n);
    
    my ($group, $groups);
    foreach my $option (@$options) {
        my $val = $option;
        my $label = $val;

        if (defined $labels->{$val}) { $label = $labels->{$val} }
        my $selected;   
        
        if (defined $val && defined $default && grep /^$val$/, @defaults) { 
            $selected = 'selected'; 
        }
    
        if ($group_labels && defined $group_labels->{$val} && $group_labels->{$val} ne $group) {
             if ($groups) { $block .= "</optgroup>\n" }
            $groups++;
            
            $group = $group_labels->{$val};
            $block .= qq(<optgroup label="$group">);
        }
        $block .= qq(<option value="$val" $selected>$label</option>\n);
    }
    if ($groups) { $block .= "</optgroup>\n" }
    
    $block .= "</select>\n";
    $block .= "</span>\<!-- end of bootstrap multiselect -->\n\n";


    ## block below ignored for now... (js specs in custom_bootstrap.js) ##
    my $filter;
    my $option_count = int(@$options) if $options;
    if ($option_count > 5 ) { $filter = 1 }
    
    $args{-id} = $id;
#    if ($ajax) { $block .= $self->_ajax_fill_dropdown(-ajax=>$ajax, -id=>$id, -type=>'multiselect') }  
#    $block .= _js_init_multi_dropdown(-selectAll=>$multiple, -filter=>$filter, %args);
    
    return $block;   
}

#
# javascript included to accompany multiselect dropdowns.
# 
# Return: inline javascript code to be included with multi_dropdown
########################
sub _js_init_multi_dropdown {
########################
    my %args = filter_input(\@_);
    my $id = $args{-id};

    ## Advanced Options ##
    my $selectAll = $args{-selectAll} || 1;
    my $filter    = $args{-filter} || 1;

    ## ButtonText does not seem to work when included here (useful for specifying text for case of blank default for dropdown menus) ##
    my $init =<<INIT;

<!-- Initialize the multiselect with custom specifications: -->
<script type="text/javascript">
    \$(document).ready(function() {
    \$('#$id').multiselect( {
        enableFiltering: true,
        filterBehavior: 'both',
        enableCaseInsensitiveFiltering: true,
        filterPlaceholder: 'Search',
        includeSelectAllOption: true,
        includeSelectAllIfMoreThan: 15,
/*        includeSelectAllDivider: true,   Small bug with this option noted */
      /* filterPlaceholder: 'Search', */ 
        onDropdownShown: function(event) {
            /* can we focus on the searchbox when dropdown shown */
         },  
        buttonText: function(options, select) {
                var def = '';
                if ( $(this).attr('multiple') ) { def = 'None selected' }
                else { def = 'Select' }
                
                var selected = '';
                var count = 0;
                var separator = '<BR>';
                options.each(function () {
                    selected += $(this).text() + separator;
                    count = count+1;
                }); 
                var prompt;
                if (selected.length > separator.length) { prompt = selected.substr(0, selected.length - separator.length) }
                else { prompt = def }
                
                if (count > 4) { prompt = count + ' selected' }
                else if (count > 1) { prompt += '<BR>' } /* only use this if using br as a separator */
                
                prompt +=  ' <b class="caret"></b>';
                
                return prompt;
           },
    });
  });
</script>

INIT

        return $init;
}

# UNDER CONSTRUCTION... just started... haven't played with this yet to fine tune it at all...
#
#
##########################
sub _ajax_fill_dropdown {
##########################
    my $self = shift;
    my %args = filter_input(\@_);    
    my $id = $args{-id};
    my $ajax_script = $args{-ajax};
    
    ## Initiated, but not fully set up yet... ##
        
    my $ajax =<<AJAX;

<script  type="text/javascript">
\$(document).ready(function(){
    var \$select = \$("#$id").multiselect(); //apply the plugin
    \$select.multiselect('disable'); //disable it initially
    \$.ajax({
            type: "POST",
            url: "$ajax_script",
            data: "",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: function OnPopulateControl(response) {
                list = response.d;
                if (list.length > 0) {
                    \$select.multiselect('enable');
                    \$("#$id").empty().append('<option value="0">Please select</option>');
                    \$.each(list, function () {
                        \$("#$id").append(\$("<option></option>").val(this['Value']).html(this['Text']));
                        });
                    \$("#$id").val(valueselected);
                }
                else {
                    \$("#$id").empty().append('<option selected="selected" value="0">Not available<option>');
                }
                \$("#$id").multiselect('refresh'); //refresh the select here
            },
            error: function () {
                alert("Error");
            }
        });
});
</script>

AJAX

    return $ajax;
}

#
# Simple wrapper to provide carousel view
# This may be particularly useful for online tutorials - walking users through a multi-step process 
#
# Input: array ref of items to put in each slide, array ref of captions for each slide (indices must match up on slides and captions)
###############
sub carousel2 {
###############
    my $self = shift;
    my %args = filter_input( \@_ );
    my $slides = $args{-slides};
    my $captions = $args{-captions};
    
    my $init = qq(
        <div id='carousel' class='carousel slide' data-ride='carousel' data-interval='false'>
        <!-- Indicators -->
        <ol class='carousel-indicators'>);
    my $counter;
    foreach my $slide (@$slides) {
        
        $init .= qq( <li data-target='#carousel' data-slide-to='$counter'></li> );
        $counter++;
    }
    $init .= qq( </ol> 
                    <!-- Wrapper for slides -->
                );

    my $slide_block = qq(<div class="carousel-inner">);
    
    my $off = 0;
    $counter = 0;
    my $size = scalar(@$slides);
    foreach my $slide (@$slides) {
        my $active = 'active' if !$off++;
        my $alt = 'alter';
        $slide_block .= qq(\t<div class="item $active">\n);
        $slide_block .= qq(\t$slide\n);
        if ($captions) {
            $slide_block .= qq(\t<div class='carousel-caption'>\n);
            $slide_block .= "\t\t@$captions[$counter]\n\t</div><!-- end of caption -->\n";
        }
        $slide_block .= "</div> <!-- end of item -->\n";
        $counter++;
    }
 
    $slide_block .= "</div> <!-- end of carousel -->\n";
    
    my $controls = qq(
        
    <!-- Controls -->
    <a class='left carousel-control' href='#carousel' data-slide='prev'>
    <span class='glyphicon glyphicon-chevron-left'></span>
    </a>
    <a class='right carousel-control' href='#carousel' data-slide='next'>
    <span class='glyphicon glyphicon-chevron-right'></span>
    </a>
    );

   return $init . $slide_block . $controls . "</div> <!-- END OF CAROUSEL -->\n";
}

#
#
# Simple wrapper to provide carousel view
# This may be particularly useful for online tutorials - walking users through a multi-step process 
#
# eg.  print $BS->carousel(-images=>\@images);
#
# Input: array ref of items to put in each slide, array ref of captions for each slide (indices must match up on slides and captions)
###############
sub carousel {
###############
    my $self = shift;
    my %args = filter_input(\@_, -args=>'images,captions');        
    my $images = $args{-images};
    my $captions = $args{-captions};
    my $id = $args{-id} || 'carousel-' . int(rand(10000));
    my $width = $args{-width};
    my $style = $args{-style};
    my $control_type = $args{-control_type} || 'buon';
    my $caption_position = $args{-caption_position} || 'external';  ## internal or external
    my $background_colour = $args{-background_colour} || 'gray';
    my $ms = $args{-interval};   ## in ms
    my $include_indicators = defined $args{-include_indicators} ?  $args{-include_indicators} : 1;

    my $caption_style;
    if ($caption_position =~/external/i) { $caption_style .= " position:initial;" }
    if ($background_colour) { $style .= " background-color:$background_colour;" }
   
    my $image_style = qq(style="max-width:$width%; " width="$width%");
    
    my $caption_width = $width - 10;
    $caption_style .= " max-width:$caption_width%;";
   
   my $count = int(@$images);
   my $last_index = $count - 1;
   
   my $init = qq(<div id='$id' class='carousel slide' data-ride='carousel' style='$style' data-interval="$ms">);
   
   my $indicators;
   if ($include_indicators) {
       $indicators = qq(
           <!-- Indicators -->
           <ol class='carousel-indicators' style='position:relative'>
           <li data-target='#$id' data-slide-to='0' class='active'></li>
       );

       if ($count > 1) {
           foreach my $i (1..$last_index) {
               $indicators .= qq(<li data-target='#$id' data-slide-to='$i'></li>\n);
           }
       }
       $indicators .= "</ol>\n<!-- Wrapper for slides -->\n";
   }
       
   my $image_block = qq(<div class="carousel-inner" >);

   my $off = 0;  
   foreach my $i (1 .. int(@$images)) {
       my $image = $images->[$i-1];
       my $caption = $captions->[$i-1] ;
       my $active = 'active' if !$off++;
       my $alt = 'alter';
       $image_block .= qq(\t<div class="item $active"><center>\n);
       $image_block .= qq(\t<img src="$image" alt="$alt" $image_style width=$width>\n);
       if ($caption) { 
           $image_block .= qq(\t<div class="carousel-caption" style="$caption_style">\n);
           $image_block  .= "\t\t$caption\n\t</div> <!-- end of caption -->\n";
       }
       $image_block .= "</center></div> <!-- end of item -->\n";
   }
     
   $image_block .= "</div> <!-- end of carousel -->\n";

   my $controls = "<!-- Controls -->\n";

   if ($control_type =~/button/i) {
       ## Use buttons to control carousel ##
       $controls .= qq(       
           <div style="text-align:center; background-color:$background_colour;">
           <input type="button" class="btn cycle-slide" data-target="$id" id="$id-cycle" value="Start">
           <input type="button" class="btn pause-slide" data-target="$id" id="$id-pause" value="Pause">
           <input type="button" class="btn prev-slide" data-target="$id" id="$id-prev" value="Prev">
           <input type="button" class="btn next-slide" data-target="$id" id="$id-next" value="Next">
           $indicators
           </div>
           );
    }
    else {
        ## use default > and < chevrons to move back and forth ##
        $controls .= qq(       
            <a class='left carousel-control' href='#$id' data-slide='prev'>
            <span class='glyphicon glyphicon-chevron-left'></span>
            </a>
            <a class='right carousel-control' href='#$id' data-slide='next'>
            <span class='glyphicon glyphicon-chevron-right'></span>
            </a>
            $indicators
        );

    }
    
    my $include = qq( );

   return $init . $image_block . $controls . $include . "</div>\n<!-- END OF CAROUSEL -->\n";

}


################
sub test_page {
################
    my $self = shift;
    
    my $page;
    
    my $menu_specs = [
            {'Simple Menu' => ['1a','1b']}, 
            {'external link' => 'http://google.ca'}, 
            {'Empty' => ''}, 
            {'multi-level' => [ {'4a' => 'link'}, {'4b' => [{'4b1' => 'ok'}, {'4b2' => ['x','y',{'z' => 'z1'}]}]} ] }
        ];
        
    ## Show top-positioned fixed header ... ##
    $page .= $self->header(-left=>'left_header_icon', -centre=>'centre_Header_Block', -right=>[{'short list' => ['abc', 'xyz']}, {'more options' => ['User: ', 'Pwd: ']}, 'scalar'], -position=>'top', -span=>4);    
    $page .= $self->header(-left=>'', -centre=>'Main Footer', -right=>'right', -position=>'bottom', -span=>[4,4,4]);

    ## menu 
    $page .= $self->menu($menu_specs);
    
    ## Alert messages ##
    my $messages = $self->message('message');
    $messages .= $self->warning('std warning');
    $messages .= $self->error('std err');
    $messages .= $self->success('success');

    $messages .= "<HR>Icon generation<P>";
    $messages .= "calendar: " . $self->icon('calendar') . ' ';
    $messages .= ".... with onclick spec:" . $self->icon('calendar', -onclick=>"alert('with onclick...'); return false; ");

    
    ##########################
    ##### Form Generation ####
    ##########################
   
    ## Full Form Examples ##
    my $datefield1 = $self->calendar(-field_name=>'date', -id=>'date1', -quick_link=>'day,month,year');
    my $datefield2 = $self->calendar(-field_name=>'date', -id=>'date2', -quick_link=>'day,month,year', -type=>'datetime');
    my $datefield2b = $self->calendar(-field_name=>'date', -id=>'date2', -quick_link=>'day,month,year', -type=>'datetime', -calendar_format=>'jquery');
    my $datefield3 = $self->calendar(-field_name=>'date', -id=>'date3', -quick_link=>'day,month,year');
    my $daterange1 = $self->calendar(-field_name=>'date', -id=>'date4', -range=>1, -quick_link=>'day,month,year', -inline=>1); 
    my $daterange2 = $self->calendar(-field_name=>'date', -id=>'date5', -range=>1, -quick_link=>'day,month,year', -inline=>0); 
    my $daterange3 = $self->calendar(-field_name=>'date', -id=>'date6', -range=>1, -quick_link=>'day,month,year', -inline=>0); 
    
       my $first = $self->form_element(-label=>'First Name', -input=> qq(<input type="text"></input> <!-- end of input -->), -span=>[2,4]);
       my $last = $self->form_element(-label=>'Last Name', -input=> qq(<input type="text"></input> <!-- end of input -->), -span=>[2,4]);
       my $email = $self->form_element(-label=>'Email Address', -input=> qq(<input type="text"></input> <!-- end of input -->), -span=>[2,10]) ;
       my $date = $self->form_element(-label=>'Date', -input=> $datefield1 , -span=>[2,10]) ;
       my $date2 = $self->form_element(-label=>'Range', -input=> $daterange1 , -span=>[2,10]) ;

       my $extra = $self->form_element(-label=>'Extra preset', -input=>'default value', -span=>[2,10]);

    my $full_form = "Bootstrap form generator options:";
    $full_form .= $self->form( [$first . $last, $email, $date, $extra], -style=>'background-color:#ccc', -span=>[6,6], -type=>'horizontal', -initialize=>"<Form >");
    
    eval "require LampLite::Form";  ## use form to test form output .. ##

    require LampLite::Form;
    my $Form = new LampLite::Form(-style=>'background-color:#afa; padding:20px', -span=>[2,10], -class=>'form-horizontal', -framework=>'bootstrap');
    $Form->append(-label=>'First Name', -input=> qq(<input type="text"></input> <!-- end of input -->));
    $Form->append(-label=>'Last Name', -input=> qq(<input type="text"></input> <!-- end of input -->));
    $Form->append(-label=>'Email Address', -input=> qq(<input type="text"></input> <!-- end of input -->));
    $Form->append(-label=>'DatePlus', -input=> $datefield2);
    $Form->append(-label=>'DatePlus2', -input=> $datefield2b);
    $Form->append(-label=>'Range', -input=> $daterange2 );
    $Form->append(-label=>'Extra with Default', -input=> "<B>Extra with default</B>"); 
    
    $full_form .= $Form->generate(-open=>1, -close=>1);
 
    $full_form .= '<hr>';
    $full_form .= "Standard table form generator:";
    my $Form = new LampLite::Form(-style=>'background-color:#faa', -span=>[6,6], -type=>'horizontal', -framework=>'table');
    $Form->append(-label=>'First Name', -input=> qq(<input type="text"></input> <!-- end of input -->), -span=>[2,4]);
    $Form->append(-label=>'Last Name', -input=> qq(<input type="text"></input> <!-- end of input -->), -span=>[2,4]);
    $Form->append(-label=>'Email Address', -input=> qq(<input type="text"></input> <!-- end of input -->));
    $Form->append(-label=>'Date', -input=> $datefield3 );
    $Form->append(-label=>'Range', -input=> $daterange3 );
    $Form->append(-label=>'Extra with Default', -input=> "<B>Extra with default</B>"); 
    $full_form .= $Form->generate();
    
    ## Form Elements ##
    my $form = "<HR>Form Elements:<HR>";

    my @options = ('A' .. 'Z');
    
    $form .= 'No filter:<BR>' 
        . $self->dropdown(-id=>'abc', -options=>\@options, -default=>'C');
    
    $form .= 'With filter:<BR>' 
        . $self->dropdown(-id=>'abc', -options=>\@options, -default=>'C', -filter=>1);   ## normal dropdown 

    $form .= 'multi-select:<BR>' .
        $self->dropdown(-id=>'abcd', -options=>\@options, -selectAll=>1, -type=>'multiple', -default=>['G','H','I']);  ## multiple select 
       
    $form .= "<HR>";   
    $form .= $self->success("tooltip / popovers");
    $form .= $self->load_tooltip_js();

    $form .= $self->text_group_element(-name=>'hello2', -tooltip=>'tooltip', -placeholder=>'tooltip', -prepend_text => 'Prepend', -append_text=>'Append');
    $form .= $self->text_group_element(-name=>'hello3', -tooltip=>'tooltip2', -popover=>'popover2', -placeholder => 'tooltip and popover');

    $form .= '<HR>';

    my $modals = $self->modal(-body=>'Content of standard modal', -title=>'Modal Title', -label=>'Modal');

    my $i = 1;
    foreach my $i (1..3) {
        $form .= $self->calendar(-name=>'hello4', -id=>"d-$i", -append=>1) . "<P>";
    }
    
    $form .= "<P> try range...";
    $form .= $self->calendar(-id=>'cal2', -from=>"date", -to=>'date2', -default=>'2013-03-04') . "<P>";
    
    my @layers = ({'Tab A' => 'Section 1'}, {'Tab B' => 'Section 2'});

    my $layers = $self->layer(-layers=>\@layers, -active=>'Tab B');
   
    $page .= $self->accordion( 
        -layers => [ 
            {'label' => 'Form Elements', 'content' => $form },
            {'label' => 'Full Forms', 'content' => $full_form },
            {'label' => 'Messages', 'content' => $messages },
            {'label' => 'Layers', 'content' => $layers },
            {'label' => 'Modals', 'content' => $modals },
            ] );              
              
    return $page;
}

##########################
sub dropdown_width_test {
##########################
    my $self = shift;

my $test =<<TEST;
<select style='width:50px'>
    <option value="1">Test 1</option>
    <option value="2">Test 2</option>
    <option value="3">Test 3 with a really long name that doesn't need to maintain the window size... </option>
</select>
<select style='width:500px'>
    <option value="1">Test 1</option>
    <option value="2">Test 2</option>
    <option value="3">Test 3</option>
</select>

TEST

    return $test;
}

# 
# Javascript to manage hierarchical dropdowns in menu with left / right caret indicators 
#
##############
sub menu_js {
##############

    my $js =<<JS;
    
<script type="text/javascript">
    \$(function(){
        \$(".dropdown-menu > li > a.trigger").on("click",function(e){
            var current=\$(this).next();
            var grandparent=\$(this).parent().parent();
            
            if(\$(this).hasClass('left-caret')||\$(this).hasClass('right-caret')) {
                \$(this).toggleClass('right-caret left-caret');
 
                grandparent.find('.left-caret').not(this).toggleClass('right-caret left-caret');
            }
            
            if(\$(this).hasClass('up-caret')||\$(this).hasClass('down-caret')) {
                \$(this).toggleClass('down-caret up-caret');
            
                grandparent.find('.up-caret').not(this).toggleClass('down-caret up-caret');
            }
                
            grandparent.find(".sub-menu:visible").not(current).hide();
            current.toggle();
            e.stopPropagation();
        });
        \$(".dropdown-menu > li > a:not(.trigger)").on("click",function(){
            var root=\$(this).closest('.dropdown');
            root.find('.left-caret').toggleClass('right-caret left-caret');
            root.find('.up-caret').toggleClass('down-caret update_Progress-caret');
            root.find('.sub-menu:visible').hide();
        });
    });
</script>


JS

    return $js;
}

##############################
# private_functions          #
##############################

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

1;
