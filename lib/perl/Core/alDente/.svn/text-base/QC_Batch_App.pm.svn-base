##################
# QC_Batch_App.pm #
##################
#
# This module is used to monitor QC_Batch records
#
package alDente::QC_Batch_App;

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
use RGTools::Conversion;

use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use alDente::QC_Batch;
use alDente::QC_Batch_Views;
use alDente::Validation;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Prefix $URL_temp_dir $html_header);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('QC Batch');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'QC Batch'                    => 'QC_Batch_help',
            'View QC Batch'               => 'view_Batch',
            'Add QC Batch'                => 'add_Batch',
            'Confirm QC Batch'            => 'add_Batch',
            'Pass QC Batch'               => 'pass_Batch',
            'Fail QC Batch'               => 'fail_Batch',
            'Re-Test QC Batch'            => 'retest_Batch',
            'Set Expired QC Batch'        => 'set_expired_Batch',
            'Review History for QC Batch' => 'review_Batch',
            'Release QC Batch'            => 'release_Batch',
            'Reject QC Batch'             => 'reject_Batch',
            'Quarantine QC Batch'         => 'quarantine_Batch',
            'Generate QC Report'          => 'generate_Report',
            'Add QC Batch Type'				=> 'add_QC_Batch_type',
            'Change Name'					=> 'change_QC_Batch_type_name',
            'Delete'						=> 'delete_QC_Batch_type',
        }
    );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    return $self;
}

#
# This method defines a new QC_Batch record as well as the individual QC_Batch_Member records
#
# Input:  either:
# * a Stock_ID (in which case the bacth members are all items from that stock record)
# ..or..
# * a Class of item and a list of ids
# ..or..
# * a Stock_Catalog_Number (and optional Lot number)
#
#
# Return: home page for new Batch_ID
##################
sub add_Batch {
##################
    my $self = shift;

    my $q   = $self->query;
    my $dbc = $self->param('dbc');

    my $catalog = $q->param('Catalog_Number');
    my $stock   = get_Table_Param( -field => 'FK_Stock_Catalog__ID', -dbc => $dbc );
    my $class   = $q->param('FK_Object_Class__ID');
    my $ids     = $q->param('Batch_IDs');

    my $name        = $q->param('QC_Batch_Type_Name') || $q->param('FK_QC_Batch_Type__ID');
    my $lot         = $q->param('Lot_Number');
    my $comments    = $q->param('QC_Batch_Comments');
    my $untracked   = $q->param('Untracked');
    my $confirmed   = $q->param('Confirmed');
    my $lot_since   = $q->param('Lot_Received_Since');
    my $lot_until   = $q->param('Lot_Received_Until');
    my $cat_since   = $q->param('Cat_Received_Since');
    my $cat_until   = $q->param('Cat_Received_Until');
    my $search_by   = $q->param('QC_By');
    my $solution_id = $q->param('FK_Solution__ID');

    my @marked = $q->param('Mark');

    my $stock_catalog_id = $q->param('Stock_Catalog_ID');    ## passed as hidden field after confirmation ...
    my $untracked        = $q->param('Untracked');
    my $count            = $q->param('Count');

    my $debug = 0;

    $comments =~ s /^(.+?)[.;\s]?$/$1. /;                    ## add comment terminator ..

    my $page;
    my $lot_option;

    my $stock_selected;
    if (@marked) {
        $stock_selected = Cast_List( -list => \@marked, -to => 'string', -autoquote => 1 );
        $stock_selected = " AND Stock_ID IN ($stock_selected)";
    }

    if ( $search_by eq 'By Catalog Number' ) {
        if ($lot) { $lot_option = " AND Stock_Lot_Number = '$lot'" }
        if ($cat_since) { $lot_option .= " AND Stock_Received >= '$cat_since'" }
        if ($cat_until) { $lot_option .= " AND Stock_Received <= '$cat_until'" }

        my ($stock_catalog_info) = $dbc->Table_find( 'Stock,Stock_Catalog', 'Stock_Type,Stock_Catalog_ID', "WHERE FK_Stock_Catalog__ID=Stock_Catalog_ID AND Stock_Catalog_Number like '$catalog' $lot_option", -debug => $debug );
        ( $class, $stock_catalog_id ) = split ',', $stock_catalog_info;

        if ( !$class ) { return $dbc->session->error('No class found') }

        $class =~ s/(Primer|Buffer|Matrix|Reagent)/Solution/;

        $ids = join ',', $dbc->Table_find( "$class, Stock, Stock_Catalog", $class . '_ID', "WHERE FK_Stock__ID=Stock_ID AND FK_Stock_Catalog__ID=Stock_Catalog_ID AND Stock_Catalog_Number like '$catalog' $lot_option $stock_selected", -debug => $debug );
    }
    elsif ( $search_by eq 'By Stock' ) {
        $stock_catalog_id = $dbc->get_FK_ID( 'FK_Stock_Catalog__ID', $stock );

        if ($lot)       { $lot_option .= " AND Stock_Lot_Number = '$lot'" }
        if ($lot_since) { $lot_option .= " AND Stock_Received >= '$lot_since'" }
        if ($lot_until) { $lot_option .= " AND Stock_Received <= '$lot_until'" }
        ($class) = $dbc->Table_find( 'Stock_Catalog,Stock', 'Stock_Type', "WHERE FK_Stock_Catalog__ID=Stock_Catalog_ID AND Stock_Catalog_ID = '$stock_catalog_id' $lot_option", -distinct => 1 );

        $class =~ s/(Primer|Buffer|Matrix|Reagent)/Solution/;

        $ids = join ',', $dbc->Table_find( "$class, Stock, Stock_Catalog", $class . '_ID', "WHERE FK_Stock__ID=Stock_ID AND FK_Stock_Catalog__ID=Stock_Catalog_ID AND Stock_Catalog_ID IN ($stock_catalog_id) $lot_option $stock_selected", );
    }
    elsif ( $search_by eq 'By ID' ) {
        $class =~ s/(Primer|Buffer|Matrix|Reagent)/Solution/;
        if ( $ids =~ /[a-zA-Z]/ ) {
            $ids = &get_aldente_id( $dbc, $ids, $class );
        }
        elsif ( $ids =~ /\-/ ) {
            $ids = extract_range($ids);
        }
    }
    elsif ( $search_by eq 'Untracked' ) {
        $class            = 'Untracked';
        $stock_catalog_id = $untracked;
        $confirmed        = 1;                                                   ## no confirmation needed
        $solution_id      = &get_aldente_id( $dbc, $solution_id, 'Solution' );
    }

    #    else {
    #	$dbc->session->error('user must supply one of: class, stock, catalog_number or indicate untracked item');
    #	return alDente::QC_Batch_Views::new_Batch_form($dbc);
    #    }

    if ($untracked) {
        ## ok to continue.. ##
    }
    elsif ( !$ids || !$class ) {
        $dbc->session->error('No Records found matching criteria');
        return alDente::QC_Batch_Views::home_page($dbc);
    }

    Message("Defining new Batch of $class records to QC");

    if ($confirmed) {
        my $Batch = new alDente::QC_Batch( -dbc => $dbc, -class => $class, -ids => $ids, -name => $name, -comments => $comments, -untracked => $untracked, -count => $count, -catalog_id => $stock_catalog_id, -solution_id => $solution_id );
        $page .= alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    }
    else {
        $page .= alDente::QC_Batch_Views::confirm_Batch( -dbc => $dbc, -class => $class, -ids => $ids, -name => $name, -comments => $comments, -catalog_id => $stock_catalog_id, -search_by => $search_by );
    }

    return $page;
}

###################
sub view_Batch {
###################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $q   = $self->query;
    my $dbc = $self->param('dbc');

    my $batch_id = $args{-batch_id} || $q->param('Batch_ID');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );

    my $page = alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    return $page;
}

###################
sub pass_Batch {
###################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $batch_id = $q->param('Batch_ID');
    my $comments = $q->param('Comments');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );

    $Batch->set_Batch( -dbc => $dbc, -batch_id => $batch_id, -status => 'Passed', -comments => $comments );

    my $page = alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    return $page;
}

###################
sub fail_Batch {
###################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $batch_id = $q->param('Batch_ID');
    my $comments = $q->param('Comments');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );
    $Batch->set_Batch( -dbc => $dbc, -batch_id => $batch_id, -status => 'Failed' );

    my $page = alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    return $page;
}

###################
sub retest_Batch {
###################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $batch_id = $q->param('Batch_ID');
    my $comments = $q->param('Comments');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );
    $Batch->set_Batch( -dbc => $dbc, -batch_id => $batch_id, -status => 'Re-Test', -comments => $comments );

    my $page = alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    return $page;
}

###################
sub set_expired_Batch {
###################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $batch_id = $q->param('Batch_ID');
    my $comments = $q->param('Comments');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );
    $Batch->set_Batch( -dbc => $dbc, -batch_id => $batch_id, -status => 'Expired', -comments => $comments );

    my $page = alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    return $page;
}

#######################
sub release_Batch {
#######################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $batch_id = $q->param('Batch_ID');
    my $comments = $q->param('Comments');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );
    $Batch->set_Batch_Member( -dbc => $dbc, -batch_id => $batch_id, -status => 'Released', -comments => $comments );

    my $page = alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    return $page;
}

#######################
sub reject_Batch {
#######################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $batch_id = $q->param('Batch_ID');
    my $comments = $q->param('Comments');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );
    $Batch->set_Batch_Member( -dbc => $dbc, -batch_id => $batch_id, -status => 'Rejected', -comments => $comments );

    my $page = alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    return $page;
}

#######################
sub quarantine_Batch {
#######################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $batch_id = $q->param('Batch_ID');
    my $comments = $q->param('Comments');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );
    $Batch->set_Batch_Member( -dbc => $dbc, -batch_id => $batch_id, -status => 'Quarantined', -comments => $comments );

    my $page = alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $Batch->{batch_id} );
    return $page;
}

##########################
sub generate_Report {
##########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $name          = get_Table_Params( -field => 'FK_QC_Batch_Type__ID', -dbc => $dbc );    # array ref of QC_Batch_Type_Name
    my $manufacturer  = $q->param('FK_Organization__ID');
    my $since         = $q->param('Since');
    my $until         = $q->param('Until');
    my $group         = $q->param('Group_By');
    my @status        = $q->param('QC_Batch_Status');
    my $comments      = $q->param('Comment_String');
    my @member_status = $q->param('QC_Member_Status');

    $group =~ s/\bName\b/QC_Batch_Type_Name/g;
    $group =~ s/\bMonth\b/Left\(QC_Batch_Initiated,7\) as Month/g;
    $group =~ s/\bStatus\b/QC_Batch_Status/g;

    if ( $manufacturer =~ /^--/ ) { $manufacturer = '' }    ## chose
    my $report = alDente::QC_Batch_Views::display_Report( $dbc, $name, $manufacturer, -since => $since, -until => $until, -group => $group, -member_status => \@member_status, -status => \@status, -comments => $comments );

    return $report;
}

#
#
#
###################
sub review_Batch {
###################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $batch_id = $q->param('Batch_ID');

    my $Batch = new alDente::QC_Batch( -dbc => $dbc, -batch_id => $batch_id );
    return alDente::QC_Batch_Views::view_History( $dbc, $Batch );
}

#######################
sub QC_Batch_help {
#######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $id = $q->param('ID');

    if ($id) {
        return alDente::QC_Batch_Views::Batch_home( -dbc => $dbc, -batch => $id );
    }
    else {
        return alDente::QC_Batch_Views::home_page($dbc);
    }
}

########################
# Add new QC_Batch_Type
########################
sub add_QC_Batch_type {
########################	
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $name          = $q->param('New_QC_Batch_Type_Name');
	my $batch_obj = new alDente::QC_Batch( -dbc => $dbc );
	my $new_id = $batch_obj->new_QC_Batch_type( -dbc => $dbc, -name => $name );
	if( $new_id ) {
		$dbc->message( "Added new QC_Batch_Type '$name'" );
	}
	else {
		$dbc->error( "Failed to add new QC_Batch_Type" );
	}
	return;
}

########################
# Change QC_Batch_Type_Name
########################
sub change_QC_Batch_type_name {
########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
	my $old_name = $q->param('FK_QC_Batch_Type__ID');	# the referenced QC_Batch_Type_Name
	my $revised_name = $q->param('Revised_QC_Batch_Type_Name');	
	
	my $batch_obj = new alDente::QC_Batch( -dbc => $dbc );
	my $ok = $batch_obj->update_QC_Batch_type( -dbc => $dbc, -old_name => $old_name, -new_name => $revised_name );
	if( $ok ) {
		$dbc->message( "QC_Batch_Type name changed successfully( $old_name => $revised_name )" );
	}
	else {
		$dbc->error( "Failed to change QC_Batch_Type name" );
	}
	return;
}

########################
# Delete QC_Batch_Type
# If the specified QC_Batch_Type is referenced by QC_Batch records, it is not allowed to delete.
# 
########################
sub delete_QC_Batch_type {
########################	
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $name          = $q->param('FK_QC_Batch_Type__ID');	# the referenced QC_Batch_Type_Name
	my @found = $dbc->Table_find( 'QC_Batch,QC_Batch_Type', 'QC_Batch_ID', "WHERE FK_QC_Batch_Type__ID = QC_Batch_Type_ID AND QC_Batch_Type_Name = '$name'" );
	if( @found ) {
		my $list = join ',', @found;
		$dbc->error( "Deletion failed! $name is referenced by QC_Batch( $list )" );
		return;
	}

	my ( $id ) = $dbc->Table_find( 'QC_Batch_Type', 'QC_Batch_Type_ID', "WHERE QC_Batch_Type_Name = '$name'" );
		
	my $ok = $dbc->delete_records( -table => 'QC_Batch_Type', -id_list => $id, -confirm => 1 );

	if( $ok ) {
		$dbc->message( "QC_Batch_Type '$name' has been deleted" );
	}
	else {
		$dbc->error( "Failed to delete QC_Batch_Type '$name'" );
	}
	
	return;
}


return 1;
