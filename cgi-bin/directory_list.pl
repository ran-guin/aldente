#!/usr/local/bin/perl

use strict;
use CGI qw(:standard);
use CGI::Carp('fatalsToBrowser');

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use lib $FindBin::RealBin;

use Data::Dumper;
use SDB::CustomSettings;
use RGTools::RGIO;

my ($base_directory) = param('base_dir');
my ($file_filter)    = param('file_filter') || '*';

print  "Content-type: text/html\n\n";
print "<html>\n";
print "<head><title>$base_directory</title></head>\n";
print "<body>\n";

# check that the base_directory is valid
if ( ($base_directory !~ /\/home\/aldente\/private\/Projects/) || ($base_directory =~ /\/\.\./) ) {
    print "Sorry, the directory supplied is invalid or not permitted to be viewed via this interface";
    print "<br />";
    print $base_directory;
    print "</BODY></HTML>";
    exit;
}

# get lists of files and directories
my @file_list      = split "\n", `find $base_directory/ -iname  '*$file_filter*' -type f -maxdepth 1 -printf '%f\t%s\n'`;
my @link_list      = split "\n", `find $base_directory/ -ilname '*$file_filter*' -type l -maxdepth 1 -printf '%f\t%s\n'`;

#push @file_list, @link_list;  ## for now, just treat links like files...

my @directory_list = split "\n", `find $base_directory/ -type d -maxdepth 1 -mindepth 1 -printf '%f\n'`;
my @broken_links   = split "\n", `find $base_directory/ -xtype l -maxdepth 1 -printf '%f\n'`;
my $script         = script_name();


print "\n\n<h2>$base_directory</h2>\n";
print "\n";

# start an unordered list
print "<ul>\n";

# display link to parent dir
$base_directory =~ /\A(.*)\/[^\/]*\z/m;
my $parent_directory = $1;

print "    <li><a href=\"$script?base_dir=$parent_directory\" style=\"font-weight:bold\">.. (parent directory)</a></li>";

unless (@file_list || @directory_list || @link_list) {
    print "    <li>\n"
        . "        (empty)\n"
        . "    </li>\n";
}

# for all dir, link to same pop-up, with that dir as the home directory
foreach my $subdir ( sort @directory_list ) {

    my @subdir_file_list  = split "\n", `find $base_directory/$subdir/ -type f -maxdepth 1 -printf '%f\n'`;
    my @subdir_link_list  = split "\n", `find $base_directory/$subdir/ -type l -maxdepth 1 -printf '%f\n'`;
    my @subdir_xlink_list = split "\n", `find $base_directory/$subdir/ -type x -maxdepth 1 -printf '%f\n'`;
    my @subdir_dir_list   = split "\n", `find $base_directory/$subdir/ -type d -maxdepth 1 -mindepth 1 -printf '%f\n'`;

    my $num_files   = scalar @subdir_file_list;
    my $num_links   = scalar @subdir_link_list;
    my $num_subdirs = scalar @subdir_dir_list;
    my $num_xlinks  = scalar @subdir_xlink_list;

    print "    <li>\n"
          . "        <a href=\"$script?base_dir=$base_directory/$subdir\" style=\"font-weight: bold\">$subdir/</a> "
          . "<i>(";
    print "<B>$num_files</B> Files; " if $num_files;
    print "<B>$num_subdirs</B> Directories; " if $num_subdirs;
    print "<B>$num_links</B> Links;" if $num_links;
    print " <B><Font color=red>$num_xlinks Broken links</Font></B>" if $num_xlinks;
    print "empty" if (!$num_files && !$num_subdirs && !$num_links && !$num_xlinks);
    print ")</i>\n"
          . "    </li>\n";
}

#for Solexa htm pages

my @viewable_extensions = qw(htm* txt gif tiff* jpg jpeg png log plt ss params);
my $ext_regexp = join '|', @viewable_extensions;
# for all .htm or .html files, link to another pop-up that displays that file

foreach my $link_info (@link_list) {
    my ($link,$size) = split '\t', $link_info;
    if (-e "$base_directory/$link/") {
	## this link is a directory ... 
	my @link_file_list  = split "\n", `find $base_directory/$link/ -type f -maxdepth 1 -printf '%f\n'`;
	my @link_link_list  = split "\n", `find $base_directory/$link/ -type l -maxdepth 1 -printf '%f\n'`;
	my @link_xlink_list = split "\n", `find $base_directory/$link/ -type x -maxdepth 1 -printf '%f\n'`;
	my @link_dir_list   = split "\n", `find $base_directory/$link/ -type d -maxdepth 1 -mindepth 1 -printf '%f\n'`;
	
	my $num_files   = scalar @link_file_list;
	my $num_links   = scalar @link_link_list;
	my $num_subdirs   = scalar @link_dir_list;
	my $num_xlinks  = scalar @link_xlink_list;
	
	print "    <li>\n"
	    . "        <a href=\"$script?base_dir=$base_directory/$link\" style=\"font-weight: bold\">$link -> (link)</a> "
		. " <i>(";
	
	print "<B>$num_files</B> Files; " if $num_files;
	print "<B>$num_subdirs</B> Directories; " if $num_subdirs;
	print "<B>$num_links</B> Links;" if $num_links;
	print " <B><Font color=red>$num_xlinks Broken links</Font></B>" if $num_xlinks;
	print "empty" if (!$num_files && !$num_subdirs && !$num_links && !$num_xlinks);
	print ")</i>\n"
	    . "    </li>\n";
    } 
    else {
	push @file_list, $link_info;
    }
}

foreach my $file_info ( sort @file_list ) {
    my ($file,$size) = split "\t", $file_info;
    my $sunits = 'bytes';  # size units 
    if ($size > 1000000000) { $size = ($size/10000000)/100; $sunits = 'G'; }
    elsif ($size > 1000000) { $size = int($size/100000)/10; $sunits = 'M'; }
    elsif ($size > 1000) { $size = int($size/100)/10; $sunits = 'K'; }
    
    print "    <li>\n";
    print " " x 8;
    if   ( $file =~ /\A.*\.($ext_regexp)\z/im ) {
	my $tmp_file .= timestamp();
	my $tmp_dir = "dynamic/tmp";
	chdir "$URL_temp_dir";
	try_system_command("rm $file");
	try_system_command("ln -s $base_directory/$file $file");  
	print qq{<a href="$URL_domain/$URL_dir_name/$tmp_dir/$file">$file</a> ($size $sunits)\n;} 
    }
#	    try_system_command("./directory_list.pl -file  )}
    else                                      { print "$file\n";}
    print "    </li>\n";
}

print "</ul>\n";
print "</body>\n</html>";

exit;
