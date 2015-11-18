package LampLite::JQuery;

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::JQuery.pm - Wrapper for jquery embedded elements

Note: some of these may also depend on parallel implementation of Bootstrap or other standard UI frameworks, but are not part of the standalone Bootstrap functionality
(see Bootstrap module for standard bootstrap wrapper methods)

=head1 SYNOPSIS <UPLINK>

Assumes jquery included 

# Usage examples:
#
#  print $JQ->calendar();
#  print $JQ->dropdown_list(-list=>\@list, -autocomplete=>$ajax_on);
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
use RGTools::RGIO qw(filter_input date_time);
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################

##############################
# global_vars                #
##############################

my $t = "\t";

###################
# Constructor
#
# Simple jquery object constructor
#
##########
sub new {
##########
    my $this = shift;
    my $class = ref($this) || $this;

    my ($self) = {};
    bless $self, $class;

    $self->{status} = '';

    ### List of files included should be kept up to date and fully tested if updated ###
    $self->{js_files} = [
        qw(
            jquery-1.10.2.min
            jquery-migrate
            jquery-ui-1.10.3.custom.min
            )
    ];

    return $self;
}

#####################################################
# Wrapper to generate HTML Header with bootstrap file
#
# Return: HTML code to include js file
###############
sub load_js {
###############
    my $self  = shift;
    my $path  = shift;
    my $files = shift || $self->{js_files};

    my $js;
    foreach my $file (@$files) {
        $js .= "<script src='$path/$file.js'></script>\n";
    }

    return $js;
}

#
# Wrapper for simple datetime picker (variation from showCalendar js option)
#
# Usage: When creating a text field, if you want the calendar to show up onclick call calendar using the same element id
# Example: $output = $q->textfield( -id => $element_id, ...);
#          $output .= $JQ->calendar( -id => $element_id, ...);
#
# Note that you do not need to specify to open the calendar onclick for the text field since they share the same element id.
# If you pass in the call as an onclick argument, then the calendar will initialize onclick rather than displaying.
#
# To open the calendar using an element other than the text field used to initialize the calendar pass in the following argument for onclick:
# -onclick => "jQuery('#$element_id').datetimepicker('show');"
# where $element_id is the element id of the text field
#
# Example: $output = $BS->text_element(-id => $element_id, -icon_append => $icon, -icon_onclick => "jQuery('#$element_id').datetimepicker('show');", ...);
#          $output .= $BS->calendar( -id => $element_id, ...);
#
# Output: JavaScript to initialize calendar for the provided element id
#
###############
sub calendar {
###############
    my $self = shift;
    my %args = &filter_input( \@_, -args=>'id', -mandatory=>'id' );
    my $id              = $args{-id};
    my $show_date       = $args{-show_date} || 'true';      ## whether or not to show datepicker; defaults to true;
    my $show_time       = $args{-show_time} || 'true';      ## whether or not to show timepicker; defaults to true;
    my $value           = $args{-value};                    ## current value of datetimepicker; if set, ignores input.value;
    my $lang            = $args{-language} || 'en';         ## language; defaults to Egnlish;
    my $format          = $args{-format} || 'Y-m-d H:i';    ## format of datetimepicker; defaults to YYYY-MM-dd HH:mm;
    my $step            = $args{-step} || 1;                ## number of minutes between intervals in timepicker; defaults to every 1 minute;
    my $close_on_date   = $args{-close_on_date} || 'false'; ## whether or not the calendar show close on selection of date (for example, if you disable the timepicker); defaults to false;

   #  my $cal = "<script type='text/javascript'>jQuery(function(){\njQuery('#$id').datetimepicker({\n" . "\tdatepicker:$show_date,\n" . "\ttimepicker:$show_time,\n" . "\tvalue:'$value',\n" . "\tlang:'$lang',\n" . "\tformat:'$format',\n" . "\tstep:$step,\n" . "\tcloseOnDateSelect:$close_on_date,\n" . "\tvalidateOnBlur:false,\n" .
 # "\t});\n});</script>";
    
    my $cal = "jQuery('#$id').datetimepicker({\n" . "\tdatepicker:$show_date,\n" . "\ttimepicker:$show_time,\n" . "\tvalue:'$value',\n" . "\tlang:'$lang',\n" . "\tformat:'$format',\n" . "\tstep:$step,\n" . "\tcloseOnDateSelect:$close_on_date,\n" . "\tvalidateOnBlur:false\n}); jQuery('#$id').datetimepicker('show');";

    return $cal;
}

###############################
### Flexbox wrapper methods ###
###############################

### Under Construction ###

###############
sub flexbox {
###############
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'content,flex' );
    my $list      = $args{-content};
    my $flex      = $args{-flex} || 1;
    my $direction = $args{-direction};
    my $justify   = $args{-justify_content};
    my $style     = $args{-style};
    my $toggle    = $args{-toggle};
    my $id        = $args{-id} || int( rand(1000) );
    my $tag_type  = $args{-tag_type} || 'div';

    my $flexbox;

    if ($toggle) {

        #        $flexbox .= qq(<nav class = 'navbar navbar-default col-md-12' style='$style'>\n);
        if ( $toggle eq '1' ) { $toggle = '<!-->' }
        $flexbox .= $self->toggle( -id => $id, -button => $toggle );
        $flexbox .= $self->toggle_open($id);
    }

    if ($direction) { $style .= "flex-direction:$direction;" }
    if ($justify)   { $style .= "justify-content:$justify;" }

    my $display_flex = $self->flex_display_css();

    $flexbox .= "<$tag_type class='flexbox-row' style='$display_flex; $style'>\n";

    foreach my $i ( 1 .. int(@$list) ) {
        my $item = $list->[ $i - 1 ];
        my $style;

        if ( $flex && ref $flex eq 'ARRAY' ) { $style = $self->flex_css( $flex->[ $i - 1 ] ) }    ## "flex:$flex->[$i-1]"}
        elsif ($flex) { $style = $self->flex_css($flex) }                                         ## "flex: $flex" }

        $flexbox .= "\t<span style='$style'>\n";
        $flexbox .= "\t\t" . $item;
        $flexbox .= "\t</span> <!-- end of span for section $i -->\n";
    }

    $flexbox .= "</$tag_type> <!-- end of flexbox-row $tag_type -->\n";

    if ($toggle) { $flexbox .= $self->toggle_close() }

    return $flexbox;
}

########################
sub flex_display_css {
########################
    my $self      = shift;
    my %args      = @_;
    my $direction = $args{-direction};

    my $css = "display: -webkit-box;"    ## /* OLD - iOS 6-, Safari 3.1-6 */
        . "display: -moz-box;"           ## /* OLD - Firefox 19- (buggy but mostly works) */
        . "display: -ms-flexbox;"        ## /* TWEENER - IE 10 */
        . "display: -webkit-flex;"       ## /* NEW - Chrome */
        . "display: flex; ";             ## /* NEW, Spec - Opera 12.1, Firefox 20+ */

    if ($direction) {
        $css .= "flex-direction: $direction; ";
    }

    return $css;
}

########################
sub flex_css {
########################
    my $self  = shift;
    my $value = shift;

## width: 20%;               /* For old syntax, otherwise collapses. */

    my $flex_css
        = "-webkit-box-flex: $value;      /* OLD - iOS 6-, Safari 3.1-6 */\n"
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

    my $flex_order_css = <<ORDER;
-webkit-box-ordinal-group: $value;  
-moz-box-ordinal-group: $value;     
-ms-flex-order: $value;     
-webkit-order: $value;  
order: $value;
ORDER

    return $flex_order_css;
}

#
# Local wrapper for making dropdown lists and scrolling lists.
#
# May access third party tools to this more effectively than with pure HTML.
#
# Return: block of code generating list
######################
sub dropdown_list {
######################
    my $list;

    return $list;
}

##############################
### End of Flexbox methods ###
##############################

#
# Simple wrapper to generate test page to simplify testing of UI functionality for this module
#
#
#
# Return: UI test page
################
sub test_page {
################
    my $self = shift;

    my $page;

    my $i = 1;
    $page .= "Test interface elements here......<P>\n";

    $page .= "<P> try range with default...<P>\n";

    return $page;
}

##############################
# private_functions          #
##############################

#===  FUNCTION  ================================================================
#         NAME: initializeDropdownPlugin
#      PURPOSE: Start Dropdown plugin
#   PARAMETERS: TBD
#      RETURNS: HTML String that calls the javascript function that will start the plugin
#===============================================================================
sub initializeDropdownPlugin {
    my $final = "<script> window.onload=initializeSelect2();</script>";
    $final .= <<Tooltip;
    <script type="text/javascript">window.onload=\$(document).ready(function () {\$("[rel=tooltip]").tooltip();});</script>
Tooltip
    return $final;
}    ## --- end sub initializeDropdownPlugin

##############################
# Simple wrapper to provide SlidesJS view
#
# Input: array ref of items to put in each slide, array ref of captions for each slide (indices must match up on slides and captions)
#
##############################
sub carousel {
    my %args     = filter_input( \@_ );
    my $slides   = $args{-slides};
    my $captions = $args{-captions};
    my $items    = $args{-items} || 2;
    my $id       = $args{-id} || int( rand(1000) );

    my $slide_block = qq( <div class='owl-carousel' id='carousel-$id'>\n );

    foreach my $slide (@$slides) {
        $slide_block .= qq(\t<div>);
        $slide_block .= qq($slide);
        $slide_block .= qq(</div>\n);
    }

    $slide_block .= "</div> <!-- end slidesjs -->\n";

    $slide_block .= qq(
        <script>
            \$\(document\).ready\(function\(\) {
                \$\('#carousel-$id'\).owlCarousel\({
                    items: $items,
                    itemsDesktopSmall: [979, 1],
                    itemsTablet: [768, 1],
                    paginationSpeed: 200,
                    navigation: true,
                    paginationNumbers: true
                }\);
            }\);
        </script>
        );

    return $slide_block;

}

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

Ran Guin

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

1;
