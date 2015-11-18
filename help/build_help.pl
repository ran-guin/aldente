#!/usr/local/bin/perl56

###############################
# build_help.pl
###############################
use strict;

use Data::Dumper;
use Cwd 'abs_path';

require "getopts.pl";
&Getopts('A:f:hrF:Ra:u');

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/"; # add the local directory to the lib se

#use alDente::SDB_Defaults qw($image_dir);
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Code;

use vars qw($opt_A $opt_f $opt_h $opt_r $opt_F $opt_R $opt_a $opt_u);
use vars qw($URL_address $current_dir $code_version);

if ($opt_h) {_print_help_info(); exit;}

my $action = 'Help'; #Possible actions are 'All', 'Help' and 'Perldoc'
$action = $opt_A if ($opt_A); 
my $help = ($action =~ /All|Help/i);
my $perldoc = ($action =~ /All|Perldoc/i);
my $new_db_changes = ($action =~ /All|DB_Changes/i);
my %List;
if ($opt_f) {
    foreach my $file (split /,/, $opt_f) {
	%List->{$file} = 1;
    }
}
my $update = $opt_u;    ## only add perldoc if the file does not already exist.

my $perldoc_dir = "$current_dir/../www/html/perldoc/";
my $help_directory = "$current_dir/../help/";
my $module_directory = "$current_dir/../lib/perl/";

my @help_files = glob("$help_directory/*.help");

my $all_help = "Manual.help";

my $remove = 1;               # Whether to remove perldoc from script.  Zero = Do not remove
if ($opt_R) {$remove = 2}     # Remove ALL perldocs from script.
elsif ($opt_r) {$remove = 1}  # Remove perldocs except perldoc header and footer

my $author = $opt_a || '';

my %found_help;

if ($help) {
    unlink("$help_directory/$all_help");

    open(FILES,">$help_directory/bin_files.help") or die "cannot open $help_directory/bin_files.help";
}

my %Help;
%Help = _build_FS_help('perl',"$current_dir/../bin/");

#If user choose to insert perldoc but did not specify a file then confirm again with user.
if ($perldoc && !$opt_f) {
    print "Are you sure you want to insert Perldoc to and re-organize ALL source files? (y/n)";
    my $ans = Prompt_Input(-type=>'char');
    unless ($ans =~ /y|Y/) {exit;}
}

#
# <CONSTRUCTION>
#  Add code to generate man pages for *.pl files (but NOT perldoc) #
#
#foreach my $key (keys %Help) {
#    if ($help) {
#	print FILES "$key : " . %Help->{$key}->{summary} . '<BR>';
#    }
#    my $file = $key . "." . %Help->{$key}->{ext};
#    if ($perldoc && (%Help->{$key}->{ext} =~ /pm|pl/i) && (!$opt_f || exists %List->{$file})) {
#	_build_code(%Help->{$key}->{dir} . "/$key." . %Help->{$key}->{ext});
#	_build_perldoc($key,%Help->{$key}->{dir},%Help->{$key}->{ext});
#	if ($remove) {
#	    _build_code(%Help->{$key}->{dir} . "/$key." . %Help->{$key}->{ext},-remove=>$remove);
#	}
#	
#    }
#}

if ($help) {close(FILES);}

my @modules = ('RGTools','SDB','alDente','Sequencing','Gene_Expression');
my @excludes = ('TLC.pm'); # A list of files to exclude from perldoc generation.                                                  

foreach my $module (@modules) {
    my %Help = _build_FS_help('modules',"$module_directory/$module/");
    if ($help) {
	open(FILES,">$help_directory/$module" . "_modules.help") or die "cannot open $help_directory/bin_files.help";

	print FILES "<H2>$module Modules</H2>\n<P>\n";
	my $readme = `cat $module_directory/$module/README`; 
	unless ($readme=~/no such/i) { 
	    print FILES $readme;
	}
	print FILES "\n<span class=small><UL>\n";
	foreach my $key (keys %Help) {
	    #my $link = &Link_To("$URL_address/SDB_code.pl",$key,"?Find=1&Modules=$module");
	    my $link = &Link_To("$URL_domain/$URL_dir_name/html/perldoc/$key.html",$key,undef,undef,['newwin']);
	    print FILES "\n<LI>$link : " . %Help->{$key}->{summary};
	}
	print FILES "\n</UL></span>\n";
	close(FILES);
	print "Wrote to $module" . "_modules.help (link to $URL_address OF $0)\n";
    }
    foreach my $key (keys %Help) {	
	my $file = $key . "." . %Help->{$key}->{ext};
	if ($perldoc && (%Help->{$key}->{ext} =~ /pm/i) && (!$opt_f || exists %List->{$file})) {
	    
	    if ($update && -e "$perldoc_dir/$key.html") { print "($key exists - ignoring in update mode)\n"; next; }
	    
	    unless (grep /^$file$/, @excludes) {
		print "*** build $file ***\n";
		_build_code(%Help->{$key}->{dir} . "/$key." . %Help->{$key}->{ext});
		_build_perldoc($key,%Help->{$key}->{dir},%Help->{$key}->{ext});
		if ($remove) {
		    _build_code(%Help->{$key}->{dir} . "/$key." . %Help->{$key}->{ext},-remove=>$remove);
		}
	    }
	}
    }
}

if ($help) {
    my $help_list = "build_help.files";
    open(HELP,"$help_directory/$help_list") or die "cannot open $help_directory/$help_list";

    my $TofC = "<h1>Table Of Contents</H1><P>\n";

    my $manual = '';
    my $chapter;
    while (<HELP>) {
	chomp;
	my $help = $_;
	my $title;
	my $name;
	if (/Chapter:\s*(.*)/) {
	    $chapter = $1;
	    my $title = $chapter;
	    if ($chapter=~/(.*):\s*(\S+)/) {
		$chapter = $2;
		$title = $1;
	    }
	    
	    print "$title Chapter\n***********************\n";
	    
	    `echo \"$title\" > $chapter.chapter.help`;
	    if ($TofC) { 
		$TofC .= "</UL>\n"; 
	    } 
	    $TofC .= "<h2>$title Chapter</h2><UL>\n";
	    $manual .= "<h1>$title Chapter</h1>\n";
	    next;
	}
        elsif (/(.*):(\S+)/) {
	    $title = $1;
	    $name = $2;
	} elsif (/(\S+)/) {
	    $title = $1;
	    $name = $1;
	}
	
	if (-e "$help_directory/$name.help") {
#	    `echo \"<HR>\n<A Name=$name>\" >> $all_help`;
#	    `cat $help_directory/$name.help >> $all_help`;
	    $manual .= "\n<HR>\n<A Name=$name>\n";
	    $manual .= `cat $help_directory/$name.help`;
	    
	    `cat $help_directory/$name.help >> $chapter.chapter.help`;
	    %found_help->{$name} = 1;
	    $TofC .= "<LI><A Href=\#$name>$title</A>\n";
	    print "$chapter : $name ($title)\n";
	}
	else { print "Missing $help_directory/$name.help.\n"; } 
    }
    close(HELP);

    if ($TofC) {  $TofC .= "</UL>\n" } 
    open(MANUAL,"> $help_directory/Manual.help") or die "Cannot make manual\n";
    print MANUAL $TofC;
    print MANUAL $manual;
    close(MANUAL);

    open(TOFC,"> $help_directory/TofC.help") or die "Cannot make manual\n";
    print TOFC $TofC;
    close(TOFC);


    print "Using help files:\n*****************\n";
    print join "\n", keys %found_help;
    print                  "\n*****************\n";

    foreach my $help_file (@help_files) {
	if ($help_file =~/(\S+)\/(.*?)\.help/i) {
	    my $dir = $1;
	    my $help = $2;
	    if ($dir=~/^\.\/?$/) { $dir = '' }
	    unless (%found_help->{$help}) { print "Not using $help (in $dir)..\n"; }
	}
	else { print "format ? $help_file..\n"; }
    }

    print "done..\n";

#
# Add small routine to replace help file names in text with hyperlinks...
#
# 
}

if ($new_db_changes) {
    _build_db_new_changes();
}

exit;

###############
sub _build_FS_help{
###############
    my $type = shift;
    my $dir = shift;
    
    my %Help;
    my $ext;

    if ($type =~ /perl/) {
	$ext = "pl";
    } elsif ($type =~ /module/) {
	$ext = "pm";
    } elsif ($type =~/dir/) {

    } else { return }
 
    my @files = glob("$dir*.$ext");
    foreach my $file (@files) {
	if ($file =~ /$dir(.+)\.$ext/) {
	    my $filename = $1;
	    my $output = `grep -B 100 'use strict' $file`;
	    if ($output =~ /$filename\.$ext[\n\s\#]+([a-zA-Z].*?)\n/) {
		%Help->{$filename}->{summary} = $1;   ### get first string of text after file name
#		print "Help : $1\n";
	    }
	    %Help->{$filename}->{dir} = $dir;
	    %Help->{$filename}->{ext} = $ext;
	    my @routines = `grep ^sub $file`;
	    foreach my $routine (@routines) {
		my $name;
		if ($routine =~/sub (.*)\s*\{/) { $name = $1 }
		push(@{ %Help->{$filename}->{routines}},$name); 
	    }
#	    print "$file:\n$output\n_______________________________________\n";
	}
    }
    return %Help;
}

#####################
sub _build_code {
#####################
#
#Re-organize the code and insert perldoc into code
#
    my $file = shift; #Source file to insert Perldoc and re-organize [String]
    my %args = @_;
    my $remove = $args{-remove} || 0;
    
    my $action = 'inserted';

    my $code = Code->new($file);
    $code->define_custom_modules(-dirs=>\@modules);
    if ($remove) {
	$action='removed';
	my $perldoc_level;
	if ($remove == 1) {$perldoc_level = 1}
	elsif ($remove == 2) {$perldoc_level = 0}
	$code->generate_code(-perldoc=>$perldoc_level,-author=>$author);
    } else {
	$code->generate_code(-perldoc=>2,-author=>$author);    
    }
    $code->save_code(-overwrite=>1);

    print "$file: Perldoc $action (and code re-organized if necessary).\n";
}

#####################
sub _build_perldoc {
#####################
#
#Runs the pod2html program to convert perldoc into HTML help files
#Or runs the pod2pdf program to convert perldoc into PDF files
#
    my $file = shift;
    my $dir = shift;
    my $ext = shift;

    unless (-d $perldoc_dir) {mkdir $perldoc_dir}

    my $infile = "$dir/$file.$ext";
    my $outfile = "$perldoc_dir/$file.html";
    my $command;

    my $format = $opt_F || 'html';
    my $URL_path = $URL_base_dir_name;

    my $resolved_current_dir = abs_path($current_dir);
    if ($resolved_current_dir =~ /(.*versions\/)([\w-]+)/) {
	my $base_dir = $1;
	my $version_name = $2;
	
	# Resolve URL version
	my $URL_version_name;
	my $fback = try_system_command("find $base_dir -type l"); # First find all the symlinks
	my $found = 0;
	foreach my $link (split /\n/, $fback) {
	    my $link_to = readlink($link);    ### Find out where the symlink is pointing to
	    if ($link_to eq $version_name) {  
		if ($link =~ /production/i) { ### There is no version name for production - it is just like 'SDB'
		    $URL_version_name = '';
		}
		else {
		    ($URL_version_name) = $link =~ /\/(\w+)$/;
		}
		$found = 1;
		last;
	    }
	}

	unless ($found) {$URL_version_name = $version_name}  # If still not found then use then use the directory name as the URL version  name
	$URL_path = $URL_base_dir_name . "_" . $URL_version_name if $URL_version_name;
    }

    #Add uplinks to the perldoc HTML generated...
    if ($format =~ /all|html/i) {
	my $temp_infile = "$infile.temp";
	try_system_command("cp $infile $temp_infile");
	
	my $all_lines;
	open(FILE,"$temp_infile");
	my $inside_synopsis = 0;
	 
	foreach my $line (<FILE>) {  # Replace blank lines with <BR>
	    $all_lines .= $line;
	}
	 
	while ( $all_lines =~s/^([ ][\S ]+)\n\s*\n[ ]/$1<BR>\n /m ) {}   ## replace blank lines in synopsis with <BR> in temp file 
	 
	open(FILE,">$temp_infile");
	print FILE $all_lines;
	close (FILE);

	$command = "/usr/bin/pod2html --infile=$temp_infile --outfile=$outfile -css=/$URL_path/css/perldoc.css";
	print $command;
	print try_system_command($command);
	if (-f $outfile) {
	    my $img_dir = $image_dir;
	    $img_dir =~ s/\//\\\//g;
	    # Replace uplinks
	    my $uplink = "&nbsp;<a href='#top'><img src=\\/$img_dir\\/uplink.png><\\/a>";
	    $command = "/usr/local/bin/perl56 -i -pe 's/(<[L|l][I|i]>.*)\\s*&lt;UPLINK&gt;(.*<\\/[L|l][I|i]>)/\$1\$2/g' $outfile";
	    print try_system_command($command);
	    $command = "/usr/local/bin/perl56 -i -pe 's/(<[H|h]\\d{1}>.*)&lt;UPLINK&gt;(.*<\\/[H|h]\\d{1}>)/\$1$uplink\$2/g' $outfile";
	    print try_system_command($command);
	    $command = "/usr/local/bin/perl56 -i -pe 's/&lt;(BR|br)&gt;/<BR>/g' $outfile";
	    print try_system_command($command);
	    print "$dir/$file.$ext: Perldoc HTML generated ($outfile).\n";		
	}
	else {
	    print "***$dir/$file.$ext: Perldoc HTML not generated.\n";
	}

	try_system_command("rm -f $temp_infile");
    }
    if ($format =~ /all|pdf/i) {
	my $temp_html_file = "$outfile.temp";
	$command = "/usr/bin/pod2html --infile=$infile --outfile=$temp_html_file -css=/$URL_path/css/perldoc.css";
	print try_system_command($command);
	if (-f $temp_html_file) {
	    # Get rid of the <UPLINK> tags
	    $command = "/usr/local/bin/perl56 -i -pe 's/(<[L|l][I|i]>.*)\\s*&lt;UPLINK&gt;(.*<\\/[L|l][I|i]>)/\$1\$2/g' $temp_html_file";
	    print try_system_command($command);
	    $command = "/usr/local/bin/perl56 -i -pe 's/(<[H|h]\\d{1}>.*)&lt;UPLINK&gt;(.*<\\/[H|h]\\d{1}>)/\$1\$2/g' $temp_html_file";
	    print try_system_command($command);
	    # Replace "<BR>" with blank lines
	    $command = "/usr/local/bin/perl56 -i -pe 's/&lt;(BR|br)&gt;/<BR>/g' $temp_html_file";
	    print try_system_command($command);	 
	    #$command = "/usr/local/bin/perl56 -i -pe 's/<PRE|pre>\\n<\\/(PRE|pre)>/<BR>/g' $temp_html_file";
	    #print try_system_command($command);	
	    my $all_lines;
	    open (FILE,$temp_html_file);
	    my $inside_pre = 0;
	    foreach my $line (<FILE>) {
		if ($line =~ /<PRE|pre>/) {
		    $inside_pre = 1;
		    $line .= "\n";
		}
		elsif ($line =~ /<\/(PRE|pre)>/) {
		    $inside_pre = 0;
		    $line .= "\n";
		}
		elsif ($inside_pre) {
		    $line .= "<BR>";
		}
		$all_lines .= $line;
	    }
	    close (FILE);

	    open(FILE,">$temp_html_file");
	    print FILE $all_lines;
	    close (FILE);
 
	    # Get rid of "<PRE>" tags and format text to appropiate size
	    $command = "/usr/local/bin/perl56 -i -pe 's/<(PRE|pre)>/<P><FONT SIZE='-1'>/g' $temp_html_file";
	    print try_system_command($command);	  
	    $command = "/usr/local/bin/perl56 -i -pe 's/<\\/(PRE|pre)>/<\\/FONT><P>/g' $temp_html_file";
	    print try_system_command($command);	  	    

	    my $ps_file = $outfile;
	    my $pdf_file = $outfile;
	    $ps_file =~ s/\.html/\.ps/;
	    $pdf_file =~ s/\.html/\.pdf/;
	    my $cmd2 = "/home/sequence/alDente/share/bin/html2ps --original $temp_html_file > $ps_file";
	    my $cmd3 = "ps2pdf $ps_file $pdf_file";
	    my $cmd4 = "rm -f $ps_file";
	    my $cmd5 = "rm -f $temp_html_file";
	    try_system_command("$cmd2; $cmd3; $cmd4;");
	    print "$dir/$file.$ext: Perldoc PDF generated ($pdf_file).\n";
	}
	else {
	    print "***$dir/$file.$ext: Perldoc PDF not generated.\n";
	}
    }
}

##################################
# Build database new changes file
##################################
sub _build_db_new_changes {
    my $sql_file = "$current_dir/../install/upgrade/sql/upgrade_$code_version.sql";
    my $pl_file = "$current_dir/../install/upgrade/bin/upgrade_$code_version.pl";
    my $new_db_changes_file = "$current_dir/New_DB_Changes.help";

    print "Generating new DB changes help file at '$new_db_changes_file'...\n";
    
    open(DB_CHANGES,">$new_db_changes_file");
    print DB_CHANGES "<h2>New Database Changes for Release $code_version (@{[today()]})</h2><p>\n\n";
    
    # Parse out the comments from the SQL file
    print DB_CHANGES _parse_sql_pl_file($sql_file);

    # Parse out the comments from the PL file
    print DB_CHANGES _parse_sql_pl_file($pl_file);   

    close(DB_CHANGES);
}

#################################################
# Parse the SQL and PL file to extract comments
# Return: The concatenation of comments
#################################################
sub _parse_sql_pl_file {
    my $file = shift;

    my $output;

    open(SQL_PL_FILE,$file);
    while (<SQL_PL_FILE>) {
	if (/^\s*(\#+)(.*)$/) {
	    my $hashes = $1;
	    my $comments = $2;
	    if ($comments =~ /^<\/?\w+>/) { # HTML tags and comments - print as it is
		$output .= "$comments\n";
	    }
	    elsif ($comments =~ /;$/) { next }  # Semicolon at the end.  Assume is commented code and so don't display
	    elsif (length($hashes) == 1 && $comments !~ /^$/) {
		$output .= "- $comments<br>\n";
	    }
	    elsif ($comments !~ /^$/) { # Some kind of header
		$output .= "<br><h3>$comments</h3>\n";
	    }
	}
    }
    close(SQL_PL_FILE);  

    return $output;
}

#########################
sub _print_help_info {
#########################
print<<HELP;

File:  buildhelp.pl
####################
This script updates the help files.

Options:
##########

-A     Action
       -If not specified or specified as 'All', then the script will update both the help manuals and the Perldocs
       -If specified as 'Help', then the script will just update the help manuals
       -If specified as 'Perldoc', then the script will just update the Perldocs
       -If specified as 'Db_Changes', then the script will parse out the new database changes into the New_DB_Changes.help file 

-F     Format of perldoc to be built
       - If specified as 'All', then Perldoc will be written to both HTML and PDF format
       - If not specified or specified as 'Html', then the Perldoc will be written to a HTML format
       - If specified as 'Pdf', then the Perldoc will be written to a PDF format

-f     File - Specify the source code file (.pl or .pm) for which a Perldoc will be built.

-h     Print help information

Examples:
###########
Update both help files and perldocs:      buildhelp.pl
Update help files only:                   buildhelp.pl -A Help                
Update Perldocs only:                     buildhelp.pl -A Perldoc
Generate new database changes only:       buildhelp.pl -A DB_Changes

HELP
}
