package Lib_Construction::Spect_Summary;



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

##############
# Constructor for the Spect_Summary
#
##############
sub new {
##############
    my $this  = shift;
    my $class  = ref($this) || $this;
    my %args = filter_input(\@_);

    my $self = {};

    $self = alDente::View->new();
    $self->{scope} = 'spectread';
    $self->{view_tables} = 'Run,SpectRun,SpectRead';
    $self->{view_name} = "Spectrophotometer Summary Page";
    $self->{command_name} = "Spect_Summary";
    $self->{key_field} = 'run_id';
    $self->{link}{library} = "&Scan=1&Barcode=<value>";

    bless $self, $class; 
    return $self;
}

################################
sub preset_input_fields {
################################
    my $self = shift;
    my $preset_inputs = {
	                    'Library.FK_Project__ID' =>{argument=>'-project_id'},
	                    'Run.Run_ID' =>{argument=>'-run_id'},
			    'Run.Run_Status' =>{argument=>'-run_status'},
			    'Run.Run_Validation' =>{argument=>'-run_validation'},
			    'Plate.FK_Library__Name' =>{argument=>'-library'},
			    'Plate.Plate_Number' => {argument=>'-plate_number'},
			    'Run.Run_DateTime'=>{argument=>''},
			    }; 
    my @order = qw(
        Library.FK_Project__ID
        Plate.FK_Library__Name
        Plate.Plate_Number
        Run.Run_DateTime
        Run.Run_ID
        Run.Run_Status
        Run.Run_Validation
    );
    
    $self->configure_input_fields(-fields=>$preset_inputs,-order=>\@order);
    return 1;
}
################
sub configure {
################
    my $self = shift;    
    $self->{view_tables} = 'Run,GenechipRun';

    $self->preset_input_fields();
    $self->preset_output_fields();
};

########################
#
# Return a set of inputs for views that are provided by default
#
#
#
########################
sub get_default_inputs {
########################
    my %args = (

    );
    return %args;
}

# Set default inputs
# 
########################
sub set_default_inputs {
########################
    my $self = shift;
    my %args = (

    );
    return %args;

}

#################################
sub preset_output_fields {
#################################
    my $self = shift;

    ## also allow the following fields to be chosen as output 
    my @allow = qw(
		   run_time
		   );   
    ## set the defaults
    my @order = qw(
		   run_id
		   well
		   sample_name
		   dilution_factor
		   A260_A280_ratio
		   spec_concentration
		   unit
		   A260m
		   A260cor
		   A260
		   A280m
		   A280cor
		   A280
		   well_status
		   );
    
#    my $fields = Cast_List(-list=>\@order,-to=>'string');

    $self->configure_output_fields(-tables=>$self->{view_tables},-prepick=>\@order,-fields=>[@order,@allow]);
    $self->{view_defaults} = $self->{view_outputs};

    return 1;
}




################################
#
#
#
#################
sub get_actions{
#################
    my $self = shift;
    my $dbc = $self->{dbc} || $Connection;
    my %actions;

    $actions{1} = submit(-name=>'Set Validation Status',-class=>'Action',-onClick=>"
        unset_mandatory_validators(this.form);
        document.getElementById('comments_validator').setAttribute('mandatory',(this.form.ownerDocument.getElementById('validation_status').value=='Rejected') ? 1 : 0)
        return validateForm(this.form)
        ") . '&nbsp;' . popup_menu(-name=>'Validation Status',-values=>['',get_enum_list($dbc,'Run','Run_Validation')],-default=>'',-id=>'validation_status',-force=>1);


    $actions{2} = set_validator(-name=>'Comments',-id=>'comments_validator') .
            submit(-name=>'Annotate Runs',-class=>'Action',-onClick=>"return validateForm(this.form)") .  
            Show_Tool_Tip(textfield(-name=>'Comments',-size=>30,-default=>''),"Mandatory for Rejected and Failed runs");



    my $groups = $dbc->get_local('group_list');
    my $reasons = alDente::Fail::get_reasons(-dbc=>$dbc,-object=>'Run',-grps=>$groups);
  
    $actions{3} = submit(-name=>'Set as Failed',-class=>'Action',-onClick=>"
        unset_mandatory_validators(this.form);
document.getElementById('failreason_validator').setAttribute('mandatory',1);
document.getElementById('comments_validator').setAttribute('mandatory',1);
return validateForm(this.form)") . '&nbsp;' . popup_menu(-name=>'FK_FailReason__ID',-values=>['',sort keys %{$reasons}],-labels=>$reasons,-force=>1) . set_validator(-name=>'FK_FailReason__ID',-id=>'failreason_validator');

    return %actions;
}


