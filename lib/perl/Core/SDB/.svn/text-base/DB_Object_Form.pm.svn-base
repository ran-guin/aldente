package SDB::DB_Object_Form;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Object_Form.pm - 

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;
use CGI qw(:standard fatalsToBrowser);

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::DB_Object;
use RGTools::RGmath;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::HTML_Table;
use RGTools::Conversion;

use alDente::SDB_Defaults;    ### Temporary for testing

##############################
# global_vars                #
##############################
### Global variables
use vars qw(%Settings $Connection );
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my %References;
my %Child_Tables;

##############################
# constructor                #
##############################

##################
sub new {
##################
    #
    # Constructor of the object
    #
    my $this = shift;

    my %args   = @_;
    my $frozen = $args{-frozen} || 0;                                                             # Reference to frozen object if there is any. [Object]
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    if ( $args{-table} ) { return $this->_new_OLD(%args) }                                        ## phased out...

    my $self = $this->SDB::DB_Object::new(%args);

    my $class = ref($this) || $this;

    $self->{dbc} = $dbc;

    bless( $self, $class );

    if ($frozen) { return $self }                                                                 # If frozen then return now with the new dbc handle.

    # initialize parameter passing hash - this is for state information (such as confirmation/s needed, hidden fields, etc)
    my %params;
    $params{hidden_fields}   = [];
    $params{delete_confirm}  = 0;
    $params{highlight_index} = [];
    $params{fk_views}        = {};

    # list of all database tables
    my @tables = &Table_find( $dbc, "DBTable", "DBTable_Name" );
    $params{tables_list} = \@tables;
    $self->{params} = \%params;

    return $self;
}

##############################
# public_methods             #
##############################

##########################
sub multi_table_edit_display {
##########################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my $reload     = 0;
    my $sort_order = param("Sort_Order");
    my $add_table  = param("Add_Table");
    my $advanced   = param("Advanced View");

    my %args            = @_;
    my $condition       = $args{-condition};
    my $title           = $args{-title};
    my $table_ref       = $args{-tables} || $self->{tables};
    my $truncate        = $args{ -truncate } || 0;
    my $action          = $args{-action};
    my $limit           = $args{-limit};
    my $total_records   = $args{-total_records} || 0;
    my $current_record  = $args{-current_record} || 1;
    my $order_by        = $args{-order_by};
    my $unhide_all      = $args{-unhide_all};
    my $view_references = $args{-view_references} || 0;

    my @tables      = @{$table_ref};
    my $refresh_fks = 0;

    # if a table needs to be added, add it to the tables list
    if ( $add_table && ( $add_table ne "--Select--" ) && ( !( grep( /^$add_table$/, @{ $self->{tables} } ) ) ) ) {
        $self->add_tables($add_table);
        $reload = 1;

        # trigger search record
        $action = "Search Records";
        print "Reloading with $add_table...";
    }

    ## replace with standardized form generator ##

    require LampLite::Form_Views;
    print LampLite::Form_Views::start_custom_form( "Multi_table_edit_form", -dbc=>$dbc );

    # get state information
    my %Unhide = {};
    my %Hide   = {};
    if ( param('Unhide_Fields') ) {
        my @hidden = param('Unhide_Fields');
        foreach my $unh (@hidden) {
            $Unhide{$unh} = 1;
        }
    }

    my @hidden_fields = ();
    if ($unhide_all) {
        $self->{params}{hidden_fields} = [];
    }
    else {
        foreach my $hide ( @{ $self->{params}{hidden_fields} } ) {
            push( @hidden_fields, $hide ) unless $Unhide{$hide};
            $Hide{$hide} = 1;
        }
    }

    # if action is not delete, reset delete and highlight fields
    if ( ( $action !~ /delete/i ) ) {
        $self->{params}{delete_confirm}  = 0;
        $self->{params}{highlight_index} = [];
    }

    # do action first
    if ( $action eq "Search Records" ) {
        $reload = $self->search_multi_table_display( -limit => $limit );

        # reset total records to force a retrieval of number of entries
        $total_records = 0;
        $refresh_fks   = 1;
    }
    elsif ( $action eq "Update Records" ) {
        $reload      = $self->update_multi_table_display();
        $refresh_fks = 1;
    }
    elsif ( ( $action eq "Delete Records" ) ) {
        $reload = $self->delete_multi_table_display();
    }
    elsif ( ( $action eq "Delete Confirmed" ) ) {
        $reload = $self->delete_multi_table_display( -confirm => 1 );
    }
    elsif ( $action eq "Copy Records" ) {
        $reload = $self->set_multi_table_display();
    }
    elsif ( $action =~ /(\d+)\-\d+/ ) {
        $current_record = $1;
        $reload         = 1;
        $refresh_fks    = 1;
    }
    elsif ( $action eq "Refresh Records" ) {

        # reload from db
        $reload = 1;
    }

    # do a reload if action is not an update
    if ($reload) {

        # refresh if the table_list has not changed
        $self->load_Object( -refresh => 1, -limit => ( $current_record - 1 ) . ",$limit", -multiple => 1 );
        $total_records = $self->load_Object( -refresh => 1, -count_only => 1 );
    }

    # if total_records is not defined, then do a retrieve on the count
    # if total_records is not defined (or this is a reload), then do a retrieve on the count
    if ( !($total_records) || $reload ) {
        $total_records = $self->load_Object( -refresh => 1, -count_only => 1 );
    }

    # sort (if necessary)
    if ($order_by) {
        $self->sort_object( -by => $order_by, -order => $sort_order );
    }

    my $primary_id = $self->primary_value();
    unless ($title) {
        $title = "Data from ";
        foreach my $table (@tables) {
            $title .= &Link_To( $dbc->config('homelink'), $table, "&Multi-Record=1&TableName=$table", 'lightblue' ) . '; ';
        }
    }

    # do preprocessing for each field (see if it is a foreign key, etc)
    my %field_info;

    # create first row (edit fields)
    # add checkbox, with javascript to toggle all checkboxes
    my @edit_row = ( checkbox( -name => "Toggle_Rows", -label => 'toggle', -onClick => "ToggleNamedCheckBoxes(document.Multi_table_edit_form,'Toggle_Rows','Row');" ) );
    my @headers = ('');

    print "<input type='hidden' name='Sort_Column' id='Sort_Column'/>";
    print "<input type='hidden' name='Multitable_orderby' id='Multi'/>";

    my $field_list = Cast_List( -list => $self->fields(), -to => 'string', -autoquote => 1 );

    my %info_hash = &Table_retrieve(
        $self->{dbc}, 'DBField,DBTable',
        [ 'Field_Name', 'DBTable_Name', 'Prompt', 'Field_Description', 'Field_Options', 'Field_Format' ],
        "where FK_DBTable__ID=DBTable_ID AND Concat(DBTable_Name,'.',Field_Name) IN ($field_list) Order by Field_Order"
    );

    # get field properties

    my @fields = @{ $info_hash{Field_Name} };    ## ordered list of fields

    #    foreach my $field (@{$self->fields()}) {
    foreach my $index ( 0 .. $#fields ) {
        my $rfield  = $info_hash{Field_Name}[$index];
        my $rtable  = $info_hash{DBTable_Name}[$index];
        my $options = $info_hash{Field_Options}[$index];
        my $field   = "$rtable.$rfield";
        my ( $ref_table, $ref_field ) = foreign_key_check($rfield);
        my ($field_def) = get_field_types( $dbc, $rtable, $rfield );
        $field_def =~ s/^\S+\s(.*)/$1/;
        $field_info{$field}{type}      = $field_def;
        $field_info{$field}{table}     = $rtable;
        $field_info{$field}{field}     = $rfield;
        $field_info{$field}{ref_table} = $ref_table;
        $field_info{$field}{ref_field} = $ref_field;
        $field_info{$field}{options}   = $options;

        $field_info{$field}{tooltip} = $info_hash{'Field_Description'}[$index];
        my $tooltip = $field_info{$field}{tooltip};
        $field_info{$field}{prompt} = $info_hash{'Prompt'}[$index];
        $field_info{$field}{prompt} ||= $field;
        my $hide = ( $options =~ /\bhidden\b/i );

        ### resolve fks
        # if this is a reload or the FK values are undefined, resolve the FKs or primary field
        if ( ( $refresh_fks || ( !defined( $self->{params}{fk_views}{$rtable}{$rfield} ) ) ) && ( ( $ref_table && $ref_field ) || ( $options =~ /primary/i ) ) ) {
            $self->_resolve_fks( -table => $rtable, -field => $rfield );
        }

        # by default, field is not hidden, unless it is part of the hidden list
        if ( $Hide{$field} && !$Unhide{$field} ) {
            $field_info{$field}{hidden} = 1;
        }
        elsif ($hide) {
            $field_info{$field}{hidden} = 1;
        }
        else {
            $field_info{$field}{hidden} = 0;
        }

        # check to see if the hide checkbox is checked. If it is, add to hidden list
        if ( param("Hide.$field") ) {
            $field_info{$field}{hidden} = 1;
            push( @hidden_fields, $field );
        }

        # if $field is hidden, ignore
        if ( $field_info{$field}{hidden} == 1 ) {
            next;
        }

        # add prompt as header names, but link back to multitable
        my $onClick = qq{document.Multi_table_edit_form.Sort_Column.value="$field"; document.Multi_table_edit_form.Multi.value="Refresh Records"; document.Multi_table_edit_form.submit(); return false;};
        push( @headers, "<a href='' onclick='$onClick'><Font color=black>$field_info{$field}{prompt}</font></a>" );

        # create first row (edit information)
        # hide field
        my $col = checkbox( -name => "Hide.$field", -label => "(hide)" ) . '<BR>';
        if ( $field_def =~ /enum/ ) {
            my $enum_def = $field_def;
            $enum_def =~ s/enum\((.*)\)/$1/;
            my @values = ('');
            push( @values, split ',', $enum_def );

            # strip all quotes except quotes that are adjacent to each other
            foreach (@values) {
                unless ( ( $_ eq "''" ) || ( $_ eq "\"\"" ) ) {
                    s/\'//g;
                    s/\"//g;
                }
            }
            $col .= &Show_Tool_Tip( popup_menu( -name => "${rtable}.${rfield}", -values => \@values ), $tooltip );
        }
        elsif ( $field_def =~ /set/ ) {
            my $list_def = $field_def;
            $list_def =~ s/set\((.*)\)/$1/;
            my @values = ('');
            push( @values, split ',', $list_def );

            # strip all quotes except quotes that are adjacent to each other
            foreach (@values) {
                unless ( ( $_ eq "''" ) || ( $_ eq "\"\"" ) ) {
                    s/\'//g;
                    s/\"//g;
                }
            }
            $col .= &Show_Tool_Tip( scrolling_list( -name => "${rtable}.${rfield}", -values => \@values, -multiple => 'true' ), $tooltip );
        }
        else {

            # show popup for FKs as well if they are under a certain size
            my @fk_array = ();
            if ( defined $ref_table ) {
                @fk_array = ('');
                push( @fk_array, get_FK_info_list( $dbc, $ref_field ) );
            }
            if ( ( defined $ref_table ) && ( scalar(@fk_array) < $Settings{FOREIGN_KEY_POPUP_MAXLENGTH} ) ) {
                $col .= &Show_Tool_Tip( popup_menu( -name => "${rtable}.${rfield}", -values => \@fk_array ), $tooltip );
            }
            else {
                $col .= &Show_Tool_Tip( textfield( -name => "${rtable}.${rfield}" ), $tooltip );
            }
        }
        push( @edit_row, $col );
    }

    # save hidden field info
    $self->{params}{hidden_fields} = \@hidden_fields;

    # add --Select-- to tables list
    my @tables_list = ('--Select--');
    push( @tables_list, @{ $self->{params}{tables_list} } );
    my @row1 = ( "Limit: " . textfield( -name => "Limit_multitable", -size => 5, -value => 100 ), checkbox( -name => "Display All" ) );
    my @row2 = ( "(sort)" . radio_group( -name => "Sort_Order", -values => [ 'asc', 'desc' ] ), checkbox( -name => "View References" ) );
    my @row3 = ( submit( -name => "Multitable", -label => "Refresh", -class => "Std" ) );

    my %rowspan;
    if ( int(@hidden_fields) ) {
        push( @row1, " Restore: " . popup_menu( -name => 'Unhide_Fields', -value => [ '', @hidden_fields ], -multiple => 1 ) );
        $rowspan{1}{3} = 3;
    }

    if ( int(@tables) ) {
        my $table_list = Cast_List( -list => \@tables, -to => 'string', -autoquote => 1 );
        my @ref_from = &Table_find( $dbc, 'DBField,DBTable', 'Foreign_Key', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name in ($table_list) AND Length(Foreign_Key) > 1", 'Distinct' );
        map {
            if (/(.+)\.(.+)/) { $_ = $1 }
        } @ref_from;

        my $join_condition = join "%' OR Foreign_Key LIKE '", @tables;
        my @ref_to = &Table_find( $dbc, 'DBField,DBTable', 'DBTable_Name', "WHERE FK_DBTable__ID=DBTable_ID AND (Foreign_Key LIKE '$join_condition%') AND DBTable_Name NOT IN ($table_list)", 'Distinct' );
        my @ref_tables = ( @ref_from, @ref_to );
        if ( int(@ref_tables) ) {
            push( @row3, "Add Table: " . popup_menu( -name => "Add_Table", -values => [ '', @ref_tables ] ) );
            unless ( int(@hidden_fields) ) { push( @row1, '' ); push( @row2, '' ); push( @row3, '' ); }    ## add empty cells if not already there...
        }
    }

    my $options .= &Views::Table_Print( content => [ \@row1, \@row2, \@row3 ], print => 0, rowspan => \%rowspan, bgcolour => 'lightgrey' );
    my $title_str = $title . br() . $options;

    my $Info = HTML_Table->new( -title => $title_str, -width => 600 );
    $Info->Set_Width("100%");

    # push references on if necessary
    if ($view_references) {
        push( @headers, "Ref:" );
    }
    $Info->Set_Headers( \@headers );

    # add edit row
    $Info->Set_Row( \@edit_row );

    foreach my $record ( 1 .. $self->{record_count} ) {
        my @row = ();

        # put checkbox
        push( @row, checkbox( -name => "Row$record", -label => '' ) );
        my $ref_list = "";

        #	foreach my $field (@{$self->fields()}) {
        foreach my $index ( 0 .. $#fields ) {
            my $rfield = $info_hash{'Field_Name'}[$index];
            my $rtable = $info_hash{'DBTable_Name'}[$index];
            my $field  = "$rtable.$rfield";

            #	    my $rtable =$field_info{$field}{table};
            #	    my $rfield = $field_info{$field}{field};
            unless ( grep /^$rtable$/, @tables ) {next}
            my $value = $self->{fields}{$rtable}{$rfield}{values}[ $record - 1 ];

            my $ref_table = $field_info{$field}{ref_table};
            my $ref_field = $field_info{$field}{ref_field};
            my $prompt    = $field_info{$field}{prompt};
            my $hidden    = $field_info{$field}{hidden};
            my $options   = $field_info{$field}{options};

            # if hidden, skip this field
            if ($hidden) {
                next;
            }

            # resolving fks slows down the page by a LOT (WHY) - option to turn it on (defaulted to off)
            if ( $options =~ /primary/i ) {
                my $detail_list = "";
                if ($view_references) {
                    ( $ref_list, $detail_list ) = $dbc->get_references( $rtable, { $rfield => $value } );
                }
                my $FK_value = $self->{params}{fk_views}{$rtable}{$rfield}{$value};
                $value = &Link_To( $dbc->config('homelink'), $FK_value, "&Search=1&Table=$rtable&Search+List=$value", $Settings{LINK_COLOUR}, ['newwin'] );
            }
            elsif ( $ref_table && $ref_field && $value ) {    ## FK field - deference and display link instead
                my $FK_value = $self->{params}{fk_views}{$rtable}{$rfield}{$value};
                $value = &Link_To( $dbc->config('homelink'), $FK_value, "&Info=1&Table=$ref_table&Field=$ref_field&Like=$value", $Settings{LINK_COLOUR}, ['newwin'] );
            }

            # translate dates to human-readable form
            if ( $field_info{$field}{type} =~ /date/i ) {
                $value = &RGTools::Conversion::convert_date( $value, 'simple' );
            }

            # truncation
            if ( ( $options !~ /primary/i ) && ( !( $ref_table && $ref_field && $value ) ) && ( $value !~ /<A/ ) && $truncate && ( length($value) > $truncate ) ) {    ## truncate (only if NOT a link)... ##
                $value = substr( $value, 0, $truncate ) . "...";
            }

            # add a space if it is blank
            unless ($value) {
                $value = "&nbsp;";
            }

            push( @row, $value );

            # add info
        }

        # append references
        if ($view_references) {
            if ( $ref_list ne "" ) {
                push( @row, $ref_list );
            }
            else {
                push( @row, "&nbsp;" );
            }
        }

        # highlight
        my $curr_row = $record - 1;
        if ( grep( /^$curr_row$/, @{ $self->{params}{highlight_index} } ) ) {
            $Info->Set_Row( \@row, 'lightredbw' );
        }
        else {
            $Info->Set_Row( \@row );
        }
    }
    $Info->Set_Border(1);

    # freeze self (for parameter passing)
    print &RGTools::RGIO::Safe_Freeze( -name => "dbobject", -value => $self, -format => "hidden", -encode => 1 );
    print submit( -name => "Multitable", -value => "Search Records", -class => "Search" ) . &hspace(5);
    print submit( -name => "Multitable", -value => "Update Records", -class => "Action" ) . &hspace(5);
    print submit( -name => "Multitable", -value => "Copy Records",   -class => "Action" ) . &hspace(5);
    print submit( -name => "Multitable", -value => "Delete Records", -class => "Action" ) . &hspace(5);

    #if ($filename) {$output .= $Info->Printout($filename,$html_header);}
    # print printable and CSV page
    
    my $temp_dir = $dbc->config('URL_temp_dir');
    my $output = $Info->Printout("$temp_dir/Multi_table@{[timestamp()]}.csv");
    $output .= $Info->Printout( "$temp_dir/Multi_table@{[timestamp()]}.html", $html_header );
    $output .= $Info->Printout(0);
    print $output;

    # hidden value - total_records
    print hidden( -name => "recordcount_multitable",  -value => $total_records );
    print hidden( -name => "currentplace_multitable", -value => $current_record );

    # print out links to next values
    my $upper_limit = 1;
    my $lower_limit = 1;
    foreach my $pos ( 1 .. ( $total_records / $limit ) ) {
        $upper_limit = $limit * $pos;
        print submit( -name => "Multitable", -value => "$lower_limit-$upper_limit", -class => "Std" );
        $lower_limit = $upper_limit + 1;
    }

    # print out last bit if necessary
    if ( $lower_limit < $total_records ) {
        print submit( -name => "Multitable", -value => "$lower_limit-$total_records", -class => "Std" );
    }

    print end_form();
}

#####################################
sub update_multi_table_display {
#####################################
    my $self = shift;

    # assume object was thawed already, and reconnected with db
    my $dbc = $self->{dbc};

    my @tables = @{ $self->{tables} };

    my %field_info;

    # get field properties
    foreach my $field ( @{ $self->fields() } ) {
        my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
        my ($field_def) = get_field_types( $dbc, $rtable, $rfield );
        my ( $ref_table, $ref_field ) = foreign_key_check($rfield);
        $field_def =~ s/^\S+\s(.*)/$1/;
        $field_info{$field}{type}      = $field_def;
        $field_info{$field}{table}     = $rtable;
        $field_info{$field}{field}     = $rfield;
        $field_info{$field}{ref_table} = $ref_table;
        $field_info{$field}{ref_field} = $ref_field;
    }
    my @indices = ();

    # store all the primary fields
    my %primary_hash = %{ $self->primary_fields() };
    my $insert_count = 0;
    foreach my $index ( 1 .. $self->{record_count} ) {

        # if checkbox is not checked, skip values
        unless ( param("Row$index") ) {
            next;
        }

        push( @indices, $index - 1 );
        my @fields = ();
        my @values = ();
        foreach my $field ( @{ $self->fields() } ) {
            my $rtable = $field_info{$field}{table};
            my $rfield = $field_info{$field}{field};
            unless ( grep /^$rtable$/, @tables ) {next}

            # if the value is set to anything other than blank, change the value
            unless ( param("${rtable}.${rfield}") ) {
                next;
            }

            # if updating primary field, skip the field update
            if ( $rfield eq $primary_hash{$rtable} ) {
                Message("$rfield is a primary field - skipping update to field");
                next;
            }

            my @array = param("${rtable}.${rfield}");

            # if the string is double quotes, set the value to blank
            foreach (@array) {
                if ( ( $_ eq "''" ) || ( $_ eq "\"\"" ) ) {
                    $_ = "";
                }

                # if elem is a date, resolve to SQL
                if ( $field_info{$field}{type} =~ /date/i ) {
                    $_ = convert_date( $_, 'SQL' );
                }
                elsif ( $field_info{$field}{type} =~ /time/i ) {
                    $_ = convert_time($_);
                }

                # if an FK, resolve to FK_ID
                if ( defined( $field_info{$field}{ref_table} ) ) {
                    my $id = get_FK_ID( $dbc, $field_info{$field}{ref_field}, $_ );
                    if ( $id ne '' ) {
                        $_ = $id;
                    }
                }
            }
            my $val_str = join ',', @array;
            push( @fields, $field );
            push( @values, $val_str );
        }

        # do database update
        $self->update( -index => $index - 1, -fields => \@fields, -values => \@values );

        $insert_count++;
    }

    # if nothing is updated, try inserting
    if ( $insert_count == 0 ) {
        my @fields = ();
        my @values = ();
        foreach my $field ( @{ $self->fields() } ) {
            my $rtable = $field_info{$field}{table};
            my $rfield = $field_info{$field}{field};
            unless ( grep /^$rtable$/, @tables ) {next}

            # if the value is set to anything other than blank, change the value
            unless ( param("${rtable}.${rfield}") ) {
                next;
            }

            my @array = param("${rtable}.${rfield}");

            # if the string is double quotes, set the value to blank
            foreach (@array) {
                if ( ( $_ eq "''" ) || ( $_ eq "\"\"" ) ) {
                    $_ = "";
                }

                # if elem is a date, resolve to SQL
                if ( $field_info{$field}{type} =~ /date/i ) {
                    $_ = convert_date( $_, 'SQL' );
                }
                elsif ( $field_info{$field}{type} =~ /time/i ) {
                    $_ = convert_time($_);
                }
            }

            my $val_str = join ',', @array;
            push( @fields, $field );
            push( @values, $val_str );
        }

        # do database update
        $self->set_multi_table_display( -fields => \@fields, -values => \@values );

        # return true to reload page from db
        return 1;
    }

    # don't reload page from db
    return 0;

}

#################
sub delete_multi_table_display {
#################
    my $self = shift;

    # assume object was thawed already, and reconnected with db
    my $dbc     = $self->{dbc};
    my %args    = @_;
    my $confirm = $args{-confirm};

    # get state information - if the delete requires a confirm, it will show a delete confirmation
    # and highlight the records to be deleted
    if ($confirm) {

        # do database update
        $self->delete( -index => $self->{params}{highlight_index} );
        $self->{params}{highlight_index} = [];
        $self->{params}{delete_confirm}  = 0;

        # don't reload page from db
        return 0;
    }
    else {
        my @indices = ();
        foreach my $index ( 1 .. $self->{record_count} ) {

            # if checkbox is checked, update values
            unless ( param("Row$index") ) {
                next;
            }
            push( @indices, $index - 1 );
        }
        $self->{params}{highlight_index} = \@indices;
        $self->{params}{delete_confirm}  = 1;

        # display confirm button
        print submit( -name => "Multitable", -value => "Delete Confirmed", -class => "Action" );
        print br() . br();
    }

    # reload page from db
    return 1;
}

#################
sub set_multi_table_display {
#################
    my $self = shift;

    # assume object was thawed already, and reconnected with db
    my $dbc        = $self->{dbc};
    my %args       = @_;
    my $fields_ref = $args{-fields};
    my $values_ref = $args{ -values };    # arrayref of values to insert

    # create a database object (for the insert)
    my $do = SDB::DB_Object->new( -dbc => $dbc, -tables => $self->{tables} );

    my @fields = ();
    my %value_hash;
    my %field_info;
    my @primary_fields = values( %{ $self->primary_fields() } );

    # get field properties
    foreach my $field ( @{ $self->fields() } ) {
        my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
        $field_info{$field}{table} = $rtable;
        $field_info{$field}{field} = $rfield;

        # don't include primary fields (will be filled in with the insert call)
        unless ( ( grep( /$rfield/, @primary_fields ) ) ) {
            push( @fields, $field );
        }
    }

    # get data for the rows to be duplicated
    # if fields_ref and values_ref are defined, use them. Otherwise, try to grab information
    # from the current table
    if ( $values_ref && $fields_ref ) {
        @fields = @{$fields_ref};
        $value_hash{1} = $values_ref;
    }
    else {
        my $counter = 1;
        foreach my $index ( 1 .. $self->{record_count} ) {

            # if checkbox is checked, update values
            unless ( param("Row$index") ) {
                next;
            }
            my %values = %{ $self->values( -index => $index - 1 ) };
            my @row = ();
            foreach my $field (@fields) {
                push( @row, $values{$field} );
            }
            $value_hash{$counter} = \@row;
            $counter++;
        }
    }

    # do database insert
    $do->set_multi_values( -fields => \@fields, -values => \%value_hash );
    $do->insert();

    # reload page from db
    return 1;
}

#####################################
sub search_multi_table_display {
#####################################
    my $self = shift;

    # assume object was thawed already, and reconnected with db
    my $dbc             = $self->{dbc};
    my %args            = @_;
    my $limit           = $args{-limit};
    my $extra_condition = $args{-extra_condition} || param('Extra Condition');

    my @tables = @{ $self->{tables} };

    my $condition = "";
    my %field_info;

    # get field properties
    foreach my $field ( @{ $self->fields() } ) {
        my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
        my ($field_def) = get_field_types( $dbc, $rtable, $rfield );
        my ( $ref_table, $ref_field ) = foreign_key_check($rfield);

        $field_def =~ s/^\S+\s(.*)/$1/;
        $field_info{$field}{table}     = $rtable;
        $field_info{$field}{field}     = $rfield;
        $field_info{$field}{type}      = $field_def;
        $field_info{$field}{ref_table} = $ref_table;
        $field_info{$field}{ref_field} = $ref_field;
    }
    foreach my $field ( @{ $self->fields() } ) {
        my $rtable = $field_info{$field}{table};
        my $rfield = $field_info{$field}{field};
        unless ( grep /^$rtable$/, @tables ) {next}

        # if the value is set to anything other than blank, add to search
        unless ( param("${rtable}.${rfield}") ) {
            next;
        }
        my @array = param("${rtable}.${rfield}");

        # if the string is double quotes, set the value to blank
        $condition .= " ( ";
        foreach my $elem (@array) {

            # if elem is a fk, resolve first
            if ( defined $field_info{$field}{ref_table} ) {
                $elem = get_FK_ID( $dbc, $field_info{$field}{ref_field}, $elem );
            }

            # if elem is a date, resolve to SQL
            if ( $field_info{$field}{type} =~ /date/i ) {
                $elem =~ s/\*/%/g;
                if ( $elem =~ /[\?|\%]/ ) {
                    $condition .= " ${rtable}.${rfield} LIKE " . $dbc->dbh->quote( convert_date( $elem, 'SQL' ) . '%' ) . " OR ";
                }
                elsif ( $elem =~ /([\>=\<]+)\s*([\-\w]+)/ ) {
                    $condition .= " ${rtable}.${rfield} $1 " . $dbc->dbh->quote( convert_date( $2, 'SQL' ) ) . " OR ";
                }
                else {
                    $condition .= " ${rtable}.${rfield} = " . $dbc->dbh->quote( convert_date( $elem, 'SQL' ) ) . " OR ";
                }
            }
            elsif ( $field_info{$field}{type} =~ /time/i ) {
                $elem =~ s/\*/%/g;
                if ( $elem =~ /[\?|\%]/ ) {
                    $condition .= " ${rtable}.${rfield} LIKE " . $dbc->dbh->quote( convert_time($elem) . '%' ) . " OR ";
                }
                elsif ( $elem =~ /([\>=\<]+)\s*([\-\w]+)/ ) {
                    $condition .= " ${rtable}.${rfield} $1 " . $dbc->dbh->quote( convert_time($2) ) . " OR ";
                }
                else {
                    $condition .= " ${rtable}.${rfield} = " . $dbc->dbh->quote( convert_time($elem) ) . " OR ";
                }
            }

            # resolve range if given (6-9 will be resolved to 6,7,8,9
            else {
                $elem = &RGTools::RGIO::resolve_range($elem);
                foreach ( split ',', $elem ) {
                    $elem =~ s/\*/%/g;
                    if ( ( $elem eq "''" ) || ( $elem eq "\"\"" ) ) {
                        $condition .= " ${rtable}.${rfield} = '' OR ";
                    }
                    elsif ( $elem =~ /[\?|\%]/ ) {
                        $condition .= " ${rtable}.${rfield} LIKE '$elem' OR ";
                    }
                    else {
                        my $connector = '=';

                        # look for >, <, <=, >=, !=, and <>
                        if ( $elem =~ /(<=|>=|<>|!=|<|>)(.*)/ ) {
                            $connector = $1;
                            $elem      = $2;
                        }
                        $condition .= " ${rtable}.${rfield} $connector '$elem' OR ";
                    }
                }
            }
        }

        # remove trailing OR if exists
        if ( rindex( $condition, " OR " ) > 0 ) {
            $condition = substr( $condition, 0, rindex( $condition, " OR " ) );
        }
        $condition .= " ) AND ";
    }
    $condition .= "1";

    if ($extra_condition) { $condition .= " AND $extra_condition"; }

    # retrieve with values
    # if no condition, don't do anything
    if ($condition) {
        $self->load_Object( -condition => "$condition", -multiple => 1, -limit => $limit );
    }

    print "<I>Condition: $condition.</I>" . &vspace();
    print "Extra Condition: " . textfield( -name => 'Extra Condition', -size => 100, -default => '', -force => 1 ) . hr;

    # don't reload page from db
    return 0;
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################

########################################
# Resolves the FKs for a given (loaded) field
# Return: none
########################################
sub _resolve_fks {
    my $self = shift;

    # assume object was thawed already, and reconnected with db
    my $dbc      = $self->{dbc};
    my %args     = @_;
    my $fk_table = $args{-table};    # (Scalar) Table where the FK is located (necessary for resolving)
    my $fk_field = $args{-field};    # (Scalar) Name of FK field

    my ( $ref_table, $ref_field ) = foreign_key_check($fk_field);

    # grab query that will get the FK
    # if it is prefixed by an FK, resolve the parent table first
    # otherwise just use get_view()
    my ( $Vtable, $view, $order_view );
    my $query_field = $ref_field;
    if ( $fk_field =~ /^FK/ ) {
        ( $Vtable, $view, $order_view ) = get_view( $dbc, $ref_table, $ref_field, $ref_field );
        $query_field = $ref_field;
    }
    else {
        ( $Vtable, $view, $order_view ) = get_view( $dbc, $fk_table, $fk_field, $fk_field );
        $query_field = $fk_field;
    }

    # grab all the ids to get the FK for
    my $fk_items  = &unique_items( $self->{fields}{$fk_table}{$fk_field}{values} );
    my $condition = "('";
    $condition .= join( "','", @{$fk_items} );
    $condition .= "')";

    my $sth = $dbc->query( -query => "SELECT $view as viewFK$query_field,$query_field from $Vtable WHERE $query_field in $condition", -finish => 0 );
    my $data = &SDB::DBIO::format_retrieve( -sth => $sth, -format => "HofH", -keyfield => $query_field );

    # initialize/wipe out old FK data
    $self->{params}{fk_views}{$fk_table}{$fk_field} = {};

    # fill out FK data
    if ( defined $self->{fields}{$fk_table}{$fk_field}{values} ) {
        foreach my $count ( 1 .. @{ $self->{fields}{$fk_table}{$fk_field}{values} } ) {
            my $fk_value = $self->{fields}{$fk_table}{$fk_field}{values}[ $count - 1 ];

            # search for fk value of the return
            my $alt_value = $fk_value;
            if ( defined $data->{$fk_value}{"viewFK$query_field"} ) {
                $alt_value = $data->{$fk_value}{"viewFK$query_field"};
            }
            $self->{params}{fk_views}{$fk_table}{$fk_field}{$fk_value} = $alt_value;
        }
    }
    else { Message("No Data") }
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

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2004-11-29

=head1 REVISION <UPLINK>

$Id: DB_Object_Form.pm,v 1.21 2004/11/30 01:43:07 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
