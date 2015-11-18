#!/usr/local/bin/perl
###################################################################################################################################
# project_view.pl
#
# Wrapper script to display project statistics (all of the work is done in Project.pm)
#
# $Id: project_view.pl,v 1.2 2003/11/28 20:35:07 rguin Exp $
###################################################################################################################################
use lib "../lib/perl";
use strict;

### Reference to standard Perl modules
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use MIME::Base32;
use Storable qw(thaw);

### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Project;
use alDente::Web;
use SDB::CustomSettings;

### Global variables
use vars qw($testing $homefile $URL_domain $html_header %Defaults);

$page = new CGI;

alDente::Web::Initialize_page();

$page->start_html("Project Information Retrieval");

print $page->start_form(-action=>"project_view.pl");

unless ($page->param()) {
    print "<pre>\n";
    print "Project ID: ",$page->textfield(-name=>"Project_ID"),"\n";
    print "</pre>\n";
    print $page->submit(-value=>"Get");
    print $page->reset(-value=>"Clear");
}
if ($page->param()) {
    my %vars = $page->Vars;
    my $project_id;
    if ($vars{"args"}) {
	my %args = %{thaw(MIME::Base32::decode($vars{"args"}))};
	$project_id = $args{"Project_ID"};
    }
    else {
	$project_id = $vars{"Project_ID"};
    }
    my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>$Defaults{BACKUP_HOST},-user=>'viewer',-password=>'viewer',-connect=>0);
    $dbc->connect();
    
    my $project = new Project(-dbc=>$dbc, -project_id=>$project_id);
    $project->get_project_stats();
}

alDente::Web::unInitialize_page();
