#!/usr/local/bin/perl
##############################
# perldoc_header             #
##############################
#
# add_lims_default_users.pl
#
# This script addes a list of LIMS default users with appropriate privileges
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

use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
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
use vars qw($opt_file $opt_user);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
use Getopt::Long;

&GetOptions(
    'user=s' => \$opt_user,
    'file=s' => \$opt_file,
);

if ( !( $opt_user && $opt_file ) ) {
    &help_menu();
}

my $file  = $opt_file;
my $login = $opt_user;

require YAML;
my $hash = YAML::LoadFile($file);

#print Dumper $hash;

foreach my $user ( keys %$hash ) {

    #print Dumper $hash->{$user};
    &add_lims_user( -user => $user, -detail => $hash->{$user} );

}

sub add_lims_user {
    my %arg    = @_;
    my $user   = $arg{-user};
    my $detail = $arg{-detail};

    #print Dumper $detail;

    my $access   = $detail->{'access'};
    my $password = $detail->{'password'};

    #################################################################
    # Access Levels:
    #   FULL:   all privileges
    #   SUPER:  all privileges minus the following
    #               - Grant, Event
    #   ADMIN:  STD privileges plus the following
    #               - File, Create_tmp_table, Repl_slave, Repl_client
    #   STD:    Select, Insert, Update, Delete
    #   RO:     Select only
    #################################################################

    my @access_modes = ( 'FULL', 'SUPER', 'ADMIN', 'STD', 'RO' );

    foreach my $mode (@access_modes) {
        if ( $access->{$mode} ) {
            &add_user_to_dbs( -user => $user, -access => $mode, -db_list => $access->{$mode}, -password => $password );
        }
    }
}

sub add_user_to_dbs {
    my %arg    = @_;
    my $user   = $arg{-user};
    my $access = $arg{-access};
    my $dbs    = $arg{-db_list};
    my $pwd    = $arg{-password};

    #print Dumper $dbs;

    foreach my $db (@$dbs) {

        #print Dumper $db;
        &add_user_to_db( -user => $user, -db => $db, -access => $access, -password => $pwd );
    }
}

sub add_user_to_db {
    my %arg    = @_;
    my $user   = $arg{-user};
    my $access = $arg{-access};
    my $db     = $arg{-db};
    my $pwd    = $arg{-password};

    my ( $host, $database ) = split( ':', $db );
    if ( $host =~ /^<(.+)>$/ ) {

        #print Dumper $Configs{$1};
        $host = $Configs{$1};
    }
    if ( $database =~ /^<(.+)>$/ ) {
        $database = $Configs{$1};
    }

    ## User privilege types
    my @user_priv_full  = ( '%', $user, $pwd, 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', '', '', '', '', 0, 0, 0, 0, '', '' );
    my @user_priv_super = ( '%', $user, $pwd, 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'N', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'N', 'Y', 'Y', '', '', '', '', 0, 0, 0, 0, '', '' );
    my @user_priv_adm   = ( '%', $user, $pwd, 'Y', 'Y', 'Y', 'Y', 'N', 'N', 'N', 'N', 'N', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'Y', 'N', 'N', 'Y', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '', '', '', '', 0, 0, 0, 0, '', '' );
    my @user_priv_std   = ( '%', $user, $pwd, 'Y', 'Y', 'Y', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '', '', '', '', 0, 0, 0, 0, '', '' );
    my @user_priv_ro    = ( '%', $user, $pwd, 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', '', '', '', '', 0, 0, 0, 0, '', '' );

    ## db specific privilege types
    my @db_priv_full  = ( '%', $database, $user, 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y' );
    my @db_priv_super = ( '%', $database, $user, 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'N', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'N', 'Y' );
    my @db_priv_adm   = ( '%', $database, $user, 'Y', 'Y', 'Y', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N' );
    my @db_priv_std   = ( '%', $database, $user, 'Y', 'Y', 'Y', 'Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N' );

    my $dbc = SDB::DBIO->new( -host => $host, -dbase => 'mysql', -user => $login );
    $dbc->connect();

    my ($exist) = $dbc->Table_find( 'user', 'User', "WHERE User = '$user'" );
    my $exist_db = 0;

    if ($exist) {
        if ($database) {
            ($exist_db) = $dbc->Table_find( 'db', 'User', "WHERE User = '$user' AND Db = '$database'" );
            if ($exist_db) {
                print "\nDatabase user $user already exists on $host for $database\n";
                return;
            }
        }
        else {
            print "\nDatabase user $user already exists on $host\n";
            return;
        }
    }

    my @user_fields = qw(Host User Password Select_priv Insert_priv Update_priv Delete_priv Create_priv Drop_priv Reload_priv Shutdown_priv
        Process_priv File_priv Grant_priv References_priv Index_priv Alter_priv Show_db_priv Super_priv
        Create_tmp_table_priv Lock_tables_priv Execute_priv Repl_slave_priv Repl_client_priv
        Create_view_priv Show_view_priv Create_routine_priv Alter_routine_priv Create_user_priv
        Event_priv Trigger_priv Create_tablespace_priv ssl_type ssl_cipher x509_issuer x509_subject
        max_questions max_updates max_connections max_user_connections plugin authentication_string);

    my @db_fields = qw(Host Db User Select_priv Insert_priv Update_priv Delete_priv Create_priv Drop_priv Grant_priv
        References_priv Index_priv Alter_priv Create_tmp_table_priv Lock_tables_priv Create_view_priv
        Show_view_priv Create_routine_priv Alter_routine_priv Execute_priv Event_priv Trigger_priv);

    my $user_priv;

    #print Dumper   \@user_fields;
    #print Dumper scalar(@user_fields);
    if ( ( $access eq 'RO' ) || ($database) ) {
        $user_priv = \@user_priv_ro;
    }
    elsif ( $access eq 'FULL' ) {
        $user_priv = \@user_priv_full;
    }
    elsif ( $access eq 'STD' ) {
        $user_priv = \@user_priv_std;
    }
    elsif ( $access eq 'SUPER' ) {
        $user_priv = \@user_priv_super;
    }
    elsif ( $access eq 'ADMIN' ) {
        $user_priv = \@user_priv_adm;
    }

    my $user_field_list = Cast_List( -list => \@user_fields, -to => 'string', -autoquote => 0 );
    my $db_field_list   = Cast_List( -list => \@db_fields,   -to => 'string', -autoquote => 0 );

    my $user_priv_list = Cast_List( -list => $user_priv, -to => 'string', -autoquote => 1 );
    my $added;

    if ( !$exist ) {
        $added = $dbc->Table_append( 'user', "$user_field_list", "$user_priv_list", -no_triggers => 1, -autoquote => 0 );
    }
    else {
        $added = 1;
    }

    #print Dumper $user_field_list;
    #print Dumper $user_priv_list;
    #print Dumper $added;
    if ($added) {
        if ($database) {
            my $db_priv;

            if ( $access eq 'FULL' ) {
                $db_priv = \@db_priv_full;
            }
            elsif ( $access eq 'SUPER' ) {
                $db_priv = \@db_priv_super;
            }
            elsif ( $access eq 'ADMIN' ) {
                $db_priv = \@db_priv_adm;
            }
            elsif ( $access eq 'STD' ) {
                $db_priv = \@db_priv_std;
            }

            my $db_priv_list = Cast_List( -list => $db_priv, -to => 'string', -autoquote => 1 );

            #print Dumper $db_full_list;
            $added = $dbc->Table_append( 'db', "$db_field_list", "$db_priv_list", -no_triggers => 1, -autoquote => 0 );
            print "\nAdded $user to $host with $access access to $database\n\n";
        }
        else {
            print "\nAdded $user to $host with $access access\n\n";
        }
    }

    my $flush   = 'flush privileges;';
    my $reponse = $dbc->dbh()->do(qq{$flush});
}

sub help_menu {
    print "\nPlease run the script like this:\n\n";
    print "$0\n";
    print "  \t-file  (e.g. conf/lims_default_users.yml)\n";
    print "  \t-user  (e.g. aldente_admin)\n";
    exit(0);
}
