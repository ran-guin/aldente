#!/usr/local/bin/perl
################################################################################
# Code.pm
#
# This object represents a Perl source code.  It has the ability to insert Perldoc and re-organize a source file.
#
################################################################################
package Code;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

build_pod.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

   use strict;
   .....
   .....
   return 1;

-Subs that have a leading understore in their name are assumed to be private. Please note that POD is only generated for public subs. For example:

   sub _method2 { # Private method.  No POD generated.
   .....
   }

 -The constructor of the class should be named 'new'.  Attributes of the class should be declared inside the constructor. For example, the attributes of the following class are 'id', 'name' and 'value':

   sub new {
       my \$this = shift;
        
       my \$class = ref(\$this) || \$this;
       my \$self = {};

       \$self->{id} = '';
       \$self->{name} = '';
       \$self->{value} = '';

       bless \$self, \$class;
       return \$self;
   }

   sub method1 { # Public method. POD will be generated.
   .....
   }

   sub square {
   #
   # This method takes a number and returns the square of it.
   #
   .....
   }

   sub method {
       my \$self = shift;
       my \$length = shift;
       my \$width = shift;
       .....
   }

   sub function {
       my \$length = shift; # Length of the box [Int]
       .....
   }  

   sub function {
       my \$length = shift; # Length of the box [Int]
       .....
   }  

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/local/bin/perl<BR>!/usr/local/bin/perl<BR>Code.pm<BR>This object represents a Perl source code.  It has the ability to insert Perldoc and re-organize a source file.<BR>

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
use Getopt::Std;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use RGTools::RGIO;
use RGTools::Code;
use RGTools::Directory;

##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_i $opt_o $opt_s $opt_A $opt_F $opt_h $opt_e);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
getopts('i:o:s:A:Fhe:');
my $infile = $opt_i;
my $outfile = $opt_o;
my $style = $opt_s;
my $action = $opt_A;
my $force = $opt_F;
my $help = $opt_h;
my $ext = $opt_e;                 ## optional list of file extensions to include 
my $production_html = "/opt/alDente/www/htdocs/html/";
my $share_html      = "/home/sequence/alDente/share/";
if ($help) {
    _print_help_info();
}
elsif ($action && $infile) {
    if ($action =~ /dir/) {
	print "generate directory navigator\n";
	$outfile ||= 'temp';
	#unless (-e $outfile) { 
	    `mkdir $share_html/$outfile`;
	#}
	my $dir = Directory->new(-search=>$infile);
	$dir->generate_html_navigator(-filename=>$outfile,-html_dir=>"$share_html",-html_URL=>"/share",-ext=>$ext);
    }        
    if ($action =~ /all|pod/i) {
	my $code = Code->new($infile);
	$code->generate_code(-perldoc=>2);
	$code->save_code(-overwrite=>$force);
	print "$infile: Perldoc inserted and code re-organized.\n";
    }
    if ($action =~ /all|html/i) {
	unless ($outfile) {print "Please specify output HTML file. Type 'build_code.pl -h' for help on using this program.\n"; exit;}
	unless ($force) {$infile = "$infile.pod"}
	my $command;
	if ($style) {
	    $command = "/usr/bin/pod2html --infile=$infile --outfile=$outfile --css=$style";
	}
	else {
	    $command = "/usr/bin/pod2html --infile=$infile --outfile=$outfile";
	}
	print "\nGENERATE HTML \n$command\n";
	print try_system_command($command);
	#Add uplinks to the perldoc HTML generated...
	if (-f $outfile) {
	    my $uplink = "&nbsp;<a href='#top'>&uarr;<\\/a>";
	    $command = "/usr/local/bin/perl -i -pe 's/(<[L|l][I|i]>.*)\\s*&lt;UPLINK&gt;(.*<\\/[L|l][I|i]>)/\$1\$2/g' $outfile";
	    print try_system_command($command);
	    $command = "/usr/local/bin/perl -i -pe 's/(<[H|h]\\d{1}>.*)&lt;UPLINK&gt;(.*<\\/[H|h]\\d{1}>)/\$1$uplink\$2/g' $outfile";
	    print try_system_command($command);
	    print "$infile: Perldoc HTML generated ($outfile).\n";
	}
	else {
	    print "***$infile: Perldoc HTML not generated.\n";
	}
    }
    if ($action =~ /all|gin/i) {
	my $html_file;
	if ($outfile) {$html_file = $outfile}
	else {$html_file = $infile}
	print try_system_command("ginperldoc $html_file");
    }
}
else { _print_help_info() }

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

#########################
sub _print_help_info {
#########################
print<<HELP;

File:  build_pod.pl
####################
This script can re-organize and insert POD into Perl source code, and also generate Perldoc html from the source code file. By default, the modified source code is saved in a new file (e.g. if original source file is 'test.pl' then the new file is 'test.pl.pod') - user can override this by using the '-F' switch.

Options:
##########

-A     Specify an action to perform:
       -pod:  Insert POD and re-organize source code
       -html: Generates the Perldoc HTML from a source code file
       -gin:  Takes the Perldoc HTML generated and put it into GIN
       -all:  Do all of the above
       -dir:  Generate directory navigator

-F     Force to overwrite the original source file (only applicable if action includes 'pod')
-i     Specify the location of input source file
-o     Specify the location of the output html file (only applicable if action includes 'html')
-s     Specify the location of the cascading style sheet for the output html file (only applicable if action includes 'html')
-h     Print help information

Examples:
###########
Insert POD and reorganize code:                               build_pod.pl -A pod -i /home/test.pl
Insert POD and reorganize code - overwrites original file:    build_pod.pl -A pod -i /home/test.pl -F
Generates Perldoc HTML from code that already contains POD:   build_pod.pl -A html -i /home/test.pl -o /home/test.html
Insert Perldoc HTML into GIN:                                 build_pod.pl -A gin -i /home/test.html
Do everything above, overwrites and include style sheets:     build_pod.pl -A all -i ./lib/perl/alDente/alDente_API.pm -o www/html/perldoc/alDente_API.html -s '/SDB/css/perldoc.css'

Just build html navigator for files in '/home/rguin/'          build_pod.pl -A dir -i /home/rguin -o new_subdir

Conventions:
###########################
To ensure POD is properly generated for your source code, please follow the following conventions:

-The first command block in your source code contains the description of the module. For example:

-The first command block inside a sub contains the description of the sub. For example:

-To designate a sub as a method rather than a function/subroutine, the first argument must be '\$self = shift;' or '\$this = shift;'. For example:

 In this case, the '\$length' argument has 'Length of the box' as its description and 'Int' as its data type (note that data type specification is within a pair of square brackets after the description and is optional).

-Superclasses is determined based on the \@ISA array. For example, 'DB_Object' is the superclass of the following class:

   use SDB::DB_Object;
   \@ISA = qw(DB_Object);

-When typing in synopsis for the module, please ensure every single line begins with at least 1 space.

Limitations:
###########################
-Currently we do not support source files that have multiple packages within them.

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

2003-08-19

=head1 REVISION <UPLINK>

$Id: build_pod.pl,v 1.12 2004/04/20 18:49:08 achan Exp $ (Release: $Name:  $)

=cut

