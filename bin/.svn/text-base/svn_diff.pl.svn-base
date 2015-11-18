#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
##############################
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use Getopt::Std;
use Data::Dumper;
use Storable;
use RGTools::RGIO;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
our ( $opt_d, $opt_t, $opt_m, $opt_R, $opt_s, $opt_S, $opt_v, $opt_f, $opt_C, $opt_x, $opt_h );
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
getopts('d:t:mRs:iS:vf:Cx:h');

###Global variables and command line options;
my $Dir;
my $Target;
my $Move;
my $Recursive;
my $Dir    = $opt_d || '';
my $Target = $opt_t || '';
my $Move   = $opt_m || 0;
my $temp   = $opt_s || '';
my $subdir = $opt_S || 'RGTools';
my $verbose   = $opt_v;
my $file_spec = $opt_f || '*';
my $clear     = $opt_C;
my $ext       = $opt_x;
my $help      = $opt_h;

if ( $file_spec =~ /(.+)(\..+)/ ) { $file_spec = $1; $ext = $2 }
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
if ($help) {
    print <<HELP

    Usage:

    svn_diff.pl [arguments]

    argument options:

    -S <Subdirectory> (eg '-S RGTools', '-S cgi-bin')
    -f <file>  (eg 'DBIO' or 'DBIO.pm')
    
    -v (verbose mode - shows full diffs)
    -C (clear (rm) files that are the same between production & development mode AND no current -r HEAD diffs)
    
******************
    This generates an overview of the svn differences detected between the production mode and the test mode

    It also generates a list of differences between the current version and the HEAD for this version

    ***************

    Examples:

    svn_diff.pl -S SDB  (find all of the SDB module diffs)
    svn_diff.pl -S ./install -f '*.pat' (find all of the patch file diffs)
    svn_diff.pl -S ./install -x '.pat'  (find all of the .pat file diffs - same as above)
    svn_diff.pl -S ./www -f '*.*'       (find all file diffs under the www directory)

HELP
}
if ($help) {exit}
my @dirs = ( '/opt/alDente/versions/dev/', '/opt/alDente/versions/alpha/' );

if ( $subdir =~ /bin$/ ) {
    $ext ||= '.pl';
    $subdir = "./$subdir";
}
else {
    $ext ||= '.pm';
    if ( $subdir !~ /^\./ ) { $subdir = './lib/perl/' . $subdir }    ## allow specification eg -S ./Plugins ##
}

if ( $file_spec =~ /\w+/ || $ext =~ /\w+/ ) { $file_spec = "-name $file_spec$ext" }

my @files = split "\n", `find $subdir $file_spec -type f`;

print "Found " . int(@files) . ' files';
print "\n [ find $subdir $file_spec -type f ]\n";

my @svn;
foreach my $i ( 0 .. $#dirs ) {
    my $svn_info = `svn info $dirs[$i] | grep '^URL'`;
    chomp $svn_info;
    $svn_info =~ s/URL:\s*//;
    $svn[$i] = $svn_info;
}

if ( !@files ) {
    Message("no files found from: 'find $subdir $file_spec -type f");

    my $diff_command = "svn diff -x -w $svn[0]/$subdir/ $svn[1]/$subdir/ | grep ^Index";
    Message($diff_command);

    my @version_diffs = split "\n", `$diff_command`;
    Message( int(@version_diffs) . " Primary File differences\n\n" );
    foreach my $version_diff (@version_diffs) {
        $version_diff =~ s/^Index:\s+//;
        if ( !grep /$subdir\/$version_diff$/, @files ) {
            Message("NEW FILE: $version_diff");
            push @files, $version_diff;
        }
    }
}
print "\nCompare SVN versions:\n\n* ";
print join "\n* ", @svn;
print "\n\n";

my %cmp;
my @no_diff;
foreach my $i ( 0 .. $#files ) {
    my $file = $files[$i];
    chomp $file;
    my $filename;
    if ( $file =~ /(.*)\/(.+)\/(.+)$/ ) { $filename = "$2/$3" }
    elsif ( $file !~ /\b$subdir\// ) { $filename = "$subdir/$file" }
    else                             { Message("FILE: $file ??"); next; }

    my @commands = ( "\svn diff -x -w $svn[0]/$file $svn[1]/$file", "\svn diff -x -w -r HEAD $file" );

    my $i = 0;
    foreach my $command (@commands) {
        $i++;
        my $results = `$command 2>&1`;
        my @lines = split '\n', $results;

        if ($file) { print "$command\n\n"; }

        if ( ( int(@lines) < 3 ) && $lines[0] =~ /(not under version control|not found in the repository)/ ) {
            $cmp{$filename} .= "* $filename NOT UNDER VERSION CONTROL *\n";
        }
        my $plus_count  = int( grep /^\+\s/, @lines );
        my $minus_count = int( grep /^\-\s/, @lines );

        if   ( !$plus_count && !$minus_count ) { }                                                       ## $cmp{$filename} .= "+/- 0 \n"; }
        else                                   { $cmp{$filename} .= "+ $plus_count; - $minus_count;" }

        if ($verbose) { $cmp{$filename} .= "\n$command:\n********************\n$results\n" }
    }
    if ( !$cmp{$filename} ) {
        push @no_diff, $file;
    }
    print "** $file **\n";
}

print "\n\nNo Diffs\n*********\n";
print join "\n", @no_diff;
if ($clear) {
    foreach my $file (@no_diff) { `rm $file`; }
}
print "\n\nDiffs (line count)\n=> beta [+] vs production [-] [ current vs HEAD ] \n************************\n";
print Dumper \%cmp;

print "\n\n";
exit;

