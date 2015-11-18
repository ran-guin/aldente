#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
##############################
# Modules                    #
##############################

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use Data::Dumper;
use Getopt::Std;

use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::DBIO;
use SDB::Installation;
use SDB::CustomSettings qw(%Configs);
use vars qw($opt_version $opt_variation $opt_patches);
use Getopt::Long;
##############################
# Input                      #
##############################

&GetOptions(
    'version=s'   => \$opt_version,
    'variation=s' => \$opt_variation,
    'patches=s'   => \$opt_patches
);
my $version   = $opt_version;
my $variation = $opt_variation;
my $patches   = $opt_patches;

unless ($version) {
    Message "No version provided";
    exit;
}

my $host  = $Configs{TEST_HOST};
my $dbase = $Configs{TEST_DATABASE};
my $user  = 'viewer';
my $pwd   = 'viewer';

my $dbc = new SDB::DBIO(
    -host    => $host,
    -dbase   => $dbase,
    -user    => $user,
    -connect => 1,
);

my $Report = Process_Monitor->new( -variation => $variation );

##############################
#  Logic                     #
##############################
if ($patches) {
    my $quiet = 0;                                                       #1 if you do not want to have output Messages on the screen
    my $install = new SDB::Installation( -simple => 1, -dbc => $dbc );
    $install->SDB::Installation::update_patches( -version => $version, -quiet => $quiet );
    $Report->completed();
    $Report->DESTROY();
    exit;
}

my $search_command = "/usr/local/bin/svn update /opt/alDente/versions/" . $version;
my $feedback       = try_system_command($search_command);
my @results        = split "\n", $feedback;
my @updated;
my @deleted;
my @conflicts;
my @added;

for my $found (@results) {
    if    ( $found =~ /^U(.+)/ ) { push @updated, $1 }
    elsif ( $found =~ /^D(.+)/ ) { push @deleted, $1 }
    elsif ( $found =~ /^A(.+)/ && !( $found =~ /^At(.+)/ ) ) { push @added, $1 }
    elsif ( $found =~ /^C(.+)/ ) { push @conflicts, $1 }
}

for my $conflict (@conflicts) {
    $Report->set_Error("Conflict in file $conflict");
}

my $a_count = @added;
my $d_count = @deleted;
my $u_count = @updated;
$Report->set_Message("$a_count files added");
$Report->set_Message("$d_count files deleted");
$Report->set_Message("$u_count files updated");
$Report->completed();
$Report->DESTROY();

exit;

