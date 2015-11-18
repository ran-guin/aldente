#!/usr/local/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use Data::Dumper;
use SDB::GSDB;
use SDB::DBIO;
use XML::Parser;
use RGTools::RGIO;
use RGTools::Conversion;

use vars qw($opt_scope $opt_file $opt_host $opt_dbase $opt_user $opt_pass $opt_help $opt_h);
use vars qw($testing $Connection);

use Getopt::Long;
&GetOptions(
	    'scope'       => \$opt_scope,
	    'file=s'      => \$opt_file,
	    'host=s'      => \$opt_host,
	    'dbase=s'     => \$opt_dbase,
	    'user=s'      => \$opt_user,
	    'pass=s'      => \$opt_pass,
	    'help'        => \$opt_help,
	    'h'           => \$opt_h,
	    );

my %custom;
my %affy_custom;
$alias{table}{'SAMPLE'} = ['Sample'];
$alias{table}{'EXPERIMENT'} = ['Run'];
$alias{table}{'CHIP'} = ['Genechip','Plate','Plate_Sample','Sample'];
$alias{table}{'GENECHIP_EXPERIMENT'} = ['Run','Genechip_Experiment'];
$alias{field}{'GCOS_Sample_ID'} = 'Sample_Name';
$alias{field}{'GCOS_SampleName'} = 'Sample_Name'; 
$alias{field}{'Run_User'} = 'GCOS_Experiment_User';
$alias{field}{'Library_Name'} = 'FK_Library__Name';
$alias{field}{'Plate_Format'} = 'FK_Plate_Format__ID';
$alias{field}{'Rack'} = 'FK_Rack__ID';

$custom{'Affymetrix'} = \%affy_custom;

my $file = $opt_file;
my $user = $opt_user;
my $pass = $opt_pass;
my $host = $opt_host;
my $dbase = $opt_dbase;
my $help = $opt_help || $opt_h || 0;
my $scope = $opt_scope || "Affymetrix";

my $error_str = "";

unless ($host) {
    $error_str .= "Error: Missing or incorrect parameter: Missing host (-host) specification\n";
}

unless ($dbase) {
    $error_str .= "Error: Missing or incorrect parameter: Missing database (-dbase) specification\n";
}

unless ($user) {
    $error_str .= "Error: Missing or incorrect parameter: Missing user (-user) specification\n";
}

unless ($pass) {
    $error_str .= "Error: Missing or incorrect parameter: Missing password (-pass) specification\n";
}

unless (grep (/^$scope$/,keys(%custom))) {
    $error_str .= "Error: Missing or incorrect Parameter: Scope (-scope) $scope does not exist\n";
}

if ($help) {
    &print_help_info();
    exit;
}
elsif ($error_str || $help) {
    print $error_str;
    &print_help_info();
    exit;
}

my %alias = %{$custom{$scope}};

die "Can't find file \"$file\""
  unless -f $file;

print "***********\n Connect to Database \n**************\n";

my $dbio = new SDB::DBIO(-dbase=>$dbase,-host=>$host,-user=>$user,-password=>$pass,-connect=>1);
$dbc = $dbio; 

my $curr_set;
my $curr_str;

my $parser = new XML::Parser(ErrorContext => 2);

$parser->setHandlers(Char => \&char_handler,
		     Default => \&default_handler,
		     Start => \&start_handler,
		     End => \&end_handler);

$parser->parsefile($file);



exit;

sub insert_to_db {
    my $insert_hash = shift;
    my $dbc = $Connection # change to shift

    my @insert_tables = ();
    my @insert_fields = ();
    my @insert_values = ();

    my %attributes;
    
    my %insert;

    # for each field, check to see if it has an alias and replace it
    # if the field name is undefined, fail out and roll back the transaction
    # check each table and replace the keys with the correct table name
    # check each field and replace keys with the correct field name
    # if the field name is a field, insert it
    # if the field name is an attribute, insert it into the attributes
    foreach my $table (keys %{$insert_hash}) {
	if (exists $alias{table}{$table}) {
	    push (@insert_tables, @{$alias{table}{$table}});
	}
	else {
	    push (@insert_tables, $table);  
	}
    }
    @insert_tables = @{&unique_items(\@insert_tables)};
    foreach my $table (keys %{$insert_hash}) {
	foreach my $field (keys %{$insert_hash->{$table}}) {
	    my $newfield = $field;
	    if (exists $alias{field}{$field}) {
		$newfield = $alias{field}{$field};
	    }
	    # check if this field exists
	    my @id = &Table_find($dbc,"DBTable,DBField","DBField_ID","WHERE FK_DBTable__ID=DBTable_ID AND Field_Name = '$newfield' AND DBTable_Name in (".&autoquote_string(join(',',@insert_tables)).")");
	    if (int(@id) > 0) {
		# this is a field
		# if the field already exists, don't repeat it
		unless (grep /$newfield/,@insert_fields) {
		    push (@insert_fields, $newfield);
		    my $value = $insert_hash->{$table}{$field};
		    # custom code, should be removed
		    if ($newfield =~ /Run_DateTime|Expiry_Date|Plate_Created/) {
			$value = convert_date($value);
		    }
		    push (@insert_values, $value);
		}
	    }
	    else {
		# this is an attribute
		# find which table this is an attribute of and store the value
		my ($attribute_str) = &Table_find($dbc,"Attribute","Attribute_Class,Attribute_ID","WHERE Attribute_Name = '$newfield' AND Attribute_Class in (".&autoquote_string(join(',',@insert_tables)).")");
		my ($attribute_table,$attribute_id) = split ',',$attribute_str;
		# if there is no attribute, warn and fail out this insert
		unless ($attribute_table) {
		    print "Error: Attribute $newfield missing from $table. Skipping this insert\n";
		    return;
		}
		$attributes{$attribute_table}{$attribute_id} = $insert_hash->{$table}{$field};

	    }
	}
	
    }

    # insert using smart_append
    my %newids = %{$dbio->smart_append(-tables=>join(',',@insert_tables),-fields=>\@insert_fields,-values=>\@insert_values,-autoquote=>1)};

    # use generated IDs to insert attributes
    foreach my $table (keys %attributes) {
	my %attribute_values;
	my $count = 1;
	# build hash for smart append
	foreach my $attrib_id (keys %{$attributes{$table}}) {
	    $attribute_values{$count} = [$newids{$table}{newids}[0],$attrib_id,$attributes{$table}{$attrib_id}];
	    $count++;
	}

	# insert into database
	$dbio->smart_append(-tables=>"${table}_Attribute",-fields=>["FK_${table}__ID","FK_Attribute__ID","Attribute_Value"],-values=>\%attribute_values,-autoquote=>1);
    }

}

sub char_handler
{

    my ($p,$str) = @_;

    $curr_str .= $str;

}  # End of char_handler

sub default_handler
{
    my ($p, $data) = @_;

}  # End of default_handler

sub start_handler {
    my $p = shift;
    my $el = shift;

    if ($el =~ /^SET$/) {
	$curr_set = {};
    }
    $curr_str = "";
}

sub end_handler {
    my $p = shift;
    my $el = shift;
    if ($el =~ /^SET$/) {
	&insert_to_db($curr_set);
    }
    my @context = @{$p->{'Context'}};

    if (int(@context) == 3) {
	$curr_set->{$context[2]}{$el} = $curr_str;
    }

}

sub print_help_info {
print<<HELP;

File:  upload_xml.pl
####################
This script uploads rows for a set of tables and attributes defined by an XML file.

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
-scope       The scope of the XML file. One of Affymetrix.

-file        Filename of the source XML file.

------------------------------
3) Help options:
------------------------------
-h or -help  Prints this help page 
 
------------------------------
Usage examples
------------------------------
upload_xml.pl -file file.xml -scope Affymetrix -dbase sequence -host lims02 -user user -pass pass
    --  this uploads information from file.xml to the sequence database using the Affymetrix scope

HELP
}
