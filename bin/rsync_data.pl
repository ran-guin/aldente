#!/usr/local/perl/lims-5.8.8/bin/perl
use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";    # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::FTP;

use vars qw($opt_help $opt_quiet $opt_path $opt_remove $opt_link $opt_dest $opt_exclude $opt_in_progress_file $opt_finish_file $opt_log_file);

use Getopt::Long;
&GetOptions(
    'help'               => \$opt_help,
    'quiet'              => \$opt_quiet,
    'path=s'             => \$opt_path,
    'remove'             => \$opt_remove,
    'link'               => \$opt_link,
    'dest=s'             => \$opt_dest,
    'exclude=s'          => \$opt_exclude,
    'in_progress_file=s' => \$opt_in_progress_file,
    'finish_file=s'      => \$opt_finish_file,
    'log_file=s'         => \$opt_log_file,
    ## 'parameter_with_value=s' => \$opt_p1,
    ## 'parameter_as_flag'      => \$opt_p2,
);

my $help    = $opt_help;
my $quiet   = $opt_quiet;
my $path    = $opt_path;
my $remove  = $opt_remove;
my $link    = $opt_link;
my $dest    = $opt_dest;
my $exclude = $opt_exclude;
my $debug   = 0;
my $source_dir;
my $dest_dir;
my $finish_commands;
my $complete_file;
my $parent_dir;

if ($link) {
    my $readlink = `readlink $path`;
    chomp $readlink;
    $readlink =~ s/\/+$//;
    $source_dir      = $readlink . "/" if $readlink;
    $dest_dir        = $path . "_rsync";
    $finish_commands = "unlink $path; mv $dest_dir $path;";
    $complete_file   = $path . "/rsync.finished.txt";
    if ( $source_dir =~ /(.*)\/.+/ ) { $parent_dir = $1; }
}
elsif ($dest) {
    if ( $path =~ /,/ ) {
        $source_dir = $path;
        $source_dir =~ s/,/ /g;
        $dest_dir      = $dest;
        $complete_file = $dest_dir . "rsync.finished.txt";
    }
    else {
        $source_dir = $path;
        my $dir;
        if ( $source_dir =~ /.*\/(.*)/ ) { $dir = $1 }
        $source_dir .= "/";
        $dest_dir      = "$dest/$dir";
        $complete_file = $dest_dir . "/rsync.finished.txt";
    }
}

if ( !$source_dir || !$dest_dir ) {exit}

my $log_file         = $dest_dir . "/rsync.log";
my $in_progress_file = $path . "/rsync.in_progress.txt";

$log_file         = $opt_log_file         if $opt_log_file;
$in_progress_file = $opt_in_progress_file if $opt_in_progress_file;
$complete_file    = $opt_finish_file      if $opt_finish_file;

my $rsync_complete = &run_rsync( -source_dir => $source_dir, -dest_dir => $dest_dir, -log_file => $log_file, -exclude => $exclude, -verbose => '' ) if !$debug;
if ($rsync_complete) {
    print "rsync complete\n";
    if ( !$debug ) {
        try_system_command( "$finish_commands touch $complete_file; rm $in_progress_file", -verbose => 1 );
        if ($remove) {
            try_system_command( "rm -rf $source_dir", -verbose => 1 );
            if ($parent_dir) {
                try_system_command( "rmdir $parent_dir", -verbose => 1 );
            }
        }
    }
}
else {
    try_system_command( "rm $in_progress_file", -verbose => 1 );
    print "rsync incomplete\n";
}

exit;

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    rsync_data.pl -p 

Mandatory Input:
**************************
  -p <path that is a symlink>
Options:
**************************     
  -r <remove parent directory>

Examples:
***********

HELP

}
