################################################################################
# Views.pm
#
# This facilitates automatic viewing in HTML view..
#
################################################################################
################################################################################
# $Id: Views.pm,v 1.22 2004/10/08 00:21:40 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.22 $
#     CVS Date: $Date: 2004/10/08 00:21:40 $
################################################################################
package Views;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Views.pm - This facilitates automatic viewing in HTML view..

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This facilitates automatic viewing in HTML view..<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
#require Exporter;
#@EXPORT = qw(
#	     Draw_Map
#	     Mini_Histogram
#	     html_highlight
#	     Heading
#	     sub_Heading
#	     small_type
#	     Print_Page
#	     filter_header
#	     Table_Print
#	     );
#@EXPORT_OK = qw(
#		Table_Print
#		);

##############################
# standard_modules_ref       #
##############################

use RGTools::RGIO;

use CGI qw(:standard);
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

sub Draw_Map {
    ###################
    #
    # Draw 'traffic light' map ($rows x $cols).
    # Save as $filename;
    # (specify $border, size of each element...)
    #
    # if very small prints elements as squares - otherwise circles...
    #

    my $filename = shift;
    my $rows     = shift;
    my $cols     = shift;
    my $matrix   = shift;

    my $each = ( defined $_[0] ) ? $_[0] : 5;    ### size of each element of matrix in image
    my $border = shift;

    my @elements = @$matrix;

    ##### Determine imaga and bin size
    my $max = 1000;
    my $div = 100;

    my $shape;
    if   ( $each > 10 ) { $shape = 'circle'; }
    else                { $shape = 'square'; }

    $rows ||= scalar(@elements);

    my @col = @{ $elements[0] };
    $cols ||= scalar(@col);

    my $x = $cols * $each;
    my $y = $rows * $each;

    require GD;
    
    # create a new image
    my $im = new GD::Image( $x, $y );

    # allocate some colors
    my $black = $im->colorAllocate( 0,   0,   0 );
    my $white = $im->colorAllocate( 255, 255, 255 );
    my $grey  = $im->colorAllocate( 100, 100, 100 );

    #my $NG = $im->colorAllocate(255,255,255);
    # NGs are black as well
    my $NG = $im->colorAllocate( 0, 0, 0 );

    # will never have slow grows assigned (Post.pm ignores slow grow flag)
    my $SG = $im->colorAllocate( 255, 200, 200 );
    my @colour;

    ############# Set up the colour map colours... ##################
    my $Colour = {};
    $Colour->{Red}   = [ 0, 100, 255, 240, 240, 250, 160, 80,  0,   0,   163, 200, 255 ];    ### matches Histogram.pm + black,grey at beginning..
    $Colour->{Green} = [ 0, 100, 0,   100, 159, 255, 240, 232, 230, 134, 0,   50,  255 ];
    $Colour->{Blue}  = [ 0, 100, 0,   0,   0,   0,   0,   0,   230, 234, 247, 255, 255 ];

    my $colours = int( @{ $Colour->{Red} } );
    foreach my $colour ( 1 .. $colours ) {
        my $index = $colour - 1;
        $colour[$index] = $im->colorAllocate( $Colour->{Red}[$index], $Colour->{Green}[$index], $Colour->{Blue}[$index] );
    }

    #    $colour[0] = $im->colorAllocate(0,0,0);        # black
    #    $colour[1] = $im->colorAllocate(100,100,100);  # gray
    #    $colour[2] = $im->colorAllocate(250,0,0);      # red
    #    $colour[3] = $im->colorAllocate(240,100,0);    # orange
    #    $colour[4] = $im->colorAllocate(240,159,0);    # mustard
    #    $colour[5] = $im->colorAllocate(250,255,0);    # yellow
    #    $colour[6] = $im->colorAllocate(160,240,0);    # lime
    #    $colour[7] = $im->colorAllocate(80,232,0);      # green
    #    $colour[8] = $im->colorAllocate(0,230,230);      # cyan
    #    $colour[9] = $im->colorAllocate(0,134,234);      # blue
    #    $colour[10] = $im->colorAllocate(163,0,247);   # purple

    my $divs = 12;

    # make the background transparent and interlaced
    $im->transparent($white);
    $im->interlaced('true');

    my $stop = 0;
    foreach my $row ( 1 .. $rows ) {
        foreach my $col ( 1 .. $cols ) {
            my $element = $elements[ $row - 1 ][ $col - 1 ];
            my $pixel_colour;
            if    ( $element < -1 ) { $pixel_colour = $NG; }    ### No Grow
            elsif ( $element < 0 )  { $pixel_colour = $SG; }    ## Slow Grow
            elsif ( int( $element / $div ) > $divs ) {
                $pixel_colour = $colour[$divs];
            }
            elsif ( !defined $element ) { $pixel_colour = $black; }
            elsif ( $element =~ /NULL/ ) { $pixel_colour = $black; }
            elsif ( !$element ) { $pixel_colour = $grey; }      ### blac ?
            else {
                $pixel_colour = $colour[ int( $element / $div ) + 2 ];
            }
            my $border_colour;
            if   ($border) { $border_colour = $black; }
            else           { $border_colour = $pixel_colour; }

            my $x_origin = ( $col - 1 ) * $each;
            my $y_origin = ( $row - 1 ) * $each;

            if ( $shape =~ /circle/i ) {
                my $offset = int( $each / 2 );
                $im->arc( ( $col - 1 ) * $each + $offset, ( $row - 1 ) * $each + $offset, $each - 2, $each - 2, 0, 360, $pixel_colour );
                $im->fill( ( $col - 1 ) * $each + $offset, ( $row - 1 ) * $each + $offset, $pixel_colour );
            }
            else {
                $im->rectangle( $x_origin, $y_origin, $x_origin + $each - 1, $y_origin + $each - 1, $border_colour );
                if ( $each > 2 ) {
                    $im->rectangle( $x_origin + 1, $y_origin + 1, $x_origin + $each - 2, $y_origin + $each - 2, $pixel_colour );
                    $im->fill( $x_origin + 2, $y_origin + 2, $pixel_colour );
                }
            }
        }
    }
    binmode STDOUT;
    if ($filename) {
        open( PNGIMAGE, ">$filename" ) or warn "Can't open $filename";

        # Convert the image to PNG and print it on standard output
        print PNGIMAGE $im->png;
        close(PNGIMAGE) or warn "problem closing";
    }
    else {
        $im->png;
    }
    return ( $rows, $cols );
}

#############
sub html_highlight {
#############
    my $text = shift;
    my $colour = shift || 'red';

    return "<B><Font color=$colour>$text</Font></B>";
}

#################
sub Heading {
#################
    #
    # Print heading in html format
    #
    my $text = shift || '';

    #  my $spec = shift || "bgcolor='#999999' ";
    my $spec  = shift || "bgcolor='#BBBBBB' ";
    my $width = shift || '100%';
    my $align = shift || '';

    if ($align) { $spec .= " align=$align "; }

    my $padding  = ( defined $_[0] ) ? $_[0] : 4;
    my $spacing  = shift;
    my $no_new_p = shift;                           #No new paragraph after the heading.

    if ($width)             { $width   = "width=$width" }
    if ( defined $padding ) { $padding = "cellpadding=$padding" }
    if ( defined $spacing ) { $spacing = "cellspacing=$spacing" }

    my $ret_val = "<Table $width $padding $spacing>\n<tr>\n<td $spec><span class='larger'>$text</span></td>\n</tr>\n</table>";
    unless ($no_new_p) { $ret_val .= "<p>" }
    $ret_val .= "\n\n";

    return $ret_val;
}

#################
sub sub_Heading {
#################
    #
    # Print heading in html format
    #
    my $text = shift;

    my $reduce = shift || 0;
    my $spec   = shift || 'class=mediumheader';
    my $width  = shift || '100%';

    my $padding  = ( defined $_[0] ) ? $_[0] : 4;
    my $spacing  = ( defined $_[1] ) ? $_[1] : 4;
    my $no_new_p = ( defined $_[2] ) ? $_[2] : 1;
    ;    #No new paragraph after the heading.

    if ($width)             { $width   = "width=$width" }
    if ($padding)           { $padding = "cellpadding=$padding" }
    if ( defined $spacing ) { $spacing = "cellspacing=$spacing" }

    my $ret_val = "<Table $width $padding $spacing>\n<tr>\n<td $spec><Font size=-$reduce>$text</Font></td>\n</tr>\n</table>";
    unless ($no_new_p) { $ret_val .= "<p>" }
    $ret_val .= "\n\n";

    return $ret_val;
}

###################
sub small_type {
###################
    my $message = shift;
    my $bold    = shift;

    my $formatted = "<span class=small>";

    if ($bold) { $formatted .= "<B>"; }

    $formatted .= $message;
    if ($bold) { $formatted .= "</B>"; }

    $formatted .= "</Span>";

    return $formatted;
}

####################
sub Print_Page {
####################
    #
    # Allow link to quickly print out page...
    #
    my $Printout = shift;
    my $filename = shift;
    my $title    = shift;
    my $header   = shift;

    my $OUTFILE;
    my $path;
    if   ( $filename =~ /htdocs\/(.*)/ ) { $path = $1; }
    else                                 { $path = $filename; }

    if ($filename) {
        print br() . "\n<a href=\"/$path\"><B><Font Size=+1>Printout Page</Font></B></a>\n", "<I> (Note: 'RELOAD' new page before printing)</I>";
        open( OUTFILE, ">$filename" ) or print "opening $OUTFILE ($filename) Error";
        print OUTFILE start_html('Popup Window');
        print OUTFILE "\n$header";    ### insert header to html file here if desired
        print OUTFILE h1($title);
        print OUTFILE $Printout;
        print OUTFILE end_html();
        close(OUTFILE);
        return;
    }
    else { print $Printout; }
    return;
}

#####################
sub filter_header {
#####################
    #
    # Header bar for sub-sections in Search forms
    #

    my $header = shift;
    my $p;

    $p .= qq[<table border="0" cellspacing="0" cellpadding="4" width="100%">\n];
    $p .= qq[<tr>\n];
    $p .= qq[<td valign="top" class="lightgreenbw">\n<span class="small">];
    $p .= $header;
    $p .= qq[</span></td>\n];
    $p .= qq[</tr>\n];
    $p .= qq[</table>\n\n];

    return $p;
}

#
# Accessor to generate table 
# 
# Options: 
#   -column_style => 'color:red' or ['color:red', 'color:blue'] or {'1' => 'color:red', '2' => 'color:blue' }
#
# Return: HTML code for table
###########################
sub Table_Print {
###########################
    #
    # Prints contents in the webpage framed by an HTML table.
    # Say you want to print the contents '1','2','3' in the first row and '4','5' in the second row, you call the function by Print_Tables([['1','2','3'],['4','5']])
    #
    my %args = @_;

    my @contents = @{ $args{content} };

    my $padding = ( defined $args{padding} ) ? $args{padding} : 2;
    my $spacing = ( defined $args{spacing} ) ? $args{spacing} : 0;
    my $print   = ( defined $args{print} )   ? $args{print}   : 1;
    my $valign      = $args{valign} || 'Top';
    my $halign      = $args{align};
    my $width       = $args{width} || '100%';
    my $class       = $args{class};
    my $bgcolour    = $args{bgcolour};
    my $colspan     = $args{colspan};                                  # Specify the column span.  Format: %colspan->{row}->{column} = columns (e.g. %colspan->{2}->{1} = 2)
    my $rowspan     = $args{rowspan};                                  # Specify the row span.  Format: %rowspan->{row}->{column} = rows (e.g. %rowspan->{2}->{1} = 2)
    my $cell_colour = $args{cell_colour};                              # Specify the colour
    my $border      = $args{border} || 0;
    my $title     = $args{title};
    my $title_colour = $args{title_colour} || '#999999';
    my $nowrap      = ( defined $args{nowrap} ) ? $args{nowrap} : 1;
    my $align_columns = $args{-align_columns};          ## optional column alignment specification (eg -align_columns=>{1=>'right'} )
    my $column_style  = $args{-column_style};            ## optional column alignment specification (eg -align_columns=>{1=>'right'}  or column_style => 'color:red')
    my $return_html = $args{-return_html};   
    my $debug = $args{-debug};

    if ($return_html) { $print = 0 }

    my $wrap;
    if ($nowrap) { $wrap = " nowrap"; }

    my @alignment;
    if ($halign) {
        @alignment = @$halign;
    }

    my $class_on;
    my $class_off;
    if ($class) {
        $class_on  = "<span class='$class'>";
        $class_off = "</span>";
    }

    my $frame = "\n<table cellspacing='$spacing' bgcolor= '$bgcolour' cellpadding='$padding' width='$width' border=$border>\n";

    if ($title) {
	$frame .= "\t<TR bgcolor='$title_colour'><TD colspan=10><B>$title</B><HR></TD></TR>\n";
    }

    my $i = 1;
    foreach my $row (@contents) {
        $frame .= "\t<tr bgcolor='$bgcolour' valign='$valign'>\n";
        my $j = 1;
        foreach my $cell ( @{$row} ) {
            my $span = '';
            my $bgcolour;
            my $align;
            
            my $col_style;
            
            if ($column_style) {
                if (ref $column_style eq 'HASH') { $col_style = $column_style->{$j} }
                elsif (ref $column_style eq 'ARRAY') { $col_style = $column_style->[$j] }
                else { $col_style = $column_style }
            }
            if ( exists $colspan->{$i}->{$j} ) {
                $span .= " colspan='$colspan->{$i}->{$j}'";
            }
            if ( exists $rowspan->{$i}->{$j} ) {
                $span .= " rowspan='$rowspan->{$i}->{$j}'";
            }
            if ( exists $cell_colour->{$i}->{$j} ) {
                $bgcolour = " bgcolor='$cell_colour->{$i}->{$j}'";
            }
            if ( exists $alignment[ $j - 1 ] ) {
                $align = " align=$alignment[$j-1]";
            }
            elsif ( exists $alignment[0] ) { $align = " align=$alignment[0]" }
            $frame .= "\t\t<td $wrap $span $bgcolour $align style=\"$col_style\">$class_on$cell$class_off</td>\n";
            $j++;
        }
        $frame .= "\t</tr>\n";
        $i++;
    }

    $frame .= "</table>\n";

    if ($print) {
        print $frame;
    }

    return $frame;
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

2003-11-27

=head1 REVISION <UPLINK>

$Id: Views.pm,v 1.22 2004/10/08 00:21:40 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
