#!/usr/bin/perl

use strict;

use CGI ':standard';

use POSIX qw(strftime);
require "getopts.pl";

use FindBin;
use Data::Dumper;

# logic:
# ask for LIMS path
# ask for path to install to (cgi-bin directory)
# ask for path to use for published documents and configuration (htdocs directory)
# ask for variables specified in config file
my $aldente_libpath = '';
my $aldente_importpath = '';
my $ldap_libpath = '';
my $config_path = '';

my $install_path = '';
my $htdocs_path = '';
my $public_submission_path = '';

my $installoption = 0;
my $option_file = '';
while (!$installoption) {
    print "Install options:\n";
    print "\t(1) Install on lims01 production\n";
    print "\t(2) Install on lims01 test\n";
    print "\t(3) Install on lims01 beta\n";
    print "\t(5) Install on lims01 Ran\n";
    print "\t(7) Install on lims01 Reza\n";
    print "\t(8) Install on lims01 Eric\n";
    print "\t(9) Install on webx440\n";
    print "\t(10) Install on lims01 Jing\n";
    print "\t(11) Install on lims01 Tara\n";
    print "\t(99) Prompt for variables\n";
    print ">>";
    my $install_choice = prompt(6);
    if ($install_choice) {
	if ($install_choice == 1) {
	    print "** Installing to PRODUCTION **\n";
	    $option_file = 'production.conf';
	    $installoption = 1;
	}
	elsif ($install_choice == 2) {
	    print "** Installing to TEST **\n";
	    $option_file = 'test.conf';
	    $installoption = 1;
	}
	elsif ($install_choice == 3) {
	    print "** Installing to BETA **\n";
	    $option_file = 'beta.conf';
	    $installoption = 1;
	}
	elsif ($install_choice == 5) {
	    print "** Installing to DEVELOPMENT rguin**\n";
	    $option_file = 'rguin.conf';
	    $installoption = 1;
	}
	elsif ($install_choice == 7) {
	    print "** Installing to DEVELOPMENT rsanaie**\n";
	    $option_file = 'rsanaie.conf';
	    $installoption = 1;
	}
	elsif ($install_choice == 8) {
	    print "** Installing to DEVELOPMENT echuah**\n";
	    $option_file = 'echuah.conf';
	    $installoption = 1;
	}
	elsif ($install_choice == 9) {
	    print "** Installing to EXTERNAL (webx440) **\n";
	    $option_file = "external.conf";
	    $installoption = 1;
	}
	elsif ($install_choice == 10) {
	    print "** Installing to DEVELOPMENT Jing**\n";
	    $option_file = 'jwang.conf';
	    $installoption = 1;
	}
	elsif ($install_choice == 11) {
	    print "** Installing to DEVELOPMENT Tara**\n";
	    $option_file = 'tgibbs.conf';
	    $installoption = 1;
	}
	elsif ($install_choice == 99) {
	    print "\n\n** PROMPTING FOR VARIABLES **\n\n";
	    $installoption = 1;
	}
	else {
	    print "Invalid option...\n";	
	}
    }
} 

my $ok = 0;
# load the options file
if ($option_file) {
    my $var = parse_config($option_file);
    # assign to variables
    $aldente_libpath = $var->{'ALDENTE_LIB'}{value};
    $aldente_importpath = $var->{'ALDENTE_IMPORT'}{value};
    $ldap_libpath = $var->{'LDAP_LIB'}{value};
    $config_path = $var->{'CONFIG'}{value};

    $install_path = $var->{'INSTALL'}{value};
    $htdocs_path = $var->{'HTDOCS'}{value};
    $public_submission_path = $var->{'EXT_SUB_DIR'}{value};
}

while (!$ok) {
    print "Initializing collaborator page scripts...\n";
    print "\n\n*** Install path information ***\n\n";
    print "Enter cgi-bin directory to install to: [$install_path]\n >>>";
    $install_path = prompt($install_path);
    print "Enter web-accessible (htdocs) path to use: [$htdocs_path]\n >>>";
    $htdocs_path = prompt($htdocs_path);

    print "\n\n*** Library path information ***\n\n";
    print "Enter path to alDente perl libraries: [$aldente_libpath]\n >>>";
    $aldente_libpath = prompt($aldente_libpath);
    $aldente_importpath = "$aldente_libpath/Imported";
    print "Enter path to Net::LDAP library: [$ldap_libpath]\n >>>";
    $ldap_libpath = prompt($ldap_libpath);
    print "Enter path for configuration file collab_config.xml: [$config_path]\n >>>";
    $config_path = prompt($config_path);
    print "Enter path for the public submission path: [$public_submission_path]\n >>>";
    $public_submission_path = prompt($public_submission_path);

    # print paths entered
    print "\n\n******* SUMMARY *******";
    print "cgi-bin: $install_path\n";
    print "htdocs: $htdocs_path\n";
    print "alDente library path : $aldente_libpath\n";
    print "alDente import library path : $aldente_importpath\n";
    print "LDAP library path : $ldap_libpath\n";
    print "Config file path : $config_path\n";
    print "\n\n";
    print "\nIs this information correct? (y/n) :";
    my $info_ok = <STDIN>;
    if ($info_ok =~ /y|yes/i) {
	$ok = 1;
    }
    else {
	$ok = 0;
    }
}


my $bindir = $FindBin::RealBin;

print "Initiating install:\n";
print "* Copying alDente_public.pl\n";

# make sure install path, htdocs, and config file path exists and are writable
unless (-e $install_path) {
    `mkdir $install_path`;
}
unless (-w $install_path) {
    print "ERROR: Install path $install_path not writable. Install terminating...\n";
    exit;
}
unless (-e $htdocs_path) {
    `mkdir $htdocs_path`;
}
unless (-w $htdocs_path) {
    print "ERROR: htdocs path $htdocs_path not writable. Install terminating...\n";
    exit;
}
unless (-e $config_path) {
    `mkdir $config_path`;
}
unless (-w $config_path) {
    print "ERROR: config path $config_path not writable. Install terminating...\n";
    exit;
}

# copy CGI script
`cp -f $bindir/../cgi-bin/alDente_public.pl $install_path`;
# copy configuration file
`cp -f $bindir/../conf/setup.pl $config_path`;
if ($option_file && (-e $option_file) ) {
    `cp -f $option_file $config_path/config.conf`;
}
else {
    `cp -f $bindir/../conf/config.conf $config_path/config.conf`;
}

### modify alDente_public.pl - point to correct paths
open (INF,"$install_path/alDente_public.pl");
my @lines = <INF>;
close INF;
open (TMP,">$install_path/alDente_public.pl.tmp");

foreach my $line (@lines) {
    if ($line =~ /^CONFIG_ALDENTEPATH : /) {
	$line = "use lib '$aldente_libpath';\n";
    } 
    elsif ($line =~ /^CONFIG_ALDENTEIMP : /) {
	$line = "use lib '$aldente_importpath';\n";
    }
    elsif ($line =~ /^CONFIG_LDAPPATH : /) {
	$line = "use lib '$ldap_libpath';\n";
    }
    elsif ($line =~ /^CONFIG_CONFIGFILE : /) {
	$line = "my \$config_file = '$config_path/config.conf';\n";
    }
    
    print TMP $line;
}
close TMP;
`rm -f $install_path/alDente_public.pl`;
`mv $install_path/alDente_public.pl.tmp $install_path/alDente_public.pl`;
`chmod 555 $install_path/alDente_public.pl`;

# make Projects and submissions directory
`mkdir $htdocs_path/Projects` unless (-e "$htdocs_path/Projects");
`ln -s $public_submission_path $htdocs_path/submissions` unless (-e "$htdocs_path/submissions");
`chmod -f 777 $htdocs_path/Projects`;
`chmod -f 777 $htdocs_path/submissions`;

# symlink to images directory
`ln -sf $aldente_libpath/../../www $htdocs_path/www` unless (-e "$htdocs_path/www"); 


exit;

#########################
# Function to prompt for standard input
#########################
sub prompt {
#########################
    my $default = shift;

    my $retval = <STDIN>;
    chomp $retval;
    $retval ||= $default;
    return $retval;
}

#########################
# Function to parse the config file
#########################
sub parse_config {
#########################
    my $file = shift;         # (Scalar) filename of the config file
    my $ignore_tags = shift;  # (ArrayRef) list of tags to ignore

    # open file
    open(INF,"$file");
    my %variables;

    my @lines = ();
    while (<INF>) {
	push(@lines,$_);
    }
    close INF;

    # go through the file
    # search for a variable tag [VARIABLE]
    # once a variable tag is found, find its value and store it
    # repeat
    my $curr_variable = '';
    foreach my $line (@lines) {
	# ignore comments
	if ( ($line =~ /^\#/) || ($line =~ /^\/\//) ) {
	    next;
	} 
	if ($line =~ /^\[(\w+)\](.*)/) {
	    next if (grep /^$1$/,@{$ignore_tags});
	    $curr_variable = $1; 
	    my $desc = $2;
	    $desc =~ s/^\s+//;
	    $desc =~ s/\s+$//; 
	    $variables{$curr_variable}{desc} = $desc;	    
	    $variables{$curr_variable}{value} = '';
	    next;
	}

	if ($curr_variable) {
	    $variables{$curr_variable}{value} .= $line;
	    next;
	}
    }
    foreach my $key (keys %variables) {
	$variables{$key}{value} =~ s/^\s+//;
	$variables{$key}{value} =~ s/\s+$//;	
    }

    return \%variables;
}


exit;
