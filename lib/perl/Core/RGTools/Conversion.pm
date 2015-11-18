################################################################################
#
# Conversion.pm
#
# Conversion : This provides a variety of tools to convert information between formats
#
################################################################################
################################################################################
# $Id: Conversion.pm,v 1.20 2004/12/09 17:42:07 rguin Exp $
################################################################################
# CVS Revision: $Revision: 1.20 $
################################################################################
package RGTools::Conversion;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Conversion.pm - Conversion : This provides a variety of tools to convert information between formats

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Conversion : This provides a variety of tools to convert information between formats<BR>

=cut

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    week_days
    convert_to_regexp
    convert_to_condition
    convert_to_hours
    normalize_time
    unpack_to_array
    extract_range
    pad_Distribution
    get_units
    normalize_units
    simplify_units
    Get_Best_Units
    get_number
    number
    format_well
    SQL_hours
    SQL_well
    SQL_day
    text_SQL_date
    recast_value
    convert_date
    convert_time
    SQL_weekdays
    convert_HofA_to_AofH
    convert_HofA_to_HHofA
    Convert_Case
    convert_to_mils
    convert_units
    subtract_amounts
    add_amounts
    get_base_units
    Custom_Convert_Units
    pad_Distribution
    end_of_day
    convert_file_path
);

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# standard_modules_ref       #
##############################

use POSIX qw(strftime);
use strict;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;

#use Date::Calc qw(Day_of_Week Delta_Days Add_Delta_Days Parse_Date);
use Data::Dumper;
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

################################
#
# subtract amounts of possibly different units and converts them to desired unitd
#################
sub subtract_amounts {
#################
    my $qty1         = shift;    ## original quantity
    my $units1       = shift;    ## units originally quoted
    my $qty2         = shift;    ## original quantity
    my $units2       = shift;    ## units originally quoted
    my $target_units = shift;    ## units to convert to

    my $amount = 0;

    my $base1       = get_base_units($units1);
    my $base2       = get_base_units($units2);
    my $target_base = $base1;

    if ($target_units) {
        $target_base = get_base_units($target_units);
    }

    if ( ( uc($base1) eq uc($base2) ) && ( uc($base1) eq uc($target_base) ) ) {

        if ( $units1 =~ /^$units2$/i ) {
            $amount = $qty1 - $qty2;

            #if($amount < 0){
            #    $amount = 0;
            #}

            # if not target units secified
            if ( !$target_units ) {
                return Get_Best_Units( $amount, $units1 );
            }
            else {
                return convert_units( $amount, $units1, $target_units );
            }

        }
        else {

            ( $qty1, $units1 ) = convert_to_mils( $qty1, $units1 );
            ( $qty2, $units2 ) = convert_to_mils( $qty2, $units2 );

            $amount = $qty1 - $qty2;

            #if ($amount < 0){
            #    $amount = 0;
            #}

            # if not target units secified
            if ( !$target_units ) {
                return Get_Best_Units( $amount, $units1 );
            }
            else {
                return convert_units( $amount, $units1, $target_units );
            }
        }
    }
    else {
        Call_Stack();
        print "Warning: Incompatible units ($units1 <-> $units2 <-> $target_units)<BR>";
        return ( undef, undef );
    }

}

################################
#
# adds amounts of possibly different units and converts them to desired unitd
####################
sub add_amounts {
####################
    my %args           = filter_input( \@_, -args => 'qty1,units1,qty2,units2,target_units' );
    my $qty1           = $args{-qty1};                                                           # original quantity
    my $units1         = $args{-units1};                                                         ## units originally quoted
    my $qty2           = $args{-qty2};                                                           # original quantity
    my $units2         = $args{-units2};                                                         ## units originally quoted
    my $target_units   = $args{-target_units};                                                   ## units to convert to
    my $adjust_units   = $args{-adjust_units};
    my $check_negative = $args{-check_negative};                                                 ## makes sure the result doesnt go negative

    my $result_qty;
    my $result_unit;

    my $amount      = 0;
    my $base1       = get_base_units($units1);
    my $base2       = get_base_units($units2);
    my $target_base = $base1;

    if ($target_units) {
        $target_base = get_base_units($target_units);
    }
    if ( ( uc($base1) eq uc($base2) ) && ( uc($base1) eq uc($target_base) ) ) {
        if ( $units1 =~ /^$units2$/i ) {
            $amount = $qty1 + $qty2;

            # if not target units secified
            if ( !$target_units ) {
                if ($adjust_units) { ( $result_qty, $result_unit ) = Get_Best_Units( $amount, $units1 ) }
                else               { ( $result_qty, $result_unit ) = ( $amount, $units1 ) }
            }
            else {
                return convert_units( $amount, $units1, $target_units );
            }

        }
        else {
            ( $qty1, $units1 ) = convert_to_mils( $qty1, $units1 );
            ( $qty2, $units2 ) = convert_to_mils( $qty2, $units2 );

            $amount = $qty1 + $qty2;

            # if not target units secified
            if ( !$target_units ) {
                ( $result_qty, $result_unit ) = Get_Best_Units( $amount, $units1 );
            }
            else {
                ( $result_qty, $result_unit ) = convert_units( $amount, $units1, $target_units );
            }
        }
    }
    else {
        print "Warning: Incompatible units ($units1 <-> $units2 <-> $target_units)";
        return ( undef, undef );
    }
    if ( $check_negative && $result_qty < 0 ) {
        Message("Warning: This has resulted in a negative quantity setting to zero");
        $result_qty = 0;
    }

    return ( $result_qty, $result_unit );

}

################################
# parses amount and units out of a string
#
# ex: my ($amount,$units) = get_amount_units('2.3ng');
#     $amount -> '2.3'
#     $units -> 'ng'
# Note: entering 32.g is invalid, but just 'mg' is valid
######################
sub get_amount_units {
######################
    my $input = shift;
    my ( $amount, $units );
    if ( $input =~ /^(\d*\.?\d+)(\w+)$/ ) {    ## Split the quantity into amount and units.
        $amount = $1;
        $units  = $2;
    }
    elsif ( $input =~ /(\w+)$/ ) {
        $units = $1;
    }
    return ( $amount, $units );
}

################################
#
# returns base units
######################
sub get_base_units {
######################
    my $units = shift;    ## original quantity
    my $base_unit;

    # for non-standard units eg. organs
    if ( length($units) > 2 ) {
        return $units;
    }
    if ( $units =~ /(g|l)$/i ) {    ## kilograms or litres ##
        return lc($1);
    }
    else {
        return $units;
    }
}

##################
sub unpack_to_array {
##################
    #
    # grab statistics from an array...
    #
    my $array = shift;
    my $bytes = shift || 2;

    my @array = unpack "S*", $array;

    return @array;

}

#######################
sub extract_range {
#######################
    #
    # converts range specs to list...
    #  (eg. 1-4,5,7-9 becomes 1,2,3,4,5,7,9) or A-C to A,B,C)
    #
    my %args = &filter_input(
         \@_,
        -args      => 'list,delimiter,max_letter,max_number,format384',
        -mandatory => 'list'
    );
    my $list         = $args{-list};                                               # list (string such as "1,2,4-7" or "A-D,G"
    my $delimiter    = $args{-delimiter} || ",";                                   # optional delimiter (comma used as default);
    my $max_letter   = $args{-max_letter} || 'H';
    my $max_number   = ( defined $args{-max_number} ) ? $args{-max_number} : 12;
    my $min_number   = 1;
    my $format384    = $args{-format384} || '';
    my $strip_quotes = 1;

    if ($strip_quotes) { $list =~ s /(\'|\")//g; }                                 ## strip quotes

    $list =~ s/ //g;                                                               # remove spaces;
    if ( $list =~ /[I-Zi-z]/ ) { $max_letter = 'P'; $max_number = 24; }
    elsif ($format384) { $max_letter = 'P'; $max_number = 24; }

    my @formatted_list;
    foreach my $list_element ( split ',', $list ) {

        while ( $list_element =~ /(\d+)\s?-\s?(\d+)/ ) {
            my $range = join "$delimiter", ( $1 .. $2 );
            $list_element =~ s/$1\s?-\s?$2/$range/;
        }
        while ( $list_element =~ /([A-Za-z])\s?-\s?([A-Za-z])/ ) {
            my $range = join "$delimiter", ( $1 .. $2 );
            $list_element =~ s/$1\s?-\s?$2/$range/;
        }

        ##### the following assumes wells A..H 1..12 ############

        my $range;
        while ( $list_element =~ /([A-Za-z])(\d+)\s?-\s?([A-Za-z])(\d+)/ ) {
            my ( $min_L, $min_N, $max_L, $max_N ) = ( $1, $2, $3, $4 );
            foreach my $letter ( $min_L .. $max_L ) {
                foreach my $number ( $min_N .. $max_N ) {
                    $range .= "$letter$number,";
                }
            }
            chop $range;
            $list_element =~ s/\b$min_L$min_N\s?-\s?$max_L$max_N\b/$range/;
        }
        push( @formatted_list, $list_element );
    }
    $list = join "$delimiter", @formatted_list;
    return $list;
}

##########################################################
# Pad Distribution as supplied by frequency_distribution
# (it generates distribution from min -> max)
#
# The binsize specified groups N keys in the Distribution hash together
# Note: The frequency_distribution should have been run with a bin size of 1
#
# Return: array of bins from 0 -> max+
####################
sub pad_Distribution {
####################
    my $dist       = shift;                   ## hash reference (to output of frequency_distribution ##
    my %args       = @_;
    my $min        = $args{-min} || 0;
    my $max        = $args{-max} || 0;
    my $binsize    = $args{-binsize} || 10;
    my $accumulate = $args{-accumulate};

    my @padded_Distribution;

    if ($accumulate) {
        @padded_Distribution = @$accumulate;
    }
    my %Distribution = %{$dist};

    my $bin = $min;
    foreach my $key ( sort { $a <=> $b } keys %Distribution ) {
        #### fill distribution graph with values from 0 -> min first time through if necessary ###
        unless ( ( $bin > $min ) || ( $key <= $min + 1 ) ) {
            while ( $bin < $key / $binsize ) {
                $padded_Distribution[$bin] = 0 unless $padded_Distribution[$bin];
                $bin++;
            }
        }
        unless ( $Distribution{$key} ) {next}
        $bin = int( $key / $binsize );
        $padded_Distribution[$bin] += $Distribution{$key};
    }

    ## add right padding if desired ##
    $max = int($max);
    if ( $max && ( $max > $bin ) ) {
        foreach my $right_pad ( $bin .. $max ) {
            $padded_Distribution[$right_pad] = 0 unless $padded_Distribution[$right_pad];
        }
    }

    return \@padded_Distribution;
}

#
# Tweak data output based upon expected data type.
#
# Primary adjustments:
# * casts char to int if necessary
# * casts zero value to '' or 0 depending on type
# * recasts date fields to specified format
#
# Return: recasted value
######################
sub recast_value {
######################
    my %args        = &filter_input( \@_, -args => 'value,type,date_format' );
    my $value       = $args{-value};
    my $type        = $args{-type};
    my $date_format = $args{-date_format} || 'Simple';
    my $field       = $args{-field};                                             ## only used for debuggging....
    my $debug       = $args{-debug};

    my $recast;
    if ( ( $type =~ /^date/i ) && $value =~ /[1-9]/ ) {
        $value = convert_date( $value, $date_format );
    }

    if ( defined $value ) {
        if ($value) {
            if ( $type =~ /^int\b/i ) {
                ## cast to integer type for positive integers ##
                $recast = int($value);
                if ($debug) { Message("Recast $field : $value to int"); Call_Stack(); }
            }
            elsif ( $type =~ /^(float|decimal)/i && $value =~ /^([+-]?\d+)(\.?)(\d*)$/ ) {
                my $int      = $1;
                my $decimal  = $2;
                my $fraction = $3;
                $recast = int($int);
                if ($fraction) {
                    my $divisor = 10**( length($fraction) );
                    $fraction = int($fraction);
                    $recast += $fraction / $divisor;
                }
            }
            else { $recast = $value }
        }
        else {
            ## defined but 'false' values ##
            if ( $type =~ /^(int|float|decimal)\b/i ) {
                ## Note:  if '' is a valid option (different from 0), then value should be NULL - otherwise, it will be reset to 0 ##
                $recast = 0;
            }
            elsif ( $type =~ /^(text|char|enum)\b/i ) { $recast = $value . '' }
            else {
                $recast = $value;    ## for both cases: '' and 0
            }
        }
    }
    else {
        $recast = undef;
    }

    return $recast;
}

################################################
#
# Convert input string to regexp search pattern
#
# Return : Regexp search pattern.
###########################
sub convert_to_regexp {
###########################
    my $string = shift;

    my $regexp = '%';
    if ( $string =~ /^\'(.*)\'$/ ) {
        $regexp = $1;
    }
    elsif ( $string =~ /^\"(.*)\"$/ ) {
        $regexp = $1;
    }
    elsif ( $string =~ /(\*|\?)/ ) {
        $regexp = $string;
        $regexp =~ s /\*/\%/g;
        $regexp =~ s /\?/_/g;
    }
    elsif ( $string =~ /\?/ ) {
        $regexp = $string;
    }
    elsif ( $string =~ /^./ ) {
        $regexp = "$string";    ## search for explicit string anywhere in target
    }
    else { return $string }     ## empty string
    return $regexp;
}

################################################
#
# Convert input string to search condition
#
# Return : search condition.
##############################
sub convert_to_condition {
##############################
    my %args = &filter_input( \@_, -args => 'string,field,type' );
    my $value       = $args{-string} || $args{-value};
    my $field       = $args{-field};
    my $type        = $args{-type} || '';
    my $range_limit = $args{-range_limit} || 0;          ## limit length range of strings converted to integer range (eg 101-500 => 'between 101 and 500')
    my $max_options = $args{-max_options} || 100;        ## limit of range of strings converted as comma-delimited list

    my @values;
    if   ( ref $value eq 'ARRAY' ) { @values = @{$value} }
    else                           { @values = ($value) }

    my @conditions;
    foreach my $string (@values) {
        my $cond = 1;
        if ( length($string) == 0 ) {next}

        if ( $string =~ /^([\>\<]\=?)([\d\s\:\-]+)$/ ) {
            my ( $op, $num ) = ( $1, $2 );
            if ( $type =~ /date/i ) {
                ## convert date if reqd ##
                $num = convert_date( $num, 'SQL', 'quote' );
            }
            $cond = "$field $op $num";    ## allows for Field >= 25.6 or Field < '2005-01-01'
        }
        elsif ( ( $string =~ /^(\-?\d*)\.?(\d*)?\s?\-\s?(\-?\d*)\.?(\d*)?$/ ) && eval($string) < 0 && ( !$range_limit || ( eval("0-($string)") <= $range_limit ) ) ) {
            ## numerical range only (eg '1.5 - 2.7')
            my ( $d1, $d2 );
            $d1 = $1 ? $1 : 0;
            if ($2) { $d1 .= '.' . $2 }

            $d2 = $3 ? $3 : 0;
            if ($4) { $d2 .= '.' . $4 }

            $cond = "$field BETWEEN $d1 AND $d2";
        }
        elsif ( $string =~ /^\s?\>?\s?([\d\-\:\s]+)\s[\-\<>]+\s([\d\-\:\s]+)$/ ) {    ## date range
            ## convert date if reqd ##
            my ( $d1, $d2 ) = ( $1, $2 );
            if ( $type =~ /date/i ) {
                $d1 = convert_date( $d1, 'SQL', -quote => 0 );
                $d2 = convert_date( $d2, 'SQL', -quote => 0 );
            }
            $cond = "$field BETWEEN '$d1' AND '$d2'";
        }
        elsif ( $string =~ /^[\d\.\,\s]+$/ && $type !~ /TEXT|CHAR/i ) {
            ## list of integers only ##
            ## for non-text type only ##
            $cond = "$field iN ($string)";
        }
        elsif ( $string =~ /^(null|undef)$/ ) {    ## NULL or undef
            $cond = "$field IS NULL";
        }
        elsif ( $string =~ /^empty$/ ) {
            $cond = "$field = ''";
        }
        elsif ( $string eq '0' ) {
            $cond = "($field=0 OR $field='' OR $field IS NULL)";
        }
        elsif ( $string =~ /[\*\?]/ ) {
            my $pattern = convert_to_regexp($string);
            $cond = "$field LIKE '$pattern'";
        }
        elsif ( $string =~ /[\%]/ ) {
            $cond = "$field LIKE '$string'";
        }
        elsif ( $string =~ /^(.*)\[(\d+)\-(\d+)\](.*)$/ ) {
            ### convert 'AB_[1-5]_C' => IN ('AB_1_C','AB_2_C','AB_3_C','AB_4_C','AB_5_C') ###
            my ( $prefix, $a1, $a2, $suffix ) = ( $1, $2, $3, $4 );
            my @options = ($string);    ## include the original string in case it is explicit ##

            my @elements = split /[\|\,]/, $string;
            foreach my $element (@elements) {
                if ( $element =~ /^(.*)\[(\d+)\-(\d+)\](.*)$/ ) {
                    my ( $prefix, $a1, $a2, $suffix ) = ( $1, $2, $3, $4 );
                    if ( ( $a2 > $a1 ) && ( $a2 - $a1 ) < $max_options ) {
                        foreach my $i ( $a1 .. $a2 ) { push @options, $prefix . $i . $suffix }
                    }
                    else { Message("Warning: $a1 - $a2 range too large - not converting") }
                }
                else {
                    push @options, $element;
                }
            }
            my $option_list = Cast_List( -list => \@options, -to => 'string', -autoquote => 1 );
            $cond = "$field In ($option_list)";
        }
        elsif ( $string =~ /([\|\,])/ ) {
            ## normal list of options
            my $delimiter = $1;
            my @list = split /\s*[\|\,]\s*/, $string;

            my @options;
            if ( $type =~ /date/i ) {
                ## convert date if reqd ##
                map {
                    if ( $type =~ /date/i )
                    {
                        $string = convert_date( $string, 'SQL', 'quote' );
                    }
                    push @options, $string;
                } @list;
            }
            else {
                @options = Cast_List( -list => \@list, -to => 'array', -autoquote => 1 );
            }

            if (@options) {
                $cond = "$field IN (";
                $cond .= join ",", @options;
                $cond .= ")";
            }
        }
        else {
            ## convert date if reqd ##
            if ( $type =~ /date/i ) {
                $string = convert_date( $string, 'SQL' );
            }

            # only add quotes if the string is already not quoted
            if ( $string !~ /^\'.*\'$/ ) {
                $string = "'$string'";
            }
            $cond = "$field = $string";
        }
        push @conditions, $cond;
    }
    my $condition = join ' OR ', @conditions;
    $condition ||= 1;

    return "($condition)";
}

##########################
#
#
# Return value after conversion
#################
sub convert_units {
#################
    my $qty         = shift;    ## original quantity
    my $start_units = shift;    ## units originally quoted
    my $end_units   = shift;    ## units to convert to
    my $quiet       = shift;    ## Suppress error messages

    if ( $start_units =~ /^$end_units$/i ) { return ( $qty, $start_units ); }
    elsif ( !$end_units ) { return ( $qty, $start_units ); }

    my ( $start,  $units1 ) = convert_to_mils( $qty, $start_units, undef, $quiet );
    my ( $invert, $units2 ) = convert_to_mils( $qty, $end_units,   undef, $quiet );

    my $end_qty = $qty;
    unless ( $units1 =~ /^$units2$/i ) {
        print "Warning: Cannot convert $units1 -> $units2" unless $quiet;
        return ( $qty, $start_units, 'error' );
    }
    if ($invert) {
        $end_qty = $qty * $start / $invert;
        print "** Converted $qty $start_units -> $end_qty $end_units.**" unless $quiet;
        return ( $end_qty, $end_units );
    }
    else {
        print "Warning: problem converting to $end_units." unless $quiet;
        return ( $qty, $start_units, 'error' );
    }
}

#########################
#  Convert time units to hours
#
#
#########################
sub normalize_time {
#########################

    my %args          = @_;
    my $time          = $args{ -time };
    my $units         = $args{-units};
    my $hours_in_day  = $args{-hours_in_day} || 8;
    my $days_in_month = $args{-days_in_month} || 22;    ## average working days...
    my $days_in_week  = $args{-days_in_week} || 5;      ## average working days...
    my $use           = $args{ -use };                  ## array reference to units used...
    my $truncate      = $args{ -truncate } || 0;
    my $set_units     = $args{-set_units} || '';        ## specify units to return .

    unless ($use) { $use = [ 'sec', 'min', 'hrs', 'days', 'wks', 'months' ] }

    my $multiplier = 1;

    if ( ( !( defined $time ) ) || ( !( defined $units ) ) ) {
        print "Units or time undefined ? ($time $units)\n";
        return ( $time, $units );
    }
    my ($hours) = convert_to_hours(
        -time         => $time,
        -units        => $units,
        -hours_in_day => $hours_in_day
    );
    my $converted = $hours;

    if ($set_units) {
        if ( $set_units =~ /sec/i ) {
            $converted = $hours * 60 * 60;
            $units     = 'sec';
        }
        elsif ( $set_units =~ /min/i ) {
            $converted = $hours * 60;
            $units     = 'min';
        }
        elsif ( $set_units =~ /month/i ) {
            $converted = $hours / $hours_in_day / $days_in_month;
            $units     = 'months';
        }
        elsif ( $set_units =~ /(wk|week)/i ) {
            $converted = $hours / $hours_in_day / $days_in_week;
            $units     = 'wks';
        }
        elsif ( $set_units =~ /day/i ) {
            $converted = $hours / $hours_in_day;
            $units     = 'days';
        }
        elsif ( $set_units =~ /(hr|hour)/i ) {
            $units = 'hr|hour';
        }
        elsif ( $set_units =~ /^FTE$/ ) {
            $units = 'FTE';
        }
        else {
            Message("Unit: $set_units Not recognized");
        }
    }
    else {
        if ( $hours < 1 / 60 ) {
            $converted = $hours * 60 * 60;
            $units     = 'sec';
        }
        elsif ( $hours < 1 ) {
            $converted = $hours * 60;
            $units     = 'min';
        }
        elsif ( $hours > $hours_in_day * $days_in_month ) {
            $converted = $hours / $hours_in_day / $days_in_month;
            $units     = 'months';
        }
        elsif ( $hours > $hours_in_day * 4 * $days_in_week ) {
            $converted = $hours / $hours_in_day / $days_in_week;
            $units     = 'wks';
        }
        elsif ( $hours > 2 * $hours_in_day ) {
            $converted = $hours / $hours_in_day;
            $units     = 'days';
        }
        else {
            $units = 'hr|hour';
        }
    }

    foreach my $unit (@$use) {
        if ( $unit =~ /^$units/i ) { $units = $unit }
    }
    ## allow truncation to only a couple of decimal places
    if ( $truncate && $converted > 100 ) {
        $converted = int($converted);
    }
    elsif ( $truncate && $converted > 1 ) {
        $converted = int( $converted * 100 ) / 100;
    }
    elsif ( $truncate && $converted > 0.1 ) {
        $converted = int( $converted * 1000 ) / 1000;
    }

    return ( $converted, $units );
}

#########################
# Add time argument to date
#########################
sub end_of_day {
#########################
    my $date      = shift;
    my $autoquote = shift;
    unless ( $date =~ /:/ ) {

        # add time in case user omits time argument (encompass whole $until day)
        $date .= " 23:59:59";
    }
    if ($autoquote) {
        return "'$date'";
    }
    else {
        return $date;
    }
}

#########################
#  Convert time units to hours
#
#
#########################
sub convert_to_hours {
#########################

    my %args         = @_;
    my $time         = $args{ -time };
    my $units        = $args{-units};
    my $hours_in_day = $args{-hours_in_day} || 8;

    my $multiplier = 1;

    if ( ( !( defined $time ) ) || ( !( defined $units ) ) ) {
        return ( $time, $units );
    }
    if ( $units =~ /hours/i ) {
        $multiplier = 1;
    }
    elsif ( $units =~ /min/i ) {
        $multiplier = 1 / 60;
    }
    elsif ( $units =~ /day/i ) {
        $multiplier = $hours_in_day;
    }
    elsif ( $units =~ /week/i ) {
        $multiplier = 5 * $hours_in_day;
    }
    elsif ( $units =~ /month/i ) {
        $multiplier = 20 * $hours_in_day;
    }

    my $converted_time = $time * $multiplier;
    return ( $converted_time, 'Units' );
}

########################################################
#  Find the number of weekdays given a date a range
###################
sub week_days {
###################
    my %args = @_;
    require Date::Calc;
    my $date_from = $args{-date_from};
    my $date_to   = $args{-date_to};

    my ( $year, $month, $day );

    if ( $date_from =~ /(\d+)-(\d+)-(\d+)/ ) {
        ( $year, $month, $day ) = ( $1, $2, $3 );
    }
    my @start = ( $year, $month, $day );
    if ( $date_to =~ /(\d+)-(\d+)-(\d+)/ ) {
        ( $year, $month, $day ) = ( $1, $2, $3 );
    }
    my @stop = ( $year, $month, $day );

    my $date_diff = Delta_Days( @start, @stop );
    my $week_days;
    for ( my $i = 0; $i <= $date_diff; $i++ ) {
        my @date = Add_Delta_Days( @start, $i );
        ## skip weekend
        if ( Day_of_Week(@date) =~ /6|7/i ) {
            next;
        }
        $week_days++;
    }
    return $week_days;
}

################################
#
# Converts anything to mils
# if quantity or units is undefined, returns arguments (essential to preserve undefined state)
#
# (Assumes either litres or grams)
#######################
sub convert_to_mils {
########################
    my $qty      = shift;    ## original quantity
    my $units    = shift;    ## original units (eg. mg / ml )
    my $decimals = shift;
    my $quiet    = shift;

    if ( $qty =~ /([pumkgl]+)/i ) {
        $units = $1;         ## allow for units supplied in qty field.
    }

    unless ( defined $qty && $units ) {
        return ( $qty, $units );
    }

    my $units_alias = '';
    my $multiplier  = 1;
    if ( $units =~ /^\s*(g|l)/i ) {    ## kilograms or litres ##
        $units_alias = $1;
        $multiplier  = 1000;
    }
    elsif ( $units =~ /^m(g|l)/i ) {    ## kilograms or litres ##
        $units_alias = $1;
        $multiplier  = 1;
    }
    elsif ( $units =~ /^u(g|l)/i ) {
        $units_alias = $1;
        $multiplier  = 1 / 1000;
    }
    elsif ( $units =~ /^n(g|l)/i ) {
        $units_alias = $1;
        $multiplier  = 1 / 1000000;
    }
    elsif ( $units =~ /^p(g|l)/i ) {
        $units_alias = $1;
        $multiplier  = 1 / 1000000000;
    }
    elsif ( $units =~ /^k(g|l)/i ) {
        $units_alias = $1;
        $multiplier  = 1000000;
    }
    else {
        unless ($quiet) {
            Message("Warning : Units other than litre or gram found: $units");

            #RGTools::RGIO::Call_Stack();
            return ( 0, 'Unknown' );
        }
    }
    my $end_qty = $qty * $multiplier;

    if ( $decimals && $end_qty > 0 ) {    ##### if large number reduce number of decimal points..
        my $format = "%0.$decimals" . "f";
        $end_qty = sprintf( $format, $end_qty );
    }

    return ( $end_qty, 'm' . $units_alias );
}

###############################
# Subroutine: takes in a scalar representing a well ie A01, a1, p4 P04
# Return: a string representing the same well, but uppercased and removed/added zero-padding depending on switches. By default, pads the wells.
###############################
sub format_well {
############################
    my $well       = shift;              # (Scalar) a well string
    my $zero_pad   = shift || 'pad';     # (Scalar) format command - either 'pad' or 'nopad'
    my @well_array = split ',', $well;
    foreach (@well_array) {

        # uppercase
        $_ = uc($_);
        if ( $zero_pad eq "nopad" ) {
            $_ =~ s/(\w{1})\Q0\E(\d{1})/$1$2/i;
        }
        else {

            # pad well
            $_ =~ s/^(\w)(\d)$/$1\Q0\E$2/;
        }
    }
    return join ',', @well_array;
}

################
sub SQL_well {
################
    my $field = shift;

    return "CASE WHEN LENGTH($field) > 2 THEN UPPER($field) ELSE UPPER( CONCAT(LEFT($field,1), '0' , RIGHT($field,1))) END";
}

######################
#
# Convert a string with * or ? wildcards to SQL format (using %, _)
#
#
#
######################
sub wildcard_to_SQL {

    my $pattern = shift;

    $pattern =~ s /\*/%/g;    ## <CONSTRUCTION> - move to a wildcard_SQL conversion method
    $pattern =~ s /\?/\_/g;

    return $pattern;
}

################
sub SQL_hours {
################

    my $number      = shift;
    my $units       = shift;
    my $HPD         = shift || 7;    ## hours per day for calculation
    my $case_option = shift || '';
    my $round       = shift || 1;

    if ( $number && $units ) {
        return
            "CASE $case_option WHEN $units LIKE 'Hour%' THEN ROUND($number,$round) WHEN $units LIKE 'Day%' THEN ROUND($number * $HPD,$round) WHEN $units LIKE 'Week%' THEN ROUND($number * $HPD * 7,$round) WHEN $units LIKE 'Month%' THEN ROUND($number*$HPD*30,$round) WHEN $units like 'Minute%' THEN ROUND($number/60,$round) ELSE ROUND($units,$round) END";
    }
    else {
        return $number;
    }
}

######################
sub text_SQL_date {
######################
    my $field = shift;

    return "concat(Left(DayName($field),3),'_',Left(MonthName($field),3),'_',DayofMonth($field))";
}
#############################################
#
# Convert date to and from SQL format
#  (allows for inclusion of wildcard characters for day and month using * or %).
#
#  (allows for custom formatting using YYYY or YY, DD, MM or Mon, TIME in the format specification)
#
# 'SQL' format converts from 'Jun-24-2001' to '06-24-2001'
# 'Simple' format converts from '06-24-2001' to 'Jun-24-2001'
# 'DD Mon / 2005' converts to '24 Jun / 2005'
#
# Return: converted date
#######################
sub convert_date {
#######################
    my %args = filter_input( \@_, -args => 'date,format,quote' );
    my $date   = $args{-date}     || 0;        ## input date (eg 'Jun 2nd, 2005' or '2006-01-15')
    my $format = $args{'-format'} || 'SQL';    ## format ('SQL' -> 2005-01-31', 'Simple' -> 'Jan-01-2005', or Custom: 'Mon DD/YY'-> Jan 31/2005
    my $quote        = $args{-quote};          ## return quoted date.
    my $date_tooltip = $args{-date_tooltip};   ## can override by simply suppying -web=>0
    my $invalid      = $args{-invalid};        ## Return 'invalid' if the date cannot be recognized (instead of just Message)

    unless ( $date =~ /[1-9]/ ) {
        return 'invalid' if $invalid;

        # if there is no date specified, return a blank string
        return '0000-00-00';
    }

    if ( $date =~ /^\'(.*)\'/ ) {
        $date = $1;

        ## return quoted date if supplied with quoted date, and quote not specified ##
        if ( !defined $quote ) { $quote = 1 }
    }

    my $newdate = $date;

    ## replace with Decode_Month if avail...
    my $Month;
    $Month->{JAN} = '01';
    $Month->{FEB} = '02';
    $Month->{MAR} = '03';
    $Month->{APR} = '04';
    $Month->{MAY} = '05';
    $Month->{JUN} = '06';
    $Month->{JUL} = '07';
    $Month->{AUG} = '08';
    $Month->{SEP} = '09';
    $Month->{OCT} = '10';
    $Month->{NOV} = '11';
    $Month->{DEC} = '12';

    my ( $year, $month, $day, $time ) = ( '%', '%', '%', '' );

    #
    # Tidied up date conversion below by simplifying many cases which can be resolved by process of elimination
    #   eg \d\d\d\d -> year
    #   [a-z]{3}    -> month
    #   remaining digits (1 or 2) -> day
    #
    #   If all of the above are resolved, then the date is resolved...
    #   commenting out (for now) blocks that are unnecessary - delete commented out blocks following next release if no problems...
    #

    if ( $date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)(.*)/ ) {
        ## YYYY-MM-DD ## (standard SQL) ##
        ( $year, $month, $day, $time ) = ( $1, $2, $3, $4 );

    }

    #    elsif ( $date =~ /^([a-zA-Z]{3})[a-zA-Z]*[-\s\/]{1}(\d{1,2})[-\s\/\,]{1,2}(\d\d\d\d)(.*)/ ) {
    #        ## Apr 03, 1975 ## 'Simple' Format   ## also understands 'April 3, 1975'
    #        ( $month, $day, $year, $time ) = ( $1, $2, $3, $4 );
    #    }
    elsif ( $date =~ /^([a-zA-Z]{3})[a-zA-Z]*[-\s\/]{1}(\d{1,2})[-\s\/\,]{1,2}(\d\d)$/ ) {
        ## Apr 03/75 ## 'Simple' Format   ## also understands 'April 3, 00'
        ( $month, $day, $year, $time ) = ( $1, $2, $3, $4 );
        ## assume years after '70 are 1970 & up...
        if   ( $year >= 70 ) { $year += 1900 }
        else                 { $year += 2000 }
    }
    elsif ( $date =~ /^(\d\d\d\d)[-\s\/]{1}([\d\*\%]{1,2})[-\s\/\,]{1,2}([\d\*\%]{1,2})(.*)/ ) {
        ######### Extend flexibility for SQL searching in date field by allowing wildcards and less common formats #######
        ## 2001-*-*                              ## Allow wildcards in SQL format ##
        ( $year, $month, $day, $time ) = ( $1, $2, $3, $4 );
    }

    # These are covered with replacement block at bottom...
    #
    #
    #    elsif ( $date =~ /^([a-zA-Z]{3})[a-zA-Z]*[-\s\/]{1}([\d\*\%]{1,2})(nd|st|rd|th|)[-\s\/\,]{1,2}(\d\d\d\d)(.*)/ ) {
    #        ### Format = Apr-*-2001 ####
    #        ( $month, $day, $year, $time ) = ( $1, $2, $4, $5 );
    #    }
    #    elsif ( $date =~ /^([\d\*\%]{1,2})[\-\s\/\,]{1,2}([a-zA-Z]{3})[a-zA-Z]*[\-\s\/\,]{1,2}(\d\d\d\d)(.*)/ ) {
    #        ### Format = 02 February 2001 ####
    #        ( $day, $month, $year, $time ) = ( $1, $2, $3, $4 );
    #    }
    #
    #    ## Allow English names for Months ##
    elsif ( $date =~ /^([\d\*\%]{1,2})[\-\s\/\,]{1,2}([a-zA-Z]{3})[a-zA-Z]*[\-\s\/\,]{1,2}(\d\d)\b(.*)/ ) {
        ### Format = 02 Feb 01 ####
        ( $day, $month, $year, $time ) = ( $1, $2, $3, $4 );
        if   ( $year > 50 ) { $year = 1900 + $year }    ## assume year is in the late 1900s.
        else                { $year = 2000 + $year }    ## assume year is > 2000
    }
    elsif ( $date =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/ ) {
        ## standard timestamp ##
        ( $year, $month, $day, $time ) = ( $1, $2, $3, " $4:$5:$6" );
    }
    else {
        ## no standard formats... so just check if unambigous by elimination ...
        my $replace = $date;
        if ( $replace =~ s/\b(\d\d\d\d)\b// )             { $year  = $1 }
        if ( $replace =~ s/\b([a-zA-Z]{3})[a-zA-Z]*\b// ) { $month = $1 }
        if ( $year && $month && $replace =~ /\b(\d\d?)\b/ )       { $day = $1 }
        if ( $year && $month && $replace =~ /\b([\d\%]{1,2})\b/ ) { $day = $1 }    ## allow wildcard in day

        # Preserve the time if present, otherwise it may cause problems e.g. for comparisons where dates are the same but times are different
        if ( $replace =~ /(.*)(\d\d:\d\d:\d\d)$/ ) { $time = ' ' . $2 }

        if ( !$day ) {
            Message("Date field ambiguous - please change it to YYYY-MM-DD in text format");
            return 'invalid' if $invalid;
        }
    }

    $month = $Month->{ uc( substr( $month, 0, 3 ) ) } if defined $Month->{ uc( substr( $month, 0, 3 ) ) };    # convert from 'February' -> 2

    $year  = sprintf "%04d", $year  if $year  =~ /\d+/;
    $month = sprintf "%02d", $month if $month =~ /\d+/;
    $day   = sprintf "%02d", $day   if $day   =~ /\d+/;

    if ( $format =~ /Simple/i ) {                                                                             ### Convert FROM SQL
        if ( $day . $month . $year =~ /[\*\%]/ ) {
            $format = 'Mon-DD-YYYY TIME';
        }                                                                                                     ## use format option below if wildcards...
        else {
            my $date = strftime( '%b-%d-%Y', 0, 0, 0, $day, $month - 1, $year - 1900 );
            $newdate = $date . $time if $date;
        }
    }
    elsif ( $format =~ /SQL/ ) {
        $newdate = "$year-$month-$day" . $time;
    }

    if ( $format =~ /(DD|MM|YY)/i || $format =~ /(Year|Mon|Day)/i ) {
        ##  Allow custom formats using replacement options: YYYY, YY, DD, MM, Mon, TIME
        $newdate = $format;

        if ( $time =~ /(\d\d):(\d\d):(\d\d)/ ) {
            my ( $hour, $minute, $second ) = ( $1, $2, $3 );
            $newdate =~ s/TIME/HOUR:MINUTE:SECOND/;

            $newdate =~ s /HOUR/$hour/;
            $newdate =~ s /MINUTE/$minute/;
            $newdate =~ s /SECOND/$second/;
        }
        elsif ( !$time ) {
            $newdate =~ s/\s+TIME/$time/;
        }
        else {
            $newdate =~ s/TIME/$time/;
        }

        $newdate =~ s /DD/$day/;
        $newdate =~ s /MM/$month/;
        $newdate =~ s /YYYY/$year/;

        my $yr = substr( $year, 2, 2 );
        $newdate =~ s /YY/$yr/;

        if ( $newdate =~ /Mon/ ) {
            foreach my $month_name ( keys %$Month ) {
                if ( $Month->{$month_name} == $month ) {
                    $month = uc( substr( $month_name, 0, 1 ) ) . lc( substr( $month_name, 1, 2 ) );
                    last;
                }
            }
            $newdate =~ s /Mon/$month/;
        }

    }
    unless ( $newdate =~ /\d/ ) { $newdate = $date; }
    $newdate =~ s /\*/%/g;    ## convert * wildcards to '%' (SQL compatible).

    if ($quote) {
        $newdate = "'$newdate'";
    }

    if ($date_tooltip) {
        ## check for cgi-bin to enable standard usage of this feature on non-interface based scripts ##

        ## show date as tooltip to avoid messing up sorting functions ##
        return Show_Tool_Tip( $date, $newdate );
    }
    return $newdate;
}

#######################
# Enables use of format 'Min.Sec' for tracking minutes and seconds.
#  other formats are consistent with SQL standard (N -> 00::00:N; M:N -> M:N:0)
#  (also enables passage of '1 m' or '500 s' - converted to SQL time format)
#
# return time (in SQL time format) - return 0 if unrecognized format.
######################
sub convert_time {
######################
    my $time  = shift;
    my $units = shift || 's';
    my $quote = 0;

    if ( $time =~ /^\'(.*)\'/ ) { $time = $1; $quote++; }

    if ( $time =~ /([\d\.\:]+)\s*([smh])/i ) { $time = $1; $units = $2; }
    if ( $time =~ /\:/ ) {
        ## this format is ok... just leave it
    }
    elsif ( $time =~ /^\s*(\d+)\.(\d+)\s*$/ ) {
        $time =~ s /\./\:/g;
        $time = "00:$time";    ## convert to minutes: 1.2 -> 00:01:02
    }
    elsif ( $time =~ /^(\d+)$/ ) {
        if ( $units =~ /^h/ ) { return "$1:00:00" }
        elsif ( $units =~ /^m/ ) {
            my $hours = int( $time / 60 ) || '0';
            my $min = $time;
            $min  = $time - $hours * 60;
            $time = "$hours:$min:00";
        }
        elsif ( $units =~ /^s/ ) {
            my $minutes = int( $time / 60 )    || '0';
            my $hours   = int( $minutes / 60 ) || '0';
            my $min = $minutes - $hours * 60;

            my $sec = $time - $hours * 60 * 60 - $min * 60;
            $time = "$hours:$min:$sec";
        }
    }

    if   ($quote) { return "'$time'"; }
    else          { return $time }
}

#########################
# Returns string for day
# eg SQL_day('2005-11-30') = 'Wed. Nov 30/2005'
#
##############
sub SQL_day {
##############
    my $date = shift;

    unless ( $date =~ /[a-zA-Z]/ ) { $date = "'$date'"; }
    return "concat(Left(DayName($date),3),'. ',Left(MonthName($date),3),' ',DayofMonth($date),'/',Year($date))";
}

#######################
sub SQL_weekdays {
#######################
    my $from = shift;
    my $to   = shift;

    $from = "'$from'" unless $from =~ /^\'/;
    $to   = "'$to'"   unless $to   =~ /^\'/;

    my $order1 = $from;
    my $order2 = $to;
    $order1 =~ s/\W//g;
    $order2 =~ s/\W//g;
    if ( $order1 > $order2 ) {    ## reverse order ##
        my $temp = $from;
        $from = $to;
        $to   = $temp;
    }

    my $diff      = "(TO_DAYS($to) - TO_DAYS($from))";
    my $weeks     = "FLOOR($diff/7)";
    my $remainder = "$diff - FLOOR($diff/7)*7";

    my $extra_days
        = "CASE WHEN DayName($from) = 'Sunday' THEN Least($remainder,1) "
        . "WHEN $remainder-WeekDay($from)-2 < 0 THEN Least($remainder-2,$remainder-1,$remainder) "
        . "WHEN $remainder-WeekDay($from)-2 = 0 THEN Least($remainder-1,$remainder) "
        . "WHEN $remainder-WeekDay($from)-2 > 0 THEN $remainder " . "END";

    #    print "R: $remainder as Remaind<BR>";
    #    print "D: 5*$weeks as WeekDays<BR>";
    #    print "X: $extra_days as extra<BR>";

    my $weekdays = "5*$weeks + $extra_days as Weekdays";

    return $weekdays;
}

###########################
sub translate_date {
###########################
    my %args = &filter_input( \@_ );
    my $date = $args{-date};

    my %date_tags = (
        'TODAY'     => '',
        'YESTERDAY' => '-1d',
        'LASTDAY'   => '-1d',
        'LASTWEEK'  => '-7d',
        'LASTMONTH' => '-30d',
        'LASTYEAR'  => '-365d',
    );

    $date = uc($date);

    if ( defined $date_tags{$date} ) {
        return date_time( -offset => $date_tags{$date} );
    }
    else {
        Message("Warning: Unknown tag ($date)");
        return $date;
    }
}

##########################################
# Convert a hash of indexes to arrays to an array of references
# (each with similar keys to the original hash, and scalars for values)
#
# Return reference to array
############################
sub convert_HofA_to_AofH {
######################
    my $hash       = shift;    ## data in hash form
    my $KEY        = shift;    ## return hash keyed to this field instead of an array.
    my $order      = shift;    ## order hash (if keys chosen).
    my $stack_keys = shift;    ## Flag to determine if two records of the same key will be stacked (as an array of hashes) or just overwritten

    my %data = %{$hash};

    my @keys = keys %data;

    unless ( defined $data{ $keys[0] } && $data{ $keys[0] } ) {
        if ($KEY) { return {}; }
        else      { return []; }
    }

    my $records = int( @{ $data{ $keys[0] } } );

    my @array_data = ();
    my %keyed_data;
    foreach my $index ( 1 .. $records ) {
        my $this_key = '';
        foreach my $sub_key ( split ',', $KEY ) {
            $this_key .= $data{$sub_key}[ $index - 1 ];
        }
        my %thisrecord = map { $_, $data{$_}->[ $index - 1 ] } keys %data;
        if ($KEY) {
            if ( $stack_keys && defined $keyed_data{$this_key} ) {
                if ( ref( $keyed_data{$this_key} ) ne 'ARRAY' ) {
                    $keyed_data{$this_key} = [ $keyed_data{$this_key} ];
                }
                push( @{ $keyed_data{$this_key} }, \%thisrecord );
            }
            else {
                $keyed_data{$this_key} = \%thisrecord;
            }
            if ($order) {
                $keyed_data{order}[ $index - 1 ] = $this_key;
            }    ## generate ordered list if desired
        }
        else {
            push( @array_data, \%thisrecord );
        }
    }

    if ($KEY) {

        #	print "return hash (on $KEY)\n";
        return \%keyed_data;
    }
    else {

        #	print "Return array_ref\n";
        return \@array_data;
    }
}

##########################################
# Convert a hash of indexes to arrays to an array of references
# (each with similar keys to the original hash, and scalars for values)
#
# Return reference to hash
############################
sub convert_HofA_to_HHofA {
######################
    my $hash = shift;    ## data in hash form
    my $KEY  = shift;    ## return hash keyed to this field instead of an array.

    my @KEY_HASH_LIST = Cast_List( -list => $KEY, -to => 'array' );
    my %data          = %{$hash};
    my @keys          = keys %data;
    my %key_hash;

    for my $key_hash (@KEY_HASH_LIST) {
        if ( !$hash->{$key_hash} ) { return $hash }    #KEY not found in hash, do nothing.
    }

    for ( my $index = 0; $index <= $#{ $hash->{ $KEY_HASH_LIST[0] } }; $index++ ) {
        my $new_key;
        for my $key_hash (@KEY_HASH_LIST) {
            if ( !$new_key ) { $new_key = $hash->{$key_hash}[$index] }
            else             { $new_key .= "-$hash->{$key_hash}[$index]" }
        }
        for my $key (@keys) {
            push @{ $key_hash{$new_key}{$key} }, $hash->{$key}[$index];
        }
    }
    return \%key_hash;
}

####################
sub get_units {
####################
    #
    # return readable units given amount...
    #
    my $amount   = shift;
    my $units    = shift;
    my $decimals = ( defined $_[0] ) ? $_[0] : 2;

    my $base    = '';
    my $unknown = 0;
    my $mils    = 0;

    if    ( $units =~ /l/i ) { $base    = 'L'; }
    elsif ( $units =~ /g/i ) { $base    = 'g'; }
    else                     { $unknown = 1; }

    ######## convert to mils.... ###########3

    if    ( $units =~ /^u/i )    { $mils = $amount / 1000; }
    elsif ( $units =~ /^m/i )    { $mils = $amount; }
    elsif ( $units =~ /^[lg]/i ) { $mils = 1000 * $amount; }
    elsif ( $units =~ /^k/i )    { $mils = 1000 * 1000 * $amount; }
    elsif ( $units =~ /^n/i )    { $mils = $amount / 1000000; }
    else                         { $mils = $amount; $unknown = 1; }

    if ($unknown) {
        return "$amount units";
    }

    my @prefixes = ( 'n', 'u', 'm', '', 'k' );

    my $prefix_index = 2;
    while ( ( $mils >= 1000 ) && ( $prefix_index < 4 ) ) {
        $mils /= 1000;
        $prefix_index++;
    }
    while ( ( $mils < 1 ) && ( $prefix_index > 0 ) ) {
        $mils *= 1000;
        $prefix_index--;
    }
    my $format = "%0.$decimals" . "f";
    $mils = sprintf( $format, $mils );

    return "$mils $prefixes[$prefix_index]$base";
}

####################
sub normalize_units {
####################
    #
    # convert units to ml or mg (returning base unit as second parameter)...
    #
    my $amount   = shift;
    my $units    = shift;
    my $decimals = shift;    ## (defined $_[0]) ? $_[0]:2;

    my $base = 'mL';

    ######### if amount contains units, reset units as specified... ###########
    my $mils;
    if ( $amount =~ /([\d\.]+)\s?([a-zA-Z]+)/ ) { $mils = $1; $units = $2; }
    else                                        { $mils = $amount; $units ||= 'mL'; }

    if ( ( $mils =~ /g/i ) || ( $units =~ /g/i ) ) {
        $base = 'mg';
    }                        ### allow g to override ml (should be checked first since base units may be mL by default
    elsif ( ( $mils =~ /l/i ) || ( $units =~ /l/i ) ) { $base = 'mL'; }

    $units =~ s/\s//g;       ##### remove any spaces if they exist...

    ######## convert to mils or mg.... ###########3
    #    print "Checking $mils-$units.",br();
    if ( ( $mils =~ /^u/i ) || ( $units =~ /^u/i ) ) { $mils = $mils / 1000; }
    elsif ( ( $mils =~ /^m/i ) || ( $units =~ /^m/i ) ) { }
    elsif ( ( $mils =~ /^[lg]/i ) || ( $units =~ /^[lg]/i ) ) {
        $mils = 1000 * $mils;
    }
    elsif ( ( $mils =~ /^k/i ) || ( $units =~ /^k/i ) ) {
        $mils = 1000 * 1000 * $mils;
    }
    elsif ( ( $mils =~ /^n/i ) || ( $units =~ /^n/i ) ) {
        $mils = $mils / 1000000;
    }

    #     (what if 0.0000045 ? - do not sprintf...)
    if ( $decimals && $mils > 1 ) {    ##### if large number reduce number of decimal points..
        my $format = "%0.$decimals" . "f";
        $mils = sprintf( $format, $mils );
    }

    $mils += 0;                        #### return only number...
    return ( $mils, $base );
}

####################
sub simplify_units {
####################
    #
    # convert units more readable format...
    #
    my $amount   = shift;
    my $units    = shift;
    my $decimals = ( defined $_[0] ) ? $_[0] : 2;

    my $base = 'ml';

    ######### if amount contains units, reset units as specified... ###########
    my $mils;
    if   ( !$units && $amount =~ /([\d\.]+)\s?([a-zA-Z]+)/ ) { $mils = $1;      $units ||= $2; }
    else                                                     { $mils = $amount; $units ||= 'mL'; }

    if ( ( $mils =~ /g/i ) || ( $units =~ /g/i ) ) {
        $base = 'mg';
    }    ### allow g to override ml (should be checked first since base units may be mL by default
    elsif ( ( $mils =~ /l/i ) || ( $units =~ /l/i ) ) { $base = 'ml'; }

    $units =~ s/\s//g;    ##### remove any spaces if they exist...

    unless ($amount) { return ( $amount, $base ); }    ########### if zero

    ######## convert to mils.... ###########3

    my $unknown = 0;
    if ( $units =~ /mole/i ) { $mils = $amount; $unknown = 1; }
    elsif ( $units =~ /^u/ )     { $mils = $amount / 1000; }
    elsif ( $units =~ /^m/ )     { $mils = $amount; }
    elsif ( $units =~ /^[lg]/i ) { $mils = 1000 * $amount; }
    elsif ( $units =~ /^k/i )    { $mils = 1000 * 1000 * $amount; }
    elsif ( $units =~ /^n/ )     { $mils = $amount / 1000000; }
    elsif ( $units =~ /^p/ )     { $mils = $amount / 1000000000; }
    else                         { $mils = $amount; $unknown = 1; }

    if ($unknown) {
        return ( $amount, $units );
    }

    my @prefixes = ( 'p', 'n', 'u', 'm', '', 'k' );

    my $prefix_index = 3;
    while ( ( $mils >= 1000 ) && ( $prefix_index < 5 ) ) {
        $mils /= 1000;
        $prefix_index++;
    }
    while ( ( $mils < 1 ) && ( $prefix_index > 0 ) ) {
        $mils *= 1000;
        $prefix_index--;
    }

    my $format = "%0.$decimals" . "f";
    $mils = sprintf( $format, $mils );
    unless ($mils) {
        return ( $mils, $base );
    }    ########### if very close to zero

    my $new_prefix = $prefixes[$prefix_index];
    $base =~ s /m/$new_prefix/;

    return ( $mils, $base );
}

#############################
sub get_standard_unit_bases {
#############################
    return ('moles');

}

#############################
sub units_base_Match {
#############################
    # returns Bolean to check and see if two units have same base
    #
#############################
    my %args   = filter_input( \@_, -args => 'first,second' );
    my $first  = $args{-first};
    my $second = $args{-second};

    if ( !$first || !$second ) {return}

    my @non_standard = ( 'pcs', 'Animals', 'boxes', 'Cells', 'Million Cells', 'Embryos', 'Gram of Tissue', 'tubes', 'Organs', 'Sections', 'cfu', 'rxns', 'ul/well' );

    $first  =~ s/grams/g/i;
    $second =~ s/grams/g/i;
    $first  =~ s/litres/g/i;
    $second =~ s/litres/g/i;

    if ( grep {/(\b$first)\b/} @non_standard ) {
        if   ( $first eq $second ) { return 1 }
        else                       {return}
    }
    elsif ( $first =~ /(\w+)\/(\w+)/ || $second =~ /(\w+)\/(\w+)/ ) {
        my $first_top     = $1;
        my $first_bottom  = $2;
        my $second_top    = $3;
        my $second_bottom = $4;

        my $first_top_base     = _get_Units_Base($first_top);
        my $first_bottom_base  = _get_Units_Base($first_bottom);
        my $second_top_base    = _get_Units_Base($second_top);
        my $second_bottom_base = _get_Units_Base($second_bottom);

        if   ( ( $first_top_base eq $second_top_base ) && ( $first_bottom_base eq $second_bottom_base ) ) { return 1 }
        else                                                                                              {return}

    }
    else {
        my $first_base  = _get_Units_Base($first);
        my $second_base = _get_Units_Base($second);
        if   ( $first_base eq $second_base ) { return 1 }
        else                                 {return}
    }

    return;
}

#############################
sub _get_Units_Base {
#############################
    my %args = filter_input( \@_, -args => 'unit' );
    my $unit = $args{-unit};

    if ( $unit =~ /^\w$/ ) {
        return $unit;
    }
    elsif ( $unit =~ /^\w(\w+)$/ ) {
        return $1;
    }

}

#############################
# Get the best units
#############################
sub Get_Best_Units {
#####################
    my %args     = filter_input( \@_, -args => 'amount,units,base,decimals' );
    my $amount   = $args{-amount};                                               # Amount
    my $units    = $args{-units};                                                # Current units (e.g. uL)
    my $base     = $args{-base};                                                 # Base (e.g. L).  If not provided, then assumed to be the last letter in the units.
    my $decimals = $args{-decimals};

    #add list support
    my @amount_list = Cast_List( -list => $amount, -to => 'array' );
    my @units_list  = Cast_List( -list => $units,  -to => 'array' );

    #only go through lists if amount and units have the same >1 size
    if ( int(@amount_list) > 1 && int(@units_list) > 1 && int(@amount_list) == int(@units_list) ) {
        my @new_amount_list;
        my @new_units_list;

        #call Get_Best_Units for each one and return a list
        for ( my $index = 0; $index <= $#amount_list; $index++ ) {
            my ( $new_amount, $new_units ) = &Get_Best_Units( $amount_list[$index], $units_list[$index], $base, $decimals );
            push @new_amount_list, $new_amount;
            push @new_units_list,  $new_units;
        }
        my $return_amount_list = join ",", @new_amount_list;
        my $return_units_list  = join ",", @new_units_list;
        return ( $return_amount_list, $return_units_list );
    }

    my $prefix;
    my $std_units = join '|', get_standard_unit_bases();

    if ($base) {
        ($prefix) = $units =~ /^([A-Za-z]{0,1})$base$/;
    }
    elsif ( $units =~ /^([A-Za-z]{0,1})($std_units)$/ ) {
        $prefix = $1;
        $base   = $2;
    }
    elsif ( length($units) == 1 ) {
        $prefix = '';
        $base   = $units;
    }
    else {
        ( $prefix, $base ) = $units =~ /^([A-Za-z]{0,1})([A-Za-z\/]{0,4})$/;    # Also need to handle units e.g. ng/uL
    }

    unless ( abs($amount) > 0 ) {
        return ( $amount, $base );
    }    ## if no value to begin with ...

    #unless ($base) {print "Please specify a base.<BR>\n"; return '';}

    my @prefixes = ( 'y', 'z', 'a', 'f', 'p', 'n', 'u', 'm', '', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y' );    # From 1e-24 to 1e24

    # Get the current prefix index
    my $index;
    for ( $index = 0; $index <= $#prefixes; $index++ ) {
        if ( $prefix eq $prefixes[$index] ) {last}
    }

    unless ($index) {
        print "Prefix '$prefix' not supported.<BR>\n";
        return '';
    }

    while ( abs($amount) >= 1000 ) {
        $amount /= 1000;
        $index++;
    }
    while ( abs($amount) < 1 ) {
        $amount *= 1000;
        $index--;
    }

    if ($decimals) {
        my $format = "%0.$decimals" . "f";
        $amount = sprintf( $format, $amount );
    }

    return ( $amount, "$prefixes[$index]$base" );
}

#################
sub get_number {
#################
    #
    # print out a number (reduce to K or M if long)
    #
    my $number = shift;

    $number =~ s/\s+//g;

    if    ( $number =~ /^([\d\.]+)k$/ ) { return 1000 * $1; }
    elsif ( $number =~ /^([\d\.]+)M$/ ) { return 1000 * 1000 * $1; }
    elsif ( $number =~ /^([\d\.]+)G$/ ) { return 1000 * 1000 * 1000 * $1; }
    elsif ( $number =~ /^([\d\.]+)T$/ ) { return 1000 * 1000 * 1000 * 1000 * $1; }
    elsif ( $number =~ /^([\d\.]+)m$/ ) { return $1 / 1000.0; }
    elsif ( $number =~ /^([\d\.]+)u$/ ) { return $1 / 1000.0 / 1000.0; }
    else                                { return $number; }
}

###########
sub number {
###########
    #
    # print out a number (reduce to K or M if long)
    #
    my $number    = shift;
    my $decimals  = shift;
    my $separator = shift;    ### include original number if

    my $new_number = $number;
    if ( $number > 1000000000 ) {
        $new_number = int( $number / 10000000 ) / 100 . "G";

    }
    elsif ( $number > 1000000 ) {
        $new_number = int( $number / 10000 ) / 100 . "M";
    }
    elsif ( $number > 10000 ) {
        $new_number = int( $number / 10 ) / 100 . "K";
    }
    ###### check smallest to biggest if less than 1;
    elsif ( $number < 0.000000001 ) { $new_number = '0'; }    ### if < 0.001 u
    elsif ( $number < 0.001 ) {
        $new_number = int( $number * 1000000000 ) / 1000 . "u";
    }
    elsif ( $number < 1 ) {
        $new_number = int( $number * 1000000 ) / 1000 . "m";
    }

    if ($decimals) {
        $new_number =~ s/(\d\.\d{0,$decimals})\d+/$1/;
    }

    if ( $separator && ( $new_number ne $number ) ) {
        if ( $separator =~ /</ ) {
            $new_number = "<B>$new_number</B>";
        }    ## if html format detected for separator
        $new_number .= $separator . "[$number]";
    }
    return $new_number;
}

#######################
sub Convert_Case {
#######################
    my $string = shift;
    my $case   = shift;    # either can be 'upper' or 'lower'
    my $range  = shift;    # which letters to apply (in a range).  If not provide, then all letters are applied.

    my $before;
    my $match;
    my $after;
    my $len = length($string);

    if ( $range =~ /(\d+)-(d+)/ ) {    # Range provided.
        $before = substr( $string, 0,      $1 );
        $match  = substr( $string, $1,     $2 - $1 + 1 );
        $after  = substr( $string, $2 + 1, $len - $2 - 1 );
    }
    elsif ( $range =~ /(\d+)/ ) {      # Only apply to 1 letter.
        $before = substr( $string, 0,      $1 );
        $match  = substr( $string, $1,     1 );
        $after  = substr( $string, $1 + 1, $len - $1 - 1 );
    }
    else {                             # No range provided. Apply to all characters.
        $before = '';
        $match  = $string;
        $after  = '';
    }

    if ( $case =~ /upper/i ) {
        $string = $before . uc($match) . $after;
    }
    elsif ( $case =~ /lower/i ) {
        $string = $before . lc($match) . $after;
    }

    return $string;
}

#####################################################
# Allow user to specify a custom conversion scale
# and convert the value to either the specified units
# or the optimal units
#####################################################
sub Custom_Convert_Units {
    my %args = @_;

    my $value           = $args{-value};             # The value to convert from
    my $units           = $args{-units};             # The value units to conver from
    my $scale           = $args{-scale};             # The scale to be used. Must start from lowest to highest.
    my $scale_units     = $args{ - scale_units };    # The scale units to be used. Must start from lowest to highest.
    my $converted_units = $args{-to} || 'auto';      # The units to conver to.  Default is 'auto', in which the optimal units is automatically determined.
    my $decimals        = $args{ - decimals };       # The number of decimals to display for the converted value

    $scale       = Cast_List( -list => $scale,       -to => 'arrayref' );
    $scale_units = Cast_List( -list => $scale_units, -to => 'arrayref' );

    # Check inputs
    unless ( defined $value && defined $units && defined $scale && defined $scale_units ) {
        print "Missing arguments.<br>\n";
        return;
    }
    unless ( int(@$scale) == int(@$scale_units) ) {
        print "The number of elements in -scale (" . int(@$scale) . ") does NOT match the number of elements in -scale_units (" . int(@$scale_units) . ").<br>\n";
        return;
    }
    unless ( grep /^$units$/i, @$scale_units ) {
        print "The units provided ($units) is invalid.<br>\n";
        return;
    }
    unless ( ( $converted_units =~ /auto/i ) || ( grep /^$converted_units$/i, @$scale_units ) ) {
        print "The units to convert to ($converted_units) is invalid.<br>\n";
        return;
    }
    unless ( ( !defined $decimals ) || $decimals =~ /^\d+$/ ) {
        print "You can only specify numeric values for the -decimal arugment.<br>\n";
        return;
    }

    # Figure out the current scale index
    my $curr_index = 0;
    foreach my $su (@$scale_units) {
        if ( $su =~ /^$units$/i ) {last}
        $curr_index++;
    }

    # Now do the conversion
    my $converted_value = $value;
    if ( $converted_units =~ /auto/i ) {    # Automatically figure out the optimal units
                                            # Convert to lowest units
        $converted_value *= ( $scale->[$curr_index] / $scale->[0] );
        $curr_index      = 0;
        $converted_units = $scale_units->[0];

        #print "CV: $converted_value; CI: $curr_index\n";

        while ( ( $converted_value >= ( $scale->[ $curr_index + 1 ] / $scale->[$curr_index] ) ) && ( $curr_index < $#$scale ) ) {
            $converted_value *= ( $scale->[$curr_index] / $scale->[ $curr_index + 1 ] );
            $converted_units = $scale_units->[ $curr_index + 1 ];
            $curr_index++;
        }
    }
    else {    # Convert to specified units
              # Figure out the target index
        my $tar_index = 0;
        foreach my $su (@$scale_units) {
            if ( $su =~ /^$converted_units$/i ) {last}
            $tar_index++;
        }
        my $factor = $scale->[$curr_index] / $scale->[$tar_index];
        $converted_value = $converted_value * $factor;
    }

    if ( defined $decimals ) {
        $converted_value = sprintf( "%.${decimals}f", $converted_value );
    }

    return ( $converted_value, $converted_units );
}

#######################
sub convert_volume {
#######################
    my $volume       = shift;
    my $units        = shift;
    my $target_units = shift;

    my @scale = ( 1 / 1000000000, 1 / 1000000, 1 / 1000, 1, 1000, 4000 );
    my @scale_units = ( 'pl', 'nl', 'ul', 'ml', 'l', 'gallons' );
    if ( $units =~ /g$/i ) { return ( $volume, $units ) }    ## ignore mass measurements
    return Custom_Convert_Units( -value => $volume, -units => $units, -to => $target_units, -scale => \@scale, -scale_units => \@scale_units );
}

#####################
sub wiki_to_HTML {
#####################
    my %args = filter_input(\@_, -args => 'text,convert_linefeeds');
    my $text = $args{-text};
    my $convert_linefeeds = $args{-convert_linefeeds};

    ## also convert line feeds to html breaks  ##
    if ($convert_linefeeds) {
        $text =~s/\n\n/\n<P>\n/g;
        $text =~s/\n/<BR>\n/g;
    }

    my $config = {
        'h'   => 'h',
        'li'  => 'LI',
        'ul'  => 'UL',
        'il'  => 'OL',
        'img' => 'IMG SRC',
        'ref' => 'A HREF',
    };

    my $html = wiki_to_xml( $text, $config );
    
    
    
    return $html;
}

#####################
# Useful for converting HTML to other XML format (eg XMLmind)
#
#     my %config = {
#        'b'      => 'emphasis'
# 	'h'      => 'title',
# 	'li'     => 'listitem',
# 	'ul'     => 'itemizedlist',
# 	'ol'     => 'orderedlist',
# 	'img'    => 'graphic fileref',
# 	'A Href'    => 'ulink url',
#     };
#
# my $converted_text = convert_tags($text,\%config);
#
# Return: converted text string
######################
sub convert_tags {
######################
    my %args = &filter_input(
         \@_,
        -args      => 'text,convert',
        -mandatory => 'text,convert'
    );
    my $text         = $args{-text};
    my $convert      = $args{-convert};
    my $self_closing = $args{-self_closing};
    my $quiet        = $args{-quiet};

    my @self_closing_tags;
    @self_closing_tags = @$self_closing if $self_closing;
    my @tags     = keys %$convert;
    my @new_tags = values %$convert;

    my %Key = %{$convert};
    my ( $fixed_sct, $fixed_tag ) = ( 0, 0 );

    print "Converting Tags:\n";
    print "*" x 40 . "\n";
    foreach my $tag (@self_closing_tags) {
        my $new_tag = $Key{$tag};
        Message("$tag -> $new_tag") unless $quiet;
        while ( $text =~ s /<$tag([^>]*?)\/>/<$new_tag$1\/>/i ) {
            $fixed_sct++;
        }
    }

    foreach my $tag (@tags) {
        my $new_tag = $Key{$tag};
        my ($stop_tag)     = split ' ', $tag;
        my ($new_stop_tag) = split ' ', $new_tag;
        Message("$tag -> $new_tag .. /$new_stop_tag") unless $quiet;
        while ( $text =~ s /<$tag(.*?)<\/$stop_tag>/<$new_tag$1<\/$new_stop_tag>/i ) {
            $fixed_tag++;
        }
    }
    print "*" x 40 . "\n";

    my $copy = $text;
    my @unidentified_tags;

    while ( $copy =~ s/^(.*?)<(\w+)(.*)$/$3/ ) {
        push @unidentified_tags, $2 unless grep /^$2/, @new_tags, @unidentified_tags;
    }
    Message("Found $fixed_tag defined tags + $fixed_sct self-closing tags") unless $quiet;
    if (@unidentified_tags) {
        Message("Warning: found unidentified tags:");
        print join "\n ", @unidentified_tags;
    }

    return $text;
}

#################
sub escape_regex_special_chars {
#################
    my %args = &filter_input( \@_, -args => 'pattern,preserve', -mandatory => 'pattern' );

    my $pattern = $args{-pattern};
    my $preserve = Cast_List( -list => $args{-preserve}, -to => 'string' );

    my $spec_chars = '()[]^$|*.';

    foreach my $char ( split '', $preserve ) {
        $char = '\\' . $char;
        $spec_chars =~ s/$char//;
    }

    foreach my $char ( split '', $spec_chars ) {
        $char = '\\' . $char;
        $pattern =~ s/$char/$char/g;
    }
    return $pattern;
}

####################
sub HTML_to_xml {
####################
    my $text       = shift;
    my $config_ref = shift;
    my $quiet      = shift;

    my $config;
    if ($config_ref) { $config = $config_ref }
    else {
        $config = {
            ## xml mind configuration ##
            'b'       => 'emphasis',
            'h'       => 'title',
            'li'      => 'listitem',
            'ul'      => 'itemizedlist',
            'ol'      => 'orderedlist',
            'img src' => 'graphic fileref',
            'A Href'  => 'ulink url',
            'table'   => 'table',
            'tr'      => 'row',
            'td'      => 'entry',
        };
    }

    return convert_tags( $text, $config, -self_closing => ['img src'] );
}

#
#
# Convert standard wiki to HTML format
######################
sub wiki_to_xml_old {
######################
    my $text   = shift;
    my $config = shift;
    my $quiet  = shift;

    my @lines = split "\n", $text;

    my @std_keys = keys %$config;    # qw(h b i u li ul ol img ref tr td);

    my %key;
    foreach my $std_key (@std_keys) {
        $key{$std_key} = $config->{ lc($std_key) } || $config->{ uc($std_key) } || $std_key;
        ( $key{"stop_$std_key"} ) = split ' ', $key{$std_key};    ### strip possible parameters from end tag
    }

    my @html_lines;
    my $bullets_on = 0;
    my $table_on   = 0;
    my @sections   = ();
    my @stops      = ();
    foreach my $line (@lines) {
        chomp $line;
        $line =~ s/\bh(\d+)\.(.*)$/<$key{h}$1>$2<\/$key{stop_h}$1>/ig;
        $line =~ s/\*(\w.*?\w)\*/<$key{b}>$1<\/$key{stop_b}>/ig;         ## bold
        $line =~ s/\b\_(\w.*?\w)\_\b/<$key{i}>$1<\/$key{stop_i}>/ig;     ## bold
        $line =~ s/\+(\w.*?\w)\+/<$key{u}>$1<\/$key{stop_u}>/ig;         ## bold

        ## Tables ##
        if ( $line =~ /^\|(.+)\|(.*)/ ) {
            $line = "$1|$2";                                             # trim leading row identifier #
            my @row;
            my @cols = split /\|/, $line;

            unless ($table_on) {
                push @row, "<$key{table}>\n";
                push @row, "<title></title>\n <tgroup cols=\"" . int(@cols) . "\">\n  <tbody>\n";    ## xml mind
                $table_on = 1;
            }
            push @row, "<$key{tr}>\n <$key{td}>";
            push @row, join "<\/$key{stop_td}>\n <$key{td}>", @cols;
            push @row, "<\/$key{stop_td}>\n<\/$key{stop_tr}>\n";
            $line = join '', @row;
        }
        elsif ($table_on) {
            push @html_lines, "  </tbody>\n </tgroup>\n";                                            ## xml mind
            push @html_lines, "<\/$key{stop_table}>\n";
            $table_on = 0;
        }

        ## Bullets ##
        if ( $line =~ s/^([\*\#]+)\s+(.*)$/$2/ ) {
            my $type    = $1;
            my $indents = length($type);
            if   ( $type =~ /\#/ ) { $type = 'ol' }
            else                   { $type = 'ul' }

            if ( !$bullets_on && !$indents ) {
                push @html_lines, "<$key{li}>";
            }
            elsif ( $bullets_on == $indents ) {
                push @html_lines, "<\/$key{stop_li}>\n<$key{li}>";
            }
            elsif ( $bullets_on < $indents ) {
                $bullets_on++;
                foreach my $in ( $bullets_on .. $indents ) {
                    push @html_lines, "<$key{$type}>\n";
                    print '+' unless $quiet;
                    push @stops, "<\/" . $key{"stop_$type"} . ">\n";
                }
                push @html_lines, "<$key{li}>";
            }
            elsif ( $bullets_on > $indents ) {
                $bullets_on--;
                foreach my $out ( $indents .. $bullets_on ) {
                    push @html_lines, "<\/$key{stop_li}>\n";
                    my $stop = shift @stops;
                    push @html_lines, $stop;
                    print '-' unless $quiet;
                }
                push @html_lines, "<$key{li}>";
            }
            else {
                Message("NO OTHER POSSIBILITY");
            }
        }
        ## close bullets ##
        else {
            while ($bullets_on) {
                $bullets_on--;
                push @html_lines, "\n <\/$key{stop_li}>\n<\/$key{stop_ul}>\n";
                print '-' unless $quiet;
            }
        }

        ## special tags ##
        $line =~ s/\[(.*?)\|(.*?)\]/<$key{ref}=$2>$1<\/$key{stop_ref}>/g;    ## ref with text
        $line =~ s/\[(.*?)\]/<$key{ref}=$1>$1<\/$key{stop_ref}>/g;           ## explicit ref

        push @html_lines, $line;

        #	push @html_lines, "<BR>\n";
    }
    while ($bullets_on) {
        $bullets_on--;
        push @html_lines, "\n <\/$key{stop_li}>\n<\/$key{stop_ul}>\n";
        print '-' unless $quiet;
    }

    return join "\n", @html_lines;
}

#
#
# Convert standard wiki to HTML format
######################
sub wiki_to_xml {
######################
    my %args     = &filter_input( \@_, -args => 'text,config,quiet' );
    my $text     = $args{-text};
    my $config   = $args{-config};
    my $quiet    = defined $args{-quiet} ? $args{-quiet} : 1;
    my $xml_mind = $args{-xml_mind};

    my @lines = split "\n", $text;

    my @std_keys = keys %$config;    # qw(h b i u li ul ol img ref tr td);

    my %key;
    foreach my $std_key (@std_keys) {
        $key{$std_key} = $config->{ lc($std_key) } || $config->{ uc($std_key) } || $std_key;
        ( $key{"stop_$std_key"} ) = split ' ', $key{$std_key};    ### strip possible parameters from end tag
    }

    my @html_lines;
    my $bullets_on = 0;
    my $table_on   = 0;
    my @sections   = ();
    my @stops      = ();
    foreach my $line (@lines) {
        chomp $line;
        if ($xml_mind) {
            ### special handling for headers ###
            if ( $line =~ s/\bh(\d+)\.(.*)$/<section><$key{h}>$2<\/$key{stop_h}>/ig ) {
                ## customized for xml mind to make headers define sections ##
                my $hlevel = $1;
                print "Current Sections: @sections\n"  unless $quiet;
                if ( @sections && ( $sections[-1] >= $hlevel ) ) {    ## -> close and open new section
                    while ( @sections && ( $sections[-1] >= $hlevel ) ) {
                        $line =~ s /<section>/\n<\/section>\n<section>/;
                        print ">> open ($hlevel) / close ($sections[-1])"  unless $quiet;
                        pop @sections;
                    }
                }
                else {                                                # ($sections[-1] > $hlevel) {
                    ## ok just open subsection ##
                    print ">> new level ($hlevel)\n"  unless $quiet;
                }
                push @sections, $hlevel;
            }    ## header forced to a new section
        }
        else {
            $line =~ s/\bh(\d+)\.(.*)$/<section><$key{h}$1>$2<\/$key{stop_h}$1>/ig;
        }
        $line =~ s/\*(\w.*?\w)\*/<$key{b}>$1<\/$key{stop_b}>/ig;        ## bold
        $line =~ s/\b\_(\w.*?\w)\_\b/<$key{i}>$1<\/$key{stop_i}>/ig;    ## bold
        $line =~ s/\+(\w.*?\w)\+/<$key{u}>$1<\/$key{stop_u}>/ig;        ## bold

        ## Tables ##
        if ( $line =~ /^\|(.+)\|(.*)/ ) {

            # trim leading row identifier #
            $line = "$1|$2";
            my @row;
            my @cols = split /\|/, $line;

            unless ($table_on) {
                push @row, "<$key{table}>\n";
                push @row, "<title></title>\n <tgroup cols=\"" . int(@cols) . "\">\n  <tbody>\n";    ## xml mind
                $table_on = 1;
            }
            push @row, "<$key{tr}>\n <$key{td}>";
            push @row, join "<\/$key{stop_td}>\n <$key{td}>", @cols;
            push @row, "<\/$key{stop_td}>\n<\/$key{stop_tr}>\n";
            $line = join '', @row;
        }
        elsif ($table_on) {
            push @html_lines, "  </tbody>\n </tgroup>\n";                                            ## xml mind
            push @html_lines, "<\/$key{stop_table}>\n";
            $table_on = 0;
        }

        ## Bullets ##
        if ( $line =~ s/^([\*\#]+)\s+(.*)$/$2/ ) {
            my $type    = $1;
            my $indents = length($type);
            if   ( $type =~ /\#/ ) { $type = 'ol' }
            else                   { $type = 'ul' }

            if ( !$bullets_on && !$indents ) {
                push @html_lines, "<$key{li}>";
            }
            elsif ( $bullets_on == $indents ) {
                push @html_lines, "<\/$key{stop_li}>\n<$key{li}>";
            }
            elsif ( $bullets_on < $indents ) {
                $bullets_on++;
                foreach my $in ( $bullets_on .. $indents ) {
                    push @html_lines, "<$key{$type}>\n";
                    print '+' unless $quiet;
                    push @stops, "<\/" . $key{"stop_$type"} . ">\n";
                    print "** Add $type stop **\n" unless $quiet;
                }
                push @html_lines, "<$key{li}>";
            }
            elsif ( $bullets_on > $indents ) {
                $bullets_on--;
                foreach my $out ( $indents .. $bullets_on ) {
                    push @html_lines, "<\/$key{stop_li}>\n";
                    my $stop = shift @stops;
                    push @html_lines, $stop;
                    print '-' unless $quiet;
                    print "** Close $type stop **\n"  unless $quiet;
                }
                push @html_lines, "<$key{li}>";
            }
            else {
                Message("NO OTHER POSSIBILITY");
            }
        }
        ## close bullets ##
        else {
            while ($bullets_on) {
                $bullets_on--;
                push @html_lines, "\n <\/$key{stop_li}>\n";
                my $stop = shift @stops;
                push @html_lines, $stop;
                print '-' unless $quiet;
            }
        }

        ## special tags ##
        $line =~ s/\[(.*?)\|(.*?)\]/<$key{ref}=$2>$1<\/$key{stop_ref}>/g;    ## ref with text
        $line =~ s/\[(.*?)\]/<$key{ref}=$1>$1<\/$key{stop_ref}>/g;           ## explicit ref

        while ( $line =~ s/\<(\w+)=(\w+)/\<$1=\'$2\'/ ) { }                  ## quote right hand element if necessary.

        ## special characters ##
        $line =~ s/ & / &amp /g;
        $line =~ s/\< /&lt /g;

        ### Images ###
        my $Iref   = "../../www/images/help_images";
        my $prefix = "\n\t<screenshot>\n\t<graphic fileref=";
        my $suffix = "\n\t</screenshot>\n";

        while ( $line =~ s/\!(.*?)\!/<IMAGE>/ ) {
            my $img_ref = $1;
            my ( $filename, $options );
            my $option_string;
            if ( $img_ref =~ /^([\w\.]+)\|?(.*)$/ ) {
                my $filename = $1;
                my @options = split ',', $2;
                foreach my $option (@options) {
                    if ( $option =~ /(\w+)=(\w+)/ ) { $option_string .= " $1=\'$2\'" }
                }
                $line =~ s /\<IMAGE\>/$prefix \"$Iref\/$filename\" $option_string \/> $suffix/;
            }
            else {
                $line =~ s /<IMAGE>/\!$img_ref\!/;
            }

            #           $line =~s /<IMAGE>/<A Href=$Iref/$filename ><IMG SRC='$Iref/$filename' $option_string \/><\/A>/;
        }

        push @html_lines, $line;

        #	push @html_lines, "<BR>\n";
    }

    if ($table_on) {
        ## close table if still on... ##
        push @html_lines, "  </tbody>\n </tgroup>\n";    ## xml mind
        push @html_lines, "<\/$key{stop_table}>\n";
        $table_on = 0;
    }

    while ($bullets_on) {
        $bullets_on--;
        push @html_lines, "\n <\/$key{stop_li}>\n";
        my $stop = shift @stops;
        push @html_lines, $stop;
        print '-' unless $quiet;
    }
    if ($xml_mind) {
        while (@sections) {
            push @html_lines, "</section>\n";
            pop @sections;
        }
    }

    return join "\n", @html_lines;
}

###############################
# Description:
#	- Converts file path format between Unix/Linux and Windows
#
# <snip>
#	Usage example:
#		my $w_path = RGTools::Conversion::convert_file_path( -from => 'linux', -to => 'windows', -path => '/projects/labinstruments/bioanalyzer/BA2100-4/DNA#5542_DNA 1000_DE20901540_2013-01-14_12-02-50.xad' );
#	Return:
#		Scalar, the converted path
# </snip>
###############################
sub convert_file_path {
    my %args = &filter_input( \@_, -args => 'from,to,path' );
    my $from = $args{-from};
    my $to   = $args{-to};
    my $path = $args{-path};

    if ( $from =~ /unix|linux/xmsi && $to =~ /windows/xmsi ) {
        $path =~ s|\/|\\|g;
    }
    elsif ( $from =~ /windows/xmsi && $to =~ /unix|linux/xmsi ) {
        $path =~ s|\\|\/|g;
    }
    else {
        Message("convert_file_path() argument not supported: $from => $to");
    }
    return $path;
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

$Id: Conversion.pm,v 1.20 2004/12/09 17:42:07 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
