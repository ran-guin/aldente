##########################
#
# This module is used to simplify and standardize the formation of html tables
#
# Methods exist to include data one row at a time (Set_Row) , or one column at a time (Set_Column).
#
# Headers, settings, colours can also be specified using internal methods.
#
# Generated html file may be printout out automatically, returned via a string, or saved as a file.
# Links may also be provided for 'printable' version of table.
#
###########################
package HTML_Table;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

HTML_Table.pm - This module is used to simplify and standardize the formation of html tables 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module is used to simplify and standardize the formation of html tables <BR>Methods exist to include data one row at a time (Set_Row) , or one column at a time (Set_Column).<BR>Headers, settings, colours can also be specified using internal methods.<BR>Generated html file may be printout out automatically, returned via a string, or saved as a file.<BR>

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
use Data::Dumper;
use strict;

##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;  ## qw(filter_input Show_Tool_Tip);
use RGTools::Web_Form;

##############################
# global_vars                #
##############################
use vars qw($scanner_mode);    ### optional global giving smaller display size...
use vars qw($class_size);

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

### Default Colour Scheme ###
my $main_title = 'vdarkbluebw';
my $button = 'lightblue';
my $header_colour = '#ace'; # '#99ccff';
my $header_colour2 = '#ccccff';
my $line_colour_1 = '#ddddda';
my $line_colour_2 = '#eeeee8';
my $background_colour    = '#444444';

############
sub new {
############
    my $this = shift;
    my %args = @_;

    my $size_class = $args{-size}   || $args{-class};
    my $colour     = $args{-colour} || '';
    my $border     = $args{-border} || 0;
    my $title      = $args{-title};
    my $headers           = $args{-headers};
    my $footer           = $args{-footer};	#(array_ref) array of hashes, each array element determines row order, each element has a hash consisiting on another array and a class name for style
    my $width             = $args{-width} || 0;
    my $align             = $args{-align};
    my $padding           = defined $args{-padding} ? $args{-padding} : 5;
    my $autosort          = $args{-autosort};                                # (Scalar) Flags all columns as sortable
    my $autosort_columns  = $args{-autosort_columns} || undef;               # (ArrayRef) Array of columns that will be flagged as sortable. Counting starts at 0.
    my $autosort_end_skip = $args{-autosort_end_skip};                       # (Scalar) Number of rows to skip from the end of the table
    my $scrollable_body = $args{-scrollable_body} || 0;                       # Allows table body to scroll while header is fixed (over flow enabled)
    my $sortable          = $args{-sortable};
    my $bgcolour          = $args{-bgcolour};
    my $table_id          = $args{-id} || int(rand(1000000));
    my $style  = $args{-style};   ## style setting eg -style => 'width:100%' - allows for more up-to-date css specifications .. should expand for row / cell settings as well... 
    my $nowrap            = $args{-nowrap};
    my $table_class         = $args{-table_class};   ## flag to use dataTable class (separate pages and includes search field) 
    my $debug             = $args{-debug};
    my $cell_style        = $args{-cell_style} || "padding:${padding}px; ";

    my $toggle = 1;
    $toggle = $args{-toggle} if ( defined $args{-toggle} );
    my $add_empty_cells = 1;
    $add_empty_cells = $args{-add_empty_cells} if ( defined $args{-add_empty_cells} );    # (Scalar) Flag to enable or disable the addition of empty cells even if there is no text

    my $self = {};
    my ($class) = ref($this) || $this;
    bless $self, $class;

    $self->{title}         = $title || "";
    $self->{sub_titles}    = 0;
    $self->{columns}       = 0;
    $self->{rows}          = 0;
    $self->{headers}       = [];
    $self->{footer}       = [];
    $self->{header_labels} = [];
    $self->{header_info} = {};
    $self->{Hclass}        = [];
    $self->{Cwidth}        = [];
    $self->{toggle_colour} = $toggle;
    $self->{links}         = 0;
    $self->{common_class}  = '';             ### leave off by default.
    $self->{LINK_type}     = [];
    $self->{LINK_name}     = [];
    $self->{LINK_value}    = [];
    $self->{LINK_label}    = [];
    $self->{LINK_spec}     = [];

    $self->{IDs}             = [];
    $self->{row_IDs}         = [];
    $self->{add_empty_cells} = $add_empty_cells;

    ### Print Options ###

    $self->{global_cell_style}  = $cell_style;
    $self->{align}       = [];
    $self->{valign}      = [];
    $self->{Table_align} = "align='$align'" if $align;
    $self->{table_align} = "align='left'";
    $self->{table_id}    = $table_id;
    $self->{table_id_track} = $table_id if $table_id;
    $self->{frame}             = "";
    $self->{padding}           = "cellpadding='$padding'";
    $self->{spacing}           = "cellspacing='0'";
    $self->{border}            = "border='0'";
    $self->{margin}            = "leftmargin='50'";
    $self->{width}             = $width;
    $self->{autosort}          = $autosort;
    $self->{autosort_columns}  = $autosort_columns;
    $self->{autosort_end_skip} = $autosort_end_skip;
    $self->{scrollable_body} = $scrollable_body;
    $self->{table_class} = $table_class;
    
    if ($style) { $self->Set_Style($style) }

    # flag to turn on column span. This is defaulted to 0, but gets set to 1 once a -colspans argument is set in Set_Row
    $self->{colspan_def} = 0;

    #### 'scanner_mode' specific settings...
    if ($scanner_mode) {
        $width ||= 200;
    }
    else {
        $self->{width} = "Width=$width";
    }
    
    $self->{Tclass} = "class='$main_title'";    ### title class ######

    #   $self->{Tclass} = "bgcolor = '#0000cc'";  	### title colour ######
    $self->{button_colour} = "lightblue";       ### button colour ######

    $self->{Hcolour} = "bgcolor='$header_colour'";     ### Header Colour (dark blue) #####
    $self->{Hcolour2} = "bgcolor='$header_colour2'";
    if ( !$bgcolour ) {
        $self->{Lcolour}  = "bgcolor='$line_colour_1'";    ### Line Colour 1  (darker grey) #####
                                                    #$self->{Lcolour} =  "bgcolor='#d8d8d8'";  	### Line Colour 1  (grey) #####
        $self->{Lcolour2} = "bgcolor='$line_colour_2'";    ### Line Colour 2  (lighter grey) #####
                                                    #$self->{Lcolour2} = "bgcolor='#ffffCC'";  	### Line Colour 2  (light yellow) #####
    }
    elsif ( $bgcolour ne 'transparent' ) {
        $self->{Lcolour}  = "bgcolor='$bgcolour'";    ### Line Colour 1
        $self->{Lcolour2} = "bgcolor='$bgcolour'";    ### Line Colour 2
    }

    $self->{nowrap} = $nowrap;

    #$self->{Hcolour} = "bgcolor='#eeeefe'";    ### Header Colour #####
    #$self->{Lcolour} = "bgcolor='#eeeede'";  	### Line Colour 1 #####
    #$self->{Lcolour2} = "bgcolor='#eeeeee'";  	### Line Colour 2 #####

    if ($colour)     { $self->Set_Line_Colour($colour) }
    if ($size_class) { $self->Set_Class($size_class) }
    if ($border)     { $self->Set_Border($border) }
    if ($headers)    { $self->Set_Headers($headers) }

    if ($sortable)   { 
	$self->{sortable} = 1;
	$self->init_sortable(-table_id => $table_id); 
    }

    return $self;
}

##############################
# public_methods             #
##############################

sub rows {
    my $self = shift;
    return $self->{rows};
}

sub columns {
    my $self = shift;
    return $self->{columns};
}



#############
#
# Assign a unique ID to the table
#
#############
sub Set_Table_ID {
#############
    my $self = shift;
    my $id   = shift;

    $self->{table_id} = $id;
}
#############
#
# Define header (allows passing of css / js in header)
#
#############
sub Set_Header {
#############
    my $self   = shift;
    my $header = shift;

    $self->{header} = $header;
}
############
#
# Specify a header that is to be included prior to the table
#
#############
sub Set_Prefix {
#############
    my $self   = shift;
    my $prefix = shift;

    $self->{prefix} = $prefix;
}

##################################
#
# Specify autosorting
#
##################################
sub Set_Autosort {
##################################
    my $self = shift;
    my $sort = shift;

    if ( !$sort || ( $sort =~ /^off$/i ) ) {
        $self->{autosort} = 0;
    }
    else {
        $self->{autosort} = 1;
    }
}

##################################
#
# Specify autosorting
#
##################################
sub Set_Autosort_Columns {
##################################
    my $self = shift;
    my $columns = shift;

    my @columns = Cast_List( -list => $columns, -to => 'array' );
    
    push @{ $self->{autosort_columns} }, @columns;
}

##################################
#
# Specify autosorting
#
##################################
sub Set_Autosort_End_Skip {
##################################
    my $self          = shift;
    my $sort_end_skip = shift;

    $self->{autosort_end_skip} = $sort_end_skip;
}

################
#
# Specify additional information that is to follow the table
#
#############
sub Set_Suffix {
#############
    my $self   = shift;
    my $suffix = shift;

    $self->{suffix} = $suffix;
}

#####################
#
#
#
#
##################
sub Set_HTML_Header {
##################
    my $self   = shift;
    my $header = shift;

    $self->{HTML_header} = $header;
}

#
# Specify a class for the headers
#
##################
sub Set_Header_Class {
##################
    my $self   = shift;
    my $Hclass = shift;
    my $column = shift;

    if ($column) {
        $self->{Hclass}[ $column - 1 ] = "class='$Hclass'";
    }
    else {
        foreach my $column ( 1 .. $self->{columns} ) {
            $self->{Hclass}[ $column - 1 ] = "class='$Hclass'";
        }
    }
    return 1;
}

#
# Set colour for buttons that are generated within the table
#
#
###################
sub Set_Button_Colour {
###################
    my $self = shift;
    $self->{button_colour} = shift;    ### button colour ######width
    return 1;
}

#
# Specify the column widths within the table
#
###########################
sub Set_Column_Widths {
###########################
    my $self    = shift;
    my $widths  = shift;
    my $columns = shift;

    my @width_specs  = @$widths;
    my $column_specs = scalar(@width_specs);

    my @column_index;
    if ($columns) {
        @column_index = @$columns;    ######## map to specified columns ########
    }
    else {
        @column_index = map { $_ - 1 } ( 1 .. $column_specs );
    }
    foreach my $index ( 1 .. $self->{columns} ) {
        unless ( defined $self->{Cwidth}[ $index - 1 ] ) {
            $self->{Cwidth}[ $index - 1 ] = "width='1' ";
        }
    }

    foreach my $index ( 1 .. $column_specs ) {
        $self->{Cwidth}[ $column_index[ $index - 1 ] ] = "width='" . $width_specs[ $index - 1 ] . "'";
    }

    return 1;
}

#
# Define the body font
#
############
sub Set_Font {
############
    my $self = shift;
    my $font = shift;

    $self->{Font} .= " $font";
    $self->{TFont} = $self->{Font};

    return 1;
}

#
# Define the body cells' styles 
#
#####################
sub Set_Cell_Style {
#####################
    my $self      = shift;
    my $style = shift;
    my %args = @_;
    my $row       = $args{-row};
    my $col       = $args{-column};

    if ($col && $row) {
        ## single cell specification ##
        $self->{cell_style}{"($row,$col)"} = " style='$style'";
    }
    elsif ($col) {
        foreach my $i (1..$self->{rows}) {
            $self->{cell_style}{"($i,$col)"} = " style='$style'";
        }
    }
    elsif ($row) {
        foreach my $i (1..$self->{columns}) {
            $self->{cell_style}{"($row,$i)"} = " style='$style'";
        }
    }
    else {
        foreach my $i (1..$self->{rows}) {
            foreach my $j (1..$self->{columns}) {
                $self->{cell_style}{"($i,$j)"} = " style='$style'";
            }
        }
    }

    return 1;    
}
#
# Define the body cells' styles 
#
#####################
sub Set_Row_Style {
#####################
    my $self      = shift;
    my $style = shift;
    my %args = @_;
    my $row  = $args{-row} || shift;

    if ($row) {
        ## single cell specification ##
        $self->{row_style}{"($row)"} = " style='$style'";
    }
    else {
        foreach my $i (1..$self->{rows}) {
                $self->{row_style}{"($i)"} = " style='$style'";
        }
    }

    return 1;    
}

#
# Define the body class
#
############
sub Set_Class {
#############
    #
    my $self      = shift;
    my $thisclass = shift;

    $self->{common_class} = "class='$thisclass'";

    return 1;
}

#
# Define the body style - more powerful css specs
#
############
sub Set_Style {
#############
    #
    my $self      = shift;
    my $this_style = shift;

    $self->{style} .= "$this_style; ";

    return 1;
}

##############
sub Set_Padding {
##############
    #
    # set table padding
    #
    my $self = shift;
    my $pad  = shift;
    $self->{padding} = "cellpadding='$pad'";
    return 1;
}

##############
sub Set_Spacing {
###############
    # set table padding
    #
    my $self    = shift;
    my $spacing = shift;
    $self->{spacing} = "cellspacing='$spacing'";
    return 1;
}

#############
sub Set_Border {
#############
    #
    # Set table border
    #
    my $self   = shift;
    my $border = shift;
    $self->{border} = "border='$border'";
    return 1;
}

#############
sub Set_Width {
#############
    #
    # Set table width
    #
    my $self  = shift;
    my $width = shift;
    $self->{width} = "Width='$width'";
    return 1;
}

#####################
sub Set_Table_Alignment {
#####################
    #
    # Set table alignment
    #
    my $self      = shift;
    my $alignment = shift;

    $self->{table_align} = "align='$alignment'";
    return 1;
}

################
sub Set_Alignment {
################
    #
    # Set alignment for a specific column
    #
    my $self      = shift;
    my $alignment = shift;
    my $column    = shift;

    if ($column) {
        $self->{align}[ $column - 1 ] = "align='$alignment'";
    }
    else {
        foreach my $column ( 1 .. $self->{columns} ) {
            $self->{align}[ $column - 1 ] = "align='$alignment'";
        }
    }
    return 1;
}

#################
sub Set_VAlignment {
#################
    #
    # Set alignment for a specific column
    #
    my $self       = shift;
    my $valignment = shift;
    my $column     = shift;

    if ($column) {
        $self->{valign}[ $column - 1 ] = "valign='$valignment'";
    }
    else {
        foreach my $column ( 1 .. $self->{columns} ) {
            $self->{valign}[ $column - 1 ] = "valign='$valignment'";
        }
    }
    return 1;
}

#######################
sub Toggle_Colour {
#######################
    #
    # specify colour toggling (default = 1)
    #
    my $self   = shift;
    my $toggle = shift;

    if   ( $toggle =~ /off/i ) { $toggle = 0; }
    else                       { $toggle = 1; }

    $self->{toggle_colour} = $toggle;
    return 1;
}

#######################
sub toggle {
#######################
    #
    # toggle the colour
    #
    my $self = shift;

    ( $self->{Lcolour}, $self->{Lcolour2} ) = ( $self->{Lcolour2}, $self->{Lcolour} );

    return 1;
}

#######################
sub Toggle_Colour_on_Column {
#######################
    #
    # specify colour toggling to occur when a particular column changes...
    #
    my $self   = shift;
    my $column = shift;

    if ($column =~/^\d+$/) { 
        $self->{toggle_colour_on_column_number} = $column; 
    }
    else {
       $self->{toggle_colour_on_column} = $column;
   }
    
    return 1;
}

###########################
sub Set_Header_Colour {
###########################
    my $self   = shift;
    my $colour = shift;

    if ( $colour =~ /=/ ) {
        $self->{Hcolour} = $colour;
    }
    else {
        $self->{Hcolour} = "bgcolor='$colour'";
    }

}

#########################
sub Set_Line_Colour {
#########################
    #
    # define default line colour(s) (for colour toggling)
    #
    my $self    = shift;
    my $colour1 = shift;
    my $colour2 = shift || $colour1;

    if ($colour1) { $self->{Lcolour}  = "bgcolor='$colour1'"; }
    if ($colour2) { $self->{Lcolour2} = "bgcolor='$colour2'"; }
    return 1;
}

#############
sub Set_Title {
#############
    #
    # Set Table Title
    #
    my $self = shift;
    $self->{title} = shift;
    my %args = @_;

    my $class    = $args{class} || 'table-heading';       ### <td class=...>
    my $bgcolour = $args{bgcolour};    ### <td bgcolour=...>
    my $fclass   = $args{fclass};      ### <font class=...>
    my $fcolour  = $args{fcolour};     ### <font colour=...>
    my $fsize    = $args{fsize};       ### <font size=...>
    my $fstyle   = $args{fstyle};      ### <b>,<i>, or <u> ...... in a comma-delimited list.

    if ($fsize) { $self->{Tfont} .= "size='$fsize' " }
    if ($class) {
        $self->{Tclass} = "class='$class' ";    ### title class ######
    }
    elsif ( $bgcolour || $fclass || $fcolour || $fsize ) {

        #$self->{Tclass} = '';                ### Do not use css if bgcolour, colour or size is provided.
        if ($bgcolour) { $self->{Tclass} = "bgcolor='$bgcolour' " }
        if ($fclass) { $self->{Tfont} .= "class='$fclass' " }
        elsif ( $fcolour || $fsize ) {
            if ($fcolour) { $self->{Tfont} .= "color='$fcolour' " }
            if ($fsize)   { $self->{Tfont} .= "size='$fsize' " }
        }
        if ($fstyle) {
            foreach my $s ( split /,/, $fstyle ) {
                $s =~ /^([a-zA-z]{1}).*/;
                $self->{Tstyle} .= "<$1>";
            }
        }
    }
    return 1;
}

################
sub Set_sub_title {
################
    #
    # Set Table Sub-Title
    #
    my $self = shift;
    $self->{sub_title}[ $self->{sub_titles} ] = shift;
    my $span = shift;
    my $colour = shift || 'vlightblue';

    $span ||= 1;
    $self->{sub_title_span}[ $self->{sub_titles} ] = $span;

    if ($colour) {
        unless ( $colour =~ /=/ ) { $colour = "class='$colour'"; }

        $self->{STcolour}[ $self->{sub_titles} ] = $colour;
    }

    $self->{sub_titles}++;
    return 1;
}

################
sub Set_sub_header {
################
    #
    # Specify sub header (anywhere in table - full columnspan)
    #
    my $self       = shift;
    my $sub_header = shift;
    my $colour     = shift;
    my $spec       = shift;

    $self->{rows}++;
    my $row = $self->{rows};
    $self->{columns} ||= 1;    ## set to single column if still empty.
    $self->{C0}[ $row - 1 ] = $sub_header;

    if ( defined $colour ) {
        unless ( $colour =~ /=/ ) { $colour = "class='$colour'"; }
        $self->{colour}[ $row - 1 ] = $colour;
    }
    if ( defined $spec ) {
        $self->{row_spec}[ $row - 1 ] = $spec;
    }
    $self->{row_type}[ $row - 1 ] = 'heading';
    my $fback = $self->{C0}[ $row - 1 ];
    return 1;
}

################
sub set_footer {
################
	#
	# Specify footer
	#
	my $self       = shift;
	my $footer = shift;

	$self->{footer} = $footer;
	return 1;
}


#################
#
# Helper function for the constructor; adds jquery code to activate sortable rows
#
#################
sub init_sortable {
#################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $table_id = $args{-table_id};

    if (!defined($table_id)) {
    	my $randnum = rand();

    	# get the 8 least significant digits
    	$randnum = substr( $randnum, -8 );
    	$table_id = "sortable".$randnum;

    	$self->Set_Table_ID($table_id);
    }

    my $jq = 'jQuery';
    my $header = "<script type=\"text/javascript\"> $jq(function(){ $jq(\"#$table_id\").sortable({ items: \"tr.sortable\" }); }) </script>";

    $self->Set_Header($header);

}


##########################
sub init_table {
##########################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'title,right,class' );

    my $title   = $args{-title};
    my $right   = $args{-right};
    my $class   = $args{-class} || 'small';
    my $width   = $args{-width} || '100%';
    my $toggle  = $args{ -toggle } || 'off';
    my $colour  = $args{-colour} || $line_colour_1;
    my $colour2 = $args{-colour2} || $line_colour_2;
    my $sortable_rows = $args{-sortable_rows} || 0; 

    my $table = HTML_Table->new();

    $table->Set_Class($class);
    $table->Set_Width($width);
    $table->Toggle_Colour($toggle);
    $table->Set_Line_Colour( $colour, $colour2 );

    $title = "<table border=0 cellspacing=0 cellpadding=0 width=100%><tr><td><font size='-1'><B>$title</B></font></td><td align=right class=$class>$right</td></tr></table>" if $title;

    $table->Set_Title(
        $title,
        bgcolour => $header_colour2,
        fclass   => 'small',
        fstyle   => 'bold'
    ) if $title;

    return $table;
}



#################
sub Set_Link {
#################
    #
    # Specify form elements within table
    #
    my $self = shift;

    my %args;
    $args{-type}    = shift;
    $args{-name}    = shift;
    $args{-value}   = shift;
    $args{-label}   = shift;
    $args{-spec}    = shift;
    $args{-tip}     = shift;
    $args{-disable} = shift;

    $self->{LINK_type}[ $self->{links} ]     = $args{-type};
    $self->{LINK_name}[ $self->{links} ]     = $args{-name};
    $self->{LINK_value}[ $self->{links} ]    = $args{-value};
    $self->{LINK_label}[ $self->{links} ]    = $args{-label};
    $self->{LINK_spec}[ $self->{links} ]     = $args{-spec};
    $self->{LINK_tip}[ $self->{links} ]      = $args{-tip};
    $self->{LINK_disabled}[ $self->{links} ] = $args{-disable};

    $self->{links}++;
    return 1;
}

###################
sub Set_Column {
###################
    #
    # specify array of column values
    #
    my $self       = shift;
    my %args       = &filter_input( \@_, -args => 'values,column' );
    my $value_list = $args{ -values };
    my $column     = $args{-column};
    my $skip       = $args{-skip_rows} || 0;

    my @values = @$value_list;

    my $index = $self->{columns};
    $self->{columns}++;

    if ($column) {
        $self->{header_labels}[$index] = $column;
        $index = $column;
    }
    $self->{headers}[$index] = "C" . $index;

    my $num = scalar(@values);
    if ( $num + $skip > $self->{rows} ) {
        $self->{rows} = $num + $skip;
    }    ## increase number of rows if needed.

    foreach my $row ( 1 .. $num ) {
        $self->{"C$index"}[ $row + $skip - 1 ] = $values[ $row - 1 ];
    }
    return 1;
}

#
#
###############
sub Set_Headers {
###############
    #
    # Specify array of Header text values
    #
    my $self         = shift;
    my %args = filter_input(\@_, -args=>'list,class');
    my $header_list  = $args{-list};
    my $column_class = $args{-class} || 'table-subheading';
    my $paste_columns = $args{-paste_columns};             ## allow option to paste text area to columns (requires structured column names)  NOTE: MUST BE CALLED AFTER COLUMNS ADDED    
    my $paste_source = $args{-paste_area} || 'PasteArea';  ## form element containing text to be pasted to table
    my $paste_img = $args{-paste_icon} || 'paste';                    ##  || "/SDB_rguin/images/icons/paste.png"... OR simply supply icon name (eg -paste_icon -> 'paste') ... (accessing std Font Awesome icons)
    my $clear_img = $args{-clear_icon} || 'eraser';                    ##  || "/SDB_rguin/images/icons/paste.png"... OR simply supply icon name (eg -clear_icon -> 'eraser') ... (accessing std Font Awesome icons)
    my $tooltip_list = $args{-tooltips};  
    my $paste_reference    = $args{-paste_reference};                  ## 'name' or 'id' to automatically reference element names / ids  
    my $space_words        = $args{-space_words};          ## change Underscore_Separated_Words => 'Underscore Separated Words' in headers (allows column wrap at the same time) ##
    
    my @headers = @$header_list;
    my @tooltips = Cast_List(-list=>$tooltip_list, -to=>'array');
#    my @tooltips =  @$tooltip_list if $tooltip_list;  ## revert to BP above... 
       
    my $index   = 0;
    
    my @trimmed_headers;
    foreach my $header (@headers) {
        my $trimmed_header = _strip_tags($header);
        if ($space_words) { $header =~s/\_/ /g }
        
         push @trimmed_headers, $trimmed_header;
         
        $self->{header_info}{$trimmed_header}{description} = $tooltips[$index] if $tooltip_list;
        $self->{header_labels}[$index++] = $header;
    }
    
    if ($paste_reference) {
        ## not array reference... simply make all columns paste_columns...
        $paste_columns = [0..$#headers];
    }

    #    $self->{columns}=$index;
    if ($column_class) {
        unless ( $column_class =~ /=/ ) {
            $column_class = "class='$column_class'";
        }

        foreach my $column ( 1 .. $index ) {
            $self->{Hclass}[ $column - 1 ] = $column_class;
        }
    }
    
    if ($paste_columns && $paste_source) {
         ## optional list of columns which can be 'pasted' into using a text area (specified in a separate variable)
         ## this is designed for entry forms in which users may wish to paste excel data into a column of an html form

         $paste_reference ||= 'id';  ## default to use ids 
         $self->{paste_area} = $paste_source;
         
         foreach my $i (0 .. $#headers) {       
            if ( ! grep /^$i/, @$paste_columns) { next }
            
            my ($elements, $triggers) = $self->get_elements(-column=>$i, -type=>$paste_reference, -ignore=>'^ForceSearch', -distinct=>1);
            my $reference_elements = join ',', @$elements;
            
            if (!$reference_elements) { next }
            
            my $extra = $triggers->[0];  ## note triggers that should normally be executed when these values are normally changed... ignore for now...
            
            my $onclick = "\nPasteColumn(this.form, '$paste_source', '$reference_elements'); return false;\n";  ## javascript call to populate information from paste_source into the supplied list of form elements in this column
            my $clr     = "\nPasteColumn(this.form, 'ClearColumn', '$reference_elements'); return false;\n";
            
            my ($clear, $button);
            
            my $instructions = "Click here to paste data from Cut / Paste Area into the rows below for this column";
            
            use LampLite::Bootstrap;
            my $BS = new Bootstrap();
            
            if ($paste_img) {
                ## supply paste image for triggering javascript - should be nicer than radio button ##
                if ($paste_img =~ /[\/\.]/) {
                    ## explicit image file supplied ##
                    $button = RGTools::Web_Form::Button_Image( -onClick => $onclick, -height=>20, -src => $paste_img, -alt=>'Paste');
                }
                else {
                    ## simple icon name supplied ##
                    require LampLite::Bootstrap;
                    my $BS = new Bootstrap();
                    $button = $BS->button(-icon=>$paste_img, -onclick=>$onclick, -tooltip=>'Paste into columns below');
                }
                
                    # #Show_Tool_Tip( , $instructions);
            } 
            else {
                ## if no paste image supplied, just use a radio button with tooltip indicating action ##
                $button = Show_Tool_Tip(
                        radio_group(-name=>'paste', -values=>['Paste'],  -onClick=>$onclick),
                        $instructions);
            } 
        
            if ($clear_img) {
                if ($clear_img =~ /[\/\.]/) {
                    ## explicit image file supplied ##
                    $clear = RGTools::Web_Form::Button_Image( -onClick => $clr, -height=>20, -src => $clear_img, -alt=>'Clear');
                }
                else {
                    ## simple icon name supplied ##
                    require LampLite::Bootstrap;
                    my $BS = new Bootstrap();
                    $clear = $BS->button(-icon=>$clear_img, -onclick=>$clr, -tooltip=>'Clear columns below');
                }
            }
            else {
                $clear = Show_Tool_Tip(
                            radio_group(-name=>'clear', -values=>['Clr'], -onClick=>$clr), 'clear column');
            }
            $self->{header_labels}[$i] .= '<BR>' . $button . $clear;  ## add 'paste' button to column heading cell    
        }
        
        my $cleared = "\n";
        if ($self->{rows} > 1) {
            foreach my $j (2..$self->{rows}) { $cleared .= "''\n" } 
        }
        
        $self->{header_labels}[0] .= hidden(-name=>'ClearColumn', -value=>$cleared);
    }
    
    return 1;
}

#########################
sub get_elements {
#########################
    my $self = shift;
    my %args = filter_input(\@_);
    
    my $column = $args{-column};
    my $type = $args{-type};
    my $distinct = $args{-distinct};
    my $ignore = $args{-ignore};
    
    my @applicable_elements = qw(select input);  # order preference given to select in case of search text fields prior in conjunction with dropdown lists #
    
    my (@elements, @triggers);
    foreach my $row (1..$self->{rows}) {
        my $cell = $self->{"C$column"}[ $row - 1 ];
        
        foreach my $element_type (@applicable_elements) {
            if ($cell =~/<($element_type)\b(.+?)\/($element_type|)>/xms) {
                my $input = $2;
                my @options;
                if ( $input =~/ $type=[\'\"](.+?)[\'\"]/xms ) {
                    my $element = $1;

                    if ($element =~ /$ignore/) { 
                        ## allow option to ignore a specific field name (?) ##
                    }
                    else {
                        ## possibly keep track of change events normally executed on this element (?) ##
                        if (0) {
                            ## ignore this functionality for now... ##
                            if ($input =~/ (onchange|onblur)=[\"](.+?)[\"]/xms) {
                                my $trigger = $2;

                                ## substitute target element execution as required on the text field ... 
                                # $trigger =~s/\bthis.id/$target_id/g;
                                # $trigger =~s/\bthis,/$target_element,/g;

                                ## ... or trigger dropdown execution for full column first (?), and run this on the LAST element found (eg the dropdown)

                                if (!$distinct || ! grep/^$trigger$/, @triggers) { push @triggers, $trigger }
                            } 
                            else { 
                                if (!$distinct || ! grep/^$/, @triggers) { push @triggers, '' }
                            }
                        }
                        if (!$distinct || ! grep/^$element$/, @elements) { push @elements, $element}; 
                        last; 
                    }
                }
                else {
                    Message("NO $type IN $input");
                }
            }
        }

    }
    return \@elements, \@triggers;
}

######################
sub set_header_info {
######################
    #
    # Specify hash of additional Header information
    #
    my $self         = shift;    
    my $header_info = shift;
    
	$self->{header_info} = $header_info;

    return 1;
}

#################
sub Add_Header {
#################
    my $self   = shift;
    my $header = shift;
    my $index  = shift;

    my $index ||= int( @{ $self->{header_labels} } );

    $self->{header_labels}[ $index++ ] = $header;

    return 1;
}

######################################################################
# Subroutine that allows loading a table from a hash
# return: a reference to the hash (sorted if -sort_by option is true)
####################
sub Load_From_Hash {
#################
    my $self      = shift;
    my %args      = @_;
    my $headers   = $args{-headers};         # (Arrayref) ordered list of column headers
    my $info      = $args{ - data };         # (Hashref), with keys as the column headers, and values as an arrayref of values for the rows
    my $form_name = $args{ - form_name };    # (String) the name of the form that the table resides (needed for sorting)
    my $sort_by   = $args{-sort_by};         # (String) the header to sort the hash by
    my $order     = $args{-order};           # (String) sort order. One of 'asc' or 'desc'

    # get size of rows
    my @first_array = values( %{$info} );
    my $size        = scalar( @{ $first_array[0] } );

    # freeze the hash and the header array
    print &RGTools::RGIO::Safe_Freeze(
        -name   => "html_table_headers",
        -value  => $headers,
        -format => "hidden",
        -encode => 1
    );
    print &RGTools::RGIO::Safe_Freeze(
        -name   => "html_table_hash",
        -value  => $info,
        -format => "hidden",
        -encode => 1
    );

    print "<input type='hidden' name='Sort_Column' id='Sort_Column'/>";
    print "<input type='hidden' name='Order_By' id='Order_By'/>";

    # modify header names with links
    my @submit_headers = ();
    my $header_index = 0;
    my @cols;
    foreach my $header (@$headers) {
        push @submit_headers, $header;
        push @cols, $header_index;
        $header_index++;
    }

    $self->Set_Autosort_Columns(\@cols);

    ### Sort algorithm
    # put everything that needs to be sorted into a convenient hash
    my %sort_hash;
    my $has_letters = 0;
    foreach my $index ( 1 .. $size ) {
        my $value = $info->{$sort_by}[ $index - 1 ];
        $sort_hash{ $index - 1 } = $value;
        $has_letters = 1 if ( ( !($has_letters) ) && ( $value !~ /\d+/ ) );
    }

    # sort the hash by value
    my @sorted_keys = ();
    my $sort_func;

    # sort lexicographically if anything has letters in the values of the hash
    if ($has_letters) {
        if ( $order eq 'desc' ) {
            $sort_func = sub { $sort_hash{$b} cmp $sort_hash{$a} };
        }
        else {
            $sort_func = sub { $sort_hash{$a} cmp $sort_hash{$b} };
        }
    }
    else {
        if ( $order eq 'desc' ) {
            $sort_func = sub { $sort_hash{$b} <=> $sort_hash{$a} };
        }
        else {
            $sort_func = sub { $sort_hash{$a} <=> $sort_hash{$b} };
        }
    }
    foreach my $key ( sort $sort_func ( keys(%sort_hash) ) ) {
        push( @sorted_keys, $key );
    }

    # sort everything else using the sorted array keys as a slice
    foreach my $header ( @{$headers} ) {
        @{ $info->{$header} } = @{ $info->{$header} }[@sorted_keys];
    }

    # set headers
    $self->Set_Headers( \@submit_headers );

    # set data
    foreach my $index ( 1 .. $size ) {
        my $row = [];
        foreach my $header (@$headers) {
            push( @{$row}, $info->{$header}[ $index - 1 ] );
        }
        $self->Set_Row($row);
    }
}

#################
sub Set_Row {
#################
    #
    # Specify array of Row values
    #
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'value_list,colour,spec,toggle,repeat,colspans'); ## , -mandatory => 'value_list' );
    my $value_list  = $args{-value_list};
    my $colour      = $args{-colour};
    my $spec        = $args{-spec};
    my $toggle      = $args{'-toggle'};                                                                ## allow user to set the bgcolor of the row to the same color as the previous row
    my $repeat      = $args{-repeat} || 0;                                                             ## allow user to repeat the current row
    my $no_tool_tip = $args{'-no_tool_tip'};                                                           ## prevent the "Remove this Row" and "Duplicate This row" tooltips from showing up
    my $clone_index = $args{-clone_index};
    my $colspans    = $args{'-colspans'};                                                              # (ArrayRef) [Optional] For each cell in this row, define its column span. If not defined, defaults to 1 per cell.
    my $type        = $args{-type} || 'data';   ## allow rows to be defined as comment or heading rows (defaults to 'data' to keep track of actual data rows for statistics
    my $element_id  = $args{-element_id};       ## optional element id to enable hiding of row
    my $sortable    = $args{-sortable} || 1;    ## makes row dynamically sortable (jquery) 

    my $name = $args{-name};
    my $style = $args{-style};
    my $class = $args{-class};
    
    if ($style) { $spec .= " style='$style' "}
    if ($class) { $spec .= " class='$class' "}
    if ($name) { $spec .= " name='$name' " }
    if ($element_id) { $spec .= " id='$element_id' " }

    my @values  = @$value_list;
    my $columns = scalar(@values);
    if ($repeat) {
        $columns++;
    }

    if ($colspans) {
        $self->{colspan_def} = 1 if ( !$self->{colspan_def} );
    }

    if ( $self->{columns} < $columns ) { $self->{columns} = $columns; }

    #    if (!$row) {
    my $row = $self->{rows} + 1;

    #}
    my $column = 0;

    foreach my $value (@values) {
        ### if no headers... set headers to column index ###
        if ( !$self->{headers}[$column] ) {
            $self->{headers}[$column] = "C$column";
        }
        $self->{"C$column"}[ $row - 1 ] = $value;

        # store column spans
        if ($colspans) {
            $self->{'colspan'}{ "($row," . ( $column + 1 ) . ")" } = $colspans->[$column];
        }
        else {
            $self->{'colspan'}{ "($row," . ( $column + 1 ) . ")" } = 1;
        }

        $column++;
    }

    ## <CONSTRUCTION> - this is way to customized to be in this module - any way of removing the local dependencies ?? ## <CUSTOM>
    if ($repeat) {
        my $A_highlight = "lightgreen";
        my $R_highlight = "yellow";
        my $ci          = $clone_index || $row;
        $self->{row_attr}[ $row - 1 ] .= " clone_index = $ci";    ### use specified clone index if given
        $self->{clone_index}{$row} = $row;                        ### keep track of the row indices if they exist.

        use LampLite::Bootstrap;
        my $BS = new Bootstrap();
        
        my $button_size = 12;
        if ($no_tool_tip) {
            $self->{"C$column"}[ $row - 1 ] = $BS->button(-icon=>'plus', -onclick=>"cloneRow(this); return false; ") .$BS->button(-icon=>'minus', -onclick=>"removeRow(this); return false; ");
            
            my $old1 = &RGTools::Web_Form::Submit_Image(
                -src     => '/SDB/images/icons/plus.gif',
                -name    => 'Add',
                -onClick => 'cloneRow(this);return false;',
                -width   => $button_size,
                -height  => $button_size
                )
                . ' '
                . &RGTools::Web_Form::Submit_Image(
                -src     => '/SDB/images/icons/minus.gif',
                -name    => 'Remove',
                -onClick => 'removeRow(this); return false;',
                -width   => $button_size,
                -height  => $button_size
                );
        }
        else {
            $self->{"C$column"}[ $row - 1 ] = 
                $BS->button(-icon=>'plus', -onclick=>"cloneRow(this); return false; ", -tooltip=>'Duplicate this row') 
                . $BS->button(-icon=>'minus', -onclick=>"removeRow(this); return false; ", -tooltip=>'Remove this row');
            
            my $old2 = &Show_Tool_Tip(
                RGTools::Web_Form::Submit_Image(
                    -src     => '/SDB/images/icons/plus.gif',
                    -name    => 'Add',
                    -onClick => 'cloneRow(this);return false;',
                    -width   => $button_size,
                    -height  => $button_size
                ),
                "Duplicate this row"
                )
                . ' '
                . &Show_Tool_Tip(
                RGTools::Web_Form::Submit_Image(
                    -src     => '/SDB/images/icons/minus.gif',
                    -name    => 'Remove',
                    -onClick => 'removeRow(this); return false;',
                    -width   => $button_size,
                    -height  => $button_size
                ),
                "Remove this row"
                );
        }

    }

    $self->{rows}++;

    ## set the bgcolor of the row to the same color as the previous row
    if ( defined $toggle ) {
        if ( !$toggle ) {
            $self->{colour}[ $row - 1 ] = $self->{Lcolour2};
        }
    }

    if ( defined $colour ) {
        if ( $colour =~ /\=/ ) {
            $self->{row_class}[ $row - 1 ] = $colour;
        }
        else {
            $self->{row_class}[ $row - 1 ] = "class='$colour'";
        }
    }

    if ($sortable and $self->{sortable}) {
	$self->Set_Row_Class($row, 'sortable');
    }

    if ( defined $spec ) {
        $self->{row_spec}[ $row - 1 ] = $spec;
    }
    $self->{row_type}[ $row - 1 ] = $type;

    $self->{element_id}{row}{$row} = $element_id;

    return 1;
}

#########################
sub Set_Cell_Colour {
#########################
    my $self   = shift;
    my $row    = shift;
    my $col    = shift;
    my $colour = shift;

    $self->{"($row,$col)"} =~ s /bgcolor\s*=\s*\S+//ig;
    $self->{"($row,$col)"} .= " bgcolor='$colour'";
    return 1;
}

#########################
sub Get_Cell_Colour {
#########################
    my $self = shift;
    my $row  = shift;
    my $col  = shift;

    my $colour = $self->{"($row,$col)"} || '';
    return $colour;
}

#########################
sub Set_Cell_Class {
#########################
    my $self      = shift;
    my $row       = shift;
    my $col       = shift;
    my $thisclass = shift;

    $self->{"($row,$col)"} .= " class='$thisclass'";
    return 1;
}
#########################
sub Get_Cell_Spec {
#########################
    my $self = shift;
    my $row  = shift;
    my $col  = shift;

    my $spec = $self->{"($row,$col)"} || '';
    return $spec;
}

#########################
sub Set_Cell_Spec {
#########################
    my $self = shift;
    my $row  = shift;
    my $col  = shift;
    my $spec = shift;

    $self->{"($row,$col)"} .= " $spec ";
    return 1;
}

#########################
sub Set_Column_Class {
#########################
    my $self      = shift;
    my $col       = shift;
    my $thisclass = shift;

    my $class = $thisclass;
    unless ( $thisclass =~ /=/ ) { $class = " class='$thisclass'" }

    for my $row ( 1 .. $self->{rows} ) {
        my $index = $row - 1;
        $self->{"($row,$col)"} .= $class;
    }
    return 1;
}

#############################################
# Set colour for entire column
# (should be done AFTER table filled in)
#########################
sub Set_Column_Colour {
#########################
    my $self       = shift;
    my $col        = shift;
    my $thiscolour = shift;
    my $rows       = shift || $self->{rows};

    for my $row ( 1 .. $rows ) {
        $self->{"($row,$col)"} =~ s /bgcolor\s*=\s*\S+//ig;
        $self->{"($row,$col)"} .= " bgcolor='$thiscolour'";
    }

    $self->{'column_colour'}{$col} = $thiscolour;
    return 1;
}

#########################
sub Set_Row_Class {
#########################
    my $self  = shift;
    my $row   = shift;
    my $class = shift;

    my $class_str= $self->{row_class}[$row-1];

    if ( $class_str =~ /class\s*=\s*['"]\w+['"]/ ) {
	    $class_str =~ s/(['"])$/,$class\1/;
    }

    else {
	$class_str = "class='$class'";
    }

    $self->{row_class}[$row-1] = $class_str;
    return 1;
}

#########################
sub Set_Row_Colour {
#########################
    my $self       = shift;
    my $row        = shift;
    my $thiscolour = shift;

    for my $col ( 1 .. $self->{columns} ) {
        $self->{"($row,$col)"} =~ s /bgcolor\s*=\s*\S+//ig;
        $self->{"($row,$col)"} .= " bgcolor='$thiscolour'";
    }
    return 1;
}



#############
sub get_IDs {
#############
    my $self = shift;
    my %args = @_;
    my $col  = $args{-col};
    my $row  = $args{-row};

    my @ids;
    if ( $col && $row ) {
        push( @ids, $self->{IDs}[$row][$col] );
    }
    elsif ($col) {
        foreach my $row ( 1 .. $self->{rows} ) {
            push( @ids, $self->{IDs}[$row][$col] );
        }
    }
    elsif ($row) {
        foreach my $col ( 1 .. $self->{columns} ) {
            push( @ids, $self->{IDs}[$row][$col] );
        }
    }
    else {
    }
    
    my @return_ids;
    foreach my $id (@ids) { 
        $id =~ /(\d+)/; 
        push (@return_ids, $1); 
    };

    return @return_ids;
}

######################
#
# Load the Table object with a hash (keys = headers)
# (each key should point to an array of similar length - comprising the columns)
#
#
##################
sub load_hash {
##################
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => 'hash,order', -mandatory => 'hash' );
    my $hash_ref  = $args{-hash};
    my $order_ref = $args{-order};

    my %hash = %$hash_ref;

    my @order;
    if   ($order_ref) { @order = @$order_ref }
    else              { @order = sort keys %hash }

    $self->Set_Headers( \@order );
    foreach my $key (@order) {
        unless ( ref $hash{$key} eq 'ARRAY' ) {
            return err ( "Keys must point to arrays of similar length.  $key is " . ref $hash{$key} );
        }
        my @array = @{ $hash{$key} };
        $self->Set_Column( [@array] );
    }
    return;
}

#
# Alternative to Printout that will generate an output graph instead.
# Uses RGTools::Graph to redirect column of table to graph
# Saves output file to indicated file name
# Return: 1 on success
##############
sub Graph {
##############
    my $self = shift;
    my %args              = &filter_input( \@_, -args => 'filename,header,suppress' );
    my $file = $args{-filename};
    my $x_column = $args{-x} || 1;
    my $y_column = $args{-y};
    my $xsize = $args{-xsize} || 800;
    my $ysize = $args{-ysize} || 600;
    my $row      = $args{-row} || 1;
    my $skip_rows = $args{-skip} || [];

    foreach my $row (1..$self->{rows}) {
	## skip non-data rows ##
	if ($self->{row_type}[$row-1] ne 'data') { push @$skip_rows, $row }
    }
	
    ## preset arguments for passing to RGTools::Graph::generate ##
    $args{-output_file} = $file;
    $args{-bar_width} ||= 5;
    $args{-xsize} ||= $xsize;
    $args{-ysize} ||= $ysize;

    $x_column--;
    if (!$y_column) { $y_column = [2..$self->{columns}] } ## default to all columns after first column ##

    my @x_data;
    my @y_data;

    my %hash;
    my @array;
    if (1) {
        ## assume we are graphing the columns ##
        my $x_index = 'C' . $x_column;
        my @original_x_data = @{$self->{'C' . $x_column}};

        ## clear tags if applicable ##
        ## map { while ($_ =~s/\<.*?\>//) { } } @x_data;  ## deprecated to BP
        foreach my $x (@original_x_data) {
            while ($x =~s/\<.*?\>//) {}
            push @x_data, $x;
        }

        my $index = 0;
        foreach my $i (@$y_column) {
            $i--;
            my $y_index = 'C' . $i;
            
            my @original_y_data = @{$self->{$y_index}};
            @y_data = ();

            #	    map { while ($_ =~s/\<.*?\>//) { } } @y_data;  deprecated to BP
            foreach my $y (@original_y_data) {
                while ($y =~s/\<.*?\>//) {}
                push @y_data, $y;
            }

            foreach my $row (1..$self->{rows}) {
                if ($skip_rows && grep /^$row$/, @$skip_rows) { next }

                my $xval = $x_data[$row-1];
                my $yval = $self->{$y_index}->[$row-1];
                push @{$hash{$xval}}, $yval;
                #		push @{$array[$row-1]}, $xval;
                #		push @{$array[$row-1]}, $yval;
            }
            $index++;
        }
    }
    else {
        ## graph row instead of columns (not currently supported ...) ##
        @x_data = @{$self->{header_labels}};
        @y_data;
        foreach my $col (0..$self->{columns}-1) {
            push @y_data, $self->{"C$col"}->[$row-1];
        }
    }

    ### Add spacer ##
    if (int(@$y_column) > 1) {
        foreach my $row (1..$self->{rows}) {
            if ($skip_rows && grep /^$row$/, @$skip_rows) { next }
            my $xval = $x_data[$row-1];
            push @{$hash{$xval}}, '';
            #	    push @{$array[$row-1]}, $xval;
            #	    push @{$array[$row-1]}, '';
        }
    }

	
    my $fail = 0;
    map { if ($_ =~ /^(\d+)\.?(\d*)$/) { $fail=0 } else {  $fail++ } } @y_data;
    
    if ($fail) { Message("NON Numeric value found in first column") }
    
    
    while (int(@x_data) > int(@y_data)) { 
	## if x_data is larger set than y_data - truncate it.. ##
	pop @x_data;
    }
       
    my $title;
    if ($self->{header_labels}) {
	$title = $self->{header_labels}[$x_column-1] . ' vs ' . $self->{header_labels}[$y_column-1];
    }

    eval {"require RGTools::Graph"};
    my $ok = &Graph::generate_graph(-title=>'Distribution', -hash=>\%hash, -title=>$title, -colour=>'green,blue,red', -nominal_x=>20, %args);
    return $ok;
}

#
# Simple method to collapse rows below currently defined rows.
#
# Usage:
#
#   ... 
#    $table->Set_Row(..);
#    $table->Set_Row(..);
#    $table->collapse_section();
#    $table->Set_Row(..);
#    $table->Set_Row(..);
#
#    ## 3rd and 4th row are collapsed by default, but can be displayed with the press of a button ##
#
#  (rows can be hidden and displayed using javascript button)
#
########################
sub collapse_section {
########################
    my $self = shift;
    
    use LampLite::Bootstrap();
    my $BS = new Bootstrap;
    
    my $uncollapse_message = shift || $BS->icon('collapse-top') || 'Show More';
    my $collapse_message = shift || $BS->icon('collapse-top') || 'Hide Details';
    
    $self->{collapse_row} = $self->{rows} + 1;
    
    $self->{uncollapse_link} = $BS->button(-label=>$uncollapse_message, -onClick=>"unHideNamedElement('collapsed'); HideNamedElement('uncollapsed');" );
    $self->{collapse_link} = $BS->button(-label=>$collapse_message, -onClick=>"HideNamedElement('collapsed'); unHideNamedElement('uncollapsed');" );
     
    $self->{collapse_bgcolor} = $background_colour;
    return;
}

#########################
#
# Printout table (usually final call used to generate table)
# <snip>
# Examples:
#     $Table->Printout();  ## standard printout
#
#     my $table = $Table->Printout(0);  ## (saves table to scalar, but not printed)
#
#     my $table = $Table->Printout($filename);   ## writes table to $filename (.html file)
#     ...
#
#
#
####################
sub Printout {
####################
    my $self              = shift;
    my %args              = &filter_input( \@_, -args => 'filename,header,suppress' );
    my $nowrap            = $args{-nowrap} || $self->{nowrap};
    my $filename          = $args{-filename};
    my $Table_header      = $args{-header} || $self->{header}; ### Deprecated: now taken care of by xls_settings
    my $suppress_printing = $args{-suppress};
    my $link              = $args{ -link };
    my $randname          = $args{-randname} || 0;
    my $link_text         = $args{-link_text} || 'Printable Page';
    my $xls_settings      = $args{-xls_settings};
    my $resize_onload    = $args{-resize_onload};
    my $resize            = $args{-resize} || $resize_onload;

    $nowrap = 'nowrap' if $nowrap;

    $self->update_toggle_settings();
    
    ## set column colours after table is filled in ###
    if ( $self->{'column_colour'} ) {
        foreach my $col ( keys %{ $self->{'column_colour'} } ) {
            $self->Set_Column_Colour( $col, $self->{'column_colour'}{$col} );
        }
    }

    # generate a random number to use as a table name
    if ( !$randname ) {
        #$randname = rand();

        # get the eight least significant figures
        #$randname = substr( $randname, -8 );

        # The above way may produce a number preceded by a 0, which is regarded as octal in Javascript and this breaks SDB.js's mergesort since $randname is not in proper octal format
        $randname = int(rand(99999999)) + 1;
    }
    my ( $ind1, $ind2, $ind3, $ind4, $ind5, $ind6, $ind7 ) = ( "\t", "\t\t", "\t\t\t", "\t\t\t\t", "\t\t\t\t\t", "\t\t\t\t\t\t", "\t\t\t\t\t\t\t" );    ## variables for formatting output

    $class_size = "small";                                      ## for reduced size view...

    my $class_on;                                               ### set class is specified as common (
    my $class_off;
    
    if ( $self->{common_class} ) {
        $class_on  = "<span $self->{common_class}>";
        $class_off = "</span>";
    }
    
    my $style;
    if ($self->{style}) {
        $style = "style='$self->{style}'";
    }
        
    my $URL_path;
#### Custom adjustment ##### <CONSTRUCTION>  ##... requires altering of filename to URL path...
    if   ( $filename =~ m|\/(dynamic\/.*)| ) { $URL_path = $1; }
    else                                     { $URL_path = $filename; }

    $URL_path = URI::Escape::uri_unescape($URL_path);
    $URL_path =~s /\s/\%20/g;

    my $print_string = "";

    if ($self->{paste_area}) {
        my $clear_button = CGI::button( -name => 'ClearArea', -value => 'Clear Cut & Paste Area', class=>'Std', -onClick => "SetSelection(this.form,'$self->{paste_area}', '');");
        my $tip = "Paste data from Excel file or document here - use 'Paste' button below to paste into desired column";
        my $CParea =  Show_Tool_Tip( textarea(-rows=>5, -columns=>100,-name=>$self->{paste_area}), $tip) . ' ' . $clear_button;
            
        require LampLite::HTML;
        $print_string .= '<P>' . LampLite::HTML::create_tree( -tree=>{ 'Cut & Paste Area' => $CParea }, -closed_tip=>'') . '<P>' . '<HR>';
    }

    $print_string .= $Table_header;

    foreach my $col ( 1 .. $self->{columns} ) {
        $self->{valign}[ $col - 1 ] ||= '';
        $self->{align}[ $col - 1 ]  ||= '';
    }

    if ( $self->{prefix} ) { $print_string .= $self->{prefix} }

    my $font_string;
    
    my $cell_style;
    
    if ( $self->{Font} ) { $font_string = "Font " . $self->{Font}; }
    if ( !ref $self->{global_cell_style} ) { $cell_style = "style ='$self->{global_cell_style}'" }  ## global cell_style ##
    
    if ($self->{scrollable_body}){
    	$print_string .= "$ind1<div class = \"view_scroll_outer\">\n$ind2<div class = \"view_scroll_inner\">\n";    #inner for body, outer for header(not used yet, it will be is overflow is set for x-axis)
    } else {
    	( $ind3, $ind4, $ind5, $ind6, $ind7 ) = ( $ind1, $ind2, $ind3, $ind4, $ind5 );	# move indents back    	
    }
    
    use LampLite::Bootstrap();
    my $BS = new Bootstrap;

    if (($self->{table_id_track} =~ /resizable/) || $resize ) {
        $resize = 1;
        if (!$self->{table_id_track}) {  
            my $table_id = 'resizable' . int(rand(1000000));
            $self->{table_id_track} = $table_id;
        }
    
        my $small = $BS->tooltip( 
            $BS->button(-icon => 'compress', -onClick => "tableResize('$self->{table_id_track}'); HideElement('tglTblResize$self->{table_id_track}'); unHideElement('tglTblResize2$self->{table_id_track}'); return false;", -id=>"tglTblResize".$self->{table_id_track}, -style => "background-color:#D8D8D8"),
            "Resizes the table to the size of the visible window.");
        my $full = $BS->tooltip(
            $BS->button(-icon => 'expand', -onClick => "tableRestore('$self->{table_id_track}'); HideElement('tglTblResize2$self->{table_id_track}'); unHideElement('tglTblResize$self->{table_id_track}'); return false;", -id =>"tglTblResize2".$self->{table_id_track}, -style => "display:none;background-color:#D8D8D8"), 
                "Resizes the table to the original size.");
        
        $print_string
            .= "\n<br />"
            . $small
            . $full
            . "\n<br />";
        $print_string .= "\n<div class='wrapper'>\n";
    }
    $print_string .= "\n$ind3<table id='$self->{table_id}' class='table table-hover' $style  $self->{padding} $self->{spacing} $self->{border} $self->{width} $self->{margin} $self->{Table_align}>\n$ind4<thead>\n";
    
    if ( $self->{title} ) {
        my $closing_style_tag;
        if ( $self->{Tstyle} ) {
            $closing_style_tag = $self->{Tstyle};
            $closing_style_tag =~ s/</<\//g;
        }
        $print_string .= "$ind5<tr>\n$ind6<th $nowrap colspan=$self->{columns} $self->{Tclass} align=left $cell_style>\n$ind7<font $self->{Tfont}>$self->{Tstyle}";
        $print_string .= $self->{title} . "$closing_style_tag</font>\n$ind6</th>\n$ind5</tr>\n";
    }
    if ( $self->{sub_titles} ) {
        $print_string .= "$ind5<tr>\n";
        my $index = 0;
        while ( $self->{sub_title}[$index] ) {
            $print_string .= "$ind6<td $nowrap colspan=$self->{sub_title_span}[$index] $self->{STcolour}[$index]>\n";
            $print_string .= $self->{sub_title}[$index];
            $print_string .= "$ind6</td>\n";
            $index++;
        }
        $print_string .= "$ind5</tr>\n";
    }

    # set autosort columns
    if ( $self->{autosort} ) {
        $self->{autosort_columns} = [];
        foreach my $column ( 1 .. $self->{columns} ) {
            push( @{ $self->{autosort_columns} }, $column - 1 );
        }
    }

    ## generate list of random ids...##
    if ( defined $self->{IDs} ) {
        foreach my $row ( 1 .. $self->{rows} ) {
            foreach my $col ( 1 .. $self->{columns} ) {
                my $id = $self->{element_id}{rc}{"$row.$col"} || substr( rand(), -8 );    ## random integer
                $self->{IDs}[$row][$col] = "id='$id'";
		
                if ( ($col > 1) || ($self->{row_spec}[$row-1] =~ /\bid=/i) ) { next }   ## already specified  
		        my $row_id = $self->{element_id}{row}{$row} || substr( rand(), -8);  ## random integer default
		        $self->{row_IDs}[$row] = "id='$row_id'";
            }
        }
    }
    else { Message("no id"); }
	
    if ( scalar( @{ $self->{header_labels} } ) ) {
        $print_string .= "\n$ind5<tr $self->{Hcolour}>\n";
        foreach my $column ( 1 .. $self->{columns} ) {
            my $sortable     = 0;
            my $colzeroindex = $column - 1;
            if ( $self->{autosort_columns} && grep( /^$colzeroindex$/, @{ $self->{autosort_columns} } ) ) {
                $sortable = 1;
            }
           
            $print_string .= "$ind6<th $nowrap $self->{IDs}[0][$column] $self->{Hclass}[$column-1] $self->{Cwidth}[$column-1] $font_string  $cell_style>\n$ind7 $class_on ";
			
            my $header_tooltip;
            my $trimmed_label = _strip_tags($self->{header_labels}[ $column - 1 ]);
            
            if(defined $self->{header_info}){            	
	            $header_tooltip = $self->{header_info}{$trimmed_label}{description} || $self->{header_info}{$self->{header_labels}[ $column - 1 ]}{description};	            
	        }
	        
            if (defined $header_tooltip && $sortable) {
               my $number = $column - 1;
         	   $print_string .= Show_Tool_Tip($self->{header_labels}[ $column - 1 ]   , $header_tooltip, -onclick => "return mergesort( $number,$randname)");  
         	}
            elsif ($header_tooltip){
             	$print_string .= Show_Tool_Tip($self->{header_labels}[ $column - 1 ], $header_tooltip);
            }
            elsif ($sortable){
                $print_string .= "<a href='' onclick='return mergesort(" . ( $column - 1 ) . ",$randname)' >";
               $print_string .= $self->{header_labels}[ $column - 1 ];
               $print_string .= "</a>";
	         } 
             else {
                 $print_string .= $self->{header_labels}[ $column - 1 ];
             }

             $print_string .= "$class_off\n$ind6</th>\n";
        }
        $print_string .= "$ind5</tr>\n$ind4</thead>\n";
    }
    my $colour     = $self->{Lcolour};
    my $link_index = 0;                  ### index links
                                         # print body tag
    $self->{link_index} = 0;
    $print_string .= "\n$ind4<tbody id = $randname>\n" if ( $self->{autosort_columns} );
 
    if (! $self->{colours}) { $self->{colours} = [$self->{Lcolour}, $self->{Lcolour2} ] }
    
    my $collapse;
    foreach my $row ( 1 .. $self->{rows} ) {        
        $colour = $self->{colour}[$row-1] || $self->toggled_value(-key=>'colour', -prefix=>'C', -list=>$self->{colours}, -row=>$row);
        
        my $row_style = $self->{row_style}{"($row)"};

        my $row_spec;    ## clear to separate from previous row..
        $row_spec = $colour unless ( ( $self->{row_class}[ $row - 1 ] =~ /color/ ) || ( $self->{row_spec}[ $row - 1 ] =~ /color/ ) );
        $row_spec .= " $self->{row_class}[$row-1] $self->{row_spec}[$row-1] $self->{row_attr}[$row-1]";

        if ($self->{collapse_row} eq $row) { 
            $collapse = qq(name='collapsed' style='display:none $self->{global_cell_style}');
            $print_string .= "$ind5<tr name='uncollapsed'><td colspan=$self->{columns} align='center' bgcolor='$self->{collapse_bgcolor}' $cell_style>$self->{uncollapse_link}</TD></TR>\n";
            $print_string .= "$ind5<tr name='collapsed' $collapse><td colspan=$self->{columns} align='center' bgcolor='$self->{collapse_bgcolor}'  $cell_style>$self->{collapse_link}</TD></TR>\n";
        }
        $print_string .= "$ind5<tr $row_spec  $self->{row_IDs}[$row] $collapse $row_style>\n";
        my $skip = 0;    ###### flag to skip to next row...

        foreach my $column ( 1 .. $self->{columns} ) {
            if ($skip) { next; }
            my $index    = $column - 1;
            my $thistext = $self->{"C$index"}[ $row - 1 ];
            if ( ( !($thistext) ) && ( !( $self->{add_empty_cells} ) ) ) {
                next;
            }
         
            # if colspans are not defined, do not print
            if ( ( !$self->{row_type}[ $row - 1 ] =~ /heading/i ) && ( !defined $self->{'colspan'}{"($row,$column)"} ) ) {
                next;
            }

            my $c_style = $self->{cell_style}{"($row,$column)"} || $cell_style;
 #           print "$row + $column => " . $self->{cell_style}{"($row,$column)"}; 
            my $cell_spec;
            if ( defined $self->{"($row,$column)"} ) {
                $cell_spec = $self->{"($row,$column)"};
            }
            if ( $self->{row_type}[ $row - 1 ] =~ /heading/i ) {
                $print_string .= "$ind6<td $nowrap  $self->{IDs}[$row][$column] colspan=$self->{columns} $self->{Cwidth}[$column-1] $font_string $c_style>\n$ind7 $class_on";
                $skip = 1;    ### only do once..
            }
            else {
                my $colspan = '';

                if ( $self->{colspan_def} ) {
                    $colspan = " colspan=" . $self->{'colspan'}{"($row,$column)"};
                }

                $print_string .= "$ind6<td $nowrap  $self->{IDs}[$row][$column] $colspan $cell_spec $self->{align}[$column-1] $self->{valign}[$column-1] $self->{Cwidth}[$column-1] $font_string $c_style>\n$ind7$class_on";
            }
            $thistext =~ s/^NULL$/-/g;    ###### don't print NULL as single entry ##
            if ( $self->{links} ) {
                ## only do this if link tags are set (this can slow down the table generation quite a bit) ##
                $print_string .= _replace_links(
                    -self => $self,
                    -text => $thistext,
                    -file => $filename
                );

            }
            else {

                $print_string .= $thistext;
            }
            $print_string .= "$class_off\n$ind6</td>\n";
        }
        $print_string .= "$ind5</tr>\n";
                
        if ( $self->{autosort_end_skip} ) {
            if ( $row == ( $self->{rows} - $self->{autosort_end_skip} ) ) {
                $print_string .= "\n<$ind4/tbody>\n" if ( $self->{autosort_columns} );
            }
        }
    }
    
    $print_string .= "\n$ind4</tbody>\n" if ( $self->{autosort_columns} && !$self->{autosort_end_skip} );
    
    # Section for adding footer
    if($self->{footer}){
    	my @footers = @{$self->{footer}};
    	my $foot_rows = @footers;    	    	

    	
    	if($foot_rows > 0 ){
    		$print_string .= "$ind4<tfoot>\n";	# use html standard tfoot for footer, prevents problems when sorting etc...
	    	foreach my $footer (@footers){
	    		my %footer_row_hash = %{$footer};
	    		my @enteries = @{$footer_row_hash{enteries}};
	    		my $class = $footer_row_hash{class};
	    		my $num_enteries = @enteries;
	    			    		
	    		$print_string .= "$ind5<tr ";
	    		if($class){
    				$print_string .= "class = \"$class\" "; 
    			} else
    			{
    				$print_string .= "class = \"small\" "; 
    			}
	    		$print_string .= ">\n";
	    		if($num_enteries == 1){
	    			$print_string .= "$ind6<td colspan=\"$self->{columns}\">$class_on";
	    			$print_string .= "$enteries[0]";	    			
	    			$print_string .= "$class_off</td>\n";
	    		} else{
	    			foreach my $col ( 0 .. $self->{columns} - 1 ){
	    				$print_string .= "$ind6<td>$class_on";
	    				$print_string .= $enteries[$col];	    				
	    				$print_string .= "$class_off</td>\n";	    		
	    			}	    			
	    		}	    		
	    		$print_string .= "$ind5</tr>\n";
	    	}
	    	$print_string .= "$ind4</tfoot>\n";
    	}
    
    }
    
    $print_string .= "$ind3</table>\n";
 
    my $id = $self->{table_id};
    if ($self->{table_class} eq 'dataTable' ) { $print_string .= qq(<script>\$(document).ready(function(){\$('#$id').dataTable();});</script>) }
    
    if ($resize) {
        $print_string .= "\n</div>\n";
    }
    if ($resize_onload) {
        $print_string .= qq(\n<script type='text/javascript'>tableResize\('$self->{table_id_track}'\); HideElement\('tglTblResize$self->{table_id_track}'\); unHideElement\('tglTblResize2$self->{table_id_track}'\);</script>);
    }
    
    if ($self->{scrollable_body}){
    	$print_string .= "$ind2</div>\n$ind1</div>\n";    
    } 
    
    #  if ($self->{Font}) { $font_string .= "</Font>" }

    if ( $self->{suffix} ) { $print_string .= $self->{suffix}; }


    if ($suppress_printing) {
        return $print_string;
    }

    if ( $filename && ( $filename =~ /\.xls/ ) ) {
        if ($class_size) {
            $print_string =~ s/class=medium/class=$class_size/g;
            $print_string =~ s/cellpadding=(\d+)/cellpadding=5/g;
        }
        my $link = "\n<BR><a href='/$URL_path'><b>Excel File</b></a>\n";
        $link .= "<I> (extracts only this table)</I>\n";
        
        # print out html
        my $html_str = "";
        $html_str .= $self->{HTML_header};
        $html_str .= start_html('Popup Window');
        #$html_str .= $Table_header;
        $html_str .= start_form();                 # in case forms are being used...
        $html_str .= $print_string;
        $html_str .= end_form();
        $html_str .= end_html;

        $self->print_to_xls_native( -outfile => $filename, -xls_settings=>$xls_settings);
        return $link;
    }
    elsif ( $filename && ( $filename =~ /\.csv/ ) ) {
        if ($class_size) {
            $print_string =~ s/class=medium/class=$class_size/g;
            $print_string =~ s/cellpadding=(\d+)/cellpadding=5/g;
        }
        my $link = "\n<BR><a href='/$URL_path'><B>CSV File</B></a>\n";
        $link .= "<I> (extracts only this table)</I>\n";
        $self->print_to_csv( -outfile => $filename );
        return $link;
    }
    elsif ( $filename && ($filename =~ /\.gif$/ ) ) {
	my $link = "\n<BR><a href='/$URL_path'><B>Graph</B></a>\n";
        $link .= "<I> (extracts only this table)</I>\n";
        $self->Graph(%args);
        return $link;
    }
    elsif ($filename) {    ### in this case only print to a file ###
	    # remove session ID so that it won't be saved to file
		my $stripped_string = &remove_credential( -string => $print_string, -credentials => 'CGISESSID' );        

        if ($class_size) {
            $stripped_string =~ s/class=medium/class=$class_size/g;
            $stripped_string =~ s/cellpadding=(\d+)/cellpadding=5/g;
        }
        $link = $self->{link};
        $link ||= "\n<BR><a href='/$URL_path' onClick=\"window.open('/$URL_path', '1902'); return false;\"><B>$link_text</b></a>\n" . "<I> (extracts only this table)</i>\n";
        
#        open( OUTFILE, ">$filename" ) or print "Error writing to $filename.";
        open my $OUTFILE, '>', $filename or print "CANNOT OPEN $filename to write";
        
        ## move links into separate parameter ##
        print $OUTFILE $self->{HTML_header};

        print $OUTFILE start_html('Popup Window');
        #print $OUTFILE $Table_header;
        print $OUTFILE start_form();    # in case forms are being used...
        print $OUTFILE $stripped_string;
        print $OUTFILE end_form();
        print $OUTFILE end_html;
        close($OUTFILE);
        
        return $link;
    }
    elsif ( !defined $filename ) { print $print_string; }

    return $print_string;
}

#############################
sub update_toggle_settings {
#############################
    my $self = shift;
    
    my $column = $self->{toggle_colour_on_column};
    my $column_index = $self->{toggle_colour_on_column_number};
    
    if ($self->{toggle_colour_on_column} || $self->{toggle_colour_on_column_number}) {
        my $headers = $self->{header_labels};   
         foreach my $i (1 .. int(@$headers) ) {
            if ($headers->[$i-1] eq $column) {
                $self->{toggle_colour_on_column_number} ||= $i-1;
                last;
            }
            elsif ( $column_index && $column_index == $i ) {
                $self->{toggle_colour_on_column} ||= $headers->[$i-1];
                last;
            }
        }
    }
    return;
}
###################
sub toggled_value {
###################
    my $self = shift;
    my %args = @_;
    my $key = $args{-key};
    my $list = $args{-list};
    my $row = $args{-row};
    my $default = $args{-default};
        
    my $new_value =  $default;
    if ( my $column = $self->{"toggle_${key}_on_column_number"} ) {
        ## toggle based on column value change ##
        if ( $self->toggled(-column=>$column, -row=>$row) ) {
            $new_value = $self->toggle_value(-list=>$list, -key=>$key);
        }
    }
    elsif ( $self->{"toggle_${key}"} ) {        
        ## simple toggle based on value change ##
        $new_value = $self->toggle_value(-list=>$list, -key=>$key);
    }    

    return $new_value;
}

####################
sub toggle_value {
####################
    my $self = shift;
    my %args = @_;
    my $list = $args{-list};
    my $key  = $args{-key};
    my $default = $args{-default};
    
    my $latest = $self->{"toggled_$key"};
    my $value = $default;
    if (! $latest) { 
        ## first time through
        $value = $list->[0];
    }     
    else {
        foreach my $i (1..int(@$list)) {
            if ($latest eq $list->[$i-1]) {
                if ($i >= int(@$list)) { $value = $list->[0] }
                else { $value = $list->[$i] }
                last;
            }
         }
     }
    $self->{"toggled_$key"} = $value;

    return $value;    
}
#
# Simple accessor to determine if the given column has changed from the previous value
# (used by colour toggling on value)
#
#  Return: 1 if value is different
###############
sub toggled {
###############
    my $self = shift;
    my %args = @_;
    my $check = $args{-column};  ## column number 
    my $row  = $args{-row}; ## record number (first record = 1, so current record is row-1; last record is row-2)
    
    if ($row <=  1) { return 1 }
    elsif ($self->{"C$check"}[ $row - 2 ] eq $self->{"C$check"}[ $row - 1 ]) { return 0 }
    else { return 1}
    
}

##############################
# function that writes out a .csv file from the table
##############################
sub print_to_csv {
###############
    my $self    = shift;
    my %args    = @_;
    my $outfile = $args{-outfile};
    my $csv_str = "";
    ## write out the headers
    # write out the title
    #if ($self->{title}) {
    #	$csv_str .= "$self->{title}\n";
    #   }
    # write out subtitles
    if ( $self->{sub_titles} ) {
        my $index = 0;
        my $line  = "";
        while ( $self->{sub_title}[$index] ) {
            $line .= $self->{sub_title}[$index] . "\t";
            foreach ( 1 .. $self->{sub_title_span}[$index] ) {
                $line .= "\t";
            }
            $index++;
        }
        chop($line) if ( $line =~ /,$/ );
        $csv_str .= "$line\n";
    }

    # write out headers
    if ( scalar( @{ $self->{header_labels} } ) ) {
        my $line = "";
        foreach my $column ( 1 .. $self->{columns} ) {
            $line .= $self->{header_labels}[ $column - 1 ] . "\t";
            foreach ( 1 .. $self->{Cwidth}[ $column - 1 ] ) {
                $line .= "\t";
            }
        }
        chop($line) if ( $line =~ /,$/ );
        $csv_str .= "$line\n";
    }

    # write out the body of the table
    foreach my $row ( 1 .. $self->{rows} ) {
        my $line = "";
        foreach my $col ( 1 .. $self->{columns} ) {
            my $column = $col - 1;
            $line .= $self->{"C$column"}[ $row - 1 ] . "\t";
            foreach ( 1 .. $self->{Cwidth}[ $col - 1 ] ) {
                $line .= "\t";
            }
        }
        chop($line) if ( $line =~ /,$/ );
        $csv_str .= "$line\n";
    }

    # do regexp to parse out special tags (<br> gets replaced with a space)
    $csv_str =~ s/<br\s*?\/?>/ /gi;

    # div and script tags, everything gets removed
    # remove set_Tooltip as well
    $csv_str =~ s/<script>.*?<\/script>//gi;
    $csv_str =~ s/<div>.*?<\/div>//gi;
    $csv_str =~ s/setTooltip\Q()\E//gi;

    # remove &nbsp
    $csv_str =~ s/\&nbsp;?//gi;

    # do a regexp to remove all tags
    $csv_str =~ s/<.*?>//g;


#    my $OUT;
#    open( $OUT, ">$outfile" );
    open my $OUT, '>', $outfile;
    print $OUT $csv_str;
    close($OUT);

    #my $row = $self->{rows} + 1;
    #$self->{"C$column"}[$row-1] = $value;
}

################################
# function that writes out an excel file from the table
################################
sub print_to_xls_native {
#####################   
    # import modules needed
#    my ($mypath) = $INC{'RGTools/HTML_Table.pm'} =~ /^(.*)Core\/RGTools\/HTML_Table\.pm$/;
#
#    unless ( -e "$mypath/Imported/Excel/" ) {
#        print "Spreadsheet::Excel modules not available in $mypath/Imported/Excel/";
#        return;
#    }
#    push( @INC, "$mypath/Imported/Excel/" );    # unless (grep('$mypath/Imported/Excel/',@INC));
#    
#    # check if modules exist
#
#    my $ok = eval "require Spreadsheet::WriteExcel";
#    if ($@) {
#        print "Missing required modules: $@";
#        return;
#    }
    
    my $self       = shift;
    my %args       = @_;
    my $outputfile = $args{-outfile};
    my $xls_settings =  $args{-xls_settings};
    my $lookup_ref = $args{-lookup};
    
    # Setup spreadsheet
    # Create a new Excel workbook
#     my $workbook = Spreadsheet::WriteExcel->new("$outputfile");

    require SDB::Excel;
    my $workbook = SDB::Excel::load_Writer($outputfile) || return;
        
    # Add a worksheet
    my $worksheet_name = 'Data';

    my $sheet = $workbook->add_worksheet($worksheet_name);
    
    my $protected   = $xls_settings->{protected};
    if ($protected) { $sheet->protect() }
    
    #### set up formats #####
    my $boldformat = $workbook->addformat();
    $boldformat->set_bold(1);
    
    my $italicformat = $workbook->addformat();
    $italicformat->set_italic(1);
    
    my $bolditalicformat = $workbook->addformat();
    $bolditalicformat->set_bold(1);
    $bolditalicformat->set_italic(1);
    
    my $headerformat = $workbook->addformat();
    $headerformat->set_bold(1);
    $headerformat->set_bg_color('silver');
    $headerformat->set_align('top');
    $headerformat->set_align('center');
    $headerformat->set_text_wrap();
    $headerformat->set_border(1);
    $headerformat->set_locked($protected);
  
    my $mandatory_headerformat = $workbook->addformat;
    $mandatory_headerformat->set_bold(1);
    $mandatory_headerformat->set_bg_color('silver');
    $mandatory_headerformat->set_color('red');
    $mandatory_headerformat->set_align('top');
    $mandatory_headerformat->set_align('center');
    $mandatory_headerformat->set_text_wrap();
    $mandatory_headerformat->set_border(1);
    $mandatory_headerformat->set_locked($protected);
 
    my $empty_format = $workbook->add_format();
    $empty_format->set_bg_color('silver');
    $empty_format->set_locked(0);
    $empty_format->set_bold(1);
    $empty_format->set_align('top');
    $empty_format->set_align('left');
  
    my $date_format = $self->{date_format} || 'yyyy-mm-dd';  ## need accessor to set this as well...
    my $dateformat = $workbook->addformat();
    $dateformat->set_num_format($date_format);
    $dateformat->set_locked(0);
  
    my $locked = $workbook->add_format();
    $locked->set_locked($protected);

    my $unlocked = $workbook->add_format();
    $unlocked->set_locked(0);

    
    my $lookup_sheet;  ## optional lookup worksheet
    my $config_sheet;  ## optional worksheet for configs
   
    my $rowcounter = 0;
    my $colcounter = 0;
    
    my $mandatory = $xls_settings->{mandatory};
   
    if ($xls_settings->{header}) {
        # Message("Write header: " . $xls_settings->{header});
        
        $sheet->set_header("&L" . $xls_settings->{header});  ## include header as excel header rather than standard cell
        
#        $sheet->write( 0, 0, $xls_settings->{header}, $locked);
#        $rowcounter++;
    }
    elsif ($xls_settings->{show_title} && $self->{title} ) {
        # Message("Write title: " . $self->{title});
        # write out the title (not necessary to write this into the cells...)
        my $value = $self->{title};
        $value = &_strip_tags($value);

        $sheet->set_header("&L" . $value);  ## include title as header rather than standard cell
        
#        $sheet->write( $rowcounter, $colcounter, $value, $locked);
#        $rowcounter++;
    }

    my $col_offset = 0;
    if ($xls_settings->{add_columns}) {
        my $i = 0;
        foreach my $column (@{$xls_settings->{add_columns}}) {
            $sheet->write( $rowcounter, $i, $column, $locked );
            $i++;
            Message("Add column $column");
         }
         $col_offset = $i;
    }
    
    # write out subtitles
    if ( $self->{sub_titles} ) {
        my $index = 0;
        while ( $self->{sub_title}[$index] ) {
            my $value = $self->{sub_title}[$index];
            $value = &_strip_tags($value);
            $sheet->write( $rowcounter, $colcounter, $value, $locked );
            $colcounter++;
            foreach ( 1 .. $self->{sub_title_span}[$index] ) {
                $colcounter++;
            }
            $index++;
        }
        $rowcounter++;
    }

    my $skip_first_column = ( $self->{"C0"}[ 1 ] =~ /<input type=['"]checkbox['"]/);  ### Hide selectable checkboxes in first column (used in standard web views) if applicable ####
#    Message("Skip: $skip_first_column : $self->{columns}");
 
    $colcounter = 0;
    # write out headers
    if ( scalar( @{ $self->{header_labels} } ) ) {
        my $line = "";
        $sheet->freeze_panes(1,0);
        foreach my $column ( 1 .. $self->{columns} ) {
            my $value  = $self->{header_labels}[ $column - 1 ];
                        
            if ($column == 1 && $skip_first_column) { next }
            
            my $date_column = ($value =~/\bDate\b/i);   ## temporary - better to pass in date_format specs tied to columns as required 
            
            $value = &_strip_tags($value);
            
            my $format = $headerformat;
            if ($mandatory && grep /^$value$/, @$mandatory) { $format = $mandatory_headerformat; }
            
            auto_size_column($sheet, $colcounter + $col_offset, $value, -min=>5, -max=>400, -format=>$unlocked);
            
            if ($date_column) { 
                $value .= "\n[$date_format]";
                $sheet->write_comment($rowcounter, $colcounter + $col_offset, "Please use format:\n$date_format"); 
            }            
            $sheet->write( $rowcounter, $colcounter + $col_offset, $value, $format );

            $colcounter++;
            foreach ( 1 .. $self->{Cwidth}[ $column - 1 ] ) {
                $colcounter++;
            }
        }
        $rowcounter++;
    }
    

    $sheet->set_row(0, 30);

    my $lookup_cols = 0;
    if ($xls_settings->{lookup}) {
        ## new_sheet should be set to 0 since the API does not seem to generate the data_validation reference properly if the lookups are on a separate worksheet ##
        $lookup_cols = $self->_embed_lookup_table(-workbook=>$workbook, -sheet=>$sheet, -new_sheet=>0, -lookup=>$xls_settings->{lookup}, -column_offset=>$col_offset, -protected=>0);  ## can only protect lookup table if we put on another sheet...
    }
    
    if ($xls_settings->{config}) {
        $self->_embed_config(-workbook=>$workbook, -sheet=>$sheet, -new_sheet=>1, -config=>$xls_settings->{config}, -column_offset=>0, -protected=>1)
    }

    # write out the body of the table
    foreach my $row ( 1 .. $self->{rows} ) {
        $colcounter = 0;
        my $format = $workbook->addformat();
        my $colour = 8*$row;

        my $line = "";
        foreach my $col ( 1 .. $self->{columns} ) {
            my $column = $col - 1;
            
            if ($col == 1 && $skip_first_column) { next }

            my $value  = $self->{"C$column"}[ $row - 1 ];

            if (defined $xls_settings->{lookup}){		
                my $preset = _embedded_lookup($xls_settings, -col=>$col);

                if( length( $preset) ) {
                    $value = $preset;
                }
            }

            #### Any '-' that is in the table would have been put there in lieu of a NULL value in the database.
            ## Putting a blank in the excel to represent a NULL value
            if ($value eq '-') {
                $value = '';
            }	

            my $format;

            my $header  = $self->{header_labels}[ $column - 1 ];
            my $date_column = ($header =~/\bDate\b/i);   ## temporary - better to pass in date_format specs tied to columns as required 
            if ($date_column) { 
                $format = $dateformat;
            }
            else { $format = $unlocked }

            $value = &_strip_tags($value);
            $sheet->write( $rowcounter, $colcounter + $col_offset, $value, $format );

            $colcounter++;
            foreach ( 1 .. $self->{Cwidth}[ $col - 1 ] ) {
                $colcounter++;
            }
        }
        $rowcounter++;
    }
   
    my $locking = $protected;      ## cells write protected

    my $add_columns = 5;  ## add block of N unlockedcolumns to right of locked block of data 
    if ($locking && $add_columns) {
        my $empty_columns = $add_columns;
        ## Add unprotected block after data section to allow extra input column information ##
        $sheet->write(0, $colcounter+1, "Add extra information here if necessary ($empty_columns writeable columns)", $empty_format);
        foreach my $col ($colcounter + 2 .. $colcounter + $empty_columns) {
            $sheet->write(0, $col, '', $empty_format);
        }      
        $sheet->set_column($colcounter + 1, $colcounter + $empty_columns, undef, $unlocked);
    }

    if ($xls_settings->{column_width}) {
        $sheet->set_column(1, $self->{columns}-1, $xls_settings->{column_width});
    }
}

#
# Automatically resize column width based upon content length
#
# 
######################
sub auto_size_column {
######################
    my %args = filter_input(\@_, -args=>'sheet,col,value,min,max');
    my $sheet = $args{-sheet};
    my $col   = $args{-col};
    my $value = $args{-value};
    my $min   = $args{-min};
    my $max   = $args{-max};
    my $format = $args{-format};
   
  
    my $width = length($value) + 2;
    if ($width > $max) { $width = $max }
    elsif ($width < $min) { $width = $min }
    $sheet->set_column($col, $col, $width, $format);

    return;
}

#######################
sub _embedded_lookup {
#######################
    my %args = filter_input(\@_,-args=>'xls_settings');
    my $xls_settings = $args{-xls_settings};
    my $row = $args{-row};
    my $col = $args{-col};
    
    if (!$xls_settings) { return }
    
    my @keys = keys %{$xls_settings->{lookup}};

    if ( @keys ) {
        my $key;
        if ( grep /^$col$/, @keys ) {
            $key = $col;
        }
        elsif ( grep /^$row:$col$/, @keys ) { 
            $key = "$row:$col";
        }
        if ($xls_settings->{lookup}{$key}{option_count} == 1) { return $xls_settings->{lookup}{$key}{options}[0] }
        elsif ($xls_settings->{lookup}{$key}{option_count} > 1) { return '--select--' }
        else { return }
    }
    return;
}

##########################
sub _embed_lookup_table {
##########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $workbook = $args{-workbook};
    my $sheet = $args{-sheet};
    my $lookup_ref = $args{-lookup};
    my $col_offset = $args{-column_offset};
    my $new_sheet  = $args{-new_sheet};
    my $protected   = $args{-protected};

    my $lookup_sheet;
    my $default_offset;
    
    my $lookup_sheet;
    my $lookup_sheet_name = 'Lookup';
    if ($new_sheet) {
        $lookup_sheet = $workbook->add_worksheet($lookup_sheet_name);
        $default_offset = 0;
        $lookup_sheet->set_row(0,30);
    }
    else {
        $lookup_sheet = $sheet;
        $default_offset = 26;
    }
    
    if ($protected) { $lookup_sheet->protect() }

    my $headerformat = $workbook->add_format();
    $headerformat->set_bg_color('silver');
    $headerformat->set_bold(1);
    $headerformat->set_locked($protected);
    
    my $lookupformat = $workbook->add_format();
    $lookupformat->set_bg_color('cyan');
    $lookupformat->set_locked($protected);

    my $enumformat = $workbook->add_format();
    $enumformat->set_bg_color('yellow');
    $enumformat->set_locked($protected);
 
    my $col_counter;
    ## dynamically add lookup table information for specified reference columns ##
    foreach my $key (sort { $a <=> $b } keys %$lookup_ref) {
            my ($row,$col);
            if ($key =~ /(\d+):(\d+)/) { $row = $1; $col = $1; }
            elsif ($key =~ /^(\d+)/) { $row = 'N'; $col = $1; }
            else { Message("unknown key: $key"); next; }
            
            my $details = $lookup_ref->{$key};
       
            my $lookup_offset = $lookup_ref->{$key}{lookup_offset} || 0;
            $lookup_offset += $default_offset;

            my $lookup_column = $lookup_ref->{$key}{lookup_column} || '+' . $lookup_offset;  ## offset lookup tables to right of main columns
            my $lookup_start = $lookup_ref->{$key}{lookup_row} || $self->{header_row} || 2;  ## row to start lookup options
            
            my $start = $lookup_ref->{$key}{N_start};
            my $end   = $lookup_ref->{$key}{N_finish};      
            my $value = $lookup_ref->{$key}{value};
            my $title = $lookup_ref->{$key}{title};
            
            $col += $col_offset;
            
            my @options;
            if ($value) { 
                @options = _parse_options_from_html($value); 
                $lookup_ref->{$key}{options} ||= \@options; 
            }
            elsif ($lookup_ref->{$key}{options}) { @options =  @{$lookup_ref->{$key}{options}} }
    
            $lookup_ref->{$key}{option_count} = int(@options);

            $col_counter = $col_offset;
            if ($lookup_column =~/^\+(\d+)/) { 
                $col_counter = $1 + $col_offset;
                if (!$new_sheet) { $col_counter += $self->{columns} - 1 }   ## move to right if on same worksheet 
             }
            my $lookup_col = _column_lookup($col_counter);
                       
            ## populate the lookup table - even if it is not used ... ##
            my $i = $lookup_start;            
            if ($i > 1) { $lookup_sheet->write(0, $col_counter, $title, $headerformat); }
            
            auto_size_column($lookup_sheet, $col_counter, $title, -min=>5, -max=>40);
           
            my $length = int(@options);
            if ($length < 1) { next }
            
            my @rows;
            if ($row eq 'N') {
                ## if ref is N.5 (eg all rows for column 5) ##
                @rows = $start..$end;
                if (!$start || !$end) { Message("Error - no start supplied"); @rows = (); }
            }
            else {
                @rows = ($row);
            }
            
            my ($source, $comment, $format);
            if (int(@options) > 20 ) {
                $format = $lookupformat;
                $lookup_sheet->write_comment(0,$col_counter,"Lookup Table of $length options");
                my $lookup_end = $lookup_start + int(@options) - 1;  
                if ($new_sheet) {
                    ## this lookup reference does not seem to work with older versions of the API ... 
                    $source = "=$lookup_sheet_name!\$$lookup_col\$$lookup_start:\$$lookup_col\$$lookup_end"; 
                }
                else {
                     ## funky format required (not obvious from Excel documentation)  => $A$1:        $A$25 (ie 'A1:A25' doesn't work ! )
                    $source = "=\$$lookup_col\$$lookup_start:\$$lookup_col\$$lookup_end"; 
                }
            }
            else { 
                $format = $enumformat;
                $lookup_sheet->write_comment(0,$col_counter,"$length Options Enumerated");
                $source = \@options;
            }
           
            $format->set_locked($protected);
            foreach my $option (@options) {
                $lookup_sheet->write( $i-1, $col_counter, $option, $format );
                $i++;
            }            
           
            foreach my $r (@rows) {
                $sheet->write($r-1,$col-1,'');
                $sheet->data_validation( $r-1, $col-1, { validate => 'list', source => $source } );
            }
    }
    
    return $col_counter;
}

##########################
sub _embed_config {
##########################
    my $self = shift;
    my %args = filter_input(\@_);
    my $workbook = $args{-workbook};
    my $sheet = $args{-sheet};
    my $config_ref = $args{-config};
    my $col_offset = $args{-column_offset} || 0;
    my $colour     = $args{-colour} || 'yellow,lime';
    my $new_sheet  = $args{-new_sheet} || !$sheet;
    my $protected  = $args{-protected};
    my $config_sheet;
    my $default_offset;
    my $config_sheet_name= 'Config';
    if ($new_sheet) { 
        $config_sheet = $workbook->add_worksheet($config_sheet_name);
        $default_offset = 0;
    }
    else {
        $config_sheet = $sheet;
        $default_offset = 22;
    }
    
    if ($protected) { $config_sheet->protect() }
    
    my @colours = Cast_List(-list=>$colour, -to=>'array');
    my $key_colour = $colours[0];
    my $val_colour = $colours[1] || $key_colour;
   
    my $col = $config_ref->{offset} || $default_offset;     ## offset config settings to right of main columns (leave one blank column between lookup tables by default)
    my $row = $config_ref->{header_row} || '1';  
    $row--;                                      ## zero indexed rows 
    
    if (!$new_sheet) { $col += $self->{columns} }

    my $col2 = $col+1;
    $config_sheet->set_column($col,$col2,50);
    
    my $headerformat = $workbook->add_format();
    $headerformat->set_bg_color('silver');
    $headerformat->set_bold(1);
    $headerformat->set_locked($protected);
    
    my $keyformat = $workbook->add_format();
    $keyformat->set_bg_color($key_colour);
    $keyformat->set_locked($protected);
  
    my $valformat = $workbook->add_format();
    $valformat->set_bg_color($val_colour);
    $valformat->set_locked($protected);
   
    $config_sheet->write($row, $col, 'Parameter', $headerformat);
    $config_sheet->write($row, $col+1, 'Value', $headerformat);
    $row++;

    foreach my $key (sort { $a cmp $b } keys %$config_ref) {
   		my $list = $config_ref->{$key};
   		my @options;
   		if( $list ) {
   		   if ($list =~/array/i ){
	   		   @options = Cast_List( -list => $list, -to => 'array' ); ## array of values
   		   }  
   		   else{
   		      @options = ( $list );
      			
   		   } 
   		}
   		elsif( length( $list ) ) {	# value zero
   			@options = ( $list );
   		}

        foreach my $option (@options) { 
            $config_sheet->write($row, $col, $key, $keyformat);
            $config_sheet->write($row, $col2, $option, $valformat);
            $row++;
        }
    }

    return 1;
}

###############################
sub _parse_options_from_html {
###############################
    my $string = shift;
    my (@values, @labels);
    while ($string =~s/\<option value=\"(.*?)\"\>(.*?)\<\/option\>//) {
        push @values, $1;
        push @labels, $2;
    }
    return @values;
}
#
#
######################
sub _column_lookup {
######################
    my $counter = shift;
    
    my  $col = 'A';
    my  $prefix = '';
    my  $i = 0;
    while ($i < $counter) {
       if ($col =~/^(.*)([A-Z])$/) {
            my $c1 = $1;
            my $c2 = $2;
            
            if ($c2 eq 'Z') { 
                if ($c1 eq 'Z') { return 0 } ## overflow  ##
                if ($c1) { $c1++ }
                else { $c1 = 'A' }
                $c2='A';
            }
            else { $c2++ }
            $col = $c1 . $c2;
        }
        else { return 0 } 

        $i++;
    }
    
    return $col;
}

########################
# Allows for placer LINK tags in the script to be replaced by supplied links (supplied at a different time)
########################
sub _replace_links {
########################
    my %args     = @_;
    my $self     = $args{-self};
    my $thistext = $args{-text};
    my $link     = $self->{link_index} || $args{ -link };    ## link index
    my $filename = $args{-file};                             ## not sure why exactly ... but leave it for now..

    ## arguments below work more effectively for single field generation ##
    my $type    = $args{-type};
    my $name    = $args{-name};
    my $value   = $args{-value};
    my $label   = $args{-label};
    my $spec    = $args{-spec};
    my $tip     = $args{-tip};
    my $disable = $args{_disable};
    my $colour  = $args{-colour} || $self->{button_colour};

    if ( $type && $name ) {
        $thistext ||= 'LINK';
    }    ## temporary - to force through block below ...

    my $print_string = '';
    while ( $thistext =~ /(.*?)\bLINK\b(.*)/ ) {

        $print_string .= "$1";
        $thistext = $2;
        my $L_type     = $type    || $self->{LINK_type}[$link];
        my $L_name     = $name    || $self->{LINK_name}[$link];
        my $L_value    = $value   || $self->{LINK_value}[$link];
        my $L_label    = $label   || $self->{LINK_label}[$link];
        my $L_spec     = $spec    || $self->{LINK_spec}[$link];
        my $L_tip      = $tip     || $self->{LINK_tip}[$link];
        my $L_disabled = $disable || $self->{LINK_disabled}[$link];
        if ($filename) {
            $print_string .= $L_value;
        }
	elsif ($L_type =~ /uneditable/i) {
	    $print_string .= Show_Tool_Tip('---',"This field is non-editable.<BR>If blank, users may set the value using the single record edit form"); ## no edits';
	}
        elsif ( $L_type =~ /submit/ ) {
            my $buttonColour;
            if   ($L_label) { $buttonColour = $L_label; }
            else            { $buttonColour = $colour; }
            $print_string .= submit(
                -name  => $L_name,
                -value => $L_value,
                -style => "background-color:$buttonColour"
            );
        }
        elsif ( $L_type =~ /checkbox_group/ ) {
            if ($L_label) {
                $print_string .= checkbox_group(
                    -name      => $L_name,
                    -values    => [@$L_value],
                    -defaults  => [@$L_label],
                    -linebreak => 1,
                    -force     => 1
                );
            }
            else {
                $print_string .= checkbox_group(
                    -name      => $L_name,
                    -values    => [@$L_value],
                    -linebreak => 1,
                    -force     => 1
                );
            }
        }
        elsif ( $L_type =~ /list(\d*)/i ) {
            my $size = ( defined $1 ) ? $1 : 2;
            if ($L_label) {
                $print_string .= _show_Tool_Tip(
                    scrolling_list(
                        -name     => $L_name,
                        -values   => [@$L_value],
                        -defaults => [@$L_label],
                        -multiple => 2,
                        -force    => 1,
                        -size     => $size
                    ),
                    $L_tip
                );
            }
            else {
                $print_string .= _show_Tool_Tip(
                    scrolling_list(
                        -name     => $L_name,
                        -values   => [@$L_value],
                        -defaults => [],
                        -multiple => 2,
                        -force    => 1,
                        -size     => $size
                    ),
                    $L_tip
                );
            }
        }
        elsif ( $L_type =~ /checkbox_per_line/ ) {
            $print_string .= checkbox(
                -name      => $L_name,
                -value     => $L_value,
                -label     => $L_label,
                -onClick   => $L_spec,
                -linebreak => 1,
                -checked   => 0,
                -force     => 1
            );
        }
        elsif ( $L_type =~ /checkbox_on/i ) {
            $print_string .= checkbox(
                -name    => $L_name,
                -value   => $L_value,
                -label   => $L_label,
                -onClick => $L_spec,
                -checked => 1,
                -force   => 1
            );
        }
        elsif ( $L_type =~ /checkbox_off/ ) {
            $print_string .= checkbox(
                -name    => $L_name,
                -value   => $L_value,
                -label   => $L_label,
                -onClick => $L_spec,
                -checked => 0,
                -force   => 1
            );
        }
        elsif ( $L_type =~ /checkbox/ ) {
            if ($L_disabled) {
                $print_string .= checkbox(
                    -name     => $L_name,
                    -value    => $L_value,
                    -label    => $L_label,
                    -onClick  => $L_spec,
                    -disabled => $L_disabled
                );
            }
            else {
                $print_string .= checkbox(
                    -name    => $L_name,
                    -value   => $L_value,
                    -label   => $L_label,
                    -onClick => $L_spec
                );
            }
        }
        elsif ( $L_type =~ /popup/i ) {

            # Get maximum length of items
            my $max_length = 200;
            my $scale      = 7;

            foreach my $value (@$L_value) {
                my $len = length($value);
                $len *= $scale;
                if ( $len > $max_length ) { $max_length = $len }
            }
            $print_string .= _show_Tool_Tip(
                RGTools::Web_Form::Popup_Menu(
                    name     => $L_name,
                    id       => $L_name,
                    values   => [@$L_value],
                    default  => $L_label,
                    force    => 1,
                    onChange => $L_spec,
                    width    => $max_length,
                    disabled => $L_disabled
                ),
                $L_tip
            );
        }
        elsif ( $L_type =~ /box/i ) {
            my $rows;
            my $cols;
            if ( $L_value =~ /(\d+)\s?x\s?(\d+)/i ) { $rows = $1; $cols = $2; }
            $print_string .= _show_Tool_Tip(
                textarea(
                    -name    => $L_name,
                    -rows    => $rows,
                    -cols    => $cols,
                    -default => $L_label,
                    -force   => 1,
                    -wrap    => 'virtual'
                ),
                $L_tip
            );
        }
        elsif ( $L_type =~ /text/i ) {
            $print_string .= _show_Tool_Tip(
                textfield(
                    -name     => $L_name,
                    -size     => $L_value,
                    -default  => $L_label,
                    -force    => 1,
                    -onChange => $L_spec
                ),
                $L_tip
            );
        }
        elsif ( $L_type =~ /radio_per_line/i ) {
            $print_string .= radio_group(
                -name      => $L_name,
                -values    => [@$L_value],
                -default   => $L_label,
                -force     => 1,
                -onClick   => $L_spec,
                -linebreak => 1
            );
        }
        elsif ( $L_type =~ /radio/i ) {
            $print_string .= radio_group(
                -name    => $L_name,
                -values  => [@$L_value],
                -default => $L_label,
                -force   => 1,
                -onClick => $L_spec
            );
        }
        elsif ( $L_type =~ /reset/i ) {
            $print_string .= reset(
                -name   => $L_name,
                -values => $L_value,
                -style  => "background-color:$colour",
                -force  => 1
            );
        }
        elsif ( $L_type =~ /hidden/i ) {
            $print_string .= hidden( -name => $L_name, -value => $L_value, -force => 1 );
        }
        elsif ( $L_type =~ /toggle/i ) {
            $print_string .= checkbox(
                -name    => $L_name,
                -value   => $L_value,
                -label   => $L_label,
                -onClick => $L_spec
            );
        }
        elsif ( $L_type =~ /label/i ) {
            $print_string .= "$L_label";
            $print_string .= hidden( -name => $L_name, -value => $L_value );
        }
        else {
            $print_string .= "Link ($L_type)";
        }
        $self->{link_index}++;
    }
    $print_string .= $thistext;
    return $print_string;
}
##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

##############################
# Subroutine: Helper function that strips tags from a line
# return: none
##############################
sub _strip_tags {
###################
    my $value = shift;
    my $debug = shift;

    my $trimmed_value = $value;
    # do regexp to parse out special tags (<BR> gets replaced with a newline)
    $trimmed_value =~ s/<br\s*?\/?]>/\n/gi;

    require LampLite::HTML;
    # div and script tags, everything gets removed
    $trimmed_value = LampLite::HTML::clear_tags($trimmed_value, -trim_spaces=>1, -debug=>$debug, -clear_script=>1);

    return $trimmed_value;
}

###############
sub _show_Tool_Tip {
###############
    #
    # This enables tool tips, making use of the javascript file : DHTML.js
    #  (for this to work you MUST have the javascript file installed as well)
    #

    my $html_tag     = shift;
    my $tool_tip_msg = shift;    #The message of the tooltip.

    return Show_Tool_Tip($html_tag, $tool_tip_msg);   ## use standard method
    
    ## phase out below unless something special needs to be done still ##

    $tool_tip_msg =~ s/\'/\\\'/g;

    my $tool_tip;
    if ( ( defined $tool_tip_msg ) && ( $tool_tip_msg ne '' ) && ( $tool_tip_msg ne '0' ) ) {
        $tool_tip = qq{ onmouseOver="writetxt('$tool_tip_msg');" onmouseout="writetxt(0);">};
    }
    else {
        return $html_tag;        #Just return what was passed in
    }

    if ( $html_tag =~ /<\/\s*([a-zA-Z]+)\s*>[^>]*$/ ) {    #Looking for the ones with closing tags and grab the tag name.
        my $tag = $1;
        $html_tag =~ s/^(<\s*$tag[^<]*)>/$1$tool_tip/;
    }
    elsif ( $html_tag =~ /(>)[^>]*$/ ) {
        my $found = $1;
        $html_tag =~ s/$found/$tool_tip/;
    }

    #  "<A Href='#' style='text-decoration:none' >$html_tag<$tool_tip /A>";
    return "<div id='divToolTip' class='toolTipCont'><!--Empty div--></div><script type='text/javascript'>setToolTip()</script>$html_tag";
}

#############################
# Remove specified credential params (e.g. CGISESSID=abcd1234) from the input string.
#
# Usage:
#	my $stripped = remove_credential( -string => $string, -credentials => ['CGISESSID', 'PASSWORD'] );
#
# Return:
#	Scalar - string with specified credentials removed
#
#############################
sub remove_credential {
#############################	
    my %args = &filter_input( \@_, -args => 'string,credentials' );
    my $string = $args{-string};
    my $credentials = $args{-credentials};	# array ref or string
    my @to_remove = ();
    if( $credentials ) {
    	@to_remove = Cast_List( -list => $credentials, -to => 'array' );
    }
    foreach my $cre ( @to_remove ) {
    	if( $cre ) { $string =~ s/$cre=\w+//ig }
    }
	return $string;
}


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

2003-11-05

=head1 REVISION <UPLINK>

$Id: HTML_Table.pm,v 1.51 2004/12/09 17:43:47 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
