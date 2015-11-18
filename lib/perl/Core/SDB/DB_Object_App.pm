############################
# SDB::DB_Object_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package SDB::DB_Object_App;

##############################
# standard_modules_ref       #
##############################
use base LampLite::DB_Object_App;

use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::RGmath;

use SDB::DBIO;

use SDB::DB_Object;
use SDB::DB_Object_Views;
use SDB::DB_Form_Viewer;

##############################
# global_vars                #
##############################
use vars qw(%Configs);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $dbc;
my $q;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'             => 'home_page',
            'home'                => 'home_page',
            'View Changes'        => 'view_changes',
            'Edit Records'        => 'edit_records',
            'Search Records'      => 'search_Records',
            'Find Records'        => 'find_Records',
            'Confirm Propogation' => 'confirm_propogation',
            'Add Record'          => 'new_Record',
            'Convert Records'     => 'convert_Records',
            'Save Record'         => 'save_New_Record',
            'Display Record'      => 'display_Record',
        }
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    my $DB_Object = new SDB::DB_Object( -dbc => $dbc );
    $self->param( 'DB_Object_Model' => $DB_Object, );

    $ENV{CGI_APP_RETURN_ONLY} = 1;    ## flag SUPPRESSES automatic printing of return value when true

    return $self;
}

#
# Generic new record form
###################
sub new_Record {
###################
    my $self = shift;

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my $table          = $q->param('Table');
    my $frozen_configs = $q->param('DB_Form_Configs');

    my $auto_nav = 1;

    my $configs;
    if ($frozen_configs) { $configs = Safe_Thaw( -name => 'DB_Form_Configs', -thaw => 1, -encoded => 1 ) }

    require SDB::HTML;
    
    my $output;
    if ($table) {
        my ($type) = $dbc->Table_find( 'DBTable', 'DBTable_Type', "WHERE DBTable_Name = '$table'" );
        if ( $type eq 'Lookup' ) {
            $output .= SDB::HTML::create_tree( -tree => { "Current $table list" => $dbc->Table_retrieve_display( $table, ['*'], -return_html => 1, -title => "Current $table list" ) } );
        }
        my $form;

        if ($auto_nav) {
            $form = &SDB::DB_Form_Viewer::add_record( $dbc, $table, -configs => $configs, -groups => $dbc->get_local('group_list'), -return_html => 1 );
        }
        else {
            $form = SDB::DB_Object_Views::new_Record_form( -dbc => $dbc, -table => $table, -return_html => 1 );
        }

        $output .= $form;
    }
    else { print $dbc->warning("No table specified"); }

    return $output;
}

#####################
sub display_Record {
#####################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $class = $q->param('Table') || $q->param('Class');
    my $id    = $q->param('ID');
    
    return $self->View->std_home_page(-class=>$class, -id=>$id);
}


######################
sub save_New_Record {
######################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $table          = $q->param('DBTable');
    my $frozen_configs = $q->param('DB_Form_Configs');

    my $configs;
    if ($frozen_configs) { $configs = Safe_Thaw( -name => 'DB_Form_Configs', -thaw => 1, -encoded => 1 ) }

    my %input = $dbc->Table_retrieve( 'DBField', [ 'Field_Name', 'Field_Type' ], "WHERE Field_Table = '$table'" );

    my ( $index, @fields, @values ) = (0);
    while ( defined $input{Field_Name}[$index] ) {
        my $field = $input{Field_Name}[$index];
        my $type  = $input{Field_Type}[$index];
        $index++;

        if ( defined $q->param($field) ) {
            my @vals  = $q->param($field);
            my $value = $vals[0];
            if ( @vals > 1 && $type =~ /^SET/i ) {
                $value = join "','", @vals;
                $value = "'$value'";
            }
            if ( $value =~ /\w/ ) {
                push @fields, $field;
                push @values, $value;
            }
        }
    }

    my $id;
    if (@fields) {
        $id = $dbc->Table_append_array( $table, \@fields, \@values, -autoquote => 1 );
    }

    $dbc->session->homepage("$table=$id");

    return;
}

#
# Method to enable users to easily access LIMS IDs given another identifier field
#
#  (eg Patient Identifier, or Source.External_Identifier)
#
#
#######################
sub convert_Records {
#######################
    my $self           = shift;
    my $q              = $self->query();
    my $convert_field  = $q->param('Convert_Field');
    my $convert_string = $q->param('Convert_String');

    my ( $results, $table, $field );
    if ( $convert_field =~ /(\w+)\.(\w+)/ ) {
        $table = $1;
        $field = $2;

        my @list = split /\n/, $convert_string;    ## may change to offer different options for delimiter
        my $list = Cast_List( -list => \@list, -to => 'string', -autoquote => 1, -trim_leading_spaces => 1 );

        my @ids = $dbc->Table_find( $table, "${table}_ID AS ID", "WHERE $convert_field IN ($list)" );
        my $ids = Cast_List( -list => \@ids, -to => 'string' );

        $results = alDente::Attribute_Views::show_attribute_link( -dbc => $dbc, -object => $table, -id => $ids );

        $results .= $dbc->Table_retrieve_display(
             $table, [ $convert_field, "${table}_ID AS ID", "${table}_ID as $table" ], "WHERE $convert_field IN ($list)",
            -title       => 'Converted IDs',
            -return_html => 1,
            -border      => 1,
            -alt         => 'No matches found',
            -excel_link  => 1,
            -csv_link    => 1,
        );
    }

    return $results;
}

#####################
sub edit_records {
#####################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $table   = $q->param('Table');
    my $ids     = $q->param('ID');
    my $require = $q->param('Require');

    return $self->View->edit_Data_form( -dbc => $dbc, -table => $table, -ids => $ids, -require => $require );
}

################
sub home_page {
################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $id = $q->param('ID') || $q->param('DB_Object_ID');

    $dbc->session->reset_homepage("DB_Object=$id");

    #    return alDente::Template_Views($dbc,$id);
}

################
sub confirm_propogation {
################
    my $self    = shift;
    my $q       = $self->query();
    my $dbc     = $self->param('dbc');
    my $ids     = $q->param('ids');
    my $class   = $q->param('class');
    my @fields  = $q->param('field');
    my @values  = $q->param('value');
    my $confirm = $q->param('confirm');

    return $self->param('DB_Object_Model')->propogate_field(
        -class   => $class,
        -field   => \@fields,
        -value   => \@values,
        -ids     => $ids,
        -confirm => $confirm,
        -dbc     => $dbc
    );
}

######################
sub view_changes {
######################
    my $self = shift;
    my $q    = $self->query();

    my $dbc  = $self->param('dbc');
    my $page = "<h2>Changes to Database Record (for fields explicitly identified for tracking)</H2>";

    my $table = $q->param('Table');
    my $id    = $q->param('ID');

    my $id_list = Cast_List( -list => $id, -to => 'string', -autoquote => 1 );    ## enable autoquoting in case of string (eg library ids)

    my ($primary) = $dbc->get_field_info( -table => $table, -type => 'Primary' );

    my %Changes = $dbc->Table_retrieve(
        "Change_History,DBField,$table",
        [ $primary, 'DBField.Field_Name', 'Change_History.Old_Value', 'Change_History.New_Value', 'Change_History.FK_Employee__ID', 'Change_History.Modified_Date' ],
        "WHERE Record_ID = $primary AND FK_DBField__ID=DBField_ID AND Field_Table='$table' AND Record_ID IN ($id_list)",
    );

    my $Change = HTML_Table->new( -title => "Tracked edits to $table : $id_list" );
    $Change->Set_Headers( [ $table, 'Field', 'Old_Value', 'New_Value', 'Changed_By', 'Modification_Date' ] );
    $Change->Toggle_Colour_on_Column(2);
    my $i = 0;
    while ( defined $Changes{Field_Name}[$i] ) {
        my $primary  = $Changes{$primary}[$i];
        my $field    = $Changes{Field_Name}[$i];
        my $old      = $Changes{Old_Value}[$i];
        my $new      = $Changes{New_Value}[$i];
        my $emp      = $Changes{FK_Employee__ID}[$i];
        my $modified = $Changes{Modified_Date}[$i];

        if ( my ( $rtable, $rfield ) = foreign_key_check($field) ) {
            my $old_link = Show_Tool_Tip( $dbc->get_FK_info( $field, $old ), $old );
            my $new_link = Show_Tool_Tip( $dbc->get_FK_info( $field, $new ), $new );
            ( $old, $new ) = ( $old_link, $new_link );
        }

        $Change->Set_Row( [ $primary, $field, $old, $new, $emp, $modified ] );
        $i++;
    }
    $page .= $Change->Printout(0);

    $page .= '<hr>';

    $page .= $dbc->Table_retrieve_display( 'DBField', [ 'Field_Name', 'Tracked', 'Editable' ], "WHERE Field_Table = '$table' AND Tracked = 'yes'", -return_html => 1, -title => "Currently tracked $table fields" );
    return $page;
}

#########################
sub search_Records {
#########################
    my $self         = shift;
    my $table        = $q->param('Table');
    my $condition    = $q->param('Condition');
    my $preset       = $q->param('Preset');
    my $multi_record = $q->param('Multi-Record');

    my $dbc          = $self->param('DB_Object_Model')->dbc();
    my $start_search = $q->param('Start Search');

    my $encoded_condition = $q->param('Encoded_Condition');
    if ($encoded_condition) { $condition .= url_decode($encoded_condition) }

    my %Order;    ## <CONSTRUCTION> - adjust to allow for ordering as before..
    my %Preset;
    if ($preset) {
        my @preset_fields = split ',', $preset;
        foreach my $field (@preset_fields) {
            @{ $Preset{$field} } = split ',', $q->param($field);
        }
    }

    my $simple      = $q->param('SimpleSearch');
    my $search_list = $q->param('Search List');
    if ($multi_record) {
        my $primary = get_field_info( $dbc, $table, undef, 'pri' );
        my $ordered;
        if ( defined $Order{$table} ) {
            $ordered = $Order{$table} . " desc";
        }
        else { $ordered = "$primary desc"; }

        &SDB::DB_Form_Viewer::edit_records( $dbc, $table, -primary => $primary, -list => $search_list, -order => $ordered, -condition => $condition );
        return 1;
    }

    my $page = $self->View->search_form( -table => $table, -condition => $condition,, -preset => \%Preset );
    return $page;
}

######################
sub find_Records {
######################
    my $self      = shift;
    my $tables    = $q->param('Table');
    my $debug     = $q->param('Debug');
    my $condition = $q->param('Condition') || 1;
    my @selected  = $q->param('Select');
    my $page      = "Searching for records...";

    my @conditions;
    my @fields;
    my @attribute_fields;
    my $join_tables;
    my @join_conditions;
    my @hidden_conditions;    ## don't need to show join conditions... ##

    my %subtitles;
    my $subtitles = 1;
    my @colours = ( 'mediumgreenbw', 'mediumbluebw' );

    if ($condition) { push @conditions, $condition }

    require SDB::HTML;
    
    foreach my $table ( split ',', $tables ) {

        my @table_fields = $dbc->get_field_info( -table => $table );
        if (@selected) {
            ## only specific fields have been selected ##
            my ($selected) = RGmath::intersection( \@table_fields, \@selected );
            if ($selected) { @table_fields = @$selected }

            my ($primary) = $dbc->get_field_info( -table => $table, -type => 'Primary' );
            if ( !grep /\b$primary\b/, @table_fields ) { unshift @table_fields, $primary }    ## primary fields required
        }

        my %attributes = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_ID', 'Attribute_Name', 'Attribute_Type' ], "WHERE Attribute_Class = '$table'" );

        foreach my $field (@table_fields) {
            my @values;
            if ( length( $q->param($field) ) > 1 ) {
                @values = $q->param($field);
            }
            elsif ( length( $q->param("$field Choice") ) ) {
                @values = $q->param("$field Choice");
            }
            elsif ( length( $q->param("to_$field") ) || length( $q->param("from_$field") ) ) {
                if ( $q->param("from_$field") ) { $values[0] .= ' > ' . $q->param("from_$field") }
                if ( $q->param("to_$field") )   { $values[0] .= ' < ' . $q->param("to_$field") }
            }
            ## Checking for input of range: can search if field is a primary key of type int and not and FK
            my ($fk) = $dbc->foreign_key_check($field);
            if ( grep /$field/, $dbc->get_field_info( -table => $table, -type => 'Primary' ) && ( grep /$field/, $dbc->get_field_info( -table => $table, -type => 'int' ) ) && !$fk ) {
                $_ = RGTools::Conversion::extract_range($_) foreach (@values);
            }

            if ( !SDB::HTML::dropdown_header( $values[0] ) && length( $values[0] ) > 1 ) {
                push @conditions, SDB::HTML::add_SQL_search_condition( $dbc, "$table.$field", \@values );
                my $options = join ' OR ', @values;
            }
        }

        my $i = 0;
        while ( defined $attributes{'Attribute_ID'}[$i] ) {
            my $attr_id   = $attributes{Attribute_ID}[$i];
            my $attr_name = $attributes{Attribute_Name}[$i];
            my $attr_type = $attributes{Attribute_Type}[$i];

            $attr_name =~ s/\s/\_/g;

            ### Standard Attributes ###
            my $element_name = "Set_Att_$attr_id";
            my @values = grep /./, $q->param("Set_Att_$attr_id");    ## get all non-empty values
            my @fk_values;
            if ( $attr_type =~ /^FK/ ) {
                @fk_values = $q->param("ATT$attr_id") | $q->param("ATT$attr_id Choice") | $q->param("ATT$attr_id+Choice");
                if (@fk_values) {
                    @values = map { $dbc->get_FK_ID( $attr_type, $_ ) } @fk_values;
                }
            }
            my $value_length = length( $values[0] );

            if ( length( $values[0] ) > 0 ) {
                $join_tables .= ",${table}_Attribute AS $attr_name";
                push @join_conditions, SDB::HTML::add_SQL_search_condition( $dbc, "$attr_name.Attribute_Value", \@values );

                my $options    = join ' OR ', @values;
                my $fk_options = join ' OR ', @fk_values;
                push @hidden_conditions, "$attr_name.FK_${table}__ID=${table}_ID AND $attr_name.FK_Attribute__ID=$attr_id";
                ## <construction> need to adjust above condition library attributes ##
                push @attribute_fields, "$attr_name.Attribute_Value AS $attr_name";
            }
            $i++;
        }

        my @local_fields = map {"$table.$_"} @table_fields;
        push @fields, @local_fields;

        $subtitles{$subtitles}{title}   = "$table data";
        $subtitles{$subtitles}{colspan} = int(@local_fields);
        my $colour_index = $subtitles - 1 % int(@colours);
        $subtitles{ $subtitles++ }{colour} = $colours[$colour_index];
    }

    my $final_condition = join ' AND ', @conditions, @join_conditions, @hidden_conditions;

    my $page;
    my $show_conditions = "<UL><LI>";
    $show_conditions .= join '<LI>', @conditions, @join_conditions;
    $show_conditions .= "</UL>";

    $page .= SDB::HTML::create_tree( -tree => { 'Conditions' => $show_conditions } );

    $page .= $dbc->Table_retrieve_display(
        $tables . $join_tables,
        [ @fields, @attribute_fields ],
        "WHERE $final_condition",
        -title       => "$tables Records found",
        -return_html => 1,
        -debug       => $debug,
        -print_link  => 1,
        -excel_link  => 1,
        -sub_titles  => \%subtitles,
        -debug       => $debug
    );

    $page .= '<HR>';

    #    $page .= 'or search again...<BR>';
    #    $page .= SDB::DB_Object_Views::search_form(-dbc=>$dbc, -table=>$tables, -condition=>$condition);

    return $page;
}

return 1;
