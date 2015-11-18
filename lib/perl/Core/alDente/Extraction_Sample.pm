##############################################################################
# Extraction_Sample.pm
#
# This module handles Extraction_Sample based functions
#
###############################################################################
package alDente::Extraction_Sample;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Extraction_Sample.pm - This module handles Extraction_Sample based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Extraction_Sample based functions<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(alDente::Sample);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use alDente::Sample;
use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use SDB::HTML;
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Views;

##############################
# global_vars                #
##############################
use vars qw($project_dir);
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
    my ($class) = ref($this) || $this;
    my %args = @_;

    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);    ## database handle
    my $id         = $args{-id};
    my $ids        = $args{-ids};
    my $plate_id   = $args{-plate_id} || 0;
    my $sample_id  = $args{-sample_id} || 0;
    my $attributes = $args{-attributes};            ## allow inclusion of attributes for new record
    my $encoded    = $args{-encoded} || 0;          ## reference to encoded object (frozen)

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => 'Sample,Extraction_Sample' );

    my $extr_sample_id;
    if ($plate_id) {
        $sample_id = $this->SUPER::get_sample_id( -dbc => $dbc, -plate_id => $plate_id, -plate_type => 'Tube' );
    }
    if ($sample_id) {
        $self->{id} = $sample_id;
        $self->primary_value( -table => 'Sample', -value => $sample_id );
        $extr_sample_id = $dbc->Table_find( 'Extraction_Sample', 'Extraction_Sample_ID', "WHERE FK_Sample__ID = $sample_id" );

        #$self->{id} =  $self->get_data('Solution.Solution_ID');
    }
    elsif ($id) {
        $self->{id} = $id;
    }
    if ($extr_sample_id) {
        $self->{extraction_sample_id} = $extr_sample_id;

        #$self->add_tables('Extraction_Sample');
        $self->primary_value( -table => 'Extraction_Sample', -value => $self->{extraction_sample_id} );
    }
    $self->{dbc} = $dbc if ($dbc);

    bless $self, $class;

    return $self;
}

##############################
# public_methods             #
##############################

#############################################
# Display home page for Extraction_Sample
#############################################
sub home_page {
############
    my $self = shift;

    $self->SUPER::home_page( -id => $self->{sample_id} );

    #if ($self->value('Extraction_Details.Extraction_Details_ID')) {
    #	print &Link_To($homelink,'Edit Extraction Details',"&Search=1&Table=Extraction_Details&Search+List=" . $self->value('Extraction_Details_ID'),$Settings{LINK_COLOUR});
    #}
    #else {
    #	my %configs;
    #	$configs{'-grey'}{FK_Extraction_Sample__ID} = $self->value('Extraction_Sample.Extraction_Sample_ID');
    #
    #	# Freeze the configs hash
    #	my $frozen_configs = Safe_Freeze(-name=>"DB_Form_Configs",-value=>\%configs,-format=>'url',-encode=>1);
    #	print &Link_To($homelink,'Add Extraction Details',"&New+Entry=New+Extraction_Details&$frozen_configs",$Settings{LINK_COLOUR});
    #}
    return;
}
##############################
# Create a set of Extraction_Samples for a plateonn
# return: 1 if successful, 0 if not
##############################
sub create_extraction_samples {
##############################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $dbc = $self->{dbc} || SDB::Errors::log_deprecated_usage("Connection", $Connection);

    Message("Code should not come here...redivert through alDente::Sample::create_samples");
    Call_Stack();

    my $plate_id  = $args{-plate_id};     # (Scalar) ID of the plate to add Extraction_Samples to
    my $source_id = $args{-source_id};    # (Scalar) Source ID of the source that this plate is being created from

    unless ($source_id) {
        $source_id = '';
    }

    # retrieve properties of the plate
    my ( $plate_number, $lib, $plate_size, $plate_contents ) = @{ $dbc->Table_retrieve( "Plate", [ "Plate_Number", "FK_Library__Name", "Plate_Size", "Plate_Content_Type" ], "WHERE Plate_ID = $plate_id", -format => "RA" ) };

    # sanity check
    # if plate_contents is Clone (which it should never be), set to Mixed
    $plate_contents = 'Mixed' if ( $plate_contents eq 'Clone' );

    # for Clone_Samples:  create Extracton_Sample, Plate_Sample, and Sample records as necessary
    my $condition;
    my $well_field;

    if ( $plate_size =~ /96/ ) {
        $well_field = 'Plate_96';
        $condition  = "WHERE Quadrant='a'";
    }
    elsif ( $plate_size =~ /384/ ) {
        $well_field = 'Plate_384';
        $condition  = '';
    }
    else {
        $well_field = "N/A";
        $condition  = '';
    }

    # build a hash with all the wells to insert as the key and the quadrant as the value
    my %Map;
    my @wells;

    # retrieve the source plate id if this is created from a source that exists in the system
    my $plate_source = '';
    if ($source_id) {
        ($plate_source) = $dbc->Table_find( 'Source', 'FKSource_Plate__ID', "WHERE Source_ID=$source_id" );
    }
    my @parent_samples;

    ## if there is a source plate id, determine the sources that need to be linked to each individual sample
    # optimization - if the source plate is a tube, just grab the sample ID ONCE
    my $plate_source_type = undef;
    my $tube_sample       = undef;
    if ($plate_source) {
        ($plate_source_type) = $dbc->Table_find( "Plate", "Plate_Type", "WHERE Plate_ID=$plate_source" );
        if ( $plate_source_type eq 'Tube' ) {
            my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_source );
            $tube_sample = $Ancestry{sample_id};
        }
    }

    # if necessary, retrieve source sample by searching through the inheritance tree of the source
    if ( $well_field ne 'N/A' ) {
        my @well_info = $dbc->Table_find( 'Well_Lookup', "$well_field,Quadrant", "$condition" );
        foreach my $row (@well_info) {
            my ( $well, $quad ) = split ',', $row;
            $well = &format_well($well);
            push( @wells, $well );
            $Map{$well} = $quad;
            if ( $plate_source && ( $plate_source_type eq 'Tube' ) ) {
                push( @parent_samples, $tube_sample );
            }
            elsif ($plate_source) {
                my %Ancestry = alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_source, -well => $well );
                my $sample_id = $Ancestry{sample_id};
                push( @parent_samples, $sample_id );
            }
        }
    }
    else {
        push( @wells, $well_field );
        $Map{$well_field} = '';
    }

    # build insert hash for smart_append
    # inserting into tables Sample,Clone_Sample, and Plate_Sample
    my %extraction_sample_info;
    foreach my $i ( 0 .. $#wells ) {
        my $well = $wells[$i];
        my $quad = '';
        if ( $plate_size =~ /384/ ) {
            $quad = $Map{$well};
        }

        # custom code - do not add in a well if there is only one well
        my $sample_name = "$lib-${plate_number}\_$well";
        if ( $well eq 'N/A' ) {
            $sample_name = "$lib-${plate_number}";
        }

        $extraction_sample_info{ $i + 1 } = [ $sample_name, 'Extraction', $source_id, $parent_samples[$i], $plate_id, $well, $well, $plate_number, $lib, $plate_contents ];

    }

    my $ok = $dbc->smart_append(
        -tables    => 'Sample,Extraction_Sample,Plate_Sample',
        -fields    => [ 'Sample.Sample_Name', 'Sample.Sample_Type', 'Sample.FK_Source__ID', 'Sample.FKParent_Sample__ID', 'FKOriginal_Plate__ID', 'Original_Well', 'Plate_Sample.Well', 'Plate_Number', 'FK_Library__Name', 'Extraction_Sample_Type' ],
        -values    => \%extraction_sample_info,
        -autoquote => 1
    );

    if ($ok) {
        return 1;
    }
    else {
        return 0;
    }

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

$Id: Extraction_Sample.pm,v 1.6 2004/11/08 23:24:04 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
