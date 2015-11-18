#!/usr/local/bin/perl

use lib "../lib/perl";
use CGI;
use RGTools::RGIO;
use alDente::Collaborator;
use SDB::CustomSettings;
use alDente::SDB_Defaults;

use vars qw($testing $homefile $homelink $URL_domain %Defaults);

$homelink = "$URL_address/barcode.pl";

$page = new CGI;

print $page->header;
$page->start_html("Collaborator Information Retrieval");

unless ($page->param()) {

    print $page->start_form(-action=>"collaborator_view.pl");
    print "<pre>\n";
    print "Contact ID: ",$page->textfield(-name=>"Contact_ID"),"\n";
    print "</pre>\n";
    print $page->submit(-value=>"Get");
    print $page->reset(-value=>"Clear");
    $page->end_form;
}
if ($page->param()) {
    my %vars = $page->Vars;
    my $dbc = SDB::DBIO->new(-dbase=>'seqjsantos',-host=>$Defaults{BACKUP_HOST},-user=>'viewer',-password=>'viewer',-connect=>0);
    $dbc->connect();
    my $collaborator = new Collaborator(-dbc=>$dbc, -contact_id=>$vars{Contact_ID});
    print "<br>";
    $collaborator->get_collaborator_html();
    print "<table>";
    print "<tr valign='top'>";
    print "<td>";
    $collaborator->get_submissions_html();
    print "</td>\n<td>";
    $collaborator->get_projects_html();
    print "</td>";
    print "</tr>";
    print "</table>";
}


$page->end_html;
