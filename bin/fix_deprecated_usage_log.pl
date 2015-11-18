#!/usr/local/bin/perl

use strict;

#use warnings;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";

use RGTools::RGIO;

use Getopt::Std;
use Getopt::Long;

use vars qw($opt_search $opt_call $opt_fixed $opt_module $opt_call $opt_list $opt_level);
&GetOptions(
    'list'     => \$opt_list,
    'fixed'    => \$opt_fixed,
    'module=s'   => \$opt_module,
    'call=s'     => \$opt_call,
    'search=s'     => \$opt_search,
    'level=s'   => \$opt_level,
);

## This is a file solely for testing if Eclipse and LIMS svn can work together harmonly.
## This file will be removed once the test is done.

my $context = $opt_module;    ## $ARGV[0];
my $call  = $opt_call;      ## $ARGV[1];
my $search = $opt_search;
my $list    = $opt_list;
my $level  = $opt_level || '0';

my $find = !$opt_fixed;       ## find usage if not marked as fixed...

my $log = "/home/aldente/private/logs/usage_conflicts.log";

my @contexts;

if ( $context && !$call && !$search ) { $call = $context; $context = '?' }

print "File:\t$log\n";
print "Search: \t$search\n";
print "Call: \t$call\n";
print "Context: \t$context\n";

if ( !$list && !$search && !$context && !$call) {
    print "You must specify a call to search for\n";
    print "To clear the log, you must specify the context in which it has been fixed (eg which module)\n";
    print "\nExamples:\n";
    print "\n>$0 -list\n";
    print "\n\tthis will generate a unique list of calls that need to be corrected (though they may require correcting from further up in the Call_Stack)\n";
    print "\n>$0 -list -level N\n";
    print "\n\tthis will generate a unique list of calls N levels below the detected conflict - defaults to 0 (this is useful when corrections are made one level at a time)\n";
    print "\n>$0 -search <string>\n";
    print "\n\tthis will display all Call_Stack blocks containing <search> criteria\n";
    print "\n>$0 -call foreign_key_check\n";
    print "\n\tthis will generate a list of all sources of calls to foreign_key_check\n";
    print "\n>$0 -module SDB::DBIO -call foreign_key_check -fixed\n";
    print "\n\tthis will clear all calls to foreign_key_check from SDB::DBIO\n\n";

    print "\nThe log file for the usage conflicts should be:\n$log\n\n";
    exit;
}
elsif ($find) {
    my @grep_results = split "\n", try_system_command("cat $log");
    my @unique;
    my $stamp;
    my $file;
    my %Calls;
    my %Stamp;
    my %File;
    
    if ($call) { print "$call Called by:\n\n";}
    elsif ($search) { print "$search found in logs:\n\n" }
    else { $call = "$level =>"; print "Calls generating conflicts:\n"; }
    
    my $block;
    foreach my $i ( 0 .. $#grep_results ) {
        my $line = $grep_results[$i];
        if ($line =~/2012\-/) { 
            if ($search && $block =~/$search/) {
                $block =~s/(\t\S+ => .*$search)/*** $1/;
                $block =~s/^(\S.*$search)/*** $1/;
                print "\n$block\n";
            }
            $block = "$line\n";
        }
        else { $block .= "\t$line\n" }
        
        if ( $line =~ /\d\d\d\d\-\d\d\-\d\d/ ) { $stamp = $line }
        if ( $line =~ /M =>(.*)\/(\S+)/ )      { $file  = $2 }
        if ( $call && $line =~ /\b\Q$call\E/ ) {
            if ( $context && ( $grep_results[ $i + 1 ] !~ /\Q$context\E/ ) ) {next}
            $Calls{ $grep_results[ $i + 1 ] }++;
            $Stamp{ $grep_results[ $i + 1 ] } = $stamp;

            if ( $grep_results[ $i + 1 ] =~ /\bmain\b/ ) {
                ## include file if called directly from main
                $Stamp{ $grep_results[ $i + 1 ] } .= " from $file";
            }
        }
    }
   
    if ($search && $block =~/$search/) {
        $block =~s/(\t\S+ => .*$search)/*** $1/;
        $block =~s/^(\S.*$search)/*** $1/;
        print "\n$block\n";
    }

    foreach my $call ( sort keys %Calls ) {
        print "$call \tX $Calls{$call} \t[last noted conflict: $Stamp{$call}]\n";
    }
    print "\n\n";
    exit;
}

if (!$opt_fixed) { exit }   ## should already have exited... but include to be safe... 

## clear indicated calls from log ##
if ($call) { print "Search for $call call in $log\n\n"; }
if ($search) { print "Search for $search anywhere in $log\n\n" }

open my $LOG, '<', $log or die "Cannot find $log\n";

open my $NEWLOG, '>', "$log.tmp" or die "Cannot build $log.tmp file\n";

chmod 0664, $NEWLOG;

my $block   = '';
my $cleared = 0;
my $found   = 0;
my $clear   = 0;

while (<$LOG>) {
    my $line = $_;
    if ( $line =~ /^\s/ ) {
        $block .= $line;
        if ($found) {
            if ( $line =~ /\b\Q$context\E\b/ ) {
                $clear++;
                $found = 0;
            }
            else {
                ## different context ##
                if ( !grep /\Q$line/, @contexts ) { push @contexts, $line }
                $found = 0;
            }
        }
        elsif ( $line =~ /\b\Q$call\E\b/ ) { $found++; }
        else                                 { $found = 0; }
    }
    else {
        ### NEW BLOCK ###
        if ($clear) {
            print "CLEAR BLOCK:\n$block\n";
            $clear = 0;
            $cleared++;
        }
        else {
            print $NEWLOG $block;
        }
        
       #  if ($block =~/$search/xms) { print "\nBLOCK FOUND:\n$block\n\n" }
        
        $block = $line;
    }
}
if ( !$clear ) { print $NEWLOG $block; }

if ( $context eq '?' ) {
    print "Conflicts found calling $call:\n\n";
    print join "\n", @contexts;
}
elsif ( !$cleared ) { print "No logged conflict calls to $search from $context\n"; exit; }
elsif ($cleared) {
    my $ok = Prompt_Input( -type => 'char', -prompt => "Clear $cleared blocks from log ?" );
    if ( $ok =~ /^y/i ) {
        `mv $log.tmp $log`;
        print "Cleared $cleared usage blocks...\n";
    }
    else {
        print "Aborted\n\n";
    }
}

exit;

