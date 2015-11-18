#!/usr/local/bin/perl

use strict;
use DBI;
use Data::Dumper;
use GD::Graph::bars;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core/"; # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Imported/"; # add the local directory to the lib search path

 
use SDB::CustomSettings;
use SDB::DBIO;
use RGTools::RGIO;
use RGTools::HTML_Table;
use alDente::SDB_Defaults;
use alDente::Sequencing;
use vars qw($data_log_directory);

my $LOG_FILE = "$data_log_directory/usage.log";   # Location of the usage log file
my $TOP_X_GROWTH_SIZE = 5;                                # Top # of growth we want to monitor in terms of size
my $TOP_X_GROWTH_PERCENT = 5;                             # Top # of growth we want to monitor in terms of percentage      

my %Months = (Jan=>1,Feb=>2,Mar=>3,Apr=>4,May=>5,Jun=>6,Jul=>7,Aug=>8,Sep=>9,Oct=>10,Nov=>11,Dec=>12); 

# Get raw file size info
open(FILE,$LOG_FILE) or die("Cannot open file '$LOG_FILE'");
my %info;
my $day_of_week;
my $month;
my $day;
my $year;
while (<FILE>) {
    my $line = $_;
    if ($line =~ /([a-zA-Z]{3})\s{1}([a-zA-Z]{3})\s{1}(\d{2})\s{1}\d{2}\:\d{2}\:\d{2}\s{1}[A-Z]{3}\s{1}(\d{4})/) {
	$day_of_week = $1;
	$month = $2;
	$day = $3;
	$year = $4;
    }
    elsif ($line =~ /(\d+)\s+(.*)/) {
	my $size = $1;
	my $file = $2;
	$info{$year}{$month}{$day}{$file} = $size;
    }
}
close(FILE);

# Calculate growth data
my %size_growths;        # Track all size growths
#my %percent_growths;     # Track all percent growths
my %existing_files;      # Track all existing files
foreach my $year (sort {$a <=> $b} keys %info) {
    foreach my $month (sort {$Months{$a} <=> $Months{$b}} keys %{$info{$year}}) {
	foreach my $day (sort {$a <=> $b} keys %{$info{$year}{$month}}) {
	    foreach my $file (sort keys %{$info{$year}{$month}{$day}}) {
		my $size = $info{$year}{$month}{$day}{$file};
		if (exists $existing_files{$file}) {
		    if ($size > 0) {
			my $max_index = () = keys %{$existing_files{$file}};
			my $size_growth = $size - $existing_files{$file}{$max_index};
			#my $percent_growth = $size_growth / $existing_files{$file}{$max_index} * 100;
			#$percent_growth = sprintf("%.2f",$percent_growth);
			
			push(@{$size_growths{$year}{$month}{$day}{$size_growth}},$file);
			#push(@{$percent_growths{$year}{$month}{$day}{$percent_growth}},$file);
			
			$existing_files{$file}{$max_index + 1} = $size;
		    }
		}
		else {
		    if ($size > 0) {
			$existing_files{$file}{1} = $size;  # First time see this file
		    }
		}
	    }
	}
    }
}

# Report top X growths in terms of size and percent
print ">>>Top 5 Growths in Size:\n\n";
Y:foreach my $year (sort {$a <=> $b} keys %size_growths) {
M:    foreach my $month (sort {$Months{$a} <=> $Months{$b}} keys %{$size_growths{$year}}) {
D:	foreach my $day (sort {$a <=> $b} keys %{$size_growths{$year}{$month}}) {
            my $i = 1;
	    print ">$month $day, $year\n";
S:	    foreach my $size_growth (sort {$b <=> $a} keys %{$size_growths{$year}{$month}{$day}}) {
		if ($i > $TOP_X_GROWTH_SIZE) {last S}
		if ($size_growth > 0) {
		    my ($size,$units) = _get_readable_size($size_growth);
		    print "$size $units (" . join(",", @{$size_growths{$year}{$month}{$day}{$size_growth}}) . ")\n";
		}
		$i++;
	    }
	    print "\n";
	}
    }
}

sub _get_readable_size {
    my $size = shift;
    
    my @units = ('KB','MB','GB','TB','PB','EB','ZB','YB');
    my $i = 0;
    
    while (($size / 1024) > 1) {
	$size = $size / 1024;
	$i++;
    }

    return ($size,$units[$i]);
}
