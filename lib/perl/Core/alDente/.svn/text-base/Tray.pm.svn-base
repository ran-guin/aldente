#################
# alDente/Tray.pm
####################
package alDente::Tray;

##############################
# perldoc_header             #
##############################
##############################
# superclasses               #
##############################
### Inheritance
@ISA = qw(Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;

use SDB::CustomSettings;
use SDB::DBIO;
use alDente::Validation;
use SDB::HTML;
use SDB::Transaction;
use RGTools::RGIO;
use RGTools::Conversion qw(extract_range);

use vars qw($Connection $testing %Prefix);

### <CONSTRUCTION> This moodule should be changed so that it's not plate specific, should take in an object name

###########################
# Constructor of the object
###########################
sub new {
#########
    my $this  = shift;
    my %args  = &filter_input( \@_, -args => 'tray' );
    my $class = ref($this) || $this;

    my $dbc       = $args{-dbc}       || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tray_ids  = $args{-tray_ids}  || $args{-tray};
    my $plate_ids = $args{-plate_ids} || $args{-plates};                                                   # Load up a tray that has this plate on it
    my $newtray = $args{ -new };                                                                           # (HASH) To create a tray object, can be written to database later on

    my $check_for_partial_plates = $args{-check_for_partial_plates};

    my $self;
    $self->{dbc}      = $dbc;                                                                              # DB Handle
    $self->{tray_ids} = $tray_ids if ($tray_ids);                                                          # Plate number
    $self->{newtray}  = $newtray if ($newtray);                                                            # (HASH) Content of the tray

    bless $self, $class;

    if ( $tray_ids && $check_for_partial_plates ) { $self->check_for_partial_plates($check_for_partial_plates) }    ## define quadrants used if tray_ids supplied (eg Tra123b signifies only the b quadrant of Tra123)

    if ( $self->{tray_ids} ) {
        $self->load( -tray_ids => $self->{tray_ids} );

    }
    elsif ($plate_ids) {
        $self->load( -plate_ids => $plate_ids );
    }

    return $self;
}

###############################
sub check_for_partial_plates {
    ########################
    my $self   = shift;
    my $string = shift;

    foreach my $tray ( split ',', $self->{tray_ids} ) {
        while ( $string =~ /Tra$tray\(([a-d,\-1-8]+)\)/si ) {    ## should match pattern in DBIO::get_id and Scanner::Check_Scan_Options
            my $pattern = $1;
            my $quad    = extract_range($pattern);
            $self->{quadrants}{$tray} .= $quad;
            $string =~ s /Tra$tray\($pattern\)//i;
        }
    }
    return;
}
##############################
#
# $self->load();
#
# Returns: $self
#
####################
sub load {
####################
    my $self      = shift;
    my %args      = &filter_input( \@_, -mandatory => 'plate_ids|tray_ids' );
    my $plate_ids = $args{-plate_ids};
    my $tray_ids  = $args{-tray_ids};
    my $dbc       = $self->{dbc};

    ## If plate_ids are provided, retrieve the tray numbers for those plates
    if ( $plate_ids && !$tray_ids ) {
        $tray_ids = join ',', $dbc->Table_find( 'Plate_Tray', 'FK_Tray__ID', "WHERE FK_Plate__ID IN ($plate_ids)", -distinct => 1 );
    }

    unless ($tray_ids) {
        return undef;
    }

    ## Retrieve the trays
    my %plates = &Table_retrieve( $self->{dbc}, 'Plate_Tray,Tray', [ 'FK_Tray__ID', 'FK_Plate__ID', 'Plate_Position', 'Tray_Label' ], "WHERE Tray_ID = FK_Tray__ID and FK_Tray__ID IN ($tray_ids)" );

    my %Tray;
    my $index = 0;
    my %Tray_Labels;
    while ( defined $plates{FK_Tray__ID}->[$index] ) {
        $Tray{ $plates{FK_Tray__ID}->[$index] }{ $plates{Plate_Position}->[$index] } = $plates{FK_Plate__ID}->[$index];

        #$Tray{$plates{FK_Tray__ID}->[$index]}{Tray_Label} = $plates{Tray_Label}->[$index];
        $Tray_Labels{ $plates{FK_Tray__ID}->[$index] } = $plates{Tray_Label}->[$index];
        $index++;
    }
    $self->{tray_labels} = \%Tray_Labels;
    $self->{tray_ids}    = $tray_ids;
    $self->{trays}       = \%Tray;

    ### Create the ordered list of plate ids
    if ($plate_ids) {
        $self->{ordered_plates} = [ split( ',', $plate_ids ) ];
    }
    else {
        my @ordered_list;
        foreach my $tid ( split( ',', $tray_ids ) ) {
            my @pos_list = &Table_find( $self->{dbc}, 'Plate_Tray', 'Plate_Position', "WHERE FK_Tray__ID=$tid ORDER BY Plate_Position ASC" );
            foreach my $pos (@pos_list) {
                if ( $self->{trays}{$tid}{$pos} ) {
                    if ( $self->{quadrants}{$tid} && ( $self->{quadrants}{$tid} !~ /$pos/ ) ) {next}    ## exclude plate from this position if not included in specified quadrant list
                    push( @ordered_list, $self->{trays}{$tid}{$pos} );
                }
            }
        }
        $self->{ordered_plates} = \@ordered_list;
    }
    $self->_update_tray_index();

    return $self;
}

#
# $self->create(-plate_ids => '123,213,1235,1232', -label => 'My Label');
#
#
####################
sub create {
####################
    my $self      = shift;
    my %args      = &filter_input( \@_, -mandatory => 'plate_ids' );
    my $plate_ids = $args{-plate_ids};
    my $label     = $args{-label};
    my $dbc       = $self->{dbc};

    unless ($plate_ids) {
        $dbc->error('No plate ids supplied');
        return;
    }

    my %info = $dbc->Table_retrieve( 'Plate,Rack', [ 'Plate_ID', 'Rack_Name' ], "WHERE Plate_ID IN ($plate_ids) AND FK_Rack__ID = Rack_ID" );
    my $tray_id = $dbc->Table_append_array( 'Tray', ['Tray_Label'], [$label], -autoquote => 1 );
    my %values;
    my $size = int @{ $info{Plate_ID} };
    for my $index ( 1 .. $size ) {
        my @temp = ( $info{Plate_ID}[ $index - 1 ], $tray_id, $info{Rack_Name}[ $index - 1 ] );
        $values{$index} = \@temp;

    }

    my $results = $dbc->smart_append( -tables => 'Plate_Tray', -fields => [ 'FK_Plate__ID', 'FK_Tray__ID', 'Plate_Position' ], -values => \%values, -autoquote => 1 );

    return $tray_id;

}

########################################
#
# Function to store the tray that has just been created into the database
#
# $self->{newtray} must exist and there should not be any $self->{trays} (Since this means that the data is already stored in the db)
#
####################
sub store {
####################
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'tray_id,tray_label' );
    my $tray_id    = $args{-tray_id};                                      ### Optional tray number
    my $tray_label = $args{-tray_label};

    my $dbc = $self->{dbc};

    my $error;
    $dbc->start_trans('store_tray');

    if ( $self->{newtray} && !$self->{trays} ) {
        my @fields = qw(FK_Tray__ID FK_Plate__ID Plate_Position);
        my %Tray;
        my $index;

        if ( !$tray_label ) {
            ## if all plates have the same label - apply it to the tray ##
            my $contained_plates = join ',', values %{ $self->{newtray} };
            my @labels = $dbc->Table_find( 'Plate', 'Plate_Label', "WHERE Plate_ID IN ($contained_plates)", -distinct => 1 );

            if ( $labels[0] && ( int(@labels) == 1 ) ) { $tray_label = $labels[0] }
            elsif ( int(@labels) > 1 ) {
                ## more than one distinct label ##
                $tray_label = "**";    ## differentiate from no label ##
            }
        }

        ## Create a new Tray
        if ($tray_id) {
            $dbc->Table_append_array( 'Tray', [ 'Tray_ID', 'Tray_Label' ], [ $tray_id, $tray_label ], -autoquote => 1 );
        }
        else {
            $tray_id = $dbc->Table_append_array( 'Tray', [ 'Tray_ID', 'Tray_Label' ], [ 0, $tray_label ], -autoquote => 1 );
        }

        ## Create the insert entries for our new tray
        foreach my $position ( keys %{ $self->{newtray} } ) {
            $Tray{ ++$index } = [ $tray_id, $self->{newtray}->{$position}, $position ];
        }

        my $newids = $dbc->smart_append( -tables => 'Plate_Tray', -fields => \@fields, -values => \%Tray, -autoquote => 1 );
        if ( $newids->{Plate_Tray}->{newids} ) {
            ## Update the $self object, to reflect the storage of the object in the DB
            $self->{tray_ids} = $tray_id;
            $self->{trays}->{$tray_id} = $self->{newtray};
            delete $self->{newtray};
            $self->_update_tray_index();
        }
        else {
            $error = "Error appending";
        }

        #    Message("Tracking ". join(',',keys %{$self->{plates}}). " on new tray: $tray_id");
    }
    else {
        $error = "Cannot save an uninitialized tray object";
    }

    $dbc->finish_trans( 'store_tray', -error => $error );
    return;
}

########################################
#
#  Create a series of trays given a list of plate ids
#  If Pack is provided, it will try to pack the 96-well plates into as little 384-well plates as possible, using the order
#   of the plates it will fill from a-d and move on to the next 384 well plate.
#  Else it will try to store the 96-well plates into 384-well plates keeping their plate_position same as parent_quadrants,
#   and also groups the plates from the same original plate id in the same 384-well plate.
#  Returns an array reference of all the new tray ids
#
###############################
sub create_multiple_trays {
###############################

    my %args = &filter_input( \@_, -args => 'dbc,plates,pack,pos_list' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $plate_ref  = $args{-plates};
    my $pack       = $args{ -pack };
    my $pos_list   = $args{-pos_list};
    my $tray_label = $args{-tray_label};
    my @plates;
    my @newtrays;

    if ($plate_ref) {
        @plates = @{$plate_ref};
    }
    else {
        Message("Can not create a tray with no plates");
        return 0;
    }

    ## There are 2 types of transfers: 1) 96->384 (Which "pack" is automatically assumed)
    ##                                 2) 384->384 (Which is a Tray to Tray xfer, plate_positions are maintained)
    ##                                 3) 384->384 but quadrants have been selected, Creates Tray with positions maintained unless Pack selected

    my %newtrays;
    my @tray_order;

    if ($pack) {
        foreach my $plate_id (@plates) {
            $dbc->message("Distribute wells on plates");    ## @$pos_list on $plate_id");
            _distribute_on_tray( \%newtrays, $plate_id, -pos_list => $pos_list );
            @tray_order = sort { $a <=> $b } keys %newtrays;
        }
    }
    else {
        ## Get all the trays for the parents
        my $plate_ids = join( ',', @plates );

        my %info = &Table_retrieve( $dbc, 'Plate LEFT JOIN Plate_Tray ON FKParent_Plate__ID=FK_Plate__ID', [ 'Plate_ID', 'FK_Tray__ID', 'Plate_Position' ], "WHERE Plate_ID IN ($plate_ids)" );

        ## Not tray to tray transfer, order them by their original plates
        my %info2 = &Table_retrieve( $dbc, 'Plate', [ 'Plate_ID', 'FKOriginal_Plate__ID', 'Parent_Quadrant', 'Plate_Size', 'FKParent_Plate__ID' ], "WHERE Plate_ID IN ($plate_ids)" );
        $info{FKOriginal_Plate__ID} = $info2{FKOriginal_Plate__ID};
        $info{Parent_Quadrant}      = $info2{Parent_Quadrant};
        my $size       = $info2{Plate_Size}->[0];
        my $used_wells = Cast_List( -list => $pos_list, -to => 'String' );
        my $unused     = join ',', &alDente::Library_Plate::not_wells( $used_wells, $size );
        if ($unused) {
            my $ok = $dbc->Table_update_array( 'Library_Plate', ['Unused_Wells'], ["'$unused'"], "where FK_Plate__ID IN ($plate_ids)" );
        }

        my $data = rekey_hash( \%info, 'Plate_ID' );
        foreach my $plate_id (@plates) {
            my $index;

            if ( $data->{$plate_id}{FK_Tray__ID}[0] ) {
                $index = $data->{$plate_id}{FK_Tray__ID}[0];

                ### Could be overwritten if same quadrant of the same parent tray
                #$newtrays{$index}{ $data->{$plate_id}{Plate_Position}[0] } = $plate_id;

                #Allowing mulitple of the same parent tray
                push( @{ $newtrays{$index}{ $data->{$plate_id}{Plate_Position}[0] } }, $plate_id );

                push( @tray_order, $index ) if ( !grep( /^$index$/, @tray_order ) );
            }
            elsif ( $data->{$plate_id}{Parent_Quadrant}[0] ) {
                ## If does not already exist on a tray, look for their original plate ids
                $index = $data->{$plate_id}{FKOriginal_Plate__ID}[0];

                ### Could be overwritten if same quadrant of the same original plate
                #$newtrays{$index}{ $data->{$plate_id}{Parent_Quadrant}[0] } = $plate_id;

                #Allowing mulitple of the same quadrant of the same original plate
                push( @{ $newtrays{$index}{ $data->{$plate_id}{Parent_Quadrant}[0] } }, $plate_id );

                push( @tray_order, $index ) if ( !grep( /^$index$/, @tray_order ) );
            }
            else {
                _distribute_on_tray( \%newtrays, $plate_id, -pos_list => $pos_list );
                @tray_order = sort { $a <=> $b } keys %newtrays;
            }
        }
    }

    foreach my $tray_ref (@tray_order) {
        ## This is just for one copy of a tray
        #my $newtray = alDente::Tray->new( -dbc => $dbc, -new => $newtrays{$tray_ref} );
        #$newtray->store( -tray_label => $tray_label );
        #if ( $newtray->{tray_ids} ) {
        #    push( @newtrays, split ',', $newtray->{tray_ids} );
        #}
        #else {
        #    Message("Error storing tray");
        #    print HTML_Dump( $newtray, $tray_ref, \%newtrays );
        #    Call_Stack();
        #}

        ## Allowing multiple copy of a tray
        my %data;    # a hash contain tray data e.g { a => 5000, b => 5001, c => 5002, d -> '' }

        my $max_array_size;    # to get the quadrant that has the most plates
        for my $key ( keys %{ $newtrays{$tray_ref} } ) {
            if ( @{ $newtrays{$tray_ref}{$key} } > $max_array_size ) {
                $max_array_size = @{ $newtrays{$tray_ref}{$key} };
            }
        }

        ## create multiple tray, $max_array_size of trays will be created, first one will be most full, then second one, the third one and so forth
        for ( my $i = 0; $i < $max_array_size; $i++ ) {
            for my $key ( keys %{ $newtrays{$tray_ref} } ) {
                if ( $i >= @{ $newtrays{$tray_ref}{$key} } ) {

                    #if this quadrant has no more plate, do nothing
                }
                else {

                    #this quadrant still has plate
                    $data{$key} = $newtrays{$tray_ref}{$key}[$i];
                }
            }

            #Create tray with the data
            my $newtray = alDente::Tray->new( -dbc => $dbc, -new => \%data );
            $newtray->store( -tray_label => $tray_label );
            if ( $newtray->{tray_ids} ) {
                push( @newtrays, split ',', $newtray->{tray_ids} );
            }
            else {
                Message("Error storing tray");
                print HTML_Dump( $newtray, $tray_ref, \%newtrays );
                Call_Stack();
            }
        }
    }

    return @newtrays;
}

########################################
#
# Distributes the list of ids on the hash
#
###############################
sub _distribute_on_tray {
###############################
    my %args     = &filter_input( \@_, -args => 'hash_ref,id' );
    my $hash_ref = $args{-hash_ref};
    my $id       = $args{-id};
    my $pos_list = $args{-pos_list};

    my $pos        = 0;
    my $tray_count = 0;

    while (1) {
        if ( $hash_ref->{$tray_count} ) {
            if ( $hash_ref->{$tray_count}{ $pos_list->[$pos] } ) {
                $pos++;
                unless ( $pos_list->[$pos] ) {
                    $pos = 0;
                    $tray_count++;
                }

            }
            else {

                #$hash_ref->{$tray_count}{ $pos_list->[$pos] } = $id;
                #allow multiple
                push @{ $hash_ref->{$tray_count}{ $pos_list->[$pos] } }, $id;
                return;
            }
        }
        else {

            #$hash_ref->{$tray_count}{ $pos_list->[$pos] } = $id;
            #allow multiple
            push @{ $hash_ref->{$tray_count}{ $pos_list->[$pos] } }, $id;
            return;
        }
    }
}

########################################
#
# Input: Database handle, Object name, Object ID
# Output: Tray_ID
#
####################
sub exists_on_tray {
####################
    my %args = &filter_input( \@_, -args => 'dbc,object,id', -mandatory => 'dbc,object,id' );
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $object = $args{-object};
    my $id     = $args{-id};

    my $table_name = $object . '_Tray';
    my $fk_field   = 'FK_' . $object . '__ID';

    my ($tray_id) = $dbc->Table_find( $table_name, 'FK_Tray__ID', "WHERE $fk_field=$id" );

    return $tray_id;
}

###########################
sub convert_tray_to_plate {
###########################
    my %args = &filter_input( \@_, -args => 'dbc,barcode', -mandatory => 'dbc,barcode' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $barcode = $args{-barcode};

    my $barcode_copy = $barcode;
    while ( $barcode_copy =~ /TRA(\d+)\-TRA(\d+)/i ) {
        my @final;
        my $list = extract_range( $1 . '-' . $2 );
        my @list = split ',', $list;
        for my $item (@list) {
            push @final, 'TRA' . $item;
        }
        my $final = join '', @final;
        $barcode_copy =~ s/TRA\d+\-TRA\d+//i;
        $barcode_copy .= $final;
    }
    while ( $barcode_copy =~ /Tra(\d+)\(([a-d,\-1-8]+)\)/i ) {
        my $tray  = $1;
        my $quads = $2;
        my $plate = _tray_to_plate( $dbc, $tray, $quads, 'Pla' );
        $barcode_copy =~ s /Tra$tray\($quads\)/$plate/ig;
    }

    while ( $barcode_copy =~ /Tra(\d+)/i ) {
        my $tray = $1;
        my $plate = _tray_to_plate( $dbc, $tray, '', 'Pla' );
        $barcode_copy =~ s /Tra$tray(\D)/$plate$1/ig;
        $barcode_copy =~ s /Tra$tray$/$plate/i;
    }
    return $barcode_copy;
}

###########################
sub add_to_tray {
###########################
    my %args     = &filter_input( \@_, -args => 'dbc,plates,tray_id,pos_list', -mandatory => 'dbc,plates,tray_id,pos_list' );
    my $dbc      = $args{-dbc};
    my $plates   = $args{-plates};
    my $tray_id  = $args{-tray_id};
    my $pos_list = $args{-pos_list};

    # want to add tubes to an existing tray, need to check
    # - Wells not overlapping existing tray wells
    # - No prep applied on the tray yet
    #Check if input well duplicate with Plate_Tray position
    my $wells = join( ",", map {"\'$_\'"} @{$pos_list} );
    my ($duplicate_to_tray_pos) = $dbc->Table_find( "Plate_Tray", "Group_Concat(Plate_Position)", "WHERE FK_Tray__ID IN ($tray_id) AND Plate_Position IN ($wells)" );
    if ($duplicate_to_tray_pos) {
        $dbc->warning("Wells chosen ($duplicate_to_tray_pos) dupiicate with existing position in tray $tray_id. Can't add to tray.");
        return 0;
    }

    #check if any preps done on the tray, if there are, don't allow to add tray
    my ($preps_on_tray_pos) = $dbc->Table_find( "Plate_Tray,Plate_Prep,Prep,Lab_Protocol",
        "Prep_ID", "WHERE FK_Tray__ID IN ($tray_id) AND Plate_Tray.FK_Plate__ID = Plate_Prep.FK_Plate__ID AND FK_Prep__ID = Prep_ID AND FK_Lab_Protocol__ID = Lab_Protocol_ID AND Lab_Protocol_Name != 'Standard'" );
    if ($preps_on_tray_pos) {
        $dbc->warning("Tray $tray_id already has preps applied to it, so you can't add to the tray.");
        return 0;
    }

    my @fields = qw(FK_Plate__ID FK_Tray__ID Plate_Position);

    my $add_to_tray = 1;
    for ( my $index = 0; $index <= $#{$plates}; $index++ ) {
        my $ok = $dbc->Table_append_array( 'Plate_Tray', \@fields, [ $plates->[$index], $tray_id, $pos_list->[$index] ], -autoquote => 1 );
        if ($ok) { $dbc->session->message("Adding $plates->[$index] to $pos_list->[$index] of tray $tray_id") if $dbc->session }
        else     { $add_to_tray = 0 }
    }
    return $add_to_tray;
}

###########################
sub _tray_to_plate {
###########################
    my $dbc    = shift;
    my $tray   = shift;
    my $quad   = shift || '';
    my $prefix = shift;

    my @plates;
    if ($quad) {
        $quad = extract_range($quad);
        foreach my $section ( split ',', $quad ) {
            my @plate = $dbc->Table_find( 'Plate_Tray,Plate', 'Plate_ID', "WHERE FK_Tray__ID=$tray AND FK_Plate__ID=Plate_ID AND Plate_Position = '$section'" );
            push @plates, @plate;
        }
    }
    else {
        my @plate = $dbc->Table_find( 'Plate_Tray,Plate', 'Plate_ID', "WHERE FK_Tray__ID=$tray AND FK_Plate__ID=Plate_ID ORDER BY Plate_Position" );
        push @plates, @plate;
    }

    my $list = join ',', @plates;
    if ($prefix) { $list =~ s /,/$prefix/g; $list = $prefix . $list; }

    return $list;
}

########################################
#
# Input: Tray_ID
# Output: List of IDs of objects on the Tray
#
####################
sub get_content {
####################
    my %args = &filter_input( \@_, -args => 'dbc,object,id', -mandatory => 'dbc,object,id' );
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $object = $args{-object};
    my $id     = $args{-id};

    my $table_name = $object . '_Tray';
    my $fk_field   = 'FK_' . $object . '__ID';

    my @ids = $dbc->Table_find( $table_name, $fk_field, "WHERE FK_Tray__ID=$id" );
    return @ids;

}

########################################
#
# Combines a set of IDs if they are already in Trays.
#
# For example lets say we have Tray 1 with contents Pla10 Pla11, and we pass the following IDs to the method: 1,2,3,10,11,12
#   then this method returns 0,1,2,3,3,4
#
# This method is also used to group the barcodes together. If all of the content of the tray are in the barcode, merges them into
#   a tray barcode
#
# Also this method can be used to retrieve statistics on the current barcode. Statistics such as:
#   How many individual barcodes are there
#   How many trays exist
#   How many plates exist that are on trays but are scanned individually
#
####################
sub group_ids {
####################
    my %args = &filter_input( \@_, -args => 'dbc,object,ids', -mandatory => 'dbc,object,ids' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $object   = $args{-object};
    my $ids      = $args{-ids};
    my $barcoded = $args{-barcoded};
    my $stats    = $args{-stats};

    my @ids;
    if ( ref($ids) =~ /ARRAY/i ) {
        @ids = @{$ids};
    }
    else {
        @ids = split( ',', $ids );
    }

    my $count;
    my %ids = map { $_ => 1 } @ids;

    my ( @groups, @barcodes );    ## the array that will be returned;

    my $singlets        = 0;      ## Count of plates on trays but scanned individually
    my $completes       = 0;      ## Count of complete trays
    my $individuals     = 0;      ## Count of plates that are not on trays at all
    my $physical_plates = 0;

    if ($stats) { $barcoded = 1 }
    ;                             ## just use this method to extract stats

    foreach my $id ( keys %ids ) {
        unless ( $ids{$id} ) {
            next;                 ## Making sure that this item is not used yet
        }
        $physical_plates++;

        #      print "Checking for $id\n";
        #      print Dumper(\%ids);

        ## See if the item exists on a tray
        my $tray_id = alDente::Tray::exists_on_tray( $dbc, $object, $id );

        if ($tray_id) {
            ## If item exists on a tray, get that tray's content and check to see if all present
            my @ids_on_tray = alDente::Tray::get_content( $dbc, $object, $tray_id );

            #	print "Exists on $tray_id\n";
            my $missing;
            foreach (@ids_on_tray) {
                if ( !$ids{$_} ) {

                    #	    print "$_ is missing from " . join(',',@ids_on_tray) . "\n";
                    $missing = 1;
                }
            }

            if ($missing) {
                ## This means the objects (plates) have been scanned individually and not through the tray id
                foreach (@ids_on_tray) {
                    if ( $ids{$_} ) {
                        push( @barcodes, $Prefix{$object} . $_ );
                        delete $ids{$_};
                        $singlets++;
                    }
                }
            }
            else {
                push( @barcodes, 'Tra' . $tray_id );

                #	  print "Deleting " . join(',',@ids_on_tray) . "\n";
                map { delete $ids{$_} } @ids_on_tray;
                $completes++;
            }
        }
        else {
            push( @barcodes, $Prefix{$object} . $id );
            $individuals++;
        }
    }

    my $index = 0;
    my $max   = scalar(@ids);

    for ( my $i = 0; $i < $max; $i++ ) {
        ## See if the item exists on a tray
        my $tray_id = alDente::Tray::exists_on_tray( $dbc, $object, $ids[$i] );

        if ($tray_id) {
            ## If item exists on a tray, get that tray's content
            my @ids_on_tray = alDente::Tray::get_content( $dbc, $object, $tray_id );
            my $items_on_tray = scalar(@ids_on_tray);
            my $items_missing;

            ## Check to see if items on the tray all exist in @ids and in the same order
            for ( my $j = 0; $j < $items_on_tray; $j++ ) {
                unless ( $ids_on_tray[$j] == $ids[ $j + $i ] ) {
                    $items_missing = 1;
                    last;
                }
            }

            ## If everything is the same
            if ($items_missing) {
                push( @groups, $index );
            }
            else {
                ## jump over these ids, already checked
                $i += $items_on_tray - 1;
                foreach (@ids_on_tray) {
                    push( @groups, $index );
                }
            }
        }
        else {
            push( @groups, $index );
        }
        $index++;
    }

    my %return;
    $return{barcodes} = \@barcodes;
    $return{grouped}  = \@groups;

    $return{tray_singlets}   = $singlets;
    $return{complete_trays}  = $completes;
    $return{nontray_plates}  = $individuals;
    $return{physical_plates} = $physical_plates;

    return \%return;
}

########################################
#
#  Updates the $self->{plates} hash
#
####################
sub _update_tray_index {
####################
    my $self = shift;
    foreach my $tray ( keys %{ $self->{trays} } ) {
        foreach my $q ( keys %{ $self->{trays}->{$tray} } ) {
            $self->{plates}{ $self->{trays}->{$tray}->{$q} }{tray}     = $tray;
            $self->{plates}{ $self->{trays}->{$tray}->{$q} }{quadrant} = $q;
        }
    }
}

sub add_prefix {
    my %args = &filter_input( \@_, -args => 'id', -mandatory => 'id' );
    my $id = $args{-id};

    return "Tra$id";
}

#################################
#
# Check if the specified tray(s) contains only tubes
#
# Usage:
#		my $tray_of_tubes = alDente::Tray->tray_of_tubes( -dbc => $dbc, -tray_ids => $tray_id );
#
# Return:
#		Scalar, 1 if the tray(s) contains all tubes; 0 if not
################################
sub tray_of_tubes {
################################
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'dbc,tray_ids' );
    my $dbc      = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $tray_ids = $args{-tray_ids} || $self->{tray_ids};

    my @not_tube = $dbc->Table_find( 'Plate_Tray,Plate', 'Plate_ID', "WHERE FK_Plate__ID = Plate_ID AND FK_Tray__ID in ($tray_ids) AND Plate_Size <>'1-well'" );
    if   (@not_tube) { return 0 }
    else             { return 1 }
}
