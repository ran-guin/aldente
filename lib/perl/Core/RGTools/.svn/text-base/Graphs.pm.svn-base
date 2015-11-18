###################################################################################################################################
# Graphs.pm
#
# A light-weight module to create simple line/bar/pie/matrix graphs with minimum user input
# This module is a wrapper of GD::Graph.
# It simplifies the usage by setting many options to LIMS-prefered defaul values and a single method to generate every type of graph.
#
# This module contains the following methods:
#
# Public Methods:
# new:                 constructor.
# set_config:          set the graph configuration.
# get_config:          get the graph configuratin.
# create_graph:        create the graph
# get_PNG:             get the image in PNG format
# get_GIF:             get the image in GIF format
# get_PNG_HTML:        get the HTML code piece (<img>) for PNG graph
# get_GIF_HTML:        get the HTML code piece (<img>) for GIF graph
#
# Private Methods:
# _set_general_config: set graph configurations common to all graphs
# _set_line_config:    set graph configurations specific to Line graphs
# _set_bar_config:     set graph configurations specific to Bar graphs
# _set_pie_config:     set graph configurations specific to Pie graphs
# _set_matrix_config:  set graph configurations specific to a Matrix
# _set_line_graph:     create the part of the graph specific to Line graphs
# _set_bar_graph:      create the part of the graph specific to Bar graphs
# _set_pie_graph:      create the part of the graph sepcific to Pie graphs
# _set_matrix_graph:   create the part of the graph specific to a Matrix
#
# Example of usage:
#
# use RGTools::Graphs;
#
# ## data hash should have the following structure:
# ## 'x_axis'   => array reference of x_axis values
# ## 'dataset1' => array reference of values for dataset1
# ## 'dataset2' => array reference of values for dataset2
# ## ...
# ## 'dataset1', 'dataset2' should be replaced with the dataset names which will be appeared in the legend.
# my %data = ('x_axis'  =>  ["QC_AFFX_5Q_123","QC_AFFX_5Q_456","QC_AFFX_5Q_789","QC_AFFX_5Q_ABC"],
#	       'set 1'  =>  [    25,    30,    32,    40],
#	      );
#
# ## construct a graphs object with data and options
# my $graph = Graphs->new(-data=>\%data, -title=>'QC Plot', -x_label=>'QC Items', -y_label=>'Values');
#
# ## create an Line graph
# $graph->create_graph(-type=>'line');
#
# ## obtain the png graph
# my $png = $graph->get_PNG();
#
# ## write to a file
# open(IMG, ">test_xy.png") or die $!;
# binmode IMG;
# print IMG $png;
# close IMG;
#
# ## create a bar graph
# $graph->create_graph(-type=>'bar');
#
# ## obtain the png graph
# $png = $graph->get_PNG();
#
# ## write to a file
# open(IMG, ">test_bar.png") or die $!;
# binmode IMG;
# print IMG $png;
# close IMG;
#
# ## create a pie graph
# $graph->create_graph(-type=>'pie');
#
# ## obtain the png graph
# $png = $graph->get_PNG();
#
# ## write to a file
# open(IMG, ">test_pie.png") or die $!;
# binmode IMG;
# print IMG $png;
# close IMG;
#
# ## create a matrix
# $graph->create_graph(-type=>'matrix');
#
# ## obtain the png graph
# $png = $graph->get_PNG();
#
# ## write to a file
# open(IMG, ">test_matrix.png") or die $!;
# binmode IMG;
# print IMG $png;
# close IMG;
###################################################################################################################################

package Graphs;

use RGTools::RGIO;
use Data::Dumper;
use strict;

use GD::Graph::lines;
use GD::Graph::bars;
use GD::Graph::hbars;
use GD::Graph::points;
use GD::Graph::linespoints;
use GD::Graph::area;
use GD::Graph::mixed;
use GD::Graph::pie;
use GD::Graph::xylines;
use GD::Graph::xypoints;
use GD::Graph::xylinespoints;

use GD;

# ============================================================================
# Method     : new()
# Usage      : my $graph = Graphs->new()
# Purpose    : create a new graph object with options
# Returns    : a Graphs object
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my %args     = filter_input( \@_ );

    my $self = {};

    bless( $self, $class );

    $self->set_config(%args);

    return $self;
}

# ============================================================================
# Method     : set_config()
# Usage      : $graph->set_config();
# Purpose    : set options
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub set_config {
    my $self = shift;
    my %args = @_;
    $self->_set_general_config(%args);
    $self->_set_line_config(%args);
    $self->_set_bar_config(%args);
    $self->_set_pie_config(%args);
    $self->_set_matrix_config(%args);
    return;
}

# ============================================================================
# Method     : get_config()
# Usage      : $graph->get_config();
# Purpose    : set options
# Returns    : hash reference including all options (see option spec)
# Parameters : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub get_config {
    my $self   = shift;
    my $config = $self;
    delete( $config->{graph} ) if exists( $config->{graph} );
    delete( $config->{image} ) if exists( $config->{image} );
    return $config;
}

# ============================================================================
# Method     : create_graph()
# Usage      : $graph->create_graph();
# Purpose    : create the graph
# Returns    : the graph image that can be converted to png
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub create_graph {
    my $self = shift;
    my %args = @_;

    $self->_set_general_config(%args);

    # general config
    my $type        = $self->{type};
    my $dclrs       = $self->{dclrs};
    my $bgclr       = $self->{bgclr};
    my $transparent = $self->{transparent};
    my $interlaced  = $self->{interlaced};
    my $zero_axis   = $self->{zero_axis};

    my $gd;

    # check if data is a valid hash. if not, return empty.
    return $gd unless ref( $self->{data} ) eq "HASH";

    # create graphs according to type

    if ( $type =~ /line/i || $type =~ /xy/i ) {    # Line graph

        $self->_set_line_config(%args);
        $self->_set_thumbnail();
        $self->_set_line_graph();

    }
    elsif ( $type =~ /bar/i ) {

        $self->_set_bar_config(%args);
        $self->_set_thumbnail();
        $self->_set_bar_graph();

    }
    elsif ( $type =~ /pie/i ) {

        $self->_set_pie_config(%args);
        $self->_set_thumbnail();
        $self->_set_pie_graph();

    }
    elsif ( $type =~ /matrix/i ) {

        $self->_set_matrix_config(%args);
        $self->_set_matrix_graph();

        return $self->{image};

    }
    else {
        print "format not supported";
    }

    # general settings
    $self->{graph}->set_title_font("gdMediumBoldFont");
    $self->{graph}->set(
        dclrs       => $dclrs,
        bgclr       => $bgclr,
        transparent => $transparent,
        interlaced  => $interlaced
    );

    $gd = $self->{graph}->plot( $self->{plot_data} ) or die $self->{graph}->error;

    $self->{image} = $gd;
    return $gd;
}

# ============================================================================
# Method     : create_blank_graph()
# Usage      : $graph->create_blank_graph();
# Purpose    : create a blank graph
# Returns    : the graph image that can be converted to png
# Parameters : see option specs
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub create_blank_graph {
    my $self = shift;
    my %args = @_;

    $self->_set_general_config(%args);

    # general config
    my $type        = $self->{type};
    my $dclrs       = $self->{dclrs};
    my $bgclr       = $self->{bgclr};
    my $transparent = $self->{transparent};
    my $interlaced  = $self->{interlaced};
    my $zero_axis   = $self->{zero_axis};

    my $im = new GD::Image( $self->{width}, $self->{height} );

    # allocate some colors
    my $white = $im->colorAllocate( 255, 255, 255 );
    my $black = $im->colorAllocate( 0,   0,   0 );

    # make the background transparent and interlaced
    $im->transparent($white);
    $im->interlaced('true');

    # Put a black frame around the picture
    $im->rectangle( 0, 0, $self->{width} - 1, $self->{height} - 1, $black );

    #print Dumper $self->{graph};
    $self->{image} = $im;
    return $im;

}

# ============================================================================
# Method     : get_PNG()
# Usage      : $graph->get_PNG();
# Purpose    : get PNG image of the graph
# Returns    : PNG image of the graph
# Parameters : -image: image to be converted. optional
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub get_PNG {
    my $self  = shift;
    my %args  = @_;
    my $image = $args{-image} || $self->{image};
    return $image->png;
}

sub get_GIF {
    my $self  = shift;
    my %args  = @_;
    my $image = $args{-image} || $self->{image};
    return $image->gif;
}

# get the <img src="some src"/>
sub create_PNG_file {
    my $self      = shift;
    my %args      = @_;
    my $image     = $args{-image} || $self->{image};
    my $file_path = $args{-file_path};

    open( my $IMG, ">$file_path" ) or die $!;
    binmode $IMG;
    print $IMG $image->png;
    close $IMG;

    my $return;
    if ( -e $file_path ) {
        $return = 1;
    }
    else {
        $return = 0;
    }
    return $return;

}

sub create_GIF_file {
    my $self      = shift;
    my %args      = @_;
    my $image     = $args{-image} || $self->{image};
    my $file_path = $args{-file_path};

    open( my $IMG, ">$file_path" ) or die $!;
    binmode $IMG;
    print $IMG $image->gif;
    close $IMG;

    my $return;
    if ( -e $file_path ) {
        $return = 1;
    }
    else {
        $return = 0;
    }
    return $return;

}

# get the <img src="some src"/>
sub get_PNG_HTML {
    my $self      = shift;
    my %args      = @_;
    my $image     = $args{-image} || $self->{image};
    my $file_path = $args{-file_path};
    my $file_url  = $args{-file_url};
    my $link      = $args{ -link };
    my $alt       = $args{-alt};

    if ( open( my $IMG, ">$file_path" ) ) {
        binmode $IMG;
        print $IMG $image->png;
        close $IMG;
    }
    else {
        Message("cannot open $file_path: $!");
    }

    if ($link) {
        return "<a href='$link'><img src='$file_url' alt='$alt'></img></a>";
    }
    else {
        return "<img src='$file_url' alt='$alt'></img>";
    }
}

sub get_GIF_HTML {
    my $self      = shift;
    my %args      = @_;
    my $image     = $args{-image} || $self->{image};
    my $file_path = $args{-file_path};
    my $file_url  = $args{-file_url};
    my $link      = $args{ -link };
    my $alt       = $args{-alt};

    open( my $IMG, ">$file_path" ) or die $!;
    binmode $IMG;
    print $IMG $image->gif;
    close $IMG;
    if ($link) {
        return "<a href='$link'><img src='$file_url' alt='$alt'></img></a>";
    }
    else {
        return "<img src='$file_url' alt='$alt'></img>";
    }
}

# ============================================================================
# Method     : _set_thumbnail()
# Usage      : $graph->_set_thumbnail();
# Purpose    : unset height, weight, title, x_label, y_label, etc to create a thumbnail
# Returns    : none
# Parameters : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_thumbnail {
    my $self = shift;

    my $thumbnail = $self->{thumbnail};

    if ($thumbnail) {

        $self->{height}            = 40;
        $self->{width}             = 100;
        $self->{title}             = "";
        $self->{x_label}           = "";
        $self->{y_label}           = "";
        $self->{x_labels_vertical} = 0;
        $self->{y_tick_number}     = 1;
        $self->{show_values}       = 0;
        $self->{no_legend}         = 1;
        $self->{axis_font}         = "gdTinyFont";
        $self->{y_number_format}   = "%.1g";
        $self->{marker_size}       = 1;
        $self->{axis_space}        = 0;
        $self->{y_label_skip}      = $self->{y_tick_number} - 1;

        # determine x label_skip
        my $data = $self->{data};
        if ( $data && ( ref $data ) =~ /HASH/ ) {
            my $x_data = $data->{x_axis};
            if ( $x_data && ( ref $x_data ) =~ /ARRAY/ ) {
                $self->{x_label_skip} = ( scalar @$x_data ) - 1;
            }
        }
        $self->{axislabelclr} = $self->{bgclr};
        $self->{long_ticks}   = 0;
    }

}

# ============================================================================
# Method     : _set_axis_config()
# Usage      : $graph->_set_axis_config(-x_tick_number=>5);
# Purpose    : set options for graph with axis
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_axis_config {

    my $self = shift;
    my %args = @_;

    # y axis config
    $self->{y_label}         = $args{-y_label}         if exists $args{-y_label};
    $self->{y_max_value}     = $args{-y_max_value}     if exists $args{-y_max_value};
    $self->{y_min_value}     = $args{-y_min_value}     if exists $args{-y_min_value};
    $self->{y_tick_number}   = $args{-y_tick_number}   if exists $args{-y_tick_number};
    $self->{y_label_skip}    = $args{-y_label_skip}    if exists $args{-y_label_skip};
    $self->{y_number_format} = $args{-y_number_format} if exists $args{-y_number_format};

    # x axis config
    $self->{x_label}           = $args{-x_label}           if exists $args{-x_label};
    $self->{x_max_value}       = $args{-x_max_value}       if exists $args{-x_max_value};
    $self->{x_min_value}       = $args{-x_min_value}       if exists $args{-x_min_value};
    $self->{x_tick_number}     = $args{-x_tick_number}     if exists $args{-x_tick_number};
    $self->{x_label_skip}      = $args{-x_label_skip}      if exists $args{-x_label_skip};
    $self->{x_number_format}   = $args{-x_number_format}   if exists $args{-x_number_format};
    $self->{x_labels_vertical} = $args{-x_labels_vertical} if exists $args{-x_labels_vertical};

    # value config
    $self->{show_values}   = $args{-show_values}   if exists $args{-show_values};
    $self->{values_format} = $args{-values_format} if exists $args{-values_format};

    # ticks options
    $self->{long_ticks} = $args{-long_ticks} if exists $args{-long_ticks};

    # axis space
    $self->{axis_space} = $args{-axis_space} if exists $args{-axis_space};

    # set non-undef default values
    $self->{y_tick_number} = 5 unless defined $self->{y_tick_number};
    $self->{y_label_skip}  = 1 unless defined $self->{y_label_skip};
    $self->{x_label_skip}  = 1 unless defined $self->{x_lable_skip};
    $self->{axis_space}    = 4 unless defined $self->{axis_space};
    $self->{long_ticks}    = 0 unless defined $self->{long_ticks};

    return;
}

# ============================================================================
# Method     : _set_line_config()
# Usage      : $graph->_set_line_config(-x_tick_number=>5);
# Purpose    : set options for Line graph
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_line_config {

    my $self = shift;
    my %args = @_;

    $self->_set_axis_config(%args);

    # set marker_size
    $self->{marker_size} = $args{-marker_size} if exists $args{-marker_size};

    # set non-undef default values
    $self->{marker_size} = 4 unless defined $self->{marker_size};

    return;
}

# ============================================================================
# Method     : _set_bar_config()
# Usage      : $graph->_set_bar_config(-title=>$title, -bar_width=>$bar_width,
#                                   -bar_spacing=>$bar_spacing, -show_values=>$show_values,
#                                   -values_format=>$values_format);
# Purpose    : set options for bar graph
# Returns    : none
# Parameters : -title:         graph title. e.g., "Test"
#              -bar_width:     width (in pixel) of the bar.   e.g., 5.  default: 5
#              -bar_spacing:   spacing (in pixel) of the bar. e.g., 10. default: 10
#              -show_values:   if the values are shown.       e.g., 1.  default: 0
#              -values_format: a string representing the format of the values. same as used in sprintf. e.g., "\$%d". default: undef
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_bar_config {

    my $self = shift;
    my %args = @_;

    # set config for axises
    $self->_set_axis_config(%args);

    # bar specific config
    $self->{bar_width}   = $args{-bar_width}   if exists $args{-bar_width};
    $self->{bar_spacing} = $args{-bar_spacing} if exists $args{-bar_spacing};

    # set non-undef default values
    $self->{bar_width}   = 10 unless defined $self->{bar_width};
    $self->{bar_spacing} = 4  unless defined $self->{bar_spacing};

    return;
}

# ============================================================================
# Method     : _set_pie_config()
# Usage      : $graph->_set_pie_config();
# Purpose    : set options specific for Pie graph
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_pie_config {

    my $self = shift;
    my %args = @_;

    # set config for pie
    $self->{'3d'}           = $args{'-3d'}           if exists $args{'-3d'};
    $self->{pie_height}     = $args{-pie_height}     if exists $args{-pie_height};
    $self->{start_angle}    = $args{-start_angle}    if exists $args{-start_angle};
    $self->{suppress_angle} = $args{-suppress_angle} if exists $args{-suppress_angle};

    #set non-undef default values
    $self->{'3d'}       = 1                     unless defined $self->{'3d'};
    $self->{pie_height} = 0.1 * $self->{height} unless defined $self->{pie_height};
    $self->{label}      = $self->{title};
    return;
}

# ============================================================================
# Method     : _set_matrix_config()
# Usage      : $graph->_set_matrix_config();
# Purpose    : set options specific for matrix
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_matrix_config {

    my $self = shift;
    my %args = @_;

    # set margin for title
    $self->{margin}        = $args{-margin}        if exists $args{-margin};          # height for title
    $self->{grid_color}    = $args{-grid_color}    if exists $args{-grid_color};
    $self->{content_color} = $args{-content_color} if exists $args{-content_color};

    #set non-undef default values
    $self->{margin}        = 20      unless defined $self->{margin};
    $self->{grid_color}    = "black" unless defined $self->{grid_color};
    $self->{content_color} = "black" unless defined $self->{content_color};

    return;
}

# ============================================================================
# Method     : _set_general_config()
# Usage      : $graph->_set_general_config();
# Purpose    : set general options for all graph
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

# set general settings
sub _set_general_config {
    my $self = shift;
    my %args = @_;

    # thumbnail
    $self->{thumbnail} = $args{-thumbnail} if exists $args{-data};

    #plot data
    $self->{data} = $args{-data} if exists $args{-data};

    # graph title
    $self->{title} = $args{-title} if exists $args{-title};

    #general settings
    if ( exists $args{-type} ) {
        $self->{type} = $args{-type};
    }
    unless ( defined $self->{type} ) {
        $self->{type} ||= "line";
    }

    if ( exists $args{-height} ) {
        $self->{height} = $args{-height};
    }
    unless ( defined $self->{height} ) {
        $self->{height} ||= 300;
    }

    if ( exists $args{-width} ) {
        $self->{width} = $args{-width};
    }
    unless ( defined $self->{width} ) {
        $self->{width} ||= 400;
    }

    if ( exists $args{-dclrs} ) {
        $self->{dclrs} = $args{-dclrs};
    }
    unless ( defined $self->{dclrs} ) {
        $self->{dclrs} ||= [qw(red orange yellow green dgreen blue purple black)];
    }

    if ( exists $args{-bgclr} ) {
        $self->{bgclr} = $args{-bgclr};
    }
    unless ( defined $self->{bgclr} ) {
        $self->{bgclr} ||= "white";
    }

    if ( exists $args{-axislabelclr} ) {
        $self->{axislabelclr} = $args{-axislabelclr};
    }
    unless ( defined $self->{axislabelclr} ) {
        $self->{axislabelclr} ||= "blue";
    }

    if ( exists $args{-transparent} ) {
        $self->{transparent} = $args{-transparent};
    }
    unless ( defined $self->{transparent} ) {
        $self->{transparent} ||= 0;
    }

    if ( exists $args{-interlaced} ) {
        $self->{interlaced} = $args{-interlaced};
    }
    unless ( defined $self->{interlaced} ) {
        $self->{interlaced} ||= 0;
    }

    if ( exists $args{-zero_axis} ) {
        $self->{zero_axis} = $args{-zero_axis};
    }
    unless ( defined $self->{zero_axis} ) {
        $self->{zero_axis} ||= 0;
    }
    return;

}

# ============================================================================
# Method     : _set_line_graph()
# Usage      : $graph->_set_line_graph();
# Purpose    : create the part of graph specific to Line graph
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_line_graph {

    my $self = shift;

    # graph type
    my $type = $self->{type};

    # width and height
    my $width  = $self->{width};
    my $height = $self->{height};

    #data
    my $data = $self->{data};

    # graph title
    my $title = $self->{title};

    # y axis config
    my $y_label         = $self->{y_label};
    my $y_max_value     = $self->{y_max_value};
    my $y_min_value     = $self->{y_min_value};
    my $y_tick_number   = $self->{y_tick_number};
    my $y_label_skip    = $self->{y_lable_skip};
    my $y_number_format = $self->{y_number_format};

    # x axis config
    my $x_label           = $self->{x_label};
    my $x_max_value       = $self->{x_max_value};
    my $x_min_value       = $self->{x_min_value};
    my $x_tick_number     = $self->{x_tick_number};
    my $x_label_skip      = $self->{x_label_skip};
    my $x_number_format   = $self->{x_number_format};
    my $x_labels_vertical = $self->{x_labels_vertical};

    # values config
    my $show_values   = $self->{show_values};
    my $values_format = $self->{values_format};
    my $zero_axis     = $self->{zero_axis};

    # ticks option
    my $long_ticks = $self->{long_ticks};

    # marker size
    my $marker_size = $self->{marker_size};

    # axis space
    my $axis_space = $self->{axis_space};

    # axis label color
    my $axis_label_color = $self->{axislabelclr};

    #push x axis into plot_data
    my $x_axis    = $data->{x_axis};
    my $plot_data = [$x_axis];

    my @legend;
    foreach my $key ( sort { $a cmp $b } keys %$data ) {
        if ( $key ne "x_axis" ) {
            push( @legend,     $key );
            push( @$plot_data, $data->{$key} );
        }
    }

    my $graph;

    if ( $type =~ /line/i ) {
        $graph = GD::Graph::linespoints->new( $width, $height );
    }
    elsif ( $type =~ /xy/i ) {
        $graph = GD::Graph::xylinespoints->new( $width, $height );
    }

    $graph->set(
        title             => $title,
        x_label           => $x_label,
        x_tick_number     => $x_tick_number,
        x_label_skip      => $x_label_skip,
        x_number_format   => $x_number_format,
        x_labels_vertical => $x_labels_vertical,

        y_label         => $y_label,
        y_tick_number   => $y_tick_number,
        y_label_skip    => $y_label_skip,
        y_number_format => $y_number_format,

        show_values   => $show_values,
        values_format => $values_format,
        zero_axis     => $zero_axis,

        long_ticks => $long_ticks,

        marker_size => $marker_size,

        axis_space => $axis_space,

        axislabelclr => $axis_label_color,

    ) or die $graph->error;

    #print Dumper $graph;

    if ( defined $y_min_value ) {
        $graph->set( y_min_value => $y_min_value );
    }

    if ( defined $y_max_value ) {
        $graph->set( y_max_value => $y_max_value );
    }

    if ( defined $x_min_value ) {
        $graph->set( x_min_value => $x_min_value );
    }

    if ( defined $x_max_value ) {
        $graph->set( x_max_value => $x_max_value );
    }
    if ( scalar @legend > 0 && !$self->{no_legend} ) {
        $graph->set_legend(@legend);
    }

    if ( $self->{axis_fond} ) {
        $graph->set_x_axis_font( $self->{axis_font} );
        $graph->set_x_axis_font( $self->{axis_font} );
    }

    $self->{plot_data} = $plot_data;
    $self->{legend}    = \@legend;
    $self->{graph}     = $graph;
    return;
}

# ============================================================================
# Method     : _set_bar_graph()
# Usage      : $graph->_set_bar_graph();
# Purpose    : create the part of graph specific to Bar graph
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_bar_graph {
    my $self = shift;

    # width and height
    my $width  = $self->{width};
    my $height = $self->{height};

    #data
    my $data = $self->{data};

    # graph title
    my $title = $self->{title};

    # y axis config
    my $y_label         = $self->{y_label};
    my $y_max_value     = $self->{y_max_value};
    my $y_min_value     = $self->{y_min_value};
    my $y_tick_number   = $self->{y_tick_number};
    my $y_label_skip    = $self->{y_lable_skip};
    my $y_number_format = $self->{y_number_format};

    # x axis config
    my $x_label           = $self->{x_label};
    my $x_tick_number     = $self->{x_tick_number};
    my $x_label_skip      = $self->{x_lable_skip};
    my $x_labels_vertical = $self->{x_labels_vertical};

    # bar config
    my $bar_width   = $self->{bar_width};
    my $bar_spacing = $self->{spacing};

    # values config
    my $show_values   = $self->{show_values};
    my $values_format = $self->{values_format};
    my $zero_axis     = $self->{zero_axis};

    # get axis space
    my $axis_space = $self->{axis_space};

    # axis label color
    my $axis_label_color = $self->{axislabelclr};

    #push x axis into plot_data
    my $x_axis    = $data->{x_axis};
    my $plot_data = [$x_axis];

    my @legend;
    foreach my $key ( sort { $a cmp $b } keys %$data ) {
        if ( $key ne "x_axis" ) {
            push( @legend,     $key );
            push( @$plot_data, $data->{$key} );
        }
    }

    my $graph = GD::Graph::bars->new( $width, $height );

    $graph->set(
        title => $title,

        x_label           => $x_label,
        x_tick_number     => $x_tick_number,
        x_label_skip      => $x_label_skip,
        x_labels_vertical => $x_labels_vertical,

        y_label         => $y_label,
        y_tick_number   => $y_tick_number,
        y_label_skip    => $y_label_skip,
        y_number_format => $y_number_format,

        bar_width   => $bar_width,
        bar_spacing => $bar_spacing,

        show_values   => $show_values,
        values_format => $values_format,
        zero_axis     => $zero_axis,

        axis_space => $axis_space,

        axislabelclr => $axis_label_color,

    ) or die $graph->error;

    if ( defined $y_min_value ) {
        $graph->set( y_min_value => $y_min_value );
    }

    if ( defined $y_max_value ) {
        $graph->set( y_max_value => $y_max_value );
    }
    if ( scalar @legend > 0 && !$self->{no_legend} ) {
        $graph->set_legend(@legend);
    }

    if ( $self->{axis_fond} ) {
        $graph->set_x_axis_font( $self->{axis_font} );
        $graph->set_x_axis_font( $self->{axis_font} );
    }

    $self->{plot_data} = $plot_data;
    $self->{legend}    = \@legend;
    $self->{graph}     = $graph;
    return;
}

# ============================================================================
# Method     : _set_pie_graph()
# Usage      : $graph->_set_pie_graph();
# Purpose    : create the part of graph specific to Pie graph
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_pie_graph {

    my $self = shift;

    # width and height
    my $width  = $self->{width};
    my $height = $self->{height};

    #data
    my $data = $self->{data};

    # graph title
    my $label = $self->{label};

    # bar config
    my $threed         = $self->{'3d'};
    my $pie_height     = $self->{pie_height};
    my $start_angle    = $self->{start_angle};
    my $suppress_angle = $self->{suppress_angle};

    #push x axis into plot_data
    my $x_axis    = $data->{x_axis};
    my $plot_data = [$x_axis];

    my @legend;
    foreach my $key ( sort { $a cmp $b } keys %$data ) {
        if ( $key ne "x_axis" ) {
            push( @legend,     $key );
            push( @$plot_data, $data->{$key} );
        }
    }

    my $graph = GD::Graph::pie->new( $width, $height );

    $graph->set(
        label => $label,

        '3d'           => $threed,
        pie_height     => $pie_height,
        start_angle    => $start_angle,
        suppress_angle => $suppress_angle,

    ) or die $graph->error;

    $graph->set_value_font(gdMediumBoldFont);

    $self->{plot_data} = $plot_data;
    $self->{legend}    = \@legend;
    $self->{graph}     = $graph;
    return;

}

# ============================================================================
# Method     : _set_matrix_graph()
# Usage      : $graph->_set_matrix_graph();
# Purpose    : create the part of graph specific to Matrix graph
# Returns    : none
# Parameters : see option spec
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ============================================================================

sub _set_matrix_graph {

    my $self   = shift;
    my $width  = $self->{width};
    my $height = $self->{height};

    # title
    my $title = $self->{title};

    #data
    my $data = $self->{data};

    # color
    my $grid_color    = $self->{grid_color};
    my $content_color = $self->{content_color};

    # title margin
    my $margin = $self->{margin};

    my $im = new GD::Image( $width, $height + $margin );
    my $white = $im->colorAllocate( 255, 255, 255 );    # background color

    #grid color
    $grid_color = _convert_matrix_color( -color => $grid_color, -image => $im );

    #content color
    $content_color = _convert_matrix_color( -color => $content_color, -image => $im );

    $im->interlaced('true');

    my $x_start = 0;
    my $y_start = $margin;

    $im->string( gdGiantFont, 0, 3, $title, $grid_color );

    $im->rectangle( $x_start, $y_start, $width - 1, $height + $margin - 1, $grid_color );

    my $num_row = scalar( keys %$data ) || 1;
    my @values_size = map { scalar(@$_) } ( sort { scalar(@$b) <=> scalar(@$a) } values %$data );
    my $num_col = $values_size[0] || 1;

    my $unit_height = $height / $num_row;
    my $unit_width  = $width / $num_col;

    my @keys = sort { $a <=> $b } keys %$data;

    for ( my $i = 0; $i < scalar @keys; $i++ ) {
        my @values = @{ $data->{ $keys[$i] } };
        for ( my $j = 0; $j < scalar @values; $j++ ) {
            my $x_top_left     = $x_start + $j * $unit_width;
            my $y_top_left     = $y_start + $i * $unit_height;
            my $x_bottom_right = $x_start + ( $j + 1 ) * $unit_width;
            my $y_bottom_right = $y_start + ( $i + 1 ) * $unit_height;

            $im->rectangle( $x_top_left, $y_top_left, $x_bottom_right, $y_bottom_right, $grid_color );
            my $cell_value = $values[$j];
            if ($cell_value) {
                if ( $cell_value =~ /\w+/ ) {
                    $im->string( gdMediumBoldFont, $x_top_left, $y_top_left, $cell_value, $content_color );
                }
                else {
                    $im->filledEllipse( $x_top_left + ( $unit_width / 2 ), $y_top_left + ( $unit_height / 2 ), $unit_width, $unit_height, $content_color );

                    #$im->filledRectangle($x_top_left, $y_top_left, $x_bottom_right, $y_bottom_right,$black);
                }
            }
            else {
                $im->rectangle( $x_top_left, $y_top_left, $x_bottom_right, $y_bottom_right, $grid_color );
            }
        }
    }
    $self->{image} = $im;

    return;
}

sub _convert_matrix_color {

    my %args  = @_;
    my $color = $args{-color};
    my $image = $args{-image};
    my $return;

    if ( $color =~ /black/i ) {
        $return = $image->colorAllocate( 0, 0, 0 );
    }
    elsif ( $color =~ /red/i ) {
        $return = $image->colorAllocate( 255, 0, 0 );
    }
    elsif ( $color =~ /blue/i ) {
        $return = $image->colorAllocate( 0, 0, 255 );
    }
    else {
        $return = $image->colorAllocate( 0, 0, 0 );
    }

    return $return;

}

1;
