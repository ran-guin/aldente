##################
# Vector.pm #
##################
#
# This module is used to handle the Vector class
#
# Some included methods include:
# - retrieving information
# - retrieving associated Libraries
# - searching string for possible Restriction Sites and/or Primers
#
##################
package alDente::Vector;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Vector.pm - This module is used to handle the Vector class

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module is used to handle the Vector class<BR>Some included methods include:<BR>- retrieving information<BR>- retrieving associated Libraries<BR>- searching string for possible Restriction Sites and/or Primers<BR>

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
use CGI qw(:standard);
use DBI;
use Benchmark;

#use Storable qw(freeze thaw);
use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use SDB::HTML;
use RGTools::HTML_Table;
use RGTools::Views;
use RGTools::String;
use SDB::DBIO;
use alDente::Validation;
use alDente::SDB_Defaults qw($vector_directory $bin_home);
use alDente::Form qw(Set_Parameters);

##############################
# global_vars                #
##############################
use vars qw( %Settings $Connection %Benchmark);
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

#######
sub new {
#######
    my $this = shift;
    my %args = @_;

    my ($class) = ref($this) || $this;
    my ($self) = {};

    $self->{dbc} = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    ## database handle
    $self->{name} = $args{name} || $args{-name} || get_Table_Param( -field => 'Vector', -dbc => $self->{dbc} );    ## sample type (eg Plate)
    $self->{sequence} = $args{sequence} || $args{-sequence} || param('String');                                    ## vector sequence
    $self->{id} = $args{-id} || param('Vector_ID');

    bless $self, $class;
    if ( $self->{id} || $self->{name} ) {
        $self->load_Sequence();
    }
    return $self;
}

##############################
# public_methods             #
##############################

####################
sub load_Sequence {
####################
    #
    # load class sequence from file or database
    #
    my $self = shift;
    my %args = @_;

    my $id = $args{id} || $self->{id};
    my $name = $args{name} || $self->{name} || '';
    my $dbc = $self->{dbc};

    if ($id) {
        ($name) = $dbc->Table_find( 'Vector_Type,Vector', 'Vector_Type_Name', "WHERE FK_Vector_Type__ID=Vector_Type_ID AND Vector_ID = $id" );
        $self->{name} = $name;
    }

    unless ( $self->{sequence} ) {    ### skip if already defined

        ### first try to get it from the Database ###
        ( $self->{sequence} ) = $dbc->Table_find( 'Vector_Type', 'Vector_Sequence', "where Vector_Type_Name = '$name'" );

        unless ( $self->{sequence} ) {    ### skip if already defined
            my ($sequence_file) = $dbc->Table_find( 'Vector_Type', 'Vector_Sequence_File', "where Vector_Type_Name = '$name'" );
            my $sequence = `cat $vector_directory/$sequence_file`;
            if ( $sequence =~ /(.*?)\n(.*)/ms ) {
                $sequence = $2;
                $sequence =~ s/\s//sg;
                $self->{sequence}      = $sequence;
                $self->{sequence_file} = $sequence_file;
            }
            else {
                $self->{sequence} = '';
            }
        }
    }
    return length( $self->{sequence} );
}

##################
sub initiate_Search {
##################
    #
    # Initiate search for string / restriction site / primers
    #
    my $self = shift;
    my %args = @_;
    my $text = $args{-text};

    my $dbc = $self->{dbc};
    my $string = $self->{sequence} || '';

    ### just pull out ones that have been updated...
    my @vectors = $dbc->Table_find( 'Vector_Type', 'Vector_Type_Name', "where 1 Order by Vector_Type_Name" );

    print alDente::Form::start_alDente_form( $dbc, 'help', undef );
    print "Vector : "
        . alDente::Tools::search_list(
        -dbc     => $dbc,
        -name    => 'Vector',
        -options => \@vectors,
        -search  => 1,
        -filter  => 1,
        -default => $self->{name},
        -tip     => ".. or Copy vector sequence to text area below..."
        );

    print "<BR><i>Current Vectors in the Database (which have defined Antibiotic Markers)</i>";

    #        Show_Tool_Tip(
    #	#			      popup_menu(-name=>'Vector',-values=>\@vectors),
    #				      "Current Vectors in the Database (which have defined Antibiotic Markers)");
    #    print "<P>.. or Copy vector sequence to text area below...<P>";
    print textarea( -name => 'String', -rows => $text, -cols => 100, -default => $string );
    print br
        . submit(
        -name  => 'Search Vector for String',
        -value => 'Search Sequence',
        -style => "background-color:yellow"
        );
    print &hspace(10) . '<B> For:</B> ';
    print checkbox( -name => 'Search For', -value => 'Primers',           -label => 'Primers',           -checked => 1 );
    print checkbox( -name => 'Search For', -value => 'Restriction Sites', -label => 'Restriction Sites', -checked => 1 );
    print &hspace(50) . checkbox( -name => 'Include Line Indexes', -checked => 1 ) . '<p ></p>';

    return;
}

######################
sub search_Sequence {
######################
    #
    # Search Sequence for strings
    #

    my $self = shift;
    my %args = @_;

    my $complement = $args{complement} || 0;                  ## search for complement as well.
    my $string = $args{string} || $self->{sequence} || '';    ## string to search

    my $substrings   = $args{substrings};                     ## list of strings to search for
    my $labels       = $args{labels};
    my $link         = $args{link};
    my $colour       = $args{colour};
    my $hover_colour = $args{hover_colour};
    my $loop         = $args{-loop};                          ## input string should loop over on itself for N characters
    my $quiet        = $args{-quiet};

    my $dbc = $self->{dbc};

    if ($loop) { $string .= substr( $string, 0, $loop ) }     ## loop back to include first $loop base pairs
    my $case_sensitive = 0;

    my @Labels = @{$labels} unless !$labels;
    my @string_list;
    my @reference_list;
    if ($substrings) {
        @string_list = @{$substrings};
    }

    my %Complement;
    my %Label;
    my $index = 0;
    ## define references (in case of complements)
    foreach my $substring (@string_list) {
        $substring =~ s /\s//sg;    ## get rid of spaces & linefeeds
        while ( $substring =~ /([a-z])\((\d+)\)/i ) {    ## replace g(4) with gggg
            my $replacement = $1 x $2;
            $substring =~ s/$1\($2\)/$replacement/sg;
        }
        next unless $substring;
        $Label{ uc($substring) } = $Labels[$index] || $substring;    ## define labels for the substrings if supplied

        if ($complement) {
            my $complement_string = string_complement($substring);    ##  `$bin_home/complement.pl -s $substring -c -r -b`; #
            if ( $complement_string ne $substring ) {
                push( @reference_list, $substring );

                push( @reference_list, $complement_string );
                my $comp_label = $Labels[$index] || $substring;
                $Label{ uc($complement_string) } = $comp_label;       ## define labels for the substrings if supplied
            }
            else {
                push( @reference_list, $substring );
            }
            $Complement{$complement_string} = $substring;             ## refer to original string matches
        }
        else {
            push( @reference_list, $substring );
        }

        $index++;
    }

    my %Results;
    $Results{Complements} = 0;
    $Results{Found}       = 0;

    unless ( $string =~ /\S+/ ) { Message("No Sequence Found") unless $quiet }

    my $String = String->new( -text => $string );
    $String->find_matches( -searches => \@reference_list, -group => 1 );

    unless ( $String->{matches}->{count} ) { Message("No Matches Found") unless $quiet }

    my $show = '';
    $index = 0;
    while ( defined $String->{matches}->{sections}->{ ++$index } ) {
        my $start     = $String->{matches}->{sections}->{$index}->{start};           ## start index for section
        my $end       = $String->{matches}->{sections}->{$index}->{end};             ## end index for section
        my $length    = $String->{matches}->{sections}->{$index}->{length};          ## length of section
        my $substring = $String->{matches}->{sections}->{$index}->{text};            ## substring of section
        my @matches   = @{ $String->{matches}->{sections}->{$index}->{matches} };    ## array of matched substrings

        my @refs;
        my @labels;
        my $this_label = '';
        foreach my $match (@matches) {                                               ## get the references to the matches
            my $ref   = $Complement{$match} || $match;
            my $label = $Label{ uc($ref) }  || $ref;
            push( @refs,   $ref )   unless grep /^$ref$/,   @refs;
            push( @labels, $label ) unless grep /^$label$/, @labels;
        }
        my $references = join ',', @refs;
        $this_label = join ' + ', @labels;

        if ($references) {
            $show .= &Link_To( $dbc->config('homelink'), $substring, "$link=$references", -window => ['sites'], -tooltip => $this_label );

            #$show .= Show_Tool_Tip($substring,$this_label);
        }
        else {
            $show .= $substring;
        }
    }
    $show ||= $String->{text};

    foreach my $key ( keys %{ $String->{matches}->{searches} } ) {
        next unless $key;

        my $matched = int( @{ $String->{matches}->{searches}->{$key} } );
        if ( $Complement{$key} && ( $Complement{$key} ne $key ) ) {
            $Results{Complements} += $matched;

            $show =~ s />$key</><i>$key<\/i></ig;    ### highlight complements
        }
        else {
            $Results{Found} += $matched;
        }
        if ($matched) { $Results{Site}->{$key} = $matched; }
    }
    $Results{String} = $show;
    return %Results;
}

#
# To run whenever new vector record is added
# (slightly different call when new Primer record is added)
#
# Note: currently does not account for direction, though this could be worked in
#
# Return 1 on success
###########################
sub new_Vector_trigger {
###########################
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    #my ($id)      = $dbc->Table_find( 'Vector_Type', 'Max(vector_Type_ID)' );
    my $ok;

    my ($name) = $dbc->Table_find( 'Vector_Type', 'Vector_Type_Name', "Where Vector_Type_ID = $id" );
    my $self = new alDente::Vector( -dbc => $dbc, -name => $name );
    my @valid_primers = $self->find_tags( -type => 'Primer', -complement => 1, -condition => "Primer_Type = 'Standard'", -quiet => 1 );

    foreach my $primer (@valid_primers) {
        $ok = $self->validate_Primer( -primer_name => $primer );    ## add to VectorPrimer table
        if ($ok) { Message "Validated primer ($primer) for vector ($name) " }
    }
    if   ($ok) { Message "Validation successful!" }
    else       { Message "Failed to find any vectors to match primer sequence" }
    return $ok;

}

########################################################################
#
# Retrieve a list of tags found within a vector
#
#  (in this case, a tag is a Primer or Enzyme sequence - or its complement - found within the Vector Sequence)
#  While designed for Primers or Enzymes, it should work for any Table element that contains a .._Name field and a .._Sequence field.
#
# This assumes the existing functionality from String::find_matches

# <snip>
#
#   # example - may be used by new Vector trigger to find all valid primers for a new vector
#   my @valid_primers = $self->find_tags(-type=>'primer',-complement=>1);
#   foreach my $primer (@valid_primers) { $self->validate_Primer($primer) }
#
#   # example to check if a given primer is in the vector (in this case the complement is excluded)
#   my $found_primer = $self->find_tags(-type=>'primer', -name=>'T7');  ## returns 1 if found
#
#   # example called as a function (not requiring loading of Vector object - may be easier within loop)
#   my @enzymes = alDente::Vector::find_tags(-sequence=>$sequence,-type=>'enzyme',-complement=>1);
#
#   # example using explicit strings (not using database)
#   my @tags = $self->find_tags(-search=>['CATG','AGGCT']
#
# </snip>
#
# Return: array of elements found (empty array if nothing found)
##################
sub find_tags {
##################
    my $self       = shift;
    my %args       = filter_input( \@_, -mandatory => 'type|search' );
    my $sequence   = $args{-sequence} || $self->{sequence};              ## current vector sequence (or optionally supply an explicit sequence)
    my $type       = $args{-type};                                       ## options for Primer or Enzyme
    my $name       = $args{-name};                                       ## optionally specify particular Name(s) (eg Primer Name) (defaults to check all records in database)
    my $condition  = $args{-condition};                                  ## optional condition for inclusion of records from $type in database (eg "Primer_Type = 'Standard'")
    my $search     = $args{-search};                                     ## optional inclusion of explicit tags to search for
    my $complement = $args{-complement};                                 ## check for complement string as well
    my $dbc        = $self->{dbc};
    my $quiet      = $args{-quiet};

    $condition = ' AND ' . $condition if $condition;

    unless ($sequence) {
        Message 'No sequence entered for finding tags';
        return;
    }

    my ( @substrings, @labels );
    my @names;                                                           ## optional list of item names checked fo

    if ($search) {
        ## search tags supplied explicitly ##
        @substrings = Cast_List( -list => $search, -to => 'array' );

        #foreach my $string (@substrings) { $Labels{$string} = $string }
        @labels = @substrings;
    }
    elsif ($name) {
        ## object names explicitly supplied (optional)
        my $name_list           = Cast_List( -list => $name, -to => 'string', -autoquote => 1 );    ## convert to quoted string for use in SQL query ##
        my $sequence_field_name = $type . '_Sequence';
        my $name_field_name     = $type . '_Name';

        @substrings = $dbc->Table_find( $type, $sequence_field_name, " WHERE $name_field_name IN ($name_list) " . $condition . " Order by $name_field_name" );    ##  list of sequence tags to search for (keep track of labels for each 'substring')
        @labels     = $dbc->Table_find( $type, $name_field_name,     " WHERE $name_field_name IN ($name_list) " . $condition . " Order by $name_field_name" );    ## = list of labels for each tag (eg primer name)
    }
    else {
        ## get all items of specified type from database (may filter on condition (eg Standard Primers)
        my $sequence_field_name = $type . '_Sequence';
        my $name_field_name     = $type . '_Name';

        @substrings = $dbc->Table_find( $type, $sequence_field_name, " WHERE 1 " . $condition . " Order by $name_field_name" );                                   ##  list of sequence tags to search for (keep track of labels for each 'substring')
        @labels     = $dbc->Table_find( $type, $name_field_name,     " WHERE 1 " . $condition . " Order by $name_field_name" );                                   ## = list of labels for each tag (eg primer name)
    }
    ## execute search (using existing String method)

    my %Found = $self->search_Sequence(
        string     => $sequence,
        substrings => \@substrings,
        labels     => \@labels,
        complement => $complement,
        -loop      => 10,
        -quiet     => $quiet
    );

    my $counter;
    my %Labels;
    for my $label_found (@labels) {
        my $key   = $labels[$counter];
        my $value = $substrings[$counter];
        $value =~ s/ //g;    # get rid of spaces
        $Labels{$key} = $value;
        $counter++;
    }

    my @tags;
    foreach my $tag_found ( keys %{ $Found{Site} } ) {

        ## get label for each sequence tag found ##
        for my $tag_label ( keys %Labels ) {
            my $tag_value = $Labels{$tag_label};

            if ( uc($tag_found) eq uc($tag_value) ) {
                push @tags, $tag_label;
            }
            if ( uc( string_complement($tag_found) ) eq uc($tag_value) ) {
                push @tags, $tag_label if $complement;
            }
        }
    }
    return @tags;
}

########################################################################################################
# Simple accessor to update of VectorPrimer table which keeps track of 'Valid' Primers for a given vector
#
# <snip>
#  eg $self->validate_Primer(-primer_name => 'T7');
#
# </snip>
#
########################
sub validate_Primer {
########################
    my $self        = shift;
    my %args        = @_;
    my $dbc         = $self->{dbc};
    my $primer_name = $args{-primer_name};
    my $primer_id   = $args{-primer_id};
    my $sense       = $args{-sense} || 'N/A';                 ## optional indication of Direction (sense/anti-sense; Fwd/Rev etc) - can this be based on whether primer is complemented in sequence ?
    my $vector_name = $args{-vector_name} || $self->{name};

    my ($vector_id) = $dbc->Table_find( 'Vector_Type', 'Vector_type_ID', "WHERE Vector_Type_Name = '$vector_name'" );

    unless ($primer_id) {
        ($primer_id) = $dbc->Table_find( 'Primer', 'Primer_ID', "WHERE Primer_Name = '$primer_name'" );
    }
    if ( $vector_id && $primer_id && $sense ) {
        my @fields = ( 'FK_Vector_Type__ID', 'FK_Primer__ID', 'Direction' );
        my @values = ( $vector_id, $primer_id, $sense );
        my $ok = $dbc->Table_append_array( "Vector_TypePrimer ", \@fields, \@values, -autoquote => 1 );
        return $ok;
    }
    return;
}

#######################
sub search_Vector {
#######################
    my $self = shift;
    my %args = @_;

    my $search_type = $args{search} || join ',', param('Search For');
    my $string      = $args{string};
    my $print       = $args{print} || 0;
    my $width       = $args{width} || 100;
    my $indexed     = $args{indexed} || 0;
    my $loop        = $args{-loop} || 10;                               ## input string should loop over on itself for N characters

    my $quiet = $args{-quiet};

    my $dbc = $self->{dbc};

    my @string_list;
    $string = $self->{sequence} || $string;

    if ($loop) { $string .= substr( $string, 0, $loop ) }               ## loop back to include first $loop base pairs

    my @found;
    my @headers;

    my $Found_summary = new HTML_Table( -title => "$self->{name} search results", -valign => 'top' );

    my %Match;

    my @site_labels;
    my $link;
    my $colour;
    my $type;
    ### Search for Restriction Sites ###
    if ( $search_type =~ /^(enzymes|restriction sites)$/i ) {
        $type        = 'Enzyme';
        @site_labels = $dbc->Table_find_array( 'Enzyme', [ "Enzyme_Name", "UPPER(replace(Enzyme_Sequence,' ',''))" ], "where Length(Enzyme_Sequence) > 0 Order by Length(Enzyme_Sequence),Enzyme_Name", 'Distinct' );
        $colour      = 'purple';

        #        my @found;

        $link = "&Info=1&Table=Enzyme&Field=Enzyme_Name&Like";
    }
    elsif ( $search_type =~ /^primers$/i ) {
        $type        = 'Primer';
        @site_labels = $dbc->Table_find_array( 'Primer', [ 'Primer_Name', "UPPER(REPLACE(Primer_Sequence,' ',''))" ], "where Length(Primer_Sequence) > 0 and Primer_Type = 'Standard' Order by Length(Primer_Sequence),Primer_ID", 'Distinct' );
        $link        = "&Info=1&Table=Primer&Field=Primer_Name&Like";
        $colour      = 'blue';
    }
    else {
        $type   = '';
        $colour = 'purple';
        $link   = '';
        my @RS_labels = $dbc->Table_find_array( 'Enzyme', [ "Concat('Restriction Site: ',Enzyme_Name) as Name", "UPPER(replace(Enzyme_Sequence,' ',''))" ], "where Length(Enzyme_Sequence) > 0 Order by Length(Enzyme_Sequence),Enzyme_Name", 'Distinct' );
        my @P_labels
            = $dbc->Table_find_array( 'Primer', [ "Concat('Primer: ',Primer_Name)", "UPPER(REPLACE(Primer_Sequence,' ',''))" ], "where Length(Primer_Sequence) > 0 and Primer_Type = 'Standard' Order by Length(Primer_Sequence),Primer_ID", 'Distinct' );
        push @site_labels, @RS_labels;
        push @site_labels, @P_labels;
    }

    my ( @sites, @labels );
    foreach my $site_label (@site_labels) {
        my ( $label, $site ) = split ',', $site_label;

        #push @found, &Link_To($dbc->homelink(),$label,"$link=$label",$Settings{LINK_COLOUR},['newwin2'], -tooltip=>$site) unless (grep /^$label$/, @labels);
        push( @sites,  $site );
        push( @labels, $label );
        $Match{$site} = $label;
    }

    my %Search = $self->search_Sequence(
        string       => $string,
        substrings   => \@sites,
        labels       => \@labels,
        link         => $link,
        complement   => 1,
        colour       => $colour,
        hover_colour => 'red',
        -loop        => $loop,
        -quiet       => $quiet
    );

    my $sites_found  = $Search{Found};
    my $Csites_found = $Search{Complements};
    $string = $Search{String};    ### update string with these replacements...
    my @unique = keys %{ $Search{Site} };

    my $unique_list = join ',', map { $Match{$_} } @unique;

    foreach my $type ( split ',', $search_type ) {
        $type =~ s/s$//;          ## clear
        my $Matches_found = "<UL>\n";

        foreach my $site (@unique) {
            my $name = $Match{$site} || $Match{ string_complement($site) };
            if ( ( $search_type !~ /,/ ) || ( $name =~ s/^$type: // ) ) {
                my $link = &Link_To( $dbc->config('homelink'), "$name (x$Search{Site}{$site})", "$link=$name", -colour => 'purple', -hover_colour => 'red', -tooltip => $site );
                $Matches_found .= "\n<LI>" . $link;
            }

        }
        $Matches_found .= "</UL>\n";
        push @found,   $Matches_found;
        push @headers, $type;
    }

    if ($print) {
        my $tip = "FOUND: $unique_list";
        my $link = &Link_To( $dbc->config('homelink'), " (" . int(@unique) . " Unique)", "$link=$unique_list", $Settings{LINK_COLOUR}, ['newwin2'], -tooltip => $tip, -colour => $colour, -hover_colour => 'red' );
        Message("Found $sites_found <i>(+ $Csites_found Complemented)</i> ${type}s $link") unless $quiet;
    }

    my $output;
    if ($print) {
        if ( $self->{name} ) { $output .= &Views::sub_Heading( $self->{name} ) }

        $output .= "<span class=small>";
        $output .= String::split_tagged_string( -string => $string, -width => $width, -separator => "<BR>", -hidden_tags => 'script', -indexed => $indexed );
        $output .= "</span>";
    }

    if ($loop) { $output .= "<P><B>Note:  Vector sequence is extended by looping back to include the first $loop base pairs at the end of the defined sequence.</B><BR>This may result in repeated matches found over this region. <P>" }

    $Found_summary->Set_Headers( \@headers );
    $Found_summary->Set_Row( [@found] );
    $output .= hr . $Found_summary->Printout(0);

    return $output;
}

#########################
sub string_complement {
    #####################
    my $string = shift;

    my $comp = `$bin_home/complement.pl -s $string -c -r -b`;
    chomp $comp;
    return $comp;
}

##############################
# public_functions           #
##############################

###################
sub list_Vectors {
###################
    my %args = &filter_input( \@_, -args => 'dbc' );
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $library         = $args{-library};
    my $project         = $args{-project};
    my $vector          = $args{-vector};
    my $extra_condition = $args{-condition} || 1;

    if ($project) {
        $extra_condition .= " AND Project_Name = '$project'";
    }
    if ($library) {
        $extra_condition .= " AND Library_Name IN ('$library')";
    }
    if ($vector) {
        $extra_condition .= " AND Vector_Type_Name LIKE '$vector'";
    }

    my $all            = param('Include All Vectors');    ### allow viewing of unused vectors
    my $active_vectors = join ',',
        $dbc->Table_find( 'Project,Library,Vector,LibraryVector,Vector_Type', 'Vector_Type_Name', "WHERE FK_Vector_Type__ID=Vector_Type_ID AND FK_Vector__ID=Vector_ID AND FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID AND $extra_condition" );
    $extra_condition =~ s/^1( AND |)//;
    Message($extra_condition) if $extra_condition;

    return SDB::DB_Form_Viewer::view_records( $dbc, 'Vector_Type', 'Vector_Type_Name', $active_vectors );
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

$Id: Vector.pm,v 1.13 2004/11/09 00:51:37 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
