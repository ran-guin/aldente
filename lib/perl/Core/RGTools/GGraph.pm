##################################################################################################################################
# GGraph.pm
#$self->message(
# SQL Google Graph tools
#
# $Id: GGraph.pm,v 1.107 2004/11/30 01:42:24 rguin Exp $
###################################################################################################################################
package GGraph;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

GGraph.pm - Wrapper used to generate Google Chart graphs dynamically on web pages

=head1 SYNOPSIS <UPLINK>

=head1 DESCRIPTION <UPLINK>sub

=for html
    
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
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Storable;
use Data::Dumper;
use Benchmark;

# Temporary #
use SDB::HTML;
use RGTools::RGIO;

#use AutoLoader;
use Carp;

use vars qw(%Benchmark);

#
# Constructor:
#
#  eg my $Graph = new GGraph();
#  $Graph->google_chart(-type=>'Pie', -data=>\%data);
#
# return: blessed object
############
sub new {
############
    #
    # Method     : new()
    # Usage      : my $chart = new GGraph(-type=>'Pie')
    # Purpose    : Create a new GGraph object
    # Returns    : GGraph object
    # ============================================================================
    my $this = shift;
    my %args = @_;

    my $class = ref($this) || $this;

    my $self = {};

    ## establish general default values ##
    my $Defaults = {
        'height' => 240,
        'width'  => 400,
        'type'   => 'ColumnChart',
    };

    foreach my $key ( keys %$Defaults ) {
        $self->{defaults}{$key} = $Defaults->{$key};
    }

    bless $self, $class;

    if ( keys %args ) { $self->set_options(%args) }
    $self->{warnings} = [];

    ## Manage static list of options below ##
    my @general_options = qw(name dataname type data merge xaxis yaxis xaxis_title yaxis_title);

    ## Chart options will be added as part of the draw function ##
    my @chart_options   = qw(height width title is3d isStacked colors);
    my @boolean_options = qw(is3d isStacked logScale);
    my @axis_options    = qw(logScale);

    $self->{option_list}     = \@general_options;    #
    $self->{chart_options}   = \@chart_options;      # list of options available to chart objects
    $self->{boolean_options} = \@boolean_options;    # keep track of options that are boolean in nature (need to be converted to 'true' or 'false')
    $self->{axis_options}    = \@axis_options;
    return $self;

}

# Newer Google Charts feature (not yet used...)
#
# not yet implemented in this module, but may make customization easier.
# (may replace google_chart or parts of it)
#
#
# Return: javascript
################
sub wrapper {
################
    my $self          = shift;
    my $type          = $self->{type};
    my $data_string   = $self->{data_string};      ## eg [['Germany', 'USA', 'Brazil', 'Canada', 'France', 'RU'], [700, 300, 400, 500, 600, 800]]
    my $option_string = $self->{option_string};    ## eg {'title': 'Countries'}
    my $name          = $self->{name};

    my $jscript = <<WRAPPER;
function drawVisualization() {
  var wrapper = new google.visualization.ChartWrapper({
    chartType: $type,
    dataTable: $data_string,
    options: $option_string,
    containerId: $name
  });
  wrapper.draw();
}
WRAPPER

    return $jscript;
}

#
# Populate object attributes for any list of supplied arguments
# (also sets package based upon type)
#
# Return: hash of attributes set
#######################
sub set_options {
#######################
    my $self = shift;
    my %args = @_;

    foreach my $option ( @{ $self->{option_list} }, @{ $self->{chart_options} }, @{ $self->{boolean_options} }, @{ $self->{axis_options} } ) {
        if ( $args{"-$option"} ) {
            $self->{$option} = $args{ -$option };

            if ( $option eq 'name' ) {
                ## set default dataname and function name ##
                $self->{dataname} ||= $self->{name} . 'Data';
                $self->{function} ||= $self->{name} . 'Draw';
            }
            elsif ( $option eq 'type' ) {
                if ( $args{-type} =~ /^(Pie|Motion|Bar|Column|Area|Scatter)$/ ) {
                    ## automatically add 'Chart' to the graph type if it is using the short form ##
                    $self->{type} .= 'Chart';
                }
                $self->{package} = 'corechart';
                if ( $self->{type} =~ /^(Table)$/ ) { $self->{package} = 'table' }
            }
        }
        elsif ( !defined $self->{$option} && defined $self->{defaults}{$option} ) {
            $self->{$option} = $self->{defaults}{$option};
        }
    }

    return 1;    ## returns values set at this time
}

### Reference to alDente modules
#
#
# Dynamically generates ajax script for code using Google Charts
#
# Graph  is embedded directly into page as required.
#
# Return: embeds dynamically generated graph into page
######################
sub google_chart {
######################
    my $self   = shift;
    my %args   = @_;
    my $debug  = $args{-debug};
    my $file   = $args{-file};
    my $quiet  = $args{-quiet};
    my $height = $args{-height};
    my $width  = $args{-width};
    my $colors = $args{-colors};

    if ( !$args{-name} || !$args{-data} ) {
        print "Charts must have a name and defined data associated with them";
        return;
    }

    $self->{defaults}{height} = $height if $height;
    $self->{defaults}{width}  = $width  if $width;
    $self->{colors}           = $colors if $colors;

    if ($quiet) { $self->{quiet} = 1 }

    my %options = $self->set_options(%args);

    my $jscript = $self->_initialize();

    $jscript .= $self->google_data();

    $jscript .= $self->_draw();
    $jscript .= $self->_close();

    if ($debug) {
        if ( @{ $self->{warnings} } ) {
            print "WARNINGS: ";
            print join "; ", @{ $self->{warnings} };
        }
    }

    if ($file) {
        ## optionally create a single html page for this chart ##
        open my $FILE, '>', $file or print "Could not open $file";
        print $FILE $jscript;
        close $FILE;
        $self->message("Saved copy to $file");
    }
    return $jscript;
}

#
# Dynamically define data variable
#
# Converts standard hash into google data blocks (with attributes for type, name, data)
#
# Expected input hash format:
#   {'colA' => [@data_rowA],
#    'colB' => [@data_rowB],
#   ...}
#
# Return: javascript block defining var data.
####################
sub google_data {
####################
    my $self     = shift;
    my $name     = $self->{name};
    my $data     = $self->{data};       ## data as hash of column indexed values (use -order=>\@ordered_list if order is important)
    my $xaxis    = $self->{xaxis};      ## force to string as x axis... ##
    my $dataname = $self->{dataname};

    my $jscript = $self->_init_data();

    my $converted_data = $self->convert_data();    ## convert data to google blocks with type, name, data elements

    my $blocks = 0;
    my $count  = 0;
    my ( @Etypes, @Enames );

    foreach my $block (@$converted_data) {
        my %element = %$block;
        my $Ename   = $element{-name};
        if ( !defined $element{-data} ) { print "data undefined"; next; }
        my @array = @{ $element{-data} };
        my $Etype = $element{-type};
        $Etypes[$blocks] = $Etype;
        $Enames[$blocks] = $Ename;
        $blocks++;

        $count ||= int(@array);
        if ( $count && $count != int(@array) ) {
            print "*** WARNING ****\nData counts do not match\n";
            return 0;
        }
        ### Add Columns ###
        $jscript .= "\t$dataname.addColumn('$Etype','$Ename');\n";
    }

    ### Add Rows ###
    $jscript .= "\t$dataname.addRows([\n";
    foreach my $i ( 1 .. $count ) {
        my @row;
        foreach my $block ( 1 .. $blocks ) {
            my $value = $converted_data->[ $block - 1 ]->{-data}[ $i - 1 ];
            if ( $Etypes[ $block - 1 ] eq 'string' ) {
                if ( $value !~ /^[\'\"]/ ) { $value = "'$value'" }
            }
            push @row, $value;
        }
        ## Add Row ##
        $jscript .= "\n\t\t[";
        $jscript .= join ',', @row;
        $jscript .= "],";
    }
    $jscript =~ s/\,$//;    ## remove last comma ##
    $jscript .= "\t]);\n\n";

    return $jscript;
}

#
# Converts data from hash:
#
# eg { 'A' => [1,2,3], 'B' => [4,5,6], 'C' => ['Yes','No','Yes']}
#
# into data blocks for google charts
#
# eg
#   [
#      { -name=>'A', -type=>'number', -data=>[1,2,3]}
#      { -name=>'B', -type=>'number', -data=>[4,5,6] },
#      { -name=>'C', -type=>'string', -data=>['Yes','No','Yes']}
#   ]
#
######################
sub convert_data {
######################
    my $self  = shift;
    my $name  = $self->{name};
    my $data  = $self->{data};    ### hash in standard format as retrieved from Table_retrieve
    my $xaxis = $self->{xaxis};
    my $yaxis = $self->{yaxis};
    my $merge = $self->{merge};

    my $axes_defined = 0;         ## this flag shows that the user has specified the axes - otherwise, they may be automatically determined from the retrieved fields.
    if ( $xaxis && $yaxis ) { $axes_defined = 1; }

    my @keys = Cast_List( -list => $self->{order}, -to => 'ARRAY' );    # ordered list of fields to include

    my @numerical_data;
    my @string_data;
    if ( ref $data eq 'HASH' ) {
        my $hash = $data;

        if ( !@keys ) { @keys = keys %$hash }

        foreach my $key (@keys) {
            my $Etype        = 'string';
            my $keydata      = $hash->{$key};
            my $numbers_only = 0;
            my $dates_only   = 0;

            foreach my $v (@$keydata) {
                ## check for numerical fields ##

                $v ||= 0;    ## allow empty values to count as zero values (?)
                if ( $v =~ /^\d*\.?\d+$/ ) {
                    $numbers_only++;
                }
                else {
                    $numbers_only = 0;
                    last;
                }
            }
            if ( $numbers_only && ( $key ne $xaxis ) ) { $Etype = 'number' }

            my $block = {
                '-name' => $key,
                '-type' => $Etype,
                '-data' => $keydata,
            };

            if ( $Etype eq 'string' ) {
                if ( $key eq $xaxis ) { $self->message("put $key at beginning"); unshift @string_data, $block }    ## make first column
                else                  { push @string_data, $block }
            }
            else { push @numerical_data, $block }
        }
    }
    elsif ( ref $data ne 'ARRAY' ) {
        print "Problem with data type: " . ref $data;
        print HTML_Dump $data;
    }

    if ( !@string_data && $self->_string_required ) {
        $self->message("Forcing $numerical_data[0]->{-name} to string field");
        $string_data[0] = shift @numerical_data;
        $string_data[0]->{-type} = 'string';    ## assume first column retrieved is the string character if not otherwise specified ##
    }

    my @data = @string_data;

    if (@numerical_data) {
        push @data, @numerical_data;
        if ( !$self->{yaxis} ) {
            my @yaxis;
            foreach my $block (@numerical_data) {
                push @yaxis, $block->{-name};
            }
            $yaxis = join ',', @yaxis;
            $self->{yaxis} = $yaxis;
        }
    }

    # print HTML_Dump 'Original Data', \@data;
    if ( !$self->{xaxis} ) {
        ## automatically loaded - not via interface ##
        $xaxis         ||= $data[0]->{-name};
        $self->{xaxis} ||= $xaxis;

        $self->message("Automatically setting x axis as $xaxis");
        if ( int(@string_data) == 2 && int(@numerical_data) == 1 ) {
            ### merge automatically if simple case of 2 string columns + 1 count column ##
            $self->message("automatically merging $merge field");
            $merge ||= $string_data[1]->{-name};
            $self->{merge} = $merge;
        }
    }

    $self->{converted_data} = \@data;

    my @merged_data = @data;

    if ($merge) {
        @merged_data = @{ $self->merge_data() };
    }

    # print HTML_Dump 'Merged', \@merged_data;

    my $count    = int( @{ $merged_data[0]->{-data} } );    ## check number of data points
    my @new_data = ( $merged_data[0] );
    foreach my $block ( 1 .. $#merged_data ) {
        ## validate remaining data blocks ##
        if ( $merged_data[$block]->{-type} eq 'string' ) {
            if ( !$axes_defined ) { $self->message("Skipping $merged_data[$block]->{-name} (can only graph one string column)") }
            next;
        }
        elsif ( int( @{ $merged_data[$block]->{-data} } ) ne $count ) {
            $self->message("Skipping $merged_data[$block]->{-name} (data count mismatch)");
            next;
        }
        elsif ( grep /^$merged_data[$block]->{-name}$/, @{ $data->{$merge} } ) {
            $self->message("Including $merged_data[$block]->{-name} data");
            push @new_data, $merged_data[$block];    ## add validated block ##
                                                     #           $self->{yaxis_title} ||= $merged_data[$block]->{-name};
        }
        elsif ( $merge && $merged_data[$block]->{-name} =~ /\b($merge)\b/ ) {
            $self->message("Including Merged $merged_data[$block]->{-name} data");
            push @new_data, $merged_data[$block];    ## add validated block ##
        }
        elsif ( $yaxis =~ /\b$merged_data[$block]->{-name}\b/ ) {
            push @new_data, $merged_data[$block];
            $self->message("Including $merged_data[$block]->{-name} data");
        }
        else {
            if ( !$axes_defined ) {
                $self->message("Unsure how to handle $merged_data[$block]->{-name} (not in $yaxis)");
                print HTML_Dump $data->{$merge};
            }
        }
    }

    # print HTML_Dump 'Final Data', \@new_data, 'NEW';

    return \@new_data;
}

#
# Adjusts data in cases where grouping is done on secondary fields;
#
#  eg.if output is grouped on both Project and Year below...
#
#  Project = ['A','B','C','B','B','C']
#  Year    = ['2000','2000','2000','2001','2002','2002']
#  Count   = [12, 14, 45, 55, 66, 88]
#
# it needs to be converted to graphable groups:
#
#  Year = [2000, 2001, 2002]
#
#  A = [12,0,0]
#  B = [14,55,66]
#  C = [0,45,88]
#
# Return: revised data array
#############################
sub merge_data {
#############################
    my $self  = shift;
    my $data  = $self->{converted_data};
    my $merge = $self->{merge};
    my $yaxis = $self->{yaxis};
    my $xaxis = $self->{xaxis};

    if ( ( $merge eq $xaxis ) && ( $merge eq $yaxis ) ) {
        $self->message("No need to group $merge field - already included in $xaxis, $yaxis");
        $self->{merge} = '';
        return $data;
    }

    my $xaxis_index = 0;    ## = $data->[0]{-name};
    my ( $merge_index, $count_index );

    my $i = 0;
    while ( defined $data->[$i] ) {
        ## get indices in block for xaxis, yaxis & grouped data sets ##
        my ( $block_name, $block_type ) = ( $data->[$i]{-name}, $data->[$i]{-type} );

        if    ( $block_name eq $xaxis ) { $xaxis_index = $i }
        elsif ( $block_name eq $merge ) { $merge_index = $i }
        elsif ( $yaxis =~ /\b$block_name\b/ && $block_type eq 'number' ) { $count_index = $i }    ## Y-axis at least must be a number (y-axis for bar chart will be horizontal)
        $i++;
    }

    ### validate merge parameters before continuing ##
    $self->message("X: $data->[$xaxis_index]{-name} ($xaxis:$xaxis_index), M: $data->[$merge_index]{-name} ($merge:$merge_index), C: $data->[$count_index]{-name} ($yaxis:$count_index)");
    if ( !defined $xaxis_index || !defined $count_index ) {
        $self->message("Need more sophisticated logic to determine how to merge $merge field and count fields");
        print Dumper $data;
        $self->{merge} = '';
        return $data;
    }
    elsif ( !defined $merge_index ) {
        $self->message("skipping merge");
        $self->{merge} = '';
        return $data;
    }
    elsif ( $merge_index == $xaxis_index || $merge_index == $count_index ) {
        $self->message("skipping merge");
        $self->{merge} = '';
        return $data;
    }

    ## continue with merging ...##
    my $merges = unique_items( $data->[$merge_index]{-data} );    ## get unique list of grouped values (eg distinct Projects in example above)

    my @groups;
    my $index = 0;
    my %Merge;
    my $group_count = 0;
    foreach my $v ( @{ $data->[$xaxis_index]{-data} } ) {
        ## get distinct list of primary x-axis values ##
        if ( !grep /^$v$/, @groups ) {
            push @groups, $v;
            $group_count++;
        }
        my $merge_field = $data->[$merge_index]{-data}[$index];
        my $count_field = $data->[$count_index]{-data}[$index];

        if ( $Merge{$merge_field}->[ $group_count - 1 ] ) { $self->warning("Group Conflict with $merge_field + $v") }
        $Merge{$merge_field}->[ $group_count - 1 ] = $count_field;
        $index++;
    }

    my $sets = int(@groups);
    my @revised_data;

    my $xtype = $data->[$xaxis_index]{-name};
    if ( $self->_string_required ) { $xtype = 'string' }    ## force to string in this case
    my $xaxis_block = {
        '-name' => $data->[$xaxis_index]{-name},
        '-type' => $xtype,
        '-data' => \@groups
    };
    push @revised_data, $xaxis_block;                       ## start off with x-axis block in new data set ##

    foreach my $merge_field (@$merges) {
        ## add subsequent grouped field blocks ##
        my $merged_data = $Merge{$merge_field} || [];
        foreach my $i ( 1 .. $sets ) { $merged_data->[ $i - 1 ] ||= 0 }    ## set undefined values to 0

        my $merged_block = {
            '-name' => $merge_field,
            '-type' => 'number',
            '-data' => $merged_data
        };
        push @revised_data, $merged_block;
    }

    $self->{merged_data} = \@revised_data;
    return \@revised_data;
}

#
# This should probably be moved to a Views module.
#
#
# Return: block of html code on interface allowing user to enter graphing options
########################
sub options_interface {
########################
    my $self          = shift;
    my %args          = @_;
    my $fields        = $args{-fields};
    my $graph_options = $args{-graph_options};

    my @display_options = param('Graph Options');    ## retrieve display options from form

    if ($graph_options) { @display_options = @$graph_options }

    foreach my $option (@display_options) {
        foreach my $gg_option ( @{ $self->{option_list} }, @{ $self->{chart_options} } ) {
            if ( $option =~ /^\-?$gg_option:\s*(.+)/ ) {
                my $option_value = $1;
                $self->{$gg_option} = $option_value;
            }
        }
    }

    my $default_graph = param('Graph_Type')  || $self->{type}        || 'No Graph';
    my $default_x     = param('xaxis')       || $self->{xaxis}       || $fields->[0];
    my $default_y     = param('yaxis')       || $self->{yaxis}       || '';             ## defaults to all picked fields ...
    my $default_merge = param('merge')       || $self->{merge}       || '';
    my $default_xl    = param('xaxis_title') || $self->{xaxis_title} || $default_x;
    my $default_yl    = param('yaxis_title') || $self->{yaxis_title} || $default_y;

    my $graph_options = '<BR>Graphing enabled via Google Charts tools<BR>Note: <B>Chart data is cached by google for up to 2 weeks</B>' . vspace(5);

    $graph_options .= 'Graph Type: ' . radio_group( -name => 'Graph_Type', -values => [ 'No Graph', 'Pie', 'Scatter', 'Motion', 'Bar', 'Area', 'Column', 'Table' ], -default => $default_graph, -force => 1 ) . &vspace(5);

    $graph_options .= 'X axis: ' . popup_menu( -name => 'xaxis', -values => $fields, -default => $default_x, -force => 1 ) . ' label: ' . textfield( -name => 'xaxis_title', -size => '30', -default => $default_xl, -force => 1 ) . &vspace(5);

    $graph_options
        .= 'Y axis: '
        . scrolling_list( -name => 'yaxis', -values => $fields, -default => $default_y, -multiple => 2, -size => 4, -force => 1 )
        . ' label: '
        . textfield( -name => 'yaxis_title', -size => '30', -default => $default_yl, -force => 1 )
        . &vspace(5);

    $graph_options .= 'Merge Fields: ' . popup_menu( -name => 'merge', -values => [ '', @$fields ], -default => $default_merge, -force => 1 );

    $graph_options .= &vspace(10) . 'Height: ' . textfield( -name => 'height', -default => 600, -size => 8 ) . &hspace(10) . 'Width: ' . textfield( -name => 'width', default => 800, -size => 8 );

    foreach my $option ( @{ $self->{boolean_options} } ) {
        my $def = param($option) || $self->{$option};
        my $checked = boolean( $def, 1, 0 );
        $graph_options .= &vspace(5) . checkbox( -name => $option, -label => $option, -checked => $checked, -force => 1 );
    }

    return $graph_options;
}

#
# Method to parse output parameters from options_interface settings
# (Similar to set_options, but it retrieves options from the input arguments from the form)
#
# Return: sets applicable attributes as required.
################################
sub parse_output_parameters {
################################
    my $self = shift;
    my %args = @_;
    my $q    = new CGI;

    foreach my $option ( @{ $self->{chart_options} }, @{ $self->{option_list} } ) {
        my $val = $q->param($option) || $self->{$option} || $args{"-$option"};
        if ( grep /^$option$/, @{ $self->{boolean_options} } ) { $val = boolean( $val, 'true', 'false' ) }
        if ( defined $val ) {
            $self->{$option} = $val;
        }
        else {
            $self->{$option} = $self->{defaults}{$option};
        }

        #       if ( defined $self->{$option} ) { $self->message("$option = $self->{$option}") }
    }

    if ( my $order = $args{-order} ) {
        $self->{order} = $order;
    }

    return;
}

##############
sub message {
##############
    my $self    = shift;
    my $message = shift;
    my $force   = shift;

    push @{ $self->{messages} }, $message;
    if ( $force || !$self->{quiet} ) { Message($message) }

    return;
}

# Keep track of warnings if applicable ..
##############
sub warning {
##############
    my $self    = shift;
    my $message = shift;

    push @{ $self->{warnings} }, $message;
    return;
}

#
# Simple boolean test to return true / false value
#
#
# Return: boolean value
################
sub boolean {
################
    my $v     = shift;
    my $true  = shift || '1';
    my $false = shift || '0';

    my $boolean;
    if ( $v =~ /^(1|tr|on|y)/i ) {
        $boolean = $true;
    }
    else {
        $boolean = $false;
    }
    return $boolean;
}

#####################
## Private Methods ##
#####################
####################
#
#
# Return: boolean = true if chart type requires a string argument
#########################
sub _string_required {
#########################
    my $self = shift;
    my $type = $self->{type};

    my @string_required_types = ( 'PieChart', 'BarChart', 'ColumnChart', 'AreaChart', 'MotionChart' );

    if ( grep /^$type$/, @string_required_types ) {
        return 1;
    }
    else {
        return 0;
    }
}

#
# Initialize block of code to generate dynamic page with static chart generator
#
#
#
#####################
sub _initialize {
#####################
    my $self     = shift;
    my $function = $self->{function};
    my $package  = $self->{package};
    my $name     = $self->{name};

    my $jscript = <<SETUP;
<html>
  <body>
    <div id="$name"></div>
  </body>

  <head>
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load("visualization", "1", {packages:['$package']});
      google.setOnLoadCallback($function);
      
    function ${function}() {
SETUP

    return $jscript;
}

###################
sub _init_data {
###################
    my $self     = shift;
    my $dataname = $self->{dataname};

    my $jscript = <<INIT;
    // Define Data
    var $dataname = new google.visualization.DataTable();
INIT

    return $jscript;
}

# Return: javascript code to draw the given chart
##############
sub _draw {
##############
    my $self        = shift;
    my $name        = $self->{name};
    my $type        = $self->{type};
    my $dataname    = $self->{dataname};
    my $xaxis_title = $self->{xaxis_title} || $self->{xaxis} || '';
    my $yaxis_title = $self->{yaxis_title} || $self->{yaxis} || '';

    if ( $self->{type} eq 'BarChart' ) {
        ## reverse axes for bar charts ##
        my ( $xt, $yt ) = ( $yaxis_title, $xaxis_title );
        ( $xaxis_title, $yaxis_title ) = ( $xt, $yt );
    }

    my $options;
    foreach my $key ( @{ $self->{chart_options} } ) {
        my $option = $self->{$key};
        if ( $key eq 'colors' ) {
            if ($option) {
                $options .= "\t\t'$key':[" . $option . "],\n";
            }

        }
        else {
            $options .= "\t\t'$key': '$option',\n";
        }
    }

    my $axis_options;
    foreach my $key ( @{ $self->{axis_options} } ) {
        my $option = $self->{$key};
        if ( grep /^$key$/, @{ $self->{boolean_options} } ) { $option = boolean( $option, 'true', 'false' ) }
        $axis_options .= "\t$key: $option, ";
    }

    my $jscript .= <<FINISH;
        var chart = new google.visualization.$type(document.getElementById('$name'));
        chart.draw($dataname, {
	    $options
	    hAxis: {title: '$xaxis_title', titleTextStyle: {color: 'red'}},
	    vAxis: {title: '$yaxis_title', titleTextStyle: {color: 'red'}, $axis_options},	
	});
      }
FINISH

    return $jscript;
}

#
# Close section opened by _init
#
# Return: javascript code
##############
sub _close {
##############
    my $self = shift;
    my $name = $self->{name};

    my $jscript .= <<CLOSE;
    </script>
  </head>

</html>
CLOSE

    return $jscript;
}

return 1;

