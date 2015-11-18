#!/usr/local/bin/perl

use lib "/usr/local/ulib/prod/alDente/lib/perl/Imported";

use strict;
use DBI;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

#use RGTools::RGIO;

use Getopt::Long;
&GetOptions(
	    ## 'parameter_with_value=s' => \$opt_p1,
	    ## 'parameter_as_flag'      => \$opt_p2,
	    );

# my $host = 'lims02';
# #my $dbase = 'alDente_unit_test_DB';
# my $dbase = 'seqtest';
# my $user = 'cron';
# my $pwd;
# 
# require SDB::DBIO;
# my $dbc = new SDB::DBIO(
#                         -host     => $host,
#                         -dbase    => $dbase,
#                         -user     => $user,
#                         -password => $pwd,
#                         -connect  => 1,
#                         );
# 

my @backup_dirs = ('/home/sequence/archive/solexa/1/data2', '/home/sequence/archive/solexa/1/data1');
my $target_dir =   '/home/sequence/solexa';

foreach my $backup_dir (@backup_dirs) {
    chdir "$backup_dir";
    my @fc_dirs = glob("*FC????");

    foreach my $fc_dir (@fc_dirs) {
	chdir "$backup_dir/$fc_dir";
	print "FCDIR $fc_dir\n";
	system("mkdir $target_dir/$fc_dir");

	if ($backup_dir =~ /data2/) {
	    my @all_Ls = glob("*.L?");
	    print "DIR: $fc_dir\n";
	    my @lane_dirs;
	    foreach my $L (@all_Ls) {
		if (-d ($L)) {push (@lane_dirs, $L);}
	    }

	    foreach my $lane_dir (@lane_dirs) {
		system("mkdir $target_dir/$fc_dir/$lane_dir");
		my $bust_dir = '';
#		print "Target: 	$target_dir/$fc_dir/$lane_dir \n";
		chdir "$backup_dir/$fc_dir/$lane_dir/Data/current";

#		$bust_dir = glob("Bustard*");

#        `chmod 775 $bust_dir`;
		print "BACK: $backup_dir/$fc_dir/$lane_dir/Data/current/ \n";

		chdir "$backup_dir/$fc_dir/$lane_dir/Data/current/";
#		chdir "$bust_dir";
		print "PWD1" . `pwd`;
		my @files = glob("Bustard*/*.txt");
		chdir "$target_dir/$fc_dir/$lane_dir";
		print "PWD2" . `pwd`;

		foreach my $file (@files) {
		    $file =~ s/^Bust.*\///;
		    unless ($file =~ /sig/ || (-e "$file.bz2") ) {			
			print " $backup_dir/$fc_dir/$lane_dir/Data/current/Bustard*/$file \n";		
			system("bzip2 -c -z -k $backup_dir/$fc_dir/$lane_dir/Data/current/Bustard*/$file > $file.bz2 ");
		    }

		}
		
	    }
	}
	
	if ($backup_dir =~ /data1/) {
	    chdir "Data";
	    my @fire_dirs = glob("C1*");

	    foreach my $fire_dir (@fire_dirs) {
		system("mkdir $target_dir/$fc_dir/$fire_dir");	
		chdir "$backup_dir/$fc_dir/Data/$fire_dir/";
#		my $bust_dir = glob("Bustard*");
		system("mkdir $target_dir/$fc_dir/$fire_dir/Bustard");

#		chdir "$bust_dir";
		my @files = glob("Bustard*/*.txt");
		chdir "$target_dir/$fc_dir/$fire_dir/Bustard";
		print `pwd`;
		foreach my $file (@files) {
		    $file =~ s/^Bust.*\///;
		    unless ($file =~ /sig/  || (-e "$file.bz2")  ) {
			print " $backup_dir/$fc_dir/Data/$fire_dir/Bustard*/$file \n";		
			system("bzip2 -c -z -k $backup_dir/$fc_dir/Data/$fire_dir/Bustard*/$file > $file.bz2 ");
		    }

		}

		
	    }
	}
    }
}

    exit;
