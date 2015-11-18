##################################################################################################################################
# <module_name>.pm
#
# <concise_description>
#
###################################################################################################################################
package <module_name>;

use Carp;
use strict;


############
sub new {
############
    my $this = shift;
    my $class = ref $this || $this;
    
    my $self = {};
    
    bless $self, $class;
    return $self;
}

#
# Standard Description of Module Below
#
# Usage:
#     <snip>
#         my $success = $self->example_method(-id=>$id);   
#     </snip>
#
# Return: 1 on success 
##########################
sub example_method {
##########################
    my $self = shift;
    my %args = filter_input(\@_);

    my $id    = $args{-id};      ## description of input arguments...
    my $list  = Cast_List(-list=>$args{-list}, -to=>'array');       ## recast arguments if valid as both scalar or array ref  
    ## optional parameters ##         
    my $debug = $args{-debug};   ## define all input arguments prior to code logic

    ## concise yet useful comments indicating logic being applied ##

    ## organize code logic in intuitive blocks - move large blocks into separate methods to make more readable ##

    ## move reusable sections of code into separate methods ##

    return 1;                    ## typically return 1 on success 
}
    
return 1;

__END__;

##############################
# perldoc_header             #
##############################
=head1 NAME <UPLINK>

<module_name>

=head1 SYNOPSIS <UPLINK>

Usage:

=head1 DESCRIPTION <UPLINK>

<description>

=for html

=head1 KNOWN ISSUES <UPLINK>
    
None.    

=head1 FUTURE IMPROVEMENTS <UPLINK>
    
=head1 AUTHORS <UPLINK>
    
    Ran Guin, Andy Chan and J.R. Santos at the Michael Smith Genome Sciences Centre, Vancouver, BC
    

=head1 CREATED <UPLINK>
    
    <date>

=head1 REVISION <UPLINK>
    
    <version>

=cut
