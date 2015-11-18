################################################################################
# Data_Viewer.pm
#
# This modules provides various Data viewing methods that are relatively generic
#
# Included:
#
#  colour_map - generates an MxN map of colour-coded images
#  Generate_Histogram - a single command histogram generator using the Histogram module
#
################################################################################
################################################################################
# $ID$
################################################################################
# CVS Revision: $Revision: 1.18 $
#     CVS Date: $Date: 2004/11/30 01:43:35 $
################################################################################
package SDB::Data_Viewer;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Data_Viewer.pm - This modules provides various Data viewing methods that are relatively generic

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This modules provides various Data viewing methods that are relatively generic<BR>Included:<BR>colour_map - generates an MxN map of colour-coded images <BR>Generate_Histogram - a single command histogram generator using the Histogram module<BR>$ID$<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #W
##############################
require Exporter;
@EXPORT = qw(
    colour_map
    colour_map_legend
    Generate_Histogram
);

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use DBI;
use GD;
use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings qw($URL_dir_name $image_dir);

##############################
# custom_modules_ref         #
##############################
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
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

####################
sub colour_map {
####################
    #
    # returns coloured cell correlated with values.
    # (originally designed to represent 96-well plate quality values)
    #
    #
    my $value  = shift;
    my $max    = Extract_Values( [ shift, 1000 ] );
    my $groups = Extract_Values( [ shift, 10 ] );
    my $growth = shift || "";
    my $name   = shift;

    #
    # images generated are mapped retrieved from:  '$file_name$index$suffix.png'
    #
    my $file_name = "/$URL_dir_name/$image_dir/../wells/well-";
    my $suffix    = '-s0';

    my $default_height = 25;
    my $default_width  = 25;

    my $div       = int( $max / $groups );
    my $threshold = 0;                       ### allow one entry for 0 and rest >= ...
    my $index     = 0;

    while ( $threshold < $max ) {
        if ( $value =~ /N/i ) { $index = 'failed'; last; }
        elsif ( $value == 0 )          { last; }
        elsif ( $value >= $threshold ) { $index++ }
        else                           { last; }
        $threshold += $div;
    }
    if ( $index >= $groups ) { $index = $groups - 1; }

    #### Customize Suffix if desired... ####
    if ( $growth =~ /sl/i ) {
        $suffix = '-sg-s0';
    }
    elsif ( $growth =~ /no/i ) {
        $suffix = '-ng-s0';
    }
    elsif ( $growth =~ /^un/i ) {
        $suffix = '-un-s0';
    }
    my $selected_suffix = $suffix;
    $selected_suffix =~ s/s0$/s1/;
    if ($name) { $name = "name='$name'" }
    return "<Img src='$file_name$index$suffix.png' width=$default_width height=$default_height alt='$value' title='$value' border=0 $name>";
}

###########################
sub colour_map_legend {
###########################
    #
    # returns coloured cell correlated with values.
    # (originally designed to represent 96-well plate quality values)
    #
    my $max    = Extract_Values( [ shift, 1000 ] );
    my $groups = Extract_Values( [ shift, 10 ] );
    my $growth = shift || "";

#### Custom filename pattern ####
    my $file_name = "/$URL_dir_name/$image_dir/../wells/well-";

    my $failed_suffix = "failed-s0";

    #    my $failed_suffix = "0-s0";
    my @indexed_suffix;
    foreach my $index ( 0 .. $groups ) {
        $indexed_suffix[$index] = "$index-s0";
    }

    my @custom_headers        = ( 'NG',       'SG',         'Unused' );
    my @custom_headers_suffix = ( '1-ng-s0',  '1-sg-s0',    '1-un-s0' );
    my @custom_headers_alt    = ( 'No Grows', 'Slow Grows', 'Unused Wells' );

####################

    my $default_height = 25;
    my $default_width  = 25;

    my $div       = int( $max / $groups );
    my $threshold = 0;                       ### allow one entry for 0 and rest >= ...
    my $index     = 0;

    my @headers = ('Fail');
    push( @headers, ( '=0', '>0' ) );
    my @imgs = ("<Img src='$file_name$failed_suffix.png' width=$default_width height=$default_height alt='failed' border=0>");
    push( @imgs, "<Img src='$file_name$indexed_suffix[0].png' width=$default_width height=$default_height alt='=0' border=0>" );
    push( @imgs, "<Img src='$file_name$indexed_suffix[1].png' width=$default_width height=$default_height alt='1-99' border=0>" );

    foreach my $index ( 2 .. $groups - 1 ) {
        push( @headers, ( $index - 1 ) * $div );
        my $thisbin = $index;
        push( @imgs, "<Img src='$file_name$indexed_suffix[$index].png' width=$default_width height=$default_height alt='Bin $index' border=0>" );
    }

    foreach my $index ( 0 .. int(@custom_headers) - 1 ) {
        push( @headers, $custom_headers[$index] );
        push( @imgs,    "<Img src='$file_name$custom_headers_suffix[$index].png' width=$default_width height=$default_height alt='$custom_headers_alt[$index]' border=0>" );
    }

    my $Legend = HTML_Table->new();
    $Legend->Set_Headers( \@headers );
    $Legend->Set_Row( \@imgs );
    return $Legend->Printout(0);
}

###########################
sub Generate_Histogram {
###########################
    #
    # change this to more object oriented to handle options...
    # This calls the generate histogram routine with a number of settings
    #  specific to run info...
    #
    my %args = @_;


    #
## Standard Default Values for Runs...
    #
    my $data = $args{'data'};
    my @Bins;
    if ($data) { @Bins = @$data; }
    my $stamp       = $args{'timestamp'}   || '';
    my $filename    = $args{'filename'}    || "Hist$stamp.png";
    my $remove_zero = $args{'remove_zero'} || 0;
    my $binwidth = Extract_Values( [ $args{'binwidth'}, 2 ] );    ### width of bin in pixels...

    #    my $binvalue = Extract_Values([$args{'binvalue'},10]);  ### width of bin in pixels...
    my $group_bins = Extract_Values( [ $args{'group'},   10 ] );    ### group N bins together by colour
    my $Ncolours   = Extract_Values( [ $args{'colours'}, 13 ] );    ### number of unique colours
    my @x_ticks  = @{ $args{'x_ticks'} };
    my @x_labels = @{ $args{'x_labels'} };
    my $x_label  = $args{'xlabel'} || 'P20 Quality / Read';

    my @y_ticks      = @{ $args{'y_ticks'} };
    my @y_labels     = @{ $args{'y_labels'} };
    my $y_label      = $args{'ylabel'} || '';
    my $height       = Extract_Values( [ $args{'height'}, 100 ] );
    my $width        = $args{'width'} || 0;
    my $yline        = $args{'yline'} || 0;                          ### marked point on y axis to include line across graph
    my $path         = $args{'path'};
    my $image_format = $args{image_format} || 'png';                 ### Output format of the image
    my $colour       = $args{colour};

    my $zero = $Bins[0] || 0;
    if ($remove_zero) {
        $Bins[0] = 0;
    }

    my $num_bins = scalar(@Bins);
    my $Hist = SDB::Histogram->new( -path => $path );
    if ($colour) { $Hist->Set_Colour($colour) }
    $Hist->Set_Bins( \@Bins, $binwidth );
    if ( $x_label || int(@x_ticks) ) { $Hist->Set_X_Axis( $x_label, \@x_ticks, \@x_labels ); }
    if ( $y_label || int(@y_ticks) ) { $Hist->Set_Y_Axis( $y_label, \@y_ticks, \@y_labels ); }
    if ($yline) { $Hist->HorizontalLine($yline) }
    $Hist->Number_of_Colours($Ncolours);
    $Hist->Group_Colours($group_bins);

    ( my $scale, my $max1 ) = $Hist->DrawIt( $filename, height => $height, width => $width, image_format => $image_format );
    if ( defined($scale) && defined($max1) ) {
        return ( "<Img src='/dynamic/tmp/$filename'>", $zero, $max1 );
    }
    else {
	return err('Data_Viewer::Generate_Histogram: Error returned from DrawIt');
    }
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

$Id: Data_Viewer.pm,v 1.18 2004/11/30 01:43:35 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
