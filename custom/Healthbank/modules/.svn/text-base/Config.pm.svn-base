###################################################################################################################################
# Healthbank::Config.pm
#
# Localized configuration module 
#
###################################################################################################################################
package Healthbank::Config;

use base alDente::Config;

use strict;

use RGTools::RGIO;

#################
sub css_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my @css_files = $self->SUPER::css_files(%args);

    my @local_css = qw(
        Healthbank
     ); 
     
    push @css_files, @local_css;  
    
    return @css_files;
    
}

#################
sub js_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my @js_files = $self->SUPER::js_files(%args);
    
    my @local_js = qw(  
    );
    
    push @js_files, @local_js;
    
    return @js_files;
}

1;

