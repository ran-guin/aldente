#!/usr/local/bin/perl
## This script is run directly after initializing the core database
## It customizes the database schema and subclasses

## This is a template file that can be tweaked according to the needs of the package
##

use strict;
use warnings;
use FindBin;
use lib $FindBin::RealBin."/../../../lib/perl/";
use RGTools::RGIO;
use Getopt::Long;
use SDB::DBIO;
use SDB::CustomSettings;

my $dir = $FindBin::RealBin;
my $package_dir =  "$dir/..";
$dir =~ /\/(\w+)\/\w+$/;
my $package_name = $1;

use vars qw ( $opt_dbase $opt_user $opt_password $opt_host %Configs);

&GetOptions(
	    'dbase=s'       => \$opt_dbase,
	    'user=s'        => \$opt_user,
            'password=s'    => \$opt_password,
            'host=s'        => \$opt_host,
	    );

my ($host_init,$dbase_init) = split ':',$opt_dbase_init;

my $dbase = $opt_dbase;
my $user = $opt_user;
my $pwd = $opt_password;
my $host = $opt_host;

unless ( $dbase && $user && $pwd && $host) { die "not enough args provided\nBye\n"; }

my $sqlconnect = "mysql -h $host -u $user -p" . "$pwd" . " $dbase"; 

my $fback;

print "SQL Login command: " . "mysql -h $host -u $user -p" . "<pass>" . " $dbase\n";
print '----------------------------------------------'."\n";

my @tables_to_add;## = _get_package_tables($package_name);
print "Tables to be added:\n (list and table structure)\n";
print "----------------------------------------------\n";
my $list = join "\n ", @tables_to_add;
print $list."\n";
print "----------------------------------------------\n";

_add_tables(\@tables_to_add,-to=>"$host:$dbase");

my @sql_files = split ("\n", try_system_command("ls $dir/sql/*sql"));
my $sql_list = join "\n", @sql_files;

print ". SQL Files to be run:\n" . "$sql_list\n";
print '----------------------------------------------'."\n";

foreach my $sqlfile (@sql_files) {
    my $fback = '';
    print "Opening file:" . "$sqlfile\n";
    print "Trying command: $sqlconnect < $sqlfile\n";
    $fback = try_system_command("$sqlconnect < $sqlfile");
    print "FEEDBACK: $fback";
    print "Closing file: $sqlfile\n \n";
}

my %modules = _get_module_links();

print "--------------------------------------------\n";
print ". MODULE INSTALLATION\n";
print "--------------------------------------------\n";
print "Attemping installation of the following modules:\n ";
print join " \n", keys %modules;
print "\n";

my $successes = 0;
my $fails = 0;
foreach my $module (keys %modules) {
    
    print "Creating symbollic link for $module\n";
    unless ( -d "$modules{$module}{link_from_dir}" ) {
	my $cmd = "mkdir $modules{$module}{link_from_dir}";
	print "Making directory with command: $cmd\n";
	my $feedback;
	$feedback = try_system_command("mkdir $modules{$module}{link_from_dir}");
	print "FB: $feedback";
    }
    my $command = "ln -s $modules{$module}{target_file} $modules{$module}{link_from_dir}/$module.pm";
    print "Trying command: $command\n";
    my $feedback;
    $feedback = try_system_command("$command");
    print "FB: $feedback";
    print "Done with $module\n";
    if ( -l "$modules{$module}{link_from_dir}/$module.pm" ) { $successes++; }
    else { $fails++; }
    print "----------------------------------------------\n";
    
}
print "Successfully installed $successes modules, failed installing $fails modules\n";
print "MODULE INSTALLATION COMPLETE\n";
print "================================================\n";

print "\nMAKE CODE CHANGES\n";
print "-------------------------------------------------\n";
my $codesuccess = _make_code_changes();
print "End of code change instructions\n";
print "=================================================\n";

print "\nCHECK CONFIGURATION SETTINGS\n";
print "-------------------------------------------------\n";
#my $config_success = _check_config_settings();
print "End of instructions to check configuration settings\n";
print "==================================================\n";

print "\n. CRONJOB INSTALLATION\n";
print "-------------------------------------------------\n";

my $cronsuccess = _install_cronjobs();
if ($cronsuccess) {        
    print "Done with crontab\n";
} 
else {
    print "Problem installing crontab\n";
}


print "=================================================\n";

print "Add-on package $package_name successfully installed, congratulations\n";

exit;

############################################
# find which tables should be added
# usage: 
# my @tables_to_add = _get_package_tables($package);
############################################
sub _get_package_tables {
    my $package = shift;
    my %args = @_;

    my @package_tables;    
    return @package_tables;
    
}

##############
# add tables from initialization db
####################################
sub _add_tables {
    
    my $tables_ref = shift;
    my %args = @_;
    my @tables = @{$tables_ref};
    my ($host,$dbase) = split ':',$args{-to};
    
    die "Change the restore db commands to mimic what is in bin/setup.pl";

    my $bin_dir = "$dir/../../../bin";

#    my $restore_structure_command = "perl $bin_dir/restore_DB.pl -host $host -dbase $dbase -from -structure -force -user super_cron -password repus";
#    my $restore_db_command = "perl $bin_dir/restore_DB.pl -host $host -dbase $dbase -from $init_db -force -user super_cron -password repus";

    foreach my $table (@tables) {
	Message "*** Building table $table\nUsing structure from \nData from \n";
	my $structure_command = $restore_structure_command . " -T $table";
	my $feedback;
	$feedback = try_system_command($structure_command);
	my $data_command = $restore_db_command." -T $table";
	$feedback = try_system_command($data_command);
	Message "FB (from restore_DB.pl):\n $feedback";
	if ($feedback !~ /Error/) {
	    print "Table $table built successfully\n";
	} 
	else { print "Error building $table\n"; }
	print "-------------------------------\n";
    }

}
###########################################
# define where modules will be installed
########################
sub _get_module_links {

    my $module_dir = "$dir/../modules/";
    my %modules; ## enter module names here;

## Repeat the lines below for all the modules you would like to install

##    $module{<module>} = { 'target_file' => "$module_dir/<module>.pm", 'link_from_file'=>"$dir/../../../lib/perl/<dir>/" } 
## 
     
    return %modules;
                       
}


############################################
# install cronjobs from ../cron folder
#############################################
sub _install_cronjobs {

    ## append file in ../cron/ into crontab for this server
    my $crondir = "$dir/../cron";
    my $cron_lock = "$crondir/.cron_installed";

    if (-e $cron_lock) {print "Cronjob has been installed already...aborting cron install\nreturn 0;}

    print "Looking for cronjobs.txt ...";
    my $cron_text = "$crondir/cronjobs.txt";
    open(CRON,$cron_text) or warn "No cron text file found...\nNo changes made to crontab\n" && return 0;
    print "Found it\n";
	
    my $cron_text_temp = "$crondir/cron_jobs_temp.txt";
    print "Making temp file: $cron_text_temp\n";

    my $make_temp_file_cmd = "cp $cron_text $cron_text_temp";
    my $feedback = try_system_command($make_temp_file_cmd);
    print "Cmd: $make_temp_file_cmd\n";
    print "Error making temp file\nFB: $feedback\n" if $feedback;

    my $old_cron_txt = "old_cron.txt";
    my $old_cron_txt_cmd = "crontab -l > $crondir/$old_cron_txt";
    print "Making text from old crontab\nUsing cmd: $old_cron_txt_cmd\n";
    $feedback = try_system_command($old_cron_txt_cmd);
    print "FB: $feedback\n" if $feedback;
    my $new_cron_file = "$crondir/newcron";

    my @replacement_strings = qw( DATABASE SQL_HOST BACKUP_DATABASE BACKUP_HOST TEST_DATABASE version_name Home_dir Data_home_dir Plugins Custom Options);
    
    print "Opening file $cron_text_temp...\n";
    open(TEMP,$cron_text_temp) or warn "couldn't open temp file: $cron_text_temp\n" && return 0; 
    open(NEWCRON,">$new_cron_file") or warn "couldn't make new cron file: $new_cron_file\n" && return 0;
    open(OLDCRON,"<$crondir/$old_cron_txt") or warn "couldn't open copy of old cron file\n" && return 0;

    foreach my $line (<OLDCRON>) {
	print NEWCRON "$line";
    }

    foreach my $line (<TEMP>) {
	foreach my $config (@replacement_strings) {
	    $line =~ s/\<$config\>/$Configs{$config}/g;       
	}	
	if ($line =~ /upgrade_DB/) { ## get rid of options for upgrade_DB that are not relevant to this deployment
	    $line =~ s/\-o\s+([\-\d\>])/$1/g;
	    $line =~ s/\-O\s+([\-\d\>])/$1/g;
	    $line =~ s/\-g\s+([\-\d\>])/$1/g;	    
	}
	print NEWCRON "$line";
    }
    close(TEMP);
     
    my $make_cron_cmd = "crontab $crondir/newcron";
    print "Replacing crontab with $new_cron_file...\nCommand: $make_cron_cmd\n";
    
    $feedback = try_system_command($make_cron_cmd);
    print "FB: $feedback\n" if $feedback;

    open(CRONLOCK,">$cron_lock");
    print CRONLOCK "crontab successfully installed\n";
    close(CRONLOCK);

    return 1;

}

############################################
# make changes to code
############################################
sub _make_code_changes {

    print "Look at the file:\n$dir/README\n for instructions about hardcode changes to make\n";
    
    return 1;

}
