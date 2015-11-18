######################
#
# Package to handle Lane related functionalities
#
######################
package alDente::Lane;
######################

#Packages from Perl
use strict;
use Data::Dumper;

#Packages from SDB
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::HTML;

#Packages from RGTools
use RGTools::RGIO;
use RGTools::Conversion;

#Packages from alDente
use alDente::Grp;
use alDente::Validation;

use vars qw($testing $Connection );

#########
sub new {
#########
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = @_;
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my $self = SDB::DB_Object::new( $this, -dbc => $dbc, -tables => 'Lane' );

    bless $self, $class;

    $self->{dbc} = $dbc;

    return $self;
}

#####################
#
#
################
sub fail_lanes {
################
    my %args = &filter_input( \@_, -args => 'dbc,run_id,lanes,reason', -mandatory => 'dbc,run_id,lanes,reason' );

    my $dbc      = $args{-dbc};
    my $run_id   = $args{-run_id};
    my $lanes    = Cast_List( -list => $args{-lanes}, -to => 'string' );
    my $reason   = $args{-reason};
    my $comments = $args{-comments};
    my $quiet    = $args{-quiet};

    my $lane_ids = join ',', $dbc->Table_find( 'GelRun,Lane', 'Lane_ID', "WHERE FK_Run__ID=$run_id AND GelRun_ID=FK_GelRun__ID AND Lane_Number IN ($lanes)" );

    my $fails_ref = alDente::Fail::Fail( -dbc => $dbc, -ids => $lane_ids, -object => 'Lane', -reason => $reason, -comments => $comments, -quiet => $quiet );
    return $fails_ref;
}

#####################
#
#
################
sub unfail_lanes {
################
    my %args = &filter_input( \@_, -args => 'dbc,run_id,lanes', -mandatory => 'dbc,run_id,lanes' );

    my $dbc    = $args{-dbc};
    my $run_id = $args{-run_id};
    my $lanes  = Cast_List( -list => $args{-lanes}, -to => 'string' );
    my $quiet  = $args{-quiet};

    my $ok;

    my $failreasons = join ',', $dbc->Table_find( 'FailReason,Object_Class', 'FailReason_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class='Lane'" );
    my $lane_ids    = join ',', $dbc->Table_find( 'Run,GelRun,Lane',         'Lane_ID',       "WHERE Run_ID=FK_Run__ID AND GelRun_ID=FK_GelRun__ID AND Run_ID=$run_id AND Lane_Number IN ($lanes)" );

    if ( !$failreasons or !$lane_ids ) { Message("Error: No lanes or Failtypes exist in the database"); return 0; }
    my $fail_ids = join ',', $dbc->Table_find( 'Fail', 'Fail_ID', "WHERE Fk_FailReason__ID IN ($failreasons) AND Object_ID IN ($lane_ids)" );
    if ( !$fail_ids ) { Message("Error: No Fail entries for the given Runs and Lanes"); return 0; }
    $ok = $dbc->delete_records( 'Fail', 'Fail_ID', -id_list => $fail_ids );
    Message("Deleted $ok Fail entries") unless ($quiet);
    $ok = $dbc->Table_update_array( 'Lane', ['Lane_Status'], ['Passed'], "WHERE Lane_ID IN ($lane_ids)", -autoquote => 1 );
    Message("Set $ok Lane entries from Failed to Passed") unless ($quiet);
    return 1;

}

#####################
#
#
###################
sub create_lanes {
###################
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $run_ids = Cast_List( -list => $args{-run_ids}, -to => 'string' );
    my $force   = $args{-force};
    my $quiet   = $args{-quiet};

    my $lane_ids = join ',', $dbc->Table_find( 'Lane,GelRun', 'Lane_ID', "WHERE FK_GelRun__ID=GelRun_ID AND FK_Run__ID IN ($run_ids)" );
    if ($lane_ids) {
        if ($force) {
            my $ok = $dbc->delete_records( 'Lane', 'Lane_ID', -id_list => $lane_ids );
            if ($ok) { Message("Deleted $ok Lane entries") unless $quiet }
        }
        else {
            my $existing_lanes = join ',', $dbc->Table_find( 'Lane,GelRun', 'FK_Run__ID', "WHERE FK_GelRun__ID=GelRun_ID AND FK_Run__ID IN ($run_ids)", -distinct => 1 );
            Message("Error: Lane entries already existing for the following Run(s): $existing_lanes.") unless $quiet;
            return 0;
        }
    }

    my @lane_fields = qw(FK_GelRun__ID FK_Sample__ID Lane_Number Lane_Status Well Lane_Growth);

    my $mapping = &_get_lane_well_mapping( -dbc => $dbc, -run_ids => $run_ids, -quiet => $quiet, -fields => \@lane_fields );

    my $count = 0;
    my %lane_entries;
    foreach ( @{$mapping} ) {
        $lane_entries{ ++$count } = $_;
    }

    ### Start the analysis by creating a GelAnalysis entry for each Gel and Lane entries for each Gel
    my $laneids = $dbc->smart_append( -tables => 'Lane', -fields => \@lane_fields, -values => \%lane_entries, -autoquote => 1 );
    if ( $laneids->{Lane}{newids} && !$quiet ) {
        Message( "Created " . int( @{ $laneids->{Lane}->{newids} } ) . " Lane entries" );
    }
    return $laneids->{'Lane'}->{'newids'};

}

############################
#
#  Returns an array of hashes for the mapping of plate wells and gel lanes
#
#
############################
sub _get_lane_well_mapping {
############################
    my %args = &filter_input( \@_, -args => 'dbc,run_ids' );

    my $dbc     = $args{-dbc};
    my $run_ids = $args{-run_ids};
    my $quiet   = $args{-quiet};
    my @fields  = Cast_List( -list => $args{-fields}, -to => 'array' );

    ### Retrieve some info about these Runs
    my %runs = $dbc->Table_retrieve(
        'RunBatch,Run,GelRun,Plate,Library_Plate,Plate_Format',
        [ 'Run_ID', 'GelRun_ID', 'Plate.Plate_ID AS Pla_ID', 'Run_Directory', 'GelRun_Type', 'No_Grows', 'Slow_Grows', 'Unused_Wells', 'Problematic_Wells', 'Empty_Wells', 'Well_Lookup_Key' ],
        "WHERE RunBatch_ID=FK_RunBatch__ID AND Run_ID=FK_Run__ID AND Plate.Plate_ID=Library_Plate.FK_Plate__ID AND Plate.Plate_ID=Run.FK_Plate__ID AND Plate.FK_Plate_Format__ID=Plate_Format_ID AND Run_ID IN ($run_ids)"
    );
    my $index = -1;

    unless (%runs) { Message("Error: Missing run information") unless ($quiet); return 0; }

    my %Plate_Info;
    while ( defined $runs{Run_ID}[ ++$index ] ) {
        $Plate_Info{ $runs{Pla_ID}[$index] }{Run_ID}            = $runs{Run_ID}[$index];
        $Plate_Info{ $runs{Pla_ID}[$index] }{GelRun_ID}         = $runs{GelRun_ID}[$index];
        $Plate_Info{ $runs{Pla_ID}[$index] }{GelRun_Type}       = $runs{GelRun_Type}[$index];
        $Plate_Info{ $runs{Pla_ID}[$index] }{No_Grows}          = [ split ',', &format_well( $runs{No_Grows}[$index] ) ];
        $Plate_Info{ $runs{Pla_ID}[$index] }{Slow_Grows}        = [ split ',', &format_well( $runs{Slow_Grows}[$index] ) ];
        $Plate_Info{ $runs{Pla_ID}[$index] }{Unused_Wells}      = [ split ',', &format_well( $runs{Unused_Wells}[$index] ) ];
        $Plate_Info{ $runs{Pla_ID}[$index] }{Problematic_Wells} = [ split ',', &format_well( $runs{Problematic_Wells}[$index] ) ];
        $Plate_Info{ $runs{Pla_ID}[$index] }{Empty_Wells}       = [ split ',', &format_well( $runs{Empty_Wells}[$index] ) ];
        $Plate_Info{ $runs{Pla_ID}[$index] }{Well_Lookup_Key}   = $runs{Well_Lookup_Key}[$index];
        $Plate_Info{ $runs{Pla_ID}[$index] }{Lane_Counter}      = 0;                                                                 ### For sequential lane numbering scheme
    }

    my $plate_ids = join ',', sort { $a <=> $b } keys %Plate_Info;
    ### Retrieve info for each sample on these Gels
    my @sample_fields = ( 'Plate.Plate_ID', 'FK_Sample__ID', 'Plate_96 AS Well', 'Gel_121_Standard', 'Gel_121_Custom' );

    #### Gels that are aliquots of 384-well plates
    my %samples = $dbc->Table_retrieve(
        'Plate,Plate AS OrigPlate,Plate_Sample,Well_Lookup,Plate_Format',
        \@sample_fields,
        "WHERE Plate.Plate_ID IN ($plate_ids) AND Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND OrigPlate.FK_Plate_Format__ID=Plate_Format_ID AND Wells=384 AND OrigPlate.Plate_ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.Well="
            . SQL_well('Plate_384')
            . " AND Plate.Parent_Quadrant=Well_Lookup.Quadrant ORDER BY Plate.Plate_ID,Plate_96"
    );

    #### Gels that are initially 96-well plates
    my %samples_96 = $dbc->Table_retrieve(
        'Plate,Plate AS OrigPlate,Plate_Sample,Well_Lookup,Plate_Format',
        \@sample_fields,
        "WHERE Plate.Plate_ID IN ($plate_ids) AND Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND OrigPlate.FK_Plate_Format__ID=Plate_Format_ID AND Wells=96 AND OrigPlate.Plate_ID=Plate.FKOriginal_Plate__ID AND Plate_Sample.Well=Well_Lookup.Plate_96 AND Quadrant='A' ORDER BY Plate.Plate_ID,Plate_96"
    );

    if (%samples_96) {
        if (%samples) {
            map { push( @{ $samples{$_} }, @{ $samples_96{$_} } ) } keys %samples;
        }
        else {
            %samples = %samples_96;
        }
    }

    my @lane_entries;

    ### Create the Lane entries
    $index = -1;
    while ( defined $samples{FK_Sample__ID}[ ++$index ] ) {
        my $this_plate      = $samples{Plate_ID}[$index];
        my $run_id          = $Plate_Info{$this_plate}{Run_ID};
        my $gelrun_id       = $Plate_Info{$this_plate}{GelRun_ID};
        my $nogrow_ref      = $Plate_Info{$this_plate}{No_Grows};
        my $slowgrow_ref    = $Plate_Info{$this_plate}{Slow_Grows};
        my $unused_ref      = $Plate_Info{$this_plate}{Unused_Wells};
        my $problematic_ref = $Plate_Info{$this_plate}{Problematic_Wells};
        my $empty_ref       = $Plate_Info{$this_plate}{Empty_Wells};
        my $format_style    = $Plate_Info{$this_plate}{Well_Lookup_Key};
        my $sample_id       = $samples{FK_Sample__ID}[$index];
        my $well            = $samples{Well}[$index];
        my $lane_numb;

        if ( $Plate_Info{ $samples{Plate_ID}[$index] }{GelRun_Type} eq 'Sizing Gel' ) {
            $lane_numb = $samples{$format_style}[$index];
        }
        else {
            ### Sequential Lanes numbering scheme
            $lane_numb = ++$Plate_Info{ $samples{Plate_ID}[$index] }{Lane_Counter};
        }

        my $lane_growth = 'OK';

        if ( grep( /^$well$/, @{$nogrow_ref} ) ) {
            $lane_growth = 'No Grow';
        }
        elsif ( grep( /^$well$/, @{$slowgrow_ref} ) ) {
            $lane_growth = 'Slow Grow';
        }
        elsif ( grep( /^$well$/, @{$unused_ref} ) ) {
            $lane_growth = 'Unused';
        }
        elsif ( grep( /^$well$/, @{$problematic_ref} ) ) {
            $lane_growth = 'Problematic';
        }
        elsif ( grep( /^$well$/, @{$empty_ref} ) ) {
            $lane_growth = 'Empty';
        }

        ### Default to Pass (?)
        my @entry;
        foreach my $field (@fields) {
            if    ( $field eq 'FK_GelRun__ID' ) { push @entry, $gelrun_id }
            elsif ( $field eq 'FK_Sample__ID' ) { push @entry, $sample_id }
            elsif ( $field eq 'Lane_Number' )   { push @entry, $lane_numb }
            elsif ( $field eq 'Lane_Status' )   { push @entry, 'Passed' }
            elsif ( $field eq 'Well' )          { push @entry, $well }
            elsif ( $field eq 'Lane_Growth' )   { push @entry, $lane_growth }
            elsif ( $field eq 'Run_ID' )        { push @entry, $run_id }
        }

        push( @lane_entries, \@entry );
    }

    return \@lane_entries;

}

return 1;

