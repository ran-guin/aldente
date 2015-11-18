#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

check_run_links.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
#superclasses
#system_variables
#standard_modules_ref
#This program checks for the presence of trace files for each sequence run Requested.
Output:
    Files:  (placed into logs/ directory)
    broken_links - broken links (due to compression of original files ?)
    missing_traces - no .../chromat_dir files exist.
    badly_broken_links - broken links which are NOT simply compressed
    non_link_files - trace files which are NOT links to the mirror directory.
    bad_archive_links - links in the archive directory with a suffix (e.g. .27) that does not correspond to the actual number of trace files.
    use strict;

=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
################################################################################
#
# check_run_links.pl
#
# This program checks for the presence of trace files for each sequence run
# requested.
#
# Output:
#
# Files:  (placed into logs/ directory)
#
# broken_links - broken links (due to compression of original files ?)
# missing_traces - no .../chromat_dir files exist.
# badly_broken_links - broken links which are NOT simply compressed
# non_link_files - trace files which are NOT links to the mirror directory.
# bad_archive_links - links in the archive directory with a suffix (e.g. .27) that does not correspond to the actual number of trace files.
#
################################################################################
################################################################################
# $Id: check_run_links.pl,v 1.8 2003/11/27 19:37:34 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.8 $
#     CVS Date: $Date: 2003/11/27 19:37:34 $
################################################################################
#use strict;
use CGI ':standard';
use DBI;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::DBIO;
use SDB::CustomSettings;
use RGTools::Views;
use RGTools::RGIO;
use alDente::SDB_Defaults;    ### get directories only...
use strict;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_f $opt_r $opt_L $opt_l $opt_c $opt_m $opt_s $opt_F);
use vars qw($testing $project_dir @machines $temp_suffix $URL_dir $URL_temp_dir $bin_home);
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
&Getopts('fsL:lc:lm:F');
my $dbase = 'sequence';
my $log   = "$Data_log_directory";
@machines = ( 2, 3, 4, 5, 6, 69, 70, 114, 115, 246, 247 );
my %Missing_Lib;
my %Broken_Lib;
my %Bad_Break;
my %Non_Link;
my %Partial_Link;
my %Link_96;
my %Link_384;
my %Machine;
my $find      = $opt_f || 0;
my $summarize = $opt_s || 0;
my $time_stamp = &date_time;
$time_stamp =~ s/\s/_/g;
$time_stamp =~ s/:/-/g;
my $fix = $opt_F || 0;

unless ( $find || $summarize ) {
    print "please choose One of the options:\n\n"
        . "-f find links (long process)\n"
        . "-s summarize results (generally should be run with find)\n"
        . "\nOptions\n**********\n"
        . "-l list files to extract from\n"
        . "-L (library) run check on specific library\n"
        . "-m (machine_id) run check on specific sequencer\n";
    exit;
}
unless ($opt_L) {

    #try_system_command("rm -f $log/run_status/*");
    #Remove all files except files starting with 'bad_arc_link'
    try_system_command("find $log/run_status/ -type f \\! -name 'bad_arc_link*' -maxdepth 1 -exec rm -f {} \\;");
}
my $dbc = SDB::DBIO->new( -dbase => $dbase, -user => 'viewer', -password => 'viewer', -connect => 0 );
if ($find) {
    print "Finding run links..." . &date_time() . "\n";
    if ($opt_m) { @machines = split ',', $opt_m; }
    foreach my $machine (@machines) {
### set up filenames for storing information.. ###
        my $missing_file      = "not_found";
        my $broken_file       = "broken";
        my $badly_broken_file = "badly_broken";
        my $partial_file      = "partial";
        my $non_link_file     = "non_link";
        my $bad_arc_link_file = "bad_arc_link-" . date_time();
        $bad_arc_link_file =~ s/ /_/g;    #subsitiute underscore with space
        my $missing_list          = "missing_id_list";
        my $broken_list           = "broken_id_list";
        my $badly_broken_list     = "badly_broken_id_list";
        my $missing_libs          = "missing_dirs";
        my $missing_library_names = "missing_library_names";
        my $check_lib;
        my $lib_condition;
        my $list_condition;
        my $machine_condition;

        if ($opt_L) {
            $check_lib     = $opt_L;
            $lib_condition = "AND Library_Name like '$check_lib%'";    ### if library specified, include in SQL condition...
            $missing_file          .= ".$check_lib";
            $broken_file           .= ".$check_lib";
            $partial_file          .= ".$check_lib";
            $non_link_file         .= ".$check_lib";
            $bad_arc_link_file     .= ".$check_lib";
            $missing_list          .= ".$check_lib";
            $broken_list           .= ".$check_lib";
            $badly_broken_list     .= ".$check_lib";
            $missing_libs          .= ".$check_lib";
            $missing_library_names .= ".$check_lib";
            $badly_broken_file     .= ".$check_lib";
        }
        my $regenerate;
        my $find;
        if    ($opt_f) { $find       = 1; }
        elsif ($opt_r) { $regenerate = 1; }
        else           { $find       = 1; $regenerate = 1; }
        my $continuing_from;    ## allow specification of library to continue from
        if ($opt_c) {
            $continuing_from = $opt_c;
            print "Continuing from Library: $continuing_from...\n";
        }
        if ($opt_l) {
            my $list_file = $opt_l;
            my @list;
            open( LIST, "$list_file" ) or die "cannot open $list_file";
            while (<LIST>) {
                my $id = $_;
                if ( $id =~ /(\d+)/ ) {
                    $id = $1;
                    push( @list, $id );
                }
            }
            close(LIST);
            $list_condition = "AND Run_ID in (" . join ',', @list . ")";
        }
        if ($machine) {
            $machine_condition = "AND FK_Equipment__ID in ($machine)";
            $missing_file          .= ".Equ$machine";
            $broken_file           .= ".Equ$machine";
            $partial_file          .= ".Equ$machine";
            $non_link_file         .= ".Equ$machine";
            $bad_arc_link_file     .= ".Equ$machine";
            $missing_list          .= ".Equ$machine";
            $broken_list           .= ".Equ$machine";
            $badly_broken_list     .= ".Equ$machine";
            $missing_libs          .= ".Equ$machine";
            $missing_library_names .= ".Equ$machine";
            $badly_broken_file     .= ".Equ$machine";
        }
        $dbc->connect();
        my @libs = $dbc->Table_find_array(
            'Run,RunBatch,Library,Project,Plate',
            [ 'Project_Path', 'Library_Name as Lib', 'Run_ID', 'Run_Directory', 'FK_Equipment__ID' ],
            "WHERE FK_RunBatch__ID=RunBatch_ID AND Library_Name=Plate.FK_Library__Name and Plate.Plate_ID = Run.FK_Plate__ID AND FK_Project__ID = Project_ID AND Run_Status like 'Analyzed' $lib_condition $list_condition $machine_condition ORDER BY Run_Directory"
        );

        #Get the archive dir location of the current machine.
        my ($local_dir) = $dbc->Table_find( 'Machine_Default', 'Local_Data_dir', "where FK_Equipment__ID = $machine" );
        $dbc->dbh()->disconnect();
        ### erase current files ###
        unlink("$log/run_status/$missing_file");
        unlink("$log/run_status/$broken_file");
        unlink("$log/run_status/$badly_broken_file");
        unlink("$log/run_status/$partial_file");
        unlink("$log/run_status/missing_dirs");
        unlink("$log/run_status/broken_dirs");
        unlink("$log/run_status/badly_broken_dirs");
        print "generate $log/run_status/ files.." . &date_time() . "\n";

        foreach my $lib (@libs) {
            my ( $project, $library, $run_id, $subdir, $equip_id ) = split ',', $lib;
            if ($continuing_from) {
                unless ( $library eq $continuing_from ) { next; }
                $continuing_from = 0;    ### continue...
            }    ## re-start from specified library...
            unless ($subdir) { print "Failed to find subdir for $lib... ?\n"; next; }    ## MUST have subdirectory name..
            print "$lib\n";
            unless ( -e "$log/run_status/checking.$library.$machine" ) {
                `touch $log/run_status/checking.$library.$machine`;
            }
            my $lib_path = "$project/$library/AnalyzedData/$subdir";
            my $command  = "find $project_dir/$lib_path/chromat_dir/ -xtype l";          ## find broken links in path
            my $broken   = &try_system_command($command);
            my $command2 = "find $project_dir/$lib_path/chromat_dir/ -type l | wc";      ## count unbroken links in path
            my $links    = &try_system_command($command2);
            my $found;
            if ( $links =~ /\s*(\d+)/ ) { $found = $1; }

            if ( $broken =~ /No such file/ || !$found ) {                                ## if no links found (broken or unbroken)...
                my $command3 = "find $project_dir/$lib_path/chromat_dir/ -type f | wc";
                my $files    = &try_system_command($command3);
                my $found;
                if ( $files =~ /\s*(\d+)/ ) { $found = $1; }
                if ($found) {
                    print "** $project_dir/$lib_path/chromat_dir/ ** $found FILES found (Run $run_id - Equ $equip_id) **\n";
                    `echo \"$project_dir/$lib_path  (Run $run_id - Equ $equip_id)\" >> $log/run_status/$non_link_file`;
### add to list of (non_linked) files..
                    if   ( %Non_Link->{$library} ) { %Non_Link->{$library}++; }
                    else                           { %Non_Link->{$library} = 1; }
                    print "Non-Link # " . %Non_Link->{$library} . "\n";
                }
                else {
                    print "** $project_dir/$lib_path/chromat_dir/ ** NOT FOUND (Run $run_id - Equ $equip_id) **\n";
                    `echo '$project_dir/$lib_path (Run $run_id - Equ $equip_id)' >> $log/run_status/$missing_file`;    ### add to list of missing files..
                    if   ( %Missing_Lib->{$library} ) { %Missing_Lib->{$library}++; }
                    else                              { %Missing_Lib->{$library} = 1; }
                    print "Missing Link # " . %Missing_Lib->{$library} . "\n";
                }
            }
            elsif ($broken) {                                                                                          ## if broken links found
                my $command = "$bin_home/decompress.pl -c -L $subdir";                                                 ### CHECK compressed files for this subdirectory
                my $found   = &try_system_command("$command | grep found:");
                my $count;
                while ( $found =~ s /Run\S+\s+(found:|)\s*(\d+)\s+\d+\s+\d+/(retrieved)/ ) {
                    my $num = $2;
                    if ($num) { $count .= " + $2"; }                                                                   ## concatenate numbers of files found (sometimes 96 + 96 + 96 + 96) ##
                }
                if ($count) {
                    print "** $project_dir/$lib_path ** BROKEN LINK ($count found) **\n";
                    `echo '$project_dir/$lib_path ($count found) (Run $run_id - Equ $equip_id)' >> $log/run_status/$broken_file`;
                    if   ( %Broken_Lib->{$library} ) { %Broken_Lib->{$library}++; }
                    else                             { %Broken_Lib->{$library} = 1; }
                    print "Compressed Link # " . %Broken_Lib->{$library} . "\n";
                }
                else {
                    print "Found: $found\n";
                    print "try: $command\n** $project_dir/$lib_path ** BAD BREAK (Run $run_id - Equ $equip_id) **\n";
                    `echo '$project_dir/$lib_path (Run $run_id - Equ $equip_id)' >> $log/run_status/$badly_broken_file`;    ### decompression check failed.
                    if ( %Bad_Break->{$library} ) {
                        %Bad_Break->{$library}++;
                    }
                    else {
                        %Bad_Break->{$library} = 1;
                    }
                    print "Bad Break # " . %Bad_Break->{$library} . "\n";
                }
            }
            elsif ( $found == 96 ) {
                if   ( %Link_96->{$library} ) { %Link_96->{$library}++; }
                else                          { %Link_96->{$library} = 1; }
                print "Link_96 # " . %Link_96->{$library} . "\n";
            }
            elsif ( $found == 384 ) {
                if   ( %Link_384->{$library} ) { %Link_384->{$library}++; }
                else                           { %Link_384->{$library} = 1; }
                print "Link_384 # " . %Link_384->{$library} . "\n";
            }
            else {
                `echo '** Only $found files for $lib_path. **' >> $log/run_status/$partial_file`;
                print "** Only $found files for $lib_path. **\n";
                if   ( %Partial_Link->{$library} ) { %Partial_Link->{$library}++; }
                else                               { %Partial_Link->{$library} = 1; }
                print "Partial Link # " . %Partial_Link->{$library} . "\n";
            }
            ################################################################
            ###fix broken link.
            if ($fix) {
                my $broken_links = &try_system_command("find $project_dir/$lib_path/chromat_dir/ -xtype l");
                foreach my $link ( split /\n/, $broken_links ) {
                    `echo '\n-----------------------------------------------------------------------------------' >> $log/run_status/$bad_arc_link_file`;
                    `echo 'Broken links found for Proj $project - Lib $library - Run $run_id - Equ $equip_id:' >> $log/run_status/$bad_arc_link_file`;
                    `echo '-----------------------------------------------------------------------------------' >> $log/run_status/$bad_arc_link_file`;
                    my $linked_file      = readlink "$link";
                    my $good_linked_file = $linked_file;
                    $good_linked_file =~ s/(.rid\d+).\d+/$1.96/;

                    #$linked_file =~ /(\S+)\.\d+(\/\S+)/;
                    #my $good_linked_file = "$1" . ".96" . "$2";
                    #try to find if the corresponding link exist in archive folder with the correct number...
                    my $found = try_system_command("ls $good_linked_file");
                    if ( $found =~ /No such file/ ) {
                        `echo '>>>$link: $good_linked_file not found. Target not changed.' >> $log/run_status/$bad_arc_link_file`;
                    }
                    else {
                        my $feedback = try_system_command("ln -sf $good_linked_file $link");
                        if ($feedback) {    #Error occured
                            `echo '***$link: Error changing target from $linked_file to $good_linked_file' >> $log/run_status/$bad_arc_link_file`;
                        }
                        else {
                            `echo '>>>$link: Changed target from $linked_file to $good_linked_file' >> $log/run_status/$bad_arc_link_file`;
                        }
                    }
                }
            }

            #Look for potential bad links in the archive folder.
            my %susp_arc_links = _search_bad_links( "$archive_dir/$local_dir", $subdir );
            if (%susp_arc_links) {
                `echo '\n-----------------------------------------------------------------------------------' >> $log/run_status/$bad_arc_link_file`;
                `echo 'Suspicious links found for Proj $project - Lib $library - Run $run_id - Equ $equip_id:' >> $log/run_status/$bad_arc_link_file`;
                `echo '-----------------------------------------------------------------------------------' >> $log/run_status/$bad_arc_link_file`;
            }

            #First check each suspicous link to see if it really reflects the number of trace files.
            my %bad_arc_links;
            foreach my $susp_arc_link ( sort keys %susp_arc_links ) {
                my $num_files = try_system_command("ls $susp_arc_link/*.ab? | wc -l") - 0;
                if ( $susp_arc_link =~ /.$num_files$/ ) {
                    `echo '$susp_arc_link -> OK ($num_files trace files found)' >> $log/run_status/$bad_arc_link_file`;
                }
                else {
                    `echo '$susp_arc_link -> Bad link ($num_files trace files found)' >> $log/run_status/$bad_arc_link_file`;

                    #Add this link to the bad links hash.
                    $bad_arc_links{$susp_arc_link} = $num_files;    #Store the correct number of trace files into the hash for later processing.
                }
            }
            if (%bad_arc_links) {
                `echo '\n-----------------------------------------------------------------------------------' >> $log/run_status/$bad_arc_link_file`;
                `echo 'Bad links found for Proj $project - Lib $library - Run $run_id - Equ $equip_id:' >> $log/run_status/$bad_arc_link_file`;
                `echo '-----------------------------------------------------------------------------------' >> $log/run_status/$bad_arc_link_file`;
                foreach my $bad_arc_link ( sort keys %bad_arc_links ) {
                    if ($fix) {
                        my $num_files  = $bad_arc_links{$bad_arc_link};
                        my $fixed_link = $bad_arc_link;
                        $fixed_link =~ s/.\d+$/.$num_files/;
                        my $ok = rename $bad_arc_link, $fixed_link;

                        #Now need to see if there are links in the Project subfolders linking(referencing) to the bad link and if so need to change that as well.
                        if ($ok) {
                            `echo '>>>Changed $bad_arc_link to $fixed_link' >> $log/run_status/$bad_arc_link_file`;
                            my $ref_links = try_system_command("ls $project_dir/$lib_path/chromat_dir/");
                            if ($ref_links) {    #If found any references then need to fix them.
                                foreach my $ref_link ( split /\n/, $ref_links ) {
                                    my $linked_file = readlink "$project_dir/$lib_path/chromat_dir/$ref_link";
                                    if ( $linked_file =~ /$bad_arc_link(\S+)/ ) {
                                        my $feedback = try_system_command("ln -sf $fixed_link$1 $project_dir/$lib_path/chromat_dir/$ref_link");
                                        if ($feedback) {    #Error occured
                                            $ok = 0;
                                            `echo '***$project_dir/$lib_path/chromat_dir/$ref_link: Error changing target from $ref_link$1 to $fixed_link$1' >> $log/run_status/$bad_arc_link_file`;
                                        }
                                        else {
                                            `echo '>>>$project_dir/$lib_path/chromat_dir/$ref_link: Changed target from $ref_link$1 to $fixed_link$1' >> $log/run_status/$bad_arc_link_file`;
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            `echo '***Error changing $bad_arc_link to $fixed_link' >> $log/run_status/$bad_arc_link_file`;
                        }
                    }
                    else {
                        `echo '$bad_arc_link' >> $log/run_status/$bad_arc_link_file`;
                    }
                }
            }
            ##################################################################
        }
    }
    foreach my $lib ( keys %Missing_Lib ) {
        my $count = %Missing_Lib->{$lib};
        `echo '$lib $count missing files' >>  $log/run_status/missing_dirs`;
    }
    foreach my $lib ( keys %Bad_Break ) {
        my $count = %Bad_Break->{$lib};
        print "Bad Breaks for $lib: $count files";
        `echo '$lib $count badly_broken files' >>  $log/run_status/badly_broken_dirs`;
    }
    foreach my $lib ( keys %Broken_Lib ) {
        my $count = %Broken_Lib->{$lib};
        `echo '$lib $count compressed links' >>  $log/run_status/broken_dirs`;
    }
    foreach my $lib ( keys %Non_Link ) {
        my $count = %Non_Link->{$lib};
        `echo '$lib $count non-link files' >>  $log/run_status/non_link_dirs`;
    }
    foreach my $lib ( keys %Partial_Link ) {
        my $count = %Partial_Link->{$lib};
        `echo '$lib $count partially linked files' >>  $log/run_status/partial_link_dirs`;
    }
    foreach my $lib ( keys %Link_96 ) {
        my $count = %Link_96->{$lib};
        `echo '$lib $count files with 96 links' >>  $log/run_status/link_96_dirs`;
    }
    foreach my $lib ( keys %Link_384 ) {
        my $count = %Link_384->{$lib};
        `echo '$lib $count files with 384 links' >>  $log/run_status/link_384_dirs`;
    }
    if ($opt_L) { exit; }    ## do not continue if only looking at one library...
    try_system_command("cat $log/run_status/not_found.* > $log/run_status/not_found");
    try_system_command("cat $log/run_status/badly_broken.* > $log/run_status/badly_broken");
    my @regenerate_list;
    my @files_to_check = ( 'not_found', 'badly_broken' );
    $dbc->connect();
    foreach my $type (@files_to_check) {
        my $file = $type;
        my $list = $type . "_id_list";
        unlink("$log/run_status/$list");
        print "Checking $log/run_status/$file...\n";
        if ( -e "$log/run_status/$file" ) {
            open( UNFOUND, "$log/run_status/$file" ) or die "cannot find $log/run_status/$file";
            my @ids;
            while (<UNFOUND>) {
                my $dir = $_;
                chomp $dir;
                if ( $dir =~ /.*\/(\S+)/ ) {
                    my $subdir = $1;
                    my ($id) = $dbc->Table_find( 'Run', 'Run_ID', "where Run_Directory = '$subdir'" );
                    push( @ids, $id );
                    print "$id : $subdir -> $dir\n";
                    `echo $id >> $log/run_status/$list`;
                }
                else { print "$dir ??\n"; }
            }
            close(UNFOUND);
        }
        else { print "No $log/run_status/$file file found...\n"; }
    }
    $dbc->dbh()->disconnect();
}
if ($summarize) {
    print "Summarizing link results..." . &date_time() . "\n";
    my $dbc->connect();
    my @projects   = $dbc->Table_find( 'Project',   'Project_Name' );
    my @sequencers = $dbc->Table_find( 'Equipment', 'Equipment_ID,Equipment_Name' );
    foreach my $equip_info (@sequencers) {
        my ( $id, $name ) = split ',', $equip_info;
        %Machine->{$id} = $name;
    }
    my $html = 1;
    if ($html) {
        my $html_file = "$Web_home_dir/dynamic/check_run_links.html";    ###temporary - need to think of a better location in production.
        open( HTML, ">$html_file" ) or die "cannot open $html_file";

        #	print HTML "Content-type: text/html\n\n";
        print HTML $html_header;                                         ### imported from Default File (SDB_Defaults.pm)
        print HTML "\n<!------------ JavaScript ------------->\n";
        print HTML $java_header;                                         ### imported from Default File (SDB_Defaults.pm)
        print HTML "\n<!------------ Program ------------->\n";
        print HTML &RGTools::Views::Heading("File monitoring of Sequence Run Data");
        print HTML "<span class=small><B>Last Updated: " . &date_time() . "</B></span>" . hr();
        print HTML "<B>Current Projects:</B><UL>\n";

        foreach my $project (@projects) {
            print HTML "<LI><A Href=#$project>$project</A>\n";
        }
        print HTML "</UL>\n" . &vspace(10);
    }
    my @lib_info = $dbc->Table_find(
        'Project,Library,Run,Plate',
        'Project_Name,Library_Name,Run_Status,count(*)',
        "where Plate_ID = Run.FK_Plate__ID and Plate.FK_Library__Name = Library_Name and FK_Project__ID=Project_ID group by Run_Status,Library_Name Order by Project_Name,Library_Name,Run_Status"
    );
    $dbc->dbh()->disconnect();
    unless ($find) {    ### if find was run separately, get info from files...
        print "Look for: $log/run_status/*_dirs...\n";
        my @check_files = glob("$log/run_status/*_dirs");
        foreach my $check (@check_files) {
            print "extracting info from $check..\n";
            my %Found;
            open( CHECK, "$check" ) || do { print "could not open $check..\n"; next; };
            while (<CHECK>) {
                my $found = $_;
                if ( $found =~ /(\S+)\s*(\d+)/ ) {
                    %Found->{$1} = $2;
                }
            }
            close(CHECK);
            if    ( $check =~ /badly_broken/ ) { %Bad_Break    = %Found; }
            elsif ( $check =~ /broken/ )       { %Broken_Lib   = %Found; }
            elsif ( $check =~ /non_link/ )     { %Non_Link     = %Found; }
            elsif ( $check =~ /missing/ )      { %Missing_Lib  = %Found; }
            elsif ( $check =~ /partial/ )      { %Partial_Link = %Found; }
            elsif ( $check =~ /link_96/ )      { %Link_96      = %Found; }
            elsif ( $check =~ /link_384/ )     { %Link_384     = %Found; }
            else                               { print "$check not in standard format ..?\n"; }
        }
    }
    my $lastproject;
    my $lastlibrary;
    foreach my $info (@lib_info) {
        my ( $project, $library, $run_state, $count ) = split ',', $info;
        unless ( $project eq $lastproject ) {
            print hr() . "Project: $project\n***************************\n";
            $lastproject = $project;
            print HTML "<A Name=$project>" . hr();
            print HTML &RGTools::Views::sub_Heading("Project: $project");
        }
        unless ( $library eq $lastlibrary ) {
            print "\nLibrary: $library\n***************************\n";
            $lastlibrary = $library;
            print HTML "<A Name=$library>" . &RGTools::Views::sub_Heading( "<B>$library</B>", 1, 'class=lightbluebw' );
            print_to_HTML( "(Library Info)\n", 'link', "&Info=1&Table=Library&Field=Library_Name&Like=$library" );
        }
        print_to_HTML( "$library: $count $run_state Runs\n", 'link', "&Last+24+Hours=1&Use+Library=$library&Any+Date=1" );
        if ( $run_state eq 'Analyzed' ) {
            print HTML "<INDENT>";
            if ( %Broken_Lib->{$library} ) { print_to_HTML( "$library *** Compressed: " . %Broken_Lib->{$library} . "\n" ); }
            if ( %Non_Link->{$library} )   { print_to_HTML( "$library * Non-linked: " . %Non_Link->{$library} . "\n" ); }
            if ( %Link_96->{$library} )    { print_to_HTML( "$library * Linked 96: " . %Link_96->{$library} . "\n" ); }
            if ( %Link_384->{$library} )   { print_to_HTML( "$library * Linked 384: " . %Link_384->{$library} . "\n" ); }
            ### include a bit more info for those missing or badly broken...
            if ( %Partial_Link->{$library} ) {
                print_to_HTML( "$library * Linked some: " . %Partial_Link->{$library}, 'warning' );
                print_to_HTML( &show_machines( $library, 'partial' ) );
            }
            if ( %Missing_Lib->{$library} ) {
                print_to_HTML( "$library *** Missing: " . %Missing_Lib->{$library}, 'error' );
                print_to_HTML( &show_machines( $library, 'not_found' ) );
            }
            if ( %Bad_Break->{$library} ) {
                print_to_HTML( "$library *** Broken: " . %Bad_Break->{$library}, 'error' );
                print_to_HTML( &show_machines( $library, 'badly_broken' ) );
            }
            my $found = %Missing_Lib->{$library} + %Bad_Break->{$library} + %Non_Link->{$library} + %Broken_Lib->{$library} + %Partial_Link->{$library} + %Link_96->{$library} + %Link_384->{$library};
            if ( $count < $found ) { &print_to_HTML( "$library *** $found detected, but only $count analyzed ?!\n\n", 'error' ); }
            elsif ( $count > $found ) { print_to_HTML( "$library *** only $found detected of $count\n\n", 'error' ); }
            else                      { print_to_HTML("($library Count matches analyzed runs found)\n\n"); }
            print HTML "</INDENT>";
        }
    }
    close(HTML);

    #   &leave();
}
try_system_command("rm -f $log/run_status/checking.*");
print "\nDone " . &date_time() . "\n****************************************\n";
exit;

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

######################
sub show_machines {
######################
    my $lib          = shift;
    my $file_pattern = shift;

    $temp_suffix ||= 0;

    #    $temp_suffix++;

    my @found;
    foreach my $equip_id (@machines) {
        $temp_suffix++;
        unless ( -e "$log/run_status/$file_pattern.Equ$equip_id" ) { next; }
        my $temp_link = "$URL_temp_dir/run_links.$lib.$time_stamp.$temp_suffix";

        my $command = "grep $lib $log/run_status/$file_pattern.Equ$equip_id";
        my $count   = try_system_command("$command | wc");

        if ( $count =~ /No such file/i ) { print "no such file\n"; next; }
        if ( $count =~ /(\d+)/ ) { $count = $1; }
        if ($count) {
            try_system_command("$command > $temp_link");
            my $equip = %Machine->{$equip_id};
            push( @found, &Link_To( "$URL_domain/SDB/Temp/run_links.$lib.$time_stamp.$temp_suffix", "($equip : $count)", undef, $Settings{LINK_COLOUR}, ['newwin'] ) );
        }
    }

    my $list = join ',', @found;
    return " $list\n";
}

######################
sub print_to_HTML {
######################
    my $message = shift;
    my $status  = shift;
    my $link    = shift;

    my $homelink = "http://seq.bcgsc.bc.ca/cgi-bin/SDB/barcode.pl?User=Auto";

    print $message;
    $message =~ s/\n/<BR>/g;

    if ( $status =~ /error/ ) {
        print HTML "<Font color=red><B>$message</B></Font>";
    }
    elsif ( $status =~ /warning/ ) {
        print HTML "<B>$message</B>";
    }
    elsif ( $status =~ /highlight/ ) {
        print HTML "<B>$message</B>";
    }
    elsif ( $status =~ /link/ ) {
        print HTML &Link_To( $homelink, $message, $link, $Settings{LINK_COLOUR}, ['newwin'] );
    }
    else { print HTML "$message"; }
    return;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

##########################
sub _search_bad_links {
##########################
    my $dir    = shift;
    my $subdir = shift;

    my %bad_links;

    my $links = try_system_command("find $dir -type l -name '$subdir*' \\! -name '*.96' \\! -name '*.384' \\! -name 'Run*'");
    foreach my $link ( split /\n/, $links ) {
        $link =~ /$dir\/\d\/data\d\/(Data|AnalyzedData)\/(\S+).rid\d+.\d+$/;
        $bad_links{$link} = $2;
    }

    return %bad_links;
}

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: check_run_links.pl,v 1.8 2003/11/27 19:37:34 achan Exp $ (Release: $Name:  $)

=cut

