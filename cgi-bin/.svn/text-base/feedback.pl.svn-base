#!/usr/local/bin/perl

################################################################################
# $ID$
################################################################################
# CVS Revision: $Revision: 1.4 $
#     CVS Date: $Date: 2004/04/07 02:31:10 $
################################################################################

use CGI qw(:standard);
use DBI;
use Benchmark;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
# include GSC modules #

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::Views;
use RGTools::RGIO;
use RGTools::HTML_Table;

use alDente::Notification;
use alDente::SDB_Defaults;
use alDente::Web;
use SDB::CustomSettings;

use Imported::Barcode;
 
print &alDente::Web::Initialize_page($page);

if (param('Submit Form')) {
    my $target = 'rguin@bcgsc.bc.ca';

    my $msg = "Content-type: text/html\n\n";
    $msg .= "<H2>Feedback Form Submission:</H2>";
    foreach my $name (param()) {
	my $values = join ',', param($name);
	if ($values && $values ne "Don't Use") {	$msg .= "$name = $values<BR>\n";}
    } 
    
    &Email_Notification($target,'aldente@bcgsc.bc.ca','Feedback Form',$msg);
#    print "<BR>Message<BR>$msg";
    Message("Thank you very much for your time");
    exit;
}

my $file = param('Form');
my $type = param('Type') || 'usage';

print &RGTools::Views::Heading("Feedback");
my @help_txt;

my $path = "/opt/alDente/versions/rguin/docs/";
if (-f "$path/$file") {
    @help_txt = split "\n", try_system_command("cat /opt/alDente/versions/rguin/docs/$file");
} else {
    @help_txt = "General feedback form";
}

my $q = new CGI;

print "<Form name='Feedback' action='http://lims02/SDB_rguin/cgi-bin/feedback.pl' Method='POST' enctype='multipart/form-data'>";
#print "<Table width=80% align=center>";
my $Table=HTML_Table->new();
$Table->Set_Width('100%');
$Table->Set_Alignment('Center');
$Table->Set_Title('Topics for Feedback');
$Table->Set_Headers(['Topic','Comments']);

my @options;
if ($type =~ /usage/i) {
    @options = ("Don't Use",'Huh?','Wary','OK','Good','Great');
} elsif ($type =~/value/i) {
    @options = ('Useless','Not Interested','I guess','Useful','Extremely Useful');
} elsif ($type =~/time/i) {
    @options = ('Waste of Time','Time lost exceeds gain','Gain balances time lost','Worthwhile in long term','Huge time savings');
} 


my $list = 0;
my $form = 0;
foreach my $line (@help_txt) {
    if ($form) {
	if ($line=~/^ENDFORM/) {
	    $form = 0;
	    $Table->Printout();
	    next;
	} 	
	unless ($line=~/\S/) {next;}  ### skip blank lines in form.. 
	if ($line=~/Heading:\s*(.*)/) { $Table->Set_sub_header($1,'mediumredbw'); }

	my $topic = $line;
	if ($topic=~/(.*)[<]/) {$topic = $1;}  ### if post-note don't include...
	if ($topic=~/[>](.*)/) {$topic = $1;}  ### if post-note don't include...
	$topic=~s/\n//g;
	$topic=~s/^\s*//g;
	$topic=~s/\s*$//g;

	my $colour;
#	if ($line=~/<UL>/) {$line="<B><Font size=+2>$line</Font></B>";}
	$Table->Set_Row([$line,"LINK<BR>LINK<BR>LINK"]);
	$Table->Set_Link('radio',$topic,\@options,'');
	$Table->Set_Link('box',"COMMENT on $topic",'3x100','');
	$Table->Set_Link('checkbox',"Add Help Button(s) for $topic");
    }
    elsif ($line=~/^FORM/) {
	$form=1;
    }
    else {
	print "$line<BR>";
    }
}
	   
print '<p>'.
    ' Submitted by: '.
    $q->textfield(-name=>"From",-size=>20).
    ' (optional, but helpful if I can come to you for suggestions or clarification)'.
    '<p>';

print "\n<B>General Comments:</B> (feel free to make any other comments you may have below)<P>".
    $q->submit(-name=>'Submit Form',-style=>"background:red"),'<p>'.
    $q->textarea(-name=>"General Comments",-rows=>8,-cols=>100,-wrap=>'virtual'
);


print "</Form>\n";

print &alDente::Web::unInitialize_page($page);

exit;
