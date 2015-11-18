package Mapping::Mapping_Statistics;

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

  $self->{config}{API_scope}   = 'gelrun'; # use get_genechip_xxx
  $self->{config}{API_type}    = 'summary'; # use get_xxx_summary
  #$self->{config}{key_field}   = 'project_id';
  $self->{config}{view_tables} = 'Run,Plate,GelRun,RunBatch';

  return;
}

################################
sub set_input_options {
################################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc} || $Connection;
    $self->SUPER::set_input_options;
    

    my $title = $self->{config}{title};

    # find group for Mapping Base
    my ($group_id) = $self->{dbc}->Table_find("Grp", "Grp_ID", "where Grp_Name = 'Mapping'");

    $self->{API_args}{-group_id}{value} = Cast_List(-list=>[$group_id], -to=>"String");
    $self->{API_args}{-group_id}{preset} = 1;

    # if you want the list to be multiple selectable, you need to provide your own list

    $self->{config}{input_options} = {
				      'Library.FK_Project__ID' =>{argument=>'-project_id', value=>''},
				      'Run.Run_DateTime'=>{argument=>'', default=>'<TODAY>', value=>''},
				      'Run.Run_Status' =>{argument=>'-run_status', default=> ['Initiated','In Process','Data Acquired','Analyzed'], value=>''},
				      'Run.Run_Validation' =>{argument=>'-run_validation', default=> ['Approved','Pending'], value=>''},
				      'Run.Billable' => {argument=>'-billable', value=>''},
				     };

    $self->{config}{input_order} = [
				    'Library.FK_Project__ID',
				    'Run.Run_DateTime',
				    'Run.Run_Status',
				    'Run.Run_Validation',
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

    # general output for mapping and expression
    $self->{config}{output_options} = {
				       'run_id_count' => {picked => 1},
				      };


    $self->{config}{output_order} = [
				     'run_id_count',
				    ];

    $self->{config}{group_by} = { # these need to be the same as they appear in the API as output fields
				 'month' => {picked => 1},
				 'year' => {picked => 1},
				 'project' => {picked => 0},
				 'pipeline_name' => {picked => 0},
				 'branch_code' => {picked => 0},
				 'library' => {picked => 0},
				};

    return;
}






return 1;
