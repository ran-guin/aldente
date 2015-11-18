#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

fasta.pl - !/usr/local/bin/perl

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
use CGI ':standard';
use File::stat;
use Time::Local;
use Shell qw(cp mkdir ls);
use Carp;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

##############################
# custom_modules_ref         #
##############################
use Sequencing::Seq_Data;

 
use SDB::DBIO;
use SDB::CustomSettings;

use RGTools::RGIO;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw($opt_S $opt_L $opt_o $opt_W $opt_w $opt_A $opt_V $opt_v $opt_c $opt_R $opt_I $opt_N $opt_l $opt_u $opt_f $opt_T $opt_M $opt_Q $opt_C $opt_x $opt_i $opt_e $opt_P $opt_p $opt_X $opt_h $opt_U $opt_H $opt_a $opt_b $opt_q $opt_g $opt_d);
use vars qw($opt_QT $opt_QL $opt_Q20 $opt_user $opt_password);
use vars qw($testing %Defaults %Configs);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
unless (int(@ARGV)) { # Print help info if no arguments specified
    _print_help_info();
    exit;
}

#require "getopts.pl";
#&Getopts('S:L:o:C:x:i:e:X:h:U:H:c:R:N:T:fWwAVvPpIluMQabqg');
#
use Getopt::Long qw(:config no_ignore_case);
&GetOptions('QT=s'     => \$opt_QT,
	    'QL=s'     => \$opt_QL,
	    'Q20=s'    => \$opt_Q20,	    
	    'user=s'    => \$opt_user,	    
	    'password=s' => \$opt_password,	    
	    'f' => \$opt_f,
	    'w' => \$opt_w,
	    'W' => \$opt_W,
	    'A' => \$opt_A,
	    'V' => \$opt_V,
	    'v' => \$opt_v,
	    'P' => \$opt_P,
	    'p' => \$opt_p,
	    'I' => \$opt_I,
	    'l' => \$opt_l,
	    'u' => \$opt_u,
	    'M' => \$opt_M,
	    'Q' => \$opt_Q,
	    'a' => \$opt_a,
	    'b' => \$opt_b,
	    'q' => \$opt_q,
	    'g' => \$opt_g,
	    'S=s' => \$opt_S,
	    'L=s' => \$opt_L,
	    'o=s' => \$opt_o,
	    'c=s' => \$opt_c,
	    'R=s' => \$opt_R,
	    'N=s' => \$opt_N,
	    'T=s' => \$opt_T,
	    'C=s' => \$opt_C,
	    'i=s' => \$opt_i,
	    'e=s' => \$opt_e,
	    'X=s' => \$opt_X,
	    'x=s' => \$opt_x,
	    'h=s' => \$opt_h,
            'd=s' => \$opt_d,
	    'U=s' => \$opt_U,
	    'H=s' => \$opt_H
	    );

my $host = $opt_h || $Configs{PRODUCTION_HOST};
my $dbase = $opt_d || $Configs{PRODUCTION_DATABASE};
my $user = $opt_user;
my $password = $opt_password || '';
if ($user=~/(.*?)\s*\((.*)\)/) {
    $user = $1;
    $password = $2;
} elsif (!$user) {
    $user = Prompt_Input(-prompt=>'Username: ');
}

unless ($password) {
    $password = Prompt_Input(-prompt=>'Password: ',-type=>'password');   
} 
	
print "Connecting as $user ...\n";

my $dbc = SDB::DBIO->new(-dbase=>$dbase,-host=>$host,-user=>$user,-password=>$password);
$dbc->connect();
my $all_runs;
my $vector;
my $contaminant_threshold;
my $contaminant_name;
my $out_name;
my $verbose;
my $run;
my $lib;
my $source;
my $info;
if ($opt_I) {$info = 1;}
if ($opt_f) {$verbose = 1;}
if ($opt_S) {$source = $opt_S;}
if ($source>2) {
    print "Note:  Please use -R (id) to specify run id\n";
    print "'-S 1' or '-S 2' is now used to indicate that the Primary";
    print " (or Secondary) Source Name is to be used for the fasta file";
    print "\n\n";
    exit;
}
if ($opt_R) {$run = $opt_R;}
elsif ($opt_L) {$lib = $opt_L;}
if (!$run && (!$lib || ($lib=~/\?/) || !($lib=~/\w\w\w\w\w/))) {
    _print_help_info();
    exit;
}
unless ($dbc && $dbc->ping()) {
    print "Cannot connect as '$user' with password '$password'.\n";
    print "New version requires password authentication\n\n";
    print "Please include -U 'username(password)' in the command line\n";
    print "\neg:  fasta.pl -U 'myname(mypass)' -L CC001\n\n";
    print "(note : use quotes around the username(password) string)\n";
    print "(username and password required are used to connect to the mysql database)\n\n";
    exit;
}
if ($opt_o) {$out_name = $opt_o;} 
else {
    if ($lib) {$out_name = "$lib.fasta";}
    elsif ($run =~ /^\d+$/) { $out_name = "Run$run.fasta";}
    elsif ($run)            { $out_name = "RunList.fasta";}
    else {$out_name = "output.fasta";}
}
if ($opt_A) {$all_runs = 1; print "Including all runs\n";$out_name.=".all"}
else {$all_runs = 0; print "Not including development,test runs\n";}

if ($opt_QT) { print "Only including reads with contiguous TRIMMED quality region of > $opt_QT base pairs.\n"; $out_name.=".QT.$opt_QT"}
if ($opt_QL) { print "Only including reads with contiguous quality region of > $opt_QL base pairs.\n"; $out_name.=".QL.$opt_QL"}
if ($opt_Q20) { print "Only including reads with Q20 of > $opt_Q20 base pairs.\n"; $out_name.=".Q20.$opt_Q20"}

my $approved = 0;    ## flag to filter out runs not approved
my $billable = 0;    ## flag to filter out non-billable runs
if ($opt_a) {$approved = 1; print "Including ONLY approved runs\n"; $out_name = ".approved"; }
if ($opt_b) {$billable = 1; print "Including ONLY billable runs\n"; $out_name = ".billable"; }

my $qtrim = 1;  ### defaults to trim (and choose by trimmed length)
my $vtrim = 1;  ### defaults to trim (and choose by trimmed length)
my $choose_by = 'cut_length';
if ($opt_V) { 
    $vtrim = 0;
    $choose_by = 'total_length';
    print "Including VECTOR - choosing by total length\n";
    $out_name.=".Wvector";
}
elsif ($opt_v) {
    $vtrim = 0;
    print "Including VECTOR - choosing by quality length\n";
    $out_name.=".wvector";
}
if ($opt_P) {
    $qtrim = 0;
    $choose_by = 'total_length';
    print "Including POOR quality regions of sequence (chosen by total length)\n";
    $out_name.=".Wpoor";
}
elsif ($opt_p) {
    $qtrim = 0; 
    print "Including POOR quality regions of sequence (chosen by quality length)\n";
     $out_name.=".wpoor";
}
if ($opt_W) {
    $vtrim = 0;
    $qtrim = 0;
    $choose_by = 'total_length';
    print "Including WHOLE sequence (chosen by total length)\n";
    $out_name.=".Whole";
}
elsif ($opt_w) {
    $vtrim = 0;
    $qtrim = 0;  
    print "Including WHOLE sequence (chosen by quality length)\n";
     $out_name.=".whole";
}
if (defined $opt_e) {
    if ($opt_e < 1) { print "Invalid e-value threshold (use '-e N' where E=10^-N)\n"; exit;}
    unless ($opt_e) {
	print "Setting E_value threshold to maximum value of 0.1 (-e 1)\n";
	$opt_e = 1;
    }
    $contaminant_threshold = $opt_e;
    $contaminant_name = 'ecoli';
     $out_name.=".e$contaminant_threshold";
    print "Checking for E-Coli contamination with E < 10^-$opt_e\n";
}
if ($vtrim && $qtrim) {
    print "Trimming Run for BOTH Vector and Quality\n";
}
my $N_threshold = 0;
if ($opt_N) {
    $N_threshold = $opt_N;
    $out_name .= ".N$N_threshold";
}
my $Clip_Poly_T = 0;
if ($opt_T) {
    $Clip_Poly_T = $opt_T;     ### maximum length of T string before clipping...
    $out_name .= ".Tclipped$Clip_Poly_T";
    print "Trimming poly Ts if more than $Clip_Poly_T\n";
} 
my $chemcode;
if ($opt_c) {$chemcode = $opt_c; $out_name .= ".$chemcode";}
if ($opt_M) {$out_name .= ".mult";}
if ($opt_Q) {$out_name .= ".Q";}
if ($opt_x) {$out_name .= ".x"; print "Xcluding files in $opt_x\n";}
if ($opt_i) {$out_name .= ".i"; print "Including files in $opt_i\n";}	  	     
my $timestamp = &date_time();
$timestamp =~s/\s/_/g;
my $test = try_system_command("touch $out_name");
if ($test=~/denied/) { 
    print "Permission to write to $out_name is denied"; 
    exit; 
} else {
    unlink $out_name;
}
my $Options = {};  
$Options->{approved} = $approved;
$Options->{billable} = $billable;
$Options->{all} = $all_runs;
$Options->{qtrim} = $qtrim;
$Options->{vtrim} = $vtrim;
$Options->{choose_by} = $choose_by;
print "Vtrim: ".$Options->{vtrim} ."\n";
print "Qtrim: ".$Options->{qtrim} ."\n";
$Options->{chemcode} = $chemcode;
$Options->{source} = $source;
$Options->{info} = $info;
$Options->{N_threshold} = $N_threshold; 
$Options->{Clip_Poly_T} = $Clip_Poly_T;
$Options->{lower} = $opt_l || 0;
$Options->{upper} = $opt_u || 0;
$Options->{include_redundancies} = $opt_M || 0;
$Options->{quality_file} = $opt_Q || 0;
$Options->{column_width} = $opt_C || 0;
$Options->{include} = $opt_i || '';
$Options->{include_NG} = 1 unless $opt_g;         ## g - good grows only 
$Options->{exclude} = $opt_x || '';
$Options->{ecoli} = $contaminant_threshold || 0;
$Options->{XML} = $opt_X || 0;
$Options->{quiet} = $opt_q || 0;
$Options->{minimum_QL} = $opt_QL;
$Options->{minimum_Q20} = $opt_Q20;
$Options->{minimum_QT} = $opt_QT;


my $Custom_Header = $opt_H if $opt_H;

if ($Custom_Header && $Custom_Header !~ /^>/) { $Custom_Header = ">$Custom_Header" }  ## ensure '>' symbol begins header line ...

if ($run) {
    $run = extract_range($run);   ## convert to list if only a single value... 
    print "Converted range to list: $run\n";
}

my %sequences;
if ($Options->{XML}) {
    my @run_ids;
    if ($run) {
	@run_ids = split ',', $run; 
    } elsif ($lib) {
	@run_ids = &Table_find($dbc,'Run','Run_ID',"where Run_Status like 'Analyzed' AND Run_Directory like '$lib%'");
    } else { print 'You need to request either a list of runs or library'; exit; }
    
    %sequences = Sequencing::Seq_Data::get_run_info(dbc=>$dbc,run_ids=>\@run_ids,include_test=>1,field_list=>'Run_DateTime');
    open(XML,">".$Options->{XML}) or die "Cannot open $Options->{XML}\n";
    my $index = 0;
    my $lastid = 0;
    my $reads = 0;
    my $runs = 0;
    my $run_reads = 0;
    print XML "<RunList>\n";
    while (defined %sequences->{Well}[$index]) {
	my $id = %sequences->{FK_Run__ID}[$index];
	my $length = %sequences->{Sequence_Length}[$index];
	my $sequence =  %sequences->{Run}[$index];
	my $well =  %sequences->{Well}[$index];
	my $qleft = %sequences->{Quality_Left}[$index];
	my $qlength =  %sequences->{Quality_Length}[$index];
	my $growth  = %sequences->{Growth}[$index];
	my $P20 = %sequences->{Growth}[$index];
	my $label = %sequences->{Run_Directory}[$index];
	my $rundate = %sequences->{Run_DateTime}[$index];
	if ($id != $lastid) {
	    if ($runs) { 
		print XML "    <Reads>$run_reads</Reads>\n";
		print XML "  </SequenceRun>\n"; 
	    } 
	    print XML "  <SequenceRun ID=$id>\n";
	    print XML "    <Label>$label</Label>\n";
	    print XML "    <Date>$rundate</Date>\n";
	    $run_reads = 1;
	    $runs++;
	} else { $run_reads++; }
	print XML "    <Read>\n";
	print XML "      <RunID>$id</RunID>\n";
	print XML "      <Well>$well</Well>\n";
	print XML "      <Length>$length</Length>\n";
	print XML "      <Growth>$growth</Growth>\n";
	if ($length) { print XML "      <SequenceString>\n$sequence\n</SequenceString>\n"; }
	print XML "    </Read>\n";
	$lastid = $id;
	$reads++;
	$index++;
    }
    if ($runs) { 
	print XML "    <Reads>$run_reads</Reads>\n";
	print XML "  </SequenceRun>\n"; 
	print XML "  <Reads>$reads</Reads>\n";
    } 
    print XML "</RunList>\n";
    close(XML);
    print "Wrote to: " . $Options->{XML};
}
elsif ($run) {
    %sequences = Sequencing::Seq_Data::get_run_sequences($dbc,$run,$out_name,$Options,$Custom_Header);  # pull results from Run number 150.
    unless (%sequences) {print "No data found\n"; exit; }
    if ($verbose) {
	print "========\nData\n\n";
	system "cat $out_name";
	print "\n\n";
    }
}
elsif ($lib) {
    if ($info) {print "This takes longer since I am searching out original source names...(please be patient)\n";}
    my $pattern = $lib;
    if ($chemcode) {$pattern = "$lib%.$chemcode";}
    else {$chemcode = "";}
    my @Groups = &Table_find($dbc,'Run,Plate','count(*),Plate_Number',"where Run_Directory like '$pattern%' AND FK_Plate__ID=Plate_ID Group by Plate_Number");
    print "Library : $lib\n";
    my $plates = 0;
    my $runs = 0;
    foreach my $group (@Groups) {
	my ($count,$plate_num) = split ',', $group;
	print "Plate $plate_num : $count Runs\n";
	$plates++;
	$runs += $count;
    }
    my $limit_runs = 100;
    my $index = 0;
    my $group = 0;
    if ($runs <= $limit_runs) { $group = $plates; } ### no suffix if only 20 runs available...
    else {
	print "\nWarning - due to the number of runs for this library ($runs), there may be dynamic memory issues\n\n";
	print "Select Grouping of files by plate_number as desired:\n";
	print "L - to put entire library in one file (warning - may cause memory error if VERY big)\n";
	print "\# - put \# plates together in one file (eg. typing '5' would put plates 1..5 in one file, 6-10 in another etc.)\n";
	print "P - put each plate number in a separate fasta file...\n";
	print "q - quit\n\n";
	while (!$group) {
	    my $choice = Prompt_Input();
	    if ($choice =~ /^(\d+)$/) {
		print "Group by $1\n";
		$group = $1;
	    } elsif ($choice =~/L/i) {
		print "Group by Library (all in one file)";
		$group = $plates;
	    }  
	    elsif ($choice =~/p/i) { $group = 1; }
	    elsif ($choice =~/q/i) { exit; }
	    else {
		print "Sorry ... please enter 'L', 'P' or a number of Plate Numbers to group together";
	    }
	}
	print "Grouping fasta files in sets of $group plate_numbers (of $plates)\n"; 
    }
    _group_runs(pattern=>$pattern,group=>$group,file=>$out_name);
}
$dbc->disconnect();
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

###############
sub _group_runs {
###############
    my %args = @_;

    my $pattern = $args{pattern};
    my $groups = $args{group};
    my $file = $args{file};

    my %info = &Table_retrieve($dbc,'Run,Plate',['Run_ID','FK_Library__Name','Plate_Number'],"where FK_Plate__ID=Plate_ID AND Run_Directory like '$pattern%' Order by FK_Library__Name,Plate_Number,Run_ID");

    my $group = 1;
    my $index = 0;
    my @runs;
    my $suffix_index = 0;
    my $suffix = '';

    my @keys = keys %info;
    my $plate = %info->{Run_ID}[0];
    my $lastplate = %info->{Plate_Number}[$index] || 0;
    while (defined %info->{Run_ID}[$index]) {
	my $run = %info->{Run_ID}[$index];
	my $plate = %info->{Plate_Number}[$index];
	my $lib = %info->{FK_Library__Name}[$index];
	$index++;
	
	if ($plate == $lastplate) {
	    push(@runs,$run);
	    print "Run $run..(Pla$plate)..$lib ($group / $groups)\n";
	} 
	else {
   
	    $group++;
	    $lastplate = $plate;
	    print "Run $run..(Pla$plate)..$lib ($group / $groups)\n";
	    if ($group > $groups) { $group = 1; }
	    else { push(@runs,$run); next; } 

	    my $list = join ',', @runs;
#	    unless (defined %info->{Run_ID}[$index]) { $suffix = '' }
	    $suffix = ".$suffix_index";

	    print "get results for group of " . int(@runs) . " runs....->$file$suffix\n";
	    if ($list) {
		%sequences = Sequencing::Seq_Data::get_run_sequences($dbc,$list,"$file$suffix",$Options,$Custom_Header);  # pull results for this list
		_check_sequence(\%sequences);
		$suffix_index++;
		$Options->{quiet} = 1;   ### shut up after the first extracted group...
		@runs = ($run);          ### restart the next group with this run...
	    }
	}
    }
    
    ## finish up by getting results for last batch of plates
    my $list = join ',', @runs;
	
    if ($suffix_index) { $suffix = ".$suffix_index" }
    else { $suffix = '' }    ## Suppress suffix if grouping includes ALL plates found ##

    if ($list) {
	print "get results for  last " . int(@runs) . " runs...->$file$suffix\n";
	%sequences = Sequencing::Seq_Data::get_run_sequences($dbc,$list,"$file$suffix",$Options,$Custom_Header);  # pull results for this list
	_check_sequence(\%sequences);
    }
    return;
}

#################
sub _check_sequence {
#################
    unless (%sequences) {print "No data found\n"; exit; }
	
    if ($verbose) {
	foreach my $thiskey (sort keys %sequences) {
	    if ($thiskey=~/Clone:/) {next;}
	    elsif ($thiskey=~/Score:/) {next;}
	    my $output = %sequences->{$thiskey};
######### adjust output based on Options ... #########
	    my $header = %sequences->{"Clone:$thiskey"};
	    ($output,$header) = &fix_output($output,$header,$Options);
	    
	    if ($header=~/\w+/) {
		print ">$thiskey - $header\n$output\n";
	    }
	}
    }
    return ;
}

############################
# Prints help info
############################
sub _print_help_info {
    print "You must specify either:\n";
    print "Sequence Run id (eg ' -R 245')  or...\n";
    print "Library (eg ' -L CN001')\n\n";
    print "**********************************************\n";
    if ($lib) {
	$lib=~s/[\*\?]//g;
	my $search = $1;
	my @libs = &Table_find($dbc,'Library','Library_Name');
	print "Valid Libraries:  $search\n\n";
	foreach my $this_lib (@libs) {
	    if ($this_lib=~/$lib/i) {
		print "$this_lib\n";
	    }
	}
	if ($lib) {print "(limited to libraries like '$lib')";}
    }
    print "*************\n";
    print " Usage: \n***********\n";
    print "\nfasta.pl -U username(password) [options]\n";
    print "\nBasic Options:\n";
    print "****************\n";
    print "-R (Run ID) generate fasta file for sequence run\n";
    print "-L (Library Name) generate fasta file for library\n\n";
    print "-o (filename) write fasta file to (filename) - default = 'output.fasta'\n";
    print "\nTrimming Options:\n";
    print "*******************\n";
    print "-W INCLUDE WHOLE sequence (NOT trimmed for QUALITY OR VECTOR) - chosen by total length\n";
    print "-w  (same as above but chosen based on best quality length)\n";
    print "-P INCLUDE poor quality bps (does NOT trim for QUALITY) - chosen by total length\n";
    print "-p (same as above but chosen based on best quality length)\n";
    print "-V INCLUDE vector (does NOT trim for VECTOR) - chosen by total length\n";
    print "-v (same as above but chosen based on best quality length)\n";
    print "\n";
    print "-T N   - specify clipping of Poly_T tails detected greater than N base pairs\n";
    print "         (you may optionally specify front or back clipping only)\n";
    print "          eg. '-T F3', '-T B4', or even '-T F5B10')\n\n";
    print "\n(by DEFAULT trimming is done for BOTH Vector AND Quality)\n";
    print "\nRead Inclusion/Exclusion Options:\n";
    print "***********************************\n";
    print "-A    - include data from All runs (including Development,Test runs)\n";
    print "-a    - include only Approved runs \n";
    print "-b    - include only billable runs \n";
    print "-QT N  - include only reads with a TRIMMED quality region > N\n";
    print "-QL N  - include only reads with a quality region > N\n";
    print "-Q20 N - include only reads with a Q20 region > N\n";
    print "-g    - exclude no grows \n";
    print "-x    - specify exclusion file (file list of run ids, or names to exclude)\n";
    print "-i    - specify inclusion file (file list of run ids, or names to include)\n";    
    print "-c (chemcode) - looks only at specific chemcode\n";
    print "-e N  - ignore reads with e-coli detected with E-value < 1/(10 ^ -N)\n";
    print "-M - includes multiple results for similar clone if available\n";
    print "-f dumps fasta file to screen as well for feedback\n";
    print "\nOutput Appearance Options\n";
    print "****************************\n";
    print "-X - generates XML output (Temporary Run Object definition to be updated and standardized)\n";
    print "-H - custom fasta header. Valid entries are:\n";
    print "   - <<PRENOTE>>: pre-note (e.g. 'GSC')\n";
    print "   - <<SSDIR>>:   sequence subdirectory (e.g. 'WS0021a')\n";
    print "   - <<WELL>>:    well (e.g. 'A01')\n";
    print "   - <<LENGTH>>:  read length (e.g. '708')\n";
    print "   - <<NOTE>>:    note (e.g. 'Warning: Contamination;')\n";
    print "   e.g. To have a header like 'WS0021a.B21_A01 (708)', specify \"-H '<<SSDIR>>_<<WELL>> (<<LENGTH>>)'\" on the command line.\n\n";
    print "-Q - replace nucleotides with phred quality (extension suffixed with '.Q')\n\n";
    print "-C width - automatically places sequence string in columns of N (eg.  -C 50) for easier to read output\n";
    print "-S 1 (use Source name 1) - finds source of clone and uses this name for fasta header ('-S 2' uses secondary source if it exists)\n";
    print "-I    - include info (Run ID, Trace file path)\n";
    print "-N 15 - set all base pairs below phred 15 to 'N' indicating unknown\n";
    print "-l    - specify base pairs to be in lower case\n";
    print "-u    - specify base pairs to be in upper case\n";
    print "\nbase pairs will appear in capitals in fasta file if phred score >= 20)\n(To get all upper case in fasta file, use '-u > filename' to direct screen output to a file.\n";    
    print "\n____________________________________________________\n";
    print "example:  fasta.pl -U viewer(password) -L CN001 -A -o CN001.fasta";
    print "\n\n";
    print "Note: base pairs will appear in capitals if phred score >= 20)\n\n"; 
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

$Id: fasta.pl,v 1.24 2004/11/16 22:27:07 rguin Exp $ (Release: $Name:  $)

*** May 21 (R.Guin) ***
Excluded Failed / Aborted runs automatically in base condition
Added options:
-b (for billable only)
-a (for approved runs only)
-q (for quiet mode)
-g (to exclude no grows)

=cut

