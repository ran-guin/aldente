#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Getopt::Long;

use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::RGIO;

### modules for different runs
use alDente::SpectRun;
use alDente::BioanalyzerRun;
use Lib_Construction::GCOS_Report_Parser;

### Global variables
use vars qw($Connection $aldente_upload_dir $aldente_runmap_dir $project_dir $mirror_dir $archive_dir);
use vars qw($bioanalyzer_file_ext $bioanalyzer_img_new_ext $bioanalyzer_img_ext $spect_file_ext);
###################################

# if script itself is running elsewhere, quit
my $command = "ps axw | grep 'update_run.pl' | grep  -v ' 0:00 ' | grep -v ' 0:01 ' | grep -v 'emacs'";
my $current_processes = `$command`;
if ($current_processes) {
    print "** already in process **\n";
    print "-> $current_processes\n";
    exit;
} 

my ($opt_user,$opt_dbase,$opt_host,$opt_password,$opt_run);

&GetOptions(
	    'user=s' => \$opt_user,
	    'dbase=s' => \$opt_dbase,
	    'host=s' => \$opt_host,
	    'password=s' => \$opt_password,
	    'run=s' => \$opt_run,
	    );

&help_menu() if (!($opt_dbase && $opt_user && $opt_password && $opt_host));

my $condition = '';
if ($opt_run) {
    my $run_list = &resolve_range($opt_run);
    $condition = "where Run_ID in ($run_list) and Run_Type in ('SpectRun','BioanalyzerRun','GenechipRun')";
}
else {
    $condition = "where Run_Status = 'In Process' and Run_Type in ('SpectRun','BioanalyzerRun','GenechipRun')";
}

$dbc = SDB::DBIO->new(-dbase=>$opt_dbase,
			     -user=>$opt_user,
			     -password=>$opt_password,
			     -host=>$opt_host
			     );
$dbc->connect();

# search all pending runs
my %runs = $dbc->Table_retrieve(-table=>"Run",
				       -fields=>['Run_ID','Run_Type','Run_Directory'],
				       -condition=>"$condition",
				       -key=>'Run_ID'
				       );

foreach my $run_id (sort{$a<=>$b} keys %runs){
    my $run_type = $runs{$run_id}->{'Run_Type'};
    my $run_directory = $runs{$run_id}->{'Run_Directory'};
    print "Processing Run (Run ID $run_id)...\n";


    ##############################
    ######## SpectRun
    ##############################
    if($run_type eq "SpectRun"){
	my $file = $run_id . $spect_file_ext;
	my $upload_dir = "$aldente_upload_dir/$run_type";
	my $new_dir = "$upload_dir/New";  # source directory (user upload file)
	my $old_dir = "$upload_dir/$run_directory";  # destination directory

	if(-e "$new_dir/$file"){
	    my $data = alDente::SpectRun::parse_spect_output(-file=>"$new_dir/$file");
	    my $status = alDente::SpectRun::populate_spect_output(-data=> $data);

	    if(!$status){
		Message("Error: problem inserting into database.");
	    }
	    else{
		`mv $new_dir/$file $old_dir/$file`;
		`ln -s $old_dir/$file $aldente_runmap_dir/Run$file`;
	    }
	}
	else{
	    print "\tNo file found. Skipping...\n";
	}
    }

    ##############################
    ######## BioanalzyerRun
    ##############################
    elsif($run_type eq "BioanalyzerRun"){
	my $file = $run_id . $bioanalyzer_file_ext;
	my $upload_dir = "$aldente_upload_dir/$run_type";
	my $new_dir = "$upload_dir/New";  # source directory (user upload file)

	if(-e "$new_dir/$file"){
	    my $data = alDente::BioanalyzerRun::parse_bioanalyzer_output(-file=>"$new_dir/$file");
	    my $status = alDente::BioanalyzerRun::populate_bioanalyzer_output(-data=> $data);

	    if(!$status){
		Message("Error: problem inserting into database.");
	    }
	    else{
		my $old_dir = "$upload_dir/$run_directory";  # destination directory
		`mv $new_dir/$file $old_dir/$file`;
		`ln -s $old_dir/$file $aldente_runmap_dir/Run$file`;
		
		### find all run ids associated with master run id & move the electropherogram for each sample to new directory
		### Aassumes that electropherogram has file format of MasterRunID_well.bmp
		### e.g. if run 44203 is associated with master run 44202 and 44202 is well #2, then image will be 44202_2.bmp

		my %run_dirs = $dbc->Table_retrieve(-table=>"Run,MultiPlate_Run,BioanalyzerRead",
							   -fields=>['Well','Run_Directory','Run_ID'],
							   -condition=>"where MultiPlate_Run.FK_Run__ID = Run_ID and FKMaster_Run__ID = $run_id and BioanalyzerRead.FK_Run__ID = Run_ID",
							   -key=>'Well'
							   );
		foreach my $well (keys %run_dirs){
		    my $old_dir = "$upload_dir/$run_dirs{$well}->{'Run_Directory'}";
		    my $img = "$run_id" . "_$well";
		    my $new_img = "$run_dirs{$well}->{'Run_ID'}";
		    my $new_image = "$new_dir/$img$bioanalyzer_img_ext";  # new file
		    my $old_image = "$old_dir/$new_img$bioanalyzer_img_new_ext";  # destination file
		    if(! -e $new_image){
			next;
		    }
		    # convert bmp file to jpg format
		    &RGTools::RGIO::make_thumbnail(-input=>"$new_dir/$img$bioanalyzer_img_ext",-output=>"$new_dir/$new_img$bioanalyzer_img_new_ext");
		    my $thumbnail = "$old_dir/$new_img" . "_small$bioanalyzer_img_new_ext";
		    my $img_link = "$aldente_runmap_dir/Run$new_img$bioanalyzer_img_new_ext";
		    my $thumbnail_link = "$aldente_runmap_dir/Run$new_img" . "_small$bioanalyzer_img_new_ext";
		    `mv $new_dir/$new_img$bioanalyzer_img_new_ext $old_image`;
		    `rm -f $new_image`;
		    # create thumbnail
		    &RGTools::RGIO::make_thumbnail(-input=>$old_image,-output=>$thumbnail,-resize=>'100x100');
		    # create symbolic links
		    `ln -s $old_image $img_link`;
		    `ln -s $thumbnail $thumbnail_link`;
		}
	    }
	}
	else{
	    print "\tNo file found.  Skipping...\n";
	}
    }

    ##############################
    ######## GelRun
    ##############################
    elsif($run_type eq "GelRun"){



    }

    ##############################
    ######## GenechipRun
    ##############################
    elsif ($run_type eq 'GenechipRun') {

      my $machine_dir = "GCOS/01/GCLims/Data/";
      my $machine_upload_dir = "$machine_dir/Upload/";
      my $machine_download_dir = "$machine_dir/Download/";

      my $mirror_report_dir = "$mirror_dir/$machine_download_dir/Reports/";
      my $mirror_template_dir = "$mirror_dir/$machine_upload_dir/Templates/";
      my $mirror_samplesheet_dir = "$mirror_dir/$machine_upload_dir/SampleSheets/";

      my $archive_report_dir = "$archive_dir/$machine_download_dir/Reports/";
      my $archive_samplesheet_dir = "$archive_dir/$machine_upload_dir/SampleSheets/";
      my $archive_template_dir = "$archive_dir/$machine_upload_dir/Templates/";

      # move files from mirror to archive
      my $command = "mv ".$mirror_report_dir."*.RPT ".$archive_report_dir;
      &try_system_command($command);
      $command = "mv ".$mirror_template_dir."*.xml ".$archive_template_dir;
      &try_system_command($command);
      $command = "mv ".$mirror_samplesheet_dir."*.xml ".$archive_samplesheet_dir;
      &try_system_command($command);

      my %analyzed_runs;

      # write report file from archive report directory
      my @rpt_files;
      find sub {push (@rpt_files, $File::Find::name) if $_ =~ /\.RPT$/}, $archive_report_dir;

      foreach my $file (@rpt_files){
	my $new_files = &Lib_Construction::GCOS_Report_Parser::rewrite_report(-filename=>$file,-dbc=>$dbc);
	# mark the file in archive as DONE

	if ($new_files && ref $new_files eq 'HASH'){
	  foreach my $full_path(keys %{$new_files}){
	    my $run_name = $new_files->{$full_path};
	    $analyzed_runs{$run_name} = 1;
	    &Lib_Construction::GCOS_Report_Parser::process_report_file(-run_name=>$run_name,-filename=>$full_path,-dbc=>$dbc);
	  }
	}

	my $command = "mv ".$file." ".$file.".DONE";
	system ($command);
      }

      # if in production and if an experiment has a report, mark the samplesheet in archive directory as 'DONE' so that the Java API will recognize it and  not parse it again
      if ($dbc->{dbase} eq 'sequence') {
	foreach my $run_name (keys %analyzed_runs){
	  my $full_sample_sheet_name = $archive_samplesheet_dir.$run_name.".xml";
	  if (-e $full_sample_sheet_name){
	    my $command = "mv ".$full_sample_sheet_name." ".$full_sample_sheet_name.".DONE";
	    system ($command);
	  }
	}
      }

    }
}

sub help_menu {
    print "Run script like this:\n\n";
    print "$0\n";
    print "  \t-dbase (e.g. sequence)\n";
    print "  \t-user  (e.g. echang)\n";
    print "  \t-password\n";
    print "  \t-host  (e.g. lims01)\n";
    exit(0);
}
