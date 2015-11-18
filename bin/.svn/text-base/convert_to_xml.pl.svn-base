#!/usr/local/bin/perl

use strict;
use DBI;
use Carp;
use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use RGTools::Conversion;

use vars qw($opt_help $opt_quiet $opt_file $opt_xml $opt_type $opt_chapter $opt_section $opt_position $opt_title $opt_debug);

use Getopt::Long;
&GetOptions(
	    'help'                  => \$opt_help,
	    'quiet'                 => \$opt_quiet,
 	    'file=s'                  => \$opt_file,
	    'xml=s'                   => \$opt_xml,
	    'type=s'                  => \$opt_type,
	    'chapter=s'               => \$opt_chapter,
	    'section=s'               => \$opt_section,
	    'position=s'              => \$opt_position,
	    'title=s'                 => \$opt_title,
	    'debug'                   => \$opt_debug,
	    ## 'parameter_with_value=s' => \$opt_p1,
	    ## 'parameter_as_flag'      => \$opt_p2,
	    );

my $help  = $opt_help;
my $quiet = $opt_quiet;
my $debug = $opt_debug;
    
my $file = $opt_file;         ## file file
my $xml  = $opt_xml;          ## xml target file
my $type = $opt_type;         ## file type (wiki or html)
my $chapter = $opt_chapter;     ## chapter to add this to 
my $section = $opt_section;     ## section to add this to 
my $position = $opt_position;   ## position in section / chapter / file (eg top or bottom)
my $title    = $opt_title;      ## title of new section

my $xml_mind = 1;  ## flag to indicate conversion to xml_mind format 

unless ($file) { help(); exit; }

open my $XML, "$xml"  or carp "Cannot open '$xml' (creating file)";

#`cp $xml $xml.bak` or die "Cannot make backup $xml file";

my $file_text = `cat $file`;
 
my $config = {
    ## xml mind configuration ##
    'b'       => 'emphasis',
    'h'       => 'title',
    'li'      => 'listitem',
    'ul'      => 'itemizedlist',
    'ol'      => 'orderedlist',
    'img' => 'graphic fileref',
    'ref'  => 'ulink url',
    'table'   => 'table',
    'tr'      => 'row',
    'td'      => 'entry',
    'u'       => 'underline',
    'i'       => 'italics',
};

my $chapter_tag = 'chapter';
my $section_tag = 'section';
my $title_tag   = 'title';

my $xml_text;
$title ||= $file;
if ($type =~ /wiki/) {
    $xml_text = RGTools::Conversion::wiki_to_xml($file_text,$config,-quiet=>1,-xml_mind=>$xml_mind);
    
    if ($xml_mind) {
	$xml_text = add_para_tags($xml_text, $debug);
    }
    if ($debug) {
	print "XML:\n****\n$xml_text\n****\n";
	exit;
    }
} 
elsif ($type =~ /html/) {
    $xml_text = RGTools::Conversion::HTML_to_xml($file_text,$config,'quiet');
} 
else {
    Message("Please define type ('-type xml' or '-type html')");
    help();
}

$xml_text = "<section>\n\t<title>$title</title>\n$xml_text\n</section>\n";

my ($added, $add_to_section, $add_to_chapter) = (0,0,0);
my (@chapters, @sections, $this_chapter, $this_section);
my ($line, $lastline);
my (@lines,$xml_lines);

print "\n";
while (<$XML>) {
    $lastline = $line;
    $line = $_;
    
    if ( ($lastline =~/<$chapter_tag>/i) && ($line =~/<$title_tag>(.*?)<\/$title_tag>/) ) {
	push @chapters, $1;
	$this_chapter = shift @chapters; 
	print "*"x40 . "\n**  Found $this_chapter Chapter\n" . "*"x40 . "\n"  if $chapter eq $this_chapter; 
    }
    elsif ( ($lastline =~/<$section_tag>/i) && ($line =~/<$title_tag>(.*?)<\/$title_tag>/) ) {
	push @sections, $1;
	$this_section = shift @sections; 
	print "** Found $this_section Section **\n\n" if $section eq $this_section;
    }
    elsif ($line =~ /<\/$section_tag>/) { 
	$this_section = shift @sections;
	if ($add_to_section && $position eq 'bottom') {
	    unless ($added) {
		push @lines, $xml_text;
		push @lines, $line;
		$add_to_section = 0;
		$added++;
		print "-----> Added at line $xml_lines before section close:\n";
		chomp $line;
		print "'$line'\n";
		$line = '';
	    }	
	}
    }
    elsif ($line =~ /<\/$chapter_tag>/) { 
	$this_chapter = shift @chapters;
	if ($add_to_chapter && $position eq 'bottom') {
	    unless ($added) {
		push @lines, $xml_text; 
		push @lines, $line;
		$add_to_chapter = 0;
		$added++;
		print "------> Added at line $xml_lines before chapter close:\n";
		chomp $line;
		print "'$line'\n";
		$line = '';  ## cleared since it is added ABOVE xml text .. 
	    }
	}
    }
    
    if (!$section && $chapter && ($chapter eq $this_chapter) ) {
	$add_to_chapter = 1;
    } 
    elsif ($section && ($this_section eq $section) && !$chapter) {
	$add_to_section = 1;
    }
    elsif ( $chapter && $section && ($this_section eq $section) && ($this_chapter eq $chapter) ) {
	$add_to_section = 1;
    } 
    
    push @lines, $line;
    if (($add_to_section || $add_to_chapter) && $position eq 'top') {
	unless ($added) {
	    push @lines, $xml_text ;
	    $add_to_chapter = 0;
	    $add_to_section = 0;
	    $added++;
	    print "-> Added at line $xml_lines at the top of the chapter/section:\n";
	    chomp $line;
	    print "'$line'\n";
	}
    }
    $xml_lines++;
}
close $XML;

open my $TARGET, ">$xml.plus" or die "Cannot open $xml.plus";

if (!$xml_lines) {   ## empty xml file ###
    print $TARGET "<xml>\n$xml_text\</xml>";
} 
else {
    print $TARGET join "", @lines;
}
close $TARGET;

my $new_lines = int( split "\n", $xml_text );
print "*"x40;
#print $file_text;
print "\n";
print "-> adding $new_lines lines to original $xml_lines:\n";
print "*"x40;
print "\n";
print "$xml_text\n";
print "* EOF *\n";
print "*"x40;
print "\n\n";

print "Notes:\n*************\n";
unless ($xml && ($chapter || $section)) { print "- Not inserted.  (ONLY inserted if chapter and/or section specified along with xml target)\n"; }
unless ($type) { print "- You did not specify an input file type (HTML or wiki) eg -type wiki\n\n" }

exit;

#######################
sub add_para_tags {
#######################
    my $xml_text = shift;
    my $debug    = shift;
    
    my @bracket_options = qw(orderedlist itemizedlist section chapter);  ## force para tags between these tags ##
    my $options = join '|<', @bracket_options;
    my $end_options = join "|</", @bracket_options;

    print "\n*** Add para tags after bracket options close ***\n" if $debug;
    my $para_count = 0;
    my ($tag1, $para, $tag2);
    while ( ($xml_text =~ /(<\/$end_options)>\s*(\S.*?)(<$options|<\/$end_options)/s) && (($tag1,$para,$tag2) = ($1,$2,$3)) && ($para !~ /(<\/$end_options|<$options|<para)/) ) {
	$xml_text =~s/$tag1>\s*$para$tag2/$tag1>\n<para>\n$para\n<\/para>\n$tag2/s;
	print "bracketed:\n***\n$para ($tag1 -> $tag2)\n***\n" if $debug;
	if ($para_count++ > 10) { last };
    }
    
    print "\n*** Add para tags to lineitems ***\n" if $debug;
    my $li_count = 0;
    while ($xml_text =~s/<listitem>\s*([a-zA-Z0-9].*?)(<$options|<\/listitem)/<listitem>\n<para>\n$1<\/para>\n$2/s) {
	print "bracketed list item:\n***\n$1 ($2)\n***\n" if $debug;
	$li_count++;
    }
    print "\n*******\n" if $debug;
    return $xml_text;
}

#############
sub help {
#############

    print <<HELP;

convert_to_xml   : script used to easily convert wiki text or html text into configured xml format (default settings are for xml mind tags)

Usage:
*********

    convert_to_xml -file input_file.txt -xml limshelp.xml -chapter 'Lab Tracking' [options]

Mandatory Input:
**************************
    -file  name of file;
    -xml   name of xml file to write/append to;

Options:
**************************     
    -chapter    chapter in which this section goes (MANDATORY IF there is more than one chapter found);
    -section    section in which this section should be inserted;
    -position   position in section / chapter ('top' or 'bottom');
    -title      title of new section (defaults to name of input file)


** tag customization options below are not yet supported, but will be shortly **

** (for now the tags below default to the tags used in the xml mind template as indicated below - or html)  **

    -b          set bold tag <emphasis>
    -u          set underline tag <underline>
    -i          set italics tag <italics>
    -li         set line item tag <lineitem>
    -ol         set ordered list tag <orderedlist>
    -ul         set unordered list tag <unorderedlist>
    -ref        set ref tag <ulink url>
    -img        set img tag <graphic ref>
    -table      set table tag <table>  ** Note requires special customization, since xml mind has extra tags ** 
    -tr         set table row tag <row>
    -td         set table column tag <entry>

Examples:
***********

>convert_to_xml -file file.txt -xml limshelp.xml -chapter 'Lab Tracking' -type wiki

>convert_to_xml -file wiki_file.txt -xml limshelp.xml -chapter 'Lab Tracking' -section 'Primary Events Tracked' -position bottom -title 'New Title' -type html

NOTE: Run first to check output and position in file before overwriting original xml file.

HELP

}
