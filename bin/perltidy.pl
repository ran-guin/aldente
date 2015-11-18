#!/usr/local/bin/perl

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use SDB::CustomSettings;

use vars qw(%Configs $opt_help $opt_quiet $opt_dir $opt_file $opt_overwrite $opt_swap $opt_html $opt_method $opt_print);

use Getopt::Long;
&GetOptions(
    'help'      => \$opt_help,
    'quiet'     => \$opt_quiet,
    'dir=s'     => \$opt_dir,
    'file=s'    => \$opt_file,
    'method=s'  => \$opt_method,
    'print'     => \$opt_print,
    'swap'      => \$opt_swap,
    'html'      => \$opt_html,
    'overwrite' => \$opt_overwrite,
## 'parameter_with_value=s' => \$opt_p1,
    ## 'parameter_as_flag'      => \$opt_p2,
);

my $help      = $opt_help;
my $quiet     = $opt_quiet;
my $dir       = $opt_dir;
my $file      = $opt_file;
my $swap      = $opt_swap;
my $html      = $opt_html;
my $overwrite = $opt_overwrite;
my $method    = $opt_method;
my $print     = $opt_print;

my $success = 0;
if ($file) {
    $success = tidy( $file, $method );
}
elsif ($dir) {
    my $found = `find "$dir" -type f -name *.pm`;

    foreach my $module ( split "\n", $found ) {
        $success += tidy($module) if $module;
    }
}
else {
    help();
}

print "\n$success file(s) successfully tidied\n";
exit;

##############################
# Run perltidy on given file
#
# (optionally include a method so that ONLY the given method will be tidied (case sensitive)
#
################
sub tidy {
############
    my $file   = shift;
    my $method = shift;

    ## -csc -csci=20 -cscw                    ## defer closing side comments since it breaks Textmate indenting feature (textmate bug).

    my $options = "-pbp -l=255 -dcsc -nbol -nst -nse";    ## set max line to 255; closing side comments (on blocks bigger than 20 lines); no breaks on logical separators
    my $path    = "$Configs{web_dir}/html/perldoc";

    chomp $file;

    print "Tidying $file";
    if ($method) { print " (method = $method)" }
    print "\n";

    if ( -e "$file.tdy" && !$overwrite ) {
        Message("tdy file exists - use overwrite flag to overwrite");
    }
    else {
        `/home/aldente/private/software/perltidy $options "$file"`;

        if ( -e "$file.ERR" ) {
            print "** Error detected **\n";
            print `cat $file.ERR`;
            return 0;
        }

        if ($method) { tidy_method( $file, $method ) }

        if ($swap) {
            Message("SWAPPING...");
            `cp "$file" "$file.utdy"`;
            `cp "$file.tdy" "$file"`;
        }
    }

    if ($html) {
        if ($file =~/^(.*)\/(.+)/) { 
            my $local_path = $1; 
            my $local_file = $2;
            
            create_dir($local_path, -mode=>'777');
        }

        print "* perldoc generated:  $path/$file\n";
        `/home/aldente/private/software/perltidy $options -html "$file"`;   ## normally exits cleanly on success
        print "/home/aldente/private/software/perltidy $options -html $file\n";
        `cp "$file.html" "$path/$file.html"`;
        print qq{cp "$file.html" "$path/$file.html"\n};
    }
    return 1;
}

######################################
#
# Only tidies a specified method...
#
# (overwrites the .tdy file using only the given method tidied)
#
####################
sub tidy_method {
####################
    my $file   = shift;
    my $method = shift;

    ## get original untidied file (excluding tidied method) ##

    my $started  = 0;
    my $finished = 0;

    my @before_method;
    my @after_method;

    open my $FILE, '<', $file or die "Cannot open $file";
    while (<$FILE>) {
        my $line = $_;
        if ($finished) {
            ## already found method... just add to current file
            push @after_method, $line;
            next;
        }

        if (/^sub\s+(\w+)/) {
            ## new method found ##
            my $found_method = $1;
            if ($started) {
                ## this must be the next method, so finish up and add tidied method to current file		$finished++;
                push @after_method, $line;
                $finished++;

            }
            elsif ( $found_method =~ /\b$method\b/ ) {
                ## found method of interest ##
                #		push @tidied, $line;
                $started++;
            }
            else {
                ## standard line before given method ##
                push @before_method, $line;
            }
        }
        elsif ($started) {
            ## inside method of interest ##
            #	    push @tidied, $line;
        }
        else {
            push @before_method, $line;
        }
    }
    close $FILE;

    ## get tidied method ##
    $started  = 0;
    $finished = 0;
    my @tidied;
    open my $FILE, '<', "$file.tdy" or die "Cannot open $file";
    while (<$FILE>) {
        my $line = $_;

        if (/^sub\s+(\w+)/) {
            ## new method found ##
            my $found_method = $1;
            Message("Found $found_method ($method?)");
            if ($started) {
                ## this must be the next method, so finish up and add tidied method to current file
                last;

                #		$finished++;
                #		push @untidied, @tidied;
                #		push @untidied, $line;

            }
            elsif ( $found_method eq $method ) {
                ## found method of interest ##
                Message("Found $method");
                push @tidied, $line;
                $started++;
            }
            else {
                ## standard line before given method ##
                #		push @untidied, $line;
            }
        }
        elsif ($started) {
            push @tidied, $line;
        }
        else {
            print ".";

            #	    push @untidied, $line;
        }
    }
    close $FILE;

    my @contents = @before_method;
    push @contents, @tidied;
    push @contents, @after_method;

    print "Tidied $method\n@tidied\n";
    if ($print) {
        open my $TMP, '>', "$file.tdy.$method.pm" or die "cannot write to $file.tdy.$method.pm for printing\n";
        print $TMP join '', @tidied;
        close $TMP;
        print "Saved copy of tidied method to $file.tdy.$method.pm\n";
    }

    ## write contents to new tdy file ##

    open my $TDY, '>', "$file.tdy" or die "Cannot write to $file.tdy\n";
    print $TDY join '', @contents;
    close $TDY;

    return;
}

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    perltidy -file <filename>
    perltidy -dir <directory> -swap 
    perltidy -file <filename> -method <method> -swap   

Mandatory Input:
**************************

-file  OR -dir 

Options:
**************************     
-swap     automatically swap the tdy file into the original (saves the original as *.utdy)
-html     generates the html pod file.
-method   only tidies the specified method
-print    saves copy of tidied section of method to <filename>.tdy.method

Examples:
***********

perltidy -dir lib/perl/SDB -swap -html
perltidy -file lib/perl/alDente/alDente_API.pm -swap -html -print -method get_read_data

HELP

}
