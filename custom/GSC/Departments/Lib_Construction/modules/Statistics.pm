package Lib_Construction::Statistics;

use strict;

use CGI qw(:standard);
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Views;
use alDente::Tools;

## alDente modules
use alDente::View;
use vars qw($Connection $user_id $homelink %Benchmark);

our @ISA = qw(alDente::View);

################################
sub set_general_options {
################################

    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_general_options;

    my $title = $self->{config}{title};

    $self->{config}{API_module}  = 'Solexa_API';
    $self->{config}{API_path}    = 'Experiment/Illumina';
    $self->{config}{API_scope}   = 'solexa_run';
    $self->{config}{API_type}    = 'data';                  # use get_xxx_data
    $self->{config}{key_field}   = 'run_id';
    $self->{config}{view_tables} = 'SolexaRun';
    my @cached_links = ( 'SEQ - Overnight Protocols Completed', 'SEQ - PCR Setup 384 Completed', 'SEQ - Preps Completed', 'SEQ - Reactions Completed', 'SEQ - Rxns completed by Library', 'SEQ - Precipitations Completed', 'SEQ - Resuspensions Completed' );

    # $self->set_custom_cached_links(-cached_links=>\@cached_links);

    return;
}

################################
sub set_input_options {
################################
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_input_options;

    my $title = $self->{config}{title};
    my $dbc   = $self->{dbc};

    $self->{config}{input_options} = {
        'Library.FK_Project__ID' => { argument => '-project_id', value => '' },
        'Plate.FK_Library__Name' => { argument => '-library',    value => '' },
        'Run.Run_DateTime'       => { argument => '',            value => '' },

        #				      'Genechip_Type.Sub_Array_Type'        => {argument=>'-sub_array_type',    value=>'', list=>\@sub_array_type_list},
        'SolexaRun.Solexa_Sample_Type' => { argument => '-solexa_sample_type', value => '' },

    };

    $self->{config}{input_order} = [ 'Library.FK_Project__ID', 'Plate.FK_Library__Name', 'Run.Run_DateTime', 'SolexaRun.Solexa_Sample_Type', ];

    return;
}

#################################
sub set_output_options {
#################################
    my $self = shift;
    my %args = filter_input( \@_ );
    $self->SUPER::set_input_options;
    my $title = $self->{config}{title};

    $self->{config}{output_options} = {
        'library'             => { picked => 1 },
        'Phasing'             => { picked => 0 },
        'Prephasing'          => { picked => 0 },
        'Read_Length'         => { picked => 1 },
        'solexarun_finished'  => { picked => 1 },
        'Tiles_Analyzed'      => { picked => 1 },
        'solexa_raw_clusters' => { picked => 1 },
        'PF_Clusters_Percent' => { picked => 1 },
        'PF_alignment'        => { picked => 0 },
        'Lane_Yield_KB'       => { picked => 1 },
        'PF_Clusters'         => { picked => 1 },
    };

    $self->{config}{output_order} = [
        'library',
        'solexarun_finished',
        'Tiles_Analyzed',
        'solexa_raw_clusters',
        'PF_Clusters_Percent',
        'PF_alignment',
        'Lane_Yield_KB',
        'PF_Clusters',
        'Read_Length',
        'Phasing',
        'Prephasing',

    ];

    $self->{config}{order_by} = {    # these need to be the same as they appear in the API as output fields
        'project'       => { picked => 1 },
        'library'       => { picked => 1 },
        'pipeline_name' => { picked => 0 },
    };

    return;
}

return 1;
