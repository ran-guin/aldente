################################################################################
#
# HTML.pm
#
# HTML: Misc HTML specific tools
#
################################################################################
# $Id: HTML.pm,v 1.5 2004/11/30 01:43:42 rguin Exp $
################################################################################
package SDB::HTML;

use base LampLite::HTML;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

HTML.pm - HTML: Misc HTML specific tools 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
HTML: Misc HTML specific tools <BR>

=cut

##############################
# superclasses               #
##############################
#
@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    space
    hspace
    vspace
    lbr
    url_encode
    url_decode
    get_Table_Param
    get_Table_Params
    get_param
    set_ID
    html_box
    standard_label
    layer_list
    define_Layers
    accordion
    HTML_list
    HTML_Dump
    set_validator
    create_tree
    display_date_field
    page_heading
    section_heading
    subsection_heading
);

##############################
# standard_modules_ref       #
##############################

use Carp;
use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;
use RGTools::Conversion;

use LampLite::Bootstrap;

use LampLite::CGI;

my $q = new LampLite::CGI;

##############################
# global_vars                #
##############################
use vars qw($image_dir $homelink $Sess %Configs $Connection);
use vars qw($SDB_submit_image $SDB_Move_Right $SDB_Move_Left $SDB_Move_Up $SDB_Move_Down);

my $BS = new Bootstrap;

### Default Colour Scheme ###
my $tab_clr = '#99c';
my $off_clr = '#ccccff';

## section headings ##

## Use CSS instead to define these ###

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

#################################################################################
## To support legacy calls, pass on calls to LampLite methods as applicable ##
#################################################################################

sub set_validator { return LampLite::HTML::set_validator(@_) }

sub HTML_Dump { return LampLite::HTML::HTML_Dump(@_) }

sub create_tree { return LampLite::HTML::create_tree(@_) }

sub clear_tags { return LampLite::HTML::clear_tags(@_) }

sub display_date_field { return LampLite::HTML::display_date_field(@_) }

sub page_heading { return LampLite::HTML::page_heading(@_) }
sub section_heading { return LampLite::HTML::section_heading(@_) }
sub subsection_heading { return LampLite::HTML::subsection_heading(@_) }



#################################################################################
#################################################################################

#########
sub space {
#########
    my $width = ( defined $_[0] ) ? $_[0] : 2;

    return "<img src='/SDB/$image_dir/Space.png' height=1 width=$width>";
}

#############################
# simple horizontal space
#
##########
sub hspace {
##########
    my $width = ( defined $_[0] ) ? $_[0] : 2;

    my $height = '1px';
    $width .= 'px';
    return "\n<img src='/SDB/images/png/Space.png' class='hspace' style='height:$height; width:$width'>\n";
}

#############################
# simple vertical space
#
##########
sub vspace {
##########
    my $height = shift;

    $height ||= 1;

    $height .= 'px';
    my $width = '1px';

    return "\n<BR><img src='/SDB/images/png/Space.png' class='vspace' style='height:$height; width:$width'><br>\n";
}

#############
# linebreak - includes both "\n" and <BR>.
#########
sub lbr {
#########
    return "<BR>\n";
}

##################
sub url_encode {
##################
    my $string = shift;

    eval "require MIME::Base32";

    return MIME::Base32::encode($string);
}

##################
sub url_decode {
##################
    my $string = shift;

    eval "require MIME::Base32";

    return MIME::Base32::decode($string);
}

###############
sub Window_Alert {
###############
    my $message = shift;
    print "\n<Img Src='/SDB/$image_dir/Space.png' onLoad=\"sendAlert('$message')\">\n";
    return;
}

########################
sub tidy_tags {
########################
    my $string = shift;
    my $indent = shift;

    my $tab = "\t" if $indent;

    $string =~ s /<\/t(r|d|able)>/<\/t$1>\n/ig;    ## linefeed after closing tag

    $string =~ s /<table>/<table>\n/ig;            ## linfeed after opening tag
    $string =~ s /<tr>/$tab<tr>\n/ig;              ## linefeed + indent
    $string =~ s /<td>/$tab$tab<td>/ig;            ## linefeeed + indent + indent

    return $string;
}

########################
sub get_Table_Params {
########################
    my %args = &filter_input( \@_, -args => 'table,field,input,field_type' );
    my $autoquote = $args{-autoquote};
    return get_Table_Param( %args, -list => 1, -autoquote => $autoquote );
}

#################
# Function to grab a parameter value for a table/field
#########################
sub get_Table_Param {
#########################
    my %args       = &filter_input( \@_, -args => 'table,field,input' );
    my $table      = $args{-table};
    my $field      = $args{-field};
    my $field_type = $args{-field_type};
    my $input_ref  = $args{-input};
    my $list       = $args{-list};
    my $autoquote  = $args{-autoquote};
    my $ref_field  = $args{-ref_field};
    my $default    = $args{-default};
    my $empty      = defined $args{-empty} ? $args{-empty} : [];                                      ### return value if no parameter found (pass 'undef' to return undefined value)
    my $debug      = $args{-debug};
    my $convert_fk = $args{-convert_fk};
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    if ( $empty eq 'undef' ) { $empty = undef }

    my %Input;
    if ($input_ref) {
        %Input = %{$input_ref};
    }

    my $value = undef;

    my @variations;
    if ( $field_type eq 'DateTo' ) {
        @variations = ("to_$field");
        $table      = "to_$table";
    }
    elsif ( $field_type eq 'DateFrom' ) {
        @variations = ("from_$field");
        $table      = "from_$table";
    }
    else {
        @variations = ( "$field", "$field Choice" );
    }

    if ($table) {
        push( @variations, "$table.$field" );
        push( @variations, "$table.$field Choice" );
        ## add options without period ... these (and block above) should be phased out ##
        push( @variations, "$table-$field" );
        push( @variations, "$table-$field Choice" );
    }
    elsif ( $field =~ /\./ ) {
        $dbc->debug_message("Periods should be removed from element ids !");
    }

    if ( my ( $ref_table, $ref_field, $desc ) = SDB::DBIO::foreign_key_check( $field, -dbc => $dbc ) ) {
        ### So that it doesn't confuse fields such as FKParent_Source__ID by Source_ID
        unless ($desc) {
            push( @variations, "$ref_table.$ref_field" );
            push( @variations, $ref_field );
            push( @variations, "$ref_table.$ref_field Choice" );
            push( @variations, "$ref_field Choice" );
        }
    }

    foreach my $key (@variations) {
        if ( $Input{$key} ) { $value = $Input{$key}; last; }    ## if explicitly supplied, use this value first ##

        $value = &get_param( $key, -list => $list, -autoquote => $autoquote, -ref_field => $ref_field, -dbc => $dbc );    ## (returns array ref with list parameter)

        if ( $list && $value ) {
            ## value is an array ref in this case ##
            if ( int( @{$value} ) > 0 && length( $value->[-1] ) > 0 ) {
                ## in case more than one variation element is filled in, only retrieve list from first one found ##
                last;
            }
        }
        else {
            ## value is a scalar in this case ##
            #            unless ($value) {
            #                $value = $Input{$key} if defined $Input{$key};
            #            }
            if ( $value && length($value) > 0 ) { last; }    ## previously failed this test if multiple lines =~/^.+$/) { last }
        }
    }

    if ( $convert_fk && SDB::DBIO::foreign_key_check( $field, -dbc => $dbc ) ) {
        $value = $dbc->get_FK_ID( -field => $field, -value => $value );
    }

    if ($list) {
        if   ($default) { $value ||= [$default] }
        else            { $value ||= $empty }
    }
    else {
        if   ( defined $value && length($value) > 0 ) { return $value }
        else                                          { $value ||= $default }
    }

    return $value;
}

########################################################
# Method to get the parameter value
#
# (It will search through list if array containing blanks)
# - will return first parameter value that has a length of > 0
#
# optionally returns an array with -list parameter set.
#########################################################
sub get_param {
#################
    my %args      = &filter_input( \@_, -args => 'parameter' );
    my $parameter = $args{-parameter};
    my $list      = $args{-list};
    my $autoquote = $args{-autoquote} || 0;
    my $ref_field = $args{-ref_field};                            ## specify that this is a foreign key reference field ...
    my $empty     = $args{-empty};                                ## return undef by default
    my $dbc       = $args{-dbc};

    if ( $empty eq 'undef' ) { $empty = undef }

    my $value;
    my @values;
    foreach my $found ( $q->param($parameter) ) {
        if ( dropdown_header($found) ) { $found = '' }            ## dropdown header ##
                                                                  # <CONSTRUCTION> add a method to clean data before updating and inserting instead of modifying params
                                                                  #$found =~ s/\s+/ /g;
        push( @values, $found ) if defined $found;
        $value = $found if length($found) > 0;
        if ( $found && !$list ) {last}
    }
    map { "'$_'"; } @values if $autoquote;
    map { my $id = $dbc->get_FK_ID( $ref_field, $_ ); $_ = $id; } @values if $ref_field;

    if ( $ref_field && !$dbc ) { Message("references can only be converted with supplied dbc"); }

    if ( $list && @values ) { return \@values }
    elsif ( defined $value ) { return $value; }
    else                     { return $empty }                    ## if nothing found...
}

#
# Wrapper for javascript buttons to enable textfield list to be expanded to a given length
#
# usage:
#  $page .= expand_text_buttons(-element_id=>$eid, -values=>$count);
#
# Options:
#     -options => 'alternate,pad'    ## only include alternate and split options (options include alternate,pad,clear)
#     -orientation  => 'vertical'                    ## puts radio buttons on separate lines (defaults to simple spacing between radio buttons)
#
# Return: radio buttons enabling automatic adjustment of textfield
#########################
sub expand_text_buttons {
#########################
    my %args = filter_input( \@_, -args => 'element_id,values' );
    my $element_id  = $args{-element_id} || int( rand(1000) );            ## form element id
    my $count       = $args{ -values };                                   ## total number of values after expand
    my $options     = $args{-options} || 'alternate,pad,revert,clear';    ## options provided - default to all options (alternate = 'ABAB..', pad = 'AA..BB..')
    my $orientation = $args{-orientation} || 'vertical';                  ## display radio buttons horizontally or vertically
    my $prompt      = $args{-prompt} || $BS->icon('expand');
    my $multiplier  = $args{-multiplier};                                 ## optional form element id that allows dynamic multiplier effect
    my $separator   = $args{-separator} || '&nbsp';                       ## separator between text field and option buttons
    my $onclick     = $args{-onclick};

    my $button_class = 'btn-lg';
    if ( $count < 2 ) {return}                                            ## no reason to expand if only one... (though potentially the multiplier element could result in a target # > 4)

    my $string;
    my $delim = '&nbsp';

    ## generate radio buttons enabling javascript execution of ExpandList ##

    my $block = "<Table font size=-2 padding=0 margin=0 id='$element_id-xblock' style='display:none'><TR><TD>\n";    ## start off with option block hidden

    my $next_row = "</TD><TR><TD>\n";
    my $next_col = "</TD><TD>\n";
    if ( $orientation =~ /vert/i ) {
        ## to orient vertically put radio buttons in small table to avoid weird wrapping effects ##
        $delim = $next_row;
    }
    else {
        $delim = $next_col;
    }

    my $show = "unHideElement('$element_id-xblock'); unHideElement('$element_id-compress'); HideElement('$element_id-expand'); return false;";
    my $hide = "HideElement('$element_id-xblock'); HideElement('$element_id-compress'); unHideElement('$element_id-expand'); return false; ";

    if ($prompt) {
        $string .= $BS->button( -id => "$element_id-expand", -icon => 'expand', -class => $button_class, -onclick => $show, -tooltip => 'expand input options' );
        $string .= $BS->button( -id => "$element_id-compress", -style => 'display:none', -icon => 'compress', -class => $button_class, -onclick => $hide, -tooltip => 'hide input options' );
    }

    my $help
        = "Use buttons below to expand input values across all samples\\n\\nEg. if handling 32 tubes and you enter the values 1,2:\\nclicking AA..BB.. will:\\n* apply 1 to the first 16 samples\\n* apply 2 to the last 16 samples\\n\\nclicking AB..AB.. will:\\n* apply values 1 & 2 alternately for each tube";
    $string .= $BS->button( -icon => 'question', -class => $button_class, -style => "background-color:#ccf", -onclick => "alert('$help'); return false; " ) . "</TD><TR><TD colspan=3>";

    ## option to expand A,B to AA..BB.. ##
    if ( $options =~ /pad/ ) {
        $block .= $BS->button( -icon => 'arrows-h', -class => $button_class, -onclick => "ExpandList('$element_id','$count','pad','$multiplier'); return false;", -tooltip => 'convert 1,2 -> 1,1..2,2..' ) . ' AA..BB ' . $delim;
    }

    ## option to expand A,B to ABABAB... ##
    if ( $options =~ /alternate/ ) {
        $block .= $BS->button( -icon => 'arrows-h', -class => $button_class, -onclick => "ExpandList('$element_id','$count','alternate','$multiplier'); return false;", -tooltip => 'convert 1,2 -> 1,2..1,2..' ) . ' AB..AB ' . $delim;
    }

    ## option to revert textfield
    if ( $options =~ /revert/ ) {
        $block .= $BS->button( -icon => 'reply', -class => $button_class, -onclick => "ExpandList('$element_id','','reset'); return false; ", -tooltip => 'Reset to unexpanded list' ) . ' Reset ' . $delim;

    }

    ## option to clear textfield
    if ( $options =~ /clear/ ) {
        $block .= $BS->button( -icon => 'eraser', -class => $button_class, -onclick => "ExpandList('$element_id','','reset'); SetElement('$element_id','',''); return false; ", -tooltip => 'Clear' ) . ' Clear ' . $delim;
    }

    $block .= "</TD></TR></TABLE>\n";

    return $string . $block;
}

#
# Clears cases in which option chosen is simply a dropdown menu title (eg '-- no valid options --' or '-- Select option from below --')
#
#
#
#####################
sub cleanse_input {
#####################
    my $input = shift;

    my %Hash;
    if ($input) {
        %Hash = %$input;
        foreach my $key ( keys %Hash ) {
            my $value = $Hash{$key};
            if ( SDB::HTML::dropdown_header($value) ) {
                ## this is a dropdown menu heading - NOT AN INPUT VALUE ##
                $Hash{$key} = '';

                #		$q->param(-name=>$key, -value=>'');  ## clear URL parameter as well to be safe..
            }
        }
    }
    return \%Hash;
}

# Boolean
#
# Return: 1 if value is only a dropdown header
#######################
sub dropdown_header {
#######################
    my $value = shift;

    if ( $value =~ /^--(.+)--$/ ) {
        return 1;
    }
    else {
        return;
    }
}

#
# predefine URL Parameters for standard SDB form
#
# <snip>
# eg.
#   my %Parameters = SDB::HTML::URL_Parameters($dbc,-set=>{'extra_parameter'=>5});
# </snip>
#
######################
sub URL_Parameters {
######################
    my $dbc  = shift;
    my $set  = shift;
    my $type = shift;

    my %Set;
    if ($set) {
        %Set = %{$set};
    }

    my %P;

    my $session;
    my $user       = $dbc->get_local('user_name');
    my $dbase_mode = $dbc->{'dbase_mode'};
    my $dept       = $dbc->get_local('current_department');

    if ( defined $dbc->{session} && $dbc->{session}{session_id} ) {
        $session = $dbc->{session}{session_id};
    }
    unless ( $type =~ /start/ ) {
        push @{ $P{Name} }, ( 'Session', 'User', 'Database_Mode', 'Target_Department' );
        push @{ $P{Value} }, ( $session, $user, $dbase_mode, $dept );
    }

    $P{'url'} = $dbc->homelink();

    foreach my $opt ( keys %Set ) {
        if ( $opt && $Set{$opt} ) {
            $P{$opt} = $Set{$opt};
        }
    }

    return %P;
}

################
#
# Generate a list of items in a small table
#
# <snip>
# Eg. print HTML_list(\@items);
# (displays table with items listed below)
#
# </snip>
#
# Options:
#  -format (links or rows)
#  -title (title for tableheading)
#
# Return: printable scalar
##############
sub HTML_list {
##############
    my %args = &filter_input( \@_, -args => 'list,title' );
    my $title   = $args{-title} || '';             ## title for table generated
    my $list    = $args{-list};                    ## list of items to display
    my $alt     = $args{-alt} || '(none)';         ## alternative text to display if no items found.
    my $split   = $args{ -split };                 ## split lists on this delimiter
    my $format  = $args{'-format'} || 'records';
    my $headers = $args{-headers};

    my $table = HTML_Table->new( -class => 'small', -title => $title );
    if ($headers) { $table->Set_Headers($headers) }

    my $rows = 0;
    if ( $format =~ /li/ ) {                       ## Put all items in a single row marked with a bullet ##
        my $row = '';
        foreach my $item (@$list) {
            if ($split) { $item =~ s/$split/ = /; }    ## replace split with ' = ' (eg a,b becomes a = b) ##
            $row .= "<LI>$item";
            $rows++;
        }
        $table->Set_Row( [$row] ) if $rows;
    }
    else {                                             ## put each item in a unique row
        foreach my $item (@$list) {
            my @row = ($item);
            if ($split) {
                @row = split /$split/, $item;
            }
            $table->Set_Row( \@row );
            $rows++;
        }
    }
    unless ($rows) { $table->Set_Row( [$alt] ) }

    return $table->Printout(0);
}

#######################
#
# A generic method of combining accumulated data recursively, allowing for generation of HTML_Table rows as required
#
# <snip>
#  Example:
#      my @Tdata = ();  ## use to accumulate data
#      my $bins = pack "S*", @some_other_data;
#      my @Tbins = ();  ## use to accumulate packed data sets
#
#      my $Table = HTML_Table->new();
#
#      my @data_list = ('Q20','Runs','Reads');    ## include this data
#      my @averages  = ('Q20');                   ## include averages for this data
#      my @medians   = ('Q20');                   ## include medians for this data
#
#      ## define what each row of the output table will look like (use << >> tags to enclose data elements)
#      my @row  = (<<TITLE>>, "Q20 = <<Q20>>", "<<AVG_Q20>>","<<MEDIAN_Q20>><BR>(/ <<Reads>>)");
#
#  	&combine_records(-data=>\@data1,-cumulative_data=>\@Tdata,-packed=>[$bins],-cumulative_packed=>\@Tbins,
#                    -action=>'add',
#			 -data_list=>\@data_list,-averages=>\@averages,-medians=>\@medians,-row=>\@row,-bytes=>2);
#
#  	&combine_records(-data=>\@data2,-cumulative_data=>\@Tdata,-packed=>[$bins],-cumulative_packed=>\@Tbins,
#                    -action=>'add',
#			 -data_list=>\@data_list,-averages=>\@averages,-medians=>\@medians,-row=>\@row,-bytes=>2);
#
#     ## use summary switch to summarize... ##
#  	&combine_records(-cumulative_data=>\@Tdata,-packed=>[$bins],-cumulative_packed=>\@Tbins,
#                    -table=>$Table,-action=>'summary',
#			 -data_list=>\@data_list,-averages=>\@averages,-medians=>\@medians,-row=>\@row,-bytes=>2);
#
#     $Table->Printout();
#
##    (see HTML_Table usage for details of $Table options)
#
# (generalized from Project Stats generator)
#
######################
sub combine_records {
######################
    my %args = &filter_input( \@_, -args => 'file,title,data,cumulative_data,packed,cumulative_packed,table,action,details,colour,condition' );

    my $file  = $args{-file};
    my $title = $args{-title};

    my $data_ref          = $args{-data};
    my $cumulative_ref    = $args{-cumulative_data};
    my $packed            = $args{-packed};
    my $cumulative_packed = $args{-cumulative_packed};

    my $action = $args{-action};

    my $Table      = $args{-table};
    my $colour     = $args{-colour};
    my $details    = $args{-details};
    my $regenerate = $args{-regenerate};    ## regenerate histograms (if applicable) even if cached file exists...


    my @data            = @$data_ref       if $data_ref;          ## data which is summed
    my @cumulative_data = @$cumulative_ref if $cumulative_ref;    ## cumulative sums

    my @array            = @$packed            if $packed;
    my @cumulative_array = @$cumulative_packed if $cumulative_packed;

    my @data_list   = @{ $args{-data_list} }   if $args{-data_list};
    my @averages    = @{ $args{-averages} }    if $args{-averages};
    my @percentages = @{ $args{-percentages} } if $args{-percentages};
    my @medians     = @{ $args{-medians} }     if $args{-medians};
    my @row         = @{ $args{-row} }         if $args{-row};
    my $bytes       = $args{-bytes}       || 2;                   ## number of bytes in binary array elements.
    my $total_index = $args{-count_index} || 0;

    my $dbc = $args{-dbc};

    my $remove_zero = get_param('Remove Zero', -dbc=>$dbc);
    
    ### generate cumulative numbers...

    my $dist = 1;                                                 ## use simple distribution for cumulative stats (quite a bit faster)

    my @total;
    if ( $action =~ /add/ ) {
        foreach my $index ( 0 .. $#cumulative_data ) {
            $cumulative_ref->[$index] += $data[$index];           ## add data elements
        }

        ## accumulate packed array ##
        foreach my $index ( 0 .. $#array ) {
            if ($dist) {                                          ## quicker (less memory intensive) method of generating cumulative stats
                my @add         = unpack "S*", $array[$index];                  ## supplied values packed as specified
                my @accumulated = unpack "I*", $cumulative_packed->[$index];    ## pack accumulated packed in 4 byte segments
                my $total       = 0;
                my $total1      = 0;
                foreach my $index ( 0 .. $#accumulated ) { $total  += $accumulated[$index] }
                foreach my $index (@accumulated)         { $total1 += $index }
                foreach my $element (@add) {
                    if ( $element > int(@accumulated) ) {                       ## pad cumulative packed if necessary ##
                        foreach my $zero ( int(@accumulated) .. $element ) {
                            $accumulated[$zero] = 0;
                        }
                    }
                    $accumulated[$element]++;
                }
                $cumulative_packed->[$index] = pack "I*", @accumulated;
                $total                       = 0;
                $total1                      = 0;
                foreach my $index ( 0 .. $#accumulated ) { $total  += $accumulated[$index] }
                foreach my $index (@accumulated)         { $total1 += $index }
            }
            else {    ## longer statistical accumulation (but allows for more flexible statistical options ##
                $cumulative_packed->[$index] .= $array[$index];    ## append array elements
            }
        }
        return;

        #	Just add up the numbers if in 'add' mode.. ;
    }

    my %Index;                                                     ## generate hash referencing data_list elements with indexed position
    foreach my $index ( 0 .. $#data_list ) {
        $Index{ $data_list[$index] } = $index;
    }

    my %array_Index;                                               ## generate hash referencing array_list elements with indexed position
    foreach my $index ( 0 .. $#medians ) {
        $array_Index{ $medians[$index] } = $index;
    }

    my %Display;
    $Display{TITLE} = $title;
    ## initialize Display objects to cumulative data
    foreach my $index ( 0 .. $#data_list ) {
        $Display{ $data_list[$index] } = simplify_number( $cumulative_data[$index] );
    }

    my $total = $cumulative_data[$total_index];                    ## for averages, we need index position of count value
    foreach my $key (@averages) {
        my $avg = 'n/a';
        if ($total) {
            $avg = sprintf "%0.1f", $cumulative_data[ $Index{$key} ] / $total;
        }
        $Display{"AVG_$key"} = "$avg";
    }
    foreach my $key (@percentages) {
        my $avg = 'n/a';
        if ($total) {
            $avg = sprintf "%0.1f", 100 * $cumulative_data[ $Index{$key} ] / $total;
        }
        $Display{"PERCENT_$key"} = "$avg %";
    }

    ## if median(s) requested, unpack arrays and generate statistics ##
    foreach my $field (@medians) {
        my $index        = $array_Index{$field};
        my $packed_array = $cumulative_packed->[$index];
        if ($packed_array) {    #### if details requested include median and Histogram...
            ## Add median value if expected ##
            my $length = length($packed_array) / $bytes;

            #	    Message("Accumulated length = $length");
            my @unpacked_array;
            if ( $bytes == 2 ) {
                @unpacked_array = unpack "I*", $packed_array;
            }
            elsif ( $bytes == 1 ) {
                @unpacked_array = unpack "I*", $packed_array;
            }
            if ($dist) {        ## quicker method of statistical accumulation using simple distribution
                my $total_counts = 0;
                my $total_value  = 0;
                my ( $low_median, $high_median );
                my $median = 0;

                #		my @bin_elements = @{$cumulative_packed->[$index]};
                foreach my $index ( 0 .. $#unpacked_array ) {
                    my $element = $unpacked_array[$index];
                    $total_counts += $element;
                    my $add = $element * $index;
                    $total_value += ( $element * $index );
                }
                my $half_counts = $total_counts / 2;

                my $recounts = 0;    ## reset counter
                foreach my $bin ( 0 .. $#unpacked_array ) {
                    my $element = $unpacked_array[$bin];
                    $recounts += $element;
                    if ( $recounts == $half_counts ) { $low_median = $bin; }
                    elsif ( $recounts > $half_counts ) {
                        if   ($low_median) { $median = ( $bin + $low_median ) / 2; }
                        else               { $median = $bin; }
                        last;
                    }
                }
                my $avg = sprintf "%0.1f", $total_value / $total_counts;
                $Display{"MEDIAN_$field"} = "<B>$median</B><BR>(Avg=$avg)<BR>(N=$total_counts)";

            }
            else {
                my $stat = Statistics::Descriptive::Full->new();
                $stat->add_data(@unpacked_array);
                my $median = $stat->median();
                my $count  = $stat->count();
                my $avg    = $stat->mean();
                $Display{"MEDIAN_$field"} = "<B>$median</B><BR>(AVG=$avg)<BR>(N=$count)";

                #		THIS IS a bit sLOW... (?)
                my %Distribution = $stat->frequency_distribution( $stat->max() - $stat->min() + 1 );
                my @Dist = @{ pad_Distribution( \%Distribution, -binsize => 10 ) };

                $file ||= "HIST";
                my ($img) = &alDente::Data_Images::generate_run_hist(
                    data     => \@Dist,
                    filename => $file
                );
                $Display{FILE} = "(dynamically generated)<BR>$img";
            }
        }
        else {
            $Display{"MEDIAN_$field"} = "(no records)";
        }
    }
    
    my $URL_cache = $dbc->config('URL_cache');
    
    ## define File object if supplied from cache ##
    if ( $file && !$regenerate && -e "$URL_cache/$file" ) {
        $Display{FILE} = "(cached)<BR><IMG SRC='/dynamic/cache/$file'>";
    }
    elsif ( $details && $dist ) {
        my $remove_zero = 1;
        my @unpacked = unpack "I*", $cumulative_packed->[0];
        my @compressed;
        my $next  = 0;
        my $scale = 10;

        $file ||= "HIST" . timestamp();

        foreach my $index ( 0 .. $#unpacked ) {
            $unpacked[$index] ||= 0;
            $compressed[$next] += $unpacked[$index];
            if ( $index >= ( $next * $scale + $scale - 1 ) ) { $next++; }
        }
        my ($img) = &alDente::Data_Images::generate_run_hist(
            data        => \@compressed,
            filename    => $file,
            remove_zero => $remove_zero
        );

        $Display{FILE} = "(dynamically generated)<BR>$img";
    }
    elsif ($details) {
        $Display{FILE} = '(no cached file found)';
    }
    else {
        $Display{FILE} = '(no cached file found)';
    }

    ## based upon the template row provided, replace tags <<Field>> with Value (recursively) ##
    foreach my $cell (@row) {
        while ( $cell =~ /^(.*)<<(.*?)>>(.*)$/ ) {
            if ( defined $Display{$2} ) {
                $cell = $1 . $Display{$2} . $3;
            }
            else {
                my @keys = keys %Display;
                $cell = $1 . '?' . $3;
                Message("Value for '$2' not defined");
                Message("@keys");
            }
        }
    }

    ## If HTML_Table object supplied, add this row to the table ##
    if ($Table) {
        $Table->Set_Row( [@row], $colour );
    }
    return;
}

###########################
sub simplify_number {
###########################
    my $number = shift;
    my $font   = shift;

    my $open_font;
    my $close_font;

    if ($font) {
        $open_font  = "<Font $font>";
        $close_font = "</Font>";
    }

    my $display = $number;

    if ( $number >= 10000 ) {
        $display = "$open_font<B>" . &RGTools::Conversion::number($number) . "</B>$close_font<BR>($number)";
    }
    else {
        $display = "$open_font<B>$number</B>$close_font";
    }
    return $display;
}


###############################################################
#  Create a javascript collapsible link that can selectively hide or expand HTML areas
#
# Dependencies:
#
# SDB.js functions showBranch() and swapFolder()
#
# <snip>
# Example:
#  my @array3 = (6,7,8);
#  my %subhash = (Sub_directory=>\@array3);
#  my @array=(1,2,3);
#  my @array2=(4,5,\%subhash);
#  my %hash = (Directory1=>\@array, Directory2=>\@array2);
#
#
#  my $output = SDB::HTML::create_tree(-tree=>\%hash, -print=>1)
#
# </snip>
#
#
# RETURN: String output of the HTML or 1 (print the output directly)
###############################################################
sub create_collapsible_link {
##################################
    my %args = &filter_input( \@_, -args => 'linkname,html', -mandatory => 'linkname,html' );

    my $html                 = $args{-html};                         # (Scalar) The HTML code that needs to be hidden
    my $linkname             = $args{-linkname};                     # (Scalar) The name of the link
    my $disable_if_collapsed = $args{-disable_if_collapsed} || 0;    # (Scalar) Flag to disable form elements if they are in a closed collapsible link
    my $onClick              = $args{-onClick};                      # (Scalar) additional onClick scripts
    my $style                = $args{-style} || 'open';              # (Scalar) indicate if the link is open or collapsed by default. valid options: 'open', 'collapsed'
    my $output               = '';

    my $randnum = rand();

    # get the 8 least significant digits
    $randnum = substr( $randnum, -8 );

    # assign id
    my $id = "Collapsible$randnum";

    # initialize trigger
    $output .= "<SPAN class='trigger' onClick=\"showBranch('$id'); $onClick\">";

    # display link name
    $output .= "<a href='' onClick='return false;'>$linkname</a>";

    # close trigger
    $output .= "</span>";

    # initialize body of collapsible link
    my $style_spec;
    if ( $style =~ /collapsed/ixms ) {
        $style_spec = "style='display:none'";
    }
    $output .= "<span class='branch' id='$id' $style_spec>";

    # print HTML
    $output .= $html;

    # close collapsible link
    $output .= "</span>";

    ## Disable all the elements by default
    if ($disable_if_collapsed) {
        $output .= "\n<script>ToggleFormElements('$id',2)</script>\n";
    }

    return $output;
}

#####################
sub create_swap_link {
#####################
    my %args = &filter_input( \@_, -args => 'linkname,html', -mandatory => 'linkname,html' );

    my $html     = $args{-html};        # (ArrayRef) (size=2) The HTML code that needs to be hidden. The index[0] HTML would be the visible layer at the start.
    my $linkname = $args{-linkname};    # (Scalar) The name of the link
    my $onClick  = $args{-onClick};     # (Scalar) additional onClick scripts

    my $output = '';

    # assign IDs
    my $visible_id = "Collapsible" . substr( rand(), -8 );
    my $hidden_id  = "Collapsible" . substr( rand(), -8 );

    # initialize trigger
    $output .= "<BR><span class='trigger' onClick=\"showBranch('$hidden_id');showBranch('$visible_id'); $onClick\">";

    # display link name
    $output .= "<a href='' onClick='return false;'>$linkname</a>";

    # close trigger
    $output .= "</span>";

    # initialize body of visible collapsible link
    $output .= "<span class='branch' id='$visible_id'>";

    # print HTML
    $output .= $html->[0];

    # close collapsible link
    $output .= "</span>";

    # initialize body of collapsible link
    $output .= "<span class='branch' id='$hidden_id'>";

    # print HTML
    $output .= $html->[1];

    # close collapsible link
    $output .= "</span>";

    $output .= "\n<script>showBranch('$visible_id');</script>\n";

    return $output;
}

##################
sub layer_list {
##################
    my %args = &filter_input( \@_ );
    $args{-layers} = $args{-data_ref};
    return &define_Layers(%args);

}

###############################
# creates a layered view
# the navigation page is the first page
# and it swaps with the content pages
# <snip>
# my %layer_hash = ('Sequencing'=> $sequencing_page, 'Mapping' => $mapping_page);
# print &define_Layers(-layers=>\%layer_hash);
# </snip>
#
# RETURN: String output
###############################
sub define_Layers {
###############################
    my %args           = &filter_input( \@_, -args => 'data_ref,print,radiogroup_name,add_home' );
    my $data           = $args{-layers};                                                             # (HashRef) Data for the layer view. The keys are the selection names for the navigation page, values are the pages themselves.
    my $print          = $args{ -print };
    my $radiogroup     = $args{-radiogroup_name};                                                    # (Scalar) [Optional] If specified, will add a radio button to each key of the data_ref, with the name specified, and the corresponding key as the value.
    my $add_home       = $args{-add_home};                                                           # (Scalar) [Optional] Additional HTML code for the main nav page
    my $add_html_ref   = $args{-add_html};                                                           # (Hashref) [Optional] Additional HTML code for each key.
    my $wrap_form      = $args{-wrap_form};                                                          # (Scalar) [Optional] wrap each page in a form
    my $tooltips       = $args{-tooltips};                                                           # (Hashref) [Optional] Add a tooltip for each selection name (key of the data_ref hash)
    my $back_indicator = $args{-back_indicator} || " <i>< Back</i> ";
    my $show_layers    = $args{-show_layers} || 1;                                                   ## include original layer options at the top of each layer.
    my $format         = $args{'-format'} || 'tab';                                                  ## Format in which layer options appear (eg 'text','tab', or 'list');
    ## formatting options for tabs.. ###
    my $tab_offset  = $args{-tab_offset}  || 0;                                                      ### distance to offset beginning of tabs from the left
    my $tab_colour  = $args{-tab_colour}  || $tab_clr;                                               ### colour of selected tabs
    my $tab_width   = $args{-tab_width}   || 100;                                                    ### width of tabs (defaults to evenly distribution across full width)
    my $tab_padding = $args{-tab_padding} || 5;
    my $tab_links  = $args{-tab_links};                                                              ### optional links provided in place of layer.
    my $gap_width  = $args{-gap_width} || 1;                                                         ### width of gap between tabs
    my $gap_colour = $args{-gap_colour} || 'white';                                                  ### colour of gaps between tabs (background colour)
    my $off_colour = $args{-off_colour} || $off_clr;                                                 ### colour of tabs which are NOT selected
    my $sub_tab    = $args{-sub_tab};                                                                ### optional bar below tabs...
    my $tab_class  = $args{-tab_class} || 'tablabel';
    my $off_class  = $args{-off_class} || 'tablabel';

    my $width  = $args{-width}  || '100%';                                                           ### width of entire layer
    my $height = $args{-height} || '100%';                                                           ### width of entire layer
    my $align  = $args{-align}  || 'center';                                                         ### alignment of contents of layer in section
    my $bordercolour = $args{-border_colour};                                                        ### colour of border (Default = $tab_colour)
    my $padding      = $args{-padding} || 20;                                                        ### padding around contents of layer
    my $spacing      = $args{-spacing} || 0;
    my $event        = $args{-event} || 'onClick';                                                   ### the event that triggers the layer...(onClick or onMouseOver)
    my $order        = $args{-order};                                                                ### order of layers.
    my $onClick      = $args{-onClick} || $args{-onclick};                                           ### hash of events triggered by layer.
    my $open         = $args{ -open } || $args{-active} || $args{-default};                          ### layer which starts out open (eq key for layer)
    my $name         = $args{-name} || 'key';
    my $text_colour  = $args{-text_colour};                                                          ### text colour for tabs (in case of dark colouring... ###
    my $show_count   = $args{-show_count};                                                           ## include count of records found in each tab
    my $id           = $args{-id};
    my $visibility   = $args{-visibility};

    my $layer_type   = $args{-layer_type};                                                           ## eg tabs (default) or accordion ...
    my $parent_layer = $args{-parent_layer};

    if ($onClick) { return define_non_BS_Layers(%args) }

    my @BS_layers;
    if ( ref $args{-layers} eq 'HASH' ) {
        @BS_layers = convert_layers_hash_to_array( %args, -old_format => 1 );
    }
    elsif ( ref $args{-layers} eq 'ARRAY' ) {
        @BS_layers = @{ $args{-layers} };
    }

    return $BS->layer( -layers => \@BS_layers, -active => $open, -id => $id, -layer_type => $layer_type, -visibility => $visibility );    ### use BS wrapper...
}

###################################
sub convert_layers_hash_to_array {
###################################
    my %args       = &filter_input( \@_, -args => 'layers,order' );
    my $data       = $args{-layers};
    my $order      = $args{-order};
    my $visibility = $args{-visibility};
    my $open       = $args{ -open } || $args{-default};                                                                                   ### layer which starts out open (eq key for layer)
    my $old_format = $args{-old_format};

    my @keys;
    if ($order) { @keys = Cast_List( -list => $order, -to => 'array' ); }                                                                 ## specify order in which list is to appear.
    unless (@keys) { @keys = sort keys %{$data} }

    my @tabs;
    my @layers;

    foreach my $key (@keys) {
        if ( $data->{$key} ) {
            push @tabs, $key;

            my $v;
            if ($visibility) { $v = $visibility->{$key} }

            my $open_layer = ( $open =~ /\bkey\b/i );

            my $hash = {
                'label'      => $key,
                'content'    => $data->{$key},
                'visibility' => $v,
                'open'       => $open_layer,
            };

            if ($old_format) { $hash = { $key => $data->{$key} } }    ## replace with block above... # phase out

            push @layers, $hash;
        }
    }

    return @layers;
}

###############################
# creates a layered view
# the navigation page is the first page
# and it swaps with the content pages
# <snip>
# my %layer_hash = ('Sequencing'=> $sequencing_page, 'Mapping' => $mapping_page);
# print &define_Layers(-layers=>\%layer_hash);
# </snip>
#
# RETURN: String output
###############################
sub define_non_BS_Layers {
###############################
    my %args           = &filter_input( \@_, -args => 'data_ref,print,radiogroup_name,add_home' );
    my $data           = $args{-layers};                                                             # (HashRef) Data for the layer view. The keys are the selection names for the navigation page, values are the pages themselves.
    my $print          = $args{ -print };
    my $radiogroup     = $args{-radiogroup_name};                                                    # (Scalar) [Optional] If specified, will add a radio button to each key of the data_ref, with the name specified, and the corresponding key as the value.
    my $add_home       = $args{-add_home};                                                           # (Scalar) [Optional] Additional HTML code for the main nav page
    my $add_html_ref   = $args{-add_html};                                                           # (Hashref) [Optional] Additional HTML code for each key.
    my $wrap_form      = $args{-wrap_form};                                                          # (Scalar) [Optional] wrap each page in a form
    my $tooltips       = $args{-tooltips};                                                           # (Hashref) [Optional] Add a tooltip for each selection name (key of the data_ref hash)
    my $back_indicator = $args{-back_indicator} || " <i>< Back</i> ";
    my $show_layers    = $args{-show_layers} || 1;                                                   ## include original layer options at the top of each layer.
    my $format         = $args{'-format'} || 'tab';                                                  ## Format in which layer options appear (eg 'text','tab', or 'list');
    ## formatting options for tabs.. ###
    my $tab_offset  = $args{-tab_offset}  || 0;                                                      ### distance to offset beginning of tabs from the left
    my $tab_colour  = $args{-tab_colour}  || $tab_clr;                                               ### colour of selected tabs
    my $tab_width   = $args{-tab_width}   || 100;                                                    ### width of tabs (defaults to evenly distribution across full width)
    my $tab_padding = $args{-tab_padding} || 5;
    my $tab_links  = $args{-tab_links};                                                              ### optional links provided in place of layer.
    my $gap_width  = $args{-gap_width} || 1;                                                         ### width of gap between tabs
    my $gap_colour = $args{-gap_colour} || 'white';                                                  ### colour of gaps between tabs (background colour)
    my $off_colour = $args{-off_colour} || $off_clr;                                                 ### colour of tabs which are NOT selected
    my $sub_tab    = $args{-sub_tab};                                                                ### optional bar below tabs...
    my $tab_class  = $args{-tab_class} || 'tablabel';
    my $off_class  = $args{-off_class} || 'tablabel';

    my $width  = $args{-width}  || '100%';                                                           ### width of entire layer
    my $height = $args{-height} || '100%';                                                           ### width of entire layer
    my $align  = $args{-align}  || 'center';                                                         ### alignment of contents of layer in section
    my $bordercolour = $args{-border_colour};                                                        ### colour of border (Default = $tab_colour)
    my $padding      = $args{-padding} || 20;                                                        ### padding around contents of layer
    my $spacing      = $args{-spacing} || 0;
    my $event        = $args{-event} || 'onClick';                                                   ### the event that triggers the layer...(onClick or onMouseOver)
    my $order        = $args{-order};                                                                ### order of layers.
    my $onClick      = $args{-onClick} || $args{-onclick};                                           ### hash of events triggered by layer.
    my $open         = $args{ -open } || $args{-default};                                            ### layer which starts out open (eq key for layer)
    my $name         = $args{-name} || 'key';
    my $text_colour  = $args{-text_colour};                                                          ### text colour for tabs (in case of dark colouring... ###
    my $show_count   = $args{-show_count};                                                           ## include count of records found in each tab

    my $parent_layer = $args{-parent_layer};

    my @keys;
    if ($order) { @keys = Cast_List( -list => $order, -to => 'array' ); }                            ## specify order in which list is to appear.
    unless (@keys) { @keys = sort keys %{$data} }

    my @tabs;
    my @BS_layers;
    foreach my $key (@keys) {
        if ( $data->{$key} ) {
            push @tabs, $key;
            push @BS_layers, { $key => $data->{$key} };
        }
    }

    $open ||= $tabs[0];

    $align = "align='$align'" if $align;

    $gap_colour = "bgcolor='$gap_colour'" if $gap_colour;
    my $tab_colr = $tab_colour;
    my $off_colr = $off_colour;
    if ($tab_colour) {
        $bordercolour ||= "bordercolor='$tab_colour'";
        $tab_colour = "bgcolor='$tab_colour'";
    }
    if ($tab_class) {
        $tab_class = "class='$tab_class'";
    }
    if ($off_class) {
        $off_class = "class='$off_class'";
    }

    $off_colour = "bgcolor='$off_colour'" if $off_colour;
    my $box_spec = "border=0 $bordercolour $tab_colour width='100%' align='left' cellpadding=$padding";    ## specifications for table containing layer...

    # get the eight least significant figures of a random number
    my $home_randnum = substr( rand(), -8 );

    ## draw the navigation page

    my $primary_layer .= "\n<div id='home$name${home_randnum}'>\n";

    my $header_table = "\n<Table  $gap_colour border=0 cellspacing=0 cellpadding=$tab_padding class='small' $align>\n\t<tr>\n";

    $tab_width  = " width='$tab_width'"  if ($tab_width);
    $gap_width  = " width='$gap_width'"  if ($gap_width);
    $tab_offset = " width='$tab_offset'" if $tab_offset;

    if ( $format =~ /list/ ) {

    }
    elsif ( $format =~ /tab/ ) {
        $header_table .= "\t\t<td valign=top $tab_offset $gap_colour>\n\t\t</td>\n" if $tab_offset;
        my $tab_count = int(@tabs);
        $tab_width = ( $width + $gap_width ) / $tab_count - $gap_width unless ( $tab_width || !$tab_count );
    }
    my $output_table = "\n";

    #    foreach my $tab (@tabs) {
    #	$output_table .= "<A name=#$tab />\n";
    #    }

    $output_table .= "\n<table width=$width $gap_colour border=0 cellspacing=0 cellpadding=0 class='small' $align>\n\t<tr>\n\t\t<td valign=top $align>\n";

    my %randnum_hash;

    my $activate_parent;
    my $parent_name;    ## need to pass this in as well ?..
    if ($parent_layer) { $activate_parent = "activateBranch('layer$parent_layer','$parent_name','$tab_colr','$off_colr');" }

    #    unless ($format =~ /tab/) { $header_table .= "<td>" }

    foreach my $key (@tabs) {
        my $layer_randnum = substr( rand(), -8 );
        $randnum_hash{$key} = $layer_randnum;
        my $onclick = $onClick->{$key} if $onClick && defined $onClick->{$key};

        my $link_to_layer;
        if ( $format =~ /radio/i ) {
            $link_to_layer = radio_group( -name => 'Project', -onClick => "\"activateBranch('layer$name$randnum_hash{$key}','$name','$tab_colr','$off_colr'); $onclick\"", value => $key ) . "\n</div>\n";

            #<a href='#'class='dlink' $event=\"activateBranch('layer$randnum_hash{$key}','$tab_colr','$off_colr');$onclick\">$key</a>";
        }
        elsif ( defined $tab_links->{$key} ) {
            $link_to_layer = $tab_links->{$key};
        }
        else {
            my $text = $key;
            if ($text_colour) { $text = "<Font color='$text_colour'>$key</Font>"; }

            $link_to_layer = "\n<a href='#$key' class='dlink' style='text-decoration:none;' $event=\"$activate_parent activateBranch('layer$name$randnum_hash{$key}','$name','$tab_colr','$off_colr'); $onclick\">$text</a>\n";
        }

        if ($text_colour) { $link_to_layer = "$link_to_layer"; }    ## text colour if defined..

        my $colour = $off_colour;
        my $class = $off_class || $tab_class;
        if ( ( $open eq $key ) && !defined $tab_links->{$key} ) { $colour = $tab_colour if $tab_colour; $class = $tab_class if $tab_class; }

        if ( $format =~ /tab/i ) {
            $header_table .= "\t\t<td valign=top id = '$name$randnum_hash{$key}' $colour $class $tab_width>$link_to_layer</td>\n";
            $header_table .= "\t\t<td valign=top $gap_colour> </td>\n" if $gap_width;
        }
        elsif ( $format =~ /list/i ) {
            $header_table .= "\t\t<td $colour id = '$name$randnum_hash{$key}'>$link_to_layer</td>\n\t</tr>\n\t<tr>";
        }
        elsif ( $format =~ /radio/i ) {
            $header_table .= "\t\t<td id = '$name$randnum_hash{$key}'>$link_to_layer</td>\n\t</tr>\n\t<tr>\n";
        }
    }
    $header_table .= "\t</tr>\n</Table>\n";

    if ( $format =~ /tab/i ) {
        $output_table .= "$header_table</td></tr>\n";
        $output_table .= "<TR><TD><TABLE BORDER=1 WIDTH=100%>\n";
        if ( defined $sub_tab ) {
            $output_table .= "\t<tr>\n\t\t<td valign=top $tab_colour $tab_class colspan 20>$sub_tab</td>\n\t</tr>\n";
        }
        $output_table .= "\t<tr>\n\t\t<td $tab_class valign=top align=left cellspacing=0 cellpadding=0>\n";
    }
    else {
        $output_table .= "$header_table</td>\n\t<td valign=top width='100%'>\n";
    }

    foreach my $key (@tabs) {
        my $layer_table;
        my $layer_contents;
        if ( defined $tab_links->{$key} ) {next}    ## skip links explicitly supplied
        my $contents = $data->{$key};
        if ( $add_html_ref && defined $add_html_ref->{$key} ) {
            $contents .= $add_html_ref->{$key};
        }

        my $html_str = html_box(
             $contents,
            -spec        => $box_spec,
            -cell_colour => $gap_colour,
            -height      => $height
        );
        if ( $open =~ /^\Q$key\E$/ ) {
            $layer_contents = "\n<div class='branch' id='layer$name$randnum_hash{$key}' style='display:block'>$html_str</div>\n";
        }
        else {
            $layer_contents = "\n<div class='branch' id='layer$name$randnum_hash{$key}' style='display:none'>$html_str</div>\n";
        }
        $layer_table  .= $layer_contents;
        $output_table .= $layer_table;
    }
    $output_table .= "</TD></TR></TABLE>\n";
    $output_table .= "\t\t</td>\n\t</tr>\n</table>\n";

    return $output_table;
}

#
# Simple Wrapper for jquery accordion elements
#
# Usage:
#
#  * print accordion(-layers=>{'L1' => 'layer 1 content', 'L2' => 'layer 2 content'}, -order=>['L2','L1']);
# (ordering in this case would default to ordered keys in hash, but can be overridden as indicated)
#
#  ... or...
#
#   ... should also add functionality for this type of input (inherently ordered) ....
#
#  * print accordion(-layers=>[
#        {'title' => 'layer 1', 'content' => 'layer 1 content' },
#        {'title' => 'L2', 'content' => 'layer 2 content' }
#        ]);
#
# Return: applicable html block
################
sub accordion {
################
    my %args = &filter_input( \@_, -args => 'layers' );
    my $data = $args{-layers};    # (HashRef) Data for the layer view. The keys are the selection names for the navigation page, values are the pages themselves.

    my $randnum = rand();

    # get the 8 least significant digits
    $randnum = substr( $randnum, -8 );

    my $id = "accordion" . $randnum;

    my $jq     = 'jQuery';
    my $output = <<JS;
    
<script type=\"text/javascript\">   
    $jq(function(){
        // Accordion
        $jq(\"#$id\").accordion({ header: \"h3\" })
        })
</script>
JS

    my %Blocks;
    if ($data) { %Blocks = %$data }

    $output .= "\n\n<div id=\"$id\">\n";

    foreach my $block ( keys %Blocks ) {
        $output .= <<DIV;
    <div>
        <h3><a href="#">$block</a></h3>
        <div>$Blocks{$block}</div>
    </div> 
DIV
    }
    $output .= "\n</div>\n";

    return $output;
}

#
# Wrapper for jquery sortable list
#
# Usage:
#
#  * print sortable_list(-list => , -form_fields => 1 );
#
# Arguments:
#
#  * -form_input: Add hidden input form elements to each list item
#
# Return: applicable html block
################
sub sortable_list {
################
    my %args       = &filter_input( \@_, -args => 'list, form_input' );
    my $list       = $args{-list};
    my $form_input = $args{-form_input};

    my $randnum = rand();

    # get the 8 least significant digits
    $randnum = substr( $randnum, -8 );

    my $id = "sortable" . $randnum;

    my $jq     = 'jQuery';
    my $output = <<JS;
    
<script type=\"text/javascript\">   
    $jq(function(){
        // Sortable list
        $jq(\"#$id\").sortable({ items: 'li' });
	$jq(\"#$id\" ).disableSelection();
        })
</script>
JS

    $output .= "\n\n<ul id=\"$id\">\n";

    my $i = 0;

    foreach my $item (@$list) {
        $output .= "<li>$item";
        $output .= "<input type=\"hidden\" name=\"${id}_$i\" value=\"$item\">" if ($form_input);
        $output .= "</li>\n";
        $i++;
    }
    $output .= "\n</ul>\n";

    return $output;
}

################
# Set HTML element as specified.
#
# <snip>
#  eg.  set_ID($id,'disabled=1');
# </snip>
#
################
sub set_ID {
################
    my $id = shift;
    my %args = &filter_input( \@_, -args => 'action' );

    my $action = $args{-action};

    my $string = "document.getElementById('$id')";
    if ($action) {
        $string .= ".$action; ";
    }

    return $string;
}

##################
sub help_icon {
##################
    my %args = &filter_input( \@_, -args => 'tip' );

    my $tip = $args{-tip};
    my $icon = $args{-icon} || 'question-circle';
    
    return Show_Tool_Tip( $BS->button(-icon=>$icon), $tip);

}

###########################
sub wildcard_search_tip {
###########################
    my $tip
        = "*use wildcard (eg '123*)\n* indicate numerical range for integers (eg '< 25' or '55-62')\n* supply list of options separated by '|' (eg '1|2|3')\n* supply range in square brackets (eg '12[1-3]' to get 121, 122, or 123)\n\nIf textarea is supplied for search box, user may also paste list of options on separate lines\n\nFormat: Object prefix NOT supported! (For example, to search Plate ID 872330, enter '872330', NOT 'pla872330')\n";
    return $tip;
}

#######################################################
#
# Draws a simple box around the contents specified...
#
###############
sub html_box {
###############
    my %args        = &filter_input( \@_, -args => 'contents,spec' );
    my $contents    = $args{-contents};
    my $spec        = $args{-spec};
    my $cell_colour = $args{-cell_colour};
    my $valign      = $args{-valign} || 'top';
    my $height      = $args{-height};

    if ($valign) { $valign = "valign=$valign"; }

    if ( $cell_colour && ( $cell_colour !~ /bgcolor=/ ) ) { $cell_colour = "bgcolor=$cell_colour"; }
    if ($height) { $height = "height=$height" }

    my $box = "\n<Table $spec $height>\n";
    $box .= "\t<TR>\n\t\t<TD $valign $cell_colour>\n";
    $box .= $contents;
    $box .= "\n\t\t</TD>\n\t</TR>\n</Table>\n";

    return $box;
}

#####################
sub standard_label {
#####################
    my %args = &filter_input( \@_, -args => 'data,title', -mandatory => 'data' );

    my $data_ref = $args{-data};
    my $title    = $args{-title};

    my @rows = &Cast_List( -list => $data_ref, -to => 'array' );

    my $table = HTML_Table->new();
    $table->Set_Class('small');
    $table->Set_Width('400');
    $table->Toggle_Colour('off');

    foreach my $row (@rows) {
        if ( ref $row eq 'ARRAY' ) {
            $table->Set_Row($row);
        }
        else {
            $table->Set_Row( [$row] );
        }
    }
    my $output = '';

    $output .= $table->Printout(0);
    return $output;
}

#########################################
# HTML Table containing scrolling lists for an available list and a picked list.  The user can pick from the available list and submit options
# <snip>
# Example:
#     my $output_table = SDB::HTML::option_selector(-form=>$self->{form}, -avail_list=>\@available_fields,-avail_labels=>\%output_label,-title=>"Pick Output Fields",-avail_header=>'Available Fields',-picked_header=>'Picked Fields');
# </snip>
#
#######################
sub option_selector {
#######################
    my %args          = filter_input( \@_, -args => 'avail_list,avail_labels,picked_list', -mandatory => 'avail_list' );
    my $avail_list    = $args{-avail_list};                                                                                ## Array list of avail options
    my $avail_labels  = $args{-avail_labels};                                                                              ## Hash Labels for the avail option
    my $picked_list   = $args{-picked_list};                                                                               ## Array Picked list of options
    my $picked_labels = $args{-picked_labels};
    my $title         = $args{-title};
    my $avail_header  = $args{-avail_header};
    my $picked_header = $args{-picked_header};
    my $size          = $args{-size} || 30;
    my $sort          = $args{ -sort } || 0;
    my $rm            = $args{-rm};

    $avail_list = set_difference( $avail_list, $picked_list );
    my @available_list = Cast_List( -list => $avail_list,  -to => 'Array' ) if $avail_list;
    my @picked_list    = Cast_List( -list => $picked_list, -to => 'Array' ) if $picked_list;

    if ($sort) { @available_list = sort @available_list }

    my %avail_label;
    %avail_label = %{$avail_labels} if $avail_labels;
    my %default_label;
    %default_label = %{$picked_labels} if $picked_labels;

    my $output_table = HTML_Table->new( -title => "$title" );
    $output_table->Toggle_Colour('off');
    my @headers = ( '', $avail_header, '', $picked_header );
    $output_table->Set_Headers( \@headers );

    my $add_remove_button = $BS->button(-icon=>'chevron-right', -onclick => "swap_option_values('Available_Options','Picked_Options'); return false;")
        . $BS->button(-icon=>'chevron-left', -onclick => "swap_option_values('Picked_Options','Available_Options'); return false;");
    my $picked_up   =$BS->button(-icon=>'chevron-up', -onclick => "move_selected_options('Picked_Options',''); return false;" );
    my $picked_down = $BS->button(-icon=>'chevron-down', -onclick =>  "move_selected_options('Picked_Options','down'); return false;");
    my $avail_up    = $BS->button(-icon=>'chevron-up', -onclick =>  "move_selected_options('Available_Options',''); return false;" );
    my $avail_down  = $BS->button(-icon=>'chevron-down', -onclick =>  "move_selected_options('Available_Options','down'); return false;");

    my $available_list = &dynamic_scrolling_list( -name => "Available_Options", -id => 'Available_Options', -values => [@available_list], -labels => \%avail_label, -multiple => 2, -force => 1, -size => $size );

    $picked_list = &dynamic_scrolling_list( -name => "Picked_Options", -id => 'Picked_Options', -values => [@picked_list], -labels => \%default_label, -multiple => 2, -force => 1, -size => $size );

    $output_table->Set_Row( [ $avail_up . lbr . lbr . $avail_down, $available_list, $add_remove_button, $picked_list, $picked_up . lbr . lbr . $picked_down ] );
    my $avail_select_all  = $q->button( -name => 'Select_All_Avail', -value => 'Select All', -onClick => "select_all_options('Available_Options')" );
    my $picked_select_all = $q->button( -name => 'Select_All_Picked', -value => 'Select All', -onClick => "select_all_options('Picked_Options')" );

    $output_table->Set_Row( [ '', $avail_select_all, '', $picked_select_all ] );

    if ($rm) {
        $output_table->Set_Row( [] );
        $output_table->Set_Row( [ '', submit( -name => 'rm', -value => $rm, -force => 1, -onClick => "select_all_options('Picked_Options')", -class => 'Action' ) ] );
    }

    return $output_table;
}

################################
sub dynamic_scrolling_list {
################################
    my %args       = &filter_input( \@_ );
    my $name       = $args{-name};
    my $id         = $args{-id};
    my @list       = @{ $args{ -values } } if $args{ -values };
    my @defaults   = @{ $args{-defaults} } if $args{-defaults};
    my %labels     = %{ $args{-labels} } if $args{-labels};
    my $multiple   = $args{-multiple} || 2;
    my $size       = $args{-size};
    my $max_size   = $args{-max_size};
    my $onClick    = $args{-onClick};
    my $structname = $args{-structname};

    my $list_length = int(@list) + int(@list);
    if ( $list_length < $max_size ) { $size = $list_length }    ## make scrolling list same length as list length up to max size.
    elsif ($max_size) { $size = $max_size }
    return $q->scrolling_list(
        -name       => $name,
        -id         => $id,
        -values     => \@list,
        -labels     => \%labels,
        -defaults   => [@defaults],
        -multiple   => $multiple,
        -force      => 1,
        -size       => $size,
        -onClick    => $onClick,
        -structname => $structname
    );
}

############################################################################
#
# display_hash: Generates HTML table output given a hash
#
# Simplest Example:
#
#  print $dbc->display_hash(
#			   -hash=> {
#			       'Col1' => ['hello','world'],
#			       'col2' => ['another','column'],
#			       },
#			   );
#
# Available options:
#
# -title => 'Table title'
# -average_columns => 'Col1'
# -total_columns   => 'col2'
# -labels          => {'col2' => 'Actual text at top of col2'}
# -fields          => {'col2' => 'FK_Employee__ID'}              ## specify field upon which value is based (enables DBField based links & tooltips)
#
#
#  my %highlight_column;
#  $highlight_column{Run_Status}{Analyzed}{colour}='Green';
# -highlight_column => \%highlight_column,  ## specify a colour for a column based on the value
#
#
# Example using Table_retrieve first ....(from SDB::DBIO)
#
#  my %hash = $dbc->Table_retrieve(
#				     -table=>'Plate,Employee',
#				     -fields=>['FK_Library__Name','FK_Library__Name as Lib','Plate_Created as Made','Plate_Number as Num','Count(*) as Count'],
#				     -condition => "WHERE FK_Employee__ID=Employee_ID AND Plate_Created > ADDDATE(now(), INTERVAL -5 hour)",
#                                         -group_by=>'FK_Library__Name,Plate_Number',
#				     -limit => 10
#				     );
#   print $dbc->display_hash(
#                              -dbc=>$dbc,
#			   -hash=> \%hash,
#			   -layer=>'Lib'
#		            -average_columns=>'Count',
#			   -total_columns=>'Count',
#			    );
#
#
#######################
sub display_hash {
#######################
    my %args = &filter_input( \@_, -args => 'dbc,hash,title,return_html', -mandatory => 'hash' );
    my $dbc   = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    ## database connection (required to auto-generate links and summary information from the database
    my $title = $args{-title};
    my %Hash  = %{ $args{-hash} };                                                                ## mandatory hash to display
    my @keys;

    @keys = @{ $args{ -keys } } if $args{ -keys };                                                ## list of keys (defaults to keys in hash)
    my %fields;
    %fields = %{ $args{-fields} } if $args{-fields};                                              ## optional specification of specific fields (used to enable DBField auto-link & reference options)
    my %field_info;
    %field_info = %{ $args{-field_info} } if $args{-field_info};                                  ## optional specification of field descriptions (DBField)(used to enable field header tool tips)
    my %labels;
    %labels = %{ $args{-labels} } if $args{-labels};                                              ## optional label for keys (defaults to keys)

    my $class_key        = $args{-class};                                                              ## advanced - enables conversion of Object_ID records in case of FK_Object_Class__ID specification
    my $alt_message      = defined $args{-alt_message} ? $args{-alt_message} : "No records found;";    # alternative message if no data retrieved.
    my $width            = $args{-width};
    my $return_html      = $args{-return_html};
    my $return_table     = $args{-return_table};
    my $return_data      = $args{-return_data};                                                        ## returns array of (output, \%data);
    my $return_graph     = $args{-return_graph};                                                       ## returns array of (output, \%data);
    my $toggle_on_column = $args{-toggle_on_column};                                                   ## toggle line colour on this column name (use key name)
    my $link             = $args{-homelink} || $dbc->{homelink};                                       ## link used in auto-generated link reference
                                                                                                       #    my $order_by = $args{-order_by} || $args{-order}
    my $style            = $args{-style};                                                              ## more powerful css style specification options
                                                                                                       #    my $group_by = $args{-group_by} || $args{-group};
    my $print_link       = $args{-print_link} || 0;                                                    ## (provide link to printable page - not valid with layers)
                                                                                                       # $print_link =~ s/\s/\%20/g;

    my $excel_link        = $args{-excel_link} || 0;                                                   ## (provide link to excel page - not valid with layers)
    my $excel_name        = $args{-excel_name};
    my $return_excel_link = $args{-return_excel_link};
    my $xls_settings      = $args{-xls_settings};
    my $csv_link          = $args{-csv_link} || 0;
    my $graph             = $args{-graph} || 0;                                                        ## flag to display result as a graph

    my $print_path   = $args{-print_path}   || $dbc->config('tmp_dir') || '/tmp';
    my $fixed_header = $args{-fixed_header} || 0;

    my $cell_style                 = $args{-cell_style} || "border-right: 1px solid white; padding:5px;";    # indicate style for table cells if applicable.
    my $highlight                  = $args{-highlight};                                                      # specify rows to be highlighted (colour) based on column value
    my $colour                     = $args{-colour} || '';                                                   # colour for lines in table
    my $total_columns              = $args{-total_columns};                                                  # scalar indicating list of columns to total at bottom.
    my $average_columns            = $args{-average_columns};                                                # average the values for this list of columns (use key names)
    my $max_columns                = $args{-max_columns};                                                    # average the values for this list of columns (use key names)
    my $count_records              = $args{-count_records} || 1;                                             # show count of records
    my $sortable                   = $args{-sortable} || 'no';                                               ## Have the links on top of each column to sort the table based on that column
    my $selectable_field           = $args{-selectable_field};                                               ## Display a check box at the begining of each row and the value of
    my $selectable_field_parameter = $args{-selectable_field_parameter} || 'Mark';                         ## default name for selectable field parameters
    my $link_parameters            = $args{-link_parameters};                                                ##  optional hash (key = data keys; value = link string (replace <VALUE> with actual value recovered from data)
    my $static_labels              = $args{-static_labels};                                                  ## optional hash (key = data keys; value = static value to display (same for all records) - note link_parameters still may vary)
    my $append                     = $args{-append};                                                         ## allow appending of more text (useful if to be included in printable page)
    my $prepend                    = $args{-prepend};                                                        ## prepend table with this string (not valid with layers)
    my $Display                    = $args{-Table};                                                          ## Table may be predefined and appended to if HTML_Table object passed in
    my $add_columns                = $args{-add_columns};
    my $summary                    = $args{-summary};                                                        ## advanced - enables customized text sub-header including SQL query from database.  ('key' => '<sql query text>')
    my $by                         = $args{-by} || 'row';                                                    ## display by row or by column
    my $no_links                   = $args{-no_links};                                                       ## suppress internal links to other pages
    my $debug                      = $args{-debug};                                                          ## verbose mode for debugging
    my $border                     = $args{-border};
    my $toggle                     = $args{-toggle};
    my $highlight_string           = $args{-highlight_string};
    my $highlight_colour           = $args{-highlight_colour} || 'lightred';
    my $highlight_cell             = $args{-highlight_cell};
    my $layer_by                   = $args{-layer};                                                          ## generate tabbed layer output on this key (must be a key in the hash)
    my $layer_format               = $args{-layer_format};                                                   ## eg tab or list
    my $show_count                 = $args{-show_count};                                                     ## show count of records in each tab (only applicable when using layers)
    my $form                       = $args{-form};
    my $max_field_length           = $args{-max_field_length};                                               ## hash of max_lengths for specific columns (eg -max_field_length => {'Description' => 50, 'Name' => 10} )
    my $tips                       = $args{-tips};
    my $subtitles                  = $args{-sub_titles};                                                     ## optional sub title specification.  Format:  $subtitle{1}{Title}='First subtitle'; $subtitle{1}{colspan} = 5 ... etc
    my $timestamp                  = $args{-timestamp};                                                      ## specify timestamp suffix to be used for generated files
    my $list_in_folders            = Cast_List( -list => $args{-list_in_folders}, -to => 'arrayref' );       ## generate folder to tidy display of lists (input parameter should be an array of columns -list_in_folders=>['Libraries'] )
    my $collapse_length            = $args{-collapse_length} || 5;                                           ## length of list (in folders) at which the list collapses to a folder ... 
    my $max_length                 = $args{-max_length} || 50;                                               ## length of string - after which results appear with an expansion link
    my $google_chart               = $args{-google_chart};
    my $no_footer                  = $args{-no_footer};                                                      ## suppress totals footer row
    my $collapse_limit             = $args{-collapse_limit};                                                 ## if rows > collapse_limit, use expand icon to open table...only applicable for NON-layered tables
    my $space_words                = $args{-space_words};                                                    ## separate words with spaces (if they are currently separated with underscores)
    my $resize_onload              = $args{-resize_onload};
    my $no_footer = $args{-no_footer};   ## suppress footer indicating record count retrieved ##
    my $table_class = $args{-table_class};   ## use dataTable class 

    my $html_header   = $args{-html_header} || $dbc->config('html_header');
    my $js_header   = $args{-js_header} || $dbc->config('js_header');
    
    $total_columns = Cast_List(-list=>$total_columns, -to=>'string');
    
    my $footer = $args{-footer};                                                                             # optional footer to include at bottom of table #
    my $resize = $args{-resize} || $resize_onload;
    my $id;
    if ($resize) {
        $fixed_header = 0;
    }

    my $reduced_font        = "size='-3'";
    my $list_separator      = "<br />\n";
    my $list_prefix         = "*";
    my $blank_display_value = '-';

    if ( $layer_by =~ /No Layers/i ) { $layer_by = '' }

    $timestamp ||= timestamp();
    my $random = int( rand 1000 ) + 1;    # $random is now an integer between 1 and 100
    $timestamp .= $random;                # append a random number to the end of the timestamp to avoid file overwriting with same name

    my $gif_link;
    if ($graph) {
        $return_html  = 0;                ## if return_html , then just include graph as a link....
        $return_graph = 1;
        $gif_link     = 1;
    }

    my %Tip;
    if ($tips) { %Tip = %$tips }

    my $group   = $args{-group};
    my $regroup = $args{-regroup};        # how to regroup

    my $highlight_column = $args{-highlight_column};
    my %highlight_column;
    %highlight_column = %{$highlight_column} if ($highlight_column);

    unless (@keys) { @keys = sort keys %Hash }

    ## store link parameters in local hash for accessibility ##
    my %Links;
    if ($link_parameters) {
        ## may be in scalar, hash, or array format ##
        if ( ref($link_parameters) =~ /HASH/i ) {
            %Links = %$link_parameters;
        }
        else {
            my @link_params;
            if ( ref $link_parameters eq 'ARRAY' ) {
                @link_params = @$link_parameters;
            }
            else {
                @link_params = ($link_parameters);
            }
            foreach my $p (@link_params) {
                if ( $p =~ /(.*)=>(.*)/ ) {
                    $Links{$1} = $2;
                }
                else {
                    ## is this ever applicable... leaveing in for now, but only set once ##
                    my $link = eval "$p";
                    %Links = %$link;
                }
            }
        }
    }

    ## establish headers
    my @fields;
    if (%fields) {
        foreach my $key (@keys) {
            if ( $fields{$key} ) {
                push @fields, $fields{$key};
            }
            else {
                push @fields, $key;
            }
        }
    }
    else {
        @fields = @keys;
    }

    ## convert toggle_on_column from column name to column index if necessary.. ##
    if ( $toggle_on_column =~ /[a-zA-Z]/ ) {
        foreach my $index ( 1 .. int(@keys) ) {
            if ( $keys[ $index - 1 ] =~ /\b$toggle_on_column\b/ ) {
                $toggle_on_column = $index;
                last;
            }
        }
    }

    my @display_headers;
    ## establish labels ##
    if (%labels) {
        foreach my $key (@keys) {
            if ( $labels{$key} ) {
                push @display_headers, $labels{$key} unless ( $key eq $layer_by );
            }
            else {
                push @display_headers, $key unless ( $key eq $layer_by );
            }
        }
    }
    else {
        foreach my $key (@keys) {
            push @display_headers, $key unless ( $key eq $layer_by );    ##  = @keys;
        }
    }

    if ( $group && $regroup ) {
        @display_headers = ( '', @display_headers );
    }

    ######### extract list of fields (in order as opposed to with keys %Hash) ####

    foreach my $field (@fields) {

        # trim quotes if present...
        $field =~ s/^[\'\"]//g;
        $field =~ s/[\'\"]$//g;
    }

    my $index         = 0;
    my $defined_count = 0;
    my %Totals;    ## hash to track column totals if required ##
    my %Defined;
    my %Max;

    ## allow optional adjustments to the totals columns as custom input ##
    my %Summary;
    %Summary = %$summary if $summary;

    #   if ($add_columns) { $Summary{''}{''} = "SUM($add_column)" }
    my %Adjusted;
    my $rownum = 0;

    my %Tables;
    my $layer;
    my @layers;
    $dbc->Benchmark('pre_hash_loop');

    # creates look up hash for field references in the form Field Alias->id->hyperlink to field homepage(Field reference as title)
    my %ref_links = ();
    if ( !$no_links ) {
        %ref_links = %{ build_ref_lookup( -dbc => $dbc, -hash => \%Hash, -fields => \%fields, -blank_display_value => $blank_display_value ) };
    }

    my %Layer_alias;
    my %Selectable;
    my %layer_index;
    my $subtitle_hash;

    my @quoted_keys;
    foreach my $key (@keys) { push @quoted_keys, "'$key'" }

    if ( exists $Hash{ $quoted_keys[0] }[$index] ) {
        @keys = @quoted_keys;
    }

    my %IDs;
    my %Cell_Colour;
    $dbc->Benchmark('start_hash_loop');
    while ( exists $Hash{ $keys[0] }[$index] ) {
        if ($layer_by) {
            $layer = $Hash{$layer_by}[$index];
            if ( !$layer ) { $layer = 'NONE'; }
        }
        else { $layer = '1' }

        $rownum++;
        my @row;
        if ($selectable_field) {
            my $val = clear_tags( $Hash{$selectable_field}[$index] );

            my $set_mark;
            if ( $selectable_field_parameter ne 'Mark' ) {
                $set_mark = "if (this.checked) {
                                this.form.appendChild(getInputNode({'type':'hidden','name':'Mark','value': $val, 'id': 'Mark$val'}));
                            } else {
                                var marked = document.getElementById('Mark$val'); marked.parentNode.removeChild(marked);
                                
                            }";
            }
            my $checkbox_randnum = substr( rand(), -8 );
            my $checkbox_id      = "checkbox" . $checkbox_randnum;                                                                                      ##use checkbox_id to ensure toggle only the checkbox in this layer
            my $selected         = qq^<input type="checkbox" name=$selectable_field_parameter value="$val" id ="$checkbox_id" onClick="$set_mark"/>^;
            push( @row, $selected );

            #my $ids;
            #$ids .= ",$val" if $val;
            #$Selectable{$layer} = $ids;
            $Selectable{$layer} .= ",$checkbox_id" if $val;
        }
        my $col        = 0;
        my $row_colour = $colour;                                                                                                                       ## optional colour specification (if highlight specification included)
        my $id_value;

        ## breakout if currently grouping ##
        if ( $group && $regroup ) {
            my $group_label = $group;
            if ( $group =~ /(.*) AS (.*)/i ) { $group = $1; $group_label = $2; }

            require SDB::DB_Form_Views;
            push @row, SDB::DB_Form_Views::regenerate_query_link( %args, -regroup => $regroup, -regenerate_condition => "$group = '$Hash{$group_label}[$index]'" );
        }

        my $extra_headers = 0;
        foreach my $key (@keys) {
            my $value = $Hash{$key}[$index];

            my $header_col = $col + $extra_headers;
            if ( $layer_by eq $key ) { $header_col = 0; $extra_headers--; }

            my $displayed_value = $value;

            if ( $displayed_value eq '' ) {
                $displayed_value = $blank_display_value;
            }
            elsif ( defined( $max_field_length->{$key} ) && ( length($displayed_value) > $max_field_length->{$key} ) ) {
                my $truncated_value = substr( $displayed_value, 0, $max_field_length->{$key} ) . "...";
                $displayed_value = Show_Tool_Tip( $truncated_value, $displayed_value );
            }

            #            elsif ( tag_trimmed_length($displayed_value) > $max_length && ( $displayed_value !~ /\<TABLE/i ) ) {
            #                ## long string ... but EXCLUDE cells with embedded tables ##
            #
            #                ## if multiple values, use folder to display ##
            #                my $start = tag_trimmed_substr( $displayed_value, $max_length, -no_tags => 1 );
            #                $displayed_value = create_tree( -tree => { 'long' => $displayed_value }, -style => 'expand', -closed_title => "$start..", -open_title => '', -closed_tip => $displayed_value );

            #            }

            ## set static label if applicable ##
            if ( $static_labels->{$key} ) {
                $displayed_value = $static_labels->{$key};
            }

            my ($link_parameter);
            my $localtable;
            my $localfield;
            my $class = $Hash{$class_key}[$index] if $class_key;

            ## field may be Table.Field or Field ##
            if ( $fields[$col] =~ /^(\w+)\.(\w+)$/ ) {
                $localtable = $1;
                $localfield = $2;
            }
            ## generate dynamic link
            if ( ( defined $Links{ $fields[$col] } ) || ( defined $Links{$localfield} ) || ( defined $Links{$key} ) ) {
                $link_parameter = $Links{ $fields[$col] } || $Links{$localfield} || $Links{$key};

                if ( $list_in_folders && ( my ($column) = grep /^$display_headers[$header_col]$/, @$list_in_folders ) ) {
                    ## leave parameters with value tag... ##
                }
                else {
                    ## encode special characters in $value
                    my $encoded_value = $value;
                    $encoded_value  =~ s|#|\%23|g;                    # URL-encoding '#' to '%23'
                    $link_parameter =~ s/<VALUE>/$encoded_value/g;    ## replace <VALUE> tag with this value
                }

                if ( $link_parameter =~ /<\w+>/ ) {
                    foreach my $replace_field (@keys) {
                        ## add option to replace tag for any defined field ##
                        my $replacement = $Hash{$replace_field}[$index];
                        if ($replacement) {
                            $link_parameter =~ s /<$replace_field>/$replacement/g;
                        }
                    }
                }

                #                Message(" $fields[$col] ($localfield or $key) = $link_parameter");
            }
            
            ## Highlighting ##
            if ( ref $highlight_cell eq 'HASH' ) {
                foreach my $key ( keys %$highlight_cell ) {
                    if ( $highlight_cell && $displayed_value =~ /^$key$/ ) {
                        $Cell_Colour{$rownum}{$col+1} = $highlight_cell->{$key};
                    }
                }
            }
            if ( ref $highlight_string eq 'HASH' ) {
                foreach my $key ( keys %$highlight_string ) {
                    if ( $highlight_string && $displayed_value =~ /\Q$key\E/ ) {
                        $row_colour = $highlight_string->{$key};
                    }
                }
            }
            elsif ( defined $highlight_string && $displayed_value =~ /\Q$highlight_string\E/ ) {
                $row_colour = $highlight_colour;
            }
            elsif ( defined $highlight_string && $displayed_value =~ /$highlight_string/ ) {
                ## similar to above but with standard OR separated strings ##
                $row_colour = $highlight_colour;
            }

            if ( $displayed_value ne $blank_display_value ) {
                if ( $list_in_folders && ( my ($column) = grep /^$display_headers[$header_col]$/, @$list_in_folders ) ) {
                    ## listing field list (eg group_concat fields) in folders if necessary
                    my @list   = split_list($value);
                    my $Fcount = int(@list);

                    my $list = '';
                    if ( !$no_links && scalar @list ) {

                        if ($link_parameter) {
                            $link_parameter =~ s/.\n/<BR>/g;

                            foreach my $item (@list) {
                                my $itemized_link_parameter = $link_parameter;
                                $itemized_link_parameter =~ s/<VALUE>/$item/g;    ## replace <VALUE> tag with this value

                                my $tip = $Tip{ $display_headers[$header_col] };
                                $tip ||= "Go to $display_headers[$header_col] $item";
                                $item = &Link_To( $link, $item, $itemized_link_parameter, -window => ['newwin'], -tooltip => $tip );
                            }
                        }
                        elsif ( scalar keys %{ $ref_links{$key} } ) {
                            foreach my $item (@list) {
                                if ( $item !~ /\w/ ) {next}
                                if ( $ref_links{$key}{$item} ) {
                                    $item = $ref_links{$key}{$item};
                                }
                            }
                        }
                    }

                    if ( $Fcount > 1) { $list = $list_prefix }
                    $list .= join "$list_separator$list_prefix", @list;

                    if ( ( $Fcount > $collapse_length) ) {
                        ## for some reason multiple blank values yields ',' from Group_Concat(distinct)  ?? ##

                        ## if multiple values, use folder to display ##
                        $displayed_value = create_tree( -tree => { "list" => $list }, -style => 'expand', -closed_title => "list ($Fcount)", -open_title => '', -closed_tip => 'expand to see list' );
                    }
                    elsif ( tag_trimmed_length( $list[0] && ( $list[0] !~ /\<TABLE/i ) ) > $max_length ) {
                        ## long string ... but EXCLUDE cells with embedded tables ##

                        ## if multiple values, use folder to display ##
                        my $start = tag_trimmed_substr( $list[0], $max_length, -no_tags => 1 );
                        $displayed_value = create_tree( -tree => { '(long)' => $list }, -style => 'expand', -closed_title => "$start...", -open_title => '', -closed_tip => $list[0] );

                    }
                    else {
                        ## if single value , remove bulleted listing and display without folder
                        $list =~ s/(<LI>|<UL>|<\/UL>)//g;
                        $displayed_value = $list;
                    }
                }
                else {
                    if ($link_parameter) {
                        $link_parameter =~ s/.\n/<BR>/g;
                        ## if custom links supplied for this column ##
                        $displayed_value = &Link_To( $link, $displayed_value, $link_parameter, -window => ['newwin'] );
                    }
                    elsif ( $ref_links{$key}{$value} ) {
                        $displayed_value = $ref_links{$key}{$value};
                    }

                    if ( defined $Tip{ $display_headers[$header_col] } ) {
                        ## simply add tooltip to displayed value ##
                        $displayed_value = Show_Tool_Tip( $displayed_value, $Tip{ $display_headers[$header_col] } );
                    }

                    #	Message("Tip $key ($display_headers[$header_col] = $Tip{$display_headers[$header_col]} => $displayed_value");
                }
            }

            ## total columns if totals or averages requested...
            if ( ( $total_columns && $total_columns =~ /\b$key\b/ ) || ( $average_columns && $average_columns =~ /\b$key\b/ ) ) {
                if ( $value =~ /[0-9]/ ) {
                    $Totals{$layer}{$key} += $value;
                    $Defined{$layer}{$key}++;
                }    ## only count values if defined (zero included)
            }
            elsif ( $count_records && $key eq $keys[0] ) {

                #if ($value =~ /\w/) {
                $Defined{$layer}{ $keys[0] }++;

                #}   ## ignore only null (blank or -)
            }

            if ( $max_columns && $max_columns =~ /\b$key\b/ ) {
                $Max{$layer}{$key} = $value if ( !$Max{$layer}{$key} || ( $value > $Max{$layer}{$key} ) );
            }

            if ( $layer_by && ( $layer_by eq $key ) ) {
                if ( $displayed_value eq $blank_display_value ) {
                    $Layer_alias{$layer} = $layer;
                }
                else {
                    $Layer_alias{$layer} = $displayed_value;
                }
            }
            else {
                push( @row, $displayed_value );
            }

            $col++;

            if ( $highlight && defined $highlight->{$col} ) {
                if ( defined $highlight->{$col}{$value} ) { $row_colour = $highlight->{$col}{$value} }
            }
            if ( $highlight_column{$key} ) {
                push @{ $highlight_column{$key}{$value}{$layer}{rowcol} }, "$layer_index{$layer},$col";
            }
        }

        if ( grep /^\Q$layer\E$/, @layers ) { }    ## existing layer ...
        else {
            if ($Display) {
                $Tables{$layer} = $Display;
            }
            else {
                if ($resize) {
                    $id = 'resizable' . int( rand(1000000) );
                }
                else { $id = int( rand(1000000)) }
                
                $IDs{$layer} = $id;
                $Tables{$layer} = HTML_Table->new( -autosort => 1, -toggle => $toggle, -border => $border, -nolink => 1, -scrollable_body => $fixed_header, -style => $style, -id => $id, -cell_style => $cell_style, -table_class=>$table_class);
                my $layer_title = $title;
                if ( $Layer_alias{$layer} ) { $layer_title .= " : $Layer_alias{$layer}" }

                $Tables{$layer}->Set_Title( $layer_title, fsize => '-1' );

                #    $Tables{$layer}->Set_Class('small');
                $Tables{$layer}->Set_Font($reduced_font);
                $Tables{$layer}->Set_Width($width);
                $Tables{$layer}->Toggle_Colour_on_Column($toggle_on_column) if $toggle_on_column;
            }
            if ( $by =~ /row/i ) {
                $Tables{$layer}->Set_Headers( \@display_headers, -space_words => $space_words );
                if (%field_info) {
                    $Tables{$layer}->set_header_info( \%field_info );
                }
            }
            else {
                $Tables{$layer}->Set_Column( \@display_headers );
            }
            push @layers, $layer;
        }

        if ( $by =~ /row/i ) { $Tables{$layer}->Set_Row( [@row], $row_colour ) }
        else {
            $Tables{$layer}->Set_Column( [@row] );
            $Tables{$layer}->Set_Cell_Colour( $rownum, $col, $row_colour );
        }
        
        if ( $Cell_Colour{$rownum} ) {
            foreach my $coloured_col (keys %{$Cell_Colour{$rownum}}) {
                my $cell_colour = $Cell_Colour{$rownum}{$coloured_col};
                if ($cell_colour =~/^\#/) {
                    $Tables{$layer}->Set_Cell_Colour( $rownum, $coloured_col, $cell_colour );
                }
                else {
                    $Tables{$layer}->Set_Cell_Class( $rownum, $coloured_col, $cell_colour );                   
                }
            }
        }
        
        $layer_index{$layer}++;
        $index++;
    }
    $dbc->Benchmark('stop_hash_loop');

    foreach my $layer ( keys %Tables ) {

        foreach my $column ( keys %highlight_column ) {

            foreach my $value ( keys %{ $highlight_column{$column} } ) {
                my $colour = $highlight_column{$column}{$value}{colour};
                my $class  = $highlight_column{$column}{$value}{class};

                if ( $colour || $class ) {
                    my @coordinates = @{ $highlight_column{$column}{$value}{$layer}{rowcol} } if defined $highlight_column{$column}{$value}{$layer}{rowcol};

                    foreach my $set (@coordinates) {
                        my @rowcol = split ',', $set;
                        my $row    = ++$rowcol[0];
                        my $col    = ++$rowcol[1];
                        if ($colour) { $Tables{$layer}->Set_Cell_Colour( $row, $col, $colour ) }
                        if ($class) { $Tables{$layer}->Set_Cell_Class( $row, $col, $class ) }
                    }
                }
            }
        }

        if ( $subtitles && defined $subtitles->{$layer} ) {
            if   ( $layer eq '1' ) { $subtitle_hash = $subtitles }
            else                   { $subtitle_hash = $subtitles->{$layer} }

            foreach my $key ( sort keys %{$subtitle_hash} ) {
                my $title  = $subtitle_hash->{$key}{'title'};
                my $span   = $subtitle_hash->{$key}{'colspan'};
                my $colour = $subtitle_hash->{$key}{'colour'};
                $Tables{$layer}->Set_sub_title( $title, $span, $colour );
            }
        }
    }
    $dbc->Benchmark('post_hash_loop');

    #array of array for footers for each layer
    my %layer_footer;

    ## Add totals and/or averages if requested ##
    if ( $average_columns || $total_columns ) {
        foreach my $layer (@layers) {
            my @totals;

            if ($selectable_field) { push @totals, '' }

            foreach my $col (@keys) {    ## convert to average if average of column requested.
                my $total  = $Totals{$layer}{$col};
                my $avg    = $total / $Defined{$layer}{$col} if $Defined{$layer}{$col};
                my $max    = $Max{$layer}{$col};
                my $Ccount = $Defined{$layer}{$col};
                my $show;

                if ( $Totals{$layer}{$col} && $total_columns =~ /\b$col\b/ ) {    ## print totals
                    my $show_total .= sprintf "%0.2f ", $total;
                    $show .= Show_Tool_Tip( $show_total, "N = $Ccount ( / $index)" );
                }

                if ( $Totals{$layer}{$col} && $average_columns =~ /\b$col\b/ ) {    ## print averages
                    my $show_avg = sprintf "[Avg=%0.2f]", $avg;
                    $show .= Show_Tool_Tip( $show_avg, "N = $Ccount ( / $index)" );
                }

                if ( $Max{$layer}{$col} && $max_columns =~ /\b$col\b/ ) {           ## print averages
                    $show .= "[Max=$max]";
                }
                ## if totals are adjusted specifically, replace tags in custom querey with column totals ##
                if ( $summary && ( grep /\b$col\b/, values %Summary ) ) {
                    foreach my $key ( sort keys %Summary ) {
                        if ( grep /^$key$/, @layers ) {next}                        ## skip the layered specific key info
                        $Summary{$layer}{$key} = $Summary{$key};
                        $Summary{$layer}{$key} =~ s /\<SUM\($col\)\>/$total/ig;
                        $Summary{$layer}{$key} =~ s /\<MAX\($col\)\>/$max/ig;
                        my $sub = ( $Summary{$layer}{$key} =~ s /\<AVG\($col\)\>/$avg/ig );
                    }
                }

                $show = "<B>$show</B>" if $show;                                    ## make bold
                $show ||= '';
                push( @totals, $show ) unless ( $col eq $layer_by );
            }
            my $count = "$Defined{$layer}{$keys[0]}";
            if ( $index > $count ) { $count .= " / $index" }

            $totals[0] ||= "<B>Totals</B><BR>($count Records)";                     ### if first column is blank, give this row a 'Totals' title.
            if ($average_columns) { $totals[0] .= " [Avg]" }

            unless ($no_footer) { push @{ $layer_footer{$layer} }, { class => "lightredbw", enteries => \@totals } }
        }
    }
    elsif ( $count_records && !$no_footer ) {
        foreach my $layer (@layers) {
            my $count = $Defined{$layer}{ $keys[0] };

            if ( $index > $count ) { $count .= " / $index" }
            push @{ $layer_footer{$layer} }, { class => "lightredbw", enteries => ["$count Records"] };    ## show record count at the bottom.
        }
    }

    foreach my $layer (@layers) {
        if ($footer) {
            push @{ $layer_footer{$layer} }, { class => "darkgrey", enteries => [$footer] };
        }
        $Tables{$layer}->set_footer( $layer_footer{$layer} );
    }

    ## add adjusted total columns if applicable ##
    if ($summary) {
        foreach my $layer (@layers) {
            foreach my $key ( sort keys %{ $Summary{$layer} } ) {
                unless ( $key && $Summary{$layer}{$key} ) {next}
                my ($value) = $dbc->Table_find_array( -fields => [ $Summary{$layer}{$key} ] );
                $Tables{$layer}->Set_sub_header("<B>$key: $value");
            }
        }
    }

    $Tables{$layer}->Set_Suffix($append)  if $append;
    $Tables{$layer}->Set_Prefix($prepend) if $prepend;
    my $output = '';

    $dbc->Benchmark('displayed_hash');

    #add elements for fixed headers, script for automatic body resize and toggle on/off button
    my $fixedheader_elements;
    my $fixedheader_elements_end;

    if ( $fixed_header && $0 =~ /cgi-bin/ ) {
        $fixedheader_elements = "\n<div id=\"view_results\">";
        $fixedheader_elements .= "\n\t<br /><script type=\"text/javascript\">
        															jQuery('#view_results').ready(function() {
																		scrollTableInit();		    
																		jQuery('.dlink').click(function(){	scrollTableInit();	});
																	});	</script>";

        my $toggle_desc = "Toggles table data to be scrollable in the table on its own or by the browser page ";

        $fixedheader_elements
            .= "\n\t<br /><button id=\"tglTblScrollLock\" type=\"button\" style=\"background-color: #A0FFA1;width:108px;\" disabled=\"disabled\" onclick=\"scrollTableLockToggle();\" title=\"Locks head of the table to the top of the visible page and stops browser scrolling\" value=\"Lock Table\">Lock Table</button>\n";

        $fixedheader_elements
            .= "\n\t<button id=\"tglTblScroll\" type=\"button\" style=\"background-color: #A0FFA1;\" onclick=\"scrollTableToggle(); HideElement('tglTblScroll'); unHideElement('tglTblScroll2');\" title='$toggle_desc' value=\"Toggle table fit\">Unlock Headers</button>\n"
            . "\n\t<button id=\"tglTblScroll2\" type=\"button\" style=\"background-color: #A0FFA1;  display:none\" onclick=\"scrollTableToggle();  HideElement('tglTblScroll2'); unHideElement('tglTblScroll')\" title='$toggle_desc' value=\"Toggle table fit\">Lock Headers</button>\n";

        $fixedheader_elements_end = "</div><div style=\"clear:both;\" /><br />";
        $fixedheader_elements .= '<HR>';
    }

    my $html;
    if ($layer_by) {
        my %Layers;
        my @new_layers;
        foreach my $layer (@layers) {
            my $rows = $Tables{$layer}->{rows};

            ## add toggle button if selectable fields ##
            if ($selectable_field) {
                my $layer_ids = $Selectable{$layer};
                my $toggle_header = toggle_header( $selectable_field_parameter, $layer_ids );

                #unshift(@display_headers, 'Select') if ($layer eq $layers[0]);   ## remove toggling if layers (toggles over layers - confusing)
                shift(@display_headers) if ( $layer ne $layers[0] );    ## Remove previous layer's toggle if not first layer
                unshift( @display_headers, $toggle_header );            ## Add toggle for this layer (i.e. the layer_ids are unique to this layer)
                $Tables{$layer}->Set_Headers( \@display_headers, -space_words => $space_words );
                if (%field_info) {
                    $Tables{$layer}->set_header_info( \%field_info );
                }
            }

            my $new_layer = clear_tags( $Layer_alias{$layer} ) || $layer;
            $new_layer = "$new_layer <BR>[$rows]" if $show_count;       ## append the number of rows in this layer to the layer heading
            push @new_layers, $new_layer;
            $Layers{$new_layer} = '';

            #            When $layer_name has a / in it, it will cause problems when we try to save the file.  Replace / with an empty space
            #            $Layers{$new_layer} .= $Tables{$layer}->Printout("$print_path/$print_link.$layer" . $timestamp . ".html",$html_header) if $print_link;
            #            $Layers{$new_layer} .= $Tables{$layer}->Printout("$print_path/$print_link.$layer" . $timestamp . ".xlsx",$html_header) if $excel_link;
            my $layer_name = $layer;
            $layer_name =~ s/[\/]//g;
            my $temp_file_name;
            if    ($print_link) { $temp_file_name = "$print_path/$print_link.$layer_name" . '_' . $timestamp }
            elsif ($excel_link) { $temp_file_name = "$print_path/$excel_link.$layer_name" . '_' . $timestamp }
            elsif ($csv_link)   { $temp_file_name = "$print_path/$csv_link.$layer_name" . '_' . $timestamp }

            $Layers{$new_layer} .= $Tables{$layer}->Printout( $temp_file_name . ".html", $html_header ) if $print_link;
            $Layers{$new_layer} .= $Tables{$layer}->Printout( $temp_file_name . ".xlsx", $html_header, -xls_settings => { 'show_title' => 1 } ) if $excel_link;
            $Layers{$new_layer} .= $Tables{$layer}->Printout( $temp_file_name . ".csv", $html_header ) if $csv_link;
            $Layers{$new_layer} .= $Tables{$layer}->Printout( $temp_file_name . ".gif", $html_header ) if $gif_link;

            if ($rows) {
                if ($return_html) {
                    $Layers{$new_layer} .= $Tables{$layer}->Printout(0);
                }
                elsif ($return_graph) {
                    $Layers{$new_layer} .= "<IMG SRC='/dynamic/tmp/$print_link.$layer_name" . '_' . $timestamp . ".gif' />\n";
                }
                elsif ($google_chart) {
                    $Layers{$new_layer} = graph_table( $Tables{$layer} );    ##
                }
            }
            else {
                $Layers{$new_layer} .= "\n<BR>$alt_message<BR>\n" if $alt_message;
            }
            
            my $id = $IDs{$new_layer};            
        }
        @layers = @new_layers;

        if ( !@layers ) {
            $output .= $alt_message if $alt_message;
            print $output unless ( $return_html || $return_graph );
        }
        elsif ( $return_html || $return_graph ) {
            if ($fixed_header) {
                $output .= $fixedheader_elements;                                                                                                         #append required elements for fixed_header
                $output .= define_Layers( -layers => \%Layers, -order => \@layers, -print => 0, -show_count => $show_count, -format => $layer_format );
                $output .= $fixedheader_elements_end;
            }
            else {
                $output .= define_Layers( -layers => \%Layers, -order => \@layers, -print => 0, -show_count => $show_count, -format => $layer_format );
            }
        }
        elsif ($return_table) {
            Message("Invalid option (return_table) with layer option");
            return;
        }
        else {
            $output .= define_Layers( -layers => \%Layers, -order => \@layers, -print => !( $return_html || $return_graph ), -show_count => $show_count, -format => $layer_format );
            print $output;
        }
    }
    elsif ($index) {
        ## add toggle button if selectable fields ##
        if ($selectable_field) {
            my $layer_ids = $Selectable{$layer};
            my $toggle_header = toggle_header( $selectable_field_parameter, $layer_ids );
            unshift( @display_headers, $toggle_header );
            $Tables{$layer}->Set_Headers( \@display_headers, -space_words => $space_words );
            if (%field_info) {
                $Tables{$layer}->set_header_info( \%field_info );
            }
        }
        my $temp_file_name;
        if    ($print_link) { $temp_file_name = "$print_path/$print_link" . '_' . $timestamp }
        elsif ($excel_link) { $temp_file_name = "$print_path/$excel_link" . '_' . $timestamp }
        elsif ($csv_link)   { $temp_file_name = "$print_path/$csv_link" . '_' . $timestamp }

        if ($excel_name) { $temp_file_name .= $excel_name }
        $output .= $Tables{$layer}->Printout( $temp_file_name . ".html", $html_header ) if $print_link;
        $output .= $Tables{$layer}->Printout( $temp_file_name . ".xlsx", $html_header, -xls_settings => { 'show_title' => 1 } ) if $excel_link;
        $output .= $Tables{$layer}->Printout( $temp_file_name . ".csv", $html_header ) if $csv_link;
        $output .= $Tables{$layer}->Printout( $temp_file_name . ".gif", $html_header ) if $gif_link;

        if ($return_html) {
            if ($fixed_header) {
                $output .= $fixedheader_elements;                            #append required elements for fixed_header
                $output .= $Tables{$layer}->Printout( 0, -suppress => 1 );
                $output .= $fixedheader_elements_end;
            }
            elsif ($return_excel_link) {

                #return just an excel link with no table, $excel_name is used to distinguish excel files if this is call multiple time too quickly
                $output .= $Tables{$layer}->Printout( "$print_path/$print_link" . '_' . $timestamp . $excel_name . ".xlsx", $html_header, -xls_settings => $xls_settings );
            }
            else {
                $output .= $Tables{$layer}->Printout( 0, -suppress => 1, -resize_onload => $resize_onload );
            }
            
            my $id = $IDs{$layer};
        }
        elsif ($return_graph) {
            $output .= "<IMG SRC='/dynamic/tmp/" . $timestamp . ".gif' />\n";
        }
        elsif ($google_chart) {
            $output .= graph_table( $Tables{$layer} );    ##
        }
        elsif ($return_table) {
            return $Tables{$layer};
        }
        else {
            $output .= $Tables{$layer}->Printout(0);
            print $output;
        }

    }
    else {
        if ($return_html) {
            $output .= "\n<BR>$alt_message<BR>\n" if $alt_message;
        }
        else {
            Message($alt_message) if $alt_message;
        }
    }

    $dbc->Benchmark('final_displayed_hash');

    if ($return_data) { return ( $output, \%Hash ); }    ## option allowing all data to be returned as well

    if ( $print_link && @layers ) {
        my $filename = "$print_path/$print_link" . '_' . "$timestamp.html";
        my $linkname = "$Configs{URL_domain}/dynamic/tmp/$print_link" . '_' . "$timestamp.html";

        ########### Not sure why the file is printed again here! ###########
        # remove session ID so that it won't be saved to file
        my $output_to_file = HTML_Table::remove_credential( -string => $output, -credentials => 'CGISESSID' );

        open my $OUTFILE, '>', $filename or print "Error writing to $filename";
        print $OUTFILE $html_header;
        print $OUTFILE $js_header;
        print $OUTFILE $q->start_html('Popup Window');
        print $OUTFILE $output_to_file;
        print $OUTFILE $q->end_html;
        close($OUTFILE);

        if ( int(@layers) > 1 ) { $output = Link_To( $linkname, 'Combined Page' ) . '<hr>' . $output }
    }

    #there are more rows than specified max put in folder
    if ( defined $collapse_limit && defined $Tables{1} && $index > $collapse_limit ) {
        $title ||= "($index records)";
        return create_tree( -tree => { $title => $output }, -style => 'expand' );
    }
        
    return $output;
}

##################
sub split_list {
##################
    my $string = shift;
    if ( !$string ) { return () }

    my @blocks = split /,/, $string;

    if ( $string !~ /<[a-zA-Z]/ ) { return @blocks }    ## return split list if no tags in list... quicker for simple cases

    my $open           = 0;
    my $unclosed_block = '';
    my @list;

    foreach my $block (@blocks) {
        my $copy = $block;

        if ($open) {
            $list[-1] .= ',' . $block;
        }
        else {
            push @list, $block;
        }

        while ( $copy =~ s /\<[a-zA-Z]// ) { $open++ }
        if ($open) {
            while ( $copy =~ s /\<\/[a-zA-Z]// ) { $open-- }
            while ( $copy =~ s /\/\>// ) { $open-- }
        }    ## don't bother if no tags open (eg for comment like 'A > B')
    }

    if ($open) { Message("Error: unclosed block found in <PRE>$string</PRE>") }

    return @list;
}

##
# Retrieve length of string as it appears in web browser.
# (excludes tag part of string)
#
# Return: length of visible portion of string (excluding tag portion)
#######################
sub tag_trimmed_length {
#######################
    my $string = shift;

    if ( $string !~ /<[a-zA-Z]/ ) {
        ## no tags found... return simple length
        return length($string);
    }

    while ( $string =~ s /\<[a-zA-Z].*?\>// ) { }

    return length($string);
}

##
# Retrieve length of string as it appears in web browser.
# (excludes tag part of string)
#
# Return: length of visible portion of string (excluding tag portion)
#######################
sub tag_trimmed_substr {
#######################
    my %args    = filter_input( \@_, -args => 'string,length' );
    my $string  = $args{-string};
    my $length  = $args{ -length };
    my $no_tags = $args{-no_tags};                                 ## exclude the tags (otherwise it will include the tags but only count untagged section of the string towards the length)

    my $substr;

    my $open  = 0;
    my $count = 0;
    my @chars = split //, $string;
    foreach my $char (@chars) {
        if ( $char eq '<' ) {
            $open++;
        }
        if ($open) {
            ## inside tag...
            if ( !$no_tags ) { $substr .= $char }

        }
        else {
            ## not in tag
            $substr .= $char;
            $count++;
        }
        if ( $char eq '>' ) {
            $open--;
        }

        if ( $count >= $length ) {last}
    }
    return $substr;
}

####################
sub graph_Table {
####################
    my $Table = shift;

    return 'Under Construction - Please contact Site Admin if you see this comment';

}

#
# Customizable links generated for auto-generated viewers
#
#
##################
sub home_URL {
##################
    my $class = shift;
    my $value = shift;

    my $link;
    my $module = "$Configs{perl_dir}/Core/alDente/${class}_App.pm";
    if ( -e $module ) {
        $link = "&cgi_application=alDente::${class}_App&ID=$value";
    }
    else {
        $link = "&HomePage=$class&ID=$value";
    }
    return $link;
}

#
# Simple header to toggle selected ids in a checkbox
#
#
#
###################
sub toggle_header {
###################
    my $checkbox = shift;
    my $ids      = shift;
    my $element;
    my $toggle = Show_Tool_Tip( 'Toggle', "$element Unchecks checked rows and vice-versa" ) . '<br>' . $q->radio_group(
        -name    => 'quick_pick_rows',
        -values  => '',
        -onclick => "
        // go through each element of the form, if the element is a checkbox and the element's id is in the list of ids, toggle and then update the parameter 'Mark' for the checkbox (the same 'Mark' update for the checkbox's onClick event)       
        for (var i=0; i<this.form.length; i++) {
           var e = this.form.elements[i];
           var Ename = e.id + ',';
           var Names = '$ids' + ',';
           // check if this checkbox is in the current layer
               if (e.type=='checkbox' && Ename != ',' && Names.search(Ename)>=0) {
             // toggle
                 e.checked = !e.checked;
             if (e.name == 'Mark') {continue;}
             // set 'Mark'
             if (e.checked) {
               this.form.appendChild(getInputNode({'type':'hidden','name':'Mark','value': e.value, 'id': 'Mark' + e.value}));
             } 
             else {               
               var marked = document.getElementById('Mark' + e.value); marked.parentNode.removeChild(marked);
             }
           }
        } 
"
    );

    my $deselect .= Show_Tool_Tip(
        $q->button(
            -name    => 'Clear',
            -values  => '',
            -onclick => "
        // go through each element of the form, if the element is a checkbox and the element's id is in the list of ids, deselect and then update the parameter 'Mark' for the checkbox (the same 'Mark' update for the checkbox's onClick event)       
        for (var i=0; i<this.form.length; i++) {
           var e = this.form.elements[i];
           var Ename = e.id + ',';
           var Names = '$ids' + ',';
           // check if this checkbox is in the current layer
               if (e.type=='checkbox' && Ename != ',' && Names.search(Ename)>=0) {
             // deselect
                 e.checked = null;
             if (e.name == 'Mark') {continue;}
             // set 'Mark'
             var marked = document.getElementById('Mark' + e.value); marked.parentNode.removeChild(marked);
           }
        } 
"
        ),
        "Deselects all checked rows"
    );

    my $cell = $toggle . lbr . $deselect;

    return $cell;
}

####################################################################
#
# Simple wrapper for generating a DB_Form with custom fields
#
#####################
sub query_form {
#####################
    my %args = filter_input( \@_, -args => 'dbc,fields', -mandatory => 'dbc,fields|table' );
    my $action    = $args{-action} || 'search';
    my $preset    = $args{-preset};
    my $repeat    = $args{-repeat};
    my $navigator = $args{-navigator} || 0;
    my $submit    = $args{-submit};               ## should be explicitly set to zero if you do not want an update submission button automatically included ##
    my $dbc       = $args{-dbc};

    ## args are all passed in to generate method (parameters shifted in above are shown for purposes of auto-documentation for this method and not actually necessary)

    require SDB::DB_Form;
    my $form = SDB::DB_Form->new( %args, -start_form => 0, -end_form => 0, -wrap => 0 );
    $form->configure(%args);
    my $html = $form->generate( -navigator_on => $navigator, -return_html => 1, %args );

    return $html;
}

####################################
sub add_SQL_search_condition {
####################################
    my %args   = filter_input( \@_, -args => 'dbc,field,values,type' );
    my $dbc    = $args{-dbc};
    my $field  = $args{-field};
    my $values = $args{ -values };
    my $type   = $args{-type};

    require SDB::DBIO;

    if ( !defined $type ) {
        ($type) = $dbc->Table_find( 'DBField,DBTable', 'Field_Type', "WHERE FK_DBTable__ID=DBTable_ID AND (Field_Name = '$field' OR CONCAT(DBTable_Name,'.',Field_Name) = '$field')" );
    }

    my $fk;
    my $fk_check = SDB::DBIO::foreign_key_check( -field => $field, -dbc => $dbc );

    ## Checks whether the input field is an attribute with a foreign key as a value

    if ( $type =~ /^FK/ ) {
        $fk = $type;
    }
    elsif ($fk_check) {
        $fk = $field;
    }

    if ($fk) {
        ## first convert to id list ##
        my @ids;
        foreach my $value (@$values) {
            push @ids, $dbc->get_FK_ID( $fk, $value, -validate => 0 );
        }
        $values = \@ids;
    }

    my $condition = convert_to_condition( $values, $field, $type );
    return $condition;

}

# Generates textfield or textarea (depending upon whether size or rows & cols are passed in)
# This element will expand when focused on and reduce to normal size onblur
#
# Input options:
#  -tooltip
#  -max_rows
#  -max_cols
#  -max_size
#  -split_commas - will also convert comma-delimited list to line separated list during expansion (and revert to comma-delimited list when reduced)
#
# Normal arguments are simply passed on to respective textarea or textfield call
#
# Return: field element (either textarea or textfield with appropriate onblur or onclick parameters set)
#########################
sub dynamic_text_element {
#########################
    my %args = filter_input( \@_ );

    my $max_cols    = $args{-max_cols};
    my $max_rows    = $args{-max_rows};
    my $max_size    = $args{-max_size} || $args{-max_cols};
    my $tooltip     = $args{-tooltip};
    my $help_button = $args{-help_button};                    ## flag to indicate that the message to be displayed as tooltip/popover of a help button
    my $split       = $args{-split_commas};                   ## split elements on commas -> linefeed when expanding (defaults to also unsplit on reduce)

    my $rows = $args{-rows};
    my $cols = $args{-cols};
    my $size = $args{-size};

    my $name = $args{-name};
    my $id   = $args{-id};

    my $static = $args{-static} || 0;                         ## turn off dynamic expand functionality of textfield
    my $suffix = $args{-suffix};                              ## include suffix explicitly so that it can be separated from auto_expand prompt

    my $auto_expand = $args{-auto_expand};                    ## include radio buttons to auto-expand string to max_rows values
    my $multiplier  = $args{-multiplier};                     ## enables auto-expand to be multiplied by dynamic text element

    my $reference = $id || $name || substr(rand(), -8);
    $args{-id} ||= $reference;                   ## ensure element_id defined for use by expand_text_buttons.
    
    my $element = $q->expandable_textarea(%args);

    my ( $element, $onfocus, $onblur );
    my @row;
    $args{-id} ||= substr( rand(), -8 );                      ## ensure element_id defined for use by expand_text_buttons.
    my $q = new LampLite::CGI;
    if ($static) {
        $element = Show_Tool_Tip( $q->textfield(%args), $tooltip, -help_button => $help_button );
        push @row, Show_Tool_Tip( $q->textfield(%args), $tooltip, -help_button => $help_button );
    }
    elsif ( $args{-size} ) {
        $onblur  = "reduce_textfield('$reference',$size, null, $split); " . $args{-onblur};
        $onfocus = "expand_textfield('$reference', $max_size, null, $split); " . $args{-onfocus};

        $element = Show_Tool_Tip( $q->textfield( %args, -onfocus => $onfocus, -onblur => $onblur ), $tooltip, -help_button => $help_button );
        push @row, Show_Tool_Tip( $q->textfield( %args, -onfocus => $onfocus, -onblur => $onblur ), $tooltip, -help_button => $help_button );
    }
    elsif ( $args{-rows} && $args{-cols} ) {
        $onblur  = "reduce_textfield('$reference',$rows,$cols, $split); " . $args{-onblur};
        $onfocus = "expand_textfield('$reference', $max_rows, $max_cols, $split); " . $args{-onfocus};

        $element = Show_Tool_Tip( $q->textarea( %args, -onfocus => $onfocus, -onblur => $onblur ), $tooltip, -help_button => $help_button );
        push @row, Show_Tool_Tip( $q->textarea( %args, -onfocus => $onfocus, -onblur => $onblur ), $tooltip, -help_button => $help_button );
    }
    if ($suffix) {
        $element .= $suffix;
        push @row, $suffix;
    }

    if ( $max_rows && $auto_expand ) {
        ## if total number of object is specified ##
        push @row, expand_text_buttons( -element_id => $args{-id}, -values => $auto_expand, -orientation => 'horizontal', -multiplier => $multiplier );
    }

    my $Table = new HTML_Table( -width => '100%' );
    $Table->Set_Row( \@row );
    return $Table->Printout(0);

}

#######################
sub parse_to_view {
#######################
    my $local_dbc = shift;
    my $file      = shift;
    my $query     = shift;

    if ( $query =~ /^Select (.+) FROM (.+) WHERE (.+)/i ) {
        my $fields    = $1;
        my $tables    = $2;
        my $condition = $3;
        Message("Sent to view generator");
        Message("Fields: $fields");
        Message("Tables: $tables");
        Message("Condition: $condition");
        initialize_view(
            -dbc       => $local_dbc,
            -tables    => $tables,
            -fields    => $fields,
            -condition => $condition,
            -name      => $file
        );
    }
    else {
        Message("Error: view generator must be in format: 'SELECT * FROM * WHERE *'");
    }

    return;
}

############################
# Input: hash, fields (with the field alias and actual sql field)
# Builds a hash for field references in the form FieldAlias->id->hyperlink to field homepage(Field reference as title)
# Used mainly for display hash, or anything that requires a lot of field references linking to their homepage
# Outputs reference hash
############################
sub build_ref_lookup {
############################
    my $self = shift;

    my %args                = &filter_input( \@_, -args => 'dbc,hash,fields,blank_display_value,enable_csv_check, list_prefix,list_separator', -mandatory => 'dbc,hash,fields' );
    my $hash_ref            = $args{-hash};
    my $fields_ref          = $args{-fields};                                                                                                                                       # fields from the fields hash passed into display_hash
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $list_prefix         = $args{-list_prefix} || '';
    my $list_separator      = $args{-list_separator} || ',';
    my $enable_csv_check    = $args{-enable_csv_check} || 0;
    my $blank_display_value = $args{-blank_display_value} || '';

    my %hash   = %{$hash_ref};
    my %fields = %{$fields_ref};
    if ( !( keys %hash ) || !( keys %fields ) ) {
        return {};
    }

    my %ref_info = ();
    my @dbtable_names = $dbc->Table_find( 'DBTable', 'DBTable_Name', "WHERE 1" );

    foreach my $key ( keys %fields ) {
        my $field = $fields{$key};
        my $ref_table;

        #match fields that are reference fields (usually primary and foreign keys)
        if ( $field =~ /^COUNT\s*\(/i ) {
            next;
        }
        elsif ( $field =~ /(^|\.)FK[a-zA-Z0-9]*_(\w+)__ID\W*$/ ) {
            $ref_table = $2;
        }
        elsif ( $field =~ /(^|\.)([\w]+)[_]ID\W*$/ ) {
            my $name = $2;
            if ( grep {/^$name$/} @dbtable_names ) {
                $ref_table = $2;
            }
            else {
                next;
            }
        }
        elsif ( $field =~ /(^|\.)Library_Name\W*$/i || $field =~ /(^|\.)FK_Library__Name\W*$/i ) {
            $ref_table = 'Library';
        }
        else {
            next;
        }

        if ( !defined $hash{$key} ) {next}

        my @field_data = @{ $hash{$key} };

        # prepare field_data for batch query
        @field_data = grep( /\S/, @field_data );    # remove blanks eg. ' '
                                                    # remove duplicates
        my %comb;
        @comb{@field_data} = ();
        @field_data = keys %comb;

        if ( !@field_data ) {
            next;
        }

        my $id_links = 0;
        if ( 0 && $field =~ /(^|\.)$key$/ ) {
            ## simple id without alias should probably default to use id.
            ## if label wanted use (eg) 'Rack_ID as Rack'... ##
        }
        elsif ( $key =~ /(id|ids)$/i && $key !~ /__id/i ) {
            $id_links = 1;
        }

        my $check_csv = 0;
        if ( $enable_csv_check && $field =~ /GROUP_CONCAT/i ) {
            $check_csv = 1;
        }

        $ref_info{$key} = build_ref_links(
            -dbc                 => $dbc,
            -table               => $ref_table,
            -field_data          => \@field_data,
            -id_links            => $id_links,
            -check_csv           => $check_csv,
            -list_prefix         => $list_prefix,
            -list_separator      => $list_separator,
            -blank_display_value => $blank_display_value
        );
        if ( !defined $ref_info{$key} || !%{ $ref_info{$key} } ) {
            delete $ref_info{$key};
            next;
        }
    }

    return \%ref_info;
}

############################
# Input: field table, array of field data, id_links -  0 to display id 1 to display field_reference
# Builds links from a hash field
# builds ID links or field reference links
# Output: hash of links for each unique data
############################
sub build_ref_links {
######################
    my $self                = shift;
    my %args                = &filter_input( \@_, -args => 'dbc,table,field_data,id_links,check_csv,list_prefix,list_separator,blank_display_value', -mandatory => 'dbc,table,field_data' );
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $table               = $args{-table};
    my $field_data_ref      = $args{-field_data};
    my $id_links            = $args{-id_links} || 0;
    my $check_csv           = $args{-check_csv};
    my $list_prefix         = $args{-list_prefix} || '';
    my $list_separator      = $args{-list_separator} || ',';
    my $blank_display_value = $args{-blank_display_value} || '';
    my $link                = $args{-homelink} || $dbc->session->param('homelink') || $dbc->{homelink};                                                                                        ## link used in auto-generated link references

    my @field_data = @$field_data_ref;

    my %data_links = ( 0, $blank_display_value );

    my ($primary_key) = $dbc->get_field_info( $table, -type => 'pri' );

    my $all_field_data = Cast_List( -list => \@field_data, -to => 'string' );
    if ($id_links) {
        my $field_data_str   = Cast_List( -list => $all_field_data, -to => 'string' );
        my @basic_field_data = Cast_List( -list => $field_data_str, -to => 'array' );

        # build and create hash for reference links
        foreach my $id (@basic_field_data) {
            my $link_parameter = home_URL( $table, $id );
            $data_links{$id} = Link_To( $link, $id, $link_parameter, -window => ['newwin'], -tooltip => "Go to $table record $id" );
        }

    }
    else {
        my $field_data_str = Cast_List( -list => $all_field_data, -to => 'string', -autoquote => 1 );

        # get query conditions to for field reference SELECT $Vfield FROM $Vtable WHERE $primary = ? $Vcondition";
        my ( $Vtable, $Vfield, $ofield, $TableName_list, $Vcondition ) = $dbc->get_view( $table, $primary_key, $primary_key );

        # get field references for all records in current field using above query conditions
        my %raw_ref = $dbc->Table_retrieve( $Vtable, [ $primary_key, $Vfield ], "WHERE $primary_key IN ($field_data_str) $Vcondition" );

        my @raw_ref = @{ $raw_ref{$primary_key} } if $raw_ref{$primary_key};
        my $count = @raw_ref;

        for my $index ( 0 .. $count - 1 ) {
            my $id        = $raw_ref{$primary_key}[$index];
            my $ref_value = $raw_ref{$Vfield}[$index];
            $data_links{$id} = Link_To( $link, $ref_value, "&HomePage=$table&ID=$id", -window => ['newwin'], -tooltip => "Go to $table record $id" );

        }
    }

    # create hash lookup for ids that are Group_Concat-ed or like csv eg. '1234, 4354, 1234' => 'Link1, Link2, Link3'
    if ($check_csv) {
        my $separator = $list_separator . $list_prefix;
        foreach my $data (@field_data) {
            if ( $data =~ /,/ ) {
                my @data_arr = split ',', $data;
                my @link = ();
                foreach my $sub_data (@data_arr) {
                    push @link, $data_links{$sub_data};
                }
                $data_links{$data} = $list_prefix;
                $data_links{$data} .= join $separator, @link;
            }
        }
    }    # end group_concat record hash additions

    return \%data_links;
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

$Id: HTML.pm,v 1.5 2004/11/30 01:43:42 rguin Exp $ (Release: $Name:  $)

=cut

1;
