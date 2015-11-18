package Sequencing::Phred;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Phred.pm - 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(generate_read generate_distribution generate_culmulative);

##############################
# standard_modules_ref       #
##############################

use POSIX qw(tmpnam);
use strict;
##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Object;
use SDB::Histogram;

##############################
# global_vars                #
##############################
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

#Constructor
#arguments
#-files is a reference to an array of filehandles to graph
#-seqids is a reference to an array of Run IDs to graph
sub new {

    my $this = shift;
    my %args = @_;

    my $self = {};

    my $files  = $args{-files};
    my $seqids = $args{-seqids};

    my $class = ref($this) || $this;

    #populate the wells

    #array of arrays to store well quality data
    my @set_of_wells = ();
    my @well_map     = ();

    #fail if there are no sources specified
    unless ( $files || $seqids ) {
        die "No data source specified";
    }

    #populate from files
    foreach my $filename (@$files) {
        my %wells = {};
        _populate_well_from_file( \%wells, $filename );
        push( @set_of_wells, \%wells );
    }

    #populate from database
    my $dbc = &SDB::DBIO->new( -host => 'seqdb01', -dbase => 'sequence', -user => 'viewer', -password => 'viewer', -connect => 1 );
    foreach my $seqid (@$seqids) {
        my %wells = {};
        _populate_well_from_database( \%wells, $dbc, $seqid );
        push( @set_of_wells, \%wells );
    }

    #build histogram data

    #array of hashes for distribution
    my @q_value_count_array  = ();
    my @q20_well_count_array = ();
    my $max_dist_y           = 0;
    my $max_culm_y           = 0;
    my $max_dist_x           = 0;
    my $max_culm_x           = 0;
    foreach my $well_group (@set_of_wells) {

        my %q_value_counts;

        #hash for Q20 counts per well
        my %q20_well_counts;

        #build distribution of q-value counts
        foreach my $well_key ( keys %$well_group ) {
            my $quality_count;
            my $well = $well_group->{$well_key};
            while ( $well =~ /\d+\s+(\d+)/g ) {
                $q_value_counts{$1}++;
                if ( $q_value_counts{$1} > $max_dist_y ) {
                    $max_dist_y = $q_value_counts{$1};
                }
                if ( $1 > $max_dist_x ) {
                    $max_dist_x = $1;
                }
                if ( $1 >= 20 ) {
                    $quality_count++;
                }
            }
            $q20_well_counts{$quality_count}++;
            if ( $q20_well_counts{$quality_count} > $max_culm_y ) {
                $max_culm_y = $q20_well_counts{$quality_count};
            }
            if ( $quality_count > $max_culm_x ) {
                $max_culm_x = $quality_count;
            }
            $quality_count = 0;
        }
        push( @q_value_count_array,  \%q_value_counts );
        push( @q20_well_count_array, \%q20_well_counts );
    }

    $self->{"distributions"} = \@q_value_count_array;
    $self->{"max_dist_y"}    = $max_dist_y;
    $self->{"max_culm_y"}    = $max_culm_y;
    $self->{"max_dist_x"}    = $max_dist_x;
    $self->{"max_culm_x"}    = $max_culm_x;
    $self->{"culmulatives"}  = \@q20_well_count_array;
    $self->{"wells"}         = \@set_of_wells;
    $self->{"well_mapping"}  = \@well_map;

    bless $self, $class;
    return $self;
}

##############################
# public_methods             #
##############################

#method to create an image file of a line plot for multiple reads/wells
#arguments ($well_id, $filename)
sub generate_read {
    my $self      = shift;
    my $wells_ref = $self->{"wells"};

    my ( $well_id, $filename, undef ) = @_;

    #create temporary file to use on gnuplot
    #for data
    my @file_array = ();
    my $max_index  = 0;
    foreach my $data_set (@$wells_ref) {
        my $temp_file = tmpnam();
        my $data      = $data_set->{$well_id};
        open( INF, ">$temp_file" );
        print INF $data;
        close INF;
        if ( $data =~ /(\d*)\s(\d*)$/ ) {
            if ( $max_index < $1 ) {
                $max_index = $1;
            }
        }
        push( @file_array, $temp_file );
    }

    #for commands
    my $command_file = tmpnam();
    open( INF, ">$command_file" );
    my $gnuplot_command = "";
    $gnuplot_command .= "set xlabel \"Base Index\"\n";
    $gnuplot_command .= "set ylabel \"Quality of Read\"\n";
    $gnuplot_command .= "set terminal png small color\n";
    $gnuplot_command .= "set output '$filename'\n";
    $gnuplot_command .= "set multiplot\n";
    $gnuplot_command .= "set yrange [0:100]\n";
    $gnuplot_command .= "set xrange [0:$max_index]\n";

    my $count = 1;
    foreach my $temp_file (@file_array) {
        $gnuplot_command .= "set size 1,1\n";
        $gnuplot_command .= "set origin 0,0\n";
        $gnuplot_command .= "plot '$temp_file' smooth bezier notitle with lines $count\n";
        $count++;
    }

    $gnuplot_command .= "set nomultiplot\n";

    print INF $gnuplot_command;
    close INF;

    #call gnuplot
    #`/home/jsantos/gnuplot/bin/gnuplot $command_file`;
    `gnuplot $command_file`;
    foreach my $temp_file (@file_array) {
        unlink($temp_file);
    }
    unlink($command_file);
}

#method to create an image file of a counts vs q-value histogram
#argument ($filenames)
#$filenames is a reference to a list of filenames
sub generate_distribution {
    my $self = shift;
    my ( $filenames, undef ) = @_;
    my $dist_ref = $self->{"distributions"};
    my $max_y    = $self->{"max_dist_y"};
    my $max_x    = $self->{"max_dist_x"};

    $self->generate_histogram( $filenames, $dist_ref, "Q-value", "Counts", "100", $max_y );
}

sub generate_culmulative {
    my $self = shift;
    my ( $filenames, undef ) = @_;
    my $culmulative_ref = $self->{"culmulatives"};
    my $max_y           = $self->{"max_culm_y"};
    my $max_x           = $self->{"max_culm_x"};

    $self->generate_histogram( $filenames, $culmulative_ref, "Number of Q20s", "Reads", $max_x, $max_y );
}

#method to create an image file of a counts vs q-value histogram
#argument ($filename,$hash_ref)
#where filename is for output
#and hashref is a reference to the histogram to be created
sub generate_histogram {
    my $self = shift;
    my ( $filenames, $hash_ref, $xlabel, $ylabel, $max_x, $max_y, undef ) = @_;
    my $dist_ref          = $hash_ref;
    my $number_of_sources = @$dist_ref . "";

    #for data
    my @file_array  = ();
    my @set_of_bins = ();

    $max_y = 0;
    my $max_num_bins = 0;

    #bin-ify to 200 bins
    foreach my $data_set (@$dist_ref) {
        my @storage_bin = ();
        my %bins;
        foreach my $i ( 1 .. 100 ) {
            $bins{$i} = 0;
        }
        foreach my $entry ( keys %$data_set ) {
            my $bin_entry = int( ( $entry / $max_x ) * 100 );
            $bins{$bin_entry} = $data_set->{$entry};
        }

        foreach my $entry ( sort { $a <=> $b } keys %bins ) {
            push( @storage_bin, $bins{$entry} );
        }

        if ( $max_num_bins < @storage_bin . "" ) {
            $max_num_bins = @storage_bin . "";
        }

        #close INF;
        push( @set_of_bins, \@storage_bin );
    }

    #create the axis ticks
    my $increment = int( $max_x / 4 );
    my @axis_tick_labels = ( 0, $increment, $increment * 2, $increment * 3 );
    foreach my $i ( 0 .. 3 ) {
        $axis_tick_labels[$i] = int( $axis_tick_labels[$i] / 10 ) * 10;
    }
    my @axis_ticks = ( 0, 25, 50, 75 );

    my @entries = ();
    my $count   = 0;
    while ( $count < 20 ) {
        foreach my $bin (@set_of_bins) {
            push( @entries, $bin->[$count] );
        }
        $count++;
    }

    my $file_count = 0;
    foreach my $bin (@set_of_bins) {
        my $histogram = SDB::Histogram->new( -path => ' ' );
        $histogram->Group_Colours( $max_num_bins / 10 );
        $histogram->Set_X_Axis( $xlabel, \@axis_ticks, \@axis_tick_labels );

        $histogram->Set_Y_Axis($ylabel);

        #pad the entries if necessary
        if ( @$bin . "" < $max_num_bins ) {
            foreach ( 1 .. $max_num_bins - @$bin ) {
                push( @$bin, 0 );
            }
        }
        $histogram->Set_Bins( $bin, 1 );
        $histogram->DrawIt( $filenames->[$file_count], height => 140 );
        $file_count++;
    }

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

#parse phred data
#return an array of wells
#arguments: ($lines, $wells)
#@$lines is an array of newline-terminated lines from a phred file
#%$wells is a hash associating a well id to a set of sequence scores
sub _parse_phred {
    my ( $lines, $wells ) = @_;
    my $temp_line  = "";
    my $count      = 1;
    my $hash_index = "";
    foreach my $line (@$lines) {
        if ( $line =~ /^>.*?_([a-zA-Z0-9]*)_.*/ ) {
            $wells->{$hash_index} = $temp_line;
            $temp_line            = "";
            $count                = 1;
            $hash_index           = $1;
        }
        else {
            while ( $line =~ /(\d+)/g ) {
                $temp_line = $temp_line . "$count $1\n";
                $count++;
            }
        }
    }
    $wells->{$hash_index} = $temp_line;
}

#function to parse the sequence scores from the database to a hash
#arguments ($well_hash_ref,$database_handle,$seqid)
#$wells is a reference to a hash that associates a well id with a set of sequence scores
sub _populate_well_from_database {
    my ( $wells, $dbc, $seqid, undef ) = @_;
    my %sequences    = Table_retrieve( $dbc, "Clone_Sequence", [ 'Well', 'Sequence_Scores' ], "where FK_Run__ID=$seqid" );
    my $seq_wells    = $sequences{"Well"};
    my $well_counter = 0;

    #populate the wells
    foreach my $well (@$seq_wells) {
        my $seq_score = $sequences{"Sequence_Scores"}[$well_counter];
        my @scores    = unpack "c*", $seq_score;
        my $counter   = 1;
        foreach my $score (@scores) {
            $wells->{$well} .= $counter . " " . $score . "\n";
            $counter++;
        }
        $counter = 0;
        $well_counter++;
    }
}

#function to call the phred-parsing function on a phred quality file
#this just takes a file and parses each line into an element of an array
#arguments ($well_hash_ref,$filehandle)
#$wells is a reference to a hash that associates a well id with a set of sequence scores
#$filehandle is the filehandle of a phred quality file
sub _populate_well_from_file {
    my ( $wells, $file, undef ) = @_;
    my @lines = <$file>;
    _parse_phred( \@lines, $wells );
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

$Id: Phred.pm,v 1.9 2004/09/08 23:31:49 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
