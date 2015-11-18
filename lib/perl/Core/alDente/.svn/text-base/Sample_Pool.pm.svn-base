#!/usr/bin/perl
###################################################################################################################################
# Pool.pm
#
# Standard pooling
#
# $Id: Sample_Pool.pm,v 1.6 2004/10/12 22:08:22 jsantos Exp $
###################################################################################################################################
package alDente::Sample_Pool;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(alDente::Pool);

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
use alDente::Sample;
use alDente::Pool;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DB_Object;
use SDB::DBIO;
use SDB::HTML;
use RGTools::RGIO;

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

my %Pool_Alias;
$Pool_Alias{pool_id}     = "Pool_ID";
$Pool_Alias{description} = "Pool_Description";
$Pool_Alias{employee_id} = "FK_Employee__ID";
$Pool_Alias{date}        = "Pool_Date";
$Pool_Alias{comments}    = "Pool_Comments";
$Pool_Alias{type}        = "Sample_Pool_Type";

#$Pool_Alias{pipeline} = "Pipeline";

my %PoolSample_Alias;
$PoolSample_Alias{well}      = "PoolSample.Well";
$PoolSample_Alias{plate_id}  = "PoolSample.FK_Plate__ID";
$PoolSample_Alias{sample_id} = "PoolSample.FK_Sample__ID";

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
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);
    my $frozen  = $args{-frozen};
    my $encoded = $args{-encoded};

    my $self = $this->SUPER::new( -dbc => $dbc, -frozen => $frozen, -encoded => $encoded );

    if ($frozen) {
        $self->{dbc} = $dbc;
        return $self;
    }

    $self->add_tables('Sample_Pool');

    $self->{errors} = [];

    return $self;
}

##############################
# public_methods             #
##############################

################################
# Create sample pool
################################
sub create {
############
    my $self = shift;
    my %args = @_;

    my $employee_id = $args{-employee_id};
    my $date        = $args{-date} || today();
    my $target      = $args{-target};
    my $details     = $args{-details};

    unless ( $target =~ /^\d+$/ ) {
        Message("ERROR: Target for pooling must be a single container. (current target = '$target')");
        return 0;
    }
    eval {

        # Populate Pool and Sample_Pool table
        my @fields = ( 'FK_Employee__ID', 'Pool_Date', 'Pool_Type', 'FKTarget_Plate__ID' );
        my %values;
        $values{1} = [ $employee_id, $date, 'Sample', $target ];
        my $retval = $self->{dbc}->smart_append( -tables => 'Pool,Sample_Pool', -fields => \@fields, -values => \%values, -autoquote => 1 );

        my $new_poolid = $retval->{Pool}{newids}[0];
        die('ERROR: Failed to create new pool') unless ( $new_poolid =~ /\d+/ );

        # Populate PoolSammple records
        @fields = ( 'FK_Pool__ID', 'FK_Plate__ID', 'Sample_Quantity_Units', 'Sample_Quantity', 'FK_Sample__ID' );
        my $i = 1;
        undef(%values);

        my $sample = alDente::Sample->new( -dbc => $self->{dbc} );
        foreach my $plate ( sort { $a <=> $b } keys %$details ) {
            my $sample_id = $sample->get_sample_id( -plate_id => $plate, -plate_type => 'Tube' );
            $values{$i} = [ $new_poolid, $plate, $details->{$plate}{units}, $details->{$plate}{quantity}, $sample_id ];
            $i++;
        }

        $retval = $self->{dbc}->smart_append( -tables => 'PoolSample', -fields => \@fields, -values => \%values, -autoquote => 1 );

        my $new_poolsamples = $retval->{PoolSample}{newids};
        die('ERROR: Failed to track source of pooling.') unless ( int(@$new_poolsamples) >= 1 );

        Message("New sample pooling successfully created.");
    };
    if ($@) { print $@; $self->dbc->transaction->error($@) if $self->dbc->transaction; return 0; }
    return 1;
}

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

$Id: Sample_Pool.pm,v 1.6 2004/10/12 22:08:22 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
