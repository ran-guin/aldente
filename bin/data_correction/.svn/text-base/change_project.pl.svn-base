#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
# change_project.pl
#
# This script takes a list of library names and the name of the project which we would like to change to.

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
################################################################################

use strict;
use CGI qw(:standard);
use DBI;
use FindBin;
use Data::Dumper;

use lib $FindBin::RealBin . "/../../lib/perl/";
use lib $FindBin::RealBin . "/../../lib/perl/Core/";
use lib $FindBin::RealBin . "/../../lib/perl/Imported/";
use SDB::DBIO;

use SDB::HTML;
use SDB::CustomSettings;
use RGTools::RGIO;
use RGTools::Conversion;

use alDente::Diagnostics;    ## Diagnostics module
use alDente::SDB_Defaults;
use Getopt::Long;
##############################
# custom_modules_ref         #
##############################
##############################
# global_vars                #
##############################
use vars qw($opt_L $opt_P $opt_host $opt_dbase $opt_user);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
require "getopts.pl";

&GetOptions(
    'user=s'  => \$opt_user,
    'dbase=s' => \$opt_dbase,
    'host=s'  => \$opt_host,
    'P=s'     => \$opt_P,
    'L=s'     => \$opt_L,
);

if ( !( $opt_dbase && $opt_user && $opt_host && $opt_L && $opt_P ) ) {
    &help_menu();
}

my $host       = $opt_host;
my $dbase      = $opt_dbase;
my $login_name = $opt_user;
my $dbc        = SDB::DBIO->new( -host => $host, -dbase => $dbase, -user => $login_name );
$dbc->connect();

# Input: List of strings of the library names (eg. ('HS0182','HS0183') and the Project_ID (eg. 50) for NEW project
my @libraries = ();

@libraries = split /,/, $opt_L;

my $new_project_id = $opt_P || 0;
############
# Making sure all the inputs are defined
############

my $ok = try_system_command('whoami');
unless ( $ok =~ /aldente/ ) {
    die('You must login in as aldente to run this script.');
}

if ( @libraries == 0 ) {
    die("Error: The libraries array is empty");
}

unless ( defined($new_project_id) ) {
    die("Error: undefined new project ID");

}

if ( $new_project_id == 0 ) {
    die("Error: undefined new project ID");

}

# retrieve project_path from Projects table using ID

my ($new_project_path) = $dbc->Table_find( 'Project', 'Project_Path', "where Project_ID = $new_project_id" );
if ( !($new_project_path) ) {
    print "Error: Project Path for Project_ID is empty\n";
    die();
}

if ( $host eq $Configs{PRODUCTION_HOST} && $dbase eq $Configs{PRODUCTION_DATABASE} ) {
    print "You are about to update library destinations and project ids in Production!\n";
}
else {
    print "You are about to update project ids only in a non-Production database!\n";
}

print "Changing Project for " . scalar @libraries . " libraries to $new_project_path \(host = $host, database = $dbase\) Y/N?";
my $response = Prompt_Input();
if ( $response ne 'y' && $response ne 'Y' ) {
    die("Script terminated");
}

my $library_id;
my $library_name;
my $local_path;
$new_project_path = "$Configs{project_dir}/$new_project_path";

# check $new_project_path exists.  create it if it doesn't exist
my $ok = try_system_command("ls $new_project_path");

if ( $ok =~ /No such file or directory/ ) {

    die("Error: Destination folder $new_project_path doesn't exist");

}

# find full path of project in home/aldente/private/Projects/$new_project_path
for $library_name (@libraries) {

    if ( $library_name eq '' ) {
        next;
    }

    # find current project_path using Project_ID
    my ($result) = $dbc->Table_find( 'Project,Library', 'Project_Path', "where Library_Name = '$library_name' and Project_ID = FK_Project__ID" );
    $local_path = $result;

    if ( !($local_path) ) {
        print "Error: Project Path for Library_Name is empty\n";
        next;
    }

    $local_path = "$Configs{project_dir}/$local_path";

    # make sure the project doesn't exist in dest folder
    $ok = try_system_command("ls $new_project_path/$library_name");
    if ( $ok =~ /No such file or directory/ ) {

        if ( $host eq $Configs{PRODUCTION_HOST} && $dbase eq $Configs{PRODUCTION_DATABASE} ) {
            $ok = try_system_command("mv /$local_path/$library_name $new_project_path");
            if ( $ok ne '' ) {
                print "Error: Move Failed.  $ok\n";
                next;
            }

            $ok = try_system_command("ls $new_project_path/$library_name");
            if ( $ok =~ /No such file or directory/ ) {
                print "Error: Move Failed.  Can't find the library in the destination project: $new_project_path\n";
                next;
            }
        }

        # change the Project_ID of the Libraries to the new Project_ID
        my $fields = 'FK_Project__ID';

        $dbc->Table_update( -table => 'Library', -fields => $fields, -values => $new_project_id, -condition => "WHERE Library_Name = '$library_name'", -debug => 0 );
        print "Update successful...changed library $library_name to new project id $new_project_id\n";
    }
    else {
        print "Warning: Project for Library $library_name not updated because the folder already exists\n";
        next;
    }

}

sub help_menu {
    print "\nPlease run the script like this:\n\n";
    print "$0\n";
    print "  \t-host  (e.g. lims05)\n";
    print "  \t-dbase (e.g. seqtest)\n";
    print "  \t-user  (e.g. aldente_admin)\n";
    print "  \t-P     (New project id e.g. 548)\n";
    print "  \t-L     (List of libraries e.g. A23456,A23457,A23458)\n";
    exit(0);
}
