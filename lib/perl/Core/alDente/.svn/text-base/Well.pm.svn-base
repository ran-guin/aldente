################################################################################
# Well.pm
#
# This module handles Container (Plate) based functions
#
###############################################################################
package alDente::Well;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Well.pm - This module handles Container (Plate) based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (Plate) based functions<BR>

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use RGTools::Barcode;

##############################
# custom_modules_ref         #
##############################
#use alDente::Library;
#use alDente::Barcoding;
#use alDente::SDB_Defaults;
#use alDente::ReArray;
#use alDente::Container;
#use alDente::Validation;

use SDB::DBIO;
use SDB::CustomSettings;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

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

#######################
sub well_convert {
#######################
    #
    # converts between 384 well and 96 well plates (eg.  p24 -> H12 quadrant d)
    #
    my %args = @_;

    my $dbc         = $args{-dbc};
    my $wells       = $args{-wells};          # list of wells to convert
    my $quadrant    = $args{-quadrant};       # quadrant specification (a,b,c or d)
    my $source_size = $args{-source_size};    # size of source plate (384 well expected)
    my $target_size = $args{-target_size};    # size of target plate (96 well expected)
    my $debug       = $args{-debug};

    if ( $source_size =~ /^(\d+)/ ) { $source_size = $1; }
    if ( $target_size =~ /^(\d+)/ ) { $target_size = $1; }

    # convert to 384-well nopad (if necessary)
    if ( $source_size == 384 ) {
        $wells = &format_well( $wells, 'nopad' );
    }
    $wells = lc($wells);

    my $new_wells;
    foreach my $well ( split ',', $wells ) {

        # build condition
        my $condition = "Plate_$source_size = '$well'";
        if ($quadrant) {
            $condition .= " AND Quadrant='$quadrant'";
        }

        my $new_well = join ',', $dbc->Table_find( 'Well_Lookup', "Plate_$target_size", "where $condition", -debug => $debug );

        if ( $new_well =~ /([a-zA-Z])[0](\d)/ ) {
            $new_well = $1 . $2;
            $new_wells .= "$1$2,";
        }
        elsif ( $new_well =~ /([a-zA-Z])(\d+)/ ) {
            $new_wells .= "$new_well,";
        }
    }
    chop $new_wells;

    #    print "New wells: $new_wells.";
    if ( !$new_wells ) { return ""; }
    $new_wells = &format_well($new_wells);
    return $new_wells;
}

#########################
sub well_complement {
#########################
    #
    # Used to generate Well labels when plates have been spun 180 degrees.
    #
    # returns Well name given plate size and original well name
    #
    my $well = shift;
    my $size = shift || 96;

########## mapping of rows

    my $rows_384 = "ABCDEFGHIJKLMNOP";
    my $rows_96  = "ABCDEFGH";

    my $Min_Row = 'A';
    my $Max_Row = 'H';

    my $Min_Col = 1;
    my $Max_Col = 12;

    my $rows       = 8;
    my $row_string = $rows_96;

    if ( $size == 384 ) {
        $Max_Row    = 'P';
        $Max_Col    = 24;
        $rows       = 16;
        $row_string = $rows_384;
    }

    my $Row    = {};
    my $map_to = $Min_Row;
    foreach my $row ( 1 .. 16 ) {
        my $row_name = substr( $row_string, $row - 1, 1 );
        my $reverse_name = substr( $row_string, $rows - $row, 1 );
        $Row->{$row_name} = $reverse_name;
        $map_to++;
    }

    if ( $well =~ /([a-zA-Z])(\d+)/ ) {
        my $row     = $1;
        my $col     = $2;
        my $new_col = $Max_Col - $col + 1;
        my $new_row = $Row->{$row};
        return "$new_row$new_col";
    }
    else { return $well; }
}

################################################
# Get all the wells for a particular plate size
################################################
sub Get_Wells {
################
    my %args = @_;

    my $size = $args{-size};

    my @wells;

    my $min_row = 'A';
    my $max_row = 'H';
    my $min_col = 1;
    my $max_col = 12;

    if ( $size =~ /384/ ) {
        $max_row = 'P';
        $max_col = 24;
    }

    my $real_row;
    my $real_col;
    foreach my $row ( $min_row .. $max_row ) {
        foreach my $col ( $min_col .. $max_col ) {
            $real_row = $row;
            $real_col = $col;
            if ( $size =~ /384/ ) {
                $real_row = lc($real_row);
            }
            else {
                $real_col = sprintf( "%02d", $real_col );
            }
            push( @wells, "$real_row$real_col" );
        }
    }

    return @wells;
}

###########################################################
# Convert Wells from 96 to 384 well format and vice versa
###########################################################
sub Convert_Wells {
#######################
    my %args = &filter_input( \@_, -args => 'dbc,wells,target_size,quadrant,source_size', -mandatory => 'dbc,wells' );

    my $dbc          = $args{-dbc};
    my $source_wells = $args{-wells};
    my $target_size  = $args{-target_size};    # (Scalar) Optional: (96,384, or default to Auto) converts well to 96, 384, or automatically determined format
    my $quadrant     = $args{-quadrant};       # (Scalar) Optional: Adds a quadrant argument to all wells provided
    my $source_size  = $args{-source_size};

    my @converted_wells;
    $source_wells = Cast_List( -list => $source_wells, -to => 'arrayref' );
    my @formatted_wells = Format_Wells( -wells => $source_wells, -input_format => 'Mixed' );

    # append quadrant if they have not been defined
    foreach (@formatted_wells) {
        if ( $_ =~ /^[A-Za-z]{1}\d{2}$/ ) {
            $_ = $_ . $quadrant;
        }
    }

    # Get well mapping
    my %map_auto;
    my %map_96_to_384;
    my %map_384_to_96;

    my %map = map_wells( -dbc => $dbc, -target_size => $target_size, -source_size => $source_size );

    @converted_wells = map { $map{$_} } @formatted_wells;

    return @converted_wells;
}

#
# Generate well mapping hash.
#
# This is more efficient than calling conversion scripts many times since the mapping query only needs to be performed once
#
#
# Return: hash of well mapping to target size
##################
sub map_wells {
##################
    my %args = &filter_input( \@_, -args => 'dbc,target_size,source_size', -mandatory => 'dbc' );

    my $dbc         = $args{-dbc};
    my $target_size = $args{-target_size};    # (Scalar) Optional: (96,384, or default to Auto) converts well to 96, 384, or automatically determined format
    my $source_size = $args{-source_size};

    my @mapping = $dbc->Table_find( 'Well_Lookup', 'Plate_96,Plate_384,Quadrant' );

    my %map;
    foreach my $mapped (@mapping) {
        my ( $well_96, $well_384, $quadrant ) = split ',', $mapped;
        ($well_384) = Format_Wells( -wells => $well_384, -input_format => 'Mixed' );

        if ( $target_size =~ /96/ ) {
            $map{$well_384} = "$well_96$quadrant";
        }
        elsif ( $target_size =~ /384/ && $source_size =~ /384/ ) {
            $map{"$well_384$quadrant"} = $well_384;
        }
        elsif ( $target_size =~ /384/ ) {
            $map{"$well_96$quadrant"} = $well_384;
        }
        else {
            $map{"$well_96$quadrant"} = $well_384;
            $map{$well_384} = "$well_96$quadrant";
        }
    }
    return %map;
}

#############################################
# Zero-pad and uppercase the wells
#############################################
sub Format_Wells {
    my %args = @_;

    my $wells = $args{-wells};
    my $input_format = $args{-input_format} || 'Mixed';    # Other formats are '384', '96a', '96b', '96c' and '96d'

    $wells = Cast_List( -list => $wells, -to => 'arrayref' );
    my @formatted_wells;

    foreach my $well (@$wells) {
        my ( $well, $quadrant ) = $well =~ /^(.\d+)([a-zA-Z]?)$/;
        if ( $well =~ /^(.)(\d{1})$/ ) { $well = $1 . "0$2" }
        $well = uc($well);
        if ( $input_format =~ /Mixed/ ) {
            $quadrant = lc($quadrant) if $quadrant;
        }
        elsif ( $input_format =~ /384/ )          { $quadrant = '' }
        elsif ( $input_format =~ /96([a-zA-Z])/ ) { $quadrant = lc($1) }
        push( @formatted_wells, "$well$quadrant" );
    }

    return @formatted_wells;
}

##############################
### get plate size of spect plate and get all the wells
sub get_Plate_dimension {
##############################
    my %args     = @_;
    my $plate_id = $args{-plate};
    my $size     = $args{-size};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    if ( $size eq undef ) {
        ($size) = $dbc->SDB::DBIO::Table_find( "Plate", "Plate_Size", "where Plate_ID = $plate_id" );
    }
    my @wells = &alDente::Well::Get_Wells( -size => $size );

    my $min_col;
    my $max_col;
    my $min_row;
    my $max_row;
    foreach (@wells) {
        tr/a-z/A-Z/;
        my ( $row, $col ) = $_ =~ /(\w)(\d+)/;
        $min_row = $row if ( $min_row eq undef );
        $max_row = $row if ( $max_row eq undef );
        $min_col = $col if ( $min_col eq undef );
        $max_col = $col if ( $max_col eq undef );
        if    ( $row lt $min_row ) { $min_row = $row }
        elsif ( $row gt $max_row ) { $max_row = $row }
        if    ( $col < $min_col )  { $min_col = $col }
        elsif ( $col > $max_col )  { $max_col = $col }
    }
    return ( $min_row, $max_row, $min_col, $max_col, $size );
}

#
# Sort wells by specified order (by Row or by Column). The default order is by row
#
# Usage:
#	my $sorted = alDente::Well::sort_wells( -dbc => $dbc, -wells => $well_list, -order_by => 'column' );
#
# Return: Array reference of sorted wells
##################
sub sort_wells {
##################
    my %args = &filter_input( \@_, -args => 'wells,order_by', -mandatory => 'wells' );

    my $well_list = $args{-wells};
    my $order_by  = $args{-order_by};

    my @wells = Cast_List( -list => $well_list, -to => 'array' );
    my @sorted;

    if ( $order_by =~ /Column/ixms ) {
        my %well_info;
        foreach my $well (@wells) {
            if ( $well =~ /([a-zA-Z]{1})(\d+)/ ) {
                $well_info{$2}{$1} = $well;
            }
        }
        foreach my $col ( sort { $a <=> $b } keys %well_info ) {
            foreach my $row ( sort keys %{ $well_info{$col} } ) {
                push @sorted, $well_info{$col}{$row};
            }
        }
    }
    else {
        @sorted = sort @wells;
    }

    return \@sorted;
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

$Id: Well.pm,v 1.9 2004/09/08 23:31:52 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
