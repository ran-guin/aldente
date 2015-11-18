##################################################################################################################################
# DBIO.pm
#
# Database IO object that handles database connections and operations. (also handles transactions in the future)
# Evenetually this object will replace GSDB.pm and DB_IO.pm
#
# $Id: DBIO.pm,v 1.107 2004/11/30 01:42:24 rguin Exp $
###################################################################################################################################
package SDB::DBIO;

use base LampLite::DB;

#use base LampLite::DB;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

DBIO.pm - Database IO object that handles database connections and operations. (also handles transactions in the future)

=head1 SYNOPSIS <UPLINK>

 ### There are 2 ways to create a new DBIO object and obtain a connection
 my $dbc = SDB::DBIO->new();
 $dbc->connect(-dbase=>'seqdev',-host=>'athena',-user=>'username',-password=>'passwd');
 ## or in one line:
my $dbc = SDB::DBIO->new(-dbase=>'seqdev',-host=>'athena',-user=>'username',-password=>'passwd',-connect=>1);

 ### The DBIO object also supports freeze/thaw/encoding/decoding.  
 my $frozen = $dbc->freeze();
 ### There are 2 ways to thaw a DBIO object (note that when thawing it needs to re-establish a database handle)
 # Method 1: Pass in an existing database handle along with the frozen object if the DBIO object was created by method 1 above
 my $thawed_dbc = SDB::DBIO->new(-frozen=>$frozen,-dbc=>$dbc);
 # Method 2: Just pass in the frozen object and the database handle will be re-created automatically based on existing connection info.
 my $thawed_dbc = SDB::DBIO->new(-frozen=>$frozen);

 ### Querying records
 my $sth = $dbc->query(-query=>'Select Account_ID,Account_Name from Account');            # Query by passing in SQL statement directly
 my $sth = $dbc->query(-query=>'Select Account_ID,Account_Name from Account',-finish=>0); # Same as above, except keep the statement handle alive (thru $dbo->sth())

 ### Batch inserting records
 # Create a data hash for 2 new library records that updates the Library, Ligation, Microtiter, cDNA_Library, SAGE_Library, LibraryPrimer tables.
 my %data;
 @{$data{Library_Name}} = ('ABC50','ABC51');                  # Field in the Library table
 @{$data{Library_Type}} = ('cDNA','SAGE');                    # Field in the Library table 
 @{$data{Library_Format}} = ('Ligation','Microtiter Plates'); # Field in the Library table 
 @{$data{FK_Project__ID}} = ('3','4');                        # Field in the Library table
 @{$data{FK_Library__Name}} = ('ABC50','ABC51');              # Field in the Ligation, Microtiter, cDNA_Library, SAGE_Library, LibraryPrimer tables
 @{$data{Blue_White_Selection}} = ('Yes','');                 # Field in the cDNA_Library table
 @{$data{Insert_Site_Enzyme}} = ('1','IE');                   # Field in the SAGE_Library table
 @{$data{VolumePerWell}} = ('','A');                          # Field in the Microtiter table
 @{$data{FK_Primer__Name}} = ('T3','T7');                     # Field in the LibraryPrimer table
 @{$data{Direction}} = ('N/A','N/A');                         # Field in the LibraryPrimer table


 ### Alternatively, you can convert the hash first and then pass in the formatted hash.
 %data = %{$self->convert_hash(-table=>$table,-data=>\%data)}; # Convert the data hash
 # Or you can pass in a pair of arrays ref to specify the fields/values. (Only support single table now)

 ### You can also pass in alias to field names. There are 2 ways to define an alias to use.
 # Method 1: Define and pass in the alias hash
 my %alias;
 @{$alias{Lbl}} = (1510,1514); # The alias 'Lbl' points to the fields with the DBField_ID of 1510 and 1514 (in this case they are Ligation.Label & Microtiter.Label)
 @{$data{Lbl}} = ('Ligation Label','Microtiter Label'); # Now you can just populate the data hash with 'Lbl' instead of 'Label'    

 my $tables_list = "Sample,Clone_Sample";
 my @insert_fields = ('Sample.Sample_Name','Sample.Sample_Type','Clone_Sample.FKOriginal_Plate__ID','Clone_Sample.Library_Plate_Number',
                      'Clone_Sample.Original_Well');
 my %insert_values;
 $insert_values{1} = ['10790-100_A01','Clone','12000','100','A01'];
 $insert_values{2} = ['10790-100_A02','Clone','12000','100','A02'];
 $insert_values{3} = ['10790-100_A03','Clone','12000','100','A03'];

 # %newids in the format of $newids{Sample} = [11620,11621,11622]; $newids{Clone_Sample} = [12000,12001,12002]
 my %newids = %{$dbc->smart_append(-tables=>$tables_list,-fields=>\@insert_fields,-values=>\%insert_values,-autoquote=>1)};   

=head1 DESCRIPTION <UPLINK>sub

=for html
Database IO object that handles database connections and operations. (also handles transactions in the future)<BR>Evenetually this object will replace GSDB.pm and DB_IO.pm<BR>
    
=cut

##############################
# superclasses               #
##############################
### Inheritance

push @ISA, qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(
    list_tables
    get_enum_list
    getprompts
    Table_add
    Table_drop
    get_field_info
    initialize_field_info
    get_fields
    get_field_types
    Table_find
    Table_test
    Table_find_array
    Table_retrieve
    Table_retrieve_display
    Table_copy
    Table_binary_update
    Table_binary_append
    delete_records
    delete_record
    deletion_check
    Table_update_array_check
    Table_append
    Table_append_array
    Table_update
    Table_update_array
    rekey_hash
    Batch_Append
    get_id
    foreign_key_pattern
    get_FK_info
    get_FK_ID
    get_FK_info_list
    foreign_key
    foreign_key_check
    %Field_Info
    check_permissions
    Is_Null
    Is_Not_Null
    Insertion_Check
    Get_DBI_Error
    SQL_append_string
    simple_resolve_field
    tables
    get_join_table
    merge_data
);
@EXPORT_OK = qw(
    list_tables
    get_enum_list
    getprompts
    Table_add
    Table_drop
    get_field_info
    initialize_field_info
    get_fields
    get_field_types
    Table_find
    Table_find_array
    Table_retrieve
    Table_retrieve_display
    Table_copy
    Table_binary_update
    Table_binary_append
    delete_records
    delete_record
    deletion_check
    Table_update_array_check
    Table_append
    Table_append_array
    Table_update
    Table_update_array
    rekey_hash
    Batch_Append
    get_id
    foreign_key_pattern
    get_FK_info
    get_FK_ID
    get_FK_info_list
    foreign_key
    foreign_key_check
    check_permissions
    Is_Null
    Is_Not_Null
    Insertion_Check
    Get_DBI_Error
    simple_resolve_field
    tables
    get_join_table
    package_active
    merge_data
);

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

#use AutoLoader;
use Carp;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules

use LampLite::Login;
use LampLite::Bootstrap;

use RGTools::RGIO;
use RGTools::Object;
use RGTools::Conversion;
use RGTools::RGmath;

use SDB::DB_Access;
use SDB::CustomSettings;
use SDB::Transaction;

use LampLite::HTML qw(HTML_Dump);

##############################
# global_vars                #
##############################

## Global variables
use vars qw($config_dir %Primary_fields %Prefix %Mandatory_fields %Field_Info @DB_Tables $Sess);

my $BS = new Bootstrap;
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

############################################################
# Constructor of the object
# RETURN: The object itself
############################################################
sub new {
#########
    my $this = shift;

    my %args    = @_;
    my $frozen  = $args{-frozen} || 0;     # Reference to frozen object if there is any (optional) [Object]
    my $encoded = $args{-encoded} || 0;    # Flag indicate whether object was encoded (optional) [Bool]
    my $debug   = $args{-debug} || 0;

    my $dbc = $args{-dbc} || '';           # Database handle (optional) [Object]

    ### Connection parameters ###

    my $dbase      = $args{-dbase}       || '';
    my $login_name = $args{-user}        || 'guest';                             # login user name (MANDATORY) [String]
    my $login_pass = $args{-password}    || '';                                  # (MANDATORY unless login_file used) specification of password [String]
    my $trace      = $args{-trace_level} || 0;                                   # set trace level on database connection (defaults to 0) [Int]
    my $trace_file = $args{-trace_file}  || 'Trace.log';                         # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $quiet      = $args{-quiet}       || 0;                                   # suppress printed feedback (defaults to 0) [Int]
    my $host       = $args{-host}        || $Defaults{SQL_HOST};                 # (MANDATORY unless global default set) host for SQL server. [String]
    my $driver     = $args{-driver}      || $Defaults{SQL_DRIVER} || 'mysql';    # SQL driver  [String]
    my $config         = $args{-config};                                         # optional array of configuration files ( saves dbc->{config}{<KEY>} values from XML config files )
    my $session        = $args{-session};
    my $sessionless    = $args{-sessionless};
    my $defer_messages = $args{-defer_messages} || $quiet;

    my $dsn              = $args{-dsn};                                          # Connection string [String]
    my $start_trans      = $args{-start_trans} || 0;                             # Optional flag to indicate starting of transaction
    my $log_unit_testing = $args{-log_unit_test} || 0;
    my $no_triggers      = $args{-no_triggers};

    my $login_table = $args{-login_table} || 'Employee';
    my $login_file = $args{-login_file};

    if ( !$dsn && $driver && $dbase && $host ) {                                 # If DSN is not specified but all other info are provided, then we build a DSN.
        $dsn = "DBI:$driver:database=$dbase:$host";
    }

    ### other parameters ###
    my $alias_file = $args{-alias_file} || "$config_dir/db_alias.conf";          # Location of DB alias file (optional) [String]
    my $alias_ref  = $args{-alias};                                              # Reference to DB alias hash (optional). If passed in then overrides alias file [HashRef]
    my $connect    = $args{ -connect };                                          ## Flag to indicate that connection should be made
    my $test_mode  = $args{-test_mode};                                          ## flag to indicate that current database is NOT the production database

    ### turn test mode on if Production database is defined and not being used

    ### Ensure local parameters are passed to LampLite constructor ##

    $args{-driver}      = $driver;
    $args{-login_file}  = $login_file || SDB::DBIO::_get_login_file('', $config);
    $args{ -connect }   = 0;
    $args{-login_table} = $login_table || 'Employee';                           # CUSTOM ...

    my $self = LampLite::DB->new(%args);
    my $class = ref($this) || $this;
    bless $self, $class;

    my $mode = $args{-mode};
    if ( $self->config('PRODUCTION_DATABASE') && ( $self->config('PRODUCTION_DATABASE') eq $dbase ) ) {
        $mode ||= 'production';
        $test_mode = 0;
    }
    elsif ( $self->config('BETA_DATABASE') && ( $self->config('BETA_DATABASE') eq $dbase ) ) {
        ## set test_mode on unless we are in beta mode
        $mode ||= 'beta';
    }
    else {
        $mode ||= 'test';
        $test_mode = 1;
    }
    $self->{mode} = $mode;                                                      # Eg - Production, Beta, or Test

#    if ($config) {
#        $self->load_config( -load => 1, -config => $config );
#    }


    $self->{scanner_mode} = 0;
    if ( $0 =~ /scanner/ ) { $self->{scanner_mode} = 1 }

    if ($connect) {                                                             # Else try to obtain database handle by existing connection info
        $self->connect( -sessionless => $sessionless );
    }

    if ($session) { $session->init($self) }

    ###  Connection attributes ###
    $self->{connected} ||= 0;
    $self->{debug_mode} = $debug;                                               # Debug mode [Object]
    $self->{sth}        = '';                                                   # Current statement handle [Object]
    $self->{dbase}      = $dbase;                                               # Database name [String]
    $self->{host}       = $host;                                                # (MANDATORY unless global default set) host for SQL server. [String]
    $self->{driver}     = $driver;                                              # SQL driver [String]
    $self->{dsn}        = $dsn;                                                 # Connection string [String]

    $self->{login_name} = $login_name;                                          # Login user name [String]
    $self->{login_pass} = $login_pass;                                          # (MANDATORY unless login_file used) specification of password [String]

    $self->{trace}         = $trace;                                            # set trace level on database connection (defaults to 0) [Int]
    $self->{trace_file}    = $trace_file;                                       # optional trace_file where trace info to be written. (required if trace_level set) [String]
    $self->{quiet}         = $quiet;                                            # suppress printed feedback (defaults to 0) [Int]
    $self->{log_unit_test} = $log_unit_testing;
    $self->{test_mode}     = $test_mode;

    ### method attributes ###
    $self->{field_info_tables}   = 1;                                                 # A flag to indicate presence of DBField, DBTable tables.
    $self->{alias_file}          = $alias_file;                                       # The location of the DB alias file [String]
    $self->{alias}               = {};                                                # Reference to DB alias hash [HashRef]
    $self->{LocalAttribute}      = {};
    $self->{permission_checking} = 1 unless ($self->config('permission_tracking') eq 'OFF');
    $self->{no_triggers}         = $no_triggers;
    $self->{benchmarking}        = 1;                                                 ## enable Benchmarking (requires Benchmark module)

    #   print Dumper $dbc;
    #   Call_Stack();
    ### Create Transaction object and starts transaction if dbc is set ###

    if ($alias_ref) {
        $self->{alias} = $alias_ref;
    }
    elsif ( -f $self->{alias_file} ) {
        $self->{alias} = Storable::retrieve( $self->{alias_file} );
    }

    #    if ( $connect && !$frozen ) {
    #        $self->connect();
    #    }

    $self->{messaging} = 3;    # A flag to indicate if messages are dumped directly

    ## Monitor some things specifically (useful for debugging and development)
    $self->{deletions}      = {};
    $self->{updates}        = {};
    $self->{slow_queries}   = [];
    $self->{transactions}   = [];                  # monitor database updates within transactions <CONSTRUCTION> temporary (?)
    $self->{messages}       = [];
    $self->{warnings}       = [];
    $self->{errors}         = [];
    $self->{order}          = int( rand(1000) );
    $self->{defer_messages} = $defer_messages;     ## flag to turn off real time message generation: turn on with $self->defer_messages(); print messages later with $self->flush_messages()

    return $self;
}

# This method should be defined for all inherited DB object classes 
#
# Dynamically load the given module at the highest available level.
#  (if not found, it will check inherited classes and load them as required)
#
#
# Return: name of module loaded if found 
######################
sub dynamic_require {
######################
	my $self = shift;
	my %args = filter_input(\@_, -args=>'module');
	my $module = $args{-module};
	my $debug  = $args{-debug};
	
	my $scope = 'SDB';  ## change this line only depending on scope of method ##
	
	my $test = $scope . '::' . $module;
	my $local = eval "require $test";
	if ($local) {
		if ($debug) { $self->message("Found local $test") }
		return $test;
	}
	else {
		if ($debug) { $self->message("$test not found... keep looking.... ") }
		return $self->SUPER::dynamic_require($module, -debug=>$debug);
	}

}



#####################
sub email_options {
#####################
    my $self = shift;

    my $email = shift;

    my $domain = shift || $self->config('default_email_domain');

    my ( $long_email, $short_email ) = ( $email, $email );
    if ( $email =~ /^(.+)\@$domain$/ ) {
        $short_email = $1;
    }
    elsif ( $email !~ /\@/ && $domain ) {
        $long_email = $email . '@' . $domain;
    }

    return ( $short_email, $long_email );
}

######################
sub Get_DBI_Error {
######################
    return $DBI::errstr;
}

##################
# Returns preset values based upon data in source objects
#
# Input:
#   - tables in target form
#   - primary list of ids
#   - primary field which ids belong to
#
# Options:
#    User may specify value to use when conflicts encountered:
#        -on_conflict => { 'Sex' => 'Mixed' }    ## if Sex field is in conflict, set preset to 'Mixed'
#        -on_conflict => { 'Status' => '<concat>' }  ## if status is in conflict, set status to concatenation of values found
#        -on_conflict => { 'Status' => '<distinct concat>' }  ## if status is in conflict, set status to distinct concatenation of values found
#        -on_conflict => { 'Weight_mg' => '<average>' }  ## if Weight_mg is in conflict, set Weight_mg to average value
#
#                  ... see merge_values for full list of special tags for handling multiple values
#
# Return hash of preset values (keyed on fields)
#################
sub merge_data {
#################
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $tables       = $args{-tables} || $args{-table};
    my @sources      = Cast_List( -list => $args{-primary_list}, -to => 'array' );
    my $source_field = $args{-primary_field};
    my @skip_list    = Cast_List( -list => $args{-skip_list}, -to => 'array' );
    my $clear        = $args{-clear};                                                ## optionally supply list of fields to clear (will clear even if supplied in original preset)
    my $no_merge     = $args{-no_merge} || 0;
    my $on_conflict  = $args{-on_conflict};                                          ## indicate value to use if field conflict encountered
    my $assign       = $args{-assign};                                               ## values to assign to the specified fields. There's no need to check conflicts on these fields
    my $quiet        = $args{-quiet};
    my $debug        = $args{-debug};
    ## hash return values ##
    my $preset              = $args{-preset};                                        ## used to return unresolved conflict hash (ie pass in empty hash reference)
    my $unresolved_conflict = $args{-unresolved_conflict};                           ## used to return unresolved conflict hash (ie pass in empty hash reference)
    my $need_input          = $args{-need_input};                                    ## fields to ask for user input

    if ($debug) { print HTML_Dump "merge_data", \%args }

    my @fields = $self->get_fields( $tables, '', 'defined', -debug => $debug );
    my @primary_fields = $self->get_field_info( $tables, -type => 'Primary' );

    if ( $tables =~ /^\w+$/ ) { $source_field ||= $primary_fields[0] }               ## precludes need to supply primary_field if only one table supplied ##

    @fields = map { $a = $_; $a =~ s/ AS .*//i; $a; } @fields;
    my %Data;

    my $join_condition = $self->get_join_condition( -tables => $tables );
    $join_condition ||= 1;
    foreach my $id (@sources) {
        if ($id) {
            $Data{$id} = { $self->Table_retrieve( "$tables", \@fields, "WHERE $join_condition AND $source_field = $id" ) };
        }
    }
    if ($debug) { print HTML_Dump "Data", \%Data }

    my @deletes;
    if ($clear) { @deletes = @$clear }

    my %merge_values;
    my %resolved_conflict;
    my $sources_count = int( keys %Data );
    foreach my $field (@fields) {

        $field =~ s/^\w+\.(\w+)/$1/gi;

        if ( grep( /^$field$/i, @skip_list ) ) {next}
        if ( grep( /^$field$/i, @deletes ) )   {next}
        if ( ( grep /^$field$/, @primary_fields ) && ( $field =~ /_ID$/ ) ) {next}

        ## If this field is specified to an assigned value, place it as preset directly and no need to check conflicts
        if ( exists $assign->{$field} ) {
            $preset->{$field} = $assign->{$field};
            next;
        }

        ## require user input
        if ( exists $need_input->{$field} ) {
            next;
        }

        ### for each field see if there is a consistently set field already in the sources ##
        my $undef_value_count = 0;
        my $preset_value_count = 0;
        foreach my $source ( keys %Data ) {
            my $value;
            if ( defined $Data{$source}{$field}[0] ) {
                $value = $Data{$source}{$field}[0];
            }
            else {
                $undef_value_count++;
            }

            if ( $on_conflict->{$field} =~ /\</ ) {
                ## special cases for merging multiple values - keep track of list and set based on full list ##
                push @{ $merge_values{$field} }, $value;
                next;
            }

            if ($no_merge) {
                push @{ $preset->{$field} }, $value;
            }
            elsif ( defined $resolved_conflict{$field} ) {
                ## already resolved conflict value ##
                last;  ## GSC LIMS changed this from next for some reason (?) ... leaving for now assuming they have tested, but not sure.
            }
            elsif ( defined $preset->{$field} ) {
                if ( $value eq $preset->{$field} ) {
                    if   ( defined $unresolved_conflict->{$field} ) { $unresolved_conflict->{$field}{ $preset->{$field} }++ }
                    else                                            { $preset_value_count++ }
                }
                else {
                    ## value conflict found ##
                    if ( defined $on_conflict->{$field} ) {
                        ## set value as defined if applicable ##
                        $preset->{$field} = $on_conflict->{$field};
                        $resolved_conflict{$field}++;
                        last;  ## GSC LIMS added this ... leaving for now assuming they have tested, but not sure.
                    }
                    else {
                        if ( !defined $unresolved_conflict->{$field} ) {
                            $unresolved_conflict->{$field}{ $preset->{$field} } = $preset_value_count;
                            push( @deletes, $field );
                        }

                        #push( @deletes, $field );
                        ## keep track of unresolved conflicts for feedback purposes ##
                        $unresolved_conflict->{$field}{$value}++;

                        #$unresolved_conflict->{$field}{ $preset->{$field} }++;
                    }
                }
            }
            else {
                $preset->{$field} = $value;
                $preset_value_count++;
            }
        }    # END foreach my $source ( keys %Data )

        ## filter out the ones in cases like: one undef value, two others with the same value. This field should be considered as conflict.
        if ( !defined $resolved_conflict{$field} && $undef_value_count && defined $preset->{$field} ) {
            if ( defined $on_conflict->{$field} ) {
                ## set value as defined if applicable ##
                $preset->{$field} = $on_conflict->{$field};
                $resolved_conflict{$field}++;
            }
            else {
                push( @deletes, $field );
                $unresolved_conflict->{$field}{''} = $undef_value_count;
                $unresolved_conflict->{$field}{ $preset->{$field} } = $sources_count - $undef_value_count;
            }
        }
    }

    foreach my $field ( keys %merge_values ) {
        ## get combined values for fields with special logic defined (eg on_conflict => '<concat>') ##
        $preset->{$field} = $self->merge_values( -list => $merge_values{$field}, -on_conflict => $on_conflict->{$field}, -table => $tables, -field => $field, -quiet => $quiet );
    }

    foreach (@deletes) {
        delete $preset->{$_};
    }

    if ($debug) {
        print HTML_Dump "Preset: ",              $preset;
        print HTML_Dump "Merge: ",               \%merge_values;
        print HTML_Dump "On Conflict",           $on_conflict;
        print HTML_Dump 'Unresolved Conflicts:', $unresolved_conflict;
    }

    return $preset;
}

########################
sub create_merged_data {
########################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $table               = $args{-table};
    my $test                = $args{-test};    ## use flag to suppress messages (eg when calling only to get conflict list)
    my $unresolved_conflict = {};
    my $need_input          = {};
    my $preset              = {};
    my $debug               = $args{-debug};

    $args{-quiet} = $test;                     ## set merge to quiet if only testing merge
    ## allow use of hash references as input arguments or create them as required ##
    if   ( $args{-unresolved_conflict} ) { $unresolved_conflict          = $args{-unresolved_conflict} }
    else                                 { $args{'-unresolved_conflict'} = $unresolved_conflict }

    if   ( $args{-need_input} ) { $need_input          = $args{-need_input} }
    else                        { $args{'-need_input'} = $need_input }

    if   ( $args{-preset} ) { $preset        = $args{-preset} }
    else                    { $args{-preset} = $preset }

    ## Generate preset values (see merge_data for valid input arguments) ##
    $self->merge_data(%args);

    my @fields = $self->get_fields( $table, '', 'defined' );

    if ( !( keys %{$unresolved_conflict} ) && !( keys %{$need_input} ) ) {
        ## only add record if no unresolved conflicts remain and no field waiting for user input##
        my ( @update_fields, @update_values );
        foreach my $f (@fields) {
            if ( $f =~ /$table\.(\w+)/ ) { $f = $1 }
            else                         {next}
            if ( defined $preset->{$f} ) {
                push @update_fields, $f;
                push @update_values, $preset->{$f};
            }
        }

        if ( @update_fields && !$test ) {
            my $ok = $self->Table_append_array( $table, \@update_fields, \@update_values, -debug => $debug, -autoquote => 1 );
            return $ok;
        }
    }

    return;
}

##################################################################
# This allows various methods of treating 'combined' values
# (for example when pooling records)
#
#        -on_conflict = '<clear>'           ## if Sex field is in conflict, set value to ''
#        -on_conflict = '<concat>'          ## if status is in conflict, set status to concatenation of values found
#        -on_conflict = '<distinct concat>' ## if status is in conflict, set status to distinct concatenation of values found
#        -on_conflict => '<average>'        ## if Weight_mg is in conflict, set Weight_mg to average value
#        -on_conflict => '<sum>'                       ## set to sum of values (THIS CASE DOES NOT DEPEND ON A CONFLICT)
#
#        -on_conflict => '<today>'                     ## if date is in conflict, set to current date (normally this would be overwritten regardless in another place in the code)
#        -on_conflict => 'XYZ_<N5>'        ## set to auto-incremented string (in this case it would find the next applicable value in the range: XYZ_00001 .. XYZ_99999
#        -on_conflict => '<Project_Name=Mixed>'        ## set to explicitly referenced record (eg if Project is in conflict set FK_Project__ID to the Project_ID where Project_Name = 'Mixed' )
#
# Other options:
#
#      -delimiter = ' + '    ## only applies when on_conflict = concat or distinct concat\
#
# Return: single value representing merged values
###########################
sub merge_values {
###########################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $list        = $args{-list};
    my $on_conflict = $args{-on_conflict};
    my $delim       = $args{-delimiter} || ',';    ## delimiter to use for concatentation (if applicable)
    ## required for autoincrement option only ##
    my $dbtable = $args{-table};
    my $dbfield = $args{-field};                   ## optional field specification (can be used if autoincrement is required)
    my $quiet   = $args{-quiet};

    my $merged;
    my $set_on_conflict = 1;

    if ( $on_conflict =~ /<(.+)>/ ) {
        my $keyword = $1;
        ## special cases ##
        if ( $on_conflict =~ /<concat>/i ) {
            ## indicate that field should be set to a concatenated list of values (eg  $on_conflict{Grade} = '<concat>' ) ##
            if ( !$quiet ) { $self->message("Concat $dbfield values") }
            $set_on_conflict = 0;
            $merged = Cast_List( -list => $list, -to => 'string', -delimiter => $delim );
        }
        elsif ( $on_conflict =~ /<distinct concat>/i ) {
            ## indicate that field should be set to  a concatenated list of DISTINCT values  (eg  $on_conflict{Grade} = '<concat>' ) ##
            if ( !$quiet ) { $self->message("Distinct Concat $dbfield values") }
            $merged = Cast_List( -list => unique_items($list), -to => 'string', -delimiter => $delim );
        }
        elsif ( $on_conflict =~ /<(average|sum)>/ ) {
            ## indicate that field should be set to an average or sum value (eg  $on_conflict{Tumour_Percent} = '<average>' ) ##
            my $action = $1;
            my $sum    = 0;
            foreach my $i ( 1 .. int(@$list) ) {
                $sum += $list->[ $i - 1 ];
            }
            if ( $on_conflict =~ /<average>/i ) { $merged = $sum / int(@$list) }
            elsif ( $on_conflict =~ /<sum>/i ) { $merged = $sum; $set_on_conflict = 0; }
            if ( !$quiet ) { $self->message("$action $dbfield values") }
        }
        elsif ( $on_conflict =~ /<today>/ ) {
            ## indicate that field should be set to current date time (eg  $on_conflict{Created} = '<today>' ) ##
            if ( !$quiet ) { $self->message("Cleared $dbfield values") }
            $merged = &date_time();
        }
        elsif ( $on_conflict =~ /<clear>/ ) {
            ## indicate that field should be cleared ( eg $on_conflict{FK_Patient__ID} = '<clear>' )
            if ( !$quiet ) { $self->message("Cleared $dbfield values") }
            $merged = '';
        }
        elsif ( $on_conflict =~ /<(.+)=(.*)>/ && ( my ( $ref_T, $ref_F ) = $self->foreign_key_check($dbfield) ) ) {
            ## specify reference condition  (eg $on_conflict{FK_Project__ID} = '<Project_Name=Collaboration>' ) ##
            my $field = $1;
            my $value = $2;

            if ( !$quiet ) { $self->message("Set to $ref_T reference (where $field = '$value')") }
            ($merged) = $self->Table_find( $ref_T, $ref_F, "WHERE $field = '$value'" );
        }
        elsif ( $on_conflict =~ /^(.*)<N(.*)>/ ) {
            ## specify autoincrement value for field ( eg $on_conflict{X_Name} = '<X_<N5>' )
            my $prefix = $1;
            my $pad    = $2;

            ($merged) = @{ $self->get_autoincremented_name( -table => $dbtable, -field => $dbfield, -prefix => $prefix, -count => 1, -pad => $pad ) };
            if ( !$quiet ) { $self->message("Autoincrement $dbfield values [$prefix + N$pad]") }
        }
        else {
            if ( !$quiet ) { $self->warning("Undefined conflict specification: $on_conflict") }
        }
    }
    else {
        $merged = $on_conflict;
    }

    ## determine if values are identical ##
    if ($set_on_conflict) {
        my $conflict;
        foreach my $value (@$list) {
            if ( $value ne $list->[0] ) { $conflict++ }
        }

        if   ($conflict) { return $merged }
        else             { return $list->[0] }
    }
    else { return $merged }
}

##################
# Description:
#   -
#
#
# Output:
#   - Array reference of new ids
#
#################
sub combine_records {
#################
    my $self              = shift;
    my %args              = &filter_input( \@_, -mandatory => 'table,ids' );
    my $table             = $args{-table};
    my $debug             = $args{-debug};
    my $ids               = $args{-ids};
    my $update            = $args{-update};                                    # hash ref of fields and the values to replace existing ones
    my $exclude           = $args{-exclude};                                   # fields not to copy
    my $ignore_attributes = $args{-ignore_attributes};                         # doesn't copy attributes of records
    my $no_triggers       = $args{-no_triggers} || $self->{no_triggers};       # suppress triggers
    my $no_merge          = $args{-no_merge} || 0;

    my %update;
    require SDB::DB_Object;

    my ($primary_field) = $self->get_field_info( $table, undef, 'PRI' );
    if ($update) {
        %update = %$update;
        my $temp = join ',', ( keys %update );
        if ($exclude) { $exclude .= ',' . $primary_field }
        else          { $exclude = $primary_field }
        $exclude .= ',' . $temp;
    }

    my $hash = $self->merge_data(
        -tables        => $table,
        -primary_list  => $ids,
        -primary_field => $primary_field,
        -skip_list     => $exclude,
        -no_merge      => $no_merge,
    );

    my $size = 0;
    my @new_records;
    my @fields = keys %$hash;
    my @values = values %$hash;
    if ($no_merge) { $size = $#{ $values[0] } }
    for ( my $i = 0; $i <= $size; $i++ ) {
        if ($no_merge) {
            @values = ();
            @fields = keys %$hash;
            for my $key (@fields) {
                push @values, $hash->{$key}[$i];
            }
        }
        for my $field ( keys %update ) {
            push @fields, $field;
            push @values, $update{$field};
        }
        my $new_record = $self->Table_append_array( $table, \@fields, \@values, -autoquote => 1, -debug => $debug, -no_triggers => $no_triggers );
        if ( !$ignore_attributes ) {
            my $db_obj = new SDB::DB_Object( -dbc => $self, -tables => $table );
            $db_obj->inherit_Attribute( -child_ids => $new_record, -parent_ids => $ids, -tables => $table, -conflict => 'ignore' );
        }
        push @new_records, $new_record;
    }
    return @new_records;
}

###################
#
#
#
###################
sub get_Processlist {
###################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    my $query = 'show full processlist';

    my $start = time();

    my $sth = $self->dbh()->prepare($query);
    $sth->execute();

    if ( defined $sth->err() ) {
        $self->message( "ProcessList Error: " . Get_DBI_Error() );
        Call_Stack();
        $self->message("MySQL Show Full ProcessList");
    }
    my $end = time();
    my $ref;
    $self->_track_if_slow( "Retrieve: $query", -time => $end - $start, -dbc => $self );

    my $headers = $sth->{NAME};
    my @headers = @$headers if $headers;
    my $size    = @headers - 1;
    my %data;
    while ( $ref = $sth->fetchrow_arrayref ) {
        my @list = @$ref if $ref;
        for my $index ( 0 .. $size ) {
            push @{ $data{ $headers[$index] } }, $list[$index];
        }
    }
    $sth->finish();
    return \%data;
}

###################
# Does the list of preliminary action that need to take place after a update or append
#
#
###################
sub execute_preliminary_actions {
###################
    my %args = &filter_input( \@_, -args => 'dbc,table,action,ids,no_triggers', -mandatory => 'dbc|self,table', -self => 'SDB::DBIO' );
    my $self        = $args{-self} || $args{-dbc};
    my $TableName   = $args{-table};
    my $no_triggers = $args{-no_triggers} || $self->{no_triggers};    # suppress triggers
    my $action      = $args{-action};
    my $ids         = $args{-ids};
    my $fields      = $args{-fields};
    my $debug       = $args{-debug};
    my $copy_time   = &date_time();

    if ( !$no_triggers ) {
        $self->create_Recursive_Alias( -table => $TableName, -action => $action, -ids => $ids );
    }

    return;
}

#######################
sub get_Label_field {
#######################
    my %args = &filter_input( \@_, -args => 'dbc,table', -mandatory => 'dbc|self,table', -self => 'SDB::DBIO' );
    my $self  = $args{-self} || $args{-dbc};
    my $table = $args{-table};
    my $name  = $table . '_Label';
    my ($field) = $self->Table_find( 'DBField', 'Field_Name', "WHERE Field_Table = '$table' and Field_Name = '$name'" );
    return $field;

}

###################
# Does the list of preliminary action that need to take place after a update or append
#
#
###################
sub create_Recursive_Alias {
###################
    my %args = &filter_input( \@_, -args => 'dbc,table,action', -mandatory => 'dbc|self,table', -self => 'SDB::DBIO' );
    my $self      = $args{-self} || $args{-dbc};
    my $TableName = $args{-table};
    my $action    = $args{-action};
    my $ids       = Cast_List( -list => $args{-ids}, -to => 'string' );
    my $debug     = $args{-debug};
    my $copy_time = &date_time();

    if ( $action =~ /append|insert|update/i ) {
        my $alias_field     = $TableName . '_Alias';
        my $name_field      = $TableName . '_Name';
        my $id_field        = $TableName . '_ID';
        my $secondary_name  = $TableName;
        my $parent_fk_Field = 'FKParent_' . $TableName . '__ID';

        my ($table_type)
            = $self->Table_find( 'DBTable,DBField', 'DBTable_Type',
            "WHERE FK_DBTable__ID = DBTable_ID and DBTable_Name = '$TableName' and (Field_Name = '$alias_field' OR Field_Name = '$name_field' OR Field_Name = '$id_field' OR Field_Name = '$parent_fk_Field') GROUP BY DBTable_ID HAVING Count(*)=4" );

        unless ($table_type) {
            ### This is for special cases where the name field is the same as table name
            ($table_type)
                = $self->Table_find( 'DBTable,DBField', 'DBTable_Type',
                "WHERE FK_DBTable__ID = DBTable_ID and DBTable_Name = '$TableName' and (Field_Name = '$alias_field' OR Field_Name = '$secondary_name' OR Field_Name = '$id_field' OR Field_Name = '$parent_fk_Field') GROUP BY DBTable_ID HAVING Count(*)=4" );
            $name_field = $secondary_name;
        }

        if ( $table_type =~ /recursive/i && $ids ) {

            ### GOTTA FIND CHILDREN ###
            my ($info) = $self->Table_find( "$TableName as child LEFT JOIN $TableName as parent on child.$parent_fk_Field = parent.$id_field", "parent.$alias_field , child.$name_field , child.$parent_fk_Field", " WHERE child.$id_field = $ids" );
            my ( $parent_alias, $child_name, $parent_id ) = split ',', $info;
            my $new_alias;
            if ( !$parent_id ) {
                $new_alias = $child_name;
            }
            else {
                $new_alias = $parent_alias . '-' . $child_name;
            }
            $self->Table_update_array( $TableName, ["$alias_field"], ["$new_alias"], "WHERE $id_field = $ids", -no_triggers => 1, -autoquote => 1 );

            my @children = $self->Table_find( "$TableName", "$id_field", " WHERE $parent_fk_Field = $ids" );
            for my $child (@children) {
                $self->create_Recursive_Alias( -table => $TableName, -action => $action, -ids => $child );

            }
        }
    }

    return;
}
###################
#
#  This copies records to make new records...
#
# (options include:
#    array of fields to exclude from the copy procedure - (in case of unique indexes)
#    specification of time_stamp_field, which will be replaced by current time stamp
#    array of values to insert in place of values from 'exceptions' array above
#
#
###################
sub Table_copy {
###################
    my %args = &filter_input( \@_, -args => 'dbc,table,condition,exclude,time_stamp,replace', -mandatory => 'dbc|self,table', -self => 'SDB::DBIO' );
    my $self              = $args{-self} || $args{-dbc};
    my $TableName         = $args{-table};
    my $condition         = $args{-condition};                              # which records to copy
    my $exception_array   = $args{-exclude};                                # array ref of which fields to exclude from copying...
    my $time_stamp_field  = $args{-time_stamp};
    my $replace_with      = $args{-replace};                                # array of static replacement values for exceptions above
    my $no_triggers       = $args{-no_triggers} || $self->{no_triggers};    # suppress triggers
    my $debug             = $args{-debug} || $self->config('test_mode');
    my $ignore_attributes = $args{-ignore_attributes};                      # doesn't copy attributes of records
    my $no_merge          = $args{-no_merge};                               # don't merge data and copy each record that fits the condition
    my $new_homepage;
    my @new_ids;
    my $copy_time = &date_time();

## gotta make it work for multiple tables

    foreach my $table ( split ',', $TableName ) {
        my ($primary_field) = $self->get_field_info( $table, undef, 'PRI' );
        my @ids = $self->Table_find( $table, $primary_field, $condition, -debug => $debug );
        my @exceptions = @$exception_array if $exception_array;
        my @replacers  = @$replace_with    if $replace_with;
        if ($time_stamp_field) {
            push( @exceptions, $time_stamp_field );
            push( @replacers,  $copy_time );
        }

        my %update;
        my $size = @exceptions - 1;
        for my $index ( 0 .. $size ) {
            $update{ $exceptions[$index] } = $replacers[$index];
        }
        my $list = join ',', @ids;
        @new_ids = $self->combine_records(
            -table             => $table,
            -debug             => $debug,
            -ids               => $list,
            -update            => \%update,
            -no_triggers       => $no_triggers,
            -ignore_attributes => $ignore_attributes,
            -no_merge          => $no_merge,
        );
    }
    my $new_list = join ',', @new_ids;

    return ( $new_list, $copy_time );
}

#
# Simple boolean to see if a given option is activated
##############
sub option {
#############
    my $self   = shift;
    my $option = shift;
    if ( $$self->config('Personalized_Options') =~ /\b$option\b/ ) {
        return 1;
    }
    return 0;
}

#
####################################################################################
# Simple accessor to add record given hash of attributes.
#  (only to be used internally since this evades interface validation processes)
#
# eg
# <snip>
#     my $attributes = {'Original_Source_Name' => 'OS1', 'Defined_Date' => $date};
#     my $original_source_id = add_Record(-table=>'Original_Source',-input=>$attributes);
# </snip>
# Return: new Record ID
#################
sub add_Record {
#################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'table,input', -mandatory => 'table' );
    my $table  = $args{-table};
    my $Input  = $args{-input};
    my $repeat = $args{-repeat} || 1;
    my $debug  = $args{-debug};

    $self->start_trans('add_Records');

    require SDB::HTML;

    my @new_ids;
    foreach my $i ( 1 .. $repeat ) {
        my ( @update_fields, @update_values );

        my @fields = $self->get_fields( -table => $table );
        foreach my $field (@fields) {
            if ( $field =~ /.*\.(\w+) AS /i ) { $field = $1 }
            my $value = SDB::HTML::get_Table_Param( -table => $table, -field => $field, -dbc => $self ) || $Input->{"$table.$field"} || $Input->{$field};

            if ( $self->foreign_key_check($field) ) { $value = $self->get_FK_ID( $field, $value ); }
            if ( defined $value ) {
                push @update_fields, $field;
                push @update_values, $value;
            }
        }

        ## Add record ##
        my $record_id = $self->Table_append_array( $table, \@update_fields, \@update_values, -autoquote => 1, -debug => $debug );
        my $user_id   = $self->get_local('user_id');
        my $date      = date_time();

        ## Add attributes if applicable ##
        my @attributes = $self->Table_find( 'Attribute', 'Attribute_ID,Attribute_Name', "WHERE Attribute_Class = '$table'" );
        foreach my $attribute (@attributes) {
            my ( $attribute_id, $attribute_name ) = split ',', $attribute;
            my $value = SDB::HTML::get_Table_Param( -table => $table, -field => $attribute_name, -dbc => $self ) || $Input->{"$table.$attribute_name"} || $Input->{$attribute_name};

            if ( defined $value ) {
                my $login_table = $self->{login_table};

                my @update_fields = ( 'FK_' . $table . '__ID', "FK_${login_table}__ID", 'Set_DateTime' );
                my @update_values = ( $record_id, $user_id, $date );

                push @update_fields, 'FK_Attribute__ID', 'Attribute_Value';
                push @update_values, $attribute_id, $value;

                my $ok = $self->Table_append_array( $table . '_Attribute', \@update_fields, \@update_values, -autoquote => 1, -debug => $debug );
            }
        }
        push @new_ids, $record_id;
    }
    $self->finish_trans('add_Records');

    return join ',', @new_ids;
}

#######################
sub restore_session {
#######################
    my $self = shift;
    print "RESTORE";

    return $self->{session};
}

#
# Return ordered array of tables (the order in which they should be added to the database)
##################
sub order_tables {
##################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'tables', -mandatory => 'tables' );
    my @remaining = @{ $args{-tables} };
    my $mandatory = defined $args{-mandatory} ? $args{-mandatory} : 1;
    my $context   = $args{-context} || 'append';                                      ## append or query (with left joins) imply different ordering

    my ( @order, @final_order );
    my $count = 0;                                                                    ## counter to prevent endless loop (just in case)
    while ( @remaining || $count++ > 20 ) {
        my @independent = $self->get_independent_tables( \@remaining, -mandatory => $mandatory );    ## get independent tables (based on schema) - use mandatory option
        my ( $noref, $target_ref, $source_ref ) = $self->get_DB_Form_order( \@remaining );           ## get hierarchy from DB_Form

        my @removable = @{ RGmath::union( $noref, $target_ref ) };                                   ## all except tables that reference other tables in DB_Form
        my ($next_ref) = RGmath::intersection( \@independent, \@removable );
        my @next = @{$next_ref};

        unless (@next) { Message("Error: Cannot distinguish intersection of Ind(@independent) & Removable(@removable) tables"); last; }    ## (check Mandatory fields if this error is generated)

        my @priority = $self->form_indexed( \@next );                                                                                      ## break up array further if form_order defined (eg [A,B,C] => [A,B],[C])
        push @order, @priority;

        my @included;
        foreach my $list (@priority) { push @included, @{$list} }                                                                          ## combine all tables included (may span multiple levels - eg A,B,C) into list added in this loop

        @remaining = @{ RGmath::xor_array( \@remaining, \@included ) };                                                                    ## remove tables included in this loop from original list
    }
    foreach my $array (@order) { push @final_order, @$array }                                                                              ## convert array of array refs to simple ordered array (eg [A,B],[C] => (A,B,C))

    return @final_order;
}

# Return exclusive array:
# ( [tables with no DBForm references], [ only references to other tables], [ referenced by other tables]);
###################
sub get_DB_Form_order {
###################
    my %args = &filter_input( \@_, -args => 'dbc,tables', -mandatory => 'self|dbc,tables', -self => 'SDB::DBIO' );
    my $self   = $args{-self} || $args{-dbc};
    my @tables = @{ $args{-tables} };
    my $debug  = $args{-debug} || 0;

    my $list = join "','", @tables;
    my @source_ref = sort $self->Table_find(
        'DB_Form, DB_Form as PForm', 'DB_Form.Form_Table',
        "WHERE DB_Form.Form_Table IN ('$list') AND DB_Form.FKParent_DB_Form__ID=PForm.DB_Form_ID AND PForm.Form_Table IN ('$list')",
        -debug    => $args{-debug},
        -distinct => 1
    );
    if ($debug) {
        Message("Sources: @source_ref");
    }
    my @no_sources = sort @{ RGmath::xor_array( \@tables, \@source_ref ) };
    $list = join "','", @no_sources;

    my @target_ref = sort $self->Table_find( 'DB_Form', 'Form_Table', "WHERE Form_Table IN ('$list')", -debug => $args{-debug}, -distinct => 1 );
    my @no_ref = sort @{ RGmath::xor_array( [@no_sources], [@target_ref] ) };
    return ( \@no_ref, \@target_ref, \@source_ref );
}

####################
#
# Updated method to retrieve order of tables when generating query
#
# This is important when utilizing potential left joins.
#
# Return: array reference to ordered list of tables
#########################
sub query_order {
#########################
    my %args = &filter_input( \@_, -args => 'dbc,tables', -mandatory => 'self|dbc,tables', -self => 'SDB::DBIO' );
    my $self   = $args{-self} || $args{-dbc};
    my $seed   = $args{-seed};
    my @tables = @{ $args{-tables} };
    my $debug  = $args{-debug} || 0;

    my @open_tables = Cast_List( -list => $seed, -to => 'array' );
    my @closed;

    my @Level;
    my @accounted_for;

    my $count = 0;
    while (@open_tables) {
        $count++;
        my @still_open;

        my @nextlevel = sort @open_tables;
        $Level[ $count - 1 ] = \@nextlevel;
        push @accounted_for, @nextlevel;

        foreach my $table (@open_tables) {
            my ( $ref_from, $ref_to ) = $self->schema_references( $table, \@tables );

            if ( !grep /^$table$/, @closed ) { push @closed, $table }

            foreach my $ref (@$ref_from) {
                if ( ( !grep /^$ref$/, @still_open ) && ( !grep /^$ref$/, @closed ) && ( !grep /^$ref$/, @accounted_for ) ) { push @still_open, $ref }
            }

            foreach my $ref (@$ref_to) {
                if ( ( !grep /^$ref$/, @still_open ) && ( !grep /^$ref$/, @closed ) && ( !grep /^$ref$/, @accounted_for ) ) { push @still_open, $ref }
            }
        }

        @open_tables = @still_open;
    }

    my @list;
    foreach my $level (@Level) {
        push @list, @{$level};
    }

    return \@list;
}

#################################
#
# Generate order of tables to be used when appending records.
#
#
#
# Return: array of tables in order of insert
#####################
sub append_order {
#####################
    my %args = &filter_input( \@_, -args => 'dbc,tables', -mandatory => 'self|dbc,tables', -self => 'SDB::DBIO' );
    my $self   = $args{-self} || $args{-dbc};
    my @tables = @{ $args{-tables} };
    my $debug  = $args{-debug} || 0;

    my @complete;
    my @continue = @tables;
    while (@continue) {
        my @continue_again;
        foreach my $table (@continue) {
            my ( $ref_from, $ref_to ) = $self->schema_references( $table, \@continue );
            if   ( int(@$ref_from) == 0 ) { push @complete,       $table; }    ## nothing undefined referenced from this table
            else                          { push @continue_again, $table }
        }
        @continue = sort @continue_again;
    }
    return \@complete;
}

#################################
#
# Return list of tables:
#  * Referenced FROM seed table(s)
#  * References TO seed table
#
# eg:
#
# my ($to, $from) = schema_reference(-seed=>'Plate',-tables=>'Library,Plate,Tube,Employee');
#
#
# $to = ['Employee','Library']
# $from = ['Tube'];
#
# Return:(FROM_array_ref, TO_array_ref)
###########################
sub schema_references {
###########################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'seed,tables', -mandatory => 'seed' );
    my $seed   = $args{-seed};                                                        ## seed table(s) from which to search for references
    my $tables = $args{-tables};                                                      ## list of table(s) to include in search
    my $debug  = $args{-debug};

    my $to_condition = "Foreign_Key LIKE '$seed.%' AND Field_TABLE NOT IN ('$seed')";

    ## generated autoquoted list of applicable foreign keys to seed tables ##
    my @ref_seed_ids = map {
        my $table = $_;
        my ($primary) = $self->get_field_info( -table => $table, -type => 'Primary' );
        "$table.$primary";
    } Cast_List( -list => $seed, -to => 'array' );

    my $seed_tables = Cast_List( -list => $seed, -to => 'string', -autoquote => 1 );
    my $ref_seeds = Cast_List( -list => \@ref_seed_ids, -to => 'string', -autoquote => 1 );

    my $from_condition = "Field_Table IN ($seed_tables) AND Foreign_Key NOT IN ($ref_seeds)";

    if ($tables) {
        my $table_list = Cast_List( -list => $tables, -to => 'string', -autoquote => 1 );

        ## generate auto-quoted list of foreign keys to look for (ie table.primary_id) ##
        my @ref_ids = map {
            my $table = $_;
            my ($primary) = $self->get_field_info( -table => $table, -type => 'Primary' );
            "$table.$primary";
        } Cast_List( -list => $tables, -to => 'array' );

        my $ref_list = Cast_List( -list => \@ref_ids, -to => 'string', -autoquote => 1 );

        $from_condition .= " AND Foreign_Key IN ($ref_list)";
        $to_condition   .= " AND Field_Table IN ($table_list)";
    }

    ## get references FROM seed table(s) ##
    my @references = $self->Table_find( 'DBField', 'Foreign_Key', "WHERE $from_condition", -order_by => 'Foreign_Key', -distinct => 1, -debug => $debug );
    my @referenced = $self->Table_find( 'DBField', 'Field_Table', "WHERE $to_condition",   -order_by => 'Field_Table', -distinct => 1, -debug => $debug );

    ## get references TO seed table(s) ##
    foreach (@references) {
        ## truncate field (leaving table) from retrieved foreign key values ##
        ~s/(.+)\.(.*)/$1/;
    }

    return ( \@references, \@referenced );
}

# simply return an array of array references given an array of tables (ordered based upon Form_Order in DBForm table
# <snip>
# eg given Tables(Form_Order): A(1), B(1), C(2), D(undef)
# form_indexed([A, B, C,D])   returns   ([D],[A,B], [C])
# </snip>
################
sub form_indexed {
################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'tables', -mandatory => 'tables' );
    my @tables = @{ $args{-tables} };

    my $list = join "','", @tables;
    my @indices = $self->Table_find_array(
        'DB_Form', [ 'Form_Table', 'Max(Form_Order) as Forder' ],
        "WHERE Form_Table IN ('$list') GROUP BY Form_Table ORDER BY Form_Order ",
        -debug    => $args{-debug},
        -distinct => 1
    );    ## group to retrieve only one index per Form_Table to avoid conflict.

    my ( %Index, @indexed, @ordered );
    foreach my $form_order (@indices) {
        my ( $table, $index ) = split ',', $form_order;
        push @{ $Index{$index} }, $table;
        push @indexed, $table;
    }

    my @ordered = ( [ sort @{ RGmath::xor_array( \@tables, \@indexed ) } ] );    ## first element is tables NOT indexed
    map {
        my @array = @{ $Index{$_} };
        push @ordered, [ sort @array ];                                          ## default to simple alphabetical at each level
    } sort keys %Index;

    return @ordered;
}

# simply returns tables in given array that are not dependent on other tables in supplied list (based on DB schema defined in DBField, DBTable)
# (option for only paying attention to mandatory dependencies)
########################
sub get_independent_tables {
########################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'tables', -mandatory => 'tables' );
    my @tables    = @{ $args{-tables} };
    my $mandatory = $args{-mandatory};                                                # only pay attention to mandatory dependencies

    my $list = join "','", @tables;
    my $condition = " DBTable_Name IN ('$list') AND Foreign_Key != '' ";
    if ($mandatory) { $condition .= " AND Field_Options LIKE '%Mandatory%'" }
    my @independent;

    foreach my $table (@tables) {
        my $independent = 1;
        foreach my $referenced (@tables) {
            if ( $referenced eq $table ) {next}                                       ##  skip self-references ##
            my @dependencies = $self->Table_find( "DBField, DBTable", 'Field_Name', "WHERE FK_DBTable__ID=DBTable.DBTable_ID AND DBTable_Name = '$table' AND Foreign_Key like '$referenced.%' AND $condition", -debug => $args{-debug} );
            if (@dependencies) {
                $independent = 0;
                last;
            }
        }
        if ($independent) { push @independent, $table }
    }
    return sort @independent;
}

## Simple accessors ##

#################
sub test_mode {
#################
    my $self = shift;
    return $self->{test_mode};
}

###########
sub mode {
###########
    my $self = shift;
    return $self->{mode};    ## eg production, beta, or test ##
}

####################
sub scanner_mode {
####################
    my $self = shift;
    my $set  = shift;

    if ($set) { $self->{scanner_mode} = $set }
    return $set->{scanner_mode};
}
#
# Warning generated only for LIMS admins
#
#
######################
sub admin_warning {
######################
    my %args = &filter_input( \@_, -args => 'dbc,warning', -mandatory => 'self|dbc', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    my $warning = $args{-warning};

    my $dept = $self->get_local('home_dept');
    if ( $dept eq 'Site Admin' ) { $self->warning("Admin warning: $warning") }
    return;
}


#####################################################
# Reset messaging priority level.
# Set to :
#    0 - default - prints only the most high priority messages
#
#    5 - print all (testing , debug) messages
#
######################
sub set_message_priority {
######################
    my %args = &filter_input( \@_, -args => 'dbc,priority', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    my $priority = $args{-priority};

    $self->{messaging} = $priority;
    return;
}

## move message/warning/error from Object.pm ##
##################
sub slow_query {
#############
    my %args = &filter_input( \@_, -args => 'dbc,message', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    my $message = $args{ -message };

    push( @{ $self->{slow_queries} }, $message ) unless ( !$message );
    return;
}
############
sub slow_queries {
############
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    return $self->{slow_queries};
}

##########################################
## Track Table specific DB interactions ##
#############
sub deletion {
#############
    my $self    = shift;
    my $table   = shift;
    my $message = shift;

    push( @{ $self->{deletions}{$table} }, $message ) unless ( !$message );
    return;
}
############
sub deletions {
############
    my $self  = shift;
    my $table = shift;

    if ($table) {
        return $self->{deletions}{$table};
    }
    else {
        return $self->{deletions};
    }
}
#############
sub update {
#############
    my $self    = shift;
    my $table   = shift;
    my $message = shift;

    push( @{ $self->{updates}{$table} }, $message ) unless ( !$message );
    return;
}
############
sub updates {
############
    my $self  = shift;
    my $table = shift;

    if ($table) {
        return $self->{updates}{$table};
    }
    else {
        return $self->{updates};
    }
}

#
# Simple accessor to determine if user has admin access
#
# Return: 1 if admin access available
#####################
sub admin_access {
#####################
    my $self = shift;
    my $dept = shift || $self->config('Target_Department');    ## optional - if not supplied, returns true if admin for any dept available

    if ( defined $self->{Admin_access}{$dept} ) { return $self->{Admin_access}{$dept} }

    if ( $self->config('user') eq 'Admin' ) { return 1 }

    my $Access = $self->get_local('Access');
    if ($Access) {
        my @depts;
        if ($dept) { @depts = grep /^$dept$/, keys %$Access }
        else       { @depts = keys %$Access }
        foreach my $dept (@depts) {
            if ( grep /Admin/i, @{ $Access->{$dept} } ) {
                $self->{Admin_access}{$dept} = 1;
                return 1;
            }
        }
    }

    $self->{Admin_access}{$dept} = 0;
    return 0;
}

###########################
# Reset active database
#############
sub reset_DB {
#############
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'dbase,user,password' );

    my $dbase = $args{-dbase};    ## new database name
    my $user  = $args{-user};     ## new database name
    my $password;                 # = $args{-password};    ## new database name
    my $session = $args{-session};
    my $host = $args{-host} || $self->{host};

    if ( $host eq $self->{host} && $dbase eq $self->{dbase} && $user eq $self->{login_name} && $self->is_Connected() ) { return 1 }

    ## Continue if requiring new connection ##
    $self->disconnect();

    if ($host)  { $self->{host}       = $host }
    if ($dbase) { $self->{dbase}      = $dbase }
    if ($user)  { $self->{login_name} = $user }

    $self->{session} ||= $session;
    ## reset dsn in case this has changed ##
    $self->{dsn} = "DBI:" . $self->{driver} . ":database=$dbase:$host";    # Connection string [String

    my $ping = $self->ping();
    $self->{login_pass} = '';

    # reconnect if connected
    $self->connect( -user => $user, -host => $host, -dbase => $dbase, -force => 1 );

    return $self->is_Connected();
}

############################################################
# Destructor of the object
# - make sure statement handle is finished
# - make sure connection is closed
# - log Slow queries, errors, warnings etc. from Connection.
#
# RETURN: Nothing
############################################################
sub DESTROY {
##############
    my $self  = shift;
    my $debug = $self->{debug_mode};    ## includes logged messages at footer of page if in debug_mode.
    
    my $feedback      = '';
    my $base_dir      = $self->config('logs_data_dir');
    my $subdir = $self->{host} . '/' . $self->{dbase};
    my $home_dir = create_dir($base_dir, $subdir);

    ## Log Messages ##
    if ( @{ $self->messages } ) {
        $feedback .= "\n\n-----------------------------\nMESSAGES\n-----------------------------\n" if $debug;
        $feedback .= join "\n", @{ $self->messages } if $debug;
    }

    ## Log Slow Queries ##
    if ( @{ $self->slow_queries } ) {
        my $slow_dir = "$home_dir/slow_queries/";
        create_dir($home_dir, "slow_queries", -mode=>777);  ## unless ( -e $slow_dir ) {`mkdir -m 777 $slow_dir`}
        my $filename = $slow_dir . &datestamp;
        my $symlink  = $slow_dir . 'current';
        unless ( -e $filename ) {`touch $filename; chmod 777 $filename; rm $symlink; ln -s $filename $symlink`}

        open( SLOW, ">>$filename" );
        print SLOW "Connection: " . $self->get_host() . " : " . $self->get_dbase() . " : " . $self->get_local('user_name') . "\n\n";
        print SLOW join "\n", @{ $self->slow_queries };
        print SLOW try_system_command('top -b -n 1 | head -20');
        print SLOW "\n********************\n";
        close SLOW;
        $feedback .= "\n\n-----------------------------\nSLOW QUERIES\n-----------------------------\n" if $debug;
        $feedback .= join "\n", @{ $self->slow_queries } if $debug;
    }

    ## Log Deletions ##
    if ( keys %{ $self->deletions } ) {
        $feedback .= "\n\n--------------------------\nDELETIONS\n--------------------------\n\n" if $debug;
        foreach my $key ( keys %{ $self->deletions } ) {
            create_dir($home_dir, "deletions/$key", -mode=>777);  ## unless ( -e "$home_dir/deletions/$key/" ) {`mkdir -m 777 $home_dir/deletions/$key`}
            open( SLOW, ">>$home_dir/deletions/$key/" . &datestamp );
            print SLOW "Connection: " . $self->get_host() . " : " . $self->get_dbase() . " : " . $self->get_local('user_name') . "\n\n";
            print SLOW join "\n", @{ $self->deletions($key) };
            close SLOW;
            $feedback .= join "\n", @{ $self->deletions($key) } if $debug;
            $feedback .= "\n\n--------------------------\n\n" if $debug;
        }
    }

    ## Log Updates ##
    if ( keys %{ $self->updates } ) {
        $feedback .= "\n\n---------------------\nUPDATES\n---------------------\n\n" if $debug;
        foreach my $key ( keys %{ $self->updates } ) {
            create_dir($home_dir, "updates/$key", -mode=>777);  ## unless ( -e "$home_dir/updates/$key/" ) {`mkdir -m 777 $home_dir/updates/$key`}
            open( SLOW, ">>$home_dir/updates/$key/" . &datestamp );
            print SLOW "Connection: " . $self->get_host() . " : " . $self->get_dbase() . " : " . $self->get_local('user_name') . "\n\n";
            print SLOW join "\n", @{ $self->updates($key) };
            close SLOW;
            $feedback .= join "\n", @{ $self->updates($key) } if $debug;
            $feedback .= "\n\n--------------------------\n\n" if $debug;
        }
    }

    ## Log Errors ##
    if ( @{ $self->errors } ) {
        create_dir($home_dir, "errors", -mode=>777);  ## unless ( -e "$home_dir/errors/" ) {`mkdir -m 777 $home_dir/errors`}
        open( SLOW, ">>$home_dir/errors/" . &datestamp );
        print SLOW "Connection: " . $self->get_host() . " : " . $self->get_dbase() . " : " . $self->get_local('user_name') . "\n\n";
        print SLOW join "\n", @{ $self->errors };
        close SLOW;
        $feedback .= "\n\n--------------------------\nERRORS\n------------------------\n" if $debug;
        $feedback .= join "\n", @{ $self->errors } if $debug;
    }

    ## Log Warnings ##
    if ( @{ $self->warnings } ) {
        create_dir($home_dir, "warnings", -mode=>777);  ## unless ( -e "$home_dir/warnings/" ) {`mkdir -m 777 $home_dir/warnings`}
        open( SLOW, ">>$home_dir/warnings/" . &datestamp );
        print SLOW "Connection: " . $self->get_host() . " : " . $self->get_dbase() . " : " . $self->get_local('user_name') . "\n\n";
        print SLOW join "\n", @{ $self->warnings };
        close SLOW;
        $feedback .= "\n\n--------------------------\nWARNINGS\n-----------------------------\n" if $debug;
        $feedback .= join "\n", @{ $self->warnings } if $debug;
    }

    ## Log Transactions ##
    if ( @{ $self->transactions } ) {
        create_dir($home_dir, "transactions", -mode=>777);  ## unless ( -e "$home_dir/transactions/" ) {`mkdir -m 777 $home_dir/transactions`}
        my $separator = "*************************************\n";
        open( SLOW, ">>$home_dir/transactions/" . &datestamp );
        print SLOW "Connection: " . $self->get_host() . " : " . $self->get_dbase() . " : " . $self->get_local('user_name') . "\n\n";
        print SLOW join $separator, @{ $self->transactions };
        print SLOW $separator;
        close SLOW;
        $feedback .= "\n\n------------------------------\nTRANSACTIONS\n----------------------------\n" if $debug;
        $feedback .= join $separator, @{ $self->transactions } if $debug;
        $feedback .= $separator if $debug;
    }

    #    $self->finish_trans('DBIO_connect');
    #    $self->finish_trans('DBIO_new');

    if ( $self->{transaction}{start_names} ) { $self->finish_trans( -force => 1 ); }

    if ( $self->{sth} ) { $self->{sth}->finish() }
    $self->disconnect();

    if ( ( $0 =~ /cgi-bin/ ) && $feedback ) {
        $feedback =~ s/\n/<BR>/g;
    }
    Message("******************\nDEBUG Feedback\n*********************\n$feedback\n") if ( $feedback && $debug );
    return;
}

#
# Generate cleaned list of tables given table string parameter for SQL query (which may contain left join or Table as Label sections)
#
#
# Return: array of tables
########################
sub get_Table_list {
########################
    my %args = &filter_input( \@_, -args => 'dbc,tables', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table_list = $args{-tables};

    while ( $table_list =~ s /^(.*?)(\w+)\s*(AS \w+|)\s*(LEFT|RIGHT|INNER|)\s+JOIN\s+(\w+)(.*?)$/$1$2,$5/ ) { }    ## extract simple list in case of joins.

    my @tables = split /\s*,\s*/, $table_list;

    return @tables;
}

# Get a list of fields for a given table
# By default, hidden fields are not included.
#
# <snip>
# Example:
#    my @fields = $dbc->get_field_list(-table=>$table);
#    my @fields = $dbc->get_field_list(-table=>$table,-include=>"hidden");
# </snip>
#
# Return:  Array of fields
####################
sub get_field_list {
####################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table   = $args{-table};
    my $include = $args{-include};    ## Optionally include hidden fields
    my $qualify = $args{-qualify};

    my $condition;
    unless ( $include =~ /hidden/ ) { $condition .= " AND Field_Options NOT LIKE '%Hidden%'" }

    my @fields = $self->Table_find( 'DBField,DBTable', 'Field_Name', "where DBTable_ID=FK_DBTable__ID AND DBTable_Name = '$table' $condition AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'  Order by Field_Order" );
    unless (@fields) {
        @fields = $self->get_fields($table);
    }

    if ($qualify) {
        my @q_fields = map { "$table." . $_ } @fields;
        return @q_fields;
    }
    else { return @fields }
}

#
#
# Include accessor just in case session object is not defined
#
#####################
sub homepage {
#####################
    my $self     = shift;
    my $homepage = shift;

    if   ( $self->session ) { return $self->session->homepage($homepage) }
    else                    { return $self->{homepage} }
}

#
# Include accessor just in case session object is not defined
#
#####################
sub reset_homepage {
#####################
    my $self     = shift;
    my $homepage = shift;

    if ( $self->session ) { $self->session->reset_homepage($homepage) }
    else {
        $self->{homepage} = $homepage;
    }
    return;
}

##############
sub connect {
##############
    my $self = shift;

    my %args        = &filter_input( \@_ );
    my $dbase       = $args{-dbase} || $self->{dbase} || '';                                    # database to connect to (MANDATORY) [String]
    my $login_name  = $args{-user} || $self->{login_name};                                      # login user name (MANDATORY) [String]
    my $login_pass  = $args{-password} || $self->{login_pass};                                  # (MANDATORY unless login_file used) specification of password [String]
    my $login_file  = $args{-login_file} || $self->{login_file} || $self->_get_login_file();    # login_file (specify file containing: 'host:user:password' [String]
    my $trace       = $args{-trace_level} || $self->{trace} || 0;                               # set trace level on database connection (defaults to 0) [Int]
    my $trace_file  = $args{-trace_file} || $self->{trace_file};                                # optional trace_file where trace info to be written. (required if trace_level set)  [String]
    my $quiet       = $args{-quiet} || $self->{quiet} || 0;                                     # suppress printed feedback (defaults to 0) [Int]
    my $host        = $args{-host} || $self->{host};                                            # (MANDATORY unless global default set) host for SQL server. [String]
    my $driver      = $args{-driver} || $self->{driver};                                        # SQL driver  [String]
    my $dsn         = $self->{dsn};                                                             # Connection string [String]
    my $mode        = $args{ -mode } || $self->{mode};
    my $start_trans = $args{ -start_trans } || 0;                                               # Optional flag to indicate starting of transaction
    my $force       = $args{-force} || 0;                                                       # Force re-connection (even if already connected)
    my $sessionless = $args{-sessionless} || 0;

    if ( $self->{connected} && !$force ) { return $self }

    if ( $args{-user} )  { $self->{login_name} = $login_name }                                  ## reset in case this is defined now
    if ( $args{-dbase} ) { $self->{dbase}      = $dbase }                                       ## reset in case this is defined now
    if ( $args{-host} )  { $self->{host}       = $host }                                        ## reset in case this is defined now

    ## Deprecated usage tests below should be skipped if user is connecting as 'read only' - perhaps we can check for certain login users which are okay
    if ( $user ne 'viewer' ) {
        ## check for connection to slave by users other than viewer (read only) ##
        if ( $host eq 'hblims02' && $dbase eq 'bcg' ) { SDB::Errors::log_deprecated_usage( 'trunk.hblims02', -force => 1 ) }
        if ( $host eq $self->config('SLAVE_HOST') && $dbase eq $self->config('SLAVE_DATABASE') ) { require SDB::Errors; SDB::Errors::log_deprecated_usage( "trunk." . $self->config('SLAVE_HOST'), -force => 1 ) }
    }

    if ( $mode && %Configs && $self->config($mode . '_DATABASE') && $self->config($mode . '_HOST') ) {
        ## retrieve database mode ##
        $args{-dbase} = $self->config($mode . '_DATABASE');
        $args{-host}  = $self->config($mode . '_HOST');
    }

    ## provide optional reconnection button if connection fails ##
    my $reconnect;
    if ( $0 =~ /cgi-bin/ && $0 !~ /Web_Service/ ) {
        my $q = new CGI;
        
        use LampLite::Form;
        my $Form = new LampLite::Form(-dbc=>$self);
        $reconnect
            = $BS->warning("Problem connecting to Database [$host.$dbase] as $login_name - Please try again in case this is an intermittent network connection hiccup")
            . $Form->start_Form( -name => 'reload' )
            . LampLite::Login::reload_input_parameters()
            . $q->submit( -name => 'Try Again', -class => 'Action' )
            . $q->end_form();
    }

    $self->SUPER::connect( %args, -login_file => $login_file, -reconnect => $reconnect );

    if ( $self->{connected} ) {
         # Added a condition check to skip the MySQL default database named mysql
        if ( $dbase ne 'mysql' ) {
            if ($self->table_loaded('DBField') && $self->table_loaded('Package') ) {
                my ($package_tracking) = $self->Table_find( 'DBField', 'Field_Name', "WHERE Field_Name = 'Package_Install_Status'" );
                ## not sure if it is better to check for Package_Active or Package_Install_Status - check usage of this local variable...
                if ($package_tracking) {
                    my $packages = join ',', $self->Table_find( 'Package', 'Package_Name', "WHERE Package_Install_Status = 'Installed' AND Package_Active = 'y'" );
                    $self->set_local( 'packages', $packages );
                }
            }
        }
        return $self;
    }
    else {
        print $BS->error("Error connecting to database [$host.$dbase] as $login_name");
#        main::leave($self);
        return;
    }
}

#######################
sub _get_login_file {
#######################
    my $self   = shift;
    my $config = shift;
    
    my $home_dir    = $config->{root}     || $self->config('root');
    my $private_dir = $config->{private_data_dir} || $self->config('Home_private');

    if ( ref $self && $self->{login_file} ) { return $self->{login_file} }

    my $login_file = "$home_dir/conf/mysql.login";
    unless ( -e $login_file ) {
        $login_file = "$private_dir/mysql.login";
    }

    if ( ref $self ) { $self->{login_file} = $login_file }

    return $login_file;

=begin     
    my $login_file_name = "mysql.login";
    my $login_file      = "../conf/" . $login_file_name;
    my $login_prefix    = "../";
    my $cur_file        = $0;

    my $bin        = $FindBin::RealBin;
    my $shell_user = `whoami`;

    if ( $shell_user =~ /web/ && $cur_file =~ /\bcgi-bin\/.*$/xms ) {
        
    }
    elsif ( ( $cur_file =~ /\bbin\/(.*)$/xms ) ) {
        $login_prefix = '';
         ## adjust path to login file based on location of bin/ file  (do not do this for cgi-bin files since path is relative)##
        my $lfile = $2;
        while ( $lfile =~ s/\/\w+// ) { $login_prefix .= "../"; }
    }

    $login_file = $login_prefix . "conf/mysql.login";
    
    if (!-e $login_file) { print $BS->error("Login File: $login_file not found") }
    
    return $login_file;
=cut

}


############################################################
# Get or set the statement handle
# RETURN: The statement handle [Object]
############################################################
sub sth {
    my $self = shift;
    @_ ? ( $self->{sth} = $_[0] ) : $self->{sth};
}

#############################################
# OUTPUT: Extracting Data from the Database #
#############################################

# quick data retrieval from database
# (emulates previous (command)
#
#  This version does NOT require join statements if 'autojoin' option chosen
# RETURN: array of records returned (comma-delimeted between fields)
##############
sub quick_find {
##############
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $field_ref  = $args{-fields};
    my $condition  = $args{-condition};
    my $order      = $args{-order};
    my $group      = $args{-group};
    my $autojoin   = $args{-autojoin};
    my $distinct   = $args{-distinct};
    my @returnvals = ();

    return @returnvals;
}

#
#  data retrieval from database
# (emulates previous Table_retrieve command)
#
#  This version does NOT require join statements if 'autojoin' option chosen)
# RETURN: reference to hash of values.  (keys of which are the fields requested)
####################
sub retrieve_to_hash {
###################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $field_ref = $args{-fields};
    my $condition = $args{-condition};
    my $order     = $args{-order};
    my $group     = $args{-group};
    my $autojoin  = $args{-autojoin};
    my $distinct  = $args{-distinct};

    my %returnvals = {};

    return \%returnvals;
}

# <snip>
# e.g. my ($failed_statements,$success_statements) = $dbc->run_sql_file(-file=>"$full_path",-monitor=>1);
# or my $success = $dbc->run_sql_file(-file=>$full_path);
# </snip>
##################
sub run_sql_file {
##################
    my $self    = shift;
    my %args    = filter_input( \@_, -mandatory => 'file' );
    my $file    = $args{-file};
    my $monitor = $args{-monitor};                             ## returns failed statements & success statements in arrays
    my $debug   = $args{-debug};
    my $Report  = $args{-report};
    my $time    = $args{ -time } || 1;

    my $done;

    my $contents = `cat $file`;
    my @statements = split /;\s*\n/, $contents;

    my @failed_statements;
    my @successful_statements;
    my $error_count = scalar( @{ $self->{errors} } ) unless ( !( defined $self->{errors} ) );
    if ($Report) { $Report->set_Message("Executing SQL statements:") }
    foreach my $statement (@statements) {
        if ($Report) { $Report->set_Message($statement) }

        if ($time) { $self->Benchmark('start_run_sql') = new Benchmark }

        my $sth = $self->query( $statement, -quiet => 1 );

        my $temp_err_cnt = scalar( @{ $self->{errors} } ) unless ( !( defined $self->{errors} ) );
        if ( $temp_err_cnt > $error_count ) {
            $error_count = $temp_err_cnt;
            push @failed_statements, "$statement";
        }
        else {
            push @successful_statements, $statement;
        }

        if ( $time && $Report ) {
            $self->Benchmark('finish_run_sql') = new Benchmark;
            my $time = timediff( $self->Benchmark('finish'), $self->Benchmark('start') );
            my $string = timestr($time);
            if ( $string !~ /\s0 wallclock (.*)\s0.00 CPU/ ) {
                ## report time of execution in all non-zero instances ##
                $Report->set_Message("Execution time: [$string] $DBI::errstr");
            }
        }
        elsif ($debug) { print "$statement [$DBI::errstr]"; }
    }

    if ($monitor) {
        print "\n";
        return ( \@failed_statements, \@successful_statements );
    }
    else {
        if ( scalar(@failed_statements) > 0 ) {
            return 0;
        }
        else {
            return 1;
        }
    }
}

# <snip>
# e.g. my ($failed_statements,$success_statements) = $dbc->run_sql_array(-array=>$array_reference,-monitor=>1);
# </snip>
##################
sub run_sql_array {
##################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $array_ref = $args{-array};
    my $monitor   = $args{-monitor};       ## returns failed statements & success statements in arrays
    my $debug     = $args{-debug};
    my $Report    = $args{-report};
    my $time      = $args{ -time } || 1;
    my $done;
    my @statements;
    my $quiet = 1 unless $debug;

    my @unfiltered_statements = @$array_ref if $array_ref;
    my $completed_line;

    for my $line (@unfiltered_statements) {
        if ( $line =~ /;$/ || $line =~ /;\s+$/ ) {
            $completed_line .= " $line";
            push @statements, $completed_line;
            $completed_line = '';
        }
        else {
            $completed_line .= " $line";
        }
    }

    my @failed_statements;
    my @successful_statements;
    my $error_count = scalar( @{ $self->{errors} } ) unless ( !( defined $self->{errors} ) );
    if ($Report) { $Report->set_Message("Executing SQL statements:") }
    foreach my $statement (@statements) {
        if ($Report) { $Report->set_Message($statement) }

        if ($time) { $self->Benchmark('start_sql_array') }

        my $sth = $self->query( $statement, -quiet => $quiet );

        my $temp_err_cnt = scalar( @{ $self->{errors} } ) unless ( !( defined $self->{errors} ) );
        if ( $temp_err_cnt > $error_count ) {
            $error_count = $temp_err_cnt;
            push @failed_statements, "$statement";
        }
        else {
            push @successful_statements, $statement;
        }

        if ( $time && $Report ) {
            $self->Benchmark('finish_sql_array');
            my $time = timediff( $self->Benchmark('finish_sql_array'), $self->Benchmark('start_sql_array') );
            my $string = timestr($time);
            if ( $string !~ /\s0 wallclock (.*)\s0.00 CPU/ ) {
                ## report time of execution in all non-zero instances ##
                $Report->set_Message("Execution time: [$string] $DBI::errstr");
            }
        }
        elsif ($debug) { Message "$statement [$DBI::errstr]"; }
    }

    if ($monitor) {
        print "\n";
        return ( \@failed_statements, \@successful_statements );
    }
    else {
        if ( scalar(@failed_statements) > 0 ) {
            return 0;
        }
        else {
            return 1;
        }
    }
}

###########################
sub call_stored_procedure {
###########################
    my %args = &filter_input( \@_, -args => 'dbc,sp_name,arguments', -mandatory => 'self|dbc,sp_name', -self => 'SDB::DBIO' );
    my $self    = $args{-self} || $args{-dbc};
    my $debug   = $args{-debug};
    my $sp_name = $args{-sp_name};
    my $statement;
    my $arguments = $args{-arguments};    ## STRING of arguments in the stored procedure

    $statement = "CALL $sp_name($arguments)";
    if ($debug) {
        return $statement;
    }
    my $sth = $self->query( $statement, -quiet => 1 );
    $sth->execute();
    my $data = $sth->fetchall_arrayref();
    $sth->finish();
    return $data;
}
#################################################################
# Retrieve the SQL command used to create the table specified
#
# Input : Table name
#
# Return : Create Table SQL command
#####################
sub create_table_string {
#####################
    my $self  = shift;
    my $table = shift;

    my $sth = $self->query( -query => "SHOW CREATE TABLE $table", -finish => 0 );
    my $string = &format_retrieve( -sth => $sth, -fields => ['Create Table'], -format => 'S' );

    return $string;
}

#######################################################
# Retrieve data from the database using a SQL statement
#
# Return a hashref that contains the data. Return formats are:
#
# - AofH (The default format):
#   $retval[0] = ('Field1' => 'Value1 of first record', 'Field2' => 'Value2 of first record')
#   $retval[1] = ('Field1' => 'Value1 of second record', 'Field2' => 'Value2 of second record')
#
# - HofA (The format used by GSDB::Table_retrieve):
#   $retval{'Field1'} = ['Value1 of first record', 'Value1 of second record']
#   $retval{'Field2'} = ['Value2 of first record', 'Value2 of second record']
#
# - HofH (Use ONE of the retrieved fields as the key to the record hash, or use the reocrd number as the key to the record hash):
#   a) User specified 'Field1' as the keyfield:
#      $retval{'Value1 of first record'}{'Field2'} = 'Value2 of first record'
#      $retval{'Value1 of second record'}{'Field2'} = 'Value2 of second record'
#   b) User did not specified any keyfield:
#      $retval{1}{'Field1'} = 'Value1 of first record'
#      $retval{1}{'Field2'} = 'Value2 of first record'
#      $retval{2}{'Field1'} = 'Value1 of second record'
#      $retval{2}{'Field2'} = 'Value2 of second record'
#
# - AofA (A row-column index 2D matrix):
#   $retval[0] = ['Value1 of first record', 'Value2 of first record']
#   $retval[1] = ['Value1 of second record', 'Value2 of second record']
#
# - RH (This is used when only want to retrieve fields from ONE row):
#   $retval{'Field1'} = 'Value1 of first record'
#   $retval{'Field2'} = 'Value2 of first record'
#
# - RA (This is used when only want to retrieve fields from ONE row):
#   $retval[0] = 'Value1 of first record'
#   $retval[1] = 'Value2 of first record'
#
# - CA (This is used when only want to retrieve ONE field from multiple rows and return values in an arrayref):
#   $retval[0] = 'Value1 of first record'
#   $retval[1] = 'Value1 of second record'
#
# - CS (This is used when only want to retrieve ONE field from multiple rows and return values in a comma-delimited string):
#   $retval = 'Value1 of first reocrd, Value1 of second record'
#
# - S (This is used when only want to retrieve data from ONE field of ONE row):
#   $retval = 'Value1 of first record'
#######################################################
sub SQL_retrieve {
###################
    # <CONSTRUCTION> - can we adapt this to work within Table_retrieve (and make the format options more intuitive (?)
    #
################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    unless ($self) { Call_Stack(); return; }

    my $tables    = $args{-tables};                # The tables to retrieve records from
    my $fields    = $args{-fields};                # The fields to retrieve records from
    my $condition = $args{-condition};             # The query condition
    my $format    = $args{'-format'} || 'AofH';    # The format of the return value [String]
    my $keyfield  = $args{-keyfield};              # The keyfield to be used when using the 'HofH' format. If not specified, then the first hash will be keyed by the record number
    my $params    = $args{-params};                # The parameters (i.e. the values that replace the '?' in the SQL) [ArrayRef]
    my $preserve  = $args{-preserve} || 0;         # Whether to preserve the statement handle [Int
    my $sql       = $args{-sql};                   # The sql statement [String]
    my $debug     = $args{-debug} || 0;            # Debug mode - Prints out debugging information.

    my $retval;
    my $sth;

    # Casting of parameters
    if ($tables) { $tables = Cast_List( -list => $tables, -to => 'string' ) }
    if ($fields) { $fields = Cast_List( -list => $fields, -to => 'string' ) }

    # If user specify tables, fields, conditions instead of the SQL, then we need to build the SQL ourselves.
    if ( !$sql && $tables && $fields ) {
        $sql = "SELECT $fields FROM $tables";
        if ( $condition && $condition =~ /^\s*WHERE/i ) {
            $sql .= " $condition";
        }
        elsif ($condition) {
            $sql .= " WHERE $condition";
        }
    }

    if ($sql) {
        $sth = $self->dbh()->prepare($sql);
        if ($debug) { print "SQL: '$sql'<BR>\n" }
    }
    else {
        $sth = $self->{sth};
    }

    if ( $params && int(@$params) ) {
        my $param_list = join( "','", @$params );
        $sth->execute( eval("'$param_list'") );
    }
    else {
        $sth->execute();
    }

    my $i = 0;
    my $data;
    if ( $format =~ /\bAofA\b/i || $format =~ /\bRA\b/i || $format =~ /\bCA\b/i || $format =~ /\bCS\b/i ) {
        while ( my @row = $sth->fetchrow_array() ) {
            if ( $format =~ /\bRA\b/io ) {
                $retval = \@row;
                last;
            }
            elsif ( $format =~ /\bCA\b/io || $format =~ /\bCS\b/io ) {
                push( @$retval, $row[0] );
            }
            elsif ( $format =~ /\bAofA\b/io ) {
                push( @$retval, \@row );
            }

            $i++;
        }
        if ( $format =~ /\bCS\b/i ) {
            $retval = join( ',', @$retval );
        }
    }
    else {
        while ( my $row = $sth->fetchrow_hashref() ) {
            while ( my ( $field, $value ) = each(%$row) ) {

                if ( $format =~ /\bAofH\b/io || $format =~ /\bRH\b/io || $format =~ /\bHofH\b/io ) {
                    $data->{$field} = $value;
                }
                elsif ( $format =~ /\bS\b/io ) {
                    unless ( $fields && ( $fields ne $field ) ) {
                        $data = $value;
                        last;
                    }
                }
                elsif ( $format =~ /\bHofA\b/io ) {
                    push( @{ $retval->{$field} }, $value );
                }
            }

            if ( $format =~ /\bAofH\b/io ) {
                push( @$retval, $data );
            }
            elsif ( $format =~ /\bHofH\b/io ) {
                if ( $keyfield && exists $data->{$keyfield} ) {
                    $retval->{ $data->{$keyfield} } = $data;
                }
                else {
                    $retval->{ $i + 1 } = $data;
                }
            }
            elsif ( $format =~ /\bRH\b/io || $format =~ /\bS\b/io ) {
                $retval = $data;
                last;
            }

            undef($data);
            $i++;
        }
    }

    if ($preserve) {
        $self->{sth} = $sth;
    }
    else {
        $sth->finish();
    }

    return $retval;
}

# Extract row(s) from table given Field condition
#
#
#   leading to query:
#
#   select $field FROM $TableName WHERE $field LIKE "$like"
#
# <snip>
# Example:
#
# my @entries = $dbc->Table_find("Plate","Plate_ID, Plate_Number", "WHERE Plate_ID = 5000");
# my @entries = Table_find($dbc,"Plate","Plate_ID, Plate_Number", "WHERE Plate_ID = 5000");
#
# </snip>
# Returns: an array of values (containing the comma-delimited list of fields)
####################
sub Table_find {
####################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,condition,distinct', -mandatory => 'dbc|self,fields', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $TableName   = $args{-table};                     # Table to search
    my $fields      = $args{-fields};                    # list of fields to extract
    my $condition   = $args{-condition};                 # 'where' condition,'Order by' or 'Limit' specifications
    my $group_by    = $args{-group_by};
    my $order_by    = $args{-order_by};
    my $distinct    = $args{-distinct};                  # flag to return only distinct fields
    my $debug       = $args{-debug} || $self->config('test_mode');
    my $date_format = $args{-date_format} || 'Simple';
    my $recast      = $args{-recast};                    ## recast integers back to integers (default returns quoted integer value)
    my $limit       = $args{-limit};
    my @field_array = split ',', $fields;

    return $self->Table_find_array( $TableName, \@field_array, $condition, $distinct, -recast => $recast, -debug => $debug, -date_format => $date_format, -group_by => $group_by, -order_by => $order_by, -limit => $limit );
}

#
# SELECT fields FROM Table into array of values
#
# (Same as Table_find, but uses array for list of fields rather than comma-delimited list)
#
# <snip>
# Example:
#
# my @values = $dbc->Table_find_array($TableName,\@field_array,$condition,$distinct);
#
# </snip>
# Return:  Array of values
###########################
sub Table_find_array {
###########################
    #  Same as Table_find, except it uses arrays as inputs
    ## Try new method of auto-setting self object if used in object context ##
    ## require dbc OR self ##

    my %args = &filter_input( \@_, -args => 'dbc,table,fields,condition,distinct', -mandatory => 'dbc|self,fields', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $TableName   = Cast_List(-list=>$args{-table}, -to=>'string'); 
    my $Pfields     = $args{-fields};                    # list of fields to extract
    my $condition   = $args{-condition};                 # 'where' condition,'Order by' or 'Limit' specifications
    my $distinct    = $args{-distinct};                  # flag to return only distinct fields
    my $group_by    = $args{-group_by};
    my $order_by    = $args{-order_by};
    my $debug       = $args{-debug} || $self->config('test_mode');
    my $date_format = $args{-date_format} || 'Simple';
    my $recast      = $args{-recast};                    ## recast integers back to integers (default returns quoted integer value)
    my $limit       = $args{-limit};
    ### Caching options ##
    my $sth_cache = $args{-sth_cache};                   ## optional code for this query indicating that the prepare statement should be cached
    my $sth_input = $args{-sth_input};                   ## input values if using prepared sth

    my @sth_input;
    if ($sth_input) { @sth_input = @$sth_input }

    unless ( $self->ping() ) { print "Database handle not defined"; Call_Stack() }

    my @field_array;
    if ( $Pfields && @$Pfields ) {
        @field_array = @$Pfields;
    }
    else {
        Message("FIELDS NOT DEFINED ?");
    }

    my %resolved_fields;
    my @table_list = $self->get_Table_list($TableName);
    foreach my $field (@field_array) {
        my @resolved = simple_resolve_field( -tables => \@table_list, -field => $field, -debug => $debug, -dbc => $self );
        $resolved_fields{$field} = \@resolved;
    }

    foreach my $table (@table_list) {
        unless ( %Field_Info && defined $Field_Info{$table} ) { $self->initialize_field_info($table) }
    }

    my $fields = join ',', @field_array;

    $condition ||= "";
    my @rvalues;
    my $ref;

    if   ($distinct) { $distinct = "Distinct"; }
    else             { $distinct = ""; }
    my $Table_spec;
    if ($TableName) {

        # Adding parentheses to the tables before LEFT JOIN
        # (1st occurrence) to comply with MySQL 5.1 JOIN Syntax.
        # Ideally we should add parentheses to the queries
        # when they are constructed. But this provides a
        # quick solution to existing queries.

        $TableName =~ s /^(.*?)(\s+LEFT JOIN)/\($1\)$2/i;

        $Table_spec = "FROM $TableName ";
    }

    if ($group_by) {
        $group_by = "GROUP BY $group_by";
    }
    if ($order_by) {
        $order_by = "ORDER BY $order_by";
    }
    if ($limit) {
        $limit = "LIMIT $limit";
    }

    my $query = "SELECT $distinct $fields $Table_spec $condition $group_by $order_by $limit";

    if ($debug) { $self->message("** Retrieve:$query\n"); Call_Stack(); }

    my $start = time();

    my $sth;
    if ($sth_cache) {
        if ( $query !~ /\?/ ) { $self->warning("Cached query ($query) has no variables ?") }

        ### caching sth for faster repeated queries ##
        if ( defined $self->{"cached_sth_$sth_cache"} ) {
            $sth = $self->{"cached_sth_$sth_cache"};
            print '.';
        }
        else {
            ## first time through prepare query and cache sth ##
            $sth = $self->dbh()->prepare($query);
            $self->{"cached_sth_$sth_cache"} = $sth;
            if ( !defined $sth_input ) {
                ## prepare statement only - no need to execute yet ##
                return;
            }
        }
    }
    else {
        ## normal (non-cached) query ##
        $sth = $self->dbh()->prepare($query);
    }
    
    $sth->execute(@sth_input);

    my $end = time();
    $self->_track_if_slow( -message => "Find: $query", -time => $end - $start );

    if ( defined $sth->err() ) {
        my $message = "Table_find_array Error: " . Get_DBI_Error();
        $message .= "\n\nMySQL statement = $query\n\n";
        $self->debug_message($message);
    }

    my $Farray = $sth->fetchall_arrayref();
    $sth->finish();

    my $index = 0;
    while ( defined $Farray->[$index] ) {
        my $returns;
        my @return_values;

        my $Findex = 0;
        foreach my $field (@field_array) {
            my ( $realtable, $realfield ) = @{ $resolved_fields{$field} };

            my $Ftype = $Field_Info{$realtable}{$realfield}{Type};
            my $nextval = recast_value( -value => $Farray->[$index][$Findex], -type => $Ftype, -date_format => $date_format, -field => $field );
            push @return_values, $nextval;
            $Findex++;
        }

        if ( @return_values == 1 ) { $returns = $return_values[0]; }    ## prevents recasting to char if single integer retrieved ##
        elsif ( @return_values > 1 ) { $returns = join ',', @return_values; }

        push( @rvalues, $returns );
        $index++;
    }

    if ($debug) { print Dumper \@rvalues }
    return @rvalues;

    #
    # rewritten removing requirement for array input...
}

#
# Enable sth prepare statement for repeated executions
#
#
####################
sub sth_prepare {
####################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $query = $args{ -query };        # optional replacement values

    my $sth = $self->dbh()->prepare($query);

    return $sth;
}

#
# Execute given sth as required.
# (use with sth_prepare for repeated queries)
#
# Return arrayref
####################
sub sth_execute {
####################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $sth   = $args{ -sth };
    my $value = $args{-value};          # optional replacement values (eg "Select from * where .. = ?")

    if ($value) {
        $sth->execute($value);
    }
    else {
        $sth->execute();
    }
    my $Farray = $sth->fetchall_arrayref();
    $sth->finish();

    return $Farray;
}

###########################
#   It checks and makes sure that all mandatory fields are set
#   Return: 1 on success
#   This function is recommanded for scanner mode where dbfield is being used and JAVAScript is turned off when checking mandatory fields
#
#   Table or Param is mandatory
#   If fields is not set it will use all fields within table that are in parameters
#   Fields does not work without a table
#   The check for Fields that are mandatory only unless force flag is set
###########################
sub check_mandatory_fields {
#########################
    my %args = &filter_input( \@_, -args => 'dbc,tables,fields,condition,params', -mandatory => 'dbc|self,tables|params', -self => 'SDB::DBIO' );
    my $self            = $args{-self} || $args{-dbc};
    my $tables_ref      = $args{-tables};                # Tables to search (array reference)
    my $fields_ref      = $args{-fields};                # list of fields has to be in DBField (array reference)
    my $param_ref       = $args{-params};                # list of params dont have to be in DBField (array reference)
    my $extra_condition = $args{-field_condition};       # additional condition to filter list of fields
    my $force           = $args{-force};                 # Forces the field check even if they are not mandatory for ALL fields
    my $q               = new CGI;
    my $table_list;
    my $fields_list;
    if     ($tables_ref)  { $table_list  = join "','", @$tables_ref }
    if     ($fields_ref)  { $fields_list = join "','", @$fields_ref }
    unless ($fields_list) { $fields_list = join "','", $q->param() }

    my $ok        = 1;
    my $condition = "WHERE Field_Table IN ('$table_list') AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT LIKE '%Hidden%' AND Field_Options NOT RLIKE 'Removed' ";
    if     ($fields_list)     { $condition .= " AND (Field_Name IN ('$fields_list') OR CONCAT(Field_Table,'.',Field_Name) IN ('$fields_list')) " }
    unless ($force)           { $condition .= " AND Field_options LIKE '%Mandatory%' " }
    if     ($extra_condition) { $condition .= $extra_condition }

    my @fields = $self->Table_find( 'DBField', 'Field_Name', $condition );
    require SDB::HTML;
    for my $field (@fields) {
        my $value = SDB::HTML::get_Table_Param( -field => $field, -dbc => $self );
        unless ($value) {
            for my $table (@$tables_ref) {
                $value ||= SDB::HTML::get_Table_Param( -table => $table, -field => $field, -dbc => $self );
                if ($value) {last}
            }
        }
        unless ($value) {
            $ok = 0;
            Message "Field $field is mandatory and has to be filled in before you can continue";
        }
    }

    for my $par (@$param_ref) {
        my $value = $q->param($par);
        unless ($value) {
            $ok = 0;
            Message "The parameter $par is required to continue";
        }
    }

    return $ok;
}

# Select field values FROM Table (into hash)
#
# (Same as Table_find, except it uses arrays as inputs, returns hash)
#
# (this is particularly useful if values retrieved contain commas, as they may be more easily parsed out)
#
#  eg. %Info = &Table_retrieve($dbc,$table,\@fields,$condition);
# <snip>
# Example:
#
# my %values = $dbc->Table_retrieve($TableName,\@fields,$condition,-distinct=>$distinct);
#
# my %values = Table_retrieve($dbc,$TableName,\@fields,$condition,-distinct=>$distinct);
# </snip>
#
# Returns: $Info{field1}, $Info{field2] etc...)
###########################
sub Table_retrieve {
#########################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,condition,distinct,pad,key', -mandatory => 'dbc|self,fields', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $TableName          = $args{-table};                       # Table to search
    my $Pfields            = $args{-fields};                      # list of fields to extract ('*' retrieves all fields with prompts as keys; 'ALL' retrieves all original field names)
    my $condition          = $args{-condition};                   # 'where' condition,'Order by' or 'Limit' specifications
    my $distinct           = $args{-distinct};                    # flag to return only distinct field
    my $tablepad           = $args{-pad};                         # flag to return fully-qualified fields (Table.Field)
    my $key                = $args{-key};                         # key on a field. Warning: this has the same effect as a distinct on that field
    my $quiet              = $args{-quiet};
    my $debug              = $args{-debug} || $self->config('test_mode');           ## flag to allow testing (just returns SQL query)
    my $date_format        = $args{-date_format} || 'Simple';
    my $order_by           = $args{-order_by} || $args{-order};
    my $group_by           = $args{-group_by} || $args{-group};
    my $limit              = $args{-limit};
    my $date_tooltip       = $args{-date_tooltip};
    my $include_attributes = $args{-include_attributes};          ## only applicable when Pfield = '*' or 'ALL' ..
    ### Caching options ##
    my $sth_cache = $args{-sth_cache};                            ## optional code for this query indicating that the prepare statement should be cached
    my $sth_input = $args{-sth_input};                            ## input values if using prepared sth

    my @sth_input;
    if ($sth_input) { @sth_input = @$sth_input }

    my $format = $args{'-format'} || 'HofA';

    my @table_list = $self->get_Table_list($TableName);           ## retrieve list of tables as comma-delimited list from TableName (which may include left joins etc) ##

    foreach my $table (@table_list) {
        unless ( %Field_Info && defined $Field_Info{$table} ) { $self->initialize_field_info( -table => $table ) }
    }

    if ( $Pfields->[0] =~ /^(\*|ALL)$/ ) {
        ## only valid if only one table retrieved..

        $Pfields = [
            map {
                $_ =~ /^([\w\.]+) AS (.+)$/i;
                my $field = $1;
                my $alias = $2;
                if ( $Pfields->[0] eq 'ALL' ) {$field}    ## use original names ##
                elsif ( $alias =~ /\s+/ ) {"$field AS '$alias'"}    ## put in quotes if alias has spaces
                else                      {"$field AS $alias"}
                } $self->get_fields($TableName)
        ];

        if ($include_attributes) {
            ## only applicable with single table queries ##
            ( $TableName, $Pfields ) = $self->include_attributes( $TableName, $Pfields, $condition );
        }
    }

    # Adding parentheses to the tables before LEFT JOIN
    # (1st occurrence) to comply with MySQL 5.1 JOIN Syntax.
    # Ideally we should add parentheses to the queries
    # when they are constructed. But this provides a
    # quick solution to existing queries.

    $TableName =~ s /^(.*?)(\s+LEFT JOIN)/\($1\)$2/i;

    my $Table_spec = '';
    if ($TableName) { $Table_spec = "FROM $TableName"; }

    my @field_array;
    if ($Pfields) {
        @field_array = @$Pfields;
        foreach my $field (@field_array) {
            $field =~ s / AS (\w+)/ AS $1/i;    ## quote fields if alias used (to enable use of keywords in headings ##
        }
    }
    else {
        @field_array = $self->get_fields( \@table_list, undef, 'defined' );    ### (was get_defined_fields) ##
    }

    my %data;
    $condition ||= "";

    my @rvalues;

    if   ($distinct) { $distinct = "Distinct"; }
    else             { $distinct = ""; }

    if ($group_by) {

        # Searches if there is a function in the group by statement
        # e.g. IFNULL()
        
        if ( $group_by !~ /\(.*\)/ ) {
            foreach my $group ( Cast_List( -list => $group_by, -to => 'array' ) ) {
                if ( !grep /(^| AS )$group$/, @field_array ) {
                    push @field_array, $group;
                }
                if ( $group =~ /(.+) AS (.+)/i ) {
                    my $field = $1;
                    $group_by =~ s /$group/$field/g;
                }
            }
        }
        $condition .= " GROUP BY $group_by";
    }

    if ($order_by) {
        $condition .= " ORDER BY $order_by";
    }
    if ($limit) {
        $condition .= " LIMIT $limit";
    }

    my $fields = join ',', @field_array;

    my $query = "SELECT $distinct $fields $Table_spec $condition";
    if ($debug) { $self->message("\n** Retrieve:$query.\n\n"); Call_Stack(); }

    unless ( $self->ping() ) { print "Lost Database handle."; Call_Stack(); return {}; }

    my $start = time();
    $self->{SQL} = $query;
    if ($debug) {
        Message($query) unless $quiet;
    }

    my $sth;
    if ($sth_cache) {
        if ( $query !~ /\?/ ) { $self->warning("Cached query ($query) has no variables ?") }

        ### caching sth for faster repeated queries ##
        if ( defined $self->{"cached_sth_$sth_cache"} ) {
            $sth = $self->{"cached_sth_$sth_cache"};
        }
        else {
            ## first time through prepare query and cache sth ##
            $sth = $self->dbh()->prepare($query);
            $self->{"cached_sth_$sth_cache"} = $sth;
            if ( !defined $sth_input ) {
                ## prepare statement only - no need to execute yet ##
                return;
            }
        }
    }
    else {
        ## normal (non-cached) query ##
        $sth = $self->dbh()->prepare($query);
    }

    #    my $sth   = $self->dbh()->prepare($query);
    # $sth->execute;

    $sth->execute(@sth_input);

    my $end = time();
    $self->_track_if_slow( "Retrieve: $query", -time => $end - $start, -dbc => $self );

    if ( defined $sth->err() ) {
        $self->debug_message( "Error in DBIO Table_retrieve: " . Get_DBI_Error() . "\n$query\n" ) unless $quiet;
        if ($debug) {
            Call_Stack();
            $self->debug_message("MySQL statement = $query");
        }
    }

    my %converted_results = %{ convert_result_set_to_hash( -dbc => $self, -sth => $sth, -field_array => \@field_array, -table_list => \@table_list, -tablepad => $tablepad, -date_format => $date_format ) };

    my @field_list = @{ $converted_results{field_list} };
    %data = %{ $converted_results{data} };

    $sth->finish();

    if ($key) {
        %data = %{ rekey_hash( \%data, $key, -debug => $debug ) };
    }

    #my %keyed_data;
    # the below lines were replaced with the rekey_hash method
    #my $count = 0;
    #while (exists $data{$key}[$count]) {
    #    my $key_value = $data{$key}[$count];
    #    my %single_key;
    #    foreach my $data_key (keys %data) {
    #	$single_key{$data_key} = $data{$data_key}[$count];
    #    }
    #    $keyed_data{$key_value} = \%single_key;;
    #    $count++;
    #}
    #%data = %keyed_data;
    my $retval = &format_retrieve( -format => $format, -value => \%data, -fields => \@field_list );

    if ( $format eq 'HofA' ) {
        return %$retval;
    }
    else {
        return $retval;
    }

}

# Input: sth (after execute/query) and field array
# Return: (hash of result set data using field array as keys)  AND  (field_list) in result_hash
# Converts result set from db query into a hash
#####################
sub convert_result_set_to_hash {
#####################
    my %args        = &filter_input( \@_, -args => 'dbc, sth, field_array, table_list, tablepad, date_format', -mandatory => 'dbc, sth, field_array, table_list' );
    my $dbc         = $args{-dbc};
    my $sth         = $args{ -sth };                                                                                                                                  # sth after db execute
    my @field_array = @{ $args{-field_array} };
    my @table_list  = @{ $args{-table_list} };
    my $tablepad    = $args{-tablepad};
    my $date_format = $args{-date_format} || 'Simple';
    my $ref;
    my %field_hash;
    my $index      = 0;
    my @field_list = ();
    my %data;

    my %resolved_fields;
    foreach my $field (@field_array) {
        my @resolved = simple_resolve_field( -tables => \@table_list, -field => $field, -dbc => $dbc );
        $resolved_fields{$field} = \@resolved;
    }

    while ( $ref = $sth->fetchrow_arrayref ) {
        my $field_index = 0;
        foreach my $field (@field_array) {
            my $showfield = $field;
            my $tabledef  = '';

            my ( $realtable, $realfield ) = @{ $resolved_fields{$field} };

            if ( $showfield =~ /(.+)\sas\s(.+)/i ) {
                $realfield = $1;
                $showfield = $2;
            }

            if ( $realfield =~ /(.+?)\.(.+)/ ) {
                $tabledef  = $1;
                $realfield = $2;
            }
            elsif ( $showfield =~ /(.+?)\.(.+)/ ) {
                $tabledef  = $1;
                $realfield = $2;
                $showfield = $2;
            }
            else { $realfield = $showfield; }

            my $returnval = $ref->[$field_index];    ## defined $ref->[$field_index] ? $ref->[$field_index] : ''; handle in recast_value instead ...

            my $Ftype = $Field_Info{$realtable}{$realfield}{Type} if ( $realtable && $realfield && %Field_Info && defined $Field_Info{$realtable}{$realfield} );
            $Ftype ||= '';

            if ( $tablepad && $tabledef ) {
                $showfield = "$tabledef.$showfield";
            }
            if ( $index == 0 ) {
                push @field_list, $showfield;
            }

            $data{$showfield}[$index] = recast_value( -value => $returnval, -type => $Ftype, -date_format => $date_format, -field => $realfield );

            $field_hash{$showfield} = 1;
            $field_index++;
        }
        $index++;
    }

    my %return_hash = ( data => \%data, field_list => \@field_list );

    return \%return_hash;
}

# Rekey a hash on the value key provided
#
# INPUT:
#   %H = {'k1' => [array1]
#        {'k2' => ....
#
# OUTPUT:
#   %H = {'array1[0]' = {'k1' =>...
#                        'k2' =>...
#
#         'array1[1]' = {'k1' =>...
#                        'k2' =>...
#
#  eg. %rekeyed_hash = &rekey_hash(\%hash,$key);
# <snip>
# Example:
#
# my %values = rekey_hash(\%hash,$key);
#
# </snip>
#
# Returns: \%rekeyd_hash
###########################
sub rekey_hash {
#########################
    # fix
    my %args = &filter_input( \@_, -args => 'hash,key', -mandatory => 'hash,key' );

    my $hashref = $args{-hash};              # hash to rekey
    my $key     = $args{-key};               # hash to rekey
    my $debug   = $args{-debug};
    my %hash    = %{$hashref} if $hashref;

    my %keyed_data;
    if ($key) {

        unless ( defined $hash{$key} ) { return $hashref; }    ## returned no records

        my @new_keys      = @{ $hash{$key} };
        my @original_keys = keys %hash;
        my $index         = 0;
        foreach my $new_key (@new_keys) {
            unless ($new_key) { $new_key = 'undef' }
            foreach my $original_key (@original_keys) {
                push @{ $keyed_data{$new_key}{$original_key} }, $hash{$original_key}[$index];
            }
            $index++;
        }
        return \%keyed_data;
    }
    else {
        return $hashref;
    }

}
############################################################
# Format sth or Table_retrieve returnval
############################################################
sub format_retrieve {
############################################################
    my %args = &filter_input( \@_, -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    if ( $args{ -sth } ) {
        return &sth_retrieve_format(%args);
    }
    else {
        return &Table_retrieve_format(%args);
    }
}

############################################################
# Formats table_retrieve return values to a specified structure.
#
# Available formats are:
#
# - AofH:
#   $retval[0] = ('Field1' => 'Value1 of first record', 'Field2' => 'Value2 of first record')
#   $retval[1] = ('Field1' => 'Value1 of second record', 'Field2' => 'Value2 of second record')
#
# - HofA (The format used by GSDB::Table_retrieve):
#   $retval{'Field1'} = ['Value1 of first record', 'Value1 of second record']
#   $retval{'Field2'} = ['Value2 of first record', 'Value2 of second record']
#
# - HofH (Use ONE of the retrieved fields as the key to the record hash, or use the reocrd number as the key to the record hash):
#   a) User specified 'Field1' as the keyfield:
#      $retval{'Value1 of first record'}{'Field2'} = 'Value2 of first record'
#      $retval{'Value1 of second record'}{'Field2'} = 'Value2 of second record'
#   b) User did not specified any keyfield:
#      $retval{1}{'Field1'} = 'Value1 of first record'
#      $retval{1}{'Field2'} = 'Value2 of first record'
#      $retval{2}{'Field1'} = 'Value1 of second record'
#      $retval{2}{'Field2'} = 'Value2 of second record'
#
# - AofA (A row-column index 2D matrix):
#   $retval[0] = ['Value1 of first record', 'Value2 of first record']
#   $retval[1] = ['Value1 of second record', 'Value2 of second record']
#
# - RH (This is used when only want to retrieve fields from ONE row):
#   $retval{'Field1'} = 'Value1 of first record'
#   $retval{'Field2'} = 'Value2 of first record'
#
# - RA (This is used when only want to retrieve fields from ONE row):
#   $retval[0] = 'Value1 of first record'
#   $retval[1] = 'Value2 of first record'
#
# - CA (This is used when only want to retrieve ONE field from multiple rows and return values in an arrayref):
#   $retval[0] = 'Value1 of first record'
#   $retval[1] = 'Value1 of second record'
#
# - CS (This is used when only want to retrieve ONE field from multiple rows and return values in a comma-delimited string):
#   $retval = 'Value1 of first reocrd, Value1 of second record'
#
# - S (This is used when only want to retrieve data from ONE field of ONE row):
#   $retval = 'Value1 of first record'
############################################################
sub Table_retrieve_format {
############################################################

    my %args = &filter_input( \@_, -args => 'value,fields,format,keyfield,group_concat' );

    ## Arguments for Table_retrieve output
    my $value  = $args{-value};     # (Hashref) Table_retrieve return value
    my $fields = $args{-fields};    # (ArrayRef) The fields to retrieve records from

    ## General arguments
    my $keyfield     = $args{-keyfield};        # (Scalar) The keyfield to be used when using the 'HofH' format.
    my $group_concat = $args{-group_concat};    # (Scalar) Flag that determines whether to overwrite duplicate keys, or to push them into an array
    my $format       = $args{'-format'};        # (Scalar) Format to convert the return value to.

    # cast array reference to an array
    my @fields_array = @{$fields} if ($fields);

    my $data;

    ## Degenerate cases - for efficiency, 'simple' cases do not go through the main loop

    # Hash of Arrays
    # default, no need for comversion
    if ( $format eq 'HofA' ) {
        return $value;
    }

    # Column Array
    # get the first field arrayref and return the arrayref
    if ( $format eq 'CA' ) {
        return $value->{ $fields->[0] };
    }

    # Column Scalar
    # get the first field arrayref, concat into a string, and return the scalar
    if ( $format eq 'CS' ) {
        return join( ',', @{ $value->{ $fields->[0] } } );
    }

    # Scalar
    # get the first field, first row, and return the scalar
    if ( $format eq 'S' ) {
        return $value->{ $fields->[0] }[0];
    }

    ## Main Loop
    # iterates through each field (@fields_array) and each row for that field ($value->{$field})
    foreach my $col ( 0 .. $#fields_array ) {
        my $field = $fields->[$col];

        foreach my $i ( 0 .. int( @{ $value->{$field} } ) - 1 ) {
            my $element = $value->{$field}[$i];

            # Row Array
            # return the first row
            # Algorithm:
            # iterate through each column,
            # 1. get the 0th element (the first row value),
            # 2. push into array,
            # 3. move to the next column
            if ( $format eq 'RA' ) {
                unless ( defined $data ) {
                    $data = [];
                }
                push( @$data, $element );
                last;
            }

            # Row Hash
            # return the first row
            # Algorithm:
            # iterate through each column,
            # 1. get the 0th element (the first row value),
            # 2. assign into hash, with field -> element value,
            # 3. move to the next column
            elsif ( $format eq 'RH' ) {
                $data->{$field} = $element;
                last;
            }

            # Array of Hashes
            # Algorithm:
            # iterate through each column
            # 1. if this array position $i does not exist, create the array position and assign an empty hash
            # 2. Assign the current field to this array position's hash, with the element as the value
            # 3. move to the next column
            elsif ( $format eq 'AofH' ) {
                unless ( defined $data ) {
                    $data = [];
                }
                unless ( defined $data->[$i] ) {
                    $data->[$i] = {};
                }
                $data->[$i]{$field} = $element;
            }

            # Array of Arrays
            # Algorithm:
            # iterate through each column
            # 1. If this array position $i does not exist, create this array position and assign an empty array
            # 2. Push the current element into the current array position $i
            elsif ( $format eq 'AofA' ) {
                unless ( defined $data ) {
                    $data = [];
                }
                unless ( defined $data->[$i] ) {
                    $data->[$i] = [];
                }
                push( @{ $data->[$i] }, $element );
            }

            # Hash of Hashes
            # Algorithm
            # iterate through each column
            # 1. Check if the group_concat flag is on
            # 2. If it is, push the current element into the hash,
            #    with the keys as {value of the keyfield} {current field name}
            # 3. If it is not, overwrite the value of the hash
            #    with the keys as {value of the keyfield} {current field name}
            elsif ( $format eq 'HofH' ) {
                if ($group_concat) {
                    unless ( defined $data->{ $value->{$keyfield}[$i] }{$field} ) {
                        $data->{ $value->{$keyfield}[$i] }{$field} = [];
                    }
                    push( @{ $data->{ $value->{$keyfield}[$i] }{$field} }, $element );
                }
                else {
                    $data->{ $value->{$keyfield}[$i] }{$field} = $element;
                }
            }
        }
    }

    # return reference
    return $data;
}

#######################################################
# Format stringhandle return values
#
# Return a hashref that contains the data. Return formats are:
#
# - AofH (The default format):
#   $retval[0] = ('Field1' => 'Value1 of first record', 'Field2' => 'Value2 of first record')
#   $retval[1] = ('Field1' => 'Value1 of second record', 'Field2' => 'Value2 of second record')
#
# - HofA (The format used by GSDB::Table_retrieve):
#   $retval{'Field1'} = ['Value1 of first record', 'Value1 of second record']
#   $retval{'Field2'} = ['Value2 of first record', 'Value2 of second record']
#
# - HofH (Use ONE of the retrieved fields as the key to the record hash, or use the reocrd number as the key to the record hash):
#   a) User specified 'Field1' as the keyfield:
#      $retval{'Value1 of first record'}{'Field2'} = 'Value2 of first record'
#      $retval{'Value1 of second record'}{'Field2'} = 'Value2 of second record'
#   b) User did not specified any keyfield:
#      $retval{1}{'Field1'} = 'Value1 of first record'
#      $retval{1}{'Field2'} = 'Value2 of first record'
#      $retval{2}{'Field1'} = 'Value1 of second record'
#      $retval{2}{'Field2'} = 'Value2 of second record'
#
# - AofA (A row-column index 2D matrix):
#   $retval[0] = ['Value1 of first record', 'Value2 of first record']
#   $retval[1] = ['Value1 of second record', 'Value2 of second record']
#
# - RH (This is used when only want to retrieve fields from ONE row):
#   $retval{'Field1'} = 'Value1 of first record'
#   $retval{'Field2'} = 'Value2 of first record'
#
# - RA (This is used when only want to retrieve fields from ONE row):
#   $retval[0] = 'Value1 of first record'
#   $retval[1] = 'Value2 of first record'
#
# - CA (This is used when only want to retrieve ONE field from multiple rows and return values in an arrayref):
#   $retval[0] = 'Value1 of first record'
#   $retval[1] = 'Value1 of second record'
#
# - CS (This is used when only want to retrieve ONE field from multiple rows and return values in a comma-delimited string):
#   $retval = 'Value1 of first reocrd, Value1 of second record'
#
# - S (This is used when only want to retrieve data from ONE field of ONE row):
#   $retval = 'Value1 of first record'
#######################################################
sub sth_retrieve_format {
###################
    my %args = filter_input( \@_, -args => 'sth,format,fields', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $retval;
    my $sth      = $args{ -sth };                 # (ObjectRef) Stringhandle
    my $format   = $args{'-format'} || 'AofH';    # (Scalar) The format of the return value
    my $fields   = $args{-fields};                # (ArrayRef) Field/s to retrieve values from
    my $keyfield = $args{-keyfield};              # (Scalar) The keyfield to be used when using the 'HofH' format.

    # cast array reference to an array
    my @fields_array = @{$fields} if ($fields);

    my $i = 0;

    my $data;
    if ( $format =~ /\bAofA\b/i || $format =~ /\bRA\b/i || $format =~ /\bCA\b/i || $format =~ /\bCS\b/i ) {
        if ( $fields && int(@$fields) > 0 ) {
            while ( my $row = $sth->fetchrow_hashref() ) {
                my @rowarray = ();
                foreach my $field (@$fields) {
                    push( @rowarray, $row->{$field} );
                    if ( $format =~ /\bCA\b/io || $format =~ /\bCS\b/io ) {
                        last;
                    }
                }

                if ( $format =~ /\bRA\b/io ) {
                    $retval = \@rowarray;
                    last;
                }
                elsif ( $format =~ /\bCA\b/io || $format =~ /\bCS\b/io ) {
                    push( @$retval, $rowarray[0] );
                }
                elsif ( $format =~ /\bAofA\b/io ) {
                    push( @$retval, \@rowarray );
                }
                $i++;
            }
            if ( $format =~ /\bCS\b/i ) {
                $retval = join( ',', @$retval );
            }
        }
        else {
            while ( my @row = $sth->fetchrow_array() ) {
                if ( $format =~ /\bRA\b/io ) {
                    $retval = \@row;
                    last;
                }
                elsif ( $format =~ /\bCA\b/io || $format =~ /\bCS\b/io ) {
                    push( @$retval, $row[0] );
                }
                elsif ( $format =~ /\bAofA\b/io ) {
                    push( @$retval, \@row );
                }

                $i++;
            }
            if ( $format =~ /\bCS\b/i ) {
                $retval = join( ',', @$retval );
            }
        }
    }
    else {
        while ( my $row = $sth->fetchrow_hashref() ) {
            while ( my ( $field, $value ) = each(%$row) ) {
                if ( ($fields) && ( int(@$fields) > 0 ) && !( grep( /^$field$/, @$fields ) ) ) {
                    next;
                }
                if ( $format =~ /\bAofH\b/io || $format =~ /\bRH\b/io || $format =~ /\bHofH\b/io ) {
                    $data->{$field} = $value;
                }
                elsif ( $format =~ /\bS\b/io ) {
                    unless ( $fields_array[0] && ( $fields_array[0] ne $field ) ) {
                        $data = $value;
                        last;
                    }
                }
                elsif ( $format =~ /\bHofA\b/io ) {
                    push( @{ $retval->{$field} }, $value );
                }
            }

            if ( $format =~ /\bAofH\b/io ) {
                push( @$retval, $data );
            }
            elsif ( $format =~ /\bHofH\b/io ) {
                if ( $keyfield && exists $data->{$keyfield} ) {
                    $retval->{ $data->{$keyfield} } = $data;
                }
                else {
                    $retval->{ $i + 1 } = $data;
                }
            }
            elsif ( $format =~ /\bRH\b/io || $format =~ /\bS\b/io ) {
                $retval = $data;
                last;
            }

            undef($data);
            $i++;
        }
    }

    $sth->finish();

    return $retval;
}

#
# A simple variation on Table_retrieve_display that separates the output into N layers.
#
# Each layer represents the identical query results grouped by the 'layer' parameter.
#
# All arguments are identical to Table_retrieve_display, with the added paramter:
#
# -layer => $layer_by
#
# eg. print layer_display(
#      -table=>'Employee,Department',
#      -fields=>['Employee_Name','FK_Department__ID'],
#      -return_html=>1,
#      -layer=>'Department_Name',
#      -condition=>"WHERE FK_Department__ID=Department_ID");
#
# Note: This should not be used inside an existing layer (recursive layering causes problems)
#
# Returns: a list of employees with layered tabs for each department name
#
#######################
sub layer_display {
#######################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,condition,distinct,title,return_html', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $layer_by = $args{-layer};
    $args{-layer} = '';    ## clear layer args if supplied.

    my $fields = $args{-fields};              ## preserve field list.
    my $condition = $args{-condition} || 1;

    $args{-fields} = ["Distinct $layer_by"];
    my @layers = Table_find_array(%args);

    $args{-fields} = $fields;
    my $output;
    my %Layers;
    my @order;
    foreach my $layer ( sort @layers ) {
        $args{-condition} = "$condition AND $layer_by = '$layer'";
        $Layers{$layer} = Table_retrieve_display(%args);
        push @order, $layer;
    }

    require SDB::HTML;
    return SDB::HTML::define_Layers( -layers => \%Layers, -order => \@order, -print => 1 );
}

#
#
#  eg my $ref = $dbc->ref_table_loaded(-table=>'Sample_Type',-field=>'Sample_Type',-value=>'DNA');
##########################
sub ref_table_loaded {
##########################
    my %args = &filter_input( \@_, -args => 'dbc,table,field,value', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $ref_table = $args{-table};
    my $ref_field = $args{-field};
    my $value     = $args{-value};

    my ($primary) = $self->get_field_info( -type => 'Primary' );

    ## determine indirectly referenced table ##
    my ($table) = $self->Table_find( $ref_table, $ref_field, "WHERE $primary = '$value'" );

    if ( !$table ) {return}    ## undefined table

    my $found = $self->query( "SHOW TABLES LIKE '$table'", -finish => 0 );    # ->execute();
    if ( $found eq '0E0' ) { return 0 }                                       ## Table not found ##

    $table = '';
    if ($found) {
        my @tables = $found->fetchrow_array;
        if ( int(@tables) == 1 ) {
            $table = $tables[0];
        }
    }
    return $table;
}

#
#  Simple accessor to determine if a field exists.
#
#  This is useful for code logic that may only be relevant if a certain field is loaded.
#   (generally this sort of coding should be avoided, but this at least enables the coder to avoid having the code break)
#
# Return: array of fields matching test (null if nothing found)
####################
sub field_exists {
####################
    my $self  = shift;
    my $table = shift;
    my $field = shift;

    if ( !$field && $table =~ /(.*)\.(.*)/ ) { $table = $1; $field = $2; }
    else                                     { $field ||= '%' }

    if ( !$self->table_loaded($table) ) {return}

    my $found = $self->query( "SHOW FIELDS FROM $table LIKE '$field'", -finish => 0 );
    if ( $found eq '0E0' ) {return}

    my @fields;
    if ($found) {
        while ( my @f = $found->fetchrow_array ) {
            if ( $f[0] ) {
                push @fields, $f[0];
            }
        }
    }

    if   (@fields) { return @fields }
    else           {return}
}

#
# Get sub types for any object
#
# This recursively looks inside sub_types if there is a sub_type table and retrieves the array of type attributes and additional tables
#
#
# Return \@array_of_types, \@array_of_tables
################
sub get_type {
################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'table,id', -mandatory => 'table,id' );
    my $table     = $args{-table};
    my $sub_table = $args{-sub_table};
    my $id        = $args{-id};
    my $id_field  = $args{-id_field};
    my $fk        = $args{-fk};
    my $debug     = $args{-debug};

    my $look_at_table = $table;
    if ($sub_table) {
        ## looking at sub_table - use primary
        $look_at_table = $sub_table;
    }

    my ($primary_field) = $self->get_field_info( $look_at_table, undef, 'Primary' );    ## eg Library_Name
    $id_field ||= $primary_field;

    my ($type_field) = $self->Table_find( 'DBTable,DBField', 'Field_Name', "WHERE FK_DBTable__ID=DBTable_ID AND Field_Name = '${look_at_table}_Type'" );

    my @types;
    my @tables = ();
    if ($type_field) {
        my ($sub_type_info) = $self->Table_find( $look_at_table, "$type_field, $primary_field", "WHERE $id_field = '$id'", -debug => $debug );
        my ( $sub_type, $sub_id ) = split ',', $sub_type_info;
        if ($sub_type) {
            push @types, $sub_type;
        }
        $sub_type .= "_$table";    ## eg Run_Type = 'SOLID', add SOLID_Run table if it exists...

        ## <CUSTOM - temporary>
        if ( $sub_type =~ /RNA\/DNA_Library/ ) { $sub_type = 'RNA_DNA_Collection' }

        if ( $self->table_loaded($sub_type) && ( $sub_table ne $sub_type ) ) {
            push @tables, $sub_type;
            if ($sub_id) {
                ## continue recursively if FK defined ##
                my $fk_id_field = $primary_field;
                $fk_id_field =~ s/(.*)_(.+)/FK_$1__$2/;

                my ( $sub_type, $sub_tables ) = $self->get_type( $table, -id => $sub_id, -id_field => $fk_id_field, -sub_table => $sub_type, -debug => $debug );
                if ($sub_type) {
                    push @types, @$sub_type;
                }
                if (@$sub_tables) {
                    push @tables, @$sub_tables;
                }
            }
        }
    }

    return ( \@types, \@tables );
}

##################################################
#
#
# <snip>
# e.g. $active = $dbc->package_active($addon_name);
# </snip>
##################
sub package_active {
###################
    my $self = shift;
    my $name = shift;

    return ( $self->get_local('packages') =~ /\b$name\b/ );

}
#######################
# Finds records that reference this record (check foreign keys that point to this record)
#
#
# Return:  hash $Hash{$table.$field}  = $count  (where count is number of references)
#########################
sub get_reference_hash {
#########################
    #
    #  Find other tables that point to this table...
    #
    #
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table                  = $args{-table};
    my $hash                   = $args{-hash};                     ## optionally specify 'field=>id'  (allows reference to specific record(s) to be returned)
    my $Type                   = $args{-type};                     ## type
    my $reference_type         = $args{-reference_type};           ## limit to reference types ofrom a particular table
    my $indirect               = $args{-indirect};
    my $starting_condition     = $args{-condition} || 1;
    my $debug                  = $args{-debug};
    my $exclude_self_reference = $args{-exclude_self_reference};
    my %Specs;

    if ($hash) { %Specs = %$hash; }
    my $check_condition = "where FK_DBTable__ID=DBTable_ID AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed' AND Foreign_Key like '$table.%'";

    if ($reference_type) {
        my $reference_types = Cast_List( -list => $reference_type, -to => 'string', -autoquote => 1 );
        $check_condition .= " AND DBTable_Name IN ($reference_types)";
    }
                
    my @checks = $self->Table_find( 'DBField,DBTable', 'DBTable_Name,Field_Name,Foreign_Key,DBTable_Type', $check_condition );
    my @conditions = ($starting_condition);    ### fill list of conditions (generally only one like 'FK_Employee__ID = 25')
    if ($hash) {
        foreach my $key ( keys %Specs ) {
            my $value = Cast_List( -list => $Specs{$key}, -to => 'string', -autoquote => 1 );
            push @conditions, "$key IN ($value)";
        }
    
    }
    my $condition = join ' AND ', @conditions;

    my %Ref;
    
    foreach my $check (@checks) {
        my ( $Rtable, $Rfield, $fkname, $type ) = split ',', $check;
        my $tables = "$table,$Rtable";
        if ( $Rtable eq $table ) { $tables = $table; }    #### dont list table twice if it the same one...(checking recursive references)

        if ( !$self->table_loaded($Rtable) ) {next}       ## skip if this table is not currently loaded into schema ##
        
        if ($hash) {
            my $local_condition;
            my @found;

            if ( $tables !~ /,/ ) {
                my ($pri) = $self->get_field_info( $tables, undef, 'Primary' );
                my $list = $Specs{$pri} || $Specs{"$tables.$pri"};
                my $value = Cast_List( -list => $list, -to => 'string', -autoquote => 1 );
                
                $local_condition = "$Rtable.$Rfield IN ($value)";
                if ($exclude_self_reference) { $local_condition .= " AND $Rfield <> $pri" }
                @found = $self->Table_find( "$tables", $Rfield, "WHERE $local_condition", -distinct=>1, -debug => $debug );
            }
            else {
                $local_condition = "$Rtable.$Rfield=$fkname and Length($fkname) > 0 AND $fkname IS NOT NULL AND $condition";
                @found = $self->Table_find( "$tables", $fkname, "WHERE $local_condition", -distinct=>1, -debug => $debug );
            }
            if ( @found && ( $found[0] =~ /[1-9a-zA-Z]/ ) ) { push( @{ $Ref{"$Rtable.$Rfield"} }, @found ); }
        }
        else { push( @{ $Ref{"$Rtable.$Rfield"} }, $fkname ) }
        $Type->{"$Rtable.$Rfield"} = $type;
    }

    #########################
    ## Indirect References ##
    #########################

    if ($indirect) {
        #########################
        # 1. Object / Object_Class
        #########################

        my ($class_id) = $self->Table_find( "Object_Class", "Object_Class_ID", "WHERE Object_Class='$table'" );
        if ($class_id) {
            my @objects = $self->Table_find( 'DBField', 'Field_Table,Field_Name', "WHERE Field_Name like 'Object_ID' and Field_Options NOT RLIKE 'Obsolete' AND Field_Options NOT RLIKE 'Removed'" );
            foreach my $object (@objects) {
                my ( $Otable, $Ofield ) = split ',', $object;
                my %records = $self->Table_retrieve( "$Otable,$table", [$Ofield], "WHERE FK_Object_Class__ID=$class_id AND Object_ID=${table}_ID AND $condition" );
                if (%records) {
                    my $found = int( @{ $records{$Ofield} } );
                    if ($debug) { print "$Otable : $found\n" }
                    push @{ $Ref{"$Otable.$Ofield"} }, @{ $records{$Ofield} };
                }
                else {
                    if ($debug) { print "(no $Otable references)\n" }
                }
            }
        }

        foreach my $key ( keys %Specs ) {
            my $list = Cast_List( -list => $Specs{$key}, -to => 'string', -autoquote => 1 );

            #########################
            # 2. Record_ID
            #########################
            my %records = $self->Table_retrieve( 'Change_History, DBField', ['Change_History_ID'], "WHERE DBField_ID = FK_DBField__ID and Field_Table = '$table' and Record_ID IN($list)" );
            if ( $records{Change_History_ID} ) {
                my $found                = int( @{ $records{Change_History_ID} } );
                my $qualified_field_name = "Change_History.Change_History_ID";
                push @{ $Ref{"$qualified_field_name"} }, @{ $records{Change_History_ID} };
            }

            #########################
            # 3.  Attribute FK References
            #########################
            my $fk_pattern = 'FK%' . $table . '%ID';
            my %attribute_objects = $self->Table_retrieve( "Attribute", [ "Attribute_ID", 'Attribute_Class', 'Attribute_Type' ], "WHERE Attribute_Type LIKE '$fk_pattern'" );
            if ( $attribute_objects{Attribute_Class} ) {
                my $size = int @{ $attribute_objects{Attribute_Class} };

                for my $index ( 0 .. $size - 1 ) {
                    my $class                 = $attribute_objects{Attribute_Class}[$index];
                    my $att_id                = $attribute_objects{Attribute_ID}[$index];
                    my $attribute_class_table = $class . '_Attribute';
                    my $foreign_key;
                    if ( $class eq 'Library' ) {
                        $foreign_key = "FK_" . "$class" . "__Name";
                    }
                    else {
                        $foreign_key = "FK_" . "$class" . "__ID";
                    }
                    my %results = $self->Table_retrieve( "$attribute_class_table", ["$foreign_key"], "WHERE Attribute_Value IN ($list) and FK_Attribute__ID = $att_id" );

                    my $qualified_field_name = "$attribute_class_table." . $attribute_objects{Attribute_Type}[$index];
                    if ( $results{$foreign_key} ) {
                        push @{ $Ref{"$qualified_field_name"} }, @{ $results{$foreign_key} };
                    }
                }
            }
        }
    }

    return \%Ref;
}

#  (comma-delimited list of links to external references , comma-delimited list of links to external references that are labelled as 'Detail' tables (eg. tables with 1-to-1 references to this table that may be safely removed if record removed)
#
# RETURN: list of links to this record (array)
#######################
sub get_references {
#######################
    my %args = &filter_input( \@_, -args => 'dbc,table,hash', -mandatory => 'dbc|self,table', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table                  = $args{-table};
    my $hash                   = $args{-hash};                     ## optionally specify 'field=>id'  (allows reference to specific record(s) to be returned)
    my $indirect               = $args{-indirect};
    my $debug                  = $args{-debug};
    my $field                  = $args{-field};
    my $value                  = $args{-value};
    my $condition              = $args{-condition};
    my $type                   = $args{-type};                     ## optionally specify a type of reference
    my $exclude_self_reference = $args{-exclude_self_reference};

    if ( $field && $value ) { $hash = { $field => $value } }       ## alternative input format

    my %Type;
    my %Ref = %{ $self->get_reference_hash( -table => $table, -hash => $hash, -type => \%Type, -indirect => $indirect, -debug => $debug, -reference_type => $type, -condition => $condition, -exclude_self_reference => $exclude_self_reference ) };

    my @ref_list;
    my @detail_list;

    my $mode = $self->{mode};
    foreach my $key ( keys %Ref ) {
        my ( $ref_tab, $ref_fld ) = split( /\./, $key );
        my $ref_id = join ',', @{ unique_items( $Ref{$key} ) };

        my $reference = &Link_To( $self->config('homelink'), "$ref_tab", "&Database_Mode=$mode&Info=1&Table=$ref_tab&Field=$ref_fld&Like=$ref_id", $Settings{LINK_COLOUR}, ['newwin'] );
        if ( $Type{$key} =~ /Detail/i ) {
            push( @detail_list, $reference );
        }
        else {
            push( @ref_list, $reference );
        }
    }
    my $refs    = join ', ', @ref_list;
    my $details = join ', ', @detail_list;
    my @returnvals = ( $refs, $details, \%Ref );

    return @returnvals;
}

#################################
# INPUT : Inserting into the Database #
#################################

###################################################
# Simple record append to a single table (though multiple records may be added at one time)
# (supply fields, and values for insertion)
#
# May supply multiple values in form:
#     $values{1} = ('1','b','George'); $values{2} = ('2','d','Julie');   (send -values=>\%values)
#   .. or single value in form:
#     @values = ('1','b','George');     ... and send -values=>\@values
#
# Table specification is optional, but is necessary to auto-update foreign keys or if multiple tables share field names.
#
# RETURN : %returnval.
#       $returnval{newids} = list of newids (primary values)
#       $returnval{updated} = # of records added
######################
sub simple_append {
######################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table     = $args{-table}  || $self->{update_table};     # table to update
    my $field_ref = $args{-fields} || $self->{update_fields};    # fields to insert into
    my $value_ref        = $args{ -values };                               # values to insert
    my $autoquote        = $args{-autoquote};                              # (optional) - autoquotes text (standard)
    my $sth              = $args{ -sth };                                  # (optional) - supplied statement handle (good for repeating commands)
    my $datefields       = $args{-datefields};                             # (optional) - supplied date fields to convert to SQL format
    my $preserve         = $args{-preserve};                               ## used to preserve statement handle
    my $no_triggers      = $args{-no_triggers} || $self->{no_triggers};    # (optional) - turns off triggers (for efficiency if necessary)
    my $on_duplicate     = $args{-on_duplicate};                           # (Scalar) flag to ignore duplicate key errors
    my $monitor_progress = $args{-monitor_progress};
    my $debug            = $args{-debug} || $self->config('test_mode');
    my $skip_checks      = $args{-skip_checks};                            # (Scalar) flag to ignore duplicate key errors

    my $new_homepage;                                                      ### flag first record updated as the new homepage..
    ### Error Checking ###
    my %Input;

    if    ( ref($value_ref) =~ /array/i ) { $Input{1} = \@{$value_ref}; }
    elsif ( ref($value_ref) =~ /hash/i )  { %Input    = %{$value_ref}; }
    else                                  { $self->error("simple_append Values in invalid format"); return {}; }

    my %returnval = {};                                                    ## hash of returnval information
    if ($preserve) { %returnval = %{$preserve} }                           ## only if it is already set

    if ( defined $preserve ) {                                             ## even if first pass
        $autoquote = 0;                                                    ## no need for autoquote with predefined sth
        $sth = $returnval{$table}->{sth} || 0;                             ## get statement handle if it already is defined
    }

    foreach my $field (@$field_ref) {
        unless ( $field =~ /(.+)\.(.+)/ ) { $field = "$table.$field" }
    }

    my $ignore_flag = '';
    if ($on_duplicate) {
        $on_duplicate =~ s/^1$/IGNORE/;                                    ## previous default
        $ignore_flag = " $on_duplicate ";
    }

    my $updated = 0;

    # Reset new IDs
    $self->{newids}->{$table} = [];

    # Search for primary value to see if it is specified (i.e. for cases like Library_Name is a primary value but not auto_increment)
    my ($primary_field) = $self->get_field_info( $table, undef, 'Primary' );
    my $primary_value;
    my @primary_values;

    my $records = int( keys %Input );

########################################### DEBUG ##########################

    for ( my $i = 0; $i < @$field_ref; $i++ ) {
        if ( $field_ref->[$i] =~ /^($primary_field|$table\.$primary_field)$/ ) {
            @primary_values = map { $Input{$_}->[$i] } ( 1 .. $records );
            last;
        }
    }
    ### validate entries ###
    ### PERFORM REFERENTIAL INTEGRITY CHECK ###
    my $errors;
    unless ($skip_checks) {
        $errors = $self->_update_errors( -table => $table, -fields => $field_ref, -values => \%Input, -type => 'append' );
    }

    if ($errors) {
        $self->error($errors);

        #        print "Sorry: $errors\n";
        return \%returnval;
    }
    unless ( defined $datefields ) {
        if ( $self->{field_info_tables} ) {
            my @datearray = $self->Table_find( 'DBField,DBTable', 'Field_Name', "where FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table' and Field_Type like 'date%'" ) if $self->{field_info_tables};
            $datefields = \@datearray;
        }
    }

    ### Generate the query based on given table, fields, values ###
    my ( $new_field_ref, $new_value_ref ) = $self->convert_data( -table => $table, -fields => $field_ref, -values => \%Input, -datefields => $datefields, -autoquote => $autoquote );

    my @fields = @$new_field_ref;

    #    my @values = @$new_value_ref;
    my %Values = %{$new_value_ref};

    $self->start_trans( -name => 'simple_append' );

    my @keys = keys %Values;
    unless (@fields) { $self->message( "No fields in $table to update:\n@$new_field_ref", -priority => 2 ) }

    # keep in mind that triggers will not work for multiple values at a time (for efficiency and correctness)

    my $no_primary = 0;
    if ( int(@keys) > 1 ) {
        ### Multiple records at one time...
        my $command = "INSERT $ignore_flag INTO $table (";
        $command .= join ',', @fields;
        $command .= ") values ";
        foreach my $record ( sort { $a <=> $b } keys %Values ) {
            $command .= "(";
            my @values = @{ $Values{$record} };
            $command .= join ',', @values;
            $command .= "),";
        }
        chop $command;

        my $start = timestamp();
        $updated = $self->dbh()->do($command);
        my $end = timestamp();
        $self->_track_if_slow( "INSERT : $command", $end - $start );

        if ( $primary_values[0] ) { $returnval{newids} = \@primary_values }
        elsif ($updated) {
            my $firstid = $self->dbh()->{'mysql_insertid'};

            my $lastid = $firstid + $updated - 1;
            $returnval{newids} = [ $firstid .. $lastid ];
        }

        if ($debug) {
            $self->message( "Command:\n$command\n($updated)\n", -priority => 2 );
        }
    }
    elsif ( int(@keys) < 1 ) {
        Message("Warning: No Values to append into $table(?!)");
    }
    elsif ($sth) {
        ### Insert statement already prepared ... add another record ... ###
        my @values = @{ $Values{1} };
        $updated = $sth->execute(@values);
        $returnval{$table}{sth} = $sth;
        if ( $self->dbh()->{'mysql_insertid'} ) {
            $returnval{newid}  = $self->dbh()->{'mysql_insertid'};
            $returnval{newids} = [ $returnval{newid} ];
        }
        elsif ( $primary_values[0] ) {
            $returnval{newid}  = $primary_values[0];
            $returnval{newids} = [ $primary_values[0] ];
        }
        $self->message( ( "** (quick execute) SEND " . join ',', @fields ), -priority => 2 );
        $self->message( ( join ',', @values ), -priority => 2 );
    }
    elsif ( $table && $new_field_ref ) {
        my @values  = @{ $Values{1} };
        my $command = "INSERT $ignore_flag INTO $table (";
        $command .= join ',', @fields;
        $command .= ") values (";

        if ( defined $sth ) {    ## Prepare and Execute statement first time through
            my @emptylist = map { $_ = '?' } ( 0 .. $#values );
            $command .= join ",", @emptylist;
            $command .= ')';

            $sth = $self->dbh()->prepare($command);
            $self->message( "<BR>** PREPARE:$command.<BR>", -priority => 2 );

            $returnval{$table}{sth} = $sth;
            $self->message( "** (1st time) SEND @fields\n=@values\n", -priority => 2 );
            $updated = $sth->execute(@values);
            ### update object attributes for this method (to allow repeated calls..)
        }
        else {    ## 'Do' statement (faster for single inserts)
            $command .= join ",", @values;
            $command .= ')';
            if ($debug) { $self->message( "** (do) UPDATE $table:\n$command", -priority => 2 ) }
            ($updated) = $self->execute_command( -command => $command, -feedback => $debug );
        }

        ## add to returnvalues
        if ( $self->dbh()->{'mysql_insertid'} ) {    ## only if auto_increment fields...
            $returnval{newid} = $self->dbh()->{'mysql_insertid'};
            $new_homepage = "$returnval{newid}" unless ( $new_homepage || $returnval{newid} == 1 );
            $returnval{newids} = [ $returnval{newid} ];
            $self->{transaction}->newids( -table => $table, -newid => $returnval{newid} ) if ( $self->{transaction} );
        }
        elsif ( $primary_values[0] ) {
            $returnval{newid}  = $primary_values[0];
            $returnval{newids} = [ $primary_values[0] ];
            $self->{transaction}->newids( -table => $table, -newid => $primary_values[0] ) if ( $self->{transaction} );
        }
        else {
            if ( !$ignore_flag ) { print "no primary value.." }
            $no_primary++;
        }

    }
    else {
        $self->error("Append requires statement handle or Table, Fields, Values");
    }
    
    if ( $no_primary && $ignore_flag ) { $self->warning("Duplicate record(s) ignored") }

    # activate triggers on new ids

    $self->execute_preliminary_actions( -table => $table, -action => 'insert', -ids => $returnval{newids} );

    my $trigger_success = $no_triggers ? 1 : $self->execute_Trigger( -table => $table, -action => 'insert', -ids => $returnval{newids}, -monitor_progress => $monitor_progress );

    $returnval{updated} = $updated;

    ### Clean up of the transaction we started
    if ( !$trigger_success ) {
        $self->rollback_trans( 'simple_append', -error => "$table trigger_failure" );
        return {};
    }
    else {
        $self->finish_trans('simple_append');
        $self->reset_homepage( { $table => $new_homepage } );
        return \%returnval;
    }
}

#######################################
# Append table(s) with supplied values
#
# May supply multiple values in form:
#     $values{1} = ('1','b','George'); $values{2} = ('2','d','Julie');   (send -values=>\%values)
#   .. or single value in form:
#     @values = ('1','b','George');     ... and send -values=>\@values
#
# Table specification is optional, but is necessary to auto-update foreign keys or if multiple tables share field names.
#
# RETURN : %returnval.
#       $returnval{$table}->{newids} = list of newids (primary values)
#       $returnval{table_list}       = list of tables appended
#
###################
sub smart_append {
###################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    $dbh ||= $args{-dbh} || $self->{dbh};    # database handle
    my $table     = $args{-table}  || $self->{update_table};     # table to update (optional, but autosets fks only if in correct order)
    my $field_ref = $args{-fields} || $self->{update_fields};    # fields to insert into
    my $value_ref        = $args{ -values };                               # values to insert
    my $autoquote        = $args{-autoquote};                              # (optional) - autoquotes text (standard)
    my $tables           = $args{-tables} || $table;
    my $datefields       = $args{-datefields};                             # (optional) - supplied date fields to convert to SQL format
    my $preserve         = $args{-preserve};
    my $auto_commit      = $args{-auto_commit} || 0;                       # do NOT use transaction for this process ---> NOT IMPLEMENTED.
    my $on_duplicate     = $args{-on_duplicate};                           # (Scalar) flag to ignore duplicate key errors
    my $no_triggers      = $args{-no_triggers} || $self->{no_triggers};    # do NOT run triggers on this append
    my $monitor_progress = $args{-monitor_progress};
    my $ort   = $args{-ort};     # unnecessary - but leave in for debugging to ensure absolutely that legacy code is not affected if this parameter is not set..specify object referencing table eg -ort => {'Shipped_Object' => 'Source'}
    my $debug = $args{-debug};

    #print Dumper \%args;
    ### Error Checking ###
    my %Input;
    if    ( ref($value_ref) =~ /array/i ) { $Input{1} = $value_ref; }
    elsif ( ref($value_ref) =~ /hash/i )  { %Input    = %{$value_ref} }
    else                                  { $self->error("smart_append Values in invalid format"); return; }

    my %returnval;
    if ($preserve) {
        %returnval = %{$preserve};
        $tables ||= $returnval{table_list};
    }

    my @table_list;
    if ($tables) {
        @table_list = split ',', $tables;
        $returnval{table_list} = $tables;
    }
    else {
        @table_list = split ',', $self->get_tables($field_ref);
        $returnval{table_list} = $self->get_tables($field_ref);
    }

    unless (@table_list) { print "NO TABLE DEFINED ! \n"; }
    my %added;

    my %preserved = {};

    # Reset new IDs
    #    $self->{newids} = {};  ## why does this need to be cleared ?

    # organize the tables
    @table_list = $self->order_tables( \@table_list );

    # Starts transaction
    $self->start_trans( -name => 'smart_append' );

    my $start = timestamp();

    my %Field_index;

    my $OR = $self->_check_for_ORT( \@table_list, $field_ref, \%Input );

    foreach my $table (@table_list) {
        my @localfields = map {"$table.$_"} $self->Table_find( 'DBField,DBTable', 'Field_Name', "where FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table'" );
        my @fields;
        my %values;

        my $number_of_fields = int( @{$field_ref} );
        my $records          = int( keys %Input );

        my $localfields = 0;
        foreach my $index ( 1 .. $number_of_fields ) {

            my $field = $$field_ref[ $index - 1 ];
            if ( grep /^($field|$table\.$field)$/, @localfields ) {
                ## continue
            }
            elsif ( $self->alias($field) ) {
                my $alias = $self->alias($field);
                $field = $alias;
            }
            else {
                next;
            }
            unless ( grep /^($field|$table\.$field)$/, @fields ) {
                if ( $OR && ( grep /^$table/, keys %{ $OR->{References} } ) ) {
                    ### Block added to account for Object Referencing Table ###
                    if   ( $field =~ /(.+)\.(.+)/ ) { push( @{ $OR->{fields}{$table} }, $field ) }
                    else                            { push( @{ $OR->{fields}{$table} }, "$table.$field" ) }
                    map { $OR->{values}{$table}{$_}[$localfields] = $Input{$_}->[ $index - 1 ] } ( 1 .. $records );
                    $localfields++;
                    next;
                }

                if   ( $field =~ /(.+)\.(.+)/ ) { push( @fields, $field ) }
                else                            { push( @fields, "$table.$field" ) }
                map { $values{$_}[$localfields] = $Input{$_}->[ $index - 1 ] } ( 1 .. $records );
                $localfields++;

                @{ $added{"$table.$field"} } = map { $Input{$_}->[ $index - 1 ] } ( 1 .. $records );
            }
            $Field_index{ $fields[-1] } = $index - 1;
        }

        if ( $OR && ( grep /^$table/, keys %{ $OR->{References} } ) ) { next; }    ## if there exist Objects, and current table links to Object skip below

        my @references = $self->Table_find( 'DBField,DBTable', 'Field_Name,Foreign_Key', "where FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table' AND Foreign_Key IS NOT NULL AND Foreign_Key NOT LIKE '$table.%'" );
        foreach my $reference (@references) {
            my ( $field, $tbl, $fld );
            if ( $reference =~ /(.*)\,(.*)\.(.*)/ ) {
                $field = $1;
                $tbl   = $2;
                $fld   = $3;
            }

            #           my ($field,$Tref) = split ',', $reference;
            #           my ($tbl,$fld) = split '\.', $Tref;
            if ( $tbl && $added{"$tbl.$fld"} && !( grep /^($field|$table\.$field)$/, @fields ) ) {
                push( @fields, "$table.$field" );
                map {
                    if ( exists $Field_index{"$table.$field"} )
                    {
                        $values{$_}[$localfields] = $Input{$_}->[ $Field_index{"$table.$field"} ];
                    }
                    else {    # Grab new ids just inserted
                        $values{$_}[$localfields] = $self->{newids}->{$tbl}->[ $_ - 1 ];
                    }
                } ( 1 .. $records );

                $localfields++;
            }
        }

        my $before_error = $self->error();

        if ($preserve) {      ## only define preserve if used ##
            %preserved = %{ $self->simple_append( -table => $table, -fields => \@fields, -values => \%values, -autoquote => $autoquote, -on_duplicate => $on_duplicate, -debug => $debug, -no_triggers => $no_triggers, -preserve => \%preserved ) };
        }
        else {
            %preserved
                = %{ $self->simple_append( -table => $table, -fields => \@fields, -values => \%values, -autoquote => $autoquote, -on_duplicate => $on_duplicate, -debug => $debug, -no_triggers => $no_triggers, -monitor_progress => $monitor_progress ) };
        }

        my $after_error = $self->error();
        if ( $after_error && ( $after_error ne $before_error ) ) {    ## escape if error appending...

            my $details = HTML_Dump( "Fields", \@fields, $values{1} );
            $self->debug_message($details);

            $self->finish_trans( 'smart_append', -error => $after_error );
            return \%returnval;
        }

        my @newids = @{ $preserved{newids} } if defined $preserved{newids};
        if (@newids) {
            foreach my $newid (@newids) {
                push( @{ $self->{newids}->{$table} }, $newid );
                push( @{ $returnval{$table}->{newids} }, $newid );
            }
            my $primary_field = join ',', $self->get_field_info( $table, undef, 'Primary' );
            @{ $added{"$table.$primary_field"} } = @newids;
        }

        elsif ($DBI::errstr) { print "3\n"; print "Problems adding to $table ?? ($DBI::errstr) \n" }    ## check for autoincrement to be safe...
    }
    if ($OR) {
        foreach my $ORT ( keys %{ $OR->{References} } ) {
            ## add Object Reference Table Records After original records ##
            my $records = int( keys %Input );
            my $ORF     = 'Object_ID';                                                                  ## Default Object Reference Field unless explicitly indicated (below);
            if ( $ORT =~ /(\w+)\.(\w+)/ ) { $ORT = $1; $ORF = $2 }                                      ## allow for Object reference fields aside from Object_ID (eg 'Change_History.Record_ID' => 'Plate')

            my $new_ids = $self->{newids}{ $OR->{References}{$ORT} };                                   ## get reference Object_ID values
            push @{ $OR->{fields}{$ORT} }, "$ORT.$ORF";                                                 ## add Object_ID referencing field

            foreach my $record ( 1 .. $records ) {
                my $ref = $new_ids->[ $record - 1 ];
                push @{ $OR->{values}{$ORT}{$record} }, $ref;                                           ## add Object_ID referencing values
            }
            my ( $f, $v ) = ( $OR->{fields}{$ORT}, $OR->{values}{$ORT} );
            my %OR = %{ $self->simple_append( -table => $ORT, -fields => $f, -values => $v, -autoquote => $autoquote, -on_duplicate => $on_duplicate, -debug => $debug, -no_triggers => $no_triggers ) };

            if ( defined $OR{newids} && @{ $OR{newids} } ) {
                ## add to new id / returnval hashes if new records are added ##
                foreach my $newid ( @{ $OR{newids} } ) {
                    push( @{ $self->{newids}->{$ORT} }, $newid );
                    push( @{ $returnval{$ORT}->{newids} }, $newid );
                }
                my $primary_field = join ',', $self->get_field_info( $ORT, undef, 'Primary' );
                @{ $added{"$ORT.$primary_field"} } = @{ $OR{newids} };
            }
            elsif ($DBI::errstr) { print "Problems adding to $ORT ?? ($DBI::errstr) \n" }    ## check for autoincrement to be safe...
        }
    }
    $self->finish_trans('smart_append');
    my $end = timestamp();

    return \%returnval;
}

# Wrapper to control logic for what exactly is considered an object reference table.
#
# (table which doesn't explicitly include a standard FK field, but has a class field (eg FK_Object_Class__ID) and a record_id field (eg Object_ID) )
#
# may also include requirements regarding whether the input does not include the Object_ID itself.
#
#
# Return: true if object reference table found
#####################
sub _check_for_ORT {
#####################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'tables,fields,input' );
    my $tables = $args{-tables};
    my $fields = $args{-fields};
    my $input  = $args{-input};
    my $good   = 0;
    my $id;
    my ( $OR, $index );

    my @table_arr = Cast_List( -list => $tables, -to => 'array', -autoquote => 0 );

    foreach my $field (@$fields) {
        if ( $field =~ /(.*?)\.?FK_Object_Class__ID/ ) {

            # (\w*?)\.?
            my $rtable = $1;

            my $num_records = int( keys %{$input} );
            my @temp;
            @temp = map { $input->{$_}[$index] } ( 1 .. $num_records );

            if ( int keys %{ { map { $_, 1 } @temp } } == 1 ) {

                # all equal
                $good = 1;
            }
            else {
                $self->error("Error in _check_for_ORT::Not all records of field FK_Object_Class__ID are equal");
                return;
            }

            if ($good) { $id = $input->{1}[$index]; }
            else       { }
            if ( !$rtable ) {
                my $table_list = Cast_List( -list => $tables, -to => 'string', -autoquote => 1 );
                my @rtables = $self->Table_find( 'DBField', 'Field_Table', "WHERE Field_Table IN ($table_list) AND Field_Name = 'FK_Object_Class__ID'" );
                if ( int @rtables == 1 ) { $rtable = @rtables[0]; }
                else {
                    $self->error("Error in _check_for_ORT::Multiple or 0 instances of FK_Object_Class__ID in Tables");
                    return;
                }

            }
            my ($otable) = $self->Table_find( 'Object_Class', 'Object_Class', "WHERE Object_Class_ID = '$id'" );
            if ( grep /^$otable$/, @table_arr ) {
                $OR->{References}{$rtable} = $otable;
            }

        }
        $index++;
    }
    return $OR;
}

################################################
# Return new ids added to given table.
#  (optionally may specify the index if more than one updated.
#
# RETURN array_reference (unless index given in which case the scalar is returned)
##########
sub newids {
##########

    my %args = &filter_input( \@_, -args => 'dbc,table,index', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table = $args{-table};
    my $index = $args{ -index };

    my @newids;
    if ( $self->{newids}->{$table} ) {
        @newids = @{ $self->{newids}->{$table} };
    }

    if ( defined $index && $index ne '' ) {
        return $newids[$index];
    }
    else {
        return \@newids;
    }
}

################
#
# Append multiple records to database
# (set up for appending from multi-table forms)
# This adds one record at a time, each of which may span multiple tables.
# It is useful if different records may update a different set of fields
#
# Faster updates of multiple records of the same structure may be accomplished using
# 'smart_append' (for records spanning multiple tables) or...
# 'simple_append' (for single table updates)
#
# (may supply -values=>\@values,-format=>'array' (single record append)
#    ... or -values=>\%values,-format=>'hash' (multi-record append)
#
# (for hashes, format should be:  $values{1}=\@values, $values{2}=\@values ... etc.)
#
# RETURN: new id (or number of updates if not auto_increment primary key)
##############
sub DB_append {
##############
## <CONSTRUCTION> IS THIS OLD and to be replaced by simple_append or is there something different about it ??

    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table     = $args{-table}  || $self->{update_table};     # table to update
    my $field_ref = $args{-fields} || $self->{update_fields};    # fields to insert into
    my $value_ref = $args{ -values };                            # values to insert
    my $format    = $args{'-format'} || 'array';
    my $autoquote = $args{-autoquote};                           # (optional) - autoquotes text (standard)
    my $sth       = $args{ -sth };                               # (optional) - supplied statement handle (good for mulitple inserts)
    my $tables    = $args{-tables};

    $self->{sth} = $sth || 0;                                    ### reset it in case it has carried over from another process

    unless ($self)      { $self->error("Append requires Database handle"); return; }
    unless ($value_ref) { $self->error("Append requires Values");          return; }

    my $records = 1;
    my %values_hash;
    if ( $format =~ /hash/ ) {                                   ### append records from a list of values
        %values_hash = %{$value_ref};
        my $first_field = $$field_ref[0];
        $records = int( keys %values_hash );                     ## number of records given
    }

    ## get list of date field in this table (to convert if necessary)
    $tables ||= $self->get_tables($field_ref);
    unless ($tables) { $self->error("No Table found with given fields"); return; }

    my %preserve;
    if ( $records > 1 ) { %preserve = {}; }                      ## define it to use prepared statement handle
    $self->message( "Append $records Records\n", -priority => 2 );

    my %returnval;
    $returnval{records} = $records;
    $returnval{tables}  = $tables;
    foreach my $record ( 1 .. $records ) {                       ## loop only if more than one record (hash)
        my $vref;
        my @keys1 = keys %{%values_hash};

        #	my @keys = keys %{$values_hash{$record}};
        if   ( $format =~ /hash/ ) { $vref = $values_hash{$record} }    ## get next set of values if hash provided
        else                       { $vref = $value_ref }

        unless ($value_ref) { next; }
        my $returnhash = $self->smart_append( -tables => $tables, -fields => $field_ref, -values => $vref, -autoquote => $autoquote, -preserve => \%preserve );
        %preserve = %{$returnhash};

        foreach my $table ( split ',', $tables ) {
            my @newids = @{ $preserve{$table}->{newids} } if $preserve{$table}->{newids};
            $returnval{$table}->{newids} ||= [];
            push( @{ $returnval{$table}->{newids} }, @newids );
            $self->message( "$record : Added to $table: @newids.\n", -priority => 2 );
        }
    }
    return \%returnval;
}

#######################################################################################
# This routine appends records into a file/database given column names, and values in
# two comma separated fields.
#
# <snip>
# Example:
#     my $ok = $dbc->Table_append("Library_Source",'FK_Source__ID,FK_Library__Name',"$FK_src_id,$FK_lib_name",-autoquote=>1);
# </snip>
# Return: the number of records affected.
#########################
sub Table_append {
#########################
    my %args = &filter_input(
         \@_,
        -args      => 'dbc,table,fields,values,on_duplicate',
        -mandatory => 'dbc|self',
        -self      => 'SDB::DBIO'
    );
    my $self = $args{-self} || $args{-dbc};

    $args{-fields} = [ split( ',', $args{-fields} ) ];
    $args{ -values } = [ split( ',', $args{ -values } ) ];

    return $self->Table_append_array(%args);
}

# This routine appends records into a file/database given column names, and values in
# two comma separated fields.
#
# <snip>
# Example:
#     my $ok = $dbc->Table_append_array($dbc,"Lab_Request",['FK_Employee__ID','Request_Date'],[$emp_id,&date_time()],-autoquote=>1);
# </snip>
# Returns: the auto_increment id if applicable, or else the number of records affected.
#############################
sub Table_append_array {
#############################
    my %args = &filter_input(
         \@_,
        -args      => 'dbc,table,fields,values,on_duplicate',
        -mandatory => 'dbc|self',
        -self      => 'SDB::DBIO'
    );
    my $self = $args{-self} || $args{-dbc};

    if ( $args{ERRORS} ) { Message("Input Error Found: $args{ERRORS}"); return; }

    my $TableName       = $args{-table};                                  # table to update
    my $newfields       = $args{-fields};                                 # fields to change
    my $newentries      = $args{ -values };                               # new values
    my $condition       = $args{-condition};                              # condition determining which records to change
    my $no_triggers     = $args{-no_triggers} || $self->{no_triggers};    # suppress triggers
    my $test            = $args{-test};                                   # flag to return only the command to be used
    my $auto_quote      = $args{-autoquote};
    my $quiet           = $args{-quiet};
    my $skipcheck       = $args{-skipcheck};
    my $on_duplicate    = $args{-on_duplicate};                           # Ignore insert if there are duplicate keys
    my $skip_validation = $args{-skip_validation};                        # improves performance, but is vulnerable to input errors
    my $debug           = $args{-debug} || $self->config('test_mode');

    ## Truncate leading and trailing spaces etc
    $newentries = RGTools::RGIO::standardize_text_value($newentries);

    if ( $self->{skip_validation} ) { $skip_validation = 1 }

    my $ignore = '';
    if ($on_duplicate) {
        $on_duplicate =~ s/^1$/IGNORE/;
        $ignore = " $on_duplicate ";
    }

    my @added_fields = @$newfields;
    my @newentries   = @$newentries;

    my @added_entries = @newentries;
    $self->Benchmark( $TableName . '_validate' );

    if ( !$skip_validation ) {
        if ( my @new_added_entries = $self->Table_update_array_check( $TableName, \@added_fields, \@added_entries, 'append', -debug => $debug, -quiet => $quiet ) ) {
            @added_entries = @new_added_entries;
        }
        else {
            $self->message("(Nothing Appended to $TableName Table)");
            $debug = 1;
            $self->Table_update_array_check( $TableName, \@added_fields, \@added_entries, 'append', -debug => 1 );
            Message("Tried to record change:<BR>@added_fields<BR>to:<BR>@added_entries");
            Call_Stack() if ($debug);
            return 0;
        }
    }
    $self->Benchmark( $TableName . '_Validated' );

    ############# if auto_quote selected ################
    if ($auto_quote) {
        @added_entries = map { $self->dbh()->quote($_) } @$newentries;
    }
    else { @added_entries = @newentries; }

    @added_entries = $self->_convert_date_fields( $TableName, \@added_fields, \@added_entries );

    my $newentry = "INSERT $ignore into $TableName (" . join ',', @added_fields;
    $newentry .= ") VALUES (";
    $newentry .= join ',', @added_entries;
    $newentry .= ")";

    Message("Appending: $newentry") if ( $debug || $self->config('test_mode') );

    my $update;
    my $start = time();

    # start trans
    $self->start_trans( -name => 'append' );

    eval { $update = $self->dbh()->do($newentry); };

    $self->Benchmark( $TableName . '_Added' );

    if ($@) {
        print "ERROR $@";
        $self->finish_trans( 'append', -error => $@ );
        return 0;
    }

    my $end = time();
    $self->_track_if_slow( "append: $newentry", -time => $end - $start );

    my $return;
    my $trigger_success;
    if ( !defined $update ) {
        unless ($quiet) {
            $self->message("Tried: $newentry");
            Call_Stack();
        }
        $self->message( "Append Error: " . $! );
        $return = 0;
    }
    else {
        $update += 0;

        #	my $insert_id = $self->dbh()->{'mysql_insertid'};
        #	my $insert_id = &get_last_insert_id();
        my $insert_id = &get_last_insert_id( -dbc => $self, -table => $TableName, -fields => \@added_fields, -values => \@newentries );
        RGTools::RGIO::Test_Message( "Added $TableName ($update): " . $insert_id, $debug );

        if ( ( $update > 0 ) && $insert_id ) {
            $self->{transaction}->newids( -table => $TableName, -newid => $insert_id ) if ( $self->{transaction} );

            # trigger triggers
            $self->execute_preliminary_actions( -table => $TableName, -action => 'insert', -ids => [$insert_id] );
            $self->Benchmark( $TableName . '_Triggers' );

            $trigger_success = $no_triggers ? 1 : $self->execute_Trigger( -table => $TableName, -action => 'insert', -ids => [$insert_id] );
            $return = $insert_id;
        }
        ### only if auto_increment fields...
        else {
            $self->reset_homepage( { $TableName => $insert_id } );
            $return = $update;
            print $self->dbh()->{'mysql_insertid'};
        }
    }

    $self->Benchmark( $TableName . '_Completed' );

    ### Clean up of the transaction we started
    if ( !$no_triggers && !$trigger_success ) {
        $self->finish_trans( 'append', -error => 'trigger failure (ensure auto_increment field exists)' );
        return 0;
    }
    else {
        $self->finish_trans('append');
        return $return;
    }
}

######################
sub Batch_Append {
######################
    my %args = &filter_input(
         \@_,
        -args      => 'dbc,data,transaction,on_duplicate',
        -mandatory => 'dbc|self',
        -self      => 'SDB::DBIO'
    );
    my $self = $args{-self} || $args{-dbc};

    my $debug = $args{-debug};
    my $quiet = $args{-quiet};

    my $data_ref     = $args{-data};           # Receives hash in the format of $data{tables}->{TABLE}->{INDEX}->{FIELD}
    my $on_duplicate = $args{-on_duplicate};

    my $new_homepage;
    unless ($data_ref) { return 0 }

    my %data = %{$data_ref};
        
    my %new_ids;                               # Hash to keep track of the new ids
    my %mapped_data;                           # Hash to keep track of all other data to fill in

    my @added_fields = ();
    my @added_values = ();
    my $record_table;
    
    my @table_list = ();
    foreach my $TableName_index ( sort { $a <=> $b } keys %{ $data{index} } ) {
        my $TableName = $data{index}->{$TableName_index};
        push( @table_list, $TableName );
    }

    my %table_list_hash = map { $_ => 1 } @table_list;
    my %data1 = %data;

    # get join table info
    my $join_table = $self->get_join_table( -tables => \@table_list );

    if ($join_table) {
        foreach my $jt ( keys %$join_table ) {
            my $jfs = $join_table->{$jt};
            foreach my $jf ( keys %$jfs ) {
                my $table_field = $jfs->{$jf};
                if ( $table_field =~ /(.+)\.(.+)/ ) {
                    my $pri_table = $1;
                    my $pri_key   = $2;
                    if ( $data1{tables}{$pri_table} ) {    # if the table being joined is in the object and the join table is not
                        foreach my $i ( keys %{ $data{tables}{$pri_table} } ) {
                            if ( !$data1{tables}{$jt}{$i}{$jf} ) {

                                # add this table to table_list, add the table to $data{tables}
                                $table_list_hash{$jt} = 1;
                                $data{tables}{$jt}{$i}{$jf} = "<" . $table_field . ">";
                            }
                        }
                    }
                }
            }
        }
    }
    @table_list = keys %table_list_hash;

    # organize the tables
    @table_list = order_tables( $self, \@table_list );

    $self->start_trans('batch_append');

    my $class_key;
    foreach my $TableName (@table_list) {
        $record_table = $TableName;
        foreach my $index ( keys %{ $data{tables}->{$TableName} } ) {

            #Clear the arrays. `
            @added_fields = ();
            @added_values = ();
            foreach my $field ( keys %{ $data{tables}->{$TableName}->{$index} } ) {
                my $value = $data{tables}->{$TableName}->{$index}->{$field};
                if ( $value =~ /<(\w+)\.(\w+)>/ ) {
                    if ( exists $new_ids{"$1.$2"} ) {
                        $value = $new_ids{"$1.$2"};
                    }
                    elsif ( $self->{newids}{$1} && $self->{newids}{$1}[0] ) {
                        $value = $self->{newids}{$1}[0];
                    }
                    else {
                        $value = $mapped_data{"$1.$2"};
                    }
                }

                # convert all spaces in attribute name to underscores (requirement of prep/plate attributes)
                if ( $field =~ /Attribute_Name/ ) {
                    $value =~ s/\s/_/g;
                }

                # fill into mapped data
                $mapped_data{"$TableName.$field"} = $value;

                # if the field is numeric type, DO NOT add this field-value pair if the value is empty
                my $numeric_field = 0;
                my @field_type = $self->get_field_types( -table => $TableName, -field => $field );
                if ( int(@field_type) > 0 ) {
                    my ( $field_name, $field_type ) = split /\t/, $field_type[0];
                    if ( $field_type =~ /^int|^tinyint|^smallint|^mediumint|^bigint|^decimal|^numeric|^float|^double/i ) {
                        $numeric_field = 1;
                    }
                }
                if ( !$numeric_field || length($value) ) {
                    push( @added_fields, $field );
                    push( @added_values, $value );
                }
                if ( $field =~ /Object_Class__ID/ ) { $class_key = $value }    ## track dynamic FK
            }

            # check if the entry already exists
            if ( $on_duplicate =~ /1|IGNORE/ ) {
                my ( $primary_field, $existing_id ) = Insertion_Check( $self, $TableName, \@added_fields, \@added_values );
                if ($existing_id) {
                    my $LOG;
                    my $public_log_dir = $self->config('public_log_dir');
                    open( $LOG, ">>${public_log_dir}/batch_append_skipped_list.log" );
                    print $LOG "Duplicate key $TableName:$existing_id, skipping $TableName (Record $index)\n";
                    Message("Warning: Duplicate key, skipping $TableName (Record $index.) Entry duplicates $TableName $existing_id");
                    close($LOG);
                    next;
                }
            }
            #### continue if NOT xml format (appending database) ... ####
            my $ok = $self->Table_append_array( $TableName, \@added_fields, \@added_values, -autoquote => 1, -debug => $debug );
            if ($ok) {

                #	    my $home_page_id = $self->get_FK_info(foreign_key($TableName),$ok);
                my $home_page = &Link_To( $self->homelink(), "Home Page: $ok", "&HomePage=$TableName&ID=$ok" );
                $self->message("New $TableName record added ($home_page)") unless ($quiet);

                my ($primary) = $self->get_field_info( $TableName, undef, 'Primary' );
                my $primary_value;

                my $newid;
                if ( $primary eq $TableName . "_ID" ) { $newid = $ok; }
                else {
                    my $Pindex = -1;
                    my $index  = 0;
                    map {
                        my $field = $_;
                        if ( $field eq $primary ) { $Pindex = $index }
                        $index++;
                    } @added_fields;
                    if ( $Pindex >= 0 ) { $newid = $added_values[$Pindex] }
                }
                if ($newid) {
                    $new_ids{"$TableName.$primary"} = $newid;   
                }
                
                ## <CONSTRUCTION> ## remove customization ##
                ############### Custom Insertion (also append daughter tables if appropriate) ############
                my $num = CGI::param('Stock_Number_in_Batch') || $Input{'Stock_Number_in_Batch'} || 0;
                if ( $num && ( $TableName eq 'Stock' ) ) {
                    my $id = $ok;    ## id returned from append_array..
                                     #&Table_find($dbc,'Stock','Stock_ID',"order by Stock_ID desc limit 1");       ####### get last added entry...
                    my $updated;
                    my $type = CGI::param('Stock_Type') || $Input{'Stock_Type'} || '';
                    if    ( $type =~ /reagent/i ) { $type = 'Solution' }
                    elsif ( $type =~ /kit/i )     { $type = 'Box' }
                    foreach my $thisnum ( 1 .. $num ) {
                        my $new_id = $self->Table_append_array( $type, [ $type . "_Number", $type . "_Number_in_Batch", 'FK_Stock__ID' ], [ $thisnum, $num, $id ], -debug => $debug );
                        unless ($new_id) {
                            my $error = Get_DBI_Error();
                            $self->message("Error: Database not updated ($error)");
                            $self->finish_trans( 'batch_append', -error => "No new_id generated for $type ($error)" );
                            return 0;
                        }

                        $self->{transaction}->newids( -table => $type, -newid => $new_id ) if ( $self->{transaction} );

                        if ( ( $type =~ /Solution/ ) && $new_id ) {
                            $updated++;
                            &alDente::Barcoding::PrintBarcode( $self, 'Solution', $new_id );
                        }
                    }
                    if ($updated) { $self->message("Added $updated new $type records") unless ($quiet); }
                    else          { print "Type: $type."; }
                }
                ############### End Custom Insertion (also append daughter tables if appropriate) ########
            }
            else {
                my $error = Get_DBI_Error();
                $self->message("Error: Database not updated ($error)");
                $self->finish_trans( 'batch_append', -error => "Not updated ($error)" );
                return 0;
            }
        }
        $self->reset_homepage( \%new_ids ) if ( !$self->homepage() );
    }

    $self->finish_trans('batch_append');
   
    return \%new_ids;
}

#################################
sub Table_binary_append {
#################################
    # UNDER CONSTRUCTION
    #
    # This routine appends records into a file given column names, and values in
    # two comma separated fields.
    #
    #  It returns the number of records affected.
    #
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table      = $args{-table};                                             # table to append
    my $newfields  = Cast_List( -list => $args{-fields}, -to => 'string' );     # fields to include
    my @newentries = Cast_List( -list => $args{ -values }, -to => 'array' );    # values of fields included

    my $newentry = "INSERT into $table ($newfields) VALUES (";

    foreach my $new (@newentries) {
        $newentry .= "?,";
    }
    chop $newentry;
    $newentry .= ")";

    # Check mandatory, foreign, and Unique fields...
    $self->message("<BR>Updating database with command:<BR>$newentry<BR>");
    my $sth = $self->dbh()->prepare($newentry);

    if ( !defined $sth ) {
        $self->message( "Append Error(2) " . Get_DBI_Error() );
        Call_Stack();
        return -1;
    }
    else {
        $sth += 0;
        return $sth;
    }

    my $ok = $sth->execute(@newentries);
    if ( defined $sth->err() ) {
        $self->message( "Table_binary_append Error: " . Get_DBI_Error() );
        $self->message("MySQL statement = $newentry");
    }

    $sth->finish;
    return $ok;
}
#####################################
# UPDATE: Database records          #
#####################################

######################################
# Update multiple records in multiple tables
# Returns the number of rows affected
######################################
sub DB_update {
############## THIS FUNCTION IS NOT TESTED YET #######################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    if ( $self->{table} ) { return $self->_update_OLD(%args) }

    my $tables    = $args{-tables};       ### Tables to be updated
    my $fields    = $args{-fields};       ### Fields to be updated
    my $values    = $args{ -values };     ### Values to be updated
    my $records   = $args{-records};      ### The records to be updated (e.g. $records->{Library.Library_Name} = ['CG001','CG002'])
    my $autoquote = $args{-autoquote};    # Autoquote or not

    $tables = Cast_List( -list => $tables, -to => 'arrayref' );
    $fields = Cast_List( -list => $fields, -to => 'arrayref' );
    $values = Cast_List( -list => $values, -to => 'arrayref' );

    $records = $self->_convert_records( -records => $records );

    my %updated;
    foreach my $table (@$tables) {
        my @update_fields;
        my @update_values;
        my $i = 0;
        foreach my $field (@$fields) {
            my ( $rtable, $rfield ) = simple_resolve_field( $field, -dbc => $self );
            if ( $rtable eq $table ) {
                push( @update_fields, $rfield );
                push( @update_values, $values->[$i] );
            }
            $i++;
        }
        if ( @update_fields && @update_values ) {
            my $condition = "where 1";
            foreach my $field ( keys %{ $records->{$table} } ) {
                my $values = join "','", @{ $records->{$table}->{$field} };
                $condition .= " and $table.$field in ('$values')";
            }
            if ($autoquote) {
                $updated{$table} = $self->Table_update_array( $table, \@update_fields, \@update_values, $condition, -autoquote => 1 );
            }
            else {
                $updated{$table} = $self->Table_update_array( $table, \@update_fields, \@update_values, $condition );
            }
        }
    }

    return \%updated;
}

#
# This routine updates records into a file given column names, and values in
# two comma separated fields, along with a condition string.
#
# This version does not requires quotes around appropriate fields,
#  but will fail on SQL commands
#  such as Left, Concat (must use Table_update_array instead)
#
# (It first validates data using 'update_array_check')
# <snip>
# Example:
#
# my $num_records = $self->Table_update(-table=>'Plate', -fields=>$fields, -values=>$values, -condition=>"WHERE Plate_ID = 5000");
#
# </snip>
# Return:  the number of records affected.
#
#############################
sub Table_update {
#############################

    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values,condition', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    if ( $args{ERRORS} ) { Message("Input Error Found: $args{ERRORS}"); return; }
    my $TableName = $args{-table};        # table to update
    my $newfields = $args{-fields};       # fields to change
    my $newvalues = $args{ -values };     # new values
    my $condition = $args{-condition};    # condition determining which records to change

## convert comma-delimited list into array of fields / values
    my @Farray = split ',', $newfields;
    my @Varray = split ',', $newvalues;
    $args{-fields} = \@Farray;
    $args{ -values } = \@Varray;
    return $self->Table_update_array(%args);
}

# This routine updates records into a file given column names, and values in
# two comma separated fields, along with a condition string.
#
# (It first validates data using 'update_array_check')
#
#  It returns the number of records affected.
#
# This is IDENTICAL to Table_update except it uses the input fields as arrays...
#
# <snip>
# Example:
#
# my $num_records = $dbc->Table_update_array(-table=>'Plate', -fields=>\@fields, -values=>\@values, -condition=>"WHERE Plate_ID = 5000");
#
# </snip>
# Return:  the number of records affected.
#############################
sub Table_update_array {
#############################

    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values,condition', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    if ( $args{ERRORS} ) { Message("Input Error Found: $args{ERRORS}"); return; }

    my $TableName          = $args{-table};                                  # table to update
    my $newfields          = $args{-fields};                                 # fields to change
    my $newentries         = $args{ -values };                               # new values
    my $condition          = $args{-condition};                              # condition determining which records to change
    my $test               = $args{-test};                                   # flag to return only the command to be used
    my $auto_quote         = $args{-autoquote};
    my $quiet              = $args{-quiet};
    my $force              = $args{-force};
    my $suppress_log       = $args{-suppress_log};                           # allow suppression of update logging (eg when updating via trigger)
    my $comment            = $args{-comment};                                # comment passed to change_history if applicable
    my $confirm            = $args{-confirm};
    my $ignore             = $args{-ignore};                                 # ignore duplicate records created with update ..
    my $no_triggers        = $args{-no_triggers} || $self->{no_triggers};    # suppress triggers
    my $skip_validation    = $args{-skip_validation};                        # improves performance, but is vulnerable to input errors
    my $explicit           = $args{-explicit};
    my $debug              = $args{-debug} || $self->config('test_mode');
    my $append_only_fields = $args{-append_only_fields};                     # fields that should be append only eg. comments, currently does not perform any type of checking use with caution
                                                                             #in the exceptional append cases use SQL case to set the not-to-be-updated field to be NULL or blank  eg. see Run.pm set_billable_status
    my $append_separator   = $args{-append_separator};                       #separator used to separate each append

    ## Truncate leading and trailing spaces etc
    $newentries = RGTools::RGIO::standardize_text_value($newentries);

    if ( $self->{skip_validation} ) { $skip_validation = 1 }
    if ($ignore)                    { $ignore          = 'IGNORE' }          # IGNORE flag set

    my @update_fields = @$newfields;
    my @new_entries   = @$newentries;

    ############## allow automatic quoting if specified... ###########

    my @entries;
    if ($auto_quote) {
        @entries = map { $self->dbh()->quote($_) } @new_entries;
    }
    else { @entries = @new_entries; }

    @entries = $self->_convert_date_fields( $TableName, \@update_fields, \@entries );

    my $index = 0;
    my $set   = "";

    ### check valid entries (replacing if necessary)

    $self->start_trans( 'update_records', -debug => $debug );

    if ( !$skip_validation ) {
        unless ( @entries = $self->Table_update_array_check( $TableName, \@update_fields, \@entries, 'update', $condition, $force, -comment => $comment, -quiet => $quiet, -no_triggers => $no_triggers, -explicit => $explicit, -debug => $debug ) ) {
            if ($debug) {
                print Get_DBI_Error();
                print "fields: @update_fields\n<BR>";
                print "entries: @entries\n<BR>";
                print "condition: $condition\n<BR>";
                $self->message("Error in update_array_check ($condition)");
            }
            $self->finish_trans( 'update_records', 'Failed update validation' );
            return 0;
        }

    }

    $set = $self->make_table_update_set_statement( -fields => $newfields, -values => \@entries, -append_only_fields => $append_only_fields, -append_separator => $append_separator );

    if ($test) {
        $self->finish_trans( 'update_records', 'Just testing' );
        return "UPDATE $ignore $TableName SET $set $condition\n";
    }

    my $updated_records = 0;
    my $newentry;
    if ( $set =~ /^ =/ ) {
        $self->finish_trans( 'update_records', "Improper format ($set)" );
        return 0;
    }
    elsif ($set) {
        $newentry = "UPDATE $ignore $TableName SET $set $condition";

        # Check mandatory, foreign, and Unique fields...
        if ($confirm) {
            my $ok = Prompt_Input( 'c', $newentry );
            unless ( $ok =~ /y/i ) {
                $self->finish_trans( 'update_records', 'Aborted' );
                return 1;
            }
        }

        if ($debug) {
            $self->message("*** Command:$newentry.");
        }
        my $start = time();

        # if a transaction already started, do not wrap in eval statements
        $updated_records = $self->dbh()->do($newentry);

        my $end = time();
        $self->_track_if_slow( "update: $newentry", -time => $end - $start );
        my $error = Get_DBI_Error();
        if ( !defined $updated_records && $error ) {
            Call_Stack();
            $self->message("Update Array Error: $newentry ($error)");
        }
        $updated_records += 0;
    }
    else {
        $self->finish_trans( 'update_records', '(nothing set)' );
        return 0;
    }

    if ( ( $updated_records eq 'NULL' ) || ( $updated_records < 0 ) ) { $updated_records = 0; }

    my $trigger_success = 1;
    if ( !$no_triggers ) {

        my ( $tables, $join_condition ) = $self->extract_table_joins($TableName);    ## get list of tables being updated (non-trivial for left joins) ##
        foreach my $table ( split ',', $tables ) {
            my @ids_list = $self->get_Primary_ids( -tables => $tables, -ref_table => $table, -condition => "$condition AND $join_condition" );
            $self->execute_preliminary_actions( -table => $table, -action => 'update', -ids => \@ids_list, -fields => \@update_fields );
            if ( $self->has_Trigger( -table => $table, -action => 'update', -fields => \@update_fields ) ) {
                ### update trigger exists ###
                if (@ids_list) {
                    $trigger_success = $self->execute_Trigger( -table => $table, -action => 'update', -ids => \@ids_list, -fields => \@update_fields );
                    if ( !$trigger_success ) {last}
                }
                else {
                    Message("No records updated in $table..");
                }
            }
        }
    }

    # Log to updates file if from web

    my $log_info = "UPDATE $ignore $self->{dbase}.$TableName ($self->{host})\n";
    $log_info .= "User: " . $self->get_local('user_name') . "\n";
    $log_info .= "Date: " . date_time() . "\n";
    $log_info .= "File: " . $0 . "\n";
    $log_info .= "SQL: $newentry\n";
    $log_info .= "Update fields: @update_fields\n";
    $log_info .= "Update values: @entries\n";
    $log_info .= "Condition: $condition\n" if ($condition);
    $log_info .= "Autoquote = $auto_quote\n";
    $log_info .= "Updated = $updated_records\n";

    $self->update( $TableName, $log_info ) if $updated_records;

    $self->finish_trans( 'update_records', -debug => $debug );
    return $updated_records;
}

#	Given field values and fields, builds SET statement in table update
# optionally add append_only_fields and append_separator for fields such as comments, notes, description etc...
# Usage: $self->make_table_update_set_statement(	-fields => ['FK_Source__ID', 'Sample_Comments'],
#																						-values => ['123456', '[2011-12-12]Associated with correct source'],
#																						-append_only_fields => ['Sample_Comments'] );
#############################
sub make_table_update_set_statement {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,fields,values', -mandatory => 'dbc|self,fields,values', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $newfields          = $args{-fields};                     # fields to change
    my $entries            = $args{ -values };                   # new values
    my $append_only_fields = $args{-append_only_fields};         # fields that should be appending only eg. comments
    my $append_separator   = $args{-append_separator} || ',';    # separator used to separate each append

    my %append_lookup = ();
    if ( defined $append_only_fields && @$append_only_fields ) {
        @append_lookup{@$append_only_fields} = ();
    }

    my $set   = '';
    my $count = 0;
    foreach my $field (@$newfields) {
        my $entry = $entries->[$count];

        # will concat previous values in fields if append only...
        if ( exists $append_lookup{$field} ) {
            $entry = "CASE WHEN COALESCE(LENGTH($entry), 0) > 0 THEN CASE WHEN $field IS NOT NULL AND $field != '' THEN CONCAT($field, \"$append_separator\", $entry) ELSE $entry END ELSE $field END";
        }

        $set .= "$field = $entry,";
        $count++;
    }
    chop $set;

    return $set;
}

################################################################################
#  Updating a table with binary information
################################################################################

##############################
sub Table_binary_update {
##############################
    #
    #  updates Table with values specified...
    # (does NOT include update check)
    #
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values,condition', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table     = $args{-table};
    my $field     = $args{-fields};       # binary field to update
    my $value     = $args{ -values };     # value of field to update to
    my $condition = $args{-condition};    # condition under which update applies

    my $query = "Update $table set $field = ? $condition";
    my $sth   = $self->dbh()->prepare($query);
    my $ok    = $sth->execute($value);
    if ( defined $sth->err() ) {
        $self->message( "Table_binary_update Error: " . Get_DBI_Error() );
        $self->message("MySQL statement = $query");
    }

    $sth->finish();
    if   ( defined $ok ) { return $ok; }
    else                 { return 0; }
}

########################################
# DELETE Records from the Database
########################################

# Delete multiple records from multiple tables
#
# Return: Hash of deleted records
#################
sub DB_delete {
#################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $tables    = $args{-tables};              ### A list of tables to delete from
    my $records   = $args{-records};             ### specify records to delete  (e.g. $records->{"Library.Library_Name"} = ['CN001','CN002'])
    my $skip      = $args{-skip} || $tables;     ### The list of tables to skip checking for dependency in the initial check
    my $autoquote = $args{-autoquote};           ### whether to autoquote the values
    my $debug     = $args{-debug} || $self->config('test_mode');

    $tables = Cast_List( -list => $tables, -to => 'arrayref' );
    $skip   = Cast_List( -list => $skip,   -to => 'arrayref' );

    ### Starts transaction if not already started ###
    $self->Benchmark('start_delete_transaction');
    $self->start_trans( -name => 'DB_delete' );

    my %deletes;

    # First check to make sure all values from all tables can be deleted
    foreach my $record ( keys %$records ) {
        my ( $table, $field ) = simple_resolve_field( $record, -dbc => $self );
        foreach my $value ( @{ $records->{$record} } ) {
            if ($autoquote) { $value = $self->dbh()->quote($value) }
            if ( $self->deletion_check( $table, $field, $value, undef, undef, undef, $skip ) ) {
                push( @{ $deletes{$table}->{$field} }, $value );
            }
            else {

                #		$self->{transaction}->error("Failed to Delete $field = $value");
                Message("Cannot delete where $table.$field = $value");
                $self->finish_trans( 'DB_delete', -error => "Cannot delete where $table.$field = $value" );
                return 0;
            }
        }
    }

    my @commands;
    my $start = timestamp();
    my %deleted;

    # Now do the actual delete
    foreach my $table ( reverse @$tables ) {    ### Start deleting from the table that is last in the list
        my $condition = "where 1 ";
        foreach my $field ( keys %{ $deletes{$table} } ) {
            $condition .= "and $field in (";
            foreach my $value ( @{ $deletes{$table}->{$field} } ) {
                Message("Try to delete $field = $value...");
                if ( $self->deletion_check( $table, $field, $value ) ) {
                    &RGTools::RGIO::Test_Message( "(ok to delete $field = $value)", $debug );
                    $condition .= "$value,";
                }
                else {

                    #			$self->{transaction}->error("Failed to delete $field = $value");
                    $self->finish_trans( 'DB_delete', -error => "Failed to delete $field = $value" );
                    return 0;
                }
            }
            $condition =~ s/(.*),$/$1/;
            $condition .= ")";
        }

        ### Now do the delete
        my $command;

        &RGTools::RGIO::Test_Message( "DELETE $condition", $debug );
        $command = "Delete from $table $condition";

        #print "*********$command*********\n";
        &RGTools::RGIO::Test_Message( "Command: $command.", $debug );

        #	    $self->{transaction}->message($command) if $self->{transaction}; ## add to Transaction messages ##
        $deleted{$table} = $self->dbh()->do($command);
        push( @commands, $command );
    }
    $self->finish_trans( 'DB_delete', -error => $@ );
    my $end = timestamp();
    $self->_track_if_slow( "Transaction\n" . Dumper( $self->{transaction} ) . "\n", $end - $start );

    return \%deleted;
}

########################
sub get_Breakaway_Options {
########################
    my %args = &filter_input( \@_, -args => 'dbc,table,field,default', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self    = $args{-self} || $args{-dbc};
    my $table   = $args{-table};
    my $field   = $args{-field};
    my $default = $args{-default};
    my @selectable;

    if ( $field && $table && $default ) {
        my @options = $self->Table_find(
            'DB_Form as parent , DB_Form as child', 'child.Parent_Value',
            "WHERE child.FKParent_DB_Form__ID = parent.DB_Form_ID 
      and parent.Form_Table = '$table'  
      and child.Parent_Field = '$field';"
        );

        unless ( int {@options} && $options[0] ) {
            return;
        }
        if ( grep /^$default$/, @options ) {

            @selectable = $self->Table_find(
                'DB_Form as parent , DB_Form as child, DB_Form as other', 'other.Parent_Value',
                "WHERE child.FKParent_DB_Form__ID = parent.DB_Form_ID 
         and other.FKParent_DB_Form__ID = parent.DB_Form_ID
         and other.Form_Table = child.Form_Table
         and other.Parent_Field = '$field'
         and child.Parent_Value = '$default'
         and parent.Form_Table = '$table'  
         and child.Parent_Field = '$field';"
            );
        }
        else {
            my @all_options = $self->get_FK_info( -field => $field, -list => 1, );
            require RGTools::RGmath;
            @selectable = RGmath::minus( \@all_options, \@options );
        }

        if ( int {@selectable} && $selectable[0] ) {
            return \@selectable;
        }
        else {
            return ($default);
        }

    }
    else {
        return;
    }

    return;
}

#########################
sub delete_records {
#########################
    #
    # Delete Records from earlier routine WHERE list of ID's is given by parameter 'Mark'
    #
    my %args = &filter_input( \@_, -args => 'dbc,table,dfield,id_list,extra_condition,autoquote,replace,override,cascade,batch,cascade_condition', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    if ( $args{ERRORS} ) { Message("Input Error Found: $args{ERRORS}"); return; }
    my $table           = $args{-table};                                # Table
    my $dfield          = $args{-dfield};                               # ID field
    my $id_list         = $args{-id_list};                              # comma-delimited list ... this deletes WHERE $dfield in ($id_list)
    my $extra_condition = $args{-condition} || 1;                       ### (add extra condition - optional)
    my $auto_quote      = $args{-autoquote};                            ### auto-matically quotes values (NOT used for example for: Name = Left(FullName,5))
    my $replacement     = $args{-replace};                              ### replace foreign keys pointing to deleted record to point to this id instead (MUST BE FK to primary key)
    my $override        = $args{-override};                             ### overide permission checks - i.e. ok to delete regardless of user's permission.
    my $batch_delete    = defined $args{-batch} ? $args{-batch} : 1;    # allows to delete multiple records using WHERE $dfield in ($id_list) rather than one record at a time
    my $cascade_delete = $args{-cascade};    ## hash or array of 'REFERENCED BY' tables to delete (in order in which they should be deleted) .. eg ['Tube','Plate_Set'] or {'Plate' => ['Tube','Plate_Set'], 'Plate_Set' => ['Plate_Prep']}
    my $debug          = $args{-debug};
    my $quiet          = $args{-quiet};
    my $confirm        = $args{-confirm};    ## prompt for confirmation at each record.

    ## Hash that is put in so that you are able to put different conditions on the cascades.
    ## The keys of the hash refer to the table which is being deleted.
    ## If the value is another hash, then the code will pass that as -cascade_delete.
    ## If however the value is a string (A mysql condition) then it will pass that as a -condition parameter.
    ## Only works when $cascade_delete has an inputted hash. For an example look at Container.pm and the Delete_Container method

    my $cascade_delete_condition = $args{-cascade_condition};
    my %cascade_condition;

    $id_list = Cast_List( -list => $id_list, -to => 'string', -autoquote => 1 );

    if ( $debug && $cascade_delete ) {
        print HTML_Dump "CASCADE delete $table records ($dfield in ($id_list) " . ref $cascade_delete, $cascade_delete;
    }

    my @cascade = undef;
    my %Cascade = undef;

    if ($cascade_delete_condition) {
        %cascade_condition = %$cascade_delete_condition;
    }

    if ( ref $cascade_delete eq 'ARRAY' ) {
        ## simple ordered list of records to delete first ##
        @cascade = @$cascade_delete;
    }
    elsif ( ref $cascade_delete eq 'HASH' ) {
        ## complex multiple hierarchy of deletions ##
        %Cascade = %$cascade_delete;
    }

    my $primary = $Primary_fields{$table} || join ',', $self->get_field_info( $table, undef, 'Primary' );

    #  safer to ensure that this is set ...
    if ( !$dfield ) {
        $dfield = $primary;
    }

    if ( $dfield ne $primary ) {
        if ($id_list) {
            my $fk_list = $id_list;
            ## only necessary for multi-layered cascading deletions ##
            my $condition   = "WHERE $dfield IN ($fk_list) AND $extra_condition";
            my $check_table = $table;
            if ( $table eq 'Change_History' ) { $check_table = "$table,DBField"; $condition .= " AND DBField_ID = FK_DBField__ID and Field_Table = '$args{-change_history_table}'" }
            $id_list = join ',', $self->Table_find( $check_table, $primary, $condition );    #, -debug => 1
        }
        if ( !$id_list ) { return 1; }                                                       ## no records need to be deleted for this table ##
    }

    my $dref          = -1;
    my $count         = 0;
    my $total_deleted = 0;
    my $value;
    my $deleted;
    my $reference_deleted = 1;

    ########### if autoquote , quote the values listed...  ############
    if ($auto_quote) {
        $id_list = Cast_List( -list => $id_list, -to => 'string', -autoquote => 1 );
        $replacement = $self->dbh()->quote($replacement);
    }

    ### Starts transaction
    $self->Benchmark('start_delete_transaction');
    $self->start_trans("delete_records $table");

    my @ids;
    if ($batch_delete) {
        ### delete together ## (all or nothing deleted)
        @ids = ($id_list);
    }
    else {
        ## delete one record at a time ## (deletions committed independently)
        @ids = split ',', $id_list;
    }

    my @cascade_deletes;
    if ( @cascade && $cascade[0] ) {
        @cascade_deletes = @cascade;
    }
    elsif ( defined $Cascade{$table} && $Cascade{$table}->[0] ) {
        @cascade_deletes = @{ $Cascade{$table} };
    }
    elsif ($cascade_delete) {
        Message("Warning: cascade defined but not recognized");
    }
    push @cascade_deletes, 'Change_History';

    my %local_args = %args;    ## copy local arguments for cascaded deletes
    $local_args{-condition} = '';       # only used for the original deleted record
    $local_args{-batch}     = 1;        # force batch delete for cascaded tables
    $local_args{-debug}     = $debug;

    if ($debug) { print HTML_Dump "$table IDs, Cascade, ARRAY, HASH", \@ids, \@cascade_deletes, \@cascade, \%Cascade }

    foreach my $id_batch (@ids) {
        my ( $count, $tried ) = ( 0, 0 );

        ## check if referencing tables can be deleted and delete them

        foreach my $referencing_table (@cascade_deletes) {
            my $sub_cascade;            ## cascading tables applicable to each recursive table (only when cascade supplied as a hash) ##
            my $sub_cascade_condition = undef;    ## cascades the conditions which is given with the recursive table.

            if (%Cascade) { $sub_cascade = get_cascade( \%Cascade, $referencing_table ) }
            if ( exists( $cascade_condition{$referencing_table} ) ) {
                $sub_cascade_condition = $cascade_condition{$referencing_table};
            }

            $local_args{-id_list} = $id_batch;
            $local_args{-table}   = $referencing_table;    ## replace table parameter
            $local_args{-cascade} = $sub_cascade;          ## replace cascade parameter
            if ( ref $sub_cascade_condition eq 'HASH' ) {
                $local_args{-cascade_condition} = $sub_cascade_condition;    ## replace cascade_condition parameter
            }
            else {
                $local_args{-condition} = $sub_cascade_condition;
            }

            unless ( $referencing_table =~ /^\w+$/ ) {next}                  ## skip possible non-words (eg '-- choose --' in lists)

            my @fk_fields = _get_FK_name( $self, $referencing_table, $table, $primary );
            unless (@fk_fields) {
                ## Get Indirect reference
                @fk_fields = $self->Table_find( 'DBField', 'Field_Name', "WHERE Field_Table = '$referencing_table' and (Field_Name ='Object_ID' or Field_Name = 'Record_ID')" );
            }

            if ($debug) { Message("Check for $referencing_table records (referencing @fk_fields)") }
            my $deletion_count = 0;
            foreach my $fk_field (@fk_fields) {
                $local_args{-dfield} = $fk_field;
                if ( $referencing_table eq 'Change_History' ) { $local_args{-change_history_table} = $table; }
                my $deleted = $self->delete_records(%local_args);
                $deletion_count += $deleted;
                $reference_deleted *= $deleted;    ## clears to zero if any of these fail deletion

                if ($reference_deleted) {
                    if ($debug) { Message("$fk_field..($deleted)") }
                }
                else {
                    $self->finish_trans( "delete_records $table", -error => "Failed to delete $referencing_table" );
                    return 0;
                }
            }

            #    if ($deletion_count) { Message("Deleted $deletion_count $referencing_table records") }
        }
        ## if all referencing tables have been deleted successfully delete the actual record requested by the user

        if ($reference_deleted) {
            if ( !$quiet ) { Message("Deleting $table records") }
            $deleted = $self->delete_record(
                -table     => $table,
                -field     => $primary,
                -id_list   => $id_batch,
                -condition => $extra_condition,
                -override  => $override,
                -debug     => $debug,
                -quiet     => $quiet,
                -autoquote => $auto_quote
            );
            $tried++;
            if ($deleted) { $count++ }
            $total_deleted += $deleted;
        }

        if ($deleted) {
            $self->{transaction}->message( scalar(@ids) . " $primary record(s) marked for deletion from $table table" );
        }
        else {
            $self->finish_trans( "delete_records $table", -error => "Failed to delete $table ($primary IN ($id_list)" );
            return 0;
        }

        if ( !$quiet ) { $self->message("$total_deleted $table records deleted successfully. ($count / $tried)") }
    }
    $self->Benchmark('finish_delete_transaction');
    $self->finish_trans("delete_records $table");
    $self->Benchmark('deleted_records');
    return $deleted;
}

#
# Retrieve the relevant cascading tables given a hash of tables to cascade delete.
#
# eg .  if A <- B <- C <- D;  A -< E    then -cascade => { A => [B,E], B=>[C], C=>[D] }
#
#  get_cascade(A) = {  { A => [B,E], B=>[C], C=>[D] }
#  get_cascade(B) = {  { B => [C], C=>[D] }
#  get_cascade(C) = [D]                         ### if one-dimensional, use array reference for simple case ##
#
####################
sub get_cascade {
####################
    my $cascade = shift;
    my $table   = shift;

    my %input_Cascade = %$cascade;
    my %Cascade;

    if ( !defined $input_Cascade{$table} ) { return; }

    my @cascade = @{ $input_Cascade{$table} };
    while (@cascade) {
        my @next_cascade;
        foreach my $table (@cascade) {
            if ( $input_Cascade{$table} ) {
                my @next_layer = @{ $input_Cascade{$table} };
                $Cascade{$table} = \@next_layer;
                push @next_cascade, @next_layer;
            }
        }
        @cascade = @next_cascade;
    }

    my $returnval;
    if (%Cascade) {
        $Cascade{$table} = $input_Cascade{$table};

        $returnval = \%Cascade;    ## still hash cascade ##
    }
    else {
        $returnval = $input_Cascade{$table};    ## simple cascade
    }

    return $returnval;
}

###########################
sub delete_record {
#########################
    #
    # This routine deletes a record from a table after checking with 'deletion_check'
    #
    # (it was originally set up only to be called from 'delete_records', but
    # an extra condition parameter was added to allow some more conditional deletions
    #
    #########################
    my %args = &filter_input(
         \@_,
        -args      => 'dbc,table,field,value,condition,replace,autoquote,override,transaction,id_list',
        -mandatory => 'dbc|self',
        -self      => 'SDB::DBIO'
    );
    my $self = $args{-self} || $args{-dbc};
    if ( $args{ERRORS} ) { Message("Input Error Found: $args{ERRORS}"); return; }

    my $table      = $args{-table};
    my $field      = $args{-field};               # (eg. delete WHERE $field = $value)
    my $value      = $args{-value};               # (eg. delete WHERE $field = $value)
    my $condition  = $args{-condition} || 1;      # extra condition...
    my $auto_quote = $args{-autoquote};           ### automatically quotes values (NOT used for example for: Name = Left(FullName,5))
    my $override   = $args{-override};            ### overide permission checks - i.e. ok to delete regardless of user's permission.
    my $debug      = $args{-debug} || $self->config('test_mode');
    my $quiet      = $args{-quiet};
    my $confirm    = $args{-confirm};
    my $id_list    = $args{-id_list} || $value;

    my $qid_list = $id_list;
    my $command;
    my $perform;
    my $track        = '';
    my $deleted      = 0;
    my $ok_to_delete = 1;

    if ($confirm) {
        my $ok = Prompt_Input( -type => 'c', -prompt => "Delete from $table records where $field IN ($qid_list) $condition?" );    #(replacement = $replacement)
        unless ( $ok =~ /y/i ) { Message("Skipped deletion"); return 1; }
    }
    if ($id_list) {
        if ( !$self->deletion_check( -table => $table, -field => $field, -value => $id_list, -condition => $condition, -override => $override, -debug => $debug, -confirm => $confirm, -autoquote => $auto_quote ) ) {
            $ok_to_delete = 0;
            Message("$table ($field = $id_list) Failed deletion check");
        }
    }
    else {
        if ( !$self->deletion_check( -table => $table, -field => $field, -value => $value, -condition => $condition, -override => $override, -debug => $debug, -confirm => $confirm, -autoquote => $auto_quote ) ) {
            $ok_to_delete = 0;
            Message("$table ($field = $value) Failed deletion check");
        }
    }
    if ($auto_quote) {
        $value = $self->dbh()->quote($value);
        $qid_list = Cast_List( -list => $id_list, -to => 'string', -autoquote => 1 ) if $id_list;
    }

    ## return success right away if there is no referring records ##
    my $existing_ref;
    if ($qid_list) {
        ($existing_ref) = $self->Table_find( $table, $field, "WHERE $field IN ($qid_list)" );
    }

    unless ($existing_ref) {

        # Message("No $table references..");
        return 1;
    }

    ### Starts transaction
    $self->start_trans( -name => "delete_record $table" );

    ######################## START EVAL ################################
    my $start = time();
    my $list_condition;
    if ($ok_to_delete) {
        if ($id_list) {
            $list_condition = "$field IN ($qid_list)";
        }
        else {
            $list_condition = "$field = $value";
        }
        $command = "Delete FROM $table WHERE $list_condition AND $condition";
        $self->message("ok to delete $field IN ($qid_list)") if $debug;
    }
    else {
        $self->finish_trans( "delete_record $table", -error => "$table record ($field: $id_list or $value) could not be deleted --> Deletion aborted!" );
        return 0;
    }

    ########## Custom Insertion for Sample sheet deletion.  ###########
    if ( ( $table eq 'Run' ) ) {
        ###### remove sample sheet ############
        $value ||= $id_list if $id_list;
        &Sequencing::Sample_Sheet::remove_ss( -condition => "WHERE Run_ID in ($value)", -dbc => $self );
        $self->{transaction}->message("remove_ss WHERE Run_ID in ($value)");    ## include in transaction object  ##
    }
    ########## End of Custom Insertion for Sample sheet deletion.  ###########

    $self->message("** CMND: $command.") if $debug;
    $self->{transaction}->message($command);                                    ## include command in transaction object if applicable ##
    $deleted = $self->dbh()->do($command);
    $self->message("Deleting $table record (where $field IN ($id_list/$value) AND $condition) - Deleted $deleted.") unless ($quiet);

    $self->finish_trans( "delete_record $table", -error => $@ );

    my $end = time();
    $self->_track_if_slow( "Delete: $command", -time => $end - $start );        ## track ALL deletions in database.

    # Log to deletions file
    my $log_info = "DELETE FROM $dbase.$table (host=$Defaults{mySQL_HOST})\n";
    $log_info .= "Date: " . date_time() . "\n";
    $log_info .= "User: " . $self->get_local('user_name') . "\n";
    $log_info .= "File: " . $0 . "\n";
    $log_info .= "SQL: $command\n";
    $log_info .= "$list_condition\n";
    $log_info .= "Condition: $condition\n" if ($condition);

    #$log_info .= "Replacement: $replacement\n" if ($replacement);
    $log_info .= "Autoquote: $auto_quote \n";
    $log_info .= "Override: $override \n";
    $log_info .= "Success = $deleted\n";

    $self->deletion( $table, "$command ($deleted)" );
    $self->Benchmark("deleted_$table");
    return $deleted;
}

# This is a validation checker for record deletion
# It checks to make sure foreign tables do not point to deleted data
#
# Return: 1 on success, O on failure
###########################
sub deletion_check {
#########################

    my %args = &filter_input(
         \@_,
        -args      => 'dbc,table,field,value,condition,replace,override,skip,transaction',
        -mandatory => 'dbc|self',
        -self      => 'SDB::DBIO'
    );
    my $self = $args{-self} || $args{-dbc};

    my $table             = $args{-table};             # table to check
    my $field             = $args{-field};             # (eg. delete where $field = $value)
    my $value             = $args{-value};             # (eg. delete where $field = $value)
    my $extra_condition   = $args{-condition} || 1;    ###### allow extra condition...
    my $override          = $args{-override};          #Whether to override user permission checks
    my $skip_child_tables = $args{-skip};              #### A list of child tables that the check can skip [ArrayRef]
    my $debug             = $args{-debug};
    my $confirm           = $args{-confirm};
    my $autoquote         = $args{-autoquote};

    my $condition;
    my $found;
    my $tables;

    ##### Custom Insertion (permission check ) #######
    $user_id = $self->get_local('user_id') if ( $self && !$user_id );
    if ( !$override && !$self->check_permissions( $user_id, $table, 'delete', $field, $value ) ) {
        ## permission denied ##
        $self->error("Permission to delete $table ($field=$value) denied to user $user_id");
        return 0;
    }
    ##### End Custom Insertion (permission check ) #######

    my $primary = join ',', $self->get_field_info( $table, undef, 'Primary' );
    my ( $something, $details, $refs ) = $self->get_references(
        -table                  => $table,
        -field                  => $primary,
        -value                  => $value,
        -exclude_self_reference => 1,
        -indirect               => 1
    );

    if ($refs) {
        my $found;
        my %references = %$refs;
        for my $qualified_reference ( keys %references ) {
            my ( $ref_table, $ref_field ) = $self->foreign_key_check($qualified_reference);
            if ( $ref_field ne $field ) {next}    ## reference is not to primary field (okay)  - eg plate_set_number references...

            my @records      = @{ $references{$qualified_reference} };
            my $record_count = @records;
            $found = 1;
            $self->error("Cannot delete $table ($field=$value) denied.  $record_count records from $qualified_reference refer to it");
        }
        if   ($found) { return 0 }
        else          { return 1 }
    }

    return 1;
}

###########################
sub replace_records {
#########################
    my $self      = shift;
    my %args      = &filter_input( \@_, -mandatory => 'table,value|id_list,replace' );
    my $table     = $args{-table};
    my $dfield    = $args{-dfield};                                                      # ID field
    my $value     = $args{-value} || $args{-id_list};
    my $replace   = $args{-replace};
    my $field     = $args{-field};
    my $condition = $args{-condition} || 1;
    my $debug     = $args{-debug};
    my $quiet     = $args{-quiet};
    my $confirm   = $args{-confirm};                                                     ## prompt for confirmation at each record.

    my ($primary) = $self->get_field_info( $table, undef, 'Primary' );
    $value = Cast_List( -list => $value, -to => 'string', -autoquote => 1 );

    if ( $primary ne $dfield ) {
        ## only necessary for multi-layered cascading deletions ##
        my $fk_list = $value;
        $value = join ',', $self->Table_find( $table, $primary, "WHERE $dfield IN ($fk_list) AND $condition" );
        if ( !$value ) { return 1; }                                                     ## no records need to be deleted for this table ##

    }
    my ( $something, $details, $refs ) = $self->get_references(
        -table    => $table,
        -field    => $primary,
        -value    => $value,
        -indirect => 1
    );

    $self->start_trans( -name => "replace_records" );

    if ($refs) {
        my %references = %$refs;
        for my $qualified_reference ( keys %references ) {
            my $fail;
            if ( $qualified_reference =~ /^(.+)\.(.+)$/ ) {
                for my $id ( split ',', $value ) {
                    my $success = $self->replace_record( -table => $1, -value => $id, -replace => $replace, -field => $2, -original_table => $table );
                    unless ($success) {
                        $self->finish_trans( "replace_records", -error => "$1 record ($2: $id) could not be replaced --> Replacement aborted!" );
                        return 0;
                    }
                }
            }
        }
    }

    my $result = $self->delete_record(
        -table     => $table,
        -field     => $primary,
        -id_list   => $value,
        -autoquote => 1,
    );
    unless ($result) {
        $self->finish_trans( "replace_records", -error => "$table record ($primary: $value) could not be Deleted --> Replacement aborted!" );
        return 0;
    }

    $self->finish_trans("replace_records");
    return 1;
}

# Return: 1 on success, O on failure
###########################
sub replace_record {
#########################
    my $self           = shift;
    my %args           = &filter_input( \@_ );
    my $table          = $args{-table};
    my $value          = $args{-value};            # has to be single value
    my $replace        = $args{-replace};
    my $field          = $args{-field};
    my $condition      = $args{-condition} || 1;
    my $confirm        = $args{-confirm};
    my $original_table = $args{-original_table};
    my $debug          = $args{-debug};
    my $result;
    my $autoquote;
    my ($primary) = $self->get_field_info( $table, undef, 'Primary' );
    my $temp = join ',', $self->Table_find( $table, $primary, " WHERE  $field IN ($value)" );
    unless ($temp) { return 1 }

    $self->start_trans( -name => "replace_record $table" );
    $replace = Cast_List( -list => $replace, -to => 'string', -autoquote => 1 );

    if ( $table =~ /_Attribute$/ ) {
        ## Inherit attributes
        require SDB::DB_Object;
        my $db_obj = new SDB::DB_Object( -dbc => $self, -tables => $original_table );
        $db_obj->inherit_Attribute( -child_ids => $replace, -parent_ids => $value, -tables => $original_table, -conflict => 'ignore' );

        my ($primary) = $self->get_field_info( $table, undef, 'Primary' );
        my $ids = join ',', $self->Table_find( $table, $primary, " WHERE  $field IN ($value)" );
        unless ($ids) {
            $self->finish_trans("replace_record $table");
            return 1;
        }

        $result = $self->delete_record(
            -table   => $table,
            -field   => $primary,
            -id_list => $ids,
        );
    }
    elsif ( $table eq 'Change_History' ) {
        ## Change comments
        my $comment = " -- original record: " . $value;
        $self->Table_update_array(
            'Change_History, DBField', ['Comment'], ["$comment"],
            "WHERE FK_DBField__ID = DBField_ID and Field_Table = '$original_table' AND Record_ID in ($value) AND $condition",
            -autoquote => 1,
            -debug     => $debug
        );

        $result = $self->Table_update_array(
            'Change_History, DBField', ['Record_ID'], [$replace],
            "WHERE FK_DBField__ID = DBField_ID and Field_Table = '$original_table' AND Record_ID in ($value) AND $condition",
            -debug     => $debug,
            -autoquote => $autoquote
        );
        $result = 1;
        $self->message("Replaced $table records ($value) with ($replace) ");

    }
    elsif ( $field eq 'Object_ID' ) {

        #gotta consider FK_Object ID HERE
        $result = $self->Table_update_array(
            "$table,Object_Class", ["$field"], [$replace], "WHERE FK_Object_Class__ID = Object_Class_ID and Object_Class = '$original_table' and $table.$field in ($value) AND $condition",
            -debug     => $debug,
            -autoquote => $autoquote
        );
        $self->message("Replaced $table records ($value) with ($replace) ");

    }
    else {
        my ($table_type) = $self->Table_find( 'DBTable', 'DBTable_Type', " WHERE DBTable_Name = '$table'" );
        if ( $table_type eq 'Subclass' ) {
            ## delete table with id = value
            my ($primary) = $self->get_field_info( $table, undef, 'Primary' );
            my $ids = join ',', $self->Table_find( $table, $primary, " WHERE  $field IN ($value)" );
            $result = $self->delete_record(
                -table   => $table,
                -field   => $primary,
                -id_list => $ids,
            );
        }
        else {
            $result = $self->Table_update_array( $table, ["$field"], [$replace], "WHERE $table.$field in ($value) AND $condition", -debug => $debug, -autoquote => $autoquote );
            $self->message("Replaced $table records ($value) with ($replace) ");
        }

    }

    $self->finish_trans("replace_record $table");

    return $result;

}

#
# Determine whether referencing field is pointing to primary field in reference table.
#
#
# eg return 0 if FK_Plate_Set__Number references Plate_Set when deleting Plate_Set_ID ...
#
# Return: 1 if field is referencing same attribute
###################
sub _same_field {
###################
    my $field      = shift;
    my $otherfield = shift;

    my ( $field_spec, $other_spec );

    if ( $field =~ /(.*)_(.+)$/ ) { $field_spec = $2 }

    if ( $otherfield =~ /(.*)_(.+)$/ ) { $other_spec = $2 }

    if ( $field_spec eq $other_spec ) { Message("$field ($field_spec) = $otherfield ($other_spec)"); return 1; }
    else                              { return 0 }
}

#################################
# Retrieve the join condition required given a list of tables
#
#
# RETURN: condition (eg. for $tables = 'Plate,Run,Clone_Sequence)
#  'FK_Run__ID=Run_ID AND FK_Plate__ID=Plate_ID'
#########################
sub get_join_condition {
#########################
    my %args = &filter_input( \@_, -args => 'dbc,tables,join_conditions,no_joins', -mandatory => 'dbc|self,tables', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $tables          = $args{-tables};
    my $join_conditions = $args{-join_conditions};    ### optionally specified join conditions (arrayref)
    my $no_joins        = $args{-no_joins};           ### optionally specified tables not to be joined [arrayref]
    my $exclude         = $args{-exclude};
    my $debug           = $args{-debug};

    my @table_list = Cast_List( -list => $tables, -to => 'array' );
    my $condition;

    if ( int(@table_list) < 2 ) {return}              ## no need for join if 1 or no tables..
    my %made_joins;
    my @join_conditions;                              ## account for conditions already specified ...

    foreach my $condition (@$join_conditions) {
        my ( $checked_condition, $t1, $t2 ) = $self->parse_join_condition( -condition => $condition, -debug => $debug );
        if ($checked_condition) {
            $made_joins{"$t1.$t2"} = 1;
            $made_joins{"$t2.$t1"} = 1;
            push @join_conditions, $checked_condition;
        }
    }

    my $duplicate_joins = 1;
    foreach my $table (@table_list) {
        if ( $exclude && grep /^$table$/, @$exclude ) {next}

        ## check for references to other tables in this list
        my $join_condition;
        my $dbtable = $table;
        my $newtablename;
        if ( grep /\bAS\b/i, $table ) {    # if the table has been given a new identifier
            ( $dbtable, $newtablename ) = split( "AS", $table );
        }
        my %fks = $self->Table_retrieve(
            'DBTable,DBField',
            [ 'DBTable_Name', 'DBField_ID', 'Field_Name', 'Foreign_Key' ],
            "where DBTable_ID=FK_DBTable__ID and DBTable_Name = '$dbtable' and Length(Foreign_Key) > 1 AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'"
        );
        my $i = 0;
        while ( defined $fks{DBField_ID}[$i] ) {
            my $t = $fks{DBTable_Name}[$i];
            if ($newtablename) { $t = $newtablename }
            my $f  = $fks{Field_Name}[$i];
            my $fk = $fks{Foreign_Key}[$i];
            $i++;

            $fk =~ /(\w+)\.(\w+)/;
            my $fk_table = $1;
            if ( grep /\b$fk_table\b/, @table_list ) {    # If foreign table is in the list
                unless ( $fk_table eq $t ) {              # Do not self join (in case of recursive fields)
                    if ( $made_joins{"$t.$fk_table"} ) {
                        $duplicate_joins++;
                        next;
                    }                                     # Do not join again if join is already made
                    elsif ( $made_joins{"$fk_table.$t"} ) {
                        $duplicate_joins++;
                        next;
                    }                                     # Do not join again if join is already made
                    elsif ( $no_joins && ( grep /^$fk_table$/, @$no_joins ) && ( grep /^$t$/, @$no_joins ) ) {
                        next;
                    }                                     # Do not join if joining tables specified as no joins
                    $made_joins{"$t.$fk_table"} = 1;
                    $join_condition = "$t.$f = $fk";
                    push( @join_conditions, $join_condition );
                    if ($debug) { Message("*** ADDED $join_condition dynamically ($fk_table, $t)***"); print HTML_Dump $no_joins }
                }
            }
            else {
                my $tl = join ":", @table_list;
            }
        }
    }

    if ( int(@join_conditions) > int(@table_list) - 1 ) {

        #$self->warning('Too many join conditions generated ?');
        #Message("JC: @join_conditions");
        #Message("T: @table_list");
        #Call_Stack();
    }
    elsif ( int(@join_conditions) < ( int(@table_list) - $duplicate_joins ) ) {

        #     The logic above has been refactored in the next version.... leave message below only for debugging purposes in the meantime...

        if ($debug) {
            $self->error("Not enough join conditions generated ? $duplicate_joins");

            Message("JC: @join_conditions");
            Message("T: @table_list");
            Call_Stack();
        }
    }

    return join ' AND ', @join_conditions;
}

###############################
sub parse_join_condition {
###############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'condition' );
    my $condition = $args{-condition};
    my $debug     = $args{-debug};

    if ( $condition =~ /^([\w\.]+)\s?=\s?([\w\.]+)$/ ) {
        my $lval = $1;
        my $rval = $2;

        my $i = -1;
        my @table;
        my @field;
        my @ref_T;
        my @ref_F;

        foreach my $element ( $lval, $rval ) {
            $i++;
            if ( $element =~ /(\w+)\.(\w+)/ ) {
                $table[$i] = $1;
                $field[$i] = $2;
                ( $ref_T[$i], $ref_F[$i] ) = $self->foreign_key_check($2);
            }
            elsif ( $element =~ /(\w+)[_](ID|Name|Code)/ ) {
                $table[$i] = $1;
                $field[$i] = $element;
            }
            else {
                if ($debug) {
                    $self->warning("Element in condition not in proper format ($element ?)");
                }
                next;
            }
        }
        if ( $ref_T[0] && $ref_T[1] ) {
            ## both elements point to FK (eg Run.FK_Plate__ID = Tube.FK_Plate__ID) ##
        }
        elsif ( $ref_T[0] && $table[1] ) {
            ## left element point to FK (eg Run.FK_Plate__ID = Plate_ID) ##
        }
        elsif ( $ref_T[1] && $table[0] ) {
            ## right element point to FK (eg Plate_ID = Tube.FK_Plate__ID) ##
        }
        else {
            if ($debug) { $self->warning("Non-standard join statement between $table[0] and $table[1] : ($condition)") }
        }

        my $t1 = $table[0];
        my $t2 = $table[1];

        return ( $condition, $t1, $t2 );
    }

    Message("Unrecognized condition: $condition");
    return ();
}

#####################################################################################
# Returns array of tables in database (excluding quote character)
#
# Wrapper for DBI $dbh->tables method, enabling consistent output over version changes
#
# Defaults to trim quotation characters from newer output format (override using -trim_quotes=>0)
# Defaults to exclude database qualification unless schema is defined as '%' (override using -qualified=>1)
#
#
# Return: adjusted table list as array
#################
sub DB_tables {
#################
    my %args = &filter_input( \@_, -args => 'dbc,catalog,schema,table,type', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    ## no parameters supplied in deprecated version - should retrieve current table list only in this case... ##
    my $catalog = $args{-catalog} || '';    ## see DBI manual for instructions
    my $schema  = $args{-schema}  || '';
    my $table = defined $args{-table} ? $args{-table} : '%';    ### use % to retrieve all databases
    my $type = $args{-type} || '';
    ## additional parameters not included in dbh->tables() to normalize output deprecated versions (for newer output style, specify -qualified=>1, -trim_quotes=>0 ##
    my $qualified = $args{-qualified} || ( $schema eq '%' );    ## qualify table if applicable ##
    my $trim_quotes = defined $args{-trim_quotes} ? $args{-trim_quotes} : 1;

    my @tables;
    if ( ref $self eq "DBI::db" ) {
        ### if used as a $dbc method instead of $self method
        @tables = $self->tables;
    }
    elsif ( $self->dbc() ) {
        @tables = $self->dbh()->tables( $catalog, $schema, $table, $type );
    }
    else {
        Message("self undefined");
        print HTML_Dump ref $self, $self->dbc();
        Call_Stack();
    }

    ###  convert new format ("`database`.`table`" => "database" or "database.table") ##
    if ($trim_quotes) {
        map { ~s/[\'\"\`]//g } @tables;
    }

    if ( !$qualified && $tables[0] =~ /\./ ) {
        ## new DBIO output : trim database qualification if applicable ##
        map { ~s/(.*)\.(.*)/$2/ } @tables;
    }
    elsif ( $qualified && ( $tables[0] !~ /\./ ) ) {
        map { ~s /(.*)/$self->{dbase}.$1/ } @tables;
    }

    return @tables;
}

#########################
#
# Extract list of tables in database which include given fields
#
###############
sub get_tables {
###############
    my %args = &filter_input( \@_, -args => 'dbc,fields', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    my $fields = $args{-fields};

    my %Table;
    foreach my $field (@$fields) {
        my ( $ref_table, $ref_field ) = $self->foreign_key_check($field);
        if ($ref_table) {
            next;
        }
        map { $Table{$_}++ } $self->Table_find( 'DBField,DBTable', 'DBTable_Name', "where FK_DBTable__ID=DBTable_ID AND Field_Name = '$field'" );
    }

    my @tables = keys %Table;
    $self->message( "Use: @tables", -priority => 2 );
    return join ',', @tables;
}

#
# Formats the field SELECT query by dynamically determining prompts if available via DBField
#
# Optional -format parameter allows retrieval of prompt ONLY.
#
# Return: '$field AS $prompt'
##############################
sub format_field_select {
##############################
    my %args = filter_input( \@_, -args => 'dbc,field', -self => 'SDB::DBIO' );
    my $self   = $args{-self} || $args{-dbc};
    my $table  = $args{-table};
    my $field  = $args{-field};
    my $format = $args{'-format'};              ## flag to indicate returned value should be propmt or full select statement (eg 'A AS B')
    my $prompt = $args{-prompt};
    my $tables = $args{-tables};

    if ( $field =~ /^(\w*?)(\.?)(\w+)$/ ) {
        ## simple field ##
        $table = $1;
        $field = $3;

        my $table_list;
        if ( !$table ) {
            ## unqualified field ##
            $tables = join ',', $self->get_Table_list($tables);    ## retrieve list of tables as comma-delimited list from TableName (which may include left joins etc) ##
            $table_list = Cast_List( -list => $tables, -to => 'string', -autoquote => 1 );
        }
        else {
            $table_list = "'$table'";
        }

        ## get prompt from DBfield table ##
        my @info = $self->Table_find( 'DBField', 'Field_Table,Prompt', "WHERE Field_Table IN ($table_list) AND Field_Name = '$field'" );
        if ( int(@info) > 1 ) { $self->warning("$field is Ambiguous") }
        my @tp = split ',', $info[0];
        ## don't use prompt if the prompt itself is not unique since it will confuse query if two same prompts are used in a query
        my ($prompt_count) = $self->Table_find( 'DBField', 'count(*)', "WHERE Prompt = '$tp[1]'" );
        if ( $prompt_count == 1 ) {
            $table  ||= $tp[0];
            $prompt ||= $tp[1];
        }
    }
    elsif ( $field =~ /^(.+) AS (\w+)$/i ) {
        ## prompt format already supplied ##
        $field  = $1;
        $prompt = $2;
    }
    else {
        ## unqualified meta field (eg LEFT(Name,5)) ##
    }

    if ($table) { $table .= '.' }

    if ( $format =~ /prompt/i ) { return $prompt }
    $prompt =~ s/\s/\_/g;      ## replace spaces for SQL commands ##
    $prompt =~ s/[\(\)]//g;    ## replace brackets for SQL commands ##

    if   ($prompt) { return "$table$field AS $prompt" }
    else           { return "$table$field" }
}

##############################################
# Convert field names if alias is defined
#
# RETURN: array of new field names
###################
sub convert_data {
###################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $field_ref  = $args{-fields};
    my $value_ref  = $args{ -values };
    my $table      = $args{-table};        ## domain of fields to choose from
    my $autoquote  = $args{-autoquote};
    my $datefields = $args{-datefields};

    ### Error Checking ###
    my %Input;
    my $format;
    if    ( ref($value_ref) =~ /array/i ) { $Input{1} = $value_ref;    $format = 'array'; }
    elsif ( ref($value_ref) =~ /hash/i )  { %Input    = %{$value_ref}; $format = 'hash'; }
    else                                  { $self->error("convert_data Values in invalid format"); return; }

    #    unless (keys %{$self->{alias}}) { return ($field_ref,$value_ref) } ## if no aliases are defined

    my @actual_fields = @$field_ref;    ## assume the same if object not supplied
    @actual_fields = $self->get_field_list( -table => $table, -include => 'hidden', -qualify => 1 ) if $table;

    my @fields;
    my @values;
    foreach my $index ( 1 .. int(@$field_ref) ) {
        my $field = $$field_ref[ $index - 1 ];
        my $alias = $self->alias($field);
        if ($alias) { $self->message( "Found Alias $alias for $field\n", -priority => 2 ); }

        if ( $alias && grep /^$alias$/, @actual_fields ) {
            push( @fields, $alias );
        }
        elsif ( $field && grep /^$field$/, @actual_fields ) {
            push( @fields, $field );
        }
        elsif ( $field && grep /^$table\ .$field$/, @actual_fields ) {
            push( @fields, "$table.$field" );
        }
        else {next}

        foreach my $record ( keys %Input ) {
            my $value = $Input{$record}[ $index - 1 ];
            if ( $autoquote && ( $value !~ /^NULL$/i ) && ( $value !~ /^\'.*\'$/ ) ) {
                if ($value) {
                    $value = $self->dbh()->quote($value);
                }
                else {
                    if ( defined($value) ) {
                        $value = "'$value'";
                    }
                    else {
                        $value = "NULL";
                    }
                }
            }

            my ( $currtable, $currfield ) = $self->resolve_field($field);

            if ( $datefields && grep /^$currfield$/, @$datefields ) {
                $value = convert_date( $value, 'SQL' );
            }
            $Input{$record}[ $index - 1 ] = $value;
        }
    }

    if ( $format eq 'array' ) {
        @values    = @{ $Input{1} };
        $value_ref = \@values;
    }
    else {
        $value_ref = \%Input;
    }
    return ( \@fields, $value_ref );
}

#
# Define or retrieve an alias for a field name..
#
#
############
sub alias {
############
    my $self  = shift;
    my $field = shift;
    my $alias = shift;

    if ($alias) {    ## reset if given..
        $self->{alias}->{$field} = $alias;
    }
    return $self->{alias}->{$field};
}

#### methods below to be tidied up a bit... ####

############################################################
# - Converts a hash from the format: $data{Library_Name} = ('CNOO1') to $data{tables}->{Library}->{1}->{Library_Name} = 'CN001'.
# - It automatically figures out which tables the field belongs to based on the DB_Form table.
# - Also allows user to specify alias for field name in the format of $alias{Lbl} = 'Label'
# RETURN: The converted hash
############################################################
sub convert_hash {
###################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table       = $args{-table};      # The parent table [String]
    my $data_ref    = $args{-data};       # Reference to the data hash [HashRef]
    my $include_ref = $args{-include};    # A list of tables to be included [ArrayRef]
    my $exclude_ref = $args{-exclude};    # A list of tables to be excluded [HashRef]

    my %data = %{$data_ref};
    my %ret;
    my $record_count = 0;

    # Get the total record count
    foreach my $key ( keys %data ) {
        my $count = @{ $data{$key} };
        if ( $count > $record_count ) { $record_count = $count }
    }

    # Get the list of all tables that is in the branch
    my %tables;
    $tables{$table}->{parent_field} = '';
    $tables{$table}->{parent_value} = '';
    my %index;
    $index{$table} = 1;
    my ( $tables_ref, $index_ref ) = $self->_get_child_tables( -dbc => $self, -table => $table, -children => \%tables, -index => \%index, -include => $include_ref, -exclude => $exclude_ref );
    %tables = %{$tables_ref};
    %index  = %{$index_ref};

    # Get the fields of the child tables
    my %all_fields;

    #my %all_field_ids;

    my $tables_list = join( "','", map {$_} keys %tables );
    my %fields = $self->Table_retrieve( 'DBTable,DBField', [ 'DBField_ID', 'DBTable_Name', 'Field_Name' ], "where DBTable_ID=FK_DBTable__ID and DBTable_Name in ('$tables_list')" );
    my $i = 0;
    while ( defined $fields{DBField_ID}[$i] ) {

        #my $id = $fields{DBField_ID}[$i];
        my $t = $fields{DBTable_Name}[$i];
        my $f = $fields{Field_Name}[$i];
        $all_fields{$t}->{$f} = 1;

        unless ( grep /\b$f\b/, keys %data ) {
            if ( ( my $ref_table, my $ref_field ) = $self->foreign_key_check($f) ) {
                for ( my $index = 1; $index <= $record_count; $index++ ) {
                    $ret{tables}->{$t}->{$index}->{$f} = "<$ref_table.$ref_field>";
                }
            }
        }
        $i++;
    }

    # Convert the data
    foreach my $field ( keys %data ) {

        # Figure out which table(s) the current field belongs to
        foreach my $t ( keys %all_fields ) {
            my $resolved_field = $field;

            # First check to see if the field name passed in is an alias.
            if ( $self->{alias} ) {
                my %alias = %{ $self->{alias} };
                if ( exists $alias{$field} ) {
                    my $target = $alias{$field};
                    if ( exists $all_fields{$t}->{$target} ) { $resolved_field = $target }

                    #my @field_ids = @{$alias{$field}};
                    #foreach my $field_id (@field_ids) {
                    #if (exists $all_field_ids{$field_id}->{table} && ($all_field_ids{$field_id}->{table} eq $t) && exists $all_field_ids{$field_id}->{field}) {
                    #$resolved_field = $all_field_ids{$field_id}->{field};
                    #last;
                    #}
                    #}
                }
            }

            my $found = 0;
            if ( exists $all_fields{$t}->{$resolved_field} ) {    # Make sure the field belongs to the table
                                                                  #my $prev_value = '';
                for ( my $i = 0; $i < $record_count; $i++ ) {
                    my $pf = $tables{$t}->{parent_field};
                    my $pv = $tables{$t}->{parent_value};

                    #print "Specified=" . @{$data{$pf}}->[$i] . ";Expected=" . $tables{$t}->{parent_value} . "\n";
                    if ( $pf && $pv && ( $data{$pf}->[$i] ne $tables{$t}->{parent_value} ) ) {next}

                    if ( defined $data{$field}->[$i] && $data{$field}->[$i] ne '' ) {
                        my $value = $data{$field}->[$i];
                        $ret{tables}->{$t}->{ $i + 1 }->{$resolved_field} = $value;

                        #$prev_value = $value;
                        $found = 1;
                    }

                    #else {
                    #$ret{tables}->{$t}->{$i + 1}->{$resolved_field} = $prev_value;
                    #$found = 1;
                    #}

                }

                if ($found) {
                    $ret{index}->{ $index{$t} } = $t;
                }
            }
        }
    }

    return \%ret;
}

############################################################
# -Converts arrays of fields and values to $data{tables}->{Library}->{1}->{Library_Name} = 'CN001'.
# RETURN: The converted hash
############################################################
sub convert_arrays {
#####################
    my $self = shift;
    my %args = @_;

    my $table      = $args{-table};        # Table that contains the fields [String]
    my $fields_ref = $args{-fields};       # A list of fields to be used [ArrayRef]
    my $values_ref = $args{ -values };     # A list of values to be used [ArrayRef]
    my $index      = $args{ -index };      # Record index
    my $append_to  = $args{-append_to};    # Reference to an existing hash to append more data to [HashRef]

    my %data;
    if ( defined $append_to ) { %data = %{$append_to} }

    # Figure out the index if not provided
    unless ($index) {
        if (%data) {
            $index = () = keys %{ $data{tables}->{$table} };
            $index += 1;
        }
        else {
            $index = 1;
        }
    }

    my $array_index = 0;
    foreach my $field ( @{$fields_ref} ) {
        $data{tables}->{$table}->{$index}->{$field} = $values_ref->[$array_index];
        $array_index++;
    }

    # See if there are FK fields that are not specified (because they will be pointing to new primary IDs and don't know what they will be at this point yet)
    my %all_fields = $self->Table_retrieve( 'DBTable,DBField', [ 'DBField_ID', 'DBTable_Name', 'Field_Name' ], "where DBTable_ID=FK_DBTable__ID and DBTable_Name = '$table'" );
    my $i = 0;

    #print Dumper %all_fields;
    while ( defined $all_fields{DBField_ID}[$i] ) {
        my $f = $all_fields{Field_Name}[$i];
        unless ( grep /\b$f\b/, @{$fields_ref} ) {
            my ( $ref_table, $ref_field ) = $self->foreign_key_check($f);
            if ( ( my $ref_table, my $ref_field ) = $self->foreign_key_check($f) ) {

                #	 if (defined $append_to and !exists $data{tables}{$ref_table}) {$i++; next;}   # If we are appending to existing data and ref table is not one of the previous tables then do NOT try to reference it
                #	 elsif ($ref_table eq $table) {$i++; next;}  # Do not self reference
                #	 $data{tables}->{$table}->{$index}->{$f} = "<$ref_table.$ref_field>";
                if ( defined $append_to and exists $data{tables}{$ref_table} ) {
                    $data{tables}->{$table}->{$index}->{$f} = "<$ref_table.$ref_field>";
                }
            }
        }

        $i++;
    }

    if ( $index == 1 ) {
        my $max_table_index = keys %{ $data{index} };
        $data{index}->{ $max_table_index + 1 } = $table;
    }

    return \%data;
}

##############################################################
# Resolve the table and field name of a fully qualified field
###############################################################
sub resolve_field {
    my $self  = shift;
    my $field = shift;

    my $rtable;
    my $rfield;

    if ( $field =~ /(\w+)\.(\w+)/ ) {
        $rtable = $1;
        $rfield = $2;
    }
    else {
        $rfield = $field;
    }

    return ( $rtable, $rfield );
}

#####################################
# Acquire locks on tables
# Returns the result from SQL.
#
# <snip>
# $Conn->lock_tables(-read=>['DBTable','DBField'],-write=>['Plate','Plate_Set']);
#
# OR
#
# $Conn->lock_tables(-read=>'DBTable,DBField',-write=>'Plate,Plate_Set');
#
# </snip>
#####################################
sub lock_tables {
    my %args = &filter_input( \@_, -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self  = $args{-self} || $args{-dbc};
    my $write = $args{ -write };
    my $read  = $args{ -read };
    my $debug = $args{-debug};

    my $sql        = "LOCK TABLES ";
    my @lock_types = qw(READ WRITE);
    my @locks;
    foreach my $type ( 'READ', 'WRITE' ) {
        my $key = lc($type);
        my @tables = Cast_List( -list => $args{"-$key"}, -to => 'array' );
        foreach my $table (@tables) {
            push @locks, "$table $type";
        }
    }
    $sql .= join ',', @locks;

    my ( $arg1, $arg2, $arg3 ) = $self->execute_command( -command => $sql );
    $self->execute_command('FLUSH TABLES WITH READ LOCK');
    if ($debug) {
        $self->message("$sql");
    }

    return $arg3;
}

######################################
# Unlock tables
# Returns the result from SQL.
######################################
sub unlock_tables {
    my $self = shift;

    my ( $arg1, $arg2, $arg3 ) = $self->execute_command( -command => "UNLOCK TABLES" );

    return $arg3;
}

#########################################################
# Get all the sub types at a particular hierachy level
# Returns an array of sub types
#
# <snip>
# $dbc->get_subtypes(-table=>'Sample',-level=>1);  # Retrieve all subtypes of Sample of level 1(i.e. 'Clone','Extraction')
# $dbc->get_subtypes(-table=>'Sample',-level=>2);  # Retrieve all subtypes of Sample of level 2(i.e. 'DNA','RNA','Protein')
# $dbc->get_subtypes(-table=>'Sample',-level=>1);  # Retrieve all subtypes of Extraction_Sample of level 1(i.e. 'DNA','RNA','Protein')
#
# </snip>
#########################################################
sub get_subtypes {
    my $self = shift;
    my %args = @_;

    my $level      = $args{-level} || 1;          # The level to be retrieved from
    my $table      = $args{-table};               # The table to get the subtypes
    my $curr_level = $args{-curr_level} || 1;     # The current level we are in the hierachy
    my $suffix     = $args{-suffix} || $table;    # The suffix

    my @ret;

    # First make sure the table we are looking for actually exists in the database

    if ( $self->Table_retrieve( -table => 'DBTable', -fields => ['COUNT(*)'], -condition => "WHERE DBTable_Name = '$table'", -format => 'S' ) ) {
        my @types = &get_enum_list( $self, $table, "${table}_Type" );    # Get all the types
        if (@types) {
            if ( $level == $curr_level ) {                               # OK - the current level matches the specified level
                @ret = @types;
            }
            else {
                foreach my $type (@types) {                              # Recurisively get subtypes
                    push( @ret, $self->get_subtypes( -level => $level, -table => "${type}_$suffix", -curr_level => $curr_level + 1 ) );
                }
            }
        }
    }

    return @ret;
}

#################
# Perform validation checks on new or edited records
#
# RETURN: errors encountered (0 = success)
#################
sub _update_errors {
#################
    #
    #
    # This routine does a validation check before updating a record.
    #
    #  It checks for Mandatory, Unqiue fields, and ensures pointers to foreign
    #  keys are valid.
    #
    #
    my $self = shift;
    my %args = @_;

    my $table            = $args{-table};                 # table to check
    my $fields_to_update = $args{-fields};                # updated fields
    my $entry_values     = $args{ -values };              # updated field values
    my $update           = $args{-type};                  # To discern between append and update
    my $condition        = $args{-condition};             #
    my $debug            = $args{-debug} || $self->config('test_mode');
    my $user_id          = $self->get_local('user_id');

### Error Checking ###
    my %Input;
    if    ( ref($entry_values) =~ /array/i ) { $Input{1} = $entry_values; }
    elsif ( ref($entry_values) =~ /hash/i )  { %Input    = %{$entry_values} }
    else                                     { $self->error("_update_errors Values in invalid format"); return; }

    my $records = int( keys %Input );                     ## number of records to check at once (normally = 1)

    unless (%Field_Info) { $self->initialize_field_info($table); }

    my $primary = $Primary_fields{$table};
    $primary ||= join ',', $self->get_field_info( $table, undef, 'Primary' );

    #    $fields_to_update =~s / //g; ## remove stray spaces in field list.
    unless ( $self->check_permissions( $user_id, $table, 'edit' ) ) {
        Message("Error: permission denied to edit $table");
        return "No permission";
    }
    my @update_fields = @$fields_to_update;

    # check for mandatory fields only if appending records
    if ( $update =~ /append/i ) {
        my @mfields;
        if ( grep /DBField/, $self->DB_tables() ) {
            @mfields = $self->Table_find_array( 'DBField,DBTable', ["Concat(DBTable_Name,'.',Field_Name)"], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table' AND Field_Options like '%Mandatory%'" );
        }
        elsif ( defined $Mandatory_fields{$table} ) {
            @mfields = map {"$table.$_"} split /,/, $Mandatory_fields{$table};
        }

###### Check mandatory fields for data ################
        foreach my $mfield (@mfields) {
            my $index = 0;
            my $found = 0;
            foreach my $field (@update_fields) {
                $field =~ s / //g;

                if ( $mfield eq $field ) {
                    foreach my $record ( 1 .. $records ) {
                        if ( ( $Input{$record}[$index] =~ /\w/ ) && !( $Input{$record}[$index] eq 'NULL' ) ) {
                            $found++;
                        }
                    }
                    last;
                }
                $index++;
            }
            if ( ( $found < $records ) && $mfield ) {
                $self->error("Error: Mandatory field $mfield is missing in @update_fields ($found / $records)!");
                return "Mandatory field $mfield missing in @update_fields ($found / $records) (require @mfields)";
            }
        }
    }
    elsif ( !$condition ) {
        RGTools::RGIO::Message("Not updating.  Some Condition must be set.");
        return "No condition set for update";
    }

    my @ffields = $self->get_field_info( $table, &foreign_key_pattern() );
    ###### Check foreign fields for valid entries ############
    foreach my $ffield (@ffields) {
        my $ftn;
        my $fcn;    ## foreign table name, column name
        if ( ( $ftn, $fcn ) = $self->foreign_key_check($ffield) ) { }
        ########### Custom Insertion (specify other valid formats) ###########

        elsif ( $ffield =~ /([\w_]+)[:]([\w_]+)/ ) {
            $ftn = $1;
            $fcn = $2;
        }
        elsif ( $ffield =~ /([\w]+)_ID/ ) {
            $ftn = $1;
            $fcn = $ffield;
        }
        elsif ( $ffield =~ /([\w]+)_Name/ ) {
            $ftn = $1;
            $fcn = $ffield;
        }

        ########### End Custom Insertion (specify other valid formats) ###########
        else { $ftn = $ffield; $fcn = $ffield; }

        my $index = 0;
        my $found = 0;
        foreach my $field (@update_fields) {
            if ( $ffield eq $field ) {
                foreach my $record ( 1 .. $records ) {
                    if ( ( $Input{$record}[$index] =~ /\S/ ) && !( $Input{$record}[$index] eq 'NULL' ) && !( $Input{$record}[$index] =~ /""/ ) && ( defined $Input{$record}[$index] ) ) {
                        my $querystring = "SELECT count(*) from $ftn where $fcn like $Input{$record}[$index]";

                        ( my $finds ) = $self->Table_find( $ftn, 'count(*)', "where $fcn like $Input{$record}[$index]" );

                        if ( ( $field =~ /^FK/ ) && ( $Input{$record}[$index] == 0 ) ) {
                            RGTools::RGIO::Test_Message( "Zero value for $field noted", $debug );
                            next;
                        }
                        elsif ( $finds < 1 ) {
                            RGTools::RGIO::Message("FK Error: $field = $Input{$record}[$index] ? in $table ($finds) \n");
                            return "FK Error";
                        }
                    }
                }
            }
            $index++;
        }
    }

    RGTools::RGIO::Test_Message( "\nChecking Unique fields...", $debug );
    my @ufields = $self->get_field_info( $table, undef, 'uni' );
###### Check Unique fields for valid entries ############

    foreach my $ufield (@ufields) {
        my $index = 0;
        my $found = 0;
        foreach my $field (@update_fields) {
            if ( ( $ufield eq $field ) ) {
                foreach my $record ( 1 .. $records ) {
                    my @found = $self->Table_find( $table, $primary, "where $field like $Input{$record}[$index]" );

                    if ( $condition =~ /$primary\s?=\s?$found[0]/ ) {
                    }
                    #### this is ok if we are simply changing the same record as condition specified
                    elsif ( $#found > 0 ) {
                        RGTools::RGIO::Message("Check Error ($$found): $field = $Input{$record}[$index] NOT unique !");
                        return "Unique field error";
                    }
                }
            }
            $index++;
        }
    }

    ########## Check Date fields... ##################
    @update_fields = @$fields_to_update;

    my $index = 0;
    foreach my $field (@update_fields) {
        if ( $Field_Info{$table}{$field}{Type} =~ /date/i ) {
            foreach my $record ( 1 .. $records ) {
                if ( $Input{$record}[$index] =~ /\d\d\d\d[-]\d\d[-]\d\d/ ) {
                    next;
                }
                elsif ( $Input{$record}[$index] =~ /\d/ ) {
                    Message( "Error in Date entry for $field: $Input{$record}[$index]", "should be either YYYY-MM-DD or Mon-DD-YYYY" );
                    return "Date Error";
                }
                else {    ### blank...
                    next;
                }
            }
        }
        $index++;
    }
    return;
}

############################################################
# Recursively gets the child tables
# RETURN: An hashref to the list of child tables along with the branching conditions
############################################################
sub _get_child_tables {
    my $self = shift;
    my %args = @_;

    my $table        = $args{-table};       # Primary table [String]
    my $children_ref = $args{-children};    # Reference to a hash that contains the child tables [HashRef]
    my $index_ref    = $args{ -index };     # Reference to an index hash of child tables [HashRef]
    my $include_ref  = $args{-include};     # A list of tables to be included [ArrayRef]
    my $exclude_ref  = $args{-exclude};     # A list of tables to be excluded [ArrayRef]

    my @include;
    my @exclude;

    if ($include_ref) {
        @include = @{$include_ref};
    }
    elsif ($exclude_ref) {
        @exclude = @{$exclude_ref};
    }

    my %children;
    if ($children_ref) { %children = %{$children_ref} }

    my %index;
    if ($index_ref) { %index = %{$index_ref} }

    if (@include) {    # If include list is specified, then do not need to query the DB_Form table.  Just take these tables in order
        foreach my $t (@include) {
            $children{$t}->{parent_field} = '';
            $children{$t}->{parent_value} = '';
            my $max_table_index = keys %index;
            $index{$t} = $max_table_index + 1;
        }
    }
    else {
        my %found = $self->Table_retrieve( 'DB_Form As P, DB_Form As C', [ 'C.Form_Table', 'C.Parent_Field', 'C.Parent_Value' ], "where C.FKParent_DB_Form__ID = P.DB_Form_ID and P.Form_Table = '$table'" );

        my $i = 0;
        while ( defined $found{Form_Table}[$i] ) {
            my $t  = $found{Form_Table}[$i];
            my $pf = $found{Parent_Field}[$i];
            my $pv = $found{Parent_Value}[$i];

            ## Do various checks to make sure we want to include this table
            #if (@include && !(grep /\b$t\b/, @include)) {#
            #$i++;
            #next;
            #}
            #elsif (@exclude && (grep /\b$t\b/, @exclude)) {#
            if ( @exclude && ( grep /\b$t\b/, @exclude ) ) {
                $i++;
                next;
            }

            $children{$t}->{parent_field} = $pf;
            $children{$t}->{parent_value} = $pv;

            my $max_table_index = keys %index;
            $index{$t} = $max_table_index + 1;

            my ( $children_ref, $index_ref ) = $self->_get_child_tables( -dbc => $self, -table => $t, -children => \%children, -index => \%index );
            %children = %{$children_ref};
            %index    = %{$index_ref};

            $i++;
        }
    }

    return ( \%children, \%index );
}

###########################
# Convert records hashes
###########################
sub _convert_records {
    my $self = shift;
    my %args = @_;

    my $records = $args{-records};
    my %ret;

    foreach my $key (%$records) {
        if ( $key =~ /(\w+)\.(\w+)/ ) {    # Converting from: $records->{'Library.Library_Name'} = ['CN001','CN002']
            my $table = $1;
            my $field = $2;
            @{ $ret{$table}->{$field} } = @{ $records->{$key} };
        }
        else {                             # Converting from: $records->{Library}->{Library_Name} = ['CN001','CN002']
            foreach my $field ( %{ $records->{$key} } ) {
                @{ $ret{"$key.$field"} } = @{ $records->{$key}->{$field} };
            }
        }
    }
}

############################
# Return auto-quoted value
#
# RETURN: value sent with quotes
##############
sub _autoquote {
##############
    my $value_ref = shift;

    my @values = @$value_ref;
    my $i      = 0;
    foreach my $value (@values) {
        $values[$i] = qq{'$values[$i]'};
        $i++;
    }
    return \@values;
}

##########################
# GSDB Modules
##########################

###############################################################################
#
# In newer versions of DBI method, this returns 'quoted' array of table names
# (Use DB_tables instead if wishing to exclude quote characters).
#
####################
sub tables {
####################
    #
    # Retrieves the database tables and strips unwanted quotes from table names
    #
    my %args = &filter_input( \@_, -args => 'dbc,', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my @tables = $self->DB_tables();
    my @tabs   = ();
    foreach (@tables) {
        $_ =~ s/\`|\'|\"//g;
        push( @tabs, $_ );
    }
    return @tabs;
}

####################
sub list_tables {
####################
    #
    # show tables contained in database (html table generated)
    #  describing field information for each field.
    # (optionally may specify single table to get info for)
    #
    my %args = &filter_input( \@_, -args => 'dbc,defined_table,view', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $defined_table = $args{-defined_table};
    my $view          = $args{-view};            ## may be 'simple', or 'detailed'.. otherwise defaults to show all standard 'Desc Table' fields.

    my @tables = $self->DB_tables();
    foreach (@tables) {
        $_ =~ s/\`|\'|\"//g;
    }
    my $querystring;

    unless ( %Field_Info && $Field_Info{$defined_table} ) { $self->initialize_field_info($defined_table) }    ### initialize Hash with various field information (global)

    #    unless ($defined_table) {  ### just display database info..
    print "<Font size=-1><UL>"
        . "<LI><B>Bold fields are specified as Mandatory by code</B><BR>"
        . "<LI>Foreign keys are formatted like 'FK(optional_description)_Table__ID' and are hyperlinked to associated tables"
        . "<LI>Examples normally represent last entry in table"
        . "</UL></Font>";

    if ($defined_table) { @tables = ($defined_table); }                                                       ### if single table specified...

    my @exclusions = ( 'FK', 'TableName', 'NULL_ok' );
    my @columns;
    map {
        my $key = $_;
        $key =~ s/(.*) as (.*)/$2/i;
        unless ( grep /^$key$/, @exclusions ) { push( @columns, $key ) }
    } @{ $Field_Info{Fields} };

    foreach my $table (@tables) {
        unless ( $table && defined $Field_Info{$table} ) {next}
        my @fields = @{ $Field_Info{$table}{Fields} };
        if ( $view =~ /simple/i ) { @fields = ('Field') }    ## Enable 'simple' view showing only Field names
        my ($count) = $self->Table_find( $table, 'count(*)' );
        my ($primary) = $self->get_field_info( $table, undef, 'primary' );
        my $order;
        if ($primary) { $order = "Order by $primary DESC"; }    ### grab most recent entry for example
        my %Example = $self->Table_retrieve( $table, \@fields, "$order Limit 1" );

        my $Table = HTML_Table->new();
        $Table->Set_Title("$table ($count entries)");
        $Table->Set_Width('100%');
        $Table->Set_Class('small');

        #	$Table->Set_Line_Colour('white');
        $Table->Set_Column_Widths( [ 200, 100, 30, 30, 100, 150 ] );
        $Table->Set_Border(1);
        $Table->Set_Headers( [ @columns, 'Example' ] );

        my @mfields;
        if ( grep /DBField/, $self->DB_tables() ) {
            @mfields = $self->Table_find( 'DBField,DBTable', 'Field_Name', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table' AND Field_Options LIKE '%Mandatory%'" );
        }
        elsif ( defined $Mandatory_fields{$table} ) {
            @mfields = split /,/, $Mandatory_fields{$table};
        }

        foreach my $field (@fields) {
            my @row;
            foreach my $key (@columns) {
                my $value = $Field_Info{$table}{$field}{$key} || '-';

                #		if (&list_contains($Mandatory_fields{$table},$field)) {$value = "<B>$value</B>";}
                if ( grep /^$field$/, @mfields ) { $value = "<B>$value</B>"; }

                if ( $value =~ /(enum|set)\((.*)\)/ ) {
                    $value = "$1:<BR>$2";
                    $value =~ s /,/<BR>/g;
                }
                if ( ( $key eq 'Field' ) && ( $value =~ /FK[a-zA-Z0-9]*_(.*)__(.*)/ ) ) {
                    my $reftable = $1;
                    if ($defined_table) {    ## link to other tables if only 1
                        push( @row, &Link_To( $self->homelink(), $value, "&TableHome=$reftable", 'red' ) );
                    }
                    else {
                        push( @row, &Link_To( "#$1", $value, '', 'red' ) );
                    }
                    my @keys = keys %{ $Field_Info{$table}{$field} };
                }
                else { push( @row, $value ); }

            }
            my $example = $Example{$field}[0];
            if ( $Field_Info{$table}{$field}{Type} =~ /blob/i ) {
                $example = "(binary)";
            }
            elsif ( $field =~ /Histogram/ ) {
                $example = "(binary)";
            }
            else {
                if ( length($example) > 50 ) { $example = substr( $example, 0, 50 ) . "..."; }
            }
            push( @row, "<Font color=blue><B>$example</B></Font>" );

            $Table->Set_Row( \@row );
        }
        print "<A Name=$table>";    ## provide local link in case many tables listed...
        print $Table->Printout( -filename => "$URL_temp_dir/$table" . "_field_list.html", -header => $html_header );
        $Table->Printout();
    }
    return;
}

# retrieve list of enumerated values for a given field;
#  (also works for 'set' values)
#  (it retrieves this from field definition, removing quotes from list)
#
# <snip>
# Example:
#       my @enum_list = $dbc->get_enum_list($table,$rfield);
#
#       my @enum_list = get_enum_list($dbc,$table,$rfield);
# </snip>
# Returns: array of enumerated values
##########################
sub get_enum_list {
##########################
    my %args = &filter_input( \@_, -args => 'dbc,table,field,mask', -mandatory => 'dbc|self,table,field', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table    = $args{-table};    ## table
    my $field    = $args{-field};    ## field of type enum or set
    my $mask_ref = $args{-mask};     ## An array of masks for filtering the list
    my $sort     = $args{ -sort };

    my $sth = $self->query( -dbc => $self, -query => "SHOW columns from $table LIKE '$field'", -finish => 0 );
    my @fieldinfo = $sth->fetchrow_array;

    my $type       = $fieldinfo[1];
    my $field_list = "";

    if ( $type =~ /enum\((.*)\)/i ) {
        $field_list = $1;
        ####### special handling of quotes around text...

        if ( $field_list =~ /^\'(.*)\'$/ ) { $field_list = $1; }
        $field_list =~ s/\',\'/,/g;
        $field_list =~ s/\'\'/\'/g;
        $type = 'enum';
    }
    elsif ( $type =~ /set\((.*)\)/i ) {
        $field_list = $1;
        ####### special handling of quotes around text...

        if ( $field_list =~ /^\'(.*)\'$/ ) { $field_list = $1; }
        $field_list =~ s/\',\'/,/g;
        $field_list =~ s/\'\'/\'/g;
        $type = 'set';
    }
    my $null_ok = $fieldinfo[2];
    my @enum_list;
    if ($mask_ref) {
        ### Perl quirk... if string ends with 'something,' split does not return last empty element,
        ###               hence -1 has to be passed
        foreach my $item ( split ',', $field_list, -1 ) {
            foreach my $mask (@$mask_ref) {
                if ( $item =~ /$mask/ ) {
                    push( @enum_list, $item );
                    last;
                }
            }
        }
    }
    else {
        @enum_list = split ',', $field_list, -1;
    }
    if ($sort) { @enum_list = sort @enum_list }

    return (@enum_list);
}

########################################
# extracts Prompts
#
# (first checks for predefined prompts)
# defaults to field name if not defined.
#
#######################
sub getprompts {
#######################

    my %args = &filter_input( \@_, -args => 'dbc,table', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self   = $args{-self} || $args{-dbc};
    my $table  = $args{-table};                 # Table Name
    my $fields = $args{-fields};

    my @field_names = Cast_List( -list => $fields, -to => 'array' );

    my @prompts;

    #Retrieve prompts info from DBField.
    my $i = 0;
    my %info = $self->Table_retrieve( 'DBTable,DBField', [ 'DBField_ID', 'Prompt' ], "WHERE DBTable_ID = FK_DBTable__ID AND DBTable_Name = '$table' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed' order by Field_Order" );
    while ( defined $info{Prompt}[$i] ) {
        push( @prompts, $info{Prompt}[$i] );
        $i++;
    }

    if (@prompts) {
        @field_names = @prompts;
    }

    my $found = int(@field_names);

    if ( $found < 2 ) {
        @field_names = $self->get_fields($table);
    }

    my @formatted_field_names = @field_names;

    return @formatted_field_names;
}
################################################################################
# Table Creation / Removal
################################################################################

##################
sub Table_add {
##################
    #
    #  eg. &Table_add($dbc,$table,"$field $type $field $type ...");
    #
###################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $TableName = $args{-table};     # Table name to add
    my $vars      = $args{-fields};    # Field list to include in new Table

    my $sql = qq{create table $TableName ($vars)};
    my $sth = $self->dbh()->do($sql);
    if ( defined Get_DBI_Error() ) {
        $self->error( "Table_add Error: " . Get_DBI_Error() );
        $self->warning("MySQL statement = $sql");
    }
    else { $self->message("Created Table $TableName with variables: $vars"); }
    $sth->finish();
    return 1;
}

###################################################
sub Table_drop {
###################
    my %args = &filter_input( \@_, -args => 'dbc,table', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $TableName = $args{-table};    # Table name to drop

    my $sth = $self->dbh()->prepare("drop table $TableName");
    $sth->execute();
    if ( defined $sth->err() ) {
        $self->error( "Table_drop Error: " . Get_DBI_Error() );
        Message("MySQL statement = drop table $TableName");
    }
    $sth->finish();
    return 1;
}
################################################################################
#  Display/Extract Table information
################################################################################

# Get fields of a particular type, can specify a table and pattern
#
# <snip>
# Example:
#    my @fields = $dbc->get_field_info($table,undef,'Primary');
# </snip>
#
# Returns: array of fields of a particular type in a given table
#  (or in all tables if 2nd parameter is omitted)
##########################
sub get_field_info {
##########################

    my %args = &filter_input( \@_, -args => 'dbc,table,pattern,type', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self           = $args{-self} || $args{-dbc};
    my $target_table   = $args{-table};                  ## specify a particular table (optional)
    my $like           = $args{-pattern} || '%';         ## file name pattern condition
    my $type           = $args{-type} || 0;              ## type specification (Null, Primary, Multiple (key), Unique)
    my $debug          = $args{-debug};
    my $force          = $args{-force};                  ## regenerate (ignore existing %Field_Info if it exists)
    my $source         = $args{-source} || 'DBField';    ## allow for reloading from standard SQL
    my $search_for_new = $args{-search_for_new};
    my $attribute      = $args{-attribute};
    my $field          = $args{-field};

    my @tables;
    if ($target_table) {

        #push(@tables,$target_table);
        @tables = Cast_List( -list => $target_table, -to => 'Array' );
    }
    else {
        @tables = $self->DB_tables();
        foreach (@tables) {
            $_ =~ s/\`|\'|\"//g;
        }
    }

    if ( ( grep /^DBField$/, $self->DB_tables ) && ( !$search_for_new ) ) {
        ## This block should always be run now ##
        my $condition = "Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'";
        if (@tables) {
            my $table_list = join "','", @tables;
            $condition .= " AND DBTable_Name IN ('$table_list')";
            $attribute ||= 'Field_Name';
        }
        else {
            $attribute ||= "Concat(DBTable_Name,'.',Field_Name)";
        }
        if ($like) { $condition .= " AND Field_Name like '$like'"; }
        if    ( $type =~ /date|time|int|float|decimal/i ) { $condition .= " AND Field_Type like '$type%'"; }
        if    ( $type =~ /pri|uni/i )                     { $type = substr($type,0,3); $condition .= " AND Field_Index like '%$type%'"; }
        if    ( $type =~ /not null/i )                    { $condition .= " AND Null_OK like 'NO'"; }
        elsif ( $type =~ /null/i )                        { $condition .= " AND Null_OK like 'YES'"; }
        if    ( $type =~ /\bind/i )                       { $condition .= " AND Length(Field_Index) > 1"; }
        if    ( $type =~ /\bfk/i )                        { $condition .= " AND Length(Foreign_Key) > 1"; }
        if ($field) { $condition .= " AND Field_Name LIKE '$field'" }

        ## <CONSTRUCTION> - add more options and allow | or & in type declaration ...

        my @fields = $self->Table_find_array( 'DBField,DBTable', [$attribute], "WHERE FK_DBTable__ID=DBTable_ID AND $condition", -debug => $debug );
        return @fields;
    }

    # Fields from Info are: ('Field','Type','Null','Key','Default','Extra','Privileges')
    #
    my %Indexes;
    %Indexes = ( Field => 0, Type => 1, Null => 2, Key => 3, Default => 4, Extra => 5, Privileges => 6, Key_Name => 2 );

    my $field_value;
    my $field_index;

    if ( $type =~ /date/i ) { $field_index = $Indexes{Type}; $field_value = 'date'; }
    if ( $type =~ /time/i ) { $field_index = $Indexes{Type}; $field_value = 'time'; }

    if    ( $type =~ /^null/i )    { $field_index = $Indexes{Null}; $field_value = 'YES'; }
    elsif ( $type =~ /not null/i ) { $field_index = $Indexes{Null}; $field_value = ''; }

    if ( $type =~ /pri/i ) { $field_index = $Indexes{Key}; $field_value = 'PRI'; }
    if ( $type =~ /ind/i ) { $field_index = $Indexes{Key}; $field_value = 'PRI|UNI|MUL'; }
    if ( $type =~ /uni/i ) {
        ## unique fields are handled more easily with field_management tables .. ##
        my $field_management = grep /DBField/, $self->DB_tables();
        if ($field_management) {
            $self->initialize_field_info( $target_table, -force => $force, -source => $source );
            my @field_info = ();
            foreach my $table (@tables) {
                foreach my $field ( @{ $Field_Info{$table}{Fields} } ) {
                    if ( $Field_Info{$table}{$field}{Extra} =~ /Unique/ ) { push( @field_info, $field ) }
                }
            }
            return @field_info;
        }
        else {
            $field_index = $Indexes{Key};
            $field_value = 'PRI|UNI|MUL';    ## this is not that reliable, since some may be labelled 'MUL'
        }
    }

    my $tables = scalar(@tables);
    my @field_info;

    foreach my $this_table (@tables) {

        my $query = "SHOW columns From $this_table LIKE '$like'";
        my $sth   = $self->dbh()->prepare($query);
        $sth->execute();

        if ( defined $sth->err() ) {

            #	    Message("get_field_info Error: $query");
            #	    Message("Error: " . Get_DBI_Error());
            #	    Message(qq{MySQL statement = show columns FROM $this_table LIKE "$like"});
        }

        while ( my @fieldinfo = $sth->fetchrow_array ) {
            unless (@fieldinfo) { next; }
            if ( !$field_index || ( $fieldinfo[$field_index] =~ /$field_value/i ) ) {
                my $field;
                if ( !$target_table ) {
                    $field = "$this_table.$fieldinfo[0]";
                }
                else {
                    $field = $fieldinfo[0];
                }
                push( @field_info, $field );
            }
        }
        $sth->finish();
    }
    return @field_info;
}

##########################################################################
# Initialize global field_info - useful for quick access in other scripts
#   puts general info on tables into accessible hash (global in scope).
#
# Extract information on Database fields to enable easier information handling
# - ready access to field information - eg. Types, Prompts, References etc.
#
# Return: hash or hashref to the Field_Info
################################
sub initialize_field_info {
################################
    my %args = &filter_input( \@_, -args => 'dbc,table', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};    ## set self if dbc defined

    my $table  = $args{-table};
    my $force  = $args{-force};
    my $source = $args{-source} || 'DBField';
    my $debug  = $args{-debug};

    unless ( $self->ping ) { Message("Lost dbc"); Call_Stack(); }

    my $field_management = $self->table_loaded('DBField');
    if ( !$field_management ) { $source = 'Standard' }

    ##########################################
    ### Deprecate use of Field_Info Global ###
    ##########################################

    ## already defined (DBField)
    if ( %Field_Info && $field_management && defined $Field_Info{$table}{Fields} && !$force ) {

        # detect context this function is called
        # if list context - return the hash
        if ( wantarray() ) {
            return %Field_Info;
        }

        # if scalar, return the reference
        elsif ( defined wantarray() ) {
            return \%Field_Info;
        }

        # null context
        else {
            return undef;
        }
    }
    ## already defined (standard)
    elsif ( %Field_Info && !$field_management && defined $Field_Info{$table} && !$force ) {

        # detect context this function is called
        # if list context - return the hash
        if ( wantarray() ) {
            return %Field_Info;
        }

        # if scalar, return the reference
        elsif ( defined wantarray() ) {
            return \%Field_Info;
        }

        # null context
        else {
            return undef;
        }
    }
    #######################################################
    ### Use local attribute to cache field info instead ###
    #######################################################
    my %FI;
    if ( $self->{Field_Info} ) { %FI = %{ $self->{Field_Info} } }    ### retrieve cached field information ###

    ## Cached FI value if available ##
    if ( %FI && !$force && ( defined $FI{$table} || ( $field_management && defined $FI{$table}{Fields} ) ) ) {

        # detect context this function is called
        # if list context - return the hash
        if ( wantarray() ) {
            return %FI;
        }

        # if scalar, return the reference
        elsif ( defined wantarray() ) {
            return \%FI;
        }

        # null context
        else {
            return undef;
        }
    }

    ## gets here if undefined or forced ##
    my @keys = keys %Field_Info;

    unless ( $self->ping() ) { print "undefined Database "; Call_Stack(); }

    my @tables;
    if ( $table =~ /^(.+?) LEFT JOIN (\w+)/i ) {
        ## dynamically figure out included tables if supplied table list includes LEFT JOIN ##
        push @tables, $1;
        my $table_string = $table;

        while ( $table_string =~ s/^(.*) LEFT JOIN (\w+)/$1,$2/ ) {
            push @tables, $2;
        }
    }
    elsif ($table) {
        @tables = Cast_List( -list => $table, -to => 'array' );
    }
    else {
        @tables = $self->DB_tables();
        @DB_Tables = @tables unless (@DB_Tables);    ## set global
    }

    ## check for standard field management tables (DBField,DBTable) ##

    if ( $field_management && ( $source =~ /DBField/ ) ) {
        ## generate details for DBField, DBTable tables (first using standard 'desc' functions, then table_management fields)
        unless ( $Field_Info{DBField} ) { $self->initialize_field_info( 'DBField', -source => 'standard' ) }
        unless ( $Field_Info{DBField} ) { $self->initialize_field_info('DBField'); }

        my @showfields = (
            'DBTable_Name as TableName',
            'Field_Name as Field',
            'Field_Description as Description',
            'Field_Type as Type',
            'NULL_ok',
            'Field_Index as Index_Key',
            'Foreign_Key as FK',
            'Field_Options as Extra',
            'Field_Format as Format',
            'Field_Default as Default_Value',
            'Prompt',
            'Tracked',
            'Editable',
        );
        $Field_Info{Fields} = \@showfields;

        foreach my $table (@tables) {
            $Field_Info{$table} = {};    ### clear previous settings ##
            my %Field_settings = $self->Table_retrieve( 'DBTable,DBField', \@showfields, "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' ORDER BY Field_Order", -debug => $debug );

            my @output_fields = keys %Field_settings;
            my $index         = 0;
            while ( defined $Field_settings{TableName}[$index] ) {    ### (defined $Field_settings{Field_Table}[$index]) {

                if ( $Field_settings{Extra}[$index] =~ /Obsolete|Removed/ ) {

                    #     Message("Skip $Field_settings{TableName}[$index].$Field_settings{Field}[$index]");
                    $index++;
                    next;
                }

                my $table = $Field_settings{TableName}[$index];
                my $field = $Field_settings{Field}[$index];
                push( @{ $Field_Info{$table}{Fields} }, $field );
                foreach my $key ( keys %Field_settings ) {
                    $Field_Info{$table}{$field}{$key} = $Field_settings{$key}[$index];
                }
                $Field_Info{$table}{$field}{Key}     = $Field_settings{Index_Key}[$index];        ## cannot use Key since it is a reserved word
                $Field_Info{$table}{$field}{Null}    = $Field_settings{NULL_ok}[$index];          ## cannot use Key since it is a reserved word
                $Field_Info{$table}{$field}{Default} = $Field_settings{Default_Value}[$index];    ## cannot use Key since it is a reserved word
                $Field_Info{$table}{$field}{Extra}   = $Field_settings{Extra}[$index];

                if ( $Field_Info{$table}{$field}{Extra} =~ /mandatory/i ) {
                    push( @{ $Field_Info{$table}{Mandatory} }, $field );
                }
                if ( $Field_Info{$table}{$field}{Extra} =~ /primary/i ) {
                    $Field_Info{$table}{Primary} = $field;
                }
                $index++;
            }
        }

    }
    else {
        ## if no field management tables detected, use standard 'desc table' output ##
        my @showfields = ( 'Field', 'Type', 'Null', 'Key', 'Default', 'Extra' );
        foreach my $table (@tables) {
            my $command = "show columns FROM $table";
            my $sth     = $self->dbh()->prepare($command);
            $sth->execute();
            if ( defined $sth->err() ) {
                print "\nInitializing Error: $command\n";
                print Get_DBI_Error() . "\n";
                return 0;
            }
            else {
                while ( my @field_info = $sth->fetchrow_array ) {
                    my $field = $field_info[0];
                    push( @{ $Field_Info{$table}{Fields} }, $field );
                    foreach my $index ( 0 .. $#showfields ) {
                        $Field_Info{$table}{$field}{ $showfields[$index] } = $field_info[$index];
                    }
                }
            }
            $sth->finish();
        }
        $Field_Info{Fields} = \@showfields;
    }

    if ( int(@tables) == 1 ) {
        $self->{Field_Info}{$table} = $Field_Info{$table};
        return $Field_Info{$table};
    }    ## return hash if single table supplied ..

    # detect context this function is called
    # if list context - return the hash
    if ( wantarray() ) {
        return %Field_Info;
    }

    # if scalar, return the reference
    elsif ( defined wantarray() ) {
        return \%Field_Info;
    }

    # null context
    else {
        return undef;
    }
}

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
sub get_fields {
##########################

    my %args = &filter_input( \@_, -args => 'dbc,table,like,defined', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};    ## set self if dbc defined

    my $target_table   = $args{-table};                                                 # specify a particular table (optional)
    my $like           = $args{-like} || '%';                                           # set name query string (optional)
    my $pre_defined    = $args{ -defined };                                             # get only fields as defined (in DBField table) if possible
    my $include_hidden = defined $args{-include_hidden} ? $args{-include_hidden} : 1;
    my $simple         = $args{-simple};                                                # just return field names
    my $qualified      = $args{-qualified};                                             # just return qualified field names

    my $debug = $args{-debug};

    my @tables;

    if ($target_table) {
        @tables = Cast_List( -list => $target_table, -to => 'array' );
    }
    else {
        @tables = $self->DB_tables();
    }

    my $tables = scalar(@tables);
    my @field_info;

    my $hidden_condition;
    if ( !$include_hidden ) {
        $hidden_condition = " AND Field_Options NOT LIKE '%Hidden%'";
    }

    foreach my $this_table (@tables) {
        my $table_spec = "$this_table.";    ## <CONSTRUCTION> .. added this (ok ?)
        my @fields;

        #Retrieve fields info from DBField.
        my $i    = 0;
        my %info = $self->Table_retrieve(
            'DBTable,DBField',
            [ 'Field_Name', 'Field_Alias', 'Prompt' ],
            "WHERE DBTable_ID = FK_DBTable__ID AND DBTable_Name = '$this_table' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed' $hidden_condition order by Field_Order, Field_Name",
            -debug => $debug
        );

        while ( defined $info{Field_Name}[$i] ) {
            my $alias = $info{Field_Alias}[$i] || $info{Prompt}[$i] || $info{Field_Name}[$i];
            push( @fields, "$info{Field_Name}[$i] AS $alias" );
            $i++;
        }

        unless ($i) {next}    ## no current fields being tracked...

        unless ($target_table) { $table_spec = "$this_table."; }    ### if one specified, exclude table spec..

        ### retrieve appropriate fields...
        my @retrieved;

        #### if looking for pre_defined fields..
        if ( $pre_defined && ( defined $this_table ) && @fields ) {
            @retrieved = @fields;

            #	    return @retrieved;
        }
        else {                                                      #### get all valid fields for this table...
            my $sth = $self->query( -dbc => $self, -query => "Show columns FROM $this_table LIKE '$like'", -finish => 0 );
            while ( my @fieldinfo = $sth->fetchrow_array ) {
                my $field;
                $field = "$table_spec$fieldinfo[0]";
                push( @retrieved, $field );
            }
            $sth->finish();
        }

        unless (@fields) { push( @field_info, @retrieved ); next; }
        ### re-sort according to defined list order if it exists...
        my @requested_fields = @fields;
        foreach my $newfield (@requested_fields) {
            my $actual_field = $newfield;
            my $prompt       = $newfield;
            if ( $newfield =~ /(.+)( AS .+)/ ) { $actual_field = $1; $prompt = $2; }
            if ( ( grep /^($table_spec|)$actual_field($prompt|)$/, @retrieved ) ) {
                unless ( grep /^$table_spec$actual_field$prompt$/, @field_info ) {    ## and is not already included..
                    if ($simple) {
                        push( @field_info, "$actual_field" );
                    }
                    elsif ($qualified) {
                        push( @field_info, "$table_spec$actual_field" );

                    }
                    else {
                        push( @field_info, "$table_spec$actual_field$prompt" );
                    }
                }
            }
        }
    }
    return @field_info;
}

# Find the name and type of a field for a given table
#
# <snip>
# Example:
#    my @field_info = $dbc->get_field_types(-table=>'Employee', -field=>'Employee_Name');
# </snip>
#
# Returns: array of Field Name, Type from given table
#########################
sub get_field_type {
#########################

    my %args = &filter_input(
         \@_,
        -args      => 'dbc,table,field',
        -mandatory => 'dbc|self,field',
        -self      => 'SDB::DBIO'
    );
    my $self = $args{-self} || $args{-dbc};

    my $table = $args{-table};    ## table from which to retrieve fields from
    my $field = $args{-field};    ## (optional) field name

    if ( $field =~ /(.+)\.(\.+)/ ) {
        $table = $1;
        $field = $2;
    }

    my $type;
    my $sth = $self->query( -dbc => $self, -query => "SHOW columns FROM $table LIKE '$field'", -finish => 0 );
    while ( my @fieldinfo = $sth->fetchrow_array ) {
        my $localfield = $fieldinfo[0];
        $type = $fieldinfo[1];
        last;
    }
    $sth->finish();

    return $type;
}

# Find the name and type of a field for a given table
#
# <snip>
# Example:
#    my @field_info = $dbc->get_field_types(-table=>'Employee', -field=>'Employee_Name');
# </snip>
#
# Returns: array of Field Name, Type from given table
#########################
sub get_field_types {
#########################

    my %args = &filter_input(
         \@_,
        -args      => 'dbc,table,field',
        -mandatory => 'dbc|self',
        -self      => 'SDB::DBIO'
    );
    my $self = $args{-self} || $args{-dbc};

    my $table = $args{-table};    ## table from which to retrieve fields from
    my $field = $args{-field};    ## (optional) field name

    $field ||= "%";

    my @field_types = ();
    my $sth = $self->query( -dbc => $self, -query => "SHOW columns FROM $table LIKE '$field'", -finish => 0 );
    while ( my @fieldinfo = $sth->fetchrow_array ) {
        my $field = $fieldinfo[0];
        my $type  = $fieldinfo[1];
        push( @field_types, "$field\t$type" );
    }
    $sth->finish();

    return @field_types;
}

# Resolve the table and field name of a fully qualified field
#
# <snip>
# Example:
#    my @field_info = simple_resolve_field(-field=>'Employee.Employee_Name');     ## dbc not needed
#
# or
#
#    my @field_info = simple_resolve_field(-field=>'Employee_Name',-dbc=>$dbc);  ## dbc needed to search db for field name
#
#,
# </snip>
## Return: Array containing the reference table and the field name
##############################
sub simple_resolve_field {
##############################
    my %args   = &filter_input( \@_, -args => 'field', -mandatory => 'field' );
    my $field  = $args{-field};
    my $tables = $args{ -tables };
    my $debug  = $args{-debug};
    my $self   = $args{-dbc} || $args{-self};                                     ## can work without $dbc/$self object

    my ( $rtable, $rfield );

    $field =~ s/^['"]//g;
    $field =~ s/['"]$//g;

    if ( $field =~ /^\s*(\w+)\.(\w+)\s*$/ ) {
        $rtable = $1;
        $rfield = $2;
    }
    else {
        $rfield = $field;
    }

    my @tables = Cast_List( -list => $tables, -to => 'array' );
    if ( int(@tables) == 1 ) { $rtable = $tables[0] }

    if ( !$rtable && $self ) {
        my $added_condition;
        if ($tables) {
            my $table_list = Cast_List( -list => $tables, -to => 'string', -autoquote => 1 );
            $added_condition = " AND Field_Table IN ($table_list)";
        }

        ## make sure the query below does NOT get called into a recursive endless loop - ie the call below should avoid this block on the next run....
        ($rtable) = $self->Table_find( 'DBField', 'Field_Table', "WHERE Field_Name = \"$rfield\" $added_condition" );
    }
    return ( $rtable, $rfield );
}

##############
sub Table_test {
##############
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,condition,distinct', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    Message("done test");
    return;
}

# This method simply converts the field name to its
# FK equivalent eg. Sample_ID -> FK_Sample__ID
#
#####################
sub _get_FK_name {
#####################
    my $self     = shift;
    my %args     = &filter_input( \@_, -args => 'fk_table,table,field' );
    my $fk_table = $args{-fk_table};
    my $table    = $args{-table};
    my $field    = $args{-field};

    my @fk_field_name = &Table_find( $self, 'DBTable,DBField', 'Field_Name', "WHERE FK_DBTable__ID = DBTable_ID AND DBTable_Name = '$fk_table' AND Foreign_Key = '$table.$field'" );
    if ( scalar(@fk_field_name) > 0 ) {
        return @fk_field_name;
    }
    else {
        return;
    }
}

# This routine does a validation check before updating a record.
#
#  It checks for Mandatory, Unique fields, and ensures pointers to foreign
#  keys are valid.
# <snip>
# Example:
#    @entry_list = $self->Table_update_array_check($TableName,\@field_list,\@entry_list,'append')
# </snip>
# Return: Array
#####################################
sub Table_update_array_check {
#####################################

    my %args = &filter_input(
         \@_,
        -args      => 'dbc,table,fields,values,update,condition,force,check_unique',
        -mandatory => 'dbc|self',
        -self      => 'SDB::DBIO'
    );

    my $self             = $args{-self} || $args{-dbc};
    my $TableName        = $args{-table};                                              # table to check
    my $fields_to_update = $args{-fields};                                             # updated fields
    my $entry_values     = $args{ -values };                                           # updated field values
    my $update           = $args{ -update };                                           # To discern between append and update
    my $condition        = $args{-condition};
    my $force            = $args{-force};                                              # Override permission check
    my $date             = &date_time();
    my $debug            = $args{-debug} || $self->config('test_mode');
    my $check_unique     = defined $args{-check_unique} ? $args{-check_unique} : 1;    # run the unique check on the data
    my $quiet            = $args{-quiet};
    my $message_ref      = $args{-message_ref};                                        # (ArrayRef) if this is defined, the error messages (if any) will be stuffed into this reference
    my $comment          = $args{-comment} || '';                                      # comment passed on to Field change history log (if applicable)
    my $no_triggers      = $args{-no_triggers} || $self->{no_triggers};
    my $explicit         = $args{-explicit};                                           ## do not evaluate logical statements

    my @messages = ();

    my $login_table = $self->{login_table};                                            ## may be either Employee or User

    $user_id = $self->get_local('user_id') if !$user_id;

    # if updating records no need to check for unique records
    if ( $update =~ /update/i ) {
        $check_unique = 0;
    }

    #    should still check to make sure updates are still unique in next release...

    # if DBField is not populated, do not check integrity constraints
    # just return the unmodified values
    unless ( grep /DBTable/, $self->DB_tables() ) {
        return @{$entry_values};
    }

    # if it's an update some condition must be set
    if ( !$condition && ( $update =~ /update/i ) ) {
        $self->message("Not updating.  Some Condition must be set.");

        #return ();
    }

    my ( $tables, $joins ) = $self->extract_table_joins($TableName);

    foreach my $table ( split ',', $tables ) {
        unless ( %Field_Info && defined $Field_Info{$table} ) {
            $self->initialize_field_info($table);
        }
    }

    # Permission check
    unless ( $force || $self->check_permissions( $user_id, $TableName, 'edit', -debug => 0 ) ) {
        Message("Error: updating $TableName permission denied to Emp$user_id") if ( !$quiet );
        return ();
    }

    my @update_fields = @$fields_to_update;
    my @entries       = @$entry_values;
    my $table_list    = Cast_List( -list => $tables, -to => 'string', -autoquote => 1 );
    my %field_info    = $self->Table_retrieve(
        'DBField,DBTable',
        [ 'Field_Name', 'Field_Table', 'DBField_ID', 'Field_Format', 'Field_Options', 'Field_Type', 'Foreign_Key', 'Tracked', 'NULL_ok', 'Editable' ],
        "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name in ($table_list)",
        -key => "Field_Name"
    );

    my %Primary;    ## keep track of Primary fields for updated tables
    my %PVs;        ## keep track of Primary values for updated records
                    # step through each field and value pair and validate it
    for ( my $index = 0; $index < scalar(@update_fields); $index++ ) {
        my $field = $update_fields[$index];
        if ( $field =~ /(\w+)\.(\w+)/ ) { $field = $2 }
        my $value = $entries[$index];
        my $edit_comment;
        if   ( ref $comment eq "ARRAY" ) { $edit_comment = $comment->[$index] }
        else                             { $edit_comment = $comment }

        my $field_name;
        my $field_id;
        my $field_frmt;
        my $field_opts;
        my $field_type;
        my $field_fk;
        my $field_tracked;
        my $field_null_ok;
        my $editable;
        my $field_table;

        if ( exists $field_info{$field}{Field_Name} ) {
            $field_name    = $field_info{$field}{Field_Name}[0];
            $field_id      = $field_info{$field}{DBField_ID}[0];
            $field_frmt    = $field_info{$field}{Field_Format}[0];
            $field_opts    = $field_info{$field}{Field_Options}[0];
            $field_type    = $field_info{$field}{Field_Type}[0];
            $field_fk      = $field_info{$field}{Foreign_Key}[0];
            $field_tracked = $field_info{$field}{Tracked}[0];
            $field_null_ok = $field_info{$field}{NULL_ok}[0];
            $editable      = $field_info{$field}{Editable}[0];
            $field_table   = $field_info{$field}{Field_Table}[0];
        }

        # check enum fields
        if ( $field_type =~ /^enum\((.*)\)/i ) {
            my @options = split ',', $1;
            my @match = grep /^[\'\"]?$value[\'\"]?$/, @options;

            if ( scalar @match == 0 ) {

                # if(!($value eq 'NULL' && $field_null_ok ne 'NO')){
                # push (@messages ,"Error: Value $value is not valid for field $field");
                # Message("Error: Value $value is not valid for field $field -> ($field_type)") if (!$quiet);
                # }
                if ( $field_null_ok eq 'NO' ) {
                    if ( $value =~ /\W/ || $value ne 'NULL' ) {
                        push( @messages, "Error: Value $value is not valid for field $field" );
                        Message("Error: Value $value is not valid for field $field -> ($field_type)") if ( !$quiet );
                    }
                }

            }

            #elsif($value =~ /\S/) { # user meant to enter something
            #Message("match");
            #push (@messages ,"Error: Value $value is not valid for field $field");
            #Message("Error: Value $value is not valid for field $field -> ($field_type)") if (!$quiet);
            #}

        }

        # check for mandatory fields
        $field =~ s/ //g;
        if ( $field_opts =~ /mandatory/i && !defined $value ) {
            push( @messages, "Error: Value for mandatory field $field is not set for $TableName!" );
            Message("Error: Value for mandatory field $field is not set for $TableName!") if ( !$quiet );

            #return ();
        }

        # check of the format of the field value is correct
        $field_frmt =~ s/^\^/\^[\'\"]?/;    ## allow for quoted values ##
        $field_frmt =~ s/\$$/[\'\"]?\$/;

        if ( $field_frmt && $field_frmt ne 'NULL' && ( $value !~ /\b(CONCAT|CASE)\b/ ) && ( $value !~ /$field_frmt/ ) ) {
            ### skip format checking if value contains CASE or CONCAT expression ##
            push( @messages, "Warning: $field ($value) does not match expected format ($field_frmt)" );
            Message("Warning: $field ($value) does not match expected format ($field_frmt)") if ( !$quiet );

            #return ();
        }

        # check foreign fields for valid entries

        if ( $field_fk && $value && ( $value != 0 ) && ( $value =~ /\S/ ) && ( $value ne 'NULL' ) && ( $value !~ /""/ ) ) {
            my ( $fktable, $fkprimary_field ) = simple_resolve_field( $field_fk, -dbc => $self );
            my ($id_found) = $self->Table_find( "$fktable", "$fkprimary_field", "WHERE $fkprimary_field = '$value'" );
            if ($id_found) {
                ## Found the id, no need to check
            }
            else {
                my $fk_id = get_FK_ID( -dbc => $self, -field => $field_name, -value => $value, -debug => 0 );
                if ( !$fk_id ) {
                    push( @messages, "Error:  Foreign key value $value does not exist in table $fktable" );
                    Message("Error:  Foreign key value $value does not exist in table $fktable") if ( !$quiet );
                }
            }

            #return ();
        }

        # Check Date fields...
        if ( $field_type =~ /date/i && ($value) && ( $value != 0 ) && ( $value =~ /\S/ ) && ( $value ne 'NULL' ) && ( $value !~ /""/ ) && ( $value !~ /''/ ) && !( $value =~ /\d{4}-\d{2}-\d{2}/ or $value =~ /\w{3}-\d{2}-\d{4}/ ) ) {
            push( @messages, "Error in Date entry for $field: $value <BR>should be either YYYY-MM-DD or Mon-DD-YYYY" );
            Message("Error in Date entry for $field: $value <BR>should be either YYYY-MM-DD or Mon-DD-YYYY") if ( !$quiet );

            #Call_Stack();
            #return ();
        }

        # if field is tracked and it's an update and no errors
        if ( scalar(@messages) == 0 ) {

            my $cond;
            my $primary_value      = 0;
            my $primary_value_list = 0;
            my @ids;

            if ( $condition && ( $update =~ /update/i ) ) {
                if ( !$Primary{$field_table} ) {
                    ## This only needs to be established once per updated table ##
                    # ( $Primary{$field_table} ) = $self->get_field_info( -table => $field_table, -type => 'Pri' );
                    $Primary{$field_table}  = $self->primary_field($field_table);
                    push @{ $PVs{$field_table} }, $self->Table_find( $TableName, $Primary{$field_table}, $condition, -distinct => 1 );
                }
            }

            # if the condition contains only one value
            #    if ( $condition =~ / AND / ) { }    ## do not update if more than one condition (too complex) ##
            #    elsif ( $condition =~ /\=/ ) {
            #        ( $cond, $primary_value ) = split '=', $condition;
            #
            #                   # if the condition contains a list of number ids eg. in (1,2,3)
            #               }
            #               elsif ( $condition =~ /\(([\d\, ]+)\)/ ) {
            #                   ( $cond, $primary_value_list ) = split /in/i, $condition;
            #                   $primary_value_list =~ /\(([\d\,]+)\)/;
            #                   @ids = split( ',', $1 );
            #
            #                    # if the condition contains a list of word ids eg. in (A,B,C)
            #                }
            #                elsif ( $condition =~ /\(([\'\w\,]+)\)/ ) {
            #                    ( $cond, $primary_value_list ) = split / in \(/i, $condition;
            #                    $primary_value_list =~ /\(([\w\,]+)\)/;
            #                    @ids = split( ',', $1 );
            #                }
            #

            #
            # This may be useful, but:
            #
            # We FIRST need to add a different enum option to 'Editable' to indicate only editable via code (as opposed to directly on form) - eg Plate.FK_Rack__ID
            #
            #
            #		if ($editable =~/no/) {
            #		    my ($old_value) = $self->Table_find( $TableName, $field, $condition );
            #		    my $new_value = $value;
            #                    $new_value     =~ s/^\'//;    # at the beginning of the new value
            #                    $new_value     =~ s/\'$//;    # at the end of the new value
            #
            #		    if ($new_value eq $old_value) { next }   ## skip this record since it is the same...
            #		    else { $self->warning("CANNOT change '$field' from '$old_value' to '$new_value' - it is marked as NON-Editable (see Admin)"); return; }
            #		}

            if ( $field_tracked =~ /yes/i ) {
                ## remove single quotes from the new value
                $user_id ||= 0;
                my $new_value = $value;
                $new_value =~ s/^\'//;    # at the beginning of the new value
                $new_value =~ s/\'$//;    # at the end of the new value

                my @change_history_fields = ( 'FK_DBField__ID', 'Old_Value', 'New_Value', "FK_${login_table}__ID", 'Modified_Date', 'Record_ID', 'Comment' );

                ## Refactored Change History update to allow for multiple table updates ###
                if (%PVs) {
                    my %change_histories;
                    my $index = 0;
                    foreach my $primary_value ( @{ $PVs{$field_table} } ) {

                        my ($old_value) = $self->Table_find( $TableName, $field, "$condition AND $Primary{$field_table}='$primary_value'" );

                        my $q_new_value = $self->get_value( -table => $TableName, -value => $new_value, -condition => $condition, -explicit => $explicit, -debug => $debug );

                        if ( $old_value ne $q_new_value || $edit_comment ) {
                            my @values = ( $field_id, $old_value, $q_new_value, $user_id, $date, $primary_value, $edit_comment );
                            $change_histories{ ++$index } = \@values;
                        }
                    }
                    if ($index) {
                        my $ok2 = $self->smart_append( -tables => 'Change_History', -fields => \@change_history_fields, -values => \%change_histories, -autoquote => 1, -no_triggers => $no_triggers, -debug => $debug );
                    }
                }
            }
        }

        ## <CONSTRUCTION - add check for Object_ID & Object_Class to check dynamic foreign keys ##
        ########### <CONSTRUCTION - do we still need these ?? - Custom Insertion (specify other valid formats) ###########

        #elsif ($ffield=~/([\w_]+)[:]([\w_]+)/) {
        #    $ftn = $1; $fcn = $2;
        #}
        #elsif ($ffield=~/([\w]+)_ID/) {
        #    $ftn = $1; $fcn = $ffield;
        #}
        #elsif ($ffield=~/([\w]+)_Name/) {
        #    $ftn = $1; $fcn = $ffield;
        #}

    }

    if ($check_unique) {
        foreach my $table ( split ',', $tables ) {
            my @ufields = $self->get_field_info( $table, undef, 'uni' );
            ###### Check Unique fields for valid entries ############
            foreach my $ufield (@ufields) {
                my $index = 0;
                my $found = 0;
                foreach my $field (@update_fields) {
                    if ( ( $ufield eq $field ) ) {
                        my $value = $entries[$index];
                        if ( $value !~ /^\'.*\'$/ ) {
                            $value = "'$value'";
                        }
                        my @found = $self->Table_find( $table, $Primary{$table}, "WHERE $field LIKE $value", -autoquote => 1 );

                        if ( $condition =~ /$Primary{$table}\s?=\s?$found[0]/ ) {

                        }
                        elsif ( ( scalar(@found) > 0 ) && ( $update eq 'append' ) ) {

                            my @pri = $self->get_field_info( $table, undef, 'pri' );
                            ## <CONSTRUCTION> - this should generate a session error which may be hidden. ##
                            my $error = "Unique field check failed : $ufield should be unique, but $entries[$index] already exists.";
                            push( @messages, $error );
                                err ( $error, 0, $debug ) unless $quiet;

                            #Message($error) if (!$quiet);
                            #return ();
                        }    #### this is ok if we are simply changing the same record as condition specified
                        elsif ( scalar(@found) > 0 ) {
                            my $error = "$#found existing record(s): $field = $entries[$index] NOT unique !";
                            Message("$#found existing record(s): $field = $entries[$index] NOT unique !");
                            $self->warning("$#found existing record(s): $field = $entries[$index] NOT unique !");
                            return ();
                        }
                    }
                    $index++;
                }
            }
        }
    }

    if ( scalar(@messages) == 0 ) {
        return @entries;
    }
    else {
        if ($message_ref) {
            foreach my $message (@messages) {
                push( @{$message_ref}, $message );
            }
        }
        return ();
    }
}

#
# Extract value from supplied string (accounting for potential SQL Queries that need to be evaluated first)
#
#
# For most values, this simply returns the value itself.
# For some values, however, the value needs to be evaluated first
#
# eg:
#  'CASE WHEN... '
#  'CONCAT( ...'
#  'LEFT( ...'
#
# Additional SQL Query strings may need to be included as required, but this should handle the most common ones...
#
# This is particularly useful when tracking updates in Change_History.
#
# Return: evaluated value
#################
sub get_value {
################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $table       = $args{-table};
    my $condition   = $args{-condition};
    my $value       = $args{-value};
    my $explicit    = $args{-explicit};
    my $debug       = $args{-debug};
    my $q_new_value = $value;

    if ( !defined($table) ) {
        my $sth = $self->query( -query => "SELECT $value" );
        $sth->execute();
        my $row = $sth->fetchrow_hashref();

        my @eval_values = values(%$row);
        $q_new_value = $eval_values[0];
    }

    elsif ( !$explicit && $value =~ /\b(CASE|CONCAT)\b/ ) {
        ## don't quote if using CASE or CONCAT expression
        my ($eval_value) = $self->Table_find_array( -table => $table, -fields => [$value], -condition => $condition, -debug => $debug );

        $q_new_value = $eval_value;
    }
    return $q_new_value;
}

#
# Add comment to existing comment field
#
# * only adds if comment does not exist)
# * appends if field is not null
# * adds separator if necessary
#
###########################
sub append_comments {
###########################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'table,field,comment,condition', -mandatory => 'condition' );
    my $table     = $args{-table};
    my $field     = $args{-field};
    my $comment   = $args{-comment};
    my $condition = $args{-condition} || 'WHERE 1';

    my $ok = $self->Table_update_array(
        $table, [$field],
        ["CASE WHEN $field LIKE '%;' THEN CONCAT($field, ' $comment;') WHEN LENGTH($field) > 1 THEN CONCAT($field,'; $comment;') ELSE '$comment' END"],
        "$condition AND ($field NOT LIKE '%$comment%' OR $field is NULL)"
    );

    return $ok;
}

############################
# Function to execute a trigger given its id
# Return: 1 if successful, 0 if not
############################
sub execute_Trigger {
##################
    my $self = shift;
    my %args = @_;

    my $TableName        = $args{-table};
    my $action           = $args{-action};
    my $ids_ref          = $args{-ids};                # optionally, can supply ids instead of relying on last_insert_id()
    my $fields           = $args{-fields};
    my $monitor_progress = $args{-monitor_progress};

    # query if this table has a trigger
    my $trigger_id = &has_Trigger( -dbc => $self, -table => $TableName, -action => $action, -fields => $fields );
    $trigger_id = Cast_List( -list => $trigger_id, -to => 'String' );

    if ( !$trigger_id ) {
        ## no trigger ##
        return 1;
    }

    if ( $action =~ /update/ && !$ids_ref ) {
        Message "Need ids for 'update' trigger";
        return;
    }

    my @ids = ();
    if ($ids_ref) {

        # use id argument
        @ids = @{$ids_ref};
    }
    else {
        my $sth = $self->dbh()->prepare("SELECT LAST_INSERT_ID()");
        $sth->execute();
        my $insert_id_ref = $sth->fetchall_arrayref();
        my $newid         = $insert_id_ref->[0][0];
        @ids = ($newid);
    }

    # grab fields for trigger
    my %trigger_info = Table_retrieve( $self, 'DB_Trigger', [ 'DB_Trigger_ID', 'DB_Trigger_Type', 'Trigger_On', 'Value', 'Fatal' ], "WHERE DB_Trigger_ID IN ($trigger_id)" );

    my $index   = 0;
    my $success = 1;

    my $count    = int(@ids);
    my $triggers = int( @{ $trigger_info{DB_Trigger_ID} } );
    my ( $Progress, $completed );
    if ( $triggers && $monitor_progress =~ /\btrigger\b/i && $action =~ /(insert|update)/i ) {
        $completed = 0;
        
        require SDB::Progress;
        $Progress = new SDB::Progress( -title => "Running $triggers $TableName Triggers x $count", -target => $count * $triggers );
    }

    #    $self->defer_messages();
    ### loop through each trigger for a given table
    while ( defined $trigger_info{DB_Trigger_ID}[$index] and $success ) {
        my $trigger_info    = $trigger_info{DB_Trigger_ID}[$index];
        my $trigger_type    = $trigger_info{DB_Trigger_Type}[$index];
        my $trigger_command = $trigger_info{Value}[$index];
        my $fatal           = $trigger_info{Fatal}[$index];
        my $trigger_on      = $trigger_info{Trigger_On}[$index];

        ### Execute each trigger
        my $trigger_str = $TableName . '_' . $trigger_info;
        $self->Benchmark("START_TRIGGER_$trigger_str");
        if ( $action =~ /insert/ or $action =~ /update/ ) {
            if ( $trigger_on =~ /batch/ ) {
                ## batch trigger
                $success &= $self->execute_Trigger_helper( -table => $TableName, -action => $action, -id => $ids_ref, -trigger_id => $trigger_info, -trigger_type => $trigger_type, -trigger_command => $trigger_command, -fatal => $fatal, -batch => 1 );
                $completed += $count;
                if ( $monitor_progress =~ /\btrigger\b/i ) { $Progress->update($completed) }
            }
            else {
                ## single trigger
                foreach my $id (@ids) {
                    $success &= $self->execute_Trigger_helper( -table => $TableName, -action => $action, -id => $id, -trigger_id => $trigger_info, -trigger_type => $trigger_type, -trigger_command => $trigger_command, -fatal => $fatal, -batch => 0 );
                    $completed++;
                    if ( $monitor_progress =~ /\btrigger\b/i ) { $Progress->update($completed) }
                }

                #                $self->message("update -> $completed")
            }
        }

        $self->Benchmark("END_TRIGGER_$trigger_str");

        $index++;
    }

    #    $self->flush_messages();
    return $success;
}

#############################
# Function to find if there is a trigger associated with the specified table,action
# Return: 0 if no trigger, the trigger id if there is a trigger
#############################
sub has_Trigger {
#############################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $TableName = $args{-table};
    my $action    = $args{-action};
    my $fields    = $args{-fields};

    # first, check to see if the database has a Trigger table. If none, just return.
    if ( !( grep /^DB_Trigger$/, $self->DB_tables( -trim_quotes => 1 ) ) ) {
        return 0;
    }

    my $trigger_on_pattern = '%' . $action;
    my $condition          = "WHERE Trigger_On like '$trigger_on_pattern' and Status='Active' AND Table_Name='$TableName' ";

    if ( ( $action =~ /update/ ) && $fields ) {
        my $quoted_field_list = Cast_List( -list => $fields, -to => 'string', -autoquote => 1 );
        $quoted_field_list =~ s/$TableName\.(\w+)/$1/ig;    ## trim applicable field name
        $quoted_field_list =~ s/\w+\.(\w+)//ig;             ## exclude fully qualified fields from OTHER tables ...
        $quoted_field_list =~ s/\s//g;                      ## trim spaces to ensure field names match quoted string
        $quoted_field_list =~ s/,(\'\'|\"\")//g;            ## trim repetetive blank fields (ok if there is one at the beginning... )
        $condition .= "  AND (Field_Name IN ($quoted_field_list) or Field_Name is NULL or Field_Name ='')";
    }

    my @triggers = Table_find( $self, 'DB_Trigger', 'DB_Trigger_ID', $condition );

    if (@triggers) {
        return \@triggers;
    }
    else {
        return 0;
    }
}

############################
# Function to get the ID value
# Gets Primary ID from DBField. If it is an ID (or undefined), just use mysql_insert_id
# Otherwise, use the defined field from DBField and get it from the fields and values array
# Return: ID value
############################
sub get_last_insert_id {
############################
    my %args = @_;
    my $self = $args{-self} || $args{-dbc};

    my $table      = $args{-table};
    my $fields_ref = $args{-fields};
    my $values_ref = $args{ -values };

    # check if the DBTable and DBField tables exist
    my @tables = $self->DB_tables();
    foreach (@tables) {
        $_ =~ s/\`|\'|\"//g;
    }
    if ( ( !( grep /^DBTable$/, @tables ) ) || ( !( grep /^DBField$/, @tables ) ) ) {

        # if no metatables, just return last_insert_id
        return $self->dbh()->{'mysql_insertid'};
    }

    # get the primary field

    my @primary = &Table_find( $self, "DBTable,DBField", "Field_Name", "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' AND Field_Options like '%Primary%'" );

    # if there is no primary field selected, return last_insert_id
    if ( int(@primary) == 0 ) {
        return $self->dbh()->{'mysql_insertid'};
    }

    # if the primary field is an autoincrement ID, just return last_insert_id
    elsif ( $primary[0] =~ /_ID$/i ) {
        return $self->dbh()->{'mysql_insertid'};
    }

    # it is not an id, return the primary value that has been specified
    else {
        my %row_hash;
        @row_hash{@$fields_ref} = @$values_ref;

        return $row_hash{ $primary[0] };
    }
}

############################
# Helper Function to execute the trigger based on what time
# Return: 1 if successful, 0 if not
############################
sub execute_Trigger_helper {
############################
    my $self          = shift;
    my %args          = @_;
    my $TableName     = $args{-table};
    my $action        = $args{-action};
    my $id            = $args{-id};                  # single id if single trigger; array ref if batch trigger
    my $trigger_id    = $args{-trigger_id};          ## trigger to execute
    my $trigger_cmd   = $args{-trigger_command};     ## command value
    my $trigger_type  = $args{-trigger_type};        ## type of trigger
    my $batch_trigger = $args{-batch_trigger};       ## single or batch trigger
    my $fatal         = $args{-fatal};
    my $batch         = $args{-batch};               ## batch trigger?
    my $debug         = $args{-debug} || $self->config('test_mode') ;

    # separate out triggers by type
    my $returned = 0;

    my $trigger_command = $trigger_cmd;

    # replace <ID> wildcard in trigger value with the actual id
    if ( $trigger_type eq 'SQL' && $batch ) {
        my $ids_list = Cast_List( -list => $id, -to => 'string', -autoquote => 0 );
        $trigger_command =~ s/<ID>/$ids_list/g;
    }
    else {
        $trigger_command =~ s/<ID>/$id/g;
    }

    if ( $trigger_type eq 'SQL' ) {
        my $sth = $self->dbh()->prepare($trigger_command);
        if ($sth) {
            $returned = $sth->execute();
        }
        else {
            print "Error in trigger: " . $DBI::errstr . "\n";
            Call_Stack();
            $returned = 0;
        }
    }
    elsif ( $trigger_type eq 'Perl' ) {

        $trigger_command =~ s /dbh/dbc/g;

        $trigger_command =~ s /\$dbc/\$self/g;                ## replace reference to dbc with $self
        $trigger_command =~ s /\->do\(/\->dbh\(\)\->do\(/g;
        if ($debug) { Message("Trigger perl ($trigger_command)") }

        $returned = eval($trigger_command);

        if ($debug) {
            Call_Stack();
            Message("Executing Trigger:");
            print "<PRE>";
            print $trigger_command;
            print "</PRE>";
        }

        if ($@) {
            print "Error in trigger $trigger_id: $@\n";
            Call_Stack();
            $returned = 0;
        }
    }
    elsif ( $trigger_type eq 'Form' ) {
        $returned = 0;
    }
    elsif ( $trigger_type eq 'Method' ) {
        my $module;
        if ( $trigger_command =~ /^([\w\:]+)::(\w+?)$/ ) {
            $module          = $1;    ### over-ride table name if calling from a specific module ###
            $trigger_command = $2;
        }
        else {
            $module = "alDente::$TableName";
        }

        eval {"require $module"};

        my $object_type = $module;
        Message("Executing $object_type (new ... $trigger_command) - $id.") if ($debug);
        ## <CONSTRUCTION> Need to import object if necessary and possibly fully qualify name (?) ##
        eval "require $object_type";
        Message($@) if $@;
        my $object = $object_type->new( -dbc => $self, -id => $id, -quick_load => 1 );
        
        print HTML_Dump $object_type, $object if ($debug);

        $self->Benchmark("eth-$id-$module-run");

        $returned = $object->$trigger_command;
        $self->Benchmark("eth-$id-$module-ran");
        if ($debug) { Message("Trigger executed ($returned) on $object_type $id") }
    }
    elsif ( $trigger_type eq 'Shell' ) {
        ## simply run shell command ##
        $returned = try_system_command($trigger_command);
    }
    else {
        Message("Invalid trigger type: $trigger_type.");
    }

    if ( $fatal =~ /No/i ) { return 1 }    ## return 1 regardless to prevent rollback (Error / Warning messages only)
    return $returned;
}

#
# Simple accessor to get field description
#
#
############################
sub get_field_description {
############################
    my %args = &filter_input( \@_, -args => 'dbc,field', -mandatory => "dbc|self,field", -self => 'SDB::DBIO' );
    my $self  = $args{-self} || $args{-dbc};
    my $field = $args{-field};
    my $table = $args{-table};

    if ($table) { $field = "$table.$field" }

    if ( $field =~ /(\w+)\.(\w+)/ ) {
        my ( $table, $fld ) = ( $1, $2 );

        my ($desc) = $self->Table_find( 'DBField', 'Field_Description', "WHERE Field_Table = '$table' and Field_Name = '$fld'" );
        return $desc;
    }

    return;
}

#####################
sub barcode_prefix {
#####################
    my $self = shift;
    my $class = shift;
    
    my $Prefix = $self->config('Barcode_Prefix');
    
    if ($Prefix) {
        if ($class) { return $Prefix->{$class} }
        else { return $Prefix }
    }
    
}

#
# Simple accessor to get field prompt
#
#
############################
sub get_field_prompt {
############################
    my %args = &filter_input( \@_, -args => 'dbc,field', -mandatory => "dbc|self,field", -self => 'SDB::DBIO' );
    my $self  = $args{-self} || $args{-dbc};
    my $field = $args{-field};
    my $table = $args{-table};

    if ($table) { $field = "$table.$field" }

    if ( $field =~ /(\w+)\.(\w+)/ ) {
        my ( $table, $fld ) = ( $1, $2 );

        my ($prompt) = $self->Table_find( 'DBField', 'Prompt', "WHERE Field_Table = '$table' and Field_Name = '$fld'" );
        return $prompt;
    }

    return;
}

############################################################################
#  Foreign Key Handling
############################################################################
#
# Return a valid ID number given a barcode
#
# (checks given table for actual record)
#
# <snip>
# Example:
#
# my $valid_ids = $dbc->get_id(-barcodde=>$barcode, -table=>'Rack');
#
# </snip>
# Return: list of ID's
#########################
sub get_id {
#########################

    my %args = &filter_input( \@_, -args => 'dbc,barcode,table,limit,remove_repeats,feedback', -mandatory => "dbc|self,barcode,table", -self => 'SDB::DBIO' );
    my $self           = $args{-self} || $args{-dbc};
    my $validate       = $args{-validate};              ## validate this object (eg. make sure solution is not thrown out or expired)
    my $barcode        = $args{-barcode};               ## input barcode (may be id already - simply returned)
    my $TableName      = $args{-table};                 ## table to check (in case of id only, this checks for valid id)
    my $limit          = $args{-limit};                 ## (optional) - limit to number of ids retrieved (eg. 1)
    my $remove_repeats = $args{-remove_repeats};        ## (optional) - flag to indicate if repeat entries should be removed (allowed by default)
    my $feedback       = $args{-feedback};              ## (optional) - indicates more verbose feedback.
    my $condition      = $args{-condition};
    my $allow_repeats  = $args{-allow_repeats};         ### To turn off the warning whenever repeated ids have been entered
    my $debug          = $args{-debug} || $self->config('test_mode');
    my $quiet          = $args{-quiet};
    
    my $type           = $self->barcode_prefix($TableName);           ### if only 'Equ' specified, assume this is prefix..
    unless ($barcode) { return ''; }

    ########## START Custom entry ##############################
    my $tray_prefix = $self->barcode_prefix('Tray');
    if ( $barcode =~ /($tray_prefix)\d+/i && $TableName eq 'Plate' ) {
        require alDente::Tray;
        $barcode = alDente::Tray::convert_tray_to_plate( -dbc => $self, -barcode => $barcode );
    }
    ## this is done before normal processing to enable use of normal multi-plate id logic ##

    ####### END Custom Entry ##############################

    ##### MULTIPLE Barcode... ##########

    my @list;
    my $id = $barcode;
    my $ids;
    ###### Single prefixed barcode:
    if ( $id =~ /^($type)(\d+)$/i ) {
        $ids = 0 + $2;
    }
    elsif ( $id =~ /^(\d+)$/ ) {
        ### simple number.
        $ids = $id;

        ######## Barcode from Pulldown menu:
        # (ok to take out?)
        #    elsif ($id=~/[a-zA-Z]{3}(\d+):/) {$id = $1;}  ### extract from pulldown menus..
        ######## List of numbers only:
    }
    elsif ( $id =~ /^[\d\,\s]*$/ ) {
        if ($limit) {
            my @list = split ',', $id;
            my $num = 0;
            my @new_list;
            while ( defined $list[$num] ) {
                if ( $num < $limit ) {
                    push( @new_list, $list[$num] );
                }
                $num++;
            }
            $ids = join ',', @new_list;
        }
        else { $ids = $id }
    }
    elsif ($type) {
        my $num         = 0;
        my $original_id = $id;
        my $pos;
        ###### convert range of plates to a list...
        my $list  = '';
        my $stuck = 2001;
        while ( $id =~ /($type)(\d+)(.*)/i ) {
            my $type1     = $1;
            my $id1       = $2;
            my $remainder = $3;
            if ( $remainder =~ /^\s?[-]\s?($type)(\d+)/i ) {
                my $range = $2 - $id1;
                if ( $range < 1 ) { Message("INVALID Range!"); return; }
                elsif ( $range > $stuck ) { Message("Range limited to $stuck values"); return; }

                my $type2 = $1;
                my $id2   = $2;

                $ids .= extract_range("$id1-$id2") . ',';
                $id =~ s/$type1$id1\s?[-]\s?$type2$id2(\D|$)/$1/;
            }
            else {
                $id =~ s/$type1$id1(\D|$)/$1/;
                $ids .= "$id1,";
            }
            unless ( $stuck-- ) { Message("Stuck in loop"); Call_Stack(); last; }
        }
        chop $ids;    ## chop off comma
    }
    else {
        $ids = $id;
    }

    @list = split ',', $ids;

    ########## if barcodes are repeated, remove redundancies #########
    if ($remove_repeats) {
        my $added;
        $ids = $list[0] + 0;
        foreach my $add_id (@list) {
            $add_id += 0;
            if ( !$add_id ) { next; }
            if ( &list_contains( $id, $add_id ) ) {
            }
            else { $ids .= "," . $add_id; }
        }
    }

    my %unique_list = map { $_, 1 } split ',', $ids;
    my @u_list      = join ',',                keys %unique_list;
    my $unique      = int( keys %unique_list );

    #    my @u_list = @{RGTools::RGIO::unique_items([split(',',$ids)])};
    #    my $unique = scalar(@u_list);

    my @id_list = split ',', $ids;
    my $num_found = int(@id_list);
    if ( ( $unique != $num_found ) && !$allow_repeats ) {
        $self->warning("Warning: Repeat value found! [<i>$barcode</i> only $unique unique (@u_list) of $num_found ($ids) ids]");
    }
    
    my $valid_ids;
    if ( $ids =~ /\d+/ ) {
        $valid_ids = $self->valid_ids( $ids, $TableName, -condition => $condition, -validate => $validate, -debug => $debug, -quiet => $quiet );
    }
    else {
        $valid_ids = $ids;
    }

    return $valid_ids;
}

###################################################################
# retrieve only the ids that are valid for a given table.
# (ie. values already exist with in this list)
#
# <snip>
# Example:
#
# my $list = $dbc->valid_ids($ids, 'Solution');
#
# </snip>
# Return: list of ID's
###################
sub valid_ids {
###################

    my %args = &filter_input( \@_, -args => 'dbc,ids,table', -mandatory => 'dbc|self,ids,table', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $validate  = $args{-validate};
    my $ids       = Cast_List( -list => $args{-ids}, -to => 'string', -autoquote => 1 );    ### ids to check
    my $TableName = $args{-table};                                                          ### table containing id field
    my $condition = $args{-condition} || 1;                                                 ## optional extra condition
    my $quiet     = $args{-quiet} || 0;                                                     ## quiet option will not notify user of invalid id usage.
    my $debug     = $args{-debug};

    $condition =~ s/^WHERE //i;                                                             ## trim where at beginning of condition if supplied.

    ## if validate option chosen and extra validation conditions exist for this object, include them ##
    if ( $validate && defined $Validate_condition{$TableName} ) {
        $condition .= " AND $Validate_condition{$TableName}";
    }

    my $primary = $Primary_fields{$TableName} || 0;
    unless ($primary) {
        $primary = join ',', $self->get_field_info( $TableName, undef, 'Pri' );
    }
    unless ($primary) { $self->warning("Could not find primary field for $TableName"); return; }

    my @ok_ids = $self->Table_find( $TableName, $primary, "WHERE $primary IN ($ids) AND $condition", -debug => $debug);
    my @original_list = Cast_List( -list => $args{-ids}, -to => 'array', -trim_leading_zeros => 1, -debug => $debug);

    map { $_ =~ s/^[\'\"](.*)[\'\"]$/$1/ } @original_list;    ### remove the quotes incase...
    map { $_ =~ s/^[\'\"](.*)[\'\"]$/$1/ } @ok_ids;           ### remove the quotes incase...

    if ( !$quiet ) {
        my ( $intersec, $a_only, $b_only ) = &RGmath::intersection( \@original_list, \@ok_ids );
        if ( $a_only && defined( $a_only->[0] ) ) {
            $self->warning("Invalid (or Inactive) $TableName ID(s) entered: (@$a_only) - ignored");
            Call_Stack();
            if ( !$scanner_mode ) {
                my $originals = Cast_List( -list => $a_only, -to => 'string', -autoquote => 1 );
                my @fields = ( "$primary as ID", "$primary as $TableName" );

                my @table_fields = $self->Table_find( 'DBField', 'Field_Name', "WHERE Field_Table = '$TableName'" );
                if ( grep /FK_Rack__ID/,         @table_fields ) { push @fields, 'FK_Rack__ID as Location' }
                if ( grep /$TableName[_]Status/, @table_fields ) { push @fields, "${TableName}_Status as Status" }
                if ( grep /QC_Status/,           @table_fields ) { push @fields, 'QC_Status' }
                if ($debug) {
                    print $self->Table_retrieve_display(
                        $TableName, \@fields,
                        "WHERE $primary IN ($originals)",
                        -return_html => 1,
                        -title       => 'Invalid Records Found',
                        -debug       => $debug
                    );
                }
            }
        }
    }

    my @return_list;

    ### In order to preserve the order of IDs...
    foreach my $id (@original_list) {
        if ( $id && grep( /^$id$/, @ok_ids ) ) {
            push( @return_list, $id );
        }
    }
    my $return;
    $return = join( ',', @return_list ) if (@return_list);

    return $return;
}

# Gives a foreign key pattern match given a table name
#
# <snip>
# Example:
#
# my $list = SDB::DBIO::foreign_key_pattern('Employee')
#
# </snip>
# Return:  Foreign key pattern match
#############################
sub foreign_key_pattern {
#############################
    #
    # Specify foreign key pattern to check for..
    #
    my $TableName = shift || '';
    return 'FK%\_' . ${TableName} . '\_\_%';    ## neeed to escape underscores since these are wildcards in SQL
}

## Redundant .. remove - deprecate ##
###########################
sub foreign_key_check {
###########################
    #
    # Check if a field name corresponds to foreign key format
    #
    # Return target Table, target field if foreign key.
    #
    my %args = &filter_input( \@_, -args => 'field,class', -self => 'LampLite::DB' );

    my $self = $args{-self} || $args{-dbc};

    my $field = $args{-field};
    my $class = $args{-class};
    my $group = $args{-include_group_concat};    ## include group_concat ##
    my $debug = $args{-debug};

    $field =~s/^(\w+)\-//;  ## trim optional prefix to field name (eg 'Add-FK_User__ID') 

    if ( $class =~ /^\d+$/ ) {
        ## convert ID to class name ##
        $class = $self->get_db_value( -table=>'Object_Class', -field=>'Object_Class', -condition=>"Object_Class_ID = $class" );
    }

    my $TableName;                               ### target table
    my $target;                                  ### target field name
    my $descrip;                                 ### description of field...

    if ( $field =~ /^(\w+)\.(\w+)/ ) {
        ## truncate .. AS Alias if applicable ? ##
        $field = $2;
    }

    ############# Custom Insertion (Foreign Key specification) #################
    if ($group) {
        $field =~ s /^GROUP_CONCAT\((.*)\)/$1/i;
    }
    $field =~ s/^DISTINCT //i;                   ## ignore leading 'Distinct' spec
    $field =~ s/^(\w+)\.//;

    if ( $field =~ /^FK([A-Za-z0-9]*?)_(\S+)__(\S+)/i ) {
        ## changed to prevent matching of Concat.. CASE variations ##
        $TableName = $2;
        $target    = "$2_$3";
        $descrip   = $1;
    }
    elsif ( ( $field eq 'Object_ID' ) && $class ) {
        ## Special case : Object_ID references another record dynamically (references the id in the '$class' table)
        $TableName = $class;
        $target    = $class . "_ID";
    }
    else { return () }

    ############# End Custom Insertion (Foreign Key specification) #################
    my @list = ( $TableName, $target, $descrip );
    return @list;
}

###########################################################
# Get info on foreign keys (Returns Barcode: (+ info))
#
# (used to generate readable popup menu)
#
# <snip>
# Example:
#
# my $list = $dbc->get_FK_info(-field=>'FK_Plate__ID', -id=>5000);
#
# Get a list of formats
# my $formats = $dbc->get_FK_info(-field=>'FK_Plate_Format__ID', -list=>1);
#
# </snip>
# Return:  string with information on foreign key with specified id.
########################
sub get_FK_info {
########################
    my %args = &filter_input( \@_, -args => 'dbc,field,id,list,condition', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    my $field                = $args{-field};
    my $id                   = $args{-id};
    my $list                 = $args{-list};                                     ## allow users to retrieve full list of fk_info values
    my $fk_count             = $args{-fk_count};
    my $debug                = $args{-debug} || $self->config('test_mode');
    my $class                = $args{-class};                                    ## optional class specfication for encoded foreign keys (with multiple referenced tables)
    my $limit                = $args{-limit};
    my $additional_condition = $args{-condition} || 1;
    my $join_tables          = $args{-join_tables};                              ## allow for conditions to include fields from other tables
    my $join_condition       = $args{-join_condition};                           ## allows for conditions to include fields from other tables
    my $include_id           = $args{'include_id'} || $args{-include_id} || 0;
    my $view_filter          = $args{-view_filter};
    my $context              = $args{ -context };
    my $brief                = $args{-brief};                                    ## flag to exclude Barcode Prefix for Barcoded objects (otherwise - automatically included to enable searching in dropdowns)
    my $quiet                = $args{-quiet};
    my $get_query            = $args{-get_query};                                ## return query rather than executing query and returning results... (used for dynamic list generation using ajax) ##

    my $order = $args{'Order'} || $args{-Order};
    my $link = $args{'link'} || $args{ -link } || 0;
    my $validate = defined $args{-validate} ? $args{-validate} : 1;
    if ( defined $class && ( $class =~ /^\d+$/ ) ) {
        ## convert ID to class name ##
        ($class) = $self->Table_find( 'Object_Class', 'Object_Class', "WHERE Object_Class_ID = $class" );
    }
    if ($view_filter) {
        $view_filter =~ s/\*/\%/g;
    }
    my $TableName = '';
    my $id_field;

    if ( $field =~ /concat/i ) {
        ### just return id if too complicated
        return ($id);
    }
    elsif ( ( defined $id ) && !$id ) {
        $id = undef;
    }
    
    # sanity check
    # if there is an order by statement in the condition, do NOT use the defaulted order
    if ( $additional_condition =~ /(order by.*)/i ) {
        $order = $1;
        $additional_condition =~ s/^(.*)order by.*$/$1/i;
    }
    elsif ($order) {
        unless ( $order =~ /^order by/i ) { $order = "ORDER BY $order"; }
    }

    my $quoted_id;
    if ( defined $id ) {
        $id =~ s/^\'//;    # at the biginning of the new value
        $id =~ s/\'$//;    # at the end of the new value
        $quoted_id = $self->dbh()->quote($id);
    }    ### just in case...

    if ( ( $TableName, $id_field ) = $self->foreign_key_check( $field, -class => $class ) ) {

        #	### convert encoded object references to reference applicable table ###
        #	if (($TableName=~/Object_Class/) && $class) {#
        #	    Message("HERE IS $TableName ($id_field)");
        #	    $TableName = $class;
        #	    $id_field = $class . "_ID";
        #	}
        #
        if ( $class && ( $field =~ /Object_ID/ ) ) {
            ## convert specified Object to reference specific class (if supplied) ##
            $TableName = $class;
            $id_field  = $class . '_ID';
        }
    }
    else {
        if ( $field =~ /(\w+)\.(\w+)/ ) {
            $TableName = $1;
            $id_field  = $2;
        }
    }
    
    if ( !$TableName ) { return undef; }

    my $condition = '';
    if ( $additional_condition =~ /^WHERE/i ) {
        $condition = $additional_condition;
    }
    elsif ( $additional_condition =~ /\w+/ ) {
        $condition = "WHERE $additional_condition";
    }
    elsif ( !$condition ) {
        $condition = "WHERE 1";
    }
    ########### Custom Insertion (specify records to exclude) #################

    if ($list) {
        ## only add filtering condition if returning a list   ... ##
        ( my $pastmonth ) = split ' ', &RGTools::RGIO::date_time('-30d');    ####### omit solutions finished more than 1 month ago...
        if ( $field =~ /FKPrimer_Solution__ID/ ) {
            $condition .= " AND Solution_Type = 'Primer' AND (Solution_Status LIKE 'Open%' || Solution_Finished > '$pastmonth') ";
        }
        elsif ( $field =~ /FK_Primer__Name|Primer_ID/ || ( $field =~ /object_id/i && $TableName =~ /Primer/i ) ) {
            $condition .= " AND Primer_Type IN ('Adapter','Standard') AND Primer_Status <> 'Inactive'";
        }
        elsif ( $field =~ /FKBuffer_Solution__ID/ ) {
            $condition .= " AND Solution_Type = 'Buffer' AND (Solution_Status LIKE 'Open%' || Solution_Finished > '$pastmonth') ";
        }
        elsif ( $field =~ /FKMatrix_Solution__ID/ ) {
            $condition .= " AND Solution_Type = 'Matrix' AND (Solution_Status LIKE 'Open%' || Solution_Finished > '$pastmonth')";
        }
        elsif ( $field =~ /FKVendor_Organization__ID/ ) {
            $condition .= " AND Organization_Type LIKE '%Vendor%' ";
        }
        elsif ( $field =~ /FKManufacturer_Organization__ID/ ) {
            $condition .= " AND Organization_Type LIKE '%Manufacturer%' ";
        }
        elsif ( $field =~ /FKAgarose_Solution__ID/ ) {
            $condition .= " AND Stock_Catalog_Name like 'MP Mediaprep_0.9% Trevi' AND FK_Stock_Catalog__ID = Stock_Catalog_ID";
        }

        #        elsif ($field =~ /FK_Grp__ID/) {
        #            $condition .= " AND Grp_Type like 'Lab Dept'";
        #        }
    }
    ########### End Custom Insertion (specify records to exclude) #################

    if ( $self->barcode_prefix($TableName) && !$brief ) { $include_id = 1; }    ### force to include prefix $id when barcode type... ##

    my ( $Vtable, $view, $order_view, $Vtab, $Vcondition ) = $self->get_view( $TableName, $field, $id_field, $include_id, -class => $class, -context => $context );

    if ( $list && ( grep /^${Vtable}_Status$/, keys %{ $Field_Info{$Vtable} } ) ) {
        ## status field exists for this table ##
        $condition = "WHERE 1" unless ($condition);
        $condition .= " AND ${Vtable}_Status NOT IN ('Inactive')";
        ## <CONSTRUCTION> - standardize status types or take into account other options (old, not in use etc)
    }

    print Dumper( $Vtable, $view, $order_view, $TableName, $field, $id_field, $include_id, $class ) if ($debug);

    my $searchTable = $Vtable;
    $searchTable .= ",$join_tables"        if $join_tables;
    $condition   .= " AND $join_condition" if $join_condition;
    $order ||= "Order by $order_view";

    my $limit_condition = '';
    if ($limit) {
        $limit_condition = "LIMIT $limit";
    }

    if ($id) {
        if ( $id =~ /^<.*\>$/ ) { return $id }    ### special tag used ###

        if ( $id =~ /\D/ && $id_field =~ /_ID$/ ) {
            my $id_info = $self->get_FK_ID( $id_field, $id, -debug => $debug, -quiet => $quiet );
            if ( $id_info > 0 ) {
                return $id;
            }
            else {
                return undef;
            }

        }
        else {
            my $extra_condition = "AND $id_field in ($quoted_id) ";
            my ($info) = $self->Table_find_array( $searchTable, [$view], "$condition $extra_condition $Vcondition $limit_condition", -distinct => 1, -debug => $debug );
            RGTools::RGIO::Test_Message( "$info = $view ($id_field = $id)", $debug );

            unless ($info) {
                $extra_condition = " AND $view in ($quoted_id) ";
                ($info) = $self->Table_find_array( $searchTable, [$view], "$condition $extra_condition $Vcondition $limit_condition ", -distinct => 1, -debug => $debug );
            }

            if ( $info eq 'NULL' || !$info ) {
                 return ( $self->valid_ids( $id, $TableName ) );
            }
            elsif ($link) {
                my $link = &Link_To( $link, $info, "&Info=1&Table=$TableName&Field=$id_field&Like=$id", undef, ['newwin'] );
                return ($link);
            }
            else {
                return ($info);
            }
        }
    }
    elsif ($list) {
        unless ($order) { $order = "ORDER BY $order_view" }
        if ( $validate && %Validate_condition && $Validate_condition{$Vtable} ) {
            $condition .= " AND $Validate_condition{$Vtable} ";
        }
        if ($fk_count) {

            # <CONSTRUCTION>
            my $count;
            if ($additional_condition) {
                ## if filtering condition supplied, get (presumably lower count of records) ##
                ($count) = $self->Table_find_array( $searchTable, ['count(*)'], "$condition $Vcondition $order $limit_condition", -distinct => 1, -debug => $debug );
            }
            else {
                ($count) = $self->Table_find_array( 'DBTable', ['Records'], " WHERE DBTable_Name = '$searchTable'", -debug => $debug );
                if ( $count < 1000 ) {
                    ## get exact count if table not too big ##
                    ($count) = $self->Table_find_array( $searchTable, ["count(distinct $id_field)"], "$condition $Vcondition $order", -distinct => 1, -debug => $debug );
                }
            }
            return $count;
        }

        if ($view_filter) {
            if ( $view_filter =~ /^(\%)?(.*\|.*?)(\%)?$/ ) {
                ## allow for multiple input options using | for delimiter
                ## (also converts %A|B% syntax to '%A%' or '%B%'...)
                my $anystart = $1;
                my $anyend   = $3;
                my $string   = $2;

                my @options = split /\|/, $string;
                my @view_options;
                foreach my $option (@options) {
                    push @view_options, "CAST($view as CHAR) LIKE '$anystart$option$anyend'";
                }
                $view_filter = join ' OR ', @view_options;
                $view_filter = "AND ($view_filter)";
            }
            else {
                $view_filter = "AND CAST($view as CHAR) LIKE  '$view_filter'";
            }
        }

        if ($get_query) {
            ## return hash of query parameters.
            $condition =~ s/WHERE //;    ## strip initial WHERE in condition
            return { 'Table' => $searchTable, 'Field' => $view, 'Condition' => "$condition $view_filter  $Vcondition $order $limit_condition" };
        }

        my @info = $self->Table_find_array( $searchTable, [$view], "$condition $view_filter  $Vcondition $order $limit_condition", -distinct => 1, -debug => $debug );
        my @formatted;
        foreach my $inf (@info) {

            #	    $inf=~s/,/ /g;
            push( @formatted, $inf );
        }

        return @formatted;
    }
    else { return undef; }
}

###########################
sub get_FK_info_list {
###########################
    #
    # get list of Foreign key info
    # - returns array of foreign key info for all records.
    #  (calls 'get_FK_info' for each record)
    #
    my %args = &filter_input( \@_, -args => 'dbc,field,condition,max_size', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $class     = $args{-class};
    my $field     = $args{-field};
    my $condition = $args{-condition} || "1";
    my $maxlist   = Extract_Values( [ $args{-max_size}, 2000 ] );

    my ( $TableName, $id_field, $descrip ) = $self->foreign_key_check( $field, -class => $class );

    ########## Custom Insertion (Specify more specific conditions if required) ###

    if ( $field =~ /Solution__ID/i ) {

        #	$condition = "WHERE Solution_Status = 'Open'";
        if ( ( $descrip =~ /Primer/i ) || ( $descrip =~ /Matrix/i ) || ( $descrip =~ /Buffer/i ) ) {
            $condition .= " AND Solution_Type LIKE '$descrip'";
        }

    }

    ########## End Custom Insertion (Specify more specific conditions if required) ###

    my @info_list = $self->get_FK_info( -field => $field, -id => undef, -condition => $condition, -list => 1, -class => $class );

    return @info_list;
}

# This retrieves the ID given the 'info'
# (accomplishes the reverse of 'get_FK_info'
#
# <snip>
# Example:
#
# my $id = $dbc->get_FK_ID(-field=>$field,-value=>$value);
#
# </snip>
# Return Array
########################################
sub get_FK_ID {
####################

    my %args = &filter_input( \@_, -args => 'dbc,field,value,include', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $field      = $args{-field};
    my $val        = $args{-value};
    my $include_id = $args{-include};
    my $class      = $args{-class};                                      ## optional class specfication for encoded foreign keys (with multiple referenced tables)
    my $validate   = defined $args{-validate} ? $args{-validate} : 1;    ## validate ids on the fly (set to 0 if using for search condition - ie not important)
    my $debug      = $args{-debug};
    my $quiet      = $args{-quiet};                                  ## quiet mode - does not generate debug messages.
    my $TableName  = $args{-table};

    if ( $class =~ /^\d+$/ ) {
        ## convert ID to class name ##
        ($class) = $self->Table_find( 'Object_Class', 'Object_Class', "WHERE Object_Class_ID = $class" );
    }

    unless ($val) {
        return undef;
    }
    if ( $val =~ /^\-\-/ ) { return undef }                              ## this is a prompt in a popdown menu list - not available for choosing.. ##

    my ( @values, @ret );
    my $array_flag = 0;
    if ( ref($val) =~ /ARRAY/i ) {
        @values     = @{$val};
        $array_flag = 1;
    }
    else {
        push( @values, $val );
    }

    foreach my $value (@values) {
        my $id_field;
        my $copy = $value;

        $copy =~ s/^\'//;    # at the biginning of the new value
        $copy =~ s/\'$//;    # at the end of the new value
        if ( $copy !~ /\'/ ) { $value = $copy; }

        # Escape special characters in html format
        # The situation is caused by using popup_menu to generate options for template download file
        # TODO: We need to have a better solution and fix that in Template_Views::generate_matrix_form
        # Until then, we need to escape them when they are present
        $value =~ s/&#39;/\'/;
        $value =~ s/&amp;/&/;

        my $direct_value;
        
        if ( ( my $table, $id_field ) = $self->foreign_key_check( $field, -class => $class ) ) {
            ### convert encoded object references to reference applicable table ###
            # not sure why the logic checks for Object_Class when it should be looking for Object_ID ?? - did this work ?
            #	if (($TableName =~ /Object_Class/i) && $class) {
            #	    $TableName = $class;
            #	    $id_field = $class . "_ID";
            #	}
            
            $TableName ||= $table;

            if ( $class && ( $field =~ /Object_ID/ ) ) {
                ## convert specified Object to reference specific class (if supplied) ##
                $TableName ||= $class;
                $id_field  = $class . '_ID';
            }
            my $prefix = $self->barcode_prefix($TableName);
            if ( $prefix && ( $value =~ /^($prefix|)(\d+)$/i ) ) { $direct_value = $2; }
        }
        elsif ( $field =~ /(.+)\.(.+)/ ) {
            $TableName ||= $1;
            $id_field  = $2;
        }
        else {
            if ( $field =~ /(\w+)_(\w+)/ ) {
                $id_field  = $field;
                $TableName ||= $1;
            }
            else {
                push( @ret, $value );
            }
        }
        
        unless ($TableName) { return err ("No Table supplied in args to get_FK_ID"); }
        if ( $self->barcode_prefix($TableName) ) {
            $include_id = 1;
        }    ### force to include prefix$id when barcode type... ##

        my ( $Vtable, $view, $view_order, $Vtab, $Vcondition ) = $self->get_view( $TableName, $field, $id_field, $include_id, -class => $class, -debug => $debug );

        ##### Custom rack handling <CONSTRUCTION>
        if ( ( $field eq 'FK_Rack__ID' ) && param('Rack_Slot') ) {

            my $slot = param('Rack_Slot') || '';
            my $rack_id = $value;

            if ($view) {
                my $prefix = $self->barcode_prefix('Rack');
                if ( $rack_id =~ /^($prefix|)(\d+)$/ ) {
                    $rack_id = $2;
                }
                else {
                    ($rack_id) = $self->Table_find( 'Rack', 'Rack_ID', "WHERE $view = \"$value\"" );
                }
            }

            else {
                $rack_id = $value;
            }

            if ( $rack_id && $slot =~ /\w+/ ) {    # If slot is specified, then need to map it back to the actual rack ID. If can't mapped, then just use the specified rack_id

                my ($new_rack_id) = $self->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = $rack_id AND Rack_Type = 'Slot' AND Rack_Name = '$slot'" );

                if ($new_rack_id) {
                    my @existing_plates = $self->Table_find( 'Plate', "Plate_ID", "WHERE FK_Rack__ID=$new_rack_id" );
                    if ( scalar(@existing_plates) > 0 ) {
                        $self->warning("Cannot move: Slot is already filled, defaulting to " . $self->barcode_prefix('Rack') . "$rack_id");
                        $value = $rack_id;
                        push( @ret, $value );
                    }
                    $value = $new_rack_id;
                }
                else {
                    $self->warning("WARNING: Slot '$slot' not available for rack '$rack_id'. Move later if necessary.");
                }
            }
            push( @ret, $value );
        }

        if ($view) {
            my $distinct = $self->dbh()->quote($value);
            ## The block below is much faster at quickly retrieving matching views (eg WHERE CONCAT(FK_Library__Name,Plate_Numer) = 'Lib011') due to slowness of query due to concat)
            my $test_id;
            my $prefix = $self->barcode_prefix($Vtable);
            if ( $distinct =~ /$prefix(\d+)\:/i ) {
                ## this only works if the 'View' includes the prefix (eg 'Sam754947: LL005-1_A03' or 'Pla1234: Lib01-1') ##
                $test_id = $1;
            }
            elsif ( $distinct =~ /\[(\d+)\]$/i ) {
                ## this works for 'Mus Musculus [10090]'
                $test_id = $1;
            }
            if ($test_id) {
                ## if we can make a good guess as to what the id is, then check to see if it is right ##
                my ($shortcut) = $self->Table_find_array( $Vtable, [$view], "WHERE $id_field = $test_id $Vcondition" );    ## check to see if this is what we are looking for ##
                $shortcut = $self->dbh()->quote($shortcut);
                if ( lc($shortcut) eq lc($distinct) ) {
                    push @ret, $test_id;
                    next;
                }
            }

            ## this is much slower than above, but may be necessary ##

            my $id = join ',', $self->Table_find_array( $Vtable, [$id_field], "WHERE $view = $distinct $Vcondition", 'Distinct', -debug => $debug);
            $id ||= $direct_value;
            
            if ( ( $id eq 'NULL' ) || !$id ) {
                $id = $self->valid_ids( -ids => $value, -table => $TableName, -debug => $debug, -quiet => $quiet );    #### look for standard format
            }

            if ( $validate && !$quiet ) {
                if ( !$id && !$quiet ) { $self->warning("There is no record with value '$value' in '$TableName'"); Call_Stack(); }        ## generate message if supplied value is neither a valid info string or a valid id ##
            }
            push @ret, $id;
        }
        else {
            push( @ret, $value );
        }
    }
    if ($array_flag) {
        return \@ret;
    }
    else {
        return $ret[0];
    }
}

#########################
# Description:
#	This function checks for warning genereated with each query and returns the warning.
#
# <snip>
# Example:
#
# my $warning = $dbc->get_warnings( );
#
# </snip>
# Return a string
#########################
sub get_warnings {
########################
    my %args = &filter_input( \@_, -args => 'dbc', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $warning_message = '';

    my $query = 'show warnings;';
    ## only show warnings for now to Site Admin users (too many non-fatal warnings getting generated ##
    if ( $self->get_local('home_dept') ne 'Site Admin' ) { $query = 'show errors' }

    my $sth = $self->dbh()->prepare($query);
    $sth->execute();
    my $Farray = $sth->fetchall_arrayref();
    $sth->finish();

    my @warning_refs = @$Farray if $Farray;
    for my $warning_ref (@warning_refs) {
        my @warning = @$warning_ref if $warning_ref;
        if ( $warning[0] eq 'Warning' ) {
            $warning_message .= $warning[2] . '[Code:' . $warning[1] . ']' . "\n";
        }
    }

    return $warning_message;
}

#
# Retrieve auto-incremented name(s) for a text field based on a standard prefix
#
# Return: array_ref or names.
#############################
sub get_autoincremented_name {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,field,value,include', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self      = $args{-self} || $args{-dbc};
    my $field     = $args{-field};
    my $table     = $args{-table};
    my $count     = $args{-count} || 1;
    my $offset    = $args{-offset};
    my $prefix    = $args{-prefix};
    my $pad       = $args{-pad};
    my $char_size = $args{-char_size};
    my $debug     = $args{-debug};
    my @new_names;

    if ( $pad == 1 ) { $pad = 0 }    ## though it shouldn't really be used, N1 is essentially equivalent to no padding (so should probably not generally be limited to 9 digits in case it is set accidentally)  ##

    if ( $field =~ /(\w+)\.(\w+)/ ) { $table = $1; $field = $2 }

    my $order     = "ORDER BY ABS( REPLACE($field,'$prefix','')) DESC LIMIT 1";    ## force ordering by integer value of suffix ##
    my $condition = " WHERE $field LIKE '$prefix%' ";

    if ( $pad && $pad != 1 ) {
        $condition .= " AND $field REGEXP \"^${prefix}[0-9]{$pad}" . '$"';

        #    $condition .= ' AND ' . $field . ' REGEXP \"^' . ${prefix} . '[0-9]{' . $pad . '}$\"';
    }

    if ($char_size) {
        $condition .= "AND LENGTH($field) = $char_size";
    }

    my ($last_name) = $self->Table_find_array( $table, [$field], " $condition $order", -debug => $debug );

    my $nextindex;
    my $lastindex;

    my $counter_length;
    if ($char_size) { $counter_length = $char_size - length($prefix) }
    my $nextindex = 1;
    if ( $last_name =~ /^$prefix(\d+)/ ) {
        $lastindex = $1;
        $nextindex = $lastindex + 1;
    }

    if ($char_size) {
        foreach my $i ( 1 .. $count ) {
            if ( length($nextindex) < $counter_length ) {
                my $breaker;
                while ( length($nextindex) < $counter_length ) {
                    $breaker++;
                    $nextindex = '0' . $nextindex;
                    if ( $breaker > 1000 ) {last}
                }
                push @new_names, $prefix . $nextindex;

            }
            elsif ( $counter_length && ( length($nextindex) > $counter_length ) ) {
                $self->message("Error: Ran out of auto-increment numbers (digits = $counter_length). Last record in database: $prefix$lastindex");
                push @new_names, undef;
            }
            else {
                push @new_names, $prefix . $nextindex;
            }
            $nextindex++;
        }

    }
    else {
        foreach my $i ( 1 .. $count ) {
            my $padded = $nextindex;
            if ($pad) { $padded = sprintf "%0${pad}d", $nextindex }
            push @new_names, $prefix . $padded;
            if ( $pad && ( length($padded) > $pad ) ) { $self->warning("Ran out of auto-increment numbers (Padding set to $pad). Last record in database: $prefix$lastindex"); }
            $nextindex++;
        }
    }

    if   ( defined $offset ) { return $new_names[$offset] }
    else                     { return \@new_names }
}

#  Retrieves alternative view for foreign keys
#
#  (eg. shows info from referenced table)
#
###################
sub get_view {
###################

    my %args = &filter_input( \@_, -args => 'dbc,table,field,id_field,include', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $TableName  = $args{-table};        #### table
    my $field      = $args{-field};        #### field referenced
    my $id_field   = $args{-id_field};     #### id_field in referenced table
    my $include_id = $args{-include};      #### flag to include id in name if desired...
    my $class      = $args{-class};
    my $context    = $args{ -context };    #### optional context indicating which options may be relevant (eg -context=>{'Plate' => 5000});
    my $Vcondition = $args{-condition};    #### additional optional condition on view output list.
    my $debug      = $args{-debug};

    my $view;
    my $TableName_list;

    my ($ref) = $self->Table_find( 'DBField', 'Field_Reference', "WHERE Field_Name = '$id_field'", -debug => $debug );
    #### <CONSTRUCTION>  Remove FK_View hash dependency
    $ref ||= $FK_View{$id_field};

    if ($ref) {
        $view = $ref;
    }
    elsif ( !$view ) {
        ($view) = map {
            if (/(.*) as (.*)/) { $_ = $1; }
        } $self->get_fields( $TableName, $TableName . "_Name", 'defined' );    ### (was get_defined_fields) ##
    }
    else { $view = $id_field; }

    my ( $rtable, $rfield ) = $self->foreign_key_check( $field, -class => $class );

    my $order  = $view;
    my $Vtable = $rtable || $TableName;                                                   ### view table may include another table...

    $TableName_list = $TableName;

    #### Dynamically include tables directly referenced by primary object in Field_Reference ###
     
    $Vtable = $self->extend_Object_scope(-table=>$Vtable, -reference=>$ref );

    ########## Custom Edit (specific views extending beyond one table...) - or if context specific filtering is desired ##########

    if ( $rfield =~ /\bSolution_ID\b/ || $field =~ /\bSolution_ID\b/ ) {
        $Vtable = "Solution left join Stock on FK_Stock__ID=Stock_ID left join Stock_Catalog on FK_Stock_Catalog__ID = Stock_Catalog_ID";

        #	$view = "concat(Stock_Catalog_Name,' ',Solution_Number,'/',Solution_Number_in_Batch)";
        $order          = 'Stock_Catalog_Name';
        $TableName_list = "Solution,Stock,Stock_Catalog";
    }
    elsif ( $rfield =~ /\bBox_ID\b/ || $field =~ /\bBox_ID\b/ ) {
        $Vtable = "Box left join Stock on FK_Stock__ID=Stock_ID";

        #	$view = "concat(Stock_Catalog_Name,' ',Box_Number,'/',Box_Number_in_Batch)";
        $order          = 'Stock_Catalog_Name';
        $TableName_list = "Box,Stock,Stock_Catalog";
    }
    elsif ( $rfield =~ /\bRack_ID\b/ || $field =~ /\bRack_ID\b/ ) {
        $id_field = "CASE WHEN Rack_Type = 'Slot' THEN FKParent_Rack__ID ELSE Rack_ID END";
    }
    elsif ( $field =~ /FK_Stock__ID/ ) {
        $Vtable = "Stock left join Stock_Catalog on FK_Stock_Catalog__ID = Stock_Catalog_ID";

        #	$view = "concat(Stock_Catalog_Name,' ',Solution_Number,'/',Solution_Number_in_Batch)";
        $order          = 'Stock_Catalog_Name';
        $TableName_list = "Stock,Stock_Catalog";
    }
    elsif ( $rfield =~ /Vector_ID/ ) {
        $Vtable = "Vector,Vector_Type";

        $order          = "Vector_Type_Name";
        $TableName_list = "Vector,Vector_Type";
        $Vcondition .= "AND FK_Vector_Type__ID = Vector_Type_ID";
    }

    ######## ENSURE (matches edit in get_fk_info) ###############

    #    unless ($view =~/concat/i) {
    #	$view =~s /,/,' ',/g;  #### replace commas with spaces in concatenation..
    #	$order =~s /,/,' ',/g;
    #    }

    my $include = '';
    if ($include_id) {
        if ( my $prefix = $self->barcode_prefix($TableName) ) {
            $prefix =~ s /^(.+)\|(.*)/$1/ if ( $prefix =~ /\|/ );    ## if more than one possibility, just use the first one...
            $include = "'" . $prefix . "',";
        }
        $include .= "$id_field";
        if ( $view =~ /\b$id_field\b/ ) {                            ## already included
        }
        elsif ( $view =~ /^concat\((.*)/i ) { $view = "CONCAT($include,': ',$1" }    ## just add this in the beginning of the concat function ##
        elsif ($view) { $view = "$include,': ',$view"; }
        else          { $view = $include; $order = $include; }
    }
    $order ||= $view;

    if ( $view =~ /,/i && $view !~ /^concat\(/i ) {
        return ( $Vtable, "concat($view)", "concat($order)", $TableName_list, $Vcondition );
    }
    elsif ($view) {
        return ( $Vtable, $view, $view, $TableName_list, $Vcondition );
    }
    else {
        return ( $Vtable, $id_field, $id_field, $TableName_list, $Vcondition );
    }
}

#####################
sub foreign_key {
#####################
    #
    # Return the name of the id field for a foreign key
    #
############# Custom Insertion #################
    my %args = &filter_input( \@_, -args => 'table', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table = $args{-table};
    my $key;

############# Custom Insertion #################
    # $key = "FK_$TableName" . "__ID";
    ## pull out in descending order to retrieve  FK_ before FKOrig (for example) ##
    my ($fk_field) = $self->Table_find( 'DBField', 'Field_Name', "WHERE Foreign_Key like '${table}.%' ORDER BY Field_Name DESC" );
############# End Custom Insertion #############

    return $fk_field;
}

###########################
sub referenced_field {
###########################
    #
    # Check if a field name corresponds to foreign key format
    #
    # Return target Table, target field if foreign key.
    #
    my %args = &filter_input( \@_, -args => 'field,class', -self => 'SDB::DBIO' );
    my $self                 = $args{-self} || $args{-dbc};
    my $field                = $args{-field};
    my $include_group_concat = $args{-include_group_concat};

    if ( $include_group_concat && $field =~ /^GROUP_CONCAT\((DISTINCT |)(\w+\.)(\w+)(\_ID|Name)\)/i ) {
        $field = $2 . $3 . $4;
        $args{-field} = $field;
    }

    if ( $field =~ /(^|\.)(\w+[a-zA-Z])_ID$/ ) {
        my $table = $2;
        return ( $table, $table . '_ID' );
    }

    return $self->foreign_key_check(%args);
}

############################### CUSTOM Routines ###############################

###########################
sub check_permissions {
###########################
    my %args = &filter_input( \@_, -args => 'dbc,user_id,table,type,field,value', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $user_id   = $args{-user_id};
    my $TableName = $args{-table};
    my $type      = $args{-type};      ### editing or deletion...
    my $field     = $args{-field};     ### if deleting ...
    my $value     = $args{-value};     ### if deleting ...
    my $groups    = $args{-groups};
    my $debug     = $args{-debug};

    my $permitted;
    my $login_table = $self->{login_table};    ## may be Employee or User

    if ( $self->ping() && !$user_id ) {        ## ok if user logged directly into database ##
        return 1;
    }
    elsif ( !$self->{permission_checking} ) {
        return 1;
    }

    # <CONSTRUCTION> Standardize 'groups' local variable
    my @grp_names = @{ $self->get_local('groups') } if defined $self->get_local('groups');

    $groups ||= $self->get_local('group_list');
    if ( !$user_id ) {                         # No user id in effect - allow
        $permitted = 1;
    }
    elsif ( grep( /Site Admin/, @grp_names ) ) {    # Give all permissions if user is part of LIMS admin
        $permitted = 1;
    }
    elsif ( scalar(@grp_names) == 0 ) {             # no permissions if the user is not part of any group
        Message("User not member of any groups");
        $permitted = 0;
    }
    else {                                          # Check user group permissions
        my %info;
        if ($groups) {                              ## better to supply list of groups ##
            %info = $self->Table_retrieve( 'GrpDBTable,DBTable', ['Permissions'], "WHERE DBTable_ID = FK_DBTable__ID AND DBTable_Name = '$TableName' AND GrpDBTable.FK_Grp__ID IN ($groups)" );
        }
        else {
            %info
                = $self->Table_retrieve( "Grp$login_table,GrpDBTable,DBTable", ['Permissions'], "WHERE DBTable_ID = FK_DBTable__ID AND DBTable_Name = '$TableName' AND GrpDBTable.FK_Grp__ID=Grp$login_table.FK_Grp__ID AND FK_${login_table}__ID=$user_id" );
        }
        my $i           = 0;
        my @permissions = ();
        while ( defined $info{Permissions}[$i] ) {
            my @p = split /,/, $info{Permissions}[$i];
            @permissions = @{ &RGmath::union( \@permissions, \@p ) };
            $i++;
        }

        if ( $field && $value && $type =~ /delete/ && grep /\bO\b/, @permissions ) {    # Check original user permissions if deletion
            my ($user_field) = $self->get_field_info( $TableName, '%' . "${login_table}__ID" );
            if ( $user_field =~ /${login_table}__ID$/i ) {
                my ($original_user) = $self->Table_find( $TableName, $user_field, "WHERE $field in ($value)" );    ### get Employee who entered record..
                if ($original_user) {
                    if ( $original_user != $user_id ) {
                        ( my $original_name ) = &Table_find( $self, $login_table, "${login_table}_Name", "WHERE ${login_table}_ID = $original_user" );

                        # Get department access
                        my @accesses = Table_find( $self, "Grp,Grp${login_table},Department,${login_table}", 'Access',
                            "WHERE Grp${login_table}.FK_${login_table}__ID=${login_table}.${login_table}_ID AND Grp.FK_Department__ID=Department.Department_ID AND Grp${login_table}.FK_Grp__Id=Grp.Grp_ID AND Grp${login_table}.FK_${login_table}__ID = $user_id AND Department_Name = '$Login{current_department}' AND ${login_table}_Status='Active'"
                        );
                        my $department_access = join ",", @accesses;
                        if ( $department_access =~ /Admin/i and grep /\bD\b/, @permissions ) {                     # If admin and has deletion privilege then allow delete
                            Message("This record created by $original_name and now deleted by an Admin user ($user_id).");
                            $permitted = 1;
                        }
                        else {
                            Message("This record can only be edited by $original_name (or Admin) .$user_id.");
                            $permitted = 0;
                        }
                    }
                    else {                                                                                         # User is the original user - so OK it.
                        $permitted = 1;
                    }
                }
                else {                                                                                             # No original user found - OK it as well
                    $permitted = 1;
                }
            }
        }
        else {                                                                                                     # Check general permissions

            if ($debug) {
                print HTML_Dump( $type, \@permissions );
            }
            if ( $type =~ /\b(add|append|edit)\b/ && grep /\bW\b/, @permissions ) {
                $permitted = 1;
            }
            elsif ( $type =~ /\b(update|edit)\b/ && grep /\bU\b/, @permissions ) {
                $permitted = 1;
            }
            elsif ( $type =~ /delete/ && grep /\bD\b/, @permissions ) {
                $permitted = 1;
            }
            else {
                $permitted = 0;
            }
        }
    }
    return $permitted;
}

############################
sub Custom_Exceptions {
############################
    # Allow certain exceptions for deleting records which are externally referenced
    #
    # (in these cases, deletion is cascaded if possible)
    my %args = &filter_input( \@_, -args => 'dbc,table,field,found,check_only', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self       = $args{-self} || $args{-dbc};
    my $othertable = $args{-table};                 ### connected table to deleted record...
    my $otherfield = $args{-field};
    my $found      = $args{-found};                 ### related record found
    my $check_only = $args{-check_only} || 0;       # if true, then just check for exceptions (no deletions)

    #### specify connected table to also delete from ..
    my $delete_from;
    my $delete_field;
    my %delete_list;
    my $delete_self;
    my $force = 0;                                  # allow forcing of deletions (user can delete non-owned records
##    if (($othertable=~/Mixture/i)
##	  && ($otherfield=~/FKMade_Solution__ID/)) {
##	  ### (routine below not set up yet ... ###
##	  print "<B>Delete record of Mixture..</B><BR>";
##	  $delete_from = $othertable;
##	  $delete_field = $otherfield;
##	  $delete_list{$found} = 1;
##	  ### delete_or_rollback($self,,'Mixure','FKMade_Solution_Run',$value) ###
##    }
##### allow deletion of 384 well plates (but pre-delete, rollback ideal) ###
##    elsif (($othertable=~/MultiPlate_Run/i)
##	     && ($otherfield=~/FK[\S]*_Sequence__ID/)) {
##	  ### (routine below not set up yet ... ###
##	  print "<B>Delete associations with other plates in run</B><BR>";
##	  $delete_from = $othertable;
##	  $delete_field = $otherfield;
##	  $delete_list{$found} = 1;
##	  ### delete_or_rollback($self,'MultiPlate_Run','FK_Run__ID',$value) ###
##    }
##    elsif (($othertable=~/Plate_Set/i)
##	     && ($otherfield=~/FK_Plate__ID/)) {
##	  ### (routine below not set up yet ... ###
##	  print "<B>Delete associations with Plate Sets</B><BR>";
##	  $delete_from = $othertable;
##	  $delete_field = $otherfield;
##	  $delete_list{$found} = 1;
##	  $force=1;
##	  ### delete_or_rollback($self,,'Mixure','FKMade_Solution_Run',$value) ###
##    }
##    elsif (($othertable =~ /(Library_Plate|Tube|Gel_Plate)/) && ($otherfield eq 'FK_Plate__ID')) { # Delete a Library_Plate or Tube logical entity
##
##	  print "<B>Delete associations with $othertable</B><BR>";
##	  $delete_from = $othertable;
##	  $delete_field = $otherfield;
##	  $delete_list{$found} = 1;
##    }
##    elsif (($othertable =~ /Plate/) && ($otherfield eq 'FKOriginal_Plate__ID')) { # Delete a Library_Plate or Tube logical entity
##	$delete_self = 1;
##   }
##     elsif (($othertable =~ /Plate_Sample|Clone_Sample|Extraction_Sample/) && ( ($otherfield eq 'FK_Sample__ID') || ($otherfield eq 'FKOriginal_Plate__ID'))  ) { # Delete Plate_Sample, Clone_Sample
##	  #print "<B>Delete associations with $othertable</B><BR>";
##	  $delete_from = $othertable;
##	  $delete_field = $otherfield;
##	  $delete_list{$found} = 1;
##    }

    my @delete_keys = keys %delete_list;
    my $delete = join ',', @delete_keys;

    if ( $delete =~ /\S/ ) {
        unless ($check_only) {
            my $ok = &delete_records( $self, $delete_from, $delete_field, $delete, -override => $force );
            Message("deleted $ok records FROM $delete_from Table");
        }
        return 1;
    }
    elsif ($delete_self) { return 1; }
    else                 { return 0; }
}

# Generate the WHERE clause to include records with NULL, 0 or blank (i.e. '')
#
####################
sub Is_Null {
####################

    my $field = shift;
    return "$field IS NULL OR $field = 0 OR $field = ''";
}

#Generate the WHERE clause to exclude records with NULL, 0 or blank (i.e. '')
#
####################
sub Is_Not_Null {
####################

    my $field = shift;
    return "$field IS NOT NULL AND $field <> 0 AND $field <> ''";
}

##########################
sub Insertion_Check {
##########################
    #
    # - Checks whether the record about to be inserted violates the unique indexes. If found then return the primary ID of the existing record.
    #
    #
    my $self       = shift;
    my $TableName  = shift;
    my $fields_ref = shift;
    my $values_ref = shift;

    my @fields = @{$fields_ref};
    my @values = @{$values_ref};

    my $command = "show index FROM $TableName";
    my $sth     = $self->dbh()->prepare($command);
    $sth->execute();

    my %check_keys;
    while ( my $field_ref = $sth->fetchrow_hashref() ) {
        if ( $field_ref->{Non_unique} == 0 ) {
            my $key_name    = $field_ref->{Key_name};
            my $column_name = $field_ref->{Column_name};

            my $array_index;
            foreach my $field (@fields) {
                if ( $field eq $column_name ) {
                    $check_keys{$key_name}->{$column_name} = $values[$array_index];
                }
                $array_index++;
            }
        }
    }
    $sth->finish();

    my $primary_id;

    #Now perform the queries for each key to be checked.
    foreach my $key ( keys %check_keys ) {
        my $condition = "WHERE 1";
        foreach my $column ( keys %{ $check_keys{$key} } ) {
            my $value = $check_keys{$key}->{$column};
            $condition .= " AND $column = '$value'";
        }
        my ($primary_field) = get_field_info( $self, $TableName, undef, 'Primary' );
        ($primary_id) = Table_find( $self, $TableName, $primary_field, $condition );
        if ($primary_id) { return ( $primary_field, $primary_id ) }
    }
}

################################
# Append a string if necessary
#
#
########################
sub SQL_append_string {
########################
    my $field  = shift;
    my $string = shift;

    my $appended = "CASE WHEN $field like \"%$string%\" THEN $field WHEN Length($field) < 1 THEN \"$string\" ELSE CONCAT($field,\"; \",\"$string\") END";
    return $appended;
}

# Track if a query is slow and send a warning message if the user is an admin
#
# <snip>
# Example:
#
# $dbc->_track_if_slow(-message=>"SLOW QUERY",$time,10);
#
# </snip>
# Return
#######################
sub _track_if_slow {
#######################
    my %args = &filter_input( \@_, -args => 'message,time,cutoff', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $message = $args{ -message };
    my $time    = $args{ -time };

    my $time_cutoff = $args{-cutoff} || 2;

    if ( $time > $time_cutoff ) {
        $self->slow_query( date_time() . "\nSLOW $message\nTIME: $time seconds\n" );
        $self->message("Admin message indicating slow SQL execution<P>$message") if $self->get_local('user_name') =~ /^admin/i;    ## only show query message to admin user.
    }
    return;
}

###################################################################
# Convert date fields from Mon-DD-YYYY format to YYYY-MM-DD format
#
# <snip>
# Example:
#
# my @entries = _convert_date_fields($table,\@fields,\@values);
#
# </snip>
# Return Array
##############################
sub _convert_date_fields {
##############################
    my %args = &filter_input( \@_, -args => 'self,table,fields,values', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self             = $args{-self} || $args{-dbc};
    my $TableName        = $args{-table};
    my $fields_to_update = $args{-fields};
    my $entry_values     = $args{ -values };

    my @update_fields = @$fields_to_update;
    my @entries       = @$entry_values;

    my $index = 0;
    foreach my $field (@update_fields) {
        my $type = $Field_Info{$TableName}{$field}{Type};
        if ( $TableName =~ /^(.+)_Attribute$/ ) {
            ($type) = $self->Table_find( 'Attribute', 'Attribute_Type', "WHERE Attribute_Class='$1' and Attribute_Name = '$field'" );
        }
        if ( $type =~ /\bdate/i ) {

            # Convert Date returns 0000-00-00
            $entries[$index] = &convert_date( $entries[$index], 'SQL' );
        }
        elsif ( $type =~ /\btime/i ) {

            # Convert Time returns 0000-00-00
            $entries[$index] = &convert_time( $entries[$index] );
        }
        $index++;
    }
    return @entries;
}

#############################
# Order tables so that tables which have other tables depending on them
# will be put first
#
# Return: ordered list of tables
#############################
sub organize_tables {
#############################
    my %args = &filter_input( \@_, -args => 'dbc,tables', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};

    my $table_list_ref = $args{ -tables };

    my @table_list = @{$table_list_ref};

    # build insert order if DBField,DBTable exists
    my %fk_list;
    my @ordered_table_list = ();
    foreach my $table ( sort { $a cmp $b } @table_list ) {    # to ensure a constant starting order for a given array
        my %fk_field_info = &Table_retrieve( $self, "DBTable,DBField", [ "Field_Name", "Foreign_Key" ],
            "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' AND Field_Name like 'FK%' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT RLIKE 'Removed'" );

        my %object_id
            = &Table_retrieve( $self, "DBTable,DBField", ["Field_Name"], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' AND Field_Name like 'Object_ID%' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT LIKE '%Removed%'" );
        next if ( defined $object_id{'Field_Name'} );

        if ( ( defined $fk_field_info{'Field_Name'} ) && ( int( @{ $fk_field_info{'Field_Name'} } ) > 0 ) ) {
            my $count = 0;
            foreach my $field_name ( sort { $a cmp $b } @{ $fk_field_info{'Field_Name'} } ) {
                my ( $fk_table, undef ) = $fk_field_info{'Foreign_Key'}[$count] =~ /(\w+)\.(\w+)/;

                # my ($fk_table,undef) = &foreign_key_check($fk_field_info{'Foreign_Key'}[$count]);

                # if FK table is not in the table list or is self-referential, it is irrelevant
                if ( ( grep /^$fk_table$/, @table_list ) && ( $fk_table ne $table ) ) {
                    $fk_list{$table}{$field_name} = $fk_field_info{'Foreign_Key'}[$count];
                }
                $count++;
            }
            if ( !( defined $fk_list{$table} ) ) {
                $fk_list{$table} = {};
            }
        }
        else {
            $fk_list{$table} = {};
        }
    }

    ## Logic - go through each fk field and flag it if it has a value associated with it

    ## initialize insert order
    ## Loop:
    ## while there is still a table in the FK list
    ## for each table in the FK list
    ##   if it does not have an fk dependency, push it into the insert order
    ##   if its fk dependencies has already been pushed into the insert order, push it into the insert order
    ## repeat
    ## insert unresolved tables in the same order they were given as

    my $loopcount = 20;
    while ( $loopcount > 0 ) {
        foreach my $table ( sort { $a cmp $b } keys %fk_list ) {

            # remove fk dependencies already pushed into the table list
            # also, check if the FK field is defined in the field list. If it is, assume it has a value and can be removed
            foreach my $fk_field ( keys %{ $fk_list{$table} } ) {
                my ( $fk_table, undef ) = $fk_list{$table}{$fk_field} =~ /(\w+)\.(\w+)/;
                if ( grep /^$fk_table$/, @ordered_table_list ) {
                    delete $fk_list{$table}{$fk_field};
                }

            }

            # degenerate case, no fk dependency
            if ( int( keys %{ $fk_list{$table} } ) == 0 ) {
                push( @ordered_table_list, $table );
                delete $fk_list{$table};
                next;
            }

            # end case - no more tables in FK list
            if ( int( keys %fk_list ) == 0 ) {
                last;
            }
        }
        $loopcount--;
    }

    # insert remaining tables into the ordered table list
    foreach my $table (@table_list) {
        unless ( grep /^$table$/, @ordered_table_list ) {
            push( @ordered_table_list, $table );
        }
    }
}

# Supply the table name and condition and it will return a list of <Primary_ID> matching the consition
# Output: Hash referecne
# example:
#	{ -solution => 1,3,4,56,14 ,
#	  -stock    => 11,23,56,4567	}
################
sub get_Primary_ids {
################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'tables,condition', -mandatory => 'tables' );
    my $tables    = $args{ -tables };
    my $ref_table = $args{-ref_table};
    my $condition = $args{-condition};

    my %result;

    my ($primary_field) = $self->primary_field($ref_table); ## get_field_info( -table => $ref_table, -type => 'Primary' );

    if ( !$primary_field ) { $self->warning("Primary field not found for $ref_table"); return; }

    my @ids = $self->Table_find( $tables, $primary_field, $condition, -distinct => 1 );

    return @ids;
}

# Extract the ids from a string assuming that the string contains 3 letter prefix followed by the id
#
# <snip>
# Example:
#
# my $list = SDB::DBIO::extract_ids(-barcode=>'pla19242sol2048');
#
# </snip>
# Return Array Ref of IDs
##################
sub extract_ids {
##################
    my %args = &filter_input( \@_, -args => 'barcode' );
    my $list = $args{-barcode};
    my @list;
    if ($list) {
        while ( $list =~ /[a-zA-Z]{0,3}(\d+)/g ) {
            push( @list, $1 );
        }
    }
    return \@list;

}

# Get join tables and foreign keys for a given list of tables (all join tables if no table is specified)
#
# <snip>
# Example:
#
# my $join = SDB::DBIO::get_join_table(-tables=>['Source','Library']);
#
# </snip>
# Return Hash reference keyed by join tables
##################
sub get_join_table {
##################

    my %args = &filter_input( \@_, -args => 'dbc,tables', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
    my $debug = $args{-debug};

    my $tables_arrayref = $args{ -tables };
    my @arrays;
    if ($tables_arrayref) {
        @arrays = @$tables_arrayref;
    }

    my $tables    = "DBTable,DBField,DBTable as J1,DBField as J1F";
    my @fields    = ( "DBTable.DBTable_Name as JoinTable", "Max(concat(J1.DBTable_Name,'.',J1F.Field_Name,'.',DBField.Field_Name)) as T1", "Min(concat(J1.DBTable_Name,'.',J1F.Field_Name,'.',DBField.Field_Name)) as T2" );
    my $condition = "where DBField.FK_DBTable__ID=DBTable.DBTable_ID AND J1F.FK_DBTable__ID=J1.DBTable_ID AND DBField.Foreign_Key = concat(J1.DBTable_Name,'.',J1F.Field_Name) AND DBTable.DBTable_Type = 'Join'";
    my $constrain = " Group by DBTable.DBTable_ID Having count(*) = 2";

    if ( scalar @arrays ) {
        my $tables_string = "'" . join( "','", @arrays ) . "'";
        $condition .= " AND J1.DBTable_Name IN ($tables_string)";
    }

    my @result = &Table_find_array( -dbc => $self, -table => $tables, -fields => \@fields, -condition => $condition . $constrain, -debug => $debug );

    my %return;
    if ( scalar @result > 0 ) {
        foreach my $record (@result) {
            my @items = split( ",", $record );
            my $t1    = $items[1];
            my $t2    = $items[2];

            my ( $table1, $fk1, $join_key1 ) = split( /\./, $t1 );
            my ( $table2, $fk2, $join_key2 ) = split( /\./, $t2 );

            $return{ $items[0] }{$join_key1} = $table1 . "." . $fk1;
            $return{ $items[0] }{$join_key2} = $table2 . "." . $fk2;
        }
    }
    return \%return;
}

############################################
# Quick table generator that makes use of DBField to add functionality.
#
# options:
#   - toggle_on_column (indicate column to toggle line colours on)
#   - alt_message s(indicate message to display if no results come from query)
#   - colour (default line colour for rows)
#   - highlight (hash containing special row highlighting specs)
#       - eg $h{4}{Closed} = 'grey' would colour rows grey where column 4 = 'Closed'
# <snip>
# Example:
#
# my $ok = $dbc->Table_retrieve_display($TableName,\@fields,$condition,-distinct=>$distinct);
#
# my $html = Table_retrieve_display($dbc,$TableName,\@fields,$condition,-distinct=>$distinct,-title=>$title,-return_html=>1);
# </snip>
#
# Return: output in scalar form
################################
sub Table_retrieve_display {
################################
    my %args = &filter_input( \@_, -args => 'dbc,table,fields,condition,distinct,title,return_html', -mandatory => 'dbc|self', -self => 'SDB::DBIO' );
    my $self = $args{-self} || $args{-dbc};
###
    my $TableName          = $args{-table};                             # Table to search
    my $Pfields            = $args{-fields};                            # list of fields to extract ('*' retrieves all fields with prompts as keys; 'ALL' retrieves all original field names)
    my $condition          = $args{-condition};                         # 'where' condition,'Order by' or 'Limit' specifications7
    my $distinct           = $args{-distinct};                          # flag to return only distinct fields
    my $title              = $args{-title};
    my $toggle_on_column   = $args{-toggle_on_column};
    my $link               = $args{ -homelink } || $self->homelink();
    my $sortable           = $args{-sortable} || 'no';                  ## Have the links on top of each column to sort the table based on that column
    my $include_attributes = $args{-include_attributes};                ## only applicable when Pfield = '*' or 'ALL' ..
    my $table_class = $args{-table_class};
    my $debug              = $args{-debug};

## parameters below moved to SDB::HTML::display_hash
    #    my $alt_message = defined $args{-alt_message} ? $args{-alt_message} : "No records found";  # alternative message if no data retrieved.
    #    my $width = $args{-width} || '75%';
    #    my $return_html = $args{-return_html};  # flag to return the HTML for the table
    #    my $return_table = $args{-return_table};
    #    my $return_data  = $args{-return_data};   ## returns array of (output, \%data);
    #    my $print_link = $args{-print_link} || 0;
    #    my $excel_link = $args{-excel_link} || 0;
    #    my $print_path = $args{-print_path} || $URL_temp_dir;
    #    my $highlight   = $args{-highlight};    # specify rows to be highlighted (colour) based on column value
    #    my $colour      = $args{-colour} || ''; #
    #    my $total_columns = $args{-total_columns};  # scalar indicating list of columns to total at bottom.
    #    my $average_columns = $args{-average_columns};
    #    my $selectable_field = $args{-selectable_field};     ## Display a check box at the begining of each row and the value of
    #    my $link_parameters = $args{-link_parameters}; ##   that check box will be $selectable_field of that row (ex Plate_ID)
    #    my $append = $args{-append};        ## allow appending of more text (useful if to be included in printable page)
    #    my $prepend = $args{-prepend};
    #    my $Display       = $args{-Table};
    #    my $add_columns   = $args{-add_columns};
    #    my $summary       = $args{-summary};               ## display both average and totals for these keys
    #    my $by            = $args{-by} || 'row';           ## display by row or by column
    #    my $no_links      = $args{-no_links};              ## suppress internal links to other pages
    #    my $border        = $args{-border};
    #    my $highlight_string = $args{-highlight_string};
    #    my $highlight_colour = $args{-highlight_colour} || 'lightred';
    #    my $layer            = $args{-layer};
    #    my $show_count       = $args{-show_count};         ## show count of records in each tab (only applicable when using layers)

    ( $TableName, $Pfields ) = $self->decode_fields(%args);
    $args{-fields} = $Pfields;
    $args{-table}  = $TableName;

    my @header_list = @$Pfields;
    my $original_fields = join ',', @header_list;
    ## <Construction>  Want to move GROUP BY ORDER BY statements into separate arguments for Table_retrieve
    my @header          = ();
    my @fields          = ();
    my @display_headers = ();    ## Header titles as links

    my $class_key;
    my %labels;                  ## replace display_headers...
    my @headers;
    my %fields;
    foreach my $field (@header_list) {

        my $key = $field;
        if ( $field =~ /(.+) AS (.+)/i ) {
            my $actual_field = $1;
            $key = $2;

            my $label = $key;
            if ( $sortable eq 'yes' ) {
                $label = Link_To( $link, $label, "&Quick_Action_List=Table_retrieve_display&Table=$TableName&Condition=$condition&Fields=$original_fields&Distinct=$distinct&Title=$title&Toggle=$toggle_on_column&Order_By=$label", 'black', '' );
            }
            push @fields, $actual_field;
            push( @display_headers, $key );
            push( @headers,         $key );
            $fields{$key} = $fields[-1];
            $labels{$key} = $label;
        }
        else {
            my $label = $field;
            if ( $sortable eq 'yes' ) {
                $label = Link_To( $link, $field, "&Quick_Action_List=Table_retrieve_display&Table=$TableName&Condition=$condition&Fields=$original_fields&Distinct=$distinct&Title=$title&Toggle=$toggle_on_column&Order_By=$field", 'black', '' );
            }

            push( @display_headers, $label );
            push( @headers,         $field );
            push( @fields,          $field );
            $fields{$field} = $field;
            $labels{$field} = $label;

        }
        if ( $fields[-1] =~ /FK_Object_Class__ID/i ) { $class_key = $key }    ## track the class referencing field
    }
    $self->Benchmark('TRD_start_retrieve');

    my %Results = $self->Table_retrieve( %args, -class => $class_key, -date_tooltip => 1, -debug => $debug );

    $self->Benchmark('TRD_done retrieve');

    $args{-fields} = \%fields;
    $args{-dbc}    = $self;

    require SDB::HTML;
    return SDB::HTML::display_hash( %args, -hash => \%Results, -keys => \@headers, -labels => \%labels );
}

#
# Wrapper to decode field lists passed into retrieve method(s).
#
# The main purpose is to generate a default list of fields if supplied with '*' or 'ALL'.. or if no fields are passed in
#
# Return: (tables, fields)
####################
sub decode_fields {
####################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $Pfields            = $args{-fields};
    my $TableName          = $args{-table};
    my $condition          = $args{-condition};
    my $include_attributes = $args{-include_attributes};

    my @retrieve_fields;
    if ( $Pfields->[0] =~ /^(\*|ALL)$/ ) {
        foreach my $f ( $self->get_fields($TableName) ) {
            $f =~ /^([\w\.]+) AS (.+)$/i;
            my $field = $1;
            my $alias = $2;
            $alias =~ s/\_{2}/\_/;
            if ( $Pfields->[0] eq 'ALL' ) { push @retrieve_fields, $field }    ## use original names ##
            elsif ( $alias =~ /\s+/ ) { push @retrieve_fields, "$field AS '$alias'" }    ## put in quotes if alias has spaces
            else {
                if ( my ( $fk_table, $fk_field, $desc ) = $self->foreign_key_check($field) ) {
                    if ($desc) { $fk_table = $desc . '_' . $fk_table }

                    if ( defined $self->barcode_prefix($fk_table) ) { push @retrieve_fields, "$field AS $alias" }    ## if object is a barcoded item, include BOTH ID and field_reference by default
                    if ( grep /AS $fk_table$/i, @retrieve_fields ) {
                        ## CONSTRUCTION:  THIS SHOULD BE REMOVED WITH NEXT RELEASE
                        $fk_table .= '_';
                    }
                    push @retrieve_fields, "$field as $fk_table";

                }
                else {
                    push @retrieve_fields, "$field AS $alias";
                }
            }
        }

        $Pfields = \@retrieve_fields;

        if ( $include_attributes && $self->table_loaded( $TableName . '_Attribute' ) ) {
            ## only applicable with single table queries ##
            ( $TableName, $Pfields ) = $self->include_attributes( $TableName, $Pfields, $condition );
        }
    }
    elsif ( !$Pfields ) {
        my @table_list = $self->get_Table_list($TableName);
        @retrieve_fields = $self->get_fields( \@table_list, undef, 'defined' );    ### (was get_defined_fields) ##
        $Pfields = \@retrieve_fields;
    }

    foreach my $index ( 1 .. int(@$Pfields) ) {
        $Pfields->[ $index - 1 ] = $self->format_field_select( $Pfields->[ $index - 1 ], -tables => $TableName );
        $index++;
    }

    map {
        if (/^\w+\.(\w+)$/) { $_ .= " AS $1" }
    } @$Pfields;

    return ( $TableName, $Pfields );
}

############################
sub include_attributes {
############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'table,fields,condition' );
    my $TableName = $args{-table};
    my $Pfields   = $args{-fields};
    my $condition = $args{-condition};

    my $LJ;
    my $local_condition = $condition || 'WHERE 1';
    my @attributes = $self->Table_find(
        "$TableName, ${TableName}_Attribute,Attribute",
        'FK_Attribute__ID,Attribute_Name',
        "$local_condition AND FK_${TableName}__ID=${TableName}_ID AND ${TableName}_Attribute.FK_Attribute__ID=Attribute_ID AND Attribute_Class = '$TableName'",
        -distinct => 1
    );

    foreach my $attribute (@attributes) {
        my ( $att_id, $att_name ) = split ',', $attribute;
        $att_name =~ s/\s/\_/g;
        $LJ .= " LEFT JOIN ${TableName}_Attribute AS $att_name ON $att_name.FK_Attribute__ID=$att_id AnD $att_name.FK_${TableName}__ID=${TableName}_ID";
        push @{$Pfields}, "$att_name.Attribute_Value as $att_name";
    }
    $TableName .= $LJ;
    return ( $TableName, $Pfields );
}

#
# converts table paramter to list of tables
# (non trivial for cases of left join) - need to parse out table names and left join condition if possible
#
#
# Return: [[array of tables], [array of joins]]
############################
sub extract_table_joins {
############################
    my $self  = shift;
    my $table = shift;

    my @tables;
    my @joins;
    if ( $table =~ /^\w+$/ ) { return ( $table, 1 ) }    ## single table - easiest case

    if ( $table =~ / join /i ) {
        ## complex case with join ##  are there other cases we need to consider beside LEFT / RIGHT JOINS ?

        my $starting_table = $table;
        while ( $table =~ s /(.*) (LEFT|RIGHT) JOIN (\w+) ON (.*?)$/$1/i ) {
            my $more_tables = $3;
            unshift @joins, $4;
            unshift @tables, split /[\s\,]+/, $more_tables;    ## going from right to left so put on the stack in reverse order
        }

        ## put what is left back at the front of the list...
        my @front_tables = split /[\s\,]+/, $table;
        unshift @tables, @front_tables;
    }
    else {
        ## comma-delimited string only ... easy (are there any exceptions to this ?)
        @tables = split /[\s\,]+/, $table;
    }

    ## convert arrays to strings ##
    my $table_list      = join ',',     @tables;
    my $join_conditions = join ' AND ', @joins;
    $join_conditions ||= 1;

    return ( $table_list, $join_conditions );
}

########################
sub master_log {
########################
    my $self   = shift;
    my $Report = shift;

    my $sth = $self->query( -query => 'Show Master Status' );
    $sth->execute();
    my $row = $sth->fetchrow_hashref();
    if ($row) {
        $Report->set_Message("Master Database File: $row->{File}");
        $Report->set_Message("Master Database Position: $row->{Position}");
    }
    return;
}

####################
sub slave_log {
####################
    my $self   = shift;
    my $Report = shift;

    my $sth = $self->query( -query => 'Show Slave Status' );
    $sth->execute();
    my $row = $sth->fetchrow_hashref();
    if ($row) {
        $Report->set_Message("Slave Database File: $row->{Relay_Log_File}");
        $Report->set_Message("Slave Database Position: $row->{Relay_Log_Pos}");
    }
    return;
}

######################## check whether slave is working
sub is_slave_running {
########################
    my $self   = shift;
    my $Report = shift;

    my $sth = $self->query( -query => 'Show Slave Status' );
    $sth->execute();
    my $row = $sth->fetchrow_hashref();
    if ( $row->{Slave_IO_Running} eq 'Yes' && $row->{Slave_SQL_Running} eq 'Yes' ) {
        return 1;
    }
    else {
        return;
    }
}

########################
sub start_slave {
########################
    my $self   = shift;
    my $Report = shift;

    my $sth = $self->query( -query => 'START SLAVE' );
    $sth->execute();
    $Report->set_Message("Start Slave");
    return;
}

########################
sub stop_slave {
########################
    my $self   = shift;
    my $Report = shift;

    my $sth = $self->query( -query => 'STOP SLAVE' );
    $sth->execute();
    $Report->set_Message("Stop Slave");
    return;
}

# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>
    
None.
    

=head1 FUTURE IMPROVEMENTS <UPLINK>
    
    Eventually this object will replace the existing GSDB.pm and DB_IO.pm. Also support for transaction will be added in the future.
    

=head1 AUTHORS <UPLINK>
    
    Ran Guin, Andy Chan and J.R. Santos at the Canadas Michael Smith Genome Sciences Centre
    

=head1 CREATED <UPLINK>
    
    2003-09-05
    

=head1 REVISION <UPLINK>
    
    $Id: DBIO.pm,v 1.107 2004/11/30 01:42:24 rguin Exp $ (Release: $Name:  $)
							 

=cut

return 1;
