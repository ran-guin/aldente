#!/usr/local/bin/perl

################################################################################
#
# restore_RDB.pl
#
# This program restore the MySQL database with replication implemented
#
################################################################################

use strict;
use DBI;
use Data::Dumper;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

 
use SDB::CustomSettings;
use RGTools::RGIO;
use alDente::SDB_Defaults;  

##############################
use vars qw($opt_D $opt_u $opt_h $opt_f $opt_b);
use vars qw($Dump_dir);

require "getopts.pl";
&Getopts('D:u:hf:b');

if ($opt_h) {
    print_help_info();
    exit;
}

my $m_dbase = $opt_D;                  # Master database
my $source = $opt_f;
my $m_host = $Defaults{mySQL_HOST};    # Master host
my $user = $opt_u;                     # Login user

my $bin_log_only = $opt_b;             # Only apply bin_log files (assumes full backup already complete)...

# Resolve master dbase into host if necessary
if ($m_dbase =~ /([\w\-]*):([\w\-]*)/) {
    $m_host = $1;
    $m_dbase = $2;
}

my $s_host;
my $s_dbase;
if ($source =~ /([\w\-]*):([\w\-]*)/) {       ## specify slave host : database (if ONLY restoring slave)
    $s_host = $1;
    $s_dbase = $2;
} 
elsif ($source) {                             ## assume slave database has same name, but on different host 
    $s_host = $source;
    $s_dbase = $m_dbase;
}
else {                                        ## restore both together...
    $s_host = $m_host; 
    $s_dbase = $m_dbase;
}

my $password = Prompt_Input(-prompt=>'Password: >',-type=>'password');
my $confirmed;

unless ($m_host && $m_dbase && $user && $password) {
    print_help_info();
    exit;
}


restore();


###############################################
# Performs the restore on both master and slave
###############################################
sub restore {
    # Locate the backups
    my ($full_dump, $binlog_backup) = locate_backups();

    # Compare the backups and figure out what kind of restore we want to do
    my ($full_dump_datetime) = $full_dump =~ /(.+)-full/;
    my ($binlog_backup_datetime) = $binlog_backup =~ /(.+)-binlog/;

    if ($bin_log_only) {
	binlog_restore(-binlog_dir=>$binlog_backup,-host=>$m_host,-dbase=>$m_dbase);	
    }
    elsif ($full_dump_datetime gt $binlog_backup_datetime) { # The full dump is more up-to-date
	print "\n>>No binary logs found after latest full backup dump. Restoring from dumps...\n";
	# Note that the replication process will also restore the slave database automatically.....
	dump_restore(-dump_dir=>$full_dump,-host=>$m_host,-dbase=>$m_dbase);
    }
    elsif ($full_dump_datetime lt $binlog_backup_datetime) { # The full dump is not most up-to-date. Require apply binlogs to it after the restore.
	print "\n>>Binary logs found after latest full backup dump. Restoring from dumps and then applying binary logs...\n";	
	# Note that the replication process will also restore the slave database automatically.....
	dump_restore(-dump_dir=>$full_dump,-host=>$m_host,-dbase=>$m_dbase);
	binlog_restore(-binlog_dir=>$binlog_backup,-host=>$m_host,-dbase=>$m_dbase);
    }
}

################################
# Locate the latest backups
#
# Return an arrayref of:
# - The latest full dump dir
# - The latest binlog backup dir
################################
sub locate_backups {
    my $search_dir = "$Dump_dir/$s_host.$s_dbase";   ## search for source host : database

    my $full_dump;
    my $binlog_backup;

    print "\n>>Searching for the latest full backup dump and latest binary log backups (@{[date_time()]})...\n";
    my $cmd = "ls -r $search_dir";
    my $fback = try_system_command($cmd);
    foreach my $dir (split /\n/, $fback) {
	print ">Searching under '$dir' (@{[date_time()]})...\n";

	# Searching for full backups
	$cmd = "find $search_dir/$dir -name '*-full' | sort -r";
	print ">Trying '$cmd'...\n";
	my $fback2 = try_system_command($cmd);
	if ($fback2) {
	    my @full_dumps = split(/\n/, $fback2);
	    $full_dump = $full_dumps[0];
	    if ($full_dump && $binlog_backup) {last;}
	}

	# Searching for binlog backups
	$cmd = "find $search_dir/$dir -name '*-binlog' | sort -r";
	print ">Trying '$cmd'...\n";
	my $fback2 = try_system_command($cmd);
	if ($fback2) {
	    my @binlog_backups = split(/\n/, $fback2);
	    $binlog_backup = $binlog_backups[0];
	    if ($full_dump && $binlog_backup) {last;}
	}
    }

    print ">Found latest full backup dump at '$full_dump'\n"; 
    print ">Found latest binary log backups at '$binlog_backup'\n"; 

    return ($full_dump, $binlog_backup);
}

##################################
# Peforms a dump restore
##################################
sub dump_restore {
    my %args = @_;

    my $dump_dir = $args{-dump_dir};
    my $host = $args{-host};
    my $dbase = $args{-dbase};

    #### Temporary proection ####
    if ($dbase eq 'sequence') {
	unless ($user =~/admin/) { print "*** Restore of 'sequence' database not allowed by $user. *** \n"; exit; }
	unless ($confirmed=~/^y/i) {
	    $confirmed = Prompt_Input(-prompt=>"** Ensure Master database is locked prior to continuing... ok ? ");
	    unless ($confirmed =~/^y/i) { exit; }
	}
    }

    # Get the list of tables to be restored
    my $cmd = "ls $dump_dir";
    my $fback = try_system_command($cmd);
    my @dump_files = split /\n/, $fback;

    # Figure out the tables
    my @tables;
    my %large_tables;
    foreach my $dump_file (@dump_files) {
	my ($table,$index) = $dump_file =~ /^(\w+)\.(\d*)\.?sql/;
	unless (grep /^$table$/, @tables) {push(@tables, $table)}
	if ($index) {$large_tables{$table} = 1} # Keep track of the large tables
    }

    my $prompt = "-"x80 . "\nThe following tables in the database '$host:$dbase' will be restored.\n" . "-"x80 . "\n" . join("\n",@tables) . "\n" . "-"x80 . "\nType y to continue";
    my $ans = Prompt_Input(-prompt=>$prompt);
    unless ($ans =~ /^y$/i) {return}

    my $mysql_command = qq{$mysql_dir/mysql -u $user --password="$password" -h $host $dbase};
    print "\n>>Restoring database '$host:$dbase' (@{[date_time()]})...\n"; 

T:  foreach my $table (@tables) {
        #### Special handling for very LARGE tables.. (separate into multiple files)...####
	if (exists $large_tables{$table}) {
	    print ">>Restoring table '$table' in chunks (@{[date_time()]})...\n";   
	    my $index = 1;
	    while (-f "$dump_dir/$table.$index.sql") {
		print ">>Restoring index $index (@{[date_time()]})...\n"; 
		my $command = qq{$mysql_command < $dump_dir/$table.$index.sql};
		print ">Trying '$command'...\n";
		my $ok = try_system_command(qq{$command});
		#If error out then move on to the next table.
		if ($ok =~ /ERROR/) { print "\n$ok\n\n"; next T; }

		$index++;
	    }
	    $index--;
	} else {
	    print ">>Restoring table '$table' (@{[date_time()]})...\n"; 
	    if (-f "$dump_dir/$table.sql") {
		my $command = qq{$mysql_command < $dump_dir/$table.sql};
		print ">Trying '$command'...\n";
		my $ok = try_system_command($command);
		#If error out then move on to the next table.
		if ($ok =~ /ERROR/) { print "\n$ok\n\n"; next T; }
	    } else { 
		print "ERROR: '$dump_dir/$table.sql' not found.\n"; 
	    }
	}
	print ">>Optimizing table '$table' (@{[date_time()]})...\n"; 	
	try_system_command(qq{$mysql_command -e "OPTIMIZE TABLE $table"});
    }

    print "\n>>Restore from dumps completed. (@{[date_time()]})\n";
}

##################################
# Applys binary logs to database
##################################
sub binlog_restore {
    my %args = @_;

    my $binlog_dir = $args{-binlog_dir};
    my $host = $args{-host};
    my $dbase = $args{-dbase};

    #### Temporary protection ####
    if ($dbase eq 'sequence') {
	unless ($user =~/admin/) { print "*** Restore of 'sequence' database not allowed by $user. *** \n"; exit; }
	unless ($confirmed=~/^y/i) {
	    $confirmed = Prompt_Input(-prompt=>"** Has full backup already been accomplished.. ok ? ");
	    unless ($confirmed =~/^y/i) { exit; }
	}
    }

    # Read the binary log index file to see what binary logs we need
    my ($index_file) = glob("$binlog_dir/*.index");

    if (-f $index_file) {
	my @binlogs;
	print ">>Reading binary log index file '$index_file' (@{[date_time()]})...\n"; 
	open(INDEX,$index_file);
	while (<INDEX>) {
	    my ($binlog) = $_ =~ /.*\/([^\/]+)$/;
	    chomp($binlog);
	    push(@binlogs,"$binlog_dir/$binlog");
	}
	close(INDEX);
	
	my $list1 = join "'\n'", @binlogs;
	my $list2 = join ' ', @binlogs;
	print ">>Applying binary log files:\n'$list1'\n**\n(@{[date_time()]})...\n"; 
	my $command = "$mysql_dir/mysqlbinlog $list2 | $mysql_dir/mysql -u $user --password='$password' -h $host $dbase";
	print ">Trying command '$command' (@{[date_time()]})...\n";
#	print try_system_command($command);
	print 
    }
    else {
	print "ERROR: Index file for binary logs not found.\n";
	return;
    }

    print "\n>>Finished applying binary logs. (@{[date_time()]})\n ** Restart Slave and Master if necessary **\n\n";
}


#########################
sub print_help_info {
#########################
print<<HELP;

File:  restore_RDB.pl
####################
This script performs a restore of the replicated database. Note that if the restore is done to a master database, the slave database will be automatically restored as well by MySQL's replication mechanism.

Options:
##########

------------------------------
1) Database login information:
------------------------------
-D     The database to be restored. Format is 'host:database' (e.g. -D lims02:sequence)
-u     User for database login (e.g. -u bob)

-f (from source)   In case of exceptional case where Slave needs to be restored separately from a master database of another name...
-b     Apply binary update logs only (Assumes full update from the morning is already complete).

Note: This script will actually locate the latest full backup dump and the latest binary logs backup. Afterwards, a comparison will be done between the two.
- If latest full backup dump is created later than the latest binary logs backup, then the restore will simply restore the dumps.
- If latest full backup dump is created earlier than the latest binary logs backup, then the restore will restore the dumps and then apply the binary logs using the mysqlbinlog program.

HELP
}
