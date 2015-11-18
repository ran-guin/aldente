#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

code_review.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>Allow review of code changes committed to CVS and tide to Issue ID<BR>

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
################################################################################
#
# code_review.pl
#
# Allow review of code changes committed to CVS and tide to Issue ID
#
################################################################################
use strict;
use Getopt::Std;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use SDB::DBIO;
use RGTools::RGIO;
use alDente::Notification;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_I $opt_M $opt_h);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
getopts('I:Mh');
my $Issue_ID = $opt_I if ($opt_I);
my $Me = $opt_M if ($opt_M);
my $Code_Dir = "/opt/alDente/versions/production/";
my $Code_Repository = "/home/cvs/alDente/";
my $Web_Code_Repositiory = "http://gin.bcgsc.ca/cvs/alDente/";
my %Issues;
my $Log;
my %Changes;
my $search_condition = "Status = 'Resolved'";
my $search_log = '';                            ## allow users to search cvs log
my $file;
my $revision;
my $date;
my $email_targets = 'rguin@bcgsc.bc.ca,achan@bcgsc.bc.ca';
my $email_source = 'Code Review <sequence@bcgsc.bc.ca>';
my $dbc = SDB::DBIO->new(-dbase=>'sequence',-host=>'lims02',-user=>'rguin',-connect=>0);

if ($opt_h) {
    _print_help_info();
}
else {
    _main();
}
if ($dbc) { $dbc->disconnect() }
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
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

######################
sub _main {
###################### 

    unless ($Log) {
	chdir $Code_Dir;
	print "loading cvs log...\n";
	$Log = try_system_command("cvs log");
    }
    
    A:  while (1) {
	my $count = 0;
	my $refresh = 0;
        while (!$Issue_ID && !$search_log) { $refresh = _search_issues($refresh) }
	
	%Changes = '';  ## reset list of changes... 
	foreach my $line (split /\n/, $Log) {
	    if ($line =~ /RCS file: $Code_Repository(\S+),v/) {
		$file = $1;
	    }
	    elsif ($line =~ /revision (.*)/) {
		$revision = $1;
	    }
	    elsif ($line =~ /date: (.*);\s+author:/) {
		$date = $1;
	    }
	    elsif ($line =~ /Issue\s*\#\s*$Issue_ID/i) { #These are CVS logs and see if it is the issue id we are interested in
		$count++;
		%Changes->{$count}->{File} = $file;
		%Changes->{$count}->{Revision} = $revision;
		%Changes->{$count}->{Date} = $date;
		%Changes->{$count}->{Log} = $line;
	    } 
	    elsif ($search_log && ($line =~ /$search_log/)) {
		$count++;
		%Changes->{$count}->{File} = $file;
		%Changes->{$count}->{Revision} = $revision;
		%Changes->{$count}->{Date} = $date;
		%Changes->{$count}->{Log} = $line;
	    }
	}
	
	print "\n" . "-"x50 . "\n";
	print " $count changes found for Issue \#$Issue_ID:\n";
	print "-"x50 . "\n";
	print ' '. %Issues->{$Issue_ID}->{Description};
	print "\n" . "-"x50 . "\n";
	print " Assigned Release : " . %Issues->{$Issue_ID}->{Assigned_Release} . "\n";
	print " Assigned To: " . %Issues->{$Issue_ID}->{Assigned_To} . "\n";
	print "-"x50 . "\n";
	if ($count) {
	    print " *** Changes : *** \n";
	    foreach my $change (sort { $a <=> $b } keys %Changes) {
		print "$change) $Changes{$change}{File} (Revision: $Changes{$change}{Revision}; Date: $Changes{$change}{Date})\n";
		print "\t$Changes{$change}{Log})\n";
	    }
	    print "-"x50 . "\n";
	}
	
	print "\n Options:\n\n";
	print " i - view issues again\n";
	print " m - show Messages attached to this issue\n";
	print " n - view next issue\n";
	print " p - view previous issue\n";
	print " q - quit\n\n";
	print " O [comments] -  reOpen this issue (include optional comments)\n";
	print " C [comments] - Close this issue (include optional comments) \n\n";
	if ($count) {
	    print " To View Changes for this issue: \n";
	    print " # U[#] - unified form\n";
	    print " # C[#] - context form (optionally suffix with the number of lines before/after change: eg 2C10)\n";
	    print " # w - generate the URL of the CVS web page in which to view the change\n\n";
	}
	
	my $output;
	while (!$output) {
	    my $choice = Prompt_Input();
	    $output = _parse_choice($choice);
	}
    }
}

##############
sub _parse_choice{
###############
    my $choice = shift;
   
    if ($choice =~ /^(\d+)\s*([A-Za-z]*)(\d*)/ && exists %Changes->{$1}) {
	my $chosen = $1;
	my $option = $2;
	my $param = $3;

	$file = %Changes->{$1}->{File};
	$revision = %Changes->{$1}->{Revision};
	
	my $diff_option;
	my $context_lines = 3;  ## default number of context lines.
	if ($option=~/[uc]/i) { $diff_option = '-' . uc($option); }
	elsif (!$option) { $diff_option = '-U' }

	if (($option=~/[uc]/) && $param) { $context_lines = $param; }
	
	#First find the previous revision.
	my $previous_revision;
	if ($revision =~ /^(\d+)\.(\d+)$/) { #Code in main trunk
	    $previous_revision = "$1." . ($2 - 1); #Just subtract 1 from the last number
	}
	elsif ($revision =~ /(.*)\.(\d+)\.(\d+)$/) { #Code in the branch
	    if ($3 > 1) { #Just subtract 1 from the last number
		$previous_revision = "$1.$2." . ($3 - 1); 
	    }
	    else { #Otherwise just trim the last 2 numbers in the revision to get the previous version.
		$previous_revision = $1;
	    }
	}
	    
	#Now display the diff.
	if ($revision eq '1.1') {
	    print " First revision: No diff.\n";
	}
	elsif ($option =~/w/) { #Display in web interface mode
	    print " Check out this URL to view the difference on the web \n";
	    print "******************************************************\n";
	    print " Diff URL => $Web_Code_Repositiory$file.diff?r1=$previous_revision&r2=$revision\n";
	    print "******************************************************\n";
	}
	else { #Just display in the console
	    my $diff_command = " cvs diff $diff_option $context_lines -r $previous_revision -r $revision $file";
	    print try_system_command($diff_command);
	}
    }
    elsif ($choice =~ /^i/i) {
	$Issue_ID = '';
	$search_log = '';
	return 1;
    }
    elsif ($choice =~/^m\s*(\S+)/i) { 
	_comment_Issue($Issue_ID,$1);
    }
    elsif ($choice =~/^m/i) {
	print " Messages related to Issue $Issue_ID : \n ***********************************************************\n";
	print %Issues->{$Issue_ID}->{Notes} if defined %Issues->{$Issue_ID}->{Notes};
	return 1;
    }
    elsif ($choice =~ /^n/i) {
	$Issue_ID = %Issues->{$Issue_ID}->{Next} if defined %Issues->{$Issue_ID}->{Next};
	return 1;
    }
    elsif ($choice =~ /^p/i) {
	$Issue_ID = %Issues->{$Issue_ID}->{Last} if defined %Issues->{$Issue_ID}->{Last};
	return 1;
    }
    elsif ($choice =~ /^q$/i) { #quit
	exit;
    }
    elsif ($choice =~ /^O\s*(.*)/) {
	print " Re-Open Issue $Issue_ID.";
	_reOpen($Issue_ID,$1);
    }
    elsif ($choice =~ /^C\s*(.*)/) {
	print " Close Issue $Issue_ID.";
	_close_Issue($Issue_ID,$1);
    }
    else {
	print " Invalid choice.\n";
	return;
    }
}

#########################
sub _search_issues {
#########################
    my $refresh = shift;

    my $i = 0;
    if (!$refresh && (defined %Issues)) {
	$i = scalar(keys %Issues);
    }
    else {
        $dbc->connect(); 
	%Issues = {};
	my $condition;
	if ($Me) {
	    $Me = try_system_command("whoami");
#	    my ($me_id) = $Connection->Table_find('Employee','Employee_ID',"where Email_Address = '$Me' or Email_Address = '$Me\@bcgsc.bc.ca'");
	    my ($me_id) = $dbc->Table_find('Employee','Employee_ID',"where Email_Address = '$Me' or Email_Address = '$Me\@bcgsc.bc.ca'");

	    $condition = "where $search_condition and FKAssigned_Employee__ID = $me_id order by Issue_ID";
	}
	else {
	    $condition = "where $search_condition order by Issue_ID";
	}
#	my %info = $Connection->Table_retrieve('Issue',['Issue_ID','Description','Assigned_Release','FKAssigned_Employee__ID'],$condition);
	my %info = $dbc->Table_retrieve('Issue',['Issue_ID','Description','Assigned_Release','FKAssigned_Employee__ID'],$condition);

	while (defined %info->{Issue_ID}[$i]) {
	    my $id = %info->{Issue_ID}[$i];
	    %Issues->{$id}->{Description} = %info->{Description}[$i];
	    %Issues->{$id}->{Assigned_Release} = %info->{Assigned_Release}[$i];
	    %Issues->{$id}->{Assigned_To} = get_FK_info($dbc,'FK_Employee__ID',%info->{FKAssigned_Employee__ID}[$i]);
	    %Issues->{$id}->{Next} =  %info->{Issue_ID}[$i+1] if defined %info->{Issue_ID}[$i+1];
	    %Issues->{$id}->{Last} =  %info->{Issue_ID}[$i-1] if defined %info->{Issue_ID}[$i-1];

	    my @notes = $dbc->Table_find('Issue_Detail','Message',"where FK_Issue__ID=$id");
	    if (@notes) {
		%Issues->{%info->{Issue_ID}[$i]}->{Notes} = join "\n***\n", @notes;
	    }
	    $i++;
	}
    }
    my $choice;
    while (1) {
	print "\n" . "-"x50 . "\n";
	print " $i Issues found ($search_condition):\n";
	print "-"x50 . "\n";
	foreach my $issue (sort {$a <=> $b} keys %Issues) {
	    unless ($issue =~ /^\d+$/) { next }
	    print " $issue\t$Issues{$issue}{Description} ($Issues{$issue}{Assigned_Release})\n";
	}

	$search_log = '';   ## clear any current search request... 

	print "\n Current Issues ($search_condition) \n";
	print "\n" . "-"x50 . "\n";
	print " Options: \n***************\n";
	print "# - choose an issue ID from the list to show info for that issue.\n";
	print "R - get list of Resolved issues. \n";
	print "C - get list of Closed Issues. \n";
	print "O - get list of Open Issues. \n";
	print "I - get list of In Process Issues. \n";
	print "D - get list of Deffered Issues. \n";
	print "\n";
	print "S string - search for the given string among issues\n";
	print "L string - search for the given string in the CVS log (case sensitive)\n";
	print "\nq - quit. \n";
	print "\n" . "-"x50 . "\n";
	$choice = Prompt_Input();
	if (($choice =~ /^(\d+)$/) && (exists %Issues->{$1})) {
	    $Issue_ID = $1;
	    return 0;
	}
	elsif ($choice =~/^o$/i) { unless ($search_condition =~/Open/) { $search_condition = "Status = 'Open'"; return 1;} }
	elsif ($choice =~/^i$/i) { unless ($search_condition =~/In Process/) { $search_condition = "Status = 'In Process'"; return 1;} }
	elsif ($choice =~/^r$/i) { unless ($search_condition =~ /Resolved/) { $search_condition = "Status = 'Resolved'"; return 1;} }
	elsif ($choice =~/^c$/i)  { unless ($search_condition =~ /Closed/) { $search_condition = "Status = 'Closed'"; return 1;} }
	elsif ($choice =~/^d$/i) { unless ($search_condition =~ /Deferred/) { $search_condition = "Status = 'Deferred'"; return 1;} }
	elsif ($choice =~/^s\s*(.*)/i) { $search_condition = "Description like '%$1%'"; return 1; }
	elsif ($choice =~/^l\s*(.*)/i) { $search_log = $1; $search_condition = '1'; $Issue_ID = 0; return 1; }
	elsif ($choice =~ /^q$/i) {
	    exit;
	}
	else {
	    print "Invalid choice.\n";
	}
    }
}

#########
sub _reOpen{
#########
    my $issue = shift;
    my $comment = shift;
    
    my $now = &date_time();
    my $username = `whoami`;
    
    my $ok = $dbc->Table_update_array('Issue',['Status'],['Open'],"where Issue_ID=$Issue_ID",-autoquote=>1);

    if ($comment) {
	my ($user) = $dbc->Table_find('Employee','Employee_ID',"where Email_Address = '$username'");
	unless ($user=~/[1-9]/) { 
	    print "No employee in database with email : $username\n";
	    print "You must relog if you wish to edit the database\n\n";
	    return;
	}
	my @fields = ('FK_Issue__ID','Submitted_DateTime','Message','FKSubmitted_Employee__ID');
	my @values = ($Issue_ID,$now,$comment,$user);
	$dbc->Table_append_array('Issue_Detail',\@fields,
			    \@values,"where Issue_ID=$Issue_ID",-autoquote=>1);
    }
    if ($ok) {
	$dbc->Table_update_array('Issue',['Last_Modified'],[$now],"where Issue_ID=$Issue_ID",-autoquote=>1);
	&alDente::Notification::Email_Notification($email_targets,$email_source,"Re-Opened Issue","Issue $Issue_ID has been Re-Opened\n$comment\n");
#        my $tmp = alDente::Subscription->new(-dbc=>$dbc);
#        $ok = $tmp->send_notification(-name=>"Re-Opened Issue",-from=>$email_source,-subject=>"Re-Opened Issue (from Subscription Module)",-body=>"Issue $Issue_ID has been Re-Opened\n$comment\n",-content_type=>'html',-testing=>1);
    alDente::Subscription::send_notification(-dbc=>$dbc,-name=>"Re-Opened Issue",-from=>$email_source,-subject=>"Re-Opened Issue (from Subscription Module)",-body=>"Issue $Issue_ID has been Re-Opened\n$comment\n",-content_type=>'html',-testing=>1);

	print "reOpened script\n";
    }
    return ;
}

################
sub _comment_Issue{
################
    my $issue = shift;
    my $comment = shift;
    my $now = &date_time();

    if ($comment) {
	my $username = `whoami`;
	my ($user) = $dbc->Table_find('Employee','Employee_ID',"where Email_Address = '$username'");
	unless ($user=~/[1-9]/) { 
	    print "No employee in database with email : $username\n";
	    print "You must relog if you wish to edit the database\n\n";
	    return;
	}
	my @fields = ('FK_Issue__ID','Submitted_DateTime','Message','FKSubmitted_Employee__ID');
	my @values = ($Issue_ID,$now,$comment,$user);
	$dbc->Table_append_array('Issue_Detail',\@fields,
			    \@values,"where Issue_ID=$Issue_ID",-autoquote=>1);
    }
    print "Add comment: $comment.\n";
    return ;
}

#########
sub _close_Issue{
#########
    my $issue = shift;
    my $comment = shift;
    my $now = &date_time();
    my $username = `whoami`;
    
    my $ok = $dbc->Table_update_array('Issue',['Status'],['Closed'],"where Issue_ID=$Issue_ID",-autoquote=>1);

    if ($comment) {
	my ($user) = $dbc->Table_find('Employee','Employee_ID',"where Email_Address = '$username'");
	unless ($user=~/[1-9]/) { 
	    print "No employee in database with email : $username\n";
	    print "You must relog if you wish to edit the database\n\n";
	    return;
	}
	my @fields = ('FK_Issue__ID','Submitted_DateTime','Message','FKSubmitted_Employee__ID');
	my @values = ($Issue_ID,$now,$comment,$user);
	$dbc->Table_append_array('Issue_Detail',\@fields,
			    \@values,"where Issue_ID=$Issue_ID",-autoquote=>1);
    }
    if ($ok) {
	$dbc->Table_update_array('Issue',['Last_Modified'],[$now],"where Issue_ID=$Issue_ID",-autoquote=>1);
	&alDente::Notification::Email_Notification($email_targets,$email_source,"Closed Issue","Issue $Issue_ID has been Closed by $username ($now)\n$comment\n");
	print "close script with comment: $comment.\n";
    }
    
    return ;
}

#########################
sub _print_help_info {
#########################
print<<HELP;

File:  code_review.pl
####################
This script searchs for code changes committed to CVS for a given Issue ID. Note that in order to find code changes for say Issue \#157, the CVS log will need to contain the tag 'Issue #157' when the code is committed.

Options:
##########
1) Issues query options:
-I     Issue ID. 
-M     If included then the query will only return resolved issues assigned to the user who runs this script.
-If both 'I' and 'M' are not provided, then the script will search for all resolved issues.

2) Other options:
-h     Print help info.

Examples:
###########
Search for code changes for Issue \#157:                               code_review.pl -I 157
Search for code changes for resolved issues assigned to me:           code_review.pl -M
Search for code changes for all resolved issues:                      code_review.pl

HELP
}

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

$Id: code_review.pl,v 1.13 2004/06/03 18:12:30 achan Exp $ (Release: $Name:  $)

=cut

