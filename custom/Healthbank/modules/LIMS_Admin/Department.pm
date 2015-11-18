package Healthbank::LIMS_Admin::Department;

use base SDB::Site_Admin;

use strict;
use warnings;

use RGTools::RGIO;
use LampLite::Bootstrap;
use LampLite::HTML;

use LampLite::DB_Access_Views;

my $q = new LampLite::CGI;
my $BS = new Bootstrap;

## Specify the icons that you want to appear in the top bar
my @icons_list = qw(Views System_Monitor Subscription Session Import Template  Barcodes Queries DBField Employee JIRA);

########################################
sub home_page {
#################
    my $self = shift;
    my %args = filter_input( \@_ );

    require Healthbank::LIMS_Admin::Department_Views;
    return $self->View->home_page(%args);

}

########################################
# Function to decode frozen data structures
########################################
sub decode_base32 {
####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'string');
    my $str = $args{-string};
    my $thaw = $args{-thaw};

    if ($thaw) {
        require YAML;
        $str = YAML::thaw($str);
    }
    
    my $decoded = MIME::Base32::decode($str);


    if (ref $decoded eq 'HASH' && $decoded->{dbc} ) {
        $decoded->{dbc} = '';
    }

    return $decoded;
}
########################################
# Function to decode frozen data structures
########################################
sub encode_base32 {
####################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'object');
    my $object = $args{-object};
    my $freeze = $args{-freeze};

    if (ref $object eq 'HASH' && $object->{dbc}) {
        $object->{dbc} = $object->{dbc}->{connected};
    }
    
    if ($freeze) {
        require YAML;
        my $frozen = YAML::freeze($object);
        return MIME::Base32::encode($frozen);
    }
    else {
        return MIME::Base32::encode($object);
    }
}

########################################
#
# Accessor function for the icons list
####################
sub get_icons {
####################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};
    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{'LIMS Admin'} } ) ) {
        push @icons_list, "Submission";
    }

    return \@icons_list;
}

# Return: default icon_class (may override in specific Department.pm module )
######################
sub get_icon_class {
#####################
    my $self = shift;
    my $navbar = 1;                                                          ## flag to turn on / off dropdown navigation menu

    my $class = 'iconmenu';
    if ($navbar) { $class = 'dropnav' }

    return $class;
}

#######################
sub get_custom_icons {
#######################
    my %images;

    return \%images;
}

return 1;
