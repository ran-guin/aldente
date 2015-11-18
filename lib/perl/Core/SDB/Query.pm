##################################################################################################################################
# Query.pm
#
# SQL Query tools
#
# $Id: Query.pm,v 1.107 2004/11/30 01:42:24 rguin Exp $
###################################################################################################################################
package SDB::Query;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Query.pm - Generic SQL query generating tools 

=head1 SYNOPSIS <UPLINK>

=head1 DESCRIPTION <UPLINK>sub

=for html
    
=cut

##############################
# superclasses               #
##############################
### Inheritance

# use base RGTools::Object;

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Storable;
use Data::Dumper;
use Benchmark;

#use AutoLoader;
use Carp;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules

use SDB::CustomSettings;
use SDB::Transaction;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Object;
use RGTools::Conversion;
use RGTools::RGmath;

##############################
# global_vars                #
##############################
use vars qw($AUTOLOAD $testing);

### Global variables

use vars qw($config_dir $login_file %Primary_fields %Mandatory_fields %Field_Info @DB_Tables $Sess);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

#########################
sub compare_queries {
#########################
    my $query1 = shift;
    my $query2 = shift;

    if ( $query1 eq $query2 ) { Message("IDENTICAL"); return 1; }
    elsif ( lc($query1) eq lc($query2) ) { Message("Identical (except for case)"); return 1; }

    my $hash1 = deconstruct_query($query1);
    my $hash2 = deconstruct_query($query2);

    my @keys = qw(fields tables conditions group order limit);
    foreach my $key (@keys) {
        my ( @a1, @a2 );
        if ( ref $hash1->{$key} eq 'ARRAY' ) {
            @a1 = @{ $hash1->{$key} };
            @a2 = @{ $hash2->{$key} };
        }
        else {
            @a1 = ( $hash1->{$key} );
            @a2 = ( $hash2->{$key} );
        }
        my $max = int(@a1) - 1;
        if ( int(@a2) > int(@a1) ) { $max = int(@a2) - 1 }
        my $same = 0;
        foreach my $i ( 0 .. $max ) {
            if ( $a1[$i] =~ /^\Q$a2[$i]\E$/ ) {
                $same++;
            }
            else {
                Message("Difference in $key # $i ($a1[$i] vs $a2[$i])");
            }
        }
        Message("$same similar ${key} specs");
    }
    return;
}

############################
sub deconstruct_query {
############################
    my $query = shift;
    my %args  = filter_input( \@_ );
    my %hash;
    my @arr = split /\s+/ixms, $query;

    my ( $select_pos, $from_pos, $where_pos );
    my $open_tag = 0;
    my $max_idx  = int @arr - 1;

    foreach my $i ( 0 .. $max_idx ) {
        my $element = $arr[$i];
        if ( $element =~ /^SELECT$/ixms ) {
            if ( !defined $select_pos ) {
                $select_pos = $i;
                next;
            }
        }
        if ( $element =~ /^FROM$/ixms ) {
            if ( !defined $from_pos ) {
                $from_pos = $i;
                next;
            }
        }
        if ( $element =~ /^WHERE$/ixms ) {
            if ( !$open_tag ) {
                $where_pos = $i;
                last;
            }
        }
        if ( $element =~ /\(/xms ) {
            $open_tag++;
        }
        if ( $element =~ /\)/xms ) {
            $open_tag--;
        }
    }

    if ( !defined $where_pos ) { $where_pos = $max_idx + 1 }

    my ( $field_string, $table_string, $condition_string );

    foreach my $i ( $select_pos + 1 .. $from_pos - 1 ) {
        $field_string .= $arr[$i] . ' ';
    }
    foreach my $i ( $from_pos + 1 .. $where_pos - 1 ) {
        $table_string .= $arr[$i] . ' ';
    }
    foreach my $i ( $where_pos + 1 .. $max_idx ) {
        $condition_string .= $arr[$i] . ' ';
    }

    if ( $field_string && $table_string ) {
        my ( $condition, $group, $order, $limit );

        if ($condition_string) {
            my $temp = $condition_string;

            if ( $temp =~ /(.+) LIMIT (.+)$/i ) {
                $temp  = $1;
                $limit = $2;
            }
            if ( $temp =~ /(.+) ORDER BY (.+)$/i ) {
                $temp  = $1;
                $order = $2;
            }

            if ( $temp =~ /(.*) GROUP BY (.+)$/i ) {
                $temp  = $1;
                $group = $2;
            }
            $condition = $temp;

        }

        $hash{type} = 'SELECT';
        my ( $fields, $Fseparators ) = split_fields( $field_string, -sort => 1, %args );
        $hash{fields} = $fields;

        my ( $tables, $Tseparators ) = split_fields( $table_string, -split => 'LEFT JOIN' );
        $hash{tables} = $tables;
        $hash{Tsep}   = $Tseparators;

        ( $hash{condition} ) = split_fields($condition) if ($condition);
        ( $hash{group} )     = split_fields($group)     if ($group);
        ( $hash{order} )     = split_fields($order)     if ($order);
        $hash{limit} = $limit;
    }
    my $string = query_string( \%hash );
    return $string;
}

###################
sub query_string {
###################
    my %args    = filter_input( \@_, -args => 'hash' );
    my $hashref = $args{-hash};
    my $br      = $args{-linebreak} || "<BR>\n";          ## linebreak

    my %hash = %$hashref;

    my $string;

    $string .= '<B>' . $hash{type} . '</B>' . $br;

    $string .= join "$br,", @{ $hash{fields} };

    if ( $hash{tables} ) {
        $string .= $br . '<B>FROM</B>' . $br;
        $string .= $hash{tables}->[0];

        foreach my $i ( 2 .. int( @{ $hash{tables} } ) ) {
            ## include JOIN OR , separator as applicable ##
            $string .= $br . $hash{Tsep}->[ $i - 2 ] . ' ' . $hash{tables}->[ $i - 1 ];
        }
    }

    if ( $hash{condition} && @{ $hash{condition} } ) {
        $string .= $br . '<B>WHERE</B>' . $br;
        $string .= join "$br AND ", @{ $hash{condition} };
    }

    if ( $hash{group} && @{ $hash{group} } ) {
        $string .= $br . '<B>GROUP BY</B>' . $br;
        $string .= join "$br,", @{ $hash{group} };
    }

    if ( $hash{order} && @{ $hash{order} } ) {
        $string .= $br . '<B>ORDER BY</B>' . $br;
        $string .= join "$br,", @{ $hash{order} };
    }

    if ( $hash{limit} ) {
        $string .= $br . '<B>LIMIT</B>' . $br;
        $string .= $hash{limit};
    }

    return $string;
}

#
# Splits up string into array of sections.
#
# This can be used to split up conditions (on AND) or tables (on LEFT JOIN) without breaking up blocks in parentheses.
#
# Options:
#  * sort output array
#  * trim (allows for a supplied string to be trimmed from the beginning eg. 'WHERE ' in condition string)
#  * split - specify a string to split on (aside from ',')
#
# Return: Array
#####################
sub split_fields {
#####################
    my $string    = shift;
    my %args      = filter_input( \@_ );
    my $split     = $args{ -split } || '\bAND\b';
    my $sort      = $args{ -sort };
    my $trim      = $args{-trim};
    my $debug     = $args{-debug};
    my $separator = $args{-separator} || $split;    ## characters mandating a split in string (if tags are closed)

    $separator = $separator . "|\,";

    my @sections;
    my @split;

    if ($debug) {
        Message("Initial String: $string");
        Message("Separate on $separator");
    }
    if ($trim) { $string =~ s/^$trim\s+//i }

    ## first break up the string on all split characters
    my $abort = 500;
    while ( $string =~ /^(.*?)(\(|\)|$separator)(.*)$/i ) {
        my $left_match  = $1;
        my $split_match = $2;
        $string = $3;

        if    ( $split_match =~ /^$separator$/i )    { $split_match = " $split_match " }    ## add spaces to separators ##
        elsif ( $left_match  =~ /\b(IN|JOIN ON) $/ ) { $split_match = " $split_match " }    ## add spaces to IN (...) and JOIN ON (...)
        push @split, $split_match;

        if ( $left_match =~ /^\s?\Q$split_match\E\s?$/ ) { push @sections, ''; }

        #	if ( $left_match =~ /^\s?$split_match\s?$/ ) { push @sections, '' }
        else {
            $left_match =~ s /^\s+//;

            #	        $left_match=~s /\s+$//;
            push @sections, $left_match;
        }
        if ( !$abort-- ) {last}
    }

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    if ($string) { push @sections, $string }

    my @items;

    my $open_tags = 0;

    ## now paste back together sections that need to be together if required (defined by parentheses) ##
    my @separators;    ## keep track of separators as well
    foreach my $i ( 0 .. $#sections ) {
        if ($debug) { Message( "S $i: $sections[$i] ($open_tags) $split[$i] :" . int(@items) ) }

        if ( !$open_tags && $split[ $i - 1 ] =~ /$separator/ ) {
            if ($debug) { Message("Next item: $sections[$i]...") }
            ## add next item ##

            $sections[$i] =~ s/^\s+$//;    ### clear empty space...

            push @items,      $sections[$i];
            push @separators, $split[ $i - 1 ];
        }
        elsif (@items) {
            ## if tags still open, append to previous list item ##
            $items[-1] .= $split[ $i - 1 ];
            $items[-1] .= $sections[$i];
        }
        else {
            $items[0] = $sections[$i];
        }

        if ( $split[$i] =~ /\(/ ) { $open_tags++; }
        elsif ( $split[$i] =~ /\)/ ) {
            $open_tags--;
            if ( !$open_tags ) {
                ## if this split tag closes the tags, append to current section
                #               $items[-1] .= $split[$i];
                # $items[-1] .= $sections[$i];
            }
        }
        $i++;
    }

    if ( $split[-1] eq ')' ) { $items[-1] .= $split[-1] }    ## add final closing tag if necessary...

    my @list = @items;

    ## sort if requested ##
    #   figure out how to sort separators at the same time...
    #
    #    if ($sort) {
    #        @list = sort {$a cmp $b} @items;
    #    }

    if ($debug) { print HTML_Dump $string, \@list }

    return \@list, \@separators;
}

return 1;

