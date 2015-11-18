#!/usr/bin/perl
##############################################################################################################################
# Views.pm
#
# Module that displays views for sequenced plates (ABI Sanger-style sequencing)
#
##############################################################################################################################
package Sequencing::Views;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Views.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/bin/perl<BR>!/usr/local/bin/perl56<BR>!/usr/local/bin/perl56<BR>Module that displays views for sequenced plates (ABI Sanger-style sequencing)<BR>

=cut      

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use Data::Dumper;
use GD;
use Statistics::Descriptive;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Conversion;
use SDB::DBIO;
use Sequencing::Tools qw(SQL_phred);
use Sequencing::Sequence;

##############################
# global_vars                #
##############################
### Global variables
use vars qw(%Settings $User %Std_Parameters $java_bin_dir $templates_dir $bin_home);

#####################################
#
# Function to generate a capillary view of the run.
#
#####################################
sub RunPlate {
#####################################
    my %args  = &filter_input( \@_, -args => 'dbc,run_id' );
    my $dbc   = $args{-dbc};
    my $runid = $args{-run_id};                                # (Scalar) Run ID to display

    my ($plate_size) = $dbc->Table_find( "Run,Plate", "Plate_Size", "WHERE FK_Plate__ID=Plate_ID AND Run_ID = $runid" );

    # by default, this is 96-well (8 rows, 12 columns)
    my $row_size = 8;
    my $col_size = 12;

    # 384-well plates have double the number of rows and columns
    if ( $plate_size =~ /384.*well/ ) {
        $row_size = 16;
        $col_size = 24;
    }
    my $APPLET_HEIGHT = 300;
    my $APPLET_WIDTH  = 500;
    my $reads         = $row_size * $col_size;
    my $rowheight     = 7;                       # Height of each read in the image
    my $n_bp          = 1200;                    # Width of the image - each bp is 1 pixel.
    my $topmargin     = 85;
    my $leftmargin    = 40;
    my $rightmargin   = 60;
    my @color_qual;
    my @color_vec;
    my @color_gen;
    my $im = new GD::Image( $n_bp / 2 + $leftmargin + $rightmargin, $reads * $rowheight + $topmargin );

    my $qual;
    my ( @rgb, $hue, $tone_f, $tone_r );

    # Allocate the colours for the image
    my $maxqual   = 70;
    my $qualstep  = 2;
    my $qualshift = 10;
    my $maxhue    = 300;
    for ( $qual = 0; $qual <= $maxqual; $qual += $qualstep ) {
        $hue = int( $maxhue * ( $qual - $qualshift ) / ( $maxqual - $qualshift ) );    # Maps $qual onto 0-300 (red-blue)
        if ( $hue < 0 ) { $hue = 0 }

        #      $tone_f = int(255*($hue%60)/60);      # Maps $qual onto 0-255 linearly (forward)
        $tone_f = int( 255 * ( 1 / ( 1 + exp( -( ( $hue % 60 ) - 30 ) / 6 ) ) ) );
        $tone_r = 255 - $tone_f;
        if ( $hue < 60 ) {
            @rgb = ( 255, $tone_f, 0 );
        }
        elsif ( $hue < 120 ) {
            @rgb = ( $tone_r, 255, 0 );
        }
        elsif ( $hue < 180 ) {
            @rgb = ( 0, 255, $tone_f );
        }
        elsif ( $hue < 240 ) {
            @rgb = ( 0, $tone_r, 255 );
        }
        else {
            @rgb = ( $tone_f, 0, 255 );
        }
        $hue = int( 255 * $hue / $maxhue );
        $color_qual[ $qual / $qualstep ] = $im->colorAllocate(@rgb);
        $color_vec[ $qual / $qualstep ] = $im->colorAllocate( $hue, $hue, $hue );
        $color_gen[ $qual / $qualstep ] = $im->colorAllocate( $hue, 0, 0 );
    }
    my $white      = $im->colorAllocate( 255, 255, 255 );
    my $black      = $im->colorAllocate( 0,   0,   0 );
    my $dgreen     = $im->colorAllocate( 0,   175, 0 );
    my $dred       = $im->colorAllocate( 175, 0,   0 );
    my $dyellow    = $im->colorAllocate( 175, 175, 0 );
    my $background = $im->colorAllocate( 100, 100, 100 );
    my $blue       = $im->colorAllocate( 0,   0,   255 );
    my $red        = $im->colorAllocate( 255, 0,   0 );

    # fills
    $im->fill( 1, 1, $background );
    $im->filledRectangle( 0,                           0, $n_bp,                                  $topmargin,                       $white );
    $im->filledRectangle( 0,                           0, $leftmargin,                            $reads * $rowheight + $topmargin, $white );
    $im->filledRectangle( $n_bp / 2 + $leftmargin + 1, 0, $n_bp / 2 + $leftmargin + $rightmargin, $reads * $rowheight + $topmargin, $white );
    my ( $run, $bp, $phred, $bpcolor, $bp1status, $bp2status, $posx );

    #Provide a legend for the well, capillary, read length and Q20.
    my $line_xoffset = 12;
    my $line_yoffset = 3;

    #$im->stringTTF($font,0,$topmargin-20,'Well',7,0,$blue);
    $im->string( gdTinyFont, 0, $topmargin - 25, 'Well', $blue );
    $im->line( 0 + $line_xoffset, $topmargin - $line_yoffset, 0 + $line_xoffset, $topmargin - 20 + $line_yoffset, $blue );

    #$im->stringTTF($font,20,$topmargin-20,'Cap',7,0,$blue);
    $im->string( gdTinyFont, 25, $topmargin - 25, 'Cap', $blue );
    $im->line( 20 + $line_xoffset, $topmargin - $line_yoffset, 20 + $line_xoffset, $topmargin - 20 + $line_yoffset, $blue );

    #$im->stringTTF($font,$n_bp/2+$leftmargin+2,$topmargin-20,'Leng',7,0,$blue);
    $im->string( gdTinyFont, $n_bp / 2 + $leftmargin + 2, $topmargin - 25, 'Leng', $blue );
    $im->line( $n_bp / 2 + $leftmargin + 2 + $line_xoffset, $topmargin - $line_yoffset, $n_bp / 2 + $leftmargin + 2 + $line_xoffset, $topmargin - 20 + $line_yoffset, $blue );

    #$im->stringTTF($font,$n_bp/2+$leftmargin+25,$topmargin-20,'Q20',7,0,$blue);
    $im->string( gdTinyFont, $n_bp / 2 + $leftmargin + 25, $topmargin - 25, 'Q20', $blue );
    $im->line( $n_bp / 2 + $leftmargin + 25 + $line_xoffset, $topmargin - $line_yoffset, $n_bp / 2 + $leftmargin + 25 + $line_xoffset, $topmargin - 20 + $line_yoffset, $blue );

    # Provide a scale
    for ( $bp = 0; $bp <= $n_bp; $bp++ ) {
        $posx = int( $leftmargin + $bp / 2 );
        if ( !( $bp % 100 ) ) {
            $im->line( $posx, $topmargin, $posx, $topmargin - 5, $black );

            #$im->stringTTF($font,$posx-(length($bp)-1)*2,$topmargin-8,$bp,7,0,$black);
            $im->string( gdTinyFont, $posx - ( length($bp) - 1 ) * 2, $topmargin - 13, $bp, $black );
        }
        elsif ( !( $bp % 25 ) ) {
            $im->line( $posx, $topmargin, $posx, $topmargin - 2, $black );
        }
    }

    # retrieve information for each read
    my $read_summary = $dbc->Table_retrieve(
        "Clone_Sequence",
        [   "Well as well",
            "FK_Run__ID as runid",
            "Sequence_Length as length",
            "Quality_Left as ql",
            "Quality_Length as qt",
            "Quality_Left + Quality_Length -1 as qr",
            "Vector_Left as vl",
            "Vector_Right as vr",
            "Vector_Total as vt",
            "Clone_Sequence_Comments as comment",
            "Growth as growth",
            "Capillary as capillary"
        ],
        "WHERE FK_Run__ID=$runid",
        -format => 'AofH'
    );

    # retrieve information for the run
    my $run_summary = $dbc->Table_retrieve(
        "Run,RunBatch,Equipment,Plate,Library,Project,Employee",
        [ "Employee_Name as employee", "Run_DateTime as rundate", "Equipment_Name as sequencer", "Plate_Created as platedate", "Project_Name as project", "Run_ID as runid" ],
        "WHERE FK_RunBatch__ID=RunBatch_ID AND RunBatch.FK_Equipment__ID=Equipment_ID AND Run.FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID AND RunBatch.FK_Employee__ID=Employee_ID AND Run_ID=$runid",
        -format => 'RH'
    );

    my @phred_lengths_array = $dbc->Table_find( "Clone_Sequence", "Quality_Length", "WHERE FK_Run__ID=$runid" );

    # get Q20Length for each well
    # get scores for each base pair on a per-well basis
    my %well_scores = $dbc->Table_retrieve( "Clone_Sequence", [ "Sequence_Scores", "Well", SQL_phred(20) . " as Q20Length" ], "WHERE FK_Run__ID=$runid" );

    unless ( keys %well_scores ) { Message("Data not available in this database"); return; }

    my $keyed_scores = $dbc->Table_retrieve_format(
        -value    => \%well_scores,
        -fields   => [ "Sequence_Scores", "Well", "Q20Length" ],
        -format   => 'HofH',
        -keyfield => 'Well'
    );

    my $imgmap = "";
    print "<div width=100% align=right>";

    #    PrintIcons($runid);
    print "</div><br>";
    print "<span class=small>";
    foreach my $key ( sort keys %{$run_summary} ) {
        print "<b><span class=vdarkbluetext>$key</span></b> " . $run_summary->{$key};
        print "&nbsp;&nbsp;";
    }
    print "</span><BR>";

    # Generate the Imagemap
    $imgmap .= qq{<map name="platemap">\n};
    my ( $mapx1, $mapx2, $mapy1, $mapy2, $alttext );
    my $index       = 0;
    my $update_well = 1;
    my $well        = 0;
    while ( $index < $reads ) {
        my $well_text = chr( int( $index / $col_size ) + 65 ) . sprintf( "%02d", $index % $col_size + 1 );

        #$im->stringTTF($font,0,$topmargin+($well+1)*$rowheight-2,$well_text,7,0,$black);
        $im->string( gdTinyFont, 0, $topmargin + ( $index + 1 ) * $rowheight - 7.5, $well_text, $black );
        if ( $well_text eq $read_summary->[$well]->{'well'} ) {

            #	  my $p20bp = $phred_lengths->[$well];
            my $p20bp = $keyed_scores->{$well_text}{"Q20Length"};
            my @scores = unpack( "C*", $keyed_scores->{$well_text}{'Sequence_Scores'} );

            ( $mapx1, $mapy1, $mapx2, $mapy2 ) = ( $leftmargin, $topmargin + $well * $rowheight, $n_bp / 2 + $leftmargin, $topmargin + ( $well + 1 ) * $rowheight - 1 );
            $alttext
                = "$well_text | RL "
                . $read_summary->[$well]->{'length'}
                . " | QL $p20bp | QL/QR "
                . $read_summary->[$well]->{'ql'} . "/"
                . $read_summary->[$well]->{'qt'}
                . " | VL/VR/VT "
                . $read_summary->[$well]->{'vl'} . "/"
                . $read_summary->[$well]->{'vr'} . "/"
                . $read_summary->[$well]->{'vt'} . " |";
            my $chromatogram_link = "$URL_address/view_chromatogram.pl?runid=$runid&well=$well_text&height=$APPLET_HEIGHT&width=$APPLET_WIDTH&dbase=$dbc->{dbase}&host=$dbc->{host}";
            $imgmap .= qq{<area shape=rect coords="$mapx1,$mapy1,$mapx2,$mapy2" href='$chromatogram_link' target='_blank' title="$alttext">\n};

            # For now, analyze the first $n_bp BP.
            for ( $bp = 0; $bp < $n_bp; $bp += 2 ) {
                $posx = $leftmargin + $bp / 2;

                # Take the average phred between the two base pairs.
                if ( defined $scores[$bp] && defined $scores[ $bp + 1 ] ) {
                    $phred = int( ( $scores[$bp] + $scores[$bp] ) / 2 );
                }
                elsif ( !defined $scores[ $bp + 1 ] ) {
                    $phred = $scores[$bp];
                }

                $bp1status = GetBPStatus( $read_summary, $well, $bp );
                $bp2status = GetBPStatus( $read_summary, $well, $bp + 1 );

                # Decide what colour to use.
                if ( $bp1status =~ /vector/ || $bp2status =~ /vector/ ) {
                    $bpcolor = $color_vec[ $phred / $qualstep ];
                }
                elsif ( $bp1status =~ /quality/ && $bp2status =~ /quality/ ) {
                    $bpcolor = $color_qual[ $phred / $qualstep ];
                }
                elsif ( $bp1status =~ /outside/ || $bp2status =~ /outside/ ) {
                    last;
                }
                else {
                    $bpcolor = $color_gen[ $phred / $qualstep ];
                }
                unless ($bpcolor) { $bpcolor = $white }    # If no color is defined, then use white
                $im->filledRectangle( $posx, $topmargin + $index * $rowheight, $posx + 1, $topmargin + ( $index + 1 ) * $rowheight - 2, $bpcolor );
            }

            #$im->stringTTF($font,20,$topmargin+($well+1)*$rowheight-2,$read_summary->[$well]->{'capillary'},7,0,$black);
            $im->string( gdTinyFont, 20, $topmargin + ( $index + 1 ) * $rowheight - 7.5, $read_summary->[$well]->{'capillary'}, $black );

            #$im->stringTTF($font,$n_bp/2+$leftmargin+2,$topmargin+($well+1)*$rowheight-2,$read_summary->[$well]->{'length'},7,0,$black);
            $im->string( gdTinyFont, $n_bp / 2 + $leftmargin + 2, $topmargin + ( $index + 1 ) * $rowheight - 7.5, $read_summary->[$well]->{'length'}, $black );
            if ( $p20bp > 300 ) {

                #$im->stringTTF($font,$n_bp/2+$leftmargin+25,$topmargin+($well+1)*$rowheight-2,$p20bp,7,0,$dgreen);
                $im->string( gdTinyFont, $n_bp / 2 + $leftmargin + 25, $topmargin + ( $index + 1 ) * $rowheight - 7.5, $p20bp, $dgreen );
            }
            elsif ( $p20bp > 100 ) {

                #$im->stringTTF($font,$n_bp/2+$leftmargin+25,$topmargin+($well+1)*$rowheight-2,$p20bp,7,0,$dyellow);
                $im->string( gdTinyFont, $n_bp / 2 + $leftmargin + 25, $topmargin + ( $index + 1 ) * $rowheight - 7.5, $p20bp, $dyellow );
            }
            else {

                #$im->stringTTF($font,$n_bp/2+$leftmargin+25,$topmargin+($well+1)*$rowheight-2,$p20bp,7,0,$dred);
                $im->string( gdTinyFont, $n_bp / 2 + $leftmargin + 25, $topmargin + ( $index + 1 ) * $rowheight - 7.5, $p20bp, $dred );
            }
            $well++;
        }
        $index++;
    }
    $imgmap .= qq{</map>\n};
    print $imgmap, "\n";

    # Generate a legend
    my $legend_topx        = 20;
    my $legend_width       = 215;
    my $legend_height      = 40;
    my $legend_item_width  = 5;
    my $legend_item_height = 10;
    $im->rectangle( $legend_topx, 0, $legend_topx + $legend_width, $legend_height, $black );
    my $qual_idx;
    my $color;

    #$im->stringTTF($font,$legend_topx+20,10,"Quality/Vector Base Pair Phred",7,0,$black);
    $im->string( gdTinyFont, $legend_topx + 20, 5, "Quality/Vector Base Pair Phred", $black );
    my $i = 1;
    for ( $qual = 0; $qual < $maxqual; $qual += $qualstep ) {
        $qual_idx = $qual / $qualstep;
        $color    = $color_qual[$qual_idx];
        $im->filledRectangle( $legend_topx + 20 + $qual_idx * $legend_item_width, 15, $legend_topx + 20 + ( $qual_idx + 1 ) * $legend_item_width, 15 + $legend_item_height, $color );
        $color = $color_vec[$qual_idx];
        $im->filledRectangle( $legend_topx + 20 + $qual_idx * $legend_item_width, 15 + 5, $legend_topx + 20 + ( $qual_idx + 1 ) * $legend_item_width, 15 + $legend_item_height, $color );
        if ( !( $qual % ( $qualstep * 2 ) ) ) {
            my $font_colour;

            # Alternate the color so it is easier to read the legend
            if ( $i % 2 == 0 ) {
                $font_colour = $black;
            }
            else {
                $font_colour = $red;
            }

            #$im->stringTTF($font,$legend_topx+20+$qual_idx*$legend_item_width,15+$legend_item_height+10,$qual,7,0,$black);
            $im->string( gdTinyFont, $legend_topx + 20 + $qual_idx * $legend_item_width, 15 + $legend_item_height + 5, $qual, $font_colour );
            $i++;
        }
    }
    my $text = "Run Plate View for run ID $runid";

    #$im->stringTTF($font,$legend_topx+$legend_width+30,15,$text,15,0,$black);
    $im->string( gdGiantFont, $legend_topx + $legend_width + 30, 0, $text, $black );
    my $subtext = "Vector sequence shown in greyscale. Non-vector, quality sequence shown";

    #$im->stringTTF($font,$legend_topx+$legend_width+30,27,$subtext,7,0,$black);
    $im->string( gdSmallFont, $legend_topx + $legend_width + 30, 12, $subtext, $black );
    $subtext = "in rainbow palette. Non-vector, non-quality sequence shown in dark red.";

    #$im->stringTTF($font,$legend_topx+$legend_width+30,35,$subtext,7,0,$black);
    $im->string( gdSmallFont, $legend_topx + $legend_width + 30, 20, $subtext, $black );
    $subtext = "Numbers to the right show read length and phred 20 length.";

    #$im->stringTTF($font,$legend_topx+$legend_width+30,43,$subtext,7,0,$black);
    $im->string( gdSmallFont, $legend_topx + $legend_width + 30, 28, $subtext, $black );

    # write the image to disk
    open( FILE, ">/$URL_temp_dir/detail-$runid$well.png" );
    binmode FILE;
    print FILE $im->png;
    close(FILE);

    # output display HTML
    print qq{<br><img src="/dynamic/tmp/detail-$runid$well.png" border=0 usemap="#platemap">};
    print "<br><span class=small><b>Placing your cursor over a read will show some statistics.</b></span>";

}

################################################################
# Fetch the status of a BP in a given read. The possible
# values returned are:
#   quality,vector,outside
# The status 'quality' and 'vector' could be returned as a list,
# since it is possible for a base pair to be both.
#
# For a sequence of L+1 base pairs:
#
# Vector assignment:
#
# 0...................................................L
# --vector--^                      ^--vector-----------
#           VL                     VR
#
# Quality assignment:
#
# 0...................................................L
#          ^----quality-------^
#          QL                 QR
#
#
###########################
sub GetBPStatus {
###########################
    my $read_summary = shift;
    my $well_idx     = shift;
    my $bp_idx       = shift;
    my $qt           = $read_summary->[$well_idx]->{'qt'};
    my $ql           = $read_summary->[$well_idx]->{'ql'};
    my $qr           = $read_summary->[$well_idx]->{'qr'};
    my $vt           = $read_summary->[$well_idx]->{'vt'};
    my $vl           = $read_summary->[$well_idx]->{'vl'};
    my $vr           = $read_summary->[$well_idx]->{'vr'};
    my $tot          = $read_summary->[$well_idx]->{'length'};
    if ( $ql < 0 ) { $ql = 0; }
    if ( $qr < 0 ) { $qr = 0; }

    #  if($vl < 0) { $vl = 0; }
    #  if($vr < 0) { $vr = 0; }
    my @status;

    # Check for quality
    if ( $bp_idx > $tot ) {
        push( @status, "outside" );
    }
    else {
        if ( $bp_idx >= $ql && $bp_idx <= $qr ) {
            push( @status, "quality" );
        }

        # BELOW:
        # Bug fix. The vector calculation was not correct. The old code was calculating
        # something like a complement of what was supposed to be shown
        # if ($bp_idx >= $vl && $bp_idx <= $vl+$vt) then vector
        # (26 Oct 2000 MK)
        if ( $vl > $vr && !$vr ) {

            # All vector
            push( @status, "vector" );
        }
        else {

            # Check for left vector first.
            if ( $vl > 0 && $bp_idx <= $vl ) {
                push( @status, "vector" );
            }
            if ( $vr > 0 && $bp_idx >= $vr ) {
                push( @status, "vector" );
            }
        }
    }
    return join( ",", @status );
}

###################################
# Function that returns a table with the frequency and culmulative distributions for
# Q10, Q20, and Q30 values for a run
###################################
sub QualityTable {
###################################
    my %args  = &filter_input( \@_, -args => 'dbc,run_id' );
    my $dbc   = $args{-dbc};
    my $runid = $args{-run_id};                                # (Scalar) Run ID to display

    my %well_scores = $dbc->Table_retrieve( "Clone_Sequence", [ SQL_phred(10) . " as Q10Length", SQL_phred(20) . " as Q20Length", SQL_phred(30) . " as Q30Length" ], "WHERE FK_Run__ID=$runid", -format => "HofA" );

    my @ranges = map { $_ * 100 } ( 0 .. 15 );
    my $num_scores = int( @{ $well_scores{'Q20Length'} } );

    my $q10stat = Statistics::Descriptive::Full->new();
    $q10stat->add_data( @{ $well_scores{"Q10Length"} } );
    my %q10dist = $q10stat->frequency_distribution( \@ranges );
    my $q20stat = Statistics::Descriptive::Full->new();
    $q20stat->add_data( @{ $well_scores{"Q20Length"} } );
    my %q20dist = $q20stat->frequency_distribution( \@ranges );
    my $q30stat = Statistics::Descriptive::Full->new();
    $q30stat->add_data( @{ $well_scores{"Q30Length"} } );
    my %q30dist = $q30stat->frequency_distribution( \@ranges );

    my $table = new HTML_Table();
    $table->Set_Border(1);
    $table->Set_Title("Phred Value Distribution");
    $table->Set_sub_title( 'Range', 1, 'mediumyellowbw' );
    $table->Set_sub_title( 'Q=10',  3, 'mediumgreenbw' );
    $table->Set_sub_title( 'Q=20',  3, 'mediumredbw' );
    $table->Set_sub_title( 'Q=30',  3, 'mediumbluebw' );
    $table->Set_Headers( [ "&nbsp;", "Reads", "Freq", "Cml", "Reads", "Freq", "Cml", "Reads", "Freq", "Cml" ] );
    my $q10culm   = 0;
    my $q20culm   = 0;
    my $q30culm   = 0;
    my $prevRange = 0;

    my $row = 1;
    my $col = 1;
    foreach my $range (@ranges) {
        my @colspans = ();
        $col = 1;
        my $q10freq = $q10dist{$range} / $num_scores;
        my $q20freq = $q20dist{$range} / $num_scores;
        my $q30freq = $q30dist{$range} / $num_scores;
        $q10culm += $q10freq;
        $q20culm += $q20freq;
        $q30culm += $q30freq;

        my @row = ();

        # add range
        if ( $range == 0 ) {
            push( @row,      0 );
            push( @colspans, 1 );
        }
        else {
            push( @row,      $prevRange + 1 . "-" . $range );
            push( @colspans, 1 );
        }
        $prevRange = $range;

        # check if q10dist > 0. If it is, add values. Else, leave it empty
        if ( $q10dist{$range} ) {
            push( @row, $q10dist{$range}, sprintf( "%3.1f", 100 * $q10freq ), sprintf( "%3.1f", 100 * $q10culm ) );
            $col += 3;
            push( @colspans, 1, 1, 1 );
        }
        else {
            $col++;
            push( @row,      '&nbsp;' );
            push( @colspans, 3 );
        }

        # check if q20dist > 0. If it is, add values. Else, leave it empty
        if ( $q20dist{$range} ) {
            push( @row, $q20dist{$range}, sprintf( "%3.1f", 100 * $q20freq ), sprintf( "%3.1f", 100 * $q20culm ) );
            $col += 3;
            push( @colspans, 1, 1, 1 );
        }
        else {
            $col++;
            push( @row,      '&nbsp;' );
            push( @colspans, 3 );
        }

        # check if q10dist > 0. If it is, add values. Else, leave it empty
        if ( $q30dist{$range} ) {
            push( @row, $q30dist{$range}, sprintf( "%3.1f", 100 * $q30freq ), sprintf( "%3.1f", 100 * $q30culm ) );
            $col += 3;
            push( @colspans, 1, 1, 1 );
        }
        else {
            $col++;
            push( @row,      '&nbsp;' );
            push( @colspans, 3 );
        }
        $row++;

        $table->Set_Row( \@row, -colspans => \@colspans );
    }

    $table->Toggle_Colour('off');

    my $summary_table = new HTML_Table();
    $summary_table->Set_Border(1);
    $summary_table->Set_Title("Phred Length Summary ($num_scores reads)");
    $summary_table->Set_sub_title( 'Measure', 1, 'mediumyellowbw' );
    $summary_table->Set_sub_title( 'Q=20',    1, 'mediumredbw' );
    $summary_table->Set_sub_title( 'Q=10',    1, 'mediumgreenbw' );
    $summary_table->Set_sub_title( 'Q=30',    1, 'mediumbluebw' );

    $summary_table->Set_Row( [ 'Average', sprintf( "%3.1f", $q20stat->mean() ),               sprintf( "%3.1f", $q10stat->mean() ),               sprintf( "%3.1f", $q30stat->mean() ), ] );
    $summary_table->Set_Row( [ 'Median',  sprintf( "%3.1f", $q20stat->median() ),             sprintf( "%3.1f", $q10stat->median() ),             sprintf( "%3.1f", $q30stat->median() ) ] );
    $summary_table->Set_Row( [ 'Std Dev', sprintf( "%3.1f", $q20stat->standard_deviation() ), sprintf( "%3.1f", $q10stat->standard_deviation() ), sprintf( "%3.1f", $q30stat->standard_deviation() ) ] );

    my $combined_table = new HTML_Table();
    $combined_table->Toggle_Colour('off');
    $combined_table->Set_Row( [ $table->Printout(0) ] );
    $combined_table->Set_Row( [ $summary_table->Printout(0) ], -spec => 'align=center' );

    return $combined_table->Printout(0);
}

####################################
# Function to generate page for Histograms and Statistics
####################################
sub StatsPlate {
####################################
    my %args  = &filter_input( \@_, -args => 'dbc,run_id' );
    my $dbc   = $args{-dbc};
    my $runid = $args{-run_id};

    my %well_scores = $dbc->Table_retrieve( "Clone_Sequence", [ SQL_phred(10) . " as Q10", SQL_phred(20) . " as Q20", SQL_phred(30) . " as Q30" ], "WHERE FK_Run__ID=$runid", -format => "HofA" );
    my ($run_dir) = $dbc->Table_find( "Run", "Run_Directory", "WHERE Run_ID = $runid" );

    print h2("Statistics for $run_dir: Run ($runid)");

    print "<TABLE>\n";
    print "<TR>\n";
    print "<TD>\n";
    print QualityTable( $dbc, -run_id => $runid );
    print "</TD>\n";

    foreach my $threshold ( keys %well_scores ) {
        my $data = $well_scores{$threshold};
        print "<TD valign=top>\n";
        print "<TABLE border=1>\n";
        print "<TR>\n";
        print "<TD>\n";
        print &Sequencing::Sequence::Bin_counts( $data, 'type' => 'dist,cum', 'title' => "$threshold" );
        print "</TD>\n";
        print "</TR>\n";
        print "</TABLE>\n";
        print "</TD>\n";
    }

    print "</TR>\n";
    print "</TABLE>\n";
}

####################################
# Function to display a simple textarea with sequence text
####################################
sub DisplaySequence {
####################################
    my %args  = &filter_input( \@_, -args => 'dbc,run_id' );
    my $dbc   = $args{-dbc};
    my $runid = $args{-run_id};
    my $well  = $args{-well};
    print h2("Sequence for Run $runid (Well: $well)");
    my ($sequence) = $dbc->Table_find( "Clone_Sequence", "Sequence", "WHERE FK_Run__ID=$runid AND Well='$well'" );

    # preprocess - add newlines every 60 characters
    my @str = $sequence =~ /(\w{50}|\w+)/gi;

    print "<PRE>";
    foreach my $line (@str) {
        print "$line\n";
    }
    print "</PRE>";
}

return 1;
