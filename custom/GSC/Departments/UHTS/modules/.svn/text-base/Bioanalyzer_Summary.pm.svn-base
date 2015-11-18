package UHTS::Bioanalyzer_Summary;



@ISA = qw(alDente::View);

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
use vars qw($Connection $user_id $homelink);


sub set_general_options {
  my $self = shift;
  my %args = filter_input(\@_);
  $self->SUPER::set_general_options;


  $self->{config}{API_module}  = 'Microarray_API';
  $self->{config}{API_path}    = 'UHTS';
  $self->{config}{API_scope}   = 'bioanalyzerrun'; # use get_genechiprun_xxx
  $self->{config}{API_type}    = 'data'; # use get_xxx_data

  $self->{config}{key_field}   = 'run_id';
  $self->{config}{view_tables} = 'Run,BioanalyzerRun';

  return;
}



################################
sub set_input_options {
################################
    my $self = shift;
    my %args = filter_input(\@_);
    $self->SUPER::set_input_options;

    $self->{config}{input_options} = {
				      'Library.FK_Project__ID' =>{argument=>'-project_id', value=>''},
				      'Run.Run_ID' =>{argument=>'-run_id', value=>''},
				      'Run.Run_Status' =>{argument=>'-run_status', value=>''},
				      'Run.Run_Validation' =>{argument=>'-run_validation', value=>''},
				      'Run.Run_DateTime'=>{argument=>'', value=>''},
				     };

    $self->{config}{input_order} = [
				      'Library.FK_Project__ID',
				      'Run.Run_DateTime',
				      'Run.Run_ID',
				      'Run.Run_Status',
				      'Run.Run_Validation',
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
				       'run_id' => {picked=>1},
				       'run_time' => {picked=>1},
				       'bioanalyzerrun_invoiced' => {picked => 1},
				       'billable' => {picked => 1},
				       'run_status' => {picked=>1},
				       'validation' => {picked=>1},
				      };



    $self->{config}{output_order} = [
				     'run_id',
				     'run_time',
				     'bioanalyzerrun_invoiced',
				     'billable',
				     'run_status',
				     'validation',
				    ];
    return;
}


################################
#
#
#
#################
sub get_actions{
#################
    my $self = shift;

    my $title = $self->{config}{title};

    my %actions;

    my $dbc = $self->{dbc} || $Connection;

    $actions{1} = submit(-name=>'Set_Billable', -value=>'Set Billable', -class=>'Action')
                 . '&nbsp;'
                 . popup_menu(-name=>'Billable', -values=>[$dbc->get_enum_list('Run', 'Billable')], -default=>'Yes', -id=>'billable', -force=>1);


    $actions{2} = submit(-name=>'Set_Invoiced', -value=>'Set Invoiced', -class=>'Action')
                 . '&nbsp;'
                 . popup_menu(-name=>'Invoiced', -values=>[$dbc->get_enum_list('GenechipRun', 'Invoiced')], -default=>'No', -id=>'invoiced', -force=>1);



    return %actions;
}


################
sub do_actions {
################
  my $self = shift;

  my @ids;
  if(param('SelectRun')) {
    @ids = param('SelectRun');
  } elsif(param('run_id')) {
    @ids = param('run_id');
  }
  my $dbc = $self->{dbc};



  if(scalar @ids > 0){
    my $ids_string = join (",", @ids);

    if (param ("Set_Billable")){
      my $billable = param ("Billable");
      if($billable){
	my $ok = $dbc->Table_update_array('Run',['Billable'],[$billable],"WHERE Run_ID in ($ids_string)",-autoquote=>1);
	Message("Updated $ok records");
      }
    }elsif (param ("Set_Invoiced")){
      my $invoiced = param ("Invoiced");
      if($invoiced){
	my $ok = $dbc->Table_update_array('BioanalyzerRun',['Invoiced'],[$invoiced],"WHERE Run_ID in ($ids_string)",-autoquote=>1);
	Message("Updated $ok records");
      }
    }
  } else {

  }

}

1;
