#!/usr/bin/perl
###################################################################################################################################
# Sample_Receiving.pm
#
# Object that handles functions related to sample receiving
###################################################################################################################################
package Lib_Construction::Sample_Receiving;       

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
use Lib_Construction::TTR;

### Global variables
use vars qw($User);
use vars qw($Connection $user $user_id $testing $lab_administrator_email $stock_administrator_email);
use vars qw($sample_files_dir);

### Modular variables
my $DateTime; 

### Constants
my $FONT_COLOUR = 'BLUE'; 
#my $ttr_dir = '/home/aldente/private/sample_files';
my $ttr_dir = $sample_files_dir;

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
# Subroutine: Receive a sample. 
# Return: none
###########################
sub receive_sample {
    my $self = shift;
    my %args = @_;
    my $sample_id = $args{-sample_id};
    my $dbc = $self->{dbc};

    ### check if the source can be received

    # check if the source has been received already (look up Source table)
    my @source_id = $dbc->Table_find("Source,Original_Source","Source_ID","WHERE FK_Original_Source__ID=Source_ID AND External_Identifier='$sample_id' AND Original_Source_Name like '%TTR%'");
    unless (scalar(@source_id) == 0) {
	# sample has been received already, return
	Message("Error: Sample has already been received");
	return;
    }
    
    # check if the sample exists in the TTR 'in waiting' samples. If it does, read the
    # file and receive it. Otherwise, return an error
    unless ( (-e "$ttr_dir/$sample_id.xml") && (-r "$ttr_dir/$sample_id.xml") ) {
	Message("Error: Sample source file cannot be found.");
	return;
    } 

    # process and rewrite XML file
    my $ttro = new TTR(-dbc=>$dbc);
    my $insert_hash = $ttro->update_XML(-file=>"$ttr_dir/$sample_id.xml");
    
    # get source data
    my @source_fields = keys %{$insert_hash->{TABLE}{Source}};
    my @source_values = ();
    foreach my $field (@source_fields) {
	push (@source_values,$insert_hash->{TABLE}{Source}{$field});
    }
    ### put in transaction
    my $transaction = new SDB::Transaction(-dbc=>$dbc);

    $transaction->start();
    my $source_id = 0;
    eval {
	# insert source
	$source_id = $dbc->Table_append_array("Source",\@source_fields,\@source_values);
	# get RNA_DNA_Source data
	my @tissue_fields = keys %{$insert_hash->{TABLE}{RNA_DNA_Source}};
	my @tissue_values = ();
	foreach my $field (@tissue_fields) {
	    push (@tissue_values,$insert_hash->{TABLE}{RNA_DNA_Source}{$field});
	}
	# locate FK_Source__ID
	push (@tissue_fields,"FK_Source__ID");
	push (@tissue_values,$source_id);
	# insert RNA_DNA_Source 
	my $ok = $dbc->Table_append_array("RNA_DNA_Source",\@tissue_fields,\@tissue_values);
    };
    if ($transaction && $transaction->started()) {
	$transaction->finish($@);
    }

    if ($transaction->error()) {
	Message("Transaction failed in inserting Source/RNA_DNA_Source. Contact a LIMS admin.");
	Call_Stack();
    }
    # print Source barcode
    if ($source_id) {&alDente::Barcoding::PrintBarcode($dbc,'Source',$source_id)}
}

return 1;
