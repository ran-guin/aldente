#
# Run.pm
#
# This module handles routines specific to Sequencing Runs
################################################################################
#
# History:
#  Originally written to correct for well mapping errors of 3730-1 (Oct / 2003)
#
#######################
package alDente::Run;

##############################
# perldoc_header             #
##############################

#Run.pm - This module handles routines specific to Runs

##############################
# superclasses               #
##############################
@ISA = qw(Exporter SDB::DB_Object);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    get_run_data
    get_run_list
);
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use RGTools::RGmath;

use SDB::DB_Object;
use SDB::DBIO;
use SDB::DB_Form_Viewer;
use SDB::CustomSettings;
use SDB::HTML;

use alDente::SDB_Defaults;
use alDente::alDente_API;
use alDente::Validation;
use alDente::Tools;
use alDente::Invoiceable_Work;
use alDente::Run_Views;
##############################
# global_vars                #
##############################
use vars qw(%Field_Info $URL_temp_dir $testing $run_maps_dir $project_dir %Configs);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my $TABLE          = 'Run';
my @RELATED_TABLES = 'RunBatch,Plate,Library,Project';

##############################
# constructor                #
##############################

##########
sub new {
##########
    #
    # Constructor of the object
    #
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = @_;

    my $dbc        = $args{-dbc};
    my $dbh        = $dbc->dbh();                        # Database handle
    my $run_id     = $args{-run_id} || $args{-id};       # specify Run ID [int]
    my $retrieve   = $args{-retrieve};                   # retrieve information right away [0/1]
    my $verbose    = $args{-verbose};
    my $tables     = $args{-tables} || 'Run,RunBatch';
    my $quick_load = $args{-quick_load};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => $tables );

    $self->{dbc} = $dbc;

    if ( defined $run_id ) {
        $self->{run_id} = $run_id;
        $self->{id}     = $run_id;
        $self->primary_value( -table => 'Run', -value => $run_id );

        my ($run_type) = $self->{dbc}->Table_find( 'Run', 'Run_Type', "WHERE Run_ID = $run_id" );

        # SequenceRun isn't a real run type, so get rid of it
        if ( $run_type eq 'SequenceRun' ) {
            ## do NOT try to add SequenceRun table ##
        }
        elsif ( $run_type eq 'SolexaRun' ) {
            unless ($quick_load) {
                $self->add_tables($run_type);
                $self->add_tables('Flowcell');
            }
        }
        else {
            ## for GelRun,SpectRun,BioAnalyzer,GenechipRun ##
            $self->add_tables($run_type) if ( $run_type && !$quick_load );
        }
        $self->load_Object( -quick_load => 1, -id => $run_id );
    }
    else {
        $self->{dbc}     = $dbc;
        $self->{records} = 0;      ## number of records currently loaded

    }

    bless $self, $class;

    return $self;
}

##############################
# public_methods             #
##############################

##############################
#
# Load information of a run when an ID was not given when constructor was used
#
##############################
sub load_run {
##############################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $run_id     = $args{-run_id};
    my $quick_load = $args{-quick_load};

    $self->{run_id} = $run_id;
    $self->{id}     = $run_id;
    $self->primary_value( -table => 'Run', -value => $run_id );

    my ($run_type) = $self->{dbc}->Table_find( 'Run', 'Run_Type', "WHERE Run_ID = $run_id" );

    # SequenceRun isn't a real run type, so get rid of it
    if ( $run_type eq 'SequenceRun' ) {
        ## do NOT try to add SequenceRun table ##
    }
    elsif ( $run_type eq 'SolexaRun' ) {
        unless ($quick_load) {
            $self->add_tables($run_type);
            $self->add_tables('Flowcell');
        }
    }
    else {
        ## for GelRun,SpectRun,BioAnalyzer,GenechipRun ##
        $self->add_tables($run_type) if ( $run_type && !$quick_load );
    }
    $self->load_Object( -quick_load => 1, -id => $run_id );
    return 1;
}

##############################
#
# Return the Run_Type of this run
#
##############################
sub get_run_type {
##############################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $run_id = $args{-run_id} || $self->{run_id};
    my ($run_type) = $self->{dbc}->Table_find( 'Run', 'Run_Type', "WHERE Run_ID = $run_id" );
    return $run_type;
}

##############################
#
# Return valid run types
#
##############################
sub get_valid_run_types {
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my (@run_types) = $dbc->Table_find(
        -table     => 'Run',
        -fields    => 'Run_Type',
        -condition => "WHERE 1",
        -distinct  => 1
    );
    return @run_types;

}
##############################
#
# Create Run Batches and return's its ID
#
##############################
sub create_runbatch {
##############################

    my %args = &filter_input( \@_, -args => 'fk_equipment__id,comments,fk_employee__id,fk_plate__id, run_type', -mandatory => 'fk_equipment__id,fk_plate__id,run_type' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $user_id     = $dbc->get_local('user_id');
    my $equip    = $args{-fk_equipment__id};
    my $emp      = $args{-fk_employee__id} || $user_id;
    my $plates   = $args{-fk_plate__id};
    my $run_type = $args{-run_type};
    my $comments = $args{-comments};
    my $quiet    = $args{-quiet};

    ########## CHECKING FUNDING SOURCE #############
    if ( $dbc->package_active('Funding_Tracking') ) {
        require alDente::Funding;
        my $funding = alDente::Funding->new( -dbc => $dbc );
        unless ( $funding->validate_active_funding( -plates => $plates ) ) {
            $dbc->session->warning("Valid funding source is required for invoice run type ($run_type) to continue!");
            return 0;
        }
    }

    my $now          = &date_time();
    my @Batch_fields = ( 'FK_Employee__ID', 'FK_Equipment__ID', 'RunBatch_RequestDateTIme', 'RunBatch_Comments' );
    my @Batch_values = ( $emp, $equip, $now, $comments );

    my $batch_id = $dbc->Table_append_array( 'RunBatch', \@Batch_fields, \@Batch_values, -autoquote => 1 );

    if ($batch_id) {
        $dbc->message( "New RunBatch: " . &Link_To( $dbc->config('homelink'), $batch_id, "&Info=1&Table=RunBatch&Field=RunBatch_ID&Like=$batch_id", $Settings{LINK_COLOUR} ) ) unless ($quiet);
        return $batch_id;
    }
    else {
        $dbc->warning("see admin (Batch value problem)");
        return 0;
    }

}

################################
sub create_runbatch_attribute {
################################
    my %args                      = @_;
    my $dbc                       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $emp                       = $args{-employee_id};
    my $runbatch_id               = $args{-runbatch_id};
    my $attribute_id              = $args{-attribute_id};
    my $attribute_value           = $args{-attribute_value};
    my $set_datetime              = date_time();
    my @runbatch_attribute_fields = ( 'FK_Employee__ID', 'FK_RunBatch__ID', 'FK_Attribute__ID', 'Attribute_Value', 'Set_DateTime' );
    my @runbatch_attribute_values = ( $emp, $runbatch_id, $attribute_id, $attribute_value, $set_datetime );
    my $runbatch_attribute_id     = $dbc->Table_append_array( 'RunBatch_Attribute', \@runbatch_attribute_fields, \@runbatch_attribute_values, -autoquote => 1 );
    if ($runbatch_attribute_id) {
        return $runbatch_attribute_id;
    }
    else {
        $dbc->error("Could not add run batch attribute");
        return 0;
    }
}

######################
sub retrieve_by_Library {
######################
    #
    # Standard interface to retrieve Record(s)
    #
    my $self = shift;
    my %args = @_;      ## arguments passed

    my $project_id   = $args{-project_id};             # Project_ID
    my $library      = $args{-library};                # Library name
    my $plate_number = $args{-plate_number};           # plate number (not id) - optional
    my $quadrant     = $args{-quadrant} || '';         # quadrant              - optional
    my $well         = $args{-well};                   # well                  - optional
    my $condition    = $args{-condition} || 1;         # condition (optional additional condition)
    my $fields       = $args{-fields};
    my $group_by     = $args{-group_by};
    my $order_by     = $args{-order_by} || 'Run_ID';

    if ($library) {
        $condition = "$condition AND Library_Name like '$library%'";
    }
    elsif ($project_id) {
        $condition = "$condition AND Project_ID = $project_id";
    }
    else {
        $self->error("No Library or Project Specified");
        return;
    }

    ## update condition if plate_number given
    if ($plate_number) { $condition .= " AND Plate_Number in ($plate_number)" }

    $self->add_tables( join ',', @RELATED_TABLES );
    ## generate retrieve statement including related tables ##
    my $found = $self->load_Object( -condition => $condition, -multiple => 1, -fields => $fields, -group_by => $group_by );

    $self->{reads} = $found;
    return $found;    ## number of records retrieved
}

###############################################################################
# Request that specified runs be marked as failed, and set up for re-running
#
#
###########
sub re_run {
###########
    my $self = shift;
    my %args = @_;

    my $quiet   = $args{-quiet} || 0;
    my $run_ids = $args{-run_ids};
    my $since   = $args{-since};
    my $until   = $args{ -until };
            my $machine = $args{-machine_id};
            my $cond    = $args{-condition};
            ### changed fields.. ###
            my $newdate  = $args{-date};
            my $newuser  = $args{-user_id};
            my $comments = $args{-comments} || '';
            my $fail     = $args{-fail};
            my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my @newbatches;

    my $rerun_comments;
    if ($fail) {
        $rerun_comments = "Failed, requested rerun. $comments";
    }
    else {
        $rerun_comments = $comments;
    }

    if ( $newdate && $newuser ) {
        print "Resetting Date to $newdate\n";
        print "Resetting User to $newuser\n";
    }
    else {
        print "Please supply new Date (eg -date '2003-10-01') and user (eg -user_id 55)";
        return;
    }

    my @reruns;
    if ($run_ids) {
        @reruns = @{$run_ids};
        print "Specified " . int(@reruns) . " Runs..\n";
    }
    elsif ( $machine && $since ) {
        my $condition = "FK_RunBatch__ID=RunBatch_ID";
        if ($machine) {
            $condition .= " AND FK_Equipment__ID in ($machine)";
        }
        if ($since) {
            $condition .= " AND Run_DateTime >= '$since'";
        }
        if ($until) {
            $condition .= " AND Run_DateTime <= '$until'";
        }
        if ($cond) {
            $condition .= " AND $cond";
        }
        print "Condition: $condition\n\n";
        @reruns = $dbc->Table_find( 'Run,RunBatch', 'Run_ID', "WHERE $condition" );
    }
    else {
        print "Please specify -since AND -machine_id ... OR -run_ids\n";
    }

    if ( int(@reruns) ) {
        print "Found " . int(@reruns) . " Runs..\n";
    }
    else {
        print "No run ids matching condition";
        return;
    }

    my %returnval;
    $returnval{ids} = \@reruns;

    my @newnames;
    my %Batch_copy = {};
    foreach my $run_id (@reruns) {
        print "Run $run_id : ";

        $self->primary_value( -table => 'Run', -value => $run_id );
        $self->load_Object( -include_FK_tables => 1, -FK_tables => [ 'RunBatch', 'Plate' ] );

        $self->update( -fields => [ 'Run_Status', 'Run_Comments' ], -values => [ 'Failed', $rerun_comments ] );

        my $basename = $self->value('Run_Directory');
        my $lib      = $self->value('Plate.FK_Library__Name');
        if ( $basename =~ /($lib)\-(.+)\.(.+)\.(\d+)$/ ) {
            $basename = "$1\-$2.$3";
        }
        elsif ( $basename =~ /($lib)\-(.+)\.(.+)$/ ) {
        }
        else { print "$basename cannot be parsed\n"; next; }
        my $newname = _nextname($basename);

        push( @newnames, $newname );

        print $self->value('Run_Directory') . " - ";
        print $self->value('RunBatch.FK_Equipment__ID') . ' ';
        print ' (' . $self->value('Run_DateTime') . ')';
        print "...";

        my $size = $self->value('Plate.Plate_Size');

        my $batch = $self->value('FK_RunBatch__ID');
        my ($proj_path) = $dbc->Table_find( 'Project,Library', 'Project_Path', "where FK_Project__ID=Project_ID and Library_Name = '$lib'" );
        my $ss_path = "$project_dir/$proj_path/$lib/";

        #	print "*** SS: $ss_path ($size)\n";
        `touch $ss_path/SampleSheets/$newname.txt`;

        ### Generate a new matching Batch record if it has not already been done...
        my $newbatch = 0;
        if ( $Batch_copy{$batch} ) {
            $newbatch = $Batch_copy{$batch};
        }
        else {
            $newbatch = $self->_copy_batch( -batch => $batch, -user_id => $newuser, -comments => $comments, -date => $newdate );
            $Batch_copy{$batch} = $newbatch;
        }

        $self->value( 'Run_ID',          'NULL' );
        $self->value( 'FK_RunBatch__ID', $newbatch );

        #	$self->value('Run_Comments',$comments);  ## put batch in RunBatch..
        $self->value( 'Run_Directory',     $newname );
        $self->value( 'Run_DateTime',      $newdate );
        $self->value( 'Run_Status',        'Pending' );
        $self->value( 'Analysis_DateTime', '0000-00-00' );
        $self->value( 'Run_Directory',     '' );
        $self->value( 'Phred_Version',     '' );
        $self->value( 'Reads',             0 );

        ## update Batch ##

        #	my $feedback = $self->insert();
        #	my $newid = %{$feedback}->{id};

        #	print " added Run $newid. ($newname : $size)\n";
    }

    $returnval{new_names} = \@newnames;

    return \%returnval;
}

################
sub get_data_path {
################
    my %args = &filter_input( \@_, -args => 'dbc,run_id,plate_id' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_id = Cast_List( -list => $args{-plate_id}, -to => 'string' );
    my $run_id   = Cast_List( -list => $args{-run_id},   -to => 'string' );
    my $simple   = $args{-simple};

    my $data_dir = "AnalyzedData";
    my $extra_condition;
    if ($run_id) {
        $extra_condition = "Run_ID = $run_id";
    }
    elsif ($plate_id) {
        $extra_condition = "Plate_ID = $plate_id";
    }
    else { $dbc->message("No Run ID or plate specified"); return; }

    my ($path_info) = $dbc->Table_find_array( 'Project,Library,Run,Plate', [ "Project_Path", "Library_Name", "Run_Directory" ], "WHERE FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name and FK_Project__ID=Project_ID AND $extra_condition" );

    my ( $proj, $library, $run_name ) = split ',', $path_info;
    my $path = "$project_dir/$proj/$library/$data_dir/$run_name";
    if ($simple) { $path = "$proj/$library/$data_dir/$run_name"; }

    return $path;
}

#
#
############################
sub get_analyzed_runs {
############################
    my %args            = @_;
    my $dbc             = $args{-dbc};
    my $extra_condition = $args{-extra_condition};

    my %analyzed_runs = $dbc->Table_retrieve( 'Run', [ 'Run_ID', 'Run_Type' ], "WHERE Run_Status = 'Analyzed' $extra_condition" );
    return \%analyzed_runs;
}

# Trigger for Run
#
# Usage: $self->run_trigger();
# Return: 1
#################
sub run_trigger {
#################
    my $self = shift;

    $self->record_initiated_run();

    #when run is initiated add invoiceable run
    my $Invoiceable_Work = new alDente::Invoiceable_Work( -dbc => $self->{dbc} );
    $Invoiceable_Work->add_invoiceable_run_info( -run_id => $self->value('Run.Run_ID') );

    return 1;
}

#################
# Records the Initated Run step for the plate_id of a given Run
#
#################
sub record_initiated_run {
#################
    my $self = shift;

    my $id       = $self->value('Run.Run_ID');
    my $plate_id = $self->value('Run.FK_Plate__ID');
    my ($equipment) = $self->{dbc}->Table_find( 'Run,RunBatch', 'FK_Equipment__ID', "WHERE FK_RunBatch__ID = RunBatch_ID and Run_ID = $id" );

    ## Record a protocol for when a run is initiated, records the equipment it was initiated with as well
    require alDente::Prep;
    my $prep_obj = alDente::Prep->new( -dbc => $self->{dbc} );

    my %input;
    $input{'Current Plates'}   = $plate_id;
    $input{'FK_Equipment__ID'} = $equipment;
    if ($plate_id) {
        $prep_obj->Record( -ids => $plate_id, -protocol => 'Initiated Run', -step => 'Initiated Run',      -input => \%input );
        $prep_obj->Record( -ids => $plate_id, -protocol => 'Initiated Run', -step => 'Completed Protocol', -input => \%input );
    }
    return 1;
}

# get a list of runs that have a run_status " data acquired "
#
#
############################
sub get_data_acquired_runs {
############################
    my %args            = @_;
    my $dbc             = $args{-dbc};
    my $extra_condition = $args{-extra_condition};

    my %data_acquired_runs = $dbc->Table_retrieve( 'Run', [ 'Run_ID', 'Run_Type' ], "WHERE Run_Status = 'Data Acquired' $extra_condition" );
    return \%data_acquired_runs;
}

# get a list of runs that have a run_status " data acquired "
#
#
############################
sub get_analyzing_runs {
############################
    my %args            = @_;
    my $dbc             = $args{-dbc};
    my $extra_condition = $args{-extra_condition};

    my %analyzing_runs = $dbc->Table_retrieve( 'Run', [ 'Run_ID', 'Run_Type' ], "WHERE Run_Status = 'Analyzing' $extra_condition" );
    return \%analyzing_runs;
}

###############
sub home_page {
###############
    my $self = shift;
    my %args = @_;

    #  my $type = $args{-run_type};
    my $dbc = $self->{dbc};
    my $id  = $self->{run_id};

    ## <construction> - why not just load the object ? ##
    my $API = alDente::alDente_API->new( -dbc => $dbc );

    # get run data
    my $run_data = $API->get_run_data( -run_id => $id, -fields => 'FK_Plate__ID, Run_Datetime, Run_Directory, Run_Status, Run_Test_Status, Run_Type', -log => 0, -quiet => 1 );
    my $plate_id    = &alDente::Tools::alDente_ref( 'Plate', $run_data->{'FK_Plate__ID'}[0], -dbc => $dbc );
    my $datetime    = $run_data->{'Run_Datetime'}[0];
    my $run_dir     = $run_data->{'Run_Directory'}[0];
    my $status      = $run_data->{'Run_Status'}[0];
    my $test_status = $run_data->{'Run_Test_Status'}[0];
    my $type        = $run_data->{'Run_Type'}[0];

    my $summary_table = HTML_Table->new( -class => 'small', -title => "Run: $id" );
    $summary_table->Set_Row( [ 'Type: ', $type ] ) if $type;
    $summary_table->Set_Row( [ 'Plate: ',       $plate_id ] );
    $summary_table->Set_Row( [ 'Datetime: ',    $datetime ] );
    $summary_table->Set_Row( [ 'Directory: ',   $run_dir ] );
    $summary_table->Set_Row( [ 'Status: ',      "<font color='red'>$status</font>" ] ) if $status ne 'Analyzed';
    $summary_table->Set_Row( [ 'Test Status: ', "<font color='red'>$test_status</font>" ] ) if $test_status eq 'Failed';

    my $details = $self->display_Record( -tables => $self->{tables} );
    my $display_run_data = alDente::Run_Views::show_run_data( -dbc => $dbc, -run_id => $id );

    &Views::Table_Print( content => [ [ $summary_table->Printout(0) . vspace(5) . $display_run_data, $details ] ] );

    return 1;

}

##############################
# public_methods             #
##############################

#
# Given a set of optional parameters this will return a list of valid runs
#
# This should be used to initiate any more complex data queries by first extracting applicable runs.
#
# <snip>
#  Example:
#   my %data = get_run_data(-project_id=>4);
#   my $run_list = join ',', @{$data{run_id}};
#   my $first_machine  = $data{machine}[0];
# </snip>
#
# Return: \%data (hash reference; keys = fields of interest = arrayref of returned values)
#  OBSOLETE ...
########################
sub get_run_data_OLD {
#########################
    my %args = filter_input( \@_, -args => 'dbc' );

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $API = alDente::alDente_API->new( -dbc => $dbc );

    #    $args{-debug} = 1;
    $args{-quiet} = 1;
    $args{ -log } = 0;    ## turn logging off

    my $data = $API->get_run_data(%args);
    return $data;

    ## below should be obsolete ...

    if ( $args{ERRORS} ) { $dbc->message("Input Errors Found: $args{ERRORS}"); return; }

    ## Specify conditions for data retrieval
    my $input_condition = $args{-condition} || '1';    ### extra condition (vulnerable to structure change)
    my $study_id        = $args{-study_id};            ### a study id (a defined set of libraries/projects)
    my $project_id      = $args{-project_id};          ### specify project_id
    my $library         = $args{-library};             ### specify library
    ## run specification options
    my $run_id         = $args{-run_id};               ### specify run id
    my $run_name       = $args{-run_name};             ### specify run name (must be exact format)
    my $exclude_run_id = $args{-exclude_run_id};       ### specify run id to EXCLUDE (for Run or Read scope)
    ## plate specification options
    my $plate_id          = $args{-plate_id};                   ### specify plate_id
    my $plate_number      = $args{-plate_number};               ### specify plate number
    my $plate_type        = $args{-plate_type} || '';           ### specify type of plate (tube or Library_Plate)
    my $plate_class       = $args{-plate_class} || '';          ### specify class of plate (clone or extraction)
    my $plate_application = $args{-plate_application} || '';    ### specify application of plate (Sequencing/Mapping/PCR)
    my $original_plate_id = $args{-original_plate_id};          ### specify original plate id
    my $original_well     = $args{-original_well};              ### specify original well
    my $applied_plate_id  = $args{-applied_plate_id};           ### specify original plate id (including ReArrays)
    my $quadrant          = $args{-quadrant};                   ### specify quadrant from original plate

    ## Inclusion / Exclusion options
    my $since = $args{-since};                                  ### specify date to begin search (context dependent)
    my $until = $args{ -until };                                ### specify date to stop search (context dependent)
            my $include = $args{-include} || 0;                 ### specify data to include (eg. production,approved)
            my $exclude = $args{-exclude} || 0;                 ### OR specify data to exclude (eg. failed)

            ## Output options
            my $fields = $args{-fields} || '';
            my $order  = $args{-order}  || '';
            my $group  = $args{-group}  || 'run_id';
            my $KEY    = $args{-key};
            my $limit  = $args{-limit}  || '';                  ### limit number of unique samples to retrieve data for
            my $quiet = $args{-quiet};                          ### suppress feedback by setting quiet option

            # =pod
            # ##
            # ## <CONSTRUCTION> - items below need to be excluded or worked into the logic...
            # ##
            #     my $pool         = $args{-pools};                              ### specify pool for information on pooled libraries
            #     my $pool_type    = $args{-pool_type};                         ### specify pool_type to extract info for
            #     my $rearray         = $args{-rearray};                        ### get info for Re-Array plates/libs (boolean)
            #     my $rearray_type    = $args{-rearray_type};                   ### indicate type of re-array to extract info for
            #     my $original_plate_number = $args{-original_plate_number};    ### specify original plate number (prior to pooling / rearraying)
            #
            #     ## Specify custom details of sample data to retrieve
            #     my $source_collection = $args{-source_collection};            ### specify source collection (eg. 'IRAL')
            #     my $source_plate      = $args{-source_plate};                 ### specify plate number from source (eg. 55 for 'IRAL 55')
            #     my $source_library_id = $args{-source_library_id};            ### specify library id as specified from source
            #
            #     ## convert array of values to comma-delimited lists...
            #     # <CONSTRUCTION> following options may or may not be included...
            #
            #     #    if (ref($source_collection) eq 'ARRAY') { $source_collection = join "','", @$source_collection }
            #     #    if (ref($source_library_id) eq 'ARRAY') { $source_library_id = join ",", @$source_library_id }
            #
            #     #    if (ref($pool) eq 'ARRAY') { $pool = join "','", @$pool }
            #     #    if (ref($rearray) eq 'ARRAY') { $rearray = join "','", @$rearray }
            # =cut

            ### Re-Cast arguments if necessary ###
            my $study_ids = Cast_List( -list => $study_id, -to => 'string' ) if $study_id;
    my $project_ids = Cast_List( -list => $project_id, -to => 'string' ) if $project_id;
    my $libraries     = Cast_List( -list => $library,      -to => 'string', -autoquote => 1 ) if $library;
    my $plates        = Cast_List( -list => $plate_id,     -to => 'string' )                  if $plate_id;
    my $plate_numbers = Cast_List( -list => $plate_number, -to => 'string' )                  if $plate_number;
    my $runs          = Cast_List( -list => $run_id,       -to => 'string' )                  if $run_id;
    my $run_names = Cast_List( -list => $run_name, -to => 'string', -autoquote => 1 ) if $run_name;

##########################################
    # Retrieve Record Data from the Database #
##########################################

    ## Generate Condition ##
    my $tables         = 'Run,RunBatch,Equipment,Plate,Library,SequenceAnalysis';
    my $join_condition = "WHERE Run.FK_RunBatch__ID=RunBatch.RunBatch_ID";
    $join_condition .= " AND RunBatch.FK_Equipment__ID = Equipment.Equipment_ID";
    $join_condition .= " AND Run.FK_Plate__ID = Plate.Plate_ID";
    $join_condition .= " AND Plate.FK_Library__Name = Library.Library_Name";

    #   $join_condition .= " AND SequenceAnalysis.FK_SequenceRun__ID = Run.Run_ID";

    my $left_join_tables = '';

    ## specify optional tables to include (with associated condition) - used in 'include_if_necessary' method ##
    my $join_conditions = {
        'Vector_Based_Library'          => "Vector_Based_Library.FK_Library__Name=Library.Library_Name",
        'Library_Plate'                 => "Library_Plate.FK_Plate__ID=Plate.Plate_ID",
        'Branch'                        => "Plate.FK_Branch__Code = Branch.Branch_Code",
        'Branch_Condition'              => "Branch_Condition.FK_Branch__Code = Branch.Branch_Code",
        'Object_Class as Primer_Object' => "Object_Class.Object_Class='Primer'",

        #			   'Primer'             => "Chemistry_Code.FK_Primer__Name=Primer.Primer_Name",
        'Primer'           => "Branch_Condition.Object_ID = Primer.Primer_ID AND Primer_Object.Object_Class_ID = Branch_Condition.FK_Object_Class__ID",
        'SequenceAnalysis' => "SequenceAnalysis.FK_SequenceRun__ID = Run.Run_ID",
    };

    ## specify optional tables to LEFT JOIN - used in 'include_if_necessary' method  ##
    my $left_join_conditions = { 'LibraryPrimer' => "Library.Library_Name=LibraryPrimer.FK_Library__Name AND Primer.Primer_Name=LibraryPrimer.FK_Primer__Name" };

    my @extra_conditions;
    if ($study_ids)     { }                                                                          ## <CONSTRUCTION> - re-generate '$libraries' variable... ##
    if ($project_ids)   { push( @extra_conditions, "Library.FK_Project__ID in ($project_ids)" ); }
    if ($libraries)     { push( @extra_conditions, "Library.Library_Name in ($libraries)" ) }
    if ($plates)        { push( @extra_conditions, "Plate.Plate_ID in ($plates)" ) }
    if ($plate_numbers) { push( @extra_conditions, "Plate.Plate_Number in ($plate_numbers)" ) }
    if ($runs)          { push( @extra_conditions, "Run.Run_ID in ($runs)" ) }

    ## Include runs (ie Approved / Production / Billable ##
    if ( $include =~ /\bapproved\b/i )   { push( @extra_conditions, "Run_Validation = 'Approved'" ) }
    if ( $include =~ /\bproduction\b/i ) { push( @extra_conditions, "Run_Status = 'Production'" ) }
    if ( $include =~ /\bbillable\b/i )   { push( @extra_conditions, "Billable = 'Yes'" ) }

    ## Special inclusion / exclusion options ##
    if ($since) { push( @extra_conditions, " AND Run_DateTime >= '$since'" ) }
    if ($until) { push( @extra_conditions, " AND Run_DateTime <= '$until'" ) }

    ## Retrieve list of applicable Experiments / Runs ##
    my $conditions = join ' AND ', @extra_conditions;
    $conditions ||= 1;

    ## default field list
    my @field_list = ( 'run_id', 'run_time', 'machine', 'employee', 'library', 'plate_number', 'Average_Q20', 'Average_Length', 'Total_Length', 'chemistry_code', 'vector', 'library_format', 'direction' );

    if ( $group || $KEY && ( $group !~ /^(run_name|run_id)$/ ) && ( $KEY !~ /^(run_name|run_id)$/ ) ) {
        ## IF grouping runs
        push( @field_list, "Count(*) as runs", 'latest_run', 'first_plate_created' );
    }
    else {
        ## IF returning one run per record ##
        push( @field_list, ( 'Plate_ID', 'sequencer', 'vector', 'primer', 'run_time', 'run_id', 'run_name', 'unused_wells', 'direction', 'plate_created', 'plate_class', 'library_format', 'parent_quadrant', 'plate_position', 'run_status', 'validation' ) );
    }

    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }

    ## retrieve mapping of simple names to actual fields
    my %Fields = %{ &alDente::alDente_API::map_to_fields( -fields => \@field_list, -tables => "Run,$tables" ) };
    map {
        my $newfield = $_;
        if ( $Fields{$newfield} ) {
            $newfield = "$Fields{$newfield} as $newfield";
        }
        $_ = $newfield;
    } @field_list;

    ## Add optional fields if necessary (check fields requested, conditions for extra tables)
    my ( $add_tables, $add_conditions, $left_joins ) = ( 1, 1, 1 );    # set on to go through loop at least once
    my $max_tries = 5;                                                 ## just to make sure we don't get caught in some kind of endless loop...

    while ( $max_tries && ( $add_tables || $left_joins ) ) {           # execute recursively in case one optional join implicates another
        ( $add_tables, $add_conditions, $left_joins ) = &alDente::alDente_API::include_if_necessary(
            -fields     => \@field_list,
            -condition  => $conditions,
            -table_list => "$tables $left_join_tables",
            -join       => $join_conditions,
            -left_join  => $left_join_conditions
        );
        ## Update tables, conditions, left_joins ##
        $tables           .= $add_tables;
        $conditions       .= $add_conditions;
        $left_join_tables .= $left_joins;
        $max_tries--;
    }

    if ($limit) { $limit = "LIMIT $limit" }
    if ($group) { $group = "GROUP BY $group" }

    my %data = &Table_retrieve( $dbc, "$tables $left_join_tables", \@field_list, "$join_condition AND $conditions $group $limit", -limit => $limit, -group => $group ) if @field_list;
    return \%data;
}

##################################
#
# Given a set of optional parameters this will return a list of valid runs
#
# This should be used to initiate any more complex data queries by first extracting applicable runs.
#
# <snip>
#  Example:
#   my @list = get_run_list(-project_id=>4);
# </snip>
#
# Return: \@run_list (array of integer values)
###############
sub get_run_list {
###############
    my %args = filter_input( \@_ );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }

    $args{-fields} = 'run_id';    ## alias for run id field
    my %run_data = get_run_data(%args);

    return $run_data{run_id};     ## array reference to list of runs returned
}

##############################
#
# Appends $comment to the current run comments of $run_ids
#
###################
sub annotate_runs {
###################
    my %args = &filter_input( \@_, -args => 'run_ids,comments', -mandatory => 'run_ids,comments' );

    my $run_ids  = $args{-run_ids};
    my $comments = $args{-comments};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $quiet    = $args{-quiet};

    $dbc->message("Commented runs: ($run_ids), with $comments") unless ($quiet);
    $comments = $dbc->dbh()->quote($comments);

    my $ok = $dbc->Table_update_array( 'Run', ['Run_Comments'], [ "CASE WHEN LENGTH(Run_Comments) > 1" . " THEN CONCAT(Run_Comments,'; ',$comments)" . " ELSE $comments" . " END" ], "WHERE Run_ID IN ($run_ids)", );

    return $ok;
}

##############################
#
# Sets the run status of a set of $run_ids
#
###########################
sub set_run_status {
###########################
    my %args = &filter_input( \@_, -args => 'run_ids,status' );
    my $run_ids = Cast_List( -list => $args{-run_ids}, -to => 'string' );
    my $status  = $args{-status};
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $quiet   = $args{-quiet};

    my @valid_states = $dbc->get_enum_list( 'Run', 'Run_Status' );
    my $ok;
    if ( grep( /^$status$/, @valid_states ) ) {
        $ok = $dbc->Table_update_array( 'Run', ['Run_Status'], [$status], "WHERE Run_ID IN ($run_ids)", -autoquote => 1 );
        $dbc->message("Changed the status of $ok Run(s) to $status") unless ($quiet);
    }
    return $ok;
}

##############################
#
# Sets the run status of a set of $run_ids
#
###########################
sub set_run_test_status {
###########################
    my %args = &filter_input( \@_, -args => 'run_id, test_status', -mandatory => 'run_id,test_status' );
    my $run_ids = Cast_List( -list => $args{-run_id}, -to => 'string' );
    my $status  = $args{-test_status};
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $quiet   = $args{-quiet};

    my @valid_states = $dbc->get_enum_list( 'Run', 'Run_Test_Status' );
    my $ok;
    if ( grep( /^$status$/, @valid_states ) ) {
        $ok = $dbc->Table_update_array( 'Run', ['Run_Test_Status'], [$status], "WHERE Run_ID IN ($run_ids)", -autoquote => 1 );
        $dbc->message("Changed the status of $ok Run(s) to $status") unless ($quiet);
    }
    return $ok;
}

##############################
#
# Sets the validation status of a set of $run_ids
#
###########################
sub set_validation_status {
###########################
    my %args         = &filter_input( \@_, -args => 'run_ids,status' );
    my $status       = $args{-status};
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $run          = $args{-run_id} || $args{-run_ids} || get_param( -field => 'Mark', -list => 1, -empty => 0 ) || get_param( -field => 'run_id', -list => 1 );    ## array ref to list of run_ids
    my $comments     = $args{-comments} || param('Comments');
    my $auto_comment = $args{-auto_comment};                                                                                                                          ### flag to automatically comment run with validation stamp (user date)
    my $quiet        = $args{-quiet};

    my @valid_states = $dbc->get_enum_list( 'Run', 'Run_Validation' );
    my $run_ids = Cast_List( -list => $run, -to => 'string' );
    unless ( $run_ids =~ /[1-9]/ && grep( /^$status$/, @valid_states ) ) {
        $dbc->message("Unable to find runs ($run_ids) or validation status ($status)") unless ($quiet);
        return 0;
    }

    if ($auto_comment) {
        ## automatically append comments with string: "<initials> set to <validation> (<date>); " ##
        my ($date) = split ' ', date_time();
        $comments = $dbc->get_local('user_initials') . " set to $status ($date); " . $comments;
    }

    my $ok = $dbc->Table_update_array( 'Run', ['Run_Validation'], [$status], "WHERE Run_ID IN ($run_ids)", -autoquote => 1, -comment => $comments );
    if ( $ok && $comments ) {
        ## add comments if applicable ##
        annotate_runs( -dbc => $dbc, -run_ids => $run_ids, -comments => $comments );
    }

    $dbc->message("Changed the status of $ok Run(s) to $status") unless ($quiet);
    return $ok;
}
#########################
sub set_billable_status {
#########################
    my %args            = filter_input( \@_, -args => 'dbc,run_id,billable_status' );
    my $dbc             = $args{-dbc};
    my $run_id          = $args{-run_id};
    my $quiet           = $args{-quiet};
    my $billable_status = $args{-billable_status};
    my $comments        = $args{-billable_comments};
    my $from_invoice    = $args{-from_invoice} || 0;                                    # just to make sure its not recursively calling each other.
    my $run_ids         = Cast_List( -list => $run_id, -to => 'String' );

    my @valid_states = $dbc->get_enum_list( 'Run', 'Billable' );
    unless ( $run_ids =~ /[1-9]/ && grep( /^$billable_status$/, @valid_states ) ) {
        $dbc->message("Unable to find runs ($run_ids) or billable status ($billable_status)") unless ($quiet);
    }

    my $ok = $dbc->Table_update_array( 'Run', ['Billable'], [$billable_status], "WHERE Run_ID IN ($run_ids)", -autoquote => 1, -comment => $comments );

    # additional update to invoiceable_work table as we migrate towards invoiceable fields into more specific tables
    if ( $ok && !$from_invoice ) {
        my @iw_id = $dbc->Table_find_array( 'Invoiceable_Work INNER JOIN Invoiceable_Run ON FK_Invoiceable_Work__ID = Invoiceable_Work_ID', ['Invoiceable_Work_ID'], "WHERE FK_Run__ID IN ($run_ids) " );
        require alDente::Invoice;
        alDente::Invoice::change_billable_status( -dbc => $dbc, -invoiceable_work_id => \@iw_id, -billable_status => $billable_status, -billable_comments => $comments, -from_run => 1 );
    }

    return $ok;
}

#######################
sub set_run_qc_status {
#######################
    my %args         = &filter_input( \@_, -args => 'run_ids,qc_status' );
    my $status       = $args{-qc_status};
    my $dbc          = $args{-dbc};
    my $run          = $args{-run_id} || $args{-run_ids} || get_param( -field => 'Mark', -list => 1, -empty => 0 ) || get_param( -field => 'run_id', -list => 1 );    ## array ref to list of run_ids
    my $comments     = $args{-comments} || param('Comments');
    my $auto_comment = $args{-auto_comment};                                                                                                                          ### flag to automatically comment run with validation stamp (user date)
    my $quiet        = $args{-quiet};
    my @valid_states = $dbc->get_enum_list( 'Run', 'QC_Status' );
    my $run_ids      = Cast_List( -list => $run, -to => 'string' );
    if ($auto_comment) {
        ## automatically append comments with string: "<initials> set to <validation> (<date>); " ##
        my ($date) = split ' ', date_time();
        $comments = $dbc->get_local('user_initials') . " set to $status ($date); " . $comments;
    }
    my $ok = $dbc->Table_update_array( 'Run', ['QC_Status'], [$status], "WHERE Run_ID IN ($run_ids)", -autoquote => 1 );
    if ( $ok && $comments ) {
        ## add comments if applicable ##
        annotate_runs( -dbc => $dbc, -run_ids => $run_ids, -comments => $comments );
    }
    $dbc->message("Changed the QC status of $ok Run(s) to $status") unless ($quiet);
    return $ok;
}

#############################
#  sets analysis status of a run object
#
############################
sub set_analysis_status {
############################
    my %args      = &filter_input( \@_, -args => 'dbc,run_ids,run_type,status', -mandatory => 'dbc,run_ids,run_type,status' );
    my $dbc       = $args{-dbc};
    my $run_ids   = Cast_List( -list => $args{-run_ids}, -to => 'string' );
    my $run_type  = $args{-run_type};
    my $status    = $args{-status};
    my $details   = $args{-details};
    my $timestamp = $args{-timestamp};
    my $quiet     = $args{-quiet};

    my $run_analysis = $run_type . 'Analysis';
    my $status_id = join ',', $dbc->Table_find( 'Status', 'Status_ID', "WHERE Status_Type='$run_analysis' AND Status_Name='$status' LIMIT 1" );

    unless ($status_id) {
        $dbc->error("Invalid status: '$status' for $run_analysis") unless ($quiet);
        return 0;
    }
    my $plate_ids = join ',', $dbc->Table_find( 'Run', 'FK_Plate__ID', "WHERE Run_ID IN ($run_ids)" );

    ### Record Prep
    my %input;
    $input{'Current Plates'} = $plate_ids;
    my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $dbc->get_local('user_id') );

    $dbc->start_trans('Run_set_analysis_status');

    my @update_fields = ('FK_Status__ID');
    my @update_values = ($status_id);

    ## Disallow changing of values such as key fields...
    my @avail_fields = $dbc->get_field_list( -table => $run_analysis );
    my @restricted_fields = ( "${run_analysis}_ID", 'FK_Run__ID' );
    my ( $common, $avail_only, $restricted_only ) = &RGmath::intersection( \@avail_fields, \@restricted_fields );
    @avail_fields = @{$avail_only};

    if ($details) {
        foreach my $key ( keys %{$details} ) {
            if ( grep( /^$key$/, @avail_fields ) ) {
                push( @update_fields, $key );
                push( @update_values, $details->{$key} );
            }
            else {
                $dbc->warning("Ignoring $key. Invalid property") unless ($quiet);
            }
        }
    }

    $dbc->Table_update_array( $run_analysis, \@update_fields, \@update_values, "WHERE FK_Run__ID IN ($run_ids)", -autoquote => 1 );
    my $step_name;
    if ( $status eq 'Completed' ) {
        $step_name = 'Completed Protocol';
    }
    else {
        $step_name = "$run_analysis: $status";
    }
    $Prep->Record( -protocol => 'Run Analysis', -step => $step_name, -ids => $plate_ids, -input => \%input, -timestamp => $timestamp );
    $dbc->finish_trans('Run_set_analysis_status');
    $dbc->message("Set the $run_analysis status of ($run_ids) to '$status'") unless ($quiet);
    return 1;
}

#################################
#  HTML output blocks for runs ##
#################################

########################################################################
# Return: Horizontal bar containing links pertinent to runs
##########################
sub run_view_options {
##########################
    my %args         = &filter_input( \@_, -args => 'plate_id,run_id', -mandatory => 'plate_id,run_id' );
    my $plate_id     = $args{-plate_id};
    my $run_id       = $args{-run_id};
    my $more_options = $args{-more_options};
    my $dbc          = $args{-dbc};

    my $run_view_options;
    $run_view_options .= &Link_To( $dbc->config('homelink'), "Plate",    "&HomePage=Plate&ID=$plate_id" ) . hspace(10);
    $run_view_options .= &Link_To( $dbc->config('homelink'), "Ancestry", "&Display Ancestry=1&Plate_ID=$plate_id" ) . hspace(10);
    $run_view_options .= &Link_To( $dbc->config('homelink'), "History",  "&cgi_application=alDente::Container_App&rm=Plate+History&FK_Plate__ID=$plate_id" ) . hspace(10);

    $run_view_options .= hspace(10) . $more_options if $more_options;

    return hr . $run_view_options . hr;    ## (bracket list of options with horizontal lines)
}

sub run_status_btn {
    my %args          = filter_input( \@_, -args => "dbc" );
    my $dbc           = $args{-dbc};
    my $status_filter = "unset_mandatory_validators(this.form);";
    $status_filter .= "unset_mandatory_validators(this.form);";
    $status_filter .= "document.getElementById('run_validator').setAttribute('mandatory',1);";
    $status_filter .= "document.getElementById('comments_validator').setAttribute('mandatory',(this.form.ownerDocument.getElementById('run_status').value=='Failed') ? 1 : 0);";
    $status_filter .= "return validateForm(this.form)";
    my $run_status_btn = submit( -name => 'Set_Run_Status', -value => 'Set Run Status', -class => 'Action', -onClick => "$status_filter" );

    # there's also a param in Button Options called 'Run Status'. Will cause problems if '_' removed in 'Run_Status'
    $run_status_btn .= hspace(10)
        . popup_menu(
        -name    => 'Run_Status',
        -values  => [ '', get_enum_list( $dbc, 'Run', 'Run_Status' ) ],
        -default => '',
        -id      => 'run_status',
        -force   => 1
        );
    $run_status_btn .= set_validator( -name => 'run_status', -id => 'run_validator' );
    return $run_status_btn;
}

sub set_run_test_status_btn {
    my %args = filter_input( \@_, -args => "dbc" );
    my $dbc = $args{-dbc};

    # there's also a param in Button Options called 'Run Status'. Will cause problems if '_' removed in 'Run_Status'
    my $run_test_status_options = popup_menu(
        -name    => 'Run_Test_Status',
        -values  => [ '', get_enum_list( $dbc, 'Run', 'Run_Test_Status' ) ],
        -default => '',
        -id      => 'run_status',
        -force   => 1
    );

    my $onClick = "sub_cgi_app( 'alDente::Run_App' )";

    my $form_output;
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Set Run Test Status', -class => 'Action', -onClick => $onClick, -force => 1 ), "Set Run Test Status" );
    $form_output .= hspace() . $run_test_status_options;
    $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );
    return $form_output;
}

##########################
sub catch_run_status_btn {
##########################
    my %args = filter_input( \@_, -args => "dbc,run,runs" );
    my $dbc = $args{-dbc};

    my $run  = param('Run_Status');
    my @runs = param('Mark');
    unless (@runs) {
        @runs = param('run_id');
    }
    my $comments = param('Comments');
    if ( param('Set_Run_Status') ) {
        my $ok = set_run_status( -dbc => $dbc, -run_ids => \@runs, -status => $run );
        my $runs = Cast_List( -list => \@runs, -to => 'String' );
        if ($ok) {
            annotate_runs( -dbc => $dbc, -run_ids => $runs, -comments => $comments );
        }
    }
    return;
}
############################
sub catch_run_billable_btn {
############################
    my %args   = filter_input( \@_, -args => "dbc,run_id" );
    my $dbc    = $args{-dbc};
    my $run_id = $args{-run_id};

    my $runs              = $args{-run_id} || get_param( -parameter => 'Mark', -empty => 0, -list => 1 ) || get_param( -parameter => 'run_id', -list => 1 );
    my $billable_status   = param('Billable');
    my $billable_comments = param('Billable_Comments');
    if ( param('Set Run Billable Status') ) {
        my $ok = set_billable_status( -dbc => $dbc, -run_id => $runs, -billable_status => $billable_status, -billable_comments => $billable_comments );
    }
    return;
}
######################
sub run_billable_btn {
######################
    my %args              = filter_input( \@_, -args => 'dbc' );
    my $dbc               = $args{-dbc};
    my $validation_filter = "unset_mandatory_validators(this.form);";
    $validation_filter .= "unset_mandatory_validators(this.form);";
    $validation_filter .= "document.getElementById('billable_validator').setAttribute('mandatory',1);";
    $validation_filter .= "document.getElementById('billable_comments_validator').setAttribute('mandatory',1);";
    $validation_filter .= "return validateForm(this.form)";
    my $run_billable_btn = submit( -name => 'Set Run Billable Status', -value => "Set Billable Status", -class => 'Action', -onClick => "$validation_filter" );
    $run_billable_btn .= hspace(10) . popup_menu( -name => 'Billable', -id => 'Billable', -values => [ '', get_enum_list( $dbc, 'Run', 'Billable' ) ], -force => 1 );
    $run_billable_btn .= set_validator( -name => 'Billable', -id => 'billable_validator' );
    $run_billable_btn .= set_validator( -name => 'Billable_Comments', -id => 'billable_comments_validator' ) . " Billable Comments: " . textfield( -name => 'Billable_Comments', -size => 30, -default => '' );
    return $run_billable_btn;
}

######################
sub update_billable_comments_btn {
######################
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc  = $args{-dbc};
    my $btn  = submit( -name => 'Update Billable Comments', -value => "Update Billable Comments", -class => 'Action' ) . ' comments: ' . textfield( -name => 'comments', -size => 20 );
    return $btn;
}

##########################
sub catch_update_billable_comments_btn {
##########################
    my %args     = filter_input( \@_, -args => "dbc" );
    my $dbc      = $args{-dbc};
    my $comments = param('comments');
    my @marked   = param('Mark') || param('run_id');
    if ( param('Update Billable Comments') ) {
        my $records = join ',', @marked;
        my $ok = $dbc->Table_update_array( 'DBField, Change_History', ['Comment'], [$comments], "WHERE FK_DBField__ID = DBField_ID  and Field_Name =  'Billable' and Field_Table = 'Run' and Record_ID IN ($records) ", -autoquote => 1 );
        if ($ok) {
            $dbc->message("Updated $ok records");
        }
    }
    return;
}

sub run_validation_btn {
    my %args              = filter_input( \@_, -args => "dbc" );
    my $dbc               = $args{-dbc};
    my $auto_comment      = $args{-auto_comment};
    my $btn_name          = $args{-btn_name} || 'Set_Validation_Status';
    my $validation_filter = "unset_mandatory_validators(this.form);";
    $validation_filter .= "unset_mandatory_validators(this.form);";
    $validation_filter .= "document.getElementById('validation_validator').setAttribute('mandatory',1);";
    $validation_filter .= "document.getElementById('comments_validator').setAttribute('mandatory',(this.form.ownerDocument.getElementById('validation_status').value=='Rejected') ? 1 : 0);";
    $validation_filter .= "return validateForm(this.form)";
    my $run_validation_btn = submit( -name => $btn_name, -value => 'Set Validation Status', -class => 'Action', -onClick => "$validation_filter" );

    $run_validation_btn .= hspace(10)
        . popup_menu(
        -name    => 'Validation Status',
        -values  => [ '', get_enum_list( $dbc, 'Run', 'Run_Validation' ) ],
        -default => '',
        -id      => 'validation_status',
        -force   => 1
        );
    $run_validation_btn .= set_validator( -name => 'Validation Status', -id => 'validation_validator' );
    $run_validation_btn .= set_validator( -name => 'Comments', -id => 'comments_validator' ) . " Comments: " . textfield( -name => 'Comments', -size => 30, -default => '' );
    $run_validation_btn .= hidden( -name => 'Auto_Comment', -value => $auto_comment );

    return $run_validation_btn;
}

#######################################
# Accessor to set run validation
#
# <snip>
#   (retrieves parameters automatically from run_validation_btn method)
#
#   (direct call examples):
#
#   my $updated = alDente::Run::catch_run_validation_btn($dbc,'Approved',[1000,2000]);
#   my $updated = alDente::Run::catch_run_validation($dbc,-auto_comment=>1);     ## if parameters match expected parameters; auto_comment appends run_comments with '<initials> set to <validation> (<date>);'
# </snip>
#
# Return: 1 on success
###############################
sub catch_run_validation_btn {
###############################
    my %args         = filter_input( \@_, -args => "dbc,validation,runs" );
    my $dbc          = $args{-dbc};
    my $validation   = $args{-validation} || param('Validation Status');
    my $auto_comment = $args{-auto_comment} || param('Auto_Comment');                                                                                      ### flag to automatically comment run with validation stamp (user date)
    my $run          = $args{-run_id} || get_param( -parameter => 'Mark', -empty => 0, -list => 1 ) || get_param( -parameter => 'run_id', -list => 1 );    ## array ref to list of run_ids
    my $comments     = $args{-comments} || param('Comments');
    my $set_status   = $args{-set_status} || param('Set_Validation_Status');                                                                               ## not sure why this is necessary, but included to prevent changing logic
    if ($set_status) {
        my $ok = set_validation_status( -dbc => $dbc, -run_ids => $run, -status => $validation, -auto_comment => $auto_comment );
    }
    return 1;
}

##############################
# private_methods            #
##############################

#################################################################################
# Get next applicable sequence subdirectory (for re-running with same branch)
#
# Either pass a basename and figure out the version, or provide a set of plate_ids.
#
#############
sub _nextname {
#############
    my %args = &filter_input( \@_, -args => 'basename,plate_ids,check_branch,sufix' );

    my $name         = $args{-basename};
    my $plates       = Cast_List( -list => $args{-plate_ids}, -to => 'string' );
    my $check_branch = $args{-check_branch};                                                            ### Error out if branch does not exist
    my $sufix        = $args{-suffix};                                                                  # array ref of sufix matching to each plate id
    my $existing     = $args{-existing};                                                                ## running list of all the current run dirs being retrieved
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    unless ( $name || $plates ) {
        $dbc->error("No inputs provided");
        return 0;
    }

    my %plates_info;

    if ($plates) {
        ### Retrieve all the run directories of the Runs generated from the same original plate of this plate, and make sure to pick a Run_Directory which is unique

        my %plates_hash = $dbc->Table_retrieve( 'Plate', [ 'Plate_ID', 'FK_Branch__Code AS Branch', "CONCAT(FK_Library__Name,'-',Plate_Number,Parent_Quadrant) AS Name" ], "WHERE Plate_ID IN ($plates)" );

        my $index = -1;
        if ( $plates_hash{Plate_ID} ) {
            while ( $plates_hash{Plate_ID}[ ++$index ] ) {
                $plates_info{ $plates_hash{Plate_ID}[$index] }{Name}   = $plates_hash{Name}[$index];
                $plates_info{ $plates_hash{Plate_ID}[$index] }{Branch} = $plates_hash{Branch}[$index];

            }
        }
        else {
            $dbc->error("Invalid Plates");
            return 0;
        }

        $index = -1;
        my $error;
        my @run_dirs;
        my @Plates = split ',', $plates;
        while ( $Plates[ ++$index ] ) {

            my $run_dir = $plates_info{ $Plates[$index] }{Name};
            my $branch  = $plates_info{ $Plates[$index] }{Branch};
            my $suf     = $sufix->[$index];

            if ( $check_branch && !$branch ) {
                $dbc->error("Plate $Plates[$index] does not have a branch!");
                $error = 1;
                next;
            }

            $run_dir .= '.' . $branch;
            $run_dir .= '.' . $suf if ($suf);

            push( @run_dirs, &alDente::Run::_nextname( -basename => $run_dir, -existing => \@run_dirs, -dbc => $dbc ) );    ### Recursive call
        }
        return ( \@run_dirs, $error );

    }
    elsif ($name) {
        ### Retrieve all the run directories of similar name
        my @existing = Cast_List( -list => $args{-existing}, -to => 'array' );
        @existing = grep( /^$name/, @existing );
        push @existing, $dbc->Table_find( 'Run', 'Run_Directory', "WHERE Run_Directory LIKE '$name%'" );
        my $newname = $name;
        my $max_ver;
        if ( grep( /\.\d+$/, @existing ) ) {                                                                                ### Have versions
            foreach (@existing) {
                $_ =~ /^(.*)\.(\d+)$/;
                $max_ver = $2 if ( $2 > $max_ver );
            }
            $max_ver++;
            $newname = "$name.$max_ver";
        }
        elsif (@existing) {                                                                                                 ### No versions, only have the first one
            $newname = "$name.1";
        }
        return $newname;
    }
}

###############
sub _copy_batch {
###############
    my $self = shift;
    my %args = @_;

    my $batch_id = $args{-batch};
    my $newdate  = $args{-date};
    my $comments = $args{-comments} || '';
    my $user_id  = $args{-user_id} || 0;

    my $Batch = SDB::DB_Object->new( -tables => 'RunBatch', -dbc => $self->{dbc} );
    $Batch->primary_value( -table => 'Run', -value => $batch_id );

    $Batch->load_Object();
    $Batch->value( 'RunBatch_ID',              'NULL' );
    $Batch->value( 'RunBatch_RequestDateTime', $newdate );
    $Batch->value( 'RunBatch_Comments',        $comments );
    $Batch->value( 'FK_Employee__ID',          $user_id );

    my $feedback = $Batch->insert();

    my $newid = $feedback->{id};
    print "(Batch $batch_id->$newid)";
    return $newid;
}

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

Ran Guin

Andy Chan

=head1 CREATED <UPLINK>

2003-11-05

=head1 REVISION <UPLINK>

$Id: Run.pm,v 1.6 2004/09/08 23:31:50 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
