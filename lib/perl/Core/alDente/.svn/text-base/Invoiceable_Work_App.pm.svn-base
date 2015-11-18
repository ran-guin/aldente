###################################################################################################################################
# Sequencing::Statistics.pm
#
#
#
#
###################################################################################################################################
package alDente::Invoiceable_Work_App;
use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;
use RGTools::Views;
use SDB::CustomSettings;
use RGTools::Object;
use alDente::SDB_Defaults;

use alDente::Invoiceable_Work;
use alDente::Invoiceable_Work_Views;

use vars qw( %Configs);

############
sub setup {
############

    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'home_page'              => 'home_page',
        'Change Billable Status' => 'change_billable',
        'Set Funding'            => 'change_funding',
        'Update Funding'         => 'change_funding_multiple',

        #'Set Billable Status' => 'change_billable',
        'Append Invoiceable Work Item Comment' => 'append_invoiceable_work_item_comment',
    );

    my $dbc = $self->param('dbc');

    $self->param(
        'Model' => alDente::Invoiceable_Work->new( -dbc       => $dbc ),
        'View'  => alDente::Invoiceable_Work_Views->new( -dbc => $dbc ),

    );

    return $self;

}

##################
sub home_page {
##################

    my $self = shift;

    my $dbc = $self->param('dbc');

    $q = $self->query();

    my $id = $q->param("Invoiceable_Work_ID") || $q->param('ID');

    my $invoiceable_work = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $id, -initialize => 0 );
    my $invoiceable_work_view = new alDente::Invoiceable_Work_Views( -dbc => $dbc, -id => $id, -model => { 'Invoiceable_Work' => $invoiceable_work } );

    return $invoiceable_work_view->home_page( -dbc => $dbc, -id => $id );
}

# ##############################
# sub change_billable_iwr {
# ##############################
# my $self = shift;
# my %args = filter_input( \@_, 'dbc' );
# my $dbc  = $args{-dbc} || $self->param('dbc');
# my $q    = $self->query;

# my $status    = $q->param('Billable');
# my $comments  = $q->param('Billable_Comments');
# my $time      = date_time();
# my $from_view = '';
# my @ids_list;

# $dbc->warning("In change_billable_iwr()\n");  ## for debug only delete later

# push( @ids_list, $q->param('ID') );

# if ( !@ids_list ) {
# $from_view = 'Yes';
# @ids_list  = $q->param('Mark');
# }
# my $mark_field = $q->param('MARK_FIELD');

# #Message("mark_field = $mark_field");    ## for debug only delete later
# #print HTML_Dump \@ids_list;

# if( $mark_field =~ /Invoiceable_Work_ID/ ) {

# }
# elsif( $mark_field =~ /Invoiceable_Work_Reference_ID/ ) {

# }
# return;
# }

##############################
#
# changes the billable status of invoiceable_work or invoiceable work reference and appends the given comment
# Comments are assumed to be mandatory
# this method can be called from both the work/run and the invoiced_work views
#
##############################
sub change_billable {
##############################
    my $self  = shift;
    my %args  = filter_input( \@_, 'dbc' );
    my $dbc   = $args{-dbc} || $self->param('dbc');
    my $debug = $args{-debug};
    my $q     = $self->query;

    my $status    = $q->param('Billable');
    my $comments  = $q->param('Billable_Comments');
    my $time      = date_time();
    my $from_view = '';                               ## A parameter that tells if command is from the views or not.
    my $from_run  = ();                               ## Just to make sure its not recursively calling each other.
    my @ids_list;

    $dbc->warning("In change_billable()\n") if $debug;
    Message("In change_billable()")         if $debug;

    push( @ids_list, $q->param('ID') );               ## gets /Invoiceable_Work_ID from user input

    if ( !@ids_list ) {                               ## If there is no param that is called ID then it is from the views and should be called 'Mark'
        $from_view = 'Yes';
        @ids_list  = $q->param('Mark');
    }
    my $mark_field = $q->param('MARK_FIELD');

    ## change billable status from Invoable_Work_Reference side view (lib construction->public view->invoiced work)
    if ( $mark_field =~ /Invoiceable_Work_Reference_ID/ ) {

        Message("mark_field = Invoiceable_Work_Reference_ID") if $debug;
        my @changed_invoiced_iwr_id;
        my @changed_run_type_iwr_id;
        my @update_infor;

        my $formatted_comment .= "[$time | Billable($status)] - ";
        $formatted_comment    .= "$comments";
        $formatted_comment =~ s/([\,\'\"\\])/\\$1/g;

        foreach my $r_id (@ids_list) {
            my $iw = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $r_id, -initialize => 0 );
            my $iw_view = new alDente::Invoiceable_Work_Views( -dbc => $dbc, -id => $r_id, -model => { 'Invoiceable_Work' => $iw } );

            my ($billable_info) = $dbc->Table_find_array( 'Invoiceable_Work_Reference', [ 'Invoiceable_Work_Reference_Invoiced', 'Billable' ], "WHERE Invoiceable_Work_Reference_ID IN ($r_id)" );
            my ( $invoiced, $old_status ) = split ',', $billable_info;

            my ($iw_id) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FKReferenced_Invoiceable_Work__ID', "WHERE Invoiceable_Work_Reference_ID IN ($r_id)" );
            my $ok2;

            if ($iw_id) {
                $ok2 = $dbc->Table_update_array( 'Invoiceable_Work', ['Invoiceable_Work_Comments'], ["'$formatted_comment'"], "WHERE Invoiceable_Work_ID IN ($iw_id)", -append_only_fields => ['Invoiceable_Work_Comments'] );
            }
            if ( $status eq $old_status ) {
                print Message("Work Reference ID: $r_id - Same billable status, comment still appended but billable status not changed!");
                if ($from_view) {
                    next;
                }
                else {
                    return $iw_view->home_page( -dbc => $dbc, -id => $r_id );
                }
            }
            push @update_infor, $r_id;

            if ($ok2) {
                my ($not_run_work_type) = $dbc->Table_find_array( 'Invoiceable_Work, Invoiceable_Work_Reference',
                    ['Invoiceable_Work_ID'], "WHERE Invoiceable_Work_Reference_ID IN ($r_id) AND FKReferenced_Invoiceable_Work__ID = Invoiceable_Work_ID AND Invoiceable_Work_Type != 'Run'" );

                if ($not_run_work_type) {

                    my ($iw_id) = $dbc->Table_find_array( 'Invoiceable_Work, Invoiceable_Work_Reference', ['Invoiceable_Work_ID'], "WHERE Invoiceable_Work_ID = FKReferenced_Invoiceable_Work__ID AND Invoiceable_Work_Reference_ID = $r_id" );

                    my (@iwr_family) = $dbc->Table_find_array( 'Invoiceable_Work_Reference', ['Invoiceable_Work_Reference_ID'], "WHERE FKReferenced_Invoiceable_Work__ID = $iw_id" );

                    my $iwr_family_string = join ',', @iwr_family;

                    my @invoiced = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE Invoiceable_Work_Reference_ID IN ($iwr_family_string) AND Invoiceable_Work_Reference_Invoiced = 'Yes'" );

                    if (@invoiced) {
                        push @changed_invoiced_iwr_id, $r_id;    ## later will be used for sending email notification for non run work type
                    }
                }
            }
        }

        if (@update_infor) {
            my $update_infor_id_string = join ',', @update_infor;
            my (@children) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE FKParent_Invoiceable_Work_Reference__ID IN ($update_infor_id_string)" );
            push @update_infor, @children;

            while (@children) {
                my $children_string = join ',', @children;
                @children = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference_ID', "WHERE FKParent_Invoiceable_Work_Reference__ID IN ($children_string)" );
                push @update_infor, @children;
            }

            my $id_string = join ',', @update_infor;
            my $ok1 = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['Invoiceable_Work_Reference.Billable'], ["$status"], "WHERE Invoiceable_Work_Reference_ID IN ($id_string)", -autoquote => 1 );

            if ($ok1) {
                print Message("Billable status of Invoiceable_Work_Reference_ID $id_string has been changed to '$status'.<br>Comments '$comments' was appended");
            }
        }
        if (@changed_invoiced_iwr_id) {
            my $iwr_string = join ',', @changed_invoiced_iwr_id;
            ## filter out the duplicate iw_ids
            my (@iw_ids) = $dbc->Table_find_array( 'Invoiceable_Work_Reference', ['FKReferenced_Invoiceable_Work__ID'], "WHERE Invoiceable_Work_Reference_ID IN ($iwr_string) GROUP BY FKReferenced_Invoiceable_Work__ID" );

            my $iw_string = join ',', @iw_ids;
            ## filter out the iw_ids that have the same library names
            my (@unique_iw_id) = $dbc->Table_find_array( 'Invoiceable_Work, Plate, Library', ['Invoiceable_Work_ID'], "WHERE Invoiceable_Work_ID IN ($iw_string) AND FK_Plate__ID = Plate_ID AND FK_Library__Name = Library_Name GROUP BY Library_Name;" );

            foreach my $iw_id (@unique_iw_id) {
                my @comments = $dbc->Table_find_array( 'Invoiceable_Work', ['Invoiceable_Work_Comments'], "WHERE Invoiceable_Work_ID = $iw_id" );
                alDente::Invoiceable_Work::billable_status_change_notification( $dbc, -iw_ids => $iw_id, -billable_status => $status, -billable_comments => $comments[0] );
            }
        }
    }
    ## change billable status from run/work side view
    else {
        Message("mark_field = Invoiceable_Work_ID") if $debug;

        foreach my $id (@ids_list) {

            my $iw = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $id, -initialize => 0 );
            my $iw_view = new alDente::Invoiceable_Work_Views( -dbc => $dbc, -id => $id, -model => { 'Invoiceable_Work' => $iw } );

            my ($billable_info) = $dbc->Table_find_array(
                'Invoiceable_Work_Reference, Invoiceable_Work',
                [ 'Invoiceable_Work_Reference_Invoiced', 'Billable' ],
                "WHERE FKReferenced_Invoiceable_Work__ID in ($id) AND (Indexed IS NULL OR Indexed = 0) AND FKReferenced_Invoiceable_Work__ID = Invoiceable_Work_ID"
            );

            my ( $invoiced, $old_status ) = split ',', $billable_info;

            my $formatted_comment .= "[$time | Billable($status)] - ";
            $formatted_comment    .= "$comments";
            $formatted_comment =~ s/([\,\'\"\\])/\\$1/g;

            my $ok2 = $dbc->Table_update_array( 'Invoiceable_Work', ['Invoiceable_Work_Comments'], ["'$formatted_comment'"], "WHERE Invoiceable_Work_ID IN ($id)", -append_only_fields => ['Invoiceable_Work_Comments'] );

            if ( $status eq $old_status ) {
                print Message("Work ID: $id - Same billable status, comment still appended but billable status not changed!");
                if ($from_view) {
                    next;
                }
                else {
                    return $iw_view->home_page( -dbc => $dbc, -id => $id );
                }
            }
            my ($is_run_work_type) = $dbc->Table_find( 'Invoiceable_Run', 'FK_Run__ID', "WHERE FK_Invoiceable_Work__ID IN ($id)" );    ## if work type is run, update will call the trigger method

            if ($is_run_work_type) {
                print Message("work type is run situation") if $debug;
                my $ok1 = $dbc->Table_update_array( 'Run', ['Run.Billable'], ["$status"], "WHERE Run_ID IN ($is_run_work_type)", -autoquote => 1 );
            }
            else {
                print Message("work type is not run situation") if $debug;
                my $ok1 = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['Billable'], ["$status"], "WHERE FKReferenced_Invoiceable_Work__ID IN ($id)", -autoquote => 1 );

                if ( $ok2 && $ok1 ) {
                    my @invoiced_iwr_ids
                        = $dbc->Table_find_array( 'Invoiceable_Work_Reference', [ 'Invoiceable_Work_Reference_ID', 'Invoiceable_Work_Reference_Invoiced' ], "WHERE FKReferenced_Invoiceable_Work__ID = $id AND Invoiceable_Work_Reference_Invoiced = 'Yes'" );
                    if (@invoiced_iwr_ids) {
                        my @comments = $dbc->Table_find_array( 'Invoiceable_Work', ['Invoiceable_Work_Comments'], "WHERE Invoiceable_Work_ID = $id" );
                        alDente::Invoiceable_Work::billable_status_change_notification( $dbc, -iw_ids => $id, -billable_status => $status, -billable_comments => $comments[0] );
                    }
                }
            }
            print Message("Billable status of iw_id $id has been changed to '$status'.<br>Comments '$comments' was appended");
            if ( !$from_view ) {
                return $iw_view->home_page( -dbc => $dbc, -id => $id );
            }
        }
    }
    return;
}

##############################
# changes the funding of invoiceable_work
#
# Assumes that the input $funding is a string not a number ie GSC-0977 [Received]
# The variable $funding_id converts this into an id ie 603
#
##############################
sub change_funding {
##############################

    my $self      = shift;
    my %args      = filter_input( \@_, 'dbc' );
    my $dbc       = $args{-dbc} || $self->param('dbc');
    my $q         = $self->query;
    my $funding   = $q->param('FK_Funding__ID Choice') || $q->param('FK_Funding__ID');    ## An inputted string
    my $from_view = '';                                                                   ## A parameter that tells if command is from the views or not.
    my @ids_list;
    push( @ids_list, $q->param('ID') );

    ## If there is no param that is called ID then it is from the views and should be called 'Mark'
    if ( !@ids_list ) {
        $from_view = 'Yes';
        @ids_list  = $q->param('Mark');
    }

    foreach my $id (@ids_list) {

        my $iw = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $id, -initialize => 0 );
        my $iw_view = new alDente::Invoiceable_Work_Views( -dbc => $dbc, -id => $id, -model => { 'Invoiceable_Work' => $iw } );

        ## Converts the string from a concat of variables to an ID
        my $funding_id = $dbc->get_FK_ID( -field => "FK_Funding__ID", -value => $funding );
        my $updated;

        my $IW_obj = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $id );
        if ( $IW_obj->has_multiple_invoiceable_work_ref( -dbc => $dbc, -id => $id ) ) {
            require alDente::Invoiceable_Work_Views;
            return $iw_view->confirm_update_funding_page( -dbc => $dbc, -id => $id, -funding => $funding );
        }

        if ($updated) {
            print Message("Invoiceable_Work_ID $id: Funding updated to $funding");
        }
        else {
            print Message("Warning: Invoiceable_Work item has failed to update!");
        }

        if ( !$from_view ) { return $iw_view->home_page( -dbc => $dbc, -id => $id ); }

    }
    return;
}

##############################
# changes the funding of invoiceable_work
#
# Assumes that the input $funding is a string not a number ie GSC-0977 [Received]
# The variable $funding_id converts this into an id ie 603
#
##############################
sub change_funding_multiple {
##############################
    my $self    = shift;
    my %args    = filter_input( \@_, 'dbc' );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $q       = $self->query;
    my $funding = $q->param('FK_Funding__ID');

    #    my $from_view = '';                                                                   ## A parameter that tells if command is from the views or not.
    my @ids_list;

    @ids_list = $q->param('Mark');

    my ($parent_iwr)          = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FKParent_Invoiceable_Work_Reference__ID', "WHERE Invoiceable_Work_Reference_ID = @ids_list[0]" );
    my ($invoiceable_work_id) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FKReferenced_Invoiceable_Work__ID',       "WHERE Invoiceable_Work_Reference_ID = $parent_iwr" );

    push( @ids_list, $parent_iwr );

    my $iw = new alDente::Invoiceable_Work( -dbc => $dbc, -id => $invoiceable_work_id, -initialize => 0 );
    my $iw_view = new alDente::Invoiceable_Work_Views( -dbc => $dbc, -id => $invoiceable_work_id, -model => { 'Invoiceable_Work' => $invoiceable_work_id } );

    foreach my $id (@ids_list) {

        ## Converts the string from a concat of variables to an ID
        my $funding_id = $dbc->get_FK_ID( -field => "FK_Funding__ID", -value => $funding );
        my $updated;

        $updated = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['FKApplicable_Funding__ID'], [$funding_id], "WHERE Invoiceable_Work_Reference_ID = $id" );

        if ($updated) {
            if ( $id == $parent_iwr ) {
                print Message("Invoiceable_Work_ID $invoiceable_work_id : Funding updated to $funding<br><br>");
            }
            else {
                print Message("Invoiceable_Work_Reference_ID $id : Funding updated to $funding");
            }
        }
        else {
            if ( $id == $parent_iwr ) {
                print Message("Warning: Invoiceable_Work_ID '$invoiceable_work_id' has failed to update!<br><br>");
            }
            else {
                print Message("Warning: Invoiceable_Work_Reference item '$id' has failed to update!");
            }
        }
    }

    #    if ( !$from_view ) { return $iw_view->home_page( -dbc => $dbc, -id => $id ); }
    return $iw_view->home_page( -dbc => $dbc, -id => $invoiceable_work_id );

    #    return;
}

######################
# Handle the 'Append Invoiceable Work Item Comment' run mode
#
#########################
sub append_invoiceable_work_item_comment {
#########################
    my $self = shift;
    my %args = filter_input( \@_, 'dbc' );
    my $dbc  = $args{-dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $iw_comments = $q->param('IW_Comments');
    my $mark_field  = $q->param('MARK_FIELD');
    my @ids         = $q->param('Mark');
    if ( !@ids ) { $dbc->message("No records are selected for appending comments!"); return }

    if ( $mark_field =~ /Invoiceable_Work_Reference_ID/ ) {
        my $id_list = Cast_List( -list => \@ids, -to => 'String' );
        @ids = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FKReferenced_Invoiceable_Work__ID', "WHERE Invoiceable_Work_Reference_ID in ($id_list)", -distinct => 1 );
    }

    my $ok;
    if (@ids) {
        $ok = alDente::Invoiceable_Work::append_invoiceable_work_comment( -dbc => $dbc, -invoiceable_work_id => \@ids, -iw_comments => $iw_comments );
    }
    else {
        $dbc->message("No Invoiceable_Work record found. Comments are not appened!");
    }
    return;
}

return 1;
