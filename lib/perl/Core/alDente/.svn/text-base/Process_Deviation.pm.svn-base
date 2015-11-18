##################################################################################################################################
# alDente::Process_Deviation.pm
#
# Model module that handles Process Deviation related functions
#
###################################################################################################################################
package alDente::Process_Deviation;

##############################
# standard_modules_ref       #
##############################
use Carp;
use strict;
use Data::Dumper;

############################
## Local modules required ##
############################
use RGTools::RGIO;
use RGTools::RGmath;

use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use SDB::DB_Object;

############
sub new {
############
    #
    #Constructor of the object
    #
    my $this = shift;
    my %args = @_;

    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $id           = $args{-id};                                                                       ## Process Deviation ID
    my $deviation_no = $args{-Deviation_No};                                                             ## Deviation No

    my $class = ref($this) || $this;

    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => 'Process_Deviation' );
    bless $self, $class;

    $self->{dbc}          = $dbc;
    $self->{id}           = $id if ($id);
    $self->{Deviation_No} = $deviation_no if ($deviation_no);

    return $self;
}
###############################
# Link process deviation to objects
#
# Usage:	link_deviation_to_objects( -dbc => $dbc, -deviation_no => 'PD.476', -object_class => 'Plate', -object_ids => [ '1','2','3' ] );
#			link_deviation_to_objects( -dbc => $dbc, -process_deviation_id => $id, -object_class => 'Library', -object_ids => [ 'A10270','A10269' ] );
# Return:	Hash ref of the new ids info if success; 0 if failed
###############################
sub link_deviation_to_objects {
###############################
    my $self         = shift;
    my %args         = filter_input( \@_, -args => 'dbc,deviation_no,object_class,object_ids' );
    my $dbc          = $args{-dbc} || $self->{dbc};
    my $deviation_no = $args{-deviation_no} || $self->{Deviation_No};
    my $pd_ID        = $args{-process_deviation_id} || $self->{id};
    my $object_class = $args{-object_class};
    my $object_ids   = $args{-object_ids};                                                         # array ref

    if ( !$pd_ID && $deviation_no ) {
        ($pd_ID) = $dbc->Table_find( 'Process_Deviation', 'Process_Deviation_ID', "Where Deviation_No = '$deviation_no'" );
    }
    return 0 if ( !$pd_ID || !$object_class || !$object_ids || !int(@$object_ids) );

    my ($object_class_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "Where Object_Class = '$object_class'" );
    my $user = $args{-user_id} || $dbc->get_local('user_id');
    my $timestamp = &date_time();
    my %values;
    my $index = 0;
    foreach my $id (@$object_ids) {
        $values{ ++$index } = [ $pd_ID, $object_class_id, $id, $user, $timestamp ];
    }
    my $new_ids = $dbc->smart_append(
        -tables    => 'Process_Deviation_Object',
        -fields    => [ 'FK_Process_Deviation__ID', 'FK_Object_Class__ID', 'Object_ID', 'FK_Employee__ID', 'Set_DateTime' ],
        -values    => \%values,
        -autoquote => 1
    );
    return $new_ids;
}

###############################
# The subroutine defined the valid object classes that can be applied to process deviations
#
# Usage:	my @valid = alDente::Process_Deviation::get_valid_deviation_object_classes();
# Return:	Array
###############################
sub get_valid_deviation_object_classes {
###############################
    #my %args = filter_input( \@_, -args => 'dbc' );
    #my $dbc = $args{-dbc};
    my @valid_object_classes = ( 'Source', 'Plate', 'Library', 'Run' );
    return @valid_object_classes;
}

##############################
# Get process deviation IDs that meet the specified criteria
#
# Usage:	 my $ref = alDente::Process_Deviation::get_valid_deviation_object_classes( -deviation_no => 'PD.300,PD.400' );
# 			 my $ref = alDente::Process_Deviation::get_valid_deviation_object_classes( -object_class => 'Plate,Library' );
# 			 my $ref = alDente::Process_Deviation::get_valid_deviation_object_classes( -object_class => 'Plate', -object_id => '12345,23456' );
# Return:	Array ref of process deviation IDs if found; 0 if not found
##############################
sub get_deviation {
##############################
    my %args              = filter_input( \@_, -args => 'dbc,deviation_no,object_class,object_id' );
    my $dbc               = $args{-dbc};
    my $deviation_no_list = $args{-deviation_no};
    my $object_class_list = $args{-object_class};                                                      # object class names
    my $object_id_list    = $args{-object_id};
    my $debug             = $args{-debug};

    my $tables     = 'Process_Deviation LEFT JOIN Process_Deviation_Object ON FK_Process_Deviation__ID = Process_Deviation_ID';
    my $conditions = "WHERE 1 ";
    if ($deviation_no_list) {
        my $deviation_nos = Cast_List( -list => $deviation_no_list, -to => 'string', -autoquote => 1 );
        $conditions .= " and Deviation_No in ( $deviation_nos ) ";
    }
    if ($object_class_list) {
        my $object_classes = Cast_List( -list => $object_class_list, -to => 'string', -autoquote => 1 );
        $tables     .= ' LEFT JOIN Object_Class ON FK_Object_Class__ID = Object_Class_ID ';
        $conditions .= " and Object_Class in ( $object_classes ) ";
    }
    if ($object_id_list) {
        my $object_ids = Cast_List( -list => $object_id_list, -to => 'string', -autoquote => 1 );
        $conditions .= " and Object_ID in ( $object_ids ) ";
    }

    my @pds = $dbc->Table_find( $tables, 'Process_Deviation_ID', $conditions, -distinct => 1, -debug => $debug );
    if   ( int(@pds) ) { return \@pds }
    else               { return 0 }
}

######################################
#
# Multiple ids can be entered in the comma separated list format (e.g. 620658,620670).
# All digit IDs can be entered in range (e.g. 620658-620700).
# To enter libraries in range, enclose the digits in range in square brackets (e.g. A25[382-471]).
# Tips: If the object class is 'Plate', 'traxxxx' can be accepted and will be converted to plate ids automatically (e.g. tra30654,tra30656 or tra30666-tra30668)."
#
# This helper method converts the above ids to an arrage of ids
#######################################
sub convert_ids {
#######################################
    my %args      = filter_input( \@_ );
    my $obj_class = $args{-object_class};
    my $obj_ids   = $args{-object_ids};
    my $dbc       = $args{-dbc};

    my @ids;
    if ( $obj_class eq 'Plate' && $obj_ids =~ /pla/xmsi ) {    # remove 'pla' prefix
        $obj_ids =~ s/pla//gi;
    }

    if ( $obj_ids =~ /^\s*(\d+)\s*-\s*(\d+)\s*$/xms ) {        # all digits in range
        my $from = $1;
        my $to   = $2;
        foreach my $id ( $from .. $to ) { push @ids, $id }
    }
    elsif ( $obj_ids =~ /^\s*(\w*)\[\s*(\d+)\s*-\s*(\d+)\s*\]\s*$/xms ) {    # A1[001-005]
        my $prefix = $1;
        my $from   = $2;
        my $to     = $3;
        foreach my $id ( $from .. $to ) { push @ids, $prefix . $id }
    }
    elsif ( $obj_ids =~ /^\s*tra(\d+)/xmsi && $obj_class eq 'Plate' ) {      # tray
        my @trays;
        if ( $obj_ids =~ /^\s*(tra\d+)\s*$/xmsi ) {                          # single tray ID
            push @trays, $1;
        }
        elsif ( $obj_ids =~ /^tra\d+(,\s*tra\d+\s*)*$/xms ) {                # comma spearated list
            @trays = split ',', $obj_ids;
        }
        elsif ( $obj_ids =~ /^\s*tra(\d+)\s*-\s*tra(\d+)\s*$/xmsi ) {        # in range
            my $from = $1;
            my $to   = $2;
            foreach my $id ( $from .. $to ) { push @trays, 'tra' . $id }
        }
        ## convert to plates
        if ( int(@trays) ) {
            my $tray_list = join '', @trays;
            require alDente::Tray;
            my $barcode = alDente::Tray::convert_tray_to_plate( -dbc => $dbc, -barcode => $tray_list );
            @ids = split /Pla/, $barcode;
            if ( int(@ids) && !$ids[0] ) {
                shift @ids;                                                  # remove the first empty element
            }
        }
    }
    elsif ( $obj_ids =~ /,/ ) {                                              # comma separated list format
        @ids = Cast_List( -list => $obj_ids, -to => 'array' );
    }
    else {
        push @ids, $obj_ids;
    }

    return \@ids;
}

1;
