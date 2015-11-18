#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
# performance_monitor.pl 
#
# This program runs allows monitoring of slow page and slow query logs to summarize sources of poor performance.
#
##################################################
use strict;
use CGI qw(:standard);
use DBI;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;


use SDB::DBIO;
 
use SDB::Report;                ## Seq_Notes
use SDB::HTML;
use SDB::CustomSettings;

use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Process_Monitor;

use alDente::Employee;
use alDente::Notification;     ## Notification module
use alDente::Diagnostics;      ## Diagnostics module
use alDente::SDB_Defaults;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_S $opt_C $opt_D $opt_X $opt_A $opt_I $opt_R $opt_T $opt_f $opt_F $opt_G);
use vars qw($Data_log_directory $testing $html_header);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
require "getopts.pl";
&Getopts('SDX:IRT:fF:GC');

######################## construct Process_Monitor object for writing to log file ###########
my $Report = Process_Monitor->new(
				  -quiet => 0,
				  -verbose => 0
				  );
my $today = &datestamp;
my $database = $Configs{PRODUCTION_DATABASE};
my $home = "$URL_domain/$URL_dir_name/cgi-bin/barcode.pl?User=Auto&Database=$database";

my $log_directory = $Data_log_directory;
my $slow_page_dir = "$log_directory/slow_pages";

### Create the file for tomorrow
my $tomorrow = &datestamp('+1d');
try_system_command("touch $slow_page_dir/$tomorrow");
try_system_command("chmod 666 $slow_page_dir/$tomorrow");
try_system_command("rm -rf $slow_page_dir/current");
try_system_command("ln -s $slow_page_dir/$tomorrow $slow_page_dir/current");


if (-e "$slow_page_dir/$today") {
open(FILE,"$slow_page_dir/$today") or die ( $Report->set_Error("Cannot open slow page file $slow_page_dir/$today."),
					    $Report->DESTROY(),	       					    
					   );
}
else {
    $Report->set_Message("Slow page file $slow_page_dir/$today does not exist");
    $Report->completed();
    exit;
#					    $Report->DESTROY(),	       					         
}

### This allows us to determine the type of queries that are generating slow responses.  If these parameters are defined, then the slow pages are labelled as such ###

my @check_params = ('Aliquot Solution','Make Std Solution','Multipage_Form','Last 24 Hours','Confirm Primer Plates','Confirm QPIX log','Pick From Qpix','Remove Run Request','Rearray Action','Save Original Stock','Freeze Protocol','Agar_Plates','Upload Band file','Upload Yield Report','Date Range Summary','Set Validation Status','FormNav','Barcode_Event','PlateToTubeTransfer','FormData','Check Recent Plates','Check Submissions','Prep Summary','Protocol Summary','Plate_Event','Continue Prep','Aliquot Solution');

my %Slow_Load;
my %Found;
my $count = 0;
while (<FILE>) {
    my $line = $_;
    if ($line =~ /Slow Page Load Time Noted \((\d+) s/) {
	$count++;
	$Slow_Load{$count}{Time} = $1;
    }
    if ($line =~/\/SDB\/cgi-bin\/(\w*\.pl)\?/) {
	$Slow_Load{$count}{application} = $1;
    } elsif ($line =~/^Input Parameters:/) {
	my $input = $line;
	while ($line =~/^(\t|\w)/) {
	    if ($line =~ /^User = (\w+)/) {
		$Slow_Load{$count}{User} = $1;
	    } 
	    elsif ($line =~ /^Use Library = (\w+)/) {
		$Slow_Load{$count}{library} = $1;
	    }  
	    elsif ($line =~ /^SeqRun_View = (\d+)/) {
	#	$Slow_Load{$count}{action} .= "Run_view;";
		$Slow_Load{$count}{Run} = $1;
	    } 
	    elsif ($line =~ /^Prep Step Name \= ([\w\s]+)/) {
		$Slow_Load{$count}{prep} = $1;
	    } 
	    elsif ($line =~ /^([\w\s]+) \=/) {
		my $param = $1;
		if ((grep /^$param$/, @check_params) && !$Slow_Load{$count}{action}) {
		    $Slow_Load{$count}{action} = $param;
		}
	    }
	    $line = <FILE>;
	    $input .= $line;
	}
	$Slow_Load{$count}{action} ||= "Unknown;";
	push(@{$Found{$Slow_Load{$count}{action}}{times}}, $Slow_Load{$count}{Time});
	push(@{$Found{$Slow_Load{$count}{action}}{very_slow_times}}, $Slow_Load{$count}{Time}) if ($Slow_Load{$count}{Time} > 30);
	$Report->set_Detail(Dumper($Slow_Load{$count}));  ## before loading full input... 
	$Slow_Load{$count}{input} = $input;
        $Report->succeeded();
    }
}
close(FILE) or die "Problem closing slow page file";

## now dump full input in case this is useful...
foreach my $num (1..$count) {
   $Report->set_Detail(Dumper($Slow_Load{$num}));
}

foreach my $key (keys %Found) {
    my @times = @{$Found{$key}{times}};
    my $count = int(@times);
    $Report->set_Warning("Slow Page Generation for: $key ($count instances: @times)");
    
    if (defined $Found{$key}{very_slow_times}) {
	my @very_slow_times = @{$Found{$key}{very_slow_times}};
	my $vs_count = int(@very_slow_times);
	$Report->set_Warning("VERY Slow Page Generation for: $key ($vs_count instances: @very_slow_times)");
    }
}

$Report->completed();

exit;
