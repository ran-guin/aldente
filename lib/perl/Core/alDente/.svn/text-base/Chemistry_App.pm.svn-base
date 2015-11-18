#############################
# alDente::Chemistry_App.pm #
#############################
#
# This module is used to monitor Goals for Chemistry objects.
#
package alDente::Chemistry_App;
use base alDente::CGI_App;

use strict;
##############################
# standard_modules_ref       #
##############################

############################
## Local modules required ##
############################

use RGTools::RGIO;
use RGTools::RGmath;

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use alDente::Chemistry;

##############################
# global_vars                #
##############################
use vars qw(%Configs );    #

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'        => 'home_page',
            'View Chemistry' => 'show_chemistry',

            #'Check Chemistry Calculator' => 'show_chemistry',
            'Change Status'          => 'change_chemistry_status',
            'Accept TechD Chemistry' => 'accept_chemistry',
        }
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();
    my $id  = $q->param("Chemistry_ID");

    $self->param( 'Chemistry_id' => $id );
    $self->param( 'dbc'          => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}

################
sub home_page {
################
    return 'Chemistry Home Under Construction';
}

################
sub change_chemistry_status {
################
    my $self         = shift;
    my $q            = $self->query();
    my $dbc          = $self->param('dbc');
    my $chemistry_id = $q->param('Chemistry_ID');
    my $status       = $q->param('Status');

    my $chemistry_obj = new alDente::Chemistry( -dbc => $dbc, -id => $chemistry_id );
    my ($info) = $dbc->Table_find( 'Standard_Solution', 'Standard_Solution_Status,Standard_Solution_Name', "where Standard_Solution_ID = $chemistry_id" );
    my ( $old_status, $chemistry_name ) = split ',', $info if ($info);
    my $ok = $chemistry_obj->set_chemistry_status( -id => $chemistry_id, -status => $status );
    if   ($ok) { Message("Status Set to <B>$status</B>"); }
    else       { Message("Status was not affected"); }

    ## generate notification to admins if TechD chemistry changed from 'Under Development' to 'Active'
    if ( $old_status eq 'Under Development' && $status eq 'Active' ) {
        require alDente::Admin;
        alDente::Admin::send_status_change_notification( -dbc => $dbc, -type => 'Standard Solution', -name => $chemistry_name );
    }

    ## reload chemistry
    $chemistry_obj->load_chemistry( -id => $chemistry_id, -force => 1, -quick_load => 1 );
    return $chemistry_obj->show_Formula();
}

###########################
# Accept TechD chemistry
###########################
sub accept_chemistry {
###########################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');
    my $chem = $q->param('Standard_Solution Choice') || $q->param('Chemistry');

    if ( !$chem || $chem eq '-' ) {
        $dbc->message("No standard chemistry was selected");
        return;
    }

    if ( !grep( /Admin/i, @{ $dbc->get_local('Access')->{$Current_Department} } ) ) {
        Message("Please ask $Current_Department Admins to accept the chemistry");
        return;
    }

    ## assign 'Admin' Grp_Access to the production grp
    my $chem_id = $dbc->get_FK_ID( 'FK_Standard_Solution__ID', $chem );

    my $chem_obj = new alDente::Chemistry( -dbc => $dbc, -id => $chem_id );

    my $grp_access = $chem_obj->get_grp_access( -dbc => $dbc, -name => $chem );
    my $depart_id = $dbc->get_FK_ID( 'FK_Department__ID', $Current_Department );
    my @prod_grps = alDente::Grp::get_Grps( -dbc => $dbc, -department => $depart_id, -type => 'Production', -format => 'ids' );
    my $production_grp = $prod_grps[0] if ( int(@prod_grps) );
    my $access = 'Admin';    # assign 'Admin' permission to the production grp
    my $ok_prod;
    if ( grep /^$production_grp$/, keys %$grp_access ) {
        if ( $grp_access->{$production_grp} eq 'Admin' ) {

            # admin permission already. Do nothing
            $ok_prod = 1;
        }
        else {    # update Grp_Access to 'Admin'
            $ok_prod = $dbc->Table_update_array( 'GrpStandard_Solution', ['Grp_Access'], [$access], "where FK_Standard_Solution__ID = $chem_id and FK_Grp__ID = $production_grp ", -autoquote => 1 );
        }
    }
    else {        # associate production grp with the protocol
        $ok_prod = $dbc->Table_append_array( 'GrpStandard_Solution', [ 'FK_Grp__ID', 'FK_Standard_Solution__ID', 'Grp_Access' ], [ $production_grp, $chem_id, $access ], -autoquote => 1 );
    }

    ## assign 'Read-only' Grp_Access to the TechD grp
    my @techD_grps = alDente::Grp::get_Grps( -dbc => $dbc, -department => $depart_id, -type => 'TechD', -format => 'ids' );
    my $techD_grp = $techD_grps[0] if ( int(@techD_grps) );

    my $ok_techD = $dbc->Table_update_array( 'GrpStandard_Solution', ['Grp_Access'], ['Read-only'], "where FK_Standard_Solution__ID = $chem_id and FK_Grp__ID = $techD_grp ", -autoquote => 1 );

    my $grp_name = $dbc->get_FK_info( 'FK_Grp__ID', $production_grp );
    if ( $ok_prod && $ok_techD ) {
        Message("$chem has been accepted by $grp_name successfully.");
        return 1;
    }
    else {
        Message("Error: Accepting $chem by $grp_name hasn't been completed.");
        return 0;
    }

}

sub show_chemistry {
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');
    my $chem = $q->param('Standard_Solution Choice') || $q->param('Chemistry');

    if ( !$chem || $chem eq '-' ) {
        $dbc->message("No standard chemistry was selected");
        return;
    }

    #$chem =~ s/\+/ /g;
    my $chem_id = $q->param('Chemistry_ID') || $q->param('Standard_Solution_ID');
    my $wells   = $q->param('Wells')        || $q->param('Samples');
    my $blocks  = $q->param('Blocks');
    my $blocksX = $q->param('BlocksX');
    if ( $blocks && $blocksX ) { $wells = $blocks * $blocksX }

    my $Formula = alDente::Chemistry->new( -dbc => $dbc, -id => $chem_id, -name => $chem );

    if ( $chem_id || $chem ) {
        $Formula->show_Formula();
    }
    else {
        $Formula->list_Formulas();
    }
    return 1;
}

return 1;

