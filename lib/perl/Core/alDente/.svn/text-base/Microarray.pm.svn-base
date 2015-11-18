################################################################################
# Microarray.pm
#
# This module handles Microarray-based functions
#
###############################################################################
package alDente::Microarray;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Array.pm - This module handles Microarray based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Microarray based functions<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DB_Object);

##############################
# standard_modules_ref       #
##############################

use CGI qw(:standard);
use Data::Dumper;
use URI::Escape;
use RGTools::Barcode;
use Benchmark;
use strict;

##############################
# custom_modules_ref         #
##############################
use alDente::Form;
use alDente::Container_Views;

use SDB::DB_Object;
use SDB::Session;
use SDB::DBIO;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw($current_plates $Sess);
use vars qw( $Connection %Std_Parameters);
use vars qw(%Benchmark);
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

########
sub new {
########
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my $dbc  = $args{-dbc}  || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id   = $args{-id}   || $args{-microarray_id};
    my $type = $args{-type} || 'Genechip';                                                       ## type of Microarray
    my $stock_id = $args{-stock_id};

    if ( $stock_id && !$id ) {
        ($id) = $Connection->Table_find( "Microarray", "Microarray_ID", "WHERE FK_Stock__ID=$stock_id" );
    }

    if ( $id =~ /(\d+),/ ) { $id = $1 }                                                          ## get the first in the list if more than one...

    my $frozen  = $args{-frozen}  || 0;
    my $encoded = $args{-encoded} || 0;                                                          ## reference to encoded object (frozen)
    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => "Stock,Microarray,$type", -frozen => $frozen, -encoded => $encoded, -dbc => $dbc );
    my ($class) = ref($this) || $this;
    $self->{dbc} = $dbc;
    bless $self, $class;

    if ( $encoded || $frozen ) { return $self }

    $self->{dbc} = $dbc;

    if ($id) {
        $self->{id} = $id;                                                                       ## list of current plate_ids
        $self->primary_value( -table => 'Microarray', -value => $id );                           ## same thing as above..
        $self->load_Object();
    }

    return $self;
}

############
# Microarray homepage
############
sub home_page {
############
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->{dbc} || $args{-dbc};

    my $type = $self->value('Microarray.Microarray_Type');
    my $id   = $self->value('Microarray.Microarray_ID');

    print alDente::Form::start_alDente_form($dbc);
    print hidden( -name => "id", -value => $id );
    print submit( -name => 'Barcode_Event', -value => 'Re-Print Microarray Barcode', -class => "Std" ) . br() . br();
    if ( $type && $id ) {
        print $self->display_Record();
    }

    print end_form();
}

return 1;
