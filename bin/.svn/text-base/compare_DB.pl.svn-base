#!/usr/local/bin/perl

use strict;
use DBI;

use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";

use File::Find;

use RGTools::RGIO;
use RGTools::RGmath;
use RGTools::Process_Monitor;

use SDB::Installation;
use SDB::CustomSettings;

use vars qw($opt_help $opt_quiet $opt_dbase1 $opt_dbase2 $opt_core $opt_user $opt_password $opt_patched $opt_upgraded $opt_dumps $opt_v $opt_from_release $opt_testing %Configs $opt_ignore $opt_ignore_obsolete);

use Getopt::Long;
&GetOptions(
    'help'            => \$opt_help,
    'quiet'           => \$opt_quiet,
    'dbase1=s'        => \$opt_dbase1,
    'dbase2=s'        => \$opt_dbase2,
    'core=s'          => \$opt_core,
    'user=s'          => \$opt_user,
    'password=s'      => \$opt_password,
    'patched'         => \$opt_patched,
    'upgraded'        => \$opt_upgraded,
    'dumps'           => \$opt_dumps,
    'from_release'    => \$opt_from_release,
    'version|v=s'     => \$opt_v,
    'testing=s'       => \$opt_testing,
    'ignore=s'        => \$opt_ignore,
    'ignore_obsolete' => \$opt_ignore_obsolete,
);
my $help         = $opt_help;
my $testing      = $opt_testing || 0;
my $quiet        = $opt_quiet;
my $patched      = $opt_patched;
my $upgraded     = $opt_upgraded;
my $from_release = $opt_from_release;
my $dumps        = $opt_dumps;
my $ignore       = $opt_ignore;
my $ignore_obs   = $opt_ignore_obsolete;

################ Setting up databases  and connections #################
my $host2;
my $dbase2;
my $check_data;    #= $opt_core;     ## if there is a core database it should check the data as well as structure

my @ignore_tables;
if ($ignore) { @ignore_tables = split ',', $ignore }

my ( $host1, $dbase1 ) = split ':', "$opt_dbase1";
if ( $opt_dbase2 && $opt_core ) {
    Message "You have provided two target databases $opt_dbase2 & $opt_core. Use (dbase1 and core ) OR (dbase1 and dbase1)";
    exit;
}
elsif ( !$opt_dbase2 && !$opt_core ) {
    Message "Not enough information prvided please select second database";

}
elsif ($opt_core) {
    Message " Comparing against core database $opt_core and  $opt_dbase1";
    ( $host2, $dbase2 ) = split ':', "$opt_core" if $opt_core;
    $check_data = $dbase2;    ## if there is a core database it should check the data as well as structure
}
elsif ($opt_dbase2) {
    Message "Comparing two databases $opt_dbase2 and $opt_dbase1";
    ( $host2, $dbase2 ) = split ':', "$opt_dbase2" if $opt_dbase2;
}
my $user = $opt_user;
my $pwd  = $opt_password;

if ( $help || !$dbase1 ) {
    help();
    exit;
}
if ( ( my $whoami = `whoami` ) !~ /aldente/ && !$testing ) {
    chomp $whoami;
    print "$whoami: Please log in as aldente to run\n\n";
    exit;
}
## Setting User and Password

if ( !$user || $user ne 'super_cron_user' ) {
    Message "User set to super_cron";
    $user = 'super_cron_user';
}

require SDB::DBIO;

my $Report = Process_Monitor->new( -testing => $testing, -variation => $opt_v );
$Report->set_Message("Attempting to connect to $host1:$dbase1 as $user");
my $dbc1 = new SDB::DBIO(
    -host    => $host1,
    -dbase   => $dbase1,
    -user    => $user,
    -connect => 1,
);
my $from_release;
my $dbc2;
$Report->set_Message("Attempting to connect to $host2:$dbase2 as $user");
$dbc2 = new SDB::DBIO(
    -host    => $host2,
    -dbase   => $dbase2,
    -user    => $user,
    -connect => 1,
);

my %db_info;
$db_info{$dbase1}{host} = $host1;
$db_info{$dbase1}{dbc}  = $dbc1;
$db_info{$dbase2}{host} = $host2;
$db_info{$dbase2}{dbc}  = $dbc2;

my $log;
$Report->set_Message("Generating summary of database differences");
my $summary = generate_diff_report( -user => $user, -dbase1 => $dbase1, -dbase2 => $dbase2, -db_info => \%db_info, -dumps => $dumps, -upgraded => $upgraded, -from_release => $from_release, -report => $Report, -core => $check_data );
$log .= "$summary";

foreach my $line ( split "\n", $log ) {
    chomp $line;
    if ( $line =~ /ERROR/ ) {
        $Report->set_Error("$line");
    }
    else {
        $Report->set_Detail("$line");
    }
}
my $errors = $Report->get_Errors();
$errors = int( @{$errors} );
my $warnings = $Report->get_Warnings();
$warnings = int( @{$warnings} );
print "compare_DB number of errors: $errors, compare_DB number of warnings: $warnings\n";
$Report->set_Message("$summary");
$Report->completed();
$Report->DESTROY();
print "\n\n";
exit;

####################
sub generate_diff_report {
####################
    my %args     = filter_input( \@_ );
    my %db_info  = %{ $args{-db_info} };
    my $user     = $args{-user};
    my $dbase1   = $args{-dbase1};
    my $dbase2   = $args{-dbase2};
    my $dumps    = $args{-dumps};
    my $upgraded = $args{-upgraded};
    my $core     = $args{-core};

    my $from_release = $args{-from_release};

    my $summary;

    if ($dumps) {
        ##remove files from temp
        #	$Report->set_Message("Clearing temp folder of past schemas");
        #	_clear_temp_files(-dbase1=>$dbase1,-dbase2=>$dbase2,-types=>'sql,diff');
    }

    foreach my $db ( keys %db_info ) {
        my $dbc = $db_info{$db}{dbc};
        next if ( !$dbc );
        $Report->set_Message("Generating hash of $db database's tables and fields");
        $Report->set_Message("Dumping table sql files into temp directory") if ($dumps);
        my @tables = _get_tables( -dbc => $dbc );

        foreach my $table (@tables) {
            if ($dumps) {
                _dump_table( -dbc => $dbc, -table => $table );
            }

            my @fields = _get_fields( -dbc => $dbc, -table => $table );
            $db_info{$db}{tables}{$table} = {};

            foreach my $field (@fields) {
                my %field_info = _get_field_info( -dbc => $dbc, -field => "$table.$field" );
                $db_info{$db}{tables}{$table}{fields}{$field}{type} = $field_info{type};
                ##field info is complete
            }
            ##table info is complete

        }
        ##db_info has hash of tables, pointing to fields, each of which is a hash pointing to field info
        $Report->set_Message("Hash is complete");
        $Report->set_Message("Tables all dumped for $db database") if ($dumps);
    }
    #################################################
    ##  db info is filled out for both databases ####
    #################################################

    my @db1_tables;
    my @db2_tables;
    @db1_tables = keys %{ $db_info{$dbase1}{tables} };
    @db2_tables = keys %{ $db_info{$dbase2}{tables} };
    $Report->set_Message("Finding common and differing tables between the two databases...");
    my ( $intersec, $db1_only, $db2_only ) = RGmath::intersection( \@db1_tables, \@db2_tables );

    my %db_diffs;
    $db_diffs{$dbase1}{tables} = $db1_only;
    $db_diffs{$dbase2}{tables} = $db2_only;
    $db_diffs{$dbase1}{fields} = [];
    $db_diffs{$dbase2}{fields} = [];

    $summary .= "=======================================\n";
    $summary .= "Comparison of two databases\n";
    $summary .= "Database 1: $dbase1\n";
    $summary .= "Database 2: $dbase2\n";
    if ( $from_release || $patched || $upgraded ) {
        $summary .= "(";
        if ($from_release) {
            $summary .= "Generated from latest release's initialization files; ";
        }
        else {
            $summary .= "Began as copy of $opt_dbase2\n";
        }
        if ($patched) {
            $summary .= "All available patches applied; ";
        }
        if ($upgraded) {
            $summary .= "Upgraded; ";
        }
        $summary .= ")\n";
    }
    #################################################
    ##  Table Differences                        ####
    #################################################

    $summary .= log_section('Table Differences');
    foreach my $db ( "$dbase1", "$dbase2" ) {
        $summary .= "--------------------------------------\n";
        $summary .= "*** Tables ONLY IN $db database: ***\n";
        if ( defined $db_diffs{$db}{tables} ) {
            if ( scalar( @{ $db_diffs{$db}{tables} } ) > 0 ) {
                foreach my $table ( sort @{ $db_diffs{$db}{tables} } ) {
                    if ( _check_if_obsolete( -dbase => $db, -table => $table, -dbc => $db_info{$db}{dbc} ) && $ignore_obs ) {
                        $Report->set_Message("Table obsolete: $table");
                    }
                    else {
                        $summary .= "$table\n";
                        $Report->set_Error("Table unique to $db: $table");
                    }
                }
            }
            else {
                $summary .= "(No tables unique to $db database)\n";
            }
        }
    }

    #################################################
    ## Field  Differences                        ####
    #################################################
    my $data_difference_report;
    my $struct_difference_report;
    $summary .= log_section('Field Differences');
    unless ( !$intersec ) {
        $Report->set_Message("Finding differences in common tables...");
    }
    foreach my $table ( sort @{$intersec} ) {
        my @db1_fields = sort keys %{ $db_info{$dbase1}{tables}{$table}{fields} };
        my @db2_fields = sort keys %{ $db_info{$dbase2}{tables}{$table}{fields} };
        if ($dumps) {
            my $diff_log = _gen_diff_files( -dbase1 => $dbase1, -dbase2 => $dbase2, -table => $table );
            $summary .= "$diff_log\n" if $diff_log;
            $Report->set_Error("Diff found:\n$diff_log") if $diff_log;
        }
        else {
            my ( $field_intersec, $db1_fields, $db2_fields ) = RGmath::intersection( \@db1_fields, \@db2_fields );
            if ($db1_fields) {
                foreach my $field ( @{$db1_fields} ) {
                    push @{ $db_diffs{$dbase1}{fields} }, "$table.$field";
                }
            }
            if ($db2_fields) {
                foreach my $field ( @{$db2_fields} ) {
                    push @{ $db_diffs{$dbase2}{fields} }, "$table.$field";
                }
            }
            if ( $field_intersec && $core && !( int @$db1_fields ) && !( int @$db2_fields ) ) {
                ###### Being here means tables are exactly the same in structure and one of the databases is a core
                #################################################
                ## Value  Differences                        ####
                #################################################
                if ( !( grep /\b$table\b/, @ignore_tables ) ) {
                    $data_difference_report .= _get_table_value_difference( -table => $table, -dbase1 => $dbase1, -dbase2 => $dbase2, -db_info => \%db_info );
                }

            }
            if ( $field_intersec && !( int @$db1_fields ) && !( int @$db2_fields ) ) {
                ###### Being here means tables are exactly the same in structure and one of the databases is a core
                #################################################
                ## Table Structure Differences               ####
                #################################################
                $struct_difference_report .= _get_structure_diff( -table => $table, -dbase1 => $dbase1, -dbase2 => $dbase2, -db_info => \%db_info );

                #    print _get_table_struct_difference (-table => $table , -dbase1=>$dbase1,-dbase2=>$dbase2,-db_info=>\%db_info);
            }

        }
    }
    _clean_temp_files();

    if ( !$dumps ) {
        foreach my $db ( "$dbase1", "$dbase2" ) {
            $summary .= "*** Fields ONLY in $db database (in common tables): ***\n";
            my $lasttable;
            if ( defined $db_diffs{$db}{fields} ) {
                if ( scalar( @{ $db_diffs{$db}{fields} } ) > 0 ) {
                    foreach my $field ( sort @{ $db_diffs{$db}{fields} } ) {
                        if ( _check_if_obsolete( -dbase => $db, -field => $field, -dbc => $db_info{$db}{dbc} ) && $ignore_obs ) {
                            $Report->set_Message("Field Obsolete: $field ");
                        }
                        else {
                            $Report->set_Error("Field unique to $db: $field");
                            $field =~ /(.+)\.(.+)/;
                            my $table = $1;
                            if ( $table ne $lasttable ) {
                                ## separate fields by table
                                $lasttable = $table;
                                $summary .= "\n";
                            }
                            $summary .= "$field\n";
                        }

                    }
                }
                else {
                    $summary .= "...None\n";
                }
            }
        }
    }
    else {
        $summary .= "LEGEND FOR COMPARISON:\n";
        $summary .= "Lines beginning with '<' refer to $dbase1 dumps\n";
        $summary .= "Lines beginning with '>' refer to $dbase2 dumps\n";
        $Report->set_Message("Removing all temp files...");
        _clear_temp_files( -dbase1 => $dbase1, -dbase2 => $dbase2, -types => 'all' );
        $Report->set_Message("Files cleared");
    }

    if ($struct_difference_report) {
        $Report->set_Message("There are structure differences between common tables with same fields");
        $summary .= "\n=======================================================\n";
        $summary .= " Structure differneces between common tables with same fields \n";
        $summary .= " $struct_difference_report ";
        $summary .= "\n=======================================================\n";

    }
    if ($data_difference_report) {
        $Report->set_Error("There are Data differences between common tables");
        $summary .= "\n=======================================================\n";
        $summary .= " Data differences between common tables \n";
        $summary .= " $data_difference_report ";
        $summary .= "\n=======================================================\n";

    }

    return $summary;
}
########################################
sub _get_structure_diff {
########################################
    # Description:
    #   - This fucntion takes in two databases and a table name and returns the differences in table structures
    # Output:
    #   - The difference between values if any
    #   -  Null if no difference
########################################
    my %args       = filter_input( \@_ );
    my $table      = $args{-table};
    my $dbase1     = $args{-dbase1};
    my $dbase2     = $args{-dbase2};
    my %db_info    = %{ $args{-db_info} };
    my $dbc1       = $db_info{$dbase1}{dbc};
    my $dbc2       = $db_info{$dbase2}{dbc};
    my $seperation = "\n-------------------------------\n";

    my $temp_file_values_dbase2 = _dump_table_struct_into_temp( -table => $table, -dbc => $dbc2, -variation => 'A' );
    my $temp_file_values_dbase1 = _dump_table_struct_into_temp( -table => $table, -dbc => $dbc1, -variation => 'B' );
    my $difference = _get_difference( -table => $table, -structure => 1, -file1 => $temp_file_values_dbase1, -file2 => $temp_file_values_dbase2, -dbase1 => $dbase1, -dbase2 => $dbase2 );

    return $seperation . $difference if $difference;
    return;
}

########################################
sub _get_table_value_difference {
########################################
    # Description:
    #   - This fucntion takes in two databases and a table name and returns the differences
    # Output:
    #   - The difference between values if any
    #   -  Null if no difference
    # Note:
    #   - dbase2 needs to be core so that the dump files dont become huge
########################################
    my %args    = filter_input( \@_ );
    my $table   = $args{-table};
    my $dbase1  = $args{-dbase1};
    my $dbase2  = $args{-dbase2};
    my %db_info = %{ $args{-db_info} };
    my $dbc1    = $db_info{$dbase1}{dbc};
    my $dbc2    = $db_info{$dbase2}{dbc};
    my $difference_report;
    my $temp_file_values_dbase;
    my $temp_file_values_core;
    my $seperation            = "\n-------------------------------\n";
    my $primary_id            = _get_primary_id($table);
    my $number_of_records     = $dbc2->Table_find( $table, $primary_id );
    my $second_num_of_records = $dbc1->Table_find( $table, $primary_id );

    if ($number_of_records) {

        #&& $second_num_of_records
        $temp_file_values_core = _dump_table_values_into_temp( -table => $table, -dbc => $dbc2, -variation => 'A' );
        $temp_file_values_dbase = _dump_table_values_into_temp( -table => $table, -dbc => $dbc1, -variation => 'B', -limit => $number_of_records );
        my $difference = _get_difference( -file1 => $temp_file_values_core, -file2 => $temp_file_values_dbase, -dbase1 => $dbase1, -dbase2 => $dbase2, -table => $table );

        return $seperation . $difference if $difference;
        return;
    }
    elsif ($second_num_of_records) {
        return $seperation . "Table: $table contains $second_num_of_records  EXTRA records \n";
    }
    else {
        return;
    }
    return;
}

########################################
sub _get_primary_id {
########################################
    #   Description:
    #       - takes in table name and guesses the primary id of the table
########################################
    my $table = shift;
    my $primary_id;
    my @fields                     = $dbc2->get_fields($table);
    my $possible_primary_id        = $table . '_ID';
    my $second_possible_primary_id = $table . '_Name';
    if ( grep /$possible_primary_id/, @fields ) { $primary_id = $possible_primary_id }
    elsif ( grep /$second_possible_primary_id/, @fields ) { $primary_id = $second_possible_primary_id }
    else                                                  { $primary_id = $fields[0] }
    return $primary_id;
}

########################################
sub _clean_temp_files {
########################################
    #   This function deletes the temp_files created by _dump_Dbase_into_temp
########################################
    my $dump_path_A = _temp_log_dir() . "/data_" . 'A';
    my $dump_path_B = _temp_log_dir() . "/data_" . 'B';
    my $command     = "rm $dump_path_A/* --force";
    my $fb          = try_system_command($command);
    $command = "rm  $dump_path_B/* --force";
    $fb      = try_system_command($command);

    return;
}

########################################
sub _dump_table_struct_into_temp {
########################################
    #   Description:
    #       - This function dump the strcuture of a given table into a .sql file
########################################
    my %args      = filter_input( \@_ );
    my $table     = $args{-table};
    my $dbc       = $args{-dbc};
    my $limit     = $args{-limit};
    my $variation = $args{-variation} || 'A';

    my $database  = $dbc->{dbase};
    my $user      = $dbc->{login_name};
    my $pass      = $dbc->{login_pass};
    my $host      = $dbc->{host};
    my $mysql_dir = '/usr/bin';

    my $dump_path = _temp_log_dir() . "/data_" . $variation;
    if ( !( -d "$dump_path" ) ) {
        my $fb = try_system_command("mkdir $dump_path");
        if ($fb) { die "Couldn't make dump folder: $dump_path\n"; }
    }

    my $options = qq{-u $user --password=$pass -h $host};
    my $file    = "$dump_path/$table";

    ##
    my $dump_options = qq{--opt -all -q --quote_names --no-data --compact};

    my $dump_cmd = "$mysql_dir/mysqldump $options $dump_options $database $table > $dump_path/$table.sql";
    my $fb       = try_system_command("$dump_cmd");

    my $final_file = "$dump_path/$table.sql";

    my $dumped;
    if ( $fb =~ /error/i ) {
        $dumped = 0;
    }
    else {
        $dumped = $final_file;
    }
    return $dumped;

}

########################################
sub _dump_table_values_into_temp {
########################################
    #   Description:
    #       - This function dump the data of a given table into a .txt file
########################################
    my %args      = filter_input( \@_ );
    my $table     = $args{-table};
    my $dbc       = $args{-dbc};
    my $limit     = $args{-limit};
    my $variation = $args{-variation} || 'A';

    my $database  = $dbc->{dbase};
    my $user      = $dbc->{login_name};
    my $pass      = $dbc->{login_pass};
    my $host      = $dbc->{host};
    my $mysql_dir = '/usr/bin';

    my $dump_path = _temp_log_dir() . "/data_" . $variation;
    if ( !( -d "$dump_path" ) ) {
        my $fb = try_system_command("mkdir $dump_path");
        if ($fb) { die "Couldn't make dump folder: $dump_path\n"; }
    }

    my $options = qq{-u $user --password=$pass -h $host};
    my $file    = "$dump_path/$table";
    my $query   = "SELECT * FROM $table";
    if ($limit) {
        $query .= " LIMIT $limit";
    }
    my $command = qq{$mysql_dir/mysql $options $database -e "$query INTO OUTFILE '$dump_path/$table.txt'"  };
    my $fb      = try_system_command("$command");

    my $final_file = "$dump_path/$table.txt";

    my $dumped;
    if ( $fb =~ /error/i ) {
        $dumped = 0;
    }
    else {
        $dumped = $final_file;
    }
    return $dumped;

}

########################################
sub _get_difference {
########################################
    #   -Description:
    #       This fucntion takes a table , two different dumps of that table and their respective database names
    #       and generates a report of their differences
########################################

    my %args     = filter_input( \@_ );
    my $file_A   = $args{-file1};
    my $file_B   = $args{-file2};
    my $dbase1   = $args{-dbase1};
    my $dbase2   = $args{-dbase2};
    my $table    = $args{-table};
    my $struct   = $args{-structure};         ## Flag indicating stcuture difference
    my $diff_cmd = " diff $file_A $file_B";
    my @missings;
    my @extras;
    my @results = split "\n", try_system_command("$diff_cmd");
    my $report;

    for my $result (@results) {
        if ( $result =~ /\>(.+)/ ) {
            push @extras, $1;
        }
        elsif ( $result =~ /\<(.+)/ ) {
            push @missings, $1;
        }
    }

    my $count_extra   = @extras;
    my $count_missing = @missings;
    if ( !$count_extra && !$count_missing ) { return; }

    ## Header for report
    if ( !$struct ) {
        $report = "Table $table: " . "Total missing records: $count_missing and total extra records $count_extra \n";
    }

    ## Body of report
    if ($count_missing) {
        if   ($struct) { $report .= "Table '$table' from '$dbase1': \n" }
        else           { $report .= "Missing records:\n" }
    }
    for my $missing (@missings) {
        $report .= "$missing\n";
    }

    if ($count_extra) {
        if   ($struct) { $report .= "Table '$table' from '$dbase2': \n" }
        else           { $report .= "Extra records\n" }
    }
    for my $extra (@extras) {
        $report .= "$extra\n";
    }

    return $report;
}

################
sub log_section {
################
    my $title = shift;
    my $stars = shift || 3;    ## number of asterisks to surround title with ##

    my $length = length($title) + 2 * $stars + 2;

    my $output = '*' x $length . "\n";
    $output .= '*' x $stars;
    $output .= " $title ";
    $output .= '*' x $stars . "\n";
    $output .= '*' x $length . "\n";

    return $output;
}

#e.g. _dump_table(-dbc=>$dbc,-table=>$table);
#################
sub _dump_table {
#################
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $table = $args{-table};

    my $dbase     = $dbc->{dbase};
    my $user      = $dbc->{login_name};
    my $pass      = $dbc->{login_pass};
    my $host      = $dbc->{host};
    my $mysql_dir = '/usr/bin';

    my $dump_path = _temp_log_dir() . "/schema";
    if ( !( -d "$dump_path" ) ) {
        my $fb = try_system_command("mkdir $dump_path");
        if ($fb) { die "Couldn't make dump folder: $dump_path\n"; }
    }
    my $options      = qq{-u $user --password=$pass -h $host};
    my $dump_options = qq{--opt -all -q --quote_names --no-data --compact};

    my $dump_cmd = "$mysql_dir/mysqldump $options $dump_options $dbase $table > $dump_path/$dbase.$table.sql";
    my $fb = try_system_command( "$dump_cmd", -report => $Report );

    my $dumped;
    if ( $fb =~ /error/i ) {
        $dumped = 0;
    }
    else {
        $dumped = 1;
    }

    return $dumped;

}

#e.g. my $different = _gen_diff_files(-dbase1=>$dbase1,-dbase2=>$dbase2,-table=>$table);
####################
sub _gen_diff_files {
####################
    my %args   = filter_input( \@_ );
    my $dbase1 = $args{-dbase1};
    my $dbase2 = $args{-dbase2};
    my $table  = $args{-table};

    my $table_diff_log;

    my $tmp_path = _temp_log_dir() . "/schema";
    my $path     = "$tmp_path/$dbase1" . "_vs_" . "$dbase2";
    if ( !( -d "$path" ) ) {
        try_system_command("mkdir $path");
    }

    my $diff_cmd         = "diff $tmp_path/$dbase1.$table.sql $tmp_path/$dbase2.$table.sql";
    my $target_full_path = "$path/$table.diff";

    my $fb = try_system_command("$diff_cmd");
    if ($fb) {
        open( DIFF, ">$target_full_path" );
        print DIFF "$fb\n";
        close DIFF;
    }

    my $different;
    if ( -f "$target_full_path" ) {
        $table_diff_log = ">>>>>>>>>>>>>>>>>>>>>>>\n";
        $table_diff_log .= "DIFF IN TABLE: $table\n";
        $table_diff_log .= try_system_command("cat $target_full_path");

        $table_diff_log .= "END DIFF: $table\n";
        $table_diff_log .= "<<<<<<<<<<<<<<<<<<<<<<<<";
    }
    else {
        $table_diff_log = '';
    }

    return $table_diff_log;

}

#######################
sub _clear_temp_files {
#######################
    my %args   = filter_input( \@_, -mandatory => "dbase1,dbase2" );
    my $dbase1 = $args{-dbase1};
    my $dbase2 = $args{-dbase2};
    my $types  = $args{-types};
    my $diff   = 1 if ( $args{-types} =~ /diff/ );
    my $sql    = 1 if ( $args{-types} =~ /sql/ );
    my $rm_all = 1 if ( $args{-types} =~ /^all$/ );

    my $tmp_dir     = _temp_log_dir();
    my $schema_path = _temp_log_dir() . "/schema";
    if ( $sql || $rm_all ) {
        my $rm_sql_cmd = "rm $schema_path/*.sql";
        $Report->set_Message("Removing *.sql files from $schema_path");
        try_system_command( "$rm_sql_cmd", -report => $Report );
    }

    if ( $types =~ /diff/i || $rm_all ) {
        my $diff_path = "$schema_path/$dbase1" . "_vs_" . "$dbase2";
        if ( -d $diff_path ) {
            my $rm_diff_cmd = "rm $diff_path/*.diff";
            $Report->set_Message("Removing *.diff files from $diff_path");
            try_system_command( "$rm_diff_cmd", -report => $Report );
            my $rm_path_cmd = "rmdir $diff_path";
            $Report->set_Message("Removing diff folder: $diff_path");
            try_system_command( "$rm_path_cmd", -report => $Report );
            my $rm_schema_cmd = "rmdir $schema_path";
            $Report->set_Message("Removing schema dump directory: $schema_path");
            try_system_command( "$rm_schema_cmd", -report => $Report );
        }
    }
    if ($rm_all) {
        my $rm_files = "rm $tmp_dir/*";
        $Report->set_Message("Removing all other files from temp dir: $tmp_dir");
        try_system_command("$rm_files");
        my $rm_compare_cmd = "rmdir $tmp_dir";
        $Report->set_Message("Removing temp directory: $tmp_dir");
        try_system_command("$rm_compare_cmd");
    }
    return 1;
}

# e.g. my @tables = _get_tables(-dbc=>$dbc);
##################
sub _get_tables {
#################3
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $query = "SHOW TABLES";
    my $sth   = $dbc->dbh()->prepare($query);
    $sth->execute();

    my @tables;

    while ( my @row = $sth->fetchrow_array ) {
        my $table = $row[0];
        push @tables, $table;
    }
    return @tables;
}

#e.g. my @fields = _get_fields(-dbc=>$dbc,-table=>$table);
##################
sub _get_fields {
##################
    my %args = filter_input( \@_ );

    my $dbc   = $args{-dbc};
    my $table = $args{-table};

    my $dbase = $dbc->{dbase};

    my $query = "DESC $dbase.$table";
    my $sth   = $dbc->dbh()->prepare($query);

    $sth->execute();

    my @fields;
    while ( my @row = $sth->fetchrow_array ) {
        my $field_name = $row[0];
        push @fields, $field_name;
    }

    return @fields;
}

#e.g. my @field_info = _get_field_info(-dbc=>$dbc,-field=>"$table.$field");
###################
sub _get_field_info {
###################
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $field = $args{-field};
    my ( $table, $name ) = split '\.', $field;

    my $dbase = $dbc->{dbase};

    my $query = "DESC $dbase.$table";

    my $sth = $dbc->dbh()->prepare($query);
    $sth->execute();

    my %field_info;

    while ( my @row = $sth->fetchrow_array() ) {
        if ( $row[0] eq "$name" ) {
            $field_info{type} = $row[1];
        }
    }
    return %field_info;

}

# e.g. _build_db(-dbc_from=>$dbc);
######################
sub _build_db {
####################
    my %args     = filter_input( \@_, -mandatory => 'dbc_from' );
    my $dbc_from = $args{-dbc_from};
    my $name     = $args{-name};
    my $host     = $args{-host};
    my $user     = $args{-user};
    my $pass     = $args{-password};
    my $Report   = $args{-report};

    my $target_dump_dir  = _temp_log_dir() . "/schema";
    my $target_dump_file = "$name" . "_backup.sql";
    my $target_dump_full = "$target_dump_dir/$target_dump_file";

    $Report->set_Message("Dumping $dbc_from->{host}:$dbc_from->{dbase} to temp file: $target_dump_full");

    my $dump_cmd = "/usr/bin/mysqldump";
    $dump_cmd .= " -h $dbc_from->{host} -u $dbc_from->{login_name} -p$dbc_from->{login_pass}";
    $dump_cmd .= " $dbc_from->{dbase}";

    my $full_dump_cmd = "$dump_cmd > $target_dump_full";
    $Report->set_Detail("Dump cmd: $full_dump_cmd");
    my $fb;
    $fb = try_system_command( $full_dump_cmd, -report => $Report );

    my $mysql_cmd = "/usr/bin/mysql";
    $mysql_cmd .= " -h $host -u $user -p$pass";
    my $mysql_cmd_no_pass = "/usr/bin/mysql -h $host -u $user -p<pass>";
    my $create_cmd        = "CREATE DATABASE $name";
    $Report->set_Message("Creating temp database... $host:$name");
    try_system_command( "$mysql_cmd -e '$create_cmd'", -report => $Report );
    my $mysql_full_cmd = "$mysql_cmd $name < $target_dump_full";
    $Report->set_Message("Piping the target's dump file to the temp database: $host:$name");
    $Report->set_Detail("MySQL CMD: $mysql_cmd_no_pass $name < $target_dump_full");
    $fb = try_system_command( $mysql_full_cmd, -report => $Report );

    try_system_command( "rm $target_dump_full", -report => $Report );

    return;

}

####################
sub _build_core_db {
#####################
    my %args    = filter_input( \@_ );
    my $name    = $args{-name};
    my $host    = $args{-host};
    my $user    = $args{-user};
    my $pass    = $args{-password};
    my $version = $args{-version};
    my $Report  = $args{-report};

    if ( !( $user && $pass ) ) {
        $user = Prompt_Input( -prompt => "MySQL Username? " );
        $pass = Prompt_Input( -prompt => "MySQL password? ", -type => 'pass' );
    }

    my $mysql_dir       = "/usr/bin";
    my $create_cmd      = "CREATE DATABASE $name";
    my $full_create_cmd = "$mysql_dir/mysql -h $host -u $user -p$pass -e '$create_cmd'";

    $Report->set_Message($full_create_cmd);

    my $feedback = try_system_command("$full_create_cmd");

    my $bin_dir = "$FindBin::RealBin";

    my $script     = "build_core_db.pl";
    my $cmd_append = "-dbase $name";
    $cmd_append .= " -host $host -password $pass -user $user -version $version";
    my $cmd_append_no_pass = "-dbase $name -host $host -password <pass> -user $user -version $version";

    my $full_cmd = "$bin_dir/$script $cmd_append";
    $Report->set_Message("CMD TO CALL core-building script: $bin_dir/$script $cmd_append_no_pass");
    my $fb = try_system_command( "$full_cmd", -report => $Report );

    return 1;
}

#####################
sub _check_if_obsolete {

    my %args    = filter_input( \@_ );
    my $dbase   = $args{-dbase};
    my $table   = $args{-table};
    my $q_field = $args{-field};
    my $type    = $args{-type};
    my $dbc     = $args{-dbc};
    if ($table) {
        my ($status) = $dbc->Table_find( 'Package,DBTable', 'DBTable_ID', " WHERE DBTable_Name = '$table' and FK_Package__ID = Package_ID and Package.Package_Name = 'Obsolete'" );
        return $status;
    }
    elsif ( $q_field =~ /(.+)\.(.+)/ ) {
        my $field_table = $1;
        my $field       = $2;
        my ($status) = $dbc->Table_find( 'Package,DBField', 'DBField_ID', " WHERE Field_Name = '$field' and Field_Table = '$field_table' and  FK_Package__ID = Package_ID and Package.Package_Name = 'Obsolete'" );
        return $status;
    }
    ## 1 means obsolete means obsolete

    return;
}

#####################
sub _install_addons {
#####################
    my %args         = filter_input( \@_ );
    my $Installation = $args{-installation};
    my $addons_ref   = $args{-addons};

    my @addon_names;
    if ($addons_ref) {
        @addon_names = @{$addons_ref};
    }
    $Report->set_Message("Installing add-on packages...");
    foreach my $addon (@addon_names) {
        $Report->set_Message("Installing $addon..");
        my $installed = $Installation->install_Package($addon);
    }

    return 1;
}

#####################
sub _upgrade_db {
#####################
    my %args         = filter_input( \@_ );
    my $Installation = $args{-installation};
    my $Report       = $args{-report};

    my $db_name = $Installation->{dbc}{dbase};
    my $db_host = $Installation->{dbc}{host};
    if ( $db_name !~ /.*TEMP$/ ) {
        $Report->set_Detail( Call_Stack() );
        $Report->set_Message("ARRGGH!!, you shouldn't be trying to upgrade this database its not marked with 'TEMP' suffix!");
        die "database to be upgraded not marked with 'TEMP' suffix, please use upgrade_DB.pl directly if you wish to upgrade a database\n";
    }

    my $bin_dir        = $FindBin::RealBin;
    my $upgrade_script = "upgrade_DB.pl";
    my $temp_log_dir   = _temp_log_dir();

    my $upgrade_args = "-D $Installation->{dbc}{host}:$Installation->{dbc}{dbase} -u $Installation->{dbc}{login_name} -p $Installation->{dbc}{login_pass} -A all -b all -f -S -t";
    my $upgrade_output;
    $upgrade_output = "1> $temp_log_dir/upgrade_DB.$db_host.$db_name.log 2> $temp_log_dir/upgrade_DB.$db_host.$db_name.err" if ( !$opt_testing );

    my $full_upgrade_cmd         = "$bin_dir/$upgrade_script $upgrade_args $upgrade_output";
    my $full_upgrade_cmd_no_pass = "$bin_dir/$upgrade_script -D $Installation->{dbc}{host}:$Installation->{dbc}{dbase} -u $Installation->{dbc}{login_name} -p <pass> -A all -b all -f -S -t $upgrade_output";

    $Report->set_Message("Upgrading temp database...");
    $Report->set_Message("UPGRADE CMD: $full_upgrade_cmd_no_pass");
    my $feedback = try_system_command( "$full_upgrade_cmd", -report => $Report );
    foreach my $line ( split "\n", $feedback ) {
        if ( $line =~ /ERROR/ ) { $Report->set_Error("$line"); }
        else {
            $Report->set_Detail("$line");
        }
    }
    return;

}
############################
sub _get_latest_release {
#############################

    my $release_dir = "$FindBin::RealBin/../install/init/release/";

    my %folders;
    find sub { $folders{$_} = 1 if -d }, $release_dir;

    my $current = 0;
    foreach my $key ( keys %folders ) {
        if ( $key =~ /^\d+\.\d+$/ ) {
            if ( $key > $current ) {
                $current = $key;
            }
        }
    }
    return $current;
}

# my $version_released = _check_if_released('2.7');
########################
sub _check_if_released {
########################
    my $version = shift;

    my $released;
    if ( _get_latest_release() < $version ) {
        $released = 0;
    }
    else {
        $released = 1;
    }

    return $released;
}

# my $temp_log_dir = temp_log_dir();
##################
sub _temp_log_dir {
##################

    my $temp_log_dir = "$Configs{data_log_dir}/compare_DB";
    if ( !( -d $temp_log_dir ) ) {
        try_system_command "mkdir $temp_log_dir";
        if ( !( -d $temp_log_dir ) ) {
            die "Death of a script: no temp log dir available: $temp_log_dir\n ";
        }
    }

    return $temp_log_dir;

}

# create subdir/test in home/aldente/versions/alanl/docs/schema/
# create database test_schema (err check: if can't create db)
# load the scripts in the folders for version $a into test_schema
# run upgrade_DB on test_schema
# $schema_dir = ~/docs/schema/$a
# for each table:
#			    $a
# diff $schema_dir/test/$table.sql $schema_dir/$b/$table.sql
# record any diffs as warnings in cron summary for compare_DB

# delete the contents in the test dir and drop the test_schema

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    ## Compare two different databases:
    compare_DB.pl -dbase1 host1:dbase1 -dbase2 host2:dbase2 -user super_cron -pass ******
   
    ## Compare two different databases one of which is a core (does datacheck as well):
    compare_DB.pl -dbase1 host1:dbase1 -core host2:dbase2   -user super_cron -pass ******

    -ignore_obsolete:   ignores obsolete fields in diffs, just reports them as obsolete



HELP

}
