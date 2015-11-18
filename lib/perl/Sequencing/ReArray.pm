
###################################################################################################################################
# Sequencing_ReArray.pm
#
# Implements ReArray functionality for Sequencing. Primer ordering and qpix rearrays are implemented here.
#
# $Id: Sequencing_ReArray.pm,v 1.183 2004/12/15 23:33:14 jsantos Exp $
###################################################################################################################################
package Sequencing::ReArray;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

ReArray.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/bin/perl<BR>Implements ReArray functionality for Sequencing. Primer ordering and qpix rearrays are implemented here.<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(alDente::ReArray);            

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;
use Storable;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::Messaging;
use alDente::SDB_Defaults;
use alDente::Library_Plate_Set;
use alDente::Primer;
use alDente::Notification;
use alDente::Messaging;
use alDente::ReArray;
use alDente::Tray;
use SDB::DB_Object;
use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use RGTools::Object;

##############################
# global_vars                #
##############################
### Global variables
use vars qw( $User $project_dir $URL_version $Benchmark);
use vars qw(@locations @libraries @plate_sizes @plate_formats %Std_Parameters @users);
use vars qw($Connection $dbh $user  $testing $lab_administrator_email $stock_administrator_email $scanner_mode);
use vars qw($yield_reports_dir);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
# include Excel CPAN modules
my ($mypath) = $INC{'Sequencing/ReArray.pm'} =~ /^(.*)Sequencing\/ReArray\.pm$/;
push(@INC,"$mypath/Imported/Excel/");
require Spreadsheet::ParseExcel::SaveParser;
#my @supplies_emails = split ',',$stock_administrator_email;
#my @lab_admin_emails = split ',',$lab_administrator_email;
#my @supplies_emails = ('jsantos@bcgsc.ca');
#my @lab_admin_emails = ('jsantos@bcgsc.ca');
my $EXCEL_TEMPLATE = $mypath."/../../conf/templates/Primer Order Form.xls";
my $TAB_TEMPLATE = $mypath."/../../conf/templates/Primer Order Form.txt";
### Modular variables
my $DateTime; 
### Constants
my $FONT_COLOUR = 'BLUE'; 

##############################
# constructor                #
##############################

###############################################################
# Constructor: Initializes a ReArray object
# RETURN: reference to a ReArray object
###############################################################
sub new {
    my $this = shift;
    my %args = @_;
    my $rearray_id = $args{-rearray_id}; # ReArray ID of the project
    my $frozen = $args{-frozen} || 0; # flag to determine if the object was frozen
    my $encoded = $args{-encoded}; # flag to determine if the frozen object was encoded
    my $class = ref($this) || $this;
    my $dbc = $args{-dbc} || $Connection; 
    
    my $self;

    if ($frozen) {
        $self = $this->Object::new(%args);
        bless $self, $class;
    }
    elsif ($rearray_id) {
        $self = new alDente::ReArray(-dbc=>$dbc,-primary=>$rearray_id);
        bless $self, $class;
    }
    else {
	$self = new alDente::ReArray(%args);
	bless $self, $class;
    }
    $self->{dbc} = $dbc;
    $self->{ordered} = 0;
    $self->{plate_order_number} = 1;
    # the format for the order array is name,well,sequence
    $self->{order_array} = [];
    return $self;  
}

##############################
# public_methods             #
##############################


######################################
# Subroutine: creates a rearray for sequencing. Note that this is a generalized function, and does not include plate creation or primer creation,
#             although it is possible to create a rearray with primers assigned to them. It is the user's responsibility to create primers using
#             the primer module, as well as the corresponding Primer_Plate and Primer_Plate_Wells. The intention is to eventually have all sequencing rearray functions call 
#             this function to create a rearray. Not intended for external use unless an API is wrapped around it.
# RETURN: the id of the new ReArray_Request if successful, 0 otherwise
######################################
sub create_sequencing_rearray {
    my $self = shift;
    my $dbc = $self->{dbc};
    my %args = @_;
    ## MANDATORY FIELDS
    my $source_plates_ref = $args{-source_plates}; # (ArrayRef) (source plates for source wells in format (1,2,1,1,1,1,2.....). This must correspond to source wells. Not required if -status is "Pre-Rearray"
    my $source_wells_ref = $args{-source_wells};   # (ArrayRef) source wells for ReArray in format (A01,B01,B02,B03.....). This must correspond to target wells and source plates.
    my $target_wells_ref = $args{-target_wells};   # (ArrayRef) target wells for ReArray in format (A01,B02,B01,E03.....). This must correspond to source wells.
    my $target_plate = $args{-target_plate};       # (Scalar) the target plate of the rearray   
    my $primer_names_ref = $args{-primer_names};   # (ArrayRef) primers associated with the target wells. 
    my $primer_plate_wells_ref = $args{-primer_plate_wells}; # (ArrayRef) Optional: Primer plate wells associated with the target wells. 
    my $emp_name = $args{-emp_name};               # (Scalar) employee ID of new ReArray creator.
    my $type = $args{-request_type};                       # (Scalar) Rearray type, whether it is a Clone Rearray or Reaction Rearray rearray.
    my $status = $args{-request_status} || $args{-status}; # (Scalar) Status of the rearray, one of 'Waiting for Primers','Waiting for Preps','Ready for Application','Barcoded','Completed'
    my $target_format_size = $args{-target_size};       # (Scalar) format size of target plate. Should be 96 or 384.
    my $notify_list = $args{-notify_list};         # (Scalar) Comma-delimited list of emails to be notified of events other than the owner of the rearray.
    my $create_plate = $args{-create_plate};       # (Scalar) flag that tells the subroutine to create target plates (by calling those functions in create_rearray)
    my $plate_comments = $args{-plate_comments};   # (Scalar) Optional: comments to be added to the target plate
    my $rearray_comments = $args{-rearray_comments}; # (Scalar) Optional: comments to be added to the rearray
    my $purpose = $args{-purpose} || 'Not applicable'; # (Scalar) Optional: Purpose of a rearray. Currently used only for clone rearrays.
    
    ## ERROR CHECKS
    # check if status is defined correctly
    unless ($status || ($status =~ /Waiting for Primers|Waiting for Preps|Ready for Application|Barcoded|Completed/) ) { 
	$self->error("Missing Parameter: ReArray Status not specified - must be one of 'Waiting for Primers','Waiting for Preps','Ready for Application','Barcoded','Completed'");
    }
    unless ($type) { $self->error("ERROR: Missing Parameter: Rearray Type not specified"); }
     # check if source plates, target plates, source wells, and target wells are defined
    unless ($source_wells_ref) { $self->error("ERROR: Missing Parameter: Source Wells not specified"); }
    unless ($target_wells_ref) { $self->error("ERROR: Missing Parameter: Target Wells not specified"); }
    unless (scalar(@{$source_wells_ref}) == scalar(@{$target_wells_ref})) {
	$self->error("ERROR: Size Mismatch: -source_wells array does not match -target_wells array");
    }

    unless ($source_plates_ref) { $self->error("ERROR: Missing Parameter: Source Plate/s not specified"); } 
    unless (scalar(@{$source_wells_ref}) == scalar(@{$source_plates_ref})) {
	$self->error("ERROR: Size Mismatch: -source_plates array does not match -source_wells array");
    }	
    if ( (!($create_plate)) && (!($target_plate)) ) { $self->error("ERROR: Missing Parameter: Target Plate not specified"); }

    # check if primer details are defined if the type is Oligo, Standard, or Resequence ESTs
    if ($type =~ /Reaction Rearray/) {
	unless ($primer_names_ref) { $self->error("ERROR: Missing Parameter: Primers not specified"); }
	unless (scalar(@{$source_wells_ref}) == scalar(@{$primer_names_ref})) {
	    $self->error("ERROR: Size Mismatch: -source_wells array does not match -primer_names array");
	}
	foreach my $name (@{$primer_names_ref}) {
	    my @retval = $self->{dbc}->Table_find("Primer","count(*)","WHERE Primer_Name='$name'");
	    if (scalar(@retval) == 0) {
		$self->error("ERROR: Integrity problem: Primer does not exist in the database");	
	    }
	}
    }

    unless ($emp_name) { 
	$emp_name = &get_username();
    }
    unless ($target_format_size) { $self->error("ERROR: Missing Parameter: Target format size not specified"); }

    # get the employee ID, and fullname
    # get employee id of user
    my @emp_id_array = $self->{dbc}->Table_find('Employee','Employee_ID,Employee_FullName',"where Email_Address='$emp_name'");
    my ($emp_id,$employee_fullname) = split ',',$emp_id_array[0];
    unless ($emp_id =~ /\d+/) {
	$self->error("ERROR: Invalid parameter: Employee $emp_name does not exist in database");
    }

    # check if there are rearray comments. If there is none, fail
    unless ($rearray_comments) {
	$self->error("ERROR: Missing Parameter: -rearray_comments argument not specified");
    }

    # At this point, error checking is done, return if there is at least one error
    if ($self->error()) {
	$self->success(0);
	return;
    }

    my $skip_plate_creation;
    if ($create_plate) {
	$skip_plate_creation = 0;
    }
    else {
	$skip_plate_creation = 1;
    }

    ## INSERT REARRAY
    # call rearray function
    $args{-employee} = $emp_id;
    $args{-skip_plate_creation} = $skip_plate_creation;
    $args{-target_size} = $target_format_size;
    $args{-notify_list} = $notify_list;
    unless (defined $args{-plate_class}) {
	$args{-plate_class} = 'ReArray';
    }    
    my ($sample_type_id) = $dbc->Table_find('Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = 'Clone'");
    $args{-sample_type_id} = $sample_type_id;
    my ($rearray_id, $plate_id) = $self->create_rearray(%args);
    # error check
    if ($self->error()) {
	$self->success(0);
	return 0;
    }
    ## add purpose
    if ($purpose) {
	$self->{dbc}->Table_update_array("ReArray_Request",['ReArray_Purpose'],["'$purpose'"],"WHERE ReArray_Request_ID = $rearray_id");
    }
    # create Plate_PrimerPlateWell entries if the type is Reaction rearray
    if ($type eq "Reaction Rearray") {
	### build a lookup table of target well -> primer_plate_well ids, source plate id
	# find the primer in a Primer_Plate_Well (not made in house)
	my @primer_plate_wells = ();
	if ($primer_plate_wells_ref) {
	    @primer_plate_wells = @{$primer_plate_wells_ref};
	}
	else {
	    foreach my $primer_name (@$primer_names_ref) {
		my ($primer) = $self->{dbc}->Table_find("Primer_Plate_Well,Primer_Plate left join Solution on FK_Solution__ID=Solution_ID left join Stock on FK_Stock__ID=Stock_ID left join Stock_Catalog on FK_Stock_Catalog__ID=Stock_Catalog_ID",
		        "Primer_Plate_Well_ID","WHERE FK_Primer__Name='$primer_name' AND FK_Primer_Plate__ID=Primer_Plate_ID AND ( (Stock_ID IS NULL) OR (Stock_Catalog.Stock_Source <> 'Made in House') ) AND Primer_Plate_Status <> 'Inactive'");
		push (@primer_plate_wells, $primer);
	    }   
	}
	my %targetwell_to_primer;
	@targetwell_to_primer{@{$target_wells_ref}} = @primer_plate_wells;
	# get the rearray ids of the rearray just created, with the target well (assumed to be unique)
	my @rearray_array = $self->{dbc}->Table_find("ReArray","ReArray_ID,Target_Well","WHERE FK_ReArray_Request__ID=$rearray_id");
	my %rearray_info;
	my $index =  1;
	foreach my $row (@rearray_array) {
	    my ($id, $target_well) = split ',',$row;
	    my $primer_plate_well = $targetwell_to_primer{$target_well};
	    $rearray_info{$index} = [$primer_plate_well,$target_well,$plate_id];
	    $index++;
	}
	# fill information for Plate_PrimerPlateWell

	$dbc->smart_append(-tables=>'Plate_PrimerPlateWell',-fields=>['FK_Primer_Plate_Well__ID','Plate_Well','FK_Plate__ID'],-values=>\%rearray_info,-autoquote=>1);    
    }

    return ($rearray_id, $plate_id);
}

###############################################################
# Subroutine: creates oligo rearrays from files or a data string, and orders primers for these rearrays
# RETURN: the ids (as a comma-delimited list) of the new ReArray_Requests if successful, 0 otherwise
###############################################################
sub order_oligo_rearray_from_file {
###############################
    my $self = shift;
    my $dbc = $self->{dbc};
    my %args = @_;
    ## MANDATORY FIELDS ##
    my $emp_name = $args{-emp_name}; # (Scalar) The unix userid of the employee making the rearray
    my $file_list = $args{-files}; # (Scalar) The fully-qualified filenames of the source files
    my $oligo_direction = $args{-direction}; # (Scalar) The direction of the primers. One of 5 or 3.
    my $target_library = $args{-target_library}; # (Scalar) The library of the plate to be created
    my $omit_primers = $args{-omit_primer_order}; # (Scalar) Flag that tells the function not to write primers to the primer table. This will assume that the Order Numbers are already in the database, so the Rearray will be set to Ready for Application instead of Waiting for Primers
    my $plate_comments = $args{-plate_comments}; # (Scalar) target plate comments
    my $rearray_comments = $args{-rearray_comments}; # (Scalar) Optional: comments regarding the rearray
    my $target_plate_size = $args{-target_plate_size} || 96; 
    my $target_plate = $args{-target_plate};
    my $create_plate = defined $args{-create_plate} ? $args{-create_plate} : 1;
    ## OPTIONAL FIELDS
    my $notify_list = $args{-notify_list} || ''; # (Scalar) a comma-delimited string of emails who will be informed when the primer plate has been provided with an external order number. 
    my $data = $args{-data}; # (Scalar) An input string with information formatted exactly like the input file. Overrides the -files tag.
    my $rearray_type = "Reaction Rearray";  

    # ERROR CHECK #
    unless ($file_list || $data) {
	$self->error("ERROR: Missing Parameter: Need to define -files and -data.");
    }
    unless ($emp_name) {
	$emp_name = &get_username();
    }
    if ( (!($omit_primers)) && (!($oligo_direction)) ) {
	$self->error("ERROR: Missing Parameter: -direction not defined");
    }
    unless ( $oligo_direction =~ /5|3/ ) {
	$self->error("ERROR: Invalid Parameter: -direction must be one of 3 or 5");
    }
    # get the file list
    my @files = split ',',$file_list;
    foreach my $file (@files) {
	unless ( (-e $file) && (-r $file) ) {
	    $self->error("ERROR: Invalid Parameter: $file does not exist or cannot be read");
	}  
    }
    unless ($target_library) {
	$self->error("ERROR: Missing Parameter: -target_library not defined");
    }

    # do an error check on library
    my ($lib_count) = $self->{dbc}->Table_find('Library','count(*)',"where Library_Name='$target_library'");
    if ($lib_count != 1) {
	$self->error("ERROR: Invalid library: Library $target_library cannot be found in database");
    }

    # ERROR CHECK FINISHED
    if ($self->error()) {
	$self->success(0);
	return 0;
    }

    # if the primer order is omitted, assume that Order Numbers are in database, so set to Waiting for Primers
    my $status_flag = "Waiting for Primers";
    if ($omit_primers) {
	$status_flag = "Ready for Application";
    }


    # create a set of rearrays to order (contained in @lines_array)
    my @lines_array = ();

    if ($data) {
	my @lines = split "\n",$data;
	push (@lines_array,\@lines);
    }

    
    if ($file_list && (int(@files) > 0) ) {
	foreach my $file (@files) {
	    my @file_lines;
	    open(INF,"$file");
	    @file_lines = <INF>;
	    push (@lines_array,\@file_lines);
	}
    }
    
    my @ids = ();
    foreach my $batch (@lines_array) {
	my @lines = @{$batch};
	
	## PARSE ARRAY OF DATA ROWS
	# reference arrays, each element pointing to a 96-element array
	my @source_plate_array = ();
	my @source_well_array = ();
	my @target_well_array = ();
	my @primer_name_array = ();
	my @primer_sequence_array =();
	my @solution_id_array = ();
	my @tm_working_array = ();
	my @primer_plate_well_array = ();
	
	# temporary references
	my $source_plates = [];
	my $source_wells = [];
	my $target_wells = [];
	my $primer_names = [];
	my $primer_sequences = [];
	my $solution_ids = [];
	my $tms_working = [];
	
	# read each line and dump every 96 to the reference arrays
	# each line should have the format: source plate, source well, target well, primer name, primer sequence,melting temp {,primer well}
	my $primer_obj = new alDente::Primer(-dbc=>$dbc);
	my $counter = 0;
	foreach my $line (@lines) {
	    my @element_array = split ',',$line;
	    # check if there are a proper number of elements, if not, skip line
	    # portion of code for rearrays that have primers in-house
	    if ($omit_primers) {
		if ( (scalar(@element_array) != 4)  && (scalar(@element_array) != 5)  ) {
		    $self->error("ERROR: incorrect elementcount in $line");
		    $self->success(0);
		    return 0;
		}
		# do some more data verification
		if ($line !~ /^\d+,[A-P]{1}\d{2},[A-P]{1}\d{2},.+$/) {
		    $self->error("ERROR: unrecognized format in $line");
		    $self->success(0);
		    return 0;
		}
		
		# read into array
		push (@{$source_plates}, $element_array[0]);
		push (@{$source_wells}, $element_array[1]);
		push (@{$target_wells}, $element_array[2]);
		my $name = &RGTools::RGIO::chomp_edge_whitespace($element_array[3]);
		$primer_obj->value('Primer_Name',$name);
		
		if ( (scalar(@element_array) == 5) && $element_array[4]) {
		    my $sol_id = &RGTools::RGIO::chomp_edge_whitespace($element_array[4]);
		    my ($verified) = $self->{dbc}->Table_find("Primer_Plate","Primer_Plate_ID","WHERE FK_Solution__ID=$sol_id");
		    if ($verified) {
			push (@{$solution_ids},$sol_id);
		    }
		    else {
			push (@{$solution_ids},'');
		    }
		}
		else {
		    push (@{$solution_ids},'');
		}
		
		my $name_count = $primer_obj->exist();
		
		if ( $name_count == 0 ) {
		    $self->error("ERROR: Integrity problem: Primer Name $name does not exist in database");
		    $self->success(0);
		    return 0;
		}
		push (@{$primer_names}, $name);
		## these two are already defined in the database, so just set it to blank values
		push (@{$primer_sequences}, "");
		push (@{$tms_working}, "");
		$counter++;
	    }
	    else {
		if ( (scalar(@element_array) != 6) && (scalar(@element_array) != 5)  ) {
		    $self->error("ERROR: incorrect elementcount in $line");
		    $self->success(0);
		    return 0;
		}
		# do some more data verification
		if ($line !~ /^\d+,[A-P]{1}\d{2},[A-P]{1}\d{2},\s*\S+\s*,[ACGTacgt]+(?:,[\d\.]+)?$/) {
		    $self->error("ERROR: unrecognized format in $line");
		    $self->success(0);
		    return 0;
		}
		
		# read into array
		push (@{$source_plates}, $element_array[0]);
		push (@{$source_wells}, $element_array[1]);
		push (@{$target_wells}, $element_array[2]);
		push (@{$solution_ids},'');
		my $name = &RGTools::RGIO::chomp_edge_whitespace($element_array[3]);
		$primer_obj->value('Primer_Name',$name);	
		
		my $name_count = $primer_obj->exist();
	    
		if ( $name_count > 0 ) {
		    $self->error("ERROR: Integrity problem: Primer Name $name already exists in database");
		    $self->success(0);
		    return 0;
		}
		push (@{$primer_names}, $name);
		my $seq = &RGTools::RGIO::chomp_edge_whitespace($element_array[4]);
		push (@{$primer_sequences}, $seq);
		if (scalar(@element_array) == 6) {
		    push (@{$tms_working}, $element_array[5]);
		}
		else {
		    my $calculated_tm = $primer_obj->_calc_temp_MGC_Standard(-sequence=>$element_array[4]);
		    push (@{$tms_working}, $calculated_tm);
		}
		$counter++;
	    }
	    
	    if ($counter == $target_plate_size) {
		$counter = 0;
		push (@source_plate_array, $source_plates);
		push (@source_well_array, $source_wells);
		push (@target_well_array, $target_wells);
		push (@primer_name_array, $primer_names);
		push (@primer_sequence_array, $primer_sequences);
		push (@tm_working_array, $tms_working);
		push (@solution_id_array, $solution_ids);
		$source_plates = [];
		$source_wells = [];
		$target_wells = [];
		$primer_names = [];
		$primer_sequences = [];
		$tms_working = [];
		$solution_ids = [];
	    }
	}

	if ($counter != 0) {
	    push (@source_plate_array, $source_plates);
	    push (@source_well_array, $source_wells);
	    push (@target_well_array, $target_wells);
	    push (@primer_name_array, $primer_names);
	    push (@primer_sequence_array, $primer_sequences);
	    push (@tm_working_array, $tms_working);
	    push (@solution_id_array, $solution_ids);
	}

	## call appropriate functions
	
	# call primer ordering functions
	my @primer_plate_id_array = ();
	if (!($omit_primers)) {
	    for (my $i=0; $i < scalar(@source_plate_array); $i++) {
		my $target_wells = $target_well_array[$i];
		my $primer_names = $primer_name_array[$i];
		my $primer_sequence = $primer_sequence_array[$i];
		my $primer_temp = $tm_working_array[$i];
		# send off primer order
		my @directions = ();
		foreach (1..scalar(@{$primer_names})) {
		    push (@directions, $oligo_direction);
		}
		my $rethash_ref = $self->order_primers(-emp_name=>$emp_name,-wells=>$target_wells,-name=>$primer_names,-sequence=>$primer_sequence,-tm_working=>$primer_temp,-primer_type=>'Oligo',-direction=>\@directions);
		# error check
		if ($self->error()) {
		    $self->success(0);
		    return 0;
		}
	    }   
	}
	else {
	    # if omitting primers, search for the primer_plate_well ids that need to be filled in
	    for (my $i=0; $i < scalar(@source_plate_array); $i++) {	
		my $primer_names = $primer_name_array[$i];
		my $solution_ids = $solution_id_array[$i];
		my $counter = 0;
		my @primer_well_ids = ();
		foreach my $primer_name (@{$primer_names}) {
		    my $solution_id = $solution_ids->[$counter];
		    my $primer_condition = "WHERE FK_Primer__Name='$primer_name' AND FK_Primer_Plate__ID=Primer_Plate_ID ";
		    if ($solution_id) {
			$primer_condition .= " AND FK_Solution__ID=$solution_id ";
		    }
		    my ($primer_string) = $self->{dbc}->Table_find("Primer_Plate_Well,Primer_Plate","Primer_Plate_Well_ID,Primer_Plate_Status",$primer_condition);
		    my ($primer_plate_well_id,$status) = split ',',$primer_string;

		    push (@primer_well_ids,$primer_plate_well_id);
		    # if even one primer is ordered, then put rearray on order
		    if ($status =~ /Ordered|To Order/i) {
			$status_flag = "Waiting for Primers";
		    }
		    $counter++;
		}
		push (@primer_plate_well_array,\@primer_well_ids);
	    }
	}

	# call rearray functions
	for (my $i=0; $i < scalar(@source_plate_array); $i++) {
	    my $source_plates = $source_plate_array[$i]; 
	    my $source_wells = $source_well_array[$i];
	    my $target_wells = $target_well_array[$i];
	    my $primer_names = $primer_name_array[$i];
	    my $primer_sequence = $primer_sequence_array[$i];
	    my $primer_plate_well_ids = $primer_plate_well_array[$i] if (exists $primer_plate_well_array[$i]);
	    # call rearray functions
	    my ($plate_id, $id);
	    if (exists $primer_plate_well_array[$i]) {
		($id, $plate_id) = $self->create_sequencing_rearray(-status=>$status_flag,-source_plates=>$source_plates,-source_wells=>$source_wells,-target_wells=>$target_wells,-primer_names=>$primer_names,-emp_name=>$emp_name,-request_type=>$rearray_type,-target_size=>$target_plate_size,-target_library=>$target_library,-plate_application=>'Sequencing',-plate_class=>'Oligo',-create_plate=>$create_plate,-target_plate=>$target_plate,-notify_list=>$notify_list,-rearray_comments=>$rearray_comments,-primer_plate_wells=>$primer_plate_well_ids);
	    } else {
		($id, $plate_id) = $self->create_sequencing_rearray(-status=>$status_flag,-source_plates=>$source_plates,-source_wells=>$source_wells,-target_wells=>$target_wells,-primer_names=>$primer_names,-emp_name=>$emp_name,-request_type=>$rearray_type,-target_size=>$target_plate_size,-target_library=>$target_library,-plate_application=>'Sequencing',-plate_class=>'Oligo',-create_plate=>$create_plate,-target_plate=>$target_plate,-notify_list=>$notify_list,-rearray_comments=>$rearray_comments);
	    }
	    # error check
	    if ($self->error()) {
		$self->success(0);
		return 0;
	    }
	    push (@ids, $id);
	}
    }
	
    my $interested_groups = join ',', $self->{dbc}->Table_find('Library','FK_Grp__ID',"WHERE Library_Name = '$target_library'",-distinct=>1);

    # if primers are omitted, send an email to the lab administrators immediately
    if ($omit_primers && ($status_flag !~ /Waiting for Primers/)) {
	#my @mail = @lab_admin_emails;
	my @mail = @{ &alDente::Employee::get_email_list($dbc,'lab admin',-group=>$interested_groups) };
	my @notify_emails = split ',',$notify_list;
	foreach (@notify_emails) {
	    if ( ($_ ne '') || ($_ ne 'NULL') ) {
		push (@mail, $_);
	    }
	}
	push (@mail, $emp_name);
	my $target_list = join ',',  @mail;

	my $url_location = "";
	my $new_ids = join ',',@ids;
	my ($employee_fullname) = $self->{dbc}->Table_find('Employee','Employee_FullName',"WHERE Email_Address='$emp_name'");
	foreach my $rearray_id (@ids) {
            $url_location .= Link_To($dbc->homelink(),"Rearray $rearray_id","Request_ID=$rearray_id&Expand+ReArray+View=1&Order=Target_Well","$Settings{LINK_COLOUR}");
	}
	my $range = &convert_to_range($new_ids);
	$range =~ s/,/\./g;
#	&alDente::Notification::Email_Notification($target_list,'aldente@bcgsc.bc.ca','Primer ReArray requested',"Primer ReArray/s, request number/s $new_ids from $employee_fullname has been requested\n\n$url_location",undef,'html',-append=>"oligo_rearray.txt");
    }

    # SEND OFF PRIMER ORDER
    # get the range
    unless ($omit_primers) {
	my $rearray_range = $ids[0]."-".$ids[-1];
	$self->send_primer_order(-emp_name=>$emp_name,-request_range=>$rearray_range,-notify_list=>$notify_list,-group=>$interested_groups);   
    }
    ## add to a Lab_Request
    # create a Lab_Request entry
    my ($emp_id) = $self->{dbc}->Table_find("Employee","Employee_ID","WHERE Email_Address='$emp_name'");
    my $insert_id = $self->{dbc}->Table_append_array("Lab_Request",['FK_Employee__ID','Request_Date'],[$emp_id,&date_time()],-autoquote=>1);
    $self->{dbc}->Table_update_array("ReArray_Request",['FK_Lab_Request__ID'],["$insert_id"],"WHERE ReArray_Request_ID in (".join(',',@ids).")");
    return join ',',@ids;

}

###############################################################
# Subroutine: Searches for the plate ids associated with a clone file
# RETURN: an arrayref of the plate ids
###############################################################
sub search_clone_plates {
    my $self = shift;
    my %args = @_;
    
    ### MANDATORY FIELDS ###
    my $emp_name = $args{-emp_name};   # (Scalar) Unix userid of the person doing the rearray
    my $data = $args{-data};           # (Scalar) data for the qpix rearray. Contains the same information as the clone file. Takes priority over -clonefile.
    my $clonefile = $args{-clonefile}; # (Scalar) filename of the clone file. The path should be fully qualified (eg /home/jsantos/csv). Superseded by -data.

    
    my $format = $args{-format};     # (Scalar) determines which plate format to search for, and picks the latest plate with that format. For example, -format=>'Glycerol' will grab the latest glycerol plate with that Library_Name.Plate_Number combination.
    my $original = $args{-original}; # (Scalar) flag that determines whether or not to grab the earliest ORIGINAL plates. This should be the typical behaviour.
    my $force_invalid_plates = $args{-force_invalid_plates}; # (Scalar) flag that determines whether or not to allow plates that have been exported, garbaged, or are not active
 

    my $dbc = $self->{dbc};

    ### ERROR CHECKING

    
    # check to see if format or original has been defined
    # this defines the behaviour of the plate search
    # the $original flag tells the script to look for the initial plate created (FKParent_Plate__ID == 0)
    # the $format is a string that the script will look for in the Plate_Format string. It will match all the plates and get the LATEST one.
    # (Plate_Format like (%$format%) group by FK_Library_Name, Plate Number) 
    unless ($original || $format) {
	$self->error("ERROR: Missing Parameter: -original flag or -format string not set");
    }
    # do error checking on clonefile if defined
    if ($clonefile && (!(-e $clonefile) ) ) {
	$self->error("ERROR: Invalid argument: file does not exist");	
    }
    if ($clonefile && (!(-r $clonefile) ) ) {
	$self->error("ERROR: Invalid argument: file cannot be read");	
    }
    
    ### FINISHED INITIAL ERROR CHECK
    if ($self->error()) {
	$self->success(0);
	return 0;
    }

    # get a hash that translates 96-well notation plus a quadrant to 384-well notation (ie A01b => 'A02')
    # also, get an array containing all 384-well addresses, ordered by Quadrant
    my %well_lookup = $dbc->Table_retrieve("Well_Lookup",['Quadrant','Plate_96','Plate_384'],'order by Quadrant,Plate_96');
    my %well_map; 
    my %well_384_to_96;
    my @wells_384 = ();
    my $index = 0;

    foreach my $well (@{$well_lookup{'Plate_96'}}) {
	$well_lookup{'Plate_384'}[$index] = &format_well($well_lookup{'Plate_384'}[$index]);
	$well_map{uc($well_lookup{'Plate_96'}[$index].$well_lookup{'Quadrant'}[$index])} = $well_lookup{'Plate_384'}[$index];
	$well_384_to_96{$well_lookup{'Plate_384'}[$index]} = uc($well_lookup{'Plate_96'}[$index]).$well_lookup{'Quadrant'}[$index];
	push (@wells_384, $well_lookup{'Plate_384'}[$index]);
	$index++;
    }

    my @wells_96 = ();
    foreach my $row ('A'..'H') {
	foreach my $col (1..12) {
	    $col = sprintf "%02d", $col;
	    my $newwell = $row.$col;
	    push (@wells_96,$newwell);	
	}
    }
    
    my @lines = ();
    # if clone data specified, split it into lines
    if ($data) {
	@lines = split "\n",$data;
    }
    else {
    # if clone file specified, open clone file and read all the lines into an array
	open(INF,"$clonefile");
	@lines = <INF>;
    }

    # initialize arrays that need to be stored
    my @clones = ();
    my @libraries = ();
    my @plate_numbers = ();
    my @newwells = ();
    my @clone_ids =();
    my @primers_seq = ();
    my @primers_tmp = ();
    
    my %defined_plates;

    my %lib_platenum_to_well;

    # look for lines that have clone information. Extract information from it : library, plate, well, primer sequence and primer melting pt
    foreach my $line (@lines) {
	if ($line =~ /^(\S{5})([a-zA-Z0-9]+)_?(\S{3}),(\w+),([\d\.]+)(?:,pla(\d+))?$/) {
	#if ($line =~ /(\S{5})([a-zA-Z0-9]+)_?(\S{3}),(\w+),([\d\.]+)/) {
	    my $library = $1;
	    my $plate = $2;
	    my $well = $3;
	    my $primer_seq = $4;
	    my $primer_tm = $5;

	    my $optional_plate = $6;

	    my $newwell = '';
	    my $newplate = '';
	    if ($plate =~ /(\d+)(\D).*/) {
		$newwell = $well_map{uc($well.$2)};
		$newplate = $1;
	    }
	    else {
		$newwell = $well;
		$newplate = $plate;
	    }

	    # if the optional plate argument is defined, store and make
	    # sure it is not queried against the database
	    if ($optional_plate) {
		$defined_plates{$library.$plate} = $optional_plate;
	    }

	    my $clone = ("$library,$plate,$newwell,$primer_seq,$primer_tm");
	    push (@clones,$clone);
	    push (@libraries, $library);
	    push (@plate_numbers, $newplate);
	    my $clone_id = $library.$plate.$well;
	    push (@clone_ids,$clone_id);
	    push (@newwells,$newwell);

	    push (@primers_seq, $primer_seq);
	    push (@primers_tmp, $primer_tm);

	    # create an association between library-plate number to well
	    # also, append clone_ids and primer information to the well id
	    
	    if (defined $lib_platenum_to_well{"$library-$newplate"}) {
		push (@{$lib_platenum_to_well{"$library-$newplate"}}, "$newwell,$newwell,$clone_id,$primer_seq,$primer_tm");
	    }
	    else {
		$lib_platenum_to_well{"$library-$newplate"} = ["$newwell,$newwell,$clone_id,$primer_seq,$primer_tm"];
	    }
	}
	elsif ($line =~ /^(\S{5})([a-zA-Z0-9]+)_?(\S{3})(?:,pla(\d+))?$/) {
	    my $library = $1;
	    my $plate = $2;
	    my $well = $3;
	    my $primer_seq = " ";
	    my $primer_tm = "0";
	    
	    my $optional_plate = $4;

	    my $newwell = '';
	    my $newplate = '';
	    if ($plate =~ /(\d+)(\D).*/) {
		$newwell = $well_map{uc($well.$2)};
		$newplate = $1;
	    }
	    else {
		$newwell = $well;
		$newplate = $plate;
	    }

	    # if the optional plate argument is defined, store and make
	    # sure it is not queried against the database
	    if ($optional_plate) {
		$defined_plates{$library.$plate} = $optional_plate;
	    }

	    my $clone = ("$library,$plate,$newwell,$primer_seq,$primer_tm");
	    push (@clones,$clone);
	    push (@libraries, $library);
	    push (@plate_numbers, $newplate);
	    my $clone_id = $library.$plate.$well;
	    push (@clone_ids,$clone_id);
	    push (@newwells,$newwell);

	    push (@primers_seq, $primer_seq);
	    push (@primers_tmp, $primer_tm);

	    # create an association between library-plate number to well
	    # also, append clone_ids and primer information to the well id
	    
	    if (defined $lib_platenum_to_well{"$library-$newplate"}) {
		push (@{$lib_platenum_to_well{"$library-$newplate"}}, "$newwell,$well,$clone_id,$primer_seq,$primer_tm");
	    }
	    else {
		$lib_platenum_to_well{"$library-$newplate"} = ["$newwell,$well,$clone_id,$primer_seq,$primer_tm"];
	    }
	}
	else {
	    $self->error("ERROR: unrecognized line in data file $line");
	    $self->success(0);
	    return 0;
	}

    }    

    ### ERROR CHECK
    # check to see if all the defined plates exist in the database
    if (scalar(keys(%defined_plates)) > 0) {
	my @error_check = $self->{dbc}->Table_find('Plate','Plate_ID','WHERE Plate_ID in ('.(join ',',values(%defined_plates)).')');
	if (scalar(values(%defined_plates)) != scalar(@error_check)) {
	    $self->error("ERROR: Invalid value: Defined plate not found in database");
	    $self->success(0);
	    return 0;
	}
    }
    
    # check to see if the source plates are all 384-well. If not, check if their plate format is 384-well.
    # if it is NOT 384-well, fail.
    # if it is 384-well, get the Multiple_Barcode entry and replace it with the correct plate id and well designation

    # get plates that are not 384-well size
    my @format_check_for_384_size = ();
    if (scalar(keys(%defined_plates))>0) {
	@format_check_for_384_size = $self->{dbc}->Table_find('Plate','Plate_ID',"WHERE Plate_Size<>'384-well' AND Plate_ID in (".join(',',values(%defined_plates)).")");
    }
    unless (scalar(@format_check_for_384_size) == 0) {
	my @format_check_for_384_format = $self->{dbc}->Table_find('Plate,Plate_Format','Plate_ID',"WHERE FK_Plate_Format__ID=Plate_Format_ID AND Wells <>'384' AND Plate_ID in (".join(',',@format_check_for_384_size).")");	
	unless (scalar(@format_check_for_384_format) == 0) {
	    $self->error("ERROR: Size error: Using a 96-well plate in a clone rearray");
	    $self->success(0);
	    return 0;
	}
	# everything in @format_check_for_384_size is 96-well size, 384-well format
	# check the well, grab the mul barcode - replace the plate id with the correct one and map the well id to 96-well for clone tracking (actual well)
	foreach my $plateid (@format_check_for_384_size) {
	    my $tray_id = alDente::Tray::exists_on_tray($dbc,'Plate',$plateid);
	    if(!$tray_id) {
		$self->error("ERROR: $plateid does not exist on a tray.");
		$self->success(0);
		return 0;
	    }
	    my @mul_array = alDente::Tray::get_content($dbc,'Plate',$tray_id);
	    my $i = 0;
	    my @quadrant_array = ('a','b','c','d');
	    my %quadrant_to_plate;
	    foreach my $id (@mul_array) {
		$quadrant_to_plate{$quadrant_array[$i]} = $id;
		$i++;
	    }
	    # get information about plate
	    my ($plate_info) = $self->{dbc}->Table_find('Plate','FK_Library__Name,Plate_Number',"WHERE Plate_ID=$plateid");
	    my ($library,$plate_number) = split ',',$plate_info;
	    foreach my $row (@{$lib_platenum_to_well{"$library-$plate_number"}}) {
		# get well translation
		my ( $sourcewell, $actual_well, $cloneid, $primer_seq, $primer_temp, $alt_plateid) = split ',',$row;
		$well_384_to_96{$sourcewell} =~ /^(\S{3})(\w)$/;
		my $well = $1;
		my $quadrant = $2;
		$alt_plateid = $quadrant_to_plate{$quadrant}; ### <CONSTRUCTION> Why reset to another value after retrieving above ?		
		$row = "$sourcewell,$well,$cloneid,$primer_seq,$primer_temp,$alt_plateid";
	    }
	}
    }
    
    ### get plate id
    $index = 0;
    my $condition_string = "(";
    my $search_condition = " FKParent_Plate__ID=0 ";
    my %found_lib_platenum;
    foreach my $library (@libraries) {
	# if the plate id has been defined in the source file, don't query the database on it
	if (defined($defined_plates{$library.$plate_numbers[$index]})) {
	    $index++;
	    next;
	}
	# if the library-platenumber combination has been included already, skip
	my $lib_platenum = "$library-$plate_numbers[$index]";
	if (defined $found_lib_platenum{$lib_platenum}) {
	    $index++;
	    next;
	}
	$found_lib_platenum{$lib_platenum} = 1;
	$condition_string .= "(FK_Library__Name='$library' AND Plate_Number=$plate_numbers[$index]) OR";
	if ($original) {
	    $search_condition = " FKParent_Plate__ID=0 ";
	}
	elsif ($format) {
	    $search_condition = " Plate_Format_Type like '%$format%' ";
	}
	$index++;
    }
    # remove the final OR
    $condition_string = substr ($condition_string, 0, -3) if (length($condition_string) > 1);
    # close parenthesis
    $condition_string .= ")";

    ## Get all plate IDs involved in the Rearray

    # create a hash that represents the latest Plate_ID associated with the Library_Name, Plate_Number pair
    my %plate_ids;
    # get Plate IDs ordered by Plate_Created
    # This is so the last occurence of the Library_Name.Plate_Number pair is the latest Plate_ID (which is what we want)
    # Save each Plate_ID in a hash with the Library_Name.Plate_Number pair as keys.
    # this loop will terminate with the hash containing the latest Plate_IDs

    foreach my $plate_id ($self->{dbc}->Table_find_array("Plate_Format,Plate,Rack",['FK_Library__Name','Plate_Number','Plate_ID','Plate_Status','Rack_Name'],"WHERE $condition_string AND $search_condition AND FK_Plate_Format__ID=Plate_Format_ID AND FK_Rack__ID=Rack_ID ORDER BY Plate_Created")) {
	my ($lib_name, $plate_number, $plate_id, $plate_status, $rack_name)  = split ',',$plate_id;
	if ( (!($force_invalid_plates)) && ($rack_name =~ /Exported/) ) {
	    $self->error("ERROR: plate $plate_id ($lib_name-$plate_number) has been exported");
	    $self->success(0);
	    return 0;  
	}
	if ( (!($force_invalid_plates)) && ($rack_name =~ /Garbage/) ) {
	    $self->error("ERROR: plate $plate_id ($lib_name-$plate_number) has been thrown away");
	    $self->success(0);
	    return 0;  
	}
	if ( (!($force_invalid_plates)) && ($plate_status !~ /Active/)) {
	    $self->error("ERROR: plate $plate_id ($lib_name-$plate_number) is no longer active");
	    $self->success(0);
	    return 0;  
	}
	$plate_ids{$lib_name.$plate_number} = $plate_id;
    }


    # make another call to Table_find, but sort by Equipment Name and Rack ID
    my $plate_id_string = join ',',values(%plate_ids);
    # add defined plates to the string
    if (scalar(values(%defined_plates)) > 0) {
	if ($plate_id_string ne "") {
	    $plate_id_string .= ','.(join ',',values(%defined_plates));
	}
	else {
	    $plate_id_string .= join ',',values(%defined_plates);
	}
    }

    my @plate_array = $self->{dbc}->Table_find_array("Plate,Rack,Equipment",['FK_Library__Name','Plate_Number','Plate_ID'],"WHERE Plate_ID in ($plate_id_string) AND FK_Equipment__ID=Equipment_ID AND FK_Rack__ID=Rack_ID ORDER BY Equipment_Name, Rack_ID, Plate_ID ASC");


    # generate arrays needed for create_rearray call
    # can create multiple 384-well plates, stored in $<target>_rearrays array
    # also, start building primer rearray information for 96-well oligo plates
    # this will only be used if the $prerearray flag is set
    $index = 0; 

    # variables for 384 well clone rearray
    my $counter = 0;
    my @source_plates_array = ();
    my @source_wells_array = ();
    my @target_wells_array = ();
    my @actual_source_wells_array = ();
    my $source_plates = [];
    my $target_wells = [];
    my $source_wells = [];
    my $actual_source_wells = [];

    # variables for 96 well oligo rearray
    my $index_96 = 0;
    my $plate_track_num = 0;
    my @source_plates_array_96 = ();
    my @source_wells_array_96 = ();
    my @target_wells_array_96 = ();
    my @primer_seq_array_96 = ();
    my @primer_tmp_array_96 = ();
    my @primer_name_array_96 = ();
    my $source_plates_96 = [];
    my $target_wells_96 = [];
    my $source_wells_96 = [];  
    my $primer_sequence_96 = [];
    my $primer_temp_96 = [];
    my $primer_name_96 = [];

    # track if the clone has been entered into the arrays
    # if it has, then skip over it, BUT
    # it is still entered into the 96-well rearrays, double-dipping
    # from a single well

    # sort the wells within each plate A01-P24
    foreach my $arrayref (values %lib_platenum_to_well) {
	my @newarray = sort (@{$arrayref});
	$arrayref = \@newarray;
    }
    # get a count of similar primer names in the database, and increment the suffix correctly
    my $primer_name_string = "";
    foreach my $clone (@clone_ids) {
	$primer_name_string .= "OR (Primer_Name like '$clone%') ";
    }
    my @primer_naming_count = $self->{dbc}->Table_find_array('Primer', ['count(*)',"left(Primer_Name,instr(Primer_Name,'-') - 1)"], "where 1 $primer_name_string group by left(Primer_Name,instr(Primer_Name,'-') - 1)");
    my %primer_naming_hash;
    foreach my $row (@primer_naming_count) {
	my ($count, $name) = split ',',$row;
	$primer_naming_hash{$name} = $count;
    }

    # hash that keeps track of repeats
    my %unique_clone_ids;
    my $primer_name = "";
    my $source_plate_count = 0;
    my $wellcount_index = -1;

    foreach my $plate_string (@plate_array) {
	my ($library, $platenum, $plateid) = split ',',$plate_string;
	my $prev_cloneid = "";
	foreach my $s_well (@{$lib_platenum_to_well{"$library-$platenum"}}) {

	    my ( $sourcewell, $actual_well, $cloneid, $primer_seq, $primer_temp, $alt_plateid) = split ',',$s_well;
	    # make the sourcewell equal to the actual well (the 384-well designation for a 96x4/384 was preserved for sorting), as
	    # now it is necessary to use the actual well designation, which is 96-well.
	    $sourcewell = $actual_well;
	    my $orig_plateid = $plateid;
	    if ( $alt_plateid =~ /\d+/ ) {
		$plateid = $alt_plateid;
	    }

	    $primer_name = $cloneid;

	    if ($prev_cloneid ne $cloneid) {
		$wellcount_index++;
	    }
	    if ($wellcount_index==96) {
		$wellcount_index=0;
		$source_plate_count++;
	    } 

	    # save 96_well information
	    push (@{$primer_sequence_96}, $primer_seq);
	    push (@{$primer_temp_96}, $primer_temp);
	    push (@{$source_plates_96}, $source_plate_count);
	    push (@{$source_wells_96}, $wells_96[$wellcount_index]);
	    push (@{$target_wells_96}, $wells_96[$index_96]);
	    $index_96++;

	    # save 384_well information
	    if (!(defined $unique_clone_ids{$cloneid})) {
		push (@{$source_plates}, $plateid);
		push (@{$source_wells}, $sourcewell);
		push (@{$actual_source_wells}, $actual_well);
		push (@{$target_wells}, $wells_384[$index]);
		$unique_clone_ids{$cloneid} = 1;
		$primer_naming_hash{$cloneid}++;
		$primer_name .= "-$primer_naming_hash{$cloneid}";
		$index++;
	    }
	    else {
		$unique_clone_ids{$cloneid}++;
		$primer_naming_hash{$cloneid}++;
		$primer_name .= "-$primer_naming_hash{$cloneid}";
	    }

	    push (@{$primer_name_96}, $primer_name);

	    # roll index over if index hits 96
	    if ($index_96 == 96) {
		$index_96 = 0;
		push (@primer_name_array_96,$primer_name_96);
		push (@primer_seq_array_96,$primer_sequence_96);
		push (@primer_tmp_array_96,$primer_temp_96);
		push (@source_plates_array_96, $source_plates_96);
		push (@source_wells_array_96, $source_wells_96);
		push (@target_wells_array_96, $target_wells_96);
		$primer_sequence_96 = [];
		$primer_name_96 = [];
		$primer_temp_96 = [];	
		$target_wells_96 = [];
		$source_wells_96 = []; 
		$source_plates_96 = [];
	    }
	    # roll index over if index hits 384
	    if ($index == 384) {
		$index = 0;
		push (@source_plates_array, $source_plates);
		push (@source_wells_array, $source_wells);
		push (@target_wells_array, $target_wells);
		push (@actual_source_wells_array, $actual_source_wells);
		$source_plates = [];
		$target_wells = [];
		$source_wells = [];
		$actual_source_wells = [];
	    }
	    $prev_cloneid = $cloneid;
	    $plateid = $orig_plateid;
	}
    }

    # push if the temporary arrays haven't been pushed into the storage arrays
    if ($index != 0) {
	push (@source_plates_array, $source_plates);
	push (@source_wells_array, $source_wells);
	push (@target_wells_array, $target_wells); 
	push (@actual_source_wells_array, $actual_source_wells);  
    }
    if ($index_96 != 0) {
	push (@primer_seq_array_96,$primer_sequence_96);
	push (@primer_tmp_array_96,$primer_temp_96);
	push (@source_wells_array_96, $source_wells_96);
	push (@target_wells_array_96, $target_wells_96);
	push (@primer_name_array_96, $primer_name_96);
	push (@source_plates_array_96, $source_plates_96);
    }
    my @retarray = ();
    for (my $i=0; $i < scalar(@source_plates_array); $i++) {
	my $unique_plates = unique_items($source_plates_array[$i]);
	push (@retarray,@{$unique_plates});
    } 
    
    return \@retarray;
}


###############################################################
# Subroutine: creates a qpix rearray, writes out a qpix file and location file,
#             and creates a rearray for the qpix.
#             sends an email to the lab admins for the qpix request.
#             Note that the subroutine assumes that both source and destination
#             Plate sizes are 384.
# RETURN: the ids (comma_delimited) of the new ReArray_Requests if successful, 0 otherwise
###############################################################
sub create_clone_rearray {
######################
    my $self = shift;
    my %args = @_;
    
    ### MANDATORY FIELDS ###
    my $emp_name = $args{-emp_name};   # (Scalar) Unix userid of the person doing the rearray
    my $data = $args{-data};           # (Scalar) data for the qpix rearray. Contains the same information as the clone file. Takes priority over -clonefile.
    my $clonefile = $args{-clonefile}; # (Scalar) filename of the clone file. The path should be fully qualified (eg /home/jsantos/csv). Superseded by -data.
    my $target_library = $args{-target_library}; # (Scalar) identifies the library that the new plates will be part of
    my $target_oligo_library = $args{-target_oligo_library}; # (Scalar) identifies the library that the new oligo plates will be part of (if applicable).
    my $plate_application = $args{-plate_application}; # (Scalar) identifies the application that the new plates will be used for. 

    ### PRE-REARRAY INFORMATION ###
    my $prerearray = $args{-create_96_transfer}; # (Scalar) flag that determines whether or not to create 4 96-well oligo rearrays for each qpix rearray (in the form of Reserved rearray plates). Primers will also be assigned to the oligo rearrays
    my $prerearray_384 = $args{-create_384_transfer}; # (Scalar) flag that determines whether or not to create 1 384-well oligo rearrays for each qpix rearray (in the form of Reserved rearray plates). Primers will also be assigned to the oligo rearrays
    my $omit_primer_order = $args{-omit_primer_order} || 0;
    my $oligo_direction = $args{-oligo_direction}; # (Scalar) the oligo direction

    ### OPTIONAL FIELDS ###
    my $format = $args{-format};     # (Scalar) determines which plate format to search for, and picks the latest plate with that format. For example, -format=>'Glycerol' will grab the latest glycerol plate with that Library_Name.Plate_Number combination.
    my $original = $args{-original}; # (Scalar) flag that determines whether or not to grab the earliest ORIGINAL plates. This should be the typical behaviour.
    my $notify_list_primer_order = $args{-notify_list_primer_order} || ''; # (Scalar) a comma-delimited string of emails who will be informed when the primer plate (the second step) has been provided with an external order number. 
    my $force_invalid_plates = $args{-force_invalid_plates}; # (Scalar) flag that determines whether or not to allow plates that have been exported, garbaged, or are not active
    my $clone_rearray_comments = $args{-clone_rearray_comments}; # (Scalar) comments for the clone rearray
    my $oligo_rearray_comments = $args{-oligo_rearray_comments}; # (Scalar) comments for the 4 oligo rearray
    my $duplicate_wells = $args{-duplicate_wells} || 0; # (Scalar) determines if wells can be double-dipped
    my $purpose = $args{-purpose}; # (Scalar) purpose of a clone rearray. One of Not applicable, 96-well oligo prep, 96-well EST prep, 384-well oligo prep, 384-well EST prep, 384-well hardstop prep
    my $debug = $args{-debug};     ## enables testing (redirects email notifications)

    # force duplication of wells if 384-well transfer
    $duplicate_wells = 1 if ($prerearray_384);

    my $dbc = $self->{dbc};

    ### ERROR CHECKING
    unless ($emp_name) {
	$emp_name = &get_username();
    }
    unless ($data || $clonefile) {
	$self->error("ERROR: Missing Parameter: -clonefile <clonefile> or -data <data> not specified");
    }
    if ($prerearray && (!($oligo_direction))) {
	$self->error("ERROR: Missing Parameter: Oligo direction -oligo_direction not specified");
    }

    if ($purpose !~ /Not applicable|96-well oligo prep|96-well EST prep|384-well oligo prep|384-well EST prep|384-well hardstop prep/) {
	$self->error("ERROR: Incorrect Parameter: -purpose should be one of Not applicable, 96-well oligo prep, 96-well EST prep, 384-well oligo prep, 384-well EST prep, or 384-well hardstop prep");
    }
    
    # check to see if format or original has been defined
    # this defines the behaviour of the plate search
    # the $original flag tells the script to look for the initial plate created (FKParent_Plate__ID == 0)
    # the $format is a string that the script will look for in the Plate_Format string. It will match all the plates and get the LATEST one.
    # (Plate_Format like (%$format%) group by FK_Library_Name, Plate Number) 
    unless ($original || $format) {
	$self->error("ERROR: Missing Parameter: -original flag or -format string not set");
    }

    # get employee id of user
    my @emp_id_array = $self->{dbc}->Table_find('Employee','Employee_ID,Employee_FullName',"where Email_Address='$emp_name'");
    my ($emp_id,$employee_fullname) = split ',',$emp_id_array[0];
    unless ($emp_id =~ /\d+/) {
	$self->error("ERROR: Invalid parameter: Employee $emp_name does not exist in database");
    }

    # do an error check on library
    my ($lib_count) = $self->{dbc}->Table_find('Library','count(*)',"where Library_Name='$target_library'");
    if ($lib_count != 1) {
	$self->error("ERROR: Invalid library: Library $target_library cannot be found in database");
    }
    if ($target_oligo_library) {
	my ($oligo_lib_count) = $self->{dbc}->Table_find('Library','count(*)',"where Library_Name='$target_oligo_library'");
	if ($oligo_lib_count != 1) {
	    $self->error("ERROR: Invalid library: Library $target_oligo_library cannot be found in database");
	}
    }

    ## Establish interested parties (groups to email) 
    my $interested_groups = join ',', $self->{dbc}->Table_find('Library','FK_Grp__ID',"WHERE Library_Name = '$target_library'",-distinct=>1);
    
    # do error check on clonefile if defined
    if ($clonefile && (!(-e $clonefile) ) ) {
	$self->error("ERROR: Invalid argument: file does not exist");	
    }
    if ($clonefile && (!(-r $clonefile) ) ) {
	$self->error("ERROR: Invalid argument: file cannot be read");	
    }

    # do error check on comments
    unless ($clone_rearray_comments) {
	$self->error("ERROR: Missing Parameter: -clone_rearray_comments not defined");
    }
    if ( ($prerearray || $prerearray_384) && !($oligo_rearray_comments) ) {
	$self->error("ERROR: Missing Parameter: -oligo_rearray_comments not defined");
    }
    
    ### FINISHED INITIAL ERROR CHECK
    if ($self->error()) {
	$self->success(0);
	return 0;
    }

    # get a hash that translates 96-well notation plus a quadrant to 384-well notation (ie A01b => 'A02')
    # also, get an array containing all 384-well addresses, ordered by Quadrant
    my %well_lookup = $dbc->Table_retrieve("Well_Lookup",['Quadrant','Plate_96','Plate_384'],'order by Quadrant,Plate_96');
    my %well_map; 
    my %well_384_to_96;
    my @wells_384 = ();
    my $index = 0;

    foreach my $well (@{$well_lookup{'Plate_96'}}) {
	$well_lookup{'Plate_384'}[$index] = &format_well($well_lookup{'Plate_384'}[$index]);
	$well_map{uc($well_lookup{'Plate_96'}[$index].$well_lookup{'Quadrant'}[$index])} = $well_lookup{'Plate_384'}[$index];
	$well_384_to_96{$well_lookup{'Plate_384'}[$index]} = uc($well_lookup{'Plate_96'}[$index]).$well_lookup{'Quadrant'}[$index];
	push (@wells_384, $well_lookup{'Plate_384'}[$index]);
	$index++;
    }

    my @wells_96 = ();
    foreach my $row ('A'..'H') {
	foreach my $col (1..12) {
	    $col = sprintf "%02d", $col;
	    my $newwell = $row.$col;
	    push (@wells_96,$newwell);	
	}
    }
    
    my @lines = ();
    # if clone data specified, split it into lines
    if ($data) {
	@lines = split "\n",$data;
    }
    else {
    # if clone file specified, open clone file and read all the lines into an array
	open(INF,"$clonefile");
	@lines = <INF>;
    }

    # initialize arrays that need to be stored
    my @clones = ();
    my @libraries = ();
    my @plate_numbers = ();
    my @newwells = ();
    my @clone_ids =();
    my @primers_seq = ();
    my @primers_tmp = ();
    
    my %defined_plates;

    my %lib_platenum_to_well;

    # look for lines that have clone information. Extract information from it : library, plate, well, primer sequence and primer melting pt
    my $linecount = 0;
    foreach my $line (@lines) {
	$linecount++;
	if ($line =~ /^(\S{5})(\d+[abcd]?)_?(\S{3}),(\w+),([\d\.]+)(?:,pla(\d+))?$/) {
	    my $library = $1;
	    my $plate = $2;
	    my $well = $3;
	    my $primer_seq = $4;
	    my $primer_tm = $5;

	    my $optional_plate = $6;

	    my $newwell = '';
	    my $newplate = '';
	    if ($plate =~ /(\d+)(\D).*/) {
		$newwell = $well_map{uc($well.$2)};
		$newplate = $1;
	    }
	    else {
		$newwell = $well;
		$newplate = $plate;
	    }

	    $newwell = uc($newwell);

	    # if the optional plate argument is defined, store and make
	    # sure it is not queried against the database
	    if ($optional_plate) {
		$defined_plates{$library.$plate} = $optional_plate;
	    }

	    my $clone = ("$library,$plate,$newwell,$primer_seq,$primer_tm");
	    push (@clones,$clone);
	    push (@libraries, $library);
	    push (@plate_numbers, $newplate);
	    my $clone_id = $library.$plate.$well;
	    push (@clone_ids,$clone_id);
	    push (@newwells,$newwell);

	    push (@primers_seq, $primer_seq);
	    push (@primers_tmp, $primer_tm);

	    # create an association between library-plate number to well
	    # also, append clone_ids and primer information to the well id
	    
	    if (defined $lib_platenum_to_well{"$library-$newplate"}) {
		push (@{$lib_platenum_to_well{"$library-$newplate"}}, "$newwell,$newwell,$clone_id,$primer_seq,$primer_tm");
	    }
	    else {
		$lib_platenum_to_well{"$library-$newplate"} = ["$newwell,$newwell,$clone_id,$primer_seq,$primer_tm"];
	    }
	}
	elsif ($line =~ /^(\S{5})(\d+[abcd]?)_?(\S{3})(?:,pla(\d+))?$/) {
	    my $library = $1;
	    my $plate = $2;
	    my $well = $3;
	    my $primer_seq = " ";
	    my $primer_tm = "0";
	    
	    my $optional_plate = $4;

	    my $newwell = '';
	    my $newplate = '';
	    if ($plate =~ /(\d+)(\D).*/) {
		$newwell = $well_map{uc($well.$2)};
		$newplate = $1;
	    }
	    else {
		$newwell = $well;
		$newplate = $plate;
	    }

	    $newwell = uc($newwell);

	    # if the optional plate argument is defined, store and make
	    # sure it is not queried against the database
	    if ($optional_plate) {
		$defined_plates{$library.$plate} = $optional_plate;
	    }

	    my $clone = ("$library,$plate,$newwell,$primer_seq,$primer_tm");
	    push (@clones,$clone);
	    push (@libraries, $library);
	    push (@plate_numbers, $newplate);
	    my $clone_id = $library.$plate.$well;
	    push (@clone_ids,$clone_id);
	    push (@newwells,$newwell);

	    push (@primers_seq, $primer_seq);
	    push (@primers_tmp, $primer_tm);

	    # create an association between library-plate number to well
	    # also, append clone_ids and primer information to the well id
	    
	    if (defined $lib_platenum_to_well{"$library-$newplate"}) {
		push (@{$lib_platenum_to_well{"$library-$newplate"}}, "$newwell,$newwell,$clone_id,$primer_seq,$primer_tm");
	    }
	    else {
		$lib_platenum_to_well{"$library-$newplate"} = ["$newwell,$newwell,$clone_id,$primer_seq,$primer_tm"];
	    }

	    # don't create prerearrays because primer info will be missing
	    $prerearray = 0;
	}
	elsif ($line =~ /^pla(\d+)_(\S{3})(?:,pla(\d+))?$/) {
	    ## add option to supply plate ids explicitly ##
	}
	else {
	    $self->error("ERROR: unrecognized format on line $linecount in data file ($line)");
	    $self->success(0);
	    return 0;
	}

    }    

    ### ERROR CHECK
    # check to see if all the defined plates exist in the database
    if (scalar(keys(%defined_plates)) > 0) {
	my @error_check = $self->{dbc}->Table_find('Plate','Plate_ID','WHERE Plate_ID in ('.(join ',',values(%defined_plates)).')');
	if (scalar(values(%defined_plates)) != scalar(@error_check)) {
	    $self->error("ERROR: Invalid value: Defined plate not found in database");
	    $self->success(0);
	    return 0;
	}
    }
    
    # check to see if the source plates are all 384-well. If not, check if their plate format is 384-well.
    # if it is NOT 384-well, fail.
    # if it is 384-well, get the Multiple_Barcode entry and replace it with the correct plate id and well designation

    # get plates that are not 384-well size
    my @format_check_for_384_size = ();
    if (scalar(keys(%defined_plates))>0) {
	@format_check_for_384_size = $self->{dbc}->Table_find('Plate','Plate_ID',"WHERE Plate_Size<>'384-well' AND Plate_ID in (".join(',',values(%defined_plates)).")");
    }
    unless (scalar(@format_check_for_384_size) == 0) {
	my @format_check_for_384_format = $self->{dbc}->Table_find('Plate,Plate_Format','Plate_ID',"WHERE FK_Plate_Format__ID=Plate_Format_ID AND Wells <>'384' AND Plate_ID in (".join(',',@format_check_for_384_size).")");	
	unless (scalar(@format_check_for_384_format) == 0) {
	    $self->error("ERROR: Size error: Using a 96-well plate in a clone rearray");
	    $self->success(0);
	    return 0;
	}
	# everything in @format_check_for_384_size is 96-well size, 384-well format
	# check the well, grab the mul barcode - replace the plate id with the correct one and map the well id to 96-well for clone tracking (actual well)
	foreach my $plateid (@format_check_for_384_size) {
	    my $tray_id = alDente::Tray::exists_on_tray($dbc,'Plate',$plateid);
	    if(!$tray_id) {
		$self->error("ERROR: $plateid does not exist on a tray.");
		$self->success(0);
		return 0;
	    }
	    my @mul_array = alDente::Tray::get_content($dbc,'Plate',$tray_id);
	    my $i = 0;
	    my @quadrant_array = ('a','b','c','d');
	    my %quadrant_to_plate;
	    foreach my $id (@mul_array) {
		$quadrant_to_plate{$quadrant_array[$i]} = $id;
		$i++;
	    }
	    # get information about plate
	    my ($plate_info) = $self->{dbc}->Table_find('Plate','FK_Library__Name,Plate_Number',"WHERE Plate_ID=$plateid");
	    my ($library,$plate_number) = split ',',$plate_info;
	    foreach my $row (@{$lib_platenum_to_well{"$library-$plate_number"}}) {
		# get well translation
		my ( $sourcewell, $actual_well, $cloneid, $primer_seq, $primer_temp, $alt_plateid) = split ',',$row;
		$well_384_to_96{$sourcewell} =~ /^(\S{3})(\w)$/;
		my $well = $1;
		my $quadrant = $2;
		$alt_plateid = $quadrant_to_plate{$quadrant};  ### <CONSTRUCTION> Why reset to another value after retrieving above ?	
		$row = "$sourcewell,$well,$cloneid,$primer_seq,$primer_temp,$alt_plateid";
	    }
	}
    }
    
    ### get plate id
    $index = 0;
    my $condition_string = "(";
    my $search_condition = " (FKParent_Plate__ID=0 OR FKParent_Plate__ID IS NULL) ";
    foreach my $library (@libraries) {
	# if the plate id has been defined in the source file, don't query the database on it
	if (defined($defined_plates{$library.$plate_numbers[$index]})) {
	    $index++;
	    next;
	}
	$condition_string .= "(FK_Library__Name='$library' AND Plate_Number=$plate_numbers[$index]) OR";
	if ($original) {
	    $search_condition = " (FKParent_Plate__ID=0 OR FKParent_Plate__ID IS NULL) ";
	}
	elsif ($format) {
	    $search_condition = " Plate_Format_Type like '%$format%' ";
	}
	$index++;
    }
    # remove the final OR
    $condition_string = substr ($condition_string, 0, -3);
    # close parenthesis
    $condition_string .= ")";

    ## Get all plate IDs involved in the Rearray

    # create a hash that represents the latest Plate_ID associated with the Library_Name, Plate_Number pair
    my %plate_ids;
    # get Plate IDs ordered by Plate_Created
    # This is so the last occurence of the Library_Name.Plate_Number pair is the latest Plate_ID (which is what we want)
    # Save each Plate_ID in a hash with the Library_Name.Plate_Number pair as keys.
    # this loop will terminate with the hash containing the latest Plate_IDs
    foreach my $plate_id ($self->{dbc}->Table_find_array("Plate_Format,Plate,Rack",['FK_Library__Name','Plate_Number','Plate_ID','Plate_Status','Rack_Name'],"WHERE $condition_string AND $search_condition AND FK_Plate_Format__ID=Plate_Format_ID AND FK_Rack__ID=Rack_ID ORDER BY Plate_Created")) {
	my ($lib_name, $plate_number, $plate_id, $plate_status, $rack_name)  = split ',',$plate_id;
	if ( (!($force_invalid_plates)) && ($rack_name =~ /Exported/) ) {
	    $self->error("ERROR: plate $plate_id ($lib_name-$plate_number) has been exported");
	    $self->success(0);
	    return 0;  
	}
	if ( (!($force_invalid_plates)) && ($rack_name =~ /Garbage/) ) {
	    $self->error("ERROR: plate $plate_id ($lib_name-$plate_number) has been thrown away");
	    $self->success(0);
	    return 0;  
	}
	if ( (!($force_invalid_plates)) && ($plate_status !~ /Active/)) {
	    $self->error("ERROR: plate $plate_id ($lib_name-$plate_number) is no longer active");
	    $self->success(0);
	    return 0;  
	}
	$plate_ids{$lib_name.$plate_number} = $plate_id;
    }

    # make another call to Table_find, but sort by Equipment Name and Rack ID
    my $plate_id_string = join ',',values(%plate_ids);
    # add defined plates to the string
    if (scalar(values(%defined_plates)) > 0) {
	if ($plate_id_string ne "") {
	    $plate_id_string .= ','.(join ',',values(%defined_plates));
	}
	else {
	    $plate_id_string = join ',',values(%defined_plates);
	};
    }

    my @plate_array = $self->{dbc}->Table_find_array("Plate,Rack,Equipment",['FK_Library__Name','Plate_Number','Plate_ID'],"WHERE Plate_ID in ($plate_id_string) AND FK_Equipment__ID=Equipment_ID AND FK_Rack__ID=Rack_ID ORDER BY Equipment_Name, Rack_ID, Plate_ID ASC");


    # generate arrays needed for create_rearray call
    # can create multiple 384-well plates, stored in $<target>_rearrays array
    # also, start building primer rearray information for 96-well oligo plates
    # this will only be used if the $prerearray flag is set
    $index = 0; 

    # variables for 384 well clone rearray
    my $counter = 0;
    my @source_plates_array = ();
    my @source_wells_array = ();
    my @target_wells_array = ();
    my @actual_source_wells_array = ();
    my $source_plates = [];
    my $target_wells = [];
    my $source_wells = [];
    my $actual_source_wells = [];

    # variables for 96 well oligo rearray
    my $index_96 = 0;
    my $index_384 = 0;
    my $plate_track_num = 0;
    my @source_plates_array_96 = ();
    my @source_wells_array_96 = ();
    my @target_wells_array_96 = ();
    my @primer_seq_array_96 = ();
    my @primer_tmp_array_96 = ();
    my @primer_name_array_96 = ();
    my @sample_id_array_96 = ();
    my $source_plates_96 = [];
    my $target_wells_96 = [];
    my $source_wells_96 = [];
    my $primer_sequence_96 = [];
    my $primer_temp_96 = [];
    my $primer_name_96 = [];
    my $sample_id_96 = [];


    # track if the clone has been entered into the arrays
    # if it has, then skip over it, BUT
    # it is still entered into the 96-well rearrays, double-dipping
    # from a single well

    # sort the wells within each plate A01-P24
    foreach my $arrayref (values %lib_platenum_to_well) {
	my @newarray = sort (@{$arrayref});
	$arrayref = \@newarray;
    }
    # get a count of similar primer names in the database, and increment the suffix correctly
    my $primer_name_string = "";
    foreach my $clone (@clone_ids) {
	$primer_name_string .= "OR (Primer_Name like '$clone%') ";
    }
    my @primer_naming_count = $self->{dbc}->Table_find_array('Primer', ['count(*)',"left(Primer_Name,instr(Primer_Name,'-') - 1)"], "where 1 $primer_name_string group by left(Primer_Name,instr(Primer_Name,'-') - 1)");
    my %primer_naming_hash;
    foreach my $row (@primer_naming_count) {
	my ($count, $name) = split ',',$row;
	$primer_naming_hash{$name} = $count;
    }

    # keep track of sample ids for the clone rearray
    my %clone_sample_ids;
    my $current_sample_id = 0;

    # hash that keeps track of repeats
    my %unique_clone_ids;
    my $primer_name = "";
    my $source_plate_count = 0;
    my $wellcount_index = -1;

    foreach my $plate_string (@plate_array) {
	my ($library, $platenum, $plateid) = split ',',$plate_string;
	my $prev_cloneid = "";
	foreach my $s_well (@{$lib_platenum_to_well{"$library-$platenum"}}) {
	    my ( $sourcewell, $actual_well, $cloneid, $primer_seq, $primer_temp, $alt_plateid) = split ',',$s_well;
	    # make the sourcewell equal to the actual well (the 384-well designation for a 96x4/384 was preserved for sorting), as
	    # now it is necessary to use the actual well designation, which is 96-well.
	    $sourcewell = $actual_well;
	    my $orig_plateid = $plateid;
	    if ( $alt_plateid =~ /\d+/ ) {
		$plateid = $alt_plateid;
	    }

	    $primer_name = $cloneid;

	    if ($prev_cloneid ne $cloneid) {
		$wellcount_index++;
	    }
	    if ($wellcount_index==96) {
		$wellcount_index=0;
		$source_plate_count++;
	    } 

	    # save 96_well information
	    push (@{$primer_sequence_96}, $primer_seq);
	    push (@{$primer_temp_96}, $primer_temp);
	    push (@{$source_plates_96}, $source_plate_count);
	    if ($duplicate_wells) {
		push (@{$source_wells_96}, $wells_96[$index_96]);	
	    }
	    else {
		push (@{$source_wells_96}, $wells_96[$wellcount_index]);
	    }

	    push (@{$target_wells_96}, $wells_96[$index_96]);
	    $index_96++;

	    # save 384_well information
	    if ( ($duplicate_wells) || (!(defined $unique_clone_ids{$cloneid})) ) {
		# find sample id
		$clone_sample_ids{$plateid}{$sourcewell} ||= &alDente::Container::get_Parents(-dbc=>$dbc,-id=>$plateid,-well=>$sourcewell,-format=>'sample_id');
		$current_sample_id = $clone_sample_ids{$plateid}{$sourcewell};
		push (@{$source_plates}, $plateid);
		push (@{$source_wells}, $sourcewell);
		push (@{$actual_source_wells}, $actual_well);
		push (@{$target_wells}, $wells_384[$index]);
		$unique_clone_ids{$cloneid} = 1;
		$primer_naming_hash{$cloneid}++;
		$primer_name .= "-$primer_naming_hash{$cloneid}";
		$index++;
	    }
	    else {
		$unique_clone_ids{$cloneid}++;
		$primer_naming_hash{$cloneid}++;
		$primer_name .= "-$primer_naming_hash{$cloneid}";
	    }

	    push (@{$primer_name_96}, $primer_name);
	    push (@{$sample_id_96}, $current_sample_id);

	    # roll index over if index hits 96
	    if ($index_96 == 96) {
		$index_96 = 0;
		push (@primer_name_array_96,$primer_name_96);
		push (@primer_seq_array_96,$primer_sequence_96);
		push (@primer_tmp_array_96,$primer_temp_96);
		push (@source_plates_array_96, $source_plates_96);
		push (@source_wells_array_96, $source_wells_96);
		push (@target_wells_array_96, $target_wells_96);
		push (@sample_id_array_96, $sample_id_96);
		$sample_id_96 = [];
		$primer_sequence_96 = [];
		$primer_name_96 = [];
		$primer_temp_96 = [];	
		$target_wells_96 = [];
		$source_wells_96 = []; 
		$source_plates_96 = [];
	    }
	    # roll index over if index hits 384
	    if ($index == 384) {
		$index = 0;
		push (@source_plates_array, $source_plates);
		push (@source_wells_array, $source_wells);
		push (@target_wells_array, $target_wells);
		push (@actual_source_wells_array, $actual_source_wells);
		$source_plates = [];
		$target_wells = [];
		$source_wells = [];
		$actual_source_wells = [];
	    }
	    $prev_cloneid = $cloneid;
	    $plateid = $orig_plateid;
	}
    }

    # push if the temporary arrays haven't been pushed into the storage arrays
    if ($index != 0) {
	push (@source_plates_array, $source_plates);
	push (@source_wells_array, $source_wells);
	push (@target_wells_array, $target_wells); 
	push (@actual_source_wells_array, $actual_source_wells);  
    }
    if ($index_96 != 0) {
	push (@primer_seq_array_96,$primer_sequence_96);
	push (@primer_tmp_array_96,$primer_temp_96);
	push (@source_wells_array_96, $source_wells_96);
	push (@target_wells_array_96, $target_wells_96);
	push (@primer_name_array_96, $primer_name_96);
	push (@source_plates_array_96, $source_plates_96);
	push (@sample_id_array_96, $sample_id_96);
    }
   
    # call create_sequencing_rearray to create the clone rearray
    my @rearray_ids = ();
    my @new_plate_ids = ();

    my $new_plate_id = "";

    for (my $i=0; $i < scalar(@source_plates_array); $i++) {

	my ($new_rearray_id, $plate_id) = $self->create_sequencing_rearray(-status=>"Ready for Application",-source_plates=>$source_plates_array[$i],-source_wells=>$source_wells_array[$i],-target_wells=>$target_wells_array[$i],-emp_name=>$emp_name,-request_type=>"Clone Rearray",-target_size=>384,-target_library=>$target_library,-plate_application=>$plate_application,-plate_class=>'ReArray',-create_plate=>1,-rearray_comments=>$clone_rearray_comments,-purpose=>$purpose);  
	if ($self->error()) {
	    $self->success(0);
	    return;
	}

	push (@rearray_ids, $new_rearray_id);
	push (@new_plate_ids, $plate_id);
	$new_plate_id = $plate_id;
    } 

    #### fill the Primer Rearray table

    my $datetime = &date_time();
    # get information on the ReArray table to find the foreign keys that need to be set for Primer_ReArray
    my $new_ids = join ',',@rearray_ids;
    my @fk_rearray_id_rows = $self->{dbc}->Table_find_array('ReArray',['ReArray_ID'],"where FK_ReArray_Request__ID in ($new_ids)");
    my @fk_ids = ();
    my %rearray_info = ();
    foreach my $fk_rearray_id_row (@fk_rearray_id_rows) {
	my ($fk_rearray_id) = split ',',$fk_rearray_id_row;
	push (@fk_ids, $fk_rearray_id);
    }
    $index = 1; 

    #my $dbo = SDB::DBIO->new(-dbh=>$dbh);    

    # check to see if we want to create the 96-well plates
    # if yes, call Container_Set to perform the transfer, then create the 96-well
    # rearrays with the corresponding primers
    my @prerearray_ids = ();

    if ($prerearray || $prerearray_384)  {
	my $oligo_rearray_status = 'Waiting for Primers';
	if ($omit_primer_order) {
	    $oligo_rearray_status = 'Waiting for Preps';
	}
	# create primer records
	# skip if omit_primer_order
	unless ($omit_primer_order) {
	    for (my $i=0; $i < scalar(@source_wells_array_96); $i++) {
		my $target_wells = $target_wells_array_96[$i];
		my $primer_names = $primer_name_array_96[$i];
		my $primer_sequence = $primer_seq_array_96[$i];
		my $primer_temp = $primer_tmp_array_96[$i];
		# send off primer order
		my @direction = ();
		foreach (1..scalar(@{$primer_names})) {
		    push (@direction,$oligo_direction);
		}
		my %rethash = %{$self->order_primers(-emp_name=>$emp_name,-wells=>$target_wells,-name=>$primer_names,-sequence=>$primer_sequence,-tm_working=>$primer_temp,-primer_type=>'Oligo',-direction=>\@direction)};
		# error check
		if ($self->error()) {
		    $self->success(0);
		    return 0;
		}
	    }
	}
	
	## Insert oligo rearrays
	# ASSUMPTION: the _96 arrays are all ordered a,b,c,d

	# code for 384-well oligo rearrays
	if ($prerearray_384) {
	    # if target_oligo_library is not defined, use target_library
	    my $oligo_library = $target_library;
	    if ($target_oligo_library) {
		$oligo_library = $target_oligo_library;
	    }
	    my @oligo_sourceplates_384 = ();
	    my @oligo_sourcewells_384 = ();
	    my @oligo_targetwells_384 = ();
	    my @oligo_primernames_384 = ();
	    my @oligo_sampleid_384 = ();
	    my $count = 0;
	    my $temp_sourceplates = [];
	    my $temp_sourcewells = [];
	    my $temp_targetwells = [];
	    my $temp_primernames = [];
	    my $temp_sampleid = [];
	    
	    # compile each batch of 4 into 1 384-well oligo rearray
	    for (my $i=0; $i < scalar(@source_wells_array_96); $i++) {
		foreach my $source_plate_count (@{$source_plates_array_96[$i]}) {
		    push (@{$temp_sourceplates}, 0);
		}
		# convert target wells into 384-well format (from 96)
		foreach my $well_from_96 (@{$target_wells_array_96[$i]}) {
		    my $quad = '';
		    $quad = 'A' if ($count == 0);
 		    $quad = 'B' if ($count == 1);
		    $quad = 'C' if ($count == 2);
		    $quad = 'D' if ($count == 3);
		    # fill source wells as well
		    push(@$temp_targetwells,$well_map{"$well_from_96$quad"});
		    push(@{$temp_sourcewells},$well_map{"$well_from_96$quad"});
		}
		push(@{$temp_primernames},@{$primer_name_array_96[$i]});
		push(@{$temp_sampleid},@{$sample_id_array_96[$i]});
		$count++;
		if ($count == 4) {
		    push (@oligo_sourceplates_384,$temp_sourceplates);
		    push (@oligo_sourcewells_384,$temp_sourcewells);
		    push (@oligo_targetwells_384,$temp_targetwells);
		    push (@oligo_primernames_384,$temp_primernames);
		    push (@oligo_sampleid_384,$temp_sampleid);	    
		    $temp_sourceplates = [];
		    $temp_sourcewells = [];
		    $temp_targetwells = [];
		    $temp_primernames = [];
		    $temp_sampleid = [];
		    $count = 0;
		}
	    }
	    # push into array if there are elements in the temporary arrays
	    if (int(@$temp_sourcewells) > 0) {
		push (@oligo_sourceplates_384,$temp_sourceplates);
		push (@oligo_sourcewells_384,$temp_sourcewells);
		push (@oligo_targetwells_384,$temp_targetwells);
		push (@oligo_primernames_384,$temp_primernames);
		push (@oligo_sampleid_384,$temp_sampleid);	 
		$temp_sourceplates = [];
		$temp_sourcewells = [];
		$temp_targetwells = [];
		$temp_primernames = [];
		$temp_sampleid = [];
	    }
	    # create rearray with primer linking
	    # for 384-well transfers
	    for (my $i=0; $i < scalar(@oligo_sourceplates_384); $i++) {
		my $sourceplates = $oligo_sourceplates_384[$i];
		my $sourcewells = $oligo_sourcewells_384[$i];
		my $targetwells = $oligo_targetwells_384[$i];
		my $primernames = $oligo_primernames_384[$i];
		my ($id, $plate_id) = $self->create_sequencing_rearray(-status=>$oligo_rearray_status,-source_plates=>$sourceplates,-source_wells=>$sourcewells,-target_wells=>$targetwells,-primer_names=>$primernames,-emp_name=>$emp_name,-request_type=>"Reaction Rearray",-target_size=>384,-target_library=>$oligo_library,-plate_application=>$plate_application,-plate_class=>'Oligo',-create_plate=>1,-notify_list=>$notify_list_primer_order,-rearray_comments=>$oligo_rearray_comments);  
		# error check
		if ($self->error()) {
		    $self->success(0);
		    return 0;
		}
		# update FK_Sample__ID of the rearray
		my $sample_count = 0;
		my $sample_ids = $oligo_sampleid_384[$i];
		foreach my $sample_id (@{$sample_ids}) {
		    my $target_well = $target_wells->[$sample_count];
		    $self->{dbc}->Table_update_array("ReArray",['FK_Sample__ID'],["$sample_id"],"WHERE FK_ReArray_Request__ID=$id AND Target_Well like '$target_well'");
		    $sample_count++;
		}
		push (@prerearray_ids, $id);
	    }
	}
	else {
	# code for 96-well oligo rearrays
	    for (my $i=0; $i < scalar(@source_wells_array_96); $i++) {
		my @source_plates = ();
		foreach my $source_plate_count (@{$source_plates_array_96[$i]}) {
		    push (@source_plates, 0);
		}
		my $source_wells = $source_wells_array_96[$i];
		my $target_wells = $target_wells_array_96[$i];
		my $primer_names = $primer_name_array_96[$i];
		# if target_oligo_library is not defined, use target_library
		my $oligo_library = $target_library;
		if ($target_oligo_library) {
		    $oligo_library = $target_oligo_library;
		}
		# create rearray with primer linking
		# for 96-well transfers
		my ($id, $plate_id) = $self->create_sequencing_rearray(-status=>$oligo_rearray_status,-source_plates=>\@source_plates,-source_wells=>$source_wells,-target_wells=>$target_wells,-primer_names=>$primer_names,-emp_name=>$emp_name,-request_type=>"Reaction Rearray",-target_size=>96,-target_library=>$oligo_library,-plate_application=>$plate_application,-plate_class=>'Oligo',-create_plate=>1,-notify_list=>$notify_list_primer_order,-rearray_comments=>$oligo_rearray_comments);  
		# error check
		if ($self->error()) {
		    $self->success(0);
		    return 0;
		}
		# update FK_Sample__ID of the rearray
		my $sample_count = 0;
		my $sample_ids = $sample_id_array_96[$i];
		foreach my $sample_id (@{$sample_ids}) {
		    my $target_well = $target_wells->[$sample_count];
		    $self->{dbc}->Table_update_array("ReArray",['FK_Sample__ID'],["$sample_id"],"WHERE FK_ReArray_Request__ID=$id AND Target_Well like '$target_well'");
		    $sample_count++;
		}
		push (@prerearray_ids, $id);
	    }
	}

	# get the range
	my $rearray_range = $prerearray_ids[0]."-".$prerearray_ids[-1];
	unless ($omit_primer_order) {
	    $self->send_primer_order(-emp_name=>$emp_name,-request_range=>$rearray_range,-group=>$interested_groups);
	} 	
    }

    # send email notification to lab admins
    #my @mail = @lab_admin_emails;
    my @mail =  @{ &alDente::Employee::get_email_list($dbc,'lab admin',-group=>$interested_groups)};
    push (@mail, $emp_name);    
    my $target_list = join ',',  @mail;
    my $url_location = "";
    foreach my $rearray_id (@rearray_ids) {
        $url_location .= Link_To($dbc->homelink(),"Rearray $rearray_id","Request_ID=$rearray_id&Expand+ReArray+View=1&Order=Target_Well","$Settings{LINK_COLOUR}");
    }

    my $range = &convert_to_range($new_ids);
    $range =~ s/,/\./g;
#    &alDente::Notification::Email_Notification($target_list,'aldente@bcgsc.bc.ca','Clone Rearray requested',"Clone Rearray/s, request number/s $new_ids from $employee_fullname has been requested\n\n$url_location",undef,'html',-append=>"clone_rearray.txt",-testing=>$debug);

#++++++++++++++++++++++++++++++ Subscription Module version of the Notification
#    my $tmp = alDente::Subscription->new(-dbc=>$dbc);
	
#    my $ok = $tmp->send_notification(-name=>"Clone Rearray Requested",-from=>'aldente@bcgsc.ca',-subject=>"Clone Rearray Requested (request number/s $new_ids) from $employee_fullname (from Subscription Module)",-body=>"Clone ReArray/s, request number/s $new_ids from $employee_fullname has been requested\n\n$url_location",-content_type=>'html',-testing=>1,-append=>"clone_rearray_subscription.txt");
	
#++++++++++++++++++++++++++++++
    my $ok = alDente::Subscription::send_notification(-dbc=>$dbc,-name=>"Clone Rearray Requested",-from=>'aldente@bcgsc.ca',-subject=>"Clone Rearray Requested (request number/s $new_ids) from $employee_fullname (from Subscription Module)",-body=>"Clone ReArray/s, request number/s $new_ids from $employee_fullname has been requested\n\n$url_location",-content_type=>'html',-testing=>0,-append=>"clone_rearray_subscription.txt");

    
    # print and return the new ReArray_Request_IDs created
    push (@rearray_ids, @prerearray_ids);

    ## add to a Lab_Request
    # create a Lab_Request entry
    ($emp_id) = $self->{dbc}->Table_find("Employee","Employee_ID","WHERE Email_Address='$emp_name'");
    my $insert_id = $self->{dbc}->Table_append_array("Lab_Request",['FK_Employee__ID','Request_Date'],[$emp_id,&date_time()],-autoquote=>1);
    $self->{dbc}->Table_update_array("ReArray_Request",['FK_Lab_Request__ID'],["$insert_id"],"WHERE ReArray_Request_ID in (".join(',',@rearray_ids).")");

    return join ',',@rearray_ids;
}





##########################################
# Function: autosets primer rearray status, and sends emails if necessary
# Return: 1 if successful, 0 otherwise.
##########################################
sub autoset_primer_rearray_status {
##########################################
    my $self = shift;

    my %args = &filter_input(\@_);
    my $rearray_ids = $args{-rearray_ids};
    my $group = $args{-group};
    my $department = $args{-department};
    my $debug = $args{-debug};     ## enables testing (redirects email notifications)

    my $dbc = $self->{dbc};

    unless ($rearray_ids) {
	Message("No rearray ids defined");
	return 0;
    }
    if (int(@$rearray_ids) == 0) {
	Message("No rearray ids defined");
	return 0;
    }

    my @links = ();
    my @email_list = ();
    my @prep_list = ();
    my @ready_list = ();
    my @primer_list = ();

    foreach my $request_id (sort {$a <=> $b} @$rearray_ids) {
	my $ready_rearray = 0;
	my @undefined_source_plates = $self->{dbc}->Table_find('ReArray',"FKSource_Plate__ID","WHERE FK_ReArray_Request__ID = $request_id AND FKSource_Plate__ID=0");
	my @ordered_primer_plates = $self->{dbc}->Table_find("ReArray,ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate","distinct Primer_Plate_ID","WHERE FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND FK_Primer_Plate__ID=Primer_Plate_ID AND (Primer_Plate_Status='To Order' OR Primer_Plate_Status='Ordered') AND ReArray_Request_ID = $request_id");
	
	# if there are both no undefined source plates and all primer plates have been received, then set to Ready
	if ( (int(@undefined_source_plates) == 0) && (int(@ordered_primer_plates) == 0) ) {
	    my ($status_id) = $self->{dbc}->Table_find("Status","Status_ID","WHERE Status_Name = 'Ready for Application'");
	    $self->{dbc}->Table_update_array("ReArray_Request",['FK_Status__ID'],[$status_id],"WHERE ReArray_Request_ID = $request_id");
	    push (@ready_list, $request_id);
	    $ready_rearray = 1;
	}
	# if there are undefined source plates but no more primer plates to order, then set to Waiting for Preps
	elsif ( (int(@undefined_source_plates) > 0) && (int(@ordered_primer_plates) == 0) ) {
	    my ($status_id) = $self->{dbc}->Table_find("Status","Status_ID","WHERE Status_Name = 'Waiting for Preps'");
	    $self->{dbc}->Table_update_array("ReArray_Request",['FK_Status__ID'],[$status_id],"WHERE ReArray_Request_ID = $request_id");
	    push (@prep_list, $request_id);
	}
	# if there are still primer plates on order, set to Waiting for Primers
	else {
	    my ($status_id) = $self->{dbc}->Table_find("Status","Status_ID","WHERE Status_Name = 'Waiting for Primers'");
	    $self->{dbc}->Table_update_array("ReArray_Request",['FK_Status__ID'],[$status_id],"WHERE ReArray_Request_ID = $request_id");
	    push (@primer_list, $request_id);
	}
	    
	# if a rearray has been set to ready, then send emails
	if ($ready_rearray) {
	    # get employee name and email 
	    my @employee_info = $self->{dbc}->Table_find_array('Employee,ReArray_Request',['Employee_FullName','Email_Address'],"where FK_Employee__ID=Employee_ID and ReArray_Request_ID=$request_id");
	    my ($emp_name,$emp_email) = split ",",$employee_info[0];
	    # get the other emails of interested people from ReArray_Notify
	    my @other_emails_array = $self->{dbc}->Table_find_array('ReArray_Request',['ReArray_Notify'],"where ReArray_Request_ID=$request_id");
	    # split the emails and add to email list
	    my @other_emails = ();
	    if (($other_emails_array[0] != '') || ($other_emails_array[0] !~ /NULL/)) {
		@other_emails = split ',',$other_emails_array[0];
	    }
	    # send email to lab_administrators that a rearray is ready to be applied
	    my @emails =  @{ &alDente::Employee::get_email_list($dbc,'lab admin',-group=>$group,-department=>$department,-project=>$project) };
	    push(@emails,@other_emails,$emp_email);
	    
	    push (@email_list,@emails);
	    @email_list = @{&unique_items(\@email_list)};
	    my $url_location .= Link_To($dbc->homelink(),"Rearray $request_id","Request_ID=$request_id&Expand+ReArray+View=1&Order=Target_Well","$Settings{LINK_COLOUR}");
            push (@links, $url_location);
	} 
    }

    my $target_list = join ',', @email_list;
    my $message = join '<BR>',@links;
#    &alDente::Notification::Email_Notification($target_list,'aldente@bcgsc.bc.ca','Primer ReArray ready for application',"Primer Rearrays ready to be applied: <BR> $message",undef,'html',-append=>"rearray_ready.txt",-testing=>$debug);

#++++++++++++++++++++++++++++++ Subscription Module version of the Notification
#Are we going to do anything about attachments
    # my $tmp = alDente::Subscription->new(-dbc=>$dbc);
	
    # my $ok = $tmp->send_notification(-name=>"Primer ReArray ready for application",-from=>'aldente@bcgsc.ca',-subject=>'Primer ReArray ready for application (from Subscription Module)',-body=>"Primer Rearrays ready to be applied: <BR> $message",-content_type=>'html',-testing=>1,-append=>"rearray_ready_subscription.txt");
	my $ok = alDente::Subscription::send_notification(-dbc=>$dbc,-name=>"Primer ReArray ready for application",-from=>'aldente@bcgsc.ca',-subject=>'Primer ReArray ready for application (from Subscription Module)',-body=>"Primer Rearrays ready to be applied: <BR> $message",-content_type=>'html',-testing=>0,-append=>"rearray_ready_subscription.txt");

#++++++++++++++++++++++++++++++

    if (int(@prep_list) > 0) {
	Message("The following rearrays have been set to Waiting for Preps");
	Message(join(',',@prep_list));
    }
    if (int(@ready_list) > 0) {
	Message("The following rearrays have been set to Ready for Appplication");
	Message(join(',',@ready_list));
    }
    return 1;
}


##############################
# public_functions           #
##############################


##############################
# private_methods            #
##############################



##############################
# private_functions          #
##############################



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

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-10-31

=head1 REVISION <UPLINK>

$Id: ReArray.pm,v 1.183 2004/12/15 23:33:14 jsantos Exp $ (Release: $Name:  $)

=cut


return 1;
