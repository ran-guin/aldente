#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

cleanup_web.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>cleanup.pl<BR>This program:<BR>compresses old backup files, <BR>removes old files in Temp directory<BR>NOTE:  directories are hard coded for Safety (/home/sequence/)<BR>

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
#
################################################################################
#
# cleanup.pl
#
# This program:
#   compresses old backup files,
#   removes old files in Temp directory
#
# NOTE:  directories are hard coded for Safety (/home/sequence/)
#
################################################################################
################################################################################
# $Id: cleanup_web.pl,v 1.9 2004/05/25 23:37:30 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.9 $
#     CVS Date: $Date: 2004/05/25 23:37:30 $
################################################################################

########################################
## Standard Initialization of Module ###
########################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/LampLite";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

########################
## Local Core modules ##
########################
use CGI;
use Data::Dumper;
use Benchmark;

use strict;
##########################
## Local custom modules ##
##########################
use RGTools::RGIO;
use LampLite::Bootstrap;

use SDB::DBIO;         ## use to connect to database
use SDB::DB_Access;    ## use to retrieve login access passwords
use SDB::HTML;         ## use for web interface output (only needed for cgi-bin files)

use alDente::Config;   ## use to initialize configuration settings

### Modules used for Web Interface only ###
use alDente::Session;
use LampLite::MVC;

##############################
# global_vars                #
##############################
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);        ## replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
use vars qw($homelink);       ## replace with $dbc->homelink()
use vars qw(%Search_Item);    ## replace with $dbc->homelink()
use vars qw($Connection);
use vars qw(%Field_Info);
use vars qw($scanner_mode);
###############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Config = new alDente::Config( -initialize => 1, -root => $FindBin::RealBin . '/..' );

my ( $home, $version, $domain, $custom, $path, $dbase, $host, $login_type, $session_dir, $init_errors, $url_params, $session_params, $brand_image, $screen_mode, $configs, $custom_login, $css_files, $js_files, $init_errors, $configs ) = (
    $Config->{home},       $Config->{version},      $Config->{domain},      $Config->{custom},     $Config->{path},           $Config->{dbase}, $Config->{host},
    $Config->{login_type}, $Config->{session_dir},  $Config->{init_errors}, $Config->{url_params}, $Config->{session_params}, $Config->{icon},  $Config->{screen_mode},
    $Config->{configs},    $Config->{custom_login}, $Config->{css_files},   $Config->{js_files},   $Config->{init_errors},    $Config->{configs}
);

if ( ref $configs eq 'HASH' ) { %Configs = %$configs }

SDB::CustomSettings::load_config($configs);    ## temporary ...

#####################
## Input Arguments ##
#####################
use vars qw($opt_help);
use vars qw($opt_S $opt_u);

use Getopt::Long;
&GetOptions(
    'help|h'   => \$opt_help,
    'save|S=s' => \$opt_S,
    'user|u=s' => \$opt_u,
);

use RGTools::Process_Monitor;
use SDB::Report;

if ($opt_help) {
    print help();
    exit;
}

############################################
## End of Standard Template for bin files ##
############################################
use vars qw($opt_P $opt_S $opt_X $opt_u);

my $URL_temp_dir      = $Configs{URL_temp_dir};
my $session_dir       = $Configs{session_dir};
my $Web_log_directory = $Configs{Web_log_directory};
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
use vars qw($opt_X $opt_P);    # not used..

############# Options for Cleaning UP ###########
my $directory;
my $exception;
my $preserve;
my $erased    = 0;
my $checked   = 0;
my $preserved = 0;
my $removed   = 0;
my $save      = 0;
my $unknown   = 0;
my $DEBUG_API = 0;
( my $archive_dir    = $Configs{Data_log_dir} ) =~ s/logs/sessions/;
( my $API_logs_dir   = $Configs{API_logs} );
( my $archive_domain = $Configs{URL_domain} ) =~ s/http:\/\///;
$archive_domain =~ s/\.bcgsc\.ca//;

my $archive_path = "$archive_dir/$archive_domain";

######################## construct Process_Monitor object for writing to log file ###########
my %convert_month = (
    '01' => 'Jan',
    '02' => 'Feb',
    '03' => 'Mar',
    '04' => 'Apr',
    '05' => 'May',
    '06' => 'Jun',
    '07' => 'Jul',
    '08' => 'Aug',
    '09' => 'Sep',
    '10' => 'Oct',
    '11' => 'Nov',
    '12' => 'Dec',
);

my $Report = Process_Monitor->new( -configs => $configs );

if ($opt_X) { $exception = $opt_X; }
if ($opt_P) {
    $preserve = Extract_Values( [ $opt_P, 1 ] );
    if ( $preserve < 10 ) { $preserve = "0$preserve"; }
}
my $userid;
if ($opt_u) {
    $userid = $opt_u;
}
if ($opt_S) { $save = " -mtime +$opt_S"; }
else {
    $Report->set_Error("Specify days to Save ( '-S 4' to save Session files newer than 4 days old)");
    help();
    exit;
}

##### track cleanup in log_file... #######
my $log_file  = "$Web_log_directory/cleanup/cleanup_" . &today;
my $temp_save = 7;

### save time in days for temporary directories...
#### Get rid of old files in Temp directory ####
$Report->set_Detail("Cleaning out Temp directory..");
if ( $URL_temp_dir =~ /tmp/i ) {
    ### require path name to include temp to be sure int is imported...
    my @imagelist = split '\n', try_system_command( "find $URL_temp_dir/ -mtime +$temp_save -type f", -report => $Report );
    my $deleted = 0;
    foreach my $file (@imagelist) {
        if ( $file =~ /(.*)\/tmp\/(.*)/i ) {    #ensure it is a temp directory..
            $Report->set_Detail("delete $file..");
            unlink($file);

            #           ### hard code in TEMP path to be SAFE
            #	    $fback .= "rm -f $1/tmp/$2\n";
            #	    $fback .= try_system_command("rm -f $1/tmp/$2");
            $deleted++;
        }

        #    unlink $file;
    }
    $Report->set_Message("Deleted $deleted files older than $temp_save days old from $URL_temp_dir");
}

############# also clean up SessionInfo files... #############
$Report->set_Detail("Move Sessions to subdirectories");

# session files are stored in a code version / database structure now
# for example the session files for SDB (i.e. production) using sequence database will be stored in $session_dir/production/sequence/ directory

# get code version directory first in $session_dir
my $search_version = "find $session_dir -maxdepth 1 -type d ";
my @versionlist = split "\n", try_system_command( $search_version, -report => $Report );

foreach my $version (@versionlist) {
    ## ignore session_dir..
    if ( $version ne $session_dir ) {

        #find database directory in each code version directory
        my $search_db = "find $version -maxdepth 1 -type d ";
        my @dblist = split "\n", try_system_command( $search_db, -report => $Report );
        foreach my $db_dir (@dblist) {
            ## ignore version directory
            if ( $db_dir ne $version ) {

                #archiving
                $Report->set_Detail("Archiving $db_dir");

                my $search = "find $db_dir/ -maxdepth 1 -name \"$userid*\" $save -type f ";
                my @sessionlist = split "\n", try_system_command( $search, -report => $Report );

                $Report->set_Detail( "found " . int(@sessionlist) . " Session files" );
                if ( $sessionlist[0] =~ /too long/ ) {
                    $Report->set_Detail(" *** LIST TOO LONG ... ***");
                }
                elsif ( int(@sessionlist) < 2 ) {
                    $Report->set_Detail("@sessionlist");
                }
                my $moved = 0;
                my $feedback;
                my $ignored = 0;
                foreach my $file (@sessionlist) {
                    unless ( $file && $db_dir ) {next}
                    if ( $file =~ /$db_dir\/(.+)\// ) {
                        ## ignore subdirectory files..
                        $Report->set_Detail("skip subdirectory $file");
                        next;
                    }
                    if ( $file =~ /$db_dir\/\-1\./ ) {
                        ## ignore -1 session files for now.
                        $Report->set_Detail("skip $file");
                        next;
                    }
                    if ( $file =~ /$db_dir\/\d*:(\w{3})_(\w{3})_([\d_]{2})(.*)(\d{4})/ || $file =~ /$db_dir\/\w*:(\w{3})_(\w{3})_([\d_]{2})(.*)(\d{4})/ ) {

                        #                        print "Found $file\n";
                        my $month = $2;
                        my $year  = $5;
                        my $day   = $3;
                        $day =~ s /_/0/;

                        $Report->set_Detail("$month $day/ $year;");

                        ###Making archive a non local link
                        if ( !-e "$archive_path" ) { my $dir = create_dir( -path => $archive_path, -mode => 775 ); }
                        ( my $archive_version = $version ) =~ s/$session_dir/$archive_path/;
                        if ( !-e "$archive_version" ) { my $dir = create_dir( -path => $archive_version, -mode => 775 ); }
                        ( my $archive_db = $db_dir ) =~ s/$session_dir/$archive_path/;
                        if ( !-e "$archive_db" ) { my $dir = create_dir( -path => $archive_db, -mode => 775 ); }

                        my $dir = create_dir( "$archive_db/archive/", "$year/$month/$day", 775 );

                        if ( !-e "$db_dir/archive" ) { my $link = try_system_command("ln -s $archive_db/archive $db_dir/archive"); }

                        my $error;
                        my $filename = $file;
                        $filename =~ s/$db_dir\///;

                        #if ( -f "$dir/$filename" ) {    # If session file already exist, merge the new one into it
                        #    $error = &try_system_command( "cat $file $dir/$filename > $file.tmp", -report => $Report );
                        #    $error = &try_system_command( "mv $file.tmp $dir/$filename",          -report => $Report );

                        #}
                        #else {                          # Otherwise just move the file into the archived folder
                        $error = &try_system_command( "mv $file $dir/", -report => $Report );

                        #}
                        if ($error) {
                            $Report->set_Error("Error moving $file to $dir in $month ?: $error");
                        }

                        $moved++;
                    }
                    elsif ( $file =~ /$db_dir\/cgisess/ ) {
                        my $stat_command = "stat $file";
                        my @info         = split "\n", try_system_command( $stat_command, -report => $Report );
                        my @info_2       = split " ", $info[5];
                        my ( $year, $mon, $day ) = split '-', $info_2[1];
                        my $month = $convert_month{$mon} || $mon;

                        ###Making archive a non local link
                        if ( !-e "$archive_path" ) { my $dir = create_dir( -path => $archive_path, -mode => 775 ); }
                        ( my $archive_version = $version ) =~ s/$session_dir/$archive_path/;
                        if ( !-e "$archive_version" ) { my $dir = create_dir( -path => $archive_version, -mode => 775 ); }
                        ( my $archive_db = $db_dir ) =~ s/$session_dir/$archive_path/;
                        if ( !-e "$archive_db" ) { my $dir = create_dir( -path => $archive_db, -mode => 775 ); }
                        my $dir = create_dir( "$archive_db/archive/", "$year/$month/$day", 775 );

                        if ( !-e "$db_dir/archive" ) { my $link = try_system_command("ln -s $archive_db/archive $db_dir/archive"); }

                        my $error;
                        my $filename = $file;
                        $filename =~ s/$db_dir\///;
                        $error = &try_system_command( "mv $file $dir/", -report => $Report );

                        if ($error) {
                            $Report->set_Error("Error moving $file to $dir in $month ?: $error");
                        }

                        $moved++;
                    }
                    elsif ( $file =~ /$db_dir\/\.sess/ || $file =~ /$db_dir\/\.login/ ) {
                        try_system_command("rm -f $file");
                    }
                    elsif ( !$userid ) {
                        $ignored++;
                    }
                    else {
                        $Report->set_Warning("Not sure where to relocate $file in $db_dir/");
                    }
                }

                if ($ignored) {
                    $Report->set_Message("Ignored $ignored unassigned files in $db_dir");
                }
                elsif ($moved) {
                    $Report->set_Message("Moved $moved old Session files (in $db_dir)");
                }
                elsif ( grep /\b(www|template|custom|bin|lib|Options|Plugins|install|svn|conf|docs|tmp)\b/, $db_dir ) {
                    $Report->set_Message("Skipping $db_dir files");
                }
                else {
                    $Report->set_Warning("Did nothing in $db_dir");
                }

            }
        }
    }
}
#### delete sessions older than one month AS WELL ####

###################################################################################################################################
# ***** Info about the 'if' statement implemented below *****
#
# find and tar API logs that are more than 2 months old
#
# remove the original (untared) directories
#
# By: Himanshu Sharma (Co-op)
# Email: hsharma@bcgsc.ca
###################################################################################################################################

if ($API_logs_dir) {

    # Find all 'month' directories that are more than 2 months (-mtime +60) old
    my ( $find_API_dirs, @archive_API_dirs, $tar_command );
    $find_API_dirs = "find $API_logs_dir -mindepth 2 -maxdepth 2 -mtime +60 -type d";
    @archive_API_dirs = split "\n", try_system_command( $find_API_dirs, -report => $Report );

    # tar -cjf the 'month' directories that are more than 2 months old
    foreach my $archive_API_dir (@archive_API_dirs) {
        $archive_API_dir =~ /(.*)(\d\d)$/;
        my $month = $2;
        $tar_command = "tar -cjf $1$month.tar.bz2 $archive_API_dir";
        try_system_command( $tar_command, -report => $Report );
    }

    #remove all the untar(ed) directories that are more than 2 months old
    my $remove_cmd;
    foreach my $remove_dir (@archive_API_dirs) {
        $remove_cmd = "rm -r $remove_dir";
        try_system_command( $remove_cmd, -report => $Report );
    }

    if ($DEBUG_API) {
        print Dumper @archive_API_dirs;
        print $tar_command;
        print $remove_cmd;
    }

}

$Report->completed();
$Report->succeeded();
$Report->DESTROY();

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
sub help {
    print <<HELP;
File:  cleanup.pl
#####################
Options:
##########
-save (S) N             number of days to Save.  (all older than N days will be erased) 
-user (u) 25            specify user for session files to move...
(to restore database use:  'restore_DB')
Example:  
###########
           cleanup_web.pl -S 7
cleans up all files except those within the last 7 days.
(Also save files containing a datestamp for the first of the month).
Note:
###########
cleanup.pl also empties some TEMP directories of files (older than 2 days by default)
HELP

}

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

$Id: cleanup_web.pl,v 1.9 2004/05/25 23:37:30 achan Exp $ (Release: $Name:  $)

=cut

