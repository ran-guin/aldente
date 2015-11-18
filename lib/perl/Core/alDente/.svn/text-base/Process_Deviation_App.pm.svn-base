#####################################
# alDente::Process_Deviation_App.pm #
#####################################
#
# Control module that handles Process Deviation related logics
#
package alDente::Process_Deviation_App;
use base RGTools::Base_App;

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

use alDente::Process_Deviation;
use alDente::Process_Deviation_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs);    #

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                               => 'home_page',
            'Link Deviation to Objects'             => 'link_deviation_to_objects',
            'Search Deviation'                      => 'search_deviation',
            'Remove Deviation from Objects'         => 'select_objects',
            'Delete Process Deviation from Objects' => 'confirm_removing_deviation_from_objects',
        }
    );

    my $dbc = $self->param('dbc');
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

####################
# Home page for Process Deviation
#
################
sub home_page {
################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $id = $q->param('ID');
    return alDente::Process_Deviation_Views::home_page( -dbc => $dbc, -id => $id );
}

##############################
# Link process deviation to objects
#
##############################
sub link_deviation_to_objects {
##############################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @deviation_no = $q->param('Process_Deviation.Deviation_No') || $q->param('Process_Deviation.Deviation_No Choice');
    my @object_class = $q->param('Object_Class');
    my @object_ids   = $q->param('Object_ID');

    my $row_count = int(@deviation_no);
    if ( !$row_count ) {
        Message("No data entered");
        return alDente::Process_Deviation_Views::home_page( -dbc => $dbc );
    }

    foreach my $i ( 0 .. $row_count - 1 ) {
        my $dev_no    = $deviation_no[$i];
        my $obj_class = $object_class[$i];
        my $obj_ids   = $object_ids[$i];
        next if ( !$dev_no || !$obj_class || !$obj_ids );

        my @ids = @{ alDente::Process_Deviation::convert_ids( -dbc => $dbc, -object_class => $obj_class, -object_ids => $obj_ids ) };

        my @invalid_ids;
        my $valid_list = $dbc->valid_ids( -ids => \@ids, -table => $obj_class );
        my @valid_ids;

        if ($valid_list) {
            @valid_ids = split ',', $valid_list;
            @invalid_ids = RGmath::minus( \@ids, \@valid_ids );
        }
        else {
            @invalid_ids = @ids;
        }

        #if( int( @invalid_ids ) ) {
        #	my $list = join ',', @invalid_ids;
        #	$dbc->warning( "Invalid $obj_class IDs entered: $list" );
        #}

        if ($valid_list) {
            my $PD = new alDente::Process_Deviation( -dbc => $dbc );
            my $ok = $PD->link_deviation_to_objects( -dbc => $dbc, -deviation_no => $dev_no, -object_class => $obj_class, -object_ids => \@valid_ids );
            if ($ok) {
                $dbc->message("$obj_class IDs ($valid_list) have been linked to $dev_no");
            }
        }
    }

    return alDente::Process_Deviation_Views::home_page( -dbc => $dbc, -deviation_Nos => \@deviation_no );
}

####################
# Search Process Deviation
#
################
sub search_deviation {
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $dev_no    = $q->param('Process_Deviation.Deviation_No') || $q->param('Process_Deviation.Deviation_No Choice');
    my $obj_class = $q->param('Object_Class');
    my $obj_ids   = $q->param('Object_ID');

    return if ( !$dev_no && !$obj_class && !$obj_ids );

    my @ids;
    if ( $obj_ids =~ /,/ ) {    # comma separated list format
        @ids = Cast_List( -list => $obj_ids, -to => 'array' );
    }
    elsif ( $obj_ids =~ /^\s*(\d+)\s*-\s*(\d+)\s*$/ ) {    # all digits in range
        my $from = $1;
        my $to   = $2;
        foreach my $id ( $from .. $to ) {
            push @ids, $id;
        }
    }
    elsif ($obj_ids) {
        push @ids, $obj_ids;
    }

    my $obj_ids_list;
    if ( int(@ids) ) {
        $obj_ids_list = join ',', @ids;
    }
    my $pds = alDente::Process_Deviation::get_deviation( -dbc => $dbc, -deviation_no => $dev_no, -object_class => $obj_class, -object_id => $obj_ids_list );
    if ( !$pds ) {
        Message("No process deviation meet your search criteria!");
    }
    return alDente::Process_Deviation_Views::home_page( -dbc => $dbc, -ids => $pds );

}

############################################
#
# Select Process Deviation linked to objects
#
############################################
sub select_objects {
############################################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    # Get parameters from the HTTP request
    my $dev_no    = $q->param('Process_Deviation.Deviation_No') || $q->param('Process_Deviation.Deviation_No Choice');
    my $obj_class = $q->param('Object_Class');
    my $obj_ids   = $q->param('Object_ID');
    my $missing   = 0;

    # Error checking
    if ( !$dev_no ) {
        $dbc->error("Missing deviation number.");
        $missing = 1;
    }

    if ( !$obj_class ) {
        $dbc->error("Missing object class.");
        $missing = 1;
    }

    if ( !$obj_ids ) {
        $dbc->error("Missing object ID.");
        $missing = 1;
    }

    if ($missing) { return; }

    my $ids = alDente::Process_Deviation::convert_ids( -dbc => $dbc, -object_class => $obj_class, -object_ids => $obj_ids );
    my $id_list = Cast_List( -list => $ids, -to => 'string', -autoquote => 1 );

    my $obj_class_id = $dbc->get_FK_ID( 'FK_Object_Class__ID', $obj_class );

    my $tables     = "Process_Deviation_Object";
    my @field_list = ( 'Process_Deviation_Object_ID', 'FK_Process_Deviation__ID', 'FK_Object_Class__ID', 'Object_ID', 'FK_Employee__ID' );
    my $condition  = "WHERE FK_Object_Class__ID = $obj_class_id AND Object_ID in ($id_list)";

    return alDente::Process_Deviation_Views::select_objects_view( -dbc => $dbc, -tables => $tables, -fields => \@field_list, -condition => $condition );
}

##########################################
#
# Delete process deviation links to objects
#
##########################################
sub confirm_removing_deviation_from_objects {
    my $self = shift;
    my $q    = $self->query;
    my @ids  = $q->param('Mark');
    my $dbc  = $self->param('dbc');

    my $obj_id = Cast_List( -list => \@ids, -to => 'string', -autoquote => 0 );
    my $ok = $dbc->delete_records( -table => 'Process_Deviation_Object', -field => 'Process_Deviation_Object_ID', -id_list => $obj_id, -quiet => 1 );
    if ($ok) {
        ## deleted samples successfully ##
        #$dbc->finish_trans("delete_deviation_objects $obj_id");
        Message("Process Deviation Object(s) $obj_id have been deleted");
    }
    else {
        Message("Failed to delete Process Deviation Object(s) $obj_id");
    }
}

return 1;

