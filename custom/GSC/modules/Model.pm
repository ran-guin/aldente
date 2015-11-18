##################################################################################################################################
# GSC.pm
#
# Specific methods for GSC
#
###################################################################################################################################
package GSC::Model;

use Data::Dumper;
use Carp;
use strict;
use RGTools::RGIO;

############
sub new {
############
    my $this  = shift;
    my $class = ref $this || $this;
    my %args  = @_;
    my $dbc   = $args{-dbc};

    my $self = {};
    $self->{dbc} = $dbc;
    bless $self, $class;
    return $self;
}

sub determine_genome_reference {
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $self->{dbc};
    my $library = $args{-library};
    require BioSpecimens::Trigger;
    require alDente::Library;
    require alDente::Funding;
    my @library_list = Cast_List( -list => $library, -to => 'Array' );
    ## check if pooled
    my @genome_info;
    foreach my $lib (@library_list) {
        my %pool;
        %pool = $dbc->Table_retrieve(
            'Library,Plate,ReArray_Request,ReArray,Plate as SP',
            ['SP.FK_Library__Name as Library'],
            "WHERE Library_Name IN ('$lib') and 
                      Plate.FK_Library__Name = LIbrary_Name and 
                      ReArray_Request.FKTarget_Plate__ID = Plate.PLate_ID and 
                      ReArray.FK_ReArray_Request__ID = ReArray_Request_ID and 
                      SP.Plate_ID = ReArray.FKSource_Plate__ID", -key => 'Library'
        );

        if ( int( keys %pool ) > 0 ) {
            foreach my $sub_lib ( sort keys %pool ) {
                my $lib_genome = $self->determine_genome_reference_by_library( -library => $sub_lib );
                push @genome_info, $lib_genome;
            }

        }
        else {
            my $lib_genome = $self->determine_genome_reference_by_library( -library => $library );
            push @genome_info, $lib_genome;

        }
    }
    return \@genome_info;
}

sub determine_genome_reference_by_library {
    my $self    = shift;
    my %args    = @_;
    my $dbc     = $self->{dbc};
    my $library = $args{-library};

    require BioSpecimens::Trigger;
    require alDente::Library;
    require alDente::Funding;

    my $lib = alDente::Library->new( -dbc => $dbc );
    my $lib_genome  = $lib->get_library_genome_reference( -library       => $library, -dbc => $dbc );
    my $trigger     = BioSpecimens::Trigger->new( -dbc                   => $dbc );
    my $bcr_genome  = $trigger->get_BCR_Study_genome_reference( -library => $library, -dbc => $dbc );
    my $fund        = alDente::Funding->new( -dbc                        => $dbc );
    my $fund_genome = $fund->get_funding_genome_reference( -library      => $library, -dbc => $dbc );

    my $genome_info;
    my $determination_level;
    my @blah = keys %{$lib_genome};
    if ( int(@blah) > 0 ) {
        $genome_info         = $lib_genome;
        $determination_level = 'Library';
    }
    elsif ( int( keys %{$bcr_genome} ) > 0 ) {
        $genome_info         = $bcr_genome;
        $determination_level = 'BCR_Study';
    }
    elsif ( int( keys %{$fund_genome} ) > 0 ) {
        $genome_info         = $fund_genome;
        $determination_level = 'Funding';
    }

    # default
    my %genome;
    %genome = $dbc->Table_retrieve(
        'Source,Original_Source,Library,Genome,Sample',
        [ 'Genome_ID', 'Library_Name as Library', 'Genome.FK_Taxonomy__ID as Taxonomy' ],
        "WHERE Source_ID = Sample.FK_Source__ID and Sample.FK_Library__Name = Library_Name and Original_Source_ID = Source.FK_Original_Source__ID and Original_Source.FK_Taxonomy__ID = Genome.FK_Taxonomy__ID and Genome_Default = 'Yes'and Library.FK_Original_Source__ID = Original_Source_ID and Library_Name = '$library'",
        -distinct => 1
    );

    ## check if genome_id match the taxonomy_id, otherwise, if there is a default for that taxonomy, use the default_genome_ref
    my ($check_genome_taxonomy) = $dbc->Table_find( 'Genome', 'Genome_ID', "WHERE FK_Taxonomy__ID = $genome{Taxonomy}[0] AND Genome_ID = $genome_info->{Genome_ID}" ) if $genome_info->{Genome_ID} && $genome{Taxonomy}[0];
    if ( !$genome_info->{Genome_ID} || !$check_genome_taxonomy ) {
        if ( $genome{Genome_ID}[0] && $genome{Library}[0] ) {
            $genome_info->{Library}   = $genome{Library}[0];
            $genome_info->{Genome_ID} = $genome{Genome_ID}[0];

            $determination_level = 'Default';
        }
        else {
            $determination_level = 'No Default set';
        }
    }
    $genome_info->{determination_level} = $determination_level;
    return $genome_info;
}
#################################
sub determine_reference_trigger {
#################################
    my $self                      = shift;
    my %args                      = @_;
    my $run_analysis_id           = $args{-run_analysis_id};
    my $multiplex_run_analysis_id = $args{-multiplex_run_analysis_id};
    my $dbc                       = $self->{dbc};
    my $debug                     = $args{-debug};
    require BioSpecimens::Trigger;
    require alDente::Library;
    require alDente::Funding;

    my $genome_id;
    my $target_read_length;
    my $plate_id;
    my $taxonomy_id;
    my $reference_info;
    if ($run_analysis_id) {
        my ($run_analysis_type) = $dbc->Table_find( 'Run_Analysis', 'Run_Analysis_Type', "WHERE Run_Analysis_ID = $run_analysis_id" );

        ## only apply this trigger to secondary alignments
        if ( $run_analysis_type ne 'Secondary' ) {
            return;
        }
        my $bcr_ref;
        my $lib_ref;
        my $fund_ref;
        my $trigger = BioSpecimens::Trigger->new( -dbc => $dbc );
        ( $bcr_ref, $target_read_length ) = $trigger->get_BCR_Study_reference( -run_analysis_id => $run_analysis_id );
        my $lib = alDente::Library->new( -dbc => $dbc );

        $lib_ref = $lib->get_library_analysis_reference( -run_analysis_id => $run_analysis_id );
        my $fund = alDente::Funding->new( -dbc => $dbc );
        $fund_ref = $fund->get_funding_analysis_reference( -run_analysis_id => $run_analysis_id );

        if ($lib_ref) {
            $genome_id = $lib_ref;
        }
        elsif ($bcr_ref) {
            $genome_id = $bcr_ref;
        }
        elsif ($fund_ref) {
            $genome_id = $fund_ref;
        }
        else {
            $genome_id = "";
        }

        ($reference_info) = $dbc->Table_find(
            'Run_Analysis,Sample,Source,Original_Source,Run,Plate',
            'FK_Taxonomy__ID,Plate_ID',
            "WHERE Run_Analysis_ID = $run_analysis_id and Run_Analysis.FK_Run__ID = Run_ID and Run.FK_Plate__ID = Plate_ID and  
                                           Run_Analysis.FK_Sample__ID = Sample_ID and
                                           Source_ID = Sample.FK_Source__ID and 
                                           Original_Source_ID = Source.FK_Original_Source__ID"
        );
        ( $taxonomy_id, $plate_id ) = split ',', $reference_info;

        #Add in temporary check for sequence length and if length is greater than 150. trim to 150
        #my ($cycles) = $dbc->Table_find( 'Run_Analysis,SolexaRun', 'Cycles', "WHERE Run_Analysis.FK_Run__ID = SolexaRun.FK_Run__ID AND Run_Analysis_ID = '$run_analysis_id'" );
        #if ( $cycles > 150 ) {
        #
        #    #check to see if target_read_length is already set to less than 150, if so, don't overwrite
        #    if ( !$target_read_length || $target_read_length > 150 ) {
        #        $target_read_length = 150;
        #    }
        #}

    }
    elsif ($multiplex_run_analysis_id) {
        my $bcr_ref;
        my $lib_ref;
        my $fund_ref;
        my $trigger = BioSpecimens::Trigger->new( -dbc => $dbc );
        ( $bcr_ref, $target_read_length ) = $trigger->get_BCR_Study_reference( -multiplex_run_analysis_id => $multiplex_run_analysis_id );

        my $lib = alDente::Library->new( -dbc => $dbc );
        $lib_ref = $lib->get_library_analysis_reference( -multiplex_run_analysis_id => $multiplex_run_analysis_id );

        my $fund = alDente::Funding->new( -dbc => $dbc );
        $fund_ref = $fund->get_funding_analysis_reference( -multiplex_run_analysis_id => $multiplex_run_analysis_id );

        if ($lib_ref) {
            $genome_id = $lib_ref;
        }
        elsif ($bcr_ref) {
            $genome_id = $bcr_ref;
        }
        elsif ($fund_ref) {
            $genome_id = $fund_ref;
        }
        else {
            $genome_id = "";
        }
        ($reference_info) = $dbc->Table_find(
            'Multiplex_Run_Analysis,Sample,Source,Original_Source LEFT JOIN ReArray ON ReArray.FK_Sample__ID = Multiplex_Run_Analysis.FK_Sample__ID',
            'FK_Taxonomy__ID,ReArray.FKSource_Plate__ID',
            "WHERE Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id and 
                                           Multiplex_Run_Analysis.FK_Sample__ID = Sample_ID and
                                           Source_ID = Sample.FK_Source__ID and 
                                           Original_Source_ID = Source.FK_Original_Source__ID"
        );
        ( $taxonomy_id, $plate_id ) = split ',', $reference_info;
        if ( !$taxonomy_id ) {
            ($reference_info) = $dbc->Table_find(
                'Run_Analysis,Multiplex_Run_Analysis,Sample,Source,Original_Source,Run',
                'FK_Taxonomy__ID,Run.FK_Plate__ID',
                "WHERE Run_Analysis_ID = FK_Run_Analysis__ID and 
                                           Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id and 
                                           Run_Analysis.FK_Sample__ID = Sample_ID and Run_Analysis.FK_Run__ID = Run_ID and
                                           Source_ID = Sample.FK_Source__ID and 
                                           Original_Source_ID = Source.FK_Original_Source__ID"
            );
            ( $taxonomy_id, $plate_id ) = split ',', $reference_info;
        }

        if ( !$plate_id ) {
            ($plate_id) = $dbc->Table_find(
                'Run_Analysis,Multiplex_Run_Analysis,Run',
                'Run.FK_Plate__ID',
                "WHERE Run_Analysis_ID = FK_Run_Analysis__ID and 
                                           Multiplex_Run_Analysis_ID = $multiplex_run_analysis_id and
		                           Run_Analysis.FK_Run__ID = Run_ID"
            );
        }
    }
    require alDente::Container;
    my $list = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id, -list => 1, -include_self => 1, -format => 'list' );
    my @library_strategy = $dbc->Table_find(
        'Plate_Attribute,Attribute,Library_Strategy', 'distinct Library_Strategy_Name',
        "WHERE FK_Attribute__ID = Attribute_ID and Attribute_Name = 'Library_Strategy' and Attribute_Value = Library_Strategy_ID
       and FK_Plate__ID in ($list) "
    );
    my $library_strategy = $library_strategy[0];
    my $default_genome_ref;
    if ( $library_strategy =~ /^RNA.Seq$/ ) {
        ($default_genome_ref) = $dbc->Table_find( 'Genome', 'Genome_ID', "WHERE FK_Taxonomy__ID = $taxonomy_id and Genome_Default='Yes' and Genome_Type = 'Transcriptome'" );
    }
    else {
        ($default_genome_ref) = $dbc->Table_find( 'Genome', 'Genome_ID', "WHERE FK_Taxonomy__ID = $taxonomy_id and Genome_Default='Yes' and Genome_Type = 'Genome'" );
    }

    ## check if genome_id match the taxonomy_id, otherwise, if there is a default for that taxonomy, use the default_genome_ref
    my ($check_genome_taxonomy) = $dbc->Table_find( 'Genome', 'Genome_ID', "WHERE FK_Taxonomy__ID = $taxonomy_id AND Genome_ID = '$genome_id'" );
    if ( !$check_genome_taxonomy && $default_genome_ref ) {
        $genome_id = $default_genome_ref;
    }

    ## default reference check
    if ( $default_genome_ref && !$genome_id ) {
        $genome_id = $default_genome_ref;
    }

    my $datetime = &date_time();
    my $ok;

    if ($run_analysis_id) {

        ## given the genome, set the analysis genome of the run attribute
        my ($attribute_id)      = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'FKAnalysis_Genome__ID' and Attribute_Class = 'Run_Analysis'" );
        my ($trim_attribute_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'Trimmed_Sequence_Length' and Attribute_Class = 'Run_Analysis'" );
        if ($target_read_length) {
            if ($debug) {
                Message("Adding Trimmed Length $target_read_length to Run_Analysis_ID $run_analysis_id");
            }
            else {
                $ok = $dbc->Table_append_array(
                    'Run_Analysis_Attribute',
                    [ 'FK_Run_Analysis__ID', 'FK_Attribute__ID', 'Attribute_Value',   'FK_Employee__ID', 'Set_DateTime' ],
                    [ $run_analysis_id,      $trim_attribute_id, $target_read_length, 141,               $datetime ],
                    -autoquote => 1
                );
            }
        }
        if ($genome_id) {
            if ($debug) {
                Message("Adding Analysis_Genome $genome_id to Run_Analysis $run_analysis_id");
            }
            else {
                $ok = $dbc->Table_append_array( 'Run_Analysis_Attribute', [ 'FK_Run_Analysis__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ], [ $run_analysis_id, $attribute_id, $genome_id, 141, $datetime ],
                    -autoquote => 1 );
            }
        }
    }
    elsif ($multiplex_run_analysis_id) {
        my ($attribute_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'FKAnalysis_Genome__ID' and Attribute_Class = 'Multiplex_Run_Analysis'" );

        if ($genome_id) {
            if ($debug) {
                Message("Adding Analysis_Genome $genome_id to Multiplex_Run_Analysis $multiplex_run_analysis_id");
            }
            else {
                $ok = $dbc->Table_append_array(
                    'Multiplex_Run_Analysis_Attribute',
                    [ 'FK_Multiplex_Run_Analysis__ID', 'FK_Attribute__ID', 'Attribute_Value', 'FK_Employee__ID', 'Set_DateTime' ],
                    [ $multiplex_run_analysis_id,      $attribute_id,      $genome_id,        141,               $datetime ],
                    -autoquote => 1
                );
            }
        }
    }
    return $genome_id;
}

return 1;

__END__;
##############################
# perldoc_header             #
##############################
=head1 NAME <UPLINK>

<module_name>

=head1 SYNOPSIS <UPLINK>

Usage:

=head1 DESCRIPTION <UPLINK>

<description>

=for html

=head1 KNOWN ISSUES <UPLINK>
    
None.    

=head1 FUTURE IMPROVEMENTS <UPLINK>
    
=head1 AUTHORS <UPLINK>
    
    Ran Guin, Andy Chan and J.R. Santos at the Michael Smith Genome Sciences Centre, Vancouver, BC
    

=head1 CREATED <UPLINK>
    
    <date>

=head1 REVISION <UPLINK>
    
    <version>

=cut
