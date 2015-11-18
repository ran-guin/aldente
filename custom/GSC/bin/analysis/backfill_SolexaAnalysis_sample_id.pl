#!/usr/local/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use SDB::DBIO;
use RGTools::RGIO;
use Sequencing::Solexa_Analysis;

use vars qw($opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_flowcell $opt_lane $opt_update $opt_run);

&GetOptions(
    'help|h|?'       => \$opt_help,
    'host=s'		=> \$opt_host,
    'dbase|d=s'    => \$opt_dbase,
    'user|u=s'     => \$opt_user,
    'password|p=s' => \$opt_password,
    'flowcell=s'		=>\$opt_flowcell,
    'lane=s'			=>\$opt_lane,
    'update'		=> \$opt_update, 
    'run|r=s'			=> \$opt_run,     
);

my $help             = $opt_help;
my $host             = $opt_host;
my $dbase            = $opt_dbase;
my $user             = $opt_user;
my $pwd              = $opt_password;
my $flowcell_list              = $opt_flowcell;
my $lane_list = $opt_lane;
my $update = $opt_update; # flag for database update
my $run_ids = $opt_run;

if( $help ) {
	&display_help();
	exit;
}

my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my @runs;
if( $run_ids ) {
	@runs = Cast_List(-list => $run_ids, -to => 'Array');
}
elsif( $lane_list ) { ## backfill for the given lanes of one specific flowcell
	if( $flowcell_list ) {
    	my @flowcells = Cast_List(-list => $flowcell_list, -to => 'Array');
    	if( @flowcells > 1 ) {
	    	Message( "ERROR: Only one flowcell is accepted when lanes are specified!" );
	    	exit;
    	}
    	if( @flowcells ) {
    		my $flowcell = $flowcells[0];
			@runs = $dbc->Table_find('Flowcell,SolexaRun', 'FK_Run__ID', "WHERE Flowcell_Code = '$flowcell' and FK_Flowcell__ID = Flowcell_ID and Lane in ( $lane_list )", -distinct => 1);
    	}
	}
	else {
	    	Message( "ERROR: No flowcell specified for the lanes!" );
	    	exit;
	}
}
elsif( $flowcell_list ) { ## backfill for all the lanes of the given flowcells
    my @flowcells = Cast_List(-list => $flowcell_list, -to => 'Array');
    foreach my $fc ( @flowcells ) {
		my @run_ids = $dbc->Table_find('Flowcell,SolexaRun', 'FK_Run__ID', "WHERE Flowcell_Code = '$fc' and FK_Flowcell__ID = Flowcell_ID", -distinct => 1 );
    	push @runs, @run_ids; 
    }
}
else { # search all runs without SolexaAnalysis.FK_Sample__ID
	@runs = $dbc->Table_find(
		-table => 'SolexaAnalysis, Run LEFT join Sample on SolexaAnalysis.FK_Sample__ID = Sample.Sample_ID', 
		-fields => 'FK_Run__ID', 
		-condition => "WHERE Sample.Sample_ID is null and Run_ID = FK_Run__ID and Run_Validation = 'Approved' ",
		-distinct => 1,
	);
}

my $runs_count = scalar( @runs );
if( $runs_count ) {
	print "The following $runs_count runs will be processed:\n";
	print Dumper \@runs;
}

foreach my $run ( @runs ) {
	my ( $sample_id ) = $dbc->Table_find(
		-table => 'Run, Plate, Plate_Sample, Sample', 
		-fields => 'Sample_ID', 
		-condition => "WHERE Run_ID = $run and FK_Plate__ID = Plate_ID and Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID and FK_Sample__ID = Sample_ID",
		-distinct => 1,
	);
	
		if( $sample_id ) {
			print "Found Sample_ID $sample_id for run $run\n";
			if( $update ) {
					my $num_records = $dbc->Table_update_array( 
						-table =>'SolexaAnalysis',
						-fields => ['FK_Sample__ID'],
						-values => [$sample_id],
						-condition => "WHERE FK_Run__ID = $run"
					);
					if( $num_records ) {
						Message( "$num_records records are updated.");
					}
			} # END $update
			else {
				print "Sample ID not updated. Please use -update to update the record!\n";
			}
		}
		else {
			print "No Sample_ID found for run $run\n";
		}
}

sub display_help {
    print <<HELP;

Syntax
======
backfill_SolexaAnalysis_sample_id.pl - This script backfills the SolexaAnalysis.FK_Sample__ID.

Arguments:
=====

-- required arguments --
-host				: specify database host, ie: -host lims02.  
-dbase, -d			: specify database, ie: -dbase sequence. 
-user, -u			: specify database user. 
-passowrd, -p		: password for the user account. 

-- optional arguments --
-help, -h, -?		: displays this help. (optional)
-run, -r			: comma separated list of run ids
-flowcell			: comma separated list of flowcells. 
-lane				: comma separated list of lanes.  
-update				: flag to update database

Note: 
If both -flowcell and -lane are specified, the -flowcell should have only one flowcell.
If -flowcell is specified and no -lane specified, all lanes under the specified flowcells will be retrieved.


Example
=======
backfill_SolexaAnalysis_sample_id.pl -host lims02 -d sequence -u xxxx -p xxxx -r 110114
backfill_SolexaAnalysis_sample_id.pl -host lims02 -d sequence -u xxxx -p xxxx -flowcell 12936AAXX -lane 1,2,3
backfill_SolexaAnalysis_sample_id.pl -host lims02 -d sequence -u xxxx -p xxxx -flowcell 12936AAXX



HELP
}		

