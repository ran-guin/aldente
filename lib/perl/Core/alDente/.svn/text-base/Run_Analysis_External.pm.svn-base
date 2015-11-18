###################################################################################
# alDente::Run_Analysis_External.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
####################################################################################
package alDente::Run_Analysis_External;
use base qw(alDente::Run_Analysis);

use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use alDente::Run;
use alDente::Invoice;

use vars qw( %Configs );

sub load_Object {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->{dbc};
    my $id   = $self->{id};

    # print "DEBUG: auto loading!\n";
    my ($data) = $dbc->Table_find( 'External_Run_Analysis', 'Input_Directory, Output_Directory', "Where FK_Run_Analysis__ID = $id" );
    my ( $input_directory, $base_directory ) = split( ',', $data );
    my $run_analysis_path = $self->get_run_analysis_path( -base_name => 'BWA' );
    my $output_directory = $base_directory . "/" . "$run_analysis_path";

    $self->{base_directory}   = $base_directory;
    $self->{input_directory}  = $input_directory;
    $self->{output_directory} = $output_directory;

    return;
}

sub get_base_directory {
    my $self                     = shift;
    my %args                     = @_;
    my $dbc                      = $args{-dbc} || $self->{dbc};
    my $external_run_analysis_id = $args{-external_run_analysis_id};
    my ($out) = $dbc->Table_find( "External_Run_Analysis", "Output_Directory", "WHERE External_Run_Analysis_ID = $external_run_analysis_id" );

    return $out;

}

#########################################################################
# Checks to do before the external run analysis is even appended. Helps reduce the amount of Aborted External_Run_Analysis in the DB.
#
###########################
sub pre_start_checks {
###########################
    my $self        = shift;
    my %args        = &filter_input( \@_, -mandatory => 'config_hash' );
    my %config_hash = %{ $args{-config_hash} };
    my $pass        = 1;

    #### Check the desire fastq read_length in config with that of the actual fastq readlength #####
    #### <CONSTRUCTION FASTQ MUST BE .GZ FORMAT AS POST STEP CAN'T HANDLE .FASTQ FORMAT> ###########
    if ( $config_hash{read_length} ) {

        if ( $config_hash{read1} ) {
            my $fastq = $config_hash{input_directory} . "/" . $config_hash{read1};
            print "$fastq\n";
            my ( $unless_header, $sequence ) = split( "\n", try_system_command("gunzip -c $fastq | head -2") );

            unless ( length $sequence == $config_hash{read_length} ) {
                print "READ_LENGTH CHECK FAILED\n";
                return 0;
            }
        }
        if ( $config_hash{read2} ) {
            my $fastq = $config_hash{input_directory} . "/" . $config_hash{read2};
            print "$fastq\n";
            my ( $unless_header, $sequence ) = split( "\n", try_system_command("gunzip -c $fastq | head -2") );

            unless ( length $sequence == $config_hash{read_length} ) {
                print "READ_LENGTH CHECK FAILED\n";
                return 0;
            }
        }
    }
    #### End of First Check, Additional pre analysis checks can be included below #####

    return $pass;
}

#########################################################################
# Create a new Run_Analysis record and start the first step of the analysis pipeline
#
###########################
sub start_run_analysis {
###########################
    my $self                     = shift;
    my %args                     = &filter_input( \@_, -mandatory => 'external_run_analysis_id, analysis_pipeline_id' );
    my $dbc                      = $args{-dbc} || $self->{dbc};
    my $external_run_analysis_id = $args{-external_run_analysis_id};
    my $analysis_pipeline_id     = $args{-analysis_pipeline_id};
    my $force                    = $args{-force};
    my $run_analysis_type        = 'Secondary';
    my $now                      = $args{-date_time} || &date_time();
    my ($sample_id)              = '16117794';

    #Check if analysis is already in progress, if it is, can't continue unless force
    #Create a new Run_Analysis record

    #$dbc->Table_find( "Run,Plate,Plate_Sample", "FK_Sample__ID", "WHERE FK_Plate__ID = Plate_ID and Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND Run_ID = $run_id" );
    Message("$external_run_analysis_id, $analysis_pipeline_id, $sample_id");

    my @run_analysis_fields = ( 'Run_Analysis_Started', 'Run_Analysis_Status', 'FK_Run__ID', 'FKAnalysis_Pipeline__ID', 'Current_Analysis', 'FK_Sample__ID', 'Run_Analysis_Type' );
    my @run_analysis_values = ( $now, 'Analyzing', 'NULL', $analysis_pipeline_id, 'Yes', $sample_id, $run_analysis_type );
    my $run_analysis_id = $dbc->Table_append_array( 'Run_Analysis', \@run_analysis_fields, \@run_analysis_values, -autoquote => 1, -no_triggers => 1 );

    ## check to see if parent exists
    #add run analysis record to database
    # print "DEBUG:ALDENTE::Run_Analysis Run_Analysis created $run_analysis_id\n";
    #add analysis_step records to database

    my @analysis_steps = $dbc->Table_find( "Pipeline_Step", "Pipeline_Step_ID", "WHERE FK_Pipeline__ID = $analysis_pipeline_id" );
    for my $analysis_step (@analysis_steps) {
        my @analysis_step_fields = ( 'FK_Run_Analysis__ID', 'FK_Pipeline_Step__ID' );
        my @analysis_step_values = ( $run_analysis_id, $analysis_step );
        my $analysis_step_id = $dbc->Table_append_array( 'Analysis_Step', \@analysis_step_fields, \@analysis_step_values, -autoquote => 1 );
    }

    # print "DEBUG:ALDENTE::Run_Analysis Analysis_Step created\n";
    #update External_Run_Analysis_Status to Analyzing
    my $update;
    $update = $dbc->Table_update_array( "External_Run_Analysis", [ "Status", "FK_Run_Analysis__ID" ], [ 'Analyzing', "$run_analysis_id" ], "WHERE External_Run_Analysis_ID = $external_run_analysis_id", -autoquote => 1 )
        if $run_analysis_type eq 'Secondary';

    # print "DEBUG:ALDENTE::Run_Analysis External_run_Analysis updated\n";
    #Create a run_analysis log file
    my $log_file = $self->get_analysis_log( -run_analysis_id => $run_analysis_id );

    #try_system_command("touch $log_file");

    # print "DEBUG:ALDENTE::Run_Analysis log file created: $log_file\n";

    if ($run_analysis_id) {
        $self->{id} = $run_analysis_id;
        $self->primary_value( -table => 'Run_Analysis', -value => $run_analysis_id );
        $self->load_Object( -debug => 0 );
    }

    return $run_analysis_id;
}

1;
