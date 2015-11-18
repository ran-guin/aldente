################################################################################
#
# Work Request.pm
#
# By Ash Shafiei, October 2008
################################################################################
package alDente::Work_Request;
##############################
# standard_modules_ref       #
##############################

#@ISA = qw(SDB::DB_Object);
use base SDB::DB_Object;
use Carp;
use strict;

##############################
# custom_modules_ref         #
##############################
use alDente::Form;
use alDente::SDB_Defaults;
use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::RGmath;
use SDB::HTML;

use alDente::Goal;
use alDente::Tools;

use RGTools::Views;
use RGTools::Conversion;
##############################
# global_vars                #
##############################
use vars qw( %Configs  $Security);
######################################################
##          Public Methods                          ##
######################################################

##############################
# constructor                #
##############################
#########
sub new {
#########
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args   = @_;
    my $id     = $args{-id};
    my $dbc    = $args{-dbc};      #|| $Connection->dbh(); # Database handle
    my $tables = $args{-tables};

    unless ($tables) { $tables = [ 'Funding', 'Goal' ] }

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables );

    bless $self, $class;

    $self->{id}  = $id;
    $self->{dbc} = $dbc;
    return $self;
}
######################################################
##          Public Methods                          ##
######################################################

###################################
sub new_work_request_trigger {
###################################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $id    = $self->{id} || $args{-id};
    my $dbc   = $self->{dbc};
    my $quiet = $dbc->{quiet};

    #    $self->load_Object(-quick_load=>1, -force=>1);

    my $wr_list = Cast_List( -list => $id, -to => 'string', -autoquote => 0 );
    my @work_requests = Cast_List( -list => $id, -to => 'array' );

    my %ticket_funding_info = $dbc->Table_retrieve(
        'Work_Request,Goal,Funding',
        [ 'Work_Request_ID', 'FK_Funding__ID', 'Funding_Name', 'Goal_Name' ],
        "WHERE FK_Funding__ID=Funding_ID AND FK_Goal__ID=Goal_ID AND Work_Request_ID in ($wr_list) AND Goal_Type Like 'Custom Data Analysis'",
        -key => 'Work_Request_ID'
    );

    foreach my $wr (@work_requests) {
        unless ( exists $ticket_funding_info{$wr} ) {
            my %funding_info = $dbc->Table_retrieve(
                'Work_Request,Goal,Funding',
                [ 'Work_Request_ID', 'FK_Funding__ID', 'Funding_Name', 'Goal_Name' ],
                "WHERE FK_Funding__ID=Funding_ID AND FK_Goal__ID=Goal_ID AND Work_Request_ID = $wr AND Goal_Type Like 'Custom Data Analysis'",
                -key => 'Work_Request_ID'
            );
            if ( keys %funding_info ) {
                $ticket_funding_info{$wr} = $funding_info{$wr};
                $dbc->Table_update_array( 'Work_Request', ['Scope'], ['Library'], "WHERE Work_Request_ID = '$wr' AND Scope IS NULL", -autoquote => 1 );
            }
        }
    }
    my %ticket_comments;
    my $jira = setup_jira();
    foreach my $wr (@work_requests) {
        if ( $ticket_funding_info{$wr} ) {
            my $funding_id   = $ticket_funding_info{$wr}{FK_Funding__ID}[0];
            my $funding_name = $ticket_funding_info{$wr}{Funding_Name}[0];
            my $goal_name    = $ticket_funding_info{$wr}{Goal_Name}[0];

            my @existing_tickets = $dbc->Table_find( 'Work_Request,Funding,Jira', 'Jira_Code', "WHERE FK_Jira__ID=Jira_ID AND FK_Funding__ID = Funding_ID AND Funding_ID = '$funding_id'", -distinct => 1 );
            if (@existing_tickets) {
                ## ok - SOW already has a tracked ticket ##
                my $WR_details = $dbc->Table_retrieve_display( 'Work_Request,Goal', [ 'Work_Request_Title', 'Goal_Name', 'Work_Request.Comments' ], "WHERE FK_Goal__ID=Goal_ID AND Work_Request_ID = '$wr'", -return_html => 1 );
                my $comment = html_to_wiki($WR_details);
                foreach my $jira_ticket (@existing_tickets) {
                    $ticket_comments{$jira_ticket} .= $comment;
                }
                my ($jira_id) = $dbc->Table_find( 'Jira', 'Jira_ID', "WHERE Jira_Code = '$existing_tickets[0]'" );    ## assume only one Jira Ticket per Funding source for now....
                $dbc->Table_update_array( 'Work_Request', ['FK_Jira__ID'], [$jira_id], "WHERE Work_Request_ID = '$wr' AND FK_Jira__ID IS NULL", -autoquote => 1 );
            }
            else {
                my $task_id  = 3;
                my $assignee = 'yma';

                my $funding_details = $dbc->Table_retrieve_display(
                    'Work_Request,Goal,Funding',
                    [ 'Work_Request_Title', 'Goal_Name', 'Funding_Code', 'Funding_Name', 'Funding_Description', 'Funding_Status', 'Work_Request.Comments' ],
                    "WHERE FK_Funding__ID=Funding_ID AND FK_Goal__ID=Goal_ID AND Work_Request_ID = '$wr'",
                    -return_html => 1
                );
                my $comment = html_to_wiki($funding_details);

                my $link = "[Link to LIMS Page|$Configs{URL_domain}/$Configs{URL_address}/barcode.pl?HomePage=Funding&ID=$funding_id]";
                $comment .= "\n$link";    ## Add link to LIMS home page in ticket description ##

                my $issue = {
                    'project'     => 'SOW',
                    'type'        => $task_id,
                    'summary'     => "New Work Request for $funding_name ($goal_name)",
                    'assignee'    => $assignee,
                    'description' => $comment
                };

                my $ticket_id = $jira->create_issue( -issue_details => $issue );
                my $jira_code = $ticket_id->{key};

                if ($ticket_id) {
                    my $jira_id = $dbc->Table_append_array( 'Jira', ['Jira_Code'], [$jira_code], -autoquote => 1 );
                    $dbc->Table_update_array( 'Work_Request', ['FK_Jira__ID'], [$jira_id], "WHERE Work_Request_ID = '$wr'", -autoquote => 1 );

                    my $link = Jira::get_link( -issue_id => $jira_code );
                    Message("Added JIRA Ticket $jira_code: $link") unless ($quiet);

                    my $ok = alDente::Subscription::send_notification(
                        -dbc          => $dbc,
                        -name         => "New Jira Ticket for SOW",
                        -from         => 'aldente@bcgsc.ca',
                        -subject      => "Additional Bioinformatics Analysis requested for $jira_code",
                        -body         => "Go to this ticket and add yourself as a watcher if you would like to keep tabs on its progress:\n$link",
                        -content_type => 'html',
                        -testing      => 0
                    );
                }
                else {
                    Message("Error generating ticket ");
                    print HTML_Dump $issue;
                }
            }
            $dbc->message( "Funding home page: " . alDente_ref( 'Funding', $funding_id, -dbc => $dbc ) ) unless ($quiet);
        }
        else {
            $dbc->message("Work Request $wr No ticketing option") unless ($quiet);
        }
    }

    ## append comments to JIRA tickets
    my $links;
    my @existing_tickets = keys %ticket_comments;
    foreach my $jira_ticket (@existing_tickets) {
        my $link = Jira::get_link( -issue_id => $jira_ticket );
        Message("Appending JIRA Ticket $jira_ticket: $link");
        my $ok = $jira->add_comment( -issue_id => $jira_ticket, -comment => $ticket_comments{$jira_ticket} );
        $links .= "$link; ";
    }
    if (@existing_tickets) {
        my $ok = alDente::Subscription::send_notification(
            -dbc          => $dbc,
            -name         => "New Jira Ticket for SOW",
            -from         => 'aldente@bcgsc.ca',
            -subject      => "Additional Work_Request Added for @existing_tickets",
            -content_type => 'html',
            -body         => "Go to any ticket and add yourself as a watcher if you would like to keep tabs on its progress:\n$links",
            -testing      => 0
        );
    }

    $dbc->message("updating library status if required...") unless ($quiet);
    my $ok = alDente::Goal::set_Library_Status( -dbc => $dbc, -work_request => \@work_requests );

    return;
}

# add a work request to the database
# For now this will add library level work requests. All other work request scope type (Source, SOW) will need to be added via backfill script.
#
# Returns: work request id
######################
sub add_work_request {
######################
    my $self                 = shift;
    my %args                 = filter_input( \@_ );
    my $goal_target          = $args{-goal_target};                                    # the goal target
    my $comments             = $args{-comment};                                        # optional comments
    my $work_request_type    = $args{-work_request_type} || 'Default Work Request';    # optional
    my $funding              = $args{-funding};                                        # mandatory SOW for the work request
    my $library              = $args{-library};                                        # mandatory library
    my $goal_target_type     = $args{-goal_target_type} || 'Original Request';         # optional
    my $goal                 = $args{-goal};                                           # type of goal
    my $debug                = $args{-debug};
    my $dbc                  = $args{-dbc} || $self->{dbc};
    my $work_request_title   = $args{-work_request_title};
    my $jira_id              = $args{-jira_id};
    my $work_request_created = &date_time();
    my $source_id            = $args{-source_id};
    my $request_employee_id  = $args{-request_employee_id};
    my $request_contact_id   = $args{-request_contact_id};

    my ($funding_id)           = $dbc->Table_find( 'Funding',           'Funding_ID',           "WHERE Funding_Code ='$funding'" );
    my ($work_request_type_id) = $dbc->Table_find( 'Work_Request_Type', 'Work_Request_Type_ID', "WHERE Work_Request_Type_Name = '$work_request_type'" );
    my $scope = $args{-scope} || 'Library';

    my ($goal_id) = $dbc->Table_find( 'Goal', 'Goal_ID', "WHERE Goal_Name = '$goal'" );
    unless ( $funding_id && $work_request_type_id && $work_request_type_id ) {
        return 0;
    }
    my @mandatory_fields = ( 'Work_Request.Goal_Target', 'Work_Request.FK_Work_Request_Type__ID', 'Work_Request.FK_Library__Name', 'Work_Request.Goal_Target_Type', 'Work_Request.FK_Funding__ID', 'Work_Request.FK_Goal__ID' );
    my @mandatory_values = ( $goal_target, $work_request_type_id, $library, $goal_target_type, $funding_id, $goal_id );

    if ($scope) {
        push @mandatory_fields, 'Scope';
        push @mandatory_values, $scope;
    }
    if ($work_request_title) {
        push @mandatory_fields, 'Work_Request_Title';
        push @mandatory_values, $work_request_title;
    }
    if ($jira_id) {
        push @mandatory_fields, 'FK_Jira__ID';
        push @mandatory_values, $jira_id;
    }
    if ($work_request_created) {
        push @mandatory_fields, 'Work_Request_Created';
        push @mandatory_values, $work_request_created;
    }
    if ($source_id) {
        push @mandatory_fields, 'FK_Source__ID';
        push @mandatory_values, $source_id;
    }
    if ($request_employee_id) {
        push @mandatory_fields, 'FKRequest_Employee__ID';
        push @mandatory_values, $request_employee_id;
    }
    if ($request_contact_id) {
        push @mandatory_fields, 'FKRequest_Contact__ID';
        push @mandatory_values, $request_contact_id;
    }

    my $index = 0;
    foreach my $field (@mandatory_fields) {
        my $value = $mandatory_values[$index];
        $self->value( $field, $value );
        $index++;
    }
    if ($comments) {
        $self->value( 'Work_Request.Comments', $comments );
    }
    $self->value( 'Work_Request.FKRequest_Employee__ID', $dbc->get_local('user_id') );
    if ($debug) {
        print Dumper $self;
        return $self;
    }
    $self->insert();
    my ($returnval) = @{ $self->newids('Work_Request') };

    return $returnval;

}

############################
sub html_to_wiki {
############################
    my $table = shift;

    $table =~ s/\s+/ /xmsg;    ## convert all linefeeds to simple spaces ...

    while ( $table =~ s/<\/TD.*?>/ | /ixmsg )    { }
    while ( $table =~ s/<\/TH (.*?)>/ | /ixmsg ) { }

    while ( $table =~ s/<TR (.*?)>/\n| /ixmsg ) { }

    while ( $table =~ s/<.*?>//ixmsg ) { }

    return $table;
}

###################
sub setup_jira {
###################
    my %args = filter_input( \@_ );

    my $user      = 'limsproxy';
    my $password  = 'noyoudont';             ## <CONSTRUCTION> remove hardcoding
    my $jira_wsdl = $Configs{'jira_wsdl'};

    require Plugins::JIRA::Jira;

    my $jira = Jira->new( -user => $user, -password => $password, -uri => $jira_wsdl, -proxy => $jira_wsdl );
    $jira->login();
    return $jira;
}

####################
sub ticket_name {
####################
    my $self = shift;

    my $name = $self->value('Funding.Funding_Name');
    return $name;
}

############################
sub get_other_WR_ids {
############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my @lib_names = $dbc->Table_find(
        -table     => 'Work_Request',
        -fields    => "FK_Library__Name",
        -condition => "WHERE Work_Request_ID = $id"
    );
    my $name   = $lib_names[0];
    my @WR_ids = $dbc->Table_find(
        -table     => 'Work_Request',
        -fields    => "Work_Request_ID",
        -condition => "WHERE FK_Library__Name = '$name'" . " Order by Work_Request_ID DESC"
    );

    return \@WR_ids;
}

############################
sub get_db_object {
############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $db_obj = SDB::DB_Object->new( -dbc => $dbc );
    $db_obj->add_tables('Work_Request');
    $db_obj->{Work_Request_id} = $id;
    $db_obj->primary_value( -table => 'Work_Request', -value => $id );    ## same thing as above..
    $db_obj->load_Object( -type => 'Work_Request' );

    return $db_obj;
}

############################
sub get_WR_plate_ids {
############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};                                                ## Work Request ID

    my @plate_list = $dbc->Table_find(
        -table     => 'Plate',
        -fields    => "Plate_ID",
        -distinct  => 'Distinct',
        -condition => "WHERE FK_Work_Request__ID = $id"
    );

    return \@plate_list;
}

############################
sub get_Lib_plate_ids {
############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};    ## Work Request ID

    my @library = $dbc->Table_find(
        -table     => 'Work_Request',
        -fields    => "FK_Library__Name",
        -condition => "WHERE Work_Request_ID = $id"
    );

    my $lib = $library[0];

    my @plate_list = $dbc->Table_find(
        -table     => 'Plate',
        -fields    => "Plate_ID",
        -distinct  => 'Distinct',
        -condition => "WHERE FK_Library__Name = '$lib' "
    );
    return \@plate_list;
}

#
# Get Associated Work Requests
#
# Return: array reference to list of Work Requests tied to a Library, Funding source, Project etc
############################
sub get_WR_ids {
############################
    my $self         = shift;
    my %args         = @_;
    my $dbc          = $args{-dbc};
    my $lib          = $args{-library};
    my $funding      = $args{-funding};
    my $project_name = $args{-project};
    my $plate_format = $args{-plate_format};
    my $type         = $args{-type};
    my $table        = 'Work_Request';
    my @id_list;

    if ( !$lib && !$funding && !$project_name && !$plate_format && !$type ) {
        Message('No Search Criteria Entered. Please Enter some search options');
        return \@id_list;
    }

    my $plate_format_id = $dbc->get_FK_ID( -field => 'Plate_Format_ID',      -value => $plate_format ) if $plate_format;
    my $type_id         = $dbc->get_FK_ID( -field => 'Work_Request_Type_ID', -value => $type )         if $type;
    my $funding_id      = $dbc->get_FK_ID( -field => 'Funding_ID',           -value => $funding )      if $funding;
    my $project_id      = $dbc->get_FK_ID( -field => 'Project_ID',           -value => $project_name ) if $project_name;

    ## Building The Search Condition
    my $search_condition = "WHERE 1  ";
    if ($plate_format_id) {
        $search_condition .= " AND Work_Request.FK_Plate_Format__ID = $plate_format_id ";
    }
    if ($lib) {
        $search_condition .= " AND Work_Request.FK_Library__Name = '$lib' ";
    }
    if ($type_id) {
        $search_condition .= " AND Work_Request.FK_Work_Request_Type__ID = $type_id ";
    }
    if ($funding_id) {
        $search_condition .= " AND Work_Request.FK_Funding__ID = $funding_id ";
    }
    if ($project_id) {
        $search_condition .= " AND FK_Project__ID = $project_id ";
        $table            .= ' ,Library';
        $search_condition .= " AND FK_Library__Name = Library_Name ";
    }

    $search_condition .= " AND Scope = 'Library' ";

    @id_list = $dbc->Table_find(
        -table     => $table,
        -fields    => "Work_Request_ID",
        -condition => "$search_condition " . " Order BY FK_Library__Name ",
        -distinct  => "distinct"
    );
    return \@id_list;

}

#######################
# Sets value of Goal_Target in WR to enable auto-determination of status
#
# (normally for these types of goals, the count should be set to zero)
#
# (setting goal_target to 0 indicates target is met (count >= target)
# (setting goal_target to 1 indicates target is NOT met (count < target)
#
# Return: number of records changed
########################
sub reset_custom_WR {
########################
    my %args   = filter_input( \@_, -args => 'dbc,id,set', -mandatory => 'dbc,id,set' );
    my $dbc    = $args{-dbc};
    my $wr_ids = $args{-id};
    my $set    = $args{-set};

    my $new_value;
    if   ( $set =~ /open/i ) { $new_value = '1' }    ## set target to one if re-opening requets
    else                     { $new_value = '0' }    ## set target to zero to close request

    my $ids = Cast_List( -list => $wr_ids, -to => 'string' );

    my $change = join ',', $dbc->Table_find( 'Work_Request,Goal', 'Work_Request_ID', "WHERE FK_Goal__ID=Goal_ID AND Work_Request_ID IN ($ids) AND Goal_Type = 'Custom Data Analysis'", -distinct => 1 );

    if ($change) {
        my $ok = $dbc->Table_update( 'Work_Request', 'Goal_Target', $new_value, "WHERE Work_Request_ID IN ($change) AND Goal_Target != '$new_value'" );
        if ($ok) { Message("WR $change goal target reset to $new_value (0 = closed; 1 = open)") }
    }
    return $change;
}

######################################################
##          Private Functions                       ##
######################################################

#
# Is this method needed ? - it is not called... or is it somehow called dynamically ?..
#
###########################
sub _return_value {
##########################
    my %args         = &filter_input( \@_ );
    my $fields_ref   = $args{-fields};
    my $values_ref   = $args{ -values };
    my $target       = $args{-target};
    my $index_return = $args{-index_return};

    my $value;
    my @fields = @$fields_ref if $fields_ref;
    my @values = @$values_ref if $values_ref;
    my $counter = 0;

    foreach my $field_name (@fields) {
        if ( $field_name eq $target ) {
            if ($index_return) {
                return $counter;
            }
            else {
                return $values[$counter];
            }
        }
        $counter++;
    }
    return;
}

###########################
#
# This will backfill all of the source and SOW level work requests
# Will skip if there is an existing work_request at that level
#
#
###########################
sub backfill_work_request {
###########################
    my $self           = shift;
    my %args           = @_;
    my $dbc            = $args{-dbc};
    my $debug          = $args{-debug};
    my $sow            = $args{-sow};     ## a given list of already comma SOW ids
    my $added_src      = 0;
    my $added_sow      = 0;
    my $sign           = '';              ## This is for changing the relationship word within the mysql command (can be either an '=' or 'IS')
    my $goal_sign      = '';              ## This is for changing the relationship word within the mysql command (can be either an '=' or 'IS')
    my $title          = 0;
    my $condition      = '';
    my $goal_condition = '';
    my $sow_condition  = '';

    if ($sow) {
        $sow_condition = " AND FK_Funding__ID IN ($sow) ";
    }

    ## This part of the backfill will first fill the Source level work requests
    my @work_request_src = $dbc->Table_find_array(
        'Work_Request',
        [   'FK_Goal__ID', 'SUM(CASE WHEN Goal_Target IS NOT NULL THEN Goal_Target ELSE 0 END)',
            '0', 'FK_Plate_Format__ID', 'FK_Work_Request_Type__ID', 'FK_Funding__ID', 'FK_Jira__ID', 'MIN(Work_Request_Created)', 'FK_Source__ID', 'Percent_Complete', 'FKRequest_Employee__ID', 'FKRequest_Contact__ID'
        ],
        "WHERE Goal_Target_Type = 'Original Request' AND Scope = 'Library' $sow_condition GROUP BY FK_Source__ID, FK_Goal__ID, FK_Funding__ID, FK_Work_Request_Type__ID"
    );

    print Message( "Found " . int(@work_request_src) . " Work Requests on the source level to fill." );

    foreach my $wr_src (@work_request_src) {
        my ( $goal, $goal_target, $plates_submitted, $plate_format, $work_Request_type, $funding, $jira, $date, $source, $percentage, $employee, $contact ) = split ',', $wr_src;

        if ($funding) { $sign = ' = '; }
        else {
            $sign      = ' IS ';
            $funding   = 'NULL';
            $condition = " OR FK_Funding__ID = 0";
        }

        if ($goal) { $goal_sign = ' = '; }
        else {
            $goal_sign      = ' IS ';
            $goal           = 'NULL';
            $goal_condition = " OR FK_Funding__ID = 0";
        }

        if ( !$jira ) { $jira = 'NULL'; }

        my ($exists_src)
            = $dbc->Table_find( 'Work_Request', 'Work_Request_ID',
            "WHERE Scope = 'Source' AND FK_Source__ID = $source AND (FK_Goal__ID $goal_sign $goal $goal_condition ) AND (FK_Funding__ID $sign $funding $condition) AND FK_Work_Request_Type__ID = $work_Request_type" );

        if ($exists_src) {
            if ($debug) {
                print Message("Work_Request $exists_src has same parameters already");
                HTML_Dump $wr_src;
            }
            next;
        }

        ## Because there are commas which are allowed in the title this needs to be sperate
        ($title) = $dbc->Table_find( 'Work_Request', 'Work_Request_Title', "WHERE Scope = 'Library' AND FK_Source__ID = $source AND FK_Goal__ID = $goal AND (FK_Funding__ID $sign $funding $condition) AND FK_Work_Request_Type__ID = $work_Request_type" );

        $dbc->Table_append_array(
            'Work_Request',
            [   'FK_Goal__ID', 'Goal_Target',          'Num_Plates_Submitted', 'FK_Plate_Format__ID', 'FK_Work_Request_Type__ID', 'Goal_Target_Type',      'FK_Funding__ID', 'Work_Request_Title',
                'FK_Jira__ID', 'Work_Request_Created', 'FK_Source__ID',        'Percent_Complete',    'FKRequest_Employee__ID',   'FKRequest_Contact__ID', 'Scope'
            ],
            [ "$goal", "$goal_target", "$plates_submitted", "$plate_format", "$work_Request_type", 'Original Request', "$funding", "$title", "$jira", "$date", "$source", "$percentage", "$employee", "$contact", 'Source' ],
            -autoquote => 1
        );

        $added_src++;
    }

    ## This part of the backfill will do the second part which is the SOW level of work request
    my @work_request_sow = $dbc->Table_find_array(
        'Work_Request',
        [   'FK_Goal__ID', 'SUM(CASE WHEN Goal_Target IS NOT NULL THEN Goal_Target ELSE 0 END)',
            '0', 'FK_Plate_Format__ID', 'FK_Work_Request_Type__ID', 'FK_Funding__ID', 'FK_Jira__ID', 'MIN(Work_Request_Created)', 'Percent_Complete', 'FKRequest_Employee__ID', 'FKRequest_Contact__ID'
        ],
        "WHERE Goal_Target_Type = 'Original Request' AND Scope = 'Source' $sow_condition GROUP BY FK_Goal__ID, FK_Funding__ID, FK_Work_Request_Type__ID"
    );

    print Message( "Found " . int(@work_request_sow) . " Work Requests on the SOW level to fill." );

    foreach my $wr_sow (@work_request_sow) {
        my ( $goal, $goal_target, $plates_submitted, $plate_format, $work_Request_type, $funding, $jira, $date, $percentage, $employee, $contact ) = split ',', $wr_sow;

        if ($funding) { $sign = ' = '; }
        else {
            $sign      = ' IS ';
            $funding   = 'NULL';
            $condition = " OR FK_Funding__ID = 0";
        }

        if ($goal) { $goal_sign = ' = '; }
        else {
            $goal_sign      = ' IS ';
            $goal           = 'NULL';
            $goal_condition = " OR FK_Funding__ID = 0";
        }

        my ($exists_sow) = $dbc->Table_find( 'Work_Request', 'Work_Request_ID', "WHERE Scope = 'SOW' AND (FK_Goal__ID $goal_sign $goal $goal_condition ) AND (FK_Funding__ID $sign $funding $condition) AND FK_Work_Request_Type__ID = $work_Request_type" );

        if ($exists_sow) {
            if ($debug) {
                print Message("Work_Request $exists_sow has same parameters already");
                HTML_Dump $wr_sow;
            }
            next;
        }

        ## Because there are commas which are allowed in the title this needs to be sperate
        ($title) = $dbc->Table_find( 'Work_Request', 'Work_Request_Title', "WHERE Scope = 'Library' AND FK_Goal__ID = $goal AND (FK_Funding__ID $sign $funding $condition) AND FK_Work_Request_Type__ID = $work_Request_type" );

        $dbc->Table_append_array(
            'Work_Request',
            [   'FK_Goal__ID', 'Goal_Target',          'Num_Plates_Submitted', 'FK_Plate_Format__ID',    'FK_Work_Request_Type__ID', 'Goal_Target_Type', 'FK_Funding__ID', 'Work_Request_Title',
                'FK_Jira__ID', 'Work_Request_Created', 'Percent_Complete',     'FKRequest_Employee__ID', 'FKRequest_Contact__ID',    'Scope'
            ],
            [ "$goal", "$goal_target", "$plates_submitted", "$plate_format", "$work_Request_type", 'Original Request', "$funding", "$title", "$jira", "$date", "$percentage", "$employee", "$contact", 'SOW' ],
            -autoquote => 1
        );
        $added_sow++

    }

    print Message("There were $added_src src level work request records added.");
    print Message("There were $added_sow sow level work request records added.");

    return;
}

# ###########################
# # old method, been replaced by the new work_request_funding_trigger under it
# # this trigger will be called when Work_Request.FK_Funding__ID been updated
# ###########################
# sub work_request_funding_trigger {
# ###########################
# my $self  = shift;
# my %args  = &filter_input( \@_ );
# my $dbc   = $args{-dbc};
# my $id    = $args{-id};
# my $table = $args{-table};
# my $debug = $args{-debug};

# my $id_string = Cast_List( -list => $id, -to => 'string', -autoquote => 1 );

# $dbc->warning("In work_request_funding_trigger()\n") if $debug;
# Message("In work_request_funding_trigger()")         if $debug;
# print HTML_Dump \%args                               if $debug;

# require SDB::DB_Object;
# my $result = SDB::DB_Object::sync(
# -dbc            => $dbc,
# -fields         => [ 'Invoiceable_Work.FKApplicable_Funding__ID', 'Work_Request.FK_Funding__ID' ],
# -id             => "Work_Request.Work_Request_ID IN ($id_string)",
# -join_condition => "Plate.FK_Work_Request__ID = Work_Request_ID AND Invoiceable_Work.FK_Plate__ID = Plate_ID",
# -add_table      => "Plate"
# );

# return;
# }

###########################
# this trigger will be called when Work_Request.FK_Funding__ID been updated
# (IWR.FKApplicable_Funding__ID instead of IW.FKApplicable_Funding__ID compare to the old method)
###########################
sub work_request_funding_trigger {
###########################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $id    = $args{-id};             # Work_Request_ID
    my $table = $args{-table};
    my $debug = $args{-debug};

    require SDB::DB_Object;
    my $id_string = Cast_List( -list => $id, -to => 'string', -autoquote => 1 );
    my @id_arr = Cast_List( -list => $id_string, -to => 'array' );
    my ( @problem_iw_list, @ok_iw_list, @full_iw_list );

    $dbc->warning("In work_request_funding_trigger()\n") if $debug;
    Message("In work_request_funding_trigger()")         if $debug;
    Message("Updated_Work_Request_ID = $id_string")      if $debug;

    foreach my $wr_id (@id_arr) {
        my @iw_list = $dbc->Table_find_array( 'Invoiceable_Work, Plate', ['Invoiceable_Work_ID'], "WHERE Invoiceable_Work.FK_Plate__ID = Plate_ID AND Plate.FK_Work_Request__ID = $wr_id", -debug => $debug );

        ## If work request is the only one for the library and all of the IW items have the same funding, update all invoiceable work items for that lib
        my ($lib) = $dbc->Table_find( 'Work_Request', 'FK_Library__Name', "WHERE Work_Request_ID = $wr_id", -distinct => 1 );
        my @wr_from_lib = $dbc->Table_find( 'Work_Request', 'Work_Request_ID', "WHERE FK_Library__Name = '$lib'", -distinct => 1 );
        my @funding_from_iwr = $dbc->Table_find(
            'Invoiceable_Work_Reference, Invoiceable_Work, Plate',
            'Invoiceable_Work_Reference.FKApplicable_Funding__ID',
            "WHERE FKReferenced_Invoiceable_Work__ID = Invoiceable_Work_ID AND FK_Plate__ID = Plate_ID AND FK_Library__Name = '$lib'",
            -distinct => 1
        );

        if ( ( int(@wr_from_lib) == 1 ) && ( int(@funding_from_iwr) == 1 ) ) {    ## one work request for library and all invoiceable work items have the same funding
            my @all_iw_from_lib = $dbc->Table_find( 'Invoiceable_Work, Plate', 'Invoiceable_Work_ID', "WHERE FK_Plate__ID = Plate_ID AND FK_Library__Name = '$lib'", -distinct => 1 );
            push @full_iw_list, @all_iw_from_lib;
        }
        elsif (@iw_list) {
            push @full_iw_list, @iw_list;

            foreach my $iw_id (@iw_list) {
                my @current_iwr_funding = $dbc->Table_find_array(
                    'Invoiceable_Work_Reference, Invoiceable_Work',
                    ['Invoiceable_Work_Reference.FKApplicable_Funding__ID'],
                    "WHERE Invoiceable_Work_ID = FKReferenced_Invoiceable_Work__ID AND Invoiceable_Work_ID = $iw_id",
                    -debug => $debug
                );

                my %seen;
                my @unique_current_iwr_funding = grep { !$seen{$_}++ } @current_iwr_funding;    # delete duplicate values in arrary
                @unique_current_iwr_funding = grep { $_ && !m/^\s+$/ } @unique_current_iwr_funding;    # delete undef values in arrary

                my $num = scalar(@unique_current_iwr_funding) if $debug;
                Message("number of unique_current_iwr_funding = $num") if $debug;

                if ( scalar(@unique_current_iwr_funding) > 1 ) {                                       # if a iw has more than 1 funding, system doesn't know how to react
                    push @problem_iw_list, $iw_id;
                }
            }
        }
        else {                                                                                         # a plate not associate with a wr yet, but the plate may has iw
            my ($wr_library) = $dbc->Table_find_array( 'Work_Request', ['FK_Library__Name'], "WHERE Work_Request_ID = $wr_id", -debug => $debug );
            my @valid_funding_list;
            @valid_funding_list = $dbc->Table_find_array( 'Work_Request', ['FK_Funding__ID'], "WHERE Work_Request.FK_Library__Name = '$wr_library'", -autoquote => 1, -debug => $debug ) if $wr_library;
            my %seen;
            my @unique_valid_funding_list = grep { !$seen{$_}++ } @valid_funding_list;                 # delete duplicate funding in this library
            @unique_valid_funding_list = grep { $_ && !m/^\s+$/ } @unique_valid_funding_list;          # delete undef and empty values from arrary

            if ( scalar(@unique_valid_funding_list) == 1 ) {                                           # if only one funding is found in this library
                                                                                                       # OK to apply changes to all IWR.FKApplicable_Funding__ID in the same library, even the IW and WR may not directly connected through Plate
                                                                                                       # need to check if all target iw's only have <= 1funding
                my @lib_iw_list = $dbc->Table_find_array(
                    'Invoiceable_Work, Plate', ['Invoiceable_Work_ID'],
                    "WHERE Plate_ID = Invoiceable_Work.FK_Plate__ID AND Plate.FK_Library__Name = '$wr_library'",
                    -qutoquote => 1,
                    -distinct  => 1,
                    -debug     => $debug
                );

                push @full_iw_list, @lib_iw_list;

                foreach my $iw_id (@lib_iw_list) {
                    my @current_iwr_funding = $dbc->Table_find_array(
                        'Invoiceable_Work_Reference, Invoiceable_Work',
                        ['Invoiceable_Work_Reference.FKApplicable_Funding__ID'],
                        "WHERE Invoiceable_Work_ID = FKReferenced_Invoiceable_Work__ID AND Invoiceable_Work_ID = $iw_id",
                        -debug => $debug
                    );

                    my %seen;
                    my @unique_current_iwr_funding = grep { !$seen{$_}++ } @current_iwr_funding;    # delete duplicate parent plates
                    @unique_current_iwr_funding = grep { $_ && !m/^\s+$/ } @unique_current_iwr_funding;

                    my $num = scalar(@unique_current_iwr_funding) if $debug;
                    Message("number of unique_current_iwr_funding = $num") if $debug;

                    if ( scalar(@unique_current_iwr_funding) > 1 ) {
                        push @problem_iw_list, $iw_id;
                    }
                }
            }
        }
    }
    my %in_bl = map { $_ => 1 } @problem_iw_list;
    @ok_iw_list = grep { not $in_bl{$_} } @full_iw_list;    # @ok_iw_list = @full_iw_list - @problem_iw_list

    foreach my $ok_iw (@ok_iw_list) {
        my ($target_funding) = $dbc->Table_find_array(
            'Invoiceable_Work IW, Plate, Work_Request WR', ['WR.FK_Funding__ID'],
            "WHERE IW.FK_Plate__ID = Plate_ID AND Plate.FK_Work_Request__ID = Work_Request_ID AND Invoiceable_Work_ID = $ok_iw",
            -no_trigger => 1,
            -debug      => $debug
        );
        Message("target_funding(wr.FK_Funding__ID) for IW ($ok_iw) = $target_funding") if $debug;

        if ( !$target_funding ) {                           # plate not associate with any wr or wr doesn't have funding yet
            my ($target_lib) = $dbc->Table_find_array(
                'Invoiceable_Work IW, Plate', ['FK_Library__Name'],
                "WHERE IW.FK_Plate__ID = Plate_ID AND Invoiceable_Work_ID = $ok_iw",
                -no_trigger => 1,
                -debug      => $debug
            );

            ($target_funding) = $dbc->Table_find_array(
                'Work_Request', ['FK_Funding__ID'],
                "WHERE Work_Request.FK_Library__Name = '$target_lib' AND Work_Request.FK_Funding__ID IS NOT NULL",
                -autoquote => 1,
                -debug     => $debug
            )                                                                                                                 if $target_lib;
            Message("target_funding(wr.FK_Funding__ID) for IW ($ok_iw) = $target_funding if plate not associate with any wr") if $debug;
        }

        my $update_iwr_funding
            = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['Invoiceable_Work_Reference.FKApplicable_Funding__ID'], [$target_funding], "WHERE Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID = $ok_iw", -debug => $debug )
            if $target_funding;

        # my $update_iw_funding = $dbc->Table_update_array( 'Invoiceable_Work', ['Invoiceable_Work.FKApplicable_Funding__ID'], [$target_funding],
        # "WHERE Invoiceable_Work_ID = $ok_iw", -no_trigger => 1 );   # this should be delete later since the new data structure we only have IWR.FKApplicable_Funding__ID instead
    }
    my $problem_iw_list_str = Cast_List( -list => \@problem_iw_list, -to => 'string' ) if @problem_iw_list;
    $dbc->warning("The following Invoiceable Work contains multiple Fundings: $problem_iw_list_str, not able to apply Funding change for these Invoiceable Work record(s)") if @problem_iw_list;

    return;
}

###########################
# this trigger will be called when Plate.FK_Work_Request__ID been updated
###########################
sub change_plate_WR_trigger {
###########################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $id    = $args{-id};             # Plate_ID
    my $debug = $args{-debug};

    require SDB::DB_Object;
    my $id_string = Cast_List( -list => $id,        -to => 'string' );
    my @id_arr    = Cast_List( -list => $id_string, -to => 'array' );

    #my @id_arr = (722670,270084,270490,723640);		# for test only, plate 722670 has 2 iw, and >1 iwr, 270084 is 270490's parent, 722670|270084|270490|723640
    my ( @problem_iw_list, @ok_iw_list, @full_iw_list );

    $dbc->warning("In change_plate_WR_trigger()\n") if $debug;
    Message("In change_plate_WR_trigger()")         if $debug;
    Message("Updated_Plate_ID = $id_string")        if $debug;

    foreach my $plate_id (@id_arr) {
        Message("*** current_plate_id = $plate_id ***") if $debug;
        my @iw_id_list = $dbc->Table_find_array( 'Invoiceable_Work', ['Invoiceable_Work_ID'], "WHERE Invoiceable_Work.FK_Plate__ID = $plate_id" );
        push @full_iw_list, @iw_id_list;

        foreach my $iw_id (@iw_id_list) {
            my @iwr_id_list = $dbc->Table_find_array( 'Invoiceable_Work_Reference', ['Invoiceable_Work_Reference_ID'], "WHERE Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID = $iw_id" );
            my $previous_iwr_funding;
            my $index = 0;
            Message("*** current_iw_id = $iw_id ***") if $debug;

            foreach my $iwr_id (@iwr_id_list) {
                my ($current_iwr_funding) = $dbc->Table_find( 'Invoiceable_Work_Reference', 'Invoiceable_Work_Reference.FKApplicable_Funding__ID', "WHERE Invoiceable_Work_Reference_ID = $iwr_id" );

                Message("*** current_iwr_id = $iw_id ***") if $debug;
                if ( ( $index > 0 ) && ( !( $current_iwr_funding eq "" ) ) && ( !( $previous_iwr_funding eq "" ) ) && ( !( $current_iwr_funding eq $previous_iwr_funding ) ) )
                {    # if not all the Invoiceable_Work_Reference.FKApplicable_Funding__ID for a Invoiceable_Work are the same
                    $dbc->warning("In current_iwr_funding eq previous_iwr_funding\n") if $debug;
                    push @problem_iw_list, $iw_id;
                    last;    # jump to the next $iw_id
                }
                if ( !( $current_iwr_funding eq "" ) ) {
                    $previous_iwr_funding = $current_iwr_funding;
                }
                $index++;
            }
        }
    }

    my %in_bl = map { $_ => 1 } @problem_iw_list;
    @ok_iw_list = grep { not $in_bl{$_} } @full_iw_list;    # @ok_iw_list = @full_iw_list - @problem_iw_list

    foreach my $ok_iw (@ok_iw_list) {
        my ($target_funding)
            = $dbc->Table_find_array( 'Invoiceable_Work IW, Plate, Work_Request WR', ['WR.FK_Funding__ID'], "WHERE IW.FK_Plate__ID = Plate_ID AND Plate.FK_Work_Request__ID = Work_Request_ID AND Invoiceable_Work_ID = $ok_iw", -no_trigger => 1 );

        my $update_iwr_funding
            = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['Invoiceable_Work_Reference.FKApplicable_Funding__ID'], [$target_funding], "WHERE Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID = $ok_iw", -no_trigger => 1 );

        # my $update_iw_funding = $dbc->Table_update_array( 'Invoiceable_Work', ['Invoiceable_Work.FKApplicable_Funding__ID'], [$target_funding],
        # "WHERE Invoiceable_Work_ID = $ok_iw", -no_trigger => 1 );   # this should be delete later since the new data structure we only have IWR.FKApplicable_Funding__ID instead
    }
    my $problem_iw_list_str = Cast_List( -list => \@problem_iw_list, -to => 'string' ) if @problem_iw_list;
    $dbc->warning("The following Invoiceable Work contains multiple Fundings: $problem_iw_list_str, not able to apply Funding change for these Invoiceable Work record(s)") if @problem_iw_list;
    return;
}

###########################
# update the database to change plate's work request
###########################
sub save_work_request_change {
###########################
    my %args           = &filter_input( \@_ );
    my $dbc            = $args{-dbc};
    my @plate_id_list  = @{ $args{-ids} };         # eg. -ids => \@id as input
    my @plate_wr_list  = @{ $args{-plate_wr} };
    my @plate_opt_list = @{ $args{-plate_opt} };
    my $debug          = $args{-debug};

    $dbc->warning("In save_work_request_change()") if $debug;
    Message("In save_work_request_change()")       if $debug;

    require alDente::Container;
    my $index      = 0;
    my $num_update = 0;

    foreach my $plate_id (@plate_id_list) {        # update selected plated to the target work request according to the change options

        my $current_plate_wr_id = substr( @plate_wr_list[$index], 0, index( @plate_wr_list[$index], ':' ) );    # get Work_Request_ID from request detail (eg. 31544: ASPFL-112 => 31544)
        my ($current_fk_funding__id) = $dbc->Table_find( 'Work_Request', 'FK_Funding__ID', "WHERE Work_Request_ID = $current_plate_wr_id" );

        if ( @plate_opt_list[$index] eq "This Plate/Container and children Plates" ) {                          # apply changes to the selected plates and their children plates

            my $current_children_plate_list_str = alDente::Container::get_Children( -dbc => $dbc, -id => $plate_id, -format => 'list', -include_self => 1 );
            my @current_children_plate_list = Cast_List( -list => $current_children_plate_list_str, -to => 'Array' ) if $current_children_plate_list_str;
            my $update_wr = $dbc->Table_update_array( 'Plate', ['FK_Work_Request__ID'], [$current_plate_wr_id], "WHERE Plate_ID IN ($current_children_plate_list_str)", -autoquote => 1 );
            $num_update = $num_update + scalar(@current_children_plate_list);
        }
        elsif ( @plate_opt_list[$index] eq "This Plate/Container only" ) {                                      #apply change to the selected plates only
            my $update_wr = $dbc->Table_update_array( 'Plate', ['FK_Work_Request__ID'], [$current_plate_wr_id], "WHERE Plate_ID = $plate_id", -autoquote => 1 );
            $num_update++;
        }
        $index++;

    }
    Message("$num_update Plate record(s) have been updated.");
    return;
}

##################################
# Trigger to call method that sets work requests for solexa runs
# (on insert into Run table)
#
# Input: Run_ID
# Output: Message indicating success or failure (on success,
# message includes which work request/funding was assigned)
##################################
sub set_solexa_work_request_trigger {
##################################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $run   = $args{-run};
    my $debug = $args{-debug};
    my $result;

    $dbc->warning("In set_solexa_request_trigger()\n") if $debug;
    Message("In set_solexa_request_trigger()")         if $debug;
    Message("run id = $run")                           if $debug;

    ## Checking Run_Type -- function only applies to Solexa Runs
    my ($run_type) = $dbc->Table_find( 'Run', 'Run_Type', "WHERE Run_ID = $run" );

    unless ( $run_type eq 'SolexaRun' ) {
        Message("Run is a $run_type, not SolexaRun") if $debug;
        return;
    }

    my $wr = &set_solexa_work_request( -dbc => $dbc, -run => $run, -debug => $debug );
    my ($pla) = $dbc->Table_find( 'Run', 'FK_Plate__ID', "WHERE Run_ID = $run" );
    my ($funding) = $dbc->Table_find( 'Work_Request, Funding', 'Funding_Name', "WHERE Funding_ID = FK_Funding__ID AND Work_Request_ID = '$wr'" );

    if ($wr) {
        $result = "SUCCESS: Work Request $wr ($funding) has been assigned to Plate $pla for Run $run.\n";
    }
    else {
        $result = "ERROR: No work request was assigned to Plate $pla for Run $run.\n";
    }

    return $result;
}

##################################
# Function to set work request for Solexa Runs
# Input: Run_ID
# Output: Work_Request_ID assigned to plate run was done on
#
# Looks for all work requests associated to a library that have
# the associated goal '%#%Lanes%'.
# If 1 is found, set that as the work request.
# If > 1 is found, determine which work request to assign using
# the number of plates w/ associated work request (excluding the current plate being
# assigned a work request) vs. work request goal target.
# If none are found, set the work request to be first existing work request for library
##################################
sub set_solexa_work_request {
##################################
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $run_id = $args{-run};
    my $debug  = $args{-debug};

    ## Checking Run_Type -- function only applies to Solexa Runs
    my ($run_type) = $dbc->Table_find( 'Run', 'Run_Type', "WHERE Run_ID = $run_id" );

    unless ( $run_type eq 'SolexaRun' ) {
        Message("Run is a $run_type, not SolexaRun") if $debug;
        return;
    }

    my ($pla) = $dbc->Table_find( 'Run',   'FK_Plate__ID',     "WHERE Run_ID = $run_id" );    ## Get Plate_ID run was done on
    my ($lib) = $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID = $pla" );     ## Get Library_Name
    Message("PLA: $pla, Library: $lib found for Run $run_id") if $debug;

    ## Get all Work Requests associated w/ library that have Goal for runs (ordering is important)
    my @work_request = $dbc->Table_find(
        'Work_Request',
        'Work_Request_ID',
        "WHERE FK_Library__Name = '$lib' 
        AND FK_Goal__ID IN ( SELECT Goal_ID
                            FROM Goal
                            WHERE Goal_Name LIKE '%#%Lanes%' )
        ORDER BY Work_Request_ID"
    );
    Message("Available Work Requests for Runs: @work_request") if $debug;

    my $updated_pla;    ## Plate_ID that was updated
    if ( int @work_request > 1 ) {    ## Multiple eligible work requests found
        Message("Multiple eligible work requests found") if $debug;

        my $wr_string = Cast_List( -list => \@work_request, -to => 'string' );
        my @info = $dbc->Table_find_array( 'Work_Request', [ 'FK_Funding__ID', 'Goal_Target' ], "WHERE Work_Request_ID IN ($wr_string) ORDER BY Work_Request_ID" );
        my @funding;                  ## Fundings from WR
        my @target;                   ## Goal Targets from WR
        foreach my $info (@info) {
            my ( $fund, $targ ) = split ',', $info;
            push @funding, $fund;
            push @target,  $targ;
        }
        my $index = 0;
        foreach my $wr (@work_request) {
            ## Get number of plates that are associated to each work request AND have had runs done on them (excluding the plate that is currently being set)
            my ($count_pla)
                = $dbc->Table_find( 'Plate, Run, Invoiceable_Work', 'COUNT(DISTINCT Plate_ID)', "WHERE Plate_ID = Run.FK_Plate__ID AND Plate_ID = Invoiceable_Work.FK_Plate__ID AND FK_Work_Request__ID = $wr AND Billable = 'Yes' AND Plate_ID <> $pla" );
            my $funding_from_wr = $funding[$index];
            my %funding_target;
            my $i = 0;    ## Index
            foreach my $f (@funding) {
                $funding_target{$f} += $target[$i];
                $i++;
            }
            Message("PLA count: $count_pla; Target from WR: $target[$index]; Total Target for Funding: $funding_target{$funding_from_wr}") if $debug;

            ## Check that the work request has not been completed (make sure number of plates assigned to work request is less than both the goal target of
            ## work request and total goal target of work requests for runs grouped by funding)
            if ( ( $count_pla < $funding_target{$funding_from_wr} ) && ( $count_pla < $target[$index] ) ) {
                $updated_pla = $dbc->Table_update_array( 'Plate', ['FK_Work_Request__ID'], ["$wr"], "WHERE Plate_ID = $pla" );
                Message("Set FK_Work_Request__ID = $wr for PLA $updated_pla (Run $run_id)") if $debug;

                return $wr;
            }
            $index++;
        }
        Message("All eligible work requests are complete. Setting Work Request to be highest eligible Work_Request_ID.") if $debug;

        $updated_pla = $dbc->Table_update_array( 'Plate', ['FK_Work_Request__ID'], ["$work_request[($index - 1)]"], "WHERE Plate_ID = $pla" );
        Message("Set FK_Work_Request__ID = $work_request[($index - 1)] for PLA $updated_pla (Run $run_id)") if $debug;

        return $work_request[ ( $index - 1 ) ];
    }
    elsif ( int @work_request == 1 ) {    ## One eligible work request found
        Message("One eligible work request found") if $debug;

        $updated_pla = $dbc->Table_update_array( 'Plate', ['FK_Work_Request__ID'], ["$work_request[0]"], "WHERE Plate_ID = $pla" );
        Message("Set FK_Work_Request__ID = $work_request[0] for PLA $updated_pla (Run $run_id)") if $debug;

        return $work_request[0];
    }
    else {                                ## No eligible work requests found, set to any available work request from library
        Message("No eligible work requests found") if $debug;

        my @all_work_requests = $dbc->Table_find( 'Work_Request', 'Work_Request_ID', "WHERE FK_Library__Name = $lib ORDER BY Work_Request_ID" );
        $updated_pla = $dbc->Table_update_array( 'Plate', ['FK_Work_Request__ID'], ["$all_work_requests[0]"], "WHERE Plate_ID = $pla" );
        Message("Updated PLA $updated_pla for Run $run_id : Set Work Request to $all_work_requests[0]") if $debug;

        return $all_work_requests[0];
    }
}

return 1;
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
    
    

=head1 CREATED <UPLINK>
    
    <date>

=head1 REVISION <UPLINK>
    
    <version>

=cut

