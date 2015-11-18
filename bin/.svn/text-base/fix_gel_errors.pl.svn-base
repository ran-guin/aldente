#!/usr/local/bin/perl


use strict;
use Data::Dumper;
use Getopt::Long;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;

use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Lane;


our ( $opt_help, $opt_host, $opt_db, $opt_user, $opt_password, $opt_first_run, $opt_second_run, $opt_runlist, $opt_to_format, $opt_proceed );


# process command line options
&GetOptions(
    'help'                  => \$opt_help,
    'host=s'                => \$opt_host,
    'db=s'                  => \$opt_db,
    'user=s'                => \$opt_user,
    'password=s'            => \$opt_password,
    'first_run=s'           => \$opt_first_run,
    'second_run=s'          => \$opt_second_run,
    'runlist=s'             => \$opt_runlist,
    'to_format=s'           => \$opt_to_format,
    'proceed=s'               => \$opt_proceed,
);


my $host	 = $opt_host;
my $dbase    = $opt_db;
my $user     = $opt_user;
my $password = $opt_password;
my $help     = $opt_help;
my $first_run   = $opt_first_run;
my $second_run  = $opt_second_run;
my $runlist  = $opt_runlist;
my $to_format   = $opt_to_format;
my $globalproceed = $opt_proceed;

if ($help) {
    help();
    exit;
}

unless ($dbase and $user and $password and ( ($first_run and $second_run) or ($runlist and $to_format) ) ) {
    print "Missing parameters.\n";
    help();
    exit;
}

my $dbc = SDB::DBIO->new(-host=>$host,-dbase=>$dbase,-user=>$user,-password=>$password,-connect=>1);

if ($first_run and $second_run) {
    &fix_sample_swaps(-dbc=>$dbc,-first_run=>$first_run,-second_run=>$second_run);
}
elsif ($runlist and $to_format) {

    my $to_format_id;
    if (lc($to_format) eq 'ferro') {
        $to_format = 'Ferro 121 Lane Gel';
    }
    elsif (lc($to_format) eq 'hamilton') {
        $to_format = 'Manual 121 Lane Gel';
    }
    else {
        Message("Error: Incorrect to_format '$to_format'");
        help();
        exit;
    }

    &set_load_format(-dbc=>$dbc,-to_format=>$to_format,-runlist=>$runlist);


}
else {
    Message("Invalid arguments");
    help();
    exit;
}

############################
#
# Updates the Sample_IDs and Lane to Well mapping for swapped plates
#
#   Retrieve Mapping for the two plates
#   Take the Sample Name and Well fields from first run, and swap them with Sample name and Well fields with the second run
#
############################
sub set_load_format {
############################
    my %args = &filter_input(\@_,-args=>'dbc,runlist,to_format',-mandatory=>'dbc,runlist,to_format');

    my $dbc             = $args{-dbc};
    my $runlist         = $args{-runlist};
    my $to_format       = $args{-to_format};


    my ($to_format_id) = $dbc->Table_find('Plate_Format','Plate_Format_ID',"WHERE Plate_Format_Type='$to_format'");

    my $plate_ids = join ',', $dbc->Table_find('Run','FK_Plate__ID',"WHERE Run_ID IN ($runlist)");

    if (int(split(',',$plate_ids)) != int(split(',',$runlist))) {
        Message("Error: Invalid runs");
        return undef;
    }

    $dbc->start_trans('fix_loadformat');

    my $update = $dbc->Table_update_array('Plate',['FK_Plate_Format__ID'],[$to_format_id],"WHERE Plate_ID IN ($plate_ids)");
    Message("Updated Format of $update plates. Will now proceed to updating of Lane mappings...");

    my $mapping = &alDente::Lane::_get_lane_well_mapping(-dbc=>$dbc,-run_ids=>$runlist,-fields=>['Run_ID','FK_GelRun__ID','Well','FK_Sample__ID','Lane_Number']);

    $update = 0;
    foreach my $entry (@{$mapping}) {
        $update += $dbc->Table_update_array('Lane',['FK_Sample__ID','Well'],[$entry->[3],$entry->[2]],"WHERE FK_GelRun__ID = $entry->[1] AND Lane_Number='$entry->[4]'",-autoquote=>1);
    }

    Message("Updated $update Lane entries");


    $dbc->finish_trans('fix_loadformat');

}


############################
#
# Updates the Sample_IDs and Well to well mapping for swapped plates
#
#   Retrieve Mapping for the two plates
#   Take the Sample Name and Well fields from first run, and swap them with Sample name and Well fields with the second run
#
############################
sub fix_sample_swaps {
############################
    my %args = &filter_input(\@_,-args=>'dbc,first_run,second_run',-mandatory=>'dbc,first_run,second_run');

    my $dbc         = $args{-dbc};
    my $first_run   = $args{-first_run};
    my $second_run  = $args{-second_run};
    my $proceed = $globalproceed || 0;

    #Get basic information about the two runs
    my ($run_1) = $dbc->Table_find('Run,Plate,Library,Project,Plate_Format',"FK_Plate__ID,Run_Directory,concat('$Configs{project_dir}','/',Project.Project_Path,'/',Library.Library_Name,'/AnalyzedData/',Run.Run_Directory),Plate_Format_Type","WHERE Run_ID = $first_run AND FK_Plate__ID = Plate_ID AND FK_Library__Name = Library_Name AND FK_Project__ID = Project_ID AND FK_Plate_Format__ID = Plate_Format_ID");
    my ($run_2) = $dbc->Table_find('Run,Plate,Library,Project,Plate_Format',"FK_Plate__ID,Run_Directory,concat('$Configs{project_dir}','/',Project.Project_Path,'/',Library.Library_Name,'/AnalyzedData/',Run.Run_Directory),Plate_Format_Type","WHERE Run_ID = $second_run AND FK_Plate__ID = Plate_ID AND FK_Library__Name = Library_Name AND FK_Project__ID = Project_ID AND FK_Plate_Format__ID = Plate_Format_ID");

    my ($first_plate,$first_rundir,$first_fulldir,$first_format) = split(',',$run_1);
    my ($second_plate,$second_rundir,$second_fulldir,$second_format) = split(',',$run_2);
    
    print "1: $first_plate\n";
    print "2: $second_plate\n";

    print "1: $first_rundir\n";
    print "2: $second_rundir\n";

    print "1: $first_fulldir\n";
    print "2: $second_fulldir\n";

    print "1: $first_format\n";
    print "2: $second_format\n";

    #Get archive link for the 2 runs
    my $first_archive_info = try_system_command("find $first_fulldir/image.tif -ls");
    my @parts = split (/\s/, $first_archive_info);
    my ($first_archive) = grep (/$first_rundir\.run/, @parts);

    my $second_archive_info = try_system_command("find $second_fulldir/image.tif -ls");
    my @parts = split (/\s/, $second_archive_info);
    my ($second_archive) = grep (/$second_rundir\.run/, @parts);

    print "1: $first_archive\n";
    print "2: $second_archive\n";

    #Get new archive file name
    my $first_new_archive = $first_archive;
    $first_new_archive =~ s/$first_rundir/$second_rundir/;

    my $second_new_archive = $second_archive;
    $second_new_archive =~ s/$second_rundir/$first_rundir/;

    print "1: $first_new_archive\n";
    print "2: $second_new_archive\n";

    #rename archive file name
    print "1: mv $first_archive $first_new_archive\n";
    print "2: mv $second_archive $second_new_archive\n";
    try_system_command("mv $first_archive $first_new_archive") if $proceed;
    try_system_command("mv $second_archive $second_new_archive") if $proceed;


    #clear originally run directory image link and stats
    print "1: rm $first_fulldir/image.tif\n";
    print "1: rm $first_fulldir/stats.html\n";
    print "2: rm $second_fulldir/image.tif\n";
    print "2: rm $second_fulldir/stats.html\n";
    try_system_command("rm $first_fulldir/image.tif") if $proceed;
    try_system_command("rm $first_fulldir/stats.html") if $proceed;
    try_system_command("rm $second_fulldir/image.tif") if $proceed;
    try_system_command("rm $second_fulldir/stats.html") if $proceed;


    #re-symlink to proper image (a swap happen here)
    print "1: ln -s $first_new_archive $second_fulldir/image.tif\n";
    print "2: ln -s $second_new_archive $first_fulldir/image.tif\n";
    try_system_command("ln -s $first_new_archive $second_fulldir/image.tif") if $proceed;
    try_system_command("ln -s $second_new_archive $first_fulldir/image.tif") if $proceed;

    #Updating run comments
    my $note1 = " Swapped with $second_run;";
    $note1 = $dbc->dbh()->quote($note1);
    $note1 = "CONCAT(Run_Comments,$note1)";
    my $note2 = " Swapped with $first_run;";
    $note2 = $dbc->dbh()->quote($note2);
    $note2 = "CONCAT(Run_Comments,$note2)";

    $first_rundir = $dbc->dbh()->quote($first_rundir);
    $second_rundir = $dbc->dbh()->quote($second_rundir);

    #Begin update database
    if ($proceed) {

	$dbc->start_trans('fix_swap');
	
	my $ok = 1;
	$ok &= $dbc->Table_update_array('Run',['FK_Plate__ID','Run_Directory'],[$second_plate,$second_rundir . '_tmp'],"WHERE Run_ID=$first_run",-autoquote=>1,-debug=>0);
	$ok &= $dbc->Table_update_array('Run',['FK_Plate__ID','Run_Directory','Run_Comments'],[$first_plate,$first_rundir,$note2],"WHERE Run_ID=$second_run",-autoquote=>0,-debug=>0);
	$ok &= $dbc->Table_update_array('Run',['Run_Directory','Run_Comments'],[$second_rundir,$note1],"WHERE Run_ID=$first_run",-autoquote=>0,-debug=>0);
	$ok &= $dbc->Table_update_array('Run,Plate',['Plate_Created'],['Run_DateTime'],"WHERE Run_ID IN ($first_run,$second_run) AND FK_Plate__ID = Plate_ID",-autoquote=>0,-debug=>0);
	
	if (!$ok) {
	    Message("Error: Couldn't swap plate info on the runs");
	    exit;
	} else {
	    Message("Updated FK_Plate__ID and Run_Directory");
	}
	
	my $mapping = &alDente::Lane::_get_lane_well_mapping(-dbc=>$dbc,-run_ids=>"$first_run,$second_run",-fields=>['Run_ID','FK_GelRun__ID','Well','FK_Sample__ID','Lane_Number']);
	
	if (!$mapping) {
	    Message("Error: Error in Well Mapping");
	    return 0;
	}
	
	my $update = 0;
	foreach my $entry (@{$mapping}) {
	    $entry->[0] = $entry->[0] == $first_run ? $second_run :
		$entry->[0] == $second_run ? $first_run : '';
	    
	    $update += $dbc->Table_update_array('Lane',['FK_Sample__ID','Well'],[$entry->[3],$entry->[2]],"WHERE FK_GelRun__ID = $entry->[1] AND Lane_Number='$entry->[4]'",-autoquote=>1);
	}
	print "Updated $update records.\n";
	
	$dbc->finish_trans('fix_swap');

    }


    #re-draw images
    &Make_GelImages(-run_ids=>"$first_run,$second_run",-proceed=>$proceed);

    ##correct load format if the swap is different format
    if ($first_format ne $second_format) {
	print "1: set_load_format(-dbc=>$dbc,-to_format=>$first_format,-runlist=>$first_run)\n";
	print "2: set_load_format(-dbc=>$dbc,-to_format=>$second_format,-runlist=>$second_run)\n";
	&set_load_format(-dbc=>$dbc,-to_format=>$first_format,-runlist=>$first_run) if $proceed;
	&set_load_format(-dbc=>$dbc,-to_format=>$second_format,-runlist=>$second_run) if $proceed;
    }
}


sub Make_GelImages() {
    my %args = &filter_input(\@_);
    my $run_ids = $args{-run_ids};
    my $proceed = $args{-proceed};

    my %runs = $dbc->Table_retrieve(
        'RunBatch,Run,GelRun,Plate,Library,Project,
            Equipment       AS GelBoxEqu,
            Equipment       AS GelCombEqu,
            Employee        AS LoaderEmp, 
            Solution        AS AgarSol, 
            Stock           AS AgarStock,
            Stock_Catalog   AS AgarCatalog,
            Rack            AS GelRack',

        [   'Plate_ID', 'Run_ID', 'RunBatch_ID', 'Run_Directory', 'Library_Name', 'Project_Path',
            'GelBoxEqu.Equipment_Name AS GelBox',
            'GelCombEqu.Equipment_Name AS GelComb',
            'LoaderEmp.Initials AS Loader',
            'AgarCatalog.Stock_Catalog_Name AS AgarSol',
            'FKPosition_Rack__ID', "CONCAT(GelRack.FKParent_Rack__ID,':',GelRack.Rack_Name) AS RackPos"
        ],

        "WHERE Project.Project_ID=Library.FK_Project__ID AND
            Library.Library_Name=Plate.FK_Library__Name AND 
            Plate.Plate_ID=Run.FK_Plate__ID AND 
            RunBatch_ID=FK_RunBatch__ID AND 
            GelCombEqu.Equipment_ID=GelRun.FKComb_Equipment__ID AND 
            GelBoxEqu.Equipment_ID=GelRun.FKGelBox_Equipment__ID AND 
            LoaderEmp.Employee_ID=RunBatch.FK_Employee__ID AND
            GelRun.FKAgarose_Solution__ID = AgarSol.Solution_ID AND 
            AgarSol.FK_Stock__ID=AgarStock.Stock_ID AND 
            AgarStock.FK_Stock_Catalog__ID = AgarCatalog.Stock_Catalog_ID AND
            GelRun.FK_Run__ID=Run.Run_ID AND 
            Run.FKPosition_Rack__ID = GelRack.Rack_ID AND 
            Run_Status='Data Acquired' AND
            Run_ID IN ($run_ids)"
    );

    my $index = -1;
    while(defined $runs{Run_ID}[++$index]) {
        ### These files are valid, they need to
        #     - be moved to archived
        #     - updated their fluroimager equipment id
        #     - create a link in projects directory for this file
        #     - create thumbnails as required..
        #     - marked in the system to have it's analysis started

        my $run_id      = $runs{Run_ID}[$index];
        my $proj_path   = $runs{Project_Path}[$index];
        my $library     = $runs{Library_Name}[$index];
        my $run_dir     = $runs{Run_Directory}[$index];
        my $rack_id     = $runs{FKPosition_Rack__ID}[$index];
	my $project_dir = "$Configs{project_dir}";
	my $run_directory_full_path = "$project_dir/$proj_path/$library/AnalyzedData/$run_dir";

        &annotate_image(
            -input=>"$run_directory_full_path/image.tif",
            -output=>"$run_directory_full_path/annotated.jpg",
            -text=>"$runs{Run_Directory}[$index]\t$runs{GelBox}[$index]\t$runs{GelComb}[$index]\t" .
                     "$runs{Loader}[$index]\t$runs{AgarSol}[$index]\t$runs{RackPos}[$index]",
			-extra_args=> ' -level 50%,90% ',-proceed=>$proceed);
        &annotate_image(
            -input=>"$run_directory_full_path/image.tif",
            -output=>"$run_directory_full_path/thumb.jpg",
			-extra_args=>" -resize 120x120 -level 30%,95%",-proceed=>$proceed);
    }
}


######################
#
# Creates a thumbnail of a 
#
#####################
sub annotate_image {
#####################
    my %args = &filter_input(\@_,-args=>'input,output,text');
    
    my $input   = $args{-input};
    my $output  = $args{-output};
    my $text    = $args{-text};
    my $rotate  = $args{-rotate} || 90;
    my $extra_args = $args{-extra_args} || '';
    my $proceed = $args{-proceed};

    if($rotate) {
        $extra_args .= " -rotate $rotate ";
    }

    if($text) {
        my $pointsize = 32;
        $extra_args .= " -fill black -draw \"text 10,50 '$text'\" -pointsize $pointsize";
    }

    my $command = "/usr/bin/convert $input $extra_args $output 2>/dev/null"; ## Stupid convert always gives error 'MissingRequired.'
    print "$command\n"; 
    try_system_command($command) if $proceed;
}




#############
sub help {
#############

    print <<HELP;

Synopsis:
*********
    This script is used to fix user errors made during gel loading.

Description:
***********
    This script is used to fix user errors made during gel loading. Some of the typical known errors spotted so far are:
            - Wrong plate scanned for a gel
            - Wrong Load format selected during the load (ie. hamilton vs. ferro)
                Available options for the 'to_format' are: ferro, hamilton

Usage:
*********
    
    To fix plate swaps:
    ./fix_gel_errors.pl -db sequence -host lims02 -user user -password passwd -first_run 40000 -second_run 40001

    To set the load format of a set of runs to "ferro":
    ./fix_gel_errors.pl -db sequence -host lims02 -user user -assword passwd -runlist 80505,80506,80511,80512,80529,80530 -to_format ferro

    
    
HELP

}
