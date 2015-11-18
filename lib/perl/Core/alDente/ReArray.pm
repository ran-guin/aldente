package alDente::ReArray;

use CGI qw(:standard);

use alDente::CGI_App;
use RGTools::RGIO;
use Data::Dumper;
use SDB::DB_Object;
use SDB::HTML;
use SDB::CustomSettings;
use RGTools::Conversion;
use alDente::Library_Plate;
use CGI::Carp('fatalsToBrowser');

use vars qw(%Configs %Settings $Sess);
=pod
=head1 SYNOPSIS



## Dependencies

## Container/Library_Plate
## Primer
## Primer_Order


##  GUI Interface
    ##  Navigation
    ##  Add plugins
    ##  Search ReArray Requests
    ##  Handle own parameters
    ##  Manual ReArray

##  API Calls for ReArrays

## Plate ReArray Handling #################################

##  Create ReArray Request
	##  Target Plate
		##  Creation of Target Plate
		##  Reserved & Assigning Plates
	##  Types of ReArray Requests
		## Pooling of Tubes/Plates
	##  Status of ReArray Requests
	##  Summaries
	##  Subscription
	    ## Notification
##  Create ReArray Object
    ##  Source Plate
	##  Source Wells
	##  Target Wells

##  Reassign target plate


## Parsing ReArray Information from a file
    ##  Headers (Standardize)
        ##  Defaults if necessary
        
        
        ##  Primer Object
        	##  Ordering Primers
        		## IDT Plug-in file format 
        		## Illumina Plug-in file format 
        		## Primer Yield report uploading
        		## Subscription

        ##  Parsing Primer Plate Information from a file

## ReArraying Machines ####################################

        ##  Equipment Plug-ins
        	##  QPIX
        		##  Generation of file format
        		##  Summary View
        		##  Parsing log file
        	##  Multiprobe
        		##  Summary View
        		##  Generation of file format

            ##  Subscription/Notification


Database structures:

CREATE TABLE `ReArray_Request` (
`ReArray_Notify` text,
`ReArray_Format_Size` enum('96-well','384-well') NOT NULL default '96-well',
`ReArray_Type` enum('Clone Rearray','Manual Rearray','Reaction Rearray','Extraction Rearray','Pool Rearray') default NULL,
`FK_Employee__ID` int(11) default NULL,
`Request_DateTime` datetime default NULL,
`FKTarget_Plate__ID` int(11) default NULL,
`ReArray_Comments` text,
`ReArray_Request` text,
`ReArray_Request_ID` int(11) NOT NULL auto_increment,
`FK_Lab_Request__ID` int(11) default NULL,
`FK_Status__ID` int(11) NOT NULL default '0',
`ReArray_Purpose` enum('Not applicable','96-well oligo prep','96-well EST prep','384-well oligo prep','384-well EST prep','384-well hardstop prep') default 'Not applicable',
PRIMARY KEY (`ReArray_Request_ID`),
KEY `request_time` (`Request_DateTime`),
KEY `request_target` (`FKTarget_Plate__ID`),
KEY `request_emp` (`FK_Employee__ID`),
KEY `FK_Lab_Request__ID` (`FK_Lab_Request__ID`),
KEY `FK_Status__ID` (`FK_Status__ID`),
KEY `ReArray_Purpose` (`ReArray_Purpose`)
) ENGINE=InnoDB

## ReArray_Purpose -> Used???
## Types of ReArrays -> Clarify
## Lab Request -> used for summaries?
## Rearray Notify ->drop

CREATE TABLE `ReArray` (
`FKSource_Plate__ID` int(11) NOT NULL default '0',
`Source_Well` char(3) NOT NULL default '',
`Target_Well` char(3) NOT NULL default '',
`ReArray_ID` int(11) NOT NULL auto_increment,
`FK_ReArray_Request__ID` int(11) NOT NULL default '0',
`FK_Sample__ID` int(11) default '-1',
PRIMARY KEY (`ReArray_ID`),
KEY `rearray_req` (`FK_ReArray_Request__ID`),
KEY `target` (`Target_Well`),
KEY `source` (`FKSource_Plate__ID`),
KEY `fk_sample` (`FK_Sample__ID`)
) ENGINE=InnoDB

## FK_Sample__ID Redundant?


Usage:

     my ($rearray_request_id, $target_plate_id)  = $rearray_obj->create_rearray(-request_type => $request_type,
                                                                                -source_plates => ['5000','5000'],
                                                                                -source_wells => ['A01','A02'],
                                                                                -target_wells => ['P23','P24']);

     my $rearray_types= $rearray_obj->get_rearray_request_types();

     my $rearray_types= $rearray_obj->get_rearray_request_status_list();

     my $employees= $rearray_obj->get_rearray_request_employee_list();

     my $target_plate_id= $rearray_obj->reassign_target_plate(-request_request => request_id);

     my $updated_wells= $rearray_obj->update_rearray_well_map( -rearray_request=>1234,
                                                               -target_wells => ['A01','A02'],
                                                               -source_wells => ['G02','F02']
                                                               -source_plates => ['5000','5001']
                                                             );
     my $updated_wells= $rearray_obj->apply_rearrays( 
                                                    -rearray_requests=>[1,2,3],
                                                    );
=cut

our @ISA = qw(SDB::DB_Object);
use strict;
###########################################################

#########
sub new {
#########
    my $this  = shift;
    my $class = ref $this || $this;
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $self  = {};
     
    $self->{dbc}       = $dbc;
    $self->{event_log} = ();
    #$self->{success}   = 0;
	$self = $this->SDB::DB_Object::new(-dbc=>$dbc,-tables=>"ReArray");
    bless $self, $class;

    return $self;
}

# Generates a rearray request
#
# Example:
#
# <snip>
#     my ($rearray_request_id, $target_plate_id)  = $rearray_obj->create_rearray(-request_type => $request_type,
#                                                                                -source_plates => ['5000','5000'],
#                                                                                -source_wells => ['A01','A02'],
#                                                                                -target_wells => ['P23','P24']);
#
# </snip>
# Returns: ($rearray_request_id, $target_plate_id)
####################
sub create_rearray {
####################
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $request_type     = $args{-request_type};        # Type of rearray
    my $employee         = $args{-employee};            #
    my $rearray_comments = $args{-rearray_comments};    #
    my $source_plates    = $args{-source_plates};       # Arrayref of source plates
    my $source_wells     = $args{-source_wells};        # Arrayref of source wells
    my $target_wells     = $args{-target_wells};        # Arrayref of target wells
    
    my $target_plate_id = $args{-target_plate_id};      # Optional target plate
    my $create_plate    = $args{-create_plate};         # Optional to create a new plate
    my $request_status  = $args{-request_status} || "Ready for Application";       # Optional

    my $dbc = $self->{dbc};
    
    my $source_plate_list = Cast_List(-list=>$source_plates, -to=>'string');
    
    ## deterimine common sample_type ##
    my @sample_types = $dbc->Table_find('Plate','FK_Sample_Type__ID',"WHERE Plate_ID IN ($source_plate_list)", -distinct=>1);

    my $sample_type_id;
    if (int(@sample_types) == 1) { $sample_type_id = $sample_types[0] }
    else { ($sample_type_id) = $dbc->Table_find('Sample_Type','Sample_Type_ID',"WHERE Sample_Type = 'Mixed'") }
    $args{-sample_type_id} = $sample_type_id;
     
    $self->{dbc}->start_trans('create_rearray');
	
    ## Create target plate or add to existing plate
	unless ($target_plate_id) {
		## NOTE: since the ReArray records have not been created at this point, the Plate attributes are not inherited.
    	$target_plate_id = $self->_create_target_plate(%args);
	}
    	 
	$request_status = $self->get_rearray_request_status(-status_name=>$request_status);
	
    ## Create rearray_request
    my $rearray_request_id = $self->_create_rearray_request(
        -target_plate_id  => $target_plate_id,
        -employee         => $employee,
        -request_status   => $request_status,
        -request_type     => $request_type,
        -rearray_comments => $rearray_comments,
    );
    ## Create rearray
    my @rearray_ids = $self->_create_rearray(
        -source_plates   => $source_plates,
        -source_wells    => $source_wells,
        -target_wells    => $target_wells,
        -rearray_request => $rearray_request_id
    );

	## NOTE: inherit Plate attributes after the ReArray records are created
	alDente::Container::batch_inherit_attributes( -dbc => $self->{dbc}, -id => $target_plate_id );
	
    ## create Source and Library_Source records if not there for manual rearray
    if( $request_type eq 'Manual Rearray' ) {
	my ($target_library_name) = $self->{dbc}->Table_find('Plate','FK_Library__Name',"WHERE Plate_ID = $target_plate_id");
	my ( $target_original_source_id ) = $self->{dbc}->Table_find('Library','FK_Original_Source__ID',"WHERE Library_Name = '$target_library_name'");
	my @library_sources =  $self->{dbc}->Table_find('Library_Source','FK_Source__ID',"WHERE FK_Library__Name = '$target_library_name'", -distinct => 1 );
	if( ! @library_sources ) {
		my $source_count = @$source_plates; 
		my @sources;
		for( my $i=0; $i<$source_count; $i++ ) {
			my $source_plate = $source_plates->[$i];
			my $source_well = $source_wells->[$i];
			my( $source_id ) = $self->{dbc}->Table_find(
				-table	=> 'Plate,Plate_Sample,Sample',
				-fields	=> 'FK_Source__ID',
				-condition	=> "WHERE Plate_ID = $source_plate and Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID and Well = '$source_well' and FK_Sample__ID = Sample_ID",
				-distinct	=> 1,
			);
			push @sources, $source_id if( $source_id );
		}
		my $source_obj = alDente::Source->new( -dbc => $self->{dbc} );
		my $new_sources = $source_obj->create_source( -dbc => $self->{dbc}, -from_sources => \@sources, -target_original_source_id => $target_original_source_id );
		if( $new_sources ) {
			## insert Library_Source record
			foreach my $new_source_id ( @$new_sources ) {
	        	$self->{dbc}->Table_append( "Library_Source", 'FK_Source__ID,FK_Library__Name', "$new_source_id,$target_library_name", -autoquote => 1 );
			}
		}
	}
    }
    
    $self->{dbc}->finish_trans( 'create_rearray', -error => $@ );

    return ( $rearray_request_id, $target_plate_id );
}

# Set the status for a rearray
#
# Example:
# <snip>
#     $rearray_obj->set_rearray_status(-status=>'Completed');
# </snip>
# Returns:
#########################
sub set_rearray_status {
#########################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $status = $args{-status};
    $self->{rearray_status} = $status;
    return;
}

# Get the status for a rearray
#
# Example:
# <snip>
#     my $status = $rearray_obj->get_rearray_status();
# </snip>
# Returns: rearray status
########################
sub get_rearray_status {
########################
    my $self = shift;
    return $self->{rearray_status};
}

# Get available rearray types
#
# Example:
# <snip>
#     my $rearray_types= $rearray_obj->get_rearray_request_types();
# </snip>
# Returns: arrayref of rearray request types
###############################
sub get_rearray_request_types {
###############################
    my $self                  = shift;
    my @rearray_request_types = ();
    @rearray_request_types = $self->{dbc}->get_enum_list( 'ReArray_Request', 'ReArray_Type' );
    return \@rearray_request_types;
}

# Get available rearray request statuses
#
# Example:
# <snip>
#     my $rearray_types= $rearray_obj->get_rearray_request_status_list();
# </snip>
# Returns: arrayref of rearray request statuses
#####################################
sub get_rearray_request_status_list {
#####################################
    my $self = shift;

    my @rearray_request_status_lists = ();
    @rearray_request_status_lists = $self->{dbc}->Table_find( 'Status', 'Status_Name', "WHERE Status_Type = 'ReArray_Request'" );
    return \@rearray_request_status_lists;
}

sub get_rearray_request_status {
	my $self = shift;
	my %args = filter_input(\@_,-mandatory=>"status_name");
	my $status_name = $args{-status_name};
	my ($request_status_id) = $self->{dbc}->Table_find( 'Status', 'Status_ID', "WHERE Status_Type = 'ReArray_Request' and Status_Name = '$status_name'" );
	return $request_status_id;
}

# Get employees that have requested rearrays
#
# Example:
# <snip>
#     my $employees= $rearray_obj->get_rearray_request_employee_list();
# </snip>
# Returns: arrayref of employees
#######################################
sub get_rearray_request_employee_list {
#######################################
    my $self      = shift;
    my @employees = ();
    @employees = $self->{dbc}->Table_find( 'ReArray_Request', 'FK_Employee__ID', "WHERE 1", -distinct => 1 );
    return \@employees;
}

# Helper function to create a rearray request item
#
# Example:
# <snip>
#     my $request_id= $rearray_obj->_create_rearray_request();
# </snip>
# Returns: $rearray_request_id
#############################
sub _create_rearray_request {
#############################
    my $self             = shift;
    my %args             = filter_input( \@_, -args => 'employee_id,target_plate,request_type,rearray_comments,status_id' );
    my $employee_id      = $args{-employee};                                                                                   # Employee ID of person who requested the rearray
    my $target_plate     = $args{-target_plate_id};                                                                               # Target Plate ID
    my $request_type     = $args{-request_type};                                                                               # Type of ReArray Request
    my $rearray_comments = $args{-rearray_comments};                                                                           # Comments
    my $request_status   = $args{-request_status};                                                                             # Status ID of the rearray
    my @fields = ( 'FK_Employee__ID', 'FKTarget_Plate__ID', 'ReArray_Type','Request_DateTime', 'ReArray_Comments', 'FK_Status__ID' );

    my @values = ( $employee_id, $target_plate, $request_type, &date_time(), $rearray_comments, $request_status );

    my $rearray_request_id = $self->{dbc}->Table_append_array( 'ReArray_Request', \@fields, \@values, -autoquote => 1 );

    return $rearray_request_id;
}

# Helper function to create a rearray records
#
# Example:
# <snip>
#     my $request_id= $rearray_obj->_create_rearray();
# </snip>
# Returns: \@rearray_ids
#####################
sub _create_rearray {
#####################
    my $self            = shift;
    my %args            = filter_input( \@_, -args => 'rearray_request,source_plates,source_wells,target_wells' );
    my $rearray_request = $args{-rearray_request};                                                                   # ReArray Request ID
    my $source_plates   = $args{-source_plates};                                                                     # Arrayref of Source Plate IDs
    my $source_wells    = $args{-source_wells};                                                                      # Arrayref of Source Wells
    my $target_wells    = $args{-target_wells};                                                                      # Arrayref of Target Wells

    my @fields = ( 'FK_ReArray_Request__ID', 'FKSource_Plate__ID', 'Source_Well', 'Target_Well' );

    my %rearray_values;
    my $index = 1;
    foreach my $source_plate ( @{$source_plates} ) {
        $rearray_values{$index} = [ $rearray_request, $source_plate, format_well($source_wells->[$index-1]), format_well($target_wells->[$index-1]) ];
        $index++;
    }
    my @rearray_ids = $self->{dbc}->smart_append( -tables => "ReArray", -fields => \@fields, -values => \%rearray_values, -autoquote => 1 );
    return \@rearray_ids;
}

# Helper function to create a target plate
#
# Example:
# <snip>
#     my $target_plate_id= $rearray_obj->_create_target_plate();
# </snip>
# Returns: $target_plate_id
##########################
sub _create_target_plate {
##########################
    ## Use Container method
    my $self = shift;
	my %args = @_;

	my $dbc = $self->{dbc};
	my $status = $args{-status};
	my $source_plates_ref = $args{-source_plates};
	my $target_wells_ref = $args{-target_wells};
	my $target_library = $args{-target_library};
	my $plate_rack = $args{-target_rack};
	my $emp_id = $args{-employee};
	my $plate_format_id = $args{-plate_format};
	my $plate_application = $args{-plate_application};
	my $target_format = $args{-target_size};
	my $plate_class = $args{-plate_class};
	my $plate_comments = $args{-plate_comments};
	my $plate_type = $args{-plate_type} || 'Library_Plate';
	my $sample_type_id= $args{-sample_type_id};
	my $plate_status = $args{-plate_status} || 'Active';
	########### END ASSIGNMENTS #####################################
	my $datetime = $args{-datetime} || &date_time();
	my $plate_position = $args{-plate_position} || '';
	my $parent_quadrant = $args{-parent_quadrant} || '';
   	my $parent_plate = $args{-parent_plate} || 0;
   	my $pipeline_id = $args{-pipeline};
        my $plate_label = $args{-plate_label};

	# if the rearray status is on order or pre-rearrayed, the plate status is 'Reserved'
	if (($status eq 'Waiting for Preps')||($status eq 'Waiting for Primers')||($status eq 'Ready for Application')) {
		$status = 'Reserved';
	}
	if ($plate_status){
		## override status if plate status is passed in
		$status = $plate_status;
	}

	# create plate
	my @source_plates = ();
	my @target_wells = ();
	@source_plates = @{$source_plates_ref} if ($source_plates_ref);
	@target_wells = @{$target_wells_ref} if ($target_wells_ref);

	# if target_library is not specified, check the parent plate and see what library it has.
	# if plates are from multiple libraries, then return an error.
	if ( (!($target_library)) && (scalar(@source_plates) < 1) ) {
		$target_library = ' ';
	}
	elsif (!($target_library)) {
		# get unique source plates
		# algorithm from Perl Cookbook pp. 102
		my %seen = ();
		my @unique_plates = grep { ! $seen{$_} ++ } @source_plates;
		# check plates and get their library.
		my $plates = join "','",@unique_plates;
		$plates = "'$plates'";
		my @libraries = $dbc->Table_find('Plate','distinct FK_Library__Name',"where Plate_ID IN ($plates)");
		if (@libraries."" > 1) {
			$self->error("Missing Parameter: Target_Library Not Specified");
		}
		else {
			$target_library = $libraries[0];
		}
	}

	# more error checking
	unless ($plate_format_id) {
		my @plate_format_array = $dbc->Table_find('Plate_Format','Plate_Format_ID',"where Plate_Format_Type like '%To Be Determined%'");
		$plate_format_id = $plate_format_array[0];
	}
	#    unless ($plate_application) { $self->error("Missing Parameter: Plate Application Not Specified"); }
	unless ( $plate_class || ($plate_class =~ /^ReArray$|^Standard$|^Oligo$/) ) {
		$self->error("Incorrect or missing plate class: has to be one of ReArray, Standard, or Oligo");
	}

	# Error checking done, return if there are errors
	if ($self->error()) {
		$self->success(0);
		return 0;
	}

	# use SDB::Temp->smart_append
	#$Connection ||= $self->{connection} || new SDB::DBIO(-dbc=>$dbc);

	# add information to values array
	# Plate ID auto assigned
	# plate size from target wells
	my $plate_size;
	if ($target_format == 96) {
		$plate_size = "'96-well'";
	}
	elsif ($target_format == 384) {
		$plate_size = "'384-well'";
	}
    elsif ($target_format) {
	$plate_size = $target_format;
    }
	else {
		$self->error("ERROR: Incorrect Parameter: Invalid number of target wells, has to be 1, 96, or 384");
		$self->success(0);
		return 0;
	}

	# Sub_Quadrants are derived from target_wells
	# only applicable to 384 well plates
	my $sub_quadrants = '';
	if ( $plate_size !~ /96/ ) {
		$sub_quadrants = $self->_get_subquadrants(-wells=>\@target_wells);
	}

	my %input;
	$input{library} = $target_library;
	$input{plate_size} = $plate_size;
	$input{rack_id} = $plate_rack || 1;
	$input{employee} = $emp_id;
	$input{plate_format_id} = $plate_format_id;
	$input{plate_status} = $status;
	$input{plate_type} = $plate_type;
	$input{plate_application} = $plate_application;
	$input{plate_class} = $plate_class;
	$input{plate_position} = $plate_position;
	$input{plate_test_status} = 'Production';
	$input{parent_plate_id} = 0;
	$input{quadrants_available} = $sub_quadrants;
	$input{parent_quadrant} = $parent_quadrant;
	$input{plate_comments} = $plate_comments;

	$input{pipeline_id} = $pipeline_id;
        $input{sample_type_id} = $sample_type_id;
        $input{plate_label} = $plate_label;
    
    my $container = "alDente::$plate_type";
    eval "require $container";
    my $lpo = $container->new(-dbc=>$dbc);

        #my $lpo = new alDente::Library_Plate(-dbc=>$dbc);
	my $newid = $lpo->add_Plate(-input=>\%input,-add_samples=>0,-quiet=>1,-dbc=>$dbc);
	
	unless ($newid) {
		$self->error("Database Error: Inserting new plate into database");
		$self->success(0);
		return 0;
	}
	$self->success(1);
	return $newid;	
}

# Helper function to parse a rearray request from a csv file
#
# Example:
# <snip>
#     my %rearray_info= $rearray_obj->parse_rearray_from_file();
# </snip>
# Returns: %rearray_info
sub _parse_rearray_from_file {
    my %rearray_info;
    my $self = shift;
    ## Use parse_csv method

    return \%rearray_info;
}

############################################################
# Function: determines which quadrants in a 384 well plate are filled
# RETURN: A comma-delimited string containing the quadrants that have wells filled
############################################################
sub _get_subquadrants {
#########################
    my $self = shift;
    my %args = @_;
    my @target_wells = @{$args{-wells}};
    my $dbc = $self->{dbc};
    # get the mapping (384-well => quadrant) from the database
    my %mapping = $self->{dbc}->Table_retrieve("Well_Lookup",['Plate_384','Quadrant']);
    my %well_map;
    my $index = 0;
    foreach my $well (@{$mapping{'Plate_384'}}) {
    $mapping{'Plate_384'}[$index] = &format_well($well);
    $well_map{&format_well($mapping{'Plate_384'}[$index])} = $mapping{'Quadrant'}[$index];
    $index++;
    }
    # go through each well and plug into a hash.
    my %quadrants;
    foreach my $target_well (@target_wells) {
    if ($well_map{&format_well($target_well)}) {
        $quadrants{$well_map{&format_well($target_well)}} = $target_well;
    }
    }
    # get the quadrants
    my @quad_list = keys %quadrants;
    my $quadrant_string = join ',',@quad_list;
    return "'".$quadrant_string."'";
}


# Reassign a plate for a rearray
#
# Example:
# <snip>
#     my $target_plate_id= $rearray_obj->reassign_target_plate();
# </snip>
# Returns: $target_plate_id
sub reassign_target_plate {
    my $self = shift;
    my $target_plate_id;

    ## Delete/Fail the old plate?

    ## Create a new plate and associate it to the rearray request

    return $target_plate_id;
}





########################################
sub generate_span8_csv {
########################################
	my $self = shift;
    my %args = @_;
	my $dbc = $self->{dbc} || $args{-dbc};
	my $request_id_ref = $args{-request_id};
	my @request_id = @$request_id_ref;

	my %dest_map;
	$dest_map{0} = "A";
	$dest_map{1} = "B";
	$dest_map{2} = "C";
	$dest_map{3} = "D";
	
	
	#print HTML_Dump \%dest_map;


	#Message("Model id: @request_id");
	my $request_id_list = Cast_List( -list => \@request_id, -to => 'String', -autoquote => 1 );
	#Message ("$request_id_list");
	
	##############
	# Note: The left join on Plate_Tray is here in the case of different plate types.
	# 		A plate(LIMS) refers to a collection of containers containing the same library
	#		A plate for this case can be tray with all 96 wells containing the same Library
	#		OR a subset of wells within a Tray that contain the same library
	#		If the latter case is true, we want the tray ID as we are interested in the unique 96-well containers 
	#		which needs to be identified for the biomek span-8 robot. 
	
	
	my %info = $dbc->Table_retrieve( "	Library, 
										Original_Source, 
										Plate as Child, 
										Plate as Parent LEFT JOIN Plate_Tray ON Plate_Tray.FK_Plate__ID = Parent.Plate_ID,
										ReArray, 
										ReArray_Request		", 
										['Parent.FK_Library__Name as a', 
										'CASE
										WHEN Plate_Tray.FK_Tray__ID is not Null 
										THEN 
										Plate_Tray.FK_Tray__ID
										ELSE 
										Parent.Plate_ID
										END as src_plate_ID',
										'Source_Well as SourceWell', 
										'Child.FK_Library__Name as b',
										'Original_Source_Name as c',
										'Target_Well as DestWell',
										'FKTarget_Plate__ID as Dest',
										'ReArray_Comments as d',		
										'Parent.Plate_Size as Src_Size',
										'Child.Plate_Size as Dest_Size',
										'Plate_Tray.FK_Tray__ID as src_tray_ID'								], 										
										"WHERE FK_ReArray_Request__ID = ReArray_Request_ID and 
										Parent.FK_Library__Name = Library_Name and 
										Library.FK_Original_Source__ID = Original_Source_ID and 
										Parent.Plate_ID = FKSource_Plate__ID and 
										FKTarget_Plate__ID = Child.Plate_ID and 
										ReArray_Request_ID in ($request_id_list)", -debug => 0
									);

	################################################################
	##
	## Format the Source Name to Src#_AB1000 format
	## Placed in if statement so I can reuse temp variables later.
	################################################################
	if(1){
		my $index = 0;
		my %temp;
		foreach my $id (@{$info{src_plate_ID}}){
			my $int = scalar keys(%temp);
			
			unless ($temp{$id}){
				$temp{$id}=$int+1;
			}
			my $plate_string = $id. "_$temp{$id}";
			$info{src_plate_ID}->[$index] = $plate_string;
			$index++;
		}
	}
	################################################################
	## Format Volume
	################################################################
	
	my @arr;
	foreach (@{$info{a}}){
		push @arr, 4;		
	}
	$info{Volume}	= \@arr;


	#################################################################
	##  Check and Format Dest Name
	##  Placed in if statement so I can reuse temp variables later.
	#################################################################
	my @tmp = @{$info{Dest}} if $info{Dest};
	$info{Dest_plate_id} = \@tmp;
	
	if(1){
		my $index = 0;
		my %temp;
		my %size;
		
		foreach my $type (@{$info{Dest_Size}}){
			$size{$type} = 1;
		}
		my $num_keys = scalar keys %size;
		unless($size{"1-well"} && $num_keys == 1){
			Message("WARNING: All Destinations expected to be tubes ( or 1-well plates), one or multiple dest is not a tube");
		}
		
		
		
		foreach my $id (@{$info{Dest}}){
			my $int = scalar keys(%temp);			
			unless ($temp{$id}){
			$temp{$id} = $int;
			}
			
		
			my $rac_num = (int $temp{$id} / 24) + 1;
			my $plate_string = "TubeRac" . $rac_num;
			$info{Dest}->[$index] = $plate_string;
			$info{Physical_Tube_Rac}->[$index] = "Rac_#".$rac_num;
			$index++;
		}
	}
	#$info{Dest_unique} = $info{Dest};

	##################################################################
	## Check and Format DestWell
	##################################################################
	
	
		if(1){
		
			my $index = 0;
			my %temp;

			foreach my $id (@{$info{Dest_plate_id}}){
				my $int = scalar keys(%temp);
				
				unless ($temp{$id}){
				$temp{$id}=$int+1;
				}
				my $char_key = int 	(($temp{$id} - 1)%24  / 6 );
				my $char_let = $dest_map{$char_key};
				my $num = (($temp{$id} - 1) % 6)+1;
				$info{DestWell}->[$index] = $char_let . $num;
				$index++;
			}
			
		}

	#################################################################
	## Format SourceWells, from A02 to A2
	#################################################################
	my $index = 0;
	foreach my $well (@{$info{SourceWell}}){
		
		$well =~ /(\D)(.*)/;
		my $newwell = $1. int $2;
		$info{SourceWell}->[$index] = $newwell;
		$index++;
	}

	#################################################################
	## Sort and Cut, Current format only allows 2 Dest racs, 4 scr plates max
	#################################################################	
	my $num_src = 0;
	my $num_dest = 0;
	my $MAX_SRC = 4;
	my $MAX_DEST = 2;
	my %src;
	my %dest;
	my %output;
	
	my $set = 1;
	my $size = 0;
	my $hash_size = scalar @{$info{DestWell}};
	
	while ($size < $hash_size){

		#Message ("size: $size HASH: $hash_size");
		$src{"$info{src_plate_ID}->[$size]"} = 1;	
		$dest{"$info{Dest}->[$size]"} = 1;	
		$num_src	= scalar keys %src;
		$num_dest	= scalar keys %dest;
		
		
		
		##slice and reset if limit reacted
		if( $num_src > $MAX_SRC || $num_dest > $MAX_DEST){
			#Message ("At CAP");	
			$set++;
			 for (keys %src)
   			 {
       		 	delete $src{$_};
    		 }	
    		 for (keys %dest)
   			 {
       		 	delete $dest{$_};
    		 }
		}
	
		foreach my $key (keys %info){
			#Message ("$key");
			push @{$output{$set}->{$key}}, $info{$key}->[$size];				
		}
		$size++;

	
	}
	 
	#################################################################
	## End of Sort and Cut, begin renaming per csv
	#################################################################		
	
	foreach my $key (keys %output){
	
		if(1){
			my @source;
			my %temp;	
			foreach my $id (@{$output{$key}->{src_plate_ID}}){
				my $int = scalar keys(%temp);
				
				unless ($temp{$id}){
				$temp{$id}=$int+1;
				}
				my $plate_string = "Src" . "$temp{$id}" . "_Axygen96-PCR-FS";
				push @source, $plate_string;
			}
			$output{$key}->{Source} = \@source;
		}

	}

		foreach my $key (keys %output){
	
		if(1){
			my @Dest;
			my %temp;	
			foreach my $id (@{$output{$key}->{Dest}}){
				my $int = scalar keys(%temp);
				
				unless ($temp{$id}){
				$temp{$id}=$int+1;
				}
				my $Dest_String = "TubeRac" . "$temp{$id}";
				push @Dest, $Dest_String;
			}
			$output{$key}->{Dest} = \@Dest;
		}

	}
	
	

							
	return \%output; 									
}


###########################################
sub generate_span8_instructions {
###########################################	
	my $self = shift;
    my %args = @_;
    my %info = %{$args{-info}};

	my	$set = 1; 
	my %instructions;
	my @worksheet1;
	my %well_map;
	
	while ($info{$set}){
		my $index = 0;
		my %SRC_placement;
		my %DEST_placement;
			
		foreach my $src_plate_ID (@{$info{$set}->{src_plate_ID}}){
			my $Physical_Tube_Rac = $info{$set}->{Physical_Tube_Rac}[$index];
			
			unless ($instructions{$set}->{$src_plate_ID}){			
				push @{$SRC_placement{id}}, $src_plate_ID;
				push @{$SRC_placement{pos}}, $info{$set}->{Source}[$index];			
				$instructions{$set}->{$src_plate_ID} = 1;
			}
			unless ($instructions{$set}->{$Physical_Tube_Rac}){			
				push @{$DEST_placement{id}}, $Physical_Tube_Rac;
				push @{$DEST_placement{pos}}, $info{$set}->{Dest}[$index];			
				$instructions{$set}->{$Physical_Tube_Rac} = 1;
			}
			my $destwell = $info{$set}->{DestWell}[$index];
			my $rac = $info{$set}->{Physical_Tube_Rac}[$index];
			unless($well_map{$rac}->{$destwell}){		
				$well_map{$rac}->{$destwell} = $info{$set}->{Dest_plate_id}[$index];
			}
						
		 	$index++;
		}
		

		push @worksheet1, ["SET $set"];

		push @worksheet1, ["SOURCE_TRAY_ID","SOURCE_TRAY_POS"];
		my $j = 0;
		foreach my $id (@{$SRC_placement{id}}){
			my $pos = $SRC_placement{pos}->[$j];

			push @worksheet1, [$id, $pos];
			$j++;
		}

		push @worksheet1, ["DEST_PHYSICAL_RAC_#","DEST_RAC_POS"];
		
		$j = 0;
		foreach my $id (@{$DEST_placement{id}}){
			my $pos = $DEST_placement{pos}->[$j];

			push @worksheet1, [$id, $pos];
			$j++;
		}
		
		push @worksheet1, [""];

	$set++;
	}
	
	################################################################
	## Begin Generating well map
	#################################################################	

	my %L_map = (A => '1', B => '2', C => '3', D => '4');

	my $timestamp = timestamp();
	my $filename 	= "$URL_temp_dir/$timestamp\span-8_Instructions.xlsx";
	my $linkname 	= "$Configs{URL_domain}/dynamic/tmp/$timestamp\span-8_Instructions.xlsx";

	require SDB::Excel;
	my $workbook 	= SDB::Excel::load_Writer($filename);
	my $worksheet1 = $workbook->add_worksheet("Instructions"); 
	
	$worksheet1->write_col(0, 0, \@worksheet1 );
	$worksheet1->set_column('A:B', 25); 
	
	my $worksheet2 = $workbook->add_worksheet("Well Map"); 
		 
	$set = 1;
		
	my @racs = keys %well_map;
	@racs = sort @racs;
		
		
	my $offset = 0;
	foreach my $rac (@racs){
		
		$worksheet2->write_row($offset, 0, ["$rac","1","2","3","4","5","6"] );
		$worksheet2->write_col($offset+1,0, ["A","B","C","D"] );
			

		foreach my $pos (keys %{$well_map{$rac}}){
			
			my $hash_key = $pos;
			my $letter = substr($pos, 0, 1, "");
			my $num = $pos;
				

				
				
			my $row = $L_map{$letter} + $offset;
			my $col = $num;
							
			$worksheet2->write($row,$col,$well_map{$rac}->{$hash_key})
			}		
		
		$set++;
		$offset += 6;
	}
		
		

	$workbook->close();

	return $linkname;
}






#########################################
# Function: updates/appends to the plate_sample table based on rearray information
# return: 1 if successful, 0 if not
#########################################
sub update_plate_sample_from_rearray {
    my $self = shift;
    my %args = @_;
    my $rearray_id = $args{-request_id};
    my $pool       = $args{-pool};
    my $auto_check = $args{-auto_check};
    my $dbc = $self->{dbc};

    # get target plate
    my ($info) = $dbc->Table_find("ReArray_Request,Plate","FKTarget_Plate__ID, FK_Library__Name, ReArray_Type","WHERE FKTarget_Plate__ID = Plate_ID AND ReArray_Request_ID=$rearray_id");
    my ($target_plate,$target_library,$rearray_request_type) = split(",", $info);

    # get all source wells and target wells for that plate
    my %rearray_info = $dbc->Table_retrieve("ReArray,ReArray_Request",["Source_Well","Target_Well","FKSource_Plate__ID"],"WHERE FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID=$target_plate");
    
    if ($auto_check) {
	if ($rearray_request_type eq 'Pool Rearray') {
	    return $self->create_pool_sample(
					     -dbc                  => $dbc,
					     -library              => $target_library,
					     -target_plate         => $target_plate,
					     -source_plates        => $rearray_info{FKSource_Plate__ID},
					     -rearray_request      => $rearray_id,
					     -rearray_source_wells => $rearray_info{Source_Well},
					     -rearray_target_wells => $rearray_info{Target_Well}
					     );
	}
    }


    ### delete all Plate_Samples related to this request
    # remove Plate_Sample with that Original Plate
    # for speed
    if (!$pool) { $dbc->query(-query=>"DELETE FROM Plate_Sample WHERE FKOriginal_Plate__ID=$target_plate"); }
    
    #my %well_lookup;  
    #my %well_384_to_96;
    #my %well_96_to_384;
    #my $i = 0;
    
    #%well_lookup = $dbc->Table_retrieve("Well_Lookup",['Quadrant','Plate_96','Plate_384'],'order by Quadrant,Plate_96');
    #foreach my $well (@{$well_lookup{'Plate_96'}}) {
    #$well_lookup{'Plate_384'}[$i] = &format_well($well_lookup{'Plate_384'}[$i]);
    #$well_96_to_384{uc($well_lookup{'Plate_96'}[$i].$well_lookup{'Quadrant'}[$i])} = $well_lookup{'Plate_384'}[$i];
    #$well_384_to_96{$well_lookup{'Plate_384'}[$i]} = uc($well_lookup{'Plate_96'}[$i]).$well_lookup{'Quadrant'}[$i];
    #$i++;
    #}
    #my %well_info;
    #$well_info{'96_to_384'} = \%well_96_to_384;
    #$well_info{'384_to_96'} = \%well_384_to_96;


    my $samples = alDente::Container::get_sample_id(-dbc=>$dbc,-plate_ids=>$rearray_info{FKSource_Plate__ID}, -wells=>$rearray_info{Source_Well});

    my @insert_fields = ('FKOriginal_Plate__ID','FK_Sample__ID','Well');
    my %sample_insert;
    my $counter = 1;
    my $index   = 1;
    my %tplate_twell_lookup;
    
    while (exists $rearray_info{FKSource_Plate__ID}[$counter-1]) {
    my $source_well = $rearray_info{Source_Well}[$counter-1];
    my $target_well = $rearray_info{Target_Well}[$counter-1];
    my $source_plate = $rearray_info{FKSource_Plate__ID}[$counter-1];
    #my %ancestry = &alDente::Container::get_Parents(-dbc=>$dbc,-id=>$source_plate,-well=>$source_well,-well_lookup=>\%well_info,-simple=>1);
    my $sample_id = $samples->{$source_plate}{$source_well};# = $ancestry{sample_id};

        if (!$tplate_twell_lookup{"$target_plate:$target_well"}){
            $sample_insert{$index} = [$target_plate,$sample_id,$target_well];
            $tplate_twell_lookup{"$target_plate:$target_well"} = 1;
            $index++;
        }
        if ($pool) {
	    $dbc->Table_update('ReArray','FK_Sample__ID',$sample_id,"WHERE Source_Well = '$source_well' AND FKSource_Plate__ID = '$source_plate' AND FK_ReArray_Request__ID = '$rearray_id'", -skip_validation=>1, -no_triggers=>1);
	}
        $counter++;
    }
    if (!$pool) {
	# do an insert into Plate_Sample
	$dbc->smart_append(-tables=>'Plate_Sample',-fields=>\@insert_fields,-values=>\%sample_insert,-autoquote=>1);
	# do an update from Plate_Sample to ReArray
	# NEED TO ADAPT TABLE_UPDATE TO SUPPORT MULTIPLE TABLES
	$dbc->query(-query=>"UPDATE Plate_Sample,ReArray,ReArray_Request SET ReArray.FK_Sample__ID=Plate_Sample.FK_Sample__ID WHERE FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID=FKOriginal_Plate__ID AND Target_Well=Well AND FKTarget_Plate__ID=$target_plate");
    }
    return 1;
}


# Update the well mapping for a rearray
#
# Example:
# <snip>
#     my $updated_wells= $rearray_obj->update_rearray_well_map( -rearray_request=>1224,
#                                                               -target_plate => 52021,
#                                                               -target_wells => ['A01','A02'],
#                                                               -source_wells => ['G02','F02']
#                                                               -source_plates => ['5000','5001']
#                                                             );
# </snip>
# Returns: number of wells updated
sub update_rearray_well_map {
    my $self                    = shift;
    my %args                    = filter_input( \@_, -args => "rearray_request,target_plate,target_wells,source_wells,source_plates" );
    my $rearray_request         = $args{-rearray_request};                                                                                # Rearray request id
    my $target_plate            = $args{-target_plate};                                                                                   # Target plate id
    my $target_wells            = $args{-target_wells};                                                                                   # Arrayref of target wells
    my $source_wells            = $args{-source_wells};                                                                                   # Arrayref of source wells
    my $source_plates           = $args{-source_plates};                                                                                  # Arrayref of source plates
    my $number_of_wells_updated = 0;

    my $target_wells = Cast_List( -list => $target_wells, -to => 'String', -autoquote => 1 );
    my $index = 0;

    my @rearray_ids = $self->{dbc}->Table_find(
        "ReArray,ReArray_Request", "ReArray_ID",
        "WHERE FK_ReArray_Request__ID = ReArray_Request_ID and 
                                                ReArray_Request_ID = $rearray_request and 
                                                Target_Well IN ($target_wells) and FKTarget_Plate__ID = $target_plate",
        -autoquote => 1
    );

    my $index = 0;
    foreach my $rearray_id (@rearray_ids) {
        my $updated = $self->{dbc}->Table_update_array( "ReArray", [ 'FKSource_Plate__ID', 'Source_Well' ], [ $source_plates->[$index], $source_wells->[$index] ], "WHERE ReArray_ID = $rearray_id", -autoquote => 1 );
        if ($updated) {
            $number_of_wells_updated++;
        }
        $index++;
    }

    ## Set unused wells
    my $rearray_wells = join ',', $self->{dbc}->Table_find( 'ReArray, ReArray_Request', 'Target_Well', "where FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID = $target_plate" );
    #my ($target_plate_size) = $self->{dbc}->Table_find( 'ReArray, ReArray_Request', 'ReArray_Format_Size', "where FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID = $target_plate" );
    my ($target_plate_size) = $self->{dbc}->Table_find('ReArray, ReArray_Request, Plate','Plate_Size',"where FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID = $target_plate AND FKtarget_Plate__ID = Plate_ID");
    my $unused = join ',', &alDente::Library_Plate::not_wells( $rearray_wells, $target_plate_size );
    alDente::Library_Plate::set_unused_wells( -unused_wells => $unused, -dbc => $self->{dbc},-plate=>$target_plate );

    return $number_of_wells_updated;
}


#####################################################################################
# Apply the target plate information for a given rearray request rearray
#
# Example:
# <snip>
#     my $updated_wells= $rearray_obj->apply_rearrays(
#                                                     -rearray_requests=>[1,2,3],
#
#                                                    );
# </snip>
# Returns: number of rearray requests applied
#######################################################################################
sub apply_rearrays {
#######################################################################################    
    my $self             = shift;
    my %args             = filter_input( \@_, -args => 'request_ids' );

	my $request_ids = $args{-request_ids};
    # parse out parameters 
    my $plate_size = $args{-size};
    my $plate_format = $args{-format};
    my $rack = $args{-rack}; 
    my $status = $args{-status} || 'Active';
    my $application = $args{-application} || 'Sequencing';
    my $quadrant= $args{-quadrant};
    my $library = $args{-library};
    my $created = $args{-created_date} || &date_time();
    my $pipeline = $args{-pipeline};
	my $dbc = $self->{dbc};

    my $attribute = 'printer_group_id';
    my $cgi_app = new alDente::CGI_App( PARAMS => { dbc => $dbc } );
    $cgi_app->update_session_info();
    if ( !defined $dbc->session->param($attribute) ) {
	return $cgi_app->prompt_for_session_info($attribute);
    }

	my $num_applied;

	my @request_array = Cast_List(-list=>$request_ids,-to=>'Array');

	foreach my $request (@request_array) {
		my @retval = $dbc->Table_find("ReArray_Request,Plate,Status","distinct Plate_Size,FK_Library__Name,ReArray_Type,Status_Name as ReArray_Status","WHERE FK_Status__ID=Status_ID AND FKTarget_Plate__ID=Plate_ID AND ReArray_Request_ID in ($request)");
		if (scalar(@retval) > 1) {
			Message("Cannot apply rearrays from different libraries, sizes, types, or status");
			return;
		}
	}

	# grab the ids
	$plate_format = $dbc->get_FK_ID("FK_Plate_Format__ID",$plate_format);
	$rack = $dbc->get_FK_ID("FK_Rack__ID",$rack);

	foreach my $request (@request_array) {
		Message("Applying Rearray");
		my ($rearray_status) = $dbc->Table_find("ReArray_Request,Status","Status_Name as ReArray_Status","WHERE FK_Status__ID=Status_ID AND ReArray_Request_ID=$request");
		my $plate;
		# for reserved plate ids
		if ($rearray_status=~/Waiting for Primers|Waiting for Preps|Ready for Application/i) {
			my @plate_array = $dbc->Table_find('ReArray_Request','FKTarget_Plate__ID',"where ReArray_Request_ID=$request");
			$plate = $plate_array[0];
		}  
		# if not reserved, create the blank plate
		else {
			#$plate = $self->create_rearray_plate(-size=>$plate_size,-format=>$plate_format,-rack=>$rack,-quadrant=>$quadrant,-created=>$created,-library=>$library,-format=>$plate_format,-pipeline=>$pipeline);
		}
		if ($plate=~/,/) {$dbc->warning("multiple plates identified");}
		else {
			if ($rearray_status=~/Ready for Application/i) {
				my $datetime = &date_time();

				my $ok2 =$dbc->Table_update_array('Plate',['Plate_Status','Plate_Created','FK_Plate_Format__ID','FK_Rack__ID','FK_Pipeline__ID'],['Active',$datetime,$plate_format,$rack,$pipeline],"WHERE Plate_ID = $plate",-autoquote=>1);

				# return error if there is a problem
				if ($ok2) {
					my @plate_info = $dbc->Table_find('Plate','FK_Library__Name,Plate_Number',"WHERE Plate_ID=$plate");
					my ($library,$plate_num) = split ',',$plate_info[0];

					Message("Activated Pla$plate: $library $plate_num ($datetime)");
					print &Link_To($dbc->homelink()," (edit details)","&Search=1&Table=Plate&Search+List=$plate",$Settings{LINK_COLOUR},['newwin2']);  
					&alDente::Barcoding::PrintBarcode($dbc,'Plate',$plate);
				}
				else {
					Message("Error: Cannot update Plate table: Plate $plate not updated");
				}
			}
			else {
				my $new_status = "Barcoded";
				
				Message "Warning: This action is not allowed.  You cannot change an applied rearray at this point";
				return;
				### This commented out for now till reassign is written.
				
				Message("Copying requests: $request");		
				my ($new_ids,$copy_time) = $self->reassign(-requests=>$request,-plate=>$plate);
				# change $request for later (assigning plate samples)
				$request = $new_ids;
				if ($new_ids) {
					Message("Re-Assigning Previous Request to ($new_ids) - $copy_time");
				}
				else {
					Message("Problem updating new ReArray records");
				}
			}	
			# change status of Plate and Rearray
			auto_assign(-dbc=>$self->{dbc},-plate=>$plate,-requested=>$request);
			$self->update_plate_sample_from_rearray(-request_id=>$request);	
		}
	}
    return $num_applied;
}
sub auto_assign {
    my %args = &filter_input(\@_,-args=>'dbc,plate,requested');
    use SDB::HTML;
    my $dbc = $args{-dbc} ;
    my $plate = $args{-plate};
    my $requested = $args{-requested};

    #$plate = get_aldente_id($dbc,$plate,'Plate');
    my ($status_id) = $dbc->Table_find("Status","Status_ID","WHERE Status_Name = 'Barcoded'");
    my $ok = $dbc->Table_update_array('ReArray_Request',['FK_Status__ID','FKTarget_Plate__ID'],[$status_id,$plate],"where ReArray_Request_ID in ($requested)",-debug=>1);

    my $wells = join ',', $dbc->Table_find('ReArray, ReArray_Request','Target_Well',"where FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID = $plate");
    #my ($size) = $dbc->Table_find('ReArray, ReArray_Request','ReArray_Format_Size',"where FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID = $plate");
    my ($size) = $dbc->Table_find('ReArray, ReArray_Request, Plate','Plate_Size',"where FK_ReArray_Request__ID=ReArray_Request_ID AND FKTarget_Plate__ID = $plate AND FKtarget_Plate__ID = Plate_ID");
    my $unused = join ',',&alDente::Library_Plate::not_wells($wells,$size);
        if ($wells && ($wells ne 'NULL')) {
    my $ok =$dbc->Table_update_array('Library_Plate',['Unused_Wells'],["'$unused'"],"where FK_Plate__ID = $plate");

    if ($ok) {
    
    }
    else {
        Message("No Wells set to 'Unused' (may already be set)");
        }
    }
    else {Message("No used Wells found...(target = $plate)");}
    
    

    if ($ok) {
        ### send email to who requested the rearray
        my @emails = $dbc->Table_find_array('Employee,ReArray_Request',['Email_Address'],"where ReArray_Request_ID in ($requested) AND FK_Employee__ID=Employee_ID");
        foreach my $email (@emails) {
            # &alDente::Notification::Email_Notification($email,'seqdb01@bcgsc.bc.ca','LIMS Rearray Notification',"Rearray Request Number $requested has been Assigned to plate $plate");
        }
    }
    else {
        Message("No Requested Wells updated: " . Get_DBI_Error());
    }

    foreach my $name (param()) {
        if ($name=~/Replace $requested:(\d+)/) {
            my $search = $1;
            (my $replace) = param($name);
            if ($search eq $replace) {next;}
            Message("$name: replace $search with $replace");
            ######### UPDATE ###############
            my $ok =$dbc->Table_update('ReArray','FKSource_Plate__ID',$replace,"where FK_ReArray_Request__ID in ($requested) and FKSource_Plate__ID=$search");
        }
    }



    ######### Set quadrants if necessary   ####################
    my ($plate_size) = $dbc->Table_find("Plate","Plate_Size","WHERE Plate_ID = $plate");
    # if the plate size is 384, then check if the quadrants are set properly. If it is not, then reset it

    if ($plate_size =~ /384/) {
    my $nopad_wells = &autoquote_string(&format_well($wells,'nopad'));
    my @quads = $dbc->Table_find("Well_Lookup","distinct Quadrant","WHERE Plate_384 in ($nopad_wells)");
    my $quads = join ',', @quads;
        Message("Quadrants set to: $quads");
    $dbc->Table_update_array("Library_Plate",['Sub_Quadrants'],["$quads"],"WHERE FK_Plate__ID = $plate",-autoquote=>1);
    }
   
   # } 
############### Change plate info for Reserved Plates ####################
    if (param('Reserved Plate')) {
        my $today = &date_time();
        my $status = 'Active';
        my $ok =$dbc->Table_update_array('Plate',['Plate_Created','FK_Employee__ID','Plate_Status'],[$today,$dbc->get_local('user_id'),$status],"where Plate_ID = $plate",-autoquote=>1);
    }
    return 1;
}

sub complete_rearray {
    my $self = shift;
	my %args = filter_input(\@_);
	my $dbc = $self->{dbc};
	my $rearray_requests = $args{-rearray_requests};

    my $rearray_ids = Cast_List(-to=>'String',-list=>$rearray_requests);
    my ($status_id) = $dbc->Table_find( "Status", "Status_ID", "WHERE Status_Name like 'Completed'" );
   	$dbc->Table_update_array( "ReArray_Request", ['FK_Status__ID'], [$status_id], "WHERE ReArray_Request_ID in ($rearray_ids)" );
    Message("Completed Rearrays ($rearray_ids)");
	return;
}

sub abort_rearray {
    my $self = shift;
	my %args = filter_input(\@_);
	my $dbc = $self->{dbc};
	my $rearray_requests = $args{-rearray_requests};

 	my $rearray_ids = Cast_List(-to=>'String',-list=>$rearray_requests);
    my ($status_id) = $dbc->Table_find( "Status", "Status_ID", "WHERE Status_Name like 'Aborted'" );
    $dbc->Table_update_array( "ReArray_Request", ['FK_Status__ID'], [$status_id], "WHERE ReArray_Request_ID in ($rearray_ids)" );
    Message("Aborted Rearrays ($rearray_ids)");
	return;
}

###############################################################
# Subroutine: Creates a remapped primer plate for each rearray
# Return: none
###############################################################
sub remap_primer_plate_from_rearray {
    my $self              = shift;
    my %args              = @_;
    my $rearray_id        = $args{-rearray_id};
    my $primer_plate_name = $args{-primer_plate_name};
    my $notes             = $args{-notes};
    my $dbc               = $self->{dbc};

    my $datetime = &date_time();

    # grab target plate
    my ($target_plate_info) = $self->{dbc}->Table_find( "ReArray_Request,Plate_Format,Plate", "FKTarget_Plate__ID,Plate_Size", "WHERE ReArray_Request_ID=$rearray_id and FKTarget_Plate__ID = Plate_ID and Plate_Format_ID = FK_Plate_Format__ID" );

    my ( $target_plate, $plate_size ) = split ',', $target_plate_info;

    # grab Plate_PrimerPlateWell information

    my %info
        = $dbc->Table_retrieve( "Plate_PrimerPlateWell,Primer_Plate_Well", [ "FK_Primer__Name", "Plate_Well", "Primer_Plate_Well_ID", "Plate_PrimerPlateWell_ID" ], "WHERE FK_Plate__ID=$target_plate AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID" );

    # create new Primer_Plate
    # create new Primer_Plate_Well

    my %quad;

    my $po = new alDente::Primer( -dbc => $dbc );

    # get the organization ID
    my ($organization_id) = $self->{dbc}->Table_find( "Organization", "Organization_ID", "WHERE Organization_Name = 'GSC'" );
    my @target_wells;
    if ( $plate_size =~ /384/ ) {
        my $index = 0;
        while ( defined $info{FK_Primer__Name}[$index] ) {
            my $target_well = $info{Plate_Well}[$index];
            push( @target_wells, $target_well );
            my $primer_name                = $info{FK_Primer__Name}[$index];
            my $primer_plate_well_id       = $info{Primer_Plate_Well_ID}[$index];
            my $plate_primer_plate_well_id = $info{Plate_PrimerPlateWell_ID}[$index];
            $target_well = format_well( $target_well, 'nopad' );
            my ($well_info) = $self->{dbc}->Table_find( 'Well_Lookup', 'Quadrant,Plate_96', "WHERE Plate_384 = '$target_well'" );
            my ( $quad, $new_target_well ) = split ',', $well_info;
            push( @{ $quad{$quad}{FK_Primer__Name} },          $primer_name );
            push( @{ $quad{$quad}{Plate_Well} },               $new_target_well );
            push( @{ $quad{$quad}{Primer_Plate_Well_ID} },     $primer_plate_well_id );
            push( @{ $quad{$quad}{Plate_PrimerPlateWell_ID} }, $plate_primer_plate_well_id );
            $index++;
        }

    }
    else {
        $quad{''} = \%info;
    }

    $self->{dbc}->query( -query => "DELETE FROM Plate_PrimerPlateWell WHERE FK_Plate__ID=$target_plate" );

    my $index = 0;
    foreach my $key ( sort keys %quad ) {
        my $ref                         = $quad{$key}{'FK_Primer__Name'};
        my @primer_names                = @{$ref};
        my @primer_wells                = @{ $quad{$key}{'Plate_Well'} };
        my @parent_primer_platewell_ids = @{ $quad{$key}{'Primer_Plate_Well_ID'} };
        my $quadrant                    = uc($key);
        my $new_primer_plate_name       = "$primer_plate_name" . "_" . "$quadrant";
        my ( $primer_plate_id, $newids_ref ) = $po->create_primer_plate(
            -primer_plate_name          => $new_primer_plate_name,
            -primer_names               => \@primer_names,
            -order_date                 => $datetime,
            -status                     => 'Received',
            -primer_wells               => \@primer_wells,
            -parent_primerplatewell_ids => \@parent_primer_platewell_ids,
            -organization_id            => $organization_id,
            -source                     => 'Made in House',
            -notes                      => $notes,
            -omit_primers               => 1
        );

        my ($new_sol_id) = $self->{dbc}->Table_find( "Primer_Plate", "FK_Solution__ID", "WHERE Primer_Plate_ID=$primer_plate_id" );
        ## print barcode
        &alDente::Barcoding::PrintBarcode( $dbc, 'Solution', "$new_sol_id" );

        # delete previous Plate_PrimerPlateWell information

        # recreate new Plate_PrimerPlateWell information
        my %new_primerplate = $dbc->Table_retrieve( "Primer_Plate_Well", [ 'Primer_Plate_Well_ID', 'Well' ], "WHERE FK_Primer_Plate__ID=$primer_plate_id" );
        my %insert;
        my $counter = 1;
        while ( exists $new_primerplate{'Primer_Plate_Well_ID'}[ $counter - 1 ] ) {
            my $target_well;
            if ( $plate_size =~ /384/ ) {
                ($target_well) = $self->{dbc}->Table_find( 'Well_Lookup', 'Plate_384', "WHERE Quadrant = '$key' and Plate_96 = '$new_primerplate{'Well'}[$counter-1]'" );
                $target_well = format_well( $target_well, 'pad' );
            }
            else {
                $target_well = $new_primerplate{'Well'}[ $counter - 1 ];
            }
            $insert{$counter} = [ $target_plate, $new_primerplate{'Primer_Plate_Well_ID'}[ $counter - 1 ], $target_well ];
            $counter++;
            $index++;
        }
        $self->{dbc}->smart_append( -tables => 'Plate_PrimerPlateWell', -fields => [ 'FK_Plate__ID', 'FK_Primer_Plate_Well__ID', 'Plate_Well' ], -values => \%insert, -autoquote => 1 );

    }

    return;

}

#############################
# function to place rearrays into a lab_request
#############################
sub add_to_lab_request {
    my $self           = shift;
    my %args           = @_;
    my $dbc            = $self->{dbc};    ## SDB::DBIO->new(-dbh=>$dbh,-connect=>0);
    my $request_ids    = $args{-request_ids};            # (ArrayRef) reference to an array of request ids to group
    my $employee_id    = $args{-employee_id};            # (Scalar) id of the employee adding the lab request
    my $lab_request_id = $args{-lab_request_id};         # (Scalar) id of the lab request to add to. If not defined, a new lab request will be created

    unless ($request_ids) {
        Message("ERROR: Missing parameter: No rearrays to add to lab request");
    }
    my $ids = Cast_List(-list=>$request_ids,-to=>'String');

    unless ($lab_request_id) {

        # insert into Lab_Request table
        my $datetime = &date_time();
        $dbc->smart_append( -tables => "Lab_Request", -fields => [ 'FK_Employee__ID', 'Request_Date' ], -values => [ "$employee_id", "$datetime" ], -autoquote => 1 );
        $lab_request_id = $dbc->newids( 'Lab_Request', 0 );
    }

    if ( $lab_request_id && ( $lab_request_id =~ /\d+/ ) ) {

        # add requests
        $self->{dbc}->Table_update_array( "ReArray_Request", ["FK_Lab_Request__ID"], ["$lab_request_id"], "WHERE ReArray_Request_ID in ($ids)" );
        Message("Added Rearrays ($ids) to lab request $lab_request_id");
    }
}


#################################
sub confirm_qpix_log_rearray {
#################################
    my $self = shift;
    my %args = filter_input(\@_);
    my $dbc = $self->{dbc};
    my $target_plate = $args{-target_plate};
    my $source_plates = $args{-source_plates};
    my $source_wells = $args{-source_wells};
    my $target_wells = $args{-target_wells};
    my $logfiles = $args{-logfiles};
    my $rearray_date_time = &date_time();
    my @source_plates = Cast_List(-list=>$source_plates, -to=>'Array');
    my @source_wells = Cast_List(-list=>$source_wells,-to=>'Array');
    my @target_wells = Cast_List(-list=>$target_wells,-to=>'Array');
    my @logfiles = Cast_List(-list=>$logfiles,-to=>'Array');    

    my $rearray_comments = "Extraction from qpix source plates";
    my $type = "Extraction ReArray";
    my $status = 'Completed';
    my ($target_size) = $dbc->Table_find( 'Plate', 'Plate_Size', "WHERE Plate_ID = $target_plate");
    ## Set the plate status to active
    my $ok = $dbc->Table_update_array( 'Plate', ['Plate_Status'], ['Active'], "WHERE Plate_ID = $target_plate",-autoquote=>1);

	### Create the rearray records for the extraction
    my $rearray_request;

	( $rearray_request, $target_plate ) = $self->create_rearray(
        -source_plates       => \@source_plates,
        -source_wells        => \@source_wells,
        -target_wells        => \@target_wells,
        -target_plate_id     => $target_plate,
        -employee            => $dbc->get_local('user_id'),
        -request_type        => $type,
        -status              => $status,
        -target_size         => $target_size,
        -rearray_comments    => $rearray_comments,
        -plate_status        => 'Active',
        -create_plate => 0
    );
	my $Sample = alDente::Sample::create_samples( -dbc => $dbc, -plate_id => $target_plate,-from_rearray_request=>$rearray_request, -type =>'Clone');
    auto_assign(-dbc=>$dbc, -plate=>$target_plate,-requested=>$rearray_request);
    Message("ReArray_Request: $rearray_request completed");

    #my $sample_info = $self->create_sample(-request_id=>$rearray_request,-sample_type=>'Clone');
    ### move the log files 
    foreach my $log (@logfiles){
	(my $dir, my $logname) = &Resolve_Path($log);
	$logname =~s/ /\\ /g;
	my $feedback = try_system_command("cp $dir/$logname $dir/archive/$logname; chmod 777 $dir/archive/$logname");
    }		    

    return;# @target_log_files;


}

sub write_to_rearray_log {

}

##### Start Utilitiy functions for that used by multiprobe #####

# Get info about a rearray
#
# Example:
# <snip>
# my $info = $rearray_obj->get_rearray_info(-id=>$rearray_id, -type=>'DNA');
# my ( $plate_id, $lib_name, $platenum ) = split ',', $info;
# </snip>
# Returns: a string of rearray info delimited by ,
##### End Utilitiy functions for that used by multiprobe #####
sub get_rearray_info {
    my $self       = shift;
    my $dbc        = $self->{dbc};
    my %args       = &filter_input( \@_, -args => 'id,type', -mandatory => 'id,type' );
    my $rearray_id = $args{-id};
    my $type       = $args{-type};
    if ( $type eq 'DNA' ) {
        my @find_array = $dbc->Table_find( 'Plate,ReArray_Request', 'Plate_ID,FK_Library__Name,Plate_Number', "WHERE ReArray_Request_ID in ($rearray_id) AND FKTarget_Plate__ID=Plate_ID" );
        return $find_array[0];
    }
    elsif ( $type eq 'Primer' ) {
        my @find_array = $dbc->Table_find(
            'Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate,ReArray_Request,Plate',
            'distinct FK_Solution__ID,FK_Library__Name,Plate_Number',
            "WHERE ReArray_Request_ID in ($rearray_id) AND FKTarget_Plate__ID=Plate_ID AND FK_Plate__ID=Plate_ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND Primer_Plate_ID=FK_Primer_Plate__ID"
        );
        return $find_array[0];
    }
    elsif ( $type eq 'QPIX' ) {
        my @find_array = $dbc->Table_find( 'Plate,ReArray_Request,Library,Project', 'Project_Name,Project_Path,Library_Name',
            "WHERE ReArray_Request_ID in ($rearray_id) AND FKTarget_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID" );
        return $find_array[0];
    }
    elsif ( $type eq 'Target' ) {
        my @target_info = $dbc->Table_find( 'ReArray_Request,Plate', 'FKTarget_Plate__ID,FK_Library__Name,Plate_Number', "where FKTarget_Plate__ID=Plate_ID AND ReArray_Request_ID in ($rearray_id) order by ReArray_Request_ID" );
        return \@target_info;
    }
    return '';
}

# Check to see if a primer plate can remap
#
# Example:
# <snip>
# my $can_remap = $rearray_obj->can_remap(-id=>$rearray_id);
# </snip>
# Returns: 1 if can remap, 0 if cannot remap
sub can_remap {
    my $self       = shift;
    my $dbc        = $self->{dbc};
    my %args       = &filter_input( \@_, -args => 'id', -mandatory => 'id' );
    my $rearray_id = $args{-id};
    my $can_remap  = 0;

    my %well_info = $dbc->Table_retrieve(
        "ReArray,ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well",
        [ "Target_Well", "Well as Primer_Well" ],
        "WHERE ReArray_Request_ID=$rearray_id AND FK_ReArray_Request__ID=ReArray_Request_ID AND (FKTarget_Plate__ID=FK_Plate__ID AND Plate_Well=Target_Well) AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID"
    );
    my $counter = 0;
    while ( exists $well_info{"Target_Well"}[$counter] ) {
        if ( $well_info{"Target_Well"}[$counter] ne $well_info{"Primer_Well"}[$counter] ) {
            $can_remap = 1;
            last;
        }
        $counter++;
    }

    return $can_remap;
}

# Check to see if target and source well of a rearray are same size
#
# Example:
# <snip>
# $rearray_obj->compare_size(-id=>$rearray_id);
# </snip>
# Returns: Session warning messages
sub compare_size {
    my $self       = shift;
    my $dbc        = $self->{dbc};
    my %args       = &filter_input( \@_, -args => 'id', -mandatory => 'id' );
    my $rearray_id = $args{-id};

    my @target_rearray_sizes = $dbc->Table_find( "ReArray_Request,Plate,Plate_Format", "Wells", "WHERE ReArray_Request_ID in ($rearray_id) AND FKTarget_Plate__ID=Plate_ID AND FK_Plate_Format__ID=Plate_Format_ID", 'distinct' );

    my @source_rearray_sizes = $dbc->Table_find( "ReArray,Plate,Plate_Format", "Wells", "WHERE FK_ReArray_Request__ID in ($rearray_id) AND FKSource_Plate__ID=Plate_ID AND FK_Plate_Format__ID=Plate_Format_ID", 'distinct' );
    if ( ( scalar(@target_rearray_sizes) != 1 ) && ( $target_rearray_sizes[0] ne '96' ) ) {
        $dbc->warning("Target plate is not 96-well") if ($dbc);
    }
    if ( ( scalar(@source_rearray_sizes) != 1 ) && ( $source_rearray_sizes[0] ne '96' ) ) {
        $dbc->warning("One or more source plates is not 96-well") if ($dbc);
    }
}
############################################################
# Assigns new source plates for a rearray
# RETURN: 1 if successful, 0 otherwise
############################################################
sub assign_source_plates {
    my $self                              = shift;
    my $dbc                               = $self->{dbc};
    my %args                              = @_;
    my $rearray_id                        = $args{-rearray_id};
    my $targetwell_to_sourceplate_hashref = $args{-targetwell_to_sourceplate_hash};
    my %platehash                         = %{$targetwell_to_sourceplate_hashref};

    # do error check on source_plates - see if they exist
    foreach my $well ( keys %platehash ) {
        if ( $platehash{$well} !~ /\d+/ ) {
            Message("invalid source plate $platehash{$well}...");
            return 0;
        }
        my ($plate) = $self->{dbc}->Table_find( "Plate", "count(Plate_ID)", "WHERE Plate_ID=$platehash{$well}" );
        if ( $plate == 0 ) {
            Message("plate $platehash{$well} does not exist...");
            return 0;
        }
    }

    # get target plate
    my ($target_plate) = $self->{dbc}->Table_find( "ReArray_Request", "FKTarget_Plate__ID", "WHERE ReArray_Request_ID=$rearray_id" );

    # get information about the rearray from database
    my %rearray_info = $dbc->Table_retrieve( "ReArray", [ "Target_Well", "FKSource_Plate__ID" ], "WHERE FK_ReArray_Request__ID=$rearray_id" );

    # reformat the %rearray_info hash into a hash keyed by Target_Well (Assume Target_Well is unique)
    my $count        = 0;
    my @target_wells = @{ $rearray_info{"Target_Well"} };
    my %wells_to_source;
    foreach my $row (@target_wells) {
        $wells_to_source{$row} = $rearray_info{"FKSource_Plate__ID"}[$count];
        $count++;
    }

    foreach my $well ( keys %platehash ) {

        # assign new source plates
        # if it is the same, skip
        if ( ( defined $wells_to_source{$well} ) && ( $wells_to_source{$well} == $platehash{$well} ) ) {
            next;
        }
        else {
            my $ok = $self->{dbc}->Table_update_array( "ReArray", ["FKSource_Plate__ID"], [ $platehash{$well} ], "WHERE FK_ReArray_Request__ID=$rearray_id AND Target_Well='$well'" );
            unless ($ok) {
                Message("No updates done to rearray, error updating...");
                return 0;
            }
            $wells_to_source{$well} = $platehash{$well};
        }
    }
    return 1;
}

# Get plate size of a rearray
#
# Example:
# <snip>
# my $plate_size = $rearray_obj->get_plate_size(-id=>$rearray_id);
# </snip>
# Returns: Session warning messages
sub get_plate_size {
    my $self       = shift;
    my $dbc        = $self->{dbc};
    my %args       = &filter_input( \@_, -args => 'id', -mandatory => 'id' );
    my $rearray_id = $args{-id};

    my ($plate_size) = $dbc->Table_find( "ReArray_Request,Plate_Format,Plate", "Plate_Size", "WHERE ReArray_Request_ID IN ($rearray_id) and FKTarget_Plate__ID = Plate_ID and Plate_Format_ID = FK_Plate_Format__ID" );
    return $plate_size;
}

###############################################################
# Subroutine: Generates an ordered array representing information needed for a multiprobe file (based on a rearray)
# RETURN: an array, with each line representing a multiprobe line
###############################################################
sub generate_rearray_primer_multiprobe {
###############################################################
    my %args = &filter_input( \@_, -args => 'rearray_id,default_sol_id' );

    my $rearray_id     = $args{-rearray_id};             # (Scalar) rearray id for this primer multiprobe
    my $new_sol_id     = $args{-default_sol_id} || 1;    # (Scalar) placeholder solution id (if a sol id has not yet been defined)
    my $dbc            = $args{-dbc};                    # (ObjectRef) Database handle
    my $split_quadrant = 1;

    # first, look to see if the Primer_Plate applied (through Plate_PrimerPlateWell) is Made in House (if there is only one)
    # if it isn't - just pull off the information from Plate_PrimerPlateWell and ask the user if he/she
    #               wants to create a new Primer_Plate with the new mapping
    # if it is    - use the parent Primer_Plate information instead of the information in Plate_PrimerPlateWell
    #               Ask the user if he/she wants to re-create a new Primer_Plate

    # flag that determined whether the Primer_Plates can be remapped
    my $new_plate = 0;

    # grab primer plate/s

    my @primer_plate_ids
        = $dbc->Table_find( "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well", "distinct FK_Primer_Plate__ID", "WHERE FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND ReArray_Request_ID=$rearray_id" );

    # more than 1 source primer plate - definitive indication that it can be remapped
    my ($plate_size) = $dbc->Table_find( "ReArray_Request,Plate_Format,Plate", "Plate_Size", "WHERE ReArray_Request_ID=$rearray_id and FKTarget_Plate__ID = Plate_ID and Plate_Format_ID = FK_Plate_Format__ID" );
    my $order_by = "right(Plate_Well,2),left(Plate_Well,1)";
    my $extra_condition;
    my $rearray_tables = "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well as Child,Primer_Plate_Well as Parent,Primer_Plate as Parent_Plate,Primer_Plate as Child_Plate";
    my $rearray_fields = "Parent_Plate.FK_Solution__ID,Child_Plate.FK_Solution__ID,Parent.Well,Plate_Well,Parent.FK_Primer__Name";

    if ( $plate_size =~ /384/i ) {
        $new_plate = 1;
        if ($split_quadrant) {
            $rearray_tables  .= ",Well_Lookup";
            $extra_condition .= "AND Plate_Well = CASE WHEN (Length(Plate_384)=2) THEN ucase(concat(left(Plate_384,1),'0',Right(Plate_384,1))) ELSE Plate_384 END";
            $order_by = "Quadrant," . $order_by;
        }
    }
    elsif ( scalar(@primer_plate_ids) > 1 ) {
        $new_plate = 0;
    }
    else {

        # check to see if the primer plate has the same mapping as Plate_PrimerPlateWell
        # if it is, then it has been mapped already
        my @well_match = $dbc->Table_find( "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well", "Plate_Well,Well", "WHERE FKTarget_Plate__ID=FK_Plate__ID AND FK_Primer_Plate_Well__ID=Primer_Plate_Well_ID AND ReArray_Request_ID=$rearray_id" );
        foreach (@well_match) {
            my ( $plate_well, $primer_well ) = split ',', $_;
            if ( $plate_well ne $primer_well ) {
                $new_plate = 0;
                last;
            }
            else {

                # if it passed this test, then they are the same
                $new_plate = 1;
            }
        }
    }
    my @result_array = ();

    # already created a new Primer_Plate. Display its parents' information
    if ( $new_plate == 1 ) {
        @result_array = $dbc->Table_find( "$rearray_tables", "$rearray_fields",
            "WHERE ReArray_Request_ID=$rearray_id AND FKTarget_Plate__ID=FK_Plate__ID AND Child.Primer_Plate_Well_ID=FK_Primer_Plate_Well__ID AND Child.FK_Primer_Plate__ID=Child_Plate.Primer_Plate_ID AND Child.FKParent_Primer_Plate_Well__ID=Parent.Primer_Plate_Well_ID AND Parent.FK_Primer_Plate__ID=Parent_Plate.Primer_Plate_ID $extra_condition ORDER BY $order_by"
        );
    }
    else {

        # did not create a new Primer_Plate. Display
        @result_array = $dbc->Table_find(
            "ReArray_Request,Plate_PrimerPlateWell,Primer_Plate_Well,Primer_Plate",
            "FK_Solution__ID,'$new_sol_id',Well,Plate_Well,FK_Primer__Name",
            "WHERE ReArray_Request_ID=$rearray_id AND FKTarget_Plate__ID=FK_Plate__ID AND Primer_Plate_Well_ID=FK_Primer_Plate_Well__ID AND FK_Primer_Plate__ID=Primer_Plate_ID ORDER BY right(Plate_Well,2),left(Plate_Well,1)"
        );
    }

    my @remap_array = ();
    foreach my $info (@result_array) {
        my ( $source, $target, $source_well, $target_well, $primer_name ) = split ',', $info;

        # zero-pad the SOL ID for target and source
        $source = sprintf( "SOL%010d", $source );
        $target = sprintf( "SOL%010d", $target );
        push( @remap_array, "$source,$target,$source_well,$target_well,$primer_name" );
    }

    return \@remap_array;
}

###############################################################
# Subroutine: Assigns no grows to the target plate, depending on the parent assignments
# RETURN: none
##############################################################
sub assign_grows_from_parents {
    my $self         = shift;
    my $dbc          = $self->{dbc};
    my %args         = @_;
    my $rearray_id   = $args{-request_id};
    my $target_plate = $args{-target_plate};

    # if request ID is given, get the target plate
    if ( !($target_plate) ) {
        ($target_plate) = $self->{dbc}->Table_find( "ReArray_Request", "FKTarget_Plate__ID", "WHERE ReArray_Request_ID=$rearray_id" );
    }

    # if target plate is given, get the request id
    elsif ( !($rearray_id) ) {
        ($rearray_id) = $self->{dbc}->Table_find( "ReArray_Request", "ReArray_Request_ID", "WHERE FKTarget_Plate__ID=$target_plate" );
    }

    # get the slow grows and no grows list
    my ($no_grows_str)   = $self->{dbc}->Table_find( "Library_Plate", "No_Grows",   "WHERE FK_Plate__ID=$target_plate" );
    my ($slow_grows_str) = $self->{dbc}->Table_find( "Library_Plate", "Slow_Grows", "WHERE FK_Plate__ID=$target_plate" );

    my @no_grows   = map { &format_well($_) } split ',', $no_grows_str;
    my @slow_grows = map { &format_well($_) } split ',', $slow_grows_str;

    # remove padding zeros
    foreach (@no_grows) {
        if ( $_ =~ /(\s)0(\d)/ ) {
            $_ = $1 . $2;
        }
    }
    foreach (@slow_grows) {
        if ( $_ =~ /(\s)0(\d)/ ) {
            $_ = $1 . $2;
        }
    }

    # grab all the source plates and wells, and the targets
    my @rearray_info = $self->{dbc}->Table_find( "ReArray", "FKSource_Plate__ID,Source_Well,Target_Well", "WHERE FK_ReArray_Request__ID=$rearray_id" );

    # parse out rearray information
    my %sourceplate_to_well_info;
    my %sourceplate_to_sourcewell;
    foreach (@rearray_info) {
        my ( $sourceplate, $sourcewell, $targetwell ) = split ',';

        # remove padding zeros
        if ( $sourcewell =~ /(\w)0(\d)/ ) {
            $sourcewell = $1 . $2;
        }
        if ( $targetwell =~ /(\w)0(\d)/ ) {
            $targetwell = $1 . $2;
        }
        if ( defined $sourceplate_to_well_info{$sourceplate} ) {
            push( @{ $sourceplate_to_well_info{$sourceplate}->{$sourcewell} }, $targetwell );
        }
        else {
            $sourceplate_to_well_info{$sourceplate}->{$sourcewell} = [$targetwell];
        }
        if ( defined $sourceplate_to_sourcewell{$sourceplate} ) {
            push( @{ $sourceplate_to_sourcewell{$sourceplate} }, $sourcewell );
        }
        else {
            $sourceplate_to_sourcewell{$sourceplate} = [$sourcewell];
        }
    }

    # check each source plate to see what no grows and slow grows are marked out. If the source wells coincide with no grows or slow grows,
    # mark out those in the target plate as well
    foreach my $source_plate ( keys %sourceplate_to_well_info ) {
        my @source_wells = @{ $sourceplate_to_sourcewell{$source_plate} };
        my ($source_no_grows_str)   = $self->{dbc}->Table_find( "Library_Plate", "No_Grows",   "WHERE FK_Plate__ID=$source_plate" );
        my ($source_slow_grows_str) = $self->{dbc}->Table_find( "Library_Plate", "Slow_Grows", "WHERE FK_Plate__ID=$source_plate" );
        my @source_no_grows   = split ',', $source_no_grows_str;
        my @source_slow_grows = split ',', $source_slow_grows_str;

        # remove padding zeros
        foreach (@source_no_grows) {
            if ( $_ =~ /(\s)0(\d)/ ) {
                $_ = $1 . $2;
            }
        }
        foreach (@source_slow_grows) {
            if ( $_ =~ /(\s)0(\d)/ ) {
                $_ = $1 . $2;
            }
        }
        foreach my $source_well (@source_wells) {
            if ( grep /$source_well/, @source_no_grows ) {
                push( @no_grows, @{ $sourceplate_to_well_info{$source_plate}->{$source_well} } );
            }
            if ( grep /$source_well/, @source_slow_grows ) {
                push( @slow_grows, @{ $sourceplate_to_well_info{$source_plate}->{$source_well} } );
            }
        }
    }

    # get all unique wells from no grows and slow grows
    @no_grows   = sort { $a <=> $b } @{ &unique_items( \@no_grows ) };
    @slow_grows = sort { $a <=> $b } @{ &unique_items( \@slow_grows ) };

    # insert into target plate
    if (@no_grows) {
        $self->{dbc}->Table_update_array( "Library_Plate", ["No_Grows"], [ "'" . join( ',', @no_grows ) . "'" ], "WHERE FK_Plate__ID=$target_plate" );
    }
    if (@slow_grows) {
        $self->{dbc}->Table_update_array( "Library_Plate", ["Slow_Grows"], [ "'" . join( ',', @slow_grows ) . "'" ], "WHERE FK_Plate__ID=$target_plate" );
    }
    return;
}

###############################################################
# Subroutine: Generates an ordered array representing information needed for a multiprobe file
# RETURN: an array, with each line representing a multiprobe line
###############################################################
sub generate_DNA_multiprobe {
###############################################################
    my %args       = &filter_input( \@_, -args => 'rearray_id' );
    my $rearray_id = $args{-rearray_id};                            # (Scalar) Rearray ID for this multiprobe
    my $dbc        = $args{-dbc};                                   # (ObjectRef) Database handle

    my @result_array = $dbc->Table_find(
        "ReArray,ReArray_Request,Library_Plate,Plate",
        "concat(FK_Library__Name,'-',Plate_Number,Plate.Parent_Quadrant,'_',Source_Well),FKSource_Plate__ID,FKTarget_Plate__ID,Source_Well,Target_Well",
        "WHERE ReArray_Request_ID=$rearray_id AND FK_ReArray_Request__ID=ReArray_Request_ID AND FKSource_Plate__ID=Plate_ID AND FK_Plate__ID=Plate_ID ORDER BY right(Target_Well,2),left(Target_Well,1) ASC"
    );
    my @rearray_array = ();
    foreach my $info (@result_array) {
        my ( $sample_name, $source, $target, $source_well, $target_well ) = split ',', $info;

        # zero-pad the PLA ID for target and source
        $source = sprintf( "PLA%010d", $source );
        $target = sprintf( "PLA%010d", $target );
        push( @rearray_array, "$source,$target,$source_well,$target_well,$sample_name" );
    }
    return \@rearray_array;
}

##### End Utilitiy functions for that used by multiprobe #####

##### Start Utilitiy functions for that used by QPIX #####

###############################################################
# Subroutine: Creates a qpix string given a hashref of information on all needed rearrays
#             Original-style QPIX file
# RETURN: a string representing the qpix file
###############################################################
sub _generate_qpix_source_only {
###############################################################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc,data_ref' );

    my $dbc         = $args{-dbc};         # (ObjectRef) Database handle
    my $data_ref    = $args{-data_ref};    # (Hashref) A Table_retrieve hash of FKSource_Plate__ID,FK_Library__Name,Plate_Number,Source_Well,Target_Well,Plate_Size, Wells, and Plate_Position
    my $qpix_string = "";

    # get mapping from 96-well to 384-well (in case it is necessary)
    my %well_lookup = $dbc->Table_retrieve( "Well_Lookup", [ 'Quadrant', 'Plate_96', 'Plate_384' ], 'order by Quadrant,Plate_96' );
    my %well_96_to_384;
    my $index = 0;
    foreach my $well ( @{ $well_lookup{'Plate_96'} } ) {
        $well_96_to_384{ uc( $well_lookup{'Plate_96'}[$index] ) . $well_lookup{'Quadrant'}[$index] } = $well_lookup{'Plate_384'}[$index];
        $index++;
    }

    my %rearray_info = %{$data_ref};

    # loop through %rearray_info and create a hash that maps {Source_Plates} => arrayref of plate names in the format
    # <LIBNAME><PLATENUMBER><WELL>,<TARGETWELL>
    my %sourceplate_hash;
    my %source_id_to_platename;
    $index = 0;
    my @Ordered_source_ids = ();
    my $total_clone_count  = 0;
    foreach my $source_id ( @{ $rearray_info{'FKSource_Plate__ID'} } ) {

        # add library name
        my $plate_name = $rearray_info{'FK_Library__Name'}[$index];

        # add plate number
        $plate_name .= $rearray_info{'Plate_Number'}[$index];
        $source_id_to_platename{$source_id} = $plate_name;

        # add source well
        if ( ( $rearray_info{'Plate_Size'}[$index] eq "96-well" ) && ( $rearray_info{'Wells'}[$index] eq '384' ) ) {
            my $quadrant = $rearray_info{"Plate_Position"}[$index];
            $plate_name .= &format_well( $well_96_to_384{ $rearray_info{'Source_Well'}[$index] . $quadrant } );
            my ($mul_id) = $dbc->Table_find( "Multiple_Barcode", "Multiple_Text", "WHERE Multiple_Text like '%pla$source_id%'" );
            $source_id = $mul_id;
        }
        else {
            $plate_name .= $rearray_info{'Source_Well'}[$index];
        }

        # add target well
        $plate_name .= $rearray_info{'Target_Well'}[$index];
        $index++;
        if ( defined $sourceplate_hash{"$source_id"} ) {
            push( @{ $sourceplate_hash{"$source_id"} }, "$plate_name" );
        }
        else {
            $sourceplate_hash{"$source_id"} = ["$plate_name"];

            # save the first instance of the source ID into an ordered array
            # to make it easy to retrieve the order (IMPORTANT!)
            push( @Ordered_source_ids, "$source_id" );
        }
        $total_clone_count++;
    }

    # process hash into the qpix string
    my $source_counter    = 0;
    my $clone_counter     = 0;
    my $total_plate_count = scalar(@Ordered_source_ids);
    foreach my $source_id (@Ordered_source_ids) {
        $source_counter++;
        $qpix_string .= "PLATE: $source_counter\n";
        if ( $source_id =~ /pla/i ) {
            $qpix_string .= "BARCODE: $source_id\n";
        }
        else {
            $qpix_string .= "BARCODE: pla$source_id\n";
        }

        # loop through all the names
        my @source_wells = ();
        my $well_counter = 0;
        foreach my $input_name ( @{ $sourceplate_hash{"$source_id"} } ) {
            my ( $well_name, $target_well ) = split ',', $input_name;
            $well_name =~ /(\S{5})(\S+)(\S{3})(\S{3})/;

            # $qpix_string .= "$well_name ";
            push( @source_wells, $3 );
            $well_counter++;
        }
        $clone_counter += $well_counter;
        $qpix_string .= "COMMENT: $source_id_to_platename{$source_id} SRC $source_counter\_$total_plate_count CLN $well_counter DONE $clone_counter\_$total_clone_count\n";

        # print the source wells in order
        foreach my $source_well (@source_wells) {
            $qpix_string .= "$source_well\n";
        }
    }

    return $qpix_string;
}

###############################################################
# Subroutine: Creates a qpix string given a hashref of information on all needed rearrays
#             New-style QPIX file
# RETURN: a string representing the qpix file
###############################################################
sub _generate_qpix_source_and_destination {
###############################################################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc,data_ref' );

    my $dbc      = $args{-dbc};         # (ObjectRef) Database handle
    my $data_ref = $args{-data_ref};    # (Hashref) A Table_retrieve hash of FKSource_Plate__ID,FK_Library__Name,Plate_Number,Source_Well,Target_Well,Plate_Size, Wells, and Plate_Position

    my $qpix_string = "";

    # get mapping from 96-well to 384-well (in case it is necessary)
    my %well_lookup = $dbc->Table_retrieve( "Well_Lookup", [ 'Quadrant', 'Plate_96', 'Plate_384' ], 'order by Quadrant,Plate_96' );
    my %well_96_to_384;
    my $index = 0;
    foreach my $well ( @{ $well_lookup{'Plate_96'} } ) {
        $well_96_to_384{ uc( $well_lookup{'Plate_96'}[$index] ) . $well_lookup{'Quadrant'}[$index] } = $well_lookup{'Plate_384'}[$index];
        $index++;
    }

    my %rearray_info = %{$data_ref};

    # loop through %rearray_info and create a hash for information on the qpix
    my %source_id_to_platename;
    $index = 0;
    my @Ordered_source_ids = ();
    my $total_clone_count  = 0;
    my %qpix_info;
    my %sourceplate_track;
    my %targetplate_track;

    foreach my $source_id ( @{ $rearray_info{'FKSource_Plate__ID'} } ) {

        # add library name
        my $plate_name = $rearray_info{'FK_Library__Name'}[$index];

        # add plate number
        $plate_name .= $rearray_info{'Plate_Number'}[$index];
        $source_id_to_platename{$source_id} = $plate_name;

        my $source_well = $rearray_info{'Source_Well'}[$index];

        # determine correct source_id and well (remap mul plates)
        if ( ( $rearray_info{"Plate_Size"}[$index] eq "96-well" ) && ( $rearray_info{'Wells'}[$index] eq '384' ) ) {
            my $quadrant = $rearray_info{"Plate_Position"}[$index];
            $source_well = &format_well( $well_96_to_384{ $source_well . $quadrant } );
            my ($mul_id) = $dbc->Table_find( "Multiple_Barcode", "Multiple_Text", "WHERE Multiple_Text like '%pla$source_id%'" );
            $source_id = $mul_id;
        }
        unless ( defined $sourceplate_track{"$source_id"} ) {

            # save the first instance of the source ID into an ordered array
            # to make it easy to retrieve the order
            push( @Ordered_source_ids, "$source_id" );
            $sourceplate_track{"$source_id"} = scalar(@Ordered_source_ids);
        }

        my $target_id   = $rearray_info{'FKTarget_Plate__ID'}[$index];
        my $target_well = $rearray_info{'Target_Well'}[$index];

        # define what number the target_plate is
        if ( defined $targetplate_track{"$target_id"} ) {
            $target_id = $targetplate_track{"$target_id"};
        }
        else {
            my $target_count = scalar( keys %targetplate_track );
            $target_count++;
            $targetplate_track{"$target_id"} = $target_count;
            $target_id = $targetplate_track{"$target_id"};
        }

        if ( defined $qpix_info{"$source_id"} ) {
            push( @{ $qpix_info{"$source_id"}{Rearray} }, "$source_well,$sourceplate_track{$source_id},$target_well,$target_id" );
        }
        else {
            $qpix_info{"$source_id"}{Rearray} = ["$source_well,$sourceplate_track{$source_id},$target_well,$target_id"];
        }
        $index++;
        $total_clone_count++;
    }

    #HTML_Dump(\%qpix_info);
    # process hash into the qpix string
    my $source_counter    = 0;
    my $clone_counter     = 0;
    my $total_plate_count = scalar(@Ordered_source_ids);

    # dump all the source definitions
    foreach my $source_id (@Ordered_source_ids) {
        $source_counter++;
        $qpix_string .= "PLATE: $source_counter\n";
        if ( $source_id =~ /pla/i ) {
            $qpix_string .= "BARCODE: $source_id\n";
        }
        else {
            $qpix_string .= "BARCODE: pla$source_id\n";
        }
        my $well_count = scalar( @{ $qpix_info{$source_id}{Rearray} } );
        $clone_counter += $well_count;
        $qpix_string .= "COMMENT: $source_id_to_platename{$source_id} SRC $source_counter\_$total_plate_count CLN $well_count DONE $clone_counter\_$total_clone_count\n";
    }

    # dump all the sourcewell => targetwell definitions
    foreach my $source_id (@Ordered_source_ids) {
        foreach my $row ( @{ $qpix_info{"$source_id"}{Rearray} } ) {
            $qpix_string .= "$row\n";
        }
    }

    return $qpix_string;
}

###############################################################
# Subroutine: Function that generates a QPIX string
# RETURN: a string representing the qpix file
###############################################################
sub generate_qpix {
###############################################################
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => "dbc,rearray_ids,type,quadrant" );
    my $rearray_ids = $args{-rearray_ids};                                              # (Scalar) A comma-delimited list of rearray_ids to generate a qpix file for. It is generally recommended to use one at a time.
    my $dbc         = $args{-dbc};                                                      # (ObjectRef) Database handle
    my $type        = $args{-type} || 'Source Only';                                    # (Scalar) Type of QPIX file. One of 'Source Only' or 'Source and Destination'
    my $quadrant    = $args{-quadrant} || 0;                                            # (Scalar) [Optional] Quadrant specification

    my $plate_limit = $args{-plate_limit};

    # retrieve rearray information from the database
    unless ($rearray_ids) {
        Message("Specify rearray ids");
    }

    my $extra_condition = '';

    if ($quadrant) {
        $extra_condition = " AND Quadrant in ($quadrant) ";
    }

    my $condition
        = "where ReArray_Request_ID in ($rearray_ids) AND ReArray_Request_ID=FK_ReArray_Request__ID AND FKSource_Plate__ID=Plate_ID AND Plate_ID=FK_Plate__ID AND Plate_384=concat(Left(Target_Well,1),abs(Right(Target_Well,2))) AND FK_Plate_Format__ID=Plate_Format_ID $extra_condition order by ReArray_Request_ID,FKSource_Plate__ID,Quadrant,Plate_96";

    my %rearray_info = $dbc->Table_retrieve( 'Well_Lookup,ReArray_Request,ReArray,Plate,Plate_Format,Library_Plate',
        [ 'FKSource_Plate__ID', 'FK_Library__Name', 'Plate_Number', 'Source_Well', 'Target_Well', 'FKTarget_Plate__ID', 'Plate_Size', 'Wells', 'Library_Plate.Plate_Position' ], $condition );
    my %split_hash      = ();
    my @present_sources = ();
    my $index           = 0;
    my $split_index     = 1;

    while ( defined $rearray_info{FKSource_Plate__ID}[$index] ) {
        my $source = $rearray_info{FKSource_Plate__ID}[$index];
        if ( !( grep( /^$source$/, @present_sources ) ) ) {
            push( @present_sources, $source );
        }

        if ($plate_limit) {
            if ( int(@present_sources) > $plate_limit ) {

                @present_sources = ();
                $split_index++;
                next;
            }

        }
        foreach my $key ( keys %rearray_info ) {
            push( @{ $split_hash{$split_index}{$key} }, $rearray_info{$key}[$index] );
        }
        $index++;
    }

    my @qpix_str = ();
    foreach my $qpix_key ( sort { $a <=> $b } keys %split_hash) {
        my $qpix_str = '';
        if ( $type =~ /Source Only/ ) {

            # old-style QPIX file
            $qpix_str = $self->_generate_qpix_source_only( -dbc => $dbc, -data_ref => $split_hash{$qpix_key} );
            push( @qpix_str, $qpix_str );
        }
        elsif ( $type =~ /Source and Destination/ ) {

            # new style QPIX file

            $qpix_str = $self->_generate_qpix_source_and_destination( -dbc => $dbc, -data_ref => $split_hash{$qpix_key} );
            push( @qpix_str, $qpix_str );
        }
        else {
            $dbc->error("ERROR: Invalid Argument: Type should be one of 'Source Only' or 'Source and Destination'");
        }
    }

    return \@qpix_str;
}

###############################################################
# Subroutine: Function that generates a QPIX string
# RETURN: a string representing the qpix file
###############################################################
sub get_qpix_info {
###############################################################
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => "rearray_ids,quadrant" );
    my $rearray_ids = $args{-rearray_ids};
    my $quadrant    = $args{-quadrant};
    my $dbc         = $self->{dbc};

    my $extra_condition = '';

    if ($quadrant) {
        $extra_condition = " AND Quadrant in ($quadrant) ";
    }

    my %rearray_info = $dbc->Table_retrieve(
        'Well_Lookup,Equipment,Rack,ReArray_Request,ReArray,Plate,Plate_Format',
        [ 'Plate_ID', 'FK_Library__Name', 'Plate_Number', 'Equipment_Name', 'Rack_ID', 'Wells', 'Plate_Size', 'Wells' ],
        "where Equipment_ID=FK_Equipment__ID AND Rack_ID=FK_Rack__ID AND ReArray_Request_ID in ($rearray_ids) AND ReArray_Request_ID=FK_ReArray_Request__ID AND FKSource_Plate__ID=Plate_ID AND FK_Plate_Format__ID=Plate_Format_ID AND Plate_384=concat(Left(Target_Well,1),abs(Right(Target_Well,2))) $extra_condition order by ReArray_Request_ID,FKSource_Plate__ID,Quadrant,Plate_96"
    );
    return \%rearray_info;
}
##### End Utilitiy functions for that used by QPIX #####

##### PRIMER functionality

############################################################
# Function: determines if a scalar exists in an array of strings (pattern match)
# RETURN: 1 if found, 0 otherwise
############################################################
sub _like_in_array {
    my $array  = shift;    # array of strings
    my $scalar = shift;    # the scalar to search for in the array of strings
    foreach my $item ( @{$array} ) {
        if ( $item =~ /$scalar/ ) {
            return 1;
        }
    }
    return 0;
}
###############################################################
# Subroutine: confirms that the specified plates are the complete set of source plates
#             Displays an html prompt
# RETURN: none
###############################################################
sub validate_source_plates {
    my $self = shift;
    my %args = @_;
    my $rearray_ids = $args{-request_ids}; # (Scalar) A comma-delimited list of rearray ids to check
    my $plate_ids = $args{-source_plates}; # (Scalar) A comma-delimited list of source plates
   
    my $dbc = $self->{dbc};

    my @given_source_plates = split ',',$plate_ids;
    # grab all source plates specified by the rearrays
    my @correct_source_plates = $self->{dbc}->Table_find("ReArray","distinct FKSource_Plate__ID","WHERE FK_ReArray_Request__ID in ($rearray_ids)");
    Message("Scanned in ".int(@given_source_plates)." plates");
    # do a set difference (both ways) to find all plates not listed in the rearray ids 
    my @missing_plates = @{&set_difference(\@correct_source_plates,\@given_source_plates)};
    my @excess_plates = @{&set_difference(\@given_source_plates,\@correct_source_plates)};
    if (int(@missing_plates) > 0) {
	Message("ERROR: Missing plates");
	foreach my $id (@missing_plates) {
	    my $plate_name = $dbc->get_FK_info("Plate_ID",$id);
	    Message($plate_name);
	}
    }
    if (int(@excess_plates) > 0) {
	Message("ERROR: Incorrect plates");
	foreach my $id (@excess_plates) {
	    my $plate_name = $dbc->get_FK_info("Plate_ID",$id);
	    Message($plate_name);
	}
    }
    if ( (int(@excess_plates) == 0) && (int(@missing_plates) == 0) ) {
        Message("Correct set of plates for rearray $rearray_ids scanned in!"); 
    } 
   
}
###################
sub nextwell {
###################
	my %args = filter_input(\@_,-args=>'well,format,fill_by,unused_columns,unused_rows');
    my $well = $args{-well};
    my $format = $args{-format};
	my $fill_by = $args{-fill_by};
	my $unused_columns = $args{-unused_columns};
	my $unused_rows = $args{-unused_rows};
	
    my $columns = 12;
    my $rows = 'H';
    if ($format =~/384/) {
	$columns = 24;
	$rows = 'P';
    }
    $rows++;

    my $Ucols = join ',',$unused_columns;
    $Ucols = uc($Ucols);

    my $Urows = join ',',$unused_rows;
    $Urows = uc($Urows);
    
    $Ucols = &extract_range(-list=>$Ucols);
    $Urows = &extract_range(-list=>$Urows);

    my $row = 'A';
    my $col = 1;

    my $init=0;
    if (!$well) {$init = 1;}

    $well = format_well($well);
    if ($well=~/^([a-zA-Z])(\d+)$/) {$row = $1; $col = 0+$2;}
    
    my $skip = 1;
    my $pass = 0;
    while ($skip) {
	$pass++;
	$skip = 0;
	if ($fill_by=~/Row/) {        ####### Fill wells by Row
	    unless ($init) {$col++;}
	    if ($col > $columns) {$col = 1; $row++;}
	    if  (&list_contains($Urows,$row)) {
		$row++;
	    }
	    if (&list_contains($Ucols,$col)) {
		$skip = 1;
	    }
	    if  (&list_contains($Urows,$row)) {
		$skip = 1;
	    }
	    if ($row eq $rows) {
		$row = 'A';		
	    }
	}
	else {                        ######## Fill wells by Column
	    unless ($init) {$row++;}
	    if ($row eq $rows) {
		$row = 'A';
		$col++;
	    }
	    if  (&list_contains($Urows,$row)) {
		$skip = 1;
	    }
	    if (&list_contains($Ucols,$col)) {
		$skip = 1;
	    }
	}
	$init=0;
    }
    my $next_well = format_well("$row$col");
    return $next_well;
}


sub pool_to_tube {
    my $self = shift;
    my $dbc = $self->{dbc};
    my %args = &filter_input( \@_ );
    my $format_id = $args{-format_id};
    my $library = $args{-library};
    my $source_plate_id = $args{-source_plate_id};
    my $target_plate_size = $args{-target_plate_size};
    my $sample_type_id = $args{-sample_type_id};
    my @rearray_source_wells = @{$args{-source_wells}};    

    my $target_rack = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Name='Temporary'" );
    
    my @rearray_target_wells;
    my @source_plates;

    my $type = 'Pool Rearray';
    my $plate_type = 'Tube';
    @rearray_target_wells = ('N/A') x scalar(@rearray_source_wells);
    @source_plates = ($source_plate_id) x scalar(@rearray_source_wells);

    my ( $rearray_request, $target_plate )
	= $self->create_rearray 
	(
	 -source_plates    => \@source_plates,
	 -source_wells     => \@rearray_source_wells,
	 -target_wells     => \@rearray_target_wells,
	 -employee         => $dbc->get_local('user_id'),
	 -request_type     => $type,
	 -status           => 'Completed',
	 -target_size      => $target_plate_size,
	 -create_plate     => 1,
	 -rearray_comments => "",
	 -target_library   => $library,
	 -plate_format     => $format_id,
	 -sample_type_id   => $sample_type_id,
	 -plate_status     => 'Active',
	 -target_rack      => $target_rack,
	 -plate_class      => 'ReArray',
	 -plate_type       => $plate_type,
	 );

    if ($target_plate) {
	alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $target_plate );
 
	  #create new sample for the pool tube and update Plate_Sample
	  my $pool = 1; #set to 1 here so that update_plate_sample_from_rearray will only update FK_Sample__ID in ReArray
	  my ($new_sample_type) = $dbc->Table_find( 'Plate,Sample_Type', 'Sample_Type', "WHERE Plate_ID IN ($source_plate_id) AND FK_Sample_Type__ID = Sample_Type_ID" );
	  my @source_ids
	      = $dbc->Table_find( "Plate,Plate_Sample,Sample", "FK_Source__ID", "WHERE Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND FK_Sample__ID=Sample_ID AND Plate_ID in ($source_plate_id) AND FK_Source__ID <> 0", -distinct => 1 );
	  
	  if ( int(@source_ids) > 1 ) {
	      Message("Warning: Multiple samples identified!!!!");
	  }
	  elsif ( int(@source_ids) < 1 ) {
	      Message("Warning: No source ids identified");
	  }
	  
	  my $ok = alDente::Sample::create_samples( -dbc => $dbc, -source_id => $source_ids[0], -type => $new_sample_type, -plate_id => $target_plate );

	  $self->update_plate_sample_from_rearray( -request_id => $rearray_request, -pool=>$pool );

	  if ( $dbc->package_active('Indexed_Run') ) {
	      #test for duplicate index in the pool
	      require Indexed_Run::Indexed_Run;
	      my $index_run = new Indexed_Run::Indexed_Run(-dbc=>$dbc);
	      $index_run->duplicate_index_check(-plate_id=>$target_plate);
	  }
	    
	  return $target_plate;
      }
}

###############################################
sub create_pool_sample {
###############################################
    # Description:
    #   create pooled samples in the new tube
    # Input:
    #	-library		library
    #   -target_plate           id of the new tube
    #   -source_plates    	source plate ids
    #   -rearray_request	rearray request for the pooling
    #	-rearray_source_wells	rearray source wells
    #	-rearray_target_wells	rearray target wells
    # output:
    #   None
    # <snip>
    # 	$rearray->create_pool_sample(-dbc => $dbc, -library => $library, -target_plate => $target_plate, -source_plate_id => $source_plate_id, -rearray_request => $rearray_request, -rearray_source_wells => \@rearray_source_wells, -rearray_target_wells => \@rearray_target_wells);
    # </snip>
####################################
    my $self            = shift;
    my %args            = filter_input( \@_, -mandatory => 'library,target_plate,source_plates,rearray_request,rearray_source_wells,rearray_target_wells' );
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $library		= $args{-library};
    my $target_plate	= $args{-target_plate};
    my @source_plates	= @{$args{-source_plates}};
    my $rearray_request	= $args{-rearray_request};
    my @rearray_source_wells = @{$args{-rearray_source_wells}};
    my @rearray_target_wells = @{$args{-rearray_target_wells}};
    
    ## Only update FK_Sample__ID in ReArray
    $self->update_plate_sample_from_rearray( -request_id => $rearray_request, -pool=>1 );
	    
    ## Create pool sample for each well and update Plate_Sample
    #use target library's source instead
    my $source_id;
    my $source_obj = alDente::Source->new( -dbc => $dbc, -id => $source_id );    
    
    my $source_plate_id = join(",", @source_plates);
    my $rearray_source_wells_str = Cast_List( -list => \@rearray_source_wells, -to => 'string', -autoquote => 1 );
    $rearray_source_wells_str = '' if( !$rearray_source_wells_str );
    my @source_ids
	= $dbc->Table_find( "Plate,Plate_Sample,Sample", "FK_Source__ID", "WHERE Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND FK_Sample__ID=Sample_ID AND Plate_ID in ($source_plate_id) AND FK_Source__ID <> 0 AND (Plate_Sample.Well in ($rearray_source_wells_str) OR Plate_Sample.Well = Plate.Plate_Parent_Well)", -distinct => 1, -debug=>0 );
	    
    if ( int(@source_ids) > 1 ) {
        $dbc->message("One or more sources identified, creating source pool");
        #Need to update Source_Pool and Hybrid_Original_Source in this case
        my %info;
        $info{src_ids} = \@source_ids;
		my ($plate_format_id)  = $dbc->Table_find( 'Plate_Format',  'Plate_Format_ID',  "WHERE Plate_Format_Type = 'Undefined - To Be Determined'" );
		my ($barcode_label_id) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_ID', "WHERE Label_Descriptive_Name = 'No Barcode'" );
		my %assign;
		$assign{FK_Plate_Format__ID} = $plate_format_id;
		$assign{FK_Barcode_Label__ID} = $barcode_label_id;
		$assign{Source_Status} = 'Redefined';
		$assign{FKSource_Plate__ID} = $target_plate;
        if( $library ) {
	    	my ($os_id)  = $dbc->Table_find( 'Library',  'FK_Original_Source__ID',  "WHERE Library_Name = '$library'" );
	    	$info{original_source} = $os_id;
	    	$assign{FK_Original_Source__ID} = $os_id;
        }
		my %on_conflict;
		$on_conflict{Amount_Units} = '';
		$on_conflict{FKReference_Project__ID} = '';

        my $new_source_id = $source_obj->Pool(-dbc=>$dbc, -tables=>'', -info => \%info, -source_id => $source_id, -no_volume=>1, -no_html=>1, -target_library_name => $library, -assign=>\%assign, -on_conflict=>\%on_conflict);
        if( $new_source_id ) { $source_id = $new_source_id }
        else { return 0 }
    }
    else {
        $dbc->warning("No source ids identified");
    }

    ## Check to see if it is all the same samples, if they are, don't create pool sample, use the sample
    ## <CONSTRUCTION> only for tube
    my @samples = $dbc->Table_find("ReArray","FK_Sample__ID","WHERE FK_ReArray_Request__ID = $rearray_request", -distinct => 1);
    if (int(@samples) == 1) {
		my @insert_fields = ('FKOriginal_Plate__ID','FK_Sample__ID','Well');
		my %sample_insert;
		$sample_insert{1} = [$target_plate,$samples[0],'N/A'];
		$dbc->smart_append(-tables=>'Plate_Sample',-fields=>\@insert_fields,-values=>\%sample_insert,-autoquote=>1);
    }
    else {
		my $ok = alDente::Sample::create_samples( -dbc => $dbc, -source_id => $source_id, -plate_id => $target_plate, -wells=>\@rearray_target_wells );
    }
	
	return 1;    
}    

return 1;

