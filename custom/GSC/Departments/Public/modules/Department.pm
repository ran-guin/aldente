package Public::Department;

use base LampLite::DB_Object;

use RGTools::RGIO;
use LampLite::HTML;

use strict;
use warnings;

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
    my %args = filter_input( \@_, -args => 'dbc,open_layer');
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $open_layer = $args{-open_layer} || 'Summaries';
    my $modules    = $args{-modules};

    ### Permissions ###
    my %Access = %{ $dbc->get_local('Access') };

#    alDente::Department::set_links($dbc);

    my @searches;
    my @creates;

    # Lab permissions for searches
    #  if (grep(/Management/,@{$Access{Management}})) {#
    push( @searches, qw(Contact) );
    push( @creates,  qw(Collaboration Contact) );

    require LampLite::Login_Views;

    my @layers;
    push @layers, {'label' => 'Contact Info', 'content' => LampLite::Login_Views->LIMS_contact_info };
    push @layers, {'label' => 'Applying for an Account' , 'content' =>  application_instructions() };
    push @layers, { 'label' => 'LIMS Info', 'content' => lims_info() };

    my $output = SDB::HTML::define_Layers(
        -layers    => \@layers,
        -tab_width => 100,
        -default  => 'LIMS Info',
        );
    
    return $output;
    
}

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

########################################
sub application_instructions {
########################################
   
   my $page = section_heading("Applying for a LIMS Account");

   $page .= subsection_heading("Internal GSC Account");

   $page .= "Simply Go to the main LIMS Page and click on the 'Apply for Account' link<P>";
    $page .= "Once your application is approved by a GSC Administrator, you will be sent an email verification that your request has been approved";

    $page .= subsection_heading("External Collaborator Account (for logging into the GSC Public Page");

    $page .= "These pages require an LDAP access to get through our firewall.<P>";
    $page .= "This requires a slightly more rigorous approval process, but if applicable, a GSC Administrator should be able to approve your application and set you up with an account relatively quickly.<P>";
    $page .= "Once approved, you will be notified by email, after which you should be able to log in to our public page to make online submissions";

    $page .= '<hr>';

    return $page;
}

########################################
sub lims_info {
########################################

    my $page ;

$page .= "General info about the LIMS...";

    return $page;
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
