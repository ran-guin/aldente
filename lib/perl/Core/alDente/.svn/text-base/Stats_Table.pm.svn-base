package alDente::Stats_Table;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Stats_Table.pm - 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>+

=head1 DESCRIPTION <UPLINK>

=for html

=cut

use RGTools::HTML_Table;
##############################
# superclasses               #
##############################
use base HTML_Table;

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

use RGTools::Graph;
use RGTools::RGIO;
use RGTools::Conversion;

use SDB::HTML;
use SDB::CustomSettings;

use Data::Dumper;

use strict;

##############################
# custom_modules_ref         #
##############################
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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

##################
sub add_Stats {
##################
    #
    # <snip> eg.
    #    my $Table = new Stats_Table();
    #    for my $row (1..$n) {
    #         $Table -> Set_Row(\@row);
    #    }
    #    $Table->add_Stats({1=>'Count', 2=>'Sum,Avg,StdDev', 3=>hist});
    #
    #
    # Return: number of statistical numbers to generate
#####################
    my $self  = shift;
    my $Stats = shift;    ## hash indicating stats to perform (eg $Table->Column_Stats({1=>'Avg,Sum', 'count'=>'Sum'});
    my $class = shift;

    my $set = 0;
    foreach my $key ( keys %$Stats ) {
        my $stats = $Stats->{$key};
        my $column;
        if ( $key =~ /^\d+$/ ) {
            $column = $key;    ## column index
            push @{ $self->{column_stats} }, $column;
        }
        if ( !$column ) {next}    ## column not found

        if ( $stats =~ /\bSum|Total\b/i ) {
            push @{ $self->{sum_columns} }, $column;
            $set++;
        }
        if ( $stats =~ /\bAvg\b/i ) {
            push @{ $self->{avg_columns} }, $column;
            $set++;
        }
        if ( $stats =~ /\bCount|N\b/i ) {
            push @{ $self->{count_columns} }, $column;
            $set++;
        }
        if ( $stats =~ /\bMedian\b/i ) {
            push @{ $self->{median_columns} }, $column;
            $set++;
        }
        if ( $stats =~ /\bMin\b/i ) {
            push @{ $self->{min_columns} }, $column;
            $set++;
        }
        if ( $stats =~ /\bMax\b/i ) {
            push @{ $self->{max_columns} }, $column;
            $set++;
        }
        if ( $stats =~ /\bStdDev\b/i ) {
            push @{ $self->{StdDev_columns} }, $column;
            $set++;
        }
        if ( $stats =~ /\bHist|Dist/i ) {
            ## Histogram of Distribution ##
            push @{ $self->{hist_columns} }, $column;
            $set++;
        }

    }

    if ($class) { $self->{stats_class} = $class }

    $self->_add_Column_Stats();

    return $set;
}

###########################
sub _add_Column_Stats {
###########################
    my $self  = shift;
    my $class = $self->{stats_class};

    my $message;
    if ( !defined $self->{column_stats} ) { $message .= "Stats to display not defined"; return; }

    my %total;
    my %count;
    my %avg;

    my %Values;

    if ( !$self->{rows} ) {return}

    foreach my $column ( @{ $self->{column_stats} } ) {
        my $index = $column - 1;

        if ( !defined $self->{"C$index"} ) { $message .= "No Column $index data"; next; }

        my @values = @{ $self->{"C$index"} };
        $total{$column} = 0;
        $count{$column} = 0;
        foreach my $value (@values) {
            if ( $value =~ /^[0-9\.]+$/ ) {
                ## for now just allow integers and simple decimal (may adjust for e+06 or suffix like 'M or k')
                ## also adjust to generate statistics from Statistics module rather than totaling by hand...
                $total{$column} += $value;
                $count{$column}++;
                push @{ $Values{$column} }, $value;
            }
        }
        my $avg = 'undef';
        if ( $count{$column} ) {
            $avg{$column} = $total{$column} / $count{$column};
        }

        require RGTools::Graph;
    }

    my @row;
    foreach my $column ( 1 .. $self->{columns} ) {
        my $value = '';
        if ( grep /^$column$/, @{ $self->{column_stats} } ) {
            if ( grep /^$column$/, @{ $self->{sum_columns} } ) {
                $value = "&Sigma=$total{$column}<BR>" || 'undef';
            }
            if ( grep /^$column$/, @{ $self->{avg_columns} } ) {
                $value .= sprintf "[Avg=%0.2f]<BR>", $avg{$column};
            }
            if ( grep /^$column$/, @{ $self->{count_columns} } ) {
                $value .= "[N=$count{$column}]<BR>" || 'undef';
            }
            if ( grep /^$column$/, @{ $self->{hist_columns} } ) {
                $value .= $self->get_stats( $column, $Values{$column}, 'hist' ) || 'undef';
            }
            if ( grep /^$column$/, @{ $self->{median_columns} } ) {
                $value .= $self->get_stats( $column, $Values{$column}, 'median' ) || 'undef';
            }
            if ( grep /^$column$/, @{ $self->{min_columns} } ) {
                $value .= $self->get_stats( $column, $Values{$column}, 'min' ) || 'undef';
            }
            if ( grep /^$column$/, @{ $self->{max_columns} } ) {
                $value .= $self->get_stats( $column, $Values{$column}, 'max' ) || 'undef';
            }
            if ( grep /^$column$/, @{ $self->{StdDev_columns} } ) {
                $value .= $self->get_stats( $column, $Values{$column}, 'stddev' ) || 'undef';
            }
        }
        push @row, $value;
    }
    $self->Set_Row( \@row, $class );
    return $message;
}

##################
sub get_stats {
##################
    my $self   = shift;
    my $column = shift;
    my $values = shift;
    my $type   = shift;

    my $stat;
    if ( $self->{stats_data}{$column} ) { $stat = $self->{stats_data}{$column} }
    else {
        $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@$values);

        $self->{stats_data}{$column} = $stat;
    }

    if    ( $type eq 'median' ) { return '[Median = ' . $stat->median() . ']<BR>' }
    elsif ( $type eq 'min' )    { return '[Min = ' . $stat->min() . ']<BR>' }
    elsif ( $type eq 'max' )    { return '[Max = ' . $stat->max() . ']<BR>' }
    elsif ( $type eq 'stddev' ) { return sprintf '[+/- %3.1f]<BR>', $stat->standard_deviation() }
    elsif ( $type eq 'hist' ) {
        my $name = "Hist.C$column." . timestamp;
        return $self->distribution_graph( $stat, $name );
    }
    else { return "$type undef<BR>" }
}

#############################
sub distribution_graph {
#############################
    my $self     = shift;
    my $stat     = shift;
    my $filename = shift;

    if ( !$stat || !defined $stat->count() ) { return 'undef' }

    my %Distribution = $stat->frequency_distribution( $stat->max() - $stat->min() + 1 );

    ### set all values to stat->max (distribution does not work in this case)
    if ( $stat->max() == $stat->min() ) {
        $Distribution{ int( $stat->max() ) } = $stat->count();
    }

    my @Dist = @{ pad_Distribution( \%Distribution, -binsize => 1 ) };

    my $image_path = $Configs{URL_temp_dir};

    my $min = int( $stat->min() ) - 1;
    my $max = int( $stat->max() ) + 1;

    &Graph::generate_graph( -title => 'Distribution', -x_data => [ $min .. $max ], -y_data => [ @Dist[ $min .. $max ] ], -x_label_skip => 5, -bar_width => 2, -ysize => 100, -xsize => 50, -output_file => "$image_path/$filename" );
    my $hist = "<Img Src='/dynamic/tmp/$filename.gif'><BR>" || 'undef';

    return $hist;
}

1;
