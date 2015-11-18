################################################################################
# Web_Form.pm
#
# This module contains a few form related functions
#
###############################################################################
package RGTools::Web_Form;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

This module contains a few form related functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

	use:
	
	Popup_Menu
	Submit_Button

	just like you would the standard CGI functions, but it handles different OS limitations more smoothly
	
	
=head1 DESCRIPTION <UPLINK>

=for html

This module contains a few form related functions

=cut

use CGI qw(:standard);
use strict;

use RGTools::RGIO;

###########################
# (Moved to this module)
# Wrapper for popup_menu that allows easier adaptation based upon OS
#
###########################
sub Popup_Menu {
###########################
    #
    # Returns a popup menu that is capable of auto-expand width (at least in Mozilla...)
    #
    my %args        = @_;
    my $name        = $args{name} || $args{-name};
    my $id          = $args{id};
    my $values      = $args{values} || $args{ -values } || $args{-value} || $args{value};    ###Reference to an array
    my $labels      = $args{labels} || $args{-label};                                        ###Reference to a hash
    my $default     = $args{default} || $args{-default};
    my $force       = $args{force} || $args{-force};
    my $onClick     = $args{onClick} || $args{-onClick};
    my $onChange    = $args{onChange} || $args{-onChange};
    my $disabled    = $args{disabled} || 0;
    my $width       = $args{width} || $args{-width} || 100;
    my $struct_name = $args{-struct_name};
    my $pm;
    my $style;

    if ( $ENV{HTTP_USER_AGENT} =~ /mozilla\/5\.0/i ) {
        if ( $disabled == 0 ) {
            $pm = popup_menu(
                -id          => $id,
                -name        => $name,
                -values      => $values,
                -labels      => $labels,
                -default     => $default,
                -style       => "width:$width",
                -force       => $force,
                -onClick     => $onClick,
                -onChange    => $onChange,
                -struct_name => $struct_name
            );
        }
        else {
            $pm = popup_menu(
                -id          => $id,
                -name        => $name,
                -values      => $values,
                -labels      => $labels,
                -default     => $default,
                -style       => "width:$width",
                -force       => $force,
                -onClick     => $onClick,
                -onChange    => $onChange,
                -disabled    => $disabled,
                -struct_name => $struct_name
            );
        }
    }
    else {
        ### Note that I purposely assign $onClick to onChange event here because the onClick event in IE does not work well.
        $onChange = $onClick;
        if ( $disabled == 0 ) {
            $pm = popup_menu(
                -id          => $id,
                -name        => $name,
                -values      => $values,
                -labels      => $labels,
                -default     => $default,
                -force       => $force,
                -onChange    => $onChange,
                -struct_name => $struct_name
            );
        }
        else {
            $pm = popup_menu(
                -id          => $id,
                -name        => $name,
                -values      => $values,
                -labels      => $labels,
                -default     => $default,
                -force       => $force,
                -onChange    => $onChange,
                -disabled    => $disabled,
                -struct_name => $struct_name
            );
        }
    }

    return $pm;
}

#############
# Simple wrapper to produce a button with a bit more functionality
#
# Return:  HTML text including Submit button.
###########################
sub Submit_Button {
###########################
    #
    # Returns a HTML button that is capable of submitting a form to a new window.
    #
    my %args         = @_;
    my $form         = $args{form};
    my $name         = $args{name};
    my $value        = ( defined $args{value} ) ? $args{value} : 1;
    my $label        = $args{label} || $args{value} || $name;
    my $style        = $args{style};                                  ## (use class) || "background-color:$Settings{STD_BUTTON_COLOUR}";
    my $newwin_form  = $args{newwin_form} || $form;                   # Name of the form where the newwin checkbox is.
    my $newwin       = $args{newwin} || 'NewWin';                     # Name of the checkbox that toggles new window or not.
    my $validate     = $args{validate};                               # Name of the form element to validate value is entered before submitting.
    my $validate_msg = $args{validate_msg};                           # Message to show to user in case validation failed.
    my $onClick      = $args{onClick};
    my $onMouseOver  = $args{onMouseOver};
    my $new_window   = $args{new_window} || 0;                        # Open the form in new window (independent of the new window checkbox)
    my $class        = $args{class} || 'Std';
    my $force        = defined $args{-force} ? $args{-force} : 1;

    my $target = 'alDente';                                           #Name of the target window.

    if ($validate) {
        $validate_msg ||= "Please enter a value for $validate first.";
        $onClick .= "if (!getElementValue(document.$form,\'$validate\')) {alert(\'$validate_msg\'); return false;}";
    }

    if ($new_window) {
        $onClick .= "document.$form.target = '$target';";
        $onClick .= "window.open(\'\',\'$target\',\'height=800,width=1000,scrollbars=yes,resizable=yes,toolbar=yes,location=no,directories=no\');";
    }
    else {
        $onClick .= "if (getElementValue(document.$newwin_form,\'$newwin\')) {document.$form.target = \'$target\';";
        $onClick .= "window.open(\'\',\'$target\',\'height=800,width=1000,scrollbars=yes,resizable=yes,toolbar=yes,location=no,directories=no\');}";
        $onClick .= "else {document.$form.target = \'\';}";
    }

    my $b = submit(
        -name        => $name,
        -value       => $value,
        -label       => $label,
        -style       => $style,
        -class       => $class,
        -onClick     => $onClick,
        -onMouseOver => $onMouseOver,
        -force => $force,
    );

    return $b;
}

#####################
# function for generating an image submit button
#####################
sub Image_Submit {
#####################
    my %args = filter_input( \@_ );
    $args{-class} = 'submit';
    return Button_Image(%args);

}

#
# Same as Image_Submit
#
#####################
sub Submit_Image {
#####################
    my %args = filter_input( \@_ );
    $args{-class} = 'submit';
    return Button_Image(%args);

}

########################
#
# enable clickable image
##################
sub Button_Image {
##################
    my %args = filter_input( \@_ );
    my $alt = $args{-alt};

    unless ( defined $args{-value} ) {
        $args{-value} = 1;
    }
    my $name;
    if ( defined $args{-name} ) {
        $name = $args{-name};
        my $value = $args{-value};
        $args{-onClick} = "this.form.appendChild(getInputNode({'type':'hidden','name':'$name','value':'$value'}));" . $args{-onClick};
    }
    my $class;
    if ( defined $args{-class} ) {
        $class = "class='$args{-class}'";
    }

    unless ( $args{-class} =~ /submit/i ) {
        my $onclick;
        ### append return false at the end
        if ( defined $args{-onClick} ) {
            $onclick = $args{-onClick};
            if ( $onclick !~ /return false;$/i ) {
                $onclick .= "; return false;";
            }
        }
        else {
            $onclick = "return false;";
        }

        $args{-onClick} = $onclick;
    }

    my $attributes = '';
    foreach my $key ( keys %args ) {
        if ( $key =~ /^-(\w+)$/ ) {
            $attributes .= " $1=\"$args{$key}\" ";
        }
    }

    return qq^ <input $class type="image" $attributes alt='$alt'\/> ^;

}

return 1;
