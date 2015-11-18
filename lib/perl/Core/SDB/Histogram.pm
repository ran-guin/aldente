###############################
#
# Histogram.pm
#
# This package allows generation of histograms as png images.
#
# ( see also /home/martink/export/prod/modules/historgram.pm for another Histogram module )
#
###############################
package SDB::Histogram;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Histogram.pm - This package allows generation of histograms as png images.

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This package allows generation of histograms as png images.<BR>( see also /home/martink/export/prod/modules/historgram.pm for another Histogram module )<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT    = qw();
@EXPORT_OK = qw();

##############################
# standard_modules_ref       #
##############################

use Data::Dumper;
use CGI qw(:standard);
use DBI;
use GD;
use strict;
use RGTools::RGIO;
use SDB::HTML;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;

##############################
# global_vars                #
##############################
use vars qw($URL_temp_dir);

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

sub new {
    my $this = shift;

    my %args = @_;                                         ## allow input options
    my $path = $args{-path} || "$URL_temp_dir/" || './';

    my ($class) = ref($this) || $this;
    my ($self) = {};
    $self->{pathname}       = $path;
    $self->{filename}       = "Hist.png";
    $self->{image_height}   = 0;
    $self->{image_width}    = 0;
    $self->{bins}           = [];
    $self->{number_of_bins} = 0;
    $self->{colours}        = 11;
    $self->{group_bins}     = 1;
    $self->{bin_width}      = 10;
    $self->{min}            = 0;
    $self->{max}            = 0;
    $self->{Colour}         = [];
    $self->{x_scale}        = $self->{bin_width};
    $self->{y_scale}        = 1;
    $self->{x_axis_ticks}   = [];
    $self->{x_axis_labels}  = [];
    $self->{y_axis_ticks}   = [];
    $self->{y_axis_labels}  = [];
    $self->{x_axis_title}   = '';
    $self->{y_axis_title}   = '';
    $self->{x_offset}       = 0;
    $self->{y_offset}       = 0;

    $self->{Yline} = ();
    $self->{Xline} = ();

    #
    # Define the colours for the histogram bins
    #
    # Default Colours...
    #
    #    $self->{Red}   = [255,240,240,250,160, 80,  0,  0,163,200,255];  ### matches Views.pm without black,grey at beginning..
    #    $self->{Green} = [  0,100,159,255,240,232,230,134,  0, 50,255];
    #    $self->{Blue}  = [  0,  0,  0,  0,  0,  0,230,234,247,255,255];

    $self->{Red}   = [ 255, 240, 240, 250, 160, 80,  0,   0,   163, 200, 197, 202, 177 ];    ### matches Views.pm without black,grey at beginning..
    $self->{Green} = [ 0,   100, 159, 255, 240, 232, 230, 134, 0,   50,  49,  93,  115 ];
    $self->{Blue}  = [ 0,   0,   0,   0,   0,   0,   230, 234, 247, 255, 182, 162, 149 ];

    $self->{max_colour} = 13;
    $self->{border}     = 0;

    bless $self, $class;
    $self->Set_Background( 150, 150, 150 );                                                  ## initialize default background colours
    return $self;
}

##############################
# public_methods             #
##############################

#################
sub Border {
#################
    my $self          = shift;
    my $border_colour = shift;

    $self->{border} = $border_colour;
    return;
}

#######################
sub Get_Colours {
####################### Get Histogram colours... ############################
    my $self = shift;

    my $colours = $self->{colours};
    my @red     = ();
    my @green   = ();
    my @blue    = ();

    foreach my $colour_index ( 1 .. $colours ) {
        $red[ $colour_index - 1 ]   = sprintf "%2x", int( $self->{Red}[ $colour_index - 1 ] );
        $green[ $colour_index - 1 ] = sprintf "%2x", int( $self->{Green}[ $colour_index - 1 ] );
        $blue[ $colour_index - 1 ]  = sprintf "%2x", int( $self->{Blue}[ $colour_index - 1 ] );
        $self->{BinColours}[ $colour_index - 1 ] = $red[ $colour_index - 1 ];
        $self->{BinColours}[ $colour_index - 1 ] .= $green[ $colour_index - 1 ];
        $self->{BinColours}[ $colour_index - 1 ] .= $blue[ $colour_index - 1 ];
        $self->{BinColours}[ $colour_index - 1 ] =~ s/\s/0/g;
    }
    return 1;
}

#######################
sub Set_Background {
#######################
    my $self = shift;

    my $red   = shift;
    my $green = shift;
    my $blue  = shift;

    $self->{bkgd}{Red}   = $red;
    $self->{bkgd}{Green} = $green;
    $self->{bkgd}{Blue}  = $blue;

    return;
}

#######################
sub Set_Colour {
####################### Set Histogram colours... ############################
    my $self = shift;

    $self->{colours} = 1;
    my $colour = shift;

    if ( $colour =~ /black/i ) {
        $self->{Static_Colour}{Red}   = 0;
        $self->{Static_Colour}{Green} = 0;
        $self->{Static_Colour}{Blue}  = 0;
    }

    return 1;
}

#####################
sub Set_Shades {
#####################
    my $self      = shift;
    my %args      = @_;
    my $shade_ref = $args{-shades};
    my $min       = $args{-min} || 5;
    my $max       = $args{-max} || 250;
    my $scale     = $args{-scale};
    my $invert    = $args{-invert};             ## invert black and white (so that large numbers show up dark).
    my $colour    = $args{-colour} || 'blue';

    my @shades = @$shade_ref;
    if ( $scale =~ /auto/i ) {
        my $max_shade = 0;
        map { $max_shade = $_ if ( $_ > $max_shade ); } @shades;
        $scale = $max / $max_shade;
    }

    map {
        my $shade = $_;
        $shade = int( $shade * $scale ) if $scale;
        if    ( $shade < $min ) { $shade = $min }
        elsif ( $shade > $max ) { $shade = $max }

        if ($invert) { $shade = 255 - $shade; }    # invert colour
        $_ = $shade;
    } @shades;

    $self->{Red}   = \@shades;
    $self->{Green} = \@shades;
    $self->{Blue}  = \@shades;

    $self->{custom_colours} = 1;

    my @clear = @shades;
    map { $_ = 0; } @clear;

    $self->{colours}    = int(@shades);
    $self->{max_colour} = int(@shades);
    return @shades;
}

#
# Define an array of the bin values.
#
#################
sub Set_Bins {
#################
    my $self      = shift;
    my $bin_list  = shift;
    my $bin_width = shift;

    if ( $bin_width > 0 ) {
        $self->{bin_width} = $bin_width;
        $self->{x_scale}   = $bin_width;    ### the same thing...
    }

    my @bins  = @$bin_list;
    my $index = 0;
    foreach my $thisbin (@bins) {
        $self->{bins}[ $index++ ] = $thisbin;
    }
    $self->{number_of_bins} = $index;

    return 1;
}

#################
sub Set_X_Axis {
#################
    my $self         = shift;
    my $x_axis_title = shift;
    my $indexes      = shift;
    my $labels       = shift;

    $self->{x_axis_title} = $x_axis_title;
    if ($indexes) {
        my @tick_points = @$indexes;
        $self->{x_axis_ticks} = \@tick_points;
        if ($labels) {
            my @tick_labels = @$labels;
            $self->{x_axis_labels} = \@tick_labels;
        }
        else {
            $self->{x_axis_labels} = \@tick_points;
        }
    }

    return 1;
}

#################
sub Set_Y_Axis {
#################
    my $self         = shift;
    my $y_axis_title = shift;
    my $indexes      = shift;
    my $labels       = shift;

    $self->{y_axis_title} = $y_axis_title;
    if ($indexes) {
        my @tick_points = @$indexes;
        $self->{y_axis_ticks} = \@tick_points;
        if ($labels) {
            my @tick_labels = @$labels;
            $self->{y_axis_labels} = \@tick_labels;
        }
        else {
            $self->{y_axis_labels} = \@tick_points;
        }
    }
    return 1;
}

###########################
sub Number_of_Colours {
###########################

    my $self    = shift;
    my $colours = shift;

    if ( $colours > $self->{max_colour} ) { $colours = $self->{max_colour}; }
    $self->{colours} = $colours;
    return 1;
}

########################
sub Group_Colours {
########################

    my $self = shift;
    $self->{group_bins} = shift;
    return 1;
}

#####################
sub Set_Height {
#####################
    my $self = shift;
    $self->{image_height} = shift;
    return 1;
}

###################
sub Set_Path {
###################
    my $self = shift;
    $self->{pathname} = shift;
    return 1;
}

########################
sub HorizontalLine {
########################
    #
    # add horizontal line at specified y position
    #
    #
    my $self  = shift;
    my $yline = shift;

    push( @{ $self->{Yline} }, $yline );
    return 1;
}

########################
#
# This routine generates a simple histogram
#
# Return: (x,y) size - or 0 on error.
#################
sub DrawIt {
#################
    my $self = shift;
    my $file = shift || $self->{filename};
    my %args = @_;

    my $image_height = Extract_Values( [ $args{height}, $self->{image_height} ] );
    my $image_width  = Extract_Values( [ $args{width},  $self->{image_width} ] );
    my $y_scale      = Extract_Values( [ $args{yscale}, $self->{y_scale} ] );
    my $x_scale      = Extract_Values( [ $args{xscale}, $self->{x_scale} ] );
    my $image_format = $args{image_format} || 'png';
    my $visible_zero = $args{-visible_zero};

    my $filename = "$self->{pathname}/$file";    #### name of png file to create
    #print "what's filename inside drawit (path: $self->{pathname} + file: $file - $filename\n";

    #    $height ||= $self->{image_height};      #### height of image (optional))
    #    $image_width ||= $self->{image_width};      #### height of image (optional))

    my $max = Extract_Values( [ $args{max}, $self->{max} ] );    #### maximum value (optional)
    my $min = Extract_Values( [ $args{min}, $self->{min} ] );

    my @bars    = @{ $self->{bins} };
    my $colours = $args{colours} || $self->{colours};            #### array of colours for each bar
    my $group   = $self->{group_bins};
    my $border  = $self->{border};

    my @matrix;

    #    if ($colours>10) {$colours=10;}          ## only 10 colours defined...

    my $number_of_bars = scalar(@bars);

########### Set maximum value #############
    my $max_value = 0;
    my $min_value = $bars[0];
    foreach my $bar (@bars) {
        if ( $bar > $max_value ) { $max_value = $bar; }    # find highest bar...
        if ( $bar < $min_value ) { $min_value = $bar; }    # find lowest bar...
    }

    ########## if maximum not set, set to 10% above maximum #############
    unless ($max) {
        $max = $max_value * 1.1;
    }
    if ( $max == 0 ) { return ( 0, 0 ); }

########## Set Y axis scale ###############

    my $x_offset = 0;
    my $y_offset = 0;

    if ( $self->{x_axis_title} )            { $y_offset += 15; }
    if ( $self->{y_axis_title} )            { $x_offset += 15; }
    if ( defined $self->{x_axis_ticks}[0] ) { $y_offset += 15; }
    if ( defined $self->{y_axis_ticks}[0] ) { $x_offset += 15; }

    if ($image_height) {
        $y_scale = ( $image_height - $y_offset ) / $max;
    }
    else {
        $y_scale ||= 1;
        $image_height = int( $max * $y_scale ) + $y_offset;
    }

    $x_scale ||= $self->{bin_width};
    if ( $x_scale < 2 ) { $x_scale = 2 }    ### minimum number of pixels per bin to allow filling..
    unless ( $image_width > $x_offset + $x_scale * $number_of_bars + 1 ) {
        $image_width = $x_offset + $x_scale * $number_of_bars + 1;
    }

    my $bin_width = $x_scale;

    my $req_image_width = $bin_width * scalar(@bars) + $border + $x_offset;
    if ( !$image_width || ( $image_width < $req_image_width ) ) { $image_width = $req_image_width; }
    ############# Draw the Histogram... ##################
    # create a new image

    my $x = $image_width;
    my $y = $image_height;

    my $im = new GD::Image( $x, $y );

################ Default Colours #########################
############# Set up the colour map colours... ##################
    #   &Get_Colours($self,$im);
    #  $self->{Colour}[0] = $im->colorAllocate(250,0,0);      # red
    #  $self->{Colour}[1] = $im->colorAllocate(240,100,0);    # orange
    #  $self->{Colour}[2] = $im->colorAllocate(240,159,0);    # mustard
    #  $self->{Colour}[3] = $im->colorAllocate(250,255,0);    # yellow
    #  $self->{Colour}[4] = $im->colorAllocate(160,240,0);    # lime
    #  $self->{Colour}[5] = $im->colorAllocate(80,232,0);      # green
    #  $self->{Colour}[6] = $im->colorAllocate(0,230,230);      # cyan
    #  $self->{Colour}[7] = $im->colorAllocate(0,134,234);      # blue
    #  $self->{Colour}[8] = $im->colorAllocate(163,0,247);   # purple
    #  $self->{Colour}[9] = $im->colorAllocate(100,100,100);  # gray

    foreach my $colour ( 1 .. $self->{max_colour} ) {
        my $index = $colour - 1;
        if ( $self->{Static_Colour} ) {
            $self->{Colour}[$index] = $im->colorAllocate( $self->{Static_Colour}{Red}, $self->{Static_Colour}{Green}, $self->{Static_Colour}{Blue} );
        }
        else {
            $self->{Colour}[$index] = $im->colorAllocate( $self->{Red}[$index], $self->{Green}[$index], $self->{Blue}[$index] );
        }
    }

    my $black      = $im->colorAllocate( 0,                  0,                    0 );
    my $white      = $im->colorAllocate( 255,                255,                  255 );
    my $background = $im->colorAllocate( $self->{bkgd}{Red}, $self->{bkgd}{Green}, $self->{bkgd}{Blue} );
    ############### make the background transparent and interlaced
    $im->transparent();
    $im->interlaced('true');

    $im->fill( 1, 1, $background );

    my $border_colour = $black;    ## black border

    my $bin_num = 0;
    my $clr_num = 0;               ### start at red...

    my $clr_inc = 1;
    unless ( $self->{custom_colours} ) {
        if    ( $colours < 4 ) { $clr_inc = 3; }
        elsif ( $colours < 6 ) { $clr_inc = 2; }
    }
    my $num_of_group = 0;          ###### count number in colour group...

    #### Add text/axis labels... #####

    ### Axes ...###
    my $x_end = $image_width;
    my $y_end = $image_height;

    $im->rectangle( $x_offset, $y_end - $y_offset, $x_end, 0, $border_colour );
    $im->fill( $x_offset + 1, 1, $background );

    my $y_axis = $y_end - $y_offset;

    $im->line( $x_offset, $y_axis, $x_end, $y_axis, $black );    # x-axis

    if ( $self->{x_axis_title} =~ /\S/ ) {
        my $title_position = $image_height - 15;

        #	if (defined $self->{x_axis_ticks}[0]) {$title_position += 10; }
        $im->string( gdSmallFont, $x_offset + 5, $title_position, $self->{x_axis_title}, $black );    # axis label
    }
    $im->line( $x_offset, 0, $x_offset, $y_axis, $black );                                            # y-axis
    if ( $self->{y_axis_title} =~ /\S/ ) {
        my $title_position = 0;
        $im->stringUp( gdSmallFont, $title_position, $y_axis, $self->{y_axis_title}, $black );
    }

    # tick marks (extend 3 pixels on either side of the axis)
    my @x_ticks  = @{ $self->{x_axis_ticks} };
    my @x_labels = @{ $self->{x_axis_labels} };

    if (@x_ticks) {
        foreach my $index ( 0 .. $#x_ticks ) {
            my $tick     = $x_ticks[$index];
            my $label    = $x_labels[$index];
            my $tick_pos = $tick * $x_scale + $x_offset;
            $im->line( $tick_pos, $y_axis, $tick_pos, $y_axis + 3, $black );
            my $length = length($label);
            $im->string( gdSmallFont, $tick_pos - $length * 5 / 2, $y_axis + 5, $label, $black );
        }
    }

    my @y_ticks  = @{ $self->{y_axis_ticks} };
    my @y_labels = @{ $self->{y_axis_labels} };

    if (@y_ticks) {
        foreach my $index ( 0 .. $#y_ticks ) {
            my $tick  = $y_ticks[$index];
            my $label = $y_labels[$index];

            my $tick_pos = $y_axis - $tick * $y_scale;
            $im->line( $x_offset - 3, $tick_pos, $x_offset, $tick_pos, $black );
            my $length = length($label);
            $im->stringUp( gdSmallFont, $x_offset - 15, $tick_pos + $length * 5 / 2, $label, $black );
        }
    }

    my @colours      = @{ $self->{Colour} };
    my $colour_index = 0;
    foreach my $bar (@bars) {
        my $x_origin = $bin_num * $bin_width + $x_offset;
        my $y_origin = $y_axis;
        if   ($border) { $border_colour = $black; }
        else           { $border_colour = $self->{Colour}[$clr_num]; }

        my $bin_height = int( $bars[$bin_num] * $y_scale );
        $bin_height ||= 1 if $visible_zero;    ## ensure that even 0 sized bins are visible (provide height of 1 pixel) ##
        if ( $bin_height > 0 ) {
            $im->rectangle( $x_origin, $y_origin, $x_origin + $bin_width - 1, $y_origin - $bin_height, $border_colour );
            $im->fill( $x_origin + 1, $y_origin - 1, $self->{Colour}[$clr_num] );
        }
        $bin_num++;

        $num_of_group++;
        if ( $num_of_group >= $group ) {
            $num_of_group = 0;
            $clr_num += $clr_inc;              ### go to next colour...
            $colour_index++;
            if    ( $colour_index >= $colours )      { $colour_index = 0; $clr_num = 0; }    ### rotate to first colour
            elsif ( $clr_num > $self->{max_colour} ) { $colour_index = 0; $clr_num = 0; }    ### rotate to first colour
        }
    }

    foreach my $yline ( @{ $self->{Yline} } ) {                                              ### include optional horizontal line requests to be included...
        my $ypos = $y_axis - $yline * $y_scale;

        #
        #  The dotted lines do NOT work for the older version of GD (web03)
        $im->setStyle( $black, $black, $black, gdTransparent, gdTransparent, gdTransparent );

        #	$im->line($x_offset, $ypos, $image_width, $ypos, $black);
        $im->line( $x_offset, $ypos, $image_width, $ypos, gdStyled );
    }

    binmode STDOUT;
    if ($filename) {

        open( IMAGE, ">$filename" ) or return err ("Cannot open $filename");

        # Convert the image to out and print it on standard output
        print IMAGE $im->$image_format;
        close(IMAGE) or return err ('problem closing file');
    }
    else {
        $im->$image_format;
    }
    return ( $y_scale, $max_value );
}

########################
sub DrawLine {
########################
    #
    # This routine generates a simple histogram
    #
    my $self         = shift;
    my $file         = shift || $self->{filename};
    my $max          = Extract_Values( [ shift, $self->{max} ] );
    my $height       = shift;
    my $image_format = shift || 'png';
    $height ||= $self->{image_height};    #### height of image (optional))

    my $filename = $self->{pathname} . $file;    #### name of png file to create
    my $width    = $self->{bin_width};           #### width of the bars (x 5 pixels)
    my $min      = $self->{min};
    my @bars     = @{ $self->{bins} };
    my $colours  = $self->{colours};             #### array of colours for each bar
    my $group    = $self->{group_bins};
    my $border   = $self->{border};

    my @matrix;
    if ( $colours > 10 ) { $colours = 10; }      ## only 10 colours defined...

    my $number_of_bars = scalar(@bars);

########### Set maximum value #############
    my $max_value = 0;
    my $min_value = $bars[0];
    foreach my $bar (@bars) {
        if ( $bar > $max_value ) { $max_value = $bar; }    # find highest bar...
        if ( $bar < $min_value ) { $min_value = $bar; }    # find lowest bar...
    }

    ########## if maximum not set, set to 10% above maximum #############
    unless ($max) {
        $max = $max_value * 1.1;
    }
    if ( $max == 0 ) { return ( 0, 0 ); }

########## Set Y axis scale ###############

    my $scale = $colours / $max;

    ############# Draw the Histogram... ##################
    # create a new image
    my $x  = $width * scalar(@bars) + $border;
    my $y  = $height;
    my $im = new GD::Image( $x, $y );
################ Default Colours #########################
############# Set up the colour map colours... ##################
    #    &Get_Colours($self,$im);

    #    $self->{Colour}[0] = $im->colorAllocate(0,0,0);      # black
    #    $self->{Colour}[1] = $im->colorAllocate(250,0,0);      # red
    #    $self->{Colour}[2] = $im->colorAllocate(240,100,0);    # orange
    #    $self->{Colour}[3] = $im->colorAllocate(240,159,0);    # mustard
    #    $self->{Colour}[4] = $im->colorAllocate(250,255,0);    # yellow
    #    $self->{Colour}[5] = $im->colorAllocate(160,240,0);    # lime
    #    $self->{Colour}[6] = $im->colorAllocate(80,232,0);      # green
    #    $self->{Colour}[7] = $im->colorAllocate(0,230,230);      # cyan
    #    $self->{Colour}[8] = $im->colorAllocate(0,134,234);      # blue
    #    $self->{Colour}[9] = $im->colorAllocate(163,0,247);   # purple
    #    $self->{Colour}[10] = $im->colorAllocate(100,100,100);  # gray

    foreach my $colour ( 1 .. $colours ) {
        my $index = $colour - 1;
        $self->{Colour}[$index] = $im->colorAllocate( $self->{Red}[$index], $self->{Green}[$index], $self->{Blue}[$index] );
    }

    my $black      = $im->colorAllocate( 0,                  0,                    0 );
    my $white      = $im->colorAllocate( 255,                255,                  255 );
    my $background = $im->colorAllocate( $self->{bkgd}{Red}, $self->{bkgd}{Green}, $self->{bkgd}{Blue} );
    ############### make the background transparent and interlaced
    $im->transparent();
    $im->interlaced('true');

    my $border_colour = $black;    ## black border

    my $bin_num = 0;
    my $clr_num = 0;               ### start at red...

    my $clr_inc = 1;
    if    ( $colours < 4 ) { $clr_inc = 3; }
    elsif ( $colours < 6 ) { $clr_inc = 2; }
    my $num_of_group = 0;          ###### count number in colour group...

    foreach my $bar (@bars) {
        my $x_origin = $bin_num * $width;
        my $y_origin = 0;
        my $clr_num  = int( $bars[$bin_num] * $scale );
        if   ( $clr_num >= $colours ) { $clr_num       = $colours - 1; }                ### max
        if   ($border)                { $border_colour = $black; }
        else                          { $border_colour = $self->{Colour}[$clr_num]; }

        $im->rectangle( $x_origin, $y, $x_origin + $width - 1, $y - $height, $border_colour );
        if ( $width > 2 ) { $im->fill( $x_origin + 1, $y - 1, $self->{Colour}[$clr_num] ); }
        $bin_num++;
    }

    binmode STDOUT;
    if ($filename) {
        open( IMAGE, ">$filename" ) or warn "Can't open";

        # Convert the image to output and print it on standard output
        print IMAGE $im->$image_format;
        close(IMAGE) or warn "problem closing";
    }
    else {
        $im->$image_format;
    }
    return ( $scale, $max_value );
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

$Id: Histogram.pm,v 1.22 2004/11/30 01:43:42 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
