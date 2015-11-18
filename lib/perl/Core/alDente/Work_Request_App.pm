##################
# Work_Request_App.pm #
##################
#
# This is a Work_Request for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Work_Request_App;

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

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use SDB::HTML;
use SDB::DBIO;
use alDente::Work_Request;
use alDente::Work_Request_Views;
use alDente::Tools;
use alDente::Form;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#
######################################################
##          Controller                              ##
######################################################
############
sub setup {
############
    my $self = shift;

    $self->start_mode('default_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default_page'                => 'default_page',
            'home_page'                   => 'home_page',
            'summary_page'                => 'summary_page',
            'Search'                      => 'search_results',
            'New Work Request'            => 'new_work_request',
            'New Custom Work Request'     => 'new_custom_work_request',
            'Protocol Page'               => 'protocol_page',
            'funding_page'                => 'funding_page',
            'Show Work Requests'          => 'show_Work_Requests',
            'Update Funding Source'       => 'update_Funding',
            'Save Work Requests'          => 'save_funding_work_requests',
            'Change Plate Work_Request'   => 'change_plate_work_request',
            'Confirm Change Work Request' => 'confirm_work_request_change',
            'Confirm Change'              => 'confirm_change_with_iw_funding_change',
            'Add Goals'                   => 'add_work_request',
            'Save Goals'                  => 'save_work_request',
            'Cancel'                      => 'home_page',                               # has problem need to be home page!!!!! come back to fix it ***
        }
    );

    my $dbc = $self->param('dbc');
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    $self->param( 'Model' => alDente::Work_Request->new( -dbc => $dbc ) );

    return $self;
}

#####################
# keep modify it !!!!
####################
sub home_page {
####################

    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');

    return;
}

############################
sub default_page {
############################
    #
    # home_page (default)
    #
    # Return: display (table)
############################
    my $self  = shift;
    my $q     = $self->query();
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->param('dbc');
    my $id    = join ',', $q->param('ID') || join ',', $q->param('Work_Request_ID');
    my $model = $self->param('Model');

    if ( $id =~ /,/ ) {
        return alDente::Work_Request_Views::display_list_page( -id => $id, -dbc => $dbc );
    }
    elsif ($id) {
        my $db_object         = $model->get_db_object( -dbc     => $dbc, -id => $id );
        my $work_requests_ref = $model->get_other_WR_ids( -dbc  => $dbc, -id => $id );
        my $WR_plates         = $model->get_WR_plate_ids( -dbc  => $dbc, -id => $id );
        my $lib_plates        = $model->get_Lib_plate_ids( -dbc => $dbc, -id => $id );

        return alDente::Work_Request_Views::display_home_page(
            -model          => $self->param('Model'),
            -id             => $id,
            -dbc            => $dbc,
            -DB_obj         => $db_object,
            -WR_ids         => $work_requests_ref,
            -library_plates => $lib_plates,
            -WR_plates      => $WR_plates
        );
    }
    else {
        return alDente::Work_Request_Views::display_search_page( -dbc => $dbc );
    }
}

#############################
sub show_Work_Requests {
#############################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    my $lib       = $q->param('Library_Name') || $q->param('Library');     ## $args{-library};
    my $goal      = $q->param('Goal_ID')      || $q->param('Goal');        ## $args{-goal_id};
    my $condition = $q->param('Condition')    || $args{-condition} || 1;

    if ($lib)  { $condition .= " AND FK_Library__Name='$lib'" }
    if ($goal) { $condition .= " AND Goal_ID IN ($goal)" }

    my $show = $dbc->Table_retrieve_display(
        "Work_Request,Goal,Work_Request_Type LEFT JOIN Submission_Table_Link ON Submission_Table_Link.Key_Value = Work_Request_ID AND Submission_Table_Link.Table_Name = 'Work_Request' LEFT JOIN Submission ON Submission_Table_Link.FK_Submission__ID=Submission_ID",
        [ 'Work_Request_ID', 'FK_Funding__ID', 'Goal_Name', 'Work_Request_Type_Name as Goal_Type', 'Goal_Target', 'Goal_Target_Type', 'Submission_Table_Link.FK_Submission__ID', 'Submission_DateTime', 'Comments' ],
        -condition   => "WHERE $condition AND Work_Request.FK_Goal__ID=Goal_ID AND Work_Request_Type_ID=FK_Work_Request_Type__ID AND Scope = 'Library' ORDER BY Work_Request_ID",
        -title       => "$lib Work Requests for " . alDente_ref( 'Goal', $goal, -dbc => $dbc ),
        -return_html => 1,
        -debug       => 0
    );
    return $show;
}

############################
sub search_results {
############################
    my $self         = shift;
    my $q            = $self->query();
    my $dbc          = $self->param('dbc');
    my $lib          = $q->param('FK_Library__Name');
    my $type         = $q->param('FK_Work_Request_Type__ID Choice') || $q->param('FK_Work_Request_Type__ID');
    my $funding      = $q->param('FK_Funding__ID Choice') || $q->param('FK_Funding__ID ');
    my $proj         = $q->param('FK_Project__ID Choice') || $q->param('FK_Project__ID');
    my $plate_format = $q->param('FK_Plate_Format__ID Choice') || $q->param('FK_Plate_Format__ID');
    my $model        = $self->param('Model');

    #use alDente::Work_Request;
    my $ids_ref = $model->get_WR_ids(
        -library      => $lib,
        -funding      => $funding,
        -project      => $proj,
        -plate_format => $plate_format,
        -type         => $type,
        -dbc          => $dbc
    );
    my @id_array = @$ids_ref;
    my $size     = @id_array;

    if ( $size > 1 ) {
        my $ids_list = join ',', @id_array;
        return alDente::Work_Request_Views::display_list_page( -id => $ids_list, -dbc => $dbc );
    }
    elsif ( $size == 1 ) {
        my $db_object         = $model->get_db_object( -dbc     => $dbc, -id => $id_array[0] );
        my $work_requests_ref = $model->get_other_WR_ids( -dbc  => $dbc, -id => $id_array[0] );
        my $WR_plates         = $model->get_WR_plate_ids( -dbc  => $dbc, -id => $id_array[0] );
        my $lib_plates        = $model->get_Lib_plate_ids( -dbc => $dbc, -id => $id_array[0] );

        return alDente::Work_Request_Views::display_home_page(
            -id             => $id_array[0],
            -dbc            => $dbc,
            -DB_obj         => $db_object,
            -WR_ids         => $work_requests_ref,
            -library_plates => $lib_plates,
            -WR_plates      => $WR_plates
        );

    }
    else {
        Message("No results for criteria. Please try your search again");
        return $self->display_search_page( -dbc => $dbc );
    }

}

############################
sub new_work_request {
############################
    my $self         = shift;
    my $q            = $self->query();
    my $dbc          = $self->param('dbc');
    my $lib          = $q->param('WR_library');
    my $src          = $q->param('WR_source');
    my $funding      = $q->param('Funding_ID');
    my $num_of_goals = $q->param('Number of goals');

    my $grey   = $q->param('Grey');
    my $preset = $q->param('Preset');
    my $custom = $q->param('Custom');

    my %grey;
    my %preset;
    my %hidden;
    my %list;

    my $navigator = 1;
    my $repeat;

    $hidden{Scope} = 'Library';    # Temporarily we would want this to be hidden but preset to 'Library'

    if ($grey)   { %grey   = %$grey }
    if ($preset) { %preset = %$preset }
    if ($custom) {
        $grey{FK_Work_Request_Type__ID} = 'Default Work Request';
        $grey{Goal_Target}              = 1;
        $hidden{Num_Plates_Submitted}   = 0;
        $hidden{Container_Format}       = '';
        $hidden{FKRequest_Employee__ID} = $dbc->get_local('user_id');
    }

    # custom form depending on input parameters
    if ($lib) {
        $grey{FK_Library__Name}   = $lib;
        $preset{Goal_Target_Type} = 'Add to Original Target';
        my @specific_goal = $dbc->get_FK_info( -field => 'FK_Goal__ID', -condition => "WHERE Goal_Scope = 'Specific'", -list => 1 );
        $list{FK_Goal__ID} = \@specific_goal;

    }
    elsif ($src) {
        $grey{FK_Source__ID} = $src;
        my @specific_goal = $dbc->get_FK_info( -field => 'FK_Goal__ID', -condition => "WHERE Goal_Scope = 'Specific'", -list => 1 );
        $list{FK_Goal__ID} = \@specific_goal;

    }
    elsif ($funding) {

        my $timestamp = date_time();

        #$navigator = 0;
        #$repeat    = $num_of_goals - 1;

        $grey{Work_Request_Created}       = $timestamp;
        $grey{FK_Funding__ID}             = $funding;
        $preset{FK_Work_Request_Type__ID} = 'Default Work Request';

        $hidden{FK_Library__Name}     = '';
        $hidden{Goal_Target_Type}     = 'Original Request';
        $hidden{FK_Source__ID}        = '';
        $hidden{Percent_Complete}     = 0;
        $hidden{Num_Plates_Submitted} = 0;
        $hidden{FK_Plate_Format__ID}  = '';

        my @broad_goal = $dbc->get_FK_info( -field => 'FK_Goal__ID', -condition => "WHERE Goal_Scope = 'Broad'", -list => 1 );
        $list{FK_Goal__ID} = \@broad_goal;
    }

    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Work_Request', -target => 'Database' );
    $table->configure( -grey => \%grey, -preset => \%preset, -omit => \%hidden, -list => \%list );

    return $table->generate( -navigator_on => $navigator, -return_html => 1, -repeat => $repeat );
}

################################
#
# Create work request for selected objects (e.g. source, library)
#
################################
sub add_work_request {
################################
    my $self                  = shift;
    my %args                  = filter_input( \@_, 'dbc' );
    my $dbc                   = $args{-dbc} || $self->param('dbc');
    my $q                     = $self->query;
    my @ids                   = $q->param('Mark');
    my $class                 = $q->param('class');
    my $key                   = $q->param('key');
    my $goal_type             = $q->param('Goal_Type');                # allow filter by Goal_Type
    my $include_goals         = $q->param('Goal_Name');                # only show these goals
    my $suppress_source_goals = $q->param('Suppress_Source_Goals');    ## flag not to show goals from source
    unless ($key) { ($key) = $dbc->get_field_info( $class, undef, 'Primary' ); }

    my $count = 0;
    if (@ids) {
        $count = scalar(@ids);
    }

    if ( $count < 1 ) { return "No IDs specified." }

    my $page;

    my $id_list = Cast_List( -list => \@ids, -to => 'string', -autoquote => 0 );
    my @goal_ids;
    if ($include_goals) {
        my @goals = Cast_List( -list => $include_goals, -to => 'array' );
        foreach my $goal_name (@goals) {
            my $goal_id = $dbc->get_FK_ID( 'FK_Goal__ID', $goal_name );
            if ($goal_id) { push @goal_ids, $goal_id }
        }

    }

    $page = $self->View->set_goal_form( -dbc => $dbc, -class => $class, -key => $key, -id => $id_list, -goal_type => $goal_type, -suppress_source_goals => $suppress_source_goals, -include_goal => \@goal_ids );

    return $page;

}

################################
#
# Save new goals for selected objects e.g. source, library
#
################################
sub save_work_request {
################################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->{dbc} || $self->param('dbc');

    my $id_list       = $q->param('IDs');           # e.g. source ids
    my $field_id_list = $q->param('DBField_IDs');
    my $class         = $q->param('class');
    my $max_index     = $q->param('Max_Index');

    my $qid_list = Cast_List( -list => $id_list, -to => 'string', -autoquote => 1 );
    my $key = $dbc->foreign_key( -table => $class );

    my @ids       = split ',', $qid_list;
    my @field_ids = split ',', $field_id_list;
    my %values;
    my $updated = 0;

    my %dup_ids;
    foreach my $i ( 0 .. $#ids ) {
        my $id = $ids[$i];
        $id =~ s/\'//g;
        $ids[$i] = $id;
        my $key_field = $field_ids[0];
        my @field_values;
        foreach my $index ( 0 .. $max_index ) {
            my $row_index = $index + 1;
            my $col_index = 1;
            my @selected  = $q->param("add_work_request.$id.$index.selected");
            if (@selected) {    # this row is selected
                my @values = $q->param("E_$col_index\_$row_index");
                unless ( scalar(@values) > 0 && grep /./, @values ) {
                    @values = $q->param("E_$col_index\_$row_index Choice");
                }
                if (@values) {
                    $dup_ids{$id}{$index} = int(@values);
                }
            }
        }
    }

    my $col = 1;                ## column index is dependent on order of fields in list (order of fields should be same as the way they are ordered in HTML table)
    for my $field_id (@field_ids) {
        my @field_values;
        foreach my $id ( keys %dup_ids ) {
            foreach my $index ( keys %{ $dup_ids{$id} } ) {
                my $row = $index + 1;
                for ( my $i = 0; $i < $dup_ids{$id}{$index}; $i++ ) {
                    my @values = $q->param("E_$col\_$row");
                    unless ( scalar(@values) > 0 && grep /./, @values ) {
                        @values = $q->param("E_$col\_$row Choice");
                    }
                    push @field_values, @values[$i];
                }
                $row++;
            }
        }
        if ( scalar(@field_values) > 0 ) {
            my ($field_name) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE DBField_ID =$field_id" );
            @{ $values{$field_name} } = @field_values;
        }
        $col++;
    }

    my %wr_data;
    my $index = 1;
    foreach my $id ( keys %dup_ids ) {
        foreach my $i ( keys %{ $dup_ids{$id} } ) {
            for ( my $j = 0; $j < $dup_ids{$id}{$i}; $j++ ) {
                my $goal_id;
                $goal_id = $dbc->get_FK_ID( -field => 'FK_Goal__ID', -value => @{ $values{FK_Goal__ID} }[ $index - 1 ] ) if ( $values{FK_Goal__ID}->[ $index - 1 ] );
                my $wr_type_id;
                $wr_type_id = $dbc->get_FK_ID( -field => 'FK_Work_Request_Type__ID', -value => @{ $values{FK_Work_Request_Type__ID} }[ $index - 1 ] ) if ( $values{FK_Work_Request_Type__ID}->[ $index - 1 ] );
                my $funding_id;
                $funding_id = $dbc->get_FK_ID( -field => 'FK_Funding__ID', -value => @{ $values{FK_Funding__ID} }[ $index - 1 ] ) if ( $values{FK_Funding__ID}->[ $index - 1 ] );
                my $goal_target_type = $values{Goal_Target_Type}->[ $index - 1 ];

                $wr_data{$index} = [ '', $id, $goal_id, @{ $values{Goal_Target} }[ $index - 1 ], $wr_type_id, $goal_target_type, $funding_id, @{ $values{Comments} }[ $index - 1 ], date_time(), $dbc->get_local('user_id'), $class ];
                $index++;
            }
        }
    }

    my @wr_fields = ( 'Work_Request_ID', "$key", 'FK_Goal__ID', 'Goal_Target', 'FK_Work_Request_Type__ID', 'Goal_Target_Type', 'FK_Funding__ID', 'Comments', 'Work_Request_Created', 'FKRequest_Employee__ID', 'Scope' );

    my $wr_ids = $dbc->SDB::DBIO::smart_append(
        -tables    => 'Work_Request',
        -fields    => \@wr_fields,
        -values    => \%wr_data,
        -autoquote => 1,
    );

    my $wrs = $$wr_ids{'Work_Request'};
    my $wr_list = Cast_List( -list => $$wrs{'newids'}, -to => 'string', -autoquote => 0 );

    if ($wr_list) {
        $dbc->message("Work Request $wr_list created");
    }

    #$dbc->{session}->homepage("Source=$id_list");

    return;

}

############################
sub update_Funding {
############################
    my $self    = shift;
    my $q       = $self->query();
    my $dbc     = $self->param('dbc');
    my $model   = $self->param('Model');
    my $wr_id   = $q->param('work_request_id');
    my $funding = $q->param('FK_Funding__ID Choice') || $q->param('FK_Funding__ID');

    my $funding_id = $dbc->get_FK_ID( "FK_Funding__ID", $funding );

    my $ok = $dbc->Table_update_array( 'Work_Request', ['FK_Funding__ID'], [$funding_id], "where Work_Request_ID = $wr_id" );

    my $db_object         = $model->get_db_object( -dbc     => $dbc, -id => $wr_id );
    my $work_requests_ref = $model->get_other_WR_ids( -dbc  => $dbc, -id => $wr_id );
    my $WR_plates         = $model->get_WR_plate_ids( -dbc  => $dbc, -id => $wr_id );
    my $lib_plates        = $model->get_Lib_plate_ids( -dbc => $dbc, -id => $wr_id );

    return alDente::Work_Request_Views::display_home_page(
        -model          => $self->param('Model'),
        -id             => $wr_id,
        -dbc            => $dbc,
        -DB_obj         => $db_object,
        -WR_ids         => $work_requests_ref,
        -library_plates => $lib_plates,
        -WR_plates      => $WR_plates
    );
}

############################
sub new_custom_work_request {
############################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');
    my $lib  = $q->param('WR_library');

    my %grey;
    my %hidden;
    $grey{FK_Library__Name} = $lib;
    $grey{Goal_Target_Type} = ['Included in Original Target'];
    my @goal = $dbc->get_FK_info( -field => 'FK_Goal__ID', -condition => "WHERE Goal_Name = 'Custom Goal'", -list => 1 );
    $grey{FK_Goal__ID} = \@goal;
    $grey{Goal_Target} = 1;
    my @type = $dbc->get_FK_info( -field => 'FK_Work_Request_Type__ID', -condition => "WHERE Work_Request_Type_Name = 'Custom Type'", -list => 1 );
    $grey{FK_Work_Request_Type__ID} = \@type;

    $hidden{'Num_Plates_Submitted'} = '';
    $hidden{'FK_Plate_Format__ID'}  = '';

    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Work_Request', -target => 'Database', -grey => \%grey );
    $table->configure(
        -grey   => \%grey,
        -hidden => \%hidden
    );

    return $table->generate( -navigator_on => 1, -return_html => 1 );

}

############################
sub protocol_page {
############################
    my $self    = shift;
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $funding = $self->param('Model');
    my $id_list = $self->param('plate_ids') || $q->param('plate_ids');

    my $Prep = alDente::Plate_Prep->new( -dbc => $dbc, -user => $dbc->get_local('user_id') );

    return $Prep->get_Prep_history( -plate_ids => $id_list, -view => 1 );
}

############################
# Get Plate_ID(s) which need to change work request from the Change_Plate_Work_Request View
############################
sub change_plate_work_request {
############################
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $q            = $self->query;
    my $dbc          = $self->param('dbc');
    my @id           = $q->param('Mark');
    my $funding_name = $q->param('funding Choice');    # use 'funding Choice' instead of 'funding' since search_list have the filter/search box
    my $goal_name    = $q->param('goal');
    my $debug        = $args{-debug};

    $dbc->warning("In change_plate_work_request()") if $debug;
    Message("In change_plate_work_request()")       if $debug;

    my $funding_id = $dbc->get_FK_ID( -field => "FK_Funding__ID", -value => $funding_name );
    my $goal_id    = $dbc->get_FK_ID( -field => "FK_Goal__ID",    -value => $goal_name );
    my $funding_condition = " AND FK_Funding__ID = $funding_id";
    my $goal_condition    = " AND FK_Goal__ID = $goal_id";

    my $extra_condition = $funding_condition if $funding_id;
    $extra_condition .= $goal_condition if $goal_id;

    #Message("extra_condition = $extra_condition") if $debug;

    my $count = 0;
    $count = scalar(@id) if @id;
    if ( $count < 1 ) {
        $dbc->warning("No Plate_ID specified.");
        return;
    }
    return alDente::Work_Request_Views::display_change_plate_work_request( -dbc => $dbc, -ids => \@id, -extra_condition => $extra_condition );
}

############################
# check if all the required fields are filled and non conflicts been found before actually save the changes
############################
sub confirm_work_request_change {
############################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $dbc        = $args{-dbc} || $self->param('dbc');
    my $debug      = $args{-debug};
    my $q          = $self->query;
    my $valid_list = $q->param('valid_plate_list');
    require alDente::Container;

    $dbc->warning("In confirm_work_request_change()")                     if $debug;
    Message("In confirm_work_request_change()")                           if $debug;
    Message("Plate ID(s) that need to change Work Request = $valid_list") if $debug;

    my @valid_plate_list = Cast_List( -list => $valid_list, -to => 'Array' );
    my ( @plate_wr, @plate_opt, @current_children_plate_list, @not_ok_to_change_plate_list, @invoiced_iw_change_funding_plate_list );
    my ( $current_plate_id, $current_plate_wr, $current_plate_opt, $current_plate_wr_id, $current_plate_name, $conflict_plate_name );
    my ( $err_msg, $conflict_err_msg );
    my $err_count = 0;

    # make sure all the fields have valid values(not just '' or blank)
    foreach my $valid_plate_id (@valid_plate_list) {
        $current_plate_wr  = $q->param("wr.$valid_plate_id");
        $current_plate_opt = $q->param("opt.$valid_plate_id");

        ##########################################
        # check if the selected plate has Invoiceable_Work and change funding (both invoiced and not invoiced)
        my @plate_iw_list;

        if ( $current_plate_opt eq "This Plate/Container only" ) {
            @plate_iw_list = $dbc->Table_find_array( 'Invoiceable_Work', ['Invoiceable_Work_ID'], "WHERE FK_Plate__ID = $valid_plate_id", -distinct => 1 );
        }
        elsif ( $current_plate_opt eq "This Plate/Container and children Plates" ) {
            my $current_children_plate_list_str = alDente::Container::get_Children( -dbc => $dbc, -id => $valid_plate_id, -format => 'list', -include_self => 1 );
            @plate_iw_list = $dbc->Table_find_array( 'Invoiceable_Work', ['Invoiceable_Work_ID'], "WHERE FK_Plate__ID in ($current_children_plate_list_str)", -distinct => 1 );
        }

        my $current_target_wr_funding;
        if ( $current_plate_wr != "''" ) {
            my $current_target_plate_wr_id = substr( $current_plate_wr, 0, index( $current_plate_wr, ':' ) );    # get Work_Request_ID for each work request (eg. 31544: ASPFL-112 => 31544)
            ($current_target_wr_funding) = $dbc->Table_find_array( 'Work_Request', ['FK_Funding__ID'], "WHERE Work_Request_ID = $current_target_plate_wr_id", -distinct => 1 );
        }

        foreach my $iw_id (@plate_iw_list) {
            my @current_iw_funding = $dbc->Table_find_array(
                'Invoiceable_Work AS IW, Invoiceable_Work_Reference AS IWR',
                ['IWR.FKApplicable_Funding__ID'],
                "WHERE IWR.FKReferenced_Invoiceable_Work__ID = IW.Invoiceable_Work_ID AND Invoiceable_Work_ID = $iw_id",
                -distinct => 1
            );

            if ( ( scalar(@current_iw_funding) == 1 && ( $current_iw_funding[0] ) != $current_target_wr_funding ) || scalar(@current_iw_funding) > 1 ) {    # when a Invoiceable_Work have more than one funding, need to work on this case in the future
                push @invoiced_iw_change_funding_plate_list, $valid_plate_id;
                last;
            }
        }
        ##########################################

        if ( ( $current_plate_wr eq "''" ) || ( $current_plate_opt eq "''" ) ) {
            $current_plate_name = alDente::Container::get_plate_name( -dbc => $dbc, -id => $valid_plate_id );

            #$err_msg .= "pla$valid_plate_id, ";
            $err_msg .= "pla$valid_plate_id: $current_plate_name, ";
            $err_count++;
        }
        else {
            push @plate_wr,  $current_plate_wr;
            push @plate_opt, $current_plate_opt;
        }
    }

    if ( $err_count > 0 ) {

        # Message("Some mandatory fields are still missing for the following Plate(s): $err_msg please go back and fill all the required information.");
        $dbc->warning("Some mandatory fields are still missing for the following Plate(s): $err_msg please go back and fill all the required information.");

        return;
    }
    else {    # all the mandatory fields have been filled, OK to check the conflict
        my $index = 0;
        foreach my $current_plate_id (@valid_plate_list) {

            $current_plate_wr    = @plate_wr[$index];
            $current_plate_opt   = @plate_opt[$index];
            $current_plate_wr_id = substr( $current_plate_wr, 0, index( $current_plate_wr, ':' ) );    # get Work_Request_ID for each work request (eg. 31544: ASPFL-112 => 31544)
            $index++;

            Message("******************** Separate Each Plate_ID ********************") if $debug;
            Message("current_plate_id = $current_plate_id")                             if $debug;

            if ( $current_plate_opt eq "This Plate/Container and children Plates" ) {                  # need to make sure this parent's work request won't conflict with its children plate's work request

                my $current_children_plate_list_str = alDente::Container::get_Children( -dbc => $dbc, -id => $current_plate_id, -format => 'list', -include_self => 0 );
                my @current_children_plate_list = Cast_List( -list => $current_children_plate_list_str, -to => 'Array' ) if $current_children_plate_list_str;

                foreach my $current_children_plate_id (@current_children_plate_list) {
                    foreach my $pid (@valid_plate_list) {
                        if ( $pid == $current_children_plate_id ) {                                    # check if the current children plate is one of the selected plate that user want to change WR

                            my $current_parent_plate_target_wr = $q->param("wr.$current_plate_id");
                            my $current_child_plate_target_wr  = $q->param("wr.$current_children_plate_id");

                            if ( !( $current_parent_plate_target_wr eq $current_child_plate_target_wr ) ) {    # check if the parent plate has different target WR than its children

                                Message("********** Conflicting Parent-Child Target WR Found! **********")     if $debug;
                                Message("current_parent_plate_id = $current_plate_id")                         if $debug;
                                Message("current_children_plate_id = $current_children_plate_id")              if $debug;
                                Message("current_parent_plate_target_wr_id = $current_parent_plate_target_wr") if $debug;
                                Message("current_child_plate_target_wr_id = $current_child_plate_target_wr")   if $debug;
                                push @not_ok_to_change_plate_list, $pid;
                                push @not_ok_to_change_plate_list, $current_plate_id;                          # parent and children plate's WR and option are conflicting each other, add parent Plate_ID to the conflicting list
                            }
                            last;
                        }
                    }
                }
            }
        }
        my %seen;
        my @unique_not_ok_to_change_plate_list = grep { !$seen{$_}++ } @not_ok_to_change_plate_list;           # delete duplicate parent plates

        if (@unique_not_ok_to_change_plate_list) {                                                             # There is at least one conflict been found, warnning the user and stop the process until user fix all the conflicts
            foreach my $not_ok_to_change_plate_id (@unique_not_ok_to_change_plate_list) {
                $conflict_plate_name = alDente::Container::get_plate_name( -dbc => $dbc, -id => $not_ok_to_change_plate_id );
                $conflict_err_msg .= "pla$not_ok_to_change_plate_id: $conflict_plate_name, ";
            }

            # Message("*** Target Work Request for the following Plate(s) are conflicting with their children/parent Plate(s)'s target Work Request: $conflict_err_msg please go back and resolve the conflict manually ***");
            $dbc->warning("*** Target Work Request for the following Plate(s) are conflicting with their children/parent Plate(s)'s target Work Request: $conflict_err_msg please go back and resolve the conflict manually ***");
            return;
        }
        else {                                                                                                 # no conflict has been found ,ok to change WR for all Plate(s)
            Message("*** No conflict has been found, OK to change Work Request for all selected Plate(s) ***");

            # **** keep working on this, check if IW.Funding will be effect on any invoiced IW, warn them first
            my $change_invoiced_iw_funding_flag = 0;
            $change_invoiced_iw_funding_flag = 1 if @invoiced_iw_change_funding_plate_list;
            Message("change_invoiced_iw_funding_flag = $change_invoiced_iw_funding_flag") if $debug;

            if ( $change_invoiced_iw_funding_flag == 1 ) {

                my $invoiced_iw_change_funding_plate_list_str = Cast_List( -list => \@invoiced_iw_change_funding_plate_list, -to => 'string' );
                $dbc->warning("Change Work Request for the following Plate(s): $invoiced_iw_change_funding_plate_list_str, may lead to change their related Invoiceable Work funding. Do you still want to apply the changes?");
                return alDente::Work_Request_Views::check_iw_funding_change_btn( $dbc, -ids => \@valid_plate_list, -plate_wr => \@plate_wr, -plate_opt => \@plate_opt );
            }
            else {
                return alDente::Work_Request::save_work_request_change( -dbc => $dbc, -ids => \@valid_plate_list, -plate_wr => \@plate_wr, -plate_opt => \@plate_opt );    # update the database
            }
        }
    }
    return;
}

############################
# user want to apply change regardless of the effect of change funding
# for invoiced Invoiceable_Work_Reference.FKApplicable_Funding__ID records
############################
sub confirm_change_with_iw_funding_change {
############################
    my $self               = shift;
    my %args               = &filter_input( \@_ );
    my $dbc                = $args{-dbc} || $self->param('dbc');
    my $debug              = $args{-debug};
    my $q                  = $self->query;
    my $valid_list         = $q->param('valid_plate_list');
    my $plate_wr_list_str  = $q->param('plate_wr_list');
    my $plate_opt_list_str = $q->param('plate_opt_list');

    $dbc->warning("In confirm_change_with_iw_funding_change()")           if $debug;
    Message("In confirm_change_with_iw_funding_change()")                 if $debug;
    Message("Plate ID(s) that need to change Work Request = $valid_list") if $debug;
    Message("plate_wr_list_str = $plate_wr_list_str")                     if $debug;
    Message("plate_opt_list_str = $plate_opt_list_str")                   if $debug;

    my @valid_plate_list = Cast_List( -list => $valid_list,         -to => 'Array' );
    my @plate_wr         = Cast_List( -list => $plate_wr_list_str,  -to => 'Array' );
    my @plate_opt        = Cast_List( -list => $plate_opt_list_str, -to => 'Array' );

    return alDente::Work_Request::save_work_request_change( -dbc => $dbc, -ids => \@valid_plate_list, -plate_wr => \@plate_wr, -plate_opt => \@plate_opt );    # update the database
}

return 1;
