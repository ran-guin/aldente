###############################################################################
## Tools.pm
#
# This module provides tools that enable more powerful usage of functions available in alDente
#
################################################################################
# $Id: Tools.pm,v 1.9 2004/12/16 18:27:18 mariol Exp $
################################################################################
# CVS Revision: $Revision: 1.9 $
#     CVS Date: $Date: 2004/12/16 18:27:18 $
################################################################################
package alDente::Tools;
##############################
# superclasses               #
##############################
@ISA = qw(Exporter);
##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    Href
    alDente_ref
    initialize_parameters
    Load_Parameters
    Links
    printout
);
use strict;

use CGI qw(:standard);

# use alDente::Validation;

use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Directory;

use LampLite::HTML;
use LampLite::Bootstrap;

use SDB::CustomSettings;

use alDente::SDB_Defaults;

use vars qw(%Sess %Configs $Connection %table_barcodes %Field_Info);

my $q  = new CGI;
my $BS = new Bootstrap;
#########################
sub Search_Database {
#########################
    #
    # Search in standard tables for string...
    #
    # (This routine allows users unaccustomed to the database to search for a meaningful name)
    # - It supplies the number of matches found in various tables, hyperlinked to a detailed table showing these items.
    #
    #
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};    ## database handle
    my $input_string = $args{-input_string};                                                             ## search string
    my $search       = $args{-search} || $dbc->config('Search_DB');                                                                   ## hash indicating tables/fields to search
    my $pick_table   = $args{-pick_table};                                                               ## specify to search in only one table (optional)...
    my $verbose      = $args{-verbose};

    my %Search = %{$search};

    my @tables;
    if   ($pick_table) { @tables = ($pick_table); }
    else               { @tables = keys %Search; }

    my $search_condition = convert_to_condition( $input_string, '<field>', -range_limit => 1000 ) if $input_string;    ## generate Generic search condition string

    my $Results = HTML_Table->new();
    $Results->Set_Title("Search Results (looking for $input_string)");
    if ($pick_table) {
        $Results->Set_Headers( [$pick_table] );
    }
    else {
        $Results->Set_Headers( [ 'Table', 'Matches Found' ] );
    }
    

    my @total_found;
    print create_tree( -tree => { 'Fields searched:' => HTML_Dump $search}, -print => 0 );

    foreach my $table (@tables) {
        if ( !$dbc->table_loaded($table) ) {next}
        my @list = @{ $Search{$table} };
        my $idfield = join ',', $dbc->get_field_info( $table, undef, 'Primary' );

        unless ( $list[0] =~ /\w/ ) { next; }

        my @conditions;
        foreach my $check_field (@list) {
            my $this_condition = $search_condition;
            $this_condition =~ s /<field>/$check_field/g;
            push @conditions, "($this_condition)" if $check_field;
        }
        my $condition = join " OR ", @conditions;

        my @ids = $dbc->Table_find_array( $table, [ $idfield, @list ], "WHERE $condition" ) if $condition;
        my @id_list;
        my $found = 0;

        if (@ids) {
            unless ($pick_table) {
            }

            foreach my $id (@ids) {
                $id =~ /(.*?),/;
                my $this_id = $1;
                push( @id_list, $this_id );
                $found++;
                push @total_found, "$table:$this_id";
            }

            if ($pick_table) {    ### print out info on all ids found...
                print SDB::DB_Form_Viewer::view_records( $dbc->dbc, $pick_table, $idfield, join ',', @id_list );
                return int(@id_list);
            }
            elsif ( $found == 1 ) {    ### only one id found?
                $Results->Set_Row( [ "<B>$table</B>", &Link_To( $dbc->config('homelink'), $found, "&HomePage=$table&ID=$id_list[0]", $Settings{LINK_COLOUR} ) ] );
            }
            else {

                $Results->Set_Row( [ "<B>$table</B>", &Link_To( $dbc->config('homelink'), $found, "&Search+Database=1&Table=$table&DB+Search+String=$input_string", $Settings{LINK_COLOUR}, ['newwin'] ) ] );
            }
        }
    }

    my $page;
    if ( int(@total_found) == 1 ) {
        my ( $table, $id ) = split ':', $total_found[0];

        ## Customized ... need to remove this requirement somehow ##
        #### <CONSTRUCTION>
        ## Lists below are only for documentation while under construction... classifies tables retrieved under Search into groups... ##
        my @require_fixing = qw(Shipment Flowcell Run Invoice Sample Funding Project Stock Contact);    ## Home page generation needs upgrading
        my @fixed          = qw(Source Employee);                                                                                               ## home pages which have already been updatd (include list in Info::GoHome as well...)
        my @add_modules    = qw(Patient Standard Solution);                                                                                     ## Home pages should be generated (using new format)

        my %Map = (
            'Flowcell' => 'Sequencing::Flowcell',
            'Plate'    => 'alDente::Container',
        );

        my $class = 'alDente::' . $table;
        if ( $Map{$table} ) {
            $class = $Map{$table};
        }

        my $module = $class;
        $module =~ s/.+:://;

        if ( !-e "/opt/alDente/versions/ll/lib/perl/Core/alDente/$module.pm" ) {
            ## Objects which do not currently have dedicated MVC modules - just dump the record information ... ##
            #            $dbc->message("Use default page generator for $class");
            my ($primary) = $dbc->get_field_info( -table => $table, -type => 'Primary' );
            $page = subsection_heading("Found $table record [$id]");
            $page .= &SDB::DB_Form_Viewer::view_records( $dbc, $table, $primary, $id );
        }
        else {
            if ( grep /\b$table\b/, @require_fixing ) {
                ### Bypass new logic temporarily for home pages generated via search run mode that have not yet been updated, but require non-standard home pages ##
                $dbc->debug_message("$table should be updated to enable standard home page usage");
            }
            my $Object = $class->new( -dbc => $dbc, -id => $id );
            $page = $Object->View->std_home_page( -dbc => $dbc, -table => $table, -id => $id );    ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##
        }
    }
    else {
        $page = $Results->Printout(0);
    }
    
    if (@total_found == 1) { $dbc->message("Found one record matching '$input_string'") }
    elsif   (@total_found) { $dbc->message("Search string: '$input_string'<P>Note: To broaden search, you may use wildcards (eg '*'), however <B>query may be VERY slow if a wildcard is used at the START of the string</B>") }
    else                { $dbc->warning("Tried looking for: '$input_string'<P>Nothing found: Try using a wildcard ('*' for any number of characters) or ('?' for any single character)") }

    return $page;

    # return @total_found;

    # $results;
}

####################
sub search_code {
####################
    my %args          = @_;
    my $path          = $args{'path'};
    my $file          = $args{'filename'};
    my $search        = $args{'search'};
    my $output_file   = $args{'output'};
    my $searchsection = $args{'search_area'} =~ /comment/i;
    my $searchroutine = ( $args{'search_area'} =~ /routine/i ) || $searchsection;
    my $list          = $args{'list'};
    my $format        = $args{'format'} || 'html';
    my $method        = $args{'method'};
    my $section       = $args{'section'};

    my $break = '<BR>' if ( $format =~ /html/i );

    my $suffix = '';
    if    ($list)   { $suffix = ".list"; }     ### just list routines..
    elsif ($method) { $suffix = ".$method" }

    my $Table;

    ## allow custom filter for allowing certain lines of code within parameter block (used in REGEXP) ##
    my $ignore_filter = "->log_parameters|{ERRORS}";

    if ($search) {
        $Table = HTML_Table->new();
        $Table->Set_Prefix("<P>");
        $Table->Set_Suffix("<HR>");
        $Table->Set_Headers( [ 'Module : Routine', 'Parameters', 'Defaults', 'Comment' ] );
        $Table->Set_Title("$path with $search");
        $Table->Set_Line_Colour('white');
        $Table->Set_Border(1);
        $Table->Set_Class('small');
    }

    my $output;    # = &Views::Heading("Searching $path/$file");
    unless ($search) {
        $Table = HTML_Table->new();

        #	    $Table->Set_Suffix("<HR>");
        if ($section) {
            $Table->Set_Headers( [$section] );
        }
        else {
            $Table->Set_Headers( [ 'Routine', 'Parameters', 'Defaults', 'Comment' ] );
        }
        $Table->Set_Title("$path/$file");
        $Table->Set_Line_Colour('white');
        $Table->Set_Border(1);
        $Table->Set_Class('small');
    }

    my $prefix = '';

    my $found        = '';
    my $perldoc_path = "/opt/alDente/versions/rguin/www/html/perldoc";

    #    $output .= "Open $path/$file\n";
    open my $THISFILE, '<', "$path/$file" or die "error opening $path/$file\n";

    if ($section) {
        my $in_section   = 0;
        my $section_text = '';
        while (<$THISFILE>) {
            my $line = $_;
            if ( $line =~ /^\=head1 (\w+)/ ) {
                my $section_name = $1;
                if ( $section_name eq $section ) {
                    $in_section++;
                }
                elsif ($section_text) {
                    ### already found section of interest...
                    last;
                }
            }
            elsif ( $line =~ /^=\w+/ ) {
                ## entered next section ...
                if ($in_section) {last}
            }
            elsif ($in_section) {
                $section_text .= $line;
            }
            else {
                next;
            }
        }
        unless ($section_text) {
            $section_text = "(no $section section found)";
        }
        $Table->Set_Line_Colour('lightgrey');
        $Table->Set_Row( [ "<PRE>" . $section_text . "</PRE>" ] );
    }
    else {
        while (<$THISFILE>) {
            my $line = $_;

            ## convert tag items in code to be viewable via html ##
            $line =~ s/</&lt /g;
            $line =~ s/>/&gt /g;

            if ( $line =~ /^\s*\#+(.*)/ ) {
                $prefix .= substr( $line, 1, length($line) );
            }
            elsif ( $line =~ /^sub\s+(\S+)/ ) {    ### found new subroutine...
                my $routine = $1;

                if ( $method && ( $routine !~ /^$method$/ ) ) {next}
                my $header       = $routine;
                my $perldoc_name = $file;
                $perldoc_name =~ s/\.pm$/\.html/;
                my $link = $file;
                if ( -e "$perldoc_path/$perldoc_name" ) {
                    $link = "<A Href='/$perldoc_path/$perldoc_name'>$file</A>";
                }
                else { $link = "$file"; }

                if ($search) { $header = "$link : $routine"; }    ### be more specific if listing for all routines...
                $found .= "Routine: $header\n************************************\n";
                my $Pnum    = 0;
                my $comment = $prefix;
                $prefix = '';                                     ## reset for next subroutine
                my @parameter;
                my @Pvalue;
                my @Pcomment;
                my @Plist;

                #		$Table->Set_Row([$routine],'lightredbw');
                my $end = 0;

                my $commented_parameters = 0;
                my $section;
                my $args_hash = 'args';
                my %comment_after;
                while ( !$end ) {
                    ### as long as we are in the comment section of this routine...
                    #
                    # the keyword 'args' is expected below when passing a hash of arguments.  (this may be adjusted)..
                    #
                    $line = <$THISFILE>;
                    if ( $line =~ /%(\w+)\s*=\s*&?filter_input\(/ ) { $args_hash = $1; $found .= "Arg: $args_hash<BR>"; next; }
                    elsif ( $line =~ /($ignore_filter)/ )  {next}       ## ignore specific indicated strings if included in parameter block
                    elsif ( $line =~ /$args_hash\{ERROR/ ) { next; }    ## skip over argument error checking

                    $section .= $line;

                    if ( $line =~ /^\s*\#+\s*(.*)\s*\#*/ ) {            ## if it is commented out...
                        if ($Pnum) {
                            $comment_after{$Pnum} = $1;
                        }
                        else {
                            $comment .= "$1" . $break;
                        }
                    }
                    elsif ( $line =~ /(\S+)\s*=\s*([defined]*\s*[\@\$\%\{]+$args_hash|Cast_List|self\->|shift|Option|\$_|\@_)(.*)\;\s*\#*(.*)/i ) {
                        $parameter[$Pnum] = $1;
                        $Pvalue[$Pnum]    = "$2$3";
                        $Pcomment[$Pnum]  = $4;
                        if ( $Pcomment[$Pnum] || $Pvalue[$Pnum] ) { $commented_parameters++; }
                        chomp $parameter[$Pnum];
                        chomp $Pvalue[$Pnum];
                        chomp $Pcomment[$Pnum];
                        push( @Plist, $parameter[$Pnum] );
                        $Pnum++;
                    }
                    elsif ( !( $line =~ /\S/ ) ) { next; }
                    elsif ( $line =~ /^\#/ ) { next; }
                    else                     { $end = 1; }
                }
                my $parameters = join ", ", @Plist;

                if ( !$search || ( $searchsection && $section =~ /$search/i ) || ( $searchroutine && $routine =~ /$search/i ) ) {
                    $Table->Set_Row( [ "<B>$header</B>", $parameters ], 'lightredbw' );    ## 'bgcolor=AACCFF' );
                    if ( $comment =~ /[a-z]+/ ) {                                           ## use upper case for html tags (<BR>)
                        $comment =~ s/\n/<BR>/g;
                        $Table->Set_sub_header( $comment, 'vlightbluebw', 'class=small' );
                    }
                    if ( $commented_parameters && !$list ) {
                        foreach my $index ( 1 .. $Pnum ) {                                  ### print parameter comments
                            $found .= "\t\t$parameter[$index-1]\t$Pvalue[$index-1]\t$Pcomment[$index-1]\n";
                            $Table->Set_Row( [ '', $parameter[ $index - 1 ], $Pvalue[ $index - 1 ], $Pcomment[ $index - 1 ] ] );
                            $Table->Set_sub_header( $comment_after{$index}, 'vlightgrey' ) if defined $comment_after{$index} && ( $index < $Pnum );    ## not for the last parameter (nothing should follow it)
                        }
                    }
                }
            }
            else { $prefix = '' }                                                                                                                      ## reset
        }
    }
    close($THISFILE);

    if ($output_file) {
        if ( $search && $Table->{rows} ) {
            $output .= Views::Heading("$file");
            $output .= $Table->Printout("$Configs{URL_temp_dir}/$output_file.search.html");
            $output .= $Table->Printout(0);
        }
        elsif ( $Table->{rows} ) {
            if ( $method && !$section ) {
                $output .= Views::Heading("\$self -> $method");
            }
            else {
                $output .= Views::Heading("$file");
            }
            $output .= $Table->Printout("$Configs{URL_temp_dir}/$output_file.$file.$method.$suffix.html");
            $output .= $Table->Printout(0);
        }
    }
    else {
        my $rows = $Table->{rows};
        my $cols = $Table->{columns};
        if ( $rows || $cols ) {
            $output .= "$file: $rows x $cols table generated... \n";
            $output .= "*" x 64;
            $output .= "\n";

            $output .= join "\t", @{ $Table->{header_labels} };
            $output .= "\n";
            $output .= "_" x 64;
            $output .= "\n";

            foreach my $row ( 1 .. $rows ) {
                foreach my $col ( 1 .. $cols ) {
                    my $column = $col - 1;
                    my $cell   = $Table->{"C$column"}[ $row - 1 ] . "\t";
                    $cell =~ s/<BR>/\n/g;
                    $output .= $cell;
                }
                $output .= "\n";
            }
        }
    }

    return $output;
}

###################
#
# This adds a search / filter options (with filter option)
# (otherwise sets up a textfield which will search an associated popdown menu)
#
# Example:
#  &search_filter(-name=>'FK_Barcode_Label__ID',-default=>$def_barcode,-option_condition=>"Barcode_Label_Type = 'solution'",-filter=>1,-breaks=>1)]
#
# Options:
#   -break => 1   (include linebreak)
#   -option_condition => ..  (include condition when auto-setting options (uses get_FK_info(-list=>1) for form name
#   -name => ..              (name of textfield (should be same as field name for foreign key lookups)
#
#
####################
sub search_list {
####################
    my %args = filter_input( \@_, -args => 'dbc,form,name,default' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    ## required to enable automatic searching (not necessary if options supplied explicitly)
    my $name  = $args{-name}  || $args{-field} || 'SearchField';                                ## name of field (use FK_.. for foreign keys)
    my $field = $args{-field} || $name         || 'SearchField';                                ## name of field (use FK_.. for foreign keys)
    my $id               = $args{-id};                                                                  ## unique id
    my $record           = $args{-record};                                                              ## optional record value (to enable context based FK_info_list)
    my $table            = $args{-table};
    my $default          = $args{-default};                                                             ## supplying id is sufficient for fk_view dropdown lists
    my $prefix           = $args{-prefix};
    my $search           = $args{-search};                                                              ## enable searching (if this and filtering is off, then only text field may be available)
    my $filter           = $args{-filter};                                                              ## enable filtering (default value if applicable)
    my $new              = $args{-new};                                                                 ## enable specification of new item name
    my $no_list          = $args{-no_list} || 0;                                                        ## suppress list (no popdown menu) - this overrides filtering / search options
    my $no_text          = $args{-no_text};                                                             ## suppress textfield (only popdown menu) - this overrides filtering / search options
    my $options          = $args{-options};                                                             ## array reference to the options for the dropdown list
    my $option_condition = $args{-condition} || $args{-option_condition} || '1';                        ## condition from which to generate option list from full fk list
    my $join_tables      = $args{-join_tables};
    my $join_condition   = $args{-join_condition} || 1;
    my $breaks           = $args{-breaks} || 0;                                                         ## line breaks (when breaks=1, a linebreak follows radio options)
    my $tips_off         = $args{-no_tips};                                                             ## suppresses tool_tip options (may be helpful for scanner_mode)
    my $new_ok           = $args{-new_ok} || 0;                                                         ## allow user to enter a NEW entry in the text field (may warn if similar entries exist
    my $tips             = $args{-tip};                                                                 ## valid keys: Search, Text, Filter, New, List  eg -tip=>{'New'='new name','Text'=>'try..'}
    my $mode             = $args{-mode};
    my $sort             = $args{ -sort };                                                              ## sort the output list..
    my $smart_sort       = $args{-smart_sort};                                                          ## sort the output list by ID number (even if the list contains letter prefixes
    my $filter_by_dept   = $args{-filter_by_dept};                                                      ## Values are filtered based on the $args{-department} or $Current_Department
    my $foreign_key      = $args{-foreign_key};                                                         ## force search of foreign key (not necessary if foreign_key check of field name returns true)
    my $mask             = $args{-mask};
    my $fk_extra         = $args{-fk_extra} || [];
    my $width            = $args{-width};
    my $short_list_size  = $args{-short_list_size} || 70;                                               ## length at which simple dropdown menu is automatically supplied with Search / Filter option
    my $long_list_size   = $args{-long_list_size} || $Settings{FOREIGN_KEY_POPUP_MAXLENGTH} || 1000;    ## length at which filter list is replaced with text field (autocomplete)
    my $debug            = $args{-debug} || 0;
    my $onchange         = $args{-onchange} || $args{-onChange};                                        ## optional onChange action
    my $onclick          = $args{-onclick} || $args{-onClick};                                          ## optional onclick action
    my $element_name     = $args{-element_name} || $name;                                               ## override element name (defaults to name (of field))
    my $scroll           = $args{-scroll};                                                              ## scrolling box size (if applicable)
    my $columns          = $args{-columns} || 6;                                                        ## checkbox columns (if applicable)
    my $size             = $args{-size};                                                                ## length of scrolling list (or columns of checkboxes if applicable)
    my $list_only        = $args{-list_only};
    my $action           = $args{-action};                                                              ## adjust depending upon context (eg search or update or append) ##
    my $prompt           = $args{-prompt} || '';                                                        ## initial prompt eg ('-- Select Project --')
    my $quote            = $args{-quote};

    my $autofill         = $args{-autofill};   ## flag to indicate autofill option... this results in blank values to default to '' 

    my $class      = $args{-class};    ## class specification for element (particularly for textfield element sizes eg narrow-txt, wide-txt, superwide-txt) - see custom bootstrap css file for specs.
    my $short_list = 0;
    my $large_list = 0;

    my $Autoquery;
    my $AQ_condition;                  ## encoded version of condition...

    #########################
        eval "require LampLite::Form";
        my $F = new LampLite::Form(-dbc=>$dbc);

        if ($scroll || ($mode eq 'scroll')) { $action = 'search' }

        if ($field =~ /\bFK/) { 
            
            ## Need to adapt old usage (using FK_info values instead oF IDs with info labels) ##
            if ($default && $default !~/^\d+$/) { 
                ## convert readable reference back to id ## 
#                 $dbc->debug_message("supply condition or ids instead of FK info list (default = $default) for $table.$field");
                 $default = $dbc->get_FK_ID($field, $default);
            }
            if ($options && grep /\D/, $options) {
                $options = $dbc->get_FK_ID($field, $options);
#                $dbc->debug_message("supply condition or ids instead of FK info list for $table.$field")
             }  
        }  ## clear default if using FK - deprecating fk_info used as value for dropdowns ... 

        my $include = $fk_extra->[0];
        my ($prompt, $element) = $F->View->prompt(-dbc=>$dbc, -table=>$table, -field=>$field, -tooltip=>$tips, -context=>$action, -autofill=>$autofill, -options=>$options, -name=>$element_name, -condition=>$option_condition, -default=>$default, -list_type=>$mode, -class=>$class);

        return $element;

        ## Phase out older usage of search_list to use standard format ## 

        # Note: some functionality included below may need to be phased in (or removed) as required 

    #########################

    my @Cache = ('Library.Library_Name');    ## define in configuration settings to speed up loading of these options...

    require MIME::Base32;
    my $encoded_condition      = MIME::Base32::encode($option_condition) if ($option_condition);
    my $encoded_join_condition = MIME::Base32::encode($join_condition)   if ($join_condition);

    my $cache_name;
    if ( grep /^$name$/, @Cache && ( $option_condition eq '1' ) ) {
        $cache_name = $name;
        if ($filter_by_dept) { $cache_name .= '.' . $dbc->config('Target_Department') }
        if ( defined $dbc->{cache_list}{$cache_name} ) { $options = $dbc->{cache_list}{$cache_name}; }
    }

    if ( $action eq 'search' ) { $mode = 'Scroll' }
    else                       { $mode ||= 'Popup' }

    if ( $action =~ /edit/i && !$options ) {
        $options = $dbc->get_Breakaway_Options( -field => $field, -table => $table, -default => $default );
    }

    $filter_by_dept = 0 unless $Configs{department_tracking};
    my @fk_extra = @{$fk_extra} if ($fk_extra);
    my @Mask     = @{$mask}     if ($mask);

    my $structname;
    if   ( $name && $table ) { $structname = "$table.$name" }
    else                     { $structname = $name }

    my $SL_size          = $scroll;
    my $checkbox_columns = $columns;
    my $ajax_scroll      = 0;

    my @defaults;

    if ( $default =~ /HASH/i || $default =~ /ARRAY/i ) {
        ## These lines were added to avoid problems when record has comma in it
        @defaults = Cast_List( -list => $default, -to => 'Array' );
    }
    elsif ($default) {
        push @defaults, $default;
    }

    my $output = $prefix;
    my $textfield;

    if ($no_list) {
        ## do not provide option list - just a textfield ##
        $textfield = Show_Tool_Tip( textfield( -name => $element_name, -value => $default, -size => $size, -class => $class ), "Use wildcard * for searching if necessary" ) . "\n";
        $output .= "\n$textfield\n";
        return $output;
    }
    my $department = $args{-department} || $dbc->session->param('Target_Department') || $Current_Department;
    if ( $filter_by_dept =~ /\D/ ) {

        #explicit passing in department by the filter_by_dept argument, so reset $department to the filter_by_dept argument
        $department = $filter_by_dept;
    }

    my $dept_join_tables;
    my $dept_join_condition;
    my $dept_option_condition;

    ## Ajax autocomplete should have dept filtering off no matter what, so store
    ## that part of the query in case it has to be removed

    if ( $department && $filter_by_dept ) {

        #<CONSTRUCTION> Hard-code department relation right now, the below should use a new table Department_Relationship to be more generalize
        if ( $department eq 'UHTS' ) { $department = "'Lib_Construction','UHTS'" }
        if ( $name =~ /FK_Library__Name|Library_Name/i ) {
            $dept_join_tables      = join( ',', ( 'Grp', 'Department' ) );
            $dept_join_condition   = ' AND Library.FK_Grp__ID=Grp_ID AND Grp.FK_Department__ID=Department_ID';
            $dept_option_condition = " AND Department_Name IN ('$department','Public')";
        }
        elsif ( $name =~ /FK_Project__ID|Project_ID/i ) {
            $dept_join_tables = join( ',', ( 'Grp', 'Department', 'Library' ) );
            $dept_join_condition   .= ' AND Library.FK_Grp__ID=Grp_ID AND Grp.FK_Department__ID=Department_ID AND Library.FK_Project__ID=Project_ID';
            $dept_option_condition .= " AND Department_Name IN ('$department','Public')";
        }
        elsif ( $name =~ /FK_Pipeline__ID|Pipeline_ID/i ) {
            $dept_join_tables = join( ',', ( 'Grp', 'Department' ) );
            $dept_join_condition   .= ' AND Pipeline.FK_Grp__ID=Grp_ID AND Grp.FK_Department__ID=Department_ID';
            $dept_option_condition .= " AND Department_Name IN ('$department','Public')";
        }

        $dept_join_tables = "," . $dept_join_tables if $join_tables;

        $join_tables      .= $dept_join_tables;
        $join_condition   .= $dept_join_condition;
        $option_condition .= $dept_option_condition;
    }

    my @option_list;
    my $help;

    if ($options) {
        @option_list = @$options;
    }
    elsif ( $dbc->foreign_key_check($name) || $foreign_key || ( $field eq 'Library_Name' && $table eq 'Library' ) ) {
        #### Custom code
        $foreign_key ||= $name;
        if ( $foreign_key =~ /Rack_ID|Rack__ID/i ) {
            $option_condition .= " AND Rack_Type <> 'Slot'";
        }
        elsif ( $foreign_key =~ /Barcode_Label__ID/i ) {
            my $barcode_tables = &autoquote_string( $table_barcodes{$table} );
            $option_condition .= " AND Barcode_Label_Type in ($barcode_tables)" if ($barcode_tables);
        }
        elsif ( $foreign_key =~ /Primer__Name|Primer__ID/i ) {
            $option_condition .= " AND Primer_Type IN ('Standard','Adapter')";
        }
        elsif ( $foreign_key =~ /Library__Name/ && $dbc->config('visible_Projects') && $Sess->{projects} !~ /All Projects/ ) {
            my $project_list = Cast_List( -list => $dbc->config('visible_Projects'), -to => 'String' );
            $option_condition .= " AND FK_Project__ID IN (" . $dbc->config('visible_Projects') . ')';
        }
        elsif ( $foreign_key =~ /Pipeline__ID|Pipeline_ID/i ) {
            if ( !$search ) { $option_condition .= " AND Pipeline_Status = 'Active'" }    ## exclude this filter if searching
        }
        elsif ( $foreign_key =~ /Funding__ID|Funding_ID/i ) {
            if ( !$search ) { $option_condition .= " AND Funding_Status NOT IN ('Terminated', 'Closed', 'On Hold')" }    ## exclude this filter if searching
        }

        ### end custom code
        my %Field_info     = $dbc->Table_retrieve( 'DBField', [ 'Field_Options', 'List_Condition' ], "WHERE Field_Name like '$name' and Field_Table = '$table'", -debug => $debug );
        my $searchable     = $Field_info{Field_Options}[0];
        my $list_condition = $Field_info{List_Condition}[0];    ### Accounted for in LampLite... ###

        if ( $list_condition && ( $action ne 'search' ) ) {
            $list_condition =~ s/^<[\w\.]+>\s?\=\s?[\w\.]+/1/;

            ## skip dynamically generated list conditions ##
            $option_condition .= " AND $list_condition";
        }
 
        ## get a count of the fk values
        my $context;
        my $fk_count = $dbc->get_FK_info(
             $foreign_key,
            -condition      => $option_condition,
            -join_tables    => $join_tables,
            -join_condition => $join_condition,
            -list           => 1,
            -fk_count       => 1,
            -context        => $context,
            -debug          => $debug
        );

        if ($record) {
            ### Add context specific checking if applicable (passes context on to SDB::DBIO::get_view for applicable filtering of lists)
            $context = { $table => $record };
        }

        ## If autocomplete is wanted, remove the dept filtering
        if ( ( ( $fk_count >= $long_list_size ) || ( $field eq 'Library_Name' && $table eq 'Library' ) ) && ( lc($mode) eq 'popup' || lc($mode) eq 'scroll' ) ) {    ## foreign key count is too large or searching by Library_Name
            $ajax_scroll = 1;
            $join_tables      =~ s/\Q$dept_join_tables\E//;
            $join_condition   =~ s/\Q$dept_join_condition\E//;
            $option_condition =~ s/\Q$dept_option_condition\E//;
        }
        elsif ( $fk_count >= $long_list_size ) {

            my ($searchable) = $dbc->Table_find( 'DBField', 'Field_Options', "WHERE Field_Name like '$name' and Field_Table = '$table'" );
            ## only generate full list if table is explicitly flagged as searchable ##
            if ( $searchable =~ /Searchable/ ) {
                @option_list = $dbc->get_FK_info(
                     $foreign_key,
                    -condition      => $option_condition,
                    -join_tables    => $join_tables,
                    -join_condition => $join_condition,
                    -list           => 1,
                    -context        => $context,
                    -debug          => $debug
                );
            }
            else {
                ## force to textfield
                $textfield
                    = Show_Tool_Tip( textfield( -name => $element_name, -value => $default, -size => $size, -class => $class ), "$structname list too long (> $long_list_size) $searchable - must supply id only (or request that field be made searchable)" )
                    . "\n";
                $output .= "\n$help\n$textfield\n";
                return $output;
            }
        }
        else {
            ## reference list ##

            if ( 1 || $dbc->scanner_mode ) {
                ## generate dynamically with ajax if this list is long to improve performance ##
                @option_list = $dbc->get_FK_info(
                     $foreign_key,
                    -condition      => $option_condition,
                    -join_tables    => $join_tables,
                    -join_condition => $join_condition,
                    -list           => 1,
                    -context        => $context,
                    -debug          => $debug
                );
            }
            else {
                $Autoquery = $dbc->get_FK_info(
                     $foreign_key,
                    -condition      => $option_condition,
                    -join_tables    => $join_tables,
                    -join_condition => $join_condition,
                    -list           => 1,
                    -context        => $context,
                    -debug          => $debug,
                    -get_query      => 1,
                );
                $AQ_condition = MIME::Base32::encode( $Autoquery->{Condition} );
            }
        }
    }
    else {
        my ( $table, $local_name ) = SDB::DBIO::simple_resolve_field($structname);
        my @enum_options = get_enum_list( $dbc, $table, $local_name );
        if (@enum_options) {
            ## if enum set option_list to enum list ##
            @option_list = @enum_options;
        }
        else {
            ## else find distinct values in this field ##
            # There is a problem with $dbc->config('visible_Projects')
            my $visible = $dbc->config('visible_Projects');
            
            if ($visible) {
                my $project_list = Cast_List( -list =>$visible, -to => 'String' );
                if ( $name =~ /\bLibrary_Name$/ && $dbc->config('visible_Projects') ) {
                    $option_condition .= " AND FK_Project__ID IN ($project_list)";
                }
            }

            my $tables = $table;
            unless ($tables) { print HTML_Dump( $table, $name ); Call_Stack(); }
            $tables           .= ",$join_tables"        if $join_tables;
            $option_condition .= " AND $join_condition" if $join_condition;

            ## generate with ajax if this list is long ##

            # Message("Tables: $tables,\n, Field: $name,\n option condition: $option_condition\n");
            @option_list = $dbc->Table_find( $tables, $name, "WHERE $option_condition", -distinct => 1 );
        }

    }
 
    if ($cache_name) { $dbc->{cache_list}{$cache_name} = \@option_list }    ## Cache list of options

    if ($sort) {
        ## sort options
        @option_list = sort(@option_list);
    }
    if ($smart_sort) {

        #	    @option_list = RGmath::smart_sort(@option_list);
        @option_list = sort(@option_list);
    }

    if ($list_only) {
        return \@option_list;
    }

    #### Check if mask is specified
    if (@Mask) {
        my @new_list;
        foreach my $item (@option_list) {
            foreach my $mask (@Mask) {
                if ( $item =~ /$mask/ ) {
                    push( @new_list, $item );
                    last;
                }
            }
        }
        @option_list = @new_list;
    }
    #### Check if Extra FK's provided
    if (@fk_extra) {
        push( @option_list, @fk_extra );
    }

    my $no_valid_options;    ## flag to indicate no valid options found

    $dbc->Benchmark('finish_scroll');
    if ( !$ajax_scroll ) {
        ## Skip option attributes for ajax list

        if ( int(@option_list) == 1 ) {
            ## set default only if only one option (but use popup menu to enable auto-update using NewLink)
            $short_list = 1;
            $default    = $option_list[0];
        }
        elsif ( int(@option_list) == 0 ) {
            if ( !$Autoquery ) { $no_valid_options = 1 }
        }
        elsif ( int(@option_list) < $short_list_size && !$new ) {
            ## list particularly short ##
            if ( ( $mode eq 'scroll' ) && int(@option_list) > 2 ) {
                ## leave search filtering on for scrolling lists ##
            }
            else {
                $short_list = 1;
            }
        }
        elsif ( int(@option_list) > $long_list_size ) {
            $large_list = 1;
        }
        else {
            ## normal medium length list ##
        }
    }

    for ( my $i = 0; $i < scalar @defaults; $i++ ) {
        my $key = $defaults[$i];
        if ( !( grep /^\Q$key\E$/, @option_list ) ) {
            my $new_key = $dbc->get_FK_info($name, -id => $key, -debug => $debug );
            $defaults[$i] = $new_key;
        }
    }

    if ( ( $no_valid_options || $no_text ) && !$new ) { $search = 0; $filter = 0; }

    my $objid;
    my $randnum = rand();

    if ($id) {
        $objid = $id;
    }

    #
    #    the block below should be commented out - otherwise multiple element ids may conflict on the same page (even in different forms)
    #
    #    elsif ($element_name) {
    #        $objid = $element_name;
    #    }
    else {
        $objid = rand();

        # get the eight least significant figures
        $objid = $name . substr( $objid, -8 );
        $randnum =~ s/0\.//;    # change to int...
        $objid .= $randnum;
    }

    my $force_ok = $new_ok ? 0 : 1;
    my ( $reset_action, $on_blur );

    if ($ajax_scroll) {
        my $dbase = $dbc->{dbase};
        my $host  = $dbc->{host};
        my $field = $foreign_key || $name;

        my $URL = $dbc->config('URL_dir_name') || 'SDB';
        my $ajax_url = "/$URL/cgi-bin/ajax/query.pl" . "?Database_Mode=$dbc->{mode}" . "&Table=$table&Field=$field" . "&Global_Search=1&Autocomplete=1&Condition=$encoded_condition&Join_Tables=$join_tables" . "&Join_Condition=$encoded_join_condition";
        $on_blur = "if (trim(this.value).length >= 3) { dependentFilter(this.id,\'$ajax_url\',this.id, 1); } $onchange";

        #$on_blur = "LongListMenuSearch(this,\'$ajax_url\',$force_ok); $onchange";
        $search = 0;
    }
    else {
        $reset_action = "repopulate_list(this)";
        if ($Autoquery) {
            $reset_action = "populate_list('$objid.Choice', '/$URL_dir_name/cgi-bin/ajax/query.pl', \"$Autoquery->{Table}\", \"$Autoquery->{Field}\", \"$AQ_condition\", true);";
        }

        $on_blur = "MenuSearch2(this,$force_ok); $onchange";
    }

    my ( $tip1, $tip2, $tip3, $tip4, $tip5 );
    unless ($tips_off) {
        if ( ref $tips eq 'HASH' ) {
            $tip1 = $tips->{Search};
            $tip2 = $tips->{Filter};
            $tip3 = $tips->{New};
            $tip4 = $tips->{List};

            if ( $search || $filter ) {
                ## was xor ... not sure why ...
                $tip5 = $tips->{Text};
            }
        }
        else {
            ( $tip1, $tip2, $tip3, $tip4, $tip5 ) = map {$tips} ( 1 .. 5 );
        }

        $tip1 ||= "Search list for string entered in text field";
        $tip2 ||= "Reduce list to items containing string entered in text field\n\n(if nothing returned, click on Search button to regenerate original dropdown list)";
        $tip3 ||= "Choose this option to turn search/filtering off (eg when you are entering a brand new stock name)";
        if ( %Field_Info && defined $Field_Info{$table} && defined $Field_Info{$table}{$field} ) {
            $tip4 ||= $Field_Info{$table}{$field}{Description};
        }
        if ( $action eq 'search' ) {
            $tip5 ||= "Type string to search for available options";
        }
        else {
            $tip5 ||= 'Type string to search for available options';
        }

    }

    my $element_name_choice;    ##

    if ( $search || $filter ) {
        if ( $action =~ /search/i && !$search ) {
            $textfield = $textfield = Show_Tool_Tip(
                textarea(
                    -name       => $element_name,
                    -value      => '',
                    -rows       => 2,
                    -cols       => $size,
                    -onBlur     => $on_blur,
                    -force      => 1,
                    -id         => "$objid",
                    -structname => $structname
                ),
                $tip5
            );
        }
        else {
            my $populate;

            if ($Autoquery) {
                my $cond = MIME::Base32::encode( $Autoquery->{Condition} );
                $populate = "populate_list('$objid.Choice', '/$URL_dir_name/cgi-bin/ajax/query.pl', \"$Autoquery->{Table}\", \"$Autoquery->{Field}\", \"$AQ_condition\");";
            }
            if ( ( $ajax_scroll ) && !$search ) {
                $textfield = Show_Tool_Tip(
                    textfield(
                        -name       => $element_name,
                        -value      => '',
                        -size       => $size,
                        -onBlur     => $on_blur,
                        -force      => 1,
                        -id         => "$objid",
                        -structname => $structname,
                        -onclick    => $populate,
                        -class      => $class,
                    ),
                    $tip5
                );
            }
        }

        if ($ajax_scroll) {
            my $indicator_id = "indicator_" . $objid;
            $indicator_id =~ s/\./_/g;
            if ( $breaks > 1 ) { $textfield .= '<BR>' }
            $textfield .= " (Auto Completed)";
            $textfield .= "<span class='ajax_indicator' style='display:none' id='$indicator_id' ><img src='/$URL_dir_name/images/icons//ajax_working_indicator.gif' alt='Working...' /></span>";
            $textfield .= "\n<div id='${objid}.Autocomplete' class='autocomplete' style='display:none'></div>";
        }
        else { $textfield = "$help\n$textfield\n" }

        $textfield .= "\n";
        $element_name_choice = $element_name . ' Choice';    ## different element name if both textfield and popup menu
    }
    else {
        $element_name_choice = $element_name;                ## use same element_name if no textfield for searching ##
    }

    my $search_element;
    my $choices;
    my @values;

    if (0) { 
        ## turned off in GSC Upgrade ##
    if ( ( ( $search && $filter ) || ( $search && $new ) || ( $new && $filter ) ) ) {
        $search_element .= Show_Tool_Tip(
            radio_group(
                -name       => "ForceSearch$objid",
                -value      => 'Search',
                -style      => 'display:inline-block',
                -class      => 'inline',
                -id         => "$objid.Search",
                -structname => $structname,
                -onClick    => $reset_action,
                -default    => 'Search',
                -force      => 1
            ),
            $tip1
            )
            . "\n"
            if $search;

        $search_element .= Show_Tool_Tip(
            radio_group(
                -class      => 'inline',
                -name       => "ForceSearch$objid",
                -value      => 'Filter',
                -style      => 'display:inline-block',
                -default    => 'Filter',
                -id         => "$objid.Filter",
                -structname => $structname,
                -onClick    => $reset_action,
                -force      => 1
            ),
            $tip2
            )
            . "\n"
            if $filter;

        $search_element .= Show_Tool_Tip(
            radio_group(
                -class      => 'inline',
                -name       => "ForceSearch$objid",
                -value      => 'NEW',
                -id         => "$name.New",
                -structname => $structname,
                -default    => 'Filter',
                -force      => 1
            ),
            $tip3
            )
            . "\n"
            if $new;

    }
    elsif ($search) {
        $search_element .= hidden(
            -name       => "ForceSearch$objid",
            -value      => 'Search',
            -force      => 1,
            -structname => $structname
        ) . "\n";
    }
    elsif ($filter) {
        $search_element .= hidden(
            -name       => "ForceSearch$objid",
            -value      => 'Filter',
            -force      => 1,
            -structname => $structname
        ) . "\n";
    }
    }

    unshift( @option_list, $prompt ) if ( defined $option_list[0] && length( $option_list[0] ) > 0 );    ### If the list already has a non-blank element in front of it
    if ( $default =~ /\'\'/ ) { unshift @option_list, "''" }

    my $style;

    if ($width) { $style = "width:${width}px" }                                                          ##  if ( $Sess->{HTTP_USER_AGENT} =~ /firefox/i );                               ## does not work with IE ##
    #### Only enable it for when the option list has not been altered, and it is in popup mode

    #### AJAX autocomplete replaced with scrolling list that updates on entry of a search term
    #### (does not populate entire FK list)

    if ($ajax_scroll) {
        my ( @values, %labels );

        if (@defaults) {
            @values = ( '', @defaults );
            @labels{@values} = @values;
        }
        else {
            @values = ('');
            %labels = ( '' => '--Enter string above to search list--' );
        }

        my $multiple = 'false';
        if ( $action =~ /search/i ) { $multiple = 'true' }

        $choices = Show_Tool_Tip(
            scrolling_list(
                -name       => "$element_name_choice",
                -id         => "$objid.Choice",
                -values     => \@values,
                -defaults   => \@defaults,
                -labels     => \%labels,
                -multiple   => $multiple,
                -force      => 1,
                -size       => $SL_size,
                -onClick    => "SetSelection(this.form,'$element_name',''); $onclick",
                -structname => $structname
            ),
            $tip4
        );

        # require MIME::Base32;
        # my $encoded_condition;
        # $encoded_condition = MIME::Base32::encode($option_condition) if ($option_condition);
        # my $host                      = $dbc->{host};
        # my $dbase                     = $dbc->{dbase};
        # my $AUTO_COMPLETE_AJAX_SCRIPT = "/$URL_dir_name/cgi-bin/ajax/auto_completer.pl";
        # $search_element = '';

#$textfield      = Show_Tool_Tip(
#    textfield(
#        -name    => $element_name,
#        -default => $default,
#        -force   => 1,
#        -id      => $objid,
#        -onFocus =>
#            "new Ajax.Autocompleter('$objid','${objid}.Choice','$AUTO_COMPLETE_AJAX_SCRIPT',{minChars:3,paramName:'value',parameters:'Database_Mode=$mode&Table=$table&Field=$foreign_key&Condition=$encoded_condition',frequency:2,indicator:'indicator_$objid'});",
#    ),
#    $tip4
#    )
#    . "(Auto Completed)"
#    . "<span class='ajax_indicator' style='display:none' id='indicator_$objid' ><img src='/$URL_dir_name/images/icons//ajax_working_indicator.gif' alt='Working...' /></span>"
#    . "\n<div id='${objid}_choices' class='autocomplete' style='display:none'></div>\n";
    }
    elsif ($no_valid_options) {
        $choices = Show_Tool_Tip(
            popup_menu(
                -name       => $element_name,
                -values     => ['-- no valid options --'],
                -default    => $default,
                -width      => $size,
                -force      => 1,
                -style      => $style,
                -id         => $objid,
                -structname => $structname,
                -onchange   => $onchange,
                -onClick    => $onclick
            ),
            $tip4
        );
    }
    elsif ( lc($mode) eq 'popup' ) {

        # for popup menus, add two single quotes for autofill
        if ( ( $default ne "''" ) && $quote ) {
            push @option_list, "''";
        }

        if ($short_list) {
            $choices = Show_Tool_Tip(
                popup_menu(
                    -name       => $element_name,
                    -values     => \@option_list,
                    -default    => $default,
                    -width      => $size,
                    -force      => 1,
                    -style      => $style,
                    -id         => $objid,
                    -structname => $structname,
                    -onchange   => $onchange,
                    -onClick    => $onclick
                ),
                $tip4
            );

        }
        else {
            my $original_list = join( '^!^', @option_list );
            $output .= "<span id='$objid.OriginalList' class='HiddenData'><!--$original_list--></span>";

            my $clear_selection;

            if ($quote) {
                $clear_selection = "SetSelection(this.form,'$element_name','\'\'');";
                if ( $element_name eq $element_name_choice ) { $clear_selection = '\'\'' }
            }
            else {
                $clear_selection = "SetSelection(this.form,'$element_name','');";
                if ( $element_name eq $element_name_choice ) { $clear_selection = '' }
            }

            my $populate;

            my @opts = ('');
            if ($Autoquery) {
                my $cond = MIME::Base32::encode( $Autoquery->{Condition} );
                $populate = "populate_list('$objid.Choice', '/$URL_dir_name/cgi-bin/ajax/query.pl', \"$Autoquery->{Table}\", \"$Autoquery->{Field}\", \"$cond\");";
            }
            else {
                @opts = @option_list;
            }

            if ( $default =~ /^\'\'$/ ) { push @opts, $default }

            ## standard search / filter for non-trivial lists ##
            $choices = Show_Tool_Tip(
                popup_menu(
                    -width      => $size,
                    -name       => "$element_name_choice",
                    -values     => \@opts,
                    -default    => $default,
                    -force      => 1,
                    -style      => $style,
                    -onChange   => $clear_selection . $onchange,
                    -onClick    => "$populate; $onclick",
                    -id         => "$objid.Choice",
                    -structname => $structname,
                ),
                $tip4
            );
        }
    }
    elsif ( lc($mode) eq 'text' or $large_list ) {
        my $scalar_default;    ## force default into scalar even if supplied as array reference (in case of lists being passed in) ##
        if   ( ref $default eq 'ARRAY' ) { $scalar_default = $default->[0]; }
        else                             { $scalar_default = $default }

        $choices = $help
            . Show_Tool_Tip(
            textfield(
                -name    => "$element_name",
                -size    => $size,
                -default => $scalar_default,
                -class   => $class,
                -force   => 1,
            ),
            $tip4
            );
    }
    elsif ( lc($mode) eq 'scroll' ) {

        for ( my $i = 0; $i < scalar @defaults; $i++ ) {
            my $key = $defaults[$i];
            if ( !( grep /^\Q$key\E$/, @option_list ) ) {
                my $new_key = get_FK_info( $dbc, $name, -id => $key, -debug => $debug );
                $defaults[$i] = $new_key;
            }
        }
        if ( $field eq 'Library_Type' ) {

            # Message HTML_Dump '1--' ,$element_name_choice;
            #  Message HTML_Dump '2--', $objid ;
            #   Message HTML_Dump '3--' , \@option_list ;
            #    Message HTML_Dump '4--' , \@defaults ; ;
            #     Message HTML_Dump '5--', $SL_size ;
            #      Message HTML_Dump '6--', $element_name ;
            #       Message HTML_Dump '7--', $structname ;
        }
        $choices = Show_Tool_Tip(
            scrolling_list(
                -name       => "$element_name_choice",
                -id         => "$objid.Choice",
                -values     => \@option_list,
                -defaults   => [@defaults],
                -multiple   => 4,
                -force      => 1,
                -size       => $SL_size,
                -structname => $structname,
                -onClick    => "$onclick",
            ),
            $tip4
        );
        my $original_list = join( '^!^', @option_list );
        $output .= "<span id='$objid.OriginalList' class='HiddenData'><!--$original_list--></span>";

        #Message $choices;
    }
    elsif ( lc($mode) eq 'checkbox' ) {
        my $i = 0;

        foreach my $option (@option_list) {
            unless ($option) {next}    ## do not allow blank options from checkboxes
            $i++;
            my $checked = grep { $_ eq $option } @defaults;

            $choices .= "\n<SPAN style='white-space:nowrap'>";    # avoid linebreaks between checkbox and label #
            $choices .= Show_Tool_Tip(
                checkbox(
                    -name       => $element_name,
                    -label      => $option,
                    -value      => $option,
                    -checked    => $checked,
                    -structname => $structname,
                    -force      => 1
                ),
                ''
            );
            $choices .= "</SPAN> \n";

            if ( $i >= $checkbox_columns ) {
                $i = 0;
            }
        }
    }
    elsif ( lc($mode) eq 'radio' ) {
        my $i = 0;

        #	foreach my $option (@option_list) {
        #	    unless ($option) { next }     ## do not allow blank options from checkboxes
        #	    $i++;
        #	    my $checked = grep /^$option$/, @defaults;
        #	    Message("D$name = @defaults ($option) $checked. ($default)");
        my @options;
        foreach my $option (@option_list) {
            if ($option) { push @options, $option; }
        }

        #$choices .= Show_Tool_Tip(
        $choices .= "\n<SPAN style='white-space:nowrap'>";    # avoid linebreaks between checkbox and label #
        $choices .= radio_group(
            -name       => $element_name,
            -values     => \@options,
            -default    => $defaults[0],
            -structname => $structname,
            -columns    => $checkbox_columns,
            -force      => 1
        );
        $choices .= "</SPAN> \n";

        #			      ),
        #		  'choose'
        #		      );
        #	    if ($i >= $checkbox_columns) {
        #		$i=0;
        #		$choices .= '<BR>';
        #	    }
        #	}
    }
    else {
        Message("Warning Invalid mode ($mode)");
    }

    if ( $short_list || ( $large_list && !$ajax_scroll ) ) {
        ## keep dropdown simple if it is only a short list ... or a large list requiring auto-complete ##
        $output .= "\n$choices\n";
    }
    elsif ( $breaks == 1 && $choices ) {
        ##  add linebreak after filter options linebreaks set
        $output .= "\n$textfield<BR>\n";
        if ($search_element) { $output .= "$search_element<BR>\n" }
        $output .= "$choices\n";

        if ( $field eq 'Library_Type' ) {

            #    Message "\n<span id='$objid.SearchList'>\n$output\n</span>\n";
        }

    }
    elsif ( $breaks > 1 && $choices && $search_element ) {
        $output .= "\n$search_element<BR>\n$textfield<BR>\n$choices\n";
    }
    else {
        $output .= "\n$textfield\n$search_element\n$choices\n";
    }

    #    if (defined $dbc->{search_list}{$name}) { return $dbc->{search_list}{$name}; }

    return "\n<span id='$objid.SearchList'>\n$output\n</span>\n";
}

###########################
sub get_prompt_element {
##########################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $name         = $args{-name};
    my $options      = $args{-options};
    my $condition    = $args{-condition} || 1;                 ## optional condition on field - enables domain lists for dropdown menus ##
    my $default      = $args{-default};
    my $breaks       = $args{-breaks};
    my $mode         = $args{-mode};
    my $onchange     = $args{-onChange} || $args{-onchange};
    my $limit        = $args{-limit};                          ## limit on length of dropdowns (before autocomplete kicks in)
    my $element_name = $args{-element_name} || $name;
    my $class        = $args{-class};

    if ( ref $default eq 'ARRAY' ) {
        if ( int(@$default) == 0 ) { $default = undef; }
    }
    if ( ref $options eq 'ARRAY' ) {
        if ( int(@$options) == 0 ) { $options = undef; }
    }

    my $field;
    my $table;
    my $prompt;

    if ( $name =~ /^(.+)\.(.+)$/ ) {
        $table = $1;
        $field = $2;
    }
    else {
        $dbc->message("cannot figure out table / field specs ($name : $element_name)");

        #        return;
    }

    my $header = $name;

    if ( defined $options ) {
        my $option_list = Cast_List( -list => $options, -to => 'string', -autoquote => 1 );
        if ( my ( $fk_table, $fk_field ) = $dbc->foreign_key_check($name) ) {
            ## this section is a bit hacked and should be refactored... ##
            my @option_ids;

            foreach my $option ( Cast_List( -list => $options, -to => 'array' ) ) {
                my $option_id = $dbc->get_FK_ID( $field, $option );
                push @option_ids, $option_id;
            }

            my ($primary) = $dbc->get_field_info( $fk_table, -type => 'Pri' );
            my $option_id_list = Cast_List( -list => \@option_ids, -to => 'string', -autoquote => 1 );

            $condition .= " AND $primary IN ($option_id_list)";
        }
        else {
            $condition .= " AND $header IN ($option_list)";
        }
    }

    if ( $table =~ /(.+)\_Attribute$/ ) {
        my $class = $1;

        my ($attribute_id) = $dbc->Table_find( 'Attribute', "Attribute_ID", " WHERE Attribute_Name = '$field' and Attribute_Class = '$class'" );
        my $attribute_name = $field;

        if ( !$attribute_id ) {
            $dbc->warning("Attribute $field not found for $class class");
            return '';
        }
        $prompt = alDente::Attribute_Views::prompt_for_attribute( -name => $attribute_name, -attribute_id => $attribute_id, -dbc => $dbc, -force_element_name => $element_name, -default => $default, -mode => $mode, -onchange => $onchange );
    }
    elsif ( $dbc->foreign_key_check($name) ) {
        $prompt = alDente::Tools::search_list(
            -dbc            => $dbc,
            -name           => $name,
            -filter         => 1,
            -search         => 1,
            -condition      => $condition,
            -default        => $default,
            -breaks         => $breaks,
            -mode           => $mode,
            -element_name   => $element_name,
            -long_list_size => $limit,
            -onchange       => $onchange
        );
    }
    else {
        my ($type) = $dbc->Table_find( 'DBField', "Field_Type", " WHERE Field_Table = '$table' and Field_Name = '$field'" );
        if ( $type =~ /^enum|set/ ) {
            $prompt = alDente::Tools::search_list(
                -dbc            => $dbc,
                -name           => $name,
                -filter         => 1,
                -condition      => $condition,
                -default        => $default,
                -breaks         => $breaks,
                -mode           => $mode,
                -element_name   => $element_name,
                -long_list_size => $limit,
                -onchange       => $onchange
            );
        }
        elsif ( $type =~ /(date|time)$/i ) {
            my $element_id = int( rand(1000) );
            $element_name =~ s/\./\-/g;
            $element_id   =~ s/\./\-/g;
            $name         =~ s/\./\-/g;
            $prompt = $q->textfield( -name => $element_name, -id => "$name-$element_id", -size => 15 );
            $prompt .= $BS->calendar( -id => "$name-$element_id" );    ## note change of . to - (standard element ids should only contain alphanumerics + dash + underscore)
        }
        else {
            $prompt = $q->textfield( -name => $element_name, -size => 15, -force => 1, -default => $default, -onchange => $onchange, -class => $class );
        }
    }
    return $prompt;
}

##########################
sub get_local_organization_id {
#######################
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $return = $args{ -return } || 'id';    # enum (name, id)

    require alDente::Organization;
    my $org_obj = new alDente::Organization( -dbc           => $dbc );
    my $id      = $org_obj->get_Local_organization( -return => $return );
    return $id;
}
#########################################################
#
# Set DOM parameters for all elements in search_list
#
# <snip>
#   ## this will hide all of the search_list elements.. ##
#   eg.  set_search_IDs('FK_Library__Name',"style.display='none'");
# </snip>
#
######################
sub set_search_IDs {
######################
    my $name = shift;
    my $set  = shift;

    my $action = '';
    foreach my $suffix ( '.Text', '.Choice', '.Search', '.Filter' ) {
        $action .= set_ID( $name . $suffix, $set );
    }
    return $action;

}

##########################
# Subroutine: show a 96- or 384-well table that prompts for well information
##########################
sub show_well_table {
#######################
    my %args           = &filter_input( \@_ );
    my $size           = $args{-size} || 96;        # (Scalar) one of 96 or 384
    my $plate_id       = $args{-plate_id};          # (Scalar) Plate ID that needs to be assigned wells
    my $assigned_wells = $args{-assigned_wells};    # (Scalar) Wells that are already pooled at that time
    my $form           = $args{-form};              # (Scalar) Flag to enable or disable form tags around the table
    my $dbc            = $args{-dbc};

    my $name = "AssignPlate$plate_id";

    my $maxrow = 'H';
    my $maxcol = 12;
    if ( $size =~ /384/ ) {
        $maxrow = 'P';
        $maxcol = 24;
    }
    my $table = new HTML_Table();
    $table->Set_Title("Assign Wells for Plate $plate_id");

    # create selection mechanism for columns
    my @colcheck = map { &submit( -name => "Select C$_", -label => "$_", -onClick => "ToggleRegExpCheckBoxesID(this.form,'Select C$_','${name}Well.{1}$_\$'); return false;" ) } ( 1 .. $maxcol );

    # create select all button
    unshift( @colcheck, &submit( -name => 'Select All', -onClick => "ToggleRegExpCheckBoxesID(this.form,'Select All','${name}Well.*');return false" ) );
    $table->Set_Row( \@colcheck );
    foreach my $row ( 'A' .. $maxrow ) {
        my @well_elements = ();
        foreach my $col ( 1 .. $maxcol ) {
            my $wellname = &format_well("$row$col");
            push( @well_elements, &checkbox( -name => 'Well', -id => "${name}Well$row$col", -label => $wellname, -value => "$wellname", -force => 1 ) );
        }

        # create selection mechanism for rows
        unshift( @well_elements, &submit( -name => "Select R$row", -label => $row, -onClick => "ToggleRegExpCheckBoxesID(this.form,'Select R$row','${name}Well$row'); return false" ) );
        $table->Set_Row( \@well_elements );
    }
    my $str = '';

    require alDente::Form;
    $str .= alDente::Form::start_alDente_form( $dbc, ) if ($form);
    $str .= submit( -name => "Set Wells", -class => 'Std', -onClick => "return saveWells(this.form,'$plate_id');" );
    $str .= $table->Printout(0);
    $str .= submit( -name => "Set Wells", -class => 'Std', -onClick => "return saveWells(this.form,'$plate_id');" );

    $str .= end_form() if ($form);
    return $str;
}

######################
sub calculate {
######################
    my %args = &filter_input( \@_, -args => 'action,p1_amnt,p1_units,p2_amnt,p2_units', -mandatory => 'action,p1_amnt,p1_units,p2_amnt,p2_units' );

    my $action   = lc $args{-action};
    my $p1_amnt  = $args{-p1_amnt};
    my $p1_units = lc $args{-p1_units};
    my $p2_amnt  = $args{-p2_amnt};
    my $p2_units = lc $args{-p2_units};

    unless ( $action =~ /^add|subtract$/ ) {
        Message("Error: Unknown action: '$action'");
        return ( undef, undef );
    }

    my ( $res_amnt, $res_units );
    ### If exact same types, ie, ul & ul, or Cells & Cells
    if ( $p1_units eq $p2_units ) {
        if ( $action eq 'add' ) {
            $res_amnt  = $p1_amnt + $p2_amnt;
            $res_units = $p2_units;
        }
        elsif ( $action eq 'subtract' ) {
            if ( $p1_amnt > $p2_amnt ) {
                $res_amnt  = $p1_amnt - $p2_amnt;
                $res_units = $p2_units;
            }
            else {
                $res_amnt  = 0;
                $res_units = $p2_units;
            }
        }
    }
    elsif ( ( length($p1_units) == 2 ) and ( length($p2_units) == 2 ) ) {
        $p2_units =~ /^(\w)(\w)$/;
        my $p1_unit_type = $2;

        $p2_units =~ /^(\w)(\w)$/;
        my $p2_unit_type = $2;

        ### If same type, ie mL & uL
        if ( $p1_unit_type eq $p2_unit_type ) {
            ($p1_amnt) = convert_to_mils( $p1_amnt, $p1_units );
            ($p2_amnt) = convert_to_mils( $p2_amnt, $p2_units );

            if ( $action eq 'add' ) {
                $res_amnt = $p1_amnt + $p2_amnt;
            }
            elsif ( $action eq 'subtract' ) {
                if ( $p1_amnt > $p2_amnt ) {
                    $res_amnt = $p1_amnt - $p2_amnt;
                }
                else {
                    $res_amnt = 0;
                }
            }
            ( $res_amnt, $res_units ) = &Get_Best_Units( -amount => $res_amnt, -units => "m$p1_unit_type" );
        }
    }
    elsif ( $p1_units xor $p2_units ) {
        $res_units = $p1_units || $p2_units;
        Message("Warning: Units Missing - Assuming $res_units");
        if ( $p1_units eq $p2_units ) {
            if ( $action eq 'add' ) {
                $res_amnt = $p1_amnt + $p2_amnt;
            }
            elsif ( $action eq 'subtract' ) {
                if ( $p1_amnt > $p2_amnt ) {
                    $res_amnt = $p1_amnt - $p2_amnt;
                }
                else {
                    $res_amnt = 0;
                }
            }
        }

    }
    else {
        ### If different types, ie mL & Cells
        ### <CONSTRUCTION> Needs to be agreed upon (RFC)\
        $res_amnt  = $p1_amnt;
        $res_units = $p1_units;
    }

    return ( $res_amnt, $res_units );
}

#Moved from alDente::Sequencing, need to check if this being used or not (if not being used then can remove it)
########################
sub Links {
########################

    print "\n<HR size=2 color='black'>",

        "\n<A href=\"http://www.bcgsc.bc.ca/intranet/sequencing/\"><B>GSC Sequencing Page</B></A><BR>",          "\n<A href=\"http://www.bcgsc.bc.ca/cgi-bin/intranet/sequence/summary/dbsummary\"><B>GSC DBSummary</B></A><BR>",
        "\n<A href=\"http://www.bcgsc.bc.ca/intranet/sequencing/Human_cDNA\"><B>Human cDNA Project</B></A><BR>", "\n<A href=\"http://szweb.bcgsc.bc.ca/cgi-bin/intranet/SAGEdb/index.pl\"><B>SAGEdb</B></A><BR>",
        "\n<A href=\"http://rgweb.bcgsc.bc.ca/cgi-bin/intranet/Protocol\"><B>Protocols</B></A><BR>",             "\n<A href=\"http://rgweb.bcgsc.bc.ca/cgi-bin/Chemistry\"><B>Chemistry Calculator</B></A><BR>",
        "\n<A href=\"http://www.bcgsc.bc.ca/intranet/sequencing/mirror.shtml\"><B>Mirror Status</B></A><BR>",    "\n<A href=\"http://rgweb.bcgsc.bc.ca/sequencing.shtml\"><B>Sequencing Database Info</B></A><BR>",

        "<HR size=2 color='black'>";
}

#Moved from alDente::Sequencing, currently used by alDente/Solution.pm alDente/Container.pm alDente/Box.pm
##################
sub Href {
##################
    #
    # Print out a linkable reference label...
    #
    my $homelink = shift;
    my $name     = shift;
    my $type     = shift;
    my $dbc      = $Connection;
    my $ref;

    if ( $type =~ /lib/i ) {
        $ref = &Link_To( $dbc->config('homelink'), "<B>$name</B>", "&Info=1&Table=Library&Field=Library_Name&Like=$name", 'blue', ['newwin'] );
    }
    elsif ( $type =~ /equ/i ) {
        my $id = get_aldente_id( $dbc, $name, 'Equipment' );
        $ref = &Link_To( $dbc->config('homelink'), "<B>$name</B>", "&Info=1&Table=Equipment&Field=Equipment_ID&Like=$id", 'blue', ['newwin'] );
    }
    elsif ( $type =~ /proj/i ) {
        $ref = &Link_To( $dbc->config('homelink'), "<B>$name</B>", "&Info=1&Table=Project&Field=Project_Name&Like=$name", 'blue', ['newwin'] );
    }
    elsif ( $type =~ /Lot/i ) {
        $ref = &Link_To( $dbc->config('homelink'), "<B>$name</B>", "&Info=1&Table=Stock&Field=Stock_Lot_Number&Like=$name", 'black', ['newwin'] );
    }
    else { $ref = $name; }

    return $ref;
}

#Moved from alDente::Sequencing, currently used by alDente/Solution.pm alDente/Run_App.pm* alDente/Container.pm alDente/Library.pm alDente/Project.pm* alDente/Goal_App.pm alDente/Original_Source.pm alDente/Pipeline.pm* alDente/Equipment.pm* alDente/Validation.pm alDente/Run.pm* alDente/Source.pm alDente/Control_Plate.pm Sequencing/Custom.pm* Sequencing/SolexaRun.pm Sequencing/SolexaRun_Summary.pm* Mapping/Mapping_Summary.pm SDB/Session.pm*
# also used by bin/cron/Notification.pl bin/Notification.pl
#'*' means that the file uses alDente_ref by using alDente::Sequencing::alDente_ref
##################
# A simple way to link to an alDente reference object home page and include id in tool tip
##################
sub alDente_ref {
##################
    my %args = &filter_input( \@_, -args => 'table,id,tooltip' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table    = $args{-table};                                                                   ## pass in the table name (eg 'Plate')
    my $field    = $args{-field};                                                                   ## or pass in the field name (eg 'FK_Plate__ID')
    my $id       = $args{-id} || $args{-name} || $args{-code};                                      ## three standard foreign key types: ID, Name, Code
    my $tip      = $args{-tooltip};
    my $debug    = $args{-debug};
    my $link_new = $args{-new_link};                                                                ## used to override the link to use instead of homepage
    my $no_link  = $args{-no_link};                                                                 ## used if there is no link required
    my $brief    = $args{-brief};                                                                   ## exclude barcode prefix if applicable
    my $barcode  = $args{-barcode};                                                                 ## supply only a barcode if desired (figures out id, table & field)
    my $quiet    = $args{-quiet};

    my $value = $id;
    $table =~ s/^alDente:://;                                                                       ## strip alDente specification if full class supplied ...

    if ( $barcode =~ /(\w{3})(\d+)/ ) {
        my $prefix = $1;
        $value = $2;
        foreach my $key ( keys %Prefix ) {
            if ( lc $Prefix{$key} eq lc $prefix ) {
                $table = $key;
                $field = "FK_${key}__ID";
            }
        }
        if ( !$field || !$table ) { $dbc->warning("Prefix not found for barcode $barcode") }
    }

    $field ||= $dbc->foreign_key( -table => $table );
    if ( $field =~ /FK_(\w+)\_\_/ ) { $table ||= $1 }

    my $label = $dbc->get_FK_info( -field => $field, -id => $value, -brief => $brief, -debug => $debug, -quiet => $quiet );

    if ($brief) {
        $label =~ s/^.+\:\s*(\w+)/$1/;    ## clear optional prefix ##
    }

    $tip ||= "$table $id ($label)";

    my $link;
    if ( -e "$Configs{perl_dir}/alDente/${table}_App.pm" ) {
        $link = "&cgi_application=alDente::${table}_App&ID=$value";
    }
    else {

        #        Message("$Configs{perl_dir}/alDente/${table}_App.pm not found");
        $link = "&HomePage=$table&ID=$value";
    }

    if ($link_new) {
        $link = $link_new;
    }
    if ($no_link) {
        return $label;
    }

    return &Link_To( -link_url => $dbc->homelink(), -label => $label, -param => $link, -tooltip => $tip );
}

#
# This generates references for standard fields and caches the sth for rapid reloading for different values
# If used repeatedly, this is much faster than calling alDente_ref multiple times.
#
# Return: hyperlink to home page for standard object given id...
################
sub quick_ref {
################
    my %args = &filter_input( \@_, -args => 'table,id,tooltip' );

    my $dbc       = $args{-dbc};
    my $table     = $args{-table};
    my $id        = $args{-id};
    my $tooltip   = $args{-tooltip};
    my $separator = $args{-separator} || ',';
    my $truncate  = $args{ -truncate } || 1;    ## option to truncate prefix (eg 'Equ123: F4-1' becomes 'F4-1')
    my $alt       = $args{-alt} || '';          ## alternative return string in cases of empty id value
    my $debug     = $args{-debug};

    my $skip_tooltip = 0;
    if ( defined $tooltip && $tooltip ne '' ) {
        $skip_tooltip = 1;
    }

    my @id_list = Cast_List( -list => $id, -to => 'array' );
    ## return right away if no ID supplied ##
    if ( int(@id_list) == 1 && !$id ) { return $alt }

    if ( defined $dbc->{sth_cache}{$table}{$id} ) { return $dbc->{sth_cache}{$table}{$id}; }

    my $sth;
    my ($primary) = $dbc->get_field_info( -table => $table, -type => 'Pri' );

    if ( defined $dbc->{sth_qr}{$table} ) {
        $sth = $dbc->{sth_qr}{$table};
        if ($debug) { Message("Reusing sth for $table ($id)") }
    }
    else {
        my ( $Vtable, $Vfield, $field, $TableName_list, $Vcondition ) = $dbc->get_view( $table, $primary, $primary );

        my $query = "SELECT $Vfield FROM $Vtable WHERE $primary = ? $Vcondition";
        $sth = $dbc->sth_prepare( -query => $query );
        $dbc->{sth_qr}{$table} = $sth;
        if ($debug) { Message("Q $table: $query"); }
    }

    my $Farray;
    my @temp;
    foreach my $id (@id_list) {
        if ($id) {
            my $val = $dbc->sth_execute( -sth => $sth, -value => $id );
            push @temp, $val;
        }
        else { push @temp, [] }    ## otherwise it returns the previous execution result ##
    }

    $Farray = \@temp;

    if ($debug) { print HTML_Dump $Farray; }

    my $i = 0;
    my @links;
    while ( defined $Farray->[$i][0][0] ) {
        my $label     = $Farray->[$i][0][0];
        my $reference = $id_list[$i];
        if ( $truncate && $label =~ /^(.+)\:\s*(.*)$/ ) {

            ## truncate extra stuff ##
            if ( $primary =~ /ID$/i ) { $label =~ $2 }    ## for auto-increment fields
            else                      { $label = $1; $reference = $2 || $1; }    ## for primary name fields (eg Library_Name)
        }

        if ( !$skip_tooltip ) {
            $tooltip = "Go to this $table record [$reference]";
        }

        my $ref;
        if ( defined $dbc->{sth_cache}{$table}{$id} ) { $ref = $dbc->{sth_cache}{$table}{$id}; }
        else {
            $ref = Link_To( $dbc->config('homelink'), $label, "&HomePage=$table&ID=$id_list[$i]", -tooltip => $tooltip );
            $dbc->{sth_cache}{$table}{$reference} = $ref;
        }
        push @links, $ref;

        $i++;
    }
    return join $separator, @links;
}

##################################################################

# Moved from alDente::Sequencing, need to check if this being used or not (if not being used then can remove it)
use vars qw($barcode);
###################
sub printout {
###################
    my %args   = filter_input( \@_, -args => 'table,copies' );
    my $table  = $args{-table};
    my $copies = $args{-copies};
    my $dbc    = $args{-dbc};

    if    ( param('Print Next') ) { print "Adding new $table to database", &vspace(); }
    elsif ( param('Reprint') )    { print "Reprinting Barcode",            &vspace(); }
    else                          { print "not understood"; }

    print h3("(Printing $copies)");

    print &vspace();
    print "Code = $barcode";
    print "Text = $table";

    require alDente::Form;

    print alDente::Form::start_alDente_form($dbc);

    print submit( -name => 'Home' ), "\n</FORM>";

    return;
}

#Moved from alDente::Sequencing, currently used by bin/cron/refresh_parameters.pl* bin/data_correction/update_library_list.pl* bin/refresh_parameters.pl* bin/update_library_list.pl* bin/update_Stats.pl* cgi-bin/barcode.pl*
#'*' means that the file uses the function by explicitly adding path
#can move to alDente::Config in the future
##################################
sub initialize_parameters {
##################################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $dbase = shift;

    my %Parameters;
    &SDB::DBIO::initialize_field_info($dbc);    ### generate %Field_Info
    ################################### Generate BaseLine Parameters ########################

    my %Employee_Name;
    my %Employee_ID;
    my %IP_user;
    my %Email_Address;
    my %Permissions;
    my %Department;

    #my %Groups;
    #my %Admin;
    my %Department_Name;
    my %Group_Name;
    my %Department_ID;
    my %Group_ID;
    my %Department_Group;

    #my ($admin_id) = $dbc->Table_find('User_Group','User_Group_ID',"where User_Group_Name = 'LIMS Admin'");
    my %Employee_Info = &Table_retrieve( $dbc, 'Employee', [ 'Employee_ID', 'Employee_Name', 'IP_Address', 'Email_Address', 'Permissions', 'FK_Department__ID' ], "WHERE Employee_Status like 'Active' ORDER BY Employee_Name" );
    my @users;
    my $index = 0;
    while ( defined $Employee_Info{Employee_ID}[$index] ) {
        my $id          = $Employee_Info{Employee_ID}[$index];
        my $name        = $Employee_Info{Employee_Name}[$index];
        my $ip          = $Employee_Info{IP_Address}[$index];
        my $email       = $Employee_Info{Email_Address}[$index];
        my $permissions = $Employee_Info{Permissions}[$index];
        my $department  = $Employee_Info{FK_Department__ID}[$index];

        #my @groups = $dbc->Table_find('User_Group_Member','FK_User_Group__ID',"where FKMember_Employee__ID = $id");

        $index++;

        unless ( $id && $name ) { next; }
        push( @users, $name );

        $Employee_Name{"$id"} = $name;
        $Employee_ID{"$name"} = $id;
        $IP_user{$ip}         = $name;
        $Email_Address{"$id"} = $email;
        $Permissions{"$id"}   = $permissions;

        #$Groups{"$id"} = join ',', @groups;
        #if (grep /\b$admin_id\b/, @groups) {$Admin{"$id"} = 1}
        #else {$Admin{"$id"} = 0}
        $Department{"$id"} = get_FK_info( $dbc, 'FK_Department__ID', $department );
    }

    #my %permission_info = Table_retrieve($dbc,'User_Group',['User_Group_ID','Permissions']);
    #my $index=0;
    #while (defined $permission_info{User_Group_ID}[$index]) {
    #my $id = $permission_info{User_Group_ID}[$index];
    #my $permissions = $permission_info{Permissions}[$index];
    #$Permissions{"$id"} = $permissions;

    #$index++;
    #}

    my %dept = Table_retrieve( $dbc, 'Department', [ 'Department_ID', 'Department_Name' ], "WHERE Department_Status = 'Active'" );
    my $i = 0;
    while ( defined $dept{Department_ID}[$i] ) {
        my $dept_id   = $dept{Department_ID}[$i];
        my $dept_name = $dept{Department_Name}[$i];

        $Department_Name{$dept_id} = $dept_name;
        $Department_ID{$dept_name} = $dept_id;

        $i++;
    }

    my %grp = Table_retrieve( $dbc, 'Grp', [ 'Grp_ID', 'Grp_Name', 'FK_Department__ID' ] );
    $i = 0;
    while ( defined $grp{Grp_ID}[$i] ) {
        my $grp_id   = $grp{Grp_ID}[$i];
        my $grp_name = $grp{Grp_Name}[$i];
        my $dept_id  = $grp{FK_Department__ID}[$i];

        $Group_Name{$grp_id} = $grp_name;
        $Group_ID{$grp_name} = $grp_id;
        push( @{ $Department_Group{$dept_id} }, $grp_id );

        $i++;
    }

    my @projects        = $dbc->Table_find( 'Project', 'Project_Name', 'ORDER BY Project_Name' );
    my @active_projects = $dbc->Table_find( 'Project', 'Project_Name', "WHERE Project_Status='Active'" );

    my @locations = get_FK_info( $dbc, 'FK_Rack__ID', -condition => "WHERE Rack_Type <> 'Slot' ORDER BY Rack_Alias", -list => 1 );

    ########## global arrays for all Pages ####################
    #
    # Standard lists available for use include:
    #
    #  @plate_sizes : Enumerated list of Plate Sizes
    #  @organizations : List of organizations
    #  @library_names
    #  @libraries
    #  @plate_formats
    #  @locations
    #  @s equencers
    #
    #####################
    #
    # Global arrays for main barcode page.
    #

    my @plate_sizes = &get_enum_list( $dbc, 'Plate', 'Plate_Size' );

    #$dbc->Table_find('Plate','Plate_Size',undef,'Distinct');
    my @organizations = $dbc->Table_find( 'Organization', 'Organization_Name', "ORDER BY Organization_Name", 'Distinct' );

    my @suppliers   = $dbc->Table_find( 'Organization', 'Organization_Name', "WHERE Organization_Type like '%Supplier%' ORDER BY Organization_Name",             'Distinct' );
    my @s_suppliers = $dbc->Table_find( 'Organization', 'Organization_Name', "WHERE Organization_Type like \"%Supplier%\" ORDER BY Organization_Name",           'Distinct' );
    my @e_suppliers = $dbc->Table_find( 'Organization', 'Organization_Name', "where Organization_Type like \"%Equipment Supplier%\" Order by Organization_Name", 'Distinct' );

    my @libraries = $dbc->Table_find( 'Library', 'Library_Name', " ORDER BY Library_Name" );

    my @plate_formats = &get_FK_info( $dbc, 'FK_Plate_Format__ID', -condition => "where Plate_Format_Status = 'Active'", -list => 1 );

    my @lab_protocols = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_Name', " ORDER BY Lab_Protocol_Name" );

    my @std_chemistries = $dbc->Table_find( 'Standard_Solution', 'Standard_Solution_Name', " ORDER BY Standard_Solution_Name" );

    my @equip_info = $dbc->Table_find( 'Equipment,Stock,Stock_Catalog,Equipment_Category',
        'Equipment_ID,Equipment_Name', "WHERE Category = \"Sequencer\" AND FK_Stock__ID= Stock_ID AND FK_Stock_Catalog__ID = Stock_Catalog_ID AND Stock_Catalog.FK_Equipment_Category__ID = Equipment_Category_ID ORDER BY Equipment_Name" );
    my @sequencers;

    # foreach my $equip (@equip_info) {
    #    ( my $id, my $name ) = split ',', $equip;
    #  push( @sequencers, &get_FK_info( $dbc, 'FK_Equipment__ID', $id ) );
    # $sequencers{$id} = $name;
    #}

    my @standard_solutions = $dbc->Table_find( 'Standard_Solution', 'Standard_Solution_Name', "where Standard_Solution_Status = 'Active'" );

    my @all_standard_solutions = $dbc->Table_find( 'Standard_Solution', 'Standard_Solution_Name', "where Standard_Solution_Status in ('Active','Under Development')" );

    #   $dbc->disconnect();
    %Parameters = (
        application => 'alDente',

        #		      employees => \@employees,
        users                  => \@users,
        projects               => \@projects,
        active_projects        => \@active_projects,
        locations              => \@locations,
        Field_Info             => \%Field_Info,
        plate_sizes            => \@plate_sizes,
        organizations          => \@organizations,
        suppliers              => \@suppliers,
        s_suppliers            => \@s_suppliers,
        e_suppliers            => \@e_suppliers,
        libraries              => \@libraries,
        lab_protocols          => \@lab_protocols,
        std_chemistries        => \@std_chemistries,
        plate_formats          => \@plate_formats,
        sequencers             => \@sequencers,
        standard_solutions     => \@standard_solutions,
        all_standard_solutions => \@all_standard_solutions,
        Employee_Name          => \%Employee_Name,
        Employee_ID            => \%Employee_ID,
        email_address          => \%Email_Address,
        Permissions            => \%Permissions,
        IP_user                => \%IP_user,
        Department             => \%Department,

        #Groups => \%Groups,
        #Admin => \%Admin,
        Department_Name  => \%Department_Name,
        Group_Name       => \%Group_Name,
        Department_ID    => \%Department_ID,
        Group_ID         => \%Group_ID,
        Department_Group => \%Department_Group
    );

    return \%Parameters;
}

# Moved from alDente::Sequencing, currently used by cgi-bin/barcode.pl* cgi-bin/Protocol.pl*--
# '*' means that the file uses the function by explicitly adding path
# '--' means just a comment in the file
##############################
# Load the parameters
##############################
sub Load_Parameters {
######################
    my %args = @_;

    my $db = $args{-dbase} || $dbase;
    my $h  = $args{-host}  || $Defaults{SQL_HOST};

    my $parameters_file = "Parameters.$h:$db";
    my $param = &RGTools::RGIO::load_Stats( $parameters_file, $Stats_dir, 'lock', 'quiet' );
    return $param;
}

##############################
# Description:
#		This function return an absolute path
# Input:
#	Structure: [Mandatory]  seperated by '/' list of subdirectories needed. Options are: host,version/database/date
#	Root:	   the root directory to start from if not supplied default to /
#	Version:   code version eg production, test, beta ...
# 	Date: 		[Format: YYYY-MM-DD]
# Ouput:
#	absolute directory path
# Usage:
#	$dir = alDente::Tools::get_directory(-structure => 'HOST/VERSION/DATE', -root =>  '/home/aldente/private');
##############################
sub get_directory {
##############################
    my %args      = &filter_input( \@_, -args => 'structure,root,dbc', -mandatory => 'structure' );
    my $root      = $args{-root};
    my $structure = $args{-structure};
    my $dbc       = $args{-dbc};                                                                      ## not necessary unless getting host, database from dbc object (instead of config file)

    ## optional standard directory splitting options ##
    my $group    = $args{-group_id};
    my $project  = $args{-project_id};
    my $employee = $args{-employee_id};                                                               ## may expand to handle storage by Employee or Dept....
    my $dept     = $args{-department_id};

    my $dir = $root;

    my %Replace;                                                                                      ## hash of replacement characters in structure ##
    if ( $dbc && $dbc->is_Connected ) {
        $Replace{HOST}     = $dbc->{host};
        $Replace{DATABASE} = $dbc->{dbase};
    }
    else {
        $Replace{HOST}     = $Configs{SQL_HOST};
        $Replace{DATABASE} = $Configs{DATABASE};
    }

    if ( $structure =~ /\b(date|day|month|year|time)\b/ ) {
        ## including date in directory path ##
        my $time = timestamp();
        my ( $date, $year, $month, $day, $hour, $minute, $second );
        if ( $time =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/ ) {
            ( $year, $month, $day, $hour, $minute, $second ) = ( $1, $2, $3, $4, $5, $6 );
            $date = "$year-$month-$day";
        }
        $date =~ s/\-/\//g;    ## remove - characters from date string
        $Replace{TIME}  = $time;
        $Replace{DATE}  = $date;
        $Replace{DAY}   = $day;
        $Replace{MONTH} = $month;
        $Replace{YEAR}  = $year;
    }

    foreach my $subdir ( split '/', $structure ) {
        ## handle each subdirectory separately ##
        foreach my $key ( keys %Replace ) {
            $subdir =~ s/\b$key\b/$Replace{$key}/g;
        }
        if ($subdir) { $dir .= '/' . $subdir }
    }

    ## append with special group subdirectories if supplied (eg Group/<ID>  or Project/<ID> ...)
    if ($group) {
        if ( $group !~ /^\d+$/ ) { Message('Warning: Expecting Group ID - non-standard'); }
        $dir .= '/Group/' . $group;
    }
    elsif ($project) {
        if ( $project !~ /^\d+$/ ) { Message('Warning: Expecting Group ID - non-standard'); }
        $dir .= '/Project/' . $project;
    }

    return $dir;
}

#
# Accessor to standardized path structure for standard classes
#
# Usage:  ($path, $sub_path) = get_standard_Path(-type=>'template',-group=>45);
#
###############################
sub get_standard_Path {
###############################
    my %args      = filter_input( \@_ );
    my $type      = $args{-type};
    my $root      = $args{-root};
    my $structure = $args{-structure} || 'HOST/DATABASE';    ## standard path structure ...
    my $group     = $args{-group} || $args{-group_id};       ## ID not name
    my $project   = $args{-project} || $args{-project_id};
    my $create    = $args{-create};
    my $mode      = $args{-mode};
    my $dbc       = $args{-dbc};                             ## only necessary if autoloading dbase and host from dbc object

    if (!$root && $dbc && defined $dbc->config($type . '_dir') ) { $root = $dbc->config($type . '_dir') }

    my %Root;
    $Root{template}   = $Configs{upload_template_dir} || $dbc->config('upload_template_dir');
    $Root{view}       = $Configs{views_dir}           || $dbc->config('view_dir');
    $Root{submission} = $Configs{submission_dir}      || $dbc->config('submission_dir');

    if ( $type && !$root ) { $root = $Root{ lc($type) } }
    my $path = get_directory(
        -structure  => $structure,
        -root       => $root,
        -group_id   => $group,
        -project_id => $project,
        -dbc        => $dbc
    );

    if ( $path =~ /^$root(.*)$/ ) {
        my $sub_path = $1;
        if ($create) { create_dir( $root, $sub_path, $mode ) }
        return ( $root, $sub_path );
    }
    else {
        return ($path);
    }
}

return 1;
