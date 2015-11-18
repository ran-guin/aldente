######################################################################################
# String.pm
#
# This object represents a string and support various string parsing functionalities
#
######################################################################################
package String;

use RGTools::RGIO;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

String.pm - This object represents a string and support various string parsing functionalities

=head1 SYNOPSIS <UPLINK>

 use RGTools::String;

 my $s = String->new(-text=>"CATCATCATCA"); #Create a new String object with the specified text.
 $s->find_matches(-searches=>['CATCA','CAT','ATC'],-index=>1,-group=>1); #Specify the strings to search for; also perform indexing and grouping.
 print Dumper $s->{matches}->{searches}; 
 print Dumper $s->{matches}->{indexes};
 print Dumper $s->{matches}->{sections};

=head1 DESCRIPTION <UPLINK>

=for html
This object represents a string and support various string parsing functionalities<BR>

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
    split_tagged_string
    split_to_screen
);

##############################
# standard_modules_ref       #
##############################
##############################
# custom_modules_ref         #
##############################
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
##############################
# constructor                #
##############################

#########################
sub format_Text {
#########################
    my %args      = &filter_input( \@_ );
    my $text      = $args{-text};
    my $color     = $args{-color};
    my $italic    = $args{-italic};         ## bolean
    my $bold      = $args{-bold};           ## bolean
    my $face      = $args{-face};
    my $size      = $args{-size};
    my $highlight = $args{-highlight};      ## color of highlight
    my $id        = $args{-id};
    my $style     = $args{-style};

    my $tags;
    my $final;

    if ($color)     { $tags .= " COLOR='$color' " }
    if ($face)      { $tags .= " FACE='$face' " }
    if ($size)      { $tags .= " SIZE='$size' " }
    if ($highlight) { $tags .= " style='background-color:$highlight' " }
    if ($id)        { $tags .=  " id='$id' "}
    if ($style)     { $tags .=  " style='$style' "}
   
    $final = "<Font" . $tags . " >" . $text . "</FONT>";

    if ($bold) {
        $final = "<B>" . $final . "</B>";
    }
    if ($italic) {
        $final = "<I>" . $final . "</I>";
    }

    return $final;
}

##################
sub new {
##################
    #
    #Constructor
    #
    my $this = shift;
    my %args = @_;

    my $text = $args{-text};    # Directly pass in a string text [String]
    my $file = $args{-file};    # Specify a text file which contains the string [String]

    my ($class) = ref($this) || $this;
    my ($self) = {};

    if ( !$text && $file ) {
        open( FILE, $file ) or die("Cannot open file: $file");
        while (<FILE>) {
            $text .= $_;
        }
        close(FILE);
    }

    $self->{text}   = $text;            # The text of the string [String]
    $self->{length} = length($text);    # Number of characters in the string [String]

    $self->{matches}             = {};  # A hash that is used for storing matches in various formats [Hash]
    $self->{matches}->{count}    = 0;   # Total number of matches found [Int]
    $self->{matches}->{searches} = {};  # A hash that groups the matches by searches [Hash]
    $self->{matches}->{indexes}  = {};  # A hash that groups the matches by individaul characters of the string [Hash]
    $self->{matches}->{sections} = {};  # A hash that groups the matches by matched sections [Hash]

    $self->{indexes} = {};                  # A hash that contains various kinds of indexes. [Hash]
    $self->{indexes}->{characters} = {};    # An index hash for the characters of string [Hash]

    bless $self, $class;

    return $self;
}

##############################
# public_methods             #
##############################

#####################
sub find_matches {
#####################
    #
    # Search for matches and populate the $self->{matches}->{searches} hash by default.
    # Returns: The number of matches [Int]
    #
    my $self = shift;
    my %args = @_;

    my $searches       = $args{-searches};               # A list of strings to be searched [ArrayRef]
    my $index          = $args{ -index };                # Index the matches. [Int]
    my $group          = $args{-group};                  # Specify additional grouping of the result matches into sections. [Int]
    my $case_sensitive = $args{-case_sensitive} || 0;    # Flag to indicate whether the search is going to be case-sensitive [Int]

    my $search_string = $self->{text};
    $search_string =~ s/\n//g;                           # Get rid of line feed characters
    unless ($case_sensitive) { $search_string = uc($search_string) }

    foreach my $search ( @{$searches} ) {
        my $pos = -1;
        unless ($case_sensitive) { $search = uc($search) }
        while ( ( $pos = index( $search_string, $search, $pos ) ) > -1 ) {
            unless ( grep /^$pos$/, @{ $self->{matches}->{searches}->{$search} } ) {
                ## this test is added to easily remove redundant elements which were showing up for some reason... ##
                push @{ $self->{matches}->{searches}->{$search} }, $pos;
                $self->{matches}->{count}++;
            }
            $pos++;
        }
    }
    if ( $index || $group ) { $self->_index_matches() }
    if ($group) { $self->_group_matches() }
}

##############################
# public_functions           #
##############################

###################
sub split_to_screen {
###################
    #
    # split string to separate into rows of length N
    #
    my %args       = @_;
    my $string     = $args{-string};
    my $max_length = $args{-width};                ## width of rows in characters...
    my $separator  = $args{-separator} || "\n";    ## separator to be used between rows
    my $index      = $args{'-index'};              ## add optional index flag - (includes line #s on left side)..

    my $length = length($string);

    my $line = 0;
    if ( $length > $max_length ) {
        my $returnstring = '';
        my $line_number;
        while ($string) {
            $line++;
            my $sub = substr( $string, 0, $max_length );
            if ($index) { $line_number = "$line:\t" }
            $returnstring .= $separator . $line_number . $sub;
            my $remaining = length($string) - $max_length;
            if ( $remaining > 0 ) {
                $string = substr( $string, $max_length, $remaining );
            }
            else { $string = 0 }
        }
        return $returnstring;
    }
    else {
        return $string;
    }
}

#########################
sub split_tagged_string {
#########################
    #
    # split string to fit on html screen
    #
    #  The block replacement is used to screen out html link tags which may be in the string.
    #
    my %args = @_;

    my $string      = $args{-string} || '';
    my $max_length  = $args{-width};
    my $separator   = $args{-separator} || "\n";
    my $indexed     = $args{-indexed} || 0;
    my $start_tag   = $args{-tag_start} || "<";
    my $stop_tag    = $args{-tag_stop} || ">";
    my $hidden_tags = $args{-hidden_tags} || '';
    my $show_tags   = $args{-show_tags} || 0;      ## flag to help with troubleshooting (includes tags in printout)

    my $length       = length($string);
    my $returnstring = "";
    my $hiding       = 0;

    $string =~ s/\n//g;

    my $line_length  = 0;
    my $hidden_block = '';
    my $char_number  = 1;
    if ( $length <= $max_length ) { return $string }
    else {
        while ($string) {
            $returnstring .= "\n";    ## add linefeed for more readable source code
            my $index    = 0;
            my $nextline = '';
            if ($indexed) {
                $char_number += $line_length;
                if ( $hidden_block =~ /^(\/a|s*)$/i ) {    ## If we are NOT inside a reference, print the index number
                    $returnstring .= sprintf "%0.5d : ", $char_number;
                }
                else {
                    $returnstring .= "&nbsp &nbsp &nbsp &nbsp &nbsp ";
                }
                $returnstring .= "\n";
            }
            $line_length  = 0;
            $hidden_block = '';

            ## <CONSTRUCTION> - some problems (probably only when tags are imbedded
            ## (eg when vectors are searched for primers AND restriction sites simultaneously)
            ## - need to evaluate logic again at some point.. )?)
            while ( $line_length < $max_length ) {
                my $char = substr( $string, $index++, 1 );
                if ( $char eq $start_tag ) {
                    $hidden_block = '';    ## keep track of hidden block
                    $hiding++;
                    $returnstring .= "\n<font color=blue>$char</font>\n" if $show_tags;
                }
                elsif ( $char =~ /$stop_tag/ ) {
                    $hiding--;
                    $returnstring .= "\n<font color=blue>$char</font>\n" if $show_tags;
                    if ( $hiding < 0 ) { $hiding = 0; Message("Warning"); }
                }
                elsif ($hiding) {
                    $hidden_block .= $char;

                    # ... why not something like ?: unless ($char =~ /\s/ || $hidden_block=~/\s/) { $hidden_block .= $char }
                    $returnstring .= "\n<font color=red>$char</font>\n" if $show_tags;
                }
                elsif ( $hidden_tags && ( $hidden_block =~ /^$hidden_tags/ ) ) {
                    ## if hidden block is <script .. hide script as well..
                    $returnstring .= "\n<font color=blue>$char</font>\n" if $show_tags;
                }
                else {
                    $returnstring .= "\n<font color=green>$char</font>\n" if $show_tags;
                    $line_length++;
                }
                $nextline .= $char;
            }

            $returnstring .= "<BR>\n" if $show_tags;

            $returnstring .= $nextline . $separator . "\n";

            my $remaining = length($string) - length($nextline);
            if ( $remaining > 0 ) {
                $string = substr( $string, length($nextline), $length );
            }
            else { $string = 0 }
        }
    }

    return $returnstring;
}

##############################
# private_methods            #
##############################

#######################
sub _index_matches {
#######################
    #
    #Index the matches found and generates $self->{matches}->{indexes}.
    #
    my $self = shift;

    foreach my $search ( sort keys %{ $self->{matches}->{searches} } ) {
        foreach my $index ( @{ $self->{matches}->{searches}->{$search} } ) {

            # For each index within the length of the search item, set the match
            for ( my $i = $index; $i < $index + length($search); $i++ ) {
                push( @{ $self->{matches}->{indexes}->{$i} }, $search );
            }
        }
    }
}

#######################
sub _group_matches {
#######################
    #
    #Group the string into sections of matches along with non-matches.
    #
    my $self = shift;

    my $si          = 0;    # index of sections (starts at 1)
    my $new_section = 1;    # Flag to indicate whether we are starting a new section.

    my @previous_matches;
    my @current_matches;
    for ( my $i = 0; $i < $self->{length}; $i++ ) {
        if ( defined $self->{matches}->{indexes}->{$i} ) {
            @current_matches = @{ $self->{matches}->{indexes}->{$i} };
        }
        else {
            @current_matches = ();
        }

        my $this = join ',', @current_matches;
        my $last = join ',', @previous_matches;
        if ( $this eq $last ) {
            $new_section = 0;
        }
        else {
            $new_section = 1;
        }

        if ( $new_section || $si == 0 ) {
            $self->{matches}->{sections}->{ ++$si }->{start} = $i;
            @{ $self->{matches}->{sections}->{$si}->{matches} } = @current_matches;
            unless ( $si == 1 ) {
                $self->{matches}->{sections}->{ $si - 1 }->{end}    = $i - 1;
                $self->{matches}->{sections}->{ $si - 1 }->{length} = $i - $self->{matches}->{sections}->{ $si - 1 }->{start};
                $self->{matches}->{sections}->{ $si - 1 }->{text}   = substr( $self->{text}, $self->{matches}->{sections}->{ $si - 1 }->{start}, $self->{matches}->{sections}->{ $si - 1 }->{length} );
            }
        }

        if ( $i == ( $self->{length} - 1 ) ) {    #Last positiion
            $self->{matches}->{sections}->{$si}->{end}    = $i;
            $self->{matches}->{sections}->{$si}->{length} = $i - $self->{matches}->{sections}->{$si}->{start} + 1;
            $self->{matches}->{sections}->{$si}->{text}   = substr( $self->{text}, $self->{matches}->{sections}->{$si}->{start}, $self->{matches}->{sections}->{$si}->{length} );
        }

        @previous_matches = @current_matches;
    }
}

#####################
sub proofread_Form {
#####################
    my $string = shift;

    my $q     = new CGI;
    my $block = '<h3>Cut and Paste Document Contents into text area below:</h3>';

    $block .= '<FORM>';
    $block .= $q->submit( -name => 'rm', -value => 'Proof Read', -class => 'ACTION' );

    $block .= $q->textarea( -name => 'string', -rows => 50, -columns => 200, -default => $string, -force => 1 );

    $block .= $q->hidden( -name => 'cgi_application', -value => 'String_App' ) . $q->submit( -name => 'rm', -value => 'Proof Read', -class => 'ACTION' ) . $q->end_form();

    return $block;
}

#
#
#
# Return: array of (before string, after string, warnin string)
####################
sub check_string {
####################
    my $string = shift;
    my $context_length = shift || 20;    ## length of context string in case of warnings...

    my ( @index, @before, @after, @warnings );

    my $remaining = $string;
    my $reformatted;

    my $index = 0;
    while ( $remaining =~ /^(.*?)(\$|dollars)(.*)$/ ) {
        my $prefix_length = length($1);
        $remaining = $2 . $3;

        $index += $prefix_length;
        my ( $prefix, $dollars, $decimal, $cents );

        if ( $remaining =~ s/^(\$[\s\-]?)([\d\,]+)(\.?)([\d]*)// ) {
            ## $ 122,000.22
            $prefix  = $1;
            $dollars = $2;
            $decimal = $3;
            $cents   = $4;

            my $before = $prefix . $dollars . $decimal . $cents;

            $dollars =~ s/[\s,]//g;
            $prefix  =~ s/[\s\-]//g;

            $reformatted = $prefix . $dollars . $decimal . $cents;
            push @before, $before;
            push @after,  $reformatted;
            push @index,  $index;

            my $section_length = length($before);
            $index += $section_length;
        }
        else {
            $remaining =~ s/^.//;
            push @warnings, $index;
            $index++;
        }
    }

    return ( \@index, \@before, \@after, \@warnings );
}

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

None.

=head1 FUTURE IMPROVEMENTS <UPLINK>

More string parsing functionalities.

=head1 AUTHORS <UPLINK>

Ran Guin and Andy Chan at the Canada's Michael Smith Genome Sciences Centre.

=head1 CREATED <UPLINK>

2003-07-15

=head1 REVISION <UPLINK>

$Id: String.pm,v 1.6 2003/11/27 19:43:01 achan Exp $ (Release: $Name:  $)

=cut

return 1;
