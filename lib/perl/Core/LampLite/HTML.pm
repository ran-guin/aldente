###################################################################################################################################
# LampLite::HTML.pm
#
# Basic HTML based tools for LAMP environment
#
###################################################################################################################################
package LampLite::HTML;

use Data::Dumper;

use LampLite::Bootstrap;
use LampLite::CGI;

use RGTools::RGIO qw(filter_input date_time Cast_List today Show_Tool_Tip Call_Stack);

my $q = new LampLite::CGI;
my $BS = new Bootstrap();
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::HTML.pm - HTML Tools available for LampLite Package

=head1 SYNOPSIS <UPLINK>


=head1 DESCRIPTION <UPLINK>

=for html

=cut

@ISA = qw(Exporter);

require Exporter;

@EXPORT = qw(
    HTML_Dump
    set_validator
    create_tree
    page_heading
    section_heading
    subsection_heading
);

use strict;

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);

##############################
# public methods            #
##############################

#
# Initialize html page with header, css, js files
#
########################
sub initialize_page {
########################
    my %args      = filter_input( \@_ );
    my $js_files  = $args{-js_files};
    my $css_files = $args{-css_files};
    my $css_path  = $args{-css_path} || $args{-path} . '/css';  ## may need to be revised for setup.pl
    my $js_path   = $args{-js_path} || $args{-path} . '/js';
    my $bootstrap = $args{-include_bootstrap};
    my $min_width = $args{-min_width};
    my $style     = $args{-style};
    my $class     = $args{-class} || 'body';

    my $suppress_content_type = $args{-suppress_content_type};    ## suppress Content-type: text/html\n\n lines (not required for html files)

    my $page;

    if ( !$suppress_content_type ) { $page .= "Content-type: text/html\n\n" }
    $page .= <<INIT;
<!DOCTYPE HTML>
<HTML>
<HEAD>

<meta name='viewport' content='width=device-width, initial-scale=1.0'>
INIT

    ###################################
    ## Load CSS &&  Javascript Files ##
    ###################################
    $page .= "<!-- Load CSS -->\n";

    $page .= load_css( $css_path, $css_files );

    $page .= "\n<!-- Load JavaScript -->\n";

    $page .= load_js( $js_path, $js_files );

    $page .= $BS->load_tooltip_js();
    $page .= $BS->menu_js();           ## generates js for main menu control and left / right caret markers

    $page .= "</HEAD>\n";

    if ($min_width) {
        $style .= "min-width:${min_width}px; ";
    }

    $page .= "<BODY id='body' class='$class' style='$style'>\n";

    return $page;
}

#
# Wrapper to easily enable a block to be toggled open and closed.
# 
# The toggle (which can be either an icon or a label) may be separated spacially from the content which is toggled.
#
# Usage:
#
#  my ($button, $content) = toggle_section(-icon=>['expand'], $content);   ## simple usage enables content to be displayed when expand icon is clicked
# 
#  (or include alternate content)
#
#   my ($button, $content) = toggle_section(-label=>['Content A','Content B'], -content=>[$contentA, $contentB]);  ## toggles content section between content A and content B (content B defaults to visible)
#
#  (this also toggles on and off the toggle labels so that 'Content A' toggle button appears when contentB is visible and vice versa)
# 
#  Return: array (toggle block, content block)
#####################    
sub toggle_section {
#####################
        my %args = filter_input(\@_);
        my $id   = $args{-id} || int( rand(1000));
        my $name = $args{-name};
        my $label = $args{-label} || $args{-open_label};
        my $icon = $args{-open_icon} || $args{-icon};
        my $content = $args{-open_content} || $args{-content};
        
        my $close_icon = $args{-close_icon};
        my $close_label = $args{-close_label};
        my $close_content = $args{-close_content};
        my $close_tooltip = $args{-close_tooltip};
        
        my $tooltip = $args{-tooltip};
        my $button_class = defined $args{-button_class} ? $args{-button_class} : 'Std btn';
        my $button_style = $args{-button_style};
        
        if (ref $icon eq 'ARRAY') { $close_icon = $icon->[1]; $icon = $icon->[0] }  ## allow input in form -icon=>['open','close']

        if (ref $label eq 'ARRAY') { $close_label = $label->[1]; $label = $label->[0] }  ## allow input in form -icon=>['open','close']
                 
        if (ref $content eq 'ARRAY') { $close_content = $content->[1]; $content = $content->[0] }  ## allow input in form -content => ['content 1 ','content 2'] Note: content 2 is open to start ... 

        if (ref $tooltip eq 'ARRAY') { $close_tooltip = $tooltip->[1]; $tooltip = $tooltip->[0] }  ## allow input in form -icon=>['open','close']
         
        my $open = "unHideElement('$id'); ";
        my $close = "HideElement('$id'); ";
        
        if ($close_icon || $close_label) { 
             $close .= " HideElement('$id-close'); unHideElement('$id-open');";
            $open .= " unHideElement('$id-close'); HideElement('$id-open');";
        }

        my $block;
        if ($close_content) {
            $open .= "HideElement('$id-closed'); ";
            $close .= "unHideElement('$id-closed'); ";            
        }
        
        my $toggle = $BS->button(-name=>$name, -label=>$label, -id=>$id . '-open', -class=>$button_class, -style=>$button_style, -icon=>$icon, -onclick=>"$open return false;", -tooltip=>$tooltip);

        if ($close_icon || $close_label) { 
            $toggle .= $BS->button(-name=>$name . '-close', -label=>$close_label, -id=>$id . '-close', -class=>$button_class, -icon=>$close_icon, -style=>'display:none', -onclick=>"$close return false;", -tooltip=>$close_tooltip) 
        }
    
        my $block;
        if ($content) {
            $block .= "<div style='display:none' id='$id' class='toggle-block open-content'>"
            . $content               
            . "</div>\n";
        }
        if ($close_content) { 
            $block .= "<div style='display:block' id='$id-closed' class='toggle-block closed-content'>"
            . $close_content               
            . "</div>\n";        
        }
        
        return ($toggle, $block );
}

#########################
sub uninitialize_page {
#########################
    my %args   = filter_input( \@_ );
    my $mobile = $args{-mobile};

    
    return "<!--- Uninitialized Page --->\n</BODY>\n</HTML>\n";
    
    
    ## only use this if non-standard dropdown plugin is being used ##
    my $block = "</body>\n</html>\n";
    unless ($mobile) {
        $block = LampLite::JQuery::initializeDropdownPlugin() . $block;
    }
    return $block;
}

#
# check for browser version limitations
#
# Return: 1 on success (warning generated inline if browser version not up to date)
####################
sub browser_check {
####################
    my %args        = @_;
    my $required    = $args{-required} || {};
    my $recommended = $args{-recommended} || {};
    my $dbc         = $args{-dbc};

    my $browser = $ENV{HTTP_USER_AGENT};
    my $pass    = 1;
    my $check   = { %$required, %$recommended };

    foreach my $key ( keys %$check ) {
        my $needed      = $required->{$key};
        my $recommended = $recommended->{$key};

        if ( $browser =~ /$key\/(\d+)([\d\.]+)/i ) {
            my $version    = $1;
            my $subversion = $2;

            my $recommended_message;
            if ($recommended) { $recommended_message = "(Version $recommended is suggested)" }

            if ( $needed && $version < $needed ) {
                my $message = "Your version ($version [$subversion]) of Firefox seems out of date.  Version $needed is a minimum requirement. $recommended_message\n You will need to update your browser to enable this interface to work correctly.";
                if   ($dbc) { $dbc->error($message) }
                else        { print $BS->error($message) }
                $pass = 0;
            }
            elsif ( $recommended && $version < $recommended ) {
                my $message = "Your version ($version [$subversion]) of Firefox seems out of date. $recommended_message\n  We recommend that you update your browser.";
                if   ($dbc) { $dbc->warning($message) }
                else        { print $BS->warning($message) }
            }
        }
    }

    return $pass;
}

#
# Simple wrapper to load list of js files under a specified path
#
# Input:
#    -path:  URL path where js files are located
#    -files: array of files to load
#
#
#############
sub load_js {
#############
    my %args    = &filter_input( \@_, -args => 'path, files, comment', -mandatory => 'path,files' );
    my $path    = $args{-path};
    my $files   = $args{-files};
    my $comment = $args{-comment};

    my $block = "<!-- Load JS Files $comment -->\n";
    if ( !ref $files ) { $files = [$files] }
    foreach my $file (@$files) {
        my $full_file = $file;
        if ( !$file ) {next}
        if ( $file !~ /\.js$/ ) { $full_file .= '.js' }
        if ( $file !~ /:/ ) { $full_file = "$path/$full_file" }    ## include path if not fully qualified ##
        $full_file =~s/(\w)\/\//$1\//g; ##
        $block .= "<script type='text/javascript' src='$full_file'></script>\n";
    }
    return $block;
}

#
# Simple wrapper to load list of css files under a specified path
#
# Input:
#    -path:  URL path where js files are located
#    -files: array of files to load
#
#
#############
sub load_css {
#############
    my %args    = &filter_input( \@_, -args => 'path, files, comment', -mandatory => 'path,files' );
    my $path    = $args{-path};
    my $files   = $args{-files};
    my $comment = $args{-comment};

    my $block = "<!-- Load CSS Files $comment -->\n";
    if ( !ref $files ) { $files = [$files] }
    foreach my $file (@$files) {
        my $full_file = $file;
        if ( !$file ) {next}
        if ( $file !~ /\.css$/ ) { $full_file .= '.css' }
        if ( $file !~ /:/ ) { $full_file = "$path/$full_file" }    ## include path if not fully qualified ##
        $full_file =~s/(\w)\/\//$1\//g; ##
        $block .= "<LINK rel='stylesheet' type='text/css' href='$full_file'>\n";
    }
    return $block;
}

######################
sub get_media_file {
######################
    my %args = &filter_input( \@_, -args => 'type' );
    my $type = $args{-type};                                       ## image, video, audio ...

    my $HTML = <<HTML;

    <form action="server.cgi" method="post" enctype="multipart/form-data">
      <input type="file" name="$type" accept="$type/*" default="$type File" placeholder="$type File" capture >
      <input type="submit" value="Upload">
    </form>
    
HTML

}

###############################
#  Similar to Dumper::Dump, but more easily viewed if passing to a web page.
#
# Note: this excludes the dbc argument in a hash if applicable
# (if you want to view the dbc within a hash, include it as a separate argument:
#    eg print HTML_Dump \%args, $args{-dbc}'
#
# <snip>
#  Example:  print HTML_Dump(\%Results);
# </snip>
# Return: scalar version of output.
#################
sub HTML_Dump {
#################
    my @input = @_;

    my @swap_args  = ( 'dbc', '-dbc' );    ## replace dbc object with scalar indicating connection status ##
    my %swapped;

    my $dump = "\nHTML_Dump:<BR>\n";
    foreach my $v (@input) {
        my $ref = ref $v;
        my $dbc;                          ## placeholder just in case we want to hide dbc... ##
        if ( UNIVERSAL::isa( $v, 'HASH' ) ) {
            foreach my $swap (@swap_args) {
                if ( defined $v->{$swap} ) {
                    $swapped{$swap} = $v->{$swap};

                    if ( $v->{$swap}->isa('LampLite::DB') ) {
                        if ( $v->{$swap}{connected} ) {
                            $v->{$swap} = 'connected';

                            #   print "-dbc => 'is connected'";
                        }
                        else {
                            $v->{$swap} = 'not connected';

                            #$dump .= '(dbc is NOT connected)';
                        }
                    }
                }

                #next;
            }    ## hide dbc argument if included
        }
        $dump .= "<U>$ref:</U><BR>";

        $dump .= "\n<PRE>\n";
        $dump .= _truncated_dump($v);    ## removes dbc object from dump ...
        $dump .= "\n</PRE>\n";

        if ( UNIVERSAL::isa( $v, 'HASH' ) ) {
            foreach my $swap (@swap_args) {
                if ( defined $swapped{$swap} ) { $v->{$swap} = $swapped{$swap} }    ## restore again...
            }
        }
    }
#    Call_Stack();
    return $dump;
}

#####################
sub _truncated_dump {
#####################
    my $v      = shift;
    my $remove = shift || 'dbc';
    my $class  = shift || 'LampLite::DB';

    my $dumper = Dumper $v;
    
    my $include;
    if ( $remove eq 'dbc' ) {
        $dumper =~ /'connected'\s*=>\s*(\w+)/xms;
        $include = "'connected' => $1";
    }

    $dumper =~ s /'-?$remove'\s*\=>\s*bless\((.*)'(LampLite::DB|SDB::DBIO)'/'$remove' \=> bless\( { $include }, '$2'/xms;

    return $dumper;
}

########################################
#
# Creates validator tags that will be used to validate an HTMLFromElement
#
# Requires: www/js/LampLite.js validateForm(<HTMLFormElement>)
#
# <snip>
#
# start_form('myForm');
# textfield(-name=>'Library');
# set_validator(-name=>'Library',-format=>'{\w}{5,6}',-mandatory=>1,-prompt=>'Library Name');
# ...
# submit(-name=>'Submit Form',-onClick=>'return validateForm(this.form)');
# print '</form>;
#
# </snip>
#
####################
sub set_validator {
####################
    my %args = &filter_input( \@_, -args => 'name,format,mandatory,prompt' );

    my $field     = qq^name="$args{-name}"^;
    my $alias     = qq^alias="$args{-alias}"^ if ( $args{-alias} );
    my $format    = qq^format="$args{-format}"^ if ( $args{'-format'} );
    my $mandatory = qq^mandatory="$args{-mandatory}"^ if ( $args{-mandatory} );
    my $readonly  = qq^readonly="$args{-readonly}"^ if ( $args{-readonly} );
    my $id        = qq^id="$args{-id}"^ if ( $args{-id} );
    my $prompt    = qq^prompt="$args{-prompt}"^ if ( $args{-prompt} );
    my $type      = qq^type="$args{-type}"^ if ( $args{-type} );
    my $count     = qq^count="$args{-count}"^ if ( $args{-count} );
    my $confirm   = qq^confirmPrompt="$args{-confirmPrompt}"^ if ( $args{-confirmPrompt} );

    ## add optional case & case_value options so that the indicated condition can depend upon a specific case
    #  eg if there is a radio_group with a radio_group optionA =  1,2 or 3... an element may only be mandatory for option 2 (case_name=>optionA, -case_value=>'2')
    #
    my $case       = qq^case_name="$args{-case_name}"^   if ( $args{-case_name} );
    my $case_value = qq^case_value="$args{-case_value}"^ if ( $args{-case_value} );

    return qq^<validator $id $field $alias $format $mandatory $readonly $prompt $type $count $case $case_value $confirm> </validator>\n^;
}

##################
sub clear_tags {
##################
    my %args         = filter_input( \@_, -args => 'string' );
    my $string       = $args{-string};
    my $trim_spaces  = defined $args{-trim_spaces} ? $args{-trim_spaces} : 1;    ## trim leading and trailing space characters
    my $clear_script = $args{-clear_script};
    my $debug        = $args{-debug};

    if ($clear_script) { $string =~ s/<script\b(.*?)<\/script>//gxmsi }          ## clear any script text within the given string  (eg javascript specifications)

    while ( $string =~ s /<[^\d][^<]*?>//xms ) { }

    if ($trim_spaces) {
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
    }

    return $string;
}

###############################################################
#  Create a java script tree structure based on keys in a hash being "branches" and the values stored in arrays
#
# Dependencies:
#
# LampLite.js functions showBranch() and swapFolder()
#
# <snip>
# Example:
#  my @array3 = (6,7,8);
#  my %subhash = (Sub_directory=>\@array3);
#  my @array=(1,2,3);
#  my @array2=(4,5,\%subhash);
#  my %hash = (Directory1=>\@array, Directory2=>\@array2);
#
#
#  my $output = create_tree(-tree=>\%hash, -print=>1)
#
# </snip>
#
#
# RETURN: String output of the HTML or 1 (print the output directly)
###############################################################
#####################
sub create_tree {
#####################
    my %args = &filter_input( \@_, -args => 'tree,print', -mandatory => 'tree' );

    my $tree                 = $args{-tree};                                             ## hash containing keys that become the directory name and values contained in the directory as arrays
    my $ordered_list         = $args{-order};                                            ## order of the branches
    my $print_tree           = $args{ -print };                                          ## print out the HTML tree <OPTIONAL>
    my $toggle_open          = defined $args{-toggle_open} ? $args{-toggle_open} : 1;    ## toggle the open/closed image icon
    my $unique_key           = $args{-unique_key};                                       ## unique identifier for the branch
    my $onClick              = $args{-onClick};                                          ## Additional javascript code
    my $title                = $args{-title};
    my $leaf_list            = $args{-leaf_list};                                        ## Put leaf elements into an unordered list
    my $disable_if_collapsed = $args{-disable_if_collapsed} || 0;                        ### Flag for disabling the form elements when collapsed
    my $event                = $args{-event} || 'onClick';                               ## onMouseOver should only be used for help type layers (closes on MouseOut)
    my $dir                  = $args{-dir};
    my $default_open         = $args{-default_open};                                     ## Branch name of the branch that will remain open
    my $block_name           = $args{-block_name};                                       ## Optional name given for a block (folder or expand)
    my $style                = $args{-style} || 'folder';
    my $colour               = $args{-colour} || '#66a';   ## icon colour

    my $open_title   = $args{-open_title};
    my $closed_title = $args{-closed_title};

    my $tooltip    = $args{-tooltip};
    my $open_tip   = $tooltip || $args{-open_tip};
    my $closed_tip = $tooltip || $args{-closed_tip};

    my ($open_icon, $closed_icon);
    if ( $style =~ /folder/i ) {
        $closed_icon = 'folder';
        $open_icon   = 'folder-open';
    }
    elsif ( $style =~ /expand/i ) {
        $closed_icon = 'plus-square';
        $open_icon   = 'minus-square';
    }
    
    my %html_tree = %{$tree} if ($tree);
    my @keys = sort keys %html_tree;
    ## default arrangement of multiple trees = Vertical unless there are 2 (in which case default = Hor)
    if ( int(@keys) == 2 ) {
        $dir ||= 'Horizontal';
    }
    else {
        $dir ||= 'Vertical';
    }

    my @default_open;
    @default_open = Cast_List( -list => $default_open, -to => 'Array' );
    my $index = 0;

    my $output    = '<div></div>';
    my $recursive = $args{-recursive};

    my @branches;
    foreach my $branch_name ( sort keys %html_tree ) {
        my $branch_output = '';

        my $type = ref( $html_tree{$branch_name} );
        my @branch_values;
        if ( $type eq 'ARRAY' ) {
            @branch_values = @{ $html_tree{$branch_name} };
        }
        else {
            @branch_values = ( $html_tree{$branch_name} );    ## cast scalar into standard array form.
        }
        my $randnum = rand();

        # get the eight least significant figures
        $randnum = substr( $randnum, -8 );
        my $id = $randnum . $index . $unique_key;

        my $open_text   = $branch_name;
        my $closed_text = $branch_name;
        
        my $closed_trigger = "unHideElement('$id'); HideElement('closed-$id');  unHideElement('open-$id'); return false; ";
        my $open_trigger = "HideElement('$id');  unHideElement('closed-$id'); HideElement('open-$id'); return false;";

        if ( $open_title || $closed_title ) {
            $closed_trigger .= " unHideElement('Open_Title.$id'); HideElement('Closed_Title.$id');";
            $open_trigger .= " unHideElement('Closed_Title.$id'); HideElement('Open_Title.$id');";
            $open_text   = "<span id='Open_Title.$id'>$open_title</span><span id='Closed_Title.$id' style='display:none'>$closed_title</span>";
            $closed_text = "<span id='Open_Title.$id' style='display:none'>$open_title</span><span id='Closed_Title.$id' >$closed_title</span>";
        }
        
        my $closed_image = $BS->icon($closed_icon, -colour=>$colour, -id=>"closed-$id", -style=>'display:block', -onclick=> $closed_trigger);
        my $open_image = $BS->icon($open_icon, -colour=>$colour, -id=>"open-$id", -style=>'display:none', -onclick=> $open_trigger);

        my $trigger_event = "$event=\"$onClick\"";
        if ( $event eq 'onMouseOver' ) { $trigger_event .= "onMouseOut=\"$onClick\""; }    ### close on Mouse out if applicable

        $branch_output .= "<SPAN class='trigger' $trigger_event>\n";

        if ($open_tip)   { $open_title   = Show_Tool_Tip( $open_text,   $open_tip ) }
        if ($closed_tip) { $closed_title = Show_Tool_Tip( $closed_text, $closed_tip ) }


        if (grep /\Q$branch_name/i, @default_open ) {
            $branch_output .= $closed_image . $open_image . "$open_text</span><BR>\n<span class='branch o' id='$id' style='display:block'>\n";
        }
        else {
            $branch_output .=  $closed_image . $open_image . "$closed_text</span>\n<BR><span class='branch c' id='$id' style='display:none'>\n";
        }

        if ($title) { $branch_output .= "<H1>$title</H1>\n" }
        if ( $leaf_list && ( int(@branch_values) > 0 ) ) {
            $branch_output .= "<ul>";
        }
        foreach my $value (@branch_values) {
            ### Check if the value is another tree
            if ( ref($value) eq 'HASH' ) {

                my %hash = %{$value};
                $branch_output .= create_tree( -tree => \%hash, -print_tree => $print_tree, -toggle_open => $toggle_open, -style=>$style );
            }
            else {
                if ($leaf_list) {
                    $branch_output .= "<li>$value</li>\n";
                }
                else {
                    $branch_output .= $value . "<BR>\n";
                }
            }

        }
        if ( $leaf_list && ( int(@branch_values) > 0 ) ) {
            $branch_output .= "</ul>\n";
        }
        $branch_output .= "</span> <!-- end of collapsible block span -->\n";
        $index++;

        ## Disable all the elements by default
        if ($disable_if_collapsed) {
            $branch_output .= "\n<script>ToggleFormElements('$id',2,'$block_name')</script>\n";
        }
        push( @branches, $branch_output );
    }

    if ( $dir =~ /hor/i ) {
        $output .= "\n<Table>\n\t<TR>\n";
        foreach my $branch (@branches) {
            $output .= "\t<TD valign=top>\n\t";
            $output .= $branch;
            $output .= "\n\t</TD>";
        }
        $output .= "\t</TR></Table>\n";
    }
    else {
        foreach my $branch (@branches) {
            $output .= $branch . "<BR>\n";
        }
    }

    if ($print_tree) {
        print $output;
        return 1;
    }
    else {
        return $output;
    }
}

#
# Generate date field 
#
# Usage:
#
# print display_date_field(-element_name='Date', -default=$today);
#
# print display_date_field(-element_name=>'searchDate', -range=>1);  ## generates 2 date fields for range input (defaults prompt label to 'From' , 'Until')
#
# print display_date_field(-element_name=>'searchDate', -range=>1, -inline=>0, -range_labels=>['Start:', 'End:']);   ## specify range labels; include on separate lines (defaults to inline) 
#
#
# Return: input field
##########################
sub display_date_field {
##########################
    my %args         = filter_input( \@_, -args => 'field_name,default,default_to,direction', -mandatory => 'field_name' );
    my $field_name   = $args{-field_name};
    my $element_name = $args{-element_name};
    my $element_id   = $args{-element_id};
    my $default      = $args{-default};                                                                                       ## OPTIONAL
    my $default_to   = $args{-default_to};                                                                                    ## OPTIONAL
    my $range        = $args{-range};
    my $range_labels = $args{-range_labels} || ['From', 'Until'];                                                             ## boolean (indicating both since and until dates)
    my $inline       = defined $args{-inline} ? $args{-inline} : 1;                                                           ## put date fields in single line when range option selected

    my $prompt_label   = $args{-prompt_label};
    my $quick_link     = $args{-quick_link};                                                                                  ## Show radio buttons to set date ranges
    my $description    = $args{-description};                                                                                 ## tooltip description to show up over date field
    my $to_description = $args{-to_description};                                                                              ## tooltip to show up over until field
    my $direction      = $args{-direction} || '-';
    my $calendar       = $args{-calendar} || 1;                                                                               ## boolean (enable graphic calendar)
    my $form_name      = $args{-form_name};                                                                                   ## required for calendar option...
    my $type           = $args{-type} || 'date';                                                                              ## alternatively.. time
    my $cal_format     = $args{-calendar_format} || 'showCalendar';   ## (showCalendar or jquery) ## local variable to toggle between showCalendar js functionality and jquery datetimepicker ##
    my $linefeed       = $args{-linefeed};    ## alternative spec to inline... this forces linefeed if range is being used... 
    my $action         = $args{-action};  ## type of action being performed with this form element (eg search / update / insert )
    
    if ($linefeed) { $inline = 0 }

    if (!$element_name) {
        $element_name = $field_name;
        $element_name =~s/\./\-/g;        
    } 
    $element_id ||= $element_name;

    # BS->calendar seems to generate some sort of conflict within the form navigator, so leave current usage until this is resolved ##
    #
    # return $BS->calendar(-name => $element_name, -id => "$element_name-$element_id", -type=>$type);
    my $format;

    if ( $element_name =~ s/\./\-/g || $element_id =~ s/\./\-/g ) { print "Deprecated Usage: Date element id contains . character (replace with - if possible)<BR>name = $args{-element_name} / id = $args{-element_id}"; Call_Stack(); }

    my ($format,$showTime, $jq_format, $jq_showTime);                                                                                                             

    ## call paramters to showCalendar are a bit weird - type should be '12' (for 12-hour clock), '24', or 0 (for date only) ##

    if ( $type =~ /time/ ) {
        ## Tell JS function to display 24h time option
        $showTime = "'12'";
        $format   = '%Y-%m-%d %H:%M'; ## use 'Y-m-d H:i'  if using jquery datetimepicker ... 
        $jq_showTime = 'true';
        $jq_format  = 'Y-m-d H:i';
    }
    else {
        $showTime = 0;
        ## Tell JS function to not display time at all
        $format = '%Y-%m-%d';
        $jq_showTime = 'false';
        $jq_format  = 'Y-m-d';
    }

    if ($cal_format =~/jquery/) {
        ## Enable different calendar types ##
        require LampLite::JQuery;
        my $JQ = new LampLite::JQuery();
         
        return $q->textfield(-id=>$element_id, -name=>$element_name, -size=>'20', -value=>"$default", -placeholder=>"YYYY::MM::DD", -onclick=> $JQ->calendar( -id => $element_id, -show_time => $jq_showTime, -format => $jq_format ) );
        # return $JQ->calendar( -id => $element_id, -show_time => $jq_showTime, -format => $jq_format );
    }

    $form_name = "document.$form_name" unless ( $form_name =~ /^document\./ );
    my %labels = ();

    my $display = $prompt_label;

    ## Create the quick links
    if ( $default eq 'today' ) { $default = today() }

    ## make default 1 day if not set (as this is mostly used for 24 hrs) ##
    if ($action =~/(insert|append)/i) {
        if ( !defined $default && !defined $default_to ) {
            $default = substr( date_time('-1d'), 0, 10 );
            $default_to = today();
        }
    }

    my $no_button = 0;

    # do not preset any radio button if this is true
    if ( ( $default_to && $default_to ne today() ) || ( !exists $labels{$default} ) ) {
        $no_button = 1;
    }

    ## Display date range
    my $target_field;
    if ($range) {
        if ( $direction eq '-' ) {
            $target_field = "from_$element_name";
        }
        else {
            $target_field = "to_$element_name";
        }

        my $target_to_field = "to_$element_name";
        my $today_value     = today();

        my $auto_pick = &auto_pick_dates( -to => "to_${element_name}_id", -from => "from_${element_name}_id", -shortcuts => $quick_link );

        my $from = display_date_field( -element_id => "from_${element_name}_id", -field_name => "from_$element_name", -default => $default,    -type => $type, -prompt_label => $range_labels->[0]);
        my $to   = display_date_field( -element_id => "to_${element_name}_id",   -field_name => "to_$element_name",   -default => $default_to, -type => $type, -prompt_label => $range_labels->[1]);

        if ($inline) {
            $display .= $BS->row([$from, $to], -span=>[6,6]);
        }
        else {
            $display .= $BS->row([$from]);
            $display .= $BS->row([$to]);
        }
        
        if ($auto_pick) {
            $display .= $BS->row( [$auto_pick]);
         }

    }
    else {
        my $randnum = rand();

        # get the eight least significant figures
        $randnum = substr( $randnum, -8 );

        my $onclick = qq(showCalendar('$element_id','$format', $showTime); return false;\n);
        my ($icon, $append_onclick);
        if ($calendar) {
            ## show calendar on icon rather than textfield ## 
            $icon = 'calendar ';
            $append_onclick = $onclick;
            $onclick = $onclick;
        }

        $display = $BS->text_group_element(
            -append_icon  => $icon,
            -prepend_text => $prompt_label,
            -default      => $default,
            -id           => $element_id,
            -name         => $element_name,
            -append_onclick => $append_onclick,
            -onclick      => $onclick,   
            -text_style   => 'min-width:100px; z-index:0',
        );

        if ($quick_link) { $display .= &auto_pick_dates( -id => $element_id, -shortcuts => $quick_link ) }
    }

    return $display;
}

# Wrapper to generate javascript to autoset date fields by providing a map of shortcut values
#
#  my $shortcuts = {
#    '1d' => [$yesterday, $  ],
#    '1w' => [$week, $today],
#    '1m' => [$month, $today],
#    '1y' => [$year, $today],
#    'any' => ['',''],
#   };
#
# Return: javascript to include in calendar block above ..
######################
sub auto_pick_dates {
######################
    my %args          = @_;
    my $from_id       = $args{-from} || $args{-id};
    my $to_id         = $args{-to};
    my $name          = $args{-name} || "Setdate.$from_id";
    my $use_shortcuts = $args{-shortcuts};

    my $block;

    if ($use_shortcuts) {

        my ($today)     = split ' ', date_time();
        my ($yesterday) = split ' ', date_time('-1d');
        my ($week)      = split ' ', date_time('-7d');
        my ($month)     = split ' ', date_time('-30d');
        my ($year)      = split ' ', date_time('-365d');

        my $shortcuts = [ { 'today' => [ $today, $today ] }, { '1d' => [ $yesterday, $today ] }, { '1w' => [ $week, $today ] }, { '1m' => [ $month, $today ] }, { '1y' => [ $year, $today ] }, { 'any' => [ '', '' ] }, ];

        foreach my $sc (@$shortcuts) {
            my ($key) = keys %$sc;
            my $range = $sc->{$key};

            my ( $from, $to, $onclick );
            if ( ref $range eq 'ARRAY' ) {
                ( $from, $to ) = @$range;
            }
            else {
                $to = $range;
            }

            if ( defined $to   && $to_id )   { $onclick .= "document.getElementById('$to_id').value='$to'; " }
            if ( defined $from && $from_id ) { $onclick .= "document.getElementById('$from_id').value='$from'; " }
            if ($onclick) { $block .= qq(<input type="radio" class="inline" name="$name" onclick="$onclick">$key</input>\n) }    ## class: radio-inline should be defined
        }
    }

    return $block;
}

#
# Wrapper to generate page heading
# (assumes css class 'page-heading')
#
#
# Usage:
#   print page_heading("Heading")
#
#   print page_heading("Heading", -bgcolor=>0);  ## suppresses standard background colouring
#
# Return: wrap text in class
#####################
sub page_heading {
#####################
    my %args    = filter_input( \@_, -args => 'text' );
    my $text    = $args{-text};

    return std_heading( $text, -class => 'page-heading', %args );
}

#
# Wrapper to generate section heading
# (assumes css class 'section-heading')
#
# Usage:
#   print section_heading("Heading")
#
#   print section_heading("Heading", -bgcolor=>0);  ## suppresses standard background colouring
#
# Return: wrap text in class
#####################
sub section_heading {
#####################
    my %args    = filter_input( \@_, -args => 'text' );
    my $text    = $args{-text};

    return std_heading( $text, -class => 'section-heading', %args );
}

#
# Wrapper to generate subsection heading
# (assumes css class 'subsection-heading')
#
# Usage:
#   print subsection_heading("Heading")
#
#   print subsection_heading("Heading", -bgcolor=>0);  ## suppresses standard background colouring
#
# Return: wrap text in class
#####################
sub subsection_heading {
#####################
    my %args    = filter_input( \@_, -args => 'text' );
    my $text    = $args{-text};

    $args{-class}   = 'subsection-heading';
    return std_heading(%args);
}

#
# Wrapper to generate page heading
# (assumes css class 'page-heading')
#
# Return: wrap text in class
#####################
sub std_heading {
#####################
    my %args     = filter_input( \@_, -args => 'text' );
    my $text     = $args{-text};
    my $class    = $args{-class};
    my $align    = $args{-align};
    my $bgcolor  = $args{-bgcolor};
    my $embedded = $args{-embedded};
    my $style    = $args{-style};
    my $inline   = $args{-inline} || $embedded;            ## default puts heading on distinct line (using bootstrap span class) unless embedded

    my $apply_class_to = 'tr td';                             ## this just enables easier debugging for the time being... set to 'td' or 'text' ...

    my $cell_spec = "width='100%'";
    if ($align) { $cell_spec .= " style='text-align:$align'" }

    my $table_spec = "padding='4px' style='background-color:$bgcolor; $style;'";    ## default table specifications

    if   ($inline) { $table_spec .= " class='inline'" }
    else           { $table_spec .= " width='100%'" }                               ## "$class .= ' span12' }

    my $content;
    my ( $tdclass, $trclass );

    if    ( $apply_class_to =~ /td/i ) { $content = $text; $tdclass = $class; }
    if ( $apply_class_to =~ /tr/i ) { $content = $text; $trclass = $class; }

    my $block;
    if ($embedded) {
        $content = qq(<span class="$class abc">$text</span>\n);
        $block   = $content;
    }
    else {
        $block = "\n<Table $table_spec><TR class='$trclass'><TD $cell_spec class='$tdclass'>\n$content\n</TD></TR></Table>\n";
    }

    if   ($inline) { return $block }
    else           { return "\n<P>$block</P>\n" }

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
