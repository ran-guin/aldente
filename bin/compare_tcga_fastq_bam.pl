#!/usr/local/bin/perl-5.18.2/bin/perl

use strict;
use warnings;

use DBI;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib $FindBin::RealBin . "/../lims/lib/perl/";
use lib $FindBin::RealBin . "/../lims/lib/perl/Core";
use lib $FindBin::RealBin . "/../lims/lib/perl/Imported";
use lib $FindBin::RealBin . "/../lims/lib/perl/Experiment";
use lib $FindBin::RealBin . "/../lims/lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lims/lib/perl/Departments";
use lib $FindBin::RealBin . "/../lims/custom/GSC/modules";

use RGTools::RGIO;
use SDB::DBIO;

use File::Basename;
use File::Spec;
use IPC::Run3;
use List::MoreUtils;
use SRA::ArchiveIO;
use XML::Simple;

our ( $opt_help, $opt_barcode, $opt_library, $opt_temp_dir, $opt_tx_host );


&GetOptions(
    'help|h|?'   => \$opt_help,
    'barcode=s'  => \$opt_barcode,
    'library=s'  => \$opt_library,
    'temp_dir=s' => \$opt_temp_dir,
    'tx_host=s'  => \$opt_tx_host,
);

my $input_barcode = $opt_barcode;
my $input_lib = $opt_library;
my $temp_dir = $opt_temp_dir || '/projects/prod_scratch1/lims/test';
my $tx_host = $opt_tx_host || 'gtorrent01';


my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>'lims05',-user=>'cron_user',-connect=>1);

my @barcodes;

if ($input_barcode) {
	@barcodes = Cast_List (-to => 'array', -list => $input_barcode);
}

elsif ($input_lib) {
	my $quoted_lib_str = Cast_List (-to => 'string', -list => $input_lib, -autoquote => 1);

	@barcodes = $dbc->Table_find(	
		-table => 'Source join Sample on FK_Source__ID = Source_ID',
		-fields => 'External_Identifier',
		-condition => "where Sample.FK_Library__Name in ($quoted_lib_str)",
		-distinct => 1,
	);
}

print '-' x 40, "\n";

foreach my $barcode (@barcodes) {

	print "$barcode validation\n";
    print '-' x 5, "\n";


	my $metadata = SRA::ArchiveIO::download_cgHub_metadata(
		-study => 'phs000178',
		-state => 'live',
		-center_name => 'BCCAGSC',
		-library_strategy => 'RNA-Seq',
		-legacy_sample_id => $barcode,
		-summary => 1
	);
	
	my $hash = XMLin($metadata, ForceArray => [ 'Result', 'EXPERIMENT', 'ANALYSIS', 'RUN', 'file' ]);
	my $info = $hash->{Result};


    my $download_path = RGTools::RGIO::create_dir(
            -path         => $temp_dir,
            -subdirectory => $barcode,
            -mode         => 775
    );

	my (%read_count_of, %read_names_of);
	my $fastq_analysis_id;


	while (my ($result_num, $result) = each (%{$info})) {

		my $analysis_id = $result->{analysis_id};

		$read_count_of{$analysis_id} = 0;
		$read_names_of{$analysis_id} = [];

    	my @file_array = Cast_List( -list => $result->{files}->{file}, -to => 'array' );

    	foreach my $file_hash (@file_array) {
	        my $filename = $file_hash->{filename};

	        my $analysis_dir = File::Spec->catdir( $download_path, $analysis_id);
   	        my $file_path = File::Spec->catfile( $analysis_dir, $filename );

	        if ($filename =~ /bam$/) {

		        if ( -e $file_path ) {
		            print "File $file_path already downloaded\n";
		        }
		        else {
		        	print "Downloading $analysis_id to $download_path\n";
		            my $success = SRA::ArchiveIO::download_cgHub_file( -analysis_id => $analysis_id, -host => $tx_host, -path => $download_path );
		        }

	        	my $flagstat_file = $file_path.".flagstat";
	        	my ($stdout, $stderr);

	        	if (! -e $flagstat_file) {

		        	my $cmd = "/gsc/software/linux-x86_64/samtools-0.1.17/samtools flagstat $file_path";
		        	print $cmd."\n";
		        	IPC::Run3::run3( $cmd, \undef, \$stdout, \$stderr );

		        	print $stderr if $stderr;

		        	if ($stdout) {
		        		open(FILE, ">", $flagstat_file);
		        		print FILE $stdout;
		        		close(FILE);
		        	}
	        	}

	        	open(FLAGSTAT, "<", $flagstat_file);
	        	my $read_count_line = <FLAGSTAT>;

	        	my ($qc_passed_reads, $qc_failed_reads);
	        	
	        	if ($read_count_line =~ /^(\d+) \+ (\d+) in total/) {
	        		$qc_passed_reads = $1;
	        		$qc_failed_reads = $2;

	        	}

	        	$read_count_of{$analysis_id} += ($qc_passed_reads + $qc_failed_reads);

	        	my $cmd = "/gsc/software/linux-x86_64/samtools-0.1.17/samtools view -H $file_path | grep '\@RG'";
		        print $cmd."\n";
		        IPC::Run3::run3( $cmd, \undef, \$stdout, \$stderr );

		        print $stderr if $stderr;

		        my @rg_lines = split /\n/, $stdout;

		        foreach my $rg_line (@rg_lines) {

		        	my ($tag_name, $run_id, $rg_barcode);

		        	my @rg_cols = split /\s+/, $rg_line;
		        	($tag_name, $run_id) = split /:/, $rg_cols[1];
		        	($tag_name, $rg_barcode) = split /:/, $rg_cols[5];

		        	if ($barcode ne $rg_barcode) {
		        		print "ERROR: Header contains barcode $rg_barcode, expected barcode $barcode\n";
		        	}

		      		my %run_data = $dbc->Table_retrieve(
		        		-table => 'Run join SolexaRun on FK_Run__ID = Run_ID join RunBatch on FK_RunBatch__ID = RunBatch_ID join Equipment on FK_Equipment__ID = Equipment_ID',
		        		-fields => ['Equipment_Name', 'Lane'],
		        		-condition => "where Run_ID = $run_id"
		        	);

		      		push @{$read_names_of{$analysis_id}}, $run_data{Equipment_Name}->[0]."/".$run_data{Lane}->[0];
		        }


		    }

		    elsif($filename =~ /tar$/) {

		    	### For clarity in the rest of the code
		    	my $tar_file_path = $file_path;
		    	$fastq_analysis_id = $analysis_id;


		        if ( -e $tar_file_path ) {
		            print "File $tar_file_path already downloaded\n";
		        }
		        else {
		        	print "Downloading $analysis_id to $download_path\n";
		            my $success = SRA::ArchiveIO::download_cgHub_file( -analysis_id => $analysis_id, -host => $tx_host, -path => $download_path );
		        }
		       	my ($stdout, $stderr);

		       	my $tar_content_list = File::Spec->catfile($analysis_dir, 'tar_contents.txt');

		       	if (!-e $tar_content_list) {
		       		my $cmd = "tar -tvf $tar_file_path";
		        	print $cmd."\n";
		        	IPC::Run3::run3( $cmd, \undef, \$stdout, \$stderr );

		        	print $stderr if $stderr;
		        	if ($stdout) {
		        		open(FILE, ">", $tar_content_list);
		        		print FILE $stdout;
		        		close(FILE);
		        	}
		       	}


		       	my %file_size_of;

		       	open(CONTENTS_FILE, "<", $tar_content_list);

		       	while (my $line = <CONTENTS_FILE>) {
		       		my @cols = split /\s+/, $line;

		       		$file_size_of{$cols[5]} = $cols[2];
		       	}


		       	foreach my $gzip_file (keys %file_size_of) {

		       		my $gzip_file_path = File::Spec->catfile($analysis_dir, $gzip_file);

		       		if (! -e $gzip_file_path) {
		       			my $cmd = "tar -C $analysis_dir -xvf $tar_file_path";
		        		print $cmd."\n";
		        		IPC::Run3::run3( $cmd, \undef, \$stdout, \$stderr );

		        		print $stderr if $stderr;
		       		}

		       		my @stat_cols = stat($gzip_file_path);

		       		if ($stat_cols[7] == $file_size_of{$gzip_file}) {
		       			print "$gzip_file OK\n";
		       		}
		       		else {
		       			print "ERROR: $gzip_file not OK, deleting...\n";
		       			unlink($gzip_file_path);
		       			last;
		       		}

		       		my $fastq_read_count_file = File::Spec->catfile($analysis_dir, $gzip_file.".count");

		       		if (!-e $fastq_read_count_file) {

			       		my $fastq_line_count;

			       		print "Counting lines of $gzip_file\n";

		       			my $cmd = "gunzip -c $gzip_file_path | wc";
		        		print $cmd."\n";
		        		IPC::Run3::run3( $cmd, \undef, \$stdout, \$stderr );

		        		print $stderr if $stderr;

		        		if ($stdout =~ /^\s*(\d+)/) {
		        			$fastq_line_count = $1;
		        		}

						$fastq_line_count /= 4;
						open(COUNT_FILE, ">", $fastq_read_count_file);
						print COUNT_FILE $fastq_line_count;
						close(COUNT_FILE);
					}

					$stdout = undef;

					my $cmd = "gunzip -c $gzip_file_path | head -1";
		        	print $cmd."\n";
		        	IPC::Run3::run3( $cmd, \undef, \$stdout, \$stderr );

		        	print $stderr if $stderr;
					
					if ($stdout =~ /^\@(\w+):(\d)/) {
						my $machine = $1;
						my $lane    = $2;

						$machine =~ s/_.*//;
						$machine =~ s/HS/HiSeq-/;
						$machine =~ s/SOLEXA/GA-/;

						push @{$read_names_of{$analysis_id}}, "$machine/$lane";
					}

					open(COUNT_FILE, "<", $fastq_read_count_file);
					$read_count_of{$analysis_id} += <COUNT_FILE>;
					close(COUNT_FILE);
		       	}
		    }


    	} ## End foreach ($file)

    	print '-' x 5, "\n";

	}

	if (!defined( $fastq_analysis_id )) {
		print "ERROR: No live FASTQ found for $barcode, halting comparison\n";
		last;
	}

	my $fastq_read_count = delete( $read_count_of{$fastq_analysis_id} );
	my @fastq_read_names   = sort( List::MoreUtils::uniq( @{ delete( $read_names_of{$fastq_analysis_id} ) } ) );

	foreach my $bam_analysis_id (keys %read_count_of) {

		print "Matching BAM $bam_analysis_id -> FASTQ $fastq_analysis_id\n";


		my $bam_read_count = $read_count_of{$bam_analysis_id};
		my @bam_read_names   = sort( List::MoreUtils::uniq( @{ $read_names_of{$bam_analysis_id} } ) );


		if ( $bam_read_count == $fastq_read_count ) {
			print "Matched read count: BAM [$bam_read_count] - FASTQ [$fastq_read_count]\n";
		}
		else {
			print "ERROR: Mismatched read count: BAM [$bam_read_count] - FASTQ [$fastq_read_count]\n";
		}


    	my $iterator = List::MoreUtils::each_array(@fastq_read_names, @bam_read_names);
    	while ( my ($fastq_read_name, $bam_read_name) = $iterator->() ) {
			if ( $fastq_read_name eq $bam_read_name ) {
				print "Matched read name: BAM [$bam_read_name] - FASTQ [$fastq_read_name]\n";
			}
			else {
				print "ERROR: Mismatched read name: BAM [$bam_read_name] - FASTQ [$fastq_read_name]\n";
			}
    	}
	}

	print '-' x 40, "\n";
}
