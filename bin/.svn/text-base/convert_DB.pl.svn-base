#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use Storable qw(dclone);

# Get options
use Getopt::Long;
use vars qw($opt_D $opt_u $opt_p $opt_h $opt_shortpk $opt_fixfk $opt_T $opt_i);
&GetOptions('D=s'      => \$opt_D,
	    'u=s'      => \$opt_u,
	    'p=s'      => \$opt_p,
	    'h'        => \$opt_h,
	    'shortpk=s'=> \$opt_shortpk,
	    'fixfk'    => \$opt_fixfk,
	    'T=s'        => \$opt_T,
	    'i'        => \$opt_i
	    ); 

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::DBIO;
 
use SDB::CustomSettings;
use RGTools::RGIO;
use alDente::SDB_Defaults;

if ($opt_h || !$opt_D || !$opt_u) {
    _print_help_info();
    exit;
}

my $host = $Defaults{mySQL_HOST};
my $dbase = $opt_D;
my $index_only = $opt_i;
# Resolve database into host and database
if ($opt_D =~ /(.*):([\w\-]*)/) {
    $host = $1;
    $dbase = $2;
}

my $password = $opt_p || Prompt_Input(-type=>'password',-prompt=>'Password: >');

my $dbc = SDB::DBIO->new();
my $dbc->connect(-host=>$host,-dbase=>$dbase,-user=>$opt_u,-password=>$password);

my @Tables;
if ($opt_T) {@Tables = split /,/, $opt_T}

my $cmd;
my $arg1;
my $arg2;
my $arg3;

# First turn off foreign key check
unless ($index_only) {
    $cmd = "SET FOREIGN_KEY_CHECKS=0";
    print ">>>Turning off foreign key checks. Trying '$cmd'...\n";
    ($arg1,$arg2,$arg3) = $dbc->execute_command(-command=>$cmd);
    print "$arg3\n";
}

# Get all tables from the database
my %tables;
$cmd = "SHOW TABLES";
print ">>>Getting all tables from database. Trying '$cmd'...\n";

my $sth = $dbc->query(-query=>$cmd,-finish=>0);
my $tables = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'CA');

foreach my $table (@$tables) {
    $tables{$table} = 1;
    if (@Tables && !(grep /^$table$/, @Tables)) {next}
    unless ($index_only) {
	print "-"x80 . "\n";
	$cmd = "ALTER TABLE `$table` Type=InnoDB";
	print ">>>Converting table '$table' to InnoDB type. Trying '$cmd'...\n";
	($arg1,$arg2,$arg3) = $dbc->execute_command(-command=>$cmd);
	print "$arg3\n";
    }
}

foreach my $table (@$tables) {
    if (@Tables && !(grep /^$table$/, @Tables)) {next}
    print "-"x80 . "\n";
    # Find all the foreign key fields
    my %fks;
    $cmd = "DESC `$table`";
    print ">>>Getting fields of table '$table'. Trying '$cmd'...\n";
    
    $sth = $dbc->query(-query=>$cmd,-finish=>0);
    my $fields = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'AofH');

    foreach my $field (@$fields) {
	my $field_name = $field->{Field};
	my ($ref_table,$ref_field) = foreign_key_check($field_name);
	if ($ref_table,$ref_field) {
	    print "Found foreign key field $field_name -> $ref_table.$ref_field\n";
	    $fks{$field_name}{ref_table} = $ref_table;
	    if ($opt_shortpk) {
		foreach my $pk (split /,/, $opt_shortpk) {
		    $ref_field =~ s/\w+\_$pk$/$pk/;
		}
	    }
	    $fks{$field_name}{ref_field} = $ref_field;
	    $fks{$field_name}{type} = $field->{Type};
	    $fks{$field_name}{null} = $field->{Null};
	    $fks{$field_name}{default} = $field->{Default};
	    $fks{$field_name}{extra} = $field->{Extra};
	}
    }

    my %index_fields;
    if (keys %fks) {
	# Get all the indices available for this table
	$cmd = "SHOW INDEX FROM `$table`";
	print ">>>Getting indices of table '$table'. Trying '$cmd'...\n";
	$sth = $dbc->query(-query=>$cmd,-finish=>0);
	my $indices = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'AofH');

	foreach my $index (@$indices) {
	    my $field_name = $index->{Column_name};
	    if ($index->{Seq_in_index} == 1) {  ### Index for foreign key must be the first one in sequence
		$index_fields{$field_name} = 1;
	    }
	}

	print ">>>Attempting to create indices for foreign key fields...\n";
	# Now for each FKs, see if index already created. If not, then created it.
	foreach my $fk (keys %fks) {
	    if (exists $index_fields{$fk}) {
		print "Index already exist for $fk.\n";
	    }
	    else {
		$cmd = "ALTER TABLE `$table` ADD INDEX (`$fk`)";
		print "Creating index for $fk. Trying '$cmd'...\n";
		($arg1,$arg2,$arg3) = $dbc->execute_command(-command=>$cmd);
		print "$arg3\n";	
	    }
	    # break if index_only flag is set
	    if ($index_only) {
		next;
	    }

	    # Ensure data type for foreign key field is same as primare key field
	    my $ref_table = $fks{$fk}{ref_table};
	    my $ref_field = $fks{$fk}{ref_field};
	    my $type = $fks{$fk}{type};

	    my $create_fk = 0;

	    if (exists $tables{$ref_table}) { # First see if the reference table exists
		$cmd = "SHOW COLUMNS FROM `$ref_table` LIKE '$ref_field'";
		
		$sth = $dbc->query(-query=>$cmd,-finish=>0);
		my $ref_info = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'RH');		
		
		if ($ref_info->{Field} and $ref_info->{Type} eq $type) {$create_fk = 1}
		elsif ($ref_info->{Field}) {
		    print "Data type of foreign key field '$fk' ($type) does NOT match data type of $ref_table.$ref_field ($ref_info->{Type})\n";
		    if ($opt_fixfk) {
			my $null = $fks{$fk}{null};
			my $default = $fks{$fk}{default};
			my $extra = $fks{$fk}{extra};

			($null eq 'YES') ? ($null = '') : ($null = 'NOT NULL');
			$default ? ($default = "DEFAULT '$default'") : ($default = ''); 
			unless ($extra) {$extra = ''}

			$cmd = "ALTER TABLE `$table` MODIFY `$fk` $ref_info->{Type} $null $default $extra";
			print "Altering data type of foreign key field '$fk' to '$ref_info->{Type}'. Trying '$cmd'...\n";
			($arg1,$arg2,$arg3) = $dbc->execute_command(-command=>$cmd);
			print "$arg3\n";
			$create_fk = 1 if ($arg3 =~ /success/);
		    }
		}
		else {
		    print "Field $ref_table.$ref_field does NOT exist.\n";
		}
	    }
	    else {
		print "Table '$ref_table' does NOT exist.\n";
	    }

	    if ($create_fk) {
		
		#check if the foreign key already exists
		#FOREIGN KEY (`FK_Plate__ID`) REFERENCES `Plate` (`Plate_ID`)
		$cmd = "SHOW CREATE TABLE `$table`";
		
		$sth = $dbc->query(-query=>$cmd,-finish=>0);
		my $data = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'RH');

		my $string = $data->{'Create Table'};

		if ($string=~/FOREIGN KEY \(\`$fk\`\) REFERENCES \`$ref_table\` \(\`$ref_field/)
		{
		    print "FK Constraint 'FOREIGN KEY $fk REFERENCES $ref_table ($ref_field)' already exists\n";
		}
		else {
		# Create foreign key constraints
		
		$cmd = "ALTER TABLE `$table` ADD FOREIGN KEY `$fk` (`$fk`) REFERENCES `$ref_table` (`$ref_field`)";
		print "Creating foreign key constraint for $fk -> $ref_table.$ref_field. Trying '$cmd'...\n";
		($arg1,$arg2,$arg3) = $dbc->execute_command(-command=>$cmd);
		print "$arg3\n";		    
	        }
	    }
	    else {
		print "Foreign key constraint NOT created for $fk -> $ref_table.$ref_field\n";
	    }
	}
    }
}


# Finally turn on foreign key check
unless ($index_only) {
    $cmd = "SET FOREIGN_KEY_CHECKS=1";
    print ">>>Turning on foreign key checks. Trying '$cmd'...\n";
    ($arg1,$arg2,$arg3) = $dbc->execute_command(-command=>$cmd);
    print "$arg3\n";
}

$dbc->disconnect();


#########################
sub _print_help_info {
#########################
print<<HELP;

File:  convert_DB.pl
####################
This script converts a MyISAM database to InnoDB database and automatically create the foreign key constraints.

Options:
##########

------------------------------
1) Database login information:
------------------------------
-D     The database to be backup. Format is 'host:database' (e.g. -D lims02:sequence)
-u     User for database login (e.g. -u bob)
-p     Password for login (optional - if not provided then user will be prompted for it)

---------------------------
2) Additional options:
---------------------------
-h         Print help info.

-shortpk   If specified, then the primary key field will assume the short format.
           e.g. For a foreign key field of 'FK_Sequence__ID', it assumes the primary key field will be 'Sequence_ID'.
                If "-shortpk=ID" is specified, then the primary key field will simply be 'ID'.

-fixfk     When creating foreign key constraints, the foreign key field need to have the same data type as the primary key field.
           If "-fixfk" is specified, then in the case of mismatch the foreign key field will be altered to match the primary key field.

-T         A comma-delimited list of tables to convert. If not specified, then all tables in the database will be converted.

-i         Fix only foreign key indices.

HELP
}
