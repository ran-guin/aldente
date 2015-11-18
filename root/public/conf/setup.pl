#!/usr/bin/perl

use strict;

use FindBin;
use Data::Dumper;

require "getopts.pl";
&Getopts('f:');
use vars qw($opt_f);

my $file = $opt_f || "config.conf";

# initialize 'marked' keys
my %marked_keys;

# first, check to see if config xml is there
if (! -e "$file") {
    print "** Config file $file not found.\n\n";
    print "You must write the defaults to file first\n\n";
    exit;
}


## open config file
my $conf = &parse_config($file);
unless ($conf) {
    print "Config file $file missing, please initialize it first.\n";
    exit;
}
&save_config($conf,"test2.conf");

mainMenu();
# read commandline
for (my $command = readCommand(); $command !~ /^quit/i; $command = readCommand()) {
    processCommand($command);
    mainMenu();
}

exit;

##########################
# display main menu
##########################
sub mainMenu() {
##########################
    print "External Collaborator page config:\n\n";
    print "(1) Display configuration\n";
    print "(2) Add new entry\n";
    print "(3) Delete entry\n";
    print "(4) Edit entry\n";
    print "(save) Save Changes\n";
    print "(quit) Exit setup\n";
    print '>';
}

###################################
# read commmand from standard input
###################################
sub readCommand {
###################################
    my $command = <STDIN>;
    return $command;
}

###################################
# process commandline commands
###################################
sub processCommand {
###################################
    my $command = shift;

    # command 1 - display entries
    if ($command == 1) {
	display_settings();
    }
    # command 2 - add a new setting
    elsif ($command == 2) {
	print "Adding a new setting:\n";
	# prompt for key name, description and value
	print "Key Name > ";
	my $key_name = readCommand();
	print "Description > ";
	my $desc = readCommand();
	print "Value > ";
	my $value = readCommand();
	# remove trailing whitespace
	chomp($key_name);
	chomp($desc);
	chomp($value);
	# push into configuration hash
	push (@$conf, { "$key_name" => { 'desc' => $desc, 'value' => $value } });
	$marked_keys{$key_name} = '(A)';
    }
    # command 3 - delete a setting
    elsif ($command == 3) {
	print "Choose which settings to delete:\n";
	display_settings();
	print '>';
	# prompt for a setting number to delete
	my $choice = readCommand();
	if ($choice =~ /^quit$/i) {
	    return;
	}
	unless ($choice =~ /^\d+$/) {
	    return;
	}
	# remove from configuration hash
	#splice (@$conf, $choice , 1);
	my ($key_name) = keys %{$conf->[$choice]};
	$marked_keys{$key_name} = '(D)';
    }
    # command 4 - edit a setting
    elsif ($command == 4) {
	print "Choose which setting to change:\n";
	display_settings();
	print "(quit) Return to main menu\n";
	# prompt for entries to edit
	for (my $subcommand = readCommand(); $subcommand !~ /^quit/i; $subcommand = readCommand()) {
	    # check if the user wants to save
	    setSettings($subcommand);
	    print "Choose which setting to change:\n";
	    display_settings();
	    print "(quit) Return to main menu\n";
	    print '>';
	}
    }
    # save command 
    elsif ($command =~ /^s$|^save$/i) {
	saveSettings();
    }
    # quit command
    elsif ($command =~ /^q$|^quit$/i) {
	exit;
    }
}

##########################
# Function to irrevocably save settings
##########################
sub saveSettings {
##########################
    # remove deletes
    foreach my $key (keys %marked_keys) {
	if ($marked_keys{$key} eq '(D)') {
	    # search for the key and remove it from the configuration hash
	    my $counter = 0;
	    foreach my $row (@$conf) {
		my ($local_key) = keys %{$conf->[$counter]};
		# found key to delete
		if ($local_key eq $key) {
		    splice (@$conf, $counter , 1);
		    last;
		}
		$counter++;
	    }
	}
    }
    # save into config file
    &save_config($conf,$file);
    # remove all highlighted rows
    %marked_keys = ();
}

##########################
# function to prompt a user for editing settings
##########################
sub setSettings {
##########################
    my $selection = shift;

    # error check - a number must be chosen
    unless ($selection =~ /^\d+$/) {
	print "** ERROR: Must choose a number!\n";
	return;
    }

    # if selection is invalid, return
    unless (exists $conf->[$selection]) {
	print "** ERROR: Invalid selection!\n";
	return;
    }
    # prompt user to give a new value
    my ($key) = keys %{$conf->[$selection]};
    print "Enter new value for $key > ";
    my $newvalue = readCommand();
    ## strip newline
    chomp($newvalue);
    # push into configuration
    $conf->[$selection]{$key}{value} = $newvalue;
    $marked_keys{$key} = '(M)';
}

#########################################
# Function to display current settings
#########################################
sub display_settings {
#########################################
    my $counter = 0;
    print "\n ** SETUP VARIABLES: ** \n\n";
    foreach my $hashref (@$conf) {
	foreach my $key (keys %$hashref) {
	    print "($counter) $key -> ".$hashref->{$key}{value};
	    if (exists $marked_keys{$key}) {
		print " $marked_keys{$key} (*) "; 
	    }
	    print "\n";
	}
	$counter++;
    }
    print "\n";
}

#########################
# Function to parse the config file
# Slightly different parser to preserve order
# (this is critical if editing the config file)
#########################
sub parse_config {
#########################
    my $file = shift;         # (Scalar) filename of the config file
    my $ignore_tags = shift;  # (ArrayRef) list of tags to ignore

    # open file
    open(INF,"$file");
    my @variables;

    my @lines = ();
    while (<INF>) {
	push(@lines,$_);
    }
    close INF;

    # go through the file
    # search for a variable tag [VARIABLE]
    # once a variable tag is found, find its value and store it
    # repeat
    my $index = -1;
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
	    my %varhash;
	    $varhash{$curr_variable} = { 'desc' => $desc,
					 'value' => ''
					 };
	    push(@variables,\%varhash);
	    $index++;
	    next;
	}

	if ($curr_variable) {
	    $variables[$index]{$curr_variable}{value} .= $line;
	    next;
	}
    }
    foreach (@variables) {
	foreach my $key (keys %{$_}) {
	    $_->{$key}{value} =~ s/^\s+//;
	    $_->{$key}{value} =~ s/\s+$//;	
	}
    }

    return \@variables;
}

###########################
# Function to save the config file
###########################
sub save_config {
###########################
    my $config_ref = shift;
    my $file = shift;
    
    open (OUTF,">$file");
    foreach my $row (@{$config_ref}) {
	foreach my $name (sort keys %{$row}) {
	    my $value = $row->{$name}{value};
	    my $desc = $row->{$name}{desc};
	    print OUTF "[$name] $desc\n\n";
	    print OUTF "$value\n\n";
	}
    }
    close OUTF;
}
