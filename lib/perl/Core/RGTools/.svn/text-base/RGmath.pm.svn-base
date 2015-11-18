package RGmath;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

RGmath.pm - 

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
    intersection
    union
    xor_array
    merge_Hash
    interpolate
    distinct_list
    $pi $size2mob
    $mob2size
    get_sum
    minus
);

##############################
# standard_modules_ref       #
##############################
##############################
# custom_modules_ref         #
##############################

use RGTools::RGIO;
use strict;
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
my $pi = 3.14;

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

###################
sub interpolate {
###################
    my $value    = shift;
    my $filename = shift;    #  tab delimited file containing values to interpolate
    my $roundoff = shift;

    $roundoff ||= 3;

    # print "Trying to interpolate $value from Table: $filename.\n";

    open( TABLE, "$filename" ) or die "Error opening lookup table: $filename\n";

    my $X1;
    my $X2;
    my $Y1;
    my $Y2;

    while (<TABLE>) {
        if (/([\.\d]+)\s+([\.\d]+)/) {
            if ( $1 <= $value ) {
                $X1 = $1;
                $Y1 = $2;
            }
            elsif ( $1 > $value ) {
                $X2 = $1;
                $Y2 = $2;
                last;
            }
        }
    }
    close(TABLE);

    if ( !$X1 ) {
        print "Need to extrapolate beginning of $filename table ($value < first value)\n";
        return 0;
    }
    elsif ( !$X2 ) {
        print "Need to extrapolate end of table ($value < last value\n";
        return 0;
    }
    else {
        my $diff  = $X2 - $X1;
        my $xdiff = $value - $X1;

        my $ydiff  = $Y2 - $Y1;
        my $interp = ( $xdiff / $diff ) * $ydiff + $Y1;
        if ( $interp =~ /^(\d+\.?\d{$roundoff})/ ) { $interp = $1; }

        #    print "interpolated $value to $interp ($X1,$Y1)..($X2,$Y2)\n";
        return $interp;
    }
}

##############
sub union {
##############
    #
    # return the union of two arrays as an array
    #

    my $ref1 = shift;
    my @result;

    if ( defined($ref1) and ref($ref1) eq 'ARRAY' ) {
        @result = @{$ref1};

        while ( my $nextref = shift ) {
            if ( defined($nextref) and ref($nextref) eq 'ARRAY' ) {
                my @nextArray = @{$nextref};
                foreach my $element (@nextArray) {
                    unless ( grep /^$element$/, @result ) { push( @result, $element ) }
                }
            }
            else {
                @result = ();
                last;
            }
        }
    }

    else {
        @result = ();
    }

    return \@result;
}

##############
sub minus {
##############
    #
    #
    #
    my $aref   = shift;    # reference to second array
    my $bref   = shift;    # reference to second array
    my @aarray = @$aref;
    my @barray = @$bref;
    my @results;
    for my $element (@aarray) {
        if ( !( grep /^$element$/, @barray ) ) {
            push @results, $element;
        }
    }
    return @results;
}

##############
sub xor_array {
##############
    #
    # return the xor of two arrays as an array
    #
    my $aref = shift;    # reference to second array
    my $bref = shift;    # reference to second array

    my @xor = ();
    my @union = @{ union( $aref, $bref ) };
    foreach my $element (@union) {
        my $in_a = grep /^$element$/, @$aref;
        my $in_b = grep /^$element$/, @$bref;
        if ( ( $in_a && !$in_b ) || ( !$in_a && $in_b ) ) {
            if ( !grep /^$element$/, @xor ) { push @xor, $element; }
        }
    }
    return \@xor;
}

###############
sub distinct_list {
###############
    my $list  = shift;
    my $strip = shift;

    my @distinct = ();

    if ( ref($list) eq 'ARRAY' ) {

        foreach my $item (@$list) {
            if ( $strip && ( $item !~ /\S/ ) ) {next}
            if ($strip) { $item =~ s/^\s+//g }
            if ($strip) { $item =~ s/\s+$//g }
            if ( !grep /^\Q$item\E$/, @distinct ) { push @distinct, $item }
        }

    }
    return \@distinct;
}

#<snip>
#Usage example:
#        my ($intersec,$a_only,$b_only)=&RGmath::intersection(\@a,\@b);
#Or:     my ($intersec,$a_only,$b_only)=&RGmatch::intersection($astr,$bstr);
#</snip>
#####################
sub intersection {
#####################
    #
    # return the intersection of two arrays as an array
    #
    my $aref = shift;
    my $bref = shift;

    $aref = Cast_List( -list => $aref, -to => 'arrayref' );
    $bref = Cast_List( -list => $bref, -to => 'arrayref' );

    if (!$aref || !$bref) { return ([], $aref, $bref) }
    
    my @a = @{$aref};
    my @b = @{$bref};

    my @a_only = ();    ## elements only found in first array
    my @b_only = ();    ## elements only found in second array

    my @result = ();
    foreach my $element (@b) {
        if   ( grep /^\Q$element\E$/, @a ) { push( @result, $element ) }
        else                               { push( @b_only, $element ) }
    }

    ### populate the array of element ONLY in array a.
    foreach my $element (@a) {
        unless ( grep /^\Q$element\E$/, @b ) { push( @a_only, $element ) }
    }

    return ( \@result, \@a_only, \@b_only );
}

# Return the sum given an array of values
#
# Return:  scalar
###########
sub get_sum {
###########
    my %args   = @_;
    my $values = $args{ -values };    ## values to be added
    my $sum;
    foreach my $val ( @{$values} ) {
        $sum += $val;
    }
    return $sum;
}

###########################################
# A sort function that provides a smart ascending sort when sorting alphanumeric string
# For example, B10 is larger than B3 (a native perl sort will sort B10 smaller than B3
# This is just a wrapper for using smart_cmp and is the same as using sort {&smart_cmp($a,$b)}
#<snip>
#Usage example:
#      my @sortarray = smart_sort(@array);
#</snip>
# return a smart ascending sorted array (see smart_cmp for descending sort and case insensitive sort)
##################
sub smart_sort {
##################
    my (@arr) = @_;
    my @newarr = sort { &smart_cmp( $a, $b ) } @arr;
    return @newarr;
}
###########################################
# Merges two hashes
# The second hash is the dominant one, meaning if a key is in both hashes it will select the value from the second hash
#<snip>
# Usage example:
#      my $href = merge_hash( -hash1=>\%hash1, -hash2=>\%hash2 );
#</snip>
#
##################
sub merge_Hash {
##################
    my %args      = &filter_input( \@_, -args => 'hash1,hash2', -mandatory => 'hash1,hash2' );
    my $hash1_ref = $args{-hash1};
    my $hash2_ref = $args{-hash2};
    my %hash1     = %$hash1_ref if $hash1_ref;
    my %hash2     = %$hash2_ref if $hash2_ref;

    my @keys = keys %hash2;
    for my $key (@keys) {
        if ( exists( $hash2{$key} ) ) {
            $hash1{$key} = $hash2{$key};
        }
    }
    return \%hash1;
}

###########################################
# A comparison function that compares two alphanumeric string and
# returns -1 if input1 is less than input2
# returns 0 if input1 is equal to input2
# returns 1 if input1 is greater than input2
# For example, &smart_cmp("B10","B3") returns 1 because B10 is greater than B3
#<snip>
#Usage example:
#      my $res = &smart_cmp{$a,$b};
#      or in a sort:
#      my @sortarray = sort {&smart_cmp($a,$b)} @array; # for ascending sort
#      my @sortarray = sort {&smart_cmp($b,$a)} @array; # for descending sort
#      my @sortarray = sort {&smart_cmp($a,$b,-case_insensitive=>1)} @array; #for ascending case insensitive sort
#</snip>
##################
sub smart_cmp {
##################
    my %args        = &filter_input( \@_, -args => 'a,b' );
    my $first       = $args{-a};
    my $second      = $args{-b};
    my $insensitive = $args{-case_insensitive} || 0;

    my $res = 0;
    if ($insensitive) {
        $first  = uc($first);
        $second = uc($second);
    }
    my @firstarr  = $first  =~ /\d+|\D+/g;
    my @secondarr = $second =~ /\d+|\D+/g;

    while ( $res == 0 ) {
        my $match1 = shift @firstarr;
        my $match2 = shift @secondarr;
        if ($match1) {
            if ($match2) {
                if ( $match1 =~ /\d+/ ) {
                    if ( $match2 =~ /\d+/ ) {
                        if   ( !( $match1 <=> $match2 ) ) { $res = $match1 cmp $match2 }
                        else                              { $res = $match1 <=> $match2 }
                    }
                    else { $res = -1 }
                }
                else {
                    if   ( $match2 =~ /\d+/ ) { $res = 1 }
                    else                      { $res = $match1 cmp $match2 }
                }
            }
            else { $res = 1 }
        }
        else {
            if   ($match2) { $res = -1 }
            else           { $res = 0; last; }
        }
    }
    return $res;
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

$Id: RGmath.pm,v 1.8 2004/09/08 23:49:14 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
