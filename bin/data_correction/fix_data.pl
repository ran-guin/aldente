#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";

use RGTools::RGIO;
 
use SDB::Transaction;
use SDB::CustomSettings;
use SDB::DBIO;
use alDente::SDB_Defaults;
use Sequencing::Sequencing_API;
use RGTools::Conversion;

unless ($ARGV[0]) {_print_help_info(); exit;}
use Getopt::Std;
use vars qw($opt_D $opt_u $opt_p $opt_h $opt_b $opt_B);
getopts('D:u:p:hb:B:');
if ($opt_h) {_print_help_info(); exit;}

my $host = $Defaults{mySQL_HOST}; #Default to the default mysql host.
my $dbase = $opt_D if ($opt_D);
my $user = $opt_u if ($opt_u);
my $passwd = $opt_p if ($opt_p);

if ($dbase =~ /([\w\-]*):([\w\-]*)/) { #See if user is specifying both host and database.
    $host = $1;
    $dbase = $2;
}

# Define all the blocks here
my @blocks = ('Clone_Gel','Concentrations','Library');
if ($opt_b) {
    @blocks = split /,/, $opt_b;
}
elsif ($opt_B) {
    my @temp_blocks = @blocks;
    my @exclude_blocks = split /,/, $opt_B;
    undef(@blocks);
    foreach my $block (@temp_blocks) {
	unless (grep /^$block$/, @exclude_blocks) {
	    push(@blocks,$block);
	}
    }
}

my $dbc = Sequencing_API->new(-dbase=>$dbase,-host=>$host,-DB_user=>$user,-DB_password=>$passwd,-connect=>1);

################ Starting individual blocks ####################

if (_check_block('Clone_Gel')) {
    my $transaction = Transaction->new(-dbc=>$dbc);
    my $updated = 0;

    # Find missing FK_Sample__ID in Clone_Gel
    
    my $gels = $dbc->Table_retrieve(-table=>'Gel,Clone_Gel',-fields=>['Clone_Gel_ID','FK_Plate__ID,Well'],-condition=>"WHERE Gel_ID=FK_Gel__ID AND (FK_Sample__ID IS NULL OR FK_Sample__ID = '' OR FK_Sample__ID = 0)",-format=>'AofH');

    $transaction->start();
    foreach my $gel (@$gels) {
	my ($clone_gel_id,$plate_id,$well) = ($gel->{Clone_Gel_ID},$gel->{FK_Plate__ID},$gel->{Well});
	my $sample_id = $dbc->get_sample_ids(-plates=>[$plate_id],-wells=>[$well])->[0];
	if ($sample_id) {
	    print ">Updating Clone_Gel: Plate_ID($plate_id) and Well($well) -> Sample_ID($sample_id)\n";
	    $updated += Table_update_array($dbc,'Clone_Gel',['FK_Sample__ID'],[$sample_id],"WHERE Clone_Gel_ID = $clone_gel_id",-autoquote=>1,-trans=>$transaction);
	}
	else {print ">WARNING: No sample_id found for Plate $plate_id and Well $well.\n"}
    } 
    
    print ">>>Updated $updated Clone_Gel records.\n\n";
    $transaction->finish();
}

if (_check_block('Concentrations')) {
    my $transaction = Transaction->new(-dbc=>$dbc);
    my $updated = 0;

    # Find missing FK_Sample__ID in Concentrations
    my $concs = $dbc->Table_retrieve(-table=>'ConcentrationRun,Concentrations',-fields=>['Concentration_ID','FK_Plate__ID,Well'],-condition=>"WHERE ConcentrationRun_ID=FK_ConcentrationRun__ID AND (FK_Sample__ID IS NULL OR FK_Sample__ID = '' OR FK_Sample__ID = 0)",-format=>'AofH');
    $transaction->start();
    
    $updated = 0;
    foreach my $conc (@$concs) {
	my ($concentration_id,$plate_id,$well) = ($conc->{Concentration_ID},$conc->{FK_Plate__ID},$conc->{Well});
	my $sample_id = $dbc->get_sample_ids(-plates=>[$plate_id],-wells=>[$well])->[0];
	if ($sample_id) {
	    print ">Updating Concentrations: Plate_ID($plate_id) and Well($well) -> Sample_ID($sample_id)\n";
	    $updated += Table_update_array($dbc,'Concentrations',['FK_Sample__ID'],[$sample_id],"WHERE Concentration_ID = $concentration_id",-autoquote=>1,-trans=>$transaction);
	}
	else {print ">WARNING: No sample_id found for Plate $plate_id and Well $well.\n"}
    } 
    
    print ">>>Updated $updated Concentrations records.\n\n";
    $transaction->finish();
}

if (_check_block('Library')) {    
    my @format_tables = ('Ligation','Microtiter','Xformed_Cells','ReArray_Plate'); 
    my %format_names;
    $format_names{Ligation} = 'Ligation';
    $format_names{Microtiter} = 'Microtiter Plates';
    $format_names{Xformed_Cells} = 'Transformed Cells';
    $format_names{ReArray_Plate} = 'ReArrayed';   

    # Get DBTable_IDs;
    my $sth = $dbc->query(-query=>"SELECT DBTable_ID,DBTable_Name FROM DBTable WHERE DBTable_Name in ('Ligation','Microtiter','Xformed_Cells','ReArray_Plate','Sequencing_Library','Library')",-finish=>0);
    my $tids = &SDB::DBIO::format_retrieve(-sth=>$sth,-format=>'HofH',-keyfield=>'DBTable_Name');

    ## Get libraries that are missing FK_Sequencing_Library__ID ##
    foreach my $format_table (@format_tables) {
	print ">>>Checking $format_table table...\n";
	my $primary = $format_table . "_ID";
	
	my $ids = $dbc->Table_retrieve(-table=>"$format_table",-fields=>[$primary],-condition=>"WHERE FK_Sequencing_Library__ID IS NULL OR FK_Sequencing_Library__ID = 0 OR FK_Sequencing_Library__ID = ''",-format=>'CA');
	foreach my $id (@$ids) {
	    print ">$format_table ID $id missing FK_Sequencing_Library__ID.\n";
	    # Now attempting to do the fix:
	    # First see if this is from a Submission
	    my $seq_lib_id = $dbc->Table_retrieve(-table=>"Submission_Detail AS ${format_table}_Sub, Submission_Detail AS Library_Sub, Sequencing_Library"
						-fields=>['Sequencing_Library_ID'],
						-condition=>"WHERE ${format_table}_Sub.FKSubmission_DBTable__ID = $tids->{$format_table}{DBTable_ID} AND ${format_table}_Sub.Reference = $id AND ${format_table}_Sub.FK_Submission__ID = Library_Sub.FK_Submission__ID AND Library_Sub.FKSubmission_DBTable__ID = $tids->{Library}{DBTable_ID} AND Sequencing_Library.FK_Library__Name = Library_Sub.Reference",
						-format=>'S');	    
#
	    if ($seq_lib_id) {
		print ">Updating Sequencing_Library_ID to $seq_lib_id based on submission_info.";
		my $ok = Table_update_array($dbc,$format_table,['FK_Sequencing_Library__ID'],[$seq_lib_id],"WHERE $primary = $id",-autoquote=>1);
		if ($ok) {print " (OK)\n"}
		else {print " (Failed)\n"}
		next;
	    }
	}
    }

    ## Get sequencing libraries that are missing the corresponding format entries
    my ($barcode_label_id) = Table_find($dbc,'Barcode_Label','Barcode_Label_ID',"WHERE Barcode_Label_Name = 'lib_cnt_plate'");
    foreach my $format_table (@format_tables) {
	print ">>>Checking sequencing libraries for missing $format_table entries...\n";	
	
	my $ids = $dbc->Table_retrieve(-table=>"Sequencing_Library LEFT JOIN $format_table ON Sequencing_Library_ID=FK_Sequencing_Library__ID",-fields=>["Sequencing_Library_ID"],-condition=>"WHERE Sequencing_Library_Format='$format_names{$format_table}' AND FK_Sequencing_Library__ID IS NULL",-format=>'CA');

	foreach my $id (@$ids) {
	    print ">Sequencing library ID $id ($format_names{$format_table}) missing corresponding $format_table entries.\n";
	    # Create library container entries
	    my @cnt_fields = ('FK_Rack__ID','FK_Barcode_Label__ID','Library_Container_Type');
	    my @cnt_values = (1,$barcode_label_id);
	    my @format_fields = ('FK_Sequencing_Library__ID');
	    my @format_values = ($id);
	    if ($format_table eq 'Ligation') {
		push(@cnt_values,'Tube');
		push(@format_fields,'Sequencing_Type');
		push(@format_values,'N/A');
	    }
	    elsif ($format_table eq 'Microtiter') {
		push(@cnt_values,'Plate');
		push(@format_fields,'Sequencing_Type');
		push(@format_values,'N/A');
	    }
	    elsif ($format_table eq 'Xformed_Cells') {
		push(@cnt_values,'Tube');
		push(@format_fields,'Sequencing_Type');
		push(@format_values,'N/A');
	    }
	    elsif ($format_table eq 'ReArray_Plate') {
		push(@cnt_values,'Plate');
	    }

	    my $transaction = Transaction->new(-dbc=>$dbc);
	    $transaction->start();
	    my $newid = Table_append_array($dbc,'Library_Container',\@cnt_fields,\@cnt_values,-autoquote=>1,-trans=>$transaction);
	    if ($newid) {
		push(@format_fields,'FK_Library_Container__ID');
		push(@format_values,$newid);
		$newid = Table_append_array($dbc,$format_table,\@format_fields,\@format_values,,-autoquote=>1,-trans=>$transaction);
	    }
	    else {$transaction->rollback()}
	    if ($newid) {
		$transaction->finish();
		print ">Inserted new library container and $format_table entries.\n";
		}
	    else {
		$transaction->rollback();
		print ">Failed to inserted new library container and $format_table entries.\n";
	    }
	}
    }  
}

$dbc->disconnect();

###############################################
# Checks whether the current block is to be run
###############################################
sub _check_block {
    my $block = shift;

    if (grep /^$block$/,@blocks) {
	print "-"x100 . "\n";
	print "Running block '$block' (@{[date_time()]})...\n";
	print "-"x100 . "\n";
	return 1;
    }
    else {
	print "-"x100 . "\n";
	print "Skipping block '$block' (@{[date_time()]})...\n";
	print "-"x100 . "\n";
	return 0;
    }
}

#########################
sub _print_help_info {
#########################
print<<HELP;

File:  fix_data.pl
####################
This script checks defined data integrity checks and automatically fix problems.

Options:
##########

------------------------------
1) Database login information:
------------------------------
-D     Database specification. Accepts 2 formats:
       -Database name only: The default SQL host will be used. (e.g. -D sequence)
       -Host and database name: The specified SQL host will be used. (e.g. -D athena:sequence)
-u     User for database login (e.g. -u bob)
-p     Password for database login (e.g. -p 123)

---------------------------
2) Additional options:
---------------------------
-b     Specify a comma-delimited list of blocks to be included (If not specified then all blocks will be run)
-B     Specify a comma-delimited list of blocks to be excluded

HELP
}
