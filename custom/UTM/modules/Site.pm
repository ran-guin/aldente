##################################################################################################################################
# UTM::Site.pm
#
# Model for Tour Guide Site object class
#
###################################################################################################################################
package UTM::Site;

use base LampLite::DB_Object;

use Carp;

use strict;

use RGTools::RGIO;

#
# Accessor to load full tour (not just single record)
#
# Usage Options:
#
#   $self->load(-site_id => $site_id);
#   $self->load(-scope=>'Site', -id=>$site_id);
#
#   $self->load(-scope=>'Tour', -id=>$tour_id);
#
#
###########
sub load {
###########
    my $self = shift;
    my %args = filter_input(\@_);
    my $scope = $args{-scope};
    my $id = $args{-id};    
    my $site_id = $args{-site_id} || $self->{site_id};
    my $tour_id = $args{-tour_id} || $self->{tour_id};
    my $dbc = $self->dbc();
    
    if ($scope eq 'Site') { $site_id ||= $id }
    elsif ($scope eq 'Tour') { $tour_id ||= $id }
    
    if ($site_id) {
        $scope = 'Site';
        $tour_id = $dbc->get_db_value(-sql=>"SELECT FK_Tour__ID FROM Site where Site_ID = '$site_id'");
        $id = $site_id;
    }
    elsif ($tour_id) {
        $scope = 'Tour';
        $site_id = $dbc->get_db_value(-sql=>"SELECT FK_Site__ID FROM Tour where Tour_ID = '$tour_id'");
        $id = $tour_id;
    }
    
    $self->{site_id} = $site_id;
    $self->{tour_id} = $tour_id;
    
    my $dbc  = $self->dbc();
    
    if ($self->{loaded}{$scope}{$id}) { return $self}

    ## Load information from parent Site record ##
    my $info = $dbc->hash(-table=>'Site', -condition=>"Site_ID = $site_id");
    foreach my $key (keys %{$info}) {
        $self->field($key, $info->{$key}[0]);
    }
    
    ## Load information from Tour record ##
    my $tour_info = $dbc->hash(-table=>'Tour', -condition=>"Tour_ID = $tour_id");
    foreach my $key (keys %{$tour_info}) {
        $self->field($key, $tour_info->{$key}[0]);
    }

    ## Load information for daughter Site records ##
    my $site_info = $dbc->hash(-table=>'Site', -field=>['*'], -condition=>"FK_Tour__ID = $tour_id", -order=>'Site_ID');

    $self->{sites} = $site_info;
    if ($site_info) {
        my @sites = @{$site_info->{Site_ID}};
        $self->{site_ids} = \@sites;
        $self->{starting_site_id} = $site_info->{Site_ID}[0];
    }
    else {
        $self->{site_ids} = [];
    }
    $self->{loaded}{Tour}{$tour_id} = 1;

    return $self;
}

##################
sub children {
##################
    my $self = shift;
    my %args = filter_input(\@_);
    my $site_id = $args{-site_id};
    my $tour_id = $args{-tour_id};
    my $debug = $args{-debug};
    my $dbc = $self->{dbc};
    
    if ($site_id) {
        my @tours = $dbc->get_db_array(-table=>'Tour', -field=>'Tour_ID', -condition=>"FK_Site__ID = $site_id", -debug=>$debug);
        return @tours;
    }
    elsif ($tour_id) {
        my @sites = $dbc->get_db_array(-table=>'Site', -field=>'Site_ID', -condition=>"FK_Tour__ID = $tour_id", -debug=>$debug);
        return @sites;
        
    }
    else {
        $dbc->error("Cannot check for children without scope inference");
        Call_Stack();
        return;
    }
}

############
sub field {
############
    my $self = shift;
    my $field = shift;
    my $value = shift;

    if (!$field) { return }
    
    if ($value) {
        $self->{field}{$field} = $value;
    }

    return $self->{field}{$field};
}

#############
sub access {
#############
    my $self = shift;
    my %args = filter_input(\@_);
    my $tour_id = $args{-tour_id};
    my $type = shift || 'host';
    my $dbc = $self->{dbc};
    

    my @owners = $self->owners(-tour_id=>$tour_id);
    my $user_id = $dbc->config('user_id');
    
    if ( grep /^$user_id$/, @owners) { return 1 }
    
    return 0;
}

##############
sub owners {
##############
    my $self = shift;
    my %args = filter_input(\@_);
    my $tour_id = $args{-tour_id};
    my $dbc = $self->{dbc};
    
    my @owners = $dbc->get_db_array(-table=>'User', -field=>'User_ID', -condition=>"User_Access like 'Admin'");  ## general site Admins
    
    push @owners, $dbc->get_db_value(-sql=>"SELECT FKOwner_User__ID FROM Tour where Tour_ID = $tour_id");                   ## add current owner

    while ( my $parent_site = $dbc->get_db_value(-sql=>"SELECT FK_Site__ID FROM Tour where Tour_ID = $tour_id") ) {
        my $parent_tour = $dbc->get_db_value(-sql=>"SELECT FK_Tour__ID FROM Site where Site_ID = $parent_site");
        if ($parent_tour) {
            push @owners, $dbc->get_db_value(-sql=>"SELECT FKOwner_User__ID FROM Tour where Tour_ID = $parent_tour");
        }
        $tour_id = $parent_tour;
    }
    
    return @owners;
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
    
    Ran Guin

=head1 CREATED <UPLINK>
    
    <date>

=head1 REVISION <UPLINK>
    
    <version>

=cut
