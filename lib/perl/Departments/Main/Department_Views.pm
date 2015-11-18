package Main::Department_Views;

use base SDB::DB_Object_Views;

use strict;
use warnings;

use RGTools::RGIO;

use LampLite::CGI;
my $q = new LampLite::CGI;

## Specify the icons that you want to appear in the top bar

########################################
#
#  Actual home page for this department
#
##############################
sub home_page {
##############################
    my $self = shift;
    my %args = filter_input(\@_,-args=>'dbc,open_layer',-mandatory=>'dbc');
    my $dbc = $args{-dbc};

    my $open_layer= $args{-open_layer};
    return 'home';

    ### Permissions ###
    my %Access = %{$dbc->get_local('Access')};

    my $datetime = &date_time;
    my $user = $dbc->get_local('user_id');

    # This user does not have any permissions on Department
    if (!($Access{'Main'} || $Access{'LIMS Admin'})) {
        return;
    }

    #   Main::Department::set_links($dbc);

    my ($search_ref,$creates_ref) = Main::Department::get_searches_and_creates(-access=>\%Access);
    my @searches = @$search_ref;
    my @creates = @$creates_ref;

    my ($greys_ref,$omits_ref) = Main::Department::get_greys_and_omits();
    my @grey_fields= @$greys_ref;
    my @omit_fields = @$omits_ref;

    my $grey = join '&Grey=',@grey_fields;
    my $omit = join '&Omit=',@omit_fields;

    my $search_create_box = $self->Model::search_create_box($dbc, \@searches,\@creates);

    my $extra_links;

    ## Define admin layer
    my $admin_table = alDente::Admin::Admin_page($dbc,-reduced=>0,-department=>'Main',-form_name=>'Admin_layer');

    ## Define the layers of the Main Department 
    my $layers = {
        "Database" => $search_create_box . $q->lbr . $extra_links 
    };


    my @order;

    return define_Layers(-layers=>$layers, 
        -tab_width=>100,
        -order=>\@order,
        -default=>$open_layer);
    }

return 1;
