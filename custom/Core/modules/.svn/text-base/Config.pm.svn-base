###################################################################################################################################
# Core::Config.pm
#
# Localized configuration module 
#
###################################################################################################################################
package Core::Config;

use base SDB::Config;

use strict;

use RGTools::RGIO;

################
sub initialize {
################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $debug = $args{-debug};                     ## show config settings (use debug > 1 to show hash details)
    
    my $init_config = $self->SUPER::initialize(%args);

    my $path = $self->{path};
    my $brand_image = "logo.png";
    $self->{config}{icon} = $brand_image;

    return $init_config;
}


#################
sub css_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my @css_files = $self->SUPER::css_files(%args);

    my @local_css = qw(
        Core
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

