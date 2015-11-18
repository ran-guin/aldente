#!/usr/local/bin/perl 
#############################################################
# index.pl
#############################################################
#
#  This file generates a documented listing of routines showing input parameters 
#  and general comments as they appear in the actual code.
#
#
#############################################################

use CGI ':standard';

use strict;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::Code;

use SDB::CustomSettings;
use SDB::HTML;

use alDente::Tools;

use vars qw($opt_i $opt_d $opt_f $opt_b $opt_m $opt_p $opt_s $opt_o $opt_l $opt_a);
use vars qw($THISFILE $INDEXFILE $URL_temp_dir $URL_dir_name $URL_home);

require "getopts.pl";
&Getopts('f:d:s:bm:p:s:o:la:');

########### Options ##############

my $timestamp = localtime();
my $default_path = $FindBin::RealBin . "/../";
my $default_dir = 'lib/perl/Core/SDB';
my $default_out = "$URL_temp_dir";

my $filename = $opt_f; ##  || "search.$timestamp";
my $dir = $opt_d || $default_dir;
my $search = $opt_s || '';
my $break = $opt_b || '<BR>';
my $modules = $opt_m || '';
my $path = $opt_p || $default_path;
my $search_area = $opt_a || 'routine';

my $quiet = 1;

unless ($modules) { 
    print<<HELP;

File: index
#####################

Options:
##########


-f (filename)         output filename  

-d (directory)        specify specific directory within path (defaults to $default_dir)

-s (searchstring)     string to search for within modules

-m (list or 'ALL')    modules to search for (comma-delimeted)

-p (path)             path where files are found (defaults to $default_path)

-o (path)             storagepath for html files (defaults to $default_out)


Example:  
###########
           /home/sequence/SeqDB/cgi-bin/backup_DB -D sequence -T Plate 


HELP
    exit;
}

#
# Establish the list of modules to be searched.
#
my  @index_list = glob("$path/$dir/*");

my @new_index_list;
if ($modules eq 'ALL') { 
    @index_list = glob("$path/$dir/*");
    foreach my $module (@index_list) {
	if ($module=~/(.*)\/(.*?)\.(pm|pl)$/) { push(@new_index_list,"$2.$3"); }
    }
    @index_list = @new_index_list;
    print "Indexing ALL Modules\n" unless $quiet;
}
else {
    my @module_list = split ',', $modules;
    foreach my $module (@module_list) {
	if (grep /\/$module\.pm$/, @index_list) {
	    push(@new_index_list,"$module.pm");
	} elsif (grep /\/$module\.pl$/, @index_list) {
	    push(@new_index_list,"$module.pl");
	} else { print "$module NOT found\n"; }
    }
    @index_list = @new_index_list;
}

unless ($quiet) {
    print "Indexing: \n";
    print join "\n", @index_list;
    print "\n\n";
    print "generate: $path/$dir ($filename) page\n";
}

print generate_man_page(file_list => \@index_list);

exit;

############################
sub generate_man_page {
############################
    my %args = @_;
    
    my @index_list = @{$args{'file_list'}};

    my $page;
    foreach my $file (@index_list) {   ### for each file/module... 
      $page .= alDente::Tools::search_code(
				  path => "$path/$dir",
				  filename => $file,
				  search => $search,
				  output => $filename,
				  search_area => $search_area,
				  module => $search,
				  );
    }
    return $page;
}
