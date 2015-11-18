################
# Parser.pm
#
# <concise_description>
#
# This module contains a utility method called that enables easy access to data from the tables embedded within html files of this sort. (Assuming that the data of interested is contained within a HTML table structure).  It also has a wrapper which takes a Hash containing the name of the tables and fields requested and use the forementioned method to extract and display the field values in a easy to read format on the screen.
# Assumptions on the HTML file:
# - There are no undefined tags and it is well-formed (i.e. all elements has a begin and end tag)
# - The name of each table is directly above the table
# - A field can only appear in 1 table row/column once.  (i.e. if the field "Lane" is in column 1, it can't appear in column 2)
# - The field header must be located at either the first row of the table (horizontal) or the first column (vertical)
# - Rows that are empty will be ignored
################

package HTML_Parser;

# note to self: put this in RGTools
##############################
# perldoc_header             #
##############################

=head1 SYNOPSIS <UPLINK>

 Usage:

	## for single row or single column tables ##
    
	my ($chip_data) = extract_data(-file_name=>'summary.html',-table=>'Chip Summary',-fields=>['Run Folder']);
	my $run_folder = $chip_data->{'Run Folder'};
    
    # Note: put dumper of chip_data (data struct)

	## returns array of hashes ##
	## future action: add a filter input parameter which allows the user to specify the value of the row.

	my @lane_data        = extract_data(-file=>'summary.html', 
				      -table=>'Lane Parameter Summary',
				      -fields=>['Lane','Sample ID','Sample Target','Sample Type', 'Length', 'Filter', 'Titles'],
					
				);
	

=head1 DESCRIPTION <UPLINK>

=cut

#################################
use strict;
use Data::Dumper;
use RGTools::Table_Content_Parser;
use RGTools::RGIO;

use SDB::HTML;
use SDB::CustomSettings;

use HTML::Parser;
use Time::localtime;

use Carp;
use Shell qw(cat);
######################################
# constructor for the Class
################################################################
sub new {
################################################################
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = &filter_input( \@_ );

    my $self = {};

    bless $self, $class;

    # DB Handle

    return $self;
}

###############
# Return data from a HTML file in the fields specified in the array (the utility method)
#################
sub extract_data {
#################
    # Assume the fields in the array are arranged in the order they appear.  Top to bottom (for vertical table), Left to right (for horizontal table)
    my %args           = &filter_input( \@_, -args => 'file_name,table,fields,skip,table_type' );
    my $html_file_name = $args{-file_name};                                                         # name of html file with full path
    my $table_name     = $args{-table};                                                             # name of the table we are looking for
    my @fields         = @{ $args{-fields} };                                                       # fields of the table we are interested in  (Optional). If user pass in more than 1 field, we considered the user is extracting lane data
    my $table_type     = $args{-table_type};

    my $skip = $args{-skip} || 0;                                                                   # specify the number of rows from the top to skip over when we look for the field name(Optional)

    # Read the html file and put it into a string variable.
    my $html_file_as_string = try_system_command("cat $html_file_name");
    my @indices;
    $html_file_as_string =~ /($table_name(.*?)<table(.*?)<\/table>)/ims;                            #ims
    $html_file_as_string = $1;

    #-------------remove when done begin
    #my $NLOG;

    #   open($NLOG,'>',"before");
    #  print $NLOG $html_file_as_string;
    # close $NLOG;

    #-------------remove when done ends

    # $_ = $1;
    #remove empty rows
    $html_file_as_string =~ s/<tr>(\s|\n|\r)+<\/tr>//;

    #-------------remove when done begin

    #    open($NLOG,'>',"after");
    #   print $NLOG $html_file_as_string;
    #  close $NLOG;

    #-------------remove when done ends

###############3

    ##################################################################
    #  Use TableContentParser's parse method to get the table
    #  - input: the html file as  string, the name of the table.
    #  - output: contents of the table as a 2 dimensional array if it exists in the HTML file
    # Notes: TableContentParser uses HTML::TableContentParser

    my $TCP = new Table_Content_Parser();

    my $TCP_hash = $TCP->parse($html_file_as_string);    ## hash  [ { 'rows' => {'cells'=>[ {'data' => r1c1 },
    ##									{'data' => r1c2 },
    ##										....
    ## convert hash (see above) to array of hashes (indexed on field name - eg col 1 or row 1)
    ## determine if in rows or cols
    #   skip parameter: specify the number of lines to be skip from the top row when we look for the fields.  Eg skip=>1, we look for the fields in line 2
    my $element_count;
    my $number_of_fields;
    if (@fields) {
        $number_of_fields = scalar @fields;

        #           print "table_type: $table_type,number of fields: $number_of_fields,skip = $skip\n";
        if ( $table_type == 0 ) {
            @indices = @{ _get_field_indices_by_col( -hash_ref => \$TCP_hash, -fields => \@fields, -skip => $skip ) };
            $element_count = scalar @indices;

            #                print "element count:$element_count\n";
            # if the indices of all the fields are found, return the hash
            if ( $element_count == $number_of_fields ) {

                return _populate_hash( -hash_ref => \$TCP_hash, -fields => \@fields, -indices => \@indices, -skip => $skip + 1, -table_type => 0 );
            }
            else {
                return undef;
            }
        }
        else {    #either it's a vertical table or some of the table fields are not defined
                  #print "look at vert table,skip = $skip\n";

            @indices = @{ _get_field_indices_by_row( -hash_ref => \$TCP_hash, -fields => \@fields, -skip => $skip ) };

            # print "b4 calling scalar what's in indicies: ".Dumper(@indices)."\n";
            $element_count = scalar @indices;

            #  print "what's in indicies: ".Dumper(@indices).",element count: $element_count\n";
            if ( $element_count == $number_of_fields ) {    #table field not defined
                return _populate_hash( -hash_ref => \$TCP_hash, -fields => \@fields, -indices => \@indices, -skip => $skip + 1, -table_type => 1 );

            }
            else {

                #    print "tf undef return undef\n";
                return undef;
            }

        }

    }    # user specified fields

    #		## elsif ($rows) { @fields = _get_row(\%TCP_hash,-row=>1+$skip); @indices = (1..int(@fields)) }
    #		## else { @fields = _get_col(\%TCP_hash,-col=>1+$skip); indices = (1..int(@fields)) }
    #        if (@fields) { #it's a horizontal table

    #    my @fields = _get_row(\$TCP_hash,-row=>1+$skip);

    #   my @indices = (1..int(@fields));
    #        }
    ## populate hash given @array(nxn),@field_names, @indices (same size as @field_names).
    ## assumptions (field_names match exactly to $array[0][N] (or $array[N][0] if in rows)
    ## include option for skipping N rows.
    #		## eg @result = _populate_hash(\%TCP_hash,\@field_names,\@indices,-skip=>1);

    ## return array of hashes:
    #	eg [
    #		{'% Phasing' => '0.6000', '% Prephasing' => '0.3100'}
    #		, {'% Phasing' => '0.07'...} ##  if multiple rows
}

###############################################
# locate which column has the fields we are looking for
###############################################
sub _get_field_indices_by_col() {
#############################

    my %args     = &filter_input( \@_, -args => 'hash_ref,fields,skip', -mandatory => 'hash_ref,fields' );
    my $hash_ref = $args{-hash_ref};
    my $fields   = $args{-fields};
    my $skip     = $args{-skip};
    my @indices;

    # for each field in the fields array, match it against the cell data for each cell in the row specified by skip
    #   print "val in 1st r, 2st col: $$hash_ref->[0]->{rows}->[0]->{cells}[1]->{data}\n";
    # print "what's the whole hash: ".Dumper($hash_ref)."\n";
    my $row = $$hash_ref->[0]->{rows}->[$skip];

    my $cells = $row->{cells};
    my $field;
    my $cell;
    my $i;
    my $j;

    #this is right

    #     print "what's in row array: ".Dumper($row).", number of rows:".@{$$hash_ref->[0]->{rows}}."\n";
    #      print "what's in cells array: ".Dumper($cells).", number of elements in cells:".@{$cells}."\n";
    my $key;
    my $value;
    my $data;
    foreach $field (@$fields) {

        # put matched indices into the result array
        for ( $i = 0; $i < @{$cells}; $i++ ) {
            $data = $cells->[$i]->{data};
            $data =~ s/^\s*(\S*(?:\s+\S+)*)\s*$/$1/;

            #           print "data: $data,field: $field at $i\n";
            if ( $data eq $field ) {

                #                print "data: $data,field: $field match at $i\n";
                push( @indices, $i );
            }
        }
    }

    #    print "what's in indices: ".Dumper(@indices)."\n";
    return \@indices;
}

###############################################
# locate which row has the fields we are looking for
###############################################
sub _get_field_indices_by_row() {
#############################
    #   print "gfibr\n";
    my %args     = &filter_input( \@_, -args => 'hash_ref,fields,skip', -mandatory => 'hash_ref,fields' );
    my $hash_ref = $args{-hash_ref};
    my $fields   = $args{-fields};
    my $skip     = $args{-skip};
    my @indices;
    my $field;
    my $i;
    my $data;

    # for each field in the fields array, match it against the cell data column specified by skip on each row

    my $rows = $$hash_ref->[0]->{rows};

    foreach $field (@$fields) {

        # put matched indices into the result array
        for ( $i = 0; $i < @{$rows}; $i++ ) {
            $data = $$hash_ref->[0]->{rows}->[$i]->{cells}[$skip]->{data};
            $data =~ s/^\s*(\S*(?:\s+\S+)*)\s*$/$1/;

            #              print "data: $data,field: $field at $i\n";

            if ( $data eq $field ) {

                #                   print "$data matches $field @ $i\n";
                push( @indices, $i );
            }
        }
    }

    #print "what's in indices: ".Dumper(@indices)."\n";

    return \@indices;
}

###########################
# convert hash from the format [to [{field=>data}]
###########################
sub _populate_hash {
###########################

    my %args     = &filter_input( \@_, -args => 'hash_ref,fields,indices,skip,table_type', -mandatory => 'hash_ref,fields,indices,skip,table_type' );
    my $hash_ref = $args{-hash_ref};
    my @fields   = @{ $args{-fields} };
    my @indices  = @{ $args{-indices} };

    #    my @indices = $args{-indices};
    #print "in pop_hash, indicies array:".Dumper(@indices)."\n";
    my $skip       = $args{-skip};
    my $table_type = $args{-table_type};    # 0 for horizontal table, 1 for vertical
    my $i;
    my $data;
    my $j;
    my $rows      = $$hash_ref->[0]->{rows};
    my $row_count = @{$rows};
    my @result    = ();
    my %hash;
    my @pairs = ();
    my $position;
    my $field_array_size = @fields;
    my $key;
    my $result_count = 0;

    #horizontal table
    if ( $table_type == 0 ) {
        for ( $i = $skip; $i < $row_count; $i++ ) {
            @pairs = ();
            for ( $j = 0; $j < $field_array_size; $j++ ) {
                $position = $indices[$j];
                $data     = $rows->[$i]->{cells}[$position]->{data};
                $key      = $fields[$j];

                #build the hash
                push( @pairs, $key );
                push( @pairs, $data );
            }
            push @result, {@pairs};

        }
    }
    else {    #Vertical table
              #Q: which is the best row for calculate the number of columns
        $position = $indices[0];
        my $cols      = $$hash_ref->[0]->{rows}->[$position]->{cells};
        my $col_count = @{$cols};

        # print "we will look at row $position for the # of cols and we find $col_count coluns, skip = $skip\n";

        for ( $i = $skip; $i < $col_count; $i++ ) {
            @pairs = ();
            for ( $j = 0; $j < $field_array_size; $j++ ) {
                $position = $indices[$j];
                $data     = $rows->[$position]->{cells}[$i]->{data};
                $key      = $fields[$j];

                #build the hash
                push( @pairs, $key );
                push( @pairs, $data );

                #  print "what's in pairs: ".Dumper(@pairs)."\n";
            }
            push @result, {@pairs};

        }

    }

    return \@result;
}
1;
