package Core::Public::Department;

use base Core::Department;

use strict;
use warnings;

use RGTools::RGIO;
use SDB::HTML;

use LampLite::Bootstrap;
use SDB::FAQ;

my $BS = new Bootstrap;

my @icons_list = qw();

## Specify the icons that you want to appear in the top bar
########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
   my $self = shift;

   return $self->View->home_page();
}

###############
sub faqs {
###############
    my $self = shift;
    my $dbc = $self->dbc();
    
#    my $info = section_heading('FAQs');
    
    my $FAQ = new SDB::FAQ(-dbc=>$dbc);
    return $FAQ->View->show_FAQs();
}

#################
sub contact_us {
#################
    my $self = shift;
    
    my $info;
    
    $info .=<<INFO;

Email is the easiest way to contact us.

Feel free to direct any questions, comments or concerns to: info\@sociolite.com

INFO
    
    return $info;
}

#########################################

########################################
#
# Accessor function for the icons list
#
####################
sub get_icons {
####################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $access = $dbc->get_local('Access');
    my %Access = %{$access} if $access;
    if ( $Access{Public} && grep( /Admin/, @{ $Access{Public} } ) ) {
        push @icons_list, "Employee";
    }

    return \@icons_list;
}
#
#
####################
sub get_custom_icons {
####################
    my %images;
    return \%images;

}

# Return: default icon_class (may override in specific Department.pm module )
######################
sub get_icon_class {
#####################
    my $navbar = 1;                                                          ## flag to turn on / off dropdown navigation menu

    my $class = 'iconmenu';
    if ($navbar) { $class = 'dropnav' }

    return $class;
}

return 1;
