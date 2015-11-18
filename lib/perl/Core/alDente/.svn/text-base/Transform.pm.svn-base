###################################################################################################################################
# alDente::Transform.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package alDente::Transform;
use base SDB::DB_Object;    ## remove this line if object is NOT a DB_Object

use strict;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Progress;

use Benchmark;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;

## alDente modules

use vars qw( %Configs %Benchmark);

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id} || $args{-template_id};    ##

    # my $self = {};   ## if object is NOT a DB_Object

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Transform' );    ## if object IS a DB_Object (generally and class relating to database record)
    $self->{dbc} = $dbc;

    my ($class) = ref($this) || $this;
    bless $self, $class;

    if ($id) {
        ## $self->add_tables();  ## add tables to standard object if applicable (relationships that ALWAYS link records to other database records)
        $self->primary_value( -table => 'Transform', -value => $id );                 ## same thing as above..
        $self->load_Object();
    }

    return $self;
}

###########################
sub inherit_Attributes_from_Sources_to_Plates {
###########################
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'dbc,plates' );
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $source_ids = $args{-source_ids};
    my $target_ids = $args{-target_ids};
    my $debug      = $args{-debug};
    my @s_ids      = split ',', $source_ids;
    my @t_ids      = split ',', $target_ids;
    my $s_count    = @s_ids;
    my $t_count    = @t_ids;
    if ( $s_count != $t_count ) {
        Message "Warning: Cannot inherit attributes as the numbers do not match (Source:$s_count  Plate: $t_count)";
        return;
    }

    for my $index ( 0 .. $s_count - 1 ) {
        SDB::DB_Object::inherit_attributes_between_objects( -dbc => $dbc, -source => 'Source', -target => 'Plate', -source_id => $s_ids[$index], -target_id => $t_ids[$index], -skip_message => 1 );
    }

    return;
}

#########################################################################
# Script to run whenever a new Transform record is added to the database
#

###########################
sub get_Source_Fields {
###########################
    # Gets list of fields in source table that are not in exclude list
    #
###########################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'dbc' );
    my $dbc           = $args{-dbc};
    my @source_fields = $dbc->get_fields( -table => 'Source' );
    my @final_list;
    my @exclude_fields = (
        'Source_Status',          'Received_Date',         'FKReceived_Employee__ID',       'FK_Rack__ID',                       'Current_Amount',  'Original_Amount',
        'Amount_Units',           'FKSource_Plate__ID',    'FK_Plate_Format__ID',           'FKParent_Source__ID',               'FK_Shipment__ID', 'FK_Sample_Type__ID',
        'Source_Created',         'Current_Concentration', 'Current_Concentration_Units',   'Current_Concentration_Measured_by', 'Source_ID',       'Source_Number',
        'FK_Original_Source__ID', 'FK_Storage_Medium__ID', 'Storage_Medium_Quantity_Units', 'Storage_Medium_Quantity'
    );

    for my $field (@source_fields) {
        my $name;
        if ( $field =~ /Source\.(\w+) AS .+/ ) {
            $name = $1;
        }
        if ( !grep /^$name$/, @exclude_fields ) {
            push @final_list, $name;
        }
    }
    return @final_list;
}

###########################
sub get_NA_Fields {
###########################
    # Gets list of fields in Nucleic_Acid table that are not in exclude list
    #
###########################
    my $self          = shift;
    my %args          = filter_input( \@_, -args => 'dbc' );
    my $dbc           = $args{-dbc};
    my @source_fields = $dbc->get_fields( -table => 'Nucleic_Acid' );
    my @final_list;
    my @exclude_fields = ( 'Nucleic_Acid_ID', 'FK_Source__ID', );

    for my $field (@source_fields) {
        my $name;
        if ( $field =~ /Nucleic_Acid\.(\w+) AS .+/ ) {
            $name = $1;
        }
        if ( !grep /^$name$/, @exclude_fields ) {
            push @final_list, $name;
        }
    }
    return @final_list;
}

###########################
sub can_Simple {
###########################
    # Checks to see if the fast and simple method can be used for the case
    # Condition is that there can only be sample_types that their final parent is nucleic acid
    #
###########################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'dbc,plates' );
    my $dbc    = $args{-dbc};
    my $plates = $args{-plates};

    my %plates = $dbc->Table_retrieve( 'Plate, Sample_Type', ["Sample_Type"], "WHERE FK_Sample_Type__ID = Sample_Type_ID AND  Plate_ID IN ($plates)" );

    ## get parent sample_types
    my %sources = $dbc->Table_retrieve(
        'Plate, Sample, Source, Sample_Type',
        ["Sample_Type.Sample_Type"],
        "WHERE Plate.FKOriginal_Plate__ID = Sample.FKOriginal_Plate__ID and FK_Source__ID = Source_ID AND Source.FK_Sample_Type__ID = Sample_Type_ID AND Plate_ID IN ($plates)"
    );

    ### get map for sample type parents
    my @sample_type      = @{ $plates{Sample_Type} }  if $plates{Sample_Type};
    my @src_sample_types = @{ $sources{Sample_Type} } if $sources{Sample_Type};
    push @sample_type, @src_sample_types;

    my %st_map;
    for my $s_type (@sample_type) {
        if ( $st_map{$s_type} ) {next}
        my $sub_table = alDente::Source::get_main_Sample_Type( -find_table => 1, -dbc => $dbc, -sample_type => $s_type );
        $st_map{$s_type} = $sub_table;
    }
    my $size = keys %st_map;
    my ($type) = values %st_map;

    if   ( $size == 1 && $type eq 'Nucleic_Acid' ) { return 1 }
    else                                           {return}

}

###########################
sub simple_Source_Plate_transform {
###########################
    # A faster transformation only for nucleic acids
    # gathers info for all records then does smart append
    #
###########################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'dbc,plates' );
    my $dbc    = $args{-dbc};
    my $plates = $args{-plates};
    my $sm_id  = $args{-sm_id};
    my @records;
    my @db_tables = $dbc->DB_tables();
    my $user_id   = $dbc->get_local('user_id');
    $dbc->Benchmark('start_creation');

    ## get info in the system information based on plates

    my @source_fields = get_Source_Fields( -dbc => $dbc );
    my @na_fields     = get_NA_Fields( -dbc     => $dbc );
    push @source_fields, @na_fields;

    my @plate_fields = (
        'Plate_ID',                'Source_ID',                'Plate.FK_Plate_Format__ID', 'Current_Volume',               'Current_Volume_Units', 'Plate.FK_Rack__ID',
        'Sample_Type.Sample_Type', 'Plate.FK_Sample_Type__ID', 'Original_Concentration',    'Original_Concentration_Units', 'Source.FK_Original_Source__ID'
    );

    push @plate_fields, @source_fields;

    my $tables    = 'Plate, Source, Nucleic_Acid , Plate_Sample, Sample, Library, Sample_Type LEFT JOIN Tube ON Plate_ID = Tube.FK_Plate__ID';
    my $condition = " WHERE Sample.FK_Source__ID = Source_ID and Plate_ID IN ($plates) and Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID 
                    and FK_Sample__ID = Sample_ID and Plate.FK_library__Name = Library_Name and Plate.FK_Sample_Type__ID = Sample_Type_ID AND Source_ID = Nucleic_Acid.FK_Source__ID";
    my %plates = $dbc->Table_retrieve( $tables, \@plate_fields, "$condition" );

    my @fields = (
        'Source_Status',  'Received_Date',         'FKReceived_Employee__ID',     'FK_Rack__ID',                       'Current_Amount',  'Original_Amount',
        'Amount_Units',   'FKSource_Plate__ID',    'FK_Plate_Format__ID',         'FKParent_Source__ID',               'FK_Shipment__ID', 'FK_Sample_Type__ID',
        'Source_Created', 'Current_Concentration', 'Current_Concentration_Units', 'Current_Concentration_Measured_by', 'FK_Original_Source__ID',
    );
    push @fields, @source_fields;
    if ($sm_id) {
        push @fields, 'FK_Storage_Medium__ID';
    }

    my $index = 0;
    my %all_values;
    for my $id ( @{ $plates{Plate_ID} } ) {
        my $type   = $plates{Sample_Type}[$index];
        my @values = (
            'Active', &today(), $user_id,
            $plates{FK_Rack__ID}[$index],
            $plates{Current_Volume}[$index],
            $plates{Current_Volume}[$index],
            $plates{Current_Volume_Units}[$index],
            $plates{Plate_ID}[$index],
            $plates{FK_Plate_Format__ID}[$index],
            $plates{Source_ID}[$index],
            '', $plates{FK_Sample_Type__ID}[$index],
            &today(),
            $plates{Original_Concentration}[$index],
            $plates{Original_Concentration_Units}[$index],
            '', $plates{FK_Original_Source__ID}[$index],
        );
        for my $sub_field (@source_fields) {
            push @values, $plates{$sub_field}[$index],;
        }
        if ($sm_id) {
            push @values, $sm_id;
        }

        $index++;
        $all_values{$index} = \@values;
    }

    my $returnhash = $dbc->smart_append( -table => "Source,Nucleic_Acid", -fields => \@fields, -values => \%all_values, -autoquote => 1 );    #, -on_duplicate => $on_duplicate, -debug => $debug, -no_triggers => $no_triggers

    my @new_source_ids = @{ $returnhash->{Source}->{newids} } if $returnhash->{Source}->{newids};
    my $new_source_list = join ',', @new_source_ids;

    my %sources = $dbc->Table_retrieve( "Source", [ "Source_ID", "FKSource_Plate__ID" ], "WHERE Source_ID IN ($new_source_list)" ) if $new_source_list;
    $dbc->Benchmark('end_creation');

    my $index = 0;
    for my $id ( @{ $sources{Source_ID} } ) {
        ### This would be so much faster if the fucntion could handle multiple values
        SDB::DB_Object::inherit_attributes_between_objects( -dbc => $dbc, -source => 'Plate', -source_id => $sources{FKSource_Plate__ID}[$index], -target => 'Source', -target_id => $sources{Source_ID}[$index], -skip_message => 1 );
        $index++;
    }
    $dbc->Benchmark('end_inheritance');

    return $new_source_list;
}

###########################
sub create_Sources_from_Plates {
###########################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'dbc,plates' );
    my $dbc    = $args{-dbc};
    my $plates = $args{-plates};
    my $sm_id  = $args{-sm_id};
    my @records;

    my $tables      = 'Plate, Source, Plate_Sample, Sample, Library';
    my @info_fields = ( 'Plate_ID', 'Source_ID', 'Plate.FK_Plate_Format__ID', 'Current_Volume', 'Current_Volume_Units', 'Plate.FK_Rack__ID', 'Sample_Type.Sample_Type', 'Plate.FK_Sample_Type__ID' );
    my $user_id     = $dbc->get_local('user_id');
    my $fields      = [
        'Source_Status',       'Received_Date',       'FKReceived_Employee__ID', 'FK_Rack__ID',         'Current_Amount',        'Original_Amount',               'Amount_Units', 'FKSource_Plate__ID',
        'FK_Plate_Format__ID', 'FKParent_Source__ID', 'FK_Shipment__ID',         'FK_Sample_Type__ID',, 'FK_Storage_Medium__ID', 'Storage_Medium_Quantity_Units', 'Storage_Medium_Quantity'
    ];

    my $tables    = 'Plate, Source, Plate_Sample, Sample, Library, Sample_Type';
    my $condition = " WHERE FK_Source__ID = Source_ID and Plate_ID IN ($plates) and Plate_Sample.FKOriginal_Plate__ID = Plate.FKOriginal_Plate__ID 
                    and FK_Sample__ID = Sample_ID and Plate.FK_library__Name = Library_Name and Plate.FK_Sample_Type__ID = Sample_Type_ID";
    my %info = $dbc->Table_retrieve( $tables, \@info_fields, "$condition", -distinct => 1 );

    my @tables = $dbc->DB_tables();

    my $index = 0;

    $dbc->defer_messages();
    my $count = int( @{ $info{Plate_ID} } );
    my $Progress;
    if ( $count > 1 ) { $Progress = new SDB::Progress( "Transforming $Prefix{Source} records into $Prefix{Plate} records", -target => $count ) }

    for my $id ( @{ $info{Plate_ID} } ) {

        my $type   = $info{Sample_Type}[$index];
        my $values = [
            'Active', &today(), $user_id,
            $info{FK_Rack__ID}[$index],
            $info{Current_Volume}[$index],
            $info{Current_Volume}[$index],
            $info{Current_Volume_Units}[$index],
            $info{Plate_ID}[$index],
            $info{FK_Plate_Format__ID}[$index],
            $info{Source_ID}[$index],
            '', $info{FK_Sample_Type__ID}[$index],
            $sm_id, '', ''
        ];
        my $source_id = $info{Source_ID}[$index];

        ( my $new_src_id, my $copy_time ) = $dbc->Table_copy( -table => 'Source', -condition => "where Source_ID = $source_id", -exclude => $fields, -replace => $values );
        push @records, $new_src_id;

        my $sub_table = alDente::Source::get_main_Sample_Type( -find_table => 1, -dbc => $dbc, -sample_type => $type );

        if ( $sub_table && grep ( /^$sub_table$/, @tables ) ) {
            my $sub_fields = ['FK_Source__ID'];
            my $sub_values = [$new_src_id];
            ( my $result ) = $dbc->Table_copy( -table => $sub_table, -condition => "where FK_Source__ID = $source_id", -exclude => $sub_fields, -replace => $sub_values );
        }

        ## inherit attributes between Src and Pla ##
        SDB::DB_Object::inherit_attributes_between_objects( -dbc => $dbc, -source => 'Plate', -source_id => $id, -target => 'Source', -target_id => $new_src_id, -skip_message => 1 );
        $index++;
        if ( $count > 1 ) { $Progress->update($index) }
    }
    $dbc->flush_messages();

    return join ',', @records;
}

###########################
sub move_Plates_to_Box {
###########################

    my %args   = filter_input( \@_, -args => 'dbc,plates' );
    my $dbc    = $args{-dbc};
    my $plates = $args{-plates};

    my $quoted_plates = Cast_List( -list => $plates, -to => 'string', -autoquote => 1 );

    my %plate_tray_info = $dbc->Table_retrieve( -table => 'Plate_Tray', -fields => [ 'FK_Plate__ID', 'Plate_Position', 'FK_Tray__ID' ], -condition => "where FK_Plate__ID in ($quoted_plates)" );
    my %plate_pos;
    my $tray;
    my $index = 0;
    while ( defined $plate_tray_info{FK_Plate__ID}[$index] ) {
        if ( !defined $tray ) {
            $tray = $plate_tray_info{FK_Tray__ID}[$index];
        }
        elsif ( $plate_tray_info{FK_Tray__ID}[$index] != $tray ) {
            $dbc->warning("Plates can't be on multiple trays.");
            return 0;
        }
        $plate_pos{ $plate_tray_info{FK_Plate__ID}[$index] } = $plate_tray_info{Plate_Position}[$index];
        $index++;
    }

    if ( scalar( keys %plate_pos ) <= 0 ) {    # not on a tray, no need to move to slotted box
        return 1;
    }

    my %rack_output = $dbc->Table_retrieve( -table => 'Plate,Rack', -fields => [ 'Rack_ID', 'Rack_Type' ], -condition => "where FK_Rack__ID = Rack_ID and Plate_ID in ($quoted_plates)", -distinct => 1 );
    my $racks       = $rack_output{'Rack_ID'};
    my $types       = $rack_output{'Rack_Type'};

    my $unique_racks = unique_items($racks);
    my $unique_types = unique_items($types);

    if ( scalar(@$unique_racks) == 0 or scalar(@$unique_types) == 0 ) {
        $dbc->warning("No valid racks found for plates. Please move plates to single rack/shelf/unslotted box or slots of a box that match tray postions and try again.");
        return 0;
    }

    elsif ( scalar(@$unique_types) > 1 ) {
        $dbc->warning("Plates found on multiple rack types. Please move plates to single rack/shelf/unslotted box or slots of a box that match tray postions and try again.");
        return 0;
    }

    elsif ( scalar(@$unique_types) == 1 ) {
        my $rack_type = $unique_types->[0];
        ## rack or shelf
        if ( $rack_type =~ /rack|shelf/i ) {
            if ( int(@$unique_racks) > 1 ) {
                Message("WARNING: plates are on multiple $rack_type.");
            }

            my $rack = $unique_racks->[0];

            ## create slotted box
            my ( $box, $slots ) = create_slotted_box( -dbc => $dbc, -rack => $rack, -plate_positions => \%plate_pos );

            ## move items
            my @ids = Cast_List( -list => $plates, -to => 'array' );
            alDente::Rack::move_Items( -dbc => $dbc, -type => 'Plate', -ids => \@ids, -rack => $box, -slots => $slots, -confirmed => 1 );

            my $location_link = alDente::Tools::alDente_ref( 'Rack', $box, -dbc => $dbc );
            $dbc->warning("Source records assigned to slots in New Box $location_link");
            return 1;
        }
        elsif ( $rack_type =~ /box/i ) {
            if ( int(@$unique_racks) > 1 ) {
                $dbc->warning("WARNING: plates are on multiple $rack_type. Please move plates to single rack/shelf/unslotted box or slots of a box that match tray postions and try again.");
                return 0;
            }

            my $rack          = $unique_racks->[0];
            my @plate_ids     = Cast_List( -list => $plates, -to => 'array' );
            my $rack_contents = alDente::Rack::get_rack_contents( -dbc => $dbc, -rack_id => $rack );
            my @contents      = Cast_List( -list => $rack_contents->{"Rac$rack"}, -to => 'array' );
            foreach my $item (@contents) {
                if ( $item !~ /^Pla(\d+)/ ) {
                    $dbc->warning("Items other than the selected plates were found in the box. Please remove these extra items before retrying.");
                    return 0;
                }
                my $id = $1;
                if ( !grep /^$id$/, @plate_ids ) {
                    $dbc->warning("Items other than the selected plates were found in the box. Please remove these extra items before retrying.");
                    return 0;
                }
            }

            ## create slots
            my ( $box, $slots ) = create_slotted_box( -dbc => $dbc, -rack => $rack, -plate_positions => \%plate_pos );

            ## move items
            my @ids = Cast_List( -list => $plates, -to => 'array' );
            alDente::Rack::move_Items( -dbc => $dbc, -type => 'Plate', -ids => \@ids, -rack => $box, -slots => $slots, -confirmed => 1 );

            my $location_link = alDente::Tools::alDente_ref( 'Rack', $box, -dbc => $dbc );
            $dbc->warning("Source records assinged to new slots in $location_link");
            return 1;
        }
        elsif ( $rack_type =~ /slot/i ) {
            ## confirm all PLA records are in the same box AND that the slot location matches the Tray location
            my $match = check_slot_location( -dbc => $dbc, -plates => $plates, -plate_positions => \%plate_pos );
            if ($match) {
                my ($parent) = $dbc->Table_find( 'Rack', 'FKParent_Rack__ID', "where Rack_ID = $unique_racks->[0]" );
                my $location_link = alDente::Tools::alDente_ref( 'Rack', $parent, -dbc => $dbc );
                $dbc->warning("Source records remain in Slots of $location_link");
            }
            return $match;
        }

    }
}

###########################
sub create_slotted_box {
###########################
    my %args      = filter_input( \@_, -args => 'dbc,rack,plate_positions' );
    my $dbc       = $args{-dbc};
    my $rack      = $args{-rack};
    my $plate_pos = $args{-plate_positions};

    my %slots;
    my ( $max_row, $max_col );

    foreach my $plate ( keys %$plate_pos ) {
        my $pos = $plate_pos->{$plate};

        $pos = lc($pos);
        $pos =~ /^([A-Za-z])(\d+)/;
        my $row = $1;
        my $col = $2;

        if ( $row gt $max_row ) { $max_row = $row; }
        if ( $col > $max_col )  { $max_col = $col; }
        ## Change the format of A01 -> A1, for example
        $pos =~ s/([A-Za-z])0(\d)/$1$2/;

        $slots{$plate} = $pos;
    }

    ## Change the column from 01 -> 1, for example
    $max_col =~ s/^0//;
    my $max_slot = $max_row . $max_col;

    my $box = alDente::Rack::generate_slotted_box( -dbc => $dbc, -rack => $rack, -max => $max_slot );
    return ( $box, \%slots );
}

###########################
sub check_slot_location {
###########################
    my %args      = filter_input( \@_, -args => 'dbc,plates,plate_positions' );
    my $dbc       = $args{-dbc};
    my $plates    = $args{-plates};
    my $plate_pos = $args{-plate_positions};

    ## retrieve plate locations
    my $quoted_plates = Cast_List( -list => $plates, -to => 'string', -autoquote => 1 );
    my %plate_info = $dbc->Table_retrieve( -table => 'Plate,Rack', -fields => [ 'Plate_ID', 'Rack_Name', 'FKParent_Rack__ID' ], -condition => "where FK_Rack__ID = Rack_ID and Plate_ID in ($quoted_plates)" );
    my %plate_locations;
    my $parent;
    my $index = 0;
    while ( defined $plate_info{Plate_ID}[$index] ) {
        if ( !defined $parent ) {
            $parent = $plate_info{FKParent_Rack__ID}[$index];
        }
        elsif ( $plate_info{FKParent_Rack__ID}[$index] != $parent ) {    ## not in the same box
            $dbc->warning("WARNING: Plates are in slots of multiple boxes. Please move plates to single rack/shelf/unslotted box or slots of a box that match tray postions and try again.");
            return 0;
        }

        $plate_locations{ $plate_info{Plate_ID}[$index] } = $plate_info{Rack_Name}[$index];
        $index++;
    }

    foreach my $plate ( keys %$plate_pos ) {
        my $pos = $plate_pos->{$plate};
        $pos = lc($pos);
        $pos =~ s/([A-Za-z])0(\d)/$1$2/;
        my $location = $plate_locations{$plate};
        if ( $pos !~ /^$location$/i ) {
            $dbc->warning("WARNING: slot location do not match tray location. Please move plates to single rack/shelf/unslotted box or slots of a box that match tray postions and try again.");
            return 0;
        }
    }

    return 1;
}

1;
