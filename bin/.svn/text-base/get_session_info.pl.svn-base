#!/usr/local/bin/perl

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

use Data::Dumper;
use Getopt::Long;
use Time::Local;

use RGTools::RGIO;
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::Session;
use vars qw($opt_help $opt_quiet $opt_webhost $opt_version $opt_dbase $opt_start_date $opt_end_date $opt_find $opt_return $opt_print %Configs);

&GetOptions(
    'help'         => \$opt_help,
    'quiet'        => \$opt_quiet,
    'webhost=s'    => \$opt_webhost,
    'version=s'    => \$opt_version,
    'dbase=s'      => \$opt_dbase,
    'start_date=s' => \$opt_start_date,
    'end_date=s'   => \$opt_end_date,
    'find=s'       => \$opt_find,
    'return=s'     => \$opt_return,
    'print=s'      => \$opt_print,        # flag to print out the plain text of the matched blocks
);

my $help       = $opt_help;
my $quiet      = $opt_quiet;
my $webhost    = $opt_webhost || $Configs{PRODUCTION_WEBHOST};
my $version    = $opt_version || $Configs{version_name};
my $dbase      = $opt_dbase || $Configs{PRODUCTION_DATABASE};
my $start_date = $opt_start_date || today();                     # if no start date entered, set it to today
my $end_date   = $opt_end_date || today();                       # if no end date entered, set it to today
my $find       = $opt_find;                                      # semicolon separated name-value pairs
my $return     = $opt_return;
my $print      = $opt_print;

my $localhost = `hostname`;
if ( $localhost =~ /^(\w)\..*/ ) { $localhost = $1 }

## get the search criteria
my @conditions = split ';', $find;
my %conditions;
foreach my $pair (@conditions) {
    if ( $pair =~ /(([^=])+)=(.*)/ ) {
        $conditions{$1} = $3;
    }
}

my @sessions_found;

my @dates;
my $date = $start_date;
while ( $date le $end_date ) {
    push @dates, $date;
    $date = date_time( -date => $date, -offset => '+1d' );
}

#print Dumper \@dates;

foreach my $date (@dates) {
    print "checking date $date ...\n";
    my $files = SDB::Session::get_session_files( -date => $date, -webhost => $webhost, -code_version => $version, -dbase => $dbase );
    print "Got " . @$files . " session files\n";

    ## parse each session file
    foreach my $file (@$files) {    # @$files
        my $blocks_found = SDB::Session::parse_session_file( -file => $file, -conditions => \%conditions );
        if ($blocks_found) {
            push @sessions_found, @$blocks_found;
        }

        ## remove temp file
        if ( $file =~ /$Configs{temp_dir}/ ) {
            print "Please remove temp file $file later!\n";

            #`rm -f $file`;
        }
    }
}

print "\n" . int(@sessions_found) . " Session(s) found:\n";
print SDB::Session::format_sessions( \@sessions_found, -return => $return );
if ( int(@sessions_found) && $print ) {
    open( my $OUT, ">$print" ) || die "Couldn't open $print: $!\n";
    foreach my $sess (@sessions_found) {
        print $OUT "************************************************\n";
        print $OUT "$sess->{block_text}\n";
    }
    close($OUT);
    print "\nMatched session blocks printed to $print\n";
}

