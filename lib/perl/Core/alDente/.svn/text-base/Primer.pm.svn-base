#!/usr/bin/perl
###################################################################################################################################
# Primer.pm
#
# Class module that encapsulates a DB_Object that represents a Primer
#
# $Id: Primer.pm,v 1.35 2004/12/03 20:02:42 jsantos Exp $
###################################################################################################################################
package alDente::Primer;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Primer.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Class module that encapsulates a DB_Object that represents a Primer<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

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

#use Storable;
use POSIX qw(log10);

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Barcoding;
use alDente::Notification;
use alDente::Subscription;
use alDente::Stock;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Object;
use RGTools::Conversion;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;

##############################
# global_vars                #
##############################
### Global variables
use vars qw($User $Connection $java_bin_dir $templates_dir $bin_home $Sess);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Modular variables
my $DateTime;
### Constants
my $FONT_COLOUR = 'BLUE';
my ($mypath) = $INC{'alDente/Primer.pm'} =~ /^(.*)alDente\/Primer\.pm$/;
my $TAB_TEMPLATE = $mypath . "/../../conf/templates/Primer Order Form.txt";

##############################
# constructor                #
##############################

############################################################
# Constructor: Takes a database handle and a primer ID and constructs a primer object
# RETURN: Reference to a Primer object
############################################################
sub new {
###########
    my $this = shift;
    my %args = @_;

    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $primer_id = $args{-primer_id};                                                               # Primer ID of the project
    my $frozen    = $args{-frozen} || 0;                                                             # flag to determine if the object was frozen
    my $encoded   = $args{-encoded};                                                                 # flag to determine if the frozen object was encoded
    my $class     = ref($this) || $this;

    #    my $conn = $args{-connection};  # delete this comment block if sure

    #    $Connection = $conn if ($conn);
    #    unless ($Connection) {
    #	Message("Connection not defined");
    #    }

    my $self;
    if ($frozen) {
        $self = $this->Object::new(%args);
    }
    elsif ($primer_id) {
        $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Primer,Primer_Customization", -primary => $primer_id, -dbc => $dbc );

        #acquire all information necessary for Projects
        $self->load_Object();
        bless $self, $class;
    }
    else {
        $self = SDB::DB_Object->new( -dbc => $dbc, -tables => "Primer,Primer_Customization", -dbc => $dbc );
        bless $self, $class;
    }

    $self->{dbc} = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

############################################################
# Subroutine: creates an HTML page view of a single primer plate
# RETURN: none
############################################################
sub view_primer_plate {
############################################################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};
    #### MANDATORY FIELDS
    my $primer_plate_id = $args{-primer_plate_id};

    # do error checking
    unless ($primer_plate_id) {
        Message("No primer plate ID specified");
        return;
    }
    if ( $primer_plate_id !~ /\d+/ ) {
        Message("Incorrect ID format");
        return;
    }

    # retrieve primer plate data
    my %primer_plate_info = &Table_retrieve(
        $dbc,
        "Primer_Plate left join Solution on FK_Solution__ID=Solution_ID",
        [ 'Primer_Plate_ID', 'Primer_Plate_Name', 'Order_DateTime', 'Arrival_DateTime', 'Primer_Plate_Status', 'FK_Solution__ID', 'Notes', 'FK_Rack__ID' ],
        "WHERE Primer_Plate_ID=$primer_plate_id"
    );
    unless ( defined $primer_plate_info{Primer_Plate_ID}[0] ) {
        Message("Primer Plate ID ($primer_plate_id) does not exist");
        return;
    }

    # get rack
    my $rack = "";
    if ( defined $primer_plate_info{FK_Rack__ID}[0] ) {
        $rack = &get_FK_info( $dbc, "FK_Rack__ID", $primer_plate_info{FK_Rack__ID}[0] );
    }
    else {
        $rack = "Unknown Location";
    }

    # get notes
    my $notes = $primer_plate_info{Notes}[0];

    # retrieve primer_plate_well and primer data
    my %primer_info = &Table_retrieve(
        $dbc,
        "Primer_Plate_Well,Primer,Primer_Customization",
        [ 'Well', 'Primer_Name', 'Primer_Sequence', 'Primer_Type', 'Tm_Working', 'Direction', 'Amplicon_Length', 'Position', 'Adapter_Index_Sequence', 'Primer_Plate_Well_Notes' ],
        "WHERE Primer_Plate_Well.FK_Primer__Name=Primer_Name AND Primer_Customization.FK_Primer__Name=Primer_Name AND FK_Primer_Plate__ID=$primer_plate_id"
    );
    ### create table

    # set title
    my $title = "";
    $title .= "$primer_plate_info{Primer_Plate_Name}[0]<BR>";
    $title .= "Primer Plate $primer_plate_id<BR>";
    if ( defined $primer_plate_info{FK_Solution__ID}[0] ) {
        $title .= "sol$primer_plate_info{FK_Solution__ID}[0]<BR>";
    }
    else {
        $title .= "Unassigned solution<BR>";
    }

    $title .= "<font size=2>";
    $title .= "Ordered $primer_plate_info{Order_DateTime}[0]<BR>";
    $title .= "Arrived $primer_plate_info{Arrival_DateTime}[0]<BR><BR>";
    $title .= "$rack<BR>";
    $title .= "</font>";

    # set headers
    my @headers = ( 'Primer Name', 'Well', 'Sequence', 'Type', 'Direction', 'Tm', 'Well Notes' );

    # check to see if the primers have position information. Add in the column if needed.
    my $has_position = 0;
    if ( $primer_info{Position}[0] && ( $primer_info{Position}[0] =~ /Outer|Nested/ ) ) {
        $has_position = 1;
    }
    my $details_width = 4;
    if ($has_position) {
        $details_width++;
        push( @headers, 'Position' );
    }
    my $has_adapter_index_seq = 0;
    if ( grep /\w/, @{ $primer_info{Adapter_Index_Sequence} } ) {
        $has_adapter_index_seq = 1;
        $details_width++;
        push( @headers, 'Adapter Index Sequence' );
    }

    # initialize
    print alDente::Form::start_alDente_form( $dbc, "PrimerView", $dbc->homelink() );
    print hidden( -name => "PlateRow", -value => $primer_plate_id );
    print submit( -name => "Show Remap Summary", -style => "background-color:lightgreen" );

    #
    my $table = new HTML_Table();
    $table->Set_Title($title);
    $table->Toggle_Colour(0);
    $table->Set_Border(1);
    $table->Set_Headers( \@headers );
    $table->Set_sub_title( 'Primer',   2,              'lightredbw' );
    $table->Set_sub_title( 'Sequence', 1,              'mediumyellowbw' );
    $table->Set_sub_title( 'Details',  $details_width, 'mediumgreenbw' );
    my $total_tm = 0;

    # display all primer information
    my $index = 0;
    while ( exists $primer_info{Primer_Name}[$index] ) {
        my $primer_name       = $primer_info{Primer_Name}[$index];
        my $primer_well       = $primer_info{Well}[$index];
        my $primer_type       = $primer_info{Primer_Type}[$index];
        my $primer_direction  = $primer_info{Direction}[$index];
        my $primer_tm         = $primer_info{Tm_Working}[$index];
        my $primer_sequence   = $primer_info{Primer_Sequence}[$index];
        my $primer_position   = $primer_info{Position}[$index];
        my $adapter_index_seq = $primer_info{Adapter_Index_Sequence}[$index];
        my $ppw_notes         = $primer_info{Primer_Plate_Well_Notes}[$index];

        my $row = [ $primer_name, $primer_well, $primer_sequence, $primer_type, $primer_direction, $primer_tm, $ppw_notes ];
        if ($has_position) {
            push( @{$row}, $primer_position );
        }
        if ($has_adapter_index_seq) {
            push( @{$row}, $adapter_index_seq );
        }
        $table->Set_Row($row);
        $total_tm += $primer_tm;
        $index++;
    }
    $index ||= 1;    # can't divide by zero
    my $ave_tm = $total_tm / ($index);    # doesn't need +1 because it incremented at the end of the loop
                                          # add notes at the end
    $table->Set_sub_header("Notes: $notes");
    $table->Set_sub_header("Average Tm: $ave_tm");
    print $table->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Primer_Plate@{[timestamp()]}.html", $html_header );
    $table->Printout();
    print end_form();
}

###############################################################
# Subroutine: generates an HTML page for viewing Primer plates
# RETURN: none
###############################################################
sub view_primer_plates {
    ####################
    my $self                      = shift;
    my %args                      = @_;
    my $dbc                       = $self->{dbc};
    my $primer_status             = $args{-primer_status};
    my $from_order_date           = $args{-from_order_date};
    my $notes                     = $args{-notes};
    my $type                      = $args{-type};
    my $primer_plate_ids          = $args{-primer_plate_ids};
    my $primer_plate_solution_ids = $args{-primer_plate_solution_ids};
    my $button_options            = $args{-button_options} || 'lab';
    my $extra_conditions          = $args{-extra_condition};

    print alDente::Form::start_alDente_form( $dbc, "Primer_Form", $dbc->homelink() );

    # retrieve primer plate data
    my $condition = "";
    if ($primer_status) {
        $condition .= " Primer_Plate_Status='$primer_status' AND ";
    }
    if ($from_order_date) {
        $condition .= " Order_DateTime >= '$from_order_date' AND ";
    }
    if ($notes) {

        # regexp replace *s with %s
        $notes = convert_to_regexp($notes);
        $condition .= " Notes like '$notes' AND";
    }
    if ($primer_plate_ids) {
        $primer_plate_ids = &resolve_range($primer_plate_ids);
        $condition .= " Primer_Plate_ID in ($primer_plate_ids) AND";
    }
    elsif ($primer_plate_solution_ids) {
        $condition .= " FK_Solution__ID IN ($primer_plate_solution_ids) AND";
    }

    $condition .= $extra_conditions . " AND " if ($extra_conditions);

    my %info = $dbc->Table_retrieve(
        "Primer_Plate left join Solution on FK_Solution__ID=Solution_ID",
        [ 'Primer_Plate_ID', 'Primer_Plate_Name', 'left(Order_DateTime,10) as Order_Time', 'left(Arrival_DateTime,10) as Arrive_Time', 'Primer_Plate_Status', 'FK_Solution__ID', 'Notes', 'FK_Rack__ID' ],
        "WHERE $condition 1",
        -debug => 0
    );

    # create table
    # add checkboxes to regenerate primer orders
    my $table = new HTML_Table();

    #Message("C: $condition 1");
    $table->Set_Title("Primer Plate List");

    my $toggleBoxes = "ToggleNamedCheckBoxes(document.Primer_Form,'ToggleAll','PlateRow');return 0;";

    $table->Set_Headers( [ checkbox( -name => "ToggleAll", -label => '', -onClick => $toggleBoxes ), "Name", "Primer Plate ID", "Solution ID", "Status", "Contains", "Notes", "Location", "Order Date", "Arrival Date" ] );
    my $index = 0;
    while ( exists $info{Primer_Plate_ID}[$index] ) {
        my $name        = $info{Primer_Plate_Name}[$index];
        my $id          = $info{Primer_Plate_ID}[$index];
        my $sol_id      = $info{FK_Solution__ID}[$index];
        my $order_time  = $info{Order_Time}[$index];
        my $arrive_time = $info{Arrive_Time}[$index];
        my $status      = $info{Primer_Plate_Status}[$index];
        my $notes       = $info{Notes}[$index];

        # get location
        my $rack = "";
        if ( defined $info{FK_Rack__ID}[0] ) {
            $rack = &get_FK_info( $dbc, "FK_Rack__ID", $info{FK_Rack__ID}[0] );
        }
        else {
            $rack = "Unknown";
        }

        # query for what primer types each Primer_Plate contains
        my @contains = $dbc->Table_find( "Primer_Plate,Primer_Plate_Well,Primer", "distinct Primer_Type", "WHERE FK_Primer_Plate__ID=Primer_Plate_ID AND FK_Primer__Name=Primer_Name AND Primer_Plate_ID=$id" );
        my $contains_str = join( ',', @contains );

        # break if $type is defined and it does not match the $contains string
        if ( ( defined($type) && ( $type ne '' ) ) && ( !( grep /$type/, @contains ) ) ) {
            $index++;
            next;
        }

        # add checkbox for selection
        my $selectbox = checkbox( -name => "PlateRow", -value => $id, -label => '' );

        # change id to a link
        $id = Link_To( $dbc->config('homelink'), "$id", "&View+Primer+Plate=1&Primer+Plate+ID=$id", "$Settings{LINK_COLOUR}", ["newwin"] );

        # set row
        my $row = [ $selectbox, $name, $id, $sol_id, $status, $contains_str, $notes, $rack, $order_time, $arrive_time ];

        # fill out whitespace
        foreach ( @{$row} ) {
            if ( $_ eq "" || $_ eq "0000-00-00" ) {
                $_ = "&nbsp";
            }
        }
        $table->Set_Row($row);
        $index++;
    }
    my $primer_organizations = _get_primer_organizations( -dbc => $dbc );

    $table->Set_Border(1);
    $table->Printout();
    print hidden( -name => 'cgi_application', -value => 'alDente::Primer_App', -force => 1 );
    print set_validator( -name => 'PlateRow', -mandatory => 1, -prompt => 'No primer plate selected' );

    if ( $button_options eq 'lab' ) {
        print vspace(5);

        #print submit( -label => 'Regenerate Primer Order', -name => 'Regenerate Primer Order From Primer Plate', -style => "background-color:lightgreen" );
        print submit( -name => 'rm', -value => 'Regenerate Primer Order', -style => "background-color:lightgreen", -onClick => "return validateForm(this.form)" );
        print br() . vspace(2);
        print Show_Tool_Tip( submit( -name => 'rm', -value => 'Order Repeated Primer Plate', -style => "background-color:lightgreen", -onClick => "return validateForm(this.form)" ),
            "Order repeated primer plate. A new solution ID will be generated. The original primer plate information will be copied to the new plate. The new primer plate status will be set to 'Ordered'" );
        print hspace(10) 
            . "New Primer Plate Name:"
            . Show_Tool_Tip(
            textfield( -name => 'New_Primer_Plate_Name', -size => 20, -force => 1 ),
            "Enter the name(s) of the new primer plate(s). If multiple names are to be entered, please separate the names by comma and enter them in the same order of the listed primer plates above. If no name is entered, the primer plate name of the original plate with 'Repeated' appended will be used."
            );
        print br() . vspace(2);

        #print submit( -name => 'Mark Primer Plates as Ordered', -style => "background-color:lightgreen" );
        print submit( -name => 'rm', -value => 'Mark Primer Plates as Ordered', -style => "background-color:lightgreen", -onClick => "return validateForm(this.form)" );
        print br() . vspace(2);
        print submit( -name => 'rm', -value => 'Mark Primer Plates as Canceled', -style => "background-color:lightgreen", -onClick => "return validateForm(this.form)" );
        print br() . vspace(2);

        #print submit( -name => 'Generate Custom Primer Multiprobe', -style => "background-color:lightgreen" );
        print submit( -name => 'rm', -value => 'Generate Custom Primer Multiprobe', -style => "background-color:lightgreen", -onClick => "return validateForm(this.form)" );
        print br() . vspace(2);

        #print submit( -name => 'rm', -value => 'Generate Custom Primer Multiprobe', -style => "background-color:lightgreen" );
        #print br() . vspace(2);

        #  print submit( -name => 'rm', -value => 'Receive Primer Plate as Tubes', -style => "background-color:lightgreen");
        print RGTools::Web_Form::Submit_Button(
            form         => 'Primer_Form',
            name         => 'rm',
            label        => 'Receive Primer Plate as Tubes',
            onClick      => "validateForm(this.form);",
            validate     => 'FK_Organization__Name',
            validate_msg => 'Please enter an organization first.'
            )
            . hspace(5)
            . ' from organization: '
            . hspace(5);
        print alDente::Tools->search_list( -dbc => $dbc, -name => 'FK_Organization__Name', -option_condition => " Organization_ID IN ($primer_organizations) ", -default => '', -search => 1, -filter => 1, -breaks => 1, -width => 390 );
        print checkbox( -name => 'delete_primer_plate', -label => 'Delete Primer Plate', -checked => 1, -force => 1 );
        print br();
    }
    elsif ( $button_options eq 'bioinformatics' ) {
        print submit( -name => 'rm', -value => 'Delete Primer Plate Orders', -style => "background-color:red" );
        print br();
    }

    print end_form();
}

############################################################
# Subroutine: mark a set of primer plates as ordered (from to order)
# RETURN: none
############################################################
sub mark_plates_as_ordered {
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $self->{dbc};
    my $primer_ids = $args{-primer_ids};

    unless ($primer_ids) {
        Message("No Primer Plates selected");
        return;
    }

    my @ids = split ',', $primer_ids;

    foreach my $id (@ids) {
        my %primer_plate = $dbc->Table_retrieve( "Primer_Plate", [ "Primer_Plate_Status", "Primer_Plate_Name", "Notify_List" ], "WHERE Primer_Plate_ID=$id" );
        unless ( defined $primer_plate{Primer_Plate_Status}[0] ) {next}

        my $status = $primer_plate{Primer_Plate_Status}[0];
        my $list   = $primer_plate{Notify_List}[0];
        my $name   = $primer_plate{Primer_Plate_Name}[0];

        if ( $status ne 'To Order' ) {
            Message("Primer Plate $id not in TO ORDER status, skipping...");
            next;
        }
        else {
            my $ok = $dbc->Table_update_array( "Primer_Plate", ["Primer_Plate_Status"], ["'Ordered'"], "WHERE Primer_Plate_ID=$id" );
            if ($ok) {
                Message("Primer plate $id set to Ordered. Updated $ok records.");
            }
            else {
                Message("Warning: no records updated.");
            }
            if ($list) {

                my $ok = alDente::Subscription::send_notification(
                    -dbc  => $dbc,
                    -name => "Primer Plate Ordered",
                    -from => 'aldente@bcgsc.ca',

                    # -to           => $list,
                    -subject      => "Primer Plate $name ($id) Ordered (from Subscription Module)",
                    -body         => "Primer Plate $name ($id)  Ordered.  " . &date_time(),
                    -content_type => 'html',
                    -testing      => $dbc->test_mode
                );
            }
        }
    }

    #$self->view_primer_plates(-primer_plate_ids=>$primer_ids);
}

############################################################
# Subroutine: mark a set of primer plates as canceled (from to order or ordered)
# RETURN: none
############################################################
sub mark_plates_as_canceled {
    my $self       = shift;
    my %args       = @_;
    my $dbc        = $self->{dbc};
    my $primer_ids = $args{-primer_ids};

    unless ($primer_ids) {
        Message("No Primer Plates selected");
        return;
    }

    my @ids = split ',', $primer_ids;

    foreach my $id (@ids) {
        my %primer_plate = $dbc->Table_retrieve( "Primer_Plate", [ "Primer_Plate_Status", "Primer_Plate_Name", "Notify_List" ], "WHERE Primer_Plate_ID=$id" );
        unless ( defined $primer_plate{Primer_Plate_Status}[0] ) {next}

        my $status = $primer_plate{Primer_Plate_Status}[0];
        my $list   = $primer_plate{Notify_List}[0];
        my $name   = $primer_plate{Primer_Plate_Name}[0];

        unless ( $status eq 'To Order' || $status eq 'Ordered' ) {
            Message("Primer Plate $id not in TO ORDER or ORDERED status, skipping...");
            next;
        }
        else {
            my $ok = $dbc->Table_update_array( "Primer_Plate", ["Primer_Plate_Status"], ["'Canceled'"], "WHERE Primer_Plate_ID=$id" );
            if ($ok) {
                Message("Primer plate $id set to Canceled. Updated $ok records.");
            }
            else {
                Message("Warning: no records updated.");
            }

##
            # <CONSTRUCTION> Can add email subscription later, not too important.
##

=for comment            if ($list) {

                my $ok = alDente::Subscription::send_notification(
                    -dbc  => $dbc,
                    -name => "Primer Plate Ordered",
                    -from => 'aldente@bcgsc.ca',

                    # -to           => $list,
                    -subject      => "Primer Plate $name ($id) Ordered (from Subscription Module)",
                    -body         => "Primer Plate $name ($id)  Ordered.  " . &date_time(),
                    -content_type => 'html',
                    -testing      => $dbc->test_mode
                );
=cut            }

        }
    }

    #$self->view_primer_plates(-primer_plate_ids=>$primer_ids);
}

###############################################################
# Function: copies a primer plate (essentially a remap call)
# RETURN: solution ID of the new primer plate
###############################################################
sub copy_primer_plate {
    my $self = shift;

    my %args = &filter_input( \@_, -args => 'solution_id,primer_plate_id,new_name,stock_name,target_solution_id' );

    if ( $args{ERROR} ) {
        $self->error("$args{ERROR}");
        return;
    }

    my $dbc = $self->{dbc};

    my $solution_id        = $args{-solution_id};                          # (Scalar) solution ID of the plate to be copied
    my $primer_plate_id    = $args{-primer_plate_id};                      # (Scalar) primer plate ID of the plate to be copied
    my $new_name           = $args{-new_name};                             # (Scalar) New name for the primer plate.
    my $stock_name         = $args{-stock_name} || 'Custom Oligo Plate';
    my $target_solution_id = $args{-target_solution_id};
    my $user_id            = $dbc->get_local('user_id');

    if ( !$solution_id && !$primer_plate_id ) {
        print("Missing argument: solution_id or primer_plate_id");
        return;
    }
    if ( $solution_id && !$primer_plate_id ) {
        ($primer_plate_id) = $dbc->Table_find( "Primer_Plate", "Primer_Plate_ID", "WHERE FK_Solution__ID=$solution_id" );
    }

    if ( $primer_plate_id && !$solution_id ) {
        ($solution_id) = $dbc->Table_find( "Primer_Plate", "Primer_Plate_ID", "WHERE Primer_Plate_ID=$primer_plate_id" );
    }

    # retrieve all wells
    my @primer_plate_info = $dbc->Table_find( "Primer_Plate", "Notes,Primer_Plate_Name", "WHERE Primer_Plate_ID=$primer_plate_id" );
    my ( $notes, $old_name ) = split ',', $primer_plate_info[0];

    $new_name ||= $old_name;

    my @source_wells  = $dbc->Table_find( "Primer_Plate_Well", "Well", "WHERE FK_Primer_Plate__ID=$primer_plate_id" );
    my @target_wells  = ();
    my @source_plates = ();

    foreach my $well (@source_wells) {
        push( @target_wells,  $well );
        push( @source_plates, $primer_plate_id );
    }

    my $sol_id = $self->remap_primer_plate(
        -stock_name         => $stock_name,
        -primer_plate_name  => $new_name,
        -emp_id             => $user_id,
        -notes              => $notes,
        -source_plates      => \@source_plates,
        -source_wells       => \@source_wells,
        -target_wells       => \@target_wells,
        -target_solution_id => $target_solution_id
    );
    if ( $self->error() ) {
        print $self->error();
        return 0;
    }
    else {
        return $sol_id;
    }
}

###############################################################
# Function: creates a new remapped primer plate from existing primer
#           plates
# RETURN: solution ID of the new primer plate
###############################################################
sub remap_primer_plate {
    my $self = shift;

    my %args = &filter_input( \@_, -args => 'primer_plate_name,stock_name,source_plates,source_wells,target_wells,notes,target_solution_id', -mandatory => 'source_plates,source_wells,target_wells,notes' );

    if ( $args{ERROR} ) {
        $self->error("$args{ERROR}");
        return;
    }

    my $primer_plate_name  = $args{-primer_plate_name};
    my $notes              = $args{-notes};
    my $source_plates_ref  = $args{-source_plates};        # (ArrayRef) An array of primer plate ids (the source of the remap)
    my $source_wells_ref   = $args{-source_wells};         # (ArrayRef) An array of well ids to be drawn from
    my $target_wells_ref   = $args{-target_wells};         # (ArrayRef) An array of well ids to be used as targets
    my $emp_name           = $args{-emp_name};             # (Scalar) The name of the user creating the remapped plate
    my $emp_id             = $args{-emp_id};
    my $stock_name         = $args{-stock_name};
    my $target_solution_id = $args{-target_solution_id};
    my $dbc                = $self->{dbc};
    $dbc ||= $self->{dbc};

    # ERROR CHECK

    if ( ( int( @{$source_plates_ref} ) != int( @{$source_wells_ref} ) ) ) {
        $self->error("ERROR: Invalid parameter: Source plates array must be the same size as source wells array");
    }
    if ( ( int( @{$source_plates_ref} ) != int( @{$target_wells_ref} ) ) ) {
        $self->error("ERROR: Invalid parameter: Source plates array must be the same size as target wells array");
    }

    # check if primer plates have been received
    my @status_check = $dbc->Table_find( "Primer_Plate", "distinct Primer_Plate_Status", "WHERE Primer_Plate_ID in (" . join( ',', @{ unique_items($source_plates_ref) } ) . ")" );
    if ( int(@status_check) > 1 ) {
        $self->error("ERROR: Invalid argument: All source plates must be of status 'Received'");
    }
    else {
        if ( $status_check[0] ne 'Received' ) {
            $self->error("ERROR: Invalid argument: All source plates must be of status 'Received'");
        }
    }

    # get the employee ID, and fullname
    # get employee id of user

    unless ($emp_id) {
        my @emp_id_array = $dbc->Table_find( 'Employee', 'Employee_ID,Employee_FullName', "where Email_Address='$emp_name'" );
        ($emp_id) = split ',', $emp_id_array[0];
    }
    unless ( $emp_id =~ /\d+/ ) {
        $self->error("ERROR: Invalid parameter: Employee $emp_name does not exist in database");
    }

    if ( $self->error() ) {
        $self->success(0);
        return;
    }

    # if no primer_plate_name defined, then concatenate the names of the sources
    my @source_names = $dbc->Table_find( "Primer_Plate", "Primer_Plate_Name", "WHERE Primer_Plate_ID in (" . join( ',', @{$source_plates_ref} ) . ")", -distinct => 1 );
    $primer_plate_name ||= join( '.', @source_names );

    # get the primer name and primer plate well ids of all sources defined
    my @source_primerwell_ids = ();
    my @source_primernames    = ();
    my $counter               = 0;
    foreach my $source_plate ( @{$source_plates_ref} ) {
        my $source_well = format_well( $source_wells_ref->[$counter] );
        my @retval = $dbc->Table_find( "Primer_Plate_Well,Primer_Plate", "FK_Primer__Name,Primer_Plate_Well_ID", "WHERE FK_Primer_Plate__ID=Primer_Plate_ID AND Primer_Plate_ID=$source_plate AND Well like '$source_well'" );
        my ( $primername, $primer_well ) = split( ',', $retval[0] );
        push( @source_primerwell_ids, $primer_well );
        push( @source_primernames,    $primername );
        $counter++;
    }

    # get the organization ID
    my ($organization_id) = $dbc->Table_find( "Organization", "Organization_ID", "WHERE Organization_Name = 'GSC'" );

    # create new primer plate
    my $datetime = &date_time();
    my ( $primer_plate_id, $newids_ref ) = $self->create_primer_plate(
        -stock_name                 => $stock_name,
        -primer_names               => \@source_primernames,
        -order_date                 => $datetime,
        -primer_plate_name          => $primer_plate_name,
        -arrival_data               => $datetime,
        -emp_id                     => $emp_id,
        -status                     => 'Received',
        -primer_wells               => $target_wells_ref,
        -parent_primerplatewell_ids => \@source_primerwell_ids,
        -notes                      => $notes,
        -organization_id            => $organization_id,
        -source                     => 'Made in House',
        -omit_primers               => 1,
        -solution_id                => $target_solution_id
    );

    my ($new_sol_id) = $dbc->Table_find( "Primer_Plate", "FK_Solution__ID", "WHERE Primer_Plate_ID=$primer_plate_id" );

    # print barcode
    unless ($target_solution_id) {
        &alDente::Barcoding::PrintBarcode( $dbc, 'Solution', "$new_sol_id" ) if defined $Sess->{session_id};
    }
    return $new_sol_id;
}

########################################################
# Function: Generate a solution ID for a primer plate
# Return: the solution ID of the primer plate
########################################################
sub generate_solution_id {
########################################################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $dbc             = $self->{dbc};
    my $user_id         = $dbc->get_local('user_id');
    my $primer_plate_id = $args{-primer_plate_id};
    my $organization_id = $args{-organization_id};
    my $emp_id          = $args{-emp_id} || $user_id;
    my $source          = $args{-source} || 'Order';
    my $stock_name      = $args{-stock_name} || "Custom Oligo Plate";

    # create a solution id for the primer plate
    my $solution_id = "";

    ## For Stock Insert
    my ($notes) = $dbc->Table_find( "Primer_Plate", "Notes", "WHERE Primer_Plate_ID=$primer_plate_id" );
    my $cat_number = "";
    if ($notes) {
        $cat_number = " $notes";
    }

    ####### new way of finding catalog id goes right here
    my @cat_ids = $dbc->Table_find( "Stock_Catalog", "Stock_Catalog_ID", "WHERE FK_Organization__ID = $organization_id AND Stock_Catalog_Name = '$stock_name' AND Stock_Source = '$source' AND Stock_Status = 'Active'" );
    my $catalog_ID = $cat_ids[0];
    unless ($catalog_ID) {
        ## If there is no catalog Id one needs to be created
        my @catalog_fields = qw (Stock_Catalog_Name Stock_Type  Stock_Source    Stock_Size  Stock_Size_Units    FK_Organization__ID);
        my @catalog_values = ( $stock_name, 'Primer', $source, 'undef', 'n/a', $organization_id );
        $catalog_ID = $dbc->Table_append_array( 'Stock_Catalog', \@catalog_fields, \@catalog_values, -autoquote => 1 );
    }

    my ($barcode_id) = $dbc->Table_find( "Barcode_Label", "Barcode_Label_ID", "WHERE Label_Descriptive_Name='1D Small Solution Labels'" );

    my @fields = ( 'Stock_Received', 'Identifier Number', 'Stock_Lot_Number', 'FK_Employee__ID', 'Stock_Cost', 'FK_Orders__ID', 'Stock_Number_in_Batch', 'FK_Grp__ID', 'FK_Barcode_Label__ID', 'FK_Stock_Catalog__ID' );
    my ($group) = $dbc->Table_find( "Grp", "Grp_ID", "WHERE Grp_Name = 'Cap_Seq Production'" );
    my @values = ( &today(), $cat_number, '', $emp_id, 0, 0, 1, $group, $barcode_id, $catalog_ID );

    ## For Solution Info insert
    push( @fields, ( 'nMoles', 'OD', 'micrograms' ) );
    push( @values, ( 0,        0,    0 ) );
    ## For Solution insert
    push( @fields, ( 'Solution_Type', 'Solution_Started', 'Solution_Expiry', 'Quantity_Used', 'FK_Rack__ID', 'Solution_Status', 'Solution_Number', 'Solution_Number_in_Batch', 'QC_Status', 'Solution_Quantity' ) );
    push( @values, ( 'Primer', '', '', '', 1, 'Unopened', 1, 1, 'N/A', '' ) );
    $dbc->smart_append( -tables => "Stock,Solution,Solution_Info", -fields => \@fields, -values => \@values, -autoquote => 1 );
    $solution_id = $dbc->newids( 'Solution', 0 );

    return $solution_id;
}

############################################################
# Subroutine: creates a new primer plate in the database
# RETURN: 0 if unsuccessful, or the primer plate id if successful
############################################################
sub create_primer_plate {
##############################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};
    ### MANDATORY FIELDS
    my $primer_names_ref           = $args{-primer_names};                  # (ArrayRef) an array of primer names
    my $primer_sequences_ref       = $args{-sequences};                     # (ArrayRef) an array of primer sequences corresponding to the primer names
    my $type                       = $args{-type};                          # (Scalar) the type of the primer. One of Standard, Custom, or Oligo
    my $wells_ref                  = $args{-primer_wells};                  # (ArrayRef) an array of wells that correspond to primers
    my $parent_primerplatewell_ref = $args{-parent_primerplatewell_ids};    # (ArrayRef) Optional: an array of parent Primer_Plate_Well IDs
    my $primer_plate_name          = $args{-primer_plate_name};             # (Scalar) the primer plate name (the external order number)
    my $sol_id                     = $args{-solution_id};                   # (Scalar) the solution id of the primer plate.
    my $organization_id            = $args{-organization_id};               # (Scalar) Organization that is supplying the primer plate
    my $emp_id                     = $args{-emp_id};                        # (Scalar) Employee ID of the person doing the ordering
    my $order_date                 = $args{-order_date};                    # (Scalar) the order date
    my $arrival_date               = $args{-arrival_date};                  # (Scalar) The arrival date
    my $plate_status               = $args{-status};                        # (Scalar) The status of the primer plate. One of 'To Order','Ordered', or 'Received'
    my $source                     = $args{-source} || 'Order';
    my $stock_name                 = $args{-stock_name};

    my $tms_working_ref              = $args{-tm_working};                      # (ArrayRef) Optional: an array of working temperatures. Define either this or the tm calculation string
    my $amplicon_length_ref          = $args{-amplicon_length};                 # (ArrayRef) Optional: an array of amplicon lengths. Only required for amplicon primer plates
    my $tm_calc                      = $args{-tm_calc};                         # (Scalar) Optional: a string defining the tm calculation. Right now, only supports "MGC Standard".
    my $direction_ref                = $args{-direction};                       # (ArrayRef) Optional: an array of directions for the primers. Defaulted to 'Unknown'.
    my $position_ref                 = $args{-position};                        # (ArrayRef) Optional: an array of positions for primers. One of Outer or Nested.
    my $omit_insertion               = $args{-omit_primers} || 0;               # (Scalar) flag that determines if the primer names are going to be inserted into the db. Should almost never be used, provided for completeness.
    my $notes                        = $args{-notes};                           # (Scalar) Optional: brief note that may be attached to the primer plate
    my $notify_list                  = $args{-notify_list};                     # (Scalar) Optional: list of emails to be notified on arrival
    my $adapter_index_seq            = $args{-adapter_index_seq};               # (ArrayRef) Optional: array of adapter index sequences
    my $well_notes                   = $args{-well_notes};                      # (ArrayRef) Optional: notes to be appended to the primer plate well
    my $alternate_primer_identifiers = $args{-alternate_primer_identifiers};    # (ArrayRef) Optional: alternate_primer_identifiers to add to primers
    unless ($well_notes) {
        $well_notes = [];
    }

    $dbc ||= $self->{dbc};

    # error checking mostly handled by set_new_primers
    # ERROR CHECKS
    unless ($primer_plate_name) {
        $primer_plate_name = "";
    }
    unless ($sol_id) {
        $sol_id = 0;
    }
    unless ($arrival_date) {
        $arrival_date = "";
    }
    unless ($order_date) {
        $self->error("ERROR: Missing parameter: Order Date");
    }
    unless ($plate_status) {
        $self->error("ERROR: Missing parameter: Primer Plate Status");
    }
    unless ($wells_ref) {
        $self->error("ERROR: Missing parameter: Primer Wells");
    }
    unless ( scalar( @{$primer_names_ref} ) == scalar( @{$wells_ref} ) ) {
        $self->error("ERROR: Invalid parameter: primer names must have the same size as primer wells");
    }
    if ( defined($parent_primerplatewell_ref) ) {
        unless ( scalar( @{$primer_names_ref} ) == scalar( @{$parent_primerplatewell_ref} ) ) {
            $self->error("ERROR: Invalid parameter: primer names must have the same size as parent primer plate well ids");
        }
    }
    else {
        my @empty = ();
        foreach ( @{$primer_names_ref} ) {
            push( @empty, '' );
        }
        $parent_primerplatewell_ref = \@empty;
    }
    if ( $self->error() ) {
        $self->success(0);
        return 0;
    }

    my $new_primer_ids;
    unless ($omit_insertion) {
        $new_primer_ids = $self->set_new_primers(
            -name                         => $primer_names_ref,
            -sequence                     => $primer_sequences_ref,
            -tm_working                   => $tms_working_ref,
            -tm_calc                      => $tm_calc,
            -type                         => $type,
            -direction                    => $direction_ref,
            -amplicon_length              => $amplicon_length_ref,
            -position                     => $position_ref,
            -adapter_index_seq            => $adapter_index_seq,
            -alternate_primer_identifiers => $alternate_primer_identifiers,
        );
        unless ( $self->success() ) {
            return 0;
        }
    }
    my $datetime = &date_time();

    # create the primer plate
    my $primer_plate_id = $dbc->Table_append_array(
        "Primer_Plate",
        [ 'Primer_Plate_Name', "Order_DateTime", "Arrival_DateTime", "Primer_Plate_Status", "FK_Solution__ID", 'Notes', 'Notify_List' ],
        [ $primer_plate_name,  $order_date,      $arrival_date,      $plate_status,         $sol_id,           $notes,  $notify_list ],
        -autoquote => 1
    );
    unless ($primer_plate_id) {
        $self->error("ERROR: Database error: Cannot insert into Primer Plate table");
        $self->success(0);
        return 0;
    }
    my %primer_info;
    my $index = 1;
    foreach my $primer_name ( @{$primer_names_ref} ) {
        $primer_info{$index} = [ $wells_ref->[ $index - 1 ], $primer_name, $primer_plate_id, $parent_primerplatewell_ref->[ $index - 1 ], $well_notes->[ $index - 1 ] ];
        $index++;
    }

    # create the primer plate wells
    $dbc->smart_append( -tables => "Primer_Plate_Well", -fields => [ "Well", "FK_Primer__Name", "FK_Primer_Plate__ID", 'FKParent_Primer_Plate_Well__ID', 'Primer_Plate_Well_Notes' ], -values => \%primer_info, -autoquote => 1 );

    unless ($sol_id) {

        # add solution ID to the primer plate
        $sol_id = $self->generate_solution_id( -stock_name => $stock_name, -primer_plate_id => $primer_plate_id, -organization_id => $organization_id, -emp_id => $emp_id, -source => $source );
        $dbc->Table_update_array( "Primer_Plate", ["FK_Solution__ID"], [$sol_id], "WHERE Primer_Plate_ID=$primer_plate_id" );
    }

    return ( $primer_plate_id, $new_primer_ids );
}

############################################################
# Subroutine: imputs multiple primers to the database
# RETURN: 0 if unsuccessful, or a reference to a list of new ids if successful.
############################################################
sub set_new_primers {
############################################################
    my $self = shift;
    my %args = &filter_input( \@_ );

    # Mandatory Fields #
    my $primer_names_ref                 = $args{-name};                            # (ArrayRef) an array of primer names
    my $primer_sequences_ref             = $args{-sequence};                        # (ArrayRef) an array of primer sequences corresponding to the primer names
    my $tms_working_ref                  = $args{-tm_working};                      # (ArrayRef) Optional: an array of working temperatures. Define either this or the tm calculation string
    my $directions_ref                   = $args{-direction};                       # (ArrayRef) Optional: an array of directions for the primers.
    my $positions_ref                    = $args{-position};                        # (ArrayRef) Optional: an array of position information for primers. One of Nested or Outer.
    my $amplicon_length_ref              = $args{-amplicon_length};                 # (ArrayRef) Optional: an array of amplicon lengths. Only required if at least one primer is an amplicon.
    my $tm_calc                          = $args{-tm_calc};                         # (Scalar) Optional: a string defining the tm calculation. Right now, only supports "MGC Standard".
    my $type_ref                         = $args{-type};                            # (ArrayRef|Scalar) an array of primer types. One of Standard, Custom, or Oligo
    my $dbc                              = $self->{dbc};
    my $adapter_index_seq                = $args{-adapter_index_seq};               # (ArrayRef) Optional: array of adapter index sequences
    my $alternate_primer_identifiers_ref = $args{-alternate_primer_identifiers};    # (ArrayRef) Optional: alternate_primer_identifiers to add to primers

    unless ($primer_names_ref) {
        $self->error("ERROR: Missing parameter: Primer Name");
    }
    unless ($primer_sequences_ref) {
        $self->error("ERROR: Missing parameter: Primer Sequence");
    }
    unless ( $tms_working_ref || $tm_calc ) {
        $self->error("ERROR: Missing parameter: Working temperature or temperature calculator definition");
    }

    unless ($type_ref) {
        $self->error("ERROR: Missing/Incorrect parameter: Primer Type array");
    }

    my @primer_names     = @{$primer_names_ref};
    my @primer_sequences = @{$primer_sequences_ref};

    my @tms_working = ();

    # if working temperatures aren't defined, call the appropriate tm calculator
    if ($tms_working_ref) {
        @tms_working = @{$tms_working_ref};
    }
    else {
        if ( $tm_calc eq "MGC Standard" ) {
            foreach my $sequence (@primer_sequences) {
                my $temp = $self->_calc_temp_MGC_Standard( -sequence => $sequence );
                unless ( $self->success() == 1 ) {
                    return 0;
                }
                push( @tms_working, $temp );
            }
        }
    }

    # check if all arrays are the same size
    my $name_size = @primer_names . "";
    my $seq_size  = @primer_sequences . "";
    my $tms_size  = @tms_working . "";

    unless ( ( $name_size == $seq_size ) && ( $name_size == $tms_size ) ) {
        $self->error("ERROR: Incorrect argument: Primer Name, Sequence, and Temperature arrays should be the same size");
    }

    my @amplicon_length = ();
    my $index           = 0;

    # if the argument is a scalar, parse out into array
    unless ( ref($type_ref) eq 'ARRAY' ) {
        my @array = ();
        foreach ( 1 .. $name_size ) {
            push( @array, $type_ref );
        }
        $type_ref = \@array;
    }

    my @allow_primer_types = $dbc->get_enum_list( 'Primer', "Primer_Type" );
    my $allow_primer_type = join( "|", @allow_primer_types );
    foreach my $type (@$type_ref) {
        unless ( $type =~ /$allow_primer_type/ ) {
            $self->error("ERROR: Incorrect parameter: Primer Type");
        }
        if ( $type =~ /Amplicon/ ) {
            if ( exists $amplicon_length_ref->[$index] ) {
                push( @amplicon_length, $amplicon_length_ref->[$index] );
            }
            else {
                $self->error("ERROR: Missing parameter: Amplicon Length");
                push( @amplicon_length, '' );
            }
        }
        else {
            push( @amplicon_length, '' );
        }
        $index++;
    }

    my $amp_size = @amplicon_length . "";

    unless ( $amp_size == $name_size ) {
        $self->error("ERROR: Incorrect argument: Amplicon size arrays should be the same size");
    }

    my @directions = ();

    # if directions are not defined, define them as 'Unknown'
    if ($directions_ref) {
        my $direction_size = @{$directions_ref};
        unless ( $direction_size == $name_size ) {
            $self->error("ERROR: Incorrect argument: Primer Name and Direction arrays should be the same size");
        }
        @directions = @{$directions_ref};

        # map to Forward or Reverse
        foreach (@directions) {
            if ( $_ eq '5' ) {
                $_ = 'Forward';
            }
            elsif ( $_ eq '3' ) {
                $_ = 'Reverse';
            }
        }
    }
    else {
        foreach ( 1 .. $name_size ) {
            push( @directions, 'Unknown' );
        }
    }

    my @positions = ();

    # if positions are defined, check the sizes
    if ( $positions_ref && ( int( @{$positions_ref} ) > 0 ) ) {
        my $position_size = @{$positions_ref};
        unless ( $position_size == $name_size ) {
            $self->error("ERROR: Incorrect argument: Primer Name and Position arrays should be the same size");
        }
        @positions = @{$positions_ref};

        # map to Forward or Reverse
        foreach (@positions) {
            if ( $_ eq 'O' ) {
                $_ = 'Outer';
            }
            elsif ( $_ eq 'N' ) {
                $_ = 'Nested';
            }
        }
    }

    my @adapter_index_seqs = ();
    if ( $adapter_index_seq && ( int( @{$adapter_index_seq} ) > 0 ) ) {
        my $adapter_index_seq_size = @{$adapter_index_seq};
        unless ( $adapter_index_seq_size == $name_size ) {
            $self->error("ERROR: Incorrect argument: Primer Name and Adapter Index Seq arrays should be the same size");
        }
        @adapter_index_seqs = @{$adapter_index_seq};
    }

    my @alternate_primer_identifiers = ();
    if ( $alternate_primer_identifiers_ref && ( int( @{$alternate_primer_identifiers_ref} ) > 0 ) ) {
        my $alternate_primer_identifiers_ref_size = @{$alternate_primer_identifiers_ref};
        unless ( $alternate_primer_identifiers_ref_size == $name_size ) {
            $self->error("ERROR: Incorrect argument: Primer Name and Adapter Index Seq arrays should be the same size");
        }
        @alternate_primer_identifiers = @{$alternate_primer_identifiers_ref};
    }

    # check if name already exists

    foreach my $p_name (@primer_names) {
        $self->value( 'Primer_Name', $p_name );
        my @retval = $dbc->Table_find( 'Primer', 'Primer_ID', "where Primer_Name='$p_name'" );
        if ( $retval[0] =~ /d+/ ) {
            $self->error("ERROR: Integrity problem: Primer Name $p_name already exists in database with Primer ID $retval[0]");
        }
    }

    # done error checking. If there is an error, break
    if ( $self->error() ) {
        $self->success(0);
        return 0;
    }

    # fill information for Primer
    # add in Position information if they are defined
    my %primer_info;
    my $counter = 1;
    foreach my $name (@primer_names) {
        $primer_info{$counter} = [ $name, $primer_sequences[ $counter - 1 ], $tms_working[ $counter - 1 ], $type_ref->[ $counter - 1 ], $name, $directions[ $counter - 1 ], $amplicon_length[ $counter - 1 ] ];
        if ( int(@positions) > 0 ) {
            push( @{ $primer_info{$counter} }, $positions[ $counter - 1 ] );
        }
        if ( int(@adapter_index_seqs) > 0 ) {
            push( @{ $primer_info{$counter} }, $adapter_index_seqs[ $counter - 1 ] );
        }
        if ( int(@alternate_primer_identifiers) > 0 ) {
            push( @{ $primer_info{$counter} }, $alternate_primer_identifiers[ $counter - 1 ] );
        }
        $counter++;
    }

    my @fields = ( 'Primer_Name', 'Primer_Sequence', 'Tm_Working', 'Primer_Type', 'FK_Primer__Name', 'Direction', 'Amplicon_Length' );
    if ( int(@positions) > 0 ) {
        push( @fields, 'Position' );
    }
    if ( int(@adapter_index_seqs) > 0 ) {
        push( @fields, 'Adapter_Index_Sequence' );
    }
    if ( int(@alternate_primer_identifiers) > 0 ) {
        push( @fields, 'Alternate_Primer_Identifier' );
    }

    my %retval = %{ $dbc->smart_append( -tables => 'Primer,Primer_Customization', -fields => \@fields, -values => \%primer_info, -format => 'hash', -autoquote => 1 ) };

    my @primer_ids = @{ $retval{Primer}->{newids} };

    if ( scalar(@primer_ids) != scalar(@primer_names) ) {
        $self->error( "ERROR: Database error: Inserted " . scalar(@primer_ids) . " primers in database, expected " . scalar(@primer_names) );
        $self->success(0);
        return 0;
    }

    $self->success(1);
    return \@primer_ids;
}

############################################################
# Function: changes the Notes field of an existing Primer Plate
# RETURN: 1 if successful, 0 otherwise
############################################################
sub set_notes {
############################################################
    my $self            = shift;
    my %args            = &filter_input( \@_, -args => 'primer_plate_id,notes', -mandatory => 'primer_plate_id,notes' );
    my $primer_plate_id = $args{-primer_plate_id};                                                                         # (Scalar) The ID of the primer plate
    my $notes           = $args{-notes};                                                                                   # (Scalar) The new value of the notes field

    my $dbc = $self->{dbc};

    ## Error Check ##
    unless ($primer_plate_id) {
        $self->error("ERROR: Missing argument: -primer_plate_id is missing");
        $self->success(0);
        return 0;
    }
    my @id = $dbc->Table_find( "Primer_Plate", "Primer_Plate_ID", "WHERE Primer_Plate_ID = $primer_plate_id" );
    unless ( int(@id) > 0 ) {
        $self->error("ERROR: Invalid Argument: -primer_plate_id ($primer_plate_id) does not exist");
        $self->success(0);
        return 0;
    }

    my $ok = &Table_update_array( $dbc, "Primer_Plate", ['Notes'], [$notes], "WHERE Primer_Plate_ID = $primer_plate_id", -autoquote => 1 );
    unless ($ok) {
        $self->error("ERROR: Database error: Cannot modify Primer Plate $primer_plate_id");
        $self->success(0);
        return 0;
    }
    $self->success(1);
    return 1;
}

##############################
# public_functions           #
##############################
###################
sub list_Primers {
###################
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $library         = $args{-library};
    my $project         = $args{-project};
    my $library_type    = $args{-type};
    my $primer          = $args{-primer};
    my $extra_condition = $args{-condition} || 1;

    my $tables    = 'Project,Library';
    my $condition = "WHERE FK_Project__ID=Project_ID";

    if ($project) {
        $extra_condition .= " AND Project_Name = '$project'";
    }
    if ($library_type) {

        #$tables .= ",Vector_Based_Library";
        #$condition .= " AND Vector_Based_Library.FK_Library__Name=Library_Name";
        $tables          .= " LEFT JOIN Vector_Based_Library ON Vector_Based_Library.FK_Library__Name=Library_Name";
        $extra_condition .= " AND (Vector_Based_Library_Type = '$library_type' OR Library_Type = '$library_type')";
    }

    if ($library) {
        my $lib_list = Cast_List( -list => $library, -to => 'string', -autoquote => 1 );
        $extra_condition .= " AND Library_Name IN ($lib_list)";
    }
    if ($primer) {
        $extra_condition .= " AND Primer_Name LIKE '$primer'";
    }

    my $admin  = 0;
    my $access = $dbc->get_local('Access');
    if ( ( grep {/Admin/xmsi} @{ $access->{ $dbc->config('Target_Department') } } ) || $access->{'LIMS Admin'} ) {
        $admin = 1;
    }

    my $all    = param('Include All Primers');                                      ### allow viewing of unused primers
    my $output = h1('Valid Primers <I>(possible options based upon Vector)</I>');
    ## Valid primers ##
    #    $output .= &Link_To($homelink,'Add',"&LibraryApplication=1&FK_Library__Name=$library&Object_Class=Primer") if $library;
    if ($admin) {
        $output .= create_tree(
            -tree  => { "New Valid Primer" => validate_Primer( -library => $library, -navigator_on => 0 ) },
            -print => 0
        );
    }

    $output .= &Table_retrieve_display(
        $dbc, "$tables,Primer,LibraryVector,Vector,Vector_Type,Vector_TypePrimer", [ 'Library_Name', 'Primer_Name', 'Primer_Sequence', 'Vector_Type_Name' ],
        "$condition AND FK_Primer__ID=Primer_ID  AND Vector_TypePrimer.FK_Vector_Type__ID=Vector.FK_Vector_Type__ID AND Vector_Type_ID = Vector.FK_Vector_Type__ID AND LibraryVector.FK_Vector__ID=Vector_ID AND LibraryVector.FK_Library__Name=Library_Name AND $extra_condition",
        -return_html      => 1,
        -toggle_on_column => 1
    ) if $extra_condition ne '1';

    ## Suggested primers ##
    $output .= h1('Suggested Primers <I>(suggested options based upon Library)</I>');

    #    $output .= &Link_To($homelink,'Add',"&LibraryApplication=1&FK_Library__Name=$library&Object_Class=Primer") if $library;
    if ($admin) {
        $output .= create_tree(
            -tree  => { "Suggest New Primer" => suggest_Primer( -library => $library, -navigator_on => 0 ) },
            -print => 0
        );
    }

    $output .= &Table_retrieve_display(
        $dbc, "$tables,Primer,LibraryApplication,Object_Class", [ 'Library_Name', 'Primer_Name', 'Primer_Sequence', 'Direction' ],
        "$condition AND LibraryApplication.Object_ID=Primer_ID AND LibraryApplication.FK_Library__Name=Library_Name AND FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Primer' AND $extra_condition",
        -return_html      => 1,
        -toggle_on_column => 1
    ) if $extra_condition ne '1';

    return $output;
}

#####################
sub suggest_Primer {
#####################
    my %args               = &filter_input( \@_ );
    my $library            = $args{-library};
    my $object_class       = 'Primer';
    my $dbc                = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $navigator_on       = $args{-navigator_on};
    my @application_values = $dbc->Table_find( "LibraryVector,Vector,Vector_TypePrimer,Primer",
        "Primer_Name", "WHERE Vector_TypePrimer.FK_Vector_Type__ID=Vector.FK_Vector_Type__ID and FK_Primer__ID = Primer_ID and Vector_ID = LibraryVector.FK_Vector__ID AND FK_Library__Name = '$library'" );

    my %list;
    my %grey;
    $grey{'LibraryApplication.FK_Object_Class__ID'} = $object_class;

    #    $list{'LibraryApplication.Direction'} = &get_enum_list($dbc,'LibraryApplication',"Direction");
    $list{'LibraryApplication.Object_ID'}        = \@application_values;
    $grey{'LibraryApplication.FK_Library__Name'} = $library;

    my $suggest_form = SDB::DB_Form->new( -dbc => $dbc, -table => 'LibraryApplication', -target => 'Database' );
    $suggest_form->configure( -list => \%list, -grey => \%grey );
    return $suggest_form->generate( -title => "Suggest $object_class for Library", -form => 'LibraryApplication', -return_html => 1, -mode => 'Normal', -navigator_on => $navigator_on );
}

######################
sub validate_Primer {
######################
    my %args         = &filter_input( \@_ );
    my $library      = $args{-library};
    my $object_class = 'Primer';

    my $filter_table = "Vector_TypePrimer";
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $navigator_on = $args{-navigator_on};

    my %list;
    my %grey;
    $grey{'LibraryApplication.FK_Object_Class__ID'} = $object_class;
    $list{'LibraryApplication.Direction'} = $dbc->get_enum_list( 'LibraryApplication', "Direction" );

    #    $list{'LibraryApplication.Object_ID'} = \@application_values;
    $grey{'LibraryApplication.FK_Library__Name'} = $library;

    my $valid_form = SDB::DB_Form->new( -dbc => $dbc, -table => $filter_table, -target => 'Database' );

    #print HTML_Dump \@valid_library_values;

    my @valid_vector = $dbc->Table_find( "LibraryVector,Vector,Vector_Type", "Vector_Type_Name", "WHERE Vector.FK_Vector_Type__ID = Vector_Type_ID and FK_Library__Name = '$library' and FK_Vector__ID = Vector_ID" );
    $list{'FK_Vector_Type__ID'} = \@valid_vector;

    #my @valid_list = $dbc->Table_find( $tables, "$object_name", "WHERE $fk_object_class_field = $object_id $filter_condition ORDER BY $object_name",-distinct=>1);
    $grey{"$filter_table.FK_Library__Name"} = $library;

    #$list{$fk_object_class_field} = \@valid_list;
    $valid_form->configure( -list => \%list, -grey => \%grey );
    return $valid_form->generate( -title => "Valid $object_class for Library", -form => 'Valid_Primer', -return_html => 1, -navigator_on => $navigator_on );
}

#
#
# PHASE OUT
#
######################
sub new_Chem_Code {
######################
    my %args    = &filter_input( \@_ );
    my $library = $args{-library};
    my $primer  = $args{-primer};

    my $filter_table = "Chemistry_Code";                                                       ## phased out already
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    Call_Stack();                                                                              ## this method is phased out - delete after 2.42  ##

    my %list;
    my %grey;

    my $condition = 1;

    my $valid_form = SDB::DB_Form->new( -dbc => $dbc, -table => $filter_table, -target => 'Database' );

    my @list = &get_FK_info( $dbc, 'FK_Primer__Name', -list => 1, -condition => "Primer_Type = 'Standard'" );
    $list{'FK_Primer__Name'} = \@list;

    $grey{"$filter_table.FK_Primer__Name"} = $primer if $primer;
    $valid_form->configure( -list => \%list, -grey => \%grey );

    return $valid_form->generate( -title => "Defining New Chemistry Code", -form => 'Chem_Code', -return_html => 1 );

}

#########
sub get_db_object {
#########
    my $self      = shift;
    my %args      = @_;
    my $dbc       = $args{-dbc};
    my $primer_id = $args{-id};

    my $db_obj = SDB::DB_Object->new( -dbc => $dbc );
    $db_obj->add_tables('Primer');
    $db_obj->{primer_id} = $primer_id;
    $db_obj->primary_value( -table => 'Primer', -value => $primer_id );    ## same thing as above..
    $db_obj->load_Object( -type => 'Primer' );

    return $db_obj;
}

############################################################
# Subroutine: takes in primer plate ids and create stock and solution records for each well of the primer plates and delete the primer plates
# RETURN: 0 if unsuccessful, or 1 if successful. Also print out barcodes
############################################################
sub receive_primer_plate_as_tubes {
    my $self                = shift;
    my %args                = &filter_input( \@_, -args => 'primer_plate_ids', -mandatory => 'primer_plate_ids' );
    my $dbc                 = $self->{dbc};
    my $primer_plate_ids    = $args{-primer_plate_ids};
    my $org_name            = $args{-org_name};
    my $delete_primer_plate = $args{-delete_primer_plate};
    my $user_id             = $dbc->get_local('user_id');

    ( my $org_id ) = $dbc->Table_find( 'Organization', 'Organization_ID', " WHERE Organization_Name = '$org_name'" );

    $primer_plate_ids = Cast_List( -list => $primer_plate_ids, -to => 'string' );
    if ($Sess) {
        $dbc->message("Finding Primer Infomation for each well of the primer plate $primer_plate_ids");
    }

    my %primers = $dbc->Table_retrieve(
        "Primer_Plate,Primer_Plate_Well LEFT JOIN Stock_Catalog ON Stock_Catalog_Name = FK_Primer__Name AND FK_Organization__ID = $org_id",
        [ 'Primer_Plate_ID', 'FK_Primer__Name', 'Well', 'Stock_Catalog_ID', 'Primer_Plate_Well_Notes' ],
        "WHERE FK_Primer_Plate__ID = Primer_Plate_ID AND Primer_Plate_ID IN ($primer_plate_ids)"
    );

    #print Dumper %primers;

    my $index = -1;
    while ( defined $primers{Primer_Plate_ID}[ ++$index ] ) {
        my $primer_plate_id  = $primers{Primer_Plate_ID}[$index];
        my $primer_name      = $primers{FK_Primer__Name}[$index];
        my $well             = $primers{Well}[$index];
        my $stock_catalog_id = $primers{Stock_Catalog_ID}[$index];
        my $p_solution_id    = $primers{Solution_ID}[$index];
        my $p_stock_id       = $primers{Stock_ID}[$index];
        my $label            = $primers{Primer_Plate_Well_Notes}[$index];
        $dbc->message("Primer_Plate: $primer_plate_id, Well: $well, Primer: $primer_name");

        #next;
        if ( !$stock_catalog_id ) {

            #no stock catalog record for it, need to create new one
            my $stock_catalog_name         = $primer_name;
            my $stock_catalog_type         = 'Primer';
            my $stock_catalog_source       = 'Order';
            my $stock_catalog_status       = 'Active';
            my $stock_catalog_size         = 1;
            my $stock_catalog_size_unit    = 'tubes';
            my $stock_catalog_manufacturer = $org_id;        #$dbc->Table_find("Organization","Organization_ID","WHERE Organization_Name = '$type'");
            my $stock_catalog_vendor       = "";

            my $stock_catalog_fields = [ 'Stock_Catalog_Name', 'Stock_Type', 'Stock_Source', 'Stock_Status', 'Stock_Size', 'Stock_Size_Units', 'FK_Organization__ID' ];    # FK_Organization__ID, FKVendor_Organization__ID
            my $stock_catalog_values = [ $stock_catalog_name, $stock_catalog_type, $stock_catalog_source, $stock_catalog_status, $stock_catalog_size, $stock_catalog_size_unit, $stock_catalog_manufacturer ];
            my $catalog_item = alDente::Stock->new( -dbc => $dbc );
            $stock_catalog_id = $catalog_item->save_catalog_info( -dbc => $dbc, -fields => $stock_catalog_fields, -values => $stock_catalog_values, -type => $stock_catalog_type );
        }

        #stock fields: Stock_Catalog = above
        my $stock_number_in_batch = 1;
        my $stock_group           = $dbc->Table_find( "Grp", "Grp_ID", "WHERE Grp_Name = 'Cap_Seq Production'" );
        my $stock_received        = &today();                                                                                                                              #today
        my $stock_employee        = $user_id;                                                                                                                              #global
        my ($stock_barcode) = $dbc->Table_find( "Barcode_Label", "Barcode_Label_ID", "WHERE Label_Descriptive_Name='2D Tube Solution Labels'" );

        my $stock_fields = [ 'Stock_Number_in_Batch', 'FK_Grp__ID', 'Stock_Received', 'FK_Employee__ID', 'FK_Barcode_Label__ID', 'FK_Stock_Catalog__ID' ];
        my $stock_values = [ $stock_number_in_batch, $stock_group, $stock_received, $stock_employee, $stock_barcode, $stock_catalog_id ];

        #solution fields:
        my $solution_type      = ['Primer'];
        my $solution_rack      = ['1'];                                                                                                                                    #R1
        my $solution_number    = ['1'];
        my $solution_qc_status = ['N/A'];
        my $solution_status    = ['Unopened'];

        my $solution_fields = [ 'Solution_Type', 'FK_Rack__ID', 'Solution_Number', 'Solution_Number_in_Batch', 'QC_Status', 'Solution_Status', 'Solution_Label', 'FK_Stock__ID', 'FK_Solution_Info__ID' ];
        my $solution_values = [ [$solution_type], [$solution_rack], [$solution_number], [ [$stock_number_in_batch] ], [$solution_qc_status], [$solution_status], [ [$label] ] ];

        #print HTML_Dump $solution_fields;
        #print HTML_Dump $solution_values;

        my $primer_fields = ['Solution_Info_ID'];
        my $primer_values = [ [ [] ] ];

        #print HTML_Dump $primer_values;

        # saving the information
        my $stock_item = alDente::Stock->new( -dbc => $dbc );

        my $id_list = $stock_item->save_stock_info(
            -dbc      => $dbc,
            -type     => 'Primer',
            -category => 'Solution',
            -fields   => $solution_fields,
            -values   => $solution_values,
            -s_fields => $stock_fields,
            -s_values => $stock_values,
            -p_fields => $primer_fields,
            -p_values => $primer_values,
        );

        # print the barcodes
        #next;
        $dbc->session->message("solution $id_list created") if $dbc->session;
        my $option;
        $option = "Solution_Label" if $label;
        $stock_item->print_stock_barcodes( -dbc => $dbc, -category => 'Solution', -id_list => $id_list, -option => $option );
    }

    #delete Primer_Plate
    if ($delete_primer_plate) {
        my %primers = $dbc->Table_retrieve( 'Primer_Plate,Solution,Stock', [ 'Primer_Plate_ID', 'Solution_ID', 'Stock_ID' ], "WHERE Primer_Plate_ID IN ($primer_plate_ids) AND FK_Solution__ID = Solution_ID AND FK_Stock__ID = Stock_ID" );
        $index = -1;
        while ( defined $primers{Primer_Plate_ID}[ ++$index ] ) {
            my $primer_plate_id = $primers{Primer_Plate_ID}[$index];
            my $p_solution_id   = $primers{Solution_ID}[$index];
            my $p_stock_id      = $primers{Stock_ID}[$index];
            if ($Sess) {
                $dbc->message("Deleting Primer_Plate: $primer_plate_id, Solution: $p_solution_id, Stock: $p_stock_id");
            }

            #next;
            my $ok = $dbc->delete_records( -table => 'Primer_Plate', -field => 'Primer_Plate_ID', -id_list => $primer_plate_ids, -cascade => get_cascade_tables('Primer_Plate'), -quiet => 0 );
            my $ok = $dbc->delete_records( -table => 'Solution',     -field => 'Solution_ID',     -id_list => $p_solution_id,    -quiet                                                 => 0 );
            my $ok = $dbc->delete_records( -table => 'Stock',        -field => 'Stock_ID',        -id_list => $p_stock_id,       -quiet                                                 => 0 );
        }
    }
}

#
# To run whenever new standard primer record is added
#
# Return 1 on success
# Note this method is only applicable for standard primers, it will just exit if the primer being added is not type of standard
###########################
sub new_Primer_trigger {
###########################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my ($id) = $dbc->Table_find( 'Primer', 'Max(Primer_ID)' );
    my $ok;
    require alDente::Vector;
    my ($primer_info) = $dbc->Table_find( 'Primer', 'Primer_Type,Primer_Name', "WHERE Primer_ID = $id" );
    my ( $primer_type, $primer_name ) = split ',', $primer_info;

    if ( $primer_type eq 'Standard' ) {
        my @vector_names = $dbc->Table_find( 'Vector_Type', 'Vector_Type_Name', "WHERE Vector_Sequence is not NULL and Vector_Sequence <> ''" );
        for my $vector_name (@vector_names) {
            my $vector = new alDente::Vector( -dbc => $dbc, -name => $vector_name );
            my @valid_primers = $vector->find_tags( -type => 'Primer', -complement => 1, -name => $primer_name, -quiet => 1 );
            if ( $valid_primers[0] eq $primer_name ) {
                $ok = $vector->validate_Primer( -primer_name => $primer_name );    ## add to Vector_TypePrimer table
                if ($ok) { Message "Validated vector ($vector_name) for primer ($primer_name)" }
            }
        }
        if   ($ok) { Message "Validation successful!" }
        else       { Message "Failed to find any vectors to match primer sequence" }
    }
    else {
        return 1;
    }
    return $ok;

}

##############################
# private_methods            #
##############################

############################################################
# Subroutine: takes a string that represents a primer sequence and calculates the temperature
# RETURN: 0 if unsuccessful, or the working temperature of the primer otherwise.
############################################################
sub _calc_temp_MGC_Standard {
    my $self     = shift;
    my %args     = @_;
    my $sequence = $args{-sequence};

    # do temperature calculation
    # MGC Standard - provided by Anca Petrescu
    my @sequence_array = split( //, $sequence );
    my $sequence_length = scalar(@sequence_array);
    unless ( $sequence_length > 0 ) {
        $self->error("ERROR: Invalid argument: Zero length sequence");
        $self->success(0);
        return 0;
    }
    my $num_G = 0;
    my $num_C = 0;
    foreach my $base (@sequence_array) {
        if ( $base eq 'G' || $base eq 'g' ) {
            $num_G++;
        }
        elsif ( $base eq 'C' || $base eq 'c' ) {
            $num_C++;
        }
    }
    my $Na = 0.1;
    my $GC = ( $num_G / $sequence_length + $num_C / $sequence_length );
    my $Tm = 81.5 + 41 * ($GC) - 500 / $sequence_length + 16.6 * log10($Na);
    $Tm = $Tm - 7;

    $self->success(1);
    return $Tm;
}

############################################################
# Subroutine: orders a single primer.
# RETURN: 0 if unsuccessful, or Primer_ID if successful
############################################################
######################
sub _get_primer_organizations {
######################
    my %args = @_;
    my $dbc  = $args{-dbc};

    my @org_ids = $dbc->Table_find( 'Organization,Stock_Catalog', 'Organization_ID', " WHERE (FK_Organization__ID = Organization_ID or FKVendor_Organization__ID = Organization_ID) and Stock_Type = 'Primer' ", 'distinct' );
    return join ',', @org_ids;
}

######################
sub _set_new_primer {
######################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};

    # Mandatory Fields #
    my $primer_name     = $args{-name};
    my $primer_sequence = $args{-sequence};
    my $tm_working      = $args{-tm_working};

    # error checking
    unless ($primer_name) {
        $self->error("ERROR: Missing parameter: Primer Name");
    }
    unless ($primer_sequence) {
        $self->error("ERROR: Missing parameter: Primer Sequence");
    }
    unless ($tm_working) {
        $self->error("ERROR: Missing parameter: Working temperature");
    }

    # chomp all spaces in primer sequence(to be added)
    # check if primer sequence only has valid letters (ACTGU) (to be added)

    # done error checking. If there is an error, break
    if ( $self->error() ) {
        $self->success(0);
        return 0;
    }

    # append to database
    $self->value( "Primer_Name",     $primer_name );
    $self->value( "Primer_Sequence", $primer_sequence );
    $self->value( "Tm_Working",      $tm_working );

    my %rethash = %{ $self->insert() };
    if ( $rethash{error} ne '' ) {
        $self->error("ERROR: Database Error: $rethash{error}");
        $self->success(0);
        return 0;
    }
    $self->success(1);
    return $rethash{id};
}

######################
sub delete_Primer {
######################
    # Also deletes from Primer_Customization and Stock_Catalog table if Applicable
######################
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};
    my $name = $args{-name};
    my $error;
    my ($stock) = $dbc->Table_find( 'Stock_Catalog,Stock', 'count(Stock_ID)', " WHERE Stock_Catalog_Name = '$name' and FK_Stock_Catalog__ID = Stock_Catalog_ID" );
    if ($stock) {
        Message "Cannot delete primer $name because there are $stock items pointing to its catalog record";
    }
    else {
        my ($primer_id)  = $dbc->Table_find( 'Primer',               'Primer_ID',               " WHERE Primer_Name = '$name' " );
        my (@custom_ids) = $dbc->Table_find( 'Primer_Customization', 'Primer_Customization_ID', " WHERE FK_Primer__Name = '$name' " );
        my ($stock_cat)  = $dbc->Table_find( 'Stock_Catalog',        'Stock_Catalog_ID',        " WHERE Stock_Catalog_Name = '$name'" );
        my $custom_list = join ',', @custom_ids;

        my $ok = $dbc->delete_records( -table => 'Primer', -id_list => $primer_id, -quiet => 1 );
        unless ($ok) { $error = 1 }

        $ok = $dbc->delete_records( -table => 'Primer_Customization', -id_list => $custom_list, -quiet => 1 ) if $custom_list;
        if ( !$ok && $custom_list ) { $error = 1 }

        my $ok = $dbc->delete_records( -table => 'Stock_Catalog', -id_list => $stock_cat, -quiet => 1 ) if $stock_cat;

    }

    if ($error) {
        Message "problem while deleting primer $name";
        return;
    }
    else {
        Message "-- deleted primer $name --";
    }
    return 1;
}

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

2003-09-26

=head1 REVISION <UPLINK>

$Id: Primer.pm,v 1.35 2004/12/03 20:02:42 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
