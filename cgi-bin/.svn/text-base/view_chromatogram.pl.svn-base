#!/usr/local/bin/perl

########################################################################
#
#  Genome Run Center Web Script
#
#
#  view_chromatogram                                            Oliver
#
#
### Description
#
#  Perl script that creates a web page containing a Java applet that
#  displays raw chromatographic traces stored in AB1 or SCF formats.
#
#  The applet files are currently located at
#	http://olweb.bcgsc.bc.ca/intranet/common/applets/Chrom_Applet/
#
#  This page is ideally created as a simple pop-up window by the
#  referring web page (see example below).
#
#
### History
#
#    v0.10a		11 October 2000
#    v0.11a		13 October 2000
#
#
### Usage
#
#   http://olweb.bcgsc.bc.ca/cgi-bin/intranet/common/chrom_applet.pl?file={FILESPEC}&start={INTEGER}&height={PIXELS}&width={PIXELS}
#
#
#   Description of key/value pairs:
#
#	runid={INTEGER}  The run sequence identifier
#			 This key is MANDATORY!
#	well={grid}	 The well position.
#			 This key is MANDATORY!
#	start={INTEGER}  Chromatogram position to start viewing (i.e., by
#			 specifying a nucleotide sequence position, value must
#			 be positive; a value of '0' means first position)
#			 [default is 0]
#	height={PIXELS}  Applet height in pixels [default is 300]
#	width={PIXELS}   Applet width in pixels [default is 500]
#
#   Omit the query string (everything after '?') to get a brief help page.
#
#
#   Example invocation:
#
#	http://olweb.bcgsc.bc.ca/cgi-bin/intranet/view_chromatogram?runid=250&well=A01&start=0&height=333&width=666
#
#
#   Example code on referring page to create simple pop-up window:
#
#   <head>
#   ...
#   <script type="text/javascript" language="javascript1.2">
#	<!-- begin hide script from old browsers
#	function OpenChromTraceWindow(run_ID, well_ID, start_pos, width, height) {
#		// ensure appropriate applet size (use defaults if inappropriate);
#		// browser window will be scaled accordingly
#		if (width < 100) {
#			width = 500;
#		}
#		if (height < 100) {
#			height = 300;
#		}
#		// Note: Remove the backslashes in your real code
#		var popup = window.open("http://olweb.bcgsc.bc.ca/cgi-bin/intranet/chrom_applet.pl?file="+trace_file+\
#               "&atpos="+start_pos+"&width="+width+"&height="+height, "ChromTraceWindow",\
#		"width="+(width+2)+",height="+(height+2)+",status=no,resizable=yes,toolbar=no,scrollbar=no");
#	}
#	//   end hide script from old browsers -->
#   </script>
#   ...
#   </head>
#   <body>
#   ...
#   <a href="javascript:void OpenChromTraceWindow('MyDirectory/TraceFile.ab1',0,600,250)">View Trace</a>
#   ...
#   </body>
#
#   This javascript function is available in the file chrom_applet.js located
#   in the same URL as the Chromatogram applet. To create a link on your web page to
#   it, please see
#         http://www.bcgsc.bc.ca/intranet/web/templates.shtml#js
#
########################################################################

#######################################################################################
## Standard Template for building cron jobs or scripts that connect to the database ###
#######################################################################################
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Departments";
use lib $FindBin::RealBin . "/../lib/perl/LampLite";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin . "/../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../lib/perl/Experiment";

########################
## Local Core modules ##
########################
use CGI ":cgi";
use Data::Dumper;
use Benchmark;
use strict;

##########################
## Local custom modules ##
##########################
use RGTools::RGIO;
use RGTools::Process_Monitor;
use LampLite::Bootstrap;

use SDB::DBIO;    ## use to connect to database
use alDente::ChromatogramHTML;
use alDente::Config;    ## use to initialize configuration settings

## Globals ##
my $q               = new CGI;
my $BS              = new Bootstrap();
my $start_benchmark = new Benchmark();

$| = 1;                 # flush STDOUT
##############################################################
## Temporary - phase out globals gradually as defined below ##
##############################################################
use vars qw(%Configs);  ### phase out global, but leave in for now .... replace with $dbc->config() ... need to also expand config list as done in SDB/Custom_Settings currently...
###############################################################

####################################################################################################
###  Configuration Loading - use this block (and section above) for both bin and cgi-bin files   ###
####################################################################################################
my $Setup = new alDente::Config( -initialize => 1, -root => $FindBin::RealBin . '/..' );

my $configs = $Setup->{configs};

%Configs = $configs;    ## phase out global, but leave in for now ....
###################################################
## END OF Standard Module Initialization Section ##
###################################################

# Process parameters
my $run_id;
my $well_id;
my $start       = 0;
my $width       = 500;
my $height      = 300;
my $applet_only = 0;
my $dbase       = param("dbase");
my $host        = param("host");
my $login_name  = "viewer";
my $login_pass  = "viewer";

my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -password => $login_pass, -connect => 0, -config => $configs );
$dbc->connect();

#my $dbc = DB_Connect(dbase=>"sequence",user=>'viewer',password=>'viewer');

# Main processing block
if ( defined( $run_id = param("runid") ) && defined( $well_id = param("well") ) ) {

    # Set these to defaults if bad values specified in script
    if ( defined( $_ = param("width") ) && $_ > 500 ) {
        $width = $_;
    }
    if ( defined( $_ = param("height") ) && $_ > 300 ) {
        $height = $_;
    }

    ViewChromatogramApplet( $dbc, $run_id, $well_id, $width, $height, $applet_only );
}
else {
    ViewChromatogramHelpHTML();
}

if ($dbc) { $dbc->disconnect(); }

exit;
