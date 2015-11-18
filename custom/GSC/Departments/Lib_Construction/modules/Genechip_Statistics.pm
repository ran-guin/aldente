package Lib_Construction::Genechip_Statistics;




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



sub set_general_options {
  my $self = shift;
  my %args = filter_input(\@_);
  $self->SUPER::set_general_options;

  my $title = $self->{config}{title};

  $self->{config}{API_module}  = 'Microarray_API';
  $self->{config}{API_path}    = 'Lib_Construction';
  $self->{config}{API_scope}   = 'genechiprun'; # use get_genechip_xxx
  $self->{config}{API_type}    = 'summary'; # use get_xxx_summary
  #$self->{config}{key_field}   = 'project';
  $self->{config}{view_tables} = 'Run, Plate';

  return;
}

################################
sub set_input_options {
################################
    my $self = shift;
    my %args = filter_input(\@_);
    $self->SUPER::set_input_options;

    my $title = $self->{config}{title};
    my $dbc = $self->{dbc};

    # preset values
    $self->{API_args}{-analysis_type}{value} = Cast_List(-list=>["Expression","Mapping"], -to=>"String",-autoquote=>1);
    $self->{API_args}{-analysis_type}{preset} = 1;

    # if you want the list to be multiple selectable, you need to provide your own list
    # set -sub_array_type and -name values

    my @genechip_type_name_list = $dbc->Table_find("Genechip_Type", "Genechip_Type_Name");
    my @sub_array_type_list = $dbc->Table_find("Genechip_Type", "Sub_Array_Type");

    @genechip_type_name_list = sort {$a cmp $b} @genechip_type_name_list;
    @sub_array_type_list = sort {$a cmp $b} @sub_array_type_list;

    $self->{config}{input_options} = {
				      'Library.FK_Project__ID'              => {argument=>'-project_id',        value=>''},
				      'Plate.FK_Library__Name'              => {argument=>'-library',           value=>''},
				      'Run.Run_DateTime'                    => {argument=>'',                   value=>''},
				      #'Run.Run_Status'                      => {argument=>'-run_status',        value=>''},
				      #'Run.Run_Validation'                  => {argument=>'-run_validation',    value=>''},
				      'Genechip_Type.Sub_Array_Type'        => {argument=>'-sub_array_type',    value=>'', list=>\@sub_array_type_list},
				      'Genechip_Type.Genechip_Type_Name'                  => {argument=>'-genechip_type_name',              value=>'', list=>\@genechip_type_name_list},
				      'Run.Billable'                        => {argument=>'-billable',          value=>''},

				     };

    $self->{config}{input_order} = [
				    'Library.FK_Project__ID',
				    'Plate.FK_Library__Name',
				    'Run.Run_DateTime',
				    #'Run.Run_Status',
				    #'Run.Run_Validation',
				    'Genechip_Type.Sub_Array_Type',
				    'Genechip_Type.Genechip_Type_Name',
				    'Run.Billable',
				   ];

    return;
}






#################################
sub set_output_options {
#################################
    my $self = shift;
    my %args = filter_input(\@_);
    $self->SUPER::set_input_options;
    my $title = $self->{config}{title};

    # output_options are those from Genechip_Summary concatenated with '_functionname', where functionname is 'count', 'avg', 'sum', 'min', 'max' or 'stddev'. Note that group_by items will be added automatically if they are not specified in the output_options
    $self->{config}{output_options} = {
				       'run_id_count' => {picked => 1},
				      };


    $self->{config}{output_order} = [
				     'run_id_count',
				    ];

    $self->{config}{group_by} = { # these need to be the same as they appear in the API as output fields
				 'project' => {picked => 1},
				 'library'    => {picked => 0},
				 'pipeline_name' => {picked => 0},
				 'genechiprun_invoiced' => {picked => 0},
				};

    return;
}






return 1;
