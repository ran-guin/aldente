################################################################################
#
# HTML.pm
#
# HTML: Misc HTML specific tools
#
################################################################################
# $Id: HTML.pm,v 1.5 2004/11/30 01:43:42 rguin Exp $
################################################################################
package SDB::GD_Tools;

use RGTools::RGIO;

use GD;

###############################################################################
# Draw out the pipeline accodring to the formatted information
# Each Pipeline structure is contained in a hash with the Pipeline as the Key
# <snip>
# Example:
#      my @test = ({ID=>1,Display=>'Protocol 1', Gen=>1, Action=>'',Parents=>[]},
#		{ID=>2,Display=>'Protocol 2', Gen=>2, Action=>'',Parents=>[1]},
#		{ID=>4,Display=>'Protocol 4', Gen=>2, Action=>'',Parents=>[1]},
#		{ID=>5,Display=>'Protocol 5', Gen=>2, Action=>'',Parents=>[1]},
#		{ID=>3,Display=>'Protocol 3', Gen=>3, Action=>'',Parents=>[2,4,5]},
#		{ID=>6,Display=>'Protocol 6', Gen=>4, Action=>'',Parents=>[3]}
#		);
#  &SDB::HTML::draw_lineage(-dbc=>$dbc,-lineage=>\@test,-form=>$form, -title=>'Test Generic',-file=>'Test', -file_path=>$URL_temp_dir,-action_type=>'POST');
# </snip>
# Return 1 on success
#####################
sub draw_lineage {
#####################
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $lineage = $args{-lineage};                                  ##  hash of
    my @lineage = Cast_List( -list => $lineage, -to => 'Array' );

    my $file      = $args{-file};                                   # file name
    my $file_path = $args{-file_path};                              # directory path

    my $full_path = $file_path . "/" . $file;

    my $max_gen = $args{-max_gen} || 4;                             # maximum number of generations

    my $title = $args{-title};                                      ## title of the diagram

    my $form_action      = $args{-form_action};                     ## custom action that clicking on the links will give you
    my $form_action_type = $args{-action_type};                     ## GET OR POST
    my $no_action        = $args{-no_action};                       ## indicate no action
    my $highlight        = $args{-highlight};                       ## Highlight a box
    my $print            = $args{ -print };
    my $subdir           = $args{-sub_directory} || 'tmp';

    my $CHAR_LENGTH      = 6.5;                                     # Width of a character in GD
    my $MAX_DISPLAY_CHAR = 20;                                      # Maximum displayable characters for a procedure
    my $WHITESPACE       = 170;                                     # space between procedures

    my $full_file = "$file.PNG";

    my $URL_temp_dir = $dbc->config('URL_temp_dir');
    my $filename  = "$URL_temp_dir/$full_file";                     #### name of png file to create

    ## Calculate the image height and image width<CONSTRUCTION>
    my $height = 120;

    eval "require GD";
    my $width        = $max_gen * $WHITESPACE;
    my $im           = new GD::Image( $width, $height );
    my $image_format = $args{-image_format} || 'png';

    ##### COLOURS
    my $background    = $im->colorAllocate( 240, 240, 240 );
    my $boxbackground = $im->colorAllocate( 200, 200, 255 );
    my $black         = $im->colorAllocate( 0,   0,   0 );
    my $white         = $im->colorAllocate( 255, 255, 255 );
    my $blue          = $im->colorAllocate( 0,   0,   255 );
    my $red           = $im->colorAllocate( 255, 0,   0 );
    my $highlight_color = $red;

    $im->transparent($white);
    $im->interlaced('true');

    $im->fill( 1, 1, $background );
    ## Draw the title of the pipeline
    #$im->string(gdLargeFont, ($width-(length($title)*$CHAR_LENGTH))/2,0, $title, $black);
    $im->string( gdLargeFont, 0, 0, $title, $red );
    $im->string( gdSmallFont, 0, 18, "(Click on pipeline step you wish to view)", $black ) if ( !$no_action );

    my %ordered_list;
    ## find the Order of procedures for the pipeline
    foreach my $val (@lineage) {
        $ordered_list{ $val->{Gen} }++;
    }
    my $i           = 1;
    my $value_index = 0;

    my $image_x = 5;
    my $image_y = 0;
    ## Start IMAGE MAP

    my $output;

    #print "<map name='$file'>";
    $output .= "<map name='$file'>";
    ## keep the end coordinates for drawing lines between the parents and childs

    my %coords;

    while ( defined $ordered_list{$i} ) {

        $image_y = ( $height / $ordered_list{$i} ) / 2;

        for ( my $x = 0; $x < $ordered_list{$i}; $x++ ) {
            my $val         = $lineage[$value_index];
            my $actual_name = $val->{Display};
            my $current_id  = $val->{ID};
            my $text_width  = $CHAR_LENGTH * length($actual_name);
            my $display_name;
            if ( length($actual_name) > $MAX_DISPLAY_CHAR ) {
                $display_name = substr( $actual_name, 0, $MAX_DISPLAY_CHAR );
            }
            else {
                $display_name = $actual_name;
            }
            $im->string( gdSmallFont, $image_x + 5, $image_y, $display_name, $black );
            $value_index++;
            my $x2 = $image_x + $MAX_DISPLAY_CHAR * $CHAR_LENGTH;
            my $y2 = $image_y + 20;

            $coords{ $val->{ID} } = [ $x2, $y2 - 10 ];
            if ( $current_id == $highlight ) {
                $im->filledRectangle( $image_x, $image_y, $x2, $y2, $boxbackground );
                $im->rectangle( $image_x - 1, $image_y - 1, $x2 + 1, $y2 + 1, $highlight_color );
                $im->rectangle( $image_x, $image_y, $x2, $y2, $highlight_color );
            }
            else {
                $im->filledRectangle( $image_x, $image_y, $x2, $y2, $boxbackground );
                $im->rectangle( $image_x, $image_y, $x2, $y2, $black );
            }
            $im->string( gdSmallFont, $image_x + 5, $image_y + 3, $display_name, $black );
            ## Create an area map for hotlinks to the drill down for the procedure
            my $action = $val->{Action};
            if ( !$no_action ) {
                if ( $form_action_type =~ /POST/i ) {

                    #print Show_Tool_Tip("<area shape='rect'  value= '$val->{Display}' href='' coords='$image_x,$image_y,$x2,$y2' onclick=\"$action\">","$actual_name");
                    $output .= Show_Tool_Tip( "<area shape='rect'  value= '$val->{Display}' href='' coords='$image_x,$image_y,$x2,$y2' onclick=\"$action\">", $actual_name );
                }
                else {    ## GET
                          #	print Show_Tool_Tip("<area shape='rect'  value= '$val->{Display}' href='$action' coords='$image_x,$image_y,$x2,$y2' >","$actual_name");
                    $output .= Show_Tool_Tip( "<area shape='rect'  value= '$val->{Display}' href='$action' coords='$image_x,$image_y,$x2,$y2' >", $actual_name );
                }
            }
            ## check for parents
            my @parents = @{ $val->{Parents} } if $val->{Parents};
            if (@parents) {
                foreach my $parent (@parents) {
                    my $parent_x = $coords{$parent}[0];
                    my $parent_y = $coords{$parent}[1];
                    ## draw a line from the parents to the child
                    $im->line( $parent_x, $parent_y, $image_x, $image_y + 10, $black );
                }
            }
            $image_y += ( $height / $ordered_list{$i} );
        }

        $image_x += $WHITESPACE;
        $i++;
    }

    #print "</map>";
    $output .= "</map>" . '<BR>';
    if ($filename) {
        my $IMAGE;
        open $IMAGE, '>', $filename or warn "Can't open $filename";

        # Convert the image to out and print it on standard output
        binmode $IMAGE;
        print $IMAGE $im->$image_format;
        close($IMAGE) or warn "problem closing";
    }

    #print "<img border = 0 src='/dynamic/$subdir/$full_file' usemap='#$file'><br>";

    $output .= "<img border = 0 src='/dynamic/$subdir/$full_file' usemap='#$file'><br>";
    if ($print) {
        print $output;
        return 1;
    }
    else { return $output; }

}

1;