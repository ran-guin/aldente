#!/usr/local/bin/perl
###################################################################################################################################
# Purpose:	
#			
# 			
# Notes:	
# 			
###################################################################################################################################
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

*.pl - !/usr/local/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>


=cut

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use Data::Dumper;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use Getopt::Long;
use File::Path;

### Reference to alDente modules
use RGTools::RGIO;
use RGTools::Process_Monitor;
use SDB::CustomSettings;
use SDB::DBIO;
use alDente::Subscription;

##############################
# global_vars                #
##############################
### Global variables
use vars qw(%Configs $opt_database $opt_host $opt_debug);

&GetOptions(
    'database=s'    => \$opt_database,
    'host=s'        => \$opt_host,
    'debug'         => \$opt_debug,
);

##############################
# modular_vars               #
##############################
my $debug            = $opt_debug;    

##############################
# constants                  #
##############################


##############################
### LOGIC
##############################

my $host     = $opt_host        || $Configs{DEV_HOST};
my $dbase    = $opt_database    || $Configs{DEV_DATABASE};
my $password = 'viewer';
my $user     = 'viewer'; 

my $dbc     = SDB::DBIO->new( -dbase => $dbase, -user => $user, -password => $password, -host => $host, -connect => 1 );
my $Report   = Process_Monitor->new();

$Report->completed();
$Report->DESTROY();

exit;
##############################
### END OF LOGIC
##############################




##############################
### Internal Functions
##############################

#############################
sub _helper { 
#############################
# Description:
#
# Usage: 
#
#############################
    my %args            = filter_input( \@_);
    my $value           = $args{-value};
    my $dbc             = $args{-dbc};

    return;
}



##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

##############################

##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>


=cut 
