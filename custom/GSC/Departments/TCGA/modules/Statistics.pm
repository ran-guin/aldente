###################################################################################################################################
# TCGA::Statistics.pm
#
#
#
#
###################################################################################################################################
package TCGA::Statistics;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules
use alDente::View;
use vars qw( $Connection $user_id $homelink %Configs );

our @ISA = qw( alDente::View );

##############################
sub set_general_options {
##############################
  my $self = shift;
  my %args = filter_input(\@_);

  $self->SUPER::set_general_options;

  $self->{config}{API_module }  = 'TCGA_API';
  $self->{config}{API_path   }  = 'TCGA';
  $self->{config}{API_scope  }  = 'TCGA_Run';   # use get_TCGA_run_xxx
  $self->{config}{API_type   }  = 'data';         # use get_xxx_data
  $self->{config}{key_field  }  = 'run_id';
  $self->{config}{view_tables}  = 'Run, Plate';  
  $self->{config}{actions} = [
      'alDente::Run::run_status_btn(-dbc=>$self->{dbc});',
      'alDente::Run::run_billable_btn(-dbc=>$self->{dbc});',
    ];
  $self->{config}{catch_actions} = [
    'alDente::Run::catch_run_status_btn(-dbc=>$self->{dbc});',
    'alDente::Run::catch_run_billable_btn(-dbc=>$self->{dbc});',
    ];
  
 

  return;

}

################################
sub set_input_options {
################################
    my $self = shift;
    my %args = filter_input(\@_);

    $self->SUPER::set_input_options;

    $self->{config}{input_options} = {
        'Library.FK_Project__ID' => { argument => '-project_id',     value => '' },
        'Plate.Plate_ID'         => { argument => '-plate_id',       value => '' },
        'Plate.FK_Library__Name' => { argument => '-library',        value => '' },
        'Plate.Plate_Number'     => { argument => '-plate_number',   value => '' },
        'Run.Run_DateTime'       => { argument => '',                value => '' },
        'Run.Run_ID'             => { argument => '-run_id',         value => '' },
        'Run.Run_Status'         => { argument => '-run_status',     value => '' },
        'Run.Run_Validation'     => { argument => '-run_validation', value => '' },
        'RunBatch.FK_Equipment__ID' => { argument => '-equipment' => '' },
    };

    $self->{config}{input_order} = [
        'Library.FK_Project__ID',
        'Plate.Plate_ID',
        'Plate.FK_Library__Name',
        'Plate.Plate_Number',
        'Flowcell.Flowcell_Code',
        'Run.Run_DateTime',
        'Run.Run_ID',
        'Run.Run_Status',
        'Run.Run_Validation',
        'RunBatch.FK_Equipment__ID',
    ];

    return;

}



#################################
sub set_output_options {
#################################
    my $self = shift;
    my %args = filter_input(\@_);

    $self->SUPER::set_input_options;

    $self->{config}{output_options} = {
        'run_id'           => { picked => 1 },
        'run_status'       => { picked => 1 },
        'run_validation'   => { picked => 1 },
        'project'          => { picked => 1 },
        'run_time'         => { picked => 1 },
        'billable'         => { picked => 1 },
        'run_comments'     => { picked => 1 },
        'flowcell_code'    => { picked => 1 },
        'lane'             => { picked => 1 },
        'plate_id'         => { picked => 1 },
        'pipeline'         => { picked => 1 },
        'library'          => { picked => 1 },
        'plate_number'     => { picked => 1 },
        'machine'          => { picked => 1 },
    };

    $self->{config}{output_order} = [
        'run_id',
        'run_validation',   
        'billable',
        'run_status',
        'run_time',
        'machine',
        'run_name',
        'project',
        'plate_id',
        'library',
        'plate_number',
        'pipeline',
        'run_initiated_by',
        'subdirectory',
        'run_QC_status',
    ];

    $self->{config}{output_link} = {
        'run_id'      => "&Scan=1&Barcode=run<value>",
        'plate_id'    => "&Scan=1&Barcode=Pla<value>",
        'library'     => "&HomePage=Library&ID=<value>",
    };
    $self->{config}{output_function} = {
        'full_run_path' => "get_TCGA_Statistics_html",
        'pipeline' => "get_pipeline_of_parent_plate",
    };
    return;

}

1;
