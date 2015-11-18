#!/usr/bin/perl
###################################################################################################################################
# Pool.pm
#
# Standard pooling
#
# $Id: Pool.pm,v 1.15 2004/10/12 22:08:03 jsantos Exp $
###################################################################################################################################
package alDente::Pool;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Pool.pm - !/usr/bin/perl

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
!/usr/bin/perl<BR>!/usr/local/bin/perl56<BR>Standard pooling<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use DBI;
use Data::Dumper;

#use Storable;

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use alDente::SDB_Defaults;
use SDB::CustomSettings;
use SDB::DB_Object;
use SDB::DBIO;
use alDente::Validation;

use RGTools::RGIO;
use SDB::HTML;

##############################
# global_vars                #
##############################
### Global variables
use vars qw($Connection);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################

##############################
# constructor                #
##############################

###########################
# Constructor of the object
###########################
sub new {
    my $this = shift;
    my $class = ref($this) || $this;

    my %args    = @_;
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);    # Database handle
    my $frozen  = $args{-frozen};
    my $encoded = $args{-encoded};

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Pool', -frozen => $frozen, -encoded => $encoded );

    if ($frozen) {
        $self->{dbc} = $dbc;
        return $self;
    }

    $self->{errors} = [];

    return $self;
}

##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
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

$Id: Pool.pm,v 1.15 2004/10/12 22:08:03 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
