###############################################################
# DB_Object.pm
#
# This object is the superclass of alDente database objects.
#
####################################################################################################
# $Id: DB_Object.pm,v 1.112 2004/11/30 23:05:38 mariol Exp $
####################################################################################################
package SDB::DB_Object;

use base LampLite::DB_Object;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DB_Object.pm - This object is the superclass of alDente database objects.

=head1 SYNOPSIS <UPLINK>

 use SDB::DB_Object;
 use SDB::DBIO;
  
#my $dbc = DB_Connect(host=>'athena',dbase=>'seqachan',user=>'labuser',password=>'manybases');
 my $dbc = SDB::DBIO->new();
 $dbc->connect(-host=>'athena',-dbase=>'seqdev',-user=>'labuser',-password=>'manybases');
  
 ### A 'SAGE_Library' object that spans 3 tables: Library, Vector_Based_Library, SAGE_Library
 my $dbo1 = SDB::DB_Object->new(-dbc=>$dbc,-tables=>'Library,Vector_Based_Library,SAGE_Library');
 my $scalar;
 my @array;
 my %hash;
  
 ### Retrieve library CN001
 # Option 1 - Specify primary values first and then call retrieve()
 $dbo1->primary_value(-table=>'Library',-value=>'CN001');  # If the '-table' parameter is omitted the first table from the tables list is assumed
 %hash = %{$dbo1->load_Object()};                             # Format: $hash{'Library.Library_Name'} = 'CN001'
  
 # Option 2 - Specify a condition where calling retrieve()
 %hash = %{$dbo1->load_Object(-condition=>"Library.Library_Name='CN001'")}; # Format: $hash{'Library.Library_Name'} = 'CN001'
  
 ### After the retrieve, values are also stored inside the object and can be retrieved by calling the values() method
 %hash = %{$dbo1->values()};   # Get all values; Format: $hash{'Library.Library_Name'} = 'CN001'
 %hash = %{$dbo1->values(-fields=>['Library.Library_Host','Vector_Based_Library.5Prime_Sequence','SAGE_Library.RNA_DNA_Extraction'])};  ### Get values for specific fields; Format: $hash{'Library.Library_Name'} = 'CN001'
 $scalar = $dbo1->value(-field=>'Library.Library_Host');  # Get values for a single field.
  
 ### Other than retrieving all the fields, you can limit the fields you want to retrieve by using the 'fields' param:
 %hash = %{$dbo1->load_Object(-fields=>['Library.Library_Name','Vector_Based_Library.5Prime_Sequence','SAGE_Library.RNA_DNA_Extraction'])};
  
 ### You can also provide an alias of your fields
 %hash = %{$dbo1->load_Object(-fields=>["concat(Library.Library_Name,' - ',Library.Library_FullName) As Lib"])};
  
 ### In addition to the core tables, you can also retrieve tables/fields from other tables
 %hash = %{$dbo1->load_Object(-FK_tables=>['Project','Funding'])}; # Retrieve all fields from Project and Funding FK tables
 %hash = %{$dbo1->load_Object(-FK_tables=>['Project','Funding'],-FK_fields=>['Project.Project_Name','Funding.Funding_Name'])}; # Retrieve the fields 'Project.Project_Name' and 'Funding.Funding_Name' from Project and Funding FK tables
  
 ### Other information that you can obtain...
 $scalar = $dbo1->record_count();         # The number of records in the object
 %hash = %{$dbo1->primary_fields()};      # Get all the primary fields; Format: $hash{'Library'} = 'Library Name'
 $scalar = $dbo1->primary_field(-table=>'SAGE_Library');  # Get primary field of a table. If the '-table' parameter is omitted the first table from the tables list is assumed
 %hash = %{$dbo1->primary_values()};      # Get all the primary values; Format: $hash{'Library'} = 'CN001'
 $scalar = $dbo1->primary_value(-table=>'SAGE_Library');   # Get primary value of a table. If the '-table' parameter is omitted the first table from the tables list is assumed
  
 ### Updating the database
 # First you can clone another object using the clone() method
 my $dbo2 = $dbo1->clone();
  
 # Change the new object to library 'CN100' and set primary and foreign keys to ''
 $dbo2->values(-fields=>['Library.Library_Name','Vector_Based_Library.Vector_Based_Library_ID','Vector_Based_Library.FK_Library__Name',
               'SAGE_Library.SAGE_Library_ID','SAGE_Library.FK_Library__Name','SAGE_Library.FK_Vector_Based_Library__ID'],
               -values=>['CN100','','CN100','','CN100','']);
  
 # Insert the CN100 into the database
 %hash = %{$dbo2->insert()};                 # Returns the number of records inserted; Format: $hash{Library} = 1;
  
 # Update some values of CN100 into the database
 %hash = %{$dbo2->update(-fields=>['Library.Library_Host','Vector_Based_Library.5Prime_Sequence','Vector_Based_Library.3Prime_Sequence',
                         'SAGE_Library.RNA_DNA_Extraction'],-values=>['CN100 Host','AAAA','TTTT','RNA Extraction?'])}; 
                         # Returns the number of records updated; Format: $hash{Library} = 1
  
 # Delete the CN100 record from the database
 %hash = %{$dbo2->delete()};                 # Returns the number of records deleted; Format: $hash{Library} = 1

=head1 DESCRIPTION <UPLINK>

=for html
This object is the superclass of alDente database objects.<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use Data::Dumper;
use Carp;

#use AutoLoader;
use CGI qw(:standard);

##############################
# custom_modules_ref         #
##############################
use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::Object;
use RGTools::RGmath;
use RGTools::RGIO;

use RGTools::HTML_Table;
use RGTools::Conversion;
#  alDente::SDB_Defaults;    ### Temporary for testing

use SDB::Attribute;
use SDB::Attribute_Views;

use LampLite::Bootstrap();

##############################
# global_vars                #
##############################
### Global variables
use vars qw(%Settings %Field_Info);
my $BS = new Bootstrap();
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
##################

##############################
# constructor                #
##############################

##############################
# my $set_fields;
# my $set_condition;
# my $set_id;
# my $set_add_table;
##############################

##################
sub new {
##################
    #
    # Constructor of the object
    #
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = &filter_input( \@_, -args => 'dbc' );
    my $frozen = $args{-frozen} || 0;                                                                # Reference to frozen object if there is any. [Object]
    my $dbc    = $args{-dbc}    || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table  = $args{-table} || $args{-tables};
    my $id   = $args{-id}; 
    my $debug = $args{-debug};

    # allow no initialization for loading from XML
    my $initialize = 1;
    if ( ( defined $args{-initialize} ) && ( $args{-initialize} == 0 ) ) {
        $initialize = 0;
    }

    my $self = $this->Object::new(%args);
    bless $self, $class;
    
    $self->{debug} = $debug;
    $self->{dbc}   = $dbc;
    $self->{id}    = $id;

    if ($frozen) { return $self }    # If frozen then return now with the new dbc handle.

    $self->{multi} = $args{-multi} || 0;    # Temporary flag to indicate using multipe version or not
    $self->{include_fields} = Cast_List( -list => $args{-include_fields}, -to => 'arrayref' );    # Explicitly specify the list of fields to include
    $self->{exclude_fields} = Cast_List( -list => $args{-exclude_fields}, -to => 'arrayref' );    # Explicitly specify the list of fields to exclude
    $self->{fields_list}    = [];                                                                 # A list of fields
    $self->{fields}         = {};                                                                 # Hash of all the fields of the object
    $self->{record_count}   = 0;                                                                  # Number of records currently in the object
    $self->{primary_fields} = {};                                                                 # A hash that contains the primary field for each table
    $self->{record_index}   = {};                                                                 # An index hash for faster retrieval of records
    $self->{newids}         = {};                                                                 # New primary values from the previous INSERT operation
    $self->{no_joins}       = [];                                                                 # Specify an arrayref of tables not to be joined

    # A list of tables that the object will spend (defaulted to current class)
        
    my $table_ref = Cast_List( -list => $table || $class, -to => 'arrayref' );
    if ( $table_ref->[0] =~ /DB_Object/i ) {
        $self->{tables} = [];
    }
    else {
        $self->{tables} = $table_ref;
    }
    $self->{left_joins} = [];

    if ( $initialize && $dbc ) {
        $self->_initialize();
    }

    if ( $args{-retrieve} ) {
        my $FK_tables    = $args{-FK_tables}    || '';    # Indicate the list of foreign tables to follow [ArrayRef]
        my $FK_fields    = $args{-FK_fields}    || '';    # Indicate the list of foreign fields to follow. By default will retrieve all fields [ArrayRef]
        my $child_tables = $args{-child_tables} || '';    # Indicate the list of child tables to follow [ArrayRef]
        my $child_fields = $args{-child_fields} || '';    # Indicate the list of child fields to follow. By default will retrieve all fields [ArrayRef]
        my $multiple     = $args{-multiple}     || 0;
        $self->load_Object( -FK_tables => $FK_tables, -FK_fields => $FK_fields, -child_tables => $child_tables, -child_fields => $child_fields, -multiple => $multiple );
    }

    ### Quick load if id or table=>id supplied ###
    if ( $id || $args{-load} ) {
        my %load;
        if ( $args{-load} ) {
            %load = %{ $args{-load} };    
            $id = $load{-id};           
        }
        
        my $main_table = $self->{tables}->[0];

        foreach my $thistable ( @{ $self->{tables} } ) {    ## check all tables for table=>id spec
            if ( $load{"$thistable"} ) {
                $id = $load{"$thistable"};
                $main_table ||= $thistable;
            }
        }
        
        $self->primary_value( -table => $main_table, -value => $id );
        $self->load_Object();
    }

    $self->set( 'DBobject', $self->{tables}->[0] );         # mark the object type - automatically use the FIRST table in the definition.
    return $self;
}

#
# Quick accessor to View module
#
#
###########
sub View {
###########
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'id,class' );
    my $id    = $args{-id} || $self->{id};
    my $class = $args{-class} || ref $self;
    my $dbc   = $args{-dbc} || $self->{dbc} || $self->param('dbc');

    my $view_class = $class;
    $view_class .= '_Views';
    $args{-dbc} = $dbc;

    eval "require $view_class";
    my $View = $view_class->new(%args);
    $View->{Model} = $self;

    if ($id) { $View->{id} = $id; }
    return $View;
}

##############################
# public_methods             #
##############################

############
sub reset {
############
    my $self = shift;
    my $dbc  = shift;

    if ($dbc) { $self->{dbc} = $dbc }

    #    $self->_initialize();

}

##################
# dbh Accessor
#
# Return: database handle
#######
sub dbh {
########
    my $self = shift;
    return $self->{dbh};
}

##################
# dbc Accessor
#
# Return: database handle
#######
sub dbc {
########
    my $self = shift;
    return $self->{dbc};
}

########
sub get {
########
    my $self  = shift;
    my $field = shift;

    if ( $field && defined $self->{$field} ) {
        ### Attribute retrieval subroutine ##
        return $self->{$field};
    }
    else {
        return undef;
    }
}

########
sub set {
########
    my $self  = shift;
    my $field = shift;
    my $value = shift;

    if ( $field && defined $value ) {
        ### Attribute retrieval subroutine ##
        return $self->{$field} = $value;
    }
    else {
        return 0;
    }
}

##############################
#  load an object from a form
#
#  Ex: $db_obj->load_object_from_form(-insert=>1);
#  -if insert=>1 the object will be inserted into the DB
#
#  Returns: \$db_obj
#
##############################
sub load_object_from_form {

    my $self   = shift;
    my %args   = @_;
    my $dbc    = $self->{dbc};
    my @tables = @{ $self->{tables} };
    my $insert = $args{-insert};         ## if set the obeject will be inserted into the DB

    my @update_tables;
    foreach my $table (@tables) {
#        $dbc->initialize_field_info($table);
        my $Field_Info = $dbc->field_info($table);
        my @fields = @{ $Field_Info{$table}{Fields} };
        foreach my $field (@fields) {

            my $value = get_Table_Param( -table => $table, -field => $field, -dbc => $dbc );

            #convert foreign key info to fk value
            my ( $reftable, $reffield ) = $dbc->foreign_key_check($field);
            if ( $reftable && $reffield && $value ) {
                $value = get_FK_ID( -dbc => $dbc, -field => $field, -value => $value );
            }
            $self->value( "$table.$field", $value );
            if ($value) {
                if ( !grep /^$table$/, @update_tables ) { push @update_tables, $table }    ## include this table in insert command
            }
        }
    }

    my $ok = 0;
    if ($insert) {
        $ok = $self->insert( -tables => \@update_tables );
    }
    if ( !$ok ) {
        return $ok;
    }
    return $self;

}

##############################
#  load an object from an XML file
#
#  Ex: $db_obj->load_object_from_XML(-file=>'xmlfile.xml');
#  -if insert=>1 the object will be inserted into the DB
#
#  Returns: \$db_obj
#
##############################
sub load_object_from_XML {

    my $self   = shift;
    my %args   = @_;
    my $dbc    = $self->{dbc};
    my @tables = @{ $self->{tables} };

    my $insert = $args{-insert};    ## if set the object will be inserted into the DB
    my $file   = $args{-file};      ## defines the file to load from

    # check if file exists
    unless ( ( -e "$file" ) && ( -r "$file" ) ) {
        Message("Error: File cannot be found or read.");
        return;
    }

    # read XML
    eval "require XML::Simple";
    my $xo = new XML::Simple();
    my $xhash = $xo->XMLin( "$file", KeepRoot => 1 );

    # check to make sure that the table list in XML is a subset of $self->{tables}
    # if tables is not initialized, load the object tables argument
    if ( $self->{tables} && scalar( @{ $self->{tables} } ) > 0 ) {
        my $ok        = 1;
        my @xmltables = split( ',', $xhash->{object}{tables} );
        my @diff      = @{ &RGTools::RGIO::set_difference( \@xmltables, \@tables ) };
        if ( scalar(@diff) > 0 ) {
            Message( "ERROR: table/s " . join( ',', @diff ) . " are not defined in DB_Object." );
            return undef;
        }
    }
    else {
        $self->add_tables( $xhash->{object}{tables} );
        @tables = @{ $self->{tables} };
    }

    foreach my $table (@tables) {
#        $dbc->initialize_field_info($table);
        my $Field_Info = $dbc->field_info($table);
        my @fields = @{ $Field_Info{$table}{Fields} };
        foreach my $field (@fields) {
            my $value = $xhash->{object}{field}{$field}{value} || '';
            $self->value( "$table.$field", $value );
        }
    }
    if ($insert) {
        $self->insert();
    }
    return $self;
}

##############################
#  export an object to an xml file
#
#  Ex: $db_obj->dump_to_XML();
#
#  Returns: xml string
#
##############################
sub dump_to_XML {

    my $self   = shift;
    my %args   = @_;
    my $dbc    = $self->{dbc};
    my @tables = @{ $self->{tables} };

    my $class = ref $self;

    # determine (using reflection) if the module name specifies the primary table
    # if not, then use the first table defined
    my $main_table = $class;
    $main_table =~s /.*\:\://;
    if ( $main_table eq 'DB_Object' && $tables[0]) {
        $main_table = $tables[0];
    }

    eval "require XML::Simple";
    my $xml = '';
    foreach my $index ( 1 .. $self->record_count() ) {

        my %outhash;

        # define tables
        $outhash{object}{table} = join( ',', @tables );
        $outhash{object}{name} = $main_table;

        # get primary fields
        my $primary_field = $self->primary_field( -table => $main_table );
        $outhash{object}{id} = $self->value( -field => "$main_table.$primary_field", -index => $index - 1 );

        # define values
        foreach my $table (@tables) {
            my $Field_Info = $dbc->field_info($table);
#            $dbc->initialize_field_info($table);
            my @fields = @{ $Field_Info{$table}{Fields} };
            foreach my $field (@fields) {
                my $value = $self->value( -field => "$table.$field", -index => $index - 1 );

                # if value is undef, omit it
                if ( defined $value ) {
                    $outhash{object}{field}{$field}{value} = $value;
                }
            }
        }

        # read XML
        my $xo = new XML::Simple();
        $xml .= $xo->XMLout( \%outhash, KeepRoot => 1 );
    }

    return $xml;
}
##################
#
# Accessor for Database field data.
#
# retrieves values loaded by 'load_Object'
# - stored in object as $self->{fields}{table}{field}{values}  (arrayref)
###############
sub get_data {
###############
    my $self  = shift;
    my $field = shift;
    my $index = shift || $self->{record_index} || 0;

    if ( my ( $rtable, $rfield ) = $self->_resolve_field( \$field, -quiet => 0 ) ) {
        $rtable ||= $self->single_table();

        if ( grep /^$rtable$/, @{ $self->{tables} } ) {
            return $self->value( -field => "$rtable.$rfield", -index => $index );
        }
        else {
            Message("Unrecognized table $rtable [$field]");
        return;
        }
   }
    else {
        Message("Unrecognized field $rfield");
        return;
    }
}

###################
sub single_table {
###################
    my $self = shift;

    if ( $self->{tables} && int( @{ $self->{tables} } ) == 1 ) {
        return $self->{tables}->[0];
    }
}

##################
#
# Accessor for Database field data.
#
# retrieves values loaded by 'load_Object'
# - stored in object as $self->{fields}{table}{field}{values}  (arrayref)
#
################
sub get_list {
################
    my $self  = shift;
    my $field = shift;

    if ( my ( $rtable, $rfield ) = $self->_resolve_field( \$field, -quiet => 0 ) ) {
        if ( grep /^$rtable$/, @{ $self->{tables} } ) {
            return $self->{fields}{$rtable}{$rfield}{values};
        }
        else {
            Message("Unrecognized table $rtable");
            return;
        }
    }
    else {
        Message("Unrecognized field $rfield");
        return;
    }
}

######################
#
# Accessor for Database information for the current record
# - all data for current record returned in single keyed hash.
# (use $self->next_record to go to next record if multiple records loaded at once)
#
#############
sub get_record {
#############
    my $self  = shift;
    my $index = shift;

    if ( defined $index ) {
        $self->{record_index} = $index;
        $self->{more_records} = $self->{record_count} - $index;
    }

    unless ( defined $self->{record_count} ) { print "No Data retrieved (did you use the -save option ?)"; return {}; }
    unless ( $self->{record_count} ) { print "No records returned"; print HTML_Dump(); return {}; }
    unless ( defined $self->{record_index} ) { $self->{record_index} = 0 }

    my %hash;
    my @tables = keys %{ $self->{fields} };
    foreach my $table (@tables) {
        my @fields = keys %{ $self->{fields}->{$table} };
        foreach my $field (@fields) {
            my $key = "$table.$field";
            $hash{$key} = $self->value( -field => "$table.$field", -index => $self->{record_index} );
        }
    }

    return \%hash;
}

# Load the attributes for an object if an ID exists
#
#######################
sub load_attributes {
#######################
    my $self  = shift;
    my $index = shift;

    foreach my $table ( keys %{ $self->{fields} } ) {
        my $attribute_table = $table . "_Attribute";
        if ( grep /^$attribute_table$/, $self->dbc->DB_tables() ) {
            my %table_attributes = $self->dbc->Table_retrieve( "$attribute_table,Attribute", [ 'Attribute_Name', 'Attribute_Value' ], "WHERE FK_" . $table . "__ID = $index and FK_Attribute__ID = Attribute_ID", -key => 'Attribute_Name' );

            foreach my $attr ( keys %table_attributes ) {
                $self->{$attr} = $table_attributes{$attr};
            }
        }
    }
    return 1;
}

# get the attributes for a record
#
# Return: hash of attribute
############################
sub get_attribute_record {
############################
    my $self        = shift;
    my $id          = shift || $self->{id};
    my $return_list = shift || 1;
    my %hash;
    my @list;
    foreach my $table ( keys %{ $self->{fields} } ) {
        my $attribute_table = $table . "_Attribute";
        if ( grep /$attribute_table/, $self->dbc->DB_tables() ) {
            my %table_attributes = $self->dbc->Table_retrieve( "$attribute_table,Attribute", [ 'Attribute_Name', 'Attribute_Value' ], "WHERE FK_" . $table . "__ID = $id and FK_Attribute__ID = Attribute_ID", -key => 'Attribute_Name' );

            foreach my $attr ( keys %table_attributes ) {
                $hash{$attr} = $table_attributes{$attr};
                push( @list, "$attr = $hash{$attr}{Attribute_Value}" );
            }
        }
    }
    if (@list) { return @list; }
    return \%hash;
}

###############
# Increment pointer to next record
# (useful when multiple objects loaded at once, and you wish to access them sequentially)
#
# Return:  hash (keys are fields)  eg.
###########
sub next_record {
###########
    my $self = shift;

    if ( $self->{record_index} < $self->{record_count} ) {
        $self->{record_index}++;
        return 1;
    }
    else {
        return 0;
    }
}

###########
sub get_next {
###########
    my $self  = shift;
    my $field = shift;
    my $index = shift || 0;

    $self->next_record();
    return $self->get_data( $field, $index );    ## get next loaded data object
}

#
# Retrieve values from the database table.
# Return a reference to the hash that contains the data
#
#
# Uses:
## DBIO:
#    Table_find
#    get_join_conditions
#
# self:
#    add_tables
#    left_join
#    primary_value(s)
#    primary_field
#    _resolve_field
# 
#######################
sub load_Object {
#######################
    my $self = shift;
    my %args = @_;
    if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }

    my $field_ref             = $args{-fields};
    my $FK_tables             = $args{-FK_tables} || '';                # Indicate the list of foreign tables to follow [ArrayRef]
    my $FK_fields             = $args{-FK_fields} || '';                # Indicate the list of foreign fields to follow. By default will retrieve all fields [ArrayRef]
    my $child_tables          = $args{-child_tables} || '';             # Indicate the list of child tables to follow [ArrayRef]
    my $child_fields          = $args{-child_fields} || '';             # Indicate the list of child fields to follow. By default will retrieve all fields [ArrayRef]
    my $condition             = $args{-condition} || 1;
    my $multiple              = $args{-multiple} || 0;
    my $order                 = $args{-order_by};
    my $group                 = $args{-group_by};
    my $limit                 = $args{-limit};
    my $refresh               = $args{-refresh} || 0;                   # Do not rebuild query - just do the last query done
    my $count_only            = $args{-count_only} || 0;                # Return number of rows returned, but do not retrieve data
    my $debug                 = $args{-debug} || $self->{debug} || 0;
    my $left_join_tables      = $args{-left_join_tables};
    my $left_join_fields      = $args{-left_join_fields} || '';
    my $force                 = $args{-force};
    my $quick_load            = $args{-quick_load};                     ## do not connect to referencing tables
    my $include_custom_tables = $args{-include_custom_tables};

    if ( $self->{loaded} && !$force ) { return $self; }

    #    if ($quick_load) { $child_tables = ''; $left_join_tables = ''; }
    my $dbc = $self->{dbc};

    # error check on limit
    if ( $limit && $limit !~ /^[\d\,]+$/ ) {
        return;
    }

    if ($include_custom_tables) {
        my $object = $include_custom_tables;
        my $id     = $self->{id};

        if ( !$id ) { Message("cannot get custom tables without id") }
        else {
            my ($type) = $dbc->Table_find( $object, "${object}_Type", "WHERE ${object}_ID = $id", -debug );
            if ( $type =~ /^Clone|Extraction$/ ) { $type .= '_Sample' }
            ## type should match exactly sub_table name (enabling automatic customization without affecting code)
            my ($custom_table)  = $dbc->Table_find( 'DBTable,DBField', 'DBTable_Name', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$type' and Field_Name like 'FK_Sample__ID'",           -debug => $debug );
            my ($custom_table2) = $dbc->Table_find( 'DBTable,DBField', 'DBTable_Name', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name = '${type}_$object' and Field_Name like 'FK_Sample__ID'", -debug => $debug );
            $custom_table ||= $custom_table2;    ## allow for variation (eg Sample_Type = Clone   ->   Clone OR Clone_Sample sub_table)

            if ($custom_table) {
                $self->add_tables($custom_table);

                my @custom_details = $dbc->Table_find( 'DBTable,DBField', 'DBTable_Name', "WHERE  FK_DBTable__ID=DBTable_ID AND Field_Name like 'FK_${custom_table}__ID'", -distinct => 1, -debug => $debug );
                Message("Including $custom_table + @custom_details");

                foreach my $table (@custom_details) {
                    ## add custom sub-tables if defined (according to standard format) ##
                    $self->left_join( $table, -condition => "$table.FK_${custom_table}__ID = ${custom_table}_ID" );
                }
            }
        }
    }
    $left_join_tables ||= $self->{left_joins};

    ## load primary value if it is not already defined ##
    if ( !$self->primary_value ) { $self->primary_value( -table => $self->{DBobject}, -value => $self->{id} ) }

    unless ($refresh) {
        my @conditions = ($condition);

        unless ( $args{-condition} ) {
            ### Build condition based on primary value by default
            my $values = $self->primary_values();
            foreach my $table ( keys %$values ) {
                ## dynamically figure out how to join this table...
                my $primary_field = $self->primary_field($table);

                if ( $values->{$table} ) {
                    my $primary_value = $values->{$table};
                    if ($primary_value) {
                        push( @conditions, "$table.$primary_field in ('$primary_value')" );
                        Message("Auto-setting condition: $conditions[-1]") if $debug;
                    }
                }
            }
            if ($debug) { Message("Load Condition: @conditions"); print HTML_Dump $values; }
        }

        my $tables_list = Cast_List( -list => $self->{tables}, -to => 'arrayref' );
        $field_ref        = Cast_List( -list => $field_ref,        -to => 'arrayref' ) if $field_ref;
        $FK_tables        = Cast_List( -list => $FK_tables,        -to => 'arrayref' ) if $FK_tables;
        $FK_fields        = Cast_List( -list => $FK_fields,        -to => 'arrayref' ) if $FK_fields;
        $child_tables     = Cast_List( -list => $child_tables,     -to => 'arrayref' ) if $child_tables;
        $child_fields     = Cast_List( -list => $child_fields,     -to => 'arrayref' ) if $child_fields;
        $left_join_tables = Cast_List( -list => $left_join_tables, -to => 'arrayref' ) if $left_join_tables;
        $left_join_fields = Cast_List( -list => $left_join_fields, -to => 'arrayref' ) if $left_join_fields;

        my @fields_list = $field_ref ? @$field_ref : @{ $self->fields( -include_joins => 1 ) };
        my $i = 0;
        foreach my $field (@fields_list) {
            if ( $field =~ /^(.+) as (.+)$/i ) {
                ## format ok
            }
            elsif ( defined $self->{Field_Alias}->{$field} ) {
                $field = "$self->{Field_Alias}->{$field} AS $field";
            }
            elsif ( $field =~ /(.+)\.(.+)/ ) {
                $field = "$field AS '$field'";    ### fully qualify tablename in retrieved key
            }
            else {
                ## leave field name as it is...
            }
        }

        if ($FK_tables) {                         ### Add FK tables to tables list
            push( @$tables_list, @$FK_tables );
            $tables_list = unique_items($tables_list);
        }
        if ($child_tables) {                      ### Add child tables to tables list
            push( @$tables_list, @$child_tables );
            $tables_list = unique_items($tables_list);
        }

        if ($left_join_tables) {                  ### Add left join tables to tables list
            push( @$tables_list, @$left_join_tables );
            $tables_list = unique_items($tables_list);
        }

        $tables_list = Cast_List( -list => $tables_list, -to => 'string' );

        my @retrieve_tables;

        foreach my $table ( split /,/, $tables_list ) {
            unless ($table) {next}                ### blank table causing error (?)...
            unless ( grep /^$table$/, @{ $self->{left_joins} } ) { push( @retrieve_tables, $table ) }
        }
        $self->{retrieve_tables} = join ",", @retrieve_tables;

        # Get the join between the tables and then build the where clause
        my @excluded_tables;
        if ( $self->{explicit_joins} ) { @excluded_tables = keys %{ $self->{explicit_joins} }; }

        my $join_condition = $dbc->get_join_condition( $self->{retrieve_tables}, $self->{join_conditions}, $self->{no_joins}, -exclude => \@excluded_tables, -debug => $debug );

        if ($join_condition) { push( @conditions, $join_condition ) }
        
        if ($FK_tables) {
            foreach my $FK_table (@$FK_tables) {
                my @fields = Table_find_array( $dbc, 'DBTable,DBField', ['Field_Name'], "where DBTable_ID=FK_DBTable__ID and DBTable_Name = '$FK_table' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'", -debug => $debug );
                foreach my $FK_field (@fields) {
                    $FK_field = "$FK_table.$FK_field";
                    ## add field if specified (or if none specified)
                    Message("Warning 1: add $FK_table . $FK_field");
                    if ( !$FK_fields || grep /^$FK_field$/, @$FK_fields ) { push( @fields_list, "$FK_field As '$FK_field'" ) }
                }
            }
        }
        if ($child_tables) {
            foreach my $child_table (@$child_tables) {
                my @fields = Table_find_array( $dbc, 'DBTable,DBField', ['Field_Name'], "WHERE DBTable_ID=FK_DBTable__ID and DBTable_Name = '$child_table' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'", -debug => $debug );
                foreach my $child_field (@fields) {
                    $child_field = "$child_table.$child_field";
                    Message("Warning 2: add $child_table . $child_field");
                    ## add field if specified (or if none specified)
                    if ( !$child_fields || grep /^$child_field$/, @$child_fields ) {
                        push( @fields_list, "$child_field As '$child_field'" );
                    }
                }
            }
        }

        ## add fields from left joined tables
        if ($left_join_tables) {
            foreach my $left_join_table (@$left_join_tables) {
                my @fields
                    = Table_find_array( $dbc, 'DBTable,DBField', ['Field_Name'], "WHERE DBTable_ID=FK_DBTable__ID and DBTable_Name = '$left_join_table' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'", -debug => $debug );
                foreach my $left_join_field (@fields) {
                    $left_join_field = "$left_join_table.$left_join_field";
                    ## add field if specified (or if none specified)
                    if ( !$left_join_fields || grep /^$left_join_field$/, @$left_join_fields ) {
                        push( @fields_list, "$left_join_field As '$left_join_field'" );
                    }
                }
            }
        }

        @fields_list = @{ unique_items( \@fields_list ) };

        if ( !@fields_list ) { Call_Stack(); return $self->{dbc}->warning("no fields to retrieve..."); }

        my $group_by;
        if ($group) { $group_by = "GROUP BY $group" }

        $condition = join ' AND ', @conditions;

        $self->{retrieve_fields} = \@fields_list;

        if ( $self->{left_joins} ) {
            foreach my $index ( 1 .. int( @{ $self->{left_joins} } ) ) {
                my $left_join      = $self->{left_joins}->[ $index - 1 ];
                my $join_condition = $self->{left_join_conditions}->[ $index - 1 ];
                $self->{retrieve_tables} .= " LEFT JOIN $left_join ON $join_condition";
            }
        }
        $self->{retrieve_condition} = "WHERE $condition $group_by";
        $self->{retrieve_query}     = "SELECT ";
        $self->{retrieve_query} .= join ',', @{$self->{retrieve_fields}};
        $self->{retrieve_query} .= " FROM $self->{retrieve_tables} $self->{retrieve_condition}";
    
    }

    # allow definition of order by and limit when refreshing
    if ($limit) {
        $self->{limit} = "LIMIT $limit";
    }
    elsif ( ( !$multiple ) && ( !$self->{limit} ) ) {
        $self->{limit} = "LIMIT 1";
    }
    else {
        $self->{limit} = "";
    }
    if ($order) {
        $self->{order_by} = " ORDER BY $order ";
    }
    else {
        $self->{order_by} = "";
    }

    my @retrieve_fields = @{ $self->{retrieve_fields} };

    my %info;

    # if count_only, then just do a count(*)
    if ($count_only) {
        %info = &Table_retrieve( $dbc, $self->{retrieve_tables}, ["count(*) as num_records"], "$self->{retrieve_condition} $self->{order_by} $self->{limit}", -debug => $debug );
        print ">>>>" . HTML_Dump( \%info ) if $debug;
        return $info{"num_records"}[0];
    }
    else {
        # proceed normally
        %info = &Table_retrieve( $dbc, $self->{retrieve_tables}, $self->{retrieve_fields}, "$self->{retrieve_condition} $self->{order_by} $self->{limit}", -debug => $debug );
        if ( !%info ) {

            #	    $dbc->session->warning("Error autoloading:  Check query:  SELECT count(*) FROM $self->{retrieve_tables} $self->{retrieve_condition} $self->{order_by} $self->{limit}");
            #	    Call_Stack();
        }

        print ">>>>" . HTML_Dump( \%info ) if $debug;
    }

    $self->{record_count} = 0;
    my %ret;

    if (%info) {
        foreach my $field ( sort { $a <=> $b } keys %info ) {

            #	    push(@{$self->{fields_list}}, $field);
            # if this is a view field, put it into the {FK_view} hash
            my $rtable = "";
            my $rfield = "";
            ( $rtable, $rfield ) = $self->_resolve_field( \$field, -default_table => $self->{retrieve_tables} );

            my @values = @{ $info{$field} };

            #@{$self->{fields}->{$rtable}->{$rfield}->{value}} = @values;
            @{ $self->{fields}->{$rtable}->{$rfield}->{values} } = @values;

            $self->{record_count} = int( @{ $info{$field} } );

            #Set the record index if this is the primary field of the table
            if ( $self->primary_field($rtable) eq $rfield ) {
                my $i = 0;
                map { $self->{record_index}->{$rtable}->{$_} = $i++ } @values;
            }
        }
        foreach my $field ( keys %info ) {
            my $rfield = $field;
            $rfield =~ s/^\'(.*)\'$/$1/;
            if ($multiple) {    ## Return format:  $info{"Library.Library_Name"} = ['CN001']
                $ret{$rfield} = $info{$field};
            }
            else {              ## Return format:  $info{"Library.Library_Name"} = 'CN001'
                $ret{$rfield} = $info{$field}->[0];
            }
        }
        $self->{loaded} = 1;
        return \%ret;
    }
    else {

        return 0;
    }
}

######################################
# Insert new records into the database
# Returns the number of rows affected
######################################
sub insert {
#############
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $dbc    = $self->{dbc};
    my $tables = $args{-tables} || $self->{tables};
    if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }    ## added recently - didn't work without this when pooling sources... ?

    my $include_tables = $args{-include_tables} || $tables;
    my $exclude_tables = $args{-exclude_tables};
    my $no_triggers    = $args{-no_triggers};

    $include_tables = Cast_List( -list => $include_tables, -to => 'arrayref' );
    $exclude_tables = Cast_List( -list => $exclude_tables, -to => 'arrayref' );

    ### Batch inserting records
    my @insert_fields;
    my %insert_values;

    my %values = %{ $self->values( -records => '*', -include_tables => $include_tables, -exclude_tables => $exclude_tables ) };
    my %ret;

    foreach my $field ( keys %values ) {
        my $defined = 0;
        foreach my $val ( @{ $values{$field} } ) {
            if ( defined $val ) { $defined++ }
        }
        unless ($defined) {next}    ## skip fields for which ALL values are undefined ##

        my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
        unless ( $self->_check_inclusion( -item => $rtable, -include_list => $include_tables, -exclude_list => $exclude_tables ) ) {next}    ### Exclude tables

        if ( grep /^$rtable$/, @{ $self->{tables} } ) {
            my ( $reftable, $reffield ) = foreign_key_check( -dbc => $dbc, -field => $rfield );
            if ( $reftable && ( grep /^$reftable$/, @{$include_tables} ) && ( $rtable ne $reftable ) ) {next}                                ### Skip FK field if reference another table in the tables list
            push( @insert_fields, $rfield );
            my $i = 1;
            map { push( @{ $insert_values{$i} }, $_ ); $i++; } @{ $values{$field} };
        }
    }

    my $tables_list = Cast_List( -list => $self->{tables}, -to => 'string' );

    $dbc->smart_append( -tables => $tables_list, -fields => \@insert_fields, -values => \%insert_values, -autoquote => 1, -no_triggers => $no_triggers );

    ### Finally obtain the new IDs and stick them into the object
    foreach my $table ( split /,/, $tables_list ) {
        unless ( $self->_check_inclusion( -item => $table, -include_list => $include_tables, -exclude_list => $exclude_tables ) ) {next}    ### Exclude tables
        my $count         = 0;
        my $primary_field = $self->primary_field($table);
        foreach my $newid ( @{ $dbc->newids($table) } ) {
            $self->primary_value( -table => $table, -value => $newid, -index => $count );
            push( @{ $ret{newids}{$table} }, $newid );
            $count++;
        }
        $ret{$table} = $count;
    }

    $self->{newids} = $dbc->{newids};                                                                                                       # Update the new IDs

    return \%ret;
}

######################################
# Update existing records
# Returns the number of rows affected
######################################
sub update {
#############
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};
    if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }

    my $fields         = $args{-fields} || $self->{fields_list};    ### Fields to be updated
    my $values         = $args{ -values };
    my $records        = $args{-records};                           # The records to get or set (e.g. $record->{Library.Library_Name} = ['CG001','CG002'])
    my $i              = $args{ -index };
    my $include_tables = $args{-include_tables};                    ### Include these tables to update
    my $exclude_tables = $args{-exclude_tables};                    ### Exclude these tables from update
    my $no_triggers    = $args{-no_triggers};

    $include_tables = Cast_List( -list => $include_tables, -to => 'arrayref' );
    $exclude_tables = Cast_List( -list => $exclude_tables, -to => 'arrayref' );

    my @indices;
    $i = Cast_List( -list => $i, -to => 'arrayref' );
    if ( !$i && !$records ) { $i = [0] }                            # Default to index zero if no index and records specified.

    if   ($i) { @indices = @$i }
    else      { @indices = @{ $self->_get_indices( -records => $records ) } }

    $fields = Cast_List( -list => $fields, -to => 'arrayref' );

    my @tables;
    foreach my $field (@$fields) {
        my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
        unless ( $self->_check_inclusion( -item => $rtable, -include_list => $include_tables, -exclude_list => $exclude_tables ) ) {next}    ### Exclude tables
        unless ( grep /^$rtable$/, @tables ) { push( @tables, $rtable ) }
    }

    ### Start transaction if not already started ###
    $dbc->start_trans( -name => 'DB_Object_update' );

    my %updated;
    foreach my $table (@tables) {
        unless ( $self->_check_inclusion( -item => $table, -include_list => $include_tables, -exclude_list => $exclude_tables ) ) {next}     ### Exclude tables
        my $primary = $self->primary_field($table);

        foreach my $i (@indices) {
            my $condition = "where 1";
            my @update_fields;
            my @update_values;
            my $primary_value = $self->primary_value( -table => "$table", -index => $i );
            $condition .= " and $primary = '$primary_value'";
            my $field_index = 0;
            foreach my $field (@$fields) {
                my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
                if ( $rtable eq $table ) {
                    if ($values) {    ### If value is provided, then update the value inside the object as well
                        $self->{fields}->{$rtable}->{$rfield}->{values}->[$i] = $values->[$field_index];
                    }
                    my $value = $self->{fields}->{$rtable}->{$rfield}->{values}->[$i];
                    push( @update_fields, $rfield );
                    push( @update_values, $value );
                }
                $field_index++;
            }
            $updated{$table} += $dbc->Table_update_array( $table, \@update_fields, \@update_values, $condition, -autoquote => 1, -no_triggers => $no_triggers );
        }
    }

    $dbc->finish_trans( -name => 'DB_Object_update' );

    return \%updated;
}

######################################
# Delete an existing record
# Returns the number of rows affected
######################################
sub delete {
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};
    if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }

    my $records = $args{-records};    # The records to get or set (e.g. $record->{Library.Library_Name} = ['CG001','CG002'])
    my $i       = $args{ -index };

    my @indices;
    $i = Cast_List( -list => $i, -to => 'arrayref' );
    if ( !$i && !$records ) { $i = [0] }    # Default to index zero if no index and records specified.

    if   ($i) { @indices = @$i }
    else      { @indices = @{ $self->_get_indices( -records => $records ) } }

    my %records;
    foreach my $table ( reverse @{ $self->{tables} } ) {    ### Start deleting from the table that is last in the list
        my $primary = $self->primary_field($table);
        if ( $self->{fields}->{$table}->{$primary}->{values} ) {
            @{ $records{"$table.$primary"} } = map { $self->{fields}->{$table}->{$primary}->{values}->[$_] } @indices;
        }
    }

    my $deleted = $dbc->DB_delete( -tables => $self->{tables}, -records => \%records, -autoquote => 1 );

    if ($deleted) {
        foreach my $table ( keys %$deleted ) {
            if ( $deleted->{$table} > 0 ) {
                map { $self->{fields}->{$table}->{$_}->{values} = undef } keys %{ $self->{fields}->{$table} };    ## Remove the values from the object as well
            }
        }
    }

    return $deleted;
}

#######################
sub db_table {
#######################
    #
    # Return the database table name [String]
    #
    Call_Stack();
    my $self = shift;

    return $self->{table};
}

#######################
sub primary_fields {
#######################
    #
    # Return the primary fields [HashRef]
    #
    my $self = shift;

    return $self->{primary_fields};
}

#######################
sub primary_field {
#######################
    #
    # Return the primary key field [String]
    #
    my $self = shift;
    my $table = shift || $self->{tables}->[0];

    if ( $self->{primary_fields}->{$table} ) { return $self->{primary_fields}->{$table} }

    my ($primary_field) = $self->{dbc}->get_field_info( -table => $table, -type => 'Primary' );
    $self->{primary_fields}->{$table} = $primary_field;

    return $primary_field;
}

#######################
sub primary_values {
#######################
    #
    # Set or return the primary key values
    #
    my $self = shift;
    my %args = @_;

    my $tables   = $args{-tables} || $self->{tables};
    my $values   = $args{ -values };
    my $multiple = $args{-multiple} || 0;

    $tables = Cast_List( -list => $tables, -to => 'arrayref' );
    $values = Cast_List( -list => $values, -to => 'arrayref' );

    my %ret;

    my $i = 0;

    foreach my $table ( @{$tables} ) {
        $table =~s/.*\:\://;  ## truncate scope if included ##
        if ( !$table ) {next}    ## in case blank table gets passed in (which breaks code)
        my $primary_field = $self->{dbc}->primary_field($table);
        if ( !$primary_field ) {
            ($primary_field) = $self->{dbc}->get_field_info( -table => $table, -type => 'Primary' );
        }
        if ( !$primary_field ) {
            $self->{dbc}->warning("Could Not resolve primary field for $table");
            next;
        }

        if ( grep /^$table$/, @$tables ) {
            if ($values) {       ## Set primary values
                $self->values( -fields => "$table.$primary_field", -values => $values->[$i] );
            }

            if ($multiple) {
                $ret{$table} = $self->values( -field => "$table.$primary_field" );    ### Return primary values
            }
            else {
                $ret{$table} = $self->value( -field => "$table.$primary_field" );     ### Return primary values
            }
        }
        $i++;
    }

    return \%ret;
}

#######################
sub primary_value {
#######################
    #
    # Set or return the primary key value [String]
    #
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'table,value,records,multiple,index' );
    my $table    = $args{-table} || $self->{tables}->[0];
    my $value    = $args{-value};
    my $records  = $args{-records};
    my $multiple = $args{-multiple};
    my $index    = $args{ -index };

#    if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }
    
    $table =~s/.*\:\://;

    $table = Cast_List( -list => $table, -to => 'string' );
    $value = Cast_List( -list => $value, -to => 'string' );

    my $primary_field = $self->{dbc}->primary_field($table);
    
    if ( !$primary_field ) {
        ($primary_field) = $self->{dbc}->get_field_info( -table => $table, -type => 'Pri' );
    }

    if ( !$primary_field ) { return $self->{dbc}->warning("Could not Resolve primary field for $table"); }

    if ($value) {
        if ($records) {
            return $self->value( -field => "$table.$primary_field", -value => $value, -records => $records );
        }
        elsif ( defined $index ) {
            return $self->value( -field => "$table.$primary_field", -value => $value, -index => $index );
        }
        else {
            return $self->value( -field => "$table.$primary_field", -value => $value );
        }
    }

    if ($records) {
        return $self->value( -field => "$table.$primary_field", -records => $records, -multiple => $multiple );
    }
    elsif ( defined $index ) {
        return $self->value( -field => "$table.$primary_field", -index => $index, -multiple => $multiple );
    }

    return $self->value( -field => "$table.$primary_field" );
}

######################
#
# Dynamically increase the scope of the fields...
# Add to scope of tables included in the current object (should be done right after construction if possible)
#
#########################
sub add_tables {
###################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'tables,condition' );
    my $tables    = $args{-tables};
    my $condition = $args{-condition};                                  ## optional (supply join condition - otherwise determined automatically)
    my $debug     = $args{-debug};
    my $debug     = $args{-condition};

    #    Message("Add $tables ($condition)");
    my @new_tables     = Cast_List( -list => $tables,    -to => 'array' );
    my @new_conditions = Cast_List( -list => $condition, -to => 'array' );

    foreach my $new_table (@new_tables) {
        unless ( grep /^$new_table$/, @{ $self->{tables} } ) { push( @{ $self->{tables} }, $new_table ) }
        $self->_initialize();
    }

    if ($condition) {
        foreach my $index ( 0 .. $#new_tables ) {
            my $new_condition = $new_conditions[$index];
            if ($new_condition) {
                push( @{ $self->{join_conditions} }, $new_conditions[$index] );
                $self->no_join( $new_tables[$index] );
            }
        }
    }

    if ( int(@new_tables) == 1 && $new_conditions[0] ) {
        if ( $new_conditions[0] =~ /(\w+)\.FK(\w*)_$new_tables[0]__/ ) {
            ## do not autojoin these tables if explicit join condition supplied ##
            $self->no_joins("$new_tables[0], $1");
        }
        else {
            $self->{explicit_joins}{ $new_tables[0] } = $new_conditions[0];
        }
    }

    return 1;
}

######################
#
# Dynamically increase the scope of the fields by left joining another table
#
# Return 1 on success
#########################
sub left_join {
###################
    my $self            = shift;
    my %args            = filter_input( \@_, -args => 'table,to,condition' );
    my $table           = $args{-table};                                        ## table to left join
    my $reference_table = $args{-to};                                           ## table in current list of tables
    my $join_condition  = $args{-condition};                                    ## (optional) condition - may be supplied instead of reference table

    push( @{ $self->{left_joins} }, $table );
    if ($join_condition) {
        push( @{ $self->{left_join_conditions} }, $join_condition );
    }
    else {
        $join_condition = join ' AND ', $self->get_join_conditions( $table, $reference_table );
        push( @{ $self->{left_join_conditions} }, $join_condition );
    }

    #    push(@{$self->{tables}},$table);

    $self->_initialize();

    return 1;
}

#######################
sub fields {
#######################
    #
    # Return the database fields [Array]
    #
    my $self = shift;
    my %args = &filter_input( \@_ );

    # this is not used
    #my $include_joins = $args{-include_joins};
    my @list = @{ $self->{fields_list} };
   
    if ( !@list ) {
        my @tables = Cast_List( -list => $self->{tables}, -to => 'array' );
        my @full_list;
        foreach my $table (@tables) {
            ## pull up tables in specified order, and field in field_order as defined in DB_field
            my @list = $self->{dbc}->Table_find_array( 'DBField', ["Concat(Field_Table, '.', Field_Name)"], "WHERE Field_Table = '$table' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT LIKE '%Removed%' ORDER BY Field_Order" );
            push @full_list, @list;
        }
        $self->{fields_list} = \@full_list;
    }

    return $self->{fields_list};
}

#######################
sub fields_info {
#######################
    #
    # Return the fields info
    #
    my $self = shift;

    return $self->{fields};
}

#
# Set or Return the value for ONE specified field
# - If value is specified, then the corresponding field is set with the specified value
# - If value is not specified, then the current value of the field is returned in a scalar
#
#######################
sub value {    ### For now just handle single record
#######################
     my $self = shift;
# if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }


    my %args = &filter_input( \@_, -args => 'field,value,records,index', -mandatory => 'field' );

    my $field   = $args{-field};
    my $value   = $args{ -value };
    my $records = $args{-records};    # The records to get or set (e.g. $record->{Library.Library_Name} = ['CG001','CG002'])
    my $i       = $args{ -index };

    if ( $field && !ref($field) && !defined $value && !defined $i && !defined $records ) {    # simplest case - just pass in a field name
        my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
        my $ret;
        if ( exists $self->{fields}->{$rtable}->{$rfield}->{values} ) {
            $ret = $self->{fields}->{$rtable}->{$rfield}->{values}->[0];
        }
        return $ret;
    }

    if ( ref($field) =~ /array/i or ref($value) =~ /array/i ) {
        ### <CONSTRUCTION> Phasing out...
        print "Content-type: text/html\n\n";
        Message("Error: Please submit an issue regarding this matter");
        $field = Cast_List( -list => $field, -to => 'string' );
        $value = Cast_List( -list => $value, -to => 'string' );
        Call_Stack();
    }

    $i = Cast_List( -list => $i, -to => 'arrayref' );

    if ( !defined $i && !$records ) { $i = [0]; }    # Default to index zero if no index and records specified.

    my @indices;

    if ( defined $i ) {
        @indices = @$i;
    }
    else {
        @indices = @{ $self->_get_indices( -records => $records ) };
    }

    my $ret;
    
    my ( $rtable, $rfield ) = $self->_resolve_field( \$field );

    if ( $field && ( exists $self->{fields}->{$rtable}->{$rfield} ) && defined $value ) {    # Set
        map { $self->{fields}->{$rtable}->{$rfield}->{values}->[$_] = $value } @indices;
        @$ret = map { $self->{fields}->{$rtable}->{$rfield}->{values}->[$_] } @indices;
        $self->_update_record_count();
        return @$ret;
    }
    elsif ( $field && ( exists $self->{fields}->{$rtable}->{$rfield}->{values} ) ) {         # Get
        if ( @indices > 1 ) {
            @$ret = map { $self->{fields}->{$rtable}->{$rfield}->{values}->[$_] } @indices;
            return @$ret;
        }
        else {
            $ret = $self->{fields}->{$rtable}->{$rfield}->{values}->[ $indices[0] ];
            return $ret;
        }
    }

}

#########################
# Set or Get values from the database
#
# Return: hash (keys = fields (default) or record_numbers (depending on 'array_by' option)
#   (keys in turn point to either scalars (default) or array_references (if 'array_by'='record' OR multiple option chosen)
#######################
sub values {
#######################
    #
    # Set or Return the values for the specified fields
    # - If values are specified, then the corresponding fields are set with those values
    # - If values are not specified, then the values of the fields are returned in a Hashref
    #
    my $self = shift;
    my %args = @_;

    if ( $self->{table} ) { Call_Stack();  Message("phased out- check with Administrators"); return 0; }

    my $fields         = $args{ -fields };          # Fields to be inserted into
    my $values         = $args{ -values };          # Values to be inserted
    my $records        = $args{-records};           # The records to get or set (e.g. $record->{Library.Library_Name} = ['CG001','CG002'])
    my $index          = $args{ -index };           # Explicitly specify the index
    my $include_tables = $args{-include_tables};    # Include these tables when retrieving the values
    my $exclude_tables = $args{-exclude_tables};    # Exclude certain tables when retrieving the values

    if ( ref($fields) =~ /array/i or ref($values) =~ /array/i ) {
        ### <CONSTRUCTION> Phasing out...
        $fields = Cast_List( -list => $fields, -to => 'arrayref' );
        $values = Cast_List( -list => $values, -to => 'arrayref' );

        #        print "Content-type: text/html\n\n";
        #        Message("Error: Please submit an issue regarding this matter");
        #        Call_Stack();
        # ???
    }

    $include_tables = Cast_List( -list => $include_tables, -to => 'arrayref' );
    $exclude_tables = Cast_List( -list => $exclude_tables, -to => 'arrayref' );

    my @indices;
    $index = Cast_List( -list => $index, -to => 'arrayref' );
    if ( !$index && !$records ) { $index = [0] }    # Default to index zero if no index and records specified.

    if   ($index) { @indices = @$index }
    else          { @indices = @{ $self->_get_indices( -records => $records ) } }

    my %vals;
    if ( $fields && $values ) {                     # Set
        my $i = 0;
        foreach my $field (@$fields) {
            my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
            map { $self->{fields}->{$rtable}->{$rfield}->{values}->[$_] = $values->[$i] } @indices;
            $i++;
        }
    }
    else {                                          # Get
        foreach my $table ( keys %{ $self->{fields} } ) {
            unless ( $self->_check_inclusion( -item => $table, -include_list => $include_tables, -exclude_list => $exclude_tables ) ) {next}    ### Exclude tables
            foreach my $field ( keys %{ $self->{fields}->{$table} } ) {
                ### If users specified a list of fields check whether this is what they want
                if ( $fields && !grep /^$table\.$field$/, @{$fields} ) {next}
                if ( $self->{fields}{$table}{$field}{options} =~ /obsolete|removed/i ) {next}

                if (@indices) {                                                                                                                 # Return the specified records
                    if ( $index && ( @$index == 1 ) ) {                                                                                         # If specifically request ONE record
                        $vals{"$table.$field"} = $self->{fields}->{$table}->{$field}->{values}->[ $indices[0] ];
                    }
                    else {
                        map { push( @{ $vals{"$table.$field"} }, $self->{fields}->{$table}->{$field}->{values}->[$_] ) } @indices;
                    }
                }
            }
        }
    }

    $self->_update_record_count();
    return \%vals;
}

#################################################################################
# Set multiple values - Allow user to set different set of values for each record
# Arguments:
# - fields [arrayref] (qualified with table name)
# - values [hashref] (1-based index)
#################################################################################
sub set_multi_values {
####################
    my $self = shift;
    my %args = @_;

    my $fields = $args{ -fields };
    my $values = $args{ -values };

    $fields = Cast_List( -list => $fields, -to => 'arrayref' );

    foreach my $index ( sort { $a <=> $b } keys %$values ) {
        $self->values( -fields => $fields, -values => $values->{$index}, -index => $index - 1 );
    }
    $self->_update_record_count();
}

#######################
sub exist {
#######################
    #
    # Test whether a particular record is in the database table
    # Returns the number of matched records [Int]
    #
    my $self = shift;

    my %args    = filter_input( \@_, -args => 'table,records,index' );
    my $table   = $args{-table};
    my $records = $args{-records};                                       # The records to get or set (e.g. $record->{Library.Library_Name} =['CG001','CG002'])
    my $i       = $args{ -index };

    if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }

    $i = Cast_List( -list => $i, -to => 'arrayref' );
    if ( !$i && !$records ) { $i = [0] }                                 # Default to index zero if no index and records specified.

    my @indices;

    if   ($i) { @indices = @$i }
    else      { @indices = @{ $self->_get_indices( -records => $records ) } }

    unless ($table) { $table = $self->{tables}->[0] }
    my $condition = "where 1";

    foreach my $field ( keys %{ $self->{fields}->{$table} } ) {
        if ( $self->{fields}->{$table}->{$field}->{values} ) {
            my @values = map { $self->{fields}->{$table}->{$field}->{values}->[$_] } @indices;
            $condition .= " and $field in ('" . join( "','", @values ) . "')";
        }
    }

    my ($count) = &Table_find( $self->{dbc}, $table, 'Count(*)', $condition );

    return $count;
}

##################
sub clone {
##################
    #
    # Clone the object
    #
    my $self = shift;
    my %args = @_;

    my $clone = $self->SUPER::clone();

    $clone->{dbc} = $args{ -dbc };    # Recreate the database handle [ObjectRef]

    return $clone;
}

#################
sub sort_object {
#################
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $self->{dbc};
    my $sort_by = $args{-by};
    my $order   = $args{-order} || 'asc';

    unless ($sort_by) {
        return;
    }

    my ( $rtable, $rfield ) = $self->_resolve_field( \$sort_by );

    # put everything that needs to be sorted into a convenient hash
    my %sort_hash;
    my $has_letters = 0;
    foreach my $index ( 1 .. $self->{record_count} ) {
        my $value = $self->{fields}{$rtable}{$rfield}{values}[ $index - 1 ];
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
    foreach my $field ( @{ $self->fields( -include_joins => 1 ) } ) {
        ( $rtable, $rfield ) = $self->_resolve_field( \$field );
        @{ $self->{fields}{$rtable}{$rfield}{values} } = @{ $self->{fields}{$rtable}{$rfield}{values} }[@sorted_keys];
    }
}

####################
sub get_attributes {
####################
    my $self = shift;

    my %args = &filter_input( \@_, -args => 'table,id' );
    my $table_ref = $args{-table} || $self->{tables};
    my $record_id = $args{-id};
    my @tables    = Cast_List( -list => $table_ref, -to => "array" );
    my $dbc       = $self->{dbc};

    # when providing an ID user should only specify 1 table
    if ( scalar(@tables) > 1 && $record_id ) {
        Message("Invalid input");
        return 0;
    }
    my @attributes;

    foreach my $table (@tables) {
        my $primary         = $Field_Info{$table}{Primary};
        my $id              = $record_id || $self->value($primary);
        my $attribute_table = $table . "_Attribute";
        ## adjust to work for non '_ID' tables (eg Library_Name) ##
        my ($fk_field) = $dbc->get_field_info( $table, undef, 'Primary' );
        $fk_field =~ s /$table/FK_$table\_/;
##
        if ( grep /^$attribute_table$/, $dbc->DB_tables() ) {
            my %attributes
                = Table_retrieve( $dbc, "$attribute_table,Attribute", [ "Attribute_ID", "Attribute_Name", "Attribute_Value", "$attribute_table" . "_ID", "Attribute_Access", "Attribute_Type" ], "WHERE FK_Attribute__ID=Attribute_ID and $fk_field = '$id'" );

            if ( exists $attributes{Attribute_ID}[0] ) {
                my @attribute_ID     = @{ $attributes{Attribute_ID} };
                my @attribute_Name   = @{ $attributes{Attribute_Name} };
                my @attribute_Value  = @{ $attributes{Attribute_Value} };
                my @attribute_access = @{ $attributes{Attribute_Access} };
                my @attribute_type   = @{ $attributes{Attribute_Type} };
                my @table_attr_id    = @{ $attributes{ $attribute_table . "_ID" } };

                for ( my $i = 0; $i < scalar(@attribute_ID); $i++ ) {
                    my $link;
                    my $value_display;

                    if ( $attribute_type[$i] =~ /^FK/i ) {
                        $value_display = $dbc->get_FK_info( -field => $attribute_type[$i], -id => $attribute_Value[$i] );
                    }
                    else {
                        $value_display = $attribute_Value[$i];
                    }

                    if ( $attribute_access[$i] eq 'Editable' ) {
                        $link = &Link_To( $dbc->config('homelink'), $value_display, "&cgi_application=SDB::Attribute_App&rm=Set+Attributes&Attribute_ID=$attribute_ID[$i]&ID=$record_id&Class=$table_ref", $Settings{LINK_COLOUR} );
                    }
                    else {
                        $link = $value_display;
                    }
                    push( @attributes, "<font size=-2>$attribute_Name[$i] = $link</font>" );
                }
            }
        }
    }

    return \@attributes;
}

#

#####################
sub display_Record {
#####################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $format     = $args{'-format'}   || 'html';
    my $show_nulls = $args{-show_nulls} || 0;                 # show 'field = value' pairs even when no value found (or value = 0)
    my $index      = $args{ -index }    || 1;                 # which record to retrieve ('index 1' => 1st record)
    my $table_ref  = $args{-tables}     || $self->{tables} || [];
    my $filename   = $args{-filename}   || 0;
    my $print      = $args{ -print };
    my $exclude            = $args{-exclude};                 # fields to exclude (or 'empty' to exclude zero values)
    my $truncate           = $args{ -truncate };              # truncate very long fields (eg. verbose descriptions)
    my $include_references = $args{-include_references};      # list of tables to include references for (if any) - set to '1' for all references...
    my $title              = $args{-title};
    my $include_joins      = $args{-include_joins} || 0;
    my $view_only          = $args{-view_only};               ## Do not display [Edit] links
    my $dbc                = $self->{dbc};
    my $debug              = $args{-debug};

    my @tables = @{$table_ref} ;
    
    if ( $include_joins && $self->{left_joins} ) { print "Added "; push( @tables, @{ $self->{left_joins} } ); }

    my @fields = @{ $self->fields( -include_joins => $include_joins ) };
    my $exclude_empty = 1 if $exclude eq 'empty';

    my %titles = $dbc->Table_retrieve( 'DBTable', [ 'DBTable_Name', 'DBTable_Title' ], "WHERE DBTable_Name IN ('" . join( "','", @tables ) . "')");
    %titles = %{ rekey_hash( \%titles, 'DBTable_Name' ) };

    unless ($title) {
        $title = "Data from " . join( ", ", map { $titles{$_}{DBTable_Title}[0] } @tables );
    }

    my $output;

    my $recordTable;
    if ( $format =~ /text/ ) {
        foreach my $field (@fields) {
            my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
            if ( $self->{fields}{$rtable}{$rfield}{options} =~ /Hidden|Obsolete|Removed/i ) {next}
            my $label = $self->{fields}->{$rtable}->{$rfield}->{prompt} || $field;
            my $value = $self->{fields}->{$rtable}->{$rfield}->{values}[ $index - 1 ];

            ## grab the specified index (in case of multiples)
            if ( $value || $show_nulls ) {
                $output .= sprintf "%20s", "$label";
                $output .= "\t=\t$value\n";
            }
        }
    }
    else {
        my %Info;
        my $showed_table;
        my @tableOrder;
        
        require SDB::HTML;

        foreach my $field (@fields) {
            my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
            unless ( grep /^$rtable$/, @tables ) {next}

            if ( $self->{fields}{$rtable}{$rfield}{options} =~ /Hidden|Obsolete|Removed/i ) {next}
            unless ( $showed_table eq $rtable ) {

                #record the table order to display them appropriately
                push( @tableOrder, $rtable );
                my $rtable_title = $titles{$rtable}{DBTable_Title}[0];
                my $row          = b("$rtable_title");
                my $link;
                unless ($view_only) {
                    my $search_list = $self->primary_value( -table => $rtable );
                    $link
                        = "[ "
                        . &Link_To( $dbc->config('homelink'), 'Edit', "&Search=1&Table=$rtable&Search+List=$search_list", $Settings{LINK_COLOUR}, ['newwin'] ) . " ]"
                        . SDB::HTML::hspace(10)
                        . Link_To( $dbc->config('homelink'), 'View Edits', "&cgi_application=SDB::DB_Object_App&rm=View+Changes&Table=$rtable&ID=$search_list" );

                    if ( defined $Field_Info{$rtable}{'FK_Rack__ID'} ) {
                        $link .= SDB::HTML::hspace(10) . Link_To( $dbc->config('homelink'), 'Storage_History', "&cgi_application=alDente::Rack_App&rm=Storage+History&Table=$rtable&ID=$search_list" );
                    }

                }

                push( @{ $Info{$rtable}{row} }, [ [ $row, $link ], $Settings{HIGHLIGHT_CLASS} ] );
                $showed_table = $rtable;

                if ( $include_references eq '1' || $include_references =~ /\b$rtable\b/ ) {
                    my $primary = $Field_Info{$rtable}{Primary};
                    my $id      = $self->value($primary);
                    my ( $ref_list, $detail_list ) = $dbc->get_references( $rtable, { $primary => $id } );
                    push( @{ $Info{$rtable}{row} }, [ [ 'Referenced By: ', $ref_list ] ] );
                }
            }
            my $prompt = $Field_Info{$rtable}{$rfield}{Prompt};
            my $desc   = $Field_Info{$rtable}{$rfield}{Description};
            $prompt ||= $field;
            my ( $ref_table, $ref_field ) = foreign_key_check( -dbc => $self->{dbc}, -field => $field );

            my $value = $self->value($field) || $self->value("$rtable.$rfield");

            if ( $prompt eq 'ID' ) {
                my ($FK_value) = get_FK_info( $self->{dbc}, "FK_$rtable" . "__ID", $value );
                unless ($view_only) {
                    $value = &Link_To( $dbc->config('homelink'), $value, "&Search=1&Table=$rtable&Search+List=$value", $Settings{LINK_COLOUR}, ['newwin'] );
                }
            }
            elsif ( $ref_table && $ref_field && $value ) {    ## FK field - deference and display link instead
                my ($FK_value) = get_FK_info( -dbc => $self->{dbc}, -field => $rfield, -id => $value );

                # Mario - Oct. 6/05
                # Link changed to go directly to object homepage rather than the info table
                #$value = &Link_To( $dbc->config('homelink'),$FK_value,"&Info=1&Table=$ref_table&Field=$ref_field&Like=$value",$Settings{LINK_COLOUR},['newwin']);
                if ($view_only) {
                    $value = $FK_value;
                }
                else {
                    $value =~ s/\+/%2B/g;
                    $value = &Link_To( $dbc->config('homelink'), $FK_value, "&HomePage=$ref_table&ID=$value", $Settings{LINK_COLOUR}, ['newwin'] );
                }
            }
            elsif ( $truncate && length($value) > $truncate ) {    ## truncate (only if NOT a link)... ##
                my $truncated_value = Show_Tool_Tip( substr( $value, 0, $truncate ) . "...", $value, -type => 'popover', -trigger => 'hover', -placement => 'auto' );
                $value = $truncated_value;
            }
            
            if ( defined $value || $show_nulls ) {
                push( @{ $Info{$rtable}{row} }, [ [ Show_Tool_Tip( $prompt, $desc ), $value ] ] );
            }

        }
        
        $recordTable = HTML_Table->new( -title => "$title" );
        foreach my $table (@tableOrder) {
            foreach my $row ( @{ $Info{$table}{row} } ) {
                $recordTable->Set_Row(@$row);
            }

            my ($primary) = $dbc->get_field_info( -table => $table, -type => 'Primary' );
            my $id = $self->value($primary);

            my $attributes = SDB::Attribute_Views::show_Attributes( $dbc, $table, $id );
            if ($attributes) {
                $recordTable->Set_sub_header( "$attributes", 'bgcolor="#FFFFCC"' );
            }
            if ( $table eq $tableOrder[0] && $tableOrder[1] ) {

                #          $recordTable->collapse_section('Show More ' . $BS->icon('collapse'), 'Hide Details ' . $BS->icon('collapse-top'));  ## remove paramters to only include dropdown caret ... ##
            }
        }
    }

    if ($filename) { $output .= $recordTable->Printout( $filename, $html_header ); }
    $output .= $recordTable->Printout(0);
    unless ($show_nulls) { $output .= "(excluded empty fields)" }

    if ($print) { print $output }
    return $output;
}

#########################################
# Return the number of records currently
# in the object
#########################################
sub record_count {
###############
    my $self = shift;

    return $self->{record_count};
}

###################################################################################
# Return new ids added to given table.
#  (optionally may specify the index if more than one updated.
#
# RETURN array_reference (unless index given in which case the scalar is returned)
###################################################################################
sub newids {
###############
    my $self  = shift;
    my $table = shift;
    my $index = shift;

    my @newids;
    if ($table) {    # Return newids for a particular table.
        if ( $self->{newids}->{$table} ) {
            @newids = @{ $self->{newids}->{$table} };
        }

        if   ( defined $index ) { return $newids[$index] }
        else                    { return \@newids }
    }
    else {           # Return newids for all tables.
        return $self->{newids};
    }
}

#########################################################
# Set/Get a list of tables not to be joined to each other
#
# The tables list should be a list of table pairs (eg Plate:Library) that should NOT be joined dynamically
# (these tables are either joined explicitly or are not joined in this context)
#
# Return: arrayref to list of table pairs
#########################################################
sub no_joins {
################
    my $self   = shift;
    my $tables = shift;    ## list of table pairs to exclude dynamic table joining for (eg. Plate:Library, Library:Original_Source)
    my $reset  = shift;

    if ($reset) { $self->{no_joins} = [] }    ## reset no_joins

    if ($tables) {
        $tables = Cast_List( -list => $tables, -to => 'arrayref' );
        push @{ $self->{no_joins} }, @$tables;
        $self->{no_joins} = unique_items( $self->{no_joins} );
    }

    return $self->{no_joins};
}

################
sub no_join {
################
    my $self  = shift;
    my $table = shift;

    my @table_list = Cast_List( -list => $table, -to => 'array' );
    foreach my $tab (@table_list) {
        push @{ $self->{no_joins} }, $tab;
    }
    return $self->{no_joins};
}

sub field_alias {
    my $self  = shift;
    my $alias = shift;

    if ($alias) { $self->{Field_Alias} = $alias }

    return $self->{Field_Alias};
}

################################
# This would be fairly generic and essentially be a simple wrapper for update_array to change the specified fields to the indicated values.
#
#
# $obj -> propogate_field(-class=>'Plate', -field=>['Plate_Status'], -value=>['On Hold'], -id=>\@main_ids);
################################
sub propogate_field {
################################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{ -dbc };
    my $class   = $args{-class};
    my $field   = $args{-field};
    my $value   = $args{ -value };
    my $confirm = $args{-confirm};

    my $ids      = Cast_List( -list => $args{-ids},      -to => 'string' );
    my $children = Cast_List( -list => $args{-children}, -to => 'string' );

    if ($confirm) {
        ## Add table update here
        my ($primary) = $dbc->get_field_info( $class, undef, 'PRI' );
        my $condition = "WHERE $primary in ($ids)";
        my $result = $dbc->Table_update_array( $class, $field, $value, $condition, -autoquote => 1 );
        if ($result) {
            my @fields = @$field if $field;
            my @values = @$value if $value;
            my $f_size = @fields;
            for my $index ( 0 .. $f_size - 1 ) {
                Message "$fields[$index] set to $values[$index] for $class with ids = $ids";
            }
        }
        else {
            Message "Failed to update records!";
        }
        return;

    }
    else {
        return SDB::DB_Object_Views::display_confirmation_page( -ids => $ids, -class => $class, -field => $field, -value => $value, -dbc => $dbc );
    }

}

#
# Allow inheritance of attributes for a specified attribute table ie. Sample_Attribute
################################
sub inherit_Attribute {
################################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $parent_ids       = Cast_List( -list => $args{-parent_ids}, -to => 'string' ) if $args{-parent_ids};    # Parent ID
    my $child_ids        = $args{-child_ids};                                                                  # Child ID
    my $attributes       = $args{-attributes};                                                                 # Attributes to inherit
    my $conflict_res     = $args{-conflict};                                                                   # this is enum ('ignore','combine') in case two attribute values are not the same
    my %set              = %{ $args{ -set } } if $args{ -set };                                                # Child IDs
    my @children         = Cast_List( -list => $child_ids, -to => 'Array' );
    my $table            = $args{-table} || $self->{tables}->[0];                                              #
    my $parent_count     = scalar( my @array = split ',', $parent_ids );
    my $attribute_object = $table;
    my $dbc              = $self->{dbc};

    unless ( $dbc->table_loaded( $attribute_object . "_Attribute" ) ) {

        ###### GOTTA PUT CHECK HERE TO MAKE SURE TABLE ACTUALLY HAS AN ATTRUBUTE
        return 1;
    }

    my $fk_field = $dbc->foreign_key( -table => $table );

    my $extra_condition = "";

    if ($attributes) {
        $attributes = Cast_List( -list => $attributes, -to => 'String', -autoquote => 1 );
        $extra_condition .= " AND Attribute_Name IN ($attributes) ";
    }

    #print Dumper $self->{primary_fields};

    ## get a list of inherited attributes for the table
    if ($parent_ids) {
        my %inherited_attributes = $dbc->Table_retrieve(
            "Attribute," . $attribute_object . "_Attribute",
            [ 'count(*) as count', 'Attribute_ID', 'Attribute_Value' ],
            "WHERE FK_Attribute__ID=Attribute_ID AND Inherited = 'Yes' and Attribute_Class = '$attribute_object' AND $fk_field IN ($parent_ids) $extra_condition GROUP BY Attribute_ID,Attribute_Value ORDER BY Attribute_ID,Attribute_Value"
        );

        if ( defined $inherited_attributes{Attribute_ID}[0] ) {

            my %attributes;
            my %attr_count;
            my $attribute_value;
            my @table_attributes = ();
            for ( my $i = 0; $i < @{ $inherited_attributes{Attribute_ID} }; $i++ ) {

                # if all parents have the same attribute value
                if ( $inherited_attributes{count}[$i] == $parent_count ) {
                    push( @{ $attributes{ $inherited_attributes{Attribute_ID}[$i] } }, $inherited_attributes{Attribute_Value}[$i] );
                    $attr_count{ $inherited_attributes{Attribute_ID}[$i] } = $parent_count;

                    # if not all parents have the same attribute value
                }
                else {
                    push( @{ $attributes{ $inherited_attributes{Attribute_ID}[$i] } }, $inherited_attributes{Attribute_Value}[$i] );
                    $attr_count{ $inherited_attributes{Attribute_ID}[$i] } = $attr_count{ $inherited_attributes{Attribute_ID}[$i] } + $inherited_attributes{count}[$i];
                }
            }

            foreach my $child_id (@children) {

                my $current_date = &now();

                $table .= "_Attribute";

                foreach my $attr ( keys %attributes ) {
                    if ( $conflict_res eq 'ignore' && int @{ $attributes{$attr} } > 1 ) {next}
                    my $attribute_list = SDB::Attribute::merged_Attribute_value( -dbc => $dbc, -id => $attr, -values => \@{ $attributes{$attr} } );
                    if ( !$attribute_list ) {next}
                    my @values = ( $child_id, $attr, $attribute_list, $current_date );
                    my @fields = ( $fk_field, 'FK_Attribute__ID', 'Attribute_Value', 'Set_DateTime' );

                    map {
                        if ($_)
                        {
                            push( @fields, $_ );
                            push( @values, $set{$_} );
                        }
                    } keys %set if ( $args{ -set } );
                    my @existing_attribute = $dbc->Table_find( $table, 'Attribute_Value', "WHERE $fk_field = $child_id and FK_Attribute__ID = $attr" );
                    if ( int(@existing_attribute) > 0 ) {
                        ## skip if the attribute is set already
                        next;
                    }
                    my $added = $dbc->Table_append_array( $table, \@fields, \@values, -autoquote => 1 );
                }
            }
        }
        else {
            return 0;
        }

        return 1;
    }
    else {
        return 0;
    }
}

##############################################
sub inherit_attributes_between_objects {
##############################################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{ -dbc };
    my $source       = $args{-source};
    my $source_id    = $args{-source_id};
    my $target       = $args{-target};
    my $target_id    = $args{-target_id};
    my $debug        = $args{-debug};
    my $skip_message = $args{-skip_message};

    my @src_fields = map {
        if ( $_ =~ /(.+)\.(\w+)/ ) { $_ = $2 }
    } $dbc->get_fields( -table => $source );

    my @src_attributes = $dbc->Table_find( 'Attribute', 'Attribute_Name', "WHERE Attribute_Class = '$source'" );

    my @target_fields = map {
        if ( $_ =~ /(.+)\.(\w+)/ ) { $_ = $2; }
    } $dbc->get_fields( -table => $target );

    my @target_attributes = $dbc->Table_find( 'Attribute', 'Attribute_Name', "WHERE Attribute_Class = '$target'" );

    my ($shared) = RGmath::intersection( [ @src_fields, @src_attributes ], [ @target_fields, @target_attributes ] );

    my ($primary_src)    = $dbc->get_field_info( -table => $source, -type => 'Primary' );
    my ($primary_target) = $dbc->get_field_info( -table => $target, -type => 'Primary' );

    my $inherited = 0;
    if ( !$source_id || !$target_id ) {
        ## Return list of shared field/attributes ##
        return $shared;
    }
    else {
        ## if source and target ids supplied - inherit field/attributes as required ... ##
        foreach my $share (@$shared) {
            my ( $src_value, $target_value );
            ## get source value ##
            if ( grep /^$share$/, @src_fields ) {
                ($src_value) = $dbc->Table_find( $source, $share, "WHERE $primary_src = $source_id" );
            }
            else {
                ($src_value) = $dbc->Table_find( "${source}_Attribute,Attribute", 'Attribute_Value', "WHERE FK_Attribute__ID=Attribute_ID AND FK_${source}__ID = $source_id AND Attribute_Class='$source' AND Attribute_Name = '$share'" );
            }
            if ( !$src_value ) {next}    ## not set...

            ## get target value ##
            if ( grep /^$share$/, @target_fields ) {
                ($target_value) = $dbc->Table_find( $target, $share, "WHERE $primary_target = $target_id" );
                if ( !$target_value ) { $inherited += $dbc->Table_update( $target, $share, $src_value, "WHERE $primary_target = $target_id" ) }
            }
            else {
                my $condit = "WHERE FK_Attribute__ID=Attribute_ID AND FK_${target}__ID = $target_id AND Attribute_Class='$target' AND Attribute_Name = '$share'";
                ($target_value) = $dbc->Table_find( "${target}_Attribute, Attribute", 'Attribute_Value', $condit );
                if ( !$target_value ) {
                    my $ok = SDB::Attribute::set_attribute( -dbc => $dbc, -object => $target, -attribute => $share, -id => $target_id, -value => $src_value );
                    if ($ok) {
                        $dbc->message("Inherited Attribute $share");
                        $inherited++;
                    }
                }
            }
        }
        if ( !$skip_message ) {
            Message("Inherited $inherited field/attributes..");
        }
    }
    return $inherited;
}

##
#
#
## OLD.. ??
###############################
sub get_join_conditions {
###############################
    my $self            = shift;
    my $table_ref       = shift;
    my $reference_table = shift;

    my @tables = Cast_List( -list => $table_ref, -to => 'array' );
    $reference_table ||= $tables[0];
    my $table_list = Cast_List( -list => $table_ref, -to => 'string', -autoquote => 1 );

    my @references = &Table_find( $self->{dbc}, 'DBField,DBTable', 'DBTable_Name,Field_Name,Foreign_Key', "where FK_DBTable__ID=DBTable_ID AND DBTable_Name in ($table_list) AND Foreign_Key like '$reference_table.%'" );
    my @conditions;
    foreach my $ref (@references) {
        my ( $tablename, $field, $FK ) = split ',', $ref;

        # print "$tablename : $field : $FK; => @conditions<BR>";
        if ( $self->{join_condition}{$tablename} ) {    # use explicit condition if supplied
            push( @conditions, $self->{join_condition}{$tablename} );
            next;
        }
        elsif ( $FK =~ /(.*)\./ && $self->{join_condition}{$1} ) {
            push( @conditions, $self->{join_condition}{$tablename} );
            next;
        }
        if ( $FK =~ /$tablename\./ ) {next}             ### ignore recursive links...
        if ( $field && $FK ) { push( @conditions, "$tablename.$field=$FK" ) }

        #	print "Add condition for $tablename : $tablename.$field = $FK<BR>";
    }
    ### ADD condition if back referencing (table references current list of tables...)
    return @conditions;
}

##############################
# public_functions           #
##############################

##############################
# private_methods            #
##############################

#######################
sub _initialize {
#######################
    #
    # Initialize the object with info from the DBField and DBTable tables
    #
    my $self = shift;
    my %args = @_;

    if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }

    my $dbc = $args{ -dbc } || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    $Connection ||= $dbc;

    $dbc->connect_if_necessary();

    $self->_get_DBfields();
    return 1;
}

####################################################
# Resolve a field into its table and field component
# If table was not specified, it will auto determine
####################################################
sub _resolve_field {
########################
    my $self      = shift;
    my $field_ref = shift;
    my %args      = @_;
    my $quiet     = $args{-quiet};
    my $dbc       = $self->{dbc};

    my ( $prefix, $suffix ) = $$field_ref =~ /(\W*)\w*\.?\w+(\W*)/;
    my ( $rtable, $rfield ) = SDB::DBIO::simple_resolve_field($$field_ref);

    my $found = 0;
    if ($rtable) {
        $found = 1;
    }
    else {
        foreach my $tblfld ( @{ $self->fields( -include_joins => 1 ) } ) {
            my ( $tbl, $fld ) = SDB::DBIO::simple_resolve_field($tblfld);
            if ( $fld eq $rfield ) {
                $rtable = $tbl;
                $found++;
            }
        }
    }

    if ( $found < 1 && $self->{tables} && int( @{ $self->{tables} } ) == 1 && $rfield ) {
        $rtable = $self->{tables}->[0];
        $found++;
    }

    if ( $found < 1 ) {
        $dbc->warning("Table cannot be resolved for field '$$field_ref'") unless $quiet;
        Call_Stack();
        return;
    }
    elsif ( $found > 1 ) {
        Message("More than one table found for field '$$field_ref'") unless $quiet;
        return;
    }
    else {
        my $fully_qualified;
        if ($rtable) { $fully_qualified = "$prefix$rtable." }
        $fully_qualified .= "$rfield$suffix";
        $$field_ref = "$fully_qualified";
        return ( $rtable, $rfield );
    }
}

#######################
sub _set_defaults {
#######################
    #
    # Sets the default values for the database fields
    #
    my $self = shift;

    foreach my $field ( $self->fields( -include_joins => 1 ) ) {
        unless ( defined $self->{fields}->{$field}->{value} ) {
            $self->{fields}->{$field}->{value} = $self->{fields}->{$field}->{default};
        }
    }
}

########################
# Get the record indices
########################
sub _get_indices {
    my $self = shift;
    my %args = @_;

    my $records = $args{-records};    # The records that we are interested in (e.g. $record->{Library.Library_Name} = ['CG001','CG002'])

    my @indices;
    if ( $records eq '*' ) {          # User is requesting all records
        @indices = map {$_} ( 0 .. ( $self->{record_count} - 1 ) );
    }
    elsif ($records) {
        my ( $field,  $vals )   = each %{$records};
        my ( $rtable, $rfield ) = $self->_resolve_field( \$field );
        $vals = Cast_List( -list => $vals, -to => 'arrayref' );
        foreach my $value (@$vals) {
            if ( $self->{primary_fields}->{$rtable} eq $rfield ) {    ### Fast retrieval based on primary field
                if ( $self->{record_index}->{$rtable}->{$value} ) {
                    push( @indices, $self->{record_index}->{$rtable}->{$value} );
                }
            }
            else {                                                    ### Have to search one by one to find it
                for ( my $i = 0; $i < @{ $self->{fields}->{$rtable}->{$rfield}->{values} }; $i++ ) {
                    if ( $self->{fields}->{$rtable}->{$rfield}->{values}->[$i] eq $value ) {
                        push( @indices, $i );
                        last;
                    }
                }
            }
        }
    }
    else {                                                            # If no records specified, then default to first record (i.e. index of zero)
        push( @indices, 0 );
    }

    return \@indices;
}

####################################
# Updates the record count attribute
####################################
sub _update_record_count {
    my $self = shift;

    my $max = 0;
    foreach my $table ( @{ $self->{tables} } ) {
        foreach my $field ( keys %{ $self->{fields}->{$table} } ) {
            if ( exists $self->{fields}->{$table}->{$field}->{values} ) {
                my $count = @{ $self->{fields}->{$table}->{$field}->{values} };
                if ( $count > $max ) {
                    $max = $count;
                    $self->{record_count} = $count;
                }
            }
        }
    }
}

#####################################
# Checks whether a particular item
# is to be include or not based on the
# include list and exclude list
######################################
sub _check_inclusion {
    my $self = shift;
    my %args = @_;

    my $item         = $args{-item};
    my $include_list = $args{-include_list};
    my $exclude_list = $args{-exclude_list};

    my $ret = 1;

    if ( $include_list && ( !grep /^$item$/, @$include_list ) ) { $ret = 0 }
    elsif ( $exclude_list && ( grep /^$item$/, @$exclude_list ) ) { $ret = 0 }

    return $ret;
}

##################
# Get standard object fields
#  (does NOT include fields from left joined tables - get these with $self->fields(-include_joins=>1))
#
#
#############################
sub _get_DBfields {
#############################
    #
    # Get the DBfields from the DBField table
    #
    my $self = shift;
    my %args = @_;
    my $dbc  = $self->{dbc};
    
    if ( $self->{table} ) { Call_Stack(); Message("phased out- check with Administrators"); return 0; }

    foreach my $table ( @{ $self->{tables} } ) {
        my $Field_Info = $dbc->field_info($table);
        
#        $dbc->initialize_field_info( -table => $table );
        $self->{primary_fields}->{$table} = $Field_Info{$table}{Primary};

        my @fields = keys %{$Field_Info} if $Field_Info;  ## @{ $Field_Info{$table}{Fields} } if $Field_Info{$table}{Fields};    ## <CONSTRUCTION> - generate message instructing to upgrade DBField table if undefined here
        foreach my $field (@fields) {
            if ( $self->{include_fields} && ( ( !grep /^$table\.$field$/, @{ $self->{include_fields} } ) ) && ( !grep /^$table\.\*$/, @{ $self->{include_fields} } ) ) {next}
            elsif ( $self->{exclude_fields} && ( ( grep /^$table\.$field$/, @{ $self->{exclude_fields} } ) || ( grep /^$table\.\*$/, @{ $self->{exclude_fields} } ) ) ) {next}
            elsif ( $Field_Info{$table}{$field}{Field_Scope} eq 'Attribute' ) {next}
            $self->{fields}->{$table}->{$field}->{default}     = $Field_Info{$field}{Default};
            $self->{fields}->{$table}->{$field}->{type}        = $Field_Info{$field}{Type};
            $self->{fields}->{$table}->{$field}->{prompt}      = $Field_Info{$field}{Prompt};
            $self->{fields}->{$table}->{$field}->{options}     = $Field_Info{$field}{Extra};
            $self->{fields}->{$table}->{$field}->{description} = $Field_Info{$field}{Description};
            unless ( grep /^$table\.$field$/, @{ $self->{fields_list} } ) {
                push( @{ $self->{fields_list} }, "$table.$field" );
            }
        }
    }

    return;
}

#############################
sub _get_FK_tables {

    # ### TO BE REMOVED ###
#############################
    #
    # Get the foreign tables
    #

    my $self = shift;
    my %args = @_;

    my $table  = $args{-table};            # Get foreign tables for this table [String]
    my @fields = @{ $args{ -fields } };    # Get foreign tables from these fields [ArrayRef]

    foreach my $field (@fields) {
        my ( $reftable, $reffield ) = &foreign_key_check($field);
        if ( $reftable && $reffield ) {
            if ( ( !$self->{FK_tables} || grep /^\b$reftable\b$/, @{ $self->{FK_tables} } ) && ( $reftable ne $table ) && ( !exists $References{$table}->{$field} ) ) {    #Do not follow if reference the same table and do not follow circular reference
                unless ( exists $References{$table}->{$field} ) { $References{$table}->{$field} = 1 }
                $self->_initialize( -table => $reftable, -type => 'FK' );
            }
        }
    }
}

##########################
# sample input:
# sync( -dbc              => $dbc,
#       -fields           => ['Run.Billable', 'Invoiceable_Work_Reference.Billable'],
#       -id               => "Invoiceable_Work_Reference.Invoiceable_Work_Reference_ID IN (1,2,3)", or "Invoiceable_Work_Reference.Invoiceable_Work_Reference_ID = 5"
#       -join_condition   => "FK_Invoiceable_Work__ID = FKReferenced_Invoiceable_Work__ID AND FK_Run__ID = Run.Run_ID",
#       -add_table        => "Invoiceable_Run" );
# return: True on success (number of successful executions) 0 if no changes made, return -1 if the input format is not valid
##########################
sub sync {
##########################
    #my $self           = shift;
    my %args           = &filter_input( \@_ );
    my $dbc            = $args{ -dbc };
    my $fields         = $args{ -fields };         ## eg -fields => ['Patient.Patient_Sex', 'Original_Source.Sex'];
    my $ID             = $args{-id};               ## eg -id => 'Run.Run_ID = 5'
    my $join_condition = $args{-join_condition};
    my $add_table      = $args{-add_table};
    my $debug          = $args{-debug};

    my ( @t, @f );
    my $fnum = 0;
    my $defined_index;

    $dbc->warning("In sync()\n") if $debug;
    Message("In sync()")         if $debug;
    print HTML_Dump \%args       if $debug;

    foreach my $field ( Cast_List( -list => $fields, -to => 'array' ) ) {
        if ( $field =~ /(.+)\.(.+)/ ) {
            push @f, $2;
            push @t, $1;
            if ( $ID =~ /^$1\./ ) {
                $defined_index = $fnum;
            }    ## 0 if first field indicated has id supplied
        }
        else {
            print "Error: $field not in table.field format\n";
            return -1;
        }
        $fnum++;
    }
    my $set_index     = !$defined_index;                ## index of field to set (in case of supplied ID)
    my $add_condition = "$t[0].$f[0] != $t[1].$f[1]";

    if ( $ID && !defined $defined_index ) {
        print "Error: ID supplied ($ID) must be fully qualified and match one of the supplied tables: (@t)\n";
        return -1;
    }

    if ( @f > 2 ) {
        print "Error: only 2 synced fields supported at this time\n";
        return -1;
    }

    #my ($query1, $query2);
    my $tables = "$t[0], $t[1]";
    my $fixed  = 0;

    if ($add_table) {
        $tables .= ", $add_table";
    }
    if ($ID) {
        ## if IDs supplied, only condition1 required - don't need to check if values are set or not... ##
        #$query1 = "UPDATE $tables SET $t[$set_index].$f[$set_index] = $t[$defined_index].$f[$defined_index] WHERE "
        #. "$join_condition AND $ID AND $add_condition";

        ###########################################
        my $field1   = "$t[$set_index].$f[$set_index]";
        my $field2   = "$t[$defined_index].$f[$defined_index]";
        my $updated1 = $dbc->Table_update_array( "$tables", [$field1], [$field2], "WHERE $join_condition AND $ID AND $add_condition", -skip_validation => 1, -no_triggers => 1 );    ## -debug => 1 for checking
        $fixed = $updated1;
        ###########################################
    }
    else {

        #$query1 = "UPDATE $tables SET $t[0].$f[0] = $t[1].$f[1] WHERE "
        #. "$join_condition AND " . is_set(-dbc => $dbc, -field => "$t[1].$f[1]") . " AND " . not_set(-dbc => $dbc, -field => "$t[0].$f[0]") . " AND $add_condition";
        #$query2 = "UPDATE $tables SET $t[1].$f[1] = $t[0].$f[0] WHERE "
        #. "$join_condition AND " . is_set(-dbc => $dbc, -field => "$t[0].$f[0]") . " AND " . not_set(-dbc => $dbc, -field => "$t[1].$f[1]") . " AND $add_condition";

        ###########################################
        my $updated1 = $dbc->Table_update_array(
            "$tables", ["$t[0].$f[0]"], ["$t[1].$f[1]"],
            "WHERE "
                . "$join_condition AND "
                . is_set( -dbc  => $dbc, -field => "$t[1].$f[1]" ) . " AND "
                . not_set( -dbc => $dbc, -field => "$t[0].$f[0]" )
                . " AND $add_condition",
            -skip_validation => 1,
            -no_triggers     => 1
        );

        my $updated2 = $dbc->Table_update_array(
            "$tables", ["$t[1].$f[1]"], ["$t[0].$f[0]"],
            "WHERE "
                . "$join_condition AND "
                . is_set( -dbc  => $dbc, -field => "$t[0].$f[0]" ) . " AND "
                . not_set( -dbc => $dbc, -field => "$t[1].$f[1]" )
                . " AND $add_condition",
            -skip_validation => 1,
            -no_triggers     => 1
        );

        $fixed = $updated1 + $updated2;
        ###########################################
    }

    #$fixed += $dbc->execute_command($query1) if !$debug;
    #print "Q1 = $query1\n\n" if $debug;
    #if ($query2) {
    ## only if not using ID ... reverse field order and update any not currently set ##
    #$fixed += $dbc->execute_command($query2) if !$debug;
    #print "Q2 = $query2\n\n" if $debug;
    #}

    my %remaining_conflicts = $dbc->Table_retrieve( $tables, [ "count(*)", "$t[0].$f[0]", "$t[1].$f[1]" ], "WHERE $join_condition AND $t[0].$f[0] != $t[1].$f[1]", -group => "$t[0].$f[0], $t[1].$f[1]" );
    if (%remaining_conflicts) {
        print $dbc->Message("Remaining Sync Conflicts\n") if $debug;
    }
    if ( $debug =~ /html/i ) {
        require SDB::HTML;
        print SDB::HTML::display_hash( -title => 'Remaining Sync Conflicts', -hash => \%remaining_conflicts );
    }
    elsif ($debug) {
        print Dumper \%remaining_conflicts;
    }
    return $fixed;
}

##########################
# sample input: not_set(-field => 'Original_Source.Sex')
##########################
sub not_set {
##########################

    my %args  = &filter_input( \@_ );
    my $dbc   = $args{ -dbc };
    my $field = $args{-field};

    my $not_set_condition = "($field = '' OR $field IS NULL OR LENGTH($field) = 0 OR $field = 'Unknown' OR $field = 'N/A' OR $field = 'n/a')";

    return $not_set_condition;
}

##########################
sub is_set {
##########################

    my %args  = &filter_input( \@_ );
    my $dbc   = $args{ -dbc };
    my $field = $args{-field};

    my $is_set_condition = "(Length($field) > 0 AND $field IS NOT NULL)";

    return $is_set_condition;
}

######################### end of new code #########################

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

2003-11-24

=head1 REVISION <UPLINK>

$Id: DB_Object.pm,v 1.112 2004/11/30 23:05:38 mariol Exp $ (Release: $Name:  $)

=cut

return 1;
