package GSC::Config;

use base alDente::Config;

################################################################################
#
# Author           : Ran Guin
#
# Purpose          : Configuration Variable Accessor Module
#
#
################################################################################

use RGTools::RGIO qw(filter_input);

##############################
# perldoc_header             #
##############################

#################
sub css_files {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my @css_files = $self->SUPER::css_files(%args);

    my @local_css = qw(
        GSC
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

return 1;
