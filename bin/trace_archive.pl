#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

trace_archive.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>This program checks for the presence of trace files for each sequence run <BR>requested.<BR>Output:<BR>Files:  (placed into logs/ directory)<BR>broken_links - broken links (due to compression of original files ?)<BR>missing_traces - no .../chromat_dir files exist.<BR>badly_broken_links - broken links which are NOT simply compressed<BR>non_link_files - trace files which are NOT links to the mirror directory.<BR>bad_archive_links - links in the archive directory with a suffix (e.g. .27) that does not correspond to the actual number of trace files.<BR>use strict;<BR>

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
# trace_archive.pl
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
# $Id: trace_archive.pl,v 1.6 2004/06/03 18:11:41 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.6 $
#     CVS Date: $Date: 2004/06/03 18:11:41 $
################################################################################
#use strict;
use CGI qw(:standard);
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
use vars qw($testing);
use vars qw($testing $project_dir @machines $temp_suffix $URL_dir $URL_temp_dir $bin_home $mirror_dir $archive_dir);
use vars qw($opt_C $opt_L $opt_R $opt_M $opt_x $opt_N $opt_u $opt_v);
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
&Getopts('C:L:R:M:xN:uv');
my $dbase           = 'sequence';
my $log             = "$Data_log_directory";
my $today           = date_time();
my $dbc             = DB_Connect( dbase => 'sequence', user => 'labuser', password => 'manybases', host => 'lims02' );
my $mirror          = $mirror_dir;
my $archive         = $archive_dir;
my $project         = $project_dir;
my $extra_condition = '';
my $Econdition      = '';
my $verbose;
if ($opt_v) { $verbose = 1 }

if ($opt_C) {
    $extra_condition = "AND $opt_C ";
}
if ($opt_L) {
    $extra_condition .= "AND Run_Directory like '$opt_L%' ";
}
if ($opt_N) {    ### new runs...
    my @newruns = &Table_find( $dbc, 'Run left join TraceData on Run_ID = FK_Run__ID', 'Run_ID', "where Run_Status = 'Analyzed' AND FK_Run__ID IS NULL" );
    my $runs = join ',', @newruns;
    $extra_condition .= "AND Run_ID in ($runs) ";
}
if ($opt_R) {
    my $runs = extract_range($opt_R);
    $extra_condition .= "AND Run_ID in ($runs) ";
}
if ($opt_M) {
    my $machine = $opt_M;
    $machine =~ s /,/','/g;    ## quote values in list if applicable
    $Econdition = "AND (Equipment_ID in ('$machine') OR Equipment_Name in ('$machine'))";
}
if ($verbose) { print "Extra Condition : $extra_condition\n" }
my $extract = 0;               ### extract tarzipped files...
if ($opt_x) {
    $extract = 1;
}
my @decompressed = ();
my @machines = &Table_find( $dbc, 'Equipment,Machine,Sequencer_Type', 'Equipment_Name,Equipment_ID', "where FK_Equipment__ID = Equipment_ID and FK_Sequencer_Type__ID = Sequencer_Type_ID $Econdition" );
if ($extract) { push( @machines, @machines ) }    ### run again after extraction to update...
print "Checking @machines..\n";
my $Edir;
foreach my $machine (@machines) {
    my $stamp = date_time();
    my ( $Ename, $Eid ) = split ',', $machine;
    my $subdir;
    if ( $Ename =~ /37(\d+)-(\d+)/ ) {
        $Edir   = "37$1/$2";
        $subdir = "data1/Data";
    }
    elsif ( $Ename =~ /MB(\d+)/i ) {
        $Edir   = "mbace/$1";
        $subdir = "data2/AnalyzedData";
    }
    print "check $mirror/$Edir ($stamp)\n*************************\n";
    $testing = 1;
    my @runs = &Table_find(
        $dbc,
        'Run,RunBatch,Plate,Plate_Format',
        'Run_ID,Run_Directory,Plate_Size,Plate_Format_Size',
        "where FK_Plate_Format__ID=Plate_Format_ID AND FK_Plate__ID=Plate_ID AND FK_RunBatch__ID=RunBatch_ID AND FK_Equipment__ID = $Eid AND Run_Status = 'Analyzed' $extra_condition"
    );
    $testing = 0;
    my $checked   = 0;
    my @Mcontents = glob("$mirror/$Edir/$subdir/*");
    my @Acontents = glob("$archive/$Edir/$subdir/*");
    my $Mfiles    = int(@Mcontents);
    my $Acontents = int(@Acontents);
    print "Mirrored: " . int(@Mcontents) . "\n";
    print "Archived: " . int(@Acontents) . "\n";
    print "Runs: " . int(@runs) . "\n";

    foreach my $run (@runs) {
        ### Get Run ID and Name (get Master ID/Name if applicable) ###
        my ( $Rid, $Rname, $Psize, $Pformat ) = split ',', $run;
        my ($master) = &Table_find( $dbc, 'MultiPlate_Run,Run', 'FKMaster_Run__ID,Run_Directory', "where FKMaster_Run__ID=Run_ID AND FK_Run__ID = $Rid" );
        my ( $Mid, $Mname ) = split ',', $master;
        print "** Run $Rid : $Rname ($Psize/$Pformat)";
        my $format;
        if ( $master =~ /(\d+),(.*)/ ) {
            $Mid   = $1;
            $Mname = $2;
            print "\tMaster = ($Mid : $Mname)";
            $format = "$Psize x 4";
        }
        else { $Mid = $Rid; $Mname = $Rname; $format = "$Psize/$Pformat"; print "($Mname) "; }
        #### check Projects directory for links/files/broken links .. ####
        my ($path) = &Table_find_array( $dbc, 'Project,Library', [ 'Project_Path', 'Library_Name' ], "where FK_Project__ID = Project_ID and Library_Name = Left('$Rname',5)" );
        $path =~ s/,/\//;
        if ( !$extract && $opt_u && $opt_L ) {
            my $moved = `/opt/alDente/versions/rguin/bin/update_sequence.pl -A get -S $Rid`;
            print "** \n $moved \n**\n";
        }
        my ( @links, @files, @broken );
        my $chromat_dir = "$project/$path/AnalyzedData/$Rname/chromat_dir";
        my $path_found  = '';
        if ( -e "$project/$path/AnalyzedData/$Rname/chromat_dir" ) {
            $path_found = 'OK';
            @links      = `find $chromat_dir -type l -maxdepth 1`;
            @files      = `find $chromat_dir -type f -maxdepth 1`;
            @broken     = `find $chromat_dir -xtype l -maxdepth 1`;
            if ( ( int(@links) >= 96 ) && ( int(@links) == ( int(@broken) + 96 ) ) ) {
                print "\n** Delete " . int(@broken) . " broken redundant links **:\n";
                foreach my $broke (@broken) {
                    `rm -f $broke`;
                    if ($verbose) { print "-- deleted: $broke\n" }
                }
                print "\n*****************\n";
                @broken = `find $chromat_dir -xtype l -maxdepth 1`;
                @links  = `find $chromat_dir -type l -maxdepth 1`;
            }
        }
        else { $path_found = 'Not Found'; print ' ** no path **'; }
        #### check archive & mirror directories ... ####
        my @mirrored = grep /$Mname\.(\D)/,                        @Mcontents;
        my @archived = grep /$Mname\.(\D)/,                        @Acontents;
        my @zipped   = grep /$Mname(Run|_Run)(.*)(.tar.gz|.tgz)$/, @Mcontents;
        if ($extract) {
            foreach my $zipped (@zipped) {
                if ( grep /^$Rname$/, @decompressed ) {
                    print "Already decompressed $Rname\n";
                }
                else {
                    print `/opt/alDente/versions/rguin/bin/decompress.pl -D sequence -L $Rname`;
                    push( @decompressed, $Rname );
                }
                print "\n*** Decompression done..\n";
                my $moved = `/opt/alDente/versions/rguin/bin/update_sequence.pl -A get -S $Rid`;
                while ( $moved =~ s/detected (\d+)//i ) { print "Detected $1 ..\n" }
                print "\n*** files moved to archive if possible  (Run Again) ***..\n";
            }
        }
        my $Mnum  = 0;
        my $Msize = 0;
        foreach my $nextdir (@mirrored) {
            print "check $nextdir\n";

            #	    if (-e $nextdir) {
            my @brokenlinks = `find $nextdir -xtype l -maxdepth 1`;

            #	    if (int(@archived) < 96) { print " ** less than 96 archived files ** : " . int(@archived) . "\n" }
            if ( int(@brokenlinks) ) {
                print "\n*** DELETE " . int(@brokenlinks) . " Broken Links ****\n";
                if (@brokenlinks) {
                    foreach my $broke (@brokenlinks) {
                        `rm $broke`;
                        if ($verbose) { print "-- deleted: $broke.\n" }
                    }
                }
            }
            else { print " ( No broken links in $nextdir) \n" }

            #	    }
            if ( -e $nextdir ) {
                my $dirsize = `du -Ls $nextdir`;
                if ( $dirsize < 20 ) {    ### get rid of essentially empty directories...
                    my @included = glob("$nextdir/*");
                    if ( int(@included) == 1 ) {
                        my $Idir = $included[0];
                        if ( $Idir =~ /(.*)\/(.+)$/ ) {
                            if ( -e "$Idir/$2" ) {
                                #### recursive directories ###
                                `rm -fR $nextdir/$2`;
                                print "\n** Deleted SMALL recursive directory.\n ";
                            }
                        }
                    }
                }
                `rmdir $nextdir`;    ### if empty only
                `rm $nextdir`;       ### if empty only
                $dirsize = `du -Ls $nextdir`;
                $Msize += $dirsize;
            }
            unless ( -e "$nextdir" ) {next}
            my @traces = `find $nextdir/ -type f -maxdepth 1`;
            $Mnum += int(@traces);
        }
        my $Anum  = 0;
        my $Asize = 0;
        foreach my $nextdir (@archived) {
            print "$nextdir..\n";
            if ( -d "$nextdir" ) {
                my @broke = `find $nextdir/ -xtype l -maxdepth 1`;
                foreach my $broken_link (@broke) {`rm $broken_link`}
                my @traces = `find $nextdir/ -type f -maxdepth 1`;
                $Anum  += int(@traces);
                $Asize += `du -Ls $nextdir`;
            }
            elsif ( -f "$nextdir" ) {
                $Anum++;
                $Asize += `du -Ls $nextdir`;
            }
        }
        my $Znum    = 0;
        my $Zsize   = 0;
        my $Plinks  = int(@links);
        my $Pbroken = int(@broken);
        my $Pfiles  = int(@files);
        ### get rid of broken links that are redundant ###
        if ( int(@zipped) && ( $Asize > 150 * $Anum ) && !$Pbroken && ( ( ( $Anum == 96 ) && ( $format =~ /^96(.*)/ ) ) || ( ( $Anum == 384 ) && ( $format =~ /^(384|96-well x 4)/ ) ) ) ) {
            print "\n*** DELETE " . int(@zipped) . " Zipped FILES (with REDUNDANT broken links) ****\n";
            unlink @zipped;
            unlink @broken;
            @zipped  = ();
            @broken  = ();
            $Pbroken = 0;
            $Plinks -= $Pbroken;
        }
        ### get rid of zipped files if Archived files exist and are big...
        if ( ( $Anum >= 96 ) && ( $Asize > 150 * $Anum ) && ( $Plinks >= 96 ) && ( $Pbroken == 0 ) && ( $format =~ /96(.*)96/ ) && int(@zipped) && ( int(@zipped) <= $Anum ) ) {
            print "\n*** DELETE " . int(@zipped) . " Zipped FILES ****\n";
            unlink @zipped;
            @zipped = ();
        }
        foreach my $nextdir (@zipped) {
            unless ( -e $nextdir ) {next}
            my @traces = `tar -ztvf $nextdir`;
            $Zsize += `du -Ls $nextdir`;
            $Znum  += int(@traces);
        }
        print " [M:$Mnum:$Msize] [A:$Anum:$Asize] [Z:$Znum:$Zsize]";
        print " L:$Plinks";
        print " F:$Pfiles";
        print " X:$Pbroken";
        my $ok = &Table_update_array(
            $dbc, 'TraceData',
            [ 'Mirrored', 'MirroredSize', 'Archived', 'ArchivedSize', 'Zipped', 'ZippedSize', 'Checked', 'Machine', 'Links', 'Files', 'Broken', 'Path',      'Format' ],
            [ $Mnum,      $Msize,         $Anum,      $Asize,         $Znum,    $Zsize,       $today,    $Ename,    $Plinks, $Pfiles, $Pbroken, $path_found, $format ],
            "where FK_Run__ID=$Rid",
            -autoquote => 1
        );
        $checked++;
        print " [$ok].\n";
    }
}
$dbc->disconnect();
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
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
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

$Id: trace_archive.pl,v 1.6 2004/06/03 18:11:41 achan Exp $ (Release: $Name:  $)

=cut

