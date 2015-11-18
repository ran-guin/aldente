package alDente::ReArray1;

use RGTools::RGIO;
use Data::Dumper;
use strict;

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
    $self->{success}   = 0;

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
    my $request_status  = $args{-request_status};       # Optional

    my $request_type;                                   ## ReArray Type

    $self->{dbc}->start_trans('create_rearray');

    ## Create target plate or add to existing plate
    $target_plate_id = $self->_create_target_plate(%args);

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
    my $self = shift;
    my @rearray_request_types = $self->{dbc}->Table_find( 'ReArray_Request', 'ReArray_Type', "WHERE 1", -distinct => 1 );

    return @rearray_request_types;
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

    my @rearray_request_status_lists;

    return \@rearray_request_status_lists;
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
    my $self = shift;
    my @employees = $self->{dbc}->Table_find( 'ReArray_Request', 'FK_Employee__ID', "WHERE 1", -distinct => 1 );
    return @employees;
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
    my $target_plate     = $args{-target_plate};                                                                               # Target Plate ID
    my $request_type     = $args{-request_type};                                                                               # Type of ReArray Request
    my $rearray_comments = $args{-rearray_comments};                                                                           # Comments
    my $request_status   = $args{-request_status};                                                                             # Status ID of the rearray

    my @fields = ( 'FK_Employee__ID', 'FKTarget_Plate__ID', 'Request_DateTime', 'ReArray_Comments', 'FK_Status__ID' );

    my @values = ( $employee_id, $target_plate, &date_time(), $rearray_comments, $request_status );

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
    my $index = 0;
    foreach my $source_plate ( @{$source_plates} ) {
        $rearray_values{$index} = [ $rearray_request, $source_plate, $source_wells->[$index], $target_wells->[$index] ];
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
    my $target_plate_id;

    return $target_plate_id;
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
    return $target_plate_id;
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
    return $number_of_wells_updated;
}

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
sub apply_rearrays {
    my $self             = shift;
    my %args             = filter_input( \@_, -args => 'rearray_requests' );
    my $rearray_requests = $args{-rearray_requests};
    my $num_applied;

    return $num_applied;
}

sub write_to_rearray_log {

}
return 1;

