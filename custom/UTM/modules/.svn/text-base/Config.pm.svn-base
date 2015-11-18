package UTM::Config;

use base LampLite::Config;

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

################
sub initialize {
################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $debug = 0;                     ## show config settings (use debug > 1 to show hash details)

    my $init_config = $self->SUPER::initialize(%args);

    my @url_params     = @{$self->{url_params}};
    my @session_params     = @{$self->{session_params}};

    push @session_params, qw(Access);                                                                                                                   ## parameters automatically passed excplicitly within URL

    $self->{url_params}     = \@url_params;
    $self->{session_params} = \@session_params;

    return 1;
}    

return 1;
