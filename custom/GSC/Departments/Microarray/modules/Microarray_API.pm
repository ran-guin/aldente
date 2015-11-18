################################################################################
# Microarray_API.pm
#
# This module handles custom data access functions for the microarray plug-in
#
###############################################################################
package Microarray_API;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Microarray_API.pm - This module handles custom data access functions for the Microarray plug-in

=head1 SYNOPSIS <UPLINK>

 #### Example of Usage ####

 ## Connect to the database (you may define the parameters early on and only connect later if necessary) ##
 my $API = Microarray_API->new(-dbase=>'sequence',-host=>'athena',-user=>'viewer',-password=>$pass);
 $API->connect();

 ## get genechip run data
 my @fields = ('run_id', 'analysis_type', 'analysis_datetime','alpha1','alpha2','tau','noise_rawq',
               'scale_factor','norm_factor','avg_a_signal','avg_p_signal','avg_m_signal','tgt');

 my $data = $API->get_genechiprun_data(-analysis_type=>'Expression', -run_validation=>'Approved', -fields=>\@fields);

 ## looping through the result
 foreach my $item (@$data) {
     my $run_id = $item->{run_id};
     my $analysis_type = $item->{analysis_type};
 }

 ## get genechip run statistics data
 $data = $API->get_genechiprun_summary(-group_by=>['project_id', 'library'], -analysis_type=>'Expression',
                                       -count=>['run_id','run_status'], 
                                       -avg=>['avg_a_signal', 'avg_o_signal', 'avg_m_signal'],
                                       -max=>['avg_a_signal'],
                                       -min=>['avg_p_signal'], 
                                       -stddev=>['avg_m_signal'])

 $data = $API->get_genechiprun_summary(-group_by=>['project_id', 'library'], -analysis_type=>'Mapping',
                                       -count=>['run_id','run_status'], 
                                       -avg=>['total_snp', 'qc_mcr_percent', 'qc_mdr_percent'])

 ## looping through the result
 foreach my $item (@$data) {
     my $project_id = $item->{project_id};
     my $library = $item->{library};
     my $analysis_type = $item->{analysis_type};
     my $run_id_count = $item->{run_id_count};
     my $total_snp_avg = $item->{total_snp_avg};
 }

 #### Checking for possible fields that can be used ####

 ## get a list of the fields recoverable from the 'get_genechiprun_data' method
 my %info = %{ $API->get_genechiprun_data(-list_fields=>1) };


 #######################################################################
 # Note: for more options and details see alDente::alDente_API module ##
 #        (including details on using web services to access API)      #
 #######################################################################


=head1 DESCRIPTION <UPLINK>

=for html

 This module handles custom data access functions for the Microarray plug-in<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(alDente::alDente_API);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;
use Carp;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::DB_Object;
use SDB::CustomSettings;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGIO;

use alDente::alDente_API;

##############################
# global_vars                #
##############################
##############################
# custom_modules_ref #
##############################
##############################
# global_vars #
##############################
use vars qw($AUTOLOAD $testing $Security $project_dir $Web_log_directory $Connection %Aliases);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################

##############################
# main_header                #
##############################

##############################
# public_methods             #
##############################

#########################################################
# Retrieve data about Genechip Runs
#
# <SNIP>
# Example:
#   my @fields = ('analysis_type', 'analysis_datetime','alpha1','alpha2','tau','noise_rawq',
#                 'scale_factor','norm_factor','avg_a_signal','avg_p_signal','avg_m_signal','tgt');
#   my $data = $API->get_genechiprun_data(-analysis_type=>'Expression', -run_validation=>'Approved', -fields=>\@fields);
#   @fields = ('analysis_type', 'analysis_datetime', 'total_snp','qc_mcr_percent','qc_mdr_percent',
#              'snp_call_percent','aa_call_percent','ab_call_percent','bb_call_percent');
#   $data = $API->get_genechiprun_data(-analysis_type=>'Mapping', -run_validation=>'Pending', -fields=>\@fields);
#   ## looping through the result
#   foreach my $item (@$data) {
#     my $run_id = $item->{run_id};
#     my $analysis_type = $item->{analysis_type};
#   }
#</SNIP>
#
######################
sub get_genechiprun_data {
######################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input( \@_ );

    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields        = $args{-fields};           ### specify output field list
    my $add_fields    = $args{-add_fields};
    my $analysis_type = $args{-analysis_type};    ### specify analysis_type: Expression or Mapping
    my $sub_array_type
        = $args{-sub_array_type};    ### specify sub type for the assay: one of '500K Mapping','250K Mapping','100K Mapping','10K Mapping','Other Mapping','Human Expression','Rat Expression','Mouse Expression','Yeast Expression' or 'Other Expression'
    my $scanner_equipment = $args{-scanner_equipment};
    my $run_status        = $args{-run_status};            ### specify run status: one of 'In Process','Analyzed','Aborted','Failed','Expired' or 'Not Applicable'
    my $run_validation    = $args{-run_validation};        ### specify run validation: one of 'Pending','Approved' or 'Rejected'
    my $name              = $args{-genechip_type_name};    ### specify genechip name: e.g., 'Mapping10K_Xba142'
    my $billable          = $args{-billable};              ### specify if billable: yes or no

    my @field_list = ( 'cel_file', 'dat_file', 'chp_file', 'sample', 'analysis_type', 'analysis_datetime' );

    if ( $analysis_type eq 'Expression' ) {
        my @exp_fields = ( 'alpha1', 'alpha2', 'tau', 'noise_rawq', 'scale_factor', 'norm_factor', 'avg_a_signal', 'avg_p_signal', 'avg_m_signal', 'tgt' );
        push( @field_list, @exp_fields );
    }
    elsif ( $analysis_type eq 'Mapping' ) {
        my @map_fields = ( 'total_snp', 'qc_mcr_percent', 'qc_mdr_percent', 'snp_call_percent', 'aa_call_percent', 'ab_call_percent', 'bb_call_percent' );
        push( @field_list, @map_fields );

    }
    my @input_conditions = ();
    if ($analysis_type) {
        push( @input_conditions, "GenechipAnalysis.Analysis_Type in ($analysis_type)" );
    }
    if ($sub_array_type) {
        push( @input_conditions, "Genechip_Type.Sub_Array_Type in ($sub_array_type)" );
    }

    if ($scanner_equipment) {
        push( @input_conditions, "GenechipRun.FKScanner_Equipment__ID in ($scanner_equipment)" );
    }

    if ($run_status) {
        push( @input_conditions, "Run.Run_Status in ($run_status)" );
    }

    if ($run_validation) {
        push( @input_conditions, "Run.Run_Validation in ($run_validation)" );
    }

    if ($name) {
        push( @input_conditions, "Genechip_Type.Genechip_Type_Name in ($name)" );
    }

    if ($billable) {
        push( @input_conditions, "Run.Billable in ($billable)" );
    }

    if (@input_conditions) {
        $args{-condition} = \@input_conditions;
    }

    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    $args{-fields} = \@field_list;

    my $input_joins;
    $input_joins->{'GenechipRun'}      = 'GenechipRun.FK_Run__ID = Run.Run_ID';
    $input_joins->{'Sample'}           = 'GenechipAnalysis.FK_Sample__ID = Sample_ID';
    $input_joins->{'GenechipAnalysis'} = 'GenechipAnalysis.FK_Run__ID = Run.Run_ID';
    $input_joins->{'Plate'}            = "GenechipRun.FK_Plate__ID = Plate_ID";
    $input_joins->{'RNA_DNA_Source'}   = 'RNA_DNA_Source.FK_Source__ID = Source.Source_ID';
    $input_joins->{'Source'}           = 'Library_Source.FK_Source__ID = Source.Source_ID';
    $input_joins->{'Library_Source'}   = 'Library_Source.FK_Library__Name = Library.Library_Name';
    $input_joins->{'Original_Source'}  = 'Source.FK_Original_Source__ID = Original_Source.Original_Source_ID';
    $input_joins->{'Array'}            = 'Array.FK_Plate__ID = Plate.Plate_ID';
    $input_joins->{'Microarray'}       = 'Array.FK_Microarray__ID = Microarray.Microarray_ID';
    $input_joins->{'Genechip'}         = 'Genechip.FK_Microarray__ID = Microarray.Microarray_ID';
    $input_joins->{'Genechip_Type'}    = 'Genechip.FK_Genechip_Type__ID = Genechip_Type.Genechip_Type_ID';
    $input_joins->{'Pipeline'}         = 'Pipeline.Pipeline_ID = Plate.FK_Pipeline__ID';
    my $input_left_joins;
    $input_left_joins->{'GenechipMapAnalysis'} = 'GenechipMapAnalysis.FK_Run__ID = Run.Run_ID';
    $input_left_joins->{'GenechipExpAnalysis'} = 'GenechipExpAnalysis.FK_Run__ID = Run.Run_ID';

    $args{-input_joins}      = $input_joins;
    $args{-input_left_joins} = $input_left_joins;

    return $self->get_run_data(%args);
}

#########################################################
# Retrieve statistics data about Genechip Runs
#
# Available statistics functions:
#  -count: count
#  -avg: average
#  -max: maximum
#  -min: minimum
#  -sub: summary
#  -stddev: standard deviation
#
# Args:
#  -group_by: the output fields to group by. array reference
#  -fields: output field list. array reference. automaticall include group_by fields if not specified here
#  statistics functions specified above: output field list which you want the function to be applied to.
#                                        Note that you need to make sure the functions make sense on these fields. array reference
#  search parameters: as used in get_genechiprun_data
#
# Returns:
# Note that fields with stats functions will appear as field_fucntion as the key in the return data structure. e.g.: run_id_count, avg_a_signal_min, avg_m_signal_stddev
#
# <SNIP>
# Example:
#
#   my $data = $API->get_genechiprun_summary(-group_by=>['project_id', 'library'], -analysis_type=>'Expression',
#                                            -count=>['run_id','run_status'],
#                                            -avg=>['avg_a_signal', 'avg_o_signal', 'avg_m_signal'],
#                                            -max=>['avg_a_signal'],
#                                            -min=>['avg_p_signal'],
#                                            -stddev=>['avg_m_signal'])
#
#   $data = $API->get_genechiprun_summary(-group_by=>['project_id', 'library'], -analysis_type=>'Mapping',
#                                         -count=>['run_id','run_status'],
#                                         -avg=>['total_snp', 'qc_mcr_percent', 'qc_mdr_percent'])
#
#   ## looping through the result
#   foreach my $item (@$data) {
#     my $project_id = $item->{project_id};
#     my $library = $item->{library};
#     my $analysis_type = $item->{analysis_type};
#     my $run_id_count = $item->{run_id_count};
#     my $total_snp_avg = $item->{total_snp_avg};
#   }
#
#</SNIP>
#
###############################
sub get_genechiprun_summary {
###############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    return $self->convert_parameters_for_summary( -scope => 'genechiprun', %args );
}

######################
sub get_spectrun_data {
######################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields     = $args{-fields};
    my $add_fields = $args{-add_fields};

    my @field_list = ( 'scanner_equipment', 'A260_blank_avg', 'A280_blank_avg' );
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    $args{-fields} = \@field_list;

    my $input_joins;
    $input_joins->{'SpectRun'} = 'SpectRun.FK_Run__ID = Run.Run_ID';

    my $input_left_joins;
    $input_left_joins->{'SpectAnalysis'} = 'SpectAnalysis.FK_Run__ID = Run.Run_ID';

    $args{-input_joins}      = $input_joins;
    $args{-input_left_joins} = $input_left_joins;
    return $self->get_run_data(%args);
}

########################
sub get_spectread_data {
########################
    my $self = shift;
    $self->log_parameters(@_);

    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields     = $args{-fields};
    my $add_fields = $args{-add_fields};

    my @field_list = ( 'run_id', 'well', 'well_status', 'A260m', 'A260cor', 'A260', 'A280m', 'A280cor', 'A280', 'A260_A280_ratio', 'dilution_factor', 'concentration', 'unit' );
    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    $args{-fields} = \@field_list;

    my $input_joins;

    $input_joins->{'SpectRun'}      = 'SpectRun.FK_Run__ID = Run.Run_ID';
    $input_joins->{'SpectAnalysis'} = 'SpectAnalysis.FK_Run__ID = Run.Run_ID';
    $input_joins->{'SpectRead'}     = 'SpectRead.FK_Run__ID = Run.Run_ID';
    $input_joins->{'Sample'}        = 'SpectRead.FK_Sample__ID = Sample.Sample_ID';

    $args{-input_joins} = $input_joins;
    $args{-group_by}    = "SpectRead.FK_Run__ID,well";
    return $self->get_run_data(%args);
}

##############################
sub get_bioanalyzerrun_data {
##############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields         = $args{-fields};
    my $add_fields     = $args{-add_fields};
    my $run_status     = $args{-run_status};
    my $run_validation = $args{-run_validation};
    my $billable       = $args{-billable};

    my @field_list = ( 'invoiced', 'analysis_datetime' );

    my @input_conditions = ();

    if ($run_status) {
        push( @input_conditions, "Run.Run_Status in ($run_status)" );
    }

    if ($run_validation) {
        push( @input_conditions, "Run.Run_Validation in ($run_validation)" );
    }

    if ($billable) {
        push( @input_conditions, "Run.Billable in ($billable)" );
    }

    if (@input_conditions) {
        $args{-condition} = \@input_conditions;
    }

    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }

    $args{-fields} = \@field_list;

    my $input_joins;
    $input_joins->{'BioanalyzerRun'}  = 'BioanalyzerRun.FK_Run__ID = Run.Run_ID';
    $input_joins->{'RNA_DNA_Source'}  = 'RNA_DNA_Source.FK_Source__ID = Source.Source_ID';
    $input_joins->{'Source'}          = 'Library_Source.FK_Source__ID = Source.Source_ID';
    $input_joins->{'Library_Source'}  = 'Library_Source.FK_Library__Name = Library.Library_Name';
    $input_joins->{'Original_Source'} = 'Source.FK_Original_Source__ID = Original_Source.Original_Source_ID';

    my $input_left_joins;

    $args{-input_joins}      = $input_joins;
    $args{-input_left_joins} = $input_left_joins;

    return $self->get_run_data(%args);
}

#############################
sub get_bioanalyzerread_data {
#############################
    my $self = shift;
    $self->log_parameters(@_);
    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }
    my $fields     = $args{-fields};
    my $add_fields = $args{-add_fields};

    my @field_list = ( 'scanner_equipment', 'well', 'well_status', 'rna_dna_concentration', 'rna_dna_concentration_unit', 'rna_dna_integrity_number', 'sample_comment' );

    if ($fields) {
        @field_list = Cast_List( -list => $fields, -to => 'array' );
    }
    elsif ($add_fields) {
        my @add_list = Cast_List( -list => $add_fields, -to => 'array' );
        push( @field_list, @add_list );
    }
    $args{-fields} = \@field_list;
    my $input_joins;
    $input_joins->{'BioanalyzerRun'}      = 'BioanalyzerRun.FK_Run__ID = Run.Run_ID';
    $input_joins->{'BioanalyzerAnalysis'} = 'BioanalyzerAnalysis.FK_Run__ID = Run.Run_ID';
    $input_joins->{'BioanalyzerRead'}     = 'BioanalyzerRead.FK_Run__ID = Run.Run_ID';
    $input_joins->{'Sample'}              = 'BioanalyzerRead.FK_Sample__ID = Sample.Sample_ID';

    $args{-input_joins} = $input_joins;
    $args{-group_by}    = "BioanalyzerRun.FK_Run__ID,well";
    return $self->get_run_data(%args);
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

=head1 CREATED <UPLINK>

2003-11-13

=head1 REVISION <UPLINK>

$Id: Sequencing_API.pm,v 1.341 2004/12/03 20:05:20 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
