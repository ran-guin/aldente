package Site_Admin::Department;

use base Main::Department;

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
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my $dbc = $self->{dbc};
    return $self->View->home_page(-dbc=>$dbc);
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
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc = $args{-dbc};

    ###Permissions###
    my %Access = %{ $dbc->get_local('Access') };
    if ( grep( /Admin/, @{ $Access{'Site Admin'} } ) ) {
        push @icons_list, "Submission";
    }

    return \@icons_list;
}

#######################
sub get_custom_icons {
#######################
    my %images;

    return \%images;
}

return 1;
