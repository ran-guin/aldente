###################################################################################################################################
# SDB::Attribute.pm
#
# Model in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::Attribute;

use base LampLite::Attribute;
use strict;

use RGTools::RGIO;   ## include standard tools

##########################################
## A wraper to use API's set_attribute
##########################################
sub set_attribute {
##########################################
    ## <CONSTRUCTION> Copy from alDente_API's set_attribute, need to redirect API call to here (however, unsure why API's set_attribute use set_data)
    # my $API = alDente::alDente_API->new( -dbc => $dbc );
    # my $set_loading_conc = $API->set_attribute( -object => 'Plate', -attribute => 'Scheduled_Concentration', -list => \%attributes );
    #  or...
    #  $set_loading_conc = alDente::Attribute::set_attribute(-object=>'Plate', -attribute => 'Scheduled_Concentration', -id => $id, -value => $value);   ## or -list => { $id => $value; $id2 => $value2 ...}
    #
    my %args = filter_input( \@_, -args => 'dbc|self', -mandatory => 'dbc|self,object,attribute|attribute_id,list|value', -self => 'SDB::Attribute' );
    my $self = $args{-self};
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $object       = $args{-object};
    my $att          = $args{-attribute};
    my $attrib_id    = $args{-attribute_id};
    my $on_duplicate = $args{-on_duplicate};    ## either IGNORE or REPLACE (on duplicate key)

    my %list;
    my $quiet = $args{-quiet};
    my $start = timestamp();
    ## alternate input for simpler cases (only one attribute and value) ##
    my $id    = $args{-id};
    my $value = $args{-value};

    my @tables = $dbc->tables();

    if ( !grep( /^$object$/, @tables ) ) {
        return "Error: Unknown object '$object'";
    }

    if ( !grep( /^${object}_Attribute$/, @tables ) ) {
        return "Error: Can not store attributes for '$object'";
    }
    if ( $args{-list} ) {
        %list = %{ $args{-list} };
    }
    elsif ( $id && $value ) {
        ## alternate form of input for simple cases ##
        foreach my $id_N ( Cast_List( -list => $id, -to => 'array' ) ) {
            $list{$id_N} = $value;
        }
    }
    else {
        return $dbc->error('Must supply attribute list or id / value pair');
    }

    my $att_type;
    my %attrib_info;
    if ($att) {
        %attrib_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_ID', 'Attribute_Type' ], "WHERE Attribute_Class='$object' AND Attribute_Name='$att'" );
        $attrib_id   = $attrib_info{'Attribute_ID'}[0];
        $att_type    = $attrib_info{'Attribute_Type'}[0];
    }
    elsif ($attrib_id) {
        %attrib_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Name', 'Attribute_Type' ], "WHERE Attribute_Class='$object' AND Attribute_ID = '$attrib_id'" );
        $att         = $attrib_info{'Attribute_Name'}[0];
        $att_type    = $attrib_info{'Attribute_Type'}[0];
    }

    my $user_id = $dbc->get_local('user_id') || $args{-fk_employee_id};
    if ( !$attrib_id ) {
        return "Error: Unknown attribute '$att' for '$object'";
    }

    if ( !$user_id ) {
        return "Error: No FK_Employee__ID. Please provide fk_employee_id argument ";
    }
    my $datetime = &date_time();
    my ($primary_field) = $dbc->get_field_info( $object, undef, 'Primary' );
    my ($fk_field) = $dbc->_get_FK_name( "${object}_Attribute", $object, $primary_field );

    my @fields = ( $fk_field, 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' );
    my %values;

    my @keys = map {"'$_'"} keys %list;
    my @to_update_records = $dbc->Table_find( "${object}_Attribute", $fk_field, "WHERE $fk_field IN (" . join( ',', @keys ) . ") AND FK_Attribute__ID=$attrib_id" );

    #    if (@to_update_records) {#
    #        $dbc->warning("$att already defined for $object: @to_update_records");
    #	map { $list{"$_"} = undef } @to_update_records;
    #    }

    my $updates = 0;
    my $count   = 0;

    foreach my $key ( keys %list ) {
        my $value = $list{$key};
        if ( !defined $value ) {next}
        if ( $att_type =~ /^FK(\w*?)_(\w+)__(\w+)$/ ) {
            $value = $dbc->get_FK_ID( -field => $att_type, -value => $value );
        }
        elsif ( $att_type =~ /^Date/i ) {
            $value = convert_date( $value, 'SQL' );
        }

        ## block below unnecessary once newer version of mySQL allows REPLACE on Duplicate ##
        if ( $on_duplicate =~ /^REPLACE$/i ) {
            my ($fk_field) = $dbc->foreign_key( -table => $object );
            my ($existing_record) = $dbc->Table_find( "${object}_Attribute", 'Attribute_Value', "WHERE $fk_field='$key' AND FK_Attribute__ID=$attrib_id" );

            if ( defined $existing_record ) {
                ## update instead of setting attribute ##
                $dbc->Table_update_array( "${object}_Attribute", \@fields, [ $key, $attrib_id, $value, $user_id, $datetime ], "WHERE $fk_field='$key' AND FK_Attribute__ID=$attrib_id", -autoquote => 1 );
                $updates++;
                next;
            }

            #  $on_duplicate = '';    ## replace does not work in this version of mySQL
        }
        #############

        $values{ ++$count } = [ $key, $attrib_id, $value, $user_id, $datetime ];
    }

    my $newids;
    if (%values) {
        $newids = $dbc->smart_append( "${object}_Attribute", \@fields, \%values, -autoquote => 1 );
        $updates += int( @{ $newids->{"${object}_Attribute"}->{newids} } );
    }

    return $updates;
}

########################
sub get_Attributes {
########################
    my %args      = &filter_input( \@_, -args => 'dbc,table,id', -mandatory => 'table,id,dbc' );
    my $table_ref = $args{-table};
    my $record_id = $args{-id};
    my @tables    = Cast_List( -list => $table_ref, -to => "array" );
    my $dbc       = $args{-dbc};

    # when providing an ID user should only specify 1 table
    if ( scalar(@tables) > 1 && $record_id ) {
        Message("Invalid input");
        return 0;
    }
    my @attributes;

    my %return_attributes;
    foreach my $table (@tables) {
        my $id              = $record_id;
        my $attribute_table = $table . "_Attribute";
        ## adjust to work for non '_ID' tables (eg Library_Name) ##
        my ($fk_field) = $dbc->get_field_info( $table, undef, 'Primary' );
        $fk_field =~ s /$table/FK_$table\_/;
##
        if ( grep /^$attribute_table$/, $dbc->DB_tables() ) {
            my %attributes = Table_retrieve(
                $dbc, "$attribute_table,Attribute",
                [ "Attribute_ID", 'Attribute_Type', "Attribute_Name", "Attribute_Value", "$attribute_table" . "_ID" ],
                "WHERE FK_Attribute__ID=Attribute_ID AND Attribute_Class = '$table' AND $fk_field = '$id'"
            );
            if ( exists $attributes{Attribute_ID}[0] ) {
                my @attribute_ID    = @{ $attributes{Attribute_ID} };
                my @attribute_Name  = @{ $attributes{Attribute_Name} };
                my @attribute_Value = @{ $attributes{Attribute_Value} };
                my @table_attr_id   = @{ $attributes{ $attribute_table . "_ID" } };
                my @attribute_types = @{ $attributes{Attribute_Type} };

                for ( my $i = 0; $i < scalar(@attribute_ID); $i++ ) {

                    my $value = $attribute_Value[$i];
                    my $type  = $attribute_types[$i];
                    if ( $type =~ /^FK/ ) {
                        $value = $dbc->get_FK_info( $type, $value );    ## convert to readable form
                    }
                    $return_attributes{ $attribute_Name[$i] } = $value;
                }
            }
        }
    }
    return \%return_attributes;
}

##################################
sub get_Attribute_enum_list {
##################################
    my %args = &filter_input( \@_, -mandatory => 'id|name,dbc' );
    my $id   = $args{-id};
    my $name = $args{-name};
    my $dbc  = $args{-dbc};
    my @options;
    my %attribute_info;

    if ($id) {
        %attribute_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Name', 'Attribute_Type' ], "WHERE Attribute_ID = $id" );
    }
    elsif ($name) {
        %attribute_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Name', 'Attribute_Type' ], "WHERE Attribute_Name = '$name'" );
    }
    my $type   = $attribute_info{Attribute_Type}[0];
    my $prompt = $attribute_info{Attribute_Name}[0];

    if ( $type =~ /enum\((.+)\)/i ) {
        my $list = $1;
        @options = split ',', $list;
        map { ~s/^[\'\"]//; ~s/[\'\"]$//; } @options;
    }
    return @options;
}

##################################
sub get_Attribute_FK_Table {
##################################
    my %args  = &filter_input( \@_, -mandatory => 'id|name,dbc' );
    my $id    = $args{-id};
    my $name  = $args{-name};
    my $dbc   = $args{-dbc};
    my $class = $args{-class};

    my $extra_condition = '';
    if ($class) { $extra_condition .= " AND Attribute_Class = '$class' " }

    my %attribute_info;
    my $table;
    if ($id) {
        %attribute_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Name', 'Attribute_Type' ], "WHERE Attribute_ID = $id $extra_condition" );
    }
    elsif ($name) {
        %attribute_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Name', 'Attribute_Type' ], "WHERE Attribute_Name = '$name' $extra_condition" );
    }
    my $type   = $attribute_info{Attribute_Type}[0];
    my $prompt = $attribute_info{Attribute_Name}[0];

    if ( $type =~ /^FK([A-Za-z0-9]*?)_(\S+)__(\S+)/ ) {
        $table = $2;
    }
    return $table;
}

##################################
sub merged_Attribute_value {
##################################
    my %args      = &filter_input( \@_, -mandatory => 'dbc,attribute|id,values' );
    my $attribute = $args{-attribute};
    my $values    = $args{ -values };
    my $dbc       = $args{-dbc};
    my $id        = $args{-id};
    my $merged_value;

    # get attribute type
    my $att_type;
    my %attrib_info;

    if   ($attribute) { %attrib_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Type', 'Attribute_Name' ], "WHERE Attribute_Name='$attribute'" ); }
    else              { %attrib_info = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Type', 'Attribute_Name' ], "WHERE Attribute_ID='$id'" ); }
    $att_type = $attrib_info{'Attribute_Type'}[0];
    my $att_name = $attrib_info{'Attribute_Name'}[0];

    # handle same values
    my $flag    = 0;
    my $default = @$values[0];
    foreach my $value (@$values) {
        if ( $att_type =~ /^Text|VAR/i ) {
            if ( lc($default) ne lc($value) ) { $flag = 1 }
        }
        else {
            if ( $default !~ /^$value$/i ) { $flag = 1 }
        }
    }
    if ( !$flag ) { return $default }

    # check attribute type and calculate merged value
    if ( $att_type =~ /^FK/i ) {
        my $mixed_id = $dbc->get_FK_ID( -field => $att_type, -value => 'Mixed', -quiet => 1 );

        if ($mixed_id) { $merged_value = $mixed_id; }
    }
    elsif ( $att_type =~ /enum\((.+)\)/i ) {
        my $flag    = 0;
        my $list    = $1;
        my @options = Cast_List( -list => $list, -to => 'Array' );
        map { ~s/^[\'\"]//; ~s/[\'\"]$//; } @options;

        foreach my $option (@options) {
            if ( $option =~ /^mixed$/i ) { $flag = 1; }
        }

        if ($flag) { $merged_value = 'Mixed' }

        #        else         { $merged_value = 'NULL' }
    }
    elsif ( $att_type =~ /^Text|VAR/i ) {
        ## comment out merging of the text type values. If the values are different, there shouldn't be a merged value
        #foreach my $value (@$values) {
        #    if ( $merged_value ne '' ) { $merged_value .= ' + '; }
        #    $merged_value .= $value;
        #}
        $dbc->warning("Attribute values for $att_name are different and not merged. Please set it manually.");
    }
    else {

        #        $merged_value = 'NULL';
    }

    return $merged_value;
}

################################################
# Check attribute format
#
# Input:
#		-dbc :	the database connection
#		-attributes	:	list of attribute names. NOTE: -ids should be used instead of -attributes whenever possible since attribtue names are not unique.
#		-ids		:	list of attribute ids
#		-values		:	list of attribute values. The number of values must match the number of attributes/ids
#		-mandatory	:	array ref of mandatory attribute names or ids.
#						If -attribute is passed in, -mandatory is assumed to have attribute names;
#						if -ids is passed in, -mandatory is assumed to have attribute ids.
#		-fk_reference	: flag to indicate the values for the FK attribute type are referenced values, not the FK IDs. This usually happens in template upload.
#
# Return :
#		( $good, \@messages )
#		If all the values pass the format check, $good = 1; otherwise 0
#		The second item being returned is an array ref of messages. If the value is validated, the message string is empty; if not, the string indicates the error message
################################################
sub check_attribute_format {
    my %args = &filter_input( \@_, -args => 'dbc,names,ids,class,values,mandatory,fk_reference', -mandatory => 'dbc,names|ids,values' );
    my $dbc = $args{-dbc};
    my $names        = $args{-names};           # list of attribute names. NOTE: -ids should be used instead of -attributes whenever possible since attribtue names are not unique.
    my $values       = $args{ -values };        # list of attribute values
    my $ids          = $args{-ids};             # list of attribute ids
    my $class        = $args{-class};           # Attribute Class
    my $mandatory    = $args{-mandatory};       # list of mandatory attributes
    my $fk_reference = $args{-fk_reference};    # flag to indicate the values for the FK attribute type are referenced values, not the FK IDs.

    my @input_values = Cast_List( -list => $values, -to => 'array' );
    my @input_attributes;
    my $attribute_info;
    if ($ids) {
        @input_attributes = Cast_List( -list => $ids, -to => 'array' );
        my $distinct_list = RGmath::distinct_list( \@input_attributes );
        $attribute_info = get_attribute_info( -dbc => $dbc, -ids => $distinct_list, -class => $class );
    }
    elsif ($names) {
        @input_attributes = Cast_List( -list => $names, -to => 'array' );
        my $distinct_list = RGmath::distinct_list( \@input_attributes );
        $attribute_info = get_attribute_info( -dbc => $dbc, -names => $distinct_list, -class => $class );
    }

    my @input;
    my @mandatory_ids;
    if ($ids) {
        @input = @$ids;
        @mandatory_ids = Cast_List( -list => $mandatory, -to => 'array' ) if ($mandatory);
    }
    elsif ($names) {
        ## build reverse lookup hash
        my %reverse_lookup;
        foreach my $id ( keys %$attribute_info ) {
            $reverse_lookup{ $attribute_info->{$id}{Attribute_Name} } = $id;
        }

        foreach my $attribute (@input_attributes) {
            push @input, $reverse_lookup{$attribute};
        }
        if ($mandatory) {
            my @mandatory_att = Cast_List( -list => $mandatory, -to => 'array' );
            foreach my $attribute (@mandatory_att) {
                push @mandatory_ids, $reverse_lookup{$attribute};
            }
        }
    }

    my $good = 1;
    my @messages;
    foreach my $index ( 0 .. $#input ) {
        my $id     = $input[$index];
        my $value  = @input_values[$index];
        my $format = $attribute_info->{$id}{Attribute_Format};
        my $type   = $attribute_info->{$id}{Attribute_Type};
        my $name   = $attribute_info->{$id}{Attribute_Name};

        my $msg = '';
        if ( !$value ) {
            if ( grep /^$id$/, @mandatory_ids ) {
                $good = 0;
                $msg  = "Attribute $name is Mandatory";
            }
            next;
        }
        elsif ( $format && $value !~ /$format/ ) {
            $good = 0;
            if ( $type =~ /INT/i || $type =~ /Decimal/i || $type =~ /enum/i ) {
                $msg = "Attribute $name (value=$value) should match type $type format";
            }
            else {
                $msg = "Attribute $name (value=$value) should match pattern \"$format\"";
            }
        }
        elsif ( $type =~ /^FK/i ) {
            ################
            ## For the FK attributes, since they always appear as dropdowns, which can prevent user from entering invalid values already. So the format check here probably can be turned off.
            ################
            #my $table;
            #if ( $type =~ /^FK([A-Za-z0-9]*?)_(\S+)__(\S+)/ ) {
            #    $table = $2;
            #}
            #my @option_list;
            #if ($fk_reference) { @option_list = $dbc->get_FK_info( $type, -list => 1 ) }
            #else               { @option_list = $dbc->get_Primary_ids( -tables => $table, -ref_table => $table ) }
            #if ( !grep /^$value$/, @option_list ) {
            #    $good = 0;
            #    $msg  = "'$value' NOT a recognized value for " . $attribute_info->{$id}{Attribute_Class} . '_Attribute.' . $name . ' -- ' . $type;
            #}
        }

        push @messages, $msg;
    }

    return ( $good, \@messages );
}

#####################################
# Retrieve attribute information. The default attribute format for types Int, Decimal, amd ENUM are retrieved here.
#
# Input:
#		dbc		- the database connection
#		names	- list of attribute names
#		ids		- list of attribtue ids
#		class	- specify attribute class
#		grp		- specify group
# Output:
#		Hash ref of the attribute information
#####################################
sub get_attribute_info {
    my %args  = &filter_input( \@_, -args => 'dbc,names,ids,class,grp', -mandatory => 'dbc' );
    my $dbc   = $args{-dbc};
    my $names = $args{-names};
    my $ids   = $args{-ids};
    my $class = $args{-class};                                                                   # attribute class
    my $grp   = $args{-grp};
    my $list  = $args{-list};

    ## get attribute information
    my $tables     = 'Attribute';
    my $conditions = ' WHERE 1 ';
    if ($ids) {
        my $id_list = Cast_List( -list => $ids, -to => 'string', -autoquote => 0 );
        $conditions .= " AND Attribute_ID in ( $id_list ) ";
    }
    elsif ($names) {
        my $name_list = Cast_List( -list => $names, -to => 'string', -autoquote => 1 );
        $conditions .= " AND Attribute_Name in ( $name_list ) ";
    }
    if ($class) { $conditions .= " AND Attribute_Class = '$class' " }
    if ($grp) {
        $tables     .= ",Grp";
        $conditions .= " AND FK_Grp__ID = Grp_ID AND ( Grp_ID = '$grp' OR Grp_Name = '$grp' )";
    }
    my %hash = $dbc->Table_retrieve( $tables, [ 'Attribute_ID', 'Attribute_Name', 'Attribute_Format', 'Attribute_Type', 'Attribute_Class', 'Attribute_Description', 'Inherited', 'FK_Grp__ID', 'Attribute_Access' ], "$conditions" );

    my %attribute_info;
    my $index = 0;
    while ( defined $hash{'Attribute_ID'}[$index] ) {
        my $id = $hash{'Attribute_ID'}[$index];
        $attribute_info{$id}{Attribute_Name}        = $hash{'Attribute_Name'}[$index];
        $attribute_info{$id}{Attribute_Type}        = $hash{'Attribute_Type'}[$index];
        $attribute_info{$id}{Attribute_Class}       = $hash{'Attribute_Class'}[$index];
        $attribute_info{$id}{Attribute_Description} = $hash{'Attribute_Description'}[$index];
        $attribute_info{$id}{Inherited}             = $hash{'Inherited'}[$index];
        $attribute_info{$id}{FK_Grp__ID}            = $hash{'FK_Grp__ID'}[$index];
        $attribute_info{$id}{Attribute_Access}      = $hash{'Attribute_Access'}[$index];

        if ( $hash{'Attribute_Format'}[$index] ) {
            $attribute_info{$id}{Attribute_Format} = $hash{'Attribute_Format'}[$index];
        }
        elsif ( $hash{'Attribute_Type'}[$index] =~ /^Int/i ) {
            $attribute_info{$id}{Attribute_Format} = '^(\+|-)?[\d]+$';
            if ($list) {
                $attribute_info{$id}{Attribute_Format} .= " list";
            }
        }
        elsif ( $hash{'Attribute_Type'}[$index] =~ /^Decimal/i ) {
            $attribute_info{$id}{Attribute_Format} = '^(\+|-)?[\d]+(\.\d+)?$';
            if ($list) {
                $attribute_info{$id}{Attribute_Format} .= " list";
            }
        }
        elsif ( $hash{'Attribute_Type'}[$index] =~ /^enum\((.+)\)/i ) {
            my $list = $1;
            my @options = split ',', $list;
            map { ~s/^\s+//; ~s/\s+$//; ~s/^[\'\"]//; ~s/[\'\"]$// } @options;
            my @converted_options;
            foreach my $option (@options) {
                $option = "^\Q$option\E\$";
                push @converted_options, $option;
            }
            $attribute_info{$id}{Attribute_Format} = join "|", @converted_options;
        }
        $index++;
    }

    return \%attribute_info;
}

#############################################
sub validate_attribute_name_trigger {
############################################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $id   = $self->{id};

    ## Check to see if the new Attribute_Name is the a duplicate of DBField.Field_Name
    my ($duplicate) = $dbc->Table_find( 'Attribute,DBField', 'COUNT(*)', "WHERE Attribute_Name = Field_Name and Attribute_ID = $id" );

    if ($duplicate) {
        $dbc->{session}->error("Duplicate Attribute Name and Field Name. Please re-name the attribute");
        return 0;
    }
    return 1;
}


1;


