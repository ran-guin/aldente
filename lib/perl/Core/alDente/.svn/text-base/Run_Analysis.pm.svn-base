###################################################################################
# alDente::Run_Analysis.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
####################################################################################
package alDente::Run_Analysis;
use base SDB::DB_Object;    ## remove this line if object is NOT a DB_Object

use strict;

## Standard modules ##
use CGI qw(:standard);
use Data::Dumper;

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

## alDente modules
use alDente::Run;

use vars qw( %Configs );

#####################
sub new {
#####################
    my $this              = shift;
    my %args              = &filter_input( \@_ );
    my $dbc               = $args{-dbc};
    my $id                = $args{-id} || $args{-run_analysis_id};    ##
    my $base_directory    = $args{-base_directory};
    my $input_directory   = $args{-input_directory};
    my $output_directory  = $args{-output_directory};
    my $scratch_space_dir = $args{-scratch_space_directory};
    my $pipeline_version  = $args{-pipeline_version};

    # my $self = {};   ## if object is NOT a DB_Object ... otherwise...
    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Run_Analysis' );
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        ## $self->add_tables();  ## add tables to standard object if applicable
        $self->primary_value( -table => 'Run_Analysis', -value => $id );
        $self->load_Object();
    }
    if ($base_directory) {
        $self->set_base_directory( -base_directory => $base_directory );

    }
    if ($input_directory) {
        $self->{input_directory} = $input_directory;
    }
    if ($output_directory) {
        $self->{output_directory} = $output_directory;
    }
    if ($scratch_space_dir) {
        $self->set_analysis_scratch_space( -analysis_scratch_space => $scratch_space_dir );
    }
    if ($pipeline_version) {
        $self->set_pipeline_version( -pipeline_version => $pipeline_version );
    }
    $self->set_cluster_host();

    return $self;
}

#To be implemented in sub class
sub set_cluster_host {
    my $self = shift;
    $self->{cluster_host} = "";
    return;
}

sub set_base_directory {
    my $self           = shift;
    my %args           = @_;
    my $base_directory = $args{-base_directory};
    $self->{base_directory} = $base_directory;
    return;
}

sub get_base_directory {
    my $self = shift;
    return $self->{base_directory};

}

sub get_pipeline_version {
    my $self = shift;
    return $self->{pipeline_version};
}

sub set_pipeline_version {
    my $self             = shift;
    my %args             = @_;
    my $pipeline_version = $args{-pipeline_version};
    $self->{pipeline_version} = $pipeline_version;

}
#########################################################################
# Create a new Run_Analysis record and start the first step of the analysis pipeline
#
###########################
sub start_run_analysis {
###########################
    my $self                   = shift;
    my %args                   = &filter_input( \@_, -mandatory => 'run_id,analysis_pipeline_id' );
    my $dbc                    = $args{-dbc} || $self->{dbc};
    my $run_id                 = $args{-run_id};
    my $analysis_pipeline_id   = $args{-analysis_pipeline_id};
    my $force                  = $args{-force};
    my $run_analysis_type      = $args{-run_analysis_type} || 'Secondary';
    my $now                    = $args{-date_time} || &date_time();
    my $parent_run_analysis_id = $args{-parent_run_analysis_id};
    my $has_mra                = $args{-has_multiplex_run_analysis};
    my $batch_id               = $args{-batch_id};
    my $analysis_mode          = $args{-analysis_mode};
    my $analysis_comment       = $args{-analysis_comment};

    #Check if analysis is already in progress, if it is, can't continue unless force
    my $condition = "WHERE FK_Run__ID = $run_id AND FKAnalysis_Pipeline__ID = $analysis_pipeline_id AND Run_Analysis_Status NOT IN ('Aborted','Failed') ";

    my ($previous_run_analysis_info) = $dbc->Table_find( "Run_Analysis", "Run_Analysis_ID,Run_Analysis_Status", $condition, -order_by => 'Run_Analysis_Started desc', -limit => 1 );
    my ( $previous_run_analysis_id, $previous_run_analysis_status );
    ( $previous_run_analysis_id, $previous_run_analysis_status ) = split ',', $previous_run_analysis_info if ($previous_run_analysis_info);
    if ( $previous_run_analysis_id && !$force ) {
        Message("Analysis already started with Run_Analysis_ID $previous_run_analysis_id.");
        return $previous_run_analysis_id;
    }
    elsif ( $force && $previous_run_analysis_id && $previous_run_analysis_status eq 'Analyzing' ) {
        Message("Re-Analysis already started with Run_Analysis_ID $previous_run_analysis_id.");
        return $previous_run_analysis_id;
    }
    else {
        $dbc->Table_update_array( 'Run_Analysis', ['Current_Analysis'], ['No'], "WHERE FK_Run__ID = $run_id AND FKAnalysis_Pipeline__ID = $analysis_pipeline_id", -autoquote => 1 );
    }

    #Create a new Run_Analysis record
    my ($sample_id) = $dbc->Table_find( "Run,Plate,Plate_Sample", "FK_Sample__ID", "WHERE FK_Plate__ID = Plate_ID and Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND Run_ID = $run_id" );
    Message("$run_id, $analysis_pipeline_id, $sample_id");
    my @run_analysis_fields = ( 'Run_Analysis_Started', 'Run_Analysis_Status', 'FK_Run__ID', 'FKAnalysis_Pipeline__ID', 'Current_Analysis', 'FK_Sample__ID', 'Run_Analysis_Type' );
    if ($analysis_mode)    { push @run_analysis_fields, "Run_Analysis_Test_Mode" }
    if ($analysis_comment) { push @run_analysis_fields, "Run_Analysis_Comments" }

    my @run_analysis_values = ( $now, 'Analyzing', $run_id, $analysis_pipeline_id, 'Yes', $sample_id, $run_analysis_type );
    if ($analysis_mode)    { push @run_analysis_values, $analysis_mode }
    if ($analysis_comment) { push @run_analysis_values, $analysis_comment }

    ## check to see if parent exists
    my $parent_run_analysis;
    if ($parent_run_analysis_id) {
        ($parent_run_analysis) = $dbc->Table_find( 'Run_Analysis', 'Run_Analysis_ID', "WHERE Run_Analysis_ID = $parent_run_analysis_id" );
    }
    if ($parent_run_analysis) {
        push @run_analysis_fields, 'FKParent_Run_Analysis__ID';
        push @run_analysis_values, $parent_run_analysis_id;
    }
    if ($batch_id) {
        push @run_analysis_fields, 'FK_Run_Analysis_Batch__ID';
        push @run_analysis_values, $batch_id;
    }

    #add run analysis record to database
    my $run_analysis_id = $dbc->Table_append_array( 'Run_Analysis', \@run_analysis_fields, \@run_analysis_values, -autoquote => 1 );

    #add analysis_step records to database
    my @analysis_steps = $dbc->Table_find( "Pipeline_Step", "Pipeline_Step_ID", "WHERE FK_Pipeline__ID = $analysis_pipeline_id" );
    for my $analysis_step (@analysis_steps) {
        my @analysis_step_fields = ( 'FK_Run_Analysis__ID', 'FK_Pipeline_Step__ID' );
        my @analysis_step_values = ( $run_analysis_id, $analysis_step );
        my $analysis_step_id = $dbc->Table_append_array( 'Analysis_Step', \@analysis_step_fields, \@analysis_step_values, -autoquote => 1 );

    }

    #update Run_Status to Analyzing
    my $update;
    $update = $dbc->Table_update( 'Run', 'Run_Status', 'Analyzing', "WHERE Run_ID = $run_id", -autoquote => 1 ) if $run_analysis_type eq 'Secondary';

    #Create a run_analysis log file
    my $log_file = $self->get_analysis_log( -run_analysis_id => $run_analysis_id );

    #try_system_command("touch $log_file");

    if ($run_analysis_id) {
        $self->{id} = $run_analysis_id;
        $self->primary_value( -table => 'Run_Analysis', -value => $run_analysis_id );
        $self->load_Object( -debug => 0 );
    }

    return $run_analysis_id;
}

#########################################################################
# Create a new Run_Analysis record and start the first step of the analysis pipeline
#
###########################
sub create_run_analysis_batch {
###########################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $lims_user = $args{-lims_user};
    my $comments  = $args{-comments};
    my $datetime  = &date_time();

    my ($employee_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "Where Email_Address = '$lims_user'" );
    my @run_analysis_batch_fields = ( "FK_Employee__ID", "Run_Analysis_Batch_RequestDateTime" );
    my @run_analysis_batch_values = ( "$employee_id",    "$datetime" );
    if ($comments) {
        push @run_analysis_batch_fields, "Run_Analysis_Batch_Comments";
        push @run_analysis_batch_values, "$comments";
    }

    my $run_analysis_batch_id = $dbc->Table_append_array( 'Run_Analysis_Batch', \@run_analysis_batch_fields, \@run_analysis_batch_values, -autoquote => 1 );

    return $run_analysis_batch_id;
}

sub get_run_analysis_folder {
    my $self            = shift;
    my %args            = &filter_input( \@_, -mandatory => 'run_analysis_id,base_name' );
    my $base_folder     = $args{-base_folder};
    my $base_name       = $args{-base_name};
    my $run_analysis_id = $args{-run_analysis_id};
    my $dbc             = $self->{dbc};
    my ($run_analysis_started) = $dbc->Table_find( 'Run_Analysis', 'DATE(Run_Analysis_Started) as Run_Analysis_Started', "WHERE Run_Analysis_ID = $run_analysis_id" );
    my $run_analysis_folder;

    $run_analysis_folder = $base_folder . $base_name . $run_analysis_started;

    return $run_analysis_folder;
}

sub get_run_analysis_path {
    my $self = shift;

    my %args      = &filter_input( \@_, -mandatory => 'base_name' );
    my $base_name = $args{-base_name};
    my $id        = $self->{id};
    my $dbc       = $args{-dbc} || $self->{dbc};

    my ($run_analysis_started) = $dbc->Table_find( 'Run_Analysis', "DATE(Run_Analysis_Started) as Run_Analysis_Started", "WHERE Run_Analysis_ID = $id" );

    my $run_analysis_path = $base_name . '_' . $run_analysis_started;
    return $run_analysis_path;
}

sub run_analysis {

    my $self = shift;
    my $dbc  = $self->{dbc};
    Message("Starting run analysis $self->{id}");

    my ( $pipeline_step_id, $analysis_software, $analysis_module ) = $self->get_next_analysis_step( -run_analysis_id => $self->{id} );

    #Message("$pipeline_step_id, $analysis_software, $analysis_module");
    if ( !$pipeline_step_id ) {
        Message("No more steps");
        return 1;
    }

    my $analysis_step_id = $self->start_analysis_step( -run_analysis_id => $self->{id}, -pipeline_step_id => $pipeline_step_id );
    my $analysis_status;
    if ($analysis_module) {
        $analysis_status = $self->execute_analysis( -analysis_step_id => $analysis_step_id, -analysis => $analysis_module );
    }
    Message("Analysis Status: $analysis_status");
    if ( $analysis_status eq 'Analyzed' ) {

        #previous step finished, so record the time it finish and run the next step
        $self->finish_analysis_step( -run_analysis_id => $self->{id}, -pipeline_step_id => $pipeline_step_id, -analysis_step_status => "Analyzed" );
        $self->run_analysis();
    }
    elsif ( $analysis_status eq 'Failed' ) {
        $self->finish_analysis_step( -run_analysis_id => $self->{id}, -pipeline_step_id => $pipeline_step_id, -analysis_step_status => "Failed" );
        return 'Failed';
    }
    return 0;
}

#########################################################################
# Update Run_Analysis_Finished and Run_Analysis_Status
#
###########################
sub finish_run_analysis {
###########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'run_analysis_id,run_analysis_status' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $run_analysis_id     = $args{-run_analysis_id};
    my $run_analysis_status = $args{-run_analysis_status};
    my $now                 = $args{-date_time} || &date_time();

    $dbc->Table_update_array( "Run_Analysis", [ "Run_Analysis_Status", 'Run_Analysis_Finished' ], [ $run_analysis_status, $now ], "WHERE Run_Analysis_ID = $run_analysis_id", -autoquote => 1 );

    #Create a finish run_analysis log file
    my $log_file = $self->get_analysis_log( -run_analysis_id => $run_analysis_id, -finish => 1 );

    #try_system_command("touch $log_file");

    return;
}

# Update Analysis Step to its default values so that it can be restarted
#
#########################
sub reset_analysis_step {
#########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'run_analysis_id,analysis_step_id' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $run_analysis_id  = $args{-run_analysis_id};
    my $analysis_step_id = $args{-analysis_step_id};
    my $now              = $args{-finish_time} || &date_time();
    Message("Resetting Analysis Step for $run_analysis_id ");

    #Update Analysis_Step_Finished and Analysis_Step_Status
    $dbc->Table_update_array( "Analysis_Step", [ "Analysis_Step_Finished", "Analysis_Step_Status", "Analysis_Step_Started" ], [ 'NULL', 'NULL', 'NULL' ], "WHERE FK_Run_Analysis__ID = $run_analysis_id AND Analysis_Step_ID = $analysis_step_id" );

    return;

}
#########################################################################
# Create a new Analysis_Step record and start the analysis step
#
###########################
sub start_analysis_step {
###########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'run_analysis_id,pipeline_step_id' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $run_analysis_id  = $args{-run_analysis_id};
    my $pipeline_step_id = $args{-pipeline_step_id};
    my $now              = $args{-start_time} || &date_time();
    Message("Updating analysis_step");

    my ($analysis_step_id) = $dbc->Table_find( "Analysis_Step", "Analysis_Step_ID", "WHERE FK_Run_Analysis__ID = $run_analysis_id AND FK_Pipeline_Step__ID = $pipeline_step_id" );

    #Check to see if it already Analyzing
    my ($analysis_status) = $dbc->Table_find( "Analysis_Step", "Analysis_Step_ID", "WHERE Analysis_Step_ID = $analysis_step_id AND Analysis_Step_Status IS NOT NULL" );
    if ($analysis_status) {
        Message("Analysis_Step $analysis_step_id (Run_Analysis $run_analysis_id) already started");
        return 0;
    }

    #Create a analysis_step log file
    my $log_file = $self->get_analysis_log( -analysis_step_id => $analysis_step_id );

    #try_system_command("touch $log_file");

    #Update analysis_step
    $dbc->Table_update_array( "Analysis_Step", [ "Analysis_Step_Started", "Analysis_Step_Status" ], [ $now, 'Analyzing' ], "WHERE FK_Run_Analysis__ID = $run_analysis_id AND FK_Pipeline_Step__ID = $pipeline_step_id", -autoquote => 1 );

    return $analysis_step_id;
}

#########################################################################
# Update Analysis_Step_Finished and Analysis_Step_Status (also update Run_Analysis.FKLast_Pipeline_Step__ID)
#
###########################
sub finish_analysis_step {
###########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'run_analysis_id,pipeline_step_id,analysis_step_status' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $run_analysis_id      = $args{-run_analysis_id};
    my $pipeline_step_id     = $args{-pipeline_step_id};
    my $analysis_step_status = $args{-analysis_step_status};
    my $now                  = $args{-finish_time} || &date_time();
    Message("Finishing analysis_step");

    my ($analysis_step_id) = $dbc->Table_find( "Analysis_Step", "Analysis_Step_ID", "WHERE FK_Run_Analysis__ID = $run_analysis_id AND FK_Pipeline_Step__ID = $pipeline_step_id" );

    #Create a analysis_step finish log file
    my $log_file = $self->get_analysis_log( -analysis_step_id => $analysis_step_id, -finish => 1 );

    #try_system_command("touch $log_file");

    #Update Analysis_Step_Finished and Analysis_Step_Status
    $dbc->Table_update_array( "Analysis_Step", [ "Analysis_Step_Finished", "Analysis_Step_Status" ], [ $now, $analysis_step_status ], "WHERE FK_Run_Analysis__ID = $run_analysis_id AND FK_Pipeline_Step__ID = $pipeline_step_id", -autoquote => 1 );

    #Update Run_Analysis.FKLast_Pipeline_Step__ID
    $dbc->Table_update( "Run_Analysis", "FKLast_Analysis_Step__ID", $analysis_step_id, "WHERE Run_Analysis_ID = $run_analysis_id" );

    return;
}

#########################################################################
# Return the next pipeline step given a Run_Analysis_ID
#
###########################
sub get_next_analysis_step {
###########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'run_analysis_id' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $run_analysis_id = $args{-run_analysis_id};

    #<CONSTRUCTION># Doesn't support parallel analysis_step with this query
    my %analysis_step_info = $dbc->Table_retrieve(
        'Analysis_Step,Pipeline_Step,Analysis_Software',
        [ 'Pipeline_Step_ID', 'Analysis_Software_Name', 'Analysis_Executable_Module' ],
        "WHERE FK_Pipeline_Step__ID = Pipeline_Step_ID and Object_ID = Analysis_Software_ID AND FK_Run_Analysis__ID = $run_analysis_id AND (Analysis_Step_Finished IS NULL or Analysis_Step_Finished = '0000-00-00 00:00:00') Order By Pipeline_Step_Order LIMIT 1",
        -debug => 0
    );

    my $pipeline_id       = $analysis_step_info{Pipeline_Step_ID}[0];
    my $analysis_software = $analysis_step_info{Analysis_Software_Name}[0];
    my $analysis_module   = $analysis_step_info{Analysis_Executable_Module}[0];

    return ( $pipeline_id, $analysis_software, $analysis_module );
}
#########################################################################
# Return the next pipeline step given a Run_Analysis_ID
#
###########################
sub get_analysis_step {
###########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'run_analysis_id' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $run_analysis_id    = $args{-run_analysis_id};
    my $analysis_id        = $args{-analysis_step_id};    ## OPTIONAL
    my $analysis_status    = $args{-analysis_status};     ## OPTIONALLY filter by analysis status
    my $analysis_condition = '';
    if ($analysis_status) {
        $analysis_condition .= " AND Analysis_Step_Status ='$analysis_status'";
    }
    my $analysis_id_condition = '';
    if ($analysis_id) {
        $analysis_id_condition .= " AND Analysis_Step_ID = '$analysis_id' ";
    }

    #<CONSTRUCTION># Doesn't support parallel analysis_step with this query
    my %analysis_step_info = $dbc->Table_retrieve(
        'Analysis_Step,Pipeline_Step,Analysis_Software,Run_Analysis',
        [ 'Pipeline_Step_ID', 'Analysis_Software_Name', 'Analysis_Executable_Module' ],
        "WHERE FK_Pipeline_Step__ID = Pipeline_Step_ID and Object_ID = Analysis_Software_ID AND 
				FK_Run_Analysis__ID = $run_analysis_id and FK_Run_Analysis__ID = Run_Analysis_ID $analysis_id_condition $analysis_condition"
    );

    my $pipeline_id       = $analysis_step_info{Pipeline_Step_ID}[0];
    my $analysis_software = $analysis_step_info{Analysis_Software_Name}[0];
    my $analysis_module   = $analysis_step_info{Analysis_Executable_Module}[0];

    return ( $pipeline_id, $analysis_software, $analysis_module );
}
#########################################################################
# Given an analysis_step_id, return its log file name
#
###########################
sub get_analysis_log {
###########################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $run_analysis_id  = $args{-run_analysis_id};
    my $analysis_step_id = $args{-analysis_step_id};
    my $status           = defined $args{-finish} ? 'finished' : 'started';

    my $log_dir;
    $log_dir = $Configs{run_analysis_log_dir} if $run_analysis_id;
    $log_dir = "$Configs{run_analysis_log_dir}/analysis_step_log" if $analysis_step_id;

    my $id = $run_analysis_id;
    $id = $analysis_step_id if $analysis_step_id;
    $id .= ".$self->{cluster_host}" if $self->{cluster_host};

    if ( !$log_dir ) { return "" }

    #test mode
    my $mode = $self->dbc->mode();
    if ( $mode ne 'production' ) { $log_dir .= "/test" }

    return "$log_dir/$id.$status";

}

###########################
sub get_run_analysis_data {
###########################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $dbc           = $self->{dbc};
    my $run_type      = $args{-run_type};
    my $pipeline_name = $args{-pipeline_name};
    my $pipeline_type = $args{-pipeline_type};

    my $extra_condition = $args{-extra_condition} || '';
    if ($run_type) {
        $run_type = Cast_List( -list => $run_type, -to => 'String', -autoquote => 1 );
        $extra_condition .= " AND Run_Type IN ($run_type) ";
    }
    if ($pipeline_name) {
        $pipeline_name = Cast_List( -list => $pipeline_name, -to => 'String', -autoquote => 1 );
        $extra_condition .= " AND Pipeline_Name IN ($pipeline_name) ";
    }
    if ($pipeline_type) {
        $pipeline_type = Cast_List( -list => $pipeline_type, -to => 'String', -autoquote => 1 );
        $extra_condition .= " AND Pipeline_Type IN ($pipeline_type) ";
    }

    my %run_analysis_data;
    my $tables = 'Run,Run_Analysis,Pipeline,Pipeline_Step,Object_Class,Analysis_Software,Analysis_Step';
    %run_analysis_data = $dbc->Table_retrieve(
        $tables,
        [ 'FK_Run__ID',
            'Pipeline_Type',
            'Run_Analysis_Started',
            'Analysis_Step_Started',
            'Analysis_Step_Finished',
            'Run_Analysis_Status',
            'Analysis_Step_Status',
            'Analysis_Software_Name',
            'Pipeline_Step_Order'
        ],
        "WHERE Run_ID = FK_Run__ID and Pipeline_ID = Run_Analysis.FKAnalysis_Pipeline__ID and 
	Pipeline_Step.FK_Pipeline__ID = Pipeline_ID  and 
	FK_Object_Class__ID = Object_Class_ID and 
	Object_Class = 'Analysis_Software' and 
	Object_ID = Analysis_Software_ID and 
	FK_Run_Analysis__ID = Run_Analysis_ID and 
	FK_Pipeline_Step__ID = Pipeline_Step_ID $extra_condition ", -order => "FK_Run__ID, Pipeline_Step_Order, Run_DateTime",
    );

    return \%run_analysis_data;
}

sub get_run_analysis_types {
    my $self = shift;
    my $dbc  = $self->{dbc};

    my @analysis_pipelines;
    @analysis_pipelines = $dbc->Table_find( "Pipeline,Run_Analysis,Run", 'distinct Run_Type,Pipeline_Name,Pipeline_Type', "WHERE FK_Run__ID = Run_ID and Pipeline_ID = FKAnalysis_Pipeline__ID" );
    return @analysis_pipelines;
}

#########################################################################
# Given a Analysis_Software.Analysis_Executable_Module, run it
#
###########################
sub execute_analysis {
###########################
    my $self             = shift;
    my $dbc              = $self->{dbc};
    my %args             = &filter_input( \@_ );
    my $run_analysis_id  = $args{-run_analysis_id} || $self->{id};
    my $analysis_step_id = $args{-analysis_step_id};
    my $analysis         = $args{-analysis};

    $analysis =~ s/<RUN_ANALYSIS_ID>/$run_analysis_id/g;
    $analysis =~ s/<ANALYSIS_STEP_ID>/$analysis_step_id/g;

    my $returned = eval($analysis);
    if ($@) {
        print "Error in analysis: $@\n";
        Call_Stack();
        $returned = 0;
    }

    return $returned;

}

#########################################################################
# Given an analysis_step, check to see if the step is finished
#
###########################
sub check_analysis_step_progress {
###########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'run_analysis_id' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    ### if see analyzed log file in the log directory
    ### then call $self->finish_analysis_step
    ### $next_step = $self->get_next_analysis_step
    ### $self->start_analysis_step(-run_analysis_id=>$run_analysis_id, -pipeline_step_id=>$next_step)

    return;
}

#########################################################################
# Given an analysis, check to see if the analysis is running too long, details to be implemented in sub class
#
###########################
sub check_expiring_analysis {
###########################
    my $self            = shift;
    my %args            = &filter_input( \@_, -mandatory => 'run_analysis_id' );
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $run_analysis_id = $args{-run_analysis_id};
    my $hour_limit      = $args{-hour_limit};
    my $title           = $args{-title} || "Expiring Analysis Check";

    my ($info) = $dbc->Table_find( "Run_Analysis", "Run_Analysis_Started,Run_Analysis_Status", "WHERE Run_Analysis_ID = $run_analysis_id" );
    my ( $run_analysis_started, $run_analysis_status ) = split( ",", $info );
    $run_analysis_started = convert_date( $run_analysis_started, 'SQL' );

    my @difference = $dbc->SQL_retrieve( -sql => "select TIME_FORMAT(TIMEDIFF(NOW(), '$run_analysis_started'),'%H')", -format => 'CA' );

    if ( $difference[0][0] > $hour_limit && $run_analysis_status ne 'Expired' && $hour_limit ) {
        print Dumper \@difference, $run_analysis_started;

        require alDente::Subscription;

        alDente::Subscription::send_notification(
            -dbc          => $dbc,
            -name         => 'Expiring Analysis Check',
            -from         => 'Expiring Analysis Check <aldente@bcgsc.bc.ca>',
            -subject      => "$title for Run_Analysis $run_analysis_id",
            -body         => "Run_Analysis $run_analysis_id is overdue, Run_Analysis_Status set to Expired",
            -content_type => 'html'
        );
        $dbc->Table_update( "Run_Analysis", "Run_Analysis_Status", "Expired", "WHERE Run_Analysis_ID = $run_analysis_id", -autoquote => 1 );

    }

    return;
}

#########################################################################
# Given an analysis_step_log to indicate it started/finished
#
###########################
sub update_analysis_step_log {
###########################
    my $self = shift;
    my %args = &filter_input( \@_, -mandatory => 'analysis_step_id,status' );
    my $dbc  = $args{-dbc} || $self->{dbc};

}

#########################################################################
# Script to run whenever a new Run_Analysis record is added to the database
#
###########################
sub new_run_analysis_trigger {
###########################
    return;
}

#
#
#
#
################################
sub write_to_check_finish_file {
################################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $method        = $args{-method};
    my $id            = $self->{id};
    my $finished_file = $args{-finished_file};
    my $path          = $args{-path};
    my @finished_file = @{$finished_file};
    my $check_file    = "$method" . "$id.expected.txt";
    open my $OUT, '>', "$path/$check_file" || return ( 0, '', "Can't open $path/$check_file\n" );

    foreach my $finished_file (@finished_file) {

        print $OUT "$finished_file\n";
    }

    close $OUT;
    return;
}

##########################
sub check_finished_files {
##########################
    my $self                     = shift;
    my %args                     = filter_input( \@_ );
    my $path                     = $args{-path};
    my $analysis_method          = $args{-method};
    my $id                       = $self->{id};
    my $expected_method_finished = "$path/$analysis_method$id.expected.txt";
    print "expected finished method = $expected_method_finished\n";
    ## read in the analysis_method.finished file to get a list of the expected finished files.
    my @expected_files = ();
    my $num_found      = 0;
    if ( -e "$expected_method_finished" ) {
        open my $EXP_FILE, '<', "$expected_method_finished" || return ( 0, '', "Can't open $expected_method_finished\n" );
        while (<$EXP_FILE>) {
            my $expected_file = chomp_edge_whitespace($_);
            print "$expected_file\n";
            push @expected_files, $expected_file;

            if ( -e "$path/$expected_file" ) {
                $num_found++;
            }
        }
        close($EXP_FILE);

    }
    else {
        print "Could not find expected finished file\n";
        return 0;
    }
    ## check file system with for the expected finished files
    my $num_expected = int(@expected_files);

    ## compare the actual list of finished files

    if ( $num_expected > 0 && $num_expected == $num_found ) {

        return 1;
    }

    return 0;
}
################################
sub get_analysis_scratch_space {
################################
    my $self = shift;

    return $self->{analysis_scratch_space_directory};
}
################################
sub set_analysis_scratch_space {
################################
    my $self                   = shift;
    my %args                   = @_;
    my $analysis_scratch_space = $args{-analysis_scratch_space};
    $self->{analysis_scratch_space_directory} = $analysis_scratch_space;

}

sub get_run_analysis_priority {
    my $self      = shift;
    my %args      = @_;
    my $pri_value = $args{-priority};
    my $dbc       = $self->{dbc};
    my $priority;
    my %priority;
    $priority{'5 Highest'} = '-10';
    $priority{'4 High'}    = '-200';
    $priority{'3 Medium'}  = '-600';
    $priority{'2 Low'}     = '-800';
    $priority{'1 Lowest'}  = '-1000';

    $priority = $priority{$pri_value};

    return $priority;
}

sub determine_priority {
    my $self            = shift;
    my %args            = filter_input( \@_ );
    my $run_analysis_id = $args{-run_analysis_id};
    my $library         = $args{-library};
    my $project_id      = $args{-project_id};
    my $dbc             = $self->{dbc};

    require alDente::Priority_Object;
    my $po = alDente::Priority_Object->new( -dbc => $dbc );
    my $run_analysis_priority;
    $run_analysis_priority = $po->get_priority( -object_class => 'Run_Analysis', -object_id => $run_analysis_id );

    my $library_priority;
    $library_priority = $po->get_priority( -object_class => 'Library', -object_id => $library );

    my $project_priority;
    $project_priority = $po->get_priority( -object_class => 'Project', -object_id => $project_id );
    my $priority;
    if ($run_analysis_priority) {
        $priority = $run_analysis_priority;
    }
    elsif ($library_priority) {
        $priority = $library_priority;
    }
    elsif ($project_priority) {
        $priority = $project_priority;
    }
    else {
        $priority = '3 Medium';

    }
    my $priority_number;
    $priority_number = $self->get_run_analysis_priority( -priority => $priority );
    return $priority_number;
}
######################################
sub md5_checksum {
######################################
    my $self                      = shift;
    my %args                      = filter_input( \@_ );
    my $run_analysis_id           = $args{-run_analysis_id};
    my $dbc                       = $self->{dbc};
    my $multiplex_run_analysis_id = $args{-multiplex_run_analysis_id};
    my $index                     = $args{-adapter_index};
    my $output_path               = $args{-output_path};
    my $lane                      = $args{-lane};
    my $md5_checksum;
    my $header;

    if ( $multiplex_run_analysis_id && $index ) {
        my $path  = $output_path . "/s_" . $lane . "_*" . $index . "*.md5sum";
        my @exist = glob("$path");
        unless (@exist) {
            Message("md5sum file does not exist for run analysis: $run_analysis_id");
            return 0;
        }
        $header = try_system_command("head $output_path/s_$lane\_*$index*.md5sum");

        my ($md5_checksum) = split( " ", $header );
        $dbc->Table_update_array( "Multiplex_Run_Analysis", ["Md5_Checksum_1"], [$md5_checksum], "WHERE Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id", -autoquote => 1, -debug => 0 );
    }
    elsif ($run_analysis_id) {
        my $path  = $output_path . "/s_" . $lane . "_*.md5sum";
        my @exist = glob("$path");
        unless (@exist) {
            Message("md5sum file does not exist for run analysis: $run_analysis_id");
            return 0;
        }

        $header = try_system_command("head $output_path/s_$lane\_*.md5sum");
        my ($md5_checksum) = split( " ", $header );

        $dbc->Table_update_array( "Run_Analysis", ["Md5_Checksum_1"], [$md5_checksum], "WHERE Run_Analysis_ID = $run_analysis_id", -autoquote => 1 );

    }
    else {
        Message("run analysis id not passed to md5_checksum function not found");
    }

    return $md5_checksum;
}
1;
