################################################################################
#
# Rack.pm
#
# This module handles Rack Functions (moving & locating stuff)
#
################################################################################
# $Id: Rack.pm,v 1.38 2004/11/25 01:43:41 echuah Exp $
################################################################################
# CVS Revision: $Revision: 1.38 $
#     CVS Date: $Date: 2004/11/25 01:43:41 $
###############################################################################

package alDente::Rack;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Rack.pm - This module handles Rack Functions (moving & locating stuff)

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Rack Functions (moving & locating stuff)<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter  SDB::DB_Object);
use vars qw(%Configs %Prefix);
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    Move_Racks
    move_Items
    add_rack
    Update_Rack_Info
);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:standard);
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use RGTools::HTML_Table;
use RGTools::Conversion;
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Form;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Container;
use alDente::Tools;
use alDente::Rack_Views;
use alDente::Validation;
##############################
# global_vars                #
##############################
my $BS = new Bootstrap();
use vars qw(%Settings $Sess @locations $Connection %Prefix);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

##############################
# constructor                #
##############################
##############################
# constructor                #
##############################
##########
sub new {
##########
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = @_;
    my $id   = $args{-id};
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $retrieve = $args{-retrieve};
    my $verbose  = $args{-verbose};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => ['Rack'] );

    bless $self, $class;

    if ($id) {
        $self->{id} = $id;
        $self->primary_value( -table => 'Rack', -value => $id );
        $self->load_Object();
    }

    $self->{dbc}     = $dbc;
    $self->{records} = 0;      ## number of records currently loaded
    return $self;
}

# Simple accessor to garbage rack
#
# Return: ID of garbage location
##############
sub garbage {
##############
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    if ( !$self->{garbage} ) {
        my ($garbage_rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_ALias IN ('Garbage', 'Garbage Rack')" );
        $self->{garbage} = $garbage_rack;
    }

    return $self->{garbage};
}

##############################
# public_methods             #
##############################

#
# Accessor to simplify SQL queries requiring ordering by Row, Column or ID (Rack_ID).
#
#
# eg.  $dbc->Table_find('Rack','Rack_Name','ORDER BY ' . SQL_Slot_order('Row') );
#
# Assumptions:  applicable Rack object (containing slot name) is called 'Rack'
#
# Return: SQL query for ordering
#####################
sub SQL_Slot_order {
#####################
    my $order          = shift;
    my $include_parent = shift;

    my $desc = '';
    if ( $order =~ /^(\w+)sDESC/i ) {
        $desc  = ' DESC';
        $order = $1;
    }
    my $parent;
    if ($include_parent) { $parent = 'FKParent_Rack__ID, ' }

    my %Order_by;
    $Order_by{'row'}    = $parent . "Left(Rack.Rack_Name,1), 1*(Mid(Rack.Rack_Name,2,3))";
    $Order_by{'column'} = $parent . "1*(Mid(Rack.Rack_Name,2,3)), LEFT(Rack.Rack_Name,1)";
    $Order_by{'id'}     = $parent . 'Rack.Rack_ID';

    if ( !defined $Order_by{ lc($order) } ) { Message("Warning:'$order' Order not defined") }

    return $Order_by{ lc($order) } . $desc;
}

# Return: 1 if rack indicated is in transit
###################
sub in_transit {
###################
    my %args    = filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc     = $args{-dbc};
    my $rack_id = $args{-rack_id};
    my $quiet   = $args{-quiet};

    my @in_transit = $dbc->Table_find_array(
        'Rack,Equipment,Location,Site LEFT JOIN Shipment ON Shipment.FKTransport_Rack__ID=Rack_ID',
        [ 'Count(*)', 'Shipment_ID' ],
        "WHERE FK_Equipment__ID=Equipment_ID AND FK_Location__ID = Location_ID AND FK_Site__ID=Site_ID AND Location_Name = 'In Transit' AND Rack_ID='$rack_id' AND Shipment_Status like 'Sent'",
        -group_by => 'Rack_ID,Shipment_ID',
        -order_by => 'Shipment_ID DESC'
    );

    if ( int(@in_transit) > 1 ) {
        $dbc->warning("Warning - multiple shipments tied to same transport rack - using most recent Shipment") unless $quiet;
    }

    my ( $transit_racks, $shipment_id );
    if ( $in_transit[0] ) {
        ( $transit_racks, $shipment_id ) = split ',', $in_transit[0];
#        $dbc->message( alDente_ref( 'Rack', $rack_id, -dbc => $dbc ) . ' is in transit' ) unless $quiet;
    }

    return ( $transit_racks, $shipment_id );
}

##############################
# public_functions           #
##############################

#####################
sub compare_Well {
#####################
    my $first  = shift;
    my $second = shift;
    my $row_a;
    my $row_b;
    my $col_a;
    my $col_b;

    if ( $first =~ /^([a-z]|[A-Z]+)(\d+)$/ ) {
        $row_a = $1;
        $col_a = $2;
    }
    if ( $second =~ /^([a-z]|[A-Z]+)(\d+)$/ ) {
        $row_b = $1;
        $col_b = $2;
    }

    ######## Begin Comparison
    if ( $row_a gt $row_b ) {
        return -1;
    }
    elsif ( $row_a lt $row_b ) {
        return 1;
    }
    elsif ( $row_a eq $row_b ) {
        if ( $col_a > $col_b ) {
            return -1;
        }
        elsif ( $col_a < $col_b ) {
            return 1;
        }
        else {
            return 0;
        }
    }
    return 0;
}

#########################
sub reverse_Prefix {
#########################
    my $dbc = shift;
    my $tables = shift;
    my %rev_prefix;

    my %Prefix = %{ $dbc->barcode_prefix };
    
    foreach my $pref ( keys %Prefix ) {
        if ( !$tables || ( grep /^$pref$/i, @$tables ) ) {
            $rev_prefix{ $Prefix{$pref} } = $pref;
        }
    }
    return %rev_prefix;
}

#############################
sub validate_rack_condition {
############################
    my %args      = &filter_input( \@_, -args => 'dbc,rack_id,barcode' );
    my $dbc       = $args{-dbc};
    my $condition = $args{-condition};

    my $rack_equipment_cateogries = "'Freezer','Storage'";    ## The categories of equipment which are concidered long term storages for racks
    ( my $approved_condition ) = $dbc->Table_find( 'Equipment_Category', 'Sub_Category', "WHERE Category IN ($rack_equipment_cateogries) and Sub_Category = '$condition'" );
    if   ($approved_condition) { return $approved_condition }
    else                       { return '' }

}

#############################
sub get_all_rack_conditions {
#############################
    my %args                      = &filter_input( \@_ );
    my $dbc                       = $args{-dbc};
    my $blank                     = $args{-blank};                                                                                                            ## doesn't return other (used for sql conditions)
    my $rack_equipment_cateogries = "'Freezer','Storage'";                                                                                                    ## The categories of equipment which are concidered long term storages for racks
    my @conditions                = $dbc->Table_find( 'Equipment_Category', 'Sub_Category', "WHERE Category IN ($rack_equipment_cateogries)", 'distinct' );
    if ($blank) {
        push @conditions, '';
    }
    else {
        push @conditions, 'Other';
    }
    return \@conditions;

}

#############################
sub display_content_move_warning {
#############################
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $source = $args{-source};
    my $target = $args{-target};

    my $source_slots = $dbc->Table_find( 'Rack', 'Rack_ID', " WHERE FKParent_Rack__ID IN ($source) AND Rack_Type = 'Slot'" ) if $source;
    my $target_slots = $dbc->Table_find( 'Rack', 'Rack_ID', " WHERE FKParent_Rack__ID IN ($target) AND Rack_Type = 'Slot'" ) if $target;

    if ( $source_slots && !$target_slots ) {
        $dbc->warning("You are moving box content from a slotted box ($source) to an unslotted box ($target)");
    }

    return;
}

#############################
sub get_stored_material_types {
############################
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $include_self = $args{-include_self};

    my @types = $dbc->Table_find( 'DBField', "Field_Table", "WHERE Field_Name LIKE 'FK_Rack__ID'" );
    if ($include_self) {
        push @types, 'Rack';
        push @types, 'Equipment';
    }
    return @types;

}

#############################
sub get_rack_equipment_storage_list {
############################
    my %args         = &filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $return_names = $args{-return_info};
    my @info;
    my $rack_equipment_cateogries = "'Freezer','Storage'";                                                  ## The categories of equipment which are concidered long term storages for racks
    my @equipment                 = $dbc->Table_find( 'Stock_Catalog,Stock,Equipment,Equipment_Category',
        'Equipment_ID', "WHERE Category IN ($rack_equipment_cateogries) AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID= Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID" );
    if ($return_names) {
        for my $id (@equipment) {
            my $info = $dbc->get_FK_info( 'FK_Equipment__ID', $id );
            push @info, $info;
        }
        return \@info;
    }
    else {
        return \@equipment;
    }
}

#############################
sub get_default_rack {
#############################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc' );
    my $dbc = $args{-dbc};

    my ($default_rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "where Rack_Name = 'Temporary' LIMIT 1" );

    return $default_rack;
}

#############################
sub get_rack_parameter {
#############################
    my $name = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $param = get_Table_Param( -field => $name, -dbc => $dbc );

    if ( $param =~ /$Prefix{Rack}(\d+)/i ) { $param = $1 }

    return $param;
}

###########################
sub get_Object_slots {
###########################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->{dbc};    ## database connection
    my $object = $args{-object};
    my $ids    = $args{-ids};
    my ($primary) = $dbc->get_field_info( $object, undef, 'PRI' );

    my @results = $dbc->Table_find( "Rack, $object", 'Rack_Name', "WHERE Rack_Type = 'Slot' AND FK_Rack__ID = Rack_ID AND $primary IN ($ids) ORDER BY Rack_ID");
    my $list = join ',', @results;

    return $list;
}

#
#
# get slots in a rack
# - Assumes items in rack may include:
# * Plate/Tube items
# * Source items
# * Solution items
#
# return array ref of slot names
#
###########################
sub get_slots {
###########################
    my $self         = shift;
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    ## database connection
    my $rack_id      = $args{-rack_id} || $self->{id};                                                   ## rack id (box rack id)
    my $empty_only   = $args{-empty_only};                                                               ## if only count empty slots
    my $order        = $args{-order} || "row,column";                                                    ## order by 'colunm,row' or 'row,column'
    my $check_number = $args{-prefill_count};                                                            ## number of slots to prefill. if this is specified, a warning will be displayed if any of the first $check_number slots are occupied.
    my $exclude      = $args{-exclude};                                                                  ## optional list of slots to exclude (may be filled with other items)...
    my $blank        = $args{-blank};                                                                    ## include blank option at top of list for default dropdown menus
    my $dir          = $args{-direction} || 'ASC';                                                       ## Order direction (default to ASCending order)
    my $count        = $args{-count};
    my $debug        = $args{-debug};

    if ( $self->{available_slots}{$rack_id} ) { return $self->{available_slots}{$rack_id} }
    my $condition = "where FKParent_Rack__ID = $rack_id ";

    my $column_order = "ABS(RIGHT(Rack_Name,Length(Rack_Name)-1))";                                      ## colunm: 1,2,3 ...
    my $row_order    = "LEFT(Rack_Name,1)";                                                              ## row: a,b,c ...

    if ($exclude) {
        $exclude = extract_range($exclude);
        $exclude =~ s/([A-Za-z])0*(\d+)/$1$2/g;                                                          ## remove leading zero
        my $exclusion_list = Cast_List( -list => $exclude, -to => 'string', -autoquote => 1 );
        $condition .= " AND Rack_Name NOT IN ($exclusion_list)";
    }

    if ( $order =~ /match/i ) {

    }
    elsif ($order) {
        $order =~ s /ROW/$row_order/i;
        $order =~ s /(COLUMN|COL)/$column_order/i;
        $condition .= "ORDER BY $order";
    }

    my @slots;
    my @avail_slots = $dbc->Table_find_array(
        "Rack LEFT JOIN Plate on Plate.FK_Rack__ID = Rack_ID LEFT JOIN Source ON Source.FK_Rack__ID=Rack_ID LEFT JOIN Solution ON Solution.FK_Rack__ID=Rack_ID",
        [ "Rack_Name", "CASE WHEN Plate.FK_Rack__ID>0 THEN 'Plate' WHEN Source.FK_Rack__ID>0 THEN 'Source' WHEN Solution.FK_Rack__ID>0 THEN 'Solution' ELSE 0 END AS Content" ],
        $condition, -debug => $debug
    );

##    $dbc->message( "Checking available slots");  ## " in " . alDente_ref( 'Rack', $rack_id, -dbc => $dbc ) );
    if ($debug) { Message("Avail slots: $avail_slots[0] ... $avail_slots[-1]") }

    my ( $block_start, $block_end, $slot_name, $taken );
    my $index = 0;
    foreach my $slot (@avail_slots) {
        my ( $slot_name, $plate_rack_id ) = split ',', $slot;

        #        $slot_name     = $avail_slots[$index];
        #        my $plate_rack_id = $avail_slots{FK_Rack__ID}->[$index];

        $taken = 0;
        if ($plate_rack_id) {
            $taken = 1;
        }

        my $skipped_msg = "";
        if ( !$empty_only ) {
            push @slots, $slot_name;

            # $skipped_msg = "Slot $slot_name ok..";
        }
        else {
            if ($taken) {
                $skipped_msg = "Slot skipped ($plate_rack_id)";
            }
            else {

                # $skipped_msg = "Slot $slot_name ok..";
                push @slots, $slot_name;
            }
        }
        if ( int(@slots) <= $check_number ) {
            ( $block_start, $block_end ) = slot_message( $dbc, $slot_name, $taken, $block_start, $block_end, $rack_id );
        }

        #	if (int(@slots) >= $count) { last }  ## leave this out to enable full list of empty slots to be returned ...
        if ( $debug && $skipped_msg ) { $dbc->message($skipped_msg) }
    }

    if (@avail_slots) {
        if (@slots) {
            $dbc->message( int(@slots) . " Available Slot(s): <B>$slots[0] .. $slots[-1]</B>" );
        }
        else { $dbc->warning("No slots available in $Prefix{Rack}$rack_id"); }
    }
    else {
        $dbc->warning("No slots available in $Prefix{Rack}$rack_id (slots full or no slots identified) - simply applying to Box");
    }
    slot_message( $dbc, $slot_name, $taken, $block_start, $block_end, $rack_id );
    unshift @slots, '';
    $self->{available_slots}{$rack_id} = \@slots;

    return \@slots;

}

####################
sub reserve_slot {
###################
    my $self = shift;
    my $rack = shift;
    my $slot = shift;

    push @{ $self->{reserved}{$rack} }, $slot;

    return;

}

#####################
sub reserved_slots {
#####################
    my $self = shift;
    my $rack = shift;

    if   ($rack) { return $self->{reserved}{$rack} }
    else         { return $self->{reserved} }
}

#################
sub next_slot {
#################
    my $self  = shift;
    my $rack  = shift;
    my $index = shift || 1;

    my $slot;
    while ( !$slot ) {
        $slot = $self->{available_slots}{$rack}[ $index++ ];
        if ( !$slot ) { Message("No more room in Rack $rack"); last; }
        if ( grep /^$slot$/, @{ $self->{reserved}{$rack} } ) { $slot = '' }
    }

    return $slot;
}

#####################
sub slot_message {
#####################
    my $dbc         = shift;
    my $slot_name   = shift;
    my $taken       = shift;
    my $block_start = shift;
    my $block_end   = shift;
    my $rack_id     = shift;

    $rack = alDente_ref( 'Rack', $rack_id, -dbc => $dbc );
    if ($taken) {
        if   ($block_start) { $block_end   = $slot_name }
        else                { $block_start = $slot_name }
    }
    else {
        if ($block_end) {
            $dbc->warning("Slots $block_start .. $block_end are filled");
        }
        elsif ($block_start) {
            $dbc->warning("Slot $block_start is filled (in $rack)");
        }
        $block_start = '';
        $block_end   = '';
    }
    return ( $block_start, $block_end );
}

#
# Determine what user expects to do based upon scanned barcode(s)
#
#
# Return (action, %Found);  where Found is a hash of Rack / item associations (in case multiple racks scanned with multiple items)
##########################
sub determine_action {
##########################
    my $dbc     = shift;
    my $barcode = shift;

    my @items = alDente::Scanner::parse_items_from_barcode( -barcode => $barcode, -dbc => $dbc );
    my %Found;
    my @classes = get_stored_material_types( undef, -dbc => $dbc, -include_self => 1 );
    foreach my $class (@classes) {
        my @found = grep /$Prefix{$class}\d+/i, @items;
        if (@found) { $Found{$class} = \@found }    ## store count of each type
    }

    my @types = keys %Found;
    my $action;
    if ( int(@types) == 1 && $types[0] eq 'Rack' ) {
        if   ( $Found{Rack} == 1 ) { $action = 'home' }
        else                       { $action = 'scanned_Racks' }
    }
    elsif ( int(@types) == 2 && $types[0] eq 'Equipment' && $types[1] eq 'Rack' ) {
        $action = 'move_Rack';
    }
    elsif ( int(@types) > 1 && ( grep /Rack/i, @types ) ) {
        $action = 'move_Items';
    }
    else {
        $dbc->message("Unsure of expected request");
        print HTML_Dump \%Found, @types;
        Call_Stack();
    }

    return ( $action, \%Found );
}

################################
sub correct_Rack_Full {
################################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc,rack' );
    my $dbc  = $self->{dbc} || $args{-dbc};
    my $rack = $args{-rack};
    unless ($rack) {return}

    my %rack_info = $dbc->Table_retrieve( 'Rack', [ 'Rack_Name', 'Rack_Type', 'Rack_Full' ], "WHERE Rack.Rack_ID = $rack" );
    my $rack_name = $rack_info{Rack_Name}[0];
    my $rack_type = $rack_info{Rack_Type}[0];
    my $rack_full = $rack_info{Rack_Full}[0];

    unless ( $rack_type =~ /Slot/i ) {return}

    my ( $links, $details, $refs ) = $dbc->get_references( 'Rack', { 'Rack_ID' => $rack } );    ## third element is the hash of references
    my @objects = keys %$refs if $refs;

    if ( $objects[0] && $rack_full =~ /N/i ) {
        $dbc->message("Changing Rack $rack to Full");
        $dbc->Table_update( 'Rack', 'Rack_Full', 'Y', "WHERE Rack_ID = $rack", -no_triggers => 1, -autoquote => 1 );
        return 1;
    }
    elsif ( !$objects[0] && $rack_full =~ /Y/i ) {
        $dbc->message("Changing Rack $rack to Empty");
        $dbc->Table_update( 'Rack', 'Rack_Full', 'N', "WHERE Rack_ID = $rack", -no_triggers => 1, -autoquote => 1 );
        return 1;
    }
    else {
        ## The data is correct
        return;
    }
}

################################
sub generate_Storage_hash {
################################
    my $self               = shift;
    my %args               = filter_input( \@_, -args => 'dbc,racks,target,ref,condition' );
    my $dbc                = $args{-dbc};
    my $racks              = $args{-racks};
    my $target_ref         = $args{-target};
    my $types              = $args{-types};
    my $starting_condition = $args{-condition} || 1;
    my $debug              = $args{-debug};
    my $split_on           = $args{-split_on};

    my @targets = @$target_ref;
    my %Store;
    my ( @locations, @objects, @ids, @slots );

    my @classes = Cast_List( -list => $types, -to => 'array' );

    my @group_list;
    if ( ref($split_on) eq 'HASH' and ( scalar keys %$split_on > 0 ) ) {
        ## when putting items of certain types (class) into different target boxes ##
        foreach my $class (@classes) {
            my $prefix = $dbc->barcode_prefix($class);
            $dbc->message("Sorting $prefix items into Boxes");

            $class =~ s/\..*//;    ## truncate .FK_Rack__ID ...
            if ( !defined $split_on->{$class} ) {next}
            foreach my $rack ( split ',', $racks ) {
                my $order      = alDente::Rack::SQL_Slot_order('Row');
                my $slot_racks = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = $rack AND Rack_Type = 'Slot' ORDER BY $order" );
                my $rack_list  = $rack;
                if ($slot_racks) { $rack_list = "$slot_racks,$rack" }

                my $condition = "WHERE FK_Rack__ID IN ($rack_list) AND $starting_condition";

                #                my @groups = $dbc->Table_find_array( $class, $split_on->{$class}, $condition, -distinct => 1, -debug => $debug );
                my $length = 0;

                my $groups = $dbc->Table_retrieve( $class, $split_on->{$class}, $condition, -distinct => 1, -debug => $debug, -format => 'AofA' );
                my @groups_list;
                if ($groups) { @groups_list = @$groups; }

                foreach my $group (@groups_list) {
                    my @vals = @$group;

                    #                   my @vals           = split ',', $group;   #values %groups;
                    my @sub_conditions = ($condition);

                    foreach my $i ( 1 .. int( @{ $split_on->{$class} } ) ) {
                        if ( $vals[ $i - 1 ] ) {
                            push @sub_conditions, "$split_on->{$class}->[$i-1] = \"$vals[$i-1]\"";
                        }
                        else {
                            push @sub_conditions, "($split_on->{$class}->[$i-1] = \"$vals[$i-1]\"  OR $split_on->{$class}->[$i-1] IS NULL)  ";
                        }
                    }
                    my $sub_condition = join ' AND ', @sub_conditions;

                    @group_list = $dbc->Table_find( $class, $class . '_ID', "$sub_condition ORDER BY FK_Rack__ID" );

                    my $i = 0;    ## target index reset for each group (if more than one target rack)
                    foreach my $member (@group_list) {
                        push @objects,   $class;
                        push @ids,       $member;
                        push @locations, $targets[$i];

                        push @{ $Store{$class}{ $targets[$i] } }, $member;
                        $i++;
                        if ( $i >= int(@targets) ) {
                            $i = 0;
                        }
                        ## loop back to starting rack if all target options used ##  eg (box 1, box 2, box3... box 1, box 2, box3...)
                    }

                }
            }
        }
    }
    else {
        $dbc->message("Maintaining order of locations");
        ## not splitting up samples by class (re-order independent of content)  ##
        my $i = 0;
        foreach my $rack ( split ',', $racks ) {

            my $slot_racks = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = $rack AND Rack_Type = 'Slot' ORDER BY Rack_Name" );

            my $rack_list = $rack;
            if ($slot_racks) { $rack_list = "$slot_racks,$rack" }

            my $condition = "WHERE Location.Rack_ID IN ($rack_list) AND $starting_condition";

            my @fields;
            my $tables = 'Rack AS Location';
            my ( @class_cases, @id_cases );
            foreach my $class (@classes) {
                $class =~ s/\..*//;    ## truncate .FK_Rack__ID ...
                if ( $class =~ /Shipment/i ) {next}

                #if ($class =~ /Rack/i){ next }
                my $fk = get_Rack_FK($class);

                $tables .= " LEFT JOIN $class on $class.$fk=Location.Rack_ID";
                push @fields,      "$class.${class}_ID";
                push @class_cases, "WHEN $class.${class}_ID IS NOT NULL THEN '$class'";
                push @id_cases,    "WHEN $class.${class}_ID IS NOT NULL THEN $class.${class}_ID";
            }

            my $id_groups  = join ',', @fields;
            my $class_case = join ' ', @class_cases;
            my $id_case    = join ' ', @id_cases;
            if (@fields) {
                my $occupied_condition = join ' IS NOT NULL OR ', @fields;
                $condition .= " AND ($occupied_condition IS NOT NULL)";
            }

            push @fields, "CASE $class_case END as Class";
            push @fields, "CASE $id_case END as ID";
            push @fields, 'Location.Rack_ID';

            my $flist = join ',', @fields;
            my %group_list = $dbc->Table_retrieve( $tables, \@fields, "$condition GROUP BY Location.Rack_ID,$id_groups ORDER BY Location.Rack_ID,$id_groups", -debug => $debug );

            my $index = 0;
            while ( defined $group_list{Rack_ID}[$index] ) {
                my $class = $group_list{Class}[$index];

                push @objects,   $group_list{Class}[$index];
                push @ids,       $group_list{ID}[$index];
                push @locations, $targets[$i];

                push @{ $Store{$class}{ $targets[$i] } }, $group_list{ID}[$index];

                $index++;
                $i++;    ## target index (not hash index)
                if ( $i >= int(@targets) ) {
                    $i = 0;
                }
                ## loop back to starting rack if all target options used ##  eg (box 1, box 2, box3... box 1, box 2, box3...)
            }
        }

        #	    $page .= create_tree(-tree => {"$class records" => $dbc->Table_retrieve_display($class,['*'],$condition, -return_html=>1) });
    }

    return \@objects, \@ids, \@locations, \@slots;
}

#
# Generate Storage hash based upon scanned barcode string.
#
# eg 'pla1pla2pla3rac15pla5pla6rac17' => {'15' => [pla1,pla2,pla3,], '17' => [pla5,pla6]}
#############################
sub parse_Scan_Storage {
#############################
    my %args             = filter_input( \@_, -args => 'dbc,barcode' );
    my $dbc              = $args{-dbc};
    my $original_barcode = $args{-barcode};

    $original_barcode =~ /$Prefix{Rack}(\d+)/i;
    my $rack_id = $1;

    my @moves = split /$Prefix{Rack}\d+/i, $original_barcode;

    ## initialize with simple case (single rack scanned)
    my @racks = ($rack_id);
    my @items = ($original_barcode);

    if ( int(@moves) >= 1 ) {
        ## multiple target locations indicated ##
        @racks = ();
        @items = ();

        my $racks = $original_barcode;
        my $i     = 0;
        if ( !$moves[0] ) {
            $i++;
        }    ## if Rac is scanned prior to items, shift out first blank list of items
        while ( $racks =~ s /$Prefix{Rack}(\d+)//i ) {
            push @racks, $1;
            push @items, $moves[ $i++ ];
        }
    }

    my %reverse_prefix = reverse_Prefix($dbc);
    %reverse_prefix = map { ( lc $_, $reverse_prefix{$_} ) } keys %reverse_prefix;
    my %Store;
    my ( @locations, @objects, @ids, @slots );
    foreach my $i ( 1 .. int(@racks) ) {
        my $object = $items[ $i - 1 ];
        my @identify;

        if ( $object =~ /^(\w{3})(\d+)-\1(\d+)$/ ) {    ## If a range of objects is given...
            my $type     = lc($1);
            my $id_str   = get_aldente_id( $dbc, $object, $reverse_prefix{$type}, -validate => 0 );
            my @id_range = split /,/, $id_str;
            my $count    = scalar(@id_range);

            if ( $reverse_prefix{$type} eq 'Tray' ) {
                for my $id (@id_range) {
                    my @parts = alDente::Scanner::parse_items_from_barcode( -barcode => "$type$id", -dbc => $dbc );
                    push @identify, @parts;
                }
            }
            else {
                @ids = ( @ids, @id_range );
                @locations = ( @locations, ( $racks[ $i - 1 ] ) x $count );
                @objects   = ( @objects,   ( $reverse_prefix{$type} ) x $count );
            }
        }
        else {    ## If individual object barcodes are given...
            @identify = alDente::Scanner::parse_items_from_barcode( -barcode => $object, -dbc => $dbc );    ## eg Pla12Sol5 -> 'Pla12', 'Sol5'
        }

        foreach my $item (@identify) {
            push @locations, $racks[ $i - 1 ];
            my $type = lc( substr( $item, 0, 3 ) );
            ## Exclude tray because this is already resolved to PLA ids
            unless ( $reverse_prefix{$type} eq 'Tray' ) {
                push @objects, $reverse_prefix{$type};
                push @ids, substr( $item, 3, length($item) - 3 );
            }
        }

        #$Store{ $racks[ $i - 1 ] } = \@identify;
    }
    return ( \@objects, \@ids, \@racks, \@slots );
}

#
# simplified method to store items given Storage hash
#
# Refactor to use more intuitive input parameters (consistent with Rack_Views::confirm_Storage)
#
####################
sub store_Items {
####################
    my %args      = filter_input( \@_, -args => 'dbc,store' );
    my $dbc       = $args{-dbc};
    my $store_ref = $args{-store};

    my $objects = $args{-objects};
    my $racks   = $args{-racks};
    my $ids     = $args{-ids};
    my $slots   = $args{-slots};

    my $stored = 0;
    $dbc->message("Storing Items");
    if ($store_ref) {
## Old logic ##
        my %Store = %$store_ref;
        foreach my $key ( keys %Store ) {
            if ( $key =~ /^(\d+)$/ ) {
                ## Store { '$rack_id' => ['pla1', 'pla2'],
                $dbc->warning("not set up to store this type of hash yet...");
            }
            else {
                ## Store { 'Plate' => 'rack_id' => [@ids]} format ##
                my $rack_id = $1;
                foreach my $target ( keys %{ $Store{$key} } ) {
                    my $ids = join ',', @{ $Store{$key}{$target} };
                    $stored += $dbc->Table_update( $key, 'FK_Rack__ID', $rack_id, "WHERE ${key}_ID IN ($ids)" );
                }
            }
        }
    }
    elsif ( $objects && $racks && $ids ) {
## New logic ##
        my @ids;
        foreach my $item_index ( 1 .. int(@$ids) ) {
            my $slot   = $slots->[ $item_index - 1 ] if $slots;
            my $rack   = $racks->[ $item_index - 1 ];
            my $object = $objects->[ $item_index - 1 ];
            my $id     = $ids->[ $item_index - 1 ];
            if ($slot) {
                ($rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = '$rack' AND Rack_Name = '$slot'" );
            }
            $stored += $dbc->Table_update( $object, 'FK_Rack__ID', $rack, "WHERE ${object}_ID IN ($id)" );
        }
    }

    return $stored;
}

#
# Move items as specified.
#
# If not confirmed, this needs to add to an existing page within an existing form (ie no start / end form tags, so that all movements are tracked with the same submit)
# Return: Log (html) of moved items (if confirmed)
###################
sub move_Items {
###################
    my %args        = @_;
    my $dbc         = $args{-dbc};
    my $type        = $args{-type};          ## Plate, Source, Solution
    my $ids         = $args{-ids};           ## items to be moved
    my $rack        = $args{-rack};          ## rack to move to
    my $confirmed   = $args{-confirmed};
    my $slots       = $args{-slots};
    my $slot_choice = $args{-slot_choice};
    my $force       = $args{-force};
    my $event       = $args{-event};
    my $quiet       = $args{-quiet};
    my $fill_by     = $args{-fill_by};
    my $slot;                                ##        = $args{-slot};
    my $repeated  = $args{'-repeated'};      ## enable turning off of prefix button options if multiple move frames are generated on one page
    my $locations = $args{-locations};

    if ( ref $ids eq 'ARRAY' ) { $ids = Cast_List( -list => $ids, -to => 'string' ) }
    my @id_list = split /,/, $ids;

    my @logs;
    ## Checking to see if the number of ids matches number of locations
    my @locs = split /,/, $locations;
    if ( !( int @locs == int @id_list ) && $locations ) { $locations = '' }

    $rack = $dbc->get_FK_ID( 'FK_Rack__ID', $rack );
    unless ($rack) {
        return 0;
    }
    my %rack_info = $dbc->Table_retrieve( 'Rack', [ 'Rack_Name', 'Rack_Type', 'Rack_Full' ], "WHERE Rack.Rack_ID = $rack" );

    my $rack_name = $rack_info{Rack_Name}[0];
    my $rack_type = $rack_info{Rack_Type}[0];
    my $rack_full = $rack_info{Rack_Full}[0];

    if ( !$force && $rack_name =~ /Exported|Garbage/i ) {
        $dbc->error("Can not move objects directly into $rack_name racks!");
        if ( $rack_name =~ /Exported/i ) {
            $dbc->message("Please scan the object and use the Export button to export this item.");
        }
        else {
            $dbc->message("Please scan the object and use the Throw Away button to throw out this item.");
        }
        return 0;
    }

    ## set homepage to moved items
    my $list = join ',', @id_list;
    if ( $Sess->{dbc} ) { $Sess->homepage("$type=$list") }

    my $Log = new HTML_Table( -title => "$type Storage Log [" . date_time() . ']', -border => 1 );
    $Log->Set_Headers( [ $type, 'Starting Location', 'Destination' ] );

    if ($confirmed) {
        ## Set previsou rack to empty
        my $fk          = get_Rack_FK($type);
        my %previ_racks = $dbc->Table_retrieve( "$type, Rack as Loc", [ 'Loc.Rack_ID', 'Loc.Rack_Type' ], "WHERE $type.${type}_ID IN ($ids) AND $type.$fk = Loc.Rack_ID");
        my $size        = int @{ $previ_racks{Rack_ID} } - 1;
        my @change_ids;
        for my $index ( 0 .. $size ) {
            if ( $previ_racks{Rack_Type}[$index] =~ /Slot/i ) {
                push @change_ids, $previ_racks{Rack_ID}[$index];
            }
        }
        my $change_ids = Cast_List( -list => \@change_ids, -to => 'String' );
        $dbc->Table_update_array( 'Rack', ['Rack_Full'], ['N'], "WHERE Rack_ID IN ($change_ids)", -no_triggers => 1, -autoquote => 1 ) if $change_ids;

        # Move the plates
        my %count_moves;
        my $new_rack_info;
        my $check = 0;

        ## Check if slots exist on rack
        my %child_rack_info = $dbc->Table_retrieve(
            "Rack INNER JOIN Rack as Child_Rack ON Child_Rack.FKParent_Rack__ID = Rack.Rack_ID and Child_Rack.Rack_Type = 'Slot'",
            [ 'Child_Rack.Rack_ID as Child_Rack_ID', 'Child_Rack.Rack_Name as Child_Rack_Name', 'Child_Rack.Rack_Full as Child_Rack_Full' ],
            "WHERE Rack.Rack_ID = $rack",
            -key => 'Child_Rack_Name'
        );

        if ( ( $slots && %child_rack_info ) || ( $rack_type eq 'Box' && %child_rack_info ) ) {
            my $slot;
            my %updates;
            if ($slots) {
                foreach my $id (@id_list) {
                    $slot = $slots->{$id};
                    my $target_rack      = $child_rack_info{$slot}{Child_Rack_ID}[0];
                    my $target_slot_full = $child_rack_info{$slot}{Child_Rack_Full}[0];
                    if ($target_rack) {
                        $updates{$id} = $target_rack;
                    }
                }
            }
            else {
                my $order                = alDente::Rack::SQL_Slot_order('Row');
                my @next_available_slots = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = $rack and Rack_Full <> 'Y'  ORDER BY $order" );
                my $i                    = 0;
                foreach my $id (@id_list) {
                    $updates{$id} = $next_available_slots[$i];
                    $i++;
                }
            }

            foreach my $key ( sort { $a <=> $b } keys %updates ) {
                my ($old_rack_id) = $dbc->Table_find( $type, 'FK_Rack__ID', "WHERE ${type}_ID IN ($key)" );
                my @fields        = ();
                my @values        = ();
                
                if (! $updates{$key}) {
                    $dbc->error("Valid location information not found");
                }
                elsif ( $old_rack_id ne $updates{$key} ) {
                    push @fields, 'FK_Rack__ID';
                    push @values, "$updates{$key}";
                }

                if ( $type eq 'Plate' ) {
                    if ( $rack_name =~ /Export/ ) {
                        push( @fields, 'Plate_Status' );
                        push( @values, "\'Exported\'" );
                    }

                    my $archive = param('Archive');
                    if ($archive) {
                        push( @fields, 'Plate_Status' );
                        push( @values, "\'Archived\'" );
                    }
                }
                if (@fields) {
                    my $set_string = $dbc->make_table_update_set_statement( -fields => \@fields, -values => \@values );
                    my $moved = $dbc->query("UPDATE $type,Rack SET $set_string  WHERE Rack_ID = FK_Rack__ID and $type\_ID = $key");
                    $dbc->Table_update_array( 'Rack', ['Rack_Full'], ['Y'], "WHERE Rack_ID = $updates{$key}", -no_triggers => 1, -autoquote => 1 );
                    $Log->Set_Row( [ alDente_ref( $type, $key, -dbc => $dbc ), alDente_ref( 'Rack', $old_rack_id, -dbc => $dbc ), alDente_ref( 'Rack', $updates{$key}, -dbc => $dbc ) ] );
                    $count_moves{$type}++;
                }
            }
        }
        else {
            ## if not then only moving items to one rack

            my $fk = get_Rack_FK($type);
            my ($old_rack_id) = $dbc->Table_find( $type, $fk, "WHERE ${type}_ID IN ($ids)" );
            my @fields        = ();
            my @values        = ();
            if ( $old_rack_id ne $rack ) {
                if ( $type eq 'Rack' ) {
                    push @fields, 'FKParent_Rack__ID';

                }
                else {
                    push @fields, 'FK_Rack__ID';
                }
                push @values, "$rack";
            }

            if ( $rack_type eq 'Slot' && $rack_full eq 'Y' ) {

                #full
                $dbc->warning("Cannot move ${type}(s) $ids to $Prefix{Rack} $rack ($slot): Slot is already filled ");
                
                return;
            }
            elsif ( $rack_type eq 'Slot' ) {

                # set the slot to full
                if ( $type ne 'Rack' ) {
                    $dbc->Table_update( "Rack", "Rack_Full", "Y", "where Rack_ID IN ($rack)", -autoquote => 1 );
                }
                else {
                    push @fields, 'Rack_Full';
                    push @values, 'Y';
                }
            }

            if ( $type eq 'Plate' ) {
                if ( $rack_name =~ /Export/ ) {
                    push( @fields, 'Plate_Status' );
                    push( @values, 'Exported' );
                }

                my $archive = param('Archive');
                if ($archive) {
                    push( @fields, 'Plate_Status' );
                    push( @values, 'Archived' );
                }
            }
            ## move the items
            my $moved = 0;

            if (@fields) {
                foreach my $id ( sort { $a <=> $b } split ',', $ids ) {
                    my $fk = get_Rack_FK($type);
                    my ($old_rack_id) = $dbc->Table_find( $type, $fk, "WHERE ${type}_ID IN ($id)" );
                    $Log->Set_Row( [ alDente_ref( $type, $id, -dbc => $dbc ), alDente_ref( 'Rack', $old_rack_id, -dbc => $dbc ), alDente_ref( 'Rack', $values[0], -dbc => $dbc ) ] );
                }
                $moved = $dbc->Table_update_array( $type, \@fields, \@values, "where $type" . "_ID IN ($ids)", -autoquote => 1 );
            }
            $count_moves{$type} = $moved;

        }

        ## update rack Alaises
        if ( $type eq 'Rack' ) {
            my ($equ_id) = $dbc->Table_find( 'Rack', 'FK_Equipment__ID', "WHERE Rack_ID = $rack" );
            my $reset = $dbc->Table_update( 'Rack', 'FK_Equipment__ID', $equ_id, "WHERE Rack_ID IN ($ids)" );
            for my $tmp_id (@id_list) {
                &Update_Rack_Info(
                    -dbc      => $dbc,
                    -rack_id  => $tmp_id,
                    -no_print => 1
                );
            }
        }

        my $new_alias = $dbc->get_FK_info( 'FK_Rack__ID', $rack );
        $event ||= "Move to $new_alias";

        if ( $event && ( $type eq 'Plate' ) ) {

            if ( $dbc->package_active('Storage_Tracking') ) {
                $dbc->message("Recorded relocation");

                my $user_id = $dbc->get_local('user_id');
                my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id, -plates => $ids );

                my %input;
                if ( $type eq 'Plate' ) {
                    $input{'Current Plates'} = $ids;
                    $input{'Prep Step Name'} = $event;

                    my $ok = $Prep->Record(
                        -protocol        => 'Standard',
                        -input           => \%input,
                        -change_location => 0,
                    );
                }
            }
        }
        $dbc->message( "<B>Moved $count_moves{$type}</B> $type(s) to " . $dbc->display_value( 'Rack', $rack) );
    }
    else {
        ## return the move page
        # Display the form for moving items (unconfirmed)
        my $Rack = new alDente::Rack( -dbc => $dbc );
        return alDente::Rack_Views::move_Page(
            -dbc         => $dbc,
            -type        => $type,
            -ids         => $ids,
            -slot_choice => $slot_choice,
            -rack        => $rack,
            -repeated    => $repeated,
            -fill_by     => $fill_by,
            -locations   => $locations,
            -Rack        => $Rack
        );

    }

    $dbc->session->reset_homepage('') if $dbc->session;
    my $returnval;

    if ( $confirmed && $Log->{rows} ) {
        my $timestamp = timestamp();
        $returnval .= $Log->Printout( "$Configs{URL_temp_dir}/relocate.$timestamp.html", -link_text => 'Printable log of sample movement' );
        $returnval .= $Log->Printout(0);
    }

    return $returnval;
}

###########################################
# Move contents of one rack to another
#
#
#
############################
sub move_Rack_Contents {
############################
    my %args        = @_;
    my $dbc         = $args{-dbc};
    my $source_rack = $args{-source_rack};
    my $target_rack = $args{-target_rack};
    my $include     = $args{-include};
    my $confirmed   = $args{-confirmed};

    ## (form already initiated in Rack_home) ##
    my $page;

    if ($confirmed) {
        my $total_moved = 0;
        foreach my $type ( split ',', $include ) {
            my $moved = $dbc->Table_update_array( $type, ['FK_Rack__ID'], [$target_rack], "WHERE FK_Rack__ID IN ($source_rack)" );
            if ($moved) { $page .= $dbc->message("Moved $moved $type items<BR>") }
            $total_moved += $moved;
        }
        if ( $include =~ /,/ ) {
            $page .= $dbc->message("Moved $total_moved total items from Rack(s) $source_rack -> Rack $target_rack<BR>");
        }    ## if more than one type
        $page .= alDente::Rack_Views::home_page( $dbc, $source_rack );
    }
    else {
        $page
            .= hidden( -name => 'Source_Racks',  -value => $source_rack, -force => 1 )
            . hidden( -name  => 'Include Items', -value => $include,     -force => 1 )
            . hidden( -name  => 'Target_Rack',   -value => $target_rack, -force => 1 )
            . hidden( -name => 'Transfer Rack Contents', -value => 'Yes' );
        $page .= hr;
        my $total_found = 0;

        $page .= 'Found:<UL>';
        foreach my $type ( split ',', $include ) {
            my ($found) = $dbc->Table_find( $type, 'count(*)', "WHERE FK_Rack__ID IN ($source_rack)" );
            if ($found) { $page .= "<LI>$found $type items" }
            $total_found += $found;
        }
        $page .= '</UL>';

        if ( $total_found > 0 ) {
            $page .= "Move all of $total_found items above to Rack $target_rack ? <BR>";
            $page .= submit( -name => 'rm', -value => 'Confirm Move', -class => "Action" );
            $page .= hr;
        }
        else {
            $dbc->warning('Nothing to move');
            $page .= alDente::Rack_Views::home_page( $dbc, $source_rack );
        }
    }
    return $page;
}

####################
sub Move_Racks {
####################
    my %args = @_;

    my $source_racks = $args{-source_racks};
    my $target_rack  = $args{-target_rack};
    my $equip        = $args{-equip};
    my $confirmed    = $args{-confirmed};
    my $new_names    = $args{-new_names};
    my $leave_name   = $args{'-leave_name'};    ## option to leave rack name unchangedd (usefulwhen hipping boxes))
    my $no_print     = $args{-no_print};        ## skip barcode printing (eg when shipping boxes)
    my $in_transit   = $args{ -in_transit };
    my $dbc          = $args{-dbc};
    my $debug        = $args{-debug};

    my $monitor_limit = 400;                    ## arbitrary limit (set to prevent page timeout at least if not to keep user up to speed... )

    unless ( $equip xor $target_rack ) {
        $dbc->error("No destination specified ('$equip' xor '$target_rack'");
        Call_Stack();
        return 0;
    }

    my $output;
    my ( $t_equip, $t_type, $t_alias, $t_site, $target_equip_info );
    
    if ($equip) {
        ($target_equip_info) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
            'Equipment_Name,Sub_Category', "where Equipment_ID=$equip AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID" );
        $target_equip_info =~ s/,/ /g;
    }
    else {
        my %tinfo = $dbc->Table_retrieve( 'Rack,Equipment,Location', [ 'Rack_ID', 'FK_Equipment__ID', 'Rack_Type', 'Rack_Alias', 'FK_Site__ID' ], "WHERE Rack_ID=$target_rack AND FK_Location__ID=Location_ID AND FK_Equipment__ID=Equipment_ID" );
        $t_equip = $tinfo{FK_Equipment__ID}[0];
        $t_type  = $tinfo{Rack_Type}[0];
        $t_alias = $tinfo{Rack_Alias}[0];
        $t_site  = $tinfo{FK_Site__ID}[0];

        my $current_site = $dbc->session->{site_id};
        if ( $t_site ne $current_site ) {
            my $curent_site_name = alDente_ref( 'Site', $current_site, -dbc => $dbc );
            my $target_site_name = alDente_ref( 'Site', $t_site,       -dbc => $dbc );

            if ($in_transit) {
                ## no need to relocate item to current site ##
            }
            elsif ( shipping_rack( $dbc, $target_rack ) ) {
                ## if the target_rack is determined to be a transport shipping rack ##
                $dbc->message( "Relocating " . alDente_ref( 'Rack', $target_rack, -dbc => $dbc ) . ' to ' . $curent_site_name );
                relocate_Rack( $dbc, $target_rack );
            }
            elsif ( $target_site_name =~ /in transit/i ) {
                ## Nothing to report
            }
            else {
                $dbc->warning( 'You are at ' . $curent_site_name . ', but transferring samples to a location at ' . $target_site_name );
            }
        }
    }

    if ($confirmed) {
        $dbc->start_trans('Move_Racks');

        my @fields = qw(FK_Equipment__ID FKParent_Rack__ID);
        my $destination;
        my $update_equip;
        my $update_parent_rack;
        if ($equip) {
            $update_equip       = $equip;
            $update_parent_rack = 0;
            $destination        = b("Equ$equip") . " $target_equip_info";
        }
        else {
            $update_equip       = $t_equip;
            $update_parent_rack = $target_rack;
            $destination        = b("$Prefix{Rack}$target_rack");
        }
        my $moved = 0;
        my @src_racks = split /,/, $source_racks;

        my $Progress;
        if ( int(@src_racks) > $monitor_limit ) { $Progress = new SDB::Progress( 'Moving ' . int(@src_racks) . ' Racks', -target => int(@src_racks) ) }
        my $moved_src_count = 0;

        foreach my $rack (@src_racks) {
            my $new_name = param("New_Rack_Name:$rack") || $new_names->{$rack};
            if ( !$leave_name ) {
                &Update_Rack_Info(
                    -dbc                => $dbc,
                    -rack_id            => $rack,
                    -specified_name     => $new_name,
                    -no_print           => $no_print,
                    -update_equip       => $update_equip,
                    -update_parent_rack => $update_parent_rack
                );

                # Message("Moved <B>$Prefix{Rack}$rack</B> to $destination");
                $moved++;
            }
            elsif ($in_transit) {

                #
                # # if leave_name and in_transit, then append " x.n" to the end of the rack alias
                my @fields = qw(FK_Equipment__ID FKParent_Rack__ID);
                my @values = ( $update_equip, $update_parent_rack );
                my $ok     = $dbc->Table_update_array( 'Rack', \@fields, \@values, "WHERE Rack_ID in ($rack)", -autoquote => 1 );
                _mark_shipped_racks( $dbc, $rack );
            }
            if ($Progress) { $Progress->update( ++$moved_src_count ) }

            ## removed block to move child racks since child racks should be moved automatically within 'Update_Rack_Info' call above if applicable ##
        }
         
        $output = "Moved $moved storage locations";

        $dbc->finish_trans('Move_Racks');
    }
    else {
        $output = alDente::Rack_Views::move_Rack(
            -dbc          => $dbc,
            -equip        => $equip,
            -source_racks => $source_racks,
            -target_rack  => $target_rack
        );
    }
    return $output;
}

#########################
sub _mark_shipped_racks {
#########################
    my %args = filter_input( \@_, -args => 'dbc,rack' );

    my $dbc  = $args{-dbc};
    my $rack = $args{-rack};
    my $force = $args{-force};

    my $pattern = " x.";
    my ($old_alias)      = $dbc->Table_find( 'Rack',      'Rack_Alias',   "WHERE Rack_ID = $rack" );
    my ($old_name)      = $dbc->Table_find( 'Rack',      'Rack_Name',   "WHERE Rack_ID = $rack" );
    
    if ($old_alias eq $old_name) { 
        ## static rack - no need to change name ##
        return;
    }
    
    my ($in_transit_equ) = $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_Name = 'In Transit'" );
    my @x_aliases        = $dbc->Table_find( 'Rack',      'Rack_Alias',   "WHERE FK_Equipment__ID = $in_transit_equ AND Rack_Alias like '$old_alias%$pattern%' " );
    my $max_copy         = 0;
    foreach my $alias (@x_aliases) {
        if ( $alias =~ /.*$pattern(\d+)/ ) {
            if ( $1 > $max_copy ) { $max_copy = $1 }
        }
    }
    $max_copy++;    ## increase the copy number

    my $set = "SET ";
    my $condition = 1;
    ## option to force the equipment reference to In Transit regardless of current state - otherwise, it failsafes to only adjust the alias if the equipment is already marked as In Transit ##
    if ($force) { $set .= "FK_Equipment__ID = $in_transit_equ," }
    else { $condition .= " AND FK_Equipment__ID = $in_transit_equ"}

    ## do the batch update in one statement to improve performance
    my $command = "Update Rack $set Rack_Alias = CONCAT( IF(LOCATE('$pattern', Rack_Alias), LEFT( Rack_Alias, LOCATE('$pattern', Rack_Alias)-1), Rack_Alias), '$pattern$max_copy' ) WHERE $condition AND Rack_Alias like '$old_alias%' ";
    my $updated = $dbc->execute_command( -command => $command, -debug=>1);

    return $updated;
}

####################
sub get_Rack_FK {
####################
    my %args  = filter_input( \@_, -args => 'table' );
    my $table = $args{-table};
    my $fk    = "FK_Rack__ID";
    if ( $table =~ /Rack/ ) { $fk = "FKParent_Rack__ID" }
    return $fk;
}

#
# Designed to relocate shipping racks if they are referenced at a site other than where they are located
#
#
# Return: 1 if relocated
####################
sub relocate_Rack {
    ####################
    my %args   = filter_input( \@_, -args => 'dbc,rack' );
    my $dbc    = $args{-dbc};
    my $rack   = $args{-rack};
    my $ignore = $args{'-ignore'};                           ## optional number of samples in rack to ignore (useful if contents is already moved first)

    if ( !$rack ) { ($rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Alias like 'In Use'" ); $dbc->warning("Location unidentified - please relocate samples when you are done"); }

    my ($rack_site) = $dbc->Table_find( 'Rack,Equipment,Location,Site', 'Site_Name', "WHERE FK_Site__ID=Site_ID AND FK_Equipment__ID=Equipment_ID AND FK_Location__ID=Location_ID AND Rack_ID = $rack" );
    if ( $rack_site ne $dbc->session->{site_name} ) {
        ## check if samples are in this box ##
        my $current_site = $dbc->session->{site_name};
        my ($samples) = $dbc->Table_find( 'Plate,Rack', 'Count(*)', "WHERE FK_Rack__ID=Rack_ID AND (Rack_ID = $rack OR FKParent_Rack__ID = $rack)" );

        if ( $samples > $ignore ) {
            ## samples are in this box - need to track box/rack properly to avoid errors ##
            $dbc->warning(
                "This Transport Box (contains $samples items) should not be at this location <BR>(it is assigned to '$rack_site'. <BR><BR><B>Please Check Content!</B><BR><BR>If correct, you may re-assign it to your site ($current_site) by Scanning Transport Box along with local Site Barcode<BR><BR>Please See Admin if you are unsure."
            );
        }
        else {
            my ($site_equip) = $dbc->Table_find( 'Equipment,Location,Site', 'Equipment_ID', "WHERE FK_Location__ID=Location_ID AND FK_Site__ID=Site_ID AND Equipment_Name like 'Site-%' AND Site_Name = '$current_site'", -debug => 0 );
            ## no samples in box - move transport box to this site automatically ##
            Move_Racks(
                -dbc          => $dbc,
                -source_racks => $rack,
                -equip        => $site_equip,
                -confirmed    => 1
            );
            $dbc->message( "Moved " . alDente_ref( 'Rack', $rack, -dbc => $dbc ) . " to $current_site" );
            return 1;
        }
    }
    return;
}

#################
sub add_rack {
#################
    my %args               = @_;
    my $dbc                = $args{-dbc};
    my $equipment_id       = $args{-equipment_id};
    my $number             = $args{-number} || 1;
    my $type               = $args{-type};
    my $parent             = $args{-parent} || 0;
    my $rack_number        = $args{-rack_number} || 0;
    my $max_rack_row       = $args{-max_rack_row} || 0;
    my $max_rack_col       = $args{-max_rack_col} || 0;
    my $max_slot_row       = $args{-max_slot_row} || 0;    ## Used for slots inside the box
    my $max_slot_col       = $args{-max_slot_col} || 0;    ## Used for slots inside the box
    my $specified_prefix   = $args{-specified_prefix};
    my $shipping_container = $args{-shipping_container};
    my $create_slots       = $args{-create_slots};
    my $barcoded           = 0;
    my @new_racks;

    ## Make sure that the row letter is lower case so that the
    ## loops that follow have the correct bounds
    ## e.g. from a->a not from a->H
    $max_rack_row = lc($max_rack_row);
    $max_slot_row = lc($max_slot_row);

    my @rack_nums;
    if ( $max_rack_row && $max_rack_col ) {
        my ( $min_row, $max_row, $min_col, $max_col ) = ( 'a', $max_rack_row, '1', $max_rack_col );
        foreach my $row ( $min_row .. $max_row ) {
            foreach my $col ( $min_col .. $max_col ) {
                push( @rack_nums, "$row$col" );
            }
        }
    }
    elsif ($number) {
        if ( $rack_number =~ /^[a-zA-Z]$/ ) {
            ## enable rack numbering using letters ... eg Shelves A-G instead of S1 - S7
            foreach my $i ( 1 .. $number ) {
                push @rack_nums, $rack_number++;
            }
        }
        else {
            @rack_nums = map {$_} ( 1 .. $number );
        }
    }

    if ( !$equipment_id && $parent ) {
        ($equipment_id) = $dbc->Table_find( 'Rack', 'FK_Equipment__ID', "WHERE Rack_ID = $parent " );
    }

    if ( $max_rack_row && $max_rack_col ) {
        # This is the case for creating slots
        my @fields = ( 'FK_Equipment__ID', 'Rack_Type', 'Rack_Name', 'Rack_Alias', 'FKParent_Rack__ID' );
        my %values;

        # Get rack alias
        my $alias = $dbc->Table_retrieve(
            -table     => 'Rack',
            -fields    => ['Rack_Alias'],
            -condition => "WHERE Rack_ID = $parent",
            -format    => 'S'
        );

        my $i = 1;
        foreach my $rack_number (@rack_nums) {
            my $this_alias = "$alias-$rack_number";

            $values{$i} = [ $equipment_id, $type, $rack_number, "$this_alias", $parent ];
            $i++;
        }

        # Batch insert the slots
        my $ret = $dbc->simple_append(
            -table     => 'Rack',
            -fields    => \@fields,
            -values    => \%values,
            -autoquote => 1
        );
        $barcoded  = int( @{ $ret->{newids} } );
        @new_racks = @{ $ret->{newids} };
    }
    else {

        # Any other type of racks
        foreach my $rack_no (@rack_nums) {
            my @fields = ( 'FK_Equipment__ID', 'Rack_Type', 'FKParent_Rack__ID' );
            my @values = ( $equipment_id, $type, $parent );

            if ($shipping_container) {
                my $temp_name = $specified_prefix || 'Default Transport Box ';
                my $next = get_next_rack_name( -dbc => $dbc, -name => $temp_name, -static => 1 );
                push @fields, 'Rack_Name', 'Rack_Alias';
                push @values, $next, $next;
            }

            my $new_rack = $dbc->Table_append_array( 'Rack', \@fields, \@values, -autoquote => 1 );

            if ( $new_rack =~ /[1-9]/ ) {

                if ( !$shipping_container ) {

                    # Update the rack info
                    my $ok = &Update_Rack_Info(
                        -dbc            => $dbc,
                        -rack_id        => $new_rack,
                        -rack_number    => $rack_no,
                        -specified_name => $specified_prefix,
                        -static         => $shipping_container,
                    );
                }

                $barcoded++;
                &alDente::Barcoding::PrintBarcode( $dbc, 'Text', "$Prefix{Rack}$new_rack", 'proc_med' );
            }
            push( @new_racks, $new_rack );
        }
    }

    my $new_rack_list = join ',', @new_racks;
    ( my $conditions ) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
        'Sub_Category', "WHERE Equipment_ID=$equipment_id AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID" );

    unless ( $type =~ /Slot/i ) {
        $dbc->message("Created $barcoded new rack(s) ($new_rack_list) for Equ$equipment_id ($conditions)");
    }

    ## create Slots inside boxes
    if ( $type eq 'Box' && $create_slots ) {
        for my $new_rack (@new_racks) {
            my @slot_racks = alDente::Rack::add_rack(
                -dbc          => $dbc,
                -parent       => $new_rack,
                -type         => 'Slot',
                -max_rack_row => $max_slot_row,
                -max_rack_col => $max_slot_col,
                -create_slots => $create_slots,
            );
        }
    }

    return @new_racks;
}

#
# This method ensures that there is a slotted box for placing items.
#
# * If supplied location is a Rack or Shelf, create a new box
# * Add slots if necessary
#
# Return: box_id
###########################
sub generate_slotted_box {
###########################
    my %args = filter_input( \@_, -args => 'dbc,rack,max' );
    my $dbc  = $args{-dbc};
    my $rack = $args{-rack};                                   ## target location (could be Rack / Shelf or Box ##
    my $max  = $args{-max};                                    ## only required if slots need to be added (eg -max=>'H12')

    my ( $max_slot_row, $max_slot_col );
    if ( $max =~ /([a-zA-Z])(\d+)/ ) {
        $max_slot_row = $1;
        $max_slot_col = $2;
    }

    my ($info) = $dbc->Table_find_array( "Rack LEFT JOIN Rack as Slots ON Slots.FKParent_Rack__ID=Rack.Rack_ID AND Slots.Rack_Type = 'Slot'", [ 'Rack.Rack_Type', 'count(*)', 'Rack.FK_Equipment__ID' ], "WHERE Rack.Rack_ID = $rack GROUP BY Rack.Rack_ID" );
    my ( $type, $slots, $equipment_id ) = split ',', $info;

    my $slotted_box;
    ## Ensure there is a box first ##
    if ( $type =~ /(Shelf|Rack)/ ) {
        ($slotted_box) = alDente::Rack::add_rack(
            -dbc          => $dbc,
            -parent       => $rack,
            -type         => 'Box',
            -equipment_id => $equipment_id,
        );
        $dbc->message("Added box $slotted_box");
    }
    elsif ( $type eq 'Box' ) {
        $slotted_box = $rack;
    }

    ## add slots if necessary ##
    if ( ( $slots <= 1 ) && $max ) {
        my @slot_racks = alDente::Rack::add_rack(
            -dbc          => $dbc,
            -parent       => $slotted_box,
            -type         => 'Slot',
            -max_rack_row => $max_slot_row,
            -max_rack_col => $max_slot_col,
            -create_slots => 1,

            #-equipment_id => $equipment_id,
        );
        $dbc->message("Added slots to box");
    }

    return $slotted_box;
}

##################
sub static_rack {
##################
    my $dbc = shift;
    my $rid = shift;

    my $static_rack = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_ID = $rid AND (Rack_Alias = Rack_Name  OR Movable = 'N')" );
    return $static_rack;
}

######################
sub shipping_rack {
######################
    my $dbc = shift;
    my $rid = shift;

    my $standard_racks = Cast_List(
        -to        => 'string',
        -autoquote => 1,
        -list      => [ 'Garbage', 'In Use', 'Exported', 'In Transit' ]
    );

    my $shipping_rack = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_ID = $rid AND Rack_Alias =  Rack_Name AND Rack_Name NOT IN ($standard_racks)" );

    return $shipping_rack;
}

###################################
# Updates the rack info such as alias, name and FK_Equipment__ID
# Then recursively updates its children as well
###################################
sub Update_Rack_Info {
###################################
    my %args               = &filter_input( \@_, -args => 'dbc,rack_id' );
    my $dbc                = $args{-dbc};
    my $rid                = $args{-rack_id};
    my $r_number           = $args{-rack_number};
    my $specified_prefix   = $args{-specified_name};                         ## default to S / R / B (optionally text.. eg Plasma)
    my $no_print           = $args{-no_print};
    my $force              = $args{-force};
    my $static             = $args{'-static'};                               ## static rack (alias = name and/or Movable = N) - set only when creating new static racks
    my $shipment_id        = $args{-shipment_id};
    my $debug              = $args{-debug};
    my $update_equip       = $args{-update_equip};
    my $update_parent_rack = $args{-update_parent_rack};
    if ( !$force ) {
        ## check to see if this is a static rack ##
        if ( static_rack( $dbc, $rid ) ) {

            # update equipment or parent rack if passed in before return
            if ( $update_equip || $update_parent_rack ) {
                my @fields = qw(FK_Equipment__ID FKParent_Rack__ID);
                my @values = ( $update_equip, $update_parent_rack );
                my $ok     = $dbc->Table_update_array( 'Rack', \@fields, \@values, "WHERE Rack_ID in ($rid)", -autoquote => 1 );
            }
            return 0;    ## returns for shipping containers (name = alias) and non-movable items (Movable = N)
        }
    }
    my $type;
    my $conditions;
    my $r_name;
    my $parent;
    my $e_id;
    my $e_name;
    my @fields;
    my @values;

    if ( $update_equip || $update_parent_rack ) {
        my %info = $dbc->Table_retrieve( 'Rack', [ 'Rack_Type As RT', 'Rack_Name As RN' ], "WHERE Rack_ID = $rid " );
        my %eq_info = $dbc->Table_retrieve( 'Equipment', ['Equipment_Name As EN'], "WHERE Equipment_ID = $update_equip " ) if $update_equip;
        $e_name = $eq_info{EN}[0];    ## eg F80-3
        $type   = $info{RT}[0];       ## eg Box
        $r_name = $info{RN}[0];       ## eg B2 or Plasma3

        $parent = $update_parent_rack;
        $e_id   = $update_equip;
        push @fields, ( 'FK_Equipment__ID', 'FKParent_Rack__ID' );
        push @values, ( $e_id, $parent );

    }
    else {
        my %info = $dbc->Table_retrieve(
            'Rack,Equipment,Stock,Stock_Catalog,Equipment_Category',
            [ 'Rack_Type As RT', 'Sub_Category As RC', 'Rack_Name As RN', 'FKParent_Rack__ID As Parent', 'Equipment_ID As EID', 'Equipment_Name As EN' ],
            "WHERE Rack_ID = $rid AND FK_Equipment__ID=Equipment_ID AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_Id and Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID"
        );

        $type       = $info{RT}[0];             ## eg Box
        $conditions = $info{RC}[0];             ## eg -80 degrees
        $r_name     = $info{RN}[0];             ## eg B2 or Plasma3
        $parent     = $info{Parent}[0] || 0;    ##
        $e_id       = $info{EID}[0];
        $e_name     = $info{EN}[0];             ## eg F80-3
    }

    my $movable_rack_condition = " Rack_Name != Rack_Alias";
    if ( ( $conditions =~ /Room Temperature/i ) && !$e_id ) {
        ## just a room temperature shelf somewhere
        my $ok = $dbc->Table_update(
            'Rack', 'Rack_Alias', $r_name, "WHERE Rack_ID = $rid AND $movable_rack_condition",
            -autoquote => 1,
            -debug     => $debug
        );
        ## for now set it exactly (temporary - do we want to concatenate the parent name ... ?) ##

        # update equipment or parent rack if passed in before return
        if ( $update_equip || $update_parent_rack ) {
            my @fields1 = ( 'FK_Equipment__ID', 'FKParent_Rack__ID' );
            my @values1 = ( $update_equip, $update_parent_rack );
            my $ok = $dbc->Table_update_array( 'Rack', \@fields1, \@values1, "WHERE Rack_ID in ($rid)", -autoquote => 1 );
        }

        return $ok ? 1 : 0;
    }

    my $starting_letter;    ## allow for alphabetic numbering if desired ##
    my $type_prefix;
    my $default = $type =~ /^([a-zA-Z]{1})\w+/;    ## default to S, R, or B
    if ($specified_prefix) { $type_prefix = $specified_prefix; }
    elsif ( $r_number =~ /^[a-zA-Z]$/ ) { $starting_letter = $r_number }    ## no prefix default for rack numbering using letters...
    elsif ($r_name) { $type_prefix = $r_name }                              ## override S/R/B default
    else {
        ($type_prefix) ||= $default;
    }
    $type_prefix .= $r_number if $r_number =~ /\d/;                         ## only do this when using numerical rack numbers (eg not when calling racks A..D)

    # Get parent info
    my %p_info;
    if ($parent) {
        %p_info = $dbc->Table_retrieve( 'Rack', [ 'Rack_Alias As RA', 'Rack_Type As RT', 'FK_Equipment__ID AS EID' ], "WHERE Rack_ID = $parent" );
    }

    my $nextname = get_next_rack_name( -dbc => $dbc, -parent_rack_alias => $p_info{RA}[0], -parent_id => $parent, -name => $type_prefix, -rack_id => $rid, -equipment_id => $e_id, -static => $static, -starting_number => $starting_letter )
        ;                                                                   ## given parent rack - get next 'Rack_Name' based on specified type
    $r_name = $nextname;

    push( @fields, "Rack_Name" );
    push( @values, $r_name );

    my ($old_alias) = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE Rack_ID = $rid" );

    my $alias;
    if ($parent) {
        my $p_alias = $p_info{RA}[0];
        my $p_type  = $p_info{RT}[0];
        my $p_eid   = $p_info{EID}[0];

        $alias = "$p_alias-$r_name";
        if ( grep /FK_Equipment__ID/, @fields ) {

            # already updated the equipment
        }
        else {
            push( @fields, "FK_Equipment__ID" );
            push( @values, $p_eid );
        }
    }
    else {
        if ( $conditions && ( $conditions ne 'Room Temperature' ) && ( $conditions ne 'N/A' ) && ( $e_name ne $conditions ) ) {
            $alias = "$e_name ($conditions) $r_name";
        }
        else {
            $alias = "$e_name $r_name";
        }
    }

    if ($static) {
        $alias = $r_name;
    }    ## set alias = name for static racks (non-movable racks and shipping containers)
    elsif ( $e_name =~ /^Site\-(\d+)/ && !$parent ) {
        ## clean up name for virtual site locations ##
        ($shipment_id) = $dbc->Table_find( 'Shipment', 'Shipment_ID,Shipment_Status', "WHERE FKTransport_Rack__ID=$rid ORDER BY Shipment_ID DESC" );
        $alias = "unstored $type $r_name (from Shipment $shipment_id)";
    }

    push( @fields, 'Rack_Alias' );
    push( @values, $alias );

    my $ok = $dbc->Table_update_array(
        'Rack', \@fields, \@values, "WHERE Rack_ID = $rid",
        -autoquote => 1,
        -debug     => $debug
    );

    if ($ok) {

        #        $dbc->message("New Rack Alias : $alias");
        if ( ( $alias ne $old_alias ) && !$no_print ) {
            ## reprint barcode for rack ##
            $dbc->message("New Barcode for rack(s) generated");
            &alDente::Barcoding::rack_barcode( -dbc => $dbc, -rack_id => $rid );
        }
    }

    my $errors;
    if ( Get_DBI_Error() ) { $errors = 1 }

    # Now find all the child that reference this rack and update their name/alias as well
    my @child_racks = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = $rid AND Rack_ID <> $rid" );
    foreach my $child_rack (@child_racks) {
        my $ok = &Update_Rack_Info(
            -dbc      => $dbc,
            -rack_id  => $child_rack,
            -no_print => $no_print,
            -static   => $static
        );
        unless ($ok) { $errors = 1 }
    }

    return $errors ? 0 : 1;
}

#########################################################
# <snip>
# eg my $name = get_next_rack_name($dbc,12,'Plasma');
#
#   (if Rack 12 is 'F80-3 S1-R2', and there are no current 'Plasma1' boxes on this rack...)
#
#    ... $name = 'Plasma1' (first time)
#    ...and later 'Plasma2'... etc.)
#
# (needs parent id so that it only looks for matching names in the same place)
#
#</snip>
#
# Return: Next 'name' for rack
#########################
sub get_next_rack_name {
#########################
    my %args              = filter_input( \@_, -args => 'dbc,parent_id,name,rack_id,equipment_id' );
    my $dbc               = $args{-dbc};
    my $parentid          = $args{-parent_id};
    my $name              = $args{-name};
    my $rid               = $args{-rack_id};
    my $e_id              = $args{-equipment_id};
    my $static            = $args{-static};
    my $parent_rack_alias = $args{-parent_rack_alias};
    my $starting_number   = $args{-starting_number} || '1';                                            ## allows for starting_number of 'A'  to enable lettering of Racks...(eg 'A' - 'D' instead of S1-S4);

    ## strip off number from name ##
    $name =~ s/(\d*)$//;
    my $proposednum = $1 || $starting_number;
    my $prefix = $name;
    $prefix      =~ s/\s+$//;
    $proposednum =~ s/^[0]+//;

    ## find all racks with same prefix from same parent rack
    my $namecond;
    if ($static) {
        $namecond = "WHERE Rack_Name LIKE '$prefix%'";
    }
    else {
        $namecond = "WHERE FKParent_Rack__ID = $parentid";
        $namecond .= " AND Rack_ID <> $rid"          if $rid;
        $namecond .= " AND FK_Equipment__ID = $e_id" if $e_id;
    }
    my @racknames = $dbc->Table_find( 'Rack', 'Rack_Name', "$namecond" );
    my @other_aliases = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE Rack_Alias LIKE '$parent_rack_alias%'" ) if $parent_rack_alias;

    my @existingnums;
    foreach my $rname (@racknames) {
        if ( $rname =~ /^$name/i ) {
            $rname =~ s/(\d+)$//;
            my $rnum = $1;
            $rnum =~ s/^[0]+//;
            push @existingnums, $rnum;
        }
    }

    my $number;
    if ($proposednum) {
        while ( grep /^$proposednum$/, @existingnums ) {
            $proposednum++;
        }
        $number = $proposednum;
    }    ## use stripped number suffix if it is available
    else {
        my $maxnum = shift @existingnums;
        foreach my $num (@existingnums) {
            if ( $num > $maxnum ) { $maxnum = $num; }
        }
        $number = ++$maxnum;
    }

    my $next_name = $prefix . $number;
    while ( grep /$next_name/, @other_aliases ) {
        $number++;
        $next_name = $prefix . $number;
    }

    return $next_name;
}

##########################
sub get_child_racks {
##########################
    my %args         = filter_input( \@_, -args => 'dbc,rack_id', -mandatory => 'dbc,equipment_id|rack_id' );
    my $dbc          = $args{-dbc};
    my $equipment_id = $args{-equipment_id};
    my $rack_ids     = $args{-rack_id};

    if ($equipment_id) {
        my @racks = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FK_Equipment__ID IN ($equipment_id)" );

        if ( !@racks ) { @racks = (0) }
        return @racks;
    }

    elsif ( $rack_ids =~ /[1-9]/ ) {
        my @racks;
        my $generation = $rack_ids;
        while ( $generation =~ /[1-9]/ ) {
            my @gen_racks = split ',', $generation;
            push @racks, @gen_racks;

            $generation = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID IN ($generation)" );
            my @next_gen = split ',', $generation;
        }
        return @racks;
    }
    else {return}
}

#
# Given a rack, find the contents of the rack
#
# Optionally separate slots within racks if index_slots paramter supplied.
#
# Output format: {'Rac55' => 'Pla54,Pla55,Pla56'} or 'Rack55' => {'a1' => 'Pla54', 'a2' => 'Pla55' ...}
#
# Note contents are listed in slot order if applicable
#
#
# Return: Hash of rack contents
###########################
sub get_rack_contents {
###########################
    my %args          = filter_input( \@_, -args => 'rack_id,rack_contents,recursive' );
    my $rack_id       = $args{-rack_id};
    my $rack_contents = $args{-rack_contents};
    my $recursive     = $args{-recursive};
    my $index_slots   = $args{-index_slots};
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my @objects       = get_stored_material_types( undef, -dbc => $dbc, -include_self => 1 );

    my %rev_prefix        = reverse_Prefix($dbc, \@objects );

    my $prefix = $dbc->barcode_prefix('Rack');
    
    my @items;
    foreach my $key ( keys %rev_prefix ) {
        my $table = $rev_prefix{$key};

        if ( $table eq 'Equipment' ) {next}

        my ($primary) = $dbc->get_field_info( $table, undef, 'PRI' );
        if ( $table eq 'Rack' ) {
            my @ids = $dbc->Table_find( $table, "$primary", "WHERE FKParent_Rack__ID = $rack_id and Rack_Type <> 'Slot'", -debug => 0 );
            my @sub_racks = map { $prefix . $_ } @ids;
            if ($recursive) {
                foreach my $id (@ids) {
                    my $contents = get_rack_contents(
                        -rack_id       => $id,
                        -rack_contents => $rack_contents,
                        -recursive     => $recursive
                    );
                    $rack_contents = $contents;
                }
            }
            push( @items, @sub_racks );
            ## Check if the Rack_type is a box -- Special Handling for SLOTS

            my ($rack_type) = $dbc->Table_find( 'Rack', 'Rack_Type', "WHERE Rack_ID = $rack_id" );
            if ( $rack_type eq 'Box' ) {
                my @tables = get_stored_material_types( undef, -dbc => $dbc );
                my %slots;
                foreach my $table (@tables) {
                    my $pf = $dbc->barcode_prefix($table);
                    my ($primary) = $dbc->get_field_info( $table, undef, 'PRI' );
                    my @slot_info = $dbc->Table_find( "Rack,$table", "Rack_Name,$primary", "WHERE FK_Rack__ID = Rack_ID and FKParent_Rack__ID = $rack_id" );
                    foreach my $slot_info (@slot_info) {
                        my ( $slot_name, $slot_content ) = split ',', $slot_info;
                        if ( $slot_name && $slot_content ) {
                            $slots{$slot_name} = "$pf$slot_content";
                        }
                    }
                }
                foreach my $key ( sort keys %slots ) {
                    if ($index_slots) {
                        $rack_contents->{"$prefix$rack_id"}{$key} = $slots{$key};
                    }
                    else { push @items, "$slots{$key}" }
                }
            }
            ## END Special handling for slots
        }
        else {
            if ($primary) {
                my @ids = $dbc->Table_find( $table, "$primary", "WHERE FK_Rack__ID = $rack_id" );
                my @barcodes = map { $key . $_ } @ids;
                push( @items, @barcodes );
            }
            else {
                $dbc->warning("Could not find primary key for $table ?");
            }
        }
    }
    if ($index_slots) {
        if (@items) { $rack_contents->{"$prefix$rack_id"}{''} = Cast_List( -list => \@items, -to => 'String' ) }
    }
    else { $rack_contents->{"$prefix$rack_id"} = Cast_List( -list => \@items, -to => 'String' ) }

    return $rack_contents;
}

###############################
sub add_rack_for_location {
###############################
    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $dbc = $args{-dbc};

    my ($stock_ID)    = $dbc->Table_find( 'Stock, Stock_Catalog', 'Stock_ID',                                  "Where Stock_Catalog_Name = 'Storage Area' AND FK_Stock_Catalog__ID = Stock_Catalog_ID" );
    my ($Category_ID) = $dbc->Table_find( 'Equipment_Category',   'Equipment_Category_ID',                     "Where Category = 'Storage' and Sub_Category= 'Storage_Site'" );
    my ($loc_id)      = $dbc->Table_find( 'Location',             'Max(Location_ID)' );
    my ($info)        = $dbc->Table_find( 'Location',             "Location_ID, Location_Name, Location_Type", "WHERE Location_ID= $loc_id" );

    # my $info;
    my ( $location_id, $location_name, $location_type ) = split ',', $info;

    my ( $prefix, $index ) = _get_equipment_name( -category_id => $Category_ID, -dbc => $dbc );
    my $equipment_name = "$prefix-$index";

    my @equipment_fields = qw (Equipment_Name     Equipment_Status    FK_Location__ID FK_Stock__ID    Equipment_Comments   );
    my @equipment_values = ( $equipment_name, 'In Use', $location_id, $stock_ID, "Storage Site equipment for $location_name" );

    # We only need this rack if exports are to be done without tracking - otherwise user should define shelf if applicable.
    my $equipment_ID = $dbc->Table_append_array( 'Equipment', \@equipment_fields, \@equipment_values, -autoquote => 1 );

    if ( $location_type eq 'External' ) {
        ## internal locations should have shelves defined manually by users as required ##
        my @rack_fields = qw (Rack_Type       Rack_Name     Rack_Alias Movable FK_Equipment__ID FKParent_Rack__ID);
        my @rack_values = ( 'Shelf', "VS-$equipment_name", "$location_name", 'N', $equipment_ID, 0 );
        my $rack_ID     = $dbc->Table_append_array( 'Rack', \@rack_fields, \@rack_values, -autoquote => 1 );
    }

    return 1;
}

##########################
sub get_Site_Address {
##########################
    my $dbc         = shift;
    my %args        = filter_input( \@_ );
    my $site_id     = $args{-site_id};
    my $location_id = $args{-location_id};
    my $condition   = $args{-condition} || 1;

    if   ($location_id) { $condition .= " AND Location_ID = $location_id" }
    else                { $condition .= " AND Site_ID = $site_id" }

    my ($target_address) = $dbc->Table_find_array( 'Location, Site', ["Concat(Site_Address,'<BR>',Site_City,', ',Site_State,'<BR>',Site_Zip,'<BR>',Site_Country)"], "WHERE FK_Site__ID=Site_ID AND $condition" );

    return $target_address;
}

##########################
sub get_Contents_from_File {
##########################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $fh     = $args{-file};
    my $dbc    = $args{-dbc};
    my $object = $args{-object};
    require RGTools::RGmath;
    my @contents;
    my %locations;

    if ($fh) {
        my $buffer = '';
        my $found;
        while (<$fh>) {
            ## read either csv or txt format (csv uses , while txt uses ; delimiter) ##
            my $line = $_;
            if ( $line =~ /^\s*([A-Z]\d\d)[\;\,]\s*(.+)/ ) {
                my $well    = $1;
                my $content = $2;

                $content =~ s/\s+$//;    ## clear trailing spaces
                push @contents, $content;
                $locations{$content} = $well;
                $found++;
            }
        }
    }
    my $barcodes = join "','", @contents;
    unless ($barcodes) {
        $dbc->warning("Warning: No records");
        return;
    }
    my @final_locations;
    my @final_objects;

    if ( $object =~ /source/i ) {
        my %results = $dbc->Table_retrieve( 'Source', [ 'Factory_Barcode', 'Source_ID' ], "WHERE Factory_Barcode IN ('$barcodes')" );
        my $size    = int @{ $results{Factory_Barcode} };
        my $prefix  = 'SRC';

        for my $index ( 0 .. $size - 1 ) {
            my $barcode_value = $results{Factory_Barcode}[$index];
            my $object_id     = $results{Source_ID}[$index];
            my $location      = $locations{$barcode_value};
            if ( $location =~ /^(\w)0(\d)$/ ) {
                $location = $1 . $2;
            }
            push @final_locations, $location;
            push @final_objects,   $prefix . $object_id;

        }
    }
    elsif ( $object =~ /plate/i ) {
        my %results = $dbc->Table_retrieve(
            'Source, Plate_Attribute , Attribute',
            [ 'Factory_Barcode', 'FK_Plate__ID' ],
            "WHERE Factory_Barcode IN ('$barcodes') AND FK_Attribute__ID = Attribute_ID and Attribute_Name = 'Redefined_Source_For' and Attribute_Value =Source_ID"
        );
        my $size   = int @{ $results{Factory_Barcode} };
        my $prefix = 'PLA';

        for my $index ( 0 .. $size - 1 ) {
            my $barcode_value = $results{Factory_Barcode}[$index];
            my $object_id     = $results{FK_Plate__ID}[$index];
            my $location      = $locations{$barcode_value};
            if ( $location =~ /^(\w)0(\d)$/ ) {
                $location = $1 . $2;
            }
            push @final_locations, $location;
            push @final_objects,   $prefix . $object_id;

        }
    }
    else {
        $dbc->warning("Warning: No objects");
        return;
    }

    return ( \@final_objects, \@final_locations );
}

###############################
sub get_export_locations {
###############################
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $rack = $args{-rack};

    my @locations;

    if ($rack) {
        ## enable export to any location other than current location ##
        my $current_locations = join ',', $dbc->Table_find( 'Equipment,Rack', 'FK_Location__ID', "WHERE FK_Equipment__ID=Equipment_ID AND Rack_ID IN ($rack)" );
        @locations = $dbc->Table_find( 'Location', 'Location_Name', "Where Location_ID NOT IN ($current_locations)" );
    }
    else {
        @locations = $dbc->Table_find( 'Location', 'Location_Name', "Where Location_Type = 'External'" );
    }

    #    $dbc->message("Loc: @locations");
    return \@locations;
}

###############################
sub add_new_export_locations {
###############################
    my %args              = @_;
    my $dbc               = $args{-dbc};
    my @organization_list = $dbc->get_FK_info_list( "FK_Organization__ID", "Where Organization_Type Like '%Collaborator%'" );

    my %list;
    my %preset;
    $list{'FK_Organization__ID'}   = \@organization_list;
    $preset{'FK_Organization__ID'} = $dbc->get_local('organization_name');
    my $table = SDB::DB_Form->new( -dbc => $dbc, -table => 'Location', -target => 'Database' );
    $table->configure( -list => \%list, -preset => \%preset );
    return $table->generate( -navigator_on => 1, -return_html => 1 );
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

###############################
# Recursively get rack children
###############################
##########################
sub _get_equipment_name {
##########################
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc};
    my $category_id = $args{-category_id};

    my $command = "Concat(Max(Replace(Equipment_Name,concat(Prefix,'-'),'') + 1)) as Next_Name";
    my ($name) = $dbc->Table_find_array(
        'Equipment_Category',
        -fields    => ['Prefix'],
        -condition => "WHERE Equipment_Category_ID=$category_id"
    );
    my ($number) = $dbc->Table_find_array( 'Equipment,Equipment_Category,Stock,Stock_Catalog',
        [$command], "WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Equipment_Category__ID=Equipment_Category_ID AND Equipment_Category_ID=$category_id" );
    unless ($number) { $number = 1 }
    return ( $name, $number );
}

sub _get_rack_children {
    my %args = @_;

    my $dbc      = $args{-dbc};
    my $rack_id  = $args{-rack_id};
    my $children = $args{-children};
    my $recurse  = $args{-recurse} || 10;
    $recurse--;

    push( @{$children}, $rack_id );
    my @child_id = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID=$rack_id" );
    if ( $recurse > 0 ) {
        foreach (@child_id) {
            _get_rack_children(
                -dbc      => $dbc,
                -rack_id  => $_,
                -children => $children,
                -recurse  => $recurse
            );
        }
    }
}

################################
# Recursively get rack contents
################################
sub _get_rack_contents {
########################
    my %args = @_;

    my $dbc       = $args{-dbc};
    my $rack_id   = $args{-rack_id};
    my $recursive = $args{-recursive};
    my $level     = $args{-level};

    my $slot_racks = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID IN ($rack_id) AND Rack_Type = 'Slot'" );

    my ($info) = $dbc->Table_find( 'Rack', 'Rack_Type,Rack_Name', "WHERE Rack_ID=$rack_id" );
    my ( $type, $name ) = split /,/, $info;

    my $table = HTML_Table->new();
    $table->Set_Class('small');
    $table->Set_Border(1);

    unless ( $type eq 'Slot' ) { $name = get_FK_info( $dbc, 'FK_Rack__ID', $rack_id ) }
    $table->Set_Title($name);

    # First get items stored directly under the rack
    my $items = "<span class='small'>";
    my ( $ref_list, $detail_list, $ref ) = $dbc->get_references( 'Rack', { 'Rack_ID' => "$rack_id,$slot_racks" } );
    foreach my $ref_table ( sort keys %$ref ) {
        my ( $rt, $rf ) = &SDB::DBIO::simple_resolve_field($ref_table);
        my ($primary) = get_field_info( $dbc, $rt, undef, 'PRI' );
        my @pks = $dbc->Table_find( $rt, $primary, "WHERE FK_Rack__ID = $rack_id" );
        foreach my $pk (@pks) {
            my $name;
            if   ( exists $Prefix{$rt} ) { $name = "$Prefix{$rt}$pk" }
            else                         { $name = "$rt $pk" }

            $items .= &Link_To( $dbc->config('homelink'), $name, "&Info=1&Table=$rt&Field=$primary&Like=$pk", 'blue', ['newwin'] ) . "<br>";
        }
    }
    $items .= "</span>";

    if ($recursive) {

        # Then recursively get items stored in child racks
        my @child_racks = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = $rack_id AND Rack_Type <> 'Slot'" );
        foreach my $child_rack (@child_racks) {
            $items .= "<br>"
                . _get_rack_contents(
                -dbc       => $dbc,
                -rack_id   => $child_rack,
                -recursive => 1,
                -level     => $level + 1
                );
        }

        # Finally get slots if current type is a box
        my $slots_table;
        if ( $type eq 'Box' ) {
            ##
        }
    }

    $table->Set_Row( [$items] );

    if ( $level > 0 ) {
        return $table->Printout(0);
    }
    else {
        return $table->Printout( "$alDente::SDB_Defaults::URL_temp_dir/Rack_Contents_@{[timestamp()]}.html", $html_header ) . $table->Printout(0);
    }
}

#############################
# Display a list of plates using Table_retrieve_display
#############################
sub display_object_in_rack {
#############################
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $ids  = $args{-ids};
    my $type = $args{-type};    # (sol, pla, src)
    my $tables;
    my @fields;
    my $condition;

    if ( $type eq 'pla' ) {
        $tables    = 'Plate';
        @fields    = ( 'Plate_ID', 'Plate_Size', 'Plate_Created', 'FK_Library__Name as Library', 'FK_Plate_Format__ID as Plate_Format', 'Plate_Number', 'FK_Rack__ID as Rack' );
        $condition = "WHERE Plate.Plate_ID in (" . $ids . ")";
    }
    elsif ( $type eq 'sol' ) {
        $tables    = 'Solution,Stock,Stock_Catalog';
        @fields    = ( 'Solution_ID', 'Stock_Catalog_Name as Name', 'FK_Employee__ID as Employee', 'FK_Grp__ID as Grp', 'Solution_Started as Started', 'Solution_Type as Type', 'Solution_Status as Status', 'FK_Rack__ID as Rack' );
        $condition = "WHERE FK_Stock_Catalog__ID = Stock_Catalog_ID AND FK_Stock__ID = Stock_ID and Solution_ID in (" . $ids . ")";
    }
    elsif ( $type eq 'src' ) {
        $tables = 'Source,Original_Source';
        @fields = (
            'Source_ID',
            'FK_Original_Source__ID',
            'FKReceived_Employee__ID as Employee',
            'FK_Sample_Type__ID as Sample_Type',
            'Source_Number',
            'FKParent_Source__ID as Parent_Source',
            'FK_Barcode_Label__ID as Barcode_Label',
            'FKSource_Plate__ID as Plate',
            'FK_Rack__ID as Rack'
        );
        $condition = "WHERE FK_Original_Source__ID = Original_Source_ID and Source_ID in (" . $ids . ")";
    }
    Table_retrieve_display( $dbc, $tables, \@fields, $condition );
}

#Return
#################################
sub check_equipment_to_rack {
#################################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $ID   = $args{-ID};

    #if rac id then return it
    my @racks = Cast_List(
        -list    => &get_aldente_id( $dbc, $ID, 'Rack', -validate => 1, -allow_repeats => 1 ),
        -to      => 'array',
        -default => 0
    );
    if (@racks) { return $ID }
    else {

        # else try to convert equipment id
        my @equipment = Cast_List(
            -list    => &get_aldente_id( $dbc, $ID, 'Equipment', -validate => 1, -allow_repeats => 1 ),
            -to      => 'array',
            -default => 0
        );
        my @racks;
        for my $equipment (@equipment) {
            my @rack_ids = $dbc->Table_find( "Rack", "Rack_ID", "WHERE FK_Equipment__ID = $equipment" );
            if ( int(@rack_ids) == 1 ) {
                push( @racks, $rack_ids[0] );
            }
            else {
                $dbc->warning("Equipment $equipment has more than 1 rack in it. Invalid equipment and ignored") if defined $Sess;
                return '';
            }
        }
        return join( '', map {"$Prefix{Rack}$_"} @racks );
    }
}

#################################
#
# Retrieves the next available position of sub compartments (rack,shelf,box,...) given an equipment or rack
#
# Returns Hash or 0 if fails
#
##########################
sub _get_available_names {
##########################
    my %args = &filter_input( \@_ );

    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $equ_id    = $args{-equ_id};
    my $rack_id   = $args{-rack_id};
    my @requested = @{ $args{-list} };

    my ( $shelves, $racks, $boxes, $slots );

    ### Find out how many items are moving to this equipment
    foreach (@requested) {
        if    ( $_ eq 'Shelf' ) { $shelves++ }
        elsif ( $_ eq 'Rack' )  { $racks++ }
        elsif ( $_ eq 'Box' )   { $boxes++ }
        elsif ( $_ eq 'Slot' )  { $slots++ }
    }

    if ( $equ_id xor $rack_id ) {

        my %avail;

        if ($shelves) {
            $avail{Shelf} = _get_next_available_position(
                -dbc      => $dbc,
                -rack_id  => $rack_id,
                -equ_id   => $equ_id,
                -type     => 'Shelf',
                -quantity => $shelves
            );
        }
        if ($racks) {
            $avail{Rack} = _get_next_available_position(
                -dbc      => $dbc,
                -rack_id  => $rack_id,
                -equ_id   => $equ_id,
                -type     => 'Rack',
                -quantity => $racks
            );
        }
        if ($boxes) {
            $avail{Box} = _get_next_available_position(
                -dbc      => $dbc,
                -rack_id  => $rack_id,
                -equ_id   => $equ_id,
                -type     => 'Box',
                -quantity => $boxes
            );
        }
        if ($slots) {
            $avail{Slot} = _get_next_available_position(
                -dbc      => $dbc,
                -rack_id  => $rack_id,
                -equ_id   => $equ_id,
                -type     => 'Slot',
                -quantity => $slots
            );
        }
        ### Error checking to see if _get_next_available_position has returned 0
        foreach ( values %avail ) {
            if ( $_ == 0 ) { return undef; }
        }

        return \%avail;
    }
    else {
        $dbc->message("Please specify a rack_id or equ_id");
        return 0;
    }
}

#
# Retrieve existing list of Locations on a given Location ('Rack')
#
# Return hash of existing racks
#############################
sub existing_sub_storage {
#############################
    my %args      = &filter_input( \@_, -args => 'dbc,type', -mandatory => 'type' );
    my $dbc       = $args{-dbc};
    my $rack_id   = $args{-rack_id};
    my $equ_id    = $args{-equ_id};
    my $rack_type = lc $args{-type};

    ### Get the current list
    my %existing;
    if ($rack_id) {
        ### Check to see if no hierarchy rules are broken

        #	my $ok = can_move_rack($dbc, -rack_id=>$rack_id, -target_type => $rack_type);
        my $ok = 1;    # above logic not correct ... skip for now...
        if ($ok) {
            my ($alias) = $dbc->Table_find_array( 'Rack', ['Rack_Alias'], "WHERE Rack_ID = $rack_id" );    ## also need to check for racks with the same name that are still in transit to avoid possible confusion ##
            my $in_transit_condition = " (Equipment_Name='In Transit' AND Rack.Rack_Alias like '$alias-%') ";
            %existing = $dbc->Table_retrieve( 'Rack, Rack as Parent,Equipment',
                ['Rack.Rack_Name'], "WHERE Parent.FK_Equipment__ID=Equipment_ID AND Rack.FKParent_Rack__ID=Parent.Rack_ID AND (Parent.Rack_ID=$rack_id OR $in_transit_condition) AND Rack.Rack_Type='$rack_type'" );
        }
        else {
            $dbc->error("You cannot move this onto a $rack_type");
            return;
        }
    }
    elsif ($equ_id) {
        %existing = $dbc->Table_retrieve( 'Rack', ['Rack_Name'], "WHERE FK_Equipment__ID=$equ_id AND FKParent_Rack__ID=0" );
    }
    else {
        $dbc->message("No Rack or Equipment specified!");
        return;
    }

    return %existing;
}

#
# Simple boolean indicating whether you can move a given rack (location_id) into a target location (or target location type)
#
#
#
#
# Return; 1 if move is valid
#######################
sub can_move_rack {
#######################
    my %args = &filter_input(
         \@_,
        -args      => 'dbc,rack_id,target_rack',
        -mandatory => 'dbc,rack_id,target_type|target_rack'
    );
    my $dbc         = $args{-dbc};
    my $rack_id     = $args{-rack_id};
    my $target_type = $args{-target_type};
    my $target_rack = $args{-target_rack};
    my $debug       = $args{-debug};

    my %hierarchy = (
        'equipment' => 6,
        'shelf'     => 5,
        'rack'      => 4,
        'drawer'    => 3,
        'box'       => 2,
        'slot'      => 1
    );

    my $rack_type = join ',',
        $dbc->Table_find(
        'Rack', 'Rack_Type', "WHERE Rack_ID IN ($rack_id)",
        -distinct => 1,
        -debug    => $debug
        );
    if ( $rack_type =~ /,/ ) {
        $dbc->warning('Cannot move multiple rack types at one time');
        return 0;
    }

    if ($target_rack) {
        ($target_type) = $dbc->Table_find( 'Rack', 'Rack_Type', "WHERE Rack_ID=$target_rack", -debug => $debug );
    }
    $target_type = lc $target_type;

    $rack_type = lc $rack_type;
    if ( $hierarchy{$rack_type} >= $hierarchy{$target_type} ) {
        return 0;
    }
    else {
        return 1;
    }
}

#
# Simple boolean indicating whether you can move a content of a rack to another
#   The conditions currently are : 1- same type of rack, 2- only 2 racks
# Input:
#   -dbc
#   -
# Output:
#   Return; 1 if move is valid
#######################
sub can_move_content {
#######################
    my %args = &filter_input(
         \@_,
        -args      => 'dbc,rack_id,target_rack',
        -mandatory => 'dbc,rack_id,target_rack'
    );
    my $dbc         = $args{-dbc};
    my $rack_id     = $args{-rack_id};
    my $target_rack = $args{-target_rack};
    my $debug       = $args{-debug};

    if ( $rack_id =~ /,/ || $target_rack =~ /,/ ) {

        # only works for 2 racks
        return;
    }

    my $rack_type = join ',',
        $dbc->Table_find(
        'Rack', 'Rack_Type', "WHERE Rack_ID IN ($rack_id,$target_rack)",
        -distinct => 1,
        -debug    => $debug
        );
    if ( $rack_type =~ /,/ ) {

        # Type needs to be the same
        return 0;
    }

    return 1;
}

#
#  Retrieves the available child rack names for a given rack (ie available Rack_Names on a Shelf) :-)
#
#
#######################################
sub _get_next_available_position {
#######################################
    my %args     = &filter_input( \@_, -args => 'type,quantity', -mandatory => 'type' );
    my $rack_id  = $args{-rack_id};
    my $equ_id   = $args{-equ_id};
    my $type     = lc $args{-type};
    my $quantity = $args{-quantity} || 1;
    my $dbc      = $args{-dbc};

    my %existing = existing_sub_storage(
        -dbc     => $dbc,
        -equ_id  => $equ_id,
        -rack_id => $rack_id,
        -type    => $type
    );

    my @existing;
    if ( $existing{Rack_Name} ) {
        @existing = @{ $existing{Rack_Name} };
    }
    my @availables;

    my %initials = (
        'shelf' => 'S',
        'rack'  => 'R',
        'box'   => 'B',
        'slot'  => 'a'
    );

    my $initial = $initials{$type};

    ### Start by the first one
    my $number = 1;
    for ( my $i = 0; $i < $quantity; $i++ ) {
        while (1) {
            my $name = $initial . $number;
            ### If exists skip, if not add to the list
            if ( grep( /^$name$/, @existing ) ) {
                $number++;
            }
            else {
                push( @existing,   $name );
                push( @availables, $name );
                last;
            }
        }
    }
    return \@availables;
}

##############################
sub process_rack_request {
##############################
    my %args        = &filter_input( \@_, -args => 'dbc,rack_id,barcode' );
    my $dbc         = $args{-dbc};
    my $rack_id     = $args{-rack_id};
    my $barcode     = $args{-barcode};
    my $slot_choice = $args{-slot_choice};
    my $repeated    = $args{-repeated};
    my $confirmed   = $args{-confirmed} || param('Confirm Move');
    my $fill_by     = $args{-fill_by};
    my $slot_ref    = $args{-slots};
    my $group       = $args{-group};

    my $type;
    if ( $group =~ /^Rac(\d+)\.(.+)/ ) {
        ## eg Rac55.Plate ##
        $rack_id = $1;
        $type    = $2;
    }

    my %slots;
    my $plates = &get_aldente_id(
         $dbc, $barcode, 'Plate',
        -condition => "Plate_Type IN ('Library_Plate','Array')",
        -quiet     => 1
    );
    my $tubes = &get_aldente_id(
         $dbc, $barcode, 'Plate',
        -condition => "Plate_Type ='Tube'",
        -quiet     => 1
    );

    my $solutions = &get_aldente_id( $dbc, $barcode, 'Solution' );
    my $sources   = &get_aldente_id( $dbc, $barcode, 'Source' );
    my $boxes     = &get_aldente_id( $dbc, $barcode, 'Box' );

    my $equip = param('Target_Equipment') || &get_aldente_id( $dbc, $barcode, 'Equipment' );
    my $target_rack = get_rack_parameter( 'Target_Rack', -dbc => $dbc );
    my $racks = param('Source_Racks') || &get_aldente_id( $dbc, $barcode, 'Rack' );

    unless ( $racks || $rack_id ) {
        return;
    }

    my $page;

    my $source_rack = $racks;
    if ($target_rack) {
        my $target_rack_id = &get_FK_ID( $dbc, 'FK_Rack__ID', $target_rack );
        if ( $target_rack_id =~ /[1-9]/ ) { $racks .= ",$target_rack_id"; }

    }

    my $transfer_items = param('Transfer Rack Contents');
    my $transfer_includes = join ',', param('Include Items');

    #    print alDente::Form::start_alDente_form($dbc, 'process_Rack');

    unless ($confirmed) {
        unless ($racks) {
            $barcode = "rac$rack_id$barcode";
        }
        $page .= hidden( -name => 'Scan', -value => 1, -force => 1 ) . hidden( -name => 'Barcode', -value => $barcode, -force => 1 );

    }

    my $moving_contents = 0;
    my $moving_racks    = 0;
    if ( $racks =~ /([\d,]+),(\d+)/ && !$equip ) {
        $source_rack = $1;
        $target_rack = $2;
        if ($transfer_items) {
            $page .= alDente::Rack::move_Rack_Contents(
                -dbc         => $dbc,
                -source_rack => $source_rack,
                -target_rack => $target_rack,
                -include     => $transfer_includes,
                -confirmed   => $confirmed
            );
            $moving_contents = 1;
        }
        else {
            $page .= alDente::Rack::Move_Racks(
                -dbc          => $dbc,
                -source_racks => $source_rack,
                -target_rack  => $target_rack,
                -confirmed    => $confirmed
            );
            $moving_racks = 1;
        }
    }

    my %slots;
    my $containers;
    if ( $plates =~ /[1-9]/ ) {
        $containers = $plates;
    }
    elsif ( $tubes =~ /[1-9]/ ) {
        $containers = $tubes;
    }

    my %slots;
    foreach my $container ( split /,/, $containers ) {
        $slots{$container} = param("Rack_Slot:$container");
    }
    if ( $plates =~ /[1-9]/ ) {
        my @types = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID IN ($plates)", 'Distinct' );
        unless ( scalar(@types) == 1 ) {    # Do not allow moving different types of container at the same time
            $dbc->error("Cannot move different types of container at the same time.");

            # print end_form();
            return 0;
        }
        my @status = $dbc->Table_find( 'Plate', 'Plate_Status', "WHERE Plate_ID IN ($plates)", 'Distinct' );
        unless ( ( scalar(@status) == 1 ) && $status[0] eq 'Active' ) {    # Do not allow moving different types of container at the same time
            $dbc->warning("Some of these plates are not currently active and cannot be moved");

            # print end_form();
            &alDente::Container::activate_Plate(
                -dbc     => $dbc,
                -ids     => $plates,
                -rack_id => $source_rack
            );
            return 0;
        }
        $page .= move_Items(
            -dbc         => $dbc,
            -type        => 'Plate',
            -ids         => $plates,
            -rack        => $rack_id,
            -confirmed   => $confirmed,
            -slots       => \%slots,
            -slot_choice => $slot_choice,
            -fill_by     => $fill_by,
            -repeated    => $repeated++
        );
    }
    if ( $tubes =~ /[1-9]/ ) {
        my @status = $dbc->Table_find( 'Plate', 'Plate_Status', "WHERE Plate_ID IN ($tubes)", 'Distinct' );
        unless ( ( scalar(@status) == 1 ) && $status[0] eq 'Active' ) {

            # Do not allow moving different types of container at the same time
            $dbc->warning("Some of these plates are not currently active and cannot be moved");

            # print end_form();
            &alDente::Container::activate_Plate(
                -dbc     => $dbc,
                -ids     => $tubes,
                -rack_id => $source_rack
            );
            return 0;
        }
        $page .= move_Items(
            -dbc         => $dbc,
            -type        => 'Plate',
            -ids         => $tubes,
            -rack        => $rack_id,
            -confirmed   => $confirmed,
            -slot_choice => $slot_choice,
            -slots       => \%slots,
            -repeated    => $repeated++ ,
            -fill_by     => $fill_by
        );
    }
    if ( $solutions =~ /[1-9]/ ) {
        my @solution_status = $dbc->Table_find( 'Solution', 'Solution_Status', "WHERE Solution_ID IN ($solutions)", 'Distinct' );
        if ( grep /^Finished$/i, @solution_status ) {
            $dbc->warning("Some of these solutions are marked as Finished and cannot be moved");

            # print end_form();
            &alDente::Solution::activate_Solution(
                -dbc     => $dbc,
                -ids     => $solutions,
                -rack_id => $source_rack
            );
            return 0;
        }
        $page .= alDente::Rack::move_Items(
            -dbc       => $dbc,
            -type      => 'Solution',
            -ids       => $solutions,
            -rack      => $rack_id,
            -confirmed => $confirmed,
            -fill_by   => $fill_by
        );
    }

    if ( $sources =~ /[1-9]/ ) {
        my %slots;
        foreach my $source ( split /,/, $sources ) {
            $slots{$source} = param("Rack_Slot:$source");
        }
        $page .= alDente::Rack::move_Items(
            -dbc         => $dbc,
            -type        => 'Source',
            -ids         => $sources,
            -rack        => $rack_id,
            -confirmed   => $confirmed,
            -slot_choice => $slot_choice,
            -slots       => \%slots,
            -fill_by     => $fill_by,
            -repeated    => $repeated++
        );
    }

    if ( $boxes =~ /[1-9]/ ) {
        $page .= alDente::Rack::move_Items(
            -dbc       => $dbc,
            -type      => 'Box',
            -ids       => $boxes,
            -rack      => $rack_id,
            -confirmed => $confirmed,
            -fill_by   => $fill_by,
            -repeated  => $repeated++
        );
    }

    if ( $source_rack =~ /[1-9]/ && $equip =~ /[1-9]/ ) {    # Moving rack(s) to equipment
        $page .= alDente::Rack::Move_Racks(
            -dbc          => $dbc,
            -source_racks => $source_rack,
            -equip        => $equip,
            -confirmed    => $confirmed
        );
    }
    return $page;                                            # ( $moving_contents, $moving_racks );
}

#################
sub delete_rack {
#################
    my %args    = filter_input( \@_, -args => 'dbc,rack_id', -mandatory => 'dbc,rack_id' );
    my $dbc     = $args{-dbc};
    my $rack_id = $args{-rack_id};

    my @racks = Cast_List( -list => $rack_id, -to => 'array' );

    my $total_deleted = 0;
    foreach my $rack (@racks) {

        my @daughter_racks = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID IN ($rack)" );
        my $failed = 0;
        foreach my $Drack (@daughter_racks) {
            my $ok = $dbc->delete_records(
                -table   => 'Rack',
                -field   => 'Rack_ID',
                -id_list => $Drack,
                -cascade => get_cascade_tables('Rack'),
                -quiet   => 1
            );
            if ($ok) {
                $total_deleted++;
            }
            else {
                $dbc->warning("Failed to delete Rack $Drack on Rack $rack... skipping");
                $failed++;
                last;
            }
        }

        if ($failed) {next}

        my $ok = $dbc->delete_records(
            -table   => 'Rack',
            -field   => 'Rack_ID',
            -id_list => $rack,
            -cascade => get_cascade_tables('Rack'),
            -quiet   => 1
        );
        $total_deleted++;
    }

    if ($total_deleted) { $dbc->success("Deleted $total_deleted Rack Records in total (including daughter rack records)") }
    return $total_deleted;
}

###################################
sub add_barcode_for_bench {
###################################
    my %args          = @_;
    my $dbc           = $args{-dbc};
    my $location_name = $args{-location_name};
    my $rack_name     = $args{-rack_name};
    my $ok            = 1;

    ( my $location_id ) = $dbc->Table_find( 'Location', 'Location_ID', "Where Location_Name = '$location_name'" );
    ( my $equipment_id ) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
        'Equipment_ID', "WHERE FK_Location__ID = $location_id AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Equipment_Category__ID = Equipment_Category_ID AND Sub_Category = 'Storage_Site'" );

    ( my $rack_id ) = add_rack(
        -dbc              => $dbc,
        -equipment_id     => $equipment_id,
        -type             => 'Shelf',
        -specified_prefix => $rack_name,
    );

    my $num_records = $dbc->Table_update_array(
        -table     => 'Rack',
        -fields    => [ 'Movable', 'Rack_Alias', 'Rack_Name' ],
        -values    => [ "'N'", "'$rack_name'", "'$rack_name'" ],
        -condition => "WHERE Rack_ID = $rack_id",
        -debug     => 1
    );
    return $rack_id;
}

###################################
sub add_transport_box {
###################################
    my %args          = @_;
    my $dbc           = $args{-dbc};
    my $location_name = $args{-location_name};
    my $rack_name     = $args{-rack_name} || 'Transport Box';
    my $ok            = 1;

    ( my $location_id ) = $dbc->Table_find( 'Location', 'Location_ID', "Where Location_Name = '$location_name'" );
    ( my $equipment_id ) = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
        'Equipment_ID', "WHERE FK_Location__ID = $location_id AND FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Equipment_Category__ID = Equipment_Category_ID AND Sub_Category = 'Storage_Site'" );
    ( my $parent_rack ) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FK_equipment__ID = $equipment_id and (FKParent_Rack__ID = 0 or FKParent_Rack__ID is NULL)" );

    ( my $rack_id ) = add_rack(
        -dbc                => $dbc,
        -equipment_id       => $equipment_id,
        -number             => 1,
        -parent             => $parent_rack,
        -type               => 'Box',
        -specified_prefix   => $rack_name,
        -shipping_container => 1
    );
    return $rack_id;
}

###############################
# Description:
#	This method returns contents of a rack
#	It looks and finds what the content of the rack and its children are
#
# Input:
#	Rack ID ( type HAS to be 'Box')
#	Fill    (enum row or column)  If positions are not in slots then this will give a position list based on this selection by row or column
#	quiet	Suppress messages
#	type
#
# Output:
#	hash reference
#	keys: Object names and positions for that object respectively
#	values: ids array object and array of positions for object_position
#   Output Example:
#			{ 	'Source' 			=> [1001,1002,1003],
#				'Source_Position' 	=> [A1,A2,B3],
#				'Plate' 			=> [5013,5014] ,
#				'Plate_Position'	=> [A3,B1]
#			}
#		WHERE 22 and 25 are the rack ids
# <snip>
# Usage:
#	my $rack_content = $rack_obj -> get_box_content (   -id 	=> $rack_id,
#														-fill       => 'row',
#   													-plate_type => $plate_type );
# </snip>
###############################
sub get_box_content {
###############################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $rack_id = $args{-id} || $self->{id};
    my $fill    = $args{-fill};
    my $quiet   = $args{-quiet};
    my $fill    = $args{-type};
    my @tables;
    my %list;

### This checks to make sure that rack is a box type
    my @found = $dbc->Table_find( 'Rack', 'Rack_Type', "WHERE Rack_ID IN ($rack_id)", -distinct => 1 );

    unless ( int @found == 1 && $found[0] eq 'Box' ) {
        $dbc->warning("Your Rack Needs to be a Box") unless $quiet;
        return;
    }

### First Check The content of the main Rack
    my ( $links, $details, $box_refs ) = $dbc->get_references( 'Rack', { 'Rack_ID' => $rack_id } );    ## third element is the hash of references

    my @box_objects = keys %$box_refs if $box_refs;
    my @box_object_temp = ();
    foreach my $box_obj (@box_objects) {

        # ignore Shipment, not a physical entity to track
        unless ( $box_obj =~ /Shipment/ ) {
            push @box_object_temp, $box_obj;
        }
    }
    @box_objects = @box_object_temp;

### Seoncd Lets Check Slots
    my $slots = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', " WHERE FKParent_Rack__ID IN ($rack_id)" );
    my ( $links, $details, $slot_refs ) = $dbc->get_references( 'Rack', { 'Rack_ID' => $slots } ) if $slots;    ## third element is the hash of references
    my @slot_objects = keys %$slot_refs if $slot_refs;

### Cant have both slots and box containing objects
### Fianlly get the content ids and positions
    if ( int @box_objects > 1 && int @slot_objects ) {
        $dbc->warning("Both Box and its Slots Contain Items") unless $quiet;

        #		return;
    }
    elsif ( int @slot_objects ) {
        for my $key (@slot_objects) {
            if ( $key =~ /^Rack\b/ ) {next}                                                                     ## ignore referencing racks
            if ( $key =~ /(.+)\./ ) {
                my $table = $1;
                my ($primary_field) = $dbc->get_field_info( -table => $table, -type => 'Primary' );
                my @info = $dbc->Table_find( $table . ',Rack', $primary_field . ',Rack_Name', "WHERE $key IN ($slots) and $key = Rack_ID" );
                my @ids;
                my @positions;
                for my $line (@info) {
                    my ( $obj_id, $position ) = split ',', $line;
                    push @ids,       $obj_id;
                    push @positions, $position;
                }
                $list{$table} = \@ids;
                $list{ $table . '_Position' } = \@positions;
            }
        }

    }
    elsif ( int @box_objects ) {
        for my $key (@box_objects) {
            if ( $key =~ /^Rack\b/ ) {next}
            if ( $key =~ /(.+)\./ ) {
                my $table = $1;
                my ($primary_field) = $dbc->get_field_info( -table => $table, -type => 'Primary' );
                my @ids = $dbc->Table_find( $table, $primary_field, "WHERE $key = $rack_id" );
                $list{$table} = \@ids;
                $list{ $table . '_Position' } = $self->get_position_array( -count => int @ids, -fill => $fill );
            }
        }

    }

    return \%list;

}

#
# Generate manifest for exporting samples
#
# * build plate_list
# * build source_list
# * define rack, child racks
# * define Manifest attribute fr current class
#
# Populates:
# * $Manifest->{plate_list}
# * $Manifest->{source_list}
# * $Manifest->{type}   eg ['Plate','Source']
# * $Manifest->{rack}
# * $Manifest->{child_racks}
#
########################
sub build_manifest {
########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc' );

    my $dbc             = $self->{dbc};
    my $rack            = $args{-rack};
    my $equipment       = $args{-equipment} || $args{-equipment_id};
    my $since           = $args{'-since'};
    my $until           = $args{'-until'};
    my $plate_list      = $args{-plate_list};
    my $source_list     = $args{-source_list};
    my $rack_list       = $args{-rack_list};
    my $manifest_fields = $args{-manifest_fields};
    my $title           = $args{-title};
    my $summary         = $args{-summary};

    my $header          = $args{-header};
    my $extra_condition = $args{-condition};
    my $item_types      = $args{-item_types};

    my $Manifest = {};    ## defined  manifest object (sub class of self)
    $Manifest->{extra_condition} = [];
    $Manifest->{item_types}      = $item_types;

    $title ||= "Items found";
    if ($since) { $title .= " (since $since)" }
    if ($until) { $title .= " (until $until)" }

    if ( $since && $since !~ /\:/ ) { $since .= ' 00:00:00' }
    if ( $until && $until !~ /\:/ ) { $until .= ' 23:59:59' }

    if ($plate_list) {
        $title .= " from specified list";
    }

    my $transport_container;
    if ($rack) {
        my $rack_id = $dbc->get_FK_ID( 'FK_Rack__ID', $rack );

        my $child_racks = join ',', alDente::Rack::get_child_racks( $dbc, -rack_id=>$rack_list, -equipment_id=>$equipment);
        $title .= " in/on: '$rack'";
        $transport_container = alDente::Tools::alDente_ref( 'Rack', $rack, -dbc => $dbc );

        $Manifest->{transport_rack_id} = $rack_id;
        $Manifest->{scope}             = "Rac$rack_id";
        $Manifest->{child_racks}       = $child_racks;
    }

    ## <CONSTRUCTION> - what if BOTH rack, equipment ??
    if ($equipment) {
        my $equipment_id = $dbc->get_FK_ID( 'FK_Equipment__ID', $equipment );
        my $child_racks = join ',', alDente::Rack::get_child_racks( $dbc, -equipment_id => $equipment_id );

        $title .= " in '$equipment'";
        $transport_container = alDente::Tools::alDente_ref( 'Equipment', $equipment, -dbc => $dbc );

        $Manifest->{scope}       = "Equ$equipment";
        $Manifest->{child_racks} = $child_racks;
        push @{ $Manifest->{extra_condition} }, "FK_Equipment__ID=$equipment";
    }

    if ($extra_condition) { push @{ $Manifest->{extra_condition} }, $extra_condition }
    $Manifest->{title} = $title;

    if ( !( @{ $Manifest->{extra_condition} } || $since || $until || $Manifest->{child_racks} || $equipment ) ) {
        $dbc->warning("must specify some conditions or use valid racks to generate manifest");
        return;
    }

    $Manifest->{plate_list}  = $plate_list  || $self->get_manifest_content( -Manifest => $Manifest, -type => 'Plate',  -since => $since, -until => $until, -condition => $extra_condition, -manifest_fields => $manifest_fields, -summary=>$summary );
    $Manifest->{source_list} = $source_list || $self->get_manifest_content( -Manifest => $Manifest, -type => 'Source', -since => $since, -until => $until, -condition => $extra_condition, -manifest_fields => $manifest_fields, -summary=>$summary );
    $Manifest->{rack_list}   = $rack_list;
    $self->{Manifest}        = $Manifest;

    return $Manifest;
}

#
# Retrieve list of items based upon:
# - specified condition(s)
# - current 'child_racks' attribute (required)
#
# Keep track of context specific tables and conditions (stored as attribute)
# (so that same query can be generated with different grouping criteria for summaries)
#
# * $self->{plate_tables}
# * $self->{plate_conditions}
#
# * $self->{source_tables}
# * $self->{source_conditions}
#
############################
sub get_manifest_content {
############################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $Manifest = $args{-Manifest};
    my $type     = $args{-type};
    my $since    = $args{-since};
    my $until    = $args{ -until };
    my $extra_condition = $args{-condition};
    my $debug           = $args{-debug};
    my $manifest_fields = $args{-manifest_fields};
    my $summary = $args{-summary};
    
    my $dbc             = $self->{dbc};

    my $rack = $args{-rack} || $Manifest->{child_racks};    ## comma-delimited list ok.
    if ( !$rack ) { $dbc->warning("Manifest must be tied to a Location"); return []; }

    my ( $key, $group );

    my ( @id_list, @found );
    my ( $tables, $condition, $fields );

    my $using_default_fields = 0;
    if ( $type eq 'Plate' ) {

        $tables = 'Plate,Plate_Sample,Sample,Source,Original_Source,Sample_Type,Plate_Format,Rack,Equipment,Location';
        $condition
            = "WHERE Plate_Sample.FK_Sample__ID=Sample_ID AND Plate_Sample.FKOriginal_Plate__ID=Plate.FKOriginal_Plate__ID AND Sample.FK_Source__ID=Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND Plate.FK_Sample_Type__ID=Sample_Type_ID AND Plate.FK_Plate_Format__ID=Plate_Format_ID AND Plate.FK_Rack__ID=Rack_ID AND Rack.FK_Equipment__ID=Equipment_ID AND Equipment.FK_Location__ID=Location_ID";

        if ($rack) {
            ## for some reason the query itself executes much slower than it should, so we can speed things up for inapplicable cases this way - Don't return directly since Manifest keys are defined below .... ##
            $extra_condition .= " AND Plate.FK_Rack__ID IN ($rack)";
            @found = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE FK_Rack__ID IN ($rack)" );
        }
        
        if ($manifest_fields && @$manifest_fields) {
            my @final_list;
            my @field_list = @$manifest_fields;
            for my $item (@field_list) {
                if ( $item =~ /Plate\./ ) {
                    push @final_list, $item;
                }
            }
            $fields = \@final_list;
        }
        else {
            $using_default_fields++;
            $fields = [
                'Plate.FK_Plate_Format__ID',
                'Plate_ID as Container_ID',
                'Plate_ID as Plate',
                'Plate.FKOriginal_Plate__ID as Sample',
                'Plate.FK_Sample_Type__ID',
                "Concat(Current_Volume,' ',Current_Volume_Units) as Quantity",
                'To_Days(Current_Date()) - To_Days(Plate_Created) as Days_Old'
            ];
        }
        $key ||= "concat(Plate.FK_Library__Name,'-',Plate.Plate_Number) as Plate";    ## count contents by this key eg 'Original_Source_Name as Subject'
        $group = 'Plate_ID';
        if ($since) { $extra_condition .= " AND Plate_Created >= '$since'" }
        if ($until) { $extra_condition .= " AND Plate_Created <= '$until'" }

        my $transport_container;
    }
    elsif ( $type eq 'Source' ) {
        $tables    = '(Source,Original_Source,Rack,Equipment,Location, Anatomic_Site) LEFT JOIN Plate_Format ON Source.FK_Plate_Format__ID=Plate_Format_ID';
        $condition = "WHERE Source.FK_Original_Source__ID=Original_Source_ID AND Original_Source.FK_Anatomic_Site__ID=Anatomic_Site_ID AND Source.FK_Rack__ID=Rack_ID AND Rack.FK_Equipment__ID=Equipment_ID AND Equipment.FK_Location__ID=Location_ID ";

        if ($rack) {
            ## for some reason the query itself executes much slower than it should, so we can speed things up for inapplicable cases this way - Don't return directly since Manifest keys are defined below ....##
            $extra_condition .= " AND Source.FK_Rack__ID IN ($rack)";
            @found = $dbc->Table_find( 'Source', 'Source_ID', "WHERE FK_Rack__ID IN ($rack)" );
        }

        if ($manifest_fields) {
            my @final_list;
            my @field_list = @$manifest_fields;
            for my $item (@field_list) {
                if ( $item =~ /Source\./ ) {
                    push @final_list, $item;
                }
            }
            $fields = \@final_list;
        }
        else {
            $using_default_fields++;
            $fields = [
                'Source_ID as Source_ID',
                'Source.FK_Original_Source__ID as Sample_Origin',
                'Source.External_Identifier as External_Identifier',
                'Source.Source_Label as Label',
                'Source.FK_Plate_Format__ID as Plate_Format',
                'Source.FK_Sample_Type__ID as Sample_Type',
                'Original_Source.FK_Anatomic_Site__ID as Anatomic_Site',
                "Concat(Current_Amount,' ',Amount_Units) as 'Quantity'",
            ];
        }

        $key ||= "Concat(FK_Taxonomy__ID,' : ', Anatomic_Site_Alias) as Anatomic_Site";    ## count contents by this key eg 'Original_Source_Name as Subject'

        if ($since) { $extra_condition .= " AND Received_Date >= '$since'" }
        if ($until) { $extra_condition .= " AND Received_Date <= '$until'" }

        my $transport_container;
    }

    if ($tables) {
        if ($summary) { 
            
            if ($using_default_fields) { $fields = [] }  ## clear single record fields used by default if summary selected 
        
            push @$fields, "Count(*) as Samples";
            $group = "FK_Plate_Format__ID, FK_Sample_Type__ID";
        }

        my $manifest;
        if (@found) {
            ## only retrieve details if samples of specified type were actually found ##
            @id_list = $dbc->Table_find( $tables, "${type}_ID", "$condition $extra_condition", -distinct => 1 );

            if ( !@id_list ) { return \@id_list }
            $manifest = $dbc->Table_retrieve_display(
                 $tables, 
                 $fields, 
                 "$condition $extra_condition",
                -group         => $group,
                -return_html   => 1,
                -excel_link    => 1,
                -print_link    => $type,
                -title         => "Manifest of $type Records",
                -total_columns => 'Quantity',
                -debug         => $debug,
            );

        }

        $Manifest->{"${type}_manifest"} = $manifest;
    }
    else {
        $dbc->warning("Manifest not currently available for $type records");
    }

    $Manifest->{"${type}_tables"}     = $tables;
    $Manifest->{"${type}_conditions"} = $condition;
    $Manifest->{"${type}_list"}       = \@id_list;

    my $alias = $type;
    if ($dbc->config('Barcode_Prefix') && $dbc->config('Barcode_Prefix')->{$type}) {  $alias = $dbc->config('Barcode_Prefix')->{$type} }
    if (@id_list) { $dbc->message( int(@id_list) . " $alias records found" ) }

    return \@id_list;
}

###############################
# Description:
#
# Input:
#
# Output:
#
###############################
sub get_position_array {
###############################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc};
    my $count = $args{-count};
    my $fill  = $args{-fill};

    my @position;
    if ($fill) {

        #	 @positions = $dbc -> Table_find ();

    }

    return \@position;
}

#
# Moves boxes from one site to another (or to/from 'In Transit')
# Resets status of containers to/from 'In Transit'
#
###############################
sub set_shipping_status {
###############################
    my %args  = filter_input( \@_, -args => 'dbc' );
    my $dbc   = $args{-dbc};
    my $boxes = $args{-boxes};
    my $list  = $args{-list};                          # hash of items to move (eg -list => {'Plate' =>[55,56,57], 'Source' => [5,6,7]

    my $target      = $args{-target};
    my $site_equip  = $args{-site_equip};              ## target rack if specified
    my $transit     = $args{-transit};                 ## flag to indicate samples in transit.
    my $shipment_id = $args{-shipment_id};
    my $debug       = $args{-debug};

    if ( !$site_equip ) {
        ($site_equip) = $dbc->Table_find( 'Equipment,Location,Site', 'Equipment_ID', "WHERE FK_Site__ID=Site_ID AND FK_Location__ID=Location_ID AND Equipment_Name like 'Site-%' AND Site_ID = '$target'" );
    }

    my %List = %{$list};

    my $equip_status = 'In Use';
    my $status       = 'Active';
    my $transit_loc;
    if ($transit) {
        $status       = 'Exported';
        $equip_status = 'In Transit';
        ($site_equip)  = $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_Name = 'In Transit'" );
        ($transit_loc) = $dbc->Table_find( 'Location',  'Location_ID',  "WHERE Location_Name = 'In Transit'" );
    }

    my @included_boxes;
    my @types = keys %List;
    foreach my $type (@types) {
        my @fields;
        my @values;
        my $ids = Cast_List( -list => $List{$type}, -to => 'string', -autoquote => 1 );

        my $ids = Cast_List( -list => $List{$type}, -to => 'string', -autoquote => 1 );
        if ( $target && $type eq 'Equipment' ) {
            ## only for cases in which entire Freezer is transported ##
            push @fields, 'Equipment_Status', 'FK_Location__ID';
            push @values, $equip_status, $transit_loc;
        }
        elsif ( $target && $type eq 'Rack' ) {
            ## NO ACTION REQUIRED
            my $id_list = $ids;
            $id_list =~s/['"]//g;
            push @included_boxes, $id_list;
        }
        else {
            push @fields, "${type}_Status";
            push @values, $status;
        }
        my $comment;
        if ($shipment_id) { $comment = "Shipment $shipment_id" }

        if (@fields) {
            my $ok = $dbc->Table_update_array( $type, \@fields, \@values, "WHERE ${type}_ID IN ($ids)", -autoquote => 1, -debug => $debug, -comment => $comment );
        }

        ## set the Plate_Status to 'Inactive' instead of 'Active' for Failed plates
        if ( $type eq 'Plate' && $status eq 'Active' ) {
            my $Container_Obj = new alDente::Container( -dbc => $dbc );
            my $failed = $Container_Obj->get_plates( -failed => 'Yes', -id => $ids );
            if ( int(@$failed) ) {
                ## set the Plate_Status to 'Inactive' for Failed plates
                my $ok = alDente::Container::set_plate_status( -dbc => $dbc, -plate_id => $failed, -status => 'Inactive' );
            }
        }
    }

    if ( $shipment_id && $status eq 'Active' ) { alDente::Shipment::receive_Shipment( $dbc, $shipment_id ) }

    if ($site_equip) {
        if ($debug) { $dbc->message( "Move boxes: $boxes to Equ $site_equip: " . alDente_ref( 'Equipment', $site_equip, -dbc => $dbc ) ) }

        $boxes .= Cast_List(-list=>\@included_boxes, -to=>'string');
        
        Move_Racks(
            -dbc          => $dbc,
            -no_print     => 1,             ## should we leave the name or change to In Transit: S1-R2 (for example)
            -source_racks => $boxes,
            -equip        => $site_equip,
            -confirmed    => 1
        );
    }
    else {
        $dbc->warning("No site location ($site_equip) for shipping boxes ($boxes) to Location $target");
    }

    return;
}

#
#
# Generate temporary parent location barcode for tracking bulk movement of existing racks (eg boxes)
#
# Return: new Rack barcode ID
##################################
sub generate_transport_rack {
##################################
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $racks = $args{-rack_list};
    my $debug = $args{-debug};

    my $rack_list = Cast_List( -list => $racks, -to => 'string' );

    ## Current site where these racks are located ##

    my ($site_equip) = $dbc->Table_find( 'Equipment', 'Equipment_ID', "WHERE Equipment_Name LIKE 'In Transit'", -debug => $debug );
    if ( !$site_equip ) { $dbc->error("Cannot find transport record") }

    my ($new_rack) = add_rack(
        -dbc                => $dbc,
        -equipment_id       => $site_equip,
        -type               => 'Shelf',
        -shipping_container => 1
    );
    unless ($rack_list) {
        Move_Racks(
            -dbc          => $dbc,
            -leave_name   => 1,
            -source_racks => $rack_list,
            -target_rack  => $new_rack,
            -confirmed    => 1,
            -in_transit   => 1,
            -debug        => $debug,
        );
    }
    return $new_rack;
}

#########################
sub rack_change_history_trigger {
#########################
    my %args              = filter_input( \@_ );
    my $dbc               = $args{-dbc};
    my $change_history_id = $args{-change_history_id};

    my %change_history = $dbc->Table_retrieve(
        'Change_History,DBField,Rack as Old_Rack,Rack as New_Rack',
        [ 'Field_Table', 'Old_Value', 'New_Value', 'Old_Rack.Rack_Alias as Old_Alias', 'New_Rack.Rack_Alias as New_Alias' ],
        "WHERE FK_DBField__ID = DBField_ID and Change_History_ID = $change_history_id and Old_Rack.Rack_ID = Old_Value and New_Rack.Rack_ID = New_Value and Field_Name like '%FK_Rack__ID%'"
    );
    my $old_value = $change_history{'Old_Value'}[0];
    my $new_value = $change_history{'New_Value'}[0];
    my $old_alias = $change_history{'Old_Alias'}[0];
    my $new_alias = $change_history{'New_Alias'}[0];
    if ( $old_value && $new_value ) {
        my $ok = $dbc->Table_update_array( 'Change_History', ['Comment'], ["Moved Rac$old_value:$old_alias to Rac$new_value:$new_alias"], "WHERE Change_History_ID = $change_history_id", -autoquote => 1 );

    }

    return 0;
}

#########################
sub rack_change_history_batch_trigger {
#########################
    my %args              = filter_input( \@_, -args => 'dbc,change_history_id' );
    my $dbc               = $args{-dbc};
    my $change_history_id = $args{-change_history_id};                               # array ref

    my @ids;
    if ( ref($change_history_id) eq 'ARRAY' ) {
        @ids = @$change_history_id;
    }
    else {
        @ids = ($change_history_id);
    }
    my $id_list = Cast_List( -list => \@ids, -to => 'String', -autoquote => 1 );

    my %change_history = $dbc->Table_retrieve(
        'Change_History,DBField,Rack as Old_Rack,Rack as New_Rack',
        [ 'Change_History_ID', 'Field_Table', 'Old_Value', 'New_Value', 'Old_Rack.Rack_Alias as Old_Alias', 'New_Rack.Rack_Alias as New_Alias' ],
        "WHERE FK_DBField__ID = DBField_ID and Change_History_ID in ( $id_list ) and Old_Rack.Rack_ID = Old_Value and New_Rack.Rack_ID = New_Value and Field_Name like '%FK_Rack__ID%'"
    );
    my %updates;
    my $index = 0;
    while ( defined $change_history{'Change_History_ID'}[$index] ) {
        my $old_value = $change_history{'Old_Value'}[$index];
        my $new_value = $change_history{'New_Value'}[$index];
        my $old_alias = $change_history{'Old_Alias'}[$index];
        my $new_alias = $change_history{'New_Alias'}[$index];
        if ( $old_value && $new_value ) {
            my $comment = "Moved Rac$old_value:$old_alias to Rac$new_value:$new_alias";
            if ( exists $updates{$comment} ) {
                push @{ $updates{$comment} }, $change_history{'Change_History_ID'}[$index];
            }
            else {
                $updates{"Moved Rac$old_value:$old_alias to Rac$new_value:$new_alias"} = [ $change_history{'Change_History_ID'}[$index] ];
            }
        }
        $index++;
    }
    if ( scalar( keys %updates ) ) {
        foreach my $comment ( keys %updates ) {
            my $ids     = Cast_List( -list => $updates{$comment}, -to => 'String', -autoquote => 1 );
            my $command = "UPDATE Change_History" . " SET Comment = '$comment'" . " WHERE Change_History_ID in ( $ids )";
            my $ok      = $dbc->execute_command( -command => $command );
        }
    }

    return 0;
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

2003-11-27

=head1 REVISION <UPLINK>

$Id: Rack.pm,v 1.38 2004/11/25 01:43:41 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
