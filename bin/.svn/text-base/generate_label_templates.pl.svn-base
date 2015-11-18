#!/usr/local/bin/perl

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use Data::Dumper;

use alDente::Issue;
use alDente::Notification;

use SDB::DBIO;
use SDB::CustomSettings qw($html_header);
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Barcode;

## Get options ##
use vars qw($opt_printer $opt_print $opt_label $opt_help $opt_png $opt_host $opt_dbase $opt_user $opt_password);

use Getopt::Long;
&GetOptions(
	    'printer=s'    => \$opt_printer,
	    'print'        => \$opt_print,
	    'label=s'        => \$opt_label,
	    'help'         => \$opt_help,
	    'h'            => \$opt_help,
	    'png=s'          => \$opt_png,
	    'dbase=s'        => \$opt_dbase,
	    'host=s'         => \$opt_host,
	    'user=s'         => \$opt_user,
	    'password=s'     => \$opt_password    
	);

my $printer    = $opt_printer;
my $print      = $opt_print;
my $label      = $opt_label;
my $help       = $opt_help;
my $png        = $opt_png;
my $dbase      = $opt_dbase || 'seqtest';
my $host       = $opt_host  || 'lims02';
my $user       = $opt_user || 'viewer';
my $password       = $opt_password || 'viewer';

$label =~s /\*/%/;  # allow wildcards #

my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>$host,-user=>'viewer',-password=>'viewer',-connect=>1);
$Connection = $dbc;
unless ($dbc->ping()) { Message("\n** Failed to connect to $dbase on $host **"); exit; }

Message("Connected to $dbase on $host (to change use -dbase <dbase> -host <host> options0");
my $continue = Prompt_Input(-type=>'char',-prompt=>'Continue (Y / N) ?');
unless ($continue =~ /^y/) { print "Aborting\n"; exit; }

my $printer_condition;
$printer_condition .= " AND Printer_Name = '$printer'" if $printer;
$printer_condition .= " AND Barcode_Label_Name like '$label'" if $label;
$printer_condition ||= " AND Printer_Output <> 'OFF'";

my @types = $dbc->Table_find('Barcode_Label,Printer','Barcode_Label_Name,Printer_Name,Printer_DPI',
				    "WHERE Printer.FK_Label_Format__ID=Barcode_Label.FK_Label_Format__ID $printer_condition",-distinct=>1);

unless (@types) { Message("No label types found ($printer_condition)"); }
foreach my $type (@types) {
    my ($label,$printer,$dpi) = split ',', $type;
    Message("**** Generate $label barcode on $printer ($dpi) **** ");
    print '*'x60 . "\n";
    my $barcode = new Barcode(-type=>$label);
    $barcode->establish_printer($printer,$dpi);
    $barcode->set_fields(-sample=>1,('name2'=>$label,'name'=>$label,'solname'=>$label,'ors_name'=>$label) );
    my $zpl = $barcode->make_zpl;
    my $filename = "/opt/alDente/versions/production/template/barcodes/$label.zpl";
    open my $FILE, ">$filename" or Message("Cannot open $label");
    print {$FILE} $zpl;
    close $FILE;
    print $zpl;

    if ($png) {
	my $file = $png;
	$file =~s/<label>/$label/g;
	$barcode->makepng('html',$file);
	print "** Generated $file **\n";
    }

    if ($print) {
	`lpr $filename -P$printer`;
	print " --> sent to $printer\n";
    }
    print "\n" . '*'x60 . "\n";
}
$dbc->disconnect();

exit;

###########
sub help {
###########

    print <<HELP;

Usage:
*********

    generate_barcode_label_template.pl [options]

Mandatory Input:
**************************


Options:
**************************     
    -print              (print sample barcodes)
    -label <label>      (print only this one type of label)
    -printer <printer>  (print only labels applicable to given printer)

Examples:
***********

HELP

}

