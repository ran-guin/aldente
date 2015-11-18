##################################################################################################################################
# UTM::Site_App.pm
#
# Controller for Tour Guide Site object class
#
###################################################################################################################################
package UTM::Site_App;

use base LampLite::DB_Object_App;
use Carp;

use strict;

use RGTools::RGIO;

use UTM::Site;
use UTM::Site_Views;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('View Site');    ## Collect New Sample Sources');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
            'View Site'  => 'view_Site',
            'View City'  => 'view_City',
            'View Tour'  => 'view_Tour',
            'Edit Records'        => 'edit_records',
            'Add New Site'   => 'add_Site',
            'Save New Site(s)'  => 'save_Site',
            'Add New Tour'   => 'add_Tour',
            'Add Tour'   => 'add_Tour',
            'Save New Tour(s)'  => 'save_Tour',
            'Save Tour'   => 'save_Tour',
        }
    );

    my $dbc = $self->param('dbc');
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

#################
sub view_City {
#################
    my $self = shift;

    my $q = $self->query();
    my $dbc = $self->dbc();
     my $id = $q->param('ID');
    
    return $self->View->view_City(-id=>$id);
    
}

#################
sub view_Site {
#################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();

    my $id = $q->param('ID');

    return $self->View->view_Site(-id=>$id);    
}

#################
sub view_Tour {
#################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();
    
    my $id = $q->param('ID');
    
    return $self->View->view_Tour(-id=>$id);
    
}

###############
sub add_Tour {
#################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();
    
    my $id = $q->param('ID');
    my $parent = $q->param('Site_ID') || $q->param('FK_Site__ID') ;
    my $count = $q->param('N Sites');
    my @fields = $q->param('Fields');
    my $type   = $q->param('Tour_Type');

    return $self->View->add_Tour(-parent=>$parent, -N=>$count, -fields=>\@fields, -type=>$type);

}

###############
sub add_Site {
#################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();
    
    my $id = $q->param('ID');
    my $parent = $q->param('Tour_ID') || $q->param('FK_Tour__ID') ;
    my $count = $q->param('N Sites');
    my @fields = $q->param('Fields');
    my $type   = $q->param('Site_Type');

    return $self->View->add_Site(-parent=>$parent, -N=>$count, -fields=>\@fields, -type=>$type);

}

###############
sub save_Tour {
#################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();

    my $parent = $q->param('Site_ID') || $q->param('FK_Site__ID') ;
    
    my $fields = $dbc->fields('Tour');

    my %Data;
    foreach my $field ( @$fields ) {
        @{$Data{$field}} = $q->param($field);
    }
    
    $dbc->save_Record('Tour', \%Data);

    $dbc->session->homepage("Site=$parent");
    
    return $self->View->view_Site(-id=>$parent);
}

###############
sub save_Site {
#################
    my $self = shift;
    my $q = $self->query();
    my $dbc = $self->dbc();

    my $parent = $q->param('Tour_ID') || $q->param('FK_Tour__ID') ;
    
    my $fields = $dbc->fields('Site');
    
    my %Data;
    foreach my $field ( @$fields ) {
        @{$Data{$field}} = $q->param($field);
    }
    
    $dbc->save_Records('Site', \%Data);
    
    $dbc->session->homepage("Tour=$parent");
    
    return $self->View->view_Tour(-id=>$parent);
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
