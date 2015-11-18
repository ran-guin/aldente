##################
# Statistics_App.pm #
##################
#
# This module is used to monitor Goals for Library and Project objects.
#
package Cancer_Genetics::Statistics_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::HTML qw(vspace HTML_Dump display_date_field set_validator);
use alDente::Form;

# use alDente::Cancer_Genetics;
##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);  # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');
    
    $self->run_modes(
	'Home Page'	       => 'home_page', 
	'Display Samples'      => 'display_sources',
	'Display Tubes'       => 'lab_activities',
	'Display Patient Info' => 'display_patient_info',
	'Display Preps'           => 'prep_stats'
    );

    my $dbc = $self->param('dbc');

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    
    return $self;
}


#
# home_page has submit buttons to lead to the other run modes
# Also, displays some basic statistics relevant to each of the run modes 
###############
sub home_page {
###############
 
   my $self = shift;
   my $q = $self->query;
   my $dbc = $self->param('dbc') ;

   my @other_run_modes = ('Display Samples','Display Tubes','Display Preps','Display Patient Info');

   my $home_form = start_custom_form( -name => 'Cancer Genetics Samples', -parameters => {&Set_Parameters} ); 
   $home_form .= Views::Heading ("Cancer Genetics Samples");

   $home_form .= $self->_cg_stats_home_form(-run_modes=>\@other_run_modes);

   return $home_form;
}

#
#run mode: display_sources shows information about sources collected, based on user-entered parameters 
#
##################
sub display_sources {
##################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $default_hist= '-30d';
    my %preset;
    $preset{from_Received_Date} = &date_time($default_hist);
    $preset{to_Received_Date} = &date_time();

    $preset{Source_Status} = ['Active'];
    #Start custom form
    my $form .= start_custom_form(-name=>'Search_Page',-parameters=>{&Set_Parameters()});
    $form .= Views::Heading ("Cancer Genetics - Received Samples");

    $form .= $q-> hidden (-name=> 'cgi_application', -value => 'Cancer_Genetics::Statistics_App',-force=>1);
    $form .= $q-> hidden (-name => 'rm', -value => 'Display Samples',-force=>1);
    $form .= &SDB::HTML::query_form(-dbc=>$dbc, -fields=>['Source.Source_Type','Source.Received_Date','Source.Source_Status','Source.External_Identifier'],-title=>'Received Samples filter criteria',-action=>'search',-preset=>\%preset);
    $form .= $q-> submit(-name =>'Action',-value=>"Search",-class=>"Search",-force=>1);
    $form .= $q->end_form();

    ## Filter parameters
    my @sampletype = $q->param('Source_Type'); ## Source.Source_Type
    my $from_date = $q->param('from_Received_Date'); ## Source.Received_Date
    my $to_date = $q->param('to_Received_Date'); ## Source.Received_Date
    my $quick_link = $q->param('quick_link'); ##quick_link
    my @active = $q->param('Source_Status'); ## Source.Source_Status
    my $labid = $q->param('External_Identifier');
    my $exported = $q->param('Notes'); ## Source.Notes (check notes for string: 'Exported' if Exported plates are desired)

    $form .= $self->get_sources(-sampletype=>\@sampletype,-to_date=>$to_date,-from_date=>$from_date,-quick_link=>$quick_link,-active=>\@active,-labid=>$labid,-exported=>$exported);

    return $form;
}

# <snip>
# Usage example: $form .= $self->get_sources(-to_date=>$to_date,-from_date=>$from_date,-exported=>$exported)
# There are other options for equipment storage conditions, sample type, and status 
# </snip>
# Get Source information given search conditions
##################
sub get_sources {
##################
    my $self        = shift;
    my %args        = &filter_input(\@_);
    my $dbc         = $self->param('dbc');
    my @sampletype  = @{$args{-sampletype}};
    my $to_date     = $args{-to_date};
    my $from_date   = $args{-from_date};
    my $quick_link  = $args{-quick_link};
    my @active      = @{$args{-active}};
    my $labid       = $args{-labid};
    my $exported    = $args{-exported};
    
    my $form;
    ## Display source information except for fields irrelevant to the lab
    my @tables = qw(Source);
    my @display_fields = qw(External_Identifier Received_Date Source_Type FK_Patient__ID);
    my @conditions;    

    if (@sampletype) { push @conditions, "(" . join( ' OR ', map {"Source_Type = '$_'"} @sampletype) . ")" }
    if ($to_date || $from_date) {
        if ($to_date && !$from_date) { $from_date = $quick_link }
        if (!$to_date && $from_date) { $to_date = $quick_link }
        push @conditions, "DATE(Source.Received_Date) BETWEEN '$from_date' AND '$to_date'";
    }
    if (@active) { push @conditions, "(" . join( ' OR ', map {"Source_Status = '$_'"} @active) . ")" }
    if ($labid) { push @conditions, "Source.External_Identifier = '$labid'" }
    if ($exported) { push @conditions, "Notes like '%$exported%'" }

    my $tables = join ',',@tables;
    my $condition = "WHERE ". join(' AND ',@conditions) if @conditions;

    if ($condition) {
	my $sample_display = $dbc->Table_retrieve_display($tables,\@display_fields,$condition,-return_html=>1);
	$form .= Views::sub_Heading ("Search Results");
	$form .= "Condition: $condition<BR>";
	$form .= $sample_display;
    }

    return $form;
}



#run mode:
#show information about Sources and Plates with samples from a particular patient_id
# 
###################
sub display_patient_info {
###################

    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $patientid_ref = $q->param('Source.FK_Patient__ID');
    my $originals = 1;

    my $patientid = $dbc->get_FK_ID('FK_Patient__ID',$patientid_ref);

    ## Prompt for Patient_ID
    my $form .= start_custom_form(-name=>'Search_Page',-parameters=>{&Set_Parameters()});
    $form .= Views::Heading ("Cancer Genetics - Patient Samples");

    $form .= $q-> hidden (-name=> 'cgi_application', -value => 'Cancer_Genetics::Statistics_App',-force=>1);
    $form .= $q-> hidden (-name => 'rm', -value => 'Display Patient Info',-force=>1);
    $form .= 'Enter patient id to retrieve sample/tube summaries <br>';
    $form .= &alDente::Tools::search_list(
					  -name=>'Source.FK_Patient__ID',
					  -breaks=>1,
					  -search=>1,
					  -size=>3,
					  -filter_by_department=>1,
					  -department=>'Cancer_Genetics'
					  );
    $form .= $q->submit(-name =>'Search By Patient ID',-value=>"Search By Patient ID",-class=>"Search",-force=>1,-onClick=>"unset_mandatory_validators(this.form); document.getElementById('Search_By_Patient_ID_validator').setAttribute('mandatory',1); return validateForm(this.form)") . set_validator(-name=>'Source.FK_Patient__ID',-id=>'Search_By_Patient_ID_validator') . &vspace();

    $form .= $q->end_form();

    ## get html output of patient info given a patient id
    $form .= $self->get_patient_info(-patient_id=>$patientid,-originals_only=>$originals);
  
    return $form;
}


#<snip>
#Example:
# my $patientpage = get_patient_info(-patient_id=>10)
#</snip
#Returns: a page with patient info and info about the plates/sources associated with him 
# Find all sources with the given FK_Patient__ID
######################
sub get_patient_info {
######################

    my $self       = shift;
    my %args       = &filter_input(\@_);
    my $dbc        = $self->param('dbc');
    my $patient_id = $args{-patient_id};
    my $originals_only = $args{-originals_only};

    if ($originals_only) {

        Message "To receive plasma or serum aliquoted from original sample, first find the sample by searching for the right Study ID";
	Message"Next, click on the Plate_ID for the sample from which the new sample is derived";

	Message "Then, make aliquots and put the aliquots through the extraction protocol";
    }

    my $page; #put patient info here
    if (!$patient_id) { return $page }

    #Patient table
#    $page .= Views::Heading ("Patient Information");
    my @patient_fields = $dbc->Table_find('DBField,DBTable','Field_Name',"WHERE FK_DBTable__ID = DBTable_ID AND DBTable_Name='Patient' AND Field_Name != 'Patient_ID'");
    my $patient_condition = "WHERE Patient_ID = $patient_id";
    $page .= $dbc->Table_retrieve_display('Patient',\@patient_fields,$patient_condition,-return_html=>1);

    #Get Source IDs and Plate IDs for the given Patient ID
    my $tables = 'Patient,Source,Sample,Plate_Sample,Plate';
    my @fields = qw(Source_ID Plate_ID);
    my $condition = "WHERE FK_Patient__ID = Patient_ID AND FK_Source__ID = Source_ID AND FK_Sample__ID = Sample_ID AND Plate_Sample.FKOriginal_Plate__ID = Plate_ID AND Patient_ID = $patient_id";
    if ($originals_only) {
	$condition .= " AND Sample.FKParent_Sample__ID = 0";
    }
    my %IDs = $dbc->Table_retrieve($tables,\@fields,$condition,-key=>'Source_ID',-debug=>$debug);

    for my $Source_ID (sort {$a<=>$b} keys %IDs) {
	#Display Source table
	my @source_fields = qw( Source_Type Received_Date Collected_Date FK_Patient__ID);
	my $source_condition = "WHERE Source_ID = $Source_ID";
	$page .= &vspace();

	    $page .= Views::sub_Heading ("Sample Summary for Source: $Source_ID",-1);
	    $page .= $dbc->Table_retrieve_display('Source',\@source_fields,$source_condition,-return_html=>1);


	my $Plate_IDs = join(",", @{$IDs{$Source_ID}{Plate_ID}});
	#Display Plates table
	my @plate_fields = qw(Plate_ID Plate_Number Plate_Created Plate_Content_Type Plate_Status FK_Plate_Format__ID FK_Rack__ID );
	my $plate_condition = "WHERE Plate_ID in ($Plate_IDs)";

	   # $page .= Views::sub_Heading (": $Source_ID",-1);
	    
	$page .= $dbc->Table_retrieve_display('Plate',\@plate_fields,$plate_condition,-return_html=>1);
	
    }
    return $page;
}


#run mode: lab_activities
#display information about plates (tubes only in the case of Cancer_Genetics)
#
##################
sub lab_activities { 
##################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my %preset;

    $preset{Plate_Status}=['Active'];
#    $preset{FK_Rack__ID}=[''];
    #Search table
    my $form .= start_custom_form(-name=>'Search_Page',-parameters=>{&Set_Parameters()});
    $form .= Views::Heading ("Cancer Genetics - Tubes")
;
    $form .= $q-> hidden (-name=> 'cgi_application', -value => 'Cancer_Genetics::Statistics_App',-force=>1);
    $form .= $q-> hidden (-name => 'rm', -value => 'Display Tubes',-force=>1);  
    $form .= &SDB::HTML::query_form(-dbc=>$dbc, -fields=>['Equipment.Equipment_Condition','Plate.Plate_Content_Type','Plate.Plate_Created','Plate.Plate_Status','Plate.FK_Rack__ID','Source.External_Identifier'],-title=>'Tube filter criteria',-action=>'search',-preset=>\%preset);

    $form .= $q-> submit(-name =>'Action',-value=>"Search",-class=>"Search",-force=>1);
    $form .= $q->end_form();

    ## Filter parameters
    my @eqcondition = $q->param('Equipment_Condition'); ## Plate->Rack->Equipment->Equipment.Equipment_Conditions
    my @sampletype = $q->param('Plate_Content_Type'); 
    my $to_date = $q->param('to_Plate_Created') ; ## Plate.Plate_Created
    my $from_date = $q->param('from_Plate_Created') ; ## Plate.Plate_Created
    my $quick_link = $q->param('quick_link'); ##quick_link
    my @status = $q->param('Plate_Status'); ## Plate.Plate_Status
    my @location = $q->param('FK_Rack__ID Choice');
    my $labid = $q->param('External_Identifier'); ## Plate<-Plate_Sample->Sample->Source->Source.External_Identifier

    $form .= $self->get_lab_activities(-eqcondition=>\@eqcondition,-sampletype=>\@sampletype,-to_date=>$to_date,-from_date=>$from_date,-quick_link=>$quick_link,-status=>\@status,-location=>\@location,-labid=>$labid);

    return $form;
}
#<snip>
#Usage example: $form .= $self->get_lab_activities(-to_date=>$to_date,-from_date=>$from_date,-status=>\@status);
#Other options available include location (rack), and lab_id
#</snip>
###################
sub get_lab_activities {
###################
    my $self        = shift;
    my %args        = &filter_input(\@_);
    my $dbc         = $self->param('dbc');
    my @eqcondition = @{$args{-eqcondition}};
    my @sampletype  = @{$args{-sampletype}};
    my $to_date     = $args{-to_date};
    my $from_date   = $args{-from_date};
    my $quick_link  = $args{-quick_link};
    my @status      = @{$args{-status}};
    my @location    = @{$args{-location}};
    my $labid       = $args{-labid};
    
    my $form;
    ## List the attributes of each plate
    my @tables = qw(Plate);
    #my @display_fields = map {"Plate.$_"} $dbc->Table_find('DBField,DBTable','Field_Name',"WHERE FK_DBTable__ID = DBTable_ID AND DBTable_Name='Plate'");
    my @display_fields = qw(Plate_ID Plate_Number Plate_Created Plate_Content_Type FK_Rack__ID FK_Pipeline__ID FK_Library__Name Plate_Status);
    push @display_fields, "FKLast_Prep__ID AS Last_Prep";
    my @conditions;

    if (@eqcondition) {
        push @tables, 'Equipment';
        push @tables, 'Rack';
        my $joineqcondition = "(" . join( ' OR ', map { "Equipment_Condition = '$_'"} @eqcondition) . ")";
        push @conditions, "$joineqcondition AND FK_Rack__ID = Rack_ID AND Rack.FK_Equipment__ID = Equipment.Equipment_ID";
    }

    if (@sampletype) { push @conditions, "(" . join( ' OR ', map {"Plate_Content_Type = '$_'"} @sampletype) . ")" }
    if ($to_date || $from_date) {
        if ($to_date && !$from_date) { $from_date = $quick_link }
        if (!$to_date && $from_date) { $to_date = $quick_link }
        push @conditions, "DATE(Plate.Plate_Created) BETWEEN '$from_date' AND '$to_date'";
    }
    if (@status) { push @conditions, "(" . join( ' OR ', map {"Plate_Status = '$_'"} @status) . ")" }
    if (@location) {
	push @conditions, "(" . join( ' OR ', map {"concat(\"Rac\",Rack.Rack_ID,\": \",Rack_Alias) = '$_'"} @location) . ")"; 
	if (!@eqcondition) {
	    push @tables, 'Rack';
	}
    }
    if ($labid) {
	push @tables, 'Plate_Sample';
	push @tables, 'Sample';
	push @tables, 'Source';
	push @conditions, "External_Identifier = '$labid' AND FK_Source__ID = Source_ID AND FK_Sample__ID = Sample_ID AND Plate_Sample.FKOriginal_Plate__ID = Plate_ID"
    }

    my $tables = join ',',@tables;
    my $condition = "WHERE ". join(' AND ',@conditions) if @conditions;

    if ($condition) {
	#$debug = 1;
	$tables .= " LEFT JOIN Plate_Prep ON (Plate_ID = FK_Plate__ID AND FK_Prep__ID IN (SELECT Prep_ID FROM Prep WHERE Prep_Name = 'Export')) LEFT JOIN Prep ON Prep_ID = FK_Prep__ID";	
	if (grep /^Exported$/, @status) {
	    push @display_fields, "Prep_Comments as Export_Prep_Comments";
	}
        my $sample_display = $dbc->Table_retrieve_display($tables,\@display_fields,$condition,-return_html=>1,-debug=>$debug);
        $form .= Views::sub_Heading ("Search Results");
        $form .= "Condition: $condition<BR>";
        $form .= $sample_display;
    }
    return $form;
}


#run mode: prep_stats
#display Prep information, filtered by protocol, failures, or dates
#
###################
sub prep_stats {
###################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    
    my $protocol = $q->param('Lab_Protocol_Name'); ## Use to filter Prep.FK_Lab_Protocol__ID 
    my $to_date = $q->param('to_Prep_DateTime'); ## Prep.Prep_DateTime
    my $from_date = $q->param('from_Prep_DateTime'); ## Prep.Prep_DateTime
    my $quick_link = $q->param('quick_link'); ##quick_link
    ## Only look at failed preps is an option
    my @prep_action = $q->param('Prep_Action'); #Prep.Prep_Action
    #my $failed_prep = $q->param('failed_prep'); ## Prep.Prep_Failure_Date
    ## Can also filter based on FailureReason
    #my $failedonly = $q->param('failed'); ## Prep.FK_FailureReason__ID

    ##set default prep filter criteria

    my $form .= start_custom_form(-name=>'Search_Page',-parameters=>{&Set_Parameters()});
    $form .= Views::Heading ("Cancer Genetics - Preps");

    $form .= $q-> hidden (-name=> 'cgi_application', -value => 'Cancer_Genetics::Statistics_App',-force=>1);
    $form .= $q-> hidden (-name => 'rm', -value => 'Display Preps',-force=>1);

    #$form .= &SDB::HTML::query_form(-dbc=>$dbc, -fields=>['Lab_Protocol.Lab_Protocol_Name','Prep.Prep_DateTime','Prep.Prep_Action']);
    require SDB::DB_Form;
    my $DBform = SDB::DB_Form->new(-dbc=>$dbc,-fields=>['Lab_Protocol.Lab_Protocol_Name','Prep.Prep_DateTime','Prep.Prep_Action'],-start_form=>0,-end_form=>0,-wrap=>0);
    my @lab_protocol_names = $dbc->Table_find('Lab_Protocol','Lab_Protocol_Name');
    my %list;
    $list{'Lab_Protocol_Name'} = \@lab_protocol_names;
    my %preset = ();
#    $preset{'Prep_DateTime'} = &date_time();
		  
    $DBform->configure(-list=>\%list,-preset=>\%preset);
    $form .= $DBform->generate(-navigator_on=>0,-return_html=>1,-action=>'search',-title=>'Prep filter criteria');

    $form .= $q-> submit(-name =>'Action',-value=>"Search",-class=>"Search",-force=>1);
    $form .= $q->end_form();

    $form .= $self->get_prep_stats(-protocol=>$protocol,-to_date=>$to_date,-from_date=>$from_date,-quick_link=>$quick_link,-prep_action=>\@prep_action);

    return $form;
}

#<snip>
#Example:
# my $prep_stats = $self->get_prep_stats(-protocol=>$protocol,-to_date=>$to_date,-from_date=>$from_date,-prep_action=>@prep_action);
#</snip
#Returns: a page with:
# Display prep information for all Preps that reference the specified protocol in the specific range (or all failed preps or preps that failed for a particular reason)
# For each prep, display two comma-delimited lists; one list of Plate_Sets and one list of Plates which were used in the Prep;
# FK_Prep__ID<-Plate_Prep->FK_Plate__ID AND FK_Prep__ID<-Plate_Prep->FK_Plate_Set__Number
# Each Plate and Plate_Set in those lists should be a link to the home page for that plate or plate set
# Display them ordered by time
######################
sub get_prep_stats {
######################

    my $self        = shift;
    my %args        = &filter_input(\@_);
    my $dbc         = $self->param('dbc');
    my $protocol    = $args{-protocol};
    my $to_date     = $args{-to_date};
    my $from_date   = $args{-from_date};
    my $quick_link  = $args{-quick_link};
    my @prep_action = @{$args{-prep_action}};

    my $page;

    #Get prep stats from Prep and Plate_Prep tables
    my @tables = qw(Prep Plate_Prep Lab_Protocol);
    my @display_fields = qw(FK_Plate__ID FK_Plate_Set__Number Prep_DateTime Prep_Name FK_Lab_Protocol__ID Prep_Comments);
    my @conditions;
    if ($protocol) { push @conditions, "Lab_Protocol_Name = '$protocol'";
    }
    if ($to_date || $from_date) {
	if ($to_date && !$from_date) { $from_date = $quick_link }
	if (!$to_date && $from_date) { $to_date = $quick_link }
	push @conditions, "DATE(Prep.Prep_DateTime) BETWEEN '$from_date' AND '$to_date'"; 
    }
    if (@prep_action) { push @conditions, "(" . join( ' OR ', map {"Prep.Prep_Action = '$_'"} @prep_action) . ")" }
    #$debug=1;
    if (@conditions) {
	$page = Views::sub_Heading ("Preps Search Result");
	my $tables = join ',',@tables;
	my $orderby = " ORDER BY Prep_DateTime, FK_Plate_Set__Number, FK_Plate__ID";
	push @conditions, "Prep_ID = FK_Prep__ID", "FK_Lab_Protocol__ID = Lab_Protocol_ID";
	if ($protocol ne "Standard") { push @conditions, "Lab_Protocol_Name <> 'Standard'" }
	my $condition = "WHERE ". join(' AND ',@conditions) . $orderby;
	my %prep_stats = $dbc->Table_retrieve($tables,\@display_fields,$condition,-debug=>$debug);
	
	#This is required becasue for some reasons, display_hash can't handle a layer name that has ()
	@{$prep_stats{Prep_Name}} = map {$_ =~ s/\(/- /g; $_ =~ s/\)//g; $_;} @{$prep_stats{Prep_Name}};
	$page .= $dbc->SDB::HTML::display_hash(
	 	    -dbc=>$dbc,
                    -hash=> \%prep_stats,
                    -layer=>'Prep_Name',
		    -show_count=>1,
                    -return_html=>1
	);
    }

    return $page;
}

# <snip>
# Usage example: my $cg_stats_home_form = $self->_cg_stats_home_form(-run_modes=>\@run_modes);
#</snip> 
#makes form that allows navigation among run modes
#
####################
sub _cg_stats_home_form {
###################  

    my $self         = shift;
    my %args         = @_;
    my @run_modes    = @{$args{-run_modes}};
    my $q            = $self->query;
    my ($begin_date) = $q->param ('from_date_range') || split ' ', &date_time('-7d');
    my ($end_date)   = $q->param ('to_date_range') || split ' ', &date_time();
    my $output;

## Choose date range at top of page
## use for Sample received statistics and Protocol Statistics
##Default is for the past 7 days
## Filter the rest of the page according to the date range

    $output .= display_date_field (-field_name=>"date_range",
				   -quick_link=>['7 days', '2 weeks', '1 month','3 months','6 months','Year to date'],
				   -range=>1,-linefeed=>1,-default=>$begin_date,-default_to=>$end_date);
    $output .= $q-> hidden (-name=> 'cgi_application', -value => 'Cancer_Genetics::Statistics_App',-force=>1);
    $output .= $q-> submit (-name => 'Search',-value => 'Search Now', -class => "Search", -force=>1) . vspace();

## Table: Sample Receiving Statistics
    $output .= $self->get_sample_receiving_statistics(-begin_date=>$begin_date, -end_date=>$end_date);
    $output .= $q->submit(-name => 'rm', -value=>"$run_modes[0]", -class=>"Search");
    $output .= '<br><br>';

## Tubes
## Table: Tube Statistics
    $output .= $self->get_tube_statistics();
    $output .= $q->submit(-name => 'rm', -value=>"$run_modes[1]", -class=>"Search");
    $output .= '<br><br>';

## Protocols
## Table: Protocol Statistics
    $output .= $self->get_protocol_statistics(-begin_date=>$begin_date, -end_date=>$end_date);
    $output .= $q->submit(-name => 'rm', -value=>"$run_modes[2]", -class=>"Search");
    $output .= '<br><br>';

## Patients
## Table: Patient Statistics
## Rows: 
# Number of patients
# Percentage of patients
## Columns: 
# 'With active samples'
# 'Males'
# 'Females'
# 'Over 40' 
# Patients with active samples: How many patients are referenced by active tubes (Patient<-Source<-Sample<-Plate_Sample->OriginalPlate<-Plate)

    $output .= $q->submit(-name => 'rm', -value=>"$run_modes[3]", -class=>"Search");
    $output .= '<br><br>';

    $output .= $q->end_form();

    return $output;
}

#<snip> 
#Usage example: $sample_table = $self->get_sample_receiving_statistics(-begin_date=>$begin_date,-end_date=>$end_date); 
#</snip>
####################################
sub get_sample_receiving_statistics {
####################################
## Rows: one for each of four source-types: blood, plasma, serum, and saliva
## Columns:
# Received: # of sources received in the specified date range
    my $self       = shift;
    my %args       = &filter_input(\@_,-args=>'begin_date,end_date',-mandatory=>'begin_date,end_date');
    my $dbc        = $self->param('dbc');
    my $begin_date = $args{-begin_date};
    my $end_date   = $args{-end_date};
    my $output;

    #select Source_Type, Count(*) AS Count from Source Group By Source_Type WHERE DATE(Received_Date) BETWEEN '$begin_date' AND '$enddate';
    my %values = $dbc->Table_retrieve('Source',
				      ['Source_Type','Count(*) AS Count'],
				      "WHERE DATE(Received_Date) BETWEEN '$begin_date' AND '$end_date'",
				      -group_by=>'Source_Type');

    my $table = $dbc->SDB::HTML::display_hash(
	      -dbc=>$dbc,
	      -keys=> ['Source_Type','Count'],
              -hash=> \%values,
	      -title=> "Samples Received between $begin_date and $end_date",
	      #-total_columns=>'Count',
	      #-average_columns=>'Count',
              -return_html=>1
	      );
    $output .= $table;

    return $output;
}

sub get_tube_statistics {
## Rows: one for each content-type
## Columns:
# Active Tubes: Number of tubes with Plate_Status 'Active'
# -80 degrees: # of tubes in -80 degree storage conditions
# Exported: # of tubes with Plate_Status 'Exported'
# Contaminated: # of tubes with Plate_Status 'Contaminated'
# Archived: # of tubes with Plate_Status 'Archived'
    my $self       = shift;
    my $dbc        = $self->param('dbc');
    my $output;

    #select Plate_Content_Type, Plate_Status, Count(*) AS Count from Plate Group By Plate_Content_Type, Plate_Status
    my %values = $dbc->Table_retrieve('Plate',
                                      ['Plate_Content_Type','Plate_Status','Count(*) AS Count'],
                                      -group_by=>'Plate_Content_Type,Plate_Status',
				      );

    my %newhashvalues;
    for my $i (0 .. $#{$values{Plate_Content_Type}}) {
	$newhashvalues{$values{Plate_Content_Type}[$i]}{$values{Plate_Status}[$i]} = $values{Count}[$i];
    }

    #For -80 degree storage condition
    #select Plate_Content_Type, Count(*) AS Count(*) from Plate, Rack where FK_Rack__ID = Rack_ID AND Rack_Alias like '%-80 degrees%' Group by Plate_Content_Type
    my %minus80values = $dbc->Table_retrieve('Plate,Rack',
				      ['Plate_Content_Type','Count(*) AS Count'],
				      "WHERE FK_Rack__ID = Rack_ID AND Rack_Alias like '%-80 degrees%'",
                                      -group_by=>'Plate_Content_Type',
				      -key=>'Plate_Content_Type'
				      );

    my @plate_content_type = $dbc->get_enum_list('Plate','Plate_Content_Type');
    my @columns = ('Active','-80 degrees','Exported','Contaminated','Archived');
    my $table = HTML_Table->new( -width => '75%', -title => "Tube Statistics" );
    $table->Set_Headers(['Plate Content Type',@columns]);
    for my $content_type (@plate_content_type) {
	my @row = ();
	push @row, $content_type;
	my $i = 0;
	for my $column (@columns) {
	    $i++;
	    $row[$i] = 0;
	    if ($column eq '-80 degrees') { $row[$i] = $minus80values{$content_type}{Count}[0] if $minus80values{$content_type}{Count}[0]}
	    else { $row[$i] = $newhashvalues{$content_type}{$column} if $newhashvalues{$content_type}{$column} }
	}    
	$table->Set_Row(\@row);
    }
    $output .= $table->Printout(0);	
    
    return $output;
}

sub get_protocol_statistics {
## Rows: one for each protocol (except Standard)
## Columns:
# Completed: How many protocols completed in the specified date range (Prep_Name is 'Completed Protocol' and FK_Lab_Protocol__ID is the protocol being examined.
# Tubes: # of plates involved in the completion of the protocols (use Plate_Prep to get all the plates)
    my $self       = shift;
    my %args       = &filter_input(\@_,-args=>'begin_date,end_date',-mandatory=>'begin_date,end_date');
    my $dbc        = $self->param('dbc');
    my $begin_date = $args{-begin_date};
    my $end_date   = $args{-end_date};
    my $output;

    my %newvalues = $dbc->Table_retrieve('Plate_Prep,Prep,Lab_Protocol',
					 [ "Count(*) AS Number_of_Prep", "Count(Distinct FK_Plate__ID) AS Number_of_Plate", "SUM(CASE WHEN Prep_Name = 'Completed Protocol' THEN 1 ELSE 0 END) AS Completed_Protocol", "Lab_Protocol_Name"],
					 "WHERE FK_Prep__ID = Prep_ID AND FK_Lab_Protocol__ID = Lab_Protocol_ID AND Lab_Protocol_Name <> 'Standard' AND DATE(Prep_DateTime) BETWEEN '$begin_date' AND '$end_date'",
					 -group_by=>'Lab_Protocol_Name'
					 );
    #print HTML_Dump %newvalues;

    my $table = $dbc->SDB::HTML::display_hash(
              -dbc=>$dbc,
              -keys=> ['Lab_Protocol_Name','Completed_Protocol','Number_of_Prep','Number_of_Plate'],
              -hash=> \%newvalues,
              -title=> "Protocols between $begin_date and $end_date",
              -return_html=>1
						  );
    $output .= $table;

    return $output;
}
return 1;
