#!/usr/bin/perl
###################################################################################################################################
# TTR.pm
#
# Object that handles functions related to the TTR repository
#
# $Id: TTR.pm,v 1.5 2004/10/12 18:38:47 mariol Exp $
###################################################################################################################################
package Lib_Construction::TTR;       

### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use Data::Dumper;
use Storable;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; 
use lib $FindBin::RealBin . "/../lib/perl/Imported"; 
use XML::Simple;

### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Tube;
use alDente::Barcoding;
use SDB::CustomSettings;
use RGTools::RGIO;

### Global variables
use vars qw($User);
use vars qw($Connection $user $user_id $testing $lab_administrator_email $stock_administrator_email);

### Modular variables
my $DateTime; 

### Constants
my $FONT_COLOUR = 'BLUE'; 
my $ttr_dir = '/home/aldente/private/TTR_files';

###########################
# Constructor
###########################
sub new {
    my $this  = shift;
    my $class  = ref($this) || $this;

    my %args = @_;
    my $dbc = $args{-dbc} || $Connection;

    my $self = {};
    $self->{dbc} = $dbc;

    bless($self,$class);

    return $self;
}

###########################
# Subroutine: updates a flat sample XML with TTR-specific information 
# Return: none
#############################
sub update_XML {
    my $self = shift;
    my $dbc = $self->{dbc};
    my %args = @_;
    my $file = $args{-file};
    
    # read XML
    my $xo = new XML::Simple();
    my $x_struct = $xo->XMLin("$file",KeepRoot=>1);

    my $x_sample_id = $x_struct->{SAMPLE}{ID};
    my $x_type = $x_struct->{SAMPLE}{TYPE};
    my $x_vol = $x_struct->{SAMPLE}{QUANTITY}{content};
    my $x_vol_units = $x_struct->{SAMPLE}{QUANTITY}{units};
    ## need to fill in this information - this will be specific to TTR
    my $x_alias_type = 'TTR';
    my $x_extraction_type = "RNA";
    # determine library type from sample type
    my $x_lib;
    if ($x_type =~ /Normal Tissue/i) {
	$x_lib = 'TTR Normal Tissue';
    }
    elsif ($x_type =~ /Tumour Tissue/i) {
	$x_lib = 'TTR Tumour Tissue';
    }
    elsif ($x_type =~ /Blood/i) {
	$x_lib = 'TTR Blood';
    }
    else {
	return 0;
    }


    my %orig_source;
    my ($label) = $dbc->Table_find("Barcode_Label","Barcode_Label_ID","WHERE Barcode_Label_Name='src_tube'");
    my ($orig_source_id) = $dbc->Table_find("Original_Source","Original_Source_ID","WHERE Original_Source_Name='$x_lib'");
    # build hash for source
    
    $orig_source{TABLE}{Source}{FK_Original_Source__ID} = $orig_source_id;
    $orig_source{TABLE}{Source}{FK_Rack__ID} = 1;
    $orig_source{TABLE}{Source}{FK_Barcode_Label__ID} = $label;
    # need to change to TTR contact
    $orig_source{TABLE}{Source}{FK_Contact__ID} = 27;
    $orig_source{TABLE}{Source}{External_Identifier} = $x_sample_id;
    $orig_source{TABLE}{Source}{Original_Amount} = $x_vol;
    $orig_source{TABLE}{Source}{Amount_Units} = $x_vol_units;
    $orig_source{TABLE}{Source}{Source_Type} = 'RNA_DNA_Source';
    $orig_source{TABLE}{Source}{Source_Status} = 'Active';
    # build hash for RNA_DNA_Source
    $orig_source{TABLE}{RNA_DNA_Source}{Nature} = 'Tissue';

    return \%orig_source;
}

return 1;
