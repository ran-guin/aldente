#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

quick_view.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>

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
use strict;
use Date::Calc qw(Day_of_Week);
use Storable;
use CGI qw(:standard);
use DBI;
use Benchmark;
use Carp;
use CGI::Carp qw(fatalsToBrowser);
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::DBIO;

use alDente::SDB_Defaults;
use RGTools::RGIO;
use SDB::CustomSettings;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($testing $fasta_dir $project_dir);
use vars qw($opt_L $opt_R $opt_P $opt_w $opt_W $opt_S $opt_c);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
require "getopts.pl";
&Getopts('L:R:P:w:W:Sc');

my $host       = 'lims01';
my $dbase      = 'sequence';
my $login_name = 'viewer';
my $login_pass = 'viewer';

my $dbc = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name, -password => $login_pass );
$dbc->connect();

my $storage_dir = $fasta_dir;
my $library     = $opt_L;
my $run         = $opt_R;
my $plate       = $opt_P;
my $line_width  = $opt_w || 50;
my $score_info  = $opt_S || 0;
my $plate_condition;
if ($opt_P) { $plate_condition = "and Plate_Number in ($plate)" }
my $well;
if ($opt_W) { $well = $opt_W; }
else        { print "You must specify which well to view (defaults to A01)\n\n"; $well = 'A01'; }
my $coded = 0;
if ($opt_c) { $coded = 1; }
my @sequence_info;

if ($run) {
    @sequence_info = &Table_find_array( $dbc, 'Run,Equipment,RunBatch', [ 'Run_ID', 'Run_Directory', 'Equipment_Name' ], "where FK_Equipment__ID=Equipment_ID AND FK_RunBatch__ID=RunBatch_ID AND Run_ID in ($run)" );
}
elsif ($library) {
    print "Choose run to view from:\n*********************\n\n";
    @sequence_info = &Table_find_array(
        $dbc,
        'Run,Plate,Equipment,RunBatch',
        [ 'Run_ID', 'Run_Directory', 'Equipment_Name' ],
        "where FK_Equipment__ID=Equipment_ID  AND FK_RunBatch__ID=RunBatch_ID AND Run_Directory like '$library%' and FK_Plate__ID=Plate_ID $plate_condition"
    );
}
my $sequences = 0;
my $id;
my $equip;
foreach my $sequence (@sequence_info) {
    ( $id, my $name, $equip ) = split ',', $sequence;
    unless ( $id =~ /\d+/ ) { next; }
    print "RunID: $id = $name ($equip)\n";
    $sequences++;
}
if ( $sequences == 1 ) {
    my @sequence_info = &Table_find( $dbc, 'Clone_Sequence', 'Run,Quality_Length,Quality_Left,Sequence_Length,Vector_Quality,Vector_Left,Vector_Right,Clone_Sequence_Comments', "where FK_Run__ID = $id and Well = '$well'" );
    ( my $sequence, my $qlength, my $qleft, my $sl, my $vq, my $vl, my $vr, my $comments ) = split ',', $sequence_info[0];
    my $length    = length($sequence);
    my $left_bad  = lc( substr( $sequence, 0, $qleft ) );
    my $insert    = uc( substr( $sequence, $qleft, $qlength ) );
    my $right_bad = lc( substr( $sequence, $qleft + $qlength ) );
    $sequence = $left_bad . $insert . $right_bad;
    print "Length: $sl.  Quality_Length: $qlength\n";
    print " (Vector: ";
    if ( $vl > 0 ) { print "0..$vl "; }
    $sl--;    ### set length to index 1...
    if ( $vr > 0 && $vl < $sl ) { print "$vr..$sl"; }
    print ")\n$comments\n\n";
    print "Machine: $equip\n";
    my @coded_scores;

    if ($score_info) {
        ( my $scores ) = &Table_find_array( $dbc, 'Clone_Sequence', ['Sequence_Scores'], "where FK_Run__ID=$id and Well='$well'" );
        my @phred_scores = unpack "C*", $scores;
        my $code;
        foreach my $this_score (@phred_scores) {
            if ($coded) {
                if ( $this_score > 45 ) { $this_score = 0; $code = 'Z'; }
                elsif ( $this_score >= 20 ) {
                    $this_score -= 20;
                    $code = 'A';
                }
                else { $code = 'a'; }
                while ($this_score) { $code++; $this_score--; }
                push( @coded_scores, $code );
            }
            else {    #### simply zero pad...
                if   ( $this_score < 10 ) { $this_score = '0' . $this_score . ' '; }
                else                      { $this_score = $this_score . ' '; }
                push( @coded_scores, $this_score );
            }
        }
    }
    my $displayed = 0;
    my $printed_sequence;
    my $printed_scores;
    while ( $displayed < $length ) {
        my $left_bad  = $qleft - $displayed;
        my $right_bad = $displayed + $line_width - $qleft - $qlength;
        my $line      = substr( $sequence, $displayed, $line_width );
        $displayed += $line_width;
        $printed_sequence .= $displayed - $line_width . ":  \t$line\n";
        if ($score_info) {
            $printed_scores .= $displayed - $line_width . ":  \t";
            my $index = $displayed - $line_width;
            for ( 1 .. $line_width ) { $printed_scores .= $coded_scores[ $index++ ]; }
            $printed_scores .= "\n";
        }
    }
    print "$printed_sequence \n";
    if ($score_info) {
        if ($coded) {
            print "Scores (0 - 19 => a - t), (20 - 45 => A - Z), (>45 => Z)\n";
            print "*********************************************************\n";
            print "$printed_scores\n";
        }
        else {
            print "Scores:\n";
            print "*********************************************************\n";
            print "$printed_scores\n";
        }
    }
    my $path_info = join ',', &Table_find( $dbc, 'Project,Library,Run,Plate', 'Project_Path,Library_Name,Run_Directory', "where Run_ID = $id and Library_Name = Plate.FK_Library__Name and Plate.Plate_ID = Run.FK_Plate__ID  and FK_Project__ID=Project_ID" );
    ( my $proj_path, my $lib, my $ssdir ) = split ',', $path_info;
    my $file   = "$project_dir/$proj_path/$lib/AnalyzedData/$ssdir/chromat_dir/$ssdir*$well*";
    my $broken = try_system_command("find $file -xtype l");
    if ($broken) {
        print "Broken link(s) found:\n$file\n*******************\n";
        print "(this file is probably compressed)\n";
        print "To attempt to decompress the trace file, use the command:\n\n";
        print "decompress.pl -D $dbase -L $ssdir\n\n";
        print "(NOTE: this must be run as 'sequence')\n\n";
        exit;
    }
    else {
        print "\n...\nTrace viewing command:\nted -ABI $file &\n";
        &try_system_command("ted -ABI $file &");
    }
}
elsif ( $sequences == 0 ) {
    print "No sequences found";
    unless ($opt_L) { &instructions(); }
}
else {
    print "\nThis displays data for only one run at a time.  Choose Run ID.";
    unless ($opt_L) { &instructions(); }
}
print "\n\n";
$dbc->disconnect();
exit;

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

########################
sub instructions {
########################
    #
    #
    #
    #

    {
        print <<HELP

********************************
quick_view.pl  Usage:
********************************
(located in /home/rguin/public)

This program runs from the command line and is intended to provide quick reference to data from specific sequencing run and corresponding to a specific clone.  

It will generate:
a text output of the sequence (showing the 'quality length' region in upper case)
a graphical display of the trace data (using 'ted').

Note:  
The sequence text is generated from phred.
The basepairs displayed with the graph are generated from 'ted' (less sophisticated)

(In some cases these do not correspond exactly - phred results are stored in the database)

Run IDs may be accessed by entering the Library and (optionally the Plate Number) for the Run of interest.

Required (for view)
********************

-R Run_ID  - if not known, try options below to list Run IDs per Library/Plate Number
-W Well    - defaults to 'A01' 

Options
************

-L Library - show run ids from a specific library
-P Plate_Number - show run ids from a specific plate number

-w N - set the number of basepairs displayed per row to N

examples:
************

quick_view.pl -R 1234 -W A04  - displays trace and sequence data for Run 1234.

quick_view.pl -L CN001 - will list all run ids generated for the 'CN001' library.

quick_view.pl -L CN001 -P 5 will list all run ids generated for Plate 5 of the 'CN001' Library.

HELP
    }
    return;
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

$Id: quick_view.pl,v 1.6 2003/11/27 19:37:36 achan Exp $ (Release: $Name:  $)

=cut

