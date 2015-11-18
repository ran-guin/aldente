################################################################################
# Tube.pm
#
# This module handles Container (Plate) based functions
#
###############################################################################
package alDente::Tube;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Tube.pm - This module handles Container (Plate) based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (Plate) based functions<BR>

=cut

##############################
# superclasses               #
##############################
use base alDente::Container;
# @ISA = qw(alDente::Container);

##############################
# system_variables           #
##############################
#require Exporter;
#@EXPORT_OK = qw(home_tube);

##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;
use RGTools::Barcode;

##############################
# custom_modules_ref         #
##############################
use alDente::Library;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::ReArray;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::Conversion;

##############################
# global_vars                #
##############################
use vars qw($project_dir $Connection $current_plates);
use vars qw($testing);

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
    #
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id         = $args{-id};
    my $ids        = $args{-ids};
    my $plate_id   = $args{-plate_id} || 0;
    my $attributes = $args{-attributes};                                                              ## allow inclusion of attributes for new record
    my $encoded    = $args{-encoded} || 0;                                                            ## reference to encoded object (frozen)
    my $quick_load = $args{-quick_load};                                                              ## exclude child tables and left joins

    my ($class) = ref($this) || $this;

    my $self = alDente::Container->new( -dbc => $dbc, -encoded => $encoded, -type => 'Tube', -quick_load => $quick_load );

    bless $self, $class;

    $self->{dbc} = $dbc;
    $self->add_tables('Tube');

    $self->{type} = 'Tube';
    if ($plate_id) {
        $self->{plate_id} = $plate_id;
        $self->primary_value( -table => 'Plate', -value => $plate_id );    ## same thing as above..
        $self->load_Object( -type => 'Tube', -plate_id => $plate_id, -quick_load => $quick_load );
        $self->{id} = $self->get_data("Tube_ID");
    }
    elsif ($id) {
        $self->{id} = $id;                                                 ## list of current plate_ids
        $self->primary_value( -table => 'Tube', -value => $id );           ## same thing as above..
        $self->load_Object( -type => 'Tube', -quick_load => $quick_load, -type_id => $id );
        $self->{plate_id} = $self->get_data('Plate_ID');

    }
    elsif ($attributes) {

        #	$self->add_Record(-attributes=>$attributes);
    }
    return $self;
}

##############################
# public_methods             #
##############################

################
sub home_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );

    Call_Stack();

    return "This method has been deprecated... standardize by simply calling \$Plate->View->std_home_page() - edit Container::display_record_views as required if adjustments required";

    return alDente::Container_Views->Tube_home_page( $self, %args );
}

################
sub add_Plate {
################
    my $self = shift;
    my %args = &filter_input( \@_ );
    if ( $args{ERRORS} ) { Message("Input Errors Found: $args{ERRORS}"); return; }

    my $input = $args{-input};
    if ($input) {
        foreach my $key ( keys %{$input} ) {
            $args{"-$key"} = $input->{$key};
        }
    }
    my $returnval = $self->SUPER::add_Plate(%args);

    return $returnval;
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

$Id: Tube.pm,v 1.39 2004/11/25 23:48:49 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
