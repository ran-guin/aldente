#!/usr/local/bin/perl

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";         # add the local directory to the lib search path

use RGTools::RGIO;

use vars qw($opt_help $opt_quiet);

use Getopt::Long;
&GetOptions(
	    'help'                  => \$opt_help,
	    'quiet'                 => \$opt_quiet,
	    ## 'parameter_with_value=s' => \$opt_p1,
	    ## 'parameter_as_flag'      => \$opt_p2,
	    );

my $help  = $opt_help;
my $quiet = $opt_quiet;

my $host = 'limsdev02';
#my $dbase = 'alDente_unit_test_DB';
my $dbase = 'seqdev';
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


exit;

#############
sub help {
#############

    print <<HELP;

Usage:
*********

    <script> [options]

Mandatory Input:
**************************

Options:
**************************     


Examples:
***********

HELP

}
