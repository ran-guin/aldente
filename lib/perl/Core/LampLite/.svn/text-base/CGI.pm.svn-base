
package LampLite::CGI;

use base CGI;

use RGTools::RGIO qw(filter_input truncate_string);

### Simple wrapper for customizing CGI elements ###
#
# These methods override standard CGI elements by customizing some of the attributes 
#
# It allows for certain standard parameters to be added which adjust the class of the form elements automatically
#  (some of the default classes used within this file may depend upon inclusion of specific css files or bootstrap )
#
# Some of the customizations may potentially be changed to load class options from a customizable configuration file #

#############
sub submit {
#############
	my $self = shift;
	my %args = @_;

	my $mobile   = $args{-mobile};  ## argument to enable mobile specific adjustments to cgi parameters
	my $size   = $args{-size};      ## argument to enable mobile specific adjustments to cgi parameters
	
    ## default class to btn / btn-lg ##
    if ($mobile || $size =~/^l/i) { $args{-class} .= ' btn-lg '}
    else { $args{-class} .= ' btn ' }
    
    if ($args{-style} !~/margin/) { $args{-style} .= " margin:5px;" }  ## set margin for buttons by default ##

    my $element = $self->SUPER::submit(%args);  
    return $self->element($element, %args);
}

############
sub reset {
############
	my $self = shift;
	my %args = @_;

    ## default class to btn / btn-lg ##
    if ($mobile || $size =~/^l/i) { $args{-class} .= ' btn-lg '}
    else { $args{-class} .= ' btn ' }
    
    if ($args{-style} !~/margin/) { $args{-style} .= " margin:5px;" }  ## set margin for buttons by default ##

    my $element = $self->SUPER::reset(%args);
    return $self->element($element, %args);
}

#################
sub textfield {
#################
    my $self = shift;
    my %args = @_;
    
	my $mobile   = $args{-mobile};  ## argument to enable mobile specific adjustments to cgi parameters
	my $size   = $args{-size};  ## argument to enable mobile specific adjustments to cgi parameters

    ## default class to btn / btn-lg ##
    if ( ($mobile || $size =~/^l/) && ! defined $args{-class}) { $args{-class} .= ' input-lg'}
    
	my $element = $self->SUPER::textfield(%args);    
    return $self->element($element, %args);
    
}

#
# Generates textfield or textarea (depending upon whether size or rows & cols are passed in)
# This element will expand when focused on and reduce to normal size onblur
#
# Input options:
#  -tooltip
#  -max_rows
#  -max_cols
#  -max_size
#
# Normal arguments are simply passed on to respective textarea or textfield call
#
# Return: field element (either textarea or textfield with appropriate onblur or onclick parameters set)
###########################
sub expandable_textarea {
###########################
    my $self = shift;    
    my %args = @_;

    my $max_size = $args{-max_size} || $args{-max_cols};
    my $tooltip  = $args{-tooltip};
    my $split    = $args{-split_commas} || 0;                   ## split elements on commas -> linefeed when expanding (defaults to also unsplit on reduce)

    my $rows = $args{-rows};
    my $cols = $args{-cols};
    my $size = $args{-size};

    my $max_cols = $args{-max_cols} || $cols;
    my $max_rows = $args{-max_rows} || $rows;

    my $id   = $args{-id} || substr( rand(), -8);

    my $static = $args{-static} || 0;                      ## turn off dynamic expand functionality of textfield
    
    if ($static) {
        $element = $self->textfield(%args);
    }
    elsif ( $args{-size} ) {
        my $onblur  = "reduce_textfield('$id',$size, null, $split); " . $args{-onblur};
        my $onfocus = "expand_textfield('$id', $max_size, null, $split); " . $args{-onfocus};

        $args{-onfocus} = $onfocus;
        $args{-onblur}  = $onblur;
        $element = $self->textarea( %args);

    }
    elsif ( $args{-rows} && $args{-cols} ) {
        
        if ($max_rows > $rows || $max_cols > $cols) {
            my $onblur  = "reduce_textfield('$id',$rows,$cols, $split); " . $args{-onblur};
            my $onfocus = "expand_textfield('$id', $max_rows, $max_cols, $split); " . $args{-onfocus};

            $args{-onfocus} = $onfocus;
            $args{-onblur}  = $onblur;
        }
        $element = $self->textarea( %args );
    }
    else {
        $element = $self->textarea(%args);        
    }
    
    return $element;
}

#################
sub radio_group {
#################
    my $self = shift;
    my %args = @_;
    
	my $mobile   = $args{-mobile};  ## argument to enable mobile specific adjustments to cgi parameters
	my $size   = $args{-size};  ## argument to enable mobile specific adjustments to cgi parameters

    ## default class to btn / btn-lg ##
    if ( ($mobile || $size =~/^l/) && ! defined $args{-class}) { $args{-class} .= ' input-lg'}
    
	my $element = $self->SUPER::radio_group(%args);    
    return $self->element($element, %args);
    
}

##################
sub popup_menu {
##################
    my $self = shift;
    my %args = @_;
    
    my $mobile = $args{-mobile};  ## added argument to enable mobile specific adjustments to cgi parameters
    
    my $element = $self->SUPER::popup_menu(%args);
    return $self->element($element, %args);
    
#    return $BS->dropdown(%args);
}

#################
sub password_field {
#################
    my $self = shift;
    my %args = @_;
    
	my $mobile   = $args{-mobile};  ## argument to enable mobile specific adjustments to cgi parameters
	my $size   = $args{-size};  ## argument to enable mobile specific adjustments to cgi parameters

    ## default class to btn / btn-lg ##
    if ($mobile || $size =~/^l/) { $args{-class} .= ' input-lg'}
        
    my $element = $self->SUPER::password_field(%args);    
    return $self->element($element , %args);
    
}

######################
sub get_media_file {
######################
	my $self = shift;
    my $type = shift;  ## image, video, audio ... 
 	my %args = @_;
   
    my $name = $args{-name};
    my $id   = $args{-id};
    my $style = $args{-style};
    my $class =  $args{-class} || 'input-lg';
    
    $args{-accept} = "$type/*";
    $args{-capture} = 'capture';
    
    my $submit; ##  = $self->filefield(%args);
    
 $submit .= qq(<input type="file" class="$class" style="$style" name="$name" id="$id" accept="$type/*" default="$type File" placeholder="$type File" capture >\n);

    return $submit;
}

#
# General wrapper to return elements of any standard CGI kind.
#  
# It may adapt the result in standard ways (such as inclusion of tooltips) based on the input arguments 
###############
sub element {
############### 
    my $self = shift;
    my $element = shift;
    my %args = @_;

    my $mobile = $args{-mobile};
    
    my $tooltip = $args{-tooltip};
    if ($mobile || $size =~/^l/) { $args{-class} .= ' input-lg'}

    if ($tooltip) { 
        require LampLite::Bootstrap;
        my $BS = new Bootstrap();
        return $BS->tooltip($element, $tooltip);
    }
    
    return $element;
}

############
sub button {
############
    my $self = shift;
    my %args = @_;
    my $class = $args{-class};  ## default to bootstrap standard 
    
    $args{-class} ||= 'Std btn';
    my $element = $self->SUPER::button(%args);    
    return $self->element($element , %args);
    
}

### Move from RGTools::RGIO ###

#
# View input parameters to cgi script
#
#########################
sub show_parameters {
#########################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'li,format,truncate,profiler');
    my $format   = $args{-format} || 'html';   ## text or html
    my $truncate = $args{-truncate} || 100;
    my $profiler = $args{-profiler};

    require URI::Escape;
    
    my $br    = '<BR>';
    my $input = "\nInput Parameters:" . $br;
    $input .= "\n<span class=small>" if ( $format =~ /html/ );
    
    my $shell_parameters;
    foreach my $name ( $self->param() ) {
        my $value   = join '<LI>', $self->param($name);
        my $display = '';
        my $found   = 0;
        if ( $format =~ /text/ ) {
            $display          .= "$name = $value\n";
            $shell_parameters .= "&$name=" . URI::Escape::uri_escape($value);
            $found++ if defined $value;
        }
        else {
            $value = RGTools::RGIO::truncate_string( $value, $truncate ) if ($value);
            $display          .= "$name = <UL><LI>$value</UL><BR>\n";
            $shell_parameters .= "&$name=" . URI::Escape::uri_escape($value);
            $found++ if defined $value;
        }
        $input .= $display if $found;    ## only show if value actually passed...
    }

    $input .= "</span>\n" if ( $format =~ /html/ );

    return $input;
}

return 1;