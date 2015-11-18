package alDente::ChromatogramHTML;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

ChromatogramHTML.pm - 

=head1 SYNOPSIS

Writes HTML page containing chromatogram viewer.

=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# superclasses               #
##############################

@ISA = qw(Exporter);

##############################
# system_variables           #
##############################
require Exporter;
@EXPORT = qw(ViewChromatogramApplet ViewChromatogramHelpHTML);

##############################
# standard_modules_ref       #
##############################

use strict;
use CGI qw(:cgi);
use DBI;
use lib "/home/martink/export/prod/modules/gscweb";
use gscweb;

##############################
# custom_modules_ref         #
##############################
use alDente::SDB_Defaults qw(:directories);
use SDB::CustomSettings qw($domain);

##############################
# global_vars                #
##############################
# Retrieve web resource paths
our ( $sequence_dbs_URL, $username );
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
$sequence_dbs_URL = "http://www.bcgsc.bc.ca/cgi-bin/intranet/sequence/summary/dbsummary";
$username         = "aldente";                                                              # id of current maintainer
######################
# ViewChromatogramApplet($run_id, $well_id, $width, $height, $applet_only)
#
# Main calling routine
#
# Parameters:
#	$run_id      - identifier for sequence run (natural number)
#	$well_id     - identifier for well in 96-well format plate;
#	                  Format: A01, A02, ..., A12, B01, B02, ..., B12, ......, H01, ..., H12
#	$width       - width of applet (pixels)
#	$height      - height of applet (pixels)
#	$applet_only - flag where header is displayed (0 - full HTML, 1 - applet element only)
1;

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

######################
# ViewChromatogramApplet($run_id, $well_id, $width, $height, $applet_only)
#
# Main calling routine
#
# Parameters:
#	$run_id      - identifier for sequence run (natural number)
#	$well_id     - identifier for well in 96-well format plate;
#	                  Format: A01, A02, ..., A12, B01, B02, ..., B12, ......, H01, ..., H12
#	$width       - width of applet (pixels)
#	$height      - height of applet (pixels)
#	$applet_only - flag where header is displayed (0 - full HTML, 1 - applet element only)

sub ViewChromatogramApplet {
    my $target_window = "MAIN_WINDOW";
    my ( $dbh, $run_id, $well_id, $width, $height, $applet_only ) = @_;
    my $this_script_name = "barcode.pl";
    if ( ValidRunID($run_id) && ValidWellID($well_id) ) {

        my $sequence_path = "/home/aldnete/public/Projects";    ### RG

        $well_id = "\u$well_id";                                # first well character in data-file-name is in uppercase

        my $sql = <<"HereSQL";

SELECT
  Run.FK_Plate__ID,
  Plate.Plate_Created,
  Plate.FK_Library__Name,
  Project.Project_Name,
  Project.Project_Path,
  Run.Run_DateTime,
  Employee.Employee_Name,
  Employee.Email_Address,
  Equipment.Equipment_Name,
  Run_Directory
FROM
  Run,
  RunBatch,
  Employee,
  Equipment,
  Library,
  Plate,
  Project
WHERE
  Run.Run_ID = $run_id
  AND Run.FK_Plate__ID = Plate.Plate_ID
  AND Plate.FK_Library__Name = Library.Library_Name
  AND Library.FK_Project__ID = Project.Project_ID
  AND Run.FK_RunBatch__ID = RunBatch.RunBatch_ID
  AND RunBatch.FK_Employee__ID = Employee.Employee_ID
  AND RunBatch.FK_Equipment__ID = Equipment.Equipment_ID

HereSQL

        # Get related info about chromatogram from Run database:
        #    plate ID, plate creation date, library name, project name, run ID, run date, employee (and email address), sequencer
        my $sth = $dbh->prepare($sql);
        $sth->execute();
        my ( $plate_id, $plate_created, $library_name, $project_name, $proj_path, $sequence_datetime, $employee, $email, $sequencer, $sequence_subdir ) = $sth->fetchrow_array();

        # Added project path to retrieve list... (RG)
        #

        $sth->finish();

        # Get filename
        $_ = "";

        my $lib = substr( $sequence_subdir, 0, 5 );
        my $basepath = "$sequence_path/$proj_path/$lib/AnalyzedData/$sequence_subdir/chromat_dir/";

        if ( defined($sequencer) ) {    # get filespec from sequencer name
            $_ = $sequencer;
            if ( $sequencer =~ /D3700-\d/i ) {
                tr/-D/\//;
                $_ = $mirror . $_ . "/*/Data/Run_*/${sequence_subdir}_${well_id}*.[aA][bB]1";
            }
            elsif ( $sequencer =~ /MB\d/i ) {
                $sequence_subdir =~ /(^[A-Za-z0-9]+)/;
                my $lib_part = $1;
                s/MB//;
                $_ = $mirror . "/mbace/" . $_ . "/*/AnalyzedData/${sequence_subdir}Run*/${lib_part}${well_id}.*.[aA][bB][dD]";
            }
        }

        my @chrom_file = glob("$basepath$sequence_subdir*$well_id*");

        ########## if nothing found try looking for Megabase format (eg 'Lib011aH12.E7.1') ##############3
        if ( $#chrom_file < 0 ) {
            if ( $sequence_subdir =~ /^(.*?)\.(.*)/ ) {
                my $base_subdir = $1;
                my $base_ver    = $2;
                @chrom_file = glob("$basepath$base_subdir$well_id.$base_ver*");
            }
        }

        # XHTML output
        if ( scalar @chrom_file > 0 ) {

            # wipe out $mirror from globbed filespec
            my $chrom_file  = $chrom_file[0];
            my $linked_file = readlink $chrom_file;
            $chrom_file  =~ s|^$sequence_path/||;
            $linked_file =~ s|^$mirror||;
            $linked_file = "$domain/mirror/$linked_file";

            # common text for HTML page
            my $applet_alt = "Java applet showing chromatogram:";
            my $page;
            if ( !$applet_only ) {

                print <<BODY_1;
Content-Type: text/html

<html>
<head>
  <title>Chromatogram: $chrom_file</title>
</head>

<body>
<table width='$width' cellspacing='0' bgcolor='silver' style='font-size: 12px'>
<col width='13%' /><col width='45%' /><col width='4%' /><col width='13%' /><col width='25%' />
<tbody>
<tr><th align='right'>File: </th><td colspan='4'>&nbsp;$chrom_file<BR>->$linked_file</td></tr>
<tr><th align='right'>Project: </th><td>&nbsp;<a href='$sequence_dbs_URL?scope=Project&scopevalue=$project_name' target='$target_window'>$project_name</a></td><td>&nbsp;</td><th align='right'>Plate ID: </th>
<td>&nbsp;<a href='$sequence_dbs_URL?scope=RunID&scopevalue=$run_id&option=bpsummary' target='$target_window'>$plate_id ($sequence_subdir)</a></td></tr>
<tr><th align='right'>Library: </th><td>&nbsp;<a href='$sequence_dbs_URL?scope=Library&scopevalue=$library_name' target='$target_window'>$library_name</a></td><td>&nbsp;</td><th align='right'>Plate date: </th>
<td>&nbsp;$plate_created</td></tr>
<tr><th align='right'>Sequencer: </th><td>&nbsp;<a href='$sequence_dbs_URL?scope=Sequencer&scopevalue=$sequencer' target='$target_window'>$sequencer</a></td><td>&nbsp;</td><th align='right'>Run ID: </th><td>&nbsp;<a href='$sequence_dbs_URL?scope=RunID&scopevalue=$run_id&option=bpsummary' target='$target_window'>$run_id</a></td></tr>
<tr><th align='right'>Employee: </th><td>&nbsp;<a href='mailto:$username\@bcgsc.bc.ca\'>$employee</a></td><td>&nbsp;</td><th align='right'>Run date: </th><td>&nbsp;$sequence_datetime</td></tr></td></tr></tbody></table>
BODY_1
            }

            print <<BODY_2;
<applet id='chromApp' name='chromApp' alt='$applet_alt $chrom_file' width='$width' height='$height'>
  <param name='file' value='$linked_file' valuetype='data' />
  <param name='codebase' value='$domain' />
  <param name='code' value='ChromatogramApplet' />
  <param name='archive' value='ChromatogramViewer.jar' />
$applet_alt $chrom_file.
</applet>
BODY_2

            if ( scalar @chrom_file > 1 ) {
                print "<p>Multiple files found.</p>\n";
                foreach my $f (@chrom_file) {
                    print "$f<br>\n";
                }
            }

            if ( !$applet_only ) {
                print "</body></html>";

                #$page->BottomBar(0);
            }
        }
        elsif ( @chrom_file == 0 ) {
            if ( !$applet_only ) {
                die "Could not find an associated file for this Run_ID and Well combination. ($basepath$sequence_subdir*$well_id*)";
            }
            else {
                print "<p class='larger'><span class='lightredbw'>Error: $this_script_name - Could not find an associated file for this Run_ID and Well combination.</span></p>";
            }
        }
        else {
            if ( !$applet_only ) {
                die "Multiple Files Found";
            }
            else {
                print "<p class='larger'><span class='lightredbw'>Error: $this_script_name - Multiple files found.</span></p>";
            }
        }
    }
    else {
        if ( !$applet_only ) {
            die "Bad Query String Fields. Some or all of the fields have illegal values.";
        }
        else {
            print "<p class='larger'><span class='lightredbw'>Error: $this_script_name - Some or all of the fields have illegal values. Refer to <a href='$this_script_name'>Usage</a>.</span></p>";
        }
    }
}

######################
# ViewChromatogramHelpHTML()
#
# Print help in HTML.
#
# Parameters:
#	(none)

sub ViewChromatogramHelpHTML {

    print <<HTML_USAGE;
Content-Type: text/html

<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'DTD/xhtml1-transitional.dtd'>
<html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' lang='en'>
<head>
<title>WebScript Help - view_chromatogram</title>
<meta http-equiv='Content-Type' content='text/html' />
<style>
body { color: black; background-color: white }
p.invoke { font-size: larger }
div { padding-top: 2em }
span.heading_2 { font-size: 1.5em; font-weight: bolder }
span.heading_3 { font-size: 1.2em }
span.replace_text { color: navy }
table.footer { vertical-align: top; font-size: 0.7em; font-style: italic }
td.footer_right { text-align: right }
</style>
</head>
<body>
<p><img src='http://olweb.bcgsc.bc.ca/intranet/images/WebScriptHelp.png' alt='Logo for WebScript help pages.' width='685' height='80' /></p>
<h1>view_chromatogram</h1>
<table width='100%'>
<col width='80' /><col />
<tbody>
<tr><td>&nbsp;</td>
<td><a href='#synopsis'>Synopsis</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href='#usage'>Usage</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href='#desc'>Description</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href='#example'>Example</a>
<div><span class='heading_2'><a name='synopsis' id='synopsis'>Synopsis</a></span><hr size='1' />
<table width='100%'><col width='60' /><col /><tbody><tr><td>&nbsp;</td><td><p><span class='heading_3'>view_chromatogram</span> - revision 0.3a (17 October 2000)</p><p>Generates an HTML page containing a view of a chromatographic trace from a sequencing experiment along with information about the trace.</p><img src='view_chromatogram_screenshot.png' alt='Screen image of HTML page generated by view_chromatogram.' width='500' height='300' />
</td></tr></tbody></table>
</div>

<div><span class='heading_2'><a name='usage' id='usage'>Usage</a></span><hr size='1' />

<table width='100%'><col width='60' /><col /><tbody><tr><td>&nbsp;</td><td>
<span class='heading_3'>view_chromatogram?file=<span class='replace_text'>path</span>&start=<span class='replace_text'>integer</span>&width=<span class='replace_text'>pixels</span>&height=<span class='replace_text'>pixels</span></td></tr>
<tr><td>&nbsp;</td><td>where the query string fields are:</td></tr>
<table width='100%'><col width='20' /><col width='25%' /><col /><tbody>
<tr valign='top'><td>&nbsp;</td><td>file=<span class='replace_text'>path</span></td><td>Path of file.</td></tr>
<tr valign='top'><td>&nbsp;</td><td>start=<span class='replace_text'>integer</span></td><td>Non-negative integer representing the starting position of peak (base pair) to view (index begins with [default = 0]).</td></tr>
<tr valign='top'><td>&nbsp;</td><td>width=<span class='replace_text'>pixels</span></td><td>Width of applet in pixels [default = 500].</td></tr>
<tr valign='top'><td>&nbsp;</td><td>height=<span class='replace_text'>pixels</span></td><td>height of applet in pixels [default = 300].</td></tr>
</tbody></table>
</td></tr></tbody></table>
</div>

<div><span class='heading_2'><a name='desc' id='desc'>Description</a></span><hr size='1' />
<table width='100%'><col width='60' /><col /><tbody><tr><td>&nbsp;</td><td><p>Generates an HTML page containing a java applet for viewing chromatographic traces.</p>
<p>hello</p>
</td></tr></tbody></table>
</div>
<div><span class='heading_2'><a name='example' id='example'>Example</a></span><hr size='1' />
<table width='100%'><col width='60' /><col /><tbody><tr><td>&nbsp;</td><td><p>Generates an HTML page containing a java applet for viewing chromatographic traces.</p>
<p>hello</p>
</td></tr></tbody></table>
</div>
<div>
<hr size='2' />
<table class='footer' width='100%'>
<col /><col />
<tbody><tr>
<td>&copy; 2000, <a href='http://www.bcgsc.bc.ca'>B.C. Genome Sciences Centre</a>.</td><td class='footer_right'>Maintained by: $username (<a href='mailto:$username\@bcgsc.bc.ca'>$username\@bcgsc.bc.ca</a>). Last modified: 16 October 2000.</td></tr></tbody></table>
</div>
</td>
</tr>
</tbody>
</table>
</body>
</html> 
HTML_USAGE

}

######################
#
# Private Subroutines
#

######################
# ValidRunID($run_id)
#
# Checks to see if the identifier for a sequencing experiment is valid.
# Valid values are any positive integer.
#
# Parameters:
#	$run_id - sequence run identifier to be checked (integer).

sub ValidRunID {

    return ( $_[0] =~ /^\d+$/ );
}

######################
# ValidWellID($well_id)
#
# Checks to see if the identifier for a well in a 96-well plate is valid.
# Valid well format is string of pattern: 'A01'...'A12', 'B01'...'B12, 'C01'...'G12', 'H01'...'H12'
#
# Parameters:
#	$well_id - well identifier to be checked (string).

sub ValidWellID {

    return ( $_[0] =~ /[A-Pa-p](\d\d)/ && $1 >= 1 && $1 <= 24 );
}

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

$Id: ChromatogramHTML.pm,v 1.3 2003/11/27 19:42:49 achan Exp $ (Release: $Name:  $)

=cut

return 1;
