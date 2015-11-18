package Graph;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Graph.pm - 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    generate_graph
);

##############################
# standard_modules_ref       #
##############################

use GD::Graph::points;
use GD::Graph::bars;
use Data::Dumper;
use Getopt::Long;
use strict;

use RGTools::RGIO;

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

####
# Simple method to generate graph
#
# <snip>
#  Examples of usage:
#
# ### Graphing from an array ####
#.
#     use RGTools::Graph;
#     my $file = 'test';
#
#     Graph::generate_graph(-x_data=>\@x_array, -y_data=>\@y_array, -output_file=>"$dbc->config('tmp_web_dir')/$file", -title=>'Plot this');
#     print "<IMG SRC='/dynamic/$file.gif'/>";
#
#     Graph::generate_graph(-y_data=>\@y_data, -output_file=>""$dbc->config('tmp_web_dir')/$file", -bar_width=>10, -ymax=>100);              ## x_array defaults to simple index values 1..N
#     print "<IMG SRC='/dynamic/tmp/$file.gif'/>";
#
# ### Graphing directly from a file ###
#
#     Graph::generate_graph(-file => $input_data_file, -ycol=>3, -xcol=>0, -output_file => "$dbc->config('tmp_web_dir')/$file", -title=>'Plot');            ## plot column 4 (index=3) with first column as x-axis ##
#     print "<IMG SRC='/dynamic/tmp/$file.gif'/>";
#
#
# </snip>
#
#     print "<IMG SRC='/dynamic/tmp/$file.$file'>";
#
# Return: 1 on success (0 on error) (undef if only zero data)
########################
sub generate_graph {
########################
    my %args          = filter_input( \@_ );
    my $x_data        = $args{-x_data};
    my $y_data        = $args{-y_data};
    my $array         = $args{-array};                           ## array of columns alternative input (eg ([A,B], [1,4],[2,3],[3,2])
    my $hash          = $args{-hash};                            ## alternative input (eg {'A' => [1,2,3], 'B' => [4,3,2])
    my $x_column_name = $args{-x_column_name};
    my $y_column_name = $args{-y_column_name};
    my $tail_lines    = $args{-tail_lines};                      ## Number of lines to use at the end of the file (skip totals at bottom)
    my $ymax          = $args{-ymax} || 0;
    my $ymin          = $args{-ymin} || 0;
    my $output_file   = $args{-output_file} || "test.gif";
    my $image_xsize   = $args{-xsize} || 500;
    my $image_ysize   = $args{-ysize} || 300;
    my $x_label       = $args{-x_label};
    my $y_label       = $args{-y_label};
    my $bar_width     = $args{-bar_width} || 1;                  ## width of bars in bar graph
    my $marker_size   = $args{-marker_size} || 1;
    my $colour        = $args{-colour} || 'red';                 ## colour of points / bars in graph
    my $x_label_skip  = $args{-x_label_skip} || 0;               ## skip labels between nominal x labels (if densely packed)
    my $title         = $args{-title};
    my $debug         = $args{-debug};
    my $nominalx      = $args{-nominal_x} || $bar_width || 1;    ## bar graph, with x values as labels
    ## input file options ##
    my $file      = $args{-file};                                ## name of file containing data to be graphed (requires ycol
    my $delimiter = $args{-delimiter} || '\s+';
    my $x_column  = $args{-xcol};
    my $y_column  = $args{-ycol};

    my @colours;
    if ( $colour =~ /,/ ) { @colours = split ',', $colour }
    else                  { @colours = ($colour) }

    $title = "$x_label x $y_label" unless ( $title || !( $x_label && $y_label ) );
    if ($debug) {
        print "RGTools::Graph::generate_graph<BR>";
        print '<PRE>';
        print Dumper \%args;
        print "<PRE>";
    }
    if ( $output_file !~ /\.gif$/ ) {
        $output_file .= ".gif";
    }
    if ( $tail_lines && !( "$file" || ( -e "$file" ) ) ) {
        Call_Stack();
        print "Warning: requested only limited lines of input file, but no input file exists.\n";
        if ( !$file && !( $x_data && $y_data ) ) {
            return 0;
        }
        elsif ( -e "$file" ) {
            print "Using entire file";
        }
    }

    my $count = 1;
    my @graph_data = ( [], [] );
    my %graph_hash;

    my ( $data, $ymin, $ymax, $units );

    if ($file) {
        ( $data, $ymin, $ymax, $units ) = get_data_from_file(%args);    ## -file=>$file, -tail_lines=>$tail_lines, -delimiter=>$delimiter, -x_column=>$x_column, -y_column=>$y_column);
        @graph_data = @$data;
    }
    elsif ( $x_data || $y_data ) {
        ( $data, $ymin, $ymax, $units ) = get_data_directly(%args);     ################################## $x_data,$y_data);
        @graph_data = @$data;
    }
    elsif ($array) {
        @graph_data = @$array;
        ( $ymin, $ymax ) = get_min_max( \@graph_data );
    }
    elsif ($hash) {
        %graph_hash = %$hash;
        ( $ymin, $ymax ) = get_min_max($hash);
    }
    $ymax = pad_max($ymax);

    if ( $ymax == $ymin && $ymin == 0 ) {
        if ($debug) { print "Zero data set only for $file ($ymin - $ymax)\n" }
        return;
    }

    # collapse the array, putting repeated values onto a different array
    # keep track of the maximum number of values associated with one x value
    # because that is the number of arrays that need to be created
    my $maxdepth           = 0;
    my $count              = 0;
    my @ordered_graph_xval = ();

    if ($hash) {
        @ordered_graph_xval = sort { $a cmp $b } keys %graph_hash;
    }
    else {
        ## unless hash explicitly supplied... generate from graph_data array ##
        foreach my $item ( @{ $graph_data[0] } ) {

            # portion of code for nominal x-values
            push( @ordered_graph_xval, $item );
            if ($nominalx) {
                if ( defined $graph_hash{$item} ) {
                    my $i = 1;
                    while ( defined $graph_data[$i] ) { push( @{ $graph_hash{$item} }, $graph_data[ $i++ ]->[$count] ) }
                }
                else {
                    my $i = 1;
                    while ( defined $graph_data[$i] ) { push( @{ $graph_hash{$item} }, $graph_data[ $i++ ]->[$count] ) }

                    #                $graph_hash{$item} = [ $graph_data[1]->[$count] ];
                    $maxdepth = 1 if ( $maxdepth == 0 );
                }
            }

            # code for ordinal x values
            else {
                if ( defined $graph_hash{$item} ) {
                    push( @{ $graph_hash{$item} }, $graph_data[1]->[$count] );
                    if ( scalar( @{ $graph_hash{$item} } ) > $maxdepth ) {
                        $maxdepth = scalar( @{ $graph_hash{$item} } );
                    }
                }
                else {
                    $graph_hash{$item} = [ $graph_data[1]->[$count] ];
                    $maxdepth = 1 if ( $maxdepth == 0 );
                }
            }
            $count++;
        }
    }

    my @sorted_graph_data = ();
    for ( my $i = 0; $i < $maxdepth; $i++ ) {
        push( @sorted_graph_data, [] );
    }
    my %drawn_xval;

    if ($nominalx) {

        # portion of code for nominal x-values
        foreach my $key (@ordered_graph_xval) {
            if ( defined $drawn_xval{$key} ) {
                next;
            }
            else {
                $drawn_xval{$key} = 1;
            }
            my @item_array = @{ $graph_hash{$key} };
            for ( my $i = 0; $i <= scalar(@item_array); $i++ ) {
                if ( $i == 0 ) { push( @{ $sorted_graph_data[$i] }, $key ) }
                else {
                    push( @{ $sorted_graph_data[$i] }, $item_array[ $i - 1 ] );
                }
            }
        }
    }
    else {
        foreach my $key ( sort { $a <=> $b } keys %graph_hash ) {
            my @item_array = @{ $graph_hash{$key} };

            # code for ordinal x-values
            push( @{ $sorted_graph_data[0] }, $key );
            for ( my $i = 0; $i < $maxdepth; $i++ ) {
                if ( scalar(@item_array) > $i ) {
                    push( @{ $sorted_graph_data[ $i + 1 ] }, $item_array[$i] );
                }
                else {
                    push( @{ $sorted_graph_data[ $i + 1 ] }, undef );
                }
            }

        }

    }

    if ($units) { $title .= "($units)" }

    my $graph;
    if ($nominalx) {

        print "Generate bar graph\n" if $debug;

        # determine best xsize
        my $good_xsize = scalar( @{ $sorted_graph_data[0] } ) * $bar_width + 100;
        if ( $good_xsize > $image_xsize ) {
            $image_xsize = $good_xsize;
        }
        $graph = new GD::Graph::bars( $image_xsize, $image_ysize );
        $graph->set(
            x_label           => "$x_label",
            y_label           => "$y_label",
            title             => "$title",
            y_max_value       => "$ymax",
            y_min_value       => "$ymin",
            x_label_skip      => $x_label_skip,
            x_labels_vertical => 1,
            bar_width         => $bar_width,
            dclrs             => \@colours,
            r_margin          => 20
        ) or die $graph->error;
        $graph->set_x_label_font( 'arial', 20 );
    }
    else {
        print "Generate scatter plot\n" if $debug;
        $graph = new GD::Graph::points( $image_xsize, $image_ysize );
        $graph->set(
            x_label       => "$x_label",
            y_label       => "$y_label",
            title         => "$title",
            y_max_value   => "$ymax",
            y_min_value   => "$ymin",
            x_ticks       => 0,
            x_tick_number => "auto",
            marker_size   => $marker_size,
            dclrs         => \@colours,
            r_margin      => 20
        ) or die $graph->error;
    }

    print "Write to $output_file.\n" if $debug;

    open my $IMG, '>', $output_file or print "Error - could not write to $output_file\n";
    binmode $IMG;

    my $i = $graph->plot( \@sorted_graph_data ) or die $graph->error;

    print $IMG $i->gif;

    #     Message "Plotted graph to $output_file";
    close($IMG);

    return 1;
}

############################
sub get_data_from_file {
############################
    my %args       = filter_input( \@_ );
    my $file       = $args{-file};
    my $tail_lines = $args{-tail_lines};
    my $delimiter  = $args{-delimiter} || "\t";
    my $x_column   = $args{-x_column};
    my $y_column   = $args{-y_column};

    my @graph_data;
    my $nominalx;

    my ( $xcol, $ycol ) = ( -1, -1 );
    if ( $x_column =~ /^\d+$/ ) {
        $xcol = $x_column;
    }
    if ( $y_column =~ /^\d+$/ ) {
        $ycol = $y_column;
    }

    my $start_line_num = 1;
    if ($tail_lines) {
        my $line_count = try_system_command("wc -l < $file");
        chomp $line_count;
        unless ( $line_count <= $tail_lines ) {
            $start_line_num = $line_count - $tail_lines;
        }
    }

    my $count = 0;
    open my $FH, '<', $file or die "Cannot find & open $file";
    while (<$FH>) {
        my $line = $_;
        chomp($line);
        my @cols = split( /$delimiter/, $line );

        # if the x or y axis hasn't been defined, look for it in the table headers
        # if it still cannot be resolved, fail out
        if ( ( $count == 0 ) && ( ( $xcol == -1 ) || ( $ycol == -1 ) ) ) {
            my $index = 0;
            foreach my $item (@cols) {
                if ( ( $xcol == -1 ) && ( ( $item eq $args{-x_label} && !$args{-x_column_name} ) || ( $item eq $args{-x_column_name} ) ) ) {
                    $xcol = $index;
                }
                if ( ( $ycol == -1 ) && ( ( $item eq $args{y_label} && !$args{-y_column_name} ) || ( $item eq $args{-y_column_name} ) ) ) {
                    $ycol = $index;
                }
                $index++;
            }
            if ( ( $xcol == -1 ) || ( $ycol == -1 ) ) {
                print "X and Y axis not defined, failing out...\n";
                close($FH);
                exit;
            }
            next;
        }
        if ( $count < $start_line_num ) {
            $count++;
            next;
        }

        # normal case is data. Parse out the defined x and y columns
        my $y = $cols[$ycol];
        my $x;
        if   ( defined $args{-xcol} ) { $x = $cols[$xcol] }
        else                          { $x = $count }

        # if any x_values are non-numeric - assume nominalx (bar graph labels) #
        if ( $x !~ /^([\-\d\.]+)$/ ) {
            $nominalx = 1;
        }

        if ( $y =~ /^([\-\d\.]+(\S*))/ ) {
            ## ok float or integer ##
            $y = $1;
            $args{-units} = $2;
        }
        elsif ( $y eq '' ) {
            $y = 0;
        }
        else {

            #		print "skipping line $count - Non-Numeric data:\n X - $x_label: $x\n Y - $y_label: $y\n\n";
            $args{-y_label} ||= $y;
            if ( $count == 1 ) { $args{-title} .= " ($x vs $y)" }
            next;
        }

        push( @{ $graph_data[0] }, $x );
        push( @{ $graph_data[1] }, $y );
        $count++;
    }
    close($FH);

    my ( $ymin, $ymax ) = get_min_max( -data => $graph_data[1] );

    return ( \@graph_data, $ymin, $ymax, $args{-units} );
}

###########################
sub get_data_directly {
###########################
    my %args = filter_input( \@_ );

    my $x_data = $args{-x_data};
    my $y_data = $args{-y_data};
    my $debug  = $args{-debug};

    my (@graph_data);
    my $count = 0;

    ## data provided directly ##
    if ( !( int( @{$y_data} ) ) ) {
        print "Setting X-data to 1..N\n";
        my @data = @{$x_data};
        $y_data = [@data];
        $x_data = [ 1 .. int( @{$y_data} ) ];
    }

    if ( $x_data && ( int( @{$x_data} ) == int( @{$y_data} ) ) ) {
        my $i = 0;
        while ( defined $x_data->[$i] ) {
            my $x = $x_data->[$i];
            my $y = $y_data->[$i];

            if ( ref $y eq 'ARRAY' ) {
                Message("Array input");
                if ( $i == 0 ) { push @{ $graph_data[0] }, @{$x_data}; }

                push @{ $graph_data[0] }, $x;
                foreach my $j ( 1 .. int(@$y) ) { push @{ $graph_data[ $i + 1 ] }, $y_data->[ $j - 1 ] }

            }
            else {
                push @{ $graph_data[0] }, $x;
                push @{ $graph_data[1] }, $y;

                ## only applicable if y values are array of scalars... ##

                # if any x_values are non-numeric - assume nominalx (bar graph labels) #
                if ( $x !~ /^[\-\d\.]+$/ ) {
                    $args{-nominalx} = 1;
                }

                if ( $y =~ /^([\-\d\.]+)(\S*)/ ) {
                    $y = $1;
                    $args{-units} = $2;
                }
                elsif ( $y eq "" ) {
                    $y = 0;
                }
                else {
                    print "skipping line $count (header?) - Non-numeric data:\n X - $args{-y_label}: $x\n Y - $args{-y_label}: $y\n\n";
                    if ( !$i ) { $args{-title} .= " ($x vs $y)" }    ## assume line 1 is a header
                    $i++;
                    next;
                }

            }

            $i++;
        }
        $count = $i;
        print "Found $i data points\n" if $debug;
    }

    else {
        print "X: $x_data; ";
        print "N=" . int( @{$x_data} );
        print "; M=" . int( @{$y_data} );
        print "Error: x_data list not consistent with y_data list\n";
        return 0;
    }

    my ( $ymin, $ymax ) = get_min_max( -data => $graph_data[1] );

    return ( \@graph_data, $ymin, $ymax, $args{-units} );
}

#
# Retrive Min, Max values
#
# Works for scalar, array, hash, array of hashes
# (may supply optional starting min, max values)
#
#
# Return: overall minimum, maximum value found
####################
sub get_min_max {
####################
    my %args = filter_input( \@_, -args => 'data,min,max' );
    my $data = $args{-data};
    my $min  = $args{-min};
    my $max  = $args{-max};

    if ( ref $data eq 'ARRAY' ) {
        foreach my $val (@$data) {
            ( $min, $max ) = get_min_max( $val, $min, $max );
        }
    }
    elsif ( ref $data eq 'HASH' ) {
        foreach my $key ( keys %$data ) {
            my $val = $data->{$key};
            ( $min, $max ) = get_min_max( $val, $min, $max );
        }
    }
    else {
        my $val = $data;
        if ( $val < $min )   { $min = $val }
        if ( $val > $max )   { $max = $val }
        if ( !defined $min ) { $min = $val }
        if ( !defined $max ) { $max = $val }
    }

    return ( $min, $max );
}

#
# Pad maximum values to give a neater maximum for graphs
#
# rounds up values to 2 significant digits
#
# Return: padded max
################
sub pad_max {
################
    my $max = shift;

    if ( $max <= 0 ) { return $max }    ## different logic required for negatives.

    my $mag = 1;
    while ( $max > $mag ) {
        $mag *= 10;
    }

    my $padded = int( 100 * $max / $mag );

    if ( $padded / 10 > int( $padded / 10 ) ) { $padded++ }    ## round 1.28 -> 1.4, but leave 2.0 as 2.0 ##

    $padded *= $mag / 100;
    return $padded;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
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

2004-11-29

=head1 REVISION <UPLINK>

$Id: Graph.pm,v 1.4 2004/12/09 17:42:40 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
