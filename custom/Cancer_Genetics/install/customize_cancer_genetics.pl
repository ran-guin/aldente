## This script is run directly after initializing the core database
## It customizes the database schema and subclasses of Cancer Genetics group

use strict;
use warnings;
use lib "/opt/alDente/versions/chilchey/lib/perl";
use RGTools::RGIO;

my $dbase = 'cancer_genetics';
my $user = 'aldente_admin';
my $pwd = 'etnedla';
my $host = 'limsdev02';

my $sqlconnect = "mysql -h $host -u $user -p" . "$pwd" . " $dbase"; 

my $fback;
my @sql_files = split ("\n", try_system_command("ls ../sql/*.mysql"));
my $sql_list = join "\n", @sql_files;

print "SQL Login command: " . "$sqlconnect\n";
print '----------------------------------------------'."\n";
print "SQL Files to be run:\n" . "$sql_list\n";
print '----------------------------------------------'."\n";


foreach my $sqlfile (@sql_files) {
    print "Opening file:" . "$sqlfile\n";
    print "Trying command: $sqlconnect < $sqlfile\n";
    $fback = try_system_command("$sqlconnect < $sqlfile");
    print "FEEDBACK: $fback\n";
    print "Closing file: $sqlfile\n \n";
}

print "Cancer Genetics LIMS now fully functional\n"."Have a great day\n";
