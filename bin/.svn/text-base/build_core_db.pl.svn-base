#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use SDB::CustomSettings;

use vars qw($opt_help $opt_quiet $opt_debug $opt_dbase $opt_host $opt_user $opt_pwd $opt_version);

use Getopt::Long;
&GetOptions(
    'help'  => \$opt_help,
    'quiet' => \$opt_quiet,
    'debug' => \$opt_debug,
    q
	    ## 'parameter_with_value=s' => \$opt_p1,
	    ## 'parameter_as_flag'      => \$opt_p2,
	    'dbase=s'   => \$opt_dbase,
    'host=s'     => \$opt_host,
    'user=s'     => \$opt_user,
    'password=s' => \$opt_pwd,
    'version=s'  => \$opt_version,
);

my $new_dbase;
my $version;
if ($opt_version) {
    $version = $opt_version;
}
else {
    die "You MUST specify the version of database you wish to install (use -version option)";
}
if ($opt_dbase) {
    $new_dbase = $opt_dbase;
}
else {
    print "No target database name provided, exiting ...\n";
    return 0;
}

my $logfile;
my $logfilename;
my $logfiledir;

my $help  = $opt_help;
my $quiet = $opt_quiet;
my $debug = $opt_debug;

use SDB::DBIO;
my $host = $opt_host || $Configs{DEV_HOST};
my $user = $opt_user || 'super_cron';
my $pwd  = $opt_pwd;
my $dbc_new = new SDB::DBIO(
    -host     => $host,
    -dbase    => $new_dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1
);

if(!$pwd){
    $pwd = SDB::DBIO::get_password_from_file(-host=>$host, -user=>$user);
}

## Drop database
drop_db( -database => $new_dbase, -host => $host, -user => $user, -password => $pwd );

## Create database
build_db( -database => $new_dbase, -host => $host, -user => $user, -password => $pwd );

my @dataloaded_tables;
my @loaded_tables;

my @core_tables = _get_tables_from_conf( -scope => 'core', -version => $version );
my @lab_tables  = _get_tables_from_conf( -scope => 'lab',  -version => $version );

## Upload core tables
print "\n********************\n";
print "Core Tables Identified:\n";
foreach my $coretable ( sort @core_tables ) {
    print "$coretable\n";
}
print "\n*********************\n";

foreach my $core_table ( sort @core_tables ) {
    print "Table: $core_table\n";
    print "Uploading $core_table\n";
    upload_table( -dbase => $new_dbase, -table => $core_table, -version => $version );
    push @loaded_tables, $core_table;
    print "Finished with $core_table";
    print "\n********************\n";
}

## Upload lab tables

print "\n*********************\n";
print "Lab Tables Identified:\n";
foreach my $lab_table ( sort @lab_tables ) {
    print "$lab_table\n";
}
print "\n*********************\n";

foreach my $labtable ( sort @lab_tables ) {
    print "Table: $labtable\n";
    print "Uploading ...\n";
    print "Uploading $labtable";
    upload_table( -dbase => $new_dbase, -table => $labtable, -version => $version );
    push @loaded_tables, $labtable;
    print "Finished with $labtable";
    print "\n******************\n";
}

print "*** UPLOAD INITIALIZATION DATA ***\n";

foreach my $loaded_table (@loaded_tables) {

    my $connect = "mysql -h $host -u $user -p" . "$pwd $new_dbase";
    my $path    = "$FindBin::RealBin/../install/init/release/$version";
    print "======\n Table: $loaded_table\n *** uploading data from $path ...\n";
    my $command = qq{-e "LOAD DATA LOCAL INFILE '$path/$loaded_table.txt' INTO TABLE $loaded_table"};
    print "*** Mysql connect: $connect $command\n";
    my $feedback = try_system_command("$connect $command");
    print "FB: $feedback\n";
    push @dataloaded_tables, $loaded_table;
    print "Completed data load for $loaded_table\n";

}

################################################################3
#my @included_tables = $dbc_init->Table_find('DBTable','DBTable_Name', "WHERE Scope = 'Option'");
## There must be an additional condition here to check whether options have been specified
# Check %Configs{Options}
#print "You have chosen to install the following Optional Tables:\n@uincluded_tables\n****************\n";

#foreach my $included_table (@optional_tables) {
#    upload_table(-table=>$included_table);
##  foreach Optional Table (based upon options selected):
#
#       set table to 'Active'
#       import optional modules
##############################################################

## Upload

##  foreach Plugin Table (based upon plugins selected):
#my @plugin_tables = $dbc_init->Table_find('DBTable','DBTable_Name', "WHERE Scope = 'Plugin'");
## additional condition required to select only some plugins
#foreach my $plugin_table (@plugin_tables);
#       set table to 'Active'
#    upload_table(-table=>$plugin_table);
#       import plugin modules

######################################################

# Retrieve all acive tables
# For each active table
#     * run SQL create table command (from $table.sql)  ##
#     * Prefill standard records - run initialize values script
#         if exists table
#             Insert initialization records

##  Run db_field_set to set DBField, DBTable records.

## Reset sub_types for standard objects

set_sub_types('Library');               ## remove library sub_types ##
set_sub_types('Source');                ## remove source sub_types
set_sub_types('Work_Request');          ## remove source sub_types
set_sub_types('Sequencing_Library');    ## remove source sub_types

## Customizations ##
#
# Optional:
# cp Lab_Department.pm -> CustomDept_Department.pm
# add Type breakoff
#     # alter table add _type enum(..)
#     # create tables (1 for each enum)
#     # add DB_Form records to auto_navigate
# add optional fields (as required)
#
# run dbfield_set to upgrade DBField, DBTable records.

####################
# Upload table right away, from initialization files
#
# -load flag indicates to load data from initialization database
#
####################
sub upload_table {
###################
    my %args    = &filter_input( \@_, -args => 'table', -mandatory => 'version' );
    my $table   = $args{-table};
    my $host    = $args{-host} || 'limsdev02';
    my $dbase   = $args{-dbase};
    my $load    = $args{-load};
    my $version = $args{-version};
    die "Must specify version!" if !$version;

    my $password = SDB::DBIO::get_password_from_file(-host=>$host, -user=>'super_cron');
    my $path     = "$FindBin::RealBin/../install/init/release/$version";    ##
    my $bin_path = "$FindBin::RealBin/../bin";
    my $connect  = "mysql -u super_cron -p$password -h $host $dbase";

    my $struc_cmd = "$connect < $path/$table.sql";
    print "*** System command: $struc_cmd\n";
    try_system_command("$struc_cmd");

    if ($load) {
        print "*** uploading data from $path ...\n";
        my $command = qq{-e "LOAD DATA LOCAL INFILE '$path/$table.txt' INTO TABLE $table"};
        print "*** Mysql connect: $connect $command\n";
        try_system_command("$connect $command");
    }

}

###################
sub set_sub_types {
###################
    my $table     = shift;
    my $field     = shift || $table . '_Type';
    my $field_ref = shift;                       ## include subtypes if desired (defaults to single enum value of 'Normal')

    unless ( ( grep /\b$table\b/, @core_tables ) || ( grep /\b$table\b/, @lab_tables ) ) {
        print "** Skipping $table (NOT currently loaded)\n";
        return;
    }
    my @new_options;
    if ($field_ref) {
        @new_options = @$field_ref;
    }
    else {
        @new_options = ('Normal');
    }

    my ($enum)     = $dbc_new->Table_find( 'DBField,DBTable', 'Field_Type', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table' AND Field_Name = '$field' " );
    my ($field_id) = $dbc_new->Table_find( 'DBField,DBTable', 'DBField_ID', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table' AND Field_Name = '$field' " );

    my @current_options;
    if ( $enum =~ /^enum\((.*)\)$/ ) {
        @current_options = split ',', $1;
    }
    else {
        Message("$enum NOT recognized enum ($enum) in $table.$field");
    }

    if ( @new_options && @current_options ) {
        my $new_option_list = join "','", @new_options;

        $dbc_new->Table_update_array( 'DBField,DBTable', ['Field_Type'], ["enum('$new_option_list')"], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table' AND Field_Name = '$field'", -autoquote => 1 );

        foreach my $option (@current_options) {
            $dbc_new->dbh()->do("DELETE FROM DB_Form where Parent_Field = '$field' AND Parent_Value NOT IN ('$new_option_list')");

            #             $dbc_new->delete_records(-table=>'DB_Form',-field=>"Parent_Field",-value=>$field,-extra_condition=>"Parent_Value NOT IN ('$new_option_list')",-debug=>1);
        }
        my $command = "ALTER TABLE $table MODIFY $field Enum('$new_option_list')";
        $dbc_new->dbh()->do($command);
        print "\n*** Setting subtypes of $table ***\n";
        Message("Swap $table.$field options: @current_options -> @new_options");
    }
    else {
        Message("Failed to find current options (@current_options) or new options (@new_options)");
    }

    return 1;
}

1;
###################
#Delete database from server
#
#####################
sub drop_db {
#####################

    my %args     = &filter_input( \@_, -args => 'database' );
    my $database = $args{'-database'};
    my $user     = $args{-user};
    my $pwd      = $args{-pwd} || $args{-password};
    my $host     = $args{-host};

    my $connect = "mysql -h $host -u $user -p" . "$pwd $database";

    print "\n**********************\n" . "DROPPING DATABASE $database\n";
    print "*************************\n";
    my $sqlh = new SDB::DBIO(
        -host     => $host,
        -user     => $user,
        -password => $pwd,
        -dbase    => $database,
        -connect  => 1
    );

    my $sth = "DROP DATABASE IF EXISTS $database";
    print "Statement to drop database:\n" . "$sth\n";
    $sqlh->query("$sth");
    print "Attempting connection with command:\n" . "$connect\n";
    my $feedback = try_system_command("$connect");
    print "Feedback:\n" . "$feedback";
    if ($feedback) {
        print "Database $database dropped\n";
    }
    print "**********************\n";
    return 1;

}

#####################
#Create database
####################
sub build_db {
####################

    my %args     = &filter_input( \@_, -args => 'database' );
    my $database = $args{'-database'};
    my $user     = $args{'-user'};
    my $pwd      = $args{-pwd} || $args{-password};
    my $host     = $args{-host};

    my $connect = "mysql -h $host -u $user -p" . "$pwd $database";
    print "\n**********************\n" . "BUILDING DATABASE $database\n";
    my $sqlh = new SDB::DBIO(
        -host     => $host,
        -user     => $user,
        -password => $pwd,
        -dbase    => 'seqinit',
        -connect  => 1
    );

    my $sth = "CREATE DATABASE $database";
    print "*****************************\n";
    print "Statement to create database:\n" . "$sth\n";
    print "Creating database ...\n";
    $sqlh->query("$sth");
    print "Database $database created\n";
    print "**********************\n";
    return 1;

}

#########################
sub _get_tables_from_conf {
#########################
    my %args    = filter_input( \@_, -mandatory => 'scope' );
    my $scope   = $args{-scope};                                ## (lab or core)
    my $version = $args{-version};

    my $conf_path = "$FindBin::RealBin/../install/init/release/$version";
    my $filename  = "$scope" . "_tables.conf";

    my $full_path = "$conf_path/$filename";

    my @tables;
    if ( -f $full_path ) {
        open( DBCONF, "<$full_path" );
        foreach my $line (<DBCONF>) {
            next if ( $line =~ /^[\s]*[\#]+/ );
            chomp $line;
            $line =~ s/^[\s]+//;
            $line =~ s/[\s]+$//;
            push @tables, $line;
        }
    }
    elsif ( $scope =~ /core/i ) {
        die "Couldn't find file specifying core tables!\n(Looked for $full_path)\n";
    }
    elsif ( $scope =~ /lab/i ) {
        die "Couldn't find file specifying lab tables!\n(Looked for $full_path)\n";
    }

    return @tables;

}
