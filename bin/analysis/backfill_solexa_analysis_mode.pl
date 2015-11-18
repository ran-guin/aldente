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

use vars qw($opt_help $opt_host $opt_dbase $opt_user $opt_password $opt_library $opt_flowcell $opt_lane $opt_update $opt_run );

my %flowcell_dirs;
$flowcell_dirs{'13233AAXX'} = '/projects/flowcellscratch/080118_SOLEXA4_0009_13233AAXX';
$flowcell_dirs{'13286AAXX'} = '/projects/flowcellscratch/080125_SOLEXA4_0011_13286AAXX';
$flowcell_dirs{'301CDAAXX'} = '/projects/flowcellscratch/080307_SOLEXA6_0003_301CDAAXX';
$flowcell_dirs{'2012CAAXX'} = '/projects/flowcellscratch/080314_SOLEXA4_0025_2012CAAXX';
$flowcell_dirs{'201FEAAXX'} = '/projects/flowcellscratch/080331_SOLEXA4_0030_201FEAAXX';
$flowcell_dirs{'20821AAXX'} = '/projects/flowcellscratch/080325_SOLEXA4_0028_20821AAXX';
$flowcell_dirs{'20820AAXX'} = '/projects/flowcellscratch/080407_SOLEXA4_0032_20820AAXX';
$flowcell_dirs{'3017YAAXX'} = '/projects/flowcellscratch/080328_SOLEXA6_0006_3017YAAXX';
$flowcell_dirs{'3019NAAXX'} = '/projects/flowcellscratch/080408_SOLEXA6_0008_3019NAAXX';
$flowcell_dirs{'30KWMAAXX'} = '/gsc/archive/sbs_primary_data/solexa1_7/data7/081124_SOLEXA5_0053_30KWMAAXX';
$flowcell_dirs{'612FTAAXX'} = '/projects/sbsdemo/ga6/091013_SOLEXA6_0084_612FTAAXX';

&GetOptions(
    'help|h'       => \$opt_help,
    'host=s'		=> \$opt_host,
    'dbase|d=s'    => \$opt_dbase,
    'user|u=s'     => \$opt_user,
    'password|p=s' => \$opt_password,
    'library=s'    => \$opt_library,
    'flowcell=s'		=>\$opt_flowcell,
    'lane=s'			=>\$opt_lane,
    'update'		=> \$opt_update, 
    'run=s'			=> \$opt_run,     
);

my $help             = $opt_help;
my $host             = $opt_host;
my $dbase            = $opt_dbase;
my $user             = $opt_user;
my $pwd              = $opt_password;
my $library_list = $opt_library;
my $flowcell_list              = $opt_flowcell;
my $lane_list = $opt_lane;
my $update = $opt_update; # flag for database update
my $run_ids = $opt_run;

my $dbc = new SDB::DBIO(
    -host     => $host,
    -dbase    => $dbase,
    -user     => $user,
    -password => $pwd,
    -connect  => 1,
);

my %flowcell_lanes;
if( $run_ids ) {
	my @runs = Cast_List(-list => $run_ids, -to => 'Array');
	my %flowcells;
	foreach my $run ( @runs ) {
		my  @flowcell_lanes = $dbc->Table_find('Run,SolexaRun,Flowcell', 'Flowcell_Code,Lane', "WHERE Run_ID = $run and FK_Run__ID = Run_ID and FK_Flowcell__ID = Flowcell_ID");
		foreach my $flowcell_lane ( @flowcell_lanes ) {
			my ( $flowcell, $lane ) = split ',', $flowcell_lane;
			if( defined $flowcells{$flowcell} ) {
				push @{$flowcells{$flowcell}}, $lane; 
			}
			else {
				$flowcells{$flowcell} = [$lane];
			}
		}
	}
	foreach my $fc ( keys %flowcells ) {
    	$flowcell_lanes{$fc} = join ',', @{$flowcells{$fc}};
	}
}
elsif( $lane_list ) { ## backfill for the given lanes of one specific flowcell
	if( $flowcell_list ) {
    	my @flowcells = Cast_List(-list => $flowcell_list, -to => 'Array');
    	if( @flowcells > 1 ) {
	    	Message( "ERROR: Only one flowcell is accepted when lanes are specified!" );
	    	exit;
    	}
    	if( @flowcells ) {
    		$flowcell_lanes{$flowcells[0]} = $lane_list;
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
    	$flowcell_lanes{$fc} = '0'; 
    }
}
elsif( $library_list ) { ## backfill for all the lanes of all the flowcells of the given libraries
	my @libraries = Cast_List(-list => $library_list, -to => 'Array');
	my %flowcells;
	foreach my $library ( @libraries ) {
		my  @flowcell_lanes = $dbc->Table_find('Library,Plate,Run,SolexaRun,Flowcell', 'Flowcell_Code,Lane', "WHERE Library_Name = '$library' and FK_Library__Name = Library_Name and FK_Plate__ID = Plate_ID and Run_Validation = 'Approved' and FK_Run__ID = Run_ID and FK_Flowcell__ID = Flowcell_ID");
		foreach my $flowcell_lane ( @flowcell_lanes ) {
			my ( $flowcell, $lane ) = split ',', $flowcell_lane;
			if( defined $flowcells{$flowcell} ) {
				push @{$flowcells{$flowcell}}, $lane; 
			}
			else {
				$flowcells{$flowcell} = [$lane];
			}
		}
	}
	foreach my $fc ( keys %flowcells ) {
    	$flowcell_lanes{$fc} = join ',', @{$flowcells{$fc}};
	}
}

my $fc_count = keys %flowcell_lanes;
if( $fc_count ) {
	print "The following lanes on $fc_count flowcells will be processed:\n";
	print "Flowcell\tLane(s)\n";
	foreach my $fc ( keys %flowcell_lanes ) {
			print "$fc\t$flowcell_lanes{$fc}\n";
	}
}

foreach my $fc ( keys %flowcell_lanes ) {
	#my $solexa_analysis_obj = Sequencing::Solexa_Analysis->new(-dbc=>$dbc,-flowcell=>$fc);
	#my $flowcell_dir = $flowcell_dirs{$fc};
	#my @flowcell_paths;
	#if( $flowcell_dir ) {
	#	@flowcell_paths = ( $flowcell_dir );
	#}
	#else {
	#	@flowcell_paths = $solexa_analysis_obj->get_flowcell_directory();
	#}
	
	my @lanes = split( /,/, $flowcell_lanes{$fc} );
	foreach my $lane ( @lanes ) {
		my $solexa_analysis_obj = Sequencing::Solexa_Analysis->new(-dbc=>$dbc,-flowcell=>$fc);
		my $analysis_mode = $solexa_analysis_obj->get_analysis_mode( -lane => $lane, -flowcell_dir => $flowcell_dirs{$fc} );
		print "Solexa Analysis Mode = $analysis_mode\n";
		if( $analysis_mode && $update ) {
		    my %update_analysis_ref;
		    $update_analysis_ref{fields} = ['SolexaAnalysis_Mode'];
		    $update_analysis_ref{values} = [ $analysis_mode];
			$solexa_analysis_obj->update_solexa_analysis_record_by_lane( -lane => $lane, -update_analysis_ref => \%update_analysis_ref );
		}
	} # END foreach $lane
}
