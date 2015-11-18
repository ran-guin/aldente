#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Departments";

use Getopt::Long;
use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;
use File::Find;

### modules for different runs
use alDente::SpectRun;
use alDente::BioanalyzerRun;
use Lib_Construction::GCOS_Report_Parser;

use RGTools::Process_Monitor;

### Global variables
use vars qw($Connection);
use vars qw(%Configs);
###################################
my $mirror_dir  = $Configs{mirror_dir};
my $archive_dir = $Configs{archive_dir};
my $project_dir = $Configs{project_dir};

my ( $opt_user, $opt_dbase, $opt_host, $opt_run, $opt_file, $opt_debug, $opt_force, $opt_keep );

&GetOptions(
    'user=s'  => \$opt_user,
    'dbase=s' => \$opt_dbase,
    'host=s'  => \$opt_host,
    'run=s'   => \$opt_run,     # runs to analyze
    'file=s'  => \$opt_file,    # report files to analyze
    'debug'   => \$opt_debug,
    'force'   => \$opt_force,
    'keep'    => \$opt_keep,    # keep samplesheet in mirror dir (used when run manually)
);

&help_menu() if ( !( $opt_dbase && $opt_user && $opt_host ) );

######################## construct Process_Monitor object for writing to log file ###########
my $Report = Process_Monitor->new();

my $condition = '';
if ($opt_run) {
    my $run_list = &resolve_range($opt_run);
    $condition = "where Run_ID in ($run_list) and Run_Type in ('GenechipRun')";
}
else {
    $condition = "where Run_Status = 'In Process' and Run_Type in ('GenechipRun')";
}

my @files = split( ",", $opt_file );
my $debug = $opt_debug;
my $force = $opt_force;

my %files_hash;

foreach my $item (@files) {
    $files_hash{$item} = 1;
}

my $dbc = SDB::DBIO->new(
    -dbase => $opt_dbase,
    -user  => $opt_user,
    -host  => $opt_host
);
$dbc->connect();

# search all pending runs
my %runs = $dbc->Table_retrieve(
    -table     => "Run",
    -fields    => [ 'Run_ID', 'Run_Type', 'Run_Directory' ],
    -condition => "$condition",
);

my $machine_dir          = "GCOS/01/GCLims/Data/";
my $machine_upload_dir   = "$machine_dir/Upload/";
my $machine_download_dir = "$machine_dir/Download/";

my $mirror_report_dir      = "$mirror_dir/$machine_download_dir/Reports/";
my $mirror_template_dir    = "$mirror_dir/$machine_upload_dir/Templates/";
my $mirror_samplesheet_dir = "$mirror_dir/$machine_upload_dir/SampleSheets/";

my $archive_report_dir      = "$archive_dir/$machine_download_dir/Reports/";
my $archive_samplesheet_dir = "$archive_dir/$machine_upload_dir/SampleSheets/";
my $archive_template_dir    = "$archive_dir/$machine_upload_dir/Templates/";

# change report files in mirror from *.rpt to *.RPT  (the files in mirror are copied by a scheduled task on the windows box)
my @lower_cases;
find sub { push @lower_cases, $File::Find::name if $_ =~ /\.rpt$/ }, $mirror_report_dir;
foreach my $lower_case (@lower_cases) {
    my $uper_case = $lower_case;
    $uper_case =~ s/rpt$/RPT/;
    my $command = "mv $lower_case $uper_case";

    #print "$command\n";
    my $feedback = &try_system_command($command);
    if ($feedback) {
        $Report->set_Detail($feedback);
    }
    else {
        $Report->set_Detail("Moved $lower_case to $uper_case");
    }
}

# move report files from mirror to archive if the SOURCE file is newer than the destination file or when the destination file is missing
# get each file in archive
#   if file ends with 'DONE'
#      if same file (without 'DONE') exisits in mirror, if yes, delete the file in mirror
# mv all files in mirror to archive
my %files_archive;
find sub { $files_archive{$_} = $File::Find::name }, $archive_report_dir;

foreach my $file ( keys %files_archive ) {
    my $archive_file = $files_archive{$file};

    if ( -e $archive_file && !( -d $archive_file ) ) {

        if ( $file =~ /DONE$/ ) {
            $file =~ s/\.DONE$//;
            my $mirror_file = $mirror_report_dir . $file;

            if ( -e $mirror_file ) {

                #delete mirror file
                my $command  = "rm -f $mirror_file";
                my $feedback = &try_system_command($command);
                if ($feedback) {
                    $Report->set_Detail($feedback);
                }
                else {
                    $Report->set_Detail("Deleted $mirror_file");
                }
            }
        }
    }
}

my $feedback;
my $command = "mv -u " . $mirror_report_dir . "*.RPT " . $archive_report_dir;

#print "$command\n";
$feedback = &try_system_command($command);
if ($feedback) {
    $Report->set_Detail($feedback);
}
else {
    $Report->set_Detail("Moved -u $mirror_report_dir.RPT to $archive_report_dir ");
}

# copy new template files to archive (leave the copy in mirror for immediate reference)
$command = "cp -u " . $mirror_template_dir . "*.xml " . $archive_template_dir;

#print "$command\n";
$feedback = &try_system_command($command);
if ($feedback) {
    $Report->set_Detail($feedback);
}
else {
    $Report->set_Detail("Copied $mirror_template_dir.RPT to $archive_template_dir ");
}

if ( !$opt_keep ) {

    # move new samplesheet files to archive
    $command = "mv " . $mirror_samplesheet_dir . "*.xml " . $archive_samplesheet_dir;

    #print "$command\n";
    $feedback = &try_system_command($command);
    if ($feedback) {
        $Report->set_Detail($feedback);
    }
    else {
        $Report->set_Detail("Moved -u $mirror_samplesheet_dir.RPT to $archive_samplesheet_dir ");
    }
}

my $run_dirs_string;
my $index = 0;
while ( exists $runs{Run_ID}->[$index] ) {
    my $run_id        = $runs{Run_ID}->[$index];
    my $run_type      = $runs{'Run_Type'}->[$index];
    my $run_directory = $runs{'Run_Directory'}->[$index];
    $run_dirs_string .= $run_directory . ",";
    $index++;
}

$run_dirs_string =~ s/,$//;

my %analyzed_runs;

# write report file from archive report directory
my @rpt_files;

if ( scalar( keys %files_hash ) > 0 ) {
    foreach my $key ( keys %files_hash ) {
        find sub { push @rpt_files, $File::Find::name if $_ =~ /$key$/ }, $archive_report_dir;
    }
}
else {
    find sub { push @rpt_files, $File::Find::name if $_ =~ /\.RPT$/ }, $archive_report_dir;
}

foreach my $file (@rpt_files) {
    $Report->set_Detail("Processing $file...");
    ## resolve file
    my $new_exp_data = &Lib_Construction::GCOS_Report_Parser::resolve_report( -filename => $file, -dbc => $dbc, -run_directory => $run_dirs_string );

    if ( scalar( keys %$new_exp_data ) > 0 ) {
        ## rewrite file
        my $rewrite_result = &Lib_Construction::GCOS_Report_Parser::rewrite_report( -data => $new_exp_data, -run_directory => $run_dirs_string, -dbc => $dbc, -debug => $debug, -force => $force );

        my $status    = $rewrite_result->{$file}{status};
        my $new_files = $rewrite_result->{$file}{data};

        if ($status) {
            my $command  = "mv " . $file . " " . $file . ".DONE";
            my $feedback = &try_system_command($command);
            if ($feedback) {
                $Report->set_Detail($feedback);
            }
            else {
                $Report->set_Detail("Moved $file to $file.DONE ");
            }
        }
        else {
            $Report->set_Detail("$file NOT DONE");
        }

        ## fill in database
        if ( $new_files && ref $new_files eq 'HASH' ) {
            foreach my $full_path ( keys %{$new_files} ) {
                my $run_name = $new_files->{$full_path};
                $analyzed_runs{$run_name} = 1;
                &Lib_Construction::GCOS_Report_Parser::process_report_file( -run_name => $run_name, -filename => $full_path, -dbc => $dbc );
                $Report->set_Detail("$run_name updated");
            }

        }
        else {
            $Report->set_Detail("No new files");
        }
    }
    else {
        $Report->set_Detail("Skipping $file");
    }

}

$Report->set_Message("Done updating GenechipRuns...");

# if in production and if an experiment has a report, mark the samplesheet in archive directory as 'DONE' so that the Java API will recognize it and  not parse it again
if ( $dbc->{dbase} eq 'sequence' ) {
    $Report->set_Detail("USE PRODUCTION DATABASE");
    foreach my $run_name ( keys %analyzed_runs ) {
        my $full_sample_sheet_name = $archive_samplesheet_dir . $run_name . ".xml";
        if ( -e $full_sample_sheet_name ) {
            my $command  = "mv " . $full_sample_sheet_name . " " . $full_sample_sheet_name . ".DONE";
            my $feedback = &try_system_command($command);

            if ($feedback) {
                $Report->set_Detail($feedback);
            }
            else {
                $Report->set_Detail("Moved $full_sample_sheet_name to $full_sample_sheet_name.DONE");
            }

        }
    }
}
$Report->set_Message("Done running update_genechiprun");

$Report->completed();
$Report->DESTROY();

sub help_menu {
    print "Run script like this:\n\n";
    print "$0\n";
    print "  \t-dbase (e.g. sequence)\n";
    print "  \t-user  (e.g. echuah)\n";
    print "  \t-host  (e.g. lims05)\n";
    exit(0);
}
