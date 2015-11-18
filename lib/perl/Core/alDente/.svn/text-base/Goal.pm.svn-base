##################
# Goal.pm #
##################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Goal;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::HTML;    ## for debugging only ##
use alDente::Project;

##############################
# global_vars                #
##############################
use vars qw(%Configs);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

#################################
# constructor                #
#################################
#
# Constructor - initiate with
#
###########
sub new {
################
    my $this = shift;
    my %args = @_;
    my $dbc  = $args{-dbc};

    my $self = {};

    my $class = ref($this) || $this;
    bless $self, $class;

    $self->{dbc} = $dbc;
    return $self;
}

#
# Retrieve custom goal ids:
#
# <snip>
# $custom_goal_ids = ($dbc,'%');         ## all custom goals
# $custom_goal_ids = ($dbc);             ## custom goal
# $custom_goal_id  = ($dbc,'Completed'); ## 'Completed custom goal' goal (specific goal)
#
# </snip>
#
####################
sub custom_goal {
####################
    my $dbc = shift;
    my $type = shift || '';

    if ( $type =~ /\w/ ) { $type .= ' '; }

    my $custom_goal = join ',', $dbc->Table_find( 'Goal', 'Goal_ID', "WHERE Goal_Name LIKE '${type}Custom Goal'" );
    return $custom_goal;
}

###################
# Retrieve progress information based upon goals
#
# Output hash format (using library_names as keys) eg:
#
# %output = {'Lib1'=> {
#     'Goal_ID'         = (6),
#     'Goal_Name'         = ('96-well plates to sequence'),
#     'Goal_Description'         = ('plates (96-well) to run on sequencer (and approve)'),
#     'Completed' = (1),
#     'Outstanding'    = ('Add to Original Target'),
#     'Initial_Target'      = (100),
#     'Additional_Requests' = (50),
#     },
#     'Lib2' => {  ... }
#    }
#
# (some additional keys are also included such as Goal_Tables, Goal_Condition, Goal_Count - useful in debugging, but otherwise not generally needed)
#
# Return: hash with Libraries as keys;
###################
sub get_Progress {
###################
    my %args       = &filter_input( \@_, -args => 'dbc|self,library', -self => 'alDente::Goal' );
    my $self       = $args{-self};
    my $dbc        = $args{-dbc} || $self->{dbc};                                                   ## cgi_application parameter
    my $library    = $args{-library};                                                               ## Library passed as url parameter
    my $funding_id = $args{-funding_id};                                                            ## optionally filter on specific funding
    my $debug      = $args{-debug};

    my %required;
    my @libraries = &Cast_List( -list => $library, -to => 'array' );

    my $custom_goal = custom_goal($dbc);                                                            ## standard custom only
    my $custom_goals = custom_goal( $dbc, '%' );                                                    ## both custom goal and completed goal

    my $funding_condition;
    if ($funding_id) {
        if ( !$library ) { @libraries = $dbc->Table_find( 'Work_Request', 'FK_Library__Name', "WHERE FK_Funding__ID = $funding_id AND Length(FK_Library__Name) > 1", -distinct => 1 ) }
        $funding_condition .= " AND Work_Request.FK_Funding__ID IN ($funding_id)";
    }

    my $rownum = 0;
    foreach my $lib (@libraries) {
        ## get all of the goal & work request information for each library ##

        my $condition            = "FK_Goal__ID=Goal_ID AND FK_Library__Name like '$lib' $funding_condition AND FK_Work_Request_Type__ID = Work_Request_Type_ID ";
        my $exclude_custom_goals = " AND Goal_ID NOT IN ($custom_goals)";

        my %initial_goals = &Table_retrieve(
            $dbc,
            "Work_Request,Goal,Work_Request_Type",
            [ 'FK_Goal__ID', 'Sum(Goal_Target) as Initial_Target', 'Work_Request_Type_Name' ],
            "WHERE $condition $exclude_custom_goals AND Goal_Target_Type = 'Original Request' GROUP BY FK_Goal__ID, Work_Request_Type_Name",
            -debug => 0
        );

        my %requests = &Table_retrieve(
            $dbc,
            "Work_Request, Goal, Work_Request_Type",
            [ 'FK_Goal__ID', 'Sum(Goal_Target) as Additional_Requests', 'Goal_Target_Type', "CASE WHEN FK_Goal__ID IN ($custom_goal) THEN Work_Request_ID ELSE 0 END as Custom", 'Work_Request_Type_Name' ],
            "WHERE $condition $exclude_custom_goals AND Goal_Target_Type != 'Original Request' AND Scope = 'Library' Group by FK_Goal__ID,Goal_Target_Type,Work_Request_Type_Name",
            -debug => 0
        );

        ## add up additional work requests ##
        my %AR;
        my $i = 0;
        my @goal_ids;
        my %goal_work_request_type;
        while ( defined $requests{FK_Goal__ID}[$i] ) {
            my $goal_id           = $requests{FK_Goal__ID}[$i];
            my $request           = $requests{Additional_Requests}[$i];
            my $type              = $requests{Goal_Target_Type}[$i];
            my $work_request_type = $requests{Work_Request_Type_Name}[$i];
            if ( $type ne 'Included in Original Target' ) { $AR{$goal_id} += $request }
            if ( !grep /^$goal_id$/, @goal_ids ) { push @goal_ids, $goal_id }
            $goal_work_request_type{$goal_id}{$work_request_type} = 1;
            $i++;
        }

        my %IR;
        $i = 0;
        while ( defined $initial_goals{FK_Goal__ID}[$i] ) {
            my $goal_id           = $initial_goals{FK_Goal__ID}[$i];
            my $request           = $initial_goals{Initial_Target}[$i];
            my $work_request_type = $initial_goals{Work_Request_Type_Name}[$i];
            $IR{$goal_id} += $request;
            if ( !grep /^$goal_id$/, @goal_ids ) { push @goal_ids, $goal_id }
            $goal_work_request_type{$goal_id}{$work_request_type} = 1;
            $i++;
        }

        my $goal_ids = join ',', @goal_ids;
        my %goals;
        if ($goal_ids) {
            ## only if non_custom goals found ##
            %goals = $dbc->Table_retrieve( "Goal", [ 'Goal_ID', 'Goal_Name', 'Goal_Description', 'Goal_Tables', 'Goal_Count', 'Goal_Condition', 'Goal_Type' ], "WHERE Goal_ID IN ($goal_ids)" );

            $i = 0;
            while ( defined $goals{Goal_Name}[$i] ) {
                my $goal      = $goals{Goal_Name}[$i];
                my $goal_id   = $goals{Goal_ID}[$i];
                my $goal_desc = $goals{Goal_Description}[$i];
                my $tables    = $goals{Goal_Tables}[$i];
                my $select    = $goals{Goal_Count}[$i];
                my $condition = $goals{Goal_Condition}[$i];

                my $WR_target = 0;
                my $I_target  = 0;

                if ( defined $AR{$goal_id} ) { $WR_target = $AR{$goal_id} }
                if ( defined $IR{$goal_id} ) { $I_target  = $IR{$goal_id} }
                my $target = $I_target + $WR_target;

                $condition =~ s/\<LIBRARY\>/$lib/g;

                my @found;
                @found = $dbc->Table_find( $tables, $select, "WHERE $condition" ) if $select;

                my $count = 0;
                foreach my $plus (@found) {
                    if ($plus) { $count = $count + $plus }
                }

                ##
                my $done      = $count;
                my $also_done = 0;
                my $remaining = 0;

                if ( $count > $I_target ) {
                    if ($WR_target) {

                        #$done      = $I_target;
                        $also_done = $count - $I_target;
                    }

                    if ( $also_done > $WR_target ) {
                        $remaining = 0;
                    }
                    else {
                        $remaining = $WR_target - $also_done;
                    }
                }
                else {

                    #$done      = $count;
                    $remaining = $I_target - $count;
                    $also_done = 0;
                }

                $goals{Completed}[$i]           = $done;
                $goals{Additional_Requests}[$i] = $WR_target;
                $goals{Initial_Target}[$i]      = $I_target;
                $goals{Target}[$i]              = $target;
                $goals{Outstanding}[$i]         = $remaining;

                ## add work request type
                $goals{Work_Request_Type}[$i] = join ',', keys %{ $goal_work_request_type{$goal_id} };

                $i++;
            }
        }

        ## Handle custom goals separately ... ##
        ## WHY ... ?? ... removed ###

        my $custom_goals_only = $exclude_custom_goals;
        $custom_goals_only =~ s / NOT IN / IN /;

        my %custom_goals = $dbc->Table_retrieve(
            "Work_Request,Goal,Work_Request_Type",
            [   'Work_Request_ID', 'Goal_ID', 'Goal_Name',
                'Work_Request_Title as Description',
                'Goal_Target as Target',
                "CASE WHEN FK_Goal__ID IN ($custom_goals) THEN Work_Request_ID ELSE 0 END as Custom",
                "CASE WHEN Goal_Name = 'Completed Custom Goal' THEN Goal_Target ELSE 0 END as Completed",
                'Work_Request_Type_Name'
            ],
            "WHERE $condition $custom_goals_only"
        );

        my $count = $i;
        $i = 0;
        while ( defined $custom_goals{Work_Request_ID}[$i] ) {
            my $id                = $custom_goals{Goal_ID}[$i];
            my $name              = $custom_goals{Goal_Name}[$i];
            my $target            = $custom_goals{Target}[$i];
            my $desc              = $custom_goals{Description}[$i];
            my $custom            = $custom_goals{Custom}[$i];
            my $completed         = $custom_goals{Completed}[$i];
            my $work_request_type = $custom_goals{Work_Request_Type_Name}[$i];

            $goals{Goal_ID}[$count]             = $id;
            $goals{Goal_Name}[$count]           = $name;
            $goals{Additional_Requests}[$count] = $target;
            $goals{Target}[$count]              = $target;              ## same as additional requests (no initial_targets defined since not definable goal)
            $goals{Completed}[$count]           = $completed;           ## must be established by adming <CONSTRUCTION> incorporate into attributes and retrieve as required.
            $goals{Goal_Description}[$count]    = $desc;
            $goals{Custom}[$count]              = $custom;
            $goals{Work_Request_Type}[$count]   = $work_request_type;
            $count++;
            $i++;
        }

        ## add work requests NOT tied to goals ##

        my %work_requests = $dbc->Table_retrieve(
            'Work_Request,Work_Request_Type',
            [ 'Work_Request_Type_Name', 'Work_Request_Title', 'Sum(Goal_Target) as Target', 'Work_Request_Title as Description' ],
            "WHERE FK_Work_Request_Type__ID=Work_Request_Type_ID $funding_condition AND FK_Library__Name = '$lib' AND Goal_Target > 0 AND (FK_Goal__ID IS NULL OR FK_Goal__ID = 0) GROUP BY FK_Work_Request_Type__ID",
        );

        $count = $i;
        $i     = 0;
        while ( defined $work_requests{Work_Request_Type_Name}[$i] ) {
            my $name   = $work_requests{Work_Request_Type_Name}[$i];
            my $target = $work_requests{Target}[$i];
            my $desc   = $work_requests{Description}[$i];
            my $custom = $work_requests{Custom}[$i];

            $goals{Goal_Name}[$count]           = $name;
            $goals{Additional_Requests}[$count] = $target;
            $goals{Target}[$count]              = $target;    ## same as additional requests (no initial_targets defined since not definable goal)
            $goals{Completed}[$count]           = '?';        ## must be established by adming <CONSTRUCTION> incorporate into attributes and retrieve as required.
            $goals{Goal_Description}[$count]    = $desc;
            $goals{Custom}[$count]              = $custom;
            $goals{Work_Request_Type}[$count]   = $name;
            $count++;
            $i++;
        }

        $required{$lib} = {%goals};
    }
    return \%required;
}

######################
#
# Retrieve goals completed automatically and reset Library status to 'Complete' or 'In Production' if applicable
#
#
########################
sub set_Library_Status {
########################
    my %args                = &filter_input( \@_, -args => 'dbc|self,library,set_peripheral_info', -self => 'alDente::Goal' );
    my $self                = $args{-self};
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $library             = $args{-library};
    my $work_request        = $args{-work_request};                                                                              ## enable call directly from new LibraryGoal record (eg via trigger)
    my $set_peripheral_info = $args{-set_peripheral_info} || 0;                                                                  # will run set_work_request_percent_complete as well
    my $condition           = $args{-condition} || 1;
    my $status              = $args{-status} || 'Incomplete';
    my $Report              = $args{-report};
    my $debug               = $args{-debug};

    if ($work_request) {
        my $wr_list = Cast_List( -list => $work_request, -to => 'string', -autoquote => 0 );
        if ($wr_list) {
            $library = join ',', $dbc->Table_find( 'Work_Request', 'FK_Library__Name', "WHERE Work_Request_ID in ($wr_list) AND Scope = 'Library'" );
        }
    }

    if ( !$library ) { return; }

    my @libraries = &Cast_List( -list => $library, -to => 'array' );

    my @closed   = ();
    my @opened   = ();
    my @messages = ();
    my %required;
    %required = %{ get_Progress( -dbc => $dbc, -library => $library ) } if $library;

    my @complete_library       = ();    # holds libraries which have completed both lab work and data analysis
    my %wr_completion_extremes = ();    # track goal-library relations that have 0% completion or 100% completion, to batch update.
    my %change_library;
    my %change_library_analysis;
    my $today = today();
    foreach my $lib ( sort keys %required ) {
        my %goals = %{ $required{$lib} };
        my ($status) = $dbc->Table_find( 'Library', 'Library_Status', "WHERE Library_Name = '$lib'" );

        if ( $status =~ /(On Hold|Cancelled)/ ) { print "Skipping $status library $lib\n"; next; }

        my $i = 0;
        my %goal_completion;

        my $message;
        while ( defined $goals{Target}[$i] ) {
            my $target    = $goals{Target}[$i];
            my $completed = $goals{Completed}[$i];
            my $goal      = $goals{Goal_Name}[$i];
            my $goal_type = $goals{Goal_Type}[$i];
            $i++;

            if ( $goal =~ /No Defined goals/i ) {next}    ## skip undefined goal targets ##

            if ( $completed >= $target ) {
                $message .= "Completed $goal ($completed/$target); ";
                $goal_completion{$goal_type}{complete}++;
            }
            else {
                $goal_completion{$goal_type}{incomplete}++;
                $message .= "Incomplete goal $goal ($completed/$target); ";
            }
        }

        my $lw_complete = 0;
        my $da_complete = 0;

        ## Order below is important - if ANY of the goals are incomplete, the status should be set to incomplete ##
        if ( $goal_completion{'Lab Work'}{incomplete} ) {
            my ($change) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name = '$lib' AND Library_Status IN ('Complete')" );
            if ($change) {

                #my $change = $dbc->Table_update_array( 'Library', [ 'Library_Status', 'Library_Completion_Date' ], [ 'In Production', '0000-00-00' ], "WHERE Library_Name = '$lib'", -autoquote => 1 );
                push @{ $change_library{'In Production'} }, $lib;

                push @messages, "Status of $lib changed to 'In Production' ($message)";
                push @opened,   $lib;

                &alDente::Project::set_Project_status( -dbc => $dbc, -library => $lib, -debug => $debug );
            }
        }
        elsif ( $goal_completion{'Lab Work'}{complete} ) {
            my ($today) = split ' ', &date_time();
            my ($change) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name = '$lib' and Library_Status in ('In Production','Submitted')" );
            if ($change) {

                #$dbc->Table_update_array( 'Library', [ 'Library_Status', 'Library_Completion_Date' ], [ 'Complete', $today ], "WHERE Library_Name = '$lib'", -autoquote => 1 );
                push @{ $change_library{'Complete'} }, $lib;
                push @messages, "Status of $lib changed to 'Complete' ($message)";
                push @closed,   $lib;

                &alDente::Project::set_Project_status( -dbc => $dbc, -library => $lib, -debug => $debug );
            }
            $lw_complete = 1;
        }
        if ( $goal_completion{'Data Analysis'}{incomplete} ) {
            my ($change) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name = '$lib' AND Library_Analysis_Status IN ('N/A','Complete')" );
            if ($change) {
                push @{ $change_library_analysis{'In Production'} }, $lib;

                #my $change = $dbc->Table_update_array( 'Library', ['Library_Analysis_Status'], ['In Production'], "WHERE Library_Name = '$lib'", -autoquote => 1 );
                push @messages, "Analysis_Status of $lib changed to 'In Production' ($message)";

                #push @opened,   $lib;
            }
        }
        elsif ( $goal_completion{'Data Analysis'}{complete} ) {
            my ($today) = split ' ', &date_time();
            my ($change) = $dbc->Table_find( 'Library', 'Library_Name', "WHERE Library_Name = '$lib' and Library_Analysis_Status in ('N/A','In Production')" );
            if ($change) {

                #$dbc->Table_update_array( 'Library', ['Library_Analysis_Status'], ['Complete'], "WHERE Library_Name = '$lib'", -autoquote => 1 );
                push @{ $change_library_analysis{'Complete'} }, $lib;
                push @messages, "Analysis_Status of $lib changed to 'Complete' ($message)";

                #push @closed,   $lib;
            }
            $da_complete = 1;
        }

        if ( %goals && $set_peripheral_info ) {
            if ( $lw_complete && $da_complete ) {
                push @complete_library, $lib;
            }
            else {
                %wr_completion_extremes = %{ set_Work_Request_Percent_Complete( $dbc, -library => $lib, -goals => \%goals, -completion_extremes => \%wr_completion_extremes ) };

            }
        }
    }

    # perform batch updates for work_request percent completion
    if ($set_peripheral_info) {
        if (@complete_library) {
            set_Library_WR_Complete( $dbc, -library_list => \@complete_library );
        }

        if (%wr_completion_extremes) {
            set_WR_completion_extremes( $dbc, -completion_extremes => \%wr_completion_extremes );
        }
    }

    if ( defined $change_library{'In Production'} && int( @{ $change_library{'In Production'} } ) > 0 ) {
        my $in_prod_list = Cast_List( -list => $change_library{'In Production'}, -to => 'String', -autoquote => 1 );
        my $change = $dbc->Table_update_array( 'Library', [ 'Library_Status', 'Library_Completion_Date' ], [ 'In Production', '0000-00-00' ], "WHERE Library_Name IN ($in_prod_list)", -autoquote => 1, -debug => 0 );
    }
    if ( defined $change_library{'Complete'} && int( @{ $change_library{'Complete'} } ) > 0 ) {
        my $completed_list = Cast_List( -list => $change_library{'Complete'}, -to => 'String', -autoquote => 1 );
        $dbc->Table_update_array( 'Library', [ 'Library_Status', 'Library_Completion_Date' ], [ 'Complete', $today ], "WHERE Library_Name IN ($completed_list)", -autoquote => 1, -debug => 0 );
    }
    if ( defined $change_library_analysis{'In Production'} && int( @{ $change_library_analysis{'In Production'} } ) > 0 ) {
        my $completed_list = Cast_List( -list => $change_library_analysis{'In Production'}, -to => 'String', -autoquote => 1 );
        $dbc->Table_update_array( 'Library', ['Library_Analysis_Status'], ['In Production'], "WHERE Library_Name IN ($completed_list)", -autoquote => 1, -debug => 0 );
    }
    if ( defined $change_library_analysis{'Complete'} && int( @{ $change_library_analysis{'Complete'} } ) > 0 ) {
        my $completed_list = Cast_List( -list => $change_library_analysis{'Complete'}, -to => 'String', -autoquote => 1 );
        $dbc->Table_update_array( 'Library', ['Library_Analysis_Status'], ['Complete'], "WHERE Library_Name IN ($completed_list)", -autoquote => 1, -debug => 0 );
    }

    return ( \@closed, \@opened, \@messages );
}

######################
# Uses goals passed in when run inside
# Retrieve goals completed and updates percent complete partially completed Work_Request table
# Also builds on top of completion_extremes hash to allow for batch update on wrs
# Output: adds onto completion_extremes hash .. appending libraries which have Completed goals and unstarted goals
########################
sub set_Work_Request_Percent_Complete {
########################
    my %args                = &filter_input( \@_, -args => 'dbc,library,goals,completion_extremes', -self => 'alDente::Goal' );
    my $self                = $args{-self};
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $lib                 = $args{-library};
    my $completion_extremes = $args{-completion_extremes};
    my $goals               = $args{-goals};
    my %goals               = %{$goals};

    my $i = 0;

    my @complete_goal_id  = ();
    my @unstarted_goal_id = ();

    while ( defined $goals{Target}[$i] ) {
        my $target    = $goals{Target}[$i];
        my $completed = $goals{Completed}[$i];
        my $goal      = $goals{Goal_Name}[$i];
        my $goal_id   = $goals{Goal_ID}[$i];
        $i++;

        ##set undefined goal targets to percent complete ##
        if ( $goal =~ /No Defined goals/ || !$target ) {
            push @unstarted_goal_id, $goal_id;
            next;
        }

        #for straight forward cases we can update all work_requests associated with that library and goal
        if ( $completed >= $target ) {
            if ( defined $completion_extremes->{$goal_id}{completed} ) {
                push @{ $completion_extremes->{$goal_id}{completed} }, $lib;
            }
            else {
                $completion_extremes->{$goal_id}{completed} = [$lib];
            }
        }
        elsif ( $completed <= 0 ) {
            if ( defined $completion_extremes->{$goal_id}{unstarted} ) {
                push @{ $completion_extremes->{$goal_id}{unstarted} }, $lib;
            }
            else {
                $completion_extremes->{$goal_id}{unstarted} = [$lib];
            }
        }
        else {
            ## split partial completions across applicable work requests...
            my @work_request = $dbc->Table_find( 'Work_Request', 'Work_Request_ID, Goal_Target', "WHERE FK_Library__Name = '$lib' AND FK_Goal__ID = $goal_id ORDER BY Work_Request_ID" );

            set_WR_partial_percent_complete( $dbc, -work_request_list => \@work_request, -completed => $completed );
        }
    }

    return $completion_extremes;
}

######################
# Input: Array ref of Work_Requests, Goal completed for those work_reqs
# Splits goal completion across work_requests starting from early work_requests
# Output: goal_completed (should be 0) unless completed more than target
########################
sub set_WR_partial_percent_complete {
########################
    my %args              = &filter_input( \@_, -args => 'dbc,work_request_list,completed', -self => 'alDente::Goal' );
    my $self              = $args{-self};
    my $dbc               = $args{-dbc} || $self->{dbc};
    my $completed         = $args{-completed};
    my $work_request_list = $args{-work_request_list};                                                                    # array_ref of work_requests in order of wr_id

    my $percent_complete = 0;
    my $unstarted_wrs = Cast_List( -list => $work_request_list, -to => 'string' );
    $dbc->Table_update_array( 'Work_Request', ['Percent_Complete'], [$percent_complete], "WHERE Work_Request_ID IN ($unstarted_wrs) AND Scope = 'Library'" );    # set all to 0 first

    foreach my $wr (@$work_request_list) {
        my ( $wr_id, $wr_target ) = split ',', $wr;

        if ( $completed <= 0 ) {
            last;                                                                                                                                                # break out of loop the rest should have been updated to 0 in the beginning
        }

        if ( defined $wr_target && $wr_target > 0 && $completed ) {
            if ( $completed >= $wr_target ) {
                $percent_complete = 100;
                $completed        = $completed - $wr_target;
            }
            else {
                $percent_complete = 100 * $completed / $wr_target;
                $completed        = 0;
            }
            $dbc->Table_update_array( 'Work_Request', ['Percent_Complete'], [$percent_complete], "WHERE Work_Request_ID = $wr_id" );
        }
    }

    return $completed;
}

######################
# Input: Array ref of Libraries that are complete
# Batch update all work requests associated with those libraries to set their Percent_Complete to 100%
# Output: number of records updated
########################
sub set_Library_WR_Complete {
########################
    my %args         = &filter_input( \@_, -args => 'dbc,library_list', -self => 'alDente::Goal' );
    my $self         = $args{-self};
    my $dbc          = $args{-dbc} || $self->{dbc};
    my $library_list = $args{-library_list};                                                          #array_ref of complete libraries

    my $libraries = Cast_List( -list => $library_list, -to => 'string', -autoquote => 1 );

    my $updated = $dbc->Table_update_array( 'Work_Request', ['Percent_Complete'], [100], "WHERE FK_Library__Name IN ($libraries)" );

    return $updated;
}

######################
# Input: Hash ref of Libraries that are either complete (100%) or unstarted (0%)
# Batch update all work requests associated with those libraries to set their Percent_Complete respectively
# Output: none
########################
sub set_WR_completion_extremes {
########################
    my %args                = &filter_input( \@_, -args => 'dbc,completion_extremes', -self => 'alDente::Goal' );
    my $self                = $args{-self};
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $completion_extremes = $args{-completion_extremes};                                                          #array_ref of complete and unstarted libraries

    foreach my $goal_id ( keys %$completion_extremes ) {

        if ( defined $completion_extremes->{$goal_id}{completed} && scalar @{ $completion_extremes->{$goal_id}{completed} } ) {
            my $completed_libraries = Cast_List( -list => $completion_extremes->{$goal_id}{completed}, -to => 'string', -autoquote => 1 );
            $dbc->Table_update_array( 'Work_Request', ['Percent_Complete'], [100], "WHERE FK_Library__Name IN ($completed_libraries) AND FK_Goal__ID = $goal_id" );
        }

        if ( defined $completion_extremes->{$goal_id}{unstarted} && scalar @{ $completion_extremes->{$goal_id}{unstarted} } ) {
            my $unstarted_libraries = Cast_List( -list => $completion_extremes->{$goal_id}{unstarted}, -to => 'string', -autoquote => 1 );
            $dbc->Table_update_array( 'Work_Request', ['Percent_Complete'], [0], "WHERE FK_Library__Name IN ($unstarted_libraries) AND FK_Goal__ID = $goal_id" );
        }
    }

    return;
}

# Input: Library_Name or Sourcelist
# Return: Work_Req_ID, Work_Req_Title, Goal_Name, Work_Req_Created, Work_Req_Goal_Target,Work_Req_Comments, Work_Req_Type, Num_Plates_Submitted, Funding
# Will be used for the getting an array of html tables, each of which will be associated with a library or source depending on input.
#####################
sub get_work_request_breakout {
#####################
    my %args              = &filter_input( \@_, -args => 'dbc,library_list|source_list,field_list', -mandatory => 'dbc,library_list|source_list' );
    my $dbc               = $args{-dbc};
    my $library_list      = $args{-library_list};                                                                                                     # array of libraries from Key field of view
    my $source_list       = $args{-source_list};                                                                                                      # array of sources from Key field of view
    my $default_field_ref = [ 'id', 'title', 'goal', 'created', 'goal_target', 'comments', 'type', 'plates_submitted', 'funding' ];
    my $custom_field_ref  = $args{-field_list} || $default_field_ref;                                                                                 #provide a custom field list, or it will use default
    my @key_list;
    my $keys;

    if ( $library_list && !$source_list ) {
        @key_list = Cast_List( -list => $library_list, -to => 'Array' );                                                                              #array for merge_data_for_column
        $keys = Cast_List( -list => $library_list, -to => 'String', -autoquote => 1 );                                                                #autoquote for SQL IN query
    }
    elsif ( !$library_list && $source_list ) {
        @key_list = Cast_List( -list => $source_list, -to => 'Array' );                                                                               #array for merge_data_for_column
        $keys = Cast_List( -list => $source_list, -to => 'String', -autoquote => 1 );                                                                 #autoquote for SQL IN query
    }
    else {
        return;
    }

    my $grouping_field = "Work_Request.FK_Library__Name";

    my @fields = ();

    my %wr_fields = (
        'id',      'Work_Request.Work_Request_ID AS ID',               'title',            'Work_Request.Work_Request_Title AS Title',              'goal',     'Goal.Goal_Name AS Goal',
        'created', 'Work_Request.Work_Request_Created AS Created',     'goal_target',      'Work_Request.Goal_Target AS Goal_Target',               'comments', 'Work_Request.Comments AS Comments',
        'type',    'Work_Request_Type.Work_Request_Type_Name AS Type', 'plates_submitted', 'Work_Request.Num_Plates_Submitted AS Plates_Submitted', 'funding',  'Work_Request.FK_Funding__ID AS Funding'
    );

    #  custom_field_ref is an empty array; use default fields
    if ( !@$custom_field_ref ) {
        $custom_field_ref = $default_field_ref;
    }

    #adds fields in custom order, or default if not specified
    foreach my $c_field (@$custom_field_ref) {
        my $field = $wr_fields{ lc($c_field) };
        if ($field) {
            push @fields, $field;
        }
    }

    my $tables = '(Work_Request, Work_Request_Type, Goal)';

    my $extra_conditions = "Work_Request.FK_Library__Name IN ($keys)";
    my $order_by         = $grouping_field;

    #If source_list if provided, change fields, tables and conditions
    if ($source_list) {
        unshift( @fields, $grouping_field );
        $grouping_field = "LS.FK_Source__ID";
        $tables .= ', Library_Source LS';
        $extra_conditions = "Work_Request.FK_Library__Name = LS.FK_Library__Name AND LS.FK_Source__ID IN ($keys)";
        $order_by         = $grouping_field . ', Work_Request.FK_Library__Name';
    }

    my %results = $dbc->Table_retrieve(
        $tables,
        [ @fields, $grouping_field ],
        "LEFT JOIN Plate ON Plate.FK_Work_Request__ID = Work_Request.Work_Request_ID WHERE Work_Request_Type.Work_Request_Type_ID = Work_Request.FK_Work_Request_Type__ID AND Goal.Goal_ID = Work_Request.FK_Goal__ID AND $extra_conditions GROUP BY Work_Request.Work_Request_ID ORDER BY $order_by",
        -distinct => 1
    );

    #data should be ordered by grouping field before being passed into merge data for grouping
    return alDente::View::merge_data_for_table_column( %args, -dbc => $dbc, -data_hash => \%results, -key_list => \@key_list, -grouping_field => $grouping_field, -field_order => \@fields );
}

#
# Move to View module ...
#
##############################
sub add_Analysis_Goal_form {
##############################
    my %args      = filter_input( \@_ );
    my $dbc       = $args{-dbc};
    my $reference = $args{-reference};          ### indicate whether linking to Libraries / SOWs / Plates.
    my $goal_type = $args{-goal_type};
    my $condition = $args{-condition} || '1';

    my $q = new CGI;
    my $form = alDente::Form::start_alDente_form( -dbc => $dbc );

    if ($goal_type) {
        $condition .= " AND Goal_Type = '$goal_type'";
    }

    $form .= "Specify Libraries..";
    my $reference_objects;

    my $reference_input = Show_Tool_Tip( $q->textarea( -name => 'Library List', -rows => 20, -cols => 20 ), "Paste list of libraries here, and select applicable goals to be added" );

    my $goal_column = "<U>Additional $goal_type Goals to be Tracked:</U><BR>";
    my @goals = $dbc->get_FK_info_list( -field => 'FK_Goal__ID', -condition => $condition );
    foreach my $goal (@goals) {
        $goal_column .= $q->checkbox( -name => 'FK_Goal__ID', -value => $goal, -label => $goal ) . '<br>';
    }

    $form .= &Views::Table_Print( content => [ [ $reference_input, $goal_column ] ], -return_html => 1 );

    $form
        .= '<P>'
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Goal_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => "Add $goal_type Goals", -class => 'Action', -force => 1 )
        . $q->checkbox( -name => 'Add JIRA Ticket', -checked => 0 );

    $form .= $q->end_form();
    return $form;

}

#########################
# Retrieve all the sub goals of the specified goal
#
# <snip>
#	my @sub_goals = @{alDente::Goal::get_sub_goals( -dbc => $dbc, -goal_id = $id )};
# </snip>
#
# Return: Array ref
#########################
sub get_sub_goals {
#########################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $goal_id = $args{-goal_id};

    ## get all its specific goals
    my @sub_goals;
    my @broad = ($goal_id);
    my $broad = shift @broad;
    while ($broad) {
        my @sub = $dbc->Table_find( 'Sub_Goal', 'FKSub_Goal__ID', "WHERE FKBroad_Goal__ID = $broad" );
        foreach my $goal (@sub) {
            my ($scope) = $dbc->Table_find( 'Goal', 'Goal_Scope', "WHERE Goal_ID = $goal" );
            if   ( $scope =~ /Broad/i ) { push @broad,     $goal }
            else                        { push @sub_goals, $goal }
        }
        $broad = shift @broad;
    }
    return \@sub_goals;
}

1;
