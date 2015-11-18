#!/usr/local/bin/perl

use lib "../lib/perl";
use CGI;
use RGTools::RGIO;
use alDente::Submission;
use SDB::CustomSettings;
use alDente::SDB_Defaults;

use vars qw($testing $homefile $homelink $URL_domain %Defaults);

$homelink = "$URL_address/barcode.pl";

$page = new CGI;

print $page->header;

$page->start_html("Submission Information Retrieval");
print $page->start_form(-action=>"submission_view.pl");

unless ($page->param()) {
    print "<pre>\n";
    print "Submission ID: ",$page->textfield(-name=>"Submission_ID"),"\n";
    print "</pre>\n";
    print $page->submit(-value=>"Get");
    print $page->reset(-value=>"Clear");
}
if ($page->param()) {
    my %vars = $page->Vars;
    my $dbc = SDB::DBIO->new(-dbase=>'seqjsantos',-host=>$Defaults{BACKUP_HOST},-user=>'viewer',-password=>'viewer',-connect=>0);
    $dbc->connect();
    
    my $submission = new Submission(-dbc=>$dbc,-submission_id=>$vars{"Submission_ID"});
    print "<br>";
    $submission->display_full_table();
}

$page->end_form;
$page->end_html;
