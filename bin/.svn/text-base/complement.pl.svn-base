#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

complement.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>perldoc_header             #<BR>superclasses               #<BR>system_variables           #<BR>standard_modules_ref       #<BR>This program generates ACGT complement strings (for files or STDIO)<BR>

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
# complement.pl
#
# This program generates ACGT complement strings (for files or STDIO)
#
################################################################################
################################################################################
# $Id: complement.pl,v 1.4 2003/11/27 19:37:35 achan Exp $
################################################################################
# CVS Revision: $Revision: 1.4 $
#     CVS Date: $Date: 2003/11/27 19:37:35 $
################################################################################
use strict;
use CGI ':standard';
use Shell qw(ls cp mv rm);

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_f $opt_s $opt_n $opt_c $opt_r $opt_h $opt_b);
use vars qw($SFILE $NFILE);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
require "getopts.pl";
&Getopts('f:s:n:crh:b');
my $string;
my $comp;
my $rev;
my $new;
if ($opt_f && $opt_n && ($opt_c || $opt_r)) {}
elsif ($opt_s && ($opt_c || $opt_r)) {}
else {
    print <<END;
complement.pl
################
Usage
########
used to generate ACGT complement files
Switches:
####################################
-c  Complement the given string
AND/OR
-r  Reverse the given string
#####################################
-s (string)
OR 
-f (filename)
-n (new filename)
#####################################
Example:
###########
/home/rguin/Perl/complement.pl -f oldfile.seq -n newfile.seq -c -r
END
    print "\n";
    exit;
}
my $header;
if ($opt_h) {
    $header = $opt_h;
}
my $brief = $opt_b || 0;            ## brief (only results for output)
my $fixed;
my $reverse;
my $complement;
if ($opt_r) {$reverse=1; $fixed .= "Reversed.";}
if ($opt_c) {$complement=1; $fixed .= "Complemented.";}
if ($opt_s) {
    $string = $opt_s;
    if ($complement) {
	print "Complemented...\n" unless $brief;
	$new = complement($string);
    }
    if ($reverse) {
	print "Reversed...\n" unless $brief;
	$new = reverse($new);
    }
    print "Original String:\n$string\n\nNew String:\n" unless $brief;
    print "$new\n";
}
elsif ($opt_f) {
    my $file = $opt_f;
    my $new_file;
    if (!$opt_n) {
	print "must enter new file name!\n\n" unless $brief;
	exit;
    }
    else {$new_file = $opt_n;}
    open(SFILE,"$file") or die "Error opening $SFILE";
    open(NFILE,">$new_file") or die "Error opening $NFILE";
    if ($header) {
	foreach my $h (1..$header) {
	    my $line = <SFILE>;
	    chomp $line;
	    print NFILE "$line ($fixed)\n";
	    print "Printed header line: $line\n"  unless $brief;
	}
    }
    my @lines;
    while (<SFILE>) {
	$string = $_;
	$new=$string;
	if ($complement) {
	    $new = complement($string);
	}
	if ($reverse) {
	    $new = reverse($new);
	}
	push(@lines,$new);
#	print "$new";
    }
    my $num_lines = scalar(@lines);
    if ($num_lines<1) {
	print "No lines found in source file" unless $brief;
	exit;
    }
    foreach my $index (1..$num_lines) {
	print NFILE "$lines[$num_lines-$index]";
    }
    close(NFILE);
    close(SFILE);
    print "Saved to $new_file\n\n" unless $brief;
}
    exit;
######################################
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

######################################

sub complement {
    my $string=shift;
    my $temp = shift || 'Q';
    
    ## swap A <> T ##

    $string=~s/A/$temp/ig;  ## change to temporary character 
    $string=~s/T/A/ig;  ## change to temporary character 
    $string=~s/$temp/T/ig;  ## change to temporary character 
    
    ## swap G <> C ##

    $string=~s/G/$temp/ig;
    $string=~s/C/G/ig;
    $string=~s/$temp/C/ig;
    return $string;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
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

$Id: complement.pl,v 1.4 2003/11/27 19:37:35 achan Exp $ (Release: $Name:  $)

=cut

