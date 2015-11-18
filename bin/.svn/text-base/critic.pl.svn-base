#!/usr/local/bin/perl

use strict;
use DBI;

use vars qw($opt_help $opt_quiet $opt_severity $opt_file $opt_verbose);

use Data::Dumper;
use Getopt::Long;
&GetOptions(
	    'help'                  => \$opt_help,
	    'quiet'                 => \$opt_quiet,
        'severity=s'            => \$opt_severity,
        'file=s'                => \$opt_file,
        'verbose=s'             => \$opt_verbose,
## 'parameter_with_value=s' => \$opt_p1,
	    ## 'parameter_as_flag'      => \$opt_p2,
	    );

my $help  = $opt_help;
my $quiet = $opt_quiet;
my $severity = $opt_severity || 'harsh';
my $file     = $opt_file;
my $verbose  = $opt_verbose;

#!/usr/local/bin/perl

unless ($file) { 
    &help();
    exit;
}

use Perl::Critic;
my $critic = Perl::Critic->new(-severity=>$severity, -verbose=>$verbose,-exclude=>['RequireExtendedFormatting']);
my @violations = $critic->critique($file);

print "critic.pl -file $file -severity $severity\n";
print '*' x 80;
print "\n";

print parse_violations(\@violations);

if ($verbose) {
    print Dumper $critic->policies;
    print "\n\n";
    print Dumper $critic->statistics;
    print "*" x 40;
    print "\n";
}                                         
exit;

###########################
sub parse_violations {
###########################
    my $violations = shift;

    my %std_violations;
    foreach my $violation (@$violations) {
	chomp $violation;
	if ($violation =~/^(.*) at line (\d+), column (\d+). See page[s]? ([\d\,]+) of PBP/ims) {
	    my $desc = $1;
	    my $line = $2;
	    my $col  = $3;
	    my $ref  = $4;
	    my $viol = "$1 (* see PBP pg $4 *)";
	    $std_violations{$viol} ||= "Line(s): ";
	    $std_violations{$viol} .= "$line;";
	}
	elsif ($violation =~ /^(.*) at line (\d+), column (\d+). (.*)$/ims) {
	    my $desc = $1;
	    my $line = $2;
	    my $col  = $3;
	    my $expl = $4;
	    my $viol = "$1 [$4]";
	    $std_violations{$viol} ||= "Line(s): ";
	    $std_violations{$viol} .= "$line;";
	} 
	else {
	    $std_violations{"Special Case - $violation"}++;
	}
    }
    
    my @violation_summary;
    foreach my $key (keys %std_violations) {
	push @violation_summary, "$key ----------- {$std_violations{$key}}\n";
    }
    return @violation_summary;
}
#############
sub help {
#############

    print <<HELP;

Usage:
*********

    critic.pl -file <file> [options]

Mandatory Input:
**************************
-file <filename>

Options:
**************************     
-severity <severity> (eg: 1-5 or 'gentle','stern','harsh','brutal','cruel');

Examples:
***********

HELP

}
