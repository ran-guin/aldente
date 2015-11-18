package alDente::Protocol;

use strict;
use Data::Dumper;
use CGI qw(:standard);
use DBI;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Pipeline;

use vars qw($scanner_mode %Prefix );

sub new {
    my $this             = shift;
    my %args             = @_;
    my $pipeline         = $args{-pipeline};
    my $protocol_id      = $args{-id};
    my $pipeline_step_id = $args{-pipeline_step_id};
    my $dbc              = $args{-dbc};
    my $library_filter   = $args{-library_filter};
    my $library_condition;
    $library_condition = Cast_List( -list => $args{-library_condition}, -to => 'arrayref' ) if ( $args{-library_condition} );

    my ($class) = ref($this) || $this;
    my ($self) = {};

    ## Initialize Attributes
    $self->{protocol_id}           = $protocol_id;
    $self->{pipeline}              = $pipeline;
    $self->{pipeline_step_id}      = $pipeline_step_id;
    $self->{parent_pipeline_steps} = [];
    $self->{child_pipeline_steps}  = [];
    $self->{API_loaded}            = 0;
    $self->{library_filter}        = $library_filter;
    $self->{library_condition}     = $library_condition;

    my $libraries = Cast_List( -list => $library_filter, -to => "String", -autoquote => 1 );
    push @{ $self->{library_condition} }, "Plate.FK_Library__Name IN ($libraries) " if $libraries;

    $self->{pipeline_step_conditions} = {
        'Ready' => {
            plate_format_id => '',
            pipeline_id     => '',
            plate_status    => ''
        },
        'In Process' => {

        },
        'Completed' => { include_transfers => '' },
        'Pipeline'  => {

        }
    };
    $self->{completed_plates}   = [];
    $self->{transferred_plates} = [];
    $self->{in_progress_plates} = [];
    $self->{ready_plates}       = [];
    $self->{redo_plates}        = [];
    $self->{repeat_plates}      = [];
    $self->{dbc}                = $dbc;

    bless $self, $class;

    return $self;
}

sub load_configuration {
    my $self = shift;

    $self->set_parent_pipeline_steps( -pipeline_step => $self->{pipeline_step_id} );

}

sub request_broker {

}

# ============================================================================
# Method     : get_parent_pipeline_steps()
# Usage      : $self->get_parent_pipeline_steps();
# Purpose    : Get the parent protocols
# Returns    : List of Protocols as Array Reference
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub get_parent_pipeline_steps {
    my $self = shift;
    my %args = @_;
    return $self->{parent_pipeline_steps};
}

# ============================================================================
# Method     : get_child_pipeline_steps()
# Usage      : $self->get_child_pipeline_steps();
# Purpose    :
# Returns    : List of Protocols as Array Reference
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub get_child_pipeline_steps {
    my $self = shift;
    return $self->{child_pipeline_steps};
}

# ============================================================================
# Method     : set_child_pipeline_steps()
# Usage      : $self->set_child_pipeline_steps(-protocols=>\@protocols);
# Purpose    :
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub set_child_pipeline_steps {
    my $self      = shift;
    my %args      = @_;
    my $protocols = $args{-protocols};
    $self->{child_pipeline_steps} = $protocols;
    return;
}

# ============================================================================
# Method     : set_child_pipeline_steps()
# Usage      : $self->set_child_pipeline_steps(-protocols=>\@protocols);
# Purpose    :
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub set_parent_pipeline_steps {
    my $self                  = shift;
    my %args                  = @_;
    my $pipeline_step         = $args{-pipeline_step};
    my $parent_pipeline_steps = $args{-parent_pipeline_steps};

    my @pipeline_steps;
    if ($parent_pipeline_steps) {
        @pipeline_steps = @{$parent_pipeline_steps};
    }
    else {
        @pipeline_steps = $self->{dbc}->Table_find( 'Pipeline_StepRelationship', 'FKParent_Pipeline_Step__ID', "WHERE FKChild_Pipeline_Step__ID = $pipeline_step" );
    }

    $self->{parent_pipeline_steps} = \@pipeline_steps;
    return;
}

# ============================================================================
# Method     : get_ready_plates()
# Usage      : $self->get_ready_plates();
# Purpose    : Get the plates that are ready for the given protocol
# Returns    : List of Plate ID's as Array Reference
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : Must be run AFTER get_completed, get_in_progress - Use via wrapper get_progress instead.
# See Also   : n/a
# ============================================================================
sub get_ready_plates {
###########################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $condition    = Cast_List( -list => $args{-condition}, -to => 'arrayref' );
    my $transferred  = $args{-transferred};
    my $in_progress  = $args{-in_progress};
    my $completed    = $args{-completed};
    my $failed       = $args{-failed};
    my $debug        = $args{-debug} || 0;
    my @ready_plates = ();
    ## if the parent pipeline steps exist, check if the parent pipeline step is a protocol,
    ## if it is a protocol, find the plates that have completed the protocol

    if ( int( @{ $self->{parent_pipeline_steps} } ) > 0 ) {
        foreach my $parent_pipeline_step ( @{ $self->{parent_pipeline_steps} } ) {

            # create the parent pipeline_step object and get the completed plates for that pipeline
            my $parent = alDente::Pipeline::get_pipeline_step( -dbc => $self->{dbc}, -pipeline_step_id => $parent_pipeline_step, -library_filter => $self->{library_filter} );
            $parent->get_completed_plates( -condition => $condition );
            push @ready_plates, @{ $parent->{completed_plates} };
        }
        @ready_plates = @{ unique_items( \@ready_plates ) };

        @ready_plates = sort @{ set_difference( \@ready_plates, [ @{$transferred}, @{$in_progress}, @{$completed}, @{$failed} ] ) };
    }
    else {
        my $condition_string;
        my @conditions;
        if ($condition) { @conditions = @{$condition} }
        if ( $self->{library_condition} ) { push @conditions, @{ $self->{library_condition} } }
        $condition_string = join ' AND ', @conditions;

        #previous sql query for the first step of pipeline
        #finding plates in the library and pipeline where there is no child and no last prep id
#####
        #	    my @pipeline_plates = $self->{dbc}->Table_find('Library,Plate LEFT JOIN Plate as Child ON Plate.Plate_ID = Child.FKParent_Plate__ID','Plate.Plate_ID',
        #                                                    "WHERE Plate.FK_Library__Name=Library_Name AND
        #	                                                 Plate.FK_Pipeline__ID = $self->{pipeline}
        #	                                                and Plate.Plate_Status ='Active' AND $condition_string
        #                                                        and IF(Plate.FKLast_Prep__ID,0,1)
        #	                                                ",-debug=>$debug);
        #            # removed (?) :  AND Child.Plate_ID IS NULL
#####

        #new sql: find plates in the library and pipeline where the plate's last prep record is not any one of the protocols in the pipeline
        #	my @pipeline_plates = $self->{dbc}->Table_find("Library,Plate
        #                                                       LEFT JOIN Plate_Prep ON Plate.Plate_ID=Plate_Prep.FK_Plate__ID
        #                                                       AND Plate_Prep.FK_Prep__ID=Plate.FKLast_Prep__ID
        #                                                       LEFT JOIN Prep ON Prep.Prep_ID=Plate_Prep.FK_Prep__ID
        #                                                       AND FK_Lab_Protocol__ID IN (Select Object_ID from Pipeline_Step where FK_Pipeline__ID = $self->{pipeline})",
        #						       'Plate_ID',
        #						       "WHERE Plate.FK_Library__Name=Library_Name
        #                                                       AND Plate.FK_Pipeline__ID = $self->{pipeline}
        #                                                       AND Plate.Plate_Status ='Active'
        #                                                       AND $condition_string
        #                                                       AND Prep_ID IS NULL
        #                                                       GROUP BY Plate_ID",
        #						       -debug=>$debug);

        #new sql: find plates in the library and pipeline where none of the protocols in the pipeline has prep on the plate
        my @pipeline_plates = $self->{dbc}->Table_find(
            "Library,Plate
                                                       LEFT JOIN Plate_Prep ON Plate.Plate_ID=Plate_Prep.FK_Plate__ID
                                                       LEFT JOIN Prep ON Prep.Prep_ID=Plate_Prep.FK_Prep__ID
                                                       AND FK_Lab_Protocol__ID IN (Select Object_ID from Pipeline_Step where FK_Pipeline__ID = $self->{pipeline})
                                                       LEFT JOIN Plate_Schedule ON Plate.Plate_ID = Plate_Schedule.FK_Plate__ID",
            'Plate_ID, SUM(CASE WHEN Prep_ID > 0 THEN 1 ELSE 0 END) AS Pipeline_Protocol_Preps',
            "WHERE Plate.FK_Library__Name=Library_Name
                                                       AND (Plate.FK_Pipeline__ID = $self->{pipeline} OR (Plate_Schedule.FK_Pipeline__ID = $self->{pipeline} AND Plate.Plate_ID = Plate.FKOriginal_Plate__ID))
                                                       AND Plate.Plate_Status ='Active'
                                                       AND Plate.Failed = 'No'
                                                       AND $condition_string
                                                       GROUP BY Plate_ID
                                                       HAVING Pipeline_Protocol_Preps = 0",
            -debug => $debug
        );

        ## find plates that have not been in this protocol and are marked for this pipeline
        ## or parent pipeline (if user chose to include parent pipelines)

        @ready_plates = sort @{ set_difference( \@pipeline_plates, [ @{$transferred}, @{$in_progress}, @{$completed} ] ) };
        ## add additional pipeline filtering
    }

    ## call the api to retrieve the list of plates

    return \@ready_plates;
}

# ============================================================================
# Method     : get_progress()
# Usage      :
# Purpose    : Get the plates that are in the middle of a given protocol
# Returns    : List of Plate ID's as Array Reference
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : Must be run AFTER get_completed - Use via wrapper get_progress instead.
# See Also   : n/a
# ============================================================================
sub get_progress {
#################################
    my $self              = shift;
    my %args              = filter_input( \@_ );
    my $exclude_transfers = $args{-exclude_transfers};
    my $condition         = Cast_List( -list => $args{-condition}, -to => 'arrayref' ) || [];

    push @{$condition}, @{ $self->{library_condition} } if ( $self->{library_condition} );

    my $prep_status = $self->get_protocol_progress(
        -protocol        => $self->{protocol_id},
        -pipeline        => $self->{pipeline},
        -extra_condition => $condition
    );

    $self->{in_progress_plates} = $prep_status->{ $self->{protocol_id} }{'In Progress'};
    $self->{failed_plates}      = $prep_status->{ $self->{protocol_id} }{'Failed Plates'};
    $self->{transferred_plates} = $prep_status->{ $self->{protocol_id} }{'Transferred'};
    $self->{completed_plates}   = $prep_status->{ $self->{protocol_id} }{'Completed'};
    $self->{ready_plates}       = $prep_status->{ $self->{protocol_id} }{'Ready'};
    $self->{redo_plates}        = $prep_status->{ $self->{protocol_id} }{'Redo'} || [];
    $self->{repeat_plates}      = $prep_status->{ $self->{protocol_id} }{'Repeat'} || [];

    return;
}

# ============================================================================
# Method     : get_completed_plates()
# Usage      :
# Purpose    : Get the plates that have completed a given protocol
# Returns    : List of Plate ID's as Array Reference
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub get_completed_plates {
##############################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my @condition = Cast_List( -list => $args{-condition}, -to => 'array' );
    ## find the plates that have a completed protocol step
    #if ($self->{completed_plates}) { return $self->{completed_plates} } ## use as accessor ##

    push @condition, @{ $self->{library_condition} } if ( $self->{library_condition} );

    #push @condition, "FK_Pipeline__ID = $self->{pipeline}";
    #push @condition, "FKLast_Prep__ID = Prep_ID";
    #push @condition, "Prep_Name = 'Completed Protocol'";
    #push @condition, "Lab_Protocol_ID = FK_Lab_Protocol__ID";
    #push @condition, "FK_Lab_Protocol__ID = $self->{protocol_id}";

    #my $completed_condition = join ' AND ', @condition;

    #my @completed_plates = $self->{dbc}->Table_find('Plate,Prep,Lab_Protocol','Plate_ID',"WHERE $completed_condition",-group_by=>'Plate_ID',-distinct=>1);

    push @condition, "FK_Pipeline__ID = $self->{pipeline}";
    push @condition, "FK_Plate__ID = Plate_ID";
    push @condition, "FK_Prep__ID = Prep_ID";
    push @condition, "Prep_Name = 'Completed Protocol'";
    push @condition, "Lab_Protocol_ID = FK_Lab_Protocol__ID";
    push @condition, "FK_Lab_Protocol__ID = $self->{protocol_id}";

    my $completed_condition = join ' AND ', @condition;
    my @completed_plates = $self->{dbc}->Table_find( 'Plate,Plate_Prep,Prep,Lab_Protocol', 'Plate_ID', "WHERE $completed_condition", -group_by => 'Plate_ID', -distinct => 1 );

    #This is getting all the plates that has a prep records for the next protocol
    #If a plate already has a prep in the next protocol, it will be track by the next protocol, therefore can skip for the current protocol
    #This is here for that fact that more preps can already be done on the plate after it "Completed Protocol" for the current protcol
    #If this is not here, there will be extra ready
    my @next_protocols = $self->{dbc}->Table_find( 'Pipeline_Step', 'Object_ID',
        "WHERE FK_Pipeline__ID = $self->{pipeline} AND Pipeline_Step_Order IN (SELECT Pipeline_Step_Order + 1 FROM Pipeline_Step WHERE FK_Pipeline__ID = $self->{pipeline} AND Object_ID = $self->{protocol_id})" );
    if (@next_protocols) {
        my $next_protocol = join( ",", @next_protocols );
        my @next_condition;
        push @next_condition, "FK_Pipeline__ID = $self->{pipeline}";
        push @next_condition, "FK_Plate__ID = Plate_ID";
        push @next_condition, "FK_Prep__ID = Prep_ID";
        push @next_condition, "Lab_Protocol_ID = FK_Lab_Protocol__ID";
        push @next_condition, "FK_Lab_Protocol__ID IN ($next_protocol)";

        my $next_completed_condition = join ' AND ', @next_condition;
        my @next_completed_plates = $self->{dbc}->Table_find( 'Plate,Plate_Prep,Prep,Lab_Protocol', 'Plate_ID', "WHERE $next_completed_condition", -group_by => 'Plate_ID', -distinct => 1 );

        #if there are preps from the next protocol for the plate, then the plate can be tracked by the next protocol
        @completed_plates = @{ set_difference( \@completed_plates, \@next_completed_plates ) };
    }

    $self->{completed_plates} = \@completed_plates;
    return \@completed_plates;
}

#########################################
sub build_pipeline_step_condition {
#########################################
    my $self = shift;
    my %args = @_;

    my $state = $args{-state};
    my @pipeline_step_condition;

    foreach my $parameter ( keys %{ $self->{pipeline_step_conditions}->{$state} } ) {
        my $values = Cast_List( -list => $self->{pipelines_step_conditions}->{$state}{$parameter}, -to => 'String', -autoquote => 1 );
        if ($values) {
            push @pipeline_step_condition, "$parameter IN ($values)";
        }
    }
    return \@pipeline_step_condition;
}

sub parse_pipeline_step_condition {
    my $self = shift;

    foreach my $state ( keys %{ $self->{pipeline_step_conditions} } ) {
        foreach my $parameter ( keys %{ $self->{pipeline_step_conditions}->{$state} } ) {
            my $value = param($parameter);
            $self->{pipeline_step_condition}{$state}{$parameter} = $value;
        }
    }

}

# ============================================================================
# Method     : display_pipeline_step()
# Usage      :
# Purpose    : Display the status of plates given the protocol
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub display_pipeline_step {
################################
    my $self            = shift;
    my %args            = filter_input( \@_ );
    my @condition       = Cast_List( -list => $args{-condition}, -to => 'array' );
    my $display_actions = $args{-display_actions};
    my $dbc             = $self->{dbc} || $args{-dbc};

    # get the protocol name to display in the table
    my $protocol_id = $self->{protocol_id};
    my ($protocol_name) = $self->{dbc}->Table_find( "Lab_Protocol", "Lab_Protocol_Name", "WHERE Lab_Protocol_ID = $protocol_id" );
    $protocol_name = "Protocol Name" unless $protocol_name;

    $self->get_progress( -condition => \@condition );    ## populate completed_plates, ready_plates etc attributes.

    #	my $completed_plates = $self->{completed_plates};
    #	my $in_progress_plates = $self->{in_progress_plates};
    my @ready_plates       = @{ _get_plate_information( -dbc => $self->{dbc}, -plates_ref => $self->{ready_plates} ) };
    my @repeat_plates      = @{ _get_plate_information( -dbc => $self->{dbc}, -plates_ref => $self->{repeat_plates} ) };
    my @redo_plates        = @{ _get_plate_information( -dbc => $self->{dbc}, -plates_ref => $self->{redo_plates} ) };
    my @in_progress_plates = @{ _get_plate_information( -dbc => $self->{dbc}, -plates_ref => $self->{in_progress_plates} ) };
    my @completed_plates   = @{ _get_plate_information( -dbc => $self->{dbc}, -plates_ref => $self->{completed_plates} ) };
    my @transferred_plates = @{ _get_plate_information( -dbc => $self->{dbc}, -plates_ref => $self->{transferred_plates} ) };

    my $ready_plates       = organize_plate_list( -plate_list => \@ready_plates );
    my $repeat_plates      = organize_plate_list( -plate_list => \@repeat_plates );
    my $redo_plates        = organize_plate_list( -plate_list => \@redo_plates );
    my $in_progress_plates = organize_plate_list( -plate_list => \@in_progress_plates );
    my $completed_plates   = organize_plate_list( -plate_list => \@completed_plates );
    my $transferred_plates = organize_plate_list( -plate_list => \@transferred_plates );
    my $action_buttons     = $self->_plate_action_buttons();

    my $procedure_summary_table = HTML_Table->new( -class => 'small', -title => "$protocol_name", -toggle => 0 );

    my @headers = (
        Show_Tool_Tip( num_count( \@ready_plates ) . ' Ready',   "These Plates have completed the previous protocol, but have not begun this protocol yet" ),
        Show_Tool_Tip( num_count( \@redo_plates ) . ' Redo',     "" ),
        Show_Tool_Tip( num_count( \@repeat_plates ) . ' Repeat', "" ),

        #	       Show_Tool_Tip(num_count(\@transferred_plates) . ' Transferred',"These plates have been Aliquoted or Transferred to Daughter plates at least once within this protocol"),
        Show_Tool_Tip( num_count( \@in_progress_plates ) . ' In Progress', "These plates have begun this protocol, but have not yet completed it yet" ),
        Show_Tool_Tip( num_count( \@completed_plates ) . ' Completed',     "These plates have completed this protocol, but have not yet entered the next protocol" )
    );
    $procedure_summary_table->Set_Headers( \@headers, 'bgcolor=CCCCFF' );

    $procedure_summary_table->Set_Column($ready_plates);
    $procedure_summary_table->Set_Column($redo_plates);
    $procedure_summary_table->Set_Column($repeat_plates);

    #$procedure_summary_table->Set_Column($transferred_plates);
    $procedure_summary_table->Set_Column($in_progress_plates);
    $procedure_summary_table->Set_Column($completed_plates);
    my $pipeline_step_form = alDente::Form::start_alDente_form( $dbc, "$protocol_name", $dbc->homelink() );

    $pipeline_step_form .= $action_buttons if $display_actions;
    $pipeline_step_form .= $procedure_summary_table->Printout(0);
    $pipeline_step_form .= end_form();

    return $pipeline_step_form;
}

#
# simple wrapper for method above to get array count, while excluding arrays with 'No result' as the only entry
#
##################
sub num_count {
##################
    my $array = shift;

    if ( $array->[0] =~ /[1-9]/ ) {
        return int(@$array);
    }
    else {
        return 0;
    }
}

# ============================================================================
# Method     : _plate_action_buttons()
# Usage      :
# Purpose    : Display the available action buttons
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub _plate_action_buttons {
    my $self = shift;

    my $output = hidden( -name => 'cgi_application', -value => 'alDente::Container_App', -force => 1 );
    my $plate_action_buttons = HTML_Table->new( -title => "Available Actions" );
    my $reprint_button = submit( -name => 'rm', -value => 'Re-Print Plate Labels', -class => 'Std' );
    my $throw_away     = submit( -name => 'rm', -value => 'Throw Out Plates',      -class => 'Action' );
    my $save_plate_set = submit( -name => 'rm', -value => 'Save Plate Set',        -class => "Action" );
    my $reset_pipeline = submit(
        -name    => 'rm',
        -value   => 'Reset Pipeline',
        -class   => "Action",
        -onClick => "unset_mandatory_validators(this.form);
                            document.getElementById('Reset_Pipeline_Validator').setAttribute('mandatory',1);
                            return validateForm(this.form);"
    ) . ' to: ' . &alDente::Tools::search_list( -dbc => $self->{dbc}, -name => 'FK_Pipeline__ID', -mode => 'popup' ) . set_validator( -name => 'FK_Pipeline__ID Choice', -mandatory => 1, -id => 'Reset_Pipeline_Validator' );

    $plate_action_buttons->Set_Row( [ $reprint_button, $throw_away, $save_plate_set, $reset_pipeline ] );

    $output .= $plate_action_buttons->Printout(0);
    return $output;
}

sub organize_plate_list {
    my %args       = @_;
    my $plate_list = $args{-plate_list};
    my @plate_list;
    @plate_list = @{$plate_list} if $plate_list;
    my %sorted_plates;
    foreach my $plate (@plate_list) {
        my $folder_name;
        if ( $plate =~ /\:\s+(\w+)\-(\d+)/i ) {
            $folder_name = "$1";
            push @{ $sorted_plates{$folder_name} }, $plate;
        }

    }
    my @organized_plate_list;
    foreach my $sorted_list ( sort keys %sorted_plates ) {
        push @organized_plate_list, create_tree( -tree => { "$sorted_list" => $sorted_plates{$sorted_list} }, -print => 0 );
    }
    return \@organized_plate_list;
}

sub _get_plate_information {
    my %args      = filter_input( \@_, -args => 'dbc,plates_ref,check_box,brief' );
    my $dbc       = $args{-dbc};
    my $plates    = $args{-plates_ref};
    my $check_box = 1;
    $check_box = $args{-check_box} if defined( $args{-check_box} );
    my $brief = 0;
    $brief = $args{-brief} if ( $args{-brief} );
    my @plates = @{$plates} if $plates;
    my @results;

    if (@plates) {
        my $plate_string = join ',', @plates;
        my @plate_info = $dbc->Table_find( 'Plate', "Concat('Pla',Plate_ID,': ',FK_Library__Name,'-',Plate_Number,Parent_Quadrant)", "WHERE Plate_ID IN ($plate_string) order by FK_Library__Name,Plate_Number,Parent_Quadrant,Plate_ID" );
        @plate_info = map { s/\,*$//; $_ } @plate_info;

        foreach my $plate (@plate_info) {
            my $plate_id;
            if ( $plate =~ /^\D*(\d+):/ ) { $plate_id = $1; }
            my $link = &Link_To( $dbc->config('homelink'), "$plate", "&cgi_application=alDente::Scanner_App&rm=Scan&Barcode=$Prefix{Plate}$plate_id" );
            if ($check_box) {
                $link = checkbox( -name => 'FK_Plate__ID', -value => $plate_id, -label => '' ) . $link;
            }
            push( @results, $link );
        }
    }
    else {
        if ($brief) {
            @results = ();
        }
        else {
            @results = ('No results');
        }
    }
    return \@results;
}

sub _get_library_plate_name {
    my %args       = filter_input( \@_ );
    my $input_name = $args{-input_name};
    my $folder_name;
    if ( $input_name =~ /\:\s+(\w+)\-(\d+)/i ) {
        $folder_name = "$1-$2";
    }
    return $folder_name;
}

# ============================================================================
# Method     : display_protocol_actions()
# Usage      :
# Purpose    : Display the actions that are available for plates in the protocol, i.e. Save Plate Set, Print Barcodes, Throw Away
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================
sub display_pipeline_step_actions {
    my $self = shift;

    return;
}

#################
sub load_API {
#################
    my $self = shift;

    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $api  = $args{-API_module} || $self->{config}{API_module} || "alDente::alDente_API";
    my $path = $args{-API_path} || $self->{config}{API_path};                                 ## <CONSTRUCTION> - get config path ..

    eval { require $api };
    $self->{API} = $api->new(
        -dbc   => $dbc,
        -dbase => $dbc->{dbase},
        -host  => $dbc->{host},
        -user  => $self->{user},
    );
    if ( $self->{API} ) {
        $self->{API_loaded} = 1;
    }
    else {
        $self->{API_loaded} = 0;
    }

    return $self->{API_loaded};
}

sub start {
    my $this      = shift;
    my $protocol  = shift;
    my $plate_set = shift;
    my ($class) = ref($this) || $this;
    my ($self) = {};

    $self->{protocol}    = $protocol;
    $self->{set_number}  = $plate_set;
    $self->{status}      = 0;
    $self->{Plates}      = [];
    $self->{CurrentStep} = 0;
    $self->{NextStep}    = 0;

    bless $self, $class;

    return $self;
}

##############################
# public_functions           #
##############################
########################
#
# Check if this step is a transfer step. (Aliquot, Transfer, Pool, or Split..)
#  If it is, perform the appropriate transfer and generate the new plate ids.
#
#  required:  step name (eg. 'Transfer to 96-well Beckman')
#             current_plates.
#
#
##########################
sub new_plate {
##########################
    #
    my %args      = &filter_input( \@_, -args => 'step', -mandatory => 'step' );
    my $step      = $args{-step};
    my $include   = $args{-include};                                               ## may be used to include extra options like 'Pre-Print' if required ##
    my $step_type = $args{-step_type};
    my $exclude   = $args{-exclude};                                               ## may be used to exclude options like 'Setup' if required ##
    my $new_focus = $args{-new_focus};                                             ## only return true if we are changing focus

    my @include_steps;
    @include_steps = Cast_List( -list => $include, -to => 'array' ) if $include;

    #	my @transfers = qw(Transfer Aliquot Pool Split Pre-Print Setup Extract); ### Default transfers

    my @transfers = qw(Transfer Aliquot Pool Split Setup Extract);                 ### Default transfers  ## Pre-print is NOT a Transfer step
    if ($step_type) {
        ## Overwrite transfer types if specified
        @transfers = Cast_List( -list => $step_type, -to => 'array' );
    }
    push @transfers, @include_steps if $include;

    my @exclude_steps;
    @exclude_steps = Cast_List( -list => $exclude, -to => 'array' ) if $exclude;
    @transfers = @{ set_difference( \@transfers, \@exclude_steps ) };

    my $transfer_steps = join( '|', @transfers );

    my %step_info;

    if ($step =~ /^
	($transfer_steps)\s+     ## special cases
	(\#\d+\s)?                           ## optional for multiple steps with similar name (eg Transfer #2 to ..)
	([\s\w\-]*?)                          ## optional new extraction type
	\b(out\s)?to\s                        ## ... to .. (type)
	([\s\w\.\-]+)                        ## mandatory target type
	(.*)              ## special cases for suffixes (optional)
	$/xi
        )
    {

        my $xfer_method = $1;
        my $instance    = $2;
        my $sample_type = $3;
        my $focus       = $4;
        my $format      = $5;
        my $new_sample  = $6;

        my %step_info;
        $step_info{'transfer_method'} = $xfer_method;
        $step_info{'instance_num'}    = $instance;
        $step_info{'new_sample_type'} = chomp_edge_whitespace($sample_type);

        if ( $focus =~ /out/ ) {
            $step_info{'focus'} = 'source';    ## stay focused on original tubes/plates
            if ($new_focus) { return undef }   ## only if we ask to test for a new focus
        }
        else {
            $step_info{'focus'} = 'target';    ## move focus to target tubes/plates
        }
        $step_info{'new_format'}       = &chomp_edge_whitespace($format);
        $step_info{'track_new_sample'} = $new_sample;

        #	print HTML_Dump \%step_info;
        return $format, \%step_info;
    }
    else {
        return undef;
    }
}

#############################
sub get_protocol_progress {
#############################
    my $self               = shift;
    my %args               = filter_input( \@_, -args => 'protocol,pipeline,extra_condition' );
    my $protocol           = $args{-protocol};                                                    ##
    my $pipeline           = $args{-pipeline};
    my $debug              = $args{-debug} || 0;
    my @extra_condition    = Cast_List( -list => $args{-extra_condition}, -to => 'array' );
    my @pipeline_condition = ();
    my $pipeline_cond;

    if ($pipeline) {
        my $pipeline_list = Cast_List( -list => $pipeline, -to => 'String' );

        #push @pipeline_condition, "Plate.FK_Pipeline__ID IN ($pipeline_list) AND (Child.FK_Pipeline__ID IS NULL OR Child.FK_Pipeline__ID in ($pipeline_list))";
        push @pipeline_condition, "Plate.FK_Pipeline__ID IN ($pipeline_list) ";
        $pipeline_cond = "FK_Pipeline__ID IN ($pipeline_list)";
    }
    my @protocol_condition = ();
    my $protocol_cond      = '1';
    my $extra_left_join;
    my @protocols = Cast_List( -list => $protocol, -to => 'Array' );
    if ($protocol) {
        my $protocol_list = Cast_List( -list => $protocol, -to => 'String' );
        push @protocol_condition, "FK_Lab_Protocol__ID IN ($protocol_list)";
        $protocol_cond .= " AND Object_ID IN ($protocol_list)";

        #if protocol is the first step of the pipeline, add Plate_Schedule to extra left join and add new pipeline condition
        #my $current_protocol_step_id = $self->{dbc}->Table_find( 'Pipeline_Step', 'Pipeline_Step_Order', "WHERE Pipeline_Step_ID = $self->{pipeline_step_id}", -debug => $debug );
        my $current_protocol_step_id = $self->{dbc}->Table_find( 'Pipeline_Step', 'Pipeline_Step_Order', "WHERE $pipeline_cond AND $protocol_cond", -debug => $debug );
        if ( $current_protocol_step_id == 1 ) {
            $extra_left_join = "LEFT JOIN Plate_Schedule ON Plate.Plate_ID = Plate_Schedule.FK_Plate__ID";
            my $extra_pipeline_condition = pop @pipeline_condition;
            $extra_pipeline_condition = "($extra_pipeline_condition OR (Plate_Schedule.FK_Pipeline__ID = $self->{pipeline} AND Plate.Plate_ID = Plate.FKOriginal_Plate__ID))";
            push @pipeline_condition, $extra_pipeline_condition;
        }
    }
    my $conditions = join( ' AND ', @pipeline_condition, @extra_condition, @protocol_condition );

    #    my %prep_status = $self->{dbc}->Table_retrieve('Plate,Prep,Library,Lab_Protocol
    #                                                    LEFT JOIN Plate as Child ON (Child.FKParent_Plate__ID = Plate.Plate_ID)',
    #                                                   ['Plate.Plate_ID','Plate.Plate_Status','Child.Plate_Status as Child_Status','Prep_Name','Child.Plate_ID as Child','Lab_Protocol_ID','Child.FK_Branch__Code as Child_Branch'],
    #						   "WHERE Plate.FK_Library__Name = Library_Name and
    #                                                    FK_Lab_Protocol__ID = Lab_Protocol_ID
    #                                                    and Lab_Protocol_Name <> 'Standard'
    #                                                    and Prep.Prep_ID = Plate.FKLast_Prep__ID AND
    #                                                    $conditions GROUP BY Plate.Plate_ID,Child.Plate_ID"
    #						   ,-key=>'Lab_Protocol_ID');

    my %prep_status = $self->{dbc}->Table_retrieve(
        "Plate,Plate_Prep,Prep,Library,Lab_Protocol
                                                    LEFT JOIN Plate as Child ON (Child.FKParent_Plate__ID = Plate.Plate_ID)
                                                    $extra_left_join",
        [   'Plate.Plate_ID',                        'Plate.Plate_Status', 'Plate.Failed',            'Child.Plate_Status as Child_Status',
            'Child.Failed as Child_Failed',          'Prep_Name',          'Child.Plate_ID as Child', 'Lab_Protocol_ID',
            'Child.FK_Branch__Code as Child_Branch', 'Child.FK_Pipeline__ID as Child_Pipeline'
        ],
        "WHERE Plate.FK_Library__Name = Library_Name and
                                                    Plate_Prep.FK_Plate__ID = Plate.Plate_ID and 
                                                    Plate_Prep.FK_Prep__ID = Prep_ID and
                                                    FK_Lab_Protocol__ID = Lab_Protocol_ID and
                                                    Lab_Protocol_Name <> 'Standard' AND
                                                    $conditions ORDER BY Prep_DateTime DESC, Prep_ID DESC"
        ,
        -key   => 'Lab_Protocol_ID',
        -debug => $debug
    );

    #This is getting all the plates that has a prep records for the next protocol
    #If a plate already has a prep in the next protocol, it will be track by the next protocol, therefore can skip for the current protocol
    #This is here for that fact that more preps can already be done on the plate after it "Completed Protocol" for the current protcol
    #If this is not here, there will be many more unnessary Completed/Repeat
    my %next_protocol_plate_hash;
    my @next_protocols = $self->{dbc}->Table_find( 'Pipeline_Step', 'Object_ID', "WHERE $pipeline_cond AND Pipeline_Step_Order IN (SELECT Pipeline_Step_Order + 1 FROM Pipeline_Step WHERE $pipeline_cond AND $protocol_cond)", -debug => $debug );
    if (@next_protocols) {
        my $next_protocol = join( ",", @next_protocols );

        #my $next_conditions = join(' AND ', @pipeline_condition, @extra_condition, ("FK_Lab_Protocol__ID IN ($next_protocol)"));
        my $next_conditions = join( ' AND ', ("$pipeline_cond"), @extra_condition, ("FK_Lab_Protocol__ID IN ($next_protocol)") );
        my %next_prep_status = $self->{dbc}->Table_retrieve(
            'Plate,Plate_Prep,Prep,Library,Lab_Protocol',
            ['Plate_ID'],
            "WHERE Plate.FK_Library__Name = Library_Name and
                                                              Plate_Prep.FK_Plate__ID = Plate.Plate_ID and
                                                              Plate_Prep.FK_Prep__ID = Prep_ID and
                                                              FK_Lab_Protocol__ID = Lab_Protocol_ID and
                                                              Lab_Protocol_Name <> 'Standard' AND
                                                              $next_conditions Group By Plate_ID"
            , -debug => $debug
        );
        %next_protocol_plate_hash = map { $_ => 1; } grep {$_} @{ $next_prep_status{Plate_ID} };
    }

    foreach my $lab_protocol (@protocols) {
        $prep_status{$lab_protocol}{'Completed'}     = [];
        $prep_status{$lab_protocol}{'In Progress'}   = [];
        $prep_status{$lab_protocol}{'Failed Plates'} = [];
        $prep_status{$lab_protocol}{'Transferred'}   = [];
        my $data = $prep_status{$lab_protocol};

        my $index = 0;
        my %child_plate_status;
        my %processed_plate_ID;
        while ( defined $data->{Plate_ID}[$index] ) {
            my $plate_id = $data->{Plate_ID}[$index];

            #If a plate already has a prep in the next protocol, it will be track by the next protocol, therefore can skip for the current protocol
            if ( $next_protocol_plate_hash{$plate_id} ) {
                $index++;
                next;
            }

            my $child_id       = $data->{Child}[$index];
            my $child_status   = $data->{Child_Status}[$index];
            my $child_failed   = $data->{Child_Failed}[$index];
            my $child_branch   = $data->{Child_Branch}[$index];
            my $child_pipeline = $data->{Child_Pipeline}[$index];
            my $pipeline_list  = Cast_List( -list => $pipeline, -to => 'String' );

            #Not checking for child's pieline because a child can be moved to another pipeline and the parent need to be in repeat
            #if ($child_id && $child_pipeline eq $pipeline_list) {
            if ($child_id) {

                if ( $child_failed eq 'No' ) {
                    if ( $child_status ne 'Pre-Printed' ) {
                        push @{ $child_plate_status{Repeat}{$child_branch} }, $plate_id;    #if !grep({$_ eq $plate_id} @{$child_plate_status{Repeat}});
                    }
                }
                else {
                    push @{ $child_plate_status{Redo}{$child_branch} }, $plate_id;          #if !grep({$_ eq $plate_id} @{$child_plate_status{Redo}});
                }
            }

            #Not checking for child's pieline because a child can be moved to another pipeline and the parent shouldn't be in progress
            #Howver this segment of code is useful if we need to assign one plate to two different pipelines
            #i.e. this code is checking if child exist for this pipeline

            #already process the plate for the lastest prep in the protocol, no need to do any more work
            #(i.e. getting the last prep from Plate_Prep by ordering Prep_DateTime descendingly)
            if ( $processed_plate_ID{$plate_id} ) {
                $index++;
                next;
            }

            my $prep_name = $data->{Prep_Name}[$index];
            my $failed = $data->{Failed}[$index] eq 'Yes' ? 1 : 0;

            if ( $prep_name eq 'Completed Protocol' ) {
                ## Completed
                push @{ $prep_status{$lab_protocol}{'Completed'} }, $plate_id if !grep( { $_ eq $plate_id } @{ $prep_status{$lab_protocol}{'Completed'} } );
            }
            elsif ( ( !$child_id || $child_status eq 'Pre-Printed' ) && $prep_name ne 'Completed Protocol' ) {
                ## In progress
                push @{ $prep_status{$lab_protocol}{'In Progress'} }, $plate_id if !grep( { $_ eq $plate_id } @{ $prep_status{$lab_protocol}{'In Progress'} } );
            }
            elsif ($failed) {
                push @{ $prep_status{$lab_protocol}{'Failed Plates'} }, $plate_id if !grep( { $_ eq $plate_id } @{ $prep_status{$lab_protocol}{'Failed Plates'} } );
            }
            else {
                ## Transferred
                push @{ $prep_status{$lab_protocol}{'Transferred'} }, $plate_id if !grep( { $_ eq $plate_id } @{ $prep_status{$lab_protocol}{'Transferred'} } );
            }
            $processed_plate_ID{$plate_id} = 1;
            $index++;
        }

        my @overall_redo;
        foreach my $branch ( keys %{ $child_plate_status{Redo} } ) {

            #There is a fail child for the branch already, check to see if there is an unfail child for the branch and if there isn't then it is a redo
            my $redo_plates = set_difference( $child_plate_status{Redo}{$branch}, $child_plate_status{Repeat}{$branch} );

            #Make sure no duplicate
            foreach my $redo_plate ( @{$redo_plates} ) {
                push @overall_redo, $redo_plate if !grep( { $_ eq $redo_plate } @overall_redo );
            }
        }
        my @overall_repeat;
        foreach my $branch ( keys %{ $child_plate_status{Repeat} } ) {

            #if a plate is already classify as a redo, then the plate can't be a repeat
            my $repeat_plates = set_difference( $child_plate_status{Repeat}{$branch}, \@overall_redo );

            #Make sure no duplicate
            foreach my $repeat_plate ( @{$repeat_plates} ) {
                push @overall_repeat, $repeat_plate if !grep( { $_ eq $repeat_plate } @overall_repeat );
            }
        }

        #$child_plate_status{Redo}= set_difference($child_plate_status{Redo},$child_plate_status{Repeat});
        $prep_status{$lab_protocol}{'Ready'} = $self->get_ready_plates(
            -condition          => \@extra_condition,
            -transferred        => $prep_status{$lab_protocol}{'Transferred'},
            -in_progress        => $prep_status{$lab_protocol}{'In Progress'},
            -failed             => $prep_status{$lab_protocol}{'Failed Plates'},
            -completed          => $prep_status{$lab_protocol}{'Completed'},
            -child_plate_status => \%child_plate_status
        );

        $prep_status{$lab_protocol}{'Redo'}   = \@overall_redo;      #$child_plate_status{Redo};
        $prep_status{$lab_protocol}{'Repeat'} = \@overall_repeat;    #$child_plate_status{Repeat};
    }
    return \%prep_status;
}

#
# Retrieve valid protocols given a list of plates or plate_set
#
#
###############################
sub get_protocol_options {
###############################
    my %args        = filter_input( \@_, -args => 'dbc' );
    my $dbc         = $args{-dbc};
    my $set         = $args{-set};
    my $plate_ids   = $args{-plate_ids} || $args{-plate_id};
    my $format      = $args{'-format'};                        ## returns id by default (set format=>'name' to return lab protocol names (or field_reference)
    my $include_dev = $args{-include_dev};                     # flag to include under development protocols ( should be for TechD only )
    my $debug       = $args{-debug};

    if ($set) {
        $plate_ids = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number = '$set'", -distinct => 1 );
    }

    $plate_ids ||= 0;

    my @pipelines = $dbc->Table_find( 'Plate', 'FK_Pipeline__ID', "WHERE Plate_ID IN ($plate_ids)", -distinct => 1 );
    my @visible_protocols = visible_protocols( $dbc, \@pipelines, -include_dev => $include_dev, -debug => $debug );    ## pipelines visible to all plates in this group
    if ($debug) {
        print HTML_Dump "pipelines:",         \@pipelines;
        print HTML_Dump "visible protocols:", \@visible_protocols;
    }

    my @unlinked = $dbc->Table_find( 'Lab_Protocol,Object_Class LEFT JOIN Pipeline_Step ON Object_ID=Lab_Protocol_ID AND FK_Object_Class__ID=Object_Class_ID', 'Lab_Protocol_ID', "WHERE Object_Class = 'Lab_Protocol' AND Pipeline_Step_ID IS NULL" );
    if (@unlinked) {
        push @visible_protocols, @unlinked;
    }

    my $pids = join ',', @visible_protocols;

    if ($pids) {
        ## filter on accessible groups if applicable ##
        my $grps = $dbc->get_local('group_list');
        $pids = join ',',
            $dbc->Table_find( 'Lab_Protocol LEFT JOIN GrpLab_Protocol ON FK_Lab_Protocol__ID=Lab_Protocol_ID', 'Lab_Protocol_ID', "WHERE Lab_Protocol_ID IN ($pids) AND (FK_Grp__ID IN ($grps) OR FK_Grp__ID IS NULL)", -distinct => 1, -debug => $debug );

        ## reset visible protocols ##
        @visible_protocols = split ',', $pids;
    }
    else {
        $pids = '0';
    }
    if ( @visible_protocols && $format =~ /reference/i ) {
        my @list = $dbc->get_FK_info( 'FK_Lab_Protocol__ID', $pids, -condition => "WHERE Lab_Protocol_ID IN ($pids)", -debug => $debug );
        return @list;
    }
    elsif ( @visible_protocols && $format =~ /name/i ) {
        my @list = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_Name', "WHERE Lab_Protocol_ID IN ($pids)", -debug => $debug );
        return @list;

    }
    else {
        return @visible_protocols;
    }
}

#
# Retrieve visible protocols given a list of pipelines
#
###########################
sub visible_protocols {
###########################
    my %args        = filter_input( \@_, -args => 'dbc,pipeline' );
    my $dbc         = $args{-dbc};
    my $pipelines   = $args{-pipeline};
    my $condition   = $args{-condition} || 1;
    my $or          = $args{ -or };                                   ## include protocols that are in ANY of the pipelines supplied (rather than all by default)
    my $include_dev = $args{-include_dev};                            # flag to include under development protocols ( should be for TechD only )
    my $debug       = $args{-debug};

    my $found_pipelines  = 0;
    my $common_protocols = [];

    if ($or) {
        ## pull up all applicable protocol in ANY of the list given... ##
        $found_pipelines = join ',', @$pipelines;
        my @protocols = $dbc->Table_find( 'Pipeline_Step,Object_Class', 'Object_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Lab_Protocol' AND FK_Pipeline__ID IN ($found_pipelines)" );

        my @more_protocols;
        my @daughter_pipelines = $dbc->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE FKParent_Pipeline__ID IN ($found_pipelines)" );
        if (@daughter_pipelines) {
            @more_protocols = visible_protocols( $dbc, \@daughter_pipelines, -or => 1 );
        }
        $common_protocols = RGmath::union( \@protocols, \@more_protocols );
    }
    else {
        ## protocols need to be in ALL pipelines supplied (for cases of multiple plates scanned) ##
        foreach my $pipeline (@$pipelines) {
            if ( !$pipeline ) {next}
            $found_pipelines++;
            my @daughter_pipelines = $dbc->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE FKParent_Pipeline__ID = $pipeline" );
            my @protocols = $dbc->Table_find( 'Pipeline_Step,Object_Class', 'Object_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Lab_Protocol' AND FK_Pipeline__ID = '$pipeline'" );

            my @more_protocols = ();
            if (@daughter_pipelines) {
                @more_protocols = visible_protocols( $dbc, \@daughter_pipelines, -or => 1 );
            }

            if ( !@protocols && !@more_protocols ) {next}    ## #Message("nothing for $pipeline"); next; }

            if ( ( $found_pipelines > 1 ) && !$or ) {
                ($common_protocols) = RGmath::intersection( [ @protocols, @more_protocols ], $common_protocols );
            }
            else {
                $common_protocols = RGmath::union( \@protocols, \@more_protocols );
            }
        }
    }

    if ($found_pipelines) {
        my $protocol_list = join ',', @$common_protocols;
        $protocol_list ||= '0';
        $condition .= " AND Lab_Protocol_ID IN ($protocol_list)";
    }

    if   ($include_dev) { $condition .= " AND Lab_Protocol_Status in ('Active', 'Under Development') " }
    else                { $condition .= " AND Lab_Protocol_Status in ('Active') " }

    my $groups = $dbc->get_local('group_list');
    my @protocols = $dbc->Table_find( 'Lab_Protocol,GrpLab_Protocol', 'Lab_Protocol_ID', "WHERE FK_Lab_Protocol__ID=Lab_Protocol_ID AND FK_Grp__ID IN ($groups) AND $condition", -debug => $debug );
    return @protocols;
}

###########################
sub next_pipeline_options {
###########################
    # Description:
    #   get pipeline options for a given pipeline(s)
    # Input:
    #	-pipeline	given pipeline(s)
    # output:
    #   a list of next pipeline options
    # <snip>
    # 	$next_pipelines->next_pipeline_options(-dbc => $dbc,-pipeline => $pipeline);
    # </snip>
####################################
    my %args        = filter_input( \@_, -mandatory => 'dbc,pipeline' );
    my $debug       = $args{-debug};
    my $pipeline    = $args{-pipeline};
    my $protocol_id = $args{-protocol};
    my $grp         = Cast_List( -list => $args{-grp}, -to => 'string' );
    my $dbc         = $args{-dbc};

    my @pipelines = Cast_List( -list => $pipeline, -to => 'array' );

    my @daughter_pipelines;

    if ( !$pipelines[0] ) {
        ## no parent pipelines defined ... allow user to choose any pipeline ##

        if ($protocol_id) {
            @daughter_pipelines = alDente::Pipeline::get_daughter_pipelines( -dbc => $dbc, -pipeline => $pipelines[0], -class => 'Lab_Protocol', -step => $protocol_id, -debug => $debug );
        }
        else {
            if ($grp) {
                @daughter_pipelines = @{ alDente::Grp::get_group_pipeline( -dbc => $dbc, -grp => $grp ) };
            }
            else {
                @daughter_pipelines = $dbc->Table_find( "Pipeline", "Pipeline_ID", "WHERE Pipeline_Type = 'Lab_Protocol'" );
            }
        }
    }
    else {
        @daughter_pipelines = alDente::Pipeline::get_daughter_pipelines( -dbc => $dbc, -pipeline => $pipelines[0], -class => 'Lab_Protocol', -step => $protocol_id, -debug => $debug );
        if ( int(@pipelines) == 1 ) {
            ## single parent pipeline... add daughter pipelines ##
            unshift @daughter_pipelines, $pipelines[0];
        }
        else {
            ## Multiple parent pipelines
            foreach my $i ( 1 .. $#pipelines ) {
                my @next_daughters = alDente::Pipeline::get_daughter_pipelines( -dbc => $dbc, -pipeline => $pipelines[$i], -class => 'Lab_Protocol', -step => $protocol_id, -debug => $debug );
                my ($intersection) = RGmath::intersection( \@next_daughters, \@daughter_pipelines );
                @daughter_pipelines = @$intersection;
                if ( int(@daughter_pipelines) == 0 ) { last; }
            }
        }
    }
    ## May wish to add 'first step' pipelines if this is a 'last step' pipeline (?) ##

    return @daughter_pipelines;
}

###############
sub new_protocol {
###############
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->param('dbc');
    my $protocol    = $args{-protocol};
    my $status      = $args{-status} || 'Under Development';
    my $description = $args{-description} || '';
    my $user_id     = $dbc->get_local('user_id');

    my @groups;
    @groups = @{ $args{-group_ids} } if ( $args{-group_ids} );
    my $protocol_id;
    my $date = today();

    eval {
        my $description = param('Protocol Description') || '';
        my $newid = $dbc->Table_append_array(
            'Lab_Protocol',
            [ 'Lab_Protocol_Name', 'FK_Employee__ID', 'Lab_Protocol_Status', 'Lab_Protocol_Description', 'Lab_Protocol_Modified_Date', 'Lab_Protocol_Created_Date' ],
            [ $protocol,           $user_id,          $status,               $description,               $date,                        $date ],
            -autoquote => 1
        );

        die("ERROR: Failed to add new protocol '$protocol'.") unless $newid;
        $protocol_id = $newid;
        my %values;

        # Associate protocol to user groups
        my $i;
        foreach my $group (@groups) {
            $values{ ++$i } = [ $group, $newid ];
        }
        my $new_ids = $dbc->smart_append(
            -tables    => 'GrpLab_Protocol',
            -fields    => [ 'FK_Grp__ID', 'FK_Lab_Protocol__ID' ],
            -values    => \%values,
            -autoquote => 1
        );
        die("ERROR: Failed to associate new protocol '$protocol' to groups.") unless $newid;
        Message("Added new Protocol: $protocol (Status: $status).");
    };

    Message($@) if $@;
    return $protocol_id;
}

###############################
# Description:
#	- This method creates a new protocol by copying from an existing protocol
#
# <snip>
#	Usage example:
#		my $new_id = $protocol_obj->copy_protocol( -dbc => $dbc, -protocol => $protocol, -admin => $admin, -new_name => $newname, -new_group => $newgroup, -state => $state );
#	Return:
#		Scalar. New Lab_Protocol_ID if success; 0 if failed.
# </snip>
###############################
#######################
sub copy_protocol {

    #
#######################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->param('dbc');
    my $protocol  = $args{-protocol};
    my $new_name  = $args{-new_name};
    my $new_group = $args{-new_group};
    my $state     = $args{-state};

    my $exists = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_Name', "WHERE Lab_Protocol_Name = '$new_name'" );

    if ($exists) {
        Message "Protocol $new_name already exists.  Please select a different name";
        return;
    }

    my ($protocol_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = '$protocol'" );

    my $copied;

    #First copy the protocol table
    ($copied) = $dbc->Table_copy( 'Lab_Protocol', "where Lab_Protocol_ID = $protocol_id", [ 'Lab_Protocol_ID', 'Lab_Protocol_Name', 'Lab_Protocol_Status' ], undef, [ undef, $new_name, $state ], -no_merge => 1 );
    die("Problem copying protocol.") unless $copied;
    Message("Added new $new_name Protocol (Status: $state).");
    my $new_id = $copied;

    ## The group association shouldn't be copied
    #Now copy the GrpLab_Protocol record
    #( my $copied ) = $dbc -> Table_copy( 'GrpLab_Protocol', "where FK_Lab_Protocol__ID = $protocol_id", [ 'GrpLab_Protocol_ID', 'FK_Lab_Protocol__ID' ], undef, [ undef, $new_id ], -no_merge => 1 );
    #die("Problem copying group permissions of protocol.") unless $copied;
    #Message("Group permissions of protocol copied.");
    my $new_group_id = $dbc->get_FK_ID( 'FK_Grp__ID', $new_group );
    my $ok = $dbc->Table_append_array( 'GrpLab_Protocol', [ 'FK_Grp__ID', 'FK_Lab_Protocol__ID', 'Grp_Access' ], [ $new_group_id, $new_id, 'Admin' ], -autoquote => 1 );
    if ( !$ok ) {
        $dbc->error("Error setting new group for $new_name");
    }

    #Now also copy the protocol steps
    ($copied) = $dbc->Table_copy( 'Protocol_Step', "where FK_Lab_Protocol__ID = $protocol_id", [ 'Protocol_Step_ID', 'FK_Lab_Protocol__ID' ], undef, [ undef, $new_id ], -no_merge => 1 );
    die("Problem copying protocol steps") unless $copied;
    Message("Protocol steps copied.");

    return $new_id;

}

#######################
sub get_Formatted_Values {
#######################
    my $self                = shift;
    my %args                = &filter_input( \@_ );
    my $dbc                 = $args{-dbc} || $self->param('dbc');
    my $plate_label_def     = $args{-plate_label_def};
    my $transfer_q          = $args{-transfer_q};
    my $transfer_q_unit     = $args{-transfer_q_unit} || 'ml';
    my $split_x             = $args{-split_x};
    my $quantity            = $args{-quantity};
    my $quantity_units      = $args{-quantity_units} || 'ml';
    my $sformat             = $args{-sformat};
    my $mformats_chosen_ref = $args{-mformats_chosen};
    my $prep_attr_name_ref  = $args{-prep_attr_name};
    my $prep_attr_def_ref   = $args{-prep_attr_def};
    my $plate_attr_name_ref = $args{-plate_attr_name};
    my $plate_attr_def_ref  = $args{-plate_attr_def};
    my $list_ref            = $args{-list};
    my $extra_inputs_ref    = $args{-extra_inputs};

    my @Input;
    my @Defaults;
    my @Formats;

    my @mformats_chosen, my @prep_attr_name, my @prep_attr_def, my @plate_attr_name, my @plate_attr_def, my @list, my @extra_inputs;
    @mformats_chosen = @$mformats_chosen_ref if $mformats_chosen_ref;
    @prep_attr_name  = @$prep_attr_name_ref  if $mformats_chosen_ref;
    @prep_attr_def   = @$prep_attr_def_ref   if $prep_attr_def_ref;
    @plate_attr_name = @$plate_attr_name_ref if $plate_attr_name_ref;
    @plate_attr_def  = @$plate_attr_def_ref  if $plate_attr_def_ref;
    @list            = @$list_ref            if $list_ref;
    @extra_inputs    = @$extra_inputs_ref    if $extra_inputs_ref;

    # the inputs and defaults must be formatted correctly in order for them to
    # be visualized on the barcode scanners
    if (@list) {
        $list[$#list] =~ /(\d+)/;
        my $reagents = $1;
        push( @Input, $list[$#list] );
        foreach my $x ( 1 .. $reagents ) {
            my $quant = param("Quantity $x") || '';
            push( @Input,    '' );
            push( @Defaults, $quant );
            push( @Formats,  '' );
        }
    }

    my %plate_attributes;
    my %prep_attributes;
    foreach my $input (@extra_inputs) {
        my $default = '';
        my $format  = '';

        if ( $input =~ /(FK_Equipment__ID)/ ) {
            $format = join '|', @mformats_chosen;    ## allow for multiple selections
            $format ||= '';
        }
        elsif ( $input =~ /FK_Plate__ID/ )  { }
        elsif ( $input =~ /(FK_Rack__ID)/ ) { }
        elsif ( $input =~ s/(FK_Solution__ID)/$1:Solution_Quantity/ ) {
            push( @Defaults, $default );
            $format = $sformat || '';
            push( @Formats, $format );
            $default = "$quantity$quantity_units";
            $format  = '';                           #resetting format for quantity
        }
        elsif ( $input =~ /Prep_Attribute/ ) {
            my $attr_name = shift @prep_attr_name;
            if ( $input =~ /(Prep_Attribute)_(\d+)/ ) {
                $prep_attributes{$2}{name} = $attr_name;
                $input = $1;
            }
            $input   = "$input=$attr_name";
            $default = shift @prep_attr_def;
        }
        elsif ( $input =~ /Mandatory_PrepAttribute_(\d+)/ ) {
            $prep_attributes{$1}{mandatory} = 1;
            next;
        }
        elsif ( $input =~ /Plate_Attribute/ ) {
            my $attr_name = shift @plate_attr_name;
            if ( $input =~ /(Plate_Attribute)_(\d+)/ ) {
                $plate_attributes{$2}{name} = $attr_name;
                $input = $1;
            }
            $input   = "$input=$attr_name";
            $default = shift @plate_attr_def;
        }
        elsif ( $input =~ /Mandatory_PlateAttribute_(\d+)/ ) {
            $plate_attributes{$1}{mandatory} = 1;
            next;
        }
        elsif ( $input =~ /Track_Transfer/ ) {
            $default = "$transfer_q$transfer_q_unit";
        }
        elsif ( $input =~ /Split/ ) {
            $default = $split_x;
        }
        elsif ( $input =~ /Plate_Label/ ) {
            $default = $plate_label_def;
        }

        push( @Input,    $input );
        push( @Formats,  $format );
        push( @Defaults, $default );
    }

    foreach my $key ( keys %prep_attributes ) {
        if ( defined $prep_attributes{$key}{mandatory} && $prep_attributes{$key}{mandatory} == 1 ) {
            push @Input, "Mandatory_PrepAttribute_$prep_attributes{$key}{name}" if ( $prep_attributes{$key}{name} );
        }
    }
    foreach my $key ( keys %plate_attributes ) {
        if ( defined $plate_attributes{$key}{mandatory} && $plate_attributes{$key}{mandatory} == 1 ) {
            push @Input, "Mandatory_PlateAttribute_$plate_attributes{$key}{name}" if ( $plate_attributes{$key}{name} );
        }
    }

    my $defaults = join ':', @Defaults;
    my $formats  = join ':', @Formats;
    my $inputs   = join ':', @Input;

    return ( $inputs, $defaults, $formats );
}

########################
sub get_New_Step_Name {
########################
    my $self              = shift;
    my %args              = &filter_input( \@_ );
    my $dbc               = $args{-dbc} || $self->param('dbc');
    my $step_type         = $args{-step_type};
    my $format            = $args{'-format'};
    my $new_sample_type   = $args{-new_sample_type};
    my $create_new_sample = $args{-create_new_sample};
    my $step_name         = $args{-step_name};
    my $new_step_name;

    if ($create_new_sample) {
        $create_new_sample = " (Track New Sample)";
    }
    if ( $step_type =~ /Transfer/ ) {
        $new_step_name = "$step_type $new_sample_type to $format $create_new_sample";
    }
    elsif ( $step_type =~ /Aliquot/ ) {
        $new_step_name = "$step_type $new_sample_type to $format $create_new_sample";
    }
    elsif ( $step_type =~ /Extract/ ) {
        $new_step_name = "$step_type $new_sample_type to $format $create_new_sample";
    }
    elsif ( $step_type =~ /Pre-Print/ ) {
        $new_step_name = "$step_type to $format";
    }
    elsif ( $step_type =~ /Pool/ ) {
        $new_step_name = "$step_type to $format";
    }
    elsif ( $step_type =~ /Setup/ ) {
        $new_step_name = "$step_type to $format";
    }
    elsif ( $step_type =~ /Throw Away/ ) {
        $new_step_name = "$step_type";
    }
    else { $new_step_name = $step_name }
    return $new_step_name;

}

#######################
sub delete_Protocol {
#######################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->param('dbc');
    my $protocol = $args{-protocol};
    my $delete1;
    my $delete2;

    # unless trans already started, start one and finish at the end
    $dbc->start_trans( -name => 'Delete Protocol' );
    my ($P_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "where Lab_Protocol_Name = '$protocol'" );
    ## DELETE Grp Entry
    $dbc->delete_record( 'GrpLab_Protocol', 'FK_Lab_Protocol__ID', $P_id, -trans => $Transaction );
    ## DELETE PROTOCOL STEPS ##
    $delete1 = $dbc->delete_record( 'Protocol_Step', 'FK_Lab_Protocol__ID', $P_id, -trans => $Transaction );
    ## DELETE LAB PROTOCOL ##
    $delete2 = $dbc->delete_record( 'Lab_Protocol', 'Lab_Protocol_ID', $P_id, -trans => $Transaction );

    $dbc->finish_trans( -name => 'Delete Protocol' );
    return $delete2;
}

#
# Deletes protocol steps
########################
sub delete_Steps {
########################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->param('dbc');
    my $protocol = $args{-protocol};
    my $steps    = $args{-steps};

    my @step_ids = $dbc->Table_find( 'Lab_Protocol, Protocol_Step', "Protocol_Step_ID", "WHERE Lab_Protocol_ID = FK_Lab_Protocol__ID AND Lab_Protocol_Name = '$protocol' and Protocol_Step_Number IN ($steps)" );
    my $ids = join ',', @step_ids;
    my $ok;
    $ok = $dbc->delete_records(
        'Protocol_Step', 'Protocol_Step_ID',
        -id_list   => $ids,
        -autoquote => 1
    ) if ($ids);

    return $ok;

}

########################
sub reindex_Protocol {
########################
    my $self     = shift;
    my %args     = &filter_input( \@_ );
    my $dbc      = $args{-dbc} || $self->param('dbc');
    my $protocol = $args{-protocol};
    my $debug    = $args{-debug};
    my @step_id;

    $step_id[0] = $args{-id};
    my $reserve_step;
    my ($protocol_id) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "WHERE Lab_Protocol_Name = '$protocol'" );
    my $condition = " where FK_Lab_Protocol__ID = $protocol_id";

    if ( $step_id[0] ) {

        $condition .= " and Protocol_Step_ID != $step_id[0]";
        ($reserve_step) = $dbc->Table_find( 'Protocol_Step', 'Protocol_Step_Number', "WHERE Protocol_Step_ID = $step_id[0]" );

        $reserve_step--;
    }
    $condition .= " order by Protocol_Step_Number";

    my @ids = $dbc->Table_find( 'Protocol_Step', 'Protocol_Step_ID', "$condition" );
    if ( $step_id[0] ) {
        splice( @ids, $reserve_step, 0, $step_id[0] );
    }

    my $date = today();

    my $user = $dbc->{config}{user_id};

    my @fields = ( 'Lab_Protocol_Modified_Date', 'FK_Employee__ID' );
    my @values = ( $date, $user );
    $dbc->Table_update_array( 'Lab_Protocol', \@fields, \@values, "where Lab_Protocol_ID = $protocol_id", -autoquote => 1 );

    my $number = scalar(@ids);
    for ( my $index = 1; $index <= $number; $index++ ) {
        my $ok = $dbc->Table_update( 'Protocol_Step', 'Protocol_Step_Number', $index, "where Protocol_Step_ID = $ids[$index-1]", -autoquote => 1 );
    }
    return;
}

###################################
sub get_protocol_status_options {
###################################
    my %args = filter_input( \@_, -args => 'dbc', -mandatory => 'dbc' );
    my $dbc = $args{-dbc};

    my ($field_type) = $dbc->Table_find( 'DBField', 'Field_Type', "WHERE Field_Table = 'Lab_Protocol' and Field_Name = 'Lab_Protocol_Status'" );
    my @options;
    if ( $field_type && $field_type =~ /^enum\((.*)\)$/ ) {
        my @values = split ',', $1;
        foreach my $option (@values) {
            if ( $option =~ /^[\'\"](.*)[\'\"]$/ ) {
                push @options, $1;
            }
        }
    }
    return @options;
}

##########################
# Get the Grp_Access privileges for the specified protocol
#
# Example:	my @access = get_grp_access( -dbc => $dbc, -id => $id, -grp_ids => '8,9' );
#
# Return:	Hash Ref of Grp ID and Grp_Access
##########################
sub get_grp_access {
##########################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'dbc' );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $protocol_id   = $args{-id} || $self->{protocol_id};
    my $protocol_name = $args{-name};
    my $grp_ids       = $args{-grp_ids};

    my $extra_conditions = '';
    if ($grp_ids) {
        my $grp_list = Cast_List( -list => $grp_ids, -to => 'String', -autoquote => 0 );
        $extra_conditions .= " and FK_Grp__ID in ( $grp_list ) ";
    }

    my %grp_access;
    my %access_info;
    if ($protocol_id) {
        %access_info = $dbc->Table_retrieve( 'GrpLab_Protocol', [ 'FK_Grp__ID', 'Grp_Access' ], "WHERE FK_Lab_Protocol__ID = $protocol_id $extra_conditions" );
    }
    elsif ($protocol_name) {
        %access_info = $dbc->Table_retrieve( 'Lab_Protocol, GrpLab_Protocol', [ 'FK_Grp__ID', 'Grp_Access' ], "WHERE FK_Lab_Protocol__ID = Lab_Protocol_ID and Lab_Protocol_Name = '$protocol_name' $extra_conditions" );
    }
    my $index = 0;
    while ( defined $access_info{FK_Grp__ID}[$index] ) {
        $grp_access{ $access_info{FK_Grp__ID}[$index] } = $access_info{Grp_Access}[$index];
        $index++;
    }
    return \%grp_access;
}

##########################
# Get the status for the specified protocol
#
# Example:	my $status = get_protocol_status( -dbc => $dbc, -id => $id );
#
# Return:	Scalar - protocol status
##########################
sub get_protocol_status {
##########################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'dbc' );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $protocol_id   = $args{-id} || $self->{protocol_id};
    my $protocol_name = $args{-name};

    if ( !$protocol_id && !$protocol_name ) {
        return;
    }

    my $conditions = "WHERE 1 ";
    if ($protocol_id) {
        $conditions .= " and Lab_Protocol_ID = $protocol_id ";
    }
    elsif ($protocol_name) {
        $conditions .= " and Lab_Protocol_Name = '$protocol_name' ";
    }
    my ($status) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_Status', -condition => $conditions );
    return $status;
}

##########################
# Set protocol status
#
# Example:	my $ok = set_protocol_status( -dbc => $dbc, -id => $id, -status => 'Active' );
#
# Return:	1 if success; 0 if fail
##########################
sub set_protocol_status {
##########################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'dbc' );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $protocol_id   = $args{-id} || $self->{protocol_id};
    my $protocol_name = $args{-name};
    my $status        = $args{-status};

    if ( !$protocol_id && !$protocol_name ) {
        return;
    }

    my $conditions = "WHERE 1 ";
    if ($protocol_id) {
        $conditions .= " and Lab_Protocol_ID = $protocol_id ";
    }
    elsif ($protocol_name) {
        $conditions .= " and Lab_Protocol_Name = '$protocol_name' ";
    }
    my $ok = $dbc->Table_update_array( 'Lab_Protocol', ['Lab_Protocol_Status'], [$status], "$conditions", -autoquote => 1 );
    return $ok;
}

##############################
# Retrieve protocols that meet the given conditions
#
# Example:	my $protocols = get_protocol( -dbc => $dbc, -department => 'Lib_Construction', -status => 'Active' );
#
# Return:	Array ref of protocols
##############################
sub get_protocols {
##############################
    my %args       = filter_input( \@_, -args => 'dbc' );
    my $dbc        = $args{-dbc};
    my $department = $args{-department};
    my $grp_ids    = $args{-grp_ids};
    my $grp_type   = $args{-grp_type};                      # specify Grp.Grp_Type
    my $access     = $args{-access};                        # specify Grp.Access
    my $grp_access = $args{-grp_access};                    # specify GrpLab_Protocol.Grp_Access
    my $status     = $args{-status};
    my $debug      = $args{-debug};

    my $tables     = 'Lab_Protocol,GrpLab_Protocol,Grp';
    my $conditions = ' WHERE Lab_Protocol.Lab_Protocol_ID = GrpLab_Protocol.FK_Lab_Protocol__ID AND GrpLab_Protocol.FK_Grp__ID = Grp_ID ';
    if ($department) {
        $tables     .= ',Department';
        $conditions .= " AND Grp.FK_Department__ID = Department_ID AND Department_Name = '$department' ";
    }
    if ($grp_type) {
        my $list = Cast_List( -list => $grp_type, -to => 'String', -autoquote => 1 );
        $conditions .= " AND Grp_Type in ( $list ) ";
    }
    if ($grp_ids) {
        my $list = Cast_List( -list => $grp_ids, -to => 'String', -autoquote => 0 );
        $conditions .= " AND Grp_ID in ( $list ) ";
    }
    if ($access) {
        my $list = Cast_List( -list => $access, -to => 'String', -autoquote => 1 );
        $conditions .= " AND Grp.Access in ( $list ) ";
    }
    if ($grp_access) {
        my $list = Cast_List( -list => $grp_access, -to => 'String', -autoquote => 1 );
        $conditions .= " AND GrpLab_Protocol.Grp_Access in ( $list ) ";
    }
    if ($status) {
        my $list = Cast_List( -list => $status, -to => 'String', -autoquote => 1 );
        $conditions .= " AND Lab_Protocol_Status in ( $list ) ";
    }
    my @protocols = $dbc->Table_find(
        -table     => $tables,
        -fields    => 'Lab_Protocol_Name',
        -condition => $conditions,
        -distinct  => 1,
        -debug     => $debug
    );
    return \@protocols;
}

sub convert_to_labeled_list {
    my %args = filter_input( \@_, -args => 'names', -mandatory => 'names' );
    my $names = $args{-names};

    my @choices = ('-');
    my %labels = ( '-' => '--Select--' );
    foreach my $prot (@$names) {
        my $pad_prot = $prot;
        $pad_prot =~ s/\s+/\+/g;
        push( @choices, $pad_prot );
        $labels{$pad_prot} = $prot;
    }
    @choices = sort(@choices);
    return ( \@choices, \%labels );
}

return 1;
