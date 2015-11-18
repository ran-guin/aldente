#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

transfer.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>

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
use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Getopt::Std;
use Data::Dumper;
use Storable;
use RGTools::RGIO;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
our ($opt_d,$opt_t,$opt_m,$opt_R, $opt_s);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
getopts('d:t:mRs:');
###Global variables and command line options;
my $Dir;
my $Target;
my $Move;
my $Recursive;
my $Dir = $opt_d || '';
my $Target = $opt_t || '';
my $Move = $opt_m || 0;
my $temp = $opt_s || '';
my $Recursive = '';
if ($opt_R) { $Recursive = "-r " } 
unless ($Dir && $Target) { 
  print "Require Directory (-d directory) and Target (-t target)\n\n"; 
  print "example :  transfer.pl -d /home/sequence/temp_data -t /home/sequence/mirror (automatically branches to sequencer directories if applicable)\n\n";
  print "(use -s store_dir to store files/directories temporarily rather than removing similar ones)\n\n";
exit; }
&_transfer($Dir,$Target);
print "Done\n";
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

#################
sub _transfer {
#################
#
# check similarities between source and target... 
#
    my $source = shift;
    my $target = shift;
    my $limit = shift || 0;

    my $found = 0;
    my @types = ('f','d');

    foreach my $type (@types) {
      my $command = "find $source -type $type -maxdepth 1";
      print "Check ($type) $source/* : $command..\n";
      my @list = split "\n",try_system_command($command);
      print "Found " . int(@list);
      print "\n**********************************************\n";
      
      foreach my $file (@list) {
	unless ($file) { next }
	my $filename;
	my $branch = '';
	if ($file =~/$source\/(.*)/) { $filename = $1 }
	if ($filename =~/Run_[dD](3700|3730)-(\d+)(.*)/) {
	  unless ($branch=~/$1/) { $branch = "$1/$2/data1/Data" }
	}

	if ($filename && (-e "$target/$branch/$filename")) {
	  ### check if they are the same ###
	  print "*** found $filename ***...\n";
	  my $diff = try_system_command("diff $Recursive $source/$filename $target/$branch/$filename");
	  if ($diff) { 
	    print "$source != $target/$branch/$filename ?\n";
	  } else {
	    print "** $source/$filename = $target/$branch/$filename **\n";

	    if ($temp) { 
	      my $move = "mv $source/$filename $temp";
	      my $ok = try_system_command($move); 
	      print "(moved: $move)\n$ok\n"; 	    
	    }
	    else { 
	      my $ok = try_system_command("rm -fR $source/$filename");
	      print "(removed)\n$ok\n"; 
	    }

	    $found++;
	  }
	  if ($limit && ($found >= $limit)) { return $found } 
	} else { print "$filename NOT in target directory..\n" }
      }
    }
    
    print "Found $found similar files/directories\n";
    return $found;
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

$Id: transfer.pl,v 1.2 2003/11/27 19:37:36 achan Exp $ (Release: $Name:  $)

=cut

