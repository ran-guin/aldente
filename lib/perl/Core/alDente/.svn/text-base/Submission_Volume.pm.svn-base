################################################################################
#
# Submission_Volume.pm
#
# This module handles data submission
################################################################################

package alDente::Submission_Volume;

use CGI qw(:standard);

##############################
# superclasses               #
##############################
use base SDB::DB_Object;
use strict;
##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################
use Data::Dumper;
use XML::Parser;
use YAML;
use FindBin;
use List::Util;
use List::MoreUtils;

#use Net::FTP;

##############################
# custom_modules_ref         #
##############################
use SDB::Xml_Tree;
use RGTools::RGIO;
use RGTools::RGmath;
use SDB::DB_Object;
use SDB::CustomSettings;
use Cluster::Cluster;
use SDB::HTML;
use List::MoreUtils;

use CGI::Carp('fatalsToBrowser');
use vars qw( %Configs );

#****************************
#****************************
##############################
# Constructor                #
##############################
sub new {
##############################
    my $this  = shift;
    my $class = ref($this) || $this;
    my %args  = filter_input( \@_ );

    my $self = $this->_init(@_);
    bless $self, $class;

    return $self;
}

#****************************
#****************************
##############################
# Initialization function    #
#
# Stuff that should be in the constructor, but separated out because
# this helps with calling from inherited class constructors
# (like SRA::Data_Submission)
##############################
sub _init {
##############################
    my $this = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my $self = $this->SUPER::new( -dbc => $dbc, -tables => 'Submission_Volume' );

    if ($id) {
        $self->{id} = $id;
    }

    $self->{dbc}            = $dbc;
    $self->{submission_dir} = $args{-submission_dir} || $Configs{data_submission_dir};
    $self->{workspace_dir}  = $args{-workspace_dir} || $Configs{data_submission_workspace_dir};

    return $self;
}

##############################
# Mutator functions          #
##############################

##############################
### Set primary key values for object
### (Used in lieu of DB::Object->primary_key()
##############################
sub set_pk_value {
##############################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $value = $args{-value};

    my $values = Cast_List( -to => 'arrayref', -list => $value );
    $self->{id} = $values;
}

##############################
### Set primary key values for object based on
### the values of other fields in the corresponding DB Table
###
##############################
sub set_field_value {
##############################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc} || $self->{dbc};
    my $values = $args{ -values };

    my @conditions;

    while ( my ( $field, $value ) = each( %{$values} ) ) {
        my $value_str = Cast_List( -to => 'string', -list => $value, -autoquote => 1 );
        push @conditions, "$field IN ($value_str)";
    }

    my $condition = "WHERE 1";
    $condition .= " AND " . join( ' AND ', @conditions ) if scalar( @conditions > 0 );

    my @primary_keys = $dbc->Table_find(
        -fields    => "Submission_Volume_ID",
        -table     => "Submission_Volume",
        -condition => $condition,

    );

    $self->set_pk_value( -value => [@primary_keys] );

    return @primary_keys;
}

##############################
# Accessor functions         #
##############################

##############################
### Retrieve primary key values for object
### (Used in lieu of DB::Object->primary_key()
##############################
sub get_pk_value {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );

    if ( wantarray() ) {
        return @{ $self->{id} };
    }
    else {
        return Cast_List( -to => 'string', -list => $self->{id} );
    }
}

##############################
sub get_Volume_data {
##############################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc};
    my $debug = $args{-debug};

    my $id = $self->get_pk_value();

    return $self->get_Submission_Volume_data( %args, -submission_volume_id => $id );
}

#****************************
#*****************************
##############################
# get_incomplete_Volume_data         #
##############################
sub get_all_incomplete_Volumes {
##############################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc};
    my $debug = $args{-debug};

    my $fields = $args{-fields};

    my @incomplete_statuses = ( 'Requested', 'Created', 'Bundled', 'Submitted', 'In Process', 'Waiting for Admin', 'Approved by Admin' );

    my $condition = "WHERE Status.Status_Name in (" . Cast_List( -to => 'string', -list => \@incomplete_statuses, -autoquote => 1 ) . ")";

    my @required_tables = ('Status');

    my $order = "Submission_Volume.Submission_Date desc";

    return $self->get_Submission_Volume_data( -fields => $fields, -required_tables => \@required_tables, -condition => $condition, -order => $order, -debug => $debug );
}

###
### This insert function is inspired from the
### "populate" function in the ORM package DBIx::Class
###
###

##############################
sub insert {
##############################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $dbc        = $args{-dbc} || $self->{'dbc'};
    my $table      = $args{-table} || $self->{DBobject};
    my $values_ref = $args{ -values } || [];
    my $debug      = $args{-debug};

    my $i = 1;
    my %row_hash;

    my @values = @{$values_ref} if ( ref($values_ref) eq 'ARRAY' );

    my $fields;
    my %row_hash;

    if ( scalar(@values) > 0 ) {

        if ( ref( $values[0] ) eq 'ARRAY' ) {
            $fields = shift @values;

            my $i = 1;
            foreach my $row (@values) {
                $row_hash{$i} = $row;
                $i++;
            }

        }
        elsif ( ref( $values[0] ) eq 'HASH' ) {

            my @keys   = keys( %{ $values[0] } );
            my $fields = \@keys;

            my $i = 1;
            foreach my $hash_ref (@values) {
                my %hash = %{$hash_ref};

                my @row = @hash{@keys};
                $row_hash{$i} = \@row;
                $i++;
            }

        }

        my $insert_retval = $dbc->smart_append(
            -table     => $table,
            -fields    => $fields,
            -values    => \%row_hash,
            -autoquote => 1,
        );

        return @{ $insert_retval->{$table}->{newids} };
    }

    else {
        return 0;
    }
}

##############################
sub insert_Trace_Submission {
##############################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $dbc        = $args{-dbc} || $self->{'dbc'};
    my $tuples_ref = $args{-tuples} || [];

    my @tuples = @{$tuples_ref} if ( ref($tuples_ref) eq 'ARRAY' );

    my @fields = qw/FK_Run__ID FK_Sample__ID FK_Submission_Volume__ID FK_Status__ID/;

    my ($status_id) = $dbc->Table_find(
        -fields    => "Status_ID",
        -table     => "Status",
        -condition => "WHERE Status_Type = 'Submission' AND Status_Name = 'Requested'",
    );

    my $Submission_Volume_id = $self->get_pk_value();

    my @rows;

    foreach my $tuple (@tuples) {
        push @rows, [ @{$tuple}, $Submission_Volume_id, $status_id ];
    }

    if ( scalar(@rows) > 0 ) {
        return $self->insert(
            -table  => 'Trace_Submission',
            -values => [ [@fields], @rows ]
        );
    }
    else {
        return ();
    }
}
##############################
sub insert_Analysis_File {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{'dbc'};

    my @paths      = Cast_List( -to => 'array', -list => $args{-path} );
    my @file_types = Cast_List( -to => 'array', -list => $args{-file_type} );

    my $num_paths      = scalar(@paths);
    my $num_file_types = scalar(@file_types);

    ###
    ### If all the files are of one type, then for convenience you can
    ### input the file_type only once, instead of having to input an array's
    ### worth of values
    ###

    if ( scalar($num_file_types) == 1 ) {
        @file_types = (@file_types) x scalar($num_paths);
    }

    if ( $num_paths > 0 ) {

        my @fields = qw/Analysis_File_Path Analysis_Type/;
        my @rows;

        my $iterator = List::MoreUtils::each_array( @paths, @file_types );
        while ( my ( $path, $file_type ) = $iterator->() ) {
            push @rows, [ $path, lc($file_type) ];
        }

        if ( scalar(@rows) > 0 ) {
            return $self->insert(
                -table  => 'Analysis_File',
                -values => [ [@fields], @rows ]
            );
        }
        else {
            return ();
        }
    }
}

##############################
sub insert_Analysis_Submission {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{'dbc'};

    my @run_analysis_ids           = Cast_List( -to => 'array', -list => $args{-run_analysis_id} );
    my @multiplex_run_analysis_ids = Cast_List( -to => 'array', -list => $args{-multiplex_run_analysis_id} );
    my @sample_ids                 = Cast_List( -to => 'array', -list => $args{-sample_id} );
    my @analysis_file_ids          = Cast_List( -to => 'array', -list => $args{-analysis_file_id} );
    my ($status_id) = $dbc->Table_find(
        -fields    => "Status_ID",
        -table     => "Status",
        -condition => "WHERE Status_Type = 'Submission' AND Status_Name = 'Requested'",
    );

    my $submission_volume_id = $self->get_pk_value();

    my @fields = qw/FK_Run_Analysis__ID FK_Multiplex_Run_Analysis__ID FK_Sample__ID FK_Analysis_File__ID FK_Submission_Volume__ID FK_Status__ID/;

    my @rows;

    my $iterator = List::MoreUtils::each_array( @run_analysis_ids, @multiplex_run_analysis_ids, @sample_ids, @analysis_file_ids );
    while ( my ( $run_analysis_id, $multiplex_run_analysis_id, $sample_id, $analysis_file_id ) = $iterator->() ) {
        push @rows, [ $run_analysis_id, $multiplex_run_analysis_id, $sample_id, $analysis_file_id, $submission_volume_id, $status_id ];
    }

    if ( scalar(@rows) > 0 ) {
        return $self->insert(
            -table  => 'Analysis_Submission',
            -values => [ [@fields], @rows ],
        );
    }
    else {
        return ();
    }
}

#######################
#######################
#######################
# These functions are more appropriate under DBIO or some other
# generic table extraction package. However, these will need to be here
# until a good place is found
#######################
#######################
#######################

#****************************
#*****************************
############################
# Get Submission_Volumes and associated data
# If fields are fully qualified, no need to specify tables in 'required_tables'
#
# Usage:	$SRA->get_Metadata_Submission_data(
#                      -fields => ['Submission_Volume.Volume_Name'],
#                      -status => ['incomplete'] );
#
# Return:	same format as Table_retrieve
############################
sub get_Submission_Volume_data {
##############################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc} || $self->{dbc};
    my $debug = $args{-debug};

    my $fields          = $args{-fields};
    my $required_tables = $args{-required_tables} || [];
    my $condition       = $args{-condition} || "WHERE 1";
    my $group_by        = $args{-group_by} || "Submission_Volume.Submission_Volume_ID";
    my $order           = $args{-order};
    my $limit           = $args{-limit};

    my $submission_volume_id = $args{-submission_volume_id};
    my $volume_name          = $args{-volume_name};
    my $status               = $args{-status} || [];

    if ($submission_volume_id) {
        push @$required_tables, "Submission_Volume";
        $condition .= " AND Submission_Volume.Submission_Volume_ID in (" . Cast_List( -to => 'string', -list => $submission_volume_id, -autoquote => 1 ) . ")";
    }
    if ($volume_name) {
        push @$required_tables, "Submission_Volume";
        $condition .= " AND Submission_Volume.Volume_Name in (" . Cast_List( -to => 'string', -list => $volume_name, -autoquote => 1 ) . ")";
    }

    if ( $args{-incomplete} ) {
        push @{$status}, ( 'Requested', 'Created', 'Bundled', 'Submitted', 'In Process', 'Waiting for Admin', 'Approved by Admin' );
    }
    elsif ( $args{-complete} ) {
        push @{$status}, ( 'Submitted', 'Aborted', 'Rejected', 'Accepted', 'Released' );
    }
    elsif ( $args{-approved} ) {
        push @{$status}, ( 'Accepted', 'Released' );
    }
    elsif ( $args{-rejected} ) {
        push @{$status}, ('Rejected');
    }

    if ( scalar(@$status) > 0 ) {

        push @$required_tables, "Status";
        $condition .= " AND Status.Status_Name in (" . Cast_List( -to => 'string', -list => $status, -autoquote => 1 ) . ")";
    }

    my %DB_JOIN = (
        "Submission_Volume"              => undef,
        "Status"                         => 'Submission_Volume.FK_Status__ID = Status.Status_ID',
        "Employee AS Submitter_Employee" => 'Submission_Volume.FKSubmitter_Employee__ID = Submitter_Employee.Employee_ID',
        "Employee AS Requester_Employee" => 'Submission_Volume.FKRequester_Employee__ID = Requester_Employee.Employee_ID',
        "Submission_Template"            => 'Submission_Volume.FK_Submission_Template__ID = Submission_Template.Submission_Template_ID',
        "Organization"                   => 'Submission_Volume.FK_Organization__ID = Organization.Organization_ID',
    );

    return $self->_get_DB_data( -fields => $fields, -required_tables => $required_tables, -condition => $condition, -group_by => $group_by, -order => $order, -limit => $limit, -db_join => \%DB_JOIN, -debug => $debug );
}

############################
# Helper function for all functions with the name "get_<table_name>_data"
#
# It does roughly the following:
# - Separates out actual table columns from attributes in "fields"
# - Extracts all table names from fully qualified items in "fields"
# - If -follow_plate_history is used, will group_concat plate attribute values over entire plate history
# - Automatically joins all relevant tables using the relationships defined in the hash $db_join
# - Retrieves data from DB using Table_retrieve
# - Rekeys the output data hash if applicable
############################
sub _get_DB_data {
##############################
    my $self                 = shift;
    my %args                 = &filter_input( \@_ );
    my $dbc                  = $args{-dbc} || $self->{dbc};
    my $id                   = $args{-id} || $self->{id};
    my $input_fields         = $args{-fields};
    my $required_tables      = $args{-required_tables};
    my $condition            = $args{-condition};
    my $group_by             = $args{-group_by};
    my $order                = $args{-order};
    my $limit                = $args{-limit};
    my $distinct             = $args{-distinct};
    my $key                  = $args{-key} || '';
    my $db_join              = $args{-db_join};
    my $follow_plate_history = $args{-follow_plate_history} || 0;
    my $debug                = $args{-debug};

    my @input_fields     = Cast_List( -to => 'array', -list => $input_fields );
    my @input_tables     = Cast_List( -to => 'array', -list => $required_tables );
    my @input_group_by   = Cast_List( -to => 'array', -list => $group_by );
    my @input_key_fields = Cast_List( -to => 'array', -list => $key ) if ($key);

    my $tables;
    my $table_statement;
    my $new_fields;

    my @key_aliases;
    my @key_fields_to_add;

    foreach my $input_key_field (@input_key_fields) {
        if ( $input_key_field =~ /^(.*?)\s+AS\s+(\w+)\s*$/i ) {
            push @key_fields_to_add, $1;
            push @key_aliases,       $2;
        }
        elsif ( $input_key_field =~ /^([[:alpha:]_]+)\.([[:alpha:]_]+)$/ ) {
            push @key_fields_to_add, $input_key_field;
            push @key_aliases,       $input_key_field;
        }
        else {
            push @key_aliases, $input_key_field;
        }
    }

    ###
    ### This is used if no fields are explicitly wanted, or the caller wants a
    ### "SELECT * FROM..." type query.
    ### In this case, all the fields from the "base table" are returned.

    if ( scalar(@input_fields) == 0 or ( scalar(@input_fields) == 1 and $input_fields[0] eq '*' ) ) {

        my ($base_table) = grep { !defined( $db_join->{$_} ) } keys %{$db_join};

        my @fields = $dbc->get_field_list( -table => $base_table );
        $new_fields = [ @fields, @key_fields_to_add, @input_group_by ];

        my $tables = (
            scalar(@input_tables) > 0
            ? [ $base_table, @input_tables ]
            : [$base_table]
        );

        $table_statement = $self->_auto_join( -tables => unique_items($tables), -db_join => $db_join );
    }
    else {
        my $fields = unique_items( [ @input_fields, @key_fields_to_add, @input_group_by ] );

        ### This can extract necessary tables from field names that are fully qualified
        ###
        ### I deliberately don't pass in $dbc as an argument because I don't want simple_resolve_field
        ### to guess the table name without an explicit table qualifier

        my ( $qualified_fields, $attributes ) = $self->_extract_qualified_fields( -expressions => $fields, -db_join => $db_join );

        my @tables_from_qualified_fields = map { my ( $t, $f ) = $dbc->simple_resolve_field( -field => $_ ); $t } ( @$qualified_fields, @$attributes );

        my $tables = (
            scalar(@input_tables) > 0
            ? [ @tables_from_qualified_fields, @input_tables ]
            : \@tables_from_qualified_fields
        );

        ### Extract any attributes contained within the %DB_JOIN conditions
        ###
        ### Example: Run_Plate.Library_Strategy in
        ### 'Library_Strategy' => 'Library_Strategy.Library_Strategy_ID = Run_Plate.Library_Strategy',

        my $jc_attributes = $self->_extract_attrs_from_join_conditions( -db_join => $db_join );
        $attributes = [ @{$attributes}, @{$jc_attributes} ];

        my $plate_history_table;

        # if ( $follow_plate_history ) {

        #     # $plate_history_table = $self->_create_plate_attr_history_table(
        #     #     -dbc                    => $dbc,
        #     #     -fields                 => $attributes,
        #     #     -required_tables        => $required_tables,
        #     #     -condition              => $condition,
        #     #     -group_by               => $group_by,
        #     #     -order                  => $order,
        #     #     -limit                  => $limit,
        #     #     -db_join                => $db_join,
        #     #     -debug                  => $debug
        #     # );

        #     # $self->_create_plate_attr_join_tables(
        #     #     -dbc                    => $dbc,
        #     #     -fields                 => $attributes,
        #     #     -required_tables        => $required_tables,
        #     #     -condition              => $condition,
        #     #     -group_by               => $group_by,
        #     #     -order                  => $order,
        #     #     -limit                  => $limit,
        #     #     -db_join                => $db_join,
        #     #     -ancestor_plate_attrs   => $ancestor_plate_attrs,
        #     #     -descendant_plate_attrs => $descendant_plate_attrs,
        #     #     -debug                  => $debug
        #     # );
        # }

        my ( $attr_tables, $new_attr_names );

        ( $attr_tables, $new_attr_names, $db_join ) = $self->_get_attribute_join_info(
            -db_join    => $db_join,
            -attributes => $attributes,
        );

        $tables = [ @$tables, @$attr_tables ];

        my %attr_mapping;
        @attr_mapping{@$attributes} = @$new_attr_names;

        ( $new_fields, $db_join ) = $self->_substitute_attribute_names(
            -expressions          => $fields,
            -mapping              => \%attr_mapping,
            -db_join              => $db_join,
            -follow_plate_history => $follow_plate_history,
        );

        #print HTML_Dump $db_join;

        $table_statement = $self->_auto_join(
            -tables  => unique_items($tables),
            -db_join => $db_join
        );

        s/^(\w+\.\w+)$/$1 AS '$1'/g for @$new_fields;

    }

    my %SQL_output = $dbc->Table_retrieve(
        -table     => $table_statement,
        -fields    => $new_fields,
        -condition => $condition,
        -group_by  => $group_by,
        -order     => $order,
        -limit     => $limit,
        -distinct  => $distinct,
        -debug     => $debug,
    );

    ###
    ### Strip quotes where the field alias was just a fully qualified
    ### DB field name (e.g. 'Library.Library_Name' => Library.Library_Name)
    ###

    my @new_keys = keys %SQL_output;
    s/^'(.*)'$/$1/ for @new_keys;
    @SQL_output{@new_keys} = delete @SQL_output{ keys %SQL_output };

    ### Rekeying hash

    my $DB_data = $self->_multiple_rekey_hash( -hash => \%SQL_output, -key => \@key_aliases );

    return $DB_data;

}

##############################
sub _multiple_rekey_hash {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $hash = $args{-hash};
    my $key  = $args{-key};

    my @key_fields = Cast_List( -to => 'array', -list => $key );
    my %hash_copy = %{$hash} if ( ref($hash) eq 'HASH' );
    my $DB_hash = \%hash_copy;

    if ( scalar(@key_fields) > 0 ) {

        $DB_hash = $dbc->rekey_hash( -hash => $DB_hash, -key => shift @key_fields );
        my @sorting_keys = map { [$_] } keys %$DB_hash;

        foreach my $k_field (@key_fields) {

            my @new_sorting_keys;
            foreach my $sorting_key (@sorting_keys) {

                my $temp_hash = $self->get_hash_value( -hash => $DB_hash, -key => $sorting_key );

                my $temp_rekeyed_hash = $dbc->rekey_hash( -hash => $temp_hash, -key => $k_field );

                push @new_sorting_keys, map { [ @{$sorting_key}, $_ ] } keys %$temp_rekeyed_hash;

                $self->set_hash_value( -hash => $DB_hash, -key => $sorting_key, -value => $temp_rekeyed_hash );
            }

            @sorting_keys = @new_sorting_keys;

        }
    }

    return $DB_hash;
}

############################
# Given a list of tables and a hash defining how
# tables should be joined with each other (SQL conditions),
# produces the JOIN portion of an SQL statement.
##############################
sub _auto_join {
##############################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $db_join = $args{-db_join};
    my $tables  = $args{-tables};

    my %join_condition;

    my %real_table;
    my $base_table;

    while ( my ( $join_table, $jc ) = each( %{$db_join} ) ) {
        if ( $join_table =~ /(\w+)\s+AS\s+(\w+)/i ) {
            my $alias = $2;

            $real_table{$alias}     = $join_table;
            $join_condition{$alias} = $jc;
        }
        else {
            $real_table{$join_table}     = $join_table;
            $join_condition{$join_table} = $jc;
        }

        ### Only used to find the "base" table, which is the only
        ### table with join condition = undef
        if ( !defined($jc) ) {
            $base_table = $join_table;
        }
    }

    my $join_table_order = [];
    my %already_joined = map { $_ => 0 } keys %join_condition;

    foreach my $table ( @{$tables} ) {

        my $alias;
        if ( $table =~ /(\w+)\s+AS\s+(\w+)/i ) {
            $alias = $2;
        }
        else {
            $alias = $table;
        }

        if ( !$already_joined{$alias} ) {
            $already_joined{$alias} = 1;

            my @dependent_tables = ($alias);
            while (@dependent_tables) {
                my $curr_table = shift @dependent_tables;
                $join_table_order = [ $curr_table, @{$join_table_order} ];
                my $jc = $join_condition{$curr_table};

                if ( defined($jc) ) {
                    while ( $jc =~ /(\w+)\.(\w+)\s*=\s*(\w+)\.(\w+)/g ) {
                        my $first_table  = $1;
                        my $second_table = $3;

                        if ( $first_table eq $curr_table ) {
                            push @dependent_tables, $second_table;
                        }
                        elsif ( $second_table eq $curr_table ) {
                            push @dependent_tables, $first_table;
                        }
                    }
                }

                elsif ( $curr_table ne $base_table ) {
                    Message("Warning: Can't find join condition for $curr_table");
                }

                ### The last item to be prepended to $join_table_order should
                ### always be the root table (i.e. the one with join_condition = undef)
            }
        }

    }

    $join_table_order = unique_items($join_table_order);

    my $root_table          = shift( @{$join_table_order} );
    my $SQL_table_statement = $real_table{$root_table};

    foreach my $alias ( @{$join_table_order} ) {
        $SQL_table_statement .= " LEFT JOIN $real_table{$alias} ON $join_condition{$alias}";
    }

    return $SQL_table_statement;

}
############################
# If any attributes need to be retrieved in "fields" or are referenced in "condition",
# then this function will determine the appropriate items to add
# to your SQL call
#
# Input: Attributes (ex. ['Plate.Amount_DNA_ng'])
#
# Output:
#
# @tables_to_join = ('Plate_Attribute AS Plate_Amount_DNA_ng'),
# @new_fields = ('Plate_Amount_DNA_ng.Attribute_Value'),
# %db_join = ( ... <previous db_join values> ...,
#              'Plate_Attribute AS Plate_Amount_DNA_ng' => 'Plate_Amount_DNA_ng.FK_Plate__ID = Plate.Plate_ID and Plate_Amount_DNA_ng.FK_Attribute__ID = 120'
#             )
##############################
sub _get_attribute_join_info {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $aliased_attributes = $args{-attributes};
    my $db_join            = $args{-db_join};

    my %real_table;

    foreach my $join_table ( keys %{$db_join} ) {
        if ( $join_table =~ /(\w+)\s+AS\s+(\w+)/i ) {
            my $alias = $2;
            $real_table{$alias} = $1;
        }
        else {
            $real_table{$join_table} = $join_table;
        }
    }

    my $aliased_attributes = unique_items($aliased_attributes);

    my @true_attributes;

    foreach my $aliased_attr (@$aliased_attributes) {
        my ( $t, $f ) = $dbc->simple_resolve_field( -field => $aliased_attr );
        push @true_attributes, $real_table{$t} . "." . $f;
    }

    my $true_attribute_str = Cast_List( -list => \@true_attributes, -to => 'string', -autoquote => 1 ) || "''";

    my %db_output
        = $dbc->Table_retrieve( -table => "Attribute", -fields => [ "Attribute_ID", "concat(Attribute_Class,'.',Attribute_Name) as Name", "Attribute_Type" ], -condition => "WHERE concat(Attribute_Class,'.',Attribute_Name) in ($true_attribute_str)" );

    my ( %attr_id, %attr_type );

    if (%db_output) {
        @attr_id{ @{ $db_output{Name} } }             = @{ $db_output{Attribute_ID} };
        @attr_type{ @{ $db_output{Attribute_Type} } } = @{ $db_output{Attribute_ID} };
    }

    my @new_fields;
    my @tables_to_join;

    foreach my $aliased_attr (@$aliased_attributes) {
        my ( $table_alias, $attr_name ) = $dbc->simple_resolve_field( -field => $aliased_attr );
        my $real_table = $real_table{$table_alias};

        my $attr_id = $attr_id{"$real_table.$attr_name"};

        if ($attr_id) {

            my ($primary_key_name) = $dbc->get_field_info( $real_table, undef, 'Primary' );

            my $attr_table_alias;
            my $attr_table;
            my $foreign_key_name;

            $attr_table = $real_table . "_Attribute";
            ($foreign_key_name) = $dbc->_get_FK_name( -fk_table => $attr_table, -table => $real_table, -field => $primary_key_name );

            $attr_table_alias = $table_alias . "_Attribute_" . $attr_name;

            $db_join->{"$attr_table AS $attr_table_alias"} = "$attr_table_alias.FK_Attribute__ID = $attr_id AND $attr_table_alias.$foreign_key_name = $table_alias.$primary_key_name";

            push @new_fields,     "$attr_table_alias.Attribute_Value";
            push @tables_to_join, $attr_table_alias;

        }
    }

    return ( \@tables_to_join, \@new_fields, $db_join );
}

# ##############################
# sub _create_plate_attr_history_table {
# ##############################
#     my $self                   = shift;
#     my %args                   = &filter_input( \@_ );
#     my $dbc                    = $args{-dbc} || $self->{dbc};
#     my $fields                 = $args{-fields};
#     my $required_tables        = $args{-required_tables};
#     my $condition              = $args{-condition};
#     my $group_by               = $args{-group_by};
#     my $order                  = $args{-order};
#     my $limit                  = $args{-limit};
#     my $distinct               = $args{-distinct};
#     my $key                    = $args{-key} || '';
#     my $db_join                = $args{-db_join};

#     my $debug = $args{-debug};

#     my $table_name;

#     if ( grep { /^Library/ } keys %{$db_join} ) {

#         ### Getting all valid libraries for the DB request we want

#         my $tables = ( ref($required_tables) eq 'ARRAY' ? [ "Library", @$required_tables ] : "Library" );
#         my $table_statement = $self->_auto_join(
#                 -tables  => unique_items($tables),
#                 -db_join => $db_join
#         );

#         my %valid_libs = $dbc->Table_retrieve(
#                 -table     => $table_statement,
#                 -fields    => ['Library.Library_Name'],
#                 -condition => $condition,
#                 -group_by  => $group_by,
#                 -order     => $order,
#                 -limit     => $limit,
#                 -debug => 1
#         );

#         my $quoted_lib_str = Cast_List( -to => 'string', -list => $valid_libs{'Library_Name'}, -autoquote => 1 );

#         my $attr_table_alias  = "Plate_Attribute_History";
#         my $attr_table_fields = "FK_Library__Name, FK_Attribute__ID, group_concat( distinct (Attribute_Value) ) as Attribute_Value";
#         my $attr_table_tables = "Plate_Attribute JOIN Plate on Plate_Attribute.FK_Plate__ID = Plate_ID";

#         my $attr_table_group_by  = "FK_Library__Name,FK_Attribute__ID";

#         my $attr_table_condition = "WHERE Plate.FK_Library__Name in ($quoted_lib_str)";

#         my $query = "CREATE TEMPORARY TABLE $attr_table_alias SELECT $attr_table_fields from $attr_table_tables $attr_table_condition GROUP BY $attr_table_group_by";

#         $debug = 1;

#         Message("Creating temp table: $query") if ($debug);

#         my $dbh        = $dbc->{dbh};
#         my $rows_added = $dbh->do($query);

#         if ($rows_added) {
#             Message("Added TEMPORARY TABLE $attr_table_alias");
#             $table_name = $attr_table_alias;
#         }
#         else {
#             Message( $dbh->errstr);
#         }
#     }
#     else {
#         Message('No way to retreive libraries from query, aborting plate history');
#     }

#     return $table_name;
# }

# ############################
# # Creates a Plate_Attribute table whose Attribute_Values (for a given Plate_ID)
# # are gathered from itself and its ancestor plates.
# ##############################
# ### Schema of temporary plate attribute table created:
# ###
# ### | FK_Plate__ID | Attribute_Value  | FK_Attribute__ID |
# ### +--------------+------------------+------------------+
# ### |       641371 |              7.5 |                2 |
# ### |       641371 |               15 |               81 |
# ##############################
# sub _create_plate_attr_join_tables {
# ##############################
#     #     my $self    = shift;
#     #     my %args    = &filter_input( \@_ );
#     #     my $dbc     = $args{-dbc} || $self->{dbc};
#     #
#     #     my $plate_ids = $args{-plate_ids} || [];
#     #     my $debug = $args{-debug};

#     my $self                   = shift;
#     my %args                   = &filter_input( \@_ );
#     my $dbc                    = $args{-dbc} || $self->{dbc};
#     my $fields                 = $args{-fields};
#     my $required_tables        = $args{-required_tables};
#     my $condition              = $args{-condition};
#     my $group_by               = $args{-group_by};
#     my $order                  = $args{-order};
#     my $limit                  = $args{-limit};
#     my $distinct               = $args{-distinct};
#     my $key                    = $args{-key} || '';
#     my $ancestor_plate_attrs   = $args{-ancestor_plate_attrs} || 1;
#     my $descendant_plate_attrs = $args{-descendant_plate_attrs} || 1;
#     my $ancestor_generations   = $args{-ancestor_generations} || 1;
#     my $descendant_generations = $args{-descendant_generations} || 4;
#     my $db_join                = $args{-db_join};

#     my $debug = $args{-debug};

#     ###
#     ### This block is to find all Plate fields that can be extracted from this db_join mapping
#     ###

#     my ($DB_plate_pk_name) = $dbc->get_field_info( 'Plate', undef, 'Primary' );

#     my @plate_primary_keys;
#     my @plate_tables;
#     foreach my $join_table ( keys %{$db_join} ) {
#         if ( $join_table =~ /^Plate\s*(AS\s+(\w+))?$/i ) {
#             if ($2) {
#                 push @plate_primary_keys, "$2.$DB_plate_pk_name";
#                 push @plate_tables,       $2;
#             }
#             else {
#                 push @plate_primary_keys, "Plate.$DB_plate_pk_name";
#                 push @plate_tables,       'Plate';
#             }
#         }
#     }

#     if ( scalar(@plate_primary_keys) > 0 ) {
#         ###
#         ### This block extracts all possible Plate_IDs associated with this particular query
#         ###
#         my $tables = ( ref($required_tables) eq 'ARRAY' ? [ @plate_tables, @$required_tables ] : \@plate_tables );
#         my $table_statement = $self->_auto_join(
#             -tables  => unique_items($tables),
#             -db_join => $db_join
#         );

#         my @fields = map {"$_ AS '$_'"} @plate_primary_keys;

#         my %valid_plates_of_pk = $dbc->Table_retrieve(
#             -table     => $table_statement,
#             -fields    => \@fields,
#             -condition => $condition,
#             -group_by  => $group_by,
#             -order     => $order,
#             -limit     => $limit,
#         );

#         ### Stripping the quotes around the column names

#         my @keys = keys %valid_plates_of_pk;

#         foreach my $key (@keys) {
#             my $old_key = $key;
#             $key =~ s/^'(.*)'$/$1/;

#             my $plate_list = delete $valid_plates_of_pk{$old_key};

#             if ($key =~ /Plate\.(\w+)/) {
#                 $valid_plates_of_pk{$key} = $plate_list
#             }
#         }

#         my @plate_ids;
#         foreach my $plate_pk (@plate_primary_keys) {
#             push @plate_ids, @{ $valid_plates_of_pk{$plate_pk} };
#         }

#         ### SECTION:
#         ### Generation SQL conditions

#         my @conditions;

#         my %SQL_condition_of_pk;
#         my %SQL_condition_of_plate;

#         my %ancestor_plates_of;
#         my %descendant_plates_of;

#         while (my ($pk, $valid_plates_ref) = each(%valid_plates_of_pk) ) {

#             Message("Getting ancestry of $pk");

#             ### There are some plate primary keys that may return undef for certain
#             ### libraries (e.g. ReArray_Source_Plate.Plate_ID)
#             ###
#             ### Be sure to remove the undefs before calculating plate histories

#             my @valid_plates = grep defined, @{ $valid_plates_ref };
#             my @unique_valid_plates = List::MoreUtils::uniq(@valid_plates) ;

#             my @SQL_conditions;

#             foreach my $plate_id ( @unique_valid_plates ) {

#                 ### To ensure we don't redo a plate history; this is a very expensive operation

#                 if ( !exists( $SQL_condition_of_plate{$plate_id} )) {

#                     ### CONSTRUCTION:
#                     ###
#                     ### This condition needs to be improved: I need to be able to flag whether a table should search the whole
#                     ### plate history or just some of it

#                     if ( ! exists($descendant_plates_of{$plate_id}) and $pk ne 'ReArray_Source_Plate.Plate_ID' ) {
#                         $descendant_plates_of{$plate_id} = [];

#                         if ($descendant_plate_attrs) {
#                             my %descendancy = alDente::Container::get_Children( -dbc => $dbc, -plate_id => $plate_id, -generations => $descendant_generations);
#                             $descendant_plates_of{$plate_id} = $descendancy{list} if $descendancy{child_generations};
#                         }
#                     }

#                     my @descendant_plates = Cast_List(-to => 'array', -list => $descendant_plates_of{$plate_id} );

#                     if ( ! exists( $ancestor_plates_of{$plate_id}) ) {
#                         $ancestor_plates_of{$plate_id} = [];

#                         if ($ancestor_plate_attrs) {
#                             my %ancestry = alDente::Container::get_Parents( -dbc => $dbc, -plate_id => $plate_id, -simple => 1, -generations => $ancestor_generations );
#                             $ancestor_plates_of{$plate_id} = $ancestry{list} if $ancestry{parent_generations};
#                         }
#                     }

#                     my @ancestor_plates = Cast_List(-to => 'array', -list => $ancestor_plates_of{$plate_id} );

#                     my $plate_str = Cast_List( -to => 'string', -list => [ @descendant_plates, @ancestor_plates, $plate_id ] ) || "''";

#                     $SQL_condition_of_plate{$plate_id} = "(FK_Plate__ID in ($plate_str) and Plate_ID = $plate_id)";
#                 }
#             }

#             $SQL_condition_of_pk{$pk} = join( ' OR ', @SQL_condition_of_plate{@unique_valid_plates} );

#         }

#         ### Section:
#         ### Finding attribute ID's of the inputted plate attributes

#         my @plate_input_attrs;
#         my @plate_input_fields;

#         foreach my $field ( @{$fields} ) {
#             my ( $t, $f ) = $dbc->simple_resolve_field( -field => $field );

#             if ( grep {/^$t$/} @plate_tables ) {
#                 push @plate_input_attrs, $f;
#                 push @plate_input_fields, $field;
#             }
#         }

#         my %DB_output = $dbc->Table_retrieve(
#             -table     => "Attribute",
#             -fields    => [ "Attribute_Name", "Attribute_ID" ],
#             -condition => "WHERE Attribute_Class = 'Plate' AND Attribute_Name in (" . Cast_List( -list => \@plate_input_attrs, -to => 'string', -autoquote => 1 ) . ")"
#         );

#         my @attr_names = @{ $DB_output{Attribute_Name} };
#         my @attr_ids   = @{ $DB_output{Attribute_ID} };

#         my %attr_id_of;
#         @attr_id_of{@attr_names} = @attr_ids;

#         foreach my $plate_input_field (@plate_input_fields) {

#             my ( $table_alias, $attr_name ) = $dbc->simple_resolve_field( -field => $plate_input_field );

#             my $attribute_id = @attr_id_of{$attr_name};

#             my $attr_table_alias = $table_alias . "_" . $attr_name;

#             my $attr_table_fields    = "Plate_ID as FK_Plate__ID,group_concat(distinct(Attribute_Value)) as Attribute_Value, FK_Attribute__ID";
#             my $attr_table_tables    = "Plate, Plate_Attribute";
#             my $attr_table_condition;
#             my $attr_table_group_by  = "Plate_ID,FK_Attribute__ID";

#             if ( $SQL_condition_of_pk{"$table_alias.$DB_plate_pk_name"} ) {
#                 $attr_table_condition = "WHERE " . $SQL_condition_of_pk{"$table_alias.$DB_plate_pk_name"} . " AND FK_Attribute__ID = $attribute_id";
#             }
#             else {
#                 ### If the plate table to which the attribute belongs has no valid plate ID's for the parent query,
#                 ### force creation of a blank temporary table
#                 $attr_table_condition = "WHERE FALSE";
#             }

#             my $query = "CREATE TEMPORARY TABLE $attr_table_alias SELECT $attr_table_fields from $attr_table_tables $attr_table_condition GROUP BY $attr_table_group_by";

#             Message("Creating temp table: $query") if ($debug);

#             my $dbh        = $dbc->{dbh};
#             my $rows_added = $dbh->do($query);

#             if ($rows_added) {
#                 Message("Added TEMPORARY TABLE $attr_table_alias");
#             }
#             else { Message( $dbh->errstr); }
#         }

#     }
# }

############################
# Given a list of SQL fields, extracts the table names from fields
# that are fully qualified
##############################
sub _extract_qualified_fields {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $expressions = $args{-expressions} || [];
    my $db_join = $args{-db_join};

    my %real_table;

    foreach my $join_table ( keys %{$db_join} ) {
        if ( $join_table =~ /(\w+)\s+AS\s+(\w+)/i ) {
            my $alias = $2;
            $real_table{$alias} = $1;
        }
        else {
            $real_table{$join_table} = $join_table;
        }
    }

    my %aliased_field;

    foreach my $expression (@$expressions) {

        my $expr_remaining = $expression;

        while ( $expr_remaining =~ /'[^']*'/ ) {
            my $substring_to_search = $`;
            my $quoted_str          = $&;
            $expr_remaining = $';

            while ( $substring_to_search =~ /\b([[:alpha:]_]+)\.([[:alpha:]_]+)\b/g ) {
                my $true_field = $real_table{$1} . "." . $2;

                if ( !exists( $aliased_field{$true_field} ) ) { $aliased_field{$true_field} = [] }

                push @{ $aliased_field{$true_field} }, "$1.$2";
            }

        }

        while ( $expr_remaining =~ /\b([[:alpha:]_]+)\.([[:alpha:]_]+)\b/g ) {
            my $true_field = $real_table{$1} . "." . $2;

            if ( !exists( $aliased_field{$true_field} ) ) { $aliased_field{$true_field} = [] }

            push @{ $aliased_field{$true_field} }, "$1.$2";
        }
    }

    my @true_fields = keys %aliased_field;

    my @db_attrs = $dbc->Table_find_array(
        -table     => "Attribute",
        -fields    => ["concat(Attribute_Class,'.',Attribute_Name)"],
        -condition => "WHERE concat(Attribute_Class,'.',Attribute_Name) in (" . Cast_List( -list => \@true_fields, -to => 'string', -autoquote => 1 ) . ")"
    );

    my @attributes;
    foreach my $db_attr (@db_attrs) {
        my $aliased_attrs = delete $aliased_field{$db_attr};

        push @attributes, @$aliased_attrs;
    }

    my @fields;

    foreach my $aliased_fields ( values %aliased_field ) {
        push @fields, @$aliased_fields;
    }

    return ( unique_items( \@fields ), unique_items( \@attributes ) );
}

##############################
# Extract any attributes contained within the %DB_JOIN conditions
#
# Example: Run_Plate.Library_Strategy in
# 'Library_Strategy' => 'Library_Strategy.Library_Strategy_ID = Run_Plate.Library_Strategy',
##############################
sub _extract_attrs_from_join_conditions {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $db_join = $args{-db_join};

    my %real_table;
    foreach my $join_table ( keys %{$db_join} ) {
        if ( $join_table =~ /(\w+)\s+AS\s+(\w+)/i ) {
            my $alias = $2;
            $real_table{$alias} = $1;
        }
        else {
            $real_table{$join_table} = $join_table;
        }
    }

    my %aliased_field;
    my @candidate_attrs;

    while ( my ( $table, $jc ) = each( %{$db_join} ) ) {

        while ( $jc =~ /\b(\w+)\.(\w+)\b/g ) {
            my $true_field = $real_table{$1} . "." . $2;
            if ( !exists( $aliased_field{$true_field} ) ) { $aliased_field{$true_field} = [] }
            push @{ $aliased_field{$true_field} }, "$1.$2";

            push @candidate_attrs, $true_field;
        }
    }

    my @db_attrs = $dbc->Table_find_array(
        -table     => "Attribute",
        -fields    => ["concat(Attribute_Class,'.',Attribute_Name)"],
        -condition => "WHERE concat(Attribute_Class,'.',Attribute_Name) in (" . Cast_List( -list => \@candidate_attrs, -to => 'string', -autoquote => 1 ) . ")",
    );

    my @aliased_attrs;

    foreach my $db_attr (@db_attrs) {
        push @aliased_attrs, @{ $aliased_field{$db_attr} };
    }

    return \@aliased_attrs;

}

############################
# Substitutes all instances of attributes inputted like this:
# - Plate.Amount_DNA_ng
#
# to the real field that needs to be used for the SQL call:
# - Plate_Attribute_Amount_DNA_ng.Attribute_Value
#
#
#
# If Plate_History is used and 'follow_plate_history' is set,
# a group_concat(distinct(..)) is added:
# - Plate_History.Amount_DNA_ng ->
# - group_concat(distinct(Plate_Attribute_Amount_DNA_ng.Attribute_Value))
#
#
##############################
sub _substitute_attribute_names {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $expressions = $args{-expressions} || [];
    my $mapping     = $args{-mapping}     || {};
    my $db_join     = $args{-db_join};
    my $follow_plate_history = $args{-follow_plate_history};

    my @new_expressions;

    foreach my $expression (@$expressions) {

        my $new_expression;
        my $contains_plate_history = 0;

        if ( $expression =~ /^(\w+\.\w+)$/ ) {
            if ( $mapping->{$expression} ) {
                $new_expression = "$mapping->{$expression} AS '$expression'";
            }
            else {
                $new_expression = $expression;
            }

            if ( $expression =~ /^Plate_History/ ) {
                $contains_plate_history = 1;
            }
        }

        else {
            my @quoted_strings;
            my $format_string;

            while ( $expression =~ /'[^']*'/ ) {
                my $prematch   = $`;
                my $quoted_str = $&;
                $expression = $';

                $format_string .= $prematch . "\%s";

                push @quoted_strings, $quoted_str;
            }

            $format_string .= $expression;

            if ( $format_string =~ /Plate_History/ ) {
                $contains_plate_history = 1;
            }

            while ( my ( $old, $new ) = each(%$mapping) ) {
                $format_string =~ s/\b$old\b/$new/g;
            }

            $new_expression = sprintf( $format_string, @quoted_strings );
        }

        if ( $follow_plate_history and $contains_plate_history ) {

            my ( $actual_field, $alias );

            if ( $new_expression =~ /^(.*)\s+AS\s+(.*)$/i ) {
                $actual_field = $1;
                $alias        = $2;
            }
            else {
                $actual_field = $new_expression;
            }

            $new_expression = "group_concat( distinct( $actual_field ))";
            $new_expression .= " AS $alias" if $alias;
        }

        push @new_expressions, $new_expression;
    }

    while ( my ( $table, $jc ) = each( %{$db_join} ) ) {
        while ( $jc =~ /\b\w+\.\w+\b/g ) {
            my $field        = $&;
            my $field_to_sub = $mapping->{$field};

            if ($field_to_sub) {
                $db_join->{$table} =~ s/\b$field\b/$field_to_sub/;
            }
        }
    }

    return ( \@new_expressions, $db_join );
}

##############################
# Traverses a hash of arbitrary depth given a string of keys and retrieves
# the corresponding value
#
# Input:
#
# -hash: A hash of arbitrary depth
# -key: Hash keys separated by periods.
#
# Example: using key1.key2[1].key3 in this function is equivalent to
# $hash->{key1}->{key2}->[1]->{key3}
#
# Usage: my $value = get_hash_value(-hash => $hash, -key => $key);
#
# Returns: The value associated with the key, otherwise undef.
#################################
sub get_hash_value {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $hash  = $args{-hash};
    my $key   = $args{-key};
    my $debug = $args{-debug};

    #my @keys = split /\./, $key_str;
    my @keys = Cast_List( -to => 'array', -list => $key );

    foreach my $key (@keys) {

        if ( $key =~ /(\w+)\[(\d+)\]/ ) {
            $hash = $hash->{$1}->[$2];
        }

        elsif ( !$hash->{$key} ) {
            Message join( '.', @keys ) . " is not a valid key\n";
            return undef;
        }
        else {
            Message "get_hash_value debug (key: $key, value: $hash->{$key}" if ($debug);
            $hash = $hash->{$key};
        }
    }
    return $hash;
}

##############################
# Traverses a hash of arbitrary depth given a string of keys and overwrites
# the existing value with the input value
#
# Input:
#
# -hash: A hash of arbitrary depth
# -key: Hash keys separated by periods (key1.key2[1].key3....)
# -value: Value to overwrite in hash
#
# Usage: my $success = set_hash_value(-hash => $hash, -key => $key, -value => $value);
#
# Return: 1 if the key is valid and the value is set, otherwise 0.
#################################
sub set_hash_value {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $hash  = $args{-hash};
    my $key   = $args{-key};
    my $value = $args{-value};

    my @keys = Cast_List( -to => 'array', -list => $key );

    #my @keys = split /\./, $key_str;

    ## To set value, you need to stop one key
    ## before the actual value

    my ( $key, $array_index );

    foreach my $i ( 0 .. $#keys - 1 ) {
        $key = $keys[$i];

        if ( $key =~ /(\w+)\[(\d+)\]/ ) {
            $key         = $1;
            $array_index = $2;

            if ( defined( $hash->{$key} ) ) {
                if ( ref( $hash->{$key} ) eq 'ARRAY' ) {
                    $hash = $hash->{$key}->[$array_index];
                }
                else {
                    Message "Invalid key, $key not array reference";
                    return 0;
                }
            }

            else {
                $hash->{$key}->[$array_index] = {};
                $hash = $hash->{$key}->[$array_index];
            }

        }

        else {

            if ( defined( $hash->{$key} ) ) {

                if ( ref( $hash->{$key} ) eq 'HASH' ) {
                    $hash = $hash->{$key};
                }
                else {
                    Message "Invalid key, $key not a hash";
                    return 0;
                }
            }

            else {
                $hash->{$key} = {};
                $hash = $hash->{$key};
            }
        }
    }

    $key = $keys[-1];
    if ( $key =~ /(\w+)\[(\d+)\]/ and ref( $hash->{$1} ) eq 'ARRAY' ) {
        $hash->{$1}->[$2] = $value;
    }
    elsif ($key) {
        $hash->{$key} = $value;
    }
    elsif ( ref($hash) eq 'HASH' ) {
        %{$hash} = %{$value};
    }
    else {
        $hash = {};
    }

    return 1;
}

#################################
sub _get_primary_key_value {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my $table = $args{-table};
    my $field = $args{-field};
    my $value = $args{-value};

    if ( $field =~ /\b(\w+)\.(\w+)\b/ ) {
        $table = $1;
        $field = $2;
    }

    my $value_str = Cast_List( -to => 'string', -list => $value, -autoquote => 1 );

    my @pk_fields = $dbc->get_field_info( $table, undef, 'Primary' );

    my $condition = "WHERE $field in ($value_str)";

    my @results = $dbc->Table_find_array(
        -table     => $table,
        -fields    => \@pk_fields,
        -condition => $condition
    );
    return wantarray ? @results : $results[0];
}

###
###
### Legacy code starts here
###
###
###
###

####################################
# Create Trace_Submission records
#
# Usage:	my $count = $volume_obj->create_run_submission( -volume_id => $id, -run_ids => \@run_ids );
#
# Return:	Scalar, the number of records created
#####################################
sub new_trace_submission {
#####################################
    my $self   = shift;
    my %args   = &filter_input( \@_, -args => 'fields,values', -mandatory => 'fields,values' );
    my $dbc    = $self->{dbc};
    my $fields = $args{-fields};
    my $values = $args{ -values };

    return if ( !$fields || !$values );
    my $new_id = $dbc->Table_append_array(
        -dbc       => $dbc,
        -table     => 'Trace_Submission',
        -fields    => $fields,
        -values    => $values,
        -autoquote => 1,
    );
    return $new_id;

}

sub create_study_entries {

    my $self           = shift;
    my %args           = &filter_input( \@_, -args => 'request_params,name,template,libraries,runs', -mandatory => 'request_params' );
    my $dbc            = $self->{dbc};
    my $request_params = $args{-request_params};
    my $name           = $args{-name};
    my $template       = $args{-template};
    my $lib_string     = $args{-libraries};

    my @libraries = Cast_List( -list => $lib_string, -to => 'array', -autoquote => 0 );

    my @study_fields = ( 'Study_Name', 'Study_Description', 'Study_Initiated' );
    my @lib_study_fields = ( 'FK_Library__Name', 'FK_Study__ID' );

    foreach my $lib (@libraries) {
        my ($external_id) = $dbc->Table_find( 'Library,Library_Source,Source', 'External_Identifier', "WHERE FK_Library__Name = Library_Name AND FK_Source__ID = Source_ID and Library_Name = '$lib'" );

        my @study_values = ( "SRA submission library $lib", $external_id, today() );

        my $study_id = $dbc->Table_append_array(
            -dbc       => $dbc,
            -table     => 'Study',
            -fields    => \@study_fields,
            -values    => \@study_values,
            -autoquote => 1,
        );

        my @lib_study_values = ( $lib, $study_id );

        my $lib_study_id = $dbc->Table_append_array(
            -dbc       => $dbc,
            -table     => 'LibraryStudy',
            -fields    => \@lib_study_fields,
            -values    => \@lib_study_values,
            -autoquote => 1,
        );
    }
}

sub load_submission_config {
    my $self   = shift;
    my %args   = &filter_input( \@_, -args => 'config', -mandatory => 'config' );
    my $config = $args{-config};

    my $config_href = $self->load_config( -config => $args{-config} );
    if ( $config_href->{success} ) {
        $self->{'schema'}          = $config_href->{schema};
        $self->{'template'}        = $config_href->{template};
        $self->{'field'}           = $config_href->{field};
        $self->{'required_field'}  = $config_href->{required_field};
        $self->{'use_NA_if_null'}  = $config_href->{use_NA_if_null};
        $self->{'TAG'}             = $config_href->{TAG};
        $self->{'alia'}            = $config_href->{Alia};
        $self->{'static_data'}     = $config_href->{static_data};
        $self->{'format'}          = $config_href->{format};
        $self->{'custom'}          = $config_href->{custom};
        $self->{'success'}         = $config_href->{success};
        $self->{'template_header'} = $config_href->{template_header};
        $self->{'user_input'}      = $config_href->{user_input};
        $self->{'function_input'}  = $config_href->{function_input};
        return 1;
    }
    else {
        return 0;
    }
}

##########################################################
# This method is to load settings from the config file, including the template file name,
# fields, required fields, alias, TAG and custom data, and static data. It also scan all the template files
# to report any alias that are not defined in the config file.
#
# input:
#       -config => the config file name
#
# output:
#		Hash reference to the config data.
#
# example:
#		my $config_href = $data_submission->load_config( -config=>$file );
#
# note: config file is in YAML format.
#		See /home/aldente/private/views/Group/vector/vectorology.yml for an example of the YAML file.
#     	The following is the configuration data structure that is exported to the YAML file:
#    	$template;
#    	@field = ('Original_Source.Description','Library.Library_Name');
#		@required_field = ('Original_Source.Description','Library.Library_Name');
#		%TAG = (
#			'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG' => ['MOLECULE','DISEASE']
#		);
#		%Alia = (
#			'SAMPLE_SET.SAMPLE.DESCRIPTION' => 'Original_Source.Description',
#			'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.MOLECULE' => 'RNA_DNA_Source.Nature',
#		);
#		%custom_config = (
#			'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE' => {
#				'Cell Line'	=>	'cell_line_template.yml',
#				'Primary Cell' => 'primary_cell_template.yml',
#			}
#		);
#    	%static_data = (
#    		'SAMPLE_SET.xmlns:xsi' => ['http://www.w3.org/2001/XMLSchema-instance'],
#    		'SAMPLE_SET.xsi:noNamespaceSchemaLocation' => ['http://www.ncbi.nlm.nih.gov/Traces/sra/static/SRA.sample.xsd'],
#    	);
#    	%format = (
#    		'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.SEX' => 'Male|Female',
#    	)
############################
sub load_config {
    my $self   = shift;
    my %args   = &filter_input( \@_, -args => 'config', -mandatory => 'config' );
    my $config = $args{-config};

    my %result;

    if ( !-e $config ) {
        $result{success} = 0;
        return;
    }

    my $config_href = YAML::LoadFile($config);
    $result{schema}         = $config_href->{schema};
    $result{template}       = $config_href->{template};
    $result{field}          = $config_href->{field};
    $result{required_field} = $config_href->{required_field};
    $result{use_NA_if_null} = $config_href->{use_NA_if_null};
    $result{TAG}            = $config_href->{TAG};
    $result{Alia}           = $config_href->{Alia};
    $result{static_data}    = $config_href->{static_data};
    $result{format}         = $config_href->{format};
    my $custom_config = $config_href->{custom_config};
    $result{success}         = 1;
    $result{template_header} = $config_href->{template_header};
    $result{user_input}      = $config_href->{user_input};
    $result{function_input}  = $config_href->{function_input};

    ## check if alias that exist in the templates are defined in the config file
    if ( $config_href->{template} ) {
        my ( $element_arrref, $value_arrref ) = $self->get_element_value( -file => $config_href->{template}, -ignore_TAG => 1 );
        my @errors;
        foreach my $name (@$element_arrref) {
            if ( !exists $result{Alia}{$name} ) {
                push @errors, $name;
            }
        }
        my $error_num = @errors;
        if ($error_num) {
            Message( "ERROR: $error_num names in template $config_href->{template} are not defined in the config Alias:\n" . join( "\n", @errors ) . "\nPlease define these alias!\n" );
        }
        $result{success} = $error_num ? 0 : 1;
    }

    ## recursively load in the custom config files and merge with the current config data
    foreach my $key1 ( keys %$custom_config ) {
        foreach my $key2 ( keys %{ $custom_config->{$key1} } ) {
            my $custom_config_file = $custom_config->{$key1}{$key2};
            if ( -e $custom_config_file ) {
                my $hash_ref = $self->load_config( -config => $custom_config_file );
                if ($hash_ref) {
                    $result{success} = $result{success} && $hash_ref->{success};

# merge fields and remove duplicates
#$result{field} = &RGmath::union( $result{field}, $hash_ref->{field} ); # the result of RGmath::union() has duplicate fields if the input have multiple fields of something like "CASE WHEN lower(substring(Biomaterial_Type,1,15)) ='primary culture' THEN 'Primary Cell Culture' WHEN lower(substring(Biomaterial_Type,1,12)) ='primary cell' THEN 'Primary Cell' WHEN lower(substring(Biomaterial_Type,1,9) ) = 'cell line' THEN 'Cell Line' WHEN lower(substring(Biomaterial_Type,1,14) ) = 'primary tissue' THEN 'Primary Tissue' ELSE 'other' END AS SAMPLE_ATTRIBUTE_BIOMATERIAL_TYPE"
                    foreach my $field ( @{ $hash_ref->{field} } ) {
                        my $add = 1;
                        foreach my $ufield ( @{ $result{field} } ) {
                            if ( $field eq $ufield ) {
                                $add = 0;
                            }
                        }
                        push @{ $result{field} }, $field if ($add);
                    }

                    $result{use_NA_if_null} = &RGmath::union( $result{use_NA_if_null}, $hash_ref->{use_NA_if_null} );

                    #$result{required_field} =  &RGmath::union( $result{required_field}, $hash_ref->{required_field} );
                    $result{Alia} = &RGmath::merge_Hash(
                        -hash1 => $result{Alia},
                        -hash2 => $hash_ref->{Alia}
                    );
                    $result{static_data} = &RGmath::merge_Hash(
                        -hash1 => $result{static_data},
                        -hash2 => $hash_ref->{static_data}
                    );
                    $result{format} = &RGmath::merge_Hash(
                        -hash1 => $result{format},
                        -hash2 => $hash_ref->{format}
                    );
                    $result{custom}{$key1}{$key2}{TAG}            = $hash_ref->{TAG};
                    $result{custom}{$key1}{$key2}{template}       = $hash_ref->{template};
                    $result{custom}{$key1}{$key2}{required_field} = $hash_ref->{required_field};
                    $result{custom}{$key1}{$key2}{user_input}     = $hash_ref->{user_input};
                    $result{custom}{$key1}{$key2}{function_input} = $hash_ref->{function_input};
                }
            }
            else {
                Message("ERROR: $custom_config_file NOT exist!");
                $result{success} = 0;
            }
        }
    }

    return \%result;
}

##########################################################
# This method is to generate meta data
#
# input:
#       -dbc => the database connection.
#		-library => the library name for which data submission will be generated
#		-flowcell => the flowcell code for which data submission will be generated. Optional. Default is all flowcells of the specified library
#		-out_file => the output file name. optional.
#		-known_alia => hash reference to alias with known value
#
# output:
#		Hash reference.
#			$hash->{success}		- indicates if the meta data was generated successfully
#			$hash->{missing_data}	- contains the missing data if any
#			$hash->{meta_data}		- contains the meta data xml string
#       	If the output file name is specified, it will write the xml string to the file too.
#
# example:
#		my $result = $data_submission->generate_meta_data( -dbc=>$dbc, -library=>$library );
#		my $result = $data_submission->generate_meta_data( -dbc=>$dbc, -library=>$library, -flowcell=>$flowcell );
#		my $result = $data_submission->generate_meta_data( -dbc=>$dbc, -library=>$library, -out_file=>$file );
#
############################
sub generate_meta_data {
    my $self             = shift;
    my %args             = @_;
    my $data             = $args{-data};
    my $file             = $args{-out_file};
    my $force            = $args{-force};
    my $suppress_no_data = $args{-suppress_no_data};

    my %results;
    $self->{force}            = $force;
    $self->{suppress_no_data} = $suppress_no_data;
    $self->{data}             = $data;
    $self->{missing_data}     = {};
    my $map = $self->map_value( -data => $data );

    ## add static data
    foreach my $alia ( keys %{ $self->{static_data} } ) {
        for ( my $i = 0; $i < @$map; $i++ ) {
            $map->[$i]{$alia} = [ $self->{static_data}{$alia} ];
        }
    }

    my $total_missing = 0;
    for ( my $i = 0; $i < @{ $self->{data} }; $i++ ) {
        my $missing_data = $self->check_required_field(
            -field => $self->{required_field},
            -data  => $data->[$i]
        );
        my $count = keys %$missing_data;
        $total_missing += $count;
        if ($count) {
            $self->{missing_data}{$i}{missing} = $missing_data;
            $self->{missing_data}{$i}{data}    = $data->[$i];
            my $data_set_number = $i + 1;
            print "$count required fields are missing data from data set $data_set_number!\n\n";

            #print HTML_Dump $data->[$i];
        }
    }
    if ($total_missing) {
        foreach my $data_set ( keys %{ $self->{missing_data} } ) {
            foreach my $field ( keys %{ $self->{missing_data}{$data_set}{missing} } ) {
                my $names = $self->get_names_from_alias( -alias => $self->{missing_data}{$data_set}{missing}{$field}{alias} );
                $self->{missing_data}{$data_set}{missing}{$field}{names} = $names;
            }
        }
        $results{missing_data} = $self->{missing_data};

        #print HTML_Dump "missing data report:", $self->{missing_data};
    }

    if ( $total_missing && !$self->{force} ) {
        print "No submission generated!\n";
        $results{success} = 0;
    }
    else {
        $results{success} = 1;
        my $xml = $self->fill_template( -map => $map );
        $results{meta_data} = $xml;
        if ($file) {
            if ( open OUT, ">$file" ) {
                print OUT $xml;
                close(OUT);
            }
            else {
                print "WARNING: Couldn't open file $file for writing! $!\n";
            }
        }

        ## catch the missing data produced from custom templates
        if ( $self->{missing_data} ) {
            foreach my $data_set ( keys %{ $self->{missing_data} } ) {
                foreach my $field ( keys %{ $self->{missing_data}{$data_set}{missing} } ) {
                    if ( !defined $self->{missing_data}{$data_set}{missing}{$field}{names} ) {
                        my $names = $self->get_names_from_alias( -alias => $self->{missing_data}{$data_set}{missing}{$field}{alias} );
                        $self->{missing_data}{$data_set}{missing}{$field}{names} = $names;
                    }
                }
            }

            #print HTML_Dump $self->{missing_data};
            $results{missing_data} = $self->{missing_data};
        }
    }
    return \%results;
}

#############################
# Get the XML element name from the specified alias
#
# Usage:	my @names = @{get_names_from_alias( -alias => $alias )};
#
# Return:	Array ref
##############################
sub get_names_from_alias {
##############################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'alias', -madatory => 'alias' );
    my $alias = $args{-alias};

    my @names = ();
    foreach my $key ( keys %{ $self->{'alia'} } ) {
        if ( $alias eq $self->{'alia'}{$key} ) {
            push @names, $key;
        }
    }
    return \@names;
}

##########################################################
# This method is to check if the required fields have data
#
# input:
#       -data => reference to array of data
#		-field => the required field array reference
#
# output:
#       hash reference
#		print out the detail of the fields without data
#
# example:
#		my $report = $data_submission->check_required_field( -data=>$data, -field=>$required_fields );
#
############################
sub check_required_field {
    my $self   = shift;
    my %args   = @_;
    my $fields = $args{-field};
    my $data   = $args{-data};

    my %report;
    foreach my $field ( @{$fields} ) {
        if ( !defined $data->{$field} ) {
            if ( $field =~ /(.+)\s+AS\s+([\w.`]+){1}\s*$/ ) {
                my $alias      = $2;
                my $field_only = $1;
                if ( !defined $data->{$alias} || !$data->{$alias} ) {
                    $report{$field}{field} = $field_only;
                    $report{$field}{alias} = $alias;
                }
            }
            else {
                $report{$field}{field} = $field;
                $report{$field}{alias} = $field;
            }
        }
        elsif ( !$data->{$field} ) {
            $report{$field}{field} = $field;
            $report{$field}{alias} = $field;
        }
    }

    foreach my $field ( keys %report ) {
        Message("WARNING: $field is required but it is missing!\n");
    }
    return \%report;
}
##########################################################
# This method is to retrieve values for the fields specified in $self->{field} and store the values to $self->{value}
#
# input:
#       -dbc => the database connection.
#		-library => the library name for which data submission will be generated
#		-flowcell => the flowcell code for which data submission will be generated. Optional. Default is all flowcells of the specified library
#
# output:
#       None.
#
# update:
#		$self->{value}, $self->{field}
#
# example:
#		$data_submission->retrieve_values( -dbc=>$dbc, -library=>$library, -flowcell=>$flowcell );
#
############################
sub retrieve_values {
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $args{-dbc};
    my $library = $args{-library};

    #my $condition = $args{-condition};
    my $flowcell    = $args{-flowcell};
    my $data_source = $args{-data_source};

    my @customized_fields;
    my @customized_values;

    ## get the field names that can be customized
    my %custom_fields = $self->get_custom_field();

    ## retrieve values for the fields from database tables
    ## note: $self->{field} contains names for both fields and attributes. This method should be able to self distinguish between a field and an attribute when retrieving values from tables
    foreach my $key ( @{ $self->{field} } ) {

        ## seperate the table name and the field/attribute name, and then retrieve the values and put it in @value
        my $values = $self->retrieve_value(
            -field    => $key,
            -API      => $data_source,
            -dbc      => $dbc,
            -library  => $library,
            -flowcell => $flowcell
        );
        push @{ $self->{value} }, $values;

        ## check if this field need to be customized
        if ( exists $custom_fields{$key} ) {
            foreach my $xml_alia ( @{ $custom_fields{$key} } ) {
                foreach my $value (@$values) {
                    my @extra_fields = $self->{custom}{$xml_alia}{$value}{'Field'};
                    foreach my $key2 (@extra_fields) {
                        ## check if this field already captured by @{$self->{field}} or @customized_fields. if not, add it.
                        my $captured = 0;
                        if ( ( exists $self->{field}{$key2} ) || ( grep /^$key2$/, @customized_fields ) ) {
                            $captured = 1;
                        }
                        if ( !$captured ) {
                            ## seperate the table name and the field/attribute name, and then retrieve the values and put it in @extra_values
                            my $extra_values = $self->retrieve_value(
                                -field    => $key2,
                                -API      => $data_source,
                                -dbc      => $dbc,
                                -library  => $library,
                                -flowcell => $flowcell
                            );
                            push @customized_fields, $key2;
                            push @customized_values, $extra_values;
                        }
                    }
                }
            }
        }
    }

    push @{ $self->{field} }, \@customized_fields;
    push @{ $self->{value} }, \@customized_values;
}

##########################################################
# This method is to retrieve value for the given field and return its value
#
# input:
#		-field => the field/attribute name
#       -dbc => the database connection.
#		-library => the library name
#		-flowcell => the flowcell code
#		-data_source => the data source, e.g. 'Sequencing::Sequencing_API'
#
# output:
#       array reference of the value for the specified field/attribute. e.g. ["WA01"]
#
# example:
#       my $value = $data_submission->retrieve_value( -field=>"Original_Source.Host", -API=>'Illumina::Solexa_API',  -library=>"HS0995", -flowcell=>$flowcell );
############################
sub retrieve_value {
############################
    my $self            = shift;
    my %args            = @_;
    my $dbc             = $args{-dbc};
    my $library         = $args{-library};
    my $flowcell        = $args{-flowcell};
    my $qualified_field = $args{-field};      ## The field needs to be quilified
    my $api_name        = $args{-API};
    my $module;
    my $field;
    my $table;
    my %Custom_Aliases;

    if ( $api_name =~ /.*\:\:(.*)/ ) {
        $module = $1;
    }
    use SDB::HTML;
    eval "require $api_name";

    unless ($library) {
        Message('You need to supply a library name');
        return;
    }
    if ( $qualified_field =~ /(.*)\.(.*)/ ) {
        $table = $1;
        $field = $2;
        $field .= '_XML_Call';
    }
    else {
        Message "The input field ($qualified_field) is not qualified";
        return;
    }
    my $Plugin_API = $module->new( -dbc => $dbc );
    $Custom_Aliases{$table}{$field} = $qualified_field;
    $Plugin_API->add_custom_aliases( -custom_aliases => \%Custom_Aliases );
    my $data = $Plugin_API->get_Atomic_data(
        -library  => $library,
        -flowcell => $flowcell,
        -fields   => $field
    );
    my %data_hash = %$data;
    return unique_items( $data_hash{$field} );
}
##########################################################
# This method is to map the values to the corresponding alias
#
# input:
#		None.
#
# output:
#		hash reference to the alia and value pairs
#
# example:
#		my $href = $data_submission->map_value();
#
############################
sub map_value {
    my $self = shift;
    my %args = @_;
    my $data = $args{-data};

    my @use_NA_if_null;
    @use_NA_if_null = @{ $self->{use_NA_if_null} } if ( defined $self->{use_NA_if_null} );
    my @data_map;

    ## map the values in $data to the alias in $self->{alia}
    for ( my $i = 0; $i < @{$data}; $i++ ) {
        my %hash;
        foreach my $alia ( keys %{ $self->{alia} } ) {
            my $field_name = $self->{alia}{$alia};
            if ( defined $data->[$i]{$field_name} && $data->[$i]{$field_name} ne '' ) {
                my @arr = split /,,/, $data->[$i]{$field_name};
                $hash{$alia} = \@arr;

                #$hash{$alia} = [$data->[$i]{$field_name}];
            }
            else {
                foreach my $elem (@use_NA_if_null) {
                    if ( $elem =~ /.+\s+AS\s+([\w.`]+){1}\s*$/ ) {
                        my $na_alias = $1;
                        $hash{$alia} = ['NA'] if ( $field_name eq $na_alias );
                    }
                    else {
                        $hash{$alia} = ['NA'] if ( $field_name eq $elem );
                    }
                }
            }
        }
        push @data_map, \%hash;
    }

    if (@data_map) {
        $self->{data_index} = 0;
    }
    else {
        $self->{data_index} = -1;
    }
    return \@data_map;
}

##########################################################
# This method is to fill values to the XML template
#
# input:
#		-map => hash reference of XML element/attribute and value pairs
#
# output:
#		XML string
#
# example:
#		my $xml = $data_submission->fill_template( -map=>$map_href );
#
# note:
#		This method assumes the XML template is well formatted.
#		Each line has only one open tag with or without attributes.
#		If it is a simple text element, the matching closing tag is in the same line as the open tag.
#		It also assumes the number of values matches with each other.
############################
sub fill_template {
    my $self     = shift;
    my %args     = @_;
    my $map_aref = $args{ -map };

    ## add pointers to indicate the current values
    my @map;
    for ( my $i = 0; $i < @$map_aref; $i++ ) {
        my %hash;
        foreach my $key ( keys %{ $map_aref->[$i] } ) {
            $hash{$key}{value}   = $map_aref->[$i]{$key};
            $hash{$key}{pointer} = 0;                       # set the initial pointer to the first element of the value array
        }
        push @map, \%hash;
    }

    #print Dumper \@map;

    ## read in the template and store it as a linked tree
    ## each node of the tree: id, name, text, attribute, parent, first child, next
    ##
    my $template = SDB::Xml_Tree->new( -file => $self->{template} );
    if ( keys %{ $self->{TAG} } ) {
        $self->expand_TAG( -tree => $template, -TAG => $self->{TAG}, -flag => 'a' );
    }
    my $work_tree = SDB::Xml_Tree->new();
    $work_tree->copy(
        -source_tree => $template,
        -source_node => $template->get_root(),
        -recursive   => 1
    );
    $work_tree->set_root( -root => 0 );

    #my $work_tree_xml = $work_tree->render( -exclude_empty_attribute=>1 );
    #print $work_tree_xml;
    my $next_to_header;
    ## fill the template header
    if ( $self->{data_index} >= 0 ) {
        $next_to_header = $self->fill_header( -tree => $work_tree, -map => \@map );
    }

    ## fill the remaining of the template
    #my $copy_node = 1;
    my $copy_node = $next_to_header;
    my $repeat    = 0;
    my $node      = $copy_node;
    my $parent    = $work_tree->get_parent( -node => $node );
    while ( $self->{data_index} >= 0 && $self->{data_index} < @map ) {
        if ($repeat) {

            #print "repeat, copy from template node $copy_node\n";
            my $repeat_node = $work_tree->copy(
                -source_tree => $template,
                -source_node => $copy_node,
                -parent      => $parent,
                -recursive   => 1
            );
            $work_tree->set_next(
                -node => $repeat_node,
                -next => $work_tree->get_next( -node => $node )
            );
            $work_tree->set_next( -node => $node, -next => $repeat_node );
            $node = $repeat_node;

            #print Dumper $work_tree->{tree};
            #print $work_tree->render( -exclude_empty_attribute=>1 );
        }

        ## fill the root node, and recursively to its children and next node
        $self->fill_node(
            -tree     => $work_tree,
            -node     => $node,
            -map      => $map[ $self->{data_index} ],
            -template => $template
        );

        #print Dumper $work_tree->{tree};
        $self->{data_index}++;
        $repeat = 1;
    }

    ## restore TAG-VALUE pairs
    $self->restore_TAG( -tree => $work_tree, -TAG => $self->{TAG} );

    if ( $self->{suppress_no_data} ) {
        $self->suppress_no_data( -tree => $work_tree );
    }

    #print HTML_Dump "The xml tree:", $work_tree->{tree};
    #exit;
    ## output the XML
    my $xml_out = $work_tree->render( -type => 'xml', -exclude_empty_attribute => 1 );
    return $xml_out;
}

##########################################################
# This method is to fill the xml header
#
# input:
#		-tree => the xml tree reference
#		-map => hash reference of XML element/attribute and value pairs
#
# output:
#		none
#
# update:
#		the xml tree
#
# example:
#		my $xml = $data_submission->fill_header( -tree=>$tree, -map=>$map );
#
############################
sub fill_header {
    my $self = shift;
    my %args = @_;
    my $tree = $args{-tree};
    my $map  = $args{ -map };

    my $node = $tree->get_root();
    if ( !defined $self->{template_header} ) {
        return $node;
    }

    while ( $tree->is_valid( -node => $node ) ) {
        my $name = $tree->get_name( -node => $node );
        if ( grep /^$name$/, @{ $self->{template_header} } ) {
            if ( exists $map->[ $self->{data_index} ]{$name} ) {
                $tree->set_text(
                    -node => $node,
                    -text => $map->[ $self->{data_index} ]{$name}{value}[0]
                );
            }

            my $attrs = $tree->get_attribute( -node => $node );
            foreach my $attr ( keys %$attrs ) {
                my $full_attr_name = "$name.$attr";
                if ( exists $map->[ $self->{data_index} ]{$full_attr_name} ) {
                    $tree->set_attribute(
                        -node  => $node,
                        -name  => $attr,
                        -value => $map->[ $self->{data_index} ]{$full_attr_name}{value}[0]
                    );
                }
            }
        }
        else {
            last;
        }

        $node = $tree->get_next_node( -current => $node );
    }
    return $node;    # return the next node after the header
}

##########################################################
# This recursive method is to fill a XML tree node, its children, and its sister nodes
#
# input:
#
#
# output:
#		XML string
#
# example:
#		my $xml = $data_submission->fill_template();
#
# note:
#		This method assumes the XML template is well formatted.
#		Each line has only one open tag with or without attributes.
#		If it is a simple text element, the matching closing tag is in the same line as the open tag.
#		It also assumes the number of values matches with each other.
############################
sub fill_node {
    my $self     = shift;
    my %args     = @_;
    my $tree     = $args{-tree};
    my $node     = $args{-node};
    my $map      = $args{ -map };
    my $template = $args{-template};

    my $node_name = $tree->get_name( -node => $node );

    ## fill this node if it is fillable and has value
    ## fillable: not header, text not '' or has attribute
    if ( $self->is_fillable( -tree => $tree, -node => $node, -map => $map ) ) {

        #Message( "node $node $node_name fillable\n" );
        my $has_value     = 0;
        my $repeat        = 0;
        my $original_node = $node;
        while ( $self->has_value( -tree => $tree, -node => $node, -map => $map ) ) {
            ## copy the node and its children if this is a repeat
            if ($repeat) {

                #Message( "repeat, copy from template node $original_node\n" );
                my $original_node_name = $tree->get_name( -node   => $original_node );
                my $source_node        = $template->search( -name => $original_node_name );
                my $repeat_node        = $tree->copy(
                    -source_tree => $template,
                    -source_node => $source_node,
                    -parent      => $tree->get_parent( -node => $original_node ),
                    -recursive   => 1
                );
                $tree->set_next(
                    -node => $repeat_node,
                    -next => $tree->get_next( -node => $node )
                );
                $tree->set_next( -node => $node, -next => $repeat_node );
                $node = $repeat_node;

                #Message( "repeated node $original_node, node node=$node\n" );
            }
            $has_value = 1;
            my $name = $tree->get_name( -node => $node );

            #Message( "[$name] has value\n" );

            ## handle custom elements
            ## replace this node with the customized one, keep the parent and next pointers unchanged
            if ( exists $self->{custom}{$name} ) {
                my $value          = $map->{$name}{value}[ $map->{$name}{pointer} ];
                my $required_field = $self->{custom}{$name}{$value}{required_field};
                my $missing_data   = $self->check_required_field(
                    -field => $required_field,
                    -data  => $self->{data}[ $self->{data_index} ]
                );
                my $count = keys %$missing_data;
                if ($count) {
                    $self->{missing_data}{ $self->{data_index} }{missing} = $missing_data;
                    $self->{missing_data}{ $self->{data_index} }{data}    = $self->{data}[ $self->{data_index} ];
                    my $data_set_number = $self->{data_index} + 1;
                    print "$count required custom fields are missing data from data set $data_set_number!\n\n";

                    #print HTML_Dump $self->{data}[ $self->{data_index} ];
                    if ( !$self->{force} ) {
                        print "No submission generated!\n";
                        exit;
                    }
                }

                my $custom_tag = $self->{custom}{$name}{$value}{TAG};
                if ( keys %$custom_tag ) {
                    $self->expand_TAG(
                        -tree   => $tree,
                        -TAG    => $custom_tag,
                        -flag   => 'r',
                        -branch => $node
                    );

                }

                my $custom_template = $self->{custom}{$name}{$value}{template};
                if ($custom_template) {
                    $node = $tree->replace( -old => $node, -template => $custom_template );
                    $name = $tree->get_name( -node => $node );

                    #print "custom template replaced! current node=$node\n";
                    #print Dumper $tree->{tree};
                }

                # if no text nor attribute for this node, update the pointer
                my $text  = $tree->get_text( -node      => $node );
                my $attrs = $tree->get_attribute( -node => $node );
                if ( $text eq '' && !( keys %$attrs ) ) {
                    my $next_value = $self->get_next_value( -map => $map, -key => $name );
                }

            }

            ## replace text
            my $text = $tree->get_text( -node => $node );
            if ( $text ne '' ) {
                if ( $text =~ /^\*.*\*/ ) {
                    my $new_text = $self->get_next_value( -map => $map, -key => $name );    # get the next value
                    $tree->set_text( -node => $node, -text => $new_text );                  # replace text for $node
                }
            }

            ## replace attribute values
            my $attrs = $tree->get_attribute( -node => $node );
            if ( keys %$attrs ) {
                my $value_count = 0;
                my %static;
                foreach my $attr ( keys %$attrs ) {
                    my $full_name = "$name.$attr";
                    my $new_value = $self->get_next_value( -map => $map, -key => $full_name );
                    $tree->set_attribute(
                        -node  => $node,
                        -name  => $attr,
                        -value => $new_value
                    );
                    if ($new_value) {
                        $value_count++;
                    }
                    elsif ( defined $self->{static_data}{$full_name} ) {
                        $static{$attr} = $self->{static_data}{$full_name};
                    }
                }

                ## if at least one attribute has value and there are static data for attributes but not in $map, fill in the static data
                if ( $value_count && keys %static ) {
                    foreach my $attr ( keys %static ) {
                        $tree->set_attribute(
                            -node  => $node,
                            -name  => $attr,
                            -value => $static{$attr}
                        );
                    }
                }
            }

            # if no text nor attribute for this node, update the pointer
            if ( $text eq '' && !( keys %$attrs ) ) {
                my $next_value = $self->get_next_value( -map => $map, -key => $name );
            }

            ## fill its children
            my $child = $tree->get_first_child( -node => $node );
            if ( $tree->is_valid( -node => $child ) ) {
                $self->fill_node(
                    -tree     => $tree,
                    -node     => $child,
                    -map      => $map,
                    -template => $template
                );
            }

            $repeat = 1;
        }    # END while has_value

        ## handle fillable elements without value
        ## remove the preset text and attribute value
        if ( !$has_value ) {
            my $child = $tree->get_first_child( -node => $node );

            #if( $self->{suppress_no_data} && !( $tree->is_valid( -node=>$child ) ) ) {
            #	$tree->remove( -node=>$node ); ## remove this node if the flag is set and it hasn't children
            #}
            #else { ## remove the preset text and attribute value
            my $pre_set_text = $tree->get_text( -node => $node );
            if ( defined $pre_set_text && $pre_set_text =~ /^\*.*\*/ ) {    # remove this pre-set text
                $tree->set_text( -node => $node, -text => '' );
            }

            my %attrs = %{ $tree->get_attribute( -node => $node ) };
            foreach my $attr ( keys %attrs ) {
                my $pre_set_attribute_value = $attrs{$attr};
                if ( $pre_set_attribute_value =~ /^\*.*\*$/ ) {             # remove this pre-set value
                    $tree->set_attribute( -node => $node, -name => $attr, -value => '' );
                }
            }

            ## fill its children
            if ( $tree->is_valid( -node => $child ) ) {
                $self->fill_node(
                    -tree     => $tree,
                    -node     => $child,
                    -map      => $map,
                    -template => $template
                );
            }

            #}
        }
    }
    ## this node not fillable, check its children
    else {
        ## fill its children
        my $child = $tree->get_first_child( -node => $node );
        if ( $tree->is_valid( -node => $child ) ) {
            $self->fill_node(
                -tree     => $tree,
                -node     => $child,
                -map      => $map,
                -template => $template
            );
        }
    }

    $map->{$node_name}{pointer} = 0;

    ## fill the next node
    my $next_node = $tree->get_next( -node => $node );
    if ( $tree->is_valid( -node => $next_node ) ) {
        $self->fill_node(
            -tree     => $tree,
            -node     => $next_node,
            -map      => $map,
            -template => $template
        );
    }
}

sub add_submission_action {
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'action,xml,attributes', -mandatory => 'action,xml' );
    my $action     = $args{-action};
    my $xml        = $args{-xml};
    my $attributes = $args{-attributes};                                                                  # hash ref

    my $old = "<ACTIONS>";
    my $new = "<ACTIONS>\n\t\t<ACTION>\n\t\t\t<$action";
    if ($attributes) {
        foreach my $attr ( keys %$attributes ) {
            $new .= " $attr=\"$attributes->{$attr}\"";
        }
    }
    $new .= "></$action>\n\t\t</ACTION>";

    if ( $xml =~ /\<ACTIONS\>/ ) {
        $xml =~ s|$old|$new|g;
    }
    return $xml;
}

##########################################################
# This method is to expand a XML tree with special TAGs.
# Expanded TAGs for the same node have the same parent node.
# For simplicity, all the expanded tags are not allowed to have children currently.
#
# input:
#		-tree => a Xml_Tree object
#		-TAG  => hash reference. Keys are Xml tree node names. Values are tag names.
#				'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG' => ['MOLECULE','DISEASE','BIOMATERIAL_PROVIDER','BIOMATERIAL_TYPE']
#		-flag => indicate to append or replace the expanded tags. 'a' for append, 'r' for replace.
#
# output:
#		None.

# update:
#		update the Xml_Tree object, specifically, the nodes of the Xml_Tree.
#
# example:
#		$self->expand_TAG( -tree=>$tree, -TAG=>$tag_href )
#
############################
sub expand_TAG {
    my $self     = shift;
    my %args     = @_;
    my $tree     = $args{-tree};
    my $tag_href = $args{-TAG};
    my $flag     = $args{-flag};
    my $branch   = $args{-branch};

    foreach my $key ( keys %$tag_href ) {
        ## look up the node with name $key in the tree
        my $node = $tree->search( -name => $key, -branch => $branch );
        $key =~ /([\w\.]+)\.([\w]+)$/;
        my $prefix = $1;

        ## replace this node with the first tag in the list
        my $tag_num = @{ $tag_href->{$key} };
        if ($tag_num) {
            if ( $flag eq 'a' ) {
                $tree->set_name( -node => $node, -name => "$key.$tag_href->{$key}[0]" );
            }
            elsif ( $flag eq 'r' ) {
                $tree->set_name( -node => $node, -name => "$prefix.$tag_href->{$key}[0]" );
            }
        }

        ## add the remaining tags in the list
        my $parent      = $tree->get_parent( -node => $node );
        my $parent_name = $tree->get_name( -node   => $parent );
        my $parent_next = $tree->get_next( -node   => $parent );

        my $previous = $parent;
        my $last     = $parent;
        for ( my $i = 1; $i < $tag_num; $i++ ) {
            my $new_node = $tree->copy(
                -source_tree => $tree,
                -source_node => $parent,
                -parent      => $tree->get_parent( -node => $parent ),
                -recursive   => 1
            );
            my $new_tag = $tree->get_first_child( -node => $new_node );

            #$tree->set_name( -node=>$new_tag, -name=>"$key.$tag_href->{$key}[$i]" );
            if ( $flag eq 'a' ) {
                $tree->set_name( -node => $new_tag, -name => "$key.$tag_href->{$key}[$i]" );
            }
            elsif ( $flag eq 'r' ) {
                $tree->set_name( -node => $new_tag, -name => "$prefix.$tag_href->{$key}[$i]" );
            }

            $tree->set_next( -node => $previous, -next => $new_node );
            $previous = $new_node;
            $last     = $new_node;
        }
        $tree->set_next( -node => $last, -next => $parent_next );
    }
}

##########################################################
# This method is to restore the special TAGs that were expanded previously through expand_TAG().
# It is usually called before rendering the xml tree.
#
# For example, a TAG node with
# 	'name' => "SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.MOLECULE"
# 	'text' => "genomic"
# will be updated to :
# 	'name' => "SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG"
# 	'text' => "MOLECULE"
# and its VALUE node updated to :
# 	'name' => "SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.VALUE"
# 	'text' => "genomic"
#
# input:
#		-tree => a Xml_Tree object
#		-TAG  => hash reference. Keys are Xml tree node names. Values are tag names.
#				'SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG' => ['MOLECULE','DISEASE','BIOMATERIAL_PROVIDER','BIOMATERIAL_TYPE']
#
# output:
#		None.

# update:
#		update the Xml_Tree object, specifically, the nodes of the Xml_Tree.
#
# example:
#		$self->restore_TAG( -tree=>$tree, -TAG=>$tag_href )
############################

=begin
sub restore_TAG {
	my $self	= shift;
	my %args	= @_;
	my $tree	= $args{-tree};
	my $tag_href	= $args{-TAG};
	print Dumper $tag_href;
	foreach my $key ( keys %$tag_href ) {
		if( @{$tag_href->{$key}} <= 0 ) {
			next;
		}
		
		#
		## update the first tag
		#
		my $name = $key . '.' . $tag_href->{$key}[0];
		## tag node
		my $first_tag_node = $tree->search( -name=>$name );
		my $value = $tree->get_text( -node=>$first_tag_node );
		$tree->set_name( -node=>$first_tag_node, -name=>$key );
		$tree->set_text( -node=>$first_tag_node, -text=>$tag_href->{$key}[0] );
		## value node
		my $value_node = $tree->get_next( -node=>$first_tag_node );
		$tree->set_text( -node=>$value_node, -text=>$value );
		
		#
		## update the remaining tags
		#
		my $parent = $tree->get_parent( -node=>$first_tag_node );
		my $next = $tree->get_next( -node=>$parent );
		
		while( $tree->is_valid( -node=>$next ) ) {
			## tag node
			my $tag_node = $tree->get_first_child( -node=>$next );
			my $name = $tree->get_name( -node=>$tag_node );
			$name =~ /$key\.(\w+)/;
			my $tag_name = $1;
			my $value = $tree->get_text( -node=>$tag_node );
			$tree->set_name( -node=>$tag_node, -name=>$key );
			$tree->set_text( -node=>$tag_node, -text=>$tag_name );
			## value node
			my $value_node = $tree->get_next( -node=>$tag_node );
			$tree->set_text( -node=>$value_node, -text=>$value );
			
			$next = $tree->get_next( -node=>$next );
		}
	} # END foreach $key	
}
=cut

sub restore_TAG {
    my $self     = shift;
    my %args     = @_;
    my $tree     = $args{-tree};
    my $tag_href = $args{-TAG};

    foreach my $key ( keys %$tag_href ) {
        if ( @{ $tag_href->{$key} } <= 0 ) {
            next;
        }

        my @matches = $tree->search( -start_with => $key, -return_all => 1 );
        foreach my $tag_node (@matches) {
            my $node_name = $tree->get_name( -node => $tag_node );
            $node_name =~ /$key\.(.+)/;
            my $tag_name = $1;
            my $value = $tree->get_text( -node => $tag_node );
            $tree->set_name( -node => $tag_node, -name => $key );
            $tree->set_text( -node => $tag_node, -text => $tag_name );
            ## value node
            my $value_node = $tree->get_next( -node => $tag_node );
            $tree->set_text( -node => $value_node, -text => $value );
        }
    }    # END foreach $key
}

##########################################################
# This method is to check if a given node is fillable.
# A node is fillable if it meets any of the following:
# 	1. Its text is neither empty nor static data; # (it could match patern /\*.*\*/,or /^\s+$/)
#	2. It has attribute(s) and at least one of the attribute value meets point 1 above;
#	3. It has value. ( mainly used for customizable elements and/or repeatable complex elements)
#
# input:
#		-tree => Xml_Tree object
#		-node => tree node id
#
# output:
#		1 - if the given node is fillable.
#		0 - if the given node is not fillable.
#
# example:
#		$Data_Submission->is_fillable( -tree=>$tree, -node=>$node );
#
############################
sub is_fillable {
    my $self = shift;
    my %args = @_;
    my $tree = $args{-tree};
    my $node = $args{-node};
    my $map  = $args{ -map };

    my $name = $tree->get_name( -node => $node );
    if ( grep /^$name$/, @{ $self->{template_header} } ) {    # header, not fillable
        return 0;
    }

    my $text  = $tree->get_text( -node      => $node );
    my $attrs = $tree->get_attribute( -node => $node );
    my $attr_num = keys %$attrs;

    if ( $text =~ /\*.*\*/ || $text =~ /^\s+$/ ) {
        return 1;
    }

    foreach my $key ( keys %$attrs ) {
        return 1 if ( $attrs->{$key} =~ /\*.*\*/ || $attrs->{$key} =~ /^\s+$/ );
    }

    #return 1 if( $self->has_value( -tree=>$tree, -node=>$node, -map=>$map ) );

    return 0;
}

##########################################################
# This method is to check if a given node is fillable.
# A node is fillable if it meets all of the following:
# 	1. Its text is not empty or it has attribute(s)
#	2. It has value to fill in
#
# input:
#		-tree => Xml_Tree object
#		-node => tree node id
#		-map => hash reference of XML element/attribute and value pairs
#
# output:
#		1 - if the given node is fillable.
#		0 - if the given node is not fillable.
#
# example:
#		$Data_Submission->is_fillable( -tree=>$tree, -node=>$node );
#
# note:
#		Only the current node is checked for avaialble values to fill in currently. Its children are not checked.
############################
sub has_value {
    my $self = shift;
    my %args = @_;
    my $tree = $args{-tree};
    my $node = $args{-node};
    my $map  = $args{ -map };

    my $text  = $tree->get_text( -node      => $node );
    my $attrs = $tree->get_attribute( -node => $node );
    my $attr_num = keys %$attrs;
    my $element_name = $tree->get_name( -node => $node );

    if ($text) {
        if ( exists $map->{$element_name}{value} ) {
            my @values = @{ $map->{$element_name}{value} };
            my $ptr    = $map->{$element_name}{pointer};
            return 0 if ( $ptr >= (@values) );    # already reached the last value
        }
        else {
            return 0;
        }
    }

    if ($attr_num) {
        ## if at least one attribute has value, return 1; otherwise return 0
        my $num_has_value = 0;
        foreach my $attr ( keys %$attrs ) {
            my $full_attr_name = "$element_name.$attr";
            if ( defined $map->{$full_attr_name}{value} ) {
                my @values = @{ $map->{$full_attr_name}{value} };
                my $ptr    = $map->{$full_attr_name}{pointer};
                if ( $ptr < (@values) ) {
                    $num_has_value++;
                }
            }
        }
        if ( !$num_has_value ) {
            return 0;
        }
    }

    ## for elements without text or attribute, but only with value for customization
    if ( !$text && !$attr_num ) {
        if ( exists $map->{$element_name}{value} ) {
            my @values = @{ $map->{$element_name}{value} };
            my $ptr    = $map->{$element_name}{pointer};
            return 0 if ( $ptr >= (@values) );    # already reached the last value
        }
        else {
            return 0;
        }
    }

    return 1;
}
##########################################################
# This method is to retrieve the next value for a given key
#
# input:
#		-map => hash reference of XML element/attribute and value pairs
#		-key => key of the hash
#
# output:
#		value for the given key
#
# example:
#		$self->get_next_value( -map=>$map, -key=>$name );
############################
sub get_next_value {
    my $self = shift;
    my %args = @_;
    my $map  = $args{ -map };
    my $key  = $args{-key};

    if ( defined $map->{$key}{value} ) {
        my @values = @{ $map->{$key}{value} };
        my $ptr    = $map->{$key}{pointer};
        if ( $ptr < (@values) ) {
            $map->{$key}{pointer}++;
            return $values[$ptr];
        }
        else {
            return;
        }
    }
    else {
        return;
    }
}

##########################################################
# This method is to collect the fields whose matching XML alias can be customized
#
# input:
#		None.
#
# output:
#		hash reference. e.g.:
#		'Original_Source.Biomaterial_Type' => ['SAMPLE_SET.SAMPLE.SAMPLE_ATTRIBUTES.SAMPLE_ATTRIBUTE.TAG.BIOMATERIAL_TYPE']
#
# example:
#		my %custom_fields = $self->get_custom_field();
############################
sub get_custom_field {
    my $self = shift;

    my %result;
    my @custom = keys %{ $self->{custom} };
    foreach my $key (@custom) {
        my $field = $self->{alia}{$key};
        if ( exists $result{$field} ) {
            my @arr = @{ $result{$field} };
            push @arr, $key;
        }
        else {
            $result{$field} = [$key];
        }
    }
    return \%result;
}

#####################################################################
#
# This method is to parse the input XML file and return the xml elements and attributes, and their counts and values in hash structure. It also returns a XML template.
#
# input:   XML file name
# output:  A hash reference with two keys:
#          'element'  => hash reference to the hash that contains the xml elements and attributes, and their counts and values
#          'template' => a string that contains the XML template
# example: my $hash_ref = $data_submission->parse_xml( -file = > $filename )
#####################################################################
sub parse_xml {
################
    my $self = shift;
    my %args = @_;
    my $file = $args{-file};

    # initialize the XML::Parser with references to handler routines
    #
    my $handlers = Xml_Parser_Handler->new();
    my $parser   = XML::Parser->new(
        Handlers => {
            Start => sub { $handlers->handle_elem_start(@_) },
            End   => sub { $handlers->handle_elem_end(@_) },
            Char  => sub { $handlers->handle_char_data(@_) }
        }
    );

=begin
    my $parser = XML::Parser->new( Handlers => {
        Start =>   \&handle_elem_start,
        End => \&handle_elem_end,
	    Char =>    \&handle_char_data
    } );
=cut

    #
    # read in the data and run the parser on it
    #
    if ($file) {
        $parser->parsefile($file);
        my %return;

        #$return{template} = $template;
        #$return{element} = \%elements;
        $return{template} = $handlers->{template};
        $return{element}  = $handlers->{elements};
        return \%return;
    }
    else {
        print "File $file does not exist!\n";
        return;
    }

    ###
    ### Handlers
    ###
    package Xml_Parser_Handler;

    sub new {
        my $type = shift;
        my $self = {};

=begin
	my %elements;
	my $template = '';
	my @element_stack;
	my $current_data;	
	my $last_start_element; 
=cut

        $self->{elements}           = {};
        $self->{template}           = '';
        $self->{element_stack}      = ();
        $self->{current_data}       = '';
        $self->{last_start_element} = '';
        bless( $self, $type );
        return $self;
    }

    #
    # save element name and attributes
    #
    sub handle_elem_start {
        my ( $expat, $name, %atts ) = @_;

        push @{ $self->{element_stack} }, $name;    #push to stack
        my $path = join '.', @{ $self->{element_stack} };

        $self->{elements}{$path}{count}++;
        my $count = $self->{elements}{$path}{count};
        $self->{elements}{$path}{$count}{attribute} = \%atts if keys(%atts);

        # if there is char data before the start of this tag(typically line breaks, spaces, etc.) , pass it to the template
        if ( $self->{current_data} ) {

            #write to template
            $self->{template} .= $self->{current_data};
        }

        $self->{current_data}       = '';      # reset $self->{current_data}
        $self->{last_start_element} = $name;

        # write to template
        if ( keys(%atts) ) {
            $self->{template} .= "<$name";

            foreach my $att ( keys %atts ) {
                my $fill_text = "$path.$att";
                $self->{template} .= " $att=\"*$fill_text*\"";
            }
            $self->{template} .= ">";
        }

        # No attribute
        else {
            $self->{template} .= "<$name>";
        }
    }

    # collect character data into the recent element's buffer
    #
    sub handle_char_data {
        my ( $expat, $text ) = @_;
        $self->{current_data} .= $text;
    }

    #
    # pop up the closing element from stack
    # if this is a data element, store the data
    #
    sub handle_elem_end {
        my ( $expat, $name ) = @_;
        if ( $name eq $self->{last_start_element} ) {
            my $path = join '.', @{ $self->{element_stack} };
            my $count = $self->{elements}{$path}{count};
            $self->{elements}{$path}{$count}{data} = $self->{current_data};

            # empty $self->{current_data}
            $self->{current_data} = '';

            pop @{ $self->{element_stack} };
            $self->{template} .= "*$path*</$name>";
        }
        else {
            pop @{ $self->{element_stack} };

            # write to template
            $self->{template} .= "$self->{current_data}</$name>";
            $self->{current_data} = '';
        }
    }

}

##########################################################
# This method is to parse the output from parse_xml to retrieve the XML elements/attributes and their values
#
# input:
#	-file => xml file name
#	-ignore_TAG  => flag for ignoring TAG-VALUE pairs
#
# output:
#	two array references. e.g. ( ['TAXON_ID', 'alias'], ['9606', 'HS0995'] )
# 	The first is an array reference to xml element / attribute names that require values.
# 	The second is an array reference to values for the corresponding element /attribute above.
#
# example:
#	my ($element_arrref, $value_arrref) = $data_submission->get_element_value( -file=>$filename )
#
# outline of the method:
#######################
#  $result = parse_xml( -file=>$filename );
#  $elements = $result->{element};
#  foreach $key %$elements {
#      extract the element name from the $key (e.g. SAMPLE from SAMPLE_SET.SAMPLE)
#      if( element name == 'TAG' ) {
#         $prefix = substr of $key ahead of element name
#         my $value_key = "$prefix.VALUE";
#
# 	# another method to handle 'TAG'. Arguments are the pair of 'TAG' and 'VALUE' hashes with the same prefix
#         my ($tag_name_arrref, $tag_value_arrref ) = get_tag_value( $elements->{$key},  $elements->{$value_key})
#         push @elements, @$tag_name_arrref;
# 	push @values, @$tag_value_arrref;
#
#         next;
#      }
#
#      # ignore 'VALUE' elements because they are handled together with 'TAG'
#      elsif( element name == 'VALUE' ) {
#         next;
#      }
#
#      if( element has attibutes ) {
#           foreach attribute {
#               push attribute name to @elements
#               push attribute value to @values
#           }
#      }
#
#      if element has data {
#               push element name to @elements
#               push data to @values
#      }
#  }
#
#  return (\@elements, \@values);
##############################################################
sub get_element_value {
    my $self       = shift;
    my %args       = @_;
    my $file       = $args{-file};
    my $ignore_tag = $args{-ignore_TAG};

    my @elements;
    my @values;

    #print "file to process: $file\n";
    my $parse_result = $self->parse_xml( -file => $file );
    my $element_ref = $parse_result->{element};

    #print Dumper $element_ref;
    foreach my $key ( keys %$element_ref ) {
        my $prefix;
        my $name;
        if ( $key =~ /^(.*\.)([^.]+)$/ ) {
            $prefix = $1;
            $name   = $2;
        }
        else {    # this is the top level element
            $prefix = '';
            $name   = $key;
        }

        if ( uc($name) eq 'TAG' ) {
            if ( !$ignore_tag ) {
                my $value_key = $prefix . 'VALUE';
                my ( $tag_name_arrref, $tag_value_arrref ) = $self->get_tag_value(
                    -tag   => $element_ref->{$key},
                    -value => $element_ref->{$value_key}
                );
                for ( my $i = 0; $i < @$tag_name_arrref; $i++ ) {
                    push @elements, $key . '.' . $tag_name_arrref->[$i];
                    push @values,   $tag_value_arrref->[$i];
                }
            }
            next;
        }

        # ignore 'VALUE' elements because they are handled together with 'TAG'
        elsif ( uc($name) eq 'VALUE' ) {
            next;
        }

        my $count = $element_ref->{$key}{count};
        ## if count is more than one, only the attributes and data for the last count will be retrieved
        if ( $count >= 1 ) {
            if ( exists $element_ref->{$key}{$count} ) {
                ## attributes
                if ( exists $element_ref->{$key}{$count}{attribute} ) {
                    my %attrs = %{ $element_ref->{$key}{$count}{attribute} };
                    foreach my $att ( keys %attrs ) {
                        push @elements, $key . '.' . $att;
                        push @values,   $attrs{$att};
                    }
                }

                ## data
                if ( exists $element_ref->{$key}{$count}{data} && $element_ref->{$key}{$count}{data} ) {
                    push @elements, $key;
                    push @values,   $element_ref->{$key}{$count}{data};
                }
            }
        }
    }    # END foreach $key

    return ( \@elements, \@values );
}

##########################################################
# This method is to handle the special cases that 'TAG' should be treated the same as an XML element
#
# input: two hash references.
#        The first hash has the tag names
#		 The second hash has the tag values.
# 		 Both hash has the structure like ( extracted from the output of parse_xml() ):
#		 {
#  			'1' => {'data' => 'genomic DNA'},
#  			'count' => 2,
#  			'2' => {'data' => 'None'}
#		 }
#
# output: two array references. ( ['MOLECULE', 'DISEASE'], ['genomic DNA', 'None'] )
# The first is an array reference to element names that require values.
# The second is an array reference to values for the corresponding element above.
# example: my ($element_arrref, $value_arrref) = $data_submission->get_tag_value( -tag=>$tag_hashref, -value=>$value_hashref );
#
# Logic of the method:
# my $count = $tag_hashref->{count};
# for( my $i=1; i<=$count; i++ ){
#	push @tags, $tag_hashref->{$i}{data};
#	push @values, $value_hashref->{$i}{data};
#}
#
###################################
sub get_tag_value {
    my $self          = shift;
    my %args          = @_;
    my $tag_hashref   = $args{-tag};
    my $value_hashref = $args{-value};

    my @tags;
    my @values;

    my $tag_count   = $tag_hashref->{count};
    my $value_count = $value_hashref->{count};

    if ( $tag_count != $value_count ) {
        print "ERROR: TAG count is NOT the same as VALUE count!\n";
        return;
    }

    for ( my $i = 1; $i <= $tag_count; $i++ ) {
        push @tags,   $tag_hashref->{$i}{data};
        push @values, $value_hashref->{$i}{data};
    }

    return ( \@tags, \@values );
}

##########################################################
# This method is to locate the pattern in the array and return the index of the pattern
#
# input:
#        -pattern => the pattern
#		 -array_ref => the array reference
#
# output:
#		the array index of the pattern if found; -1 if not found
#
# example:
#		my $pos = $data_submission->get_index( -pattern=>$pattern, -array_ref=>$array_ref );
#
############################
sub get_index {
    my $self      = shift;
    my %args      = @_;
    my $pattern   = $args{-pattern};
    my $array_ref = $args{-array_ref};

    for ( my $i = 0; $i < @$array_ref; $i++ ) {
        return $i if ( $array_ref->[$i] =~ /^$pattern$/ );
    }

    return -1;
}

##########################################################
# This method is to walk through the xml tree and remove the nodes that do not have data
#
# input:
#        -tree => the xml tree
#
# output:
#		none
#
# example:
#		$data_submission->suppress_no_data( -tree=>$tree );
#
############################
sub suppress_no_data {
    my $self = shift;
    my %args = @_;
    my $tree = $args{-tree};

    my $nodes_removed;

    do {
        $nodes_removed = 0;
        my $current = $tree->get_root();
        while ( $tree->is_valid( -node => $current ) ) {
            my $child = $tree->get_first_child( -node => $current );
            if ( $tree->is_valid( -node => $child ) ) {
                $current = $tree->get_next_node( -current => $current );
                next;
            }

            ## no children
            ## check text
            if ( $tree->get_text( -node => $current ) ) {    ## it has text
                $current = $tree->get_next_node( -current => $current );
                next;
            }

            ## no text, check attributes
            my $has_attribute = 0;
            my $attrs = $tree->get_attribute( -node => $current );
            foreach my $attr ( keys %$attrs ) {
                if ( defined $attrs->{$attr} and $attrs->{$attr} ne '' ) {
                    $has_attribute = 1;
                    last;
                }
            }
            if ($has_attribute) {
                $current = $tree->get_next_node( -current => $current );
                next;
            }
            else {
                ## no text, no attribute, should be suppressed
                if ( $self->is_TAG( -tree => $tree, -node => $current ) ) {
                    my $parent   = $tree->get_parent( -node       => $current );
                    my $tag_node = $tree->get_first_child( -node  => $parent );
                    my $next     = $tree->get_next_node( -current => $parent );
                    $tree->remove( -node => $current );
                    $nodes_removed++;
                    $tree->remove( -node => $tag_node );
                    $nodes_removed++;
                    $tree->remove( -node => $parent );
                    $nodes_removed++;
                    $current = $next;
                }
                else {
                    my $next = $tree->get_next_node( -current => $current );
                    $tree->remove( -node => $current );
                    $nodes_removed++;
                    $current = $next;
                }
            }
        }
    } while ($nodes_removed);
}

##########################################################
# This method is to check if the given node belongs to TAG/VALUE pair
#
# input:
#        -tree => the xml tree
#		 -node => the xml tree node id
#
# output:
#		1 if the given node is part of TAG/VALUE pair
#		0 if not.
#
# example:
#		$data_submission->is_TAG( -tree=>$tree, -node=>$node );
#
############################
sub is_TAG {
    my $self = shift;
    my %args = @_;
    my $tree = $args{-tree};
    my $node = $args{-node};

    return 0 if ( !( $tree->is_valid( -node => $node ) ) );

    my $parent = $tree->get_parent( -node => $node );
    return 0 if ( !( $tree->is_valid( -node => $parent ) ) );

    my $first_child = $tree->get_first_child( -node => $parent );
    return 0 if ( !( $tree->is_valid( -node => $first_child ) ) );

    my $next = $tree->get_next( -node => $first_child );
    return 0 if ( !( $tree->is_valid( -node => $next ) ) );

    my $first_element_name  = $tree->get_name( -node => $first_child );
    my $second_element_name = $tree->get_name( -node => $next );
    if ( $first_element_name =~ /\.TAG$/ && $second_element_name =~ /\.VALUE$/ ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub create_manifest {
    my $self        = shift;
    my %args        = filter_input( \@_, -args => 'dbc,path,type,run_dirs', -mandatory => 'dbc,path,type' );
    my $dbc         = $args{-dbc};
    my $type        = $args{-type};
    my $path        = $args{-path};
    my $target      = $args{-target};
    my $volume_name = $args{-volume_name};
    my $protected   = $args{-protected};

    if ( $type eq 'meta' ) {
        ## under construction
        my @meta_types;
        push @meta_types, ('study') if ( $target !~ /edacc/i );
        push @meta_types, ( 'sample', 'experiment', 'run' );
        print "target=" . $target . "\n";
        my $manifest_file = $path . '/' . 'MANIFEST';
        open OUT, ">$manifest_file" || die "Could not open $manifest_file for writing: $!\n";
        foreach my $meta_type (@meta_types) {
            my $file = $meta_type . "." . $volume_name . ".xml";
            print OUT "$file\t" . uc($meta_type) . "\n" if ( -e "$path/$file" );
        }
        close(OUT);
        Message("$manifest_file has been created successfully!\n");
        return $manifest_file;
    }
    elsif ( $type eq 'run' ) {
        my @runs          = @{ $args{-runs} };
        my $manifest_file = $path . '/' . 'MANIFEST';
        open OUT, ">$manifest_file" || die "Could not open $manifest_file for writing: $!\n";
        if ( !$protected ) {
            foreach my $run (@runs) {
                my ($lane) = $dbc->Table_find( 'SolexaRun', 'Lane', "WHERE FK_Run__ID = $run" );
                my $srf_file_name = "Run" . $run . "Lane" . $lane . ".srf";
                print OUT "$srf_file_name\tSRF\n";
            }
        }
        ## create an empty MANIFEST file if protected
        Message("Protected data! No SRF file was listed in the MANIFEST!\n") if ($protected);
        close(OUT);
        Message("$manifest_file has been created successfully!\n");
        return $manifest_file;
    }
}

sub create_bundle {
    my $self = shift;
    my %args = filter_input(
         \@_,
        -args      => 'dbc,path,type,run_dirs,use_cluster',
        -mandatory => 'dbc,path,type'
    );
    my $dbc         = $args{-dbc};
    my $type        = $args{-type};
    my $path        = $args{-path};
    my $volume_name = $args{-volume_name};
    my $cluster     = $args{-use_cluster};
    my $target      = $args{-target};
    my $protected   = $args{-protected};

    if ( !-d $path ) {
        print "ERROR: Directory $path does not exist!\n";
        return 0;
    }

    my $bundle_path;
    my @files;

    if ( $type eq 'meta' ) {
        $bundle_path = $path;
        my $manifest_created = $self->create_manifest(
            -dbc         => $dbc,
            -path        => $bundle_path,
            -type        => $type,
            -target      => $target,
            -volume_name => $volume_name
        );
        if ( !$manifest_created ) {
            print "ERROR: Failed creating MANIFEST!\n";
            return 0;
        }

        push @files, 'MANIFEST';
        open IN, "$manifest_created" || die "Couldn't open $manifest_created for reading: $!\n";
        while (<IN>) {
            my $line = $_;
            chomp($line);
            my ( $file_name, $file_type ) = split /\t/, $line;
            my $file_full_name = $bundle_path . '/' . $file_name;
            if ( !-e $file_full_name ) {
                print "ERROR: $file_full_name does not exist!\n";
                return 0;
            }
            push @files, $file_name;
        }
        close(IN);
    }
    elsif ( $type eq 'run' ) {
        my @runs = @{ $args{-runs} };

        #$bundle_path = $path . '/' . $volume_name;
        $bundle_path = $path . '/' . $volume_name;
        if ( !-d $bundle_path ) {
            my $command = "mkdir $bundle_path";
            my ( $stdout, $stderr ) = try_system_command( -command => $command );
            if ($stderr) {
                print "ERROR occurred while running $command: $stderr\n";
                print "Aborted!\n";
                return 0;
            }
        }

        my $manifest_created = $self->create_manifest(
            -dbc         => $dbc,
            -path        => $bundle_path,
            -type        => $type,
            -target      => $target,
            -volume_name => $volume_name,
            -runs        => \@runs,
            -protected   => $protected
        );
        if ( !$manifest_created ) {
            print "ERROR: Failed creating MANIFEST!\n";
            return 0;
        }

        push @files, 'MANIFEST';
        foreach my $run (@runs) {
            my ($lane) = $dbc->Table_find( 'SolexaRun', 'Lane', "WHERE FK_Run__ID = $run" );
            my $srf_name = "Run" . $run . "Lane" . $lane . ".srf";
            my $srf_file = $bundle_path . '/' . $srf_name;
            if ( !-e $srf_file ) {
                my $from    = $path . '/' . 'Run' . $run . '/' . $srf_name;
                my $command = "mv $from $srf_file";
                print "Running $command ...\n";
                my ( $stdout, $stderr ) = try_system_command($command);
                if ($stderr) {
                    print "ERROR occurred while running $command: $stderr\n";
                    print "Aborted!\n";
                    return 0;
                }
            }
            push @files, $srf_name;
        }
    }

    #my $today = today();
    my $tar_file;
    my $tar_file_incomplete;
    my $branch;
    if ( $type eq 'meta' ) {    # EDACC does not take .tar.bz2 files in meta data submission
        $branch              = '_meta';
        $tar_file            = 'BCCAGSC_' . $volume_name . $branch . '.tar.gz';
        $tar_file_incomplete = 'BCCAGSC_' . $volume_name . $branch . '.tar.gz.incomplete';
    }
    elsif ( $type eq 'run' ) {
        $branch              = '_srf';
        $tar_file            = 'BCCAGSC_' . $volume_name . $branch . '.tar.bz2';
        $tar_file_incomplete = 'BCCAGSC_' . $volume_name . $branch . '.tar.bz2.incomplete';
    }
    my $file_list = join ' ', @files;
    my $commands;
    $commands .= "cd $bundle_path\n";
    if ( $type eq 'meta' ) {
        $commands .= "tar cvfz $tar_file_incomplete $file_list\n";
    }
    else {
        $commands .= "tar cvfj $tar_file_incomplete $file_list\n";
    }
    $commands .= "mv $tar_file_incomplete $tar_file\n";

    #my $job_name = 'Bundle_' . $volume_name;
    my $job_name = 'Bundle_' . $volume_name;
    my $job_file = $job_name . '.sh';

    $self->create_job_file(
        -contents  => $commands,
        -path      => $bundle_path,
        -file_name => $job_file
    );

    if ($cluster) {    ## submit to cluster
        new Cluster::Cluster()->submit_to_queue(
            -job_name    => "$job_name",
            -host        => 'm0001',
            -queue       => 'flow7.q',
            -std_out_dir => $bundle_path,
            -std_err_dir => $bundle_path,
            -job_file    => "$bundle_path/$job_file",
            -job_type    => 'SRF',
        );
    }
    else {
        if ( -e "$bundle_path/$job_file" ) {
            my $command = "/bin/bash $bundle_path/$job_file";
            print "Running $command ...\n";
            try_system_command( -command => $command );
        }
    }

    return 1;

}

#############################
sub create_job_file {
#############################
    my $self      = shift;
    my %args      = @_;
    my $contents  = $args{-contents};
    my $file_name = $args{-file_name};
    my $path      = $args{-path};

    my $created = 0;

    $self->log("Writing log file to $path/$file_name");

    if ( $self->{testing} ) {
        $self->log("** Testing job file creation:");

        $self->log("Contents of file:");
        $self->log("$contents");
        return 1;
    }

    open my $OUT, '>', "$path/$file_name" || return ( 0, '', "Can't open $path/$file_name\n" );
    print $OUT "#!/bin/bash \n #\$ -S /bin/bash \n";

    #print $OUT "source /home/aldente/gap_profile.sh\n";
    print $OUT "$contents";
    close $OUT;
    if ( -e "$path/$file_name" ) {
        $created = 1;
        $self->log("Wrote log file to $path/$file_name");
    }

    return $created;
}

#########
sub log {
########
    my $self = shift;
    my %args = filter_input( \@_, -args => 'log' );
    my $log  = $args{ -log };

    push @{ $self->{log} }, $log;
    my $timestamp = &date_time();
    print "$timestamp: $log\n";
    return;
}

##########################################################
# This method returns the default data submission request dir
##########################################################
sub get_request_dir {
    return $Configs{data_submission_request_dir};
}

##########################################################
# This method is to retrieve data submission requests
#
# input:
#       -path [path] => the path with request files. Default is the directory returned by request_dir().
#		-required_fields [array reference] =>  the required fields to generate submission
#
# output:
#       format - hash reference
#		returns the requests. For each successful request, a record will be inserted to table Submission_Volume if -update is used.
#
# example:
#		my $requests_href = $obj->get_requests( -path=>"/home/aldente/blabla", -required_fields=>['scope','config','library'] );
#		my $requests_href = $obj->get_requests( -required_fields=>['scope','config','library'] );
#
##########################################################
sub get_requests {
    my $self            = shift;
    my %args            = &filter_input( \@_, -args => 'path,required_fields' );
    my $request_path    = $args{-path} || $self->get_request_dir();
    my @required_params = @{ $args{-required_fields} };
    my $test            = $args{-test};

    my @success;
    my @fail;

    opendir DIR, $request_path;
    my @names = readdir DIR;
    foreach my $name (@names) {
        if ( $name =~ /^request\.([^.]+)\.([^.]+)/ ) {
            my $full_name    = $request_path . "/$name";
            my $request_name = $1;
            my $request_time = $2;
            my $ok           = open IN, "$full_name";
            if ( !$ok ) {
                warn "Could not open $full_name: $!\n";
                next;
            }
            my %params;
            while (<IN>) {
                my $line = $_;
                chomp($line);
                if ( $line =~ /^(\w+)\s*=\s*(.+)/ ) {
                    my $key   = $1;
                    my $value = $2;
                    $params{$key} = $value;
                }
            }
            close(IN);

            my @missing;
            foreach my $key (@required_params) {
                if ( !defined $params{$key} ) {
                    push @missing, $key;
                }
            }
            my $fail = @missing;

            my %return;
            $return{name}     = $request_name;
            $return{datetime} = $request_time;
            $return{params}   = \%params;

            ## log the request
            my $log_file = "$request_path/processed/$name" . ".log";
            my $log      = '';
            my $datetime = date_time();
            $log .= "################## log start ###################\n";
            $log .= "Request was processed on $datetime\n";
            $log .= "Process status: ";
            if ($fail) {
                my $missing_list = join ',', @missing;
                $log .= "ERROR - $fail required fields are missing ($missing_list)";
                $return{reason}   = "ERROR - $fail required fields are missing ($missing_list)";
                $return{log_file} = $log_file;
                push @fail, \%return;
            }
            else {
                $log .= "SUCCESS";
                $return{log_file} = $log_file;
                push @success, \%return;
            }
            $log .= "\n";
            print "Logging to $full_name\n";
            open LOG, ">>$full_name";
            print LOG $log;
            close(LOG);

            #=begin
            if ( !$test ) {
                my $command = "mv $full_name $log_file -f";
                print "Running command $command\n";
                my ( $out, $err ) = try_system_command( -command => $command );
                print $out if ($out);
                print $err if ($err);
            }

            #=cut
        }
    }

    my %hash;
    $hash{success} = \@success;
    $hash{fail}    = \@fail;
    return \%hash;
}

sub retrieve_data {
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $dbc          = $self->{dbc};
    my $scope        = $args{-scope};
    my $object       = $args{-object};
    my $API_argument = $args{-API_argument};
    my $key_aref     = $args{-record_keys};
    my $study_name   = $args{-study_name};

    my $type = '';
    $type = $args{-type} if $args{-type};

    my @values;
    my $user_input;
    my $function_input;
    my $custom;
    if ( defined $object && defined $object->{user_input} ) {
        $user_input = scalar( @{ $object->{user_input} } );
    }
    if ( defined $object && defined $object->{function_input} ) {
        $function_input = scalar( @{ $object->{function_input} } );
    }
    $custom = 1 if ( defined $object && defined $object->{custom} );

    #if( grep /^get_number_of_reads_and_data_block_name$/, @{ $object->{function_input}} ) {
    #	$API_argument->{-fields} .= ",flowcell_code,lane";
    #};

    my $data;
    my $fields_count = @{ $API_argument->{-fields} };

    if ( $fields_count > 0 ) {
        my $API;
        my $module;
        if ( $scope =~ /solexa/i ) {
            $API    = "Illumina::Solexa_API";
            $module = 'Solexa_API';
        }
        elsif ( $scope =~ /aldente/i ) {
            $API    = "alDente::alDente_API";
            $module = 'alDente::alDente_API';
        }
        elsif ( $scope =~ /sequencing/i ) {
            $API    = "Sequencing::Sequencing_API";
            $module = 'Sequencing_API';
        }
        elsif ( $scope =~ /454/ ) {
            $API    = "LS_454::LS_454_API";
            $module = 'LS_454::LS_454_API';
        }
        eval "require $API";
        my $Plugin_API = $module->new( -dbc => $dbc, -quiet => 1 );
        $data = $Plugin_API->get_Atomic_data(%$API_argument);

        #print Dumper $data;
        #exit;
    }

    my %static_values;

    if ($data) {
        my $keys_count = keys %$data;
        foreach my $key ( sort keys %$data ) {

            next if ( !$key );
            ## get user input
            if ($user_input) {
                my $values_ref = $self->get_user_input(
                    -fields        => $object->{user_input},
                    -static_values => \%static_values,
                    -study_name    => $study_name,
                    -repeat        => $keys_count,
                    -key           => $key
                );
                foreach my $name ( keys %{$values_ref} ) {
                    $data->{$key}{$name} = $values_ref->{$name};
                }
            }

            ## get data from functions
            my %data_hash = %{ $data->{$key} };
            if ($function_input) {
                my $values_ref = $self->get_function_input(
                    -dbc    => $dbc,
                    -fields => $object->{function_input},
                    -data   => $data->{$key}
                );
                foreach my $name ( keys %{$values_ref} ) {
                    $data->{$key}{$name} = $values_ref->{$name};
                }
            }

            # get custom user input and function input
            if ($custom) {
                foreach my $element ( keys %{ $object->{custom} } ) {
                    my $field_name            = $object->{alia}{$element};
                    my $value                 = $data->{$key}{$field_name};
                    my $custom_user_input     = $object->{custom}{$element}{$value}{user_input};
                    my $custom_function_input = $object->{custom}{$element}{$value}{function_input};
                    if ($custom_user_input) {
                        my $values_ref = $self->get_user_input(
                            -fields        => $custom_user_input,
                            -static_values => \%static_values,
                            -study_name    => $study_name,
                            -repeat        => $keys_count,
                            -key           => $key
                        );
                        foreach my $name ( keys %{$values_ref} ) {
                            $data->{$key}{$name} = $values_ref->{$name};
                        }
                    }
                    if ($custom_function_input) {
                        my $values_ref = $self->get_function_input(
                            -dbc    => $dbc,
                            -fields => $custom_function_input,
                            -data   => $data->{$key}
                        );
                        foreach my $name ( keys %{$values_ref} ) {
                            $data->{$key}{$name} = $values_ref->{$name};
                        }
                    }
                }
            }

            push @values, $data->{$key};
            push @$key_aref, $key if ($key_aref);
        }

        #print "values DUMP:\n";
        #print Dumper \@values;
        #exit;
    }
    else {
        my %data_hash;
        ## get user input
        if ($user_input) {
            my $values_ref = $self->get_user_input(
                -fields        => $object->{user_input},
                -static_values => \%static_values,
                -study_name    => $study_name
            );
            foreach my $name ( keys %{$values_ref} ) {
                $data_hash{$name} = $values_ref->{$name};
            }
        }

        ## get data from functions
        if ($function_input) {
            my $values_ref = $self->get_function_input(
                -dbc    => $dbc,
                -fields => $object->{function_input},
                -data   => \%data_hash
            );
            foreach my $name ( keys %{$values_ref} ) {
                $data_hash{$name} = $values_ref->{$name};
            }
        }

        push @values, \%data_hash;
    }

    return \@values;
}

sub get_user_input {
    my $self          = shift;
    my %args          = &filter_input( \@_ );
    my $fields        = $args{-fields};
    my $static_values = $args{-static_values};
    my $study_name    = $args{-study_name};
    my $repeat        = $args{-repeat};
    my $key           = $args{-key};

    my %result;
    my @need_input = ();
    foreach my $name (@$fields) {
        if ( $name eq 'STUDY_refname' ) {
            $result{$name} = $study_name;    #TEMP
        }
        elsif ( defined $static_values->{$name} ) {    # static input
            $result{$name} = $static_values->{$name};
        }
        else {
            push @need_input, $name;
        }
    }

    my $need_input_count = @need_input;
    if ($need_input_count) {

        #print "The following $need_input_count items are required for generating $type submission for $key. Please enter values for them:\n";
        print "The following $need_input_count items require input values";
        print " for key ( $key )" if ($key);
        print ". Please enter values for them:\n";
        foreach my $name (@need_input) {
            my $input = Prompt_Input( -prompt => "$name" );

            #print "$name: ";
            #my $input;
            #chomp( $input = <STDIN> );
            $result{$name} = $input;
            if ( $repeat > 1 ) {
                my $answer;
                do {
                    $answer = lc( Prompt_Input( -prompt => "Apply this value to all \"$name\" field? (Y/N)" ) );
                } while ( $answer ne 'y' && $answer ne 'n' );
                if ( $answer eq 'y' ) {
                    $static_values->{$name} = $input;
                }
            }
        }
        print "\n";

    }

    return \%result;
}

sub get_function_input {
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $fields = $args{-fields};
    my $data   = $args{-data};

    my %data_hash = %$data;
    my %result;
    foreach my $name (@$fields) {

        #print "getting function input for $name=[";
        if ( $name =~ /(\w+)\s*\(([^)]*)\s*\)\s*(AS\s+([\w.`]+))?\s*$/ ) {    # defined alias
            my $function_name      = $1;
            my $function_arguments = $2;
            my $alias              = $4;
            $alias = $name if ( !$alias );

            #print "function_name=[$function_name]\n";
            my %func_args = (
                '-API_data'  => \%data_hash,
                '-func_args' => $function_arguments,
                '-dbc'       => $dbc,
            );
            my $value = eval "alDente::Data_Submission_Customized_Functions::$function_name(\%func_args)";

            #print "value = [$value]\n";
            if ($value) {
                $value = $self->substitute( -str => $value, -replace => ',', -by => ',,' );    # replace unescaped comma with double comma
                $value =~ s|\\,|,|g;                                                           # remove the leading '\' for escaped comma
            }
            $result{$alias} = $value;
        }
        else {
            my $value = eval "alDente::Data_Submission_Customized_Functions::$name(\%data_hash)";
            if ($value) {

                #$value =~ s|,|,,|g;
                $value = $self->substitute( -str => $value, -replace => ',', -by => ',,' );    # replace unescaped comma with double comma
                $value =~ s|\\,|,|g;                                                           # remove the leading '\' for escaped comma
            }
            $result{$name} = $value;
        }

        #print "$value]\n";
    }

    return \%result;
}

sub substitute {
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $str     = $args{-str};
    my $replace = $args{-replace};        # char
    my $by      = $args{-by};             # string

    my @arr     = split //, $str;
    my $current = '';
    my $pre     = '';
    my $new_str = '';
    foreach my $char (@arr) {
        if ( $char eq $replace ) {
            if ( $pre eq '\\' ) {
                $new_str .= $char;
            }
            else {
                $new_str .= $by;
            }

        }
        else {
            $new_str .= $char;
        }
        $pre = $char;
    }
    return $new_str;
}

# Get available submission volume statuses
#
# Example:
# <snip>
#     my $volume_statuses= $data_submission_obj->get_volume_status_list();
# </snip>
# Returns: arrayref of submission volume statuses
#####################################
sub get_volume_status_list {
#####################################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => '' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my @status_lists = $dbc->Table_find(
        -table     => "Submission_Volume,Status",
        -fields    => "Status_Name",
        -condition => "WHERE Submission_Volume.FK_Status__ID = Status_ID and Status_Type = 'Submission'",
        -distinct  => '1',
    );

    return \@status_lists;
}

# Get submission volumes
#
# Example:
# <snip>
#     my $volumes = $data_submission_obj->get_volumes( -dbc=>$dbc, -volume_status=>'Accepted', -run_status=>'Bundled' );
# </snip>
# Returns: array of submission volume ids
#####################################
sub get_volumes {
#####################################
    my $self          = shift;
    my %args          = &filter_input( \@_, -args => 'dbc,volume_status,run_status', -mandatory => '' );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $Run_status    = $args{-run_status};
    my $Volume_status = $args{-volume_status};

    my $tables     = "Submission_Volume,Status";
    my $conditions = "WHERE Status_ID = Submission_Volume.FK_Status__ID and Status_Type = 'Submission'";
    if ($Volume_status) {
        my $Volume_status_list = Cast_List( -list => $Volume_status, -to => 'string', -autoquote => 1 );
        $tables     .= ",Status as Volume_Status";
        $conditions .= " and Submission_Volume.FK_Status__ID = Volume_Status.Status_ID and Volume_Status.Status_Type = 'Submission' and Volume_Status.Status_Name in ($Volume_status_list) ";
    }
    if ($Run_status) {
        my $Run_status_list = Cast_List( -list => $Run_status, -to => 'string', -autoquote => 1 );
        $tables .= " LEFT JOIN Trace_Submission on Trace_Submission.FK_Submission_Volume__ID = Submission_Volume_ID LEFT JOIN Status as Trace_Status ON Trace_Submission.FK_Status__ID = Trace_Status.Status_ID and Trace_Status.Status_Type = 'Submission'";
        $conditions .= " and Trace_Status.Status_Name in ($Run_status_list) ";
    }

    #my @Submission_Volume_ids = ();
    my @Submission_Volume_ids = $dbc->Table_find(
        -table     => $tables,
        -fields    => 'Submission_Volume_ID',
        -condition => $conditions,
        -distinct  => '1'
    );
    return \@Submission_Volume_ids;
}

# Get available run data submission statuses
#
# Example:
# <snip>
#     my $run_statuses= $data_submission_obj->get_run_status_list();
# </snip>
# Returns: arrayref of run data submission statuses
#####################################
sub get_run_data_status_list {
#####################################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => '' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my @status_lists = $dbc->Table_find(
        -table     => "Trace_Submission,Status",
        -fields    => "Status_Name",
        -condition => "WHERE Trace_Submission.FK_Status__ID = Status_ID and Status_Type = 'Submission'",
        -distinct  => '1'
    );

    return \@status_lists;
}

# Get available target organization
#
# Example:
# <snip>
#     my $org = $data_submission_obj->get_target_organization_list();
# </snip>
# Returns: arrayref of target organizations
#####################################
sub get_target_organization_list {
#####################################
    my $self = shift;

    my @org_lists = ();
    @org_lists = $self->{dbc}->Table_find(
        -table     => 'Submission_Volume,Organization',
        -fields    => 'Organization_Name',
        -condition => "WHERE FK_Organization__ID = Organization_ID",
        -distinct  => '1'
    );
    return \@org_lists;

}

sub get_template_info {
    my $self          = shift;
    my %args          = &filter_input( \@_ );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $template_name = $args{-name};
    my $template_id   = $args{-id};

    my @fields = ( 'Submission_Template_ID', 'Template_Name', 'Version', 'Effective_Date', 'Organization', 'Template_Dir', );

    my $condition = "WHERE 1 ";
    if ( defined $template_id ) {
        $condition .= " and Submission_Template_ID = $template_id ";
    }
    elsif ( defined $template_name ) {
        $condition .= " and Template_Name = '$template_name' ";
    }

    my %template_info = $dbc->Table_retrieve(
        -table     => 'Submission_Template',
        -fields    => \@fields,
        -condition => $condition,
    );

    my %return;
    if ( defined $template_info{Submission_Template_ID}[0] ) {
        $return{Submission_Template_ID} = $template_info{Submission_Template_ID}[0];
        $return{Template_Name}          = $template_info{Template_Name}[0];
        $return{Version}                = $template_info{Version}[0];
        $return{Effective_Date}         = $template_info{Effective_Date}[0];
        $return{Organization}           = $template_info{Organization}[0];
        $return{Template_Dir}           = $template_info{Template_Dir}[0];
    }

    return \%return;
}

#######################
# Retrieve submission volume name
#
# Usage:	my $name = $get_volume_name( -volume_id => $id );
#
# Return:	Scalar, volume name
######################
sub get_volume_name {
######################
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => 'volume_id', -mandatory => 'volume_id' );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $volume_id = $args{-volume_id};

    my ($name) = $dbc->Table_find(
        -table     => 'Submission_Volume',
        -fields    => 'Volume_Name',
        -condition => "WHERE Submission_Volume_ID = $volume_id",
        -distinct  => 1,
    );
    return $name;
}

#######################
# Retrieve submission volume target organization name
#
# Usage:	my $name = $get_volume_target( -volume_id => $id );
#
# Return:	Scalar, organization name
######################
sub get_volume_target {
######################
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => 'volume_id', -mandatory => 'volume_id' );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $volume_id = $args{-volume_id};

    my ($target) = $dbc->Table_find(
        -table     => 'Submission_Volume,Organization',
        -fields    => 'Organization_Name',
        -condition => "WHERE Submission_Volume_ID = $volume_id and FK_Organization__ID = Organization_ID",
        -distinct  => 1,
    );
    return $target;
}

#######################
# Retrieve submission type
#
# Usage:	my $type = $get_submission_type( -volume_id => $id );
# 			my $type = $get_submission_type( -volume_name => $name );
#
# Return:	Scalar, the submission type
######################
sub get_submission_type {
######################
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => 'volume_id,volume_name', -mandatory => '' );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $volume_id   = $args{-volume_id};
    my $volume_name = $args{-volume_name};

    my $conditions = "WHERE 1 ";
    if ($volume_id) {
        $conditions .= " and Submission_Volume_ID = $volume_id";
    }
    elsif ($volume_name) {
        $conditions .= " and Volume_Name = '$volume_name'";
    }
    my ($type) = $dbc->Table_find(
        -table     => 'Submission_Volume',
        -fields    => 'Submission_Type',
        -condition => $conditions,
        -distinct  => 1,
    );
    return $type;
}

sub validate_xml {
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $volume_name = $args{-name};
    my $volume_id   = $args{-id};

}

sub get_valid_target_organizations {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};

    my @org = $dbc->Table_find(
        -table     => 'Organization',
        -fields    => 'Organization_Name',
        -condition => "WHERE Organization_Type = 'Data Repository'",
        -distinct  => 1,
    );
    return \@org;
}

sub get_valid_templates {
    my $self = shift;
    my %args = &filter_input( \@_ );

    my @templates = $self->{dbc}->Table_find(
        -table     => 'Submission_Template',
        -fields    => 'Template_Name',
        -condition => "WHERE 1",
        -distinct  => '1'
    );
    return \@templates;
}

# Get the run ids and volume ids of the specified submission volume and/or with the specified run submission status
#
# Example:
# <snip>
#     my @runs = $data_submission_obj->get_submission_runs( -dbc=>$dbc, -volume_id=>$volume_id );
#     my @runs = $data_submission_obj->get_submission_runs( -dbc=>$dbc, -run_status=>"In Process" );
# </snip>
# Returns: array. Each element of the array is a hash reference to the hash with two keys 'run' and 'volume_id'
#####################################
sub get_submission_runs {
#####################################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $volume_id  = $args{-volume_id};
    my $run_status = $args{-run_status};

    my $condition = "WHERE 1 ";
    $condition .= " and FK_Submission_Volume__ID = $volume_id " if ($volume_id);
    $condition .= " and Submission_Status = '$run_status' "     if ($run_status);

    my %runs = $self->{dbc}->Table_retrieve(
        -table     => 'Trace_Submission',
        -fields    => [ 'FK_Run__ID', 'FK_Submission_Volume__ID' ],
        -condition => $condition,
        -distinct  => '1'
    );

    my @return;
    my $index = 0;
    while ( defined $runs{FK_Run__ID}[$index] ) {
        push @return,
            {
            'run'       => $runs{FK_Run__ID}[$index],
            'volume_id' => $runs{FK_Submission_Volume__ID}[$index]
            };
        $index++;
    }
    return @return;
}

# Get the run ids of the specified submission volume and run submission status
#
# Example:
# <snip>
#     my @runs = $data_submission_obj->get_runs( -dbc=>$dbc, -volume_id=>$volume_id );
#     my @runs = $data_submission_obj->get_runs( -dbc=>$dbc, -volume_name=>$volume_name );
#     my @runs = $data_submission_obj->get_runs( -dbc=>$dbc, -volume_id=>$volume_id, -run_status=>"In Process" );
# </snip>
# Returns: array of run ids.
#####################################
sub get_runs {
#####################################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbc,volume_id,volume_name,run_status', -mandatory => '' );
    my $dbc  = $args{-dbc} || $self->{dbc};

    #my $volume_id   = $args{-volume_id};
    #my $volume_name = $args{-volume_name};
    my $run_status = $args{-run_status};

    my $volume_id = $self->{id};
    my $tables    = "Submission_Volume, Trace_Submission";
    my $condition = "WHERE FK_Submission_Volume__ID = Submission_Volume_ID ";
    if   ($volume_id)  { $condition .= " and Submission_Volume_ID = $volume_id " }
    if   ($run_status) { $condition .= " and Submission_Status = '$run_status' " }
    else               { $condition .= " and Submission_Status <> 'Aborted' " }      ## exclude the Aborted runs

    my @runs = $self->{dbc}->Table_find(
        -table     => $tables,
        -fields    => 'FK_Run__ID',
        -condition => $condition,
        -distinct  => '1'
    );

    return @runs;
}

# Get the run information of the specified Trace_Submission_ID or submission volume id
#
# Example:
# <snip>
#     my $run_info = $data_submission_obj->get_submission_run_info( -dbc=>$dbc, -trace_submission_id=>$id );
#     my $run_info = $data_submission_obj->get_submission_run_info( -dbc=>$dbc, -volume_id=>$id );
# </snip>
# Returns: hash reference
#####################################
sub get_submission_run_info {
#####################################
    my $self                = shift;
    my %args                = &filter_input( \@_ );
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $volume_id           = $args{-volume_id};
    my $trace_submission_id = $args{-trace_submission_id};

    my @fields = ( 'Trace_Submission_ID', 'Run_ID', 'Status_Name', 'FK_Sample__ID', 'Run_Directory', 'Run_DateTime', 'Lane', 'SolexaRun_Type', 'Flowcell_Code', );

    my $tables = "Trace_Submission,Run,Status ";
    $tables .= " LEFT JOIN SolexaRun ON SolexaRun.FK_Run__ID = Run_ID ";
    $tables .= " LEFT JOIN Flowcell ON FK_Flowcell__ID = Flowcell_ID ";
    my $condition = "WHERE 1 ";
    if ($trace_submission_id) {
        $condition .= " and Trace_Submission_ID = $trace_submission_id ";
    }
    if ($volume_id) {
        $condition .= " and FK_Submission_Volume__ID = $volume_id ";
    }
    $condition .= " and Trace_Submission.FK_Run__ID = Run_ID ";
    $condition .= " and Trace_Submission.FK_Status__ID = Status_ID and Status_Type = 'Submission'";

    my %run_info = $dbc->Table_retrieve(
        -table     => $tables,
        -fields    => \@fields,
        -condition => $condition
    );
    my %return;
    my $index = 0;
    while ( defined $run_info{Trace_Submission_ID}[$index] ) {
        my $run_id = $run_info{Run_ID}[$index];
        $return{$run_id}{Trace_Submission_ID} = $run_info{Trace_Submission_ID}[$index];
        $return{$run_id}{Run_ID}              = $run_id;
        $return{$run_id}{Status_Name}         = $run_info{Status_Name}[$index];
        $return{$run_id}{Sample_ID}           = $run_info{FK_Sample__ID}[$index];
        $return{$run_id}{Run_Directory}       = $run_info{Run_Directory}[$index];
        $return{$run_id}{Run_DateTime}        = $run_info{Run_DateTime}[$index];
        $return{$run_id}{Lane}                = $run_info{Lane}[$index];
        $return{$run_id}{SolexaRun_Type}      = $run_info{SolexaRun_Type}[$index];
        $return{$run_id}{Flowcell}            = $run_info{Flowcell_Code}[$index];
        $index++;
    }

    return \%return;
}

#####################################################
# Get the run id of the specified Trace_Submission_ID
#
# Usage:	my $run_id = $data_submission_obj->get_submission_run_info( -trace_submission_id=>$id, -dbc => $dbc );
#
# Returns: Scalar, the FK_Run__ID
###################################
sub get_trace_submission_run {
###################################
    my $self                = shift;
    my %args                = &filter_input( \@_ );
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $trace_submission_id = $args{-trace_submission_id};

    my ($run) = $dbc->Table_find(
        -table     => 'Trace_Submission',
        -fields    => 'FK_Run__ID',
        -condition => "WHERE Trace_Submission_ID = $trace_submission_id",
    );
    return $run;
}

sub get_submission_status {
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => 'dbc,volume_id,run_id', -mandatory => 'run_id' ) or err ("Improper input");
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $volume_id = $args{-volume_id};
    my $run_id    = $args{-run_id};

    my $condition = "FK_Run__ID = $run_id ";
    $condition .= " and FK_Submission_Volume__ID = $volume_id" if ($volume_id);

    my @statuses = $dbc->Table_find(
        -table     => 'Trace_Submission',
        -fields    => 'Submission_Status',
        -condition => "WHERE 1 and $condition",
        -distinct  => 1,
    );

    my $return_str = join ',', @statuses;
    return $return_str;
}

sub create_srf {
    my $self        = shift;
    my %args        = &filter_input( \@_ );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $flowcell    = $args{-flowcell};
    my $lane        = $args{-lane};
    my $run         = $args{-run_id};
    my $data_dir    = $args{-data_dir};
    my $include_raw = $args{-include_raw};
    my $debug       = $args{-debug};

    my $srf_dir = $self->{'work_path'} . "/Run$run";
    if ( !-d $srf_dir ) {
        my $command = "mkdir $srf_dir";
        my ( $stdout, $stderr ) = try_system_command( -command => $command );
        print "$stdout" if ($debug);
        print "$stderr" if ($debug);
        if ($stderr) {
            print "ERROR when executing command $command\n";
            return 0;
        }
    }

    my $solexa_analysis_obj = Illumina::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $flowcell );
    $solexa_analysis_obj->create_srf(
        -run          => $run,
        -lane         => $lane,
        -seq_path     => "$data_dir",
        -job_path     => $srf_dir,
        -target_path  => $srf_dir,
        -dbc          => $dbc,
        -include_raw  => $include_raw,
        -uncompress   => '1',
        -use_pipeline => 0
    );
}

sub set_volume_status {
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $volume_id = $args{-volume_id};
    my $status    = $args{-status};
    my ($set_status) = $dbc->Table_find( 'Status', 'Status_ID', "WHERE Status_Name = '$status'" );
    my $num_records = $dbc->Table_update_array(
        -table     => 'Submission_Volume',
        -fields    => ['FK_Status__ID'],
        -values    => [$set_status],
        -condition => "WHERE Submission_Volume_ID = $volume_id",
    );
    if ($num_records) {
        Message("Submission Volume $volume_id volume status has been set to $status.\n");
        return 1;
    }
    else {
        Message("ERROR updating volume status for Submission Volume $volume_id!\n");
        return 0;
    }
}

# Set the Volume_Status for a specified submission volume
#
# Example:
# <snip>
#     my $ok = $data_submission_obj->set_volume_run_data_status( -dbc=>$dbc, -volume_id=>$volume_id, -status=>$status );
# </snip>
# Returns: 1 for success; 0 for fail
#####################################
sub set_volume_run_data_status {
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $volume_id = $args{-volume_id};
    my $status    = $args{-status};
    my ($set_status) = $dbc->Table_find( 'Status', 'Status_ID', "WHERE Status_Name = '$status' and Status_Type = 'Submission'" );
    my $num_records = $dbc->Table_update_array(
        -table     => 'Submission_Volume',
        -fields    => ['FK_Status__ID'],
        -values    => [$set_status],
        -condition => "WHERE Submission_Volume_ID = $volume_id",
    );
    if ($num_records) {
        Message("Submission Volume $volume_id run data status has been set to $status.\n");
        return 1;
    }
    else {
        Message("ERROR updating run data status for Submission Volume $volume_id!\n");
        return 0;
    }
}

# Set the Submission_Status for a specified run and submission volume
#
# Example:
# <snip>
#     my $ok = $data_submission_obj->set_run_data_status( -dbc=>$dbc, -volume_id=>$volume_id, -run_id=>$run_id, -status=>$status );
# </snip>
# Returns: 1 for success; 0 for fail
#####################################
sub set_run_data_status {
#####################################
    my $self                = shift;
    my %args                = &filter_input( \@_ );
    my $dbc                 = $args{-dbc} || $self->{dbc};
    my $trace_submission_id = $args{-trace_submission_id};
    my $volume_id           = $args{-volume_id};
    my $run_id              = $args{-run_id};
    my $status              = $args{-status};

    my $condition = "WHERE 1 ";
    my $input;
    if ($trace_submission_id) {
        $condition .= " and Trace_Submission_ID = $trace_submission_id ";
        $input = "Trace_Submission_ID $trace_submission_id";
    }
    else {
        $condition .= " and FK_Submission_Volume__ID = $volume_id and FK_Run__ID = $run_id ";
        $input = "Submission Volume $volume_id Run $run_id";
    }
    my $num_records = $dbc->Table_update_array(
        -table     => 'Trace_Submission',
        -fields    => ['Submission_Status'],
        -values    => ["'$status'"],
        -condition => $condition,
    );
    if ($num_records) {

        #Message( "Submission run data status for $input has been set to $status.\n" );
        return 1;
    }
    else {
        Message("ERROR updating Submission run data status for $input!\n");
        return 0;
    }
}

sub set_accession {
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $volume_id = $args{-volume_id};
    my $accession = $args{-accession};

    my $num_records = $dbc->Table_update_array(
        -table     => 'Submission_Volume',
        -fields    => ['SID'],
        -values    => ["'$accession'"],
        -condition => "WHERE Submission_Volume_ID = $volume_id",
    );
    if ($num_records) {
        Message("Successfully set Accession# $accession for ID $volume_id.\n");
        return 1;
    }
    else {
        Message("ERROR setting Accession# for ID $volume_id!\n");
        return 0;
    }

}

##################################
# Set the volume comments
#
# Usage:	my $ok = set_volume_comments( -comments => $comments );
#
# Return:	1 on success; 0 on failure
###############################
sub set_volume_comments {
########################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->{dbc};
    my $volume_id = $args{-volume_id};
    my $comments  = $args{-comments};

    my $num_records = $dbc->Table_update_array(
        -table     => 'Submission_Volume',
        -fields    => ['Volume_Comments'],
        -values    => ["'$comments'"],
        -condition => "WHERE Submission_Volume_ID = $volume_id",
    );
    if ($num_records) {
        Message("Successfully set Volume_Comments for ID $volume_id.\n");
        return 1;
    }
    else {
        Message("ERROR setting Volume_Comments for ID $volume_id!\n");
        return 0;
    }
}

#####################################
# Retrieve the submitted libraries
#
# Usage:	my @libraries = @{get_submitted_libraries( -volume_name => 'EZH2' )};
# 			my @libraries = @{get_submitted_libraries( -volume_id => 453 )};
# 			my @libraries = @{get_submitted_libraries()}; # get all submitted libraries
#
# Return:	Array ref
#####################################
sub get_submitted_libraries {
#####################################
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => 'dbc,volume_name,volume_id', -mandatory => '' );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $volume_id   = $args{-volume_id};
    my $volume_name = $args{-volume_name};

    my $conditions = "WHERE 1 ";
    if ($volume_id) {
        $conditions .= " and Submission_Volume_ID = $volume_id";
    }
    elsif ($volume_name) {
        $conditions .= " and Volume_Name = '$volume_name'";
    }
    $conditions .= " and FK_Submission_Volume__ID = Submission_Volume_ID and FK_Run__ID = Run_ID and FK_Plate__ID = Plate_ID";
    my @libraries = ();
    push @libraries,
        $dbc->Table_find(
        -table     => 'Submission_Volume,Trace_Submission,Run,Plate',
        -fields    => 'FK_Library__Name',
        -condition => $conditions,
        -distinct  => 1,
        );
    return \@libraries;
}

#####################################
# Save the specified submission conditions
#
# Usage:	my @libraries = @{save_submission_conditions( -volume_name => 'EZH2', -conditions => \%hash )};
#
# Return:	Hash ref, the new submission conditions
#####################################
sub save_submission_conditions {
#####################################
    my $self             = shift;
    my %args             = &filter_input( \@_, -args => 'dbc,volume_name,volume_id,conditions', -mandatory => 'conditions' );
    my $dbc              = $args{-dbc} || $self->{dbc};
    my $volume_id        = $args{-volume_id};
    my $volume_name      = $args{-volume_name};
    my $input_conditions = $args{-conditions};                                                                                  # hash ref

    my %submission_conditions = %{ $self->get_submission_conditions( -dbc => $dbc, -volume_name => $volume_name, -volume_id => $volume_id ) };
    foreach my $key ( keys %$input_conditions ) {
        $submission_conditions{$key} = $input_conditions->{$key};
    }

    my $condition_str = '';
    foreach my $key ( sort keys %submission_conditions ) {
        $condition_str .= "$key=$submission_conditions{$key} ";
    }

    my $conditions = "WHERE 1 ";
    if ( defined $volume_id ) {
        $conditions .= " and Submission_Volume_ID = $volume_id ";
    }
    elsif ( defined $volume_name ) {
        $conditions .= " and Volume_Name = '$volume_name' ";
    }
    my $num_records = $dbc->Table_update_array(
        -table     => 'Submission_Volume',
        -fields    => ['Submission_Condition'],
        -values    => ["'$condition_str'"],
        -condition => $conditions,
    );

    return \%submission_conditions;
}

#####################################
# Get the submission conditions.
# The submission conditions are stored in Submission_Volume.Submission_Condition in key=value format.
# This subroutine retrieves the submission conditions and returns them in hash format.
#
# Usage:	my %conditions = %{get_submission_conditions( -volume_name => 'EZH2' )};
#
# Return:	Hash ref
#####################################
sub get_submission_conditions {
    my $self        = shift;
    my %args        = &filter_input( \@_, -args => 'dbc,volume_name,volume_id', -mandatory => '' );
    my $dbc         = $args{-dbc} || $self->{dbc};
    my $volume_id   = $args{-volume_id};
    my $volume_name = $args{-volume_name};

    my $conditions = "WHERE 1 ";
    if ( defined $volume_id ) {
        $conditions .= " and Submission_Volume_ID = $volume_id ";
    }
    elsif ( defined $volume_name ) {
        $conditions .= " and Volume_Name = '$volume_name' ";
    }

    my ($submission_condition) = $dbc->Table_find(
        -table     => 'Submission_Volume',
        -fields    => 'Submission_Condition',
        -condition => $conditions,
        -distinct  => 1,
    );
    my %submission_conditions = ();
    if ( $submission_condition =~ /(\w+=[^;=]+;)+/ ) {
        my @items = split( ';', $submission_condition );
        foreach my $item (@items) {
            my ( $key, $value ) = split( '=', $item );
            $submission_conditions{$key} = $value;
        }
    }
    elsif ( $submission_condition =~ /([^\s=]+=[^\s=]+\s)+/ ) {
        my @items = split( ' ', $submission_condition );
        foreach my $item (@items) {
            my ( $key, $value ) = split( '=', $item );
            $submission_conditions{$key} = $value;
        }
    }
    return \%submission_conditions;
}

=begin
# Get fields that match a certain pattern
#
# <snip>
# Example:
#    my @fields = $dbc->get_fields(-table=>'Employee');
#    my @fields = $dbc->get_fields(-table=>'Employee',-like=>'%name%');
#    my @fields = $dbc->get_fields(-table=>'',-like=>'%Employee_Name%');
# </snip>
# Returns: array of fields matching specified pattern
#  (checks all tables if 2nd parameter is omitted)
#
##########################
sub _get_fields {
##########################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $dbc            = $args{-dbc} || $self->{dbc};
    my $input_tables   = $args{-table};                                                 # specify a particular table (optional)
    my $like           = $args{-like} || '%';                                           # set name query string (optional)
                                                                                        #my $dbfield_only    = $args{-all_fields};                                             # get only fields as defined in DBField table if possible
    my $include_hidden = defined $args{-include_hidden} ? $args{-include_hidden} : 1;
    my $output_mode    = $args{-output_mode} || 'prompt';

    my @tables;
    my $quoted_tables;
    my %aliases_of;

    if ($input_tables) {
        my @input_tables = Cast_List( -list => $input_tables, -to => 'array' );
        foreach my $input_table (@input_tables) {
            if ( $input_table =~ /(\w+)\s+AS\s+(\w+)/i ) {
                my $real_table = $1;
                my $alias      = $2;
                if ( defined( $aliases_of{$real_table} ) ) {
                    push @{ $aliases_of{$real_table} }, $alias;
                }
                else {
                    $aliases_of{$real_table} = [$alias];
                }
                push @tables, $real_table;
            }
            else {
                push @tables, $input_table;
            }
        }
        $quoted_tables = Cast_List( -to => 'string', -list => \@tables, -autoquote => 1 );
    }

    my @field_info;

    my $condition .= "WHERE Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'";
    if ($input_tables) {
        $condition .= " AND DBTable_Name in (" . $quoted_tables . ")";
    }
    if ($like) {
        $condition .= " AND Field_Name like '" . $like . "'";
    }
    if ( !$include_hidden ) {
        $condition .= " AND Field_Options NOT LIKE '%Hidden%'";
    }
    my $order = "Field_Order, Field_Name";

    my %DBField_info = $dbc->Table_retrieve(
        -table     => "DBField INNER JOIN DBTable ON DBTable.DBTable_ID = DBField.FK_DBTable__ID",
        -fields    => [ 'DBTable_Name', 'Field_Name', 'Field_Alias', 'Prompt' ],
        -condition => $condition,
    );

    my $info_length = scalar( @{ $DBField_info{Field_Name} } );
    my @returned_fields;
    for ( my $i = 0; $i < $info_length; $i++ ) {
        my $field_statement;

        my $table       = $DBField_info{DBTable_Name}[$i];
        my $field_alias = $DBField_info{Field_Alias}[$i] || $DBField_info{Prompt}[$i] || $DBField_info{Field_Name}[$i];
        my $field       = $DBField_info{Field_Name}[$i];

        if ( $output_mode eq 'prompt' ) {
            $field_statement = $table . "." . $field . " AS " . $field_alias;
        }
        elsif ( $output_mode eq 'qualified' ) {
            $field_statement = $table . "." . $field;
        }
        elsif ( $output_mode eq 'simple' ) {
            $field_statement = $table;
        }

        my $table_aliases = $aliases_of{ $DBField_info{DBTable_Name}[$i] };

        if ( defined($table_aliases) and ref($table_aliases) eq 'ARRAY' ) {
            foreach my $table_alias ( @{$table_aliases} ) {
                $field_statement =~ s/^$table/$table_alias/;
                $field_statement =~ s/AS\s+$field_alias$/AS ${table_alias}.${field_alias}/;
                push @returned_fields, $field_statement;
            }
        }
        else {
            push @returned_fields, $field_statement;
        }

    }

    return @returned_fields;
}
=cut

=begin

################################################################################
#
# Data_Submission_Customized_Functions package contains customized functions
# that can be used in data submission config files
#
################################################################################

package alDente::Data_Submission_Customized_Functions;

use Data::Dumper;
use strict;

use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;

use vars qw( %Configs );

sub current_xml_dateTime {

    my ( $sec, $min, $hour, $mday, $mon, $year ) = gmtime();

    my $nowtime = sprintf "%02d:%02d:%02d", $hour, $min, $sec;
    my $nowdate = sprintf "%04d-%02d-%02d", $year + 1900, $mon + 1, $mday;
    $nowdate =~ s/ /0/g;
    $nowtime =~ s/ /0/g;

    return $nowdate . "T" . $nowtime . "Z";

    #my $date_time = RGTools::RGIO::now();
    #$date_time =~ tr/ /T/;
    #$date_time .= 'Z';
    #return $date_time;
}

sub submission_concat {
    my %args      = @_;
    my %API_data  = %{ $args{-API_data} };
    my $func_args = $args{-func_args};
    my @strs      = split /\s*,\s*/, $func_args;

    my $escape = 1;

    #print "function arguments = $func_args\n";
    #print "after spliting:\n";
    #print Dumper \@strs;
    my $return_str = '';
    foreach my $str (@strs) {
        if ( $str =~ /^'(.*)'$/ ) {    # if it starts and ends with a quote character, treat it as a literal string
            $return_str .= $1;
        }
        elsif ( $str eq '-noescape' ) {    # the flag -noescape is passed in
            $escape = 0;
        }
        else {                             # get it from the API_data
            $return_str .= $API_data{$str};
        }
    }

    # escape the comma
    if ($escape) {
        $return_str =~ s|,|\\,|g;
    }

    #print "return string=$return_str\n";

    return $return_str;
}

sub get_version {
    my %args      = @_;
    my %API_data  = %{ $args{-API_data} };
    my $func_args = $args{-func_args};
    my @strs      = split /\s*,\s*/, $func_args;
    if (@strs) {
        my $name = shift @strs;
        if ( $name =~ /^'(.*)'$/ ) {    # if it starts and ends with a quote character, treat it as a literal string;
            $name = $1;
        }
        else {                          # otherwise, get it from the API_data
            $name = $API_data{$name};
        }
        foreach my $pattern (@strs) {
            if ( $pattern =~ /^'(.*)'$/ ) {    # if it starts and ends with a quote character, treat it as a literal string;
                $pattern = $1;
            }
            else {                             # otherwise, get it from the API_data
                $pattern = $API_data{$pattern};
            }

            if ( $name =~ /$pattern\s*(.*)/i ) {
                $name = $1;
            }
        }

        if ( $name =~ /\d+\.\d+(\.\d+)*/ ) {
            $name = $&;
        }

        return $name;
    }
}

sub get_program {
    my %args      = @_;
    my %API_data  = %{ $args{-API_data} };
    my $func_args = $args{-func_args};
    my @strs      = split /\s*,\s*/, $func_args;
    if (@strs) {
        my $name = shift @strs;
        if ( $name =~ /^'(.*)'$/ ) {    # if it starts and ends with a quote character, treat it as a literal string;
            $name = $1;
        }
        else {                          # otherwise, get it from the API_data
            $name = $API_data{$name};
        }
        foreach my $pattern (@strs) {
            if ( $pattern =~ /^'(.*)'$/ ) {    # if it starts and ends with a quote character, treat it as a literal string;
                $pattern = $1;
            }
            else {                             # otherwise, get it from the API_data
                $pattern = $API_data{$pattern};
            }

            if ( $name =~ /(.*?)\s*$pattern/i ) {
                $name = "$1 $pattern";
            }
        }

        return $name;
    }
}

sub submission_action {
    my %data = @_;
    if ( !defined $data{submission_volume_name} ) {
        print "Retrieve data ERROR: you must provide a submission name!\n";
        exit;
    }
    my $DATA_SUBMISSION_PATH = '/home/aldente/private/Submissions';
    my $path                 = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my @full_path_files;
    push @full_path_files, glob( "$path" . "*.xml" );
    my @return;
    foreach my $file (@full_path_files) {
        $file =~ /.*\/((?:\w+)(?:\.\w+)*.xml)/;
        push @return, 'ADD';
    }
    return join ',', @return;
}

sub submission_run_action {
    my %data                   = @_;
    my $submission_volume_name = $data{submission_volume_name};
    my $run_id                 = $data{run_id};
    my $DATA_SUBMISSION_PATH   = '/home/aldente/private/Submissions';

    #my $path = $DATA_SUBMISSION_PATH . "/created/" . $submission_volume_name;
    my $path          = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my $run_file_name = "run." . $submission_volume_name . ".run" . $run_id . ".xml";
    my @return        = ();
    if ( -e "$path/$run_file_name" ) {
        push @return, 'ADD';
    }
    return join ',', @return;
}

sub submission_add_source {
    my %data = @_;
    if ( !defined $data{submission_volume_name} ) {
        print "Retrieve data ERROR: you must provide a submission name!\n";
        exit;
    }
    my $DATA_SUBMISSION_PATH = '/home/aldente/private/Submissions';

    #my $path = $DATA_SUBMISSION_PATH . "/created/" . $data{submission_name} . '/';
    my $path = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my @full_path_files;
    push @full_path_files, glob( "$path" . "*.xml" );
    my @file_names;
    foreach my $file (@full_path_files) {

        #$file =~ /.*\/(\w+.xml)/;
        $file =~ /.*\/((?:\w+)(?:\.\w+)*.xml)/;
        push @file_names, $1;
    }
    return join ',', @file_names;
}

sub submission_run_add_source {
    my %data                   = @_;
    my $submission_volume_name = $data{submission_volume_name};
    my $run_id                 = $data{run_id};
    my $DATA_SUBMISSION_PATH   = '/home/aldente/private/Submissions';
    my $path                   = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my $run_file_name          = "run." . $submission_volume_name . ".run" . $run_id . ".xml";
    my @return                 = ();
    if ( -e "$path/$run_file_name" ) {
        push @return, $run_file_name;
    }
    return join ',', @return;
}

sub submission_run_add_schema {
    my %data                   = @_;
    my $submission_volume_name = $data{submission_volume_name};
    my $run_id                 = $data{run_id};
    my $DATA_SUBMISSION_PATH   = '/home/aldente/private/Submissions';
    my $path                   = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my $run_file_name          = "run." . $submission_volume_name . ".run" . $run_id . ".xml";
    my @return                 = ();
    if ( -e "$path/$run_file_name" ) {
        push @return, 'run';
    }
    return join ',', @return;
}

sub submission_add_schema {
    my %data = @_;
    if ( !defined $data{submission_volume_name} ) {
        print "Retrieve data ERROR: you must provide a submission name!\n";
        exit;
    }
    my $DATA_SUBMISSION_PATH = '/home/aldente/private/Submissions';
    my $path                 = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my @full_path_files;
    push @full_path_files, glob( "$path" . "*.xml" );
    my @schema;
    foreach my $file (@full_path_files) {
        $file =~ /.*\/((?:\w+)(?:\.\w+)*.xml)/;
        my $filename = $1;
        if ( $filename =~ /sample/i ) {
            push @schema, 'sample';
        }
        elsif ( $filename =~ /study/ ) {
            push @schema, 'study';
        }
        elsif ( $filename =~ /experiment/ ) {
            push @schema, 'experiment';
        }
        elsif ( $filename =~ /run/ ) {
            push @schema, 'run';
        }
    }
    return join ',', @schema;
}

sub submission_filename {
    my %data = @_;
    if ( !defined $data{submission_volume_name} ) {
        print "Retrieve data ERROR: you must provide a submission name!\n";
        exit;
    }
    my $DATA_SUBMISSION_PATH = '/home/aldente/private/Submissions';
    my $path                 = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my @full_path_files;
    push @full_path_files, glob( "$path" . "*.srf" );
    my @file_names;
    foreach my $file (@full_path_files) {

        #$file =~ /.*\/(\w+(\.\w+)?)/;
        $file =~ /.*\/((?:\w+)(?:\.\w+)*)/;
        push @file_names, $1;
    }
    return join ',', @file_names;
}

sub submission_run_filename {
    my %data                   = @_;
    my $submission_volume_name = $data{submission_volume_name};
    my $run_id                 = $data{run_id};
    my $lane                   = $data{lane};
    my $SUBMISSION_WORK_PATH   = $Configs{data_submission_workspace_dir};
    my $path                   = $SUBMISSION_WORK_PATH . "/Run$run_id";
    my $run_data_file          = "Run" . $run_id . "Lane" . $lane . ".srf";
    my @return                 = ();
    if ( -e "$path/$run_data_file" ) {
        push @return, $run_data_file;
    }
    return join ',', @return;
}

sub submission_checksum {
    my %data = @_;
    if ( !defined $data{submission_volume_name} ) {
        print "Retrieve data ERROR: you must provide a submission name!\n";
        exit;
    }
    my $DATA_SUBMISSION_PATH = '/home/aldente/private/Submissions';
    my $path                 = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my @full_path_files;
    push @full_path_files, glob( "$path" . "*.srf" );
    my @checksums;
    foreach my $file (@full_path_files) {
        my $checksum = RGTools::RGIO::get_MD5( -file => $file );
        push @checksums, $checksum;
    }
    return join ',', @checksums;
}

sub submission_run_checksum {
    my %data                   = @_;
    my $submission_volume_name = $data{submission_volume_name};
    my $run_id                 = $data{run_id};
    my $lane                   = $data{lane};
    my $SUBMISSION_WORK_PATH   = $Configs{data_submission_workspace_dir};
    my $path                   = $SUBMISSION_WORK_PATH . "/Run$run_id";
    my $run_data_file          = "Run" . $run_id . "Lane" . $lane . ".srf";
    my @return                 = ();
    if ( -e "$path/$run_data_file" ) {
        my $checksum = RGTools::RGIO::get_MD5( -file => "$path/$run_data_file" );
        push @return, $checksum;
    }
    return join ',', @return;
}

sub submission_add_run_source {
    my %data = @_;
    if ( !defined $data{submission_volume_name} ) {
        print "Retrieve data ERROR: you must provide a submission name!\n";
        exit;
    }
    my $DATA_SUBMISSION_PATH = '/home/aldente/private/Submissions';
    my $path                 = $DATA_SUBMISSION_PATH . "/Short_Read_Archive/" . $data{submission_volume_name} . '/';
    my @full_path_files;
    push @full_path_files, glob( "$path" . "*.xml" );
    my @file_names;
    foreach my $file (@full_path_files) {
        $file =~ /.*\/((?:\w+)(?:\.\w+)*.xml)/;
        my $file_name = $1;
        if ( $file_name =~ /^run\./ ) {    # run file starts with "run."
            push @file_names, $file_name;
        }
    }
    return join ',', @file_names;
}

sub get_number_of_reads_and_data_block_name {
    my %args     = @_;
    my $dbc      = $args{-dbc};
    my $flowcell = $args{-flowcell};
    my $lane     = $args{-lane};

    require Illumina::Solexa_Analysis;
    my $solexa_analysis_obj = Illumina::Solexa_Analysis->new( -dbc => $dbc, -flowcell => $flowcell );
    my $href = $solexa_analysis_obj->get_number_of_reads_and_data_block_name(
        -dbc   => $dbc,
        -lane  => $lane,
        -quiet => 0
    );
    my $number_of_reads;
    my $data_block_name;

    foreach my $end_read_type ( keys %{ $href->{$lane} } ) {
        $number_of_reads += $href->{$lane}{$end_read_type}{number_of_reads};
        $data_block_name = $href->{$lane}{$end_read_type}{data_block_name};
    }
    return ( $number_of_reads, $data_block_name );
}

###########################
# Get library index for the specified flowcell lane
#
# Usage:	get_library_index($flowcell,$lane);
#
# Return:	Scalar, the index
###########################
sub get_library_index {
#####################
    my %args      = @_;
    my %API_data  = %{ $args{-API_data} };
    my $func_args = $args{-func_args};
    my $dbc       = $args{-dbc};
    my @strs      = split /\s*,\s*/, $func_args;

    #print "function arguments = $func_args\n";
    #print "after spliting:\n";
    #print Dumper \@strs;

    if ( @strs < 2 ) {
        print "Not enough function arguments! Expecting at least two function arguments\n";
        return 0;
    }

    my @args;
    foreach my $str (@strs) {
        my $arg;
        if ( $str =~ /^'(.*)'$/ ) {    # if it starts and ends with a quote character, treat it as a literal string
            $arg = $1;
        }
        else {                         # get it from the API_data
            $arg = $API_data{$str};
        }
        push @args, $arg;
    }

    require Illumina::Solexa_API;
    my $flowcell = $args[0];           # the first argument
    my $lane     = $args[1];           # the second argument

    my $solexa_api = Solexa_API->new( -dbc => $dbc, -dbase => $Configs{DATABASE}, -host => $Configs{SQL_HOST}, -quiet => 1 );
    if ($solexa_api) {
        my $href = $solexa_api->get_flowcell_index( -flowcell => $flowcell, -lane => $lane, -quiet => 1 );
        if ($href) {
            my @keys = keys %$href;
            if ( @keys > 1 ) {
                print "ERROR: Multiple index returned for flowcell $flowcell Lane $lane!\n";
                return 0;
            }
            my $key = $keys[0];
            return $href->{$key}{index};
        }
    }

}

###########################
# Determine if the library is plate based
#
# Usage:	is_plate_based($flowcell,$lane);
#
# Return:	Scalar, 1 if plate based; 0 otherwise
###########################
sub is_plate_based {
#####################
    my $args     = &get_args(@_);
    my $flowcell = $args->{function_args}[0];    # the first argument
    my $lane     = $args->{function_args}[1];    # the second argument
    my $dbc      = $args->{dbc};

    require Illumina::Solexa_API;
    my $solexa_api = Solexa_API->new( -dbc => $dbc, -dbase => $Configs{DATABASE}, -host => $Configs{SQL_HOST}, -quiet => 1 );
    if ($solexa_api) {
        my $href = $solexa_api->get_flowcell_index( -flowcell => $flowcell, -lane => $lane, -quiet => 1 );
        if ($href) {
            my @keys = keys %$href;
            if ( @keys > 1 ) {
                print "ERROR: Multiple index returned for flowcell $flowcell Lane $lane!\n";
                return 0;
            }
            my $key         = $keys[0];
            my $solution_id = $href->{$key}{solution_id};
            my $stock_data  = $solexa_api->get_stock_data( -type => 'solution', -id => $solution_id, -fields => 'stock_name', -quiet => 1 );
            my $stock_name;
            if ( $stock_data && @{ $stock_data->{stock_name} } > 0 ) {
                $stock_name = $stock_data->{stock_name}[0];
            }
            if ( $stock_name && $stock_name eq 'Custom Oligo Plate' ) {
                return 1;
            }
        }
    }
    return 0;
}

###########################
# Convert the input value from one unit to another unit
#
# Usage:	convert_units( $value,$from, $to );
#
# Return:	Scalar, the converted value with unit
###########################
sub convert_units {
#####################
    my $args  = &get_args(@_);
    my $value = $args->{function_args}[0];    # the first argument
    my $from  = $args->{function_args}[1];    # the second argument
    my $to    = $args->{function_args}[2];    # the third argument

    my $new_value;
    if ( $from eq 'ng' && $to eq 'ug' ) {
        $new_value = $value / 1000;
    }
    $new_value .= "$to" if ($new_value);
    return $new_value;
}

#################################
# Retrieve the input arguments. It will replace any value with the API_data if applicable
#
# Usage:	my @args = get_args( @_ );
#
# Return:	Hash ref of the arguments
################################
sub get_args {
    my %args = @_;
    my %API_data;
    %API_data = %{ $args{-API_data} } if ( $args{-API_data} );
    my $func_args = $args{-func_args};

    my %return_args;
    $return_args{dbc} = $args{-dbc};

    my @strs = split /\s*,\s*/, $func_args;

    my @args;
    foreach my $str (@strs) {
        my $arg;
        if ( $str =~ /^'(.*)'$/ ) {    # if it starts and ends with a single quote character, treat it as a literal string
            $arg = $1;
        }
        elsif ( $str =~ /^"(.*)"$/ ) {    # if it starts and ends with a double quote character, treat it as a literal string
            $arg = $1;
        }
        else {                            # get it from the API_data
            $arg = $API_data{$str};
        }
        push @args, $arg;
    }

    $return_args{function_args} = \@args;
    $return_args{API_data}      = \%API_data;

    return \%return_args;
}

###########################
# Calculate the MD5 checksum for the specified file(s)
#
# Usage:	get_file_checksum( filename1, filename2, ..., filenamen );
#
# Return:	Scalar, comma separated checksums
###########################
sub get_file_checksum {
    my $args = &get_args(@_);

    my @checksums;
    my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};

    foreach my $file ( @{ $args->{function_args} } ) {
        my $checksum = 0;

        #if( -e $file ) {
        #	Message( "Calculating MD5 checksum of $file ..." );
        #	$checksum = RGTools::RGIO::get_MD5( -file => $file );
        #}

        ## The above method takes so long to get the checksum that it usually terminated before we get the result.
        ## Change to calculate the checksum beforehand and store it in a file in the data submission workspace.
        ## We get the checksum from the stored file here.
        my $checksum_file = "$SUBMISSION_WORK_PATH/$file.md5";
        if ( -e "$checksum_file" ) {
            my $command = "head $checksum_file";
            my ( $output, $stderr ) = try_system_command( -command => $command );
            if ($output) {
                chomp($output);
                $checksum = $output;
            }
        }

        push @checksums, $checksum;
    }
    return join ',', @checksums;
}

###############################
# Get the file name from the analysis manifest
#
# Usage:	my $filename = get_analysis_file_name( submission_volume_name,library_name );
#
# Return:	Scalar
###############################
sub get_analysis_file_name {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $lib         = $args->{function_args}[1];    # the second argument
    my $dbc         = $args->{dbc};

    my ($sample_name) = $dbc->Table_find( "LibraryStudy,Study", "Study_Description", "WHERE FK_Study__ID = Study_ID AND FK_Library__Name = '$lib'" );

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my @file_names = ();
    my $file_name  = $manifest->{file_names}{file_name};
    if ( ref($file_name) eq 'ARRAY' ) {
        push @file_names, @$file_name;
    }
    else {
        push @file_names, $file_name;
    }
    my @matched_files = ();
    foreach my $name (@file_names) {
        if ( $name =~ /$lib/ or $name =~ /$sample_name/ ) {
            if ( $name =~ /([^\/]*\/)*([^\/]+)$/ ) {
                my $local_name = $2;
                push @matched_files, $local_name;
            }
        }
    }
    return join ',', @matched_files;
}

###############################
# Get the analysis file checksum
#
# Usage:	my $filename = get_analysis_file_checksum( submission_volume_name,library_name );
#
# Return:	Scalar
###############################
sub get_analysis_file_checksum {
###############################
    my $args                 = &get_args(@_);
    my $volume_name          = $args->{function_args}[0];                 # the first argument
    my $lib                  = $args->{function_args}[1];                 # the second argument
    my $dbc                  = $args->{dbc};
    my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};

    my ($sample_name) = $dbc->Table_find( "LibraryStudy,Study", "Study_Description", "WHERE FK_Study__ID = Study_ID AND FK_Library__Name = '$lib'" );

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my @file_names = ();
    my $file_name  = $manifest->{file_names}{file_name};
    if ( ref($file_name) eq 'ARRAY' ) {
        push @file_names, @$file_name;
    }
    else {
        push @file_names, $file_name;
    }

    my @checksums = ();
    foreach my $name (@file_names) {
        if ( $name =~ /$lib/ or $name =~ /$sample_name/ ) {
            if ( -f $name ) {
                my $local_name = '';
                if ( $name =~ /([^\/]*\/)*([^\/]+)$/ ) {
                    $local_name = $2;
                }
                my $checksum_file = "$SUBMISSION_WORK_PATH" . "/$local_name.md5";
                my $checksum;
                if ( -f $checksum_file ) {    # get stored checksum from file
                    my $command = "head $checksum_file";
                    my ( $output, $stderr ) = try_system_command( -command => $command );
                    if ($output) {
                        chomp($output);
                        $checksum = $output;
                    }
                }

                if ( !$checksum ) {
                    Message("calculating MD5 checksum for $name ... ...");
                    $checksum = RGTools::RGIO::get_MD5( -file => $name );

                    # store the checksum
                    open my $FILE, ">$checksum_file" or die "Could not open $checksum_file for writing: $!\n";
                    print $FILE "$checksum";
                    close $FILE;
                }
                push @checksums, $checksum;
            }
        }
    }
    return join ',', @checksums;
}

###############################
# Get the file type from the analysis manifest
#
# Usage:	my $filetype = get_analysis_file_type( submission_volume_name );
#
# Return:	Scalar
###############################
sub get_analysis_file_type {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $dbc         = $args->{dbc};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    return $manifest->{analysis_file_type};
}

###############################
# Get the analysis description from the analysis manifest
#
# Usage:	my $analysis_description = get_analysis_description( submission_volume_name );
#
# Return:	Scalar
###############################
sub get_analysis_description {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $dbc         = $args->{dbc};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );

    #print HTML_Dump "manifest:", $manifest;
    return $manifest->{description};
}

###############################
# Get the analysis type from the analysis manifest
#
# Usage:	my $analysis_type = get_analysis_type( submission_volume_name );
#
# Return:	Scalar
###############################
sub get_analysis_type {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $dbc         = $args->{dbc};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    return $manifest->{analysis_type};
}

###############################
# Get the target SRA object type from the analysis manifest
#
# Usage:	my $sra_object_type = get_target_sra_object_type( submission_volume_name );
#
# Return:	Scalar
###############################
sub get_target_sra_object_type {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $dbc         = $args->{dbc};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my @obj_types = ();
    if ( $manifest->{analysis_target_sra_object_type} =~ /EXPERIMENT/ ) {
        my @refnames = split ',', $args->{API_data}{experiment_aliases};
        foreach my $refname (@refnames) { push @obj_types, $manifest->{analysis_target_sra_object_type} }
    }
    push @obj_types, "SAMPLE";

    return join ',', @obj_types;
}

###############################
# Get the refnames for the target SRA object
#
# Usage:	my $refnames = get_analysis_target_refname( submission_volume_name, library );
#
# Return:	Scalar
###############################
sub get_analysis_target_refcenter {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $lib         = $args->{function_args}[1];    # the second argument
    my $dbc         = $args->{dbc};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );

    return "BCCAGSC,TCGA";
}

###############################
sub get_analysis_target_refname {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $lib         = $args->{function_args}[1];    # the second argument
    my $dbc         = $args->{dbc};

    require SRA::Data_Submission;
    my $sra_obj  = new SRA::Data_Submission( -dbc                => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my $obj_type = $manifest->{analysis_target_sra_object_type};
    if ( $obj_type =~ /EXPERIMENT/ ) {

        my $experiments = $args->{API_data}{experiment_aliases};
        my ($sample_name) = $dbc->Table_find( "LibraryStudy,Study", "Study_Description", "WHERE FK_Study__ID = Study_ID AND FK_Library__Name = '$lib'" );
        return $experiments . "," . $sample_name;
    }
}

###############################
# Get the SRA study accession from the analysis manifest
#
# Usage:	my $study_accession = get_analysis_study_accession( submission_volume_name );
#
# Return:	Scalar
###############################
sub get_analysis_study_accession {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $dbc         = $args->{dbc};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    return $manifest->{study_accession};
}

###############################
# Get the last modified date for the analysis file
#
# Usage:	my $date = get_analysis_date( submission_volume_name, lib );
#
# Return:	Scalar
###############################
sub get_analysis_date {
###############################
    my $args        = &get_args(@_);
    my $volume_name = $args->{function_args}[0];    # the first argument
    my $lib         = $args->{function_args}[1];    # the second argument
    my $dbc         = $args->{dbc};

    my ($sample_name) = $dbc->Table_find( "LibraryStudy,Study", "Study_Description", "WHERE FK_Study__ID = Study_ID AND FK_Library__Name = '$lib'" );
    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my @file_names = ();
    my $file_name  = $manifest->{file_names}{file_name};

    if ( ref($file_name) eq 'ARRAY' ) {
        push @file_names, @$file_name;
    }
    else {
        push @file_names, $file_name;
    }

    my $analysis;

    foreach my $name (@file_names) {
        if ( $name =~ /$lib/ or $name =~ /$sample_name/ ) {
            $analysis = $name;
            last;
        }
    }

    my ( $date, $err ) = try_system_command( -command => "date --iso-8601='seconds' --utc -r $analysis" );
    if ($date) {
        chomp $date;
        $date =~ s/[\+-]\d+$/Z/;
    }

    return $date;
}

############################################
# Check if the specified processing directive pattern exists in the file name
#
# Return:	Scalar
############################################
sub get_processing_directive {
    my $args                 = &get_args(@_);
    my $pattern              = $args->{function_args}[0];                 # the first argument
    my $volume_name          = $args->{function_args}[1];                 # the second argument
    my $lib                  = $args->{function_args}[2];                 # the third argument
    my $dbc                  = $args->{dbc};
    my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my @file_names = ();
    my $file_name  = $manifest->{file_names}{file_name};
    if ( ref($file_name) eq 'ARRAY' ) {
        push @file_names, @$file_name;
    }
    else {
        push @file_names, $file_name;
    }

    my @results = ();
    foreach my $name (@file_names) {
        if ( $name =~ /$lib/ ) {
            if ( -f $name ) {
                if ( $name =~ /$pattern/i ) {
                    push @results, 'true';
                }
                else {
                    push @results, 'false';
                }
            }
        }
    }
    return join ',', @results;
}

############################################
# Check if the chastity failed reads are included in the bam file
#
# Return:	Scalar
############################################
sub is_chastity_failed_reads_included {
    my $args                 = &get_args(@_);
    my $volume_name          = $args->{function_args}[0];
    my $lib                  = $args->{function_args}[1];
    my $dbc                  = $args->{dbc};
    my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my @file_names = ();
    my $file_name  = $manifest->{file_names}{file_name};
    if ( ref($file_name) eq 'ARRAY' ) {
        push @file_names, @$file_name;
    }
    else {
        push @file_names, $file_name;
    }

    my @results = ();
    foreach my $name (@file_names) {
        if ( $name =~ /$lib/ ) {
            if ( -f $name ) {
                if ( $name =~ /chaste_/ ) {
                    push @results, 'false';
                }
                else {
                    push @results, 'true';
                }
            }
        }
    }
    return join ',', @results;
}

############################################
# Check if the chastity failed reads are removed from the bam file
#
# Return:	Scalar
############################################
sub is_chastity_failed_reads_removed {
    my $args                 = &get_args(@_);
    my $volume_name          = $args->{function_args}[0];
    my $lib                  = $args->{function_args}[1];
    my $dbc                  = $args->{dbc};
    my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my @file_names = ();
    my $file_name  = $manifest->{file_names}{file_name};
    if ( ref($file_name) eq 'ARRAY' ) {
        push @file_names, @$file_name;
    }
    else {
        push @file_names, $file_name;
    }

    my @results = ();
    foreach my $name (@file_names) {
        if ( $name =~ /$lib/ ) {
            if ( -f $name ) {
                if ( $name =~ /chaste_/ ) {
                    push @results, 'true';
                }
                else {
                    push @results, 'false';
                }
            }
        }
    }
    return join ',', @results;
}

############################################
# Check if the shadow reads are included in the alignment
#
# Return:	Scalar
############################################
sub is_shadow_reads_included {
    my $args                 = &get_args(@_);
    my $volume_name          = $args->{function_args}[0];
    my $lib                  = $args->{function_args}[1];
    my $dbc                  = $args->{dbc};
    my $SUBMISSION_WORK_PATH = $Configs{data_submission_workspace_dir};

    require SRA::Data_Submission;
    my $sra_obj = new SRA::Data_Submission( -dbc => $dbc );
    my $manifest = $sra_obj->get_analysis_manifest( -volume_name => $volume_name );
    my @file_names = ();
    my $file_name  = $manifest->{file_names}{file_name};
    if ( ref($file_name) eq 'ARRAY' ) {
        push @file_names, @$file_name;
    }
    else {
        push @file_names, $file_name;
    }

    my @results = ();
    foreach my $name (@file_names) {
        if ( $name =~ /$lib/ ) {
            if ( -f $name ) {
                if ( $name =~ /chaste_/ ) {
                    if ( $name =~ /(.*\/meta_bwa)\/.*/ ) {
                        my $path       = $1;
                        my $merge_file = "$path/merge.sh";
                        my ( $out, $err ) = try_system_command( -command => "grep export_f1b6 $merge_file" );
                        if ($out) {
                            push @results, 'false';
                        }
                        else {
                            push @results, 'true';
                        }
                    }
                    else {
                        push @results, 'NA';
                    }
                }
                else {
                    push @results, 'NA';
                }
            }
        }
    }
    return join ',', @results;
}

########################################
# Get the size fraction value.
# If it is tube based, the adapter size need to be subtracted is 119.
# If it is plate based, the adapter size need to be subtracted is 125.
#
# Usage:	my $size_fraction = get_size_fraction( $flowcell_code, $lane, $library_size_distribution, $unit );
#
# Return:	Scalar
########################################
sub get_size_fraction {
########################################
    my $args                      = &get_args(@_);
    my $flowcell                  = $args->{function_args}[0];    # the first argument
    my $lane                      = $args->{function_args}[1];    # the first argument
    my $library_size_distribution = $args->{function_args}[2];    # the third argument
    my $unit                      = $args->{function_args}[3];    # the fourth argument

    my $adapter_size;
    my $plate_based = &is_plate_based(@_);
    if   ($plate_based) { $adapter_size = 125 }
    else                { $adapter_size = 119 }

    my $low;
    my $high;
    if ( $library_size_distribution =~ /(\d+):(\d+)/ ) {
        $low  = $1;
        $high = $2;
    }
    if ( defined $low && defined $high ) {
        $low  -= $adapter_size;
        $high -= $adapter_size;
        return "$low-$high$unit";
    }
    else { return 'NA' }
}

########################################
# Get the ChIP_Seq_input experiment title.
# The format is "Input" + size fraction + cell type.
#
# Usage:	my $size_fraction = get_input_experiment_title( $flowcell_code, $lane, $library_size_distribution, $unit, "CD8 Naive" );
#
# Return:	Scalar
########################################
sub get_input_experiment_title {
########################################
    my $args                      = &get_args(@_);
    my $flowcell                  = $args->{function_args}[0];    # the first argument
    my $lane                      = $args->{function_args}[1];    # the first argument
    my $library_size_distribution = $args->{function_args}[2];    # the third argument
    my $unit                      = $args->{function_args}[3];    # the fourth argument
    my $cell_type                 = $args->{function_args}[4];    # the fifth argument

    my $size_fraction = &get_size_fraction(@_);
    my $result        = "Input " . $size_fraction . " $cell_type";
    return $result;
}

########################################
sub add_unit {
########################################
    my $args = &get_args(@_);
    my $data = $args->{function_args}[0];                         # the first argument
    my $unit = $args->{function_args}[1];                         # the second argument

    ## if data ends with digit, then add the unit; otherwise, do not add the unit because different unit might have been used sometimes
    if ( $data =~ /.*\d\s*$/ ) {
        $data .= "$unit";
    }
    return $data;
}

########################################
# Convert to the best unit. It's a wrapper of RGTools::Conversion::Get_Best_Units() and Custom_Convert_Units.
#submission_volume
# Usage:	my $data_in_best_unit = get_best_unit( $amount, $unit );
#
# Return:	Scalar, the amount and the best unit
########################################
sub get_best_unit {
########################################
    my $args   = &get_args(@_);
    my $amount = $args->{function_args}[0];    # the first argument
    my $unit   = $args->{function_args}[1];    # the second argument
    ## if amount ends with digit, then add the unit;
    ## otherwise, do not add the unit because different unit might have been used sometimes.
    if ( $amount !~ /.*\d\s*$/ ) {

        #Message( "ERROR: Incorrect format! Only numeric value is expected: amount=[$amount], unit=[$unit]" );
        return $amount;
    }

    my $qty;
    my $best_unit;
    require RGTools::Conversion;
    if ( $unit =~ /^(sec)|(s)|(min)|(m)|(hour)|(hr)|(h)$/i ) {    # time units
        if    ( $unit =~ /^s/i ) { $unit = "sec" }
        elsif ( $unit =~ /^m/i ) { $unit = "min" }
        elsif ( $unit =~ /^h/i ) { $unit = "hr" }
        my @Time_Scale       = ( 1,     60,    3600 );
        my @Time_Scale_Units = ( 'sec', 'min', 'hr' );
        ( $qty, $best_unit ) = RGTools::Conversion::Custom_Convert_Units( -value => $amount, -units => $unit, -scale => \@Time_Scale, -scale_units => \@Time_Scale_Units );
    }
    else {                                                        # volume units
        ( $qty, $best_unit ) = RGTools::Conversion::Get_Best_Units( $amount, $unit );
    }

    return "$qty$best_unit";
}

sub get_antibody_amount {
    my $args    = &get_args(@_);
    my $amount1 = $args->{function_args}[0];                      # the first argument
    my $unit1   = $args->{function_args}[1];                      # the second argument
    my $amount2 = $args->{function_args}[2];                      # the third argument
    my $unit2   = $args->{function_args}[3];                      # the fourth argument

    my $func_args;
    if ($amount1) {
        $func_args = "'" . $amount1 . "','" . $unit1 . "'";
    }
    elsif ($amount2) {
        $func_args = "'" . $amount2 . "','" . $unit2 . "'";
    }
    my $result;
    if ($func_args) {
        $result = &get_best_unit( -func_args => "$func_args" );
    }
    return $result;
}

sub get_mRNA_Seq_experiment_title {
    my $args      = &get_args(@_);
    my $plate_ids = $args->{function_args}[0];    # the first argument
    my $tissue    = $args->{function_args}[1];    # the second argument
                                                  #my $subtissue			= $args->{function_args}[2]; # the third argument
    my $dbc       = $args->{dbc};

    my $is_slx_transcriptome = 1;
    require alDente::Container;
    my @pids = Cast_List( -list => $plate_ids, -to => 'array' );
    foreach my $pid (@pids) {
        my $parents = &alDente::Container::get_Parents( -dbc => $dbc, -id => $pid, -format => 'list' );
        my @pipelines = $dbc->Table_find(
            -table     => 'Plate,Pipeline',
            -fields    => 'Pipeline_Name',
            -condition => "WHERE FK_Pipeline__ID = Pipeline_ID and Plate_ID in ($parents)",
            -distinct  => 1,
        );
        unless ( grep 'SLX-Transcriptome', @pipelines ) {
            $is_slx_transcriptome = 0;
            last;
        }
    }

    #if( $is_slx_transcriptome ) { return "RNA-Seq polyA+ $tissue $subtissue" }
    #else { return "RNA-Seq $tissue $subtissue" }
    if   ($is_slx_transcriptome) { return "RNA-Seq polyA+ $tissue" }
    else                         { return "RNA-Seq $tissue" }
}

sub get_mRNA_Seq_experiment_description {
    my $args      = &get_args(@_);
    my $plate_ids = $args->{function_args}[0];    # the first argument
    my $tissue    = $args->{function_args}[1];    # the second argument
    my $dbc       = $args->{dbc};

    my $is_slx_transcriptome = 1;
    require alDente::Container;
    my @pids = Cast_List( -list => $plate_ids, -to => 'array' );
    foreach my $pid (@pids) {
        my $parents = &alDente::Container::get_Parents( -dbc => $dbc, -id => $pid, -format => 'list' );
        my @pipelines = $dbc->Table_find(
            -table     => 'Plate,Pipeline',
            -fields    => 'Pipeline_Name',
            -condition => "WHERE FK_Pipeline__ID = Pipeline_ID and Plate_ID in ($parents)",
            -distinct  => 1,
        );
        unless ( grep 'SLX-Transcriptome', @pipelines ) {
            $is_slx_transcriptome = 0;
            last;
        }
    }
    if   ($is_slx_transcriptome) { return "RNA-Seq polyA+ $tissue" }
    else                         { return "RNA-Seq $tissue" }
}

sub get_PCR_primer_sequence {
    my $args     = &get_args(@_);
    my $plate_id = $args->{function_args}[0];    # the first argument
    my $primer   = $args->{function_args}[1];    # primer name
    my $dbc      = $args->{dbc};
    my $sequence;
    require alDente::alDente_API;
    my $api = alDente::alDente_API->new( -dbc => $dbc, -dbase => $Configs{DATABASE}, -host => $Configs{SQL_HOST}, -quiet => 1 );
    if ($api) {
        my $data = $api->get_event_data( -plate_id => $plate_id, -include_parents => 1, -protocol => 'Off Site Constructed Samples' );
        require Sequencing::Sequencing_API;
        my $seq_api = Sequencing_API->new( -dbc => $dbc, -dbase => $Configs{DATABASE}, -host => $Configs{SQL_HOST}, -quiet => 1 );
        if ( $data && $data->{event} ) {
            my $count = scalar( @{ $data->{event} } );
            if ( $count > 0 ) {                  ## constructed off site, use standard PCR primer PE 1.0: sol100918 and PCR primer PE 2.0: sol100919
                my $primer_info = $seq_api->get_primer_data( -primer => $primer );
                if ( $primer_info->{primer_sequence} && scalar( @{ $primer_info->{primer_sequence} } ) >= 1 ) {
                    $sequence = $primer_info->{primer_sequence}[0];
                }
            }
        }
        else {
            $data = $api->get_event_data( -plate_id => $plate_id, -include_parents => 1, -protocol_step => 'Add PCR primer PE 1.0' );
            if ( $data && $data->{event} ) {
                my $count = scalar( @{ $data->{event} } );
                if ( $count > 0 ) {              ## constructed in house, use SLX-PET protocol step 13 "Add PCR primer PE 1.0" and step 14 "Add PCR primer PE 2.0"
                    my $primer_info = $seq_api->get_primer_data( -primer => $primer );
                    if ( $primer_info->{primer_sequence} && scalar( @{ $primer_info->{primer_sequence} } ) >= 1 ) {
                        $sequence = $primer_info->{primer_sequence}[0];
                    }
                }
            }
        }
    }
    return $sequence;
}
=cut

###
###
### Legacy code ends here
###
###
###
###

1;
