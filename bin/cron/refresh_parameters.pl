#!/usr/local/bin/perl

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";         # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Core/";         # add the local directory to the lib search path
use lib $FindBin::RealBin . "/../lib/perl/Imported/";         # add the local directory to the lib search path

use alDente::Sequencing;
use SDB::DBIO;
use Data::Dumper;
use Getopt::Long;
use RGTools::Process_Monitor;

use vars qw($opt_dbase $opt_host);
&GetOptions(
            'dbase=s'    => \$opt_dbase,
	    'host=s'     => \$opt_host
	   );
my $dbase = $opt_dbase || 'sequence';
my $host = $opt_host || 'lims02';


my $Report = Process_Monitor->new('refresh_paramters Script');


my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>$host,-user=>'viewer',-password=>'viewer',-connect=>1);
$Report->set_Message("Starting initializing parameters");

&alDente::Tools::initialize_parameters($dbc,$dbase);

$Report->set_Message("Completed  initializing parameters");
$Report->completed();
$Report->DESTROY();
exit;
