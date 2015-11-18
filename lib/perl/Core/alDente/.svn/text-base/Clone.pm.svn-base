################################################################################
# Clone.pm
#
# This module handles Clone based functions
#
###############################################################################
package alDente::Clone;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Clone.pm - This module handles Clone based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Clone based functions<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use CGI qw(:standard);
use Data::Dumper;
use RGTools::Barcode;
use strict;

##############################
# custom_modules_ref         #
##############################
use SDB::DB_Object;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::DB_Form_Viewer;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;

##############################
# global_vars                #
##############################
use vars qw($current_plates $Connection);
use vars qw(@plate_formats @plate_info @locations @plate_sizes @libraries);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
my %Clone_Alias;
$Clone_Alias{clone_name}   = "Sample.Sample_Name";
$Clone_Alias{library}      = "Clone_Sample.FK_Library__Name";
$Clone_Alias{plate_id}     = "Clone_Sample.FKOriginal_Plate__ID";
$Clone_Alias{well}         = "Clone_Sample.Original_Well";
$Clone_Alias{sample_id}    = "Clone_Sample.FK_Sample__ID";
$Clone_Alias{plate_number} = "Clone_Sample.Library_Plate_Number";

$Clone_Alias{mgc_number} = "Sample_Alias.Alias";
$Clone_Alias{alias}      = "Sample_Alias.Alias";
$Clone_Alias{alias_type} = "Sample_Alias.Alias_Type";

my %Source_Alias;
$Source_Alias{source_name}    = "Clone_Source.Source_Name";
$Source_Alias{source_library} = "Clone_Source.Source_Library_ID";
$Source_Alias{source_id}      = "Clone_Source.FK_Organization__ID";
$Source_Alias{source_row}     = "Clone_Source.FK_Organization__ID";
$Source_Alias{source_col}     = "Clone_Source.FK_Organization__ID";

$Source_Alias{source_quadrant} = "Well_Lookup.Quadrant";

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

    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);    # Database handle
    my $sample_id = $args{-sample_id};
    my $clone_id  = $args{-clone_id};

    my $attributes = $args{-attributes};           ## allow inclusion of attributes for new record

    my $encoded = $args{-encoded} || 0;            ## reference to encoded object (if frozen)

    my ($class) = ref($this) || $this;
    my $self = SDB::DB_Object->new( -dbc => $dbc, -tables => 'Clone_Sample,Sample', -encoded => $encoded );

    bless $self, $class;
    $self->{dbc} = $dbc;
    return $self;
}

##############################
# public_methods             #
##############################

#############
sub home_page {
#############
    my $self = shift;

    print "HOme info...";
    return;
}

############
sub get_info {
############
    my $self = shift;
    my %args = @_;

    my $condition = $args{-condition} || '1';
    my $field_ref = $args{-fields};

    my @fields;
    my %field_alias;
    if ($field_ref) { @fields = @$field_ref }
    else {
        foreach my $alias ( keys %Clone_Alias ) {
            push( @fields, $Clone_Alias{$alias} );
            $field_alias{$alias} = $Clone_Alias{$alias};
        }
        if ( grep /source/i, @fields ) {
            foreach my $alias ( keys %Source_Alias ) {
                push( @fields, $Source_Alias{$alias} );
                $field_alias{$alias} = $Source_Alias{$alias};
            }
        }
    }

    if ( grep /source/i, @fields ) {
        $self->add_tables('Clone_Source');
    }
    if ( grep /\bSample_Alias\b/i, @fields ) {
        $self->add_tables( 'Sample_Alias', "Sample_Alias.FK_Sample__ID=Sample_ID" );
    }

    $self->field_alias( \%field_alias );
    $self->load_Object( -fields => \@fields, -condition => $condition, -multiple => 1 );

    return $self->{record_count};
}

##############
sub id_by_Plate {
##############
    #
    # Identify Clone given Plate information (plate id & well)
    #
    my $self = shift;

    my %args  = @_;
    my $plate = $args{-plate};    ## plate id
    my $well  = $args{-well};     ## well position in plate
    my $dbc   = $self->{dbc};
    my $found = 0;                ## flag to indicate if Clone identified

    my ($clone_id) = $dbc->Table_find( 'Clone', 'Clone_ID', "where FK_Plate__ID = $plate AND Clone_Well = '$well'" );
    if ($clone_id) {
        $found = 1;
        $self->primary_value(-table=>'Clone', -value=>$clone_id);
        $self->load_Object();
    }
    else {
        print "No Clone found for Plate $plate ($well)";
    }

    return $found;
}

##############
sub id_by_Name {
##############
    #
    # Identify Clone given Name... (eg. 'CN001-1a')
    #
    my $self = shift;

    my %args = @_;
    my $run  = $args{-name};    ## plate id

    my $found = 0;              ## flag to indicate if Clone identified

    return $found;
}

#############
sub id_by_Run {
#############
    #
    # Identify Clone given Run information (run id & well)
    #
    my $self = shift;

    my %args = @_;
    my $run  = $args{-run};     ## plate id
    my $well = $args{-well};    ## well position in plate

    my $found = 0;              ## flag to indicate if Clone identified

    return $found;
}

#######################
sub update_data_references {
#######################
    #
    # update (redundant) references to the original clone in the final data table (eg. Clone_Sequence)
    #
    # (may be used to back fill if original clones not originally stored with final data)
    #
    my $self = shift;

    ## get list of plates spawned from original (of similar size,format_size)

    ## get list of data runs using any of these plates

    ## update data for matching wells.

    ## get list of plates, well_mapping for plates of different size

    ## get list of data runs using any of these plates

    ## update data for matching wells
    ## (be careful to ensure well mapping tracked through plate mapping conversions)

}

###############
sub update_Clone {
###############
    #
    # Add record for Clones (if missing) given current Original Plate.
    #
    # (may be used to back fill if data available before clones were recorded)
    #
    my $self = shift;

    ## generate list of attributes to be stored ##

    ## save as new Clone record ##

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

$Id: Clone.pm,v 1.11 2004/11/01 21:13:49 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
