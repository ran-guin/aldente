#!/usr/local/bin/perl

use strict;
use Getopt::Std;

use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use SDB::DBIO;
use RGTools::RGIO;
use LampLite::Config;

use vars qw($opt_tables $opt_host $opt_dbase $opt_debug $opt_user $opt_pass $opt_u $opt_p $opt_help $opt_h $opt_new_tables $opt_reorder_fields $opt_scope_only $opt_packages);

use Getopt::Long;
&GetOptions(
    'tables=s'         => \$opt_tables,
    'debug'            => \$opt_debug,
    'host=s'           => \$opt_host,
    'dbase=s'          => \$opt_dbase,
    'user=s'           => \$opt_user,
    'u=s'              => \$opt_u,
    'pass=s'           => \$opt_pass,
    'p=s'              => \$opt_p,
    'help'             => \$opt_help,
    'h'                => \$opt_h,
    'new_tables'       => \$opt_new_tables,
    'reorder_fields=s' => \$opt_reorder_fields,
    'scope_only'       => \$opt_scope_only,
    'packages'         => \$opt_packages,
);

my $host  = $opt_host;
my $dbase = $opt_dbase;
my $user  = $opt_user || $opt_u;
my $pass  = $opt_pass || $opt_p;

### Set up Config ##

my $Config = LampLite::Config->new( -initialize=>$FindBin::RealBin . '/../conf/custom.cfg');

####################

my $help            = $opt_help || $opt_h;
my $debug           = $opt_debug;
my $tables          = $opt_tables || 'all';
my $new_tables_only = $opt_new_tables;        # Flag to set if only new tables are to be set
my $reorder_fields  = $opt_reorder_fields;

if ( $help || !($dbase) || !($host) ) {
    print_help();
    leave();
}

my $password_file = $FindBin::RealBin . "/../conf/mysql.login";
my $dbc = new SDB::DBIO( -dbase => $dbase, -host => $host, -user => $user, -login_file=>$password_file, -password => $pass, -connect => 1, -config=>$Config->{config});

#    open(LOG,">>$upgrade_dir/bin/upgrade_$Ver_To.log") or warn "Cannot open '$upgrade_dir/bin/upgrade_$Ver_To.log'";

my @Tables;
if ( $tables && ( $tables !~ /^all$/ ) ) {
    @Tables = split ',', $tables;
}
else {
    @Tables = $dbc->DB_tables();
}

if ($opt_scope_only) {
    set_table_packages( -dbc => $dbc );
    exit;
}

foreach my $table (@Tables) {

    # First see if we want to reorder fields for the current table
    my $reorder = 0;
    if ( ($reorder_fields) =~ /^all$/i || grep( /^$table$/, split( /,/, $reorder_fields ) ) ) {
        $reorder = 1;
    }
    print "Setting DB Table: $table... (" . now() . ")\n";
    print "*"x64;
    print "\n";

    # get fields according to the current DB_Field entries
    my @Fields_found = $dbc->get_field_info( -table => $table, -search_for_new => 1, -force => 1 );

    $dbc->initialize_field_info( $table, -source => 'standard' );

    print int(@Fields_found) . " fields. ";
    my $field_list = \@Fields_found;
    my @Showfields;
    if ($field_list) {
        @Showfields = @{$field_list};
    }

    my @Field_list;

    # get the table name and table title
    my @info        = $dbc->Table_find('DBTable', 'DBTable_ID,DBTable_Title', "where DBTable_Name = '$table'" );
    my $table_id    = 0;
    my $table_title = '';
    if ( int(@info) > 0 ) {
        ( $table_id, $table_title ) = split ',', $info[0];
    }

    if ( ( int(@info) > 0 ) ) {    # Table already defiend in DBTable
        my ($count) = $dbc->Table_find_array($table,["count(*)"]);
        $dbc->Table_update_array('DBTable',['Records'],[$count], "WHERE DBTable_Name = '$table'");
        print "updated record count for $table [$count records]\n";
        
        if ($new_tables_only) {
            print "Table: $table already defined in DBTable. NOT set.\n";
            next;
        }
    }
    else {
        print "Adding to DBTable $table\n";
        my ($count) = $dbc->Table_find_array($table,["count(*)"]);
        $table_id = $dbc->Table_append_array('DBTable', ['DBTable_Name', 'Records'], [$table, $count], -autoquote => 1 );
        $reorder = 1;    # New table so make sure we order the fields
    }
    ### Set FK_Package__ID

    my $order = 1;
    my %Hide;
    if (@Showfields) {
        @Field_list = @Showfields;
        foreach my $field (@Fields_found) {
            unless ( grep /^$field$/, @Showfields ) {
                push( @Field_list, $field );
                %Hide->{$field} = 'Hidden';
            }
        }
    }
    else { @Field_list = @Fields_found; }
    my ($id_field) = $dbc->get_field_info($table, undef, 'Pri' );
    my @unique_fields = $dbc->get_field_info($table, undef, 'Uni', -force => 1, -source => 'standard' );
    my @keyed_fields = $dbc->get_field_info($table, -type => 'Index' );
    print "(ID: $id_field)\n";
    print "(Keys: @keyed_fields)\n";

    my $added   = 0;
    my $updated = 0;

    foreach my $field (@Field_list) {

        #my $prompt = %Prompts->{$table}[$order-1] || $alias;  ### Temporary

        my $std_type    = $Field_Info{$table}{$field}->{Type};
        my $null_ok = $Field_Info{$table}{$field}{Null} || 'NO';
        my $default = $Field_Info{$table}{$field}{Default};
        my $key     = $Field_Info{$table}{$field}{Key};

        my $current = $dbc->hash(-table=>'DBField', -condition=>"Field_Name like '$field' and FK_DBTable__ID=$table_id");

        my $found = $current->{DBField_ID}[0];
        my $options = $current->{Field_Options}[0];
        my $current_format = $current->{Field_Format}[0];
        my $current_prompt = $current->{Prompt}[0];
        my $current_alias = $current->{Field_Alias}[0];
        my $current_index = $current->{Field_Index}[0];
        my $ref  = $current->{Field_Reference}[0] || '';
        my $type = $current->{Field_Type}[0] || $std_type;
        
        ## clear those options that are automatically reset if required ##
        $options =~ s /(Unique|Primary)//g;    ## these will be added subsequently if still applicable

        my $update_prompt = $field;
        my $fk            = '';
        my $format = $current_format;

        if ( ( my ( $Ftable, $Ffield ) = $dbc->foreign_key_check($field) ) ) {
            $fk = "$Ftable.$Ffield";
            my ($Ftable_prompt) = $dbc->Table_find('DBTable', 'DBTable_Title', "WHERE DBTable_Name='$Ftable'" );
            $update_prompt = $Ftable_prompt or $Ftable;

            if ( $field =~ /\bFK([a-zA-Z]+)\_/ ) { $update_prompt = "$1 $update_prompt" }
        }
        else {
            ## only on NON-foreign fields ##
            $update_prompt =~ s/\_+/ /g;

            #$alias=~s/^$table[_]//;
            ## only reset format for NON-foreign keys ##
            if ( ( $type =~ /varchar\((\d+)\)/ ) && $field !~ /^(Old|New)_Value$/ ) {    ## exclude Change_History.Old_Value, Change_History.New_Value ##
                my $max = $1;
                if ( !$format || ( $format =~ /\^\.{0\,\d+}\$/ ) ) {
                    ## preset (or reset if size of varchar is simply changed) ##
                    $format = '^.{0,' . $max . '}$';
                }
            }
        }

        my $alias = $current_alias || $field;
        my $prompt = $current_prompt || $update_prompt || $alias;

        if ( %Hide->{$field} ) { $options .= ",Hidden" unless ( $options =~ /Hidden/i ) }
#        if ( %Mandatory_fields->{$table} =~ /\b$field\b/ ) { $options .= ",Mandatory" unless ( $options =~ /Mandatory/i ) }
        if ( $field eq $id_field ) { $options .= ",Primary" unless ( $options =~ /Primary/i ) }
        if ( grep /\b$field\b/, @unique_fields ) { $options .= ",Unique" unless ( $options =~ /Unique/i ); }

        ## set up references if not set...

        if ( !$ref && ( $options =~ /primary/i ) ) {
            ## for primary fields only with no current field reference... set id reference to name if obvious..
            if ( $field =~ /($table\_|)ID$/i ) {
                my $prefix = $1;              ## allow for both Table_ID or ID format ...
                my ($name_alternative) = $dbc->Table_find('DBField', 'Field_Name', "where Field_Name like '$prefix" . "Name' and FK_DBTable__ID=$table_id" );
                if ($name_alternative) {
                    $ref = $name_alternative if $name_alternative;
                    $dbc->message("Set name to $ref ?");
                }
            }
        }

        my @fields;
        my @values;

        if ($reorder) {
            @fields = ( 'Field_Name', 'FK_DBTable__ID', 'Prompt', 'Field_Alias', 'Field_Options', 'Field_Reference', 'Field_Order', 'Field_Type', 'NULL_ok', 'Foreign_Key', 'Field_Table', 'Field_Index', 'Field_Format' );
            @values = ( $field, $table_id, $prompt, $alias, $options, $ref, $order, $type, $null_ok, $fk, $table, $key, $format );
        }
        else {
            @fields = ( 'Field_Name', 'FK_DBTable__ID', 'Prompt', 'Field_Alias', 'Field_Options', 'Field_Reference', 'Field_Type', 'NULL_ok', 'Foreign_Key', 'Field_Table', 'Field_Index', 'Field_Format' );
            @values = ( $field, $table_id, $prompt, $alias, $options, $ref, $type, $null_ok, $fk, $table, $key, $format );
        }

        if ($default) {
            push( @fields, 'Field_Default' );
            push( @values, $default );
        }

        print " ** $prompt ** (D:$default; NULL:$null_ok; T:$type; O:$options; R:$ref; I:$key; F:$format) - $found.\n";

        if ( $field =~ /^FK(\w*?)\_(\w+)\_\_/ && !$key ) {
            my $index = $2;
            if   ($1) { $index = $1 . '_' . $2 }
            else      { $index = $2 }
            $dbc->message("* Added missing $index Index *");
            $dbc->execute_command("CREATE INDEX $index ON $table ($field)");
        }
        elsif ( $field =~ /\_(ID|Time|Date|DateTime)$/i && !$key ) {
            ## any ID or Date / Time field should also be indexed automatically
            my $type = $1;
            $dbc->message("* Added $type index ($field)");
            $dbc->execute_command("CREATE INDEX $field ON $table ($field)");
        }

        if ( $found =~ /\d/ ) {
            my $ok = $dbc->Table_update_array('DBField', \@fields, \@values, "where DBField_ID = $found", -autoquote => 1, -debug => $debug, -no_triggers => 1, -explicit => 1 );
            if ($ok) { $updated++; }
        }
        else {
            my $ok = $dbc->Table_append_array(
                'DBField',
                [ 'Field_Name', 'FK_DBTable__ID', 'Prompt', 'Field_Alias', 'Field_Options', 'Field_Reference', 'Field_Order', 'Field_Type', 'NULL_ok', 'Foreign_Key', 'Field_table' ],
                [ $field,       $table_id,        $prompt,  $alias,        $options,        $ref,              $order,        $type,        $null_ok,  $fk,           $table ],
                -autoquote => 1,
                -debug     => $debug
            );
            if ($ok) { $added++; }
        }
        $order++;
    }

    my $deleted = 0;
    my @delete_fields;

    # Also get rid or obsolete fields from DBField table
    my %DB_fields = $dbc->Table_retrieve('DBTable,DBField', [ 'DBField_ID', 'Field_Name' ], "where DBTable_ID = FK_DBTable__ID and DBTable_Name = '$table' AND Field_Options NOT RLIKE 'Removed'" );
    my $i = 0;
    while ( defined $DB_fields{DBField_ID}[$i] ) {
        my $fid   = $DB_fields{DBField_ID}[$i];
        my $fname = $DB_fields{Field_Name}[$i];

        unless ( grep /\b$fname\b/, @Field_list ) {

            print "** Field: '$table.$fname' does not exist - it will be deleted.\n";
            push( @delete_fields, $fid );
        }
        $i++;
    }

    if (@delete_fields) {
        my $delete_counter;
        for my $delete_id (@delete_fields) {
            if ( $dbc->deletion_check( -table => "DBField", -field => "DBField_ID", -value => $delete_id ) ) {
                $deleted = delete_records( $dbc, 'DBField', 'DBField_ID', $delete_id );
                $delete_counter++;
            }
            else {
                my $ok = $dbc->Table_update_array( 'DBField', ['Field_Options'], ['Removed'], "where DBField_ID = $delete_id", -autoquote => 1 );
            }
        }
        $deleted = $delete_counter;
    }
    if ($reorder) {
        print $order - 1 . " ordered.  $added added.  $updated edited.  $deleted deleted.\n\n";
    }
    else {
        print "$added added.  $updated edited.  $deleted deleted\n\n";
    }

    #Set DBTable_Title to DBTable_Name if title not already set.
    unless ( $table_title =~ /[a-zA-Z]+/ ) {
        my $ok = $dbc->Table_update_array('DBTable', ['DBTable_Title'], ['DBTable_Name'], "where DBTable_ID = $table_id" );
        if ($ok) { print "Title of DBTable '$table' set to its name.\n" }
    }
}

### Set Package_IDs and scope for dbtables;
if ($opt_packages) {
    my @updated_ids = set_table_packages( -dbc => $dbc );
}

# Also get rid or obsolete tables from DBTable table
my $condition;

my $tables_list = join( ',', @Tables );

#if ($tables && ($tables !~ /^all$/) ) {
#    my $tables_list = $tables;
#    $tables_list =~ s/,/','/g;
#    $condition = "where DBTable_Name in ('$tables_list')";
#}
my @DB_table_list = $dbc->DB_tables();

my %DB_tables = $dbc->Table_retrieve('DBTable', [ 'DBTable_ID', 'DBTable_Name' ], $condition );
my $i = 0;
while ( defined $DB_tables{DBTable_ID}[$i] ) {
    my $tid   = $DB_tables{DBTable_ID}[$i];
    my $tname = $DB_tables{DBTable_Name}[$i];

    if ( !$tid || !$tname ) {
        $i++;
        next;
    }
    unless ( grep /\b$tname\b/, @DB_table_list ) {
        print "** Table: '$tname' does not exist - it will be deleted.\n";

        # delete DBField entries
        $dbc->dbh()->do("DELETE FROM DBField WHERE FK_DBTable__ID=$tid");

        # delete permission entries
        $dbc->dbh()->do("DELETE FROM GrpDBTable WHERE FK_DBTable__ID=$tid");

        # delete DBTable entry
        my $deleted = $dbc->dbh()->do("DELETE FROM DBTable where DBTable_ID=$tid");
        if ($deleted) {
            print "Table '$tname' deleted.\n\n";
        }
    }
    $i++;
}
##
##
##
#######################
sub set_table_packages {
#######################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my @core_tables = get_package_tables( 'Core', 'Core' );
    my @lab_tables  = get_package_tables( 'Lab',  'Lab' );
    my %tables_hash = (
        'Lab'  => \@lab_tables,
        'Core' => \@core_tables,
    );
    my @updated_ids;
    foreach my $key ( keys %tables_hash ) {
        next if ( !( exists $tables_hash{$key} ) );
        my @tables = @{ $tables_hash{$key} };
        my $scope  = $key;
        foreach my $table (@tables) {
            my ($table_id) = $dbc->Table_find( 'DBTable', "DBTable_ID", "WHERE DBTable_Name = '$table'" );
            my $success = $dbc->Table_update( "DBTable", "Scope", "'$scope'", "WHERE DBTable_ID = '$table_id'" );
            $dbc->message("Set Scope = '$scope' for table: $table");
            push @updated_ids, $table_id;
        }
    }

    my %installed_packages = $dbc->Table_retrieve( 'Package', [ 'Package_Name', 'Package_Scope', 'Package_ID' ], "WHERE Package_Install_Status = 'Installed'" );
    return () if ( !( defined $installed_packages{Package_Name} ) );
    my $i = 0;
    while ( exists $installed_packages{Package_Name}[$i] ) {
        $dbc->message("Setting table scope and package for $installed_packages{Package_Name}[$i]");
        my $package_name  = $installed_packages{Package_Name}[$i];
        my $package_id    = $installed_packages{Package_ID}[$i];
        my $package_scope = $installed_packages{Package_Scope}[$i];
        my @tables        = get_package_tables( "$package_name", "$package_scope" );
        foreach my $table (@tables) {
            my ($table_id) = $dbc->Table_find( 'DBTable', "DBTable_ID", "WHERE DBTable_Name = '$table'" );
            if ( !$table_id ) {
                $dbc->message("No table record found for table: $table");
            }
            unless ( !$table_id ) {
                my $success = $dbc->Table_update( -table => "DBTable", -fields => "FK_Package__ID,Scope", -values => "$package_id,'$package_scope'", -condition => "WHERE DBTable_ID = $table_id" );
                $dbc->message("Set Package_ID = '$package_name', Scope = '$package_scope' for table: $table");
                push @updated_ids, $table_id;
            }
        }
        $i++;
    }

    return @updated_ids;
}

#
#
######################3
sub get_package_tables {
#######################3
    my $package_name  = shift;
    my $package_scope = shift;

    my @package_tables;

    my $dir = "$FindBin::RealBin/..";
    my $table_file;
    if ( $package_name =~ /(lab|core)/ ) {
        $dir .= "/install/init/release/" . $dbc->config('CODE_VERSION');
        $table_file = "core_tables.conf" if ( $package_name =~ /core/i );
        $table_file = "lab_tables.conf"  if ( $package_name =~ /lab/i );
        my $full_path = "$dir/$table_file";
    }
    else {
        my $scope_folder = "custom" if ( $package_scope =~ /custom/i );
        $scope_folder = "Plugins" if ( $package_scope =~ /plugin/i );
        $scope_folder = "Options" if ( $package_scope =~ /option/i );
        $dir .= "/$scope_folder/$package_name/conf";
        $table_file = 'tables.conf';
    }
    if ( -f "$dir/$table_file" ) {
        open( TABLES, "<$dir/$table_file" );
        foreach my $line (<TABLES>) {
            chomp $line;
            $line =~ s/\s*$//;
            $line =~ s/^\s*//;
            next if ( $line =~ /^\#/ );
            unless ( !$line ) {
                push @package_tables, $line;
            }
        }
    }
    else {
        return ();
    }

    return @package_tables;
}
##########
sub leave {
##########
    if ($dbc) { $dbc->disconnect() }
    exit;
}

######################
sub print_help {
######################
    print <<HELP;

Builds the DBField and DBTable meta-tables.

Mandatory Options:
-host           : the host name of the machine that the database resides on.
-dbase          : the name of the database to build metatables for.
-user | -u      : the username to use to add metatables. Must have SELECT, INSERT, UPDATE, and DELETE permissions.
-pass | -p      : the password of the user.

Optional Flags:
-tables         : Comma-delimited list of tables to re/build metatables for.
-new_tables     : only builds metatables for new tables; ignores tables which already have DBTable entries.
-scope_only     : Only sets the scope and FK_Package__ID for all tables in DBTable
-packages       : set scope and package info
-help | -h      : display this help page

Usage example:
dbfield_set.pl -host lims01 -dbase sequence -u user -p pass -tables Container
-- This builds metatables for the Container table on database sequence\@lims01.

HELP
}

