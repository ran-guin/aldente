#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use Getopt::Std;
use File::stat;
use Statistics::Descriptive;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
 
use SDB::CustomSettings;
use SDB::DBIO;
use Sequencing::Sequencing_API;

use vars qw($opt_update $opt_type $opt_file $opt_reference $opt_alias $opt_host $opt_dbase $opt_debug $opt_user $opt_pass $opt_quiet $opt_ignore $opt_set_field $opt_help $opt_h $opt_delim $opt_scan);
use vars qw($testing $Connection $uploads_dir);

use Getopt::Long;
&GetOptions(
	    'update'      => \$opt_update,
	    'type=s'      => \$opt_type,
	    'file=s'      => \$opt_file,
	    'reference=s' => \$opt_reference,
	    'alias=s'     => \$opt_alias,
	    'debug'       => \$opt_debug,
	    'host=s'      => \$opt_host,
	    'dbase=s'     => \$opt_dbase,
	    'user=s'      => \$opt_user,
	    'pass=s'      => \$opt_pass,
	    'quiet'       => \$opt_quiet,
	    'ignore=s'    => \$opt_ignore,  
	    'set_field=s' => \$opt_set_field,
	    'help'        => \$opt_help,
	    'h'           => \$opt_h,
	    'delim=s'     => \$opt_delim,
	    'scan'        => \$opt_scan,
	    );

print "***********\n Connect to Database \n**************\n";

my $update = $opt_update;      ## boolean indicating update required. (vs appending database)
my $type = $opt_type;
my $file = $opt_file;
my $reference = $opt_reference;
my $alias = $opt_alias;
my $quiet     = $opt_quiet;       ## change to allow as input...
my $user = $opt_user || 'viewer';
my $pass = $opt_pass;
my $host = $opt_host || 'lims01';
my $dbase = $opt_dbase || 'sequence';
my $debug = $opt_debug || 0;
my $ignore = $opt_ignore;
my $set_field = $opt_set_field;
my $help = $opt_help || $opt_h || 0;
my $delim = $opt_delim || "\t";
my $scan_for_duplicates = $opt_scan || 0; 

my $upload_path = $uploads_dir;
$file = "$upload_path/$file" if $file;

## <CONSTRUCTION> We can modify upload_attribute to use a mysql-native function
## LOAD DATA LOCAL INFILE '/home/aldnete/public/uploads/test_table.txt' IGNORE INTO TABLE test_table FIELDS TERMINATED BY ' ' IGNORE 1 LINES (FK_Sample__ID,Alias);

my %Map;
$Map{'Clone_Source'} =
{
    'fields' => {
	'row'            => 'Source_Row',
	'col'            => 'Source_Col',
	'vector'         => 'Source_Vector',
	'libr_id'        => 'Source_Library_ID',
	'collection'     => 'Source_Collection',
	'plate'          => 'Source_Plate',
	'IMAGE_clone_id' => 'Source_Clone_Name',
    },
#    'attributes' => {
#	 'IMAGE_clone_ID' => {
#	     'table'           => 'Sample',
#	     'field'           => 'IMAGE_ID',
#	     'extra_table'     => 'Clone_Sample',
#	     'extra_condition' => ' AND FK_Clone_Sample__ID=Clone_Sample_ID AND FK_Sample__ID=Sample_ID ',
#	 },
#	 'IMAGE_clone_id' => {
#	     'table'           => 'Sample',
#	     'field'           => 'IMAGE_ID',
#	     'extra_table'     => 'Clone_Sample',
#	     'extra_condition' => ' AND FK_Clone_Sample__ID=Clone_Sample_ID AND FK_Sample__ID=Sample_ID ',
#	 }
#    },

};

if ($help || !($file) || !($dbase) || !($host)) {
    print_help_info();
    leave();
}

unless ($pass) {
    print "Enter password for user: $user\n";
    $pass = Prompt_Input(-type=>'passwd',-default=>'');
}

#my $API = Sequencing_API->new(-dbase=>$dbase,-host=>$host,-DB_user=>$user,-DB_password=>$pass);

my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>$host,-user=>$user,-password=>$pass,-connect=>1)  || $Connection;
#my $dbc = $dbc->connect();

unless ($dbc->ping()) { Message("Could not connect successfully to $dbase database on $host"); &leave(); }

my @ignore_headers = split ',',$ignore;
my @reference_headers = ('Sample_ID','Plate_ID','Well');  ## headers used to reference the object to which the attributes are ascribed. 
my @sample_alias_list = $dbc->Table_find('Sample_Alias','Alias_Type','',-distinct=>1);
my @attribute_list = $dbc->Table_find_array('Attribute',['Attribute_ID','Attribute_Name'],"WHERE Attribute_Class = '$type'",-distinct=>1);

if ($reference) {
    push(@reference_headers, split ',', $reference);
}

my %Extra_fields;
my @field_pairs = split ',',$set_field;
foreach my $pair (@field_pairs) {
    my ($field,$value) = split '=',$pair;
    $Extra_fields{$field} = $value;
}

my @attribute_ids;  ## needed ? 
my %Update_Field;
my %Attribute;
my %Attribute_ID;
map { $_ =~/^(\d+),(.*)$/;  $Attribute_ID{$2} = $1; } @attribute_list;  ## map attributes to ids
my %Attribute_table;
my %Alias;
my %Map_to_alias;
my %Sample_Alias;
my %table_attributes;
my @headings;

my @fields;
my @references;

my @found;
my @errors;

print "$user Uploading file: $file.\n\n";
print "Loading data for $type... \n\n";

open(FILE,$file) or die "Sorry : unable to find/open $file";
my $header = <FILE>;
my $column = 0;
foreach my $heading (split /\s+/, $header) {
    print "H: $heading.";
    if (grep /^$heading$/i, @ignore_headers) {
	print "Ignoring $heading\n";
	push(@found,"Skipped $heading column");
	push(@headings,"<Skip $heading>");
    }
    elsif (grep /^$heading$/i, @reference_headers) {
	if ($Map{"$type"}{'fields'}{$heading}) {
	    $heading = $Map{"$type"}{'fields'}{$heading};
	}
	print "Referencing $heading\n";
	push(@found,"** Using $heading as a reference **");
	push(@headings,"<Ref $heading>");
#    } 
#    elsif ($Map{"$type"}{'fields'}{$heading}) {
#	my $mapped_heading = $Map{"$type"}{'fields'}{$heading};
#	print "$heading references true heading -> $mapped_heading\n";	       	       
#	push(@found,"re-Mapped Reference to $heading");  
#	push(@headings,"<MRef $mapped_heading>");
    } else {
	# map field and attributes
	print "Updating heading\n";
	my $old_type = $type;
	my $old_heading = $heading;

	if ($Map{"$type"}{'attributes'}{$heading}) {
	    $type = $Map{"$old_type"}{'attributes'}{$heading}{'table'};
	    $heading =  $Map{"$old_type"}{'attributes'}{$heading}{'field'};
	}
	if ($Map{"$type"}{'fields'}{$heading}) {
	    $heading =  $Map{"$old_type"}{'fields'}{$heading};
	}

	# create hash to map real heading to the alias
	$Map_to_alias{"$heading"} = $old_heading;

	my $attribute = grep /^\d+,\Q$heading\E$/, @attribute_list;
	my $alias = grep /^$heading$/, @sample_alias_list;

	my ($field_info) = $dbc->Table_find('DBField,DBTable','DBTable_Name,Field_Name',"WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name IN ('$type') AND Field_Name = '$heading'");

	push(@headings,$heading);

	if ($update && $field_info) {                ### fields that exist directly in $type object 
	    my  ($table,$field) = split ',', $field_info;
	    my ($reference) = $dbc->get_field_info($table,undef,'primary');
	    push(@fields,"$table.$field");
	    push(@references,$column);
	    print "Found Field $table.$field\n";
	    $Update_Field{$heading} = "$table.$field";
	} 
	elsif ($alias){
	    $Alias{$heading} = $alias;
	    push(@found,"** Alias: $heading **");
	}
	elsif ($attribute) {
	    $Attribute_table{$heading} = $type;
	    push(@found,"** $type Attribute: $heading ($Attribute_ID{$heading}) **");
	} 
	else {
	    push(@errors,"*** Invalid Heading: $heading ***");
	} 
	$type = $old_type;
	$heading = $old_heading;
    }
    $column++;
}

if (@found) {
    print "\n*** Recognized the following headers:\n";
    print join "\n", @found;
}

if (@errors) {
    print "\n\n*** Error: cannot load file $file ***\n(the following errors were found)\n\n";
    print join "\n", @errors;
    print "\n\n";

    if (grep /Invalid Heading/, @errors) {
	
	## check for other attributes for the same object ##
	my @other_attributes = Table_find($dbc,'Attribute','Attribute_Name',"WHERE Attribute_Class = '$type'");
	if (@other_attributes) {
	    print "\nOther $type Attributes available include:\n";
	    print "**************************************************\n";
	    print join "\n", @other_attributes;
	    print "\n";
	    print "**************************************************\n";
	} else {
	    print "** There are no defined $type attributes\n";
	}
	
	map {
	    if (/Invalid Heading: (\w+)/) {
		my $heading = $1;
		## check for other objects that may have this as an attribute ##
		my @other_tables = Table_find($dbc,'Attribute','Attribute_Class',"WHERE Attribute_Name = '$heading'");
		if (@other_tables) {
		    print "\nThe $heading attribute is valid for the following table(s) only:\n";
		    print "*******************************************************************\n";
		    print join "\n", @other_tables;
		    print "\n";
		    print "*******************************************************************\n";
		} else { print "** $heading is not a recognized attribute for any object **\n"; }
	    }
	} @errors;
    }
    print "\n\n(aborted)\n\n";
    &leave;
}
print "\n\nextracting data...\n\n";

my $record = 0;
my %Attribute_record;
my %alias_record;

my $updated = 0;
my $attempted_updates = 0;
my %append_count;
foreach my $i (0..$#headings) {
    print "$headings[$i]\t";
}
print "\n\n";

unless ($debug) {
    Message("This may update information into the database.\n");
    Message("If unsure about usage, test using '-debug' option.... Are you sure you want to continue ?");
    my $yn = Prompt_Input(-type=>'char',-default=>'');
    unless ($yn =~/^Y/i) { Message("Aborting"); leave(); }
}

while (<FILE>) {
    my $line = chomp_edge_whitespace $_;          ## chomp seems to cause a problem (??)
    unless ($line =~/\w/) { next }

    Message("Input: $line.") unless $quiet;

    my @values = split $delim, $line;
    ## For each record... ##
    my $reference_condition = '';
    my @table_values;
    
    # build the reference condition by going through all columns to begin with ... 
    foreach my $i (0..$#headings) {
	if ($headings[$i] =~/<Ref (.*)>/i) { 
	    $reference_condition .= " AND $1 = '$values[$i]'";
        } 
    }
    print "Condition: $reference_condition\n" if $debug;
    
    ## go through each field again, this time, initializing updates required ##
    foreach my $i (0..$#headings) {
	unless ($headings[$i]) { next }
	## check for Aliases ##
#	my $fk_value = $table_values[$i];  ## why was this here ?
	my ($fk_value) = &Table_find($dbc,$type,$type . "_ID","WHERE 1 $reference_condition");
	
	if ($fk_value=~/[1-9]/) {  ## ensure reference value correctly found ##
	    ## skipped fields
	    if ($headings[$i] =~/<Skip (.*)>/i) { print "<Skip: $1>\t" unless $quiet; } 
	    ## reference fields
	    elsif ($headings[$i] =~/<Ref (.*)>/i) { print "<$1=$values[$i]>\t" unless $quiet;  } 
	    ## updated field directly ... 
	    elsif ($Update_Field{$headings[$i]}) {
		print "$values[$i]\t" unless $quiet;
	    } 
	    ## check for Aliases
	    elsif ($Alias{$headings[$i]} && $values[$i]) {
		if ($fk_value =~ /[1-9]/) {
		    $values[$i] =~s/\s*(.*?)\s*/$1/;  ## get rid of weird spacing characters if applicable
		    print "Alias:$values[$i]\t" unless $quiet;
		    my $ok_to_insert = 1;
		    if ($scan_for_duplicates) {
			my @alias_exists = &Table_find($dbc,"${type}_Alias","${type}_Alias_ID","WHERE FK_${type}__ID = $fk_value");
			if (scalar(@alias_exists)) {
			    print "Alias exists, skipping.\t";
			    $ok_to_insert = 0;
			}
		    }
		    if ($ok_to_insert) {
			$Sample_Alias{$headings[$i]}->{++$alias_record{$headings[$i]}} = [$fk_value,$headings[$i],$values[$i]];
		    }
		}
	    }
	    ### check for Attributes ###
	    elsif ($Attribute_ID{$headings[$i]} && $values[$i]) {
		my $attr_id = $Attribute_ID{$headings[$i]};
		$values[$i] =~s/\s*(.*?)\s*/$1/;  ## get rid of weird spacing characters if applicable
		print "Attr$attr_id:$values[$i]\t" unless $quiet;
		$table_attributes{$headings[$i]}->{++$Attribute_record{$attr_id}} = [$fk_value,$attr_id,$values[$i]];
	    }
	} else {
	    Message("Warning: No reference value found for line $i ($reference_condition)");
	}
    }
    print "\n" unless $quiet;

    if ($reference_condition && $update) {
	my @field_list;
	my @field_values;
	foreach my $index (0..$#fields) {
	    #my $val = $values[$references[$index]];
	    push (@field_list, $fields[$index]);
	    push (@field_values, $values[$references[$index]]);
	}
	foreach my $field (keys %Extra_fields) {
	    push (@field_list, $field);
	    push (@field_values, $Extra_fields{$field});
	}
	if (@fields) {
	    print "\n** Update: @field_list\n** Values: @field_values\n** Condition: $reference_condition\n\n" unless $quiet;
	    my $ok;
	    $attempted_updates++;
	    unless ($debug) {
		$ok = $dbc->Table_update_array($type,\@field_list,\@field_values,"WHERE 1 $reference_condition",-autoquote=>1);
	    }
	    if ($ok) {
		$updated++;
	    }
	} else {
#	    print "\n(No $type information required for update)\n";
	}
    }
    $record++;
    
}
#print Dumper \%Sample_Alias;
my $alias_record;
$alias_record--;  

my ($attributes_added,$aliases_added) = (0,0,0,0);
## Update Attributes from generated hash of new values ##
foreach my $key (keys %table_attributes){
    my $attribute_type = $Attribute_table{$key};
    my $foreign_key_field =  foreign_key("$attribute_type");
    my $ok = $dbc->smart_append(-dbc=>$dbc,-tables=>"$attribute_type" . "_Attribute", -fields=>[$foreign_key_field,'FK_Attribute__ID','Attribute_Value'], -values=>$table_attributes{$key}, -autoquote=>1) unless $debug;
#    Message("Attributes updated:");
    if (defined $ok->{"${attribute_type}_Attribute"}{newids}) {
	$attributes_added += int(@{$ok->{"${attribute_type}_Attribute"}{newids}});
    }
    elsif ($debug) {
#	print Dumper($table_attributes{$key});
    } else {
	Message("Cannot add attributes for $attribute_type");
    }
}
## Update Sample Aliases from generated hash of new values ##
foreach my $key(sort keys %Sample_Alias){
    my $ok = $dbc->smart_append(-dbc=>$dbc, -tables=>"Sample_Alias", -fields=>['FK_Sample__ID','Alias_Type','Alias'],-values=>$Sample_Alias{$key},-autoquote=>1,-ignore_duplicate_keys=>1) unless $debug;
    if (defined $ok->{'Sample_Alias'}{newids}) {
	$aliases_added += int(@{$ok->{"Sample_Alias"}{newids}});
    }
    elsif ($debug) {
	 #print Dumper($Sample_Alias{$key});
    } else {
	my @keys = keys %{$Sample_Alias{$key}};
	Message("No sample aliases added for $type (@keys)");
    }
}

## generate feedback showing what has been done ##
Message("Loaded file: $record lines for $type objects");
Message("Attempted updates: $attempted_updates");
Message("Updated ($updated) $type records");

my $attribute_types = int(keys %table_attributes);
my $alias_types     = int(keys %Sample_Alias);

foreach my $key (keys %Attribute_ID) {
    my $records = $Attribute_record{$Attribute_ID{$key}};   ## records are 1 indexed ...
    Message("Attempted $records $key updates") if $records;
}

Message("Added $attributes_added attribute records");
Message("Attempted $alias_record alias updates ($attribute_types attribute types per record)");
Message("Added $aliases_added sample aliases");

foreach my $key (keys %append_count) {
    Message("Loaded $append_count{$key}");
}
&leave();

##########
sub leave {
##########
    if ($dbc) {$dbc->disconnect()}
    exit;
}

#########
sub print_help_info {
#########
print<<HELP;

File:  upload_attribute.pl
####################
This script uploads attributes (and optionally fields) to a particular table from a tab-delimited file.

Options:
##########

------------------------------
1) Database login information:
------------------------------
-dbase       Database specification. 
-host        Host specification.
-user        User for database login (e.g. -user bob)
-pass        Password for database login (e.g. -pass 123)

------------------------------
2) Upload options:
------------------------------
-type        The table of the attribute to be loaded. Synonymous with table.

-file        Filename of the source tab-delimited file.

-update      Enables updating to the table fields. 
             Note that a field can be uploaded to a field or an attribute/alias, but not both.

-delim       Indicate the delimeter to be used when reading the file (defaults to tab)

-ignore      Ignore this column from the file. 
             (e.g. '-ignore Plate_ID' will ignore the column Plate_ID in the source file).

-reference   Fields to use to find an ID for the attributes. 
             This should be named the same as the headers in the source file.
             These fields will not be loaded into the table fields or attributes.
             There should always be at least one reference column.
             (e.g. -reference collection,plate,row,col)

-set_field   Updates the specified field in the table to be the specified value.
             This is useful for setting a type or comment field for all rows affected.
             (e.g. set_field Source_Type=RNA_DNA_Source)

-alias       Set the alias

-scan        Scan for duplicates being inserted, and omit them from the insert.
             The script already does this automatically, but it does not omit duplicates from the insert. 
             The duplicate scanning slows down the parsing of the file, but prevents the host
             from running out of memory or exceeding the maximum packet size.

------------------------------
3) Feedback options:
------------------------------
-debug       Disables database writes. Useful for testing.
-quiet       Reduces verbosity of feedback. It is recommended to turn it on unless it is being debugged/tested.

------------------------------
3) Help options:
------------------------------
-h or -help  Prints this help page 
 
------------------------------
Usage examples
------------------------------
upload_attribute.pl -file Attribute_File.csv -type Source -reference Attrib_ID -dbase sequence -host lims02 -user user -pass pass
--  this uploads attributes from the file Attribute_File.csv to the Source attributes. 
--  The Source_ID can be identified uniquely by the Attrib_ID column.
--  There are no fields to be updated.

upload_attribute.pl -file IRAK242 -type Clone_Source  -reference collection,plate,row,col -set_field Source_Clone_Name_Type=IMAGE_ID -update
                    -dbase sequence -host lims02 -user user -pass pass
--  This uploads field and attribute values to Clone_Source.
--  The Clone_Source_ID can be identified uniquely by a combination of four columns (collection,plate,row,col).
--  This will also set the field Source_Clone_Name_Type to be the value 'IMAGE_ID'


HELP
}
