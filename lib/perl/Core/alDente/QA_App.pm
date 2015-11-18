##################
# QA_App.pm #
##################
#
# This module is used to monitor QAs for Library and Project objects.
#
package alDente::QA_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

#use CGI qw(:standard);
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML qw(vspace HTML_Dump);

use alDente::QA;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Prefix $URL_temp_dir $html_header);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('QA_broker');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'Start QC'                 => 'QA_broker',
            'Re-Test QC'               => 'QA_broker',
            'Fail QC'                  => 'QA_broker',
            'Pass QC'                  => 'QA_broker',
            'QC Gel'                   => 'QA_broker',
            'Fail/Throw Out'           => 'QA_broker',
            'Fail QC Status'           => 'force_fail_plates',
            'QC Monitoring'            => 'monitor_Control_Plate',
            'Control Plate Monitoring' => 'monitor_Control_Plate',
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    return $self;
}

##################
sub force_fail_plates {
##################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $type      = $q->param('type');
    my $plate_ids = $q->param('Current Plates');
    $plate_ids = join ',', $q->param('Mark') if ( !$plate_ids );
    if ($plate_ids) {
        Message "Failing plates $plate_ids";
        my $ok = $dbc->Table_update_array( 'Plate', ['QC_Status'], ['Failed'], "WHERE Plate_ID IN ($plate_ids)", -no_triggers => 1, -autoquote => 1 );
    }
    return;

}

##################
sub QA_broker {
##################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $type      = $q->param('type');
    my $qc_type   = $q->param('QC_Type');
    my $qc_status = $q->param('rm');
    my @solutions = $q->param('Solution_ID');
    my $qc_gel    = $q->param('QC Gel');
    my $throw_out = $q->param('Throw_Out');
    my $plate_ids = $q->param('Current Plates') || $q->param('Plate_IDs');
    $plate_ids = join ',', $q->param('Mark') if ( !$plate_ids );

    if ( $type eq 'Solution' ) {
        @solutions = $q->param('Mark');
    }

    ( $qc_status, $plate_ids ) = $self->_normalize_qc_status( $qc_status, $plate_ids );

    if (@solutions) {
        $self->QC_Solution( \@solutions, $qc_status, -throw_out => $throw_out );
    }
    elsif ($plate_ids) {
        if ($qc_gel) { $self->QC_Gel($plate_ids) }
        $self->QC_Plate( $plate_ids, $qc_status, $qc_type, -throw_out => $throw_out );
        if ( !$q->param('sub_cgi_application') ) {
            my $container = new alDente::Container( -dbc       => $dbc, -id    => $plate_ids );
            my $view_obj  = new alDente::Container_Views( -dbc => $dbc, -model => $container );
            return $view_obj->std_home_page( -Object => $container, -id => $plate_ids );
        }
    }
    else { Message("NO plates that can be set to $qc_status"); return 0; }

    return 1;
}

#################
sub QC_Plate {
#################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'plate_ids,qc_status,type,throw_out' );
    my $plate_ids = $args{-plate_ids};
    my $qc_status = $args{-qc_status};
    my $type      = $args{-type};
    my $throw_out = $args{-throw_out};
    my $dbc       = $self->param('dbc');

    # set_qc_status casts the ids parameter to a string thus it's ok to pass in a string
    &alDente::QA::set_qc_status(-dbc=>$dbc, -status => $qc_status, -table => 'Plate', -ids => $plate_ids, -qc_type => $type );

    if ( $qc_status eq 'Failed' && $throw_out ) {
        $dbc->message("The plates have been thrown out.");
        &alDente::Container::throw_away( -dbc => $dbc, -ids => $plate_ids, -confirmed => 1 );
    }

    # add the plate prefix to each plate_id and pass in all the plate_ids as a string
    $plate_ids =~ s /\,/$Prefix{Plate}/g;

    return 0;
}

####################
sub QC_Solution {
####################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'solutions,qc_status,throw_out' );
    my $solutions = $args{-solutions};
    my $qc_status = $args{-qc_status};
    my $throw_out = $args{-throw_out};
    my $dbc       = $self->param('dbc');

    &alDente::QA::set_qc_status(
        -dbc=>$dbc,
        -status => $qc_status,
        -table  => 'Solution',
        -ids    => $solutions
    );

    if ( $qc_status eq 'Failed' && $throw_out ) {
        $dbc->message("The solutions have been thrown out.");
        my $sol_id = Cast_List( -list => $solutions, -to => 'String' );
        &alDente::Solution::empty($sol_id);
    }

    if ( $qc_status =~ /Pending|Re-Test|Failed/i ) {
        ## do not go back to solutions home page ?

        ## go back to solutions home page
        my $solutions = join ',', @$solutions;

        #$solutions =~ s /\,/$Prefix{Solution}/g;
        &alDente::Info::GoHome( -dbc => $dbc, -id => $solutions, -table => 'Solution' );
    }
    else {
        ## go back to solutions home page
        my $solutions = join ',', @$solutions;
        $solutions =~ s /\,/$Prefix{Solution}/g;
        &alDente::Info::GoHome( -dbc => $dbc, -id => $solutions, -table => 'Solution' );
    }
    return 0;
}

####################
sub QC_Gel {
####################
    my $self      = shift;
    my $plate_ids = shift;
    my $dbc       = $self->param('dbc');

    require Sequencing::Custom;
    my $result;

    $result = Sequencing::Custom::build_QC( -dbc => $dbc, -plate_ids => $plate_ids );

    if   ($result) { print $result; }
    else           { return 0; }

    return 1;
}

################################
sub monitor_Control_Plate {
################################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $plate = $q->param('Current Plates') || $q->param('Plate_ID');
    require alDente::Control_Plate;

    print alDente::Control_Plate::home_page( $dbc, $plate );
    return;
}

##############################
sub _normalize_qc_status {
##############################
    my $self      = shift;
    my $qc_status = shift;
    my $order_ids = shift;
    my $q         = $self->query;

    my $qc_action = $qc_status;
    my $ids;
    my %id_hash;
    ### Normalize qc_status string ###
    if ( $qc_status =~ /pass/i ) {
        $qc_status = 'Passed';
        $ids       = $q->param('Pending IDs');    #Can only pass pending QC
    }
    elsif ( $qc_status =~ /fail/i ) {
        $qc_status = 'Failed';
        $ids       = $q->param('Pending IDs');    #Can only fail pending QC
    }
    elsif ( $qc_status =~ /test/i ) {
        $qc_status = 'Re-Test';
        $ids       = $q->param('Passed IDs');     #Can only re-test passed QC
    }
    elsif ( $qc_status =~ /start/i ) {
        $qc_status = 'Pending';
        $ids       = $q->param('Ready IDs');      #Can only start QC ready QC
    }
    elsif ($qc_status) {
        Message("QC status $qc_status not recognized");
        return '';
    }

    %id_hash = map { $_ => 1; } grep {$_} split( /,/, $ids );

    #To preserve order, need the orders from Current Plates
    my @order_id = split( /,/, $order_ids );
    my $count = $#order_id;
    my @not_applicable_plates;
    for ( my $i = 0; $i <= $count; $i++ ) {

        #if not in id_hash, then this id is not applicable to the new qc_status
        if ( !$id_hash{ $order_id[$i] } ) {
            push @not_applicable_plates, $order_id[$i];
            splice( @order_id, $i, 1 );
            $count = $#order_id;
            $i--;
        }
    }
    $ids = join( ',', @order_id );
    my $not_applicable_plates_list = join ',', @not_applicable_plates;
    my $not_applicable_plates_num = @not_applicable_plates;
    if ($not_applicable_plates_num) {
        Message("WARNING: $not_applicable_plates_num plates ( $not_applicable_plates_list ) are NOT applicable for $qc_action - ignored!");
    }

    return ( $qc_status, $ids );
}

return 1;
